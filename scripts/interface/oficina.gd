class_name Oficina
extends Control
## Oficina da torre: tela por cima do mapa e do guarda-roupa onde o jogador gasta troféus
## em melhorias permanentes e monta os módulos liberados pelos chefes.
## A tela só mostra e pede: quem compra e monta é o `Estado` (melhorar / alternar_modulo).
## Tudo é desenhado por código com as molduras do pacote "Cryo's Mini GUI" e ícones em pixel (grade de 4 px).

const GUI_TEX: Texture2D = preload("res://assets/terceiros/gui/gui_4x.png")
const BOT_TEX: Texture2D = preload("res://assets/terceiros/gui/botoes_4x.png")
const R_MADEIRA := Rect2(8, 136, 80, 80)
const M_MADEIRA := Vector4(28, 28, 28, 28)
const R_BT_N := Rect2(132, 4, 88, 56)
const R_BT_P := Rect2(228, 8, 88, 52)
const M_BT := Vector4(16, 16, 16, 16)
const COR_TINTA := Color(1.0, 0.94, 0.8)
const COR_FUNDO := Color(0.14, 0.09, 0.12, 0.98)
const COR_OURO := Color(1.0, 0.82, 0.2)

# ---- geometria (tudo a partir destas constantes) ----
const PAINEL := Rect2(90, 20, 1100, 680)
const COL_E_X := 124.0            # coluna das melhorias
const COL_E_W := 496.0
const COL_D_X := 648.0            # coluna dos módulos
const COL_D_W := 508.0
const LISTA_Y := 180.0
const LIN_H := 100.0
const LIN_GAP := 6.0
const CARD_H := 78.0
const CARD_GAP := 7.0
const BTN_FECHAR := Rect2(540, 624, 200, 44)
const BTN_X := Rect2(1124.0, 38.0, 42.0, 42.0)
const BTN_MELHORAR_W := 136.0
const TEXTO_DESLOC := 84.0        # x do texto numa linha de melhoria, a partir da borda dela
const QUADRADOS_DESLOC := 214.0   # x dos cinco quadradinhos de nível, a partir da borda da linha

# ---- ícones em pixel: 12 linhas de 12 letras (a cor de cada letra está em PALETA) ----
const PALETA: Dictionary = {
	"o": Color(0.12, 0.07, 0.06), "g": Color(1.0, 0.82, 0.25), "G": Color(0.78, 0.52, 0.12), "h": Color(1.0, 0.96, 0.7),
	"r": Color(0.86, 0.32, 0.28), "R": Color(0.6, 0.18, 0.18), "b": Color(0.3, 0.52, 0.84), "B": Color(0.2, 0.34, 0.6),
	"y": Color(0.96, 0.76, 0.28), "v": Color(0.36, 0.7, 0.4), "V": Color(0.2, 0.46, 0.26), "n": Color(0.62, 0.42, 0.25),
	"N": Color(0.4, 0.26, 0.15), "s": Color(0.72, 0.74, 0.8), "S": Color(0.45, 0.47, 0.55), "w": Color(0.95, 0.95, 1.0),
	"c": Color(0.93, 0.56, 0.24), "k": Color(0.25, 0.25, 0.3),
}

const ICO_MELHORIA: Array = [
	[ # estrutura: muralha de blocos
		"ooo.ooo.ooo.", "orroorroorro", "oooooooooooo", "orrrrroyyyyo", "orrrrroyyyyo", "oooooooooooo",
		"obbbocccccco", "obbbocccccco", "oooooooooooo", "orrrrroyyyyo", "orrrrroyyyyo", "oooooooooooo",
	],
	[ # canhão
		"............", "............", "...oooooooo.", "..okkSSSSkko", "..okkkkkkkko", "..oooooooooo",
		"..ooNNNNoo..", ".oNnnnnnnNo.", ".oNnnoonnNo.", ".oNnnoonnNo.", ".oNnnnnnnNo.", "..ooNNNNoo..",
	],
	[ # cadência: ampulheta
		".oooooooooo.", ".onnnnnnnno.", "..owwwwwwo..", "..oyyyyyyo..", "...oyyyyo...", "....oyyo....",
		".....oo.....", "....owwo....", "...owwwwo...", "..oyyyyyyo..", ".onnnnnnnno.", ".oooooooooo.",
	],
	[ # enfermaria: cruz verde
		"............", "...oooooo...", "...ovvvvo...", "...ovvvvo...", "oooovvvvoooo", "ovvvvvvvvvvo",
		"ovvvvvvvvvvo", "oooovvvvoooo", "...ovvvvo...", "...ovvvvo...", "...oooooo...", "............",
	],
]

