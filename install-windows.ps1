# LookaRetro — installer for Windows 10/11 (turns a PC into a retro console).
#
# Usage (PowerShell):
#   powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
#   powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -System   # also disable sleep (run as admin)
#
# What it does (idempotent):
#   1. Installs RetroArch + Dolphin via winget.
#   2. Downloads DuckStation (PS1) and Pegasus Frontend (UI) into
#      %RETRO_HOME%\emulators\ (default %USERPROFILE%\Retro\emulators).
#   3. Downloads the RetroArch libretro cores for SNES/GBC/GBA/N64/DS.
#   4. Deploys low-latency configs, the ROM importer and the "LookaRetro"
#      Pegasus theme; wires Pegasus to the ROM library.
#   5. Generates metadata for any ROMs you already dropped in.
#   6. Adds Pegasus to the Windows startup folder (auto-boot).
#
#   -System: additionally sets standby/hibernate/monitor timeout to "never"
#   (requires an elevated PowerShell).

param([switch]$System)

$ErrorActionPreference = 'Stop'

$RETRO_HOME = if ($env:RETRO_HOME) { $env:RETRO_HOME } else { Join-Path $env:USERPROFILE 'Retro' }
$REPO_DIR   = $PSScriptRoot

$PEGASUS_URL      = 'https://github.com/mmatyas/pegasus-frontend/releases/download/weekly_2024w38/pegasus-fe_alpha16-82-gc3462e68_win-mingw-static.zip'
$DUCKSTATION_URL  = 'https://github.com/stenzek/duckstation/releases/latest/download/duckstation-windows-x64-release.zip'
$CORES_BASE       = 'https://buildbot.libretro.com/nightly/windows/x86_64/latest'

$CORES = @(
    'snes9x_libretro.dll',
    'gambatte_libretro.dll',
    'mgba_libretro.dll',
    'mupen64plus_next_libretro.dll',
    'melonds_libretro.dll'
)

$EMU_DIR    = Join-Path $RETRO_HOME 'emulators'
$SCRIPTS_DIR = Join-Path $RETRO_HOME 'scripts'
$RA_DIR      = Join-Path $env:APPDATA 'RetroArch'
$CORES_DIR   = Join-Path $RA_DIR 'cores'
$PEG_DIR     = Join-Path $env:LOCALAPPDATA 'pegasus-frontend'

function Info ($m) { Write-Host "==> $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Step ($m) { Write-Host ""; Write-Host "## $m" -ForegroundColor Cyan }

# ---------------------------------------------------------------------------
Step 'Installing RetroArch and Dolphin (winget)'
if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget install --id RetroArch-Team.RetroArch -e --silent --accept-source-agreements --accept-package-agreements
    winget install --id DolphinEmulator.Dolphin  -e --silent --accept-source-agreements --accept-package-agreements
} else {
    Warn 'winget not found. Install "App Installer" from the Microsoft Store, or install RetroArch/Dolphin manually.'
}

