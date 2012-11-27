(load "mylib")
(setf l '(1 (2 3) (4 (5 (6 7) 8)) 9 10))


(defun run(lst)
    (funcall
        (trec
            (lambda (tree tcar tcdr)
                (princ tree)
                (format t "~%")
                (if (single tree)
                    (funcall tcar)
                    (+ (funcall tcar)
                        (funcall tcdr)))))
        lst))
