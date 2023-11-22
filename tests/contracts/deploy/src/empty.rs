#![no_std]

multiversx_sc::imports!();

/// This contract is used to test what happens if a deployment fails.
//  The init function fails if the argument is 0
#[multiversx_sc::contract]
pub trait DeployContract {
    #[init]
    #[payable("EGLD")]
    fn init(&self, p: u32) {
        require!(p != 0u32, "cannot deploy 0");
    }
}
