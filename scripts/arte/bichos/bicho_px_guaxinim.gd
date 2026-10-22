class_name BichoPxGuaxinim
extends RefCounted
## Guaxinins (família 1, fora o Guaxinim Glutão) em pixel art, refeitos do zero (2ª versão). Mesmo método de BichoPxRato: camadas numa
## grade de letras, contorno quase preto de 1 px por camada, 3 tons (l m d) + máscara preta (a) + rosto/focinho claro (f) + patas
## "luva" escuras (u perto, a longe) + brilho no olho, cache por pose, _geo único para desenhar() e desloc().
## Marca da família: dorso arqueado (anca mais alta que o ombro), rabo grosso com anéis claros/pretos, máscara preta larga sobre
## rosto branco com focinho fino, orelhas redondas de borda clara, patas pretas finas.
## Cinco silhuetas: Comum (cinza clássico), Saltador (prateado, sentado e esguio, rabo erguido em S), Ladrão (escuro, gorro
## listrado e saco nas costas), Grandalhão (marrom parrudo, barrigão, cenho), Ninhada (mãe pêssego, dois filhotes separados
## nas costas) e o filhote solto (cabeçona).

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
	"A": {"js": 7, "ms": 10, "ab": 2, "ct": 5.5, "ex": 5, "ey": 5, "ny": 5, "rows": [
		"...llllll.......",
		".llllllllll.....",
		"llllllllllllm...",
		"lllffffffffmm...",
		"lmaaaaaaaffmmm..",
		"mmaaawyaaaffffnn",
		"mmaaaaaaaafffffn",
		"mmmfaaafffffff..",
		".dmmfffffffffd..",
		"..ddddffffdd....",
	]},
	"B": {"js": 7, "ms": 10, "ab": 2, "ct": 5.5, "ex": 5, "ey": 5, "ny": 5, "rows": [
		"...llllll.......",
		".llllllllll.....",
		"llllllllllllm...",
		"lllffffffffmm...",
		"lmaaaaaaaffmmm..",
		"mmaaawyaaaffffnn",
		"mmaaaaaaaafffffn",
		"mmmfaaafffffff..",
		".dmmfffffffffd..",
		"..ddddffffdd....",
	]},
	"C": {"js": 7, "ms": 10, "ab": 2, "ct": 5.5, "ex": 5, "ey": 5, "ny": 5, "rows": [
		"...llllll.......",
		".llllllllll.....",
		"llllllllllllm...",
		"lllaaaaaaffmm...",
		"lmaaaaaaaffmmm..",
		"mmaaawyaaaffffnn",
		"mmaaaaaaaafffffn",
		"mmmfaaafffffff..",
		".dmmfffffffffd..",
		"..ddddffffdd....",
	]},
	"D": {"js": 6, "ms": 9, "ab": 2, "ct": 4.5, "ex": 4, "ey": 4, "ny": 4, "rows": [
		"..llllll.....",
		".lllllllll...",
		"lllffffffmm..",
		"lmaaaaaffmm..",
		"maaawyaaffmnn",
		"mmaaaaaffffnn",
		".mmffffffff..",
		"..dddfffd....",
	]},
}

