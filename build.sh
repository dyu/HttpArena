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

FIB_TARGETS='
frameworks/fib/target/server
frameworks/fib-tuned/target/server
'

GOOSE_TARGETS='
frameworks/plod/target/server
'

GRADLE_TARGETS='
frameworks/ktor/build/libs/ktor-httparena.jar
'

RS_TARGETS='
frameworks/cpeak/target/release/httparena-cpeak
frameworks/may-minihttp/target/release/httparena-may-minihttp
frameworks/ntex/target/release/httparena-ntex
frameworks/tako/target/release/httparena-tako
'

ZIG_TARGETS='
frameworks/dusty/zig-out/bin/dusty-arena
frameworks/dusty-tuned/zig-out/bin/dusty-arena
frameworks/netcode-http/zig-out/bin/netcode-http-arena
frameworks/nilo/zig-out/bin/nilo-arena
'

ZIG_17_TARGETS='
frameworks/anole/zig-out/bin/anole-arena
'

ZIG_16_TARGETS='
frameworks/uwebzockets/zig-out/bin/uwebzockets
'

build_fib() {
  cd "$1"
  mkdir -p target
  CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o target/server .
  cd - > /dev/null
}

build_goose() {
  SRC_NAME=`basename $1`
  cd `dirname $(dirname $1)`
  shift
  mkdir -p target
  goose build $SRC_NAME.goose $@ --cc "$(which zcc)" -o target/$SRC_NAME --standalone
  cd - > /dev/null
}

build_gradle() {
  cd `dirname $1`
  if [ -e '.vfox/sdks/gradle/bin/gradle' ]; then
    GRADLE_BIN='.vfox/sdks/gradle/bin/gradle'
  else
    GRADLE_BIN='gradle'
  fi
  if [ -z "$2" ]; then
    JAVA_HOME=/usr/local/lib/jvm/jdk-25 $GRADLE_BIN build -x test
  else
    shift
    JAVA_HOME=/usr/local/lib/jvm/jdk-25 $GRADLE_BIN $@
  fi
  cd - > /dev/null
}

build_rs() {
  cd `dirname $1`
  cargo build --release
  cd - > /dev/null
}

build_zig() {
  ZIG_BIN="${2:-"zig18"}"
  cd `dirname $1`
  $ZIG_BIN build --release=fast
  cd - > /dev/null
}

for REL_PATH in $FIB_TARGETS; do
  if [ "$FORCE" = '1' ] || [ ! -e "$REL_PATH" ]; then
    build_fib `dirname $(dirname $REL_PATH)`
  fi
  du -shL $REL_PATH
done

for REL_PATH in $GOOSE_TARGETS; do
  if [ "$FORCE" = '1' ] || [ ! -e "$REL_PATH" ]; then
    build_goose $REL_PATH
  fi
  du -shL $REL_PATH
done

for REL_PATH in $GRADLE_TARGETS; do
  if [ "$FORCE" = '1' ] || [ ! -e "$REL_PATH" ]; then
    build_gradle `dirname $(dirname $REL_PATH)` buildFatJar --no-daemon
  fi
  du -shL $REL_PATH
done

for REL_PATH in $RS_TARGETS; do
  if [ "$FORCE" = '1' ] || [ ! -e "$REL_PATH" ]; then
    build_rs `dirname $(dirname $REL_PATH)`
  fi
  du -shL $REL_PATH
done

for REL_PATH in $ZIG_TARGETS; do
  if [ "$FORCE" = '1' ] || [ ! -e "$REL_PATH" ]; then
    build_zig `dirname $(dirname $REL_PATH)`
  fi
  du -shL $REL_PATH
done

for REL_PATH in $ZIG_17_TARGETS; do
  if [ "$FORCE" = '1' ] || [ ! -e "$REL_PATH" ]; then
    build_zig `dirname $(dirname $REL_PATH)` zig17
  fi
  du -shL $REL_PATH
done

for REL_PATH in $ZIG_16_TARGETS; do
  if [ "$FORCE" = '1' ] || [ ! -e "$REL_PATH" ]; then
    build_zig `dirname $(dirname $REL_PATH)` zig16
  fi
  du -shL $REL_PATH
done

AEGON_JAVA_JAR='frameworks/aegon-java/target/aegon-java-httparena.jar'
[ -e $AEGON_JAVA_JAR ] || ./frameworks/aegon-java/build.sh
du -shL $AEGON_JAVA_JAR
