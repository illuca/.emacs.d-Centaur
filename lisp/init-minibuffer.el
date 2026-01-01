;; init-minibuffer.el --- Minibuffer helpers -*- lexical-binding: t -*-

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
;; Minibuffer ESC bindings migrated from the Purcell config.
;;

;;; Code:

(defun sanityinc/setup-minibuffer-escape ()
  "Bind escape key to abort in minibuffer keymaps."
  (dolist (map-sym '(minibuffer-local-map
                     minibuffer-local-ns-map
                     minibuffer-local-completion-map
                     minibuffer-local-must-match-map
                     minibuffer-local-isearch-map))
    (when (boundp map-sym)
      (define-key (symbol-value map-sym) (kbd "<escape>") #'abort-recursive-edit)
      (define-key (symbol-value map-sym) [escape] #'abort-recursive-edit))))

(sanityinc/setup-minibuffer-escape)

(with-eval-after-load 'vertico
  (define-key vertico-map (kbd "<escape>") #'abort-recursive-edit)
  (define-key vertico-map [escape] #'abort-recursive-edit))

(provide 'init-minibuffer)
;;; init-minibuffer.el ends here
