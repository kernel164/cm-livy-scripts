#!/usr/bin/env bash

if [ "$1" = "" -o "$2" = "" ]; then
    echo "Usage: $0 <VERSION> <DISTRO>"
    echo
    echo "Example: $0 1.0 wheezy"
    exit 1
fi

set -ex

[[ -z $CM_EXT_BASE_DIR ]] && CM_EXT_BASE_DIR=.
[[ ! -d $CM_EXT_BASE_DIR/cm_ext ]] && CM_EXT_BASE_DIR=..
[[ ! -d $CM_EXT_BASE_DIR/cm_ext ]] && echo "set env CM_EXT_BASE_DIR!" && exit
[[ ! -f $CM_EXT_BASE_DIR/cm_ext/validator/target/validator.jar ]] && echo "missing $CM_EXT_BASE_DIR/cm_ext/validator/target/validator.jar" && exit

PARCEL_DIR=LIVY-$1
PARCEL=$PARCEL_DIR-$2.parcel

# Build Livy
if [ ! -d ./livy ]; then
  git clone https://github.com/apache/incubator-livy
  mv incubaror-livy livy
  cd ./livy
  git checkout -b tags/v0.4.0-incubating v0.4.0-incubating
else
  cd ./livy
fi

mvn clean package -DskipTests -Dspark.version=1.6.0-cdh5.11.2 -Dhadoop-version=2.6.0-cdh5.11.2 -pl '!core/scala-2.11,!repl/scala-2.11,!scala-api/scala-2.11,!integration-test/minicluster-dependencies/scala-2.11'

# Prepare parcel
cd ../

[ ! -d ./$PARCEL_DIR ] && rm -rf ./$PARCEL_DIR

mkdir -p ./$PARCEL_DIR/jars
mkdir -p ./$PARCEL_DIR/repl-jars
mkdir -p ./$PARCEL_DIR/rsc-jars

cp -r ./livy/bin ./$PARCEL_DIR/
cp -r ./livy/conf ./$PARCEL_DIR/
cp ./livy/server/target/jars/*.jar ./$PARCEL_DIR/jars/
cp ./livy/repl/target/jars/*.jar ./$PARCEL_DIR/repl-jars/
cp ./livy/rsc/target/jars/*.jar ./$PARCEL_DIR/rsc-jars/

cp -r parcel-src/meta $PARCEL_DIR/

sed -i -e "s/%VERSION%/$1/" ./$PARCEL_DIR/meta/*

# Validate and build parcel
java -jar $CM_EXT_BASE_DIR/cm_ext/validator/target/validator.jar -d ./$PARCEL_DIR

tar zcvhf ./$PARCEL $PARCEL_DIR

java -jar $CM_EXT_BASE_DIR/cm_ext/validator/target/validator.jar -f ./$PARCEL

# Remove parcel working directory
rm -rf ./$PARCEL_DIR

# Create parcel manifest
$CM_EXT_BASE_DIR/cm_ext/make_manifest/make_manifest.py .
