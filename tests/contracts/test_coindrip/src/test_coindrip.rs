#![no_std]

use testapi;

multiversx_sc::imports!();
multiversx_sc::derive_imports!();

static OWNER : &[u8; 32]                    = b"owner___________________________";
static COINDRIP : &[u8; 32]                 = b"coindrip________________________";

static ALICE : &[u8; 32]                    = b"alice___________________________";
static BOB : &[u8; 32]                      = b"bob_____________________________";

static FIRST_TOKEN: &[u8]   = b"FIRST-123456";

#[derive(ManagedVecItem, Clone)]
pub struct TokenNonceSummary<M: ManagedTypeApi> {
  pub token_id: EgldOrEsdtTokenIdentifier<M>,
  pub nonce: u64,
  pub amount: BigUint<M>
}

#[derive(TopEncode, TopDecode, NestedEncode, NestedDecode, TypeAbi)]
pub struct BalancesAfterCancel<M: ManagedTypeApi> {
  pub sender_balance: BigUint<M>,
  pub recipient_balance: BigUint<M>
}

#[derive(TopEncode, TopDecode, TypeAbi)]
pub struct Stream<M: ManagedTypeApi> {
  pub sender: ManagedAddress<M>,
  pub recipient: ManagedAddress<M>,
  pub payment_token: EgldOrEsdtTokenIdentifier<M>,
  pub payment_nonce: u64,
  pub deposit: BigUint<M>,
  pub claimed_amount: BigUint<M>,
  pub can_cancel: bool,
  pub start_time: u64,
  pub end_time: u64,
  pub balances_after_cancel: Option<BalancesAfterCancel<M>>
}

mod coindrip_proxy {
    multiversx_sc::imports!();
    use crate::Stream;

    #[multiversx_sc::proxy]
    pub trait CoindripProxy {
        #[payable("*")]
        #[endpoint(createStream)]
        fn create_stream(
            &self,
            recipient: ManagedAddress,
            start_time: u64,
            end_time: u64,
            _can_cancel: OptionalValue<bool>
        );

        #[view(recipientBalance)]
        fn recipient_balance(&self, stream_id: u64) -> BigUint;

        #[view(senderBalance)]
        fn sender_balance(&self, stream_id: u64) -> BigUint;

        /// This endpoint can be used by the recipient of the stream to claim the stream amount of tokens
        #[endpoint(claimFromStream)]
        fn claim_from_stream(
            &self,
            stream_id: u64
        );

        #[endpoint(cancelStream)]
        fn cancel_stream(
            &self,
            stream_id: u64,
            _with_claim: OptionalValue<bool>
        );

        #[endpoint(claimFromStreamAfterCancel)]
        fn claim_from_stream_after_cancel(
            &self,
            stream_id: u64
        );

        #[view(getStreamById)]
        #[storage_mapper("streamById")]
        fn stream_by_id(&self, stream_id: u64) -> SingleValueMapper<Stream<Self::Api>>;

        #[view(getStreamListByAddress)]
        #[storage_mapper("streamsList")]
        fn streams_list(&self, address: &ManagedAddress) -> UnorderedSetMapper<u64>;

        #[view(getLastStreamId)]
        #[storage_mapper("lastStreamId")]
        fn last_stream_id(&self) -> SingleValueMapper<u64>;
    }
}


#[multiversx_sc::contract]
pub trait TestCoindripContract {
    #[storage_mapper("firstToken")]
    fn first_token(&self) -> SingleValueMapper<TokenIdentifier>;

    #[storage_mapper("owner")]
    fn owner(&self) -> SingleValueMapper<ManagedAddress>;
    #[storage_mapper("alice")]
    fn alice(&self) -> SingleValueMapper<ManagedAddress>;
    #[storage_mapper("bob")]
    fn bob(&self) -> SingleValueMapper<ManagedAddress>;

    #[init]
    fn init(&self, code_path: ManagedBuffer) {
        self.init_accounts();
        self.init_tokens();

        self.deploy(&code_path);

        self.verify_invariant();
    }


    fn init_tokens(&self) {
        self.first_token().set(TokenIdentifier::from_esdt_bytes(FIRST_TOKEN));
    }


