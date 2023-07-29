unit Formats;

{$mode ObjFPC}

interface

uses
  Adlib;

const
  SONG_HALT = $FF;
  SONG_REPEAT = $FE;

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

  PNepperChannelCell = ^TNepperChannelCell;
  TNepperChannelCell = packed record
    Note  : TNepperNote;
    Effect: TNepperEffect;
  end;

  PNepperChannelCells = ^TNepperChannelCells;
  TNepperChannelCells = array[0..$3F] of TNepperChannelCell;

  PNepperChannel = ^TNepperChannel;
  TNepperChannel = packed record
    InstrumentIndex: Byte;
    Cells: TNepperChannelCells;
  end;

  PNepperPattern = ^TNepperPattern;
  TNepperPattern = array[0..7] of TNepperChannel;

  TNepperRec = packed record
    Magic: DWord;
    Name: String[40];
    IsOPL3: Boolean;
    ChannelCount: ShortInt;
    Instruments: array[0..31] of TAdlibInstrument;
    PatternIndices: array[0..$FF] of Byte;
  end;

var
  NepperRec: TNepperRec;
  Patterns: array[0..$3F] of PNepperPattern;

procedure SaveInstrument(const FileName: String; const Inst: PAdlibInstrument);
function LoadInstrument(const FileName: String; const Inst: PAdlibInstrument): Boolean;
procedure SaveSong(const FileName: String);
function LoadSong(const FileName: String): Boolean;

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

procedure SaveSong(const FileName: String);
begin

end;

function LoadSong(const FileName: String): Boolean;
begin
  Result := False;
end;

var
  I: Byte;

initialization
  FillChar(NepperRec.Magic, SizeOf(NepperRec), 0);
  for I := 0 to High(Formats.Patterns) do
  begin
    New(Formats.Patterns[I]);
    FillChar(Formats.Patterns[I]^[0], SizeOf(TNepperPattern), 0);
  end;
  NepperRec.ChannelCount := 8;

finalization
  for I := 0 to High(Formats.Patterns) do
    Dispose(Formats.Patterns[I]);

end.

