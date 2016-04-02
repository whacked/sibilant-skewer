;; (setq httpd-root default-directory)

(setq sibilant-preamble "

")

(setq sibilant-program "~/node_modules/bin/sibilant")

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

