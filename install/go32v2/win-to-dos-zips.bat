@echo off

rem Batch to generate go32v2 3.3.1 zips
rem Used on a Windows 7
rem in August 2019 for 3.2.0 prerelease test
rem Variables used below, this should be the only part
rem that needs to be updated on a future release

set BATCH_RELEASE_VERSION=3.3.1
set DOS_ZIP_VERSION=331
set BATCH_OS_TARGET=go32v2
set NAT_OS_TARGET=win32
rem To avoid problems, it seems better to keep this directory name
rem within the 8.3 constraints
set BATCH_FPCBUILD_DRIVE=c:
set BATCH_BUILD_NAME=pure-trunk
set BATCH_FPCBUILD_DIR=%BATCH_FPCBUILD_DRIVE%\pas\%BATCH_BUILD_NAME%
rem Same with forward slashes
set GNU_FPCBUILD_DIR=%BATCH_FPCBUILD_DRIVE%/pas/%BATCH_BUILD_NAME%
set GO32ZIPDIR=go32v2-zips
set FPC=

rem To avoid upx compression
set UPXPROG=echo
rem This is need to force cross compile to use short dir names
rem set LIMIT83fs="go32v2 win32"
set LOCAL_LIMIT83fs="go32v2 emx watcom msdos"
rem Start of Batch comands
%BATCH_FPCBUILD_DRIVE%
rem  Accept a label for partial runs
if not "%1" == "" goto %1

if exist %BATCH_FPCBUILD_DIR%-export goto dir_ok
cd %BATCH_FPCBUILD_DIR%

if not exist .svn goto dir_ok
cd ..
if not exist %BATCH_BUILD_NAME%-export goto no_dir
echo Removing directory %BATCH_BUILD_NAME%-export
rmdir /S /Q  %BATCH_BUILD_NAME%-export
:no_dir
echo Exporting %BATCH_BUILD_NAME% to %BATCH_BUILD_NAME%-export
svn export --force %BATCH_BUILD_NAME% %BATCH_BUILD_NAME%-export
set SKIP_DISTCLEAN=1
:dir_ok
set BATCH_BUILD_NAME=%BATCH_BUILD_NAME%-export
set BATCH_FPCBUILD_DIR=%BATCH_FPCBUILD_DRIVE%\pas\%BATCH_BUILD_NAME%
rem Same with forward slashes
set GNU_FPCBUILD_DIR=%BATCH_FPCBUILD_DRIVE%/pas/%BATCH_BUILD_NAME%
cd %BATCH_FPCBUILD_DIR%
rem Stage 0: Clean everything
:stage0
rem Test pass to check if NOGDB is needed
echo make info OS_TARGET=%BATCH_OS_TARGET%
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
if "%SKIP_DISTCLEAN%" == "1" goto skip_distclean
rm *.zip
rm -Rf %GO32ZIPDIR%
echo make distclean NOGDB=1
make distclean NOGDB=1 > distclean.log
if errorlevel 1 goto got_make_error
rem Target distclean, using NOGDB from env if set earlier
echo make distclean OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs%
make distclean OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% > target-distclean.log
if errorlevel 1 goto got_make_error
:skip_distclean
rem Stage 1: Compile and generates all zips
:stage1
echo make native rtl
rem all options removed OS_TARGET=%NAT_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs%
make -C fpcsrc/rtl all  > rtl_all.log
if errorlevel 1 goto got_make_error
make -C fpcsrc/compiler cycle  > cycle.log
if errorlevel 1 goto got_make_error
cd fpcsrc\compiler
copy /y ppc386.exe ppc386-start.exe
set FPC=%GNU_FPCBUILD_DIR%/fpcsrc/compiler/ppc386-start.exe
cd ..\..
echo make and fpmake in packages
make -C fpcsrc/packages fpmake.exe  > packages_fpmake.log
if errorlevel 1 goto got_make_error
echo make and fpmake in utils
make -C fpcsrc/utils fpmake.exe  > utils_fpmake.log
if errorlevel 1 goto got_make_error
rem use win32 target for source zip generation
rem to get correct shortening later
echo make sourcezip
rem all options removed OS_TARGET=%NAT_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs%
make sourcezip  > sourcezip.log
rem OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs%
if errorlevel 1 goto got_make_error
echo make demozip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs%
make demozip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% > demozip.log
if errorlevel 1 goto got_make_error
echo make docsrc OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs%
make docsrc OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% > docsrc.log
if errorlevel 1 goto got_make_error
echo make go32v2zip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% BUILDFULLNATIVE=1
make go32v2zip OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% BUILDFULLNATIVE=1 > go32v2zip.log
if errorlevel 1 goto got_make_error
echo make utilities OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% BUILDFULLNATIVE=1
make utilities OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% BUILDFULLNATIVE=1 > utilities.log
if errorlevel 1 goto got_make_error

