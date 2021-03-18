#!/usr/bin/env bash

version=3.3.1

fpm_suffix="-go32v2.fpm"
fpmake_list=`find ../fpcsrc/ -name "fpmake.pp" `
go32v2_compiled_fpm=`find ../fpcsrc -name "*-go32v2.fpm" `

go32v2_package_list=""

set -u

for fpm_file in $go32v2_compiled_fpm ; do
  dir=`dirname $fpm_file`
  dirname=`basename $dir`
  updir=`dirname $dir`
  updirname=`basename $updir`
  filebase=`basename $fpm_file`
  package="${filebase/-go32v2.fpm/}"
  package_name=`sed -n  "s,.*Name *:= *'\(.*\)'.*,\1,p" $dir/fpmake.pp | head -1 `
  if [ -z "$package_name" ] ; then
    package_name=`sed -n  "s,.*AddPackage *( *'\(.*\)'.*,\1,p" $dir/fpmake.pp | head -1 `
  fi
  if [[ ( "$dirname" != "$package_name" ) && ( "$package_name" != "$updirname-$dirname" ) ]] ; then
    echo "$fpm_file with package_name=$package_name"
  fi
  package_short_name=`sed -n  "s,.*ShortName *:= *'\(.*\)'.*,\1,p" $dir/fpmake.pp | head -1 `
  go32v2_package_list+=" $updir=$package_name=$package_short_name "
done

function init_list ()
{
  ok_count=0
  pb_count=0
  ok_list=""
  pb_list=""
  whole_list=""
  total=0
}

function list_part ()
{
  part="$1"
  long_short_list=`sed -n "s:^package=\(.*\)\[\(.*$part.zip\)\].*:\1=\2:p" install.dat`
  for long_short in $long_short_list ; do
    echo "Checking $long_short"
    whole_list+=" $long_short "
    long=${long_short/=*/}
    long_with_version=${long/$part.zip/-$version-$part.zip}
    short=${long_short/*=/}
    echo "long=\"$long\", short=\"$short\""
    if [ -f "$short" ] ; then
      echo "Short file found, OK"
      let ok_count++
      ok_list+=" $short"
    elif [ -f "$long" ] ; then
      mv -fv "$long" "$short"
      let ok_count++
      ok_list+=" $short"
    elif [ -f "$long_with_version" ] ; then
      mv -fv "$long_with_version" "$short"
      let ok_count++
      ok_list+=" $short"
    elif [ -f "../$long" ] ; then
      cp -fp "../$long" "$short"
      let ok_count++
      ok_list+=" $short"
    else
      echo "$long and $short not found"
      let pb_count++
      pb_list+=" $short"
    fi
  done
  for zip in *$part.zip ; do
    pref=${zip/$part.zip/}
    grep_line=`grep -iwn "ShortName *:= *'$pref'"  $fpmake_list `
    if [ -z "$grep_line" ] ; then
      grep_line=`grep -iwn "Name *:= *'$pref'" $fpmake_list `
    fi
    if [ -z "$grep_line" ] ; then
      grep_line=`grep -iwn "AddPackage *('$pref'" $fpmake_list `
    fi
    if [ -z "$grep_line" ] ; then
      pref=${pref/#u/}
      grep_line=`grep -iwn "ShortName *:= *'$pref'" $fpmake_list `
    fi
    if [ -z "$grep_line" ] ; then
      echo "Prefix $pref not found in fpmake sources"
      continue
    fi
    if [ "${whole_list/=$zip /}" != "$whole_list" ] ; then
      echo "$zip is in short list"
    elif [ "${whole_list/ $zip=/}" != "$whole_list" ] ; then
      echo "$zip is in long list"
    elif [ "${go32v2_package_list/$pref/}" != "${go32v2_package_list}" ] ; then
      echo "$zip is not in install.dat, $grep_line"
      let pb_count++
      pb_list+=" &$zip&"
    fi
  done
}

echo "List of compiled packages for go32v2" > packages_dos.log
for f in $go32v2_package_list ; do
  echo "$f" >> packages_dos.log
done

init_list
list_part dos > list_dos.log
echo "dos part:"
let total=ok_count+pb_count
echo "OK: $ok_count/$total"
echo "Pb: $pb_count/$total"
echo "PB list: $pb_list"

init_list
list_part src > list_src.log
echo "src part:"
let total=ok_count+pb_count
echo "OK: $ok_count/$total"
echo "Pb: $pb_count/$total"
echo "PB list: $pb_list"


