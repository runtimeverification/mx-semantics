(module
  (func (export "func1") (result i32)
    (block (result i32)
      (i32.const 10) 
      (if (result i32)
        (then
          (block (result i32) 
            (i32.const 2)
          )
        )
        (else
          (block (result i32)
            (i32.const 3)
          )
        )
      )
    )
  )

  (func (export "init"))
  (func (export "func2"))
)