# ---------------------------------------------------------------- medidas de cada tipo (corpo: caixa x, largura, altura, altura das patas)
# bx = coluna da esquerda do tronco; bw/bh = largura/altura; pe = altura das patas; hx = coluna da cabeça; hoff = linha da cabeça
# em relação ao topo do tronco; cab = qual cabeça; pf/pt = x das patas da frente/de trás (a de perto; a de longe fica 3 ao lado)
const _ESP: Array = [
	{"bx": -9, "bw": 16, "bh": 8, "pe": 5, "hx": 2, "hoff": -3, "cab": "A", "pf": 4, "pt": -6, "arq": 4, "rc": 14, "rw": 4},     # COMUM
	{"bx": -9, "bw": 16, "bh": 8, "pe": 3, "hx": 4, "hoff": 1, "cab": "B", "pf": 4, "pt": -6, "arq": 2, "rc": 15, "rw": 4},      # SALTADOR
	{"bx": -9, "bw": 16, "bh": 9, "pe": 5, "hx": 2, "hoff": -1, "cab": "A", "pf": 3, "pt": -6, "arq": 4, "rc": 13, "rw": 4},     # LADRAO
	{"bx": -10, "bw": 18, "bh": 11, "pe": 5, "hx": 3, "hoff": -2, "cab": "C", "pf": 4, "pt": -7, "arq": 4, "rc": 13, "rw": 5},    # GIGANTE
	{"bx": -10, "bw": 19, "bh": 10, "pe": 5, "hx": 4, "hoff": -2, "cab": "A", "pf": 4, "pt": -7, "arq": 4, "rc": 13, "rw": 4},     # GEMEO (mãe)
]

