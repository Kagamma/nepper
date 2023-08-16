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
  Input, Keyboard, Screen, Formats, EdSong, Player, Dialogs, Clipbrd;

const            
  PATTERN_SCREEN_START_X = 4;
  PATTERN_SCREEN_START_Y = 11;
  PATTERN_SCREEN_SIZE = 11;
  PATTERN_CHANNEL_WIDE = 8;

var
  VirtualSheetPointer: PWord;
  CurPattern: PNepperPattern;
  CurPatternIndex: Byte;
  Anchor: Byte = 0;
  CurChannel: Byte = 0;
  CurCell: Byte = 0;
  CurCellPart: Byte = 0;
  CurOctave: Byte = 4;
  CurStep: Byte = 1;
  CurInstrIndex: Byte = 0;
  IsEditMode: Boolean = True;
  GS2: String2;
  GS3: String3;
  IsMarked: Boolean = False;

procedure ResetParams;
begin
  if CurChannel > NepperRec.ChannelCount - 1 then
    CurChannel := NepperRec.ChannelCount - 1;
  CurCellPart := 0;
  IsMarked := False;
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
    WriteText(58, 9, $03, 'EDIT')
  else
    WriteText(58, 9, $03, '', 4);
end;

procedure RenderOctave; inline;
begin
  WriteText(70, 9, $0F, Char(CurOctave + Byte('0')));
end; 

procedure RenderPatternIndex; inline;
var
  S: String2;
begin
  HexStrFast2(CurPatternIndex, S);
  WriteText(24, 9, $F, S, 2);
end;

procedure RenderInstrument; inline;
var
  S: String2;
  PC: PNepperChannel;
begin
  PC := @CurPattern^[CurChannel];
  HexStrFast2(CurInstrIndex, S);
  WriteText(33, 9, $F, S, 2);
  WriteText(36, 9, $F, NepperRec.Instruments[CurInstrIndex].Name, 20);
end;

procedure RenderStep;
begin
  HexStrFast2(CurStep, GS2);
  WriteText(78, 9, $0F, GS2);
end;

procedure RenderSpeed;
begin
  HexStrFast2(NepperRec.Speed, GS2);
  WriteText(64, 8, COLOR_LABEL, 'Ticks:');
  WriteText(70, 8, $0F, GS2);
  HexStrFast2(NepperRec.Clock, GS2);
  WriteText(75, 8, COLOR_LABEL, 'Hz:');
  WriteText(78, 8, $0F, GS2);
end;

procedure RenderMark;
begin
  if IsMarked then
  begin
    HexStrFast2(ClipbrdCellStart, GS2);
    WriteText(72, 22, 3, 'Mark:');
    WriteText(77, 22, 3, GS2);
  end else
    WriteText(72, 22, 3, '', 7);
end;

procedure RenderChannelStatus;
var
  I: Byte;
begin
  for I := 0 to MAX_CHANNELS - 1 do
  begin
    if not Player.ChannelEnabledList[I] then
      WriteText(PATTERN_SCREEN_START_X + PATTERN_CHANNEL_WIDE * I + 1, 10, $C, 'x')
    else
      WriteText(PATTERN_SCREEN_START_X + PATTERN_CHANNEL_WIDE * I + 1, 10, $C, ' ');
  end;
end;

// Time critical function, process all pattern data to a buffer for fast scrolling
procedure RenderPatternInfo;
var
  I, J: ShortInt;
  W: Word;
  B: Byte;
  PW: PWord;
  PC: PNepperChannelCells;
