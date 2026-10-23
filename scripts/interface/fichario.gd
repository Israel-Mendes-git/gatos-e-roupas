class_name Fichario
extends Control
## Fichário de fantasias: um álbum aberto por cima da tela, no molde da oficina da torre.
## Página 0 é o índice (as 25 fantasias, por cômodo e por lugar de fora); depois vêm as fantasias, uma por página dupla:
## à esquerda o gato vestido, o poder e onde achar; à direita as 4 peças e os bônus.
## A tela só mostra: quem guarda o que o jogador teve e tem é o `Estado` (atribua `estado` antes de `abrir`).
##
## Interface pública:
##   estado: Estado               (atribuído pelo dono)
##   abrir(fantasia := -1)        (abre no índice, ou direto na página da fantasia dada)
##   fechar() / aberto() -> bool
##   tecla(keycode) -> bool       (o dono pode repassar teclas; já tem _input próprio, como a oficina)
##   ir_para_fantasia(c), ir_para_comodo(i), ir_para_pagina(p)
##   signal fechado

signal fechado
## O jogador abriu a aba "Metas" (o selo de metas novas no botão do mapa pode sumir).
signal metas_vistas
signal ajuda_pedida   # o "?" foi apertado: o dono repete a aula do Fichário

## Valor de `abrir()` que abre direto na aba "Metas".
const PAGINA_METAS := -2
## Valor de `abrir()` que abre direto na aba "Bichos" (o bestiário).
const PAGINA_BICHOS := -3
const N_ABAS := 9
const ABA_BICHOS := 8  # "Bichos": o bestiário (famílias, tipos e chefes)
const ABA_FORA := 6    # "De fora": as fantasias que só caem fora da casa
const ABA_METAS := 7
## Bestiário: página 0 = índice da casa e de fora, 1 = índice das gangues do 3º ato, 2.. = uma ficha por entrada.
const BICHOS_PAG_INDICE := 2
const BICHOS_CASA := 30   # entradas 0..29 são dos dois primeiros atos; 30..34 são as gangues

const GUI_TEX: Texture2D = preload("res://assets/terceiros/gui/gui_4x.png")
const BOT_TEX: Texture2D = preload("res://assets/terceiros/gui/botoes_4x.png")
const R_MADEIRA := Rect2(8, 136, 80, 80)
const M_MADEIRA := Vector4(28, 28, 28, 28)
const R_BT_N := Rect2(132, 4, 88, 56)
const R_BT_P := Rect2(228, 8, 88, 52)
const M_BT := Vector4(16, 16, 16, 16)

const COR_CAPA := Color(0.33, 0.12, 0.16)
const COR_COSTURA := Color(0.9, 0.72, 0.45, 0.55)
const COR_OURO := Color(1.0, 0.82, 0.2)
const PAPEL := Color(0.96, 0.92, 0.80)
const PAPEL_ESC := Color(0.89, 0.83, 0.68)
const PAPEL_BORDA := Color(0.55, 0.42, 0.3)
const TINTA := Color(0.2, 0.12, 0.12)
const TINTA2 := Color(0.43, 0.33, 0.28)
const COR_FAIXA := Color(0.2, 0.12, 0.16)
const COR_TEM := Color(0.1, 0.45, 0.2)
const COR_TEVE := Color(0.55, 0.36, 0.08)
const COR_FALTA := Color(0.62, 0.2, 0.2)
const COR_SIL := Color(0.1, 0.08, 0.14, 0.93)
## Cor de cada aba de cômodo (Índice primeiro): papel colorido.
const COR_ABA: Array[Color] = [
	Color(0.88, 0.84, 0.74), Color(0.96, 0.62, 0.66), Color(0.55, 0.74, 0.96),
	Color(0.98, 0.84, 0.4), Color(0.75, 0.6, 0.92), Color(0.55, 0.82, 0.55), Color(0.5, 0.8, 0.82), Color(0.96, 0.78, 0.5), Color(0.9, 0.62, 0.45),
]

# ---- geometria (tudo a partir destas constantes) ----
const CAPA := Rect2(44, 14, 1092, 692)
const PG_E := Rect2(96, 66, 490, 574)
const PG_D := Rect2(598, 66, 490, 574)
const ESPINHA_X := 592.0
const BTN_ANT := Rect2(96, 649, 150, 34)
const BTN_PROX := Rect2(938, 649, 150, 34)
const BTN_FECHAR := Rect2(492, 649, 200, 34)
const ABA_X := 1112.0
const ABA_W := 124.0
const ABA_H := 56.0
const ABA_Y0 := 96.0
const ABA_GAP := 8.0
const COL_E_X := 120.0     # texto da página esquerda
const COL_D_X := 620.0     # texto da página direita
const COL_W := 446.0
const LIN_Y0 := 78.0       # primeira linha de peça (página direita)
const LIN_H := 94.0
const LIN_GAP := 4.0
const TILE_W := 84.0
const TILE_H := 104.0
const IDX_Y0 := 120.0      # topo da primeira fileira do índice (o rótulo do cômodo fica nos 24 px de cima)
const IDX_PASSO := 138.0   # de uma fileira à outra
const TILE_ICO_Y := 34.0   # altura do centro do ícone dentro da miniatura
const TILE_GAP := 6.5
const GATO_ESC := 3.1
const PATADA_CADA := 3.4
const PATADA_DUR := 0.22

# ---- pixel art: tudo o que é desenho (e não texto) cai na grade de Q px, a mesma das molduras da UIComum ----
const V := preload("res://scripts/interface/vfx_px.gd")
const Q := 3.0
const PX_ESC := Color(0.3, 0.18, 0.05)          # contorno de estrela e troféu
const ARGOLA_CONT := Color(0.3, 0.3, 0.36)
const ARGOLA := Color(0.62, 0.64, 0.72)
const ARGOLA_CL := Color(0.95, 0.96, 1.0)
const ARGOLA_ESC := Color(0.45, 0.47, 0.56)
const FURO := Color(0.25, 0.15, 0.15)
const SELO_NOVO := Color(0.9, 0.2, 0.2)
## Estrela de 7 x 7 células: a = ouro, c = brilho, o = contorno.
const PX_ESTRELA: Array = ["...o...", "..oco..", "oooaooo", "oaaaaao", ".oaaao.", ".oaoao.", ".oo.oo."]
## Bolinha de situação (5 x 5): com visto branco (tem/teve) ou lisa (falta).
const PX_VISTO: Array = [".aaa.", "aaawa", "wawaa", "awaaa", ".aaa."]
const PX_BOLINHA: Array = [".aaa.", "aaaaa", "aaaaa", "aaaaa", ".aaa."]
## Seta de navegação "<" (8 x 7): a = miolo, o = contorno. Espelhada vira ">".
const PX_SETA_NAV: Array = ["...oo...", "..oao...", ".oaaoooo", "oaaaaaao", ".oaaoooo", "..oao...", "...oo..."]
## Emblema de cada grupo de metas (7 x 7): casa (Campanha), cabide (Guarda-roupa), escudo (Invasão), árvore (Lado de fora).
const PX_GRUPO: Dictionary = {
	"Campanha": ["...o...", "..oao..", ".oaaao.", "oaaaaao", ".obcbo.", ".obcbo.", ".ooooo."],
	"Guarda-roupa": ["...oo..", "....o..", "...o...", "..oao..", ".oa.ao.", "oa...ao", "ooooooo"],
	"Invasão": ["ooooooo", "oacabao", "oacabao", "oaaabao", ".oaabo.", "..obo..", "...o..."],
	"Lado de fora": ["..ooo..", ".oacao.", "oaccaao", "oaaaaao", ".oobooo", "...b...", "..obo.."],
}

# ---- estado da tela ----
var estado: Estado = null
var fora_pag: int = 0              # índice, seção "Lado de fora": página de 5 miniaturas (são mais de 5 desde a expansão)
var metas_pag: int = 0             # aba Metas: 0 = Campanha, Guarda-roupa, Invasão e Fantasias; 1 = Lado de fora
var em_metas: bool = false          # a aba "Metas" está aberta (ocupa as duas páginas)
var metas_novas: Array[String] = [] # metas cumpridas e ainda não vistas (o dono preenche antes de abrir)
var em_bichos: bool = false         # a aba "Bichos" está aberta (`pagina` 0 = índice; 1.. = um bicho por página dupla)
var aberta: bool = false
var pagina: int = 0          # 0 = índice; 1..21 = fantasias na ordem dos cômodos
var itens: Array[Dictionary] = []   # {id, r, on}
var foco: int = -1
var apertado_id: String = ""
var apertado_fora: bool = false
var t: float = 0.0
var virar_t: float = 0.0
var virar_dir: int = 1
var _ordem: Array[int] = []
var _sil: Control = null      # camada filha: tudo o que ela desenha sai em silhueta escura (modulate)
var _jobs: Array = []
# ---- juice
var anim: Dictionary = {}
var abrir_t: float = 0.0
var faiscas := UIComum.Faiscas.new()
var _foco_som: int = -1
var _mouse: Vector2 = Vector2(-500, -500)
var x_sobre: bool = false
var x_press: bool = false
var carimbo_t: float = 9.0          # < 0.25: o carimbo está batendo na página
var ganhos_exib: float = 0.0        # prêmio total das metas, contando
const BTN_AJUDA := Rect2(1022.0, 24.0, 38.0, 38.0)   # "?": repete a aula do Fichário
const BTN_X := Rect2(1070.0, 22.0, 42.0, 42.0)         # o que a silhueta desenha nesta página

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = false
	_ordem = ordem_das_fantasias()
	_sil = Control.new()
	_sil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sil.modulate = COR_SIL
	_sil.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sil.draw.connect(_desenhar_silhuetas)
	add_child(_sil)

# ------------------------------------------------------------------ interface pública
func aberto() -> bool:
	return aberta

func abrir(fantasia: int = -1) -> void:
	if aberta or estado == null:
		return
	aberta = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	apertado_id = ""
	abrir_t = 0.0
	anim.clear()
	faiscas.limpar()
	ganhos_exib = 0.0
	carimbo_t = 9.0
	Som.tocar("abrir")
	foco = -1
	virar_t = 0.0
	pagina = 0
	em_metas = fantasia == PAGINA_METAS
	em_bichos = fantasia == PAGINA_BICHOS
	metas_pag = 0
	if fantasia >= 0 and _ordem.has(fantasia):
		pagina = _ordem.find(fantasia) + 1
	_montar()
	_checa_carimbo()
	if em_metas:
		metas_vistas.emit()
	queue_redraw()

## Página de fantasia completa: o carimbo "COMPLETA" bate com som.
func _checa_carimbo() -> void:
	carimbo_t = 9.0
	if aberta and not em_metas and not em_bichos and pagina > 0 and not pagina_do_atelie() and estado != null and estado.pecas_da_fantasia(fantasia_da_pagina(pagina)) >= Pecas.SLOTS:
		carimbo_t = -0.25   # um instante de espera antes da batida

func fechar() -> void:
	if not aberta:
		return
	aberta = false
	visible = false
	Som.tocar("fechar")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	apertado_id = ""
	itens.clear()
	_jobs.clear()
	fechado.emit()

func total_paginas() -> int:
	if em_bichos:
		return entradas().size() + BICHOS_PAG_INDICE
	return _ordem.size() + 2   # índice, uma página por fantasia e a última, a da fantasia do Ateliê

## A última página das fantasias é a da fantasia criada no Ateliê (não conta como fantasia do fichário).
func pagina_do_atelie() -> bool:
	return not em_metas and not em_bichos and pagina == _ordem.size() + 1

func fantasia_da_pagina(p: int) -> int:
	return _ordem[p - 1] if p >= 1 and p <= _ordem.size() else -1

func ir_para_pagina(p: int) -> void:
	if em_metas:
		# nas Metas "página" é a dupla de folhas: 0 e 1 (o sentido vem da comparação com a página guardada)
		var alvo: int = clampi(metas_pag + signi(p - pagina), 0, 1)
		if p == pagina and p <= 0:
			alvo = 0
		if alvo != metas_pag:
			metas_pag = alvo
			Som.tocar("pagina")
			_montar()
		return
	var np: int = clampi(p, 0, total_paginas() - 1)
	if np == pagina:
		return
	virar_dir = 1 if np > pagina else -1
	virar_t = 0.26
	pagina = np
	Som.tocar("pagina")
	_montar()
	_checa_carimbo()

func ir_para_fantasia(c: int) -> void:
	if _ordem.has(c):
		ir_para_pagina(_ordem.find(c) + 1)

## Pula para a primeira fantasia do cômodo `i` (0 = Quarto ... 4 = Porão).
func ir_para_comodo(i: int) -> void:
	if i < 0 or i >= Fases.TOTAL:
		return
	ir_para_fantasia(Fases.CONJUNTOS[i][0])

## Pula para a primeira fantasia que só cai fora da casa (aba "De fora").
func ir_para_fora() -> void:
	var fo: Array[int] = fantasias_so_de_fora()
	if not fo.is_empty():
		ir_para_fantasia(fo[0])

## Aba que corresponde à página atual (0 = Índice, 1..5 = cômodos, ABA_FORA, ABA_METAS).
func aba_atual() -> int:
	if em_metas:
		return ABA_METAS
	if em_bichos:
		return ABA_BICHOS
	if pagina == 0:
		return 0
	var sala: int = comodo_da_fantasia(fantasia_da_pagina(pagina))
	return sala + 1 if sala >= 0 else ABA_FORA   # só cai fora da casa: aba "De fora"

# ------------------------------------------------------------------ dados (estáticos, testáveis)
static func comodo_da_fantasia(c: int) -> int:
	for i in Fases.TOTAL:
		if (Fases.CONJUNTOS[i] as Array).has(c):
			return i
	return -1   # só cai fora da casa (ver lugar_de_fora)

## Fantasias que só caem nos lugares de fora da casa (as da casa também caem lá, redistribuídas, mas não contam aqui).
static func fantasias_so_de_fora() -> Array[int]:
	var l: Array[int] = []
	for i in range(Fases.TOTAL, Fases.CONJUNTOS.size()):
		for c in Fases.CONJUNTOS[i]:
			if comodo_da_fantasia(int(c)) < 0 and not l.has(int(c)):
				l.append(int(c))
	return l

## Primeiro lugar de fora (índice de Fases.NOME, 5 a 9) onde a fantasia cai; -1 se não cai fora.
static func lugar_de_fora(c: int) -> int:
	for i in range(Fases.TOTAL, Fases.CONJUNTOS.size()):
		if (Fases.CONJUNTOS[i] as Array).has(c):
			return i
	return -1

## Ordem das páginas: as fantasias de cada cômodo, depois as que só caem fora da casa.
static func ordem_das_fantasias() -> Array[int]:
	var o: Array[int] = []
	for i in Fases.TOTAL:
		for c in Fases.CONJUNTOS[i]:
			if not o.has(int(c)):
				o.append(int(c))
	o.append_array(fantasias_so_de_fora())
	return o

const FORA_POR_PAG := 5

static func fora_paginas(n: int) -> int:
	return maxi(1, ceili(float(n) / FORA_POR_PAG))

## Setas da seção "Lado de fora" do índice (dir -1 = página anterior, 1 = próxima).
static func rect_seta_fora(dir: int) -> Rect2:
	return Rect2(COL_D_X + COL_W - 62.0 + (30.0 if dir > 0 else 0.0), rect_tile_fora(0).position.y - 30.0, 28.0, 22.0)

## Retângulo da miniatura da k-ésima fantasia da seção "Lado de fora" (página direita do índice, terceira fileira).
static func rect_tile_fora(k: int) -> Rect2:
	return Rect2(_sn(COL_D_X + k * (TILE_W + TILE_GAP)), IDX_Y0 + 2 * IDX_PASSO + 24.0, TILE_W, TILE_H)

static func rect_aba(i: int) -> Rect2:
	return Rect2(ABA_X, ABA_Y0 + i * (ABA_H + ABA_GAP), ABA_W, ABA_H)

## Retângulo da miniatura de uma fantasia no índice, dado o cômodo e a posição nele.
static func rect_tile(comodo: int, k: int) -> Rect2:
	var esq: bool = comodo < 3
	var fila: int = comodo if esq else comodo - 3
	var x0: float = (COL_E_X if esq else COL_D_X) + k * (TILE_W + TILE_GAP)
	return Rect2(_sn(x0), IDX_Y0 + fila * IDX_PASSO + 24.0, TILE_W, TILE_H)

static func rect_linha_peca(i: int) -> Rect2:
	return Rect2(COL_D_X, LIN_Y0 + i * (LIN_H + LIN_GAP), COL_W, LIN_H)

## Quantas peças (de qualquer tipo) o jogador já teve, de 84.
static func pecas_obtidas(e: Estado) -> int:
	var n: int = 0
	for c in Pecas.CONJUNTO_PECAS.size():
		if not Pecas.retirada(c):
			n += e.pecas_da_fantasia(c)
	return n

static func pecas_possiveis() -> int:
	return Pecas.n_ativas() * Pecas.SLOTS

static func texto_totais(e: Estado) -> String:
	return "Fantasias completas: %d de %d  ·  Peças: %d de %d" % [e.fantasias_completas(), Pecas.n_ativas(), pecas_obtidas(e), pecas_possiveis()]

## Quantas fantasias completas há no cômodo `i`.
static func completas_do_comodo(e: Estado, i: int) -> int:
	var n: int = 0
	for c in Fases.CONJUNTOS[i]:
		if e.pecas_da_fantasia(c) >= Pecas.SLOTS:
			n += 1
	return n

## Rótulo da seção da fantasia: o cômodo onde cai, ou "Lado de fora".
static func nome_secao(c: int) -> String:
	var i: int = comodo_da_fantasia(c)
	return Fases.NOME[i] if i >= 0 else "Lado de fora"

