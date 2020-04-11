unit Base.Utils;

{$include lem_directives.inc}

interface
// Base.Utils must be without any lemmix program specific references.
// Some globals here, som baseclasses as well, and some basic stuff.

uses
  LCLIntf, LMessages,
  Types, Classes, SysUtils, TypInfo, IniFiles, Math, Contnrs, Generics.Collections,
  Rtti, {IOUtils,}
  Forms,
  GR32, GR32_LowLevel;

function InitializeLemmix: Boolean;

procedure DoThrow(const msg: string; const proc: string = '');

type
  TObjectHelper = class helper for TObject
  public
    class procedure Throw(const msg: string; const method: string = '');
  end;

type
  TBitmaps = class(TObjectList<TBitmap32>);

// string stuff
function LeadZeroStr(const i, zeros: Integer): string; inline;
function ThousandStr(Int: Integer): string; overload;
function ThousandStr(Int: Cardinal): string; overload;
function CutLeft(const S: string; aLen: integer): string;
function CutRight(const S: string; aLen: integer): string;
function ReplaceFileExt(const aFileName, aNewExt: string): string;
function StripInvalidFileChars(const S: string; removeDots: Boolean = True; removeDoubleSpaces: Boolean = True; trimAccess: Boolean = True): string;

// conversion string stuff
function RectStr(const R: TRect): string;
function PointStr(const P: TPoint): string;
function BytesToHex(const bytes: TBytes): string;
function YesNo(const b: Boolean): string; inline;

// rectangle stuff
function ZeroTopLeftRect(const r: TRect): TRect; inline;
procedure RectMove(var r: TRect; x, y: Integer); inline;

// int stuff
procedure Restrict(var i: Integer; aMin, aMax: Integer); overload; inline;
procedure Restrict(var s: Single; const aMin, aMax: Single); overload; inline;
function Percentage(Max, N: integer): integer;

// debug
procedure Dlg(const s: string);
{$ifdef debug}
procedure Log(const v: TValue); overload;
procedure Log(const v1, v2: TValue); overload;
procedure ClearLog;
{$endif debug}

// version
function GetAppVersionString(out major, minor, release, build: Integer): string;

// timing stuff
function MSBetween(const T1, T2: Int64): Int64; inline;

// simple timer mechanism
type
  TTicker = record
  strict private
    fLastTick     : Int64; // ticks
    fCurrentTick  : Int64; // ticks
    fInterval     : Cardinal;  // MS
  public
    procedure Reset(const aLastTick: Int64); inline;
    function Check(const aCurrentTick: Int64): Boolean; inline;
    property LastTick: Int64 read fLastTick;
    property CurrentTick: Int64 read fCurrentTick;
    property Interval: Cardinal read fInterval write fInterval;
  end;

  // just useless stub interfaces to prevent circular references
  IDosForm = interface
    ['{24535447-B742-4EB2-B688-825A1AD69349}']
  end;

  IMainForm = interface
  ['{24535447-B742-4EB2-B688-825A1AD69349}']
    procedure SwitchToNextMonitor;
    //procedure Interrupt;
  end;

  TDisplayInfo = record
  private
    fMainForm: IMainForm;
    fCurrentForm: IDosForm;
    fDpi: Integer; // the dpi of the monitor
    fMonitorIndex: Integer; // the current monitor index
    fBoundsRect: TRect; // the boundsrect of the current display
    fDpiScale: Single; // scale relative = Dpi/96
    procedure SetMonitorIndex(aValue: Integer);
  public
    property MainForm: IMainForm read fMainForm write fMainForm;
    property CurrentForm: IDosForm read fCurrentForm write fCurrentForm;
    property MonitorIndex: Integer read fMonitorIndex write SetMonitorIndex;

    property Dpi: Integer read fDpi;
    property DpiScale: Single read fDpiScale;
    property BoundsRect: TRect read fBoundsRect;
  end;

