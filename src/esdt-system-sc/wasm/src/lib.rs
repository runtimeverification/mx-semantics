// Code generated by the multiversx-sc multi-contract system. DO NOT EDIT.

////////////////////////////////////////////////////
////////////////// AUTO-GENERATED //////////////////
////////////////////////////////////////////////////

// Init:                                 1
// Endpoints:                            6
// Async Callback (empty):               1
// Total number of exported functions:   8

#![no_std]
#![allow(internal_features)]
#![feature(lang_items)]

multiversx_sc_wasm_adapter::allocator!();
multiversx_sc_wasm_adapter::panic_handler!();

multiversx_sc_wasm_adapter::endpoints! {
    esdt_system_sc
    (
        init => init
        issue => issue_fungible
        issueNonFungible => issue_non_fungible
        issueSemiFungible => issue_semi_fungible
        registerMetaESDT => issue_meta_esdt
        setSpecialRole => set_special_roles
        registerAndSetAllRoles => register_and_set_all_roles
    )
}

multiversx_sc_wasm_adapter::async_callback_empty! {}
