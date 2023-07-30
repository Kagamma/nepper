unit Timer;

{$mode ObjFPC}

interface

procedure InstallTimer(const Hz: Byte);

implementation

uses
  Dos, Player;

var
  OldTimerHandle: Pointer;

procedure InstallTimer(const Hz: Byte);
var
  Divisor: DWord;
begin
  asm cli end;
  Divisor := 1193182 div Hz;
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
  InstallTimer(50);

finalization
  SetIntVec($1C, OldTimerHandle);
  UninstallTimer;

end.