const ICO_MODULO: Array = [
	[ # ratoeira
		"............", "..oooooooo..", ".oSSSSSSSSo.", ".oS......So.", ".oS......So.", "oooooooooooo",
		"onnnnnnnnnno", "onyyynnnnnno", "onyyhynnnnno", "onyyyyynnnno", "oNNNNNNNNNNo", "oooooooooooo",
	],
	[ # catapulta
		"........ooo.", "........oyyo", "........oyyo", "........ooo.", "......nn....", ".....nn.....",
		"....nnN.....", "...nnNNN....", ".nn..NNN..nn", "nn...NNN...n", "nnnnnnnnnnnn", "NNNNNNNNNNNN",
	],
	[ # sirene
		".....oo.....", ".....oo.....", "....orro....", "...orrrro...", "..orrhrrrro.", "..orhrrrrro.",
		"..orhrrrrro.", ".orrrrrrrro.", ".orrrrrrrro.", "oooooooooooo", "....oggo....", ".....oo.....",
	],
	[ # balista de penas
		"..........ss", ".........sSs", "........nn..", ".......nn...", "......nn....", ".....nn.....",
		"....nn......", "...nnr......", "..nnrr......", ".rrnr.......", "rrr.........", "r...........",
	],
	[ # caldeirão
		"....v..v....", "...v.v..v...", "............", ".oooooooooo.", "ovvvvvvvvvvo", "oooooooooooo",
		".okkkkkkkko.", "okkSSkkkkkko", "okkSkkkkkkko", "okkkkkkkkkko", ".okkkkkkkko.", ".oo......oo.",
	],
]

const ICO_TROFEU: Array = [
	".oooooooo.", "ooghggggoo", "o.gggggg.o", "o.oggggo.o", ".ooggggoo.",
	"...oggo...", "....gg....", "....GG....", "..oGGGGo..", "..oooooo..",
]

# ---- estado da tela ----
var dono: Variant = null
var aberta: bool = false
var itens: Array[Dictionary] = []   # botões: {id, r, on, txt, cor, tam, ...}
var foco: int = 0
var apertado_id: String = ""
var apertado_fora: bool = false
var t: float = 0.0
var aviso: String = ""
var aviso_t: float = 0.0
var flash_id: String = ""
var flash_t: float = 0.0
# ---- juice
var anim: Dictionary = {}                 # hover/apertado de cada botão
var abrir_t: float = 0.0                  # segundos desde que abriu (salto do painel, cascata)
var faiscas := UIComum.Faiscas.new()
var tr_exib: float = 0.0                  # troféus mostrados (contam até o valor real)
var pulso_tr: float = 0.0
var centro_cont: Vector2 = Vector2(640, 108)
var compra_t: Array[float] = [9.0, 9.0, 9.0, 9.0]   # < 0: troféus ainda voando; 0..0.7: valores contando
var compra_ant: Array = [[], [], [], []]            # textos de antes da compra
var mont_t: Dictionary = {}               # módulo -> segundos desde que foi montado/desmontado
var treme: Dictionary = {}                # id -> segundos de tremida (ação recusada)
var prev_pulso: float = 0.0               # clarão dos blocos da prévia da torre
var prev_recuo: float = 0.0
var _foco_som: int = -1
var x_sobre: bool = false
var x_press: bool = false

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	visible = false

func iniciar(d: Variant) -> void:
	dono = d
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

# ------------------------------------------------------------------ geometria pública
static func rect_linha(i: int) -> Rect2:
	return Rect2(COL_E_X, LISTA_Y + i * (LIN_H + LIN_GAP), COL_E_W, LIN_H)

static func rect_melhorar(i: int) -> Rect2:
	var r: Rect2 = rect_linha(i)
	return Rect2(r.end.x - BTN_MELHORAR_W - 10.0, r.position.y + 20.0, BTN_MELHORAR_W, 44.0)

static func rect_quadrado(i: int, k: int) -> Rect2:
	var r: Rect2 = rect_linha(i)
	return Rect2(r.position.x + QUADRADOS_DESLOC + k * 20.0, r.position.y + 14.0, 16.0, 16.0)

static func rect_card(i: int) -> Rect2:
	return Rect2(COL_D_X, LISTA_Y + i * (CARD_H + CARD_GAP), COL_D_W, CARD_H)

static func rect_btn_modulo(i: int) -> Rect2:
	var c: Rect2 = rect_card(i)
	return Rect2(c.end.x - 118.0, c.position.y + 19.0, 108.0, 40.0)

## Largura disponível para o texto de uma linha de melhoria (até o botão).
static func larg_texto_linha() -> float:
	return rect_melhorar(0).position.x - 8.0 - (COL_E_X + TEXTO_DESLOC)

## Largura do texto da descrição de um cartão de módulo (liberado ou bloqueado).
static func larg_texto_card(liberado: bool) -> float:
	var c: Rect2 = rect_card(0)
	var x0: float = c.position.x + 72.0
	return (rect_btn_modulo(0).position.x - 8.0 - x0) if liberado else (c.end.x - 10.0 - x0)

# ------------------------------------------------------------------ valores das melhorias
static func num(v: float) -> String:
	if absf(v - roundf(v)) < 0.001:
		return "%d" % int(roundf(v))
	return ("%.1f" % v).replace(".", ",")

