class_name BichoPxSapo
extends RefCounted
## Sapos (família 4, fora o Sapo-Rei) em pixel art, refeitos do zero. Convenções gerais em BichoPx:
## olhando para a DIREITA, patas no chão (último pixel em y = -1, contorno do pé em y = 0), 1 unidade = 1 pixel.
##
## Mesmo método do BichoPxRato: cada quadro é MONTADO em camadas numa grade de letras (patas de longe, corpo + cabeça numa camada só,
## adereços, coxa de perto + pé, papo, braço de perto, lenço, língua). Cada camada ganha contorno quase preto de 1 px (`o`); o interior usa
## 3 tons (l claro, m médio, d escuro) + barriga clara (v/V) + brilho branco no olho. O quadro é recortado, guardado em cache por pose
## e desenhado com RoupaGato.sprite. A geometria (_geo) é a mesma para desenhar() e desloc(), então as roupas acompanham o corpo.
## Anatomia de sapo: agachado, olhos saltados no alto da cabeça, boca larga, coxa traseira dobrada com pé comprido, bracinhos curtos,
## papo que infla (parado), pulo em 6 quadros (agacha, impulso, pico, queda, aterrissa, assenta) e língua no golpe.
## Cinco silhuetas: Comum (sapo verde com manchas), Saltador (perereca de olho vermelho, perna comprida, em pé nos bracinhos),
## Ladrão (sapo cinza-esverdeado, máscara, lenço e saco nas costas), Grandalhão (sapo-cururu marrom, verrugoso, cenho),
## Ninhada (rã azul de bolinhas com dois girinos nas costas) e o filhote solto (sapinho verde-limão de cabeçona).
## O `parte` (sapinho do Sapo-Rei) cai aqui também e usa o corpo de filhote, verde comum.

const _PASSO := 1.3        # quadros de passo por unidade de anim (igual ao dos outros bichos)
const _DUR_GOLPE := 0.22   # duração do golpe (golpe vai de 0.22 a 0)
const _W := 96
const _H := 52
const _OX := 44            # coluna da grade onde x = 0
const _OY := 42            # linha da grade onde y = 0

static var _cache: Dictionary = {}

# ---------------------------------------------------------------- cabeças (sem contorno; `.` = vazio)
# js = primeira linha da mandíbula (a linha do lábio); ms = coluna onde começa a boca; ab = linhas que a boca aberta acrescenta;
# ct = coluna do meio do alto; ex/ey = olho; ny = linha do nariz; my = linha da boca
const _CAB: Dictionary = {
	"A": {"js": 5, "ms": 3, "ab": 3, "ct": 4.0, "ex": 2, "ey": 1, "ny": 4, "my": 5, "rows": [
		"..lllll....",
		".leeweel...",
		".leekkel...",
		"lllllllllm.",
		"mmmmmmmmnmm",
		"mmoooooooom",
		".mmmmmmmmm.",
		"..ddddddd..",
	]},
	"B": {"js": 5, "ms": 2, "ab": 3, "ct": 4.0, "ex": 2, "ey": 1, "ny": 4, "my": 5, "rows": [
		"..lllll...",
		".leeweel..",
		".leekkel..",
		"lllllllllm",
		"mmmmmmmnmm",
		"moooooooom",
		".mmmmmmmm.",
		"..dddddd..",
	]},
	"C": {"js": 5, "ms": 3, "ab": 3, "ct": 5.0, "ex": 2, "ey": 2, "ny": 3, "my": 5, "rows": [
		"..llllll.....",
		".lddddddd....",
		".leewkedlllm.",
		"lllllllllllnm",
		"mmmmmmmmmmmmm",
		"mmooooooooomm",
		".mmmmmmmmmmm.",
		"..ddddddddd..",
	]},
	"D": {"js": 4, "ms": 2, "ab": 2, "ct": 3.0, "ex": 1, "ey": 1, "ny": 3, "my": 4, "rows": [
		"..lll...",
		".leewel.",
		".leekel.",
		"llllllnm",
		"mmoooomm",
		".mmmmmm.",
		"..dddd..",
	]},
}

