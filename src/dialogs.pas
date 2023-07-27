unit Dialogs;

{$mode ObjFPC}

interface

uses
  Utils;

function ShowInputDialog(const Title: String40; var Output: String40): Boolean;
procedure ShowMessageDialog(const Title, Text: String40);

implementation

uses
  Screen, Keyboard, Input;

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

end.

