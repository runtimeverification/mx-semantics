setExitCode 1

setAccount("testDeployer", 0, 0, "", .Map)
newAddress("testDeployer", 0, "testContract")

scDeploy(
  deployTx(
      "testDeployer"
    , 0
    , (module
        (import "env" "bigIntAdd" (func $bigIntAdd (param i32 i32 i32)))
        (import "env" "bigIntNew" (func $bigIntNew (param i64) (result i32)))
        (import "env" "bigIntGetSignedBytes" (func $bigIntGetSignedBytes (param i32 i32) (result i32)))

        (memory 1)

        (func $bigIntTest
          i64.const 1337
          call $bigIntNew
          i32.const 0
          (if (i32.ne) (then unreachable))
          i64.const #pow1(i64)
          call $bigIntNew
          i32.const 1
          (if (i32.ne) (then unreachable))
          i64.const #pow1(i64)
          call $bigIntNew
          i32.const 2
          (if (i32.ne) (then unreachable))

          i32.const 0
          i32.const 1
          i32.const 2
          call $bigIntAdd

          ;; Only first byte of memory should be set, other bytes untouched.
          i32.const 0
          i32.const 0
          call $bigIntGetSignedBytes
          i32.const 9
          (if (i32.ne) (then unreachable))
          i32.const 0
          i32.load8_s
          i32.const 1
          (if (i32.eq) (then) (else unreachable))
          i32.const 1
          i64.load
          (if (i64.eqz) (then) (else unreachable))
          i32.const 8
          i64.load
          i64.const 0
          (if (i64.eqz) (then) (else unreachable))
        )

        (func (export "init")
          call $bigIntTest
        )
      )
      , .List
      , 0
      , 0)
    , .Expect
)

setExitCode 0
