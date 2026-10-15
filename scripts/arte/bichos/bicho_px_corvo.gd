class_name BichoPxCorvo
extends RefCounted
## Corvos (família 3, fora o Corvo Velho) em pixel art, refeitos do zero. Convenções gerais em BichoPx:
## olhando para a DIREITA, patas no chão (último pixel em y = -1, contorno do pé em y = 0), 1 unidade = 1 pixel.
##
## Mesmo método de BichoPxRato: cada quadro é MONTADO em camadas numa grade de letras (cauda, patas, asa de longe, corpo + pescoço
## + cabeça numa camada só, asa de perto, adereços), cada camada ganha contorno quase preto de 1 px, o interior usa 3 tons
## (l claro com brilho s, m médio, d escuro) + bico (a/b/c), olho claro com pupila e brilho. O quadro é recortado, guardado em cache
## por pose e desenhado com RoupaGato.sprite. A geometria (_geo) é a mesma para desenhar() e desloc(): as roupas acompanham o corpo.
## Cinco silhuetas: Comum (corvo azul-escuro, cauda curta), Saltador (pega: preto e branco, cauda comprida, pernas altas, pula
## batendo asa), Ladrão (gralha de nuca e peito cinza, olho claro, lenço vermelho e saco), Grandalhão (corvo-roxo parrudo, bico enorme
## claro, cenho) e Ninhada (gralha-de-bico-amarelo cinza-clara com dois pintinhos nas costas) + o filhote solto (cabeçona).
## Golpe = bicada: a cabeça mergulha para a frente, o bico abre e a asa de perto se abre.

const _PASSO := 1.3
const _DUR_GOLPE := 0.22
const _HOP := 6.3
const _W := 80
const _H := 52
const _OX := 44
const _OY := 42

static var _cache: Dictionary = {}

# ---------------------------------------------------------------- cabeças (sem contorno; `.` = vazio)
# js = primeira linha da mandíbula; ms = coluna onde começa o bico de baixo; ab = linhas que o bico aberto acrescenta;
# ct = coluna do meio do alto do crânio; ex/ey = olho; ny = linha do bico (âncora da boca)
const _CAB: Dictionary = {
	"A": {"js": 5, "ms": 9, "ab": 2, "ct": 3.5, "ex": 4, "ey": 3, "ny": 2, "rows": [
		"..sllll........",
		".lllllllmm.....",
		"llllmmmmmaaaa..",
		"lllmewemmaaaaaa",
		"lllmekemmbbbbb.",
		"mmmmmmmmmcccc..",
		".dmmmmmmm......",
		"..ddddddd......",
	]},
	"S": {"js": 5, "ms": 9, "ab": 2, "ct": 3.5, "ex": 4, "ey": 3, "ny": 2, "rows": [
		"..sllll.......",
		".llllllm......",
		"lllmmmmmaaa...",
		"lllmewemmaaaaa",
		"lllmekemmbbbb.",
		"mmmmmmmmmccc..",
		".dmmmmmmm.....",
		"..ddddddd.....",
	]},
	"B": {"js": 5, "ms": 10, "ab": 2, "ct": 3.5, "ex": 5, "ey": 3, "ny": 2, "rows": [
		"..sllll......",
		".lllllllm....",
		"ggglllmmmaaa.",
		"gggGmewemmaaa",
		"gggGmekemmbbb",
		"ggGmmmmmmmcc.",
		".gGmmmmmm....",
		"..GGGGGG.....",
	]},
	"C": {"js": 6, "ms": 11, "ab": 3, "ct": 4.5, "ex": 5, "ey": 4, "ny": 3, "rows": [
		"..sllllll.........",
		".llllllllmm.......",
		"lllllllmmmmmaaaaa.",
		"llllddddmmmaaaaaaa",
		"lllmmewemmmbbbbbbb",
		"lllmmekemmmbbbbbb.",
		"mmmmmmmmmmmccccc..",
		"mmmmmmmmmmmmccc...",
		".dmmmmmmmmmm......",
		"..dddddddddd......",
	]},
	"D": {"js": 5, "ms": 9, "ab": 2, "ct": 3.5, "ex": 4, "ey": 3, "ny": 2, "rows": [
		"...slll.....",
		"..lllllll...",
		".lllllllmaaa",
		"llllewemaaaa",
		"llllekemmbbb",
		"mmmmmmmmmccc",
		".mmmmmmmmm..",
		"..dddddddd..",
	]},
}

