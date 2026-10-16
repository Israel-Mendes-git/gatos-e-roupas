class_name BichoPxChefeCasa
extends RefCounted
## Os cinco chefes do primeiro ato em pixel art, refeitos do zero (chefe_tipo 0 a 4): Rei dos Ratos, Guaxinim Glutão,
## Raposa Ligeira, Corvo Velho e Sapo-Rei. Mesmo método de BichoPxRato (convenções gerais em BichoPx): olhando para a DIREITA,
## patas no chão (último pixel em y = -1), 1 unidade = 1 pixel. Cada quadro é MONTADO em camadas numa grade de letras, cada camada
## ganha contorno quase preto de 1 px (`o`), o interior usa 3 tons (l m d) + brilho no olho, o quadro é recortado, guardado em cache
## por pose e desenhado com RoupaGato.sprite. A geometria (_geo) é a mesma para desenhar() e desloc(): as roupas acompanham o corpo.
## Cada chefe é a versão REI da espécie da família nova (mesma linguagem visual dos bichos comuns), maior e com adereço de identidade:
##   0 Rei dos Ratos: rato cinza gordo, olhar rabugento, dentuço, coroa de ouro, manto vermelho com gola de arminho (voa ao andar).
##   1 Guaxinim Glutão: barrigão imenso, bochechas cheias, guardanapo xadrez no pescoço, baba e migalhas (a barriga respira).
##   2 Raposa Ligeira: esguia, pernas longas de meia preta, rabão de ponta branca, lenço vermelho ao vento e rastro de velocidade;
##     `parado` = sem fôlego: cabeça caída, língua de fora, peito arfando, pernas bambas, suor, lenço murcho.
##   3 Corvo Velho: penas desgrenhadas e falhas de pele, cabeça grisalha, monóculo de ouro com correntinha e bengala (bate no chão
##     ao andar, avança na bicada).
##   4 Sapo-Rei: sapo imenso, olhos saltados, papo que infla, verrugas, coroa e colar de ouro; anda aos pulos pesados; língua no golpe.
## `parte` (sapinho do Sapo-Rei) NÃO chega aqui: vem com chefe_tipo = -1 e é desenhado por BichoPxSapo.

const _PASSO := 1.3        # quadros de passo por unidade de anim (igual ao dos outros bichos)
const _DUR_GOLPE := 0.22   # duração do golpe (golpe vai de 0.22 a 0)
const _W := 112
const _H := 64
const _OX := 64            # coluna da grade onde x = 0
const _OY := 50            # linha da grade onde y = 0

static var _cache: Dictionary = {}

# ---------------------------------------------------------------- cabeças (sem contorno; `.` = vazio)
# js = primeira linha da mandíbula; ms = coluna onde começa a boca; ab = linhas que a boca aberta acrescenta;
# ct/cy = coluna do meio e linha (relativa a hy) do alto da cabeça (âncora de chapéu; a coroa sai quando há chapéu, então a âncora
# é o crânio, não a coroa); ex/ey = olho; mb = linha da boca/focinho
const _CAB: Array = [
	{"js": 7, "ms": 6, "ab": 3, "ct": 5.0, "cy": 0, "ex": 8, "ey": 4, "mb": 6, "rows": [   # Rei dos Ratos
		"..llllllll.....",
		".llllllllllmm..",
		"lllllllmmmmmmm.",
		"llllllkkkkmmmnn",
		"mmmmmmmmkwmmmnn",
		"mmmmmmmmkkmmmnn",
		"mmmmmmmmmmmmmm.",
		".dmmmmmmmmmmm..",
		"..ddddddddddd..",
	]},
	{"js": 7, "ms": 8, "ab": 3, "ct": 7.0, "cy": -1, "ex": 8, "ey": 3, "mb": 5, "rows": [   # Guaxinim Glutão
		"...lllllll.......",
		".llllfffffffff...",
		"lllaaaaaffffffff.",
		"llaaaaaawwaaffnnn",
		"llaaaaaawyaaffnnn",
		"lllaaaaaffffffff.",
		"mmmmmmmffffffffff",
		".mmmmmmmfffffffd.",
		"..dddddddddddddd.",
	]},
	{"js": 6, "ms": 7, "ab": 2, "ct": 3.0, "cy": 0, "ex": 5, "ey": 3, "mb": 5, "rows": [   # Raposa Ligeira
		"..lllll........",
		".lllllllll.....",
		"llllllllmmm....",
		"lllddkwmmmmmnn.",
		"mmmmmkkmmmmmnn.",
		"mmmmmmmmvvvvvv.",
		".mmvvvvvvvvvv..",
		"..dvvvvvvvvv...",
	]},
	{"js": 6, "ms": 9, "ab": 3, "ct": 3.5, "cy": 0, "ex": 4, "ey": 4, "mb": 4, "rows": [   # Corvo Velho
		"..sllll..........",
		".hhhhhhllm.......",
		"hhhhhhhmmaaaaaaa.",
		"hhhddddmmaaaaaaaa",
		"hhmmewemmbbbbbbbb",
		"hhmmekemmbbbbbbb.",
		"mmmmmmmmmcccccbb.",
		".dmmmmmmmm.......",
		"..dddddddd.......",
	]},
	{"js": 9, "ms": 1, "ab": 3, "ct": 11.0, "cy": 0, "ex": 11, "ey": 2, "mb": 7, "rows": [   # Sapo-Rei (desenhado à mão)
		"..........ggg....",
		".........leeel...",
		"........leeekkl..",
		"........leeekkl..",
		".lllllllleeeelll.",
		"lmmmmmmmmmmmmmmnm",
		"mmmmmmmmmmmmmmmmm",
		"nnmmmmmmmmmmmmmmm",
		".nnnnnnnnnnnnnnnn",
		"vvvvvvvvvvvvvvvv.",
		".vvvvvvvvvvvvvv..",
		"..vvvvvvvvvvv....",
	]},
]

