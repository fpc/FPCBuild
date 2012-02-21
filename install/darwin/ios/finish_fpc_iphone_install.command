#!/bin/bash

# Script to compile and install FPC 2.6.0 for Mac OS X/ARM (iOS)
# (iPhone/iPod Touch/iPad)
# Copyright (c) 2009-2011 Jonas Maebe
# Licensed under the GPLv2 or later

STARTDIR=`pwd`
FULLSCRIPTNAME="$0"

#############################################################################
# Helper functions
#############################################################################

# error messages function
doerror() {
  cd "$FPCSOURCEDIR"
  chown -R root:admin . >/dev/null 2>&1
  chmod -R g+w . >/dev/null 2>&1
  rm -f "$FPCROSSARMBINARY"

  echo "An error occurred during" "$1"
  echo "When asking for help with this error, please provide the entire contents of"
  echo "this window (you can copy/paste it)"
}


# ask a user for a particular reply
# (from http://ubuntuforums.org/archive/index.php/t-436799.html)
function AskUser {
  local choices=
  local input=
  local match="FALSE"
  # Construct a nice list of possible choices
  for i in $@
  do
    choices="$choices / $i"
  done
  # Display list, removing heading garbage due to loop.
  echo -n "(${choices# / }) "
  
  read input
  
  i=0
  while [ x"$1" != "x" -a "$match" = "FALSE" ]
  do
    i=$(($i+1))
    if [ "$1" = "$input" ]
    then
      match="TRUE"
    fi
  
#    echo "[DEBUG] $i test: $1 = $input? $match"
  
    shift
  done
  
  # No match, fallback to default.
  if [ $match = "FALSE" ]
  then
    i=0
  fi
  
#  echo "[DEBUG] returning $i"
  
  return $i
}


failure() {
  if [ x"$FPCARMV7UNITSINSTALLDIR" -ne "x" ]; then
    rm -rf "$FPCARMV7UNITSINSTALLDIR"
  fi
  echo
  echo "You can restart this script by double-clicking it in the Finder at"
  echo "$FULLSCRIPTNAME"
  echo
  read
  exit 1
}

#############################################################################
# begin main script
#############################################################################



# get root
if [ $UID != 0 ] ; then
  echo
  echo
  echo "This script, which will finish the FPC for iOS 2.6.0 installation, has to run"
  echo "with root permission. Please enter your administrator password below if it is"
  echo "asked (it will not be asked if this script or the sudo program was run within"
  echo "the last 5 minutes)."
  echo
  echo "The script that will be executed is \"$0\""
  echo
  sudo "$0" $@
  exit $?
fi

# introduction
echo
echo
echo
echo "This script finishes the installation of FPC for the iPhone SDK 4.x/5.x (should"
echo "work with future versions). It has to be executed by an administrator user."
echo
echo "You can cancel/stop the execution of this script at any time by holding down"
echo "ctrl-c (if you want to copy/paste the output) or by closing this window."
echo
echo
echo "The script will now perform a few sanity checks and then start"
echo "compiling and installing all FPC components."
echo
echo "Press enter to continue"
read

# Obtain the installation directory of the SDK.
IPHONEINSTALLDIR=/Developer
IPHONESDKDIR=`ls -d "$IPHONEINSTALLDIR"/Platforms/iPhoneOS.platform/Developer/SDKs/*|sort|tail -1`
if [ ! -f "$IPHONESDKDIR/usr/include/arm/_structs.h" ]; then
  echo
  echo "To start, please drag the folder in which Xcode with iPhone SDK is installed"
  echo "on top of this window, or copy it in the Finder and paste it in this window."
  echo "This will fill in the full path to this folder. Then, press the return key to"
  echo "continue."
  echo
  echo -n "Enter iPhone SDK installation directory (e.g., /iPhoneSDK): "
  read IPHONEINSTALLDIR
  IPHONESDKDIR=`ls -d "$IPHONEINSTALLDIR"/Platforms/iPhoneOS.platform/Developer/SDKs/*|sort|tail -1`
  if [ ! -f "$IPHONESDKDIR/usr/include/arm/_structs.h" ]; then
    IPHONESDKDIR=not_found
  fi
