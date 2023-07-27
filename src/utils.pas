unit Utils;

{$mode ObjFPC}

interface

function HexToInt(const S: String): Word;
function ByteToYesNo(const B: Byte): String;

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

function ByteToYesNo(const B: Byte): String;
begin
  if B = 0 then
    Result := 'No'
  else
    Result := 'Yes';
end;

end.

