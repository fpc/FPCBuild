#!/bin/sh -e

# called by uscan with '--upstream-version' <version> <file>
TAR=$3
DIR=fpcbuild-$2

# clean up the upstream tarball
tar -x -z -f $TAR
tar -c -z -f $TAR --exclude '*.dll' --exclude '*.exe' --exclude '*.log' --exclude '*.o' $DIR
rm -rf $DIR

# move to directory 'tarballs'
if [ -r .svn/deb-layout ]; then
  . .svn/deb-layout
  mv $TAR $origDir
  echo "moved $TAR to $origDir"
fi
