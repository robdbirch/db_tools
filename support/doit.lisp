#!/usr/local/bin/sbcl --script

(require :asdf)
(require :cl-json)

(defun run-translate ()
  (let ((obj (read)))
     (json:encode-json obj)))

;;(run-translate)
(sb-ext:save-lisp-and-die "model2json" :toplevel 'run-translate :executable t)
