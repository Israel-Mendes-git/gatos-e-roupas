class_name BichoPxA
extends RefCounted
## Bichos em pixel art, famílias 0 a 2: ratos, guaxinins, raposas, e os chefes Rei dos Ratos, Guaxinim Glutão e Raposa Ligeira (ver BichoPx para as convenções).
## Tudo é desenhado em pixels inteiros, olhando para a direita, patas no chão em y = 0.
## Cada bicho é montado em camadas de bitmaps em texto: rabo, pernas (derivadas dos quadros ANDAR do gato do pacote),
## tronco, cabeça (com boca fechada ou aberta) e adereços. A pose vem de _geo(), usada por desenhar() e por desloc(),
## para a roupa nunca se descolar do corpo.

const _PASSO := 1.3        # quadros de passo por unidade de anim
const _DUR_GOLPE := 0.22   # duração do golpe (golpe vai de 0.22 a 0)

# letras: o = contorno, d = escuro, m = médio, l = claro, p = rosa, P = rosa escuro, k = preto, g = preto suave, n = focinho,
# w = branco, q = boca por dentro, r/R = vermelho, y = amarelo, B = azul, b/z = marrons, u = suor

# ---------------------------------------------------------------- pernas: do gato do pacote (a = escuro/longe, b = médio/perto)
# cada quadro começa na linha da barriga e termina no chão; 32 colunas, x = coluna - 16
const _PERNAS: Array = [
	[  # 0 parado
		".......oaoaabbboooooabbo........",
		".......oaoaabdo...oaobbo........",
		".......oaoaaoo....oaoao.........",
		".......oaobo......oaoao.........",
		"........ooaao......ooabo........",
		"..........oo.........oo.........",
	],
	[  # 1 andar 0
		".......oaobbbbboooooabbo........",
		".......oaobbaao...oaobbo........",
		"........oobaoo...oaaoao.........",
		".........oao.....oaooao.........",
		".........oaao.....o.oabo........",
		"..........oo.........oo.........",
	],
	[  # 2 andar 1
		"........obbbaaaoooooabbo........",
		".......obbaaooo...oaoabo........",
		".......obaoooao...oaooaao.......",
		".......oao..oaao..oao.oaao......",
		".......oaao..ooo..oaao.ooo......",
		"........oo.........ooo..........",
	],
	[  # 3 andar 2 (esticado no ar)
		".......obaaaoooooooobbbbbo......",
		"......obaoooaaoo.oaoooooabo.....",
		".....oaao...oaaaooaaoo..oaao....",
		".....oao.....ooo..oo.....oaao...",
		".....oo...................ooo...",
	],
	[  # 4 andar 4
		"........obbbbaoooooabbo.........",
		".......obbaaao.....obboo........",
		".......obaoooo.....oaoao........",
		".......obo.oao.....oaoao........",
		".......oaaooaao....oabo.........",
		"........oo..oo......oo..........",
	],
	[  # 5 andar 5
		".........ooabbboooobbaoo........",
		"........oaaoabo...obaoao........",
		"........oaaooao..obaooaao.......",
		"........oao.oaao.oao..oaao......",
		"........oaao.ooo.oaao..ooo......",
		".........oo.......ooo...........",
	],
	[  # 6 andar 6 (esticado no ar)
		".......ooaaobboooobbbaoao.......",
		"......oaaaoobbo..obbbooaao......",
		".....oaaoo..oaaoobaoo..oaao.....",
		".....oao.....oaaoao.....oaao....",
		".....oo.......oooo.......ooo....",
	],
]

# ---------------------------------------------------------------- cabeças de lado, 13 colunas; topo + queixo (fechado ou aberto)
const _CAB_TOPO: Array = [
	[  # rato: orelhas enormes, olho com pálpebra malandra
		".oooo.oooo...",
		"oppppoopppo..",
		"opppmoopppmo.",
		".oppmmommmmo.",
		".ommmmmooommo",
		".ommmmwkmmmmo",
		".ommmmkkmmmmn",
	],
	[  # guaxinim: orelhas curtas, máscara preta, bochechas claras
		"..oo...oo....",
		".ommo.ommmo..",
		".ommmmmmmmmo.",
		"ommmmmmmmmmmo",
		"ommkkkkkkkllo",
		"olkkkwwkkklln",
		"ollllkkkkllno",
	],
	[  # raposa: orelhas grandes de ponta preta, focinho fino
		"...k....k....",
		"..okk..okk...",
		"..ommoommmo..",
		".ommmmmmmmmo.",
		".ommmmmoooomo",
		".ommmmwkkmmmo",
		".ollllmommmkk",
	],
]
const _CAB_FECHADA: Array = [
	["..ollllllloo.", "...oooooooo.."],
	[".olllllllllo.", "..ollllllllo.", "...ooooooo..."],
	["..ollllllllo.", "...olllllo...", "....ooooo...."],
]
const _CAB_ABERTA: Array = [
	["..oqqqqqqqwo.", "..olllllllllo", "...oooooooo.."],
	[".oqqwqqqqwqo.", "..ollllllllo.", "...ooooooo..."],
	[".oqqwqqqqwqo.", "..ollllllllo.", "...ooooooo..."],
]

