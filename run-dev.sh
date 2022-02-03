#!/bin/sh
set -e

# docker rm -f user-conf-dev || true

image=dotmpe/devbox:dev
image=dotmpe/treebox:dev

gh_keyfile=~/.ssh/id_rsa
kbn=id_rsa
set -x
docker run \
  -ti \
  --rm \
  --name user-conf-dev \
  --volume $(realpath /etc/localtime):/etc/localtime:ro \
  --volume $(realpath $gh_keyfile):/home/treebox/.ssh/$kbn \
  --volume $(realpath ~/.ssh/known_hosts):/home/treebox/.ssh/known_hosts \
  --volume $(pwd -P):/src/github.com/dotmpe/user-conf:ro \
  -u treebox \
  -e USER=treebox \
  -w /src/github.com/dotmpe/user-conf \
  $image "$@" </dev/tty

#
