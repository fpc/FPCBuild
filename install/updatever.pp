//#!/usr/local/bin/instantfpc
program updatever;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes;

var
  VersionString: string;
  VersionParts: TStringList;
  VersionNr, ReleaseNr, PatchNr, MinorPatch: string;
  FileContent: TStringList;
  i: Integer;
  Line: string;

procedure ShowUsage;
  begin
    WriteLn('Usage: updatever <version_string>');
    WriteLn;
    WriteLn('Example: updatever 3.2.5-rc2');
    WriteLn;
    WriteLn('Version string format: major.minor.patch[-suffix]');
    Halt(1);
  end;

function ParseVersionString(const Version: string): Boolean;
  var
    MainPart, SuffixPart: string;
    DashPos: Integer;
  begin
    Result := False;
    MinorPatch := '';
    
    { Check for suffix (e.g., -rc1, -beta, etc.) }
    DashPos := Pos('-', Version);
    if DashPos > 0 then
      begin
        MainPart := Copy(Version, 1, DashPos - 1);
        SuffixPart := Copy(Version, DashPos+1, Length(Version));
        MinorPatch := SuffixPart;
      end
    else
      MainPart := Version;
    
    { Split main version parts }
    VersionParts.Delimiter := '.';
    VersionParts.StrictDelimiter := True;
    VersionParts.DelimitedText := MainPart;
    
    if VersionParts.Count <> 3 then
      begin
        WriteLn('Error: Version string must have exactly 3 parts (major.minor.patch)');
        Exit;
      end;
    
    VersionNr := VersionParts[0];
    ReleaseNr := VersionParts[1];
    PatchNr := VersionParts[2];
    
    Result := True;
  end;

function UpdateVersionLineVersionPas(const Line: string): string;
  begin
    Result := Line;
    
    if Pos('version_nr = ', Line) > 0 then
      Result := '       version_nr = ''' + VersionNr + ''';';
    
    if Pos('release_nr = ', Line) > 0 then
      Result := '       release_nr = ''' + ReleaseNr + ''';';
    
    if Pos('patch_nr   = ', Line) > 0 then
      Result := '       patch_nr   = ''' + PatchNr + ''';';
    
    if Pos('minorpatch = ', Line) > 0 then
      Result := '       minorpatch = ''-' + MinorPatch + ''';'
  end;


function UpdateVersionLineInstallPas(const Line: string): string;
  begin
    Result := Line;
    
    if Pos('installerversion=', Line) > 0 then
      begin
        Result := '     installerversion=''' + VersionNr + '.' + ReleaseNr + '.' + PatchNr;

        if MinorPatch<>'' then
          Result := Result + '-' + MinorPatch;

        Result:=Result + ''';';
      end;
  end;


function UpdateVersionLineReadme(const Line: string): string;
  begin
    Result := Line;
    
    if Pos('           Version ', Line) > 0 then
      begin
        Result := '     Version ' + VersionNr + '.' + ReleaseNr + '.' + PatchNr;

        if MinorPatch<>'' then
          Result := Result + '-' + MinorPatch;

      end;
  end;
  
function UpdateVersionLineFpcSty(const Line: string): string;
  begin
    Result := Line;
    
    if Pos('\newcommand{\fpcversion}{',Line) > 0 then
      begin
        Result := '\newcommand{\fpcversion}{'+VersionNr + '.' + ReleaseNr + '.' + PatchNr;
        if MinorPatch<>'' then
          Result := Result + '-' + MinorPatch;
        Result:=Result+'}';  

      end;
  end;



function UpdateVersionLineInstallDat(const Line: string): string;
  begin
    Result := Line;
    
    if Pos('title=Free Pascal Compiler', Line) > 0 then
      begin
        Result := 'title=Free Pascal Compiler ' + VersionNr + '.' + ReleaseNr + '.' + PatchNr;

        if MinorPatch<>'' then
          Result := Result + '-' + MinorPatch;
      end;

    if Pos('version=', Line) > 0 then
      begin
        Result := 'version=' + VersionNr + '.' + ReleaseNr + '.' + PatchNr;

        if MinorPatch<>'' then
          Result := Result + '-' + MinorPatch;
      end;
  end;


type
  TLineUpdater = function(const LIne: string): string;

procedure UpdateFile(const fn: string;LineUpdater: TLineUpdater);
  begin
    FileContent.LoadFromFile(fn);
    
    { Update version lines }
    for i := 0 to FileContent.Count - 1 do
      begin
        Line := FileContent[i];
        FileContent[i] := LineUpdater(Line);
      end;
    
    FileContent.SaveToFile(fn);
    writeln('Updated: ',fn)
  end;


begin
  if ParamCount <> 1 then
    ShowUsage;
  
  VersionString := ParamStr(1);
  
  VersionParts := TStringList.Create;
  FileContent := TStringList.Create;
  try
    if not ParseVersionString(VersionString) then
      Halt(1);
    
    WriteLn('Updating version to:');
    WriteLn('  version_nr: ', VersionNr);
    WriteLn('  release_nr: ', ReleaseNr);
    WriteLn('  patch_nr:   ', PatchNr);
    WriteLn('  minorpatch: ', MinorPatch);
    WriteLn;    

    UpdateFile('fpcsrc/installer/install.pas',@UpdateVersionLineInstallPas);

    UpdateFile('fpcsrc/installer/install.dat',@UpdateVersionLineInstallDat);

    UpdateFile('fpcsrc/compiler/version.pas',@UpdateVersionLineVersionPas);
    UpdateFile('install/doc/readme.txt',@UpdateVersionLineReadme);
    UpdateFile('fpcdocs/fpc.sty',@UpdateVersionLineFpcSty);
 finally
    VersionParts.Free;
    FileContent.Free;
  end;
end.
