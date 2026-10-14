class_name UIComum
extends RefCounted
## Peças de interface comuns a Menus, Oficina, Mapa e Fichário, para os quatro falarem a mesma língua:
##   botão (normal, mouse em cima, apertado, desabilitado, foco de teclado), botão de fechar redondo,
##   título de painel (com patinhas), contador de troféus, aviso curto, dica do mouse,
##   além de animação suave (hover/clique), salto de painel, cascata, contagem e faíscas em pixel.
## Tudo é desenhado por código sobre um CanvasItem qualquer e não guarda estado de jogo.

const GATO_TEX: Texture2D = preload("res://assets/terceiros/gui/gato_ui.png")
const C_CONT := Color(0.24, 0.17, 0.19)
const C_CREME := Color(1.0, 0.94, 0.88)
const C_ROSA := Color(1.0, 0.82, 0.76)
const C_TEXTO := Color(0.28, 0.17, 0.19)
const C_TEXTO2 := Color(0.46, 0.32, 0.33)
const C_OURO := Color(1.0, 0.8, 0.3)
const C_NOME := Color(0.8, 0.32, 0.4)
const B_VERDE := Color(0.62, 0.88, 0.6)
const B_LARANJA := Color(1.0, 0.76, 0.5)
const B_AZUL := Color(0.65, 0.8, 1.0)
const B_MARROM := Color(0.88, 0.72, 0.6)
const B_VERMELHO := Color(1.0, 0.5, 0.48)
const B_CINZA := Color(0.86, 0.82, 0.8)
const B_OURO := Color(1.0, 0.84, 0.4)
const ICONES := {"play": Vector2i(0, 0), "pausa": Vector2i(0, 1), "mais": Vector2i(1, 0), "ok": Vector2i(1, 1), "x": Vector2i(2, 0), "menos": Vector2i(2, 1), "ajuda": Vector2i(3, 0), "cifrao": Vector2i(3, 1)}
const FAISCA_COR: Array[Color] = [Color(1.0, 0.82, 0.3), Color(1.0, 0.95, 0.65), Color(1.0, 0.6, 0.4), Color(1.0, 1.0, 1.0)]

## Transformação de base (o salto de painel): todas as peças daqui compõem com ela.
static var base: Transform2D = Transform2D.IDENTITY

static func ini_pop(c: CanvasItem, centro: Vector2, s: float) -> void:
	base = Transform2D(0.0, Vector2(s, s), 0.0, centro * (1.0 - s))
	c.draw_set_transform_matrix(base)

static func fim_pop(c: CanvasItem) -> void:
	base = Transform2D.IDENTITY
	c.draw_set_transform_matrix(base)

## Muda a transformação compondo com a base (posição, rotação, escala).
static func trans(c: CanvasItem, pos: Vector2, rot: float = 0.0, esc: Vector2 = Vector2.ONE) -> void:
	c.draw_set_transform_matrix(base * Transform2D(rot, esc, 0.0, pos))

static func trans_fim(c: CanvasItem) -> void:
	c.draw_set_transform_matrix(base)

# ------------------------------------------------------------------ sons de interface (um lugar só)
static func som_hover() -> void:
	Som.tocar("hover", 1.0, 0.05, -10.0)

static func som_clique() -> void:
	Som.tocar("clique")

static func som_negado() -> void:
	Som.tocar("negado")

# ------------------------------------------------------------------ animação
## Leva o valor `v` até `alvo` a `vel` por segundo.
static func aprox(v: float, alvo: float, vel: float, delta: float) -> float:
	return move_toward(v, alvo, vel * delta)

## Atualiza a animação de um botão: "h" (mouse/foco em cima, 0..1) e "p" (apertado, 0..1).
static func anim_passo(anim: Dictionary, id: String, sobre: bool, press: bool, delta: float) -> void:
	var a: Dictionary = anim.get(id, {"h": 0.0, "p": 0.0})
	a["h"] = aprox(float(a["h"]), 1.0 if sobre else 0.0, 9.0, delta)
	a["p"] = aprox(float(a["p"]), 1.0 if press else 0.0, 14.0, delta)
	anim[id] = a

static func anim_h(anim: Dictionary, id: String) -> float:
	return float((anim.get(id, {}) as Dictionary).get("h", 0.0))

static func anim_p(anim: Dictionary, id: String) -> float:
	return float((anim.get(id, {}) as Dictionary).get("p", 0.0))

