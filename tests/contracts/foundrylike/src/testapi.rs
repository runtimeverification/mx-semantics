multiversx_sc::imports!();
multiversx_sc::derive_imports!();

#[allow(unused)]
extern "C" {

    fn createAccount(
        addressHandle: i32,
        nonce: i64,
        balanceHandle: i32,
    );
    
    fn setStorage(
        addressHandle: i32,
        keyHandle: i32,
        valueHandle: i32,
    );

    fn getStorage(
        addressHandle: i32,
        keyHandle: i32,
        dstHandle: i32,
    );

    fn assumeBool(p: bool);
    fn assertBool(p: bool);

    fn startPrank(addressHandle: i32);
    fn stopPrank();

}


#[allow(unused)]
pub fn create_account<M: ManagedTypeApi>(
    address: &ManagedAddress<M>,
    nonce: u64,
    balance: &BigUint<M>,
) {
    unsafe {
        createAccount(
            address.get_raw_handle(),
            nonce as i64,
            balance.get_raw_handle(),
        );
    }
}


// Set storage of any account
#[allow(unused)]
pub fn set_storage<M: ManagedTypeApi>(
    address: &ManagedAddress<M>,
    key: &ManagedBuffer<M>,
    value: &ManagedBuffer<M>,
) {
    unsafe {
        setStorage(
            address.get_raw_handle(),
            key.get_raw_handle(),
            value.get_raw_handle(),
        );
    }
}


// Get storage of any account
#[allow(unused)]
pub fn get_storage<M: ManagedTypeApi>(
    address: &ManagedAddress<M>,
    key: &ManagedBuffer<M>,
) -> ManagedBuffer<M> {
    unsafe {
        let mut dest = ManagedBuffer::new();
        
        getStorage(
            address.get_raw_handle(),
            key.get_raw_handle(),
            dest.get_raw_handle(),
        );

        dest
    }
}


// Start a prank: set the caller address for contract calls until stop_prank 
#[allow(unused)]
pub fn start_prank<M: ManagedTypeApi>(address: &ManagedAddress<M>) {
    unsafe {
        startPrank(address.get_raw_handle());
    }
}

// Stop a prank: reset the caller address
#[allow(unused)]
pub fn stop_prank() {
    unsafe {
        stopPrank();
    }
}

#[allow(unused)]
pub fn assume(p: bool) {
    unsafe {
        assumeBool(p);
    }
}

#[allow(unused)]
pub fn assert(p: bool) {
    unsafe {
        assertBool(p);
    }
}
