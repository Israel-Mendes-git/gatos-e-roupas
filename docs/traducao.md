# Tradução (português -> English)

O jogo tem dois idiomas num só executável. **O português é o idioma-fonte e a CHAVE é o próprio texto em português.**
Não existe coluna de português: sem tradução (ou em português), `Idioma.t` devolve a própria chave.

Peças do sistema:

| Arquivo | Para quê |
|---|---|
| `scripts/jogo/idioma.gd` (`Idioma`) | `Idioma.t(pt)`, `definir`, `proximo`, `titulo_jogo`, registro de chaves sem tradução |
| `idiomas/textos.csv` | formato CSV de tradução do Godot: `keys` (pt), `en`, `_onde` (comentário, ignorado pelo importador) |
| `ferramentas/extrai_textos.py` | acrescenta ao CSV as chaves de `Idioma.t("...")`; `--faltando` guia o trabalho |
| `ferramentas/extrai_dados.gd` | acrescenta ao CSV os textos das tabelas de dados |
| `ferramentas/teste_idioma.gd` | testa tradução, fallback, `%`, aspas e integridade do CSV |

O idioma é uma opção (Opções > Idioma), gravada em `interface.cfg` (`[opcoes] idioma`). Na primeira execução é inglês se
`OS.get_locale_language() != "pt"`. Trocar vale na hora: as telas são redesenhadas a cada quadro. Os testes ficam em
português (`Menus.gravar = false` não detecta idioma).

## Regra de ouro: traduza só na EXIBIÇÃO

Tabelas como `Pecas.CONJUNTO_NOME`, `Pecas.NOME`, `Fases.NOME`, `Pecas.PODER_NOME`... são **identidade** (busca com `.find()`,
save, Ateliê que altera `CONJUNTO_NOME`, comparações). **Nunca** traduza o conteúdo da tabela nem o valor guardado/comparado.
Traduza no ponto em que o texto vai para a tela:

```gdscript
# certo
Desenho.texto(self, Idioma.t(Pecas.CONJUNTO_NOME[c]), pos, 22, cor)
# errado: troca a identidade
Pecas.CONJUNTO_NOME[c] = Idioma.t("Cavaleiro")
```

`Idioma.t(variavel)` (sem literal) é permitido para quem desenha tabelas; as chaves dessas tabelas entram no CSV pelo
`extrai_dados.gd`. Nome digitado pelo jogador (nome da fantasia do Ateliê, nome de gato) **não** se traduz.

## Como embrulhar

1. Literal simples: `"Opções"` -> `Idioma.t("Opções")`.
2. Texto com números/nomes: **a chave tem os marcadores**, o formato é aplicado depois:
   `Idioma.t("Onda %d/%d") % [a, b]`. Um `%%` literal na chave fica `%%` (`Idioma.t("Agora: %d%%") % 70`).
   Nunca `Idioma.t("Onda %d/%d" % [a, b])` (a chave mudaria a cada valor).
3. Frases montadas por concatenação viram **um formato inteiro**: o tradutor precisa reordenar palavras.
   `"Sair agora termina" + (", mas..." if x else ".")` vira duas frases completas escolhidas por `if`:
   `Idioma.t("frase A completa") if x else Idioma.t("frase B completa")`.
   `Idioma.t("a" + "b")` é rejeitado pelo extrator (aviso). Partes que são nomes (lugar, fantasia, bicho) entram como `%s` já
   traduzidas: `Idioma.t("%s · Onda %d") % [Idioma.t(Fases.nome_do_lugar(i)), n]`.
4. Plurais simples: duas chaves completas, nunca "s" colado:
   `Idioma.t("%d gato") % n if n == 1 else Idioma.t("%d gatos") % n`. (O inglês também só tem singular/plural.)
5. Texto com quebra de linha: use o `\n` normal no literal. O extrator decodifica o escape e o CSV guarda uma quebra
   real dentro de aspas (testado). Prefira uma chave por parágrafo/linha lógica quando a quebra for só de layout.
6. Tooltips, balões, dicas, mensagens de fila (`fila_dicas`, metas, flutuantes): embrulhe **na hora de montar o texto**
   (ou ao desenhar), nunca guarde o texto já traduzido em estado que sobreviva a uma troca de idioma (save, cache longo).
   Se um texto traduzido fica em cache (ex.: `_larg_c`, `_quebrar_c`), a chave do cache deve incluir o texto já traduzido
   ou o cache deve ser limpo em `Idioma.definir`.
7. **Medir largura antes de desenhar**: `UIComum.largura/caber/quebrar`, `_quebra`, `dono._quebrar`, `get_string_size`
   precisam receber o texto **já traduzido**. Traduza uma vez numa variável e use-a para medir e desenhar:
   ```gdscript
   var txt: String = Idioma.t("Poderes automáticos")
   var larg: float = UIComum.largura(txt, 22)
   ```
   O inglês costuma ser mais curto, mas confira (ex.: "Preparação da onda" -> "Wave preparation").
8. Botões do menu guardam o texto ao montar (`_bt(...)`); como `_montar()` roda de novo ao trocar o idioma, basta embrulhar
   no `_montar`. Qualquer lista montada uma vez e guardada precisa ser remontada quando o idioma muda
   (`Idioma.atual` mudou); na dúvida, traduza no desenho em vez de na montagem.
