class_name BichoPxChefeFora
extends RefCounted
## Os cinco chefes do segundo ato (fora da casa), em pixel art, refeitos do zero no mesmo padrão dos bichos novos
## (BichoPxRato, BichoPxRaposa...): olhando para a DIREITA, patas no chão (último pixel em y = -1, contorno em y = 0),
## 1 unidade = 1 pixel. 5 Toupeira Escavadora, 6 Gambá Fedido, 7 Esquilo Acrobata, 8 Vira-Lata Chefão, 9 Texugo-Rei.
##
## Cada quadro é MONTADO em camadas numa grade de letras (rabo, patas de longe, corpo + cabeça, adereços...). Cada camada
## ganha sozinha um contorno quase preto de 1 px (`o`); o interior usa 3 tons (l claro, m médio, d escuro) mais brilho.
## O quadro vira uma lista de linhas de texto, guardada em cache por pose e desenhada por RoupaGato.sprite.
## A pose (_geo) e as âncoras das roupas saem da mesma conta para desenhar() e desloc(): a roupa nunca se descola.
## Estados: parado (respiração), andar em 6 quadros, golpe em 4 fases (preparo, golpe, segue, volta) e os especiais:
##  - Toupeira: `parado` = debaixo da terra (só o monte com o capacete e a lanterna, terra voando);
##  - Gambá: nuvem de fedor verde sempre subindo, mais forte no golpe;
##  - Esquilo: anda aos pulinhos, rabão balançando; no golpe ergue a bolota e arremessa; pisca parado;
##  - Vira-Lata: `parado` = sem fôlego (cabeça baixa, língua de fora, peito arfando);
##  - Texugo: capa balançando ao vento.

const _PASSO := 1.3
const _DUR_GOLPE := 0.22
const _W := 112
const _H := 84
const _OX := 64
const _OY := 66

static var _cache: Dictionary = {}

# ---------------------------------------------------------------- cabeças (sem contorno; `.` = vazio)
# js = linha onde começa a mandíbula, ms = coluna onde começa a boca, ab = linhas abertas no golpe, ex/ey = olho
const _CAB: Dictionary = {
	"G": {"js": 6, "ms": 8, "ab": 3, "ex": 9, "ey": 3, "rows": [   # gambá
		"...wwwwwwww.....",
		".wwwwwwwwwwww...",
		"lllllwwwwwwwww..",
		"llllmmmmmmmmmmnn",
		"lllmmmmmmmmmmmnn",
		"mmmmmmmmmmmmmn..",
		"mmmmmmmmmmmmmm..",
		".mmmmmmmmmmmm...",
		"..dmmmmmmmmd....",
		"...dddddddd.....",
	]},
	"T": {"js": 6, "ms": 8, "ab": 3, "ex": 9, "ey": 3, "rows": [   # texugo
		"....wwwwwwwwww....",
		"..wwwwwwwwwwwwww..",
		"kkkkkkkkkkkkkkkkk.",
		"kkkkkkkkkkkkkkkknn",
		"kkkkkkkkkkkkkkkknn",
		".wwwwwwwwwwwwwwwn.",
		"..wwwwwwwwwwwwww..",
		"...kkkkkkkkkkkk...",
		".....kkkkkkkk.....",
	]},
}

# ---------------------------------------------------------------- paleta
static func _hx(s: String, a: float = 1.0) -> Color:
	var c := Color(s)
	c.a = a
	return c

static func _pal(ct: int, alfa: float) -> Dictionary:
	var P: Dictionary = {"w": Color("ffffff"), "k": Color("120c14")}
	match ct:
		5:   # toupeira: veludo cinza-escuro, focinho e mãos rosas, garras cremes, capacete amarelo
			P.merge({"o": Color("1a121c"), "l": Color("7c7488"), "m": Color("524c5e"), "d": Color("332e3c"),
				"P": Color("f5bcba"), "p": Color("e48e98"), "Q": Color("b2606f"), "n": Color("6e2f40"), "q": Color("7a1f2a"),
				"c": Color("f6edd2"), "C": Color("ffffff"), "s": Color("b3a374"),
				"Y": Color("f6c61f"), "y": Color("b8860f"), "h": Color("fff08a"), "g": Color("a4afba"), "G": Color("5c6672"), "W": Color("fffbd0"),
				"B": Color("8fdcf6"), "b": Color("3a8ab8"), "S": Color("4a3020"),
				"T": Color("7a5636"), "t": Color("43301f"), "u": Color("a87a4e"),
				"j": _hx("fff2a0", 0.34), "J": _hx("fff2a0", 0.17), "x": _hx("ffffff", 0.7)}, true)
		6:   # gambá: preto-azulado, listra branca, fedor verde
			P.merge({"o": Color("07050c"), "l": Color("4e4764"), "m": Color("2f2a3c"), "d": Color("171420"),
				"w": Color("f8f6fa"), "v": Color("c6c4da"), "n": Color("e08a98"), "y": Color("ffe14a"), "Y": Color("d9a21c"),
				"q": Color("7a1c2c"), "e": Color("9a6a86"),
				"z": _hx("9ae84c", 0.62), "Z": _hx("62b82e", 0.42), "x": _hx("c8f58a", 0.3)}, true)
		7:   # esquilo acrobata: castanho, peito creme, rabão mais claro, faixa verde-água com estrela de ouro
			P.merge({"o": Color("1c1008"), "l": Color("d49a62"), "m": Color("a8683a"), "d": Color("6e4020"), "D": Color("4a2a14"),
				"v": Color("f4e2c0"), "V": Color("cfb58e"), "t": Color("eab77e"), "T": Color("b87842"), "u": Color("7e4a24"),
				"n": Color("3a2018"), "p": Color("e0a08a"), "q": Color("7a1f2a"),
				"R": Color("2fb3a8"), "r": Color("1e7a72"), "G": Color("f4c21f"),
				"S": Color("7a5230"), "s": Color("4e3320"), "a": Color("c98a3e"), "A": Color("8e5a24")}, true)
		8:   # vira-lata: caramelo, focinho e peito creme, coleira preta com pregos
			P.merge({"o": Color("22130a"), "l": Color("f2c486"), "m": Color("d08e4c"), "d": Color("965f2e"),
				"v": Color("f4e6c6"), "V": Color("cdb88e"), "e": Color("5e3b20"), "E": Color("3f2614"), "r": Color("e8a2a0"),
				"n": Color("17141a"), "N": Color("6a6a78"), "q": Color("7a1f2a"), "T": Color("ec6482"), "t": Color("b83a58"),
				"C": Color("26262e"), "c": Color("50505e"), "S": Color("e6ebf2"), "s": Color("7e8696"), "a": Color("a8483c"),
				"B": Color("9fd8ff")}, true)
		9:   # texugo-rei: grisalho, listras pretas e brancas, capa vermelha, coroa de ouro
			P.merge({"o": Color("101016"), "l": Color("cdd0dc"), "m": Color("9093a6"), "d": Color("5a5c6c"),
				"K": Color("3a3a48"), "k": Color("1c1c26"), "w": Color("f8f8fc"), "v": Color("b8bad0"),
				"y": Color("ffd23a"), "n": Color("23232d"), "q": Color("7a1f2a"), "c": Color("f6eedc"), "C": Color("b8ac90"),
				"G": Color("f4c21f"), "g": Color("b8860f"), "h": Color("fff08a"), "R": Color("e8303e"), "r": Color("8e1a2a"),
				"A": Color("d02a3e"), "a": Color("8c1a2e"), "z": Color("f0626c")}, true)
	for kk in P.keys():
		var cc: Color = P[kk]
		cc.a *= alfa
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

