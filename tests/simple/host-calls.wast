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
        (import "env" "finish"   (func $finish (param i32 i32)))

        (import "env" "getNumArguments" (func $getNumArguments (result i32)))
        (import "env" "getArgumentLength" (func $getArgumentLength (param i32) (result i32)))
        (import "env" "getArgument" (func $getArgument (param i32 i32) (result i32)))

        (memory 1)

        (func $i32.assertEqual (param i32 i32)
          local.get 0
          local.get 1
          (if (i32.ne) (then unreachable))
        )

        (func $i64.assertEqual (param i64 i64)
          local.get 0
          local.get 1
          (if (i64.ne) (then unreachable))
        )

        (func $bigIntTest
          i64.const 1337
          call $bigIntNew
          i32.const 0
          call $i32.assertEqual
          i64.const #pow1(i64)
          call $bigIntNew
          i32.const 1
          call $i32.assertEqual
          i64.const #pow1(i64)
          call $bigIntNew
          i32.const 2
          call $i32.assertEqual

          i32.const 0
          i32.const 1
          i32.const 2
          call $bigIntAdd

          ;; Only first byte of memory should be set, other bytes untouched.
          i32.const 0
          i32.const 0
          call $bigIntGetSignedBytes
          i32.const 9
          call $i32.assertEqual
          i32.const 0
          i32.load8_s
          i32.const 1
          call $i32.assertEqual
          i32.const 1
          i64.load
          i64.const 0
          call $i64.assertEqual
          i32.const 8
          i64.load
          i64.const 0
          call $i64.assertEqual
        )

        (func $argsTest
           call $getNumArguments
           i32.const 2
           call $i32.assertEqual

           i32.const 0
           call $getArgumentLength
           i32.const 0
           call $i32.assertEqual

           i32.const 1
           call $getArgumentLength
           i32.const 32
           call $i32.assertEqual

           (call $getArgument (i32.const 0) (i32.const 16))
           i32.const 0
           call $i32.assertEqual
           (i32.load i32.const 16)
           i32.const 0
           call $i32.assertEqual

        )

        (func (export "init")
          call $bigIntTest
          call $argsTest

          i32.const 0
          i32.const 0
          call $finish
        )
      )
      , ListItem(arg(0, 0)) ListItem(arg(2 ^Int 32 -Int 1, 32))
      , 0
      , 0)
    , .Expect
)

setExitCode 0
