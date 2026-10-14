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

## Valor de `abrir()` que abre direto na aba "Metas".
const PAGINA_METAS := -2
const N_ABAS := 8
const ABA_FORA := 6    # "De fora": as fantasias que só caem fora da casa
const ABA_METAS := 7

const GUI_TEX: Texture2D = preload("res://assets/gui/gui_4x.png")
const BOT_TEX: Texture2D = preload("res://assets/gui/botoes_4x.png")
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
	Color(0.98, 0.84, 0.4), Color(0.75, 0.6, 0.92), Color(0.55, 0.82, 0.55), Color(0.5, 0.8, 0.82), Color(0.96, 0.78, 0.5),
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

# ---- estado da tela ----
var estado: Estado = null
var metas_pag: int = 0             # aba Metas: 0 = Campanha, Guarda-roupa, Invasão e Fantasias; 1 = Lado de fora
var em_metas: bool = false          # a aba "Metas" está aberta (ocupa as duas páginas)
var metas_novas: Array[String] = [] # metas cumpridas e ainda não vistas (o dono preenche antes de abrir)
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
	if aberta and not em_metas and pagina > 0 and estado != null and estado.pecas_da_fantasia(fantasia_da_pagina(pagina)) >= Pecas.SLOTS:
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
	return _ordem.size() + 1

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

## Retângulo da miniatura da k-ésima fantasia da seção "Lado de fora" (página direita do índice, terceira fileira).
static func rect_tile_fora(k: int) -> Rect2:
	return Rect2(COL_D_X + k * (TILE_W + TILE_GAP), IDX_Y0 + 2 * IDX_PASSO + 24.0, TILE_W, TILE_H)

static func rect_aba(i: int) -> Rect2:
	return Rect2(ABA_X, ABA_Y0 + i * (ABA_H + ABA_GAP), ABA_W, ABA_H)

## Retângulo da miniatura de uma fantasia no índice, dado o cômodo e a posição nele.
static func rect_tile(comodo: int, k: int) -> Rect2:
	var esq: bool = comodo < 3
	var fila: int = comodo if esq else comodo - 3
	var x0: float = (COL_E_X if esq else COL_D_X) + k * (TILE_W + TILE_GAP)
	return Rect2(x0, IDX_Y0 + fila * IDX_PASSO + 24.0, TILE_W, TILE_H)

static func rect_linha_peca(i: int) -> Rect2:
	return Rect2(COL_D_X, LIN_Y0 + i * (LIN_H + LIN_GAP), COL_W, LIN_H)

## Quantas peças (de qualquer tipo) o jogador já teve, de 84.
static func pecas_obtidas(e: Estado) -> int:
	var n: int = 0
	for c in Pecas.CONJUNTO_PECAS.size():
		n += e.pecas_da_fantasia(c)
	return n

static func pecas_possiveis() -> int:
	return Pecas.CONJUNTO_PECAS.size() * Pecas.SLOTS

static func texto_totais(e: Estado) -> String:
	return "Fantasias completas: %d de %d  ·  Peças: %d de %d" % [e.fantasias_completas(), Pecas.CONJUNTO_PECAS.size(), pecas_obtidas(e), pecas_possiveis()]

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
	var i: int = comodo_da_fantasia(c)
	if i < 0:
		var lf: int = lugar_de_fora(c)
		if lf < 0:
			return "Não cai em nenhum lugar"
		return "Cai fora da casa, %s: %s e %s" % [_em(lf), Fases.FAMILIA_NOME[lf].to_lower(), Fases.CHEFE_NOME[lf]]
	return "Cai %s: %s e %s" % [_em(i), Fases.FAMILIA_NOME[i].to_lower(), Fases.CHEFE_NOME[i]]

static func comodo_bloqueado(e: Estado, i: int) -> bool:
	return i + 1 > e.fase_liberada

static func texto_bloqueio(i: int) -> String:
	return "Cômodo bloqueado: vença o chefe %s, %s" % [Fases.CHEFE_NOME[i - 1], _em(i - 1)] if i >= 1 else ""

