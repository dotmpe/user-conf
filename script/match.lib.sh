

# To escape filenames and perhaps other values for use as grep literals
match_grep_pattern_test()
{
  p_="$(match_grep "$1")"
  # test regex (nice for dev mode)
  echo "$1" | grep -q "^$p_$" || {
    error "cannot build regex for $1: $p_"
    echo "$p" > invalid.paths
    return 1
  }
}