# bx/bw/bh = tronco; pe = altura das patas; hx = coluna da cabeça; hoff = linha da cabeça em relação ao topo do tronco;
# pf/pt = x das patas de frente/trás (de perto; a de longe fica 3 ao lado); lw = grossura da perna; str/lift = passo e elevação;
# dedo = cor do pé; socks = linhas de "meia" no pé
const _ESP: Array = [
	{"bx": -11, "bw": 22, "bh": 11, "pe": 4, "hx": 4, "hoff": -3, "pf": 6, "pt": -8, "lw": 3, "str": 2.5, "lift": 2.0, "dedo": "p", "socks": 0},
	{"bx": -12, "bw": 24, "bh": 14, "pe": 3, "hx": 6, "hoff": -2, "pf": 8, "pt": -10, "lw": 3, "str": 2.0, "lift": 2.0, "dedo": "a", "socks": 0},
	{"bx": -11, "bw": 21, "bh": 9, "pe": 8, "hx": 4, "hoff": -3, "pf": 5, "pt": -9, "lw": 2, "str": 3.5, "lift": 3.0, "dedo": "f", "socks": 4},
	{"bx": -11, "bw": 21, "bh": 13, "pe": 5, "hx": 3, "hoff": -7, "pf": 2, "pt": -2, "lw": 1, "str": 3.0, "lift": 3.0, "dedo": "p", "socks": 0},
	{"bx": -14, "bw": 26, "bh": 14, "pe": 2, "hx": 1, "hoff": -4, "pf": 0, "pt": 0, "lw": 2, "str": 0.0, "lift": 0.0, "dedo": "v", "socks": 0, "amp": 3},
]

# ---------------------------------------------------------------- paleta
static func _pal(ct: int, alfa: float) -> Dictionary:
	var P: Dictionary = {
		"k": Color("1a1418"), "w": Color("ffffff"), "q": Color("7a1c2c"), "y": Color("c89428"), "Y": Color("f8dc58"), "r": Color("d8303c"),
		"R": Color("8e1a2a"), "j": Color("f0606c"), "B": Color("4a90d8"), "z": Color("6a4424"), "Z": Color("4a2c14"), "u": Color("bfe6ff"),
		"W": Color("eceef4"), "T": Color("e8607c"), "U": Color("b83c5c"), "b": Color("8a5a30"), "x": Color("bfe6ff"),
	}
	match ct:
		0:   # rato cinza-lilás de pelo gasto, barriga clara
			P.merge({"o": Color("1e1a26"), "l": Color("d0d4e8"), "m": Color("a0a6c4"), "d": Color("646a8c"), "v": Color("e4e4f0"), "p": Color("f4aabc"),
				"P": Color("c47c92"), "n": Color("e8788f"), "e": Color("f6f2f4"), "E": Color("c8c4d6")}, true)
		1:   # guaxinim pardo, face e barriga cremes, máscara e patas quase pretas
			P.merge({"o": Color("2a1a1c"), "l": Color("c8aa92"), "m": Color("927462"), "d": Color("584640"), "a": Color("1e1416"), "f": Color("f6ead4"),
				"v": Color("e0c8a8"), "p": Color("d49a98"), "P": Color("9c6a68"), "n": Color("241a1e"), "s": Color("a8804a")}, true)
		2:   # raposa-vermelha viva, meias e pontas das orelhas pretas, ponta do rabo branca
			P.merge({"o": Color("3a1a10"), "l": Color("fcb858"), "m": Color("ee7c28"), "d": Color("b04a1c"), "v": Color("fff0d8"), "e": Color("3a2018"),
				"f": Color("2a1814"), "u": Color("fffaf0"), "n": Color("241a1e")}, true)
		3:   # corvo velho: carvão azulado, cabeça grisalha, bico de chifre, pele rosada nas falhas
			P.merge({"o": Color("0a0a14"), "l": Color("66708c"), "m": Color("3e4660"), "d": Color("252a40"), "s": Color("a8b4d8"), "h": Color("8c90a4"),
				"a": Color("e0d098"), "c": Color("8a7a48"), "e": Color("f0e8b0"), "p": Color("8a7c88"), "P": Color("5c5260"), "N": Color("e8b4a8")}, true)
		_:   # sapo-rei verde-esmeralda, barriga amarelada, verrugas
			P.merge({"o": Color("10281c"), "l": Color("a4e860"), "m": Color("4eae48"), "d": Color("2a7438"), "v": Color("f4eeb0"), "V": Color("c8c47c"),
				"e": Color("f4c830"), "n": Color("1c4a2c"), "X": Color("3c8a34"), "g": Color("cdf08c")}, true)
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

## Pinta só onde a camada já tem pixel (um ponto).
static func _tp(L: PackedInt32Array, x: int, y: int, ch: String) -> void:
	var i: int = x + _OX
	var j: int = y + _OY
	if i < 0 or j < 0 or i >= _W or j >= _H:
		return
	if L[j * _W + i] != 0:
		L[j * _W + i] = ch.unicode_at(0)

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

## Pinta só onde a camada já tem pixel (mancha elíptica por cima do corpo).
static func _tinta(L: PackedInt32Array, x: int, y: int, w: int, h: int, ch: String) -> void:
	for j in h:
		for i in w:
			var nx: float = (i + 0.5 - w * 0.5) / (w * 0.5)
			var ny: float = (j + 0.5 - h * 0.5) / (h * 0.5)
			if nx * nx + ny * ny > 1.0:
				continue
			_tp(L, x + i, y + j, ch)

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
static func _geo(ct: int, anim: float, andando: bool, golpe: float, parado: bool) -> Dictionary:
	ct = clampi(ct, 0, 4)
	var t_ms: int = Time.get_ticks_msec()
	var e: float = 0.0
	if golpe > 0.0:
		e = sin(PI * clampf(1.0 - golpe / _DUR_GOLPE, 0.0, 1.0))
	var esp: Dictionary = _ESP[ct]
	var q: int = 0
	var bob: int = 0
	var resp: int = 0
	var salto: int = 0
	var aire: int = 0
	var sq: int = 0
	var hbx: int = 0
	var sw: int = 0
	var dr: int = 0
	var sem_folego: bool = parado and ct == 2
	if andando:
		q = posmod(int(anim * _PASSO), 6)
		match ct:
			2:
				bob = [0, -1, -2, -1, 0, 0][q]
				sw = q
			3:
				bob = -1 if q % 3 == 1 else 0
				hbx = [-1, 0, 1, 1, 0, -1][q]
			4:
				var f6: Array = [0.0, 0.55, 1.0, 0.7, 0.0, 0.0]
				var ar: Array = [0, 1, 1, 2, 0, 0]
				salto = roundi(float(esp["amp"]) * float(f6[q]))
				aire = ar[q]
				sq = 1 if (q == 0 or q == 4) else 0
			_:
				bob = -1 if q % 3 == 1 else 0
				sw = q
	elif golpe <= 0.0:
		var a7: int = int(anim * 7.0)
		match ct:
			1, 4:
				var ciclo: Array = [0, 1, 2, 1]
				resp = ciclo[(t_ms / 450 + a7) % 4]
			2:
				if sem_folego:
					resp = (t_ms / 190 + a7) % 2
				else:
					resp = (t_ms / 650 + a7) % 2
			_:
				resp = (t_ms / 650 + a7) % 2
		if ct == 1:
			dr = (t_ms / 320) % 4
		elif sem_folego:
			dr = (t_ms / 240) % 3
		if ct == 0:
			sw = (t_ms / 420) % 3
		elif ct == 2 and not sem_folego:
			sw = (t_ms / 170) % 6
		elif sem_folego:
			sw = (t_ms / 300) % 2
	var ei: int = roundi(4.0 * e)
	var boca: bool = e > 0.4
	var tl: int = 0
	if ct == 4 and e > 0.15:
		tl = roundi(11.0 * e)
	var ala: int = 0
	if ct == 3:
		ala = 2 if e > 0.45 else (1 if e > 0.15 else 0)
	var ch: Dictionary = _CAB[ct]
	var rows: Array = ch["rows"]
	var hw: int = String(rows[0]).length()
	var hh: int = rows.size()
	var bw: int = esp["bw"]
	var bh: int = esp["bh"]
	var pe: int = esp["pe"]
	var by0: int = -pe - bh - salto + bob
	if ct == 4:
		bh -= sq
		by0 = -pe - bh - salto
	var hdx: int = ei
	var hdy: int = 0
	if ct == 0:
		hdy = ei / 2
	elif ct == 3:
		hdx += hbx
		hdy = ei / 2
	elif ct == 2:
		if andando:
			hdy = 1
		if sem_folego:
			hdx = -1
			hdy = 5
	by0 -= resp if ct != 4 else 0
	if ct != 4:
		bh += resp
	var hx: int = int(esp["hx"]) + hdx
	var hy: int = by0 + int(esp["hoff"]) + hdy
	if ct == 4 and aire > 0:
		hx += 1
		hy -= 1
	if ct == 1:
		hy -= 0
	return {"ct": ct, "q": q, "e": e, "ei": ei, "boca": boca, "tl": tl, "ala": ala, "resp": resp, "bob": bob, "salto": salto, "aire": aire, "sq": sq,
		"sw": sw, "dr": dr, "esp": esp, "ch": ch, "hw": hw, "hh": hh, "bx": int(esp["bx"]), "bw": bw, "bh": bh, "pe": pe, "by0": by0, "hx": hx, "hy": hy,
		"andando": andando, "parado": sem_folego}

