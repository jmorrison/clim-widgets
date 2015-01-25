;;;; clim-widgets.lisp

(in-package #:clim-widgets)

; helper ----------------
(defmacro header ()
  `(progn 
     (present #\< 'change-month :stream s) (format s "~a" (svref local-time:+short-month-names+ month)) (present #\> 'change-month :stream s) (princ " " s) 
     (present #\< 'change-year :stream s) (princ year s) (present #\> 'change-year :stream s) (princ " " s)
     (present "Today" 'string :stream s) (princ " " s)
     (present #\x 'character :stream s) (terpri s)))

(defun start (m y) ;ev rename start-date (month year)
  "returns the start-date, i.e. the first of 7x6=42 dates, as an instance
  e.g #<SIMPLE-DATE-TIME:DATE-TIME 2014-07-27 00:00:00.000 {100654EAF3}>"
  (dt:make-date y (1- m) 
    (- (local-time:days-in-month (1- m) y)
       (nth-value 6 (decode-universal-time (encode-universal-time 0 0 0 1 m y))))))

(defmacro disp-day-nr ()
  `(formatting-cell (s :align-x :right)
    (cond ((dt:date= (dt:today) (dt:day+ (start month year) i)) (with-text-face (s :bold) (present (dt:day+ (start month year) i) 'date :stream s)))
          ((/= month (dt:month-of (dt:day+ (start month year) i))) (with-drawing-options (s :ink +gray+ :text-style (make-text-style nil :italic :smaller)) (present (dt:day+ (start month year) i) 'date :stream s)))
          (t (present (dt:day+ (start month year) i) 'date :stream s)))))

; present-types ---------------
(define-presentation-type change-month () :inherit-from 'character)
(define-presentation-type change-year () :inherit-from 'character)
(define-presentation-type date ())

(define-presentation-method present (d (type date) strm view &key)
  (declare (ignore type view))
  (format strm "~A" (dt:day-of d)))

; gui  ------------------------
(define-application-frame cal () 
  ((day :accessor d)
   (month :accessor m :initarg :m)
   (year :accessor y :initarg :y))
  (:panes 
    (cal1 :application 
     :width :compute :height :compute :borders nil :scroll-bars nil :text-style '(:fix nil nil)
     :display-function 'layout1)
    (cal2 :application 
     :width :compute :height :compute :borders nil :scroll-bars nil :text-style '(:fix nil nil)
     :display-function 'layout2))
  (:layouts (c1 cal1) (c2 cal2)))

(defmethod layout1 ((fr cal) s &key)
  (with-slots (month year) *application-frame*
    (header)
    (formatting-table (s)
      (formatting-row (s)
        (dotimes (d 7)
          (formatting-cell (s :align-x :center)
            (write-string (subseq (aref local-time:+short-day-names+ (mod d 7)) 0 2) s))))
      (do ((i 0) )
        ((> i 35))   ; 42 macht 1 Reihe zuviel, verstehe ich nicht
        (formatting-row (s)
          (dotimes (d 7) 
            (disp-day-nr) (incf i)))))))

(defmethod layout2 ((fr cal) s &key)
  (with-slots (month year) *application-frame*
    (header)
    (let (i)
    (formatting-table (s)
      (dotimes (l 7)  ; warum nicht 6 ?
        (setf i l)
        (formatting-row (s)
          (formatting-cell (s)
            (write-string (subseq (aref local-time:+short-day-names+ (mod l 7)) 0 2) s))
          (dotimes (d 6)     ; warum nicht 5 ?
            (disp-day-nr) (incf i 7))))))))

(define-cal-command switch-layout ((c 'character :gesture :select))
  (let ((frame *application-frame*))
    (let ((new-layout (case (frame-current-layout frame) (c1 'c2) (c2 'c1))))
      (setf (frame-current-layout frame) new-layout))))

(define-cal-command change-y ((c 'change-year :gesture :select))
  (if (char= c #\<)
    (progn (decf (y *application-frame*)) (redisplay-frame-panes *application-frame*))
    (progn (incf (y *application-frame*)) (redisplay-frame-panes *application-frame*))))

(define-cal-command change-m ((c 'change-month :gesture :select))
  (if (char= c #\<)
    (typecase (m *application-frame*) ((integer 2 12) (decf (m *application-frame*)) (redisplay-frame-panes *application-frame*))
      (t (setf (m *application-frame*) 12) (decf (y *application-frame*)) (redisplay-frame-panes *application-frame*)))
    (typecase (m *application-frame*) ((integer 1 11) (incf (m *application-frame*)) (redisplay-frame-panes *application-frame*))
      (t (setf (m *application-frame*) 1) (incf (y *application-frame*)) (redisplay-frame-panes *application-frame*)))))

(define-cal-command get-date ((date 'date :gesture :select))
  (with-accessors ((da d) (ma m) (ya y)) *application-frame*
    (setf da (dt:day-of date) ma (dt:month-of date) ya (dt:year-of date)))
  (frame-exit *application-frame*))

(define-cal-command todays-date ((c 'string :gesture :select))
  (with-accessors ((da d) (ma m) (ya y)) *application-frame*
    (let ((now (dt:now))) 
      (setf da (dt:day-of now) ma (dt:month-of now) ya (dt:year-of now))))
    (frame-exit *application-frame*))

(defun calendar (&optional (month (dt:month-of (dt:now))) (year (dt:year-of (dt:now))))
  (let ((frame (make-application-frame 'cal :m month :y year)))
    (run-frame-top-level frame)
    (if (slot-boundp frame 'day) (format nil "~a-~a-~a" (y frame) (m frame) (d frame)))))