# ---------------------------------------------------------------------------
Step 'Downloading DuckStation and Pegasus Frontend'
New-Item -ItemType Directory -Force -Path $EMU_DIR | Out-Null
$tmp = Join-Path $env:TEMP ('lookaretro-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

function Get-Zip ($url, $name) {
    $zip = Join-Path $tmp ($name + '.zip')
    Info "Downloading $name..."
    & curl.exe -fL --retry 3 -o $zip $url
    if ($LASTEXITCODE -ne 0) { throw "Download failed: $url" }
    $dest = Join-Path $tmp $name
    Expand-Archive -Path $zip -DestinationPath $dest -Force
    return $dest
}

# DuckStation
$dsDir = Get-Zip $DUCKSTATION_URL 'DuckStation'
$dsDest = Join-Path $EMU_DIR 'DuckStation'
New-Item -ItemType Directory -Force -Path $dsDest | Out-Null
Copy-Item -Path (Join-Path $dsDir '*') -Destination $dsDest -Recurse -Force

# Pegasus
$pgDir = Get-Zip $PEGASUS_URL 'Pegasus'
$pgDest = Join-Path $EMU_DIR 'Pegasus'
New-Item -ItemType Directory -Force -Path $pgDest | Out-Null
Copy-Item -Path (Join-Path $pgDir '*') -Destination $pgDest -Recurse -Force

Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
Step 'Downloading RetroArch cores'
New-Item -ItemType Directory -Force -Path $CORES_DIR | Out-Null
foreach ($core in $CORES) {
    $target = Join-Path $CORES_DIR $core
    if (Test-Path $target) { Info "$core already present — skipping"; continue }
    Info "Downloading $core ..."
    & curl.exe -fL --retry 3 -o "$target.zip" "$CORES_BASE/$core.zip"
    if ($LASTEXITCODE -ne 0) { throw "Core download failed: $core" }
    Expand-Archive -Path "$target.zip" -DestinationPath $CORES_DIR -Force
    Remove-Item "$target.zip" -Force
}

# ---------------------------------------------------------------------------
Step 'Deploying configs, importer and theme'
New-Item -ItemType Directory -Force -Path $SCRIPTS_DIR | Out-Null
foreach ($s in 'snes','gbc','gba','n64','nds','psx','wii') {
    New-Item -ItemType Directory -Force -Path (Join-Path $RETRO_HOME "roms\$s") | Out-Null
}

Copy-Item (Join-Path $REPO_DIR 'lib\import-roms.ps1') (Join-Path $SCRIPTS_DIR 'import-roms.ps1') -Force

# RetroArch config = shared + windows driver snippet
New-Item -ItemType Directory -Force -Path $RA_DIR | Out-Null
$shared   = Get-Content (Join-Path $REPO_DIR 'config\retroarch.cfg') -Raw
$platform = Get-Content (Join-Path $REPO_DIR 'config\platform\windows.cfg') -Raw
$raCfg = Join-Path $RA_DIR 'retroarch.cfg'
if (Test-Path $raCfg) { Copy-Item $raCfg "$raCfg.lookaretro.bak" -Force }
Set-Content -Path $raCfg -Value ($shared + "`n" + $platform) -Encoding UTF8

# Per-core overrides
$coreOverrides = @{
    'Snes9x'           = 'snes9x.cfg'
    'Gambatte'         = 'gambatte.cfg'
    'mGBA'             = 'mgba.cfg'
    'melonDS'          = 'melonds.cfg'
    'Mupen64Plus-Next' = 'mupen64plus_next.cfg'
}
foreach ($name in $coreOverrides.Keys) {
    $dir = Join-Path $RA_DIR "config\$name"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Copy-Item (Join-Path $REPO_DIR "config\cores\$($coreOverrides[$name])") (Join-Path $dir "$name.cfg") -Force
}

# Dolphin GFX.ini (fullscreen)
$dolphinCfg = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Dolphin Emulator\Config'
New-Item -ItemType Directory -Force -Path $dolphinCfg | Out-Null
$gfxIni = Join-Path $dolphinCfg 'GFX.ini'
if (Test-Path $gfxIni) { Copy-Item $gfxIni "$gfxIni.lookaretro.bak" -Force }
Copy-Item (Join-Path $REPO_DIR 'config\dolphin\GFX.ini') $gfxIni -Force

# Pegasus theme
$themeDir = Join-Path $PEG_DIR 'themes\LookaRetro'
New-Item -ItemType Directory -Force -Path $themeDir | Out-Null
Copy-Item (Join-Path $REPO_DIR 'theme\LookaRetro\theme.cfg') (Join-Path $themeDir 'theme.cfg') -Force
Copy-Item (Join-Path $REPO_DIR 'theme\LookaRetro\theme.qml') (Join-Path $themeDir 'theme.qml') -Force

# ---------------------------------------------------------------------------
Step 'Configuring Pegasus Frontend'
New-Item -ItemType Directory -Force -Path $PEG_DIR | Out-Null

$settings = @(
    'general.fullscreen: true',
    'general.theme: themes/LookaRetro'
)
Set-Content -Path (Join-Path $PEG_DIR 'settings.txt') -Value $settings -Encoding UTF8

$gameDirs = @('# LookaRetro game directories')
foreach ($s in 'snes','gbc','gba','n64','nds','psx','wii') {
    $gameDirs += (Join-Path $RETRO_HOME "roms\$s")
}
Set-Content -Path (Join-Path $PEG_DIR 'game_dirs.txt') -Value $gameDirs -Encoding UTF8

# Resolved emulator paths (used by import-roms.ps1)
$raExe = Join-Path $EMU_DIR 'RetroArch\retroarch.exe'
if (-not (Test-Path $raExe)) { $raExe = 'C:\RetroArch-Win64\retroarch.exe' }
if (-not (Test-Path $raExe)) {
    $wingetRA = Get-Command retroarch -ErrorAction SilentlyContinue
    if ($wingetRA) { $raExe = $wingetRA.Source }
}
$emuLines = @(
    "`$RetroArch   = '" + ($raExe -replace "'", "''") + "'",
    "`$DuckStation = '" + ((Join-Path $EMU_DIR 'DuckStation\duckstation-qt-x64-ReleaseLTCG.exe') -replace "'", "''") + "'",
    "`$Dolphin     = '" + ((Join-Path $env:LOCALAPPDATA 'Dolphin Emulator\Dolphin.exe') -replace "'", "''") + "'",
    "`$CoresDir    = '" + ($CORES_DIR -replace "'", "''") + "'"
)
Set-Content -Path (Join-Path $SCRIPTS_DIR 'emulators.ps1') -Value $emuLines -Encoding UTF8

# ---------------------------------------------------------------------------
Step 'Scanning for ROMs'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $SCRIPTS_DIR 'import-roms.ps1')

# ---------------------------------------------------------------------------
Step 'Adding Pegasus to startup'
$startup = [Environment]::GetFolderPath('Startup')
$pegExe = Join-Path $EMU_DIR 'Pegasus\pegasus-fe.exe'
if (Test-Path $pegExe) {
    $lnk = Join-Path $startup 'LookaRetro (Pegasus).lnk'
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($lnk)
    $sc.TargetPath = $pegExe
    $sc.WorkingDirectory = Split-Path $pegExe
    $sc.Description = 'LookaRetro — Pegasus Frontend'
    $sc.Save()
    Info "Startup shortcut created: $lnk"
} else {
    Warn "pegasus-fe.exe not found at $pegExe — skipping startup shortcut."
}

# ---------------------------------------------------------------------------
if ($System) {
    Step 'Disabling sleep (elevated powercfg)'
    & powercfg /change standby-timeout-ac 0
    & powercfg /change hibernate-timeout-ac 0
    & powercfg /change monitor-timeout-ac 0
    Info 'Sleep/hibernate/monitor timeout set to never (AC).'
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "LookaRetro — installation complete." -ForegroundColor Cyan
Write-Host "  ROMs:     $RETRO_HOME\roms\<system>\"
Write-Host "  Importer: $SCRIPTS_DIR\import-roms.ps1"
Write-Host "  Pegasus:  $pegExe"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Drop ROMs into $RETRO_HOME\roms\<system>\ (see docs\ROMS.md)."
Write-Host "  2. Re-run: powershell -ExecutionPolicy Bypass -File `"$SCRIPTS_DIR\import-roms.ps1`""
Write-Host "  3. Configure controllers (docs\CONTROLS.md), then launch Pegasus."
