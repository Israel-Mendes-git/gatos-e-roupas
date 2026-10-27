class_name AtelieTela
extends Control
## Ateliê: tela por cima do mapa e do guarda-roupa onde o jogador CRIA a própria fantasia (fase 1: catálogo).
## Escolhe forma e cor de cada peça, a estampa, 1 poder, 1 bônus de kit e o nome, sem orçamento
## (ver Atelie). A tela só mostra e pede: quem valida e grava é Atelie.confirmar. Mesmas molduras, fontes e botões da Oficina.

const GUI_TEX: Texture2D = preload("res://assets/terceiros/gui/gui_4x.png")
const R_MADEIRA := Rect2(8, 136, 80, 80)
const M_MADEIRA := Vector4(28, 28, 28, 28)
const COR_TINTA := Color(1.0, 0.94, 0.8)
const COR_FUNDO := Color(0.14, 0.09, 0.12, 0.98)
const COR_OURO := Color(1.0, 0.82, 0.2)
const COR_BOM := Color(0.7, 1.0, 0.75)
const COR_RUIM := Color(1.0, 0.6, 0.5)

const PAINEL := Rect2(90, 20, 1100, 680)
const COL_E_X := 124.0
const COL_E_W := 506.0
const COL_D_X := 654.0
const COL_D_W := 502.0
const LINHA_Y := 156.0
const LINHA_H := 62.0
const LINHA_GAP := 4.0
const SETA_W := 24.0
const SELETOR_W := 266.0   # largura das setas + nome da forma nas linhas com seletor de cor (peças e estampa)
const SELETOR_W_LARGO := 290.0   # poder e bônus: sem seletor de cor, o nome usa o espaço todo
const BTN_FECHAR := Rect2(668, 636, 200, 40)
const BTN_OK := Rect2(412, 636, 240, 40)
const BTN_X := Rect2(1124.0, 38.0, 42.0, 42.0)
const NOME_R := Rect2(654, 392, 330, 38)
const SUGERIR_R := Rect2(992, 392, 164, 38)
const PREVIA_R := Rect2(654, 156, 502, 228)
const PINTAR_R := Rect2(654, 588, 250, 36)

# ---- estado da tela ----
var dono: Variant = null
var aberta: bool = false
var itens: Array[Dictionary] = []
var foco: int = 0
var apertado_id: String = ""
var apertado_fora: bool = false
var t: float = 0.0
var aviso: String = ""
var aviso_t: float = 0.0
var anim: Dictionary = {}
var abrir_t: float = 0.0
var treme: Dictionary = {}
var x_sobre: bool = false
var x_press: bool = false
var _foco_som: int = -1
var digitando: bool = false
var _idioma_montado: String = ""
var rng := RandomNumberGenerator.new()

# ---- rascunho (o que o jogador está montando; só vira fantasia ao confirmar) ----
var formas_ok: Array = []     # por espaço: tipos que o jogador pode usar
var fi: Array[int] = [0, 0, 0, 0]
var mi: Array[int] = [0, 0, 0, 0]
var est: int = 0
var poderes_ok: Array[int] = []
var bonus_ok: Array[int] = []
var pi: int = 0
var bi: int = 0
var nome_txt: String = ""
var pecas_previa: Array = []
var pint: Array = [{}, {}, {}, {}]   # pintura de cada peça ({} = desenho da forma); quem mexe é o pintor
var pintor: AteliePintor = null

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	visible = false
	rng.randomize()

func iniciar(d: Variant) -> void:
	dono = d
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pintor = AteliePintor.new()
	add_child(pintor)

# ------------------------------------------------------------------ rascunho
func _carregar_rascunho() -> void:
	var e: Estado = dono.estado
	formas_ok.clear()
	for s in Pecas.SLOTS:
		formas_ok.append(Atelie.formas(e, s))
	poderes_ok = Atelie.poderes(e)
	bonus_ok = Atelie.bonus(e)
	var base: Dictionary = e.atelie if not e.atelie.is_empty() else Atelie.padrao()
	for s in Pecas.SLOTS:
		fi[s] = maxi(0, (formas_ok[s] as Array).find(int(base["formas"][s])))
		mi[s] = int(base["matizes"][s])
	est = int(base["estampa"])
	pi = maxi(0, poderes_ok.find(int(base["poder"])))
	bi = maxi(0, bonus_ok.find(int(base["bonus"])))
	nome_txt = str(base["nome"]) if not e.atelie.is_empty() else ""
	var ps: Array = base.get("pintura", [])
	for s in Pecas.SLOTS:
		pint[s] = (ps[s] as Dictionary).duplicate(true) if s < ps.size() and typeof(ps[s]) == TYPE_DICTIONARY else {}
	pecas_previa = []
	for s in Pecas.SLOTS:
		pecas_previa.append(Peca.new(Pecas.Tipo.ATELIE_CABECA + s))   # comum, como no fichário: a Rara põe a cintilação de raridade solta acima da prévia ampliada
	_aplicar()