## Quantas das fantasias que só caem fora da casa estão completas.
static func completas_so_de_fora(e: Estado) -> int:
	var n: int = 0
	for c in fantasias_so_de_fora():
		if e.pecas_da_fantasia(c) >= Pecas.SLOTS:
			n += 1
	return n

## Posse atual de um tipo de peça: {n: quantas, melhor: Peca ou null} (guarda-roupa e gatos vestidos).
static func posse(e: Estado, tipo: int) -> Dictionary:
	var n: int = 0
	var melhor: Peca = null
	var todas: Array = []
	todas.append_array(e.guarda)
	for b in e.bonecos:
		for p in b.pecas:
			if p != null:
				todas.append(p)
	for p in todas:
		if (p as Peca).tipo != tipo:
			continue
		n += 1
		if melhor == null or p.raridade > melhor.raridade or (p.raridade == melhor.raridade and p.nivel > melhor.nivel):
			melhor = p
	return {"n": n, "melhor": melhor}

static func texto_onde(c: int) -> String:
	var i: int = Fases.casa_final(c)
	if i < 0:
		return "Não cai em nenhum lugar"
	var fam: String = (Fases.FAMILIA_NOME[i].to_lower() + " e ") if i < Fases.FAMILIA_NOME.size() else ""
	return "Cai %s: %s%s" % [_em(i), fam, Fases.nome_do_chefe(i)]

## "Chefe: Rei dos Ratos (assinatura)" quando o chefe do lugar veste esta fantasia em 60% das lutas; senão só o nome do chefe.
static func texto_chefe(c: int) -> String:
	var i: int = Fases.casa_final(c)
	if i < 0:
		return ""
	return "Chefe: %s%s" % [Fases.nome_do_chefe(i), " (assinatura)" if Fases.CHEFE_ASSINATURA[i] == c else ""]

## Aviso das fantasias provisórias (3º ato ainda não existe): "por enquanto cai no Quintal". Vazio se já cai na casa final.
static func texto_provisorio(c: int) -> String:
	var fin: int = Fases.casa_final(c)
	var ag: int = Fases.lugar_atual(c)
	if fin < 0 or ag < 0 or ag == fin:
		return ""
	return "por enquanto cai %s" % _em(ag)

static func comodo_bloqueado(e: Estado, i: int) -> bool:
	return i + 1 > e.fase_liberada

static func texto_bloqueio(i: int) -> String:
	return "Cômodo bloqueado: vença o chefe %s, %s" % [Fases.CHEFE_NOME[i - 1], _em(i - 1)] if i >= 1 else ""

## "no Quarto", "na Sala", "na Cozinha", "no Sótão", "no Porão", "no Quintal", "na Garagem", "no Telhado", "na Rua", "na Toca".
static func _em(i: int) -> String:
	return ("na " if i in [1, 2, 6, 8, 9, 13] else "nos " if i == 14 else "no ") + Fases.nome_do_lugar(i)

## Lugares de fora (índices de Fases.NOME, 5 a 9) onde a fantasia cai, em texto: "no Quintal" ou "no Quintal e na Rua".
static func texto_fora(c: int) -> String:
	var l: Array[String] = []
	for i in range(Fases.TOTAL, Fases.CONJUNTOS.size()):
		if (Fases.CONJUNTOS[i] as Array).has(c):
			l.append(_em(i))
	if l.is_empty():
		return ""
	return l[0] if l.size() == 1 else ", ".join(l.slice(0, l.size() - 1)) + " e " + l[l.size() - 1]

static func _maiuscula(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)

# ------------------------------------------------------------------ texto medido
static var _larg_c: Dictionary = {}   # tamanho -> {texto -> largura}: a fonte não muda

static func largura(txt: String, tam: int) -> float:
	var por_tam: Dictionary = _larg_c.get(tam, {})
	if por_tam.has(txt):
		return float(por_tam[txt])
	var w: float = UIComum.FONTE.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam)).x
	if por_tam.size() > 400:
		por_tam.clear()
	por_tam[txt] = w
	_larg_c[tam] = por_tam
	return w

## Maior tamanho da lista em que o texto cabe em `larg` (o último, se nenhum couber).
static func tam_cabe(txt: String, tams: Array, larg: float) -> int:
	for tm in tams:
		if largura(txt, int(tm)) <= larg:
			return int(tm)
	return int(tams[tams.size() - 1])

static func quebrar(txt: String, tam: int, larg: float) -> Array[String]:
	var res: Array[String] = []
	var atual: String = ""
	# pedaços: cada palavra, e as partes de palavras com hífen (que podem quebrar depois do hífen)
	var pedacos: Array = []
	for palavra in txt.split(" "):
		var partes: PackedStringArray = palavra.split("-")
		for i in partes.size():
			pedacos.append([partes[i] + ("-" if i < partes.size() - 1 else ""), " " if i == 0 else ""])
	for pd in pedacos:
		var tent: String = pd[0] if atual == "" else atual + pd[1] + pd[0]
		if atual != "" and largura(tent, tam) > larg:
			res.append(atual)
			atual = pd[0]
		else:
			atual = tent
	if atual != "":
		res.append(atual)
	return res

## Corta com reticências até caber.
static func cortar(txt: String, tam: int, larg: float) -> String:
	if largura(txt, tam) <= larg:
		return txt
	var s: String = txt
	while s.length() > 1 and largura(s + "…", tam) > larg:
		s = s.substr(0, s.length() - 1)
	return s + "…"

## Escolhe o maior tamanho em que o texto quebrado cabe em `max_linhas`; devolve {tam, linhas}.
static func ajustar(txt: String, tams: Array, larg: float, max_linhas: int) -> Dictionary:
	var linhas: Array[String] = []
	var tam: int = int(tams[tams.size() - 1])
	for tm in tams:
		linhas = quebrar(txt, int(tm), larg)
		tam = int(tm)
		var cabe: bool = linhas.size() <= max_linhas
		for ln in linhas:
			if largura(ln, tam) > larg:
				cabe = false   # uma palavra comprida sozinha não cabe: tenta o tamanho menor
		if cabe:
			break
	if max_linhas >= 2 and linhas.size() == 1 and largura(linhas[0], tam) > larg * 1.12:
		# uma palavra só e comprida (Miauchelangelo): parte com hífen em vez de vazar da miniatura
		var palavra: String = linhas[0]
		var corte: int = palavra.length() - 1
		while corte > 1 and largura(palavra.substr(0, corte) + "-", tam) > larg:
			corte -= 1
		linhas = [palavra.substr(0, corte) + "-", palavra.substr(corte)]
	if linhas.size() > max_linhas:
		linhas = linhas.slice(0, max_linhas)
		linhas[max_linhas - 1] = cortar(linhas[max_linhas - 1] + " …", tam, larg)
	return {"tam": tam, "linhas": linhas}

## Desenha um bloco quebrado; devolve o y da linha seguinte.
func _bloco(txt: String, pos: Vector2, larg: float, tams: Array, max_linhas: int, cor: Color, entre: float = 3.0) -> float:
	var aj: Dictionary = ajustar(txt, tams, larg, max_linhas)
	var tam: int = aj["tam"]
	var y: float = pos.y
	for ln in aj["linhas"]:
		draw_string(UIComum.FONTE, Vector2(pos.x, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam), cor)
		y += tam + entre
	return y

func _txt(txt: String, pos: Vector2, tam: int, cor: Color, larg: float = -1.0, contorno: int = 0) -> void:
	Desenho.texto(self, txt, pos, tam, cor, larg, contorno)

# ------------------------------------------------------------------ montagem (itens clicáveis e silhuetas)
func _montar() -> void:
	foco = -1   # os itens mudam de uma página para outra: o foco antigo não vale mais
	itens.clear()
	_jobs.clear()
	if estado == null:
		return
	for i in N_ABAS:
		itens.append({"id": "aba%d" % i, "r": rect_aba(i), "on": true})
	itens.append({"id": "ant", "r": BTN_ANT, "on": metas_pag > 0 if em_metas else pagina > 0})
	itens.append({"id": "prox", "r": BTN_PROX, "on": metas_pag < 1 if em_metas else pagina < total_paginas() - 1})
	itens.append({"id": "fechar", "r": BTN_FECHAR, "on": true})
	itens.append({"id": "ajuda", "r": BTN_AJUDA, "on": true})
	if em_metas:
		return
	if em_bichos:
		_montar_bichos()
		return
	if pagina == 0:
		for i in Fases.TOTAL:
			var sala: Array = Fases.CONJUNTOS[i]
			for k in sala.size():
				var c: int = sala[k]
				var r: Rect2 = rect_tile(i, k)
				itens.append({"id": "f%d" % c, "r": r, "on": true})
				var cab: int = Pecas.CONJUNTO_PECAS[c][0]
				if not estado.ja_teve(cab):
					_jobs.append({"k": "icone", "tipo": cab, "centro": r.position + Vector2(TILE_W * 0.5, TILE_ICO_Y), "tam": 50.0})
		var fo: Array[int] = fantasias_so_de_fora()
		fora_pag = clampi(fora_pag, 0, fora_paginas(fo.size()) - 1)
		if fora_paginas(fo.size()) > 1:
			itens.append({"id": "pgf_ant", "r": rect_seta_fora(-1), "on": fora_pag > 0})
			itens.append({"id": "pgf_prox", "r": rect_seta_fora(1), "on": fora_pag < fora_paginas(fo.size()) - 1})
		for k in range(fora_pag * FORA_POR_PAG, mini(fo.size(), (fora_pag + 1) * FORA_POR_PAG)):
			var rf: Rect2 = rect_tile_fora(k - fora_pag * FORA_POR_PAG)
			itens.append({"id": "f%d" % fo[k], "r": rf, "on": true})
			var cabf: int = Pecas.CONJUNTO_PECAS[fo[k]][0]
			if not estado.ja_teve(cabf):
				_jobs.append({"k": "icone", "tipo": cabf, "centro": rf.position + Vector2(TILE_W * 0.5, TILE_ICO_Y), "tam": 50.0})
	elif pagina_do_atelie():
		return
	else:
		var c2: int = fantasia_da_pagina(pagina)
		var faltam: Array = []
		for s in Pecas.SLOTS:
			var tp: int = Pecas.CONJUNTO_PECAS[c2][s]
			if not estado.ja_teve(tp):
				faltam.append(tp)
				var r2: Rect2 = rect_linha_peca(s)
				_jobs.append({"k": "icone", "tipo": tp, "centro": _caixa_icone(r2).get_center(), "tam": 56.0})
		_jobs.append({"k": "gato", "c": c2, "faltam": faltam})

static func _caixa_icone(linha: Rect2) -> Rect2:
	return Rect2(linha.position.x + 8.0, linha.position.y + 13.0, 68.0, 68.0)

func _item_em(p: Vector2) -> int:
	for k in itens.size():
		if (itens[k]["r"] as Rect2).has_point(p):
			return k
	return -1

static func _cabine_gato() -> Rect2:
	return Rect2(COL_E_X, 122.0, COL_W, 262.0)

static func _pos_gato() -> Vector2:
	var cb: Rect2 = _cabine_gato()
	return Vector2(cb.get_center().x, cb.end.y - 44.0)

# ------------------------------------------------------------------ ações e entrada
func acionar(id: String) -> void:
	if not aberta:
		return
	if id == "x":
		fechar()
		return
	if id == "pgf_ant" or id == "pgf_prox":
		var np_f: int = clampi(fora_pag + (1 if id == "pgf_prox" else -1), 0, fora_paginas(fantasias_so_de_fora().size()) - 1)
		if np_f != fora_pag:
			fora_pag = np_f
			Som.tocar("pagina")
			_montar()
		return
	if id.begins_with("aba") and int(id.substr(3)) != aba_atual():
		Som.tocar("aba")
	elif id.begins_with("f") or id.begins_with("b") or id == "fechar":
		Som.tocar("clique")
	if id == "ajuda":
		Som.tocar("clique")
		ajuda_pedida.emit()
	elif id == "fechar":
		fechar()
	elif id == "ant":
		ir_para_pagina(pagina - 1)
	elif id == "prox":
		ir_para_pagina(pagina + 1)
	elif id.begins_with("aba"):
		var i: int = int(id.substr(3))
		if i == ABA_METAS:
			if not em_metas:
				em_metas = true
				em_bichos = false
				metas_pag = 0
				_montar()
				metas_vistas.emit()
			return
		if i == ABA_BICHOS:
			if not em_bichos:
				em_bichos = true
				em_metas = false
				pagina = 0
				_montar()
			return
		if em_metas or em_bichos:
			em_metas = false
			em_bichos = false
			pagina = -1
			_montar()
		if i == 0:
			ir_para_pagina(0)
		elif i == ABA_FORA:
			ir_para_fora()
		else:
			ir_para_comodo(i - 1)
	elif id.begins_with("f"):
		ir_para_fantasia(int(id.substr(1)))
	elif _eh_tile(id):
		ir_para_pagina(int(id.substr(1)) + (BICHOS_PAG_INDICE if em_bichos else 1))

func _gui_input(ev: InputEvent) -> void:
	if not aberta:
		return
	if ev is InputEventMouseMotion:
		_mouse = (ev as InputEventMouseMotion).position
		x_sobre = BTN_X.has_point(_mouse)
		foco = _item_em(_mouse)
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and BTN_X.has_point(mb.position):
			x_press = mb.pressed
			if not mb.pressed:
				acionar("x")
			return
		x_press = false
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			ir_para_pagina(pagina - 1)
			return
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			ir_para_pagina(pagina + 1)
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		var i: int = _item_em(mb.position)
		var dentro: bool = CAPA.has_point(mb.position) or _em_aba(mb.position)
		if mb.pressed:
			apertado_id = itens[i]["id"] if i >= 0 else ""
			apertado_fora = i < 0 and not dentro
		else:
			var antes: String = apertado_id
			var fora: bool = apertado_fora
			apertado_id = ""
			apertado_fora = false
			if i >= 0 and itens[i]["id"] == antes:
				if itens[i]["on"]:
					acionar(antes)
			elif i < 0 and fora and not dentro:
				fechar()   # clicou (e soltou) fora do álbum

static func _em_aba(p: Vector2) -> bool:
	for i in N_ABAS:
		if rect_aba(i).has_point(p):
			return true
	return false

func _input(ev: InputEvent) -> void:
	if not aberta or not (ev is InputEventKey):
		return
	var k: InputEventKey = ev as InputEventKey
	if not k.pressed:
		return
	if k.echo and not (k.keycode in [KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D]):
		get_viewport().set_input_as_handled()
		return
	tecla(k.keycode)
	get_viewport().set_input_as_handled()   # aberto: nenhuma tecla chega ao que está por baixo

## Esc fecha; esquerda/A/PageUp voltam; direita/D/PageDown avançam; Home/End vão às pontas.
## Devolve true se a tecla foi usada.
func tecla(kc: int) -> bool:
	if not aberta:
		return false
	var no_tile: bool = _foco_e_tile()
	if (pagina == 0 or (em_bichos and pagina == 1)) and not em_metas:
		var dir := Vector2i.ZERO
		match kc:
			KEY_LEFT, KEY_A:
				dir = Vector2i(-1, 0)
			KEY_RIGHT, KEY_D:
				dir = Vector2i(1, 0)
			KEY_UP, KEY_W:
				dir = Vector2i(0, -1)
			KEY_DOWN, KEY_S:
				dir = Vector2i(0, 1)
		if dir != Vector2i.ZERO and (no_tile or dir.y != 0):
			_mover_tile(dir)
			return true
		if (kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE) and foco >= 0 and foco < itens.size() and itens[foco]["on"]:
			acionar(itens[foco]["id"])
			return true
	match kc:
		KEY_ESCAPE:
			fechar()
		KEY_LEFT, KEY_A, KEY_PAGEUP:
			ir_para_pagina(pagina - 1)
		KEY_RIGHT, KEY_D, KEY_PAGEDOWN:
			ir_para_pagina(pagina + 1)
		KEY_HOME:
			ir_para_pagina(0)
		KEY_END:
			ir_para_pagina(total_paginas() - 1)
		_:
			return false
	return true

func _foco_e_tile() -> bool:
	if foco < 0 or foco >= itens.size():
		return false
	return _eh_tile(itens[foco]["id"])

static func _eh_tile(id: String) -> bool:
	return id.length() > 1 and (id[0] == "f" or id[0] == "b") and id.substr(1).is_valid_int()

## Foco de teclado nas miniaturas do índice: vai à miniatura mais próxima na direção `d`.
func _mover_tile(d: Vector2i) -> void:
	var tem: bool = _foco_e_tile()
	var cur: Vector2 = Vector2(PG_E.position.x, 130.0)
	if tem:
		cur = (itens[foco]["r"] as Rect2).get_center()
	var melhor: int = -1
	var ms: float = INF
	for j in itens.size():
		var id: String = itens[j]["id"]
		if not _eh_tile(id) or j == foco:
			continue
		var dc: Vector2 = (itens[j]["r"] as Rect2).get_center() - cur
		if tem:
			var ao: float = dc.x * d.x + dc.y * d.y
			if ao <= 4.0:
				continue
			var sc: float = ao + (absf(dc.x * d.y) + absf(dc.y * d.x)) * 2.5
			if sc < ms:
				ms = sc
				melhor = j
		elif dc.length() < ms:
			ms = dc.length()
			melhor = j
	if melhor >= 0:
		foco = melhor

