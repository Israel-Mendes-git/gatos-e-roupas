class_name CaoGuarda
extends RefCounted
## Cão de guarda da Casinha (módulo da torre): aliado dos gatos, em pixel art, na mesma grade de pixels dos bichos
## (BichoPx: 1 unidade = 1 pixel do sprite, olhando para a DIREITA, patas no chão em y = 0, centrado em x = 0;
## na tela cada pixel vale `esc` x Desenho.GATO_K, como os bichos comuns).
##
## Mesmo método dos bichos novos (BichoPxRato e cia.): o quadro é montado em camadas numa grade de letras
## (patas de longe, rabo, corpo com as patas de perto, cabeça, orelha, coleira, plaquinha); cada camada ganha um
## contorno escuro de 1 px que a separa das de baixo. O resultado vira corridas de pixels iguais, guardadas em cache por pose.
## Cachorro branco-creme com manchas marrons, orelha caída, rabo abanando e coleira vermelha (o telhado da Casinha)
## com plaquinha dourada: lê como bicho de casa, amigo, bem diferente do Vira-Lata Chefão (caramelo, coleira de pregos).
## Quadros: 4 de trote, parado (o rabo abana sozinho) e latido/bote (golpe: cabeça avança, boca aberta, patas firmes).

const _W := 48
const _H := 34
const _OX := 24            # coluna da grade onde x = 0
const _OY := 30            # linha da grade onde y = 0
const _PASSO := 1.3        # quadros de passo por unidade de anim (o mesmo dos bichos)
const _DUR_GOLPE := 0.22

const PALETA := {
	"o": Color("2c1a16"),                                            # contorno
	"l": Color("fff6e4"), "m": Color("eedcbc"), "d": Color("c8a882"), # pelo creme (claro, médio, sombra)
	"b": Color("b9763e"), "B": Color("7c4622"),                       # manchas marrons
	"k": Color("1c1418"), "w": Color("ffffff"),                       # olho e focinho, brilho
	"p": Color("f0788c"),                                             # língua
	"r": Color("e6403a"), "R": Color("9c1e26"),                       # coleira (vermelho do telhado da Casinha)
	"y": Color("ffd93a"), "Y": Color("c98a14"),                       # plaquinha
}

# cabeça olhando para a direita (sem contorno), 15 x 9: crânio atrás (a orelha cobre), olho na mancha, focinho comprido
const _CAB: Array[String] = [
	"...lllll.......",
	"..lllllllb.....",
	".llllllbbbl....",
	"lllllllbwkbllkk",
	"mmmmmmmbkkbmmkk",
	"mmmmmmmmbbmmmm.",
	"dmmmmmmmmdddd..",
	".dmmmmmmd......",
	"..dddddd.......",
]
# a mesma, latindo: mandíbula aberta com a língua
const _CAB_LATE: Array[String] = [
	"...lllll.......",
	"..lllllllb.....",
	".llllllbbbl....",
	"lllllllbwkbllkk",
	"mmmmmmmbkkbmmkk",
	"mmmmmmmmbbmmkk.",
	"dmmmmmmmmkkkk..",
	".dmmmmmmmkppkd.",
	"..ddddddddddd..",
]
# orelha caída (marrom), por cima do crânio
const _ORELHA: Array[String] = [
	"bbb.",
	"bbbb",
	"Bbbb",
	"Bbbb",
	".BBb",
	"..B.",
]

static var _cache: Dictionary = {}   # chave da pose -> [PackedInt32Array (x, y, larg) das corridas, PackedColorArray]

# ---------------------------------------------------------------- pintura na grade de letras
static func _nova() -> PackedInt32Array:
	var g := PackedInt32Array()
	g.resize(_W * _H)
	return g

static func _px(L: PackedInt32Array, x: int, y: int, ch: String) -> void:
	var i: int = x + _OX
	var j: int = y + _OY
	if i < 0 or j < 0 or i >= _W or j >= _H:
		return
	L[j * _W + i] = ch.unicode_at(0)

static func _rect(L: PackedInt32Array, x: int, y: int, w: int, h: int, ch: String) -> void:
	for j in h:
		for i in w:
			_px(L, x + i, y + j, ch)

static func _bmp(L: PackedInt32Array, x: int, y: int, rows: Array) -> void:
	for j in rows.size():
		var s: String = rows[j]
		for i in s.length():
			if s[i] != ".":
				_px(L, x + i, y + j, s[i])

