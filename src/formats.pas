unit Formats;

{$mode ObjFPC}

interface

uses
  Adlib;

const
  INSTRUMENT_MAGIC = $BAB0;
  SONG_MAGIC = $0BB0;
  SONG_VERSION = 1;
  SONG_HALT = $FF;
  SONG_REPEAT = $FE;

type
  TNepperNote = bitpacked record
    Note: TBit4;
    Octave: TBit4;
  end;

  TNepperEffectValue = bitpacked record
    V2: TBit4;
    V1: TBit4;
  end;

  TNepperEffect = bitpacked record
    V2: TBit4;
    V1: TBit4;
    Effect: Byte;
  end;

  PNepperChannelCell = ^TNepperChannelCell;
  TNepperChannelCell = packed record
    Note  : TNepperNote;
    Effect: TNepperEffect;
    InstrumentIndex: Byte;
  end;

  PNepperChannelCells = ^TNepperChannelCells;
  TNepperChannelCells = array[0..$3F] of TNepperChannelCell;

  PNepperChannel = ^TNepperChannel;
  TNepperChannel = packed record
    Cells: TNepperChannelCells;
  end;

  PNepperPattern = ^TNepperPattern;
  TNepperPattern = array[0..MAX_CHANNELS - 1] of TNepperChannel;

  TNepperRec = packed record  
    Magic: Word;
    Version: Byte;
    Name: String[40];
    Speed: Byte;
    Clock: Byte;
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
  Utils, Player, Timer;

type
  TNepperInstrumentHeader = packed record
    Magic: Word;
    Version: Byte;
  end;

procedure SaveInstrument(FileName: String; const Inst: PAdlibInstrument);
var
  H: TNepperInstrumentHeader;
  F: File;
begin
  if FileName = '' then
    Exit;
  if FindCharPos(FileName, '.') = 0 then
    FileName := FileName + '.nis';
  Assign(F, FileName);
  Rewrite(F, 1);
  H.Magic := INSTRUMENT_MAGIC;
  H.Version := 1;
  BlockWrite(F, H.Magic, SizeOf(TNepperInstrumentHeader));
  BlockWrite(F, Inst^.Operators[0], SizeOf(TAdlibInstrument));
  Close(F);
end;

function LoadInstrument(FileName: String; const Inst: PAdlibInstrument): Boolean;
var
  H: TNepperInstrumentHeader;
  F: File;
begin     
  Result := False;
  if FileName = '' then
    Exit;
  if FindCharPos(FileName, '.') = 0 then
    FileName := FileName + '.nis';
  Assign(F, FileName);
  {$I-}
  System.Reset(F, 1);
  {$I+}
  if IOResult = 0 then
  begin
    BlockRead(F, H.Magic, SizeOf(TNepperInstrumentHeader));
    if H.Magic <> INSTRUMENT_MAGIC then
    begin
      Close(F);
      Exit;
    end;
    BlockRead(F, Inst^.Operators[0], SizeOf(TAdlibInstrument));
    Close(F);
    Result := True;
  end;
end;

procedure SaveSong(FileName: String);
var
  F: File;
  I, J, K: Byte;
  IsDirty: Boolean;
begin
  if FindCharPos(FileName, '.') = 0 then
    FileName := FileName + '.ntr';
  if FileName = '' then
    Exit;
  if FindCharPos(FileName, '.') = 0 then
    FileName := FileName + '.nis';
  Assign(F, FileName);
  Rewrite(F, 1);
  NepperRec.Magic := SONG_MAGIC;
  NepperRec.Version := 1;
  BlockWrite(F, NepperRec, SizeOf(TNepperRec));
  for I := 0 to High(Formats.Patterns) do
  begin
    for J := 0 to NepperRec.ChannelCount - 1 do
    begin
      IsDirty := False;
      for K := 0 to $3F do
      begin
        if (Byte(Formats.Patterns[I]^[J].Cells[K].Note) <> 0) or
           (Word(Formats.Patterns[I]^[J].Cells[K].Effect) <> 0) then
        begin
          IsDirty := True;
          Break;
        end;
      end;
      if IsDirty then
      begin                                                        
        BlockWrite(F, I, 1);
        BlockWrite(F, J, 1);
        BlockWrite(F, K, 1);
        BlockWrite(F, Formats.Patterns[I]^[J].Cells[K], SizeOf(TNepperChannelCells) - K);
      end;
    end;
  end;
  Close(F);
end;

function LoadSong(FileName: String): Boolean; 
var
  F: File;

  // Nepper's TRack
  function LoadNTR: Boolean;
  var
    I, J, K: Byte;
    H: TNepperRec;
  begin
    Result := False;
    BlockRead(F, H, SizeOf(TNepperRec));
    if H.Magic <> SONG_MAGIC then
      Exit;

    NepperRec := H;
    for I := 0 to High(Formats.Patterns) do
    begin
      FillChar(Formats.Patterns[I]^[0], SizeOf(TNepperPattern), 0);
    end;

    while not EOF(F) do
    begin
      BlockRead(F, I, 1);
      BlockRead(F, J, 1);
      BlockRead(F, K, 1);
      BlockRead(F, Formats.Patterns[I]^[J].Cells[K], SizeOf(TNepperChannelCells) - K);
    end;
    Adlib.SetOPL3(Byte(NepperRec.IsOPL3));
    Result := True;
  end;

  // Reality ADlib Tracker version 1.0
  function LoadRAD: Boolean;
  type
    TRADSettingRec = bitpacked record
      InitSpeed: TBit5;
      Unused: TBit1;
      IsSlow: TBit1;
      IsDesc: TBit1;
    end;

    TRADHeaderRec = packed record
      Magic: array[0..$F] of Char;
      Version: Byte;
      Setting: TRADSettingRec;
    end;

  var
    I: Byte;
    H: TRADHeaderRec;
  begin
    Result := False;
    BlockRead(F, H, SizeOf(TNepperRec));
    if PDWord(@H.Magic[0])^ <> $20444152 then
      Exit;
    if H.Setting.IsDesc = 1 then
    begin
      I := 0;
      while (not EOF(F)) and (I <> 0) do
      begin
        BlockRead(F, I, 1);
      end;
    end;
  end;

begin    
  Result := False; 
  if FileName = '' then
    Exit;
  if FindCharPos(FileName, '.') = 0 then
    FileName := FileName + '.ntr';
  FileName := UpCase(FileName);

  Assign(F, FileName);
  {$I-}
  System.Reset(F, 1);
  {$I+}
  if IOResult = 0 then
  begin
    case PDWord(@FileName[Length(FileName) - 3])^ of
      $52544E2E: // .NTR
        begin
          Result := LoadNTR;
        end;
      $4441522E: // .RAD
        begin

        end;
    end;
    Close(F);
  end;
end;

var
  I: Byte;

initialization
  FillChar(NepperRec, SizeOf(NepperRec), 0);
  for I := 0 to High(Formats.Patterns) do
  begin
    New(Formats.Patterns[I]);
    FillChar(Formats.Patterns[I]^[0], SizeOf(TNepperPattern), 0);
  end;
  for I := 0 to High(NepperRec.Instruments) do
    NepperRec.Instruments[I].AlgFeedback.Panning := 3;
  NepperRec.ChannelCount := 8;
  NepperRec.Speed := 6;  // Unused for now
  NepperRec.Clock := 50;

finalization
  for I := 0 to High(Formats.Patterns) do
    Dispose(Formats.Patterns[I]);

end.

