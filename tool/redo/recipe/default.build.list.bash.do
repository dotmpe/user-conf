#!/usr/bin/env bash

# Compile recipe list given class

# As a source, this uses the local context table
build_list=${META_DIR:-.meta}/tab/build.list

redo-ifchange "$build_list"

XREDO_NAME=${2:?}
stderr declare -p XREDO_NAME

#target_list=${META_DIR:-.meta}/tab/build-${2:?}.list
#[[ -e $build_list ]]
