;; init-markdown.el --- Initialize markdown configurations.	-*- lexical-binding: t -*-

;; Copyright (C) 2009-2025 Vincent Zhang

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
;; Markdown configurations.
;;

;;; Code:

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode))
  :init
  (setq markdown-enable-wiki-links t
        markdown-italic-underscore t
        markdown-asymmetric-header t
        markdown-make-gfm-checkboxes-buttons t
        markdown-gfm-uppercase-checkbox t
        markdown-fontify-code-blocks-natively t

        markdown-content-type "application/xhtml+xml"
        markdown-css-paths '("https://cdn.jsdelivr.net/npm/github-markdown-css/github-markdown.min.css"
                             "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/styles/github.min.css")
        markdown-xhtml-header-content "
<meta name='viewport' content='width=device-width, initial-scale=1, shrink-to-fit=no'>
<style>
body {
  box-sizing: border-box;
  max-width: 740px;
  width: 100%;
  margin: 40px auto;
  padding: 0 10px;
}
</style>

<link rel='stylesheet' href='https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/styles/default.min.css'>
<script src='https://cdn.jsdelivr.net/gh/highlightjs/cdn-release/build/highlight.min.js'></script>
<script>
document.addEventListener('DOMContentLoaded', () => {
  document.body.classList.add('markdown-body');
  document.querySelectorAll('pre code').forEach((code) => {
    if (code.className != 'mermaid') {
      hljs.highlightBlock(code);
    }
  });
});
</script>