static func _eob(x: float) -> float:
	return 1.0 + 2.70158 * pow(x - 1.0, 3.0) + 1.70158 * pow(x - 1.0, 2.0)

## Escala do painel `tt` segundos depois de abrir: um pequeno salto (0,88 -> ~1,01 -> 1).
static func pop(tt: float) -> float:
	if tt >= 0.24:
		return 1.0
	return 0.88 + 0.12 * _eob(clampf(tt / 0.24, 0.0, 1.0))

## Progresso 0..1 do item `i` de uma lista que entra em cascata `tt` segundos depois de abrir.
static func cascata(tt: float, i: int, passo: float = 0.05, dur: float = 0.22, inicio: float = 0.06) -> float:
	return clampf((tt - inicio - i * passo) / dur, 0.0, 1.0)

## Desloca o desenho de um item da cascata (entra deslizando de lado); chame `fim_cascata` depois.
static var _base_ant: Transform2D = Transform2D.IDENTITY

static func ini_cascata(c: CanvasItem, k: float, lado: float = -1.0) -> void:
	var e: float = 1.0 - k
	_base_ant = base
	base = Transform2D(0.0, Vector2.ONE, 0.0, Vector2(lado * 46.0 * e * e, 0.0)) * _base_ant
	c.draw_set_transform_matrix(base)

static func fim_cascata(c: CanvasItem) -> void:
	base = _base_ant
	c.draw_set_transform_matrix(base)

## Contador que sobe (ou desce) até o valor em vez de trocar de uma vez.
static func contar(atual: float, alvo: float, delta: float) -> float:
	if absf(alvo - atual) < 0.05:
		return alvo
	var vel: float = maxf(6.0, absf(alvo - atual) * 5.0)
	return move_toward(atual, alvo, vel * delta)

# ------------------------------------------------------------------ formas
static func forma(c: CanvasItem, r: Rect2, cor: Color, u: float = 3.0) -> void:
	if r.size.x <= 2.0 * u or r.size.y <= 2.0 * u:
		c.draw_rect(r, cor)
		return
	c.draw_rect(Rect2(r.position.x + u, r.position.y, r.size.x - 2.0 * u, r.size.y), cor)
	c.draw_rect(Rect2(r.position.x, r.position.y + u, r.size.x, r.size.y - 2.0 * u), cor)

static func caixa(c: CanvasItem, r: Rect2, contorno: Color, fundo: Color, u: float = 3.0) -> void:
	forma(c, r, contorno, u)
	forma(c, r.grow(-u), fundo, u)

static func spr(c: CanvasItem, src: Rect2, pos: Vector2, esc: int, cor: Color = Color.WHITE) -> void:
	c.draw_texture_rect_region(GATO_TEX, Rect2(pos.round(), src.size * float(esc)), src, cor)

static func pata(c: CanvasItem, i: int, pos: Vector2, esc: int) -> void:
	spr(c, Rect2(65 + 16 * (i % 3), 33 + 16 * ((i / 3) % 3), 15, 14), pos, esc)

## `estilo`: 0 branco, 1 marrom, 2 bege, 3 rosa.
static func icone(c: CanvasItem, k: String, estilo: int, pos: Vector2, esc: int, apertado: bool = false) -> void:
	var rc: Vector2i = ICONES.get(k, Vector2i(0, 0))
	var sx: int = 128 + (estilo % 2) * 64 + 32 * rc.y + (16 if apertado else 0) + 1
	var sy: int = (estilo / 2) * 64 + 16 * rc.x + 1
	spr(c, Rect2(sx, sy, 14, 14), pos, esc)

