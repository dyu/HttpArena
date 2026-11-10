#!/bin/sh

#set -e

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

AEGON_REPO='https://github.com/UdayKhare09/Aegon.git'
AEGON_DIR='target/Aegon'

GIT_CLONE_BRANCH='git clone --recurse-submodules --shallow-submodules --single-branch -b'

export JAVA_HOME=/usr/local/lib/jvm/jdk-25

mkdir -p target

build_aegon() {
  [ -e "$AEGON_DIR" ] || { cd target; $GIT_CLONE_BRANCH main $AEGON_REPO; cd -> /dev/null; }
  cd $AEGON_DIR
  cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DAEGON_BUILD_TESTS=OFF \
    -DAEGON_BUILD_SAMPLES=OFF \
    -DAEGON_BUILD_BENCHMARKS=OFF \
    -DAEGON_BUILD_C_ABI=ON \
    -DAEGON_ENABLE_NATIVE_TUNING=ON \
    -DCMAKE_INSTALL_PREFIX=$PWD/install && \
  cmake --build build -j4 && \
  cmake --install  && \
  mvn -f bindings/java install -DskipTests
  cd - > /dev/null
}

[ -e target/Aegon/build ] || build_aegon
mvn package
