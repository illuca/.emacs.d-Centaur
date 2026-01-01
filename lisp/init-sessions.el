;; init-sessions.el --- Save and restore sessions -*- lexical-binding: t -*-

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
;; Desktop/session settings migrated from the Purcell config.
;;

;;; Code:

(defun sanityinc/time-subtract-millis (b a)
  "Return time difference between B and A in milliseconds."
  (* 1000.0 (float-time (time-subtract b a))))

(use-package desktop
  :ensure nil
  :init
  (setq desktop-path (list user-emacs-directory)
        desktop-auto-save-timeout 600
        desktop-load-locked-desktop t)
  :config
  (desktop-save-mode 1))

(defun sanityinc/desktop-time-restore (orig &rest args)
  (let ((start-time (current-time)))
    (prog1
        (apply orig args)
      (message "Desktop restored in %.2fms"
               (sanityinc/time-subtract-millis (current-time)
                                               start-time)))))
(advice-add 'desktop-read :around #'sanityinc/desktop-time-restore)

(defun sanityinc/desktop-time-buffer-create (orig ver filename &rest args)
  (let ((start-time (current-time)))
    (prog1
        (apply orig ver filename args)
      (message "Desktop: %.2fms to restore %s"
               (sanityinc/time-subtract-millis (current-time)
                                               start-time)
               (when filename
                 (abbreviate-file-name filename))))))
(advice-add 'desktop-create-buffer :around #'sanityinc/desktop-time-buffer-create)

(use-package session
  :init
  (setq session-save-file (locate-user-emacs-file ".session")
        session-name-disable-regexp "\\(?:\\`'/tmp\\|\\.git/[A-Z_]+\\'\\)"
        session-save-file-coding-system 'utf-8)
  :hook (after-init . session-initialize))

(setq desktop-globals-to-save
      '((comint-input-ring        . 50)
        (compile-history          . 30)
        desktop-missing-file-warning
        (dired-regexp-history     . 20)
        (extended-command-history . 30)
        (face-name-history        . 20)
        (file-name-history        . 100)
        (grep-find-history        . 30)
        (grep-history             . 30)
        (ivy-history              . 100)
        (magit-revision-history   . 50)
        (minibuffer-history       . 50)
        (org-clock-history        . 50)
        (org-refile-history       . 50)
        (org-tags-history         . 50)
        (query-replace-history    . 60)
        (read-expression-history  . 60)
        (regexp-history           . 60)
        (regexp-search-ring       . 20)
        register-alist
        (search-ring              . 20)
        (shell-command-history    . 50)
        tags-file-name
        tags-table-list))

(provide 'init-sessions)
;;; init-sessions.el ends here
