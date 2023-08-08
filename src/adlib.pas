unit Adlib;

{$mode objFPC}

interface

const
  ADLIB_PORT_STATUS = $0388;
  ADLIB_MODULATOR = 0;
  ADLIB_CARRIER = 1;
  ADLIB_MAX_OCTAVE = 8;
  MAX_CHANNELS = 9;

  ADLIB_SLOTS_OPL2: array[0..MAX_CHANNELS - 1, 0..1] of Byte = (
    ($00, $03),
    ($01, $04),
    ($02, $05),
    ($08, $0B),
    ($09, $0C),
    ($0A, $0D),
    ($10, $13),
    ($11, $14),
    ($12, $15)
  );

  ADLIB_SLOTS_OPL3: array[0..MAX_CHANNELS - 1, 0..3] of Word = (
    ($000, $003, $008, $00B),
    ($001, $004, $009, $00C),
    ($002, $005, $00A, $00D),
    ($010, $013, $0FF, $0FF),
    ($011, $014, $0FF, $0FF),
    ($012, $015, $0FF, $0FF),
    ($100, $103, $108, $10B),
    ($101, $104, $109, $10C),
    ($102, $105, $10A, $10D)
  );

  ADLIB_CHANNELS_OPL3: array[0..MAX_CHANNELS - 1] of Word = (
    0, 1, 2, 6, 7, 8, $100, $101, $102
  );

  // Music Frequency * 2^(20-Block) / 49716 Hz
  ADLIB_FREQ_TABLE: array[1..13] of Word = (
    $159, $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2B1
  );

  ADLIB_NOTESYM_TABLE: array[1..12] of String[2] = (
    'C-',
    'C#',
    'D-',
    'D#',
    'E-',
    'F-',
    'F#',
    'G-',
    'G#',
    'A-',
    'A#',
    'B-'
  );

type
  TBit1 = 0..1;
  TBit2 = 0..3;
  TBit3 = 0..7;
  TBit4 = 0..15;
  TBit5 = 0..31;
  TBit6 = 0..63;
  TBit7 = 0..127;
  TBit10 = 0..1023;

  TAdlibReg2035 = bitpacked record
    ModFreqMult: TBit4;
    KSR: TBit1;
    EGTyp: TBit1;
    Vib: TBit1;
    AmpMod: TBit1;
  end;

  TAdlibReg4055 = bitpacked record
    Total: TBit6;
    Scaling: TBit2;
  end;

  TAdlibReg6075 = bitpacked record
    Decay: TBit4;
    Attack: TBit4;
  end;

  TAdlibReg8095 = bitpacked record
    Release: TBit4;
    Sustain: TBit4;
  end;

  PAdlibRegA0B8 = ^TAdlibRegA0B8;
  TAdlibRegA0B8 = bitpacked record
    Freq: TBit10;
    Octave: TBit3;
    KeyOn: TBit1;
    Unused: TBit2;
  end;

  TAdlibRegC0C8 = bitpacked record
    Alg: TBit1;
    Feedback: TBit3;
    Panning: TBit2;
    Alg2: TBit2;
  end;

  TAdlibRegBD = bitpacked record
    HiHat: TBit1;
    Cymbal: TBit1;
    TomTom: TBit1;
    Snare: TBit1;
    Drum: TBit1;
    Rhymth: TBit1;
    Vibrato: TBit1;
    AMDepth: TBit1;
  end;

  TAdlibRegE0F5 = bitpacked record
    Waveform: TBit3;
    Unused: TBit5;
  end;

  PAdlibInstrumentOperator = ^TAdlibInstrumentOperator;
  TAdlibInstrumentOperator = packed record
    Effect: TAdlibReg2035;
    Volume: TAdlibReg4055;
    AttackDecay: TAdlibReg6075;
    SustainRelease: TAdlibReg8095;
    Waveform: TAdlibRegE0F5;
  end;

  PAdlibInstrument = ^TAdlibInstrument;
  TAdlibInstrument = packed record
    Operators: array[0..3] of TAdlibInstrumentOperator; // 4 operators
    AlgFeedback: TAdlibRegC0C8;
    FineTune: ShortInt;
    Is4Op: Boolean;
    Name: String[20];
  end;

var
  VolumeModList: array[0..MAX_CHANNELS - 1] of ShortInt;
  FreqRegs: array[0..MAX_CHANNELS - 1] of TAdlibRegA0B8;
  FreqRegsBack: array[0..MAX_CHANNELS - 1] of TAdlibRegA0B8;
  FreqPrecisionList: array[0..MAX_CHANNELS - 1] of DWord;
  IsOPL3Avail: Boolean = False;
  IsOPL3Enabled: Boolean;

