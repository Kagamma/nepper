unit Formats;

{$mode ObjFPC}

interface

uses
  Adlib;

const
  SONG_MAGIC = $B00B;
  SONG_VERSION = 1;
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
    Magic: Word;
    Version: Byte;
    Name: String[40];
    IsOPL3: Boolean;
    ChannelCount: ShortInt;
    Instruments: array[0..31] of TAdlibInstrument;
    PatternIndices: array[0..$FF] of Byte;
  end;

var
  NepperRec: TNepperRec;
  Patterns: array[0..$3F] of PNepperPattern;

procedure SaveInstrument(FileName: String; const Inst: PAdlibInstrument);
function LoadInstrument(FileName: String; const Inst: PAdlibInstrument): Boolean;
procedure SaveSong(FileName: String);
function LoadSong(FileName: String): Boolean;

implementation

uses
  Utils;

procedure SaveInstrument(FileName: String; const Inst: PAdlibInstrument);
var
  F: File of TAdlibInstrument;
begin 
  if FindCharPos(FileName, '.') = 0 then
    FileName := FileName + '.nis';
  if FileName = '' then
    Exit;
  Assign(F, FileName);
  Rewrite(F);
  Write(F, Inst^);
  Close(F);
end;

function LoadInstrument(FileName: String; const Inst: PAdlibInstrument): Boolean;
var
  F: File of TAdlibInstrument;
begin
  if FindCharPos(FileName, '.') = 0 then
    FileName := FileName + '.nis';
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

procedure SaveSong(FileName: String);
begin
  if FindCharPos(FileName, '.') = 0 then
    FileName := FileName + '.ntr';
end;

function LoadSong(FileName: String): Boolean;
begin
  if FindCharPos(FileName, '.') = 0 then
    FileName := FileName + '.ntr';
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

