#!/bin/bash
#
# Build the Free Pascal Windows installers on a Linux machine, using wine.
# Copyright 1996-2026 the Free Pascal development team.
#
# The compiler, the run time library and the packages are built by a windows
# compiler running under wine, so the installation tree gets the windows layout
# and the build is a normal native windows build. Only the starting compiler
# comes from elsewhere: a released 3.2.2 windows compiler, as fpcsrc/Makefile.fpc
# asks for in REQUIREDVERSION.
#
# See install/wine/README.txt for the details.

set -e
set -o pipefail

BASEDIR=$(cd "$(dirname "$0")/../.." && pwd)
PROGNAME=$(basename "$0")

# ---------------------------------------------------------------------------
# defaults
# ---------------------------------------------------------------------------

INSTALLERS=win32,win64cross,combined
INNO=
INNOCACHE=${XDG_CACHE_HOME:-$HOME/.cache}/fpc-wine
OUTPUTDIR=$BASEDIR
FPC322=
STARTCOMPILER=
NODOCS=
KEEPPREFIX=
USEPREFIX=

# Inno Setup 6.7.3. The 6.x installers live on github, the 5.x ones on
# files.jrsoftware.org.
INNO_URL=https://github.com/jrsoftware/issrc/releases/download/is-6_7_3/innosetup-6.7.3.exe
INNO_SHA256=9c73c3bae7ed48d44112a0f48e66742c00090bdb5bef71d9d3c056c66e97b732

# The released windows compiler used as starting compiler.
FPC322_URL=https://downloads.freepascal.org/fpc/dist/3.2.2/i386-win32/fpc-3.2.2.i386-win32.exe
FPC322_SHA256=7ec78b1790ecac7685f440b17f9e03865bc09846b7c068a9270c4d37704b5ac8

usage ()
{
  cat <<EOF
$PROGNAME - build the Free Pascal windows installers on linux with wine

  --installers=<list>   comma separated, default $INSTALLERS
                        win32       -> fpc-<ver>.i386-win32.exe
                        win64cross  -> fpc-<ver>.i386-win32.cross.x86_64-win64.exe
                        combined    -> fpc-<ver>.win32.and.win64.exe
  --inno=<what>         inno setup: a directory holding ISCC.exe, an installer,
                        or a url. Default: download $INNO_URL
  --inno-cache=<dir>    where downloads are kept, default $INNOCACHE
  --fpc322=<what>       starting compiler: a windows installer, or a url.
                        Default: download from downloads.freepascal.org
  --start-compiler=<f>  use this ppc386.exe as starting compiler and install
                        no released compiler at all
  --output=<dir>        where the installers are put, default the tree root
  --nodocs              build without documentation, doc-chm.zip not needed
  --prefix=<dir>        use this wine prefix instead of a temporary one
  --keep                do not remove the temporary wine prefix
  --help                this text

The tree is at $BASEDIR
EOF
}

log ()  { echo "$PROGNAME: $*" ; }
die ()  { echo "$PROGNAME: $*" >&2 ; exit 1 ; }

# ---------------------------------------------------------------------------
# command line
# ---------------------------------------------------------------------------

for a in "$@" ; do
  case "$a" in
    --installers=*)     INSTALLERS=${a#*=} ;;
    --inno=*)           INNO=${a#*=} ;;
    --inno-cache=*)     INNOCACHE=${a#*=} ;;
    --fpc322=*)         FPC322=${a#*=} ;;
    --start-compiler=*) STARTCOMPILER=${a#*=} ;;
    --output=*)         OUTPUTDIR=${a#*=} ;;
    --nodocs)           NODOCS=1 ;;
    --prefix=*)         USEPREFIX=${a#*=} ;;
    --keep)             KEEPPREFIX=1 ;;
    --help|-h)          usage ; exit 0 ;;
    *)                  usage ; die "unknown option $a" ;;
  esac
done

case ",$INSTALLERS," in
  *,win32,*|*,win64cross,*|*,combined,*) ;;
  *) die "--installers needs at least one of win32, win64cross, combined" ;;
esac

# ---------------------------------------------------------------------------
# checks
# ---------------------------------------------------------------------------

command -v wine    > /dev/null || die "wine not found"
command -v curl    > /dev/null || die "curl not found"
command -v unzip   > /dev/null || die "unzip not found"
[ -f "$BASEDIR/install/binw32/make.exe" ] || die "$BASEDIR/install/binw32/make.exe not found"
[ -f "$BASEDIR/Makefile" ] || die "no Makefile in $BASEDIR"

if [ -z "$NODOCS" ] && [ ! -f "$BASEDIR/doc-chm.zip" ] ; then
  die "doc-chm.zip not found in $BASEDIR.
    The chm documentation is required, not built, in the same way makepack
    requires doc-pdf.tar.gz. Put the file in the tree root, or pass --nodocs."
