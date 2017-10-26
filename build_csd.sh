#!/usr/bin/env bash

if [ "$1" = "" ]; then
    echo "Usage: $0 <VERSION>"
    echo
    echo "Example: $0 1.0"
    exit 1
fi

set -ex

JARNAME=LIVY-$1.jar

[[ -z $CM_EXT_BASE_DIR ]] && CM_EXT_BASE_DIR=.
[[ ! -d $CM_EXT_BASE_DIR/cm_ext ]] && CM_EXT_BASE_DIR=..
[[ ! -d $CM_EXT_BASE_DIR/cm_ext ]] && echo "set env CM_EXT_BASE_DIR!" && exit

[[ ! -f $CM_EXT_BASE_DIR/cm_ext/validator/target/validator.jar ]] && echo "missing $CM_EXT_BASE_DIR/cm_ext/validator/target/validator.jar" && exit

# validate service description
java -jar $CM_EXT_BASE_DIR/cm_ext/validator/target/validator.jar -s ./csd-src/descriptor/service.sdl

jar -cvf ./$JARNAME -C ./csd-src .
echo "Created $JARNAME"