# bx = coluna da esquerda do tronco; bw/bh = largura/altura; pe = altura das patas; hx = coluna da cabeça; hoff = linha da cabeça
# em relação ao topo do tronco; cab = qual cabeça; lw = grossura da perna; cola/cw/droop = comprimento, largura e caimento da cauda;
# pn/pl = x do quadril da perna de perto / de longe
const _ESP: Array = [
	{"bx": -10, "bw": 19, "bh": 10, "pe": 4, "hx": 3, "hoff": -6, "cab": "A", "lw": 1, "cola": 9, "cw": 3, "droop": 3, "pn": 2, "pl": -1},     # COMUM
	{"bx": -8, "bw": 15, "bh": 8, "pe": 6, "hx": 2, "hoff": -6, "cab": "S", "lw": 1, "cola": 17, "cw": 3, "droop": -1, "pn": 2, "pl": -1},    # SALTADOR
	{"bx": -10, "bw": 17, "bh": 9, "pe": 4, "hx": 2, "hoff": -5, "cab": "B", "lw": 1, "cola": 9, "cw": 3, "droop": 3, "pn": 2, "pl": -1},      # LADRAO
	{"bx": -11, "bw": 19, "bh": 11, "pe": 4, "hx": 2, "hoff": -6, "cab": "C", "lw": 2, "cola": 10, "cw": 4, "droop": 3, "pn": 2, "pl": -2},   # GIGANTE
	{"bx": -11, "bw": 20, "bh": 10, "pe": 5, "hx": 3, "hoff": -6, "cab": "A", "lw": 1, "cola": 10, "cw": 3, "droop": 3, "pn": 2, "pl": -1},   # GEMEO (mãe)
]

# ---------------------------------------------------------------- paleta
static func _pal(tipo: int, filhote: bool, alfa: float) -> Dictionary:
	var P: Dictionary = {
		"k": Color("14101c"), "w": Color("ffffff"), "q": Color("d83a5c"), "r": Color("d8303c"), "R": Color("8e1a2a"),
		"y": Color("f0d048"), "B": Color("4a90d8"), "S": Color("dcb878"), "s": Color("b8a4ff"), "t": Color("6e4a28"),
		"u": Color("f6efd0"), "U": Color("d8cca0"), "Q": Color("a89a78"), "v": Color("f6f6ff"), "V": Color("b8bcd8"),
	}
	match tipo:
		Unidade.Tipo.SALTADOR:
			P.merge({"o": Color("0a0a14"), "l": Color("4ab4aa"), "m": Color("2c4668"), "d": Color("182036"), "s": Color("86f0d0"),
				"a": Color("52526a"), "b": Color("383852"), "c": Color("26263a"), "e": Color("f4ecb0"), "p": Color("8a8498"), "P": Color("5a566c")}, true)
		Unidade.Tipo.LADRAO:
			P.merge({"o": Color("0a0a12"), "l": Color("8c98d0"), "m": Color("56628e"), "d": Color("343a60"), "s": Color("c8d0ff"),
				"g": Color("d0d4e4"), "G": Color("9aa0bc"), "a": Color("b4b4c4"), "b": Color("84849a"), "c": Color("585870"),
				"e": Color("e0f0ff"), "p": Color("8a8498"), "P": Color("5a566c")}, true)
		Unidade.Tipo.GIGANTE:
			P.merge({"o": Color("120a1c"), "l": Color("9468c8"), "m": Color("603e8c"), "d": Color("3a2354"), "s": Color("dcaaff"),
				"a": Color("e0d8c4"), "b": Color("aca490"), "c": Color("726a58"), "e": Color("ffc83c"), "p": Color("a88c9c"), "P": Color("705a6c")}, true)
		Unidade.Tipo.GEMEO:
			P.merge({"o": Color("1c2234"), "l": Color("d0dcf2"), "m": Color("9eb0d2"), "d": Color("6e7ea4"), "s": Color("ffffff"),
				"a": Color("ffd470"), "b": Color("e0a440"), "c": Color("a8702c"), "e": Color("ff8a5c"), "p": Color("e8744c"), "P": Color("a84c30")}, true)
		_:
			P.merge({"o": Color("080814"), "l": Color("7c8ee0"), "m": Color("46549a"), "d": Color("2a3066"), "s": Color("c0a8ff"),
				"a": Color("b4b4c8"), "b": Color("84849c"), "c": Color("585874"), "e": Color("f4e87c"), "p": Color("8a8498"), "P": Color("5a566c")}, true)
	if filhote:
		P.merge({"o": Color("2c2a3c"), "l": Color("f6efd0"), "m": Color("dccfa4"), "d": Color("aa9c78"), "s": Color("ffffff"),
			"a": Color("ffd470"), "b": Color("e0a440"), "c": Color("c8842c"), "e": Color("ff8a5c"), "p": Color("e8744c"), "P": Color("a84c30")}, true)
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

