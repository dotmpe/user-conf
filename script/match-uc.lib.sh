# Take any string and return a Regex to match that exact string, see
# match-grep-pattern-test.
match_grep() # String
{
  echo "$1" | $gsed -E 's/([^A-Za-z0-9{}(),?!@+_])/\\\1/g'
}


# To escape filenames and perhaps other values for use as grep literals
match_grep_pattern_test()
{
  p_="$(match_grep "$1")"
  # test regex
  echo "$1" | grep -q "^$p_$" || {
    error "cannot build regex for $1: $p_"
    return 1
  }
}
