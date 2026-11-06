#!/bin/sh

set -eo pipefail

CURRENT_DIR=$PWD
# locate
if [ -z "$BASH_SOURCE" ]; then
    SCRIPT_DIR=`dirname "$(readlink -f $0)"`
elif [ -e '/bin/zsh' ]; then
    F=`/bin/zsh -c "print -lr -- $BASH_SOURCE(:A)"`
    SCRIPT_DIR=`dirname $F`
elif [ -e '/usr/bin/realpath' ]; then
    F=`/usr/bin/realpath $BASH_SOURCE`
    SCRIPT_DIR=`dirname $F`
else
    F=$BASH_SOURCE
    while [ -h "$F" ]; do F="$(readlink $F)"; done
    SCRIPT_DIR=`dirname $F`
fi
# change pwd
cd $SCRIPT_DIR

RS_TARGETS='
frameworks/cpeak/target/release/httparena-cpeak
frameworks/may-minihttp/target/release/httparena-may-minihttp
frameworks/ntex/target/release/httparena-ntex
frameworks/tako/target/release/httparena-tako
'

DUSTY_TARGETS='
frameworks/dusty/zig-out/bin/dusty-arena
frameworks/dusty-tuned/zig-out/bin/dusty-arena
'

build_rs() {
  cd `dirname $1`
  cargo build --release
  cd - > /dev/null
}

build_dusty() {
  cd `dirname $1`
  zig18 build --release=fast
  cd - > /dev/null
}

for REL_PATH in $RS_TARGETS; do
  if [ "$FORCE" = '1' ] || [ ! -e "$REL_PATH" ]; then
    build_rs `dirname $(dirname $REL_PATH)`
  fi
  du -shL $REL_PATH
done

for REL_PATH in $DUSTY_TARGETS; do
  if [ "$FORCE" = '1' ] || [ ! -e "$REL_PATH" ]; then
    build_dusty `dirname $(dirname $REL_PATH)`
  fi
  du -shL $REL_PATH
done
