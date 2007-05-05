unit MainUnit;

interface

uses
	MacTypes;

procedure RunMainProcedure;


implementation

uses
	FPCMacOSAll;

{-------------------------------- }

procedure ShowExamples;
    var
        fontID  : Integer;
        sh      : StringHandle;
        ph      : PicHandle;
        r       : Rect;

begin
    MoveTo(7, 28);

    GetFNum('Helvetica', fontID);
    TextFont(fontID);
    TextSize(24);
    TextFace(bold);
    DrawString('Pascal Carbon example');

    MoveTo(  6, 36);
    LineTo(420, 36);

    sh := StringHandle(GetResource('STR ', 256));
    if sh <> nil then
    begin
        TextSize(12);
        TextFace(normal);
        MoveTo(6, 60);
        DrawString(sh^^);
    end;
    
    ph := PicHandle(GetResource('PICT', 256));
    if ph <> nil then
    begin
        r := ph^^.picFrame;
        OffsetRect(r, 60, 120);
        DrawPicture(ph, r);
    end;
end;

{-------------------------------- }

procedure RunMainProcedure;

    label
        CantCreateWindow,
        CantSetMenuBar,
        CantGetNibRef;

    var
        err     : OSStatus;
        nibRef  : IBNibRef;
        window  : WindowRef;

begin
    // Create a Nib reference passing the name of the nib file (without the .nib extension)
    // CreateNibReference only searches into the application bundle.
    err := CreateNibReference(CFSTR('main'), nibRef);
    if err <> noErr then
        goto CantGetNibRef;

    // Once the nib reference is created, set the menu bar. "MainMenu" is the name of the menu bar
    // object. This name is set in InterfaceBuilder when the nib is created.
    err := SetMenuBarFromNib(nibRef, CFSTR('MenuBar'));
    if err <> noErr then
        goto CantSetMenuBar;

    // Then create a window. "MainWindow" is the name of the window object. This name is set in 
    // InterfaceBuilder when the nib is created.
    err := CreateWindowFromNib(nibRef, CFSTR('MainWindow'), window);
    if err <> noErr then
        goto CantCreateWindow;

    // We don't need the nib reference anymore.
    DisposeNibReference(nibRef);

    // The window was created hidden so show it.
    ShowWindow(window);

    SetPort(GetWindowPort(window));
    ShowExamples;

    // Call the event loop
    RunApplicationEventLoop;

    // Error Handling
    CantCreateWindow:
    CantSetMenuBar:
    CantGetNibRef:
    Halt(byte(err));
end;

end.