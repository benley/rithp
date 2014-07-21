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

  (display (f (lambda (x) x)))  ; Should output 1
  (display (call/cc f))         ; Should output 2

  ; Variadic operators:
  (display (+ 1 2 3 4 5 6 (- 7 8 9 10)))
  (display (list "2^8 ==" (* 2 2 2 2 2 2 2 2))) ; 256

  ; an indented comment
  (display "hi") ; an inline comment with '"'\\\";;;'"obnoxious punctuation'!@#
  (display (list "foo" "bar" 23 "hi"))
  (display (list "Empty: list" (list)))

  (define foo "I work with actual strings now!!!") ; Simple assignment
  (display foo)
  (define foo "bar\"quoooo;ote\"'derp'''derp'quotes\'")      ; Reassign
  (display foo)

  (if (= 1 2 3 4)
    (display "HURRRRR FAIL"))
  (if (= 1 1 1 1)
    (display "OK"))

  (display (list "True:" #t "False" #f))
  foo
  )
