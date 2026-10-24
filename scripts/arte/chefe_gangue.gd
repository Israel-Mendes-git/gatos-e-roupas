class_name ChefeGangue
extends RefCounted
## Os cinco chefes de gangue do 3º ato (Fases.Chefe 10 a 14): o gato do jogo com pelagem, traços e marca próprios.
## O chefe não aparece de fantasia: as peças dele valem na luta e caem de prêmio, mas o desenho é só o que é dele,
## na grade do sprite do gato (1 unidade = 1 pixel do sprite):
##   corpo_proprio(): o corpo inteiro, com silhueta, pelagem, capa, cabelo e disco (no lugar da folha do gato);
##   marca(): por cima do corpo (rosa, máscara, olho, crista, metais).
## Gato virado para a direita: +x é a frente, -y é para cima.

enum G { GATLEONE, IMORTAL, MESTRE, MIAUNIDAS, MAGNETO, SCHRO }   # SCHRO: o chefe secreto usa o mesmo esqueleto

## Pelagem de cada chefe ([textura, tinta]): diferente da dos rivais da gangue (Fases.GANGUE_PELAGEM).
const PELAGEM: Array = [
	[2, Color(0.66, 0.66, 0.72)],   # Dom Gatleone: persa cinza
	[2, Color(1.0, 1.0, 0.98)],     # Imortal Miau: branco-giz
	[0, Color(0.42, 0.44, 0.52)],   # Programa Mestre: preto-azulado
	[1, Color(1.0, 0.86, 0.58)],    # Rei Miaunidas: dourado
	[2, Color(0.8, 0.82, 0.9)],      # Magnetomiau: prata
]

const CONT := Color(0.09, 0.06, 0.08)

static func _p(c: CanvasItem, x: int, y: int, w: int, h: int, cor: Color, alfa: float) -> void:
	c.draw_rect(Rect2(x, y, w, h), Color(cor.r, cor.g, cor.b, cor.a * alfa))

## Quantos pixels a coisa sobe/desce com o passo (o corpo balança 1 px nos quadros de andar).
static func _balanco(anim: float) -> int:
	return 1 if posmod(int(anim * 1.3), 4) >= 2 else 0

# ------------------------------------------------------------------ marca (por cima da roupa)
const MARCA_ONDE: Array[int] = [RoupaGato.Onde.PESCOCO, RoupaGato.Onde.BOCA, RoupaGato.Onde.ROSTO, RoupaGato.Onde.CABECA, RoupaGato.Onde.CORPO, RoupaGato.Onde.CORPO]

