class_name BichoPxRato
extends RefCounted
## Ratos (família 0, fora o Rei dos Ratos) em pixel art, refeitos do zero. Convenções gerais em BichoPx:
## olhando para a DIREITA, patas no chão (último pixel em y = -1, contorno do pé em y = 0), 1 unidade = 1 pixel.
##
## Como funciona: cada quadro é MONTADO em camadas numa grade de letras (rabo, patas de longe, patas de perto, orelha de longe,
## corpo + pescoço + cabeça numa camada só, orelha de perto, adereços, bigodes). Cada camada ganha automaticamente um contorno
## quase preto de 1 px (`o`) que a separa das de baixo; o interior usa 3 tons (l claro, m médio, d escuro) + rosa nas orelhas,
## patas, focinho e rabo + brilho branco no olho. O resultado é recortado, guardado em cache por pose e desenhado com
## RoupaGato.sprite (um retângulo por sequência de pixels iguais). A geometria da pose (_geo) é a mesma para desenhar() e
## desloc(), então as roupas (ancoradas por RoupaGato.ORIGEM + desloc) sempre acompanham o corpo.
## Cinco silhuetas: Comum (rato gorducho de orelha redonda), Saltador (magro, agachado, orelhão, perna traseira comprida),
## Ladrão (escuro, lenço vermelho, máscara e saco nas costas), Grandalhão (largo, barriga, cenho), Ninhada (rata rosada com dois
## filhotes nas costas) e o filhote solto (cabecinha enorme).

const _PASSO := 1.3        # quadros de passo por unidade de anim (igual ao dos outros bichos)
const _DUR_GOLPE := 0.22   # duração do golpe (golpe vai de 0.22 a 0)
const _HOP := 6.3          # unidades de anim por pulo do Saltador (~0,45 s a 14 unidades/s)
const _W := 80
const _H := 52
const _OX := 44            # coluna da grade onde x = 0
const _OY := 42            # linha da grade onde y = 0

static var _cache: Dictionary = {}

# ---------------------------------------------------------------- cabeças (sem contorno; `.` = vazio)
# js = primeira linha da mandíbula; ms = coluna onde começa a boca; ab = linhas que a boca aberta acrescenta;
# ct = coluna do meio do alto do crânio; ex/ey = olho (canto de cima à esquerda); ny = linha de cima do nariz
const _CAB: Dictionary = {
	"A": {"js": 6, "ms": 5, "ab": 2, "ct": 4.5, "ex": 5, "ey": 3, "ny": 3, "rows": [
		"..lllll.....",
		".llllllll...",
		"llllmmmmmm..",
		"lllmmkwmmmnn",
		"mmmmmkkmmmnn",
		"mmmmmkkmmmm.",
		".dmmmmmmmm..",
		"..ddddddd...",
	]},
	"B": {"js": 6, "ms": 6, "ab": 2, "ct": 4.5, "ex": 5, "ey": 2, "ny": 3, "rows": [
		"..llllll......",
		".llllllllll...",
		"llllmkwmmmmmm.",
		"lllmmkkmmmmmnn",
		"mmmmmkkmmmmmnn",
		"mmmmmkkmmmmmm.",
		".dmmmmmmmmm...",
		"..dddddddd....",
	]},
	"C": {"js": 7, "ms": 6, "ab": 3, "ct": 5.5, "ex": 8, "ey": 4, "ny": 4, "rows": [
		"...lllllll.....",
		"..lllllllllll..",
		".llllllllllllm.",
		"llllllkkkkkkmm.",
		"lllllmmmkwmmmnn",
		"mmmmmmmmkkmmmnn",
		"mmmmmmmmmmmmmm.",
		"mmmmmmmmmmmmm..",
		".dmmmmmmmmmm...",
		"..dddddddddd...",
	]},
	"D": {"js": 6, "ms": 4, "ab": 2, "ct": 3.5, "ex": 4, "ey": 3, "ny": 4, "rows": [
		"..lllll....",
		".lllllllll.",
		"llllllmmmm.",
		"lllmkwmmmnn",
		"mmmmkkmmmnn",
		"mmmmkkmmmm.",
		".mmmmmmmm..",
		"..dddddd...",
	]},
}