## [rótulo, valor no nível n, valor no nível n+1] de cada melhoria, só a partir das constantes.
static func valores(m: int, n: int) -> Array:
	match m:
		Torre.Melhoria.ESTRUTURA:
			return ["Blocos", str(Balanco.TIJOLOS_INICIAIS + Torre.ESTRUTURA_BLOCOS * n), str(Balanco.TIJOLOS_INICIAIS + Torre.ESTRUTURA_BLOCOS * (n + 1))]
		Torre.Melhoria.CANHAO:
			return ["Dano do tiro", num(Balanco.TORRE_TIRO_DANO * (1.0 + Torre.CANHAO_DANO * n)), num(Balanco.TORRE_TIRO_DANO * (1.0 + Torre.CANHAO_DANO * (n + 1)))]
		Torre.Melhoria.CADENCIA:
			return ["Tiros por segundo", "+%d%%" % int(round(Torre.CADENCIA_RAPIDEZ * n * 100.0)), "+%d%%" % int(round(Torre.CADENCIA_RAPIDEZ * (n + 1) * 100.0))]
		Torre.Melhoria.ENFERMARIA:
			return ["Cura entre ondas", "%d%%" % int(round((Balanco.CURA_MAX + Torre.ENFERMARIA_CURA * n) * 100.0)), "%d%%" % int(round((Balanco.CURA_MAX + Torre.ENFERMARIA_CURA * (n + 1)) * 100.0))]
	return ["", "", ""]

static func _maiuscula(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)

## Por que o botão está apagado ("" se pode comprar).
static func motivo_melhoria(e: Estado, m: int) -> String:
	if e.melhorias[m] >= Torre.MELHORIA_NIVEL_MAX:
		return "Máximo"
	var falta: int = Torre.MELHORIA_CUSTO - e.trofeus
	if falta > 0:
		return "Falta 1 troféu" if falta == 1 else "Faltam %d troféus" % falta
	return ""

static func requisito_modulo(m: int) -> String:
	return "Vença o chefe %s, %s" % [Fases.CHEFE_NOME[m], ("na " if m in [1, 2, 6, 8, 9] else "no ") + Fases.NOME[m]]

# ------------------------------------------------------------------ ícones em pixel
## Desenha uma arte de letras: cada letra é uma célula `cel` x `cel`; runs da mesma cor viram um retângulo só.
static func arte(c: CanvasItem, linhas: Array, pos: Vector2, cel: float, cinza: bool = false, alfa: float = 1.0) -> void:
	for y in linhas.size():
		var ln: String = linhas[y]
		var x: int = 0
		while x < ln.length():
			var ch: String = ln[x]
			if ch == ".":
				x += 1
				continue
			var x2: int = x
			while x2 + 1 < ln.length() and ln[x2 + 1] == ch:
				x2 += 1
			var cor: Color = PALETA[ch]
			if cinza:
				var g: float = (cor.r + cor.g + cor.b) / 3.0 * 0.7
				cor = Color(g, g, g)
			cor.a = alfa
			c.draw_rect(Rect2(pos.x + x * cel, pos.y + y * cel, (x2 - x + 1) * cel, cel), cor)
			x = x2 + 1

static func icone_melhoria(c: CanvasItem, m: int, pos: Vector2, cel: float, cinza: bool = false) -> void:
	arte(c, ICO_MELHORIA[m], pos, cel, cinza)

static func icone_modulo(c: CanvasItem, m: int, pos: Vector2, cel: float, cinza: bool = false, alfa: float = 1.0) -> void:
	arte(c, ICO_MODULO[m], pos, cel, cinza, alfa)

## Troféu de 10 x 10 células (com cel = 2, mede 20 x 20).
static func trofeu(c: CanvasItem, pos: Vector2, cel: float, alfa: float = 1.0) -> void:
	arte(c, ICO_TROFEU, pos, cel, false, alfa)

static func cadeado(c: CanvasItem, centro: Vector2, cor: Color) -> void:
	c.draw_arc(centro + Vector2(0, -2), 4.5, PI, TAU, 8, cor, 2.0)
	c.draw_rect(Rect2(centro.x - 6, centro.y - 2, 12, 9), cor)
	c.draw_rect(Rect2(centro.x - 1, centro.y + 1, 2, 4), Color(0.2, 0.12, 0.1))

static func seta(c: CanvasItem, pos: Vector2, cor: Color) -> void:
	c.draw_rect(Rect2(pos.x, pos.y + 3, 11, 4), cor)
	c.draw_colored_polygon(PackedVector2Array([pos + Vector2(10, 0), pos + Vector2(18, 5), pos + Vector2(10, 10)]), cor)

const SETA_W := 18.0

# ------------------------------------------------------------------ abrir, fechar, montar
func abrir() -> void:
	if aberta or dono == null:
		return
	aberta = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	abrir_t = 0.0
	anim.clear()
	faiscas.limpar()
	tr_exib = float(dono.estado.trofeus)
	pulso_tr = 0.0
	compra_t = [9.0, 9.0, 9.0, 9.0]
	mont_t.clear()
	treme.clear()
	prev_pulso = 0.0
	Som.tocar("abrir")
	aviso = ""
	aviso_t = 0.0
	apertado_id = ""
	flash_t = 0.0
	if dono.menus != null:
		dono.menus.dica_cumprida("trofeu")
	_montar()
	foco = _foco_inicial()
	_foco_som = foco
	queue_redraw()

func fechar() -> void:
	if not aberta:
		return
	aberta = false
	visible = false
	Som.tocar("fechar")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	apertado_id = ""
	itens.clear()

