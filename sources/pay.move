module exclusuive::pay;

use exclusuive::retail_shop::{RetailShop};
use exclusuive::stamp_reward::{Stamp};
use exclusuive::stamp_reward::new_stamp;

use std::string::String;
use sui::coin::Coin;
use usdc::usdc::USDC;

const E_NOT_CORRECT_SHOP: u64 = 1;
const E_NOT_PAID: u64 = 2;


// Product 정보가 있어야 그것 기반으로 pay를 할 수 있다. 아니면 구멍이 너무 커

public struct PaymentRequest {
  shop: ID,
  stamp: Stamp,
  amount: u64,
  paid: u64
}

// PyamentRequest를 이용해서 자기만의 pay 로직을 만들면 됨
public fun new_request(shop: &RetailShop, product_type_name: String, ctx: &mut TxContext): PaymentRequest {
  let stamp = new_stamp(shop, ctx);
  let product_type = shop.product_type(product_type_name);

  PaymentRequest {
    shop: object::id(shop),
    stamp,
    amount: product_type.price(),
    paid: 0
  }
}

public fun pay(shop: &mut RetailShop, request: &mut PaymentRequest, coin: Coin<USDC>) {
  assert!(object::id(shop) == request.shop, E_NOT_CORRECT_SHOP);
  let value = coin.value();
  shop.add_balance(coin);
  request.paid = request.paid + value;
}

public fun confirm_request(shop: &RetailShop, request: PaymentRequest): Stamp {
  let PaymentRequest{shop: shop_id, stamp, amount, paid} = request;
  assert!(object::id(shop) == shop_id, E_NOT_CORRECT_SHOP);
  assert!(amount == paid, E_NOT_PAID);
  stamp
}