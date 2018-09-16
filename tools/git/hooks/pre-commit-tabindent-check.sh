#!/bin/sh

grep -lsrI '^\ \ \+' --exclude '*.rst' * && {
  echo
  echo "Aborted: Leading double-spaces or more: should use tab for indentation."
  echo "See file list above. "
  exit 1
} || {
  echo "File indentation looks good"
  exit 0
}

# Id: user-conf/0.2.0-dev git/hooks/pre-commit-tabindent-check.sh