## Quanto o lugar `onde` se desloca em relação à planta do gato parado (as roupas acompanham por aqui).
static func desloc(onde: int, familia: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Vector2:
	var g: Dictionary = _geo(chefe_tipo, anim, andando, golpe, parado)
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hw: int = g["hw"]
	var hh: int = g["hh"]
	var ch: Dictionary = g["ch"]
	var p: Vector2 = Vector2.ZERO
	match onde:
		RoupaGato.Onde.CABECA:
			p = Vector2(hx + float(ch["ct"]), hy + int(ch["cy"]) + 1) - RoupaGato.ORIGEM[RoupaGato.Onde.CABECA]
		RoupaGato.Onde.BOCA:
			p = Vector2(hx + hw - 1, hy + int(ch["mb"])) - RoupaGato.ORIGEM[RoupaGato.Onde.BOCA]
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
				return Vector2(0, 5000)   # no pulo as patas ficam fora do chão: botas saem de cena em vez de flutuar
			return Vector2(0, -int(g["salto"]))
	return Vector2(roundf(p.x), roundf(p.y))

# ---------------------------------------------------------------- partes comuns
## Cabeça com a boca aberta: a mandíbula desce `ab` linhas e o vão fica vermelho (com presas na frente, exceto sapo e corvo).
static func _cab_rows(ct: int, ch: Dictionary, boca: bool) -> Array:
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
	if ct == 0 or ct == 1 or ct == 2:
		r[js - 1] = base.substr(0, fin - 1) + "ww" + base.substr(fin + 1)
	for k in int(ch["ab"]):
		var s: String = ""
		for i in base.length():
			if base[i] == ".":
				s += "."
			elif i < ms:
				s += base[i] if ct != 4 and ct != 3 else ("m" if ct == 4 else base[i])
			else:
				s += "q"
		if (ct == 0 or ct == 1 or ct == 2) and k < 2:
			s = s.substr(0, fin - 1) + "ww" + s.substr(fin + 1)
		r.append(s)
	for j in range(js, rows.size()):
		r.append(rows[j])
	return r

## perna de `w` px do quadril (x, ytop) ao pé (xf, yf); os últimos `socks` pixels da perna e o pé levam a cor `dedo`
static func _pata(L: PackedInt32Array, x: int, ytop: int, xf: int, yf: int, w: int, ch: String, dedo: String, socks: int) -> void:
	var n: int = maxi(1, yf - ytop)
	for i in n + 1:
		var y: int = ytop + i
		var x0: int = roundi(lerpf(x, xf, float(i) / float(n)))
		_rect(L, x0, y, w, 1, dedo if (socks > 0 and i >= n - socks) else ch)
	_rect(L, xf, yf, w + 1, 1, dedo)

static func _pernas4(L1: PackedInt32Array, L2: PackedInt32Array, g: Dictionary) -> void:
	var esp: Dictionary = g["esp"]
	var q: int = g["q"]
	var hip: int = int(g["by0"]) + int(g["bh"]) - 3
	var pf: int = esp["pf"]
	var pt: int = esp["pt"]
	var w: int = esp["lw"]
	var ei: int = g["ei"]
	var dedo: String = esp["dedo"]
	var tre: int = (Time.get_ticks_msec() / 110) % 2
	# [x do quadril, fase (as diagonais andam juntas), tom, camada]: as de longe (d) por baixo, as de perto (m) por cima
	var defs: Array = [[pt + 3, 0.5, "d", L1], [pf + 3, 0.0, "d", L1], [pt, 0.0, "m", L2], [pf, 0.5, "m", L2]]
	for k in defs.size():
		var d: Array = defs[k]
		var x: int = d[0]
		var xf: int = x
		var yf: int = -1
		if g["andando"]:
			var ph: float = fposmod(float(q) / 6.0 + float(d[1]), 1.0)
			xf = x + roundi(float(esp["str"]) * cos(TAU * ph))
			yf = -1 - maxi(0, roundi(float(esp["lift"]) * sin(TAU * ph)))
		elif g["parado"]:
			xf = x + (-2 if k % 2 == 0 else 2) + (tre if k < 2 else 1 - tre)   # pernas abertas e bambas
		if ei > 0 and d[1] == 0.5 and d[2] == "m" and x == pf:
			xf = x + 2 + ei   # golpe: pata dianteira de perto sobe e avança
			yf = maxi(hip + 1, -2 - 2 * ei)
		_pata(d[3], x, hip, xf, yf, w, d[2], dedo, int(esp["socks"]))
		if ei > 0 and d[1] == 0.5 and d[2] == "m" and x == pf and w < 4:
			_rect(d[3], xf + w + 1, yf, 1, 1, "w")   # garras
			_rect(d[3], xf + w, yf - 1, 1, 1, "w")

## Rabo fino e longo (rato): `th` = grossura, sobe na ponta
static func _rabo_fino(L: PackedInt32Array, g: Dictionary, sx: int, sy: int, comp: int, th: int) -> void:
	var q: int = g["q"]
	var wag: int = roundi(2.0 * sin(TAU * float(q) / 6.0))
	if g["ei"] > 1:
		wag = -3
	var n: int = comp * 2
	var ant_x: int = sx
	var ant_y: int = sy
	for i in n + 1:
		var t: float = float(i) / float(n)
		var px: int = sx - roundi(t * comp)
		var py: int = sy + roundi(4.0 * sin(t * PI * 0.8) - 8.0 * t * t * t + float(wag) * t)
		var n2: int = maxi(1, maxi(absi(px - ant_x), absi(py - ant_y)))
		for k in n2:
			var tt: float = float(k + 1) / float(n2)
			var cx: int = roundi(lerpf(ant_x, px, tt))
			var cy: int = roundi(lerpf(ant_y, py, tt))
			var tk: int = th if t < 0.7 else maxi(1, th - 1)
			for s in tk:
				_px(L, cx, cy + s, "p" if s < tk - 1 or tk == 1 else "P")
		ant_x = px
		ant_y = py

static func _orelha_c(L: PackedInt32Array, x: int, y: int, w: int, h: int, longe: bool, rim: String = "l", inner: String = "p") -> void:
	if longe:
		_elip(L, x, y, w, h, "d", "d", "d")
		_tinta(L, x + 1, y + 1, w - 2, h - 2, "P")
	else:
		_elip(L, x, y, w, h, rim, "m", "m")
		_tinta(L, x + 1, y + 1, w - 2, h - 2, inner)

# ---------------------------------------------------------------- montagem do quadro
static func _chave(g: Dictionary) -> String:
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [g["ct"], int(g["andando"]), g["q"], g["ei"], int(g["boca"]), g["resp"], g["bob"], g["salto"], g["aire"], g["sq"], int(g["parado"]), g["sw"], g["dr"], g["ala"], g["tl"], int(BichoPx.cabeca_coberta) * 2 + int(BichoPx.corpo_coberto)]

## Molde do tronco do quadro em montagem (cada _monta_* grava aqui o corpo antes do pescoço): as roupas de corpo se ajustam a ele.
static var _tr: PackedInt32Array = PackedInt32Array()

static func _monta(g: Dictionary) -> Dictionary:
	var G := _nova()
	_tr = _nova()
	match int(g["ct"]):
		0:
			_monta_rei(G, g)
		1:
			_monta_glutao(G, g)
		2:
			_monta_raposa(G, g)
		3:
			_monta_corvo(G, g)
		_:
			_monta_sapo(G, g)
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
	# "t" = molde do tronco, "c" = largura do crânio (chapéu), "cobre" = quanto da altura do tronco a roupa de corpo cobre (no chefe, só o dorso)
	return {"x": x0 - _OX, "y": y0 - _OY, "l": lin, "t": BichoPx.recorte(_tr, _W, _H, _OX, _OY),
		"c": BichoPx.cranio(Dictionary(g["ch"])["rows"], "abc" if int(g["ct"]) == 3 else ""), "cobre": 0.5}

# ================================================================ 0. REI DOS RATOS
static func _monta_rei(G: PackedInt32Array, g: Dictionary) -> void:
	var ch: Dictionary = g["ch"]
	var bx: int = g["bx"]
	var bw: int = g["bw"]
	var bh: int = g["bh"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hw: int = g["hw"]
	var hh: int = g["hh"]
	var ei: int = g["ei"]
	var sw: int = g["sw"]
	var q: int = g["q"]
	# rabo
	var L := _nova()
	_rabo_fino(L, g, bx + 1, by0 + 8, 14, 3)
	_comp(G, L)
	# pernas
	var L1 := _nova()
	var L2 := _nova()
	_pernas4(L1, L2, g)
	_comp(G, L1)
	_comp(G, L2)
	# orelha de longe
	var OL := _nova()
	_orelha_c(OL, hx - 2, hy - 4, 7, 7, true)
	_comp(G, OL)
	# corpo + pescoço + cabeça
	var B := _nova()
	_elip(B, bx, by0, bw, bh)
	_elip(B, bx, by0 - 1, 17, bh + 1)   # anca alta
	_tr = B.duplicate()
	var py0: int = hy + 3
	_elip(B, hx - 3, py0, 11, maxi(5, by0 + bh - py0 - 1))
	_bmp(B, hx, hy, _cab_rows(0, ch, g["boca"]))
	_tinta(B, bx + 8, by0 + bh - 8, bw - 16, 8, "v")   # barriga clara de rei bem alimentado
	if not g["boca"]:
		_rect(B, hx + hw - 3, hy + 7, 2, 3, "w")       # dentes de roedor sempre à mostra
		_px(B, hx + hw - 3, hy + 9, "E")
		_px(B, hx + hw - 2, hy + 9, "E")
	BichoPx.manter_iguais(_tr, B, _W)   # cabeça, marcas e barriga ficam por cima da roupa de corpo
	_comp(G, B)
	# orelha de perto
	var OP := _nova()
	_orelha_c(OP, hx + 0, hy - 5, 8, 8, false)
	_comp(G, OP)
	# manto vermelho: do pescoço à anca, ponta voando atrás, bainha de arminho
	var C := _nova()
	var xl: int = bx - 4
	var xr: int = hx - 2
	var vento: int = -(ei / 2)
	for x in range(xl, xr + 1):
		var u: float = float(x - xl) / float(xr - xl)
		var top: int = by0 - 1 + roundi((1.0 - u) * (1.0 - u) * 5.0)
		var bot: int = by0 + bh - 5 - roundi((1.0 - u) * 2.0)
		var flap: int = vento
		if u < 0.5:
			flap += roundi(sin(TAU * float(sw) / (6.0 if g["andando"] else 3.0) + u * 6.0) * 1.6 * (0.5 - u) / 0.5)
		top += flap
		bot += flap
		for y in range(top, bot + 1):
			var c: String = "r"
			if y - top < 2:
				c = "j"
			elif bot - y < 1:
				c = "k" if x % 3 == 0 else "e"
			elif bot - y < 3:
				c = "R"
			_px(C, x, y, c)
	_comp(G, C)
	# gola de arminho e fecho de ouro
	var GL := _nova()
	_elip(GL, hx - 5, hy + hh - 5, 8, 5, "e", "e", "E")
	_px(GL, hx - 3, hy + hh - 2, "k")
	_px(GL, hx, hy + hh - 3, "k")
	_comp(G, GL)
	var FE := _nova()
	_rect(FE, hx - 3, hy + hh - 2, 2, 2, "Y")
	_comp(G, FE)
	# coroa de ouro com rubi (sai quando o rei veste chapéu)
	if not BichoPx.cabeca_coberta:
		var CR := _nova()
		_bmp(CR, hx + 6, hy - 4, [
			"Y...Y...Y",
			"YY.YYY.YY",
			"YYYYYYYYY",
			"yyyryyyry",
		])
		_comp(G, CR)
	# bigodes longos e caídos (sem contorno)
	var WB := _nova()
	var tx: int = hx + hw
	var ny: int = hy + 4
	_rect(WB, tx, ny, 4, 1, "W")
	_px(WB, tx + 4, ny + 1, "W")
	_rect(WB, tx, ny + 2, 4, 1, "W")
	_px(WB, tx + 4, ny + 3, "W")
	_px(WB, tx + 5, ny + 4, "W")
	_rect(WB, tx - 1, ny + 4, 3, 1, "W")
	_comp(G, WB, false)

# ================================================================ 1. GUAXINIM GLUTÃO
static func _monta_glutao(G: PackedInt32Array, g: Dictionary) -> void:
	var ch: Dictionary = g["ch"]
	var bx: int = g["bx"]
	var bw: int = g["bw"]
	var bh: int = g["bh"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hw: int = g["hw"]
	var hh: int = g["hh"]
	var ei: int = g["ei"]
	var q: int = g["q"]
	var dr: int = g["dr"]
	# rabo grosso e listrado
	var L := _nova()
	var wag: int = roundi(2.0 * sin(TAU * float(q) / 6.0))
	if ei > 1:
		wag = -4
	var comp: int = 12
	var th: int = 6
	for i in comp * 2 + 1:
		var t: float = float(i) / float(comp * 2)
		var px: int = bx + 3 - roundi(t * comp)
		var py: int = by0 + 8 - roundi(5.0 * sin(t * PI * 0.5)) + roundi(float(wag) * t)
		var banda: int = int(t * float(comp) / 2.6)
		var claro: bool = banda % 2 == 0 and t < 0.88
		var tc: String = "m" if claro else "a"
		for k in th:
			var c2: String = tc
			if k == 0:
				c2 = "l" if claro else "d"
			elif k == th - 1:
				c2 = "d" if claro else "k"
			_px(L, px, py + k, c2)
	_comp(G, L)
	# pernas
	var L1 := _nova()
	var L2 := _nova()
	_pernas4(L1, L2, g)
	_comp(G, L1)
	_comp(G, L2)
	# orelha de longe
	var OL := _nova()
	_orelha_c(OL, hx + 1, hy - 3, 6, 6, true)
	_comp(G, OL)
	# corpo + pescoço + cabeça
	var B := _nova()
	_elip(B, bx, by0, bw, bh)
	_elip(B, bx, by0 - 1, 17, bh)   # anca alta: dorso arqueado de guaxinim
	_tr = B.duplicate()
	var py0: int = hy + 2
	_elip(B, hx - 3, py0, 10, maxi(5, by0 + bh - py0 - 1))
	_bmp(B, hx, hy, _cab_rows(1, ch, g["boca"]))
	BichoPx.manter_iguais(_tr, B, _W)   # só a cabeça fica por cima: o barrigão é o corpo dele, a manta cobre o alto e ele aparece embaixo
	_tinta(B, bx + 7, by0 + bh - 15 - g["resp"], bw - 12, 15 + g["resp"], "f")   # barrigão imenso
	_tinta(B, bx + 9, by0 + bh - 5, bw - 16, 5, "v")
	_px(B, bx + bw / 2 + 3, by0 + bh - 6, "d")    # umbigo
	_px(B, bx + bw / 2 + 4, by0 + bh - 6, "d")
	_comp(G, B)
	# orelha de perto (borda clara)
	var OP := _nova()
	_orelha_c(OP, hx + 5, hy - 4, 6, 6, false, "f", "P")
	_comp(G, OP)
	# guardanapo xadrez no pescoço, com nó e migalhas
	var N := _nova()
	var nx: int = hx
	var ny: int = hy + hh - 3
	var wids: Array = [10, 10, 10, 10, 9, 8, 6, 4]
	for j in wids.size():
		var wj: int = wids[j]
		for i in wj:
			var cx: int = nx + i + (10 - wj) / 2
			N[(ny + j + _OY) * _W + cx + _OX] = ("w" if (i / 2 + j / 2) % 2 == 0 else "r").unicode_at(0)
	_rect(N, nx - 3, ny - 1, 3, 2, "r")           # nó atrás do pescoço
	_rect(N, nx - 4, ny + 1, 2, 3, "R")
	_comp(G, N)
	var MG := _nova()
	_px(MG, nx + 3, ny + 3, "y")
	_px(MG, nx + 8, ny + 5, "b")
	_px(MG, nx + 5, ny + 7, "y")
	_px(MG, nx + 10, ny + 2, "b")
	_comp(G, MG, false)
	# baba pingando do queixo e migalhas na boca
	var DR := _nova()
	var bxx: int = hx + hw - 7
	for k in dr + 1:
		_px(DR, bxx, hy + hh - 1 + k, "u")
	_px(DR, hx + hw - 3, hy + hh - 3, "y")
	_px(DR, hx + hw - 9, hy + hh - 2, "b")
	_comp(G, DR, false)

# ================================================================ 2. RAPOSA LIGEIRA
const _OREL_F: Array = [
	"..ff..",
	".ffff.",
	".lmme.",
	".leem.",
	".leem.",
	"lleemm",
	"lleemm",
	"lmmmmm",
	"lmmmmm",
]

static func _monta_raposa(G: PackedInt32Array, g: Dictionary) -> void:
	var ch: Dictionary = g["ch"]
	var bx: int = g["bx"]
	var bw: int = g["bw"]
	var bh: int = g["bh"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hw: int = g["hw"]
	var hh: int = g["hh"]
	var ei: int = g["ei"]
	var q: int = g["q"]
	var sw: int = g["sw"]
	var par: bool = g["parado"]
	# rabão cheio, ponta branca
	var L := _nova()
	var wag: int = roundi(2.0 * sin(TAU * float(q) / 6.0))
	if ei > 1:
		wag = -4
	var comp: int = 13
	var rsy: int = by0 + 3
	var rmax: int = 4
	if par:
		wag = 5   # rabo caído
	elif g["andando"]:
		wag = -2 + roundi(sin(TAU * float(q) / 6.0))
	var n: int = comp * 2
	for i in n + 1:
		var t: float = float(i) / float(n)
		var cx: int = bx + 1 - roundi(t * comp)
		var cy: int = rsy + roundi(2.0 * sin(t * PI * 0.9) - 6.0 * t * t + float(wag) * t)
		var rr: float = float(rmax) * (0.5 + 0.5 * sin(PI * pow(t, 0.7))) * (1.0 - 0.45 * t * t)
		var r: int = maxi(1, roundi(rr))
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if dx * dx + dy * dy > r * r + r:
					continue
				var c: String = "m"
				if dy < -r * 0.4:
					c = "l"
				elif dy > r * 0.4:
					c = "d"
				if t >= 0.78:
					c = "u"
				_px(L, cx + dx, cy + dy, c)
	_comp(G, L)
	# pernas
	var L1 := _nova()
	var L2 := _nova()
	_pernas4(L1, L2, g)
	_comp(G, L1)
	_comp(G, L2)
	# orelha de longe (com chapéu, as orelhas altas ficam por baixo dele: a de longe some e a de perto mostra só a base)
	var OL := _nova()
	var far: Array = []
	for s in _OREL_F:
		far.append(String(s).replace("l", "d").replace("m", "d").replace("e", "d"))
	if not BichoPx.cabeca_coberta:
		_bmp(OL, hx + 1, hy - far.size() + 2, far)
	_comp(G, OL)
	# corpo + pescoço + cabeça + orelha de perto numa camada só
	var B := _nova()
	_elip(B, bx, by0, bw, bh)
	_elip(B, bx + bw - 12, by0 - 1, 12, bh + 2)   # peito fundo de corredora
	_tr = B.duplicate()
	var py0: int = hy + 2
	_elip(B, hx - 3, py0, 9, maxi(5, by0 + bh - py0 - 1))
	_bmp(B, hx, hy, _cab_rows(2, ch, g["boca"]))
	if BichoPx.cabeca_coberta:
		_bmp(B, hx + 5, hy - 2, _OREL_F.slice(5))
	else:
		_bmp(B, hx + 5, hy - _OREL_F.size() + 2, _OREL_F)
	_tinta(B, bx + bw - 8, by0 + bh - 6, 8, 6, "v")   # peito branco
	BichoPx.manter_iguais(_tr, B, _W)   # cabeça, marcas e barriga ficam por cima da roupa de corpo
	_comp(G, B)
	# língua de fora e suor (sem fôlego)
	if par:
		var TG := _nova()
		var tx0: int = hx + hw - 6
		_rect(TG, tx0, hy + hh - 2, 3, 4 + g["resp"], "T")
		_rect(TG, tx0 + 1, hy + hh + 1 + g["resp"], 2, 1, "U")
		_comp(G, TG)
		var SU := _nova()
		var gt: int = g["dr"]
		_rect(SU, hx + 2, hy - 1 + gt, 1, 2, "x")
		_rect(SU, hx + 12, hy + 2 + (gt + 1) % 3, 1, 2, "x")
		_rect(SU, hx - 3, hy + 4 + (gt + 2) % 3, 1, 2, "x")
		_rect(SU, bx + 8, by0 - 2 + gt, 1, 2, "x")
		_comp(G, SU, false)
	# lenço vermelho ao vento
	var Z := _nova()
	var kx: int = hx + 1
	var ky: int = hy + hh - 4
	_rect(Z, kx, ky, 6, 3, "r")
	_rect(Z, kx, ky + 3, 5, 1, "R")
	_rect(Z, kx + 1, ky, 3, 1, "j")
	if par:
		for i in 11:
			var xx: int = kx - 1 - i / 4 + (sw if i > 5 else 0)
			_rect(Z, xx, ky + 2 + i, 2, 1, "r" if i % 3 != 2 else "R")
	else:
		for i in 11:
			var ph: float = TAU * float(sw) / 6.0 - float(i) * 0.65
			var amp: float = 0.4 + float(i) * 0.1
			var yy: int = ky + 1 + roundi(sin(ph) * amp)
			_rect(Z, kx - 1 - i, yy, 1, 2, "r" if i % 4 != 3 else "j")
			_px(Z, kx - 1 - i, yy + 2, "R")
	_comp(G, Z)
	# rastro de velocidade (sem contorno)
	if g["andando"]:
		var WB := _nova()
		for i in 3:
			_rect(WB, bx - 22 - i * 4, by0 + 1 + i * 4, 12 - i * 2, 1, "W")
		_comp(G, WB, false)

# ================================================================ 3. CORVO VELHO
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
	_elip(L, sx - 7, sy - 5, 12, 10, lit, mid, sh)

static func _monta_corvo(G: PackedInt32Array, g: Dictionary) -> void:
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
	var ei: int = g["ei"]
	var q: int = g["q"]
	var ala: int = g["ala"]
	# cauda: três penas compridas e esfiapadas
	var L := _nova()
	var wag: int = 0
	if g["andando"]:
		wag = 1 if q % 3 == 1 else 0
	if ei > 1:
		wag = -3
	for k in 3:
		var ex: int = bx - 7 - k * 2
		var ey: int = by0 + 5 + k * 2 + wag
		_trazo(L, bx + 3, by0 + 2 + k, ex, ey, 2, "m")
		_rect(L, ex - 1, ey, 2, 2, "d")
		if k == 1:
			_px(L, ex + 3, ey - 2, "d")   # farpa
	_comp(G, L)
	# pernas finas e escamosas
	var L1 := _nova()
	var L2 := _nova()
	var hip: int = by0 + bh - 2
	var defs: Array = [[int(esp["pt"]), 0.5, "P", L1], [int(esp["pf"]), 0.0, "p", L2]]
	for d in defs:
		var x: int = d[0]
		var xf: int = x
		var yf: int = -1
		if g["andando"]:
			var ph: float = fposmod(float(q) / 6.0 + float(d[1]), 1.0)
			xf = x + roundi(3.0 * cos(TAU * ph))
			yf = -1 - maxi(0, roundi(-3.0 * sin(TAU * ph)))
		if ei > 0:
			xf = x + (1 if d[2] == "p" else -1)
			yf = -1
		var n: int = maxi(1, yf - hip)
		for i in n + 1:
			_px(d[3], roundi(lerpf(x, xf, float(i) / float(n))), hip + i, d[2])
			_px(d[3], roundi(lerpf(x, xf, float(i) / float(n))) + 1, hip + i, d[2])
		_rect(d[3], xf - 2, yf, 5, 1, d[2])
		_px(d[3], xf - 3, yf - 1, d[2])
	_comp(G, L1)
	_comp(G, L2)
	# asa de longe (só aberta)
	if ala > 0:
		var AL := _nova()
		_asa_aberta(AL, bx + bw - 12, by0 + 4, ala, 15, "d", "d", "o", 2)
		_comp(G, AL)
	# corpo + peito + pescoço + cabeça numa camada só
	var B := _nova()
	_elip(B, bx, by0, bw, bh)
	_elip(B, bx + bw - 12, by0 - 1, 12, bh - 1)   # peito estufado
	_tr = B.duplicate()
	var ny0: int = hy + 3
	_elip(B, hx - 1, ny0, 9, maxi(5, by0 + bh - ny0 - 1))
	# penas arrepiadas no dorso e no peito
	for i in 9:
		var sx: int = bx + 2 + i * 2 + (i % 2)
		var sh: int = 1 + (i * 5) % 3
		_rect(B, sx, by0 - sh + 1, 1, sh, "m")
		_px(B, sx, by0 - sh, "d")
	for i in 4:
		_px(B, hx - 2 + i * 2, hy + hh - 1 + (i % 2), "d")
		_px(B, hx - 1 + i * 2, hy + hh, "d")
	_bmp(B, hx, hy, _cab_rows(3, ch, g["boca"]))
	# falhas de pena: pele nua rosada
	_tp(B, bx + 6, by0 + 5, "N")
	_tp(B, bx + 7, by0 + 5, "N")
	_tp(B, bx + 7, by0 + 6, "N")
	_tp(B, bx + 15, by0 + 8, "N")
	_tp(B, bx + bw - 5, by0 + 3, "N")
	_tp(B, bx + bw - 4, by0 + 4, "N")
	BichoPx.manter_iguais(_tr, B, _W)   # cabeça, marcas e barriga ficam por cima da roupa de corpo
	_comp(G, B)
	# asa de perto: dobrada, esfiapada nas pontas, ou aberta
	var W := _nova()
	if ala > 0:
		_asa_aberta(W, bx + bw - 10, by0 + 3, ala, 16, "l", "m", "d", 2)
	else:
		var wx: int = bx + 1
		var wy: int = by0 + 2
		var ww: int = bw - 6
		var whh: int = bh - 4
		_elip(W, wx, wy, ww, whh, "l", "m", "m")
		_rect(W, bx - 4, by0 + bh - 6, 6, 2, "m")      # pontas das penas passando da anca
		_rect(W, bx - 7, by0 + bh - 5, 4, 1, "d")
		_px(W, bx - 3, by0 + bh - 3, "d")
		_rect(W, bx - 1, by0 + bh - 4, 3, 1, "d")
		_rect(W, wx + 3, wy + whh - 2, ww - 7, 1, "d")   # linhas de pena
		_rect(W, wx + 6, wy + whh - 4, ww - 12, 1, "d")
		_rect(W, wx + 2, wy + 1, 6, 1, "s")             # brilho de pena
		_px(W, wx + 11, wy + 2, "s")
	_comp(G, W)
	# bengala: bate no chão ao andar, avança na bicada
	var S := _nova()
	var cx0: int = bx + bw + 3 + ei
	if g["andando"]:
		cx0 += [0, 1, 2, 2, 1, 0][q]
	var lift: int = 0
	if g["andando"]:
		lift = [0, 2, 2, 0, 0, 0][q]
	var ctop: int = by0 + bh - 4
	_trazo(S, cx0, -2 - lift, cx0 - 2 - ei / 2, ctop, 2, "z")
	_comp(G, S)
	var KN := _nova()
	_elip(KN, cx0 - 5 - ei / 2, ctop - 4, 6, 5, "Y", "Y", "y")
	_comp(G, KN)
	# mão-asa que segura o castão
	var MA := _nova()
	_rect(MA, bx + bw - 3, by0 + bh - 5, cx0 - 2 - (bx + bw - 3) + 1 - ei / 2, 2, "m")
	_rect(MA, cx0 - 4 - ei / 2, ctop - 1, 3, 2, "d")
	_comp(G, MA)
	# monóculo de ouro com correntinha (sem contorno)
	var MO := _nova()
	var mx: int = hx + 3
	var my: int = hy + 3
	for i in 5:
		_px(MO, mx + i, my, "Y")
		_px(MO, mx + i, my + 4, "y")
		_px(MO, mx, my + i, "Y")
		_px(MO, mx + 4, my + i, "y")
	for i in 7:
		_px(MO, mx + 1 - i / 3, my + 5 + i, "Y" if i % 2 == 0 else "y")
	_comp(G, MO, false)

# ================================================================ 4. SAPO-REI
## Desenhado à mão em camadas (membros de longe, corpo, coxa, cabeça + papo, braço, coroa, colar): sapo imenso sentado, dorso largo e
## liso (a roupa de corpo veste ele inteiro), olho amarelo saltado, boca larga de canto a canto, barriga creme e verrugas.
const _SAPO_CORPO: Array = [
	"......llllllll............",
	"...lllllllllllllll........",
	"..llllmmmmmmmmmllllll.....",
	".llmmmmmmmmmmmmmmmmlllll..",
	"llmmmXmmmmmmXmmmmmmmmmlll.",
	"lmmmmmmmmmmmmmmmmmmmmmmmml",
	"mmmmmmmmmXmmmmmmmmXmmmmmmm",
	"mmmmmmmmmmmmmmmmmmmmmmmmmm",
	"mmmmmmmmmmmmmmmmmmmmmmmmvv",
	"dmmmmmmmmmmmmmmmmmmmmmvvvv",
	"ddmmmmmmmmmmmmmmmmmmvvvvvv",
	".dddmmmmmmmmmmmmmmvvvvvvv.",
	"..ddddddddddddvvvvvvvvvv..",
	"....dddddddddvvvvvvvv.....",
]
## Boca escancarada (golpe): a mandíbula cai três linhas e a língua sai do vão.
const _SAPO_CAB_ABERTA: Array = [
	"..........ggg....",
	".........leeel...",
	"........leeekkl..",
	"........leeekkl..",
	".lllllllleeeelll.",
	"lmmmmmmmmmmmmmmnm",
	"mmmmmmmmmmmmmmmmm",
	"nnmmmmmmmmmmmmmmm",
	".nnnnnnnnnnnnnnnn",
	".qqqqqqqqqqqqqqq.",
	"..qqqqqqqqqqqqq..",
	"nnnqqqqqqqqqqn...",
	"vvvvvvvvvvvvvvvv.",
	".vvvvvvvvvvvvvv..",
	"..vvvvvvvvvvv....",
]
const _SAPO_COXA: Array = [
	"...lllll....",
	".lmmmmmmmm..",
	"lmmmmmmmmmm.",
	"mmmmmXmmmmmm",
	"mmmmmmmmmmmm",
	"dmmmmmmmmmmd",
	".ddmmmmmmdd.",
	"...dddddd...",
]
const _SAPO_PE: Array = ["mmmmmmmmmvv", "ddddddddvvv"]
const _SAPO_BRACO: Array = ["mmm", "mmm", "mmm", "mmm", "mmmvv", "mmvvv"]
const _SAPO_COROA: Array = ["Y.Y.Y.Y.Y", "YYYYYYYYY", "yyryyByyy", "yyyyyyyyy"]

static func _monta_sapo(G: PackedInt32Array, g: Dictionary) -> void:
	var ch: Dictionary = g["ch"]
	var bx: int = g["bx"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hw: int = g["hw"]
	var aire: int = g["aire"]
	var tb: int = by0 + 13          # última linha do corpo
	var fy: int = -2 - int(g["salto"])   # pé no chão (sobe junto no pulo)
	# membros de longe (mais escuros)
	var L1 := _nova()
	if aire == 1:
		_trazo(L1, bx + 8, tb - 3, bx - 2, tb + 3, 3, "d")
		_trazo(L1, hx + 10, by0 + 9, hx + 15, by0 + 11, 2, "d")
	elif aire == 2:
		_trazo(L1, hx + 10, by0 + 9, hx + 13, by0 + 14, 2, "d")
	else:
		_bmp(L1, bx + 3, fy, [String(_SAPO_PE[0]).replace("m", "d"), String(_SAPO_PE[1]).replace("v", "V")])
		var bl: Array = []
		for r in _SAPO_BRACO:
			bl.append(String(r).replace("m", "d").replace("v", "V"))
		_bmp(L1, hx + 8, by0 + 10, bl)
	_comp(G, L1)
	# corpo: o molde do tronco é ele inteiro (a roupa de corpo veste o dorso todo); cabeça, coxa e braço ficam por cima dela
	var B := _nova()
	_bmp(B, bx, by0, _SAPO_CORPO)
	_tr = B.duplicate()
	_comp(G, B)
	# coxa de perto dobrada com o pé chato no chão (ou a perna esticada no ar)
	var CX := _nova()
	if aire == 1:
		_trazo(CX, bx + 6, tb - 5, bx - 7, tb + 2, 4, "m")
		_rect(CX, bx - 11, tb + 1, 5, 3, "v")
	else:
		_bmp(CX, bx - 1, by0 + 6, _SAPO_COXA)
		_bmp(CX, bx + 5, fy, _SAPO_PE)
	_tira_camada(_tr, CX)
	_comp(G, CX)
	# cabeça + papo numa camada (o papo infla com a respiração)
	var H := _nova()
	var cab: Array = _SAPO_CAB_ABERTA if g["boca"] else ch["rows"]
	_bmp(H, hx, hy, cab)
	if not g["andando"] and not g["boca"] and g["ei"] == 0 and g["resp"] > 0:
		var rs: int = g["resp"]
		_elip(H, hx + 2, hy + 9, 9 + 2 * rs, 3 + 2 * rs, "v", "v", "V")
	_tira_camada(_tr, H)
	_comp(G, H)
	# braço de perto
	var CA := _nova()
	if aire == 1:
		_trazo(CA, hx + 6, by0 + 9, hx + 12, by0 + 11, 3, "m")
		_rect(CA, hx + 12, by0 + 11, 3, 3, "v")
	elif aire == 2:
		_trazo(CA, hx + 6, by0 + 9, hx + 9, by0 + 14, 3, "m")
		_rect(CA, hx + 9, by0 + 14, 4, 2, "v")
	else:
		_bmp(CA, hx + 5, by0 + 10, _SAPO_BRACO)
	_tira_camada(_tr, CA)
	_comp(G, CA)
	# colar de ouro com pingente logo abaixo da boca, por cima do braço (sai quando o sapo veste roupa de corpo)
	if not BichoPx.corpo_coberto:
		var CO := _nova()
		var cxx: int = hx + 1
		var cyy: int = hy + 11 + int(g["resp"])
		for i in 10:
			_px(CO, cxx + i, cyy + int(1.6 * sin(PI * float(i) / 9.0)), "Y" if i % 2 == 0 else "y")
		_rect(CO, cxx + 4, cyy + 2, 2, 2, "Y")
		_px(CO, cxx + 4, cyy + 3, "r")
		_comp(G, CO)
	# coroa de ouro atrás do olho (fica sempre: o Sapo-Rei não tira a coroa)
	if not BichoPx.cabeca_coberta:
		var CR := _nova()
		_bmp(CR, hx - 1, hy + 1, _SAPO_COROA)
		_comp(G, CR)
	# língua do golpe
	if g["tl"] > 0:
		var TL := _nova()
		var tl: int = g["tl"]
		var x0: int = hx + int(ch["ms"]) + 1
		var yt: int = hy + int(ch["js"]) + 1
		_rect(TL, x0, yt, tl + hw - int(ch["ms"]) - 2, 1, "T")
		_rect(TL, x0, yt + 1, tl + hw - int(ch["ms"]) - 2, 1, "U")
		var xe: int = x0 + tl + hw - int(ch["ms"]) - 2
		_rect(TL, xe, yt - 1, 3, 2, "T")
		_rect(TL, xe, yt + 1, 3, 2, "U")
		_comp(G, TL)

## Tira do molde do tronco os pixels de uma camada pintada depois do corpo (ela fica por cima da roupa de corpo).
static func _tira_camada(TR: PackedInt32Array, L: PackedInt32Array) -> void:
	for k in L.size():
		if L[k] != 0:
			TR[k] = 0

static func desenhar(c: CanvasItem, familia: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var g: Dictionary = _geo(chefe_tipo, anim, andando, golpe, parado)
	var k: String = _chave(g)
	if not _cache.has(k):
		_cache[k] = _monta(g)
	var s: Dictionary = _cache[k]
	BichoPx.ultimo_quadro = s   # as roupas leem o molde deste quadro sem refazer a pose
	RoupaGato.sprite(c, s["x"], s["y"], s["l"], _pal(int(g["ct"]), alfa), f)

## Quadro em cache do chefe nesta pose (sprite "l", molde do tronco "t", crânio "c"), para as roupas acompanharem o desenho.
static func quadro(chefe_tipo: int, anim: float, andando: bool, golpe: float, parado: bool) -> Dictionary:
	var g: Dictionary = _geo(chefe_tipo, anim, andando, golpe, parado)
	var k: String = _chave(g)
	if not _cache.has(k):
		_cache[k] = _monta(g)
	return _cache[k]
