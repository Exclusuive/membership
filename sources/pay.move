module exclusuive::pay;

use exclusuive::retail_shop::{RetailShop};
use exclusuive::stamp_reward::{Self, Stamp, Coupon};

use std::string::String;
use sui::coin::Coin;
use sui::event;
use usdc::usdc::USDC;

const E_NOT_CORRECT_SHOP: u64 = 1;
const E_NOT_PAID: u64 = 2;

// Product 정보가 있어야 그것 기반으로 pay를 할 수 있다. 아니면 구멍이 너무 커

public struct PaymentRequest {
  shop: ID,
  stamp: Stamp,
  price: u64,
  paid: u64
}

public struct PaidEvent has copy, drop {
  shop: ID,
  payer: address,
  price: u64,
  created_at: u64
}

/// PyamentRequest를 이용해서 자기만의 pay 로직을 만들면 됨
public fun new_request(shop: &RetailShop, product_type_name: String, ctx: &mut TxContext): PaymentRequest {
  let stamp = stamp_reward::new_stamp(shop, ctx);
  let product_type = shop.product_type(product_type_name);

  PaymentRequest {
    shop: object::id(shop),
    stamp,
    price: product_type.price(),
    paid: 0
  }
}

/// USDC로 pay 가능: 자기만의 pay 로직에 이 함수를 사용하면 됨
public fun pay(shop: &mut RetailShop, request: &mut PaymentRequest, coin: Coin<USDC>) {
  assert!(object::id(shop) == request.shop, E_NOT_CORRECT_SHOP);
  let value = coin.value();
  shop.add_balance(coin);
  request.paid = request.paid + value;
}

/// 만약 coupon 사용 시에 coupon 금액이 product price 보다 클 경우 그냥 잔액 안 남기고 소진하는 걸로
public fun consume_coupon(shop: &RetailShop, request: &mut PaymentRequest, coupon: Coupon, ctx: &TxContext) {
  assert!(object::id(shop) == request.shop, E_NOT_CORRECT_SHOP);
  let (coupon_shop, coupon_type) = stamp_reward::unpack_coupon(coupon, ctx);
  assert!(object::id(shop) == coupon_shop, E_NOT_CORRECT_SHOP);
  let value = coupon_type.coupon_amount();
  if (request.price < value) {
    request.paid = request.price;
  } else {
    request.paid = request.paid + value;
  };
}

/// 마지막으로 PaymentRequest를 확인하고 필요한 금액만큼 지불한게 맞으면 Stamp를 보상으로 줌
public fun confirm_request(shop: &RetailShop, request: PaymentRequest, ctx: &TxContext): Stamp {
  let PaymentRequest{shop: shop_id, stamp, price, paid} = request;
  event::emit(PaidEvent { 
    shop: object::id(shop),
    payer: ctx.sender(),
    price: paid,
    created_at: ctx.epoch_timestamp_ms()
  });
  assert!(object::id(shop) == shop_id, E_NOT_CORRECT_SHOP);
  assert!(price == paid, E_NOT_PAID);
  stamp
}
