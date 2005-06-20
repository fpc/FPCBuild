#!/bin/sh
#
# Shell script to make a FPC .tar package for QNX systems
# Copyright 1996-2002 Michael Van Canneyt and Peter Vreman
#

# Version
VERSION=1.0.8
RELEASE=i386

unset FPCDIR

# Goto the toplevel if necessary
[ -d install ] || cd ..

#make sunoszip
#make sourcezip
#make docsrc
#make docs
#make demozip

SOURCES=`/bin/ls *src.tar.gz`
FILES=`/bin/ls *qnx.tar.gz *exm.tar.gz`
RELFILES="binary.tar sources.tar demo.tar.gz fpcdoc.tar.gz install.sh"

echo Creating binary.tar
tar cf binary.tar $FILES
echo Creating sources.tar
tar cf sources.tar $SOURCES
echo Copying install.sh
cp install/qnx/install.sh .
chmod 755 install.sh

echo Creating fpc-$VERSION-$RELEASE.tar
tar cf fpc-$VERSION-$RELEASE.tar $RELFILES