## Elipse com sombreado: topo claro, miolo médio, barriga escura. Caixa: x, y, largura, altura.
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

## Pinta só onde a camada já tem pixel (manchas por cima do corpo).
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

## Brilho (s) nas penas claras do alto: troca algumas casas `l` por `s`.
static func _brilho(L: PackedInt32Array, x0: int, x1: int, y0: int, y1: int, passo: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if (x + y * 2) % passo != 0:
				continue
			var ix: int = x + _OX
			var jy: int = y + _OY
			if ix < 0 or jy < 0 or ix >= _W or jy >= _H:
				continue
			if L[jy * _W + ix] == 108:
				L[jy * _W + ix] = 115

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
	var agach: int = 0
	var hbx: int = 0
	if andando:
		if sal:
			var fase: float = fposmod(anim / _HOP, 1.0)
			if fase < 0.3:
				agach = 1 if fase > 0.12 else 0
			elif fase < 0.92:
				var t: float = (fase - 0.3) / 0.62
				salto = roundi(5.0 * sin(PI * t))
				if salto > 0:
					aire = 1 if t < 0.5 else 2
		else:
			q = posmod(int(anim * _PASSO), 6)
			bob = -1 if q % 3 == 1 else 0
			hbx = [-1, 0, 1, 1, 0, -1][q]
	elif golpe <= 0.0:
		resp = (int(Time.get_ticks_msec() / 650) + int(anim * 7.0)) % 2
	var ei: int = roundi(3.0 * e)
	var boca: bool = e > 0.4
	var ala: int = 0
	if e > 0.45:
		ala = 2
	elif e > 0.15:
		ala = 1
	if aire == 1:
		ala = 2
	elif aire == 2:
		ala = 1
	var esp: Dictionary
	if filhote:
		esp = {"bx": -5, "bw": 10, "bh": 6, "pe": 3, "hx": 0, "hoff": -3, "cab": "D", "lw": 1, "cola": 3, "cw": 2, "droop": 1, "pn": 1, "pl": -1}
		ala = 0
	else:
		esp = _ESP[clampi(tipo, 0, 4)]
	var ch: Dictionary = _CAB[esp["cab"]]
	var rows: Array = ch["rows"]
	var hw: int = String(rows[0]).length()
	var hh: int = rows.size()
	var bh: int = esp["bh"]
	var pe: int = esp["pe"]
	var by0: int = -pe - bh - salto + bob + agach - resp
	var bh2: int = bh + resp
	var hdx: int = hbx + ei
	var hdy: int = ei
	if aire > 0:
		hdx += 1
		hdy -= 1
	match pt:
		Unidade.Tipo.ESCUDEIRO:
			hdx -= 2   # cabeça baixa e recuada atrás do escudo
			hdy += 2
			ala = 0
		Unidade.Tipo.BOMBA:
			hdx += 2   # corre curvado para a frente sob o peso da bomba
			hdy += 2
			ala = 0
		Unidade.Tipo.ATIRADOR:
			ala = 0
			if e > 0.0:
				hdx = 0   # na hora do tiro fica ereto, mirando
				hdy = -1
	var hx: int = int(esp["hx"]) + hdx
	var hy: int = by0 + int(esp["hoff"]) + hdy
	return {"q": q, "e": e, "ei": ei, "boca": boca, "salto": salto, "aire": aire, "bob": bob, "resp": resp, "esp": esp, "ch": ch, "ala": ala,
		"agach": agach, "hw": hw, "hh": hh, "bx": int(esp["bx"]), "bw": int(esp["bw"]), "bh": bh2, "pe": pe, "by0": by0, "hx": hx, "hy": hy,
		"pt": pt, "sal": sal, "andando": andando}

## Quanto o lugar `onde` se desloca em relação à planta do gato parado (as roupas acompanham por aqui).
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
				return Vector2(0, 5000)   # no ar as patas ficam recolhidas: botas saem de cena em vez de flutuar fora delas
			return Vector2(0, -int(g["salto"]))
	return Vector2(roundf(p.x), roundf(p.y))

# ---------------------------------------------------------------- partes
## Cabeça com o bico aberto: o bico de baixo desce `ab` linhas e o vão fica vermelho.
static func _cab_rows(ch: Dictionary, boca: bool) -> Array:
	var rows: Array = ch["rows"]
	if not boca:
		return rows
	var js: int = ch["js"]
	var ms: int = ch["ms"]
	var base: String = rows[js - 1]
	var r: Array = []
	for j in js:
		r.append(rows[j])
	for k in int(ch["ab"]):
		var s: String = base.substr(0, ms)
		for i in range(ms, base.length()):
			s += "q" if base[i] != "." else "."
		r.append(s)
	for j in range(js, rows.size()):
		r.append(rows[j])
	return r

## perna de lw px do quadril (x, ytop) ao pé (xf, yf); os dedos vão para a frente e um para trás
static func _pata(L: PackedInt32Array, x: int, ytop: int, xf: int, yf: int, ch: String, lw: int) -> void:
	var n: int = maxi(1, yf - ytop)
	for i in n + 1:
		var y: int = ytop + i
		var x0: int = roundi(lerpf(x, xf, float(i) / float(n)))
		_rect(L, x0, y, lw, 1, ch)
	_rect(L, xf - 1, yf, lw + 3, 1, ch)
	if lw > 1:
		_rect(L, xf - 1, yf - 1, 1, 1, ch)

static func _pernas(L1: PackedInt32Array, L2: PackedInt32Array, g: Dictionary) -> void:
	var esp: Dictionary = g["esp"]
	var q: int = g["q"]
	var hip: int = int(g["by0"]) + int(g["bh"]) - 2
	var lw: int = esp["lw"]
	var andando: bool = g["andando"]
	var sal: bool = g["sal"]
	var aire: int = g["aire"]
	# [x do quadril, fase, tom, camada]: a de longe (P) por baixo, a de perto (p) por cima
	var defs: Array = [[int(esp["pl"]), 0.5, "P", L1], [int(esp["pn"]), 0.0, "p", L2]]
	for d in defs:
		var x: int = d[0]
		var xf: int = x
		var yf: int = -1
		if sal and aire > 0:
			# no ar: pernas recolhidas, soltas para trás na subida e para a frente na descida
			xf = x - 3 if aire == 1 else x + 2
			yf = mini(-2, hip + (3 if aire == 1 else 4))
			if d[2] == "P":
				xf -= 1
		elif andando and not sal:
			var ph: float = fposmod(float(q) / 6.0 + float(d[1]), 1.0)
			xf = x + roundi(3.0 * cos(TAU * ph))
			yf = -1 - maxi(0, roundi(-3.0 * sin(TAU * ph)))
		elif sal and int(g["agach"]) > 0:
			xf = x
		if int(g["ei"]) > 0:
			xf = x + (1 if d[2] == "p" else -1)   # bicada: pés firmes no chão, abertos
			yf = -1
		_pata(d[3], x, hip, xf, yf, d[2], lw)

## Cauda em leque (mais larga na ponta, ponta recortada). sx, sy = onde nasce; droop = quanto cai até a ponta.
static func _cola(L: PackedInt32Array, sx: int, sy: int, comp: int, cw: int, droop: int, wag: int) -> void:
	for i in comp + 1:
		var h: int = cw + (i * 2) / maxi(1, comp)
		var y0: int = sy + roundi(float(droop + wag) * float(i) / float(comp))
		for j in h:
			if i >= comp - 1 and j % 2 == 1:
				continue
			var ch: String = "m"
			if j == 0:
				ch = "l" if i % 3 != 1 else "m"
			elif j >= h - 1:
				ch = "d"
			_px(L, sx - i, y0 + j, ch)

## Asa aberta: penas em leque a partir do ombro (sx, sy). `nivel` 2 = bem aberta, 1 = meia; `tam` = comprimento da pena maior.
static func _asa_aberta(L: PackedInt32Array, sx: int, sy: int, nivel: int, tam: int, lit: String, mid: String, sh: String, grosso: int) -> void:
	var angs: Array = [-84.0, -104.0, -124.0, -146.0, -168.0] if nivel >= 2 else [-118.0, -138.0, -156.0, -170.0, -182.0]
	var lens: Array = [tam - 2, tam, tam, tam - 1, tam - 3]
	for i in 5:
		var a: float = deg_to_rad(float(angs[i]))
		var n: int = int(lens[i])
		var tx: int = roundi(sx + cos(a) * n)
		var ty: int = roundi(sy + sin(a) * n)
		_trazo(L, sx, sy, tx, ty, grosso, mid)
		_rect(L, tx, ty, grosso, grosso, sh)
	_elip(L, sx - 6, sy - 4, 10, 8, lit, mid, sh)

## Pintinho nas costas da mãe (x, y = canto de baixo à esquerda do corpo)
static func _pup(G: PackedInt32Array, x: int, y: int, aberto: bool) -> void:
	var L := _nova()
	_elip(L, x, y - 5, 7, 5, "u", "U", "Q")
	_elip(L, x + 3, y - 10, 7, 7, "u", "U", "Q")
	_px(L, x + 5, y - 11, "Q")   # tufo
	_px(L, x + 6, y - 11, "Q")
	_rect(L, x + 6, y - 8, 3, 3, "e")
	_rect(L, x + 7, y - 7, 2, 2, "k")
	_px(L, x + 7, y - 7, "w")
	if aberto:
		_rect(L, x + 10, y - 8, 3, 1, "a")
		_rect(L, x + 10, y - 7, 2, 1, "q")
		_rect(L, x + 10, y - 6, 3, 1, "c")
	else:
		_rect(L, x + 10, y - 7, 3, 1, "a")
		_rect(L, x + 10, y - 6, 2, 1, "c")
	_comp(G, L)

# ---------------------------------------------------------------- montagem do quadro
static func _chave(g: Dictionary, tipo: int, filhote: bool, carregando: bool) -> String:
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [int(g["andando"]), tipo, int(filhote), int(carregando), g["q"], g["ei"], int(g["boca"]), g["aire"], g["salto"], g["resp"], g["pt"], g["ala"], g["agach"]]

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
	var ala: int = g["ala"]
	var gig: bool = tipo == Unidade.Tipo.GIGANTE and not filhote
	var lad: bool = tipo == Unidade.Tipo.LADRAO and not filhote
	var mae: bool = tipo == Unidade.Tipo.GEMEO and not filhote
	var q: int = g["q"]
	var ei: int = g["ei"]

	# cauda
	var L := _nova()
	var wag: int = 0
	if g["andando"] and not sal:
		wag = 1 if q % 3 == 1 else 0
	if ei > 1:
		wag = -3   # na bicada a cauda sobe
	if g["aire"] > 0:
		wag = -2 if g["aire"] == 1 else 1
	_cola(L, bx + 3, by0 + 2 + (1 if filhote else 0), int(esp["cola"]), int(esp["cw"]), int(esp["droop"]), wag)
	_brilho(L, bx - 20, bx + 3, by0 - 2, by0 + 12, 3)
	_comp(G, L)

	# pernas
	var L1 := _nova()
	var L2 := _nova()
	_pernas(L1, L2, g)
	_comp(G, L1)
	_comp(G, L2)

	# asa de longe (só aberta)
	if ala > 0:
		var AL := _nova()
		_asa_aberta(AL, bx + bw - 11, by0 + 3, ala, (15 if gig else 12), "d", "d", "o", 2 if not gig else 3)
		_comp(G, AL)

	# corpo + pescoço + cabeça numa camada só
	var B := _nova()
	_elip(B, bx, by0, bw, bh)
	_elip(B, bx + bw - 10, by0 - 1, 10, maxi(4, bh - 1))   # peito estufado
	var nw: int = 10 if gig else 8
	var ny0: int = hy + 3
	var TR: PackedInt32Array = B.duplicate()   # só o tronco: molde das peças de corpo (BichoPx.quadro)
	_elip(B, hx - 1, ny0, nw, maxi(5, by0 + bh - ny0 - 1))   # pescoço
	if gig:
		_tinta(B, bx + 4, by0 + 1, bw - 8, bh - 3, "m")
	if lad:
		_tinta(B, bx + bw - 11, by0 + 2, 10, bh - 2, "G")
		_tinta(B, bx + bw - 11, by0 + 1, 9, bh - 4, "g")
	if sal:
		_tinta(B, bx + 3, by0 + bh - 6, bw - 6, 6, "v")
		_tinta(B, bx + 3, by0 + bh - 3, bw - 6, 3, "V")
	_brilho(B, bx, bx + bw, by0, by0 + 3, 3)
	var cab_rows: Array = _cab_rows(ch, g["boca"])
	_bmp(B, hx, hy, cab_rows)
	if gig:
		# penas do pescoço arrepiadas
		for i in 4:
			_px(B, hx - 1 + i * 2, hy + hh - 1 + (i % 2), "d")
			_px(B, hx + i * 2, hy + hh, "d")
	_comp(G, B)

	# asa de perto: dobrada no corpo, ou aberta
	var W := _nova()
	if ala > 0:
		_asa_aberta(W, bx + bw - 9, by0 + 2, ala, (16 if gig else 13), "l", "m", "d", 2 if not gig else 3)
		_brilho(W, bx, bx + bw, by0 - 20, by0 + 4, 3)
	else:
		var wx: int = bx + 1
		var wy: int = by0 + 1
		var ww: int = bw - 3
		var whh: int = maxi(4, bh - 3)
		_elip(W, wx, wy, ww, whh)
		_rect(W, bx - 2, by0 + bh - 5, 4, 2, "m")   # pontas das penas passando da anca
		_px(W, bx - 3, by0 + bh - 4, "d")
		_rect(W, wx + 2, wy + whh - 2, ww - 5, 1, "d")   # linha de penas
		if whh > 5:
			_rect(W, wx + 4, wy + whh - 4, ww - 9, 1, "d")
		if sal:
			_tinta(W, wx + ww - 9, wy + 1, 6, 3, "v")   # mancha branca do ombro
		_brilho(W, wx, wx + ww, wy, wy + 2, 3)
	_comp(G, W)

	# adereços
	if lad:
		var S := _nova()
		var sx: int = bx
		var sy: int = by0 - 2
		if carregando:
			_rect(S, sx + 1, sy - 6, 3, 3, "r")
			_rect(S, sx + 4, sy - 7, 3, 3, "B")
			_rect(S, sx + 7, sy - 6, 3, 3, "y")
			_elip(S, sx - 1, sy - 4, 13, 10, "S", "t", "t")
			_elip(S, sx - 1, sy - 4, 13, 10, "S", "S", "t")
			_rect(S, sx + 3, sy - 3, 5, 1, "t")
		else:
			_elip(S, sx + 1, sy - 1, 8, 6, "S", "S", "t")
			_rect(S, sx + 7, sy - 2, 2, 2, "t")
		_comp(G, S)
		var Z := _nova()
		_rect(Z, hx - 1, hy + hh - 3, 6, 2, "r")
		_rect(Z, hx - 1, hy + hh - 1, 5, 1, "R")
		_rect(Z, hx - 4, hy + hh - 3 + (q % 2), 3, 1, "r")
		_rect(Z, hx - 5, hy + hh - 2 + (q % 2), 2, 1, "R")
		_comp(G, Z)
	if mae:
		var yb: int = by0 + 3
		var ab: bool = g["resp"] == 1 or ei > 0
		_pup(G, bx + 1, yb, ab)
		_pup(G, bx + 10, yb - 1, not ab)

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
	return {"x": x0 - _OX, "y": y0 - _OY, "l": lin, "t": BichoPx.recorte(TR, _W, _H, _OX, _OY), "c": BichoPx.cranio(ch["rows"], "abc")}

static func desenhar(c: CanvasItem, familia: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var g: Dictionary = _geo(tipo, anim, andando, golpe, filhote, carregando)
	var k: String = _chave(g, tipo, filhote, carregando)
	if not _cache.has(k):
		_cache[k] = _monta(tipo, filhote, carregando, g)
	var s: Dictionary = _cache[k]
	BichoPx.ultimo_quadro = s   # as roupas leem o molde deste quadro sem refazer a pose
	RoupaGato.sprite(c, s["x"], s["y"], s["l"], _pal(tipo, filhote, alfa), f)

## Quadro em cache do bicho nesta pose (sprite "l" e molde do tronco "t"), para as roupas acompanharem o desenho.
static func quadro(tipo: int, anim: float, andando: bool, golpe: float) -> Dictionary:
	var g: Dictionary = _geo(tipo, anim, andando, golpe, false, false)
	var k: String = _chave(g, tipo, false, false)
	if not _cache.has(k):
		_cache[k] = _monta(tipo, false, false, g)
	return _cache[k]
