

match_grep_pattern_test()
{
  p_="$(echo "$1" | sed -E 's/([^A-Za-z0-9{}(),!@+_])/\\\1/g')"
  # test regex
  echo "$1" | grep "^$p_$" >> /dev/null || {
    err "cannot build regex for $1: $p_"
    return 1
  }
}

