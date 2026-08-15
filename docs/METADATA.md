# Metadata — formato `metadata.pegasus.txt`

O Pegasus lê um arquivo `metadata.pegasus.txt` em cada pasta de jogo. O `import-roms.sh` gera um básico; você pode enriquecê-lo (ou deixar o Skraper fazer isso).

## Exemplo

```
collection: Super Nintendo (SNES)
shortname: snes
launch: "/Users/voce/Retro/scripts/launch.sh" snes "{file.path}"

game: The Legend of Zelda: A Link to the Past
file: Zelda - A Link to the Past.sfc
developer: Nintendo
publisher: Nintendo
genre: Action RPG
players: 1
release: 1991-11-21
rating: 95%

The hero of Hyrule... (sinopse, linha(s) soltas após os campos)
```

## Campos principais

| Campo | Significado |
|---|---|
| `collection:` | Nome do "sistema" exibido no tema |
| `shortname:` | Abreviação (ex.: `snes`) |
| `launch:` | Comando de inicialização; `{file.path}` vira o caminho do arquivo selecionado |
| `game:` | Título do jogo |
| `file:` | Arquivo de ROM (relativo à pasta) |
| `developer:` / `publisher:` | desenvolvedor / publicador |
| `genre:` | gênero (separados por vírgula) |
| `players:` | nº máximo de jogadores |
| `rating:` | nota (ex.: `95%`) |
| `release:` | data (`AAAA-MM-DD`) |

### Assets (referências de mídia)
```
assets.boxFront: capa.png
assets.screenshot: tela.png
assets.background: fundo.png
assets.logo: logo.png
assets.video: video.mp4
```

Qualquer campo extra com prefixo `x-` fica acessível no tema via `game.extra` (ex.: `x-difficulty: Hard` → `game.extra.difficulty`).

## Multi-disco (PS1)

Use `file:` repetido para cada disco; o Pegasus pergunta qual usar:

```
game: Final Fantasy VII
file: FF7 - Disc 1.cue
file: FF7 - Disc 2.cue
file: FF7 - Disc 3.cue
```

(Alternativa: um único `.m3u` listando os discos, e `file: FF7.m3u`.)

## Preservando edições manuais

O `import-roms.sh` **regenera** o arquivo a cada execução. Se você editar algo à mão e quiser preservar, coloque seus acréscimos **fora da lista gerada** — ou deixe o Skraper gerenciar o arquivo inteiro (e não rode mais o import para aquela pasta).

## Tema

O tema **LookaRetro** usa, de cada jogo:
- `title`, `summary`, `developer`, `releaseYear`, `players`, `rating`, `genre`
- `assets.boxFront` (capa na grade), `assets.screenshot`/`assets.background` (fundo desfocado)

Se faltar boxart, o tema desenha um cartão com o título — a biblioteca nunca fica "vazia" visualmente.

Referência completa: <https://pegasus-frontend.org/docs/user-guide/meta-files/>
