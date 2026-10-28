class_name AteliePintor
extends Control
## Pintor do Ateliê: o jogador repinta pixel a pixel as 4 peças da fantasia criada. Abre por cima da tela do Ateliê
## (AtelieTela) e mexe só no rascunho dela (AtelieTela.pint); quem grava é "Salvar a fantasia", como as outras escolhas.
## A grade parte da "foto" da forma escolhida, com a cor e a estampa (AtelieArte.fotografar). Botão esquerdo usa a
## ferramenta, o direito apaga. Peça com camada atrás do corpo (capa) tem as duas camadas; pintar vai para a escolhida.

const PAINEL := Rect2(90, 20, 1100, 680)
const AREA := Rect2(124, 146, 500, 470)
const PREVIA := Rect2(660, 146, 496, 206)
const COR_TINTA := Color(1.0, 0.94, 0.8)
const COR_FUNDO := Color(0.14, 0.09, 0.12, 0.98)
const COR_OURO := Color(1.0, 0.82, 0.2)
const BTN_X := Rect2(1124.0, 38.0, 42.0, 42.0)
const BTN_PRONTO := Rect2(520, 636, 240, 40)
const SW := 28.0       # amostra de cor
const SW_GAP := 3.0
const PAL_Y := 466.0
const DESFAZER_MAX := 40
## Paleta fixa: tons de cinza, de pele/terra e o arco-íris em claro e escuro.
const PALETA: Array[Color] = [
	Color("101018"), Color("3a3a48"), Color("6e6e7e"), Color("a8a8b8"), Color("e8e8f0"), Color("ffffff"),
	Color("4a2a1a"), Color("8a5a3a"), Color("c89060"), Color("f0d0a0"),
	Color("7a1a24"), Color("d83a3a"), Color("ff8a8a"), Color("a84a10"), Color("f08a20"), Color("ffc860"),
	Color("a88a10"), Color("f0d830"), Color("2a6a1a"), Color("4ab83a"), Color("a0f080"), Color("1a6a6a"),
	Color("30c0c0"), Color("1a3a8a"), Color("3a7af0"), Color("90c0ff"), Color("4a2a8a"), Color("8a4af0"),
	Color("c0a0ff"), Color("8a1a6a"), Color("e04ab0"), Color("ffa0e0"),
]
const PALETA_COLS := 16

enum Ferr { LAPIS, BORRACHA, BALDE, CONTA_GOTAS }

var tela: Node = null           # AtelieTela (dona do rascunho)
var aberto: bool = false
var slot: int = 0
var grades: Array = [{}, {}, {}, {}]   # grade de trabalho por espaço (Atelie.grade_*)
var desfazer: Array = []        # [espaço, grade antes, pintura antes]
var ferr: int = Ferr.LAPIS
var cor: Color = Color("d83a3a")
var camada: String = "frente"
var pintando: int = 0           # 0 nada; 1 ferramenta (botão esquerdo); 2 apagando (botão direito)
var mouse: Vector2 = Vector2(-100, -100)
var t: float = 0.0
var abrir_t: float = 0.0
var itens: Array[Dictionary] = []
var anim: Dictionary = {}
var apertado_id: String = ""
var x_sobre: bool = false
var cores_peca: Array[Color] = []

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

# ------------------------------------------------------------------ abrir e fechar
func abrir(dona: Node, s: int = 0) -> void:
	tela = dona
	aberto = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	abrir_t = 0.0
	desfazer.clear()
	pintando = 0
	for k in Pecas.SLOTS:
		grades[k] = {}
	Som.tocar("abrir")
	_escolher(s)

func fechar() -> void:
	if not aberto:
		return
	aberto = false
	visible = false
	pintando = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Som.tocar("fechar")
	if tela != null and tela.has_method("pintor_fechou"):
		tela.pintor_fechou()

func tipo_atual() -> int:
	return Pecas.Tipo.ATELIE_CABECA + slot

## A peça tem camada atrás do corpo (capa, aljava)?
func tem_atras() -> bool:
	return RoupaGato.tem_atras(Atelie.forma(tipo_atual()))

## Grade do espaço `s`: a pintura do rascunho ou, sem ela, a foto da forma.
func _grade(s: int) -> Dictionary:
	if (grades[s] as Dictionary).is_empty():
		var p: Dictionary = tela.pint[s]
		grades[s] = Atelie.grade_da_pintura(p) if not p.is_empty() else AtelieArte.fotografar(Pecas.Tipo.ATELIE_CABECA + s)
	return grades[s]

