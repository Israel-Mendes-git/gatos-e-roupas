class_name RoupaGatoG
extends RefCounted
## Roupas do gato em pixel art, tipos 124 em diante (ver RoupaGato para as convenções): expansão das fantasias, lote 2
## (Disparamiau 124-127, Milhau 128-131, Giramiau 132-135, Stardew Miaulley 136-139, Miaucraft 140-143, Miaulax 144-147).
##
## COMO ENCAIXA NO GATO: igual ao RoupaGatoF, as peças são desenhadas em COORDENADAS DO GATO (x para a frente, y para cima, pé em 0;
## cabeça em x 3..10 / y -17..-10, tronco em x -8..8 / y -12..-6) e convertidas para o lugar onde ficam presas. A cabeça cobre a do
## gato, o corpo cobre o tronco, os acessórios ficam no dorso (Onde.CORPO) e as peças de mão na boca. Camada [x, y, linhas, paleta, true]
## = ATRÁS do corpo (vagem do Disparamiau).
##
## FALLBACK: peça sem arte própria em `_montar` desenha a silhueta de uma peça do lado de fora, tingida.

const PRIMEIRO := 124
## Silhuetas de reserva por espaço (cabeça, corpo, mão, acessório); cada fantasia usa uma das 4 colunas.
const _MOLDE_FALLBACK: Array = [
	[Pecas.Tipo.CAPACETE_AZUL, Pecas.Tipo.BANDANA_FOLHA, Pecas.Tipo.CAPUZ_TUBARAO, Pecas.Tipo.ANTENAS],
	[Pecas.Tipo.COLETE_LISTRADO, Pecas.Tipo.MACACAO_LARANJA, Pecas.Tipo.ARMADURA_AZUL, Pecas.Tipo.ROUPA_TUBARAO],
	[Pecas.Tipo.KUNAI, Pecas.Tipo.CANHAO_BRACO, Pecas.Tipo.MORDIDA, Pecas.Tipo.FERRAO],
	[Pecas.Tipo.TANQUE, Pecas.Tipo.PERGAMINHO, Pecas.Tipo.BOIA, Pecas.Tipo.POTE_MEL],
]

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão (cabeça, corpo, boca e traseira). Os acessórios do lote 2 vão no dorso.
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.VAGEM_MUNICAO, Pecas.Tipo.TABLETE_MANTEIGA, Pecas.Tipo.VASO_SORRISO, Pecas.Tipo.GALINHA, Pecas.Tipo.MINI_CREEPER, Pecas.Tipo.PRATO_VAZIO:
			return RoupaGato.Onde.CORPO
	return -1

## Peças com camada atrás do corpo do gato.
static func tem_atras(tipo: int) -> bool:
	return tipo == Pecas.Tipo.VAGEM_MUNICAO

