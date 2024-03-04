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
static MAX_PERCENTAGE: u64       = 100_000u64;

mod pair_proxy {
    multiversx_sc::imports!();

    pub type AddLiquidityResultType<BigUint> =
        MultiValue3<EsdtTokenPayment<BigUint>, EsdtTokenPayment<BigUint>, EsdtTokenPayment<BigUint>>;
    pub type SwapTokensFixedInputResultType<BigUint> = EsdtTokenPayment<BigUint>;

    #[multiversx_sc::proxy]
    pub trait PairProxy {
        #[payable("*")]
        #[endpoint(addInitialLiquidity)]
        fn add_initial_liquidity(&self) -> AddLiquidityResultType<Self::Api>;

        #[payable("*")]
        #[endpoint(addLiquidity)]
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
pub trait TestPairContract {
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

        testapi::add_esdt_role(&self.pair_address().get(), &self.lp_token().get(), EsdtLocalRole::Mint);
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

        let max_liquidity = self.get_max_mint_value() + 1000u32;
        
        // make assumptions
        testapi::assume(BigUint::from(1000u32) < first_liquidity);
        testapi::assume(BigUint::from(1000u32) < second_liquidity);
        testapi::assume(first_liquidity < max_liquidity);
        testapi::assume(second_liquidity < max_liquidity);

        testapi::assume(BigUint::from(2u32) < first_value);
        let first_no_percent = first_value.clone() * (MAX_PERCENTAGE - TOTAL_FEE_PERCENT);
        testapi::assume((first_liquidity.clone() * MAX_PERCENTAGE + first_no_percent.clone()) < second_liquidity.clone() * first_no_percent );

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
            &pair, &alice, &first_value, &BigUint::from(1u64)
        );

        let first_reserve_final = self.get_reserve(&pair, &self.first_token().get());
        let second_reserve_final = self.get_reserve(&pair, &self.second_token().get());

        let total_fee = first_value.clone() * TOTAL_FEE_PERCENT / MAX_PERCENTAGE;
        let special_fee = BigUint::zero();  // Fee not enabled
                                            // first_value * SPECIAL_FEE_PERCENT / MAX_PERCENTAGE;
        let initial_k = first_reserve_initial.clone() * second_reserve_initial.clone();
        let final_k = first_reserve_final.clone() * second_reserve_final.clone();

        require!(initial_k.clone() <= final_k.clone(), "K decreased!");
        let condition = final_k <= initial_k.clone() + first_reserve_final.clone() + (total_fee.clone() - special_fee.clone() + 1u64) * second_reserve_final.clone();
        require!(condition, "K grew too much!");
        testapi::assert(initial_k.clone() <= final_k.clone());
        // testapi::assert(final_k <= initial_k + first_reserve_initial + second_reserve_initial);
    }

    #[endpoint(test_add_liquidity)]
    fn test_add_liquidity(&self, first_liquidity: BigUint, second_liquidity: BigUint, first_value: BigUint) {
        let pair = ManagedAddress::from(PAIR);
        let alice = ManagedAddress::from(ALICE);
        let liquidity_adder = ManagedAddress::from(BOB);

        let max_liquidity = self.get_max_mint_value() + 1000u32;

        // make assumptions
        testapi::assume(BigUint::from(1000u32) < first_liquidity);
        testapi::assume(BigUint::from(1000u32) < second_liquidity);
        testapi::assume(first_liquidity < max_liquidity);
        testapi::assume(second_liquidity < max_liquidity);

        testapi::assume(BigUint::from(2u32) < first_value);
        let first_no_percent = first_value.clone() * (MAX_PERCENTAGE - TOTAL_FEE_PERCENT);
        testapi::assume((first_liquidity.clone() * MAX_PERCENTAGE + first_no_percent.clone()) < second_liquidity.clone() * first_no_percent );

        testapi::set_esdt_balance(&liquidity_adder, &self.first_token().get(), &first_liquidity);
        testapi::set_esdt_balance(&liquidity_adder, &self.second_token().get(), &second_liquidity);
        testapi::set_esdt_balance(&alice, &self.first_token().get(), &first_value);

        self.add_liquidity(
            &pair, &liquidity_adder,
            &first_liquidity, &second_liquidity,
            &first_liquidity, &second_liquidity,
        );

        let lp_tokens = self.blockchain().get_esdt_balance(&liquidity_adder, &self.lp_token().get(), 0);
        let first_reserve_initial = self.get_reserve(&pair, &self.first_token().get());
        let second_reserve_initial = self.get_reserve(&pair, &self.second_token().get());

        testapi::assert(first_liquidity == first_reserve_initial);
        testapi::assert(second_liquidity == second_reserve_initial);
        if first_liquidity < second_liquidity {
          testapi::assert(lp_tokens == first_reserve_initial - 1000u64);
        } else {
          testapi::assert(lp_tokens == second_reserve_initial - 1000u64);
        }
    }