func _escolher(s: int) -> void:
	slot = clampi(s, 0, Pecas.SLOTS - 1)
	pintando = 0
	if not tem_atras():
		camada = "frente"
	# cores da forma (sem pintura), para o jogador voltar a elas
	cores_peca.clear()
	var foto: Dictionary = AtelieArte.fotografar(tipo_atual())
	for k in ["frente", "atras"]:
		for c in (foto[k] as PackedColorArray):
			if c.a > 0.02 and not cores_peca.has(c) and cores_peca.size() < PALETA_COLS:
				cores_peca.append(c)
	_grade(slot)
	_montar()

# ------------------------------------------------------------------ geometria
## Tamanho do pixel da grade na tela.
func celula() -> float:
	var g: Dictionary = _grade(slot)
	return clampf(floorf(minf(AREA.size.x / float(g["w"]), AREA.size.y / float(g["h"]))), 4.0, 28.0)

func rect_grade() -> Rect2:
	var g: Dictionary = _grade(slot)
	var cel: float = celula()
	var sz := Vector2(float(g["w"]) * cel, float(g["h"]) * cel)
	return Rect2((AREA.position + (AREA.size - sz) * 0.5).floor(), sz)

## Célula da grade sob o ponto (-1, -1 fora).
func celula_em(p: Vector2) -> Vector2i:
	var r: Rect2 = rect_grade()
	if not r.has_point(p):
		return Vector2i(-1, -1)
	var cel: float = celula()
	return Vector2i(int((p.x - r.position.x) / cel), int((p.y - r.position.y) / cel))

static func rect_amostra(i: int) -> Rect2:
	return Rect2(PREVIA.position.x + (i % PALETA_COLS) * (SW + SW_GAP), PAL_Y + (i / PALETA_COLS) * (SW + SW_GAP), SW, SW)

func rect_amostra_peca(i: int) -> Rect2:
	return Rect2(PREVIA.position.x + i * (SW + SW_GAP), PAL_Y + 2.0 * (SW + SW_GAP) + 26.0, SW, SW)

const RECT_COR_ATUAL := Rect2(1100, 402, 52, 52)

# ------------------------------------------------------------------ botões
func _montar() -> void:
	itens.clear()
	for s in Pecas.SLOTS:
		itens.append({"id": "s%d" % s, "r": Rect2(124 + s * 126, 98, 120, 36), "txt": Idioma.t(Pecas.SLOT_NOME[s]), "cor": UIComum.B_LARANJA, "tam": 16, "marcado": s == slot})
	var nomes: Array[String] = [Idioma.t("Lápis"), Idioma.t("Borracha"), Idioma.t("Balde"), Idioma.t("Conta-gotas")]
	for k in 4:
		itens.append({"id": "f%d" % k, "r": Rect2(PREVIA.position.x + k * 108, 362, 102, 34), "txt": "%d %s" % [k + 1, nomes[k]], "cor": UIComum.B_AZUL, "tam": 14, "marcado": k == ferr})
	itens.append({"id": "desf", "r": Rect2(PREVIA.position.x, 406, 140, 34), "txt": Idioma.t("Desfazer (Z)"), "cor": UIComum.B_CINZA, "tam": 14, "on": not desfazer.is_empty()})
	if tem_atras():
		var txt_c: String = Idioma.t("Camada: frente (C)") if camada == "frente" else Idioma.t("Camada: atrás do corpo (C)")
		itens.append({"id": "cam", "r": Rect2(PREVIA.position.x + 148, 406, 236, 34), "txt": txt_c, "cor": UIComum.B_VERDE, "tam": 14})
	itens.append({"id": "limpar", "r": Rect2(PREVIA.position.x, 588, 180, 34), "txt": Idioma.t("Limpar tudo"), "cor": UIComum.B_VERMELHO, "tam": 14})
	itens.append({"id": "orig", "r": Rect2(PREVIA.position.x + 188, 588, 308, 34), "txt": Idioma.t("Voltar ao desenho da forma"), "cor": UIComum.B_MARROM, "tam": 14, "on": not (tela.pint[slot] as Dictionary).is_empty()})
	itens.append({"id": "pronto", "r": BTN_PRONTO, "txt": Idioma.t("Voltar ao Ateliê"), "cor": UIComum.B_VERDE, "tam": 17})

