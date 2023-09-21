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
        self.test_set_timestamp();
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
    
}
