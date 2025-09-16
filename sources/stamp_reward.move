module exclusuive::stamp_reward;

// Membership 오브젝트 -> StampCard
use exclusuive::retail_shop::{RetailShop, RetailMembershipType, CouponType};
use std::string::String;

const ONE_MONTH_MS: u64 =  2_592_000_000;
const SIX_MONTH_MS: u64 =  15_552_000_000;
const ONE_YEAR_MS: u64 =  31_004_000_000;
const GUEST: vector<u8> = b"guest";

const E_NOT_CORRECT_SHOP: u64 = 1;
const E_NOT_ENOUGH_STAMPS: u64 = 2;

// stamp는 queue로 사용 (선입선출)
public struct StampCard has key {
  id: UID,
  shop: ID,
  membership_type: RetailMembershipType,
  stamps: vector<Stamp>,
  creation_date: u64,
  expiry_date: u64
}

public struct Stamp has key, store {
  id: UID,
  shop: ID,
  expiry_date: u64
}

public struct Coupon has key, store {
  id: UID,
  shop: ID,
  coupon_type: CouponType,
  expiry_date: u64
}

public struct CouponRequest {
  shop: ID,
  coupon: Coupon,
  require_stamps: u64,
  burned_stamps: u64
}


//==================================
//======== Entry Function
//==================================

entry fun create_stamp_card(shop: &RetailShop, ctx: &mut TxContext) {
  let stamp_card = new_stamp_card(shop, ctx);
  transfer::transfer(stamp_card, ctx.sender());
}


//==================================
//======== Public Functions : Stamp Card (Retail Membership)
//==================================

public fun new_stamp_card(shop: &RetailShop, ctx: &mut TxContext): StampCard {
  // RetailShop에서 membership_types의 0번째 membership type(Guest Type)으로 StampCard 발급
  let membership_type = shop.membership_type(GUEST.to_string());
  // 현재 날짜로부터 1년이 StampCard의 유효 기간
  StampCard {
    id: object::new(ctx),
    shop: object::id(shop),
    membership_type,
    stamps: vector<Stamp>[],
    creation_date: ctx.epoch_timestamp_ms(),
    expiry_date: ctx.epoch_timestamp_ms() + ONE_YEAR_MS,
  }
}

public (package) fun new_stamp(shop: &RetailShop,  ctx: &mut TxContext): Stamp {
  Stamp {
    id: object::new(ctx),
    shop: object::id(shop),
    expiry_date: ctx.epoch_timestamp_ms() + SIX_MONTH_MS // stamp는 6개월의 유효기간
  }

}

public fun add_stamp(shop: &RetailShop, stamp_card: &mut StampCard, stamp: Stamp) {
  assert!(object::id(shop) == stamp_card.shop, E_NOT_CORRECT_SHOP);

  // 물건을 구매할 때만 stamp 적립 -> PaymentRequest confirm 할 때 stamp를 얻을 수 있음
  stamp_card.stamps.push_back(stamp);
}

public fun update_stamp_card(shop: &RetailShop, stamp_card: &mut StampCard, ctx: &TxContext) {
  assert!(object::id(shop) == stamp_card.shop, E_NOT_CORRECT_SHOP);
  // expiry date 지난 stamp 는 폐기
  stamp_card.stamps.reverse();
  while (true) {
    let stamp = stamp_card.stamps.pop_back();
    if (stamp.expiry_date < ctx.epoch_timestamp_ms()) {
      let Stamp {id, shop: _, expiry_date: _} = stamp;
      object::delete(id);
      continue
    };
    stamp_card.stamps.push_back(stamp);
  };
  stamp_card.stamps.reverse();

  // expiry date는 최신 Stamp의 expiry date 로 연장
  let latest_stamp = stamp_card.stamps.borrow(stamp_card.stamps.length() - 1);
  if (latest_stamp.expiry_date > stamp_card.expiry_date){
    stamp_card.expiry_date = latest_stamp.expiry_date;
  };

  // 일정 stamp 개수 condition 넘으면 자동으로 업그레이드?? -> 나중에 구현
}

public fun request_coupon(shop: &RetailShop, stamp_card: &mut StampCard, coupon_type_name: String, ctx: &mut TxContext): CouponRequest {
  assert!(object::id(shop) == stamp_card.shop);
  let coupon_type = shop.coupon_type(coupon_type_name);
  let coupon = Coupon {
    id: object::new(ctx),
    shop: object::id(shop),
    coupon_type,
    expiry_date: ctx.epoch_timestamp_ms() + ONE_MONTH_MS
  };

  CouponRequest {
    shop: object::id(shop),
    coupon,
    require_stamps: coupon_type.require_stamps(),
    burned_stamps: 0
  }
}

public fun burn_stamp(request: &mut CouponRequest, stamp: Stamp) {
  let Stamp {id, shop, expiry_date: _} = stamp;
  assert!(shop == request.shop, E_NOT_CORRECT_SHOP);
  object::delete(id);
  request.burned_stamps = request.burned_stamps + 1;
}

public fun confirm_request_coupon(shop: &RetailShop, request: CouponRequest): Coupon {
  let CouponRequest{ shop: shop_id, coupon, require_stamps, burned_stamps } = request;
  assert!(object::id(shop) == shop_id, E_NOT_CORRECT_SHOP);
  assert!(require_stamps == burned_stamps, E_NOT_ENOUGH_STAMPS);
  coupon
}

public (package) fun upgrade_stamp_card() {}
public (package) fun downgrade_stamp_card() {}