# ---------------------------------------------------------------- paleta
static func _pal(tipo: int, filhote: bool, alfa: float) -> Dictionary:
	var P: Dictionary = {
		"k": Color("1a1418"), "w": Color("ffffff"), "q": Color("7a1c2c"), "y": Color("f0d048"), "r": Color("d8303c"), "R": Color("8e1a2a"),
		"B": Color("4a90d8"), "S": Color("dcb878"), "s": Color("a8804a"), "t": Color("6e4a28"), "W": Color("eceef4"), "z": Color("5a3a20"),
		"g": Color("3ab4a0"), "G": Color("1f7466"),
	}
	match tipo:
		Unidade.Tipo.SALTADOR:
			P.merge({"o": Color("262838"), "l": Color("f2f2fa"), "m": Color("c6cadc"), "d": Color("8a90ac"), "a": Color("2a2c44"), "u": Color("4c4e6c"), "f": Color("ffffff"), "p": Color("e8b8c8"), "P": Color("a07890"), "n": Color("3a2c3c")}, true)
		Unidade.Tipo.LADRAO:
			P.merge({"o": Color("08060a"), "l": Color("736e6c"), "m": Color("524e50"), "d": Color("34323a"), "a": Color("0e0c10"), "u": Color("2c2a34"), "f": Color("e4dccc"), "p": Color("806068"), "P": Color("503c44"), "n": Color("1a1418")}, true)
		Unidade.Tipo.GIGANTE:
			P.merge({"o": Color("260e10"), "l": Color("c8a080"), "m": Color("986a50"), "d": Color("66402e"), "a": Color("160a0e"), "u": Color("3a2420"), "f": Color("f6e4d0"), "v": Color("e0bc9c"), "p": Color("c08880"), "P": Color("804e4c"), "n": Color("2a1618")}, true)
		Unidade.Tipo.GEMEO:
			P.merge({"o": Color("4a3226"), "l": Color("f6dcb4"), "m": Color("e2b88a"), "d": Color("b48c68"), "a": Color("523428"), "u": Color("7e5c48"), "f": Color("fff8ec"), "p": Color("f4a8a0"), "P": Color("c07870"), "n": Color("5a3a30"), "i": Color("e2e2ea"), "j": Color("b6b6c4"), "h": Color("84849a")}, true)
		_:
			P.merge({"o": Color("1e1a1e"), "l": Color("c6c2be"), "m": Color("9a9692"), "d": Color("66626a"), "a": Color("26222a"), "u": Color("4c464e"), "f": Color("f8f2e6"), "p": Color("c49a98"), "P": Color("86605e"), "n": Color("261c22"), "i": Color("c6c2be"), "j": Color("9a9692"), "h": Color("66626a")}, true)
	BichoPx.pal_extra(P)
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
	var e: float = BichoPx.curva_golpe(golpe)   # contato logo no passo do dano, volta desacelerando
	var sal: bool = tipo == Unidade.Tipo.SALTADOR and not filhote
	var gig: bool = tipo == Unidade.Tipo.GIGANTE and not filhote
	var fuga: bool = BichoPx.fuga and andando and not filhote
	var q: int = 0
	var salto: int = 0
	var aire: int = 0
	var agach: int = 0
	var bob: int = 0
	var hbob: int = 0
	var resp: int = 0
	if andando:
		if sal:
			var pl: Vector3i = BichoPx.pulo(anim)   # agacha, voa 9 px, amortece a aterrissagem
			salto = pl.x
			aire = pl.y
			agach = pl.z
			q = 0
		else:
			q = posmod(int(anim * _PASSO), 6)
			var bb: Vector2i = BichoPx.bob_passo(q, gig, fuga)
			bob = bb.x
			hbob = bb.y
	elif golpe <= 0.0:
		resp = (int(Time.get_ticks_msec() / 650) + int(anim * 7.0)) % 2
	var ei: int = roundi(3.0 * e)
	var boca: bool = e > 0.4
	var pr: int = BichoPx.recuo(golpe)        # preparo: cabeça recua 1-2 px e o corpo agacha 1
	var dor: int = 1 if BichoPx.dor else 0
	var esp: Dictionary
	var ch: Dictionary
	if filhote:
		esp = {"bx": -5, "bw": 10, "bh": 7, "pe": 2, "hx": 1, "hoff": -3, "cab": "D", "pf": 2, "pt": -4, "arq": 0, "rc": 8, "rw": 3}
	else:
		esp = _ESP[clampi(tipo, 0, 4)]
	ch = _CAB[esp["cab"]]
	var rows: Array = ch["rows"]
	var hw: int = String(rows[0]).length()
	var hh: int = rows.size()
	var bw: int = esp["bw"]
	var bh: int = esp["bh"]
	var pe: int = esp["pe"]
	var by0: int = -pe - bh - salto + bob + (1 if pr > 0 else 0)
	var bh2: int = bh
	by0 -= resp
	bh2 += resp
	var hdx: int = ei - pr - dor
	var hdy: int = hbob
	match pt:
		Unidade.Tipo.ESCUDEIRO:
			hdx -= 2   # cabeça baixa e recuada atrás do escudo
			hdy += 2
		Unidade.Tipo.BOMBA:
			hdx += 2   # corre curvado para a frente sob o peso da bomba
			hdy += 2
		Unidade.Tipo.ATIRADOR:
			if e > 0.0 or pr > 0:
				hdx = 0   # mirando (no preparo) e no tiro fica ereto
				hdy = -1
	var hx: int = int(esp["hx"]) + hdx
	var hoff: int = int(esp["hoff"])
	if sal and aire == 0:
		# Saltador no chão: sentado nas patas de trás, como guaxinim que se ergue para olhar — anca larga no chão, peito de pé
		# com as mãos pretas juntas na frente, cabeça no alto (by0/bh = o peito); agachado para o pulo o peito encolhe
		by0 = -20 - resp + agach + (1 if pr > 0 else 0)
		bh2 = 13 + resp - agach
		hx = 1 + ei - pr - dor
		hoff = -6
	elif sal:
		# no ar: o corpo do pulo, cabeça à frente — subindo de nariz para cima, descendo de nariz para baixo
		hx = 3 + ei
		hoff = -3 if aire == 1 else -1
	var hy: int = by0 + hoff + hdy - (resp if tipo == Unidade.Tipo.COMUM else 0)
	return {"q": q, "e": e, "ei": ei, "boca": boca, "salto": salto, "aire": aire, "bob": bob, "resp": resp, "esp": esp, "ch": ch,
		"hw": hw, "hh": hh, "bx": int(esp["bx"]), "bw": bw, "bh": bh2, "pe": pe, "by0": by0, "hx": hx, "hy": hy, "pt": pt, "sal": sal, "andando": andando,
		"agach": agach, "pr": pr, "dor": dor, "ol": BichoPx.modo_olho(), "fuga": fuga}

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
			if g["sal"] and int(g["aire"]) == 0:
				p = Vector2(int(g["bx"]) + 3, -12) - RoupaGato.ORIGEM[RoupaGato.Onde.TRASEIRA]   # sentado: o alto da anca
			else:
				p = Vector2(int(g["bx"]) + 2, int(g["by0"]) - 1) - RoupaGato.ORIGEM[RoupaGato.Onde.TRASEIRA]
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

