#!/bin/bash
#
# Build the Free Pascal macOS installers from the staging trees that
# install/macosx/scripts/buildinstallx86release.sh produces.
# Copyright 1996-2026 the Free Pascal development team.
#
# Uses only tools that come with macOS: pkgbuild, productbuild and hdiutil.
# The Packages application and its .pkgproj files are not needed.
#
# See install/darwin/macos/README-automated.txt

set -e
set -o pipefail

BASEDIR=$(cd "$(dirname "$0")" && pwd)
PROGNAME=$(basename "$0")

# ---------------------------------------------------------------------------
# defaults
# ---------------------------------------------------------------------------

STAGEDIR=
OUTPUTDIR=$PWD
PRODUCTS=intelarm64,ppc,jvm,ios
SIGNID=
NOTARYPROFILE=
MAKEDMG=1
VERSION=

usage ()
{
  cat <<EOF
$PROGNAME - build the Free Pascal macOS installers

  --stage=<dir>         directory holding the staging trees x86, ppc, jvm and
                        ios, as written by buildinstallx86release.sh. Required.
  --products=<list>     comma separated, default $PRODUCTS
                        intelarm64  -> fpc-<ver>.intelarm64-macosx
                        ppc         -> fpc-<ver>.intel-macosx.cross.powerpc-macosx
                        jvm         -> fpc-<ver>.intel-macosx.cross.jvm
                        ios         -> fpc-<ver>.intel-macosx.cross.ios
  --version=<ver>       FPC version. Default: read from the staging tree.
  --output=<dir>        where the .pkg and .dmg files are put, default \$PWD
  --sign=<identity>     sign with this Developer ID Installer identity
  --notarize=<profile>  notarize with this notarytool keychain profile and
                        staple the result. Needs --sign.
  --no-dmg              write the .pkg files only
  --help                this text
EOF
}

log () { echo "$PROGNAME: $*" ; }
die () { echo "$PROGNAME: $*" >&2 ; exit 1 ; }

for a in "$@" ; do
  case "$a" in
    --stage=*)    STAGEDIR=${a#*=} ;;
    --products=*) PRODUCTS=${a#*=} ;;
    --version=*)  VERSION=${a#*=} ;;
    --output=*)   OUTPUTDIR=${a#*=} ;;
    --sign=*)     SIGNID=${a#*=} ;;
    --notarize=*) NOTARYPROFILE=${a#*=} ;;
    --no-dmg)     MAKEDMG= ;;
    --help|-h)    usage ; exit 0 ;;
    *)            usage ; die "unknown option $a" ;;
  esac
done

# ---------------------------------------------------------------------------
# checks
# ---------------------------------------------------------------------------

[ "$(uname -s)" = Darwin ] || die "this script builds macOS installers and needs macOS"
[ -n "$STAGEDIR" ] || { usage ; die "--stage is required" ; }
[ -d "$STAGEDIR" ] || die "--stage: $STAGEDIR is not a directory"
STAGEDIR=$(cd "$STAGEDIR" && pwd)

for t in pkgbuild productbuild hdiutil ; do
  command -v $t > /dev/null || die "$t not found, install the Xcode command line tools"
done
[ -z "$NOTARYPROFILE" ] || command -v xcrun > /dev/null || die "xcrun not found"
[ -z "$NOTARYPROFILE" ] || [ -n "$SIGNID" ] || die "--notarize needs --sign"

mkdir -p "$OUTPUTDIR"
OUTPUTDIR=$(cd "$OUTPUTDIR" && pwd)

# The version is the name of the directory under lib/fpc, so nothing has to be
# executed to find it.
if [ -z "$VERSION" ] ; then
  for d in x86 ppc jvm ios ; do
    [ -d "$STAGEDIR/$d/usr/local/lib/fpc" ] || continue
    VERSION=$(basename "$(ls -d "$STAGEDIR/$d/usr/local/lib/fpc"/*/ 2> /dev/null | head -1)")
    [ -n "$VERSION" ] && break
  done
fi
[ -n "$VERSION" ] || die "cannot work out the version, pass --version"
# 3.2.4 -> 324, as the identifiers of the earlier releases were built
VERSIONNODOTS=$(echo "$VERSION" | tr -d '.')
log "building the macOS installers for FPC $VERSION"

WORKDIR=$(mktemp -d -t fpcmacpkg)
trap 'rm -rf "$WORKDIR"' EXIT

# ---------------------------------------------------------------------------
# the products
#
# payload   the staging subdirectory, holding usr/ and Users/
# suffix    the tail of the package identifier, kept the same as the .pkgproj
#           files used, so that installer receipts stay recognisable
# name      the name of the .pkg and of the .dmg volume
# ---------------------------------------------------------------------------

product_payload () { case "$1" in
  intelarm64) echo x86 ;; ppc) echo ppc ;; jvm) echo jvm ;; ios) echo ios ;; esac ; }

product_suffix () { case "$1" in
  intelarm64) echo fpcinstintelarm64 ;; ppc) echo fpcinst386-ppc ;;
  jvm) echo fpcinst386-jvm ;; ios) echo fpcinstx86-ios ;; esac ; }

product_name () { case "$1" in
  intelarm64) echo "fpc-$VERSION.intelarm64-macosx" ;;
  ppc)        echo "fpc-$VERSION.intel-macosx.cross.powerpc-macosx" ;;
  jvm)        echo "fpc-$VERSION.intel-macosx.cross.jvm" ;;
  ios)        echo "fpc-$VERSION.intel-macosx.cross.ios" ;; esac ; }

