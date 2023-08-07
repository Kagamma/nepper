unit Player;

{$mode ObjFPC}

interface

uses
  Adlib;

var
  IsPlaying: Boolean = False; 
  ChannelEnabledList: array[0..MAX_CHANNELS - 1] of Boolean;

procedure Start(const PatternIndex: Byte = 0);
procedure Play;
procedure Stop;

implementation

uses
  Formats, EdInstr, Screen, Utils, Timer;

const
  SINE_TABLE: array[0..255] of ShortInt = (
    $00, $03, $06, $09, $0C, $10, $13, $16, $19, $1C, $1F, $22, $25, $28, $2B, $2E,
    $31, $34, $36, $39, $3C, $3F, $41, $44, $47, $49, $4C, $4E, $51, $53, $55, $58,
    $5A, $5C, $5E, $60, $62, $64, $66, $68, $6A, $6B, $6D, $6F, $70, $72, $73, $74,
    $75, $77, $78, $79, $7A, $7B, $7B, $7C, $7D, $7D, $7E, $7E, $7E, $7F, $7F, $7F,
    $7F, $7F, $7F, $7F, $7E, $7E, $7E, $7D, $7C, $7C, $7B, $7A, $79, $78, $77, $76,
    $75, $74, $73, $71, $70, $6E, $6D, $6B, $69, $67, $66, $64, $62, $60, $5E, $5B,
    $59, $57, $55, $52, $50, $4D, $4B, $48, $46, $43, $41, $3E, $3B, $38, $35, $33,
    $30, $2D, $2A, $27, $24, $21, $1E, $1B, $18, $15, $12, $0F, $0B, $08, $05, $02,
    $FF, $FC, $F9, $F6, $F2, $EF, $EC, $E9, $E6, $E3, $E0, $DD, $DA, $D7, $D4, $D1,
    $CE, $CB, $C9, $C6, $C3, $C0, $BE, $BB, $B8, $B6, $B3, $B1, $AE, $AC, $AA, $A7,
    $A5, $A3, $A1, $9F, $9D, $9B, $99, $97, $96, $94, $92, $91, $8F, $8E, $8D, $8B,
    $8A, $89, $88, $87, $86, $85, $84, $84, $83, $83, $82, $82, $81, $81, $81, $81,
    $81, $81, $81, $81, $82, $82, $83, $83, $84, $84, $85, $86, $87, $88, $89, $8A,
    $8B, $8D, $8E, $8F, $91, $92, $94, $96, $97, $99, $9B, $9D, $9F, $A1, $A3, $A5,
    $A8, $AA, $AC, $AE, $B1, $B3, $B6, $B8, $BB, $BE, $C0, $C3, $C6, $C9, $CB, $CE,
    $D1, $D4, $D7, $DA, $DD, $E0, $E3, $E6, $E9, $EC, $EF, $F3, $F6, $F9, $FC, $FF
  );

var
  I: Byte;
  Short: ShortInt;
  CurPatternIndex: Byte;
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
  LastNoteList: array[0..MAX_CHANNELS - 1] of TNepperNote;
  LastNoteFutureList: array[0..MAX_CHANNELS - 1] of TNepperNote;
  LastEffectList: array[0..MAX_CHANNELS - 1] of TNepperEffect;
  LastInstrumentList: array[0..MAX_CHANNELS - 1] of Byte;
  LastArpeggioList: array[0..MAX_CHANNELS - 1, 0..1] of Byte;
  LastNoteDelayList: array[0..MAX_CHANNELS - 1] of Byte;
  LastNoteTimerList: array[0..MAX_CHANNELS - 1] of Word;
  GS2: String2;
  ColorStatus: Byte;
  Instruments: array[0..31] of TAdlibInstrument;

procedure CleanUpStates;
begin
  FillChar(LastInstrumentList[0], SizeOf(LastInstrumentList), $FF);
  FillChar(LastNoteList[0], SizeOf(LastNoteList), 0);
  FillChar(LastEffectList[0], SizeOf(LastEffectList), 0);
  FillChar(LastNoteDelayList[0], SizeOf(LastNoteDelayList), 0);
  FillChar(LastNoteTimerList[0], SizeOf(LastNoteTimerList), 0);
  FillChar(VolumeModList[0], SizeOf(VolumeModList), 0);
