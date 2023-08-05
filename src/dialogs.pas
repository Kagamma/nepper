unit Dialogs;

{$mode ObjFPC}

interface

uses
  Utils;

function ShowInputDialog(const Title: String40; var Output: String40): Boolean;
procedure ShowMessageDialog(const Title, Text: String40);
procedure ShowHelpDialog(const FileName: String40);

implementation

uses
  Screen, Keyboard, Input;

var
  HelpData: array[0..199] of String80;
  HelpAnchor: Integer = 0;
  HelpSize: Integer = 0;
  HelpFileNameOld: String80;

function ShowInputDialog(const Title: String40; var Output: String40): Boolean;
var
  OldInputCursor: Byte;
begin
  Result := False;
  OldInputCursor := InputCursor;
  InputCursor := 1;
  Screen.WriteText(20, 10, $3E, '', 40);
  Screen.WriteTextMid(40, 10, $3E, Title);
  Screen.WriteText(20, 11, $1F, '', 40);
  Screen.SetCursorPosition(20, 11);
  repeat
    Keyboard.WaitForInput;
    Input.InputText(Output, 40);
    Screen.WriteText(20, 11, $1F, Output, 40);
    case KBInput.ScanCode of
      SCAN_ESC:
        begin
          Break;
        end;
      SCAN_ENTER:
        begin
          Result := True;
          Break;
        end;
    end;
  until False;
  Screen.WriteText(20, 10, 0, '', 40);
  Screen.WriteText(20, 11, 0, '', 40);
  InputCursor := OldInputCursor;
  KBInput.ScanCode := $FF;
end;

procedure ShowMessageDialog(const Title, Text: String40);
begin
  Screen.WriteText(20, 10, $3E, '', 40);
  Screen.WriteText(20, 11, $30, '', 40);
  Screen.WriteText(20, 12, $30, '', 40);
  Screen.WriteText(20, 13, $30, '', 40);
  Screen.WriteTextMid(40, 10, $3E, Title);
  Screen.WriteTextMid(40, 12, $3F, Text);
  Keyboard.WaitForInput;
  Screen.WriteText(20, 10, 0, '', 40);
  Screen.WriteText(20, 11, 0, '', 40); 
  Screen.WriteText(20, 12, 0, '', 40);
  Screen.WriteText(20, 13, 0, '', 40);
  KBInput.ScanCode := $FF;
end;

procedure ShowHelpDialog(const FileName: String40);

  function ReadFile: Boolean;
  var
    F: Text;
    S: String80;
  begin
    if HelpFileNameOld = FileName then
    begin
      Exit(True);
    end;
    HelpFileNameOld := FileName;
    Result := False;
    Assign(F, FileName);
    {$I-}
    System.Reset(F);
    {$I+}
    if IOResult = 0 then
    begin
      HelpAnchor := 0;
      HelpSize := 0;
      while not EOF(F) do
      begin
        Readln(F, HelpData[HelpSize]);
        Inc(HelpSize);
        if HelpSize >= High(HelpData) then
          Break;
      end;
      Close(F);
      Result := True;
    end;
  end;

  procedure RenderAll;
  var
    I: Byte;
  begin
    FillWord(ScreenPointer[80], 80*24, $0F00);
    for I := HelpAnchor to HelpAnchor + 78 do
    begin
      if I > HelpSize - 1 then
        Break;
      WriteText(0, I - HelpAnchor + 1, $0F, HelpData[I]);
    end;
  end;

  procedure RenderScrollUp;
  var
    I: Byte;
  begin
    for I := 23 downto 1 do
      Move(ScreenPointer[I * 80], ScreenPointer[(I + 1) * 80], 160);
    WriteText(0, 1, $0F, HelpData[HelpAnchor], 80);
  end;

  procedure RenderScrollDown;
  begin
    Move(ScreenPointer[160], ScreenPointer[80], 80 * 23 * 2);
    WriteText(0, 24, $0F, HelpData[Min(HelpAnchor + 24, HelpSize - 1)], 80);
  end;

begin
  if not ReadFile then
  begin
    ShowMessageDialog('Error', '"' + FileName + '" not found!');
    Exit;
  end;
  RenderAll;
  repeat
    Keyboard.WaitForInput;
    case KBInput.ScanCode of
      SCAN_ESC, SCAN_F1:
        begin
          Break;
        end;
      SCAN_UP:
        begin 
          if HelpAnchor > 0 then
          begin
            Dec(HelpAnchor);
            RenderScrollUp;
          end;
        end;   
      SCAN_DOWN:
        begin
          if HelpSize - HelpAnchor > 25 then
          begin
            Inc(HelpAnchor);
            RenderScrollDown;
          end;
        end;
      SCAN_PGUP:
        begin
          Dec(HelpAnchor, 22);
          if HelpAnchor < 0 then
            HelpAnchor := 0;
          RenderAll;
        end;    
      SCAN_PGDN:
        begin
          Inc(HelpAnchor, 22);
          if HelpSize - HelpAnchor < 24 then
            HelpAnchor := HelpSize - 24;
          RenderAll;
        end;
    end;
  until False;
  KBInput.ScanCode := $FF;
  ClrScr;
end;

end.

