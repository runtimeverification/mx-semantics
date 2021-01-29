setExitCode 1

setAccount("testDeployer", 0, 0, .Code, .Map)
newAddress("testDeployer", 0, "testContract")

scDeploy(
  deployTx(
      "testDeployer"
    , 0
    , (module
        (func (export "init"))
        (func (export "test"))
      )
      , .List
      , 0
      , 0)
    , .Expect
)

setAccount("testCaller", 0, 0, .Code, .Map)
scCall(
  callTx(
      "testCaller"
    , "testContract"
    , 0
    , "test"
    , .List
    , 0
    , 0)
  , .Expect
)

setExitCode 0