# ------------------------------------------------------------------ botão (o desenho único)
## `o`: on (bool), foco (teclado/mouse em cima), h (0..1 animado), p (0..1 animado), marcado, tam, icone, sub, balao (-1 sem).
## O botão cresce de leve com o mouse, afunda ao apertar e tem anel dourado quando está em foco.
static func botao(c: CanvasItem, r: Rect2, txt: String, cor: Color, o: Dictionary, t: float) -> void:
	var on: bool = o.get("on", true)
	var foco: bool = on and o.get("foco", false)
	var h: float = float(o.get("h", 1.0 if foco else 0.0)) if on else 0.0
	var pr: float = float(o.get("p", 0.0)) if on else 0.0
	var u: float = 3.0
	r = Rect2(r.position.round(), r.size.round())
	var esc: float = 1.0 + 0.045 * h - 0.05 * pr
	trans(c, r.get_center(), 0.0, Vector2(esc, esc))
	var rl := Rect2(-r.size * 0.5, r.size).abs()
	rl.position = rl.position.round()
	var pu: float = 0.5 + 0.5 * sin(t * 5.0)
	var ouro_a := Color(C_OURO.r, C_OURO.g, C_OURO.b, 0.5 + 0.5 * pu)
	var press: bool = on and pr > 0.45
	var tem_icone: bool = o.has("icone")
	if tem_icone and txt == "":
		var est: int = 2 if not on else (3 if (foco or h > 0.5) else 1)
		if foco:
			forma(c, rl.grow(u), ouro_a, u)
		icone(c, o["icone"], est, rl.position, 3, press)
		trans_fim(c)
		return
	var fundo: Color
	if not on:
		fundo = Color(0.83, 0.8, 0.79)
	elif press:
		fundo = cor.darkened(0.14)
	elif h > 0.01 or foco:
		fundo = cor.lerp(cor.lightened(0.2), maxf(h, 1.0 if foco else 0.0))
	else:
		fundo = cor
	if foco:
		forma(c, rl.grow(2.0 * u), ouro_a, u)
	elif o.get("marcado", false):
		forma(c, rl.grow(u), C_OURO, u)
	var rb: Rect2 = rl
	if press:
		rb.position.y += u
	else:
		forma(c, Rect2(rl.position + Vector2(0, u + 1.0), rl.size), Color(0, 0, 0, 0.32), u)
	caixa(c, rb, C_CONT, fundo, u)
	if on and not press:
		c.draw_rect(Rect2(rb.position.x + 2.0 * u, rb.position.y + u, rb.size.x - 4.0 * u, u), Color(1, 1, 1, 0.45))
		c.draw_rect(Rect2(rb.position.x + u, rb.end.y - 2.0 * u, rb.size.x - 2.0 * u, u), Color(0, 0, 0, 0.14))
	elif not on:
		for k in int(rb.size.x / 24.0):
			c.draw_rect(Rect2(rb.position.x + 14.0 + k * 24.0, rb.position.y + u, 10, u), Color(1, 1, 1, 0.35))
	var fonte: Font = ThemeDB.fallback_font
	var tam: int = int(o.get("tam", 22))
	var tx: float = rb.position.x
	var tw: float = rb.size.x
	if tem_icone:
		trans(c, r.get_center(), 0.0, Vector2(esc, esc))
		icone(c, o["icone"], 0 if on else 2, Vector2(rb.position.x + 12.0, rb.get_center().y - 14.0), 2, press)
		tx += 40.0
		tw -= 48.0
	var sub: String = o.get("sub", "")
	var yb: float = rb.position.y + (rb.size.y - fonte.get_height(tam)) * 0.5 + fonte.get_ascent(tam) - 1.0
	if sub != "":
		yb -= 11.0
	var ct: Color = C_TEXTO if on else Color(0.56, 0.5, 0.5)
	# encolhe o texto se não couber
	while tam > 11 and fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > tw - 14.0:
		tam -= 1
	var larg_txt: float = fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var extra_x: float = 0.0
	if o.has("trofeu"):
		extra_x = 12.0   # abre espaço para o troféu à direita do texto
	c.draw_string(fonte, Vector2(tx - extra_x, roundf(yb)), txt, HORIZONTAL_ALIGNMENT_CENTER, tw, tam, ct)
	if o.has("trofeu"):
		Oficina.trofeu(c, Vector2(tx + (tw + larg_txt) * 0.5 - extra_x + 4.0, rb.get_center().y - 10.0), 2.0, 1.0 if on else 0.5)
	if sub != "":
		c.draw_string(fonte, Vector2(tx, roundf(yb + 23.0)), sub, HORIZONTAL_ALIGNMENT_CENTER, tw, 14, Color(0.34, 0.22, 0.24))
	trans_fim(c)
	# carinha de gato saltando ao lado do botão em foco
	if foco and o.get("balao", -1) >= 0 and r.size.x >= 120.0:
		var bob: float = roundf(sin(t * 6.0) * 2.0)
		var rb2: Array[Rect2] = [Rect2(5, 39, 21, 18), Rect2(37, 39, 21, 18), Rect2(5, 71, 21, 18), Rect2(37, 71, 21, 18)]
		spr(c, rb2[int(o["balao"])], Vector2(r.position.x - 52.0 + bob, r.get_center().y - 18.0), 2)

