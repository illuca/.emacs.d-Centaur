;; init-cloudinary-simple.el --- Cloudinary upload using curl -*- lexical-binding: t -*-

;; Copyright (C) 2006-2025 Vincent Zhang

;; Author: Vincent Zhang <seagle0128@gmail.com>
;; URL: https://github.com/seagle0128/.emacs.d

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Simple Cloudinary upload helpers migrated from the Purcell config.
;;

;;; Code:

(require 'json)
(require 'subr-x)

;; Configuration (loaded from init-local.el)
(defvar cloudinary-cloud-name)
(defvar cloudinary-upload-preset)

(defun cloudinary-upload-file-curl (file-path)
  "Upload FILE-PATH to Cloudinary using curl.
Return the secure URL of the uploaded image."
  (unless (and cloudinary-cloud-name
               (not (string-empty-p cloudinary-cloud-name)))
    (user-error "Please set cloudinary-cloud-name in init-local.el"))

  (unless (and cloudinary-upload-preset
               (not (string-empty-p cloudinary-upload-preset)))
    (user-error "Please set cloudinary-upload-preset in init-local.el"))

  (let* ((url (format "https://api.cloudinary.com/v1_1/%s/image/upload"
                      cloudinary-cloud-name))
         (command (format "curl -s -X POST '%s' -F 'upload_preset=%s' -F 'file=@%s'"
                          url
                          cloudinary-upload-preset
                          (shell-quote-argument file-path)))
         (output (shell-command-to-string command)))

    (condition-case err
        (let* ((json-response (json-read-from-string output))
               (secure-url (alist-get 'secure_url json-response))
               (error-msg (alist-get 'error json-response)))

          (cond
           (error-msg
            (user-error "Cloudinary error: %s"
                        (or (alist-get 'message error-msg)
                            (format "%S" error-msg))))
           (secure-url
            (message "Uploaded: %s" secure-url)
            secure-url)
           (t
            (user-error "Upload failed: %s" output))))

      (error
       (user-error "Failed to parse response: %s\nOutput: %s"
                   (error-message-string err)
                   output)))))

(defun cloudinary-org-paste-image ()
  "Paste image from clipboard, upload to Cloudinary, insert link in org-mode.
If no image in clipboard, fall back to normal yank."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))

  (let ((temp-file (make-temp-file "cloudinary-" nil ".png")))
    (unwind-protect
        (let ((exit-code (call-process "pngpaste" nil nil nil temp-file)))
          (if (= exit-code 0)
              (progn
                (message "Uploading to Cloudinary...")
                (let ((url (cloudinary-upload-file-curl temp-file)))
                  (insert (format "[[%s]]\n" url))
                  (run-at-time 0.1 nil #'org-display-inline-images)
                  (message "Image inserted.")))
            (yank)))
      (when (file-exists-p temp-file)
        (delete-file temp-file)))))

(defun cloudinary-org-screenshot ()
  "Take screenshot, upload to Cloudinary, insert link in org-mode."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))

  (let ((temp-file (make-temp-file "cloudinary-screenshot-" nil ".png")))
    (unwind-protect
        (progn
          (message "Select area for screenshot...")
          (let ((exit-code (call-process "screencapture" nil nil nil "-i" temp-file)))
            (unless (and (= exit-code 0) (file-exists-p temp-file))
              (user-error "Screenshot cancelled")))

          (message "Uploading to Cloudinary...")
          (let ((url (cloudinary-upload-file-curl temp-file)))
            (insert (format "[[%s]]\n" url))
            (run-at-time 0.1 nil #'org-display-inline-images)
            (message "Screenshot inserted.")))
      (when (file-exists-p temp-file)
        (delete-file temp-file)))))

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "s-v") #'cloudinary-org-paste-image)
  (define-key org-mode-map (kbd "s-S") #'cloudinary-org-screenshot))

(provide 'init-cloudinary-simple)
;;; init-cloudinary-simple.el ends here
