setExitCode 1

setAccount("testDeployer", 0, 0, .Code, .Bytes, .MapBytesToBytes)
newAddress("testDeployer", 0, "testContract")

deployTx(
  "testDeployer"
  , 0
  , (module
      (func (export "init"))
      (func (export "test"))
    )
  , .ListBytes
  , 0
  , 0
)

setAccount("testCaller", 0, 0, .Code, .Bytes, .MapBytesToBytes)
callTx(
    "testCaller"
  , "testContract"
  , 0
  , .List
  , "test"
  , .ListBytes
  , 0
  , 0
)

setExitCode 0
