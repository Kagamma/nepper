unit EdSong;

{$mode ObjFPC}

interface

uses
  Adlib, Utils;

var
  IsSongPlaying: Boolean = False;

procedure Loop;
procedure RenderSongInfo;

implementation

uses
  Input, Keyboard, Screen, Formats, EdPattern, Player, Dialogs;

var
  IsEditSongName: Boolean = False;
  PatternAnchor: Byte = 0;
  PatternIndex: Byte = 0;

procedure ResetParams;
begin
  IsEditSongName := False;
  Input.InputCursor := 1;
  Screen.SetCursorPosition(10 + (PatternIndex - PatternAnchor) * 3, 7);
end;

procedure RenderTexts;
begin
  WriteText(0, 0, $1A, 'SONG EDIT   ');
  WriteText(0, 23, $0A, '[TAB] Pattern   [INS] Ins Pos. [L] Load [>] Add Chan. [F10] OPL2/3', 80);
  WriteText(0, 24, $0A, '[SPC] Play/Stop [DEL] Del Pos. [S] Save [<] Sub Chan.', 80);
end;

procedure RenderSongInfoFast;
var
  I, P: Byte;
  S: String2;
begin
  WriteText(10, 5, $0F, NepperRec.Name, 40);
  for I := 0 to $F do
  begin
    P := PatternAnchor + I;
    HexStrFast2(P, S);
    WriteText(10 + 3 * I, 6, $0F, S, 2);
    case NepperRec.Orders[P] of
      $FE:
        WriteText(10 + 3 * I, 7, $0F, 'R', 2);
      $FF:
        WriteText(10 + 3 * I, 7, $0F, 'H', 2);
      else
        begin
          S := HexStr(NepperRec.Orders[P], 2);
          WriteText(10 + 3 * I, 7, $0F, S, 2);
        end;
    end;
  end;
  if TAdlibOPLKind(NepperRec.OPLKind) <> aokOPL2 then
  begin
    if TAdlibOPLKind(NepperRec.OPLKind) = aokOPL3Op2 then
      WriteText(53, 8, $03, 'OPL3 Op-2')
    else
      WriteText(53, 8, $03, 'OPL3 Op-4');
  end else
  begin
    WriteText(53, 8, $03, '', 9);
  end;
end;

procedure RenderSongInfo;
begin
  WriteText(10, 5, $0F, '', 40);
  RenderSongInfoFast;
end;

procedure LoopEditSongName;
begin
  Input.InputText(NepperRec.Name, 40);
  WriteText(10, 5, $0F, NepperRec.Name, 40);
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
  procedure MoveLeft(Step: Byte);
  begin
    if Integer(PatternIndex) - Integer(Step) < 0 then
      Step := PatternIndex;
    if PatternIndex - Step >= 0 then
    begin
      Dec(PatternIndex, Step);
      if PatternIndex < PatternAnchor then
      begin
        PatternAnchor := PatternIndex;
        RenderSongInfoFast;
        Screen.SetCursorPosition(10 + 1, 7);
      end else
        Screen.SetCursorPosition(10 + (PatternIndex - PatternAnchor) * 3 + 1, 7);
      Input.InputCursor := 2;
    end;
  end;

  procedure MoveRight(Step: Byte);
  begin
    if Integer(PatternIndex) + Integer(Step) > $FF then
      Step := $FF - PatternIndex;
    if PatternIndex + Step <= High(NepperRec.Orders) then
    begin
      Inc(PatternIndex, Step);
      if PatternIndex > PatternAnchor + $F then
      begin
        PatternAnchor := PatternIndex - $F;
        RenderSongInfoFast;
        Screen.SetCursorPosition(10 + 15 * 3, 7);
      end else
        Screen.SetCursorPosition(10 + (PatternIndex - PatternAnchor) * 3, 7);
      Input.InputCursor := 1;
    end;
  end;

  procedure Insert;
  var
    I: Byte;
  begin
    if PatternIndex = $FF then
      NepperRec.Orders[$FF] := 0
    else
    begin
      for I := $FE downto PatternIndex do
      begin
        NepperRec.Orders[I + 1] := NepperRec.Orders[I];
      end;
      NepperRec.Orders[PatternIndex] := 0;
    end;
    RenderSongInfoFast;
  end;

  procedure Delete;
  var
    I: Byte;
  begin
    if PatternIndex = $FF then
      NepperRec.Orders[$FF] := 0
    else
    begin
      for I := PatternIndex to $FE do
      begin
        NepperRec.Orders[I] := NepperRec.Orders[I + 1];
      end;
      NepperRec.Orders[$FF] := 0;
    end;
    RenderSongInfoFast;
  end;

