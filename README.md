# LookaRetro 🕹️

Transforme um PC (ou Mac) em um **console retro** com interface bonita, quase zero input lag e persistência (continua rodando com a tampa fechada / sem hibernar).

- **UI/UX:** [Pegasus Frontend](https://pegasus-frontend.org) (open source) com o tema customizado **LookaRetro** — visual retrô em **pixel-art (Nintendo) + Senhor dos Anéis**, centro de seleção aprimorado com halo do Um Anel, modal de saída segura, scanlines de CRT e a marca **LookaDev**.
- **Emuladores (todos open source):** RetroArch (SNES/GBC/GBA/N64/DS), DuckStation (PS1), Dolphin (Wii), Azahar (3DS), Ryujinx (Switch), Vita3K (PS Vita).
- **Sistemas:** SNES · Game Boy Color · Game Boy Advance · Nintendo 64 · Nintendo DS · PlayStation 1 · Wii · Nintendo 3DS · Nintendo Switch · PlayStation Vita.
- **Plataformas:** macOS (Apple Silicon) · Windows 10/11 · Linux (Flatpak).
- **Catálogo Open Source:** coleção de jogos homebrew com **download automático** na primeira execução (Adjustris, uCity, Celeste Classic, demos SNES/N64…) — veja [docs/ROMS.md](docs/ROMS.md).

> **Nota sobre ROMs:** jogos comerciais (Zelda, Pokémon, Tekken, Gran Turismo, Digimon etc.) **não são open source** e são protegidos por copyright. Este projeto cuida de **toda a parte técnica** (emuladores, interface, configs) — as ROMs desses títulos devem vir de **cópias que você mesmo extraiu** dos seus cartuchos/discos. Existem alternativas genuinamente open source (homebrew) listadas em [docs/ROMS.md](docs/ROMS.md).

---

## Instalação rápida

| Plataforma | Comando |
|---|---|
| **macOS** | `./install-macos.sh` (+ `./install-macos.sh --system` p/ persistência) |
| **Windows** | `powershell -ExecutionPolicy Bypass -File .\install-windows.ps1` |
| **Linux** | `./install-linux.sh` (+ `./install-linux.sh --system` p/ tampa fechada) |

Cada instalador: baixa/instala os emuladores, implanta as configs de baixo lag e alta fidelidade gráfica, instala o tema **LookaRetro**, liga o Pegasus às pastas de ROMs e gera a lista de jogos.

Guia detalhado por plataforma: [docs/WINDOWS.md](docs/WINDOWS.md) · [docs/LINUX.md](docs/LINUX.md) · macOS na seção abaixo.

---

## Emuladores por plataforma

| Sistema | macOS (arm64) | Windows | Linux (Flatpak) |
|---|---|---|---|
| SNES/GBC/GBA/N64/DS | RetroArch (universal/Metal, arm64) | RetroArch (winget) | RetroArch (`org.libretro.RetroArch`) |
| PlayStation 1 | DuckStation (nativo) | DuckStation (zip) | DuckStation (`org.duckstation.DuckStation`) |
| Wii | Dolphin (nativo) | Dolphin (winget) | Dolphin (`org.DolphinEmu.dolphin-emu`) |
| Nintendo 3DS | Azahar (nativo arm64) | Azahar / Lime3DS | Azahar (`azahar.AppImage`) |
| Nintendo Switch | Ryujinx (universal arm64) | Ryujinx | Ryujinx |
| PlayStation Vita | Vita3K (nativo arm64 / Vulkan 1080p) | Vita3K | Vita3K (`org.vita3k.Vita3K`) |
| UI | Pegasus (x86_64/Rosetta 2) | Pegasus (`pegasus-fe.exe`) | Pegasus (x11-static) |

Os cores do RetroArch (Snes9x, Gambatte, mGBA, mupen64plus-next, melonDS) são baixados direto do [buildbot.libretro.com](https://buildbot.libretro.com) — open source, sem bins fechados.

---

## macOS (Apple Silicon)

```bash
cd LookaRetro
./install-macos.sh          # emuladores + configs + tema
./install-macos.sh --system # + nunca dormir (tampa fechada) + auto-boot no Pegasus
```

Detalhes completos (clamshell, pmset, controles, tuning): veja a seção macOS no [README antigo desta seção](#) — resumindo, o `--system` aplica:

- **Nunca dormir:** `sudo pmset -a disablesleep 1 sleep 0 disksleep 0 displaysleep 0 standby 0 autopoweroff 0` (a flag `disablesleep` é o que mantém acordado com a tampa fechada) + um LaunchDaemon que reaplica a cada 5 min.
- **Auto-boot:** LaunchAgent `com.lookaretro.pegasus` inicia o Pegasus no login.
- Conecte o Mac a uma TV via **USB-C → HDMI** e mantenha na tomada.

---

## Windows

```powershell
cd LookaRetro
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1          # emuladores + configs + tema + auto-start
powershell -ExecutionPolicy Bypass -File .\install-windows.ps1 -System  # + desativar suspensão (admin)
```

Detalhes em [docs/WINDOWS.md](docs/WINDOWS.md).

---

## Linux

```bash
cd LookaRetro
./install-linux.sh          # Flatpak emuladores + Pegasus + configs + tema + persistência
./install-linux.sh --system # + ignorar fechamento de tampa via logind (sudo)
```

Detalhes em [docs/LINUX.md](docs/LINUX.md).

---

## Adicionando jogos (ROMs)

1. Copie os arquivos para a pasta do sistema:

| Sistema | Pasta | Extensões |
|---|---|---|
| SNES | `roms/snes/` | `.sfc` `.smc` `.fig` `.swc` `.bs` |
| Game Boy Color | `roms/gbc/` | `.gbc` `.gb` |
| Game Boy Advance | `roms/gba/` | `.gba` `.agb` |
| Nintendo 64 | `roms/n64/` | `.z64` `.n64` `.v64` `.ndd` |
| Nintendo DS | `roms/nds/` | `.nds` `.dsi` |
| PlayStation 1 | `roms/psx/` | `.cue` `.chd` `.pbp` `.m3u` `.iso` |
| Wii | `roms/wii/` | `.wbfs` `.rvz` `.iso` `.ciso` |
| Nintendo 3DS | `roms/3ds/` | `.3ds` `.cci` `.cxi` `.app` |
| Nintendo Switch | `roms/switch/` | `.nsp` `.xci` `.nsz` |
| PlayStation Vita | `roms/psvita/` | `.vita` `.vpk` `.zip` |

A pasta raiz é `~/Retro` (macOS/Linux) ou `%USERPROFILE%\Retro` (Windows), configurável via `RETRO_HOME`.

2. Regere a lista de jogos:

```bash
# macOS / Linux
~/Retro/scripts/import-roms.sh
```
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Retro\scripts\import-roms.ps1"
```

3. (Re)inicie o Pegasus ou pressione **F5** no tema.

Para capas, capturas e vídeos (scraping): [docs/ROMS.md](docs/ROMS.md). Formato do `metadata.pegasus.txt`: [docs/METADATA.md](docs/METADATA.md).

---

## Controles

Navegação no tema LookaRetro (padrões do Pegasus, iguais nas 3 plataformas):

| Botão | Ação |
|---|---|
| D-pad / setas | Navegar |
| **A** | Abrir sistema / iniciar jogo |
| **B** | Voltar |
| **L1 / R1** | Sistema anterior / próximo |
| **START** | Menu do Pegasus (configurações / sair) |
| **F1** (teclado) | Menu do Pegasus |
| **F5** (teclado) | Recarregar o tema |

Dentro do RetroArch: **L3 + R3** abre o menu; **Close Content** fecha o jogo e volta ao Pegasus.

**2 jogadores (Xbox Wireless, padrão):** os dois pads são mapeados automaticamente em
todos os emuladores (P1 = primeiro a conectar, P2 = segundo) — RetroArch fixa os slots
de joypad, Dolphin usa o perfil "SDL Gamepad" (GC) + Wii Remote emulado (analógico
direito = cursor, esquerdo = shake) e o DuckStation usa layout DualShock com rumble.
Recorra o setup a qualquer momento com `bash ~/Retro/scripts/setup-controllers.sh` (ou pelo item **Reconfigurar Controles** no painel do Pegasus).

Configuração por emulador: [docs/CONTROLS.md](docs/CONTROLS.md).

## Configurações pelo painel (sem terminal)

O Pegasus ganha uma coleção **"LookaRetro Config"** com ajustes ativados direto do
controle/teclado (cada item roda sua ação e mostra um aviso na tela):

| Item | O que faz |
|---|---|
| **Modo Console — nunca dormir** | Ativa o modo console (sem sleep, tampa fechada OK) — pede a senha |
| **Modo Normal — dormir** | Restaura o sleep padrão do macOS (10 min) — pede a senha |
| **N64 — Turbo (GPU)** | Renderizador ParaLLEl-RDP (Vulkan): N64 rápido |
| **N64 — Compatível** | Renderizador Angrylion (software): se um jogo abrir preto no Turbo |
| **Reconfigurar Controles** | Reaplica o mapeamento dos 2 controles em todos os emuladores |
| **Atualizar Listas de Jogos** | Regenera as listas do Pegasus (depois pressione F5) |

A coleção é gerada por `make-settings-catalog.sh` e as ações ficam em
`pegasus-settings.sh` (ambos em `~/Retro/scripts/`).

---

## Performance / input lag

O que já vem configurado (idêntico nas 3 plataformas):

- **RetroArch:** *Hard GPU Sync* (0 frames), *threaded video* desligado (evita +1 frame), VSync, **run-ahead** (1 frame) nos cores 2D que suportam (Snes9x/Gambatte/mGBA), `quit_on_close_content` para voltar direto ao Pegasus. Driver de vídeo nativo por SO: Metal (macOS), D3D11 (Windows), GL/Vulkan (Linux).
- **DuckStation:** `-fullscreen -fastboot`.
- **Dolphin:** fullscreen via `GFX.ini`.

Dicas: controle **com fio ou 2.4GHz** (Bluetooth ~8–16 ms a mais), **Modo Jogo** (macOS/Windows) e **Modo Jogo na TV**. Detalhes: [docs/TUNING.md](docs/TUNING.md).

---

## Persistência por plataforma

| Plataforma | Mecanismo |
|---|---|
| macOS | `pmset disablesleep 1` + LaunchDaemon (watchdog) + LaunchAgent (auto-boot) |
| Windows | `powercfg` timeouts = nunca + atalho no Startup |
| Linux | `systemd-inhibit` (user service) + XDG autostart + `logind.conf` (tampa fechada) |

Reverter: `uninstall-macos.sh --apply`, `uninstall-linux.sh --apply`, ou `uninstall-windows.ps1 -Apply`.

---

## Estrutura do repositório

```
LookaRetro/
├── install-macos.sh / install-windows.ps1 / install-linux.sh
├── uninstall-macos.sh / uninstall-windows.ps1 / uninstall-linux.sh
├── lib/
│   ├── launch.sh               # lançador (macOS + Linux)
│   ├── import-roms.sh          # importador (macOS + Linux)
│   └── import-roms.ps1         # importador (Windows)
├── config/
│   ├── retroarch.cfg           # config compartilhada (baixo lag)
│   ├── platform/{macos,windows,linux}.cfg   # drivers por SO
│   ├── cores/*.cfg             # overrides por core (run-ahead)
│   └── dolphin/GFX.ini         # fullscreen
├── theme/LookaRetro/           # tema Pegasus (theme.cfg + theme.qml)
├── launchd/                    # persistência macOS
├── systemd/                    # persistência Linux
├── scripts/make-release.sh     # empacota os releases
└── docs/                       # guias
```

---

## FAQ

**Por que o Pegasus no macOS é x86_64?** O build oficial para macOS é x86_64 (roda via Rosetta 2, instalado automaticamente). É só a interface — o `launch.sh` força `arch -arm64` nos emuladores (RetroArch/DuckStation/Dolphin/Azahar/Ryujinx/Vita3K), então eles rodam **nativos em arm64** e carregam os cores arm64 mesmo sendo iniciados pelo Pegasus.
O encerramento do Pegasus conta com modal de saída segura no tema v1.3 (executando `Qt.quit()`) e flags `--disable-menu-shutdown`, `--disable-menu-reboot`, garantindo que o Mac nunca seja desligado por engano.

**Digimon World Next 0rder e Re:Digitize Decode?** Totalmente suportados! O **Digimon World Re:Digitize Decode** roda no emulador nativo **Azahar** (3DS) com resolução 4x (1080p), e o **Digimon World: Next 0rder** roda no **Vita3K** (PS Vita) via Vulkan/MoltenVK nativo no Apple Silicon com renderização em 1080p, DLCs e tradução em inglês integradas.

**O Mac ainda dorme com a tampa fechada?** Confira `pmset -g live | grep SleepDisabled` (deve ser `1`). Conflito com apps como Amphetamine/AlDente é possível.

**Linux: o jogo não abre?** Confira se `flatpak run org.libretro.RetroArch` funciona sozinho e se o core existe em `~/.var/app/org.libretro.RetroArch/config/retroarch/cores/`.

**N64 com áudio mas tela preta no macOS?** O renderizador padrão do core Mupen64Plus-Next (GLideN64) usa recursos de OpenGL legado que não existem no perfil *core* do macOS — o instalador troca automaticamente para **ParaLLEl-RDP** (Vulkan/MoltenVK, com aceleração de GPU). Se um jogo específico abrir preto, troque para o software renderer **Angrylion** — pelo painel do Pegasus (item **N64 — Compatível**) ou `setup-controllers.sh --n64-angrylion`.

**Windows: winget não existe?** Instale o "App Installer" da Microsoft Store ou instale os emuladores manualmente e ajuste `%USERPROFILE%\Retro\scripts\emulators.ps1`.

---

## Licença

Código (scripts, tema, configs): **MIT** — veja [LICENSE](LICENSE). Os emuladores (RetroArch, DuckStation, Dolphin, Pegasus, Azahar, Ryujinx, Vita3K) são projetos independentes com suas próprias licenças (GPL etc.), baixados na instalação — **não** são redistribuídos aqui.
