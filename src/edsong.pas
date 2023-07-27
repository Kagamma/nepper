unit EdSong;

{$mode ObjFPC}

interface

uses
  Adlib;

var
  IsSongPlaying: Boolean = False;

procedure Loop;

implementation

uses
  Input, Keyboard, Screen;

var
  IsEditSongName: Boolean = False;

procedure RenderTexts;
begin
  WriteText(0, 0, $1A, 'SONG EDIT   ');
  WriteText(0, 23, $0A, '[TAB] Pattern [INS] Ins Pos. [L] Load [T] Type Songname [<] Add Chan.', 80);
  WriteText(0, 24, $0A, '              [DEL] Del Pos. [S] Save [SPC] Play/Stop   [>] Sub Chan.', 80);
end;

procedure RenderSongInfo;
begin
end;

procedure LoopEditSongName;
begin
end;

procedure LoopEditSheet;
begin
end;

procedure Loop;
begin
  RenderTexts;
  RenderSongInfo;
  Screen.SetCursorPosition(10, 7);
  IsEditSongName := False;
  repeat
    Keyboard.WaitForInput;

    if IsEditSongName then
      LoopEditSongName
    else
      LoopEditSheet;

    if KBInput.ScanCode < $FE then
    begin
      if IsEditSongName and (KBInput.ScanCode = SCAN_ENTER) then
      begin
        IsEditSongName := False
      end else
      if (not IsEditSongName) and (KBInput.CharCode = 't') then
      begin
        IsEditSongName := True;
      end;
    end;
  until (KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F2) or (KBInput.ScanCode = SCAN_TAB);
end;

end.

