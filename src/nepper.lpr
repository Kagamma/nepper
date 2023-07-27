program nepper;

{$mode objFPC}

uses
  Adlib, Keyboard, Input, Screen, Utils, EdInstr, Formats;

begin
  if not Adlib.Check then
  begin
    Writeln('ERROR: AdLib sound card not found!');
    Halt;
  end;
  Adlib.Init;

  EdInstr.Loop;
  Adlib.Reset;
end.

