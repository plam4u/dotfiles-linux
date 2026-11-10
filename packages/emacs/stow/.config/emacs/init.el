(setq custom-file
	  (expand-file-name "custom.el" user-emacs-directory))

(when (file-exists-p custom-file)
  (load custom-file))

(setq inhibit-startup-screen t)
(setq ring-bell-function 'ignore)

(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)

(global-display-line-numbers-mode 1)
(column-number-mode 1)

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq make-backup-files nil)

;; remember cursor locations
(save-place-mode 1)

;; remember minibuffer history
(savehist-mode 1)

;; save recent files
(recentf-mode 1)

;; better completion
(fido-vertical-mode 1)

(setq show-paren-delay 0)

(when (display-graphic-p)
  (set-face-attribute 'default nil
                      :family "JetBrainsMono Nerd Font"
                      :height 120))

;; Enable mouse support in terminal Emacs
(unless (display-graphic-p)
  (xterm-mouse-mode 1))

;; Enable mouse wheel scrolling
(mouse-wheel-mode 1)

(setq mouse-wheel-scroll-amount '(2 ((shift) . 1)))

(setq mouse-wheel-progressive-speed 1)

(setq scroll-step 1)
(setq scroll-conservatively 101)
