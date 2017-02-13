@echo off

rem Batch to generate Dos 3.0.2 zips
rem Used on a Windows XP SP3
rem in February 2017 for 3.0.2 test
rem Variables used below, this should be the only part
rem that needs to be updated on a future release

set BATCH_RELEASE_VERSION=3.0.2
set BATCH_OS_TARGET=go32v2
set NAT_OS_TARGET=win32
rem To avoid problems, it seems better to keep thios directory
rem name within the 8.3 constraints
set BATCH_FPCBUILD_DRIVE=e:
set BATCH_FPCBUILD_DIR=%BATCH_FPCBUILD_DRIVE%\pas\fpcbuild-%BATCH_RELEASE_VERSION%
rem Same with forward slashes
set GNU_FPCBUILD_DIR=%BATCH_FPCBUILD_DRIVE%/pas/fpcbuild-%BATCH_RELEASE_VERSION%
set GO32ZIPDIR=go32v2-zips

rem To avoid upx compression
set UPXPROG=echo
rem This is need to force cross compile to use short dir names
set LIMIT83fs="go32v2 win32"
rem Start of Batch comands
cd %BATCH_FPCBUILD_DRIVE%
cd %BATCH_FPCBUILD_DIR%

rem  Accept a label fro partial runs
if not "%1" == "" goto %1

rem Stage 0: Clean everything
:stage0
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
make distclean NOGDB=1
if errorlevel 1 goto got_make_error
rem Target distclean, using NOGDB from env if set earlier
make distclean OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
rem Stage 1: Compile and generates all zips
:stage1
make sourcezip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
make demozip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
make docsrc OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
make go32v2zip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs% BUILDFULLNATIVE=1
if errorlevel 1 goto got_make_error
make utilities OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs% BUILDFULLNATIVE=1
if errorlevel 1 goto got_make_error

:stageide
rem make -C fpcsrc/rtl all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs% BUILDFULLNATIVE=1
rem if errorlevel 1 goto got_make_error
rem make -C fpcsrc/packages all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs% BUILDFULLNATIVE=1
rem if errorlevel 1 goto got_make_error
set FPC=%GNU_FPCBUILD_DIR%/fpcsrc/compiler/ppc.exe
echo Using new compiler %FPC%
rem This still fails unless you set FPCDIR explicitly...
make -C fpcsrc ide_zipinstall OS_TARGET=%BATCH_OS_TARGET% OPT=-Fl%USEDGDBDIR% LIMIT83fs=%LIMIT83fs% BUILDFULLNATIVE=1 FPCDIR=%GNU_FPCBUILD_DIR%/fpcsrc
if errorlevel 1 goto got_make_error

:stageinst
make -C fpcsrc installer_all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs% BUILDFULLNATIVE=1
if errorlevel 1 goto got_make_error
mkdir %GO32ZIPDIR%
cp fpcsrc/installer/install.exe %GO32ZIPDIR%
cp fpcsrc/installer/install.dat %GO32ZIPDIR%
rem No used for installer
rem make -C fpcsrc installer_zipinstall OS_TARGET=%BATCH_OS_TARGET%
if errorlevel 1 goto got_make_error
rem this copies both ide and installer zip
cp fpcsrc/*.zip .

rem  now we have long file names packages
:stageshort
make shortnames OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LIMIT83fs%
if errorlevel 1 goto got_make_error
rem This fails for fcl packages, because those have a long i386-go32v2 prefix
rem Set CROSSINSTALL to 1 to force that prefix in shortnames rule
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
echo "Error while running make"
:end_ok
