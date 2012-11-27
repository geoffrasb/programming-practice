;find2,before,after,duplicate,split-if (p50
;most,best,mostn (p52
;readlist,prompt,break-loop (p56
;mkstr,symb,reread,explode (p58
;rfind-if (p73

(proclaim '(
  ;simple utils{{{
  take ;n list    -> construct a new list with first n items of list.
  ifnot ;         -> just like if, for some convenience.
  last1 ;lst      -> take out the car of last one
  append1 conc1 mklist zip 
  ;}}}
  ;map functions{{{
  map0-n map1-n mapa-b map-> mappend mapcars rmapcar
  mapcar-r
  ;}}}
  ;tree,list traverse function factory{{{
  trec ttrav n-ary-trec 
  lrec ltrav bat-lrec 
  ;}}}
  fif fint fun compose 
  disjoin conjoin curry rcurry single 
  zip-map
  self-lambda
  format-string
  construct-string
;memoize (p65
;longer,filter,group (p47
;flatten,prune (p49
))

;rev-mapcar -- many function map to one expression
;bi-map -- many function map to many exp, which every exp has just a little difference
;   -> may be zip-map functions and map-generated-exps

;(defmacro labels*

;downhere has updated to gist

(defun memoize (fn)
    (let ((cache (make-hash-table :test #'equal)))
        (lambda (&rest args)
            (multiple-value-bind (val win) (gethash args cache)
                (if win
                    val
                    (setf (gethash args cache)
                        (apply fn args)))))))

(defun flatten (x)
    (labels ((rec (x acc)
                (cond ((null x) acc)
                    ((atom x) (cons x acc))
                    (t (rec (car x) (rec (cdr x) acc))))))
        (rec x nil)))

(defun prune (test tree)
    (labels ((rec (tree acc)
                (cond ((null tree) (nreverse acc))
                    ((consp (car tree))
                        (rec (cdr tree)
                            (cons (rec (car tree) nil) acc)))
                    (t (rec (cdr tree)
                            (if (funcall test (car tree))
                                acc
                                (cons (car tree) acc)))))))
        (rec tree nil)))

(defun longer (x y)
    (labels ((compare (x y)
                (and (consp x)
                    (or (null y)
                        (compare (cdr x) (cdr y))))))
        (if (and (listp x) (listp y))
            (compare x y)
            (> (length x) (length y)))))

(defun filter (fn lst)
    (let ((acc nil))
        (dolist (x lst)
            (let ((val (funcall fn x)))
                (if val (push val acc))))
        (nreverse acc)))

(defun group (source n)
    (if (zerop n) (error "zero length of group"))
    (labels ((rec (source acc)
                (let ((rest (nthcdr n source)))
                    (if (consp rest)
                        (rec rest (cons (subseq source 0 n) acc))
                        (nreverse (cons source acc))))))
        (if source (rec source nil) nil)))

(defmacro construct-string (&body body) ;use /format function in body to push string to stream
    (let* (
            (fmt (gensym))
            (res (gensym))
            (newbody 
                (funcall
                    (trec 
                        (lambda (tree a r)
                            (cond
                                ((eql (car tree) 'construct-string)
                                    tree)
                                ((eql (car tree) '/format)
                                    (append `(format ,fmt) (cdr tree)))
                                (t (cons (funcall a) (funcall r))))))
                    body)))
        `(let (  (,fmt (make-string-output-stream))
                (,res ""))
            ,@newbody
            (setf ,res (get-output-stream-string ,fmt))
            (close ,fmt)
            ,res)))

(defun format-string (format &rest args)
    (let (
            (result "")
            (buffer (make-string-output-stream)))
        (apply #'format (cons buffer (cons format args)))
        (setf result (get-output-stream-string buffer))
        (close buffer)
        result))

(defmacro mapcar-r (stm fn)
  `(mapcar ,fn ,stm))

(defun map0-n (fn n)
  (mapa-b fn 1 n))
(defun map1-n (fn n)
  (mapa-b fn 1 n))
(defun mapa-b (fn a b &optional (step 1))
  (do ((i a (+ i step))
       (result nil))
    ((> i b) (nreverse result))
    (push (funcall fn i) result)))
(defun map-> (fn start test-fn succ-fn)
  (do ((i start (funcall succ-fn i))
       (result nil))
    ((funcall test-fn i) (nreverse result))
    (push (funcall fn i) result)))

(defun mapcars (fn &rest lsts)
  (let ((result nil))
    (dolist (lst lists)
      (dolist (obj lst)
        (push (funcall fn obj) result)))
    (nreverse result)))
(defun rmapcar (fn &rest args)
  (if (some #'atom args)
    (apply fn args)
    (apply #'mapcar
      (lambda (&rest args)
        (apply #'rmapcar fn args))
      args)))

(defun take (n lst)
  (if (or (<= n 0) (null lst))
    nil
    (cons (car lst) 
      (take (- n 1)
        (if (cdr lst) (cdr lst))))))

(defun trec (rec &optional (base #'identity))
  (labels
    ((self (tree)
      (if (atom tree)
        (if (functionp base)
          (funcall base tree)
          base)
        (funcall rec tree
          (lambda () (self (car tree)))
          (lambda ()
            (if (cdr tree)
              (self (cdr tree))))))))
    #'self))
(defun ttrav (rec &optional (base #'identity))
  (labels ((self (tree)
            (if (atom tree)
                (if (functionp base)
                  (funcall base tree)
                  base)
                (funcall rec (self (car tree))
                             (if (cdr tree)
                                (self (cdr tree)))))))
    #'self))
(defun n-ary-trec (rec &key (base #'identity) (n 1))
  (labels 
    ((self (tree)
      (if 
        (or (atom tree)
          (< (list-length tree) n))
        (if (functionp base)
          (funcall base tree)
          base)
        (let* (
            (els (take n tree))
            (recfs 
              (mapcar (lambda (node) (lambda () (self node)))
                els)))
          (apply rec 
            (mapcar #'cons els recfs))))))
    #'self))

(defun lrec (rec &optional base)
  (labels ((self (lst)
            (if (null lst)
                (if (functionp base)
                    (funcall base)
                    base)
                (funcall rec (car lst)
                             #'(lambda () (self (cdr lst)))))))
    #'self))
(defun ltrav (rec &optional base)
  (labels ((self (lst)
            (if (null lst)
                (if (functionp base)
                    (funcall base)
                    base)
                (funcall rec (car lst)
                             (self (cdr lst))))))
    #'self))
(defun bat-lrec (recf &key (base nil) (chunk 1))
  (labels ((self (lst)
    (if (< (list-length lst) chunk)
        (if (functionp base)
            (funcall base)
            base)
           (apply recf (append
                           (take chunk lst)
                           `(,(lambda ()
                                (self (nthcdr chunk lst)))))))))
    #'self))


(defmacro ifnot (p fstm &optional tstm)
  (if tstm
    `(if (not ,p) ,fstm ,tstm)
    `(if (not ,p) ,fstm)))

(defun fif (if then &optional else)
  #'(lambda (x)
      (if (funcall if x)
          (funcall then x)
          (if else (funcall else x)))))
(defun fint (fn &rest fns)
  (if (null fns)
      fn
      (let ((chain (apply #'fint fns)))
        #'(lambda (x)
            (and (funcall fn x) (funcall chain x))))))
(defun fun (fn &rest fns)
  (if (null fns)
      fn
      (let ((chain (apply #'fun fns)))
        #'(lambda (x)
            (or (funcall fn x) (funcall chain x))))))


(defun compose (&rest fns)
  (destructuring-bind (fn1 . rest) (reverse fns)
      #'(lambda (&rest args)
            (reduce #'(lambda (v f) (funcall f v))
                    rest
                    :initial-value (apply fn1 args)))))
(defun disjoin (fn &rest fns)
  (if (null fns)
    fn
    (let ((disj (apply #'disjoin fns)))
      #'(lambda (&rest args)
          (or (apply fn args) (apply disj args))))))
(defun conjoin (fn &rest fns)
  (if (null fns)
      fn
      (let ((conj (apply #'conjoin fns)))
            #'(lambda (&rest args)
                (and (apply fn args) (apply conj args))))))
(defun curry (fn &rest args)
  #'(lambda (&rest args2)
      (apply fn (append args args2))))
(defun rcurry (fn &rest args)
  #'(lambda (&rest args2)
      (apply fn (append args2 args))))
      (defun always (x) #'(lambda (&rest args) x))

(defun single (lst)
  (cond
    ((not (listp lst)) nil)
    ((null lst) nil)
    ((null (cdr lst)) t)))

(defun last1 (lst)
  (car (last lst)))
(defun append1 (lst obj)
  (append lst (list obj)))
(defun conc1 (lst obj)
  (nconc lst (list obj)))
(defun mklist (obj)
  (if (listp obj) obj (list obj)))

(defun zip (lst1 lst2)
  (mapcar #'list lst1 lst2))

(defun zip-map (flst elst)
  (if (or (null flst) (null elst))
    nil
    (cons (funcall (car flst) (car elst))
          (zip-map (cdr flst) (cdr elst)))))

(defmacro self-lambda (param-lst &rest body)
  (let ((fn (gensym)))
    (labels ((replace-self (lst) ;replace "self" to "funcall fn fn"
                (cond
                  ((null lst) nil)
                  ((not (listp lst)) lst)
                  ((eql (car lst) 'self)
                      (append `(funcall ,fn ,fn) (replace-self (cdr lst))))
                  ((listp (car lst)) 
                      (cons (replace-self (car lst)) (replace-self (cdr lst))))
                  (t
                      (cons (car lst) (replace-self (cdr lst)))))))
      (let ((new-param '()) (param-length (list-length param-lst)))
        (do ((i 0 (+ i 1)))
          ((= i param-length) nil)
          (setf new-param (cons (gensym) new-param)))
        `(lambda (,@new-param)
           (labels ((lmbd (,fn ,@param-lst) 
                         ,@(mapcar #'replace-self body))) 
             (funcall #'lmbd #'lmbd ,@new-param)))))))