func _process(delta: float) -> void:
	t += delta
	if not aberta:
		return
	abrir_t += delta
	var s_pop: float = UIComum.pop(abrir_t)
	_sil.pivot_offset = Vector2(640.0, 360.0)
	_sil.scale = Vector2(s_pop, s_pop)
	UIComum.anim_passo(anim, "x", x_sobre, x_sobre and x_press, delta)
	for i in itens.size():
		var id: String = itens[i]["id"]
		UIComum.anim_passo(anim, id, i == foco, i == foco and apertado_id == id, delta)
	if foco != _foco_som:
		if foco >= 0 and abrir_t > 0.1:
			UIComum.som_hover()
		_foco_som = foco
	if carimbo_t < 9.0:
		var antes: float = carimbo_t
		carimbo_t += delta
		if antes < 0.0 and carimbo_t >= 0.0:
			Som.tocar("trofeu")
			faiscas.emitir(_cabine_gato().end - Vector2(96.0, 100.0), 20, UIComum.FAISCA_COR, 220.0, 0.7)
	faiscas.passo(delta)
	virar_t = maxf(0.0, virar_t - delta)
	queue_redraw()
	_sil.queue_redraw()

# ------------------------------------------------------------------ pintura: peças básicas
## Mesmo recorte em 9 fatias do jogo (a cópia evita depender do `principal.gd`).
static func _ladrilhar(c: CanvasItem, tex: Texture2D, s: Rect2, d: Rect2, esc: float, cor: Color) -> void:
	if d.size.x <= 0.5 or d.size.y <= 0.5 or s.size.x <= 0.0 or s.size.y <= 0.0:
		return
	var sw: float = s.size.x * esc
	var sh: float = s.size.y * esc
	var y: float = d.position.y
	while y < d.end.y - 0.01:
		var h: float = minf(sh, d.end.y - y)
		var x: float = d.position.x
		while x < d.end.x - 0.01:
			var w: float = minf(sw, d.end.x - x)
			c.draw_texture_rect_region(tex, Rect2(x, y, w, h), Rect2(s.position, Vector2(w / esc, h / esc)), cor)
			x += sw
		y += sh

static func _nove(c: CanvasItem, tex: Texture2D, src: Rect2, m: Vector4, dst: Rect2, esc: float, cor: Color = Color.WHITE, miolo: bool = true) -> void:
	var e: float = minf(esc, minf(dst.size.x / maxf(1.0, m.x + m.z), dst.size.y / maxf(1.0, m.y + m.w)))
	var ml: float = m.x * e
	var mt: float = m.y * e
	var mr: float = m.z * e
	var mb: float = m.w * e
	var x0: float = dst.position.x
	var y0: float = dst.position.y
	var x1: float = x0 + ml
	var y1: float = y0 + mt
	var x2: float = dst.end.x - mr
	var y2: float = dst.end.y - mb
	var sx: float = src.position.x
	var sy: float = src.position.y
	var iw: float = src.size.x - m.x - m.z
	var ih: float = src.size.y - m.y - m.w
	c.draw_texture_rect_region(tex, Rect2(x0, y0, ml, mt), Rect2(sx, sy, m.x, m.y), cor)
	c.draw_texture_rect_region(tex, Rect2(x2, y0, mr, mt), Rect2(sx + src.size.x - m.z, sy, m.z, m.y), cor)
	c.draw_texture_rect_region(tex, Rect2(x0, y2, ml, mb), Rect2(sx, sy + src.size.y - m.w, m.x, m.w), cor)
	c.draw_texture_rect_region(tex, Rect2(x2, y2, mr, mb), Rect2(sx + src.size.x - m.z, sy + src.size.y - m.w, m.z, m.w), cor)
	_ladrilhar(c, tex, Rect2(sx + m.x, sy, iw, m.y), Rect2(x1, y0, x2 - x1, mt), e, cor)
	_ladrilhar(c, tex, Rect2(sx + m.x, sy + src.size.y - m.w, iw, m.w), Rect2(x1, y2, x2 - x1, mb), e, cor)
	_ladrilhar(c, tex, Rect2(sx, sy + m.y, m.x, ih), Rect2(x0, y1, ml, y2 - y1), e, cor)
	_ladrilhar(c, tex, Rect2(sx + src.size.x - m.z, sy + m.y, m.z, ih), Rect2(x2, y1, mr, y2 - y1), e, cor)
	if miolo:
		_ladrilhar(c, tex, Rect2(sx + m.x, sy + m.y, iw, ih), Rect2(x1, y1, x2 - x1, y2 - y1), e, cor)

static func _sn(v: float) -> float:
	return floorf(v / Q) * Q

## Papel em pixel: retângulo com os cantos pedidos (topo-esq, topo-dir, base-dir, base-esq) chanfrados em
## `n` degraus de Q px. Fileiras que não se sobrepõem: cor com alfa (sombra) fica limpa.
func _papel_px(r: Rect2, n: int, te: bool, td: bool, bd: bool, be: bool, cor: Color) -> void:
	var x0: float = _sn(r.position.x)
	var y0: float = _sn(r.position.y)
	var x1: float = _sn(r.end.x)
	var y1: float = _sn(r.end.y)
	n = maxi(0, n)
	for k in n:
		var d: float = (n - k) * Q
		var l: float = x0 + (d if te else 0.0)
		draw_rect(Rect2(l, y0 + k * Q, x1 - (d if td else 0.0) - l, Q), cor)
		l = x0 + (d if be else 0.0)
		draw_rect(Rect2(l, y1 - (k + 1) * Q, x1 - (d if bd else 0.0) - l, Q), cor)
	draw_rect(Rect2(x0, y0 + n * Q, x1 - x0, y1 - y0 - 2.0 * n * Q), cor)

## O mesmo papel com contorno de uma célula (o degrau do chanfro também fica com uma célula de espessura).
func _papel_borda(r: Rect2, n: int, te: bool, td: bool, bd: bool, be: bool, fundo: Color, borda: Color) -> void:
	_papel_px(r, n, te, td, bd, be, borda)
	_papel_px(r.grow(-Q), n - 1, te, td, bd, be, fundo)

## Moldura de `larg` px (múltiplo de Q) por dentro de `r`, em quatro retângulos.
func _moldura_px(r: Rect2, cor: Color, larg: float = Q) -> void:
	var x0: float = _sn(r.position.x)
	var y0: float = _sn(r.position.y)
	var w: float = _sn(r.end.x) - x0
	var h: float = _sn(r.end.y) - y0
	draw_rect(Rect2(x0, y0, w, larg), cor)
	draw_rect(Rect2(x0, y0 + h - larg, w, larg), cor)
	draw_rect(Rect2(x0, y0 + larg, larg, h - 2.0 * larg), cor)
	draw_rect(Rect2(x0 + w - larg, y0 + larg, larg, h - 2.0 * larg), cor)

## Grade de letras (ver Oficina.grade) com o canto de cima em `pos`, já na grade.
func _grade(g: Array, pos: Vector2, a: Color, b: Color, c: Color, cont: Color, espelho: bool = false) -> void:
	Oficina.grade(self, g, Vector2(_sn(pos.x), _sn(pos.y)), Q, a, b, c, cont, espelho)

## Cantoneira de foto em degraus: triângulo de `n` células no canto (px, py), abrindo para (sx, sy).
func _cantoneira(px: float, py: float, sx: float, sy: float, n: int, cor: Color) -> void:
	for k in n:
		var w: float = (n - k) * Q
		var y: float = py + k * Q if sy > 0.0 else py - (k + 1) * Q
		draw_rect(Rect2(px if sx > 0.0 else px - w, y, w, Q), cor)

## As quatro cantoneiras de uma foto.
func _cantoneiras(cb: Rect2, cor: Color) -> void:
	_cantoneira(cb.position.x, cb.position.y, 1.0, 1.0, 9, cor)
	_cantoneira(cb.end.x, cb.position.y, -1.0, 1.0, 9, cor)
	_cantoneira(cb.position.x, cb.end.y, 1.0, -1.0, 9, cor)
	_cantoneira(cb.end.x, cb.end.y, -1.0, -1.0, 9, cor)

## Bolinha de situação de 15 px com o canto de cima à esquerda perto de `pos`: verde com visto, ou lisa.
func _bolinha(pos: Vector2, cor: Color, visto: bool) -> void:
	_grade(PX_VISTO if visto else PX_BOLINHA, pos, cor, cor, cor, cor.darkened(0.4))

func _folha(r: Rect2, esquerda: bool) -> void:
	var te: bool = esquerda
	var td: bool = not esquerda
	# folhas de baixo, para dar espessura ao álbum: uma faixa de papel e, por fim, a borda escura
	var dx: float = -Q if esquerda else Q
	_papel_px(Rect2(r.position + Vector2(dx * 2.0, Q * 2.0), r.size), 4, te, td, td, te, Color(0.42, 0.32, 0.24))
	_papel_px(Rect2(r.position + Vector2(dx, Q), r.size), 4, te, td, td, te, Color(0.82, 0.76, 0.62).darkened(0.06))
	_papel_borda(r, 4, te, td, td, te, PAPEL, PAPEL_BORDA)
	# linhas de caderno bem fracas, uma célula de altura
	var x0: float = _sn(r.position.x) + Q * 2.0
	var x1: float = _sn(r.end.x) - Q * 2.0
	var y: float = _sn(r.position.y + 50.0)
	while y < r.end.y - 12.0:
		draw_rect(Rect2(x0, y, x1 - x0, Q), Color(0.45, 0.6, 0.8, 0.07))
		y += Q * 7.0
	# sombra na dobra (espinha): quatro faixas de uma célula, do escuro para o claro
	for i in 4:
		var a: float = 0.15 - 0.035 * i
		var x: float = (_sn(r.end.x) - Q * (i + 2)) if esquerda else (_sn(r.position.x) + Q * (i + 1))
		draw_rect(Rect2(x, _sn(r.position.y) + Q, Q, _sn(r.end.y) - _sn(r.position.y) - Q * 2.0), Color(0.25, 0.15, 0.1, a))

func _argolas() -> void:
	var xe: float = _sn(ESPINHA_X - 21.0)        # a barra vai de xe a xe + 15 células
	for i in 5:
		var y: float = _sn(118.0 + i * 108.0)
		# furos nas duas folhas: discos de 3 células
		V.disco(self, Vector2(PG_E.end.x - 12.0, y + 1.5), 4.0, FURO, Q)
		V.disco(self, Vector2(PG_D.position.x + 12.0, y + 1.5), 4.0, FURO, Q)
		# argola de metal atravessando a espinha: cinco fileiras (contorno, brilho, miolo, sombra, contorno)
		draw_rect(Rect2(xe, y - Q * 2.0, Q * 15.0, Q * 5.0), ARGOLA_CONT)
		draw_rect(Rect2(xe, y - Q, Q * 15.0, Q), ARGOLA_CL)
		draw_rect(Rect2(xe, y, Q * 15.0, Q), Color(0.7, 0.72, 0.8))
		draw_rect(Rect2(xe, y + Q, Q * 15.0, Q), ARGOLA_ESC)
		# as pontas: discos com contorno e um brilho
		_ponta_argola(xe + Q * 0.5, y)
		_ponta_argola(xe + Q * 14.5, y)

## Ponta da argola: disco com contorno e um brilho em cima à esquerda.
func _ponta_argola(px: float, y: float) -> void:
	V.disco_c(self, Vector2(px, y + 1.5), 3.0, ARGOLA, ARGOLA_CONT, Q)
	draw_rect(Rect2(_sn(px) - Q, y - Q, Q, Q), ARGOLA_CL)

func _faixa(r: Rect2, txt: String, tams: Array, cor: Color) -> void:
	draw_rect(r.grow(2.0), Color(0, 0, 0, 0.18))
	draw_rect(r, COR_FAIXA)
	draw_rect(r, cor.darkened(0.1), false, 2.0)
	var tam: int = tam_cabe(txt, tams, r.size.x - 24.0)
	var f: Font = UIComum.FONTE
	var y: float = r.position.y + (r.size.y - f.get_height(UIComum.tam(tam))) * 0.5 + f.get_ascent(UIComum.tam(tam))
	_txt(txt, Vector2(r.position.x, y), tam, cor, r.size.x, 6)

## Estrela em pixel (7 x 7 células, 21 px) centrada em `centro`.
func _estrela(centro: Vector2, cor: Color) -> void:
	_grade(PX_ESTRELA, centro - Vector2(10.5, 10.5), cor, cor, cor.lightened(0.6), PX_ESC)

func _cadeado(centro: Vector2, cor: Color) -> void:
	Oficina.cadeado(self, centro, cor)

## Troféu em pixel (o da torre, 9 x 8 células de 2 px), centrado em `centro`; desbotado se ainda não ganho.
func _trofeu(centro: Vector2, ganho: bool) -> void:
	Oficina.arte(self, TorrePx.SPR_TROFEU, (centro - Vector2(9.0, 8.0)).round(), 2.0, false, 1.0 if ganho else 0.4)

## Emblema do grupo de metas (21 px) com o canto de cima em `pos`.
func _emblema_grupo(g: String, pos: Vector2) -> void:
	if not PX_GRUPO.has(g):
		return
	var a: Color = TINTA2
	var b: Color = PAPEL
	var c: Color = COR_OURO
	match g:
		"Campanha":
			a = COR_FALTA
		"Guarda-roupa":
			a = Color(0.62, 0.42, 0.25)
		"Invasão":
			a = COR_ABA[2].darkened(0.15)
			b = COR_ABA[2].darkened(0.35)
			c = COR_ABA[2].lightened(0.4)
		"Lado de fora":
			a = COR_TEM.lightened(0.15)
			b = TINTA2
			c = COR_ABA[5].lightened(0.3)
	_grade(PX_GRUPO[g], pos, a, b, c, TINTA)

# ------------------------------------------------------------------ pintura geral
func _draw() -> void:
	if not aberta or estado == null:
		return
	var e: Estado = estado
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.74 * minf(1.0, abrir_t / 0.12)))
	UIComum.ini_pop(self, Vector2(640.0, 360.0), UIComum.pop(abrir_t))
	# capa de couro, costura e moldura de madeira
	draw_rect(CAPA.grow(-16.0), COR_CAPA)
	for i in 6:
		draw_rect(Rect2(CAPA.position.x + 16, CAPA.position.y + 16 + i * 120, CAPA.size.x - 32, 60), Color(1, 1, 1, 0.012))
	# costura: pontos de 2 x 1 células, um a cada 4 células
	var cx0: float = _sn(CAPA.position.x + 27.0)
	var cy0: float = _sn(CAPA.position.y + 27.0)
	var cx1: float = _sn(CAPA.end.x - 27.0)
	var cy1: float = _sn(CAPA.end.y - 27.0)
	var x: float = cx0
	while x + Q * 2.0 <= cx1:
		draw_rect(Rect2(x, cy0, Q * 2.0, Q), COR_COSTURA)
		draw_rect(Rect2(x, cy1, Q * 2.0, Q), COR_COSTURA)
		x += Q * 4.0
	var y: float = cy0 + Q * 2.0
	while y + Q * 2.0 <= cy1:
		draw_rect(Rect2(cx0, y, Q, Q * 2.0), COR_COSTURA)
		draw_rect(Rect2(cx1, y, Q, Q * 2.0), COR_COSTURA)
		y += Q * 4.0
	_nove(self, GUI_TEX, R_MADEIRA, M_MADEIRA, CAPA, 0.75, Color.WHITE, false)
	# plaqueta dourada com o título: borda escura, miolo dourado com brilho em cima e sombra embaixo
	var placa := Rect2(_sn(592.0 - 130.0), _sn(33.0), 261.0, 24.0)
	UIComum.forma(self, placa, Color(0.5, 0.32, 0.06))
	draw_rect(Rect2(placa.position.x + Q, placa.position.y + Q, placa.size.x - Q * 2.0, placa.size.y - Q * 2.0), Color(0.95, 0.78, 0.3))
	draw_rect(Rect2(placa.position.x + Q * 2.0, placa.position.y + Q, placa.size.x - Q * 4.0, Q), Color(1.0, 0.92, 0.6))
	draw_rect(Rect2(placa.position.x + Q, placa.end.y - Q * 2.0, placa.size.x - Q * 2.0, Q), Color(0.8, 0.6, 0.2))
	_txt("Fichário de fantasias", Vector2(placa.position.x, placa.position.y + 17.0), 16, Color(0.3, 0.17, 0.04), placa.size.x)
	UIComum.pata(self, 0, Vector2(placa.position.x + 8.0, placa.position.y + 2.0), 1)
	UIComum.pata(self, 2, Vector2(placa.end.x - 23.0, placa.position.y + 2.0), 1)
	# as duas folhas e as argolas
	_folha(PG_E, true)
	_folha(PG_D, false)
	_argolas()
	if em_metas:
		_pagina_metas(e)
	elif em_bichos:
		_pagina_bichos(e)
	elif pagina == 0:
		_pagina_indice(e)
	elif pagina_do_atelie():
		_pagina_atelie(e)
	else:
		_pagina_fantasia(e, fantasia_da_pagina(pagina))
	# virada de página: uma folha de papel varrendo a página nova
	if virar_t > 0.0:
		var k: float = virar_t / 0.26
		var alvo: Rect2 = PG_D if virar_dir > 0 else PG_E
		# a folha some encolhendo (sem esmaecer), com a largura e a borda na grade
		var ax0: float = _sn(alvo.position.x) + Q
		var ax1: float = _sn(alvo.end.x) - Q
		var larg: float = _sn((ax1 - ax0) * k)
		if larg >= Q:
			var ay: float = _sn(alvo.position.y) + Q
			var ah: float = _sn(alvo.end.y) - Q - ay
			var rx: float = ax0 if virar_dir > 0 else ax1 - larg
			draw_rect(Rect2(rx, ay, larg, ah), PAPEL)
			var borda_x: float = rx + larg - Q if virar_dir > 0 else rx
			draw_rect(Rect2(borda_x, ay, Q, ah), PAPEL_ESC.darkened(0.12))
	_abas(e)
	_botoes()
	UIComum.fechar(self, BTN_X, {"on": true, "foco": x_sobre, "h": UIComum.anim_h(anim, "x"), "p": UIComum.anim_p(anim, "x")}, t)
	faiscas.desenhar(self)
	_dica_tile()
	UIComum.fim_pop(self)

