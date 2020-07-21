(module
  (type (;0;) (func (param i32 i32 i32) (result i32)))
  (type (;1;) (func (param i32 i32) (result i32)))
  (type (;2;) (func (param i32 i32 i32 i32)))
  (type (;3;) (func (param i32) (result i32)))
  (type (;4;) (func (result i32)))
  (type (;5;) (func (param i32 i32 i32 i32) (result i32)))
  (type (;6;) (func (param i32 i32)))
  (type (;7;) (func (param i64) (result i32)))
  (type (;8;) (func (param i32 i32) (result i64)))
  (type (;9;) (func (param i32 i32 i64) (result i32)))
  (type (;10;) (func (param i32)))
  (type (;11;) (func (param i32 i32 i32)))
  (type (;12;) (func))
  (type (;13;) (func (param i32 i32 i32 i32 i32) (result i32)))
  (type (;14;) (func (param i32 i32 i32 i32 i32)))
  (import "env" "getNumArguments" (func $getNumArguments (type 4)))
  (import "env" "storageStore" (func $storageStore (type 5)))
  (import "env" "finish" (func $finish (type 6)))
  (import "env" "signalError" (func $signalError (type 6)))
  (import "env" "bigIntNew" (func $bigIntNew (type 7)))
  (import "env" "bigIntStorageLoadUnsigned" (func $bigIntStorageLoadUnsigned (type 0)))
  (import "env" "int64storageLoad" (func $int64storageLoad (type 8)))
  (import "env" "int64storageStore" (func $int64storageStore (type 9)))
  (import "env" "bigIntGetCallValue" (func $bigIntGetCallValue (type 10)))
  (import "env" "bigIntCmp" (func $bigIntCmp (type 1)))
  (import "env" "getCaller" (func $getCaller (type 10)))
  (import "env" "bigIntUnsignedByteLength" (func $bigIntUnsignedByteLength (type 3)))
  (import "env" "bigIntGetUnsignedBytes" (func $bigIntGetUnsignedBytes (type 1)))
  (import "env" "transferValue" (func $transferValue (type 5)))
  (import "env" "getArgumentLength" (func $getArgumentLength (type 3)))
  (import "env" "getArgument" (func $getArgument (type 1)))
  (import "env" "bigIntMul" (func $bigIntMul (type 11)))
  (func $_ZN11elrond_wasm13ContractIOApi19check_num_arguments17h868a6eb9bef29c05E (type 10) (param i32)
    block  ;; label = @1
      call $getNumArguments
      local.get 0
      i32.ne
      br_if 0 (;@1;)
      return
    end
    i32.const 1048576
    i32.const 25
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$12signal_error17h976338bc113e8d25E
    unreachable)
  (func $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$12signal_error17h976338bc113e8d25E (type 6) (param i32 i32)
    local.get 0
    local.get 1
    call $_ZN16elrond_wasm_node9ext_error12signal_error17h3e53d6674adb9999E
    unreachable)
  (func $_ZN11elrond_wasm2io19arg_loader_endpoint15load_single_arg17h10003b39bc032a7eE (type 2) (param i32 i32 i32 i32)
    (local i32 i64)
    global.get 0
    i32.const 32
    i32.sub
    local.tee 4
    global.set 0
    local.get 4
    local.get 1
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$16get_argument_vec17h2c9ae2ed10b8f5ecE
    local.get 4
    i32.const 16
    i32.add
    local.get 4
    i32.load
    local.get 4
    i32.load offset=8
    call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
    local.get 4
    i64.load offset=16
    local.set 5
    local.get 0
    local.get 4
    i32.load offset=24
    i32.store offset=8
    local.get 0
    local.get 5
    i64.store align=4
    local.get 4
    call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
    local.get 4
    i32.const 32
    i32.add
    global.set 0)
  (func $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$16get_argument_vec17h2c9ae2ed10b8f5ecE (type 6) (param i32 i32)
    (local i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    local.get 2
    local.get 1
    call $getArgumentLength
    local.tee 3
    call $_ZN5alloc3vec12Vec$LT$T$GT$13with_capacity17ha05bb556483e33d0E
    local.get 2
    local.get 3
    i32.store offset=8
    local.get 1
    local.get 2
    i32.load
    call $getArgument
    drop
    local.get 0
    i32.const 8
    i32.add
    local.get 2
    i32.load offset=8
    i32.store
    local.get 0
    local.get 2
    i64.load
    i64.store align=4
    local.get 2
    i32.const 16
    i32.add
    global.set 0)
  (func $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E (type 11) (param i32 i32 i32)
    (local i32)
    global.get 0
    i32.const 32
    i32.sub
    local.tee 3
    global.set 0
    local.get 3
    i32.const 8
    i32.add
    local.get 2
    i32.const 0
    call $_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$11allocate_in17h1842a5e89cc73292E
    local.get 3
    i32.const 0
    i32.store offset=24
    local.get 3
    local.get 3
    i64.load offset=8
    i64.store offset=16
    local.get 3
    i32.const 16
    i32.add
    local.get 1
    local.get 2
    call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
    local.get 0
    i32.const 8
    i32.add
    local.get 3
    i32.load offset=24
    i32.store
    local.get 0
    local.get 3
    i64.load offset=16
    i64.store align=4
    local.get 3
    i32.const 32
    i32.add
    global.set 0)
  (func $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE (type 10) (param i32)
    local.get 0
    call $_ZN77_$LT$alloc..raw_vec..RawVec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17hc7f6833a34267be8E)
  (func $_ZN11elrond_wasm2io9arg_types12load_dyn_arg17h4ecce73d85c983baE (type 6) (param i32 i32)
    (local i32 i32 i32 i64)
    global.get 0
    i32.const 96
    i32.sub
    local.tee 2
    global.set 0
    local.get 2
    i32.const 0
    i32.store offset=32
    local.get 2
    i64.const 4
    i64.store offset=24
    local.get 2
    i32.const 72
    i32.add
    i32.const 4
    i32.or
    local.set 3
    block  ;; label = @1
      loop  ;; label = @2
        local.get 1
        i32.load offset=4
        local.get 1
        i32.load offset=8
        i32.ge_s
        br_if 1 (;@1;)
        local.get 2
        i32.const 72
        i32.add
        local.get 1
        i32.const 1048932
        i32.const 8
        call $_ZN66_$LT$T$u20$as$u20$elrond_wasm..io..arg_types..ArgType$LT$D$GT$$GT$4load17ha4069b2f65b1a2c3E
        local.get 2
        i32.const 56
        i32.add
        i32.const 8
        i32.add
        local.tee 4
        local.get 3
        i32.const 8
        i32.add
        i64.load align=4
        i64.store
        local.get 2
        local.get 3
        i64.load align=4
        i64.store offset=56
        block  ;; label = @3
          local.get 2
          i32.load offset=72
          i32.const 1
          i32.eq
          br_if 0 (;@3;)
          local.get 2
          i32.const 40
          i32.add
          i32.const 8
          i32.add
          local.get 4
          i32.load
          i32.store
          local.get 2
          local.get 2
          i64.load offset=56
          i64.store offset=40
          local.get 2
          i32.const 24
          i32.add
          local.get 2
          i32.const 40
          i32.add
          call $_ZN5alloc3vec12Vec$LT$T$GT$4push17h44b296365e57ad04E
          br 1 (;@2;)
        end
      end
      local.get 2
      i32.const 8
      i32.add
      i32.const 8
      i32.add
      local.tee 1
      local.get 2
      i32.const 56
      i32.add
      i32.const 8
      i32.add
      i64.load
      i64.store
      local.get 2
      local.get 2
      i64.load offset=56
      i64.store offset=8
      local.get 2
      i32.const 24
      i32.add
      call $_ZN4core3ptr13drop_in_place17h20a31f032c7e70f2E
      local.get 2
      i32.const 72
      i32.add
      i32.const 8
      i32.add
      local.get 1
      i64.load
      i64.store
      local.get 2
      local.get 2
      i64.load offset=8
      i64.store offset=72
      local.get 2
      i32.const 72
      i32.add
      call $_ZN152_$LT$elrond_wasm..io..arg_loader_err..DynEndpointErrHandler$LT$A$C$BigInt$C$BigUint$GT$$u20$as$u20$elrond_wasm..io..arg_loader_err..DynArgErrHandler$GT$15handle_sc_error17hfe814566389c223aE
      unreachable
    end
    local.get 2
    i32.const 8
    i32.add
    i32.const 8
    i32.add
    local.get 2
    i32.const 24
    i32.add
    i32.const 8
    i32.add
    i32.load
    local.tee 1
    i32.store
    local.get 2
    local.get 2
    i64.load offset=24
    local.tee 5
    i64.store offset=8
    local.get 0
    i32.const 8
    i32.add
    local.get 1
    i32.store
    local.get 0
    local.get 5
    i64.store align=4
    local.get 2
    i32.const 96
    i32.add
    global.set 0)
  (func $_ZN66_$LT$T$u20$as$u20$elrond_wasm..io..arg_types..ArgType$LT$D$GT$$GT$4load17ha4069b2f65b1a2c3E (type 2) (param i32 i32 i32 i32)
    (local i32 i32 i64)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 4
    global.set 0
    block  ;; label = @1
      block  ;; label = @2
        local.get 1
        i32.load offset=4
        local.tee 5
        local.get 1
        i32.load offset=8
        i32.ge_s
        br_if 0 (;@2;)
        local.get 4
        local.get 5
        local.get 2
        local.get 3
        call $_ZN11elrond_wasm2io19arg_loader_endpoint15load_single_arg17h10003b39bc032a7eE
        local.get 1
        local.get 1
        i32.load offset=4
        i32.const 1
        i32.add
        i32.store offset=4
        local.get 4
        i32.load
        local.tee 1
        i32.eqz
        br_if 0 (;@2;)
        local.get 4
        i64.load offset=4 align=4
        local.set 6
        local.get 0
        local.get 1
        i32.store offset=4
        local.get 0
        i32.const 8
        i32.add
        local.get 6
        i64.store align=4
        i32.const 0
        local.set 1
        br 1 (;@1;)
      end
      local.get 0
      i32.const 0
      i32.store offset=4
      local.get 0
      i32.const 12
      i32.add
      i32.const 25
      i32.store
      local.get 0
      i32.const 8
      i32.add
      i32.const 1048576
      i32.store
      i32.const 1
      local.set 1
    end
    local.get 0
    local.get 1
    i32.store
    local.get 4
    i32.const 16
    i32.add
    global.set 0)
  (func $_ZN5alloc3vec12Vec$LT$T$GT$4push17h44b296365e57ad04E (type 6) (param i32 i32)
    (local i32 i32 i32 i32 i64)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        i32.load offset=8
        local.tee 3
        local.get 0
        i32.load offset=4
        i32.eq
        br_if 0 (;@2;)
        local.get 0
        i32.load
        local.set 4
        br 1 (;@1;)
      end
      block  ;; label = @2
        block  ;; label = @3
          local.get 3
          i32.const 1
          i32.add
          local.tee 4
          local.get 3
          i32.lt_u
          br_if 0 (;@3;)
          local.get 3
          i32.const 1
          i32.shl
          local.tee 5
          local.get 4
          local.get 5
          local.get 4
          i32.gt_u
          select
          i64.extend_i32_u
          i64.const 12
          i64.mul
          local.tee 6
          i64.const 32
          i64.shr_u
          i32.wrap_i64
          br_if 0 (;@3;)
          local.get 6
          i32.wrap_i64
          local.tee 5
          i32.const 0
          i32.lt_s
          br_if 0 (;@3;)
          block  ;; label = @4
            block  ;; label = @5
              local.get 0
              i32.load
              i32.const 0
              local.get 3
              select
              local.tee 4
              br_if 0 (;@5;)
              local.get 2
              local.get 5
              i32.const 4
              call $_ZN62_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..AllocRef$GT$5alloc17h91e855b0ff6b448aE
              local.get 2
              i32.load
              local.tee 4
              i32.eqz
              br_if 3 (;@2;)
              local.get 2
              i32.load offset=4
              local.set 5
              br 1 (;@4;)
            end
            local.get 3
            i32.const 12
            i32.mul
            local.tee 3
            local.get 5
            i32.eq
            br_if 0 (;@4;)
            block  ;; label = @5
              local.get 3
              i32.eqz
              br_if 0 (;@5;)
              local.get 4
              local.get 3
              i32.const 4
              local.get 5
              call $__rust_realloc
              local.tee 4
              br_if 1 (;@4;)
              br 3 (;@2;)
            end
            local.get 2
            i32.const 8
            i32.add
            local.get 5
            i32.const 4
            call $_ZN62_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..AllocRef$GT$5alloc17h91e855b0ff6b448aE
            local.get 2
            i32.load offset=8
            local.tee 4
            i32.eqz
            br_if 2 (;@2;)
            local.get 2
            i32.load offset=12
            local.set 5
          end
          local.get 0
          local.get 4
          i32.store
          local.get 0
          local.get 5
          i32.const 12
          i32.div_u
          i32.store offset=4
          local.get 0
          i32.load offset=8
          local.set 3
          br 2 (;@1;)
        end
        call $_ZN5alloc7raw_vec17capacity_overflow17h52126f2f7e3db953E
        unreachable
      end
      call $_ZN5alloc5alloc18handle_alloc_error17h94b61eaffc13868aE
      unreachable
    end
    local.get 4
    local.get 3
    i32.const 12
    i32.mul
    i32.add
    local.tee 3
    local.get 1
    i64.load align=4
    i64.store align=4
    local.get 3
    i32.const 8
    i32.add
    local.get 1
    i32.const 8
    i32.add
    i32.load
    i32.store
    local.get 0
    local.get 0
    i32.load offset=8
    i32.const 1
    i32.add
    i32.store offset=8
    local.get 2
    i32.const 16
    i32.add
    global.set 0)
  (func $_ZN4core3ptr13drop_in_place17h20a31f032c7e70f2E (type 10) (param i32)
    (local i32 i32)
    local.get 0
    i32.load offset=8
    i32.const 12
    i32.mul
    local.set 1
    local.get 0
    i32.load
    local.set 2
    block  ;; label = @1
      loop  ;; label = @2
        local.get 1
        i32.eqz
        br_if 1 (;@1;)
        local.get 1
        i32.const -12
        i32.add
        local.set 1
        local.get 2
        call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
        local.get 2
        i32.const 12
        i32.add
        local.set 2
        br 0 (;@2;)
      end
    end
    block  ;; label = @1
      local.get 0
      i32.load offset=4
      local.tee 1
      i32.eqz
      br_if 0 (;@1;)
      local.get 0
      i32.load
      local.tee 2
      i32.eqz
      br_if 0 (;@1;)
      local.get 1
      i32.const 12
      i32.mul
      local.tee 1
      i32.eqz
      br_if 0 (;@1;)
      local.get 2
      local.get 1
      i32.const 4
      call $__rust_dealloc
    end)
  (func $_ZN152_$LT$elrond_wasm..io..arg_loader_err..DynEndpointErrHandler$LT$A$C$BigInt$C$BigUint$GT$$u20$as$u20$elrond_wasm..io..arg_loader_err..DynArgErrHandler$GT$15handle_sc_error17hfe814566389c223aE (type 10) (param i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 1
    global.set 0
    local.get 1
    i32.const 8
    i32.add
    local.get 0
    call $_ZN11elrond_wasm2io8sc_error7SCError8as_bytes17h1f70efe0bfeec110E
    local.get 1
    i32.load offset=8
    local.get 1
    i32.load offset=12
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$12signal_error17h976338bc113e8d25E
    unreachable)
  (func $_ZN11elrond_wasm2io9arg_types18check_no_more_args17h477780b151f82e5fE (type 6) (param i32 i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    block  ;; label = @1
      local.get 0
      local.get 1
      i32.lt_s
      br_if 0 (;@1;)
      local.get 2
      i32.const 16
      i32.add
      global.set 0
      return
    end
    local.get 2
    i32.const 8
    i32.add
    i32.const 25
    i32.store
    local.get 2
    i32.const 1048576
    i32.store offset=4
    local.get 2
    i32.const 0
    i32.store
    local.get 2
    call $_ZN152_$LT$elrond_wasm..io..arg_loader_err..DynEndpointErrHandler$LT$A$C$BigInt$C$BigUint$GT$$u20$as$u20$elrond_wasm..io..arg_loader_err..DynArgErrHandler$GT$15handle_sc_error17hfe814566389c223aE
    unreachable)
  (func $_ZN11elrond_wasm7storage12storage_util11storage_set17hed34ed5d26b9ca60E (type 11) (param i32 i32 i32)
    local.get 0
    local.get 1
    local.get 2
    i32.load
    local.get 2
    i32.load offset=8
    call $storageStore
    drop)
  (func $_ZN121_$LT$core..result..Result$LT$T$C$E$GT$$u20$as$u20$elrond_wasm..io..finish..EndpointResult$LT$A$C$BigInt$C$BigUint$GT$$GT$6finish17h79242137cf3aa830E (type 10) (param i32)
    (local i32)
    block  ;; label = @1
      local.get 0
      i32.load
      i32.const 1
      i32.eq
      br_if 0 (;@1;)
      local.get 0
      i32.const 12
      i32.add
      i32.load
      i32.const 12
      i32.mul
      local.set 1
      local.get 0
      i32.load offset=4
      local.set 0
      block  ;; label = @2
        loop  ;; label = @3
          local.get 1
          i32.eqz
          br_if 1 (;@2;)
          local.get 0
          i32.load
          local.get 0
          i32.load offset=8
          call $finish
          local.get 1
          i32.const -12
          i32.add
          local.set 1
          local.get 0
          i32.const 12
          i32.add
          local.set 0
          br 0 (;@3;)
        end
      end
      return
    end
    local.get 0
    i32.const 4
    i32.add
    call $_ZN94_$LT$elrond_wasm..io..sc_error..SCError$u20$as$u20$elrond_wasm..io..sc_error..ErrorMessage$GT$18with_message_slice17h189afa6bb7c7f926E
    unreachable)
  (func $_ZN94_$LT$elrond_wasm..io..sc_error..SCError$u20$as$u20$elrond_wasm..io..sc_error..ErrorMessage$GT$18with_message_slice17h189afa6bb7c7f926E (type 10) (param i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 1
    global.set 0
    local.get 1
    i32.const 8
    i32.add
    local.get 0
    call $_ZN11elrond_wasm2io8sc_error7SCError8as_bytes17h1f70efe0bfeec110E
    local.get 1
    i32.load offset=8
    local.get 1
    i32.load offset=12
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$12signal_error17h976338bc113e8d25E
    unreachable)
  (func $_ZN11elrond_wasm2io8sc_error7SCError8as_bytes17h1f70efe0bfeec110E (type 6) (param i32 i32)
    local.get 0
    local.get 1
    i32.load offset=4
    i32.store
    local.get 0
    local.get 1
    i32.const 12
    i32.add
    local.get 1
    i32.const 8
    i32.add
    local.get 1
    i32.load
    i32.const 1
    i32.eq
    select
    i32.load
    i32.store offset=4)
  (func $_ZN16elrond_wasm_node9ext_error12signal_error17h3e53d6674adb9999E (type 6) (param i32 i32)
    local.get 0
    local.get 1
    call $signalError
    unreachable)
  (func $__rust_dealloc (type 11) (param i32 i32 i32)
    local.get 0
    local.get 1
    local.get 2
    call $__rg_dealloc)
  (func $_ZN77_$LT$alloc..raw_vec..RawVec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17hc7f6833a34267be8E (type 10) (param i32)
    (local i32)
    block  ;; label = @1
      local.get 0
      i32.load offset=4
      local.tee 1
      i32.eqz
      br_if 0 (;@1;)
      local.get 0
      i32.load
      local.get 1
      i32.const 1
      call $__rust_dealloc
    end)
  (func $_ZN4core3ptr13drop_in_place17h6d2c218039e34872E (type 10) (param i32)
    (local i32)
    local.get 0
    i32.const 4
    i32.add
    local.set 1
    block  ;; label = @1
      local.get 0
      i32.load
      br_if 0 (;@1;)
      local.get 1
      call $_ZN4core3ptr13drop_in_place17h20a31f032c7e70f2E
      return
    end
    block  ;; label = @1
      local.get 1
      i32.load
      i32.eqz
      br_if 0 (;@1;)
      local.get 0
      i32.const 8
      i32.add
      call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
    end)
  (func $_ZN62_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..AllocRef$GT$5alloc17h91e855b0ff6b448aE (type 11) (param i32 i32 i32)
    block  ;; label = @1
      block  ;; label = @2
        local.get 1
        br_if 0 (;@2;)
        i32.const 0
        local.set 1
        br 1 (;@1;)
      end
      local.get 1
      local.get 2
      call $__rust_alloc
      local.set 2
    end
    local.get 0
    local.get 1
    i32.store offset=4
    local.get 0
    local.get 2
    i32.store)
  (func $__rust_realloc (type 5) (param i32 i32 i32 i32) (result i32)
    local.get 0
    local.get 1
    local.get 2
    local.get 3
    call $__rg_realloc)
  (func $_ZN5alloc7raw_vec17capacity_overflow17h52126f2f7e3db953E (type 12)
    i32.const 1048940
    i32.const 17
    i32.const 1048960
    call $_ZN4core9panicking5panic17hd15de8dad3ad5968E
    unreachable)
  (func $_ZN5alloc5alloc18handle_alloc_error17h94b61eaffc13868aE (type 12)
    call $rust_oom
    unreachable)
  (func $_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$11allocate_in17h1842a5e89cc73292E (type 11) (param i32 i32 i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 3
    global.set 0
    block  ;; label = @1
      block  ;; label = @2
        local.get 1
        i32.const -1
        i32.le_s
        br_if 0 (;@2;)
        local.get 3
        i32.const 8
        i32.add
        local.get 1
        local.get 2
        call $_ZN62_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..AllocRef$GT$5alloc17h91e855b0ff6b448aE.85
        local.get 3
        i32.load offset=8
        local.tee 1
        i32.eqz
        br_if 1 (;@1;)
        local.get 3
        i32.load offset=12
        local.set 2
        local.get 0
        local.get 1
        i32.store
        local.get 0
        local.get 2
        i32.store offset=4
        local.get 3
        i32.const 16
        i32.add
        global.set 0
        return
      end
      call $_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$11allocate_in28_$u7b$$u7b$closure$u7d$$u7d$17hfe2a34813757d41fE
      unreachable
    end
    call $_ZN5alloc5alloc18handle_alloc_error17h94b61eaffc13868aE
    unreachable)
  (func $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE (type 11) (param i32 i32 i32)
    (local i32 i32 i32 i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 3
    global.set 0
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          local.get 0
          i32.load offset=4
          local.tee 4
          local.get 0
          i32.load offset=8
          local.tee 5
          i32.sub
          local.get 2
          i32.ge_u
          br_if 0 (;@3;)
          local.get 5
          local.get 2
          i32.add
          local.tee 6
          local.get 5
          i32.lt_u
          br_if 1 (;@2;)
          local.get 4
          i32.const 1
          i32.shl
          local.tee 5
          local.get 6
          local.get 5
          local.get 6
          i32.gt_u
          select
          local.tee 5
          i32.const 0
          i32.lt_s
          br_if 1 (;@2;)
          block  ;; label = @4
            block  ;; label = @5
              local.get 4
              br_if 0 (;@5;)
              local.get 3
              i32.const 8
              i32.add
              local.get 5
              i32.const 0
              call $_ZN62_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..AllocRef$GT$5alloc17h91e855b0ff6b448aE.85
              local.get 3
              i32.load offset=8
              local.tee 6
              i32.eqz
              br_if 4 (;@1;)
              local.get 3
              i32.load offset=12
              local.set 4
              br 1 (;@4;)
            end
            local.get 0
            i32.load
            local.set 6
            block  ;; label = @5
              block  ;; label = @6
                local.get 5
                local.get 4
                i32.eq
                local.tee 7
                i32.eqz
                br_if 0 (;@6;)
                local.get 6
                i32.const 0
                local.get 7
                select
                local.set 6
                br 1 (;@5;)
              end
              local.get 6
              local.get 4
              i32.const 1
              local.get 5
              call $__rust_realloc
              local.set 6
              local.get 5
              local.set 4
            end
            local.get 6
            i32.eqz
            br_if 3 (;@1;)
          end
          local.get 0
          local.get 4
          i32.store offset=4
          local.get 0
          local.get 6
          i32.store
        end
        local.get 0
        i32.load
        local.get 0
        i32.load offset=8
        local.tee 4
        i32.add
        local.get 1
        local.get 2
        call $memcpy
        drop
        local.get 0
        local.get 4
        local.get 2
        i32.add
        i32.store offset=8
        local.get 3
        i32.const 16
        i32.add
        global.set 0
        return
      end
      call $_ZN5alloc7raw_vec17capacity_overflow17h52126f2f7e3db953E
      unreachable
    end
    call $_ZN5alloc5alloc18handle_alloc_error17h94b61eaffc13868aE
    unreachable)
  (func $__rust_alloc (type 1) (param i32 i32) (result i32)
    local.get 0
    local.get 1
    call $__rg_alloc)
  (func $_ZN63_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$core..clone..Clone$GT$5clone17h54aaea0aa5028552E (type 6) (param i32 i32)
    local.get 0
    local.get 1
    i32.load
    local.get 1
    i32.load offset=8
    call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E)
  (func $_ZN67_$LT$usize$u20$as$u20$elrond_wasm..esd_light..codec_ser..Encode$GT$13dep_encode_to17hfc2ac1d97ddffe18E (type 6) (param i32 i32)
    (local i32 i64 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    local.get 2
    i64.const 0
    i64.store offset=8
    local.get 0
    i64.extend_i32_u
    local.set 3
    i32.const 24
    local.set 0
    local.get 2
    i32.const 8
    i32.add
    local.set 4
    block  ;; label = @1
      loop  ;; label = @2
        local.get 0
        i32.const -8
        i32.eq
        br_if 1 (;@1;)
        local.get 4
        local.get 3
        local.get 0
        i32.const 56
        i32.and
        i64.extend_i32_u
        i64.shr_u
        i64.store8
        local.get 4
        i32.const 1
        i32.add
        local.set 4
        local.get 0
        i32.const -8
        i32.add
        local.set 0
        br 0 (;@2;)
      end
    end
    local.get 1
    local.get 2
    i32.const 8
    i32.add
    i32.const 4
    call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
    local.get 2
    i32.const 16
    i32.add
    global.set 0)
  (func $_ZN77_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$core..ops..index..Index$LT$I$GT$$GT$5index17h36220da57a371e66E (type 0) (param i32 i32 i32) (result i32)
    (local i32)
    block  ;; label = @1
      local.get 0
      i32.load offset=8
      local.tee 3
      local.get 1
      i32.gt_u
      br_if 0 (;@1;)
      local.get 1
      local.get 3
      local.get 2
      call $_ZN4core9panicking18panic_bounds_check17ha5804550fa0d0ae9E
      unreachable
    end
    local.get 0
    i32.load
    local.get 1
    i32.const 12
    i32.mul
    i32.add)
  (func $_ZN4core9panicking18panic_bounds_check17ha5804550fa0d0ae9E (type 11) (param i32 i32 i32)
    (local i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 3
    global.set 0
    local.get 3
    local.get 1
    i32.store offset=4
    local.get 3
    local.get 0
    i32.store
    local.get 3
    i32.const 28
    i32.add
    i32.const 2
    i32.store
    local.get 3
    i32.const 44
    i32.add
    i32.const 1
    i32.store
    local.get 3
    i64.const 2
    i64.store offset=12 align=4
    local.get 3
    i32.const 1049128
    i32.store offset=8
    local.get 3
    i32.const 1
    i32.store offset=36
    local.get 3
    local.get 3
    i32.const 32
    i32.add
    i32.store offset=24
    local.get 3
    local.get 3
    i32.store offset=40
    local.get 3
    local.get 3
    i32.const 4
    i32.add
    i32.store offset=32
    local.get 3
    i32.const 8
    i32.add
    local.get 2
    call $_ZN4core9panicking9panic_fmt17h89af7b08942b8a76E
    unreachable)
  (func $_ZN86_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$elrond_wasm..esd_light..codec_ser..Encode$GT$13dep_encode_to17hac65f1e455c909c4E (type 6) (param i32 i32)
    (local i32 i32 i32 i64 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    local.get 0
    i32.load
    local.set 3
    local.get 0
    i32.load offset=8
    local.set 4
    local.get 2
    i64.const 0
    i64.store offset=8
    local.get 4
    i64.extend_i32_u
    local.set 5
    i32.const 24
    local.set 0
    local.get 2
    i32.const 8
    i32.add
    local.set 6
    block  ;; label = @1
      loop  ;; label = @2
        local.get 0
        i32.const -8
        i32.eq
        br_if 1 (;@1;)
        local.get 6
        local.get 5
        local.get 0
        i32.const 56
        i32.and
        i64.extend_i32_u
        i64.shr_u
        i64.store8
        local.get 6
        i32.const 1
        i32.add
        local.set 6
        local.get 0
        i32.const -8
        i32.add
        local.set 0
        br 0 (;@2;)
      end
    end
    local.get 1
    local.get 2
    i32.const 8
    i32.add
    i32.const 4
    call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
    local.get 1
    local.get 3
    local.get 4
    call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
    local.get 2
    i32.const 16
    i32.add
    global.set 0)
  (func $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$18get_stake_per_node17h4dba662bd8dbc5bcE (type 4) (result i32)
    (local i32)
    i32.const 1048627
    i32.const 14
    i64.const 0
    call $bigIntNew
    local.tee 0
    call $bigIntStorageLoadUnsigned
    drop
    local.get 0)
  (func $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$18is_staking_failure17h92c97d246d1eaf87E (type 4) (result i32)
    i32.const 1048705
    i32.const 15
    call $int64storageLoad
    i64.const 0
    i64.ne)
  (func $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$24get_bls_deliberate_error17hd242d5779b7b97b0E (type 3) (param i32) (result i32)
    (local i32 i64)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 1
    global.set 0
    local.get 1
    i32.const 1048720
    i32.const 20
    call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
    local.get 0
    local.get 1
    call $_ZN86_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$elrond_wasm..esd_light..codec_ser..Encode$GT$13dep_encode_to17hac65f1e455c909c4E
    local.get 1
    i32.load
    local.get 1
    i32.load offset=8
    call $int64storageLoad
    local.set 2
    local.get 1
    call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
    local.get 1
    i32.const 16
    i32.add
    global.set 0
    local.get 2
    i32.wrap_i64)
  (func $setBlsDeliberateError (type 12)
    (local i32 i32 i64)
    global.get 0
    i32.const 80
    i32.sub
    local.tee 0
    global.set 0
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$17check_not_payable17he0be00cca6a3716bE
    i32.const 2
    call $_ZN11elrond_wasm13ContractIOApi19check_num_arguments17h868a6eb9bef29c05E
    local.get 0
    i32.const 16
    i32.add
    i32.const 0
    i32.const 1048740
    i32.const 7
    call $_ZN11elrond_wasm2io19arg_loader_endpoint15load_single_arg17h10003b39bc032a7eE
    local.get 0
    i32.const 32
    i32.add
    i32.const 1
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$16get_argument_vec17h2c9ae2ed10b8f5ecE
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          local.get 0
          i32.load offset=40
          local.tee 1
          i32.const 1
          i32.gt_u
          br_if 0 (;@3;)
          i64.const 0
          local.set 2
          local.get 1
          br_table 2 (;@1;) 1 (;@2;) 2 (;@1;)
        end
        local.get 0
        local.get 1
        i32.store offset=52
        local.get 0
        i32.const 1
        i32.store offset=48
        local.get 0
        i32.const 0
        i32.store offset=72
        local.get 0
        i64.const 1
        i64.store offset=64
        local.get 0
        i32.const 64
        i32.add
        i32.const 1048601
        i32.const 23
        call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
        local.get 0
        i32.const 64
        i32.add
        i32.const 1048747
        i32.const 8
        call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
        local.get 0
        i32.const 64
        i32.add
        i32.const 1048624
        i32.const 3
        call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
        local.get 0
        i32.const 8
        i32.add
        local.get 0
        i32.const 48
        i32.add
        call $_ZN11elrond_wasm9esd_light9codec_err11DecodeError13message_bytes17h385071718cc192c4E
        local.get 0
        i32.const 64
        i32.add
        local.get 0
        i32.load offset=8
        local.get 0
        i32.load offset=12
        call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
        local.get 0
        i32.load offset=64
        local.get 0
        i32.load offset=72
        call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$12signal_error17h976338bc113e8d25E
        unreachable
      end
      local.get 0
      i32.load offset=32
      i64.load8_u
      local.set 2
    end
    local.get 0
    i32.const 32
    i32.add
    call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
    local.get 0
    i32.const 64
    i32.add
    i32.const 1048720
    i32.const 20
    call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
    local.get 0
    i32.const 16
    i32.add
    local.get 0
    i32.const 64
    i32.add
    call $_ZN86_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$elrond_wasm..esd_light..codec_ser..Encode$GT$13dep_encode_to17hac65f1e455c909c4E
    local.get 0
    i32.load offset=64
    local.get 0
    i32.load offset=72
    local.get 2
    call $int64storageStore
    drop
    local.get 0
    i32.const 64
    i32.add
    call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
    local.get 0
    i32.const 16
    i32.add
    call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
    local.get 0
    i32.const 80
    i32.add
    global.set 0)
  (func $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$17check_not_payable17he0be00cca6a3716bE (type 12)
    (local i32)
    i64.const 0
    call $bigIntNew
    local.tee 0
    call $bigIntGetCallValue
    block  ;; label = @1
      local.get 0
      i64.const 0
      call $bigIntNew
      call $bigIntCmp
      i32.const 0
      i32.gt_s
      br_if 0 (;@1;)
      return
    end
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$12signal_error17h976338bc113e8d25E.125
    unreachable)
  (func $_ZN11elrond_wasm9esd_light9codec_err11DecodeError13message_bytes17h385071718cc192c4E (type 6) (param i32 i32)
    (local i32 i32)
    i32.const 1049542
    local.set 2
    i32.const 15
    local.set 3
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                local.get 1
                i32.load
                br_table 5 (;@1;) 1 (;@5;) 2 (;@4;) 3 (;@3;) 4 (;@2;) 0 (;@6;) 5 (;@1;)
              end
              local.get 1
              i32.const 8
              i32.add
              i32.load
              local.set 3
              local.get 1
              i32.load offset=4
              local.set 2
              br 4 (;@1;)
            end
            i32.const 1049528
            local.set 2
            i32.const 14
            local.set 3
            br 3 (;@1;)
          end
          i32.const 1049515
          local.set 2
          i32.const 13
          local.set 3
          br 2 (;@1;)
        end
        i32.const 1049494
        local.set 2
        i32.const 21
        local.set 3
        br 1 (;@1;)
      end
      i32.const 1049476
      local.set 2
      i32.const 18
      local.set 3
    end
    local.get 0
    local.get 3
    i32.store offset=4
    local.get 0
    local.get 2
    i32.store)
  (func $getBlsDeliberateError (type 12)
    (local i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 0
    global.set 0
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$17check_not_payable17he0be00cca6a3716bE
    i32.const 1
    call $_ZN11elrond_wasm13ContractIOApi19check_num_arguments17h868a6eb9bef29c05E
    local.get 0
    i32.const 0
    i32.const 1048740
    i32.const 7
    call $_ZN11elrond_wasm2io19arg_loader_endpoint15load_single_arg17h10003b39bc032a7eE
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        call $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$24get_bls_deliberate_error17hd242d5779b7b97b0E
        local.tee 1
        i32.const 255
        i32.and
        i32.eqz
        br_if 0 (;@2;)
        local.get 0
        local.get 1
        i32.store8 offset=15
        local.get 0
        i32.const 15
        i32.add
        i32.const 1
        call $finish
        br 1 (;@1;)
      end
      i32.const 1049476
      i32.const 0
      call $finish
    end
    local.get 0
    call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
    local.get 0
    i32.const 16
    i32.add
    global.set 0)
  (func $_ZN131_$LT$auction_mock..AuctionMockImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..AuctionMock$LT$T$C$BigInt$C$BigUint$GT$$GT$8callback17hd698b2a4cef2e82fE (type 12)
    i32.const 1048884
    i32.const 24
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$12signal_error17h976338bc113e8d25E
    unreachable)
  (func $init (type 12)
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$17check_not_payable17he0be00cca6a3716bE
    i32.const 0
    call $_ZN11elrond_wasm13ContractIOApi19check_num_arguments17h868a6eb9bef29c05E)
  (func $stake (type 12)
    (local i32 i32 i32 i64 i32 i32 i32 i32 i32)
    global.get 0
    i32.const 96
    i32.sub
    local.tee 0
    global.set 0
    local.get 0
    call $getNumArguments
    local.tee 1
    i32.store offset=24
    local.get 0
    i32.const 0
    i32.store offset=20
    local.get 0
    local.get 0
    i32.const 88
    i32.add
    i32.store offset=16
    block  ;; label = @1
      block  ;; label = @2
        local.get 1
        i32.const 1
        i32.lt_s
        br_if 0 (;@2;)
        local.get 0
        i32.const 56
        i32.add
        i32.const 0
        call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$16get_argument_vec17h2c9ae2ed10b8f5ecE
        local.get 0
        i32.load offset=64
        local.tee 2
        i32.const 5
        i32.lt_u
        br_if 1 (;@1;)
        local.get 0
        local.get 2
        i32.store offset=76
        local.get 0
        i32.const 1
        i32.store offset=72
        local.get 0
        i32.const 0
        i32.store offset=40
        local.get 0
        i64.const 1
        i64.store offset=32
        local.get 0
        i32.const 32
        i32.add
        i32.const 1048601
        i32.const 23
        call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
        local.get 0
        i32.const 32
        i32.add
        i32.const 1048641
        i32.const 9
        call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
        local.get 0
        i32.const 32
        i32.add
        i32.const 1048624
        i32.const 3
        call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
        local.get 0
        i32.const 8
        i32.add
        local.get 0
        i32.const 72
        i32.add
        call $_ZN11elrond_wasm9esd_light9codec_err11DecodeError13message_bytes17h385071718cc192c4E
        local.get 0
        i32.const 32
        i32.add
        local.get 0
        i32.load offset=8
        local.get 0
        i32.load offset=12
        call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
        local.get 0
        i32.load offset=32
        local.get 0
        i32.load offset=40
        call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$12signal_error17h976338bc113e8d25E
        unreachable
      end
      local.get 0
      i32.const 40
      i32.add
      i32.const 25
      i32.store
      local.get 0
      i32.const 1048576
      i32.store offset=36
      local.get 0
      i32.const 0
      i32.store offset=32
      local.get 0
      i32.const 32
      i32.add
      call $_ZN152_$LT$elrond_wasm..io..arg_loader_err..DynEndpointErrHandler$LT$A$C$BigInt$C$BigUint$GT$$u20$as$u20$elrond_wasm..io..arg_loader_err..DynArgErrHandler$GT$15handle_sc_error17hfe814566389c223aE
      unreachable
    end
    block  ;; label = @1
      block  ;; label = @2
        local.get 2
        br_if 0 (;@2;)
        i64.const 0
        local.set 3
        br 1 (;@1;)
      end
      local.get 0
      i32.load offset=56
      local.set 4
      i64.const 0
      local.set 3
      loop  ;; label = @2
        local.get 2
        i32.eqz
        br_if 1 (;@1;)
        local.get 2
        i32.const -1
        i32.add
        local.set 2
        local.get 3
        i64.const 8
        i64.shl
        local.get 4
        i64.load8_u
        i64.or
        local.set 3
        local.get 4
        i32.const 1
        i32.add
        local.set 4
        br 0 (;@2;)
      end
    end
    local.get 0
    i32.const 56
    i32.add
    call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
    local.get 0
    i32.const 1
    i32.store offset=20
    i32.const 0
    local.set 2
    local.get 0
    i32.const 0
    i32.store offset=64
    local.get 0
    i64.const 4
    i64.store offset=56
    local.get 3
    i32.wrap_i64
    local.tee 5
    i32.const 1
    i32.shl
    local.set 6
    i32.const 1
    local.set 4
    block  ;; label = @1
      block  ;; label = @2
        loop  ;; label = @3
          block  ;; label = @4
            block  ;; label = @5
              local.get 4
              local.get 1
              i32.ge_s
              br_if 0 (;@5;)
              local.get 2
              local.get 6
              i32.lt_u
              br_if 1 (;@4;)
            end
            local.get 2
            local.get 6
            i32.ge_u
            br_if 3 (;@1;)
            i32.const 0
            local.set 1
            i32.const 1048576
            local.set 4
            i32.const 25
            local.set 7
            br 2 (;@2;)
          end
          local.get 0
          i32.const 32
          i32.add
          local.get 0
          i32.const 16
          i32.add
          i32.const 1048908
          i32.const 24
          call $_ZN66_$LT$T$u20$as$u20$elrond_wasm..io..arg_types..ArgType$LT$D$GT$$GT$4load17ha4069b2f65b1a2c3E
          local.get 0
          i32.load offset=44
          local.set 7
          local.get 0
          i32.load offset=40
          local.set 4
          local.get 0
          i32.load offset=36
          local.set 1
          block  ;; label = @4
            local.get 0
            i32.load offset=32
            i32.const 1
            i32.eq
            br_if 0 (;@4;)
            local.get 0
            local.get 7
            i32.store offset=80
            local.get 0
            local.get 4
            i32.store offset=76
            local.get 0
            local.get 1
            i32.store offset=72
            local.get 2
            i32.const 1
            i32.add
            local.set 2
            local.get 0
            i32.const 56
            i32.add
            local.get 0
            i32.const 72
            i32.add
            call $_ZN5alloc3vec12Vec$LT$T$GT$4push17h44b296365e57ad04E
            local.get 0
            i32.load offset=24
            local.set 1
            local.get 0
            i32.load offset=20
            local.set 4
            br 1 (;@3;)
          end
        end
        local.get 0
        i32.load offset=48
        local.set 2
      end
      local.get 0
      i32.const 56
      i32.add
      call $_ZN4core3ptr13drop_in_place17h20a31f032c7e70f2E
      local.get 0
      i32.const 44
      i32.add
      local.get 2
      i32.store
      local.get 0
      i32.const 40
      i32.add
      local.get 7
      i32.store
      local.get 0
      local.get 4
      i32.store offset=36
      local.get 0
      local.get 1
      i32.store offset=32
      local.get 0
      i32.const 32
      i32.add
      call $_ZN152_$LT$elrond_wasm..io..arg_loader_err..DynEndpointErrHandler$LT$A$C$BigInt$C$BigUint$GT$$u20$as$u20$elrond_wasm..io..arg_loader_err..DynArgErrHandler$GT$15handle_sc_error17hfe814566389c223aE
      unreachable
    end
    local.get 0
    i64.load offset=56
    local.set 3
    local.get 0
    i32.load offset=64
    local.set 2
    i64.const 0
    call $bigIntNew
    local.tee 7
    call $bigIntGetCallValue
    local.get 4
    local.get 1
    call $_ZN11elrond_wasm2io9arg_types18check_no_more_args17h477780b151f82e5fE
    local.get 0
    local.get 2
    i32.store offset=64
    local.get 0
    local.get 3
    i64.store offset=56
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            call $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$18is_staking_failure17h92c97d246d1eaf87E
            i32.eqz
            br_if 0 (;@4;)
            i32.const 39
            local.set 2
            i32.const 1048755
            local.set 1
            br 1 (;@3;)
          end
          i32.const 1048641
          i32.const 9
          call $int64storageLoad
          local.set 3
          local.get 7
          local.get 5
          call $_ZN93_$LT$elrond_wasm_node..big_uint..ArwenBigUint$u20$as$u20$core..convert..From$LT$usize$GT$$GT$4from17h5682ab983d3e4210E
          call $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$18get_stake_per_node17h4dba662bd8dbc5bcE
          call $_ZN82_$LT$elrond_wasm_node..big_uint..ArwenBigUint$u20$as$u20$core..ops..arith..Mul$GT$3mul17h2d997e5c44f727b7E
          call $bigIntCmp
          i32.eqz
          br_if 1 (;@2;)
          i32.const 33
          local.set 2
          i32.const 1048794
          local.set 1
        end
        local.get 0
        i32.const 44
        i32.add
        local.get 2
        i32.store
        local.get 0
        i32.const 40
        i32.add
        local.get 1
        i32.store
        local.get 0
        i64.const 1
        i64.store offset=32
        br 1 (;@1;)
      end
      i32.const 0
      local.set 2
      local.get 0
      i32.const 0
      i32.store offset=80
      local.get 0
      i64.const 4
      i64.store offset=72
      local.get 3
      i32.wrap_i64
      local.set 8
      i32.const 1
      local.set 1
      loop  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            local.get 2
            local.get 5
            i32.ge_u
            br_if 0 (;@4;)
            local.get 2
            i32.const 1
            i32.add
            local.tee 7
            local.get 2
            i32.ge_u
            br_if 1 (;@3;)
          end
          i32.const 1048641
          i32.const 9
          local.get 8
          local.get 2
          i32.add
          i64.extend_i32_u
          call $int64storageStore
          drop
          local.get 0
          i32.const 44
          i32.add
          local.get 0
          i32.const 80
          i32.add
          i32.load
          i32.store
          local.get 0
          i32.const 0
          i32.store offset=32
          local.get 0
          local.get 0
          i64.load offset=72
          i64.store offset=36 align=4
          br 2 (;@1;)
        end
        local.get 0
        i32.const 56
        i32.add
        local.get 1
        i32.const -1
        i32.add
        i32.const 1048840
        call $_ZN77_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$core..ops..index..Index$LT$I$GT$$GT$5index17h36220da57a371e66E
        local.set 4
        local.get 0
        i32.const 32
        i32.add
        i32.const 1048650
        i32.const 13
        call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
        local.get 8
        local.get 2
        i32.add
        i32.const 1
        i32.add
        local.tee 2
        local.get 0
        i32.const 32
        i32.add
        call $_ZN67_$LT$usize$u20$as$u20$elrond_wasm..esd_light..codec_ser..Encode$GT$13dep_encode_to17hfc2ac1d97ddffe18E
        local.get 0
        i32.load offset=32
        local.get 0
        i32.load offset=40
        local.get 4
        call $_ZN11elrond_wasm7storage12storage_util11storage_set17hed34ed5d26b9ca60E
        local.get 0
        i32.const 32
        i32.add
        call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
        local.get 0
        i32.const 56
        i32.add
        local.get 1
        i32.const 1048856
        call $_ZN77_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$core..ops..index..Index$LT$I$GT$$GT$5index17h36220da57a371e66E
        local.set 6
        local.get 0
        i32.const 32
        i32.add
        i32.const 1048663
        i32.const 13
        call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
        local.get 2
        local.get 0
        i32.const 32
        i32.add
        call $_ZN67_$LT$usize$u20$as$u20$elrond_wasm..esd_light..codec_ser..Encode$GT$13dep_encode_to17hfc2ac1d97ddffe18E
        local.get 0
        i32.load offset=32
        local.get 0
        i32.load offset=40
        local.get 6
        call $_ZN11elrond_wasm7storage12storage_util11storage_set17hed34ed5d26b9ca60E
        local.get 0
        i32.const 32
        i32.add
        call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
        block  ;; label = @3
          local.get 4
          call $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$24get_bls_deliberate_error17hd242d5779b7b97b0E
          local.tee 2
          i32.const 255
          i32.and
          i32.eqz
          br_if 0 (;@3;)
          local.get 0
          i32.const 32
          i32.add
          local.get 4
          call $_ZN63_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$core..clone..Clone$GT$5clone17h54aaea0aa5028552E
          local.get 0
          i32.const 72
          i32.add
          local.get 0
          i32.const 32
          i32.add
          call $_ZN5alloc3vec12Vec$LT$T$GT$4push17h44b296365e57ad04E
          local.get 0
          local.get 2
          i32.store8 offset=87
          local.get 0
          i32.const 32
          i32.add
          local.get 0
          i32.const 87
          i32.add
          i32.const 1
          call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
          local.get 0
          i32.const 72
          i32.add
          local.get 0
          i32.const 32
          i32.add
          call $_ZN5alloc3vec12Vec$LT$T$GT$4push17h44b296365e57ad04E
        end
        local.get 1
        i32.const 2
        i32.add
        local.set 1
        local.get 7
        local.set 2
        br 0 (;@2;)
      end
    end
    local.get 0
    i32.const 56
    i32.add
    call $_ZN4core3ptr13drop_in_place17h20a31f032c7e70f2E
    local.get 0
    i32.const 32
    i32.add
    call $_ZN121_$LT$core..result..Result$LT$T$C$E$GT$$u20$as$u20$elrond_wasm..io..finish..EndpointResult$LT$A$C$BigInt$C$BigUint$GT$$GT$6finish17h79242137cf3aa830E
    local.get 0
    i32.const 32
    i32.add
    call $_ZN4core3ptr13drop_in_place17h6d2c218039e34872E
    local.get 0
    i32.const 96
    i32.add
    global.set 0)
  (func $_ZN93_$LT$elrond_wasm_node..big_uint..ArwenBigUint$u20$as$u20$core..convert..From$LT$usize$GT$$GT$4from17h5682ab983d3e4210E (type 3) (param i32) (result i32)
    local.get 0
    i64.extend_i32_u
    call $bigIntNew)
  (func $_ZN82_$LT$elrond_wasm_node..big_uint..ArwenBigUint$u20$as$u20$core..ops..arith..Mul$GT$3mul17h2d997e5c44f727b7E (type 1) (param i32 i32) (result i32)
    (local i32)
    i64.const 0
    call $bigIntNew
    local.tee 2
    local.get 0
    local.get 1
    call $bigIntMul
    local.get 2)
  (func $unStake (type 12)
    (local i32 i32 i32 i32 i32 i32)
    global.get 0
    i32.const 96
    i32.sub
    local.tee 0
    global.set 0
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$17check_not_payable17he0be00cca6a3716bE
    local.get 0
    call $getNumArguments
    i32.store offset=8
    i32.const 0
    local.set 1
    local.get 0
    i32.const 0
    i32.store offset=4
    local.get 0
    local.get 0
    i32.const 88
    i32.add
    i32.store
    local.get 0
    i32.const 16
    i32.add
    local.get 0
    call $_ZN11elrond_wasm2io9arg_types12load_dyn_arg17h4ecce73d85c983baE
    local.get 0
    i32.load offset=4
    local.get 0
    i32.load offset=8
    call $_ZN11elrond_wasm2io9arg_types18check_no_more_args17h477780b151f82e5fE
    local.get 0
    i32.const 56
    i32.add
    i32.const 8
    i32.add
    local.get 0
    i32.const 16
    i32.add
    i32.const 8
    i32.add
    i32.load
    i32.store
    local.get 0
    local.get 0
    i64.load offset=16
    i64.store offset=56
    block  ;; label = @1
      block  ;; label = @2
        call $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$18is_staking_failure17h92c97d246d1eaf87E
        br_if 0 (;@2;)
        local.get 0
        i32.const 0
        i32.store offset=80
        local.get 0
        i64.const 4
        i64.store offset=72
        local.get 0
        i32.load offset=64
        i32.const 1073741823
        i32.and
        local.set 2
        local.get 0
        i32.load offset=56
        local.set 3
        loop  ;; label = @3
          local.get 3
          local.set 4
          block  ;; label = @4
            local.get 2
            local.get 1
            i32.ne
            br_if 0 (;@4;)
            local.get 0
            i32.const 44
            i32.add
            local.get 0
            i32.const 80
            i32.add
            i32.load
            i32.store
            local.get 0
            local.get 0
            i64.load offset=72
            i64.store offset=36 align=4
            local.get 0
            i32.const 0
            i32.store offset=32
            br 3 (;@1;)
          end
          local.get 0
          i32.const 32
          i32.add
          i32.const 1048676
          i32.const 15
          call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
          local.get 1
          local.get 0
          i32.const 32
          i32.add
          call $_ZN67_$LT$usize$u20$as$u20$elrond_wasm..esd_light..codec_ser..Encode$GT$13dep_encode_to17hfc2ac1d97ddffe18E
          local.get 0
          i32.load offset=32
          local.get 0
          i32.load offset=40
          local.get 4
          call $_ZN11elrond_wasm7storage12storage_util11storage_set17hed34ed5d26b9ca60E
          local.get 4
          i32.const 12
          i32.add
          local.set 3
          local.get 1
          i32.const 1
          i32.add
          local.set 1
          local.get 0
          i32.const 32
          i32.add
          call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
          local.get 4
          call $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$24get_bls_deliberate_error17hd242d5779b7b97b0E
          local.tee 5
          i32.const 255
          i32.and
          i32.eqz
          br_if 0 (;@3;)
          local.get 0
          i32.const 32
          i32.add
          local.get 4
          call $_ZN63_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$core..clone..Clone$GT$5clone17h54aaea0aa5028552E
          local.get 0
          i32.const 72
          i32.add
          local.get 0
          i32.const 32
          i32.add
          call $_ZN5alloc3vec12Vec$LT$T$GT$4push17h44b296365e57ad04E
          local.get 0
          local.get 5
          i32.store8 offset=87
          local.get 0
          i32.const 32
          i32.add
          local.get 0
          i32.const 87
          i32.add
          i32.const 1
          call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
          local.get 0
          i32.const 72
          i32.add
          local.get 0
          i32.const 32
          i32.add
          call $_ZN5alloc3vec12Vec$LT$T$GT$4push17h44b296365e57ad04E
          br 0 (;@3;)
        end
      end
      local.get 0
      i32.const 44
      i32.add
      i32.const 39
      i32.store
      local.get 0
      i32.const 32
      i32.add
      i32.const 8
      i32.add
      i32.const 1048755
      i32.store
      local.get 0
      i64.const 1
      i64.store offset=32
    end
    local.get 0
    i32.const 56
    i32.add
    call $_ZN4core3ptr13drop_in_place17h20a31f032c7e70f2E
    local.get 0
    i32.const 32
    i32.add
    call $_ZN121_$LT$core..result..Result$LT$T$C$E$GT$$u20$as$u20$elrond_wasm..io..finish..EndpointResult$LT$A$C$BigInt$C$BigUint$GT$$GT$6finish17h79242137cf3aa830E
    local.get 0
    i32.const 32
    i32.add
    call $_ZN4core3ptr13drop_in_place17h6d2c218039e34872E
    local.get 0
    i32.const 96
    i32.add
    global.set 0)
  (func $unBond (type 12)
    (local i32 i32 i32 i32 i32 i32 i32 i64)
    global.get 0
    i32.const 160
    i32.sub
    local.tee 0
    global.set 0
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$17check_not_payable17he0be00cca6a3716bE
    local.get 0
    call $getNumArguments
    i32.store offset=16
    i32.const 0
    local.set 1
    local.get 0
    i32.const 0
    i32.store offset=12
    local.get 0
    local.get 0
    i32.const 152
    i32.add
    i32.store offset=8
    local.get 0
    i32.const 24
    i32.add
    local.get 0
    i32.const 8
    i32.add
    call $_ZN11elrond_wasm2io9arg_types12load_dyn_arg17h4ecce73d85c983baE
    local.get 0
    i32.load offset=12
    local.get 0
    i32.load offset=16
    call $_ZN11elrond_wasm2io9arg_types18check_no_more_args17h477780b151f82e5fE
    local.get 0
    i32.const 40
    i32.add
    i32.const 8
    i32.add
    local.get 0
    i32.const 24
    i32.add
    i32.const 8
    i32.add
    i32.load
    i32.store
    local.get 0
    local.get 0
    i64.load offset=24
    i64.store offset=40
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            call $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$18is_staking_failure17h92c97d246d1eaf87E
            br_if 0 (;@4;)
            local.get 0
            i32.const 0
            i32.store offset=64
            local.get 0
            i64.const 4
            i64.store offset=56
            local.get 0
            i32.load offset=48
            local.tee 2
            i32.const 1073741823
            i32.and
            local.set 3
            local.get 0
            i32.load offset=40
            local.set 4
            loop  ;; label = @5
              local.get 4
              local.set 5
              block  ;; label = @6
                local.get 3
                local.get 1
                i32.ne
                br_if 0 (;@6;)
                local.get 2
                call $_ZN93_$LT$elrond_wasm_node..big_uint..ArwenBigUint$u20$as$u20$core..convert..From$LT$usize$GT$$GT$4from17h5682ab983d3e4210E
                call $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$18get_stake_per_node17h4dba662bd8dbc5bcE
                call $_ZN82_$LT$elrond_wasm_node..big_uint..ArwenBigUint$u20$as$u20$core..ops..arith..Mul$GT$3mul17h2d997e5c44f727b7E
                local.set 1
                local.get 0
                i32.const 104
                i32.add
                i32.const 24
                i32.add
                local.tee 5
                i64.const 0
                i64.store
                local.get 0
                i32.const 104
                i32.add
                i32.const 16
                i32.add
                local.tee 4
                i64.const 0
                i64.store
                local.get 0
                i32.const 104
                i32.add
                i32.const 8
                i32.add
                local.tee 6
                i64.const 0
                i64.store
                local.get 0
                i64.const 0
                i64.store offset=104
                local.get 0
                i32.const 104
                i32.add
                call $getCaller
                local.get 0
                i32.const 72
                i32.add
                i32.const 24
                i32.add
                local.get 5
                i64.load
                i64.store
                local.get 0
                i32.const 72
                i32.add
                i32.const 16
                i32.add
                local.get 4
                i64.load
                i64.store
                local.get 0
                i32.const 72
                i32.add
                i32.const 8
                i32.add
                local.get 6
                i64.load
                i64.store
                local.get 0
                local.get 0
                i64.load offset=104
                i64.store offset=72
                local.get 1
                call $bigIntUnsignedByteLength
                local.tee 4
                i32.const 32
                i32.gt_u
                br_if 5 (;@1;)
                local.get 0
                i32.const 32
                i32.const 1
                call $_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$11allocate_in17h1842a5e89cc73292E
                local.get 0
                i64.load32_u offset=4
                local.set 7
                local.get 0
                i32.load
                local.set 5
                block  ;; label = @7
                  local.get 4
                  i32.eqz
                  br_if 0 (;@7;)
                  i32.const 32
                  local.get 4
                  i32.sub
                  local.tee 4
                  i32.const 32
                  i32.ge_u
                  br_if 5 (;@2;)
                  local.get 1
                  local.get 5
                  local.get 4
                  i32.add
                  call $bigIntGetUnsignedBytes
                  drop
                end
                local.get 5
                i32.eqz
                br_if 5 (;@1;)
                local.get 0
                local.get 7
                i64.const 137438953472
                i64.or
                i64.store offset=140 align=4
                local.get 0
                local.get 5
                i32.store offset=136
                local.get 0
                i32.const 72
                i32.add
                local.get 5
                i32.const 1048872
                i32.const 12
                call $transferValue
                drop
                local.get 0
                i32.const 136
                i32.add
                call $_ZN77_$LT$alloc..raw_vec..RawVec$LT$T$C$A$GT$$u20$as$u20$core..ops..drop..Drop$GT$4drop17hc7f6833a34267be8E
                local.get 0
                i32.const 104
                i32.add
                i32.const 12
                i32.add
                local.get 0
                i32.const 64
                i32.add
                i32.load
                i32.store
                local.get 0
                i32.const 0
                i32.store offset=104
                local.get 0
                local.get 0
                i64.load offset=56
                i64.store offset=108 align=4
                br 3 (;@3;)
              end
              local.get 0
              i32.const 104
              i32.add
              i32.const 1048691
              i32.const 14
              call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
              local.get 1
              local.get 0
              i32.const 104
              i32.add
              call $_ZN67_$LT$usize$u20$as$u20$elrond_wasm..esd_light..codec_ser..Encode$GT$13dep_encode_to17hfc2ac1d97ddffe18E
              local.get 0
              i32.load offset=104
              local.get 0
              i32.load offset=112
              local.get 5
              call $_ZN11elrond_wasm7storage12storage_util11storage_set17hed34ed5d26b9ca60E
              local.get 5
              i32.const 12
              i32.add
              local.set 4
              local.get 1
              i32.const 1
              i32.add
              local.set 1
              local.get 0
              i32.const 104
              i32.add
              call $_ZN4core3ptr13drop_in_place17h2bf718bacc71dfaaE
              local.get 5
              call $_ZN163_$LT$auction_mock..storage..AuctionMockStorageImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..storage..AuctionMockStorage$LT$T$C$BigInt$C$BigUint$GT$$GT$24get_bls_deliberate_error17hd242d5779b7b97b0E
              local.tee 6
              i32.const 255
              i32.and
              i32.eqz
              br_if 0 (;@5;)
              local.get 0
              i32.const 104
              i32.add
              local.get 5
              call $_ZN63_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$core..clone..Clone$GT$5clone17h54aaea0aa5028552E
              local.get 0
              i32.const 56
              i32.add
              local.get 0
              i32.const 104
              i32.add
              call $_ZN5alloc3vec12Vec$LT$T$GT$4push17h44b296365e57ad04E
              local.get 0
              local.get 6
              i32.store8 offset=72
              local.get 0
              i32.const 104
              i32.add
              local.get 0
              i32.const 72
              i32.add
              i32.const 1
              call $_ZN5alloc5slice29_$LT$impl$u20$$u5b$T$u5d$$GT$6to_vec17ha9af83175413d8f4E
              local.get 0
              i32.const 56
              i32.add
              local.get 0
              i32.const 104
              i32.add
              call $_ZN5alloc3vec12Vec$LT$T$GT$4push17h44b296365e57ad04E
              br 0 (;@5;)
            end
          end
          local.get 0
          i32.const 116
          i32.add
          i32.const 39
          i32.store
          local.get 0
          i32.const 104
          i32.add
          i32.const 8
          i32.add
          i32.const 1048755
          i32.store
          local.get 0
          i64.const 1
          i64.store offset=104
        end
        local.get 0
        i32.const 40
        i32.add
        call $_ZN4core3ptr13drop_in_place17h20a31f032c7e70f2E
        local.get 0
        i32.const 104
        i32.add
        call $_ZN121_$LT$core..result..Result$LT$T$C$E$GT$$u20$as$u20$elrond_wasm..io..finish..EndpointResult$LT$A$C$BigInt$C$BigUint$GT$$GT$6finish17h79242137cf3aa830E
        local.get 0
        i32.const 104
        i32.add
        call $_ZN4core3ptr13drop_in_place17h6d2c218039e34872E
        local.get 0
        i32.const 160
        i32.add
        global.set 0
        return
      end
      local.get 4
      i32.const 32
      i32.const 1049720
      call $_ZN4core9panicking18panic_bounds_check17ha5804550fa0d0ae9E
      unreachable
    end
    i32.const 1049576
    i32.const 43
    i32.const 1049560
    call $_ZN4core9panicking5panic17hd15de8dad3ad5968E
    unreachable)
  (func $_ZN4core9panicking5panic17hd15de8dad3ad5968E (type 11) (param i32 i32 i32)
    (local i32)
    global.get 0
    i32.const 32
    i32.sub
    local.tee 3
    global.set 0
    local.get 3
    i32.const 20
    i32.add
    i32.const 0
    i32.store
    local.get 3
    i32.const 1049476
    i32.store offset=16
    local.get 3
    i64.const 1
    i64.store offset=4 align=4
    local.get 3
    local.get 1
    i32.store offset=28
    local.get 3
    local.get 0
    i32.store offset=24
    local.get 3
    local.get 3
    i32.const 24
    i32.add
    i32.store
    local.get 3
    local.get 2
    call $_ZN4core9panicking9panic_fmt17h89af7b08942b8a76E
    unreachable)
  (func $claim (type 12)
    call $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$17check_not_payable17he0be00cca6a3716bE
    i32.const 0
    call $_ZN11elrond_wasm13ContractIOApi19check_num_arguments17h868a6eb9bef29c05E)
  (func $callBack (type 12)
    call $_ZN131_$LT$auction_mock..AuctionMockImpl$LT$T$C$BigInt$C$BigUint$GT$$u20$as$u20$auction_mock..AuctionMock$LT$T$C$BigInt$C$BigUint$GT$$GT$8callback17hd698b2a4cef2e82fE
    unreachable)
  (func $__rg_alloc (type 1) (param i32 i32) (result i32)
    local.get 0
    local.get 1
    call $_ZN72_$LT$wee_alloc..WeeAlloc$u20$as$u20$core..alloc..global..GlobalAlloc$GT$5alloc17h9505c3565944e308E)
  (func $__rg_dealloc (type 11) (param i32 i32 i32)
    local.get 0
    local.get 1
    local.get 2
    call $_ZN72_$LT$wee_alloc..WeeAlloc$u20$as$u20$core..alloc..global..GlobalAlloc$GT$7dealloc17h840365e51912c7bcE)
  (func $__rg_realloc (type 5) (param i32 i32 i32 i32) (result i32)
    (local i32)
    block  ;; label = @1
      local.get 3
      local.get 2
      call $_ZN72_$LT$wee_alloc..WeeAlloc$u20$as$u20$core..alloc..global..GlobalAlloc$GT$5alloc17h9505c3565944e308E
      local.tee 4
      i32.eqz
      br_if 0 (;@1;)
      local.get 4
      local.get 0
      local.get 3
      local.get 1
      local.get 1
      local.get 3
      i32.gt_u
      select
      call $memcpy
      drop
      local.get 0
      local.get 1
      local.get 2
      call $_ZN72_$LT$wee_alloc..WeeAlloc$u20$as$u20$core..alloc..global..GlobalAlloc$GT$7dealloc17h840365e51912c7bcE
    end
    local.get 4)
  (func $__rust_alloc_zeroed (type 3) (param i32) (result i32)
    local.get 0
    call $__rg_alloc_zeroed)
  (func $__rg_alloc_zeroed (type 3) (param i32) (result i32)
    (local i32)
    block  ;; label = @1
      local.get 0
      i32.const 1
      call $_ZN72_$LT$wee_alloc..WeeAlloc$u20$as$u20$core..alloc..global..GlobalAlloc$GT$5alloc17h9505c3565944e308E
      local.tee 1
      i32.eqz
      br_if 0 (;@1;)
      local.get 1
      i32.const 0
      local.get 0
      call $memset
      drop
    end
    local.get 1)
  (func $rust_oom (type 12)
    i32.const 1049893
    i32.const 16
    call $_ZN16elrond_wasm_node9ext_error12signal_error17h3e53d6674adb9999E.120
    unreachable)
  (func $_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$11allocate_in28_$u7b$$u7b$closure$u7d$$u7d$17hc32f2ac315b545e4E (type 12)
    call $_ZN5alloc5alloc18handle_alloc_error17h94b61eaffc13868aE
    unreachable)
  (func $_ZN109_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..SpecExtend$LT$$RF$T$C$core..slice..Iter$LT$T$GT$$GT$$GT$11spec_extend17h87dd1224d4828d6fE (type 11) (param i32 i32 i32)
    (local i32 i32 i32 i32)
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            local.get 0
            i32.const 4
            i32.add
            i32.load
            local.tee 3
            local.get 0
            i32.const 8
            i32.add
            i32.load
            local.tee 4
            i32.sub
            local.get 2
            local.get 1
            i32.sub
            local.tee 2
            i32.lt_u
            br_if 0 (;@4;)
            local.get 0
            i32.load
            local.set 5
            br 1 (;@3;)
          end
          local.get 4
          local.get 2
          i32.add
          local.tee 5
          local.get 4
          i32.lt_u
          br_if 1 (;@2;)
          local.get 3
          i32.const 1
          i32.shl
          local.tee 6
          local.get 5
          local.get 6
          local.get 5
          i32.gt_u
          select
          local.tee 6
          i32.const 0
          i32.lt_s
          br_if 1 (;@2;)
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                local.get 3
                i32.eqz
                br_if 0 (;@6;)
                local.get 0
                i32.load
                local.tee 5
                br_if 1 (;@5;)
              end
              block  ;; label = @6
                local.get 6
                br_if 0 (;@6;)
                i32.const 1
                local.set 5
                br 2 (;@4;)
              end
              local.get 6
              i32.const 1
              call $__rust_alloc
              local.tee 5
              br_if 1 (;@4;)
              br 4 (;@1;)
            end
            block  ;; label = @5
              local.get 3
              local.get 6
              i32.eq
              br_if 0 (;@5;)
              local.get 5
              local.get 3
              i32.const 1
              local.get 6
              call $__rust_realloc
              local.set 5
            end
            local.get 5
            i32.eqz
            br_if 3 (;@1;)
            local.get 0
            i32.const 8
            i32.add
            i32.load
            local.set 4
          end
          local.get 0
          local.get 5
          i32.store
          local.get 0
          i32.const 4
          i32.add
          local.get 6
          i32.store
        end
        local.get 5
        local.get 4
        i32.add
        local.get 1
        local.get 2
        call $memcpy
        drop
        local.get 0
        i32.const 8
        i32.add
        local.get 4
        local.get 2
        i32.add
        i32.store
        return
      end
      call $_ZN5alloc7raw_vec17capacity_overflow17h52126f2f7e3db953E
      unreachable
    end
    call $_ZN5alloc5alloc18handle_alloc_error17h94b61eaffc13868aE
    unreachable)
  (func $_ZN4core3ptr13drop_in_place17h0dc95bc6c2c4e7acE (type 10) (param i32))
  (func $_ZN50_$LT$$RF$mut$u20$W$u20$as$u20$core..fmt..Write$GT$9write_str17h5cc6f7e2d0e384f9E (type 0) (param i32 i32 i32) (result i32)
    local.get 0
    i32.load
    local.get 1
    local.get 1
    local.get 2
    i32.add
    call $_ZN109_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..SpecExtend$LT$$RF$T$C$core..slice..Iter$LT$T$GT$$GT$$GT$11spec_extend17h87dd1224d4828d6fE
    i32.const 0)
  (func $_ZN50_$LT$$RF$mut$u20$W$u20$as$u20$core..fmt..Write$GT$10write_char17h80f20bbe3df2881eE (type 1) (param i32 i32) (result i32)
    (local i32 i32 i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    local.get 0
    i32.load
    local.set 0
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                local.get 1
                i32.const 128
                i32.lt_u
                br_if 0 (;@6;)
                local.get 2
                i32.const 0
                i32.store offset=12
                local.get 1
                i32.const 2048
                i32.lt_u
                br_if 1 (;@5;)
                local.get 2
                i32.const 12
                i32.add
                local.set 3
                block  ;; label = @7
                  local.get 1
                  i32.const 65536
                  i32.ge_u
                  br_if 0 (;@7;)
                  local.get 2
                  local.get 1
                  i32.const 63
                  i32.and
                  i32.const 128
                  i32.or
                  i32.store8 offset=14
                  local.get 2
                  local.get 1
                  i32.const 6
                  i32.shr_u
                  i32.const 63
                  i32.and
                  i32.const 128
                  i32.or
                  i32.store8 offset=13
                  local.get 2
                  local.get 1
                  i32.const 12
                  i32.shr_u
                  i32.const 15
                  i32.and
                  i32.const 224
                  i32.or
                  i32.store8 offset=12
                  i32.const 3
                  local.set 1
                  br 5 (;@2;)
                end
                local.get 2
                local.get 1
                i32.const 63
                i32.and
                i32.const 128
                i32.or
                i32.store8 offset=15
                local.get 2
                local.get 1
                i32.const 18
                i32.shr_u
                i32.const 240
                i32.or
                i32.store8 offset=12
                local.get 2
                local.get 1
                i32.const 6
                i32.shr_u
                i32.const 63
                i32.and
                i32.const 128
                i32.or
                i32.store8 offset=14
                local.get 2
                local.get 1
                i32.const 12
                i32.shr_u
                i32.const 63
                i32.and
                i32.const 128
                i32.or
                i32.store8 offset=13
                i32.const 4
                local.set 1
                br 4 (;@2;)
              end
              block  ;; label = @6
                block  ;; label = @7
                  local.get 0
                  i32.load offset=8
                  local.tee 3
                  local.get 0
                  i32.const 4
                  i32.add
                  i32.load
                  i32.eq
                  br_if 0 (;@7;)
                  local.get 0
                  i32.load
                  local.set 4
                  br 1 (;@6;)
                end
                local.get 3
                i32.const 1
                i32.add
                local.tee 4
                local.get 3
                i32.lt_u
                br_if 2 (;@4;)
                local.get 3
                i32.const 1
                i32.shl
                local.tee 5
                local.get 4
                local.get 5
                local.get 4
                i32.gt_u
                select
                local.tee 5
                i32.const 0
                i32.lt_s
                br_if 2 (;@4;)
                block  ;; label = @7
                  block  ;; label = @8
                    block  ;; label = @9
                      local.get 3
                      i32.eqz
                      br_if 0 (;@9;)
                      local.get 0
                      i32.load
                      local.tee 4
                      br_if 1 (;@8;)
                    end
                    block  ;; label = @9
                      local.get 5
                      br_if 0 (;@9;)
                      i32.const 1
                      local.set 4
                      br 2 (;@7;)
                    end
                    local.get 5
                    i32.const 1
                    call $__rust_alloc
                    local.tee 4
                    br_if 1 (;@7;)
                    br 5 (;@3;)
                  end
                  block  ;; label = @8
                    local.get 3
                    local.get 5
                    i32.eq
                    br_if 0 (;@8;)
                    local.get 4
                    local.get 3
                    i32.const 1
                    local.get 5
                    call $__rust_realloc
                    local.set 4
                  end
                  local.get 4
                  i32.eqz
                  br_if 4 (;@3;)
                  local.get 0
                  i32.load offset=8
                  local.set 3
                end
                local.get 0
                local.get 4
                i32.store
                local.get 0
                i32.const 4
                i32.add
                local.get 5
                i32.store
              end
              local.get 4
              local.get 3
              i32.add
              local.get 1
              i32.store8
              local.get 0
              local.get 0
              i32.load offset=8
              i32.const 1
              i32.add
              i32.store offset=8
              br 4 (;@1;)
            end
            local.get 2
            local.get 1
            i32.const 63
            i32.and
            i32.const 128
            i32.or
            i32.store8 offset=13
            local.get 2
            local.get 1
            i32.const 6
            i32.shr_u
            i32.const 31
            i32.and
            i32.const 192
            i32.or
            i32.store8 offset=12
            local.get 2
            i32.const 12
            i32.add
            local.set 3
            i32.const 2
            local.set 1
            br 2 (;@2;)
          end
          call $_ZN5alloc7raw_vec17capacity_overflow17h52126f2f7e3db953E
          unreachable
        end
        call $_ZN5alloc5alloc18handle_alloc_error17h94b61eaffc13868aE
        unreachable
      end
      local.get 0
      local.get 3
      local.get 3
      local.get 1
      i32.add
      call $_ZN109_$LT$alloc..vec..Vec$LT$T$GT$$u20$as$u20$alloc..vec..SpecExtend$LT$$RF$T$C$core..slice..Iter$LT$T$GT$$GT$$GT$11spec_extend17h87dd1224d4828d6fE
    end
    local.get 2
    i32.const 16
    i32.add
    global.set 0
    i32.const 0)
  (func $_ZN50_$LT$$RF$mut$u20$W$u20$as$u20$core..fmt..Write$GT$9write_fmt17h3d6b4f53d0620b38E (type 1) (param i32 i32) (result i32)
    (local i32)
    global.get 0
    i32.const 32
    i32.sub
    local.tee 2
    global.set 0
    local.get 2
    local.get 0
    i32.load
    i32.store offset=4
    local.get 2
    i32.const 8
    i32.add
    i32.const 16
    i32.add
    local.get 1
    i32.const 16
    i32.add
    i64.load align=4
    i64.store
    local.get 2
    i32.const 8
    i32.add
    i32.const 8
    i32.add
    local.get 1
    i32.const 8
    i32.add
    i64.load align=4
    i64.store
    local.get 2
    local.get 1
    i64.load align=4
    i64.store offset=8
    local.get 2
    i32.const 4
    i32.add
    i32.const 1049000
    local.get 2
    i32.const 8
    i32.add
    call $_ZN4core3fmt5write17hde2e3bb6f5926acbE
    local.set 1
    local.get 2
    i32.const 32
    i32.add
    global.set 0
    local.get 1)
  (func $_ZN4core3fmt5write17hde2e3bb6f5926acbE (type 0) (param i32 i32 i32) (result i32)
    (local i32 i32 i32 i32 i32 i32 i32 i32 i32 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 3
    global.set 0
    local.get 3
    i32.const 36
    i32.add
    local.get 1
    i32.store
    local.get 3
    i32.const 3
    i32.store8 offset=40
    local.get 3
    i64.const 137438953472
    i64.store offset=8
    local.get 3
    local.get 0
    i32.store offset=32
    i32.const 0
    local.set 4
    local.get 3
    i32.const 0
    i32.store offset=24
    local.get 3
    i32.const 0
    i32.store offset=16
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            local.get 2
            i32.load offset=8
            local.tee 5
            i32.eqz
            br_if 0 (;@4;)
            local.get 2
            i32.load
            local.set 6
            local.get 2
            i32.load offset=4
            local.tee 7
            local.get 2
            i32.const 12
            i32.add
            i32.load
            local.tee 8
            local.get 8
            local.get 7
            i32.gt_u
            select
            local.tee 9
            i32.eqz
            br_if 1 (;@3;)
            local.get 2
            i32.const 20
            i32.add
            i32.load
            local.set 10
            local.get 2
            i32.load offset=16
            local.set 11
            i32.const 1
            local.set 8
            local.get 0
            local.get 6
            i32.load
            local.get 6
            i32.load offset=4
            local.get 1
            i32.load offset=12
            call_indirect (type 0)
            br_if 3 (;@1;)
            local.get 5
            i32.const 16
            i32.add
            local.set 2
            local.get 6
            i32.const 8
            i32.add
            local.set 0
            i32.const 1
            local.set 4
            block  ;; label = @5
              block  ;; label = @6
                loop  ;; label = @7
                  local.get 3
                  local.get 2
                  i32.const -12
                  i32.add
                  i32.load
                  i32.store offset=12
                  local.get 3
                  local.get 2
                  i32.const 12
                  i32.add
                  i32.load8_u
                  i32.store8 offset=40
                  local.get 3
                  local.get 2
                  i32.const -8
                  i32.add
                  i32.load
                  i32.store offset=8
                  local.get 2
                  i32.const 8
                  i32.add
                  i32.load
                  local.set 8
                  i32.const 0
                  local.set 5
                  i32.const 0
                  local.set 1
                  block  ;; label = @8
                    block  ;; label = @9
                      block  ;; label = @10
                        local.get 2
                        i32.const 4
                        i32.add
                        i32.load
                        br_table 1 (;@9;) 0 (;@10;) 2 (;@8;) 1 (;@9;)
                      end
                      local.get 8
                      local.get 10
                      i32.ge_u
                      br_if 3 (;@6;)
                      local.get 8
                      i32.const 3
                      i32.shl
                      local.set 12
                      i32.const 0
                      local.set 1
                      local.get 11
                      local.get 12
                      i32.add
                      local.tee 12
                      i32.load offset=4
                      i32.const 2
                      i32.ne
                      br_if 1 (;@8;)
                      local.get 12
                      i32.load
                      i32.load
                      local.set 8
                    end
                    i32.const 1
                    local.set 1
                  end
                  local.get 3
                  local.get 8
                  i32.store offset=20
                  local.get 3
                  local.get 1
                  i32.store offset=16
                  local.get 2
                  i32.load
                  local.set 8
                  block  ;; label = @8
                    block  ;; label = @9
                      block  ;; label = @10
                        local.get 2
                        i32.const -4
                        i32.add
                        i32.load
                        br_table 1 (;@9;) 0 (;@10;) 2 (;@8;) 1 (;@9;)
                      end
                      local.get 8
                      local.get 10
                      i32.ge_u
                      br_if 4 (;@5;)
                      local.get 8
                      i32.const 3
                      i32.shl
                      local.set 1
                      local.get 11
                      local.get 1
                      i32.add
                      local.tee 1
                      i32.load offset=4
                      i32.const 2
                      i32.ne
                      br_if 1 (;@8;)
                      local.get 1
                      i32.load
                      i32.load
                      local.set 8
                    end
                    i32.const 1
                    local.set 5
                  end
                  local.get 3
                  local.get 8
                  i32.store offset=28
                  local.get 3
                  local.get 5
                  i32.store offset=24
                  block  ;; label = @8
                    local.get 2
                    i32.const -16
                    i32.add
                    i32.load
                    local.tee 8
                    local.get 10
                    i32.ge_u
                    br_if 0 (;@8;)
                    local.get 11
                    local.get 8
                    i32.const 3
                    i32.shl
                    i32.add
                    local.tee 8
                    i32.load
                    local.get 3
                    i32.const 8
                    i32.add
                    local.get 8
                    i32.load offset=4
                    call_indirect (type 1)
                    br_if 6 (;@2;)
                    local.get 4
                    local.get 9
                    i32.ge_u
                    br_if 5 (;@3;)
                    local.get 0
                    i32.const 4
                    i32.add
                    local.set 1
                    local.get 0
                    i32.load
                    local.set 5
                    local.get 2
                    i32.const 32
                    i32.add
                    local.set 2
                    local.get 0
                    i32.const 8
                    i32.add
                    local.set 0
                    i32.const 1
                    local.set 8
                    local.get 4
                    i32.const 1
                    i32.add
                    local.set 4
                    local.get 3
                    i32.load offset=32
                    local.get 5
                    local.get 1
                    i32.load
                    local.get 3
                    i32.load offset=36
                    i32.load offset=12
                    call_indirect (type 0)
                    i32.eqz
                    br_if 1 (;@7;)
                    br 7 (;@1;)
                  end
                end
                local.get 8
                local.get 10
                i32.const 1049412
                call $_ZN4core9panicking18panic_bounds_check17ha5804550fa0d0ae9E
                unreachable
              end
              local.get 8
              local.get 10
              i32.const 1049396
              call $_ZN4core9panicking18panic_bounds_check17ha5804550fa0d0ae9E
              unreachable
            end
            local.get 8
            local.get 10
            i32.const 1049396
            call $_ZN4core9panicking18panic_bounds_check17ha5804550fa0d0ae9E
            unreachable
          end
          local.get 2
          i32.load
          local.set 6
          local.get 2
          i32.load offset=4
          local.tee 7
          local.get 2
          i32.const 20
          i32.add
          i32.load
          local.tee 8
          local.get 8
          local.get 7
          i32.gt_u
          select
          local.tee 10
          i32.eqz
          br_if 0 (;@3;)
          local.get 2
          i32.load offset=16
          local.set 2
          i32.const 1
          local.set 8
          local.get 0
          local.get 6
          i32.load
          local.get 6
          i32.load offset=4
          local.get 1
          i32.load offset=12
          call_indirect (type 0)
          br_if 2 (;@1;)
          local.get 6
          i32.const 8
          i32.add
          local.set 0
          i32.const 1
          local.set 4
          loop  ;; label = @4
            local.get 2
            i32.load
            local.get 3
            i32.const 8
            i32.add
            local.get 2
            i32.const 4
            i32.add
            i32.load
            call_indirect (type 1)
            br_if 2 (;@2;)
            local.get 4
            local.get 10
            i32.ge_u
            br_if 1 (;@3;)
            local.get 0
            i32.const 4
            i32.add
            local.set 1
            local.get 0
            i32.load
            local.set 5
            local.get 2
            i32.const 8
            i32.add
            local.set 2
            local.get 0
            i32.const 8
            i32.add
            local.set 0
            i32.const 1
            local.set 8
            local.get 4
            i32.const 1
            i32.add
            local.set 4
            local.get 3
            i32.load offset=32
            local.get 5
            local.get 1
            i32.load
            local.get 3
            i32.load offset=36
            i32.load offset=12
            call_indirect (type 0)
            i32.eqz
            br_if 0 (;@4;)
            br 3 (;@1;)
          end
        end
        block  ;; label = @3
          local.get 7
          local.get 4
          i32.le_u
          br_if 0 (;@3;)
          i32.const 1
          local.set 8
          local.get 3
          i32.load offset=32
          local.get 6
          local.get 4
          i32.const 3
          i32.shl
          i32.add
          local.tee 2
          i32.load
          local.get 2
          i32.load offset=4
          local.get 3
          i32.load offset=36
          i32.load offset=12
          call_indirect (type 0)
          br_if 2 (;@1;)
        end
        i32.const 0
        local.set 8
        br 1 (;@1;)
      end
      i32.const 1
      local.set 8
    end
    local.get 3
    i32.const 48
    i32.add
    global.set 0
    local.get 8)
  (func $_ZN4core3ops8function6FnOnce9call_once17h7513c2557cb8bf69E (type 1) (param i32 i32) (result i32)
    local.get 0
    i32.load
    drop
    loop (result i32)  ;; label = @1
      br 0 (;@1;)
    end)
  (func $_ZN4core9panicking9panic_fmt17h89af7b08942b8a76E (type 6) (param i32 i32)
    local.get 0
    call $rust_begin_unwind
    unreachable)
  (func $_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$u32$GT$3fmt17h4d5f6e7a5de9cb88E (type 1) (param i32 i32) (result i32)
    (local i32 i32 i64 i64 i32 i32)
    global.get 0
    i32.const 48
    i32.sub
    local.tee 2
    global.set 0
    i32.const 39
    local.set 3
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        i64.load32_u
        local.tee 4
        i64.const 10000
        i64.ge_u
        br_if 0 (;@2;)
        local.get 4
        local.set 5
        br 1 (;@1;)
      end
      i32.const 39
      local.set 3
      loop  ;; label = @2
        local.get 2
        i32.const 9
        i32.add
        local.get 3
        i32.add
        local.tee 0
        i32.const -4
        i32.add
        local.get 4
        local.get 4
        i64.const 10000
        i64.div_u
        local.tee 5
        i64.const -10000
        i64.mul
        i64.add
        i32.wrap_i64
        local.tee 6
        i32.const 65535
        i32.and
        i32.const 100
        i32.div_u
        local.tee 7
        i32.const 1
        i32.shl
        i32.const 1049194
        i32.add
        i32.load16_u align=1
        i32.store16 align=1
        local.get 0
        i32.const -2
        i32.add
        local.get 7
        i32.const -100
        i32.mul
        local.get 6
        i32.add
        i32.const 65535
        i32.and
        i32.const 1
        i32.shl
        i32.const 1049194
        i32.add
        i32.load16_u align=1
        i32.store16 align=1
        local.get 3
        i32.const -4
        i32.add
        local.set 3
        local.get 4
        i64.const 99999999
        i64.gt_u
        local.set 0
        local.get 5
        local.set 4
        local.get 0
        br_if 0 (;@2;)
      end
    end
    block  ;; label = @1
      local.get 5
      i32.wrap_i64
      local.tee 0
      i32.const 99
      i32.le_s
      br_if 0 (;@1;)
      local.get 2
      i32.const 9
      i32.add
      local.get 3
      i32.const -2
      i32.add
      local.tee 3
      i32.add
      local.get 5
      i32.wrap_i64
      local.tee 6
      i32.const 65535
      i32.and
      i32.const 100
      i32.div_u
      local.tee 0
      i32.const -100
      i32.mul
      local.get 6
      i32.add
      i32.const 65535
      i32.and
      i32.const 1
      i32.shl
      i32.const 1049194
      i32.add
      i32.load16_u align=1
      i32.store16 align=1
    end
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        i32.const 10
        i32.lt_s
        br_if 0 (;@2;)
        local.get 2
        i32.const 9
        i32.add
        local.get 3
        i32.const -2
        i32.add
        local.tee 3
        i32.add
        local.get 0
        i32.const 1
        i32.shl
        i32.const 1049194
        i32.add
        i32.load16_u align=1
        i32.store16 align=1
        br 1 (;@1;)
      end
      local.get 2
      i32.const 9
      i32.add
      local.get 3
      i32.const -1
      i32.add
      local.tee 3
      i32.add
      local.get 0
      i32.const 48
      i32.add
      i32.store8
    end
    local.get 1
    i32.const 1049476
    i32.const 0
    local.get 2
    i32.const 9
    i32.add
    local.get 3
    i32.add
    i32.const 39
    local.get 3
    i32.sub
    call $_ZN4core3fmt9Formatter12pad_integral17h2535d054ed500d5fE
    local.set 3
    local.get 2
    i32.const 48
    i32.add
    global.set 0
    local.get 3)
  (func $_ZN4core3fmt9Formatter12pad_integral17h2535d054ed500d5fE (type 13) (param i32 i32 i32 i32 i32) (result i32)
    (local i32 i32 i32 i32 i32 i32)
    local.get 0
    i32.load
    local.tee 5
    i32.const 1
    i32.and
    local.tee 6
    local.get 4
    i32.add
    local.set 7
    block  ;; label = @1
      block  ;; label = @2
        local.get 5
        i32.const 4
        i32.and
        br_if 0 (;@2;)
        i32.const 0
        local.set 1
        br 1 (;@1;)
      end
      i32.const 0
      local.set 8
      block  ;; label = @2
        local.get 2
        i32.eqz
        br_if 0 (;@2;)
        local.get 2
        local.set 9
        local.get 1
        local.set 10
        loop  ;; label = @3
          local.get 8
          local.get 10
          i32.load8_u
          i32.const 192
          i32.and
          i32.const 128
          i32.eq
          i32.add
          local.set 8
          local.get 10
          i32.const 1
          i32.add
          local.set 10
          local.get 9
          i32.const -1
          i32.add
          local.tee 9
          br_if 0 (;@3;)
        end
      end
      local.get 7
      local.get 2
      i32.add
      local.get 8
      i32.sub
      local.set 7
    end
    i32.const 43
    i32.const 1114112
    local.get 6
    select
    local.set 8
    block  ;; label = @1
      block  ;; label = @2
        local.get 0
        i32.load offset=8
        i32.const 1
        i32.eq
        br_if 0 (;@2;)
        i32.const 1
        local.set 10
        local.get 0
        local.get 8
        local.get 1
        local.get 2
        call $_ZN4core3fmt9Formatter12pad_integral12write_prefix17he932e11380be0113E
        br_if 1 (;@1;)
        local.get 0
        i32.load offset=24
        local.get 3
        local.get 4
        local.get 0
        i32.const 28
        i32.add
        i32.load
        i32.load offset=12
        call_indirect (type 0)
        local.set 10
        br 1 (;@1;)
      end
      block  ;; label = @2
        local.get 0
        i32.const 12
        i32.add
        i32.load
        local.tee 9
        local.get 7
        i32.gt_u
        br_if 0 (;@2;)
        i32.const 1
        local.set 10
        local.get 0
        local.get 8
        local.get 1
        local.get 2
        call $_ZN4core3fmt9Formatter12pad_integral12write_prefix17he932e11380be0113E
        br_if 1 (;@1;)
        local.get 0
        i32.load offset=24
        local.get 3
        local.get 4
        local.get 0
        i32.const 28
        i32.add
        i32.load
        i32.load offset=12
        call_indirect (type 0)
        return
      end
      block  ;; label = @2
        block  ;; label = @3
          local.get 5
          i32.const 8
          i32.and
          br_if 0 (;@3;)
          i32.const 0
          local.set 10
          local.get 9
          local.get 7
          i32.sub
          local.tee 9
          local.set 5
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                i32.const 1
                local.get 0
                i32.load8_u offset=32
                local.tee 7
                local.get 7
                i32.const 3
                i32.eq
                select
                br_table 2 (;@4;) 1 (;@5;) 0 (;@6;) 1 (;@5;) 2 (;@4;)
              end
              local.get 9
              i32.const 1
              i32.shr_u
              local.set 10
              local.get 9
              i32.const 1
              i32.add
              i32.const 1
              i32.shr_u
              local.set 5
              br 1 (;@4;)
            end
            i32.const 0
            local.set 5
            local.get 9
            local.set 10
          end
          local.get 10
          i32.const 1
          i32.add
          local.set 10
          loop  ;; label = @4
            local.get 10
            i32.const -1
            i32.add
            local.tee 10
            i32.eqz
            br_if 2 (;@2;)
            local.get 0
            i32.load offset=24
            local.get 0
            i32.load offset=4
            local.get 0
            i32.load offset=28
            i32.load offset=16
            call_indirect (type 1)
            i32.eqz
            br_if 0 (;@4;)
          end
          i32.const 1
          return
        end
        local.get 0
        i32.load offset=4
        local.set 5
        local.get 0
        i32.const 48
        i32.store offset=4
        local.get 0
        i32.load8_u offset=32
        local.set 6
        i32.const 1
        local.set 10
        local.get 0
        i32.const 1
        i32.store8 offset=32
        local.get 0
        local.get 8
        local.get 1
        local.get 2
        call $_ZN4core3fmt9Formatter12pad_integral12write_prefix17he932e11380be0113E
        br_if 1 (;@1;)
        i32.const 0
        local.set 10
        local.get 9
        local.get 7
        i32.sub
        local.tee 9
        local.set 2
        block  ;; label = @3
          block  ;; label = @4
            block  ;; label = @5
              i32.const 1
              local.get 0
              i32.load8_u offset=32
              local.tee 8
              local.get 8
              i32.const 3
              i32.eq
              select
              br_table 2 (;@3;) 1 (;@4;) 0 (;@5;) 1 (;@4;) 2 (;@3;)
            end
            local.get 9
            i32.const 1
            i32.shr_u
            local.set 10
            local.get 9
            i32.const 1
            i32.add
            i32.const 1
            i32.shr_u
            local.set 2
            br 1 (;@3;)
          end
          i32.const 0
          local.set 2
          local.get 9
          local.set 10
        end
        local.get 10
        i32.const 1
        i32.add
        local.set 10
        block  ;; label = @3
          loop  ;; label = @4
            local.get 10
            i32.const -1
            i32.add
            local.tee 10
            i32.eqz
            br_if 1 (;@3;)
            local.get 0
            i32.load offset=24
            local.get 0
            i32.load offset=4
            local.get 0
            i32.load offset=28
            i32.load offset=16
            call_indirect (type 1)
            i32.eqz
            br_if 0 (;@4;)
          end
          i32.const 1
          return
        end
        local.get 0
        i32.load offset=4
        local.set 9
        i32.const 1
        local.set 10
        local.get 0
        i32.load offset=24
        local.get 3
        local.get 4
        local.get 0
        i32.load offset=28
        i32.load offset=12
        call_indirect (type 0)
        br_if 1 (;@1;)
        local.get 2
        i32.const 1
        i32.add
        local.set 8
        local.get 0
        i32.load offset=28
        local.set 2
        local.get 0
        i32.load offset=24
        local.set 1
        block  ;; label = @3
          loop  ;; label = @4
            local.get 8
            i32.const -1
            i32.add
            local.tee 8
            i32.eqz
            br_if 1 (;@3;)
            i32.const 1
            local.set 10
            local.get 1
            local.get 9
            local.get 2
            i32.load offset=16
            call_indirect (type 1)
            br_if 3 (;@1;)
            br 0 (;@4;)
          end
        end
        local.get 0
        local.get 6
        i32.store8 offset=32
        local.get 0
        local.get 5
        i32.store offset=4
        i32.const 0
        return
      end
      local.get 0
      i32.load offset=4
      local.set 9
      i32.const 1
      local.set 10
      local.get 0
      local.get 8
      local.get 1
      local.get 2
      call $_ZN4core3fmt9Formatter12pad_integral12write_prefix17he932e11380be0113E
      br_if 0 (;@1;)
      local.get 0
      i32.load offset=24
      local.get 3
      local.get 4
      local.get 0
      i32.load offset=28
      i32.load offset=12
      call_indirect (type 0)
      br_if 0 (;@1;)
      local.get 5
      i32.const 1
      i32.add
      local.set 8
      local.get 0
      i32.load offset=28
      local.set 2
      local.get 0
      i32.load offset=24
      local.set 0
      loop  ;; label = @2
        block  ;; label = @3
          local.get 8
          i32.const -1
          i32.add
          local.tee 8
          br_if 0 (;@3;)
          i32.const 0
          return
        end
        i32.const 1
        local.set 10
        local.get 0
        local.get 9
        local.get 2
        i32.load offset=16
        call_indirect (type 1)
        i32.eqz
        br_if 0 (;@2;)
      end
    end
    local.get 10)
  (func $rust_begin_unwind (type 10) (param i32)
    (local i32 i32)
    global.get 0
    i32.const 64
    i32.sub
    local.tee 1
    global.set 0
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          block  ;; label = @4
            local.get 0
            br_if 0 (;@4;)
            local.get 1
            i32.const 40
            i32.add
            i32.const 22
            call $_ZN5alloc3vec12Vec$LT$T$GT$13with_capacity17ha05bb556483e33d0E
            local.get 1
            i32.const 40
            i32.add
            i32.const 1049909
            i32.const 22
            call $_ZN5alloc3vec12Vec$LT$T$GT$17extend_from_slice17hf4a914f0ba6e5b3eE
            local.get 1
            i32.load offset=48
            local.set 0
            local.get 1
            i32.load offset=40
            local.set 2
            br 1 (;@3;)
          end
          local.get 1
          local.get 0
          i32.store offset=12
          local.get 1
          i32.const 3
          i32.store offset=20
          local.get 1
          local.get 1
          i32.const 12
          i32.add
          i32.store offset=16
          i32.const 32
          i32.const 1
          call $__rust_alloc
          local.tee 0
          i32.eqz
          br_if 1 (;@2;)
          local.get 1
          i64.const 32
          i64.store offset=28 align=4
          local.get 1
          local.get 0
          i32.store offset=24
          local.get 1
          local.get 1
          i32.const 24
          i32.add
          i32.store offset=36
          local.get 1
          i32.const 60
          i32.add
          i32.const 1
          i32.store
          local.get 1
          i64.const 1
          i64.store offset=44 align=4
          local.get 1
          i32.const 1049932
          i32.store offset=40
          local.get 1
          local.get 1
          i32.const 16
          i32.add
          i32.store offset=56
          local.get 1
          i32.const 36
          i32.add
          i32.const 1049000
          local.get 1
          i32.const 40
          i32.add
          call $_ZN4core3fmt5write17hde2e3bb6f5926acbE
          br_if 2 (;@1;)
          local.get 1
          i32.load offset=24
          local.set 2
          local.get 1
          i32.load offset=32
          local.set 0
        end
        local.get 2
        local.get 0
        call $_ZN16elrond_wasm_node9ext_error12signal_error17h3e53d6674adb9999E.120
        unreachable
      end
      call $_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$11allocate_in28_$u7b$$u7b$closure$u7d$$u7d$17hc32f2ac315b545e4E
      unreachable
    end
    i32.const 1049024
    i32.const 51
    local.get 1
    i32.const 40
    i32.add
    i32.const 1049076
    i32.const 1049092
    call $_ZN4core6option18expect_none_failed17h4c5f11b8bced9934E
    unreachable)
  (func $_ZN4core3fmt9Formatter12pad_integral12write_prefix17he932e11380be0113E (type 5) (param i32 i32 i32 i32) (result i32)
    (local i32)
    block  ;; label = @1
      block  ;; label = @2
        local.get 1
        i32.const 1114112
        i32.eq
        br_if 0 (;@2;)
        i32.const 1
        local.set 4
        local.get 0
        i32.load offset=24
        local.get 1
        local.get 0
        i32.const 28
        i32.add
        i32.load
        i32.load offset=16
        call_indirect (type 1)
        br_if 1 (;@1;)
      end
      block  ;; label = @2
        local.get 2
        br_if 0 (;@2;)
        i32.const 0
        return
      end
      local.get 0
      i32.load offset=24
      local.get 2
      local.get 3
      local.get 0
      i32.const 28
      i32.add
      i32.load
      i32.load offset=12
      call_indirect (type 0)
      local.set 4
    end
    local.get 4)
  (func $_ZN44_$LT$$RF$T$u20$as$u20$core..fmt..Display$GT$3fmt17hdefa33539845c2d1E (type 1) (param i32 i32) (result i32)
    (local i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32 i32)
    local.get 1
    i32.const 16
    i32.add
    i32.load
    local.set 2
    local.get 0
    i32.load offset=4
    local.set 3
    local.get 0
    i32.load
    local.set 4
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          local.get 1
          i32.const 8
          i32.add
          i32.load
          local.tee 5
          i32.const 1
          i32.eq
          br_if 0 (;@3;)
          local.get 2
          i32.const 1
          i32.eq
          br_if 1 (;@2;)
          local.get 1
          i32.load offset=24
          local.get 4
          local.get 3
          local.get 1
          i32.const 28
          i32.add
          i32.load
          i32.load offset=12
          call_indirect (type 0)
          return
        end
        local.get 2
        i32.const 1
        i32.ne
        br_if 1 (;@1;)
      end
      block  ;; label = @2
        block  ;; label = @3
          local.get 3
          br_if 0 (;@3;)
          i32.const 0
          local.set 3
          br 1 (;@2;)
        end
        local.get 4
        local.get 3
        i32.add
        local.set 6
        local.get 1
        i32.const 20
        i32.add
        i32.load
        i32.const 1
        i32.add
        local.set 7
        i32.const 0
        local.set 8
        local.get 4
        local.set 0
        local.get 4
        local.set 9
        loop  ;; label = @3
          local.get 0
          i32.const 1
          i32.add
          local.set 2
          block  ;; label = @4
            block  ;; label = @5
              block  ;; label = @6
                local.get 0
                i32.load8_s
                local.tee 10
                i32.const -1
                i32.gt_s
                br_if 0 (;@6;)
                block  ;; label = @7
                  block  ;; label = @8
                    local.get 2
                    local.get 6
                    i32.ne
                    br_if 0 (;@8;)
                    i32.const 0
                    local.set 11
                    local.get 6
                    local.set 0
                    br 1 (;@7;)
                  end
                  local.get 0
                  i32.load8_u offset=1
                  i32.const 63
                  i32.and
                  local.set 11
                  local.get 0
                  i32.const 2
                  i32.add
                  local.tee 2
                  local.set 0
                end
                local.get 10
                i32.const 31
                i32.and
                local.set 12
                block  ;; label = @7
                  local.get 10
                  i32.const 255
                  i32.and
                  local.tee 10
                  i32.const 223
                  i32.gt_u
                  br_if 0 (;@7;)
                  local.get 11
                  local.get 12
                  i32.const 6
                  i32.shl
                  i32.or
                  local.set 10
                  br 2 (;@5;)
                end
                block  ;; label = @7
                  block  ;; label = @8
                    local.get 0
                    local.get 6
                    i32.ne
                    br_if 0 (;@8;)
                    i32.const 0
                    local.set 13
                    local.get 6
                    local.set 14
                    br 1 (;@7;)
                  end
                  local.get 0
                  i32.load8_u
                  i32.const 63
                  i32.and
                  local.set 13
                  local.get 0
                  i32.const 1
                  i32.add
                  local.tee 2
                  local.set 14
                end
                local.get 13
                local.get 11
                i32.const 6
                i32.shl
                i32.or
                local.set 11
                block  ;; label = @7
                  local.get 10
                  i32.const 240
                  i32.ge_u
                  br_if 0 (;@7;)
                  local.get 11
                  local.get 12
                  i32.const 12
                  i32.shl
                  i32.or
                  local.set 10
                  br 2 (;@5;)
                end
                block  ;; label = @7
                  block  ;; label = @8
                    local.get 14
                    local.get 6
                    i32.ne
                    br_if 0 (;@8;)
                    i32.const 0
                    local.set 10
                    local.get 2
                    local.set 0
                    br 1 (;@7;)
                  end
                  local.get 14
                  i32.const 1
                  i32.add
                  local.set 0
                  local.get 14
                  i32.load8_u
                  i32.const 63
                  i32.and
                  local.set 10
                end
                local.get 11
                i32.const 6
                i32.shl
                local.get 12
                i32.const 18
                i32.shl
                i32.const 1835008
                i32.and
                i32.or
                local.get 10
                i32.or
                local.tee 10
                i32.const 1114112
                i32.ne
                br_if 2 (;@4;)
                br 4 (;@2;)
              end
              local.get 10
              i32.const 255
              i32.and
              local.set 10
            end
            local.get 2
            local.set 0
          end
          block  ;; label = @4
            local.get 7
            i32.const -1
            i32.add
            local.tee 7
            i32.eqz
            br_if 0 (;@4;)
            local.get 8
            local.get 9
            i32.sub
            local.get 0
            i32.add
            local.set 8
            local.get 0
            local.set 9
            local.get 6
            local.get 0
            i32.ne
            br_if 1 (;@3;)
            br 2 (;@2;)
          end
        end
        local.get 10
        i32.const 1114112
        i32.eq
        br_if 0 (;@2;)
        block  ;; label = @3
          block  ;; label = @4
            local.get 8
            i32.eqz
            br_if 0 (;@4;)
            local.get 8
            local.get 3
            i32.eq
            br_if 0 (;@4;)
            i32.const 0
            local.set 0
            local.get 8
            local.get 3
            i32.ge_u
            br_if 1 (;@3;)
            local.get 4
            local.get 8
            i32.add
            i32.load8_s
            i32.const -64
            i32.lt_s
            br_if 1 (;@3;)
          end
          local.get 4
          local.set 0
        end
        local.get 8
        local.get 3
        local.get 0
        select
        local.set 3
        local.get 0
        local.get 4
        local.get 0
        select
        local.set 4
      end
      local.get 5
      i32.const 1
      i32.eq
      br_if 0 (;@1;)
      local.get 1
      i32.load offset=24
      local.get 4
      local.get 3
      local.get 1
      i32.const 28
      i32.add
      i32.load
      i32.load offset=12
      call_indirect (type 0)
      return
    end
    i32.const 0
    local.set 2
    block  ;; label = @1
      local.get 3
      i32.eqz
      br_if 0 (;@1;)
      local.get 3
      local.set 10
      local.get 4
      local.set 0
      loop  ;; label = @2
        local.get 2
        local.get 0
        i32.load8_u
        i32.const 192
        i32.and
        i32.const 128
        i32.eq
        i32.add
        local.set 2
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        local.get 10
        i32.const -1
        i32.add
        local.tee 10
        br_if 0 (;@2;)
      end
    end
    block  ;; label = @1
      local.get 3
      local.get 2
      i32.sub
      local.get 1
      i32.load offset=12
      local.tee 7
      i32.lt_u
      br_if 0 (;@1;)
      local.get 1
      i32.load offset=24
      local.get 4
      local.get 3
      local.get 1
      i32.const 28
      i32.add
      i32.load
      i32.load offset=12
      call_indirect (type 0)
      return
    end
    i32.const 0
    local.set 8
    i32.const 0
    local.set 2
    block  ;; label = @1
      local.get 3
      i32.eqz
      br_if 0 (;@1;)
      i32.const 0
      local.set 2
      local.get 3
      local.set 10
      local.get 4
      local.set 0
      loop  ;; label = @2
        local.get 2
        local.get 0
        i32.load8_u
        i32.const 192
        i32.and
        i32.const 128
        i32.eq
        i32.add
        local.set 2
        local.get 0
        i32.const 1
        i32.add
        local.set 0
        local.get 10
        i32.const -1
        i32.add
        local.tee 10
        br_if 0 (;@2;)
      end
    end
    local.get 2
    local.get 3
    i32.sub
    local.get 7
    i32.add
    local.tee 2
    local.set 10
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          i32.const 0
          local.get 1
          i32.load8_u offset=32
          local.tee 0
          local.get 0
          i32.const 3
          i32.eq
          select
          br_table 2 (;@1;) 1 (;@2;) 0 (;@3;) 1 (;@2;) 2 (;@1;)
        end
        local.get 2
        i32.const 1
        i32.shr_u
        local.set 8
        local.get 2
        i32.const 1
        i32.add
        i32.const 1
        i32.shr_u
        local.set 10
        br 1 (;@1;)
      end
      i32.const 0
      local.set 10
      local.get 2
      local.set 8
    end
    local.get 8
    i32.const 1
    i32.add
    local.set 0
    block  ;; label = @1
      block  ;; label = @2
        block  ;; label = @3
          loop  ;; label = @4
            local.get 0
            i32.const -1
            i32.add
            local.tee 0
            i32.eqz
            br_if 1 (;@3;)
            local.get 1
            i32.load offset=24
            local.get 1
            i32.load offset=4
            local.get 1
            i32.load offset=28
            i32.load offset=16
            call_indirect (type 1)
            i32.eqz
            br_if 0 (;@4;)
            br 2 (;@2;)
          end
        end
        local.get 1
        i32.load offset=4
        local.set 2
        i32.const 1
        local.set 0
        local.get 1
        i32.load offset=24
        local.get 4
        local.get 3
        local.get 1
        i32.load offset=28
        i32.load offset=12
        call_indirect (type 0)
        br_if 1 (;@1;)
        local.get 10
        i32.const 1
        i32.add
        local.set 0
        local.get 1
        i32.load offset=28
        local.set 10
        local.get 1
        i32.load offset=24
        local.set 1
        loop  ;; label = @3
          block  ;; label = @4
            local.get 0
            i32.const -1
            i32.add
            local.tee 0
            br_if 0 (;@4;)
            i32.const 0
            return
          end
          local.get 1
          local.get 2
          local.get 10
          i32.load offset=16
          call_indirect (type 1)
          i32.eqz
          br_if 0 (;@3;)
        end
      end
      i32.const 1
      local.set 0
    end
    local.get 0)
  (func $_ZN4core6option18expect_none_failed17h4c5f11b8bced9934E (type 14) (param i32 i32 i32 i32 i32)
    (local i32)
    global.get 0
    i32.const 64
    i32.sub
    local.tee 5
    global.set 0
    local.get 5
    local.get 1
    i32.store offset=12
    local.get 5
    local.get 0
    i32.store offset=8
    local.get 5
    local.get 3
    i32.store offset=20
    local.get 5
    local.get 2
    i32.store offset=16
    local.get 5
    i32.const 44
    i32.add
    i32.const 2
    i32.store
    local.get 5
    i32.const 60
    i32.add
    i32.const 4
    i32.store
    local.get 5
    i64.const 2
    i64.store offset=28 align=4
    local.get 5
    i32.const 1049452
    i32.store offset=24
    local.get 5
    i32.const 5
    i32.store offset=52
    local.get 5
    local.get 5
    i32.const 48
    i32.add
    i32.store offset=40
    local.get 5
    local.get 5
    i32.const 16
    i32.add
    i32.store offset=56
    local.get 5
    local.get 5
    i32.const 8
    i32.add
    i32.store offset=48
    local.get 5
    i32.const 24
    i32.add
    local.get 4
    call $_ZN4core9panicking9panic_fmt17h89af7b08942b8a76E
    unreachable)
  (func $_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17h1316c3c5708d25dcE (type 1) (param i32 i32) (result i32)
    local.get 0
    i32.load
    local.get 1
    local.get 0
    i32.load offset=4
    i32.load offset=12
    call_indirect (type 1))
  (func $_ZN53_$LT$core..fmt..Error$u20$as$u20$core..fmt..Debug$GT$3fmt17h4c91dac37b7a3712E (type 1) (param i32 i32) (result i32)
    local.get 1
    i32.load offset=24
    i32.const 1049470
    i32.const 5
    local.get 1
    i32.const 28
    i32.add
    i32.load
    i32.load offset=12
    call_indirect (type 0))
  (func $_ZN62_$LT$alloc..alloc..Global$u20$as$u20$core..alloc..AllocRef$GT$5alloc17h91e855b0ff6b448aE.85 (type 11) (param i32 i32 i32)
    block  ;; label = @1
      block  ;; label = @2
        local.get 1
        br_if 0 (;@2;)
        i32.const 1
        local.set 2
        br 1 (;@1;)
      end
      block  ;; label = @2
        local.get 2
        i32.eqz
        br_if 0 (;@2;)
        local.get 1
        call $__rust_alloc_zeroed
        local.set 2
        br 1 (;@1;)
      end
      local.get 1
      i32.const 1
      call $__rust_alloc
      local.set 2
    end
    local.get 0
    local.get 1
    i32.store offset=4
    local.get 0
    local.get 2
    i32.store)
  (func $_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$11allocate_in28_$u7b$$u7b$closure$u7d$$u7d$17hfe2a34813757d41fE (type 12)
    call $_ZN5alloc7raw_vec17capacity_overflow17h52126f2f7e3db953E
    unreachable)
  (func $_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17heb3f43a8856346abE (type 1) (param i32 i32) (result i32)
    (local i32 i32 i32)
    global.get 0
    i32.const 32
    i32.sub
    local.tee 2
    global.set 0
    local.get 1
    i32.const 28
    i32.add
    i32.load
    local.set 3
    local.get 1
    i32.load offset=24
    local.set 4
    local.get 2
    i32.const 8
    i32.add
    i32.const 16
    i32.add
    local.get 0
    i32.load
    local.tee 1
    i32.const 16
    i32.add
    i64.load align=4
    i64.store
    local.get 2
    i32.const 8
    i32.add
    i32.const 8
    i32.add
    local.get 1
    i32.const 8
    i32.add
    i64.load align=4
    i64.store
    local.get 2
    local.get 1
    i64.load align=4
    i64.store offset=8
    local.get 4
    local.get 3
    local.get 2
    i32.const 8
    i32.add
    call $_ZN4core3fmt5write17hde2e3bb6f5926acbE
    local.set 1
    local.get 2
    i32.const 32
    i32.add
    global.set 0
    local.get 1)
  (func $_ZN5alloc3vec12Vec$LT$T$GT$13with_capacity17ha05bb556483e33d0E (type 6) (param i32 i32)
    (local i32 i64)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    local.get 2
    i32.const 8
    i32.add
    local.get 1
    i32.const 0
    call $_ZN5alloc7raw_vec19RawVec$LT$T$C$A$GT$11allocate_in17h1842a5e89cc73292E
    local.get 2
    i64.load offset=8
    local.set 3
    local.get 0
    i32.const 0
    i32.store offset=8
    local.get 0
    local.get 3
    i64.store align=4
    local.get 2
    i32.const 16
    i32.add
    global.set 0)
  (func $_ZN16elrond_wasm_node9ext_error12signal_error17h3e53d6674adb9999E.120 (type 6) (param i32 i32)
    local.get 0
    local.get 1
    call $signalError
    unreachable)
  (func $_ZN171_$LT$elrond_wasm_node..ext..ArwenApiImpl$u20$as$u20$elrond_wasm..ContractIOApi$LT$elrond_wasm_node..big_int..ArwenBigInt$C$elrond_wasm_node..big_uint..ArwenBigUint$GT$$GT$12signal_error17h976338bc113e8d25E.125 (type 12)
    i32.const 1049839
    i32.const 54
    call $_ZN16elrond_wasm_node9ext_error12signal_error17h3e53d6674adb9999E.120
    unreachable)
  (func $_ZN72_$LT$wee_alloc..WeeAlloc$u20$as$u20$core..alloc..global..GlobalAlloc$GT$5alloc17h9505c3565944e308E (type 1) (param i32 i32) (result i32)
    (local i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
    local.get 1
    i32.const 1
    local.get 1
    select
    local.set 1
    block  ;; label = @1
      local.get 0
      i32.eqz
      br_if 0 (;@1;)
      local.get 0
      i32.const 3
      i32.add
      i32.const 2
      i32.shr_u
      local.set 0
      block  ;; label = @2
        local.get 1
        i32.const 4
        i32.gt_u
        br_if 0 (;@2;)
        local.get 0
        i32.const -1
        i32.add
        local.tee 3
        i32.const 255
        i32.gt_u
        br_if 0 (;@2;)
        local.get 2
        i32.const 1050004
        i32.store offset=4
        local.get 2
        local.get 3
        i32.const 2
        i32.shl
        i32.const 1050008
        i32.add
        local.tee 3
        i32.load
        i32.store offset=12
        local.get 0
        local.get 1
        local.get 2
        i32.const 12
        i32.add
        local.get 2
        i32.const 4
        i32.add
        i32.const 1049980
        call $_ZN9wee_alloc17alloc_with_refill17h0c90bb2c6d0e3667E
        local.set 1
        local.get 3
        local.get 2
        i32.load offset=12
        i32.store
        br 1 (;@1;)
      end
      local.get 2
      i32.const 0
      i32.load offset=1050004
      i32.store offset=8
      local.get 0
      local.get 1
      local.get 2
      i32.const 8
      i32.add
      i32.const 1049476
      i32.const 1049956
      call $_ZN9wee_alloc17alloc_with_refill17h0c90bb2c6d0e3667E
      local.set 1
      i32.const 0
      local.get 2
      i32.load offset=8
      i32.store offset=1050004
    end
    local.get 2
    i32.const 16
    i32.add
    global.set 0
    local.get 1)
  (func $_ZN72_$LT$wee_alloc..WeeAlloc$u20$as$u20$core..alloc..global..GlobalAlloc$GT$7dealloc17h840365e51912c7bcE (type 11) (param i32 i32 i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 3
    global.set 0
    block  ;; label = @1
      local.get 0
      i32.eqz
      br_if 0 (;@1;)
      local.get 3
      local.get 0
      i32.store offset=4
      local.get 1
      i32.eqz
      br_if 0 (;@1;)
      block  ;; label = @2
        local.get 2
        i32.const 4
        i32.gt_u
        br_if 0 (;@2;)
        local.get 1
        i32.const 3
        i32.add
        i32.const 2
        i32.shr_u
        i32.const -1
        i32.add
        local.tee 0
        i32.const 255
        i32.gt_u
        br_if 0 (;@2;)
        local.get 3
        i32.const 1050004
        i32.store offset=8
        local.get 3
        local.get 0
        i32.const 2
        i32.shl
        i32.const 1050008
        i32.add
        local.tee 0
        i32.load
        i32.store offset=12
        local.get 3
        i32.const 4
        i32.add
        local.get 3
        i32.const 12
        i32.add
        local.get 3
        i32.const 8
        i32.add
        i32.const 1049980
        call $_ZN9wee_alloc8WeeAlloc12dealloc_impl28_$u7b$$u7b$closure$u7d$$u7d$17h0bcfd582ebbac4eeE
        local.get 0
        local.get 3
        i32.load offset=12
        i32.store
        br 1 (;@1;)
      end
      local.get 3
      i32.const 0
      i32.load offset=1050004
      i32.store offset=12
      local.get 3
      i32.const 4
      i32.add
      local.get 3
      i32.const 12
      i32.add
      i32.const 1049476
      i32.const 1049956
      call $_ZN9wee_alloc8WeeAlloc12dealloc_impl28_$u7b$$u7b$closure$u7d$$u7d$17h0bcfd582ebbac4eeE
      i32.const 0
      local.get 3
      i32.load offset=12
      i32.store offset=1050004
    end
    local.get 3
    i32.const 16
    i32.add
    global.set 0)
  (func $_ZN88_$LT$wee_alloc..size_classes..SizeClassAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$22new_cell_for_free_list17hb8cba68b14d3cac1E (type 2) (param i32 i32 i32 i32)
    (local i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 4
    global.set 0
    local.get 4
    local.get 1
    i32.load
    local.tee 1
    i32.load
    i32.store offset=12
    local.get 2
    i32.const 2
    i32.add
    local.tee 2
    local.get 2
    i32.mul
    local.tee 2
    i32.const 2048
    local.get 2
    i32.const 2048
    i32.gt_u
    select
    local.tee 5
    i32.const 4
    local.get 4
    i32.const 12
    i32.add
    i32.const 1049476
    i32.const 1049956
    call $_ZN9wee_alloc17alloc_with_refill17h0c90bb2c6d0e3667E
    local.set 2
    local.get 1
    local.get 4
    i32.load offset=12
    i32.store
    block  ;; label = @1
      block  ;; label = @2
        local.get 2
        br_if 0 (;@2;)
        i32.const 1
        local.set 1
        br 1 (;@1;)
      end
      local.get 2
      i64.const 0
      i64.store offset=4 align=4
      local.get 2
      local.get 2
      local.get 5
      i32.const 2
      i32.shl
      i32.add
      i32.const 2
      i32.or
      i32.store
      i32.const 0
      local.set 1
    end
    local.get 0
    local.get 2
    i32.store offset=4
    local.get 0
    local.get 1
    i32.store
    local.get 4
    i32.const 16
    i32.add
    global.set 0)
  (func $_ZN9wee_alloc17alloc_with_refill17h0c90bb2c6d0e3667E (type 13) (param i32 i32 i32 i32 i32) (result i32)
    (local i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 5
    global.set 0
    block  ;; label = @1
      local.get 0
      local.get 1
      local.get 2
      local.get 3
      local.get 4
      call $_ZN9wee_alloc15alloc_first_fit17h13f62ede0f0ca96bE
      local.tee 6
      br_if 0 (;@1;)
      local.get 5
      i32.const 8
      i32.add
      local.get 3
      local.get 0
      local.get 1
      local.get 4
      i32.load offset=12
      call_indirect (type 2)
      i32.const 0
      local.set 6
      local.get 5
      i32.load offset=8
      br_if 0 (;@1;)
      local.get 5
      i32.load offset=12
      local.tee 6
      local.get 2
      i32.load
      i32.store offset=8
      local.get 2
      local.get 6
      i32.store
      local.get 0
      local.get 1
      local.get 2
      local.get 3
      local.get 4
      call $_ZN9wee_alloc15alloc_first_fit17h13f62ede0f0ca96bE
      local.set 6
    end
    local.get 5
    i32.const 16
    i32.add
    global.set 0
    local.get 6)
  (func $_ZN9wee_alloc15alloc_first_fit17h13f62ede0f0ca96bE (type 13) (param i32 i32 i32 i32 i32) (result i32)
    (local i32 i32 i32 i32 i32 i32 i32)
    local.get 1
    i32.const -1
    i32.add
    local.set 5
    i32.const 0
    local.set 6
    i32.const 0
    local.get 1
    i32.sub
    local.set 7
    local.get 0
    i32.const 2
    i32.shl
    local.set 8
    local.get 2
    i32.load
    local.set 9
    block  ;; label = @1
      loop  ;; label = @2
        local.get 9
        i32.eqz
        br_if 1 (;@1;)
        local.get 9
        local.set 1
        block  ;; label = @3
          loop  ;; label = @4
            block  ;; label = @5
              local.get 1
              i32.load offset=8
              local.tee 9
              i32.const 1
              i32.and
              br_if 0 (;@5;)
              local.get 1
              i32.load
              i32.const -4
              i32.and
              local.tee 10
              local.get 1
              i32.const 8
              i32.add
              local.tee 11
              i32.sub
              local.get 8
              i32.lt_u
              br_if 2 (;@3;)
              block  ;; label = @6
                block  ;; label = @7
                  local.get 11
                  local.get 3
                  local.get 0
                  local.get 4
                  i32.load offset=16
                  call_indirect (type 1)
                  i32.const 2
                  i32.shl
                  i32.add
                  i32.const 8
                  i32.add
                  local.get 10
                  local.get 8
                  i32.sub
                  local.get 7
                  i32.and
                  local.tee 9
                  i32.le_u
                  br_if 0 (;@7;)
                  local.get 11
                  i32.load
                  local.set 9
                  local.get 5
                  local.get 11
                  i32.and
                  br_if 4 (;@3;)
                  local.get 2
                  local.get 9
                  i32.const -4
                  i32.and
                  i32.store
                  local.get 1
                  local.set 9
                  br 1 (;@6;)
                end
                local.get 9
                i32.const 0
                i32.store
                local.get 9
                i32.const -8
                i32.add
                local.tee 9
                i64.const 0
                i64.store align=4
                local.get 9
                local.get 1
                i32.load
                i32.const -4
                i32.and
                i32.store
                block  ;; label = @7
                  local.get 1
                  i32.load
                  local.tee 11
                  i32.const -4
                  i32.and
                  local.tee 2
                  i32.eqz
                  br_if 0 (;@7;)
                  local.get 11
                  i32.const 2
                  i32.and
                  br_if 0 (;@7;)
                  local.get 2
                  local.get 2
                  i32.load offset=4
                  i32.const 3
                  i32.and
                  local.get 9
                  i32.or
                  i32.store offset=4
                end
                local.get 9
                local.get 9
                i32.load offset=4
                i32.const 3
                i32.and
                local.get 1
                i32.or
                i32.store offset=4
                local.get 1
                local.get 1
                i32.load offset=8
                i32.const -2
                i32.and
                i32.store offset=8
                local.get 1
                local.get 1
                i32.load
                local.tee 2
                i32.const 3
                i32.and
                local.get 9
                i32.or
                local.tee 11
                i32.store
                local.get 2
                i32.const 2
                i32.and
                i32.eqz
                br_if 0 (;@6;)
                local.get 1
                local.get 11
                i32.const -3
                i32.and
                i32.store
                local.get 9
                local.get 9
                i32.load
                i32.const 2
                i32.or
                i32.store
              end
              local.get 9
              local.get 9
              i32.load
              i32.const 1
              i32.or
              i32.store
              local.get 9
              i32.const 8
              i32.add
              local.set 6
              br 4 (;@1;)
            end
            local.get 1
            local.get 9
            i32.const -2
            i32.and
            i32.store offset=8
            block  ;; label = @5
              block  ;; label = @6
                local.get 1
                i32.load offset=4
                i32.const -4
                i32.and
                local.tee 9
                br_if 0 (;@6;)
                i32.const 0
                local.set 9
                br 1 (;@5;)
              end
              i32.const 0
              local.get 9
              local.get 9
              i32.load8_u
              i32.const 1
              i32.and
              select
              local.set 9
            end
            local.get 1
            call $_ZN9wee_alloc9neighbors18Neighbors$LT$T$GT$6remove17h471b2d872d895f83E
            block  ;; label = @5
              local.get 1
              i32.load8_u
              i32.const 2
              i32.and
              i32.eqz
              br_if 0 (;@5;)
              local.get 9
              local.get 9
              i32.load
              i32.const 2
              i32.or
              i32.store
            end
            local.get 2
            local.get 9
            i32.store
            local.get 9
            local.set 1
            br 0 (;@4;)
          end
        end
        local.get 2
        local.get 9
        i32.store
        br 0 (;@2;)
      end
    end
    local.get 6)
  (func $_ZN9wee_alloc9neighbors18Neighbors$LT$T$GT$6remove17h471b2d872d895f83E (type 10) (param i32)
    (local i32 i32)
    block  ;; label = @1
      local.get 0
      i32.load
      local.tee 1
      i32.const -4
      i32.and
      local.tee 2
      i32.eqz
      br_if 0 (;@1;)
      local.get 1
      i32.const 2
      i32.and
      br_if 0 (;@1;)
      local.get 2
      local.get 2
      i32.load offset=4
      i32.const 3
      i32.and
      local.get 0
      i32.load offset=4
      i32.const -4
      i32.and
      i32.or
      i32.store offset=4
    end
    block  ;; label = @1
      local.get 0
      i32.load offset=4
      local.tee 2
      i32.const -4
      i32.and
      local.tee 1
      i32.eqz
      br_if 0 (;@1;)
      local.get 1
      local.get 1
      i32.load
      i32.const 3
      i32.and
      local.get 0
      i32.load
      i32.const -4
      i32.and
      i32.or
      i32.store
      local.get 0
      i32.load offset=4
      local.set 2
    end
    local.get 0
    local.get 2
    i32.const 3
    i32.and
    i32.store offset=4
    local.get 0
    local.get 0
    i32.load
    i32.const 3
    i32.and
    i32.store)
  (func $_ZN4core3ptr13drop_in_place17h7331000ec308b9d9E (type 10) (param i32))
  (func $_ZN70_$LT$wee_alloc..LargeAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$22new_cell_for_free_list17h42eaff174078b105E (type 2) (param i32 i32 i32 i32)
    (local i32)
    block  ;; label = @1
      block  ;; label = @2
        local.get 2
        i32.const 2
        i32.shl
        local.tee 2
        local.get 3
        i32.const 3
        i32.shl
        i32.const 16384
        i32.add
        local.tee 3
        local.get 2
        local.get 3
        i32.gt_u
        select
        i32.const 65543
        i32.add
        local.tee 4
        i32.const 16
        i32.shr_u
        memory.grow
        local.tee 3
        i32.const -1
        i32.ne
        br_if 0 (;@2;)
        i32.const 1
        local.set 2
        br 1 (;@1;)
      end
      local.get 3
      i32.const 16
      i32.shl
      local.tee 3
      i64.const 0
      i64.store
      i32.const 0
      local.set 2
      local.get 3
      i32.const 0
      i32.store offset=8
      local.get 3
      local.get 3
      local.get 4
      i32.const -65536
      i32.and
      i32.add
      i32.const 2
      i32.or
      i32.store
    end
    local.get 0
    local.get 3
    i32.store offset=4
    local.get 0
    local.get 2
    i32.store)
  (func $_ZN70_$LT$wee_alloc..LargeAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$13min_cell_size17hbae67615d69030e4E (type 1) (param i32 i32) (result i32)
    i32.const 512)
  (func $_ZN70_$LT$wee_alloc..LargeAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$32should_merge_adjacent_free_cells17h9166c84a57c9db44E (type 3) (param i32) (result i32)
    i32.const 1)
  (func $_ZN88_$LT$wee_alloc..size_classes..SizeClassAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$13min_cell_size17h3da3d65fba1244d4E (type 1) (param i32 i32) (result i32)
    local.get 1)
  (func $_ZN88_$LT$wee_alloc..size_classes..SizeClassAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$32should_merge_adjacent_free_cells17h39aff427f58f3059E (type 3) (param i32) (result i32)
    i32.const 0)
  (func $_ZN4core3ptr13drop_in_place17he93fd79fb3b3e69bE (type 10) (param i32))
  (func $_ZN9wee_alloc8WeeAlloc12dealloc_impl28_$u7b$$u7b$closure$u7d$$u7d$17h0bcfd582ebbac4eeE (type 2) (param i32 i32 i32 i32)
    (local i32)
    local.get 0
    i32.load
    local.tee 4
    i32.const 0
    i32.store
    local.get 4
    i32.const -8
    i32.add
    local.tee 0
    local.get 0
    i32.load
    i32.const -2
    i32.and
    i32.store
    block  ;; label = @1
      local.get 2
      local.get 3
      i32.load offset=20
      call_indirect (type 3)
      i32.eqz
      br_if 0 (;@1;)
      block  ;; label = @2
        block  ;; label = @3
          local.get 4
          i32.const -4
          i32.add
          i32.load
          i32.const -4
          i32.and
          local.tee 2
          i32.eqz
          br_if 0 (;@3;)
          local.get 2
          i32.load8_u
          i32.const 1
          i32.and
          i32.eqz
          br_if 1 (;@2;)
        end
        local.get 0
        i32.load
        local.tee 2
        i32.const -4
        i32.and
        local.tee 3
        i32.eqz
        br_if 1 (;@1;)
        local.get 2
        i32.const 2
        i32.and
        br_if 1 (;@1;)
        local.get 3
        i32.load8_u
        i32.const 1
        i32.and
        br_if 1 (;@1;)
        local.get 4
        local.get 3
        i32.load offset=8
        i32.const -4
        i32.and
        i32.store
        local.get 3
        local.get 0
        i32.const 1
        i32.or
        i32.store offset=8
        return
      end
      local.get 0
      call $_ZN9wee_alloc9neighbors18Neighbors$LT$T$GT$6remove17h471b2d872d895f83E
      block  ;; label = @2
        local.get 0
        i32.load8_u
        i32.const 2
        i32.and
        i32.eqz
        br_if 0 (;@2;)
        local.get 2
        local.get 2
        i32.load
        i32.const 2
        i32.or
        i32.store
      end
      return
    end
    local.get 4
    local.get 1
    i32.load
    i32.store
    local.get 1
    local.get 0
    i32.store)
  (func $memcpy (type 0) (param i32 i32 i32) (result i32)
    (local i32)
    block  ;; label = @1
      local.get 2
      i32.eqz
      br_if 0 (;@1;)
      local.get 0
      local.set 3
      loop  ;; label = @2
        local.get 3
        local.get 1
        i32.load8_u
        i32.store8
        local.get 3
        i32.const 1
        i32.add
        local.set 3
        local.get 1
        i32.const 1
        i32.add
        local.set 1
        local.get 2
        i32.const -1
        i32.add
        local.tee 2
        br_if 0 (;@2;)
      end
    end
    local.get 0)
  (func $memset (type 0) (param i32 i32 i32) (result i32)
    (local i32)
    block  ;; label = @1
      local.get 2
      i32.eqz
      br_if 0 (;@1;)
      local.get 0
      local.set 3
      loop  ;; label = @2
        local.get 3
        local.get 1
        i32.store8
        local.get 3
        i32.const 1
        i32.add
        local.set 3
        local.get 2
        i32.const -1
        i32.add
        local.tee 2
        br_if 0 (;@2;)
      end
    end
    local.get 0)
  (table (;0;) 19 19 funcref)
  (memory (;0;) 17)
  (global (;0;) (mut i32) (i32.const 1048576))
  (global (;1;) i32 (i32.const 1051032))
  (global (;2;) i32 (i32.const 1051032))
  (export "memory" (memory 0))
  (export "setBlsDeliberateError" (func $setBlsDeliberateError))
  (export "getBlsDeliberateError" (func $getBlsDeliberateError))
  (export "init" (func $init))
  (export "stake" (func $stake))
  (export "unStake" (func $unStake))
  (export "unBond" (func $unBond))
  (export "claim" (func $claim))
  (export "callBack" (func $callBack))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2))
  (elem (;0;) (i32.const 1) func $_ZN4core3fmt3num3imp52_$LT$impl$u20$core..fmt..Display$u20$for$u20$u32$GT$3fmt17h4d5f6e7a5de9cb88E $_ZN4core3ops8function6FnOnce9call_once17h7513c2557cb8bf69E $_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17heb3f43a8856346abE $_ZN42_$LT$$RF$T$u20$as$u20$core..fmt..Debug$GT$3fmt17h1316c3c5708d25dcE $_ZN44_$LT$$RF$T$u20$as$u20$core..fmt..Display$GT$3fmt17hdefa33539845c2d1E $_ZN4core3ptr13drop_in_place17h0dc95bc6c2c4e7acE $_ZN50_$LT$$RF$mut$u20$W$u20$as$u20$core..fmt..Write$GT$9write_str17h5cc6f7e2d0e384f9E $_ZN50_$LT$$RF$mut$u20$W$u20$as$u20$core..fmt..Write$GT$10write_char17h80f20bbe3df2881eE $_ZN50_$LT$$RF$mut$u20$W$u20$as$u20$core..fmt..Write$GT$9write_fmt17h3d6b4f53d0620b38E $_ZN53_$LT$core..fmt..Error$u20$as$u20$core..fmt..Debug$GT$3fmt17h4c91dac37b7a3712E $_ZN4core3ptr13drop_in_place17h7331000ec308b9d9E $_ZN70_$LT$wee_alloc..LargeAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$22new_cell_for_free_list17h42eaff174078b105E $_ZN70_$LT$wee_alloc..LargeAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$13min_cell_size17hbae67615d69030e4E $_ZN70_$LT$wee_alloc..LargeAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$32should_merge_adjacent_free_cells17h9166c84a57c9db44E $_ZN4core3ptr13drop_in_place17he93fd79fb3b3e69bE $_ZN88_$LT$wee_alloc..size_classes..SizeClassAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$22new_cell_for_free_list17hb8cba68b14d3cac1E $_ZN88_$LT$wee_alloc..size_classes..SizeClassAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$13min_cell_size17h3da3d65fba1244d4E $_ZN88_$LT$wee_alloc..size_classes..SizeClassAllocPolicy$u20$as$u20$wee_alloc..AllocPolicy$GT$32should_merge_adjacent_free_cells17h39aff427f58f3059E)
  (data (;0;) (i32.const 1048576) "wrong number of argumentsargument decode error (): stake_per_nodenum_nodesstake_bls_keystake_bls_sigunStake_bls_keyunBond_bls_keystaking_failurebls_deliberate_errorbls_keyerr_codeauction smart contract deliberate errorincorrect payment to auction mocksrc/lib.rs\00\00\00\fb\00\10\00\0a\00\00\00,\00\00\00\1c\00\00\00\fb\00\10\00\0a\00\00\00.\00\00\00\1c\00\00\00unbond stakeno callbacks in contractbls_keys_signatures_argsbls_keyscapacity overflow\00\00\00\90\01\10\00\17\00\00\00n\02\00\00\05\00\00\00src/liballoc/raw_vec.rs\00\06\00\00\00\04\00\00\00\04\00\00\00\07\00\00\00\08\00\00\00\09\00\00\00a formatting trait implementation returned an error\00\06\00\00\00\00\00\00\00\01\00\00\00\0a\00\00\00\14\02\10\00\13\00\00\00J\02\00\00\05\00\00\00src/liballoc/fmt.rs\008\02\10\00 \00\00\00X\02\10\00\12\00\00\00index out of bounds: the len is  but the index is 00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899\00\00T\03\10\00\16\00\00\00V\04\00\00$\00\00\00T\03\10\00\16\00\00\00L\04\00\00\11\00\00\00src/libcore/fmt/mod.rs\00\00\84\03\10\00\00\00\00\00|\03\10\00\02\00\00\00: Error\00array decode errorunsupported operationinvalid valueinput too longinput too short\00\00\00\13\04\10\00b\00\00\00\d2\00\00\00\1e\00\00\00called `Option::unwrap()` on a `None` value/home/hjorthjort/.cargo/registry/src/github.com-1ecc6299db9ec823/elrond-wasm-node-0.5.1/src/ext.rs\00\00\00\88\04\10\00g\00\00\00]\01\00\00:\00\00\00/home/hjorthjort/.cargo/registry/src/github.com-1ecc6299db9ec823/elrond-wasm-node-0.5.1/src/big_uint.rsattempted to transfer funds via a non-payable functionallocation errorunknown panic occurred\00T\05\10\00\10\00\00\00panic occurred: \0b\00\00\00\00\00\00\00\01\00\00\00\0c\00\00\00\0d\00\00\00\0e\00\00\00\0f\00\00\00\04\00\00\00\04\00\00\00\10\00\00\00\11\00\00\00\12\00\00\00")
  (data (;1;) (i32.const 1050004) "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00"))