fi


# some required/used file and directory names
IPHONEPLATFORMBASEDIR="$IPHONEINSTALLDIR"/"Platforms/iPhoneOS.platform/Developer"
SIMULATORPLATFORMBASEDIR="$IPHONEINSTALLDIR"/"Platforms/iPhoneSimulator.platform/Developer"
SIMULATORSDKDIR=`echo $IPHONESDKDIR | sed -e 's/iPhoneOS/iPhoneSimulator/g'`
INCLUDEDIR="$IPHONESDKDIR/usr/include"
STRUCTSHEADER="$INCLUDEDIR"/arm/_structs.h
FPCSOURCEDIR="/Developer/FreePascalCompiler/2.6.0/Source/"
FPCBOOTSTRAPBINARY="/usr/local/bin/ppc386"
PARALLELMAKE=`sysctl -n hw.availcpu`

# check whether we can find the file that we have to convert
if [ ! -f "$STRUCTSHEADER" ]; then
  echo "Unable to find the file \"$STRUCTSHEADER\""
  echo
  echo "Is \"$IPHONEINSTALLDIR\" the installation directory of the iPhone SDK 2.2.1 or later?"
  failure
fi

# check whether h2pas is installed (part of the regular FPC installation)
if [ ! -f /usr/local/bin/h2pas -o ! -x /usr/local/bin/h2pas ]; then
  echo "Unable to find the h2pas utility. It is part of the regular FPC for"
  echo "Mac OS X/Intel installation. Please install the FPC 2.6.0 before"
  echo "installing this add-on package."
  failure
fi

# ensure that the SDK isn't installed in a directory with a space in
# its name (unfortunately, "make" cannot deal with this)
if echo "$IPHONEINSTALLDIR" | grep ' ' >/dev/null 2>&1; then
  echo "The full path to your iPhone SDK contains a space character, and unfortunately"
  echo "some of the required tools cannot deal with this. Please rename the directory"
  echo "(and the hard drive partition containing it, if it's not your startup drive)"
  echo "so it no longer contains a space in its name."
  echo 
  echo "You can rename everything back after this script has finished running."
  echo
  echo "Path: \"$IPHONEINSTALLDIR\""
  failure
fi


# check whether we can find the installed FPC sources (check a random file)
if [ ! -f "$FPCSOURCEDIR"/compiler/arm/cgcpu.pas ]; then
  echo "Unable to find the installed FPC sources. They were expected in \"$FPCSOURCEDIR\""
  failure
fi

# check whether we can find the installed FPC bootstrap compiler
if [ ! -f "$FPCBOOTSTRAPBINARY" -o ! -x "$FPCBOOTSTRAPBINARY" ]; then
  echo "Unable to find the bootstrap compiler. It was expected at \"$FPCBOOTSTRAPBINARY\""
  failure
fi

# check whether the bootstrap compiler's version is 2.6.0
currentfpcversion=`$FPCBOOTSTRAPBINARY -iV|tr -d '.'`
if [ "$currentfpcversion" -lt 260 -o "$currentfpcversion" -gt 260 ]; then
  # look for fpc 2.6.0
  FPCBOOTSTRAPBINARY=/usr/local/lib/fpc/2.6.0/ppc386
  FPCBOOTSTRAPBINARY=`echo $FPCBOOTSTRAPBINARY|sed -e 's/ .*//'`
  if [ x"$FPCBOOTSTRAPBINARY" = x ]; then
    echo "Unable to find a valid FPC bootstrap compiler (need version 2.6.0)"
    failure
  fi
  if [ ! -x "$FPCBOOTSTRAPBINARY" ]; then
    echo "The bootstrap compiler at \"$FPCBOOTSTRAPBINARY\" is not executable. Please"
    echo "reinstall FPC 2.6.0 for Intel."
    failure
  fi