## Elipse com sombreado: topo claro, miolo médio, barriga escura.
static func _elip(L: PackedInt32Array, x: int, y: int, w: int, h: int) -> void:
	for j in h:
		for i in w:
			var nx: float = (i + 0.5 - w * 0.5) / (w * 0.5)
			var ny: float = (j + 0.5 - h * 0.5) / (h * 0.5)
			if nx * nx + ny * ny > 1.0:
				continue
			var ch: String = "m"
			if j < 2 and i < w - 3:
				ch = "l"
			elif j >= h - 2:
				ch = "d"
			_px(L, x + i, y + j, ch)

## Mancha: pinta só onde a camada já tem pixel (topo claro da mancha, resto escuro na borda de baixo).
static func _mancha(L: PackedInt32Array, x: int, y: int, w: int, h: int) -> void:
	for j in h:
		for i in w:
			var nx: float = (i + 0.5 - w * 0.5) / (w * 0.5)
			var ny: float = (j + 0.5 - h * 0.5) / (h * 0.5)
			if nx * nx + ny * ny > 1.0:
				continue
			var ix: int = x + i + _OX
			var jy: int = y + j + _OY
			if ix < 0 or jy < 0 or ix >= _W or jy >= _H or L[jy * _W + ix] == 0:
				continue
			L[jy * _W + ix] = ("B" if j == h - 1 else "b").unicode_at(0)

## Linha grossa (quadrados w x w ao longo do traço).
static func _trazo(L: PackedInt32Array, x0: int, y0: int, x1: int, y1: int, w: int, ch: String) -> void:
	var n: int = maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in n + 1:
		var t: float = float(i) / float(n)
		_rect(L, roundi(lerpf(x0, x1, t)), roundi(lerpf(y0, y1, t)), w, w, ch)

## Pata de 2 px de largura do alto `ytop` até o chão; a metade de baixo desloca `dx` (passo) e a ponta sobe `ergue`.
static func _pata(L: PackedInt32Array, x: int, ytop: int, dx: int, ergue: int, ch: String, pe: String) -> void:
	var yf: int = -1 - ergue
	var meio: int = (ytop + yf) / 2
	for y in range(ytop, yf + 1):
		var xx: int = x + (dx if y > meio else 0)
		_rect(L, xx, y, 2, 1, ch if y < yf else pe)
	_px(L, x + dx + 2, yf, pe)   # dedos para a frente

## Põe a camada na grade: contorno `o` em volta dos pixels dela (por cima do que havia) e depois o miolo.
static func _comp(G: PackedInt32Array, L: PackedInt32Array, borda: bool = true) -> void:
	if borda:
		for j in _H:
			for i in _W:
				if L[j * _W + i] == 0:
					continue
				if i > 0 and L[j * _W + i - 1] == 0:
					G[j * _W + i - 1] = 111
				if i < _W - 1 and L[j * _W + i + 1] == 0:
					G[j * _W + i + 1] = 111
				if j > 0 and L[(j - 1) * _W + i] == 0:
					G[(j - 1) * _W + i] = 111
				if j < _H - 1 and L[(j + 1) * _W + i] == 0:
					G[(j + 1) * _W + i] = 111
	for k in L.size():
		if L[k] != 0:
			G[k] = L[k]

