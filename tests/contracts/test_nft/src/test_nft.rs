#![no_std]

use core::ops::Deref;

#[allow(unused_imports)]
use testapi;
use multiversx_sc::imports::*;

static MINTER : &[u8; 32]  = b"nft-minter______________________";
static ALICE : &[u8; 32]   = b"alice___________________________";

#[multiversx_sc::contract]
pub trait TestNft {

    #[init]
    fn init(&self) {
        let minter = ManagedAddress::from(MINTER);
        testapi::create_account(&minter, 0, &BigUint::from(0u64));
        testapi::create_account(&ManagedAddress::from(ALICE), 0, &BigUint::from(0u64));

        let token_id = TokenIdentifier::from_esdt_bytes(b"NFT-123456");
        testapi::add_esdt_role(&minter, &token_id, EsdtLocalRole::NftCreate);
    }

    #[endpoint]
    fn test_create_and_send_nft(&self, royalties: BigUint) {
        testapi::assume(royalties < 10000u64);
        
        let token_id = TokenIdentifier::from_esdt_bytes(b"NFT-123456");
        let minter = ManagedAddress::from(MINTER);
        let alice = ManagedAddress::from(ALICE);
        let amount = BigUint::from(1u64);

        let init_nonce = self.blockchain().get_current_esdt_nft_nonce(&minter, &token_id);

        let name = ManagedBuffer::from(b"NFT 1");
        let uri = ManagedBuffer::from(b"www.mycoolnft.com/nft1.jpg");
        let uris = ManagedVec::from_single_item(uri.clone());

        testapi::start_prank(&minter);
        let _ = self.send().esdt_nft_create(&token_id, &amount, &name, &royalties, &ManagedBuffer::from(b""), b"", &uris);
        testapi::stop_prank();

        let last_nonce = self.blockchain().get_current_esdt_nft_nonce(&minter, &token_id);
        testapi::assert(init_nonce + 1 == last_nonce);

        let token_data = self.blockchain().get_esdt_token_data(&minter, &token_id, last_nonce);
        testapi::assert(token_data.token_type == EsdtTokenType::NonFungible);
        testapi::assert(&token_data.amount == &amount);
        testapi::assert(!token_data.frozen);
        testapi::assert(&token_data.name == &name);
        testapi::assert(&token_data.creator == &minter);
        testapi::assert(&token_data.royalties == &royalties);
        testapi::assert(token_data.uris.len() == 1usize);
        testapi::assert(token_data.uris.get(0usize).deref() == &uri);

        testapi::start_prank(&minter);
        let _ = self.send().direct_esdt(&alice, &token_id, last_nonce, &amount);
        testapi::stop_prank();

        testapi::assert(BigUint::from(0u64) == self.blockchain().get_esdt_balance(&minter, &token_id, last_nonce));

        let token_data = self.blockchain().get_esdt_token_data(&alice, &token_id, last_nonce);
        testapi::assert(token_data.token_type == EsdtTokenType::NonFungible);
        testapi::assert(&token_data.amount == &amount);
        testapi::assert(!token_data.frozen);
        testapi::assert(&token_data.name == &name);
        testapi::assert(&token_data.creator == &minter);
        testapi::assert(&token_data.royalties == &royalties);
        testapi::assert(token_data.uris.len() == 1usize);
        testapi::assert(token_data.uris.get(0usize).deref() == &uri);

    }

}