## "no Quarto", "na Sala", "na Cozinha", "no Sótão", "no Porão", "no Quintal", "na Garagem", "no Telhado", "na Rua", "na Toca".
static func _em(i: int) -> String:
	return ("na " if i in [1, 2, 6, 8, 9] else "no ") + Fases.NOME[i]

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
	var w: float = ThemeDB.fallback_font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
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
		if linhas.size() <= max_linhas:
			break
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
		draw_string(ThemeDB.fallback_font, Vector2(pos.x, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)
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
	if em_metas:
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
		for k in mini(fo.size(), 5):
			var rf: Rect2 = rect_tile_fora(k)
			itens.append({"id": "f%d" % fo[k], "r": rf, "on": true})
			var cabf: int = Pecas.CONJUNTO_PECAS[fo[k]][0]
			if not estado.ja_teve(cabf):
				_jobs.append({"k": "icone", "tipo": cabf, "centro": rf.position + Vector2(TILE_W * 0.5, TILE_ICO_Y), "tam": 50.0})
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
	if id.begins_with("aba") and int(id.substr(3)) != aba_atual():
		Som.tocar("aba")
	elif id.begins_with("f") or id == "fechar":
		Som.tocar("clique")
	if id == "fechar":
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
				metas_pag = 0
				_montar()
				metas_vistas.emit()
			return
		if em_metas:
			em_metas = false
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
	if pagina == 0 and not em_metas:
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
	var id: String = itens[foco]["id"]
	return id.begins_with("f") and id != "fechar"

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
		if not id.begins_with("f") or id == "fechar" or j == foco:
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

## Retângulo com os cantos cortados (`corte` px) nos cantos pedidos: [topo-esq, topo-dir, base-dir, base-esq].
static func _pts_papel(r: Rect2, corte: float, cantos: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	var x0: float = r.position.x
	var y0: float = r.position.y
	var x1: float = r.end.x
	var y1: float = r.end.y
	if cantos[0]:
		p.append_array([Vector2(x0, y0 + corte), Vector2(x0 + corte, y0)])
	else:
		p.append(Vector2(x0, y0))
	if cantos[1]:
		p.append_array([Vector2(x1 - corte, y0), Vector2(x1, y0 + corte)])
	else:
		p.append(Vector2(x1, y0))
	if cantos[2]:
		p.append_array([Vector2(x1, y1 - corte), Vector2(x1 - corte, y1)])
	else:
		p.append(Vector2(x1, y1))
	if cantos[3]:
		p.append_array([Vector2(x0 + corte, y1), Vector2(x0, y1 - corte)])
	else:
		p.append(Vector2(x0, y1))
	return p

func _folha(r: Rect2, esquerda: bool) -> void:
	var cantos: Array = [true, false, false, true] if esquerda else [false, true, true, false]
	# folhas de baixo, para dar espessura ao álbum
	for k in [3, 2, 1]:
		var off := Vector2(-2.0 * k, 2.0 * k) if esquerda else Vector2(2.0 * k, 2.0 * k)
		var pts: PackedVector2Array = _pts_papel(Rect2(r.position + off, r.size), 12.0, cantos)
		draw_colored_polygon(pts, Color(0.82, 0.76, 0.62).darkened(0.04 * (4 - k)))
		var fech: PackedVector2Array = pts.duplicate()
		fech.append(pts[0])
		draw_polyline(fech, Color(0.42, 0.32, 0.24, 0.6), 1.0)
	var p: PackedVector2Array = _pts_papel(r, 12.0, cantos)
	draw_colored_polygon(p, PAPEL)
	# linhas de caderno bem fracas
	var y: float = r.position.y + 50.0
	while y < r.end.y - 10.0:
		draw_line(Vector2(r.position.x + 6.0, y), Vector2(r.end.x - 6.0, y), Color(0.45, 0.6, 0.8, 0.10), 1.0)
		y += 22.0
	# sombra suave na dobra (espinha)
	for i in 16:
		var a: float = 0.16 * (1.0 - i / 16.0)
		var x: float = (r.end.x - 1 - i) if esquerda else (r.position.x + i)
		draw_rect(Rect2(x, r.position.y + 2.0, 1.0, r.size.y - 4.0), Color(0.25, 0.15, 0.1, a))
	var fecha: PackedVector2Array = p.duplicate()
	fecha.append(p[0])
	draw_polyline(fecha, PAPEL_BORDA, 1.5)

func _argolas() -> void:
	for i in 5:
		var y: float = 118.0 + i * 108.0
		# furos nas duas folhas
		draw_circle(Vector2(PG_E.end.x - 12.0, y), 5.0, Color(0.25, 0.15, 0.15))
		draw_circle(Vector2(PG_D.position.x + 12.0, y), 5.0, Color(0.25, 0.15, 0.15))
		# argola de metal atravessando a espinha
		draw_rect(Rect2(ESPINHA_X - 22.0, y - 7.0, 44.0, 14.0), Color(0.3, 0.3, 0.36))
		draw_rect(Rect2(ESPINHA_X - 22.0, y - 6.0, 44.0, 12.0), Color(0.7, 0.72, 0.8))
		draw_rect(Rect2(ESPINHA_X - 22.0, y - 6.0, 44.0, 4.0), Color(0.95, 0.96, 1.0))
		draw_rect(Rect2(ESPINHA_X - 22.0, y + 3.0, 44.0, 3.0), Color(0.45, 0.47, 0.56))
		draw_circle(Vector2(ESPINHA_X - 22.0, y), 7.0, Color(0.62, 0.64, 0.72))
		draw_circle(Vector2(ESPINHA_X + 22.0, y), 7.0, Color(0.62, 0.64, 0.72))
		draw_circle(Vector2(ESPINHA_X - 22.0, y - 1.0), 3.0, Color(0.95, 0.96, 1.0))
		draw_circle(Vector2(ESPINHA_X + 22.0, y - 1.0), 3.0, Color(0.95, 0.96, 1.0))

func _faixa(r: Rect2, txt: String, tams: Array, cor: Color) -> void:
	draw_rect(r.grow(2.0), Color(0, 0, 0, 0.18))
	draw_rect(r, COR_FAIXA)
	draw_rect(r, cor.darkened(0.1), false, 2.0)
	var tam: int = tam_cabe(txt, tams, r.size.x - 24.0)
	var f: Font = ThemeDB.fallback_font
	var y: float = r.position.y + (r.size.y - f.get_height(tam)) * 0.5 + f.get_ascent(tam)
	_txt(txt, Vector2(r.position.x, y), tam, cor, r.size.x, 6)

func _estrela(centro: Vector2, raio: float, cor: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a: float = -PI * 0.5 + i * PI / 5.0
		var rr: float = raio if i % 2 == 0 else raio * 0.45
		pts.append(centro + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, cor)
	var fe: PackedVector2Array = pts.duplicate()
	fe.append(pts[0])
	draw_polyline(fe, Color(0.3, 0.18, 0.05), 1.2)

func _cadeado(centro: Vector2, cor: Color) -> void:
	draw_arc(centro + Vector2(0, -2), 4.5, PI, TAU, 8, cor, 2.0)
	draw_rect(Rect2(centro.x - 6, centro.y - 2, 12, 9), cor)
	draw_rect(Rect2(centro.x - 1, centro.y + 1, 2, 4), Color(0.2, 0.12, 0.1))

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
	var costura: Rect2 = CAPA.grow(-27.0)
	var x: float = costura.position.x
	while x < costura.end.x:
		draw_line(Vector2(x, costura.position.y), Vector2(minf(x + 7.0, costura.end.x), costura.position.y), COR_COSTURA, 2.0)
		draw_line(Vector2(x, costura.end.y), Vector2(minf(x + 7.0, costura.end.x), costura.end.y), COR_COSTURA, 2.0)
		x += 12.0
	var y: float = costura.position.y
	while y < costura.end.y:
		draw_line(Vector2(costura.position.x, y), Vector2(costura.position.x, minf(y + 7.0, costura.end.y)), COR_COSTURA, 2.0)
		draw_line(Vector2(costura.end.x, y), Vector2(costura.end.x, minf(y + 7.0, costura.end.y)), COR_COSTURA, 2.0)
		y += 12.0
	_nove(self, GUI_TEX, R_MADEIRA, M_MADEIRA, CAPA, 0.75, Color.WHITE, false)
	# plaqueta dourada com o título
	var placa := Rect2(592.0 - 130.0, 33.0, 260.0, 24.0)
	draw_rect(placa, Color(0.55, 0.38, 0.1))
	draw_rect(placa.grow(-2.0), Color(0.95, 0.78, 0.3))
	draw_rect(placa.grow(-2.0), Color(0.5, 0.32, 0.06), false, 1.0)
	_txt("Fichário de fantasias", Vector2(placa.position.x, placa.position.y + 17.0), 16, Color(0.3, 0.17, 0.04), placa.size.x)
	UIComum.pata(self, 0, Vector2(placa.position.x + 8.0, placa.position.y + 2.0), 1)
	UIComum.pata(self, 2, Vector2(placa.end.x - 23.0, placa.position.y + 2.0), 1)
	# as duas folhas e as argolas
	_folha(PG_E, true)
	_folha(PG_D, false)
	_argolas()
	if em_metas:
		_pagina_metas(e)
	elif pagina == 0:
		_pagina_indice(e)
	else:
		_pagina_fantasia(e, fantasia_da_pagina(pagina))
	# virada de página: uma folha de papel varrendo a página nova
	if virar_t > 0.0:
		var k: float = virar_t / 0.26
		var alvo: Rect2 = PG_D if virar_dir > 0 else PG_E
		var larg: float = alvo.size.x * k
		var rr: Rect2 = Rect2(alvo.position.x, alvo.position.y, larg, alvo.size.y) if virar_dir > 0 else Rect2(alvo.end.x - larg, alvo.position.y, larg, alvo.size.y)
		draw_rect(rr, Color(PAPEL.r, PAPEL.g, PAPEL.b, 0.85 * k))
		var borda_x: float = rr.end.x if virar_dir > 0 else rr.position.x
		draw_rect(Rect2(borda_x - 3.0, rr.position.y, 6.0, rr.size.y), Color(0.2, 0.12, 0.08, 0.25 * k))
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
		var rr := Rect2(r.position.x - (14.0 if ativa else (6.0 if sobre else 0.0)), r.position.y, r.size.x + (14.0 if ativa else (6.0 if sobre else 0.0)), r.size.y)
		draw_rect(Rect2(rr.position.x + 3, rr.position.y + 3, rr.size.x, rr.size.y), Color(0, 0, 0, 0.3))
		var pts := PackedVector2Array([rr.position, Vector2(rr.end.x - 12.0, rr.position.y), Vector2(rr.end.x, rr.position.y + 12.0), Vector2(rr.end.x, rr.end.y - 12.0), Vector2(rr.end.x - 12.0, rr.end.y), Vector2(rr.position.x, rr.end.y)])
		draw_colored_polygon(pts, cor)
		var fe: PackedVector2Array = pts.duplicate()
		fe.append(pts[0])
		draw_polyline(fe, TINTA, 2.0 if ativa else 1.5)
		var nome: String = "Índice" if i == 0 else ("Metas" if i == ABA_METAS else ("De fora" if i == ABA_FORA else Fases.NOME[i - 1]))
		var sub: String = ""
		if i == ABA_METAS:
			sub = "%d/%d" % [e.metas_cumpridas(), Metas.lista().size()]
		elif i == ABA_FORA:
			sub = "%d/%d" % [completas_so_de_fora(e), fantasias_so_de_fora().size()]
		elif i == 0:
			sub = "%d/%d" % [e.fantasias_completas(), Pecas.CONJUNTO_PECAS.size()]
		else:
			sub = "%d/%d" % [completas_do_comodo(e, i - 1), Fases.CONJUNTOS[i - 1].size()]
		var cx: float = r.position.x + 28.0 + (r.size.x - 28.0 - 12.0) * 0.5
		var larg_t: float = r.end.x - 14.0 - (r.position.x + 28.0)
		_txt(nome, Vector2(cx - larg_t * 0.5, rr.position.y + 25.0), 17, TINTA, larg_t)
		_txt(sub, Vector2(cx - larg_t * 0.5, rr.position.y + 44.0), 13, TINTA2, larg_t)
		if i == ABA_METAS and not metas_novas.is_empty() and not em_metas:
			draw_circle(Vector2(rr.position.x + 18.0, rr.position.y + 28.0), 7.0, Color(0.9, 0.2, 0.2))
		if i > 0 and i < ABA_FORA and comodo_bloqueado(e, i - 1):
			_cadeado(Vector2(rr.position.x + 18.0, rr.position.y + 28.0), Color(0.3, 0.2, 0.25))

func _botoes() -> void:
	for i in itens.size():
		var it: Dictionary = itens[i]
		var id: String = it["id"]
		if id.begins_with("aba") or (id.begins_with("f") and id != "fechar"):
			continue
		var txt: String = "Fechar" if id == "fechar" else ("< Voltar" if id == "ant" else "Avançar >")
		var cor: Color = UIComum.B_MARROM if id == "fechar" else UIComum.B_OURO
		var o: Dictionary = {"on": it["on"], "foco": i == foco and it["on"], "h": UIComum.anim_h(anim, id), "p": UIComum.anim_p(anim, id), "tam": 17}
		UIComum.botao(self, it["r"], txt, cor, o, t)
	var marca: String = ("Metas %d/2" % (metas_pag + 1)) if em_metas else "Índice" if pagina == 0 else "Fantasia %d de %d  ·  %s" % [pagina, _ordem.size(), nome_secao(fantasia_da_pagina(pagina))]
	_txt(marca, Vector2(250.0, 672.0), 15 if marca.length() < 26 else 13, Color(1, 0.94, 0.8), 240.0, 4)
	_txt("Setas, A/D ou PgUp/PgDn  |  Esc fecha", Vector2(700.0, 672.0), 13, Color(1, 0.94, 0.8, 0.7), 230.0, 3)

## Dica do mouse (ou do foco do teclado) sobre uma miniatura do índice.
func _dica_tile() -> void:
	if pagina != 0 or em_metas or not _foco_e_tile():
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
		_txt("só caem fora da casa", Vector2(rf0.position.x + 11.0 + largura(lblf, 16) + 10.0, rf0.position.y - 10.0), 12, TINTA2)
		for k in mini(fo2.size(), 5):
			_tile(e, fo2[k], rect_tile_fora(k))
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
	var comp: int = e.fantasias_completas()
	var nf: int = Pecas.CONJUNTO_PECAS.size()
	var po: int = pecas_obtidas(e)
	var lb: float = (pr.size.x - 28.0 - 14.0) * 0.5
	_barra(Rect2(pr.position.x + 14.0, pr.position.y + 62.0, lb, 16.0), float(comp) / nf, "Completas: %d de %d" % [comp, nf], Color(0.95, 0.72, 0.15))
	_barra(Rect2(pr.position.x + 28.0 + lb, pr.position.y + 62.0, lb, 16.0), float(po) / pecas_possiveis(), "Peças encontradas: %d de %d" % [po, pecas_possiveis()], Color(0.4, 0.7, 0.45))

func _barra(r: Rect2, frac: float, rotulo: String, cor: Color) -> void:
	_txt(rotulo, Vector2(r.position.x, r.position.y - 6.0), 14, TINTA)
	var b := Rect2(r.position.x, r.position.y, r.size.x, r.size.y)
	draw_rect(b, Color(0.25, 0.18, 0.16))
	draw_rect(Rect2(b.position.x + 2.0, b.position.y + 2.0, (b.size.x - 4.0) * clampf(frac, 0.0, 1.0), b.size.y - 4.0), cor)
	draw_rect(Rect2(b.position.x + 2.0, b.position.y + 2.0, (b.size.x - 4.0) * clampf(frac, 0.0, 1.0), 4.0), cor.lightened(0.4))

func _tile(e: Estado, c: int, r: Rect2) -> void:
	var n: int = e.pecas_da_fantasia(c)
	var completa: bool = n >= Pecas.SLOTS
	var cor: Color = Pecas.CONJUNTO_COR[c]
	var sobre: bool = foco >= 0 and itens[foco]["id"] == "f%d" % c
	draw_rect(Rect2(r.position.x + 2, r.position.y + 3, r.size.x, r.size.y), Color(0, 0, 0, 0.18))
	draw_rect(r, Color(0.98, 0.95, 0.85) if completa else PAPEL_ESC.lightened(0.25))
	# fita colorida no topo, na cor da fantasia
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 5.0), cor.darkened(0.15))
	draw_rect(r, Color(0.9, 0.68, 0.1) if completa else PAPEL_BORDA, false, 3.0 if completa else 1.5)
	var cab: int = Pecas.CONJUNTO_PECAS[c][0]
	var centro := r.position + Vector2(r.size.x * 0.5, TILE_ICO_Y)
	draw_circle(centro, 26.0, cor.lerp(PAPEL, 0.7))
	if e.ja_teve(cab):
		Desenho.icone(self, cab, centro, 50.0)
	# nome em até duas linhas
	var aj: Dictionary = ajustar(Pecas.CONJUNTO_NOME[c], [12, 11, 10, 9], r.size.x - 8.0, 2)
	var yy: float = r.position.y + 70.0
	for ln in aj["linhas"]:
		_txt(ln, Vector2(r.position.x + 4.0, yy), aj["tam"], TINTA, r.size.x - 8.0)
		yy += int(aj["tam"]) + 1
	var cc: Color = Color(0.6, 0.38, 0.0) if completa else (TINTA2 if n > 0 else Color(0.55, 0.5, 0.48))
	_txt("%d/%d" % [n, Pecas.SLOTS], Vector2(r.position.x, r.end.y - 5.0), 13, cc, r.size.x)
	if completa:
		_estrela(r.position + Vector2(r.size.x - 11.0, 16.0), 9.0, COR_OURO)
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
	draw_rect(Rect2(cb.position.x, cb.end.y - 62.0, cb.size.x, 62.0), cor.lerp(PAPEL, 0.55))
	draw_line(Vector2(cb.position.x, cb.end.y - 62.0), Vector2(cb.end.x, cb.end.y - 62.0), cor.darkened(0.2).lerp(PAPEL, 0.4), 2.0)
	draw_rect(cb, PAPEL_BORDA, false, 2.0)
	for q in 4:   # cantoneiras da foto
		var px: float = cb.position.x if q % 2 == 0 else cb.end.x
		var py: float = cb.position.y if q < 2 else cb.end.y
		var sx: float = 1.0 if q % 2 == 0 else -1.0
		var sy: float = 1.0 if q < 2 else -1.0
		draw_colored_polygon(PackedVector2Array([Vector2(px, py), Vector2(px + 26.0 * sx, py), Vector2(px, py + 26.0 * sy)]), Color(0.3, 0.17, 0.15))
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
	_txt(Pecas.PODER_NOME[c], Vector2(pb.position.x + 12.0, pb.position.y + 44.0), tam_cabe(Pecas.PODER_NOME[c], [22, 20, 18], pb.size.x - 24.0), Color(0.62, 0.34, 0.02))
	_bloco(_maiuscula(Pecas.PODER_DICA[c]) + ", a cada %d s" % int(Balanco.PODER_INTERVALO), Vector2(pb.position.x + 12.0, pb.position.y + 66.0), pb.size.x - 24.0, [14, 13, 12], 2, TINTA, 2.0)
	_txt("Vale com as 4 peças vestidas" if not completa else "Fantasia completa: o poder é seu", Vector2(pb.position.x + 12.0, pb.end.y - 7.0), 12, TINTA2)
	# onde encontrar
	var ob := Rect2(COL_E_X, 500.0, COL_W, 130.0)
	draw_rect(ob, PAPEL_ESC)
	draw_rect(ob, PAPEL_BORDA, false, 2.0)
	draw_rect(Rect2(ob.position.x, ob.position.y, 8.0, ob.size.y), COR_ABA[sala + 1 if sala >= 0 else ABA_FORA].darkened(0.05))
	_txt("Onde encontrar", Vector2(ob.position.x + 18.0, ob.position.y + 19.0), 13, TINTA2)
	var xo: float = ob.position.x + 18.0
	var wo: float = ob.size.x - 30.0
	var yy: float = _bloco(texto_onde(c), Vector2(xo, ob.position.y + 42.0), wo, [18, 16, 15, 14], 2, TINTA, 3.0)
	if sala >= 0:
		# as fantasias da casa também caem, redistribuídas, num lugar de fora
		var tf: String = texto_fora(c)
		if tf != "":
			yy = _bloco("Fora da casa, cai " + tf, Vector2(xo, yy), wo, [14, 13, 12], 1, Color(0.28, 0.4, 0.42), 3.0)
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

func _carimbo(centro: Vector2) -> void:
	var f: Font = ThemeDB.fallback_font
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
	draw_string(f, Vector2(-w * 0.5 + 11.0, 9.0), "COMPLETA", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, tinta)
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
		draw_circle(sc, 10.0, Color(0.62, 0.2, 0.2))
		draw_arc(sc, 10.0, 0.0, TAU, 16, Color(0.25, 0.08, 0.08), 1.5)
		_txt("?", Vector2(sc.x - 10.0, sc.y + 6.0), 16, Color.WHITE, 20.0)
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
	draw_circle(Vector2(x + 5.0, ty - 5.0), 5.0, cs)
	if tem or teve:
		draw_line(Vector2(x + 2.5, ty - 5.0), Vector2(x + 4.5, ty - 3.0), Color.WHITE, 1.5)
		draw_line(Vector2(x + 4.5, ty - 3.0), Vector2(x + 8.0, ty - 8.0), Color.WHITE, 1.5)
	_txt(txt, Vector2(x + 16.0, ty), tam_s, cs)

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
	Desenho.boneco(alvo, _pos_gato(), GATO_ESC, 1.0, 0, pecas, 0.0, t, golpe <= 0.0, golpe, 0.0 if so_faltam else 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, posmod(c, Desenho.PELAGENS.size()))

func _desenhar_silhuetas() -> void:
	if not aberta or estado == null:
		return
	for j in _jobs:
		if j["k"] == "icone":
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
	_estrela(Vector2(direita - 38.0, y), 7.0, COR_OURO if feita else Color(0.75, 0.68, 0.5))
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
		_txt("pendente" if not trancada else "trancada", Vector2(r.end.x - 66.0, y + 20.0), 11, TINTA2, 60.0)
	return y + 34.0

## Segunda dupla de folhas das Metas: as metas do lado de fora e o andamento de cada lugar.
func _metas_fora(e: Estado, todas: Array) -> void:
	var ms: Array = todas.filter(func(m: Dictionary) -> bool: return m["grupo"] == "Lado de fora")
	var feitas: int = 0
	for m in ms:
		if e.metas_pagas.has(m["id"]):
			feitas += 1
	var y: float = 120.0
	draw_rect(Rect2(COL_E_X, y + 3.0, 5.0, 16.0), COR_ABA[ABA_METAS].darkened(0.2))
	_txt("Lado de fora  ·  %d/%d" % [feitas, ms.size()], Vector2(COL_E_X + 11.0, y + 17.0), 16, TINTA)
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
			_txt(("Invasão: onda %d" % rec) if rec > 0 else "Invasão: sem recorde", Vector2(r.end.x - 150.0, yy + 44.0), 13, TINTA2, 140.0)
		else:
			_txt("falta", Vector2(r.end.x - 60.0, yy + 24.0), 14, TINTA2, 50.0)
		yy += 62.0

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
		draw_rect(Rect2(COL_E_X, y + 3.0, 5.0, 16.0), COR_ABA[ABA_METAS].darkened(0.2))
		_txt("%s  ·  %d/%d" % [g, feitas, ms.size()], Vector2(COL_E_X + 11.0, y + 17.0), 16, TINTA)
		y += 24.0
		for m in ms:
			y = _linha_meta(e, m, y, g == "Invasão" and not zerada)
		y += 6.0
	# página direita: as 25 fantasias (linhas baixas: 25 cabem em 118..630)
	var fs: Array = todas.filter(func(m: Dictionary) -> bool: return m["grupo"] == "Fantasias")
	var nf: int = 0
	for m in fs:
		if e.metas_pagas.has(m["id"]):
			nf += 1
	_faixa(Rect2(COL_D_X, 76.0, COL_W, 34.0), "Fantasias  ·  %d/%d  ·  junte as 4 peças" % [nf, fs.size()], [17, 16, 15, 14, 13], Color(1.0, 0.94, 0.7))
	var yy: float = 118.0
	for m in fs:
		var feita2: bool = e.metas_pagas.has(m["id"])
		var c: int = int(String(m["id"]).substr(9))
		var r2 := Rect2(COL_D_X, yy, COL_W, 19.0)
		draw_rect(r2, Color(0.86, 0.95, 0.8) if feita2 else PAPEL_ESC.lightened(0.25))
		draw_rect(r2, COR_TEM if feita2 else PAPEL_BORDA, false, 1.5 if feita2 else 1.0)
		draw_rect(Rect2(r2.position.x, r2.position.y, 5.0, r2.size.y), Pecas.CONJUNTO_COR[c].darkened(0.1))
		_txt(cortar(m["nome"], 13, 230.0), Vector2(r2.position.x + 12.0, yy + 14.0), 13, TINTA)
		if metas_novas.has(m["id"]):
			_txt("NOVA", Vector2(r2.position.x + 296.0, yy + 14.0), 11, Color(0.85, 0.15, 0.15))
			draw_rect(r2.grow(2.0), Color(1.0, 0.8, 0.2, 0.5 + 0.5 * sin(t * 6.0)), false, 2.0)
		_txt("%d/%d" % [e.pecas_da_fantasia(c), Pecas.SLOTS], Vector2(r2.position.x + 250.0, yy + 14.0), 13, COR_TEM if feita2 else TINTA2, 36.0)
		_premio(m, r2.end.x - 53.0, yy + 9.5, feita2)
		if feita2:
			_selo_meta(Vector2(r2.end.x - 34.0, yy + 9.5), "FEITA", COR_TEM, 11)
		yy += 20.4
