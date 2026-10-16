class_name RoupaGatoF
extends RefCounted
## Roupas do gato em pixel art, tipos 100 em diante (ver RoupaGato para as convenções): expansão das fantasias, lote 1
## (Super Miau 100-103, Arqueiro Miau 104-107, Motoqueiro Miausma 108-111, Fênix Miaussimo 112-115, Mimiau 116-119, Jimiau 120-123).
##
## COMO ENCAIXA NO GATO: as peças daqui são desenhadas em COORDENADAS DO GATO (pixel do gato, x para a frente, y para cima, pé em 0):
## o gato parado tem a cabeça em x 3..10 / y -17..-10 (orelha em x 6-7), o dorso em y -12, o tronco em x -8..8 / y -12..-6, o rabo
## em x -11..-6, as patas de trás em x -5..-1 e as da frente em x 5..8. `_lay` converte para o referencial do lugar onde a peça
## fica presa (RoupaGato.ORIGEM), então o desenho acompanha o gato na animação. Cada peça cobre a parte do gato que ela veste
## (nada flutua): capuz e franja abraçam o crânio, roupa de corpo cobre o tronco, capa/aljava/roda ficam ATRÁS do corpo.
##
## CAMADAS ATRÁS: uma camada [x, y, linhas, paleta, true] é desenhada ANTES do gato (RoupaGato.passo = 1; ver Desenho._gato), então só
## aparece o que sai da silhueta (a capa que esvoaça, o topo da aljava, a roda atrás da anca). As demais camadas vão por cima.
##
## FALLBACK: enquanto uma peça não tem arte própria em `_camadas`, desenha a silhueta de uma peça do mesmo espaço (cabeça, corpo,
## mão ou acessório do lado de fora, em RoupaGatoE.PECAS) tingida com a cor da fantasia.

const PRIMEIRO := 100
const _MOLDE_FALLBACK: Array[int] = [Pecas.Tipo.CAPACETE_AZUL, Pecas.Tipo.COLETE_LISTRADO, Pecas.Tipo.KUNAI, Pecas.Tipo.TANQUE]   # por espaço

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão (cabeça, corpo, boca e traseira).
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.CAPA_VERMELHA:
			return RoupaGato.Onde.PESCOCO
		Pecas.Tipo.DISTINTIVO, Pecas.Tipo.FICHAS:
			return RoupaGato.Onde.CORPO
		Pecas.Tipo.PUNHO_ACO:
			return RoupaGato.Onde.PATAS
	return -1

## Peças com camada atrás do corpo do gato (ver o cabeçalho).
static func tem_atras(tipo: int) -> bool:
	return tipo == Pecas.Tipo.CAPA_VERMELHA or tipo == Pecas.Tipo.ALJAVA or tipo == Pecas.Tipo.RODA_FOGO

