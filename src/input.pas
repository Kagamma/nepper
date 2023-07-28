unit Input;

{$mode ObjFPC}

interface

var
  InputCursor: Byte = 1;

procedure InputText(var S: String; const MaxLen: Byte; const IsHex: Boolean = False);
procedure InputHex2(var S: String; var Value: Byte; const MaxValue: Byte);
procedure InputHex3(var S: String; var Value: Word; const MaxValue: Word);
procedure InputYesNo(var S: String; var Value: Byte);

implementation

uses
  Keyboard, Screen, Utils;

procedure InputText(var S: String; const MaxLen: Byte; const IsHex: Boolean = False);
var
  Len: Byte;
begin
  Len := Length(S);
  case KBInput.ScanCode of
    SCAN_LEFT:
      begin
        if InputCursor > 1 then
        begin
          Dec(InputCursor);
          Screen.DecCursorX;
          KBInput.ScanCode := $FE;
        end;
      end;
    SCAN_RIGHT:
      begin
        if (IsHex and (InputCursor < Len)) or ((not IsHex) and (InputCursor <= Len)) then
        begin
          Inc(InputCursor);
          Screen.IncCursorX;
          KBInput.ScanCode := $FE;
        end;
      end;
    SCAN_DEL:
      begin
        if IsHex then
          Exit;
        if InputCursor <= MaxLen then
        begin
          KBInput.ScanCode := $FF;
          Delete(S, InputCursor, 1);
        end;
      end;
    SCAN_BS:
      begin
        if IsHex then
          Exit;
        if InputCursor > 1 then
        begin      
          KBInput.ScanCode := $FF;
          Dec(InputCursor);
          Delete(S, InputCursor, 1);
          Screen.DecCursorX;
        end;
      end;
    else
      if IsHex then
        case KBInput.CharCode of
          '0'..'9', 'A'..'F', 'a'..'f':
            begin
              KBInput.ScanCode := $FF;
              S[InputCursor] := KBInput.CharCode;
              if MaxLen > InputCursor then
              begin
                Inc(InputCursor);
                Screen.IncCursorX;
              end;
              if Length(S) > MaxLen then
                SetLength(S, MaxLen);
            end;
        end
      else
        case KBInput.CharCode of
          #32..#126:
            begin
              KBInput.ScanCode := $FF;
              Insert(KBInput.CharCode, S, InputCursor);
              if MaxLen > InputCursor then
              begin
                Inc(InputCursor);
                Screen.IncCursorX;
              end;
              if Length(S) > MaxLen then
                SetLength(S, MaxLen);
            end;
        end;
  end;
end;

procedure InputHex2(var S: String; var Value: Byte; const MaxValue: Byte);
begin
  S := HexStr(Value, 2);
  InputText(S, 2, True);
  if KBInput.ScanCode = $FF then
  begin
    S := UpCase(S);
    Value := HexToInt(S);
    if Value > MaxValue then
    begin
      S := HexStr(MaxValue, 2);
      Value := MaxValue;
    end;
  end;
end;

procedure InputHex3(var S: String; var Value: Word; const MaxValue: Word);
begin
  S := HexStr(Value, 3);
  InputText(S, 3, True);
  if KBInput.ScanCode = $FF then
  begin
    S := UpCase(S);
    Value := HexToInt(S);
    if Value > MaxValue then
    begin
      S := HexStr(MaxValue, 3);
      Value := MaxValue;
    end;
  end;
end;

procedure InputYesNo(var S: String; var Value: Byte);
begin
  case KBInput.CharCode of
    'y':
      begin
        KBInput.ScanCode := $FF;
        S := 'Yes';
        Value := 1;
      end;
    'n':
      begin         
        KBInput.ScanCode := $FF;
        S := 'No ';
        Value := 0;
      end;
  end;
end;

end.

