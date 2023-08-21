(module
  (type (;0;) (func (param i32 i32 i32)))
  (type (;1;) (func (param i32 i32)))
  (type (;2;) (func (param i32 i32) (result i32)))
  (type (;3;) (func (result i32)))
  (type (;4;) (func (param i32 i32 i32) (result i32)))
  (type (;5;) (func (param i32 i64)))
  (type (;6;) (func (param i32) (result i32)))
  (type (;7;) (func (param i32)))
  (type (;8;) (func))
  (type (;9;) (func (param i32 i64 i32)))
  (type (;10;) (func (param i32 i64 i32 i32 i32 i32)))
  (type (;11;) (func (param i32 i32 i64 i32 i32) (result i32)))
  (import "env" "getStorage" (func $getStorage (type 0)))
  (import "env" "bigIntGetUnsignedArgument" (func $bigIntGetUnsignedArgument (type 1)))
  (import "env" "mBufferGetArgument" (func $mBufferGetArgument (type 2)))
  (import "env" "getNumArguments" (func $getNumArguments (type 3)))
  (import "env" "signalError" (func $signalError (type 1)))
  (import "env" "mBufferAppendBytes" (func $mBufferAppendBytes (type 4)))
  (import "env" "bigIntSetInt64" (func $bigIntSetInt64 (type 5)))
  (import "env" "mBufferSetBytes" (func $mBufferSetBytes (type 4)))
  (import "env" "mBufferStorageLoad" (func $mBufferStorageLoad (type 2)))
  (import "env" "mBufferGetLength" (func $mBufferGetLength (type 6)))
  (import "env" "mBufferStorageStore" (func $mBufferStorageStore (type 2)))
  (import "env" "managedSignalError" (func $managedSignalError (type 7)))
  (import "env" "mBufferToBigIntUnsigned" (func $mBufferToBigIntUnsigned (type 2)))
  (import "env" "bigIntCmp" (func $bigIntCmp (type 2)))
  (import "env" "checkNoPayment" (func $checkNoPayment (type 8)))
  (import "env" "createAccount" (func $createAccount (type 9)))
  (import "env" "registerNewAddress" (func $registerNewAddress (type 9)))
  (import "env" "deployContract" (func $deployContract (type 10)))
  (import "env" "assertBool" (func $assertBool (type 7)))
  (import "env" "assumeBool" (func $assumeBool (type 7)))
  (import "env" "mBufferFromBigIntUnsigned" (func $mBufferFromBigIntUnsigned (type 2)))
  (import "env" "startPrank" (func $startPrank (type 7)))
  (import "env" "managedTransferValueExecute" (func $managedTransferValueExecute (type 11)))
  (import "env" "stopPrank" (func $stopPrank (type 8)))
  (import "env" "bigIntAdd" (func $bigIntAdd (type 0)))
  (func $_ZN10test_adder7testapi11get_storage17h0f6fc7df6bc2eeadE (type 2) (param i32 i32) (result i32)
    (local i32)
    local.get 0
    local.get 1
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$3new17h0a77c78b0d17cd81E
    local.tee 2
    call $getStorage
    local.get 2)
  (func $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$3new17h0a77c78b0d17cd81E (type 3) (result i32)
    (local i32)
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
    local.tee 0
    i32.const 131264
    i32.const 0
    call $mBufferSetBytes
    drop
    local.get 0)
  (func $_ZN13multiversx_sc2io16arg_nested_tuple15load_single_arg17h5adcf70ad3da9e3bE (type 3) (result i32)
    (local i32)
    i32.const 0
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
    local.tee 0
    call $bigIntGetUnsignedArgument
    local.get 0)
  (func $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E (type 3) (result i32)
    (local i32)
    i32.const 0
    i32.const 0
    i32.load offset=131280
    i32.const -1
    i32.add
    local.tee 0
    i32.store offset=131280
    local.get 0)
  (func $_ZN13multiversx_sc2io16arg_nested_tuple15load_single_arg17h96df476d5f21ac7fE (type 3) (result i32)
    (local i32)
    i32.const 0
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
    local.tee 0
    call $mBufferGetArgument
    drop
    local.get 0)
  (func $_ZN13multiversx_sc2io16arg_nested_tuple22check_num_arguments_eq17h4531d068dcf210c3E (type 8)
    block  ;; label = @1
      call $getNumArguments
      i32.const 1
      i32.ne
      br_if 0 (;@1;)
      return
    end
    i32.const 131142
    i32.const 25
    call $signalError
    unreachable)
  (func $_ZN13multiversx_sc5types11interaction18arg_buffer_managed25ManagedArgBuffer$LT$M$GT$12push_arg_raw17h7ff953cddf7c9b4cE (type 1) (param i32 i32)
    (local i32)
    global.get $__stack_pointer
    i32.const 16
    i32.sub
    local.tee 2
    global.set $__stack_pointer
    local.get 2
    local.get 1
    i32.const 24
    i32.shl
    local.get 1
    i32.const 8
    i32.shl
    i32.const 16711680
    i32.and
    i32.or
    local.get 1
    i32.const 8
    i32.shr_u
    i32.const 65280
    i32.and
    local.get 1
    i32.const 24
    i32.shr_u
    i32.or
    i32.or
    i32.store offset=12
    local.get 0
    local.get 2
    i32.const 12
    i32.add
    i32.const 4
    call $mBufferAppendBytes
    drop
    local.get 2
    i32.const 16
    i32.add
    global.set $__stack_pointer)
  (func $_ZN13multiversx_sc5types7managed5basic11big_num_cmp12cmp_conv_i6417heca673c848fc1850E (type 2) (param i32 i32) (result i32)
    i32.const -14
    local.get 1
    i64.extend_i32_u
    call $bigIntSetInt64
    local.get 0
    i32.const -14
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types16big_int_api_node143_$LT$impl$u20$multiversx_sc..api..managed_types..big_int_api..BigIntApi$u20$for$u20$multiversx_sc_wasm_adapter..api..vm_api_node..VmApiImpl$GT$6bi_cmp17h9a32bacca2fc7900E)
  (func $_ZN26multiversx_sc_wasm_adapter3api13managed_types16big_int_api_node143_$LT$impl$u20$multiversx_sc..api..managed_types..big_int_api..BigIntApi$u20$for$u20$multiversx_sc_wasm_adapter..api..vm_api_node..VmApiImpl$GT$6bi_cmp17h9a32bacca2fc7900E (type 2) (param i32 i32) (result i32)
    i32.const -1
    local.get 0
    local.get 1
    call $bigIntCmp
    local.tee 1
    i32.const 0
    i32.ne
    local.get 1
    i32.const 0
    i32.lt_s
    select)
  (func $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$14new_from_bytes17h3480de959300e7ffE (type 2) (param i32 i32) (result i32)
    (local i32)
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
    local.tee 2
    local.get 0
    local.get 1
    call $mBufferSetBytes
    drop
    local.get 2)
  (func $_ZN13multiversx_sc5types7managed7wrapped15managed_address23ManagedAddress$LT$M$GT$14new_from_bytes17hfebfa00773c6ac8aE (type 6) (param i32) (result i32)
    local.get 0
    i32.const 32
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$14new_from_bytes17h3480de959300e7ffE)
  (func $_ZN13multiversx_sc7storage7mappers19single_value_mapper31SingleValueMapper$LT$SA$C$T$GT$3get17h56f4e9100b96789bE (type 6) (param i32) (result i32)
    (local i32)
    local.get 0
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
    local.tee 1
    call $mBufferStorageLoad
    drop
    block  ;; label = @1
      local.get 1
      call $mBufferGetLength
      i32.const 32
      i32.eq
      br_if 0 (;@1;)
      call $_ZN147_$LT$multiversx_sc..storage..storage_get..StorageGetErrorHandler$LT$M$GT$$u20$as$u20$multiversx_sc_codec..codec_err_handler..DecodeErrorHandler$GT$12handle_error17hfc8d8970d478063dE
      unreachable
    end
    local.get 1)
  (func $_ZN147_$LT$multiversx_sc..storage..storage_get..StorageGetErrorHandler$LT$M$GT$$u20$as$u20$multiversx_sc_codec..codec_err_handler..DecodeErrorHandler$GT$12handle_error17hfc8d8970d478063dE (type 8)
    (local i32)
    i32.const 131199
    i32.const 22
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$14new_from_bytes17h3480de959300e7ffE
    local.tee 0
    i32.const 131221
    i32.const 16
    call $mBufferAppendBytes
    drop
    local.get 0
    call $managedSignalError
    unreachable)
  (func $_ZN13multiversx_sc7storage7mappers19single_value_mapper31SingleValueMapper$LT$SA$C$T$GT$3set17h5e176ce0eba59e0dE (type 1) (param i32 i32)
    local.get 0
    local.get 1
    call $mBufferStorageStore
    drop)
  (func $_ZN151_$LT$multiversx_sc..types..managed..basic..managed_buffer..ManagedBuffer$LT$M$GT$$u20$as$u20$core..convert..From$LT$$RF$$u5b$u8$u3b$$u20$N$u5d$$GT$$GT$4from17he240dc3bfb601013E (type 6) (param i32) (result i32)
    local.get 0
    i32.const 3
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$14new_from_bytes17h3480de959300e7ffE)
  (func $_ZN188_$LT$multiversx_sc..types..managed..basic..big_uint..BigUint$LT$M$GT$$u20$as$u20$core..convert..From$LT$multiversx_sc..types..managed..basic..managed_buffer..ManagedBuffer$LT$M$GT$$GT$$GT$4from17h17fbd1e709c14d7dE (type 6) (param i32) (result i32)
    (local i32)
    local.get 0
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
    local.tee 1
    call $mBufferToBigIntUnsigned
    drop
    local.get 1)
  (func $_ZN43_$LT$C$u20$as$u20$test_adder..TestAdder$GT$13adder_address17h767fffc7ab54771fE (type 3) (result i32)
    i32.const 131237
    i32.const 12
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$14new_from_bytes17h3480de959300e7ffE)
  (func $_ZN43_$LT$C$u20$as$u20$test_adder..TestAdder$GT$13owner_address17h9717f9fdba324c1eE (type 3) (result i32)
    i32.const 131249
    i32.const 12
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$14new_from_bytes17h3480de959300e7ffE)
  (func $rust_begin_unwind (type 8)
    call $_ZN26multiversx_sc_wasm_adapter5panic9panic_fmt17h40f4cb8688aa3b78E
    unreachable)
  (func $_ZN26multiversx_sc_wasm_adapter5panic9panic_fmt17h40f4cb8688aa3b78E (type 8)
    i32.const 131264
    i32.const 14
    call $signalError
    unreachable)
  (func $init (type 8)
    (local i32 i32 i32 i32 i32 i32 i32)
    global.get $__stack_pointer
    i32.const 16
    i32.sub
    local.tee 0
    global.set $__stack_pointer
    call $checkNoPayment
    call $_ZN13multiversx_sc2io16arg_nested_tuple22check_num_arguments_eq17h4531d068dcf210c3E
    call $_ZN13multiversx_sc2io16arg_nested_tuple15load_single_arg17h96df476d5f21ac7fE
    local.set 1
    i32.const 131078
    call $_ZN13multiversx_sc5types7managed7wrapped15managed_address23ManagedAddress$LT$M$GT$14new_from_bytes17hfebfa00773c6ac8aE
    local.set 2
    call $_ZN43_$LT$C$u20$as$u20$test_adder..TestAdder$GT$13owner_address17h9717f9fdba324c1eE
    local.get 2
    call $_ZN13multiversx_sc7storage7mappers19single_value_mapper31SingleValueMapper$LT$SA$C$T$GT$3set17h5e176ce0eba59e0dE
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
    local.tee 3
    i64.const 0
    call $bigIntSetInt64
    local.get 2
    i64.const 1
    local.get 3
    call $createAccount
    local.get 2
    i64.const 1
    i32.const 131110
    call $_ZN13multiversx_sc5types7managed7wrapped15managed_address23ManagedAddress$LT$M$GT$14new_from_bytes17hfebfa00773c6ac8aE
    call $registerNewAddress
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$3new17h0a77c78b0d17cd81E
    local.set 4
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$3new17h0a77c78b0d17cd81E
    local.set 5
    local.get 0
    i64.const 360287970189639680
    i64.store offset=8
    i32.const 0
    local.set 3
    block  ;; label = @1
      loop  ;; label = @2
        local.get 3
        i32.const 8
        i32.eq
        br_if 1 (;@1;)
        block  ;; label = @3
          block  ;; label = @4
            local.get 0
            i32.const 8
            i32.add
            local.get 3
            i32.add
            local.tee 6
            i32.load8_u
            i32.eqz
            br_if 0 (;@4;)
            local.get 3
            i32.const 9
            i32.lt_u
            br_if 1 (;@3;)
            local.get 3
            call $_ZN4core5slice5index26slice_start_index_len_fail17hfcd17f2b16d3e7c7E
            unreachable
          end
          local.get 3
          i32.const 1
          i32.add
          local.set 3
          br 1 (;@2;)
        end
      end
      local.get 5
      local.get 6
      i32.const 8
      local.get 3
      i32.sub
      call $mBufferSetBytes
      drop
      local.get 4
      local.get 5
      call $_ZN13multiversx_sc5types11interaction18arg_buffer_managed25ManagedArgBuffer$LT$M$GT$12push_arg_raw17h7ff953cddf7c9b4cE
      call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
      local.tee 6
      i64.const 0
      call $bigIntSetInt64
      local.get 2
      i64.const 5000000000000
      local.get 6
      local.get 1
      local.get 4
      i32.const 131167
      call $_ZN13multiversx_sc5types7managed7wrapped15managed_address23ManagedAddress$LT$M$GT$14new_from_bytes17hfebfa00773c6ac8aE
      local.tee 3
      call $deployContract
      call $_ZN43_$LT$C$u20$as$u20$test_adder..TestAdder$GT$13adder_address17h767fffc7ab54771fE
      local.get 3
      call $_ZN13multiversx_sc7storage7mappers19single_value_mapper31SingleValueMapper$LT$SA$C$T$GT$3set17h5e176ce0eba59e0dE
      local.get 3
      i32.const 131075
      call $_ZN151_$LT$multiversx_sc..types..managed..basic..managed_buffer..ManagedBuffer$LT$M$GT$$u20$as$u20$core..convert..From$LT$$RF$$u5b$u8$u3b$$u20$N$u5d$$GT$$GT$4from17he240dc3bfb601013E
      call $_ZN10test_adder7testapi11get_storage17h0f6fc7df6bc2eeadE
      call $_ZN188_$LT$multiversx_sc..types..managed..basic..big_uint..BigUint$LT$M$GT$$u20$as$u20$core..convert..From$LT$multiversx_sc..types..managed..basic..managed_buffer..ManagedBuffer$LT$M$GT$$GT$$GT$4from17h17fbd1e709c14d7dE
      i32.const 5
      call $_ZN13multiversx_sc5types7managed5basic11big_num_cmp12cmp_conv_i6417heca673c848fc1850E
      i32.const 255
      i32.and
      i32.eqz
      call $assertBool
      local.get 0
      i32.const 16
      i32.add
      global.set $__stack_pointer
      return
    end
    call $_ZN4core9panicking18panic_bounds_check17h00851e534fe3a3c6E
    unreachable)
  (func $_ZN4core5slice5index26slice_start_index_len_fail17hfcd17f2b16d3e7c7E (type 7) (param i32)
    local.get 0
    call $_ZN4core5slice5index29slice_start_index_len_fail_rt17h1be5bb825b955d6fE
    unreachable)
  (func $_ZN4core9panicking18panic_bounds_check17h00851e534fe3a3c6E (type 8)
    call $_ZN4core9panicking9panic_fmt17h6e5483b5a3d4ae69E
    unreachable)
  (func $test_call_add (type 8)
    (local i32 i32 i32 i32 i32)
    call $checkNoPayment
    call $_ZN13multiversx_sc2io16arg_nested_tuple22check_num_arguments_eq17h4531d068dcf210c3E
    call $_ZN13multiversx_sc2io16arg_nested_tuple15load_single_arg17h5adcf70ad3da9e3bE
    local.tee 0
    i32.const 100
    call $_ZN13multiversx_sc5types7managed5basic11big_num_cmp12cmp_conv_i6417heca673c848fc1850E
    i32.const 1
    i32.add
    i32.const 255
    i32.and
    i32.const 2
    i32.lt_u
    call $assumeBool
    call $_ZN43_$LT$C$u20$as$u20$test_adder..TestAdder$GT$13owner_address17h9717f9fdba324c1eE
    call $_ZN13multiversx_sc7storage7mappers19single_value_mapper31SingleValueMapper$LT$SA$C$T$GT$3get17h56f4e9100b96789bE
    local.set 1
    call $_ZN43_$LT$C$u20$as$u20$test_adder..TestAdder$GT$13adder_address17h767fffc7ab54771fE
    call $_ZN13multiversx_sc7storage7mappers19single_value_mapper31SingleValueMapper$LT$SA$C$T$GT$3get17h56f4e9100b96789bE
    local.set 2
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$3new17h0a77c78b0d17cd81E
    local.set 3
    call $_ZN13multiversx_sc5types7managed5basic14managed_buffer22ManagedBuffer$LT$M$GT$3new17h0a77c78b0d17cd81E
    drop
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
    local.tee 4
    local.get 0
    call $mBufferFromBigIntUnsigned
    drop
    local.get 3
    local.get 4
    call $_ZN13multiversx_sc5types11interaction18arg_buffer_managed25ManagedArgBuffer$LT$M$GT$12push_arg_raw17h7ff953cddf7c9b4cE
    local.get 1
    call $startPrank
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types19static_var_api_node11next_handle17h8c99ac0db9362219E
    local.tee 1
    i64.const 0
    call $bigIntSetInt64
    local.get 2
    local.get 1
    i64.const 5000000
    i32.const 131072
    call $_ZN151_$LT$multiversx_sc..types..managed..basic..managed_buffer..ManagedBuffer$LT$M$GT$$u20$as$u20$core..convert..From$LT$$RF$$u5b$u8$u3b$$u20$N$u5d$$GT$$GT$4from17he240dc3bfb601013E
    local.get 3
    call $managedTransferValueExecute
    local.set 3
    call $stopPrank
    block  ;; label = @1
      local.get 3
      i32.eqz
      br_if 0 (;@1;)
      call $_ZN4core9panicking18panic_bounds_check17h00851e534fe3a3c6E
      unreachable
    end
    local.get 2
    i32.const 131075
    call $_ZN151_$LT$multiversx_sc..types..managed..basic..managed_buffer..ManagedBuffer$LT$M$GT$$u20$as$u20$core..convert..From$LT$$RF$$u5b$u8$u3b$$u20$N$u5d$$GT$$GT$4from17he240dc3bfb601013E
    call $_ZN10test_adder7testapi11get_storage17h0f6fc7df6bc2eeadE
    call $_ZN188_$LT$multiversx_sc..types..managed..basic..big_uint..BigUint$LT$M$GT$$u20$as$u20$core..convert..From$LT$multiversx_sc..types..managed..basic..managed_buffer..ManagedBuffer$LT$M$GT$$GT$$GT$4from17h17fbd1e709c14d7dE
    local.set 3
    i32.const -14
    i64.const 5
    call $bigIntSetInt64
    local.get 0
    local.get 0
    i32.const -14
    call $bigIntAdd
    local.get 3
    local.get 0
    call $_ZN26multiversx_sc_wasm_adapter3api13managed_types16big_int_api_node143_$LT$impl$u20$multiversx_sc..api..managed_types..big_int_api..BigIntApi$u20$for$u20$multiversx_sc_wasm_adapter..api..vm_api_node..VmApiImpl$GT$6bi_cmp17h9a32bacca2fc7900E
    i32.const 255
    i32.and
    i32.eqz
    call $assertBool)
  (func $callBack (type 8))
  (func $_ZN4core9panicking9panic_fmt17h6e5483b5a3d4ae69E (type 8)
    call $rust_begin_unwind
    unreachable)
  (func $_ZN4core5slice5index29slice_start_index_len_fail_rt17h1be5bb825b955d6fE (type 7) (param i32)
    call $_ZN4core9panicking9panic_fmt17h6e5483b5a3d4ae69E
    unreachable)
  (table (;0;) 1 1 funcref)
  (memory (;0;) 3)
  (global $__stack_pointer (mut i32) (i32.const 131072))
  (global (;1;) i32 (i32.const 131284))
  (global (;2;) i32 (i32.const 131296))
  (export "memory" (memory 0))
  (export "init" (func $init))
  (export "test_call_add" (func $test_call_add))
  (export "callBack" (func $callBack))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2))
  (data $.rodata (i32.const 131072) "addsumowner___________________________adder___________________________wrong number of arguments\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00storage decode error: bad array lengthadderAddressownerAddress\00\00\00panic occurred")
  (data $.data (i32.const 131280) "\9c\ff\ff\ff"))