static func _lido(L: PackedInt32Array, x: int, y: int) -> int:
	var i: int = x + _OX
	var j: int = y + _OY
	if i < 0 or j < 0 or i >= _W or j >= _H:
		return 0
	return L[j * _W + i]

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

## pinta `ch` só onde já há pixel (dentro de uma elipse)
static func _tinta(L: PackedInt32Array, x: int, y: int, w: int, h: int, ch: String) -> void:
	for j in h:
		for i in w:
			var nx: float = (i + 0.5 - w * 0.5) / (w * 0.5)
			var ny: float = (j + 0.5 - h * 0.5) / (h * 0.5)
			if nx * nx + ny * ny > 1.0:
				continue
			if _lido(L, x + i, y + j) != 0:
				_px(L, x + i, y + j, ch)

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

## faixa de `esp` linhas logo abaixo da borda de cima, de x0 a x1 (só onde há pixel)
static func _faixa_topo(L: PackedInt32Array, x0: int, x1: int, esp: int, ch: String, ch2: String = "") -> void:
	for x in range(x0, x1 + 1):
		for y in range(-_OY, _H - _OY):
			if _lido(L, x, y) != 0:
				for k in esp:
					if _lido(L, x, y + k) != 0:
						_px(L, x, y + k, ch2 if (ch2 != "" and k == esp - 1) else ch)
				break

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

## luz/efeito sem contorno, só onde o quadro ainda está vazio
static func _luz(G: PackedInt32Array, L: PackedInt32Array) -> void:
	for k in L.size():
		if L[k] != 0 and G[k] == 0:
			G[k] = L[k]

static var _ck: Dictionary = {}

## ajusta o tamanho de uma lista de linhas (vizinho mais próximo)
static func _esc(rows: Array, k: float) -> Array:
	var w0: int = String(rows[0]).length()
	var h0: int = rows.size()
	var w1: int = roundi(w0 * k)
	var h1: int = roundi(h0 * k)
	var r: Array = []
	for j in h1:
		var src: String = rows[mini(h0 - 1, int(float(j) / k))]
		var s: String = ""
		for i in w1:
			s += src[mini(w0 - 1, int(float(i) / k))]
		r.append(s)
	return r

## cabeça `nome` de _CAB aumentada `k` vezes (cabeção de chefe)
static func _cabk(nome: String, k: float) -> Dictionary:
	var key: String = "%s%.2f" % [nome, k]
	if not _ck.has(key):
		var b: Dictionary = _CAB[nome]
		var r: Array = _esc(b["rows"], k)
		_ck[key] = {"js": roundi(int(b["js"]) * k), "ms": roundi(int(b["ms"]) * k), "ab": b["ab"], "ex": roundi(int(b["ex"]) * k), "ey": roundi(int(b["ey"]) * k),
			"rows": r, "hw": String(r[0]).length(), "hh": r.size()}
	return _ck[key]

static func _cab_rows(ch: Dictionary, boca: bool) -> Array:
	var r0: Array = _cab_rows0(ch, boca)
	if ch.has("olho"):
		var o: Array = ch["olho"]
		return BichoPx.olhos(r0, int(ch["ex"]), int(ch["ey"]), BichoPx.modo_olho(), o[0], o[1], o[2])
	return r0

static func _cab_rows0(ch: Dictionary, boca: bool) -> Array:
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

## perna de `w` px do quadril (x, ytop) ao pé (xf, yf): os `nm` últimos pixels são a meia (`meia`), o pé é uma pata de w+1 px
static func _pata(L: PackedInt32Array, x: int, ytop: int, xf: int, yf: int, w: int, ch: String, meia: String, nm: int = 3) -> void:
	var n: int = maxi(1, yf - ytop)
	for i in n + 1:
		var y: int = ytop + i
		var x0: int = roundi(lerpf(x, xf, float(i) / float(n)))
		var c: String = meia if i >= n - nm + 1 else ch
		for k in w:
			_px(L, x0 + k, y, c)
	for k in w + 1:
		_px(L, xf + k, yf, meia)

## quatro patas de quadrúpede (duas de longe em L1, duas de perto em L2); `solta` = a pata da frente de perto vai à frente no golpe
static func _pernas(L1: PackedInt32Array, L2: PackedInt32Array, g: Dictionary, pf: int, pt: int, hip: int, w: int, far: String, near: String, meia: String, nm: int, solta: bool = true) -> void:
	var q: int = g["q"]
	var av: int = g["av"]
	var defs: Array = [[pt + 3, 0.5, far, L1, false], [pf + 3, 0.0, far, L1, false], [pt, 0.0, near, L2, false], [pf, 0.5, near, L2, true]]
	for d in defs:
		var x: int = d[0]
		var xf: int = x - av
		var yf: int = -1
		if g["andando"]:
			var ph: float = fposmod(float(q) / 6.0 + float(d[1]), 1.0)
			var pp: Vector2i = BichoPx.pe_passo(x, ph, 2.5, 2.0)   # pé no ar vai para a frente
			xf = pp.x
			yf = pp.y
		if solta and d[4] and int(g["e"]) > 0:
			xf = x + 2 + int(g["e"])
			yf = maxi(hip + 2, -2 - 2 * int(g["e"]))
		_pata(d[3], x, hip, xf, yf, w, d[2], meia, nm)

# ---------------------------------------------------------------- pose (comum a desenhar e desloc)
## Fase do golpe: 0 parado, 1 preparo, 2 golpe (contato), 3 segue, 4 volta. O preparo acontece na janela ANTES do dano
## (BichoPx.preparo, recarga acabando); no passo do dano (golpe = 0,22) já é o contato. Antes o preparo vinha depois do dano.
static func _fase(golpe: float) -> int:
	if golpe <= 0.0:
		return 1 if BichoPx.preparo >= 0.35 else 0
	var t: float = clampf(1.0 - golpe / _DUR_GOLPE, 0.0, 0.999)
	if t < 0.3:
		return 2
	if t < 0.6:
		return 3
	return 4

## Dicionário de inteiros da pose, mais "a" = posição real de cada âncora de roupa (na ordem de RoupaGato.Onde). A de cabeça fica no
## alto do crânio: capacete da toupeira e coroa do texugo saem quando há chapéu.
static func _geo(ct: int, anim: float, andando: bool, golpe: float, parado: bool) -> Dictionary:
	var q: int = 0
	var bob: int = 0
	var resp: int = 0
	var ph: int = _fase(golpe)
	if ph == 0 and BichoPx.dor and ct != 7 and not parado:
		ph = 1   # dor: a pose recolhida (cabeça para trás) do preparo, com o olho apertado
	var tk: int = Time.get_ticks_msec()
	if andando:
		q = posmod(int(anim * _PASSO), 6)
		bob = -1 if q % 3 == 1 else 0
	elif ph == 0:
		resp = (int(tk / 650) + int(anim * 7.0)) % 2
	var g: Dictionary = {"ct": ct, "q": q, "ph": ph, "bob": bob, "resp": resp, "andando": andando, "parado": parado, "ext": 0, "ol": BichoPx.modo_olho(), "av": 0, "lag": 0}
	match ct:
		5:
			_geo5(g, tk)
		6:
			_geo6(g, tk)
		7:
			_geo7(g, tk)
		8:
			_geo8(g, tk)
		_:
			_geo9(g, tk)
	return g

static func _chave(g: Dictionary) -> String:
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [g["ct"], g["q"], g["ph"], g["bob"], g["resp"], int(g["andando"]), int(g["parado"]), g["ext"], int(BichoPx.cabeca_coberta) * 2 + int(BichoPx.corpo_coberto), g["ol"]]

## Molde do tronco e largura do crânio do quadro em montagem (cada _monta* grava aqui): as roupas de corpo e o chapéu se ajustam.
static var _tr: PackedInt32Array = PackedInt32Array()
static var _cr: int = 0

