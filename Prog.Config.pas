unit Prog.Config;

{$include lem_directives.inc}

interface

uses
  Classes, SysUtils,
  Base.Utils,
  Prog.Types, Prog.Base;

const
  DEF_MISCOPTIONS = [
    TMiscOption.GradientBridges,
    TMiscOption.UseFastForward,
    TMiscOption.UseSaveStates,
    TMiscOption.UseHyperJumps,
    TMiscOption.ShowParticles,
    TMiscOption.ShowReplayMessages,
    TMiscOption.ShowFeedbackMessages,
    TMiscOption.ShowDefaultCursor,
    TMiscOption.RepairCustomLevelErrors
  ];

  SECRET_OPTIONS = [
    TMiscOption.UseCheatCodes,
    TMiscOption.UseCheatScrollingInPreviewScreen,
    TMiscOption.UseCheatKeyToSolveLevel,
    TMiscOption.UseFinder
  ];

  DEF_SOUNDOPTIONS = [
    TSoundOption.Sound,
    TSoundOption.Music
  ];

type
  TConfig = record
  public
    LoadedSecretOptions: TMiscOptions;
    MiscOptions: TMiscOptions;
    SoundOptions: TSoundOptions;
    OptionalMechanics: TOptionalMechanics;
    ZoomFactor: Integer;
    StyleName: string;
    Monitor: Integer;
    PathToStyles: string;
    PathToMusic: string;
    procedure Load;
    procedure Save;
    function GetMiscOption(index: TMiscOption): Boolean; inline;
    procedure SetMiscOption(index: TMiscOption; aValue: Boolean); inline;
    function GetSoundOption(index: TSoundOption): Boolean; inline;
    procedure SetSoundOption(index: TSoundOption; aValue: Boolean); inline;
    {
  // music options
    property MusicEnabled: Boolean index TSoundOption.Music read GetMiscOption write SetMiscOption;
    property SoundEnabled: Boolean index TSoundOption.Sound read GetSoundOption write SetSoundOption;
  // misc options
    property UseCheatCodes: Boolean index TMiscOption.UseCheatCodes read GetMiscOption write SetMiscOption;
    property GradientBridges: Boolean index TMiscOption.GradientBridges read GetMiscOption write SetMiscOption;
    property ShowParticles: Boolean index TMiscOption.ShowParticles read GetMiscOption write SetMiscOption;
    property UseFadeOut: Boolean index TMiscOption.UseFadeOut read GetMiscOption write SetMiscOption;
    property UseCheatScrollingInPreviewScreen: Boolean index TMiscOption.UseCheatScrollingInPreviewScreen read GetMiscOption write SetMiscOption;
    property ShowDefaultCursor: Boolean index TMiscOption.ShowDefaultCursor read GetMiscOption write SetMiscOption;
    }
  end;

  TMiscOptionEnum = Enum<TMiscOption>;
  TSoundOptionEnum = Enum<TSoundOption>;
  TOptionalMechanicEnum = Enum<TOptionalMechanic>;

implementation

function TConfig.GetMiscOption(index: TMiscOption): Boolean;
begin
  Result := index in MiscOptions;
end;

procedure TConfig.SetMiscOption(index: TMiscOption; aValue: Boolean);
begin
  case aValue of
    False: Exclude(MiscOptions, index);
    True: Include(MiscOptions, index);
  end;
end;

function TConfig.GetSoundOption(index: TSoundOption): Boolean;
begin
  Result := index in SoundOptions;
end;

procedure TConfig.SetSoundOption(index: TSoundOption; aValue: Boolean);
begin
  case aValue of
    False: Exclude(SoundOptions, index);
    True: Include(SoundOptions, index);
  end;
end;

procedure TConfig.Load;
var
  list: TStringList;
  entry, filename, value: string;
  misc: TMiscOption;
  snd: TSoundOption;
  mech: TOptionalMechanic;
  v: Integer;
