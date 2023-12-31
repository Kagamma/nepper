program nepper;

{$mode objFPC}

uses
  Adlib, Keyboard, Input, Screen, Utils, EdInstr, Formats, Timer, Player,
  Dialogs, EdPattern, EdSong, Clipbrd;

begin
  Adlib.Init;

  KBInput.ScanCode := SCAN_F2;
  IsPatternEdit := False;
  repeat
    case KBInput.ScanCode of
      SCAN_F2:
        begin
          ClrScr;
          RenderCommonTexts;
          repeat
            case IsPatternEdit of
              True:
                EdPattern.Loop;
              False:
                EdSong.Loop;
            end;
            case KBInput.ScanCode of
              SCAN_TAB:
                IsPatternEdit := not IsPatternEdit;
            end;
          until(KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F3);
        end;
      SCAN_F3:
        EdInstr.Loop;
    end;
  until KBInput.ScanCode = SCAN_ESC;
  Player.Stop;
end.

