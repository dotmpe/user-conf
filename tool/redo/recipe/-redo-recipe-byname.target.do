## Lookup recipe name on */tools/redo/recipe/

# This is redo shell compatible (so no bash bang above) but that means the
# sourced recipe also has to be.
# XXX: I would check for .bash.do and defer source to new bash session but
# not sure if that'd work or how to get which for non-executables under sh
# So using .bash.do variant instead.

# XXX: static inline config
: "${XREDO_PATH:=${C_INC:?}/tool/redo/recipe:${US_BIN:?}/tool/redo/recipe:${U_C:?}/tool/redo/recipe:${U_S:?}/tool/redo/recipe:${US_INC:?}/tool/redo/recipe:${REDO_BASE:?}/tool/redo/recipe}"

XREDO_NAME=${2:?}
case "$XREDO_NAME" in
  @* )
      XREDO_NAME="$(echo "$XREDO_NAME" | cut -c2-).class.target"
    ;;
esac

export PATH=${XREDO_PATH:?}:${PATH:?}
. "${XREDO_NAME:?}.do"
#
