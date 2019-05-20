;;;
;;; This is an implementation of binary heap. Please use generalized-heap
;;; instead. I leave it just for my reference.
;;;

(defstruct (heap (:constructor make-heap
                            (size
                             &key test (element-type t)
                             &aux (data (make-array (1+ size) :element-type element-type)))))
  (data #() :type (simple-array * (*)) :read-only t)
  (test #'< :type function :read-only t)
  (position 1 :type (integer 1 #.array-total-size-limit)))

(declaim (inline heap-push))
(defun heap-push (obj heap)
  (symbol-macrolet ((position (heap-position heap)))
    (let ((data (heap-data heap))
          (test (heap-test heap)))
      (labels ((update (pos)
                 (unless (= pos 1)
                   (let ((parent-pos (ash pos -1)))
                     (when (funcall test (aref data pos) (aref data parent-pos))
                       (rotatef (aref data pos) (aref data parent-pos))
                       (update parent-pos))))))
        (setf (aref data position) obj)
        (update position)
        (incf position)
        heap))))

(declaim (inline heap-pop))
(defun heap-pop (heap &optional (error t) null-value)
  (symbol-macrolet ((position (heap-position heap)))
    (let ((data (heap-data heap))
          (test (heap-test heap)))
      (labels ((update (pos)
                 (declare ((integer 1 #.most-positive-fixnum) pos))
                 (let* ((child-pos1 (+ pos pos))
                        (child-pos2 (1+ child-pos1)))
                   (when (<= child-pos1 position)
                     (if (<= child-pos2 position)
                         (if (funcall test (aref data child-pos1) (aref data child-pos2))
                             (unless (funcall test (aref data pos) (aref data child-pos1))
                               (rotatef (aref data pos) (aref data child-pos1))
                               (update child-pos1))
                             (unless (funcall test (aref data pos) (aref data child-pos2))
                               (rotatef (aref data pos) (aref data child-pos2))
                               (update child-pos2)))
                         (unless (funcall test (aref data pos) (aref data child-pos1))
                           (rotatef (aref data pos) (aref data child-pos1))))))))
        (if (= position 1)
            (if error
                (error "No element in heap.")
                null-value)
            (prog1 (aref data 1)
              (decf position)
              (setf (aref data 1) (aref data position))
              (update 1)))))))

(declaim (inline heap-reinitialize))
(defun heap-reinitialize (heap)
  (setf (heap-position heap) 1)
  heap)

(defun heap-peak (heap &optional (error t) null-value)
  (if (= 1 (heap-position heap))
      (if error
          (error "No element in heap")
          null-value)
      (aref (heap-data heap) 1)))

;; For test
;; (eval-when (:compile-toplevel :load-toplevel :execute)
;;   (ql:quickload :fiveam)
;;   (use-package :fiveam))

;; (test heap-test
;;   (let ((h (make-heap 20)))
;;     (finishes (dolist (o (list 7 18 22 15 27 9 11))
;;                 (heap-push o h)))
;;     (is (= 7 (heap-peak h)))
;;     (is (equal '(7 9 11 15 18 22 27)
;;                (loop repeat 7 collect (heap-pop h))))
;;     (signals error (heap-pop h))
;;     (is (eql 'eof (heap-pop h nil 'eof)))
;;     (is (eql 'eof (heap-peak h nil 'eof))))
;;   (is (typep (heap-data (make-heap 10 :element-type 'fixnum))
;;              '(simple-array fixnum (*)))))

;; (run! 'heap-test)

(defun bench (&optional (size 2000000))
  (declare (optimize (speed 3)))
  (let* ((heap (make-heap size :element-type 'fixnum))
         (seed (seed-random-state 0)))
    (time (dotimes (i size)
            (heap-push (random most-positive-fixnum seed) heap)))
    (time (dotimes (i size)
            (heap-pop heap)))))
