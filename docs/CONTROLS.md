# Controles — configuração por emulador

Recomendação geral: use **controle com fio ou 2.4 GHz** (ex.: 8BitDo com dongle, DualShock 4 com fio, Xbox Series com fio) para o menor input lag. Bluetooth funciona, mas adiciona ~8–16 ms.

## Ordem sugerida

1. Conecte o controle **antes** de abrir o emulador.
2. Configure primeiro no **RetroArch** (cobre SNES/GBC/GBA/N64/DS), depois **DuckStation** (PS1) e **Dolphin** (Wii).
3. Um mesmo controle físico pode ser mapeado em cada emulador de forma independente — é normal configurar três vezes.

---

## RetroArch (SNES / GBC / GBA / N64 / DS)

O RetroArch usa um **autoconfig** por tipo de controle; na maioria dos casos o mapeamento já vem pronto.

### Mapear botões
1. Abra o RetroArch (só o app, sem jogo).
2. **Settings → Input → Port 1 Controls**.
3. Ajuste os botões (B/A, D-pad, L/R, Start/Select).
4. **Settings → Input → Save Autoconfig Profile** (salva o perfil).

### Hotkeys importantes (Settings → Input → Hotkeys)
| Ação | Sugestão | Campo |
|---|---|---|
| Abrir menu | **L3 + R3** | *Menu Toggle (Gamepad Combo)* |
| Close Content | (menu) | já configurado p/ voltar ao Pegasus |

- Por padrão o tema já usa `quit_on_close_content`, então **Close Content** fecha o RetroArch e volta ao Pegasus.
- Para dois jogadores: habilite **Port 2** e mapeie o segundo controle.

### Cores por sistema (atalhos)
- **N64:** no jogo, abra o menu → **Quick Menu → Controls** para mapear C-buttons/Z no seu controle.
- **DS:** o layout de duas telas pode ser ajustado em **Quick Menu → Options → Screen layout**.

---

## DuckStation (PlayStation 1)

1. Abra o DuckStation.
2. **Settings → Controllers**:
   - Selecione **Controller 1** como o seu controle.
   - **Digital Controller** (sem analógico) ou **Analog Controller** (com DualShock) — escolha conforme o jogo (Gran Turismo e Tekken gostam de analógico).
   - Clique em cada botão e pressione o correspondente no controle (mapeamento guiado).
3. **Save** no canto.

Dica: ative **Settings → Hotkeys** e defina um botão para abrir o menu (ex.: Start+Select) e outro para fechar o jogo.

---

## Dolphin (Wii)

1. Abra o Dolphin.
2. **Controllers** (ícone de controle na barra):
   - **GameCube:** configure um **Standard Controller** se quiser jogar com controle tradicional.
   - **Wii:** habilite **Emulated Wii Remote** (usa o seu controle como Wiimote) **ou** **Real Wii Remote** (conecta um Wiimote real via Bluetooth).
3. **Emulated Wii Remote**:
   - Configure: D-pad, A/B, 1/2, ± (Start/Select), e o **Pointing** (aponte com o analógico ou deixe no giroscópio se o controle tiver).
4. Feche e jogue.

### Jogos de Wii com Wiimote real
- Pareie o Wiimote em *Ajustes do Sistema → Bluetooth* (pressione o botão vermelho atrás do controle).
- No Dolphin: **Controllers → Wii → Real Wii Remote → Refresh** e selecione o Wiimote.

---

## Pegasus (navegação)

O Pegasus detecta o controle automaticamente. Se quiser mudar os botões de navegação:

1. **START** (no tema) → **Settings**.
2. Role até **Keys** e reconfigure **Accept / Cancel / Menu** etc.

Padrões do Pegasus:

| Função | Teclado | Gamepad |
|---|---|---|
| Accept | Enter | A |
| Cancel | Esc | B |
| Details | I | X |
| Filters | F | Y |
| Next page | E / D | R1 |
| Prev page | Q / A | L1 |
| Menu | F1 | **START** |

> No tema LookaRetro, **B** foi reaproveitado como "voltar" (em vez de abrir o menu). O menu continua no **START**.