# ---------------------------------------------------------------- medidas de cada tipo (corpo: caixa x, largura, altura, altura das patas)
# bx = coluna da esquerda do tronco; bw/bh = largura/altura; pe = altura das patas; hx = coluna da cabeça; hoff = linha da cabeça
# em relação ao topo do tronco; cab = qual cabeça; pf/pt = x das patas da frente/de trás (a de perto; a de longe fica 3 ao lado)
const _ESP: Array = [
	{"bx": -10, "bw": 18, "bh": 9, "pe": 3, "hx": 3, "hoff": -1, "cab": "A", "pf": 4, "pt": -7},   # COMUM
	{"bx": -9, "bw": 16, "bh": 8, "pe": 3, "hx": 4, "hoff": 1, "cab": "B", "pf": 4, "pt": -6},    # SALTADOR
	{"bx": -10, "bw": 17, "bh": 8, "pe": 3, "hx": 2, "hoff": 0, "cab": "A", "pf": 3, "pt": -7},    # LADRAO
	{"bx": -11, "bw": 20, "bh": 10, "pe": 3, "hx": 4, "hoff": 1, "cab": "C", "pf": 4, "pt": -8},  # GIGANTE
	{"bx": -11, "bw": 20, "bh": 10, "pe": 3, "hx": 4, "hoff": -1, "cab": "A", "pf": 4, "pt": -8},  # GEMEO (mãe)
]

# ---------------------------------------------------------------- paleta
static func _pal(tipo: int, filhote: bool, alfa: float) -> Dictionary:
	var P: Dictionary = {
		"k": Color("1a1418"), "w": Color("ffffff"), "q": Color("7a1c2c"), "y": Color("f0d048"), "r": Color("d8303c"), "R": Color("8e1a2a"),
		"B": Color("4a90d8"), "S": Color("dcb878"), "s": Color("a8804a"), "t": Color("6e4a28"), "W": Color("eceef4"), "z": Color("5a3a20"),
	}
	match tipo:
		Unidade.Tipo.SALTADOR:
			P.merge({"o": Color("3a2818"), "l": Color("f8e8b8"), "m": Color("dec28c"), "d": Color("b0905c"), "p": Color("f5a0a0"), "P": Color("c87a78"), "n": Color("e8708a")}, true)
		Unidade.Tipo.LADRAO:
			P.merge({"o": Color("0e0c16"), "l": Color("7a74a0"), "m": Color("524e72"), "d": Color("383553"), "p": Color("d890a8"), "P": Color("a06880"), "n": Color("e8708a")}, true)
		Unidade.Tipo.GIGANTE:
			P.merge({"o": Color("2e1a10"), "l": Color("c0925e"), "m": Color("8e6238"), "d": Color("5e3c24"), "v": Color("e0be90"), "p": Color("e8a090"), "P": Color("b87060"), "n": Color("e0707c")}, true)
		Unidade.Tipo.GEMEO:
			P.merge({"o": Color("4c303c"), "l": Color("fcecf0"), "m": Color("e6c6d2"), "d": Color("b89aaa"), "p": Color("ff9fb4"), "P": Color("d07890"), "n": Color("f0708c")}, true)
		_:
			P.merge({"o": Color("24222e"), "l": Color("c2c8da"), "m": Color("9097ae"), "d": Color("5f6682"), "p": Color("f0a6b8"), "P": Color("c07a90"), "n": Color("e8788f")}, true)
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

## Pinta só onde a camada já tem pixel (manchas por cima do corpo, como a barriga clara).
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

## Linha grossa (quadrados w x w ao longo do traço)
static func _trazo(L: PackedInt32Array, x0: int, y0: int, x1: int, y1: int, w: int, ch: String) -> void:
	var n: int = maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in n + 1:
		var t: float = float(i) / float(n)
		_rect(L, roundi(lerpf(x0, x1, t)), roundi(lerpf(y0, y1, t)), w, w, ch)