begin
  // clear
  MiscOptions := DEF_MISCOPTIONS;
  SoundOptions := DEF_SOUNDOPTIONS;
  LoadedSecretOptions := [];
  ZoomFactor := 0;
  StyleName := 'Orig';
  Monitor := 0;

  filename := ReplaceFileExt(Consts.AppName, '.config');

  // set defaults if no configfile
  if not FileExists(filename) then
    Exit;

  list := TStringList.Create;
  try
    list.LoadFromFile(filename);
    // misc
    for misc :=  Low(TMiscOption) to High(TMiscOption) do begin
      entry := 'Misc.' + TMiscOptionEnum.AsString(misc);
      value := list.Values[entry].Trim;
      if value.Length = 1 then
        case value[1] of
          '0': Exclude(MiscOptions, misc);
          '1': Include(MiscOptions, misc);
        end;
      // we found a secret option in the config: keep in mem
      if value.Length = 1 then
        Include(LoadedSecretOptions, misc);
    end;

    // sound
    for snd := Low(TSoundOption) to High(TSoundOption) do begin
      entry := 'Sounds.' + TSoundOptionEnum.AsString(snd);
      value := list.Values[entry].Trim;
      if value.Length = 1 then
        case value[1] of
          '0': Exclude(SoundOptions, snd);
          '1': Include(SoundOptions, snd);
        end;
    end;

    // optional mechanics
    for mech := Low(TOptionalMechanic) to High(TOptionalMechanic) do begin
      entry := 'Mechanic.' + TOptionalMechanicEnum.AsString(mech);
      value := list.Values[entry].Trim;
      if value.Length = 1 then
        case value[1] of
          '0': Exclude(OptionalMechanics, mech);
          '1': Include(OptionalMechanics, mech);
        end;
    end;

    // zoom
    value := list.Values['Display.ZoomFactor'];
    if TryStrToInt(Value, v) and (v >= 0) and (v < 16) then
      ZoomFactor := v;
    // monitor
    value := list.Values['Display.Monitor'];
    if TryStrToInt(value, v) then
      Monitor := v;
    // style
    value := list.Values['Style'];
    if not value.IsEmpty then
      StyleName := value;
    // path to styles
    value := list.Values['PathToStyles'];
    if not value.IsEmpty then
      PathToStyles := value;
    // path to music
    value := list.Values['PathToMusic'];
    if not value.IsEmpty then
      PathToMusic := value;

  finally
    list.Free;
  end;
end;

procedure TConfig.Save;
var
  list: TStringList;
  filename, entry: string;
  misc: TMiscOption;
  snd: TSoundOption;
  mech: TOptionalMechanic;
begin
  filename := ReplaceFileExt(Consts.AppName, '.config');
  list := TStringList.Create;
  try
    // misc
    for misc :=  Low(TMiscOption) to High(TMiscOption) do begin
      entry := 'Misc.' + TMiscOptionEnum.AsString(misc);
      // only save secretoptions if they were already in the config
      if not (misc in SECRET_OPTIONS) or (misc in LoadedSecretOptions) then begin
        if misc in MiscOptions
        then list.Values[entry] := '1'
        else list.Values[entry] := '0'
      end;
    end;

    // sound
    for snd :=  Low(TSoundOption) to High(TSoundOption) do begin
      entry := 'Sounds.' + TSoundOptionEnum.AsString(snd);
      if snd in SoundOptions
      then list.Values[entry] := '1'
      else  list.Values[entry] := '0'
    end;

    // sound
    for mech :=  Low(TOptionalMechanic) to High(TOptionalMechanic) do begin
      entry := 'Mechanic.' + TOptionalMechanicEnum.AsString(mech);
      if mech in OptionalMechanics
      then list.Values[entry] := '1'
      else  list.Values[entry] := '0'
    end;

    // display
    list.Values['Display.Monitor'] := Monitor.ToString;
    list.Values['Display.ZoomFactor'] := ZoomFactor.ToString;

    // style
    list.Values['Style'] := StyleName;

    // path
    if PathToStyles <> '' then
      list.Values['PathToStyles'] := PathToStyles;

    // path
    if PathToStyles <> '' then
      list.Values['PathToMusic'] := PathToMusic;

    list.Sort;
    list.SaveToFile(filename);
  finally
    list.Free;
  end;
end;


end.