func _item_em(p: Vector2) -> int:
	for k in itens.size():
		if (itens[k]["r"] as Rect2).has_point(p):
			return k
	return -1

func acionar(id: String) -> void:
	match id:
		"pronto", "x":
			Som.tocar("clique")
			fechar()
			return
		"desf":
			_desfazer()
		"cam":
			camada = "atras" if camada == "frente" else "frente"
			Som.tocar("aba", 1.1)
		"limpar":
			_guardar_desfazer()
			var g: Dictionary = _grade(slot)
			for k in ["frente", "atras"]:
				var cs: PackedColorArray = g[k]
				cs.fill(Color(0, 0, 0, 0))
				g[k] = cs
			_gravar()
			Som.tocar("fechar", 1.2)
		"orig":
			_guardar_desfazer()
			grades[slot] = AtelieArte.fotografar(tipo_atual())
			tela.pint[slot] = {}
			tela.pintura_mudou()
			Som.tocar("aba", 0.9)
		_:
			if id.begins_with("s"):
				_escolher(int(id.substr(1)))
				Som.tocar("aba")
				return
			if id.begins_with("f"):
				ferr = int(id.substr(1))
				Som.tocar("clique", 1.1)
	_montar()

# ------------------------------------------------------------------ pintar
func _guardar_desfazer() -> void:
	var g: Dictionary = _grade(slot)
	desfazer.append([slot, g.duplicate(true), (tela.pint[slot] as Dictionary).duplicate(true)])
	if desfazer.size() > DESFAZER_MAX:
		desfazer.pop_front()

func _desfazer() -> void:
	if desfazer.is_empty():
		UIComum.som_negado()
		return
	var d: Array = desfazer.pop_back()
	var s: int = int(d[0])
	grades[s] = d[1]
	tela.pint[s] = d[2]
	tela.pintura_mudou()
	if s != slot:
		_escolher(s)
	Som.tocar("aba", 0.8)
	_montar()

## Leva a grade do espaço atual para o rascunho do Ateliê (a prévia, o ícone e o gato mudam na hora).
func _gravar() -> void:
	tela.pint[slot] = Atelie.pintura_da_grade(_grade(slot))
	tela.pintura_mudou()

func _cor_em(g: Dictionary, q: Vector2i) -> Color:
	var i: int = q.y * int(g["w"]) + q.x
	var cf: Color = (g["frente"] as PackedColorArray)[i]
	return cf if cf.a > 0.02 else (g["atras"] as PackedColorArray)[i]

## Aplica a ferramenta na célula `q` (apagar: tira das duas camadas). Devolve true se mudou algo.
func _aplicar_em(q: Vector2i, apagar: bool) -> bool:
	var g: Dictionary = _grade(slot)
	if q.x < 0 or q.y < 0 or q.x >= int(g["w"]) or q.y >= int(g["h"]):
		return false
	var i: int = q.y * int(g["w"]) + q.x
	if apagar or ferr == Ferr.BORRACHA:
		var mudou: bool = false
		for k in ["frente", "atras"]:
			var cs: PackedColorArray = g[k]
			if cs[i].a > 0.02:
				cs[i] = Color(0, 0, 0, 0)
				g[k] = cs
				mudou = true
		return mudou
	match ferr:
		Ferr.CONTA_GOTAS:
			var c: Color = _cor_em(g, q)
			if c.a > 0.02:
				cor = c
				ferr = Ferr.LAPIS
				Som.tocar("clique", 1.3)
				_montar()
			return false
		Ferr.BALDE:
			return _balde(g, q)
	var outra: String = "atras" if camada == "frente" else "frente"
	var cs2: PackedColorArray = g[camada]
	var co: PackedColorArray = g[outra]
	if cs2[i] == cor and co[i].a <= 0.02:
		return false
	cs2[i] = cor
	co[i] = Color(0, 0, 0, 0)   # um pixel fica numa camada só
	g[camada] = cs2
	g[outra] = co
	return true

