unit EdInstr;

{$mode ObjFPC}

interface

uses
  Screen, Adlib, Keyboard, Input, Utils, Formats;

var
  CurInstr: PAdlibInstrument;
  IsInstrTesting: Boolean = False;

procedure Loop;

implementation

uses
  Dialogs;

const
  OP1_X = 16;
  OP2_X = 36;
  OP3_X = 56;

type
  TEdInstrMenuItem = record
    X, Y: Byte;
  end;

var
  CurMenuPos: Byte = 1;
  CurInstrPos: Byte = 0;
  TestNote: TNepperNote;
  MenuList: array[0..28] of TEdInstrMenuItem;

procedure ResetParams;
begin                           
  Input.InputCursor := 1;
  Screen.SetCursorPosition(MenuList[CurMenuPos].X, MenuList[CurMenuPos].Y);
end;

procedure RenderTexts;
begin
  WriteText(0, 0, $1F, '                                   - Nepper -', 80);
  WriteText(0, 0, $1A, 'INSTRUMENT EDIT');
  WriteText(0, 1, $0E, '     [F1] Song/Pattern Editor  [F2] Instrument Editor  [ESC] Exit Nepper');

  WriteTextBack(OP1_X, 3, $0D, 'Inst. number:');
  WriteTextBack(OP1_X, 4, $0D, 'Synthesis mode:');
  WriteTextBack(OP1_X + 2, 6, $4E, '     Operator 1    ');
  WriteTextBack(OP1_X, 7,  $0D, 'Attack:');
  WriteTextBack(OP1_X, 8,  $0D, 'Decay:');
  WriteTextBack(OP1_X, 9,  $0D, 'Sustain:');
  WriteTextBack(OP1_X, 10, $0D, 'Release:');
  WriteTextBack(OP1_X, 11, $0D, 'Volume:');
  WriteTextBack(OP1_X, 12, $0D, 'Level scale:');
  WriteTextBack(OP1_X, 13, $0D, 'Multiplier:');
  WriteTextBack(OP1_X, 14, $0D, 'Waveform:');
  WriteTextBack(OP1_X, 15, $0D, 'Sustain Sound:');  
  WriteTextBack(OP1_X, 16, $0D, 'Scale Envelope:');
  WriteTextBack(OP1_X, 17, $0D, 'Pitch Vibrator:');
  WriteTextBack(OP1_X, 18, $0D, 'Volume Vibrator:');
  
  WriteTextBack(OP2_X, 3, $0D, 'Inst. name:');
  WriteTextBack(OP2_X, 4, $0D, 'Feedback:');
  WriteTextBack(OP2_X + 2, 6, $4E, '     Operator 2    ');
  WriteTextBack(OP2_X, 7,  $0D, 'Attack:');
  WriteTextBack(OP2_X, 8,  $0D, 'Decay:');
  WriteTextBack(OP2_X, 9,  $0D, 'Sustain:');
  WriteTextBack(OP2_X, 10, $0D, 'Release:');
  WriteTextBack(OP2_X, 11, $0D, 'Volume:');
  WriteTextBack(OP2_X, 12, $0D, 'Level scale:');
  WriteTextBack(OP2_X, 13, $0D, 'Multiplier:');
  WriteTextBack(OP2_X, 14, $0D, 'Waveform:');
  WriteTextBack(OP2_X, 15, $0D, 'Sustain Sound:');
  WriteTextBack(OP2_X, 16, $0D, 'Scale Envelope:');
  WriteTextBack(OP2_X, 17, $0D, 'Pitch Vibrator:');
  WriteTextBack(OP2_X, 18, $0D, 'Volume Vibrator:');

  WriteTextBack(OP3_X, 4, $0D, 'Pitch Shift:');

  WriteTextBack(76, 22, $0D, 'Test tone:');
  WriteText(0, 23, $0A, '[L] Load [<] Prev [SPC] Test  [+] Test Tone Up');
  WriteText(0, 24, $0A, '[S] Save [>] Next [CR] Quiet  [-] Test Tone Down');
end;

procedure RenderInstrInfo;
var
  I: Byte;
  Ofs: Byte;
  S: String20;
