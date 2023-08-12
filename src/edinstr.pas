unit EdInstr;

{$mode ObjFPC}

interface

uses
  Screen, Adlib, Keyboard, Input, Utils, Formats;

var
  CurInstr: PAdlibInstrument;
  IsInstr: Boolean;
  IsInstrTesting: Boolean = False;

procedure Loop;

implementation

uses
  Dialogs, Clipbrd;

const
  OP1_X = 16;
  OP2_X = 36;
  OP3_X = 56;
  OP4_X = 76;

type
  TEdInstrMenuItem = record
    X, Y: Byte;
  end;

var
  CurMenuPos: Byte = 1;
  CurInstrPos: Byte = 0;
  TestNote: TNepperNote;
  MenuList: array[0..53] of TEdInstrMenuItem;

procedure ResetParams;
begin                           
  Input.InputCursor := 1;
  Screen.SetCursorPosition(MenuList[CurMenuPos].X, MenuList[CurMenuPos].Y);
end;

procedure RenderTexts;
begin
  WriteText(0, 0, $1F, '                                   - Nepper -', 80);
  WriteText(0, 0, $1A, 'INSTRUMENT EDIT');
  WriteText(0, 1, $0E, '  [F1] Help [F2] Song/Pattern Editor [F3] Instrument Editor [ESC] Exit Nepper');

  WriteTextBack(OP1_X, 3, COLOR_LABEL, 'Inst. number:');
  WriteTextBack(OP1_X, 4, COLOR_LABEL, 'Synthesis mode:');
  WriteTextBack(OP1_X + 2, 6, $4E, '     Operator 1    ');
  WriteTextBack(OP1_X, 7,  COLOR_LABEL, 'Attack:');
  WriteTextBack(OP1_X, 8,  COLOR_LABEL, 'Decay:');
  WriteTextBack(OP1_X, 9,  COLOR_LABEL, 'Sustain:');
  WriteTextBack(OP1_X, 10, COLOR_LABEL, 'Release:');
  WriteTextBack(OP1_X, 11, COLOR_LABEL, 'Volume:');
  WriteTextBack(OP1_X, 12, COLOR_LABEL, 'Level scale:');
  WriteTextBack(OP1_X, 13, COLOR_LABEL, 'Multiplier:');
  WriteTextBack(OP1_X, 14, COLOR_LABEL, 'Waveform:');
  WriteTextBack(OP1_X, 15, COLOR_LABEL, 'Sustain Sound:');
  WriteTextBack(OP1_X, 16, COLOR_LABEL, 'Scale Envelope:');
  WriteTextBack(OP1_X, 17, COLOR_LABEL, 'Vibrato:');
  WriteTextBack(OP1_X, 18, COLOR_LABEL, 'Tremolo:');
  
  WriteTextBack(OP2_X, 3, COLOR_LABEL, 'Inst. name:');
  WriteTextBack(OP2_X, 4, COLOR_LABEL, 'Feedback:');
  WriteTextBack(OP2_X + 2, 6, $4E, '     Operator 2    ');
  WriteTextBack(OP2_X, 7,  COLOR_LABEL, 'Attack:');
  WriteTextBack(OP2_X, 8,  COLOR_LABEL, 'Decay:');
  WriteTextBack(OP2_X, 9,  COLOR_LABEL, 'Sustain:');
  WriteTextBack(OP2_X, 10, COLOR_LABEL, 'Release:');
  WriteTextBack(OP2_X, 11, COLOR_LABEL, 'Volume:');
  WriteTextBack(OP2_X, 12, COLOR_LABEL, 'Level scale:');
  WriteTextBack(OP2_X, 13, COLOR_LABEL, 'Multiplier:');
  WriteTextBack(OP2_X, 14, COLOR_LABEL, 'Waveform:');
  WriteTextBack(OP2_X, 15, COLOR_LABEL, 'Sustain Sound:');
  WriteTextBack(OP2_X, 16, COLOR_LABEL, 'Scale Envelope:');
  WriteTextBack(OP2_X, 17, COLOR_LABEL, 'Vibrato:');
  WriteTextBack(OP2_X, 18, COLOR_LABEL, 'Tremolo:');

  WriteTextBack(OP3_X, 4, COLOR_LABEL, 'Fine Tune:');
  WriteTextBack(OP3_X + 2, 6, $4E, '     Operator 3    ');
  WriteTextBack(OP3_X, 7,  COLOR_LABEL, 'Attack:');
  WriteTextBack(OP3_X, 8,  COLOR_LABEL, 'Decay:');
  WriteTextBack(OP3_X, 9,  COLOR_LABEL, 'Sustain:');
  WriteTextBack(OP3_X, 10, COLOR_LABEL, 'Release:');
  WriteTextBack(OP3_X, 11, COLOR_LABEL, 'Volume:');
  WriteTextBack(OP3_X, 12, COLOR_LABEL, 'Level scale:');
  WriteTextBack(OP3_X, 13, COLOR_LABEL, 'Multiplier:');
  WriteTextBack(OP3_X, 14, COLOR_LABEL, 'Waveform:');
  WriteTextBack(OP3_X, 15, COLOR_LABEL, 'Sustain Sound:');
  WriteTextBack(OP3_X, 16, COLOR_LABEL, 'Scale Envelope:');
  WriteTextBack(OP3_X, 17, COLOR_LABEL, 'Vibrato:');
  WriteTextBack(OP3_X, 18, COLOR_LABEL, 'Tremolo:');
                  
  WriteTextBack(OP4_X, 4, COLOR_LABEL, 'Panning:');
  WriteTextBack(OP4_X + 2, 6, $4E, '     Operator 4    ');
  WriteTextBack(OP4_X, 7,  COLOR_LABEL, 'Attack:');
  WriteTextBack(OP4_X, 8,  COLOR_LABEL, 'Decay:');
  WriteTextBack(OP4_X, 9,  COLOR_LABEL, 'Sustain:');
  WriteTextBack(OP4_X, 10, COLOR_LABEL, 'Release:');
  WriteTextBack(OP4_X, 11, COLOR_LABEL, 'Volume:');
  WriteTextBack(OP4_X, 12, COLOR_LABEL, 'Level scale:');
  WriteTextBack(OP4_X, 13, COLOR_LABEL, 'Multiplier:');
  WriteTextBack(OP4_X, 14, COLOR_LABEL, 'Waveform:');
  WriteTextBack(OP4_X, 15, COLOR_LABEL, 'Sustain Sound:');
  WriteTextBack(OP4_X, 16, COLOR_LABEL, 'Scale Envelope:');
  WriteTextBack(OP4_X, 17, COLOR_LABEL, 'Vibrato:');
  WriteTextBack(OP4_X, 18, COLOR_LABEL, 'Tremolo:');
                                      
  WriteTextBack(76, 21, COLOR_LABEL, 'Test operator mode:');
  WriteTextBack(76, 22, COLOR_LABEL, 'Test tone:');
  WriteText(0, 23, $0A, '[L] Load [<] Prev [SPC] Test  [+] Test Tone Up   [F10] Test operator mode');
  WriteText(0, 24, $0A, '[S] Save [>] Next [CR] Quiet  [-] Test Tone Down');