end;

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
    ColorStatus := $19;
    Screen.WriteTextFast2(ScreenPointer + 72, ColorStatus, '--');
    Screen.WriteTextFast1(ScreenPointer + 74, ColorStatus, '/');
    HexStrFast2(CurPatternIndex, GS2);
    Screen.WriteTextFast2(ScreenPointer + 75, ColorStatus, GS2);
    Screen.WriteTextFast1(ScreenPointer + 77, ColorStatus, '/');
  end else
  begin
    CurPatternIndex := 0;
    PPattern := Formats.Patterns[NepperRec.PatternIndices[CurPatternIndex]];
    IsPatternOnly := False;
    ColorStatus := $1A;
    HexStrFast2(CurPatternIndex, GS2);
    Screen.WriteTextFast2(ScreenPointer + 72, ColorStatus, GS2);
    Screen.WriteTextFast1(ScreenPointer + 74, ColorStatus, '/');
    HexStrFast2(NepperRec.PatternIndices[CurPatternIndex], GS2);
    Screen.WriteTextFast2(ScreenPointer + 75, ColorStatus, GS2);
    Screen.WriteTextFast1(ScreenPointer + 77, ColorStatus, '/');
  end;
  CleanUpStates;
  Move(NepperRec.Instruments[0], Instruments[0], SizeOf(Instruments));
  InstallTimer(50);
  IsPlaying := True;
end;

procedure SetFreq(const Channel: Byte; const Freq: ShortInt);
var
  Reg: PAdlibRegA0B8;
begin
  Reg := @FreqRegs[Channel];
  SetRegFreq(Channel, FreqRegsBack[Channel].Freq + Freq);
  WriteNoteReg(Channel, Reg);
end;

procedure SlideFreq(const Channel: Byte; const Freq: Integer);
var
  Reg: PAdlibRegA0B8;
begin
  Reg := @FreqRegs[Channel];
  ModifyRegFreq(Channel, Freq, CurSpeed);
  if Reg^.Freq > ADLIB_FREQ_TABLE[13] then
  begin
    SetRegFreq(Channel, ADLIB_FREQ_TABLE[1]);
    Reg^.Octave := Reg^.Octave + 1;
  end else
  if Reg^.Freq < ADLIB_FREQ_TABLE[1] then
  begin
    SetRegFreq(Channel, ADLIB_FREQ_TABLE[13]);
    Reg^.Octave := Reg^.Octave - 1;
  end;
  WriteNoteReg(Channel, Reg);
end;

procedure SlideFreqUpdate(const Channel: Byte; const Freq: Integer);
var
  Reg: PAdlibRegA0B8;
begin
  Reg := @FreqRegs[Channel];
  ModifyRegFreq(Channel, Freq, CurSpeed);
  if Reg^.Freq > ADLIB_FREQ_TABLE[13] then
  begin
    SetRegFreq(Channel, ADLIB_FREQ_TABLE[1]);
    Reg^.Octave := Reg^.Octave + 1;
    LastNoteList[Channel].Octave := Reg^.Octave;
    LastNoteList[Channel].Note := 1;
  end else
  if Reg^.Freq < ADLIB_FREQ_TABLE[1] then
  begin
    SetRegFreq(Channel, ADLIB_FREQ_TABLE[13]);
    Reg^.Octave := Reg^.Octave - 1;
    LastNoteList[Channel].Octave := Reg^.Octave;
    LastNoteList[Channel].Note := 13;
  end;
  if LastNoteList[Channel].Octave = LastNoteFutureList[Channel].Octave then
  begin
    if ((Freq < 0) and (Reg^.Freq < ADLIB_FREQ_TABLE[LastNoteFutureList[Channel].Note])) or
       ((Freq > 0) and (Reg^.Freq > ADLIB_FREQ_TABLE[LastNoteFutureList[Channel].Note])) then
    begin
      SetRegFreq(Channel, ADLIB_FREQ_TABLE[LastNoteFutureList[Channel].Note]);
      LastNoteList[Channel] := LastNoteFutureList[Channel];
    end;
  end;
  WriteNoteReg(Channel, Reg);
end;

