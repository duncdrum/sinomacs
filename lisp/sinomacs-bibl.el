;;; sources for texts

(defun sinomacs-bibl-read-catalogs ()
  (dolist (file sinomacs-bibl-catalog-files)
    (when (file-exists-p file)
      (with-temp-buffer
	(let ((coding-system-for-read 'utf-8)
	      (lcnt 0)
	      tvol textid)
	  (insert-file-contents file)
	  (goto-char (point-min))
	  (while (not (eobp))
	    (forward-line 1)
	    (incf lcnt)
	    (if (looking-at "*")
                (while (re-search-forward "^\\([A-z0-9]+\\)	\\([^	]+\\)	\\([^	
]+\\)" nil t)
                  (puthash (match-string 1) (match-string 3) mandoku-titles)
                  (puthash (match-string 1) (match-string 2) mandoku-textdates)
                  (if (< (length (match-string 1)) 6)
                      (puthash (match-string 1) (match-string 3) mandoku-subcolls))
	  )))))
)))

(defun sinomacs-bibl-helm-candidates ()
  "Helm source for text lists"
  (let (l x)
    (unless mandoku-initialized-p
      (mandoku-initialize))
    ;; first lets add the mandoku titles
    (maphash (lambda (k v)
	       (push (concat k " " (replace-regexp-in-string "-" " " v)) l))
	        mandoku-titles)
    ;; now process the other catalogs
    (sort l 'string-lessp)
    ))

(defun sinomacs-bibl-helm ()
  (interactive)
  (let ((sinomacs-bibl-helm-source
      '((name . "Texts")
        (candidates . sinomacs-bibl-helm-candidates)
	;; (persistent-action . (lambda (candidate)
	;; 			    (message-box
	;; 			     (mapconcat 'identity (tls-helm-tree-candidates candidate) "\n")
	;; 			     )))
        (action . (("Open" . (lambda (candidate)
			       (let ((c (substring candidate 0 2)))
				 (cond ((equal c "KR")
					(org-open-link-from-string (concat "mandoku:" (car (split-string candidate " ")))))
					((equal c "XX")
					 (find-file "/tmp/testb.txt"))
;			       (find-file
;				(concat mandoku-tls-lexicon-path "concepts/" mandoku-tls-concept ".org") t)
			       (message "%s" candidate))))))
		)))
	(fallback-source '((name . "Create new concept")
                          (dummy)
                          (action . mandoku-tls-create-new-annot)) ))

    (helm :sources '(sinomacs-bibl-helm-source fallback-source))))

;; utility functions

(defun sinomacs-bibl-split-authors (v &optional shorten)
  (let* ((a (split-string v "cjk="))
	 (b (if (string-match "[ ?,\t\n\r]+\\'" (car a))
		(replace-match "" t t (car a))
	      (car a)))
	 (f   (if (string-match "=" b)
		  (mapcar (lambda (x)
			    (let* ((f (split-string x "="))
				   prop val)
			      (if (= 1 (length f))
				  (progn
				    (setq prop "gomi"
					  val (s-trim (car f))))
				(progn
				  (setq prop (s-trim (nth 0 f))
					val (s-trim (nth 1 f)))))
			      (cons prop val)))
			  (s-split "," b t))
		(list (cons "family"  b))))
	 y)
    (if (cadr a)
	(push (cons "cjk" (cadr a)) f))
    (setq y
	  (if (or shorten
		  (not (assoc-string "given" f)))
	      (if (assoc-string "cjk" f)
		  (s-format "${family} (${cjk})" 'aget f)
		(s-format "${family}" 'aget f))
	    (if (assoc-string "cjk" f)
		(s-format "${family} ${given} (${cjk})" 'aget f)
	      (s-format "${given} ${family}" 'aget f))))
    (message y)
    y
    ))


(defun sinomacs-bibl-shorten-authors--cjk (orig-fun &rest args) ; (authors)
  "Returns a comma-separated list of the surnames in authors."
  ;{family=Huang, given=Jingui, cjk=黃金貴}
  (if (car args)
      (if (string-match "=" (iso-tex2iso (car args))
	  (cl-loop for a in (s-split " and " (car args))
		   collect (sinomacs-bibl-split-authors a t)
		    into p
		    finally return (string-join p ", ")
		    ;; (let ((l (length p)))
		    ;;   (if (eq 1 l)
		    ;; 	  (concat (-last-item (s-split " +" (car p) t)))
		    ;; 	(concat (car p)))))
		    )
	(apply orig-fun args))
    nil)))

;(defun sinomacs-format--cjk-authors (value)
(defun sinomacs-bibl-format--cjk-authors (orig-fun &rest args)
  "Format authors my way."
  (if (string-match "=" value )
  (cl-loop for
	   a in (s-split " and " value t)
	   collect
		    (let ((fields
			   (mapcar (lambda (x)
				     (let* ((f (split-string x "="))
					    (prop (s-trim (nth 0 f)))
					    (val (s-trim (nth 1 f))))
				       (cons prop val)))
				   (s-split "," a t))))
		      (if (and (s--aget fields "family")
			       (s--aget fields "cjk"))
			  (s-format "${family} (${cjk})" 'aget fields)
;			  (s-format "${given} ${family} (${cjk})" 'aget fields)
			(if (s--aget fields "family")
			    (s-format "${family}" 'aget fields)
			  (if (s--aget fields "cjk")
			      (s-format "${cjk}" 'aget fields)
			    (string-join fields " ")))))
		    into authors
		    finally return
		    (let ((l (length authors)))
		      (cond
		       ((= l 1) (car authors))
		       ((= l 2) (s-join " & " authors))
		       ((< l 8) (concat (s-join ", " (-butlast authors))
					", & " (-last-item authors)))
		       (t (concat (s-join ", " authors) ", ...")))))
  (apply orig-fun args)
  ))

(advice-add 'bibtex-completion-shorten-authors :around #'sinomacs-bibl-shorten-authors--cjk)
(advice-add 'bibtex-completion-apa-format-authors :around #'sinomacs-bibl-format--cjk-authors)

;; extending the built-in table, I guess thats a bad thing to do....
(setq iso-tex2iso-trans-tab
  '(
    ("{\\\\=a}" "ā")
    ("{\\\\=e}" "ē")
    ("{\\\\=i}" "ī")
    ("{\\\\=\\\\i}" "ī")
    ("{\\\\=o}" "ō")
    ("{\\\\=u}" "ū")
    ("{\\\\=A}" "Ā")
    ("{\\\\=E}" "Ē")
    ("{\\\\=I}" "Ī")
    ("{\\\\=O}" "Ō")
    ("{\\\\=U}" "Ū")
    ("{\\\\\"a}" "ä")
    ("{\\\\`a}" "à")
    ("{\\\\'a}" "á")
    ("{\\\\~a}" "ã")
    ("{\\\\^a}" "â")
    ("{\\\\\"e}" "ë")
    ("{\\\\`e}" "è")
    ("{\\\\'e}" "é")
    ("{\\\\^e}" "ê")
    ("{\\\\\"\\\\i}" "ï")
    ("{\\\\`\\\\i}" "ì")
    ("{\\\\'\\\\i}" "í")
    ("{\\\\^\\\\i}" "î")
    ("{\\\\\"i}" "ï")
    ("{\\\\`i}" "ì")
    ("{\\\\'i}" "í")
    ("{\\\\^i}" "î")
    ("{\\\\\"o}" "ö")
    ("{\\\\`o}" "ò")
    ("{\\\\'o}" "ó")
    ("{\\\\~o}" "õ")
    ("{\\\\^o}" "ô")
    ("{\\\\\"u}" "ü")
    ("{\\\\`u}" "ù")
    ("{\\\\'u}" "ú")
    ("{\\\\^u}" "û")
    ("{\\\\\"A}" "Ä")
    ("{\\\\`A}" "À")
    ("{\\\\'A}" "Á")
    ("{\\\\~A}" "Ã")
    ("{\\\\^A}" "Â")
    ("{\\\\\"E}" "Ë")
    ("{\\\\`E}" "È")
    ("{\\\\'E}" "É")
    ("{\\\\^E}" "Ê")
    ("{\\\\\"I}" "Ï")
    ("{\\\\`I}" "Ì")
    ("{\\\\'I}" "Í")
    ("{\\\\^I}" "Î")
    ("{\\\\\"O}" "Ö")
    ("{\\\\`O}" "Ò")
    ("{\\\\'O}" "Ó")
    ("{\\\\~O}" "Õ")
    ("{\\\\^O}" "Ô")
    ("{\\\\\"U}" "Ü")
    ("{\\\\`U}" "Ù")
    ("{\\\\'U}" "Ú")
    ("{\\\\^U}" "Û")
    ("{\\\\~n}" "ñ")
    ("{\\\\~N}" "Ñ")
    ("{\\\\c c}" "ç")
    ("{\\\\c C}" "Ç")
    ("\\\\\"a" "ä")
    ("\\\\`a" "à")
    ("\\\\'a" "á")
    ("\\\\~a" "ã")
    ("\\\\^a" "â")
    ("\\\\\"e" "ë")
    ("\\\\`e" "è")
    ("\\\\'e" "é")
    ("\\\\^e" "ê")
    ;; Discard spaces and/or one EOF after macro \i.
    ;; Converting it back will use braces.
    ("\\\\\"\\\\i *\n\n" "ï\n\n")
    ("\\\\\"\\\\i *\n?" "ï")
    ("\\\\`\\\\i *\n\n" "ì\n\n")
    ("\\\\`\\\\i *\n?" "ì")
    ("\\\\'\\\\i *\n\n" "í\n\n")
    ("\\\\'\\\\i *\n?" "í")
    ("\\\\^\\\\i *\n\n" "î\n\n")
    ("\\\\^\\\\i *\n?" "î")
    ("\\\\\"i" "ï")
    ("\\\\`i" "ì")
    ("\\\\'i" "í")
    ("\\\\^i" "î")
    ("\\\\\"o" "ö")
    ("\\\\`o" "ò")
    ("\\\\'o" "ó")
    ("\\\\~o" "õ")
    ("\\\\^o" "ô")
    ("\\\\\"u" "ü")
    ("\\\\`u" "ù")
    ("\\\\'u" "ú")
    ("\\\\^u" "û")
    ("\\\\\"A" "Ä")
    ("\\\\`A" "À")
    ("\\\\'A" "Á")
    ("\\\\~A" "Ã")
    ("\\\\^A" "Â")
    ("\\\\\"E" "Ë")
    ("\\\\`E" "È")
    ("\\\\'E" "É")
    ("\\\\^E" "Ê")
    ("\\\\\"I" "Ï")
    ("\\\\`I" "Ì")
    ("\\\\'I" "Í")
    ("\\\\^I" "Î")
    ("\\\\\"O" "Ö")
    ("\\\\`O" "Ò")
    ("\\\\'O" "Ó")
    ("\\\\~O" "Õ")
    ("\\\\^O" "Ô")
    ("\\\\\"U" "Ü")
    ("\\\\`U" "Ù")
    ("\\\\'U" "Ú")
    ("\\\\^U" "Û")
    ("\\\\~n" "ñ")
    ("\\\\~N" "Ñ")
    ("\\\\\"{a}" "ä")
    ("\\\\`{a}" "à")
    ("\\\\'{a}" "á")
    ("\\\\~{a}" "ã")
    ("\\\\^{a}" "â")
    ("\\\\\"{e}" "ë")
    ("\\\\`{e}" "è")
    ("\\\\'{e}" "é")
    ("\\\\^{e}" "ê")
    ("\\\\\"{\\\\i}" "ï")
    ("\\\\`{\\\\i}" "ì")
    ("\\\\'{\\\\i}" "í")
    ("\\\\^{\\\\i}" "î")
    ("\\\\\"{i}" "ï")
    ("\\\\`{i}" "ì")
    ("\\\\'{i}" "í")
    ("\\\\^{i}" "î")
    ("\\\\\"{o}" "ö")
    ("\\\\`{o}" "ò")
    ("\\\\'{o}" "ó")
    ("\\\\~{o}" "õ")
    ("\\\\^{o}" "ô")
    ("\\\\\"{u}" "ü")
    ("\\\\`{u}" "ù")
    ("\\\\'{u}" "ú")
    ("\\\\^{u}" "û")
    ("\\\\\"{A}" "Ä")
    ("\\\\`{A}" "À")
    ("\\\\'{A}" "Á")
    ("\\\\~{A}" "Ã")
    ("\\\\^{A}" "Â")
    ("\\\\\"{E}" "Ë")
    ("\\\\`{E}" "È")
    ("\\\\'{E}" "É")
    ("\\\\^{E}" "Ê")
    ("\\\\\"{I}" "Ï")
    ("\\\\`{I}" "Ì")
    ("\\\\'{I}" "Í")
    ("\\\\^{I}" "Î")
    ("\\\\\"{O}" "Ö")
    ("\\\\`{O}" "Ò")
    ("\\\\'{O}" "Ó")
    ("\\\\~{O}" "Õ")
    ("\\\\^{O}" "Ô")
    ("\\\\\"{U}" "Ü")
    ("\\\\`{U}" "Ù")
    ("\\\\'{U}" "Ú")
    ("\\\\^{U}" "Û")
    ("\\\\~{n}" "ñ")
    ("\\\\~{N}" "Ñ")
    ("\\\\c{c}" "ç")
    ("\\\\c{C}" "Ç")
    ("{\\\\ss}" "ß")
    ("{\\\\pounds}" "£" )
    ("{\\\\P}" "¶" )
    ("{\\\\S}" "§" )
    ("\\\\pounds{}" "£" )
    ("\\\\P{}" "¶" )
    ("\\\\S{}" "§" )
    ("{\\?`}" "¿")
    ("{!`}" "¡")
    ("\\?`" "¿")
    ("!`" "¡")
    ))
;; these cause coding errors.
;; ("{\\\\AE}" "\306")
;; ("{\\\\ae}" "\346")
;; ("{\\\\AA}" "\305")
;; ("{\\\\aa}" "\345")
;; ("{\\\\copyright}" "\251")
;; ("\\\\copyright{}" "\251")

;; sinomacs-bibl ends here
