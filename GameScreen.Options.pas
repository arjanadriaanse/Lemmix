unit GameScreen.Options;

{$include lem_directives.inc}

interface

uses
  LCLIntf, LCLType, LMessages,
  Types, Classes, SysUtils, Generics.Collections, UITypes, Contnrs,
  Graphics, Controls, StdCtrls, ExtCtrls, Dialogs, Forms, GraphUtil, Grids,
  Base.Utils, Base.Bitmaps,
  Dos.Consts,
  Prog.Types, Prog.Base, Prog.Data, Prog.Cache,
  Game,
  Prog.App,
  Form.Base;

type
  //  This is a 'normal' windows screen
  TGameScreenOptions = class(TBaseDosForm)
  public
    const
      COLOR_DOS = TColor($8B3D48); //clWebDarkSlateBlue;
      COLOR_CUSTOM = TColor($2F6B55); //clWebDarkOliveGreen;
      COLOR_LEMMINI = TColor($2A2AA5); //clWebBrown;
  private
    fGrid: TDrawGrid;
    procedure Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Grid_DrawCell(Sender: TObject; aCol, aRow: Longint; aRect: TRect; aState: TGridDrawState);
    procedure Grid_CanSelectCell(Sender: TObject; aCol, aRow: Longint; var CanSelect: Boolean);
    procedure Grid_DblClick(Sender: TObject);
    function SelectedInfoToCell(info: Consts.TStyleInformation): TPoint;
    function CoordToLevelInfo(x, y: Integer): Consts.TStyleInformation;
    function GetCurrentInfo: Consts.TStyleInformation;
    procedure DoExitScreen(ok: Boolean);
  protected
    procedure BuildScreen; override;
  public
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

{ TGameScreenOptions }

constructor TGameScreenOptions.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  DoubleBuffered := True;
  Cursor := crDefault;
end;

destructor TGameScreenOptions.Destroy;
begin
  inherited Destroy;
end;

procedure TGameScreenOptions.DoExitScreen(ok: Boolean);
var
  info: Consts.TStyleInformation;
begin
  if not ok then
    CloseScreen(TGameScreenType.Menu)
  else begin
    info:= GetCurrentInfo;
    if Assigned(info) then
      App.NewStyleName := info.Name;
    CloseScreen(TGameScreenType.Menu);
  end;
end;

procedure TGameScreenOptions.BuildScreen;
var
  p: TPoint;
  lab: TLabel;
begin
  fGrid := TDrawGrid.Create(Self);
  fGrid.Parent := Self;
  fGrid.Align := alClient;
  //fGrid.AlignWithMargins := True;
  fGrid.Width := Width;
  fGrid.ColCount := (fGrid.Width - Scale(24)) div Scale(320);
  fGrid.ScrollBars := ssNone;
  fGrid.RowCount := Consts.StyleInformationlist.Count div fGrid.ColCount;
  if Consts.StyleInformationlist.Count mod fGrid.ColCount <> 0 then
    fGrid.RowCount := fGrid.RowCount + 1;
  fGrid.FixedRows := 0;
  fGrid.FixedCols := 0;
  fGrid.DefaultColWidth := 320;
  fGrid.DefaultRowHeight := 140;
  fGrid.Color := clBlack;
  fGrid.ParentColor := True;
  fGrid.DefaultDrawing := False;
  //fGrid.DrawingStyle := TGridDrawingStyle.gdsClassic;
  fGrid.BorderStyle := bsNone;
  fGrid.Options := fGrid.Options - [TGridOption.goDrawFocusSelected, TGridOption.goVertLine, TGridOption.goHorzLine, TGridOption.goRangeSelect];

  p := SelectedInfoToCell(Consts.FindStyleInfo(App.Style.Name));
  fGrid.Col := p.X;
  fGrid.Row := p.Y;

  //fGrid.Margins.SetBounds(8, 8, 8, 24);
  fGrid.OnDrawCell := Grid_DrawCell;
  fGrid.OnSelectCell := Grid_CanSelectCell;
  fGrid.OnDblClick := Grid_DblClick;

  lab := TLabel.Create(Self);
  lab.Parent := Self;
  lab.AutoSize := False;
  lab.Height := 20;
  lab.Align := alBottom;
  lab.Alignment := taCenter;
  lab.Font.Color := clgray;
  lab.Caption := App.StyleCache.GetTotalLevelCount.ToString + ' levels';

  OnKeyDown := Form_KeyDown;
end;

procedure TGameScreenOptions.Form_KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    DoExitScreen(False)
  else if Key = VK_RETURN then
    DoExitScreen(True);
end;

function TGameScreenOptions.CoordToLevelInfo(x, y: Integer): Consts.TStyleInformation;
var
  ix: Integer;
begin
  ix := y * fGrid.ColCount + x;
  if not Consts.StyleInformationlist.ValidIndex(ix) then
    Exit(nil);
  Result := Consts.StyleInformationlist[ix];
end;

function TGameScreenOptions.SelectedInfoToCell(info: Consts.TStyleInformation): TPoint;
var
  ix: Integer;
begin
  Result := Point(0, 0);
  ix := Consts.StyleInformationlist.IndexOf(info);
  Result.Y := ix div fGrid.ColCount;
  Result.X := ix mod fGrid.ColCount;
end;

function TGameScreenOptions.GetCurrentInfo: Consts.TStyleInformation;
begin
  Result := CoordToLevelInfo(fGrid.Col, fGrid.Row);
end;

procedure TGameScreenOptions.Grid_CanSelectCell(Sender: TObject; aCol, aRow: Longint; var CanSelect: Boolean);
begin
  CanSelect := Assigned(CoordToLevelInfo(aCol, aRow));
end;