fi
echo "Using \"$FPCBOOTSTRAPBINARY\" as FPC bootstrap binary"

# create the Pascal version of the _structs.h header, the whole reason why we
# we have to go through all this trouble...
/usr/bin/gcc -I"$INCLUDEDIR" -E -D__need_mcontext_t -D__DARWIN_UNIX03 "$STRUCTSHEADER" | sed -e 's/__uint32_t/cuint32/g' -e 's/_STRUCT_ARM_EXCEPTION_STATE/__darwin_arm_exception_state/' -e 's/_STRUCT_ARM_THREAD_STATE/__darwin_arm_thread_state/' -e 's/_STRUCT_ARM_VFP_STATE/__darwin_arm_vfp_state/' -e 's/__darwin_mcontext/mcontext_t/' > "$FPCSOURCEDIR"/rtl/darwin/arm/sig_cpu.h
if [ $? != 0 ]; then
  echo "Unable to preprocess the _structs.h header file at \"$STRUCTSHEADER\" using \"/usr/bin/gcc\""
  failure
fi
/usr/local/bin/h2pas -i -o "$FPCSOURCEDIR"/rtl/darwin/arm/sig_cpu.inc "$FPCSOURCEDIR"/rtl/darwin/arm/sig_cpu.h
if [ $? != 0 ]; then
  echo "Unable to translate the preprocessed header file at \"$FPCSOURCEDIR/rtl/darwin/arm/sig_cpu.h\""
  echo "Make sure not to distribute this file in source form, because you would violate"
  echo "your iPhone SDK agreement!"
  failure
fi


# Safe temporary places for the generated compilers
FPCROSSARMBINARY=`mktemp -t ppcrossarm.XXXXXXXXXXXXXXXX`
if [ $? != 0 ]; then
  echo "Unable reserve a temporary location for the ARM cross compiler. You can try"
  echo "to restart your system to clean up the /tmp/ directory to solve this problem."
  failure
fi
chmod u+x "$FPCROSSARMBINARY"

# Temp location for ARMv7 units
FPCARMV7UNITSINSTALLDIR=`mktemp -d -t fpcarmv7.XXXXXXXXXXXX`
if [ $? != 0 ]; then
  echo "Unable reserve a temporary location for the ARMv7 units. You can try"
  echo "to restart your system to clean up the /tmp/ directory to solve this problem."
  failure
fi


####################################################
echo
echo
echo "Compiling the compiler and all units for ARMv6..."
echo

cd "$FPCSOURCEDIR"

make FPC="$FPCBOOTSTRAPBINARY" distclean -j 4
if [ $? != 0 ]; then
  doerror "cleaning the source directory for ARM"
  failure
fi
# these do not appear to be erased by distclean for some reason
rm -rf "packages/fcl-db/units" "compiler/ppcarm" "compiler/ppcrossarm"

make FPC="$FPCBOOTSTRAPBINARY" OPT="-ap" CPU_TARGET=arm CROSSOPT="-FD${IPHONEPLATFORMBASEDIR}/usr/bin  -XR${IPHONESDKDIR}/ -ap -Cparmv6 -Cfvfpv2" all -j "$PARALLELMAKE"

if [ $? != 0 ]; then
  doerror "building everything for ARM"
  failure
fi

# copy cross-comiler to a safe place (useful for later)
cat compiler/ppcrossarm >> "$FPCROSSARMBINARY"
if [ $? != 0 ]; then
  doerror "copying the ARM cross-compiler"
  failure
fi

echo
echo
echo "Installing the ARM cross-compiler and all units..."
echo

