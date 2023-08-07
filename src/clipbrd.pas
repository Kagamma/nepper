unit Clipbrd;

{$mode ObjFPC}

interface

uses
  Formats, Adlib;

var
  ClipbrdCells: TNepperChannelCells;
  ClipbrdCellStart: ShortInt = -1;
  ClipbrdCellEnd: ShortInt;
  ClipbrdInstr: TAdlibInstrument;

implementation

initialization
  FillChar(ClipbrdCells[0], SizeOf(ClipbrdInstr), 0);
  FillChar(ClipbrdInstr.Operators[0], SizeOf(ClipbrdInstr), 0);

end.

