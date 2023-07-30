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
  Adlib, Formats, EdInstr, Screen, Utils;

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
  TmpByte: Byte;
  NoteByte: Byte;
  OctaveByte: Byte;
  Note: TNepperNote;
  Effect: TNepperEffect;
  LastNoteList: array[0..7] of TNepperNote;
  LastEffectList: array[0..7] of TNepperEffect;
  LastInstrumentList: array[0..7] of Byte;
  LastArpeggioList: array[0..7,0..1] of Byte;
  GS2: String2;
  ColorStatus: Byte;

procedure Start(const PatternIndex: Byte = 0);
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
    ColorStatus := $19
  else
    ColorStatus := $1A;  
  HexStrFast2(CurPatternIndex, GS2);
  Screen.WriteTextFast2(ScreenPointer + 75, ColorStatus, GS2);
  Screen.WriteTextFast1(ScreenPointer + 77, ColorStatus, '-');
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

  // Handle effect
  for CurChannel := 0 to NepperRec.ChannelCount - 1 do
  begin     
    PChannel := @PPattern^[CurChannel];
    PCell := @PChannel^.Cells[CurCell];
    PInstrument := @NepperRec.Instruments[PChannel^.InstrumentIndex];
    // Effect
    if Word(PCell^.Effect) <> 0 then
    begin
      case PCell^.Effect.Effect of
        0: // Arpeggio
          begin
            if Byte(Word(PCell^.Effect)) <> 0 then
            begin
              LastArpeggioList[CurChannel, 0] := PCell^.Effect.V1;
              LastArpeggioList[CurChannel, 1] := PCell^.Effect.V2;
            end;
          end;
        $E: // Speed
          begin
            CurSpeed := Byte(Word(PCell^.Effect));
          end;
        $F: // Functions
          begin
            case Byte(Word(PCell^.Effect)) of
              0: // Stop / Start release phase
                begin
                  Adlib.NoteOff(CurChannel);
                  Word(LastEffectList[CurChannel]) := 0;
                end;
              1: // Jump to next pattern
                begin
                  CurCell := $40;
                end;
            end;
          end;
      end;
    end;
    // Handle pitch shift
    if PInstrument^.PitchShift <> 0 then
    begin
      ChangeFreq(FreqRegs[CurChannel], CurChannel, ShortInt(PInstrument^.PitchShift));
    end;
    // Handle arpeggio
    if (CurTicks >= 1) and (CurTicks <= 2) then
    begin
      if LastArpeggioList[CurChannel, CurTicks - 1] <> 0 then
      begin
        NoteByte := LastNoteList[CurChannel].Note + LastArpeggioList[CurChannel, CurTicks - 1];
        if NoteByte > 12 then
        begin
          NoteByte := NoteByte - 12;
          OctaveByte := LastNoteList[CurChannel].Octave + 1;
        end else
          OctaveByte := LastNoteList[CurChannel].Octave;
        Adlib.NoteOn(CurChannel, NoteByte, OctaveByte);
        LastArpeggioList[CurChannel, CurTicks - 1] := 0;
      end;
    end
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
    HexStrFast2(CurPatternIndex, GS2);
    Screen.WriteTextFast2(ScreenPointer + 75, ColorStatus, GS2);
  end;
  // Play note
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
      Screen.WriteTextFast1(ScreenPointer + 67 + CurChannel, $10 + PCell^.Note.Note + 1, #4);
    end else
      Screen.WriteTextFast1(ScreenPointer + 67 + CurChannel, $1F, ' ');
  end;
  //
  HexStrFast2(CurCell, GS2);
  Screen.WriteTextFast2(ScreenPointer + 78, ColorStatus, GS2);
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
  Screen.WriteText(67, 0, $1F, '', 13);
end;

end.