begin
  FillChar(VirtualSheetPointer[0], 80*64*2, 0);
  PW := VirtualSheetPointer;
  for I := 0 to $3F do
  begin
    GS2[1] := BASE16_CHARS[Byte(I shr 4) and $F];
    GS2[2] := BASE16_CHARS[Byte(I) and $F];
    WriteTextFast2(PW, 03, GS2);
    Inc(PW, 80);
  end;
  for J := 0 to NepperRec.ChannelCount - 1 do
  begin
    PW := VirtualSheetPointer + (J * PATTERN_CHANNEL_WIDE + 4);
    PC := @CurPattern^[J].Cells;
    for I := 0 to $3F do
    begin
      if PC^[I].Note.Note = 0 then
        WriteTextFast3(PW, COLOR_LABEL, '---')
      else
      begin
        WriteTextFast2(PW, COLOR_LABEL, ADLIB_NOTESYM_TABLE[PC^[I].Note.Note]);
        WriteTextFast1(PW + 2, COLOR_LABEL, Char(PC^[I].Note.Octave + Byte('0')));
      end;
      B := PC^[I].InstrumentIndex;
      GS2[1] := BASE16_CHARS[(B shr 4) and $F];
      GS2[2] := BASE16_CHARS[B and $F];
      WriteTextFast2(PW + 3, 07, GS2);
      W := Word(PC^[I].Effect);
      GS3[1] := Char(W shr 8);
      if Byte(GS3[1]) = 0 then
        GS3[1] := '0';
      GS3[2] := BASE16_CHARS[Byte(W shr 4) and $F];
      GS3[3] := BASE16_CHARS[Byte(W) and $F];
      WriteTextFast3(PW + 5, $0F, GS3);
      PW := PW + 80;
    end;
  end;
  PW := ScreenPointer + 80 * PATTERN_SCREEN_START_Y;
  Move(VirtualSheetPointer[80 * Anchor], PW[0], PATTERN_SCREEN_SIZE*80*2);
  RenderEditModeText;
  RenderOctave;
  RenderPatternIndex;
  RenderInstrument;
  RenderStep;
  RenderChannelStatus;
  RenderSpeed;
end;

procedure RenderPatternInfoOneChannel(const Channel: Byte);
var
  I, J: ShortInt;
  W: Word;
  B: Byte;
  PW: PWord;
  PC: PNepperChannelCells;
begin
  J := Channel;
  PW := VirtualSheetPointer + (J * PATTERN_CHANNEL_WIDE + 4);
  PC := @CurPattern^[J].Cells;
  for I := 0 to $3F do
  begin
    if PC^[I].Note.Note = 0 then
      WriteTextFast3(PW, COLOR_LABEL, '---')
    else
    begin
      WriteTextFast2(PW, COLOR_LABEL, ADLIB_NOTESYM_TABLE[PC^[I].Note.Note]);
      WriteTextFast1(PW + 2, COLOR_LABEL, Char(PC^[I].Note.Octave + Byte('0')));
    end;
    B := PC^[I].InstrumentIndex;
    GS2[1] := BASE16_CHARS[(B shr 4) and $F];
    GS2[2] := BASE16_CHARS[B and $F];
    WriteTextFast2(PW + 3, 07, GS2);
    W := Word(PC^[I].Effect);
    GS3[1] := Char(W shr 8);
    if Byte(GS3[1]) = 0 then
      GS3[1] := '0';
    GS3[2] := BASE16_CHARS[Byte(W shr 4) and $F];
    GS3[3] := BASE16_CHARS[Byte(W) and $F];
    WriteTextFast3(PW + 5, $0F, GS3);
    PW := PW + 80;
  end;
  PW := ScreenPointer + 80 * PATTERN_SCREEN_START_Y;
  Move(VirtualSheetPointer[80 * Anchor], PW[0], PATTERN_SCREEN_SIZE*80*2);
end;