end;

procedure RenderInstrInfo;
var
  I: Byte;
  Ofs: Byte;
  S: String20;
begin
  WriteText(OP1_X + 1, 3, $0F, HexStrFast2(CurInstrPos));
  WriteText(OP1_X + 1, 4, $0F, HexStrFast2(CurInstr^.AlgFeedback.Alg2));
  WriteText(OP2_X + 1, 3, $0F, CurInstr^.Name, 20);
  WriteText(OP2_X + 1, 4, $0F, HexStrFast2(CurInstr^.AlgFeedback.Feedback));
  WriteText(OP3_X + 1, 4, $0F, HexStrFast2(CurInstr^.FineTune));              
  WriteText(OP4_X + 1, 4, $0F, ByteToPanning(CurInstr^.AlgFeedback.Panning));
  for I := 0 to 3 do
  begin
    Ofs := I * ((OP2_X + 2) - (OP1_X + 2));
    WriteText((OP1_X + 1) + Ofs, 7, $0F, HexStrFast2(CurInstr^.Operators[I].AttackDecay.Attack));
    WriteText((OP1_X + 1) + Ofs, 8, $0F, HexStrFast2(CurInstr^.Operators[I].AttackDecay.Decay));
    WriteText((OP1_X + 1) + Ofs, 9, $0F, HexStrFast2($F - CurInstr^.Operators[I].SustainRelease.Sustain));
    WriteText((OP1_X + 1) + Ofs, 10, $0F, HexStrFast2(CurInstr^.Operators[I].SustainRelease.Release));
    WriteText((OP1_X + 1) + Ofs, 11, $0F, HexStrFast2($3F - CurInstr^.Operators[I].Volume.Total));
    WriteText((OP1_X + 1) + Ofs, 12, $0F, HexStrFast2(CurInstr^.Operators[I].Volume.Scaling));
    WriteText((OP1_X + 1) + Ofs, 13, $0F, HexStrFast2(CurInstr^.Operators[I].Effect.ModFreqMult));;
    WriteText((OP1_X + 1) + Ofs, 14, $0F, HexStrFast2(CurInstr^.Operators[I].Waveform.Waveform));
    WriteText((OP1_X + 1) + Ofs, 15, $0F, ByteToYesNo(CurInstr^.Operators[I].Effect.EGTyp), 3); 
    WriteText((OP1_X + 1) + Ofs, 16, $0F, ByteToYesNo(CurInstr^.Operators[I].Effect.KSR), 3);
    WriteText((OP1_X + 1) + Ofs, 17, $0F, ByteToYesNo(CurInstr^.Operators[I].Effect.Vib), 3);
    WriteText((OP1_X + 1) + Ofs, 18, $0F, ByteToYesNo(CurInstr^.Operators[I].Effect.AmpMod), 3);
  end;
  Str(TestNote.Octave, S);
  WriteText(77, 22, $0F, ADLIB_NOTESYM_TABLE[TestNote.Note]);
  WriteText(79, 22, $0F, S);
  if Adlib.IsOPL3Enabled and CurInstr^.Is4Op then
    WriteText(77, 21, $0F, '4')
  else
    WriteText(77, 21, $0F, '2');