make FPC="$FPCROSSARMBINARY" OPT="-ap" CPU_TARGET=arm CROSSOPT="-FD${IPHONEPLATFORMBASEDIR}/usr/bin -XR${IPHONESDKDIR}/ -ap -Cparmv6 -Cfvfpv2" install CROSSINSTALL=1
if [ $? != 0 ]; then
  doerror "installing the ARM cross-compiler and all units"
  failure
fi

VERSION=`$FPCROSSARMBINARY -iV`

# rename compiler binary
cd /usr/local/lib/fpc/$VERSION
mv ppcrossarm ppcarm
if [ $? != 0 ]; then
  doerror "renaming the ARM cross-compiler"
  failure
fi

# add compiler symlink
cd /usr/local/bin
ln -sf ../lib/fpc/$VERSION/ppcarm ppcarm
if [ $? != 0 ]; then
  doerror "creating the ARM cross-compiler symlink"
  failure
fi

####################################################
echo
echo
echo "Compiling all units for ARMv7..."
echo

cd "$FPCSOURCEDIR"

make FPC="$FPCROSSARMBINARY" CPU_TARGET=arm  distclean -j 4
if [ $? != 0 ]; then
  doerror "cleaning the source directory for ARMv7"
  failure
fi
# these do not appear to be erased by distclean for some reason
rm -rf "packages/fcl-db/units" "compiler/ppcarm" "compiler/ppcrossarm"

cd rtl/darwin
make FPC="$FPCROSSARMBINARY" OPT="-ap" CPU_TARGET=arm CROSSOPT="-FD${IPHONEPLATFORMBASEDIR}/usr/bin  -XR${IPHONESDKDIR}/ -ap -Cparmv7 -Cfvfpv3" RELEASE=1 all -j "$PARALLELMAKE"

if [ $? != 0 ]; then
  doerror "building RTL for ARMv7"
  failure
fi
cd ../..

cd packages
make FPC="$FPCROSSARMBINARY" OPT="-ap" CPU_TARGET=arm CROSSOPT="-FD${IPHONEPLATFORMBASEDIR}/usr/bin  -XR${IPHONESDKDIR}/ -ap -Cparmv7 -Cfvfpv3" RELEASE=1 all -j "$PARALLELMAKE"

if [ $? != 0 ]; then
  doerror "building packages for ARMv7"
  failure
fi
cd ..


echo
echo
echo "Installing the ARMv7 units into temporary location..."
echo

# first install into temporary install directory in /tmp, then lipo everything
# into the previously generated ARMv6 object files

cd rtl/darwin
make FPC="$FPCROSSARMBINARY" OPT="-ap" CPU_TARGET=arm CROSSOPT="-FD${IPHONEPLATFORMBASEDIR}/usr/bin -XR${IPHONESDKDIR}/ -ap -Cparmv7 -Cfvfpv3" INSTALL_PREFIX="$FPCARMV7UNITSINSTALLDIR" RELEASE=1 install CROSSINSTALL=1
if [ $? != 0 ]; then
  doerror "installing the ARMv7 RTL"
  failure
fi
cd ../..

cd packages
make FPC="$FPCROSSARMBINARY" OPT="-ap" CPU_TARGET=arm CROSSOPT="-FD${IPHONEPLATFORMBASEDIR}/usr/bin -XR${IPHONESDKDIR}/ -ap -Cparmv7 -Cfvfpv3" INSTALL_PREFIX="$FPCARMV7UNITSINSTALLDIR" RELEASE=1 install CROSSINSTALL=1
if [ $? != 0 ]; then
  doerror "installing the ARMv7 packages"
  failure
fi
cd ..

# now lipo everything together