# ------------------------------------------------------------------ paletas
## Super Miau: o contorno azul-noite, a/b/d azul (médio, claro, sombra), y amarelo, r/R/D vermelho (médio, claro, sombra),
## k/K cabelo preto (médio, brilho), s/S prata (claro, sombra), C contorno da capa.
const _PAL_SUPER := {
	"o": Color(0.05, 0.08, 0.25), "a": Color(0.2, 0.42, 0.95), "b": Color(0.5, 0.7, 1.0), "d": Color(0.1, 0.22, 0.68),
	"y": Color(1.0, 0.86, 0.2), "r": Color(0.86, 0.12, 0.16), "R": Color(1.0, 0.38, 0.34), "D": Color(0.6, 0.06, 0.1),
	"k": Color(0.1, 0.1, 0.16), "K": Color(0.42, 0.46, 0.66), "s": Color(0.9, 0.92, 0.98), "S": Color(0.55, 0.6, 0.74),
	"C": Color(0.36, 0.02, 0.07), "O": Color(0.04, 0.03, 0.08),
}
## Arqueiro: o verde-floresta, a/b/d verde (médio, claro, sombra), k preto, r/R pluma, m/M couro e madeira (médio, claro),
## t barbante, g fivela, c/n ponta de bomba e de rede, e luva de boxe, w branco, h verde da máscara.
const _PAL_ARQ := {
	"o": Color(0.04, 0.14, 0.07), "a": Color(0.2, 0.62, 0.28), "b": Color(0.52, 0.86, 0.5), "d": Color(0.1, 0.38, 0.17),
	"k": Color(0.06, 0.06, 0.08), "r": Color(0.9, 0.18, 0.18), "R": Color(1.0, 0.55, 0.45),
	"m": Color(0.55, 0.32, 0.12), "M": Color(0.84, 0.6, 0.32), "t": Color(0.97, 0.94, 0.82), "g": Color(1.0, 0.82, 0.2),
	"c": Color(0.18, 0.18, 0.22), "n": Color(0.75, 0.8, 0.85), "e": Color(0.9, 0.2, 0.2), "y": Color(1.0, 0.9, 0.3),
	"w": Color(1, 1, 1), "h": Color(0.07, 0.3, 0.14), "N": Color(0.36, 0.2, 0.08),
}
## Motoqueiro: o preto, k/K jaqueta (médio, brilho), w/W osso (claro, sombra), f/F/y fogo (laranja, vermelho, amarelo),
## s/S tachas de prata, c/C corrente (escuro, claro), a pneu, e raio.
const _PAL_MOTO := {
	"o": Color(0.03, 0.02, 0.05), "k": Color(0.13, 0.12, 0.17), "K": Color(0.38, 0.38, 0.5),
	"w": Color(0.96, 0.94, 0.86), "W": Color(0.7, 0.68, 0.6), "f": Color(1.0, 0.52, 0.1), "F": Color(0.9, 0.22, 0.05),
	"y": Color(1.0, 0.88, 0.25), "s": Color(0.92, 0.94, 1.0), "S": Color(0.58, 0.6, 0.72),
	"c": Color(0.5, 0.52, 0.62), "C": Color(0.86, 0.88, 0.96), "a": Color(0.14, 0.13, 0.17), "e": Color(0.02, 0.02, 0.03),
	"m": Color(0.4, 0.25, 0.12),
}
## Fênix: o azul-noite, a/b/d terno (médio, claro, sombra), k/K cabelo, w/W branco (claro, sombra), r/R gravata, g/G ouro,
## h/H pele da mão, m/M/N madeira do martelo (média, clara, escura).
const _PAL_FENIX := {
	"o": Color(0.04, 0.06, 0.2), "a": Color(0.22, 0.36, 0.78), "b": Color(0.48, 0.64, 0.97), "d": Color(0.12, 0.2, 0.5),
	"k": Color(0.1, 0.09, 0.15), "K": Color(0.44, 0.42, 0.62), "w": Color(0.98, 0.98, 1.0), "W": Color(0.74, 0.78, 0.9),
	"r": Color(0.86, 0.12, 0.16), "R": Color(1.0, 0.4, 0.36), "g": Color(1.0, 0.82, 0.22), "G": Color(0.78, 0.5, 0.1),
	"h": Color(0.99, 0.8, 0.66), "H": Color(0.85, 0.56, 0.44),
	"m": Color(0.6, 0.36, 0.16), "M": Color(0.86, 0.62, 0.34), "N": Color(0.36, 0.2, 0.08),
}
## Mimiau: o contorno preto, a/b/d pano amarelo (médio, claro, sombra), k lápis, r bochecha vermelha, s costura,
## t fita, z/p/P mão de sombra (preto-roxo, brilho, contorno de brilho), e/E olhos e garras de luz, c/C papelão (marrom, claro).
const _PAL_MIMI := {
	"o": Color(0.12, 0.09, 0.11), "a": Color(0.98, 0.86, 0.34), "b": Color(1.0, 0.96, 0.62), "d": Color(0.8, 0.64, 0.18),
	"k": Color(0.06, 0.04, 0.08), "r": Color(0.92, 0.2, 0.2), "s": Color(0.45, 0.3, 0.14), "t": Color(0.85, 0.82, 0.72),
	"p": Color(0.55, 0.4, 0.8), "P": Color(0.74, 0.58, 0.98), "z": Color(0.13, 0.06, 0.22), "e": Color(1.0, 0.96, 0.78), "E": Color(1.0, 0.45, 0.4),
	"c": Color(0.62, 0.42, 0.18), "C": Color(0.82, 0.6, 0.3),
}
## Jimiau: o roxo-noite, p/P/d roxo (médio, claro, sombra), g/G verde (médio, claro), y/Y guizo (ouro, brilho), w/W carta, r/k naipes,
## b/B ficha azul, R ficha vermelha, a ficha preta, n/N couro da bolsa.
const _PAL_JIMI := {
	"o": Color(0.13, 0.05, 0.22), "p": Color(0.58, 0.28, 0.85), "P": Color(0.78, 0.55, 0.97), "d": Color(0.36, 0.13, 0.58),
	"g": Color(0.22, 0.7, 0.34), "G": Color(0.6, 0.92, 0.55), "y": Color(1.0, 0.84, 0.22), "Y": Color(1.0, 0.97, 0.7),
	"w": Color(0.98, 0.96, 0.92), "W": Color(0.62, 0.58, 0.74), "r": Color(0.86, 0.14, 0.2), "k": Color(0.12, 0.11, 0.16),
	"b": Color(0.22, 0.42, 0.92), "B": Color(0.55, 0.72, 1.0), "R": Color(0.92, 0.28, 0.3), "a": Color(0.22, 0.2, 0.28),
	"n": Color(0.5, 0.3, 0.14), "N": Color(0.76, 0.52, 0.28),
}

# ------------------------------------------------------------------ ferramentas de desenho (tela de pixels em coordenadas do gato)
## Uma "tela" é {Vector2i: letra}. Os polígonos vêm em pares x,y de CANTO de pixel (o pixel x,y ocupa [x, x+1] × [y, y+1]) e pintam
## os pixels cujo centro cai dentro.
static func _poli(cv: Dictionary, p: Array, ch: String) -> void:
	var pts := PackedVector2Array()
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for i in range(0, p.size(), 2):
		var v := Vector2(float(p[i]), float(p[i + 1]))
		pts.append(v)
		mn = mn.min(v)
		mx = mx.max(v)
	for y in range(floori(mn.y), ceili(mx.y)):
		for x in range(floori(mn.x), ceili(mx.x)):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				cv[Vector2i(x, y)] = ch

