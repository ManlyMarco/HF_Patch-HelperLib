#include "Translations.iss"
; Szumqcu is unique for tracking
#define KoiDiscordLink "https://discord.gg/Szumqcu"
#define IsDiscordLink "https://discord.gg/illusionsoft"

[Setup]
AppPublisher=ManlyMarco

AppVersion={#VERSION}
VersionInfoVersion={#VERSION}

Uninstallable=no
DisableProgramGroupPage=yes
OutputDir=.\Output
DirExistsWarning=no
AppendDefaultDirName=no

SolidCompression=yes

WizardSmallImageFile={#__DIR__}\hf.bmp
WizardImageStretch=yes
WizardImageBackColor=$FFFFFF
WizardImageFile=banner.bmp
SetupIconFile={#__DIR__}\icon.ico
InfoBeforeFile=INFO.rtf
InfoAfterFile=Plugin Readme.md
LicenseFile=LICENSE_page

DisableWelcomePage=no

ArchitecturesInstallIn64BitMode=x64os
CloseApplications=yes
RestartApplications=no
CloseApplicationsFilter=*.exe,*.dll

DefaultDirName={code:GetDefaultDirName}

WizardStyle=modern
WizardSizePercent=120,150

[Files]
Source: "{#__DIR__}\bin\HelperLib.dll";   DestDir: "{app}"      ; Flags: dontcopy
Source: "Plugin Readme.md";               DestDir: "{app}"

[Code]
procedure FindInstallLocation(srcPath, companyName, gameName, gameNameSteam: String; out strout: WideString);
external 'FindInstallLocation@files:HelperLib.dll stdcall';

procedure TestInstallLocation(appPath, srcPath, gameName, gameNameSteam: String; out errorStr: WideString; out warnStr: WideString);
external 'TestInstallLocation@files:HelperLib.dll stdcall';

procedure CreateBackup(appPath, srcPath: String);
external 'CreateBackup@files:HelperLib.dll stdcall';

procedure WriteVersionFile(appPath, srcPath, version: String);
external 'WriteVersionFile@files:HelperLib.dll stdcall';

procedure FixPermissions(appPath, srcPath: String);
external 'FixPermissions@files:HelperLib.dll stdcall';

procedure FixConfigIllusion(appPath, srcPath: String);
external 'FixConfigIllusion@files:HelperLib.dll stdcall';

procedure FixConfigKoikatsu(appPath, srcPath: String);
external 'FixConfigKoikatsu@files:HelperLib.dll stdcall';

procedure RemoveModsExceptModpacks(appPath, srcPath: String);
external 'RemoveModsExceptModpacks@files:HelperLib.dll stdcall';

procedure RemoveSideloaderDuplicates(appPath, srcPath: String);
external 'RemoveSideloaderDuplicates@files:HelperLib.dll stdcall';

procedure RemoveNonstandardListfiles(appPath, srcPath: String);
external 'RemoveNonstandardListfiles@files:HelperLib.dll stdcall';

procedure VerifyFiles(srcexe: String; out errormsg: WideString);
external 'VerifyFiles@files:HelperLib.dll stdcall';

function GetDefaultDirName(Param: string): string;
var
  str: WideString;
begin
  FindInstallLocation(ExpandConstant('{src}'), '{#CompanyName}', '{#GameName}', '{#GameNameSteam}', str);
  Result := str;
end;

<event('NextButtonClick')>
function NextButtonClick_Common(CurPageID: Integer): Boolean;
var
  errorStr: WideString;
  warnStr: WideString;
begin
  // allow the setup turning to the next page
  Result := True;

  if (CurPageID = wpInfoBefore) then
  begin
      if (FileExists('C:\windows\system32\winecfg.exe')) then
      begin
          if (MsgBox('Since you are running under Linux you must perform additional steps at the end of the installation.'#13#10#13#10'Read the Linux guides linked on this page before continuing. Click No to continue.', mbError, MB_YESNO) = IDYES) then
          begin
            Result := False;
          end;
      end;
  end;
  
  if (CurPageID = wpSelectDir) then
  begin
    TestInstallLocation(ExpandConstant('{app}'), ExpandConstant('{src}'), '{#GameName}', '{#GameNameSteam}', errorStr, warnStr);
    if not (errorStr = '') then
    begin
      MsgBox(ExpandConstant(errorStr), mbCriticalError, MB_OK);
      Result := False;
    end
    else
    begin
      if not (warnStr = '') then
        SuppressibleMsgBox(ExpandConstant(warnStr), mbError, MB_OK, 0);
    end;
  end;
end;

procedure DeletePluginsAndConfig(deleteConfig, deletePlugins: Boolean);
var 
  discard: Integer;
begin
  // Remove BepInEx folder
  if deleteConfig and deletePlugins then
  begin
    DelTree(ExpandConstant('{app}\BepInEx'), True, True, True);
  end
  else
  begin
    // Or only remove plugins
    if deletePlugins then
    begin
      DelTree(ExpandConstant('{app}\BepInEx\plugins'), True, True, True);
      DelTree(ExpandConstant('{app}\BepInEx\patchers'), True, True, True);
      DelTree(ExpandConstant('{app}\BepInEx\IPA'), True, True, True);
      Exec(ExpandConstant('{cmd}'), '/c del *.dll', ExpandConstant('{app}\BepInEx'), SW_HIDE, ewWaitUntilTerminated, discard);
      Exec(ExpandConstant('{cmd}'), '/c del *.dl_', ExpandConstant('{app}\BepInEx'), SW_HIDE, ewWaitUntilTerminated, discard);
    end;
    // Or remove settings
    if deleteConfig then
    begin
      DeleteFile(ExpandConstant('{app}\BepInEx\config.ini'));
      DelTree(ExpandConstant('{app}\BepInEx\config'), True, True, True);
    end;
  end;
end;

procedure MassTaskKill (Params: array of String);
var
  I: Integer;
  discard: Integer;
begin
  try
    for I := 0 to High(Params) do
    begin
      Exec('taskkill', '/F /IM ' + Params[I], ExpandConstant('{app}'), SW_HIDE, ewWaitUntilTerminated, discard);
    end;
  except
    ShowExceptionMessage();
  end;
end;

[Setup]

// #expr SaveToFile(AddBackslash(SourcePath) + "Preprocessed.iss")