(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../modular-arithmetic.lisp")
  (load "../mod-power.lisp"))

(use-package :test-util)

(defparameter *state* (seed-random-state 0))
(defconstant +mod+ 1000000007)

(declaim (notinline ext-gcd mod-log mod-inverse mod-echelon! mod-determinant! mod-inverse-matrix!))

(with-test (:name ext-gcd)
  (assert (equalp '(-9 47) (multiple-value-list (ext-gcd 240 46))))
  (assert (equalp '(9 47) (multiple-value-list (ext-gcd -240 46))))
  (assert (equalp '(-9 -47) (multiple-value-list (ext-gcd 240 -46))))
  (assert (equalp '(9 -47) (multiple-value-list (ext-gcd -240 -46)))))

(with-test (:name mod-inverse)
  (let ((state (sb-ext:seed-random-state 0)))
    (dotimes (i 100)
      (let ((a (random 100 state))
            (m (+ 2 (random 100 state))))
        (assert (or (/= 1 (gcd a m))
                    (= 1 (mod (* a (mod-inverse a m)) m))))))))

(defun naive-mod-log (x y modulus &key from-zero)
  (loop for k from (if from-zero 0 1) to modulus
        when (= (mod-power x k modulus) (mod y modulus))
        do (return k)
        finally (return nil)))

(with-test (:name mod-log)
  (let ((state (sb-ext:seed-random-state 0)))
    (dotimes (i 100)
      (let ((a (- (random 20 state) 10))
            (b (- (random 20 state) 10)))
        (multiple-value-bind (x y) (ext-gcd a b)
          (assert (= (+ (* a x) (* b y)) (gcd a b)))))))
  (assert (= 8 (mod-log 6 4 44)))
  (assert (= 8 (mod-log -38 -40 44)))
  (assert (null (mod-log 6 2 44)))
  (assert (= 2 (mod-log 8 4 12)))
  (assert (= 4 (mod-log 3 13 17)))
  (assert (= 1 (mod-log 12 0 4)))
  (assert (= 2 (mod-log 12 0 8)))
  (assert (null (mod-log 12 1 8)))
  (assert (= 1 (mod-log 0 0 100)))
  (loop for x to 30
        do (loop for y to 30
                 do (loop for modulus from 1 to 30
                          do (assert (eql (mod-log x y modulus)
                                          (naive-mod-log x y modulus)))
                             (assert (eql (mod-log x y modulus :from-zero t)
                                          (naive-mod-log x y modulus :from-zero t))))))
  (dotimes (_ 200)
    (let ((x (random 1000 *state*))
          (y (random 1000 *state*))
          (modulus (+ 1 (random 1000 *state*))))
      (assert (eql (mod-log x y modulus) (naive-mod-log x y modulus)))
      (assert (eql (mod-log x y modulus :from-zero t)
                   (naive-mod-log x y modulus :from-zero t))))))

(with-test (:name solve-bezout)
  (assert (= (%calc-min-factor 8 3) -2))
  (assert (= (%calc-min-factor -8 3) 3))
  (assert (= (%calc-min-factor 8 -3) 2))
  (assert (= (%calc-min-factor -8 -3) -3))
  (assert (= (%calc-max-factor 8 3) -3))
  (assert (= (%calc-max-factor -8 3) 2))
  (assert (= (%calc-max-factor 8 -3) 3))
  (assert (= (%calc-max-factor -8 -3) -2)))

(with-test (:name mod-echelon)
  (assert (equalp #2a((1 0 1000000005 1000000004) (0 1 1 4) (0 0 0 0))
                  (mod-echelon! (make-array '(3 4) :initial-contents '((1 3 1 9) (1 1 -1 1) (3 11 5 35))) +mod+)))
  (assert (= 2 (nth-value 1 (mod-echelon! #2a((1 3 1 9) (1 1 -1 1) (3 11 5 35)) +mod+))))
  (assert (equalp #2a((1 0 1000000005 0) (0 1 1 0) (0 0 0 1))
                  (mod-echelon! (make-array '(3 4) :initial-contents '((1 3 1 9) (1 1 -1 1) (3 11 5 37))) +mod+)))
  (assert (= 3 (nth-value 1 (mod-echelon! #2a((1 3 1 9) (1 1 -1 1) (3 11 5 37)) +mod+))))
  ;; extended
  (assert (equalp #2a((1 0 1000000005 1000000004) (0 1 1 4) (0 0 0 1))
                  (mod-echelon! (make-array '(3 4) :initial-contents '((1 3 1 9) (1 1 -1 1) (3 11 5 36))) +mod+ t)))
  (assert (= 2 (nth-value 1 (mod-echelon! #2a((1 3 1 9) (1 1 -1 1) (3 11 5 36)) +mod+ t))))
  (assert (equalp #2a((1 0 0 4) (0 1 0 3) (0 0 1 0))
                  (mod-echelon! (make-array '(3 4) :initial-contents '((3 1 4 1) (5 2 6 5) (0 5 2 1))) 7 t))))

(with-test (:name mod-determinant)
  (assert (= 14 (mod-determinant! #2a((3 3 3 1) (2 4 5 2) (3 4 5 1) (2 2 3 4)) +mod+)))
  (assert (= (mod -70 +mod+)
             (mod-determinant! #2a((10 20 10) (4 5 6) (2 3 5)) +mod+)))
  (assert (= 1 (mod-determinant! #2a() +mod+))))

(with-test (:name mod-inverse-matrix)
  (assert (equalp #2a((1 0 0) (0 1 0) (0 0 1))
                  (mod-inverse-matrix! #2a((1 0 0) (0 1 0) (0 0 1)) 7)))
  (assert (equalp #2a((0 0 1) (0 1 0) (1 0 0))
                  (mod-inverse-matrix! #2a((0 0 1) (0 1 0) (1 0 0)) 7)))
  (assert (null (mod-inverse-matrix! #2a((0 0 1) (1 1 1) (1 1 1)) 7))))
