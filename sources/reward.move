module exclusuive::reward;

use exclusuive::membership::{
    Membership,
    MembershipHub,
    HubCap,
    check_cap,
    get_mut_hub_uid,
    get_mut_membership_id,
    get_membership_uid
};
use std::string::String;
use sui::dynamic_field as df;

public struct Points has drop, store {
    number: u64,
}

public struct Stamp has key, store {
    id: UID,
    name: String,
}

public struct StampType has copy, drop, store {
    name: String,
}

public struct RewardKey<phantom T> has copy, drop, store {
    hub_id: ID,
    name: Option<String>,
    id: Option<ID>,
}

public fun new_stamp_type(hub: &mut MembershipHub, cap: &HubCap, name: String) {
    let hub_id = object::id(hub);
    check_cap(hub, cap);
    df::add(
        get_mut_hub_uid(hub),
        RewardKey<StampType> { hub_id, name: option::some(name), id: option::none() },
        StampType { name },
    );
}

public fun new_stamp(
    hub: &mut MembershipHub,
    cap: &HubCap,
    name: String,
    membership: &mut Membership,
    ctx: &mut TxContext,
) {
    let hub_id = object::id(hub);
    check_cap(hub, cap);

    let stamp = Stamp { id: object::new(ctx), name };
    df::add(
        get_mut_membership_id(membership),
        RewardKey<Stamp> { hub_id, name: option::some(name), id: option::some(object::id(&stamp)) },
        stamp,
    );
}

public fun new_point(
    hub: &mut MembershipHub,
    cap: &HubCap,
    membership: &mut Membership,
    amount: u64,
) {
    let hub_id = object::id(hub);
    check_cap(hub, cap);
    let points = Points { number: amount };

    let reward_key = RewardKey<Points> {
        hub_id,
        name: option::some(std::string::utf8(b"points")),
        id: option::none(),
    };

    if (df::exists_(get_membership_uid(membership), reward_key)) {
        let points_ref: &mut Points = df::borrow_mut(get_mut_membership_id(membership), reward_key);
        points_ref.number = points_ref.number + amount;
    } else {
        df::add(get_mut_membership_id(membership), reward_key, points);
    }
}
