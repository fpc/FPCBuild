Building Linux distribution packages with nfpm
==============================================

This directory contains the description of the .deb and .rpm packages that the
Free Pascal team distributes itself. The packages are written by nfpm, which
needs no dpkg and no rpmbuild on the build machine:

    https://nfpm.goreleaser.com/

The .tar installation (install/makepack and install/install.sh) and the Debian
archive packaging (install/debian) are not built from these files. They keep
their own build path.


How it works
------------

Everything is derived from one staging directory, which is a normal FPC
installation with /usr as prefix:

    make build          build the compiler and the packages, as always
    make nfpmstage      "make install" into build/nfpm/stage
    make nfpm           write the packages from build/nfpm/stage

The staging step is a plain file copy, so it costs no compilation time and it
does not disturb the .tar.gz archives that makepack uses.


Targets
-------

    nfpmstage       prepare build/nfpm/stage and the maintainer scripts
    nfpm            write the fpc package
    nfpmsrc         write the fpc-src package (sources)
    nfpmdocs        write the fpc-docs package (needs doc-pdf.tar.gz)
    nfpmall         all three
    nfpmclean       remove build/nfpm

Variables:

    NFPMFORMATS     formats to write, default "deb rpm".
                    Other possibilities: apk archlinux ipk
    NFPMRELEASE     package release number, default 1
    NFPMOUTDIR      where the packages are written, default the toplevel dir
    NFPM            full path of the nfpm program

Example:

    make nfpmall NFPMFORMATS="deb rpm apk" NFPMRELEASE=2


Files
-----

    fpc.yaml            the compiler, the units and the utilities
    fpc-src.yaml        the sources
    fpc-docs.yaml       the PDF documentation and the examples
    postinstall.sh.in   runs samplecfg after installation
    postremove.sh.in    removes the generated configuration on purge

The .in files are copied to build/nfpm/scripts with @FPCVERSION@ replaced.

The paths in the .yaml files are relative because nfpm resolves them against
the directory it is started in, and does not expand environment variables in
them. The version, the release and the architecture are passed in the
environment, which nfpm does expand.


Version numbers
---------------

The version is taken from Makefile.fpc as it is, including a suffix such as
-rc1. The "version_schema: semver" line lets nfpm write it in the way each
format expects:

    3.2.4-rc1   ->  fpc_3.2.4~rc1-1_amd64.deb
                    fpc-3.2.4~rc1-1.x86_64.rpm

Both dpkg and rpm sort 3.2.4~rc1 before 3.2.4.
