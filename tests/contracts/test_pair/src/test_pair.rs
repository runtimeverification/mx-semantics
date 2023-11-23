#![no_std]

use testapi;

multiversx_sc::imports!();

static OWNER : &[u8; 32]                    = b"owner___________________________";
static ALICE : &[u8; 32]                    = b"alice___________________________";
static BOB : &[u8; 32]                      = b"bob_____________________________";
static CHARLIE : &[u8; 32]                  = b"charlie_________________________";
static PAIR : &[u8; 32]                     = b"pair____________________________";
static ROUTER : &[u8; 32]                   = b"router__________________________";
static ROUTER_OWNER : &[u8; 32]             = b"routerowner_____________________";

static FIRST_TOKEN: &[u8]   = b"FIRST-123456";
static SECOND_TOKEN: &[u8]  = b"SECOND-123456";
static LP_TOKEN: &[u8]      = b"LPT-123456";

static TOTAL_FEE_PERCENT: u64    = 1_000u64;
static SPECIAL_FEE_PERCENT: u64  = 500u64;

mod pair_proxy {
    multiversx_sc::imports!();

    pub type AddLiquidityResultType<BigUint> =
        MultiValue3<EsdtTokenPayment<BigUint>, EsdtTokenPayment<BigUint>, EsdtTokenPayment<BigUint>>;
    pub type SwapTokensFixedInputResultType<BigUint> = EsdtTokenPayment<BigUint>;

    #[multiversx_sc::proxy]
    pub trait PairProxy {
        #[payable("*")]
        #[endpoint(addInitialLiquidity)]
        fn add_liquidity(
            &self,
            first_token_amount_min: BigUint,
            second_token_amount_min: BigUint,
        ) -> AddLiquidityResultType<Self::Api>;

        #[payable("*")]
        #[endpoint(swapTokensFixedInput)]
        fn swap_tokens_fixed_input(
            &self,
            token_out: TokenIdentifier,
            amount_out_min: BigUint,
        ) -> SwapTokensFixedInputResultType<Self::Api>;

        #[endpoint(setLpTokenIdentifier)]
        fn set_lp_token_identifier(&self, token_identifier: TokenIdentifier);

        #[view(getReserve)]
        #[storage_mapper("reserve")]
        fn pair_reserve(&self, token_id: &TokenIdentifier) -> SingleValueMapper<BigUint>;

        #[endpoint]
        fn resume(&self);
    }
}

#[multiversx_sc::contract]
pub trait TestMultisigContract {
    #[storage_mapper("firstToken")]
    fn first_token(&self) -> SingleValueMapper<TokenIdentifier>;
    #[storage_mapper("secondToken")]
    fn second_token(&self) -> SingleValueMapper<TokenIdentifier>;
    #[storage_mapper("lp_token")]
    fn lp_token(&self) -> SingleValueMapper<TokenIdentifier>;

    #[storage_mapper("pair_address")]
    fn pair_address(&self) -> SingleValueMapper<ManagedAddress>;


    #[init]
    fn init(&self, code_path: ManagedBuffer) {
        self.init_accounts();
        self.init_tokens();
        self.deploy(&code_path);

        self.set_lp_token(&self.pair_address().get(), &self.lp_token().get());
        self.resume(&self.pair_address().get());
    }

    fn init_tokens(&self) {
        self.first_token().set(TokenIdentifier::from_esdt_bytes(FIRST_TOKEN));
        self.second_token().set(TokenIdentifier::from_esdt_bytes(SECOND_TOKEN));
        self.lp_token().set(TokenIdentifier::from_esdt_bytes(LP_TOKEN));
    }


    fn init_accounts(&self) {
        let owner = ManagedAddress::from(OWNER);
        testapi::create_account(&owner,                                          0, &BigUint::from(0u64));
        testapi::create_account(&ManagedAddress::from(ALICE),                    0, &BigUint::from(0u64));
        testapi::create_account(&ManagedAddress::from(BOB),                      0, &BigUint::from(0u64));
        testapi::create_account(&ManagedAddress::from(CHARLIE),                  0, &BigUint::from(0u64));
        testapi::create_account(&ManagedAddress::from(ROUTER),                   0, &BigUint::from(0u64));
        testapi::create_account(&ManagedAddress::from(ROUTER_OWNER),             0, &BigUint::from(0u64));

        let pair = ManagedAddress::from(PAIR);
        testapi::register_new_address(&owner, 0, &pair);

    }

    fn deploy(&self, code_path: &ManagedBuffer) {

        let mut init_args = ManagedArgBuffer::new();
        init_args.push_arg(self.first_token().get());
        init_args.push_arg(self.second_token().get());
        init_args.push_arg(ManagedAddress::from(ROUTER));
        init_args.push_arg(ManagedAddress::from(ROUTER_OWNER));
        init_args.push_arg(TOTAL_FEE_PERCENT);
        init_args.push_arg(SPECIAL_FEE_PERCENT);
        init_args.push_arg(ManagedAddress::zero());

        let pair = testapi::deploy_contract(
            &ManagedAddress::from(OWNER),
            5000000000000,
            &BigUint::zero(),
            code_path,
            &init_args,
        );
        self.pair_address().set(pair);
    }

