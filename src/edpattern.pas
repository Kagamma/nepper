unit EdPattern;

{$mode ObjFPC}

interface

uses
  Adlib, Utils;

var
  IsPatternEdit: Boolean = False;

procedure RenderCommonTexts; 
procedure ResetParams;
procedure RenderPatternInfo;
procedure Loop;

implementation

uses
  Input, Keyboard, Screen, Formats, EdSong;

const            
  PATTERN_SCREEN_START_X = 4;
  PATTERN_SCREEN_START_Y = 11;
  PATTERN_SCREEN_SIZE = 11;
  PATTERN_CHANNEL_WIDE = 9;

var
  VirtualSheetPointer: PWord;
  CurPattern: PNepperPattern;
  CurPatternIndex: Byte;
  Anchor: Byte = 0;
  CurChannel: Byte = 0;
  CurCell: Byte = 0;
  CurCellPart: Byte = 0;
  CurOctave: Byte = 4;
  IsEditMode: Boolean = False;

procedure ResetParams;
begin
  if CurChannel > NepperRec.ChannelCount - 1 then
    CurChannel := NepperRec.ChannelCount - 1;
  CurCellPart := 0;
  CurOctave := 4;
end;

procedure WriteTextSync(const X, Y, Attr: Byte; const S: String80; MaxLen: Byte = 0);
begin
  WriteText(X, Y, Attr, S, MaxLen);
  ScreenPointer := VirtualSheetPointer;
  WriteText(X, Y - PATTERN_SCREEN_START_Y + Anchor, Attr, S, MaxLen);
  ScreenPointer := ScreenPointerBackup;
end;

procedure RenderEditModeText;
begin
  if IsEditMode then
    WriteText(58, 9, $0F, 'EDIT')
  else
    WriteText(58, 9, $0F, '', 4);
end;

procedure RenderOctave;
begin
  WriteText(70, 9, $0F, Char(CurOctave + Byte('0')));
end; 

procedure RenderPatternIndex;
var
  S: String2;
begin
  S := HexStr(CurPatternIndex, 2);
  WriteText(24, 9, $F, S, 2);
end;

procedure RenderPatternInfo;
var
  PX1, PX2: Byte;
  I, J: ShortInt;
  S: String10;
  PW: PWord;
  PC: PNepperChannel;
begin
  FillChar(VirtualSheetPointer[0], 80*64*2, 0);
  ScreenPointer := VirtualSheetPointer;
  for I := 0 to 63 do
  begin
    S := HexStr(I, 2);
    WriteText(0, I, 03, S, 2);
  end;
  for J := 0 to NepperRec.ChannelCount - 1 do
  begin
    PX1 := J * PATTERN_CHANNEL_WIDE + 4;
    PX2 := PX1 + 3;
    PC := @CurPattern^[J];
    for I := 0 to 63 do
    begin
      if PC^[I].Note.Note = 0 then
        WriteText(PX1, I, $0D, '---', 3)
      else
      begin
        WriteText(PX1, I, $0F, ADLIB_NOTESYM_TABLE[PC^[I].Note.Note], 2);
        WriteText(PX1 + 2, 22, $0F, Char(PC^[I].Note.Octave - Byte('0')), 1);
      end;
      S := HexStr(Word(PC^[I].Effect), 3);
      WriteText(PX2, I, $0F, S, 3);
    end;
  end;
  ScreenPointer := ScreenPointerBackup;
  PW := ScreenPointer + 80 * PATTERN_SCREEN_START_Y;
  Move(VirtualSheetPointer[80 * Anchor], PW[0], PATTERN_SCREEN_SIZE*80*2);
  RenderEditModeText;
  RenderOctave;
  RenderPatternIndex;
end;

procedure RenderCommonTexts;
begin
  WriteText(0, 0, $1F, '                                   - Nepper -', 80);
  WriteText(0, 1, $0E, '     [F1] Song/Pattern Editor  [F2] Instrument Editor  [ESC] Exit Nepper');

  WriteText(0, 3, $4E, ' SONG DATA    ');
  WriteText(0, 5, $0D, 'Song name:');
  WriteText(63, 5, $0D, 'SPECIAL COMMANDS:');
  WriteText(0, 6, $0D, ' Position:');
  WriteText(63, 6, $0D, '[R] For Repeat');
  WriteText(0, 7, $0D, '  Pattern:');
  WriteText(63, 7, $0D, '[H] For Halt');

  WriteText(0, 9, $4E, ' PATTERN DATA ');
  WriteText(16, 9, $0D, 'Pattern:');
  WriteText(27, 9, $0D, 'Instr:');
  WriteText(63, 9, $0D, 'Octave:');

  WriteText(0, 23, $0A, '');
  WriteText(0, 24, $0A, '');

  RenderSongInfo;
  RenderPatternInfo;
end;

procedure RenderTexts;
begin      
  WriteText(0, 0, $1A, 'PATTERN EDIT');
  WriteText(0, 23, $0A, '[TAB] Song [INS-DEL] I/D Line [<>] Instr.sel', 80);
  WriteText(0, 24, $0A, '           [CR] Edit mode     [+-] Pattern.sel', 80);
end;

