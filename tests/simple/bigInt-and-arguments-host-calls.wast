setExitCode 1

setAccount("testDeployer", 0, 0, "", .Map)
newAddress("testDeployer", 0, "testContract")

scDeploy(
  deployTx(
      "testDeployer"
    , 2 ^Int 256
    , (module
        (import "env" "bigIntAdd"               (func $bigIntAdd               (param i32 i32 i32)             ))
        (import "env" "bigIntCmp"               (func $bigIntCmp               (param i32 i32)     (result i32)))
        (import "env" "bigIntFinishSigned"      (func $bigIntFinishSigned      (param i32)                     ))
        (import "env" "bigIntGetCallValue"      (func $bigIntGetCallValue      (param i32)                     ))
        (import "env" "bigIntGetSignedArgument" (func $bigIntGetSignedArgument (param i32 i32)                 ))
        (import "env" "bigIntGetSignedBytes"    (func $bigIntGetSignedBytes    (param i32 i32)     (result i32)))
        (import "env" "bigIntNew"               (func $bigIntNew               (param i64)         (result i32)))
        (import "env" "bigIntSetSignedBytes"    (func $bigIntSetSignedBytes    (param i32 i32 i32)             ))
        (import "env" "bigIntSignedByteLength"  (func $bigIntSignedByteLength  (param i32)         (result i32)))

        (import "env" "getArgument"       (func $getArgument       (param i32 i32) (result i32)))
        (import "env" "getArgumentLength" (func $getArgumentLength (param i32)     (result i32)))
        (import "env" "getNumArguments"   (func $getNumArguments                   (result i32)))

        (import "env" "storageLoadLength" (func $storageLoadLength (param i32 i32)         (result i32)))
        (import "env" "storageLoad"       (func $storageLoad       (param i32 i32 i32)     (result i32)))
        (import "env" "storageStore"      (func $storageStore      (param i32 i32 i32 i32) (result i32)))

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

        (func $bigIntTest (local i32 i32 i32)
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

          (call $bigIntGetCallValue (i32.const 0))
          (call $bigIntGetSignedArgument (i32.const 1) (i32.const 1))
          ;; Add 1 to bigInt 1, where the argument is stored.
          (call $bigIntAdd (i32.const 1) (call $bigIntNew (i64.const 1)) (i32.const 1))
          (call $bigIntCmp (i32.const 0) (i32.const 1))
          i32.const 0
          call $i32.assertEqual

          ;; 15537779347414411345 is the little-endian interpretation of the big-endian 5865948865492394455
          i32.const 0
          i64.const 15537779347414411345
          i64.store
          (call $bigIntSetSignedBytes (i32.const 0) (i32.const 0) (i32.const 8))
          i64.const 5865948865492394455
          call $bigIntNew
          i32.const 0
          call $bigIntCmp
          i32.const 0
          call $i32.assertEqual

          i64.const 5865948865492394455
          call $bigIntNew
          local.set 0
          i64.const 5865948865492394454
          call $bigIntNew
          local.set 1
          i64.const 5865948865492394456
          call $bigIntNew
          local.set 2
          (call $bigIntCmp (local.get 0) (local.get 1))
          i32.const 1
          call $i32.assertEqual
          (call $bigIntCmp (local.get 0) (local.get 2))
          i32.const -1
          call $i32.assertEqual

          local.get 0
          call $bigIntSignedByteLength
          i32.const 8
          call $i32.assertEqual
          (call $bigIntGetCallValue (local.get 0))
          local.get 0
          call $bigIntSignedByteLength
          i32.const 33
          call $i32.assertEqual

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

           ;; Load a 0 argument
           (call $getArgument (i32.const 0) (i32.const 16))
           i32.const 0
           call $i32.assertEqual
           (i32.load i32.const 16)
           i32.const 0
           call $i32.assertEqual

           ;; Load a 32-byte argument
           (call $getArgument (i32.const 1) (i32.const 32))
           i32.const 32
           call $i32.assertEqual
           ;; Check that it's all 1-bits frombyte 32 to byte 63
           (i64.load (i32.const 32))
           (i64.sub (i64.const 0) (i64.const 1))
           call $i64.assertEqual
           (i64.load (i32.const 40))
           (i64.sub (i64.const 0) (i64.const 1))
           call $i64.assertEqual
           (i64.load (i32.const 48))
           (i64.sub (i64.const 0) (i64.const 1))
           call $i64.assertEqual
           (i64.load (i32.const 56))
           (i64.sub (i64.const 0) (i64.const 1))
           call $i64.assertEqual
           ;; Check that bytes weren't set adjacently.
           (i32.load8_u (i32.const 31))
           i32.const 0
           call $i32.assertEqual
           (i32.load8_u (i32.const 64))
           i32.const 0
           call $i32.assertEqual
        )

        (func $storageTest
          i32.const 0
          i64.const 1848529
          i64.store
          i32.const 8
          i64.const 99999999999
          i64.store
          (call $storageStore (i32.const 0) (i32.const 8) (i32.const 8) (i32.const 8))
          i32.const #StorageAdded()
          call $i32.assertEqual
          (call $storageLoadLength (i32.const 0) (i32.const 8))
          i32.const 8
          call $i32.assertEqual
          (call $storageLoad (i32.const 0) (i32.const 8) (i32.const 16))
          i32.const 16
          i64.load
          i64.const 99999999999
          call $i64.assertEqual

          i32.const 8
          i64.const 99999999999
          i64.store
          (call $storageStore (i32.const 0) (i32.const 8) (i32.const 8) (i32.const 8))
          i32.const #StorageUnmodified()
          call $i32.assertEqual

          i32.const 8
          i64.const 77777777777
          i64.store
          (call $storageStore (i32.const 0) (i32.const 8) (i32.const 8) (i32.const 8))
          i32.const #StorageModified()
          call $i32.assertEqual

          (call $storageStore (i32.const 0) (i32.const 8) (i32.const 8) (i32.const 0))
          i32.const #StorageDeleted()
          call $i32.assertEqual
          (call $storageStore (i32.const 0) (i32.const 8) (i32.const 8) (i32.const 8))
          i32.const #StorageAdded()
          call $i32.assertEqual
        )

        (func (export "init")
          call $bigIntTest
          call $argsTest
          call $storageTest

          i64.const 777
          call $bigIntNew
          call $bigIntFinishSigned
        )
      )
      , ListItem(arg(0, 0)) ListItem(arg(2 ^Int 256 -Int 1, 32))
      , 0
      , 0)
    , .Expect
)

#assertReturnData(Int2Bytes(777, BE, Signed))

setExitCode 0
