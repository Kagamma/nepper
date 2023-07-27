unit EdPattern;

{$mode ObjFPC}

interface

uses
  Adlib, Utils;

var
  IsPatternEdit: Boolean = False;

procedure RenderCommonTexts;
procedure Loop;

implementation

uses
  Input, Keyboard, Screen, Formats;

procedure RenderCommonTexts;
begin
  WriteText(0, 0, $1F, '                                   - Nepper -', 80);
  WriteText(0, 1, $0E, '     [F1] Song/Pattern Editor  [F2] Instrument Editor  [ESC] Exit Nepper');

  WriteText(0, 3, $4E, ' SONG DATA    ');
  WriteText(0, 5, $0D, 'Song name:');
  WriteText(63, 5, $0D, 'SPECIAL COMMANDS:');
  WriteText(0, 6, $0D, ' Position:');
  WriteText(10, 6, $0F, '00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F');   
  WriteText(63, 6, $0D, '[R] For Repeat');
  WriteText(0, 7, $0D, '  Pattern:');
  WriteText(63, 7, $0D, '[H] For Halt');

  WriteText(0, 9, $4E, ' PATTERN DATA ');
  WriteText(16, 9, $0D, 'Pattern:');
  WriteText(27, 9, $0D, 'Instr:');
  WriteText(63, 9, $0D, 'Octave:');


  WriteText(0, 23, $0A, '');
  WriteText(0, 24, $0A, '');
end;

procedure RenderTexts;
begin      
  WriteText(0, 0, $1A, 'PATTERN EDIT');
  WriteText(0, 23, $0A, '', 80);
  WriteText(0, 24, $0A, '', 80);
end;

procedure Loop;
begin
  RenderTexts;
  repeat
    Keyboard.WaitForInput;
  until (KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F2) or (KBInput.ScanCode = SCAN_TAB);
end;

end.

