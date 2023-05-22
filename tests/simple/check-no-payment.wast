setExitCode 1

setAccount("testDeployer", 0, 0, .Code, .Bytes, .Map)
newAddress("testDeployer", 0, "testContract")

deployTx(
  "testDeployer"
  , 0
  , (module
      (import "env" "checkNoPayment" (func $checkNoPayment))
      (func (export "payable"))
      (func (export "nonPayable")
        call $checkNoPayment
      )
    )
  , .List
  , 0
  , 0
)

setAccount("testCaller", 0, 100, .Code, .Bytes, .Map)

callTx(
    "testCaller"
  , "testContract"
  , 10, .List
  , "payable", .List
  , 0
  , 0
)

checkExpectStatus(OK)
checkAccountBalance("testCaller", 90)
checkAccountBalance("testContract", 10)

callTx(
    "testCaller"
  , "testContract"
  , 10, .List
  , "nonPayable", .List
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkAccountBalance("testCaller", 90)
checkAccountBalance("testContract", 10)

setExitCode 0
