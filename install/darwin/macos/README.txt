Project file and additional files for Packages tool, to package the Free Pascal Compiler.
The tool itself is available from:

http://s.sudre.free.fr/Software/Packages/about.html

license.txt - LGPL v2 is included here, because of the different line wrapping to the normal file.

welcome.rtf - First welcome screen of the installer

postinstall - Postinstall script

fpc-intel-macosx - Base project to start with the packaging.

fpc-intel-macosx/Developer/Documentation - placeholder directory for Documentation
fpc-intel-macosx/usr/local - placeholder directory for compiler files


After fixing version numbers and updating the required files, then placing the Documentation
and compiler files into the right directory, use:

"packagesbuild -v fpc-intel-macosx/fpc-intel-macosx.pkgproj"

to build the installer .pkg file. This command is part of the aforementioned Packages tool.
