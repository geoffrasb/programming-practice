(define-syntax rec
  (syntax-rules ()
    ((rec x v)
     (letrec ((x v)) x))))

(define (1- x) (- x 1))
(define (1+ x) (+ x 1))
(define (call/cc a) (call-with-current-continuation a))

(define gensym generate-uninterned-symbol)


(define (identity x) x)

#| original Y combinator
(define (Y f)
  (f (lambda (x) ((Y f) x))))
|#
(define (Y f)
  (letrec ((i-Y (lambda (f)
                  (f (lambda x (apply (i-Y f) x))))))
    (i-Y f)))
      
(define (memoize fn)
  (let ((cache (make-1d-table)))
    (lambda (arg)
      (1d-table/lookup cache arg
               (lambda (val) val)
               (lambda ()
                 (let ((res (fn arg)))
                   (1d-table/put! cache arg res)
                   res))))))

(define fib (memoize
                  (lambda (n)
                    (if (or (= 0 n) (= 1 n)) 1
                        (+ (fib (- n 1)) (fib (- n 2)))))))
