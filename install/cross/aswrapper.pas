Program aswrapper;
{
    This file is part of the Free Pascal release engineering archives (fpcbuild)
    Copyright (c) 2010 by Marco van de Voort

    Simple pascal script that calls (g)as but allows to add a parameter.
    done by shellscripts on *nix, but compiler seems to search for arm-linux-as.EXE on Windows
    so we can't use batch.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}



{ as --help output for 2.20:
 ARM-specific assembler options:
  -k                      generate PIC code
  -mthumb                 assemble Thumb code
  -mthumb-interwork       support ARM/Thumb interworking
  -mapcs-32               code uses 32-bit program counter
  -mapcs-26               code uses 26-bit program counter
  -mapcs-float            floating point args are in fp regs
  -mapcs-reentrant        re-entrant code
  -matpcs                 code is ATPCS conformant
  -mbig-endian            assemble for big-endian
  -mlittle-endian         assemble for little-endian
  -mapcs-frame            use frame pointer
  -mapcs-stack-check      use stack size checking
  -mno-warn-deprecated    do not warn on use of deprecated feature
  -mcpu=<cpu name>        assemble for CPU <cpu name>
  -march=<arch name>      assemble for architecture <arch name>
  -mfpu=<fpu name>        assemble for FPU architecture <fpu name>
  -mfloat-abi=<abi>       assemble for floating point ABI <abi>
  -meabi=<ver>            assemble for eabi version <ver>
  -mimplicit-it=<mode>    controls implicit insertion of IT instructions
  -EB                     assemble code for a big-endian cpu
  -EL                     assemble code for a little-endian cpu
  --fix-v4bx              Allow BX in ARMv4 code
}

{$mode delphi}
uses sysutils;

var s,s2 : ansistring;
    I : integer;
begin
  s:=extractfilepath(paramstr(0))+'as-new.exe';
  s2:='-meabi=4';
  if paramcount>0 then
    begin
      for i:=1 to paramcount do
        s2:=s2+' '+paramstr(i);
    end;
  // this is a bit verbose, but since there is a chance on pathseparator issues, this might help problem searching
  writeln('executing "',s,'" with arguments "',s2,'"');

  // we must handle errors, and exit with errorlevel if something goes wrong
  // otherwise make/compiler will just go on without any .o files generated

  i:=0;
  try 
    i:=executeprocess(s,s2);
    halt(i);
  except
     on e:exception do 
      begin
        writeln(e.message);
        halt(1);
      end;
   end;
end.