# ------------------------------------------------------------------ paletas
const _PAL_DISP := {
	"o": Color(0.06, 0.2, 0.1), "a": Color(0.37, 0.8, 0.3), "b": Color(0.66, 0.95, 0.48), "d": Color(0.2, 0.55, 0.22),
	"l": Color(0.2, 0.62, 0.24), "L": Color(0.55, 0.9, 0.42), "k": Color(0.07, 0.07, 0.1), "w": Color(1, 1, 1),
	"g": Color(0.55, 0.6, 0.64), "G": Color(0.84, 0.88, 0.9), "s": Color(0.3, 0.33, 0.38), "p": Color(0.5, 0.88, 0.36),
	"P": Color(0.85, 1.0, 0.7), "q": Color(0.12, 0.38, 0.16),
}
const _PAL_MILHO := {
	"o": Color(0.35, 0.22, 0.04), "a": Color(0.98, 0.85, 0.25), "b": Color(1.0, 0.95, 0.55), "d": Color(0.85, 0.65, 0.12),
	"v": Color(0.3, 0.66, 0.25), "V": Color(0.6, 0.9, 0.45), "D": Color(0.16, 0.42, 0.16), "k": Color(0.15, 0.1, 0.08),
	"w": Color(1, 0.98, 0.9), "W": Color(0.9, 0.84, 0.66), "y": Color(1.0, 0.9, 0.4), "Y": Color(1.0, 0.97, 0.7),
	"g": Color(0.62, 0.66, 0.7), "G": Color(0.88, 0.9, 0.93), "s": Color(0.34, 0.36, 0.42), "r": Color(0.86, 0.22, 0.2),
	"x": Color(1.0, 0.7, 0.55), "m": Color(0.98, 0.9, 0.5), "M": Color(1.0, 0.98, 0.78), "n": Color(0.88, 0.7, 0.2),
}
const _PAL_SOL := {
	"o": Color(0.4, 0.22, 0.02), "y": Color(1.0, 0.82, 0.12), "Y": Color(1.0, 0.94, 0.45), "f": Color(0.96, 0.58, 0.06),
	"e": Color(0.62, 0.38, 0.14), "E": Color(0.46, 0.26, 0.09), "m": Color(0.78, 0.52, 0.22), "k": Color(0.06, 0.03, 0.02),
	"a": Color(0.3, 0.7, 0.25), "b": Color(0.55, 0.9, 0.4), "d": Color(0.15, 0.45, 0.17), "l": Color(0.2, 0.6, 0.22),
	"c": Color(0.8, 0.94, 1.0, 0.55), "C": Color(0.95, 1.0, 1.0, 0.9), "h": Color(1.0, 0.9, 0.3, 0.45), "g": Color(0.9, 0.7, 0.2), "G": Color(1.0, 0.9, 0.5),
	"t": Color(0.84, 0.45, 0.25), "T": Color(0.96, 0.62, 0.4), "u": Color(0.6, 0.28, 0.14), "R": Color(1.0, 0.6, 0.6), "w": Color(1, 1, 1),
	"n": Color(0.4, 0.4, 0.46),
}
const _PAL_STAR := {
	"o": Color(0.28, 0.16, 0.06), "s": Color(0.93, 0.8, 0.42), "S": Color(1.0, 0.93, 0.64), "d": Color(0.74, 0.56, 0.24),
	"g": Color(0.3, 0.6, 0.25), "G": Color(0.55, 0.85, 0.4), "l": Color(0.35, 0.75, 0.3),
	"a": Color(0.25, 0.42, 0.76), "b": Color(0.42, 0.6, 0.92), "D": Color(0.14, 0.26, 0.52), "r": Color(0.86, 0.22, 0.22), "R": Color(1.0, 0.5, 0.45),
	"E": Color(0.55, 0.1, 0.12), "y": Color(0.98, 0.8, 0.3), "w": Color(1, 1, 1), "W": Color(0.82, 0.84, 0.9),
	"m": Color(0.55, 0.34, 0.14), "M": Color(0.8, 0.58, 0.3), "N": Color(0.36, 0.2, 0.08),
	"i": Color(0.5, 0.52, 0.56), "I": Color(0.78, 0.8, 0.84), "u": Color(0.72, 0.38, 0.16), "k": Color(0.08, 0.06, 0.06), "p": Color(1.0, 0.55, 0.15),
	"x": Color(1.0, 0.6, 0.2), "c": Color(0.96, 0.96, 0.98), "q": Color(0.86, 0.28, 0.25),
}
const _PAL_CRAFT := {
	"o": Color(0.08, 0.08, 0.12), "h": Color(0.34, 0.2, 0.1), "H": Color(0.48, 0.3, 0.15), "j": Color(0.24, 0.14, 0.07),
	"s": Color(0.8, 0.57, 0.4), "S": Color(0.92, 0.7, 0.52), "u": Color(0.64, 0.43, 0.29), "w": Color(0.96, 0.96, 1.0), "b": Color(0.25, 0.32, 0.75),
	"m": Color(0.42, 0.24, 0.14),
	"a": Color(0.2, 0.7, 0.78), "A": Color(0.45, 0.88, 0.92), "d": Color(0.12, 0.5, 0.6), "p": Color(0.3, 0.3, 0.68), "P": Color(0.48, 0.48, 0.86), "q": Color(0.18, 0.18, 0.46),
	"g": Color(0.36, 0.78, 0.3), "G": Color(0.55, 0.92, 0.42), "f": Color(0.2, 0.5, 0.18), "k": Color(0.06, 0.1, 0.06),
	"T": Color(0.22, 0.86, 0.8), "U": Color(0.7, 1.0, 0.96), "D": Color(0.1, 0.5, 0.52), "x": Color(0.5, 0.33, 0.16), "X": Color(0.72, 0.5, 0.26),
	"n": Color(0.55, 0.55, 0.6),
}
const _PAL_LAX := {
	"o": Color(0.06, 0.14, 0.18), "a": Color(0.22, 0.46, 0.5), "b": Color(0.36, 0.64, 0.66), "d": Color(0.13, 0.3, 0.36),
	"c": Color(0.97, 0.9, 0.72), "C": Color(1.0, 0.98, 0.88), "e": Color(0.84, 0.74, 0.54), "k": Color(0.05, 0.05, 0.08), "w": Color(1, 1, 1),
	"p": Color(0.35, 0.58, 0.95), "P": Color(0.62, 0.8, 1.0), "q": Color(0.2, 0.32, 0.72), "W": Color(0.92, 0.95, 1.0),
	"t": Color(0.9, 0.92, 0.96), "T": Color(0.7, 0.74, 0.84), "r": Color(0.4, 0.58, 0.8), "n": Color(0.55, 0.36, 0.18), "g": Color(0.62, 0.64, 0.7),
	"G": Color(0.88, 0.9, 0.94), "x": Color(0.9, 0.55, 0.6),
}