cd "$FPCARMV7UNITSINSTALLDIR"
cd lib/fpc/$VERSION/units/arm-darwin/
for objfile in */*.o
do
  lipo -create $objfile /usr/local/lib/fpc/$VERSION/units/arm-darwin/$objfile -output /usr/local/lib/fpc/$VERSION/units/arm-darwin/$objfile
  if [ $? != 0 ]; then
    doerror "lipo'ing $FPCARMV7UNITSINSTALLDIR/lib/fpc/$VERSION/units/arm-darwin/$objfile and /usr/local/lib/fpc/$VERSION/units/arm-darwin/$objfile"
    failure
  fi
done

# remove temporary files
rm -rf "$FPCARMV7UNITSINSTALLDIR"

####################################################

echo
echo
echo "Compiling all units for the Simulator..."
echo

cd "$FPCSOURCEDIR"

make FPC="$FPCBOOTSTRAPBINARY" OS_TARGET=iphonesim distclean -j 4
if [ $? != 0 ]; then
  doerror "cleaning the source directory for the Simulator"
  failure
fi

# these do not appear to be erased by distclean for some reason
rm -rf "packages/fcl-db/units" "compiler/ppcarm" "compiler/ppcrossarm"

cd rtl/darwin
make FPC="$FPCBOOTSTRAPBINARY" OPT="-ap" RELEASE=1 OS_TARGET=iphonesim CROSSOPT="-FD${SIMULTORPLATFORMBASEDIR}/usr/bin -XR${SIMULTORSDKDIR}/ -ap" all -j "$PARALLELMAKE"

if [ $? != 0 ]; then
  doerror "building the RTL for the Simulator"
  failure
fi
cd ../..

cd packages
make FPC="$FPCBOOTSTRAPBINARY" OPT="-ap" RELEASE=1 OS_TARGET=iphonesim CROSSOPT="-FD${SIMULTORPLATFORMBASEDIR}/usr/bin -XR${SIMULTORSDKDIR}/ -ap" all -j "$PARALLELMAKE"

if [ $? != 0 ]; then
  doerror "building the packages for the Simulator"
  failure
fi
cd ..


echo
echo
echo "Installing the Simulator units..."
echo

cd rtl/darwin
make FPC="$FPCBOOTSTRAPBINARY" OPT="-ap" OS_TARGET=iphonesim CROSSOPT="-FD${SIMULTORPLATFORMBASEDIR}/usr/bin -XR${SIMULTORSDKDIR}/ -ap" install CROSSINSTALL=1
if [ $? != 0 ]; then
  doerror "installing the Simulator RTL units"
  failure
fi
cd ../..

cd packages
make FPC="$FPCBOOTSTRAPBINARY" OPT="-ap" OS_TARGET=iphonesim CROSSOPT="-FD${SIMULTORPLATFORMBASEDIR}/usr/bin -XR${SIMULTORSDKDIR}/ -ap" install CROSSINSTALL=1
if [ $? != 0 ]; then
  doerror "installing the Simulator RTL units"
  failure
fi
cd ..


####################################################


# clean up
echo
echo
echo "Cleaning up..."
echo
cd "$FPCSOURCEDIR"
make FPC="$FPCBOOTSTRAPBINARY" distclean -j 4
make FPC="$FPCROSSARMBINARY" distclean -j 4
# these do not appear to be erased by distclean for some reason
rm -rf "packages/fcl-db/units" "compiler/ppcarm" "compiler/ppcrossarm"
chown -R root:admin .
chmod -R g+w .
rm "$FPCROSSARMBINARY"

cd "$STARTDIR"

# we're done!
echo
echo
echo "The installation of iOS SDK support for FPC was successful! You can now"
echo "create FPC iOS projects using the Xcode application included in the iOS"
echo "SDK and the templates installed by FPC for iOS if you are using Xcode 3.x."
echo "They are available in Xcode under \"User Templates\" in the \"iPhone (FPC)\""
echo " group."
echo
echo "If you are using Xcode 4.x, see http://web.me.com/macpgmr/ObjP/Xcode4/ for"
echo "example templates."
echo
echo "(You can now close this window and/or quit Terminal)"
echo
echo
echo
# wait for keypress in case Terminal is configured to automatically close windows after the
# process has finished
read