static func desloc(onde: int, familia: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Vector2:
	var ct: int = clampi(chefe_tipo, 5, 9)
	var g: Dictionary = _geo(ct, anim, andando, golpe, parado)
	var a: Array = g["a"]
	if onde == RoupaGato.Onde.PATAS:
		return g["patas"]
	var p: Vector2 = a[onde] - RoupaGato.ORIGEM[onde]
	return Vector2(roundf(p.x), roundf(p.y))

static func desenhar(c: CanvasItem, familia: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var ct: int = clampi(chefe_tipo, 5, 9)
	var g: Dictionary = _geo(ct, anim, andando, golpe, parado)
	var k: String = _chave(g)
	if not _cache.has(k):
		_cache[k] = _monta(g)
	var s: Dictionary = _cache[k]
	BichoPx.ultimo_quadro = s   # as roupas leem o molde deste quadro sem refazer a pose
	BichoPx.sprite(c, s, _pal(ct, alfa), f)

## Quadro em cache do chefe nesta pose (sprite "l", molde do tronco "t", crânio "c"), para as roupas acompanharem o desenho.
static func quadro(chefe_tipo: int, anim: float, andando: bool, golpe: float, parado: bool) -> Dictionary:
	var g: Dictionary = _geo(clampi(chefe_tipo, 5, 9), anim, andando, golpe, parado)
	var k: String = _chave(g)
	if not _cache.has(k):
		_cache[k] = _monta(g)
	return _cache[k]

static func _monta(g: Dictionary) -> Dictionary:
	var G := _nova()
	_tr = _nova()
	_cr = 0
	match int(g["ct"]):
		5:
			if g["parado"]:
				_monta5_monte(G, g)
			else:
				_monta5(G, g)
		6:
			_monta6(G, g)
		7:
			_monta7(G, g)
		8:
			_monta8(G, g)
		_:
			_monta9(G, g)
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
	return {"x": x0 - _OX, "y": y0 - _OY, "l": lin, "t": BichoPx.recorte(_tr, _W, _H, _OX, _OY), "c": _cr, "cobre": 0.5}

# ================================================================ 5 TOUPEIRA ESCAVADORA
const _HELM: Array = [
	"...hhhhhh.....",
	".hhYYYYYYY....",
	"hYYYYYYYYYY...",
	"YYYYYYYYYYYYY.",
	"YYYYYYYYYYYYYY",
	"yyyyyyyyyyyyyy",
]
const _LAMPADA: Array = [
	"GGGG",
	"gWWg",
	"gWWg",
	"GGGG",
]
## Corpo de veludo em gota, sem pescoço: a frente afina e vira a cabeça (o capacete fica nela).
const _TP_CORPO: Array = [
	"......lllllll.................",
	"...lllllllllllll..............",
	".llllmmmmmmmmllllllllll.......",
	"llmmmmmmmmmmmmmmmmlllllllll...",
	"lmmmmmmmmmmmmmmmmmmmmmmmmlll..",
	"mmmmmmmmmmmmmmmmmmmmmmmmmmmll.",
	"mmmmmmmmmmmmmmmmmmmmmmmmmmmmm.",
	"mmmmmmmmmmmmmmmmmmmmmmmmmmmmm.",
	"dmmmmmmmmmmmmmmmmmmmmmmmmmmmd.",
	"ddmmmmmmmmmmmmmmmmmmmmmmmmdd..",
	".dddmmmmmmmmmmmmmmmmmmmmdd....",
	"..ddddddddddddddddddddddd.....",
	"....dddddddddddddddddd........",
]
## Focinho rosa comprido e pontudo, com os tentáculos da estrela na ponta.
const _TP_FOCINHO: Array = [
	"PPPPp.......",
	"PPPPPPPp.P..",
	"PPPPPPPPPPP.",
	"PPPPPPPPPPPP",
	"pppppppppPP.",
	".QQQQQQQ.P..",
]
## Mãos de cavar enormes, em pá, com três garras compridas (a de longe mais escura).
const _TP_MAO: Array = [".PPPPPP.", "PPPPPPPP", "PPPPPPPp", "pPPPPPpp", ".pppppp.", "..pQQQ.."]
const _TP_MAO_L: Array = ["..ppppp.", ".ppppppp", "pppppppQ", "ppppppQQ", ".pQQQQQ."]
const _TP_GARRAS: Array = ["cccC", "....", "ccccC", "....", "cccC"]
const _TP_GARRAS_L: Array = ["sss", "...", "ssss", "...", "sss"]
const _TP_PE: Array = [".PPPP", "PPPPPp"]
const _TP_PE_L: Array = [".pppp", "ppppQQ"]

static func _geo5(g: Dictionary, tk: int) -> void:
	var q: int = g["q"]
	var ph: int = g["ph"]
	var av: int = [0, -1, 3, 2, 1][ph] if not g["parado"] else 0   # bote: o corpo inteiro avança (preparo recua)
	var bx: int = -16 + av
	var by0: int = -14 + int(g["bob"]) - int(g["resp"])
	var ax: int = 0
	var ay: int = 0
	if ph > 0:
		ax = [0, -2, 4, 5, 2][ph]
		ay = [0, -4, -1, 0, 0][ph]
	elif g["andando"]:
		ax = [-1, 1, 2, 2, 0, -1][q]
		ay = [0, -1, -1, -1, 0, 0][q]
	g["e"] = ax
	g["bx"] = bx
	g["by0"] = by0
	g["ax"] = ax
	g["ay"] = ay
	g["dente"] = ph == 2 or ph == 3
	g["av"] = av
	g["lag"] = 2 if ph == 2 else (1 if ph == 3 else 0)   # o capacete chega atrasado
	g["cx0"] = bx + 14 - int(g["lag"])
	g["cy0"] = by0 - 4 - (1 if ph == 2 else 0)
	if g["parado"]:
		g["ext"] = (tk / 140) % 4
		g["cx0"] = -8
		g["cy0"] = -20
		g["a"] = [Vector2(0, -14), Vector2(0, -8), Vector2(10, -11), Vector2(-8, -9), Vector2(0, -11), Vector2(0, 0), Vector2(1, -14)]
		g["patas"] = Vector2(0, 5000)
		return
	g["a"] = [Vector2(bx + 21, by0 + 1), Vector2(bx + 12, by0 + 6), Vector2(bx + 38, by0 + 7), Vector2(bx + 2, by0 + 4),
		Vector2(bx + 23, by0 + 9), Vector2(bx + 25, by0 + 4), Vector2(bx + 25, by0 + 3)]
	g["patas"] = Vector2(-3, 0)

## sobrepõe o efeito a tudo (inclusive ao contorno e ao corpo)
static func _luz_forte(G: PackedInt32Array, L: PackedInt32Array) -> void:
	for k in L.size():
		if L[k] != 0:
			G[k] = L[k]

static func _feixe(G: PackedInt32Array, lx: int, ly: int, n: int) -> void:
	var F := _nova()
	for dx in n:
		var meio: float = 1.0 + float(dx) * 0.4
		var cy: int = ly + roundi(float(dx) * 0.15)
		for dy in range(-ceili(meio), ceili(meio) + 1):
			_px(F, lx + dx, cy + dy, "j" if absf(float(dy)) <= meio * 0.55 else "J")
	_luz(G, F)

## capacete de mineiro com a lanterna (sai quando a toupeira veste chapéu)
static func _capacete5(G: PackedInt32Array, cx0: int, cy0: int) -> void:
	var C := _nova()
	_bmp(C, cx0, cy0, _HELM)
	_rect(C, cx0 + 5, cy0 + 1, 1, 4, "y")
	_bmp(C, cx0 + 11, cy0 + 1, _LAMPADA)
	_px(C, cx0 + 2, cy0 + 3, "h")
	_comp(G, C)

static func _monta5(G: PackedInt32Array, g: Dictionary) -> void:
	var q: int = g["q"]
	var ph: int = g["ph"]
	var bx: int = g["bx"]
	var by0: int = g["by0"]
	var ax: int = g["ax"]
	var ay: int = g["ay"]
	var pe: Array = [0, 2, 0, -2, 0, 1]
	var lv: Array = [0, 0, 1, 1, 0, 0]
	var fl: int = 0
	var nl: int = 0
	var fu: int = 0
	var nu: int = 0
	if g["andando"]:
		fl = int(pe[(q + 3) % 6])
		nl = int(pe[q])
		fu = int(lv[(q + 3) % 6])
		nu = int(lv[q])
	# rabinho, pé e mão de longe (com as garras dela)
	var R := _nova()
	_bmp(R, bx - 2, by0 + 7, ["pp", "Qp"])
	_comp(G, R)
	var L1 := _nova()
	_bmp(L1, bx + 5 + fl, by0 + 12 - fu, _TP_PE_L)
	_comp(G, L1)
	var fax: int = -ax / 2 if ph == 0 else 0
	var A := _nova()
	_bmp(A, bx + 24 + fax, by0 + 9, _TP_MAO_L)
	_comp(G, A)
	var AG := _nova()
	_bmp(AG, bx + 31 + fax, by0 + 9, _TP_GARRAS_L)
	_comp(G, AG)
	# corpo; o molde do tronco é o corpo sem a cabeça (a roupa não cobre a cara)
	var B := _nova()
	_bmp(B, bx, by0, _TP_CORPO)
	_tr = B.duplicate()
	for j in 13:
		for i in range(21, 30):
			_tr[(by0 + j + _OY) * _W + bx + i + _OX] = 0
	_cr = 12
	_comp(G, B)
	# olhinho minúsculo com brilho, logo abaixo da aba do capacete
	var O := _nova()
	_bmp(O, bx + 24, by0 + 3, [["ll", "kw"], ["ll", "kk"], ["kl", "lk"]][int(g["ol"])])   # aberto, apertado, X
	_luz_forte(G, O)
	# focinho em camada própria; boca com dentinhos no bote
	var F := _nova()
	_bmp(F, bx + 27, by0 + 3, _TP_FOCINHO)
	if g["dente"]:
		_rect(F, bx + 29, by0 + 8, 4, 1, "q")
		_px(F, bx + 30, by0 + 7, "w")
		_px(F, bx + 32, by0 + 7, "w")
	_comp(G, F)
	# pé de perto
	var L2 := _nova()
	_bmp(L2, bx + 2 + nl, by0 + 12 - nu, _TP_PE)
	_comp(G, L2)
	# capacete
	var cx0: int = g["cx0"]
	var cy0: int = g["cy0"]
	if not BichoPx.cabeca_coberta:
		_capacete5(G, cx0, cy0)
	# mão de perto com as garras (remando no passo, arranhando no golpe)
	var D := _nova()
	_bmp(D, bx + 21 + ax, by0 + 8 + ay, _TP_MAO)
	_comp(G, D)
	var DG := _nova()
	var abre: int = 1 if ph == 2 or ph == 3 else 0
	_bmp(DG, bx + 28 + ax + abre, by0 + 8 + ay, _TP_GARRAS)
	_comp(G, DG)
	if not BichoPx.cabeca_coberta:
		_feixe(G, cx0 + 15, cy0 + 2, 12)
	if ph == 2 or ph == 3:
		var X := _nova()
		var hxm: int = bx + 30 + ax
		var hym: int = by0 + 11 + ay
		_trazo(X, hxm - 3, hym - 12, hxm + 6, hym - 7, 1, "x")
		_trazo(X, hxm + 6, hym - 7, hxm + 10, hym + 1, 1, "x")
		_luz(G, X)
	if ph == 3:
		var Tt := _nova()
		_rect(Tt, bx + 38 + ax, by0 + 12, 2, 1, "T")
		_rect(Tt, bx + 41 + ax, by0 + 11, 2, 1, "t")
		_luz(G, Tt)

static func _monta5_monte(G: PackedInt32Array, g: Dictionary) -> void:
	var f: int = g["ext"]
	var up: int = 1 if (f == 1 or f == 2) else 0
	# cabeça espiando do monte: veludo, olhinho e o focinho rosa
	var B := _nova()
	_elip(B, -6, -17 - up, 13, 11)
	_bmp(B, 1, -14 - up, ["ll", "kw"])
	_comp(G, B)
	var Fo := _nova()
	_bmp(Fo, 5, -14 - up, ["PPPp...", "PPPPPPP", "ppppPPP", ".QQQ.P."])
	_comp(G, Fo)
	var cx0: int = -8
	var cy0: int = -22 - up
	if not BichoPx.cabeca_coberta:
		_capacete5(G, cx0, cy0)
	if f == 1 or f == 3:
		var A := _nova()
		var ya: int = -10 - (3 if f == 1 else 0)
		_bmp(A, -22, ya - 2, ["..PPPP", ".PPPPP", "PPPPPP", "pPPPpp", ".pppp."])
		_comp(G, A)
		var AG := _nova()
		_bmp(AG, -25, ya - 2, ["Cccc", "....", "Ccccc", "....", "Cccc"])
		_comp(G, AG)
	var M := _nova()
	_elip(M, -18, -10, 36, 20, "u", "T", "t")
	_comp(G, _corta(M))
	var Pt := _nova()
	for t in [Vector2(-12, -6), Vector2(-5, -3), Vector2(6, -7), Vector2(11, -4), Vector2(14, -2), Vector2(-15, -2), Vector2(2, -4)]:
		_rect(Pt, int(t.x), int(t.y), 3, 1, "t")
		_px(Pt, int(t.x) + 1, int(t.y) - 1, "u")
	_luz_sobre(G, Pt)
	var V := _nova()
	var vv: Array = [[-16, -14, -20, -9], [-14, -19, -17, -12], [17, -13, 21, -8], [15, -17, 18, -11]]
	for i in vv.size():
		var s: Array = vv[i]
		var k: int = (f + i) % 4
		var yy: int = int(s[1]) + (3 if k < 2 else 0) - (k % 2) * 2
		var xx: int = int(s[0]) + (0 if k < 2 else (int(s[2]) - int(s[0])) / 3)
		_rect(V, xx, yy, 2, 2, "T")
		_px(V, xx, yy, "u")
	_comp(G, V)
	if not BichoPx.cabeca_coberta:
		_feixe(G, cx0 + 15, cy0 + 2, 11)

## apaga o que está abaixo do chão (y >= 0) numa camada
static func _corta(L: PackedInt32Array) -> PackedInt32Array:
	for j in range(_OY, _H):
		for i in _W:
			L[j * _W + i] = 0
	return L

## detalhes por cima de pixels que já existem
static func _luz_sobre(G: PackedInt32Array, L: PackedInt32Array) -> void:
	for k in L.size():
		if L[k] != 0 and G[k] != 0 and G[k] != 111:
			G[k] = L[k]

# ================================================================ 6 GAMBÁ FEDIDO
static func _geo6(g: Dictionary, tk: int) -> void:
	var q: int = g["q"]
	var ph: int = g["ph"]
	var e: int = [0, -1, 3, 2, 1][ph]
	var bx: int = -9
	var bw: int = 21
	var bh: int = 10
	var by0: int = -15 + int(g["bob"]) - int(g["resp"])
	bh += int(g["resp"])
	var hx: int = 6 + e
	var hy: int = by0 - 2 + (1 if ph == 1 else 0)
	var sway: int = [0, 1, 2, 1, 0, -1][q] if g["andando"] else (-4 if (ph == 2 or ph == 3) else (3 if ph == 1 else 0))
	g["e"] = e
	g["bx"] = bx
	g["bw"] = bw
	g["bh"] = bh
	g["by0"] = by0
	g["hx"] = hx
	g["hy"] = hy
	g["sway"] = sway
	g["boca"] = ph == 2 or ph == 3
	g["ext"] = (tk / 150) % 6
	g["a"] = [Vector2(hx + 6, hy - 3), Vector2(bx + bw * 0.5, by0 + bh * 0.5), Vector2(hx + 15, hy + 5), Vector2(bx + 3, by0 + 1),
		Vector2(hx + 3, hy + 8), Vector2(hx + 10, hy + 4), Vector2(hx + 9, hy + 3)]
	g["patas"] = Vector2(0, 0)

## Rabo enorme erguido: discos de raio variável ao longo de uma curva em S (negro nas bordas, listra branca no miolo, ponta branca).
static func _rabo6(L: PackedInt32Array, g: Dictionary) -> void:
	var rx: int = int(g["bx"]) + 3
	var ry: int = int(g["by0"]) + 5
	var alt: int = 23
	var sway: int = g["sway"]
	var n: int = alt * 2
	var centros: Array = []
	for i in n + 1:
		var t: float = float(i) / float(n)
		var cx: int = rx - roundi(8.0 * sin(t * PI * 0.8)) + roundi(float(sway) * t * t)
		var cy: int = ry - roundi(t * float(alt))
		var r: float = 2.0 + 5.2 * sin(PI * pow(t, 0.72)) * (1.0 - 0.15 * t)
		centros.append([cx, cy, r, t, i])
	for cc in centros:
		var r2: int = roundi(float(cc[2])) + (1 if (int(cc[4]) * 7) % 5 == 0 and float(cc[3]) > 0.2 else 0)
		for dy in range(-r2, r2 + 1):
			for dx in range(-r2, r2 + 1):
				if dx * dx + dy * dy > r2 * r2 + r2:
					continue
				var ch: String = "m"
				if dx < -r2 * 0.35:
					ch = "l"
				elif dx > r2 * 0.35:
					ch = "d"
				_px(L, int(cc[0]) + dx, int(cc[1]) + dy, ch)
	for cc in centros:
		var t: float = cc[3]
		if t < 0.1:
			continue
		var rw: int = roundi(float(cc[2]) * (0.92 if t > 0.86 else 0.5))
		if rw < 1:
			continue
		for dy in range(-rw, rw + 1):
			for dx in range(-rw, rw + 1):
				if dx * dx + dy * dy > rw * rw + rw:
					continue
				_px(L, int(cc[0]) + dx + 1, int(cc[1]) + dy, "v" if dx > rw * 0.3 else "w")

## Fedor: fiapos ondulantes e bolhas verdes subindo (sem contorno), um quadro por fase do relógio.
static func _fedor(G: PackedInt32Array, g: Dictionary, forte: bool) -> void:
	var f: int = g["ext"]
	var Z := _nova()
	var by0: int = g["by0"]
	var bases: Array = [-19, -12, -5, 2, 9, 16]
	for i in bases.size():
		var ph: float = fposmod(float(f) / 6.0 + float(i) / 6.0, 1.0)
		var y: int = by0 - 6 - roundi(ph * 34.0) - (i % 2) * 3
		var x: int = int(bases[i]) + roundi(2.0 * sin(ph * 6.0 + float(i) * 1.7))
		var ch: String = "z" if ph < 0.4 else ("Z" if ph < 0.75 else "x")
		var s: int = 3 if ph < 0.7 else 2
		_rect(Z, x, y, s, s - 1 if s == 3 else 2, ch)
		if ph < 0.55:
			_px(Z, x + 1, y - 1, ch)
		# fiapo ondulado atrás da bolha
		for k in 5:
			_px(Z, x + roundi(1.5 * sin(float(k) * 1.3 + float(f))), y + 3 + k, "Z" if ph < 0.75 else "x")
	if forte:
		var ty: int = by0 - 24
		_elip(Z, -20, ty - 6, 11, 8, "z", "z", "Z")
		_elip(Z, -13, ty - 12, 9, 7, "z", "Z", "Z")
		_elip(Z, -23, ty, 8, 6, "Z", "Z", "x")
	# névoa rasteira junto das patas
	for k in 6:
		var x: int = -16 + k * 6 + (f % 2) * 2
		_rect(Z, x, -3 - (k + f) % 2, 5, 2, "x")
	_luz(G, Z)

static func _monta6(G: PackedInt32Array, g: Dictionary) -> void:
	var bx: int = g["bx"]
	var bw: int = g["bw"]
	var bh: int = g["bh"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var ph: int = g["ph"]
	# rabo
	var R := _nova()
	_rabo6(R, g)
	_comp(G, R)
	# patas
	var L1 := _nova()
	var L2 := _nova()
	var hip: int = by0 + bh - 3
	_pernas(L1, L2, g, 4, -7, hip, 3, "d", "d", "d", 4)
	_comp(G, L1)
	_comp(G, L2)
	# orelha de longe
	var OL := _nova()
	_bmp(OL, hx + 6, hy - 3, ["dd..", "dddd", "dddd"])
	_comp(G, OL)
	# corpo + pescoço + cabeça + orelha de perto
	var B := _nova()
	_elip(B, bx, by0, bw, bh)
	_tr = B.duplicate()
	_cr = BichoPx.cranio(_CAB["G"]["rows"])
	_elip(B, hx - 3, hy + 3, 9, 9)
	var cab: Array = _cab_rows(_CAB["G"], g["boca"])
	_bmp(B, hx, hy, cab)
	_faixa_topo(B, bx + 5, bx + bw - 5, 3, "w", "v")
	_bmp(B, hx + 2, hy - 3, [".mm.", "mlem", "mmmm"])
	# olho grande amarelo com pupila e brilho; sobrancelha pesada
	var ex: int = hx + int(_CAB["G"]["ex"])
	var ey: int = hy + int(_CAB["G"]["ey"])
	_rect(B, ex - 1, ey, 5, 4, "y")
	_rect(B, ex + 1, ey + 1, 3, 3, "k")
	_px(B, ex - 1, ey, "w")
	_px(B, ex, ey, "w")
	_rect(B, ex - 1, ey + 3, 5, 1, "Y")
	_rect(B, ex + 1, ey + 3, 3, 1, "k")
	_trazo(B, ex - 2, ey - 2 + (0 if ph == 0 else 1), ex + 4, ey - 1 + (1 if ph == 0 else 2), 1, "k")
	BichoPx.manter_iguais(_tr, B, _W)   # cabeça, marcas e barriga ficam por cima da roupa de corpo
	_comp(G, B)
	_fedor(G, g, ph == 2 or ph == 3)

# ================================================================ 7 ESQUILO ACROBATA (Fases.Chefe.CORUJA)
## Cabeça de perfil: crânio redondo, olho grande, focinho curto com o nariz na ponta, bochecha e queixo cremes.
const _ES_CAB: Array = [
	"....mmmmm.....",
	"..mmlllllmm...",
	".mlllllllllm..",
	"mllllllkkllm..",
	"mlllllkwkkllv.",
	"mllllllkkvvvvn",
	"mmlllllvvvvvvn",
	"dmmmllvvvvvvv.",
	".dmmmvvvvvvv..",
	"..ddVVVVVV....",
]
const _ES_CAB_INFO: Dictionary = {"js": 7, "ms": 8, "ab": 2, "ex": 7, "ey": 4}
## Orelha de perto em ponta com o tufo escuro; a de longe só aparece atrás do crânio.
const _ES_ORELHA: Array = ["D....", "DD...", "DDm..", "mpm..", "mppm.", "lmmm."]
const _ES_ORELHA_L: Array = ["D..", "DD.", "dd.", "ddd"]
## Corpo curto e arqueado, anca alta, peito creme subindo para o pescoço.
const _ES_CORPO: Array = [
	"......llllll........",
	"...lllllllllll......",
	"..lllmmmmmmmllll....",
	".llmmmmmmmmmmmmlvv..",
	"llmmmmmmmmmmmmmmvvv.",
	"lmmmmmmmmmmmmmmmvvvv",
	"mmmmmmmmmmmmmmmmvvvv",
	"mmmmmmmmmmmmmmmvvvvv",
	"dmmmmmmmmmmmmmmvvvv.",
	"ddmmmmmmmmmmmmvvvv..",
	".dddmmmmmmmmdVVV....",
	"...dddddddddd.......",
]
## Coxa redonda de perto (o esquilo carrega o peso na anca).
const _ES_COXA: Array = ["..mmm..", ".mmmmm.", "mmmmmmm", "mmmmmmm", ".mmmmm.", "..mmm.."]
## Rabão felpudo em ponto de interrogação: sobe atrás da anca e faz a curva por cima das costas.
const _ES_RABO: Array = [
	"........tttttt......",
	"......ttTTTTTTtt....",
	"....ttTTTTTTTTTTtt..",
	"...tTTTTTuuuuTTTTTt.",
	"..tTTTTuu....uuTTTTt",
	".ttTTTu.......uTTTTt",
	".tTTTu........tTTTTt",
	"tTTTTu.........tTTt.",
	"ttTTTu..........tt..",
	"tTTTTu..............",
	"tTTTTTu.............",
	"ttTTTTu.............",
	".tTTTTTu............",
	".tTTTTTu............",
	"..ttTTTTu...........",
	"..tTTTTTTu..........",
	"...tTTTTTTu.........",
	"....ttTTTTTu........",
	".....ttTTTTTu.......",
	".......tTTTTT.......",
	"........ttTT........",
]
## Faixa de acrobata no peito, com estrela de ouro (sai quando o esquilo veste roupa de corpo).
const _ES_FAIXA: Array = ["....RRR", "...RRGR", "..RRRr.", ".RRRr..", "RRRr...", "RRr....", "Rr....."]
## Bolota que ele arremessa.
const _ES_NOZ: Array = [".ss.", "SSSS", "aaaa", "aAaa", ".aA."]

static func _geo7(g: Dictionary, tk: int) -> void:
	var q: int = g["q"]
	var ph: int = g["ph"]
	var e: int = [0, -2, 3, 2, 1][ph]
	var hop: int = [0, -1, -3, -3, -1, 0][q] if g["andando"] else 0   # anda aos pulinhos
	var bx: int = -12
	var by0: int = -17 + hop - int(g["resp"])
	var hx: int = bx + 15 + e
	var hy: int = by0 - 6 + (1 if ph == 1 else 0)
	g["e"] = e
	g["hop"] = hop
	g["bx"] = bx
	g["by0"] = by0
	g["hx"] = hx
	g["hy"] = hy
	g["boca"] = ph == 2 or ph == 3
	var piscar: bool = (tk / 190) % 17 == 9
	var balanco: int = (tk / 420) % 2   # o rabo balança parado
	g["ext"] = (1 if piscar else 0) + 2 * balanco
	g["a"] = [Vector2(hx + 5, hy + 1), Vector2(bx + 9, by0 + 6), Vector2(hx + 13, hy + 6), Vector2(bx + 1, by0 + 3),
		Vector2(hx + 3, hy + 9), Vector2(hx + 8, hy + 5), Vector2(hx + 8, hy + 4)]
	g["patas"] = Vector2(0, hop)

static func _monta7(G: PackedInt32Array, g: Dictionary) -> void:
	var q: int = g["q"]
	var ph: int = g["ph"]
	var hop: int = g["hop"]
	var bx: int = g["bx"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var andando: bool = g["andando"]
	var ext: int = g["ext"]
	# rabão: acompanha o pulo e balança
	var sway: int = ([0, 1, 1, 0, -1, -1][q] if andando else (ext / 2)) + (-1 if ph == 1 else (1 if ph == 2 else 0))
	var R := _nova()
	_bmp(R, bx - 9 + sway, by0 - 16, _ES_RABO)
	_comp(G, R)
	# patas: as de longe (mais escuras) atrás do corpo; no ar, as patas se juntam
	var L1 := _nova()
	var L2 := _nova()
	var defs: Array = [[bx + 4, 0.5, L1, "d"], [bx + 16, 0.0, L1, "d"], [bx + 1, 0.0, L2, "m"], [bx + 13, 0.5, L2, "m"]]
	for k in defs.size():
		var d: Array = defs[k]
		var x: int = d[0]
		var xf: int = x
		var yf: int = -1 + hop
		if andando:
			var phs: float = fposmod(float(q) / 6.0 + float(d[1]), 1.0)
			xf = x + roundi(2.0 * cos(TAU * phs)) * (0 if hop < -1 else 1)
			yf = -1 + hop - maxi(0, roundi(1.5 * sin(TAU * phs)))
		if k == 3 and ph > 0:
			continue   # a pata da frente de perto é o braço do arremesso
		var top: int = by0 + (7 if k == 2 else 10)
		_pata(d[2], x, top, xf, yf, 2, d[3], "D", 1)
		if k == 2:
			_rect(d[2], xf + 3, yf, 2, 1, "D")   # pé comprido de esquilo
	_comp(G, L1)
	# orelha de longe (some sob o chapéu)
	if not BichoPx.cabeca_coberta:
		var OL := _nova()
		_bmp(OL, hx + 3, hy - 4, _ES_ORELHA_L)
		_comp(G, OL)
	# corpo (o molde do tronco é ele inteiro), coxa e patas de perto
	var B := _nova()
	_bmp(B, bx, by0, _ES_CORPO)
	_bmp(B, bx - 1, by0 + 7, _ES_COXA)
	_tr = B.duplicate()
	_comp(G, B)
	_comp(G, L2)
	# faixa de acrobata
	if not BichoPx.corpo_coberto:
		var Fa := _nova()
		_bmp(Fa, bx + 13, by0 + 1, _ES_FAIXA)
		_comp(G, Fa)
	# braço do arremesso (antes da cabeça): ergue a bolota por trás da cabeça, depois estica para a frente sob o queixo
	if ph > 0:
		var Ar := _nova()
		var sx: int = bx + 15
		var sy: int = by0 + 5
		var px: int = [0, hx - 2, hx + 11, hx + 10, hx + 7][ph]
		var py: int = [0, hy, hy + 13, hy + 13, hy + 14][ph]
		_trazo(Ar, sx, sy, px, py, 2, "l")
		_rect(Ar, px, py, 3, 2, "D")
		_comp(G, Ar)
		if ph == 1:
			var Nz := _nova()
			_bmp(Nz, px - 3, py - 4, _ES_NOZ)
			_comp(G, Nz)
	# cabeça em camada própria (boca aberta no arremesso), incisivos e olho piscando
	var H := _nova()
	var cb: Dictionary = _ES_CAB_INFO.duplicate()
	cb["rows"] = _ES_CAB
	var cab: Array = _cab_rows(cb, g["boca"])
	_bmp(H, hx, hy, cab)
	_cr = BichoPx.cranio(_ES_CAB)
	if ext % 2 == 1:
		_rect(H, hx + 6, hy + 3, 4, 3, "l")
		_rect(H, hx + 6, hy + 4, 4, 1, "k")
	BichoPx.tirar(_tr, _W, _H, hx + _OX, hy + _OY, cab)
	_comp(G, H)
	var Dt := _nova()
	_bmp(Dt, hx + 11, hy + 8 + (2 if g["boca"] else 0), ["ww", "ww"])
	_comp(G, Dt)
	# orelha de perto com o tufo
	if not BichoPx.cabeca_coberta:
		var OP := _nova()
		_bmp(OP, hx + 1, hy - 6 - (1 if ph == 1 else 0), _ES_ORELHA)
		_comp(G, OP)

# ================================================================ 8 VIRA-LATA CHEFÃO
## Cabeça de perfil: crânio redondo, focinho comprido e mais baixo com o nariz preto na ponta, bochecha e queixo cremes.
const _VL_CAB: Array = [
	"...mmmmm..........",
	"..mlllllmm........",
	".mllllllllm.......",
	"mlllllllllmm......",
	"mllllllkklllm.....",
	"mlllllkwklllvvvvnn",
	"mmllllllllvvvvvvnn",
	"mmmlllllvvvvvvvvv.",
	"dmmmmmvvvvvvvvvv..",
	".dmmmvvvvvvvvvv...",
	"..ddVVVVVVVVV.....",
	"....VVVVVV........",
]
const _VL_CAB_INFO: Dictionary = {"js": 8, "ms": 8, "ab": 2, "ex": 6, "ey": 4}
## Orelha de perto, caída por trás do olho, com a ponta rasgada; a de longe só aparece a ponta atrás do crânio.
const _VL_ORELHA: Array = ["eee..", "eEee.", "eEeee", "eEeee", "eEeee", ".eEee", ".eEe.", "..ee."]
const _VL_ORELHA_L: Array = ["EE.", "EEE", ".EE"]
## Corpo comprido com tufos no lombo, mancha escura de vira-lata na anca, peito creme subindo pelo pescoço.
const _VL_CORPO: Array = [
	"..................mmmm....",
	".................mmmmmv...",
	".......l..l.l...mmmmmvv...",
	"......llllllllllmmmmmvvv..",
	"...llllllllllllllmmmvvvvv.",
	".lllmmlllllllllllllmvvvvvv",
	"lllmmmmmmmllllllllllvvvvvv",
	"llmmeeeemmmmmmmmmmmmvvvvvv",
	"lmmeeeeeemmmmmmmmmmmvvvvvv",
	"mmmmeeeemmmmmmmmmmmmmvvvvv",
	"mmmmmmmmmmmmmmmmmmmmmvvvv.",
	"dmmmmmmmmmmmmmmmmmmmmmvv..",
	".ddmmmmmmmmmmmmmmmmmmmd...",
	"...ddddVVVVVVVVVVVVddd....",
]
const _VL_RABO: Array = ["...ll", "..lml", ".lmm.", "lmm..", "mm...", "m...."]
const _VL_RABO_CAIDO: Array = ["m....", "mm...", ".mm..", ".mm..", "..mm.", "..ll.", "..ll."]

static func _geo8(g: Dictionary, tk: int) -> void:
	var ph: int = g["ph"]
	var parado: bool = g["parado"]
	var e: int = [0, -2, 3, 2, 1][ph]
	var ofeg: int = (tk / 120) % 2 if parado else 0
	var bx: int = -15
	var bw: int = 26
	var bh: int = 14
	var by0: int = -20 + int(g["bob"]) - int(g["resp"]) + (1 if parado else 0)
	var hx: int = bx + 18 + e
	var hy: int = by0 - 5 + (4 if parado else 0) + (1 if ph == 1 else 0) + ofeg
	g["e"] = e
	g["bx"] = bx
	g["bw"] = bw
	g["bh"] = bh
	g["by0"] = by0
	g["hx"] = hx
	g["hy"] = hy
	g["ofeg"] = ofeg
	g["ext"] = ofeg
	g["boca"] = ph == 2 or ph == 3 or parado
	g["a"] = [Vector2(hx + 6, hy + 1), Vector2(bx + 12, by0 + 8), Vector2(hx + 17, hy + 6), Vector2(bx + 2, by0 + 5),
		Vector2(hx + 4, hy + 9), Vector2(hx + 8, hy + 5), Vector2(hx + 8, hy + 4)]
	g["patas"] = Vector2(1, 0)

static func _monta8(G: PackedInt32Array, g: Dictionary) -> void:
	var q: int = g["q"]
	var ph: int = g["ph"]
	var parado: bool = g["parado"]
	var bx: int = g["bx"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var ofeg: int = g["ofeg"]
	# rabo: erguido e abanando; caído quando sem fôlego
	var R := _nova()
	if parado:
		_bmp(R, bx - 3, by0 + 6, _VL_RABO_CAIDO)
	else:
		var wag: int = [0, 1, 0, -1, 0, 1][q] if g["andando"] else 0
		if ph == 1 or ph == 2:
			wag = 1
		_bmp(R, bx - 3 + wag, by0 + 0 - absi(wag), _VL_RABO)
	_comp(G, R)
	# patas de longe, orelha de longe
	var L1 := _nova()
	var L2 := _nova()
	var hip: int = by0 + 11
	_pernas(L1, L2, g, bx + 17, bx + 1, hip, 4, "d", "m", "v", 2)
	_comp(G, L1)
	var OL := _nova()
	_bmp(OL, hx + 2, hy - 1 - (1 if ph == 2 or ph == 3 else 0), _VL_ORELHA_L)
	_comp(G, OL)
	# corpo (o molde do tronco é ele inteiro) e patas de perto
	var B := _nova()
	_bmp(B, bx, by0, _VL_CORPO)
	_tr = B.duplicate()
	for i in 16:   # os tufos do lombo ficam fora do molde: a roupa tem a borda lisa
		_tr[(by0 + 2 + _OY) * _W + bx + i + _OX] = 0
	_comp(G, B)
	_comp(G, L2)
	# cabeça em camada própria, boca aberta no golpe e sem fôlego
	var H := _nova()
	var cb: Dictionary = _VL_CAB_INFO.duplicate()
	cb["rows"] = _VL_CAB
	var cab: Array = _cab_rows(cb, g["boca"])
	_bmp(H, hx, hy, cab)
	_cr = BichoPx.cranio(_VL_CAB)
	# cenho fechado e cicatriz no focinho (chefão de rua)
	_px(H, hx + 6, hy + 3, "E")
	_px(H, hx + 7, hy + 3, "E")
	_px(H, hx + 8, hy + 3 + (1 if parado else 0), "E")
	_px(H, hx + 10, hy + 3, "a")
	_px(H, hx + 11, hy + 4, "a")
	_px(H, hx + 11, hy + 5, "a")
	if parado:
		_px(H, hx + 7, hy + 5, "k")   # olho cansado, meio fechado
		var lg: int = 4 + ofeg
		_rect(H, hx + 10, hy + 10, 3, lg, "T")
		_rect(H, hx + 10, hy + 10 + lg - 1, 3, 1, "t")
		_px(H, hx + 11, hy + 10, "t")
	BichoPx.tirar(_tr, _W, _H, hx + _OX, hy + _OY, cab)
	_comp(G, H)
	# orelha de perto, caída por trás do olho (sobe um pouco no bote)
	var OP := _nova()
	_bmp(OP, hx - (1 if ph == 2 or ph == 3 else 0), hy + 1 - (1 if ph == 2 or ph == 3 else 0), _VL_ORELHA)
	_comp(G, OP)
	# coleira escura com rebites no pescoço
	var Co := _nova()
	_bmp(Co, hx + 3, hy + 8, ["CC", "SC", "CC", "CS", "CC"])
	_comp(G, Co)
	if parado:
		var Su := _nova()
		_rect(Su, hx + 5, hy - 3 - ofeg, 1, 2, "B")
		_px(Su, hx + 5, hy - 4 - ofeg, "w")
		_luz(G, Su)

# ================================================================ 9 TEXUGO-REI
const _COROA: Array = [
	"h...h...h",
	"Gh.GhG.hG",
	"GGGGGGGGG",
	"GGRGGGRGG",
	"ggggggggg",
]
## Cabeça de perfil em cunha: faixa branca do focinho até a orelha por cima, faixa preta pelo olho até o nariz, bochecha branca.
const _TEX_CAB: Array = [
	"..kk..........",
	".kwwk.........",
	".kwwwwwww.....",
	"kkkwwwwwwwww..",
	"kkkkkkwwwwwwww.",
	"kkkkkkkkkwwwwww",
	"kkkkwykkkkkkkkwn",
	"wkkkyykkkkkkkkkn",
	"wwwkkkkkkkkkkkn.",
	"wwwwwwwkkkkk....",
	".wwwwwwwwww.....",
	"...wwwwww.......",
]
const _TEX_CAB_INFO: Dictionary = {"js": 8, "ms": 8, "ab": 2, "ex": 4, "ey": 6, "olho": ["wy", "k", "w"]}
## Corpo baixo e largo, grisalho por cima (pelos claros soltos), barriga escura.
const _TEX_CORPO: Array = [
	".......l.l.l.l.l..............",
	".....lvlllvlllvlllll..........",
	"...llllllmllllllmllllll.......",
	"..llmmmlmmmmmlmmmmmmlllll.....",
	".lmmmmmmmmmmmmmmmmmmmmmmmll...",
	"lmmmmdmmmmmdmmmmmdmmmmmmmmml..",
	"mmmmmmmmmmmmmmmmmmmmmmmmmmmmml",
	"mmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
	"dmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
	".ddmmmmmmmmmmmmmmmmmmmmmmmmmmd",
	"..dddKKKKKKKKKKKKKKKKKKKKKKdd.",
	"....KKKKKKKKKKKKKKKKKKKKKKK...",
]
const _TEX_RABO: Array = ["..ll.", "llmml", "lmmmd", ".mmd."]

static func _geo9(g: Dictionary, tk: int) -> void:
	var ph: int = g["ph"]
	var e: int = [0, -2, 3, 2, 1][ph]
	var av: int = [0, -1, 3, 2, 1][ph]   # bote: o corpo inteiro avança (preparo recua); os pés ficam
	var bx: int = -17 + av
	var bw: int = 30
	g["av"] = av
	g["lag"] = 2 if ph == 2 else (1 if ph == 3 else 0)   # capa e coroa chegam atrasadas
	var bh: int = 12
	var by0: int = -16 + int(g["bob"]) - int(g["resp"])
	var hx: int = bx + 28 + e
	var hy: int = by0 - 2 + (1 if ph == 1 else 0)
	g["e"] = e
	g["bx"] = bx
	g["bw"] = bw
	g["bh"] = bh
	g["by0"] = by0
	g["hx"] = hx
	g["hy"] = hy
	g["boca"] = ph == 2 or ph == 3
	g["ext"] = (tk / 240) % 3
	g["a"] = [Vector2(hx + 6, hy + 2), Vector2(bx + bw * 0.5, by0 + bh * 0.5), Vector2(hx + 15, hy + 7), Vector2(bx + 3, by0 + 1),
		Vector2(hx + 2, hy + 10), Vector2(hx + 5, hy + 6), Vector2(hx + 5, hy + 6)]
	g["patas"] = Vector2(0, 0)

static func _monta9(G: PackedInt32Array, g: Dictionary) -> void:
	var q: int = g["q"]
	var ph: int = g["ph"]
	var bx: int = g["bx"]
	var bw: int = g["bw"]
	var bh: int = g["bh"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var fl: int = g["ext"]
	# rabo curto
	var Ra := _nova()
	_bmp(Ra, bx - 2, by0 + 1, _TEX_RABO)
	_comp(G, Ra)
	# capa vermelha por cima do dorso: presa no pescoço, cai pelas costas e passa da anca, com barra de ouro e ondulando
	var Ca := _nova()
	var nk: int = bx + bw - 4
	var tras: int = bx - 3 - (2 if g["andando"] else 0) - (2 if ph == 1 else 0) - 2 * int(g["lag"])
	for x in range(tras, nk + 1):
		var u: float = float(x - tras) / float(maxi(1, nk - tras))   # 0 atrás, 1 no pescoço
		var topo: int = by0 - 1 + (1 if x < bx + 2 else 0)
		var onda: int = roundi(1.2 * sin(float(x) * 0.7 + float(fl) * 2.1 + (float(q) if g["andando"] else 0.0)))
		var fim: int = by0 + roundi(5.0 * (1.0 - u) * (1.0 - u)) + 1 + (onda if u < 0.7 else 0)
		for y in range(topo, fim + 1):
			var ch: String = "A"
			if y == topo:
				ch = "z"
			elif posmod(x - tras, 4) == 1 and y > topo + 1:
				ch = "a"
			_px(Ca, x, y, ch)
		_px(Ca, x, fim, "G")
	_rect(Ca, nk - 1, by0, 2, 2, "G")
	# patas: curtas e grossas, pretas (as de longe mais claras)
	var L1 := _nova()
	var L2 := _nova()
	var hip: int = by0 + bh - 3
	var pf: int = bx + 23
	var pt: int = bx + 5
	_pernas(L1, L2, g, pf, pt, hip, 4, "K", "k", "k", 2)
	_comp(G, L1)
	# corpo: o molde do tronco é ele inteiro (a roupa de corpo veste o dorso)
	var B := _nova()
	_bmp(B, bx, by0, _TEX_CORPO)
	_tr = B.duplicate()
	_cr = 12
	_comp(G, B)
	if not BichoPx.corpo_coberto:
		_comp(G, Ca)
	_comp(G, L2)
	# garras brancas na pata da frente de perto (acompanham o passo e o bote)
	var Cl := _nova()
	var gx: int = pf
	var gy: int = -1
	if g["andando"]:
		var ph2: float = fposmod(float(q) / 6.0 + 0.5, 1.0)
		var pp2: Vector2i = BichoPx.pe_passo(pf, ph2, 2.5, 2.0)
		gx = pp2.x
		gy = pp2.y
	else:
		gx = pf - int(g["av"])
	if int(g["e"]) > 0:
		gx = pf + 2 + int(g["e"])
		gy = maxi(hip + 2, -2 - 2 * int(g["e"]))
	_rect(Cl, gx + 4, gy, 3, 1, "c")
	_px(Cl, gx + 3, gy, "c")
	_comp(G, Cl)
	# cabeça em camada própria, com a boca aberta no golpe
	var H := _nova()
	var cb: Dictionary = _TEX_CAB_INFO.duplicate()
	cb["rows"] = _TEX_CAB
	var cab: Array = _cab_rows(cb, g["boca"])
	_bmp(H, hx, hy, cab)
	if ph > 0:
		_px(H, hx + 3, hy + 5, "k")
		_px(H, hx + 6, hy + 5, "k")
	BichoPx.tirar(_tr, _W, _H, hx + _OX, hy + _OY, cab)
	_comp(G, H)
	# coroa de ouro com gemas (sai quando o texugo veste chapéu)
	if not BichoPx.cabeca_coberta:
		var Cr := _nova()
		_bmp(Cr, hx + 1 - int(g["lag"]), hy - 4 - (1 if int(g["lag"]) > 1 else 0), _COROA)
		_comp(G, Cr)