func rascunho() -> Dictionary:
	var fs: Array = []
	var ms: Array = []
	for s in Pecas.SLOTS:
		fs.append(int((formas_ok[s] as Array)[fi[s]]))
		ms.append(mi[s])
	return {"nome": Atelie.limpar_nome(nome_txt), "formas": fs, "matizes": ms, "estampa": est,
		"poder": poderes_ok[pi], "bonus": bonus_ok[bi], "pintura": pint.duplicate(true)}

## Mostra o rascunho no gato e nas tabelas (nome e cor); fechar devolve o que está gravado.
func _aplicar() -> void:
	Atelie.aplicar(rascunho())

# ------------------------------------------------------------------ geometria
static func rect_linha(i: int) -> Rect2:
	var passo: float = LINHA_H + LINHA_GAP
	match i:
		4: return Rect2(COL_E_X, LINHA_Y + 4.0 * passo, COL_E_W, 40.0)
		5: return Rect2(COL_E_X, LINHA_Y + 4.0 * passo + 44.0, COL_E_W, LINHA_H)
		6: return Rect2(COL_E_X, LINHA_Y + 4.0 * passo + 44.0 + passo, COL_E_W, LINHA_H)
	return Rect2(COL_E_X, LINHA_Y + i * passo, COL_E_W, LINHA_H)

## Seletor de forma (setas duplas e simples) de uma linha: [<<][<] nome [>][>>].
static func rect_seta(i: int, k: int) -> Rect2:
	# k: 0 = <<, 1 = <, 2 = >, 3 = >>  (linhas 0-3 formas, 5 poder, 6 bônus); k 0 e 1 também na estampa com 1 e 2
	var r: Rect2 = rect_linha(i)
	var x0: float = r.position.x + 78.0
	var y: float = r.position.y + 5.0
	var w: float = SELETOR_W_LARGO if i >= 5 else SELETOR_W
	match k:
		0: return Rect2(x0, y, SETA_W, 28.0)
		1: return Rect2(x0 + SETA_W + 2.0, y, SETA_W, 28.0)
		2: return Rect2(x0 + w - 2.0 * SETA_W - 2.0, y, SETA_W, 28.0)
	return Rect2(x0 + w - SETA_W, y, SETA_W, 28.0)

static func rect_nome_forma(i: int) -> Rect2:
	var a: Rect2 = rect_seta(i, 1)
	var b: Rect2 = rect_seta(i, 2)
	return Rect2(a.end.x + 4.0, a.position.y, b.position.x - a.end.x - 8.0, 28.0)

static func rect_cor_seta(i: int, k: int) -> Rect2:
	var r: Rect2 = rect_linha(i)
	var x0: float = r.position.x + 78.0 + SELETOR_W + 6.0
	var w: float = COL_E_W - 78.0 - SELETOR_W - 6.0
	var y: float = r.position.y + 5.0
	return Rect2(x0, y, SETA_W, 28.0) if k == 0 else Rect2(x0 + w - SETA_W, y, SETA_W, 28.0)

static func rect_nome_cor(i: int) -> Rect2:
	var a: Rect2 = rect_cor_seta(i, 0)
	var b: Rect2 = rect_cor_seta(i, 1)
	return Rect2(a.end.x + 3.0, a.position.y, b.position.x - a.end.x - 6.0, 28.0)

# ------------------------------------------------------------------ abrir e fechar
func abrir() -> void:
	if aberta or dono == null:
		return
	if not Atelie.liberado(dono.estado):
		return
	aberta = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	abrir_t = 0.0
	anim.clear()
	treme.clear()
	digitando = false
	aviso = ""
	aviso_t = 0.0
	apertado_id = ""
	Som.tocar("abrir")
	_carregar_rascunho()
	_montar()
	foco = _indice_de("ok")
	_foco_som = foco
	queue_redraw()