# ---------------------------------------------------------------- cabeças dos chefes do 1º ato, pixel a pixel (largura = 13 + kc, altura = 7 + fechada + rh)
# Rei dos Ratos: velho rabugento (sobrancelha pesada, pálpebra caída, rugas, orelhas enormes); 17 x 12
const _CH_TOPO: Array = [
	[
		"..ooo.....ooo....",
		".oppoo...oppoo...",
		".opppo...opppo...",
		".oppmoooooommmo..",
		".ommmmmmmmmmmmoo.",
		"ommmmmmkkkkkmmmoo",
		"ommmmmmmkwkkmmmmn",
		"ommmdmmdmmmmmmmmn",
		".ommmmmmmmmmmmmoo",
		".odmmmmmmmmmmmoo.",
	],
	[   # Guaxinim Glutão: bochechas cheias, máscara larga, migalhas; 19 x 14 (11 de topo)
		"...oo.....oo.......",
		"..ommo...ommo......",
		"..ommmooommmo......",
		".ommmmmmmmmmmmo....",
		"ommmmmmmmmmmmmmoo..",
		"ommmmmmmmmmmmmmmmo.",
		"ommkkkkkkkkkkkkkkko",
		"ollkGGGGllllGGGkllo",
		"ollkGGGGlwklGGGkllo",
		"ollllGGGlkklGGlllln",
		"olllllllllllllllllo",
	],
	[   # Raposa Ligeira: focinho fino, olhar esperto de pálpebra estreita, orelhas grandes, cicatriz; 16 x 11 (8 de topo)
		"..k.....k.......",
		".okk...okk......",
		".ommo..ommo.....",
		".ommmoommmmo....",
		".ommmmmmmmkkkoo.",
		".ommmmmmmwkmmRoo",
		".ollllmmmmmmRmkk",
		".ollllllmmmmmmkk",
	],
]
const _CH_FECH: Array = [
	["..oollllllllllloo", "....oooooooooo..."],
	[".olllllllllllllllo.", "..ollllllllllllllo..", "...oooooooooooooo..."],
	["..ollllllllllo..", "...ollllllllo...", "....ooooooooo..."],
]
const _CH_ABER: Array = [
	["..oqqqwqqqqwqqqoo", "..ollllllllllllo.", "....oooooooooo..."],
	[".oqqqwqqqqqqwqqqqo.", "..ollllllllllllllo..", "...oooooooooooooo..."],
	["..oqqwqqqqwqqo..", "..ollllllllllo..", "...ooooooooooo.."],
]
# altura da cabeça em relação ao topo do tronco
const _CAB_SOBE: Array = [3, 3, 5]

# ---------------------------------------------------------------- troncos (20 colunas, x de -10 a 9), sem a cabeça
const _CORPO: Array = [
	[  # rato: baixo, redondo
		"......oooooo........",
		"....ooommllllmmoo...",
		"..oommmmmmlllmmmmmo.",
		".ommmmmmmmmmmmmmmmmo",
		".odmmmmmmmmmmmmmmmmo",
		".oddmmmmmmmmmmmmmmo.",
		"..oddmmmmmmmmmmmmo..",
	],
	[  # guaxinim: gordo, dorso alto
		".....ooooooo........",
		"...oooddmmllmmmo....",
		"..ommmmmmmmmmmmmmoo.",
		".ommmmmmmmmmmmmmmmmo",
		".ommmmmmmmmmmmmmmmmo",
		".odmmmmmmmmmmmmmmmmo",
		".oddmmmmmmmmmmmmmmo.",
		".oddmmmmmmmmmmmmmmo.",
		"..odddmmmmmmmmmmdo..",
	],
	[  # raposa: esguia, comprida
		"...oooooooooo.......",
		"..ommmlllllmmmmooo..",
		".ommmmmmmmmmmmmmmmo.",
		".odmmmmmmmmmmmmmmo..",
		".oddmmmmmmmmmmmmo...",
		"..oddmmmmmmmmmmmo...",
	],
]

# ---------------------------------------------------------------- adereços
const _SACO: Array = [
	"....RR...",
	"...RRRR..",
	"..obbbbo.",
	".obbbbbbo",
	"obbbbbbbo",
	"obbbbzbbo",
	"obbbzzbzo",
	".ozzzzzo.",
]
const _OSSO: Array = [
	"oo.........oo",
	"owowwwwwwwowo",
	"owwwwwwwwwwwo",
	"owosssssssowo",
	"oo.........oo",
]
const _TAMPINHA: Array = [
	"...oooooo...",
	"..oyllyyyyo.",
	".oyyyyyyyyyo",
	"oyzyzyzyzyzo",
	"ozozozozozoo",
]
const _BABADOR: Array = [
	"wwwwwww",
	"wBwBwBw",
	".wwwww.",
	"..www..",
	"...w...",
]
const _PATA: Array = [
	".ooooooo.",
	"ommmmmmmo",
	"ommmmmmwo",
	".ooooooo.",
]
const _MINI: Array = [
	[
		"..oo.oo.",
		".opoopo.",
		".ommmmmo",
		"ommkwmmn",
		".olllllo",
		"..oooo..",
	],
	[
		".oo..oo.",
		"ommoommo",
		"ommmmmmo",
		"okkwkkmn",
		".ollllo.",
		"..oooo..",
	],
	[
		".k..k...",
		"okk.okk.",
		"ommmmmmo",
		"ommwkmmk",
		".olllwo.",
		"..oooo..",
	],
]

