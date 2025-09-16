module exclusuive::pay;

use exclusuive::retail_shop::{RetailShop, RetailMembershipType, CouponType};
use exclusuive::stamp_reward::{Stamp};
use exclusuive::stamp_reward::new_stamp;

const E_NOT_PAID: u64 = 1;

public struct PaymentRequest {
  shop: ID,
  stamp: Stamp,
  amount: u64,
  paid: u64
}

// PyamentRequest를 이용해서 자기만의 pay 로직을 만들면 됨
public fun new_request(shop: &RetailShop, amount: u64, ctx: &mut TxContext): PaymentRequest {
  let stamp = new_stamp(shop, ctx);
  PaymentRequest {
    shop: object::id(shop),
    stamp,
    amount,
    paid: 0
  }
}

public fun confirm_request(request: PaymentRequest): Stamp {
  let PaymentRequest{shop: _, stamp, amount, paid} = request;
  assert!(amount == paid, E_NOT_PAID);
  stamp
}