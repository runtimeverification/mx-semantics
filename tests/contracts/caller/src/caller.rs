#![no_std]

multiversx_sc::imports!();

#[multiversx_sc::contract]
pub trait CallerContract {


    #[init]
    fn init(&self) {
    }

    #[endpoint]
    #[payable("EGLD")]
    fn call_other(&self, dest: ManagedAddress, func: ManagedBuffer, value: i64)  -> ManagedBuffer {
        
        let mut arg_buffer = ManagedArgBuffer::new();
        arg_buffer.push_arg(value);

        let to_send = (*self.call_value().egld_value()).clone() / 2u64; // TODO simplify this

        let result = self.send_raw().direct_egld_execute(
            &dest,
            &to_send,
            5000000,
            &func,
            &arg_buffer,
        );

        match result {
            Result::Err(_) => ManagedBuffer::from("failed"),
            Result::Ok(_) => ManagedBuffer::from("done")
        }
    }
}
