(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../bit-basher.lisp"))

(use-package :test-util)

(defparameter *seq* #*01010010110011100111111000011111101011101110110101011100001100011111011110011101000010010001101110110101110000100010101011101001111011110111)
(defparameter *seq+1* #*00101001011001110011111100001111110101110111011010101110000110001111101111001110100001001000110111011010111000010001010101110100111101111011)
(defparameter *seq+2* #*00010100101100111001111110000111111010111011101101010111000011000111110111100111010000100100011011101101011100001000101010111010011110111101)
(defparameter *seq+3* #*00001010010110011100111111000011111101011101110110101011100001100011111011110011101000010010001101110110101110000100010101011101001111011110)
(defparameter *seq+4* #*00000101001011001110011111100001111110101110111011010101110000110001111101111001110100001001000110111011010111000010001010101110100111101111)
(defparameter *seq+5* #*00000010100101100111001111110000111111010111011101101010111000011000111110111100111010000100100011011101101011100001000101010111010011110111)
(defparameter *seq+10* #*00000000000101001011001110011111100001111110101110111011010101110000110001111101111001110100001001000110111011010111000010001010101110100111)
(defparameter *seq+15* #*00000000000000001010010110011100111111000011111101011101110110101011100001100011111011110011101000010010001101110110101110000100010101011101)
(defparameter *seq+20* #*00000000000000000000010100101100111001111110000111111010111011101101010111000011000111110111100111010000100100011011101101011100001000101010)
(defparameter *seq+25* #*00000000000000000000000000101001011001110011111100001111110101110111011010101110000110001111101111001110100001001000110111011010111000010001)
(defparameter *seq+30* #*00000000000000000000000000000001010010110011100111111000011111101011101110110101011100001100011111011110011101000010010001101110110101110000)
(defparameter *seq+40* #*00000000000000000000000000000000000000000101001011001110011111100001111110101110111011010101110000110001111101111001110100001001000110111011)
(defparameter *seq+50* #*00000000000000000000000000000000000000000000000000010100101100111001111110000111111010111011101101010111000011000111110111100111010000100100)
(defparameter *seq+60* #*00000000000000000000000000000000000000000000000000000000000001010010110011100111111000011111101011101110110101011100001100011111011110011101)
(defparameter *seq+138* #*00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001)
(defparameter *seq+139* #*00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
(defparameter *seq+140* #*00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)

(defparameter *seq+1end0* #*01010010110011100111111000011111101011101110110101011100001100011111011110011101000010010001101110110101110000100010101011101001111011110111)
(defparameter *seq+1end1* #*00010010110011100111111000011111101011101110110101011100001100011111011110011101000010010001101110110101110000100010101011101001111011110111)
(defparameter *seq+1end2* #*00110010110011100111111000011111101011101110110101011100001100011111011110011101000010010001101110110101110000100010101011101001111011110111)
(defparameter *seq+1end136* #*00101001011001110011111100001111110101110111011010101110000110001111101111001110100001001000110111011010111000010001010101110100111101111111)
(defparameter *seq+1end137* #*00101001011001110011111100001111110101110111011010101110000110001111101111001110100001001000110111011010111000010001010101110100111101111011)

(defun zero-vector (template-vector)
  (make-array (length template-vector) :element-type 'bit :initial-element 0))

(defun random-test-lshift (size sample)
  (let ((exemplar (make-array size :element-type 'bit :initial-element 0))
        (vec1 (make-array size :element-type 'bit))
        (vec2 (make-array size :element-type 'bit)))
    (dotimes (i size)
      (setf (aref exemplar i) (random 2)))
    (dotimes (_ sample)
      (fill vec2 0)
      (let ((delta (random 150)))
        (dotimes (i (max 0 (- size delta)))
          (setf (aref vec2 (+ i delta)) (aref exemplar i)))
        (assert (equal vec2 (bit-lshift exemplar delta vec1)))))))

(with-test (:name bit-lshift)
  ;; basic case
  (assert (equalp *seq+1* (bit-lshift (copy-seq *seq*) 1)))
  (assert (equalp *seq+1* (bit-lshift *seq* 1 (zero-vector *seq*))))
  (assert (equalp *seq+1* (bit-lshift *seq* 1)))
  (assert (equalp *seq+2* (bit-lshift *seq* 2)))
  (assert (equalp *seq+3* (bit-lshift *seq* 3)))
  (assert (equalp *seq+4* (bit-lshift *seq* 4)))
  (assert (equalp *seq+5* (bit-lshift *seq* 5)))
  (assert (equalp *seq+10* (bit-lshift *seq* 10)))
  (assert (equalp *seq+15* (bit-lshift *seq* 15)))
  (assert (equalp *seq+20* (bit-lshift *seq* 20)))
  (assert (equalp *seq+25* (bit-lshift *seq* 25)))
  (assert (equalp *seq+30* (bit-lshift *seq* 30)))
  (assert (equalp *seq+40* (bit-lshift *seq* 40)))
  (assert (equalp *seq+50* (bit-lshift *seq* 50 (zero-vector *seq*))))
  (assert (equalp *seq+60* (bit-lshift *seq* 60 (zero-vector *seq*))))
  (assert (equalp *seq+138* (bit-lshift *seq* 138 (zero-vector *seq*))))
  (assert (equalp *seq+140* (bit-lshift *seq* 140 (zero-vector *seq*))))
  (assert (equalp *seq+140* (bit-lshift *seq* 141 (zero-vector *seq*))))
  (assert (equalp *seq+140* (bit-lshift *seq* 890 (zero-vector *seq*))))
  (assert (equalp *seq+140* (bit-lshift *seq* 8900000000000000 (zero-vector *seq*))))

   ;; corner case
  (assert (eql *seq* (bit-lshift *seq* 0 t)))
  (assert (not (eql *seq* (bit-lshift *seq* 0))))
  (assert (equalp #* (bit-lshift *seq* 1000000000000000000 #*)))
  (assert (equalp #* (bit-lshift #* 1000000000000000000 #*)))
  (assert (equalp #*00000 (bit-lshift #* 1000000000000000000 (copy-seq #*00010))))
  (assert (equalp #*00010 (bit-lshift #* 3 (copy-seq #*00010))))
  (assert (equalp #*00000 (bit-lshift #* 4 (copy-seq #*00010))))
  (assert (equalp #*10010 (bit-lshift #*1 0 (copy-seq #*00010))))
  (assert (equalp #*00000 (bit-lshift #*1 5 (copy-seq #*00010))))

  ;; END argument
  (assert (equalp *seq+1end0* (bit-lshift *seq* 1 (copy-seq *seq*) 0)))
  (assert (equalp *seq+1end1* (bit-lshift *seq* 1 (copy-seq *seq*) 1)))
  (assert (equalp *seq+1end2* (bit-lshift *seq* 1 (copy-seq *seq*) 2)))
  (assert (equalp *seq+1end136* (bit-lshift *seq* 1 (copy-seq *seq*) 136)))
  (assert (equalp *seq+1end137* (bit-lshift *seq* 1 (copy-seq *seq*) 137)))

  ;; smaller dest-vector
  (assert (equalp #*00101 (bit-lshift *seq* 1 #*00000)))
  (assert (equalp #*00001 (bit-lshift *seq* 3 #*00000)))
  (assert (equalp #*00000 (bit-lshift *seq* 4 #*00000)))
  (assert (equalp #*00000 (bit-lshift *seq* 1000000000000000000 #*00000)))

  (random-test-lshift 140 1000)
  (random-test-lshift 64 1000)
  (random-test-lshift 128 1000))

(with-test (:name bitwise-operations)
  (let ((target (make-array 140 :element-type 'bit :initial-element 0))
        (reference (make-array 140 :element-type 'bit :initial-element 0))
        (state (seed-random-state 0)))
    (dotimes (i 100)
      ;; bit-not!
      (let ((l (random 141 state))
            (r (random 141 state)))
        (unless (<= l r) (rotatef l r))
        (bit-not! target l r)
        (loop for i from l below r
              do (setf (sbit reference i) (logxor 1 (sbit reference i))))
        (assert (equalp target reference)))
      ;; bit-count
      (let ((l (random 141 state))
            (r (random 141 state)))
        (unless (<= l r) (rotatef l r))
        (assert (= (bit-count target l r)
                   (count 1 target :start l :end r)))))))
