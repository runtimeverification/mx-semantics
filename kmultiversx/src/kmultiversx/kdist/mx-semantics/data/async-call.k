requires "list-bytes.k"

module ASYNC-CALL
  imports private BYTES
  imports private LIST-BYTES
  imports private INT-SYNTAX
  imports private BASIC-K
  imports private STRING

  syntax AsyncCall ::= #asyncCall(
                          dest: Bytes,
                          func: String,
                          args: ListBytes,
                          valueBytes: Bytes,
                          successCallback: String,
                          errorCallback: String,
                          gas: Int,
                          closure: Bytes 
                        )
        [symbol(AsyncCall)]

  syntax AsyncCallStatus ::= "AsyncCallPending"   [symbol(AsyncCallPending)]
                           | "AsyncCallResolved"  [symbol(AsyncCallResolved)]
                           | "AsyncCallRejected"  [symbol(AsyncCallRejected)]

  syntax ListAsyncCall [hook(LIST.List)]
  syntax ListAsyncCall ::= ListAsyncCall ListAsyncCall
          [ left, function, total, hook(LIST.concat),
            symbol(_ListAsyncCall_), smtlib(smt_seq_concat),
            assoc, unit(.ListAsyncCall), element(ListAsyncCallItem),
            format(%1%n%2)
          ]
  syntax ListAsyncCall ::= ".ListAsyncCall"
          [ function, total, hook(LIST.unit), symbol(.ListAsyncCall),
            smtlib(smt_seq_nil)
          ]
  syntax ListAsyncCall ::= ListItem(AsyncCall)
          [ function, total, hook(LIST.element), symbol(ListAsyncCallItem),
            smtlib(smt_seq_elem)
          ]
  syntax AsyncCall ::= ListAsyncCall "[" Int "]"
          [ function, hook(LIST.get), symbol(ListAsyncCall:get) ]
  syntax ListAsyncCall ::= ListAsyncCall "[" index: Int "<-" value: AsyncCall "]"
          [function, hook(LIST.update), symbol(ListAsyncCall:set)]
  syntax ListAsyncCall ::= makeListAsyncCall(length: Int, value: AsyncCall)
          [function, hook(LIST.make)]
  syntax ListAsyncCall ::= updateList(dest: ListAsyncCall, index: Int, src: ListAsyncCall)
          [function, hook(LIST.updateAll)]
  syntax ListAsyncCall ::= fillList(ListAsyncCall, index: Int, length: Int, value: AsyncCall)
          [function, hook(LIST.fill)]
  syntax ListAsyncCall ::= range(ListAsyncCall, fromFront: Int, fromBack: Int)
          [function, hook(LIST.range), symbol(ListAsyncCall:range)]
  syntax Bool ::= AsyncCall "in" ListAsyncCall
          [function, total, hook(LIST.in), symbol(_inListAsyncCall_)]
  syntax Int ::= size(ListAsyncCall)
          [function, total, hook(LIST.size), symbol(sizeListAsyncCall), smtlib(smt_seq_len)]
endmodule