func _foco_inicial() -> int:
	var e: Estado = dono.estado
	for k in itens.size():
		var id: String = itens[k]["id"]
		if id.begins_with("m") and itens[k]["on"]:
			return k
	for k in itens.size():
		var id: String = itens[k]["id"]
		if id.begins_with("d") and not e.tem_modulo(int(id.substr(1))) and e.modulos.size() < Torre.MODULOS_EQUIPADOS_MAX:
			return k
	return itens.size() - 1

func _montar() -> void:
	var id_foco: String = ""
	if foco >= 0 and foco < itens.size():
		id_foco = itens[foco]["id"]
	var e: Estado = dono.estado
	itens.clear()
	for m in Torre.MELHORIA_NOME.size():
		var maximo: bool = e.melhorias[m] >= Torre.MELHORIA_NIVEL_MAX
		itens.append({"id": "m%d" % m, "r": rect_melhorar(m), "on": e.pode_melhorar(m), "txt": "Máximo" if maximo else "Melhorar (%d)" % Torre.MELHORIA_CUSTO,
			"cor": Color(1.0, 0.82, 0.4), "tam": 16, "custo": not maximo})
	for m in Torre.MODULO_NOME.size():
		if not e.modulo_liberado(m):
			continue
		var monta: bool = e.tem_modulo(m)
		var cheio: bool = not monta and e.modulos.size() >= Torre.MODULOS_EQUIPADOS_MAX
		var cor: Color = Color(0.95, 0.55, 0.4) if monta else (Color(0.55, 0.65, 0.55) if cheio else Color(0.55, 0.9, 0.5))
		itens.append({"id": "d%d" % m, "r": rect_btn_modulo(m), "on": true, "txt": "Desmontar" if monta else "Montar", "cor": cor, "tam": 16, "custo": false})
	itens.append({"id": "fechar", "r": BTN_FECHAR, "on": true, "txt": "Fechar", "cor": UIComum.B_MARROM, "tam": 22, "custo": false})
	foco = itens.size() - 1
	for k in itens.size():
		if itens[k]["id"] == id_foco:
			foco = k

func _item_em(p: Vector2) -> int:
	for k in itens.size():
		if (itens[k]["r"] as Rect2).has_point(p):
			return k
	return -1

# ------------------------------------------------------------------ ações
func acionar(id: String) -> void:
	if not aberta:
		return
	var e: Estado = dono.estado
	if id == "fechar" or id == "x":
		Som.tocar("clique")
		fechar()
		return
	if id.begins_with("m"):
		var m: int = int(id.substr(1))
		var antes: Array = valores(m, e.melhorias[m])
		if e.melhorar(m):
			flash_id = id
			flash_t = 0.5
			_avisar("")
			# retorno forte: troféus voam do contador ao botão; ao chegarem, o quadradinho enche e o valor conta
			compra_ant[m] = antes
			compra_t[m] = -0.5
			pulso_tr = 1.0
			faiscas.voar(centro_cont, rect_melhorar(m).get_center(), 4, 0.42)
			Som.tocar("promover")
		else:
			var mot: String = motivo_melhoria(e, m)
			_avisar("%s já está no nível máximo" % Torre.MELHORIA_NOME[m] if mot == "Máximo" else "%s: %s para melhorar" % [Torre.MELHORIA_NOME[m], mot.to_lower()])
			_recusar(id)
	elif id.begins_with("d"):
		var m: int = int(id.substr(1))
		if e.tem_modulo(m):
			e.alternar_modulo(m)
			_avisar("")
			mont_t[m] = 0.0
			prev_pulso = 0.6
			Som.tocar("aba", 0.85)
		elif not e.modulo_liberado(m):
			_avisar(requisito_modulo(m))
			_recusar(id)
		elif e.modulos.size() >= Torre.MODULOS_EQUIPADOS_MAX:
			_avisar("Desmonte um módulo primeiro")
			_recusar(id)
		else:
			e.alternar_modulo(m)
			_avisar("")
			mont_t[m] = 0.0
			prev_pulso = 1.0
			var cr: Rect2 = rect_card(m)
			faiscas.emitir(Vector2(cr.position.x + 36.0, cr.get_center().y), 16, UIComum.FAISCA_COR, 190.0, 0.7)
			Som.tocar("promover", 1.1)
	_montar()

func _recusar(id: String) -> void:
	treme[id] = 0.34
	UIComum.som_negado()

func _avisar(txt: String) -> void:
	aviso = txt
	aviso_t = 3.0 if txt != "" else 0.0

# ------------------------------------------------------------------ entrada
func _gui_input(ev: InputEvent) -> void:
	if not aberta:
		return
	if ev is InputEventMouseMotion:
		x_sobre = BTN_X.has_point((ev as InputEventMouseMotion).position)
		var i: int = _item_em((ev as InputEventMouseMotion).position)
		if i >= 0:
			foco = i
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if BTN_X.has_point(mb.position):
			x_press = mb.pressed
			if not mb.pressed:
				acionar("x")
			return
		x_press = false
		var i: int = _item_em(mb.position)
		if mb.pressed:
			apertado_id = itens[i]["id"] if i >= 0 else ""
			apertado_fora = i < 0 and not PAINEL.has_point(mb.position)
			if i >= 0:
				foco = i
		else:
			var antes: String = apertado_id
			var fora: bool = apertado_fora
			apertado_id = ""
			apertado_fora = false
			if i >= 0 and itens[i]["id"] == antes:
				acionar(antes)
			elif i < 0 and fora and not PAINEL.has_point(mb.position):
				fechar()   # clicou (e soltou) fora da moldura

