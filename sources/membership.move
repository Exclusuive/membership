module exclusuive::membership;

use std::string::String;
use sui::dynamic_field as df;
use sui::dynamic_object_field as dof;

const ENotAuthorized: u64 = 2;

public struct MembershipHub has key, store {
    id: UID,
}

public struct HubCap has key, store {
    id: UID,
    hub_id: ID,
}

public struct Membership has key, store {
    id: UID,
    hub_id: ID,
    `type`: MembershipType,
    created_at: u64,
    is_active: bool,
}

public struct MembershipCap has key, store {
    id: UID,
    hub_id: ID,
    membership_id: ID,
}

public struct MembershipType has copy, drop, store {
    name: String,
    description: String,
    imgUrl: String,
    `type`: String,
}
public struct HubKey<phantom T> has copy, drop, store {
    hub_id: ID,
    name: Option<String>,
    id: Option<ID>,
}

public fun new_hub(ctx: &mut TxContext): (MembershipHub, HubCap) {
    let hub = MembershipHub { id: object::new(ctx) };
    let hub_cap = HubCap { id: object::new(ctx), hub_id: object::id(&hub) };
    (hub, hub_cap)
}

#[allow(lint(self_transfer))]
public fun create_membership_hub(ctx: &mut TxContext) {
    let (hub, hub_cap) = new_hub(ctx);
    transfer::share_object(hub);
    transfer::transfer(hub_cap, ctx.sender());
}

public fun new_membership_type(
    hub: &mut MembershipHub,
    cap: &HubCap,
    name: String,
    description: String,
    imgUrl: String,
    type_name: String,
) {
    let hub_id = object::id(hub);
    assert!(cap.hub_id == hub_id, ENotAuthorized);
    let membership_type = MembershipType { name, description, imgUrl, `type`: type_name };
    df::add(
        &mut hub.id,
        HubKey<MembershipType> { hub_id, name: option::some(name), id: option::none() },
        membership_type,
    );
}

public fun new_membership(
    hub: &mut MembershipHub,
    cap: &HubCap,
    name: String,
    ctx: &mut TxContext,
): MembershipCap {
    let hub_id = object::id(hub);
    assert!(cap.hub_id == hub_id, ENotAuthorized);
    let membership_type: &MembershipType = df::borrow(
        &hub.id,
        HubKey<MembershipType> { hub_id, name: option::some(name), id: option::none() },
    );
    let membership = Membership {
        id: object::new(ctx),
        hub_id,
        `type`: *membership_type,
        created_at: ctx.epoch_timestamp_ms(),
        is_active: true,
    };
    let membership_cap = MembershipCap {
        id: object::new(ctx),
        hub_id,
        membership_id: object::id(&membership),
    };
    dof::add(
        &mut hub.id,
        HubKey<Membership> {
            hub_id,
            name: option::none(),
            id: option::some(object::id(&membership)),
        },
        membership,
    );
    membership_cap
}

public fun borrow_mut_membership_by_user(
    hub: &mut MembershipHub,
    cap: &MembershipCap,
): &mut Membership {
    let hub_id = object::id(hub);
    assert!(cap.hub_id == hub_id, ENotAuthorized);
    let membership: &mut Membership = dof::borrow_mut(
        &mut hub.id,
        HubKey<Membership> { hub_id, name: option::none(), id: option::some(cap.membership_id) },
    );
    assert!(membership.is_active, ENotAuthorized);
    membership
}

public fun borrow_membership_by_user(hub: &mut MembershipHub, cap: &MembershipCap): &Membership {
    let hub_id = object::id(hub);
    assert!(cap.hub_id == hub_id, ENotAuthorized);
    let membership: &Membership = dof::borrow(
        &hub.id,
        HubKey<Membership> { hub_id, name: option::none(), id: option::some(cap.membership_id) },
    );
    assert!(membership.is_active, ENotAuthorized);
    membership
}

public fun borrow_mut_membership_by_admin(
    hub: &mut MembershipHub,
    cap: &HubCap,
    membership_id: ID,
): &mut Membership {
    let hub_id = object::id(hub);
    assert!(cap.hub_id == hub_id, ENotAuthorized);
    dof::borrow_mut(
        &mut hub.id,
        HubKey<Membership> { hub_id, name: option::none(), id: option::some(membership_id) },
    )
}

public fun borrow_membership_by_admin(
    hub: &mut MembershipHub,
    cap: &HubCap,
    membership_id: ID,
): &Membership {
    let hub_id = object::id(hub);
    assert!(cap.hub_id == hub_id, ENotAuthorized);
    dof::borrow(
        &hub.id,
        HubKey<Membership> { hub_id, name: option::none(), id: option::some(membership_id) },
    )
}

public fun deactivate_membership(hub: &mut MembershipHub, cap: &HubCap, membership_id: ID) {
    let hub_id = object::id(hub);
    assert!(cap.hub_id == hub_id, ENotAuthorized);
    let membership: &mut Membership = dof::borrow_mut(
        &mut hub.id,
        HubKey<Membership> { hub_id, name: option::none(), id: option::some(membership_id) },
    );
    membership.is_active = false;
}

public fun activate_membership(hub: &mut MembershipHub, cap: &HubCap, membership_id: ID) {
    let hub_id = object::id(hub);
    assert!(cap.hub_id == hub_id, ENotAuthorized);
    let membership: &mut Membership = dof::borrow_mut(
        &mut hub.id,
        HubKey<Membership> { hub_id, name: option::none(), id: option::some(membership_id) },
    );
    membership.is_active = true;
}

public fun delete_membership(hub: &mut MembershipHub, cap: &HubCap, membership_id: ID) {
    let hub_id = object::id(hub);
    assert!(cap.hub_id == hub_id, ENotAuthorized);
    let membership = dof::remove(
        &mut hub.id,
        HubKey<Membership> { hub_id, name: option::none(), id: option::some(membership_id) },
    );
    let Membership { id, .. } = membership;
    object::delete(id);
}

public(package) fun check_cap(hub: &MembershipHub, cap: &HubCap) {
    assert!(object::id(hub) == cap.hub_id, ENotAuthorized);
}

public(package) fun get_hub_uid(hub: &MembershipHub): &UID {
    &hub.id
}

public(package) fun get_mut_hub_uid(hub: &mut MembershipHub): &mut UID {
    &mut hub.id
}

public(package) fun get_membership_uid(membership: &Membership): &UID {
    &membership.id
}

public(package) fun get_mut_membership_id(membership: &mut Membership): &mut UID {
    &mut membership.id
}
