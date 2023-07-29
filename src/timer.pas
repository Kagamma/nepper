unit Timer;

{$mode ObjFPC}

interface

implementation

uses
  Dos, Player;

var
  OldTimerHandle: Pointer;

procedure InstallTimer;
var
  Divisor: DWord;
begin
  asm cli end;
  Divisor := 1193182 div 50;
  Port[$43] := $36;
  Port[$40] := Byte(Divisor);
  Port[$40] := Byte(Divisor shr 8);
  asm sti end;
end;

procedure UninstallTimer;
begin
  asm cli end;
  Port[$43] := $36;
  Port[$40] := 0;
  Port[$40] := 0;
  asm sti end;
end;

procedure TimerHandler; interrupt; far;
begin
  Player.Play;
end;

initialization
  GetIntVec($1C, OldTimerHandle);
  SetIntVec($1C, @TimerHandler);
  InstallTimer;

finalization
  SetIntVec($1C, OldTimerHandle);
  UninstallTimer;

end.

