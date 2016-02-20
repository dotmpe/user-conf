#!/usr/bin/env bats

base=boilerplate
load helper
init


@test "u-c update" {
 
  scriptdir=$(pwd)/script
  #TMPDIR=/tmp/uc-test-$(uuidgen)
  TMPDIR=/tmp/uc-test
  mkdir -vp $TMPDIR
  cd $TMPDIR

  # Test using 3 SH directives
  echo "SH echo 1 | tee /tmp/1" > Userconf
  echo "SH echo foo | tee -a /tmp/1" >> Userconf
  echo "SH echo bar | tee -a /tmp/1" >> Userconf

  $scriptdir/user-conf/update.sh
  test "$(echo $(wc -l /tmp/1))" = "3 /tmp/1"

  $scriptdir/user-conf/update.sh 2
  test "$(echo $(wc -l /tmp/1))" = "4 /tmp/1"
  $scriptdir/user-conf/update.sh 2
  test "$(echo $(wc -l /tmp/1))" = "5 /tmp/1"

  $scriptdir/user-conf/update.sh 1
  test "$(echo $(wc -l /tmp/1))" = "1 /tmp/1"

  rm -rf /tmp/1
}