func fechar() -> void:
	if not aberta:
		return
	if pintor.aberto:
		pintor.fechar()
	aberta = false
	visible = false
	digitando = false
	Som.tocar("fechar")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	apertado_id = ""
	itens.clear()
	Atelie.aplicar(dono.estado.atelie)   # descarta o que não foi confirmado

func _indice_de(id: String) -> int:
	for k in itens.size():
		if itens[k]["id"] == id:
			return k
	return maxi(0, itens.size() - 1)

func _montar() -> void:
	_idioma_montado = Idioma.atual
	var id_foco: String = ""
	if foco >= 0 and foco < itens.size():
		id_foco = itens[foco]["id"]
	itens.clear()
	var azul: Color = UIComum.B_AZUL
	for s in Pecas.SLOTS:
		_quatro_setas("f%d" % s, s)
		if (pint[s] as Dictionary).is_empty():   # peça pintada: a cor é a da pintura
			_seta_item("c%d" % s, "a", rect_cor_seta(s, 0), "<")
			_seta_item("c%d" % s, "b", rect_cor_seta(s, 1), ">")
	_seta_item("e", "a", rect_cor_seta(4, 0), "<")
	_seta_item("e", "b", rect_cor_seta(4, 1), ">")
	_quatro_setas("p", 5)
	_quatro_setas("b", 6)
	itens.append({"id": "nome", "r": NOME_R, "on": true, "txt": "", "cor": azul, "tam": 16, "vazio": true})
	itens.append({"id": "sug", "r": SUGERIR_R, "on": true, "txt": Idioma.t("Sugerir nome"), "cor": UIComum.B_LARANJA, "tam": 16})
	itens.append({"id": "pintar", "r": PINTAR_R, "on": true, "txt": Idioma.t("Pintar as peças"), "cor": UIComum.B_VERDE, "tam": 16})
	var igual: bool = (dono.estado.atelie == Atelie.ler(rascunho()))
	itens.append({"id": "ok", "r": BTN_OK, "on": true, "txt": Idioma.t("Salvar a fantasia") if not dono.estado.atelie.is_empty() else Idioma.t("Criar a fantasia"),
		"cor": UIComum.B_VERDE if not igual else UIComum.B_CINZA, "tam": 18})
	itens.append({"id": "fechar", "r": BTN_FECHAR, "on": true, "txt": Idioma.t("Fechar"), "cor": UIComum.B_MARROM, "tam": 20})
	foco = itens.size() - 1
	for k in itens.size():
		if itens[k]["id"] == id_foco:
			foco = k

func _seta_item(base: String, letra: String, r: Rect2, txt: String) -> void:
	itens.append({"id": base + letra, "r": r, "on": true, "txt": txt, "cor": UIComum.B_AZUL, "tam": 15})

## [<<][<] ... [>][>>] de uma linha: A e B andam 10, a e b andam 1.
func _quatro_setas(base: String, linha: int) -> void:
	_seta_item(base, "A", rect_seta(linha, 0), "<<")
	_seta_item(base, "a", rect_seta(linha, 1), "<")
	_seta_item(base, "b", rect_seta(linha, 2), ">")
	_seta_item(base, "B", rect_seta(linha, 3), ">>")

func _item_em(p: Vector2) -> int:
	for k in itens.size():
		if (itens[k]["r"] as Rect2).has_point(p):
			return k
	return -1

# ------------------------------------------------------------------ ações
## Anda `d` posições numa lista circular de `n` itens.
static func _passo(i: int, d: int, n: int) -> int:
	return posmod(i + d, maxi(1, n))

