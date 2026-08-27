Building the Windows installers on Linux with wine
==================================================

makewininstaller.sh builds the Windows installers of Free Pascal on a Linux
machine. It needs wine, curl and unzip, and nothing else that is not already in
this repository.

    install/wine/makewininstaller.sh

The result is the same set of files that a Windows release machine produces:

fpc-<version>.i386-win32.exe                        (make inno)
fpc-<version>.i386-win32.cross.x86_64-win64.exe     (make innox64)
fpc-<version>.win32.and.win64.exe                   (make innox86x64)


How it works
------------

The compiler, the run time library, the packages and the utilities are built by
a Windows compiler running under wine. The build is therefore a normal native
Windows build: OS_SOURCE and OS_TARGET are both win32, so the installation tree
gets the Windows layout that the .ist files expect, and the compiler goes
through the usual four stage cycle. Nothing is cross compiled.

The starting compiler is the released 3.2.2 Windows compiler, which is what
REQUIREDVERSION in fpcsrc/Makefile.fpc asks for. The script downloads it from
downloads.freepascal.org and installs it into a temporary wine prefix, together
with Inno Setup. Both can be given as a local file instead.

Everything the script installs goes into a temporary wine prefix which is
removed again when it is done. The user's own ~/.wine is never touched.


Options
-------

  --installers=<list>   comma separated: win32, win64cross, combined.
                        Default: all three.
  --inno=<what>         Inno Setup: a directory holding ISCC.exe, an installer
                        to run, or a url to download. Default: download
                        Inno Setup 6.7.3.
  --inno-cache=<dir>    where the downloads are kept between runs.
                        Default $XDG_CACHE_HOME/fpc-wine.
  --fpc322=<what>       the starting compiler: a Windows installer or a url.
                        Default: download it.
  --start-compiler=<f>  use this ppc386.exe and install no released compiler.
  --output=<dir>        where the installers are put. Default: the tree root.
  --nodocs              build without documentation.
  --prefix=<dir>        use this wine prefix instead of a temporary one.
  --keep                do not remove the temporary wine prefix.

Examples:

    # everything, downloading what is needed
    install/wine/makewininstaller.sh

    # only the combined installer, with a local inno setup and compiler
    install/wine/makewininstaller.sh --installers=combined \
        --inno=$HOME/innosetup-6.7.3.exe \
        --fpc322=$HOME/fpc-3.2.2.i386-win32.exe

    # reuse a prepared prefix, for repeated runs or for CI
    install/wine/makewininstaller.sh --prefix=$HOME/fpcwine


Requirements
------------

wine        tested with wine 9.0. The prefix is created with WINEARCH=win64 so
            that both the 32 bit and the 64 bit programs run.
curl        for the downloads. Not needed when --inno, --fpc322 and
            --start-compiler all point at local files.
doc-chm.zip in the root of the tree, holding help/*.chm. It is required, not
            built, in the same way that makepack requires doc-pdf.tar.gz.
            Use --nodocs to build without it.

wineserver needs a writable /run/user/<uid>. The script falls back to a
temporary directory when XDG_RUNTIME_DIR is not usable, which matters inside
containers.


Notes
-----

Uppercase letters in the path of the tree.

    install/binw32 holds two programs from GNU fileutils 3.16, of 1996:
    rm.exe and ginstall.exe. They lowercase every absolute path they are given.
    On Windows that makes no difference, because the file system does not care
    about case. Under wine on a Linux file system it does: given
    Z:/home/michael/FPC/build/... they look for z:/home/michael/fpc/build/...,
    find nothing, and exit with status 0. rm deletes nothing, ginstall creates
    no directory, make sees success and the next command fails on a directory
    that is not there.

    The script therefore builds through an all lowercase symlink when the path
    of the tree has an uppercase letter in it. Nothing else is needed; with a
    lowercase path both programs behave.

The order in which the installers are built.

    The script always builds inno first, then innox86x64, then innox64,
    whatever order --installers lists them in. Building the win64 cross
    compiler starts with "rtlclean rtl" for the source platform, so it rebuilds
    the win32 rtl and leaves the win32 packages as they were. An installer that
    picks up win32 units after that point carries an rtl and packages that were
    compiled against different unit checksums, and the first compilation on the
    user's machine fails with

        Recompiling Variants, checksum changed for ...\rtl\sysutils.ppu
        Fatal: Can't find unit Variants used by fpjson

    inno and innox86x64 install win32 units, innox64 installs only win64 units,
    so that order keeps every installer self consistent.

The build runs without -j: the GNU make 3.82 that ships in install/binw32 has
no working jobserver on Windows. This is the slowest part of the run.

The inno rules call rmcvsdir.exe, fpcmkcfg and unzip without a path, so the
script gathers the freshly built utilities in build/winbin and puts that
directory on the Windows PATH.

The tree gets its own drive letter in the wine prefix.

    wine maps Z: to the root of the file system. The root is a mount point, so
    wine looks for the label and the serial number of that volume in the block
    device the root is mounted from, and a normal user may not read that
    device. Every program that asks for the volume information of a path on Z:
    then produces

        wine: Read access denied for device L"\??\Z:\", FS volume label and
        serial are not available.

    make.exe asks at every start, so a build that runs on Z: prints thousands
    of these lines. A drive that points at a plain directory instead of at a
    mount point has no device and wine makes up a label and a serial for it.
    The script therefore links a free drive letter, t: if it is free, to the
    tree and lets the whole build run on that drive. The message is gone, and
    the paths in the build log are short.

    The drive list is read when the wine services start, so the script kills a
    running wineserver after it makes the link.
