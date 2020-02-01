Name: fpc
Version: %FPCVERSION%
Release: %RELEASE%

# Because this rpm is used on different systems, with different names
# of packages/dependencies. Do not add dependencies automatically.
AutoReqProv: no

ExclusiveArch: i386 i586 i686 ppc amd64 x86_64
License: GPL and modified LGPL
Group: Development/Languages
Source: %{name}-%{version}%VERSION_SUFFIX%-src.tar.gz
Summary: Free Pascal Compiler
Packager: Peter Vreman (peter@freepascal.org)
URL: http://www.freepascal.org/
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: fpc

%define fpcdir %{_libdir}/fpc/%{version}
%define docdir %{_docdir}/fpc-%{version}
%define exampledir %{docdir}/examples
%global debug_package %{nil}

%define fpcopt -k"--build-id"

%ifarch ppc
%define ppcname ppcppc
%else
%ifarch x86_64
%define ppcname ppcx64
%else
%ifarch amd64
%define ppcname amd64
%else
%define ppcname ppc386
%endif
%endif
%endif

%define buildbasedir %{buildroot}%{fpcdir}
%define builddocdir %{buildroot}%{docdir}
%define buildmandir %{buildroot}%{_mandir}
%define buildbindir %{buildroot}%{_bindir}
%define buildlibdir %{buildroot}%{_libdir}
%define buildexampledir %{buildroot}%{exampledir}

# The normal redhat rpm scripts does not recognize properly, what files to strip
# Hook our own strip command
%define __strip %{_builddir}/%{name}-%{version}/smart_strip.sh


%description
The Free Pascal Compiler is a Turbo Pascal 7.0 and Delphi compatible 32/64bit
Pascal Compiler. It comes with fully TP 7.0 compatible run-time library.
Some extensions are added to the language, like function overloading. Shared
libraries can be linked. Basic Delphi support is already implemented (classes,
exceptions,ansistrings,RTTI). This package contains commandline compiler and
utils. Provided units are the runtime library (RTL), free component library
(FCL), gtk,ncurses,zlib, mysql,postgres,ibase bindings.

###############################################################################
# fpc.rpm
#

%prep
%setup -c

%build
FPCDIR=
NEWPP=`pwd`/compiler/%{ppcname}
	make compiler_cycle OPT='%{fpcopt}'
	make rtl_clean rtl_smart FPC=${NEWPP} OPT='%{fpcopt}'
	make packages_smart FPC=${NEWPP} OPT='%{fpcopt}'
	make utils_all FPC=${NEWPP} OPT='%{fpcopt}'
if [ -z ${NODOCS} ]; then
	make -C fpcdocs pdf FPC=${NEWPP}
fi

%install
rm -rf %{buildroot}

FPCDIR=
NEWPP=`pwd`/compiler/%{ppcname}
INSTALLOPTS="FPC=${NEWPP} INSTALL_PREFIX=%{buildroot}/usr INSTALL_LIBDIR=%{buildlibdir} \
		INSTALL_DOCDIR=%{builddocdir} INSTALL_BINDIR=%{buildbindir} \
		INSTALL_EXAMPLEDIR=%{buildexampledir} INSTALL_BASEDIR=%{buildbasedir}"
	make compiler_distinstall ${INSTALLOPTS}
	make rtl_distinstall ${INSTALLOPTS}
	make packages_distinstall ${INSTALLOPTS}
	make utils_distinstall ${INSTALLOPTS}

	make -C demo sourceinstall ${INSTALLOPTS} INSTALL_SOURCEDIR=%{buildexampledir}
	make -C doc installdoc ${INSTALLOPTS}
	make -C man installman ${INSTALLOPTS} INSTALL_MANDIR=%{buildmandir}

if [ -z ${NODOCS} ]; then
	make -C fpcdocs pdfinstall ${INSTALLOPTS} INSTALL_DOCDIR=%{builddocdir}
fi

	# create link
	ln -sf %{fpcdir}/%{ppcname} %{buildroot}%{_bindir}/%{ppcname}

        # Workaround:
        # newer rpm versions do not allow garbage
        # delete lexyacc
        rm -rf %{buildroot}/usr/lib/fpc/lexyacc
if [ -n "${NODOCS}" ]; then
        # Also remove the examples when NODOCS is specified
	rm -rf %{buildexampledir}
fi


%clean
rm -rf %{buildroot}

%post
# Create a version independent config
%{fpcdir}/samplecfg %{_libdir}/fpc/\$fpcversion

%files
%defattr(-, root, root,-)
%{_bindir}/*
%{_libdir}/fpc
%{_libdir}/libpas2jslib.so
%dir %{docdir}
%doc %{docdir}/NEWS
%doc %{docdir}/README
%doc %{docdir}/faq*
%dir %{docdir}/ide
%doc %{docdir}/ide/readme.ide
%{_mandir}/*/*
