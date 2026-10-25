# Créditos e licenças dos pacotes de terceiros

Termos lidos nas páginas do itch.io em 12/10/2026. Conferir de novo antes de publicar.

## Em uso no jogo

**32x32 Pixel kittens Cats - Animated NPC**, de Last tick
https://last-tick.itch.io/animated-pixel-kittens-cats-32x32
- Usado em: `assets/terceiros/gatos/gato_0.png`, `gato_1.png`, `gato_2.png` (recortes ampliados do "Free pack") e nas âncoras de `scripts/jogo/gato_dados.gd`.
- Permite: uso comercial e pessoal, editar, recolorir e remixar.
- Proíbe: dizer que é de autoria própria, montar pacotes de assets com ele, revender ou redistribuir os arquivos (mesmo editados), usar para treino de IA.
- Crédito: opcional, mas o autor agradece. Creditar "Last tick" na tela de créditos.

**Cryo's Mini GUI**, de PaperHatLizard
https://paperhatlizard.itch.io/cryos-mini-gui
- Usado em: `assets/terceiros/gui/gui_4x.png` e `botoes_4x.png` (molduras, barras e ícones).
- Licença: Creative Commons Attribution 4.0 (CC BY 4.0). Uso comercial permitido.
- A CC BY pede atribuição; o autor diz nos comentários que não exige crédito, só que ninguém diga que fez a arte. Na dúvida, creditar.

**Cat User Interface**, de ToffeeCraft
https://toffeecraft.itch.io/cat-user-interface
- Usado em: `assets/terceiros/gui/gato_ui.png` (gatinho dos balões e ícones dos menus).
- Permite: uso pessoal e comercial, editar. Só pode ser distribuído como parte de um jogo ou produto, nunca avulso.

**Jersey 10**, de Sarah Cadigan-Fried (The Soft Type Project)
https://github.com/scfried/soft-type-jersey
- Usado em: `assets/fontes/Jersey10-Regular.ttf`, a fonte de todo o jogo (texto da interface e logotipo). A licença está em `assets/fontes/OFL.txt`.
- Licença: SIL Open Font License 1.1. Uso comercial permitido; pode ir no repositório e no jogo, desde que a licença acompanhe a fonte e o nome não seja vendido sozinho.

## Feito para o jogo

**Música**: trilha chiptune original, composta e sintetizada para o jogo.
- Arquivos: `assets/musica/*.wav` (título, mapa e guarda-roupa, luta dos três atos, chefe, chefe secreto, tela de final e os jingles de vitória e derrota).
- Gerada por código em `ferramentas/gera_musica.py` (ondas quadrada, triângulo e ruído; nenhuma amostra, melodia ou pacote de terceiros). Para refazer: `python ferramentas/gera_musica.py` e reimportar no Godot.

**Efeitos sonoros**: `assets/som/*.wav`, sintetizados para o jogo.

## Baixado, sem uso

**Cat Pack - Mochi** (pacote gratuito `CatPackFree.zip`), de ToffeeCraft
https://toffeecraft.itch.io/cat-pack
- ATENÇÃO: o pacote gratuito é **só para uso pessoal**. Para jogo comercial é preciso comprar o pacote pago.
- Não redistribuir nem revender.

## Atenção para o repositório

Os autores proíbem redistribuir os arquivos, e um repositório público com os PNG dentro conta como redistribuição. Por isso `assets/terceiros/` fica fora do git: cada cópia do projeto precisa dos pacotes baixados à parte. Os sons em `assets/som/` foram sintetizados para o jogo e não vêm de pacote nenhum.
