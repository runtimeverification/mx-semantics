setExitCode 1

setAccount("testDeployer", 0, 0, .Code, .Map)
newAddress("testDeployer", 0, "testContract")

deployTx(
  "testDeployer"
  , 0
  , (module
      (func (export "init"))
      (func (export "test"))
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
  , .List
  , "test"
  , .List
  , 0
  , 0
)

setExitCode 0
