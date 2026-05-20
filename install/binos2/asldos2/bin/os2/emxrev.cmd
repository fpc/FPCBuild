/* emxrev.cmd -- Display revision numbers of emx DLLs
   Copyright (c) 1993-1995 Eberhard Mattes

This file is part of emx.

emx is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

emx is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with emx; see the file COPYING.  If not, write to
the Free Software Foundation, 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.  */


  call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
  call SysLoadFuncs

  parse arg arg1 rest
  arg1 = strip( arg1, 'T')
  rest = strip( rest, 'T')
  select
  when arg1 = '' then do
    say revision( 'emx')
    say revision( 'emxio')
    say revision( 'emxlibc')
    say revision( 'emxlibcm')
    say revision( 'emxlibcs')
    say revision( 'emxwrap')
  end
  when arg1 = '-a' then do
    if rest \= '' then
      call usage
    call find_all
  end
  when arg1 = '-c' then do
    if (rest = '') | (words( rest) > 1) then
      call usage
    parse var rest drive':'rest
    if (length( drive) \= 1) | (rest \= '') then
      call usage
    call find_tree( drive':')
  end
  when arg1 = '-d' then do
    if (rest = '') | (words( rest) > 1) then
      call usage
    call find_dir rest, 'S'
  end
  when arg1 = '-f' then do
    if (rest = '') | (words( rest) > 1) then
      call usage
    say revision( rest)
  end
  when arg1 = '-p' then do
    if (rest = '') | (words( rest) > 1) then
      call usage
    call find_config rest
  end
  otherwise
    call usage
  end
  exit 0

usage:
  say 'Usage:'
  say '  emxrev           Display revision number of default emx DLLs'
  say '  emxrev -a        Scan all disks for emx DLLs'
  say '  emxrev -c d:     Scan complete drive D: for emx DLLs'
  say '  emxrev -d dir    Scan directory DIR for emx DLLs'
  say '  emxrev -f file   Display revision number of FILE'
  say '  emxrev -p file   Scan directories in LIBPATH statement of FILE'
  say ''
  say 'emx DLLs are emx.dll, emxio.dll, emxlibc.dll, emxlibcm.dll,'
  say '             emxlibcs.dll, and emxwrap.dll.'
exit 1

find_all: procedure
  drives = SysDriveMap()
  do i = 1 to words( drives)
    call find_tree( word( drives, i))
  end
  return

find_tree: procedure
  arg drive
  call find_dir drive'\', 'S'
  return

find_dir: procedure
  arg dir, opt
  last = right( dir, 1)
  if (last \= '/') & (last \= '\') & (last \= ':') then
    dir = dir'\'
  call SysFileTree dir'emx*.dll', files, 'FO'||opt
  do i = 1 to files.0
    name = translate( filespec( 'name', files.i))
    if (name = 'EMX.DLL') | (name = 'EMXIO.DLL') | (name = 'EMXLIBC.DLL'),
       | (name = 'EMXLIBCM.DLL') | (name = 'EMXLIBCS.DLL'),
       | (name = 'EMXWRAP.DLL') then
      say revision( files.i)
  end
  return
  
find_config: procedure
  arg config
  call SysFileSearch 'LIBPATH=', config, lines
  do i = 1 to lines.0
    parse var lines.i 'LIBPATH='rest
    list = translate( rest, ' ', ';')
    do j = 1 to words( list)
      call find_dir word( list, j), ''
    end
  end
  return

revision: procedure
  arg pathname
  call RxFuncAdd emx_revision, pathname, emx_revision
  signal on syntax name error
  tmp = emx_revision()
  signal off syntax
  call RxFuncDrop emx_revision
  return pathname ': revision =' tmp

error:
  return pathname ': revision number not available'
