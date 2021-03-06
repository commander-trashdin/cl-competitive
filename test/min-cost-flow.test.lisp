(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../min-cost-flow.lisp"))

(use-package :test-util)

(with-test (:name min-cost-flow)
  (let ((graph (make-array '(5) :element-type 'list :initial-element nil)))
    (add-edge! graph 0 1 2 10)
    (add-edge! graph 0 2 4 2)
    (add-edge! graph 1 2 6 6)
    (add-edge! graph 1 3 2 6)
    (add-edge! graph 3 2 3 3)
    (add-edge! graph 3 4 6 8)
    (add-edge! graph 2 4 2 5)
    (assert (= 80 (min-cost-flow! graph 0 4 9)))
    (assert (= 0 (min-cost-flow! graph 0 4 0)))
    (signals not-enough-capacity-error (min-cost-flow! graph 0 4 90))))