# ------------------------------------------------------------------ ferramentas (usam as telas de RoupaGatoF)
static func _ret(cv: Dictionary, x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	RoupaGatoF._ret(cv, x0, y0, x1, y1, ch)

static func _px(cv: Dictionary, x: int, y: int, ch: String) -> void:
	cv[Vector2i(x, y)] = ch

static func _lin(cv: Dictionary, a: Vector2i, b: Vector2i, ch: String) -> void:
	RoupaGatoF._lin(cv, a, b, ch)

static func _disco(cv: Dictionary, cx: float, cy: float, r: float, ch: String) -> void:
	RoupaGatoF._disco(cv, cx, cy, r, ch)

static func _poli(cv: Dictionary, p: Array, ch: String) -> void:
	RoupaGatoF._poli(cv, p, ch)

static func _pico(cv: Dictionary, a: Vector2i, b: Vector2i, p: Vector2i, ch: String) -> void:
	RoupaGatoF._pico(cv, a, b, p, ch)

static func _cont(cv: Dictionary, ch: String, baixo: bool = true) -> void:
	RoupaGatoF._cont(cv, ch, baixo)

static func _luz(cv: Dictionary, base: String, luz: String, sombra: String = "") -> void:
	RoupaGatoF._luz(cv, base, luz, sombra)

static func _lay(cv: Dictionary, lugar: int, pal: Dictionary, atras: bool = false) -> Array:
	return RoupaGatoF._lay(cv, lugar, pal, atras)

static func _linhas(lugar: int, x: int, y: int, linhas: Array, pal: Dictionary, atras: bool = false) -> Array:
	return RoupaGatoF._linhas(lugar, x, y, linhas, pal, atras)

## Põe a tela `de` por cima da tela `cv`.
static func _sobre(cv: Dictionary, de: Dictionary) -> void:
	for k in de.keys():
		cv[k] = de[k]

## Texto escrito à mão sobre a tela: `x`, `y` = canto de cima à esquerda; "." = não pinta.
static func _txt(cv: Dictionary, x: int, y: int, linhas: Array) -> void:
	for j in linhas.size():
		var s: String = linhas[j]
		for i in s.length():
			if s[i] != ".":
				cv[Vector2i(x + i, y + j)] = s[i]

## Pétala: fuso que sai do raio r0 e vai até r1 do centro (cx, cy), na direção `ang`, de largura `w`.
static func _petala(cv: Dictionary, cx: float, cy: float, ang: float, r0: float, r1: float, w: float, ch: String) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	var c := Vector2(cx, cy)
	var p0: Vector2 = c + d * r0
	var pm: Vector2 = c + d * (r0 + (r1 - r0) * 0.55)
	var pt: Vector2 = c + d * r1
	var pts: Array = []
	for v in [p0 - n * w * 0.45, pm - n * w, pt, pm + n * w, p0 + n * w * 0.45]:
		pts.append(v.x)
		pts.append(v.y)
	_poli(cv, pts, ch)

## Elipse de pixels centrada em (cx, cy) em canto de pixel, raios rx e ry.
static func _elipse(cv: Dictionary, cx: float, cy: float, rx: float, ry: float, ch: String) -> void:
	for y in range(floori(cy - ry), ceili(cy + ry)):
		for x in range(floori(cx - rx), ceili(cx + rx)):
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				cv[Vector2i(x, y)] = ch

# ------------------------------------------------------------------ peças
static var _cache: Dictionary = {}

## Camadas da peça com arte própria; vazio = usa o fallback.
static func _camadas(tipo: int, _anim: float, _maxima: bool = false) -> Array:
	if _cache.has(tipo):
		return _cache[tipo]
	var r: Array = _montar(tipo)
	_cache[tipo] = r
	return r

static func _montar(tipo: int) -> Array:
	var cv: Dictionary = {}
	match tipo:
		# ---------------------------------------------------------------- Disparamiau (ervilha)
		Pecas.Tipo.CABECA_ERVILHA:
			# esfera verde cobrindo o crânio, cano de canhão no lugar da boca, olho de determinação e folhas no alto
			_disco(cv, 6.5, -14.0, 5.4, "a")
			_luz(cv, "a", "b", "d")
			_px(cv, 4, -17, "b")
			_px(cv, 3, -16, "b")
			var fo: Dictionary = {}
			_pico(fo, Vector2i(3, -19), Vector2i(5, -19), Vector2i(-2, -23), "l")
			_pico(fo, Vector2i(6, -19), Vector2i(8, -19), Vector2i(9, -25), "l")
			_lin(fo, Vector2i(4, -19), Vector2i(0, -22), "L")
			_lin(fo, Vector2i(7, -19), Vector2i(8, -24), "L")
			_sobre(cv, fo)
			_ret(cv, 10, -15, 11, -9, "q")
			_ret(cv, 11, -14, 15, -10, "g")
			_ret(cv, 11, -14, 15, -13, "G")
			_ret(cv, 11, -11, 15, -10, "s")
			_ret(cv, 14, -15, 17, -9, "g")
			_ret(cv, 14, -15, 17, -14, "G")
			_ret(cv, 14, -10, 17, -9, "s")
			_ret(cv, 15, -13, 17, -11, "k")
			_px(cv, 16, -13, "p")
			_ret(cv, 6, -16, 9, -12, "w")
			_ret(cv, 7, -15, 9, -13, "k")
			_px(cv, 8, -15, "w")
			_lin(cv, Vector2i(5, -18), Vector2i(9, -16), "q")
			_lin(cv, Vector2i(5, -17), Vector2i(9, -15), "q")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_DISP)]
		Pecas.Tipo.CAULE_FOLHAS:
			# tronco de caule verde e duas folhas largas, uma em cada flanco, como braços
			RoupaGatoF._tronco(cv, "a")
			_luz(cv, "a", "b", "d")
			_cont(cv, "o", false)
			var f1: Dictionary = {}
			_poli(f1, [2, -10, 5, -11, 8, -9.5, 10.8, -2.8, 6.5, -4.8, 3.2, -6.8], "l")
			_lin(f1, Vector2i(3, -9), Vector2i(10, -3), "L")
			_lin(f1, Vector2i(5, -8), Vector2i(5, -6), "L")
			_lin(f1, Vector2i(7, -8), Vector2i(8, -6), "L")
			_cont(f1, "o")
			_sobre(cv, f1)
			var f2: Dictionary = {}
			_poli(f2, [-1.5, -9.5, -5, -11, -8.5, -9.5, -11, -2.8, -6.5, -4.8, -3, -6.8], "l")
			_lin(f2, Vector2i(-2, -9), Vector2i(-10, -3), "L")
			_lin(f2, Vector2i(-5, -8), Vector2i(-5, -6), "L")
			_lin(f2, Vector2i(-7, -8), Vector2i(-8, -6), "L")
			_cont(f2, "o")
			_sobre(cv, f2)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_DISP)]
		Pecas.Tipo.METRALHA_ERVILHA:
			# metralhadora de vagem: casca verde alongada, tambor de ervilhas em cima, cano cinza à frente
			_poli(cv, [6, -7.5, 8, -9.5, 13, -10, 16, -8.5, 16, -5.5, 13, -4.5, 8, -5, 6, -6], "l")
			_ret(cv, 8, -8, 15, -7, "L")
			_ret(cv, 7, -6, 15, -5, "d")
			for k in 3:
				_disco(cv, 9.5 + k * 2.2, -9.2, 1.1, "p")
				_px(cv, 9 + k * 2, -10, "P")
			_ret(cv, 16, -9, 23, -6, "g")
			_ret(cv, 16, -9, 23, -8, "G")
			_ret(cv, 16, -7, 23, -6, "s")
			_ret(cv, 22, -10, 24, -5, "g")
			_ret(cv, 23, -8, 24, -7, "k")
			_ret(cv, 8, -5, 10, -3, "s")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_DISP)]
		Pecas.Tipo.VAGEM_MUNICAO:
			# vagem aberta com ervilhas prontas presa às costas (atrás do corpo: só a parte de cima aparece)
			return [_linhas(RoupaGato.Onde.CORPO, -6, -22, [
				"..oo.oo.oo..",
				".oPpoPpoPpo.",
				".oppoppoppo.",
				"oloooooooolo",
				"olLLLLLLLLlo",
				"olLLLLLLLLlo",
				".olllllllllo",
				".olllddllllo",
				"..ollllllllo",
				"...oooooooo.",
			], _PAL_DISP, true)]
		# ---------------------------------------------------------------- Milhau (milho)
		Pecas.Tipo.ESPIGA_MILHO:
			# espiga de grãos cobrindo a cabeça, folhas verdes como cabelo e sorriso de grãos
			_poli(cv, [2, -14, 3, -17, 5.5, -18.8, 8.5, -18.8, 10.5, -17, 11.5, -14, 11.5, -11, 10.5, -9.5, 4, -9.5, 2.5, -11], "a")
			for k in cv.keys():
				var v: Vector2i = k
				if posmod(v.x, 2) == 0 and posmod(v.y, 2) == 0:
					cv[v] = "d"
				elif posmod(v.x, 2) == 1 and posmod(v.y, 2) == 1:
					cv[v] = "b"
			var fo: Dictionary = {}
			_pico(fo, Vector2i(3, -18), Vector2i(5, -18), Vector2i(-3, -21), "v")
			_pico(fo, Vector2i(5, -19), Vector2i(8, -19), Vector2i(6, -26), "v")
			_pico(fo, Vector2i(8, -18), Vector2i(10, -18), Vector2i(15, -22), "v")
			_lin(fo, Vector2i(4, -18), Vector2i(-1, -21), "V")
			_lin(fo, Vector2i(6, -19), Vector2i(6, -25), "V")
			_lin(fo, Vector2i(9, -18), Vector2i(14, -21), "V")
			_cont(fo, "D")
			_sobre(cv, fo)
			_px(cv, 6, -14, "k")
			_px(cv, 7, -15, "k")
			_px(cv, 8, -15, "k")
			_px(cv, 9, -14, "k")
			_ret(cv, 5, -12, 10, -11, "w")
			_px(cv, 4, -12, "k")
			_px(cv, 10, -12, "k")
			_ret(cv, 5, -11, 10, -10, "k")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_MILHO)]
		Pecas.Tipo.FOLHAS_MILHO:
			# tronco de folhas de milho apertadas (diagonais), a espiga amarela aparecendo no peito e a barba de milho na gola
			RoupaGatoF._tronco(cv, "v", -12, -5)
			for k in cv.keys():
				var v: Vector2i = k
				if posmod(v.x + v.y * 2, 5) == 0:
					cv[v] = "D"
				elif posmod(v.x + v.y * 2, 5) == 1:
					cv[v] = "V"
			for x in range(-8, 8):
				if posmod(x, 3) == 0:
					cv.erase(Vector2i(x, -5))
			_cont(cv, "o", false)
			_poli(cv, [3.5, -9, 7.5, -9, 6.5, -5.5, 4.5, -5.5], "a")
			_px(cv, 5, -8, "b")
			_px(cv, 6, -7, "d")
			_px(cv, 5, -6, "d")
			var barba: Array = [[0, -12, 0, -8], [1, -12, 2, -7], [2, -12, 3, -8], [3, -12, 5, -9], [-1, -12, -2, -9]]
			for bb in barba:
				_lin(cv, Vector2i(bb[0], bb[1]), Vector2i(bb[2], bb[3]), "y" if (int(bb[0]) % 2 == 0) else "Y")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MILHO)]
		Pecas.Tipo.BAZUCA_PIPOCA:
			# tubo de lata com rótulo vermelho e a boca estourando pipoca
			_ret(cv, 10, -14, 19, -9, "g")
			_ret(cv, 10, -14, 19, -13, "G")
			_ret(cv, 10, -10, 19, -9, "s")
			_ret(cv, 13, -14, 16, -9, "r")
			_ret(cv, 13, -14, 16, -13, "x")
			_px(cv, 14, -12, "w")
			_px(cv, 15, -11, "w")
			_ret(cv, 19, -16, 21, -7, "g")
			_ret(cv, 19, -16, 21, -15, "G")
			_ret(cv, 20, -13, 21, -10, "k")
			_cont(cv, "o")
			var pp: Array = [[23.5, -15.0], [26.0, -11.5], [23.5, -8.0], [26.5, -17.5], [22.0, -19.5], [28.0, -14.5], [25.5, -6.5]]
			for p2 in pp:
				var pc: Dictionary = {}
				_disco(pc, p2[0], p2[1], 1.7, "w")
				_px(pc, int(p2[0]), int(p2[1]) - 1, "M")
				_px(pc, int(p2[0]) + 1, int(p2[1]) + 1, "y")
				_px(pc, int(p2[0]), int(p2[1]) + 1, "W")
				_cont(pc, "n")
				_sobre(cv, pc)
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_MILHO)]
		Pecas.Tipo.TABLETE_MANTEIGA:
			# tablete de manteiga no dorso com uma faca de plástico enfiada
			_ret(cv, -6, -17, 2, -12, "M")
			_ret(cv, -5, -18, 3, -17, "w")
			_ret(cv, 2, -17, 3, -13, "m")
			_ret(cv, -6, -13, 2, -12, "m")
			_px(cv, -4, -15, "w")
			_px(cv, -3, -15, "w")
			_px(cv, 0, -14, "m")
			_cont(cv, "n")
			var fa: Dictionary = {}
			_lin(fa, Vector2i(0, -19), Vector2i(-3, -26), "W")
			_lin(fa, Vector2i(1, -19), Vector2i(-2, -26), "w")
			_lin(fa, Vector2i(0, -20), Vector2i(2, -20), "G")
			_cont(fa, "s")
			_sobre(cv, fa)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MILHO)]
		# ---------------------------------------------------------------- Giramiau (girassol)
		Pecas.Tipo.PETALAS_SOL:
			# girassol enorme em volta do rosto: duas voltas de pétalas, miolo marrom de sementes e um sorriso
			var cx: float = 6.5
			var cy: float = -13.5
			for k in 12:
				_petala(cv, cx, cy, k * TAU / 12.0 + 0.26, 3.5, 8.4, 3.2, "f")
			for k in 12:
				_petala(cv, cx, cy, k * TAU / 12.0, 3.5, 7.6, 3.0, "y")
			_disco(cv, cx, cy, 4.7, "m")
			_disco(cv, cx, cy, 4.0, "e")
			for k in cv.keys():
				var v: Vector2i = k
				if cv[v] == "e" and posmod(v.x * 3 + v.y * 5, 4) == 0:
					cv[v] = "E"
			_px(cv, 4, -15, "k")
			_px(cv, 4, -14, "k")
			_px(cv, 8, -15, "k")
			_px(cv, 8, -14, "k")
			_px(cv, 4, -12, "k")
			_px(cv, 5, -11, "k")
			_px(cv, 6, -11, "k")
			_px(cv, 7, -11, "k")
			_px(cv, 8, -12, "k")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_SOL)]
		Pecas.Tipo.CAULE_RAIOS:
			# corpo verde com uma fileira de pequenos sóis bordados e a barra de ponto amarelo
			RoupaGatoF._tronco(cv, "a", -12, -6)
			_luz(cv, "a", "b", "d")
			_cont(cv, "o", false)
			for sx in [-6, -2, 2, 6]:
				_txt(cv, sx - 1, -10, [".y.", "yey", ".y."])
			for x in range(-8, 8):
				if posmod(x, 2) == 0:
					_px(cv, x, -6, "y")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_SOL)]
		Pecas.Tipo.LANTERNA_SOL:
			# lanterna de vidro pendurada na boca, com uma bolinha de luz dentro
			_ret(cv, 10, -12, 13, -10, "n")
			_ret(cv, 12, -13, 18, -11, "g")
			_ret(cv, 12, -13, 18, -12, "G")
			_px(cv, 13, -14, "n")
			_px(cv, 17, -14, "n")
			_ret(cv, 14, -15, 17, -14, "n")
			_ret(cv, 12, -11, 18, -5, "c")
			_ret(cv, 12, -11, 13, -5, "C")
			_ret(cv, 17, -11, 18, -5, "g")
			_disco(cv, 15.0, -8.0, 3.0, "h")
			_disco(cv, 15.0, -8.0, 2.0, "y")
			_disco(cv, 15.0, -8.0, 1.0, "Y")
			_ret(cv, 12, -5, 18, -3, "g")
			_ret(cv, 12, -4, 18, -3, "G")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_SOL)]
		Pecas.Tipo.VASO_SORRISO:
			# vaso de barro com carinha sorridente e um broto de girassol, apoiado no dorso
			_ret(cv, -6, -18, 2, -16, "T")
			_ret(cv, -6, -17, 2, -16, "t")
			_ret(cv, -5, -16, 1, -12, "t")
			_ret(cv, -5, -13, 1, -12, "u")
			_px(cv, -4, -16, "k")
			_px(cv, -1, -16, "k")
			_px(cv, -4, -14, "k")
			_px(cv, -3, -13, "k")
			_px(cv, -2, -13, "k")
			_px(cv, -1, -14, "k")
			_px(cv, -5, -14, "R")
			_px(cv, 0, -14, "R")
			_cont(cv, "u")
			var br: Dictionary = {}
			_ret(br, -3, -22, -2, -18, "a")
			_ret(br, -5, -22, -3, -21, "l")
			_ret(br, -2, -23, 0, -22, "l")
			_txt(br, -4, -26, [".y.", "yey", ".y."])
			_cont(br, "d")
			_sobre(cv, br)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_SOL)]
		# ---------------------------------------------------------------- Stardew Miaulley
		Pecas.Tipo.BONE_FAZENDA:
			# chapéu de palha de fazendeiro: copa, fita verde, aba larga e um broto no topo
			_poli(cv, [2.8, -17, 3.6, -19.6, 5.5, -21.4, 8.2, -21.4, 10, -19.6, 10.8, -17], "s")
			_poli(cv, [-0.5, -15.8, 2, -17.2, 11.5, -17.2, 14.5, -15.8, 13, -14.6, 10, -14.2, 3, -14.2, 0.5, -14.6], "s")
			_ret(cv, 3, -18, 11, -17, "g")
			for k in cv.keys():
				var v: Vector2i = k
				if cv[v] == "s":
					if posmod(v.x + v.y, 3) == 0:
						cv[v] = "d"
					elif v.y <= -20 or (v.y == -16 and posmod(v.x, 2) == 0):
						cv[v] = "S"
			_ret(cv, 1, -15, 13, -14, "d")
			_cont(cv, "o")
			_txt(cv, 5, -25, ["l...l", ".l.l.", "..g.."])
			_px(cv, 7, -22, "g")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_STAR)]
		Pecas.Tipo.MACACAO_JEANS:
			# camisa xadrez vermelha sob um macacão jeans: alça no ombro, peitilho com bolso, botões e costuras
			RoupaGatoF._tronco(cv, "r", -12, -6)
			for k in cv.keys():
				var v: Vector2i = k
				var xa: bool = posmod(v.x, 3) == 0
				var ya: bool = posmod(v.y, 3) == 0
				if xa and ya:
					cv[v] = "E"
				elif xa or ya:
					cv[v] = "R"
			for y in range(-10, -5):
				for x in range(-8, 2):
					if cv.has(Vector2i(x, y)):
						cv[Vector2i(x, y)] = "a"
			for y in range(-8, -5):
				for x in range(2, 8):
					if cv.has(Vector2i(x, y)):
						cv[Vector2i(x, y)] = "a"
			_lin(cv, Vector2i(2, -12), Vector2i(4, -8), "a")
			_lin(cv, Vector2i(3, -12), Vector2i(5, -8), "a")
			_ret(cv, 3, -8, 7, -6, "a")
			_ret(cv, 4, -7, 6, -6, "D")
			_px(cv, 3, -8, "y")
			_px(cv, 7, -8, "y")
			for y in range(-10, -6):
				for x in range(-8, 2):
					if cv.has(Vector2i(x, y)) and posmod(x * 5 + y * 3, 7) == 0:
						cv[Vector2i(x, y)] = "b"
			for x in range(-8, 2, 2):
				_px(cv, x, -10, "y")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_STAR)]
		Pecas.Tipo.ENXADA:
			# enxada de cabo torto (três lances) e lâmina de ferro enferrujada
			_lin(cv, Vector2i(10, -11), Vector2i(15, -12), "m")
			_lin(cv, Vector2i(10, -10), Vector2i(15, -11), "N")
			_lin(cv, Vector2i(15, -12), Vector2i(19, -11), "m")
			_lin(cv, Vector2i(15, -11), Vector2i(19, -10), "N")
			_lin(cv, Vector2i(19, -11), Vector2i(23, -13), "m")
			_lin(cv, Vector2i(19, -10), Vector2i(23, -12), "N")
			_ret(cv, 22, -14, 26, -13, "i")
			_ret(cv, 23, -14, 27, -8, "i")
			_ret(cv, 23, -14, 24, -8, "I")
			_ret(cv, 26, -9, 27, -8, "I")
			_px(cv, 25, -12, "u")
			_px(cv, 26, -11, "u")
			_px(cv, 24, -10, "u")
			_px(cv, 25, -9, "p")
			_px(cv, 26, -13, "u")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_STAR)]
		Pecas.Tipo.GALINHA:
			# galinha branca de estimação sentada no dorso, olhar desconfiado de soslaio
			_poli(cv, [-10, -15.5, -8, -18, -4, -18.5, -1, -17.5, 0, -15.5, -1, -13, -9, -13], "c")
			_pico(cv, Vector2i(-10, -17), Vector2i(-9, -14), Vector2i(-13, -21), "c")
			_pico(cv, Vector2i(-10, -17), Vector2i(-8, -16), Vector2i(-11, -22), "W")
			_disco(cv, 0.5, -19.5, 2.2, "c")
			_ret(cv, -7, -16, -2, -14, "W")
			_lin(cv, Vector2i(-7, -16), Vector2i(-3, -16), "c")
			_ret(cv, -9, -14, -1, -13, "W")
			_cont(cv, "o")
			_px(cv, 0, -23, "r")
			_px(cv, 1, -22, "r")
			_px(cv, 0, -22, "r")
			_px(cv, 2, -19, "p")
			_px(cv, 3, -19, "p")
			_px(cv, 2, -20, "p")
			_px(cv, 2, -18, "q")
			_px(cv, 1, -20, "k")
			_px(cv, 0, -21, "i")
			_px(cv, 1, -21, "i")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_STAR)]
		# ---------------------------------------------------------------- Miaucraft
		Pecas.Tipo.CUBO_PIXEL:
			# cabeça cúbica de pixels (rosto de Steve: cabelo, olhos, nariz e barba) cobrindo a cabeça
			_txt(cv, 3, -19, [
				"hhhhhhhh",
				"hHhhHhhH",
				"hjssssjh",
				"ssssssss",
				"swbssbws",
				"ssSuuSss",
				"smmmmmms",
				"ssmmmmss",
			])
			_ret(cv, 2, -19, 3, -17, "h")
			_ret(cv, 2, -17, 3, -11, "s")
			_px(cv, 2, -17, "j")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_CRAFT)]
		Pecas.Tipo.CAMISETA_BLOCOS:
			# camiseta ciano na frente e calça azul atrás, tudo em blocos com ruído de textura; braço e perna retangulares
			RoupaGatoF._tronco(cv, "a", -12, -6)
			for k in cv.keys():
				var v: Vector2i = k
				if v.x <= -3:
					cv[v] = "p"
				var h: int = posmod(v.x * 7 + v.y * 13, 5)
				if h == 0:
					cv[v] = "A" if cv[v] == "a" else "P"
				elif h == 1:
					cv[v] = "d" if cv[v] == "a" else "q"
			_cont(cv, "o", false)
			var br: Dictionary = {}
			_ret(br, 3, -10, 6, -6, "a")
			_ret(br, 3, -6, 6, -3, "s")
			_ret(br, 3, -10, 4, -3, "S")
			_ret(br, 5, -6, 6, -3, "u")
			_cont(br, "o")
			_sobre(cv, br)
			var pe: Dictionary = {}
			_ret(pe, -8, -6, -4, -3, "p")
			_ret(pe, -8, -3, -4, -2, "n")
			_ret(pe, -8, -6, -7, -3, "P")
			_cont(pe, "o")
			_sobre(cv, pe)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_CRAFT)]
		Pecas.Tipo.PICARETA:
			# picareta de diamante: cabo de madeira em diagonal e a cabeça turquesa em arco
			var cb: Dictionary = {}
			_lin(cb, Vector2i(10, -10), Vector2i(21, -21), "x")
			_lin(cb, Vector2i(11, -10), Vector2i(22, -21), "x")
			_lin(cb, Vector2i(10, -11), Vector2i(21, -22), "X")
			_cont(cb, "o")
			_sobre(cv, cb)
			var ar: Dictionary = {}
			var pts: Array = [Vector2i(13, -23), Vector2i(15, -25), Vector2i(18, -26), Vector2i(21, -26), Vector2i(24, -25), Vector2i(26, -22), Vector2i(27, -19), Vector2i(27, -16), Vector2i(26, -14)]
			for k in pts.size() - 1:
				_lin(ar, pts[k], pts[k + 1], "T")
				_lin(ar, pts[k] + Vector2i(0, 1), pts[k + 1] + Vector2i(0, 1), "T")
				_lin(ar, pts[k] + Vector2i(1, 1), pts[k + 1] + Vector2i(1, 1), "D")
			_luz(ar, "T", "U", "")
			_cont(ar, "o")
			_sobre(cv, ar)
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_CRAFT)]
		Pecas.Tipo.MINI_CREEPER:
			# mini-creeper de pelúcia sentado no dorso, com a carinha triste de sempre
			_txt(cv, -6, -19, [
				"gGgggGg",
				"gkkgkkg",
				"gkkgkkg",
				"gggkggg",
				"ggkkkgg",
				"ggkgkgg",
			])
			_ret(cv, -5, -13, 0, -12, "g")
			_cont(cv, "f")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_CRAFT)]
		# ---------------------------------------------------------------- Miaulax (Snorlax)
		Pecas.Tipo.TOUCA_SONECA:
			# cabeça de Snorlax: capuz azul-esverdeado de orelhas pontudas, rosto creme, olho fechado de sono e dentinhos
			_poli(cv, [2, -14, 3, -17, 5.5, -18, 8.5, -18, 10.5, -17, 11.5, -14, 11.5, -11, 10.5, -9.5, 4, -9.5, 2.5, -11], "a")
			_pico(cv, Vector2i(3, -17), Vector2i(5, -17), Vector2i(2, -21), "a")
			_pico(cv, Vector2i(8, -17), Vector2i(10, -17), Vector2i(11, -21), "a")
			_luz(cv, "a", "b", "d")
			_poli(cv, [4.2, -15.2, 7, -15.6, 11.3, -14.4, 11.3, -11, 10.4, -9.6, 4.4, -9.6, 3.6, -11.5], "c")
			_ret(cv, 6, -16, 8, -15, "C")
			_px(cv, 5, -14, "k")
			_px(cv, 6, -13, "k")
			_px(cv, 7, -13, "k")
			_px(cv, 8, -14, "k")
			_px(cv, 10, -12, "k")
			_ret(cv, 6, -11, 10, -10, "k")
			_px(cv, 7, -10, "w")
			_px(cv, 9, -10, "w")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_LAX)]
		Pecas.Tipo.BARRIGA_CREME:
			# barriga enorme: o corpo incha para cima, para trás e para baixo, passando do contorno do tronco, com o peito creme
			_elipse(cv, -0.5, -9.0, 10.6, 5.9, "a")
			for k in cv.keys():
				var v: Vector2i = k
				if v.x >= 3 and v.y < -9:
					cv.erase(v)
			_luz(cv, "a", "b", "d")
			_elipse(cv, 0.5, -8.0, 7.2, 4.0, "c")
			var ks: Array = cv.keys()
			for k in ks:
				var v: Vector2i = k
				if cv[v] == "c":
					if cv.get(v + Vector2i(0, -1), "") != "c":
						cv[v] = "C"
					elif cv.get(v + Vector2i(0, 1), "") != "c":
						cv[v] = "e"
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_LAX)]
		Pecas.Tipo.TRAVESSEIRO:
			# travesseiro de combate azul com babado, mordido pela boca
			_ret(cv, 11, -15, 21, -7, "p")
			for k in cv.keys():
				var v: Vector2i = k
				if v.y == -15 or v.y == -8 or v.x == 11 or v.x == 20:
					cv[v] = "r" if posmod(v.x + v.y, 2) == 0 else "P"
			_ret(cv, 13, -13, 19, -9, "p")
			_ret(cv, 13, -13, 19, -12, "P")
			_ret(cv, 13, -10, 19, -9, "q")
			_px(cv, 16, -11, "q")
			_px(cv, 15, -11, "W")
			_px(cv, 17, -11, "W")
			_px(cv, 14, -12, "W")
			_px(cv, 18, -10, "W")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_LAX)]
		Pecas.Tipo.PRATO_VAZIO:
			# prato limpo com migalhas e um garfo torto, em pé sobre o dorso
			_disco(cv, -2.5, -17.5, 4.4, "t")
			_disco(cv, -2.5, -17.5, 3.4, "W")
			_disco(cv, -2.5, -17.5, 2.4, "T")
			_disco(cv, -2.5, -17.5, 2.0, "W")
			_px(cv, -5, -19, "w")
			_px(cv, -4, -20, "w")
			_px(cv, -3, -18, "n")
			_px(cv, -1, -16, "n")
			_px(cv, -2, -19, "n")
			_px(cv, -4, -16, "n")
			_cont(cv, "g")
			var gf: Dictionary = {}
			_ret(gf, 2, -19, 4, -13, "g")
			_ret(gf, 2, -19, 3, -13, "G")
			_ret(gf, 1, -23, 5, -20, "g")
			_ret(gf, 2, -23, 3, -20, "G")
			_px(gf, 4, -23, "g")
			_px(gf, 5, -24, "g")
			_px(gf, 3, -21, "o")
			_cont(gf, "o")
			_sobre(cv, gf)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_LAX)]
	return []