static var _cache: Dictionary = {}

static func _pal(fam: int, alfa: float) -> Dictionary:
	var P: Dictionary = {
		"r": Color("c8283a"), "R": Color("8e1a2a"), "y": Color("e8c040"), "B": Color("4a90d8"),
		"b": Color("8a5a30"), "z": Color("5a3a20"), "u": Color("bfe6ff"), "s": Color("b8bcc8"),
		"q": Color("7a1c24"), "w": Color("fbf4e8"), "k": Color("1c161c"), "g": Color("46343a"), "G": Color("7c6c76"),
	}
	match fam:
		0:
			P.merge({"o": Color("34343f"), "d": Color("6a6a7a"), "m": Color("9b9bab"), "l": Color("c2c2cf"), "p": Color("ea9aab"), "P": Color("b8707e"), "n": Color("2a1c24")}, true)
		1:
			P.merge({"o": Color("33262a"), "d": Color("66544f"), "m": Color("8f7b6d"), "l": Color("cdbfae"), "p": Color("d98a8a"), "P": Color("a86a6a"), "n": Color("1c1616")}, true)
		_:
			P.merge({"o": Color("7a2e12"), "d": Color("c25a1c"), "m": Color("ec8530"), "l": Color("f8ad52"), "p": Color("e06a6a"), "P": Color("b04848"), "n": Color("1c161c")}, true)
	for k in P.keys():
		var cc: Color = P[k]
		cc.a = alfa
		P[k] = cc
	return P

static func _rr(c: CanvasItem, x: int, y: int, w: int, h: int, ch: String, P: Dictionary, f: float) -> void:
	if w <= 0 or h <= 0:
		return
	RoupaGato.r(c, x, y, w, h, P[ch], f)

static func _sp(c: CanvasItem, x: int, y: int, lin: Array, P: Dictionary, f: float) -> void:
	RoupaGato.sprite(c, x, y, lin, P, f)

# ---------------------------------------------------------------- transformações de bitmaps
# repete `n` vezes a coluna `idx` em todas as linhas (engorda sem borrar o pixel art)
static func _larga(lin: Array, idx: int, n: int) -> Array:
	var r: Array = []
	for l in lin:
		var s: String = l
		if n > 0 and idx < s.length():
			s = s.substr(0, idx) + s.substr(idx, 1).repeat(n + 1) + s.substr(idx + 1)
		r.append(s)
	return r

static func _alta(lin: Array, idx: int, n: int) -> Array:
	var r: Array = lin.duplicate()
	for i in n:
		r.insert(idx, lin[idx])
	return r

# elipse com contorno: topo claro, barriga escura
static func _blob(w: int, h: int, luz: String = "l", fill: String = "m", sombra: String = "d") -> Array:
	var dentro: Array = []
	for j in h:
		var linha: Array = []
		for i in w:
			var nx: float = (i - (w - 1) * 0.5) / (w * 0.5)
			var ny: float = (j - (h - 1) * 0.5) / (h * 0.5)
			linha.append(nx * nx + ny * ny <= 1.0)
		dentro.append(linha)
	var r: Array = []
	for j in h:
		var s: String = ""
		for i in w:
			if not dentro[j][i]:
				s += "."
				continue
			var borda: bool = i == 0 or j == 0 or i == w - 1 or j == h - 1 or not dentro[j][i - 1] or not dentro[j][i + 1] or not dentro[j - 1][i] or not dentro[j + 1][i]
			if borda:
				s += "o"
			elif j == 1 and i < w * 0.65:
				s += luz
			elif j == h - 2:
				s += sombra
			else:
				s += fill
		r.append(s)
	return r

# rabo: sobe para a ponta (coluna 0); `esp` = meia-espessura por coluna; `cores` = uma letra por coluna
static func _rabo_lin(w: int, h: int, cy_base: int, subida: int, esp: Array, cores: String) -> Array:
	var g: Array = []
	for j in h:
		var linha: Array = []
		for i in w:
			linha.append(".")
		g.append(linha)
	for i in w:
		var cy: int = cy_base - roundi(float(subida) * float(w - 1 - i) / float(w - 1))
		var th: int = esp[i]
		for j in range(cy - th, cy + th + 1):
			if j < 0 or j >= h:
				continue
			var ch: String = cores[i]
			if ch == "m" and th >= 2:
				if j == cy - th:
					ch = "l"
				elif j == cy + th:
					ch = "d"
			g[j][i] = ch
	var r: Array = []
	for j in h:
		var s: String = ""
		for i in w:
			if g[j][i] != ".":
				s += g[j][i]
				continue
			var viz: bool = (i > 0 and g[j][i - 1] != ".") or (i < w - 1 and g[j][i + 1] != ".") or (j > 0 and g[j - 1][i] != ".") or (j < h - 1 and g[j + 1][i] != ".")
			s += "o" if viz else "."
		r.append(s)
	return r

