setExitCode 1

setAccount("testDeployer", 0, 0, .Code, .Map)
newAddress("testDeployer", 0, "testContract")

deployTx(
  "testDeployer"
  , 0
  , (module
      (import "env" "bigIntUnsignedByteLength" (func $bigIntUnsignedByteLength (param i32) (result i32)))
      (import "env" "bigIntAdd" (func $bigIntAdd (param i32 i32 i32)))
      
      (func (export "invalidHandle")
        i32.const 123
        call $bigIntUnsignedByteLength
        drop
      )
      (func (export "invalidHandleAdd")
        i32.const 1
        i32.const 2
        i32.const 3
        call $bigIntAdd
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
  , 0
  , "invalidHandle", .List
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"no bigInt under the given handle")

callTx(
    "testCaller"
  , "testContract"
  , 0
  , "invalidHandleAdd", .List
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"no bigInt under the given handle")

setExitCode 0
