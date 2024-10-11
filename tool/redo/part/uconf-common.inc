env:uconf-common:define ()
{
  declare pyml inst
  for pyml in ./package.y{,a}ml
  do
    test -e "$pyml" || continue
    declare -gx package_yml=$(basename "$pyml")
    break
  done
  for inst in ./requirements-{debian,ubuntu}.txt
  do
    test -e "$inst" || continue
    declare -gx os_deps=$(basename "$inst")
    break
  done
}

uconf-common:init ()
{
  { test -z "${package_yml:-}" || test ! -e "./${package_yml:?}"
  } || {
    build-ifchange ./$package_yml || return
    test "$package_yml" -ot ${PROJECT_CACHE:?}/package.json || {
      htd package update || return
    }
    # TODO: normalize remote repo specs everywhere
    #htd package remotes-reset || return
  }

  { test -z "${os_deps:-}" || test ! -e "./${os_deps:?}"
  } || {
    build-ifchange "./$os_deps" || return
    set -- $(< "$os_deps") &&
    sudo apt install "$@" || return
  }

  test ! -e ./requirements.txt || {
    build-ifchange ./requirements.txt &&
    pip install -r ./requirements.txt || return
  }

  test ! -e ./package.json || {
    build-ifchange ./package.json &&
    ( NODE_ENV=development npm install ) || return
  }
}

#