# ---------------------------------------------------------------- pose
## q: quadro do trote (0 a 3, -1 parado); rabo: 0/1 (abana); late: bote com a boca aberta.
static func _monta(q: int, rabo: int, late: bool) -> Array:
	var bob: int = -1 if (q == 1 or q == 3) else 0
	var pe: int = 5
	var bh: int = 8
	var bw: int = 19
	var bx: int = -10
	var by0: int = -pe - bh + bob + (1 if late else 0)   # no bote ele se firma, um pixel mais baixo
	var hx: int = 5 + (2 if late else 0)
	var hy: int = by0 - 6 - (1 if late else 0)
	# passo do trote em diagonal: par A (frente de perto + trás de longe) e par B (frente de longe + trás de perto)
	var da: int = 0
	var db: int = 0
	var ea: int = 0
	var eb: int = 0
	match q:
		0:
			da = 1
			db = -1
		1:
			ea = 1
		2:
			da = -1
			db = 1
		3:
			eb = 1
	var ff: int = 1 if late else 0   # bote: patas da frente esticam, as de trás empurram
	var G: PackedInt32Array = _nova()
	var yl: int = by0 + bh - 2
	# patas de longe (mais escuras, atrás do corpo)
	var L: PackedInt32Array = _nova()
	_pata(L, 3, yl, db + ff, eb, "d", "d")
	_pata(L, -9, yl, da - ff, ea, "d", "d")
	_comp(G, L)
	# rabo erguido, abanando; ponta clara
	L = _nova()
	var rx: int = -12 if rabo == 0 else -10
	var ry: int = by0 - 5 if rabo == 0 else by0 - 6
	if late:
		rx = -11
		ry = by0 - 6
	_trazo(L, bx + 1, by0 + 2, rx, ry, 2, "b")
	_rect(L, rx, ry, 2, 2, "l")
	_comp(G, L)
	# corpo com as patas de perto (uma massa só, para não riscar contorno dentro do tronco) e a mancha do lombo
	L = _nova()
	_elip(L, bx, by0, bw, bh)
	_pata(L, 5, yl, da + ff, ea, "m", "l")
	_pata(L, -7, yl, db - ff, eb, "m", "l")
	_mancha(L, bx + 3, by0 - 1, 8, 5)
	_comp(G, L)
	# cabeça e orelha
	L = _nova()
	_bmp(L, hx, hy, _CAB_LATE if late else _CAB)
	_comp(G, L)
	L = _nova()
	_bmp(L, hx + 1, hy - 1, _ORELHA)
	_comp(G, L)
	# coleira (sem contorno, colada no pescoço) e a plaquinha pendurada
	L = _nova()
	for j in 5:
		_rect(L, hx - 1, hy + 4 + j, 2, 1, "R" if j == 4 else "r")
	_comp(G, L, false)
	L = _nova()
	_rect(L, hx - 1, hy + 9, 2, 2, "y")
	_px(L, hx, hy + 10, "Y")
	_comp(G, L)
	# corridas horizontais de pixels iguais -> (x, y, largura) e a cor de cada uma
	var rs := PackedInt32Array()
	var cs := PackedColorArray()
	for j in _H:
		var i: int = 0
		while i < _W:
			var v: int = G[j * _W + i]
			if v == 0:
				i += 1
				continue
			var n: int = 1
			while i + n < _W and G[j * _W + i + n] == v:
				n += 1
			rs.append(i - _OX)
			rs.append(j - _OY)
			rs.append(n)
			cs.append(PALETA[String.chr(v)])
			i += n
	return [rs, cs]

static func _quadro(anim: float, andando: bool, golpe: float) -> Array:
	var late: bool = golpe > 0.0 and sin(PI * clampf(1.0 - golpe / _DUR_GOLPE, 0.0, 1.0)) > 0.3
	var q: int = -1
	var rabo: int = 0
	if andando and not late:
		q = posmod(int(anim * _PASSO), 4)
		rabo = q % 2
	else:
		rabo = int(Time.get_ticks_msec() / 220) % 2   # parado, o rabo abana sozinho
	var k: int = (q + 1) * 4 + rabo * 2 + (1 if late else 0)
	if not _cache.has(k):
		_cache[k] = _monta(q, rabo, late)
	return _cache[k]

## Desenha o cão com as patas em `pos`. `dir` 1 = olhando para a direita. `f` = clarão de dano (0 a 1).
static func desenhar(c: CanvasItem, pos: Vector2, esc: float, dir: float, anim: float, andando: bool, golpe: float, f: float = 0.0, alfa: float = 1.0) -> void:
	var s: Array = _quadro(anim, andando, golpe)
	var rs: PackedInt32Array = s[0]
	var cs: PackedColorArray = s[1]
	var k: float = esc * Desenho.GATO_K
	c.draw_set_transform(pos, 0.0, Vector2(k * dir, k))
	for i in cs.size():
		var cor: Color = cs[i]
		if f > 0.0:
			cor = Desenho.b(cor, f)
		if alfa < 1.0:
			cor.a = alfa
		c.draw_rect(Rect2(rs[i * 3], rs[i * 3 + 1], rs[i * 3 + 2], 1), cor)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Folha de quadros para conferência (trote 0 a 3, parado com o rabo nos dois lados, latido), lado a lado a partir de `p0`.
static func folha(c: CanvasItem, p0: Vector2, esc: float) -> void:
	var poses: Array = [[-1, 0, false], [-1, 1, false], [0, 0, false], [1, 1, false], [2, 0, false], [3, 1, false], [-1, 0, true]]
	var k: float = esc * Desenho.GATO_K
	for n in poses.size():
		var pz: Array = poses[n]
		var s: Array = _monta(int(pz[0]), int(pz[1]), bool(pz[2]))
		var rs: PackedInt32Array = s[0]
		var cs: PackedColorArray = s[1]
		c.draw_set_transform(p0 + Vector2(n * 36.0 * k, 0.0), 0.0, Vector2(k, k))
		for i in cs.size():
			c.draw_rect(Rect2(rs[i * 3], rs[i * 3 + 1], rs[i * 3 + 2], 1), cs[i])
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