# ------------------------------------------------------------------ abas e botões
func _abas(e: Estado) -> void:
	var atual: int = aba_atual()
	for i in N_ABAS:
		var r: Rect2 = rect_aba(i)
		var ativa: bool = i == atual
		var sobre: bool = foco >= 0 and itens[foco]["id"] == "aba%d" % i
		var cor: Color = COR_ABA[i]
		if not ativa and not sobre:
			cor = cor.darkened(0.14)
		var avanco: float = 15.0 if ativa else (6.0 if sobre else 0.0)
		var rr := Rect2(_sn(r.position.x - avanco), _sn(r.position.y), r.size.x + avanco, r.size.y)
		# sombra (uma forma só, sem sobreposição), contorno de uma célula e brilho na beirada de cima
		_papel_px(Rect2(rr.position + Vector2(Q, Q), rr.size), 4, false, true, true, false, Color(0, 0, 0, 0.3))
		_papel_borda(rr, 4, false, true, true, false, cor, TINTA)
		draw_rect(Rect2(rr.position.x + Q, rr.position.y + Q, _sn(rr.end.x) - rr.position.x - Q * 5.0, Q), cor.lightened(0.3))
		var nome: String = "Índice" if i == 0 else ("Bichos" if i == ABA_BICHOS else "Metas" if i == ABA_METAS else ("De fora" if i == ABA_FORA else Fases.NOME[i - 1]))
		var sub: String = ""
		if i == ABA_BICHOS:
			sub = "%d/%d" % [e.bichos_vistos_total(), Estado.BICHOS_TOTAL]
		elif i == ABA_METAS:
			sub = "%d/%d" % [e.metas_cumpridas(), Metas.lista().size()]
		elif i == ABA_FORA:
			sub = "%d/%d" % [completas_so_de_fora(e), fantasias_so_de_fora().size()]
		elif i == 0:
			sub = "%d/%d" % [e.fantasias_completas(), Pecas.n_ativas()]
		else:
			sub = "%d/%d" % [completas_do_comodo(e, i - 1), Fases.CONJUNTOS[i - 1].size()]
		var cx: float = r.position.x + 28.0 + (r.size.x - 28.0 - 12.0) * 0.5
		var larg_t: float = r.end.x - 14.0 - (r.position.x + 28.0)
		_txt(nome, Vector2(cx - larg_t * 0.5, rr.position.y + 25.0), 17, TINTA, larg_t)
		_txt(sub, Vector2(cx - larg_t * 0.5, rr.position.y + 44.0), 13, TINTA2, larg_t)
		if i == ABA_METAS and not metas_novas.is_empty() and not em_metas:
			var sn_c := Vector2(rr.position.x + 19.5, rr.position.y + 28.5)
			V.disco_c(self, sn_c, 4.0, SELO_NOVO, TINTA, Q)
			draw_rect(Rect2(_sn(sn_c.x) - Q, _sn(sn_c.y) - Q, Q, Q), SELO_NOVO.lightened(0.55))
		if i > 0 and i < ABA_FORA and comodo_bloqueado(e, i - 1):
			_cadeado(Vector2(rr.position.x + 18.0, rr.position.y + 28.0), Color(0.3, 0.2, 0.25))

func _botoes() -> void:
	for i in itens.size():
		var it: Dictionary = itens[i]
		var id: String = it["id"]
		if id.begins_with("aba") or _eh_tile(id) or id.begins_with("pgf"):
			continue
		var txt: String = "?" if id == "ajuda" else ("Fechar" if id == "fechar" else ("Voltar" if id == "ant" else "Avançar"))
		var cor: Color = UIComum.B_AZUL if id == "ajuda" else (UIComum.B_MARROM if id == "fechar" else UIComum.B_OURO)
		var o: Dictionary = {"on": it["on"], "foco": i == foco and it["on"], "h": UIComum.anim_h(anim, id), "p": UIComum.anim_p(anim, id), "tam": 17}
		UIComum.botao(self, it["r"], txt, cor, o, t)
		if id == "ant" or id == "prox":
			_seta_nav(it["r"], -1.0 if id == "ant" else 1.0, it["on"], float(o["h"]), float(o["p"]))
	var marca: String = ("Metas %d/2" % (metas_pag + 1)) if em_metas else ("Bestiário" if pagina == 0 else "Bestiário: gangues" if pagina == 1 else "Bicho %d de %d" % [pagina - 1, entradas().size()]) if em_bichos else "Índice" if pagina == 0 else "Ateliê  ·  a sua fantasia" if pagina_do_atelie() else "Fantasia %d de %d  ·  %s" % [pagina, _ordem.size(), nome_secao(fantasia_da_pagina(pagina))]
	_txt(UIComum.caber(marca.replace("  ·  ", " · "), 15, 236.0) if UIComum.largura(marca, 15) > 236.0 else marca, Vector2(250.0, 672.0), 15, Color(1, 0.94, 0.8), 240.0, 4)
	# entre o Fechar e o Avançar há ~230 px: o texto é medido no 19 em que é desenhado e encurta se não couber
	var atalhos: String = "Setas, A/D ou PgUp/PgDn  |  Esc fecha"
	if UIComum.largura(atalhos, 13) > 226.0:
		atalhos = "Setas ou A/D  |  Esc fecha"
	_txt(atalhos, Vector2(700.0, 672.0), 13, Color(1, 0.94, 0.8, 0.7), 230.0, 3)

## Seta em pixel dentro do botão Voltar/Avançar, junto da borda; acompanha o crescer e o afundar do botão.
func _seta_nav(r: Rect2, dir: float, on: bool, h: float, pr: float) -> void:
	if not on:
		h = 0.0
		pr = 0.0
	r = Rect2(r.position.round(), r.size.round())
	var esc: float = 1.0 + 0.045 * h - 0.05 * pr
	UIComum.trans(self, r.get_center(), 0.0, Vector2(esc, esc))
	var x: float = -r.size.x * 0.5 + 12.0 if dir < 0.0 else r.size.x * 0.5 - 12.0 - Q * 8.0
	var y: float = -Q * 3.5 + (3.0 if on and pr > 0.45 else 0.0)
	var miolo: Color = UIComum.C_CREME if on else Color(0.72, 0.68, 0.66)
	var cont: Color = UIComum.C_CONT if on else Color(0.56, 0.5, 0.5)
	Oficina.grade(self, PX_SETA_NAV, Vector2(roundf(x), roundf(y)), Q, miolo, miolo, miolo, cont, dir > 0.0)
	UIComum.trans_fim(self)

## Dica do mouse (ou do foco do teclado) sobre uma miniatura do índice.
func _dica_tile() -> void:
	if em_bichos and pagina <= 1 and _foco_e_tile():
		var en: Dictionary = entradas()[int(String(itens[foco]["id"]).substr(1))]
		var rb: Rect2 = itens[foco]["r"]
		var vis: bool = estado.viu_bicho(en["chave"])
		var st: String = "Ainda não visto" if not vis else ("Derrotado" if _derrotado(estado, en) else "Visto")
		UIComum.dica_mouse(self, [[en["nome"] if vis else "???", 16, TINTA], [st, 13, TINTA2]], _mouse if rb.has_point(_mouse) else rb.get_center(), en["cor"])
		return
	if pagina != 0 or em_metas or em_bichos or not _foco_e_tile():
		return
	var c: int = int(String(itens[foco]["id"]).substr(1))
	var r: Rect2 = itens[foco]["r"]
	var pos: Vector2 = _mouse if r.has_point(_mouse) else r.get_center()
	UIComum.dica_mouse(self, [[Pecas.CONJUNTO_NOME[c], 16, TINTA], ["%d de %d peças" % [estado.pecas_da_fantasia(c), Pecas.SLOTS], 13, TINTA2]], pos, Pecas.CONJUNTO_COR[c])

# ------------------------------------------------------------------ página do índice
func _pagina_indice(e: Estado) -> void:
	_faixa(Rect2(COL_E_X, 76.0, COL_W, 38.0), "Índice", [30, 26], COR_OURO)
	_faixa(Rect2(COL_D_X, 76.0, COL_W, 38.0), texto_totais(e), [17, 16, 15, 14, 13, 12], Color(1.0, 0.94, 0.7))
	for i in Fases.TOTAL:
		var sala: Array = Fases.CONJUNTOS[i]
		var r0: Rect2 = rect_tile(i, 0)
		var lbl: String = "%s  ·  %d/%d completas" % [Fases.NOME[i], completas_do_comodo(e, i), sala.size()]
		var ax: float = r0.position.x
		var ay: float = r0.position.y - 8.0
		draw_rect(Rect2(ax, ay - 16.0, 5.0, 16.0), COR_ABA[i + 1].darkened(0.1))
		_txt(lbl, Vector2(ax + 11.0, ay - 2.0), 16, TINTA)
		if comodo_bloqueado(e, i):
			var wl: float = largura(lbl, 16)
			_cadeado(Vector2(ax + 11.0 + wl + 16.0, ay - 6.0), Color(0.45, 0.32, 0.3))
			_txt("bloqueado", Vector2(ax + 11.0 + wl + 28.0, ay - 2.0), 12, TINTA2)
		for k in sala.size():
			_tile(e, sala[k], rect_tile(i, k))
	# seção "Lado de fora": fantasias que só caem fora da casa (página direita, terceira fileira)
	var fo2: Array[int] = fantasias_so_de_fora()
	if not fo2.is_empty():
		var rf0: Rect2 = rect_tile_fora(0)
		var lblf: String = "Lado de fora  ·  %d/%d completas" % [completas_so_de_fora(e), fo2.size()]
		draw_rect(Rect2(rf0.position.x, rf0.position.y - 24.0, 5.0, 16.0), COR_ABA[ABA_FORA].darkened(0.1))
		_txt(lblf, Vector2(rf0.position.x + 11.0, rf0.position.y - 10.0), 16, TINTA)
		var np_i: int = fora_paginas(fo2.size())
		if np_i <= 1:
			_txt("só caem fora da casa", Vector2(rf0.position.x + 11.0 + largura(lblf, 16) + 10.0, rf0.position.y - 10.0), 12, TINTA2)
		else:
			_txt("pág. %d/%d" % [fora_pag + 1, np_i], Vector2(rect_seta_fora(-1).position.x - 58.0, rf0.position.y - 10.0), 12, TINTA2)
			for it_f in itens:
				var id_f: String = it_f["id"]
				if id_f == "pgf_ant" or id_f == "pgf_prox":
					var o_f: Dictionary = {"on": it_f["on"], "foco": foco >= 0 and itens[foco]["id"] == id_f and it_f["on"], "h": UIComum.anim_h(anim, id_f), "p": UIComum.anim_p(anim, id_f), "tam": 15}
					UIComum.botao(self, it_f["r"], "<" if id_f == "pgf_ant" else ">", UIComum.B_OURO, o_f, t)
		for k in range(fora_pag * FORA_POR_PAG, mini(fo2.size(), (fora_pag + 1) * FORA_POR_PAG)):
			_tile(e, fo2[k], rect_tile_fora(k - fora_pag * FORA_POR_PAG))
	# painéis de baixo: como ler o índice (esquerda) e o progresso (direita)
	var pl := Rect2(COL_E_X, 538.0, COL_W, 92.0)
	draw_rect(pl, PAPEL_ESC)
	draw_rect(pl, PAPEL_BORDA, false, 2.0)
	_txt("Como ler o índice", Vector2(pl.position.x + 14.0, pl.position.y + 24.0), 16, TINTA)
	_bloco("Clique numa fantasia para abrir a página dela. Fantasias completas ganham uma estrela dourada; peça que ainda não apareceu fica em silhueta.", Vector2(pl.position.x + 14.0, pl.position.y + 44.0), pl.size.x - 28.0, [13, 12], 3, TINTA2, 2.0)
	var pr := Rect2(COL_D_X, 538.0, COL_W, 92.0)
	draw_rect(pr, PAPEL_ESC)
	draw_rect(pr, PAPEL_BORDA, false, 2.0)
	_txt("Seu progresso", Vector2(pr.position.x + 14.0, pr.position.y + 24.0), 16, TINTA)
	_txt("Gangues do 3º ato: na próxima página", Vector2(pr.position.x + 120.0, pr.position.y + 24.0), 12, TINTA2, pr.size.x - 134.0)
	var comp: int = e.fantasias_completas()
	var nf: int = Pecas.n_ativas()
	var po: int = pecas_obtidas(e)
	var lb: float = (pr.size.x - 28.0 - 14.0) * 0.5
	_barra(Rect2(pr.position.x + 14.0, pr.position.y + 62.0, lb, 16.0), float(comp) / nf, "Completas: %d de %d" % [comp, nf], Color(0.95, 0.72, 0.15))
	_barra(Rect2(pr.position.x + 28.0 + lb, pr.position.y + 62.0, lb, 16.0), float(po) / pecas_possiveis(), "Peças encontradas: %d de %d" % [po, pecas_possiveis()], Color(0.4, 0.7, 0.45))

func _barra(r: Rect2, frac: float, rotulo: String, cor: Color) -> void:
	_txt(rotulo, Vector2(r.position.x, r.position.y - 6.0), 14, TINTA)
	# trilho escuro de cantos cortados; o enchimento anda de célula em célula, com brilho e sombra
	var b := Rect2(_sn(r.position.x), _sn(r.position.y), _sn(r.size.x), maxf(Q * 5.0, _sn(r.size.y)))
	UIComum.forma(self, b, Color(0.25, 0.18, 0.16), Q)
	var w: float = _sn((b.size.x - Q * 2.0) * clampf(frac, 0.0, 1.0))
	if w < Q and frac > 0.0:
		w = Q
	if w >= Q:
		var ih: float = b.size.y - Q * 2.0
		draw_rect(Rect2(b.position.x + Q, b.position.y + Q, w, ih), cor)
		draw_rect(Rect2(b.position.x + Q, b.position.y + Q, w, Q), cor.lightened(0.4))
		draw_rect(Rect2(b.position.x + Q, b.position.y + Q + ih - Q, w, Q), cor.darkened(0.2))

func _tile(e: Estado, c: int, r: Rect2) -> void:
	var n: int = e.pecas_da_fantasia(c)
	var completa: bool = n >= Pecas.SLOTS
	var cor: Color = Pecas.CONJUNTO_COR[c]
	var sobre: bool = foco >= 0 and itens[foco]["id"] == "f%d" % c
	r = Rect2(_sn(r.position.x), _sn(r.position.y), r.size.x, r.size.y)
	draw_rect(Rect2(r.position.x + Q, r.position.y + Q, r.size.x, r.size.y), Color(0, 0, 0, 0.18))
	draw_rect(r, Color(0.98, 0.95, 0.85) if completa else PAPEL_ESC.lightened(0.25))
	# fita colorida no topo, na cor da fantasia
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, Q * 2.0), cor.darkened(0.15))
	_moldura_px(r, Color(0.9, 0.68, 0.1) if completa else PAPEL_BORDA)
	var cab: int = Pecas.CONJUNTO_PECAS[c][0]
	var centro := r.position + Vector2(r.size.x * 0.5, TILE_ICO_Y)
	V.disco(self, centro, 24.0, cor.lerp(PAPEL, 0.7), Q)
	if e.ja_teve(cab):
		Desenho.icone(self, cab, centro, 50.0)
	# nome em até duas linhas
	var aj: Dictionary = ajustar(Pecas.CONJUNTO_NOME[c], [12, 11, 10, 9, 8], r.size.x - 8.0, 2)
	var yy: float = r.position.y + 70.0
	for ln in aj["linhas"]:
		_txt(ln, Vector2(r.position.x + 4.0, yy), aj["tam"], TINTA, r.size.x - 8.0)
		yy += int(aj["tam"]) + 1
	var cc: Color = Color(0.6, 0.38, 0.0) if completa else (TINTA2 if n > 0 else Color(0.55, 0.5, 0.48))
	_txt("%d/%d" % [n, Pecas.SLOTS], Vector2(r.position.x, r.end.y - 5.0), 13, cc, r.size.x)
	if completa:
		_estrela(r.position + Vector2(r.size.x - 14.0, 19.0), COR_OURO)
	if sobre:
		var pu: float = 0.5 + 0.5 * sin(t * 5.0)
		draw_rect(r.grow(3.0), Color(1.0, 0.7, 0.2, 0.55 + 0.4 * pu), false, 3.0)

