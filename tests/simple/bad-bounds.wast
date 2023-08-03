setExitCode 1

setAccount("testDeployer", 0, 0, .Code, .Bytes, .MapBytesToBytes)
newAddress("testDeployer", 0, "testContract")

deployTx(
  "testDeployer"
  , 0
  , (module
      (import "env" "getCaller" (func $getCaller (param i32)))
      (import "env" "isSmartContract" (func $isSmartContract (param i32) (result i32)))
      (import "env" "writeEventLog" (func $writeEventLog (param i32 i32 i32 i32 i32)))
      
      (import "env" "smallIntGetUnsignedArgument" 
        (func $smallIntGetUnsignedArgument (param i32) (result i64))
      )
      
      (import "env" "smallIntGetSignedArgument" 
        (func $smallIntGetSignedArgument (param i32) (result i64))
      )
      
      (import "env" "smallIntFinishUnsigned" (func $smallIntFinishUnsigned (param i64)))
      (import "env" "smallIntFinishSigned"   (func $smallIntFinishSigned   (param i64)))

      (func (export "memStoreNegativeOffset")
        i32.const -1
        call $getCaller
      )
      (func (export "memStoreTooBigOffset")
        i32.const 2147483647
        call $getCaller
      )
      (func (export "memLoadNegativeOffset")
        i32.const -1
        call $isSmartContract
      )
      (func (export "memLoadTooBigOffset")
        i32.const 2147483647
        call $isSmartContract
      )
      (func (export "negativeNumArgs")
        i32.const -1
        i32.const 0
        i32.const 0
        i32.const 0
        i32.const 0
        call $writeEventLog
      )

      (func (export "smallIntGetUnsignedArgumentTest")
        (call $smallIntGetSignedArgument (i32.const 0)) ;; read the first argument: i
        i32.wrap_i64
        call $smallIntGetUnsignedArgument                 ;; read the ith argument
        call $smallIntFinishUnsigned                      ;; return it
      )

      (func (export "smallIntGetSignedArgumentTest")
        (call $smallIntGetSignedArgument (i32.const 0)) ;; read the first argument: i
        i32.wrap_i64
        call $smallIntGetSignedArgument                   ;; read the ith argument
        call $smallIntFinishSigned                        ;; return it
      )

      (func (export "init"))
      (memory (;0;) 17)
      (export "memory" (memory 0))
    )
  , .ListBytes
  , 0
  , 0
)

setAccount("testCaller", 0, 0, .Code, .Bytes, .MapBytesToBytes)

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "memStoreNegativeOffset", .ListBytes
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"bad bounds (lower)")

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "memStoreTooBigOffset", .ListBytes
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"bad bounds (upper)")

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "memLoadNegativeOffset", .ListBytes
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"mem load: bad bounds")

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "memLoadTooBigOffset", .ListBytes
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"mem load: bad bounds")

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "negativeNumArgs", .ListBytes
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"negative numArguments")

;; pass 2 arguments, get 2nd
callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "smallIntGetUnsignedArgumentTest"
  , ListItem(Int2Bytes(1, BE, Signed)) ListItem(Int2Bytes(123, BE, Unsigned))
  , 0
  , 0
)

checkExpectStatus(OK)
checkExpectOut(ListItem(Int2Bytes(123, BE, Unsigned)))


;; pass 1 argument, get 2nd, should fail
callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "smallIntGetUnsignedArgumentTest"
  , ListItem(Int2Bytes(1, BE, Signed))
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"argument index out of range")


;; pass 2 arguments, get -1st, should fail
callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "smallIntGetUnsignedArgumentTest"
  , ListItem(Int2Bytes(-1, BE, Signed)) ListItem(Int2Bytes(123, BE, Unsigned))
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"argument index out of range")


;; pass 2 arguments (2nd is too big for u64), get 2nd, should fail
callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "smallIntGetUnsignedArgumentTest"
  , ListItem(Int2Bytes(1, BE, Signed))
    ListItem(Int2Bytes(maxUInt64 +Int 5, BE, Unsigned))
  , 0
  , 0
)

checkExpectStatus(UserError)
checkExpectMessage(b"argument out of range")

setExitCode 0