procedure RenderCommonTexts;
begin
  WriteText(0, 0, $1F, '                                   - Nepper -', 80);
  WriteText(0, 1, $0E, '  [F1] Help [F2] Song/Pattern Editor [F3] Instrument Editor [ESC] Exit Nepper');

  WriteText(0, 3, $4E, ' SONG DATA    ');    
  WriteText(0, 3, $4E, ' SONG DATA    ');
  WriteText(0, 5, COLOR_LABEL, 'Song name:');
  WriteText(63, 5, COLOR_LABEL, 'SPECIAL COMMANDS:');
  WriteText(0, 6, COLOR_LABEL, ' Position:');
  WriteText(63, 6, COLOR_LABEL, '[R] For Repeat');
  WriteText(0, 7, COLOR_LABEL, '  Pattern:');
  WriteText(63, 7, COLOR_LABEL, '[H] For Halt');

  WriteText(0, 9, $4E, ' PATTERN DATA ');
  WriteText(16, 9, COLOR_LABEL, 'Pattern:');
  WriteText(27, 9, COLOR_LABEL, 'Instr:');
  WriteText(63, 9, COLOR_LABEL, 'Octave:');
  WriteText(73, 9, COLOR_LABEL, 'Step:');

  WriteText(0, 23, $0A, '');
  WriteText(0, 24, $0A, '');

  RenderSongInfo;
  RenderPatternInfo;
end;

procedure RenderTexts;
begin      
  WriteText(0, 0, $1A, 'PATTERN EDIT');
  WriteText(0, 23, $0A, '[TAB] Song [INS-DEL] I/D  [<>] Instr.sel   [SF-UP/DN] Step   [CTL-X/C/V] Ct/Cp/P', 80);
  WriteText(0, 24, $0A, '[SPC] P/S  [CR] Edit mode [+-] Pattern.sel [SF-LF/RN] Octave [F5] Copy mark', 80);
end;

