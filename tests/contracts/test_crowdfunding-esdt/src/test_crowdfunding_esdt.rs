#![no_std]

use testapi;

multiversx_sc::imports!();

static OWNER : &[u8; 32]        = b"owner___________________________";
static ALICE : &[u8; 32]        = b"alice___________________________";
static CROWDFUNDING : &[u8; 32] = b"crowdfunding____________________";

static TARGET : u32 = 100u32;
static DEADLINE : u32 = 5u32;


#[multiversx_sc::contract]
pub trait TestCrowdfundingEsdtContract {

    fn TOKEN_IDENTIFIER(&self) -> EgldOrEsdtTokenIdentifier<Self::Api> {
        EgldOrEsdtTokenIdentifier::egld()
    }

    #[storage_mapper("ownerAddress")]
    fn owner_address(&self) -> SingleValueMapper<ManagedAddress>;

    #[storage_mapper("crowdfundingAddress")]
    fn crowdfunding_address(&self) -> SingleValueMapper<ManagedAddress>;

    #[storage_mapper("aliceAddress")]
    fn alice_address(&self) -> SingleValueMapper<ManagedAddress>;

    #[storage_mapper("bobAddress")]
    fn bob_address(&self) -> SingleValueMapper<ManagedAddress>;

    #[init]
    fn init(&self, code_path: ManagedBuffer) {
        // create a user account
        let alice        = ManagedAddress::from(ALICE);
        self.alice_address().set(&alice);
        testapi::create_account(&alice, 1, &BigUint::from(200u64));

        // create the owner account
        let owner        = ManagedAddress::from(OWNER);
        self.owner_address().set(&owner);

        testapi::create_account(&owner, 2, &BigUint::from(0u64));

        // register an address for the contract to be deployed
        let crowdfunding = ManagedAddress::from(CROWDFUNDING);
        testapi::register_new_address(&owner, 2, &crowdfunding, );

        // deploy the crowdfunding contract
        let mut crowdfunding_init_args = ManagedArgBuffer::new();
        crowdfunding_init_args.push_arg(TARGET);
        crowdfunding_init_args.push_arg(DEADLINE);
        crowdfunding_init_args.push_arg(self.TOKEN_IDENTIFIER()); // initial sum

        // deploy a contract from `owner`
        let crowdfunding = testapi::deploy_contract(
                &owner,
                5000000000000,
                &BigUint::zero(),
                &code_path,
                &crowdfunding_init_args,
            );

        // save the deployed contract's address
        self.crowdfunding_address().set(&crowdfunding);
    }

    #[endpoint(test_fund)]
    fn test_fund(&self, value: BigUint) {
      let crowdfunding = self.crowdfunding_address().get();
      let alice = self.alice_address().get();

      let current_funds = self.get_current_funds(&crowdfunding);
      testapi::assume(BigUint::zero() < value);
      testapi::assume(value < self.get_target(&crowdfunding) - &current_funds + BigUint::from(1u32));

      self.fund(&crowdfunding, &alice, &value);
      testapi::assert(value + current_funds == self.get_current_funds(&crowdfunding))
    }

    fn fund(&self, crowdfunding: &ManagedAddress, user: &ManagedAddress, value: &BigUint) {
        let args = ManagedArgBuffer::new();

        testapi::start_prank(&user);
        let _ = self.send_raw().direct_egld_execute(
            &crowdfunding,
            value,
            5000000,
            &ManagedBuffer::from(b"fund"),
            &args,
        );
        testapi::stop_prank();
    }

    fn get_current_funds(&self, crowdfunding: &ManagedAddress) -> BigUint {
        self.blockchain().get_balance(crowdfunding)
    }

    fn get_target(&self, crowdfunding: &ManagedAddress) -> BigUint {
      let value = testapi::get_storage(&crowdfunding, &ManagedBuffer::from(b"target")); 
      BigUint::from(value)
    }
}
