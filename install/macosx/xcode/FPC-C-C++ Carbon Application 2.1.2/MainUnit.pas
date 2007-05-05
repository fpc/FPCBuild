unit MainUnit;

interface

uses
	MacTypes;

procedure RunMainProcedure;
	
procedure Message(msg: Str255);
procedure _Message(msg: Str255); C;

implementation

uses
	FPCMacOSAll, CSupport;

var
	gCurrentY: SInt16;
	
{-------------------------------- }

procedure RunMainProcedure;

label
	whenErr;
	
var
	err: OSStatus;
	nib: IBNibRef;
	win: WindowRef;
	str: Str255;
	fID: SInt16;
	val: SInt32;
	
begin

    // 1st the usual simple window and menubar from nib:
	
    err:= CreateNibReference(CFSTR('main'), nib);
    if err <> noErr then goto whenErr;

    err:= SetMenuBarFromNib(nib, CFSTR('MenuBar'));
    if err <> noErr then goto whenErr;

    err := CreateWindowFromNib(nib, CFSTR('MainWindow'), win);
    if err <> noErr then goto whenErr;

    DisposeNibReference(nib);

    ShowWindow(win);
    SetPort(GetWindowPort(win));
	
	// get 12 pt Geneva bold text:
	
	GetFNum('Geneva', fID);
	TextFont(fID);
	TextSize(12);
	TextFace(bold);

	// call Message directly:
	Message('FPC Carbon app with C/C++ support.');
	
	// call Message through external C:
	val:= CFunction;
	NumToString(val, str);
	Message('CFunction return val = ' + str);

	// do the same through external C++:
	val:= CPlusFunction;
	NumToString(val, str);
	Message('CPlusFunction return val = ' + str);

	Message('');
	Message('That''s all. You may as well quit now.');

	// event loop until quit
    RunApplicationEventLoop;

	Halt(0);
	
whenErr:	
    Halt(1);
end;

{-------------------------------- }

procedure Message(msg: Str255);
begin
	MoveTo(10, gCurrentY);
	DrawString(msg);
	gCurrentY:= gCurrentY + 24;
end;
	
{-------------------------------- }

procedure _Message(msg: Str255); C;
alias: '_Message';
begin Message(msg);
end;

begin
	gCurrentY:= 30;
end.