    #[endpoint(test_exchange_k)]
    fn test_exchange_k(&self, first_liquidity: BigUint, second_liquidity: BigUint, first_value: BigUint) {
        let pair = ManagedAddress::from(PAIR);
        let alice = ManagedAddress::from(ALICE);
        let liquidity_adder = ManagedAddress::from(BOB);
        
        // make assumptions
        testapi::assume(BigUint::from(1000u32) < first_liquidity);
        testapi::assume(BigUint::from(1000u32) < second_liquidity);

        testapi::set_esdt_balance(&liquidity_adder, &self.first_token().get(), &first_liquidity);
        testapi::set_esdt_balance(&liquidity_adder, &self.second_token().get(), &second_liquidity);
        testapi::set_esdt_balance(&alice, &self.first_token().get(), &first_value);

        self.add_liquidity(
            &pair, &liquidity_adder,
            &first_liquidity, &second_liquidity,
            &first_liquidity, &second_liquidity,
        );

        let first_reserve_initial = self.get_reserve(&pair, &self.first_token().get());
        let second_reserve_initial = self.get_reserve(&pair, &self.second_token().get());

        self.swap_tokens_fixed_input_first(
            &pair, &alice, &first_value, &BigUint::zero()
        );

        let first_reserve_final = self.get_reserve(&pair, &self.first_token().get());
        let second_reserve_final = self.get_reserve(&pair, &self.second_token().get());

        let initial_k = first_reserve_initial.clone() * second_reserve_initial.clone();
        let final_k = first_reserve_final * second_reserve_final;

        testapi::assert(initial_k.clone() <= final_k.clone());
        testapi::assert(final_k <= initial_k + first_reserve_initial + second_reserve_initial);
    }

    fn add_liquidity(
        &self,
        pair_address: &ManagedAddress,
        adder_address: &ManagedAddress,
        first_liquidity: &BigUint,
        second_liquidity: &BigUint,
        first_min: &BigUint,
        second_min: &BigUint,
    ) {
        let mut tokens = ManagedVec::new();
        tokens.push(EsdtTokenPayment::new(self.first_token().get(), 0, first_liquidity.clone()));
        tokens.push(EsdtTokenPayment::new(self.second_token().get(), 0, second_liquidity.clone()));
        testapi::start_prank(&adder_address);

        let mut args = ManagedArgBuffer::new();
        args.push_arg(&first_min);
        args.push_arg(&second_min);

        let _ = self.send_raw().multi_esdt_transfer_execute(
            pair_address,
            &tokens,
            5000000,
            &ManagedBuffer::from(b"addLiquidity"),
            &args,
        );

        // let _: IgnoreValue = self
        //     .pair_proxy(pair_address.clone())
        //     .add_liquidity(first_min, second_min)
        //     .with_multi_token_transfer(tokens)
        //     .execute_on_dest_context();
        testapi::stop_prank();
    }

    fn swap_tokens_fixed_input_first(
        &self,
        pair_address: &ManagedAddress,
        user_address: &ManagedAddress,
        first_amount: &BigUint,
        min_second: &BigUint,
    ) {
        testapi::start_prank(&user_address);
        let _:IgnoreValue = self
            .pair_proxy(pair_address.clone())
            .swap_tokens_fixed_input(self.second_token().get(), min_second)
            .with_esdt_transfer((self.first_token().get(), 0, first_amount.clone()))
            .execute_on_dest_context();
        testapi::stop_prank();
    }

    fn set_lp_token(
        &self,
        pair_address: &ManagedAddress,
        token_id: &TokenIdentifier,
    ) {
        testapi::start_prank(&ManagedAddress::from(ROUTER));
        let _: IgnoreValue = self
            .pair_proxy(pair_address.clone())
            .set_lp_token_identifier(token_id)
            .execute_on_dest_context();
        testapi::stop_prank();
    }

    fn get_reserve(
        &self,
        pair_address: &ManagedAddress,
        token_id: &TokenIdentifier,
    ) -> BigUint {
        let result = self
            .pair_proxy(pair_address.clone())
            .pair_reserve(token_id)
            .execute_on_dest_context();
        result
    }

    fn resume(
        &self,
        pair_address: &ManagedAddress,
    ) {
        testapi::start_prank(&ManagedAddress::from(ROUTER));
        let _: IgnoreValue = self
            .pair_proxy(pair_address.clone())
            .resume()
            .execute_on_dest_context();
        testapi::stop_prank();
    }

    #[proxy]
    fn pair_proxy(&self, sc_address: ManagedAddress) -> pair_proxy::Proxy<Self::Api>;
}
