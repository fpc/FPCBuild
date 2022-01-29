#!/bin/bash

set -vex

VERSION=3.2.2
rm -rf build/fpc-"${VERSION}".intelarm64-macosx build/fpc-"${VERSION}".intel-macosx.cross.ios build/fpc-"${VERSION}".intel-macosx.cross.powerpc-macosx build/fpc-"${VERSION}".intel-macosx.cross.jvm
mkdir -p build/fpc-"${VERSION}".intelarm64-macosx build/fpc-"${VERSION}".intel-macosx.cross.ios build/fpc-"${VERSION}".intel-macosx.cross.powerpc-macosx build/fpc-"${VERSION}".intel-macosx.cross.jvm

cp x86/Users/Shared/Free\ Pascal\ Compiler/Documentation/Getting* What*.txt build/fpc-"${VERSION}".intelarm64-macosx
cp ios/Users/Shared/Free\ Pascal\ Compiler/Documentation/Getting* build/fpc-"${VERSION}".intel-macosx.cross.ios
cp ppc/Users/Shared/Free\ Pascal\ Compiler/Documentation/Getting* build/fpc-"${VERSION}".intel-macosx.cross.powerpc-macosx
cp jvm/Users/Shared/Free\ Pascal\ Compiler/Documentation/Getting* build/fpc-"${VERSION}".intel-macosx.cross.jvm

for file in *.pkgproj
do
  builddir=`basename -s .pkgproj $file|sed -e "s/fpc-/fpc-"${VERSION}"./"`
  (
  cp ../../../doc/whatsnew.txt "build/$builddir"/"What's New.txt"
  cp ReadMe.txt "build/$builddir"
  packagesbuild --build-folder "$PWD"/build/"$builddir" "$file"
  hdiutil create -ov -fs HFS+ -srcfolder "build/$builddir" -volname `basename "$builddir"` -format UDZO build/`basename "$builddir"`.dmg
  ) &
done

#packagebuild --build-folder build/fpc-"${VERSION}".intel-macosx fpc-intel-macosx.pkgproj 
#packagebuild --build-folder build/fpc-"${VERSION}".intel-macosx.cross.ios fpc-intel-macosx.cross.ios.pkgproj
#packagebuild --build-folder build/fpc-"${VERSION}".intel-macosx fpc-intel-macosx.pkgproj
#packagebuild --build-folder build/fpc-"${VERSION}".intel-macosx fpc-intel-macosx.pkgproj

#for dir in build/*/
#do
#  hdiutil create -fs HFS+ -srcfolder "$dir" -volname `basename "$dir"` -format UDZO `basename $dir`.dmg &
#done
wait
