for var in REDO_TARGET REDO_BASE REDO_PWD REDO_STARTDIR
do
  # XXX: would use printf %q or similar, but not sure about any standard there
  # so this could mess up terminal (wether via log or not)
  echo "$var=$(eval "echo \$$var")" >&2
done && unset var
