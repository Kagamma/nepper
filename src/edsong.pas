unit EdSong;

{$mode ObjFPC}

interface

uses
  Adlib, Utils;

var
  IsSongPlaying: Boolean = False;

procedure Loop;

implementation

uses
  Input, Keyboard, Screen, Formats;

var
  IsEditSongName: Boolean = False;
  PatternIndex: Byte = 0;

procedure RenderTexts;
begin
  WriteText(0, 0, $1A, 'SONG EDIT   ');
  WriteText(0, 23, $0A, '[TAB] Pattern   [INS] Ins Pos. [L] Load [<] Add Chan.', 80);
  WriteText(0, 24, $0A, '[SPC] Play/Stop [DEL] Del Pos. [S] Save [>] Sub Chan.', 80);
end;

procedure RenderSongInfo;
var
  I: Byte;
  S: String2;
begin
  WriteText(10, 5, $0F, '', 40);
  for I := 0 to High(NepperRec.PatternIndices) do
  begin
    S := HexStr(NepperRec.PatternIndices[I], 2);
    WriteText(10 + 3 * I, 7, $0F, S, 47);
  end;
end;

procedure LoopEditSongName;
begin
  Input.InputText(NepperRec.Name, 40);
  WriteText(10, 5, $0F, NepperRec.Name);
  case KBInput.ScanCode of
    SCAN_DOWN:
      begin
        IsEditSongName := False;
        Screen.SetCursorPosition(10, 7);
        Input.InputCursor := 1;
        PatternIndex := 0;
      end;
  end;
end;

procedure LoopEditSheet;
var
  S: String;
begin
  Input.InputHex2(S, NepperRec.PatternIndices[PatternIndex], $1F);
  case NepperRec.PatternIndices[PatternIndex] of
    $FE:
      WriteText(10 + PatternIndex * 3, 7, $0F, 'R', 2);
    $FF:
      WriteText(10 + PatternIndex * 3, 7, $0F, 'H', 2);
    else
      WriteText(10 + PatternIndex * 3, 7, $0F, S);
  end;
  if KBInput.ScanCode < $FE then
    case KBInput.ScanCode of
      SCAN_UP:
        begin
          IsEditSongName := True;
          Screen.SetCursorPosition(10, 5);
          Input.InputCursor := 1;
        end;
      SCAN_LEFT:
        begin
          if PatternIndex > 0 then
          begin
            Dec(PatternIndex);
            Screen.SetCursorPosition(10 + PatternIndex * 3, 7);
            Input.InputCursor := 1;
          end;
        end;
      SCAN_RIGHT:
        begin
          if PatternIndex < High(NepperRec.PatternIndices) then
          begin
            Inc(PatternIndex);
            Screen.SetCursorPosition(10 + PatternIndex * 3, 7);
            Input.InputCursor := 1;
          end;
        end;
      else
        case KBInput.CharCode of
          'h':
            begin
              NepperRec.PatternIndices[PatternIndex] := $FF;
              WriteText(10 + PatternIndex * 3, 7, $0F, 'H', 2);
            end;
          'r':
            begin
              NepperRec.PatternIndices[PatternIndex] := $FE;
              WriteText(10 + PatternIndex * 3, 7, $0F, 'R', 2);
            end;
        end;
    end;
end;

procedure Loop;
begin
  RenderTexts;
  RenderSongInfo;
  Screen.SetCursorPosition(10, 7);
  PatternIndex := 0;
  IsEditSongName := False;
  repeat
    Keyboard.WaitForInput;

    if IsEditSongName then
      LoopEditSongName
    else
      LoopEditSheet;
  until (KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F2) or (KBInput.ScanCode = SCAN_TAB);
end;

end.