## Põe a camada na grade: contorno `o` em volta dos pixels da camada (por cima do que havia) e depois o miolo.
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
			q = 0
		else:
			q = posmod(int(anim * _PASSO), 6)
			bob = -1 if q % 3 == 1 else 0
	elif golpe <= 0.0:
		resp = (int(Time.get_ticks_msec() / 650) + int(anim * 7.0)) % 2
	var ei: int = roundi(3.0 * e)
	var boca: bool = e > 0.4
	var esp: Dictionary
	var ch: Dictionary
	if filhote:
		esp = {"bx": -5, "bw": 10, "bh": 7, "pe": 2, "hx": 1, "hoff": -3, "cab": "D", "pf": 2, "pt": -4}
	else:
		esp = _ESP[clampi(tipo, 0, 4)]
	ch = _CAB[esp["cab"]]
	var rows: Array = ch["rows"]
	var hw: int = String(rows[0]).length()
	var hh: int = rows.size()
	var bw: int = esp["bw"]
	var bh: int = esp["bh"]
	var pe: int = esp["pe"]
	var by0: int = -pe - bh - salto + bob
	if sal and aire == 0 and andando:
		by0 += 0
	var bh2: int = bh
	by0 -= resp
	bh2 += resp
	var hdx: int = ei
	var hdy: int = 0
	if aire > 0:
		hdx += 1
		hdy = -1
	match pt:
		Unidade.Tipo.ESCUDEIRO:
			hdx -= 2   # cabeça baixa e recuada atrás do escudo
			hdy += 2
		Unidade.Tipo.BOMBA:
			hdx += 2   # corre curvado para a frente sob o peso da bomba
			hdy += 2
		Unidade.Tipo.ATIRADOR:
			if e > 0.0:
				hdx = 0   # na hora do tiro fica ereto, mirando
				hdy = -1
	var hx: int = int(esp["hx"]) + hdx
	var hoff: int = int(esp["hoff"])
	if sal and aire == 0:
		hoff = -6   # sentado nas patas traseiras: cabeça no alto, corpo inclinado
		hx -= 1
	var hy: int = by0 + hoff + hdy - (resp if tipo == Unidade.Tipo.COMUM else 0)
	return {"q": q, "e": e, "ei": ei, "boca": boca, "salto": salto, "aire": aire, "bob": bob, "resp": resp, "esp": esp, "ch": ch,
		"hw": hw, "hh": hh, "bx": int(esp["bx"]), "bw": bw, "bh": bh2, "pe": pe, "by0": by0, "hx": hx, "hy": hy, "pt": pt, "sal": sal, "andando": andando}

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
				return Vector2(0, 5000)   # no ar as patas ficam esticadas: botas saem de cena em vez de flutuar fora delas
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
	# dentes de cima (incisivos) pendurados na linha do lábio
	var lab: String = base.substr(0, fin - 1) + "ww" + base.substr(fin + 1)
	r[js - 1] = lab
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

static func _pata(L: PackedInt32Array, x: int, ytop: int, xf: int, yf: int, ch: String, dedo: String) -> void:
	# perna de 2 px do quadril (x, ytop) ao pé (xf, yf = linha de baixo); o pé é uma pata rosa de 3 px
	var n: int = maxi(1, yf - ytop)
	for i in n + 1:
		var y: int = ytop + i
		var x0: int = roundi(lerpf(x, xf, float(i) / float(n)))
		_px(L, x0, y, ch)
		_px(L, x0 + 1, y, ch)
	_px(L, xf, yf, ch)
	_px(L, xf + 1, yf, dedo)
	_px(L, xf + 2, yf, dedo)

static func _pernas(L1: PackedInt32Array, L2: PackedInt32Array, g: Dictionary) -> void:
	var esp: Dictionary = g["esp"]
	var q: int = g["q"]
	var hip: int = int(g["by0"]) + int(g["bh"]) - 3
	var pf: int = esp["pf"]
	var pt: int = esp["pt"]
	var andando: bool = g["andando"]
	# [x do quadril, fase (as diagonais andam juntas), tom, camada]: as de longe (d) por baixo, as de perto (m) por cima
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
			xf = x + 2 + int(g["ei"])   # golpe: pata dianteira de perto sobe e avança
			yf = maxi(hip + 1, -2 - 2 * int(g["ei"]))
		_pata(d[3], x, hip, xf, yf, d[2], "p")