func acionar(id: String) -> void:
	if not aberta:
		return
	var e: Estado = dono.estado
	if id == "fechar" or id == "x":
		Som.tocar("clique")
		fechar()
		return
	if id == "nome":
		digitando = not digitando
		Som.tocar("clique")
		return
	if id == "pintar":
		digitando = false
		Som.tocar("clique")
		pintor.abrir(self, 0)
		return
	if id == "sug":
		nome_txt = Atelie.sugerir_nome(rng)
		_aplicar()
		Som.tocar("clique")
		_montar()
		return
	if id == "ok":
		var r: Dictionary = rascunho()
		if Atelie.confirmar(e, r):
			_avisar(Idioma.t("Pronto! As peças estão no guarda-roupa."))
			Som.tocar("nivel")
			if dono.has_method("atelie_salvo"):
				dono.atelie_salvo()
		else:
			_recusar(id)
		_aplicar()
		_montar()
		return
	# setas: id = base + letra (a = -1, b = +1, A = -10, B = +10)
	var letra: String = id.substr(id.length() - 1)
	var base: String = id.substr(0, id.length() - 1)
	var d: int = {"a": -1, "b": 1, "A": -10, "B": 10}.get(letra, 0)
	if d == 0:
		return
	match base:
		"f0", "f1", "f2", "f3":
			var s: int = int(base.substr(1))
			fi[s] = _passo(fi[s], d, (formas_ok[s] as Array).size())
			if not (pint[s] as Dictionary).is_empty():
				_avisar(Idioma.t("A peça segue pintada: a forma nova muda só o efeito."))
		"c0", "c1", "c2", "c3":
			var s2: int = int(base.substr(1))
			mi[s2] = _passo(mi[s2], d, Atelie.MATIZES)
		"e":
			est = _passo(est, d, Atelie.ESTAMPA_NOME.size())
		"p":
			pi = _passo(pi, d, poderes_ok.size())
		"b":
			bi = _passo(bi, d, bonus_ok.size())
	Som.tocar("aba", 1.1)
	_aplicar()
	_montar()

## O pintor mudou a pintura do rascunho: a prévia e as linhas mostram na hora.
func pintura_mudou() -> void:
	_aplicar()

func pintor_fechou() -> void:
	_aplicar()
	_montar()

func _recusar(id: String) -> void:
	treme[id] = 0.34
	UIComum.som_negado()

func _avisar(txt: String) -> void:
	aviso = txt
	aviso_t = 3.5 if txt != "" else 0.0

# ------------------------------------------------------------------ entrada
func _gui_input(ev: InputEvent) -> void:
	if not aberta or pintor.aberto:
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
				fechar()
			elif i < 0 and digitando:
				digitando = false

func _input(ev: InputEvent) -> void:
	if not aberta or pintor.aberto or not (ev is InputEventKey):
		return
	var k: InputEventKey = ev as InputEventKey
	if not k.pressed:
		return
	if digitando:
		if _tecla_nome(k):
			get_viewport().set_input_as_handled()
		return
	if not k.echo:
		tecla(k.keycode)
	get_viewport().set_input_as_handled()   # aberta, a tela fica com o teclado todo (nenhum atalho do jogo dispara atrás)

## Digitando o nome: letras entram até o limite, Backspace apaga, Enter ou Esc terminam.
func _tecla_nome(k: InputEventKey) -> bool:
	match k.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE:
			if not k.echo:
				digitando = false
			return true
		KEY_BACKSPACE:
			nome_txt = nome_txt.substr(0, maxi(0, nome_txt.length() - 1))
			_aplicar()
			return true
	var u: int = k.unicode
	if u >= 32 and nome_txt.length() < Atelie.NOME_MAX:
		var c: String = String.chr(u)
		if Atelie.limpar_nome("a" + c + "a").length() == 3:   # só entra o que o nome aceita
			nome_txt += c
			_aplicar()
		return true
	return u >= 32

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
	if _idioma_montado != Idioma.atual:
		_montar()
	abrir_t += delta
	aviso_t = maxf(0.0, aviso_t - delta)
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
	queue_redraw()

# ------------------------------------------------------------------ pintura
func _texto(txt: String, pos: Vector2, tam: int, cor: Color, larg: float = -1.0, contorno: int = 0) -> void:
	Desenho.texto(self, txt, pos, tam, cor, larg, contorno)

## Texto em até `max_l` linhas dentro de `larg`, no maior tamanho da lista em que cabe; devolve a altura usada.
func _bloco(txt: String, pos: Vector2, larg: float, tams: Array, max_l: int, cor: Color) -> float:
	for tm in tams:
		var ls: Array[String] = Oficina._quebrar_estatico(txt, int(tm), larg)
		if ls.size() <= max_l or tm == tams[tams.size() - 1]:
			var alt: float = float(int(tm) + 3)
			for k in mini(ls.size(), max_l):
				_texto(ls[k], pos + Vector2(0, alt * k), int(tm), cor, -1.0, 3)
			return alt * mini(ls.size(), max_l)
	return 0.0