static func _fallback(tipo: int) -> Array:
	var col: int = ((tipo - PRIMEIRO) / Pecas.SLOTS) % 4
	return RoupaGatoE.PECAS[(_MOLDE_FALLBACK[Pecas.SLOT[tipo]] as Array)[col]]

static func caixa(tipo: int) -> Rect2:
	var cs: Array = _camadas(tipo, 0.0, true)
	if cs.is_empty():
		var d: Array = _fallback(tipo)
		cs = [[d[0], d[1], d[2], {}]]
	var r := Rect2()
	var primeiro: bool = true
	for cm in cs:
		var larg: int = 0
		for l in cm[2]:
			larg = maxi(larg, (l as String).length())
		var rc := Rect2(cm[0], cm[1], larg, (cm[2] as Array).size())
		r = rc if primeiro else r.merge(rc)
		primeiro = false
	return r

static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	var cs: Array = _camadas(tipo, anim)
	if not cs.is_empty():
		for cm in cs:
			var atras: bool = (cm as Array).size() > 4
			if (RoupaGato.passo == 1 and not atras) or (RoupaGato.passo == 2 and atras):
				continue
			RoupaGato.sprite(c, cm[0], cm[1], cm[2], cm[3], f)
		return
	var d: Array = _fallback(tipo)
	RoupaGato.sprite(c, d[0], d[1], d[2], RoupaGatoE._paleta(tipo), f)