var
  S: String20;
  I,
  OldCursorX,
  OldCursorY: Byte;
begin
  Input.InputHex2(S, NepperRec.Orders[PatternIndex], $3F);
  case NepperRec.Orders[PatternIndex] of
    SONG_REPEAT:
      WriteText(10 + (PatternIndex - PatternAnchor) * 3, 7, $0F, 'R', 2);
    SONG_HALT:
      WriteText(10 + (PatternIndex - PatternAnchor) * 3, 7, $0F, 'H', 2);
    else
      WriteText(10 + (PatternIndex - PatternAnchor) * 3, 7, $0F, S);
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
          MoveLeft(1);
        end;
      SCAN_RIGHT:
        begin
          MoveRight(1);
        end;
      SCAN_PGUP:
        begin
          MoveLeft(8);
        end;
      SCAN_PGDN:
        begin
          MoveRight(8);
        end;
      SCAN_INS:
        begin
          Insert;
        end;
      SCAN_DEL:
        begin
          Delete;
        end;
      SCAN_HOME:
        begin
          MoveLeft($FF);
        end;
      SCAN_END:
        begin
          MoveRight($FF);
        end;
      SCAN_F10:
        begin
          Inc(NepperRec.OPLKind);
          if NepperRec.OPLKind > 2 then
            NepperRec.OPLKind := 0;
          Adlib.SetOPL3(TAdlibOPLKind(NepperRec.OPLKind));
          RenderSongInfoFast;
        end;
      SCAN_F1:
        begin
          OldCursorX := CursorX;
          OldCursorY := CursorY;
          ShowHelpDialog('PATTERN.TXT');
          RenderCommonTexts;
          RenderSongInfo;
          RenderTexts;
          EdPattern.RenderPatternInfo;
          Screen.SetCursorPosition(OldCursorX, OldCursorY);
        end;
      SCAN_SPACE:
        begin
          if not IsPlaying then
            Player.Start(PatternIndex, False)
          else
            Player.Stop;
        end
      else
        case KBInput.CharCode of
          'h':
            begin
              NepperRec.Orders[PatternIndex] := SONG_HALT;
              WriteText(10 + (PatternIndex - PatternAnchor) * 3, 7, $0F, 'H', 2);
            end;
          'r':
            begin
              NepperRec.Orders[PatternIndex] := SONG_REPEAT;
              WriteText(10 + (PatternIndex - PatternAnchor) * 3, 7, $0F, 'R', 2);
            end;
          '<', ',':
            begin
              if NepperRec.ChannelCount > 1 then
              begin
                Dec(NepperRec.ChannelCount);
                EdPattern.ResetParams;
                EdPattern.RenderPatternInfo;
              end;
            end;
          '>', '.':
            begin
              if NepperRec.ChannelCount < MAX_CHANNELS then
              begin
                Inc(NepperRec.ChannelCount);
                EdPattern.ResetParams;
                EdPattern.RenderPatternInfo;
              end;
            end;
          's':
            begin
              S := '';
              OldCursorX := CursorX;
              OldCursorY := CursorY;
              if ShowInputDialog('Save song', S) then
              begin
                SaveSong(S);
                S := '';
              end;
              RenderSongInfo;
              EdPattern.RenderPatternInfo;
              Screen.SetCursorPosition(OldCursorX, OldCursorY);
            end;
          'l':
            begin
              S := '';
              OldCursorX := CursorX;
              OldCursorY := CursorY;
              if ShowInputDialog('Load song', S) then
              begin
                Player.Stop;
                if not LoadSong(S) then
                  ShowMessageDialog('Error', 'File not found / Invalid format!');
                S := '';
              end;
              RenderSongInfo;
              EdPattern.RenderPatternInfo;
              Screen.SetCursorPosition(OldCursorX, OldCursorY);
            end;
        end;
    end;
end;

procedure Loop;
begin
  RenderTexts;
  RenderSongInfo;
  ResetParams;
  repeat
    Keyboard.WaitForInput;

    if IsEditSongName then
      LoopEditSongName
    else
      LoopEditSheet;
  until (KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F3) or (KBInput.ScanCode = SCAN_TAB);
end;

end.

