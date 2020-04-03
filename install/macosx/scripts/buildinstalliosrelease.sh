#!/bin/bash

# enable to debug when things go wrong, run script as $0 para1 para2 >tt.log 2>tt2.log
# set -vx

# This scripts builds x86-64 cross-compilers to ARM/AArch64 and for the iPhoneSim platform.
# It is separate from the script that builds all other x86 (cross-)compilers, because for
# FPC 3.0.x the 64 bit iOS/iPhoneSim support was in a separate branch

# If/when they get built from the same version as the other platforms again, make sure
# to remove the creation of the custom i386/x86-64 compiler binaries again below

####################################
# Configuration
###################################

SDKx64=${SDKx64-/Volumes/Data/dev/osxsdk/MacOSX10.5.sdk}
# separate for 32 and 64 bit since latest SDKs no longer include 32 bit support
SDKARM=${SDKARM-/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk}
SDKAARCH64=${SDKAARCH64-/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk}
SDKIPHONESIM32=${SDKIPHONESIM32-/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk}
SDKIPHONESIM64=${SDKIPHONESIM64-/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk}
# for compiling the final compiler binaries against an old SDK
BINUTILSDIR=${BINUTILSIDR-/Volumes/imac/Applications/Xcode5.0.2.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/}
# Create custom i386/x86-64 compiler binaries to target the iPhoneSim platform
# (define to 0 to disable) (also fpc, fpcmake, fpcres)
CREATECUSTOMX86COMPILERBINARIES=${CREATECUSTOMX86COMPILERBINARIES-0}
if [ x${NCPU} = x ]; then
  NCPU=`sysctl -n machdep.cpu.core_count`
fi

usage()
{
  echo Usage: $0 '"startppcbindir" "installdir"'
  echo FPCBUILD environment variable must point to top level fpcbuild directory
  echo "startppcbindir" must be a compiler binary dir of the same version as the
  echo one you are building for iOS
  echo
  echo Example: $0 /usr/local/lib/fpc/3.0.4 /tmp/ios304release
  echo "/usr/local" will automatically be added to "installdir"
  exit 1
}

dir_resolve()
{
cd "$1" 2>/dev/null || return $?  # cd to desired directory; if fail, quell any error messages but return exit status
echo "`pwd -P`" # output full, link-resolved path
}

BASEDIR=`dirname $0`
BASEDIR=`dir_resolve "$BASEDIR"`
source "$BASEDIR"/helpers.sh

InstallDirIOS="${InstallBaseDir}/ios/usr/local"
BASEOPT="-ap"

# Build ARM cross-compiler and units
cd "$FPCBUILD"/fpcsrc
make FPC="$1/ppcx64" OPT="$BASEOPT" distclean -j $NCPU
make FPC="$1/ppcx64" OPT="$BASEOPT" CROSSOPT="-WP6.0 -CpARMv7 -Cfvfpv3 -XR${SDKARM}" CPU_TARGET=arm all -j $NCPU CPU_SOURCE=x86_64 FPMAKEOPT="-T $NCPU --target=arm-darwin"
VERSION=`./compiler/ppcrossarm -iV`
make FPC="$1/ppcx64" OPT="$BASEOPT" CROSSOPT="-WP6.0 -CpARMv7 -Cfvfpv3 -XR${SDKARM}" INSTALL_PREFIX="$InstallDirIOS" CPU_TARGET=arm CROSSINSTALL=1 install
cd "$InstallDirIOS"/bin
mv ../lib/fpc/$VERSION/ppcrossarm ../lib/fpc/$VERSION/ppcarm
ln -sf ../lib/fpc/$VERSION/ppcarm

# Build AARCH64 cross-compiler and units
cd "$FPCBUILD"/fpcsrc
make FPC="$1/ppcx64" OPT="$BASEOPT" distclean -j $NCPU
make FPC="$1/ppcx64" OPT="$BASEOPT" CROSSOPT="-WP7.0 -XR${SDKAARCH64}" CPU_TARGET=aarch64 all -j $NCPU CPU_SOURCE=x86_64 FPMAKEOPT="-T $NCPU --target=aarch64-darwin"
VERSION=`./compiler/ppcrossa64 -iV`
make FPC="$1/ppcx64" OPT="$BASEOPT" CROSSOPT="-WP7.0 -XR${SDKAARCH64}" INSTALL_PREFIX="$InstallDirIOS" CPU_TARGET=aarch64 CROSSINSTALL=1 install
cd "$InstallDirIOS"/bin
mv ../lib/fpc/$VERSION/ppcrossa64 ../lib/fpc/$VERSION/ppca64
ln -sf ../lib/fpc/$VERSION/ppca64

