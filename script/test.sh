#!/bin/sh

# Test script: run Bats tests


PROJ_DIR="$(dirname "$(dirname "$0")")"
test "$PROJ_DIR" = "." && PROJ_DIR="$(pwd)"

BASE_DIR="$(dirname "$PROJ_DIR")"
BASE_NAME="$(basename "$PROJ_DIR")"

test "$PROJ_DIR" = "$(pwd)" || cd "$BASE_DIR/$BASE_NAME"

./test/*-spec.bats

