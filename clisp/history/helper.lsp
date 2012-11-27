
; for this kind of list: (label el1 el2...)
(defun label-of (lst) (car lst))
(defun find-label (label l-lists)
  (cdr (find-if (lambda (lst) (eql label (car lst)))
                l-lists)))
;(get (get obj 'a) 'b)
;(getchain obj 'a 'b)
(defmacro getchain (symlist)
  (if (null symlist)
    nil
    (if (single symlist)
      (car symlist)
      (reduce (lambda (a b)
                `(get ,a ,b))
              symlist))))

(defun map-symbol-plist (f sym)
  (let* ((plst (symbol-plist sym))
        (keys (funcall (bat-lrec (lambda (a b f) (cons a (funcall f))) :chunk 2)
                       plst))
        (vals (funcall (bat-lrec (lambda (a b f) (cons b (funcall f))) :chunk 2)
                       plst)))
    (mapcar f keys vals)))

(defmacro add-to-list (a lst)
  `(setf ,lst (cons ,a ,lst)))

(defun dec-bin (dec)
    (reverse (_dec-bin dec)))
(defun _dec-bin (dec)
    (if (<= dec 1)
        (list dec)
        (cons (mod dec 2)
            (_dec-bin (floor (/ dec 2))))))