product_title () { case "$1" in
  intelarm64) echo "Free Pascal Compiler $VERSION for Intel and ARM64 macOS" ;;
  ppc)        echo "Free Pascal Compiler $VERSION, PowerPC cross compiler" ;;
  jvm)        echo "Free Pascal Compiler $VERSION, JVM cross compiler" ;;
  ios)        echo "Free Pascal Compiler $VERSION, iOS cross compiler" ;; esac ; }

# ---------------------------------------------------------------------------
# the distribution script
#
# The Packages projects used an external shell script as an installation
# requirement, CommandLineToolsCheck. productbuild expects that check in
# JavaScript, so the same two file tests are written out here.
# ---------------------------------------------------------------------------

write_distribution ()
{
  local product=$1 pkgfile=$2 dest=$3
  local ident="org.freepascal.freePascalCompiler${VERSIONNODOTS}.$(product_suffix "$product")"
  cat > "$dest" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>$(product_title "$product")</title>
    <!-- No rootVolumeOnly and no <domains>, so the installer offers the
         "Select a Destination" step and the user can install on another
         volume, as the Packages projects did. RELOCATABLE was false there,
         so the location inside the volume stays /usr/local. -->
    <options customize="never" require-scripts="true"/>
    <license file="license.txt"/>
    <readme file="ReadMe.txt"/>
    <installation-check script="checkCommandLineTools()"/>
    <script><![CDATA[
function checkCommandLineTools()
{
    var v = system.version.ProductVersion.split('.');
    var haveTools;
    if (parseInt(v[0]) > 10 || (parseInt(v[0]) == 10 && parseInt(v[1]) > 13))
        haveTools = system.files.fileExistsAtPath('/Library/Developer/CommandLineTools/usr/bin/git');
    else
        haveTools = system.files.fileExistsAtPath('/usr/lib/crt1.o');
    if (!haveTools) {
        my.result.title = 'The Xcode command line tools are missing';
        my.result.message = 'You must install the Xcode command line tools BEFORE installing FPC, otherwise the generated FPC configuration file will be incomplete. For more information, see the pages linked from https://www.freepascal.org/down/i386/macosx.html';
        my.result.type = 'Fatal';
        return false;
    }
    return true;
}
]]></script>
    <pkg-ref id="$ident"/>
    <choices-outline>
        <line choice="default">
            <line choice="$ident"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$ident" visible="false">
        <pkg-ref id="$ident"/>
    </choice>
    <pkg-ref id="$ident" version="$VERSION" onConclusion="none">$(basename "$pkgfile")</pkg-ref>
</installer-gui-script>
EOF
}

# ---------------------------------------------------------------------------
# building one product
# ---------------------------------------------------------------------------

build_product ()
{
  local product=$1
  local payload="$STAGEDIR/$(product_payload "$product")"
  local name="$(product_name "$product")"
  local ident="org.freepascal.freePascalCompiler${VERSIONNODOTS}.$(product_suffix "$product")"

  [ -d "$payload" ] || { log "skipping $product, no $payload" ; return 0 ; }

  log "=== $product : $name ==="
  local w="$WORKDIR/$product"
  mkdir -p "$w/res"

  # The postinstall script is shared by all products and is taken as it is.
  mkdir -p "$w/scripts"
  cp "$BASEDIR/postinstall" "$w/scripts/postinstall"
  chmod 755 "$w/scripts/postinstall"

  # Resources shown by the installer.
  cp "$BASEDIR/license.txt" "$w/res/license.txt"
  cp "$BASEDIR/fpc-intel-macosx/ReadMe.txt" "$w/res/ReadMe.txt"

  # The component package. --ownership recommended makes the installer put the
  # files down as root:wheel; the staging tree belongs to the build user.
  pkgbuild --root "$payload" \
           --identifier "$ident" \
           --version "$VERSION" \
           --install-location / \
           --ownership recommended \
           --scripts "$w/scripts" \
           "$w/$name-component.pkg"

  # The product package, which is what the user double clicks.
  write_distribution "$product" "$w/$name-component.pkg" "$w/distribution.xml"
  productbuild --distribution "$w/distribution.xml" \
               --resources "$w/res" \
               --package-path "$w" \
               ${SIGNID:+--sign "$SIGNID"} \
               "$OUTPUTDIR/$name.pkg"

  if [ -n "$NOTARYPROFILE" ] ; then
    log "notarizing $name.pkg"
    xcrun notarytool submit "$OUTPUTDIR/$name.pkg" \
          --keychain-profile "$NOTARYPROFILE" --wait
    xcrun stapler staple "$OUTPUTDIR/$name.pkg"
  fi

  if [ -n "$MAKEDMG" ] ; then
    local dmgroot="$w/dmg/$name"
    mkdir -p "$dmgroot"
    mv "$OUTPUTDIR/$name.pkg" "$dmgroot/"
    cp "$BASEDIR/fpc-intel-macosx/ReadMe.txt" "$dmgroot/"
    cp "$BASEDIR/../../doc/whatsnew.txt" "$dmgroot/What's New.txt"
    # The getting started document lives in the payload of each product.
    find "$payload/Users/Shared/Free Pascal Compiler/Documentation" \
         -name "Getting Started*" -exec cp {} "$dmgroot/" \; 2> /dev/null || true
    rm -f "$OUTPUTDIR/$name.dmg"
    hdiutil create -ov -fs HFS+ -srcfolder "$dmgroot" -volname "$name" \
            -format UDZO "$OUTPUTDIR/$name.dmg"
  fi
}

for p in $(echo "$PRODUCTS" | tr ',' ' ') ; do
  case "$p" in
    intelarm64|ppc|jvm|ios) build_product "$p" ;;
    *) die "unknown product $p" ;;
  esac
done

log "done, in $OUTPUTDIR:"
ls -l "$OUTPUTDIR" | grep -E "\.pkg|\.dmg" || true