end;

procedure Loop;
var
  OldCurMenuPos: Byte;
  S: String40;
  V: Byte;
begin
  IsInstr := True;
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
          V := CurInstr^.AlgFeedback.Alg2;
          Input.InputHex2(S, V, 3);
          CurInstr^.AlgFeedback.Alg2 := V;
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
          Input.InputHex2(S, V, $7);
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
          Input.InputHex2(S, V, $7);
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
          V := Byte(CurInstr^.FineTune);
          Input.InputHex2(S, V, $FF);
          CurInstr^.FineTune := ShortInt(V);
        end;
      //
      29:
        begin
          V := CurInstr^.Operators[2].AttackDecay.Attack;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[2].AttackDecay.Attack := V;
        end;
      30:
        begin
          V := CurInstr^.Operators[2].AttackDecay.Decay;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[2].AttackDecay.Decay := V;
        end;
      31:
        begin
          V := $F - CurInstr^.Operators[2].SustainRelease.Sustain;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[2].SustainRelease.Sustain := $F - V;
        end;
      32:
        begin
          V := CurInstr^.Operators[2].SustainRelease.Release;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[2].SustainRelease.Release := V;
        end;
      33:
        begin
          V := $3F - CurInstr^.Operators[2].Volume.Total;
          Input.InputHex2(S, V, $3F);
          CurInstr^.Operators[2].Volume.Total := $3F - V;
        end;
      34:
        begin
          V := CurInstr^.Operators[2].Volume.Scaling;
          Input.InputHex2(S, V, 3);
          CurInstr^.Operators[2].Volume.Scaling := V;
        end;
      35:
        begin
          V := CurInstr^.Operators[2].Effect.ModFreqMult;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[2].Effect.ModFreqMult := V;
        end;
      36:
        begin
          V := CurInstr^.Operators[2].Waveform.Waveform;
          Input.InputHex2(S, V, $7);
          CurInstr^.Operators[2].Waveform.Waveform := V;
        end;
      37:
        begin
          V := CurInstr^.Operators[2].Effect.EGTyp;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[2].Effect.EGTyp := V;
        end;
      38:
        begin
          V := CurInstr^.Operators[2].Effect.KSR;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[2].Effect.KSR := V;
        end;
      39:
        begin
          V := CurInstr^.Operators[2].Effect.Vib;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[2].Effect.Vib := V;
        end;
      40:
        begin
          V := CurInstr^.Operators[2].Effect.AmpMod;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[2].Effect.AmpMod := V;
        end;
      //
      41:
        begin
          V := Byte(CurInstr^.AlgFeedback.Panning);
          Input.InputPanning(S, V);
          CurInstr^.AlgFeedback.Panning := V;
        end;
      //
      42:
        begin
          V := CurInstr^.Operators[3].AttackDecay.Attack;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[3].AttackDecay.Attack := V;
        end;
      43:
        begin
          V := CurInstr^.Operators[3].AttackDecay.Decay;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[3].AttackDecay.Decay := V;
        end;
      44:
        begin
          V := $F - CurInstr^.Operators[3].SustainRelease.Sustain;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[3].SustainRelease.Sustain := $F - V;
        end;
      45:
        begin
          V := CurInstr^.Operators[3].SustainRelease.Release;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[3].SustainRelease.Release := V;
        end;
      46:
        begin
          V := $3F - CurInstr^.Operators[3].Volume.Total;
          Input.InputHex2(S, V, $3F);
          CurInstr^.Operators[3].Volume.Total := $3F - V;
        end;
      47:
        begin
          V := CurInstr^.Operators[3].Volume.Scaling;
          Input.InputHex2(S, V, 3);
          CurInstr^.Operators[3].Volume.Scaling := V;
        end;
      48:
        begin
          V := CurInstr^.Operators[3].Effect.ModFreqMult;
          Input.InputHex2(S, V, $F);
          CurInstr^.Operators[3].Effect.ModFreqMult := V;
        end;
      49:
        begin
          V := CurInstr^.Operators[3].Waveform.Waveform;
          Input.InputHex2(S, V, $7);
          CurInstr^.Operators[3].Waveform.Waveform := V;
        end;
      50:
        begin
          V := CurInstr^.Operators[3].Effect.EGTyp;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[3].Effect.EGTyp := V;
        end;
      51:
        begin
          V := CurInstr^.Operators[3].Effect.KSR;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[3].Effect.KSR := V;
        end;
      52:
        begin
          V := CurInstr^.Operators[3].Effect.Vib;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[3].Effect.Vib := V;
        end;
      53:
        begin
          V := CurInstr^.Operators[3].Effect.AmpMod;
          Input.InputYesNo(S, V);
          CurInstr^.Operators[3].Effect.AmpMod := V;
        end;
    end;

    if KBInput.ScanCode < $FE then
      case KBInput.ScanCode of
        SCAN_LEFT:
          begin
            if CurMenuPos = 28 then
            begin
              Input.InputCursor := 2;
              CurMenuPos := 15;
            end else
            if CurMenuPos = 41 then
            begin
              Input.InputCursor := 2;
              CurMenuPos := 28;
            end else
            if CurMenuPos >= 27 then
            begin
              Input.InputCursor := 2;
              Dec(CurMenuPos, 13);
            end else
            if CurMenuPos >= 14 then
            begin
              Input.InputCursor := 2;
              Dec(CurMenuPos, 14);
            end;
            if CurMenuPos = 0 then
              Inc(CurMenuPos); 
            if CurMenuPos = 14 then
              Input.InputCursor := 1;
          end;
        SCAN_RIGHT:
          begin
            if CurMenuPos = 15 then
            begin
              Input.InputCursor := 1;
              CurMenuPos := 28;
            end else
            if CurMenuPos = 28 then
            begin
              Input.InputCursor := 1;
              CurMenuPos := 41;
            end else
            if CurMenuPos <= 14 then
            begin
              Input.InputCursor := 1;
              Inc(CurMenuPos, 14)
            end else
            if CurMenuPos <= 40 then
            begin
              Input.InputCursor := 1;
              Inc(CurMenuPos, 13)
            end;
            if CurMenuPos = 14 then
              Input.InputCursor := 1;
          end;
        SCAN_UP:
          begin
            if CurMenuPos > 1 then
              Dec(CurMenuPos);
            if (CurMenuPos = 14) or (CurMenuPos = 41) then
              Input.InputCursor := 1;
          end;
        SCAN_DOWN:
          begin
            if CurMenuPos < 53 then
              Inc(CurMenuPos);
            if (CurMenuPos = 14) or (CurMenuPos = 41) then
              Input.InputCursor := 1;
          end;
        SCAN_SPACE:
          begin
            if CurInstr^.Is4Op then
              V := 8
            else
              V := 5;
            Adlib.SetInstrument(V, CurInstr);
            AdLib.NoteClear(V);
            Adlib.NoteOn(V, TestNote.Note, TestNote.Octave, CurInstr^.FineTune);
            IsInstrTesting := True;
          end;
        SCAN_ENTER:
          begin
            Adlib.NoteClear(5);
            Adlib.NoteClear(8);
            IsInstrTesting := False;
          end;
        SCAN_F1:
          begin
            ShowHelpDialog('INSTR.TXT');
            RenderTexts;
            RenderInstrInfo;
            Screen.SetCursorPosition(MenuList[CurMenuPos].X + Input.InputCursor - 1, MenuList[CurMenuPos].Y);
            Continue;
          end;
        SCAN_C:
          begin
            if IsCtrl then
              Clipbrd.ClipbrdInstr := CurInstr^;
          end;
        SCAN_V:
          begin
            if IsCtrl then
            begin
              CurInstr^ := Clipbrd.ClipbrdInstr;
              RenderInstrInfo;
            end;
          end;
        SCAN_F10:
          begin
            CurInstr^.Is4Op := not CurInstr^.Is4Op;
            RenderInstrInfo;
          end
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
                      TestNote.Note := 1;
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
                      TestNote.Note := 12;
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
                  end; 
                  RenderTexts;
                  RenderInstrInfo;
                  Screen.SetCursorPosition(MenuList[CurMenuPos].X + Input.InputCursor - 1, MenuList[CurMenuPos].Y);
                  Continue;
                end;
              'l':
                begin
                  S := '';
                  if ShowInputDialog('Load Instrument', S) then
                  begin
                    if not LoadInstrument(S, CurInstr) then
                      ShowMessageDialog('Error', 'File not found / Invalid format!');
                    S := '';
                  end;    
                  RenderTexts;
                  RenderInstrInfo;
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
  until (KBInput.ScanCode = SCAN_ESC) or (KBInput.ScanCode = SCAN_F2);
  Adlib.NoteOff(8);
  IsInstr := False;
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
  for I := 28 to 40 do
    MenuList[I].X := OP3_X + 1;
  for I := 41 to 53 do
    MenuList[I].X := OP4_X + 1;
  // Y
  MenuList[0].Y := 3;
  MenuList[1].Y := 4;  
  MenuList[14].Y := 3;
  MenuList[15].Y := 4;
  MenuList[28].Y := 4; 
  MenuList[41].Y := 4;
  for I := 7 to 18 do
  begin
    MenuList[I - 5].Y := I;
    MenuList[I + 9].Y := I;
    MenuList[I + (29 - 7)].Y := I;     
    MenuList[I + (42 - 7)].Y := I;
  end;

end.