begin
  WriteText(OP1_X + 1, 3, $0F, HexStr(CurInstrPos, 2));
  WriteText(OP1_X + 1, 4, $0F, HexStr(CurInstr^.AlgFeedback.Alg, 2));
  WriteText(OP2_X + 1, 3, $0F, CurInstr^.Name, 20);
  WriteText(OP2_X + 1, 4, $0F, HexStr(CurInstr^.AlgFeedback.Feedback, 2));
  WriteText(OP3_X + 1, 4, $0F, HexStr(CurInstr^.PitchShift, 2));
  for I := 0 to 1 do
  begin
    Ofs := I * ((OP2_X + 2) - (OP1_X + 2));
    WriteText((OP1_X + 1) + Ofs, 7, $0F, HexStr(CurInstr^.Operators[I].AttackDecay.Attack, 2));
    WriteText((OP1_X + 1) + Ofs, 8, $0F, HexStr(CurInstr^.Operators[I].AttackDecay.Decay, 2));
    WriteText((OP1_X + 1) + Ofs, 9, $0F, HexStr($F - CurInstr^.Operators[I].SustainRelease.Sustain, 2));
    WriteText((OP1_X + 1) + Ofs, 10, $0F, HexStr(CurInstr^.Operators[I].SustainRelease.Release, 2));
    WriteText((OP1_X + 1) + Ofs, 11, $0F, HexStr($3F - CurInstr^.Operators[I].Volume.Total, 2));
    WriteText((OP1_X + 1) + Ofs, 12, $0F, HexStr(CurInstr^.Operators[I].Volume.Scaling, 2));
    WriteText((OP1_X + 1) + Ofs, 13, $0F, HexStr(CurInstr^.Operators[I].Effect.ModFreqMult, 2));;
    WriteText((OP1_X + 1) + Ofs, 14, $0F, HexStr(CurInstr^.Operators[I].Waveform.Waveform, 2));
    WriteText((OP1_X + 1) + Ofs, 15, $0F, ByteToYesNo(CurInstr^.Operators[I].Effect.EGTyp), 3); 
    WriteText((OP1_X + 1) + Ofs, 16, $0F, ByteToYesNo(CurInstr^.Operators[I].Effect.KSR), 3);
    WriteText((OP1_X + 1) + Ofs, 17, $0F, ByteToYesNo(CurInstr^.Operators[I].Effect.Vib), 3);
    WriteText((OP1_X + 1) + Ofs, 18, $0F, ByteToYesNo(CurInstr^.Operators[I].Effect.AmpMod), 3);
  end;
  Str(TestNote.Octave, S);
  WriteText(77, 22, $0F, ADLIB_NOTESYM_TABLE[TestNote.Note]);
  WriteText(79, 22, $0F, S);
end;

procedure Loop;
var
  OldCurMenuPos: Byte;
  S: String40;
  V: Byte;