func _input(ev: InputEvent) -> void:
	if not aberta or not (ev is InputEventKey):
		return
	var k: InputEventKey = ev as InputEventKey
	if not k.pressed or k.echo:
		return
	if tecla(k.keycode):
		get_viewport().set_input_as_handled()

## Teclado: setas e WASD movem o foco, Enter/Espaço acionam, Esc fecha. Devolve true se a tecla foi usada.
func tecla(kc: int) -> bool:
	if not aberta:
		return false
	match kc:
		KEY_ESCAPE:
			fechar()
		KEY_UP, KEY_W:
			_mover(Vector2i(0, -1))
		KEY_DOWN, KEY_S:
			_mover(Vector2i(0, 1))
		KEY_LEFT, KEY_A:
			_mover(Vector2i(-1, 0))
		KEY_RIGHT, KEY_D:
			_mover(Vector2i(1, 0))
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if foco >= 0 and foco < itens.size():
				acionar(itens[foco]["id"])
		_:
			return false
	return true

## Move o foco para o botão mais próximo na direção `d` (mesma coluna pesa mais que a distância).
func _mover(d: Vector2i) -> void:
	if itens.is_empty():
		return
	var c: Vector2 = (itens[foco]["r"] as Rect2).get_center()
	var melhor: int = -1
	var melhor_s: float = INF
	for j in itens.size():
		if j == foco:
			continue
		var dc: Vector2 = (itens[j]["r"] as Rect2).get_center() - c
		var ao_longo: float = dc.x * d.x + dc.y * d.y
		if ao_longo <= 4.0:
			continue
		var de_lado: float = absf(dc.x * d.y) + absf(dc.y * d.x)
		var s: float = ao_longo + de_lado * 2.5
		if s < melhor_s:
			melhor_s = s
			melhor = j
	if melhor >= 0:
		foco = melhor

func _process(delta: float) -> void:
	t += delta
	if not aberta:
		return
	abrir_t += delta
	aviso_t = maxf(0.0, aviso_t - delta)
	flash_t = maxf(0.0, flash_t - delta)
	pulso_tr = maxf(0.0, pulso_tr - delta * 3.0)
	prev_pulso = maxf(0.0, prev_pulso - delta * 1.6)
	tr_exib = UIComum.contar(tr_exib, float(dono.estado.trofeus), delta)
	UIComum.anim_passo(anim, "x", x_sobre, x_sobre and x_press, delta)
	for i in itens.size():
		var id: String = itens[i]["id"]
		var sobre: bool = i == foco
		UIComum.anim_passo(anim, id, sobre, sobre and apertado_id == id, delta)
	if foco != _foco_som:
		if foco >= 0 and foco < itens.size() and abrir_t > 0.1:
			UIComum.som_hover()
		_foco_som = foco
	for k in treme.keys():
		treme[k] = float(treme[k]) - delta
		if float(treme[k]) <= 0.0:
			treme.erase(k)
	for k in mont_t.keys():
		mont_t[k] = float(mont_t[k]) + delta
	for m in compra_t.size():
		if compra_t[m] < 9.0:
			var antes: float = compra_t[m]
			compra_t[m] += delta
			if antes < 0.0 and compra_t[m] >= 0.0:
				# os troféus chegaram: o quadradinho enche com estouro de faíscas
				var n: int = dono.estado.melhorias[m]
				var q: Rect2 = rect_quadrado(m, clampi(n - 1, 0, Torre.MELHORIA_NIVEL_MAX - 1))
				faiscas.emitir(q.get_center(), 20, UIComum.FAISCA_COR, 200.0, 0.75)
				faiscas.emitir(rect_melhorar(m).get_center(), 8, UIComum.FAISCA_COR, 120.0, 0.5)
				prev_pulso = 1.0
				prev_recuo = 1.0
				Som.tocar("nivel")
	prev_recuo = maxf(0.0, prev_recuo - delta * 2.5)
	faiscas.passo(delta)
	queue_redraw()

# ------------------------------------------------------------------ pintura
func _nove(src: Rect2, dst: Rect2, esc: float, cor: Color, miolo: bool, tex: Texture2D, m: Vector4) -> void:
	dono.nove(self, tex, src, m, dst, esc, cor, miolo)

func _texto(txt: String, pos: Vector2, tam: int, cor: Color, larg: float = -1.0, contorno: int = 0) -> void:
	Desenho.texto(self, txt, pos, tam, cor, larg, contorno)

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

## Maior tamanho da lista em que o texto cabe em `larg`.
static func tam_cabe(txt: String, tams: Array, larg: float) -> int:
	for tm in tams:
		if largura(txt, int(tm)) <= larg:
			return int(tm)
	return int(tams[tams.size() - 1])

