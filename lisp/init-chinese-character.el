;; init-chinese-character.el --- CJK font alignment -*- lexical-binding: t -*-

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
;; Setup fonts for aligned CJK glyphs.
;;

;;; Code:

(defun my-choose-font-family (candidates)
  "Return the first available font family from CANDIDATES."
  (catch 'found
    (dolist (family candidates)
      (when (member family (font-family-list))
        (throw 'found family)))
    nil))

(defun my-install-fonts ()
  "Install recommended fonts on macOS using Homebrew."
  (interactive)
  (unless (eq system-type 'darwin)
    (user-error "Font auto-install is only supported on macOS"))
  (unless (executable-find "brew")
    (user-error "Homebrew not found. Install brew first, then rerun"))
  (when (y-or-n-p "Install Fira Code via Homebrew? ")
    (shell-command "brew tap homebrew/cask-fonts")
    (shell-command "brew install --cask font-fira-code")
    (message "Installed. Restart Emacs to pick up the font.")))

(defun my-fonts-report-missing (base-family cjk-family)
  "Report missing font families in the minibuffer."
  (unless base-family
    (message "Missing base font. Run M-x my-install-fonts or install Fira Code."))
  (unless cjk-family
    (message "Missing CJK font. Install PingFang SC or adjust CJK font list.")))

(defun my-setup-fonts ()
  "Setup fonts with CJK height alignment."
  (when (display-graphic-p)
    (let* ((base-family (my-choose-font-family '("Fira Code" "SF Mono" "Menlo" "Monaco")))
           (cjk-family (my-choose-font-family '("PingFang SC" "Microsoft Yahei UI" "Simhei")))
           (fontset-name "fontset-chinese"))
      (my-fonts-report-missing base-family cjk-family)
      (when base-family
        (set-face-attribute 'default nil
                            :family base-family
                            :height 120))

      (when cjk-family
        (set-fontset-font t 'han (font-spec :family cjk-family))
        (set-fontset-font t 'kana (font-spec :family cjk-family))
        (set-fontset-font t 'hangul (font-spec :family cjk-family)))

      (when (and base-family cjk-family)
        (condition-case err
            (progn
              (unless (member fontset-name (fontset-list))
                (create-fontset-from-fontset-spec
                 (format "-*-%s-normal-normal-normal-*-14-*-*-*-m-*-fontset-chinese"
                         base-family)))
              (when (member fontset-name (fontset-list))
                (set-frame-font fontset-name nil t)))
          (error (message "Skipping fontset setup: %s" (error-message-string err)))))

      (setq face-font-rescale-alist
            '(("PingFang SC" . 1.2)
              ("Microsoft Yahei UI" . 1.2)
              ("Simhei" . 1.2))))))

(my-setup-fonts)
(add-hook 'window-setup-hook #'my-setup-fonts)

(provide 'init-chinese-character)
;;; init-chinese-character.el ends here