type
  Enum<T> = class sealed
  public
    // enum to string of set to string
    class function AsString(const aValue: T): string; static; inline;
  end;

implementation

// lowlevel program globals
var
  _UniqueName: string = 'Lemmix-1965-05-21';
  _UniqueMemoryMappedFileName: string = 'Lemmix-1965-05-21-memfile';
  _Mutex: THandle; // lemmix can only have 1 instance
  _Freq: Int64; // for timer
//  _MemoryMappedFileHandle: THandle; // for restarting lemmix with new parameter
//  _LemmixMemoryMappedRecord: PLemmixMemoryMappedRecord; // the pointer
  CurrentDisplay: TDisplayInfo; // info on monitor and currently active form

procedure DoThrow(const msg: string; const proc: string = '');
// generic invalid operation exception for procedues
var
  txt: string;
begin
  txt := msg;
  if proc <> '' then
    txt := txt + sLineBreak + 'Proc: ' + proc;
  raise EInvalidOperation.Create(txt) at get_caller_addr(get_frame),
    get_caller_frame(get_frame);
end;

class procedure TObjectHelper.Throw(const msg: string; const method: string = '');
// generic object helper for invalid operation exception from method of whichever object
var
  classString: string;
  txt: string;
begin
  classString := ClassName;
  if classString.StartsWith('T') then
    classString := Copy(classString, 2, Length(ClassString));
  txt := msg + sLineBreak + sLineBreak + 'Error from: ' + classString + sLineBreak + 'Unit: ' + Unitname;
  if method <> '' then
    txt := txt + sLineBreak + 'Method: ' + method;
  raise EInvalidOperation.Create(txt) at get_caller_addr(get_frame),
    get_caller_frame(get_frame);
end;

{ TDisplayInfo }

procedure TDisplayInfo.SetMonitorIndex(aValue: Integer);
var
  monitor: TMonitor;
begin
  if (aValue < 0) or (aValue >= Screen.MonitorCount) then
    aValue := 0;
  fMonitorIndex := aValue;
  monitor := Screen.Monitors[fMonitorIndex];
  fDpi := monitor.PixelsPerInch;
  fDpiScale := fDpi / 96;
  fBoundsRect := monitor.BoundsRect;
end;

{ Enum }

class function Enum<T>.AsString(const aValue: T): string;
// alleen aanroepen voor enum of set met typeinfo
begin
  Result := TValue.From<T>(aValue).ToString;
end;

function LeadZeroStr(const i, zeros: Integer): string; inline;
begin
  Result := i.ToString.PadLeft(zeros, '0');
end;

function ThousandStr(Int: Integer): string;
begin
  Result := FloatToStrF(Int / 1, ffNumber, 15, 0);
end;

function ThousandStr(Int: Cardinal): string;
begin
  Result := FloatToStrF(Int / 1, ffNumber, 15, 0);
end;

function CutLeft(const S: string; aLen: integer): string;
begin
  Result := Copy(S, aLen + 1, Length(S));
end;

function CutRight(const S: string; aLen: integer): string;
begin
  Result := Copy(S, 1, Length(S) - aLen);
end;

function ZeroTopLeftRect(const r: TRect): TRect;
begin
  Result := r;
  Result.Offset(-Result.Left, -Result.Top);
end;

procedure RectMove(var r: TRect; x, y: Integer);
begin
  r.Offset(x, y);
end;

procedure Restrict(var i: Integer; aMin, aMax: Integer);
begin
  i := EnsureRange(i, aMin, aMax);
end;

procedure Restrict(var s: Single; const aMin, aMax: Single); overload;
begin
  s := EnsureRange(s, aMin, aMax);
end;

function Percentage(Max, N: integer): integer;
begin
  if Max = 0 then
    Result := 0
  else
    Result := Trunc((N/Max) * 100);
end;

function ReplaceFileExt(const aFileName, aNewExt: string): string;
var
  Ext, NewExt: string;
