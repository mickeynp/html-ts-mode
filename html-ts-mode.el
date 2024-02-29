;;; html-ts-mode.el --- html ts mode for Combobulate             -*- lexical-binding: t; -*-

;; Copyright (C) 2022-2023  Mickey Petersen

;; Author: Mickey Petersen <mickey@masteringemacs.org>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:
(require 'treesit)
(require 'sgml-mode)

(defvar html-ts-font-lock-rules
  '(;; HTML font locking
    :language html
    :feature delimiter
    ([ "<!" "<" ">" "/>" "</"] @font-lock-bracket-face)

    :language html
    :feature comment
    ((comment) @font-lock-comment-face)

    :language html
    :feature attribute
    ((attribute (attribute_name)
                @font-lock-constant-face
                "=" @font-lock-bracket-face
                (quoted_attribute_value) @font-lock-string-face))

    :language html
    :feature tag
    ((script_element
      [(start_tag (tag_name) @font-lock-doc-face)
       (end_tag (tag_name) @font-lock-doc-face)]))

    :language html
    :feature tag
    ([(start_tag (tag_name) @font-lock-function-call-face)
      (self_closing_tag (tag_name) @font-lock-function-call-face)
      (end_tag (tag_name)  @font-lock-function-call-face)])
    :language html
    :override t
    :feature tag
    ((doctype) @font-lock-keyword-face)))

(defun html-ts-imenu-node-p (node)
  "Return t if NODE is a valid imenu node."
  (and (string-match-p "^h[0-6]$" (treesit-node-text node))
       (equal (treesit-node-type (treesit-node-parent node))
              "start_tag")))

(defun html-ts-imenu-name-function (node)
  "Return the name of the imenu entry for NODE."
  (let ((name (treesit-node-text node)))
    (if (html-ts-imenu-node-p node)
        (concat name " / "
                (thread-first (treesit-node-parent node)
                              (treesit-node-next-sibling)
                              (treesit-node-text)))
      name)))

(defun html-ts-setup ()
  "Setup for `html-ts-mode'."
  (interactive)
  (setq-local treesit-font-lock-settings
              (apply #'treesit-font-lock-rules
                     html-ts-font-lock-rules))
  (setq-local font-lock-defaults nil)
  (setq-local treesit-font-lock-feature-list
              '((comment)
                (constant tag attribute)
                (declaration)
                (delimiter)))
  (setq-local treesit-simple-imenu-settings
              `(("Heading" html-ts-imenu-node-p nil html-ts-imenu-name-function)))

  (setq-local treesit-font-lock-level 5)
  (setq-local treesit-simple-indent-rules
              `((html
                 ;; Note: in older grammars, `document' was known as
                 ;; `fragment'.
                 ((parent-is "document") parent-bol 0)
                 ((node-is ,(regexp-opt '("element" "self_closing_tag"))) parent 2)
                 ((node-is "end_tag") parent 0)
                 ((node-is "/") parent 0)
                 ((parent-is "element") parent 2)
                 ((node-is "text") parent 0)
                 ((node-is "attribute") prev-sibling 0)
                 ((node-is ">") parent 0)
                 ((parent-is "start_tag") prev-sibling 0)
                 (no-node parent 0))))
  (treesit-major-mode-setup))

;;;###autoload
(define-derived-mode html-ts-mode sgml-mode "HTML[ts]"
  "Major mode for editing HTML."
  :syntax-table sgml-mode-syntax-table
  (when (treesit-ready-p 'html)
    (treesit-parser-create 'html)
    (html-ts-setup)))

(provide 'html-ts-mode)
;;; html-ts-mode.el ends here
