
(load "utils")

(define (memoize fn)
  (let ((cache (make-1d-table)))
    (lambda (arg)
      (1d-table/lookup cache arg
               (lambda (val) val)
               (lambda ()
             (let ((res (fn arg)))
               (1d-table/put! cache arg res)
               res))))))

(define gen-f
  (lambda (r n0)
    (rec f (memoize (lambda (n) 
                      (if (= n 0) n0 
                          (* r 
                             (f (- n 1))
                             (- (f (- n 1)) 1))))))))

(define (run out-file-name r n0 times)
  (let ((f (gen-f r n0))
        (out (open-output-file out-file-name))
        )
    (do ((i 0 (1+ i)))
      ((= i times) (close-port out))
      (pp (f i) out))))
