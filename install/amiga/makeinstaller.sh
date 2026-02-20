#!/bin/bash
DoCPU=m68k
DoOS=amiga

PLATFORM=$DoCPU-$DoOS

echo "######## Start building Installer for "$PLATFORM

# get some dirs
AmigaDir=`pwd`
cd ../../fpcsrc
FPC_SRC=`pwd`

#echo "start at amiga dir "$AmigaDir" and FPC directory "$FPCDir
cd $AmigaDir

# make getversion to catch the version number
echo "#### compile GetVersion "
fpc -B GetVersion.pas -FU. -Fu"$FPC_SRC/compiler"
FPCVer=`./GetVersion`
echo "--- Version to compile: "$FPCVer

# make FPC

cd $FPC_SRC
make -j 8 zipinstall CPU_TARGET=$DoCPU OS_TARGET=$DoOS OPT="-O-" CROSSOPT="-XV -Avasm" FPMAKEOPT="-T 8"

# make IDE

echo "###### make ide"

FPC_COMPILER=$FPC_SRC/compiler/ppcross68k

FPC_OPTS=" -veiw -l -Avasm -XV"
FPC_OPTS=$FPC_OPTS" -O2 -Tamiga -XPm68k-amiga- -Xr -Ur -Xs -n -XX- -CX- -Sg -Cp68020 -alrt"
FPC_OPTS=$FPC_OPTS" -dRELEASE -dNODEBUG -dNOCATCH -dBrowserCol -dGDB -dm68k"
FPC_OPTS=$FPC_OPTS" -FUunits/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/rtl/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/rtl-extra/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/rtl-generics/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/ami-extra/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/fv/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/rtl-console/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/amunits/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/chm/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/fcl-xml/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/fcl-base/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/fcl-res/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/rtl-objpas/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/regexpr/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/paszlib/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/fcl-process/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/hash/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/packages/libtar/units/$PLATFORM"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/compiler"
FPC_OPTS=$FPC_OPTS" -Fi$FPC_SRC/compiler"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/compiler/m68k"
FPC_OPTS=$FPC_OPTS" -Fi$FPC_SRC/compiler/m68k"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/compiler/targets"
FPC_OPTS=$FPC_OPTS" -Fu$FPC_SRC/compiler/systems"
FPC_OPTS=$FPC_OPTS" -Fi$FPC_SRC/compiler/m68k"

cd $FPC_SRC/packages/ide

rm -rf units/$PLATFORM
mkdir -p units/$PLATFORM

$FPC_COMPILER $FPC_OPTS fp.pas

cd ..

echo "###### make fpcmake"

export FPC=$FPC_SRC/compiler/ppcross68k

cd $FPC_SRC/utils/fpcm

make OS_TARGET=amiga CPU_TARGET=m68k clean all CROSSOPT="-Avasm -XV -Cp68020"

echo "###### make fpcres"

cd $FPC_SRC/utils/fpcres

make OS_TARGET=amiga CPU_TARGET=m68k clean all CROSSOPT="-Avasm -XV -Cp68020"


rm -rf $AmigaDir/pack
mkdir $AmigaDir/pack

echo "### Unpack FPC "
tar zvxf $FPC_SRC/fpc-$FPCVer.$PLATFORM.*.tar.gz -C $AmigaDir/pack >/dev/null

echo "### copy FP-IDE, fpcmake, fpcres"
cp $FPC_SRC/packages/ide/fp $AmigaDir/pack/bin/$PLATFORM
cp $FPC_SRC/packages/ide/fp.ans $AmigaDir/pack/bin/$PLATFORM
cp $FPC_SRC/utils/fpcm/bin/m68k-amiga/fpcmake $AmigaDir/pack/bin/$PLATFORM
cp $FPC_SRC/utils/fpcres/bin/m68k-amiga/fpcres $AmigaDir/pack/bin/$PLATFORM

# create installer stuff
cd $AmigaDir
VER=$FPCVer
DIRVER=$VER
SHORTVER=${VER::-2}
SAVEVER=$SHORTVER
# what for?
#BINDIR=..
#INTDIR=..

########

PLAT=$PLATFORM

CDIR=$(pwd)
AIM=$CDIR/FPCInstall
SRC=$CDIR/pack
BIN=bin/$PLAT
UNITS=units/$PLAT
DOCS=share/doc/fpc-$DIRVER


rm *.lha

set -e

echo "### unpack help"
cd $AIM/docs
unzip -o $AmigaDir/doc-chm.zip

cd $CDIR

echo "### copy compiler"
rm -rf $AIM/compiler
mkdir -p $AIM/compiler/$BIN

mv $SRC/$BIN/fpc $AIM/compiler/$BIN
cp $CDIR/cfg/fpc.cfg $AIM/compiler/$BIN
mv $SRC/$BIN/ppc* $AIM/compiler/$BIN
mv $SRC/$BIN/fpcres $AIM/compiler/$BIN
mv $SRC/$BIN/fpcmake $AIM/compiler/$BIN

