;; init-neotree.el --- Neotree file explorer -*- lexical-binding: t -*-

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
;; Neotree settings migrated from the Purcell config.
;;

;;; Code:

(use-package neotree
  :commands (neotree-toggle neotree-find neotree-dir)
  :bind (("C-x t t" . neotree-toggle)
         ("C-x t f" . neotree-find)
         ("C-x t d" . neotree-dir))
  :init
  (setq neo-window-width 35
        neo-window-fixed-size nil
        neo-show-hidden-files t
        neo-autorefresh t
        neo-smart-open t
        neo-persist-show nil)
  :config
  (if (require 'all-the-icons nil t)
      (setq neo-theme 'icons)
    (setq neo-theme 'classic))

  (with-eval-after-load 'projectile
    (bind-key "C-x t p" #'neotree-projectile-action)))

(provide 'init-neotree)
;;; init-neotree.el ends here