# ---------------------------------------------------------------- medidas de cada tipo
# bx/bw/bh = tronco; pe = altura do chão ao ventre; hx = coluna da cabeça; hoff = linha da cabeça em relação ao topo do tronco;
# amp = altura do pulo; fl = comprimento do pé; thw/thh = coxa; pw = largura-base do papo
const _ESP: Array = [
	{"bx": -9, "bw": 17, "bh": 12, "pe": 2, "hx": 2, "hoff": -2, "cab": "A", "amp": 4, "fl": 11, "thw": 10, "thh": 9, "pw": 6},    # COMUM
	{"bx": -9, "bw": 14, "bh": 9, "pe": 4, "hx": 3, "hoff": -4, "cab": "B", "amp": 8, "fl": 12, "thw": 10, "thh": 8, "pw": 5},     # SALTADOR
	{"bx": -9, "bw": 16, "bh": 11, "pe": 2, "hx": 2, "hoff": -2, "cab": "A", "amp": 4, "fl": 11, "thw": 9, "thh": 8, "pw": 6},     # LADRAO
	{"bx": -11, "bw": 22, "bh": 13, "pe": 2, "hx": 3, "hoff": -2, "cab": "C", "amp": 2, "fl": 13, "thw": 12, "thh": 10, "pw": 7},  # GIGANTE
	{"bx": -10, "bw": 19, "bh": 12, "pe": 2, "hx": 3, "hoff": -2, "cab": "A", "amp": 3, "fl": 11, "thw": 10, "thh": 9, "pw": 6},   # GEMEO (mãe)
]
const _ESPF: Dictionary = {"bx": -5, "bw": 9, "bh": 6, "pe": 2, "hx": 0, "hoff": -2, "cab": "D", "amp": 3, "fl": 6, "thw": 5, "thh": 5, "pw": 4}   # filhote / sapinho

# bichinho (girino já com patas) que a Ninhada leva nas costas: 8 x 6, letras a/b/c = verde-limão
const _BEBE: Array = [
	"...aaa..",
	"..aewka.",
	"aaaaaaab",
	"bbbbbbbb",
	"bbbbbbbb",
	".cccccc.",
]