static func marca(c: CanvasItem, g: int, anim: float, alfa: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	match g:
		G.GATLEONE:
			# rosa vermelha na lapela (origem: pescoço), com o cabo e uma folha
			var vr := Color(0.86, 0.1, 0.16)
			_p(c, 3, 3, 4, 4, CONT, alfa)
			_p(c, 4, 4, 2, 2, vr, alfa)
			_p(c, 4, 4, 1, 1, Color(1.0, 0.5, 0.5), alfa)
			_p(c, 3, 7, 1, 1, Color(0.2, 0.55, 0.2), alfa)
		G.IMORTAL:
			# máscara de respirar com a dentadura pintada (origem: ponta do focinho) e o tubo para o pescoço
			var me := Color(0.62, 0.62, 0.66)
			_p(c, -4, -2, 6, 5, CONT, alfa)
			_p(c, -3, -1, 4, 3, me, alfa)
			for k in 2:
				_p(c, -3 + k * 2, 0, 1, 2, Color(1, 1, 1), alfa)
			_p(c, -7, 2, 4, 1, CONT, alfa)
			_p(c, -7, 3, 1, 2, CONT, alfa)
		G.MESTRE:
			# olho vermelho aceso que pulsa em dois degraus (origem: entre os olhos)
			var forte: bool = fmod(t, 0.8) < 0.4
			_p(c, 0, 0, 2, 1, Color(1.0, 0.2, 0.1) if forte else Color(0.8, 0.1, 0.05), alfa)
			if forte:
				_p(c, 2, 0, 1, 1, Color(1.0, 0.6, 0.4), alfa)
		G.MIAUNIDAS:
			# crista espartana de crina vermelha de trás para a frente, sobre qualquer chapéu (origem: topo do crânio)
			var cr := Color(0.86, 0.12, 0.1)
			_p(c, -6, -3, 10, 3, CONT, alfa)
			_p(c, -5, -4, 8, 1, CONT, alfa)
			_p(c, -5, -3, 8, 2, cr, alfa)
			_p(c, -5, -1, 8, 1, cr.darkened(0.35), alfa)
			_p(c, -2, 0, 3, 1, Color(0.8, 0.55, 0.2), alfa)   # base de bronze
		G.MAGNETO:
			# três pedaços de metal girando em volta do corpo (origem: centro do tronco), em degraus de pixel
			for k in 3:
				var a: float = t * 1.6 + k * TAU / 3.0
				var x: int = int(roundf(cos(a) * 12.0))
				var y: int = int(roundf(sin(a) * 5.0)) - 3
				_p(c, x - 1, y - 1, 4, 3, CONT, alfa)
				_p(c, x, y, 2, 1, Color(0.72, 0.74, 0.8), alfa)
				_p(c, x, y, 1, 1, Color(1, 1, 1), alfa)
				if posmod(int(t * 6.0) + k, 3) == 0:
					_p(c, x + 2, y - 2, 1, 1, Color(0.85, 0.5, 1.0), alfa)   # faísca magnética

# ------------------------------------------------------------------ corpo próprio
## Cada chefe tem o corpo desenhado à mão em formas de pixel, montado sobre o "esqueleto" do gato comum: as âncoras de
## cabeça, rosto, focinho, pescoço, tronco e anca e as patas de cada quadro (GatoDados), para andar e golpear no mesmo
## ritmo e as peças da fantasia continuarem encaixando. Grade local: x de -24 a 23, y de -34 a 3 (0 = chão).
const _X0 := 24
const _Y0 := 34
const _W := 48
const _H := 38

## Proporções: tronco (meia-largura, meia-altura), cabeça (raio x, raio y), grossura da perna, subida (pernas mais
## longas levantam corpo, cabeça e peças), rabo (grossura, comprimento).
const FORMA: Array = [
	{"tw": 9, "th": 6, "hx": 5, "hy": 5, "perna": 3, "sobe": 0, "rabo": 3, "rabo_n": 6},   # Dom Gatleone: persa gordo
	{"tw": 6, "th": 3, "hx": 4, "hy": 4, "perna": 2, "sobe": 3, "rabo": 2, "rabo_n": 6},   # Imortal Miau: seco e pernalta
	{"tw": 7, "th": 4, "hx": 4, "hy": 4, "perna": 2, "sobe": 1, "rabo": 2, "rabo_n": 9},   # Programa Mestre: liso e anguloso
	{"tw": 8, "th": 5, "hx": 4, "hy": 4, "perna": 3, "sobe": 2, "rabo": 2, "rabo_n": 7},   # Rei Miaunidas: peito largo
	{"tw": 6, "th": 4, "hx": 4, "hy": 4, "perna": 2, "sobe": 1, "rabo": 1, "rabo_n": 7},   # Magnetomiau: magro e velho
	{"tw": 7, "th": 4, "hx": 4, "hy": 4, "perna": 2, "sobe": 1, "rabo": 2, "rabo_n": 8},   # Gato de Schrödinger
]

## Paleta: o contorno, l/m/d pelo claro, médio e escuro, w peito, e olho, n nariz, x detalhe próprio, y segundo detalhe,
## c/k capa e a dobra dela.
const PALETA: Array = [
	{"o": Color(0.09, 0.06, 0.08), "l": Color(0.78, 0.78, 0.82), "m": Color(0.6, 0.6, 0.66), "d": Color(0.42, 0.42, 0.5), "w": Color(0.97, 0.96, 0.93), "e": Color(0.15, 0.1, 0.1), "n": Color(0.85, 0.5, 0.55), "x": Color(0.2, 0.2, 0.24), "y": Color(0.86, 0.1, 0.16)},
	{"o": Color(0.09, 0.06, 0.08), "l": Color(1.0, 1.0, 0.98), "m": Color(0.9, 0.9, 0.88), "d": Color(0.7, 0.7, 0.72), "w": Color(1, 1, 1), "e": Color(0.6, 0.08, 0.08), "n": Color(0.45, 0.45, 0.5), "x": Color(0.55, 0.55, 0.6), "y": Color(0.95, 0.95, 0.9)},
	{"o": Color(0.04, 0.03, 0.06), "l": Color(0.3, 0.32, 0.42), "m": Color(0.18, 0.19, 0.26), "d": Color(0.1, 0.1, 0.15), "w": Color(0.25, 0.27, 0.36), "e": Color(1.0, 0.2, 0.1), "n": Color(0.4, 0.4, 0.5), "x": Color(1.0, 0.25, 0.15), "y": Color(1.0, 0.7, 0.55)},
	{"o": Color(0.12, 0.06, 0.04), "l": Color(1.0, 0.82, 0.5), "m": Color(0.88, 0.62, 0.3), "d": Color(0.66, 0.42, 0.18), "w": Color(1.0, 0.9, 0.7), "e": Color(0.15, 0.08, 0.05), "n": Color(0.6, 0.3, 0.25), "x": Color(0.3, 0.16, 0.07), "y": Color(0.8, 0.55, 0.2), "c": Color(0.78, 0.1, 0.08), "k": Color(0.5, 0.05, 0.05)},
	{"o": Color(0.07, 0.06, 0.1), "l": Color(0.9, 0.9, 0.95), "m": Color(0.72, 0.73, 0.8), "d": Color(0.52, 0.53, 0.62), "w": Color(1, 1, 1), "e": Color(0.15, 0.1, 0.2), "n": Color(0.75, 0.55, 0.6), "x": Color(0.5, 0.18, 0.62), "y": Color(0.85, 0.2, 0.2), "c": Color(0.5, 0.18, 0.62), "k": Color(0.3, 0.08, 0.4)},
	{"o": Color(0.04, 0.03, 0.08), "l": Color(0.3, 0.34, 0.5), "m": Color(0.16, 0.17, 0.26), "d": Color(0.09, 0.09, 0.15), "w": Color(0.4, 0.45, 0.62), "e": Color(0.45, 0.95, 1.0), "n": Color(0.5, 0.55, 0.75), "x": Color(0.45, 0.95, 1.0), "y": Color(0.9, 0.9, 0.95)},
]
## Estado do Gato de Schrödinger durante o desenho dele (o Campo põe antes de desenhar cada um e tira depois).
static var schro_morto: bool = false
static var schro_caixa: float = 0.0     # > 0: dentro da caixa fechada
static var schro_ilusao: bool = false   # a cópia falsa da superposição
static var schro_queda: float = -1.0    # >= 0: caindo (0,25 colapso, 0,5 tombando, 0,75 deitado)

static func subida(g: int) -> int:
	return int(FORMA[g]["sobe"]) if g >= 0 else 0

static func _nova() -> PackedByteArray:
	var L := PackedByteArray()
	L.resize(_W * _H)
	return L

static func _px(L: PackedByteArray, x: int, y: int, ch: String) -> void:
	var ix: int = x + _X0
	var iy: int = y + _Y0
	if ix >= 0 and ix < _W and iy >= 0 and iy < _H:
		L[iy * _W + ix] = ch.unicode_at(0)

static func _rect(L: PackedByteArray, x: int, y: int, w: int, h: int, ch: String) -> void:
	for yy in h:
		for xx in w:
			_px(L, x + xx, y + yy, ch)

## Elipse cheia; com `sombra` e cor "m", luz em cima e pelo escuro embaixo.
static func _elip(L: PackedByteArray, cx: float, cy: float, rx: float, ry: float, ch: String, sombra: bool = true) -> void:
	for y in range(int(floorf(cy - ry)), int(ceilf(cy + ry)) + 1):
		for x in range(int(floorf(cx - rx)), int(ceilf(cx + rx)) + 1):
			var dx: float = (x + 0.5 - cx) / maxf(rx, 0.5)
			var dy: float = (y + 0.5 - cy) / maxf(ry, 0.5)
			if dx * dx + dy * dy <= 1.0:
				var c2: String = ch
				if sombra and ch == "m":
					c2 = "l" if dy < -0.45 else ("d" if dy > 0.5 else "m")
				_px(L, x, y, c2)

## Traço grosso de a até b (pernas, rabo).
static func _traco(L: PackedByteArray, a: Vector2, b: Vector2, w: int, ch: String) -> void:
	var n: int = maxi(1, int(ceilf(a.distance_to(b))))
	for i in n + 1:
		var p: Vector2 = a.lerp(b, float(i) / n)
		_rect(L, int(floorf(p.x - w * 0.5 + 0.5)), int(floorf(p.y)), w, 1, ch)

## Contorno: todo pixel vazio encostado (4 vizinhos) num pixel cheio vira contorno.
static func _contorno(L: PackedByteArray) -> void:
	var o: int = "o".unicode_at(0)
	var M: PackedByteArray = L.duplicate()
	for iy in _H:
		for ix in _W:
			if M[iy * _W + ix] != 0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var jx: int = ix + d.x
				var jy: int = iy + d.y
				if jx >= 0 and jx < _W and jy >= 0 and jy < _H and M[jy * _W + jx] != 0 and M[jy * _W + jx] != o:
					L[iy * _W + ix] = o
					break

static func _pintar(c: CanvasItem, L: PackedByteArray, pal: Dictionary, alfa: float, tinta: Color) -> void:
	for iy in _H:
		var ix: int = 0
		while ix < _W:
			var v: int = L[iy * _W + ix]
			if v == 0:
				ix += 1
				continue
			var fim: int = ix + 1
			while fim < _W and L[iy * _W + fim] == v:
				fim += 1
			var cor: Color = pal.get(String.chr(v), Color.MAGENTA)
			c.draw_rect(Rect2(ix - _X0, iy - _Y0, fim - ix, 1), Color(cor.r * tinta.r, cor.g * tinta.g, cor.b * tinta.b, cor.a * alfa * tinta.a))
			ix = fim

## Desenha o corpo do chefe `g` no quadro `q` do gato. Origem já no chão, sob o centro (grade do sprite).
static func corpo_proprio(c: CanvasItem, g: int, q: int, anim: float, andando: bool, alfa: float, tinta: Color) -> void:
	if g == G.SCHRO and schro_caixa > 0.0:
		_schro_caixa(c, alfa)
		return
	if g == G.SCHRO and schro_queda >= 0.5:
		_schro_caido(c, alfa, tinta, schro_queda >= 0.75)
		return
	var F: Dictionary = FORMA[g]
	var pal: Dictionary = PALETA[g]
	var R: Vector2 = Desenho._origem(RoupaGato.Onde.ROSTO, q)
	var B: Vector2 = Desenho._origem(RoupaGato.Onde.BOCA, q)
	var N: Vector2 = Desenho._origem(RoupaGato.Onde.PESCOCO, q)
	var C: Vector2 = Desenho._origem(RoupaGato.Onde.CORPO, q)
	var T: Vector2 = Desenho._origem(RoupaGato.Onde.TRASEIRA, q)
	var pes: Array = RoupaGato.patas(q)
	if pes.is_empty():
		pes = RoupaGato.PATAS_PADRAO
	var L := _nova()
	var tw: float = F["tw"]
	var th: float = F["th"]
	var cc := Vector2(C.x, C.y + 1.0)   # centro do tronco
	var quadril_y: float = cc.y + th * 0.4
	# patas de trás (de índice par, mais escuras) atrás do corpo
	var perto: Array = []
	for k in pes.size():
		var pe: Vector2 = pes[k]
		var topo := Vector2(clampf(pe.x, cc.x - tw + 2.0, cc.x + tw - 2.0), quadril_y)
		if k % 2 == 0:
			_traco(L, topo, pe + Vector2(0, -1), int(F["perna"]), "d")
			_rect(L, int(pe.x) - 1, int(pe.y) - 1, int(F["perna"]) + 1, 1, "d")
		else:
			perto.append([topo, pe])
	# rabo: da anca para trás e para cima, com a ponta virada
	var rb: int = int(F["rabo"])
	var rn: int = int(F["rabo_n"])
	var ond: float = sin(anim * 2.0) if andando else 0.0
	var r1 := T + Vector2(0.0, 1.0)
	var r2 := T + Vector2(-3.0 - rn * 0.3, -rn * 0.6 + ond)
	var r3 := r2 + Vector2(1.0 + ond, -rn * 0.4)
	_traco(L, r1, r2, rb + 1, "m")
	_traco(L, r2, r3, rb, "m")
	if g == G.IMORTAL or g == G.MAGNETO:
		_px(L, int(r3.x), int(r3.y), "l")
	_extras_atras(L, g, T, N, anim, andando)
	# tronco
	_elip(L, cc.x, cc.y, tw, th, "m")
	if g == G.MESTRE:
		# tronco anguloso: cantos de baixo retos
		_rect(L, int(cc.x - tw), int(cc.y + th - 2), 2, 2, "d")
		_rect(L, int(cc.x + tw - 2), int(cc.y + th - 2), 2, 2, "d")
	# peito e pescoço (ligam o tronco à cabeça)
	_elip(L, N.x + 2.0, N.y + 2.0, 3.0 + (1.0 if g == G.MIAUNIDAS else 0.0), 3.5, "m")
	# patas da frente por cima
	for par in perto:
		var topo2: Vector2 = par[0]
		var pe2: Vector2 = par[1]
		_traco(L, topo2, pe2 + Vector2(0, -1), int(F["perna"]), "m")
		_rect(L, int(pe2.x) - 1, int(pe2.y) - 1, int(F["perna"]) + 1, 1, "l")
	# cabeça: crânio, orelhas e focinho
	var hx: float = F["hx"]
	var hy: float = F["hy"]
	var hc := Vector2(R.x - 1.0, R.y + 1.0)
	_elip(L, hc.x, hc.y, hx, hy, "m")
	var ox: int = int(hc.x)
	var oy: int = int(hc.y - hy)
	_rect(L, ox - 3, oy - 2, 2, 3, "m")
	_px(L, ox - 3, oy - 3, "m")
	_rect(L, ox + 1, oy - 2, 2, 3, "m")
	_px(L, ox + 2, oy - 3, "m")
	_px(L, ox + 2, oy - 1, "n")
	_rect(L, int(B.x) - 3, int(B.y) - 1, 3, 3, "l")
	_extras_corpo(L, g, cc, tw, th, hc, hx, hy, B, R, N)
	_contorno(L)
	# nariz e olho por cima do contorno
	_px(L, int(B.x) - 1, int(B.y) - 1, "n")
	if g == G.SCHRO:
		_schro(c, L, pal, alfa, tinta, cc, R, B, anim)
		return
	_extras_rosto(L, g, R)
	_pintar(c, L, pal, alfa, tinta)

## Gato de Schrödinger, o gato quântico: corpo preto com olhos de psi acesos e três elétrons orbitando, que "chia"
## como TV fora do ar. Vivo: nítido, só umas linhas tremem. Morto: quase tudo é chiado azul translúcido, com furos e uma
## cópia tremida ao lado. A cópia falsa da superposição tem só dois elétrons (a pista para quem presta atenção).
static func _schro(c: CanvasItem, L: PackedByteArray, pal: Dictionary, alfa: float, tinta: Color, cc: Vector2, R: Vector2, B: Vector2, anim: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var quadro: int = int(t * 12.0)   # o chiado muda 12 vezes por segundo
	var morto: bool = schro_morto
	if schro_queda >= 0.25:
		morto = posmod(quadro, 3) != 0   # colapso: pisca forte entre vivo e chiado antes de tombar
	var a_corpo: float = alfa * (0.7 if morto else 1.0)
	# elétrons de trás (atrás do corpo)
	_eletrons(c, cc, t, alfa, false)
	if morto:
		_schro_camada(c, L, pal, a_corpo * 0.35, tinta, Vector2i(2 if posmod(quadro, 2) == 0 else -2, 0), quadro + 7, true)   # cópia tremida
	_schro_camada(c, L, pal, a_corpo, tinta, Vector2i.ZERO, quadro, morto)
	# olhos de psi (3x3) acesos, piscando de leve
	var ex: int = int(R.x)
	var ey: int = int(R.y) - 1
	var brilho: Color = Color(0.45, 0.95, 1.0, alfa) if not morto else Color(0.75, 1.0, 1.0, alfa)
	for d in [Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		c.draw_rect(Rect2(ex + d.x, ey + d.y, 1, 1), brilho)
	# elétrons da frente
	_eletrons(c, cc, t, alfa, true)

## Uma passada do corpo com chiado: cada linha pode escorregar 1-2 pixels; morto, também some pixel ao acaso e
## a cor puxa para o azul do fantasma.
static func _schro_camada(c: CanvasItem, L: PackedByteArray, pal: Dictionary, alfa: float, tinta: Color, desl: Vector2i, semente: int, morto: bool) -> void:
	for iy in _H:
		var h: int = _hash(iy * 31 + semente * 7)
		var dx: int = 0
		if morto:
			dx = (h % 5) - 2 if h % 3 == 0 else 0
		elif h % 11 == 0:
			dx = 1 if h % 2 == 0 else -1
		for ix in _W:
			var v: int = L[iy * _W + ix]
			if v == 0:
				continue
			if morto and _hash(ix * 17 + iy * 131 + semente * 3) % 4 == 0:
				continue   # furos do chiado
			var cor: Color = pal.get(String.chr(v), Color.MAGENTA)
			if morto:
				cor = cor.lerp(Color(0.55, 0.85, 1.0), 0.55)
			c.draw_rect(Rect2(ix - _X0 + dx + desl.x, iy - _Y0 + desl.y, 1, 1), Color(cor.r * tinta.r, cor.g * tinta.g, cor.b * tinta.b, cor.a * alfa * tinta.a))

static func _hash(n: int) -> int:
	var x: int = (n * 1103515245 + 12345) & 0x7fffffff
	x = x ^ (x >> 13)
	return absi(x)

## Elétrons em órbitas inclinadas em volta do tronco; `frente` desenha só a metade da órbita que passa na frente.
static func _eletrons(c: CanvasItem, cc: Vector2, t: float, alfa: float, frente: bool) -> void:
	var n: int = 2 if schro_ilusao else 3
	var cores: Array = [Color(0.45, 0.95, 1.0), Color(1.0, 0.45, 0.95), Color(0.75, 1.0, 0.45)]
	for k in n:
		var fase: float = t * (2.2 + k * 0.4) + k * TAU / 3.0
		var inc: float = [0.0, 0.9, -0.9][k]
		var cor: Color = cores[k]
		# anel pontilhado da órbita (um pixel a cada três)
		for i in 24:
			var ai: float = TAU * i / 24.0
			if (sin(ai) > 0.0) != frente or i % 3 != 0:
				continue
			var oxi: float = cos(ai) * 16.0
			c.draw_rect(Rect2(int(roundf(cc.x + oxi)), int(roundf(cc.y - 3.0 + sin(ai) * 6.0 + oxi * inc * 0.35)), 1, 1), Color(cor.r, cor.g, cor.b, alfa * 0.35))
		for rastro in 4:
			var a: float = fase - rastro * 0.16
			var ox: float = cos(a) * 16.0
			var x: float = cc.x + ox
			var y: float = cc.y - 3.0 + sin(a) * 6.0 + ox * inc * 0.35
			if (sin(a) > 0.0) != frente:
				continue
			var lado: int = 3 if rastro == 0 else 1
			c.draw_rect(Rect2(int(roundf(x)) - lado / 2, int(roundf(y)) - lado / 2, lado, lado), Color(cor.r, cor.g, cor.b, alfa * (1.0 - rastro * 0.22)))
			if rastro == 0:
				c.draw_rect(Rect2(int(roundf(x)), int(roundf(y)), 1, 1), Color(1, 1, 1, alfa))

## Caído: de barriga para cima, com as quatro patas duras para o alto, olhos em X e a língua de fora; os elétrons apagados no chão e um fiapo de fantasma subindo.
## `no_chao` false = ainda tombando (2 pixels acima do chão, com chiado).
static func _schro_caido(c: CanvasItem, alfa: float, tinta: Color, no_chao: bool) -> void:
	var pal: Dictionary = PALETA[G.SCHRO]
	var L := _nova()
	var dy: float = 0.0 if no_chao else -3.0
	# de barriga para cima: rabo estirado, tronco no chão, as quatro patas duras para o alto e a cabeça de ponta-cabeça
	_traco(L, Vector2(-8, -3 + dy), Vector2(-17, -2 + dy), 2, "m")
	for k in 4:
		var px: float = [-7.0, -2.0, 3.0, 8.0][k]
		var pt: float = px + (k - 1.5) * 1.2   # as patas abrem para os lados
		_traco(L, Vector2(px, -6 + dy), Vector2(pt, -12 + dy), 2, "d" if k % 2 == 0 else "m")
		_rect(L, int(pt) - 1, int(-13 + dy), 2, 1, "l")   # almofadinha da pata
	_elip(L, 0.0, -4.0 + dy, 8.5, 3.5, "m")
	_elip(L, 0.0, -3.0 + dy, 5.0, 1.5, "w", false)   # barriga clara virada para cima
	_elip(L, 11.0, -4.0 + dy, 4.0, 3.5, "m")
	_rect(L, 9, int(-1 + dy), 2, 2, "m")    # orelhas viradas para baixo, no chão
	_rect(L, 13, int(-1 + dy), 2, 2, "m")
	_rect(L, 14, int(-7 + dy), 2, 2, "l")   # focinho para cima
	_contorno(L)
	_px(L, 15, int(-8 + dy), "n")           # língua de fora
	var t: float = Time.get_ticks_msec() / 1000.0
	if no_chao:
		_pintar(c, L, pal, alfa, tinta)
	else:
		_schro_camada(c, L, pal, alfa, tinta, Vector2i.ZERO, int(t * 12.0), true)
	# olhos em X
	var cx := Color(0.45, 0.95, 1.0, alfa * 0.8)
	var ex: int = 10
	var ey: int = int(-5 + dy)
	for d in [Vector2i(0, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(2, 2)]:
		c.draw_rect(Rect2(ex + d.x, ey + d.y, 1, 1), cx)
	if not no_chao:
		return
	# elétrons apagados no chão
	var cores: Array = [Color(0.45, 0.95, 1.0), Color(1.0, 0.45, 0.95), Color(0.75, 1.0, 0.45)]
	for k in 3:
		var cor: Color = cores[k]
		c.draw_rect(Rect2(-14 + k * 11, -1, 2, 1), Color(cor.r, cor.g, cor.b, alfa * 0.45))
	# fiapo de fantasma subindo: cabecinha translúcida com orelhas, sobe 10 pixels e recomeça
	var sobe: float = fmod(t * 0.8, 1.0)
	var fy: int = int(-16 - sobe * 10.0)
	var fa: float = alfa * 0.55 * (1.0 - sobe)
	var fc := Color(0.75, 0.92, 1.0, fa)
	c.draw_rect(Rect2(9, fy, 5, 3), fc)
	c.draw_rect(Rect2(9, fy - 1, 1, 1), fc)
	c.draw_rect(Rect2(13, fy - 1, 1, 1), fc)
	c.draw_rect(Rect2(10, fy + 3, 1, 2), fc)
	c.draw_rect(Rect2(12, fy + 3, 1, 1), fc)

## Caixa fechada (troca de estado): o gato some dentro da caixa com o psi, que treme e solta bolhas de veneno.
static func _schro_caixa(c: CanvasItem, alfa: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var tr: int = 1 if posmod(int(t * 20.0), 2) == 0 else -1
	var x0: int = -8 + tr
	var y0: int = -15
	var esc := Color(0.4, 0.28, 0.16, alfa)
	var pap := Color(0.72, 0.55, 0.34, alfa)
	var cla := Color(0.86, 0.7, 0.46, alfa)
	c.draw_rect(Rect2(x0 - 1, y0 - 1, 18, 17), Color(0.09, 0.06, 0.08, alfa))
	c.draw_rect(Rect2(x0, y0, 16, 15), pap)
	c.draw_rect(Rect2(x0, y0, 16, 3), cla)
	c.draw_rect(Rect2(x0 + 7, y0, 2, 15), esc)   # fita da tampa
	c.draw_rect(Rect2(x0, y0 + 13, 16, 2), esc)
	# psi grande na lateral
	var ps := Color(0.2, 0.75, 0.95, alfa)
	for d in [Vector2i(0, 0), Vector2i(4, 0), Vector2i(0, 1), Vector2i(4, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 3), Vector2i(2, 4)]:
		c.draw_rect(Rect2(x0 + 3 + d.x, y0 + 5 + d.y, 1, 1), ps)
	# bolhas verdes pela fresta da tampa
	for k in 3:
		var fy: float = fmod(t * 1.5 + k * 0.33, 1.0)
		c.draw_rect(Rect2(x0 + 4 + k * 4, y0 - 2 - int(fy * 8.0), 2, 2), Color(0.45, 1.0, 0.3, alfa * (1.0 - fy)))

## Capa e disco: atrás do tronco, na mesma grade (ganham o contorno junto).
static func _extras_atras(L: PackedByteArray, g: int, T: Vector2, N: Vector2, anim: float, andando: bool) -> void:
	var on: int = 1 if andando and posmod(int(anim * 1.3), 2) == 1 else 0
	match g:
		G.MIAUNIDAS, G.MAGNETO:
			# capa dos ombros para trás: cai pelas costas e abre para trás até perto do chão (a frente fica livre)
			var fim: int = -2 if g == G.MIAUNIDAS else -4
			var y0: int = int(N.y) - 1
			for y in range(y0, fim + 1):
				var desce: float = float(y - y0) / maxf(1.0, fim - y0)
				var x0: int = int(lerpf(N.x, T.x + 3.0, desce))
				var x1: int = int(T.x) - 2 - on - int(desce * 4.0)
				_rect(L, x1, y, maxi(1, x0 - x1), 1, "c")
				if (y - y0) % 3 == 2:
					_px(L, x1 + 1, y, "k")
					_px(L, x1 + 4, y, "k")
		G.MESTRE:
			# disco de luz preso nas costas
			_elip(L, T.x + 4.0, T.y - 2.0, 3.5, 3.5, "x", false)
			_elip(L, T.x + 4.0, T.y - 2.0, 1.5, 1.5, "d", false)

## Traços no corpo e na cabeça (antes do contorno): bochechas, peito, barba, cabelo, circuitos.
static func _extras_corpo(L: PackedByteArray, g: int, cc: Vector2, tw: float, th: float, hc: Vector2, hx: float, hy: float, B: Vector2, R: Vector2, N: Vector2) -> void:
	match g:
		G.GATLEONE:
			# persa: bochechas largas, peito branco e pelo penteado para trás (topete escuro)
			_elip(L, hc.x + 1.0, hc.y + 2.0, hx + 1.0, 2.5, "l", false)
			_elip(L, N.x + 3.0, N.y + 3.0, 2.0, 3.0, "w", false)
			_rect(L, int(hc.x) - 3, int(hc.y - hy), 6, 2, "x")
		G.IMORTAL:
			# cabelo branco comprido da nuca às costas e costelas pintadas
			_traco(L, Vector2(hc.x - 2.0, hc.y - hy + 1.0), Vector2(cc.x - 2.0, cc.y - 2.0), 3, "y")
			for k in 3:
				_rect(L, int(cc.x) + k * 2, int(cc.y) - 1, 1, 3, "x")
		G.MESTRE:
			# linhas de luz vermelhas no tronco e na cabeça (traje do Tron)
			_rect(L, int(cc.x - tw) + 2, int(cc.y), int(tw * 2) - 3, 1, "x")
			_rect(L, int(cc.x) + 2, int(cc.y) - 2, 1, 3, "x")
			_rect(L, int(hc.x) - 2, int(hc.y) - 1, 4, 1, "x")
		G.MIAUNIDAS:
			# barba castanha em ponta
			_rect(L, int(B.x) - 4, int(B.y) + 1, 4, 2, "x")
			_rect(L, int(B.x) - 3, int(B.y) + 3, 2, 1, "x")
		G.MAGNETO:
			# sobrancelha branca e corcunda de velho (pelo claro no lombo)
			_rect(L, int(R.x) - 1, int(R.y) - 1, 3, 1, "w")
			_rect(L, int(cc.x) - 3, int(cc.y - th) - 1, 5, 1, "l")

## Olho (depois do contorno, para não ganhar borda).
static func _extras_rosto(L: PackedByteArray, g: int, R: Vector2) -> void:
	var ex: int = int(R.x) + 1
	var ey: int = int(R.y)
	if g == G.GATLEONE or g == G.MESTRE:
		_rect(L, ex - 1, ey, 2, 1, "e")   # olho comprido: pálpebra pesada (Dom) ou visor (Mestre)
	else:
		_px(L, ex, ey, "e")
