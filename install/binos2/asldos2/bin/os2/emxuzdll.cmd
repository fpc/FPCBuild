@echo off
if "%1"=="" goto usage
if "%2"=="" goto usage
if not "%3"=="" goto usage

if exist *.dll goto exist
unzip -j -C %1 *.dll
if errorlevel 1 goto cleanup
for %%f in (*.dll) do emxupd %%f %2
:cleanup
del *.dll 2>nul
goto end

:usage
echo Usage:   emxuzdll ^<zip_file^> ^<dll_dir^>
echo Example: emxuzdll a:\emxfix04.zip c:\emx\dll
goto end

:exist
echo Sorry, there are DLL files in the current directory
goto end

:end