    fn init_accounts(&self) {
        self.owner().set(ManagedAddress::from(OWNER));
        self.alice().set(ManagedAddress::from(ALICE));
        self.bob().set(ManagedAddress::from(BOB));
        testapi::create_account(&self.owner().get(),     0, &BigUint::from(0u64));
        testapi::create_account(&self.alice().get(),   0, &BigUint::from(0u64));
        testapi::create_account(&self.bob().get(),     0, &BigUint::from(0u64));

        let coindrip = ManagedAddress::from(COINDRIP);
        testapi::register_new_address(&self.owner().get(), 0, &coindrip);
    }

    fn deploy(&self, code_path: &ManagedBuffer) {
        let init_args = ManagedArgBuffer::new();

        testapi::deploy_contract(
            &self.owner().get(),
            5000000000000,
            &BigUint::zero(),
            code_path,
            &init_args,
        );
    }

    #[endpoint(test_all_tokens_claimed)]
    fn test_all_tokens_claimed(
        &self,
        value: BigUint,

        create_timestamp: u64,
        delta_start_time: u32,
        delta_first_claim_timestamp: u32,
        delta_end_time: u32,
        delta_last_claim_timestamp: u32,
    ) {
        testapi::assume(BigUint::zero() < value);
        testapi::assume(value < self.get_max_mint_value());
        testapi::assume(0u64 < create_timestamp);
        testapi::assume(create_timestamp < u64::MAX - 4 * u64::from(u32::MAX));

        let start_time = create_timestamp + u64::from(delta_start_time);
        let first_claim_timestamp = start_time + u64::from(delta_first_claim_timestamp);
        let end_time = first_claim_timestamp + u64::from(delta_end_time);
        let last_claim_timestamp = end_time + u64::from(delta_last_claim_timestamp);

        testapi::assume(create_timestamp < start_time);
        testapi::assume(start_time < first_claim_timestamp);
        testapi::assume(first_claim_timestamp < end_time);
        testapi::assume(end_time < last_claim_timestamp);

        let first_token = EgldOrEsdtTokenIdentifier::esdt(self.first_token().get());

        self.verify_invariant();

        testapi::set_esdt_balance(
            &self.alice().get(), &self.first_token().get(), &value
        );

        testapi::assert(self.get_alice_balance(&first_token, 0) == value);
        testapi::assert(self.get_bob_balance(&first_token, 0) == 0);
        testapi::assert(self.get_coindrip_balance(&first_token, 0) == 0);

        testapi::set_block_timestamp(create_timestamp);
        self.create_stream(
            &self.alice().get(),
            &self.bob().get(),
            &self.first_token().get(),
            &value,
            start_time,
            end_time,
            true
        );
        let stream_id = self.last_stream_id();

        testapi::assert(self.get_alice_balance(&first_token, 0) == 0);
        testapi::assert(self.get_bob_balance(&first_token, 0) == 0);
        testapi::assert(&self.get_coindrip_balance(&first_token, 0) == &value);

        testapi::set_block_timestamp(first_claim_timestamp);

        // do not claim if the expected value is 0
        let expected_first_claim_value = &value * (first_claim_timestamp - start_time) / (end_time - start_time);
        if expected_first_claim_value > 0u64 {
            self.claim_from_stream(&self.bob().get(), stream_id);
        }

        let first_claim_value = self.get_bob_balance(&first_token, 0);

        testapi::assert(expected_first_claim_value == first_claim_value);
        testapi::assert(self.get_alice_balance(&first_token, 0) == 0);
        testapi::assert(self.get_bob_balance(&first_token, 0) == first_claim_value);
        testapi::assert(self.get_coindrip_balance(&first_token, 0) == &value - &first_claim_value);

        testapi::set_block_timestamp(last_claim_timestamp);
        // do not claim if the expected value is 0
        let expected_last_claim_value = &value - &first_claim_value;
        if expected_last_claim_value > 0u64 {
            self.claim_from_stream(&self.bob().get(), stream_id);
        }

        testapi::assert(self.get_alice_balance(&first_token, 0) == 0);
        testapi::assert(self.get_bob_balance(&first_token, 0) == value);
        testapi::assert(self.get_coindrip_balance(&first_token, 0) == 0);
    }

    // #[endpoint(test_preserves_invariant)]
    // fn test_preserves_invariant(&self, value: BigUint) {
    // }

