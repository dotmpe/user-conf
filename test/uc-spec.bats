#!/usr/bin/env bats

base=uc
load helper
init

@test "1. u-c update - executes SH directives, and by index number" {

  main=$PWD/bin/uc
  TMPDIR=/tmp/uc-spec-1-update
  mkdir -vp $TMPDIR
  cd $TMPDIR

  # Test using 3 SH directives
  echo "SH echo 1 | tee $TMPDIR/1" > Userconf
  echo "SH echo foo | tee -a $TMPDIR/1" >> Userconf
  echo "SH echo bar | tee -a $TMPDIR/1" >> Userconf

  $main update
  test "$(echo $(wc -l $TMPDIR/1))" = "3 $TMPDIR/1"

  $main update 2
  test "$(echo $(wc -l $TMPDIR/1))" = "4 $TMPDIR/1"
  $main update 2
  test "$(echo $(wc -l $TMPDIR/1))" = "5 $TMPDIR/1"

  $main update 1
  test "$(echo $(wc -l $TMPDIR/1))" = "1 $TMPDIR/1"

  rm -rf $TMPDIR
}

@test "2. u-c update - processes ENV directives, and by index number" {

  main=$PWD/bin/uc
  #scriptpath=$(pwd)/script
  TMPDIR=/tmp/uc-spec-2-update
  mkdir -vp $TMPDIR
  test ! -e $TMPDIR/2 || rm $TMPDIR/2
  cd $TMPDIR

  # Test using 3 SH directives
  echo "ENV domain=example" > Userconf
  echo 'SH echo $domain | tee '$TMPDIR'/2' >> Userconf

  $main update
  test "$(echo $(wc -l $TMPDIR/2))" = "1 $TMPDIR/2"
  test "$(cat $TMPDIR/2)" = "example"

  rm -rf $TMPDIR
}

