module exclusuive::point_membership;

use exclusuive::retail_shop::{RetailShop};
use exclusuive::stamp_reward::StampCard;
use sui::dynamic_object_field;

const USDE_FEE_BPS: u64 = 100; // 1 = 0.01%, 100 = 1%

public struct MembershipCard has key, store {
  id: UID,
  shop: ID,
  point_balance: u64,
}

entry fun create_point_membership(shop: &RetailShop, ctx: &mut TxContext) {
  let point_membership = new_point_membership(shop, ctx);
  transfer::transfer(point_membership, ctx.sender());
}

public fun new_point_membership(
  shop: &RetailShop, ctx: &mut TxContext
): MembershipCard {
  MembershipCard {
    id: object::new(ctx),
    shop: object::id(shop),
    point_balance: 0
  }
}

public fun store_stamp_card_to_point_membership(membership_card: &mut MembershipCard, stamp_card: StampCard) {
  let stamp_card_id = object::id(&stamp_card);
  dynamic_object_field::add(&mut membership_card.id, stamp_card_id, stamp_card);
}

public fun borrow_stamp_card(membership_card: &MembershipCard, stamp_card_id: ID): &StampCard {
  dynamic_object_field::borrow(&membership_card.id, stamp_card_id)
}

public fun borrow_mut_stamp_card(membership_card: &mut MembershipCard, stamp_card_id: ID): &mut StampCard {
  dynamic_object_field::borrow_mut(&mut membership_card.id, stamp_card_id)
}