procedure LoopEditPattern;
var
  S: String10;
  PC: PNepperChannel;
  W: Word;
  PW: PWord;
  OldInputCursor: Byte;
  OldCursorX,
  OldCursorY: Byte;

  procedure MoveDown(Step: Byte);
  begin
    if CurCell + Step > $3F then
      Step := $3F - CurCell;
    Inc(CurCell, Step);
    if CurCell - Anchor >= PATTERN_SCREEN_SIZE then
    begin
      Anchor := CurCell - PATTERN_SCREEN_SIZE + 1;
      PW := ScreenPointer + 80 * PATTERN_SCREEN_START_Y;
      Move(VirtualSheetPointer[80 * Anchor], PW[0], PATTERN_SCREEN_SIZE*80*2);
      Screen.SetCursorPosition(CursorX, PATTERN_SCREEN_START_Y + PATTERN_SCREEN_SIZE - 1);
    end else
    begin
      Screen.SetCursorPosition(CursorX, CursorY + Step);
    end;
  end;

  procedure MoveUp(Step: Byte);
  begin
    if ShortInt(CurCell) - ShortInt(Step) < 0 then
      Step := CurCell;
    Dec(CurCell, Step);
    if CurCell < Anchor then
    begin
      Anchor := CurCell;
      PW := ScreenPointer + 80 * PATTERN_SCREEN_START_Y;
      Move(VirtualSheetPointer[80 * Anchor], PW[0], PATTERN_SCREEN_SIZE*80*2);
      Screen.SetCursorPosition(CursorX, PATTERN_SCREEN_START_Y);
    end else
    begin
      Screen.SetCursorPosition(CursorX, CursorY - Step);
    end;
  end;

  procedure SetTone(const Note, Octave: Byte);
  begin
    if (Note <> 0) or (Octave <> 0) then
    begin
      Adlib.SetInstrument(CurChannel, @NepperRec.Instruments[CurInstrIndex]);
      AdLib.NoteClear(CurChannel);
      Adlib.NoteOn(CurChannel, Note, Octave);
    end;
    if IsEditMode then
    begin
      PC^.Cells[CurCell].Note.Note := Note;
      PC^.Cells[CurCell].Note.Octave := Octave;
      PC^.Cells[CurCell].InstrumentIndex := CurInstrIndex;
      if (Note = 0) and (Octave = 0) then
      begin
        PC^.Cells[CurCell].InstrumentIndex := 0;
        WriteTextSync(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE)    , PATTERN_SCREEN_START_Y + CurCell - Anchor, COLOR_LABEL, '---', 3);
        WriteTextSync(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + 3, PATTERN_SCREEN_START_Y + CurCell - Anchor, $07, '00', 2);
      end else
      begin
        WriteTextSync(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE)    , PATTERN_SCREEN_START_Y + CurCell - Anchor, COLOR_LABEL, ADLIB_NOTESYM_TABLE[Note], 2);
        WriteTextSync(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + 2, PATTERN_SCREEN_START_Y + CurCell - Anchor, COLOR_LABEL, Char(Octave + Byte('0')), 1);
        HexStrFast2(CurInstrIndex, GS2);
        WriteTextSync(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + 3, PATTERN_SCREEN_START_Y + CurCell - Anchor, $07, GS2, 2);
        MoveDown(CurStep);
      end;
    end;
  end;

  procedure InsertTone;
  var
    I: Byte;
  begin
    for I := $3F downto CurCell + 1 do
    begin
      PC^.Cells[I] := PC^.Cells[I - 1];
    end;
    FillChar(PC^.Cells[CurCell], SizeOf(PC^.Cells[CurCell]), 0);
    RenderPatternInfoOneChannel(CurChannel);
  end;

  procedure DeleteTone;
  var
    I: Byte;
  begin
    for I := CurCell to $3E do
    begin
      PC^.Cells[I] := PC^.Cells[I + 1];
    end;
    FillChar(PC^.Cells[$3F], SizeOf(PC^.Cells[$3F]), 0);
    RenderPatternInfoOneChannel(CurChannel);
  end;

  procedure EditTone;
  begin
    if IsCtrl then
      Exit;
    case KBInput.CharCode of
      'z':
        begin
          SetTone(1, CurOctave);
        end;
      's':
        begin
          SetTone(2, CurOctave);
        end;    
      'x':
        begin
          SetTone(3, CurOctave);
        end;
      'd':
        begin
          SetTone(4, CurOctave);
        end;
      'c':
        begin
          SetTone(5, CurOctave);
        end;
      'v':
        begin
          SetTone(6, CurOctave);
        end;
      'g':
        begin
          SetTone(7, CurOctave);
        end;
      'b':
        begin
          SetTone(8, CurOctave);
        end;
      'h':
        begin
          SetTone(9, CurOctave);
        end;
      'n':
        begin
          SetTone(10, CurOctave);
        end;
      'j':
        begin
          SetTone(11, CurOctave);
        end;
      'm':
        begin
          SetTone(12, CurOctave);
        end;
      //
      'q':
        begin
          SetTone(1, CurOctave + 1);
        end;
      '2':
        begin
          SetTone(2, CurOctave + 1);
        end;
      'w':
        begin
          SetTone(3, CurOctave + 1);
        end;
      '3':
        begin
          SetTone(4, CurOctave + 1);
        end;
      'e':
        begin
          SetTone(5, CurOctave + 1);
        end;
      'r':
        begin
          SetTone(6, CurOctave + 1);
        end;
      '5':
        begin
          SetTone(7, CurOctave + 1);
        end;
      't':
        begin
          SetTone(8, CurOctave + 1);
        end;
      '6':
        begin
          SetTone(9, CurOctave + 1);
        end;
      'y':
        begin
          SetTone(10, CurOctave + 1);
        end;
      '7':
        begin
          SetTone(11, CurOctave + 1);
        end;
      'u':
        begin
          SetTone(12, CurOctave + 1);
        end;
      '0':
        begin
          SetTone(0, 0);
        end
      else
        case KBInput.ScanCode of
          SCAN_INS:
            begin
              InsertTone;
            end;                  
          SCAN_DEL:
            begin
              DeleteTone;
            end;
        end;
    end;
  end;

  procedure DisableMark;
  begin
    IsMarked := False;
    RenderMark;
  end;

  procedure EnableMark;
  begin
    IsMarked := True;
    ClipbrdCellStart := CurCell;
    RenderMark;
  end;

  procedure PlotMark;
  begin
    if not IsMarked then
    begin
      EnableMark;
    end else
    begin
      DisableMark;
    end;
  end;

  procedure CopyNotes;
  var
    I: Byte;
    procedure CopyNote;
    begin
      ClipbrdCells[I].Note := PC^.Cells[I].Note;
      ClipbrdCells[I].InstrumentIndex := PC^.Cells[I].InstrumentIndex;
    end;
  begin
    if not IsMarked then
    begin 
      Clipbrd.ClipbrdCellStart := -1;
      for I := 0 to $3F do
      begin
        CopyNote
      end;
    end else
    begin
      SwapIfBigger(Clipbrd.ClipbrdCellStart, Clipbrd.ClipbrdCellEnd);
      for I := Clipbrd.ClipbrdCellStart to Clipbrd.ClipbrdCellEnd do
      begin
        CopyNote;
      end;
    end;
  end;

  procedure CutNotes;
  var
    I: Byte;
    procedure CutNote;
    begin
      ClipbrdCells[I].Note := PC^.Cells[I].Note;
      ClipbrdCells[I].InstrumentIndex := PC^.Cells[I].InstrumentIndex;
      Byte(PC^.Cells[I].Note) := 0;
      PC^.Cells[I].InstrumentIndex := 0;
    end;
  begin
    if not IsMarked then
    begin
      Clipbrd.ClipbrdCellStart := -1;
      for I := 0 to $3F do
      begin
        CutNote;
      end;
    end else
    begin
      SwapIfBigger(Clipbrd.ClipbrdCellStart, Clipbrd.ClipbrdCellEnd);
      for I := Clipbrd.ClipbrdCellStart to Clipbrd.ClipbrdCellEnd do
      begin
        CutNote;
      end;
    end;
  end;

  procedure PasteNotes;
  var
    I: Byte;
  begin
    if Clipbrd.ClipbrdCellStart >= 0 then
    begin
      for I := 0 to Clipbrd.ClipbrdCellEnd - Clipbrd.ClipbrdCellStart do
      begin
        PC^.Cells[CurCell + I].Note := ClipbrdCells[I + Clipbrd.ClipbrdCellStart].Note;
        PC^.Cells[CurCell + I].InstrumentIndex := ClipbrdCells[I + Clipbrd.ClipbrdCellStart].InstrumentIndex;
        if I + CurCell >= $3F then
          Break;
      end;
    end else
    begin
      for I := 0 to $3F do
      begin    
        PC^.Cells[CurCell + I].Note := ClipbrdCells[I].Note;
        PC^.Cells[CurCell + I].InstrumentIndex := ClipbrdCells[I].InstrumentIndex;
        if I + CurCell >= $3F then
          Break;
      end;
    end;
  end;

  procedure CopyEffects;
  var
    I: Byte;
  begin
    if not IsMarked then
    begin
      Clipbrd.ClipbrdCellStart := -1;
      for I := 0 to $3F do 
        ClipbrdCells[I].Effect := PC^.Cells[I].Effect;
    end else
    begin
      SwapIfBigger(Clipbrd.ClipbrdCellStart, Clipbrd.ClipbrdCellEnd);
      for I := Clipbrd.ClipbrdCellStart to Clipbrd.ClipbrdCellEnd do
        ClipbrdCells[I].Effect := PC^.Cells[I].Effect;
    end;
  end;

  procedure CutEffects;
  var
    I: Byte;
  begin
    if not IsMarked then
    begin
      Clipbrd.ClipbrdCellStart := -1;
      for I := 0 to $3F do
      begin
        ClipbrdCells[I].Effect := PC^.Cells[I].Effect;
        Word(PC^.Cells[I].Effect) := 0;
      end;
    end else
    begin
      SwapIfBigger(Clipbrd.ClipbrdCellStart, Clipbrd.ClipbrdCellEnd);
      for I := Clipbrd.ClipbrdCellStart to Clipbrd.ClipbrdCellEnd do
      begin
        ClipbrdCells[I].Effect := PC^.Cells[I].Effect;
        Word(PC^.Cells[I].Effect) := 0;
      end;
    end;
  end;

  procedure PasteEffects;
  var
    I: Byte;
  begin
    if Clipbrd.ClipbrdCellStart >= 0 then
    begin
      for I := 0 to Clipbrd.ClipbrdCellEnd - Clipbrd.ClipbrdCellStart do
      begin
        PC^.Cells[CurCell + I].Effect := ClipbrdCells[I + Clipbrd.ClipbrdCellStart].Effect;
        if I + CurCell >= $3F then
          Break;
      end;
    end else
    begin
      for I := 0 to $3F do
      begin
        PC^.Cells[CurCell + I].Effect := ClipbrdCells[I].Effect;
        if I + CurCell >= $3F then
          Break;
      end;
    end;
  end; 

  procedure DoCut;
  begin   
    Clipbrd.ClipbrdCellEnd := CurCell;
    if CurCellPart = 0 then
      CutNotes
    else
      CutEffects;
    DisableMark;
    RenderPatternInfoOneChannel(CurChannel);
  end;

  procedure DoCopy;
  begin  
    Clipbrd.ClipbrdCellEnd := CurCell;
    if CurCellPart = 0 then
      CopyNotes
    else
      CopyEffects; 
    DisableMark;
  end;

  procedure DoPaste;
  begin
    if CurCellPart = 0 then
      PasteNotes
    else
      PasteEffects;
    RenderPatternInfoOneChannel(CurChannel);
  end;