begin
  Ext := ExtractFileExt(aFileName);
  NewExt := aNewExt;
  if (NewExt <> '') and not NewExt.StartsWith('.') then
    NewExt := '.' + NewExt;
  if Ext <> '' then
    Result := Copy(aFileName, 1, Length(aFileName) - Length(Ext)) + NewExt
  else
    Result := aFilename + NewExt;
end;

function StripInvalidFileChars(const S: string; removeDots: Boolean = True; removeDoubleSpaces: Boolean = True; trimAccess: Boolean = True): string;
var
  C: Char;
begin
  Result := '';
  for C in S do
    //if TPath.IsValidFileNameChar(C) then
      Result := Result + C;

  if removeDoubleSpaces then
    while Pos('  ', Result) > 0 do
      Result := Result.Replace('  ', '');

  if removeDots then
    while Pos('.', Result) > 0 do
      Result := Result.Replace('.', '');

  if trimAccess then
    Result := Result.Trim;
end;

function RectStr(const R: TRect): string;
begin
  Result := '(' + R.Left.ToString + ',' + R.Top.ToString + ',' +R.Right.ToString + ',' +R.Bottom.ToString + ')';
end;

function PointStr(const P: TPoint): string;
begin
  Result := '(' + P.X.ToString + ',' + P.Y.ToString + ')';
end;

function BytesToHex(const bytes: TBytes): string;
var
  ix: Integer;
  i: Integer;
  h: string;
begin
  SetLength(Result, Length(Bytes) * 2);
  ix := 1;
  for i := 0 to Length(Bytes) - 1 do begin
    h := IntToHex(bytes[i], 2);
    Move(h[1], Result[ix], SizeOf(Char) * 2);
    Inc(ix, 2);
  end;
end;

function YesNo(const b: Boolean): string; inline;
begin
  if b then Result := 'yes' else Result := 'no';
end;

procedure Dlg(const s: string);
begin
  MessageBox(0, Pchar(s), 'Lemmix', 0); // todo: this messes with focus controls. not restored ok (test out in Finder screen)
end;

{$ifdef debug}
var
  LogCalls: Integer;

procedure Log(const v: TValue);
var
  txtFile: TextFile;
  path: string;
begin
  path := ExtractFilePath(ParamStr(0));
  Assign(txtFile, path + 'log.txt');
  if not FileExists(path + 'log.txt') or (LogCalls = 0) then
    Rewrite(txtFile)
  else
    Append(txtFile);
  WriteLn(txtFile, v.ToString);
  CloseFile(txtFile);
  Inc(LogCalls);
end;

procedure Log(const v1, v2: TValue); overload;
begin
  Log(v1.ToString + ', ' + v2.ToString);
end;

procedure ClearLog;
begin
  DeleteFile('log.txt');
end;
{$endif debug}

function GetAppVersionString(out major, minor, release, build: Integer): string;
begin
  major := 0;
  minor := 0;
  release := 0;
  build := 0;

  Result := Format('%d.%d.%d', [major, minor, release]);
end;

function MSBetween(const T1, T2: Int64): Int64;
// returns the difference in milliseconds between 2 values, calculated with QueryTimer
begin
  if T2 > T1 then
    Result := Trunc(1000 * ((T2 - T1) / _Freq))
  else
    Result := Trunc(1000 * ((T1 - T2) / _Freq))
end;

{ TTicker }

procedure TTicker.Reset(const aLastTick: Int64);
begin
  fLastTick := aLastTick;
  fCurrentTick := aLastTick;
end;

function TTicker.Check(const aCurrentTick: Int64): Boolean;
begin
  Result := (aCurrentTick > fLastTick) and (Trunc(1000 * ((aCurrentTick - fLastTick) / _Freq)) >= fInterval);
end;

function InitializeLemmix: Boolean;
begin
  Result := True;
end;

initialization
  CurrentDisplay.fDpiScale := 1.0;
//finalization
//  FinalizeLemmix;
end.


