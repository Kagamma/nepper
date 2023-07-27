unit Adlib;

{$mode objFPC}

interface

const
  ADLIB_PORT_STATUS = $0388;
  ADLIB_PORT_DATA = $0389;
  ADLIB_MODULATOR = 0;
  ADLIB_CARRIER = 1;
  ADLIB_MAX_OCTAVE = 8;

  ADLIB_SLOTS: array[0..8, 0..1] of Byte = (
    ($00, $03),
    ($01, $04),
    ($02, $05),
    ($08, $0B),
    ($09, $0C),
    ($0a, $0D),
    ($10, $13),
    ($11, $14),
    ($12, $15)
  );

  // Music Frequency * 2^(20-Block) / 49716 Hz
  ADLIB_FREQ_TABLE: array[0..12] of Word = (
    $159, $16B, $181, $198, $1B0, $1CA, $1E5, $202, $220, $241, $263, $287, $2B1
  );

  ADLIB_NOTESYM_TABLE: array[0..11] of String[2] = ( 
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
    Unused: TBit4;
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
    Waveform: TBit2;
    Unused: TBit6;
  end;

  PAdlibInstrumentOperator = ^TAdlibInstrumentOperator;
  TAdlibInstrumentOperator = record
    Effect: TAdlibReg2035;
    Volume: TAdlibReg4055;
    AttackDecay: TAdlibReg6075;
    SustainRelease: TAdlibReg8095;
    Waveform: TAdlibRegE0F5;
  end;

  PAdlibInstrument = ^TAdlibInstrument;
  TAdlibInstrument = record
    Operators: array[0..3] of TAdlibInstrumentOperator; // 4 operators
    AlgFeedback: TAdlibRegC0C8;
    PitchShift: Byte;
    Name: String[20];
  end;

var
  FreqRegs: array[0..8] of TAdlibRegA0B8;

function Check: Boolean;
procedure Init;
procedure Reset;
procedure SetInstrument(const Channel: Byte; const Inst: PAdlibInstrument);
procedure NoteOn(const Channel, Note, Octave: Byte);
procedure NoteOff(const Channel: Byte);
procedure WriteReg(const Reg, Value: Byte);

implementation

procedure WriteReg(const Reg, Value: Byte); assembler;
asm
  mov al,Reg
  mov dx,ADLIB_PORT_STATUS
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

procedure SetInstrument(const Channel: Byte; const Inst: PAdlibInstrument);
var
  I: Byte;
  Params: PAdlibInstrumentOperator;
begin
  for I := 0 to 1 do
  begin
    Params := @Inst^.Operators[I];
    WriteReg(ADLIB_SLOTS[Channel, I] + $20, Byte(Params^.Effect));
    WriteReg(ADLIB_SLOTS[Channel, I] + $40, Byte(Params^.Volume));
    WriteReg(ADLIB_SLOTS[Channel, I] + $60, Byte(Params^.AttackDecay));
    WriteReg(ADLIB_SLOTS[Channel, I] + $80, Byte(Params^.SustainRelease));
    WriteReg(ADLIB_SLOTS[Channel, I] + $E0, Byte(Params^.Waveform));
  end;
  WriteReg(Channel + $C0, Byte(Inst^.AlgFeedback));
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
  //Delay(10);
  S2 := Port[ADLIB_PORT_STATUS];
  WriteReg($04, $60);
  WriteReg($04, $80);
  S1 := S1 and $E0;
  S2 := S2 and $E0;
  if (S1 = $00) and (S2 = $C0) then
    Check := True;
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
end;

procedure NoteOn(const Channel, Note, Octave: Byte);
var
  N: PAdlibRegA0B8;
begin
  N := @FreqRegs[Channel];
  N^.Freq := ADLIB_FREQ_TABLE[Note];
  N^.Octave := Octave;
  N^.KeyOn := 1;
  WriteReg($B0 + Channel, 0);
  WriteReg($A0 + Channel, Lo(Word(N^)));
  WriteReg($B0 + Channel, Hi(Word(N^)));
end;

procedure NoteOff(const Channel: Byte);
begin                    
  WriteReg($A0 + Channel, 0);
  WriteReg($B0 + Channel, 0);
end;

end.