func _draw() -> void:
	if not aberta or dono == null:
		return
	var e: Estado = dono.estado
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.74 * minf(1.0, abrir_t / 0.12)))
	UIComum.ini_pop(self, PAINEL.get_center(), UIComum.pop(abrir_t))
	draw_rect(PAINEL.grow(-18.0), COR_FUNDO)
	draw_rect(PAINEL.grow(-30.0), Color(0, 0, 0, 0.18), false, 2.0)
	_nove(R_MADEIRA, PAINEL, 0.75, Color.WHITE, false, GUI_TEX, M_MADEIRA)
	UIComum.titulo(self, "Oficina da torre", 640.0, 76.0, 34, COR_OURO, Color(0.16, 0.07, 0.05, 0.95), t, false)
	# troféus em destaque: contam até o valor
	centro_cont = UIComum.contador_trofeus(self, 640.0, 88.0, int(round(tr_exib)), pulso_tr)
	if aviso == "" or aviso_t <= 0.0:
		_texto(explicacao_trofeus(), Vector2(PAINEL.position.x, 148), 16, Color(1, 1, 1, 0.8), PAINEL.size.x, 3)
	_previa_torre(e)
	# cabeçalhos das colunas
	_texto("Melhorias da torre", Vector2(COL_E_X, 172), 18, COR_TINTA, -1.0, 4)
	_texto("Módulos montados: %d de %d" % [e.modulos.size(), Torre.MODULOS_EQUIPADOS_MAX], Vector2(COL_D_X, 172), 18, COR_TINTA, -1.0, 4)
	draw_line(Vector2(COL_E_X, 177), Vector2(COL_E_X + COL_E_W, 177), Color(1, 1, 1, 0.16), 1.0)
	draw_line(Vector2(COL_D_X, 177), Vector2(COL_D_X + COL_D_W, 177), Color(1, 1, 1, 0.16), 1.0)
	for m in Torre.MELHORIA_NOME.size():
		UIComum.ini_cascata(self, UIComum.cascata(abrir_t, m), -1.0)
		_linha_melhoria(e, m)
		UIComum.fim_cascata(self)
	for m in Torre.MODULO_NOME.size():
		UIComum.ini_cascata(self, UIComum.cascata(abrir_t, m + 2), 1.0)
		var sc: float = 1.0
		if mont_t.has(m) and float(mont_t[m]) < 0.34:
			sc = 1.0 + 0.07 * sin(float(mont_t[m]) / 0.34 * PI)   # o módulo montado encaixa com um salto
		if sc != 1.0:
			var cc: Vector2 = rect_card(m).get_center()
			var base_ant: Transform2D = UIComum.base
			draw_set_transform_matrix(base_ant * Transform2D(0.0, Vector2(sc, sc), 0.0, cc * (1.0 - sc)))
			_card_modulo(e, m)
			draw_set_transform_matrix(base_ant)
		else:
			_card_modulo(e, m)
		UIComum.fim_cascata(self)
	# aviso curto (sobe no lugar da explicação dos troféus) e dica de teclado
	if aviso != "" and aviso_t > 0.0:
		UIComum.aviso(self, aviso, 640.0, 134.0, clampf(aviso_t / 0.5, 0.0, 1.0), UIComum.C_NOME)
	_texto("Setas e Enter  |  Esc fecha", Vector2(COL_E_X, 652), 13, Color(1, 1, 1, 0.45), -1.0, 3)
	for k in itens.size():
		_botao(k)
	UIComum.fechar(self, BTN_X, {"on": true, "foco": x_sobre, "h": UIComum.anim_h(anim, "x"), "p": UIComum.anim_p(anim, "x")}, t)
	faiscas.desenhar(self)
	UIComum.fim_pop(self)

## Prévia pequena da torre no canto do cabeçalho: mostra, ao vivo, o que a compra ou a montagem mudou.
func _previa_torre(e: Estado) -> void:
	var cx := Rect2(128.0, 42.0, 156.0, 120.0)
	draw_rect(cx, Color(0.08, 0.05, 0.07))
	draw_rect(cx, Color(1, 0.85, 0.5, 0.35), false, 2.0)
	draw_rect(Rect2(cx.position.x + 2.0, cx.end.y - 22.0, cx.size.x - 4.0, 20.0), Color(0.2, 0.14, 0.1))
	_texto("Sua torre", Vector2(cx.position.x + 8.0, cx.position.y + 15.0), 12, Color(1, 1, 1, 0.7), -1.0, 3)
	var esc: float = 0.4
	var prev_base := Vector2(cx.position.x + 26.0, cx.end.y - 8.0)
	var base_ant: Transform2D = UIComum.base
	draw_set_transform_matrix(base_ant * Transform2D(0.0, Vector2(esc, esc), 0.0, prev_base))
	TorrePx.desenhar(self, Vector2.ZERO, e.tijolos_max(), e.tijolos_max(), e.melhorias, e.modulos, t, 0.0, {"luta": false, "pulso": prev_pulso, "recuo": prev_recuo, "vigia": true})
	draw_set_transform_matrix(base_ant)
	if prev_pulso > 0.0:
		draw_rect(cx, Color(1.0, 0.92, 0.5, 0.25 * prev_pulso), false, 3.0)

