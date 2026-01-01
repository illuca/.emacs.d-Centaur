;; init-centaur-tabs.el --- Centaur tabs configuration -*- lexical-binding: t -*-

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
;; Centaur tabs settings migrated from the Purcell config.
;;

;;; Code:

(use-package centaur-tabs
  :demand t
  :hook ((after-init . centaur-tabs-mode)
         (after-init . global-tab-line-mode))
  :bind (("s-{" . centaur-tabs-backward)
         ("s-}" . centaur-tabs-forward)
         ("C-<prior>" . centaur-tabs-backward)
         ("C-<next>" . centaur-tabs-forward))
  :init
  (setq centaur-tabs-display-line 'tab-line
        centaur-tabs-display-line-format 'tab-line-format
        centaur-tabs-style "bar"
        centaur-tabs-height 32
        centaur-tabs-set-icons t
        centaur-tabs-set-bar 'under
        centaur-tabs-set-close-button nil
        centaur-tabs-set-modified-marker t
        centaur-tabs-modified-marker "*"
        centaur-tabs-label-fixed-length 0
        centaur-tabs-auto-scroll-flag t)
  :config
  (setq centaur-tabs-buffer-groups-function
        (if (and (featurep 'projectile)
                 (fboundp 'centaur-tabs-projectile-buffer-groups))
            #'centaur-tabs-projectile-buffer-groups
          #'centaur-tabs-buffer-groups))

  (when (featurep 'helm)
    (centaur-tabs-enable-buffer-reordering))

  (defun centaur-tabs--reset-tab-line ()
    "Ensure tab-line is driven by centaur-tabs."
    (when centaur-tabs-mode
      (kill-local-variable 'tab-line-format)
      (setq tab-line-format centaur-tabs-header-line-format)))
  (add-hook 'after-change-major-mode-hook #'centaur-tabs--reset-tab-line)
  (add-hook 'window-configuration-change-hook #'centaur-tabs-display-update)
  (centaur-tabs-display-update)

  (defun centaur-tabs-hide-tab (x)
    "Do not show buffer X in tabs."
    (let ((name (format "%s" x)))
      (or
       (string-prefix-p "*" name)
       (string-prefix-p " " name)
       (and (string-prefix-p "magit" name)
            (not (file-name-extension name)))
       (memq (buffer-local-value 'major-mode x)
             '(neotree-mode treemacs-mode)))))
  (setq centaur-tabs-hide-tab-function #'centaur-tabs-hide-tab)

  (with-eval-after-load 'centaur-tabs
    (set-face-attribute 'centaur-tabs-default nil
                        :background "#f0f0f0"
                        :foreground "#666666")
    (set-face-attribute 'centaur-tabs-selected nil
                        :background "#ffffff"
                        :foreground "#000000"
                        :box nil)
    (set-face-attribute 'centaur-tabs-unselected nil
                        :background "#e8e8e8"
                        :foreground "#666666"
                        :box nil)
    (set-face-attribute 'centaur-tabs-selected-modified nil
                        :background "#ffffff"
                        :foreground "#d75f00"
                        :box nil)
    (set-face-attribute 'centaur-tabs-unselected-modified nil
                        :background "#e8e8e8"
                        :foreground "#d75f00"
                        :box nil)
    (set-face-attribute 'centaur-tabs-active-bar-face nil
                        :background "#4078f2")
    (set-face-attribute 'centaur-tabs-modified-marker-selected nil
                        :foreground "#d75f00"
                        :background "#ffffff")
    (set-face-attribute 'centaur-tabs-modified-marker-unselected nil
                        :foreground "#d75f00"
                        :background "#e8e8e8")))

(provide 'init-centaur-tabs)
;;; init-centaur-tabs.el ends here
