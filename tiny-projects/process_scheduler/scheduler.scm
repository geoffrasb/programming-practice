(require-extension defstruct)
(load "help")

(define (rec f g) (set! f g) f)
(define (lrec f base) 
  (rec g (lambda (lst)
            (if (null? lst) 
              base
              (f (car lst) (g (cdr lst)))))))
; interface:
; Apply
; IsEmpty
; RemoveFront -> use kernel->scheduler->getSleepEvent()
; Insert -> check in MLFQ's self if the thread is exist

; Apply : use C++: List.Apply
; IsEmpty : use C++: List.IsEmpty

; threadPool: containing all threads and used for checking existance
;   ops: check, add, extract
;    -> in C++: List.IsInList, Prepend, Remove
;               storing thread* or TID?
;
; ------ types in C++ ------
; ---------------------- scheduler vars ----------
(define threadPool '()) ;:: List<Tuple<Thread*,Silk*>>
(define rawrope '()) ;:: [Silk]
(define plan '()) ;:: [Silk]
(define currentSilk '())
(define insertFlag #f)
(define currentSilkSleep #f)
; ---------------------- scheduler vars --

(define (addThread! TID)
  (set! threadPool (cons TID threadPool)))
(define (existsThread! TID)
    ((lrec (lambda (ca cd)
             (if (= ca TID) #t cd))
           #f)
     threadPool))
(define (extractThread! TID)
  (set! threadPool
      ((lrec (lambda (ca cd)
               (if (= ca TID)
                 cd
                 (cons ca cd)))
             '())
       threadPool)))

(define IsEmpty! (lambda () (null? threadPool)))


; type Silk = (thread burstTime existTime)
(defstruct Silk thread burstTime existTime)

(define (new-Silk trd)
  (make-Silk thread: trd burstTime: 0 existTime: 0))
(define (incBurstTime! silk)
  (Silk-burstTime-set! silk (+ (Silk-burstTime silk) 1)))
(define (incExistTime! silk)
  (Silk-existTime-set! silk (+ (Silk-existTime silk) 1)))

; Insert
(define (Insert thread)
  (if (existsThread! thread)
    '()
    (begin
        (addThread! thread)
        (set! insertFlag #t)
        (set! rawrope (cons (new-Silk thread) rawrope)))))

; type RawRope = [Silk]
; type IdealRope = [(Silk,weight)] ;with ascendent order
; type Plan = [Silk]

(define (evaluateImportance silk)
  (if (= 0 (Silk-burstTime silk))
    1
    (/ (Silk-existTime silk) (Silk-burstTime silk))))

; reWeave :: IdealRope
(define reWeave! ;use "rawrope"
  (lambda ()
      (let ( (sorted_silklst (qsort (lambda (a b) (>= (evaluateImportance a) ;higher the better
                                                   (evaluateImportance b)))
                                 rawrope))
            )
        ((rec f (lambda (lst acc)
                  (if (null? lst) '()
                    (cons (cons (car lst) acc) (f (cdr lst) (+ 1 acc))))))
         sorted_silklst
         1))))

; planTransform! :: IdealRope -> '()
(define (planTransform! idealRope) ;take and setting "plan"
  (let ((newplan 
          (let* ((sum ((lrec (lambda (ca cd) (+ (cdr ca) cd)) 0)
                      idealRope))
                (counts (map (lambda (pair) 
                               (cons (car pair) 
                                     (ceiling (/ sum (cdr pair)))))
                             idealRope))
                (currentCounts (map (lambda (pair) 
                                       (cons (car pair) (cdr pair)))
                                    counts))
                (num 0)
                (result '())
                )
            (do () ((>= num sum) result)
              (set! currentCounts
                  ((lrec (lambda (ca cd) (cons (cons (car ca) (- (cdr ca) 1)) cd))
                         '())
                   currentCounts))
              ;get counts,currentCounts return currentCounts
              (set! currentCounts
                  ((rec f (lambda (ml sl) 
                            (if (or (null? ml) (null? sl))
                              '()
                              (if (<= 0 (cdar sl))
                                (begin
                                  (if (< num sum)
                                      (set! result (cons (caar sl) result)) '())
                                  (set! num (+ 1 num))
                                  (cons (cons (caar sl) (cdar ml)) (f (cdr ml) (cdr sl))))
                                (cons (car sl) (f (cdr ml) (cdr sl)))))))
                   counts 
                   currentCounts))))))
    (set! plan (append plan newplan))))

; RemoveFront 
(define (RemoveFront! sleepSignal)
  (if (or sleepSignal insertFlag)
    (begin
      (if sleepSignal
        (begin (extractThread! (Silk-thread currentSilk))
               (set! rawrope
                   ((lrec (lambda (ca cd)
                            (if (eq? currentSilk ca) cd
                              (cons ca cd)))
                          '())
                    rawrope))
               (set! plan
                   ((lrec (lambda (ca cd)
                            (if (eq? currentSilk ca) cd
                              (cons ca cd)))
                          '())
                    plan))
               (set! currentSilkSleep #f)
               )
        '())
      (if insertFlag (set! insertFlag #f) '())
      (planTransform! (reWeave!)))
    '())
  (begin ;return next thread in plan
    (map (lambda (silk) (incExistTime! silk) '()) rawrope)
    (if (null? plan) 
      (planTransform! (reWeave!)) '())
    (if (null? plan) '()
      (let ((res (car plan)))
        (set! plan (cdr plan))
        (incBurstTime! res)
        (set! currentSilk res)
        (Silk-thread res)
        ))))





; ------------------- simulator -------------------------