<script src='https://unpkg.com/mermaid@8.4.8/dist/mermaid.min.js'></script>
<script>
mermaid.initialize({
  theme: 'default',  // default, forest, dark, neutral
  startOnLoad: true
});
</script>
"
        markdown-gfm-additional-languages "Mermaid")

  ;; `multimarkdown' is necessary for `highlight.js' and `mermaid.js'
  (when (executable-find "multimarkdown")
    (setq markdown-command "multimarkdown"))
  :config
  ;; Support `mermaid'
  (add-to-list 'markdown-code-lang-modes '("mermaid" . mermaid-mode))

  (with-no-warnings
    ;; Use `which-key' instead
    (advice-add #'markdown--command-map-prompt :override #'ignore)
    (advice-add #'markdown--style-map-prompt   :override #'ignore)

    ;; Preview with webkit
    (defun my-markdown-export-and-preview ()
      "Preview with `xwidget' if applicable, otherwise with the default browser."
      (centaur-browse-url-of-file (markdown-export)))
    (advice-add #'markdown-export-and-preview :override #'my-markdown-export-and-preview))

  (defvar-local sanityinc/markdown--appear-last-bounds nil
    "Cons of (BEG . END) for last revealed region.")

  (defvar-local sanityinc/markdown--appear-timer nil
    "Timer for delayed reveal.")

  (defvar-local sanityinc/markdown--inhibit-reveal nil
    "When non-nil, do not re-reveal markup after fontification.")

  (defun sanityinc/markdown--bounds-in-text-block (regex group)
    "Return bounds for REGEX GROUP around point in current text block."
    (save-excursion
      (save-match-data
        (let* ((origin (point))
               (start (progn (markdown-beginning-of-text-block) (point)))
               (end (progn (markdown-end-of-text-block) (point)))
               (found nil))
          (goto-char start)
          (while (and (not found) (re-search-forward regex end t))
            (let ((beg (match-beginning group))
                  (fin (match-end group)))
              (when (and beg fin (<= beg origin) (>= fin origin))
                (setq found (cons (match-beginning 0) (match-end 0))))))
          found))))

  (defun sanityinc/markdown--inline-code-bounds ()
    "Return bounds for inline code at point."
    (save-excursion
      (save-match-data
        (when (markdown-inline-code-at-pos (point))
          (cons (match-beginning 0) (match-end 0))))))

  (defun sanityinc/markdown--wiki-link-bounds ()
    "Return bounds for a wiki link at point."
    (save-excursion
      (save-match-data
        (when (markdown-wiki-link-p)
          (cons (match-beginning 0) (match-end 0))))))

  (defun sanityinc/markdown--link-bounds ()
    "Return bounds for a regular link at point."
    (save-excursion
      (save-match-data
        (let ((p (point)))
          (when (and (boundp 'markdown-regex-link-inline)
                     (markdown-link-at-pos p))
            (goto-char p)
            (when (re-search-backward markdown-regex-link-inline nil t)
              (when (<= (match-beginning 0) p (match-end 0))
                (cons (match-beginning 0) (match-end 0)))))))))

  (defun sanityinc/markdown--heading-bounds ()
    "Return bounds for a heading at point."
    (save-excursion
      (save-match-data
        (beginning-of-line)
        (when (looking-at markdown-regex-header)
          (cons (line-beginning-position) (line-end-position))))))

  (defun sanityinc/markdown--code-block-bounds ()
    "Return bounds for a fenced code block at point."
    (save-excursion
      (save-match-data
        (let ((origin (point))
              (fence-re "^\\s-*\\(```+\\|~~~+\\)"))
          (when (re-search-backward fence-re nil t)
            (let ((fence (match-string 1))
                  (beg (line-beginning-position)))
              (forward-line 1)
              (when (re-search-forward
                     (concat "^\\s-*" (regexp-quote fence) "\\s-*$")
                     nil t)
                (let ((end (line-end-position)))
                  (when (and (<= beg origin) (<= origin end))
                    (cons beg end))))))))))

  (defun sanityinc/markdown--element-bounds-at-point ()
    "Return bounds of the Markdown element at point."
    (unless (markdown-code-block-at-point-p)
      (or (sanityinc/markdown--heading-bounds)
          (sanityinc/markdown--inline-code-bounds)
          (sanityinc/markdown--wiki-link-bounds)
          (sanityinc/markdown--link-bounds)
          (sanityinc/markdown--bounds-in-text-block markdown-regex-bold 2)
          (sanityinc/markdown--bounds-in-text-block markdown-regex-italic 1)
          (sanityinc/markdown--bounds-in-text-block markdown-regex-strike-through 2))))

  (defun sanityinc/markdown--reveal-markup (beg end)
    "Reveal hidden markup between BEG and END."
    (with-silent-modifications
      (let ((pos beg))
        (while (< pos end)
          (let* ((next (or (next-single-property-change pos 'invisible nil end) end))
                 (inv (get-text-property pos 'invisible)))
            (when (or (eq inv 'markdown-markup)
                      (and (listp inv) (memq 'markdown-markup inv)))
              (put-text-property pos next 'invisible nil))
            (setq pos next))))
      (let ((pos beg))
        (while (< pos end)
          (let* ((next (or (next-single-property-change pos 'display nil end) end))
                 (disp (get-text-property pos 'display)))
            (when (equal disp "")
              (put-text-property pos next 'display nil))
            (setq pos next))))))

  (defun sanityinc/markdown--hide-markup (beg end)
    "Re-hide markup between BEG and END by refontifying."
    (when (and beg end
               (< beg (point-max))
               (<= end (point-max)))
      (let ((sanityinc/markdown--inhibit-reveal t))
        (font-lock-flush beg end)
        (font-lock-ensure beg end))))

  (defun sanityinc/markdown--appear-update (buf)
    "Update which region has revealed markup in BUF."
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (when (and sanityinc/markdown-appear-mode
                   (bound-and-true-p markdown-hide-markup)
                   (boundp 'markdown-regex-header))
          (let* ((code-bounds (sanityinc/markdown--code-block-bounds))
                 (bounds (or code-bounds (sanityinc/markdown--element-bounds-at-point))))
            (unless (equal bounds sanityinc/markdown--appear-last-bounds)
              (let ((old-bounds sanityinc/markdown--appear-last-bounds))
                (setq sanityinc/markdown--appear-last-bounds bounds)
                (when old-bounds
                  (sanityinc/markdown--hide-markup (car old-bounds) (cdr old-bounds)))
                (when bounds
                  (sanityinc/markdown--reveal-markup (car bounds) (cdr bounds))))))))))

  (defun sanityinc/markdown--appear-post-command ()
    "Schedule markup reveal after command."
    (when sanityinc/markdown--appear-timer
      (cancel-timer sanityinc/markdown--appear-timer))
    (let ((buf (current-buffer)))
      (setq sanityinc/markdown--appear-timer
            (run-with-idle-timer 0.05 nil #'sanityinc/markdown--appear-update buf))))

  (defun sanityinc/markdown--fontify-advice (orig-fun beg end &optional loudly)
    "After fontifying, re-reveal markup in the current element."
    (let ((result (funcall orig-fun beg end loudly)))
      (when (and sanityinc/markdown-appear-mode
                 (not sanityinc/markdown--inhibit-reveal)
                 sanityinc/markdown--appear-last-bounds)
        (let ((reveal-beg (car sanityinc/markdown--appear-last-bounds))
              (reveal-end (cdr sanityinc/markdown--appear-last-bounds)))
          (when (and (<= beg reveal-end) (>= end reveal-beg))
            (sanityinc/markdown--reveal-markup reveal-beg reveal-end))))
      result))

  (defun sanityinc/markdown--enable-hide-markup ()
    "Enable markup hiding for the current buffer."
    (when (fboundp 'markdown-toggle-markup-hiding)
      (markdown-toggle-markup-hiding 1)))

  (define-minor-mode sanityinc/markdown-appear-mode
    "Show Markdown markup only for the current element."
    :init-value nil
    :lighter ""
    (if sanityinc/markdown-appear-mode
        (progn
          (add-hook 'post-command-hook #'sanityinc/markdown--appear-post-command nil t)
          (advice-add 'font-lock-fontify-region :around #'sanityinc/markdown--fontify-advice))
      (remove-hook 'post-command-hook #'sanityinc/markdown--appear-post-command t)
      (advice-remove 'font-lock-fontify-region #'sanityinc/markdown--fontify-advice)
      (when sanityinc/markdown--appear-timer
        (cancel-timer sanityinc/markdown--appear-timer)
        (setq sanityinc/markdown--appear-timer nil))
      (when sanityinc/markdown--appear-last-bounds
        (let ((sanityinc/markdown--inhibit-reveal t))
          (sanityinc/markdown--hide-markup
           (car sanityinc/markdown--appear-last-bounds)
           (cdr sanityinc/markdown--appear-last-bounds)))
        (setq sanityinc/markdown--appear-last-bounds nil))))

  (defun sanityinc/markdown-setup ()
    "Enable Markdown appearance helpers."
    (sanityinc/markdown--enable-hide-markup)
    (sanityinc/markdown-appear-mode 1))

  (add-hook 'markdown-mode-hook #'sanityinc/markdown-setup)

  (with-eval-after-load 'whitespace-cleanup-mode
    (add-to-list 'whitespace-cleanup-mode-ignore-modes 'markdown-mode)))

;; Table of contents
(use-package markdown-toc
  :diminish
  :bind (:map markdown-mode-command-map
         ("r" . markdown-toc-generate-or-refresh-toc))
  :hook markdown-mode
  :init (setq markdown-toc-indentation-space 2
              markdown-toc-header-toc-title "\n## Table of Contents"
              markdown-toc-user-toc-structure-manipulation-fn 'cdr)
  :config
  (with-no-warnings
    (define-advice markdown-toc-generate-toc (:around (fn &rest args) lsp)
      "Generate or refresh toc after disabling lsp."
      (cond
       ((bound-and-true-p eglot--manage-mode)
        (eglot--manage-mode -1)
        (apply fn args)
        (eglot--manage-mode 1))
       ((bound-and-true-p lsp-managed-mode)
        (lsp-managed-mode -1)
        (apply fn args)
        (lsp-managed-mode 1))
       (t
        (apply fn args))))))

;; Preview markdown files
;; @see https://github.com/seagle0128/grip-mode?tab=readme-ov-file#prerequisite
(use-package grip-mode
  :defines markdown-mode-command-map org-mode-map grip-update-after-change grip-use-mdopen
  :functions auth-source-user-and-password
  :autoload grip-mode
  :init
  (with-eval-after-load 'markdown-mode
    (bind-key "g" #'grip-mode markdown-mode-command-map))

  (with-eval-after-load 'org
    (bind-key "C-c C-g" #'grip-mode org-mode-map))

  (setq grip-update-after-change nil)

  ;; mdopen doesn't need credentials, and only support external browsers
  (if (executable-find "mdopen")
      (setq grip-use-mdopen t)
    (when-let* ((credential (and (require 'auth-source nil t)
                                 (auth-source-user-and-password "api.github.com"))))
      (setq grip-github-user (car credential)
            grip-github-password (cadr credential)))))

(provide 'init-markdown)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; init-markdown.el ends here
