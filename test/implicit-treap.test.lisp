(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../implicit-treap.lisp"))

(use-package :test-util)

(defun copy-itreap (itreap)
  "For development. Recursively copies the whole ITREAPs."
  (if (null itreap)
      nil
      (%make-itreap (%itreap-value itreap)
                   (%itreap-priority itreap)
                   :left (copy-itreap (%itreap-left itreap))
                   :right (copy-itreap (%itreap-right itreap))
                   :count (%itreap-count itreap)
                   :accumulator (%itreap-accumulator itreap)
                   :lazy (%itreap-lazy itreap)
                   :reversed (%itreap-reversed itreap))))

(defun itreap-sane-p (itreap)
  (labels ((priority* (itreap)
             (if (null itreap) 0 (%itreap-priority itreap))))
    (declare (inline priority*))
    (if (null itreap)
        t
        (and (> (%itreap-priority itreap) (priority* (%itreap-left itreap)))
             (> (%itreap-priority itreap) (priority* (%itreap-right itreap)))
             (itreap-sane-p (%itreap-left itreap))
             (itreap-sane-p (%itreap-right itreap))))))

(defun itreap-list (itreap)
  (let (res)
    (labels ((recur (itreap)
               (when itreap
                 (force-down itreap)
                 (recur (%itreap-left itreap))
                 (push (%itreap-value itreap) res)
                 (recur (%itreap-right itreap))
                 (force-up itreap))))
      (recur itreap)
      (reverse res))))

(defun itreap-tree (itreap)
  (if (null itreap)
      nil
      (cons (%itreap-value itreap)
            (cons (itreap-tree (%itreap-left itreap))
                  (itreap-tree (%itreap-right itreap))))))

(declaim (notinline itreap-insert itreap-query itreap-ref itreap-update itreap-bisect-left itreap-range-bisect-left))

(with-test (:name implicit-treap-sanity)
  (assert (loop for i below 100 always (itreap-sane-p (make-itreap i)))))

(with-test (:name implicit-treap-insert)
  (assert (equal '(10 1 2 3 4 5 6)
                 (itreap-list (itreap-insert (itreap 1 2 3 4 5 6) 0 10))))
  (assert (equal '(1 10 2 3 4 5 6)
                 (itreap-list (itreap-insert (itreap 1 2 3 4 5 6) 1 10))))
  (assert (equal '(1 2 10 3 4 5 6)
                 (itreap-list (itreap-insert (itreap 1 2 3 4 5 6) 2 10))))
  (assert (equal '(1 2 3 10 4 5 6)
                 (itreap-list (itreap-insert (itreap 1 2 3 4 5 6) 3 10))))
  (assert (equal '(1 2 3 4 10 5 6)
                 (itreap-list (itreap-insert (itreap 1 2 3 4 5 6) 4 10))))
  (assert (equal '(1 2 3 4 5 10 6)
                 (itreap-list (itreap-insert (itreap 1 2 3 4 5 6) 5 10))))
  (assert (equal '(1 2 3 4 5 6 10)
                 (itreap-list (itreap-insert (itreap 1 2 3 4 5 6) 6 10))))
  (assert (= 10 (itreap-query (itreap-insert (itreap 1 2 3 4 5 6) 3 10) 3 4)))
  (signals invalid-itreap-index-error
    (itreap-list (itreap-insert (itreap 1 2 3 4 5 6) 7 10)))
  (assert (equal '(10) (itreap-list (itreap-insert nil 0 10)))))

(with-test (:name implicit-treap-delete)
  (assert (equal '(2 3 4 5 6)
                 (itreap-list (itreap-delete (itreap 1 2 3 4 5 6) 0))))
  (assert (equal '(1 3 4 5 6)
                 (itreap-list (itreap-delete (itreap 1 2 3 4 5 6) 1))))
  (assert (equal '(1 2 4 5 6)
                 (itreap-list (itreap-delete (itreap 1 2 3 4 5 6) 2))))
  (assert (equal '(1 2 3 5 6)
                 (itreap-list (itreap-delete (itreap 1 2 3 4 5 6) 3))))
  (assert (equal '(1 2 3 4 6)
                 (itreap-list (itreap-delete (itreap 1 2 3 4 5 6) 4))))
  (assert (equal '(1 2 3 4 5)
                 (itreap-list (itreap-delete (itreap 1 2 3 4 5 6) 5))))
  (signals invalid-itreap-index-error (itreap-delete (itreap 1 2 3 4 5 6) 6))
  (signals invalid-itreap-index-error (itreap-delete nil 0))
  (let ((itreap (itreap 1 2 3 2 1 2 7)))
    (assert (= 1 (itreap-query itreap 1 5)))
    (setq itreap (itreap-delete itreap 4))
    (assert (= 2 (itreap-query itreap 1 5)))))

(with-test (:name implicit-treap)
  (dotimes (i 10)
    (let ((itreap1 (itreap 1 2 3 2 1 2 7)))
      (assert (equal '(1 2 3 2 1 2 7) (itreap-list itreap1)))
      ;; ref and query
      (assert (= 7 (itreap-ref itreap1 6)))
      (assert (= 1 (itreap-query itreap1 0 7)))
      (assert (= 2 (itreap-query itreap1 5 7)))
      (assert (= 2 (itreap-query itreap1 1 3)))
      ;; point update
      (setf (itreap-ref itreap1 1) 0)
      (assert (= 0 (itreap-ref itreap1 1)))
      (assert (= most-positive-fixnum (itreap-query itreap1 1 1)))
      (assert (= 0 (itreap-query itreap1 0 3)))
      (assert (= 0 (itreap-query itreap1 0 7)))
      (assert (= 1 (itreap-query itreap1 2 7)))
      (assert (= 2 (itreap-query itreap1 2 4)))
      ;; invalid index error
      (signals invalid-itreap-index-error (itreap-query itreap1 2 8))
      (signals invalid-itreap-index-error (itreap-query itreap1 2 1))
      (signals invalid-itreap-index-error (itreap-ref itreap1 8))
      (signals invalid-itreap-index-error (setf (itreap-ref itreap1 8) 5))
      ;; range update
      (setf itreap1 (itreap 1 2 3 2 1 2 7))
      (setf itreap1 (itreap-update itreap1 -10 3 5))
      (assert (equal '(1 2 3 -8 -9 2 7) (itreap-list itreap1)))
      (assert (= -8 (itreap-query itreap1 2 4)))
      (assert (= 3 (itreap-query itreap1 2 3)))
      ;; range update (for null range)
      (setf itreap1 (itreap-update itreap1 -10 3 3))
      (assert (equal '(1 2 3 -8 -9 2 7) (itreap-list itreap1)))
      (assert (= -8 (itreap-query itreap1 2 4)))
      (assert (= 3 (itreap-query itreap1 2 3))))))

(with-test (:name implicit-treap-range-bisect)
  (let ((itreap (itreap 5 2 4 2 1 4 2 1 -1)))
    (assert (= 0 (itreap-range-bisect-left itreap 6 #'>)))
    (assert (= 0 (itreap-range-bisect-left itreap 5 #'>)))
    (assert (= 1 (itreap-range-bisect-left itreap 4 #'>)))
    (assert (= 1 (itreap-range-bisect-left itreap 3 #'>)))
    (assert (= 1 (itreap-range-bisect-left itreap 2 #'>)))
    (assert (= 4 (itreap-range-bisect-left itreap 1 #'>)))
    (assert (= 8 (itreap-range-bisect-left itreap 0 #'>)))
    (assert (= 8 (itreap-range-bisect-left itreap -1 #'>)))
    (assert (= 9 (itreap-range-bisect-left itreap -2 #'>)))

    ;; START arg
    (assert (= 3 (itreap-range-bisect-left itreap 6 #'> 3)))
    (assert (= 3 (itreap-range-bisect-left itreap 5 #'> 3)))
    (assert (= 3 (itreap-range-bisect-left itreap 4 #'> 3)))
    (assert (= 3 (itreap-range-bisect-left itreap 3 #'> 3)))
    (assert (= 3 (itreap-range-bisect-left itreap 2 #'> 3)))
    (assert (= 4 (itreap-range-bisect-left itreap 1 #'> 3)))
    (assert (= 8 (itreap-range-bisect-left itreap 0 #'> 3)))
    (assert (= 8 (itreap-range-bisect-left itreap -1 #'> 3)))
    (assert (= 9 (itreap-range-bisect-left itreap -2 #'> 3)))

    (assert (= 8 (itreap-range-bisect-left itreap 6 #'> 8)))
    (assert (= 8 (itreap-range-bisect-left itreap -1 #'> 8)))
    (assert (= 9 (itreap-range-bisect-left itreap -2 #'> 8)))

    (assert (= 9 (itreap-range-bisect-left itreap -10 #'> 9)))
    (assert (= 9 (itreap-range-bisect-left itreap 10 #'> 9)))

    (signals invalid-itreap-index-error (itreap-range-bisect-left itreap 10 #'> 10))

    ;; null case
    (assert (zerop (itreap-range-bisect-left nil 10 #'<)))))

(with-test (:name implicit-treap-ordered)
  (let ((itreap (itreap 3 3 2 2 2 2 1 1 1)))
    (assert (= 6 (itreap-bisect-left itreap 1 #'>)))
    (assert (= 9 (itreap-bisect-left itreap 0 #'>)))
    (assert (= 0 (itreap-bisect-left itreap 4 #'>)))
    (assert (= 0 (itreap-bisect-right itreap 4 #'>)))
    (assert (= 2 (itreap-bisect-right itreap 3 #'>)))
    (assert (= 9 (itreap-bisect-right itreap 1 #'>)))))
