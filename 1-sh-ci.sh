#!/usr/bin/env bash

test ! -f ./test-env.sh || rm ./test-env.sh

. /etc/profile
. ./tools/ci/setup.sh
{ echo "# Added by Uc:/tools/ci/setup.sh <$0> on $(date --iso=min)"
  echo export scriptname=Circle-CI
} >> ~/.profile

. ./test-env.sh
. ./tools/ci/test.sh
. ./tools/ci/convert.sh

. ./tools/ci/run.sh
#
