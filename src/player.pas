unit Player;

{$mode ObjFPC}

interface

procedure Play;

implementation

uses
  Adlib, Formats, EdInstr;

procedure Play;
var
  N: PAdlibRegA0B8;
begin
  // For testing instrument
  if IsInstrTesting then
  begin
    if CurInstr^.PitchShift <> 0 then
    begin
      N := @FreqRegs[8];
      N^.Freq := N^.Freq + ShortInt(CurInstr^.PitchShift);
      if N^.Freq >= ADLIB_FREQ_TABLE[12] then
      begin
        N^.Freq := ADLIB_FREQ_TABLE[0];
        N^.Octave := N^.Octave + 1;
      end else
      if N^.Freq <= ADLIB_FREQ_TABLE[0] then
      begin
        N^.Freq := ADLIB_FREQ_TABLE[12];
        N^.Octave := N^.Octave - 1;
      end;
      WriteReg($A0 + 8, Lo(Word(N^)));
      WriteReg($B0 + 8, Hi(Word(N^)));
    end;
  end;
end;

end.

