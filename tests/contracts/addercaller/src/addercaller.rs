// A smart contract to test transfer & execute functions
// Initialize the contract with the address of the adder
// The endpoints `call_adder` and `call_adder_esdt` accepts 
// tokens in EGLD and ESDT and performs transfer & execute
// to the adder's `add` endpoint.

#![no_std]

multiversx_sc::imports!();

/// One of the simplest smart contracts possible,
/// it holds a single variable in storage, which anyone can increment.
#[multiversx_sc::contract]
pub trait AdderCaller {

    #[storage_mapper("dest")]
    fn dest(&self) -> SingleValueMapper<ManagedAddress>;

    #[init]
    fn init(&self, dest: &ManagedAddress) {
        self.dest().set(dest);
    }

    #[endpoint]
    #[payable("EGLD")]
    fn call_adder(&self, value: BigUint)  -> ManagedBuffer {
        let mut arg_buffer = ManagedArgBuffer::new();
        arg_buffer.push_arg(value);

        let result = self.send_raw().direct_egld_execute(
            &self.dest().get(),
            &BigUint::from(30u32),
            5000000,
            &ManagedBuffer::from(b"add"),
            &arg_buffer,
        );

        match result {
            Result::Err(e) => sc_panic!(e),
            Result::Ok(_) => ManagedBuffer::from("added")
        }
    }

    #[endpoint]
    #[payable("MYESDT")]
    fn call_adder_esdt(&self, value: BigUint)  -> ManagedBuffer {
        let mut arg_buffer = ManagedArgBuffer::new();
        arg_buffer.push_arg(value);

        let result = self.send_raw().transfer_esdt_execute(
            &self.dest().get(),
            &TokenIdentifier::from_esdt_bytes(b"MYESDT"),
            &BigUint::from(20u32),
            5000000,
            &ManagedBuffer::from(b"add"),
            &arg_buffer,
        );

        match result {
            Result::Err(e) => sc_panic!(e),
            Result::Ok(_) => ManagedBuffer::from("added-esdt")
        }
    }

    #[endpoint]
    #[payable("MYESDT")]
    fn call_adder_esdt_builtin(&self, value: BigUint) -> ManagedBuffer {
      let mut arg_buffer = ManagedArgBuffer::new();
      arg_buffer.push_arg(b"MYESDT");
      arg_buffer.push_arg(20u32);
      arg_buffer.push_arg(b"add");
      arg_buffer.push_arg(value);

      let _ = self.send_raw().execute_on_dest_context_raw(
        5000000,
        &self.dest().get(),
        &BigUint::from(0u32), 
        &ManagedBuffer::from(b"ESDTTransfer"), 
        &arg_buffer,
      );

      ManagedBuffer::from("added-esdt-builtin")
    }

    #[endpoint]
    #[payable("MYESDT")]
    fn call_adder_esdt_builtin_multi(&self, value: BigUint) -> ManagedBuffer {
      let mut arg_buffer = ManagedArgBuffer::new();
      arg_buffer.push_arg(self.dest().get());
      arg_buffer.push_arg(2u32);
      arg_buffer.push_arg(b"MYESDT");
      arg_buffer.push_arg(0u32);
      arg_buffer.push_arg(5u32);
      arg_buffer.push_arg(b"MYESDT");
      arg_buffer.push_arg(0u32);
      arg_buffer.push_arg(10u32);
      
      arg_buffer.push_arg(b"add");
      arg_buffer.push_arg(value);

      let _ = self.send_raw().execute_on_dest_context_raw(
        5000000,
        &self.blockchain().get_sc_address(),
        &BigUint::from(0u32), 
        &ManagedBuffer::from(b"MultiESDTNFTTransfer"), 
        &arg_buffer,
      );

      ManagedBuffer::from("added-esdt-builtin-multi")
    }

}

// 