fi

mkdir -p "$OUTPUTDIR" "$INNOCACHE"
OUTPUTDIR=$(cd "$OUTPUTDIR" && pwd)

# The GNU fileutils in install/binw32 are from 1996 and lowercase every
# absolute path they are given. On Windows that does not matter, on a case
# sensitive file system it means rm.exe and ginstall.exe quietly do nothing,
# and report success, as soon as the path of the tree contains an uppercase
# letter. Everything is therefore driven through an all lowercase symlink.
WORKBASE=$BASEDIR
WORKLINK=
case "$BASEDIR" in
  *[A-Z]*)
    WORKLINK=/tmp/fpcwine-tree.$$
    ln -sfn "$BASEDIR" "$WORKLINK"
    WORKBASE=$WORKLINK
    log "the path of the tree has uppercase letters, building through $WORKLINK" ;;
esac

PACKAGEVERSION=$(sed -n 's/^version *= *//p' "$BASEDIR/Makefile.fpc" | head -1)
[ -n "$PACKAGEVERSION" ] || die "cannot read the version from Makefile.fpc"
log "building the windows installers for FPC $PACKAGEVERSION"

# ---------------------------------------------------------------------------
# wine environment
# ---------------------------------------------------------------------------

export WINEARCH=win64
export WINEDEBUG=${WINEDEBUG:--all}
# wineserver needs a writable runtime directory
if [ -z "$XDG_RUNTIME_DIR" ] || [ ! -w "$XDG_RUNTIME_DIR" ] ; then
  XDG_RUNTIME_DIR=$(mktemp -d)
  export XDG_RUNTIME_DIR
fi

if [ -n "$USEPREFIX" ] ; then
  export WINEPREFIX=$USEPREFIX
  KEEPPREFIX=1
  WORKDIR=
else
  WORKDIR=$(mktemp -d -t fpcwine.XXXXXX)
  export WINEPREFIX=$WORKDIR/wine
fi

cleanup ()
{
  local rc=$?
  wineserver -k 2> /dev/null || true
  [ -z "$WORKLINK" ] || rm -f "$WORKLINK"
  if [ -z "$KEEPPREFIX" ] && [ -n "$WORKDIR" ] ; then
    rm -rf "$WORKDIR"
  elif [ -n "$WORKDIR" ] ; then
    log "wine prefix kept at $WINEPREFIX"
  fi
  exit $rc
}
trap cleanup EXIT

if [ ! -d "$WINEPREFIX" ] ; then
  log "creating the wine prefix in $WINEPREFIX"
  wineboot -u > /dev/null 2>&1
  # no gecko and mono dialogs
  wine reg add 'HKCU\Software\Wine\DllOverrides' /v mscoree /d disabled /f > /dev/null 2>&1
  wine reg add 'HKCU\Software\Wine\DllOverrides' /v mshtml  /d disabled /f > /dev/null 2>&1
fi

# ---------------------------------------------------------------------------
# the drive letter of the tree
# ---------------------------------------------------------------------------

# Z: is mapped to the root of the file system, which is a mount point, so wine
# looks for the label and the serial number of that volume in the block device
# the root is mounted from. A normal user may not read that device, and wine
# says so for every program that asks for the volume information of a path on
# Z:, make.exe among them:
#
#     wine: Read access denied for device L"\??\Z:\", FS volume label and
#     serial are not available.
#
# A drive that points at a plain directory instead of at a mount point has no
# device, and wine makes up a label and a serial for it. Giving the tree its
# own drive letter therefore keeps the whole build off Z: and the message away.
TREEDRIVE=
TREEREAL=$(readlink -f "$WORKBASE")
for d in "$WINEPREFIX"/dosdevices/[c-y]: ; do
  [ -L "$d" ] || continue
  # a drive left behind by an earlier run through a lowercase symlink
  if [ ! -e "$d" ] ; then
    case "$(readlink "$d")" in /tmp/fpcwine-tree.*) rm -f "$d" ;; esac
    continue
  fi
  [ "$(readlink -f "$d")" = "$TREEREAL" ] || continue
  TREEDRIVE=$(basename "$d")
  break
done
if [ -z "$TREEDRIVE" ] ; then
  for l in t u v w x y e f g h i j k l m n o p q r s ; do
    # a letter with a device link is a real disk or a cdrom, leave it alone
    [ ! -e "$WINEPREFIX/dosdevices/$l::" ] && [ ! -L "$WINEPREFIX/dosdevices/$l::" ] || continue
    [ ! -e "$WINEPREFIX/dosdevices/$l:" ] && [ ! -L "$WINEPREFIX/dosdevices/$l:" ] || continue
    ln -sfn "$WORKBASE" "$WINEPREFIX/dosdevices/$l:"
    TREEDRIVE=$l:
    break
  done