func _draw() -> void:
	if not aberta or dono == null:
		return
	var e: Estado = dono.estado
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.74 * minf(1.0, abrir_t / 0.12)))
	UIComum.ini_pop(self, PAINEL.get_center(), UIComum.pop(abrir_t))
	draw_rect(PAINEL.grow(-18.0), COR_FUNDO)
	draw_rect(PAINEL.grow(-30.0), Color(0, 0, 0, 0.18), false, 2.0)
	dono.nove(self, GUI_TEX, R_MADEIRA, M_MADEIRA, PAINEL, 0.75, Color.WHITE, false)
	UIComum.titulo(self, Idioma.t("Ateliê"), 640.0, 76.0, 34, COR_OURO, Color(0.16, 0.07, 0.05, 0.95), t, false)
	_texto(Idioma.t("Crie a sua fantasia: escolha formas, cores, um poder e um bônus."), Vector2(PAINEL.position.x, 112), 16, Color(1, 1, 1, 0.8), PAINEL.size.x, 3)
	_texto(Idioma.t("Peças"), Vector2(COL_E_X, 146), 18, COR_TINTA, -1.0, 4)
	_texto(Idioma.t("Sua fantasia"), Vector2(COL_D_X, 146), 18, COR_TINTA, -1.0, 4)
	for i in 7:
		UIComum.ini_cascata(self, UIComum.cascata(abrir_t, i), -1.0)
		_linha(i)
		UIComum.fim_cascata(self)
	UIComum.ini_cascata(self, UIComum.cascata(abrir_t, 2), 1.0)
	_lado_direito(e)
	UIComum.fim_cascata(self)
	if aviso != "" and aviso_t > 0.0:
		UIComum.aviso(self, aviso, 640.0, 134.0, clampf(aviso_t / 0.5, 0.0, 1.0), UIComum.C_NOME)
	_texto(Idioma.t("Setas e Enter  |  Esc fecha"), Vector2(COL_E_X, 700 - 30), 13, Color(1, 1, 1, 0.45), -1.0, 3)
	for k in itens.size():
		_botao(k)
	UIComum.fechar(self, BTN_X, {"on": true, "foco": x_sobre, "h": UIComum.anim_h(anim, "x"), "p": UIComum.anim_p(anim, "x")}, t)
	UIComum.fim_pop(self)

func _fundo_linha(r: Rect2, forte: bool = false) -> void:
	draw_rect(r, Color(0.27, 0.18, 0.1, 0.95) if forte else Color(0.2, 0.12, 0.1, 0.92))
	draw_rect(r, Color(1.0, 0.82, 0.3, 0.4) if forte else Color(1, 1, 1, 0.14), false, 2.0)

