Name: fpc-i8086-msdos
Version: 3.2.0
Release: 0.rc1

# Because this rpm is used on different systems, with different names
# of packages/dependencies. Do not add dependencies automatically.
AutoReqProv: no

ExclusiveArch: i386 i586 i686 ppc amd64 x86_64
License: GPL and modified LGPL
Group: Development/Languages
Source0: fpcbuild-%{version}rc1.tar.gz
Source1: make-i8086-msdos-unixpackage-%{version}rc1.sh
Patch0: fpcbuild-3.2.0rc1-nowatcom.diff
Summary: Free Pascal Compiler for i8086-msdos
Packager: Nikolay Nikolov (nickysn@users.sourceforge.net)
URL: http://www.freepascal.org/
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: fpc
Requires: fpc

%define fpcbuildsubdir fpcbuild-%{version}rc1

%define ppcname ppcross8086

# The normal redhat rpm scripts does not recognize properly, what files to strip
# Hook our own strip command
#%define __strip %{_builddir}/%{name}-%{version}/smart_strip.sh


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

%global debug_package %{nil}

%prep
%setup -c
%patch0 -p0
cp -p %SOURCE1 %{fpcbuildsubdir}

%build

cd %{fpcbuildsubdir}
./make-i8086-msdos-unixpackage-%{version}rc1.sh

%install
rm -rf %{buildroot}

install -d %{buildroot}%{_bindir}
install -d %{buildroot}%{_libdir}
cp -p -r %{_builddir}/%{buildsubdir}/%{fpcbuildsubdir}/OUTPUT-MSDOS/lib/fpc %{buildroot}%{_libdir}
ln -sf %{_libdir}/fpc/%{version}/%{ppcname} %{buildroot}%{_bindir}/%{ppcname}

%clean
rm -rf %{buildroot}

%post

%files
%defattr(-, root, root,-)
%{_bindir}/*
%{_libdir}/fpc
