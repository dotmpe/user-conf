# Install scripts at user dirs if they have Git Annex'ed content

# XXX: not used but may want to auto-add sync/fsck check capabilities to some
# repos/checkouts?

env:uconf-annex:define ()
{
  true "${USERDIRS:=$(echo "$HOME"/{Desktop,Documents,Downloads,Music,Pictures,Videos})}"
}

uconf-annex:init ()
{
  declare bd
  for bd in $USERDIRS
  do
    test -e "$bd/.git/annex/objects/" || continue

    test -e "$bd/build-lib.sh" || {
      test ! -h "$bd/build-lib.sh" || rm -v "$bd/build-lib.sh"
      ln -vs "${UCONF:?}/script/annex-uc.lib.sh" "$bd/build-lib.sh"
    }
  done >&2

  # TODO: install local default.do and annex lib/rules into annex checkouts
  # without internal redo setup. See env:uconf-local:init
  for bd in /srv/annex-local/*/
  do
    test -e "$bd/.build-rules.txt" || {
      test ! -h "$bd/.build-rules.txt" || rm -v "$bd/.build-rules.txt"
      echo ln -vs "${UCONF:?}/user/build/annex.list" "$bd/.build-rules.txt"
    }
  done >&2
}

#
