#!/usr/bin/env bash

# XXX: could combine all recipes in file, but that brings problems as changes
# affect all targets in the file. Instead, some generated default.do that
# uses external files can create its own internal (virtual) target scheme, the
# values of which are then validated with redo-stamp.

# The generate could make files similar to build-select.sh

xredo_name=-uc-build.user.default.default.do.bash.do
redo-ifchange ".local/cache/PATH-ucbuild-type-parts.sh"
. ".local/cache/PATH-ucbuild-type-parts.sh"
stderr declare ucbuild_type_parts

#
