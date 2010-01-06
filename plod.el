;; Plod sending commands for Emacs.

;; This file is not part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 1, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;; Suggested addition to .emacs:
;; 	(load-library "plod-mode")
;; 	(plod-alarm-on 60) ; once an hour
;;
;; When you are tired of PLODding use "M-x plod-alarm-off"
;; 
;; Alternately, use "M-x plod" whenever you want to log something.
;; 
;; paul@ascent.com (Paul Foley)	Wednesday January 20, 1993
;; paulh@harlequin.com (Paul Hudson) Later in 1993 (I forget when :-)


(provide 'plod)

(defvar send-plod-function 'plod-send-it
  "Function to call to send the current buffer as plod.")

(defvar plod-mode-map nil)

(defun plod-mode ()
  "Major mode for editing text to be sent to plod.
Like Text Mode but with these additional commands:
C-c C-s  plod-send (send the message)    C-c C-c  plod-send-and-exit"
  (interactive)
  (kill-all-local-variables)
  (make-local-variable 'plod-reply-buffer)
  (setq plod-reply-buffer nil)
  (set-syntax-table text-mode-syntax-table)
  (use-local-map plod-mode-map)
  (setq local-abbrev-table text-mode-abbrev-table)
  (setq major-mode 'plod-mode)
  (setq mode-name "Plod")
  (setq buffer-offer-save t)
  (run-hooks 'text-mode-hook 'plod-mode-hook))

(if plod-mode-map
    nil
  (setq plod-mode-map (make-sparse-keymap))
  (define-key plod-mode-map "\C-c?" 'describe-mode)
  (define-key plod-mode-map "\C-c\C-c" 'plod-send-and-exit)
  (define-key plod-mode-map "\C-c\C-s" 'plod-send))

(defun plod-send-and-exit (arg)
  "Send message like plod-send, then, if no errors, exit from plod buffer.
Prefix arg means don't delete this window."
  (interactive "P")
  (plod-send)
  (bury-buffer (current-buffer))
  (if (and (not arg)
	   (not (one-window-p)))
      (delete-window)
    (switch-to-buffer (other-buffer (current-buffer)))))

(defun plod-send ()
  "Send the message in the current buffer to plod."
  (interactive)
  (message "Sending...")
  (funcall send-plod-function)
  (set-buffer-modified-p nil)
  (delete-auto-save-file-if-necessary)
  (message "Sending...done"))

(defun plod-send-it ()
  (let ((tembuf (generate-new-buffer " plod temp"))
	(plodbuf (current-buffer)))
    (unwind-protect
	  (call-process-region (point-min) (point-max)
			       (if (boundp 'plod-program)
				   plod-program
				 "/usr/local/bin/plod")
			       nil tembuf nil)
      (kill-buffer tembuf))))


(defun plod (&optional noerase)
  "Edit a message to be sent.  Argument means resume editing (don't erase).
Returns with message buffer selected; value t if message freshly initialized.
While editing message, type C-c C-c to send the message and exit.

\\{plod-mode-map}

If plod-setup-hook is bound, its value is called with no arguments
after the message is initialized. "
  (interactive "P")
  (switch-to-buffer "*plod*")
  (setq default-directory (expand-file-name "~/"))
  (auto-save-mode auto-save-default)
  (plod-mode)
  (and (not noerase)
       (or (not (buffer-modified-p))
	   (y-or-n-p "Unsent message being composed; erase it? "))
       (progn (erase-buffer)
	      (set-buffer-modified-p nil)
	      (run-hooks 'plod-setup-hook)
	      t)))

(defun plod-other-window (&optional noerase)
  "Like `plod' command, but display plod buffer in another window."
  (interactive "P")
  (let ((pop-up-windows t))
    (pop-to-buffer "*plod*"))
  (plod noerase))


;;;
;;; Alarm interface
;;;

(defvar plod-alarm-on-p nil)		; t if alarm is on
(defvar plod-alarm-process nil)

;; run when plod-alarm-process is killed
(defun plod-alarm-sentinel (proc reason)
  (or (eq (process-status proc) 'run)
      (setq plod-alarm-on-p nil)
      (ding) 
      (message "PLOD alarm off")))

;; run every interval & at initial call to plod-alarm-on
(defun plod-alarm-filter (proc string)
  (if plod-alarm-on-p
      (plod)
    (setq plod-alarm-on-p t)))

;; Set alarm to call PLOD every so often
;;
(defun plod-alarm-on (interval)
  "Turn the Emacs PLOD alarm on.  The alarm goes off every INTERVAL minutes
and you will be switched to the PLOD buffer automatically.  
Use plod-alarm-off to stop this behaviour."
  (interactive "nEnter PLOD alarm interval (in minutes): ")
  (let ((live (and plod-alarm-process
		   (eq (process-status plod-alarm-process) 'run))))
    (if (not live)
	(progn
	  (setq plod-alarm-on-p nil)
	  (if plod-alarm-process
	      (delete-process plod-alarm-process))
	  (let ((process-connection-type nil))
	    (setq plod-alarm-process
		  (start-process "plod-alarm" nil 
				 (concat exec-directory "wakeup")
				 ; convert minutes -> seconds for wakeup
				 (int-to-string (* 60 interval)))))
	  (process-kill-without-query plod-alarm-process)
	  (set-process-sentinel plod-alarm-process 'plod-alarm-sentinel)
	  (set-process-filter plod-alarm-process 'plod-alarm-filter)))))

;; Turn PLOD alarm off
;;
(defun plod-alarm-off ()
  "Turn the Emacs PLOD alarm off."
  (interactive)
  (if plod-alarm-on-p (kill-process plod-alarm-process)))

;;; End


