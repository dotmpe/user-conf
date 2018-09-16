#!/bin/sh

#grep -lsrI '^\t\+' *
grep -nsrI '^\t\+' \
    --exclude '*~' \
    --exclude 'Makefile*' \
    --exclude '*.mk' \
    --exclude '*.y*ml' \
    --exclude '*.diff' \
    --exclude-dir 'node_modules*' \
    --exclude-dir 'bower_components*' \
    --exclude-dir 'vendor*' \
    --exclude '*.lock' \
    --exclude '*.html' \
    --exclude '*.twig' \
    --exclude '*.rst' * && {
  echo
  echo "Aborted: Leading tabs found: should use spaces for indentation."
  echo "See file list above. "
  exit 1
} || {
  echo "File indentation looks good"
  exit 0
}

# Id: user-conf/0.2.0-dev git/hooks/pre-commit-spaceindent-check.sh
