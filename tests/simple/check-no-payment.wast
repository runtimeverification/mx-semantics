setExitCode 1

setAccount("testDeployer", 0, 0, .Code, .Bytes, .MapBytesToBytes)
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
  , .ListBytes
  , 0
  , 0
)

setAccount("testCaller", 0, 100, .Code, .Bytes, .MapBytesToBytes)
setEsdtBalance(b"\"testCaller\"", b"my-tok", 20)

callTx(
    "testCaller"
  , "testContract"
  , 10, .List
  , "payable", .ListBytes
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
  , "nonPayable", .ListBytes
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"function does not accept EGLD payment")
checkAccountBalance("testCaller", 90)
checkAccountBalance("testContract", 10)

callTx(
    "testCaller"
  , "testContract"
  , 10, ListItem(esdtTransfer(b"my-tok", 10, 0))
  , "nonPayable", .ListBytes
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"function does not accept EGLD payment")
checkAccountBalance("testCaller", 90)
checkAccountBalance("testContract", 10)

callTx(
    "testCaller"
  , "testContract"
  , 0, ListItem(esdtTransfer(b"my-tok", 10, 0))
  , "nonPayable", .ListBytes
  , 0
  , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"function does not accept ESDT payment")
checkAccountBalance("testCaller", 90)
checkAccountBalance("testContract", 10)

setExitCode 0