begin
  ClrScr;
  ResetParams;
  RenderTexts;
  RenderInstrInfo;
  repeat
    Keyboard.WaitForInput;
    OldCurMenuPos := CurMenuPos;
    case CurMenuPos of
      1:
        begin
          V := CurInstr^.AlgFeedback.Alg;
          Input.InputHex2(S, V, 1);
          CurInstr^.AlgFeedback.Alg := V;
        end;
      //
      2:
        begin
          V := CurInstr^.Operators[0].AttackDecay.Attack;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[0].AttackDecay.Attack := V;
        end;
      3:
        begin
          V := CurInstr^.Operators[0].AttackDecay.Decay;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[0].AttackDecay.Decay := V;
        end;
      4:
        begin
          V := $F - CurInstr^.Operators[0].SustainRelease.Sustain;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[0].SustainRelease.Sustain := $F - V;
        end;
      5:
        begin                    
          V := CurInstr^.Operators[0].SustainRelease.Release;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[0].SustainRelease.Release := V;
        end;
      6:
        begin          
          V := $3F - CurInstr^.Operators[0].Volume.Total;
          Input.InputHex2(S, V, $3F);
          CurInstr^.Operators[0].Volume.Total := $3F - V;
        end;  
      7:
        begin             
          V := CurInstr^.Operators[0].Volume.Scaling;
          Input.InputHex2(S, V, 3);
          CurInstr^.Operators[0].Volume.Scaling := V;
        end;
      8:
        begin      
          V := CurInstr^.Operators[0].Effect.ModFreqMult;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[0].Effect.ModFreqMult := V;
        end;
      9:
        begin   
          V := CurInstr^.Operators[0].Waveform.Waveform;
          Input.InputHex2(S, V, $3);
          CurInstr^.Operators[0].Waveform.Waveform := V;
        end;
      10:
        begin                
          V := CurInstr^.Operators[0].Effect.EGTyp;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[0].Effect.EGTyp := V;
        end;
      11:
        begin
          V := CurInstr^.Operators[0].Effect.KSR;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[0].Effect.KSR := V;
        end;
      12:
        begin           
          V := CurInstr^.Operators[0].Effect.Vib;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[0].Effect.Vib := V;
        end;
      13:
        begin        
          V := CurInstr^.Operators[0].Effect.AmpMod;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[0].Effect.AmpMod := V;
        end;
      //
      14:
        begin
          Input.InputText(CurInstr^.Name, 20);
          S := CurInstr^.Name;
        end;
      15:
        begin   
          V := CurInstr^.AlgFeedback.Feedback;
          Input.InputHex2(S, V, 7);
          CurInstr^.AlgFeedback.Feedback := V;
        end;
      //
      16:
        begin                    
          V := CurInstr^.Operators[1].AttackDecay.Attack;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[1].AttackDecay.Attack := V;
        end;
      17:
        begin             
          V := CurInstr^.Operators[1].AttackDecay.Decay;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[1].AttackDecay.Decay := V;
        end;
      18:
        begin                       
          V := $F - CurInstr^.Operators[1].SustainRelease.Sustain;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[1].SustainRelease.Sustain := $F - V;
        end;
      19:
        begin                    
          V := CurInstr^.Operators[1].SustainRelease.Release;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[1].SustainRelease.Release := V;
        end;
      20:
        begin       
          V := $3F - CurInstr^.Operators[1].Volume.Total;
          Input.InputHex2(S, V, $3F);
          CurInstr^.Operators[1].Volume.Total := $3F - V;
        end;
      21:
        begin     
          V := CurInstr^.Operators[1].Volume.Scaling;
          Input.InputHex2(S, V, 3);
          CurInstr^.Operators[1].Volume.Scaling := V;
        end;
      22:
        begin              
          V := CurInstr^.Operators[1].Effect.ModFreqMult;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[1].Effect.ModFreqMult := V;
        end;
      23:
        begin            
          V := CurInstr^.Operators[1].Waveform.Waveform;
          Input.InputHex2(S, V, $3);
          CurInstr^.Operators[1].Waveform.Waveform := V;
        end;
      24:
        begin                 
          V := CurInstr^.Operators[1].Effect.EGTyp;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[1].Effect.EGTyp := V;
        end; 
      25:
        begin
          V := CurInstr^.Operators[1].Effect.KSR;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[1].Effect.KSR := V;
        end;
      26:
        begin                
          V := CurInstr^.Operators[1].Effect.Vib;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[1].Effect.Vib := V;
        end;
      27:
        begin    
          V := CurInstr^.Operators[1].Effect.AmpMod;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[1].Effect.AmpMod := V;
        end;
      //
      28:
        begin                      
          V := CurInstr^.PitchShift;
          Input.InputHex2(S, V, $FF);
          CurInstr^.PitchShift := V;
        end;
    end;

    if KBInput.ScanCode < $FE then
      case KBInput.ScanCode of
        SCAN_LEFT:
          begin
            if (CurMenuPos >= 14) and (CurMenuPos <= 27) then
            begin                 
              Input.InputCursor := 2;
              Dec(CurMenuPos, 14);
            end else
            if CurMenuPos = 28 then
            begin
              Input.InputCursor := 2;
              CurMenuPos := 15;
            end;
            if CurMenuPos = 0 then
              Inc(CurMenuPos); 
            if CurMenuPos = 14 then
              Input.InputCursor := 1;
          end;
        SCAN_RIGHT:
          begin
            if CurMenuPos <= 13 then
            begin
              Input.InputCursor := 1;
              Inc(CurMenuPos, 14)
            end else
            if CurMenuPos = 15 then
            begin
              Input.InputCursor := 1;
              CurMenuPos := 28;
            end;
            if CurMenuPos = 14 then
              Input.InputCursor := 1;
          end;
        SCAN_UP:
          begin
            if CurMenuPos > 1 then
              Dec(CurMenuPos);
            if CurMenuPos = 14 then
              Input.InputCursor := 1;
          end;
        SCAN_DOWN:
          begin
            if CurMenuPos < 28 then
              Inc(CurMenuPos);
            if CurMenuPos = 14 then
              Input.InputCursor := 1;
          end;
        SCAN_SPACE:
          begin
            Adlib.SetInstrument(8, CurInstr);
            Adlib.NoteOn(8, TestNote.Note, TestNote.Octave);
            IsInstrTesting := True;
          end;
        SCAN_ENTER:
          begin
            Adlib.NoteOff(8);
            IsInstrTesting := False;
          end;
        else
          begin
            case KBInput.CharCode of
              '+':
                begin
                  if TestNote.Octave <= ADLIB_MAX_OCTAVE - 1 then
                  begin
                    if TestNote.Note < 12 then
                    begin
                      TestNote.Note := TestNote.Note + 1;
                    end else
                    if TestNote.Octave < ADLIB_MAX_OCTAVE - 1 then
                    begin
                      TestNote.Octave := TestNote.Octave + 1;
                      TestNote.Note := 0;
                    end;
                  end;
                  Str(TestNote.Octave, S);
                  WriteText(77, 22, $0F, ADLIB_NOTESYM_TABLE[TestNote.Note]);
                  WriteText(79, 22, $0F, S);
                end;
              '-':
                begin
                  if TestNote.Octave >= 0 then
                  begin
                    if TestNote.Note > 1 then
                    begin
                      TestNote.Note := TestNote.Note - 1;
                    end else
                    if TestNote.Octave > 0 then
                    begin
                      TestNote.Octave := TestNote.Octave - 1;
                      TestNote.Note := 11;
                    end;
                  end;
                  Str(TestNote.Octave, S);
                  WriteText(77, 22, $0F, ADLIB_NOTESYM_TABLE[TestNote.Note]);
                  WriteText(79, 22, $0F, S);
                end;
              '<':
                begin
                  if CurInstrPos > 0 then
                  begin
                    Adlib.NoteOff(CurInstrPos);
                    Dec(CurInstrPos);
                    CurInstr := @NepperRec.Instruments[CurInstrPos];
                    RenderInstrInfo;
                  end;
                end;
              '>':
                begin
                  if CurInstrPos < High(NepperRec.Instruments) then
                  begin
                    Adlib.NoteOff(CurInstrPos);
                    Inc(CurInstrPos);
                    CurInstr := @NepperRec.Instruments[CurInstrPos];
                    RenderInstrInfo;
                  end;
                end;
              's':
                begin
                  S := '';
                  if ShowInputDialog('Save Instrument', S) then
                  begin
                    SaveInstrument(S, CurInstr);
                    S := '';
                    RenderTexts;
                    RenderInstrInfo;
                  end;
                  Screen.SetCursorPosition(MenuList[CurMenuPos].X + Input.InputCursor - 1, MenuList[CurMenuPos].Y);
                  Continue;
                end;
              'l':
                begin
                  S := '';
                  if ShowInputDialog('Load Instrument', S) then
                  begin
                    if not LoadInstrument(S, CurInstr) then
                      ShowMessageDialog('Error', 'File not found!');
                    S := '';
                    RenderTexts;
                    RenderInstrInfo;
                  end;
                  Screen.SetCursorPosition(MenuList[CurMenuPos].X + Input.InputCursor - 1, MenuList[CurMenuPos].Y);
                  Continue;
                end;
            end;
          end;
      end;

    if KBInput.ScanCode = $FF then
    begin
      if CurMenuPos = 14 then
        Screen.WriteText(MenuList[CurMenuPos].X, MenuList[CurMenuPos].Y, $0F, S, 20)
      else
        Screen.WriteText(MenuList[CurMenuPos].X, MenuList[CurMenuPos].Y, $0F, S);
    end;
    if OldCurMenuPos <> CurMenuPos then
    begin
      if Input.InputCursor > 2 then
        Input.InputCursor := 2;
      Screen.SetCursorPosition(MenuList[CurMenuPos].X + Input.InputCursor - 1, MenuList[CurMenuPos].Y);
    end;
  until (KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F1);
end;

var
  I: Byte;

initialization
  CurInstr := @NepperRec.Instruments[0];
  TestNote.Octave := 4;
  TestNote.Note := 1;
  // Fill up menu
  FillChar(MenuList[0], SizeOf(MenuList), $FF);
  // X
  for I := 0 to 13 do
    MenuList[I].X := OP1_X + 1;
  for I := 14 to 27 do
    MenuList[I].X := OP2_X + 1;
  MenuList[28].X := OP3_X + 1;
  // Y
  MenuList[0].Y := 3;
  MenuList[1].Y := 4;  
  MenuList[14].Y := 3;
  MenuList[15].Y := 4;
  MenuList[28].Y := 4;
  for I := 7 to 18 do
  begin
    MenuList[I - 5].Y := I;
    MenuList[I + 9].Y := I;
  end;

end.

