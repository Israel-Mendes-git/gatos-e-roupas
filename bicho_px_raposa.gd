class_name BichoPxRaposa
extends RefCounted
## Raposas (família 2, fora o chefe Raposa Ligeira) em pixel art, refeitas do zero. Mesmo padrão dos ratos (BichoPxRato):
## olhando para a DIREITA, patas no chão (último pixel em y = -1, contorno do pé em y = 0), 1 unidade = 1 pixel.
##
## Cada quadro é MONTADO em camadas numa grade de letras (rabo, patas de longe, patas de perto, orelha de longe,
## corpo + pescoço + cabeça + orelha de perto numa camada só, adereços). Cada camada ganha um contorno quase preto de 1 px
## (`o`); o interior usa 3 tons (l claro, m médio, d escuro) + `v` focinho/peito claro, `e` interior da orelha, `f` meias das patas,
## `u` ponta branca do rabo, `n` nariz e brilho branco no olho. Recortado, guardado em cache por pose e desenhado com
## RoupaGato.sprite. A geometria (_geo) é a mesma para desenhar() e desloc(): as roupas acompanham o corpo.
## Marca da família: orelhas pontudas, focinho fino e rabão cheio com a ponta clara. Cinco silhuetas:
## Comum (raposa-vermelha laranja, meias escuras), Saltador (fenec: creme, orelhões, senta nas patas e pula),
## Ladrão (raposa-prateada escura, lenço vermelho, máscara e saco), Grandalhão (ruiva-ferrugem larga, cenho, peito
## de juba) e Ninhada (raposa-do-ártico branca com dois filhotes nas costas) + o filhote solto (cabeção).

const _PASSO := 1.3
const _DUR_GOLPE := 0.22
const _HOP := 6.3
const _W := 80
const _H := 52
const _OX := 44
const _OY := 42

static var _cache: Dictionary = {}

# ---------------------------------------------------------------- cabeças (sem contorno; `.` = vazio)
const _CAB: Dictionary = {
	"A": {"js": 6, "ms": 6, "ab": 2, "ct": 5.0, "ex": 5, "ey": 3, "ny": 3, "rows": [
		"..llllll......",
		".lllllllll....",
		"llllllllllmm..",
		"llllmkwmmmmmnn",
		"mmmmmkkmmmmmnn",
		"mmmmmmvvvvvvv.",
		".mmvvvvvvvvv..",
		"..dvvvvvvvv...",
	]},
	"B": {"js": 6, "ms": 5, "ab": 2, "ct": 4.5, "ex": 4, "ey": 3, "ny": 3, "rows": [
		"..lllll.....",
		".lllllllll..",
		"llllllllmm..",
		"lllmkwmmmmnn",
		"mmmmkkmmmmnn",
		"mmmmmvvvvvv.",
		".mvvvvvvvv..",
		"..dvvvvvv...",
	]},
	"C": {"js": 7, "ms": 8, "ab": 3, "ct": 6.0, "ex": 7, "ey": 4, "ny": 3, "rows": [
		"...lllllll......",
		"..lllllllllll...",
		".llllllllllllmm.",
		"llllllkkkkmmmmnn",
		"lllllmmkwmmmmmnn",
		"mmmmmmmmkkvvvvv.",
		"mmmmmmmmmvvvvvv.",
		".vvvvvvvvvvvvv..",
		"..vvvvvvvvvvv...",
		"...dddddddd.....",
	]},
	"D": {"js": 6, "ms": 4, "ab": 2, "ct": 4.0, "ex": 3, "ey": 3, "ny": 3, "rows": [
		"..lllll....",
		".lllllllll.",
		"llllllmmmm.",
		"lllkwmmmmnn",
		"mmmkkmmmmnn",
		"mmmkkmmmmm.",
		".vvvvvvvvv.",
		"..vvvvvvv..",
	]},
}

# orelhas pontudas: r = linhas da de perto; nx/fx = coluna (em relação à cabeça) da de perto / de longe
const _OREL: Dictionary = {
	"1": {"nx": 4, "fx": 1, "r": [
		"..l..",
		".lml.",
		".lel.",
		"lmeem",
		"lmeem",
		"lmmmm",
		"lmmmm",
	]},
	"2": {"nx": 4, "fx": 1, "r": [
		"..ll..",
		".lmml.",
		".leem.",
		".leem.",
		".leem.",
		"lleemm",
		"lleemm",
		"lmmmmm",
		"lmmmmm",
	]},
	"3": {"nx": 5, "fx": 2, "r": [
		"..l...",
		".lml..",
		".lmml.",
		".leem.",
		"lleemm",
		"lleemm",
		"lmmmmm",
		"lmmmmm",
	]},
	"4": {"nx": 3, "fx": 0, "r": [
		".l..",
		"lml.",
		"lemm",
		"lemm",
		"mmmm",
	]},
}

