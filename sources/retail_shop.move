module exclusuive::retail_shop;

use std::string::String;
use sui::vec_set::VecSet;
use sui::clock::Clock;

// 가게마다 하나 씩 있는 RetailShop 오브젝트
public struct RetailShop has key {
  id: UID,
  membership_types: VecSet<RetailMembershipType>
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

// Membership 오브젝트 -> StampCard
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
//======== Public Functions : Stamp Card (Retail Membership)
//==================================

public fun new_stamp_card(shop: &RetailShop, membership_type: RetailMembershipType, clock: &Clock) {
  // 현재 날짜로부터 1년이 StampCard의 유효 기간

}

public fun add_stamp(shop: &RetailShop, stamp_card: &mut StampCard, stamp: Stamp) {
  // 물건을 구매할 때만 stamp 적립

  // 임시로 컴파일 에러 없앨라고
  let Stamp{id, shop: _, expiry_date: _} = stamp;
  object::delete(id);
}

public fun update_stamp_card(shop: &RetailShop, stamp_card: &mut StampCard, clock: &Clock) {
  // expiry date는 최신 Stamp의 expiry date 로 연장
  // expiry date 지난 stamp 는 폐기
  // 일정 stamp 개수 condition 넘으면 자동으로 업그레이드??
}

public (package) fun upgrade_stamp_card() {}
public (package) fun downgrade_stamp_card() {}