# ---------------------------------------------------------------- paleta
# mk: 0 = bicho normal, 1 = filhote solto da Ninhada, 2 = sapinho (parte) do Sapo-Rei
static func _pal(tipo: int, mk: int, alfa: float) -> Dictionary:
	var P: Dictionary = {
		"k": Color("1a1418"), "w": Color("ffffff"), "q": Color("7a1c2c"), "y": Color("f0d048"), "r": Color("d8303c"), "R": Color("8e1a2a"),
		"B": Color("4a90d8"), "S": Color("dcb878"), "s": Color("a8804a"), "t": Color("6e4a28"), "W": Color("eceef4"), "z": Color("5a3a20"),
		"T": Color("e8607c"), "U": Color("b83c5c"),
		"a": Color("c4f46c"), "b": Color("84d444"), "c": Color("3e8c36"),
	}
	var t: int = Unidade.Tipo.COMUM if mk == 2 else tipo
	match t:
		Unidade.Tipo.SALTADOR:
			P.merge({"o": Color("16301a"), "l": Color("d4f26a"), "m": Color("8ede42"), "d": Color("3ea63c"), "v": Color("fffbe0"), "V": Color("d8d6a8"),
				"e": Color("e83030"), "n": Color("2a6a30"), "x": Color("f08a28"), "X": Color("2f6ee0")}, true)
		Unidade.Tipo.LADRAO:
			P.merge({"o": Color("0c1418"), "l": Color("74a496"), "m": Color("4a7a6e"), "d": Color("2c524a"), "v": Color("c0d0be"), "V": Color("90a89c"),
				"e": Color("f4ec50"), "n": Color("1c3830"), "x": Color("244238"), "X": Color("244238")}, true)
		Unidade.Tipo.GIGANTE:
			P.merge({"o": Color("2a1c10"), "l": Color("b4ac58"), "m": Color("857c3c"), "d": Color("56502c"), "v": Color("e8dca0"), "V": Color("bcae70"),
				"e": Color("e0821c"), "n": Color("3a2a18"), "x": Color("3e3a20"), "X": Color("d8d080")}, true)
		Unidade.Tipo.GEMEO:
			if mk == 1:
				P.merge({"o": Color("163014"), "l": Color("c4f46c"), "m": Color("84d444"), "d": Color("3e8c36"), "v": Color("f4f4b8"), "V": Color("c8c880"),
					"e": Color("ffd040"), "n": Color("245a28"), "x": Color("245a28"), "X": Color("245a28")}, true)
			else:
				P.merge({"o": Color("0e1840"), "l": Color("70c8ff"), "m": Color("3088ee"), "d": Color("1c52b8"), "v": Color("eaf4ff"), "V": Color("a8c4e8"),
					"e": Color("ffd040"), "n": Color("10286a"), "x": Color("10143a"), "X": Color("ffd030")}, true)
		_:
			P.merge({"o": Color("10281c"), "l": Color("9ee25c"), "m": Color("58b640"), "d": Color("2f7c3a"), "v": Color("f0eca8"), "V": Color("c4c078"),
				"e": Color("f4c830"), "n": Color("1c4a2c"), "x": Color("1f6030"), "X": Color("1f6030")}, true)
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
static func _geo(tipo: int, anim: float, andando: bool, golpe: float, mini: bool) -> Dictionary:
	var pt: int = BichoPx.pose_truque
	var e: float = 0.0
	if golpe > 0.0:
		e = sin(PI * clampf(1.0 - golpe / _DUR_GOLPE, 0.0, 1.0))
	var esp: Dictionary = _ESPF if mini else _ESP[clampi(tipo, 0, 4)]
	var amp: int = esp["amp"]
	var q: int = 0
	var salto: int = 0
	var aire: int = 0
	var sq: int = 0
	var resp: int = 0
	if andando:
		q = posmod(int(anim * _PASSO), 6)
		var f6: Array = [0.0, 0.55, 1.0, 0.7, 0.0, 0.0]
		var ar: Array = [0, 1, 1, 2, 0, 0]
		salto = roundi(float(amp) * float(f6[q]))
		aire = ar[q]
		sq = 1 if (q == 0 or q == 4) else 0
	elif golpe <= 0.0:
		var ciclo: Array = [0, 1, 2, 1]
		resp = ciclo[(int(Time.get_ticks_msec() / 400) + int(anim * 7.0)) % 4]
	var ei: int = roundi(3.0 * e)
	var boca: bool = e > 0.4
	var tl: int = roundi(5.0 * e) if e > 0.15 else 0
	var ch: Dictionary = _CAB[esp["cab"]]
	var rows: Array = ch["rows"]
	var hw: int = String(rows[0]).length()
	var hh: int = rows.size()
	var bh: int = int(esp["bh"]) - sq
	var pe: int = esp["pe"]
	var by0: int = -pe - bh - salto
	var hx: int = int(esp["hx"]) + ei
	var hy: int = by0 + int(esp["hoff"])
	if aire > 0:
		hx += 1
		hy -= 1
	match pt:
		Unidade.Tipo.ESCUDEIRO:
			hx -= 2   # cabeça baixa e recuada atrás do escudo
			hy += 2
		Unidade.Tipo.BOMBA:
			hx += 2   # curvado para a frente sob o peso da bomba
			hy += 2
		Unidade.Tipo.ATIRADOR:
			if e > 0.0:
				hx = int(esp["hx"])   # na hora do tiro fica ereto, mirando
				hy -= 1
	return {"q": q, "e": e, "ei": ei, "boca": boca, "tl": tl, "salto": salto, "aire": aire, "sq": sq, "resp": resp, "esp": esp, "ch": ch,
		"hw": hw, "hh": hh, "bx": int(esp["bx"]), "bw": int(esp["bw"]), "bh": bh, "pe": pe, "by0": by0, "hx": hx, "hy": hy, "pt": pt, "andando": andando}

