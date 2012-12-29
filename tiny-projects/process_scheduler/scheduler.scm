#|
process launching description:
    ( (enter-time . length) )

process config description:
    ( (times (proc . weight) ...) ;overlapping
      or 
      (times proc) )              ;only one thread
|#

(define (run-machine procs scheduler)

(define (AWT proc-config)
