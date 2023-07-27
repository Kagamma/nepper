unit Formats;

{$mode ObjFPC}

interface

uses
  Adlib;

type
  TNepperNote = record
    Note: TBit4;
    Octave: TBit4;
  end;

  TNepperEffect = record
    V2: TBit4;
    V1: TBit4;
    Effect: TBit4;
    Unused: TBit4;
  end;

  TNepperChannelCell = record
    Note  : TNepperNote;
    Effect: TNepperEffect;
  end;

  TNepperChannel = array[0..$3F] of TNepperChannelCell;

  TNepperPattern = array[0..7] of TNepperChannel;

  TNepperRec = record
    Name: String[20];
    ChannelCount: Byte;
    Instruments: array[0..31] of TAdlibInstrument;
    Patterns: array[0..$F] of TNepperPattern;
  end;

var
  NepperRec: TNepperRec;

procedure SaveInstrument(const FileName: String; const Inst: PAdlibInstrument);
procedure LoadInstrument(const FileName: String; const Inst: PAdlibInstrument);

implementation

procedure SaveInstrument(const FileName: String; const Inst: PAdlibInstrument);
var
  F: File of TAdlibInstrument;
begin
  Assign(F, FIleName);
  Rewrite(F);
  Write(F, Inst^);
  Close(F);
end;

procedure LoadInstrument(const FileName: String; const Inst: PAdlibInstrument);
var
  F: File of TAdlibInstrument;
begin
  Assign(F, FIleName);
  {$I-}
  System.Reset(F);
  {$I+}
  if IOResult = 0 then
  begin
    Read(F, Inst^);
    Close(F);
  end;
end;

end.

