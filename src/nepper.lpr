program nepper;

{$mode objFPC}

uses
  Adlib, Keyboard, Input, Screen, Utils, EdInstr, Formats, Timer, Player,
  Dialogs, EdPattern, EdSong;

begin
  if not Adlib.Check then
  begin
    Writeln('ERROR: AdLib sound card not found!');
    Halt;
  end;
  Adlib.Init;

  KBInput.ScanCode := SCAN_F1;
  IsPatternEdit := False;
  repeat
    case KBInput.ScanCode of  
      SCAN_F1:
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
          until(KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F2);
        end;
      SCAN_F2:
        EdInstr.Loop;
    end;
  until KBInput.ScanCode = SCAN_ESC;
  Adlib.Reset;
end.

