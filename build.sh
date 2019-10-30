#!/bin/bash

CURRENT_DIR=$(realpath $(dirname "$0"))

build() {
  DOCKER_FILE=$1

  echo "=== Building $DOCKER_FILE"

  BASEPATH=`dirname $DOCKER_FILE`
  FILENAME=`basename $DOCKER_FILE`
  DISTRIBUTION=`echo $FILENAME | awk -F[=.] '{print $2}'`
  TAG=`echo $FILENAME | awk -F "Dockerfile.$DISTRIBUTION." '{print $2}'`
  if [[ -z $TAG ]]; then
    TAG="base"
  fi
  IMAGE="strongboxci/$DISTRIBUTION:$TAG"

  echo "Distribution: $DISTRIBUTION"
  echo "Tag: $TAG"
  echo "Image: $IMAGE"

  (set -euxo pipefail; docker build -f "$DOCKER_FILE" -t "$IMAGE" $CURRENT_DIR | tee "$DOCKER_FILE.build.log") || exit 1;

}


BUILD=$1

if [[ ! -z $BUILD ]]; then
  # build all Dockerfiles in a directory
  echo $BUILD

  if [[ -d $BUILD ]]; then
    for dockerFile in $(find $BUILD -type f -name "*Dockerfile*" ! -name "*.log" ! -name "*.bkp" | sort); do
      #if [[ $dockerFile == *"jdk11"* ]]; then
      #  continue
      #fi
      build "$dockerFile"
    done
  # build a specific Dockerfile
  elif [[ -f $BUILD ]]; then
    build "$BUILD"
  # What?
  else
    echo "$1 is neither a file nor a directory. Exiting."
    exit 1
  fi
fi

echo ""
