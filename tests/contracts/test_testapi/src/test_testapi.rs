#![no_std]

use testapi;

multiversx_sc::imports!();

#[multiversx_sc::contract]
pub trait TestTestapi {

    #[init]
    fn init(&self) {
        let alice = ManagedAddress::from(b"alice___________________________");
        testapi::create_account(&alice, 1, &BigUint::from(0u64));
    
        self.test_set_balance(&alice);
        self.test_set_esdt_balance(&alice);
        self.test_set_timestamp();
        self.test_set_get_storage(&alice);
        self.test_set_esdt_role(&alice);
        self.test_local_mint(&alice);
    }

    fn test_set_balance(&self, addr: &ManagedAddress) {
        // Given
        let value = BigUint::from(100000000u64);

        // When
        testapi::set_balance(addr, &value);

        // Expect
        let actual = self.blockchain()
            .get_balance(addr);

        require!(value == actual, "Actual balance does not match the given value");
    }

    fn test_set_esdt_balance(&self, addr: &ManagedAddress) {
        // Given
        let value = BigUint::from(100000000u64);
        let token = TokenIdentifier::from("MY_ESDT_TOKEN");

        // When
        testapi::set_esdt_balance(addr, &token, &value);

        // Expect
        let actual = self.blockchain()
            .get_esdt_balance(addr, &token, 0u64);

        require!(value == actual, "Actual esdt balance does not match the given value");
    }

    fn test_set_esdt_role(&self, addr: &ManagedAddress) {
        let token = TokenIdentifier::from("MY_ESDT_TOKEN");
        testapi::add_esdt_role(addr, &token, EsdtLocalRole::Mint);
        require!( testapi::check_esdt_role(addr, &token, EsdtLocalRole::Mint),
            "Cannot add ESDT role local mint");
        
        testapi::add_esdt_role(addr, &token, EsdtLocalRole::Burn);
        require!( testapi::check_esdt_role(addr, &token, EsdtLocalRole::Burn),
            "Cannot add ESDT role local mint");
        
        testapi::remove_esdt_role(addr, &token, EsdtLocalRole::Mint);
        require!(!testapi::check_esdt_role(addr, &token, EsdtLocalRole::Mint), 
            "Cannot remove ESDT role local mint");
        
        testapi::remove_esdt_role(addr, &token, EsdtLocalRole::Burn);
        require!(!testapi::check_esdt_role(addr, &token, EsdtLocalRole::Burn),
            "Cannot remove ESDT role local burn");
    }

    fn test_local_mint(&self, addr: &ManagedAddress) {
        let token = TokenIdentifier::from("MY_ESDT_TOKEN");
        testapi::add_esdt_role(addr, &token, EsdtLocalRole::Mint);
        
        let initial_balance = self.blockchain()
            .get_esdt_balance(addr, &token, 0u64);
        
        let mut args = ManagedArgBuffer::new();
        args.push_arg(&token);
        args.push_arg(100u32);
        
        testapi::start_prank(&addr);
        let _ = self.send_raw().direct_egld_execute(
            &addr, 
            &BigUint::from(0u32), 
            5000000000, 
            &ManagedBuffer::from(b"ESDTLocalMint"),
            &args,
        );
        testapi::stop_prank();
    
        let final_balance = self.blockchain()
            .get_esdt_balance(addr, &token, 0u64);
   
        require!(initial_balance + 100u32 == final_balance, "Cannot local mint");
    }

    fn test_set_timestamp(&self) {
        // Given
        let value = 1234567890u64;

        // When
        testapi::set_block_timestamp(value);

        // Expect
        require!(
          value == self.blockchain().get_block_timestamp(), 
          "Actual timestamp does not match the given value"
        );
    }

    fn test_set_get_storage(&self, addr: &ManagedAddress) {
      // Given
      let key = ManagedBuffer::from(b"a_storage_key");
      let value = ManagedBuffer::from(b"a storage value");
      
      // When
      testapi::set_storage(addr, &key, &value);

      // Expect
      let actual = testapi::get_storage(addr, &key);
      require!(actual == value, "Actual storage does not match the given value");
    }
    
}
