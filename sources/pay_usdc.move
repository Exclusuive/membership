module exclusuive::pay_usdc;

use exclusuive::retail_shop::{RetailShop};
use exclusuive::stamp_reward::{Self, Stamp, Coupon};

use std::string::String;
use sui::coin::Coin;
use sui::event;
use usdc::usdc::USDC;
use sui::balance::{Self, Balance};

const E_NOT_CORRECT_SHOP: u64 = 1;
const E_NOT_PAID_ENOUGH_OR_OVER_PAID: u64 = 2;
const E_PAID_BEFORE_CONSUMMING_COUPON: u64 = 3;
const E_TRY_TO_CONSUME_COUPONE_MORE_THAN_ONCE: u64 = 4;

// Product 정보가 있어야 그것 기반으로 pay를 할 수 있다. 아니면 구멍이 너무 커
public struct PaymentRequest {
  shop: ID,
  price: u64,
  paid: Balance<USDC>,
  coupon_paid: u64
}

public struct PaidEvent has copy, drop {
  shop: ID,
  payer: address,
  price: u64,
  created_at: u64
}

/// 다른 Web3 Retail MarketPlace 용 PaymentRequest
public fun new_request(
  shop: &RetailShop, price: u64
): PaymentRequest {
  PaymentRequest {
    shop: object::id(shop),
    price,
    paid: balance::zero(),
    coupon_paid: 0
  }
}

public fun new_request_with_product(
  shop: &RetailShop, product_type_name: String
): PaymentRequest {
  let product_type = shop.product_type(product_type_name);

  new_request(shop, product_type.price())
}

/// 만약 coupon 사용 시에 coupon 금액이 product price 보다 클 경우 그냥 잔액 안 남기고 소진하는 걸로
/// pay 전에 먼저 coupon을 사용해야 하고, coupon은 한 번에 1개만 사용 가능
public fun consume_coupon(
  shop: &RetailShop, request: &mut PaymentRequest, coupon: Coupon, ctx: &TxContext
) {
  assert!(object::id(shop) == request.shop, E_NOT_CORRECT_SHOP);
  assert!(request.paid.value() == 0, E_PAID_BEFORE_CONSUMMING_COUPON);
  assert!(request.coupon_paid == 0, E_TRY_TO_CONSUME_COUPONE_MORE_THAN_ONCE);
  let (coupon_shop, coupon_type) = stamp_reward::unpack_coupon(coupon, ctx);
  assert!(object::id(shop) == coupon_shop, E_NOT_CORRECT_SHOP);

  let value = coupon_type.coupon_value();
  if (request.price < value) {
    request.coupon_paid = request.price;
  } else {
    request.coupon_paid = request.coupon_paid + value;
  };
}

/// USDC로 pay 가능: 자기만의 pay 로직에 이 함수를 사용하면 됨
public fun pay(
  shop: &mut RetailShop, request: &mut PaymentRequest, coin: Coin<USDC>
) {
  assert!(object::id(shop) == request.shop, E_NOT_CORRECT_SHOP);
  request.paid.join(coin.into_balance());
}

/// 마지막으로 PaymentRequest를 확인하고 필요한 금액만큼 지불한게 맞으면 Stamp를 보상으로 줌
public fun confirm_request(
  shop: &mut RetailShop, request: PaymentRequest, ctx: &mut TxContext
): Option<Stamp> {
  let PaymentRequest{shop: shop_id, price, paid, coupon_paid} = request;
  event::emit(PaidEvent { 
    shop: object::id(shop),
    payer: ctx.sender(),
    price,
    created_at: ctx.epoch_timestamp_ms()
  });
  assert!(object::id(shop) == shop_id, E_NOT_CORRECT_SHOP);
  assert!(price == paid.value() + coupon_paid, E_NOT_PAID_ENOUGH_OR_OVER_PAID);
  stamp_reward::add_balance_usdc(shop, paid.into_coin(ctx), ctx)
}
