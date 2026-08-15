# LookaRetro no Linux

Guia específico para distribuições Linux (qualquer uma com Flatpak).

## Requisitos

- **Flatpak** com o remoto **Flathub** (o instalador adiciona se faltar).
- `systemd` (para a persistência de "nunca dormir").

## Instalação

```bash
cd LookaRetro
./install-linux.sh
```

Para também **ignorar o fechamento da tampa** (notebooks), rode com sudo:

```bash
./install-linux.sh --system
```

### O que o script faz

1. Instala **RetroArch**, **DuckStation** e **Dolphin** como Flatpaks (Flathub).
2. Dá acesso `--filesystem=home` a eles (para lerem `~/Retro/roms`).
3. Baixa o **Pegasus Frontend** (binário `x11-static`) para `~/Retro/emulators/Pegasus/`.
4. Baixa os cores do RetroArch para `~/.var/app/org.libretro.RetroArch/config/retroarch/cores/`.
5. Aplica config de baixo lag (driver GL/ALSA) + fullscreen no Dolphin.
6. Instala o tema **LookaRetro** em `~/.config/pegasus-frontend/themes/`.
7. Configura o Pegasus e gera a lista de jogos.
8. Persistência:
   - **nunca dormir:** serviço systemd de usuário `lookaretro-inhibit` (segura um lock `systemd-inhibit --what=sleep:idle`).
   - **auto-boot:** entrada XDG autostart `~/.config/autostart/lookaretro-pegasus.desktop`.
   - com `--system`: `/etc/systemd/logind.conf.d/lookaretro.conf` (`HandleLidSwitch=ignore` etc.).

## Por que Pegasus fora do Flatpak?

O Pegasus é instalado como **binário standalone** (não Flatpak) de propósito: ele precisa disparar `flatpak run ...` para lançar os emuladores Flatpak. Um Pegasus "dentro" do Flatpak não consegue chamar o `flatpak` do host diretamente (o Pegasus até tem `flatpak-spawn --host`, mas o binário standalone é mais simples e previsível).

## Adicionando jogos

```bash
~/Retro/scripts/import-roms.sh
```

A pasta raiz é `~/Retro/roms/<sistema>/`.

## Caminhos importantes

| O quê | Onde |
|---|---|
| ROMs | `~/Retro/roms/` |
| Pegasus | `~/Retro/emulators/Pegasus/pegasus-fe` |
| Config do RetroArch (Flatpak) | `~/.var/app/org.libretro.RetroArch/config/retroarch/` |
| Cores | `~/.var/app/org.libretro.RetroArch/config/retroarch/cores/` |
| Config do Pegasus | `~/.config/pegasus-frontend/` |

## Se algo não abrir

1. Teste o emulador sozinho: `flatpak run org.libretro.RetroArch`.
2. Confira se o core existe: `ls ~/.var/app/org.libretro.RetroArch/config/retroarch/cores/`.
3. Se preferir `vulkan` em vez de `gl` (melhor latência em GPU moderna), edite `config/platform/linux.cfg` e reaplique, ou mude em *Settings → Driver → Video*.

## Reverter

```bash
./uninstall-linux.sh --apply
```

Desativa/remove o serviço `lookaretro-inhibit`, a entrada autostart e o override do logind. Emuladores e ROMs ficam intactos.
