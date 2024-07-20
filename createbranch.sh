#!/bin/sh
set -e

if [ $# -lt 2 ]; then
  echo "Usage: $0 <branch/tag> <name>"
  echo
  echo "Example: $0 branch fixes_2_1"
  echo "         $0 tag release_2_0_4"
  echo
  exit 1
fi

# For testing output the git commands
if [ ."$3" = ."test" ]; then
  GIT="echo git"
else
  GIT=git
fi

# Decode git remote from current fpcbuild remote
FPCBUILDURL=`git remote get-url origin | grep fpc/build.git || true`
if [ -z "$FPCBUILDURL" ]; then
   echo "This is not an fpcbuild checkout"
   exit 1
fi

echo Using remote url $FPCBUILDURL

echo Updating everything
$GIT submodule update --init --recursive
$GIT pull --recurse-submodule
$GIT submodule update --init --recursive

if [ ."$1" = ."tag" ]; then
  echo Tagging $2
  $GIT tag -a $2 -m "  Tagging $2"
  $GIT submodule foreach git tag -a $2 -m "  Tagging $2"
  echo Pushing still disabled, check the script $0 for \#!!!
  #!!! $GIT submodule foreach git push origin $2
  #!!! $GIT push origin $2
else
  if [ ."$1" = ."branch" ]; then
    $GIT checkout -b $2
    cd fpcsrc
    $GIT checkout -b $2
    cd ../fpcdocs
    $GIT checkout -b $2
    cd ..
    $GIT submodule foreach git push origin $2
    $GIT push origin $2
  else
    echo Unknown operation $1
    exit 1
  fi
fi