9. Funções que só devolvem texto de exibição (`Pecas.conjunto_bonus`, `Torre.melhoria_dica`, `Pecas.marca_linha`) são
   embrulhadas **dentro** delas, com o formato fora do `Idioma.t`. Antes, confira com `grep` que ninguém usa o retorno como
   identidade.

## O que NÃO embrulhar

- Conteúdo de tabelas de identidade (veja acima) e ids: `"continuar"`, `"o_tela"`, chaves de dicionário, padrões de `match`.
- Caminhos (`res://`, `user://`), nomes de nós, ações de input, grupos, sinais, nomes de som/música, seções/chaves de `.cfg`.
- Mensagens de depuração (`print`, `push_warning`, `reg(...)`, `assert`), formatos de log.
- Nome de pessoa/marca/arquivo nos créditos (Jersey 10, itch.io...), números sozinhos, `%d`, `x`, símbolos.
- Nome do idioma no botão ("Português", "English"): sempre no próprio idioma.
- Texto já traduzido recebendo `Idioma.t` de novo (duplo embrulho só gera chave inútil).
- Nomes digitados pelo jogador.

Linha que o `--faltando` acusa por engano e que não deve ser traduzida: acrescente `# i18n-ok` no fim da linha.
Declarações `const`/`var` de coluna 0 (tabelas) não são acusadas: elas são cobertas pelo `extrai_dados.gd`.

## Fluxo de trabalho (por arquivo)

```
python -I ferramentas/extrai_textos.py --faltando --resumo          # contagem por arquivo
python -I ferramentas/extrai_textos.py --faltando | grep menus.gd   # linhas do arquivo em que você está
# ... embrulhe com Idioma.t ...
python -I ferramentas/extrai_textos.py                              # acrescenta as chaves novas ao CSV (--seco: só mostra)
Godot --headless --path . --script res://ferramentas/extrai_dados.gd  # tabelas de dados (rode quando mexer em tabelas)
Godot --headless --path . --import                                  # regera idiomas/textos.en.translation
Godot --headless --path . --script res://ferramentas/teste_idioma.gd
```

- O primeiro `--import` depois de clonar/adicionar `Idioma` também atualiza o cache de classes globais: se o Godot reclamar de
  `Identifier "Idioma" not declared`, rode `--import` uma vez.
- `extrai_textos.py` nunca apaga: chaves que sumiram do código aparecem como "órfãs" (limpe à mão se fizer sentido).
  Ele preserva as traduções e a ordem; as chaves novas vão para o fim.
- Se criar uma **tabela nova de textos**, acrescente-a em `TABELAS` no `extrai_dados.gd` (ele também lista "CANDIDATA fora de
  TABELAS" para ajudar a achar esquecidas).
- Capturas para conferir layout em inglês: `CAPTURA_USERDIR=gr_idioma python -I notas/captura.py --script res://ferramentas/captura_idioma.gd -- <pasta>`
  (adapte o script para a tela que você embrulhou).
- Em depuração, com o jogo em inglês, `Idioma.faltas` e `user://textos_sem_traducao.log` anotam as chaves pedidas sem
  tradução: jogue/abra a tela e confira o log.
- Commits: um arquivo (ou assunto) por commit, ex.: `feat(idioma): menu de pausa e confirmações com Idioma.t`.

## Para o redator/tradutor (preencher o CSV)

Abra `idiomas/textos.csv` (UTF-8, vírgula; use um editor que respeite aspas, ex. LibreOffice com "texto entre aspas" ou
um editor de texto). Preencha **só a coluna `en`**. Não mexa em `keys` (é o texto do jogo; mudar um caractere quebra a
tradução) nem em `_onde` (diz de que arquivo ou tabela a chave vem, para dar contexto).

- Mantenha **todos os marcadores** exatamente: `%d`, `%s`, `%%`, `%.1f`. Podem mudar de ordem só se o tipo continuar na
  mesma posição (se precisar inverter, avise o dev: o formato do GDScript é posicional).
- Preserve aspas `"` (o CSV escapa como `""`), quebras de linha e símbolos (`·`, `×`, `+`).
- Respeite o tamanho: os textos aparecem em botões e balões fixos; prefira a versão curta quando a original é curta.
- Chaves de uma ou duas palavras podem ser ambíguas ("Tela", "Ligado/Ligada"): veja `_onde` e, na dúvida, pergunte.
- Célula vazia = sem tradução: o jogo mostra o português (nunca a chave "crua" sem sentido).
- **Glossário** (sempre igual no jogo todo):
  - `miau` -> `meow` nos trocadilhos: Super Miau -> Super Meow, Miaujestosa -> Meowjestic, Guardamiau -> Guardmeow, Sua Miauestade -> Your Meowjesty. **Glossário completo e decisões do dono: `notas/idioma/glossario.md` (tem prioridade sobre esta lista).**
  - gato -> cat; bicho -> critter; fantasia -> costume; peça -> piece; guarda-roupa -> wardrobe; cômodo -> room;
    onda -> wave; troféu -> trophy; torre -> tower; ato -> act; invasão -> invasion; fichário -> binder.
  - Nome do jogo: *Gatos e Roupas* -> *Cats & Costumes* (já está em `Idioma.TITULOS`).
  - Dê o mesmo nome em inglês em toda ocorrência: a coluna `en` é a única fonte da verdade; novos termos entram aqui.
