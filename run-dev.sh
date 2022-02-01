#!/bin/sh
set -e

# docker rm -f user-conf-dev || true

image=dotmpe/devbox:dev
image=dotmpe/treebox:dev
image=dotmpe/treebox:latest

PPWD=$(pwd -P)
gh_keyfile=~/.ssh/id_rsa
kbn=id_rsa
set -x
docker run \
  -ti \
  --rm \
  --name user-conf-dev \
  --volume /src/local/user-conf-dev:/usr/lib/user-conf \
  --volume /etc/profile.d/uc-profile.sh:/etc/profile.d/uc-profile.sh \
  --volume $(realpath /etc/localtime):/etc/localtime:ro \
  --volume $(realpath $gh_keyfile):/home/treebox/.ssh/$kbn \
  --volume $(realpath ~/.ssh/known_hosts):/home/treebox/.ssh/known_hosts \
  --volume $PPWD:$PPWD:ro \
  -u treebox \
  -e USER=treebox \
  -e LOG=/etc/profile.d/uc-profile.sh \
  -w $PPWD \
  $image "$@" </dev/tty

#