static func _pernas_sal(L1: PackedInt32Array, L2: PackedInt32Array, g: Dictionary) -> void:
	var bx: int = g["bx"]
	var aire: int = g["aire"]
	var by0: int = g["by0"]
	var bh: int = g["bh"]
	var bw: int = g["bw"]
	var hip: int = by0 + bh - 4
	if aire == 1:
		# subindo: traseiras esticadas para trás, dianteiras para a frente
		_trazo(L1, bx + 6, hip, bx - 2, hip + 3, 2, "d")
		_trazo(L1, bx + bw - 4, hip + 1, bx + bw + 3, hip, 2, "d")
		_trazo(L2, bx + 4, hip + 1, bx - 4, hip + 4, 2, "m")
		_trazo(L2, bx + bw - 7, hip + 2, bx + bw + 1, hip + 1, 2, "m")
		_px(L2, bx - 5, hip + 5, "p")
		_px(L2, bx - 6, hip + 5, "p")
		_px(L2, bx + bw + 2, hip + 2, "p")
		_px(L2, bx + bw + 3, hip + 2, "p")
	elif aire == 2:
		# descendo: dianteiras alcançando o chão, traseiras recolhidas sob a barriga
		_trazo(L1, bx + bw - 4, hip, bx + bw - 1, hip + 4, 2, "d")
		_trazo(L1, bx + 8, hip, bx + 11, hip + 3, 2, "d")
		_trazo(L2, bx + bw - 7, hip + 1, bx + bw - 4, hip + 5, 2, "m")
		_trazo(L2, bx + 5, hip + 1, bx + 9, hip + 4, 2, "m")
		_px(L2, bx + bw - 3, hip + 6, "p")
		_px(L2, bx + bw - 4, hip + 6, "p")
		_px(L2, bx + 10, hip + 5, "p")
		_px(L2, bx + 11, hip + 5, "p")
	else:
		# sentado: pés traseiros compridos apoiados no chão à frente da anca; braços curtos no peito
		var ei: int = g["ei"]
		_rect(L1, bx + 5, -2, 11, 2, "d")
		_rect(L1, bx + 14, -2, 2, 2, "p")
		_rect(L2, bx + 3, -2, 11, 2, "m")
		_rect(L2, bx + 12, -2, 2, 2, "p")

static func _rabo(L: PackedInt32Array, g: Dictionary, tipo: int, sx: int, sy: int, comp: int) -> void:
	var q: int = g["q"]
	var wag: int = roundi(2.0 * sin(TAU * float(q) / 6.0))
	if g["ei"] > 1:
		wag = -2   # no golpe o rabo se ergue
	var n: int = comp * 2
	var ant_x: int = sx
	var ant_y: int = sy
	for i in n + 1:
		var t: float = float(i) / float(n)
		var px: int = sx - roundi(t * comp)
		var py: int = sy + roundi(3.0 * sin(t * PI * 0.8) - 6.0 * t * t * t + float(wag) * t)
		var n2: int = maxi(1, maxi(absi(px - ant_x), absi(py - ant_y)))
		for k in n2:
			var tt: float = float(k + 1) / float(n2)
			_px(L, roundi(lerpf(ant_x, px, tt)), roundi(lerpf(ant_y, py, tt)), "p" if t < 0.85 else "P")
		ant_x = px
		ant_y = py

static func _orelha(L: PackedInt32Array, x: int, y: int, w: int, h: int, longe: bool) -> void:
	if longe:
		_elip(L, x, y, w, h, "d", "d", "d")
		_tinta(L, x + 1, y + 1, w - 2, h - 2, "P")
	else:
		_elip(L, x, y, w, h, "l", "m", "m")
		_tinta(L, x + 1, y + 1, w - 2, h - 2, "p")

