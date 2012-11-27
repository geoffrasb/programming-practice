
;;; tut from: http://okmij.org/ftp/Scheme/monad-in-Scheme.html
;; Tree node tagging program.
;; We start by defining a datatype for integer-tagged values.

(define (make-numbered-value tag val) (cons tag val))
   ; accessors of the components of the value
(define (nvalue-tag tv) (car tv))
(define (nvalue-val tv) (cdr tv))


;; We need to define a counting monad and its two fundamental operations: `bind`(aka>>=) and `return`.

(define (return val)
  (lambda (curr_counter)
    (make-numbered-value curr_counter val)))

(define (>>= m f)
  (lambda (curr_counter)
    (let* ((m_result (m curr_counter)) ; result of the delayed computation
	   (n1 (nvalue-tag m_result)) ; represented by m
	   (v  (nvalue-val m_result)) ; feed the result to f, get another m1
	   (m1 (f v))
	   )
      (m1 n1)))) ;The result of the bigger monad

(define incr
  (lambda (n)
    (make-numbered-value (+ 1 n) n)))

(define (runM m init-counter)
  (m init-counter))

;;; examples

(define (make-node val kids)
  (>>= incr (lambda (counter)
	      (return (cons (make-numbered-value counter val) kids)))))

(define (build-btree-r depth)
  (if (zero? depth) (make-node depth '())
      (>>=
       (build-btree-r (- depth 1))
       (lambda (left-branch)
	 (>>=
	  (build-btree-r (= depth 1))
	  (lambda (right-branch)
	    (make-node depth (list left-branch right-branch))))))))

(define-syntax letM
  (syntax-rules ()
    ((letM binding exp)
     (apply (lambda (name-val)
	      (apply (lambda (name initializer)
		       `(>>= ,initializer (lambda (,name) ,expr)))
		     name-val))
	    binding))))

(define-syntax letM*
  (syntax-rules ()
    ((letM* bindings expr)
     (if (and (pair? bindings) (pair? (cdr bindings)))
	 `(letM ,(list (car bindings))
		(letM* ,(cdr bindings) ,expr))
	 `(letM ,bindings ,expr)))))

(define (build-btree depth)
  (if (zero? depth) (make-node depth '())
      (letM* ((left-branch (build-btree (- depth 1)))
	      (right-branch (build-btree (- depth 1))))
	     (make-node depth (list left-branch right-branch)))))