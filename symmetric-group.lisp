;;;
;;; Some operations on symmetric group
;;;

;; NOTE: Here the underlying set is 0-based: {0, 1, 2, ..., N-1}

(declaim (inline decompose-to-cycles))
(defun decompose-to-cycles (permutation)
  "Returns the list of all the cyclic permutations in PERMUTATION and returns
the parity of it as the second value. (Actually the second value is the distance
to the identity permutation, (0, 1, ..., N-1), w.r.t. swapping.)"
  (declare (vector permutation))
  (let* ((n (length permutation))
         result
         (visited (make-array n :element-type 'bit :initial-element 0))
         (sign 0))
    (declare ((integer 0 #.most-positive-fixnum) sign))
    (dotimes (init n)
      (when (zerop (sbit visited init))
        (push (loop for x = init then (aref permutation x)
                    until (= (sbit visited x) 1)
                    collect x
                    do (setf (sbit visited x) 1)
                       (incf sign))
              result)
        (decf sign)))
    (values result sign)))

(declaim (inline perm*))
(defun perm* (perm1 perm2)
  "Composes two permutations."
  (let* ((n (length perm1))
         (result (make-array n :element-type 'fixnum)))
    (dotimes (i n)
      (setf (aref result i) (aref perm2 (aref perm1 i))))
    result))

(declaim (inline perm-inverse))
(defun perm-inverse (perm)
  (let* ((n (length perm))
         (result (make-array n :element-type 'fixnum)))
    (dotimes (i n)
      (setf (aref result (aref perm i)) i))
    result))
