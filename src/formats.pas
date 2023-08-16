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
    B, I, J, OrderLen, LineData, ChannelData, ChannelNo, InstrNo, Octave, Note, Effect, EffectParam: Byte;
    W: Word;
    C: Char;
    H: TRADHeaderRec;
    InstrData: array[0..$A] of Byte;
    InstrUsed: array[0..$1F] of Boolean;
    PatternTable: array[0..31] of Word;
  begin
    Result := False;
    BlockRead(F, H, SizeOf(TRADHeaderRec));
    if PDWord(@H.Magic[0])^ <> $20444152 then
      Exit;
    // Read desc
    NepperRec.Name := '';
    if H.Setting.IsDesc = 1 then
    begin
      I := 1;
      repeat
        BlockRead(F, C, 1);
        if C <> #0 then
        begin
          if I <= 40 then
          begin
            NepperRec.Name[I] := C;
          end;
          Inc(I);
        end;
      until (C = #0) or EOF(F);
    end;   
    NepperRec.Name[0] := Char(40);
    // Read InstrData
    FillChar(InstrUsed[0], SizeOf(InstrUsed), 0);
    BlockRead(F, I, 1);
    while I <> 0 do
    begin
      BlockRead(F, InstrData[0], SizeOf(InstrData));
      Byte(NepperRec.Instruments[I].Operators[1].Effect) := InstrData[0];
      Byte(NepperRec.Instruments[I].Operators[0].Effect) := InstrData[1];
      Byte(NepperRec.Instruments[I].Operators[1].Volume) := InstrData[2];
      Byte(NepperRec.Instruments[I].Operators[0].Volume) := InstrData[3];
      Byte(NepperRec.Instruments[I].Operators[1].AttackDecay) := InstrData[4];
      Byte(NepperRec.Instruments[I].Operators[0].AttackDecay) := InstrData[5];
      Byte(NepperRec.Instruments[I].Operators[1].SustainRelease) := InstrData[6];
      Byte(NepperRec.Instruments[I].Operators[0].SustainRelease) := InstrData[7];
      Byte(NepperRec.Instruments[I].AlgFeedback) := InstrData[8];
      Byte(NepperRec.Instruments[I].Operators[1].Waveform) := InstrData[9];
      Byte(NepperRec.Instruments[I].Operators[0].Waveform) := InstrData[$A];
      InstrUsed[I] := True;
      BlockRead(F, I, 1);
    end;
    // Read order
    FillChar(NepperRec.Orders[0], SizeOf(NepperRec.Orders), 0);
    BlockRead(F, OrderLen, 1);
    for I := 0 to OrderLen - 1 do
    begin
      BlockRead(F, NepperRec.Orders[I], 1);
      NepperRec.Orders[I] := NepperRec.Orders[I] and $1F; // TODO: jump marker
    end;
    NepperRec.Orders[OrderLen] := $FF; // Stop mark
    // Read pattern table
    BlockRead(F, PatternTable[0], SizeOf(PatternTable));
    // Cleanup pattern before reading .RAD patterns
    for I := 0 to High(Formats.Patterns) do
    begin
      FillChar(Formats.Patterns[I]^[0], SizeOf(TNepperPattern), 0);
    end;
    NepperRec.ChannelCount := 1;
    for I := 0 to 31 do
    begin
      if PatternTable[I] = 0 then
        Continue;
      Seek(F, PatternTable[I]);
      // Read line numbers
      repeat
        BlockRead(F, LineData, 1);
        J := LineData and %01111111;
        repeat
          BlockRead(F, ChannelData, 1);
          BlockRead(F, Note, 1);
          BlockRead(F, Effect, 1);
          ChannelNo := ChannelData and %01111111;
          if NepperRec.ChannelCount < ChannelNo then
            NepperRec.ChannelCount := ChannelNo + 1;
          //
          InstrNo := ((Note and %10000000) shr 3) or ((Effect and %11110000) shr 4);
          Octave := (Note and %01110000) shr 4;
          Note := Note and %00001111;
          Inc(Note);
          if Note > 12 then
          begin
            Note := 1;
            Inc(Octave);
          end;
          Formats.Patterns[I]^[ChannelNo].Cells[J].Note.Note := Note;
          Formats.Patterns[I]^[ChannelNo].Cells[J].Note.Octave := Octave;
          Formats.Patterns[I]^[ChannelNo].Cells[J].InstrumentIndex := InstrNo;
          if Effect and %00001111 = 0 then
          begin
            Word(Formats.Patterns[I]^[ChannelNo].Cells[J].Effect) := 0;
          end else
          begin
            //
            BlockRead(F, EffectParam, 1);
            case (Effect and %00001111) of
              $1:
                Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := Byte('2');
              $2:
                Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := Byte('1');
              $3:
                Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := Byte('3');
              $5:
                Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := Byte('5');
              $A:
                Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := Byte('A');
              $C:
                Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := Byte('9');
              $D:
                Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := Byte('D');
              $F:
                Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := Byte('F');
              else
                Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := 0;
            end;
            if Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect <> 0 then
            begin
              Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.V1 := (EffectParam and %11110000) shr 4;
              Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.V2 := EffectParam and %00001111;
            end;
          end;
          if not InstrUsed[InstrNo] then
          begin
            Byte(Formats.Patterns[I]^[ChannelNo].Cells[J].Note) := 0;
            Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.Effect := Byte('Z');
            Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.V1 := $F;                 
            Formats.Patterns[I]^[ChannelNo].Cells[J].Effect.V2 := 0;
          end;
        until ((ChannelData and %10000000) <> 0) or EOF(F);
      until ((LineData and %10000000) <> 0) or EOF(F);
    end;    
    Adlib.SetOPL3(0);
    Result := True;
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
          Result := LoadRAD;
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