procedure TGameScreenOptions.Grid_DblClick(Sender: TObject);
begin
  DoExitScreen(True);
end;

procedure TGameScreenOptions.Grid_DrawCell(Sender: TObject; aCol, aRow: Longint; aRect: TRect; aState: TGridDrawState);
var
  canv: TCanvas;
  information: Consts.TStyleInformation;
  myColor, myShadowColor: TColor;
  th, numberOfLevels: Integer;
  plural, txt: string;
  txtRect: TRect;
  i: Integer;
  style: TTextStyle;

begin
  canv := fGrid.Canvas;
  canv.Brush.Color := clBlack;
  canv.FillRect(aRect);

  information := CoordToLevelInfo(aCol, aRow);

  if not Assigned(information) then
    myColor := RGB(10,10,10)
  else if information.StyleDef = TStyleDef.User then begin
    if information.Family = TStyleFamily.DOS then
      myColor := COLOR_CUSTOM //clWebDarkOliveGreen//TColorRec.Darkgreen
    else
      myColor := COLOR_LEMMINI; //clWebBrown;//TColorRec.Brown;
  end
  else
    myColor := COLOR_DOS; //clWebDarkSlateBlue;//RGB(104, 88, 164); // purple

//  if Assigned(information) and (gdSelected in aState) then
  //  myColor := GetShadowColor(myColor, -8);

  aRect.Inflate(Scale(-4), Scale(-4));

  if not Assigned(information) then
    myShadowColor := myColor
  else if (gdSelected in aState) then
    myShadowColor := clYellow
  else
    myShadowColor := GetShadowColor(myColor, -20);

  for i := 0 to Scale(4) - 1 do begin
   canv.Brush.Color := myShadowColor;
   canv.FrameRect(aRect);
   aRect.Inflate(-1, -1);
//  canv.FillRect(aRect);
  end;

//  canv.Brush.Color := myColor;
//  canv.FillRect(aRect);

//  canv.FrameRect(aRect);
//  aRect.Inflate(-1, -1);


//  if Assigned(information) and (gdSelected in aState) then
//    canv.Brush.Color := clLime
//  else
//    canv.Brush.Color := myColor;//RGB(20,20,20);

//  aRect.Inflate(Scale(-4), Scale(-4));

  canv.Brush.Color := myColor;
  if not Assigned(information) then
    canv.FillRect(aRect)
  else
    DrawVerticalGradient(canv, aRect, myColor, GetShadowColor(myColor, -5));


//  aRect.Inflate(Scale(-2), Scale(-2));
//  canv.FrameRect(aRect);
//  aRect.Inflate(-1, -1);
//  if Assigned(information) and (gdSelected in aState) then
//  canv.FrameRect(aRect);

  if not Assigned(information) then
    Exit;

  numberOfLevels := App.StyleCache.GetLevelCount(information.Name);
  if numberOfLevels = 1 then
    plural := ''
  else
    plural := 's';

  Inc(aRect.Left, Scale(8));
  Dec(aRect.Right, Scale(8));
  txtRect := aRect;

  SetBkMode(canv.Handle, TRANSPARENT);

  // style
  canv.Font := Self.Font;
  canv.Font.Height := Scale(20);
  canv.Font.Color := clWhite;//myColor;
  canv.Font.Style := [fsBold];

  style.SingleLine := True;
  style.Layout := tlTop;
  style.Alignment := taCenter;

  th := canv.TextHeight('Wq');
  txtRect := aRect;
  Inc(txtRect.Top, Scale(8));
  txtRect.Height := th;

  if information.Description <> '' then
    txt := information.Description
  else
    txt := information.name;//canv.TextOut(x, y, information.Name);

  canv.TextRect(txtRect, txtRect.Left, txtRect.Top, txt, style);

  // number of levels + author
//  canv.Font.Color := clYellow;
  canv.Font.Height := Scale(12);
  canv.Font.Style := [];
  th := canv.TextHeight('Wq');
  txtRect.Offset(0, txtRect.Height + Scale(4));
  txtRect.Height := th;


  if information.Author.IsEmpty then
    txt := numberOfLevels.ToString + ' level' + plural
  else
    txt := numberOfLevels.ToString + ' level' + plural + ' by ' + information.Author;

  canv.TextRect(txtRect, txtRect.Left, txtRect.Top, txt, style);

  // location
  th := canv.TextHeight('Wq');
  txtRect.Offset(0, txtRect.Height);
  txtRect.Height := th;

  canv.Font.Color := GetShadowColor(myColor, 60);// clWhite;//clGray;
  if information.StyleDef = TStyleDef.User then
    txt := ExcludeTrailingPathDelimiter(Consts.PathToStyle[information.Name])//'Location: ' + 'C:\Data\Delphi\10.3\Lemmix2010\Output\Replay'//ExcludeTrailingPathDelimiter(Consts.PathToStyle[information.Name])
  else
    txt := 'Resource';

  style.EndEllipsis := True;
  canv.TextRect(txtRect, txtRect.Left, txtRect.Top, txt, style);
  style.EndEllipsis := False;

  canv.Font.Color := GetShadowColor(myColor, 120);//clWhite; //clSilver;
  txtRect.Offset(0, txtRect.Height + Scale(4));
//  dec(x, Scale(16));
  txtRect.Bottom := aRect.Bottom - Scale(8);
  txtRect.Left := aRect.Left;// + Scale(8);
  txtRect.Right := aRect.Right;// - Scale(8);
  txt := information.Info;
  if txt.IsEmpty then txt := 'No info available';

  style.Alignment := taLeftJustify;
  if canv.TextWidth(txt) < txtRect.Width then
    style.Layout := tlBottom
  else
    style.WordBreak := True;
  canv.TextRect(txtRect, txtRect.Left, txtRect.Top, txt, style);
end;

end.

