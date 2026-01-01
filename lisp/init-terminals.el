;; init-terminals.el --- Terminal emulators -*- lexical-binding: t -*-

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
;; Extra eat settings migrated from the Purcell config.
;;

;;; Code:

(require 'cl-lib)

(use-package eat
  :commands (eat eat-other-window)
  :init
  (setq eat-shell (or (getenv "SHELL") "/bin/zsh")
        eat-query-before-killing-running-terminal nil
        eat-term-scrollback-size (* 2 1024 1024)
        eat-term-name #'sanityinc/eat-term-get-suitable-term-name
        eat-enable-yank-to-terminal t
        eat-term-inside-emacs (format "%s,eat" emacs-version))
  :config
  (defun sanityinc/on-eat-exit (process)
    (when (zerop (process-exit-status process))
      (kill-buffer)
      (unless (eq (selected-window) (next-window))
        (delete-window))))
  (add-hook 'eat-exit-hook #'sanityinc/on-eat-exit)

  (defun sanityinc/eat-term-get-suitable-term-name (&optional display)
    "Version of `eat-term-get-suitable-term-name' with common TERM values."
    (let ((colors (display-color-cells display)))
      (cond ((> colors 8) "xterm-256color")
            ((> colors 1) "xterm-color")
            (t "xterm"))))

  (with-eval-after-load 'eat
    (when (boundp 'eat-semi-char-non-bound-keys)
      (custom-set-variables
       `(eat-semi-char-non-bound-keys
         (quote ,(cons [?\e ?w]
                       (cl-remove [?\e ?w] eat-semi-char-non-bound-keys
                                  :test 'equal))))))))

(defvar sanityinc/eat-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "t") #'eat-other-window)
    map)
  "Prefix map for commands that create and manipulate eat buffers.")
(fset 'sanityinc/eat-map sanityinc/eat-map)

(global-set-key (kbd "C-c t") 'sanityinc/eat-map)

(provide 'init-terminals)
;;; init-terminals.el ends here
