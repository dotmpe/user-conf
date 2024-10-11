#!/usr/bin/env bash

xredo_name=-uc-build.user.default.type.bash.do

redo-ifchange ".local/cache/PATH-ucbuild-type-recipes.sh"
. ".local/cache/PATH-ucbuild-type-recipes.sh"

cat <<EOM
us-env -r user-script &&
lib_require sys os &&

xredo_name=-uc-build.user.default.type.bash.do
case "\${2:?}" in

$(
  for recipe in "${ucbuild_type_recipes[@]}"
  do
    echo "( ) . $recipe ;;"
  done
)
( * )
stderr echo ? \$2
stderr echo do file \$xredo_name
stderr echo \t1=\$1
stderr echo \t2=\$2
stderr echo \t3=\$3
stderr declare -p REDO_{BASE,PWD,STARTDIR}
false
  ;;
esac
EOM

#
