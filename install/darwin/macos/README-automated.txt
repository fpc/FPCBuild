Building the macOS installers without the Packages application
==============================================================

makemacinstaller.sh builds the .pkg and .dmg files from the staging trees that
install/macosx/scripts/buildinstallx86release.sh writes. 

It uses only tools that come with macOS and the Xcode command line tools:

pkgbuild        builds the component package from a payload directory
productbuild    builds the installer the user double clicks
hdiutil         wraps it in a disk image

The Packages application and the four .pkgproj files are not used, the build
is fully automatable. 

Usage
-----

install/darwin/macos/makemacinstaller.sh --stage=/tmp/x86release

where /tmp/x86release is the destination that was given to
buildinstallx86release.sh, so that it holds

  x86/usr/local/...        and  x86/Users/Shared/Free Pascal Compiler/...
  ppc/usr/local/...        and  ppc/Users/...
  jvm/usr/local/...        and  jvm/Users/...
  ios/usr/local/...        and  ios/Users/...

A platform whose directory is missing is skipped, so a partial staging tree is
accepted.

Options:

  --stage=<dir>         required, see above
  --products=<list>     intelarm64, ppc, jvm, ios. Default: all four.
  --version=<ver>       default: the name of the directory under
                        <stage>/*/usr/local/lib/fpc
  --output=<dir>        where the results go, default the current directory
  --sign=<identity>     "Developer ID Installer: Name (TEAMID)"
  --notarize=<profile>  a notarytool keychain profile, implies stapling
  --no-dmg              write the .pkg files only


Compatibility with earlier installs
-----------------------------------

Package identifiers are kept exactly as the .pkgproj files had them, 
so that installer receipts on existing machines stay recognisable:

  org.freepascal.freePascalCompiler<version without dots>.<suffix>

  intelarm64  fpcinstintelarm64
  ppc         fpcinst386-ppc
  jvm         fpcinst386-jvm
  ios         fpcinstx86-ios

The payload is the whole staging subdirectory installed at /, which puts the
compiler under /usr/local and the documentation under
/Users/Shared/Free Pascal Compiler, as before.

postinstall is the script in this directory. It now removes a trailing slash
from the install destination and from the system root before building its
paths. Without that it only worked on the boot volume, where the destination is
"/"; on any other volume it looked for "/Volumes/Namusr/local/bin/fpc" and the
configuration file was never written.

The Packages projects ran CommandLineToolsCheck as an installation requirement.
productbuild wants that check in JavaScript instead of a shell script, so
makemacinstaller.sh writes the same two tests into the distribution file: 

on macOS newer than 10.13 it looks for
/Library/Developer/CommandLineTools/usr/bin/git,

on older systems for 
/usr/lib/crt1.o. 
The message shown is the one from the old project file.

One deliberate difference: pkgbuild is called with "--ownership recommended".
The staging tree belongs to whoever ran the build, and this makes the installer
put the files down as root:wheel instead.

Choosing where it goes
----------------------

The Packages projects had LOCATION 0 and RELOCATABLE set to "false" and set no domains,
which means the installer shows the "Select a Destination" step and the user can
install on another volume, while the location inside that volume is always
/usr/local. The distribution file written here does the same by setting neither
rootVolumeOnly nor <domains>.

macOS only shows that step when there is more than one eligible volume, so on a
machine with a single disk the installer goes straight on. That is how it
behaved before as well.

Signing
-------

The releases up to 3.2.2 are not signed: the xar table of contents of
fpc-3.2.2.intel-macosx.cross.jvm.pkg contains no signature at all. 
Users have to get past Gatekeeper by hand.

If you want to change that, --sign and --notarize do it:

./makemacinstaller.sh --stage=/tmp/x86release \
      --sign="Developer ID Installer: Your Name (TEAMID)" \
      --notarize=fpc-notary

The notarytool profile is created once with

xcrun notarytool store-credentials fpc-notary \
     --apple-id <id> --team-id <team> --password <app specific password>


Checking the result
-------------------

pkgutil --check-signature fpc-<ver>.intelarm64-macosx.pkg
pkgutil --expand fpc-<ver>.intelarm64-macosx.pkg /tmp/expanded
pkgutil --payload-files fpc-<ver>.intelarm64-macosx.pkg | head
spctl -a -vvv -t install fpc-<ver>.intelarm64-macosx.pkg   # only when signed

Install it on a machine or a virtual machine that has no FPC:

sudo installer -pkg fpc-<ver>.intelarm64-macosx.pkg -target /
  /usr/local/bin/fpc -iV
  ls -l /etc/fpc.cfg

and check that the ownership is right:

ls -l /usr/local/lib/fpc/<ver>/ppcx64      # root wheel

(This will differ from previous installs)