# bx = coluna da esquerda do tronco; bw/bh = largura/altura; pe = altura das patas; hx = coluna da cabeça; hoff = linha da
# cabeça em relação ao topo do tronco; cab = qual cabeça; pf/pt = x das patas da frente/de trás; ore = qual orelha;
# tr = [comprimento, raio, curva] do rabo
const _ESP: Array = [
	{"bx": -10, "bw": 18, "bh": 8, "pe": 6, "hx": 3, "hoff": -3, "cab": "A", "pf": 4, "pt": -8, "ore": "1", "tr": [11, 3, 2]},    # COMUM
	{"bx": -9, "bw": 16, "bh": 8, "pe": 4, "hx": 4, "hoff": 1, "cab": "B", "pf": 4, "pt": -6, "ore": "2", "tr": [13, 3, 0]},     # SALTADOR
	{"bx": -10, "bw": 17, "bh": 8, "pe": 6, "hx": 2, "hoff": -1, "cab": "A", "pf": 3, "pt": -8, "ore": "1", "tr": [10, 3, 2]},    # LADRAO
	{"bx": -11, "bw": 21, "bh": 10, "pe": 6, "hx": 4, "hoff": -1, "cab": "C", "pf": 5, "pt": -9, "ore": "3", "tr": [12, 4, 2]},  # GIGANTE
	{"bx": -11, "bw": 20, "bh": 9, "pe": 6, "hx": 4, "hoff": -3, "cab": "A", "pf": 4, "pt": -9, "ore": "1", "tr": [11, 3, 2]},   # GEMEO (mãe)
]

# ---------------------------------------------------------------- paleta
static func _pal(tipo: int, filhote: bool, alfa: float) -> Dictionary:
	var P: Dictionary = {
		"k": Color("1a1418"), "w": Color("ffffff"), "q": Color("7a1c2c"), "y": Color("f0d048"), "r": Color("d8303c"), "R": Color("8e1a2a"),
		"B": Color("4a90d8"), "S": Color("dcb878"), "s": Color("a8804a"), "t": Color("6e4a28"),
	}
	match tipo:
		Unidade.Tipo.SALTADOR:   # fenec: creme, orelhas rosadas, ponta escura
			P.merge({"o": Color("4a3420"), "l": Color("fff0c8"), "m": Color("f0d29a"), "d": Color("c8a46c"), "v": Color("fffaf0"), "e": Color("d89484"), "f": Color("d0ac76"), "u": Color("4a3828"), "n": Color("3a2a2a")}, true)
		Unidade.Tipo.LADRAO:   # prateada: cinza-escuro, ponta branca
			P.merge({"o": Color("0e0c16"), "l": Color("8e94aa"), "m": Color("5c6078"), "d": Color("383a50"), "v": Color("c4c8d8"), "e": Color("16161e"), "f": Color("16161e"), "u": Color("ffffff"), "n": Color("1a1418")}, true)
		Unidade.Tipo.GIGANTE:   # ruiva-ferrugem, peito de juba
			P.merge({"o": Color("2a120c"), "l": Color("cc6038"), "m": Color("9c3c24"), "d": Color("64241a"), "v": Color("ecc9a0"), "e": Color("2a1410"), "f": Color("2a1410"), "u": Color("f4ecdc"), "n": Color("1a1010")}, true)
		Unidade.Tipo.GEMEO:   # do ártico: branca com sombra azulada
			P.merge({"o": Color("56648a"), "l": Color("ffffff"), "m": Color("e6eef8"), "d": Color("b2c2dc"), "v": Color("ffffff"), "e": Color("e8b4c4"), "f": Color("8a9ab8"), "u": Color("ffffff"), "n": Color("3a3a4a"), "a": Color("f0dcb4"), "b": Color("d0b488"), "c": Color("9a7e5c")}, true)
		_:   # vermelha: laranja, meias escuras, ponta branca
			P.merge({"o": Color("3a1a10"), "l": Color("f8ac4c"), "m": Color("e47a2a"), "d": Color("a84a20"), "v": Color("fff0d8"), "e": Color("3a2018"), "f": Color("3a2018"), "u": Color("fffaf0"), "n": Color("2a1c20")}, true)
	for kk in P.keys():
		var cc: Color = P[kk]
		cc.a = alfa
		P[kk] = cc
	return P

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

