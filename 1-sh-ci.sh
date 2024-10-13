#!/usr/bin/env bash

test ! -f ./test-env.sh || rm ./test-env.sh

. /etc/profile
. ./tool/ci/setup.sh
{ echo "# Added by Uc:/tool/ci/setup.sh <$0> on $(date --iso=min)"
  echo export scriptname=Circle-CI
} >> ~/.profile

. ./test-env.sh
. ./tool/ci/test.sh
. ./tool/ci/convert.sh

. ./tool/ci/run.sh
#