## Balde: pinta a região contígua da mesma cor (vazio também é uma cor), na camada escolhida.
func _balde(g: Dictionary, q: Vector2i) -> bool:
	var w: int = int(g["w"])
	var h: int = int(g["h"])
	var alvo: Color = _cor_em(g, q)
	var vazio: bool = alvo.a <= 0.02
	if not vazio and alvo == cor:
		return false
	var outra: String = "atras" if camada == "frente" else "frente"
	var cs: PackedColorArray = g[camada]
	var co: PackedColorArray = g[outra]
	var visto: Dictionary = {}
	var fila: Array[Vector2i] = [q]
	while not fila.is_empty():
		var p: Vector2i = fila.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or visto.has(p):
			continue
		visto[p] = true
		var c: Color = _cor_em(g, p)
		if (c.a <= 0.02) != vazio or (not vazio and c != alvo):
			continue
		var i: int = p.y * w + p.x
		cs[i] = cor
		co[i] = Color(0, 0, 0, 0)
		fila.append_array([p + Vector2i.LEFT, p + Vector2i.RIGHT, p + Vector2i.UP, p + Vector2i.DOWN])
	g[camada] = cs
	g[outra] = co
	return true

func _traco(p: Vector2, apagar: bool) -> void:
	if _aplicar_em(celula_em(p), apagar):
		_gravar()

# ------------------------------------------------------------------ entrada
func _gui_input(ev: InputEvent) -> void:
	if not aberto:
		return
	if ev is InputEventMouseMotion:
		mouse = (ev as InputEventMouseMotion).position
		x_sobre = BTN_X.has_point(mouse)
		if pintando > 0:
			_traco(mouse, pintando == 2)
		accept_event()
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		mouse = mb.position
		accept_event()
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed and celula_em(mouse).x >= 0:
				_guardar_desfazer()
				pintando = 2
				_traco(mouse, true)
			elif not mb.pressed:
				pintando = 0
				_montar()
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			if celula_em(mouse).x >= 0:
				_guardar_desfazer()
				pintando = 1 if ferr != Ferr.BALDE and ferr != Ferr.CONTA_GOTAS else 0
				_traco(mouse, false)
				if pintando == 0:
					_montar()
				return
			for i in PALETA.size():
				if rect_amostra(i).has_point(mouse):
					_pegar_cor(PALETA[i])
					return
			for i in cores_peca.size():
				if rect_amostra_peca(i).has_point(mouse):
					_pegar_cor(cores_peca[i])
					return
			var k: int = _item_em(mouse)
			apertado_id = itens[k]["id"] if k >= 0 else ("x" if BTN_X.has_point(mouse) else "")
		else:
			if pintando > 0:
				pintando = 0
				_montar()
				return
			var k2: int = _item_em(mouse)
			var solto: String = itens[k2]["id"] if k2 >= 0 else ("x" if BTN_X.has_point(mouse) else "")
			if solto != "" and solto == apertado_id:
				var on: bool = k2 < 0 or itens[k2].get("on", true)
				if on:
					acionar(solto)
				else:
					UIComum.som_negado()
			apertado_id = ""

func _pegar_cor(c: Color) -> void:
	cor = c
	if ferr == Ferr.BORRACHA or ferr == Ferr.CONTA_GOTAS:
		ferr = Ferr.LAPIS
	Som.tocar("clique", 1.2)
	_montar()

func _input(ev: InputEvent) -> void:
	if not aberto or not (ev is InputEventKey):
		return
	var k: InputEventKey = ev as InputEventKey
	get_viewport().set_input_as_handled()   # aberto, o pintor fica com o teclado todo
	if not k.pressed or k.echo:
		return
	tecla(k.keycode)

func tecla(kc: int) -> bool:
	match kc:
		KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER:
			fechar()
		KEY_Z:
			_desfazer()
		KEY_1, KEY_2, KEY_3, KEY_4:
			ferr = kc - KEY_1
			Som.tocar("clique", 1.1)
			_montar()
		KEY_Q, KEY_LEFT:
			_escolher(posmod(slot - 1, Pecas.SLOTS))
			Som.tocar("aba")
		KEY_E, KEY_RIGHT, KEY_TAB:
			_escolher(posmod(slot + 1, Pecas.SLOTS))
			Som.tocar("aba")
		KEY_C:
			if tem_atras():
				acionar("cam")
		_:
			return false
	return true

func _process(delta: float) -> void:
	t += delta
	if not aberto:
		return
	abrir_t += delta
	UIComum.anim_passo(anim, "x", x_sobre, x_sobre and apertado_id == "x", delta)
	for it in itens:
		var id: String = it["id"]
		var sobre: bool = (it["r"] as Rect2).has_point(mouse)
		UIComum.anim_passo(anim, id, sobre, sobre and apertado_id == id, delta)
	queue_redraw()