procedure Play;
  function GetEffectReady: Byte; inline;
  begin
    Result := Byte(Word(PCell^.Effect));
    if Result = 0 then
      Result := Byte(Word(LastEffectList[CurChannel]));
    Word(LastEffectList[CurChannel]) := Result;
    LastEffectList[CurChannel].Effect := PCell^.Effect.Effect;
  end;

  procedure Vibrato;
  begin 
    if CurTicks = 0 then
    begin
      if Byte(PCell^.Note) <> 0 then
        LastNoteTimerList[CurChannel] := 0;
    end;
    if LastEffectList[CurChannel].Effect <> PCell^.Effect.Effect then
      LastNoteTimerList[CurChannel] := 0;
    TmpByte := GetEffectReady;
    SetFreq(CurChannel, SINE_TABLE[LastNoteTimerList[CurChannel] mod (High(SINE_TABLE) + 1)] div ($10 - TNepperEffectValue(TmpByte).V2));
    Inc(LastNoteTimerList[CurChannel], High(SINE_TABLE) div (CurSpeed * 4) * (TNepperEffectValue(TmpByte).V1 + 1));
  end;

  procedure Tremolo;
  begin
    if CurTicks = 0 then
    begin
      if Byte(PCell^.Note) <> 0 then
        LastNoteTimerList[CurChannel] := 0;
    end;
    if LastEffectList[CurChannel].Effect <> PCell^.Effect.Effect then
      LastNoteTimerList[CurChannel] := 0;
    TmpByte := GetEffectReady;
    Short := SINE_TABLE[LastNoteTimerList[CurChannel] mod (High(SINE_TABLE) + 1)] div ($10 - TNepperEffectValue(TmpByte).V2);
    Instruments[PCell^.InstrumentIndex].Operators[0].Volume.Total := Max(Min(Integer(NepperRec.Instruments[PCell^.InstrumentIndex].Operators[0].Volume.Total) + Short, $3F), 0);
    Instruments[PCell^.InstrumentIndex].Operators[1].Volume.Total := Max(Min(Integer(NepperRec.Instruments[PCell^.InstrumentIndex].Operators[1].Volume.Total) + Short, $3F), 0);
    Instruments[PCell^.InstrumentIndex].Operators[2].Volume.Total := Max(Min(Integer(NepperRec.Instruments[PCell^.InstrumentIndex].Operators[2].Volume.Total) + Short, $3F), 0);
    Instruments[PCell^.InstrumentIndex].Operators[3].Volume.Total := Max(Min(Integer(NepperRec.Instruments[PCell^.InstrumentIndex].Operators[3].Volume.Total) + Short, $3F), 0);
    Inc(LastNoteTimerList[CurChannel], High(SINE_TABLE) div (CurSpeed * 4) * (TNepperEffectValue(TmpByte).V1 + 1));
    Adlib.SetInstrument(CurChannel, @Instruments[PCell^.InstrumentIndex]);
  end;

  procedure Tremor;
  begin
    if CurTicks = 0 then
    begin
      if Byte(PCell^.Note) <> 0 then
        LastNoteTimerList[CurChannel] := 0;
    end;
    TmpByte := GetEffectReady;
    I := LastNoteTimerList[CurChannel] mod (TNepperEffectValue(TmpByte).V1 + TNepperEffectValue(TmpByte).V2);
    if I < TNepperEffectValue(TmpByte).V1 then
    begin
      Instruments[PCell^.InstrumentIndex].Operators[0].Volume.Total := NepperRec.Instruments[PCell^.InstrumentIndex].Operators[0].Volume.Total;
      Instruments[PCell^.InstrumentIndex].Operators[1].Volume.Total := NepperRec.Instruments[PCell^.InstrumentIndex].Operators[1].Volume.Total;
      Instruments[PCell^.InstrumentIndex].Operators[2].Volume.Total := NepperRec.Instruments[PCell^.InstrumentIndex].Operators[2].Volume.Total;
      Instruments[PCell^.InstrumentIndex].Operators[3].Volume.Total := NepperRec.Instruments[PCell^.InstrumentIndex].Operators[3].Volume.Total;
    end else
    begin
      Instruments[PCell^.InstrumentIndex].Operators[0].Volume.Total := $3F;
      Instruments[PCell^.InstrumentIndex].Operators[1].Volume.Total := $3F;
      Instruments[PCell^.InstrumentIndex].Operators[2].Volume.Total := $3F;
      Instruments[PCell^.InstrumentIndex].Operators[3].Volume.Total := $3F;
    end;
    Adlib.SetInstrument(CurChannel, @Instruments[PCell^.InstrumentIndex]);
    Inc(LastNoteTimerList[CurChannel]);
  end;

  procedure TonePortamento;
  begin
    TmpByte := GetEffectReady;
    if (LastNoteList[CurChannel].Octave < LastNoteFutureList[CurChannel].Octave) or ((LastNoteList[CurChannel].Octave = LastNoteFutureList[CurChannel].Octave) and (LastNoteList[CurChannel].Note < LastNoteFutureList[CurChannel].Note)) then
      SlideFreqUpdate(CurChannel, TmpByte)
    else
    if (LastNoteList[CurChannel].Octave > LastNoteFutureList[CurChannel].Octave) or ((LastNoteList[CurChannel].Octave = LastNoteFutureList[CurChannel].Octave) and (LastNoteList[CurChannel].Note > LastNoteFutureList[CurChannel].Note)) then
      SlideFreqUpdate(CurChannel, -TmpByte);
  end;

  procedure FreqSlideUp;
  begin
    TmpByte := GetEffectReady;
    SlideFreq(CurChannel, TmpByte);
  end;

  procedure FreqSlideDown;
  begin
    TmpByte := GetEffectReady;
    SlideFreq(CurChannel, -TmpByte);
  end;

