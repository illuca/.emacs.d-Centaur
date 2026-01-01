;; init-basic-editor.el --- Basic editor conveniences -*- lexical-binding: t -*-

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
;; Minimal editor-friendly defaults, migrated from the Purcell config.
;;

;;; Code:

(eval-when-compile
  (require 'init-const))

(require 'cl-lib)
(require 'seq)

(defun basic-editor-redo ()
  "Redo the last undone change."
  (interactive)
  (cond
   ((fboundp 'undo-redo) (undo-redo))
   ((fboundp 'redo) (redo))
   (t (message "Redo not available in this Emacs build."))))

(defun basic-editor-save-buffer ()
  "Save the current buffer, using a GUI save panel when needed."
  (interactive)
  (if buffer-file-name
      (save-buffer)
    (let ((use-file-dialog t)
          (use-dialog-box t))
      (call-interactively #'write-file))))

(defun basic-editor-find-file ()
  "Open a file using native macOS Finder dialog when available."
  (interactive)
  (if (and sys/macp
           (fboundp 'ns-read-file-name))
      (let ((file (ns-read-file-name "Open file: "
                                     (or default-directory "~")
                                     nil nil nil nil)))
        (when file
          (find-file file)))
    (let ((use-file-dialog t)
          (use-dialog-box t)
          (completing-read-function #'completing-read-default)
          (read-file-name-function #'read-file-name-default))
      (call-interactively #'find-file))))

(defun basic-editor-new-empty-buffer ()
  "Create and switch to a new empty buffer."
  (interactive)
  (let ((buffer (generate-new-buffer "untitled")))
    (switch-to-buffer buffer)
    (funcall initial-major-mode)
    (setq buffer-offer-save t)))

(defun basic-editor-kill-buffer-and-window ()
  "Kill the current buffer and delete its window when possible."
  (interactive)
  (if (one-window-p t)
      (kill-current-buffer)
    (kill-buffer-and-window)))

(defun basic-editor-kill-buffer-and-window-simple ()
  "Kill buffer and window with single confirmation if modified."
  (interactive)
  (if (and (buffer-modified-p)
           (buffer-file-name))
      (when (y-or-n-p (format "Buffer %s modified. Close without saving? " (buffer-name)))
        (cl-letf (((symbol-function 'buffer-modified-p)
                   (lambda (&optional buffer) nil)))
          (if (one-window-p t)
              (kill-buffer (current-buffer))
            (kill-buffer-and-window))))
    (if (one-window-p t)
        (kill-current-buffer)
      (kill-buffer-and-window))))

(defun basic-editor-quit-simple ()
  "Quit Emacs with single confirmation if there are modified file buffers."
  (interactive)
  (let ((modified-files (seq-filter (lambda (buf)
                                       (and (buffer-modified-p buf)
                                            (buffer-file-name buf)))
                                     (buffer-list))))
    (if modified-files
        (when (y-or-n-p "Modified files exist. Quit without saving? ")
          (let ((kill-buffer-query-functions nil)
                (kill-emacs-query-functions nil)
                (kill-emacs-hook nil))
            (kill-emacs)))
      (kill-emacs))))

(defun basic-editor-split-right-and-focus ()
  "Split the window to the right and focus the new window."
  (interactive)
  (select-window (split-window-right)))

(defun basic-editor-comment-toggle ()
  "Toggle comment for the current line or active region."
  (interactive)
  (if (fboundp 'comment-line)
      (comment-line 1)
    (comment-dwim nil)))

(defun basic-editor-duplicate ()
  "Duplicate the current line or active region."
  (interactive)
  (let ((origin (point)))
    (if (use-region-p)
        (let ((text (buffer-substring (region-beginning) (region-end))))
          (save-excursion
            (goto-char (region-end))
            (insert text)))
      (let ((line (buffer-substring (line-beginning-position)
                                    (line-end-position))))
        (save-excursion
          (goto-char (line-end-position))
          (newline)
          (insert line))))
    (goto-char origin)))

(defun basic-editor-indent ()
  "Indent the active region or current line."
  (interactive)
  (if (use-region-p)
      (indent-region (region-beginning) (region-end))
    (indent-for-tab-command)))

(defun basic-editor-outdent ()
  "Outdent the active region or current line."
  (interactive)
  (let ((offset (- tab-width)))
    (if (use-region-p)
        (indent-rigidly (region-beginning) (region-end) offset)
      (indent-rigidly (line-beginning-position) (line-end-position) offset))))

(defun basic-editor-delete-to-bol ()
  "Delete text from point back to the beginning of the line."
  (interactive)
  (kill-line 0))

(defvar basic-editor--shift-click-origin nil)

(defun basic-editor-shift-click-start (event)
  "Remember point so shift-click can select a region on mouse release."
  (interactive "e")
  (mouse-minibuffer-check event)
  (let* ((posn (event-start event))
         (window (posn-window posn)))
    (when (windowp window)
      (with-selected-window window
        (setq basic-editor--shift-click-origin (copy-marker (point)))))))

(defun basic-editor-shift-click-select (event)
  "Select the region between saved point and the clicked location."
  (interactive "e")
  (mouse-minibuffer-check event)
  (let* ((posn (event-start event))
         (window (posn-window posn))
         (target (posn-point posn))
         (origin basic-editor--shift-click-origin))
    (setq basic-editor--shift-click-origin nil)
    (when (markerp origin)
      (unless (marker-buffer origin)
        (set-marker origin nil)))
    (when (windowp window)
      (select-window window)
      (cond
       ((and (markerp origin)
             (marker-buffer origin)
             (eq (marker-buffer origin) (current-buffer))
             (numberp target))
        (set-mark (marker-position origin))
        (goto-char target)
        (setq deactivate-mark nil)
        (activate-mark))
       (t
        (mouse-set-point event))))))

(defvar basic-editor--nav-back-stack nil)
(defvar basic-editor--nav-forward-stack nil)
(defvar basic-editor--nav-last-location nil)
(defvar basic-editor--nav-hooks-enabled nil)

(defconst basic-editor--nav-min-distance 80)
(defconst basic-editor--nav-ignored-commands
  '(basic-editor-nav-back
    basic-editor-nav-forward
    self-insert-command
    backward-char
    forward-char
    previous-line
    next-line
    left-char
    right-char
    backward-word
    forward-word
    beginning-of-line
    end-of-line
    scroll-up-command
    scroll-down-command
    mwheel-scroll
    mouse-set-point
    mouse-drag-region))

(defun basic-editor--nav--remember-location ()
  (unless (minibufferp)
    (setq basic-editor--nav-last-location
          (cons (current-buffer) (point)))))

(defun basic-editor--nav--push (buffer position)
  (let ((marker (with-current-buffer buffer (copy-marker position)))
        (top (car basic-editor--nav-back-stack)))
    (unless (and top
                 (marker-buffer top)
                 (eq (marker-buffer top) buffer)
                 (= (marker-position top) position))
      (push marker basic-editor--nav-back-stack)
      (setq basic-editor--nav-forward-stack nil))))

(defun basic-editor--nav--record-location ()
  (when (and basic-editor--nav-last-location
             (not (minibufferp))
             (not (memq this-command basic-editor--nav-ignored-commands)))
    (let* ((last-buffer (car basic-editor--nav-last-location))
           (last-point (cdr basic-editor--nav-last-location))
           (distance (abs (- (point) last-point))))
      (when (and (buffer-live-p last-buffer)
                 (or (not (eq last-buffer (current-buffer)))
                     (>= distance basic-editor--nav-min-distance)))
        (basic-editor--nav--push last-buffer last-point)))))

(defun basic-editor--nav--pop (stack-var)
  (let ((stack (symbol-value stack-var)))
    (while (and stack (not (marker-buffer (car stack))))
      (setq stack (cdr stack)))
    (let ((marker (car stack)))
      (set stack-var (cdr stack))
      marker)))

(defun basic-editor--nav--push-current (stack-var)
  (let ((marker (copy-marker (point))))
    (set stack-var (cons marker (symbol-value stack-var)))))

(defun basic-editor-nav-back ()
  "Move to the previous location in navigation history."
  (interactive)
  (let ((marker (basic-editor--nav--pop 'basic-editor--nav-back-stack)))
    (if (not marker)
        (message "No previous location.")
      (basic-editor--nav--push-current 'basic-editor--nav-forward-stack)
      (switch-to-buffer (marker-buffer marker))
      (goto-char (marker-position marker)))))

(defun basic-editor-nav-forward ()
  "Move to the next location in navigation history."
  (interactive)
  (let ((marker (basic-editor--nav--pop 'basic-editor--nav-forward-stack)))
    (if (not marker)
        (message "No next location.")
      (basic-editor--nav--push-current 'basic-editor--nav-back-stack)
      (switch-to-buffer (marker-buffer marker))
      (goto-char (marker-position marker)))))

(defun basic-editor--enable-navigation-history ()
  (unless basic-editor--nav-hooks-enabled
    (setq basic-editor--nav-hooks-enabled t)
    (add-hook 'pre-command-hook #'basic-editor--nav--remember-location)
    (add-hook 'post-command-hook #'basic-editor--nav--record-location)))

(defconst basic-editor--terminal-buffer-name "*basic-editor-terminal*")
(defconst basic-editor--terminal-buffer-base "basic-editor-terminal")

(defun basic-editor--ensure-terminal-buffer ()
  (or (get-buffer basic-editor--terminal-buffer-name)
      (save-window-excursion
        (cond
         ((fboundp 'eat)
          (let ((buf (eat)))
            (with-current-buffer buf
              (rename-buffer basic-editor--terminal-buffer-name t))))
         ((fboundp 'vterm)
          (vterm basic-editor--terminal-buffer-name))
         (t
          (ansi-term (or (getenv "SHELL") shell-file-name)
                     basic-editor--terminal-buffer-base)))
        (get-buffer basic-editor--terminal-buffer-name))))

(defun basic-editor-open-terminal ()
  "Open or focus the integrated terminal buffer."
  (interactive)
  (let* ((buffer (basic-editor--ensure-terminal-buffer))
         (window (get-buffer-window buffer)))
    (if (window-live-p window)
        (select-window window)
      (pop-to-buffer buffer))))

(defun basic-editor--bottom-side-window-p (window)
  (let ((edges (window-edges window)))
    (= (nth 3 edges) (frame-height))))

(defun basic-editor--find-bottom-terminal-window (buffer)
  (let ((found nil))
    (dolist (window (window-list))
      (when (and (eq (window-buffer window) buffer)
                 (basic-editor--bottom-side-window-p window))
        (setq found window)))
    found))

(defun basic-editor--main-window ()
  (let ((selected (selected-window)))
    (if (window-parameter selected 'window-side)
        (let ((found nil))
          (dolist (window (window-list))
            (when (and (not found)
                       (not (window-parameter window 'window-side)))
              (setq found window)))
          (or found selected))
      selected)))

(defun basic-editor-open-terminal-below ()
  "Open or focus the integrated terminal at the bottom."
  (interactive)
  (let* ((buffer (basic-editor--ensure-terminal-buffer))
         (window (basic-editor--find-bottom-terminal-window buffer)))
    (if (window-live-p window)
        (select-window window)
      (let ((target (basic-editor--main-window)))
        (select-window target)
        (let ((new-window (split-window-below)))
          (set-window-buffer new-window buffer)
          (select-window new-window))))))

(defvar basic-editor--override-keys-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "s-b") #'basic-editor-open-terminal-below)
    (define-key map (kbd "s-2") #'basic-editor-open-terminal-right)
    (define-key map (kbd "s-p") #'execute-extended-command)
    (define-key map (kbd "s-n") #'basic-editor-new-empty-buffer)
    (define-key map (kbd "s-N") #'make-frame-command)
    (define-key map (kbd "s-<left>") #'move-beginning-of-line)
    (define-key map (kbd "s-<right>") #'move-end-of-line)
    (define-key map (kbd "s-<up>") #'beginning-of-buffer)
    (define-key map (kbd "s-<down>") #'end-of-buffer)
    (define-key map (kbd "S-<down-mouse-1>") #'basic-editor-shift-click-start)
    (define-key map (kbd "S-<mouse-1>") #'basic-editor-shift-click-select)
    map)
  "Keymap for overriding macOS keybindings that must win everywhere.")

(define-minor-mode basic-editor--override-keys-mode
  "Global overrides for a few macOS keybindings."
  :global t
  :keymap basic-editor--override-keys-mode-map)

(defun basic-editor--right-side-window-p (window)
  (let ((edges (window-edges window)))
    (= (nth 2 edges) (frame-width))))

(defun basic-editor--rightmost-window ()
  (let ((rightmost nil)
        (right-edge -1))
    (dolist (window (window-list))
      (let ((edge (nth 2 (window-edges window))))
        (when (> edge right-edge)
          (setq right-edge edge)
          (setq rightmost window))))
    rightmost))

(defun basic-editor--find-right-terminal-window (buffer)
  (let ((found nil))
    (dolist (window (window-list))
      (when (and (eq (window-buffer window) buffer)
                 (basic-editor--right-side-window-p window))
        (setq found window)))
    found))

(defun basic-editor-open-terminal-right ()
  "Open or focus the integrated terminal on the right side."
  (interactive)
  (let* ((buffer (basic-editor--ensure-terminal-buffer))
         (window (basic-editor--find-right-terminal-window buffer)))
    (if (window-live-p window)
        (select-window window)
      (let ((target (basic-editor--rightmost-window)))
        (select-window target)
        (let ((new-window (split-window-right)))
          (set-window-buffer new-window buffer)
          (select-window new-window))))))

(defvar basic-editor--sidebar-window nil)
(defvar basic-editor--sidebar-prev-window nil)

(defun basic-editor--sidebar-root ()
  (let ((project (when (fboundp 'project-current)
                   (project-current nil))))
    (if project
        (project-root project)
      default-directory)))

(defun basic-editor--find-sidebar-window ()
  (or (and (window-live-p basic-editor--sidebar-window)
           basic-editor--sidebar-window)
      (let ((found nil))
        (dolist (window (window-list))
          (when (window-parameter window 'basic-editor-sidebar)
            (setq found window)))
        found)))

(defun basic-editor-toggle-sidebar ()
  "Toggle a left-side file browser and focus it."
  (interactive)
  (let ((window (basic-editor--find-sidebar-window)))
    (if (window-live-p window)
        (progn
          (delete-window window)
          (setq basic-editor--sidebar-window nil)
          (when (window-live-p basic-editor--sidebar-prev-window)
            (select-window basic-editor--sidebar-prev-window))
          (setq basic-editor--sidebar-prev-window nil))
      (let* ((root (basic-editor--sidebar-root))
             (buffer (dired-noselect root))
             (prev (selected-window))
             (side-window (display-buffer-in-side-window
                           buffer '((side . left)
                                    (slot . 0)
                                    (window-width . 0.25)))))
        (set-window-parameter side-window 'basic-editor-sidebar t)
        (setq basic-editor--sidebar-window side-window)
        (setq basic-editor--sidebar-prev-window prev)
        (select-window side-window)))))

(defun basic-editor-toggle-project-sidebar ()
  "Toggle a project sidebar, preferring Treemacs when available."
  (interactive)
  (cond
   ((fboundp 'treemacs) (treemacs))
   ((fboundp 'neotree-toggle) (neotree-toggle))
   (t (basic-editor-toggle-sidebar))))

(defun basic-editor--set-mac-keys ()
  (when sys/macp
    (setq mac-command-modifier 'super)
    (setq mac-option-modifier 'meta)
    (setq use-file-dialog t)
    (setq use-dialog-box t)
    (bind-keys
     ("s-z" . undo)
     ("s-Z" . basic-editor-redo)
     ("s-x" . kill-region)
     ("s-c" . kill-ring-save)
     ("s-v" . yank)
     ("s-a" . mark-whole-buffer)
     ("s-s" . basic-editor-save-buffer)
     ("s-o" . basic-editor-find-file)
     ("s-e" . consult-recent-file)
     ("s-P" . execute-extended-command)
     ("s-n" . basic-editor-new-empty-buffer)
     ("s-N" . make-frame-command)
     ("s-w" . basic-editor-kill-buffer-and-window-simple)
     ("s-q" . basic-editor-quit-simple)
     ("s-f" . isearch-forward)
     ("s-[" . basic-editor-nav-back)
     ("s-]" . basic-editor-nav-forward)
     ("s-E" . basic-editor-toggle-project-sidebar)
     ("s-/" . basic-editor-comment-toggle)
     ("s-d" . basic-editor-duplicate)
     ("s-\\" . basic-editor-split-right-and-focus)
     ;("<tab>" . basic-editor-indent)
     ;("<backtab>" . basic-editor-outdent)
     ("s-<delete>" . basic-editor-delete-to-bol)
     ("s-<backspace>" . basic-editor-delete-to-bol)
     ("s-<left>" . move-beginning-of-line)
     ("s-<right>" . move-end-of-line)
     ("s-<up>" . beginning-of-buffer)
     ("s-<down>" . end-of-buffer)
     ("s-r" . eval-last-sexp)
     ("s-R" . eval-print-last-sexp)
     ("<escape>" . keyboard-quit))
    (basic-editor--override-keys-mode 1)
    (basic-editor--enable-navigation-history)))

(defun basic-editor--apply-super-nav-keys ()
  "Re-apply macOS-style navigation keys after other hooks."
  (when sys/macp
    (global-set-key (kbd "s-<left>") #'move-beginning-of-line)
    (global-set-key (kbd "s-<right>") #'move-end-of-line)
    (global-set-key (kbd "s-<up>") #'beginning-of-buffer)
    (global-set-key (kbd "s-<down>") #'end-of-buffer)))

(defun basic-editor--disable-tool-bar (&optional frame)
  "Disable the tool bar for FRAME and future frames."
  (with-selected-frame (or frame (selected-frame))
    (when (fboundp 'tool-bar-mode)
      (tool-bar-mode -1)))
  (setf (alist-get 'tool-bar-lines default-frame-alist) 0)
  (setf (alist-get 'tool-bar-lines initial-frame-alist) 0))

(basic-editor--disable-tool-bar)
(add-hook 'after-init-hook #'basic-editor--disable-tool-bar t)
(add-hook 'after-make-frame-functions #'basic-editor--disable-tool-bar t)

(menu-bar-mode 1)
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode 1))

(delete-selection-mode 1)
(transient-mark-mode 1)

(setq select-enable-clipboard t)
(setq-default cursor-type 'bar)

(basic-editor--set-mac-keys)
(add-hook 'after-init-hook #'basic-editor--apply-super-nav-keys t)

(provide 'init-basic-editor)
;;; init-basic-editor.el ends here
