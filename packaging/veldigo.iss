#define VeldigoVersion "0.2.0-preview.1"
#define VeldigoBuild GetEnv("VELDIGO_BUILD_DIR")
#define VeldigoOut GetEnv("VELDIGO_OUTPUT_DIR")
[Setup]
AppId={{92292D53-FF8B-4B61-9D07-1BC2E8308911}
AppName=Veldigo
AppVersion={#VeldigoVersion}
AppVerName=Veldigo {#VeldigoVersion}
AppPublisher=Brendigo
DefaultDirName={localappdata}\Programs\Veldigo
DefaultGroupName=Veldigo
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#VeldigoOut}
OutputBaseFilename=Veldigo-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\veldigo.exe
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: "{#VeldigoBuild}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{autoprograms}\Veldigo"; Filename: "{app}\veldigo.exe"
Name: "{autodesktop}\Veldigo"; Filename: "{app}\veldigo.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Stvori prečac na radnoj površini"; GroupDescription: "Prečaci:"

[Run]
Filename: "{app}\veldigo.exe"; Description: "Pokreni Veldigo"; Flags: nowait postinstall skipifsilent