label
  AtBeginning;
begin
  // Is playing?
  if not IsPlaying then
    Exit;
  // Playing

  // Pre Effect
AtBeginning:
  for CurChannel := 0 to NepperRec.ChannelCount - 1 do
  begin
    PChannel := @PPattern^[CurChannel];
    PCell := @PChannel^.Cells[CurCell];
    PInstrument := @Instruments[PCell^.InstrumentIndex];
    if Word(PCell^.Effect) <> 0 then
    begin
      case Char(PCell^.Effect.Effect) of
        '0', #0: // Arpeggio
          begin
            if (CurTicks = 0) and (Byte(Word(PCell^.Effect)) <> 0) and (Byte(PCell^.Note) <> 0) then
            begin
              LastArpeggioList[CurChannel, 0] := PCell^.Effect.V1;
              LastArpeggioList[CurChannel, 1] := PCell^.Effect.V2;
            end;
          end;
        '4': // Vibrato
          begin
            Vibrato;
          end;
        '9': // Volume
          begin
            if CurTicks = 0 then
            begin
              Adlib.VolumeModList[CurChannel] := 0;
              TmpByte := $3F - Max(Min(Byte(Word(PCell^.Effect)), $3F), 0);
              Instruments[PCell^.InstrumentIndex].Operators[0].Volume.Total := TmpByte;
              Instruments[PCell^.InstrumentIndex].Operators[1].Volume.Total := TmpByte;
              Instruments[PCell^.InstrumentIndex].Operators[2].Volume.Total := TmpByte;
              Instruments[PCell^.InstrumentIndex].Operators[3].Volume.Total := TmpByte;
              Adlib.SetInstrument(CurChannel, @Instruments[PCell^.InstrumentIndex]);
            end;
          end;
        'A': // Volume slide
          begin
            if CurTicks = 0 then
            begin
              TmpByte := GetEffectReady;
              Inc(Adlib.VolumeModList[CurChannel], TNepperEffectValue(TmpByte).V1 - TNepperEffectValue(TmpByte).V2);
              Adlib.VolumeModList[CurChannel] := Max(Min(Adlib.VolumeModList[CurChannel], 63), -63);
              Adlib.SetInstrument(CurChannel, @Instruments[PCell^.InstrumentIndex]);
            end;
          end;
        'D': // Pattern break
          begin
            if CurTicks = 0 then
              CurCell := $40;
          end;
        'E': // BPM
          begin
            if CurTicks = 0 then
              InstallTimer(Byte(Word(PCell^.Effect)));
          end;
        'F': // Speed
          begin
            if CurTicks = 0 then
              CurSpeed := Byte(Word(PCell^.Effect));
          end;
        'M': // Tremolo
          begin
            Tremolo;
          end;
        'N': // Tremor
          begin
            Tremor;
          end;
        'Z':
          begin
            if CurTicks = 0 then
            begin
              case Byte(Word(PCell^.Effect)) of
                $F0: // Stop note
                  begin
                    Adlib.NoteClear(CurChannel);
                    Word(LastEffectList[CurChannel]) := 0;
                  end;
                $F4: // Fade note
                  begin
                    Adlib.NoteOff(CurChannel);
                    Word(LastEffectList[CurChannel]) := 0;
                  end;
              end;
            end;
          end;
      end;
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
  // Play note
  for CurChannel := 0 to NepperRec.ChannelCount - 1 do
  begin
    if not ChannelEnabledList[CurChannel] then
    begin
      if not IsInstr then
        Adlib.NoteClear(CurChannel);
      Continue;
    end;
    if CurTicks = LastNoteDelayList[CurChannel] then
    begin
      PChannel := @PPattern^[CurChannel];
      PCell := @PChannel^.Cells[CurCell];
      PInstrument := @Instruments[PCell^.InstrumentIndex];
      // Note
      if Byte(PCell^.Note) <> 0 then
      begin
        if Char(PCell^.Effect.Effect) <> '3' then
        begin
          if IsInstr then
          begin
            Instruments[PCell^.InstrumentIndex] := NepperRec.Instruments[PCell^.InstrumentIndex];
            Adlib.SetInstrument(CurChannel, @Instruments[PCell^.InstrumentIndex]);
          end else
          begin
            //if LastInstrumentList[CurChannel] <> PCell^.InstrumentIndex then
            begin
              Adlib.SetInstrument(CurChannel, @Instruments[PCell^.InstrumentIndex]);
              LastInstrumentList[CurChannel] := PCell^.InstrumentIndex;
            end;
          end;
          LastNoteList[CurChannel] := PCell^.Note;
          Byte(LastNoteFutureList[CurChannel]) := 0;
          Adlib.NoteOn(CurChannel, PCell^.Note.Note, PCell^.Note.Octave, PInstrument^.FineTune);
          Screen.WriteTextFast1(ScreenPointer + 63 + CurChannel, $10 + PCell^.Note.Note + 1, #4);
        end else
        begin
          // Tone portamento
          LastNoteFutureList[CurChannel] := PCell^.Note;
        end;
      end else
        Screen.WriteTextFast1(ScreenPointer + 63 + CurChannel, $1F, ' ');
    end;
  end;
  //
  if CurTicks = 0 then
  begin
    HexStrFast2(CurCell, GS2);
    Screen.WriteTextFast2(ScreenPointer + 78, ColorStatus, GS2);
  end;
  // Post Effect
  for CurChannel := 0 to NepperRec.ChannelCount - 1 do
  begin
    PChannel := @PPattern^[CurChannel];
    PCell := @PChannel^.Cells[CurCell];
    PInstrument := @Instruments[PCell^.InstrumentIndex];
    if Word(PCell^.Effect) <> 0 then
    begin
      case Char(PCell^.Effect.Effect) of
        '1': // Freq slide up
          begin
            FreqSlideUp;
          end;
        '2': // Freq slide down
          begin
            FreqSlideDown;
          end;
        '3': // Tone portamento
          begin
            if not ChannelEnabledList[CurChannel] then
            begin
              Continue;
            end else
            begin
              TonePortamento;
            end;
          end;
      end;
    end;
  end;
  //
  Inc(CurTicks);
  if CurTicks >= CurSpeed then
  begin
    CurTicks := 0;
    // Change to next PPattern
    if CurCell >= $3F then
    begin
      if IsPatternOnly then
      begin
        CurCell := 0;
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
        HexStrFast2(CurPatternIndex, GS2);
        Screen.WriteTextFast2(ScreenPointer + 72, ColorStatus, GS2);
        Screen.WriteTextFast1(ScreenPointer + 74, ColorStatus, '/');
        HexStrFast2(NepperRec.PatternIndices[CurPatternIndex], GS2);
        Screen.WriteTextFast2(ScreenPointer + 75, ColorStatus, GS2);
        Screen.WriteTextFast1(ScreenPointer + 77, ColorStatus, '/');
      end;
      goto AtBeginning;
    end else
      Inc(CurCell);
  end;
end;

procedure Stop;
var
  BlankInstr: TAdlibInstrument;
begin
  IsPlaying := False;
  FillChar(BlankInstr, SizeOf(BlankInstr), 0);
  for I := 0 to 8 do
  begin
    Adlib.SetInstrument(I, @BlankInstr);
    Adlib.NoteClear(I);
  end;
  CleanUpStates;
  Screen.WriteText(63, 0, $1F, '', 17);
end;

initialization
  for I := 0 to High(ChannelEnabledList) do
    ChannelEnabledList[I] := True;

end.

