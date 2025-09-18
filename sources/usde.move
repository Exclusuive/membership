module exclusuive::usde;

use std::ascii::string;
use sui::url;
use sui::coin::{Self, Coin};
use sui::dynamic_field;
use sui::balance::{Self, Balance};
use usdc::usdc::USDC;

/// The One-Time Witness struct for the USDC coin.
public struct USDE has drop {}

public struct UsdePool has key {
  id: UID,
  balance_usdc: Balance<USDC>
}

public struct TreasuryCapKey has store, copy, drop{}

// === Constants ===

const DESCRIPTION: vector<u8> = b"USDE is pegging with USDC 1:1";
const ICON_URL: vector<u8> = b"icon_url";

#[allow(lint(share_owned))]
/// Initializes
fun init(
  witness: USDE, ctx: &mut TxContext
) {
  let (treasury_cap,  metadata) = coin::create_currency(
    witness,
    6,               // decimals
    b"USDE",         // symbol
    b"USDE",         // name
    DESCRIPTION,
    option::some(url::new_unsafe(string(ICON_URL))),
    ctx
  );

  let mut pool = UsdePool {
    id: object::new(ctx),
    balance_usdc: balance::zero()
  };

  dynamic_field::add(&mut pool.id, TreasuryCapKey{}, treasury_cap);

  transfer::public_share_object(metadata);
  transfer::share_object(pool);
}

public fun exchange_usdc_to_usde(
  pool: &mut UsdePool, coin: Coin<USDC>, ctx: &mut TxContext,
): Coin<USDE> {
  let value = coin.value();
  pool.balance_usdc.join(coin.into_balance());

  let cap = dynamic_field::borrow_mut(&mut pool.id, TreasuryCapKey{});
  coin::mint<USDE>(cap, value, ctx)
}

public fun exchange_usde_to_usdc(
  pool: &mut UsdePool, coin: Coin<USDE>, ctx: &mut TxContext,
): Coin<USDC> {
  let cap = dynamic_field::borrow_mut(&mut pool.id, TreasuryCapKey{});
  let value = coin::burn<USDE>(cap, coin);
  pool.balance_usdc.split(value).into_coin(ctx)
}