# ------------------------------------------------------------------ página de fantasia
func _pagina_fantasia(e: Estado, c: int) -> void:
	var cor: Color = Pecas.CONJUNTO_COR[c]
	var n: int = e.pecas_da_fantasia(c)
	var completa: bool = n >= Pecas.SLOTS
	var sala: int = comodo_da_fantasia(c)
	# ---------------- página da esquerda
	_faixa(Rect2(COL_E_X, 76.0, COL_W, 38.0), Pecas.CONJUNTO_NOME[c], [30, 28, 26, 24, 22, 20, 18], cor)
	var cb: Rect2 = _cabine_gato()
	draw_rect(Rect2(cb.position.x + 3, cb.position.y + 4, cb.size.x, cb.size.y), Color(0, 0, 0, 0.16))
	draw_rect(cb, cor.lerp(PAPEL, 0.78))
	# chão da foto
	draw_rect(Rect2(cb.position.x, cb.end.y - 63.0, cb.size.x, 63.0), cor.lerp(PAPEL, 0.55))
	draw_rect(Rect2(cb.position.x, cb.end.y - 63.0, cb.size.x, Q), cor.darkened(0.2).lerp(PAPEL, 0.4))
	_moldura_px(cb, PAPEL_BORDA)
	_cantoneiras(cb, Color(0.3, 0.17, 0.15))
	_txt("Ficha nº %02d" % (pagina), Vector2(cb.position.x + 34.0, cb.position.y + 18.0), 13, TINTA2)
	# o gato: as peças já tidas aqui; as que faltam saem em silhueta pela camada filha
	_gato(self, c, false)
	# quatro marcadores de peça na foto
	for s in Pecas.SLOTS:
		var tp: int = Pecas.CONJUNTO_PECAS[c][s]
		var mk := Rect2(cb.end.x - 22.0 - (3 - s) * 20.0, cb.end.y - 22.0, 14.0, 14.0)
		draw_rect(mk, Color(0.2, 0.12, 0.12))
		draw_rect(mk.grow(-2.0), cor if e.ja_teve(tp) else Color(0.45, 0.4, 0.4))
	_txt("%d/%d peças" % [n, Pecas.SLOTS], Vector2(cb.position.x + 16.0, cb.end.y - 10.0), 14, TINTA)
	if completa:
		_carimbo(Vector2(cb.end.x - 96.0, cb.end.y - 100.0))
	# poder da fantasia completa
	var pb := Rect2(COL_E_X, 392.0, COL_W, 100.0)
	draw_rect(pb, PAPEL_ESC)
	draw_rect(pb, PAPEL_BORDA, false, 2.0)
	_txt("Poder da fantasia completa", Vector2(pb.position.x + 12.0, pb.position.y + 19.0), 13, TINTA2)
	_txt(Pecas.PODER_NOME[c], Vector2(pb.position.x + 12.0, pb.position.y + 42.0), tam_cabe(Pecas.PODER_NOME[c], [22, 20, 18], pb.size.x - 24.0), Color(0.62, 0.34, 0.02))
	# dica em até 2 linhas, no passo de 16 px: a fonte sai em 19, então a 2ª linha não pode descer até a legenda
	_bloco(_maiuscula(Pecas.PODER_DICA[c]) + ", a cada %d s" % int(Balanco.PODER_INTERVALO), Vector2(pb.position.x + 12.0, pb.position.y + 61.0), pb.size.x - 24.0, [14], 2, TINTA, 2.0)
	_txt("Vale com as 4 peças vestidas" if not completa else "Fantasia completa: o poder é seu", Vector2(pb.position.x + 12.0, pb.end.y - 4.0), 12, TINTA2)
	# onde encontrar
	var ob := Rect2(COL_E_X, 500.0, COL_W, 130.0)
	draw_rect(ob, PAPEL_ESC)
	draw_rect(ob, PAPEL_BORDA, false, 2.0)
	draw_rect(Rect2(ob.position.x, ob.position.y, 8.0, ob.size.y), COR_ABA[sala + 1 if sala >= 0 else ABA_FORA].darkened(0.05))
	_txt("Onde encontrar", Vector2(ob.position.x + 18.0, ob.position.y + 19.0), 13, TINTA2)
	var xo: float = ob.position.x + 18.0
	var wo: float = ob.size.x - 30.0
	var yy: float = _bloco(texto_onde(c), Vector2(xo, ob.position.y + 42.0), wo, [18, 16, 15, 14], 2, TINTA, 3.0)
	yy = _bloco(texto_chefe(c), Vector2(xo, yy), wo, [14, 13, 12], 1, Color(0.28, 0.4, 0.42), 3.0)
	var tp: String = texto_provisorio(c)
	if tp != "":
		yy = _bloco(_maiuscula(tp), Vector2(xo, yy), wo, [13, 12], 1, Color(0.55, 0.36, 0.16), 3.0)
	if sala >= 0:
		if comodo_bloqueado(e, sala):
			_cadeado(Vector2(xo + 8.0, yy + 2.0), Color(0.62, 0.22, 0.2))
			yy = _bloco(texto_bloqueio(sala), Vector2(xo + 22.0, yy + 6.0), wo - 22.0, [12], 1, COR_FALTA, 2.0)
	var outras: Array[String] = []
	for o in Fases.CONJUNTOS[sala if sala >= 0 else lugar_de_fora(c)]:
		if o != c:
			outras.append(Pecas.CONJUNTO_NOME[o])
	var linhas_livres: int = clampi(int(floor((ob.end.y - 6.0 - yy) / 14.0)), 1, 2)
	_bloco("Também cai aqui: " + ", ".join(outras), Vector2(xo, yy + 6.0), wo, [12, 11], linhas_livres, TINTA2, 2.0)
	# ---------------- página da direita
	for s in Pecas.SLOTS:
		_linha_peca(e, c, s)
	_bonus(c)

## Última página: a fantasia criada no Ateliê (nome, gato vestido, peças, poder e bônus) ou o convite para abrir o Ateliê.
func _pagina_atelie(e: Estado) -> void:
	var C = Pecas.Conjunto
	var cor: Color = Pecas.CONJUNTO_COR[C.ATELIE]
	var criada: bool = not e.atelie.is_empty()
	var nome: String = str(e.atelie.get("nome", "Ateliê")) if criada else "Ateliê"
	_faixa(Rect2(COL_E_X, 76.0, COL_W, 38.0), nome, [30, 28, 26, 24, 22, 20, 18], cor)
	var cb: Rect2 = _cabine_gato()
	draw_rect(Rect2(cb.position.x + 3, cb.position.y + 4, cb.size.x, cb.size.y), Color(0, 0, 0, 0.16))
	draw_rect(cb, cor.lerp(PAPEL, 0.78))
	draw_rect(Rect2(cb.position.x, cb.end.y - 63.0, cb.size.x, 63.0), cor.lerp(PAPEL, 0.55))
	draw_rect(Rect2(cb.position.x, cb.end.y - 63.0, cb.size.x, Q), cor.darkened(0.2).lerp(PAPEL, 0.4))
	_moldura_px(cb, PAPEL_BORDA)
	_cantoneiras(cb, Color(0.3, 0.17, 0.15))
	_txt("Ficha secreta", Vector2(cb.position.x + 34.0, cb.position.y + 18.0), 13, TINTA2)
	var pr := Rect2(COL_D_X, 122.0, COL_W, 508.0)
	var pb := Rect2(COL_E_X, 392.0, COL_W, 238.0)
	draw_rect(pb, PAPEL_ESC)
	draw_rect(pb, PAPEL_BORDA, false, 2.0)
	if not criada:
		_estrela(cb.get_center() + Vector2(0.0, -20.0), COR_OURO if Atelie.liberado(e) else Color(0.6, 0.55, 0.5))
		_txt("?", Vector2(cb.position.x, cb.get_center().y + 50.0), 40, TINTA2, cb.size.x)
		var msg: String = "Fichário completo! Abra o Ateliê (botão no mapa ou no guarda-roupa) e crie a sua fantasia." if Atelie.liberado(e) else "Complete o fichário para abrir o Ateliê"
		_txt("Fantasia do Ateliê", Vector2(pb.position.x + 12.0, pb.position.y + 24.0), 16, TINTA)
		_bloco(msg, Vector2(pb.position.x + 12.0, pb.position.y + 54.0), pb.size.x - 24.0, [20, 18, 16], 3, Color(0.62, 0.34, 0.02), 4.0)
		_bloco("Lá você escolhe as formas, as cores, a estampa, um poder, um bônus e o nome, dentro de um orçamento de pontos.", Vector2(pb.position.x + 12.0, pb.position.y + 140.0), pb.size.x - 24.0, [14, 13, 12], 3, TINTA2, 3.0)
		_txt("Completas: %d de %d" % [e.fantasias_completas(), Pecas.n_ativas()], Vector2(pb.position.x + 12.0, pb.end.y - 12.0), 14, TINTA2)
		draw_rect(pr, PAPEL_ESC)
		draw_rect(pr, PAPEL_BORDA, false, 2.0)
		_txt("Peças", Vector2(pr.position.x + 12.0, pr.position.y + 24.0), 16, TINTA)
		_txt("Ainda não existem", Vector2(pr.position.x + 12.0, pr.position.y + 54.0), 16, TINTA2)
		return
	# gato vestindo a fantasia criada
	var pecas: Array = []
	for s in Pecas.SLOTS:
		pecas.append(Peca.new(Pecas.Tipo.ATELIE_CABECA + s, 5, Pecas.Raridade.RARA))
	Desenho.boneco(self, _pos_gato(), 3.0, 1.0, 0, pecas, 0.0, t, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, true, 0, false)
	_txt("4/4 peças", Vector2(cb.position.x + 16.0, cb.end.y - 10.0), 14, TINTA)
	var cp: int = Pecas.conj_do_poder(C.ATELIE)
	_txt("Poder da fantasia completa", Vector2(pb.position.x + 12.0, pb.position.y + 19.0), 13, TINTA2)
	_txt(Pecas.PODER_NOME[cp], Vector2(pb.position.x + 12.0, pb.position.y + 44.0), tam_cabe(Pecas.PODER_NOME[cp], [22, 20, 18], pb.size.x - 24.0), Color(0.62, 0.34, 0.02))
	_bloco(_maiuscula(Pecas.PODER_DICA[cp]), Vector2(pb.position.x + 12.0, pb.position.y + 66.0), pb.size.x - 24.0, [14, 13, 12], 3, TINTA, 2.0)
	var recarga: int = int(round(Balanco.PODER_INTERVALO * float(Balanco.PODER_KIT_INTERVALO.get(cp, 1.0)) * Atelie.PODER_RECARGA_FATOR))
	_bloco("Solta a cada %d s, com %d%% da força da fantasia de origem (%s)." % [recarga, int(round(Atelie.PODER_FORCA_FATOR * 100.0)), Pecas.CONJUNTO_NOME[cp]], Vector2(pb.position.x + 12.0, pb.position.y + 134.0), pb.size.x - 24.0, [13, 12, 11], 3, TINTA2, 2.0)
	_txt("Estampa: %s" % Atelie.ESTAMPA_NOME[clampi(int(e.atelie.get("estampa", 0)), 0, Atelie.ESTAMPA_NOME.size() - 1)], Vector2(pb.position.x + 12.0, pb.end.y - 12.0), 14, TINTA2)
	# página da direita: as quatro peças e o bônus
	var ms: Array = e.atelie.get("matizes", [])
	for s in Pecas.SLOTS:
		var r: Rect2 = rect_linha_peca(s)
		var tp: int = Pecas.Tipo.ATELIE_CABECA + s
		var forma: int = Atelie.forma(tp)
		draw_rect(Rect2(r.position.x + 2, r.position.y + 3, r.size.x, r.size.y), Color(0, 0, 0, 0.14))
		draw_rect(r, PAPEL_ESC.lightened(0.2))
		draw_rect(r, cor.darkened(0.25), false, 2.0)
		draw_rect(Rect2(r.position.x, r.position.y, 6.0, r.size.y), cor)
		var cx: Rect2 = _caixa_icone(r)
		draw_rect(cx, Color(0.9, 0.85, 0.72))
		draw_rect(cx, PAPEL_BORDA, false, 2.0)
		Desenho.icone(self, tp, cx.get_center(), 56.0)
		var x: float = r.position.x + 88.0
		var larg: float = r.size.x - 88.0 - 10.0
		var tag: String = Pecas.SLOT_NOME[s]
		var wtag: float = largura(tag, 12)
		_txt(tag, Vector2(r.end.x - 10.0 - wtag, r.position.y + 20.0), 12, TINTA2)
		_txt(cortar(Pecas.NOME[forma], 19, larg - wtag - 10.0), Vector2(x, r.position.y + 24.0), 19, TINTA)
		_bloco(_maiuscula(Pecas.dica(forma)), Vector2(x, r.position.y + 43.0), larg, [13, 12, 11], 2, TINTA2, 2.0)
		var mz: int = int(ms[s]) if s < ms.size() else 0
		_txt("Cor: %s" % Atelie.MATIZ_NOME[clampi(mz, 0, Atelie.MATIZ_NOME.size() - 1)], Vector2(x, r.end.y - 8.0), 13, COR_TEM)
	var bx := Rect2(COL_D_X, 474.0, COL_W, 156.0)
	draw_rect(bx, PAPEL_ESC)
	draw_rect(bx, PAPEL_BORDA, false, 2.0)
	draw_rect(Rect2(bx.position.x, bx.position.y, bx.size.x, 5.0), cor.darkened(0.15))
	var cbn: int = Pecas.conj_do_bonus(C.ATELIE)
	_txt("Bônus: %s" % Pecas.CONJUNTO_NOME[cbn], Vector2(bx.position.x + 12.0, bx.position.y + 24.0), 16, TINTA)
	var y: float = bx.position.y + 44.0
	for g in [["2 ou 3 peças", 1], ["4 peças", 2]]:
		_txt(g[0] + ":", Vector2(bx.position.x + 12.0, y), 14, Color(0.62, 0.34, 0.02))
		y = _bloco(_maiuscula(Pecas.conjunto_bonus(C.ATELIE, g[1])), Vector2(bx.position.x + 24.0, y + 17.0), bx.size.x - 36.0, [14, 13, 12, 11], 2, TINTA, 2.0) + 4.0

func _carimbo(centro: Vector2) -> void:
	var f: Font = UIComum.FONTE
	if carimbo_t < 0.0:
		return   # ainda não bateu
	var pul: float = 1.0 + 0.03 * sin(t * 3.0)
	if carimbo_t < 0.25:
		pul = 1.0 + 2.2 * pow(1.0 - carimbo_t / 0.25, 2.0)   # desce de grande e bate
	UIComum.trans(self, centro, -0.2, Vector2(pul, pul))
	var w: float = largura("COMPLETA", 28) + 22.0
	var r := Rect2(-w * 0.5, -22.0, w, 40.0)
	var tinta := Color(0.78, 0.12, 0.12, 0.9)
	draw_rect(r, Color(1, 1, 1, 0.35))
	draw_rect(r, tinta, false, 4.0)
	draw_rect(r.grow(-6.0), tinta, false, 1.5)
	draw_string(f, Vector2(-w * 0.5 + 11.0, 9.0), "COMPLETA", HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(28), tinta)
	UIComum.trans_fim(self)

func _linha_peca(e: Estado, c: int, s: int) -> void:
	var tp: int = Pecas.CONJUNTO_PECAS[c][s]
	var cor: Color = Pecas.CONJUNTO_COR[c]
	var r: Rect2 = rect_linha_peca(s)
	var pos: Dictionary = posse(e, tp)
	var tem: bool = pos["n"] > 0
	var teve: bool = e.ja_teve(tp)
	draw_rect(Rect2(r.position.x + 2, r.position.y + 3, r.size.x, r.size.y), Color(0, 0, 0, 0.14))
	draw_rect(r, PAPEL_ESC.lightened(0.2) if teve else PAPEL_ESC)
	draw_rect(r, cor.darkened(0.25) if teve else PAPEL_BORDA, false, 2.0)
	draw_rect(Rect2(r.position.x, r.position.y, 6.0, r.size.y), cor if teve else Color(0.5, 0.45, 0.42))
	var cx: Rect2 = _caixa_icone(r)
	draw_rect(cx, Color(0.9, 0.85, 0.72) if teve else Color(0.78, 0.72, 0.62))
	draw_rect(cx, PAPEL_BORDA, false, 2.0)
	var melhor: Peca = pos["melhor"]
	if teve:
		if melhor != null:
			Desenho.icone(self, tp, cx.get_center(), 56.0, melhor.nivel, 0.0, t, melhor.marcas, melhor.raridade)
		else:
			Desenho.icone(self, tp, cx.get_center(), 56.0)
	else:
		# interrogação num selo no canto da caixa (o ícone em silhueta vem da camada filha)
		var sc: Vector2 = cx.position + Vector2(cx.size.x - 6.0, 8.0)
		V.disco_c(self, sc, 7.0, Color(0.62, 0.2, 0.2), Color(0.25, 0.08, 0.08), Q)
		_txt("?", Vector2(_sn(sc.x) - 9.0, _sn(sc.y) + 8.0), 16, Color.WHITE, 21.0)
	var x: float = r.position.x + 88.0
	var larg: float = r.size.x - 88.0 - 10.0
	var tag: String = Pecas.SLOT_NOME[s]
	var wtag: float = largura(tag, 12)
	_txt(tag, Vector2(r.end.x - 10.0 - wtag, r.position.y + 20.0), 12, TINTA2)
	_txt(cortar(Pecas.NOME[tp], 19, larg - wtag - 10.0), Vector2(x, r.position.y + 24.0), 19, TINTA if teve else Color(0.3, 0.22, 0.2))
	_bloco(_maiuscula(Pecas.dica(tp)), Vector2(x, r.position.y + 43.0), larg, [13, 12, 11], 2, TINTA2 if teve else Color(0.5, 0.42, 0.38), 2.0)
	# estado
	var txt: String = ""
	var cs: Color = COR_FALTA
	if tem:
		txt = "Tem agora ×%d" % pos["n"]
		if melhor != null:
			txt += "  ·  melhor: %s" % Pecas.RARIDADE_NOME[melhor.raridade].to_lower()
			if melhor.nivel > 0:
				txt += ", nível %d" % melhor.nivel
		cs = COR_TEM
	elif teve:
		txt = "Já teve (não tem agora)"
		cs = COR_TEVE
	else:
		txt = "Falta: ainda não apareceu"
	var ty: float = r.end.y - 8.0
	var tam_s: int = tam_cabe(txt, [14, 13, 12, 11], larg - 20.0)
	_bolinha(Vector2(x, ty - 13.0), cs, tem or teve)
	_txt(txt, Vector2(x + 18.0, ty), tam_s, cs)