static func explicacao_trofeus() -> String:
	return "Chefes dão %d, bichos fantasiados dão %d" % [Torre.TROFEU_CHEFE, Torre.TROFEU_ELITE]

func _linha_melhoria(e: Estado, m: int) -> void:
	var r: Rect2 = rect_linha(m)
	var n: int = e.melhorias[m]
	var maximo: bool = n >= Torre.MELHORIA_NIVEL_MAX
	var pode: bool = e.pode_melhorar(m)
	var n_exib: int = n - (1 if compra_t[m] < 0.0 else 0)   # o nível novo só enche quando os troféus chegam
	draw_rect(r, Color(0.27, 0.18, 0.1, 0.95) if pode else Color(0.2, 0.12, 0.1, 0.92))
	draw_rect(r, Color(1.0, 0.82, 0.3, 0.55) if pode else Color(1, 1, 1, 0.14), false, 2.0)
	if flash_id == "m%d" % m and flash_t > 0.0:
		draw_rect(r, Color(1.0, 0.9, 0.5, 0.45 * flash_t / 0.5))
	var box := Rect2(r.position.x + 10.0, r.position.y + 18.0, 64.0, 64.0)
	draw_rect(box, Color(0.08, 0.05, 0.07))
	draw_rect(box, Color(1, 0.85, 0.5, 0.35), false, 2.0)
	icone_melhoria(self, m, box.position + Vector2(8, 8), 4.0)
	var x: float = r.position.x + TEXTO_DESLOC
	_texto(Torre.MELHORIA_NOME[m], Vector2(x, r.position.y + 30.0), 22, COR_TINTA, -1.0, 4)
	for k in Torre.MELHORIA_NIVEL_MAX:
		var q: Rect2 = rect_quadrado(m, k)
		var cheio: bool = k < n_exib
		var novo: bool = cheio and k == n_exib - 1 and compra_t[m] >= 0.0 and compra_t[m] < 0.5
		if novo:
			q = q.grow(5.0 * sin(compra_t[m] / 0.5 * PI))   # estufa e assenta
		draw_rect(q, Color(0.07, 0.04, 0.06))
		draw_rect(q.grow(-2.0), Color(1.0, 0.82, 0.25) if cheio else Color(0.25, 0.18, 0.16))
		if cheio:
			draw_rect(Rect2(q.position.x + 2.0, q.position.y + 2.0, q.size.x - 4.0, 4.0), Color(1.0, 0.96, 0.7))
		if novo:
			draw_rect(q, Color(1, 1, 1, 0.8 * (1.0 - compra_t[m] / 0.5)))
		elif not cheio and k == n_exib and pode:
			var pu: float = 0.5 + 0.5 * sin(t * 5.0)
			draw_rect(q, Color(1.0, 0.82, 0.3, 0.4 + 0.5 * pu), false, 2.0)
	# valor de hoje e do próximo nível
	var v: Array = _valores_exib(m, n)
	var lw: float = larg_texto_linha()
	var y: float = r.position.y + 58.0
	if maximo:
		_texto("%s: %s (máximo)" % [v[0], v[1]], Vector2(x, y), tam_cabe("%s: %s (máximo)" % [v[0], v[1]], [17, 16, 15, 14, 13], lw), Color(0.7, 1.0, 0.75), -1.0, 3)
	else:
		var a: String = "%s: %s" % [v[0], v[1]]
		var b: String = v[2]
		var tm: int = tam_cabe(a + "    " + b, [17, 16, 15, 14, 13], lw - SETA_W - 12.0 + 8.0)
		_texto(a, Vector2(x, y), tm, COR_TINTA, -1.0, 3)
		var xa: float = x + largura(a, tm) + 6.0
		seta(self, Vector2(xa, y - 11.0), Color(1.0, 0.82, 0.3))
		_texto(b, Vector2(xa + SETA_W + 6.0, y), tm, Color(0.7, 1.0, 0.75), -1.0, 3)
	_texto(_maiuscula(Torre.melhoria_dica(m)), Vector2(x, r.position.y + 78.0), 13, Color(1, 1, 1, 0.65), -1.0, 3)
	if m == Torre.Melhoria.ESTRUTURA:
		_texto("Vale a partir do próximo cômodo", Vector2(x, r.position.y + 94.0), 12, Color(0.6, 0.85, 1.0, 0.8), -1.0, 3)
	# o porquê do botão apagado
	var mot: String = motivo_melhoria(e, m)
	if mot != "" and not maximo:
		var br: Rect2 = rect_melhorar(m)
		_texto(mot, Vector2(br.position.x, br.end.y + 20.0), 13, Color(1.0, 0.6, 0.5), br.size.x, 3)

## Valores mostrados: logo depois da compra, o número conta do antigo ao novo.
func _valores_exib(m: int, n: int) -> Array:
	var v: Array = valores(m, n)
	var ant: Array = compra_ant[m]
	if ant.is_empty() or compra_t[m] >= 0.7:
		return v
	if compra_t[m] < 0.0:
		return ant
	var k: float = compra_t[m] / 0.7
	return [v[0], _interp(str(ant[1]), str(v[1]), k), _interp(str(ant[2]), str(v[2]), k)]

