;bug to fix: aux_sig_next should be set to 0 at default state


(setf smdl
(quote
;-----------write SMDL here and command (compile-it "filename")----------------------------
;this is and example
  (state-machine
    (clock "clk")
    (init-state A)
    (triggerd
      ("tri"
        "n_sig1" "n_sig2"))
    (state
      (default
        (sync-var ("var1" "0"))
        (reg ("var3" "0")))
      (A 
        (sync-var ("var1" "val1")
                   (("a" "==" "b") 
                    ("var2" "val2")
                    ("var1" "1'b0"))))
      (B 
        (sync-var ("var1" "val2"))
        (reg ("var3" "val1"))))
    (trans-func
      ((A (and      ;"and or not" are available
            (or 
              ("a" "==" "b") 
              ("b" "==" "1'b0"))
            ("a" "<" "4'd9")))
       (B "sig1"))
      ((A ("a" "==" "b"))
       (B "sig3"))
      ((A)
       (A))
      ((B )
       (A "sig2"))))
;----------------------------------------------------------------------------------------
))

(load "helper")
(load "mylib")

(defun compile-it (outputfile)
    (compile-smdl smdl outputfile))

;trans-func and state-machine struct definition
;{{{
(defstruct (trans-func
              (:conc-name tf-)
           )
  state
  constraints
  next-state
  signals
 )
(defstruct (state-machine
              (:conc-name sm-)
            )
  clk         ; string         : just a name of clock signal
  allvar      ; list of string : sources to use
  src-out     ; list of string : sources that generate
  signals     ; list of string : prefix "aux_"
              ;       as the variable used in state-conf
  triggered
  state-vars  ; list of string
  states      ; list of symbol
  init-state  ; initial state
  (state-confs
    ((lambda ()
      (let ((s (gensym)))
        (setf (get s 'state-var) (gensym))
        (setf (get s 'src-out) (gensym))
        s))))
  trans-funcs; list of transition function, 
  )
;}}}

(defun compile-smdl (smdlcode outputfile)
  (let ((ostrm (open (make-pathname :name outputfile) 
                      :direction :output
                      :if-exists :supersede)))
  (gen-verilog (read-state-machine smdlcode)
               ostrm)
  (close ostrm)))
  

;{{{ read-state-machine:state-machine
(defun read-state-machine (lst)
  (let ((ele-labels (mapcar (lambda (el) (car el)) (cdr lst))))
      (ifnot (member 'clock ele-labels) (progn (format t "clock didn't declare.") (abort)))
      (ifnot (member 'init-state ele-labels) (progn (format t "init-state didn't declare.") (abort)))
      (ifnot (member 'state ele-labels) (progn (format t "state didn't declare.") (abort)))
      (ifnot (member 'trans-func ele-labels) (progn (format t "trans-func didn't declare.") (abort))))
  (let ((new-sm (make-state-machine)))
    (ifnot (eql (car lst) 'state-machine)
      (format t "Start of the definition should be \"state-machine\".")
      (mapcar (curry #'recog-element new-sm) (cdr lst)))
    (search-src new-sm)
    new-sm))

;{{{ recog-element
(defun recog-element (new-sm element)
  (ifnot (cond
          ((eql (car element) 'clock) 
            (setf (sm-clk new-sm) (cadr element))
            t)
          ((eql (car element) 'init-state) 
            (setf (sm-init-state new-sm) (cadr element))
            t)
          ((eql (car element) 'triggerd) 
            (setf (sm-triggered new-sm) (cdr element))
            t)
          ((eql (car element) 'state)
            (mapcar (curry #'add-states new-sm) (cdr element))
            t)
          ((eql (car element) 'trans-func)
            (mapcar (curry #'add-trans-func new-sm) (cdr element))
            t))
        (format t "Undefined element ~A." (car element))
        t))

;{{{ add-states
(defun add-states (new-sm state)
  (let* ((state-lst (cdr state))
         (state-name (car state))
         (state-var-conf (or 
                            (find-label 'state-var state-lst)
                            (find-label 'sync-var state-lst)))
         (src-out (or 
                    (find-label 'src-out state-lst)
                    (find-label 'reg state-lst))))
  (if (find state-name (sm-states new-sm))
      (format t "State ~A has defined, later configuration  will not be used." state-name)
      (progn
        (setf (sm-states new-sm) (cons state-name (sm-states new-sm)))
        (setf (get (get (sm-state-confs new-sm) 'state-var) state-name)
              state-var-conf)
        (setf (get (get (sm-state-confs new-sm) 'src-out) state-name)
              src-out)
        t))))
;}}}

;{{{ add-trans-func
(defun add-trans-func (new-sm transfunc)
  (setf (sm-trans-funcs new-sm) (cons (make-trans-func
                                          :state (caar transfunc)
                                          :constraints (cadar transfunc)
                                          :next-state (caadr transfunc)
                                          :signals (cdadr transfunc))
                                      (sm-trans-funcs new-sm))))
;}}}

;}}}

;{{{ search-src
(defun search-src (sm)
  ; pattern:
    ;Put each string of ("s1" "s2") to the different hash-table if it doesn't 
    ;exists in that table.
    ;Additionally, the second string should start with alphabet.
  (declare (special sm))
  (labels ((pattern (str-tuple list1 list2)
              (declare (special sm))
              (let ((fst (car str-tuple))
                    (sec (cadr str-tuple)))
                (if (find-if (curry #'string-equal fst)
                             (eval list1))
                  nil
                  (eval `(add-to-list ,fst ,list1)))
                (if (and
                      (alpha-char-p (char sec 0))
                      (null (find-if (curry #'string-equal sec)
                                     (eval list2))))
                  (eval `(add-to-list ,sec ,list2))
                  nil))))
  ;process on sm.state-confs.state-var (sync)
    (map-symbol-plist (lambda (_state sv-confs)
                        (mapcar (rcurry (rcurry #'pattern '(sm-allvar sm)) '(sm-state-vars sm))
                                (filter
                                    (lambda (conf)
                                        (if (stringp (car conf))
                                            conf
                                            (cadr conf)))
                                    sv-confs)))
                      (getchain ((sm-state-confs sm) 'state-var)))
  ;process on sm.state-confs.src-out (reg)
    (map-symbol-plist (lambda (_state sv-confs)
                        (mapcar (rcurry (rcurry #'pattern '(sm-allvar sm)) '(sm-src-out sm))
                                sv-confs))
                      (getchain ((sm-state-confs sm) 'src-out)))
  ;process on sm.trans-funcs
    (mapcar (rcurry (rcurry #'pattern '(sm-allvar sm)) '(sm-allvar sm))
      (funcall 
        (lrec (lambda (l f) (append l (funcall f))))
        (mapcar-r
          (filter 
            (lambda (tf) (if (tf-constraints tf) tf))
            (sm-trans-funcs sm))
          (lambda (tf)
              (funcall
                  (self-lambda (tree)
                    (if (stringp (car tree))
                        (list tree)
                        (let (
                                (l (self (cadr tree)))
                                (r (self (caddr tree))))
                            (append l r))))
                  (tf-constraints tf))))))
              
  ;process on signals
    (mapcar (lambda (tf) 
              (mapcar (lambda (sig)
                        (if (find-if (curry #'string-equal sig)
                                     (sm-signals sm))
                          nil
                          (add-to-list sig (sm-signals sm))))
                      (tf-signals tf)))
            (sm-trans-funcs sm))))
;}}}
;}}}

;{{{gen-verilog

(defun gen-verilog (sm strm)
    (format strm "//----------------code generated by SMDL compiler----------------------~%")
    (format strm "YOU STILL HAVE TO CONFIGURE COMMENTED VARIABLES.~%")

    ;variable declarations
    (format strm "~%// variables(RHS) used:~%")
    (format strm
        (construct-string
            (mapcar (lambda (var) (/format "//~A~%" var))
                (sm-allvar sm))))
    (format strm "~%// registers:~%")
    (format strm
        (construct-string
            (mapcar (lambda (so) (/format "//reg ~A;~%" so))
                (sm-src-out sm))))
    (format strm "~%// synchronous variables:~%")
    (format strm
        (construct-string
            (mapcar (lambda (sv) (/format "//reg ~A,~A_next;~%" sv sv))
                (sm-state-vars sm))))
    (if (sm-triggered sm)
        (progn
            (format strm "~%// triggered source:~%")
            (format strm
                (construct-string
                    (mapcar-r (sm-triggered sm)
                        (lambda (tri)
                            (mapcar-r (cdr tri)
                                (lambda (src)
                                    (/format "reg ~A,~A_next;~%" src src)))))))
            (mapcar-r (sm-triggered sm)
                (lambda (tri)
                    (format strm
                        (conf-alwaysblock
                            :detect (car tri)
                            :block
                            (construct-string
                                (mapcar-r (cdr tri)
                                    (lambda (src)
                                        (/format "~A_next = 1'b1;~%" src))))))))
            (format strm 
                (conf-alwaysblock
                    :detect (sm-clk sm)
                    :block
                    (construct-string
                        (mapcar-r (sm-triggered sm)
                            (lambda (tri)
                                (mapcar-r (cdr tri)
                                    (lambda (src)
                                        (/format "~A = ~A_next;~%" src src))))))))))
    (format strm "~%// state definition~%")
    (let* (
            (states 
                (filter (lambda (x) (if (not (eql x 'default)) x))
                    (sm-states sm)))
            (st-num (list-length states))
            (digit (list-length (dec-bin st-num))))
        (format strm "    reg ~A_state,_state_next;~%" 
            (if (= digit 1) 
                "" 
                (format-string "[~A:0]" (1- digit))))
        (format strm "    parameter ")
        (format strm 
            (construct-string
                (dotimes (c st-num)
                    (if (< c (1- st-num))
                        (/format "~A = ~A'd~A,~%              "
                            (symbol-name (car states)) digit c)
                        (/format "~A = ~A'd~A;~%"
                            (symbol-name (car states)) digit c))
                    (setf states (cdr states))))))
    (if (sm-signals sm)
    (progn
        (format strm "~%//signals~%")
        (format strm 
            (construct-string
                (mapcar
                    (lambda (sig)
                        (/format "    wire ~A;~%" sig sig)
                        (/format "    reg aux_~A,aux_~A_next = 0;~%" sig sig))
                    (sm-signals sm))))
        (format strm
            (construct-string
                (mapcar 
                    (lambda (sig)
                        (/format "    assign ~A = ~A & aux_~A;~%"
                            sig (sm-clk sm) sig))
                    (sm-signals sm))))))
    (terpri strm)
    (terpri strm)

    ;trigger
    (format strm
        (verilog-printer
            :indent 4
            :contents
            (conf-alwaysblock
                :detect (concatenate 'string "posedge " (sm-clk sm))
                :block
                (concatenate 'string
                    (apply #'format-string 
                        (cons ;generate format like "~A~%~A~%..."
                            (construct-string
                                (dotimes (c (list-length (sm-state-vars sm)))
                                    (/format "~~A~~%")))
                            (mapcar-r
                                (sm-state-vars sm)
                                (lambda (sv) (concatenate 'string sv " <= " sv "_next;")))))
                    (apply #'format-string 
                        (cons ;generate format like "~A~%~A~%..."
                            (construct-string
                                (dotimes (c (list-length (sm-signals sm)))
                                    (/format "~~A~~%")))
                            (mapcar-r
                                (sm-signals sm)
                                (lambda (sig) (format-string "aux_~A <= aux_~A_next;" sig sig)))))
                    "_state <= _state_next;"))))
    (terpri strm)
    (terpri strm)

    ;state configure
    (format strm
        (verilog-printer
            :indent 4
            :contents
            (conf-alwaysblock
                :block
                (labels (
                        (modify-state-vars (conf-pairs) ;change ("stt1" "val") to ("stt1_next" "val")
                            (funcall
                                (lrec (lambda (a r) 
                                    (cons 
                                        (cons (concatenate 'string (car a) "_next") (cdr a))
                                        (funcall r))))
                                conf-pairs))
                        (print-pairs (pair-lst)
                            (construct-string
                                (mapcar 
                                    (lambda (pair)
                                        (/format "~A = ~A;~%" (car pair) (cadr pair)))
                                    pair-lst)))
                        (gen-cststring (cst)
                            (funcall 
                                (trec
                                    (lambda (tree a d)
                                        (cond 
                                            ((stringp (first tree))
                                                (format-string "(~A~A~A)" 
                                                    (first tree) (second tree) (third tree)))
                                            ((eql (first tree) 'and)
                                                (let* ((r (funcall d)))
                                                    (format-string "(~A && ~A)" (first r) (second r))))
                                            ((eql (first tree) 'or)
                                                (let* ((r (funcall d)))
                                                    (format-string "(~A || ~A)" (first r) (second r))))
                                            ((eql (first tree) 'not)
                                                (format-string "(!~A)" (first (funcall d))))
                                            ((listp (car tree))  (cons (funcall a) (funcall d)))
                                            (t (format t "unknown logical operator ~A" (symbol-name (car tree))) (abort)))))
                                cst)))
                    (let* (
                            (stt-confs (sm-state-confs sm))
                            (configuration
                                (conf-case
                                    :variable "_state"
                                    :incases
                                    (construct-string
                                        (mapcar-r 
                                            (filter (lambda (stt) (if (not (eql stt 'default)) stt))
                                                (sm-states sm))
                                            (lambda (stt)
                                                (/format (conf-incase
                                                    :value (symbol-name stt)
                                                    :block 
                                                    (concatenate 'string
                                                        ;(print-pairs (modify-state-vars (getchain (stt-confs 'state-var stt))))
                                                        (construct-string
                                                            (mapcar-r (getchain (stt-confs 'state-var stt))
                                                                (lambda (conf)
                                                                    (if (stringp (car conf))
                                                                        (/format "~A_next = ~A;~%" (car conf) (cadr conf))
                                                                        (/format (concatenate 'string
                                                                            (conf-if
                                                                                :constraints (gen-cststring (car conf))
                                                                                :if-block 
                                                                                (construct-string
                                                                                    (mapcar-r (cdr conf)
                                                                                        (lambda (setting)
                                                                                            (/format "~A_next = ~A;~%" (car setting) (cadr setting))))))
                                                                            (format-string "~%")))))))
                                                        (print-pairs (getchain (stt-confs 'src-out stt)))
                                                        ;state and signals configuration
                                                        (let* (
                                                                (tfs-of-stt ;with no no-constraint transition
                                                                    (filter
                                                                        (lambda (a) 
                                                                            (if (and
                                                                                    (eql (tf-state a) stt)
                                                                                    (tf-constraints a))
                                                                                a))
                                                                        (sm-trans-funcs sm)))
                                                                (no-cst 
                                                                    (car 
                                                                        (filter 
                                                                            (lambda (a)
                                                                                (if (and
                                                                                        (eql (tf-state a) stt)
                                                                                        (null (tf-constraints a)))
                                                                                    a))
                                                                            (sm-trans-funcs sm))))
                                                                (tfnum (list-length tfs-of-stt)))
                                                            (if ;if exists no-constraint transition,other transition should fail
                                                                (and no-cst (null tfs-of-stt))
                                                                (construct-string
                                                                    (/format "_state_next = ~A;~%" (symbol-name (tf-next-state no-cst)))
                                                                    (mapcar 
                                                                        (lambda (sig) (/format "aux_~A_next = 1'b1;~%" sig))
                                                                        (tf-signals no-cst)))
                                                                (construct-string
                                                                    (dotimes (cst tfnum)
                                                                        (if (< cst (1- tfnum))
                                                                            (/format (conf-if-else/
                                                                                :constraints (gen-cststring (tf-constraints (car tfs-of-stt)))
                                                                                :if-block
                                                                                (construct-string
                                                                                    (/format "_state_next = ~A;~%" (symbol-name (tf-next-state (car tfs-of-stt))))
                                                                                    (mapcar 
                                                                                        (lambda (sig) (/format "aux_~A_next = 1'b1;~%" sig))
                                                                                        (tf-signals (car tfs-of-stt)))
                                                                                    )))
                                                                            (if no-cst
                                                                                (/format (conf-if-else
                                                                                    :constraints (gen-cststring (tf-constraints (car tfs-of-stt)))
                                                                                    :if-block
                                                                                    (construct-string
                                                                                        (/format "_state_next = ~A;~%" (symbol-name (tf-next-state (car tfs-of-stt))))
                                                                                        (mapcar 
                                                                                            (lambda (sig) (/format "aux_~A_next = 1'b1;~%" sig))
                                                                                            (tf-signals (car tfs-of-stt))))
                                                                                    :else-block
                                                                                    (construct-string
                                                                                        (/format "_state_next = ~A;~%" (symbol-name (tf-next-state no-cst)))
                                                                                        (mapcar 
                                                                                            (lambda (sig) (/format "aux_~A_next = 1'b1;~%" sig))
                                                                                            (tf-signals no-cst)))))
                                                                                (/format (conf-if
                                                                                    :constraints (gen-cststring (tf-constraints (car tfs-of-stt)))
                                                                                    :if-block
                                                                                    (construct-string
                                                                                        (/format "_state_next = ~A;~%" (symbol-name (tf-next-state (car tfs-of-stt))))
                                                                                        (mapcar 
                                                                                            (lambda (sig) (/format "aux_~A_next = 1'b1;~%" sig))
                                                                                            (tf-signals (car tfs-of-stt))))))))
                                                                        (setf tfs-of-stt (cdr tfs-of-stt)))
                                                                    ))))))))
                                        (/format (conf-incase 
                                            :value "default"
                                            :block 
                                            (format-string "_state_next = ~A;~%" (sm-init-state sm))))))))
                        (concatenate 'string
                            (construct-string
                                (mapcar-r (sm-signals sm)
                                    (lambda (sig) (/format "aux_~A_next = 1'b0;~%" sig))))
                            (if (member 'default (sm-states sm))
                                (concatenate 'string
                                    (format-string "_state_next = ~A;~%" (sm-init-state sm))
                                    (print-pairs 
                                        (modify-state-vars
                                            (getchain ((sm-state-confs sm) 'state-var 'default))))
                                    (print-pairs
                                        (getchain ((sm-state-confs sm) 'src-out 'default)))
                                    configuration)
                                (concatenate 'string
                                    (format-string "_state_next = ~A;~%" (sm-init-state sm))
                                    configuration))))))))

    (format strm "~%//^^^^^^^^^^^^^^^^code generated by SMDL compiler^^^^^^^^^^^^^^^^^^^^^^")
 ) 

;verilog-printer{{{
(defun add-indent (&key (contents "") (indent 0))
    (let* (
            (cont-len (length contents))
            (contstrm (make-string-input-stream contents))
            (buffer (make-string-output-stream))
            (result 
                (do ()
                    ((= (file-position contstrm) cont-len)
                        (get-output-stream-string buffer))
                    (fresh-line buffer)
                    (dotimes (c indent)
                        (format buffer " "))
                    (format buffer (read-line contstrm)))))
        (close contstrm)
        (close buffer)
        result))

(setf (symbol-function 'verilog-printer) #'add-indent)
;}}}

;configuration functions{{{

#|some interfaces {{{
    verilog-printer
        :indent
        :contents

    configuration functions: all the output is string
    conf-alwaysblock 
        :detect         ;signal-string
        :block          ;contents
        :indent         ;contents indentation, space-number
    conf-case
        :variable       ;variable to determine
        :incases        ;all the case
        :indent         ;contents indentation, space-number
    conf-incase
        :value          ;if variable=value
        :block          ;contents
        :indent
    conf-if
        :constraints
        :if-block
        :indent
    conf-if-else
        :constraints
        :if-block
        :else-block
        :indent
    conf-if-else/
        :constraints
        :if-block
        :indent
}}}|#

;templates{{{
(setf alwaysblock-template
"always@(~A) begin
~A
end~%")

(setf case-template
"case (~A) 
~A
endcase~%")

(setf incase-template
"~A: begin
~A
    end
")

(setf if-template
"if(~A) begin
~A
end")

(setf else-template ;first ~A is useless
"~A else begin
~A
end~%")

(setf if-else/-template
"if(~A) begin
~A
end else ")
;}}}

;pattern: template-rendering1/1
; one control variable
; one indented block
(defmacro template-rendering1/1 (&key template ctl-var block indent)
    `(let (
            (buffer (make-string-output-stream))
            (result ""))
        (format buffer ,template
            ,ctl-var
            (add-indent :contents ,block :indent ,indent))
        (setf result (get-output-stream-string buffer))
        (close buffer)
        result))

(defun conf-alwaysblock (&key (detect "*") (block "") (indent 4))
    (template-rendering1/1
        :template alwaysblock-template
        :ctl-var detect
        :block block
        :indent indent))

(defun conf-case (&key (variable "") (incases "") (indent 4))
    (template-rendering1/1
        :template case-template
        :ctl-var variable
        :block incases
        :indent indent))

(defun conf-incase (&key (value "") (block "") (indent 4))
    (template-rendering1/1
        :template incase-template
        :ctl-var value
        :block block
        :indent indent))

(defun conf-if (&key (constraints "1'b1==1'b1") (if-block "") (indent 4))
    (template-rendering1/1
        :template if-template
        :ctl-var constraints
        :block if-block
        :indent indent))

(defun conf-if-else (&key (constraints "1'b1==1'b1") (if-block "") (else-block "") (indent 4))
    (concatenate 'string 
        (template-rendering1/1
            :template if-template
            :ctl-var constraints
            :block if-block
            :indent indent)
        (template-rendering1/1
            :template else-template
            :ctl-var ""
            :block else-block
            :indent indent)))

(defun conf-if-else/ (&key (constraints "1'b1==1'b1") (if-block "") (indent 4))
    (template-rendering1/1
        :template if-else/-template
        :ctl-var constraints
        :block if-block
        :indent indent))
;}}}
;}}}

