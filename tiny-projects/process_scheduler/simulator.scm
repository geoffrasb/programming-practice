(load "scheduler")

; use interface:
; RemoveFront
; Insert

(define (nlist n len)
  (let ((result '()))
      (do ((x 0 (+ x 1)))
        ((= x len) result)
        (set! result (cons n result)))))

; process representation:
; ex: p1: '(1 . (#f #f #f t t t t)
;       means: start at time 3, length = 4
(define (genproc id start len)
  (cons id (append (nlist #f start) (nlist #t len))))

;(define originProcs '()) ;[(id start . len)]

(define procPool ;:: vector genproc
  (vector
    (genproc 1 3 4)
    (genproc 2 0 6)
  
  ))

(define machinedone #f)
(define sleep #f)
(define nextInsert '())
(define lastrun '(()))
(define scheduleResult '())

(define runmachine
  (lambda ()
    (do () (machinedone 
             (begin
               (set! scheduleResult (cdr (reverse (cdr lastrun))))
               scheduleResult))
        (do ((i 0 (+ i 1)))
          ((= i (vector-length procPool)) '())
          (let ((proc (vector-ref procPool i)))
            (if (not (null? (cdr proc)))
              (cond 
                ((eq? (car lastrun) (car proc))
                    (begin
                        (if (single (cdr proc))
                          (set! sleep #t) '())
                        (vector-set! procPool i (cons (car proc) (cddr proc)))))
                ((not (cadr proc)) (vector-set! procPool i (cons (car proc) (cddr proc))))
                (#t (set! nextInsert (cons (car proc) nextInsert))))
              '())))
        (map (lambda (a) (Insert a) '()) nextInsert)
        (set! nextInsert '())
        (set! lastrun (cons (RemoveFront! sleep) lastrun))
        (set! sleep #f)
        (if (null? (car lastrun))
          (set! machinedone #t)
          '()))))

#|
(define evalAWT ;use scheduleResult and originProcs::[(id start . len)]
  (lambda ()
    (let ((wait_rdy_lst '()))
      (map (lambda (procinfo)
             (let ((id (car procinfo))
                   (start (cadr procinfo))
                   (len (cddr procinfo)))
               |#

; ------ interface -----

