unit TestUnit;
interface
    uses
        FPCMacOSAll;

    procedure ShowExamples;
    
implementation

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
        DrawString('fpc204carbontempl');

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
    
end.
