module exclusuive::retail_shop;

use std::string::String;
use sui::vec_map::VecMap;

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
}

entry fun create_stamp_card(shop: &RetailShop, ctx: &mut TxContext) {
  // RetailShop에서 membership_types의 0번째 membership type(Guest Type)으로 StampCard 발급
}

//==================================
//======== Public Functions : Retail Shop
//==================================

public fun new_shop(ctx: &mut TxContext) {
 // shop 최초 생성 시 shop.membership_types 에 name: "Geust", require_condition: 0인 RetailMembershipType 추가

}

public fun add_retail_membership_type(shop: &mut RetailShop, cap: &RetailShopCap, name: String, require_condition: u16) {
  // require condition 은 0보다 커야 함
}

// public fun update_retail_membership_type() {}

//==================================
//======== Package Functions : Retail Shop
//==================================

public (package) fun membership_type(shop: &RetailShop, membership_type_name: String): RetailMembershipType {
  let membership_type = shop.membership_types.get(&membership_type_name);
  *membership_type
}
