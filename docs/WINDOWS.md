# LookaRetro no Windows

Guia específico para Windows 10/11.

## Requisitos

- Windows 10 (1809+) ou Windows 11
- **winget** (App Installer) — já vem no Windows 11; no 10, instale pela Microsoft Store.
- PowerShell 5.1+ (padrão do Windows)

## Instalação

```powershell
cd LookaRetro
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1
```

Para também **desativar a suspensão/hibernação** (o equivalente a "continuar rodando"), rode como administrador:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -System
```

### O que o script faz

1. Instala **RetroArch** e **Dolphin** via winget.
2. Baixa **DuckStation** e **Pegasus Frontend** (zips oficiais) para `%USERPROFILE%\Retro\emulators\`.
3. Baixa os cores do RetroArch para `%APPDATA%\RetroArch\cores\`.
4. Aplica config de baixo lag em `%APPDATA%\RetroArch\retroarch.cfg` (driver D3D11/Wasapi) e fullscreen no Dolphin.
5. Instala o tema **LookaRetro** em `%LOCALAPPDATA%\pegasus-frontend\themes\`.
6. Configura o Pegasus (`settings.txt` + `game_dirs.txt`).
7. Gera a lista de jogos (`import-roms.ps1`).
8. Cria um atalho no **Startup** para o Pegasus abrir no login.
9. Com `-System`: `powercfg` define suspensão/hibernação/monitor como **nunca**.

## Adicionando jogos

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Retro\scripts\import-roms.ps1"
```

A pasta raiz é `%USERPROFILE%\Retro\roms\<sistema>\`.

> O importador gera comandos de inicialização **diretos** (apontando para o `.exe` de cada emulador) porque o Pegasus no Windows não executa `.bat` automaticamente — ele só roda `.exe` (e atalhos `.lnk`). Os caminhos resolvidos ficam em `%USERPROFILE%\Retro\scripts\emulators.ps1`.

## Caminhos importantes

| O quê | Onde |
|---|---|
| ROMs | `%USERPROFILE%\Retro\roms\` |
| Emuladores baixados | `%USERPROFILE%\Retro\emulators\` |
| Config do RetroArch | `%APPDATA%\RetroArch\` (cores em `\cores`) |
| Config do Pegasus | `%LOCALAPPDATA%\pegasus-frontend\` |
| Config do Dolphin | `Documentos\Dolphin Emulator\Config\` |
| Emuladores resolvidos | `%USERPROFILE%\Retro\scripts\emulators.ps1` |

## Se algo não abrir

1. Confirme que o emulador existe: rode o `.exe` manualmente.
2. Edite `%USERPROFILE%\Retro\scripts\emulators.ps1` com os caminhos corretos e re-execute o importador.
3. Para RetroArch/Dolphin instalados por winget em local não padrão, use `where.exe retroarch` / `where.exe Dolphin` no `cmd` para achar o caminho.

## Reverter

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall-windows.ps1 -Apply
```

Remove o atalho do Startup e restaura os timeouts de energia padrão. Emuladores e ROMs ficam intactos.
