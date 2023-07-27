unit Screen;

{$mode ObjFPC}

interface

var
  ScreenPointer: PWord;

procedure SetCursorPosition(const X, Y: Byte);
procedure IncCursorX;
procedure DecCursorX;
procedure WriteText(const X, Y, Attr: Byte; const S: String; MaxLen: Byte = 0);
procedure WriteTextBack(const X, Y, Attr: Byte; const S: String; MaxLen: Byte = 0);

implementation

var
  CursorX,
  CursorY: Byte;

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

procedure WriteText(const X, Y, Attr: Byte; const S: String; MaxLen: Byte = 0);
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

procedure WriteTextBack(const X, Y, Attr: Byte; const S: String; MaxLen: Byte = 0);
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

initialization
  ScreenPointer := Ptr($B800, $0000);
  FillChar(ScreenPointer[0], 80*25*2, 0);

finalization
  FillChar(ScreenPointer[0], 80*25*2, 0);
  SetCursorPosition(0, 0);

end.

