(load "mylib")


(defun seti ()
  (setf i (list 
            (open (make-pathname :name "i1.txt") :direction :input)
            (open (make-pathname :name "i2.txt") :direction :input))))
(defun seto ()
  (setf o (list 
            (open (make-pathname :name "o1.txt") :direction :output :if-exists :supersede)
            (open (make-pathname :name "o2.txt") :direction :output :if-exists :supersede))))
(defun closei ()
  (mapcar #'close i))
(defun closeo ()
  (mapcar #'close o))


(setf stm 
    '(+ 
        (-  ("A" "=" "B") 
            (+  ("B" "==" "C")
                ("T" "<" "T")))
        (*  ("D" ">" "E")
            ("G" "<=" "F"))))


(defun csttrav (tree)
    (if (stringp (car tree))
        (list tree)
        (let (
                (l (csttrav (cadr tree)))
                (r (csttrav (caddr tree))))
            (append l r))))

#|
0:511 vector
4bit setting
reg 0:511result
case (selector)
    10'd4:
        result = {vector[0:3],setting,vecotr[8:511]}
        |#

(defun run ()
    (let ((strm (open (make-pathname :name "temp") :direction :output :if-exists :supersede)))
        (format strm
        (conf-case
            :variable "selector"
            :incases
            (construct-string
                (dotimes (a 64)
                    (/format
                    (conf-incase
                        :value (format-string "9'd~A" (* a 8))
                        :block (format-string "result = {vector[0:~A],setting,vector[~A:511]};" (1- (* 8 a)) (+ 8 (* 8 a)))))))))
        (close strm)))