    #[endpoint(test_swap)]
    fn test_swap(&self, first_liquidity: BigUint, second_liquidity: BigUint, first_value: BigUint) {
        let pair = ManagedAddress::from(PAIR);
        let alice = ManagedAddress::from(ALICE);

        let max_liquidity = self.get_max_mint_value() + 1000u32;

        // make assumptions
        testapi::assume(BigUint::from(1000u32) < first_liquidity);
        testapi::assume(BigUint::from(1000u32) < second_liquidity);
        testapi::assume(first_liquidity < second_liquidity);
        testapi::assume(first_liquidity < max_liquidity);
        testapi::assume(second_liquidity < max_liquidity);

        testapi::assume(BigUint::from(2u32) < first_value);
        let first_no_percent = first_value.clone() * (MAX_PERCENTAGE - TOTAL_FEE_PERCENT);
        testapi::assume((first_liquidity.clone() * MAX_PERCENTAGE + first_no_percent.clone()) < second_liquidity.clone() * first_no_percent );

        testapi::set_esdt_balance(&pair, &self.first_token().get(), &first_liquidity);
        testapi::set_esdt_balance(&pair, &self.second_token().get(), &second_liquidity);
        testapi::set_esdt_balance(&alice, &self.first_token().get(), &first_value);

        let first_liquidity_bytes = first_liquidity.to_bytes_be_buffer();
        let second_liquidity_bytes = second_liquidity.to_bytes_be_buffer();
        testapi::set_storage(&pair, &ManagedBuffer::new_from_bytes(b"lp_token_supply"), &first_liquidity_bytes);
        testapi::set_storage(&pair, &ManagedBuffer::new_from_bytes(b"reserve\x00\x00\x00\x0CFIRST-123456"), &first_liquidity_bytes);
        testapi::set_storage(&pair, &ManagedBuffer::new_from_bytes(b"reserve\x00\x00\x00\x0DSECOND-123456"), &second_liquidity_bytes);

        let first_reserve_initial = self.get_reserve(&pair, &self.first_token().get());
        let second_reserve_initial = self.get_reserve(&pair, &self.second_token().get());

        self.swap_tokens_fixed_input_first(
            &pair, &alice, &first_value, &BigUint::from(1u64)
        );

        let first_reserve_final = self.get_reserve(&pair, &self.first_token().get());
        let second_reserve_final = self.get_reserve(&pair, &self.second_token().get());

        let total_fee = first_value.clone() * TOTAL_FEE_PERCENT / MAX_PERCENTAGE;
        let special_fee = BigUint::zero();  // Fee not enabled
                                            // first_value * SPECIAL_FEE_PERCENT / MAX_PERCENTAGE;
        let initial_k = first_reserve_initial.clone() * second_reserve_initial.clone();
        let final_k = first_reserve_final.clone() * second_reserve_final.clone();

        require!(initial_k.clone() <= final_k.clone(), "K decreased!");
        let condition = final_k <= initial_k.clone() + first_value * second_reserve_initial;
        require!(condition, "K grew too much!");
        testapi::assert(initial_k.clone() <= final_k.clone());
        // testapi::assert(final_k <= initial_k + first_reserve_initial + second_reserve_initial);
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

        let _: IgnoreValue = self
            .pair_proxy(pair_address.clone())
            .add_liquidity(first_min, second_min)
            .with_multi_token_transfer(tokens)
            .execute_on_dest_context();
        testapi::stop_prank();
    }

    fn swap_tokens_fixed_input_first(
        &self,
        pair_address: &ManagedAddress,
        user_address: &ManagedAddress,
        first_amount: &BigUint,
        min_second: &BigUint,
    ) {
        let first_token = self.first_token().get();
        let second_token = self.second_token().get();
        testapi::start_prank(&user_address);
        let _:IgnoreValue = self
            .pair_proxy(pair_address.clone())
            .swap_tokens_fixed_input(second_token, min_second)
            .with_esdt_transfer((first_token, 0, first_amount.clone()))
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

    // the ESDTLocalMint function limits its input to 100 bytes, which means
    // that a contract can mint at most 2^(8*100) tokens.
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
    fn pair_proxy(&self, sc_address: ManagedAddress) -> pair_proxy::Proxy<Self::Api>;
}
