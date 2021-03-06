(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../condensation.lisp")
  (load "../random-graph.lisp"))

(use-package :test-util)

(with-test (:name scc/manual)
  ;; null graph
  (let ((scc (make-scc #())))
    (assert (equalp #() (scc-components scc)))
    (assert (= 0 (scc-count scc)))
    (assert (equalp #() (scc-sizes scc))))
  ;; graph of a vertex
  (let ((scc (make-scc #(()))))
    (assert (equalp #(0) (scc-components scc)))
    (assert (= 1 (scc-count scc)))
    (assert (equalp #(1) (scc-sizes scc))))
  ;; graph of two vertices
  (let ((scc (make-scc #((1) ()))))
    (assert (or (equalp #(0 1) (scc-components scc))
                (equalp #(1 0) (scc-components scc))))
    (assert (= 2 (scc-count scc)))
    (assert (equalp #(1 1) (scc-sizes scc))))
  (let ((scc (make-scc #(() (0)))))
    (assert (or (equalp #(0 1) (scc-components scc))
                (equalp #(1 0) (scc-components scc))))
    (assert (= 2 (scc-count scc)))
    (assert (equalp #(1 1) (scc-sizes scc))))
  (let ((scc (make-scc #((1) (0)))))
    (assert (equalp #(0 0) (scc-components scc)))
    (assert (= 1 (scc-count scc)))
    (assert (= 2 (aref (scc-sizes scc) 0))))
  (let ((scc (make-scc #(() ()))))
    (assert (or (equalp #(0 1) (scc-components scc))
                (equalp #(1 0) (scc-components scc))))
    (assert (= 2 (scc-count scc)))
    (assert (equalp #(1 1) (scc-sizes scc))))
  (let ((scc (make-scc #((1) (2) (0)))))
    (assert (equalp #(0 0 0) (scc-components scc)))
    (assert (= 1 (scc-count scc)))
    (assert (= 3 (aref (scc-sizes scc) 0))))
  (let ((scc (make-scc #((1) (0) ()))))
    (assert (or (equalp #(0 0 1) (scc-components scc))
                (equalp #(1 1 0) (scc-components scc))))
    (assert (= 2 (scc-count scc)))
    (assert (or (equalp #(2 1) (subseq (scc-sizes scc) 0 2))
                (equalp #(1 2) (subseq (scc-sizes scc) 0 2)))))
  (let ((scc (make-scc #((1) (2) (0)))))
    (assert (equalp #(0 0 0) (scc-components scc)))
    (assert (= 1 (scc-count scc)))
    (assert (= 3 (aref (scc-sizes scc) 0)))))

(defun %make-revgraph (graph)
  (let* ((n (length graph))
         (revgraph (make-array n :element-type 'list :initial-element nil)))
    (dotimes (i n)
      (dolist (dest (aref graph i))
        (push i (aref revgraph dest))))
    revgraph))

;; Kosaraju's algorithm
(defun make-scc-kosaraju (graph)
  "GRAPH := vector of adjacency lists
REVGRAPH := NIL | reversed graph of GRAPH"
  (declare (optimize (speed 3))
           (vector graph))
  (let* ((revgraph (%make-revgraph graph))
         (n (length graph))
         (visited (make-array n :element-type 'bit :initial-element 0))
         (posts (make-array n :element-type '(integer 0 #.most-positive-fixnum)))
         (components (make-array n :element-type '(integer 0 #.most-positive-fixnum)))
         (sizes (make-array n :element-type '(integer 0 #.most-positive-fixnum)
                            :initial-element 0))
         (pointer 0)
         (ord 0) ; ordinal number for a strongly connected component
         )
    (declare ((integer 0 #.most-positive-fixnum) pointer ord)
             ((simple-array list (*)) revgraph))
    (assert (= n (length revgraph)))
    (labels ((dfs (v)
               (setf (aref visited v) 1)
               (dolist (neighbor (aref graph v))
                 (when (zerop (aref visited neighbor))
                   (dfs neighbor)))
               (setf (aref posts pointer) v)
               (incf pointer))
             (reversed-dfs (v ord)
               (setf (aref visited v) 1
                     (aref components v) ord)
               (incf (aref sizes ord))
               (dolist (neighbor (aref revgraph v))
                 (when (zerop (aref visited neighbor))
                   (reversed-dfs neighbor ord)))))
      (dotimes (v n)
        (when (zerop (aref visited v))
          (dfs v)))
      (fill visited 0)
      (loop for i from (- n 1) downto 0
            for v = (aref posts i)
            when (zerop (aref visited v))
            do (reversed-dfs v ord)
               (incf ord))
      (%make-scc graph components sizes ord))))

;; We believe two SCC's are identical if the sorted SIZES are identical.
(defun scc= (scc1 scc2)
  (let ((sizes1 (sort (copy-seq (scc-sizes scc1)) #'<))
        (sizes2 (sort (copy-seq (scc-sizes scc2)) #'<)))
    (and (= (scc-count scc1) (scc-count scc2))
         (equalp sizes1 sizes2))))

(defun sorted-p (graph)
  "Returns true if GRAPH is topologically sorted"
  (dotimes (i (length graph))
    (dolist (j (aref graph i))
      (when (>= i j)
        (return-from sorted-p nil))))
  t)

(defparameter *state* (sb-ext:seed-random-state 0))

(with-test (:name scc/random)
  (dotimes (_ 2000)
    (let* ((graph (make-random-graph 20 (random 0.50 *state*) t))
           (scc1 (make-scc graph))
           (scc2 (make-scc-kosaraju graph))
           (cgraph1 (make-condensed-graph scc1))
           (cgraph2 (make-condensed-graph scc2)))
      (assert (scc= scc1 scc2))
      (assert (sorted-p cgraph1))
      (assert (sorted-p cgraph2)))))

(with-test (:name 2sat)
  (2sat-solve (make-2sat 0))
  (let ((2sat (make-2sat 1)))
    (add-implication 2sat 0 (negate 0))
    (assert (equalp #(0) (2sat-solve 2sat))))
  (let ((2sat (make-2sat 1)))
    (add-implication 2sat (negate 0) 0)
    (assert (equalp #(1) (2sat-solve 2sat))))
  (let ((2sat (make-2sat 1)))
    (add-implication 2sat 0 (negate 0))
    (add-implication 2sat (negate 0) 0)
    (assert (null (2sat-solve 2sat))))
  (let ((2sat (make-2sat 2)))
    (add-implication 2sat 1 (negate 1))
    (add-implication 2sat 0 1)
    (add-implication 2sat (negate 0) 0)
    (assert (null (2sat-solve 2sat)))))
