module exclusuive::retail_shop;

use std::string::String;
use sui::vec_map::{Self, VecMap};

const GUEST: vector<u8> = b"guest";
const E_NOT_CORRECT_SHOP_CAP: u64 = 1;

// 가게마다 하나 씩 있는 RetailShop 오브젝트
public struct RetailShop has key {
  id: UID,
  membership_types: VecMap<String, RetailMembershipType>,
  coupon_types: VecMap<String, CouponType>
}

public struct RetailShopCap has key, store {
  id: UID,
  shop: ID
}

// 멤버십 타입: Green, Silver, Gold 등등
public struct RetailMembershipType has store, copy, drop {
  name: String,
  require_condition: u16
}

// Stamp와 교환 가능한 Reward인 Coupon의 타입
public struct CouponType has store, copy, drop {
  name: String,
  require_membership: RetailMembershipType,
  require_stamps: u16
}


//==================================
//======== Entry Functions
//==================================

entry fun create_shop(ctx: &mut TxContext) {
  let (shop, cap) = new_shop(ctx);
  transfer::share_object(shop);
  transfer::transfer(cap, ctx.sender());
}

entry fun create_stamp_card(shop: &RetailShop, ctx: &mut TxContext) {
  // RetailShop에서 membership_types의 0번째 membership type(Guest Type)으로 StampCard 발급
}

//==================================
//======== Public Functions : Retail Shop
//==================================

public fun new_shop(ctx: &mut TxContext): (RetailShop, RetailShopCap) {
  let mut shop = RetailShop {
    id: object::new(ctx),
    membership_types: vec_map::empty(),
    coupon_types: vec_map::empty()
  };
  let cap = RetailShopCap {
    id: object::new(ctx),
    shop: object::id(&shop)
  };

  // shop 최초 생성 시 shop.membership_types 에 name: "Geust", require_condition: 0인 RetailMembershipType 추가
  shop.membership_types.insert(GUEST.to_string(), RetailMembershipType{
    name: GUEST.to_string(),
    require_condition: 0
  });

  (shop, cap)
}

public fun add_retail_membership_type(shop: &mut RetailShop, cap: &RetailShopCap, name: String, require_condition: u16) {
  assert!(object::id(shop) == cap.shop, E_NOT_CORRECT_SHOP_CAP);
  // require condition 은 0보다 커야 함
  assert!(require_condition > 0);
  shop.membership_types.insert(name, RetailMembershipType{
    name,
    require_condition
  });
}

// public fun update_retail_membership_type() {}

//==================================
//======== Package Functions : Retail Shop
//==================================

public (package) fun membership_type(shop: &RetailShop, membership_type_name: String): RetailMembershipType {
  let membership_type = shop.membership_types.get(&membership_type_name);
  *membership_type
}
