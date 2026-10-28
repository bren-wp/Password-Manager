$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$releaseDir = (Resolve-Path 'build/windows/x64/runner/Release').Path
$destination = Join-Path (Get-Location) 'dist'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$portableZip = Join-Path $destination 'Veldigo-Windows-portable.zip'
if (Test-Path $portableZip) { Remove-Item -Force $portableZip }
Compress-Archive -Path (Join-Path $releaseDir '*') -DestinationPath $portableZip
$payload = 'packaging/portable/payload.zip'
$manifest = 'packaging/portable/payload-manifest.json'
Copy-Item $portableZip $payload -Force
# Bind each extracted file to the executable's embedded SHA-256 manifest.
$rootPath = $releaseDir + [System.IO.Path]::DirectorySeparatorChar
$entries = @(
  Get-ChildItem -LiteralPath $releaseDir -File -Recurse | Sort-Object FullName |
    ForEach-Object {
      [pscustomobject]@{
        Path = $_.FullName.Substring($rootPath.Length).Replace([System.IO.Path]::DirectorySeparatorChar, [char]'/')
        Sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
      }
    }
)
if ($entries.Count -eq 0) { throw 'No executable files to package' }
$json = ConvertTo-Json -InputObject @($entries) -Depth 3
[System.IO.File]::WriteAllText((Join-Path (Get-Location) $manifest),
  $json, [System.Text.UTF8Encoding]::new($false))
try {
  dotnet publish packaging/portable/VeldigoPortable.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o dist/launcher
  if ($LASTEXITCODE -ne 0) { throw 'Portable launcher compilation failed' }
  Copy-Item dist/launcher/VeldigoPortable.exe dist/Veldigo-portable.exe -Force
} finally {
  Remove-Item $payload -ErrorAction SilentlyContinue
  Remove-Item $manifest -ErrorAction SilentlyContinue
}
$env:VELDIGO_BUILD_DIR = $releaseDir
$env:VELDIGO_OUTPUT_DIR = $destination
$iscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
if (!(Test-Path $iscc)) { choco install innosetup -y --no-progress }
if (!(Test-Path $iscc)) { throw 'Inno Setup 6 is unavailable' }
& $iscc packaging/veldigo.iss
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed' }
Get-ChildItem dist/Veldigo* | Select-Object Name,Length
