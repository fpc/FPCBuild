set -e

makefatbinary()
{
  lipo "$1" "$2" -create -output "$2".fat
  rm "$1" "$2"
  mv "$2".fat "$2"
}

# Check parameters
if [ x"$1" == x ]; then
  usage
fi

if [ x"$2" == x ]; then
  usage
fi

if [ ! -x "$1"/ppcx64 ]; then
  echo Cannot find "$1"/ppcx64
  usage
fi

InstallBaseDir="$2"
if [ ! -d "$InstallBaseDir" ]; then
  mkdir -p "$InstallBaseDir" 2>/dev/null
  if [ ! -d "$InstallBaseDir" -o ! -x "$InstallBaseDir" -o ! -w "$InstallBaseDir" ]; then
    echo Target is not a directory or not writable
    usage
  fi
fi

NCPU=`sysctl -n hw.logicalcpu`

# Check that we're in an fpcbuild dir
if [ ! -f "$FPCBUILD"/fpcsrc/Makefile.fpc -o ! -f "$FPCBUILD"/fpcsrc/Makefile -o ! -d "$FPCBUILD"/fpcsrc/compiler -o ! -d "$FPCBUILD"/demo -o ! -d "$FPCBUILD"/install ]; then
  usage
fi

startdir=`pwd`