func _bonus(c: int) -> void:
	var cor: Color = Pecas.CONJUNTO_COR[c]
	var bx := Rect2(COL_D_X, 474.0, COL_W, 156.0)
	draw_rect(bx, PAPEL_ESC)
	draw_rect(bx, PAPEL_BORDA, false, 2.0)
	draw_rect(Rect2(bx.position.x, bx.position.y, bx.size.x, 5.0), cor.darkened(0.15))
	_txt("Bônus de fantasia", Vector2(bx.position.x + 12.0, bx.position.y + 24.0), 16, TINTA)
	var y: float = bx.position.y + 44.0
	var grupos: Array = [["2 ou 3 peças", 1], ["4 peças", 2]]
	for g in grupos:
		_txt(g[0] + ":", Vector2(bx.position.x + 12.0, y), 14, Color(0.62, 0.34, 0.02))
		y = _bloco(_maiuscula(Pecas.conjunto_bonus(c, g[1])), Vector2(bx.position.x + 24.0, y + 17.0), bx.size.x - 36.0, [14, 13, 12, 11], 2, TINTA, 2.0) + 4.0

# ------------------------------------------------------------------ o gato e a camada de silhuetas
## Desenha o gato da fantasia `c`. Na camada principal vão as peças que o jogador já teve;
## na camada de silhueta (`so_faltam`), o gato fica invisível e só as peças que faltam aparecem.
func _gato(alvo: CanvasItem, c: int, so_faltam: bool) -> void:
	var pecas: Array = []
	for s in Pecas.SLOTS:
		var tp: int = Pecas.CONJUNTO_PECAS[c][s]
		var teve: bool = estado.ja_teve(tp)
		pecas.append(Peca.new(tp) if teve != so_faltam else null)
	var ciclo: float = fmod(t, PATADA_CADA)
	var golpe: float = ciclo if ciclo < PATADA_DUR else 0.0
	Desenho.boneco(alvo, _pos_gato(), _esc_gato(c), 1.0, 0, pecas, 0.0, t, golpe <= 0.0, golpe, 0.0 if so_faltam else 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, posmod(c, Desenho.PELAGENS.size()))

## Escala do gato da página: as fantasias de monstro (cauda, mandíbulas, asas) passam da moldura no tamanho de sempre; encolhe só o bastante
## para o conjunto das 4 peças caber na foto (largura e altura), sem mexer nas fantasias que já cabem.
func _esc_gato(c: int) -> float:
	var cb: Rect2 = _cabine_gato()
	var meia: float = 12.0   # o corpo do gato
	var alto: float = 24.0
	for s in Pecas.SLOTS:
		var tp: int = Pecas.CONJUNTO_PECAS[c][s]
		var o: Vector2 = RoupaGato.origem(RoupaGato.onde(tp), 0)
		var bx: Rect2 = Desenho.caixa_peca(tp)
		var ini: Vector2 = o + bx.position
		var fim: Vector2 = o + bx.end
		meia = maxf(meia, maxf(absf(ini.x), absf(fim.x)))
		alto = maxf(alto, -ini.y)
	var k: float = Desenho.GATO_K
	var por_larg: float = (cb.size.x - 24.0) * 0.5 / (meia * k)
	var por_alt: float = (cb.size.y - 44.0 - 34.0) / (alto * k)
	return clampf(minf(GATO_ESC, minf(por_larg, por_alt)), 1.6, GATO_ESC)

func _desenhar_silhuetas() -> void:
	if not aberta or estado == null:
		return
	for j in _jobs:
		if j["k"] == "bicho":
			_bicho(_sil, entradas()[int(j["i"])], j["pos"], float(j["esc"]), true)
		elif j["k"] == "icone":
			Desenho.icone(_sil, j["tipo"], j["centro"], j["tam"])
		elif j["k"] == "gato" and not (j["faltam"] as Array).is_empty():
			_gato(_sil, j["c"], true)


# ------------------------------------------------------------------ aba "Metas"
func _selo_meta(c: Vector2, txt: String, cor: Color, tam: int = 13) -> void:
	UIComum.trans(self, c, -0.16)
	var w: float = largura(txt, tam) + 12.0
	var h: float = tam + 9.0
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), Color(cor.r, cor.g, cor.b, 0.1))
	draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), cor, false, 2.0 if tam >= 13 else 1.5)
	_txt(txt, Vector2(-w * 0.5, tam * 0.4 + 0.5), tam, cor, w)
	UIComum.trans_fim(self)

func _premio(m: Dictionary, direita: float, y: float, feita: bool) -> void:
	_trofeu(Vector2(direita - 39.0, y), feita)
	_txt("+%d" % int(m["premio"]), Vector2(direita - 28.0, y + 5.0), 15, COR_TEVE if feita else TINTA2)

## Uma linha de meta da página esquerda; devolve o y da próxima.
func _linha_meta(e: Estado, m: Dictionary, y: float, trancada: bool) -> float:
	var feita: bool = e.metas_pagas.has(m["id"])
	var r := Rect2(COL_E_X, y, COL_W, 32.0)
	draw_rect(r, Color(0.86, 0.95, 0.8) if feita else PAPEL_ESC.lightened(0.25))
	draw_rect(r, COR_TEM if feita else PAPEL_BORDA, false, 1.5 if feita else 1.0)
	var xt: float = r.position.x + 10.0
	if trancada:
		_cadeado(Vector2(r.position.x + 16.0, y + 16.0), Color(0.45, 0.32, 0.3))
		xt += 14.0
	_txt(cortar(m["nome"], 15, 240.0), Vector2(xt, y + 14.0), 15, TINTA2 if trancada else TINTA)
	if metas_novas.has(m["id"]):
		_txt("NOVA", Vector2(r.position.x + 270.0, y + 13.0), 11, Color(0.85, 0.15, 0.15))
		draw_rect(r.grow(2.0), Color(1.0, 0.8, 0.2, 0.5 + 0.5 * sin(t * 6.0)), false, 3.0)
	var det: String = "Vença a campanha para liberar" if trancada else str(m["texto"])
	_txt(cortar(det, 11, 285.0), Vector2(xt, y + 27.0), 11, TINTA2)
	_premio(m, r.end.x - 90.0, y + 16.0, feita)
	if feita:
		_selo_meta(Vector2(r.end.x - 34.0, y + 16.0), "FEITA", COR_TEM)
	else:
		_txt("pendente" if not trancada else "trancada", Vector2(r.end.x - 72.0, y + 20.0), 11, TINTA2, 66.0)
	return y + 34.0

## Segunda dupla de folhas das Metas: as metas do lado de fora e o andamento de cada lugar.
func _metas_fora(e: Estado, todas: Array) -> void:
	var ms: Array = todas.filter(func(m: Dictionary) -> bool: return m["grupo"] == "Lado de fora")
	var feitas: int = 0
	for m in ms:
		if e.metas_pagas.has(m["id"]):
			feitas += 1
	var y: float = 120.0
	_emblema_grupo("Lado de fora", Vector2(COL_E_X, y))
	_txt("Lado de fora  ·  %d/%d" % [feitas, ms.size()], Vector2(COL_E_X + 27.0, y + 17.0), 16, TINTA)
	y += 24.0
	for m in ms:
		y = _linha_meta(e, m, y, false)
	# página direita: os cinco lugares, com a situação no 2º ato e o recorde da invasão
	_faixa(Rect2(COL_D_X, 76.0, COL_W, 34.0), "Lugares de fora  ·  %d/%d vencidos no 2º ato" % [e.vencidos_no_ato(2), Fases.TOTAL], [17, 16, 15, 14, 13], Color(1.0, 0.94, 0.7))
	var yy: float = 124.0
	for i in Fases.TOTAL:
		var li: int = i + Fases.TOTAL
		var feito: bool = e.vencido[i] >= 2
		var r := Rect2(COL_D_X, yy, COL_W, 56.0)
		draw_rect(r, Color(0.86, 0.95, 0.8) if feito else PAPEL_ESC.lightened(0.25))
		draw_rect(r, COR_TEM if feito else PAPEL_BORDA, false, 1.5 if feito else 1.0)
		draw_rect(Rect2(r.position.x, r.position.y, 5.0, r.size.y), COR_ABA[ABA_METAS].darkened(0.1))
		_txt(Fases.NOME[li], Vector2(r.position.x + 14.0, yy + 24.0), 20, TINTA, 180.0)
		_txt("Chefe: " + Fases.CHEFE_NOME[li], Vector2(r.position.x + 14.0, yy + 44.0), 13, TINTA2, 250.0)
		if feito:
			_selo_meta(Vector2(r.end.x - 40.0, yy + 18.0), "FEITO", COR_TEM)
			var rec: int = e.recordes[li]
			_txt(("Invasão: onda %d" % rec) if rec > 0 else "Invasão: sem recorde", Vector2(r.end.x - 195.0, yy + 44.0), 13, TINTA2, 160.0)
		else:
			_txt("falta", Vector2(r.end.x - 60.0, yy + 24.0), 14, TINTA2, 50.0)
		yy += 62.0
	# as ruas do 3º ato, em linhas mais baixas por baixo dos lugares de fora
	yy += 2.0
	_txt("Ruas do bairro  ·  %d/%d vencidas no 3º ato" % [e.vencidos_no_ato(3), Fases.TOTAL] + ((" · Invasão: onda %d" % e.recordes[Fases.TOTAL * 2]) if e.recordes[Fases.TOTAL * 2] > 0 else (" · Invasão: sem recorde" if e.tudo_vencido() else "")), Vector2(COL_D_X + 6.0, yy + 12.0), 15, TINTA)
	yy += 20.0
	for i in Fases.TOTAL:
		var li3: int = i + Fases.TOTAL * 2
		var feito3: bool = e.vencido[i] >= 3
		var r3 := Rect2(COL_D_X, yy, COL_W, 32.0)
		draw_rect(r3, Color(0.86, 0.95, 0.8) if feito3 else PAPEL_ESC.lightened(0.25))
		draw_rect(r3, COR_TEM if feito3 else PAPEL_BORDA, false, 1.5 if feito3 else 1.0)
		draw_rect(Rect2(r3.position.x, r3.position.y, 5.0, r3.size.y), Fases.GANGUE_COR[i])
		_txt(cortar(Fases.nome_do_lugar(li3), 16, 172.0), Vector2(r3.position.x + 14.0, yy + 21.0), 16, TINTA)
		_txt(cortar("Chefe: " + Fases.nome_do_chefe(li3), 13, 175.0), Vector2(r3.position.x + 196.0, yy + 20.0), 13, TINTA2)
		if feito3:
			_selo_meta(Vector2(r3.end.x - 40.0, yy + 16.0), "FEITO", COR_TEM)
		elif not e.lugar_aberto(3, i + 1):
			_txt("fechado", Vector2(r3.end.x - 66.0, yy + 21.0), 13, TINTA2)
		else:
			_txt("falta", Vector2(r3.end.x - 50.0, yy + 21.0), 14, TINTA2)
		yy += 35.0

func _pagina_metas(e: Estado) -> void:
	var todas: Array = Metas.lista()
	var ganhos: int = 0
	for m in todas:
		if e.metas_pagas.has(m["id"]):
			ganhos += int(m["premio"])
	ganhos_exib = UIComum.contar(ganhos_exib, float(ganhos), get_process_delta_time())
	_faixa(Rect2(COL_E_X, 76.0, COL_W, 34.0), "Metas: %d de %d  ·  troféus ganhos com metas: %d" % [e.metas_cumpridas(), todas.size(), int(round(ganhos_exib))], [17, 16, 15, 14, 13, 12], COR_OURO)
	if metas_pag == 1:
		_metas_fora(e, todas)
		return
	var zerada: bool = e.campanha_vencida()
	# página esquerda: Campanha, Guarda-roupa e Invasão
	var y: float = 120.0
	for g in ["Campanha", "Guarda-roupa", "Invasão"]:
		var ms: Array = todas.filter(func(m: Dictionary) -> bool: return m["grupo"] == g)
		var feitas: int = 0
		for m in ms:
			if e.metas_pagas.has(m["id"]):
				feitas += 1
		_emblema_grupo(g, Vector2(COL_E_X, y))
		_txt("%s  ·  %d/%d" % [g, feitas, ms.size()], Vector2(COL_E_X + 27.0, y + 17.0), 16, TINTA)
		y += 24.0
		for m in ms:
			y = _linha_meta(e, m, y, g == "Invasão" and not zerada)
		y += 6.0
	# página direita: as fantasias em duas colunas (são 42 desde a expansão: numa coluna só a lista vazava
	# da página). O prêmio é o mesmo para todas, então vai na faixa do título e não em cada linha.
	var fs: Array = todas.filter(func(m: Dictionary) -> bool: return m["grupo"] == "Fantasias")
	var nf: int = 0
	for m in fs:
		if e.metas_pagas.has(m["id"]):
			nf += 1
	var premio_f: int = int(fs[0]["premio"]) if not fs.is_empty() else 0
	_faixa(Rect2(COL_D_X, 76.0, COL_W, 34.0), "Fantasias  ·  %d/%d  ·  +%d troféus cada" % [nf, fs.size(), premio_f], [17, 16, 15, 14, 13], Color(1.0, 0.94, 0.7))
	var por_col: int = ceili(fs.size() / 2.0)
	var larg_c: float = floorf(COL_W * 0.5) - 3.0
	for k in fs.size():
		var m: Dictionary = fs[k]
		var feita2: bool = e.metas_pagas.has(m["id"])
		var c: int = int(String(m["id"]).substr(9))
		var yy: float = 118.0 + (k % por_col) * 22.0
		var r2 := Rect2(COL_D_X + (k / por_col) * (larg_c + 6.0), yy, larg_c, 20.0)
		draw_rect(r2, Color(0.86, 0.95, 0.8) if feita2 else PAPEL_ESC.lightened(0.25))
		draw_rect(r2, COR_TEM if feita2 else PAPEL_BORDA, false, 1.5 if feita2 else 1.0)
		draw_rect(Rect2(r2.position.x, r2.position.y, 5.0, r2.size.y), Pecas.CONJUNTO_COR[c].darkened(0.1))
		_txt(UIComum.caber(Pecas.CONJUNTO_NOME[c], 13, larg_c - 62.0), Vector2(r2.position.x + 11.0, yy + 15.0), 13, TINTA)
		if metas_novas.has(m["id"]):
			draw_rect(r2.grow(2.0), Color(1.0, 0.8, 0.2, 0.5 + 0.5 * sin(t * 6.0)), false, 2.0)
		if feita2:
			_selo_meta(Vector2(r2.end.x - 26.0, yy + 10.0), "FEITA", COR_TEM, 11)
		else:
			_txt("%d/%d" % [e.pecas_da_fantasia(c), Pecas.SLOTS], Vector2(r2.end.x - 46.0, yy + 15.0), 13, TINTA2, 40.0)


# ------------------------------------------------------------------ aba "Bichos" (bestiário)
# Ordem das entradas: 5 famílias, 5 bandos de fora, 9 tipos + o fantasiado, 10 chefes (30, ver Estado.BICHOS_TOTAL).
const FAM_ENFRENTAR: Array[String] = [
	"Sem truques e sem pressa: gatos na frente seguram o bando enquanto os de trás atacam.",
	"Aguentam muito dano e andam devagar: atacar de longe dá tempo de sobra, e dano alto compensa a vida.",
	"Vêm rápidas e caem rápido: gatos na linha da frente não deixam passar, e Recuar guarda a torre.",
	"Bicam forte, mas caem fácil: derrube os corvos antes de chegarem aos gatos.",
	"Regeneram o tempo todo: concentre o dano no mesmo sapo, sem espalhar golpes.",
]
const BANDO_ENFRENTAR := "Misturam todas as famílias: monte um time que sirva para tudo, com gatos fortes na frente e dano de longe atrás."
const TIPO_ENFRENTAR: Array[String] = [
	"Sem truque: qualquer gato na frente resolve. Fique de olho nos fantasiados no meio do bando.",
	"Pula por cima dos gatos: deixe um gato em Recuar perto da torre para pegá-lo.",
	"Marque o Ladrão como alvo na preparação e deixe gatos na linha da frente.",
	"Muita vida: dano alto e poderes ajudam. Marque-o como alvo para o time inteiro focar.",
	"Cada Ninhada vira dois filhotes ao cair: golpes em área resolvem rápido.",
	"Atira de longe: gatos em Avançar o alcançam. Marque-o como alvo.",
	"Cura os outros: derrube-o primeiro, marcando-o como alvo.",
	"Leva pouco dano e atrai os golpes: a Varinha ignora a defesa dele.",
	"Explode ao encostar: derrube de longe antes que chegue aos gatos ou à torre.",
	"Larga uma peça da fantasia que veste: vale a pena derrubá-lo.",
]
const FANTASIADO_OQUE := "Um bicho comum vestido com uma fantasia do lugar. Também usa os bônus dela. Com a fantasia completa, solta o poder dela, com aviso: atordoe para cancelar."
const BICHO_RETRATO_ESC := 1.45

static var _entradas_c: Array = []

