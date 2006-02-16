{
    This program is a remote test runner for wince

    Copyright (c) 2006 Free Pascal development team.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{
  Changes :

  02-16-2006 : orinaudo@gmail.com,  First release

}
program wcetrun;

{$mode objfpc}

uses
  Classes, SysUtils, windows;

var wsTestExeName,
    wsTestExtName : WideString;
    RPI           : PROCESS_INFORMATION;
    RSTARTUP      : STARTUPINFO;
    bError        : boolean;
    bExitCode     : Byte;
    lPos,
    lExitCode     : Longint;
    FileExit      : File of byte;
begin

  if Paramcount>0 then begin
   wsTestExeName:=ParamStr(1);
   writeln('wcerun - starting='+wsTestExeName);
   //create process
   FillByte(RSTARTUP,SizeOf(RSTARTUP),0);
   RSTARTUP.cb:=SizeOf(RSTARTUP);
   bError:=not CreateProcess(PWideChar(wsTestExeName), nil,nil,nil,FALSE, 0, nil, nil, @RSTARTUP, RPI );
   writeln('wcerun - waiting return');
   //wait end
   WaitForSingleObject(RPI.hProcess, INFINITE);
   writeln('wcerun - finished, get exit code');
   //get exitcode
   GetExitCodeProcess(RPI.hProcess, @lExitCode);
   writeln('wcerun - exitcode='+IntToStr(lExitCode));
   CloseHandle (RPI.hThread);
   CloseHandle (RPI.hProcess);
   //create file with exit code
   //change extension
   wsTestExtName:=ChangeFileExt(wsTestExeName,'.ext');

   if lExitCode<255
   then bExitCode:=lExitCode
   else bExitCode:=255;
   system.assign(FileExit,wsTestExtName);
   system.rewrite(FileExit);
   write(FileExit,bExitCode);
   system.Close(FileExit);

  end else writeln('wcterun - exiting no params');
end.

