#-swank
(eval-when (:compile-toplevel)
  (unless (member :child-sbcl *features*)
    (quit
     :unix-status
     (process-exit-code
      (run-program *runtime-pathname*
                   `("--control-stack-size" "128MB"
                     "--noinform" "--disable-ldb" "--lose-on-corruption" "--end-runtime-options"
                     "--eval" "(push :child-sbcl *features*)"
                     "--eval" ,(format nil "(progn (compile-file ~S) (quit))" *compile-file-pathname*))
                   :output t :error t :input t))
     :recklessly-p t)))
