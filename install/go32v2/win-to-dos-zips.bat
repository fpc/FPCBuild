@echo off

rem Batch to generate Dos 2.6.0.a zips
rem Used on a Windows XP SP3
rem in october 2010 for 2.6.0a test
rem Variables used below, this should be the only part
rem that needs to be updated on a future release

set BATCH_RELEASE_VERSION=2.6.0
set BATCH_OS_TARGET=go32v2
rem To avoid problems, it seems better to keep this directory
rem name within the 8.3 constraints
set BATCH_FPCBUILD_DRIVE=e:
set BATCH_FPCBUILD_DIR=%BATCH_FPCBUILD_DRIVE%\pas\rel260a
rem Same with forward slashes
set GNU_FPCBUILD_DIR=%BATCH_FPCBUILD_DRIVE%/pas/rel260a
set GO32ZIPDIR=go32v2-zips

rem To avoid upx compression
set UPXPROG=echo
rem This is need to force cross compile to use short dir names
set LIMIT83fs="go32v2 win32"
rem Start of Batch comands
cd %BATCH_FPCBUILD_DRIVE%
cd %BATCH_FPCBUILD_DIR%
rem Use cygwin versions od rm and cp programs
set RMPROG=e:/cygwin/bin/rm
set CPPROG=e:/cygwin/bin/cp

rem  Accept a label fro partial runs
if not "%1" == "" goto %1

rem Stage 0: Clean everything
:stage0
set STAGE=stage0
rem Test pass to check if NOGDB is needed
make info OS_TARGET=%BATCH_OS_TARGET%
if errorlevel 1 goto need_nogdb
goto gdb_ok
:need_nogdb
echo "Setting NOGDB env variable to 1"
set NOGDB=1
goto gdb_handled
:gdb_ok
set USEDGDBDIR=%GNU_FPCBUILD_DIR%/fpcsrc/libgdb/go32v2
:gdb_handled
rem Native distclean, force NOGDB=1
rm *.zip
rm -Rf %GO32ZIPDIR%
set STAGE=distclean
make distclean NOGDB=1
if errorlevel 1 goto got_make_error
rem Target distclean, using NOGDB from env if set earlier
set STAGE=target distclean
make distclean OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
rem Stage 1: Compile and generates all zips
:stage1
set STAGE=sourcezip
make sourcezip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=demozip
make demozip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=docsrc
make docsrc OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=go32v2zip
make go32v2zip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=utilities
make utilities OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
:stageide
set STAGE=stage ide rtl
make -C fpcsrc/rtl all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
rem set STAGE=stage ide packages
rem make -C fpcsrc/packages all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
rem if errorlevel 1 goto got_make_error
set STAGE=stage ide packages/gdbint
make -C fpcsrc/packages/gdbint all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=stage ide packages/regexpr
make -C fpcsrc/packages/regexpr all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=stage ide packages/fcl-base
make -C fpcsrc/packages/fcl-base all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=stage ide packages/fcl-xml
make -C fpcsrc/packages/fcl-xml all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=stage ide packages/chm
make -C fpcsrc/packages/chm all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=stage ide packages/graph
make -C fpcsrc/packages/graph all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=stage ide packages/fv
make -C fpcsrc/packages/fv all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
set STAGE=stage ide ide_zipinstall
make -C fpcsrc ide_zipinstall OS_TARGET=%BATCH_OS_TARGET% OPT=-Fl%USEDGDBDIR% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error

:stageinst
set STAGE=stage installer
make -C fpcsrc installer_all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
mkdir %GO32ZIPDIR%
set STAGE=installer %GO32ZIPDIR%
cp fpcsrc/installer/install.exe %GO32ZIPDIR%
cp fpcsrc/installer/install.dat %GO32ZIPDIR%
rem No used for installer
rem make -C fpcsrc installer_zipinstall OS_TARGET=%BATCH_OS_TARGET%
if errorlevel 1 goto got_make_error
rem this copies both ide and installer zip
cp fpcsrc/*.zip .

rem  now we have long file names packages
:stageshort
set STAGE=shortnames
make shortnames OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
rem This fails for fcl packages, because those have a long i386-go32v2 prefix
rem Set CROSSINSTALL to 1 to force that prefix in shortnames rule
set STAGE=shortnames crossinstall
make shortnames OS_TARGET=%BATCH_OS_TARGET% CROSSINSTALL=1 LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error

:stage_allzips
mkdir %GO32ZIPDIR%
cp *.zip %GO32ZIPDIR%

:test_zips
rm chk-inst.lst
cd %GO32ZIPDIR%
for %%f in (*.zip) do grep -c %%f install.dat >> ..\chk-inst.lst
cd ..
rem Check if any of the zips is not listed in install.dat
grep -c 0 chk-inst.lst
if errorlevel 1 goto zip_check_ok
echo "At least one generated zip file is not listed in install.dat"
:zip_check_ok
goto end_ok
:got_make_error
echo "Error while running make at stage %STAGE%"
:end_ok