static func _pata(L: PackedInt32Array, x: int, ytop: int, xf: int, yf: int, ch: String, dedo: String, pelo: String = "") -> void:
	# perna de 2 px do quadril (x, ytop) ao pé (xf, yf = linha de baixo): pelo do corpo em cima, "luva" preta nos 3 px de baixo
	var n: int = maxi(1, yf - ytop)
	for i in n + 1:
		var y: int = ytop + i
		var x0: int = roundi(lerpf(x, xf, float(i) / float(n)))
		var c2: String = pelo if pelo != "" and y < yf - 2 else ch
		_px(L, x0, y, c2)
		_px(L, x0 + 1, y, c2)
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
	# as de longe com o pelo num tom bem mais escuro (#) que as de perto: as quatro patas leem separadas
	var defs: Array = [[pt + 3, 0.5, "a", L1], [pf + 3, 0.0, "a", L1], [pt, 0.0, "u", L2], [pf, 0.5, "u", L2]]
	var fuga: bool = g["fuga"]
	if fuga:
		# galope do Ladrão com a carga: as de trás juntas, as da frente juntas (meia volta depois), passada maior
		defs = [[pt + 3, 1.0 / 6.0, "a", L1], [pf + 3, 0.5 + 1.0 / 6.0, "a", L1], [pt, 0.0, "u", L2], [pf, 0.5, "u", L2]]
	for d in defs:
		var x: int = d[0]
		var xf: int = x
		var yf: int = -1
		if andando:
			var ph: float = fposmod(float(q) / 6.0 + float(d[1]), 1.0)
			var pp: Vector2i = BichoPx.pe_passo(x, ph, BichoPx.PASSADA_FUGA if fuga else BichoPx.PASSADA)
			xf = pp.x
			yf = pp.y
		if int(g["ei"]) > 0 and d[1] == 0.5 and d[2] == "u" and x == pf:
			xf = x + 2 + int(g["ei"])   # golpe: pata dianteira de perto sobe e avança
			yf = maxi(hip + 1, -2 - 2 * int(g["ei"]))
		_pata(d[3], x, hip, xf, yf, d[2], "a", "#" if d[2] == "a" else "m")

## Perna de 2 px em qualquer direção, do quadril/ombro (x0, y0) até a pata (x1, y1): pelo do corpo e, nos últimos passos, a luva
## preta; a ponta da pata no tom mais escuro. É a perna do guaxinim no pulo, esticada para a frente ou para trás.
static func _perna_ar(L: PackedInt32Array, x0: int, y0: int, x1: int, y1: int, pelo: String, luva: String) -> void:
	var n: int = maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in n + 1:
		var t: float = float(i) / float(n)
		_rect(L, roundi(lerpf(x0, x1, t)), roundi(lerpf(y0, y1, t)), 2, 2, luva if i >= n - 2 else pelo)
	if absi(x1 - x0) >= absi(y1 - y0):
		_px(L, x1 + 2 if x1 >= x0 else x1 - 1, y1 + 1, "a")
	else:
		_px(L, x1 + 1 if x1 >= x0 else x1, y1 + 2 if y1 >= y0 else y1 - 1, "a")

