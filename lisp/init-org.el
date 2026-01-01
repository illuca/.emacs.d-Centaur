;; init-org.el --- Initialize Org configurations.	-*- lexical-binding: t -*-

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
;;

;;; Commentary:
;;
;; Org configurations.
;;

;;; Code:

(eval-when-compile
  (require 'init-const)
  (require 'init-custom))

(defvar sanityinc/org-global-prefix-map (make-sparse-keymap)
  "A keymap for handy global access to org helpers, particularly clocking.")

(use-package org
  :ensure nil
  :custom-face (org-ellipsis ((t (:foreground unspecified))))
  :pretty-hydra
  ;; See `org-structure-template-alist'
  ((:title (pretty-hydra-title "Org Template" 'sucicon "nf-custom-orgmode" :face 'nerd-icons-green)
    :color blue :quit-key ("q" "C-g"))
   ("Basic"
    (("a" (hot-expand "<a") "ascii")
     ("c" (hot-expand "<c") "center")
     ("C" (hot-expand "<C") "comment")
     ("x" (hot-expand "<e") "example")
     ("E" (hot-expand "<E") "export")
     ("h" (hot-expand "<h") "html")
     ("l" (hot-expand "<l") "latex")
     ("n" (hot-expand "<n") "note")
     ("o" (hot-expand "<q") "quote")
     ("v" (hot-expand "<v") "verse"))
    "Head"
    (("i" (hot-expand "<i") "index")
     ("A" (hot-expand "<A") "ASCII")
     ("I" (hot-expand "<I") "INCLUDE")
     ("H" (hot-expand "<H") "HTML")
     ("L" (hot-expand "<L") "LaTeX"))
    "Source"
    (("s" (hot-expand "<s") "src")
     ("e" (hot-expand "<s" "emacs-lisp") "emacs-lisp")
     ("y" (hot-expand "<s" "python :results output") "python")
     ("p" (hot-expand "<s" "perl") "perl")
     ("w" (hot-expand "<s" "powershell") "powershell")
     ("r" (hot-expand "<s" "ruby") "ruby")
     ("S" (hot-expand "<s" "sh") "sh")
     ("g" (hot-expand "<s" "go :imports '\(\"fmt\"\)") "golang"))
    "Misc"
    (("m" (hot-expand "<s" "mermaid :file chart.png") "mermaid")
     ("u" (hot-expand "<s" "plantuml :file chart.png") "plantuml")
     ("Y" (hot-expand "<s" "ipython :session :exports both :results raw drawer\n$0") "ipython")
     ("P" (progn
            (insert "#+HEADERS: :results output :exports both :shebang \"#!/usr/bin/env perl\"\n")
            (hot-expand "<s" "perl")) "Perl tangled")
     ("<" self-insert-command "ins"))))
  :bind (("C-c a" . org-agenda)
         ("C-c b" . org-switchb)
         ("C-c l" . org-store-link)
         ("C-c o" . sanityinc/org-global-prefix-map)
         ("C-c x" . org-capture)
         :map org-mode-map
         ("<" . (lambda ()
                  "Insert org template."
                  (interactive)
                  (if (or (region-active-p) (looking-back "^\s*" 1))
                      (org-hydra/body)
                    (self-insert-command 1)))))
  :hook (((org-babel-after-execute org-mode) . org-redisplay-inline-images) ; display image
         (org-indent-mode . (lambda()
                              (diminish 'org-indent-mode)
                              ;; HACK: Prevent text moving around while using brackets
                              ;; @see https://github.com/seagle0128/.emacs.d/issues/88
                              (make-variable-buffer-local 'show-paren-mode)
                              (setq show-paren-mode nil))))
  :config
  ;; For hydra
  (defun hot-expand (str &optional mod)
    "Expand org template.

STR is a structure template string recognised by org like <s. MOD is a
string with additional parameters to add the begin line of the
structure element. HEADER string includes more parameters that are
prepended to the element after the #+HEADER: tag."
    (let (text)
      (when (region-active-p)
        (setq text (buffer-substring (region-beginning) (region-end)))
        (delete-region (region-beginning) (region-end)))
      (insert str)
      (if (fboundp 'org-try-structure-completion)
          (org-try-structure-completion) ; < org 9
        (progn
          ;; New template expansion since org 9
          (require 'org-tempo nil t)
          (org-tempo-complete-tag)))
      (when mod (insert mod) (forward-line))
      (when text (insert text))))

  ;; To speed up startup, don't put to init section
  (setq org-modules nil                 ; Faster loading
        centaur-org-directory (expand-file-name "org" user-emacs-directory)
        org-directory centaur-org-directory
        org-default-notes-file (expand-file-name "inbox.org" org-directory)
        org-capture-templates
        `(("i" "inbox" entry (file "")
           "* TODO %?\n%U\n" :clock-resume t)
          ("t" "timebox task" entry (file "")
           "* TODO %?\nSCHEDULED: %^T\n:PROPERTIES:\n:EFFORT: %^{Effort|0:30|1:00|1:30|2:00|3:00}\n:END:\n- [ ] \n"
           :clock-resume t)
          ("p" "project" entry (file ,(expand-file-name "projects.org" org-directory))
           "* PROJECT %?\n:PROPERTIES:\n:EFFORT: %^{Effort|2:00|4:00|8:00}\n:END:\n** TODO Step 1\n** TODO Step 2\n"
           :clock-resume t)
          ("c" "config" entry (file ,(expand-file-name "config.org" org-directory))
           "* TODO %?\n%U\n" :clock-resume t)
          ("n" "note" entry (file "")
           "* %? :NOTE:\n%U\n%a\n" :clock-resume t)
          ("j" "Journal" entry (file+olp+datetree
                                ,(expand-file-name "journal.org" org-directory))
           "*  %^{Title} %?\n%U\n%a\n" :clock-resume t)
          ("b" "Book" entry (file+olp+datetree
                             ,(expand-file-name "book.org" org-directory))
           "* Topic: %^{Description}  %^g %? Added: %U"))

        org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!/!)")
          (sequence "PROJECT(p)" "|" "DONE(d!/!)" "CANCELLED(c@/!)")
          (sequence "WAITING(w@/!)" "DELEGATED(e!)" "HOLD(h)" "|" "CANCELLED(c@/!)"))
        org-todo-repeat-to-state "NEXT"
        org-todo-keyword-faces
        '(("NEXT" :inherit warning)
          ("PROJECT" :inherit font-lock-string-face))
        org-priority-faces '((?A . error)
                             (?B . warning)
                             (?C . success))

        ;; Agenda styling
        org-agenda-files (mapcar (lambda (name) (expand-file-name name org-directory))
                                 '("inbox.org" "projects.org" "someday.org" "config.org"))
        org-agenda-block-separator ?─
        org-agenda-time-grid
        '((daily today require-timed)
          (800 1000 1200 1400 1600 1800 2000)
          " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
        org-agenda-current-time-string
        "⭠ now ─────────────────────────────────────────────────"

        org-tags-column 80
        org-log-done t
        org-edit-timestamp-down-means-later t
        org-hide-emphasis-markers t
        org-catch-invisible-edits 'show
        org-export-coding-system 'utf-8
        org-fast-tag-selection-single-key 'expert
        org-html-validation-link nil
        org-export-kill-product-buffer-when-displayed t
        org-startup-with-inline-images t
        org-startup-indented t
        org-ellipsis (if (char-displayable-p ?⏷) "\t⏷" nil)
        org-pretty-entities nil)

  (unless (file-directory-p org-directory)
    (make-directory org-directory t))

  (define-key sanityinc/org-global-prefix-map (kbd "j") 'org-clock-goto)
  (define-key sanityinc/org-global-prefix-map (kbd "l") 'org-clock-in-last)
  (define-key sanityinc/org-global-prefix-map (kbd "i") 'org-clock-in)
  (define-key sanityinc/org-global-prefix-map (kbd "o") 'org-clock-out)

  (setq org-support-shift-select t
        org-enforce-todo-dependencies t
        org-enforce-todo-checkbox-dependencies t
        org-hierarchical-todo-statistics t
        org-global-properties
        '(("Effort_ALL" . "0:15 0:30 0:45 1:00 1:30 2:00 3:00 4:00"))
        org-columns-default-format "%50ITEM(Task) %10Effort(Effort) %10CLOCKSUM")

  (defun sanityinc/org--trim-left (text)
    "Trim leading whitespace from TEXT."
    (replace-regexp-in-string "\\`[ \t\n\r]+" "" text))

  (defun sanityinc/org--parse-bracket-tags (title)
    "Parse leading [tag] blocks in TITLE.
Return a cons of (TITLE . TAGS). Tags within a block can be space- or comma-separated."
    (let ((rest (sanityinc/org--trim-left title))
          (tags '()))
      (while (string-match "\\`\\[\\([^][]+\\)\\]\\s-*" rest)
        (let ((inside (match-string 1 rest)))
          (setq rest (substring rest (match-end 0)))
          (dolist (tag (split-string inside "[ ,]+" t))
            (push tag tags))))
      (cons (sanityinc/org--trim-left rest) (nreverse tags))))

  (defun sanityinc/org-capture-normalize-bracket-tags ()
    "Convert leading [tag] blocks in capture headlines to Org tags."
    (when (derived-mode-p 'org-mode)
      (save-excursion
        (goto-char (point-min))
        (when (re-search-forward org-heading-regexp nil t)
          (goto-char (match-beginning 0))
          (let* ((element (org-element-at-point))
                 (raw (org-element-property :raw-value element))
                 (existing-tags (org-element-property :tags element))
                 (parsed (sanityinc/org--parse-bracket-tags raw))
                 (title (car parsed))
                 (new-tags (cdr parsed)))
            (when (and new-tags (not (equal raw title)))
              (org-edit-headline title)
              (org-set-tags-to (delete-dups (append existing-tags new-tags)))))))))

  (add-hook 'org-capture-prepare-finalize-hook
            'sanityinc/org-capture-normalize-bracket-tags)

  (setq org-refile-use-cache nil
        org-refile-targets '((nil :maxlevel . 5) (org-agenda-files :maxlevel . 5))
        org-refile-use-outline-path t
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm)

  (defun sanityinc/verify-refile-target ()
    "Exclude todo keywords with a done state from refile targets."
    (not (member (nth 2 (org-heading-components)) org-done-keywords)))
  (setq org-refile-target-verify-function 'sanityinc/verify-refile-target)

  (defun sanityinc/org-refile-anywhere (&optional goto default-buffer rfloc msg)
    "A version of `org-refile' which allows refiling to any subtree."
    (interactive "P")
    (let ((org-refile-target-verify-function))
      (org-refile goto default-buffer rfloc msg)))

  (defun sanityinc/org-agenda-refile-anywhere (&optional goto rfloc no-update)
    "A version of `org-agenda-refile' which allows refiling to any subtree."
    (interactive "P")
    (let ((org-refile-target-verify-function))
      (org-agenda-refile goto rfloc no-update)))

  (advice-add 'org-refile :after (lambda (&rest _) (org-save-all-org-buffers)))

  (with-eval-after-load 'org-agenda
    (add-to-list 'org-agenda-after-show-hook 'org-show-entry)
    (add-hook 'org-agenda-mode-hook
              (lambda ()
                (add-hook 'window-configuration-change-hook 'org-agenda-align-tags nil t))))

  (setq-default org-agenda-clockreport-parameter-plist '(:link t :maxlevel 3))

  (let ((active-project-match "-INBOX/PROJECT"))
    (setq org-stuck-projects
          `(,active-project-match ("NEXT")))

    (setq org-agenda-compact-blocks t
          org-agenda-sticky t
          org-agenda-start-on-weekday nil
          org-agenda-span 'day
          org-agenda-include-diary nil
          org-agenda-sorting-strategy
          '((agenda habit-down time-up user-defined-up effort-up category-keep)
            (todo category-up effort-up)
            (tags category-up effort-up)
            (search category-up))
          org-agenda-window-setup 'current-window
          org-agenda-custom-commands
          `(("N" "Notes" tags "NOTE"
             ((org-agenda-overriding-header "Notes")
              (org-tags-match-list-sublevels t)))
            ("g" "GTD"
             ((agenda "" nil)
              (tags "INBOX"
                    ((org-agenda-overriding-header "Inbox")
                     (org-tags-match-list-sublevels nil)))
              (stuck ""
                     ((org-agenda-overriding-header "Stuck Projects")
                      (org-agenda-tags-todo-honor-ignore-options t)
                      (org-tags-match-list-sublevels t)
                      (org-agenda-todo-ignore-scheduled 'future)))
              (tags-todo "-INBOX"
                         ((org-agenda-overriding-header "Next Actions")
                          (org-agenda-tags-todo-honor-ignore-options t)
                          (org-agenda-todo-ignore-scheduled 'future)
                          (org-agenda-skip-function
                           '(lambda ()
                              (or (org-agenda-skip-subtree-if 'todo '("HOLD" "WAITING"))
                                  (org-agenda-skip-entry-if 'nottodo '("NEXT")))))
                          (org-tags-match-list-sublevels t)
                          (org-agenda-sorting-strategy
                           '(todo-state-down effort-up category-keep))))
              (tags-todo ,active-project-match
                         ((org-agenda-overriding-header "Projects")
                          (org-tags-match-list-sublevels t)
                          (org-agenda-sorting-strategy
                           '(category-keep))))
              (tags-todo "-INBOX/-NEXT"
                         ((org-agenda-overriding-header "Orphaned Tasks")
                          (org-agenda-tags-todo-honor-ignore-options t)
                          (org-agenda-todo-ignore-scheduled 'future)
                          (org-agenda-skip-function
                           '(lambda ()
                              (or (org-agenda-skip-subtree-if 'todo '("PROJECT" "HOLD" "WAITING" "DELEGATED"))
                                  (org-agenda-skip-subtree-if 'nottododo '("TODO")))))
                          (org-tags-match-list-sublevels t)
                          (org-agenda-sorting-strategy
                           '(category-keep))))
              (tags-todo "/WAITING"
                         ((org-agenda-overriding-header "Waiting")
                          (org-agenda-tags-todo-honor-ignore-options t)
                          (org-agenda-todo-ignore-scheduled 'future)
                          (org-agenda-sorting-strategy
                           '(category-keep))))
              (tags-todo "/DELEGATED"
                         ((org-agenda-overriding-header "Delegated")
                          (org-agenda-tags-todo-honor-ignore-options t)
                          (org-agenda-todo-ignore-scheduled 'future)
                          (org-agenda-sorting-strategy
                           '(category-keep))))
              (tags-todo "-INBOX"
                         ((org-agenda-overriding-header "On Hold")
                          (org-agenda-skip-function
                           '(lambda ()
                              (or (org-agenda-skip-subtree-if 'todo '("WAITING"))
                                  (org-agenda-skip-entry-if 'nottodo '("HOLD")))))
                          (org-tags-match-list-sublevels nil)
                          (org-agenda-sorting-strategy
                           '(category-keep)))))))))

  (add-hook 'org-agenda-mode-hook 'hl-line-mode)

  (setq org-clock-persist t
        org-clock-in-resume t
        org-clock-into-drawer t
        org-log-into-drawer t
        org-clock-out-remove-zero-time-clocks t
        org-time-clocksum-format
        '(:hours "%d" :require-hours t :minutes ":%02d" :require-minutes t))

  (setq org-archive-mark-done nil
        org-archive-location "%s_archive::* Archive")

  (defun sanityinc/show-org-clock-in-header-line ()
    (setq-default header-line-format '((" " org-mode-line-string " "))))

  (defun sanityinc/hide-org-clock-from-header-line ()
    (setq-default header-line-format nil))

  (add-hook 'org-clock-in-hook 'sanityinc/show-org-clock-in-header-line)
  (add-hook 'org-clock-out-hook 'sanityinc/hide-org-clock-from-header-line)
  (add-hook 'org-clock-cancel-hook 'sanityinc/hide-org-clock-from-header-line)

  ;; Add new template
  (add-to-list 'org-structure-template-alist '("n" . "note"))

  (with-eval-after-load 'org
    (setq org-display-remote-inline-images 'cache)

    (defun org-http-image-data-fn (protocol link _description)
      "Interpret LINK as an URL to an image file."
      (when (and (image-type-from-file-name link)
                 (not (eq org-display-remote-inline-images 'skip)))
        (let ((buf (url-retrieve-synchronously (concat protocol ":" link))))
          (if buf
              (with-current-buffer buf
                (goto-char (point-min))
                (re-search-forward "\r?\n\r?\n" nil t)
                (buffer-substring-no-properties (point) (point-max)))
            (message "Download of image \"%s\" failed" link)
            nil))))

    (org-link-set-parameters "http" :image-data-fun #'org-http-image-data-fn)
    (org-link-set-parameters "https" :image-data-fun #'org-http-image-data-fn)

    (org-clock-persistence-insinuate)

    (define-key org-mode-map (kbd "C-M-<up>") 'org-up-element)
    (when sys/macp
      (define-key org-mode-map (kbd "M-h") nil)
      (define-key org-mode-map (kbd "C-c g") 'grab-mac-link)))

  (with-eval-after-load 'org-clock
    (define-key org-clock-mode-line-map [header-line mouse-2] 'org-clock-goto)
    (define-key org-clock-mode-line-map [header-line mouse-1] 'org-clock-menu))

  (when (and sys/macp (file-directory-p "/Applications/org-clock-statusbar.app"))
    (add-hook 'org-clock-in-hook
              (lambda ()
                (call-process "/usr/bin/osascript" nil 0 nil "-e"
                              (concat "tell application \"org-clock-statusbar\" to clock in \""
                                      org-clock-current-task
                                      "\""))))
    (add-hook 'org-clock-out-hook
              (lambda ()
                (call-process "/usr/bin/osascript" nil 0 nil "-e"
                              "tell application \"org-clock-statusbar\" to clock out"))))

  ;; Use embedded webkit browser if possible
  (add-to-list 'org-file-apps
               '("\\.\\(x?html?\\|pdf\\)\\'"
                 .
                 (lambda (file _link)
                   (centaur-browse-url-of-file (browse-url-file-url file)))))

  ;; Add md/gfm backends
  (add-to-list 'org-export-backends 'md)
  (use-package ox-gfm
    :init (add-to-list 'org-export-backends 'gfm))

  ;; Babel
  (setq org-confirm-babel-evaluate nil
        org-src-fontify-natively t
        org-src-tab-acts-natively t)

  (defconst load-language-alist
    '((emacs-lisp . t)
      (perl       . t)
      (python     . t)
      (ruby       . t)
      (js         . t)
      (css        . t)
      (sass       . t)
      (C          . t)
      (java       . t)
      (shell      . t)
      (plantuml   . t))
    "Alist of org ob languages.")

  (use-package ob-go
    :init (cl-pushnew '(go . t) load-language-alist))

  (use-package ob-powershell
    :init (cl-pushnew '(powershell . t) load-language-alist))

  (use-package ob-rust
    :init (cl-pushnew '(rust . t) load-language-alist))

  ;; Install: npm install -g @mermaid-js/mermaid-cli
  (use-package ob-mermaid
    :init (cl-pushnew '(mermaid . t) load-language-alist))

  (dolist (lang '(R ditaa dot gnuplot latex ledger octave plantuml python ruby shell sql sqlite))
    (when (locate-library (concat "ob-" (symbol-name lang)))
      (unless (assoc lang load-language-alist)
        (push (cons lang t) load-language-alist))))

  (org-babel-do-load-languages 'org-babel-load-languages
                               load-language-alist))

(use-package grab-mac-link
  :if sys/macp
  :commands grab-mac-link)

(use-package org-cliplink
  :after org)

(use-package writeroom-mode)

(define-minor-mode prose-mode
  "Set up a buffer for prose editing.
This enables or modifies a number of settings so that the
experience of editing prose is a little more like that of a
typical word processor."
  :init-value nil :lighter " Prose" :keymap nil
  (if prose-mode
      (progn
        (when (fboundp 'writeroom-mode)
          (writeroom-mode 1))
        (setq truncate-lines nil)
        (setq word-wrap t)
        (setq cursor-type 'bar)
        (when (eq major-mode 'org)
          (kill-local-variable 'buffer-face-mode-face))
        (buffer-face-mode 1)
        (setq-local blink-cursor-interval 0.6)
        (setq-local show-trailing-whitespace nil)
        (setq-local line-spacing 0.2)
        (setq-local electric-pair-mode nil)
        (ignore-errors (flyspell-mode 1))
        (visual-line-mode 1))
    (kill-local-variable 'truncate-lines)
    (kill-local-variable 'word-wrap)
    (kill-local-variable 'cursor-type)
    (kill-local-variable 'blink-cursor-interval)
    (kill-local-variable 'show-trailing-whitespace)
    (kill-local-variable 'line-spacing)
    (kill-local-variable 'electric-pair-mode)
    (buffer-face-mode -1)
    (flyspell-mode -1)
    (visual-line-mode -1)
    (when (fboundp 'writeroom-mode)
      (writeroom-mode 0))))

;; Prettify UI
(use-package org-modern
  :after org
  :diminish
  :autoload global-org-modern-mode
  :init (global-org-modern-mode 1))

;; Paste with org-mode markup and link
(use-package org-rich-yank
  :after org
  :diminish
  :bind (:map org-mode-map
         ("C-M-y" . org-rich-yank)))

;; Auto-toggle Org elements
(use-package org-appear
  :diminish
  :hook org-mode
  :custom
  (org-appear-autoentities t)
  (org-appear-autokeywords t)
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t)
  (org-appear-inside-latex t)
  (org-appear-manual-linger t)
  (org-appear-delay 0.5))

;; Table of contents
(use-package toc-org
  :diminish
  :hook org-mode)

;; Preview
(use-package org-preview-html
  :after org
  :diminish
  :functions xwidget-workable-p
  :bind (:map org-mode-map
         ("C-c C-h" . org-preview-html-mode))
  :init (when (xwidget-workable-p)
          (setq org-preview-html-viewer 'xwidget)))

;; Presentation
(if emacs/>=29.2p
    (use-package dslide
      :after org
      :diminish
      :bind (:map org-mode-map
             ("s-<f7>" . dslide-deck-start)))
  (use-package org-tree-slide
    :after org
    :diminish
    :defines org-tree-slide-mode-map
    :bind (:map org-mode-map
           ("s-<f7>" . org-tree-slide-mode)
           :map org-tree-slide-mode-map
           ("<left>" . org-tree-slide-move-previous-tree)
           ("<right>" . org-tree-slide-move-next-tree)
           ("S-SPC" . org-tree-slide-move-previous-tree)
           ("SPC" . org-tree-slide-move-next-tree))
    :custom (org-tree-slide-skip-outline-level 3)))

;; Pomodoro
(use-package org-pomodoro
  :after org
  :diminish
  :custom (org-pomodoro-keep-killed-pomodoro-time t)
  :custom-face
  (org-pomodoro-mode-line ((t (:inherit warning))))
  (org-pomodoro-mode-line-overtime ((t (:inherit error))))
  (org-pomodoro-mode-line-break ((t (:inherit success))))
  :bind (:map org-mode-map
         ("C-c C-x m" . org-pomodoro))
  :init (with-eval-after-load 'org-agenda
          (bind-keys :map org-agenda-mode-map
            ("P" . org-pomodoro)
            ("K" . org-pomodoro)
            ("C-c C-x m" . org-pomodoro))))

;; Roam
(when (and (fboundp 'sqlite-available-p) (sqlite-available-p))
  (use-package org-roam
    :diminish
    :functions centaur-browse-url org-roam-db-autosync-mode
    :defines org-roam-graph-viewer
    :bind (("C-c n l" . org-roam-buffer-toggle)
           ("C-c n f" . org-roam-node-find)
           ("C-c n g" . org-roam-graph)
           ("C-c n i" . org-roam-node-insert)
           ("C-c n c" . org-roam-capture)
           ("C-c n j" . org-roam-dailies-capture-today))
    :init
    (setq org-roam-directory centaur-org-directory
          org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag))
          org-roam-graph-viewer #'centaur-browse-url)
    :config
    (unless (file-exists-p org-roam-directory)
      (make-directory org-roam-directory))
    (add-to-list 'org-agenda-files org-roam-directory)

    ;; Keep Org-roam session automatically synchronized
    (org-roam-db-autosync-mode))

  (use-package org-roam-ui
    :bind ("C-c n u" . org-roam-ui-mode)
    :init (setq org-roam-ui-browser-function #'centaur-browse-url)))

(provide 'init-org)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-org.el ends here
