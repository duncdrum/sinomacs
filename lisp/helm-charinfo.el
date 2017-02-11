;;; helm-charinfo.el --- A helm source for character information
;; -*- coding: utf-8 -*-
;; created [2016-04-15T12:59:30+0900]
;;
;; Copyright (c) 2016 Christian Wittern
;;
;; Author: Christian Wittern <cwittern@gmail.com>
;; URL: https://github.com/cwittern/helm-charinfo
;; Version: 0.01
;; Keywords: convenience
;; Package-Requires: ((emacs "24") (helm "1.7.0") (cl-lib "0.5"))
;; This file is not part of GNU Emacs.

;;; Code:

(require 'helm)

(defcustom helm-charinfo-follow-delay 1
  "Delay before Dictionary summary pops up."
  :type 'number
  :group 'helm-charinfo)

(defcustom helm-charinfo-unihan-url "http://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip"
  "URL of the downloadable Unihan database on the Unicode website. "
  :type 'string
  :group 'helm-charinfo)

(defcustom helm-charinfo-unihan-readings
  (car
   (remove nil
	   (cl-mapcar  (lambda (x) (car (file-expand-wildcards x)))
		       (list "/Users/*/src/Unihan/Unihan_Readings.txt" ;;my system :-(
			     (concat mandoku-sys-dir "Unihan_Readings.txt")
			     ;;TODO Add suitable paths for other operating system
			     ))))
  "Location of unihan files."
  :type 'string
  :group 'helm-charinfo)

(defvar helm-charinfo-dia-charmap 
         [
          ["á\\|à\\|â\\|ä\\|ā\\|ǎ\\|ã\\|å\\|ą" "a"]
          ["é\\|è\\|ê\\|ë\\|ē\\|ě\\|ę" "e"]
          ["í\\|ì\\|î\\|ï\\|ī\\|ǐ" "i"]
          ["ó\\|ò\\|ô\\|ö\\|õ\\|ǒ\\|ø\\|ō" "o"]
          ["ú\\|ù\\|û\\|ü\\|ū"     "u"]
          ["Ý\\|ý\\|ÿ"     "y"]
          ["ç\\|č\\|ć" "c"]
          ["ď\\|ð" "d"]
          ["ľ\\|ĺ\\|ł" "l"]
          ["ñ\\|ň\\|ń" "n"]
          ["þ" "th"]
          ["ß" "ss"]
          ["æ" "ae"]
          ["š\\|ś" "s"]
          ["ť" "t"]
          ["ř\\|ŕ" "r"]
          ["ž\\|ź\\|ż" "z"]
          ])

(defvar helm-charinfo-chartab nil)
(defvar helm-charinfo-selected nil)

(defun helm-charinfo-get-unihan ()
  (let ((target (expand-file-name "Unihan.zip" mandoku-sys-dir ))
	(readings (file-name-nondirectory helm-charinfo-unihan-readings)))
    (unless (file-exists-p target)
      (message "Downloading Unihan readings file from Unicode website.")
      (url-copy-file helm-charinfo-unihan-url  target)
      (if (file-exists-p target)
	  (with-current-buffer (find-file-noselect helm-charinfo-unihan-readings)
	    (erase-buffer)
	    (archive-zip-extract target readings)
	    (save-buffer)
	    (kill-buffer)
	    (message "Successfully downloaded Unihan readings file from the Unicode website."))
	(message (format "Could not download Unihan readings file from %s." unihan-url))))))

(defun helm-charinfo-remove-tonemarks (str)
  (let ((s str))
    (mapc
     (lambda (pair)
       (setq s (replace-regexp-in-string
	(elt pair 0) (elt pair 1) s)))
     helm-charinfo-dia-charmap)
  s))

(defun helm-charinfo-do-chartab ()
  "Read the Unihan Readings into helm-charinfo-chartab"
  (setq helm-charinfo-chartab (make-hash-table :test 'equal))
  (when (file-exists-p helm-charinfo-unihan-readings)
    (with-temp-buffer
      (let ((coding-system-for-read 'utf-8)
	    textid)
	(insert-file-contents helm-charinfo-unihan-readings) ;
	(goto-char (point-min))
	(while (re-search-forward "^\\(U[^
]+\\)\t\\([^\t
]+\\)\t\\([^\t
]+\\)$" nil t)
	  (let ((type (match-string 2))
		(def (match-string 3))
		(unicode (match-string 1))
		tchar)
	    ;; U+5364	kHanyuPinyin	10093.130:xī,lǔ 74609.020:lǔ,xī
	    ;; there could be duplicates? remove them
	    (setq tchar (gethash unicode helm-charinfo-chartab))
	    (if (string= type "kMandarin")
		(puthash unicode (plist-put tchar :kMandarin def)  helm-charinfo-chartab)
	      (if (string= type "kHanyuPinyin")
		  (puthash unicode (plist-put tchar :kHanyuPinyin
					      (split-string (car (split-string (cadr (split-string def ":")) " "))",")
					      )  helm-charinfo-chartab)
		(when (string= type "kDefinition")
		  (puthash unicode (plist-put tchar :kDefinition def)  helm-charinfo-chartab))))
	    ))))))

(defun helm-charinfo-get-pinyin (str &optional all)
  ;; todo: use better pinyin table with less rare forms!
  "Lookup pinyin for all characters in term, using the most
frequent pinyin reading if there are several possibilities. If
the optional argument is set to t, give all pinyin forms. "
  (unless helm-charinfo-chartab
    (helm-charinfo-do-chartab))
  (let* ((chars (string-to-list str))
	 (pys (mapcar (lambda (x)
			(let ((c  (gethash (format "U+%4.4X" x) helm-charinfo-chartab)) v)
			  (if (setq v (plist-get c :kHanyuPinyin))
			      (if (and all (> (length v) 1))
				  (concat "[" (mapconcat 'identity v "/") "]")
				(car v))
			    (plist-get c :kMandarin))))
                        chars)))
      (unless (memq nil pys) (apply 'concat pys))))

(defun helm-charinfo-get-candidates ()
  (unless helm-charinfo-chartab
    (helm-charinfo-do-chartab))
  (let (l x d)
    (maphash (lambda (k v)
	       (setq d (or (plist-get v :kDefinition) ""))
	       (if (dolist (x (plist-get v :kHanyuPinyin))
		     (push
		      (format "%c  %-8s %-8s %-10s %s"
			      (string-to-number (substring k 2) 16)  x
			      (helm-charinfo-remove-tonemarks x) k d) l ))
		   (if (plist-get v :kMandarin)
		       (push
			(format "%c %-8s %-8s %-10s %s"
				(string-to-number (substring k 2) 16)
				(plist-get v :kMandarin)
				(helm-charinfo-remove-tonemarks (plist-get v :kMandarin))
				k d ) l )
		 )))
	     helm-charinfo-chartab)
    ;(sort l 'string-lessp)
    (nreverse l)
    ))

(defvar helm-charinfo-source
  (helm-build-sync-source "Charinfo: Lookup characters by associated information:"
    :candidates #'helm-charinfo-get-candidates
    :action '(("Select" . (lambda (candidate)
			    (setq helm-charinfo-selected candidate)))
	       )
    :requires-pattern 1))
  
(defun helm-charinfo (&optional c)
  (interactive)
  (helm :sources 'helm-charinfo-source
	:buffer "*helm dictionary*"
	:input (or c (thing-at-point 'word))))
  
(provide 'helm-charinfo)


