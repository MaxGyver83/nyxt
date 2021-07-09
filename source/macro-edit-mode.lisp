;;;; SPDX-FileCopyrightText: Atlas Engineer LLC
;;;; SPDX-License-Identifier: BSD-3-Clause

(uiop:define-package :nyxt/macro-edit-mode
    (:use :common-lisp :trivia :nyxt)
  (:documentation "Mode for editing macros."))
(in-package :nyxt/macro-edit-mode)

(define-mode macro-edit-mode ()
  "Mode for creating and editing macros."
  ((name
    ""
    :documentation "The name used for the macro."
    :accessor nil)
   (function-sequence
    0
    :documentation "A variable used to generate unique identifiers for user
    added functions.")
   (functions
    (make-hash-table)
    :documentation "A list of functions the user has added to their macro.")))

(defmethod get-unique-function-identifier ((mode macro-edit-mode))
  (incf (function-sequence mode)))

(define-command-global edit-macro ()
  "Edit a macro."
  (with-current-html-buffer (buffer "*Macro edit*" 'nyxt/macro-edit-mode:macro-edit-mode)
    (markup:markup
     (:style (style buffer))
     (:h1 "Macro edit")
     (:p "Name")
     (:input :type "text" :id "macro-name")
     (:p "Commands")
     (:p (:a :class "button"
             :href (lisp-url '(nyxt/macro-edit-mode::add-command)) "+ Add command"))
     (:div :id "commands" "")
     (:br)
     (:hr)
     (:a :class "button"
         :href (lisp-url '(nyxt/macro-edit-mode::save-macro)) "Save macro")
     (:a :class "button"
         :href (lisp-url '(nyxt/macro-edit-mode::save-macro)) "Evaluate macro"))))

(defmethod render-functions ((macro-editor macro-edit-mode))
  (flet ((render-functions ()
           (markup:markup
            (:table
             (loop for key being the hash-keys of (functions macro-editor)
                   using (hash-value value)
                   collect (markup:markup
                            (:tr (:td (:a :class "button"
                                          :href (lisp-url `(nyxt/macro-edit-mode::remove-function
                                                            (current-mode 'macro-edit-mode)
                                                            ,key))
                                          "✕"))
                                 (:td (:a :class "button"
                                          :href (lisp-url `(nyxt/macro-edit-mode::command-help
                                                            (current-mode 'macro-edit-mode)
                                                            ,key))
                                          "🛈"))
                                 (:td (symbol-name (name value))))))))))
    (ffi-buffer-evaluate-javascript-async
     (buffer macro-editor)
     (ps:ps
       (setf (ps:chain document (get-element-by-id "commands") |innerHTML|)
             (ps:lisp
              (render-functions)))))))

(defmethod command-help ((macro-editor macro-edit-mode) command-id)
  (nyxt:describe-command (gethash command-id (functions macro-editor))))

(defmethod add-function ((macro-editor macro-edit-mode) command)
  (setf (gethash (get-unique-function-identifier macro-editor)
                 (functions macro-editor))
        command)
  (render-functions macro-editor))

(defmethod remove-function ((macro-editor macro-edit-mode) command-id)
  (remhash command-id (functions macro-editor))
  (render-functions macro-editor))

(defmethod name ((macro-editor macro-edit-mode))
  (let ((name
          (ffi-buffer-evaluate-javascript
           (buffer macro-editor)
           (ps:ps
             (ps:chain document (get-element-by-id "macro-name") value)))))
    (cond ((not (str:emptyp name)) (setf (slot-value macro-editor 'name) name))
          ((slot-value macro-editor 'name) (slot-value macro-editor 'name))
          (t nil))))

(defmethod generate-macro-form ((macro-editor macro-edit-mode))
  (let ((name (intern (name macro-editor)))
        (commands (mapcar
                   (lambda (command) (write `(,(name command)) :stream nil))
                   (alexandria:hash-table-values (functions macro-editor)))))
    `(define-command-global ,name '() ,@commands)))

(define-command add-command (&optional (macro-editor (current-mode 'macro-edit-mode)))
  "Add a command to the macro."
  (let ((command 
          (first
           (prompt
            :prompt "Describe command"
            :sources (make-instance 'user-command-source)))))
    (add-function macro-editor command)))

(define-command save-macro (&optional (macro-editor (current-mode 'macro-edit-mode)))
  "Save the macro to the auto-config.lisp file."
  (alexandria:if-let ((macro-name (name macro-editor))
                      (functions (alexandria:hash-table-values (functions macro-editor))))
    (echo "Macro saved. ~a" macro-name)
    (echo "Macros require a name and functions.")))