fi
if [ -n "$TREEDRIVE" ] ; then
  log "the tree is drive $TREEDRIVE in the wine prefix"
else
  log "warning: no free drive letter in the prefix, the build runs on Z: and"
  log "         wine prints a read access denied message for every program"
fi
# the drives are read when the wine services start, so a server that is already
# running does not know the new letter yet
wineserver -k 2> /dev/null || true

# ---------------------------------------------------------------------------
# fetching
# ---------------------------------------------------------------------------

# fetch <url> <destination> <expected sha256, may be empty>
fetch ()
{
  local url=$1 dest=$2 want=$3 got=
  if [ ! -s "$dest" ] ; then
    log "downloading $url"
    curl -fsS -L --retry 3 --max-time 1800 -o "$dest.part" "$url" || {
      rm -f "$dest.part"
      die "could not download $url
    Pass a local file or another url with the matching option."
    }
    mv "$dest.part" "$dest"
  else
    log "using the cached $(basename "$dest")"
  fi
  got=$(sha256sum "$dest" | cut -d' ' -f1)
  if [ -n "$want" ] && [ "$want" != "$got" ] ; then
    rm -f "$dest"
    die "checksum mismatch for $(basename "$dest"): expected $want, got $got"
  fi
  [ -n "$want" ] || log "sha256 $(basename "$dest") = $got"
}

# install a silent inno setup based installer into the prefix, unless the
# program named in the third argument is already there
innoinstall ()
{
  local installer=$1 dir=$2 check=$3
  if [ -n "$check" ] && [ -f "$check" ] ; then
    log "$(basename "$check") is already in the prefix, not installing again"
    return 0
  fi
  log "installing $(basename "$installer") into $dir"
  wine "$installer" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR="$dir" > /dev/null 2>&1
}

# ---------------------------------------------------------------------------
# inno setup
# ---------------------------------------------------------------------------

ISCCDIR=
case "$INNO" in
  "")
    fetch "$INNO_URL" "$INNOCACHE/innosetup.exe" "$INNO_SHA256"
    innoinstall "$INNOCACHE/innosetup.exe" 'C:\innosetup' "$WINEPREFIX/drive_c/innosetup/ISCC.exe"
    ISCCDIR='C:\innosetup' ;;
  http*|ftp*)
    fetch "$INNO" "$INNOCACHE/innosetup.exe" ""
    innoinstall "$INNOCACHE/innosetup.exe" 'C:\innosetup' "$WINEPREFIX/drive_c/innosetup/ISCC.exe"
    ISCCDIR='C:\innosetup' ;;
  *)
    if [ -d "$INNO" ] && [ -f "$INNO/ISCC.exe" ] ; then
      ISCCDIR=$(winepath -w "$INNO")
    elif [ -f "$INNO" ] ; then
      innoinstall "$INNO" 'C:\innosetup' "$WINEPREFIX/drive_c/innosetup/ISCC.exe"
      ISCCDIR='C:\innosetup'
    else
      die "--inno: not a directory with ISCC.exe, not a file, not a url: $INNO"
    fi ;;
esac

ISCCPROG="$ISCCDIR\\ISCC.exe"
[ -f "$WINEPREFIX/drive_c/innosetup/ISCC.exe" ] || [ -n "$INNO" ] || \
  die "inno setup did not install, no ISCC.exe in the prefix"
log "using $ISCCPROG"

# ---------------------------------------------------------------------------
# starting compiler
# ---------------------------------------------------------------------------

STARTBIN=
if [ -n "$STARTCOMPILER" ] ; then
  [ -f "$STARTCOMPILER" ] || die "--start-compiler: $STARTCOMPILER not found"
  mkdir -p "$WINEPREFIX/drive_c/startfpc"
  cp "$STARTCOMPILER" "$WINEPREFIX/drive_c/startfpc/ppc386.exe"
  STARTDIR='C:\startfpc'
else
  case "$FPC322" in
    "")     fetch "$FPC322_URL" "$INNOCACHE/fpc-3.2.2.i386-win32.exe" "$FPC322_SHA256"
            STARTINST=$INNOCACHE/fpc-3.2.2.i386-win32.exe ;;
    http*)  fetch "$FPC322" "$INNOCACHE/fpc-3.2.2.i386-win32.exe" ""
            STARTINST=$INNOCACHE/fpc-3.2.2.i386-win32.exe ;;
    *)      [ -f "$FPC322" ] || die "--fpc322: $FPC322 not found"
            STARTINST=$FPC322 ;;
  esac
  innoinstall "$STARTINST" 'C:\fpc322' "$WINEPREFIX/drive_c/fpc322/bin/i386-win32/ppc386.exe"
  STARTDIR='C:\fpc322\bin\i386-win32'
  [ -f "$WINEPREFIX/drive_c/fpc322/bin/i386-win32/ppc386.exe" ] || \
    die "the starting compiler did not install into $WINEPREFIX/drive_c/fpc322"
