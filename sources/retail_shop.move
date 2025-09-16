module exclusuive::retail_shop;

use std::string::String;

// 가게마다 하나 씩 있는 RetailShop 오브젝트
public struct RetailShop has key {
  id: UID
}

public struct RetailShopCap has key, store {
  id: UID,
  shop: ID
}

// 멤버십 타입: Green, Silver, Gold 등등
public struct RetailMembershipType has store, copy {
  name: String,
  img_url: String,
  require_stamp: u16
}

public struct RetailMembershipKey has copy, store, drop {
  membership_level: u16
}

// Membership 오브젝트 -> StampCard
public struct StampCard has key {
  id: UID,
  shop: ID,
  img_url: String,
  membership_type: RetailMembershipType,
  stamps: vector<Stamp>,
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

entry fun create_shop() {}

entry fun create_stamp_card() {}

//==================================
//======== Public Functions : Retail Shop
//==================================

public fun new_shop() {}

public fun add_retail_membership_type() {}

// public fun update_retail_membership_type() {}

//==================================
//======== Public Functions : Stamp Card (Retail Membership)
//==================================

public fun new_stamp_card() {}

public fun add_stamp() {}

public fun update_retail_membership() {}

public (package) fun upgrade_retail_membership() {}
public (package) fun downgrade_retail_membership() {}