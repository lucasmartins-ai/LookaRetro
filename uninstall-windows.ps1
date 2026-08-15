# LookaRetro — reverts the Windows changes applied by install-windows.ps1.
# Does NOT remove the emulators or your ROMs.
#
# Usage (PowerShell):
#   powershell -ExecutionPolicy Bypass -File .\uninstall-windows.ps1 -Apply

param([switch]$Apply)

$startup = [Environment]::GetFolderPath('Startup')
$lnk = Join-Path $startup 'LookaRetro (Pegasus).lnk'

function Revert($desc, [scriptblock]$action) {
    if ($Apply) {
        Write-Host "==> $desc"
        & $action
    } else {
        Write-Host "[dry-run] $desc"
    }
}

Revert 'Removing startup shortcut' {
    if (Test-Path $lnk) { Remove-Item $lnk -Force }
}

Revert 'Restoring default sleep timeouts (standby 30 min)' {
    & powercfg /change standby-timeout-ac 30
    & powercfg /change hibernate-timeout-ac 30
    & powercfg /change monitor-timeout-ac 10
}

Write-Host ""
Write-Host "Done. Emulators, configs and ROMs were left untouched."
Write-Host "Run with -Apply to actually revert."