fi

# ---------------------------------------------------------------------------
# the windows PATH
# ---------------------------------------------------------------------------

WINBIN=$BASEDIR/build/winbin
mkdir -p "$WINBIN"
WINBIN_W=$(winepath -w "$WORKBASE/build/winbin")
BINW32_W=$(winepath -w "$WORKBASE/install/binw32")
export WINEPATH="$BINW32_W;$WINBIN_W;$STARTDIR"

# unzip 5.42 asks whether to overwrite when build/inno was left behind by an
# interrupted run, and there is nothing to answer with.
export UNZIP=-o

wmake ()
{
  ( cd "$WORKBASE" && wine "$WORKBASE/install/binw32/make.exe" "$@" )
}

STARTVERSION=$(cd "$WORKBASE" && wine "$STARTDIR\\ppc386.exe" -iV 2> /dev/null | tr -d '\r')
log "starting compiler: $STARTDIR\\ppc386.exe, version ${STARTVERSION:-unknown}"
case "$STARTVERSION" in
  3.2.2|3.2.0) OVERRIDE= ;;
  *) log "warning: $STARTVERSION is not the supported starting compiler version,"
     log "         adding OVERRIDEVERSIONCHECK=1"
     OVERRIDE=OVERRIDEVERSIONCHECK=1 ;;
esac

MAKEARGS=(FPC=ppc386.exe "ISCCPROG=$ISCCPROG")
[ -z "$OVERRIDE" ] || MAKEARGS+=("$OVERRIDE")
[ -z "$NODOCS" ]   || MAKEARGS+=(NODOCS=1)

# ---------------------------------------------------------------------------
# build
# ---------------------------------------------------------------------------

log "building the win32 compiler, rtl, packages and utilities under wine"
log "this is the long part, it runs without -j because make 3.82 for windows"
log "has no working jobserver"
wmake build "${MAKEARGS[@]}"

# The inno rules call rmcvsdir.exe, fpcmkcfg and unzip without a path, so the
# freshly built utilities have to be reachable through the windows PATH.
log "collecting the built utilities in $WINBIN"
find "$BASEDIR/fpcsrc" -path "*/bin/i386-win32/*.exe" -type f -exec cp -f {} "$WINBIN/" \;
cp -f "$BASEDIR/fpcsrc/compiler/ppc386.exe" "$WINBIN/" 2> /dev/null || true
ls "$WINBIN" | head -20 | while read -r f ; do echo "    $f" ; done

# ---------------------------------------------------------------------------
# the installers
# ---------------------------------------------------------------------------

# The order is fixed and does not follow the order of --installers.
#
# Building the win64 cross compiler starts with "rtlclean rtl" for the source
# platform, so it rebuilds the win32 rtl while the win32 packages stay as they
# were. Everything that installs win32 units has to run before that happens,
# otherwise the installer ships an rtl and a set of packages that were compiled
# against different unit checksums, and the first compilation on the user's
# machine fails with "Can't find unit Variants used by fpjson".
#
# inno installs win32 units, innox86x64 installs win32 units and then builds
# the cross compiler, innox64 installs only win64 units. 
# Hence: inno, innox86x64, innox64.
built=
case ",$INSTALLERS," in *,win32,*)
  log "=== make inno (win32) ==="
  wmake inno "${MAKEARGS[@]}"
  built="$built inno" ;;
esac
case ",$INSTALLERS," in *,combined,*)
  log "=== make innox86x64 (win32 and win64 in one installer) ==="
  wmake innox86x64 "${MAKEARGS[@]}"
  built="$built innox86x64" ;;
esac
case ",$INSTALLERS," in *,win64cross,*)
  log "=== make innox64 (win32 hosted cross compiler to win64) ==="
  wmake innox64 "${MAKEARGS[@]}"
  built="$built innox64" ;;
esac

# ---------------------------------------------------------------------------
# results
# ---------------------------------------------------------------------------

shopt -s nullglob
found=("$BASEDIR"/fpc-"$PACKAGEVERSION"*.exe)
[ ${#found[@]} -gt 0 ] || die "the build finished but no installer was produced"
if [ "$OUTPUTDIR" != "$BASEDIR" ] ; then
  mv -f "${found[@]}" "$OUTPUTDIR/"
fi
log "done, built:$built"
for f in "${found[@]}" ; do
  b=$OUTPUTDIR/$(basename "$f")
  log "  $(basename "$b")  $(stat -c%s "$b") bytes"
done