# Build iphonsim 32 bit cross-compiler
cd "$FPCBUILD"/fpcsrc
make FPC="$1/ppcx64" OPT="$BASEOPT" CROSSOPT="-WP8.1 -XR${SDKIPHONESIM32}" CPU_TARGET=i386 OS_TARGET=iphonesim all -j $NCPU CPU_SOURCE=x86_64 FPMAKEOPT="-T $NCPU --target=i386-iphonesim"
make FPC="$1/ppcx64" OPT="$BASEOPT" CROSSOPT="-WP8.1 -XR${SDKIPHONESIM32}" INSTALL_PREFIX="$InstallDirIOS" CPU_TARGET=i386 OS_TARGET=iphonesim CROSSINSTALL=1 install
cd "$InstallDirIOS"/bin
if [ $CREATECUSTOMX86COMPILERBINARIES -eq 1 ]; then
  mv ../lib/fpc/$VERSION/ppcross386 ../lib/fpc/$VERSION/ppc386
  ln -sf ../lib/fpc/$VERSION/ppc386 ppc386-$VERSION
else
  rm ../lib/fpc/$VERSION/ppcross386
fi

# Build iphonesim 64 bit cross-compiler
cd "$FPCBUILD"/fpcsrc
make FPC="$1/ppcx64" OPT="$BASEOPT" CROSSOPT="-WP8.1 -XR${SDKIPHONESIM64}" CPU_TARGET=x86_64 OS_TARGET=iphonesim all -j $NCPU CPU_SOURCE=x86_64 FPMAKEOPT="-T $NCPU --target=x86_64-iphonesim"
make FPC="$1/ppcx64" OPT="$BASEOPT" CROSSOPT="-WP8.1 -XR${SDKIPHONESIM64}" INSTALL_PREFIX="$InstallDirIOS" CPU_TARGET=x86_64 OS_TARGET=iphonesim CROSSINSTALL=1 install
cd "$InstallDirIOS"/bin
if [ $CREATECUSTOMX86COMPILERBINARIES -eq 1 ]; then
  mv ../lib/fpc/$VERSION/ppcrossx64 ../lib/fpc/$VERSION/ppcx64
  ln -sf ../lib/fpc/$VERSION/ppcx64 ppcx64-$VERSION
else
  rm ../lib/fpc/$VERSION/ppcrossx64
fi

# build compilers against target macOS SDK
cd "$FPCBUILD"/fpcsrc
make FPC="$1"/ppcx64 OPT="$BASEOPT" distclean -j $NCPU
cd compiler
make FPC="$1/ppcx64" CPU_SOURCE=x86_64 OPT="$BASEOPT -WM10.5 -FD${BINUTILSDIR} -XR${SDKx64}" -j $NCPU FPMAKEOPT="-T $CNPU" cycle ppuclean i386 arm aarch64
if [ $CREATECUSTOMX86COMPILERBINARIES -eq 1 ]; then
  mv ppcx64 ppc386 "$InstallDirIOS"/lib/fpc/$VERSION
fi
mv ppcarm ppca64 "$InstallDirIOS"/lib/fpc/$VERSION

if [ $CREATECUSTOMX86COMPILERBINARIES -eq 1 ]; then
  # build complete native version to get the fpc, fpcres and fpcmake binaries with AArch64 support
  cd "$FPCBUILD"/fpcsrc
  make FPC="$1/ppcx64" CPU_SOURCE=x86_64 OPT="$BASEOPT -FD${BINUTILSDIR} -WM10.5 -XR${SDKx64}" all -j $NCPU FPMAKEOPT="-T $NCPU --target=x86_64-darwin" OVERRIDEVERSIONCHECK=1
  mv compiler/utils/fpc "$InstallDirIOS"/bin
  mv utils/fpcres/bin/x86_64-darwin/fpcres "$InstallDirIOS"/bin
  mv utils/fpcm/bin/x86_64-darwin/fpcmake "$InstallDirIOS"/bin
fi

# properly strip all binaries
strip "$InstallDirIOS"/bin/*

cd "$startdir"
