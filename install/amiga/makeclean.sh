#!/bin/sh
set +e

CDIR=$(pwd)
#remove temp
rm -rf temp
rm -rf pack

AIM=$CDIR/FPCInstall
BIN=bin/m68k-amiga
UNITS=units/m68k-amiga
DOCS=share/doc/*/

echo "remove compiler"
# remove compiler
rm -rf $AIM/compiler

echo "remove FP-IDE"
rm -rf $AIM/fp/bin

echo "remove additional tools"
# remove tools
rm -rf $AIM/addtools

echo "remove common units"
# remove common
rm -rf $AIM/common

echo "remove useful units"
# remove useful
rm -rf $AIM/useful

echo "remove FCL"
# remove fcl
rm -rf $AIM/fcl

echo "remove other units"
# remove other
rm -rf $AIM/other

echo "remove translations"
# remove translations
rm -rf $AIM/msg

rm -f $AIM/docs/faq.txt
rm -f $AIM/docs/readme.txt
rm -f $AIM/docs/whatsnew.txt
rm -rf $AIM/docs/help

rm -f $AIM/ReadMe.Amiga
rm -f $AIM/fpc_install

rm -f GetVersion GetVersion.o version.o version.ppu

echo "remove archive"
rm *.lha

echo "OK"