function Check: Boolean;
procedure Init;
procedure Reset;
procedure SetInstrument(const Channel: Byte; const Inst: PAdlibInstrument);
procedure NoteOn(const Channel, Note, Octave: Byte; const FineTune: ShortInt = 0);
procedure NoteOff(const Channel: Byte);
procedure NoteClear(const Channel: Byte);
procedure SetRegFreq(const Channel: Byte; const Freq: Word); inline;
procedure ModifyRegFreq(const Channel: Byte; const Freq: Integer; const Ticks: Byte); inline;
procedure WriteReg(const Reg: Word; Value: Byte);
procedure WriteNoteReg(const Channel: Byte; const Reg: PAdlibRegA0B8);
procedure SetOPL3(const V: Byte);

implementation

uses
  Utils;

procedure WriteReg(const Reg: Word; Value: Byte); assembler;
asm
  mov ax,Reg
  mov dx,ADLIB_PORT_STATUS
  or  ah,ah
  jz  @Pri
  inc dx
  inc dx
@Pri:
  out dx,al
  // wait at least 3.3us
  in al,dx; in al,dx; in al,dx; in al,dx; in al,dx; in al,dx;
  //
  inc dx
  mov al,Value
  out dx,al
  dec dx
  // wait at least 23us
  in al,dx; in al,dx; in al,dx; in al,dx; in al,dx; in al,dx;
  in al,dx; in al,dx; in al,dx; in al,dx; in al,dx; in al,dx;
  in al,dx; in al,dx; in al,dx; in al,dx; in al,dx; in al,dx;
  in al,dx; in al,dx; in al,dx; in al,dx; in al,dx; in al,dx;
  in al,dx; in al,dx; in al,dx; in al,dx; in al,dx; in al,dx;
  in al,dx; in al,dx; in al,dx; in al,dx; in al,dx;
end;

procedure WriteRegFast(const Reg: Word; Value: Byte); assembler;
asm
  mov ax,Reg
  mov dx,ADLIB_PORT_STATUS
  or  ah,ah
  jz  @Pri
  inc dx
  inc dx
@Pri:
  out dx,al
  // wait a bit
  in al,dx; in al,dx;
  //
  inc dx
  mov al,Value
  out dx,al
  dec dx
  // wait a bit
  in al,dx; in al,dx;
end;

function Chan(const C: Byte): Word; inline;
begin
  if IsOPL3Enabled then
    Result := ADLIB_CHANNELS_OPL3[C]
  else
    Result := C;
end;

procedure SetInstrument(const Channel: Byte; const Inst: PAdlibInstrument);
var
  I: Byte;
  C: Word;
  Op: PAdlibInstrumentOperator;
  Volume: TAdlibReg4055;
  VolumeTmp: ShortInt;
  Alg2: TAdlibRegC0C8;

  procedure AdjustVolume(const V: Byte);
  begin
    if IsOPL3Enabled and ((Channel <= 2) or (Channel >= 6)) then
      case Inst^.AlgFeedback.Alg2 of
        0:
          begin     
            if I = 3 then
              Volume.Total := V;
          end;
        1:
          begin
            if (I = 0) or (I = 3) then
              Volume.Total := V;
          end;
        2:
          begin     
            if (I = 1) or (I = 3) then
              Volume.Total := V;
          end;
        3:
          begin    
            if (I = 0) or (I = 2) or (I = 3) then
              Volume.Total := V;
          end;
      end
    else
      case Inst^.AlgFeedback.Alg2 of
        0:
          begin    
            if (I = 0) or (I = 1) then
              Volume.Total := V;
          end;
        1:
          begin         
            if I = 1 then
              Volume.Total := V;
          end;
      end;
  end;

begin
  if IsOPL3Enabled then
  begin
    C := Chan(Channel);
    for I := 0 to 3 do
    begin
      Op := @Inst^.Operators[I];
      Volume := Op^.Volume;
      VolumeTmp := Min(Max(Volume.Total - VolumeModList[Channel], 0), 63);
      AdjustVolume(VolumeTmp);

      if ADLIB_SLOTS_OPL3[Channel, I] <> $FF then
      begin
        WriteRegFast(ADLIB_SLOTS_OPL3[Channel, I] + $20, Byte(Op^.Effect));
        WriteRegFast(ADLIB_SLOTS_OPL3[Channel, I] + $40, Byte(Volume));
        WriteRegFast(ADLIB_SLOTS_OPL3[Channel, I] + $60, Byte(Op^.AttackDecay));
        WriteRegFast(ADLIB_SLOTS_OPL3[Channel, I] + $80, Byte(Op^.SustainRelease));
        WriteRegFast(ADLIB_SLOTS_OPL3[Channel, I] + $E0, Byte(Op^.Waveform));
      end;
    end;
    Inst^.AlgFeedback.Alg := Inst^.AlgFeedback.Alg2;
    WriteRegFast(C + $C0, Byte(Inst^.AlgFeedback));
    if (Byte(C) < 6) or (Byte(C) > 8) then
    begin
      Alg2.Alg := Inst^.AlgFeedback.Alg2 shr 1;
      WriteRegFast(C + 3 + $C0, Byte(Alg2));
    end;
  end else
  begin
    for I := 0 to 1 do
    begin
      Op := @Inst^.Operators[I];
      Volume := Op^.Volume;
      VolumeTmp := Min(Max(Volume.Total - VolumeModList[Channel], 0), 63);
      AdjustVolume(VolumeTmp);

      WriteReg(ADLIB_SLOTS_OPL2[Channel, I] + $20, Byte(Op^.Effect));
      WriteReg(ADLIB_SLOTS_OPL2[Channel, I] + $40, Byte(Volume));
      WriteReg(ADLIB_SLOTS_OPL2[Channel, I] + $60, Byte(Op^.AttackDecay));
      WriteReg(ADLIB_SLOTS_OPL2[Channel, I] + $80, Byte(Op^.SustainRelease));
      WriteReg(ADLIB_SLOTS_OPL2[Channel, I] + $E0, Byte(Op^.Waveform));
    end;
    Inst^.AlgFeedback.Alg := Inst^.AlgFeedback.Alg2;
    WriteReg(Channel + $C0, Byte(Inst^.AlgFeedback));
  end;
