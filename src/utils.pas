unit Utils;

{$mode ObjFPC}

interface

const
  BASE16_CHARS: array[0..15] of Char = ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
  COLOR_LABEL = $0D;

type
  String2 = String[2];
  String3 = String[3];
  String10 = String[10];
  String20 = String[20];
  String40 = String[40];
  String80 = String[80];

function HexToInt(const S: String): Word;
function ByteToYesNo(const B: Byte): String3;
function ByteToPanning(const B: Byte): Char;
procedure HexStrFast2(const V: Byte; out S: String2); overload;
procedure HexStrFast3(const V: Word; out S: String3); overload;
function HexStrFast2(const V: Byte): String2; overload;
function HexStrFast3(const V: Word): String3; overload;
function FindCharPos(const S: String; const C: Char): Byte;
function Min(const V1, V2: Integer): Integer; inline;
function Max(const V1, V2: Integer): Integer; inline;
procedure SwapIfBigger(var V1, V2: ShortInt);

implementation

function HexToInt(const S: String): Word;
var
  I, Len: Byte;
begin
  Len := Length(S);
  Result := 0;
  for I := 1 to Len do
  begin
    if Byte(S[I]) <= 57 then
      Inc(Result, (Byte(S[I]) - 48) * (1 shl (4 * (Len - I))))
    else
      Inc(Result, (Byte(S[I]) - 55) * (1 shl (4 * (Len - I))));
  end;
end;

function ByteToYesNo(const B: Byte): String3;
begin
  if B = 0 then
    Result := 'No'
  else
    Result := 'Yes';
end;

function ByteToPanning(const B: Byte): Char;
begin
  case B of
    0:
      Result := 'E';
    1:
      Result := 'L';
    2:
      Result := 'R';
    3:
      Result := 'C';
  end;
end;

procedure HexStrFast2(const V: Byte; out S: String2);
begin
  S[0] := Char(2);
  S[1] := BASE16_CHARS[Byte(V shr 4) and $F];
  S[2] := BASE16_CHARS[Byte(V) and $F];
end;

procedure HexStrFast3(const V: Word; out S: String3);
begin
  S[0] := Char(3);
  S[1] := BASE16_CHARS[Byte(V shr 8) and $F];
  S[2] := BASE16_CHARS[Byte(V shr 4) and $F];
  S[3] := BASE16_CHARS[Byte(V) and $F];
end;

function HexStrFast2(const V: Byte): String2;
begin
  Result[0] := Char(2);
  Result[1] := BASE16_CHARS[Byte(V shr 4) and $F];
  Result[2] := BASE16_CHARS[Byte(V) and $F];
end;

function HexStrFast3(const V: Word): String3;
begin
  Result[0] := Char(3);
  Result[1] := BASE16_CHARS[Byte(V shr 8) and $F];
  Result[2] := BASE16_CHARS[Byte(V shr 4) and $F];
  Result[3] := BASE16_CHARS[Byte(V) and $F];
end;

function FindCharPos(const S: String; const C: Char): Byte;
var
  I: Byte;
begin
  for I := 1 to Length(S) do
    if S[I] = C then
      Exit(I);
  Result := 0;
end;
      
function Min(const V1, V2: Integer): Integer; inline;
begin
  if V1 < V2 then
    Result := V1
  else
    Result := V2;
end;

function Max(const V1, V2: Integer): Integer; inline;
begin
  if V1 > V2 then
    Result := V1
  else
    Result := V2;
end;

procedure SwapIfBigger(var V1, V2: ShortInt);
var
  Tmp: ShortInt;
begin
  if V1 > V2 then
  begin
    Tmp := V1;
    V1 := V2;
    V2 := Tmp;
  end;
end;

end.

