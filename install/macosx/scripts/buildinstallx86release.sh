#!/bin/bash

# enable to debug when things go wrong, run script as $0 para1 para2 >tt.log 2>tt2.log
#set -vx

# This scripts builds i386/x86-64 "fat" binaries of i386/x86-64 compilers, and also of ppc/ppc64 and
# jvm cross-compilers
# The results are placed in subdirectories of the destination directory
#
# Usage: buildinstallx86release.sh /path/to/previous/fpc/release/ppcx64 /path/to/destination/path

####################################
# Configuration
###################################

# defaults for (old) SDK locations
SDKi386=${SDKi386-/Volumes/Data/dev/osxsdk/MacOSX10.4u.sdk}
SDKx64=${SDKx64-/Volumes/Data/dev/osxsdk/MacOSX10.5.sdk}
SDKppc=${SDKppc-$SDKi386}
SDKppc64=${SDKppc64-$SDKppc}
BINUTILSDIR=${BINUTILSIDR-/Volumes/Data/dev/osxsdk/Xcode502toolchain/usr/bin}
BINUTILSDIRppc=${BINUTILSDIRppc-/Volumes/Data/dev/osxsdk/oldcctools/usr/bin}
if [ x${NCPU} = x ]; then
  NCPU=`sysctl -n machdep.cpu.core_count`
fi

