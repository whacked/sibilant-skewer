;; (setq httpd-root default-directory)

(setq sibilant-preamble "

")

(setq sibilant-program "~/node_modules/bin/sibilant")

(setq-local inferior-lisp-program sibilant-program)

(defun sibilant-mode/compile ()
  "Invoke the Sibilant compiler for the current buffer."
  (interactive)
  (if (string-match "\\.sib\\(ilant\\)?$"
                    buffer-file-name)
      ;; if we are working with a sibilant file,
      ;; output the js file in the same directory PLUS source map
      (progn
        (save-buffer)
        (call-process sibilant-program
                      nil nil nil
                      "--file" buffer-file-name
                      "--sourcemap"
                      "--output" default-directory)
        (message "Compiled with sourcemap to %s" default-directory))
    ;; else we are working with some arbitrary buffer
    (let ((output-name (format "%s.js" (file-name-sans-extension (file-relative-name buffer-file-name)))))
      (shell-command-on-region
       (point-min)
       (point-max)
       (concat sibilant-program " --input")
       output-name)
      (with-current-buffer (get-buffer output-name)
        (save-buffer))
      (message "Compiled to %s" output-name))))

(defun sibilant-skewer-send-region (beg end)
  (let ((selected (buffer-substring beg end)))
    (with-temp-buffer
      (let ((tbuf (current-buffer)))
        (insert sibilant-preamble)
        (insert selected)
        (call-process-region
         (point-min) (point-max)
         sibilant-program
         t ;; delete = replace region with eval output
         tbuf nil "--input")
        (skewer-eval (buffer-string) #'skewer-post-minibuffer)))))

(defun sibilant-skewer-eval-preceding-sexp ()
  (interactive)
  (save-excursion
    (let ((beg (progn (beginning-of-sexp)
                      (point)))
          (end (progn (end-of-sexp)
                      (point))))
      (sibilant-skewer-send-region beg end))))

(defun sibilant-skewer-eval-defun ()
  (interactive)
  (save-excursion
    (let ((beg (progn (beginning-of-defun)
                      (point)))
          (end (progn (end-of-defun)
                      (point))))
      (sibilant-skewer-send-region beg end))))

(define-key sibilant-mode-map (kbd "C-x C-e") 'sibilant-skewer-eval-preceding-sexp)
(define-key sibilant-mode-map (kbd "C-M-x") 'sibilant-skewer-eval-defun)

