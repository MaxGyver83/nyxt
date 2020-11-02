;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(in-package :nyxt)

(declaim (type (cons string) *invisible-modes*))
(defvar *invisible-modes* '("base-mode") ; TODO: Export?
  "List of mode names to hide from the status view")

(defun format-status-modes (&optional (buffer (current-buffer)))
  (format nil "~{~a~^ ~}"
          (mapcar (lambda (m) (str:replace-all "-mode" "" m))
                  (set-difference
                   (mapcar (alex:compose #'str:downcase #'mode-name) (modes buffer))
                   *invisible-modes*
                   :test #'string=))))

(defun format-status-buttons ()
  (markup:markup
   (:a :class "button" :title "Backwards" :href (lisp-url '(nyxt/web-mode:history-backwards)) "←")
   (:a :class "button" :title "Forwards" :href (lisp-url '(nyxt/web-mode:history-forwards)) "→")
   (:a :class "button" :title "Reload" :href (lisp-url '(nyxt:reload-current-buffer)) "↺")
   (:a :class "button" :title "Execute" :href (lisp-url '(nyxt:execute-command)) "⚙")
   (:a :class "button" :title "Buffers" :href (lisp-url '(nyxt::list-buffers)) "≡")))

(defun format-status-load-status (&optional (buffer (current-buffer)))
  (markup:markup
   (:span (if (and (web-buffer-p buffer)
                   (eq (slot-value buffer 'load-status) :loading))
              "Loading: " ""))))

(defun format-status-url (&optional (buffer (current-buffer)))
  (markup:markup
   (:a :class "button"
       :href (lisp-url '(nyxt:set-url-from-current-url))
       (format nil " ~a — ~a"
               (object-display (url buffer))
               (title buffer)))))

(defun format-status-tabs ()
  (flet ((buffer-domains ()
           (remove-duplicates
            (remove nil
                    (mapcar #'(lambda (i) (quri:uri-domain (url i)))
                            (buffer-list :sort-by-time t)))
            :test #'equal)))
    (markup:markup
     (:span
      (loop for domain in (buffer-domains)
            collect (markup:markup
                     (:a :class "tab"
                         :href
                         (lisp-url `(nyxt::switch-buffer-or-query-domain ,domain)) domain)))))))

(defun format-status (window)
  (let ((buffer (current-buffer window)))
    (markup:markup
     (:div :id "container"
           (:div :id "controls"
                 (markup:raw
                  (format-status-buttons)
                  (format-status-load-status buffer)
                  (format-status-url buffer)))
           (:div :id "tabs"
                 (markup:raw
                  (format-status-tabs)))
           (:div :id "modes"
                 (format-status-modes buffer))))))