## filhote pequeno: corpo e cabeçona num desenho só (x, y = canto de baixo à esquerda do corpo)
static func _pup(G: PackedInt32Array, x: int, y: int, bw: int, bh: int, hw: int, hh: int) -> void:
	var L := _nova()
	_elip(L, x, y - bh, bw, bh)
	_elip(L, x + bw - 3, y - bh - hh + 2, hw, hh)
	_px(L, x + bw - 3 + hw - 2, y - bh - hh + 2 + hh / 2, "n")
	_px(L, x + bw - 3 + hw - 1, y - bh - hh + 2 + hh / 2, "n")
	var ex: int = x + bw - 3 + hw / 2 - 1
	var ey: int = y - bh - hh + 2 + hh / 2 - 1
	_rect(L, ex, ey, 2, 2, "k")
	_px(L, ex + 1, ey, "w")
	_comp(G, L)
	var O := _nova()
	_orelha(O, x + bw - 3 + 1, y - bh - hh - 1, 4, 4, false)
	_comp(G, O)

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

	# rabo
	var L := _nova()
	var rsy: int = by0 + 4
	var rcomp: int = 13
	if sal:
		rsy = by0 + 2 if g["aire"] > 0 else -5
		rcomp = 15
	elif filhote:
		rcomp = 6
		rsy = by0 + 3
	elif gig:
		rcomp = 11
	_rabo(L, g, tipo, bx + 1, rsy, rcomp)
	if sal:
		# tufo escuro na ponta do rabo
		var tx0: int = bx + 1 - rcomp
		var ty0: int = rsy + roundi(3.0 * sin(0.8 * PI) - 6.0 + float(2.0 if g["ei"] > 1 else 0.0))
		_elip(L, tx0 - 3, ty0 - 2, 5, 4, "d", "d", "k")
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

	# orelha de longe
	var OL := _nova()
	var cab_rows: Array = _cab_rows(ch, g["boca"])
	if sal:
		_orelha(OL, hx - 1, hy - 7, 4, 8, true)
	elif gig:
		_orelha(OL, hx, hy - 3, 5, 5, true)
	elif filhote:
		_orelha(OL, hx - 1, hy - 3, 3, 3, true)
	else:
		_orelha(OL, hx, hy - 3, 4, 4, true)
	_comp(G, OL)

	# corpo + pescoço + cabeça numa camada só
	var B := _nova()
	if sal and g["aire"] == 0:
		_elip(B, bx, -9, 11, 8)                    # anca redonda no chão
		_elip(B, bx + 4, -16, 8, 11)               # tronco inclinado, subindo para a cabeça
	elif sal:
		_elip(B, bx, by0 - 4, 10, bh + 4)         # anca alta
		_elip(B, bx + 6, by0 + 2, bw - 6, bh - 1)  # peito baixo
	else:
		_elip(B, bx, by0, bw, bh)
	var py0: int = hy + 2
	var TR: PackedInt32Array = B.duplicate()   # só o tronco: molde das peças de corpo (BichoPx.quadro)
	_elip(B, hx - 2, py0, 8, maxi(5, by0 + bh - py0 - 1))   # pescoço
	_bmp(B, hx, hy, cab_rows)
	if gig:
		_tinta(B, bx + 5, by0 + bh - 7, bw - 10, 7, "v")   # barrigão claro
	elif mae:
		_tinta(B, bx + 4, by0 + bh - 5, bw - 8, 5, "l")
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

	# orelha de perto
	var OP := _nova()
	if sal:
		_orelha(OP, hx + 2, hy - 8, 5, 9, false)
	elif gig:
		_orelha(OP, hx + 3, hy - 4, 6, 6, false)
	elif filhote:
		_orelha(OP, hx + 2, hy - 4, 4, 4, false)
	else:
		_orelha(OP, hx + 2, hy - 4, 5, 5, false)
	_comp(G, OP)

	# adereços
	if sal and g["aire"] == 0:
		var CX := _nova()
		_elip(CX, bx + 1, -10, 8, 8)   # coxa traseira redonda
		var ae: int = g["ei"]
		_rect(CX, bx + 12 + ae, -10 - ae, 2, 5 + ae, "m")   # braço dianteiro (avança no golpe)
		_rect(CX, bx + 13 + ae, -6 - ae, 2, 2, "p")
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
		# lenço vermelho no pescoço, com ponta voando
		var Z := _nova()
		_rect(Z, hx - 1, hy + hh - 4, 6, 2, "r")
		_rect(Z, hx - 1, hy + hh - 2, 5, 1, "R")
		_rect(Z, hx - 4, hy + hh - 4 + (q % 2), 3, 1, "r")
		_rect(Z, hx - 5, hy + hh - 3 + (q % 2), 2, 1, "R")
		_comp(G, Z)
	if mae:
		var yb: int = by0 + 2
		_pup(G, bx - 1, yb + 2, 7, 5, 6, 6)
		_pup(G, bx + 8, yb + 1, 7, 5, 6, 6)

	# bigodes (sem contorno)
	var WB := _nova()
	var tx: int = hx + hw
	var ny: int = hy + int(ch["ny"])
	_px(WB, tx, ny - 1, "W")
	_px(WB, tx + 1, ny - 1, "W")
	_px(WB, tx + 2, ny - 2, "W")
	_px(WB, tx, ny + 2, "W")
	_px(WB, tx + 1, ny + 2, "W")
	_px(WB, tx + 2, ny + 3, "W")
	_comp(G, WB, false)

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
	return {"x": x0 - _OX, "y": y0 - _OY, "l": lin, "t": BichoPx.recorte(TR, _W, _H, _OX, _OY), "c": BichoPx.cranio(ch["rows"])}

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
