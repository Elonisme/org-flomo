;;; org-flomo.el --- Emacs integration for Flomo -*- lexical-binding: t -*-
;;
;; Author: Elon Li <elonisme@keemail.me>
;; Version: 1.5
;; Package-Requires: ((json "1.0")) ; 如果有依赖的话，添加在这里
;; Keywords: flomo, integration, notes
;; URL: https://github.com/elonisme/org-flomo
;;
;;; Commentary:
;;
;; org-flomo.el provides integration with Flomo (https://flomoapp.com/), a note-taking service.
;; It allows you to send notes to Flomo from within Emacs.
;;
;;; Code:
(require 'json)

(defun send-json-post-request (api content)
  "Send a JSON POST request to the specified URL with the given JSON data."
  (setq ApiHead "https://flomoapp.com/iwh/")
  (setq url (concat ApiHead api))
  (setq json-data "{\"content\": \"\"}")
  (setq parsed-data (json-parse-string json-data :object-type 'hash-table))
  (puthash "content" content parsed-data)
  
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/json")))
         (url-request-data (json-encode parsed-data))
         (response-buffer (url-retrieve-synchronously url)))
    (with-current-buffer response-buffer
      (goto-char (point-min))
      (re-search-forward "^$")
      (setq response-body (buffer-substring (point) (point-max)))
      (kill-buffer response-buffer)))
  (message "Response: %s" response-body))

(defun extract-flomo-src-contents ()
  (save-excursion
    (goto-char (point-min))
    (let (contents result)
      (while (re-search-forward "#\\+BEGIN_SRC flomo" nil t)
        (setq contents (buffer-substring (point) (progn (re-search-forward "#\\+END_SRC" nil t) (match-beginning 0))))
        (push contents result))
      (reverse result))))


(defun read-filtered-file-contents (file-path)
  "Read and return the contents of a file as a filtered string."
  (with-temp-buffer
    (insert-file-contents file-path)
    (let ((file-contents (buffer-string)))
      ;; 使用正则表达式替换掉不符合要求的字符
      (setq file-contents (replace-regexp-in-string "[^a-zA-Z0-9/]" "" file-contents))
      file-contents)))

(defun send-to-flomo ()
  (interactive)
  (setq flomo-contents (extract-flomo-src-contents))
  (setq file-path "~/.emacs.d/org-flomo/FlomoApi.txt")
  (setq api (read-filtered-file-contents file-path))
  (dolist (content flomo-contents)
      (message "Found Flomo source contents: %s" content)
      (send-json-post-request api content)
      )
  )

(provide 'org-flomo)
;;; org-flomo.el ends here
