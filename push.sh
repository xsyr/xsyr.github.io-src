#!/bin/bash

CUR_DIR=$(pwd)

SRC="${BASH_SOURCE[0]}"
SRC_DIR=$(dirname $SRC)



cd $SRC_DIR

git commit -am 'update'
git remote set-url origin git+ssh://git@github.com/xsyr/xsyr.github.io-src.git
git push

cd $CUR_DIR


