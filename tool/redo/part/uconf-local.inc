# Install scripts at basedirs that are not Git checkouts

env:uconf-local:define ()
{
  true "${USERDIRS:=$(echo "$HOME"/{Desktop,Documents,Downloads,Music,Pictures,Videos})}"
}

uconf-local:init ()
{
  declare bd
  for bd in $USERDIRS
  do
    test -e "$bd/default.do" || {
      test ! -h "$bd/default.do" || rm -v "$bd/default.do"
      ln -vs "${UCONF:?}/tool/redo/local.do" "$bd/default.do"
    }

    test -e "$bd/.properties" || {
      test ! -h "$bd/.properties" || rm -v "$bd/.properties"
      ln -vs "${UCONF:?}/etc/package/local.asis" "$bd/.properties"
    }

    test -e "$bd/.build-rules.list" || {
      test ! -h "$bd/.build-rules.list" || rm -v "$bd/.build-rules.list"
      bn=$(basename "$bd")
      test -e "${UCONF:?}/user/build/$bn.list" && {
        ln -vs "${UCONF:?}/user/build/$bn.list" "$bd/.build-rules.list"
      } || {
        ln -vs "${UCONF:?}/user/build/local.list" "$bd/.build-rules.list"
      }
    }

    test -e "$bd/index.list" || {
      test ! -h "$bd/index.list" || rm -v "$bd/index.list"
      bn=$(basename "$bd")
      test -e "${UCONF:?}/user/index/$bn.list" && {
        ln -vs "${UCONF:?}/user/index/$bn.list" "$bd/index.list"
      } || {
        ln -vs "${UCONF:?}/user/index/local.list" "$bd/index.list"
      }
    }

    # not needed anymore unless sh-lookup setup breaks
    #test -e "$bd/build-lib.sh" || {
    #  test ! -h "$bd/build-lib.sh" || rm "$bd/build-lib.sh"
    #  ln -vs "${UCONF:?}/build-lib.sh" "$bd/build-lib.sh"
    #}
  done >&2
}
