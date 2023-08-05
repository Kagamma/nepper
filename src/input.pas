unit Input;

{$mode ObjFPC}

interface

var
  InputCursor: Byte = 1;

procedure InputText(var S: String; const MaxLen: Byte; const IsHex: Boolean = False);
procedure InputHex2(var S: String; var Value: Byte; const MaxValue: Byte);
procedure InputHex3(var S: String; var Value: Word; const MaxValue: Word);
procedure InputYesNo(var S: String; var Value: Byte);        
procedure InputPanning(var S: String; var Value: Byte);

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

procedure InputText2(var S: String; const MaxLen: Byte; const IsHex: Boolean = False);
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
          '0'..'9', 'A'..'Z', 'a'..'z':
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
  HexStrFast2(Value, S);
  InputText(S, 2, True);
  if KBInput.ScanCode = $FF then
  begin
    S := UpCase(S);
    Value := HexToInt(S);
    if Value > MaxValue then
    begin
      HexStrFast2(MaxValue, S);
      Value := MaxValue;
    end;
  end;
end;

procedure InputHex3(var S: String; var Value: Word; const MaxValue: Word);
var
  C: Char;
begin
  HexStrFast2(Byte(Value), S);
  if Byte(Value shr 8) = 0 then
    Insert('0', S, 1)
  else
    Insert(Char(Value shr 8), S, 1);
  C := S[1];
  InputText2(S, 4, InputCursor <> 1);
  if KBInput.ScanCode = $FF then
  begin   
    if Length(S) > 3 then
      Delete(S, 2, 1);
    S := UpCase(S);
    C := S[1];
    S[1] := '0';
    Value := (Word(C) shl 8) + HexToInt(S);
  end;
  S[1] := C;
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

procedure InputPanning(var S: String; var Value: Byte);
begin
  case KBInput.CharCode of
    'l':
      begin
        KBInput.ScanCode := $FF;
        S := 'L';
        Value := 1;
      end;   
    'r':
      begin
        KBInput.ScanCode := $FF;
        S := 'R';
        Value := 2;
      end; 
    'c', 'm':
      begin
        KBInput.ScanCode := $FF;
        S := 'C';
        Value := 3;
      end;
  end;
end;

end.

