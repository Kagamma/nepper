unit Screen;

{$mode ObjFPC}

interface

uses
  Utils;

var
  ScreenPointer,
  ScreenPointerBackup: PWord;
  CursorX,
  CursorY: Byte;

procedure ClrScr;
procedure SetCursorPosition(const X, Y: Byte);
procedure IncCursorX;
procedure DecCursorX;
procedure WriteTextFast1(const P: PWord; const Attr: Byte; const S: Char); inline;
procedure WriteTextFast2(P: PWord; const Attr: Byte; const S: String2); inline;
procedure WriteTextFast3(P: PWord; const Attr: Byte; const S: String3); inline;
procedure WriteText(const X, Y, Attr: Byte; const S: String80; MaxLen: Byte = 0);
procedure WriteTextBack(const X, Y, Attr: Byte; const S: String80; MaxLen: Byte = 0);
procedure WriteTextMid(const X, Y, Attr: Byte; const S: String80; MaxLen: Byte = 0);

implementation

procedure ClrScr;
begin
  FillByte(ScreenPointer[0], 80*25*2, 0);
end;

procedure SetCursorPosition(const X, Y: Byte); assembler;
asm
  mov ah,2
  mov dh,Y
  mov dl,X
  mov CursorX,dl
  mov CursorY,dh
  xor bh,bh
  int $10
end;

procedure IncCursorX;
begin
  Inc(CursorX);
  SetCursorPosition(CursorX, CursorY);
end;

procedure DecCursorX;
begin
  Dec(CursorX);
  SetCursorPosition(CursorX, CursorY);
end;

procedure WriteTextFast1(const P: PWord; const Attr: Byte; const S: Char); inline;
begin
  P^ := (Word(Attr) shl 8) + Byte(S);
end;

procedure WriteTextFast2(P: PWord; const Attr: Byte; const S: String2); inline;
var
  W: Word;
begin
  W := Attr shl 8;
  P[0] := W + Byte(S[1]);
  P[1] := W + Byte(S[2]);
end;

procedure WriteTextFast3(P: PWord; const Attr: Byte; const S: String3); inline;
var
  W: Word;
begin
  W := Attr shl 8;
  P[0] := W + Byte(S[1]);
  P[1] := W + Byte(S[2]);
  P[2] := W + Byte(S[3]);
end;

procedure WriteText(const X, Y, Attr: Byte; const S: String80; MaxLen: Byte = 0);
var
  I: Byte;
  P: PWord;
  W: Word;
begin
  if MaxLen = 0 then
    MaxLen := Length(S);
  P := ScreenPointer + (80 * Y + X);
  W := Attr shl 8;
  for I := 1 to MaxLen do
  begin
    if I <= Length(S) then
      P^ := W + Byte(S[I])
    else
      P^ := W;
    Inc(P);
  end;
end;

procedure WriteTextBack(const X, Y, Attr: Byte; const S: String80; MaxLen: Byte = 0);
var
  I: Byte;
  P: PWord;
  W: Word;
begin
  if MaxLen = 0 then
    MaxLen := Length(S);
  P := ScreenPointer + (80 * Y + X);
  W := Attr shl 8;
  for I := MaxLen downto 1 do
  begin
    if I <= Length(S) then
      P^ := W + Byte(S[I])
    else
      P^ := W;
    Dec(P);
  end;
end;

procedure WriteTextMid(const X, Y, Attr: Byte; const S: String80; MaxLen: Byte = 0);
var
  I: Byte;
  P: PWord;
  W: Word;
begin
  if MaxLen = 0 then
    MaxLen := Length(S);
  P := ScreenPointer + (80 * Y + (X - MaxLen div 2));
  W := Attr shl 8;
  for I := 1 to MaxLen do
  begin
    if I <= Length(S) then
      P^ := W + Byte(S[I])
    else
      P^ := W;
    Inc(P);
  end;
end;

initialization
  ScreenPointer := Ptr($B800, $0000);
  ScreenPointerBackup := ScreenPointer;
  FillChar(ScreenPointer[0], 80*25*2, 0);

finalization
  FillWord(ScreenPointer[0], 80*25, $0700);
  SetCursorPosition(0, 0);

end.

