;; (setq httpd-root default-directory)
;; (setq httpd-port 9000)

;; override this per-buffer to match on the target document.baseURI in
;; case you have many simultaneous skewer connections
(setq-local project-regexp nil)

(setq sibilant-preamble "")
(setq sibilant-postamble "")

(setq sibilant-program "~/node_modules/bin/sibilant")

(setq-local inferior-lisp-program sibilant-program)

(defun sibilant-mode/sibilize (sibilant)
  (shell-command-to-string
   (concat sibilant-program " -i " (prin1-to-string sibilant))))

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
  (let ((selected (buffer-substring beg end))
        (p-rx (if (local-variable-p 'project-regexp)
                  project-regexp
                nil)))
    (with-temp-buffer
      (let ((tbuf (current-buffer)))
        ;; open the project specific matcher
        (when p-rx
          (insert "(when (.test "
                  "(regex \"" p-rx "\") "
                  "document.baseURI)\n"))
        (insert sibilant-preamble)
        (insert selected)
        (insert sibilant-postamble)
        ;; close the project specific matcher
        (when p-rx
          (insert "\n)"))
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

(define-key sibilant-mode-map (kbd "C-c C-c") 'sibilant-mode/compile)
(define-key sibilant-mode-map (kbd "C-x C-e") 'sibilant-skewer-eval-preceding-sexp)
(define-key sibilant-mode-map (kbd "C-M-x") 'sibilant-skewer-eval-defun)

