#!/bin/sh
# Fill kg/vendor/eco-compiler with the compiler sources at the commit in
# kg/vendor/COMMIT, read from the eco-compiler repository given.
# Usage: scripts/vendor-compiler.sh <eco-compiler-path>
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
commit=$(cat "$here/vendor/COMMIT")
dest="$here/vendor/eco-compiler"
rm -rf "$dest" && mkdir -p "$dest"
git -C "$1" archive "$commit" compiler/src compiler/src-xhr compiler/elm.json | tar -x -C "$dest"
