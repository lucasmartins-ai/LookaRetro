# Tuning — performance e baixo input lag

O que já vem pronto pelo `install.sh` e como ajustar manualmente.

## RetroArch

Config global (`~/Library/Application Support/RetroArch/retroarch.cfg`) e overrides por core (`.../config/<Core>/<Core>.cfg`).

| Setting | Valor | Por quê |
|---|---|---|
| `video_driver` | por SO* | driver nativo, menor overhead |
| `video_hard_sync` | `true` | sincroniza a fila da GPU (menos lag) |
| `video_hard_sync_frames` | `0` | 0 frames extras de fila |
| `video_threaded` | `false` | threaded video adiciona ~1 frame de lag |
| `video_vsync` | `true` | evita tearing (com hard sync, o custo é mínimo) |
| `video_scale_integer` | `true` | pixels nítidos nos 2D |
| `audio_latency` | `64` | buffer de áudio baixo (reduza p/ 32 se aguentar sem estalos) |
| `run_ahead_enabled` | `true`* | remove 1 frame de lag **nos cores que suportam** |
| `quit_on_close_content` | `true` | fecha o RetroArch e volta ao Pegasus |

\* `run-ahead` só está ligado nos cores Snes9x, Gambatte e mGBA (via override). Não funciona de forma confiável em melonDS e Mupen64Plus-Next.

\* Drivers por SO (definidos em `config/platform/<os>.cfg`): **macOS** = `metal`/`coreaudio` · **Windows** = `d3d11`/`wasapi` · **Linux** = `gl`/`alsa` (troque por `vulkan` em GPU moderna).

### Ajuste fino de run-ahead
Se um jogo 2D "pular" frames ou ficar instável, desligue para aquele jogo:
1. Menu (L3+R3) → **Quick Menu → Latency → Run-Ahead**.
2. Aumente para 2 frames só se o jogo suportar e continuar estável.
3. **Save Game Overrides** para gravar por jogo.

### Se houver estalos de áudio
Aumente `audio_latency` (96 ou 128) em *Settings → Audio → Audio Latency*.

---

## DuckStation (PS1)

O launcher inicia com `-fullscreen -fastboot`. Para o resto, abra o DuckStation e vá em **Settings**:

| Setting | Sugestão |
|---|---|
| **Console → Emulation Speed** | 100% (normal) |
| **GPU → Renderer** | Metal (automático) |
| **GPU → Internal Resolution** | 1x p/ menor lag; 2x–4x p/ visual (M1 aguenta 4x+ fácil) |
| **Display → VSync** | Ligado (evita tearing) |
| **Display → Aspect Ratio** | 4:3 (ou 16:9 com stretch p/ TV) |
| **Audio → Sync** | Ligado |

> Para jogos competitivos (Tekken, Street Fighter), mantenha **1x** de resolução interna e VSync ligado.

---

## Dolphin (Wii)

O Dolphin roda **nativo em arm64** no M1 — performance excelente.

| Setting | Sugestão |
|---|---|
| **Graphics → General → Video Backend** | Metal (ou Vulkan se preferir) |
| **Graphics → General → Use Fullscreen** | Ligado |
| **Graphics → Enhancements → Internal Resolution** | 1x–3x (Wii roda bem em 2x+) |
| **Graphics → Enhancements → Anti-Aliasing** | None p/ menor lag |
| **Config → General → Enable Dual Core** | Ligado (padrão, maior performance) |
| **Config → Advanced → CPU Emulation Engine** | JIT Recompiler (padrão) |

### Wii com baixo lag
- Use **Real Wiimote** (Bluetooth) — o próprio Wiimote tem latência mínima.
- Para *side-scrollers* 2D, aumente a resolução interna que ainda sobra folga.

---

## Sistema (macOS)

1. **Modo Jogo:** enquanto um jogo roda em tela cheia, ative o **Modo Jogo** (ícone de joystick na barra de menus). Ele prioriza CPU/GPU para o jogo e reduz latência.
2. **TV em Modo Jogo:** desative pós-processamento de imagem na TV (motion smoothing, etc.) — é a maior fonte de lag percebido.
3. **Sem Wi-Fi/notificações:** desative notificações e o Wi-Fi se quiser o mínimo de interferência (opcional).

## Referência: onde ficam as configs

| Arquivo | macOS | Windows | Linux |
|---|---|---|---|
| `retroarch.cfg` | `~/Library/Application Support/RetroArch/` | `%APPDATA%\RetroArch\` | `~/.var/app/org.libretro.RetroArch/config/retroarch/` |
| overrides por core | `.../RetroArch/config/<Core>/` | `%APPDATA%\RetroArch\config\<Core>\` | `.../retroarch/config/<Core>/` |
| cores | `.../RetroArch/cores/` | `%APPDATA%\RetroArch\cores\` | `.../retroarch/cores/` |
| Dolphin `GFX.ini` | `~/Library/Application Support/Dolphin/Config/` | `Documentos\Dolphin Emulator\Config\` | `~/.var/app/org.DolphinEmu.dolphin-emu/config/dolphin-emu/Config/` |
| Pegasus config | `~/Library/Preferences/pegasus-frontend/` | `%LOCALAPPDATA%\pegasus-frontend\` | `~/.config/pegasus-frontend/` |