static func _pernas_sal(L1: PackedInt32Array, L2: PackedInt32Array, g: Dictionary) -> void:
	var bx: int = g["bx"]
	var aire: int = g["aire"]
	var by0: int = g["by0"]
	var bh: int = g["bh"]
	var bw: int = g["bw"]
	var hip: int = by0 + bh - 3
	if aire == 1:
		# subindo: traseiras esticadas para trás e para baixo (o impulso), dianteiras esticadas para a frente
		_perna_ar(L1, bx + 5, hip, bx - 3, hip + 5, "d", "a")
		_perna_ar(L1, bx + bw - 3, hip, bx + bw + 4, hip + 3, "d", "a")
		_perna_ar(L2, bx + 3, hip, bx - 5, hip + 4, "m", "u")
		_perna_ar(L2, bx + bw - 5, hip + 1, bx + bw + 6, hip + 3, "m", "u")   # passa por baixo do queixo
	elif aire == 2:
		# descendo: dianteiras descendo para pegar o chão, traseiras dobradas sob a barriga
		_perna_ar(L1, bx + bw - 3, hip, bx + bw + 1, hip + 6, "d", "a")
		_perna_ar(L1, bx + 5, hip, bx + 8, hip + 4, "d", "a")
		_perna_ar(L2, bx + bw - 5, hip + 1, bx + bw + 3, hip + 6, "m", "u")
		_perna_ar(L2, bx + 3, hip + 1, bx + 6, hip + 5, "m", "u")
	else:
		# sentado: os pés de trás compridos no chão, à frente da anca (luva preta, dedos no tom mais escuro)
		_rect(L1, bx + 6, -2, 8, 2, "a")
		_rect(L2, bx + 4, -2, 8, 2, "u")
		_rect(L2, bx + 11, -2, 1, 2, "a")

## Rabo grosso com anéis: faixas claras (l/m/d) e pretas (a) alternadas, mais grosso no meio, ponta preta arredondada.
## `alto` = erguido em S (Saltador sentado)
static func _rabo(L: PackedInt32Array, g: Dictionary, sx: int, sy: int, comp: int, w: int, alto: bool) -> void:
	var q: int = g["q"]
	var wag: int = roundi(2.0 * sin(TAU * float(q) / 6.0))
	if g["ei"] > 1:
		wag = -3   # no golpe o rabo se ergue
	var n: int = comp * 2
	var nan: int = 6
	for i in n + 1:
		var t: float = float(i) / float(n)
		var cx: int
		var cy: int
		if alto:
			cx = sx - roundi(5.0 * sin(t * PI * 0.8))
			cy = sy - roundi(t * comp * 0.95) + roundi(float(wag) * t)
		else:
			cx = sx - roundi(t * comp)
			cy = sy - roundi(3.0 * sin(t * PI * 0.5)) + roundi(float(wag) * t)
		var wt: int = clampi(roundi(float(w) * (0.72 + 0.5 * sin(minf(t * 1.1, 1.0) * PI * 0.85))), 2, w + 1)
		if t > 0.96:
			wt = maxi(2, wt - 1)
		var an: int = mini(int(t * float(nan)), nan - 1)
		var claro: bool = an % 2 == 0
		for k in wt:
			var c2: String = "a"
			if claro:
				c2 = "m"
				if k == 0:
					c2 = "l"
				elif k >= wt - maxi(1, wt / 3):
					c2 = "d"
			if alto:
				_px(L, cx - wt / 2 + k, cy, c2)
			else:
				_px(L, cx, cy - wt / 2 + k, c2)

static func _orelha(L: PackedInt32Array, x: int, y: int, w: int, h: int, longe: bool) -> void:
	if longe:
		_elip(L, x, y, w, h, "d", "d", "d")
		_tinta(L, x + 1, y + 1, w - 2, h - 2, "a")
	else:
		_elip(L, x, y, w, h, "f", "m", "m")   # borda de cima clara, miolo cinza escuro com o fundo preto
		_tinta(L, x + 1, y + 1, w - 2, h - 2, "d")
		_px(L, x + w / 2, y + h - 2, "a")

