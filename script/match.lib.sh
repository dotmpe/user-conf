

# To escape filenames and perhaps other values for use as grep literals
match_grep_pattern_test()
{
  p_="$(echo "$1" | sed -E 's/([^A-Za-z0-9{}(),!@+_])/\\\1/g')"
  # test regex
  echo "$1" | grep "^$p_$" >> /dev/null || {
    error "cannot build regex for $1: $p_"
    return 1
  }
}

