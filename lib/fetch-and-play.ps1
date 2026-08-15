# LookaRetro — fetch-and-play (Windows).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\fetch-and-play.ps1 <system> <target-file> <url>
#
# Downloads the open-source ROM on first play (if the target is still a 0-byte
# stub), then launches it. Deployed to %RETRO_HOME%\scripts\fetch-and-play.ps1.

param([string]$System, [string]$Target, [string]$Url)

$ErrorActionPreference = 'Stop'

if (-not $System -or -not $Target -or -not $Url) {
    Write-Host "Usage: fetch-and-play.ps1 <system> <target-file> <url>" -ForegroundColor Red
    exit 2
}

$RETRO_HOME = if ($env:RETRO_HOME) { $env:RETRO_HOME } else { Join-Path $env:USERPROFILE 'Retro' }
$EMU_FILE = Join-Path $RETRO_HOME 'scripts\emulators.ps1'
if (Test-Path $EMU_FILE) { . $EMU_FILE }

function Resolve-First {
    param([string[]]$Candidates)
    foreach ($c in $Candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

if (-not $RetroArch   -or -not (Test-Path $RetroArch))   { $RetroArch   = Resolve-First @($env:RETROARCH, (Join-Path $RETRO_HOME 'emulators\RetroArch\retroarch.exe'), 'C:\RetroArch-Win64\retroarch.exe') }
if (-not $DuckStation -or -not (Test-Path $DuckStation)) { $DuckStation = Resolve-First @($env:DUCKSTATION, (Join-Path $RETRO_HOME 'emulators\DuckStation\duckstation-qt-x64-ReleaseLTCG.exe')) }
if (-not $Dolphin     -or -not (Test-Path $Dolphin))     { $Dolphin     = Resolve-First @($env:DOLPHIN, (Join-Path $RETRO_HOME 'emulators\Dolphin\Dolphin.exe'), (Join-Path $env:LOCALAPPDATA 'Dolphin Emulator\Dolphin.exe')) }
if (-not $CoresDir    -or -not (Test-Path $CoresDir))    { $CoresDir    = Resolve-First @($env:CORES_DIR, (Join-Path $env:APPDATA 'RetroArch\cores'), (Join-Path $RETRO_HOME 'emulators\RetroArch\cores')) }

function Rom-Extensions {
    switch ($System) {
        'gbc'  { @('gb','gbc') }
        'gba'  { @('gba','agb') }
        'snes' { @('sfc','smc','fig','swc') }
        'n64'  { @('z64','n64','v64','ndd') }
        'nds'  { @('nds') }
        'psx'  { @('cue','chd','pbp','iso') }
        'wii'  { @('wbfs','rvz','iso') }
        default { @() }
    }
}

# --- download if needed ----------------------------------------------------
$fi = Get-Item -LiteralPath $Target -ErrorAction SilentlyContinue
if (-not $fi -or $fi.Length -eq 0) {
    Write-Host "LookaRetro: downloading $(Split-Path $Target -Leaf) ..."
    $tmp = Join-Path $env:TEMP ('lookaretro-fetch-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    $dl = Join-Path $tmp 'download'

    & curl.exe -fL --retry 3 -o $dl $Url
    if ($LASTEXITCODE -ne 0) { Write-Host "Download failed: $Url" -ForegroundColor Red; exit 1 }

    if ($Url -like '*.zip') {
        $extracted = Join-Path $tmp 'extracted'
        Expand-Archive -Path $dl -DestinationPath $extracted -Force
        $found = $null
        foreach ($e in Rom-Extensions) {
            $found = Get-ChildItem -Path $extracted -Recurse -Filter "*.$e" -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) { break }
        }
        if (-not $found) { Write-Host "No ROM found inside $Url" -ForegroundColor Red; exit 1 }
        Copy-Item $found.FullName $Target -Force
    } else {
        Copy-Item $dl $Target -Force
    }
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    Write-Host "LookaRetro: saved to $Target"
}

# --- launch ---------------------------------------------------------------
$cores = @{ snes='snes9x_libretro'; gbc='gambatte_libretro'; gba='mgba_libretro'; n64='mupen64plus_next_libretro'; nds='melonds_libretro' }

switch ($System) {
    'psx'  { & $DuckStation -fastboot -fullscreen -- $Target }
    'wii'  { & $Dolphin -e $Target }
    default {
        $core = $cores[$System]
        if (-not $core) { Write-Host "Unknown system: $System" -ForegroundColor Red; exit 2 }
        & $RetroArch -L (Join-Path $CoresDir ($core + '.dll')) $Target
    }
}
