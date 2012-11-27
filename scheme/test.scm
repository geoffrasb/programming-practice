(load "utils")

(define (solv lh-exp rh-exp)
  (solve (funcify lh-exp) (funcify rh-exp)))

