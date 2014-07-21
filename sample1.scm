; some rithp demo code

(begin

  (define fact
    (lambda (n)
      (begin
        (if (<= n 1) 1
          (* n (fact (- n 1)))))))

  (display (fact 9))

  ; Test callcc
  (define f
    (lambda (return) (begin (return 2) 1)))

  (display (f (lambda (x) x))) ; Should output 1
  (display (callcc f))         ; Should output 2

  (display (+ 1 2 3 4 5 6
              (- 7 8 9 10)))   ; Variadic operators
  (display (list "2^8 == " (* 2 2 2 2 2 2 2 2))) ; 256

  ; an indented comment
  (display "hi") ; an inline comment
  (display (list "foo" "bar" 23 "hi"))
  (display (list "Empty: list" (list)))

  (define foo "I work with actual strings now!!!") ; Simple assignment
  (display foo)
  (define foo "bar\"quoooo;ote\"'derp'''derp'quotes\'")      ; Reassign
  (display foo)
  foo
  )