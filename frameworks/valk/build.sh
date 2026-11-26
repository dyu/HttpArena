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

cd $SCRIPT_DIR

mkdir -p target vendor

dl_and_extract() {
  TAR_GZ="target/$1-$2.tar.gz"
  OUT_DIR="vendor/github-zikue-$1/$2"
  [ -e "$TAR_GZ" ] || curl -L -o $TAR_GZ "https://github.com/zikue/$1/archive/refs/tags/$2.tar.gz"
  [ -e $OUT_DIR ] || { mkdir -p $OUT_DIR; tar -xvzf $TAR_GZ -C $OUT_DIR --strip-components=1; }
  if [ -n "$3" ]; then
    mkdir -p $OUT_DIR/vendor && cd $OUT_DIR/vendor
    shift && shift
    for DEP in $@; do
      [ -e "github-zikue-$DEP" ] || ln -s ../../../github-zikue-$DEP
    done
    cd - > /dev/null
  fi
}

dl_and_extract valk-protobuf 0.2.1
dl_and_extract valk-grpc 0.1.3
dl_and_extract valk-sql 0.5.0
dl_and_extract valk-postgres 0.9.3 valk-sql

[ -e 'target/server' ] || valk build src -o target/server --release --static