end;

function Check: Boolean;
var
  S1, S2: Byte;
begin
  // We simply check adlib card's existence by making timer 1's register overflow,
  // then check for bit 6 & 7 in time control register
  WriteReg($04, $60); // Reset both timers
  WriteReg($04, $80); // Enable timer interrupt
  S1 := Port[ADLIB_PORT_STATUS];
  WriteReg($02, $FF);                   
  WriteReg($04, $21); // Start timer 1
  S2 := Port[ADLIB_PORT_STATUS];
  WriteReg($04, $60);
  WriteReg($04, $80);
  S1 := S1 and $E0;
  S2 := S2 and $E0;
  if (S1 = $00) and (S2 = $C0) then
    Check := True;
  if Port[ADLIB_PORT_STATUS] and 6 = 0 then
    IsOPL3Avail := True;
end;

procedure Init;
var
  BD: TAdlibRegBD;
begin
  Reset;
  BD.AMDepth := 1;
  BD.Vibrato := 1;
  WriteReg($BD, Byte(BD));
end;

procedure Reset;
var
  I: Byte;
begin
  for I := 0 to 245 do
    WriteReg(I, 0);
  if IsOPL3Avail then
    for I := 0 to 245 do
      WriteReg($100 + I, 0);
end;

procedure WriteNoteReg(const Channel: Byte; const Reg: PAdlibRegA0B8);
var
  C: Word;
begin  
  C := Chan(Channel);
  WriteReg($A0 + C, Lo(Word(Reg^)));
  WriteReg($B0 + C, Hi(Word(Reg^)));
end;

procedure NoteOn(const Channel, Note, Octave: Byte; const FineTune: ShortInt = 0);
var
  N: PAdlibRegA0B8;
  C: Word;
begin
  C := Chan(Channel);
  N := @FreqRegs[Channel];  
  N^.KeyOn := 0;
  WriteReg($B0 + C, Hi(Word(N^)));
  N^.Freq := ADLIB_FREQ_TABLE[Note] + FineTune;
  N^.Octave := Octave;
  N^.KeyOn := 1;   
  FreqPrecisionList[Channel] := DWord(N^.Freq) shl 8;
  WriteReg($A0 + C, Lo(Word(N^)));
  WriteReg($B0 + C, Hi(Word(N^)));
  FreqRegsBack[Channel] := N^;
end;

procedure NoteOff(const Channel: Byte);
var
  C: Word;
  N: PAdlibRegA0B8;
begin 
  C := Chan(Channel);
  N := @FreqRegs[Channel];
  N^.KeyOn := 0;
  WriteReg($B0 + C, Hi(Word(N^)));
end;

procedure NoteClear(const Channel: Byte);   
var
  C: Word;
begin
  C := Chan(Channel);
  WriteReg($A0 + C, 0);
  WriteReg($B0 + C, 0);
end;

procedure SetRegFreq(const Channel: Byte; const Freq: Word);
begin
  FreqPrecisionList[Channel] := DWord(Freq) shl 8;
  FreqRegs[Channel].Freq := FreqPrecisionList[Channel] shr 8;
end;

procedure ModifyRegFreq(const Channel: Byte; const Freq: Integer; const Ticks: Byte);
begin
  Inc(FreqPrecisionList[Channel], (Freq shl 8) div Ticks);
  FreqRegs[Channel].Freq := FreqPrecisionList[Channel] shr 8;
end;

procedure SetOPL3(const V: Byte);
begin
  WriteReg($105, V);
  WriteReg($104, $3F);
  IsOPL3Enabled := Boolean(V);
end;

initialization 
  if not Adlib.Check then
  begin
    Writeln('ERROR: AdLib sound card not found!');
    Halt;
  end;
  if Adlib.IsOPL3Avail then
    Writeln('OPL3 found!');
  FillChar(VolumeModList[0], SizeOf(VolumeModList), 0);

end.

