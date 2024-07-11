# Switch

The MultiversX node operates with two main cells: `<commands>` for VM commands
and `<instrs>` for Wasm instructions. Execution begins with `<commands>`; and when a
contract is invoked, control switches to `<instrs>` for the contract's Wasm code.
If the contract execution concludes or encounters a failure, the control returns to `<commands>`.
Additionally, certain host functions, such as token transfers and contract-to-contract calls, 
necessitate command execution. In these cases, control temporarily shifts to <commands> until
these operations are completed.
To implement synchronization between the `<commands>` and `<instrs>` cells, `#endWasm`, `#waitWasm`,
and `#waitCommands` statements are utilized.

```k
requires "elrond-node.md"

module SWITCH-SYNTAX

    syntax InternalCmd ::= "#endWasm"     [symbol(#endWasm)]
                         | "#waitWasm"    [symbol(#waitWasm)]
                         | "#setVMOutput" [symbol(#setVMOutput)]

    syntax InternalInstr ::= "#waitCommands"    [symbol(#waitCommands)]

endmodule

module SWITCH
    imports SWITCH-SYNTAX
    imports ASYNC-HELPERS
    imports ELROND-NODE
```

- `#endWasm` marks the end of the execution of Wasm instructions within a contract call.
  It creates the `VMOutput` for the current contract call and initiates the context switch
  from the current call to its parent call. 

```k
    rule [endWasm]:
        <commands> #endWasm 
                => #asyncExecute
                ~> #setVMOutput
                ~> popCallState
                ~> dropWorldState
                   ...
        </commands>
        <instrs> .K </instrs>
      [priority(60)]

    rule [setVMOutput]:
        <commands> #setVMOutput => .K ... </commands>
        <out> OUT </out>
        <logs> LOGS </logs>
        <outputAccounts> OUT_ACCS </outputAccounts>
        <vmOutput> _ => VMOutput(OK , .Bytes , OUT , LOGS , OUT_ACCS) </vmOutput>
      [priority(60)]

```

- `#waitWasm` is used after the `newWasmInstance` command to wait for the
  completion of the Wasm module initialization. Unlike #endWasm, it doesn't manipulate the VM output
  or call stack; it simply waits for the VM to finish its execution.

```k
    rule [waitWasm]:
        <commands> #waitWasm => .K ... </commands>
        <instrs> .K </instrs>
      [priority(60)]
```

- `#waitCommands` is utilized when an instruction initiates a command. Placed in front of the `<instrs>` cell,
  it directs execution to continue from the `<commands>` cell until an `#endWasm` command is encountered.

```k
    rule [waitCommands]:
        <instrs> #waitCommands => .K ... </instrs>
        <commands> #endWasm ... </commands>
      [priority(200)]
```

```k
endmodule
```
