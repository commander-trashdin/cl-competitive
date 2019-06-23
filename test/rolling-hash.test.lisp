(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../rolling-hash.lisp"))

(use-package :test-util)

(with-test (:name rolling-hash)
  (let ((rhash1 (make-rhash "asddfddfd" 1000000007 :base 1729)))
    (assert (= (rhash-get rhash1 2 6) (rhash-get rhash1 5 9)))
    (assert (= (rhash-get rhash1 2 2) (rhash-get rhash1 5 5)))
    (assert (/= (rhash-get rhash1 2 6) (rhash-get rhash1 3 7)))
    (assert (= (rhash-concat rhash1 (rhash-get rhash1 0 2) (rhash-get rhash1 5 7) 2)
               (rhash-get rhash1 0 4)))
    (signals error (make-rhash "error" 1000000006 :base 1729))
    (make-rhash "no error" 17 :base 11)
    (signals error (make-rhash "error" 17 :base 19))
    (signals error (make-rhash "error" 17 :base 17))
    (signals error (make-rhash "error" 17 :base 0))))