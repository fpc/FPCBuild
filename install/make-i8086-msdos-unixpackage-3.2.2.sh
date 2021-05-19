#! /bin/sh

# hacky script for building the i8086-msdos release package for the fpc 3.2.x series
# it is a stopgap solution until we have proper support for multiple subarchs and memory models in the main makefiles

# script should be run in the fpcbuild directory
# requires nasm

set -e

FPCVERSION=3.2.2
FPCRCVERSION=3.2.2

PACKAGE_VERSION=$FPCRCVERSION

CPU_SOURCE=$(fpc -iSP)
OS_SOURCE=$(fpc -iSO)

BASEDIR=$(pwd)
install -d $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCVERSION/units/msdos_

function build_subarch_mm {
    SUBARCH=$1
    MEMORY_MODEL=$2
    make -j `nproc` -C fpcsrc clean OS_SOURCE=$OS_SOURCE CPU_SOURCE=$CPU_SOURCE OS_TARGET=msdos CPU_TARGET=i8086 OPT="-CX -XXs" BINUTILSPREFIX= CROSSOPT="-Wm$MEMORY_MODEL -Cp$SUBARCH"
    make -j `nproc` -C fpcsrc buildbase OS_SOURCE=$OS_SOURCE CPU_SOURCE=$CPU_SOURCE OS_TARGET=msdos CPU_TARGET=i8086 OPT="-CX -XXs" BINUTILSPREFIX= CROSSOPT="-Wm$MEMORY_MODEL -Cp$SUBARCH"
    make -j `nproc` install CROSSINSTALL=1 INSTALL_PREFIX=$BASEDIR/OUTPUT-MSDOS OS_SOURCE=$OS_SOURCE CPU_SOURCE=$CPU_SOURCE OS_TARGET=msdos CPU_TARGET=i8086 OPT="-CX -XXs" BINUTILSPREFIX= CROSSOPT="-Wm$MEMORY_MODEL -Cp$SUBARCH" NOGDB=1
    mv $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCVERSION/units/msdos $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCVERSION/units/msdos_/$SUBARCH-$MEMORY_MODEL
    if [ "$FPCVERSION" != "$FPCRCVERSION" ]; then
        mv $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCRCVERSION/units/msdos/rtl $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCVERSION/units/msdos_/$SUBARCH-$MEMORY_MODEL
    fi
}

function build_subarch {
    build_subarch_mm $1 tiny
    build_subarch_mm $1 small
    build_subarch_mm $1 medium
    build_subarch_mm $1 compact
    build_subarch_mm $1 large
    build_subarch_mm $1 huge
}

build_subarch 8086
build_subarch 80186
build_subarch 80286
build_subarch 80386

if [ "$FPCVERSION" != "$FPCRCVERSION" ]; then
    mv $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCRCVERSION/ppcross8086 $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCVERSION/
    rm -r $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCRCVERSION
fi
mv $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCVERSION/units/msdos_ $BASEDIR/OUTPUT-MSDOS/lib/fpc/$FPCVERSION/units/msdos
rm $BASEDIR/OUTPUT-MSDOS/bin/nasm.exe
ln -s "../lib/fpc/$FPCVERSION/ppcross8086" $BASEDIR/OUTPUT-MSDOS/bin/ppcross8086
rm -r $BASEDIR/OUTPUT-MSDOS/doc

tar -c -a --owner=root --group=root --mode=g-w -f fpc-$PACKAGE_VERSION.$CPU_SOURCE-$OS_SOURCE.cross.i8086-msdos.tar.xz -C OUTPUT-MSDOS .