rem set FPC=%GNU_FPCBUILD_DIR%/fpcsrc/compiler/ppc.exe
rem echo Using new compiler %FPC%

:stageinst
echo make -C fpcsrc installer_all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% BUILDFULLNATIVE=1
make -C fpcsrc installer_all OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% BUILDFULLNATIVE=1 > installer.log
if errorlevel 1 goto got_make_error
mkdir %GO32ZIPDIR%
cp fpcsrc/installer/install.exe %GO32ZIPDIR%
cp fpcsrc/installer/install.dat %GO32ZIPDIR%
cp install/bingo32/cwsdpmi.exe %GO32ZIPDIR%
cp install/bingo32/wmemu387.dxe %GO32ZIPDIR%
rem No used for installer
rem make -C fpcsrc installer_zipinstall OS_TARGET=%BATCH_OS_TARGET%
if errorlevel 1 goto got_make_error
rem this copies both ide and installer zip
cp fpcsrc/*.zip .

echo "long zip listing" > long-zip-listing.txt
for %%f in (*.zip) do echo %%f >> long-zip-listing.txt

rem  now we have long file names packages
:stageshort
echo make shortnames OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs%
make shortnames OS_TARGET=%BATCH_OS_TARGET% LIMIT83fs=%LOCAL_LIMIT83fs% > shortnames.log 2> shortnames.err
if errorlevel 1 goto got_make_error
rem This fails for fcl packages, because those have a long i386-go32v2 prefix
rem Set CROSSINSTALL to 1 to force that prefix in shortnames rule
echo make shortnames OS_TARGET=%BATCH_OS_TARGET% CROSSINSTALL=1 LIMIT83fs=%LOCAL_LIMIT83fs%
make shortnames OS_TARGET=%BATCH_OS_TARGET% CROSSINSTALL=1 LIMIT83fs=%LOCAL_LIMIT83fs% > shortnames2.log 2> shortnames2.err
if errorlevel 1 goto got_make_error

:stage_allzips
mkdir %GO32ZIPDIR%
cp *.zip %GO32ZIPDIR%

:test_zips
if exist chk-inst.lst del chk-inst.lst
if exist short-zip-listing.txt del short-zip-listing.txt
cd %GO32ZIPDIR%
echo "Listing count of occurences of zip files  in install.dat to ..\chk-inst.lst"
for %%f in (*.zip) do grep -c %%f install.dat >> ..\chk-inst.lst
echo "Generating short zip listing in ..\short-zip-listing.txt"
for %%f in (*.zip) do echo %%f >> ..\short-zip-listing.txt
cd ..

rem Check if any of the zips is not listed in install.dat
grep -c 0 chk-inst.lst
if errorlevel 1 goto zip_check_ok
echo "At least one generated zip file is not listed in install.dat"
grep -n 0 chk-inst.lst > zero-lines.lst
sed -n "s,^\([0-9]*\):0,NR == \1,p" zero-lines.lst > gawk.lst
gawk -f gawk.lst short-zip-listing.txt > not-found.lst
type not-found.lst
:zip_check_ok

cd %GO32ZIPDIR%
zip ..\dos%DOS_ZIP_VERSION%.zip install.exe install.dat cwsdpmi.exe wmemu387.dxe *dos.zip
if errorlevel 1 goto got_zip_error
copy /y ..\dos%DOS_ZIP_VERSION%.zip ..\dos%DOS_ZIP_VERSION%full.zip
zip ..\dos%DOS_ZIP_VERSION%full.zip *src.zip 
if errorlevel 1 goto got_zip_error
goto end_ok
:got_zip_error
echo "Error while running zip"
goto end_ok
:got_make_error
echo "Error while running make"
:end_ok
