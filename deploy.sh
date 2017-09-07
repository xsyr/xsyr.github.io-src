#!/bin/bash

CUR_DIR=$(pwd)

SRC="${BASH_SOURCE[0]}"
SRC_DIR=$(dirname $SRC)

GIT_DIR=$SRC_DIR/xsyr.github.io
SITE_DIR=$SRC_DIR/_site


if [ ! -d $SITE_DIR ]; then
    git clone git@github.com:xsyr/xsyr.github.io.git
    if [ $? -ne 0 ]; then
        echo "clone from git failed."
        exit 1
    fi

    mv $GIT_DIR $SITE_DIR
fi

jekyll clean
jekyll b

cd $SITE_DIR

pwd

git remote set-url origin git+ssh://git@github.com/xsyr.github.io.git
git commit -am 'update'
git push

cd $CUR_DIR


