# Take any string and return a Regex to match that exact string, see
# match-grep-pattern-test.
match_grep() # String
{
  echo "$1" | $gsed -E 's/([^A-Za-z0-9{}(),?!@+_])/\\\1/g'
}

#
compile_glob()
{
  printf -- "$1" | ${2:-"perl"}_globs2regex
}

# simple glob to regex
gsed_globs2regex()
{
  gsed -E '
      s/\*/.*/g
      s/([^A-Za-z0-9{}(),?!@+_*])/\\\1/g
    '
}

# extended glob to regex with some NPM module
node_globs2regex()
{
  ( cd ~/bin; node -e '
var globToRegExp = require("glob-to-regexp");
var readline = require("readline");
var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});
rl.on("line", function(line){
  console.log(globToRegExp(line, { extended: true }).toString().slice(1,-1));
})
    ' )
}

# a working globs2regex with Perl
perl_globs2regex()
{
  perl -pe '
s{
    ( [?*]+ )  # a run of ? or * characters
|
    \\ (.)     # backslash escape
|
    (\W)       # any other non-word character
}{
    defined $1
        ? ".{" . ($1 =~ tr,?,,) . (index($1, "*") >= 0 ? "," : "") . "}"
        : quotemeta $+
}xeg;
    '
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