usage()
{
  echo Usage: $0 '"startppcbindir" "installdir"'
  echo FPCBUILD environment variable must point to top level fpcbuild directory
  echo
  echo Example: $0 /usr/local/lib/fpc/3.0.2 /tmp/x86release
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

InstallDirX86="${InstallBaseDir}/x86/usr/local"
mkdir -p "$InstallDirX86"
InstallDirPPC="${InstallBaseDir}/ppc/usr/local"
mkdir -p "$InstallDirPPC"
InstallDirJVM="${InstallBaseDir}/jvm/usr/local"
mkdir -p "$InstallDirJVM"

######################################################
# build native i386/x86-64 compiler binaries and units
######################################################


# need use an old Xcode to support linking against on old SDK
BASEOPT="-ap -FD${BINUTILSDIR}"


# build the native x86-64 binaries and units
cd "$FPCBUILD"/fpcsrc
make FPC="$1/ppcx64" OPT="$BASEOPT" distclean -j $NCPU
make FPC="$1/ppcx64" OPT="$BASEOPT -WM10.5 -XR${SDKx64}" CPU_SOURCE=x86_64 all -j $NCPU FPMAKEOPT="-T $NCPU --target=x86_64-darwin"
make FPC=`pwd`/compiler/ppcx64 OPT="$BASEOPT -WM10.5 -XR${SDKx64}" INSTALL_PREFIX="$InstallDirX86" install
VERSION=`./compiler/ppcx64 -iV`
InstalledCompilerDir="$InstallDirX86"/lib/fpc/$VERSION

# Build x86-64 -> i386 cross-compiler
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir"/ppcx64 OPT="$BASEOPT -WM10.5 -XR${SDKx64}" CROSSOPT="-WM10.4 -XR${SDKi386}" CPU_TARGET=i386 -j $NCPU FPMAKEOPT="-T $NCPU" all
make FPC="$InstalledCompilerDir"/ppcx64 OPT="$BASEOPT -WM10.5 -XR${SDKx64}" CROSSOPT="-WM10.4 -XR${SDKi386}" CPU_TARGET=i386 INSTALL_PREFIX="$InstallDirX86" CROSSINSTALL=1 install
cd "$InstallDirX86"/bin
mv ../lib/fpc/$VERSION/ppcross386 ../lib/fpc/$VERSION/ppc386

# Build native i386 compiler and utilities
TMPINSTALLDIR=`mktemp -d -t fpcinst.XXXXXXX`
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir/ppc386" OPT="$BASEOPT" distclean -j $NCPU OVERRIDEVERSIONCHECK=1
make FPC="$InstalledCompilerDir/ppc386" OPT="$BASEOPT -WM10.4 -XR${SDKi386}" CPU_SOURCE=i386 -j $NCPU FPMAKEOPT="-T $NCPU --target=i386-darwin" OVERRIDEVERSIONCHECK=1 all
make FPC=`pwd`/compiler/ppc386 OPT="$BASEOPT -WM10.4 -XR${SDKi386}" CPU_SOURCE=i386 INSTALL_PREFIX="$TMPINSTALLDIR" install

# Build i386 -> x86-64 cross-compiler
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir/ppc386" OPT="$BASEOPT -WM10.4 -XR${SDKi386}" CROSSOPT="-WM10.5 -XR${SDKx64}" CPU_SOURCE=i386 CPU_TARGET=x86_64 -j $NCPU FPMAKEOPT="-T $CNPU --target=x86_64-darwin" all
make FPC="$InstalledCompilerDir/ppc386" OPT="$BASEOPT -WM10.4 -XR${SDKi386}" CROSSOPT="-WM10.5 -XR${SDKx64}" CPU_SOURCE=i386 CPU_TARGET=x86_64 INSTALL_PREFIX="$TMPINSTALLDIR" CROSSINSTALL=1 install
mv "$TMPINSTALLDIR"/lib/fpc/$VERSION/ppcrossx64 "$TMPINSTALLDIR"/lib/fpc/$VERSION/ppcx64

# Create fat/universal binaries
makefatbinary "$TMPINSTALLDIR"/lib/fpc/$VERSION/ppc386 "$InstalledCompilerDir"/ppc386
makefatbinary "$TMPINSTALLDIR"/lib/fpc/$VERSION/ppcx64 "$InstalledCompilerDir"/ppcx64
for file in "$TMPINSTALLDIR"/bin/*; do
  if [ -x "$file" ]; then
    makefatbinary "$file" "$InstallDirX86"/bin/`basename "$file"`
  fi
done

# remove temp native files
rm -rf "$TMPINSTALLDIR"

# create compiler binary symbolic links
cd "$InstallDirX86"/bin
ln -sf ../lib/fpc/$VERSION/ppc386
ln -sf ../lib/fpc/$VERSION/ppcx64

# install manual pages
cd "$FPCBUILD"/install/man
make FPC="$InstalledCompilerDir"/ppc386  INSTALL_PREFIX="$InstallDirX86/share" installman NOIDE=1

# install demos
cd "$FPCBUILD"/demo
make FPC="$InstalledCompilerDir"/ppc386 INSTALL_PREFIX="$InstallDirX86" sourceinstall

# install licenses
cd "$FPCBUILD"/install/doc
mkdir -p "$InstallDirX86"/share/doc/fpc-$VERSION/license
cp jasminli.txt COPYING COPYING.v2 copying.fpc libffi.txt apache2.txt "$InstallDirX86"/share/doc/fpc-$VERSION/license

# properly strip all binaries
set +e
cd "$InstallDirX86"/bin
strip *
cd "$InstallDirX86"/lib/fpc/$VERSON/
strip *

# remove all copied .svn dirs
cd "$2"
find . -name '.svn' -print0 | xargs -0 rm -rf

cd "$startdir"

########################################################
# Build ppc and ppc64 cross-compilers
########################################################

BASECROSSOPT="-ap -FD${BINUTILSDIRppc}"


# x64 -> ppc
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir"/ppcx64 OPT="$BASEOPT" distclean -j $NCPU OVERRIDEVERSIONCHECK=1
make FPC="$InstalledCompilerDir"/ppcx64 OPT="$BASEOPT -WM10.5 -XR${SDKx64}" CROSSOPT="$BASECROSSOPT -WM10.4 -XR${SDKppc}" CPU_TARGET=powerpc -j $NCPU FPMAKEOPT="-T $NCPU" all
make FPC="$InstalledCompilerDir"/ppcx64 OPT="$BASEOPT -WM10.5 -XR${SDKx64}" CROSSOPT="$BASECROSSOPT -WM10.4 -XR${SDKppc}" CPU_TARGET=powerpc INSTALL_PREFIX="$InstallDirPPC" CROSSINSTALL=1 install
cd "$InstallDirPPC"/lib/fpc/$VERSION
mv ppcrossppc ppcppc

# x64 -> ppc64
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir"/ppcx64 OPT="$BASEOPT -WM10.5 -XR${SDKx64}" CROSSOPT="$BASECROSSOPT -WM10.4 -XR${SDKppc64}" CPU_TARGET=powerpc64 -j $NCPU FPMAKEOPT="-T $NCPU" all
make FPC="$InstalledCompilerDir"/ppcx64 OPT="$BASEOPT -WM10.5 -XR${SDKx64}" CROSSOPT="$BASECROSSOPT -WM10.4 -XR${SDKppc64}" CPU_TARGET=powerpc64 INSTALL_PREFIX="$InstallDirPPC" CROSSINSTALL=1 install
cd "$InstallDirPPC"/lib/fpc/$VERSION
mv ppcrossppc64 ppcppc64


# i386 -> ppc and ppc64
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir"/ppc386 OPT="$BASEOPT" distclean -j $NCPU OVERRIDEVERSIONCHECK=1
cd compiler
make FPC="$InstalledCompilerDir/ppc386" OPT="$BASEOPT -WM10.4 -XR${SDKi386}" CPU_SOURCE=i386 -j $NCPU FPMAKEOPT="-T $CNPU --target=powerpc-darwin" cycle ppuclean powerpc powerpc64

makefatbinary ppcppc "$InstallDirPPC"/lib/fpc/$VERSION/ppcppc
makefatbinary ppcppc64 "$InstallDirPPC"/lib/fpc/$VERSION/ppcppc64

# create compiler binary symbolic links
cd "$InstallDirPPC"/bin
ln -sf ../lib/fpc/$VERSION/ppcppc
ln -sf ../lib/fpc/$VERSION/ppcppc64
strip ../lib/fpc/$VERSION/ppcppc
strip ../lib/fpc/$VERSION/ppcppc64

##########################
# Build jvm cross-compiler
##########################

# x64 -> jvm

BASECROSSOPT="-FD$FPCBUILD/install/jvm"

# We cannot build the cross-compiler for the right OS version/SDK, because that
# -WM parameter would also be passed to the JVM cross-compiler and it would give
# an error about it (since it cannot target OS X versions). So we first build
# everything for the host OS X version, and then compile the compiler separately
# for the OS X SDK we want to target.

BASECROSSOPT="-FD$FPCBUILD/install/jvm -gl"

# build x64 -> jvm
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir"/ppcx64 OPT="-ap" distclean -j $NCPU OVERRIDEVERSIONCHECK=1
make FPC="$InstalledCompilerDir"/ppcx64 OPT="-ap" CPU_TARGET=jvm OS_TARGET=java all -j $NCPU FPMAKEOPT="-T 4"
make FPC="$InstalledCompilerDir"/ppcx64 OPT="-ap" CROSSOPT="$BASECROSSOPT" CPU_TARGET=jvm OS_TARGET=java -j $NCPU FPMAKEOPT="-T $NCPU" all
make FPC="$InstalledCompilerDir"/ppcx64 OPT="-ap" CROSSOPT="$BASECROSSOPT" CPU_TARGET=jvm OS_TARGET=java  INSTALL_PREFIX="$InstallDirJVM" CROSSINSTALL=1 install

# build x64 -> android
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir"/ppcx64 OPT="-ap" distclean -j $NCPU OVERRIDEVERSIONCHECK=1
make FPC="$InstalledCompilerDir"/ppcx64 OPT="-ap" CPU_TARGET=jvm OS_TARGET=android all -j $NCPU FPMAKEOPT="-T 4"
make FPC="$InstalledCompilerDir"/ppcx64 OPT="-ap" CROSSOPT="$BASECROSSOPT" CPU_TARGET=jvm OS_TARGET=android -j $NCPU FPMAKEOPT="-T $NCPU" all
make FPC="$InstalledCompilerDir"/ppcx64 OPT="-ap" CROSSOPT="$BASECROSSOPT" CPU_TARGET=jvm OS_TARGET=android INSTALL_PREFIX="$InstallDirJVM" CROSSINSTALL=1 install

# build x64->jvm cross-compiler
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir"/ppcx64 OPT="-ap" distclean -j $NCPU OVERRIDEVERSIONCHECK=1
cd compiler
make FPC="$InstalledCompilerDir/ppcx64" OPT="$BASEOPT -WM10.5 -XR${SDKx64}" -j $NCPU FPMAKEOPT="-T $CNPU" cycle ppuclean jvm
mv ppcjvm "$InstallDirJVM"/lib/fpc/$VERSION/

# build i386->jvm cross-compiler
cd "$FPCBUILD"/fpcsrc
make FPC="$InstalledCompilerDir"/ppc386 OPT="$BASEOPT" distclean -j $NCPU OVERRIDEVERSIONCHECK=1
cd compiler
make FPC="$InstalledCompilerDir/ppc386" OPT="$BASEOPT -WM10.4 -XR${SDKi386}" CPU_SOURCE=i386 -j $NCPU FPMAKEOPT="-T $CNPU" cycle ppuclean jvm

makefatbinary ppcjvm "$InstallDirJVM"/lib/fpc/$VERSION/ppcjvm
cd "$InstallDirJVM"/bin
ln -sf ../lib/fpc/$VERSION/ppcjvm
strip ../lib/fpc/$VERSION/ppcjvm
cp $FPCBUILD/install/jvm/javapp.jar $FPCBUILD/install/jvm/jasmin.jar .

cd "$startdir"
