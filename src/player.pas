unit Player;

{$mode ObjFPC}

interface

var
  IsPlaying: Boolean = False;

procedure Start(const PatternIndex: Byte = 0);
procedure Play;    
procedure Stop;

implementation

uses
  Adlib, Formats, EdInstr, Screen;

var
  I: Byte;
  CurPatternIndex: Byte = 0;
  PInstrument: PAdlibInstrument;
  PPattern: PNepperPattern;
  PChannel: PNepperChannel;
  PCell: PNepperChannelCell;
  CurChannel: Byte;
  CurCell: Byte;
  CurTicks: Byte = 0;
  CurSpeed: Byte = 6; // 40 for fmc?
  IsPatternOnly: Boolean;
  Note: TNepperNote;
  Effect: TNepperEffect;
  LastNoteList: array[0..7] of TNepperNote;
  LastEffectList: array[0..7] of TNepperEffect;
  LastInstrumentList: array[0..7] of Byte;

procedure Start(const PatternIndex: Byte = 0);
var
  C: Byte;
begin
  Stop;
  CurTicks := 0;
  CurCell := 0;
  CurSpeed := 6;
  if PatternIndex <> $FF then
  begin        
    CurPatternIndex := PatternIndex;
    PPattern := Formats.Patterns[PatternIndex];
    IsPatternOnly := True;
  end else
  begin             
    CurPatternIndex := 0;
    PPattern := Formats.Patterns[NepperRec.PatternIndices[CurPatternIndex]];
    IsPatternOnly := False;
  end;
  for CurChannel := 0 to NepperRec.ChannelCount - 1 do
  begin   
    PChannel := @PPattern^[CurChannel];
    Adlib.SetInstrument(CurChannel, @NepperRec.Instruments[PChannel^.InstrumentIndex]);
    LastInstrumentList[CurChannel] := PChannel^.InstrumentIndex;
  end;
  FillChar(LastNoteList[0], SizeOf(LastNoteList), 0);      
  FillChar(LastEffectList[0], SizeOf(LastEffectList), 0);
  IsPlaying := True;
  if IsPatternOnly then
    C := $19
  else
    C := $1A;
  Screen.WriteText(73, 0, C, 'PLAYING', 7);
end;

procedure ChangeFreq(var Reg: TAdlibRegA0B8; const Channel: Byte; const Freq: ShortInt); inline;
begin
  Reg.Freq := Reg.Freq + Freq;
  if Reg.Freq >= ADLIB_FREQ_TABLE[13] then
  begin
    Reg.Freq := ADLIB_FREQ_TABLE[1];
    Reg.Octave := Reg.Octave + 1;
  end else
  if Reg.Freq <= ADLIB_FREQ_TABLE[1] then
  begin
    Reg.Freq := ADLIB_FREQ_TABLE[13];
    Reg.Octave := Reg.Octave - 1;
  end;
  WriteReg($A0 + Channel, Lo(Word(Reg)));
  WriteReg($B0 + Channel, Hi(Word(Reg)));
end;

procedure PlayTestNote; inline;
begin
  if CurInstr^.PitchShift <> 0 then
  begin
    ChangeFreq(FreqRegs[8], 8, ShortInt(CurInstr^.PitchShift));
  end;
end;

procedure Play;
begin
  // For testing instrument
  if IsInstrTesting then
  begin
    PlayTestNote;
  end;
  // Is playing?
  if not IsPlaying then
    Exit;
  // Playing
  for CurChannel := 0 to NepperRec.ChannelCount - 1 do
  begin     
    PChannel := @PPattern^[CurChannel];
    PCell := @PChannel^.Cells[CurCell];
    PInstrument := @NepperRec.Instruments[PChannel^.InstrumentIndex];
    // Effect
    if Word(PCell^.Effect) <> 0 then
    begin
      case PCell^.Effect.Effect of
        5: // Stop / Start release phase
          begin
            Adlib.NoteOff(CurChannel);
            Word(LastEffectList[CurChannel]) := 0;
          end;
        $D:
          begin
            CurCell := $40;
          end;
        $F:
          begin
            CurSpeed := Byte(Word(PCell^.Effect));
          end;
      end;
    end;
    if PInstrument^.PitchShift <> 0 then
    begin
      ChangeFreq(FreqRegs[CurChannel], CurChannel, ShortInt(PInstrument^.PitchShift));
    end;
    //
  end;
  //
  Inc(CurTicks);
  if CurTicks < CurSpeed then
    Exit;
  //
  CurTicks := 0;
  // Change to next PPattern
  if CurCell > $3F then
  begin
    if IsPatternOnly then
    begin
      Stop;
      Exit;
    end else
    begin
      CurCell := 0;
      if CurPatternIndex = High(NepperRec.PatternIndices) then
      begin
        Stop;
        Exit;
      end;
      Inc(CurPatternIndex);
      I := NepperRec.PatternIndices[CurPatternIndex];
      case I of
        SONG_HALT:
          begin
            Stop;
            Exit;
          end;
        SONG_REPEAT:
          begin
            CurPatternIndex := 0;
          end;
      end;
      PPattern := Formats.Patterns[NepperRec.PatternIndices[CurPatternIndex]];
      for CurChannel := 0 to NepperRec.ChannelCount - 1 do
      begin
        if LastInstrumentList[CurChannel] <> PChannel^.InstrumentIndex then
        begin
          PChannel := @PPattern^[CurChannel];
          Adlib.SetInstrument(CurChannel, @NepperRec.Instruments[PChannel^.InstrumentIndex]);
          LastInstrumentList[CurChannel] := PChannel^.InstrumentIndex;
        end;
      end;
    end;
  end;
  //
  for CurChannel := 0 to NepperRec.ChannelCount - 1 do
  begin 
    PChannel := @PPattern^[CurChannel];
    PCell := @PChannel^.Cells[CurCell];
    PInstrument := @NepperRec.Instruments[PChannel^.InstrumentIndex];
    // Note
    if Byte(PCell^.Note) <> 0 then
    begin
      LastNoteList[CurChannel] := PCell^.Note;
      Adlib.NoteOn(CurChannel, PCell^.Note.Note, PCell^.Note.Octave);
    end;
  end;
  //
  Inc(CurCell);
end;

procedure Stop;
begin
  for I := 0 to 8 do
  begin
    Adlib.NoteClear(I);
  end;
  IsPlaying := False; 
  Screen.WriteText(73, 0, $1F, '', 7);
end;

end.

