;;; easymacs.el --- remains of Peter Heslin's Emacs config
;;
;; easymacs.el is a configuration for Emacs which is designed to be a learning environment for the digital humanities.  It provides an easy-to-install, cross-platform, comprehensive tool with key-bindings for basic editing tasks that should be familiar to non-technical users (some of these overwrite Emacs defaults).   It provides, for example, a schema-aware validating XML editor (nxml), a cross-platform command-line (eshell), integration with Git (magit) and a rich devopment environment for teaching programming in a variety of languages.
;; 
;; Author: Peter Heslin <p.j.heslin@dur.ac.uk>
;; Maintainer: Peter Heslin <p.j.heslin@dur.ac.uk>
;; 
;; Copyright (C) 2003-16 Peter Heslin
;; 
;; This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3, or (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License along with GNU Emacs; see the file COPYING.  If not, write to the Free Software Foundation, 675 Massachusettes Ave, Cambridge, MA 02139, USA.

;;; General Settings (continued from sinomacs.el)
; these are things specific to easymacs which I will retain here -- CW
;; Ido and ibuffer for buffer switching
(ido-mode 'buffer)
(setq ido-use-virtual-buffers t)
;; Ignore non-user files in ido
(defun easymacs-ido-ignore (name)
  "Ignore all non-user (a.k.a. *starred*) buffers except *eshell*."
  (and (string-match "^\*" name)
       (not (string= name "*eshell*"))))
(setq ido-ignore-buffers '("\\` " easymacs-ido-ignore))

(require 'ibuffer)
(require 'ibuf-ext)
;; Simplified ibuffer display
(setq ibuffer-formats
      '((mark modified read-only " "
	      (name 0 -1 :left :elide))))
;; Make ibuffer refresh after every command
(add-hook 'ibuffer-mode-hook (lambda () (ibuffer-auto-mode 1)))

;; imenu
(defun imenu-or-not ()
  "Try to add an imenu when we visit a file, catch and nil if
the mode doesn't support imenu."
  (condition-case nil
      (imenu-add-menubar-index)
    (error nil)))
(add-to-list 'find-file-hooks 'imenu-or-not)
(setq imenu-max-items 50
      imenu-scanning-message nil
      imenu-auto-rescan t)

(use-package drag-stuff
  :ensure t
  :diminish 'drag-stuff-mode
  :config (progn (drag-stuff-global-mode 1)
                 (drag-stuff-define-keys)))

;; Programming tools
(add-hook 'prog-mode-hook 'linum-mode)


(use-package magit
  :ensure t
  :bind ("C-x g" . magit-status)
;  :bind* ("<C-f6>" . magit-status)
  :config (setq magit-diff-refine-hunk 'all))
;; To finish magit sub-editor
(eval-after-load "with-editor"
    '(define-key with-editor-mode-map (kbd "<f12>") 'with-editor-finish))
(use-package git-gutter-fringe
  :ensure t
  :diminish 'git-gutter-mode
  :bind* (("<M-f6>" . git-gutter:next-hunk)
	  ("<S-M-f6>" . git-gutter:previous-hunk)))
;; Not sure why this doesn't work with autoloads
(require 'git-gutter-fringe)
(global-git-gutter-mode 1)
(setq git-gutter:update-interval 0)

(defun easymacs-git-wdiff ()
  (interactive)
  (let ((inhibit-read-only t)
        (coding-system-for-read 'utf-8-unix)
        (coding-system-for-write 'utf-8-unix)
        (git-command (read-string "Git command: "
                                  "git diff --color-words HEAD")))
    (shell-command git-command "*git-wdiff*")
    (switch-to-buffer "*git-wdiff*")
    (delete-other-windows)
    (ansi-color-apply-on-region (point-min) (point-max))
    (visual-line-mode 1)
    (diff-mode)
    (read-only-mode)))
(bind-key* (kbd "<C-S-f6>") 'easymacs-git-wdiff)


;; Visible bookmarks

(use-package bm
         :ensure t
         :demand t
         :init
         (setq bm-restore-repository-on-load t)
         :config
         (setq bm-highlight-style 'bm-highlight-only-fringe)
         (setq bm-cycle-all-buffers t)
         (setq bm-repository-file (expand-file-name "~/.emacs.d/bm-repository"))
         (setq-default bm-buffer-persistence t)
         (add-hook' after-init-hook 'bm-repository-load)
         (add-hook 'find-file-hooks 'bm-buffer-restore)
         (add-hook 'kill-buffer-hook #'bm-buffer-save)
         (add-hook 'kill-emacs-hook #'(lambda nil
                                          (bm-buffer-save-all)
                                          (bm-repository-save)))
         (add-hook 'after-save-hook #'bm-buffer-save)
         (add-hook 'find-file-hooks   #'bm-buffer-restore)
         (add-hook 'after-revert-hook #'bm-buffer-restore)
         (add-hook 'vc-before-checkin-hook #'bm-buffer-save)
         (global-set-key (kbd "<left-fringe> <mouse-5>") 'bm-next-mouse)
         (global-set-key (kbd "<left-fringe> <mouse-4>") 'bm-previous-mouse)
         (global-set-key (kbd "<left-fringe> <mouse-1>") 'bm-toggle-mouse)
         :bind (("<f5>" . bm-next)
                ("S-<f5>" . bm-previous)
                ("C-<f5>" . bm-toggle)))


;; Folding for fold-dwim
(setq hs-isearch-open t)
(setq hs-hide-comments-when-hiding-all t)
(setq hs-allow-nesting t)
(add-hook 'prog-mode-hook #'hs-minor-mode)
(add-hook 'prog-mode-hook #'outline-minor-mode)
(add-hook 'text-mode-hook #'outline-minor-mode)
(diminish 'hs-minor-mode)
(diminish 'outline-minor-mode)

(use-package browse-kill-ring
  :ensure t
  :bind* ("<C-S-v>" . browse-kill-ring))

;; Improve Scrolling Behaviour

;; smooth-scrolling.el keeps several lines of context visible when the cursor nears the top or bottom of the screen, and when the cursor hits that limit it scrolls by a single line rather than jumping by a page.

 (use-package smooth-scrolling
   :ensure t
   :diminish 'smooth-scrolling-mode
   :config (progn (smooth-scrolling-mode 1)
                  (setq smooth-scroll-margin 5)))

;; smooth-scroll.el has a very different purpose: it implements a scrolling motion when paging up and down.  But this does not work well with the reversible paging below, and it is really just a visual effect; so it is not enabled here.  But the functions to scroll without moving the cursor are useful.

(use-package smooth-scroll
  :ensure t
  :diminish 'smooth-scroll-mode
  :config (smooth-scroll-mode -1)
  :bind* (("<C-down>"  . scroll-up-1)
          ("<C-up>"    . scroll-down-1)
          ("<C-left>"  . scroll-right-1)
          ("<C-right>" . scroll-left-1)))

;; Code adapted from Emacswiki/Stack Overflow to implement reversible paging.  Paging down and then back up puts you back in the same spot where you started.

(defun sfp-page-down (&optional arg)
  (interactive "^P")
  (setq this-command 'next-line)
  (let ((smooth-scrolling-mode nil))
    (next-line
     (- (window-text-height)
        next-screen-context-lines))))
(put 'sfp-page-down 'isearch-scroll t)
(put 'sfp-page-down 'CUA 'move)

(defun sfp-page-up (&optional arg)
  (interactive "^P")
  (setq this-command 'previous-line)
  (let ((smooth-scrolling-mode nil))
    (previous-line
     (- (window-text-height)
        next-screen-context-lines))))

(put 'sfp-page-up 'isearch-scroll t)
(put 'sfp-page-up 'CUA 'move)

(global-set-key [next] 'sfp-page-down)
(global-set-key [prior] 'sfp-page-up)

;;; Utility functions

(defun unfill-paragraph (&optional region)
  "Takes a multi-line paragraph and makes it into a single line of text."
  (interactive (progn (barf-if-buffer-read-only) '(t)))
  (let ((fill-column (point-max)))
    (fill-paragraph nil region)))
(bind-key* (kbd "M-Q") 'unfill-paragraph)

(defun easymacs-make-dist ()
  (interactive)
  (save-some-buffers)
  (cd easymacs-dir)
  (cd "..")
  (start-process "zip" "*zip*"
		 "zip" "-r" "easymacs.zip" "easymacs" "-x" "easymacs/.git/*"))

(defun easymacs-comment-line-or-region (arg)
  (interactive)
  (let ((start (line-beginning-position))
	(end (line-end-position)))
    (when (or (not transient-mark-mode) (region-active-p))
      (setq start (save-excursion
		    (goto-char (region-beginning))
		    (beginning-of-line)
		    (point))
	    end (save-excursion
		  (goto-char (region-end))
		  (end-of-line)
		  (point))))
    (comment-region start end arg)))

(defun easymacs-kill-buffer ()
    "Kill buffer and delete window if split without prompting"
    (interactive)
    (let ((buffer (current-buffer)))
      (ignore-errors (delete-window (selected-window)))
      (kill-buffer buffer)))

(defun easymacs-kill-some-buffers ()
  "Kill most unmodified buffers, except for a few."
  (interactive)
  (when (yes-or-no-p "Close unmodified files? ")
    (let ((list (buffer-list)))
      (while list
	(let* ((buffer (car list))
	       (name (buffer-name buffer)))
	  (when (if (string-match "^\\*.*\\*$" name)
		    (and (not (string-equal name "*Messages*"))
			 (not (string-equal name "*eshell*")))
		  (not (buffer-modified-p buffer)))
	    (kill-buffer buffer)))
	(setq list (cdr list))))
    (delete-other-windows)))

(defun easymacs-select-line ()
  "Select current line"
  (interactive)
  (end-of-line)
  (set-mark (line-beginning-position)))

(defun easymacs-last-buffer ()
  (interactive)
  (switch-to-buffer
   (other-buffer (current-buffer) 1)))

;;; Word count
;; Pinched from http://www.dr-qubit.org/emacs.php

(setq mode-line-position (assq-delete-all 'wc-mode mode-line-position))
(setq mode-line-position
      (append
       mode-line-position
       '((wc-mode
	  (6 (:eval (if (use-region-p)
			(format " %d,%d,%d"
				(abs (- (point) (mark)))
				(count-words-region (point) (mark))
				(abs (- (line-number-at-pos (point))
					(line-number-at-pos (mark)))))
		      (format " %d,%d,%d"
			      (- (point-max) (point-min))
			      (count-words-region (point-min) (point-max))
			      (line-number-at-pos (point-max))))))
	  nil))))
(define-minor-mode wc-mode
  "Toggle word-count mode.
With no argument, this command toggles the mode.
A non-null prefix argument turns the mode on.
A null prefix argument turns it off.

When enabled, the total number of characters, words, and lines is
displayed in the mode-line.")

;;; Mac stuff
(when (memq window-system '(mac ns))
  (setq ns-pop-up-frames nil
	mac-command-modifier 'control
        mac-option-modifier 'meta
	x-select-enable-clipboard t))
(use-package exec-path-from-shell
  :ensure t
  :config (when (memq window-system '(mac ns))
	    (exec-path-from-shell-initialize)))

;;; Spell-checking
;; Get hunspell dictionaries like so:
;; svn co https://src.chromium.org/chrome/trunk/deps/third_party/hunspell_dictionaries/
;; make sure that one dictionary is soft-linked to default.dic and default.aff
(when (executable-find "hunspell")
  (setq-default ispell-program-name "hunspell")
  (setq ispell-really-hunspell t))
(add-hook 'text-mode-hook '(lambda ()
			     (flyspell-mode 1)))
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

;;; Eshell
;; Always save eshell history without asking
(setq eshell-save-history-on-exit 't)
(setq eshell-ask-to-save-history 'always)
(setq eshell-prefer-to-shell t)
;; Don't auto-complete ambiguities
(setq eshell-cmpl-cycle-completions nil)

(defun easymacs-eshell ()
  "Eshell with switch to directory of current buffer"
  (interactive)
  (let ((dir default-directory))
    (eshell)
    ;; Make sure it's at the front of the buffer-list
    (switch-to-buffer "*eshell*")
    (eshell-kill-input)
    (unless (string= (expand-file-name dir) (expand-file-name default-directory))
      (eshell/cd dir)
      (eshell-send-input))))

;;; Dired

  ;; Make dired less weird -- it always opens new files or directories
  ;; in the current buffer, rather than endless spawning of new buffers
  (defun easymacs-dired-mouse-find-file-same-window (event)
    ;; Never open a new buffer from dired, even when clicking with the mouse
    ;; Modified from dired.el
    "In Dired, visit the file or directory name you click on."
    (interactive "e")
    (let (window pos file)
      (save-excursion
	(setq window (posn-window (event-end event))
	      pos (posn-point (event-end event)))
	(if (not (windowp window))
	    (error "No file chosen"))
	(set-buffer (window-buffer window))
	(goto-char pos)
	(setq file (dired-get-file-for-visit)))
      (select-window window)
      (find-alternate-file (file-name-sans-versions file t))))

  (eval-after-load "dired"
    '(progn
       ;; Never open a new buffer from dired, neither for files nor directories.
       (defadvice dired-find-file (around dired-subst-directory activate)
	 "Replace current buffer if file is a directory."
	 (interactive)
	 (let ((orig (current-buffer))
	       (filename (dired-get-filename nil t)))
	   ad-do-it
	   (kill-buffer orig)))
       (define-key dired-mode-map [mouse-2]
	 'easymacs-dired-mouse-find-file-same-window)
       (define-key dired-mode-map "^" (function
				       (lambda nil (interactive)
					 (find-alternate-file ".."))))))

;;; Isearch

(bind-key* (kbd "C-f") 'isearch-forward)
(bind-key* (kbd "C-S-f") 'isearch-backward)
(bind-key* (kbd "C-r") 'query-replace)
(bind-key* (kbd "C-S-r") 'replace-string)
(bind-key* (kbd "M-r") 'query-replace-regexp)
(bind-key* (kbd "M-S-r") 'replace-regexp)
(define-key isearch-mode-map (kbd "C-f") 'isearch-repeat-forward)
(define-key isearch-mode-map (kbd "C-S-f") 'isearch-repeat-backward)
(define-key isearch-mode-map [escape] 'isearch-cancel)
(define-key isearch-mode-map (kbd "<C-up>") 'isearch-ring-retreat)
(define-key isearch-mode-map (kbd "<C-down>") 'isearch-ring-advance)
(define-key isearch-mode-map (kbd "C-f") 'isearch-repeat-forward)
(define-key isearch-mode-map (kbd "<f1>") 'ido-switch-buffer)

(bind-key* (kbd "C-d") '(lambda () (interactive)
			  (beginning-of-thing 'symbol)
			  (push-mark)
			  (activate-mark)
			  (end-of-thing 'symbol)))
(bind-key* (kbd "S-C-d") 'easymacs-select-line)

;; Modifies isearch to search for selected text, if there is a selection
(defadvice isearch-mode (around isearch-mode-default-string (forward &optional regexp op-fun recursive-edit word-p) activate)
  (if (and transient-mark-mode mark-active (not (eq (mark) (point))))
      (progn
        (isearch-update-ring (buffer-substring-no-properties (mark) (point)))
        (deactivate-mark)
        ad-do-it
        (if (not forward)
            (isearch-repeat-backward)
          (goto-char (mark))
          (isearch-repeat-forward)))
    ad-do-it))

;; Important for long lines
(setq grep-highlight-matches 'always)

;;; Regexps: re-builder and pcre2el
(use-package pcre2el
  :ensure t
  :config (pcre-mode t)
  :diminish pcre-mode)

(use-package re-builder
  :ensure t
  :config (setq reb-re-syntax 'pcre))
;; use-package bind does not work here
(add-hook 'reb-mode-hook (lambda ()
                           (local-set-key (kbd "<f5>")
                                          'reb-next-match)
                           (local-set-key (kbd "<S-f5>")
                                          'reb-prev-match)
                           (local-set-key (kbd "C-b")
                                          'reb-change-target-buffer)))



;;; Elisp
(defun easymacs-elisp-help ()
  (interactive)
  (let ((sym (intern-soft (thing-at-point 'symbol))))
    (cond
     ((and sym
	   (fboundp sym)
	   (not (boundp sym)))
      (describe-function sym))
     ((and sym
	   (not (fboundp sym))
	   (boundp sym))
      (describe-variable sym))
     ((and sym
	   (fboundp sym)
	   (boundp sym))
      (if (yes-or-no-p "Both value and function are bound; describe function? ")
	  (describe-function sym)
	(describe-variable sym)))
     (t
      (call-interactively 'describe-function)))))
(define-key emacs-lisp-mode-map (kbd "<f9>") 'easymacs-elisp-help)
(define-key emacs-lisp-mode-map (kbd "<f10>")  'completion-at-point)
(define-key emacs-lisp-mode-map (kbd "<f11>") 'eval-last-sexp)
(define-key emacs-lisp-mode-map (kbd "<f12>") 'eval-defun)

(autoload 'turn-on-eldoc-mode "eldoc" nil t)
(add-hook 'emacs-lisp-mode-hook '(lambda ()
				   (turn-on-eldoc-mode)
				   (diminish 'eldoc-mode)))
(add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)
(add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)

;;; XML

(setq auto-mode-alist
      (cons '("\\.x?html\\'" . nxml-mode) auto-mode-alist))
(setq magic-mode-alist
          (cons '("<\\?xml\\s " . nxml-mode) magic-mode-alist))

(defun easymacs-xhtml-outline-level ()
  (let ((tag (buffer-substring (match-beginning 1) (match-end 1))))
    (if (eq (length tag) 2)
	(- (aref tag 1) ?0)
      0)))
(defun easymacs-xhtml-extras ()
  (make-local-variable 'outline-regexp)
  (setq outline-regexp "\\s *<\\([h][1-6]\\|html\\|body\\|head\\)\\b")
  (make-local-variable 'outline-level)
  (setq outline-level 'easymacs-xhtml-outline-level)
  (outline-minor-mode 1)
  (hs-minor-mode 1))


;; For folding elements 
(add-to-list 'hs-special-modes-alist
	     '(nxml-mode
	       "<!--\\|<[^/>]>\\|<[^/][^>]*[^/]>"
	       ""
	       "<!--" ;; won't work on its own; uses syntax table
	       (lambda (arg) (easymacs-nxml-forward-element))
	       nil
	       ))
(defun easymacs-nxml-forward-element ()
  (let ((nxml-sexp-element-flag))
    (setq nxml-sexp-element-flag (not (looking-at "<!--")))
    (unless (looking-at outline-regexp)
      (condition-case nil
	  (nxml-forward-balanced-item 1)
	(error nil)))))
(add-hook 'nxml-mode-hook #'hs-minor-mode)

(defun easymacs-insert-tag (tag-name beg end)
  (interactive "sTag name: \nr")
  (if mark-active
      (save-excursion
	(goto-char beg)
	(insert "<" tag-name ">")
	(goto-char (+ end 2 (length tag-name)))
	(insert "</" tag-name ">"))
    (progn
      (insert "<" tag-name ">")
      (save-excursion
	(insert "</" tag-name ">")))))

;; from emacswiki
(defun nxml-where ()
      "Display the hierarchy of XML elements the point is on as a path."
      (interactive)
      (let ((path nil))
        (save-excursion
          (save-restriction
            (widen)
            (while (and (< (point-min) (point)) ;; Doesn't error if point is at beginning of buffer
                        (condition-case nil
                            (progn
                              (nxml-backward-up-element) ; always returns nil
                              t)
                          (error nil)))
              (setq path (cons (xmltok-start-tag-local-name) path)))
            (if (called-interactively-p t)
                (message "/%s" (mapconcat 'identity path "/"))
              (format "/%s" (mapconcat 'identity path "/")))))))

(defun easymacs-nxml-mode-hook ()
  (bind-key (kbd "<f5>") 'rng-next-error nxml-mode-map)
  (bind-key (kbd "<S-f5>") 'rng-next-error nxml-mode-map)
  (bind-key (kbd "<f9>") 'tei-html-docs-p5-element-at-point nxml-mode-map)
  (bind-key (kbd "<f10>") 'browse-url-of-buffer nxml-mode-map)
  (bind-key (kbd "<S-f10>") 'nxml-where nxml-mode-map)
  (bind-key (kbd "<f11>") 'easymacs-insert-tag nxml-mode-map)
  (bind-key (kbd "<C-f11>") 'nxml-split-element nxml-mode-map)
  (bind-key (kbd "<f12>") 'nxml-complete nxml-mode-map)
  (bind-key (kbd "<S-f12>") 'nxml-finish-element nxml-mode-map)
  (bind-key (kbd "<M-f12>") 'nxml-dynamic-markup-word nxml-mode-map)
  (bind-key (kbd "<C-f12>") 'nxml-balanced-close-start-tag-block
	    nxml-mode-map)
  (bind-key (kbd "<C-S-f12>") 'nxml-balanced-close-start-tag-inline
	    nxml-mode-map) 

  (when (and (buffer-file-name)
	     (string-match "\\.xhtml$"
			   (file-name-sans-versions (buffer-file-name))))
    (easymacs-xhtml-extras)))
(add-hook 'nxml-mode-hook 'easymacs-nxml-mode-hook)

(provide 'easymacs)

;;; easymacs.el ends here