static func _rabo(fam: int, grosso: int, wag: int) -> Array:
	var key: String = "t%d_%d_%d" % [fam, grosso, wag]
	if _cache.has(key):
		return _cache[key]
	var r: Array = []
	if fam == 0:
		if wag == 0:
			r = ["............", "..........pp", "........ppP.", "......ppP...", ".....pP.....", "....pP......", "...pp.pp....", "....pppP...."]
		else:
			r = ["............", "..........pp", "........ppP.", "......ppP...", ".....pP.p...", "....pP.pP...", "...pp.pP....", "....ppP....."]
	elif fam == 1:
		var e: Array = [1, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2]
		for i in e.size():
			e[i] += grosso if i > 1 else 0
		r = _rabo_lin(14, 15 + 2 * grosso, 9 + grosso, 3 + wag, e, "kkmmkkmmkkmmkk")
	else:
		var e2: Array = [1, 2, 3, 3, 3, 3, 3, 2, 2, 2, 1, 1, 1, 1, 1]
		for i in e2.size():
			e2[i] += grosso if (i > 1 and i < 10) else 0
		r = _rabo_lin(15, 13 + 2 * grosso, 8 + grosso, 3 + wag, e2, "wwwwwmmmmmmmmmm")
	_cache[key] = r
	return r

# pernas do quadro `fr`, mais curtas (rato, guaxinim) ou mais longas (raposa) e com os pés pintados por espécie
static func _pernas(fam: int, fr: int, rl: int) -> Array:
	var key: String = "p%d_%d_%d" % [fam, fr, rl]
	if _cache.has(key):
		return _cache[key]
	var src: Array = _PERNAS[fr].duplicate()
	var delta: int = int([-2, -1, 2][fam]) + rl
	if delta < 0:
		for i in mini(-delta, src.size() - 3):
			src.remove_at(2)
	elif delta > 0:
		src = _alta(src, 2, delta)
	var pes: int = [1, 2, 4][fam]
	var out: Array = []
	for r in src.size():
		var s: String = src[r]
		var t: String = ""
		var pe: bool = r >= src.size() - pes
		for ch in s:
			var o: String = ch
			match ch:
				"a", "d":
					o = "d"
				"b":
					o = "m"
				"c":
					o = "l"
				"e":
					o = "p"
			if pe:
				if fam == 2:
					o = "k" if o == "m" else ("g" if o == "d" else o)
				elif fam == 1:
					o = "d" if o == "m" else ("o" if o == "d" else o)
				else:
					o = "p" if o == "m" else ("P" if o == "d" else o)
			t += o
		out.append(t)
	_cache[key] = out
	return out

static func _corpo_lin(fam: int, k: int, rb: int, sal: bool) -> Array:
	var key: String = "c%d_%d_%d_%s" % [fam, k, rb, str(sal)]
	if _cache.has(key):
		return _cache[key]
	var r: Array = _CORPO[fam].duplicate()
	r = _larga(r, 10, k)
	r = _alta(r, 3, rb)
	if sal:
		r.remove_at(3)
	_cache[key] = r
	return r

static func _ajusta(l: String, w: int) -> String:
	return l.substr(0, w) + ".".repeat(maxi(0, w - l.length()))

static func _cab_lin(fam: int, kc: int, rh: int, boca: bool, chefe: bool = false) -> Array:
	var key: String = "h%d_%d_%d_%s_%s" % [fam, kc, rh, str(boca), str(chefe)]
	if _cache.has(key):
		return _cache[key]
	if chefe:
		var w: int = 13 + kc
		var rc: Array = []
		for l in _CH_TOPO[fam]:
			rc.append(_ajusta(l, w))
		for l in (_CH_ABER[fam] if boca else _CH_FECH[fam]):
			rc.append(_ajusta(l, w))
		_cache[key] = rc
		return rc
	var r: Array = _CAB_TOPO[fam].duplicate()
	r.append_array(_CAB_ABERTA[fam] if boca else _CAB_FECHADA[fam])
	r = _larga(r, 4, kc)
	r = _alta(r, 3, rh)
	_cache[key] = r
	return r