procedure LoopEditPattern;
var
  S: String3;
  PC: PNepperChannel;
  W: Word;
  PW: PWord;

  procedure MoveDown(const Step: Byte);
  begin
    if CurCell + Step <= $3F then
    begin
      Inc(CurCell, Step);
      if CurCell - Anchor >= PATTERN_SCREEN_SIZE then
      begin
        Anchor := CurCell - PATTERN_SCREEN_SIZE + 1;
        PW := ScreenPointer + 80 * PATTERN_SCREEN_START_Y;
        Move(VirtualSheetPointer[80 * Anchor], PW[0], PATTERN_SCREEN_SIZE*80*2);
      end else
      begin
        Screen.SetCursorPosition(CursorX, CursorY + 1);
      end;
    end;
  end;

  procedure MoveUp(const Step: Byte);
  begin
    if CurCell - Step >= 0 then
    begin
      Dec(CurCell, Step);
      if CurCell < Anchor then
      begin
        Anchor := CurCell;
        PW := ScreenPointer + 80 * PATTERN_SCREEN_START_Y;
        Move(VirtualSheetPointer[80 * Anchor], PW[0], PATTERN_SCREEN_SIZE*80*2);
      end else
      begin
        Screen.SetCursorPosition(CursorX, CursorY - 1);
      end;
    end;
  end;

  procedure EditTone;
  begin

  end;

begin
  PC := @CurPattern^[CurChannel];
  // Edit effect
  if CurCellPart = 1 then
  begin
    W := Word(PC^[CurCell].Effect);
    Input.InputHex3(S, W, $FFF);
    if IsEditMode then
    begin
      Word(PC^[CurCell].Effect) := W;
      WriteTextSync(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + (CurCellPart * 3), PATTERN_SCREEN_START_Y + CurCell - Anchor, $0F, S, 3);
    end;
  end else
  // Edit tone
  begin
    EditTone;
  end;
  // Navigate
  if KBInput.ScanCode < $FE then
  begin
    case KBInput.ScanCode of
      SCAN_LEFT:
        begin
          if CurCellPart = 0 then
          begin
            if CurChannel > 0 then
            begin
              CurCellPart := 1;
              Input.InputCursor := 3;
              Dec(CurChannel);
              Screen.SetCursorPosition(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + (CurCellPart * 3)+ (Input.InputCursor - 1), PATTERN_SCREEN_START_Y + CurCell - Anchor);
            end;
          end else
          begin
            CurCellPart := 0;
            Screen.SetCursorPosition(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + (CurCellPart * 3), PATTERN_SCREEN_START_Y + CurCell - Anchor);
          end;
        end;
      SCAN_RIGHT:
        begin
          if CurCellPart = 1 then
          begin
            if CurChannel < NepperRec.ChannelCount - 1 then
            begin
              CurCellPart := 0;
              Input.InputCursor := 1;
              Inc(CurChannel);
            end;
          end else
          begin
            CurCellPart := 1;
          end;
          Screen.SetCursorPosition(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + (CurCellPart * 3), PATTERN_SCREEN_START_Y + CurCell - Anchor);
        end;
      SCAN_DOWN:
        begin
          MoveDown(1);
        end;
      SCAN_UP:
        begin
          MoveUp(1);
        end;
      else
        case KBInput.CharCode of
          '+':
            begin
              if CurPatternIndex < $FF then
              begin
                Inc(CurPatternIndex);
                CurPattern := NepperRec.Patterns[CurPatternIndex];
                RenderPatternInfo;
              end;
            end;     
          '-':
            begin
              if CurPatternIndex > 0 then
              begin
                Dec(CurPatternIndex);
                CurPattern := NepperRec.Patterns[CurPatternIndex];
                RenderPatternInfo;
              end;
            end;
        end;
    end;
  end;
end;

procedure LoopEditOctave;
begin
  case KBInput.CharCode of
    ')':
      begin
        CurOctave := 0;
        RenderOctave;
      end;
    '!':
      begin
        CurOctave := 1;
        RenderOctave;
      end;
    '@':
      begin
        CurOctave := 2;
        RenderOctave;
      end;
    '#':
      begin
        CurOctave := 3;
        RenderOctave;
      end;
    '$':
      begin
        CurOctave := 4;
        RenderOctave;
      end;
    '%':
      begin
        CurOctave := 5;
        RenderOctave;
      end;
    '^':
      begin
        CurOctave := 6;
        RenderOctave;
      end;
  end;
end;

procedure Loop;
begin
  ResetParams;
  RenderTexts; 
  Screen.SetCursorPosition(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE), PATTERN_SCREEN_START_Y + CurCell - Anchor);
  repeat
    Keyboard.WaitForInput;
    if Keyboard.IsShift then
    begin
      LoopEditOctave;
    end else
    begin
      LoopEditPattern;
      case KBInput.ScanCode of
        SCAN_ENTER:
          begin
            IsEditMode := not IsEditMode;
            RenderEditModeText;
          end;
      end;
    end;
  until (KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F2) or (KBInput.ScanCode = SCAN_TAB); 
  if KBInput.ScanCode = SCAN_TAB then
  begin
    ResetParams;
    RenderPatternInfo;
  end;
end;

initialization
  VirtualSheetPointer := AllocMem(80*64*2);
  CurPattern := NepperRec.Patterns[0];
  CurPatternIndex := 0;

finalization
  Freemem(VirtualSheetPointer);

end.

