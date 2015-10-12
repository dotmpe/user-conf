#!/bin/sh

grep -lsrI '^\t\+' * && {
  echo
  echo "Aborted: Leading tabs found: should use spaces for indentation."
  echo "See file list above. "
  exit 1
} || {
  echo "File indentation looks good"
  exit 0
}
