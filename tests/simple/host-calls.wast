setExitCode 1

setAccount("testDeployer", 0, 2 ^Int 256, .Code, .Bytes, .MapBytesToBytes)
newAddress("testDeployer", 0, "testContract")

deployTx(
    "testDeployer"
  , 2 ^Int 256
  , (module
      (import "env" "bigIntAdd"               (func $bigIntAdd               (param i32 i32 i32)             ))
      (import "env" "bigIntCmp"               (func $bigIntCmp               (param i32 i32)     (result i32)))
      (import "env" "bigIntFinishSigned"      (func $bigIntFinishSigned      (param i32)                     ))
      (import "env" "bigIntGetCallValue"      (func $bigIntGetCallValue      (param i32)                     ))
      (import "env" "bigIntGetUnsignedArgument" (func $bigIntGetUnsignedArgument (param i32 i32)                 ))
      (import "env" "bigIntGetSignedArgument" (func $bigIntGetSignedArgument (param i32 i32)                 ))
      (import "env" "bigIntGetSignedBytes"    (func $bigIntGetSignedBytes    (param i32 i32)     (result i32)))
      (import "env" "bigIntNew"               (func $bigIntNew               (param i64)         (result i32)))
      (import "env" "bigIntSetInt64"          (func $bigIntSetInt64          (param i32 i64)                 ))
      (import "env" "bigIntGetInt64"          (func $bigIntGetInt64          (param i32)         (result i64)))
      (import "env" "bigIntSetSignedBytes"    (func $bigIntSetSignedBytes    (param i32 i32 i32)             ))
      (import "env" "bigIntSignedByteLength"  (func $bigIntSignedByteLength  (param i32)         (result i32)))
      (import "env" "bigIntSqrt"              (func $bigIntSqrt              (param i32 i32)                 ))
      (import "env" "bigIntNeg"               (func $bigIntNeg               (param i32 i32)                 ))
      (import "env" "bigIntAbs"               (func $bigIntAbs               (param i32 i32)                 ))

      (import "env" "getArgument"       (func $getArgument       (param i32 i32) (result i32)))
      (import "env" "getArgumentLength" (func $getArgumentLength (param i32)     (result i32)))
      (import "env" "getNumArguments"   (func $getNumArguments                   (result i32)))

      (import "env" "storageLoadLength" (func $storageLoadLength (param i32 i32)         (result i32)))
      (import "env" "storageLoad"       (func $storageLoad       (param i32 i32 i32)     (result i32)))
      (import "env" "storageStore"      (func $storageStore      (param i32 i32 i32 i32) (result i32)))

      (import "env" "getESDTTokenName"      (func $getESDTTokenName      (param i32) (result i32)))

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
        i32.const -1
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
        (call $bigIntGetUnsignedArgument (i32.const 1) (i32.const 1))
        ;; Add 1 to bigInt 1, where the argument is stored.
        (call $bigIntAdd (i32.const 1) (call $bigIntNew (i64.const 1)) (i32.const 1))
        (call $bigIntCmp (i32.const 0) (i32.const 1))
        i32.const 0
        call $i32.assertEqual
        (call $bigIntGetSignedArgument (i32.const 1) (i32.const 1))
        (call $bigIntAdd (i32.const 1) (call $bigIntNew (i64.const 1)) (i32.const 1))
        (call $bigIntCmp (i32.const 1) (call $bigIntNew (i64.const 0)))
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

        ;; bigIntNeg
        (call $i64.testNeg (local.get 0) (i64.const 123456)  (i64.const -123456))
        (call $i64.testNeg (local.get 0) (i64.const -123456) (i64.const 123456))
        (call $i64.testNeg (local.get 0) (i64.const 0)       (i64.const 0))

        ;; bigIntSqrt
        (call $i64.testSqrt (local.get 0) (i64.const 123456) (i64.const 351))
        (call $i64.testSqrt (local.get 0) (i64.const 36)     (i64.const 6))
        (call $i64.testSqrt (local.get 0) (i64.const 1)      (i64.const 1))
        (call $i64.testSqrt (local.get 0) (i64.const 64)     (i64.const 8))
        (call $i64.testSqrt (local.get 0) (i64.const 255)    (i64.const 15))

        ;; bigIntAbs
        (call $i64.testAbs (local.get 0) (i64.const 123456)  (i64.const 123456))
        (call $i64.testAbs (local.get 0) (i64.const -123456) (i64.const 123456))
        (call $i64.testAbs (local.get 0) (i64.const 0)       (i64.const 0))

        ;; bigIntSetInt64 / bigIntGetInt64
        (call $i64.testSetGet (local.get 0) (i64.const 123456))        
        (call $i64.testSetGet (local.get 0) (i64.const -123456))
        (call $i64.testSetGet (local.get 0) (i64.const 0))
        (call $i64.testSetGet (local.get 0) (i64.const -9223372036854775808))
        (call $i64.testSetGet (local.get 0) (i64.const 9223372036854775807))
      )
      ;; test bigIntGetInt64 and bigIntSetInt64 host functions using given big int handle
      ;; (call $i64.testSetGet (handle) (given))
      (func $i64.testSetGet (param i32 i64)
        (call $bigIntSetInt64 (local.get 0) (local.get 1))
        (call $bigIntGetInt64 (local.get 0) (local.get 0))
        (call $i64.assertEqual (local.get 1) (call $bigIntGetInt64 (local.get 0)))
      )

      ;; test bigIntSqrt host function using given big int handle
      ;; (call $i64.testSqrt (handle) (given) (expected))
      (func $i64.testSqrt (param i32 i64 i64)
        (call $bigIntSetInt64 (local.get 0) (local.get 1))
        (call $bigIntSqrt (local.get 0) (local.get 0))
        (call $i64.assertEqual (local.get 2) (call $bigIntGetInt64 (local.get 0)))
      )

      ;; test bigIntAbs host function using given big int handle
      ;; (call $i64.testAbs (handle) (given) (expected))
      (func $i64.testAbs (param i32 i64 i64)
        (call $bigIntSetInt64 (local.get 0) (local.get 1))
        (call $bigIntAbs (local.get 0) (local.get 0))
        (call $i64.assertEqual (local.get 2) (call $bigIntGetInt64 (local.get 0)))
      )
      ;; test bigIntNeg host function using given big int handle
      ;; (call $i64.testNeg (handle) (given) (expected))
      (func $i64.testNeg (param i32 i64 i64)
        (call $bigIntSetInt64 (local.get 0) (local.get 1))
        (call $bigIntNeg (local.get 0) (local.get 0))
        (call $i64.assertEqual (local.get 2) (call $bigIntGetInt64 (local.get 0)))
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

      (func (export "argsTest_getArgumentLength_invalidArg_neg")
         (call $getArgumentLength (i32.const -123))
         drop         
      )

      (func (export "argsTest_getArgumentLength_invalidArg_oob")
         (call $getArgumentLength (i32.const 123))
         drop         
      )

      (func (export "argsTest_getArgument_invalidArg_neg")
         (call $getArgument (i32.const -1) (i32.const 32))
         drop         
      )

      (func (export "argsTest_getArgument_invalidArg_oob")
         (call $getArgument (i32.const 123) (i32.const 32))
         drop         
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

      (func (export "test_getESDTTokenName")
         (call $getESDTTokenName (i32.const 0))
         drop         
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
    , ListItem(Int2Bytes(0, BE, Unsigned)) ListItem(Int2Bytes(32, 2 ^Int 256 -Int 1, BE))
    , 0
    , 0
)

checkExpectStatus(OK)
checkExpectOut(ListItem(Int2Bytes(777, BE, Signed)))
checkAccountBalance("testDeployer", 0)

setAccount("testCaller", 0, 0, .Code, .Bytes, .MapBytesToBytes)
setEsdtBalance(b"\"testCaller\"", b"my-tok", 20)
setEsdtBalance(b"\"testCaller\"", b"my-tok-2", 20)

callTx( "testCaller" , "testContract" , 0 , .List
      , "argsTest_getArgumentLength_invalidArg_neg", .ListBytes
      , 0 , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"invalid argument")

callTx( "testCaller" , "testContract" , 0 , .List
      , "argsTest_getArgumentLength_invalidArg_oob", ListItem(b"foo") ListItem(b"bar")
     , 0 , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"invalid argument")

callTx( "testCaller" , "testContract" , 0 , .List
      , "argsTest_getArgument_invalidArg_neg", .ListBytes
      , 0 , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"invalid argument")

callTx( "testCaller" , "testContract" , 0 , .List
      , "argsTest_getArgument_invalidArg_oob", ListItem(b"foo") ListItem(b"bar")
     , 0 , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"invalid argument")

callTx( "testCaller" , "testContract" , 0 , .List
      , "test_getESDTTokenName", .ListBytes
     , 0 , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"invalid token index")

callTx( "testCaller" , "testContract" , 0 ,  ListItem(esdtTransfer(b"my-tok", 10, 0)) ListItem(esdtTransfer(b"my-tok-2", 10, 0))
      , "test_getESDTTokenName", .ListBytes
     , 0 , 0
)

checkExpectStatus(ExecutionFailed)
checkExpectMessage(b"too many ESDT transfers")

setExitCode 0