begin
  PC := @CurPattern^[CurChannel];
  // Edit effect
  if CurCellPart = 1 then
  begin
    W := Word(PC^.Cells[CurCell].Effect);
    OldInputCursor := Input.InputCursor;
    Input.InputHex3(S, W);
    if IsEditMode then
    begin
      Word(PC^.Cells[CurCell].Effect) := W;
      WriteTextSync(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + (CurCellPart * 5), PATTERN_SCREEN_START_Y + CurCell - Anchor, $0F, S, 3);
      if KBInput.ScanCode = $FF then
      begin 
        if Input.InputCursor <> OldInputCursor then
        begin
          Input.InputCursor := OldInputCursor;
          Dec(CursorX);
        end;
        MoveDown(CurStep);
      end;
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
              Screen.SetCursorPosition(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + (CurCellPart * 5)+ (Input.InputCursor - 1), PATTERN_SCREEN_START_Y + CurCell - Anchor);
              RenderInstrument;
              DisableMark;
            end;
          end else
          begin
            CurCellPart := 0;
            DisableMark;
            Screen.SetCursorPosition(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + (CurCellPart * 5), PATTERN_SCREEN_START_Y + CurCell - Anchor);
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
              RenderInstrument;
              DisableMark;
            end;
          end else
          begin
            CurCellPart := 1;
            DisableMark;
          end;
          Screen.SetCursorPosition(PATTERN_SCREEN_START_X + (CurChannel * PATTERN_CHANNEL_WIDE) + (CurCellPart * 5), PATTERN_SCREEN_START_Y + CurCell - Anchor);
        end;
      SCAN_DOWN:
        begin
          MoveDown(1);
        end;
      SCAN_UP:
        begin
          MoveUp(1);
        end;
      SCAN_PGDN:
        begin
          MoveDown(8);
        end;
      SCAN_PGUP:
        begin
          MoveUp(8);
        end;
      SCAN_HOME:
        begin
          MoveUp($3F);
        end;   
      SCAN_END:
        begin
          MoveDown($3F);
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
      SCAN_F5:
        begin
          PlotMark;
        end;
      SCAN_X:
        begin
          if IsCtrl then
          begin
            DoCut;
          end;
        end;
      SCAN_C:
        begin
          if IsCtrl then
          begin
            DoCopy;
          end;
        end;
      SCAN_V:
        begin
          if IsCtrl then
          begin
            DoPaste;
          end;
        end;
      SCAN_SPACE:
        begin
          if not IsPlaying then
            Player.Start(CurPatternIndex)
          else
            Player.Stop;
        end
      else
        case KBInput.CharCode of
          '+':
            begin
              if CurPatternIndex < High(Formats.Patterns) then
              begin
                Inc(CurPatternIndex);
                CurPattern := Formats.Patterns[CurPatternIndex];
                RenderPatternInfo;
              end;
            end;
          '-':
            begin
              if CurPatternIndex > 0 then
              begin
                Dec(CurPatternIndex);
                CurPattern := Formats.Patterns[CurPatternIndex];
                RenderPatternInfo;
              end;
            end; 
          '<':
            begin
              if CurInstrIndex > 0 then
              begin
                Dec(CurInstrIndex);
                RenderInstrument;
                Adlib.SetInstrument(CurChannel, @NepperRec.Instruments[CurInstrIndex]);
              end;
            end;
          '>':
            begin
              if CurInstrIndex < 31 then
              begin
                Inc(CurInstrIndex);
                RenderInstrument;
                Adlib.SetInstrument(CurChannel, @NepperRec.Instruments[CurInstrIndex]);
              end;
            end;
        end;
    end;
  end;