static func entradas() -> Array:
	if not _entradas_c.is_empty():
		return _entradas_c
	var l: Array = []
	for i in Fases.TOTAL:
		l.append({"k": "fam", "i": i, "chave": "f%d" % i, "nome": Fases.FAMILIA_NOME[i], "cor": Desenho.COR_FAM[i],
			"oque": Fases.FAMILIA_DICA[i], "dica": FAM_ENFRENTAR[i],
			"ficha": ["Vida ×%s  ·  Velocidade ×%s  ·  Dano ×%s" % [_n(Fases.FAMILIA_VIDA[i]), _n(Fases.FAMILIA_VEL[i]), _n(Fases.FAMILIA_DANO[i])], "Chefe da família: " + Fases.CHEFE_NOME[i]],
			"onde": "Vive %s. Fora da casa, aparece misturada nos bandos." % _em(i)})
	for k in Fases.TOTAL:
		var lg: int = k + Fases.TOTAL
		l.append({"k": "bando", "i": k, "chave": "b%d" % k, "nome": Fases.FAMILIA_NOME[lg], "cor": Desenho.COR_FAM[k],
			"oque": Fases.FAMILIA_DICA[lg], "dica": BANDO_ENFRENTAR,
			"ficha": ["Chefe: " + Fases.CHEFE_NOME[lg], "Mais forte que os bichos da casa"],
			"onde": "Só no segundo ato, %s." % _em(lg)})
	for t in Balanco.TIPO_NOMES.size():
		l.append({"k": "tipo", "i": t, "chave": "t%d" % t, "nome": Balanco.TIPO_NOMES[t], "cor": Desenho.COR_TIPO[t],
			"oque": Campo.TIPO_DICA[t], "dica": TIPO_ENFRENTAR[t],
			"ficha": ["Vida ×%s  ·  Velocidade ×%s" % [_n(Balanco.TIPO_VIDA[t]), _n(Balanco.TIPO_VEL[t])], "Tamanho ×%s" % _n(Balanco.TIPO_ESCALA[t])],
			"onde": _onde_tipo(t)})
	l.append({"k": "tipo", "i": 9, "chave": "t9", "nome": "Fantasiado", "cor": Desenho.DOURADO,
		"oque": FANTASIADO_OQUE, "dica": TIPO_ENFRENTAR[9],
		"ficha": ["Larga uma peça da fantasia e dá %d troféu" % Torre.TROFEU_ELITE, "Tamanho ×%s" % _n(Balanco.ELITE_ESCALA)],
		"onde": "Em toda luta a partir da onda %d de cada lugar." % Balanco.ELITE_ONDA_MIN})
	for i in Fases.CHEFE_NOME.size():
		var vest: Array = []
		for c in Fases.lista_do_lugar(i):
			vest.append(Pecas.CONJUNTO_NOME[c])
		l.append({"k": "chefe", "i": i, "chave": "c%d" % i, "nome": Fases.CHEFE_NOME[i], "cor": Desenho.COR_CHEFES[i],
			"oque": Fases.CHEFE_ATAQUE[i] + ". Solta o poder com aviso de %d s: atordoe o chefe para cancelar." % int(Balanco.PODER_AVISO_T), "dica": Fases.CHEFE_FRAQUEZA[i],
			"ficha": ["Larga uma peça Rara ou Lendária e dá %d troféus" % Torre.TROFEU_CHEFE, "Veste: " + ", ".join(vest)],
			"onde": "Última onda %s%s." % [_do(i), "" if i < Fases.TOTAL else " (segundo ato)"]})
	for g in Fases.GANGUE_NOME.size():
		var lg3: int = g + Fases.TOTAL * 2
		l.append({"k": "gangue", "i": g, "chave": "g%d" % g, "nome": Fases.GANGUE_NOME[g], "cor": Fases.GANGUE_COR[g].lerp(Color(0.6, 0.5, 0.45), 0.25),
			"oque": texto_truque(g), "dica": GANGUE_ENFRENTAR[g], "ficha": [],
			"onde": "Só no terceiro ato: %s." % _em(lg3)})
	_entradas_c = l
	return l

const GANGUE_TRUQUE_NOME: Array[String] = ["A oferta", "Comboio", "Recompilação e discos", "Falange", "Mutação"]
const GANGUE_ENFRENTAR: Array[String] = [
	"Marque o Mensageiro como alvo e derrube-o antes que toque a torre. Gatos na frente seguram os Capangas.",
	"Derrube o Guitarrista primeiro: sem ele o comboio perde a velocidade. Gatos de longe acertam os Suicidas antes que cheguem.",
	"O Programa volta uma vez: guarde dano para o segundo round. Derrube os Lançadores antes que os discos quiquem entre os gatos.",
	"Ataque os hoplitas pelos flancos ou com poderes que atravessam, e derrube o líder para abalar a gangue inteira.",
	"Termine os mutantes feridos de uma vez: abaixo de 30% de vida eles ficam mais fortes. Dano concentrado vence.",
]

## Texto do truque da gangue `g`, com os números do Balanco.
static func texto_truque(g: int) -> String:
	match g:
		0:
			return "O Mensageiro não rouba bloco: ao tocar a torre, leva um gato para dormir com os peixes por %d s. Matá-lo antes cancela." % int(Balanco.OFERTA_T)
		1:
			return "O Guitarrista dá +%d%% de velocidade aos rivais em volta (o comboio), e o Suicida pintado corre ao primeiro gato ou à torre e explode." % int(round(Balanco.COMBOIO_VEL * 100.0))
		2:
			return "O Programa volta uma vez com %d%% de vida ao ser derrotado, e o disco do Lançador quica em até %d gatos." % [int(round(Balanco.RECOMPILA_VIDA * 100.0)), Balanco.DISCO_QUICAS + 1]
		3:
			return "Hoplitas lado a lado levam menos dano de frente (%d%% por vizinho, até %d). Golpes pelos flancos e poderes que atravessam furam a falange." % [int(round(Balanco.FALANGE_POR_VIZINHO * 100.0)), Balanco.FALANGE_MAX]
	return "Abaixo de %d%% de vida, o mutante ganha +%d%% de dano e de velocidade. O Telepata atira de longe nos gatos e na torre." % [int(round(Balanco.MUTACAO_LIMIAR * 100.0)), int(round(Balanco.MUTACAO_DANO * 100.0))]

## Tipos de rival da gangue `g` na ordem da ficha: o comum primeiro, depois os da tabela da gangue.
static func tipos_da_gangue(g: int) -> Array[int]:
	var l: Array[int] = [0]
	for par in Balanco.GANGUE_TIPOS[g]:
		l.append(int(par[0]))
	return l

## Peças do lugar que o rival do retrato veste (cabeça, corpo e mão da primeira fantasia do lugar).
static func _pecas_rival(g: int) -> Array:
	var c: int = Fases.CONJUNTOS[g + Fases.TOTAL * 2][0]
	return [Peca.new(Pecas.CONJUNTO_PECAS[c][0]), Peca.new(Pecas.CONJUNTO_PECAS[c][1]), null, null]

static func _n(v: float) -> String:
	return ("%.2f" % v).rstrip("0").rstrip(".")

## "do Quarto", "da Sala"...
static func _do(i: int) -> String:
	return ("da " if i in [1, 2, 6, 8, 9] else "do ") + Fases.NOME[i]

static func _onde_tipo(t: int) -> String:
	if t == 0:
		return "Em todo lugar, desde a primeira onda."
	var p: int = Balanco.TIPO_PROG_MIN[t]
	var fase: int = maxi(1, int(ceil((p - Balanco.ONDAS_TOTAIS) / float(Balanco.PROG_POR_FASE))) + 1)
	if fase > Fases.TOTAL:
		return "Só no segundo ato, lá fora."
	return "A partir de %s, onda %d." % [Fases.NOME[fase - 1], p - (fase - 1) * Balanco.PROG_POR_FASE]

static func _derrotado(e: Estado, en: Dictionary) -> bool:
	if en["k"] == "gangue":
		return e.vencido[int(en["i"])] >= 3   # chefe da gangue vencido (3º ato do lugar)
	if en["k"] != "chefe":
		return false
	var i: int = int(en["i"])
	return e.vencido[i] >= 1 if i < Fases.TOTAL else e.vencido[i - Fases.TOTAL] >= 2

## Posição da miniatura da k-ésima entrada no índice do bestiário.
static func rect_tile_bicho(k: int) -> Rect2:
	var x0: float = 0.0
	var y0: float = 0.0
	if k >= BICHOS_CASA:   # gangues do 3º ato: fileira de cima da segunda página de índice
		x0 = COL_E_X + (k - BICHOS_CASA) * (TILE_W + TILE_GAP)
		y0 = IDX_Y0 + 24.0
	elif k < 5:          # famílias: fileira de cima, página esquerda
		x0 = COL_E_X + k * (TILE_W + TILE_GAP)
		y0 = IDX_Y0 + 24.0
	elif k < 10:       # bandos de fora: fileira de baixo, página direita
		x0 = COL_D_X + (k - 5) * (TILE_W + TILE_GAP)
		y0 = IDX_Y0 + 2 * IDX_PASSO + 24.0
	elif k < 20:       # tipos: duas fileiras, página esquerda
		var j: int = k - 10
		x0 = COL_E_X + (j % 5) * (TILE_W + TILE_GAP)
		y0 = IDX_Y0 + IDX_PASSO + 24.0 + (j / 5) * 112.0
	else:              # chefes: duas fileiras, página direita
		var j2: int = k - 20
		x0 = COL_D_X + (j2 % 5) * (TILE_W + TILE_GAP)
		y0 = IDX_Y0 + 24.0 + (j2 / 5) * IDX_PASSO
	return Rect2(_sn(x0), _sn(y0), TILE_W, TILE_H)

## Desenha o bicho da entrada com os pés em `pe` (a camada de silhueta pinta tudo escuro).
func _bicho(alvo: CanvasItem, en: Dictionary, pe: Vector2, esc: float, _sil_: bool) -> void:
	var vazio: Array = [null, null, null, null]
	var an: float = t * 2.0 + int(en["i"])
	var i: int = int(en["i"])
	match String(en["k"]):
		"gangue":
			Desenho.boneco(alvo, pe, esc, -1.0, 1, _pecas_rival(i), 0.0, an, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, i + Fases.TOTAL * 2, false, -1, false, false, 0, false, i)
		"fam":
			Desenho.boneco(alvo, pe, esc, -1.0, 1, vazio, 0.0, an, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, i, false, -1)
		"bando":
			Desenho.boneco(alvo, pe, esc, -1.0, 1, vazio, 0.0, an, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, i + Fases.TOTAL, false, -1)
		"tipo":
			var pecas: Array = vazio
			var tp: int = i
			var eli: bool = false
			if i == 9:
				tp = 0
				eli = true
				pecas = []
				for s in Pecas.SLOTS:
					pecas.append(Peca.new(Pecas.CONJUNTO_PECAS[Pecas.Conjunto.CAVALEIRO][s]))
			Desenho.boneco(alvo, pe, esc * lerpf(1.0, Balanco.TIPO_ESCALA[tp], 0.5), -1.0, 1, pecas, 0.0, an, false, 0.0, 1.0, false, -1, 0.0, tp, false, false, 0, eli, -1)
		"chefe":
			var vest: Array = []
			for s in Pecas.SLOTS:
				vest.append(Peca.new(Pecas.CONJUNTO_PECAS[Fases.CONJUNTOS[i][0]][s]))
			Desenho.boneco(alvo, pe, esc * Balanco.CHEFE_ESCALA_TIPO[i], -1.0, 1, vest, 0.0, an, false, 0.0, 1.0, false, -1, 0.0, 0, false, true, i, false, i)

## Escala do bicho numa miniatura.
static func _esc_mini(en: Dictionary) -> float:
	return 0.5 if en["k"] != "chefe" else 0.27

func _montar_bichos() -> void:
	var lista: Array = entradas()
	if pagina <= 1:
		for k in range(0 if pagina == 0 else BICHOS_CASA, BICHOS_CASA if pagina == 0 else lista.size()):
			var r: Rect2 = rect_tile_bicho(k)
			itens.append({"id": "b%d" % k, "r": r, "on": true})
			if lista[k]["k"] != "gangue" and not estado.viu_bicho(lista[k]["chave"]):
				_jobs.append({"k": "bicho", "i": k, "pos": r.position + Vector2(TILE_W * 0.5, TILE_H - 40.0), "esc": _esc_mini(lista[k])})
	else:
		var k2: int = pagina - BICHOS_PAG_INDICE
		if not estado.viu_bicho(lista[k2]["chave"]):
			var cb: Rect2 = _cabine_gato()
			_jobs.append({"k": "bicho", "i": k2, "pos": Vector2(cb.get_center().x, cb.end.y - 44.0), "esc": BICHO_RETRATO_ESC * (0.85 if lista[k2]["k"] == "chefe" else 1.0)})

func _rotulo_bichos(txt: String, r0: Rect2, cor: Color, extra: String = "") -> void:
	draw_rect(Rect2(r0.position.x, r0.position.y - 24.0, 5.0, 16.0), cor.darkened(0.1))
	_txt(txt, Vector2(r0.position.x + 11.0, r0.position.y - 10.0), 16, TINTA)
	if extra != "":
		_txt(extra, Vector2(r0.position.x + 11.0 + largura(txt, 16) + 10.0, r0.position.y - 10.0), 12, TINTA2)

func _tile_bicho(e: Estado, k: int) -> void:
	var en: Dictionary = entradas()[k]
	var r: Rect2 = rect_tile_bicho(k)
	var viu: bool = e.viu_bicho(en["chave"])
	var der: bool = _derrotado(e, en)
	var cor: Color = en["cor"]
	var sobre: bool = foco >= 0 and itens[foco]["id"] == "b%d" % k
	draw_rect(Rect2(r.position.x + Q, r.position.y + Q, r.size.x, r.size.y), Color(0, 0, 0, 0.18))
	draw_rect(r, Color(0.98, 0.95, 0.85) if viu else PAPEL_ESC.lightened(0.1))
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, Q * 2.0), cor.darkened(0.15) if viu else Color(0.5, 0.45, 0.42))
	_moldura_px(r, Color(0.9, 0.68, 0.1) if der else PAPEL_BORDA)
	var pe: Vector2 = r.position + Vector2(TILE_W * 0.5, TILE_H - 40.0)
	V.disco(self, pe + Vector2(0, -22.0), 27.0, cor.lerp(PAPEL, 0.75) if viu else PAPEL_ESC, Q)
	if en["k"] == "gangue":
		EmblemaGangue.desenhar(self, int(en["i"]), pe + Vector2(0, -22.0), 48.0, viu)   # o brasão da gangue (silhueta com ? se ainda não vista)
	elif viu:
		_bicho(self, en, pe, _esc_mini(en), false)
	var nome: String = en["nome"] if viu else "???"
	var aj: Dictionary = ajustar(nome, [12, 11, 10, 9], r.size.x - 6.0, 2)
	var yy: float = r.end.y - 8.0 - (int(aj["tam"]) + 1) * ((aj["linhas"] as Array).size() - 1)
	for ln in aj["linhas"]:
		_txt(ln, Vector2(r.position.x + 3.0, yy), aj["tam"], TINTA if viu else TINTA2, r.size.x - 6.0)
		yy += int(aj["tam"]) + 1
	if der:
		_estrela(r.position + Vector2(r.size.x - 14.0, 19.0), COR_OURO)
	if sobre:
		var pu: float = 0.5 + 0.5 * sin(t * 5.0)
		draw_rect(r.grow(3.0), Color(1.0, 0.7, 0.2, 0.55 + 0.4 * pu), false, 3.0)

func _pagina_bichos(e: Estado) -> void:
	if pagina == 0:
		_indice_bichos(e)
	elif pagina == 1:
		_indice_gangues(e)
	else:
		_ficha_bicho(e, pagina - BICHOS_PAG_INDICE)

## Segunda página do índice do bestiário: as cinco gangues do 3º ato e o que já se viu de cada uma.
func _indice_gangues(e: Estado) -> void:
	var lista: Array = entradas()
	var vistas: int = 0
	var chefes_der: int = 0
	for g in Fases.GANGUE_NOME.size():
		if e.viu_bicho("g%d" % g):
			vistas += 1
		if e.vencido[g] >= 3:
			chefes_der += 1
	_faixa(Rect2(COL_E_X, 76.0, COL_W, 38.0), "Gangues das ruas", [30, 26], COR_OURO)
	_faixa(Rect2(COL_D_X, 76.0, COL_W, 38.0), "Gangues vistas: %d de 5  ·  Chefes derrotados: %d de 5" % [vistas, chefes_der], [17, 16, 15, 14, 13, 12], Color(1.0, 0.94, 0.7))
	_rotulo_bichos("Gangues do 3º ato", rect_tile_bicho(BICHOS_CASA), COR_ABA[ABA_BICHOS], "tipos, truque e chefe")
	for k in range(BICHOS_CASA, lista.size()):
		_tile_bicho(e, k)
	var cx := Rect2(COL_E_X, 276.0, COL_W, 354.0)
	_caixa(cx, "Como são os rivais", COR_ABA[ABA_BICHOS])
	var yy: float = cx.position.y + 46.0
	var par: Array[String] = [
		"No terceiro ato todo inimigo é um gato rival de uma gangue: veste peças do lugar e briga com o seu time antes de ir à torre.",
		"Cada gangue tem os seus tipos de rival, um truque e um chefe.",
		"Derrube o líder (o de coroa) e os outros ficam abalados por %d s: %d%% menos dano e %d%% menos velocidade." % [int(Balanco.MORAL_T), int(round(Balanco.MORAL_DANO * 100.0)), int(round(Balanco.MORAL_VEL * 100.0))],
		"Cada ficha se revela quando o rival aparece na prévia da onda. O chefe só aparece na prévia da última onda.",
	]
	for tx in par:
		yy = _bloco(tx, Vector2(cx.position.x + 18.0, yy), cx.size.x - 36.0, [17, 16, 15, 14], 4, TINTA, 4.0) + 12.0
	var y0: float = 124.0
	for g in Fases.GANGUE_NOME.size():
		var r := Rect2(COL_D_X, y0 + g * 100.0, COL_W, 92.0)
		var viu: bool = e.viu_bicho("g%d" % g)
		var cor: Color = lista[BICHOS_CASA + g]["cor"]
		draw_rect(r, PAPEL_ESC)
		draw_rect(r, PAPEL_BORDA, false, 2.0)
		draw_rect(Rect2(r.position.x, r.position.y, 8.0, r.size.y), cor.darkened(0.05) if viu else Color(0.5, 0.45, 0.42))
		_txt(Fases.GANGUE_NOME[g] if viu else "???", Vector2(r.position.x + 20.0, r.position.y + 25.0), 20, TINTA if viu else TINTA2)
		var tipos: Array[int] = tipos_da_gangue(g)
		var n_v: int = 0
		for tp in tipos:
			if e.viu_rival(g, tp):
				n_v += 1
		_txt("Tipos de rival vistos: %d de %d" % [n_v, tipos.size()], Vector2(r.position.x + 20.0, r.position.y + 50.0), 15, TINTA2)
		var vc: bool = e.viu_chefe_gangue(g)
		_txt(("Chefe: " + Fases.nome_do_chefe(Fases.TOTAL * 2 + g)) if vc else "Chefe: ainda não visto", Vector2(r.position.x + 20.0, r.position.y + 74.0), 15, TINTA if vc else TINTA2)
		EmblemaGangue.desenhar(self, g, r.position + Vector2(r.size.x - 44.0, 58.0), 48.0, viu)
		if e.vencido[g] >= 3:
			_estrela(r.position + Vector2(r.size.x - 22.0, 22.0), COR_OURO)