# ------------------------------------------------------------------ desenho
func _texto(txt: String, pos: Vector2, tam: int, c: Color, larg: float = -1.0, contorno: int = 3) -> void:
	Desenho.texto(self, txt, pos, tam, c, larg, contorno)

func _draw() -> void:
	if not aberto or tela == null:
		return
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.5))
	UIComum.ini_pop(self, PAINEL.get_center(), UIComum.pop(abrir_t))
	draw_rect(PAINEL.grow(-18.0), COR_FUNDO)
	tela.dono.nove(self, AtelieTela.GUI_TEX, AtelieTela.R_MADEIRA, AtelieTela.M_MADEIRA, PAINEL, 0.75, Color.WHITE, false)
	UIComum.titulo(self, Idioma.t("Pintar as peças"), 640.0, 76.0, 34, COR_OURO, Color(0.16, 0.07, 0.05, 0.95), t, false)
	_grade_desenho()
	_lado_direito()
	for it in itens:
		var id: String = it["id"]
		var sobre: bool = (it["r"] as Rect2).has_point(mouse)
		var o: Dictionary = {"on": it.get("on", true), "foco": false, "h": UIComum.anim_h(anim, id), "p": UIComum.anim_p(anim, id), "tam": it["tam"], "marcado": it.get("marcado", false)}
		if sobre and pintando == 0:
			o["h"] = maxf(float(o["h"]), 0.5)
		UIComum.botao(self, it["r"], it["txt"], it["cor"], o, t)
	UIComum.fechar(self, BTN_X, {"on": true, "foco": x_sobre, "h": UIComum.anim_h(anim, "x"), "p": UIComum.anim_p(anim, "x")}, t)
	var ajuda: String = Idioma.t("Esquerdo pinta · direito apaga · Z desfaz · Esc volta")
	_texto(ajuda, Vector2(124, 630), Oficina.tam_cabe(ajuda, [13, 12, 11], 380.0), Color(1, 1, 1, 0.5), 380.0)
	var lembrete: String = Idioma.t("A pintura só fica na fantasia depois de \"Criar a fantasia\" no Ateliê.")   # o mesmo nome do botão
	if not tela.dono.estado.atelie.is_empty():
		lembrete = Idioma.t("A pintura só fica na fantasia depois de \"Salvar a fantasia\" no Ateliê.")
	_texto(lembrete, Vector2(124, 652), Oficina.tam_cabe(lembrete, [13, 12, 11], 380.0), Color(1, 0.85, 0.5, 0.7), 380.0)
	UIComum.fim_pop(self)

func _grade_desenho() -> void:
	var g: Dictionary = _grade(slot)
	var r: Rect2 = rect_grade()
	var cel: float = celula()
	var w: int = int(g["w"])
	var h: int = int(g["h"])
	# fundo xadrez (vazio)
	draw_rect(r.grow(3.0), Color(0.07, 0.04, 0.06))
	for iy in h:
		for ix in w:
			var claro: bool = (ix + iy) % 2 == 0
			draw_rect(Rect2(r.position + Vector2(ix, iy) * cel, Vector2(cel, cel)), Color(0.24, 0.2, 0.24) if claro else Color(0.19, 0.15, 0.19))
	# camada de trás (um pouco apagada quando se pinta a da frente) e a da frente
	var cs_a: PackedColorArray = g["atras"]
	var cs_f: PackedColorArray = g["frente"]
	for iy in h:
		for ix in w:
			var i: int = iy * w + ix
			var q := Rect2(r.position + Vector2(ix, iy) * cel, Vector2(cel, cel))
			if cs_a[i].a > 0.02:
				draw_rect(q, cs_a[i].darkened(0.25) if camada == "frente" else cs_a[i])
			if cs_f[i].a > 0.02:
				draw_rect(q, Color(cs_f[i].r, cs_f[i].g, cs_f[i].b, cs_f[i].a * (0.45 if camada == "atras" else 1.0)))
	# linhas da grade
	if cel >= 8.0:
		for ix in range(1, w):
			draw_rect(Rect2(r.position.x + ix * cel, r.position.y, 1.0, r.size.y), Color(0, 0, 0, 0.22))
		for iy in range(1, h):
			draw_rect(Rect2(r.position.x, r.position.y + iy * cel, r.size.x, 1.0), Color(0, 0, 0, 0.22))
	# ponto onde a peça se prende ao gato (origem)
	var o := Vector2(-int(g["x"]), -int(g["y"]))
	if o.x >= 0 and o.y >= 0 and o.x <= w and o.y <= h:
		var po: Vector2 = r.position + o * cel
		draw_rect(Rect2(po.x - 6.0, po.y - 1.0, 12.0, 2.0), Color(1, 0.85, 0.3, 0.7))
		draw_rect(Rect2(po.x - 1.0, po.y - 6.0, 2.0, 12.0), Color(1, 0.85, 0.3, 0.7))
	# célula sob o mouse
	var c: Vector2i = celula_em(mouse)
	if c.x >= 0:
		var qr := Rect2(r.position + Vector2(c) * cel, Vector2(cel, cel))
		if ferr == Ferr.LAPIS or ferr == Ferr.BALDE:
			draw_rect(qr.grow(-cel * 0.25), Color(cor.r, cor.g, cor.b, 0.8))
		draw_rect(qr, Color(1, 1, 1, 0.9), false, 2.0)