static func _elip(L: PackedInt32Array, x: int, y: int, w: int, h: int, lit: String = "l", mid: String = "m", sh: String = "d") -> void:
	var tl: int = maxi(1, int(ceil(h * 0.28)))
	var ts: int = maxi(1, int(ceil(h * 0.26)))
	for j in h:
		for i in w:
			var nx: float = (i + 0.5 - w * 0.5) / (w * 0.5)
			var ny: float = (j + 0.5 - h * 0.5) / (h * 0.5)
			if nx * nx + ny * ny > 1.0:
				continue
			var ch: String = mid
			if j < tl and i < w - 1 - w / 5:
				ch = lit
			elif j >= h - ts:
				ch = sh
			_px(L, x + i, y + j, ch)

static func _tinta(L: PackedInt32Array, x: int, y: int, w: int, h: int, ch: String) -> void:
	for j in h:
		for i in w:
			var nx: float = (i + 0.5 - w * 0.5) / (w * 0.5)
			var ny: float = (j + 0.5 - h * 0.5) / (h * 0.5)
			if nx * nx + ny * ny > 1.0:
				continue
			var ix: int = x + i + _OX
			var jy: int = y + j + _OY
			if ix < 0 or jy < 0 or ix >= _W or jy >= _H:
				continue
			if L[jy * _W + ix] != 0:
				L[jy * _W + ix] = ch.unicode_at(0)

static func _bmp(L: PackedInt32Array, x: int, y: int, rows: Array) -> void:
	for j in rows.size():
		var s: String = rows[j]
		for i in s.length():
			if s[i] != ".":
				_px(L, x + i, y + j, s[i])

static func _trazo(L: PackedInt32Array, x0: int, y0: int, x1: int, y1: int, w: int, ch: String) -> void:
	var n: int = maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in n + 1:
		var t: float = float(i) / float(n)
		_rect(L, roundi(lerpf(x0, x1, t)), roundi(lerpf(y0, y1, t)), w, w, ch)

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

# ---------------------------------------------------------------- pose (comum a desenhar e desloc)
static func _geo(tipo: int, anim: float, andando: bool, golpe: float, filhote: bool, carregando: bool) -> Dictionary:
	var pt: int = BichoPx.pose_truque
	var e: float = 0.0
	if golpe > 0.0:
		e = sin(PI * clampf(1.0 - golpe / _DUR_GOLPE, 0.0, 1.0))
	var sal: bool = tipo == Unidade.Tipo.SALTADOR and not filhote
	var q: int = 0
	var salto: int = 0
	var aire: int = 0
	var bob: int = 0
	var resp: int = 0
	if andando:
		if sal:
			var fase: float = fposmod(anim / _HOP, 1.0)
			if fase >= 0.3 and fase < 0.92:
				var t: float = (fase - 0.3) / 0.62
				salto = roundi(4.0 * sin(PI * t))
				if salto > 0:
					aire = 1 if t < 0.5 else 2
		else:
			q = posmod(int(anim * _PASSO), 6)
			bob = -1 if q % 3 == 1 else 0
	elif golpe <= 0.0:
		resp = (int(Time.get_ticks_msec() / 650) + int(anim * 7.0)) % 2
	var ei: int = roundi(3.0 * e)
	var boca: bool = e > 0.4
	var esp: Dictionary
	if filhote:
		esp = {"bx": -5, "bw": 10, "bh": 6, "pe": 3, "hx": 1, "hoff": -2, "cab": "D", "pf": 2, "pt": -4, "ore": "4", "tr": [7, 2, 1]}
	else:
		esp = _ESP[clampi(tipo, 0, 4)]
	var ch: Dictionary = _CAB[esp["cab"]]
	var rows: Array = ch["rows"]
	var hw: int = String(rows[0]).length()
	var hh: int = rows.size()
	var bw: int = esp["bw"]
	var bh: int = esp["bh"]
	var pe: int = esp["pe"]
	var by0: int = -pe - bh - salto + bob
	by0 -= resp
	bh += resp
	var hdx: int = ei
	var hdy: int = 0
	if aire > 0:
		hdx += 1
		hdy = -1
	match pt:
		Unidade.Tipo.ESCUDEIRO:
			hdx -= 2
			hdy += 2
		Unidade.Tipo.BOMBA:
			hdx += 2
			hdy += 2
		Unidade.Tipo.ATIRADOR:
			if e > 0.0:
				hdx = 0
				hdy = -1
	var hx: int = int(esp["hx"]) + hdx
	var hoff: int = int(esp["hoff"])
	if sal and aire == 0:
		hoff = -6
		hx -= 1
	var hy: int = by0 + hoff + hdy - (resp if tipo == Unidade.Tipo.COMUM else 0)
	return {"q": q, "e": e, "ei": ei, "boca": boca, "salto": salto, "aire": aire, "bob": bob, "resp": resp, "esp": esp, "ch": ch,
		"hw": hw, "hh": hh, "bx": int(esp["bx"]), "bw": bw, "bh": bh, "pe": pe, "by0": by0, "hx": hx, "hy": hy, "pt": pt, "sal": sal, "andando": andando}

