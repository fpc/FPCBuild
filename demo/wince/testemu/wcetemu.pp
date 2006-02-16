{
    This program is a local test runner for win32

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
program wcetemu;

{$mode objfpc}

uses Sysutils, w32rapi, windows;


{* const **********************************************************************}

const
  SLOCALTESTEXEPATH = 'MysDisc:\My\Path\To\fpcsrc\tests\output\arm-wince\test\';
  SLOCALLOGPATHFILE = 'MysDisc:\My\Path\To\fpcsrc\tests\wcemtem.log';
  SREMOTEEXEPATH    = '\Storage Card\tests\';
  SREMOTERUNPROG    = 'wcetrun.exe';
  IBLOCKBUFFERSIZE  = 8192;
  ISEEKWAITTEMPOMS  = 1000;
  ISEEKRETRYMAX     = 100;

{* var ************************************************************************}
var flog             : Text;
    sTestExeName,
    sLocalTest,
    sRemoteTest,
    sRemoteProg      : String;
    lRes,
    lSeekFileCount   : Longint;
    bExitCode        : Byte;
    RBLOCKBUFFER     : Array[1..IBLOCKBUFFERSIZE] of Byte;
    bFileFound       : boolean;
    
{* log ************************************************************************}
procedure log(const csString: String);
begin
 system.writeln(flog,FormatDateTime('yy-mm-dd hh:nn:ss',Now)+' : '+csString);
 system.Flush(flog);
end;

{* sub RAPI *******************************************************************}
function remotecopyto( const csSource, csTarget : String): Longint;
var wsTarget        : WideString;
    lRes,
    lRead,
    lWritten,
    lRemoteExitCode : Longint;
    bError          : Boolean;
    hFileTarget     : HANDLE;
    AFileSource     : File of byte;

begin
 //create target file
 wsTarget:=csTarget;
 hFileTarget:=CeCreateFile( PWideChar(wsTarget), GENERIC_WRITE, 0, NIL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL,0);
 bError:=(hFileTarget=INVALID_HANDLE_VALUE);
 if bError then begin
  Result:=CEGetLastError;
  Log('error creating remote file "'+csTarget+'" ce('+IntToStr(CEGetLastError)+') rapi('+IntToStr(ceRapiGetError)+')');
 end else begin
  try
   //copy local file by block
   {$I-}
   AssignFile(AFileSource,csSource);
   system.FileMode := 0;
   system.Reset(AFileSource);
   {$I+}
   bError:=(system.ioresult>0);
   if bError then begin
    Log('error opening local file "'+csSource+'" ioresult='+IntToStr(system.ioresult));
    Result:=ioresult;
   end else begin
     try

       repeat
        {$I-}
        system.BlockRead( AFileSource, RBLOCKBUFFER, IBLOCKBUFFERSIZE, lRead);
        {$I+}
        bError:=ioresult>0;
        if bError then begin
          Log('error readblock local file "'+csTarget+'" toread='+IntToStr(IBLOCKBUFFERSIZE)+' read='+IntToStr(lRead));
          Result:=ioresult;
        end else begin
          bError:=not CeWriteFile( hFileTarget, @RBLOCKBUFFER,  lRead, @lWritten, nil);
          if (bError) or (lRead<>lWritten) then begin
            Log('error writing remote file "'+csTarget+'" ce(+'+IntToStr(CEGetLastError)+') written('+IntToStr(lWritten)+')');
            Result:=CEGetLastError;
          end;
        end;
       until (lRead<IBLOCKBUFFERSIZE) or (bError);
       if not bError then Result:=0;
     finally CloseFile(AFileSource);  end;
   end;
  finally CeCloseHandle(hFileTarget); end;
 end;
end;

function remoterun( const csApplication, csCmdLine : String): Longint;
var RPI           : PROCESS_INFORMATION;

    wsCmdLine,
    wsApplication : WideString;
    bError        : boolean;
begin
  wsApplication:=csApplication;
  wsCmdLine:=csCmdLine;

  bError:=not CeCreateProcess(PWideChar(wsApplication), PWideChar(wsCmdLine),nil,nil,FALSE, 0, nil, nil, nil, @RPI );
  Log('remote run "'+csApplication+' '+csCmdLine+'" exitcode='+IntToStr(CeGetLastError)+' bError='+BoolToStr(bError));
  if bError
  then Result:=CeGetLastError
  else begin
   CeCloseHandle (RPI.hThread);
   CeCloseHandle (RPI.hProcess);
   Result:=0;
  end;

end;

function remotedelete( const csTarget : String): Longint;
var wsTarget : WideString;
    bError   : boolean;
begin
  wsTarget:=csTarget;

  bError:=not CeDeleteFile(PWideChar(wsTarget));
  Log('remote delete "'+csTarget+'" exitcode='+IntToStr(CeGetLastError)+' bError='+BoolToStr(bError));
  if bError
  then Result:=CeGetLastError
  else Result:=0;

end;

function remotereadexitcode( const csRemote : String; var vbExitCode: Byte): Longint;
var wsRemote,
    wsExitCode      : WideString;
    lRead           : Longint;
    hFileRemote     : HANDLE;
    bError          : Boolean;
begin
 vbExitCode:=255;
 //create target file
   //change extention to .ext
 wsRemote:=ChangeFileExt(csRemote,'.ext');
 Sleep(ISEEKWAITTEMPOMS);
 hFileRemote:=CeCreateFile( PWideChar(wsRemote), GENERIC_READ, 0, NIL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_ATTRIBUTE_TEMPORARY,0);
 bError:=(hFileRemote=INVALID_HANDLE_VALUE);
 if bError then begin
  Result:=CEGetLastError;
  Log('error opening remote file "'+wsRemote+'" ce('+IntToStr(CEGetLastError)+') rapi('+IntToStr(ceRapiGetError)+')');
 end else begin
  try
   //read remote file
   bError:=not CeReadFile( hFileRemote, @RBLOCKBUFFER,  IBLOCKBUFFERSIZE, @lRead, nil);
   if (bError) then begin
    Log('error reading remote file "'+csRemote+'" ce(+'+IntToStr(CEGetLastError)+') read('+IntToStr(lRead)+')');
    Result:=CEGetLastError;
   end else begin
    Log('read '+IntToStr(lREad));
    vbExitCode:=RBLOCKBUFFER[1];
    Log('exit code read ='+IntToStr(vbExitCode));
    Result:=0;
   end;
  finally CeCloseHandle(hFileRemote); end;
 end;
end;

{******************************************************************************}

begin
 system.Assign(flog,SLOCALLOGPATHFILE);
 {$I-}
 system.Append(flog);
 {$I+}
 if (system.ioresult>0) then begin
  system.Rewrite(flog);
  log('log rewrite');
 end else log('log append');

 try
  if Paramcount>0 then begin

   //copy file
   sTestExeName:=ParamStr(1);
   log('remote copy "'+SLOCALTESTEXEPATH+sTestExeName+'" to "'+SREMOTEEXEPATH+sTestExeName+'"');
   lRes:=remotecopyto(SLOCALTESTEXEPATH+sTestExeName, SREMOTEEXEPATH+sTestExeName);
   if lRes=0
   then lRes:=remoterun(SREMOTEEXEPATH+SREMOTERUNPROG,'"'+SREMOTEEXEPATH+sTestExeName+'"');
   Sleep(ISEEKWAITTEMPOMS);
   //wait for test finished (waitforsingleobject and getexitcodprocess not available with rapi)
   //test finished when .exe can be remote deleted
   lSeekFileCount:=1;
   repeat

   log('sleeping '+IntToStr(ISEEKWAITTEMPOMS));
   Sleep(ISEEKWAITTEMPOMS);
   log('try remote delete "'+SREMOTEEXEPATH+sTestExeName+'"');
   if remotedelete(SREMOTEEXEPATH+sTestExeName)=0 then begin
    log('remote read exitcode"'+SREMOTEEXEPATH+sTestExeName+'"');
    lRes:=remotereadexitcode(SREMOTEEXEPATH+sTestExeName, bExitCode);
    bFileFound:=(lRes=0);
   end else begin
    bFileFound:=False;
    Inc(lSeekFileCount);
   end;
    
   until bFileFound or (lSeekFileCount>ISEEKRETRYMAX);

   if (not bFileFound) then begin
    log('* error no exitcode for "'+sTestExeName+'"');
    bExitCode:=255; //error code, not result file found
   end;

  end else log('exiting no params');
 finally log('log closed'); Close(flog); end;
 
 if bExitCode>0
 then Halt(bExitCode);
end.
