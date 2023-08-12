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
    Orders: array[0..$FF] of Byte;
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
  // http://fileformats.archiveteam.org/wiki/Reality_AdLib_Tracker_module
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
    B, I, J, OrderLen, LineNum, ChannelNo, InstrNo, Octave, Note, Effect, EffectParam: Byte;
    W: Word;
    C: Char;
    H: TRADHeaderRec;
    InstrData: array[0..$A] of Byte;
    PatternTable: array[0..31] of Word;
  begin
    Result := False;
    BlockRead(F, H, SizeOf(TNepperRec));
    if PDWord(@H.Magic[0])^ <> $20444152 then
      Exit; ;
    // Read desc
    if H.Setting.IsDesc = 1 then
    begin
      C := #0;
      I := 1;
      while (not EOF(F)) and (C <> #0) do
      begin
        BlockRead(F, C, 1);
        if C <> #0 then
        begin
          if I <= 40 then
          begin
            NepperRec.Name[I] := C;
          end;
          Inc(I);
        end;
      end;
      NepperRec.Name[0] := C;
    end;
    // Read InstrData
    BlockRead(F, I, 1);
    while I <> 0 do
    begin
      BlockRead(F, InstrData[0], SizeOf(InstrData));
      Byte(NepperRec.Instruments[I].Operators[0].Effect) := InstrData[0];
      Byte(NepperRec.Instruments[I].Operators[1].Effect) := InstrData[1];
      Byte(NepperRec.Instruments[I].Operators[0].Volume) := InstrData[2];
      Byte(NepperRec.Instruments[I].Operators[1].Volume) := InstrData[3];
      Byte(NepperRec.Instruments[I].Operators[0].AttackDecay) := InstrData[4];
      Byte(NepperRec.Instruments[I].Operators[1].AttackDecay) := InstrData[5];
      Byte(NepperRec.Instruments[I].Operators[0].SustainRelease) := InstrData[6];
      Byte(NepperRec.Instruments[I].Operators[1].SustainRelease) := InstrData[7];
      Byte(NepperRec.Instruments[I].AlgFeedback) := InstrData[8];
      Byte(NepperRec.Instruments[I].Operators[0].Waveform) := InstrData[9];
      Byte(NepperRec.Instruments[I].Operators[1].Waveform) := InstrData[$A];
      BlockRead(F, I, 1);
    end;
    // Read order
    BlockRead(F, OrderLen, 1);
    for I := 1 to OrderLen do
    begin
      BlockRead(F, NepperRec.Orders[I - 1], 1);
      NepperRec.Orders[I - 1] := NepperRec.Orders[I - 1] and $1F; // TODO: jump marker
    end;
    NepperRec.Orders[I] := $FF; // Stop mark
    // Read pattern table
    BlockRead(F, PatternTable[0], SizeOf(PatternTable));
    // Cleanup pattern before reading .RAD patterns
    for I := 0 to High(Formats.Patterns) do
    begin
      New(Formats.Patterns[I]);
      FillChar(Formats.Patterns[I]^[0], SizeOf(TNepperPattern), 0);
    end;
    for I := 0 to 31 do
    begin
      if PatternTable[I] = 0 then
        Continue;
      Seek(F, PatternTable[I]);
      // Read line numbers
      repeat
        BlockRead(F, LineNum, 1);
        for J := 0 to (LineNum and $7F) do
        begin
          repeat
            BlockRead(F, ChannelNo, 1);
            BlockRead(F, Note, 1);         
            BlockRead(F, Effect, 1);
            //

            //
            BlockRead(F, EffectParam, 1);
          until (ChannelNo and $80) <> 0;
        end;
      until (LineNum and $80) <> 0;
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

