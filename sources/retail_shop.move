module exclusuive::retail_shop;

use std::string::String;
use sui::vec_map::{Self, VecMap};
use sui::balance::{Self, Balance};
use sui::coin::{Coin};

use usdc::usdc::USDC;

const GUEST: vector<u8> = b"guest";
const E_NOT_CORRECT_SHOP_CAP: u64 = 1;

//==================================
//======== Structs
//==================================

// 가게마다 하나 씩 있는 RetailShop 오브젝트
// TODO: name
public struct RetailShop has key {
  id: UID,
  product_types: VecMap<String, ProductType>,
  membership_types: VecMap<String, RetailMembershipType>,
  coupon_types: VecMap<String, CouponType>,
  balance: Balance<USDC>
}

public struct RetailShopCap has key, store {
  id: UID,
  shop: ID
}

// 가게에서 파는 물품
public struct ProductType has store, copy, drop {
  name: String,
  price: u64
}

// 멤버십 타입: Green, Silver, Gold 등등
public struct RetailMembershipType has store, copy, drop {
  name: String,
  require_condition: u64
}

// Stamp와 교환 가능한 Reward인 Coupon의 타입
public struct CouponType has store, copy, drop {
  name: String,
  require_membership: RetailMembershipType,
  require_stamps: u64
}

//==================================
//======== Entry Functions
//==================================

entry fun create_shop(ctx: &mut TxContext) {
  let (shop, cap) = new_shop(ctx);
  transfer::share_object(shop);
  transfer::transfer(cap, ctx.sender());
}

//==================================
//======== Public Functions : Retail Shop
//==================================

public fun new_shop(ctx: &mut TxContext): (RetailShop, RetailShopCap) {
  let mut shop = RetailShop {
    id: object::new(ctx),
    product_types: vec_map::empty(),
    membership_types: vec_map::empty(),
    coupon_types: vec_map::empty(),
    balance: balance::zero()
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

public fun add_product_type(shop: &mut RetailShop, cap: &RetailShopCap, name: String, price: u64) {
  assert!(object::id(shop) == cap.shop, E_NOT_CORRECT_SHOP_CAP);
  // price 은 0보다 커야 함
  assert!(price > 0);
  shop.product_types.insert(name, ProductType{
    name,
    price
  });
}

public fun add_retail_membership_type(shop: &mut RetailShop, cap: &RetailShopCap, name: String, require_condition: u64) {
  assert!(object::id(shop) == cap.shop, E_NOT_CORRECT_SHOP_CAP);
  // require condition 은 0보다 커야 함
  assert!(require_condition > 0);
  shop.membership_types.insert(name, RetailMembershipType{
    name,
    require_condition
  });
}

public fun add_coupon_type(shop: &mut RetailShop, cap: &RetailShopCap, name: String, require_membership_name: String, require_stamps: u64) {
  assert!(object::id(shop) == cap.shop, E_NOT_CORRECT_SHOP_CAP);
  // require stamps 은 0보다 커야 함
  assert!(require_stamps > 0);

  let require_membership = shop.membership_type(require_membership_name);
  shop.coupon_types.insert(name, CouponType{
    name,
    require_membership,
    require_stamps
  });
}

// public fun update_retail_membership_type() {}

//==================================
//======== Package Functions : Retail Shop
//==================================

public (package) fun add_balance(shop: &mut RetailShop, coin: Coin<USDC>) {
  shop.balance.join(coin.into_balance());
}

public (package) fun shop(cap: &RetailShopCap): ID {
  cap.shop
}

public (package) fun product_type(shop: &RetailShop, product_type_name: String): ProductType {
  let product_type = shop.product_types.get(&product_type_name);
  *product_type
}

public (package) fun membership_type(shop: &RetailShop, membership_type_name: String): RetailMembershipType {
  let membership_type = shop.membership_types.get(&membership_type_name);
  *membership_type
}

public (package) fun coupon_type(shop: &RetailShop, coupon_type_name: String): CouponType {
  let coupon_type = shop.coupon_types.get(&coupon_type_name);
  *coupon_type
}

public (package) fun price(product_type: &ProductType): u64 {
  product_type.price
}

public (package) fun require_stamps(coupon_type: &CouponType): u64 {
  coupon_type.require_stamps
}