func _indice_bichos(e: Estado) -> void:
	var lista: Array = entradas()
	var vistos: int = e.bichos_vistos_total()
	var chefes_der: int = 0
	for en in lista:
		if en["k"] == "chefe" and _derrotado(e, en):
			chefes_der += 1
	_faixa(Rect2(COL_E_X, 76.0, COL_W, 38.0), "Bestiário", [30, 26], COR_OURO)
	_faixa(Rect2(COL_D_X, 76.0, COL_W, 38.0), ("Bichos vistos: %d de %d  ·  Chefes derrotados: %d de %d" % [vistos, lista.size(), chefes_der, Fases.CHEFE_NOME.size()]) + ("  ·  Secreto: Schrödinger" if e.feitos.has("schro") else ""), [17, 16, 15, 14, 13, 12], Color(1.0, 0.94, 0.7))
	_rotulo_bichos("Famílias da casa", rect_tile_bicho(0), COR_ABA[1])
	_rotulo_bichos("Tipos de bicho", rect_tile_bicho(10), COR_ABA[2], "e o fantasiado")
	_rotulo_bichos("Chefes da casa", rect_tile_bicho(20), COR_ABA[3])
	_rotulo_bichos("Chefes de fora", rect_tile_bicho(25), COR_ABA[ABA_FORA])
	_rotulo_bichos("Bandos de fora", rect_tile_bicho(5), COR_ABA[ABA_FORA], "todas as famílias juntas")
	for k in BICHOS_CASA:
		_tile_bicho(e, k)
	var pl := Rect2(COL_E_X, 538.0, COL_W, 92.0)
	draw_rect(pl, PAPEL_ESC)
	draw_rect(pl, PAPEL_BORDA, false, 2.0)
	_txt("Ícones sobre os bichos e gatos na luta", Vector2(pl.position.x + 10.0, pl.position.y + 17.0), 13, TINTA)
	# legenda dos estados: ícone e nome, 9 por fileira (passar o mouse num bicho na luta mostra o tempo de cada um)
	var cw: float = (pl.size.x - 12.0) / 9.0
	for q in IconesEstado.QTD:
		var cx: float = pl.position.x + 6.0 + (q % 9) * cw + cw * 0.5
		var cy: float = pl.position.y + 36.0 + (q / 9) * 32.0
		IconesEstado.desenhar(self, q, Vector2(cx, cy))
		_txt(IconesEstado.CURTO[q], Vector2(cx - cw * 0.5, cy + 16.0), 10, TINTA2, cw)
	var pr := Rect2(COL_D_X, 538.0, COL_W, 92.0)
	draw_rect(pr, PAPEL_ESC)
	draw_rect(pr, PAPEL_BORDA, false, 2.0)
	_txt("Seu progresso", Vector2(pr.position.x + 14.0, pr.position.y + 24.0), 16, TINTA)
	var lb: float = (pr.size.x - 28.0 - 14.0) * 0.5
	_barra(Rect2(pr.position.x + 14.0, pr.position.y + 62.0, lb, 16.0), float(vistos) / lista.size(), "Vistos: %d de %d" % [vistos, lista.size()], Color(0.4, 0.7, 0.45))
	_barra(Rect2(pr.position.x + 28.0 + lb, pr.position.y + 62.0, lb, 16.0), float(chefes_der) / Fases.CHEFE_NOME.size(), "Chefes derrotados: %d de %d" % [chefes_der, Fases.CHEFE_NOME.size()], Color(0.95, 0.72, 0.15))

## Cabine do retrato (página da esquerda da ficha): o bicho, o estado "visto/derrotado" e o carimbo.
func _cabine_ficha(e: Estado, en: Dictionary, viu: bool, cor: Color) -> void:
	var der: bool = _derrotado(e, en)
	var cb: Rect2 = _cabine_gato()
	draw_rect(Rect2(cb.position.x + 3, cb.position.y + 4, cb.size.x, cb.size.y), Color(0, 0, 0, 0.16))
	draw_rect(cb, cor.lerp(PAPEL, 0.78) if viu else PAPEL_ESC)
	draw_rect(Rect2(cb.position.x, cb.end.y - 63.0, cb.size.x, 63.0), cor.lerp(PAPEL, 0.55) if viu else PAPEL_ESC.darkened(0.06))
	draw_rect(Rect2(cb.position.x, cb.end.y - 63.0, cb.size.x, Q), cor.darkened(0.2).lerp(PAPEL, 0.4))
	_moldura_px(cb, PAPEL_BORDA)
	_cantoneiras(cb, Color(0.3, 0.17, 0.15))
	_txt("Ficha nº %02d" % (pagina - 1), Vector2(cb.position.x + 34.0, cb.position.y + 18.0), 13, TINTA2)
	var grupo: String = {"fam": "Família", "bando": "Bando de fora", "tipo": "Tipo de bicho", "chefe": "Chefe", "gangue": "Gangue"}[en["k"]]
	_txt(grupo, Vector2(cb.end.x - 160.0, cb.position.y + 18.0), 13, TINTA2, 130.0)
	if viu:
		var px: float = cb.get_center().x
		if en["k"] == "gangue":
			px -= 95.0
			_retrato_chefe_gangue(e, int(en["i"]), Vector2(cb.get_center().x + 105.0, cb.end.y - 44.0))
			_txt(Fases.nome_do_lugar(Fases.TOTAL * 2 + int(en["i"])), Vector2(cb.position.x + 34.0, cb.position.y + 38.0), 13, TINTA2)
		_bicho(self, en, Vector2(px, cb.end.y - 44.0), BICHO_RETRATO_ESC * (0.85 if en["k"] == "chefe" else 1.0), false)
		_txt("Derrotado" if der else "Visto", Vector2(cb.position.x + 16.0, cb.end.y - 10.0), 14, COR_TEM if der else TINTA)
	else:
		_txt("???", Vector2(cb.position.x + 16.0, cb.end.y - 10.0), 14, COR_FALTA)
	if der:
		_carimbo_bicho(Vector2(cb.end.x - 110.0, cb.position.y + 62.0))

func _caixa(r: Rect2, titulo: String, cor: Color) -> void:
	draw_rect(r, PAPEL_ESC)
	draw_rect(r, PAPEL_BORDA, false, 2.0)
	draw_rect(Rect2(r.position.x, r.position.y, 8.0, r.size.y), cor.darkened(0.05))
	_txt(titulo, Vector2(r.position.x + 18.0, r.position.y + 19.0), 13, TINTA2)

func _ficha_bicho(e: Estado, k: int) -> void:
	if entradas()[k]["k"] == "gangue":
		_ficha_gangue(e, k)
		return
	var en: Dictionary = entradas()[k]
	var viu: bool = e.viu_bicho(en["chave"])
	var der: bool = _derrotado(e, en)
	var cor: Color = en["cor"]
	# ---------------- página da esquerda
	_faixa(Rect2(COL_E_X, 76.0, COL_W, 38.0), en["nome"] if viu else "Bicho desconhecido", [30, 28, 26, 24, 22, 20, 18], cor if viu else Color(0.7, 0.66, 0.62))
	_cabine_ficha(e, en, viu, cor)
	var pb := Rect2(COL_E_X, 392.0, COL_W, 100.0)
	_caixa(pb, "O que faz", cor)
	var ob := Rect2(COL_E_X, 500.0, COL_W, 130.0)
	_caixa(ob, "Onde aparece", cor)
	# ---------------- página da direita
	var rd1 := Rect2(COL_D_X, 78.0, COL_W, 200.0)
	var rd2 := Rect2(COL_D_X, 288.0, COL_W, 150.0)
	var rd3 := Rect2(COL_D_X, 448.0, COL_W, 182.0)
	_caixa(rd1, "Como enfrentar", cor)
	_caixa(rd2, "Números", cor)
	_caixa(rd3, "No seu caderno", cor)
	if not viu:
		_bloco("Este bicho ainda não apareceu numa luta. Avance na campanha e vá ver o que ele faz.", Vector2(pb.position.x + 18.0, pb.position.y + 44.0), pb.size.x - 30.0, [16, 15, 14], 3, TINTA2, 3.0)
		_bloco("Ainda é segredo.", Vector2(ob.position.x + 18.0, ob.position.y + 44.0), ob.size.x - 30.0, [16, 15], 1, TINTA2)
		_bloco("Quando ele aparecer, a dica de como vencê-lo fica anotada aqui.", Vector2(rd1.position.x + 18.0, rd1.position.y + 44.0), rd1.size.x - 30.0, [16, 15, 14], 3, TINTA2, 3.0)
		_txt("???", Vector2(rd2.position.x + 18.0, rd2.position.y + 48.0), 20, TINTA2)
		_txt("Ainda não visto", Vector2(rd3.position.x + 18.0, rd3.position.y + 48.0), 18, COR_FALTA)
		return
	_bloco(_maiuscula(en["oque"]), Vector2(pb.position.x + 18.0, pb.position.y + 44.0), pb.size.x - 30.0, [18, 16, 15, 14], 3, TINTA, 3.0)
	_bloco(en["onde"], Vector2(ob.position.x + 18.0, ob.position.y + 44.0), ob.size.x - 30.0, [16, 15, 14], 3, TINTA, 3.0)
	_bloco(_maiuscula(en["dica"]), Vector2(rd1.position.x + 18.0, rd1.position.y + 44.0), rd1.size.x - 30.0, [22, 20, 18, 16], 6, Color(0.5, 0.28, 0.02), 5.0)
	var yy: float = rd2.position.y + 44.0
	for ln in en["ficha"]:
		yy = _bloco(ln, Vector2(rd2.position.x + 18.0, yy), rd2.size.x - 30.0, [16, 15, 14, 13], 2, TINTA, 3.0) + 6.0
	yy = rd3.position.y + 44.0
	_bolinha(Vector2(rd3.position.x + 18.0, yy - 13.0), COR_TEM, true)
	yy = _bloco("Já apareceu numa luta sua.", Vector2(rd3.position.x + 38.0, yy), rd3.size.x - 52.0, [16, 15, 14], 2, TINTA, 3.0) + 6.0
	if en["k"] == "chefe":
		_bolinha(Vector2(rd3.position.x + 18.0, yy - 13.0), COR_TEM if der else COR_FALTA, der)
		_bloco("Derrotado: sim." if der else "Derrotado: ainda não.", Vector2(rd3.position.x + 38.0, yy), rd3.size.x - 52.0, [16, 15, 14], 2, TINTA, 3.0)
	else:
		_bloco("O jogo ainda não conta quantos você derrotou.", Vector2(rd3.position.x + 38.0, yy), rd3.size.x - 52.0, [14, 13, 12], 2, TINTA2, 3.0)

## O chefe da gangue (como no painel do mapa), só depois de visto na prévia.
func _retrato_chefe_gangue(e: Estado, g: int, pe: Vector2) -> void:
	if not e.viu_chefe_gangue(g):
		return
	var li: int = Fases.TOTAL * 2 + g
	var base: int = Fases.chefe_base(li)
	var vest: Array = []
	for sl in Pecas.SLOTS:
		vest.append(Peca.new(Pecas.CONJUNTO_PECAS[Fases.CONJUNTOS[li][0]][sl]))
	Desenho.boneco(self, pe, 0.6 * Balanco.CHEFE_ESCALA_TIPO[base], -1.0, 1, vest, 0.0, t * 2.0 + g, false, 0.0, 1.0, false, -1, 0.0, 0, false, true, base, false, base)

func _carimbo_bicho(centro: Vector2) -> void:
	var f: Font = UIComum.FONTE
	var pul: float = 1.0 + 0.03 * sin(t * 3.0)
	UIComum.trans(self, centro, -0.2, Vector2(pul, pul))
	var w: float = largura("DERROTADO", 26) + 22.0
	var r := Rect2(-w * 0.5, -22.0, w, 38.0)
	var tinta := Color(0.78, 0.12, 0.12, 0.9)
	draw_rect(r, Color(1, 1, 1, 0.35))
	draw_rect(r, tinta, false, 4.0)
	draw_rect(r.grow(-6.0), tinta, false, 1.5)
	draw_string(f, Vector2(-w * 0.5 + 11.0, 8.0), "DERROTADO", HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(26), tinta)
	UIComum.trans_fim(self)

## Ficha de uma gangue do 3º ato: truque e como enfrentar à esquerda; tipos de rival e chefe à direita.
func _ficha_gangue(e: Estado, k: int) -> void:
	var en: Dictionary = entradas()[k]
	var g: int = int(en["i"])
	var viu: bool = e.viu_bicho(en["chave"])
	var cor: Color = en["cor"]
	_faixa(Rect2(COL_E_X, 76.0, COL_W, 38.0), en["nome"] if viu else "Gangue desconhecida", [30, 28, 26, 24, 22, 20, 18], cor if viu else Color(0.7, 0.66, 0.62))
	EmblemaGangue.desenhar(self, g, Vector2(COL_E_X + 28.0, 95.0), 32.0, viu)
	EmblemaGangue.desenhar(self, g, Vector2(COL_E_X + COL_W - 28.0, 95.0), 32.0, viu)
	_cabine_ficha(e, en, viu, cor)
	var pb := Rect2(COL_E_X, 392.0, COL_W, 118.0)
	_caixa(pb, ("O truque: " + GANGUE_TRUQUE_NOME[g]) if viu else "O truque", cor)
	var ob := Rect2(COL_E_X, 518.0, COL_W, 112.0)
	_caixa(ob, "Como enfrentar", cor)
	var rd1 := Rect2(COL_D_X, 78.0, COL_W, 372.0)
	var rd2 := Rect2(COL_D_X, 460.0, COL_W, 170.0)
	_caixa(rd1, "Tipos de rival", cor)
	_caixa(rd2, "O chefe", cor)
	if not viu:
		_bloco("Esta gangue ainda não apareceu numa luta. Chegue ao terceiro ato e veja a prévia da onda.", Vector2(pb.position.x + 18.0, pb.position.y + 44.0), pb.size.x - 30.0, [16, 15, 14], 3, TINTA2, 3.0)
		_bloco("Quando ela aparecer, a dica fica anotada aqui.", Vector2(ob.position.x + 18.0, ob.position.y + 44.0), ob.size.x - 30.0, [16, 15, 14], 3, TINTA2, 3.0)
		_txt("???", Vector2(rd1.position.x + 18.0, rd1.position.y + 48.0), 20, TINTA2)
		_txt("???", Vector2(rd2.position.x + 18.0, rd2.position.y + 48.0), 20, TINTA2)
		return
	_bloco(en["oque"], Vector2(pb.position.x + 18.0, pb.position.y + 42.0), pb.size.x - 30.0, [16, 15, 14], 4, TINTA, 3.0)
	_bloco(en["dica"], Vector2(ob.position.x + 18.0, ob.position.y + 42.0), ob.size.x - 30.0, [16, 15, 14, 13], 4, Color(0.5, 0.28, 0.02), 3.0)
	var yy: float = rd1.position.y + 40.0
	for tp in tipos_da_gangue(g):
		var visto: bool = e.viu_rival(g, tp)
		_bolinha(Vector2(rd1.position.x + 18.0, yy - 4.0), COR_TEM if visto else COR_FALTA, visto)
		_txt(Balanco.nome_rival(g, tp) if visto else "???", Vector2(rd1.position.x + 42.0, yy + 8.0), 16, TINTA if visto else TINTA2)
		var dica: String = Balanco.dica_rival(g, tp)
		if dica == "":
			dica = Campo.TIPO_DICA[tp]
		_bloco(dica if visto else "Ainda não apareceu.", Vector2(rd1.position.x + 42.0, yy + 23.0), rd1.size.x - 60.0, [13, 12, 11], 2, TINTA2, 2.0)
		yy += 46.0
	var li: int = Fases.TOTAL * 2 + g
	if not e.viu_chefe_gangue(g):
		_bloco("O chefe aparece na prévia da última onda do lugar.", Vector2(rd2.position.x + 18.0, rd2.position.y + 44.0), rd2.size.x - 30.0, [16, 15, 14], 3, TINTA2, 3.0)
		return
	_txt(Fases.nome_do_chefe(li), Vector2(rd2.position.x + 18.0, rd2.position.y + 44.0), 20, Color(0.5, 0.28, 0.02))
	if e.vencido[g] >= 3:
		_txt("Derrotado", Vector2(rd2.end.x - 80.0, rd2.position.y + 44.0), 14, COR_TEM)
	var y2: float = _bloco(Fases.ataque_do_chefe(li), Vector2(rd2.position.x + 18.0, rd2.position.y + 68.0), rd2.size.x - 30.0, [14, 13, 12], 3, TINTA, 3.0) + 4.0
	_bloco("Fraqueza: " + Fases.fraqueza_do_chefe(li), Vector2(rd2.position.x + 18.0, y2), rd2.size.x - 30.0, [14, 13, 12], 2, COR_TEM, 3.0)
