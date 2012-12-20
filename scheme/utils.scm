(define-syntax rec
  (syntax-rules ()
    ((rec x v)
     (letrec ((x v)) x))))

(define (1- x) (- x 1))
(define (1+ x) (+ x 1))
(define (call/cc a) (call-with-current-continuation a))

(define gensym generate-uninterned-symbol)


(define (identity x) x)
(define (single a) (if ((and (list? a) (= 1 (length a))) #t #f))
(define (zipwith f lst1 lst2)
  (if (or (null? lst1)
          (null? lst2))
    '()
    (cons (f (car lst1) (car lst2)) (zipwith f (cdr lst1) (cdr lst2)))))

#| original Y combinator
(define (Y f)
  (f (lambda (x) ((Y f) x))))
|#
(define (Y f)
  (letrec ((i-Y (lambda (f)
                  (f (lambda x (apply (i-Y f) x))))))
    (i-Y f)))

(define (DFS f expander . base)
  (letrec ((self (lambda (curr_state)
                     (f curr_state (let ((expansion (map (lambda (x) (lambda () (self x)))
                                                         (expander curr_state))))
                                     (if (null? expansion) 
                                       (if (null? base) '() (car base))
                                       expansion))))))
    self))

(define (BFS f expander . base)
  (letrec ((self (lambda (states)
                   (if (list? states)
                     (if (null? states)
                       (if (null? base) '() (car base))
                       (f states (lambda () 
                                   (self (flatten-1 (map (lambda (x) (expander x))
                                                      states))))))
                       (self (list states))))))
    self))



; experimental area ---------------------------------
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
