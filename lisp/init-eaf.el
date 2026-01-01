;; init-eaf.el --- Initialize EAF.	-*- lexical-binding: t -*-

;; Copyright (C) 2019-2025 Vincent Zhang

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
;;

;;; Commentary:
;;
;; Emacs Application Framework (EAF).
;;

;;; Code:

(eval-when-compile
  (require 'init-const))

(defconst eaf-dir (expand-file-name "emacs-application-framework" user-emacs-directory))

(when (file-directory-p eaf-dir)
  (add-to-list 'load-path eaf-dir)
  (require 'eaf)
  (setq eaf-find-file-advisor-enable t
        eaf-dired-advisor-enable t)
  (require 'eaf-browser)
  (require 'eaf-pdf-viewer)
  (require 'eaf-org-previewer)
  (require 'eaf-video-player)
  (require 'eaf-map)
  (require 'eaf-music-player)
  (with-eval-after-load 'pdf-view
    ;; Prefer EAF for PDFs by removing pdf-tools auto-mode mappings.
    (setq auto-mode-alist (rassq-delete-all 'pdf-view-mode auto-mode-alist))
    (setq magic-mode-alist (rassq-delete-all 'pdf-view-mode magic-mode-alist))
    (setq magic-fallback-mode-alist (rassq-delete-all 'pdf-view-mode magic-fallback-mode-alist))))

(provide 'init-eaf)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-eaf.el ends here