end;

procedure EnableDisableChannels;
  procedure SwitchChannelStatus(const V: Byte);
  begin
    Player.ChannelEnabledList[V] := not Player.ChannelEnabledList[V];
    RenderChannelStatus;
  end;
begin
  case KBInput.CharCode of
    '!':
      SwitchChannelStatus(0);
    '@':
      SwitchChannelStatus(1);
    '#':
      SwitchChannelStatus(2);
    '$':
      SwitchChannelStatus(3);
    '%':
      SwitchChannelStatus(4);
    '^':
      SwitchChannelStatus(5);
    '&':
      SwitchChannelStatus(6);
    '*':
      SwitchChannelStatus(7);
    '(':
      SwitchChannelStatus(8);
  end;
end;

function LoopEditOctave: Boolean;
var
  PC: PNepperChannel;
begin  
  PC := @CurPattern^[CurChannel];
  Result := False;
  if Keyboard.IsShift then
    case KBInput.ScanCode of
      SCAN_RIGHT:
        begin
          if CurOctave < 6 then
          begin
            Inc(CurOctave);
            RenderOctave;
          end;
          Result := True;
        end;
      SCAN_LEFT:
        begin
          if CurOctave > 0 then
          begin
            Dec(CurOctave);
            RenderOctave;
          end;
          Result := True;
        end;
    end;
end;

function LoopEditStep: Boolean;
begin      
  Result := False;
  if Keyboard.IsShift then
    case KBInput.ScanCode of
      SCAN_UP:
        begin
          if CurStep < $3F then
          begin
            Inc(CurStep);
            RenderStep;
          end;    
          Result := True;
        end;
      SCAN_DOWN:
        begin
          if CurStep > 0 then
          begin
            Dec(CurStep);
            RenderStep;
          end;
          Result := True;
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
    if LoopEditOctave then Continue;
    if LoopEditStep then Continue;
    LoopEditPattern;
    EnableDisableChannels;
    case KBInput.ScanCode of
      SCAN_ENTER:
        begin
          IsEditMode := not IsEditMode;
          RenderEditModeText;
        end;
    end;
  until (KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F3) or (KBInput.ScanCode = SCAN_TAB);
  if KBInput.ScanCode = SCAN_TAB then
  begin
    ResetParams;
  end;
end;

initialization
  VirtualSheetPointer := AllocMem(80*64*2);
  CurPattern := Formats.Patterns[0];
  CurPatternIndex := 0;  
  GS3[0] := Char(3);
  GS2[0] := Char(2);

finalization
  Freemem(VirtualSheetPointer);

end.