func _lado_direito() -> void:
	# prévia: o gato com a fantasia (com a pintura do rascunho)
	draw_rect(PREVIA, Color(0.08, 0.05, 0.07))
	draw_rect(PREVIA, Color(1, 0.85, 0.5, 0.35), false, 2.0)
	var cj: Color = Pecas.CONJUNTO_COR[Pecas.Conjunto.ATELIE]
	draw_rect(Rect2(PREVIA.position.x + 20.0, PREVIA.end.y - 34.0, 300.0, 4.0), Color(cj.r, cj.g, cj.b, 0.5))
	Desenho.boneco(self, Vector2(PREVIA.position.x + 160.0, PREVIA.end.y - 34.0), 2.6, 1.0, 0, tela.pecas_previa, 0.0, t, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, true, 0, false)
	var cx := Vector2(PREVIA.end.x - 70.0, PREVIA.position.y + 70.0)
	draw_rect(Rect2(cx - Vector2(44, 44), Vector2(88, 88)), Color(0.15, 0.1, 0.12))
	draw_rect(Rect2(cx - Vector2(44, 44), Vector2(88, 88)), Color(1, 1, 1, 0.14), false, 2.0)
	Desenho.icone(self, tipo_atual(), cx, 74.0)
	var nm: String = Idioma.t(Pecas.NOME[Atelie.forma(tipo_atual())])
	_texto(Fichario.cortar(nm, 13, 128.0), Vector2(cx.x - 64.0, cx.y + 66.0), 13, COR_TINTA, 128.0)
	# paleta
	_texto(Idioma.t("Cores"), Vector2(PREVIA.position.x, PAL_Y - 6.0), 15, COR_TINTA)
	for i in PALETA.size():
		_amostra(rect_amostra(i), PALETA[i])
	if not cores_peca.is_empty():
		_texto(Idioma.t("Cores da forma"), Vector2(PREVIA.position.x, PAL_Y + 2.0 * (SW + SW_GAP) + 20.0), 13, Color(1, 1, 1, 0.65))
		for i in cores_peca.size():
			_amostra(rect_amostra_peca(i), cores_peca[i])
	# cor atual
	draw_rect(RECT_COR_ATUAL.grow(3.0), Color(0.07, 0.04, 0.06))
	draw_rect(RECT_COR_ATUAL, cor)
	draw_rect(RECT_COR_ATUAL, Color(1, 1, 1, 0.5), false, 2.0)
	_texto(Idioma.t("Cor"), Vector2(RECT_COR_ATUAL.position.x - 46.0, RECT_COR_ATUAL.position.y + 32.0), 15, COR_TINTA)

func _amostra(r: Rect2, c: Color) -> void:
	var sob: bool = r.has_point(mouse)
	draw_rect(r.grow(2.0 if sob else 1.0), Color(0.07, 0.04, 0.06))
	draw_rect(r, c)
	if c == cor:
		draw_rect(r.grow(2.0), COR_OURO, false, 2.0)
	elif sob:
		draw_rect(r.grow(1.0), Color(1, 1, 1, 0.8), false, 1.0)
