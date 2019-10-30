#!/bin/bash

CURRENT_DIR=$(realpath `dirname "$0"`)
BUILD_WITH_NO_CACHE_ARG=""
BUILD_PATH=$CURRENT_DIR
MAIN_BUILD_LOG=$CURRENT_DIR/build.log
TAG_SNAPSHOT=""
# So that we can pass the timestamp from the CI
TIMESTAMP=${TIMESTAMP:-`date +"%y%m%d%H%M%S"`}
GET_SNAPSHOT=""

getDistribution() {
  echo $1 | awk -F[=.] '{print $2}'
}

getBasePath() {
  echo `dirname $1`
}

getFilename() {
  echo `basename $1`
}

getTag() {
  TAG=`echo $1 | awk -F "Dockerfile.$2." '{print $2}'`
  if [[ -z $TAG ]]; then
    TAG="base"
  fi

  if [[ ! -z "$TAG_SNAPSHOT" ]]; then
    TAG="$TAG-$TAG_SNAPSHOT"
  fi
  echo "$TAG"
}

getImage() {
  echo "strongboxci/$1:$2"
}

build() {
  DOCKER_FILE=$1

  echo "=== Building $DOCKER_FILE"
  echo ""

  BASEPATH=`getBasePath "$DOCKER_FILE"`
  FILENAME=`getFilename "$DOCKER_FILE"`
  DISTRIBUTION=`getDistribution "$FILENAME"`
  TAG=`getTag "$FILENAME" "$DISTRIBUTION"`
  IMAGE=`getImage "$DISTRIBUTION" "$TAG"`

  echo "Distribution: $DISTRIBUTION"
  echo "Tag: $TAG"
  echo "Image: $IMAGE"
  echo ""

  (set -euxo pipefail; docker build -f "$DOCKER_FILE" -t "$IMAGE" $BUILD_WITH_NO_CACHE_ARG $CURRENT_DIR | tee "$DOCKER_FILE.build.log") || {
    echo "fail: $IMAGE" >> $MAIN_BUILD_LOG
    echo "Done" >> $MAIN_BUILD_LOG
    exit 1
  }

  echo ""

  echo "success: $IMAGE" >> $MAIN_BUILD_LOG
}

getSnapshot() {
  DOCKER_FILE=$1
  BASEPATH=`getBasePath "$DOCKER_FILE"`
  FILENAME=`getFilename "$DOCKER_FILE"`
  DISTRIBUTION=`getDistribution "$FILENAME"`
  TAG=`getTag "$FILENAME" "$DISTRIBUTION"`
  IMAGE=`getImage "$DISTRIBUTION" "$TAG"`
  echo $IMAGE
}

usage() {
  cat <<EOF

 $0 [options] path

  path:
    is not specified  - will build all Dockerfiles under ./images/
    is a directory    - will build all Dockerfiles in that path
    is a file         - will build that Dockerfile.

  Options:
    -h |--help          Prints this help message.
    -c |--clear         Clears all temp/log files from the repository.
    -nc|--no-cache      Adds --no-cache to the docker build command
    -s |--snapshot      Tag the images as snapshots (i.e. strongboxci/alpine:base-TIMESTAMP)
    -gs|--get-snapshot  Prints the snapshot version (i.e. TIMESTAMP || PR-123-TIMESTAMP || BRANCH-TIMESTAMP; needed for CI)

EOF
    exit 0
}

clearLogs() {
    (set -ex; find . -type f -name "*.log" -exec rm -rfv {} \;)
    exit 0
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -c|--clear)
            clearLogs
            exit 0
        ;;
        -nc|--no-cache)
            BUILD_WITH_NO_CACHE_ARG=" --no-cache "
            shift 1
        ;;
        -s|--snapshot)
            # Jenkins PR/Branch env
            if [[ ! -z "$CHANGE_ID" ]]; then
              TAG_SNAPSHOT="PR-$CHANGE_ID-$TIMESTAMP"
            elif [[ ! -z "$BRANCH_NAME" ]]; then
              TAG_SNAPSHOT="$BRANCH_NAME-$TIMESTAMP"
            else
              TAG_SNAPSHOT="$TIMESTAMP"
            fi
            shift
          ;;
        -gs|--get-snapshot)
          GET_SNAPSHOT=true
          shift
        ;;
        -h|--help)
            usage
            exit 0
        ;;
        *)
            BUILD_PATH=$1
            shift
            break
        ;;
    esac
done

if [[ ! -z $BUILD_PATH ]]; then
  # Clear main build log before starting.
  if [[ -z "$GET_SNAPSHOT" ]]; then
    truncate -s 0 $MAIN_BUILD_LOG
  fi

  # build all Dockerfiles in a directory
  if [[ -d $BUILD_PATH ]]; then
    for dockerFile in $(find $BUILD_PATH -type f -name "*Dockerfile*" ! -name "*.log" ! -name "*.bkp*" | sort | xargs); do
      if [[ -z "$GET_SNAPSHOT" ]]; then
        build "$dockerFile"
      else
        getSnapshot "$dockerFile"
      fi
    done
    if [[ -z "$GET_SNAPSHOT" ]]; then
      echo "Done" >> $MAIN_BUILD_LOG
    fi
  # build a specific Dockerfile
  elif [[ -f $BUILD_PATH ]]; then
    if [[ -z "$GET_SNAPSHOT" ]]; then
      build "$BUILD_PATH"
      echo "Done" >> $MAIN_BUILD_LOG
    else
      getSnapshot "$BUILD_PATH"
    fi
  # what just happened?
  else
    echo "$1 is neither a file nor a directory. Exiting."
    exit 1
  fi
fi

[[ ! -z "$GET_SNAPSHOT" ]] || echo ""