func _linha(i: int) -> void:
	var r: Rect2 = rect_linha(i)
	_fundo_linha(r)
	if i < 4:
		var s: int = i
		var tipo: int = int((formas_ok[s] as Array)[fi[s]])
		_texto(Idioma.t(Pecas.SLOT_NOME[s]), Vector2(r.position.x + 8.0, r.position.y + 24.0), 17, COR_TINTA, 70.0, 4)
		var rn: Rect2 = rect_nome_forma(i)
		var nm: String = Idioma.t(Pecas.NOME[tipo])
		var tm: int = Oficina.tam_cabe(nm, [15, 14, 13, 12, 11, 10], rn.size.x)
		_texto(nm, Vector2(rn.position.x, rn.position.y + 19.0), tm, COR_TINTA, rn.size.x, 3)
		var info: String = Idioma.t(Pecas.dica(tipo))
		_texto(info, Vector2(r.position.x + 82.0, r.position.y + 51.0), Oficina.tam_cabe(info, [13, 12, 11, 10], 300.0), Color(1, 1, 1, 0.65), 300.0, 3)
		# miniatura da peça com a cor escolhida (pintada: a cor é a da pintura)
		if (pint[s] as Dictionary).is_empty():
			_cor_linha(rect_nome_cor(i), mi[s], r)
		else:
			var rp: Rect2 = rect_cor_seta(s, 0).merge(rect_cor_seta(s, 1))
			var tp: String = Idioma.t("Pintada")
			_texto(tp, Vector2(rp.position.x, rp.position.y + 19.0), Oficina.tam_cabe(tp, [14, 13, 12], rp.size.x), Color(0.7, 1.0, 0.75), rp.size.x, 3)
		# peça pronta (com cor e estampa) ao lado do rótulo
		Desenho.icone(self, Pecas.Tipo.ATELIE_CABECA + s, Vector2(r.end.x - 70.0, r.position.y + 48.0), 22.0)
	elif i == 4:
		_texto(Idioma.t("Estampa"), Vector2(r.position.x + 8.0, r.position.y + 26.0), 17, COR_TINTA, 70.0, 4)
		var ajuda: String = Idioma.t("Vale para as 4 peças.")
		if Oficina.largura(ajuda, 12) <= SELETOR_W - 8.0:
			_texto(ajuda, Vector2(r.position.x + 82.0, r.position.y + 26.0), 12, Color(1, 1, 1, 0.6), SELETOR_W - 8.0, 3)
		else:   # não cabe numa linha: duas, sem cortar
			_bloco(ajuda, Vector2(r.position.x + 82.0, r.position.y + 18.0), SELETOR_W - 8.0, [12, 11], 2, Color(1, 1, 1, 0.6))
		var rn2: Rect2 = rect_nome_cor(i)
		var nome_e: String = Idioma.t(Atelie.ESTAMPA_NOME[est])
		_texto(nome_e, Vector2(rn2.position.x, rn2.position.y + 19.0), Oficina.tam_cabe(nome_e, [14, 13, 12, 11, 10], rn2.size.x), COR_TINTA, rn2.size.x, 3)
	elif i == 5:
		var c: int = poderes_ok[pi]
		_texto(Idioma.t("Poder"), Vector2(r.position.x + 8.0, r.position.y + 24.0), 17, COR_TINTA, 70.0, 4)
		var rn3: Rect2 = rect_nome_forma(i)
		var nome_p: String = "%s (%s)" % [Idioma.t(Pecas.PODER_NOME[c]), Idioma.t(Pecas.CONJUNTO_NOME[c])]
		_texto(nome_p, Vector2(rn3.position.x, rn3.position.y + 19.0), Oficina.tam_cabe(nome_p, [15, 14, 13, 12, 11, 10], rn3.size.x), COR_OURO.lightened(0.2), rn3.size.x, 3)
		_bloco(Idioma.t(Pecas.PODER_DICA[c]), Vector2(r.position.x + 82.0, r.position.y + 45.0), 400.0, [13, 12, 11, 10], 2, Color(1, 1, 1, 0.65))
	else:
		var cb: int = bonus_ok[bi]
		_texto(Idioma.t("Bônus"), Vector2(r.position.x + 8.0, r.position.y + 24.0), 17, COR_TINTA, 70.0, 4)
		var rn4: Rect2 = rect_nome_forma(i)
		var nome_b: String = Idioma.t(Pecas.CONJUNTO_NOME[cb])
		_texto(nome_b, Vector2(rn4.position.x, rn4.position.y + 19.0), Oficina.tam_cabe(nome_b, [15, 14, 13, 12, 11, 10], rn4.size.x), COR_BOM, rn4.size.x, 3)
		_bloco(Idioma.t("2 peças: %s; 4 peças: %s") % [Pecas.conjunto_bonus(cb, 1), Pecas.conjunto_bonus(cb, 2)], Vector2(r.position.x + 82.0, r.position.y + 45.0), 410.0, [13, 12, 11, 10], 2, Color(1, 1, 1, 0.65))

## Quadradinho de cor com o nome do matiz escolhido.
func _cor_linha(rn: Rect2, m: int, _linha: Rect2) -> void:
	var amostra: Color = Color(0.9, 0.9, 0.9) if m == 0 else Color.from_hsv(float(m - 1) / 12.0, 0.7, 0.95)
	var q := Rect2(rn.position.x, rn.position.y + 5.0, 18.0, 18.0)
	draw_rect(q, Color(0.07, 0.04, 0.06))
	draw_rect(q.grow(-2.0), amostra)
	var nome_m: String = Idioma.t(Atelie.MATIZ_NOME[m])
	var larg: float = rn.size.x - 24.0
	_texto(nome_m, Vector2(q.end.x + 5.0, rn.position.y + 19.0), Oficina.tam_cabe(nome_m, [13, 12, 11, 10], larg), COR_TINTA, larg, 3)

