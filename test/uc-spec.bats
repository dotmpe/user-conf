#!/usr/bin/env bats

base=boilerplate
load helper
init


@test "1. u-c update - executes SH directives, and by index number" {

  scriptdir=$(pwd)/script
  TMPDIR=/tmp/uc-spec-1-update
  mkdir -vp $TMPDIR
  cd $TMPDIR

  # Test using 3 SH directives
  echo "SH echo 1 | tee /tmp/1" > Userconf
  echo "SH echo foo | tee -a /tmp/1" >> Userconf
  echo "SH echo bar | tee -a /tmp/1" >> Userconf

  test ! -e /tmp/1 || rm /tmp/1

  $scriptdir/user-conf/update.sh
  test "$(echo $(wc -l /tmp/1))" = "3 /tmp/1"

  $scriptdir/user-conf/update.sh 2
  test "$(echo $(wc -l /tmp/1))" = "4 /tmp/1"
  $scriptdir/user-conf/update.sh 2
  test "$(echo $(wc -l /tmp/1))" = "5 /tmp/1"

  $scriptdir/user-conf/update.sh 1
  test "$(echo $(wc -l /tmp/1))" = "1 /tmp/1"

  rm -rf /tmp/1 $TMPDIR
}

@test "2. u-c update - processes ENV directives, and by index number" {

  scriptdir=$(pwd)/script
  TMPDIR=/tmp/uc-spec-2-update
  mkdir -vp $TMPDIR
  cd $TMPDIR

  # Test using 3 SH directives
  echo "ENV domain=example" > Userconf
  echo 'SH echo $domain | tee /tmp/2' >> Userconf

  test ! -e /tmp/2 || rm /tmp/2

  $scriptdir/user-conf/update.sh
  test "$(echo $(wc -l /tmp/2))" = "1 /tmp/2"
  test "$(cat /tmp/2)" = "example"

  rm -rf /tmp/2 $TMPDIR
}