## Quanto o lugar `onde` se desloca em relação à planta do gato parado (as roupas acompanham por aqui).
static func desloc(onde: int, familia: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Vector2:
	var g: Dictionary = _geo(tipo, anim, andando, golpe, false)
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
			p = Vector2(hx + hw - 1, hy + int(ch["my"])) - RoupaGato.ORIGEM[RoupaGato.Onde.BOCA]
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
				return Vector2(0, 5000)   # no ar as patas estão esticadas: botas saem de cena em vez de flutuar fora delas
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
	var r: Array = []
	for j in js:
		r.append(rows[j])
	# boca aberta: cavidade vermelha entre a maxilha e a mandíbula, que desce
	for k in int(ch["ab"]):
		var s: String = ""
		for i in base.length():
			if base[i] == ".":
				s += "."
			elif i < ms:
				s += "m"
			else:
				s += "q"
		r.append(s)
	for j in range(js, rows.size()):
		r.append(rows[j])
	return r

# ---------------------------------------------------------------- montagem do quadro
static func _chave(g: Dictionary, tipo: int, mk: int, carregando: bool) -> String:
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [int(g["andando"]), tipo, mk, int(carregando), g["q"], g["ei"], int(g["boca"]), g["tl"], g["aire"], g["salto"], g["sq"], g["resp"], g["pt"], int(g["hx"])]

static func _monta(tipo: int, mk: int, carregando: bool, g: Dictionary) -> Dictionary:
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
	var aire: int = g["aire"]
	var salto: int = g["salto"]
	var q: int = g["q"]
	var mini: bool = mk > 0
	var sal: bool = tipo == Unidade.Tipo.SALTADOR and not mini
	var lad: bool = tipo == Unidade.Tipo.LADRAO and not mini
	var gig: bool = tipo == Unidade.Tipo.GIGANTE and not mini
	var mae: bool = tipo == Unidade.Tipo.GEMEO and not mini
	var tcol: String = "x" if sal else ("X" if mae else "v")   # ponta dos dedos
	var fl: int = esp["fl"]
	var tb: int = by0 + bh - 1          # última linha do tronco
	var fy: int = -2 - salto            # linha de cima do pé
	var fx: int = bx + 5                # coluna do pé de perto
	var ax: int = int(esp["hx"]) + 2    # coluna do braço
	var top: int = by0 + bh - 4         # onde o braço nasce
	var cab_rows: Array = _cab_rows(ch, g["boca"])

	# membros de longe
	var L1 := _nova()
	if aire == 1:
		_trazo(L1, bx + 6, tb - 3, bx - 3, tb + 2, 2, "d")
	else:
		_rect(L1, fx + 3, fy, fl, 1, "d")
		_rect(L1, fx + 3, fy + 1, fl, 1, "d")
	if aire == 0:
		_rect(L1, ax + 3, top + 1, 2, fy - top - 1, "d")
		_rect(L1, ax + 3, fy, 4, 2, "d")
	elif aire == 1:
		_trazo(L1, ax + 2, top + 1, ax + 6, top + 3, 2, "d")
	else:
		_trazo(L1, ax + 2, top + 1, ax + 5, top + 6, 2, "d")
	_comp(G, L1)

	# corpo + pescoço + cabeça numa camada só
	var B := _nova()
	_elip(B, bx, by0, bw, bh)
	var TR: PackedInt32Array = B.duplicate()   # só o tronco: molde das peças de corpo (BichoPx.quadro)
	_elip(B, hx - 1, hy + 3, 8, maxi(4, tb - (hy + 3)))   # pescoço
	_tinta(B, bx + 3, by0 + bh - 5, bw - 6, 5, "v")      # barriga clara
	var rows2: Array = cab_rows
	if lad:
		# máscara de bandido: aro preto em volta do olho e faixa abaixo
		rows2 = []
		for j in cab_rows.size():
			var s: String = cab_rows[j]
			var t: String = ""
			for i in s.length():
				var c1: String = s[i]
				if c1 == "l" and i <= 7 and j <= 3:
					c1 = "k"
				t += c1
			rows2.append(t)
	_bmp(B, hx, hy, rows2)
	# marcas de cada espécie
	if sal:
		for i in range(2, bw - 2):
			_tp(B, bx + i, by0 + 4, "X")   # faixa azul no flanco
		_tp(B, bx + 1, by0 + 3, "X")
	elif gig:
		for w in [[3, 3, "X"], [6, 1, "x"], [9, 3, "X"], [12, 1, "x"], [15, 3, "X"], [18, 2, "x"], [5, 5, "x"], [11, 5, "X"], [16, 6, "x"], [8, 7, "X"]]:
			_tp(B, bx + int(w[0]), by0 + int(w[1]), String(w[2]))
			_tp(B, bx + int(w[0]) + 1, by0 + int(w[1]), String(w[2]))
		_elip(B, hx - 4, hy + 3, 6, 5, "x", "x", "x")        # glândula atrás do olho
		_tp(B, hx - 3, hy + 3, "X")
		_tp(B, hx - 2, hy + 3, "X")
	elif mae:
		for w in [[2, 2], [6, 1], [10, 2], [14, 1], [4, 5], [12, 5], [16, 4]]:
			_rect_t(B, bx + int(w[0]), by0 + int(w[1]), 2, 2, "x")
	elif not mini:
		_tinta(B, bx + 4, by0 + 1, 4, 3, "x")
		_tinta(B, bx + 9, by0 + 1, 3, 3, "x")
		_tinta(B, bx + 13, by0 + 3, 3, 2, "x")
	_comp(G, B)

	# adereços sobre as costas
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
	if mae:
		var BB := _nova()
		_bmp(BB, bx - 1, by0 - 2, _BEBE)
		_bmp(BB, bx + 5, by0 - 3, _BEBE)
		_comp(G, BB)

	# coxa traseira de perto + pé (ou perna esticada no ar)
	var CX := _nova()
	var thw: int = esp["thw"]
	var thh: int = esp["thh"]
	if aire == 1:
		_trazo(CX, bx + 4, tb - 4, bx - 6, tb + 2, 3, "m")
		_rect(CX, bx - 9, tb + 1, 4, 2, tcol)
	else:
		_elip(CX, bx + 1, tb - thh + 1, thw, thh)
		if tb + 1 < fy:
			_trazo(CX, bx + 4, tb - 1, bx + 3, fy - 1, 2, "m")   # canela até o pé
		_rect(CX, fx, fy, fl, 1, "m")
		_rect(CX, fx, fy + 1, fl, 1, "d")
		_rect(CX, fx + fl - 2, fy, 2, 2, tcol)
	_comp(G, CX)

	# papo: infla e desinfla com a respiração
	if not g["andando"] and not g["boca"] and g["ei"] == 0:
		var PL := _nova()
		var rs: int = g["resp"]
		var pw: int = int(esp["pw"]) + 2 * rs
		var ph: int = (2 if mini else 3) + (rs if mini else 2 * rs)
		_elip(PL, hx + 1, hy + hh - 2, pw, ph, "v", "v", "V")
		_comp(G, PL)

	# braço de perto
	var CA := _nova()
	if aire == 0:
		_rect(CA, ax, top, 2, fy - top, "m")
		_rect(CA, ax, fy, 4, 2, "m")
		_rect(CA, ax + 2, fy, 2, 2, tcol)
	elif aire == 1:
		_trazo(CA, ax, top, ax + 5, top + 2, 2, "m")
		_rect(CA, ax + 5, top + 2, 2, 2, tcol)
	else:
		_trazo(CA, ax, top, ax + 3, top + 6, 2, "m")
		_rect(CA, ax + 3, top + 6, 3, 2, tcol)
	_comp(G, CA)

	# lenço vermelho do ladrão, com ponta voando
	if lad:
		var Z := _nova()
		_rect(Z, hx - 1, hy + hh - 4, 6, 2, "r")
		_rect(Z, hx - 1, hy + hh - 2, 5, 1, "R")
		_rect(Z, hx - 4, hy + hh - 4 + (q % 2), 3, 1, "r")
		_rect(Z, hx - 5, hy + hh - 3 + (q % 2), 2, 1, "R")
		_comp(G, Z)

	# língua do golpe
	if g["tl"] > 0:
		var TL := _nova()
		var tl: int = g["tl"]
		var x0: int = hx + int(ch["ms"]) + 1
		var yt: int = hy + int(ch["js"]) + int(ch["ab"]) - 2
		_rect(TL, x0, yt, tl + hw - int(ch["ms"]) - 2, 1, "T")
		_rect(TL, x0, yt + 1, tl + hw - int(ch["ms"]) - 2, 1, "U")
		var xe: int = x0 + tl + hw - int(ch["ms"]) - 2
		_rect(TL, xe, yt - 1, 3, 2, "T")
		_rect(TL, xe, yt + 1, 3, 2, "U")
		_comp(G, TL)

	# recorte
	var x0c: int = _W
	var y0c: int = _H
	var x1c: int = -1
	var y1c: int = -1
	for j in _H:
		for i in _W:
			if G[j * _W + i] != 0:
				x0c = mini(x0c, i)
				x1c = maxi(x1c, i)
				y0c = mini(y0c, j)
				y1c = maxi(y1c, j)
	var lin: Array = []
	for j in range(y0c, y1c + 1):
		var s2: String = ""
		for i in range(x0c, x1c + 1):
			var v: int = G[j * _W + i]
			s2 += String.chr(v) if v != 0 else "."
		lin.append(s2)
	return {"x": x0c - _OX, "y": y0c - _OY, "l": lin, "t": BichoPx.recorte(TR, _W, _H, _OX, _OY), "c": BichoPx.cranio(ch["rows"])}

## Quadradinho pintado só onde a camada já tem pixel.
static func _rect_t(L: PackedInt32Array, x: int, y: int, w: int, h: int, ch: String) -> void:
	for j in h:
		for i in w:
			_tp(L, x + i, y + j, ch)

static func desenhar(c: CanvasItem, familia: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var mk: int = 2 if parte else (1 if filhote else 0)
	var g: Dictionary = _geo(tipo, anim, andando, golpe, mk > 0)
	var k: String = _chave(g, tipo, mk, carregando)
	if not _cache.has(k):
		_cache[k] = _monta(tipo, mk, carregando, g)
	var s: Dictionary = _cache[k]
	BichoPx.ultimo_quadro = s   # as roupas leem o molde deste quadro sem refazer a pose
	RoupaGato.sprite(c, s["x"], s["y"], s["l"], _pal(tipo, mk, alfa), f)

## Quadro em cache do bicho nesta pose (sprite "l" e molde do tronco "t"), para as roupas acompanharem o desenho.
static func quadro(tipo: int, anim: float, andando: bool, golpe: float) -> Dictionary:
	var g: Dictionary = _geo(tipo, anim, andando, golpe, false)
	var k: String = _chave(g, tipo, 0, false)
	if not _cache.has(k):
		_cache[k] = _monta(tipo, 0, false, g)
	return _cache[k]
