setExitCode 1

setAccount("testDeployer", 0, 0, .Code, .Map)
newAddress("testDeployer", 0, "testContract")

deployTx(
  "testDeployer"
  , 0
  , (module
      (import "env" "getCaller" (func $getCaller (param i32)))
      (import "env" "isSmartContract" (func $isSmartContract (param i32) (result i32)))
      (import "env" "writeEventLog" (func $writeEventLog (param i32 i32 i32 i32 i32)))
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
      (func (export "init"))
      (memory (;0;) 17)
      (export "memory" (memory 0))
    )
  , .List
  , 0
  , 0
)

setAccount("testCaller", 0, 0, .Code, .Map)

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "memStoreNegativeOffset", .List
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"bad bounds (lower)")

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "memStoreTooBigOffset", .List
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"bad bounds (upper)")

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "memLoadNegativeOffset", .List
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"mem load: bad bounds")

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "memLoadTooBigOffset", .List
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"mem load: bad bounds")

callTx(
    "testCaller"
  , "testContract"
  , 0, .List
  , "negativeNumArgs", .List
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"negative numArguments")

setExitCode 0