## Interpola o primeiro número de `a` até o de `b` mantendo o texto em volta (ex.: "+15%" -> "+30%").
static func _interp(a: String, b: String, k: float) -> String:
	var re := RegEx.new()
	re.compile("[0-9]+(?:[,.][0-9]+)?")
	var ma: RegExMatch = re.search(a)
	var mb: RegExMatch = re.search(b)
	if ma == null or mb == null:
		return b
	var va: float = ma.get_string().replace(",", ".").to_float()
	var vb: float = mb.get_string().replace(",", ".").to_float()
	var cur: float = lerpf(va, vb, k * k * (3.0 - 2.0 * k))
	var txt: String = ("%d" % int(round(cur))) if (not mb.get_string().contains(",") and not mb.get_string().contains(".")) else ("%.1f" % cur).replace(".", ",")
	return b.substr(0, mb.get_start()) + txt + b.substr(mb.get_end())

func _card_modulo(e: Estado, m: int) -> void:
	var r: Rect2 = rect_card(m)
	var lib: bool = e.modulo_liberado(m)
	var monta: bool = e.tem_modulo(m)
	var fundo: Color = Color(0.13, 0.09, 0.1, 0.92)
	var borda: Color = Color(1, 1, 1, 0.1)
	if monta:
		fundo = Color(0.3, 0.24, 0.1, 0.96)
		borda = Color(1.0, 0.85, 0.3, 0.95)
	elif lib:
		fundo = Color(0.2, 0.14, 0.11, 0.95)
		borda = Color(1, 1, 1, 0.2)
	draw_rect(r, fundo)
	draw_rect(r, borda, false, 2.0)
	var box := Rect2(r.position.x + 8.0, r.position.y + 12.0, 54.0, 54.0)
	draw_rect(box, Color(0.08, 0.05, 0.07))
	draw_rect(box, Color(1, 0.85, 0.5, 0.35 if lib else 0.12), false, 2.0)
	icone_modulo(self, m, box.position + Vector2(3, 3), 4.0, not lib, 1.0 if lib else 0.55)
	var x: float = r.position.x + 72.0
	var cor_nome: Color = COR_TINTA if lib else Color(1, 1, 1, 0.45)
	_texto(Torre.MODULO_NOME[m], Vector2(x, r.position.y + 24.0), 18, cor_nome, -1.0, 4 if lib else 0)
	var dica: Array[String] = _quebrar_estatico(Torre.MODULO_DICA[m], 13, larg_texto_card(lib))
	var cor_dica: Color = Color(1, 1, 1, 0.8) if lib else Color(1, 1, 1, 0.38)
	for k in mini(dica.size(), 3 if lib else 2):
		_texto(dica[k], Vector2(x, r.position.y + 42.0 + 15.0 * k), 13, cor_dica)
	if monta:
		var tag := Rect2(x + largura(Torre.MODULO_NOME[m], 18) + 10.0, r.position.y + 9.0, 70.0, 20.0)
		draw_rect(tag, Color(1.0, 0.82, 0.25))
		_texto("Montado", Vector2(tag.position.x, tag.position.y + 15.0), 13, Color(0.22, 0.12, 0.06), tag.size.x)
	if not lib:
		var yq: float = r.position.y + 72.0
		cadeado(self, Vector2(x + 6.0, yq - 5.0), Color(0.85, 0.78, 0.9))
		_texto(requisito_modulo(m), Vector2(x + 20.0, yq), 13, Color(1.0, 0.85, 0.55), -1.0, 3)

## Mesma quebra de linhas do `principal.gd`, sem depender dele (para os testes de medida).
static func _quebrar_estatico(txt: String, tam: int, larg: float) -> Array[String]:
	var res: Array[String] = []
	var atual: String = ""
	for palavra in txt.split(" "):
		var tent: String = palavra if atual == "" else atual + " " + palavra
		if atual != "" and largura(tent, tam) > larg:
			res.append(atual)
			atual = palavra
		else:
			atual = tent
	if atual != "":
		res.append(atual)
	return res

func _botao(i: int) -> void:
	var b: Dictionary = itens[i]
	var r: Rect2 = b["r"]
	var id: String = b["id"]
	var sobre: bool = i == foco
	# ao entrar, os botões da lista acompanham a cascata das linhas
	var kc: float = 1.0
	var lado: float = -1.0
	if id.begins_with("m"):
		kc = UIComum.cascata(abrir_t, int(id.substr(1)))
	elif id.begins_with("d"):
		kc = UIComum.cascata(abrir_t, int(id.substr(1)) + 2)
		lado = 1.0
	r.position.x += lado * 46.0 * (1.0 - kc) * (1.0 - kc)
	if treme.has(id):
		r.position.x += roundf(sin(float(treme[id]) * 50.0) * 5.0)
	var o: Dictionary = {"on": b["on"], "foco": sobre, "h": UIComum.anim_h(anim, id), "p": UIComum.anim_p(anim, id), "tam": b["tam"]}
	if b["custo"]:
		o["trofeu"] = true
	if id == "x":
		UIComum.fechar(self, r, o, t)
	else:
		UIComum.botao(self, r, b["txt"], b["cor"], o, t)