## Retângulo de pixels [x0, x1) × [y0, y1).
static func _ret(cv: Dictionary, x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			cv[Vector2i(x, y)] = ch

static func _px(cv: Dictionary, x: int, y: int, ch: String) -> void:
	cv[Vector2i(x, y)] = ch

## Linha de pixels de a até b (Bresenham).
static func _lin(cv: Dictionary, a: Vector2i, b: Vector2i, ch: String) -> void:
	var d := Vector2i(absi(b.x - a.x), absi(b.y - a.y))
	var s := Vector2i(1 if a.x < b.x else -1, 1 if a.y < b.y else -1)
	var e: int = d.x - d.y
	var p: Vector2i = a
	for _i in 200:
		cv[p] = ch
		if p == b:
			break
		var e2: int = 2 * e
		if e2 > -d.y:
			e -= d.y
			p.x += s.x
		if e2 < d.x:
			e += d.x
			p.y += s.y

## Disco de pixels de centro (cx, cy) em canto de pixel e raio r.
static func _disco(cv: Dictionary, cx: float, cy: float, r: float, ch: String) -> void:
	for y in range(floori(cy - r), ceili(cy + r)):
		for x in range(floori(cx - r), ceili(cx + r)):
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				cv[Vector2i(x, y)] = ch

## Ponta triangular de pixels: da base (segmento de a até b) afinando até a ponta `p`.
static func _pico(cv: Dictionary, a: Vector2i, b: Vector2i, p: Vector2i, ch: String) -> void:
	var n: int = maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var q := Vector2i(roundi(lerpf(a.x, b.x, i / float(maxi(n, 1)))), roundi(lerpf(a.y, b.y, i / float(maxi(n, 1)))))
		_lin(cv, q, p, ch)

## Contorno de 1 pixel por fora da forma (nos 4 vizinhos vazios); `baixo` = false deixa a borda de baixo sem contorno.
static func _cont(cv: Dictionary, ch: String, baixo: bool = true) -> void:
	var novos: Array = []
	for k in cv.keys():
		var v: Vector2i = k
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			if d.y == 1 and not baixo:
				continue
			var n: Vector2i = v + d
			if not cv.has(n):
				novos.append(n)
	for n2 in novos:
		cv[n2] = ch

## Luz: o pixel `base` com vazio em cima vira `luz`; com vazio embaixo, `sombra` ("" = não mexe).
static func _luz(cv: Dictionary, base: String, luz: String, sombra: String = "") -> void:
	var mud: Dictionary = {}
	for k in cv.keys():
		var v: Vector2i = k
		if cv[v] != base:
			continue
		if luz != "" and not cv.has(v + Vector2i(0, -1)):
			mud[v] = luz
		elif sombra != "" and not cv.has(v + Vector2i(0, 1)):
			mud[v] = sombra
	for k2 in mud.keys():
		cv[k2] = mud[k2]

## Troca `de` por `para` onde a regra vale.
static func _regra(cv: Dictionary, de: String, para: String, regra: Callable) -> void:
	for k in cv.keys():
		var v: Vector2i = k
		if cv[v] == de and regra.call(v):
			cv[v] = para

## Camada [x, y, linhas, paleta(, true)] da tela, em coordenadas do gato convertidas para o lugar `lugar` (RoupaGato.Onde; -1 = o ponto
## de chão da pata, sem conversão). `atras` = camada atrás do corpo.
static func _lay(cv: Dictionary, lugar: int, pal: Dictionary, atras: bool = false) -> Array:
	var x0: int = 1000000
	var y0: int = 1000000
	var x1: int = -1000000
	var y1: int = -1000000
	for k in cv.keys():
		var v: Vector2i = k
		x0 = mini(x0, v.x)
		y0 = mini(y0, v.y)
		x1 = maxi(x1, v.x)
		y1 = maxi(y1, v.y)
	var linhas: Array = []
	for y in range(y0, y1 + 1):
		var s: String = ""
		for x in range(x0, x1 + 1):
			s += String(cv.get(Vector2i(x, y), "."))
		linhas.append(s)
	var o := Vector2.ZERO if lugar < 0 else RoupaGato.ORIGEM[lugar]
	var r: Array = [x0 - o.x, y0 - o.y, linhas, pal]
	if atras:
		r.append(true)
	return r

## Camada escrita à mão em coordenadas do gato: `x`, `y` = canto de cima à esquerda da primeira linha.
static func _linhas(lugar: int, x: int, y: int, linhas: Array, pal: Dictionary, atras: bool = false) -> Array:
	var cv: Dictionary = {}
	for j in linhas.size():
		var s: String = linhas[j]
		for i in s.length():
			if s[i] != ".":
				cv[Vector2i(x + i, y + j)] = s[i]
	return _lay(cv, lugar, pal, atras)

## Tronco do gato parado (x -8..7, y -12..-6): dorso em y -12 até x 2, peito a partir de y -9, e a barriga que fecha em y -6.
static func _tronco(cv: Dictionary, ch: String, de: int = -12, ate: int = -6) -> void:
	for y in range(de, ate + 1):
		for x in range(-8, 8):
			var topo: int = -12 if x < 3 else -9
			if x < -6:
				topo = -9 if x == -8 else -10
			if x == -6 and y == -12:
				continue
			if y >= topo:
				cv[Vector2i(x, y)] = ch

# ------------------------------------------------------------------ peças feitas por tela
static var _cache: Dictionary = {}

## Capa que esvoaça para trás do pescoço, em onda (`fase` 0 ou 1): sai do ombro, sobe um pouco e vai afinando até a ponta.
static func _capa(fase: int) -> Dictionary:
	var cv: Dictionary = {}
	var n: int = 20
	for k in n:
		var u: float = k / float(n - 1)
		var x: int = 2 - k
		var onda: float = sin(u * 6.5 - fase * PI) * 2.0 * u
		var espinha: float = -12.5 - 3.4 * sin(u * PI * 0.75) + 1.5 * u * u + onda
		var meia: float = (2.4 + 4.8 * sin(u * PI * 0.65)) * (1.0 - 0.8 * u * u * u)
		var topo: int = floori(espinha - meia * 0.55)
		var base: int = ceili(espinha + meia * 0.45)
		for y in range(topo, base):
			cv[Vector2i(x, y)] = "R"
	_regra(cv, "R", "D", func(v: Vector2i) -> bool: return posmod(v.x + 20, 4) == 0 and cv.has(v + Vector2i(0, -1)) and cv.has(v + Vector2i(0, 1)))
	_luz(cv, "R", "r", "D")
	_cont(cv, "C")
	return cv

## Pneu pequeno em chamas (raio 3,6; 7 × 7 pixels) centrado em (cx, cy) em canto de pixel: contorno, pneu com cravos, aro de prata e cubo em brasa
## que pisca (`anim`), com as chamas lambendo o aro por cima e por trás (animadas).
static func _roda(cv: Dictionary, cx: float, cy: float, anim: float) -> void:
	var fase: int = int(anim * 6.0) % 2
	for j in 16:
		for i in 16:
			var x: int = floori(cx - 8.0) + i
			var y: int = floori(cy - 8.0) + j
			var dx: float = x + 0.5 - cx
			var dy: float = y + 0.5 - cy
			var d: float = sqrt(dx * dx + dy * dy)
			var a: float = atan2(dy, dx)
			var ch: String = ""
			if d <= 3.7:
				if d > 3.0:
					ch = "o"
				elif d > 1.9:
					ch = "K" if int(floor((a + PI) / (PI / 4.0))) % 2 == 0 else "a"
				elif d > 0.9:
					ch = "S" if dy > 0.0 else "C"
				else:
					ch = "y" if fase == 0 else "f"
			elif dy < 1.0 and dx < 1.5:
				var lingua: int = int(floor((a + PI) / (PI / 5.0)))
				var alt: float = 1.4 + 2.0 * (0.5 + 0.5 * sin(lingua * 2.3 + fase * 2.6))
				if d <= 3.7 + alt:
					ch = "y" if d < 3.7 + alt * 0.35 else ("f" if d < 3.7 + alt * 0.7 else "F")
			if ch != "":
				cv[Vector2i(x, y)] = ch

## Corrente de elos de aço que sai do punho preso na boca, faz um arco para a frente e para baixo e acaba numa bola de chamas.
static func _corrente(chama: int) -> Dictionary:
	var cv: Dictionary = {}
	var pts: Array = []
	for k in 5:
		var t: float = k / 4.0
		pts.append(Vector2(15.5 + 6.5 * t, -11.0 + 9.0 * t * t))
	for k in pts.size():
		var c: Vector2 = pts[k]
		var cx: int = roundi(c.x)
		var cy: int = roundi(c.y)
		var cor: String = "C" if k % 2 == 0 else "c"
		var forma: Array = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-2, 0), Vector2i(2, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)] if k % 2 == 0 else [Vector2i(0, -2), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(0, 2)]
		for d in forma:
			cv[Vector2i(cx, cy) + d] = cor
	# punho (couro preto com protetor de prata)
	_ret(cv, 12, -13, 14, -10, "k")
	_px(cv, 14, -13, "S")
	_px(cv, 14, -12, "S")
	_px(cv, 14, -11, "S")
	_px(cv, 12, -13, "K")
	# bola de chamas na ponta
	var e: Vector2i = Vector2i(roundi(pts[4].x), roundi(pts[4].y) + 4)
	_disco(cv, e.x + 0.5, e.y + 0.5, 2.6, "f")
	_disco(cv, e.x + 0.5, e.y + 0.7, 1.4, "y")
	for d2 in ([Vector2i(-1, -3), Vector2i(1, -4), Vector2i(2, -3)] if chama == 0 else [Vector2i(-2, -3), Vector2i(0, -4), Vector2i(2, -2)]):
		cv[e + d2] = "F"
	_px(cv, e.x - 1, e.y - 2, "f")
	_px(cv, e.x + 1, e.y - 3 + chama, "y")
	return cv

