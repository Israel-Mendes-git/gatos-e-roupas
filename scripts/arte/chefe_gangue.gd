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
	{"o": Color(0.05, 0.04, 0.07), "l": Color(0.36, 0.36, 0.42), "m": Color(0.22, 0.22, 0.27), "d": Color(0.13, 0.13, 0.17), "w": Color(0.5, 0.5, 0.56), "e": Color(1.0, 0.86, 0.15), "n": Color(0.85, 0.5, 0.55), "x": Color(0.6, 0.62, 0.7), "y": Color(0.9, 0.9, 0.95)},
]
## Metade fantasma do Gato de Schrödinger: azul-claro translúcido, costelas e olho em X.
const PALETA_FANTASMA: Dictionary = {
	"o": Color(0.45, 0.62, 0.8, 0.85), "l": Color(0.92, 0.97, 1.0, 0.7), "m": Color(0.8, 0.9, 1.0, 0.62), "d": Color(0.66, 0.78, 0.92, 0.6),
	"w": Color(0.95, 0.98, 1.0, 0.7), "e": Color(0.3, 0.45, 0.65, 0.95), "n": Color(0.7, 0.8, 0.95, 0.7), "x": Color(0.5, 0.65, 0.85, 0.8),
	"y": Color(0.9, 0.95, 1.0, 0.7), "r": Color(0.55, 0.7, 0.88, 0.85),
}
## Gato de Schrödinger morto agora (o desenho troca qual metade domina). Vale só durante o desenho dele.
static var schro_morto: bool = false

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

## Gato de Schrödinger: um corpo só, cortado por uma costura em zigue-zague. À frente do corte ele está vivo
## (preto, olho amarelo); atrás, fantasma (translúcido, contorno pontilhado, costelas). Vivo, a frente domina;
## morto, o corte avança até o focinho e a cabeça ganha o olho em X.
static func _schro(c: CanvasItem, L: PackedByteArray, pal: Dictionary, alfa: float, tinta: Color, cc: Vector2, R: Vector2, B: Vector2, anim: float) -> void:
	var corte: int = int(B.x) - 3 if schro_morto else int(cc.x) - 2
	var ex: int = int(R.x) + 1
	var ey: int = int(R.y)
	var o: int = "o".unicode_at(0)
	# costelas na parte fantasma do tronco (3 riscos)
	for k in 3:
		var rx: int = int(cc.x) - 4 + k * 2
		if rx < corte:
			for dy in 3:
				var iy: int = int(cc.y) - 1 + dy + _Y0
				var ix: int = rx + _X0
				if ix >= 0 and ix < _W and iy >= 0 and iy < _H and L[iy * _W + ix] != 0 and L[iy * _W + ix] != o:
					L[iy * _W + ix] = "r".unicode_at(0)
	for iy in _H:
		for ix in _W:
			var v: int = L[iy * _W + ix]
			if v == 0:
				continue
			var x: int = ix - _X0
			var y: int = iy - _Y0
			var morto_px: bool = x < corte + (1 if posmod(y, 2) == 0 else 0)   # zigue-zague
			var ch: String = String.chr(v)
			if morto_px and ch == "o" and posmod(x + y, 2) == 1:
				continue   # contorno pontilhado do fantasma
			var cor: Color
			if morto_px:
				cor = PALETA_FANTASMA.get(ch, PALETA_FANTASMA["m"])
			else:
				cor = pal.get(ch, Color.MAGENTA)
			c.draw_rect(Rect2(x, y, 1, 1), Color(cor.r * tinta.r, cor.g * tinta.g, cor.b * tinta.b, cor.a * alfa * tinta.a))
	# costura: pontos claros ao longo do corte, no corpo
	for iy in _H:
		var x2: int = corte + (1 if posmod(iy - _Y0, 2) == 0 else 0)
		var ix2: int = x2 + _X0
		if ix2 >= 0 and ix2 < _W and L[iy * _W + ix2] != 0 and L[iy * _W + ix2] != o and posmod(iy, 3) != 0:
			c.draw_rect(Rect2(x2, iy - _Y0, 1, 1), Color(0.95, 0.98, 1.0, 0.9 * alfa))
	# olho: amarelo e vivo, ou X de fantasma quando a cabeça passou para o lado morto
	if ex < corte:
		var cx := Color(0.25, 0.4, 0.62, alfa)
		c.draw_rect(Rect2(ex - 1, ey - 1, 1, 1), cx)
		c.draw_rect(Rect2(ex + 1, ey - 1, 1, 1), cx)
		c.draw_rect(Rect2(ex, ey, 1, 1), cx)
		c.draw_rect(Rect2(ex - 1, ey + 1, 1, 1), cx)
		c.draw_rect(Rect2(ex + 1, ey + 1, 1, 1), cx)
	else:
		var pisca: bool = fmod(Time.get_ticks_msec() / 1000.0, 3.0) < 0.12
		c.draw_rect(Rect2(ex, ey, 1, 1 if not pisca else 1), Color(1.0, 0.86, 0.15, alfa) if not pisca else Color(0.05, 0.04, 0.07, alfa))
		c.draw_rect(Rect2(ex - 1, ey, 1, 1), Color(0.05, 0.04, 0.07, alfa))

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