    fn verify_invariant(&self) {
        let mut available:ManagedVec<TokenNonceSummary<Self::Api>> = ManagedVec::new();//<Self::Api, TokenNonceSummary>::new();
        let last_stream_id = self.last_stream_id();
        let current_timestamp = self.blockchain().get_block_timestamp();

        for i in 1u64..last_stream_id + 1 {
            let stream = self.stream_by_id(i);
            testapi::assert(&stream.claimed_amount < &(&stream.deposit + 1u64));
            let current_available = stream.deposit - &stream.claimed_amount;
            match stream.balances_after_cancel {
                Some(balances) => {
                    testapi::assert(stream.can_cancel);
                    testapi::assert(current_available == balances.sender_balance + balances.recipient_balance);
                },
                None => {}
            }
            if current_timestamp < stream.start_time {
                testapi::assert(BigUint::zero() == stream.claimed_amount)
            }

            if current_available > 0u64 {
                let mut found = false;
                for j in 0usize..available.len() {
                    let mut token_summary = available.get(j);
                    if token_summary.token_id == stream.payment_token && token_summary.nonce == stream.payment_nonce {
                        found = true;
                        token_summary.amount += &current_available;
                        available.set(j, &token_summary).unwrap();
                        break;
                    }
                }
                if !found {
                    let token_summary = TokenNonceSummary{
                        token_id: stream.payment_token,
                        nonce: stream.payment_nonce,
                        amount: current_available,
                    };
                    available.push(token_summary);
                }
            }
        }

        for summary in available.iter() {
            let actual = self.get_coindrip_balance(&summary.token_id, summary.nonce);
            testapi::assert(actual == summary.amount);
        }
    }

    fn create_stream(
        &self,
        from: &ManagedAddress,
        to: &ManagedAddress,
        token_identifier: &TokenIdentifier,
        amount: &BigUint,
        start_time:u64,
        end_time:u64,
        can_cancel: bool
    ) {
        testapi::start_prank(from);
        let _: IgnoreValue = self
            .coindrip_proxy(ManagedAddress::from(COINDRIP))
            .create_stream(to, start_time, end_time, OptionalValue::Some(can_cancel))
            .with_esdt_transfer((token_identifier.clone(), 0u64, amount.clone()))
            .execute_on_dest_context();
        testapi::stop_prank();
    }

    fn claim_from_stream(&self, user: &ManagedAddress, id:u64) {
        testapi::start_prank(user);
        let _: IgnoreValue = self
            .coindrip_proxy(ManagedAddress::from(COINDRIP))
            .claim_from_stream(id)
            .execute_on_dest_context();
        testapi::stop_prank();
    }

    fn stream_by_id(&self, id:u64) -> Stream<Self::Api> {
        self.coindrip_proxy(ManagedAddress::from(COINDRIP))
            .stream_by_id(id)
            .execute_on_dest_context()
    }

    fn last_stream_id(&self) -> u64 {
        self.coindrip_proxy(ManagedAddress::from(COINDRIP))
            .last_stream_id()
            .execute_on_dest_context()
    }

    fn get_coindrip_balance(&self, token_id: &EgldOrEsdtTokenIdentifier, nonce: u64) -> BigUint {
        self.get_balance(&ManagedAddress::from(COINDRIP), token_id, nonce)
    }

    fn get_alice_balance(&self, token_id: &EgldOrEsdtTokenIdentifier, nonce: u64) -> BigUint {
        self.get_balance(&self.alice().get(), token_id, nonce)
    }

    fn get_bob_balance(&self, token_id: &EgldOrEsdtTokenIdentifier, nonce: u64) -> BigUint {
        self.get_balance(&self.bob().get(), token_id, nonce)
    }

    fn get_balance(&self, address: &ManagedAddress, token_id: &EgldOrEsdtTokenIdentifier, nonce: u64) -> BigUint {
        if let Some(esdt_id) = token_id.as_esdt_option() {
            self.blockchain().get_esdt_balance(address, &esdt_id, nonce)
        } else {
            self.blockchain().get_balance(address)    
        }
    }

    fn get_max_mint_value(&self) -> BigUint {
      // 800 = 11 0010 000
      // 800 = 2^5 + 2^8 + 2^9
      // 2^800 = 2^512 * 2^256 * 2^32
      let a32 = BigUint::from(4294967296u64);
      let a64 = a32.clone() * a32.clone();
      let a128 = a64.clone() * a64;
      let a256 = a128.clone() * a128;
      let a512 = a256.clone() * a256.clone();
      a32 * a256 * a512
  }

  #[proxy]
    fn coindrip_proxy(&self, sc_address: ManagedAddress) -> coindrip_proxy::Proxy<Self::Api>;
}