## Leque de duas cartas grandes (espadas atrás, copas na frente) abrindo da mão (na boca) para cima e para a frente, uma inclinada
## para cada lado; as cartas são tortas de leve (cada linha anda um pouco) para parecerem giradas.
static func _leque() -> Dictionary:
	var cv: Dictionary = {}
	var idx: Dictionary = {}
	var cartas: Array = [[11, -17, -0.28], [15, -16, 0.28]]
	for k in 2:
		var c: Array = cartas[k]
		for j in 8:
			var sh: int = roundi((3.5 - j) * float(c[2]))
			for i in 6:
				idx[Vector2i(int(c[0]) + i + sh, int(c[1]) + j)] = k
	for kv in idx.keys():
		var q: Vector2i = kv
		var k2: int = idx[q]
		var borda: bool = false
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n2: Vector2i = q + dd
			if not idx.has(n2) or int(idx[n2]) > k2:
				borda = true
		cv[q] = "o" if borda else "w"
	# naipes 3 × 3 no alto de cada carta
	var nai: Array = [[".k.", "kkk", ".k."], ["r.r", "rrr", ".r."]]
	for k3 in 2:
		var c3: Array = cartas[k3]
		var sh3: int = roundi((3.5 - 2.0) * float(c3[2]))
		var g: Array = nai[k3]
		for j in 3:
			var st: String = g[j]
			for i in 3:
				if st[i] != ".":
					cv[Vector2i(int(c3[0]) + 1 + i + sh3, int(c3[1]) + 1 + j)] = st[i]
	# canto de cada carta (índice) para o naipe pequeno embaixo
	_px(cv, 12, -11, "k")
	_px(cv, 19, -10, "r")
	return cv

## Camadas da peça com arte própria; vazio = usa o fallback. `maxima` pede a pose mais larga (caixa do ícone).
static func _camadas(tipo: int, anim: float, maxima: bool = false) -> Array:
	var fase: int = 0 if maxima else int(anim * 4.0) % 2
	var chama: int = 0 if maxima else int(anim * 6.0) % 2
	var ch: int = hash([tipo, fase, chama, 0 if maxima else int(anim * 6.0) % 2])
	if _cache.has(ch):
		return _cache[ch]
	var r: Array = _montar(tipo, fase, chama, maxima, anim)
	if _cache.size() > 200:
		_cache.clear()
	_cache[ch] = r
	return r

