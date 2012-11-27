(defun run ()
(let ((ptr (open (make-pathname :name "temp.v") :direction :output)))
    (format ptr 
        (construct-string
            (dotimes (a 128)
                (/format
                    (let ((na (* a 8)))
                        (conf-incase
                            :value (format-string "10'd~A" na)
                            :block (format-string "result = vector[~A:~A];" na (+ na 7))))))))
    (close ptr)))