func _lado_direito(e: Estado) -> void:
	# prévia: o gato vestindo a fantasia
	draw_rect(PREVIA_R, Color(0.08, 0.05, 0.07))
	draw_rect(PREVIA_R, Color(1, 0.85, 0.5, 0.35), false, 2.0)
	var rr: Dictionary = rascunho()
	var cor: Color = Pecas.CONJUNTO_COR[Pecas.Conjunto.ATELIE]
	draw_circle(Vector2(PREVIA_R.position.x + 150.0, PREVIA_R.end.y - 38.0), 0.0, cor)
	draw_rect(Rect2(PREVIA_R.position.x + 20.0, PREVIA_R.end.y - 40.0, 260.0, 4.0), Color(cor.r, cor.g, cor.b, 0.5))
	Desenho.boneco(self, Vector2(PREVIA_R.position.x + 140.0, PREVIA_R.end.y - 40.0), 2.6, 1.0, 0, pecas_previa, 0.0, t, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, true, 0, false)
	var nome_mostrado: String = Idioma.t(str(rr["nome"]))
	_texto(nome_mostrado, Vector2(PREVIA_R.position.x + 290.0, PREVIA_R.position.y + 40.0), Oficina.tam_cabe(nome_mostrado, [26, 24, 22, 20, 18], 200.0), cor.lightened(0.35), 204.0, 4)
	# as quatro peças em ícone
	for s in Pecas.SLOTS:
		var cx: float = PREVIA_R.position.x + 306.0 + (s % 2) * 80.0
		var cy: float = PREVIA_R.position.y + 104.0 + (s / 2) * 62.0
		draw_rect(Rect2(cx - 28.0, cy - 28.0, 56.0, 56.0), Color(0.15, 0.1, 0.12))
		draw_rect(Rect2(cx - 28.0, cy - 28.0, 56.0, 56.0), Color(1, 1, 1, 0.14), false, 2.0)
		Desenho.icone(self, Pecas.Tipo.ATELIE_CABECA + s, Vector2(cx, cy), 46.0)
	# nome
	var recarga: int = int(round(Balanco.PODER_INTERVALO * float(Balanco.PODER_KIT_INTERVALO.get(poderes_ok[pi], 1.0)) * Atelie.PODER_RECARGA_FATOR))
	_bloco(Idioma.t("Poder do kit completo: solta a cada %d s, com %d%% da força da fantasia de origem (o bônus vale com 2 peças e com as 4).") % [recarga, int(round(Atelie.PODER_FORCA_FATOR * 100.0))],
		Vector2(COL_D_X, 470.0), COL_D_W, [13, 12, 11], 3, Color(0.6, 0.85, 1.0, 0.85))
	if not e.atelie.is_empty():
		_texto(Idioma.t("Mudar é de graça; as peças mantêm nível, raridade e marcas."), Vector2(COL_D_X, 532.0), 13, Color(1, 1, 1, 0.5), COL_D_W, 3)

func _botao(i: int) -> void:
	var b: Dictionary = itens[i]
	var r: Rect2 = b["r"]
	var id: String = b["id"]
	var sobre: bool = i == foco
	if treme.has(id):
		r.position.x += roundf(sin(float(treme[id]) * 50.0) * 5.0)
	if b.get("vazio", false):
		# campo de nome: caixa de texto com cursor piscando
		var ativo: bool = digitando
		draw_rect(r, Color(0.07, 0.04, 0.06))
		draw_rect(r, COR_OURO if ativo else (Color(1, 1, 1, 0.7) if sobre else Color(1, 1, 1, 0.25)), false, 2.0)
		var txt: String = nome_txt
		if txt == "" and not ativo:
			_texto(Idioma.t("Clique para dar um nome (até %d letras)") % Atelie.NOME_MAX, Vector2(r.position.x + 10.0, r.position.y + 25.0), 14, Color(1, 1, 1, 0.4), r.size.x - 16.0, 3)
		else:
			var cur: String = "_" if ativo and int(t * 2.0) % 2 == 0 else ""
			_texto(txt + cur, Vector2(r.position.x + 10.0, r.position.y + 26.0), 20, COR_TINTA, r.size.x - 16.0, 3)
		return
	var o: Dictionary = {"on": b["on"], "foco": sobre, "h": UIComum.anim_h(anim, id), "p": UIComum.anim_p(anim, id), "tam": b["tam"]}
	UIComum.botao(self, r, b["txt"], b["cor"], o, t)