static func desloc(onde: int, familia: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Vector2:
	var g: Dictionary = _geo(tipo, anim, andando, golpe, false, false)
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hw: int = g["hw"]
	var hh: int = g["hh"]
	var ch: Dictionary = g["ch"]
	var p: Vector2 = Vector2.ZERO
	match onde:
		RoupaGato.Onde.CABECA:
			p = Vector2(hx + float(ch["ct"]), hy + 1) - RoupaGato.ORIGEM[RoupaGato.Onde.CABECA]
		RoupaGato.Onde.BOCA:
			p = Vector2(hx + hw - 1, hy + int(ch["ny"]) + 2) - RoupaGato.ORIGEM[RoupaGato.Onde.BOCA]
		RoupaGato.Onde.ROSTO:
			p = Vector2(hx + int(ch["ex"]) + 1, hy + int(ch["ey"]) + 1) - RoupaGato.ORIGEM[RoupaGato.Onde.ROSTO]
		RoupaGato.Onde.PESCOCO:
			p = Vector2(hx + 2, hy + hh - 2) - RoupaGato.ORIGEM[RoupaGato.Onde.PESCOCO]
		RoupaGato.Onde.CORPO:
			p = Vector2(int(g["bx"]) + int(g["bw"]) * 0.5, int(g["by0"]) + int(g["bh"]) * 0.5) - RoupaGato.ORIGEM[RoupaGato.Onde.CORPO]
		RoupaGato.Onde.TRASEIRA:
			p = Vector2(int(g["bx"]) + 2, int(g["by0"]) + 1) - RoupaGato.ORIGEM[RoupaGato.Onde.TRASEIRA]
		RoupaGato.Onde.PATAS:
			if int(g["aire"]) > 0:
				return Vector2(0, 5000)
			return Vector2(0, -int(g["salto"]))
	return Vector2(roundf(p.x), roundf(p.y))

# ---------------------------------------------------------------- partes
static func _cab_rows(ch: Dictionary, boca: bool) -> Array:
	var rows: Array = ch["rows"]
	if not boca:
		return rows
	var js: int = ch["js"]
	var ms: int = ch["ms"]
	var base: String = rows[js - 1]
	var fin: int = base.rstrip(".").length() - 1
	var r: Array = []
	for j in js:
		r.append(rows[j])
	r[js - 1] = base.substr(0, fin - 1) + "ww" + base.substr(fin + 1)
	for k in int(ch["ab"]):
		var s: String = base.substr(0, ms)
		for i in range(ms, base.length()):
			s += "q" if base[i] != "." else "."
		if k == 0:
			s = s.substr(0, fin - 1) + "ww" + s.substr(fin + 1)
		r.append(s)
	for j in range(js, rows.size()):
		r.append(rows[j])
	return r

## perna de 2 px do quadril (x, ytop) ao pé (xf, yf); os 3 últimos pixels da perna são a "meia" escura (f) e o pé é uma pata de 3 px
static func _pata(L: PackedInt32Array, x: int, ytop: int, xf: int, yf: int, ch: String, meia: String) -> void:
	var n: int = maxi(1, yf - ytop)
	for i in n + 1:
		var y: int = ytop + i
		var x0: int = roundi(lerpf(x, xf, float(i) / float(n)))
		var c: String = meia if i >= n - 2 else ch
		_px(L, x0, y, c)
		_px(L, x0 + 1, y, c)
	_px(L, xf, yf, meia)
	_px(L, xf + 1, yf, meia)
	_px(L, xf + 2, yf, meia)

static func _pernas(L1: PackedInt32Array, L2: PackedInt32Array, g: Dictionary) -> void:
	var esp: Dictionary = g["esp"]
	var q: int = g["q"]
	var hip: int = int(g["by0"]) + int(g["bh"]) - 3
	var pf: int = esp["pf"]
	var pt: int = esp["pt"]
	var andando: bool = g["andando"]
	var defs: Array = [[pt + 3, 0.5, "d", L1], [pf + 3, 0.0, "d", L1], [pt, 0.0, "m", L2], [pf, 0.5, "m", L2]]
	for d in defs:
		var x: int = d[0]
		var xf: int = x
		var yf: int = -1
		if andando:
			var ph: float = fposmod(float(q) / 6.0 + float(d[1]), 1.0)
			xf = x + roundi(2.5 * cos(TAU * ph))
			yf = -1 - maxi(0, roundi(2.0 * sin(TAU * ph)))
		if int(g["ei"]) > 0 and d[1] == 0.5 and d[2] == "m" and x == pf:
			xf = x + 2 + int(g["ei"])
			yf = maxi(hip + 1, -2 - 2 * int(g["ei"]))
		_pata(d[3], x, hip, xf, yf, d[2], "f")

static func _pernas_sal(L1: PackedInt32Array, L2: PackedInt32Array, g: Dictionary) -> void:
	var bx: int = g["bx"]
	var aire: int = g["aire"]
	var by0: int = g["by0"]
	var bh: int = g["bh"]
	var bw: int = g["bw"]
	var hip: int = by0 + bh - 4
	if aire == 1:
		_trazo(L1, bx + 6, hip, bx - 2, hip + 3, 2, "d")
		_trazo(L1, bx + bw - 4, hip + 1, bx + bw + 3, hip, 2, "d")
		_trazo(L2, bx + 4, hip + 1, bx - 4, hip + 4, 2, "m")
		_trazo(L2, bx + bw - 7, hip + 2, bx + bw + 1, hip + 1, 2, "m")
		_px(L2, bx - 5, hip + 5, "f")
		_px(L2, bx - 6, hip + 5, "f")
		_px(L2, bx + bw + 2, hip + 2, "f")
		_px(L2, bx + bw + 3, hip + 2, "f")
	elif aire == 2:
		_trazo(L1, bx + bw - 4, hip, bx + bw - 1, hip + 4, 2, "d")
		_trazo(L1, bx + 8, hip, bx + 11, hip + 3, 2, "d")
		_trazo(L2, bx + bw - 7, hip + 1, bx + bw - 4, hip + 5, 2, "m")
		_trazo(L2, bx + 5, hip + 1, bx + 9, hip + 4, 2, "m")
		_px(L2, bx + bw - 3, hip + 6, "f")
		_px(L2, bx + bw - 4, hip + 6, "f")
		_px(L2, bx + 10, hip + 5, "f")
		_px(L2, bx + 11, hip + 5, "f")
	else:
		# sentado: pés traseiros apoiados no chão à frente da anca
		_rect(L1, bx + 5, -2, 10, 2, "d")
		_rect(L1, bx + 13, -2, 2, 2, "f")
		_rect(L2, bx + 3, -2, 10, 2, "m")
		_rect(L2, bx + 11, -2, 2, 2, "f")

## Rabão cheio: círculos de raio variável ao longo de uma curva (fino na raiz, gordo no meio, ponta fina e clara `u`).
static func _rabo(L: PackedInt32Array, g: Dictionary, sx: int, sy: int, comp: int, rmax: int, amp: float) -> void:
	var q: int = g["q"]
	var wag: int = roundi(2.0 * sin(TAU * float(q) / 6.0))
	if g["ei"] > 1:
		wag = -3   # no golpe o rabo se ergue
	var n: int = comp * 2
	for i in n + 1:
		var t: float = float(i) / float(n)
		var cx: int = sx - roundi(t * comp)
		var cy: int = sy + roundi(amp * sin(t * PI * 0.9) - 7.0 * t * t + float(wag) * t)
		var rr: float = float(rmax) * (0.5 + 0.5 * sin(PI * pow(t, 0.7))) * (1.0 - 0.45 * t * t)
		var r: int = maxi(1, roundi(rr))
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if dx * dx + dy * dy > r * r + r:
					continue
				var ch: String = "m"
				if dy < -r * 0.4:
					ch = "l"
				elif dy > r * 0.4:
					ch = "d"
				if t >= 0.78:
					ch = "u"
				_px(L, cx + dx, cy + dy, ch)

## filhote pequeno nas costas da mãe: corpo e cabeçona num desenho só (x, y = canto de baixo à esquerda do corpo)
static func _pup(G: PackedInt32Array, x: int, y: int, bw: int, bh: int, hw: int, hh: int) -> void:
	var L := _nova()
	_elip(L, x, y - bh, bw, bh, "a", "b", "c")
	_elip(L, x + bw - 3, y - bh - hh + 2, hw, hh, "a", "b", "b")
	var hx: int = x + bw - 3
	var hy: int = y - bh - hh + 2
	_bmp(L, hx + 1, hy - 2, [".a.", "aea", "bbb"])
	_bmp(L, hx + 3, hy - 2, [".a.", "aea", "bbb"])
	_px(L, hx + hw - 2, hy + hh / 2, "n")
	_px(L, hx + hw - 1, hy + hh / 2, "n")
	var ex: int = hx + hw / 2 - 1
	var ey: int = hy + hh / 2 - 1
	_rect(L, ex, ey, 2, 2, "k")
	_px(L, ex + 1, ey, "w")
	_comp(G, L)

# ---------------------------------------------------------------- montagem do quadro
static func _chave(g: Dictionary, tipo: int, filhote: bool, carregando: bool) -> String:
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [int(g["andando"]), tipo, int(filhote), int(carregando), g["q"], g["ei"], int(g["boca"]), g["aire"], g["salto"], g["resp"], g["pt"]]

static func _monta(tipo: int, filhote: bool, carregando: bool, g: Dictionary) -> Dictionary:
	var G := _nova()
	var esp: Dictionary = g["esp"]
	var ch: Dictionary = g["ch"]
	var bx: int = g["bx"]
	var bw: int = g["bw"]
	var bh: int = g["bh"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hw: int = g["hw"]
	var hh: int = g["hh"]
	var sal: bool = g["sal"]
	var gig: bool = tipo == Unidade.Tipo.GIGANTE and not filhote
	var lad: bool = tipo == Unidade.Tipo.LADRAO and not filhote
	var mae: bool = tipo == Unidade.Tipo.GEMEO and not filhote
	var q: int = g["q"]
	var ore: Dictionary = _OREL[esp["ore"]]
	var orows: Array = ore["r"]
	var oy: int = hy - orows.size() + 1

	# rabo
	var L := _nova()
	var tr: Array = esp["tr"]
	var rsy: int = by0 + 3
	var ramp: float = float(tr[2])
	if sal:
		rsy = by0 + 2 if g["aire"] > 0 else -4
		if g["aire"] > 0:
			ramp = 1.0
	_rabo(L, g, bx + 1, rsy, int(tr[0]), int(tr[1]), ramp)
	_comp(G, L)

	# pernas
	var L1 := _nova()
	var L2 := _nova()
	if sal:
		_pernas_sal(L1, L2, g)
	else:
		_pernas(L1, L2, g)
	_comp(G, L1)
	_comp(G, L2)

	# orelha de longe (mesma forma, tom escuro, um pouco atrás e abaixo)
	var OL := _nova()
	var far: Array = []
	for s in orows:
		far.append(String(s).replace("l", "d").replace("m", "d"))
	_bmp(OL, hx + int(ore["fx"]), oy + 1, far)
	_comp(G, OL)

	# corpo + pescoço + cabeça + orelha de perto numa camada só
	var cab_rows: Array = _cab_rows(ch, g["boca"])
	var B := _nova()
	if sal and g["aire"] == 0:
		_elip(B, bx, -10, 11, 9)                   # anca redonda no chão
		_elip(B, bx + 4, -17, 8, 12)               # tronco inclinado, subindo para a cabeça
	elif sal:
		_elip(B, bx, by0 - 4, 10, bh + 4)
		_elip(B, bx + 6, by0 + 2, bw - 6, bh - 1)
	else:
		_elip(B, bx, by0, bw, bh)
	var py0: int = hy + 2
	_elip(B, hx - 2, py0, 8, maxi(5, by0 + bh - py0 - 1))   # pescoço
	_bmp(B, hx, hy, cab_rows)
	_bmp(B, hx + int(ore["nx"]), oy, orows)
	if sal and g["aire"] == 0:
		_tinta(B, bx + 7, -14, 5, 9, "v")
	elif gig:
		_tinta(B, bx + bw - 9, by0 + bh - 7, 9, 7, "v")   # peito de juba
	elif not filhote:
		_tinta(B, bx + bw - 6, by0 + bh - 5, 6, 5, "v")
	# máscara de ladrão
	if lad:
		for j in range(3, 5):
			for i in range(3, 9):
				var s: String = cab_rows[j]
				if i < s.length() and s[i] != ".":
					_px(B, hx + i, hy + j, "k")
		_px(B, hx + 5, hy + 3, "y")
		_px(B, hx + 6, hy + 3, "w")
		_px(B, hx + 5, hy + 4, "y")
		_px(B, hx + 6, hy + 4, "y")
	_comp(G, B)

	# adereços
	if sal and g["aire"] == 0:
		var CX := _nova()
		_elip(CX, bx + 1, -11, 8, 9)   # coxa traseira redonda
		var ae: int = g["ei"]
		var topo: int = -11 - ae
		var fim: int = -1 - 2 * ae
		_rect(CX, bx + 12 + ae, topo, 2, fim - topo + 1, "m")   # braço dianteiro (sobe e avança no golpe)
		_rect(CX, bx + 12 + ae, fim - 2, 2, 3, "f")
		_px(CX, bx + 14 + ae, fim, "f")
		_comp(G, CX)
	if lad:
		var S := _nova()
		var sx: int = bx
		var sy: int = by0 - 3
		if carregando:
			_rect(S, sx + 1, sy - 6, 3, 3, "r")
			_rect(S, sx + 4, sy - 7, 3, 3, "B")
			_rect(S, sx + 7, sy - 6, 3, 3, "y")
			_elip(S, sx - 1, sy - 4, 13, 10, "S", "s", "t")
			_rect(S, sx + 3, sy - 3, 5, 1, "t")
		else:
			_elip(S, sx + 1, sy - 1, 8, 6, "S", "s", "t")
			_rect(S, sx + 7, sy - 2, 2, 2, "t")
		_comp(G, S)
		var Z := _nova()
		_rect(Z, hx - 1, hy + hh - 4, 6, 2, "r")
		_rect(Z, hx - 1, hy + hh - 2, 5, 1, "R")
		_rect(Z, hx - 4, hy + hh - 4 + (q % 2), 3, 1, "r")
		_rect(Z, hx - 5, hy + hh - 3 + (q % 2), 2, 1, "R")
		_comp(G, Z)
	if mae:
		var yb: int = by0 + 2
		_pup(G, bx - 4, yb + 2, 6, 5, 5, 6)
		_pup(G, bx + 5, yb + 1, 6, 5, 5, 6)

	# recorte
	var x0: int = _W
	var y0: int = _H
	var x1: int = -1
	var y1: int = -1
	for j in _H:
		for i in _W:
			if G[j * _W + i] != 0:
				x0 = mini(x0, i)
				x1 = maxi(x1, i)
				y0 = mini(y0, j)
				y1 = maxi(y1, j)
	var lin: Array = []
	for j in range(y0, y1 + 1):
		var s2: String = ""
		for i in range(x0, x1 + 1):
			var v: int = G[j * _W + i]
			s2 += String.chr(v) if v != 0 else "."
		lin.append(s2)
	return {"x": x0 - _OX, "y": y0 - _OY, "l": lin}

static func desenhar(c: CanvasItem, familia: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var g: Dictionary = _geo(tipo, anim, andando, golpe, filhote, carregando)
	var k: String = _chave(g, tipo, filhote, carregando)
	if not _cache.has(k):
		_cache[k] = _monta(tipo, filhote, carregando, g)
	var s: Dictionary = _cache[k]
	RoupaGato.sprite(c, s["x"], s["y"], s["l"], _pal(tipo, filhote, alfa), f)
