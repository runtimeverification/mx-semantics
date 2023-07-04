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
  (import "env" "getStorage" (func (;0;) (type 0)))
  (import "env" "bigIntGetUnsignedArgument" (func (;1;) (type 1)))
  (import "env" "mBufferGetArgument" (func (;2;) (type 2)))
  (import "env" "getNumArguments" (func (;3;) (type 3)))
  (import "env" "signalError" (func (;4;) (type 1)))
  (import "env" "mBufferAppendBytes" (func (;5;) (type 4)))
  (import "env" "bigIntSetInt64" (func (;6;) (type 5)))
  (import "env" "mBufferSetBytes" (func (;7;) (type 4)))
  (import "env" "mBufferStorageLoad" (func (;8;) (type 2)))
  (import "env" "mBufferGetLength" (func (;9;) (type 6)))
  (import "env" "mBufferStorageStore" (func (;10;) (type 2)))
  (import "env" "managedSignalError" (func (;11;) (type 7)))
  (import "env" "mBufferToBigIntUnsigned" (func (;12;) (type 2)))
  (import "env" "bigIntCmp" (func (;13;) (type 2)))
  (import "env" "checkNoPayment" (func (;14;) (type 8)))
  (import "env" "createAccount" (func (;15;) (type 9)))
  (import "env" "registerNewAddress" (func (;16;) (type 9)))
  (import "env" "deployContract" (func (;17;) (type 10)))
  (import "env" "assertBool" (func (;18;) (type 7)))
  (import "env" "assumeBool" (func (;19;) (type 7)))
  (import "env" "mBufferFromBigIntUnsigned" (func (;20;) (type 2)))
  (import "env" "startPrank" (func (;21;) (type 7)))
  (import "env" "managedTransferValueExecute" (func (;22;) (type 11)))
  (import "env" "stopPrank" (func (;23;) (type 8)))
  (import "env" "bigIntAdd" (func (;24;) (type 0)))
  (func (;25;) (type 2) (param i32 i32) (result i32)
    (local i32)
    local.get 0
    local.get 1
    call 26
    local.tee 2
    call 0
    local.get 2)
  (func (;26;) (type 3) (result i32)
    (local i32)
    call 28
    local.tee 0
    i32.const 131264
    i32.const 0
    call 7
    drop
    local.get 0)
  (func (;27;) (type 3) (result i32)
    (local i32)
    i32.const 0
    call 28
    local.tee 0
    call 1
    local.get 0)
  (func (;28;) (type 3) (result i32)
    (local i32)
    i32.const 0
    i32.const 0
    i32.load offset=131280
    i32.const -1
    i32.add
    local.tee 0
    i32.store offset=131280
    local.get 0)
  (func (;29;) (type 3) (result i32)
    (local i32)
    i32.const 0
    call 28
    local.tee 0
    call 2
    drop
    local.get 0)
  (func (;30;) (type 8)
    block  ;; label = @1
      call 3
      i32.const 1
      i32.ne
      br_if 0 (;@1;)
      return
    end
    i32.const 131142
    i32.const 25
    call 4
    unreachable)
  (func (;31;) (type 1) (param i32 i32)
    (local i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 2
    global.set 0
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
    call 5
    drop
    local.get 2
    i32.const 16
    i32.add
    global.set 0)
  (func (;32;) (type 2) (param i32 i32) (result i32)
    i32.const -14
    local.get 1
    i64.extend_i32_u
    call 6
    local.get 0
    i32.const -14
    call 33)
  (func (;33;) (type 2) (param i32 i32) (result i32)
    i32.const -1
    local.get 0
    local.get 1
    call 13
    local.tee 1
    i32.const 0
    i32.ne
    local.get 1
    i32.const 0
    i32.lt_s
    select)
  (func (;34;) (type 2) (param i32 i32) (result i32)
    (local i32)
    call 28
    local.tee 2
    local.get 0
    local.get 1
    call 7
    drop
    local.get 2)
  (func (;35;) (type 6) (param i32) (result i32)
    local.get 0
    i32.const 32
    call 34)
  (func (;36;) (type 6) (param i32) (result i32)
    (local i32)
    local.get 0
    call 28
    local.tee 1
    call 8
    drop
    block  ;; label = @1
      local.get 1
      call 9
      i32.const 32
      i32.eq
      br_if 0 (;@1;)
      call 37
      unreachable
    end
    local.get 1)
  (func (;37;) (type 8)
    (local i32)
    i32.const 131199
    i32.const 22
    call 34
    local.tee 0
    i32.const 131221
    i32.const 16
    call 5
    drop
    local.get 0
    call 11
    unreachable)
  (func (;38;) (type 1) (param i32 i32)
    local.get 0
    local.get 1
    call 10
    drop)
  (func (;39;) (type 6) (param i32) (result i32)
    local.get 0
    i32.const 3
    call 34)
  (func (;40;) (type 6) (param i32) (result i32)
    (local i32)
    local.get 0
    call 28
    local.tee 1
    call 12
    drop
    local.get 1)
  (func (;41;) (type 3) (result i32)
    i32.const 131237
    i32.const 12
    call 34)
  (func (;42;) (type 3) (result i32)
    i32.const 131249
    i32.const 12
    call 34)
  (func (;43;) (type 8)
    call 44
    unreachable)
  (func (;44;) (type 8)
    i32.const 131264
    i32.const 14
    call 4
    unreachable)
  (func (;45;) (type 8)
    (local i32 i32 i32 i32 i32 i32 i32)
    global.get 0
    i32.const 16
    i32.sub
    local.tee 0
    global.set 0
    call 14
    call 30
    call 29
    local.set 1
    i32.const 131078
    call 35
    local.set 2
    call 42
    local.get 2
    call 38
    call 28
    local.tee 3
    i64.const 0
    call 6
    local.get 2
    i64.const 1
    local.get 3
    call 15
    local.get 2
    i64.const 1
    i32.const 131110
    call 35
    call 16
    call 26
    local.set 4
    call 26
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
            call 46
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
      call 7
      drop
      local.get 4
      local.get 5
      call 31
      call 28
      local.tee 6
      i64.const 0
      call 6
      local.get 2
      i64.const 5000000000000
      local.get 6
      local.get 1
      local.get 4
      i32.const 131167
      call 35
      local.tee 3
      call 17
      call 41
      local.get 3
      call 38
      local.get 3
      i32.const 131075
      call 39
      call 25
      call 40
      i32.const 5
      call 32
      i32.const 255
      i32.and
      i32.eqz
      call 18
      local.get 0
      i32.const 16
      i32.add
      global.set 0
      return
    end
    call 47
    unreachable)
  (func (;46;) (type 7) (param i32)
    local.get 0
    call 51
    unreachable)
  (func (;47;) (type 8)
    call 50
    unreachable)
  (func (;48;) (type 8)
    (local i32 i32 i32 i32 i32)
    call 14
    call 30
    call 27
    local.tee 0
    i32.const 100
    call 32
    i32.const 1
    i32.add
    i32.const 255
    i32.and
    i32.const 2
    i32.lt_u
    call 19
    call 42
    call 36
    local.set 1
    call 41
    call 36
    local.set 2
    call 26
    local.set 3
    call 26
    drop
    call 28
    local.tee 4
    local.get 0
    call 20
    drop
    local.get 3
    local.get 4
    call 31
    local.get 1
    call 21
    call 28
    local.tee 1
    i64.const 0
    call 6
    local.get 2
    local.get 1
    i64.const 5000000
    i32.const 131072
    call 39
    local.get 3
    call 22
    local.set 3
    call 23
    block  ;; label = @1
      local.get 3
      i32.eqz
      br_if 0 (;@1;)
      call 47
      unreachable
    end
    local.get 2
    i32.const 131075
    call 39
    call 25
    call 40
    local.set 3
    i32.const -14
    i64.const 5
    call 6
    local.get 0
    local.get 0
    i32.const -14
    call 24
    local.get 3
    local.get 0
    call 33
    i32.const 255
    i32.and
    i32.eqz
    call 18)
  (func (;49;) (type 8))
  (func (;50;) (type 8)
    call 43
    unreachable)
  (func (;51;) (type 7) (param i32)
    call 50
    unreachable)
  (table (;0;) 1 1 funcref)
  (memory (;0;) 3)
  (global (;0;) (mut i32) (i32.const 131072))
  (global (;1;) i32 (i32.const 131284))
  (global (;2;) i32 (i32.const 131296))
  (export "memory" (memory 0))
  (export "init" (func 45))
  (export "test_call_add" (func 48))
  (export "callBack" (func 49))
  (export "__data_end" (global 1))
  (export "__heap_base" (global 2))
  (data (;0;) (i32.const 131072) "addsumowner___________________________adder___________________________wrong number of arguments\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00storage decode error: bad array lengthadderAddressownerAddress\00\00\00panic occurred")
  (data (;1;) (i32.const 131280) "\9c\ff\ff\ff"))