# ---------------------------------------------------------------- pose
## Geometria comum a desenhar() e desloc(): onde fica cada camada neste quadro. Tudo em pixels inteiros.
static func _geo(fam: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Dictionary:
	var chefe: bool = chefe_tipo >= 0
	var gig: bool = tipo == Unidade.Tipo.GIGANTE and not chefe
	var sal: bool = tipo == Unidade.Tipo.SALTADOR and not chefe
	var k: int = 0     # colunas a mais no tronco
	var rb: int = 0    # linhas a mais no tronco
	var kc: int = 0    # colunas a mais na cabeça
	var rh: int = 0    # linhas a mais na cabeça
	var rl: int = 0    # linhas a mais nas pernas
	kc = 2
	if fam == 0:
		rb = 1
	if gig:
		k = 2
		rb += 1
		kc = 3
		rh = 1
	if sal:
		rl = 2
	if chefe_tipo == 0:
		k = 6
		rb = 3
		kc = 4
		rh = 3
	elif chefe_tipo == 1:
		k = 8
		rb = 6
		kc = 6
		rh = 4
	elif chefe_tipo == 2:
		k = 2
		rb = 1
		rl = 1
		kc = 3
		rh = 1
	var q: int = 0
	var fr: int = 0
	var salto: int = 0
	var aire: int = 0   # Saltador no ar: 0 = no chão, 1 = subindo (corpo esticado, patas estendidas), 2 = descendo (patas recolhidas)
	if andando:
		var fase: float = fposmod(anim * _PASSO, 1.0)
		q = posmod(int(anim * _PASSO), 6)
		if sal:
			salto = roundi(3.0 * sin(PI * fase))
			fr = 0 if salto == 0 else (3 if fase < 0.5 else 6)
			if salto > 0:
				aire = 1 if fase < 0.5 else 2
				k += 2
		else:
			fr = 1 + q
	elif chefe_tipo == 2 and parado:
		q = posmod(int(anim * 4.0), 2)
		fr = q   # pernas trêmulas
	var e: float = 0.0
	if golpe > 0.0:
		e = sin(PI * clampf(1.0 - golpe / _DUR_GOLPE, 0.0, 1.0))
	var boca: bool = e > 0.35 or (chefe_tipo == 2 and parado)
	var legs: Array = _pernas(fam, fr, rl)
	var body: Array = _corpo_lin(fam, k, rb, false)
	var head: Array = _cab_lin(fam, kc, rh, boca, chefe and chefe_tipo <= 2)
	var n: int = legs.size()
	var m: int = body.size()
	var hw: int = String(head[0]).length()
	var hh: int = _CAB_TOPO[fam].size() + _CAB_FECHADA[fam].size() + rh
	if chefe and chefe_tipo <= 2:
		hh = _CH_TOPO[fam].size() + _CH_FECH[fam].size()
	var gx: int = -(k >> 1)
	var oy: int = -salto
	var yb: int = oy - n - m
	var hdx: int = roundi((3.0 if chefe else 2.0) * e)
	var hdy: int = 0
	if aire > 0:
		hdx += 1
		hdy = -1 if aire == 1 else 0
	match BichoPx.pose_truque:
		Unidade.Tipo.ESCUDEIRO:
			hdx -= 2   # encolhido atrás do escudo: cabeça baixa e recuada
			hdy += 3
		Unidade.Tipo.BOMBA:
			hdx += 2   # corre inclinado para a frente, curvado sob o peso da bomba
			hdy += 2
		Unidade.Tipo.ATIRADOR:
			if e > 0.0:
				hdx = 0   # na hora do tiro fica ereto, cabeça erguida, mirando
				hdy = -1
	if chefe_tipo == 2 and parado:
		hdx = 1
		hdy = 3 + (q % 2)
	var hx: int = 11 + k + gx - (hw - 1) + hdx
	var hy: int = yb - int(_CAB_SOBE[fam]) - rh + hdy
	return {"q": q, "fr": fr, "salto": salto, "e": e, "boca": boca, "legs": legs, "body": body, "head": head,
		"n": n, "m": m, "hw": hw, "hh": hh, "gx": gx, "k": k, "kc": kc, "rb": rb, "rh": rh, "oy": oy, "yb": yb,
		"hx": hx, "hy": hy, "bx": -10 + gx, "lx": -16 + gx, "gig": gig, "sal": sal, "chefe": chefe, "aire": aire}

static func desloc(onde: int, fam: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Vector2:
	fam = clampi(fam, 0, 2)
	var g: Dictionary = _geo(fam, tipo, anim, andando, golpe, chefe_tipo, parado)
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hw: int = g["hw"]
	var hh: int = g["hh"]
	var yb: int = g["yb"]
	var m: int = g["m"]
	var bx: int = g["bx"]
	var p: Vector2 = Vector2.ZERO
	match onde:
		RoupaGato.Onde.CABECA:
			p = Vector2(hx + hw * 0.5, hy + 1) - Vector2(5.5, -16.0)
		RoupaGato.Onde.BOCA:
			p = Vector2(hx + hw - 1, hy + 6) - Vector2(11.0, -11.0)
		RoupaGato.Onde.ROSTO:
			p = Vector2(hx + 7, hy + 5) - Vector2(7.0, -13.0)
		RoupaGato.Onde.PESCOCO:
			p = Vector2(hx + 2, hy + hh - 2) - Vector2(2.0, -11.0)
		RoupaGato.Onde.CORPO:
			p = Vector2(bx + 10 + (int(g["k"]) >> 1) - 0.5, yb + m * 0.5) - Vector2(-0.5, -9.0)
		RoupaGato.Onde.TRASEIRA:
			p = Vector2(bx + 2, yb + 1) - Vector2(-8.0, -12.0)
		RoupaGato.Onde.PATAS:
			if int(g["aire"]) > 0:
				return Vector2(0, 5000)   # no salto as patas são esticadas: botas de roupa saem de cena em vez de flutuar fora das patas
			return Vector2(0, -int(g["salto"]))
	return Vector2(roundf(p.x), roundf(p.y))

# perna fina de 2 px de grossura com contorno, de (x0, y0) a (x1, y1); o último 2 x 2 leva a cor do pé
static func _pata_ar(c: CanvasItem, x0: int, y0: int, x1: int, y1: int, cor: String, pe: String, P: Dictionary, f: float) -> void:
	var n: int = maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for pas in 2:
		for i in n + 1:
			var t: float = float(i) / float(n)
			var x: int = roundi(lerpf(x0, x1, t))
			var y: int = roundi(lerpf(y0, y1, t))
			if pas == 0:
				_rr(c, x - 1, y - 1, 4, 4, "o", P, f)
			else:
				_rr(c, x, y, 2, 2, pe if i >= n - 1 else cor, P, f)

# patas do Saltador no ar. aire 1 = subindo: dianteiras para a frente e traseiras para trás, estendidas (corpo em arco);
# aire 2 = descendo: dianteiras alcançando o chão, traseiras recolhidas sob a barriga.
static func _pernas_ar(c: CanvasItem, fam: int, aire: int, bx: int, lw: int, fundo: int, oy: int, n: int, P: Dictionary, f: float) -> void:
	var pe: String = "k" if fam == 2 else ("d" if fam == 1 else "p")
	var fx: int = bx + lw - 7
	var rx: int = bx + 4
	var y0: int = fundo - 2
	var cai: int = 1 + n / 4
	if aire == 1:
		_pata_ar(c, fx - 2, y0, fx + 5, y0 + cai, "d", pe, P, f)     # dianteira de longe (mais curta, escura)
		_pata_ar(c, rx + 2, y0, rx - 5, y0 + cai, "d", pe, P, f)     # traseira de longe
		_pata_ar(c, fx, y0, fx + 8, y0 + cai - 1, "m", pe, P, f)     # dianteira de perto
		_pata_ar(c, rx, y0, rx - 8, y0 + cai - 1, "m", pe, P, f)     # traseira de perto
	else:
		var py: int = oy - 3
		_pata_ar(c, fx - 2, y0, fx + 1, py, "d", pe, P, f)
		_pata_ar(c, fx + 1, y0, fx + 5, py + 1, "m", pe, P, f)
		_pata_ar(c, rx + 2, y0, rx - 1, y0 + 3 + n / 3, "d", pe, P, f)
		_pata_ar(c, rx, y0, rx + 3, y0 + 3 + n / 3, "m", pe, P, f)

# ---------------------------------------------------------------- filhote solto da Ninhada: cabeça grande, corpo pequeno
static func _filhote(c: CanvasItem, fam: int, P: Dictionary, f: float, anim: float, andando: bool) -> void:
	var q: int = posmod(int(anim * _PASSO), 2) if andando else 0
	var dy: int = -q if andando else 0
	var inf: String = "k" if fam == 2 else ("d" if fam == 1 else "p")
	var cab: Array = _cab_lin(fam, 0, 0, false)
	var hh: int = cab.size()
	match fam:
		0:
			for i in 5:
				_rr(c, -12 - i, dy - 5 + i, 1, 1, "p", P, f)
		1:
			_sp(c, -15, dy - 8, _blob(6, 5, "l", "m", "k"), P, f)
			_rr(c, -13, dy - 6, 1, 1, "k", P, f)
			_rr(c, -11, dy - 6, 1, 1, "k", P, f)
		_:
			_sp(c, -15, dy - 8, _blob(7, 5, "l", "m", "d"), P, f)
			_rr(c, -15, dy - 6, 2, 3, "w", P, f)
	for pp in [[-8, q], [-5, 1 - q], [1, 1 - q], [4, q]]:
		var lf: int = 1 if int(pp[1]) == 1 and andando else 0
		_rr(c, int(pp[0]) - 1, -3 - lf, 4, 3, "o", P, f)
		_rr(c, int(pp[0]), -3 - lf, 2, 2, inf if int(pp[0]) < 0 else "m", P, f)
	_sp(c, -11, dy - 8, _blob(12, 6), P, f)
	_sp(c, -2, dy - hh - 3, cab, P, f)

# um filhote nas costas da Ninhada: x = canto esquerdo da cabeça, by = chão dele
static func _mini(c: CanvasItem, fam: int, x: int, by: int, P: Dictionary, f: float) -> void:
	_sp(c, x - 6, by - 5, _blob(8, 5), P, f)
	_sp(c, x, by - 8, _alta(_larga(_MINI[fam], 3, 1), 2, 1), P, f)

# ---------------------------------------------------------------- desenho
static func desenhar(c: CanvasItem, fam: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	fam = clampi(fam, 0, 2)
	var P: Dictionary = _pal(fam, alfa)
	if filhote:
		_filhote(c, fam, P, f, anim, andando)
		return
	var g: Dictionary = _geo(fam, tipo, anim, andando, golpe, chefe_tipo, parado)
	var q: int = g["q"]
	var e: float = g["e"]
	var n: int = g["n"]
	var m: int = g["m"]
	var oy: int = g["oy"]
	var yb: int = g["yb"]
	var bx: int = g["bx"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hw: int = g["hw"]
	var hh: int = g["hh"]
	var k: int = g["k"]
	var kc: int = g["kc"]
	var rh: int = g["rh"]
	var gx: int = g["gx"]
	var sal: bool = g["sal"]
	var gig: bool = g["gig"]
	var chefe: bool = g["chefe"]
	var aire: int = g["aire"]
	var lw: int = k + 20   # largura do tronco

	# rabo (nasce na anca)
	var grosso: int = 1 if (gig or chefe) else 0
	var wag: int = (q % 2) if andando else 0
	if aire > 0 and fam > 0:
		wag = -2   # no salto o rabo acompanha esticado para trás
	var rabo: Array = _rabo(fam, grosso, wag)
	var rw: int = String(rabo[0]).length()
	var ry: int = yb + 3
	if fam == 1:
		ry = yb + 4 - (9 + grosso)
	elif fam == 2:
		ry = yb + 2 - (8 + grosso)
	_sp(c, bx - (rw - 2), ry, rabo, P, f)

	# pernas (do molde do gato); no ar, o Saltador usa patas próprias, de silhueta limpa
	if aire > 0:
		_pernas_ar(c, fam, aire, bx, lw, yb + m, oy, n, P, f)
	else:
		_sp(c, g["lx"], oy - n, g["legs"], P, f)

	# ladrão: saco nas costas; ninhada: dois filhotes montados
	if tipo == Unidade.Tipo.LADRAO and not chefe:
		var sy: int = yb - 5
		if carregando:
			_rr(c, bx - 1, sy - 3, 3, 3, "r", P, f)
			_rr(c, bx + 2, sy - 4, 3, 3, "B", P, f)
			_rr(c, bx + 5, sy - 3, 3, 3, "y", P, f)
			_rr(c, bx - 1, sy - 3, 3, 1, "R", P, f)
		_sp(c, bx - 1, sy, _SACO, P, f)
	_sp(c, bx, yb, g["body"], P, f)
	if tipo == Unidade.Tipo.GEMEO and not chefe:
		_mini(c, fam, bx + 4, yb + 3, P, f)
		_mini(c, fam, bx + 13 + k, yb + 3, P, f)

	if sal and aire == 0:
		# coxa traseira dobrada, redonda
		_sp(c, bx - 2, yb + 2, _blob(9, 7, "l", "m", "d"), P, f)   # coxa para trás
	if fam == 2:
		_rr(c, bx + lw - 7, yb + m - 3, 4 + (k >> 1), 2, "w", P, f)   # peito branco
	if gig:
		_sp(c, bx + 8, yb - 3, _blob(10, 5, "l", "m", "d"), P, f)    # ombros

	# chefes: partes do corpo (antes da cabeça)
	if chefe_tipo == 0:
		_capa_rei(c, P, f, bx, yb, m)
		_sp(c, bx + lw - 13, yb + 3, _blob(11, m - 3, "l", "l", "m"), P, f)   # barriga de rei
	elif chefe_tipo == 1:
		_sp(c, bx + 2, yb + m - 6, _blob(lw - 4, 9, "l", "l", "m"), P, f)
		_rr(c, bx + 2 + (lw - 4) / 2, yb + m - 1, 1, 1, "d", P, f)   # umbigo

	# cabeça
	_sp(c, hx, hy, g["head"], P, f)
	if fam == 0:
		if chefe:
			# bigodes longos e caídos de velho
			_rr(c, hx + hw, hy + 6, 6, 1, "s", P, f)
			_rr(c, hx + hw + 5, hy + 7, 2, 1, "s", P, f)
			_rr(c, hx + hw, hy + 8, 6, 1, "s", P, f)
			_rr(c, hx + hw + 5, hy + 9, 2, 1, "s", P, f)
			_rr(c, hx + hw + 1, hy + 5, 3, 1, "s", P, f)
		else:
			_rr(c, hx + hw, hy + 5, 2, 1, "s", P, f)    # bigodes
			_rr(c, hx + hw + 1, hy + 4, 1, 1, "s", P, f)
			_rr(c, hx + hw, hy + 7, 2, 1, "s", P, f)
			_rr(c, hx + hw + 1, hy + 8, 1, 1, "s", P, f)
	if e > 0.0:
		# golpe: pata da frente sobe e avança sob o queixo
		_sp(c, hx + 2 + roundi(4.0 * e), hy + hh - 1 + (0 if e > 0.4 else 2), _PATA, P, f)
	if gig:
		_rr(c, hx + 5 + kc, hy + 3 + rh, 4, 1, "k", P, f)   # cara fechada: sobrancelha pesada
	if chefe_tipo == 2 and parado:
		_rr(c, hx + hw - 6, hy + hh - 1, 2, 3, "p", P, f)    # língua de fora
		_rr(c, hx + hw - 6, hy + hh + 1, 2, 1, "P", P, f)

	# lenço do ladrão
	if tipo == Unidade.Tipo.LADRAO and not chefe:
		var lx: int = hx + 1
		var ly: int = hy + hh - 3
		_rr(c, lx, ly, 7, 1, "R", P, f)
		_rr(c, lx, ly + 1, 7, 2, "r", P, f)
		_rr(c, lx + 5, ly + 3, 2, 2, "r", P, f)
		_rr(c, lx + 6, ly + 4, 1, 1, "R", P, f)
		_rr(c, lx - 3, ly + (q % 2), 3, 1, "r", P, f)
		_rr(c, lx - 2, ly + 1 + (q % 2), 1, 1, "R", P, f)

	# chefes: adereços
	if chefe_tipo == 0:
		_rr(c, hx + hw - 6, hy + hh - 2, 2, 3, "w", P, f)   # dentes de roedor para fora da boca
		_rr(c, hx + hw - 6, hy + hh + 1, 2, 1, "o", P, f)
		# coroa pequena e torta, de lado entre as orelhas
		_sp(c, hx + 6, hy - 3, ["y...y.y..", "yy.yyyyy.", "yyyyyyyyo", "zyzrzyzoo"], P, f)
		_rr(c, hx + 1, hy + hh - 1, 6, 2, "w", P, f)   # gola de pele
		_rr(c, hx + 2, hy + hh - 1, 1, 1, "k", P, f)
		_rr(c, hx + 5, hy + hh, 1, 1, "k", P, f)
		var cx: int = 9 + k + gx
		_rr(c, cx, -15 + oy, 1, 14, "b", P, f)           # cetro de palito
		_rr(c, cx + 1, -15 + oy, 1, 14, "z", P, f)
		_sp(c, cx - 1, -18 + oy, [".y.", "yry", ".y."], P, f)
	elif chefe_tipo == 1:
		_sp(c, hx + hw - 11, hy + hh - 3, _larga(_OSSO, 6, 4), P, f)
		_sp(c, hx + 1, hy + hh, _BABADOR, P, f)
		# baba e migalhas no focinho
		_rr(c, hx + hw - 5, hy + hh, 1, 3 + (int(anim * 2.0) % 2), "u", P, f)
		_rr(c, hx + hw - 2, hy + hh + 2, 1, 1, "y", P, f)
		_rr(c, hx + hw - 8, hy + hh + 1, 1, 1, "b", P, f)
		_rr(c, hx + hw - 3, hy + hh - 4, 1, 1, "y", P, f)
	elif chefe_tipo == 2:
		if andando:
			# rastro de velocidade atrás da raposa
			for i in 3:
				_rr(c, bx - 14 - i * 3, yb + 1 + i * 4, 9 - i, 1, "w", P, f)
		var fx: int = hx + 2
		_rr(c, fx, hy + 3, 8, 1, "r", P, f)
		_rr(c, fx, hy + 4, 8, 1, "R", P, f)
		var fase: float = anim * 7.0
		for i in 10:
			var ox: int = fx - 1 - i
			var wy: int = roundi(sin(fase - i * 0.8) * 1.0)
			_rr(c, ox, hy + 3 + wy, 1, 2, "r" if i % 3 != 2 else "R", P, f)
			_rr(c, ox, hy + 5 + roundi(sin(fase - i * 0.8 + 1.5) * 1.0), 1, 1, "R", P, f)
		if parado:
			var gt: int = posmod(int(anim * 2.0), 3)
			_rr(c, hx + 1, hy - 2 + gt, 1, 2, "u", P, f)
			_rr(c, hx + 11, hy + 1 + gt, 1, 2, "u", P, f)
			_rr(c, hx - 2, hy + 3 + (gt + 1) % 3, 1, 2, "u", P, f)

# capa remendada do Rei dos Ratos, caindo pelas costas
static func _capa_rei(c: CanvasItem, P: Dictionary, f: float, bx: int, yb: int, m: int) -> void:
	var h: int = m - 3
	_rr(c, bx + 3, yb - 2, 12, 1, "o", P, f)
	for j in h:
		var x0: int = bx + 3 - int(j * 0.7)
		var x1: int = bx + 14 - int(j * 0.2)
		var y: int = yb - 1 + j
		_rr(c, x0, y, x1 - x0 + 1, 1, "R" if j == 0 else "r", P, f)
		_rr(c, x0 - 1, y, 1, 1, "o", P, f)
		_rr(c, x1 + 1, y, 1, 1, "o", P, f)
	# bainha em ondas
	for i in range(0, 12, 2):
		_rr(c, bx - 4 + i, yb + h - 1, 2, 1, "o", P, f)
	# remendos com pontos de costura
	_rr(c, bx + 4, yb + 2, 3, 3, "y", P, f)
	_rr(c, bx + 4, yb + 2, 1, 1, "w", P, f)
	_rr(c, bx + 8, yb + 4, 3, 3, "B", P, f)
	_rr(c, bx + 10, yb + 4, 1, 1, "w", P, f)
	_rr(c, bx + 13, yb + 1, 2, 2, "w", P, f)
	_rr(c, bx + 1, yb + 6, 2, 2, "R", P, f)