echo "### copy FP-IDE"
rm -rf $AIM/fp/bin
mkdir -p $AIM/fp/$BIN

mv $SRC/$BIN/fp $AIM/fp/$BIN
mv $SRC/$BIN/fp.ans $AIM/fp/$BIN
cp $CDIR/cfg/fp.* $AIM/fp/$BIN

echo "copy additional tools"
rm -rf $AIM/addtools
mkdir -p $AIM/addtools/$BIN

mv $SRC/$BIN/* $AIM/addtools/$BIN

# COMMON UNITS
echo "copy common units"
rm -rf $AIM/common
mkdir -p $AIM/common/$UNITS
mkdir -p $AIM/common/docs

mv $SRC/$UNITS/ami-extra $AIM/common/$UNITS
mv $SRC/$UNITS/amunits $AIM/common/$UNITS
mv $SRC/$UNITS/rtl $AIM/common/$UNITS
mv $SRC/$UNITS/rtl-* $AIM/common/$UNITS

set +e
mv $SRC/$DOCS/ami-extra $AIM/common/docs
mv $SRC/$DOCS/amunits $AIM/common/docs
mv $SRC/$DOCS/rtl-* $AIM/common/docs
set -e

#USEFUL UNITS
echo "copy useful units"
rm -rf $AIM/useful
mkdir -p $AIM/useful/$UNITS
mkdir -p $AIM/useful/docs

mv $SRC/$UNITS/bzip2 $AIM/useful/$UNITS
mv $SRC/$UNITS/chm $AIM/useful/$UNITS
mv $SRC/$UNITS/fv $AIM/useful/$UNITS
mv $SRC/$UNITS/hash $AIM/useful/$UNITS
mv $SRC/$UNITS/numlib $AIM/useful/$UNITS
mv $SRC/$UNITS/pasjpeg $AIM/useful/$UNITS
mv $SRC/$UNITS/paszlib $AIM/useful/$UNITS
mv $SRC/$UNITS/regexpr $AIM/useful/$UNITS
mv $SRC/$UNITS/symbolic $AIM/useful/$UNITS
mv $SRC/$UNITS/unzip $AIM/useful/$UNITS
mv $SRC/$UNITS/vcl-compat $AIM/useful/$UNITS

set +e
mv $SRC/$DOCS/bzip2 $AIM/useful/docs
mv $SRC/$DOCS/fv $AIM/useful/docs
mv $SRC/$DOCS/hash $AIM/useful/docs
mv $SRC/$DOCS/numlib $AIM/useful/docs
mv $SRC/$DOCS/pasjpeg $AIM/useful/docs
mv $SRC/$DOCS/paszlib $AIM/useful/docs
mv $SRC/$DOCS/regexpr $AIM/useful/docs
mv $SRC/$DOCS/symbolic $AIM/useful/docs
set -e
# FCL UNITS
echo "copy FCL units"
rm -rf $AIM/fcl
mkdir -p $AIM/fcl/$UNITS
mkdir -p $AIM/fcl/docs

mv $SRC/$UNITS/fcl-* $AIM/fcl/$UNITS
set +e
mv $SRC/$DOCS/fcl-* $AIM/fcl/docs
set -e

# OTHER UNITS
echo "copy other units"
# remove google and office stuff
rm -rf $SRC/$UNITS/odata
rm -rf $SRC/$UNITS/googleapi
rm -rf $AIM/other
mkdir -p $AIM/other/$UNITS
mkdir -p $AIM/other/docs

mv $SRC/$UNITS/* $AIM/other/$UNITS
set +e
mv $SRC/$DOCS/* $AIM/other/docs
set -e

#TRANSLATIONS
echo "copy translations"
rm -rf $AIM/msg
mv $SRC/msg $AIM

#cleanup
rm -rf temp

# get 
#git clone --depth 1 https://gitlab.com/freepascal.org/fpc/build.git --branch $RELEASEBRANCH temp
#svn co https://svn.freepascal.org/svn/fpcbuild/tags/$RELEASEBRANCH/install/doc/ temp

cp $AmigaDir/../doc/faq.txt $AIM/docs
cp $AmigaDir/../doc/readme.txt $AIM/docs
cp $AmigaDir/../doc/whatsnew.txt $AIM/docs

rm -rf pack

# templates
echo "apply templates"

cp $AmigaDir/Templates/ReadMe.Amiga $AmigaDir/FPCInstall/
cp $AmigaDir/Templates/fpc_install $AmigaDir/FPCInstall/

sed -i -e 's/%VERSION%/'$FPCVer'/g' $AmigaDir/FPCInstall/ReadMe.Amiga
sed -i -e 's/%VERSION%/'$FPCVer'/g' $AmigaDir/FPCInstall/fpc_install



echo "create archive"

NewName=FPC-$SAVEVER

mv FPCInstall $NewName
mv FPCInstall.info $NewName.info

lha co5 fpc-$SAVEVER-$PLAT.lha $NewName $NewName.info

mv $NewName FPCInstall
mv $NewName.info FPCInstall.info

echo done.



echo "OK"


