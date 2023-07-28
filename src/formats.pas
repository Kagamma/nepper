unit Formats;

{$mode ObjFPC}

interface

uses
  Adlib;

type
  TNepperNote = bitpacked record
    Note: TBit4;
    Octave: TBit4;
  end;

  TNepperEffect = bitpacked record
    V2: TBit4;
    V1: TBit4;
    Effect: TBit4;
    Unused: TBit4;
  end;

  TNepperChannelCell = record
    Note  : TNepperNote;
    Effect: TNepperEffect;
  end;

  PNepperChannel = ^TNepperChannel;
  TNepperChannel = array[0..$3F] of TNepperChannelCell;

  PNepperPattern = ^TNepperPattern;
  TNepperPattern = array[0..7] of TNepperChannel;

  TNepperRec = record
    Name: String[40];
    ChannelCount: ShortInt;
    Instruments: array[0..31] of TAdlibInstrument;
    PatternIndices: array[0..$FF] of Byte;
    Patterns: array[0..$3F] of PNepperPattern;
  end;

var
  NepperRec: TNepperRec;

procedure SaveInstrument(const FileName: String; const Inst: PAdlibInstrument);
function LoadInstrument(const FileName: String; const Inst: PAdlibInstrument): Boolean;

implementation

procedure SaveInstrument(const FileName: String; const Inst: PAdlibInstrument);
var
  F: File of TAdlibInstrument;
begin
  if FileName = '' then
    Exit;
  Assign(F, FileName);
  Rewrite(F);
  Write(F, Inst^);
  Close(F);
end;

function LoadInstrument(const FileName: String; const Inst: PAdlibInstrument): Boolean;
var
  F: File of TAdlibInstrument;
begin
  Result := False;
  if FileName = '' then
    Exit;
  Assign(F, FileName);
  {$I-}
  System.Reset(F);
  {$I+}
  if IOResult = 0 then
  begin
    Read(F, Inst^);
    Close(F);
    Result := True;
  end;
end;

var
  I: Byte;

initialization
  FillChar(NepperRec.Name[1], SizeOf(NepperRec), 0);
  for I := 0 to High(NepperRec.Patterns) do
  begin
    New(NepperRec.Patterns[I]);
  end;
  NepperRec.ChannelCount := 4;

finalization
  for I := 0 to High(NepperRec.Patterns) do
    Dispose(NepperRec.Patterns[I]);

end.

