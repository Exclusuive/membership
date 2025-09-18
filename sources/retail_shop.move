module exclusuive::retail_shop;

use std::string::String;
use sui::vec_map::{Self, VecMap};
use sui::balance::{Self, Balance};
use sui::coin::{Coin};
use sui::event;

use usdc::usdc::USDC;
use exclusuive::usde::USDE;

const GUEST: vector<u8> = b"guest";

const E_NOT_CORRECT_SHOP_CAP: u64 = 1;

//==================================
//======== Structs
//==================================

// 가게마다 하나 씩 있는 RetailShop 오브젝트
public struct RetailShop has key {
  id: UID,
  name: String,
  product_types: VecMap<String, ProductType>,
  membership_types: VecMap<String, RetailMembershipType>,
  coupon_types: VecMap<String, CouponType>,
  balance_usdc: Balance<USDC>,
  balance_usde: Balance<USDE>
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
  coupon_kind: CouponKind,
  product_type: Option<ProductType>,
  amount: u64,
  require_membership: RetailMembershipType,
  require_stamps: u64
}

public enum CouponKind has store, copy, drop {
  EXCHANGE,
  DISCOUNT
}

public struct RetailShopCreatedEvent has copy, drop {
  shop: ID,
  name: String,
  created_at: u64
}

//==================================
//======== Entry Functions
//==================================

/// Retail Shop Owner는 자신만의 RetailShop Shared Object를 생성 가능
entry fun create_shop(name: String, ctx: &mut TxContext) {
  let (shop, cap) = new_shop(name, ctx);
  transfer::share_object(shop);
  transfer::transfer(cap, ctx.sender());
}

//==================================
//======== Public Functions : Retail Shop
//==================================

public fun new_shop(
  name: String, ctx: &mut TxContext): (RetailShop, RetailShopCap
) {
  let mut shop = RetailShop {
    id: object::new(ctx),
    name,
    product_types: vec_map::empty(),
    membership_types: vec_map::empty(),
    coupon_types: vec_map::empty(),
    balance_usdc: balance::zero(),
    balance_usde: balance::zero()
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

  event::emit(RetailShopCreatedEvent { 
    shop: object::id(&shop),
    name,
    created_at: ctx.epoch_timestamp_ms()
  });

  (shop, cap)
}

/// RetailShop 메터데이터 설정: ProductType
public fun add_product_type(
  shop: &mut RetailShop, cap: &RetailShopCap, name: String, price: u64
) {
  assert!(object::id(shop) == cap.shop, E_NOT_CORRECT_SHOP_CAP);
  // price 은 0보다 커야 함
  assert!(price > 0);
  shop.product_types.insert(name, ProductType{
    name,
    price
  });
}

/// RetailShop 메터데이터 설정: MembershipType
public fun add_retail_membership_type(
  shop: &mut RetailShop, cap: &RetailShopCap, name: String, require_condition: u64
) {
  assert!(object::id(shop) == cap.shop, E_NOT_CORRECT_SHOP_CAP);
  // require condition 은 0보다 커야 함
  assert!(require_condition > 0);
  shop.membership_types.insert(name, RetailMembershipType{
    name,
    require_condition
  });
}

/// RetailShop 메터데이터 설정: CouponType
public fun add_exchange_coupon_type(
  shop: &mut RetailShop, cap: &RetailShopCap, name: String, product_name: String, require_membership_name: String, require_stamps: u64
) {
  assert!(object::id(shop) == cap.shop, E_NOT_CORRECT_SHOP_CAP);
  // require stamps 은 0보다 커야 함
  assert!(require_stamps > 0);

  let require_membership = shop.membership_type(require_membership_name);
  let product_type = shop.product_type(product_name);
  shop.coupon_types.insert(name, CouponType{
    coupon_kind: CouponKind::EXCHANGE,
    product_type: option::some(product_type),
    amount: 0,
    require_membership,
    require_stamps
  });
}

public fun add_discount_coupon_type(
  shop: &mut RetailShop, cap: &RetailShopCap, name: String, amount: u64, require_membership_name: String, require_stamps: u64
) {
  assert!(object::id(shop) == cap.shop, E_NOT_CORRECT_SHOP_CAP);
  // require stamps 은 0보다 커야 함
  assert!(require_stamps > 0);

  let require_membership = shop.membership_type(require_membership_name);
  shop.coupon_types.insert(name, CouponType{
    coupon_kind: CouponKind::DISCOUNT,
    product_type: option::none(),
    amount,
    require_membership,
    require_stamps
  });
}

// public fun update_retail_membership_type() {}

//==================================
//======== Package Functions : Retail Shop
//==================================

public (package) fun add_balance_usdc(shop: &mut RetailShop, coin: Coin<USDC>) {
  shop.balance_usdc.join(coin.into_balance());
}

public (package) fun add_balance_usde(shop: &mut RetailShop, coin: Coin<USDE>) {
  shop.balance_usde.join(coin.into_balance());
}

public (package) fun withdraw_all_usdc(shop: &mut RetailShop): Balance<USDC> {
  shop.balance_usdc.withdraw_all()
}

public (package) fun withdraw_all_usde(shop: &mut RetailShop): Balance<USDE> {
  shop.balance_usde.withdraw_all()
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

public (package) fun coupon_value(coupon_type: &CouponType): u64 {
  match (coupon_type.coupon_kind) {
    CouponKind::EXCHANGE => coupon_type.product_type.borrow().price,
    CouponKind::DISCOUNT => coupon_type.amount
  }
}

public (package) fun price(product_type: &ProductType): u64 {
  product_type.price
}

public (package) fun require_stamps(coupon_type: &CouponType): u64 {
  coupon_type.require_stamps
}