## Tronco: duas elipses (anca alta atrás, peito mais baixo) + miolo, com o sombreado dado coluna a coluna (arco do dorso claro,
## barriga escura). x, y = canto de cima à esquerda do ombro; `arq` = quanto a anca sobe acima do ombro.
static func _lomo(L: PackedInt32Array, x: int, y: int, w: int, h: int, arq: int) -> void:
	var M := _nova()
	var rw: int = int(round(w * 0.56))
	var cx: int = int(round(w * 0.36))
	_elip(M, x, y - arq, rw, h + arq)
	_elip(M, x + cx, y, w - cx, h)
	_elip(M, x + w / 6, y - maxi(1, arq - 1), w * 2 / 3, h + maxi(1, arq - 1) - 1)
	for i in _W:
		var top: int = -1
		var bot: int = -1
		for j in _H:
			if M[j * _W + i] != 0:
				if top < 0:
					top = j
				bot = j
		if top < 0:
			continue
		var n: int = bot - top + 1
		var tl: int = maxi(1, int(ceil(n * 0.3)))
		var ts: int = maxi(1, int(ceil(n * 0.26)))
		for j in range(top, bot + 1):
			var ch: String = "m"
			if j - top < tl:
				ch = "l"
			elif bot - j < ts:
				ch = "d"
			L[j * _W + i] = ch.unicode_at(0)

## filhote da ninhada deitado nas costas da mãe, de perfil, um mini-Comum (x, y = canto de baixo à esquerda)
static func _pup(G: PackedInt32Array, x: int, y: int) -> void:
	var L := _nova()
	_bmp(L, x, y - 4, ["aia", "aia"])   # rabinho listrado
	_elip(L, x + 3, y - 5, 7, 5, "i", "j", "h")
	_bmp(L, x + 8, y - 8, [
		".iiiiii.",
		"iikkkkfn",
		"ikkwykfn",
		"jjkkkfff",
		"jjjjffff",
		".hhhhhh.",
	])
	_comp(G, L)
	var O := _nova()
	_orelha(O, x + 8, y - 10, 3, 3, false)
	_orelha(O, x + 12, y - 10, 3, 3, true)
	_comp(G, O)