static func _montar(tipo: int, fase: int, chama: int, maxima: bool, anim: float) -> Array:
	var cv: Dictionary = {}
	match tipo:
		# ---------------------------------------------------------------- Super Miau
		Pecas.Tipo.FRANJA_HEROICA:
			# cabelo preto em capacete sobre o crânio (a orelha some embaixo) e o cacho caído na testa
			_poli(cv, [3, -14.6, 3.4, -16.4, 5, -17.6, 7, -17.8, 9, -17, 10, -15.8, 10.3, -14.6, 9.4, -14.6, 8.2, -15.4, 6.4, -15.4, 5, -15, 4.2, -14.2], "k")
			_poli(cv, [8.6, -15.4, 10.3, -15, 10.8, -13.6, 10, -12.4, 9.2, -12.9, 9.7, -13.8, 8.8, -14.2], "k")
			_px(cv, 5, -17, "K")
			_px(cv, 6, -17, "K")
			_px(cv, 4, -16, "K")
			_cont(cv, "O")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_SUPER)]
		Pecas.Tipo.COLLANT_S:
			# collant azul justo no tronco, cinto amarelo, e o escudo do S (amarelo, S vermelho) no peito
			_tronco(cv, "a")
			_luz(cv, "a", "b", "d")
			_regra(cv, "a", "d", func(v: Vector2i) -> bool: return v.y == -6)
			_cont(cv, "o", false)
			var es: Array = _linhas(RoupaGato.Onde.CORPO, 1, -11, [
				".ooooo.",
				"oyyyyyo",
				"oyrrryo",
				"oyryyyo",
				"oyrrryo",
				"oyyyryo",
				"oyrrryo",
				".oyyyo.",
				"..ooo..",
			], _PAL_SUPER)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_SUPER), es]
		Pecas.Tipo.PUNHO_ACO:
			# bota-luva vermelha com punho amarelo: uma em cada pata (coordenadas do pé)
			_ret(cv, -1, -4, 2, -1, "r")
			_ret(cv, -1, -2, 3, 0, "r")
			_ret(cv, -1, -4, 2, -3, "y")
			_luz(cv, "r", "R", "D")
			_cont(cv, "o", false)
			return [_lay(cv, -1, _PAL_SUPER)]
		Pecas.Tipo.CAPA_VERMELHA:
			# capa vermelha ATRÁS do corpo, esvoaçando; por cima só a gola e o fecho no ombro
			var gola: Array = _linhas(RoupaGato.Onde.PESCOCO, -5, -12, [
				".oooooo.",
				"oRRRRRyo",
				".oDDDDyo",
				"..oooo..",
			], {"o": _PAL_SUPER["C"], "R": _PAL_SUPER["r"], "r": _PAL_SUPER["R"], "D": _PAL_SUPER["D"], "y": _PAL_SUPER["y"]})
			var pc: Dictionary = {"o": _PAL_SUPER["C"], "C": _PAL_SUPER["C"], "R": _PAL_SUPER["r"], "r": _PAL_SUPER["R"], "D": _PAL_SUPER["D"]}
			return [_lay(_capa(fase), RoupaGato.Onde.PESCOCO, pc, true), gola]
		# ---------------------------------------------------------------- Arqueiro Miau
		Pecas.Tipo.CAPUZ_ARQUEIRO:
			# capuz verde de pluma vermelha atrás e a máscara preta acima dos olhos (desenho à mão, sobre o crânio)
			return [[-5.5, -5.0, _l([
				"rR...ooo...",
				".rRoobbaoo.",
				"..oobaaaaoo",
				".oobaaaaaao",
				"oaaaaaaaaao",
				"oddddddddo.",
				"..okkkkkkko",
				"...ookkkkoo",
			]), _PAL_ARQ]]
		Pecas.Tipo.COLETE_FOLHAS:
			# túnica verde de barra picotada, cinto de couro com fivela e a tira da aljava cruzando o peito
			_tronco(cv, "a", -12, -5)
			_luz(cv, "a", "b", "")
			# barra em pontas
			for x in range(-8, 8):
				if (x < -1 or x > 3) and posmod(x, 2) == 0:
					cv.erase(Vector2i(x, -5))
			_regra(cv, "a", "d", func(v: Vector2i) -> bool: return v.y >= -6 and cv.has(v + Vector2i(0, 1)) == false or v.y == -6)
			_ret(cv, -8, -8, 8, -7, "m")
			_px(cv, 4, -8, "g")
			_px(cv, 5, -8, "g")
			_lin(cv, Vector2i(2, -10), Vector2i(-4, -5), "N")
			_lin(cv, Vector2i(3, -10), Vector2i(-3, -5), "m")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_ARQ)]
		Pecas.Tipo.ARCO_RECURVO:
			# arco de madeira curvo com as pontas viradas para fora, corda esticada, empunhadura de couro e uma flecha encaixada
			var lim: Array = [Vector2i(11, -20), Vector2i(12, -19), Vector2i(13, -18), Vector2i(13, -17), Vector2i(14, -16), Vector2i(14, -15), Vector2i(14, -14), Vector2i(15, -13)]
			for k in 8:
				var q2: Vector2i = lim[k]
				cv[q2] = "m"
				cv[Vector2i(q2.x, -23 - q2.y)] = "m"   # espelhado em torno de y = -11,5
			# empunhadura
			for yy in range(-13, -9):
				cv[Vector2i(15, yy)] = "N"
				cv[Vector2i(14, yy)] = "m"
			cv[Vector2i(10, -20)] = "m"
			cv[Vector2i(10, -3)] = "m"
			_lin(cv, Vector2i(11, -20), Vector2i(11, -3), "t")
			# flecha encaixada na corda, apontando para a frente
			_lin(cv, Vector2i(12, -11), Vector2i(19, -11), "M")
			_px(cv, 20, -11, "n")
			_px(cv, 19, -12, "n")
			_px(cv, 19, -10, "n")
			_px(cv, 13, -12, "r")
			_px(cv, 12, -12, "r")
			_px(cv, 13, -10, "r")
			_px(cv, 12, -10, "r")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_ARQ)]
		Pecas.Tipo.ALJAVA:
			# aljava inclinada com três flechas (luva de boxe, bomba e rede), presa às costas: a camada de trás deixa o corpo cobrir o fundo
			# dela, e só o topo com as flechas sai por cima do dorso (a tira de couro cruza o peito no colete)
			return [[-2.5, -7.0, _l([
				"ee..y.nn.",
				"eee.c.nnn",
				".e.cc.nn.",
				"..w.w.w..",
				"..m.m.m..",
				"..ommmmo.",
				"..oMmmmo.",
				"..ogggmo.",
				"..oMmmmo.",
				"...ommo..",
				"....oo...",
			]), _PAL_ARQ, true]]
		# ---------------------------------------------------------------- Motoqueiro Miausma
		Pecas.Tipo.CAVEIRA_CHAMAS:
			# caveira em chamas no lugar da cabeça (x 2..11, y -18..-10, o crânio todo): as orelhas somem sob o osso e as chamas saem do topo;
			# as órbitas guardam um brilho de brasa
			var f0: Array = ["..f..y..f.", ".fFf.fF.fF", "fFyFfFyFfF", "FfyFFfyFfF"] if chama == 0 else [".f..y..f..", "fF.fFf.fFf", "FfFyFfFyFf", "FyfFFfyFfF"]
			return [_linhas(RoupaGato.Onde.CABECA, 2, -22, f0 + [
				"..oooooo..",
				".owwwwwwo.",
				"owwwWwwWwo",
				"owkkwwkkwo",
				"owkfwwkfwo",
				"owwwkkwwwo",
				".owwwwwwo.",
				".owkwwkwo.",
				"..oooooo..",
			], _PAL_MOTO)]
		Pecas.Tipo.JAQUETA_ESPETOS:
			# jaqueta de couro preta: ombreira com espetos, zíper torto, gola, tachas de prata na barra
			_tronco(cv, "k", -12, -5)
			_luz(cv, "k", "K", "")
			for x in range(-8, 8):
				if (x < -1 or x > 3) and posmod(x, 2) == 1:
					cv.erase(Vector2i(x, -5))
			_lin(cv, Vector2i(3, -9), Vector2i(-3, -6), "c")
			# ombreira redonda com tachas e dois espetos
			for x2 in [-5, -2, 1]:
				_px(cv, x2, -13, "S")
				_px(cv, x2, -14, "s")
			_px(cv, 2, -11, "S")
			_px(cv, 0, -11, "S")
			_px(cv, -2, -11, "S")
			for x3 in range(-6, 8, 3):
				_px(cv, x3, -6, "S")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MOTO)]
		Pecas.Tipo.CORRENTE_FOGO:
			return [_lay(_corrente(chama), RoupaGato.Onde.BOCA, _PAL_MOTO)]
		Pecas.Tipo.RODA_FOGO:
			# pneu pequeno em chamas preso na anca por um suporte de aço, atrás do corpo (camada de trás); por cima do quadril só o banco de couro
			_roda(cv, -12.5, -5.5, 0.0 if maxima else anim)
			_lin(cv, Vector2i(-11, -6), Vector2i(-7, -9), "C")
			_lin(cv, Vector2i(-11, -7), Vector2i(-7, -10), "c")
			var sup: Array = _linhas(RoupaGato.Onde.CORPO, -8, -11, [
				"..ooooooo..",
				".okkkkkkko.",
				"oKkkSkkkKko",
				".ooooooooo.",
			], _PAL_MOTO)
			return [_lay(cv, RoupaGato.Onde.TRASEIRA, _PAL_MOTO, true), sup]
		# ---------------------------------------------------------------- Fênix Miaussimo
		Pecas.Tipo.FRANJA_ADVOGADO:
			# cabelo preto com os espetos grandes apontando PARA TRÁS
			_poli(cv, [2.8, -14.4, 3.4, -16.6, 5, -18, 7, -18.4, 9, -17.6, 10.3, -16, 10.5, -14.4, 9, -15, 7.5, -15.6, 6, -15.4, 4.5, -14.6], "k")
			_pico(cv, Vector2i(4, -18), Vector2i(8, -18), Vector2i(-1, -25), "k")
			_pico(cv, Vector2i(3, -17), Vector2i(3, -15), Vector2i(-8, -21), "k")
			_pico(cv, Vector2i(3, -14), Vector2i(3, -12), Vector2i(-8, -14), "k")
			_luz(cv, "k", "K")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_FENIX)]
		Pecas.Tipo.TERNO_TRIBUNAL:
			# terno azul no tronco, lapelas, camisa branca em V e gravata vermelha caindo no peito
			_tronco(cv, "a", -12, -6)
			_luz(cv, "a", "b", "d")
			_ret(cv, 3, -9, 9, -8, "w")
			_ret(cv, 4, -8, 8, -7, "w")
			_ret(cv, 5, -7, 7, -6, "w")
			_lin(cv, Vector2i(3, -9), Vector2i(5, -6), "d")
			_lin(cv, Vector2i(8, -9), Vector2i(7, -7), "d")
			_ret(cv, 5, -9, 7, -8, "r")
			_ret(cv, 5, -8, 7, -5, "r")
			_px(cv, 6, -7, "R")
			_px(cv, 6, -5, "r")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_FENIX)]
		Pecas.Tipo.LUVA_APONTAR:
			# martelo de juiz na boca: cabo de madeira para a frente e a cabeça (cilindro com faixas de ouro e tampas escuras) de pé na ponta
			_ret(cv, 11, -12, 18, -10, "m")
			_ret(cv, 11, -12, 18, -11, "M")
			_ret(cv, 11, -10, 18, -9, "N")
			_ret(cv, 18, -15, 23, -7, "m")
			_ret(cv, 18, -15, 23, -14, "N")
			_ret(cv, 18, -8, 23, -7, "N")
			_ret(cv, 18, -13, 23, -12, "g")
			_ret(cv, 18, -10, 23, -9, "g")
			_ret(cv, 19, -12, 20, -10, "M")
			_px(cv, 22, -12, "N")
			_px(cv, 22, -11, "N")
			_px(cv, 22, -10, "N")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_FENIX)]
		Pecas.Tipo.DISTINTIVO:
			# distintivo dourado redondo preso na lapela, no peito
			_disco(cv, 2.5, -7.5, 1.9, "g")
			_px(cv, 2, -8, "G")
			_px(cv, 3, -7, "G")
			_px(cv, 1, -9, "w")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_FENIX)]
		# ---------------------------------------------------------------- Mimiau
		Pecas.Tipo.CAPUZ_PELUCIA:
			# cabeça de pano amarelo (cobre o gato todo) com as orelhas de Pikachu (uma em pé, outra caída e dobrada, pontas pretas) e o rosto
			# riscado à mão e torto: olhos pretos ovais de tamanhos diferentes, bochechas vermelhas e a boca em zigue-zague
			_poli(cv, [2, -14, 3, -17.5, 5.5, -18.5, 8.5, -18.5, 10.5, -17.5, 11.5, -14, 11.5, -11, 10, -9.5, 4, -9.5, 2.5, -11], "a")
			_poli(cv, [3.4, -17, 6.6, -17.6, 6.2, -21, 5.4, -25.5, 4.2, -25.5, 3.6, -21.5, 3.0, -19], "a")
			_poli(cv, [8, -17.5, 10.6, -17.2, 12.2, -19.4, 14.4, -19.8, 15.6, -18, 15.2, -14.6, 13.8, -14.4, 13.7, -17.2, 12.2, -16.6], "a")
			_luz(cv, "a", "b", "d")
			_regra(cv, "a", "k", func(v: Vector2i) -> bool: return (v.y < -22 and v.x < 8) or (v.x >= 14 and v.y > -19 and v.x > 12))
			_regra(cv, "b", "k", func(v: Vector2i) -> bool: return (v.y < -22 and v.x < 8) or (v.x >= 14 and v.y > -19))
			_regra(cv, "d", "k", func(v: Vector2i) -> bool: return v.x >= 14 and v.y > -19)
			_cont(cv, "o")
			# olhos: o de trás mais alto e comprido, o da frente mais baixo e mais gordo
			_ret(cv, 4, -15, 6, -12, "k")
			_ret(cv, 8, -14, 10, -11, "k")
			_px(cv, 4, -15, "a")
			_px(cv, 5, -15, "k")
			_px(cv, 9, -11, "k")
			# bochechas redondas
			_ret(cv, 3, -11, 5, -9, "r")
			_ret(cv, 10, -11, 12, -9, "r")
			_px(cv, 3, -11, "a")
			_px(cv, 10, -10, "a")
			# boca rabiscada
			for k in 4:
				_px(cv, 6 + k, -10 if k % 2 == 0 else -9, "k")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_MIMI)]
		Pecas.Tipo.DISFARCE_AMARELO:
			# pano amarelo largo cobrindo o tronco e caindo em volta das patas; a barra é irregular e embaixo dela fica a sombra preta
			_tronco(cv, "a", -12, -4)
			for y in range(-9, -3):
				cv[Vector2i(-9, y)] = "a"
				cv[Vector2i(9, y)] = "a"
			_luz(cv, "a", "b", "")
			_regra(cv, "a", "d", func(v: Vector2i) -> bool: return v.y >= -5 or v.x <= -8)
			_cont(cv, "o", false)
			var fundo: Array = [3, 1, 2, 0, 3, 1, 0, 2, 1, 3, 0, 2, 1, 3, 2, 0, 1, 2]
			for i in 18:
				var x: int = -9 + i
				var prof: int = int(fundo[i])
				for j in range(-3, -3 + prof):
					cv[Vector2i(x, j)] = "k" if j < -3 + prof - 1 or prof == 1 else "o"
				cv[Vector2i(x, -4)] = "k" if prof >= 2 else "d"
			# a sombra que espia por baixo do pano: um vão preto entre as patas, com dois olhinhos de luz e um brilho roxo na borda
			_ret(cv, -1, -5, 6, -1, "k")
			cv.erase(Vector2i(-1, -2))
			cv.erase(Vector2i(5, -2))
			for x in range(-1, 6):
				if x % 2 == 0:
					_px(cv, x, -1, "p")
			_px(cv, 1, -4, "e")
			_px(cv, 1, -3, "E")
			_px(cv, 3, -4, "e")
			_px(cv, 3, -3, "E")
			# costura torta e um remendo
			for x in range(-6, 2):
				_px(cv, x, -10 + (x % 2), "s")
			_px(cv, 1, -7, "s")
			_px(cv, 2, -7, "s")
			_px(cv, 1, -6, "s")
			_px(cv, 2, -6, "s")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MIMI)]
		Pecas.Tipo.PATA_MISTERIOSA:
			# mão de sombra que sai do pano: braço grosso e tremido de preto-roxo, palma redonda e quatro garras curvas de luz, tudo com contorno
			# lilás de brilho
			_poli(cv, [7, -6.5, 11, -8.8, 15, -9.2, 17, -8.6, 17.5, -6, 15, -4.8, 11, -5, 7, -4], "z")
			_disco(cv, 17.5, -7.0, 2.8, "z")
			_luz(cv, "z", "p", "")
			_cont(cv, "P")
			# garras curvas de luz (por cima do contorno, para ler como dedos)
			for g in [[Vector2i(19, -9), Vector2i(21, -11), Vector2i(21, -13)], [Vector2i(20, -7), Vector2i(23, -8), Vector2i(24, -10)], [Vector2i(20, -5), Vector2i(23, -5), Vector2i(24, -3)], [Vector2i(18, -4), Vector2i(20, -2), Vector2i(20, 0)]]:
				_lin(cv, g[0], g[1], "P")
				_lin(cv, g[1], g[2], "e")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_MIMI)]
		Pecas.Tipo.RABO_PAPELAO:
			# rabo em raio de Pikachu feito de papelão: a base marrom presa com fita na anca e o raio amarelo em zigue-zague (haste, placa baixa
			# para trás e placa alta para a frente)
			var raio: Array = [
				".......aaaaa",
				".......aaaaa",
				"......aaaaa.",
				".....aaaaa..",
				"....aaaaa...",
				".aaaaaaaa...",
				".aaaaaaa....",
				"..aaaaa.....",
				"....aaa.....",
				"....aaa.....",
				"....aaa.....",
				"....aaa.....",
				"....aaa.....",
				"....ttt.....",
				"...Cccc.....",
				"...Cccc.....",
				"...Cccc.....",
				"...Cccc.....",
				"...Cccc.....",
			]
			for j in raio.size():
				var ln: String = raio[j]
				for i in ln.length():
					if ln[i] != ".":
						cv[Vector2i(-13 + i, -31 + j)] = ln[i]
			_luz(cv, "a", "b", "d")
			_regra(cv, "a", "d", func(v: Vector2i) -> bool: return v.x == -7 and v.y > -24 or (v.y == -24 and v.x >= -9))
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.TRASEIRA, _PAL_MIMI)]
		# ---------------------------------------------------------------- Jimiau
		Pecas.Tipo.CORINGA_CHAPEU:
			# chapéu de bobo de três pontas (trás, cima, frente), roxo e verde, cada ponta com um guizo dourado
			_poli(cv, [2.6, -18, 5.4, -18, -2.5, -14, -5, -15.5], "p")
			_poli(cv, [4.6, -18, 8.4, -18, 7.2, -24, 6, -24], "g")
			_poli(cv, [7.5, -18, 10.6, -16.4, 14.5, -19.2, 13, -21.5], "p")
			_poli(cv, [2.6, -17.2, 10.6, -17.2, 10.6, -14.6, 2.6, -14.6], "d")
			_luz(cv, "d", "P", "")
			_luz(cv, "p", "P", "")
			_luz(cv, "g", "G", "")
			_cont(cv, "o")
			for k in 6:
				_px(cv, 3 + k * 3 / 2 + (k / 2), -15, "y")
			_disco(cv, -4.0, -14.2, 1.1, "y")
			_disco(cv, 7.0, -24.8, 1.1, "y")
			_disco(cv, 14.5, -20.0, 1.1, "y")
			_px(cv, -4, -15, "Y")
			_px(cv, 6, -25, "Y")
			_px(cv, 14, -21, "Y")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_JIMI)]
		Pecas.Tipo.COLETE_BARALHO:
			# colete de arlequim (roxo e verde em losangos) no tronco, gola de bobo em pontas brancas e um naipe no peito
			_tronco(cv, "p", -12, -6)
			_regra(cv, "p", "g", func(v: Vector2i) -> bool: return (floori((v.x + v.y + 100) / 3.0) + floori((v.x - v.y + 100) / 3.0)) % 2 == 0)
			_cont(cv, "o", false)
			# gola de pontas no pescoço
			for k in 6:
				var gx: int = -1 + k
				_px(cv, gx, -11, "w" if k % 2 == 0 else "W")
				_px(cv, gx, -10, "w" if k % 2 == 0 else "W")
			_px(cv, 6, -9, "r")
			_px(cv, 4, -9, "r")
			for p in [Vector2i(4, -8), Vector2i(5, -8), Vector2i(6, -8), Vector2i(5, -7)]:
				_px(cv, p.x, p.y, "r")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_JIMI)]
		Pecas.Tipo.LEQUE_POQUER:
			return [_lay(_leque(), RoupaGato.Onde.BOCA, _PAL_JIMI)]
		Pecas.Tipo.FICHAS:
			# bolsa de couro presa ao quadril por um cinto, com duas pilhas de fichas saindo pela boca
			_ret(cv, -8, -7, -2, -4, "n")
			_ret(cv, -8, -7, -2, -6, "N")
			_ret(cv, -9, -8, 3, -7, "k")
			_px(cv, -5, -8, "y")
			_px(cv, -4, -8, "y")
			for j in 3:
				cv[Vector2i(-8, -10 + j)] = "R" if j % 2 == 0 else "w"
				cv[Vector2i(-7, -10 + j)] = "R" if j % 2 == 0 else "w"
				cv[Vector2i(-6, -10 + j)] = "R" if j % 2 == 0 else "w"
				cv[Vector2i(-4, -11 + j)] = "b" if j % 2 == 0 else "w"
				cv[Vector2i(-3, -11 + j)] = "b" if j % 2 == 0 else "w"
				cv[Vector2i(-2, -11 + j)] = "b" if j % 2 == 0 else "w"
			cv[Vector2i(-6, -9)] = "a"
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_JIMI)]
	return []

## Iguala a largura das linhas (ponto à direita).
static func _l(linhas: Array) -> Array:
	var w: int = 0
	for l in linhas:
		w = maxi(w, String(l).length())
	var r: Array = []
	for l in linhas:
		r.append(String(l).rpad(w, "."))
	return r

static func _fallback(tipo: int) -> Array:
	return RoupaGatoE.PECAS[_MOLDE_FALLBACK[Pecas.SLOT[tipo]]]

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