## Botão redondo de fechar (X). Mesmo desenho em todas as telas.
static func fechar(c: CanvasItem, r: Rect2, o: Dictionary, t: float) -> void:
	var d: Dictionary = o.duplicate()
	d["icone"] = "x"
	botao(c, r, "", Color.WHITE, d, t)

# ------------------------------------------------------------------ título, aviso, contador, dica
## Título de painel: texto grande com contorno e uma patinha de cada lado.
static func titulo(c: CanvasItem, txt: String, cx: float, base_y: float, tam: int, cor: Color, contorno: Color = C_CONT, t: float = 0.0, sombra: bool = true) -> void:
	var fonte: Font = ThemeDB.fallback_font
	var w: float = fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var x: float = cx - w * 0.5
	if sombra:
		c.draw_string_outline(fonte, Vector2(x, base_y + 3.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 8, Color(0, 0, 0, 0.3))
	c.draw_string_outline(fonte, Vector2(x, base_y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 8, contorno)
	c.draw_string(fonte, Vector2(x, base_y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)
	var py: float = base_y - tam * 0.72 + roundf(sin(t * 2.0) * 1.0)
	pata(c, 0, Vector2(x - 46.0, py), 2)
	pata(c, 2, Vector2(x + w + 16.0, py), 2)

## Aviso curto: faixa creme de contorno escuro, centrada em `cx`, com fade por `alfa`.
static func aviso(c: CanvasItem, txt: String, cx: float, y: float, alfa: float = 1.0, cor_txt: Color = C_TEXTO, tam: int = 16) -> void:
	if txt == "" or alfa <= 0.01:
		return
	var fonte: Font = ThemeDB.fallback_font
	var w: float = fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x + 36.0
	var r := Rect2(roundf(cx - w * 0.5), y, roundf(w), 34.0)
	forma(c, Rect2(r.position + Vector2(0, 4), r.size), Color(0, 0, 0, 0.3 * alfa))
	caixa(c, r, Color(C_CONT.r, C_CONT.g, C_CONT.b, alfa), Color(C_CREME.r, C_CREME.g, C_CREME.b, alfa))
	c.draw_string(fonte, Vector2(r.position.x, r.position.y + 23.0), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, tam, Color(cor_txt.r, cor_txt.g, cor_txt.b, alfa))

## Contador de troféus: ícone + número + legenda. `pulso` (0..1) dá um soco no número quando ele muda.
## Devolve o centro do ícone (destino dos troféus que voam).
static func contador_trofeus(c: CanvasItem, cx: float, y: float, valor: int, pulso: float = 0.0, legenda: String = "troféus", tam: int = 34) -> Vector2:
	var fonte: Font = ThemeDB.fallback_font
	var txt: String = str(valor)
	var wn: float = fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var wl: float = fonte.get_string_size(legenda, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var x0: float = cx - (40.0 + 10.0 + wn + 8.0 + wl) * 0.5
	Oficina.trofeu(c, Vector2(x0, y), 4.0)
	var esc: float = 1.0 + 0.28 * pulso
	trans(c, Vector2(x0 + 50.0 + wn * 0.5, y + 32.0), 0.0, Vector2(esc, esc))
	var base := Vector2(-wn * 0.5, 0.0)
	c.draw_string_outline(fonte, base, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 6, Color(0.16, 0.07, 0.05, 0.95))
	c.draw_string(fonte, base, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color(1.0, 0.92, 0.5).lerp(Color.WHITE, pulso))
	trans_fim(c)
	c.draw_string_outline(fonte, Vector2(x0 + 58.0 + wn, y + 32.0), legenda, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color(0.16, 0.07, 0.05, 0.95))
	c.draw_string(fonte, Vector2(x0 + 58.0 + wn, y + 32.0), legenda, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.94, 0.8))
	return Vector2(x0 + 20.0, y + 20.0)

## Dica do mouse. `linhas`: [[texto, tamanho, cor], ...]. Fica sempre dentro da tela de 1280 x 720.
static func dica_mouse(c: CanvasItem, linhas: Array, mouse: Vector2, borda: Color = C_CONT, larg_min: float = 120.0) -> void:
	if linhas.is_empty():
		return
	var fonte: Font = ThemeDB.fallback_font
	var w: float = larg_min
	var h: float = 18.0
	for l in linhas:
		w = maxf(w, fonte.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, int(l[1])).x + 28.0)
		h += int(l[1]) + 6.0
	var p := Vector2(mouse.x + 16.0, mouse.y + 20.0)
	if p.x + w > 1272.0:
		p.x = mouse.x - w - 12.0
	if p.y + h > 712.0:
		p.y = mouse.y - h - 10.0
	var r := Rect2(p.round(), Vector2(roundf(w), roundf(h)))
	forma(c, Rect2(r.position + Vector2(0, 4), r.size), Color(0, 0, 0, 0.3))
	caixa(c, r, borda, C_CREME)
	var y: float = r.position.y + 12.0
	for l in linhas:
		y += int(l[1])
		c.draw_string(fonte, Vector2(r.position.x + 14.0, y), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, int(l[1]), l[2])
		y += 6.0

## Clarão que some: retângulo `r` e um anel que cresce. `k` vai de 1 (agora) a 0.
static func clarao(c: CanvasItem, r: Rect2, k: float, cor: Color = Color(1.0, 0.92, 0.55)) -> void:
	if k <= 0.0:
		return
	c.draw_rect(r, Color(cor.r, cor.g, cor.b, 0.5 * k))
	c.draw_rect(r.grow((1.0 - k) * 14.0), Color(cor.r, cor.g, cor.b, 0.8 * k), false, 3.0)

# ------------------------------------------------------------------ faíscas em pixel
## Partículas quadradas: explosões (`emitir`) e troféus voando de um ponto a outro (`voar`).
class Faiscas:
	var ps: Array[Dictionary] = []
	var chegadas: int = 0   # quantos troféus voadores já chegaram (a tela usa para dar o soco no contador)

	func vazio() -> bool:
		return ps.is_empty()

	func limpar() -> void:
		ps.clear()

	func emitir(pos: Vector2, n: int, cores: Array = UIComum.FAISCA_COR, vel: float = 170.0, vida: float = 0.7, grav: float = 300.0) -> void:
		for i in n:
			var a: float = randf() * TAU
			var v: float = vel * (0.4 + randf() * 0.6)
			ps.append({"p": pos, "v": Vector2(cos(a), sin(a) - 0.4) * v, "t": vida * (0.6 + randf() * 0.4), "m": vida, "c": cores[randi() % cores.size()], "g": grav, "z": 4.0 if randf() < 0.6 else 6.0, "tipo": 0})

	## Troféus miúdos que saem de `de`, fazem um arco e entram em `para`.
	func voar(de: Vector2, para: Vector2, n: int = 5, dur: float = 0.6) -> void:
		for i in n:
			ps.append({"p": de, "de": de, "para": para, "t": -i * 0.07, "m": dur, "arco": -60.0 - randf() * 50.0, "dx": (randf() - 0.5) * 70.0, "tipo": 1})

	func passo(delta: float) -> void:
		var i: int = ps.size() - 1
		while i >= 0:
			var q: Dictionary = ps[i]
			if q["tipo"] == 0:
				q["t"] = float(q["t"]) - delta
				q["v"] = (q["v"] as Vector2) + Vector2(0, float(q["g"])) * delta
				q["p"] = (q["p"] as Vector2) + (q["v"] as Vector2) * delta
				if float(q["t"]) <= 0.0:
					ps.remove_at(i)
			else:
				q["t"] = float(q["t"]) + delta
				var k: float = clampf(float(q["t"]) / float(q["m"]), 0.0, 1.0)
				var e: float = k * k * (3.0 - 2.0 * k)
				var de: Vector2 = q["de"]
				var para: Vector2 = q["para"]
				q["p"] = de.lerp(para, e) + Vector2(float(q["dx"]) * (1.0 - e) * sin(k * PI), float(q["arco"]) * sin(k * PI))
				if k >= 1.0:
					chegadas += 1
					ps.remove_at(i)
			i -= 1

	func desenhar(c: CanvasItem) -> void:
		for q in ps:
			if q["tipo"] == 0:
				var a: float = clampf(float(q["t"]) / (float(q["m"]) * 0.5), 0.0, 1.0)
				var z: float = float(q["z"])
				var col: Color = q["c"]
				var pp: Vector2 = ((q["p"] as Vector2) / 2.0).round() * 2.0
				c.draw_rect(Rect2(pp - Vector2(z, z) * 0.5, Vector2(z, z)), Color(col.r, col.g, col.b, a))
			elif float(q["t"]) >= 0.0:
				Oficina.trofeu(c, ((q["p"] as Vector2).round()) - Vector2(10, 10), 2.0)