# ---------------------------------------------------------------- montagem do quadro
static func _chave(g: Dictionary, tipo: int, filhote: bool, carregando: bool) -> String:
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [int(g["andando"]), tipo, int(filhote), int(carregando), g["q"], g["ei"], int(g["boca"]), g["aire"], g["salto"], g["resp"], g["pt"], int(BichoPx.cabeca_coberta),
		g["agach"], g["pr"], g["dor"], g["ol"], int(g["fuga"]), g["bob"]]

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
	var rsy: int = by0 - 1
	var rcomp: int = esp["rc"] if esp.has("rc") else 8
	var rw: int = esp["rw"] if esp.has("rw") else 3
	var alto: bool = false
	var arq: int = esp["arq"] if esp.has("arq") else 2
	if sal:
		if g["aire"] > 0:
			rsy = by0 + 1
		else:
			rsy = -5
			alto = true
	elif filhote:
		rsy = by0 + 1
	_rabo(L, g, bx + 3, rsy, rcomp, rw, alto)
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

	# orelha de longe (à frente da de perto, as duas de cima do crânio)
	var OL := _nova()
	# olho claro sobre a máscara preta: apertado/X em branco
	var cab_rows: Array = BichoPx.olhos(_cab_rows(ch, g["boca"]), int(ch["ex"]), int(ch["ey"]), int(g["ol"]), "wy", "a", "w")
	var od: int = g["dor"]   # dor: orelhas baixas e para trás
	if not lad:
		if sal:
			_orelha(OL, hx + 9 - od, hy - 3 + od, 4, 5, true)
		elif gig:
			_orelha(OL, hx + 6 - od, hy - 2 + od, 4, 4, true)
		elif filhote:
			_orelha(OL, hx + 6 - od, hy - 3 + od, 4, 4, true)
		else:
			_orelha(OL, hx + 6 - od, hy - 2 + od, 4, 4, true)
	_comp(G, OL)

	# corpo + pescoço + cabeça numa camada só
	var B := _nova()
	if sal and g["aire"] == 0:
		_elip(B, bx, -11, 12, 10)                   # anca larga sentada no chão
		_elip(B, bx + 5, by0, 9, bh + 1)            # peito de pé, subindo para a cabeça
	elif sal:
		_lomo(B, bx, by0, bw, bh, arq)              # o corpo corcunda do guaxinim, esticado no pulo
	elif filhote:
		_elip(B, bx, by0, bw, bh)
	else:
		_lomo(B, bx, by0, bw, bh, arq)
	var py0: int = hy + 2
	var TR: PackedInt32Array = B.duplicate()   # só o tronco: molde das peças de corpo (BichoPx.quadro)
	_elip(B, hx - 2, py0, 8, maxi(5, by0 + bh - py0 - 1))   # pescoço
	_bmp(B, hx, hy, cab_rows)
	BichoPx.tirar(TR, _W, _H, hx, hy, cab_rows)   # a roupa de corpo fica atrás da cabeça
	if sal and g["aire"] == 0:
		# braços curtos no peito, na mesma camada do corpo (sem contorno por dentro): só as mãos pretas aparecem, juntas na frente;
		# no golpe a de perto avança
		var ae: int = g["ei"]
		_pata(B, bx + 10, by0 + 5, bx + 12, by0 + 10, "a", "a", "d")
		_pata(B, bx + 11, by0 + 4, bx + 14 + 2 * ae, by0 + 10 - ae, "u", "a", "m")
	if gig:
		_tinta(B, bx + 6, by0 + bh - 7, bw - 12, 7, "v")   # barrigão claro
	elif mae:
		_tinta(B, bx + 5, by0 + bh - 5, bw - 10, 5, "l")
	_comp(G, B)

	# orelha de perto
	var OP := _nova()
	if not lad:
		if sal:
			_orelha(OP, hx + 3 - od, hy - 5 + od, 5, 6, false)
		elif gig:
			_orelha(OP, hx + 2 - od, hy - 3 + od, 5, 5, false)
		elif filhote:
			_orelha(OP, hx + 1 - od, hy - 3 + od, 4, 4, false)
		else:
			_orelha(OP, hx + 2 - od, hy - 3 + od, 5, 5, false)
	_comp(G, OP)

	# adereços
	if sal and g["aire"] == 0:
		# coxa de perto por cima da anca
		var CX := _nova()
		_elip(CX, bx + 1, -11, 9, 9)
		_comp(G, CX)
	if lad:
		var S := _nova()
		var sx: int = bx
		var sy: int = by0 - 3 + (BichoPx.saco_passo(q) if g["fuga"] else 0)   # fugindo: o saco balança fora de fase
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
	# gorro listrado de bandido (verde-azulado e creme) com pompom; sai se o guaxinim veste peça de cabeça
	if lad and not BichoPx.cabeca_coberta:
		var Z := _nova()
		_bmp(Z, hx + 1, hy - 4, [
			"....rr......",
			"...gggggg...",
			"..WWWWWWWW..",
			"..gggggggggg",
			".WWWWWWWWWWW",
		])
		_comp(G, Z)
	if mae:
		var yb: int = by0 + 1
		_pup(G, bx - 4, yb - 3)
		_pup(G, bx + 6, yb + 1)

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
	BichoPx.sprite(c, s, _pal(tipo, filhote, alfa), f)

## Quadro em cache do bicho nesta pose (sprite "l" e molde do tronco "t"), para as roupas acompanharem o desenho.
static func quadro(tipo: int, anim: float, andando: bool, golpe: float) -> Dictionary:
	var g: Dictionary = _geo(tipo, anim, andando, golpe, false, false)
	var k: String = _chave(g, tipo, false, false)
	if not _cache.has(k):
		_cache[k] = _monta(tipo, false, false, g)
	return _cache[k]
