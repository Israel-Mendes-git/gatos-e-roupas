class_name BichoPxChefeCasa
extends RefCounted
## Os cinco chefes do primeiro ato em pixel art, refeitos do zero (chefe_tipo 0 a 4): Rei dos Ratos, Guaxinim Glutão,
## Raposa Ligeira, Corvo Velho e Sapo-Rei. Mesmo método de BichoPxRato (convenções gerais em BichoPx): olhando para a DIREITA,
## patas no chão (último pixel em y = -1), 1 unidade = 1 pixel. Cada quadro é MONTADO em camadas numa grade de letras, cada camada
## ganha contorno quase preto de 1 px (`o`), o interior usa 3 tons (l m d) + brilho no olho, o quadro é recortado, guardado em cache
## por pose e desenhado com RoupaGato.sprite. A geometria (_geo) é a mesma para desenhar() e desloc(): as roupas acompanham o corpo.
## Cada chefe é a versão REI da espécie da família nova (mesma linguagem visual dos bichos comuns), maior e com adereço de identidade:
##   0 Rei dos Ratos: rato cinza gordo de lombo em corcova, cabeça baixa de focinho comprido, olhar rabugento, dentuço, coroa de ouro
##     e manto vermelho com barra de arminho cuja cauda arrasta no chão atrás dele (fica para trás ao andar).
##   1 Guaxinim Glutão: uma bola de guaxinim, barrigão creme quase no chão (respira por ele), máscara preta, rabão anelado,
##     guardanapo xadrez no pescoço, baba e migalhas.
##   2 Raposa Ligeira: raposa ladra elegante, esguia, pernas finas de meia preta, rabão de ponta branca, máscara de bandido, cartola
##     ameixa entre as orelhas, saco de pilhagem nas costas e rastro de velocidade; `parado` = sem fôlego: corpo caído, cabeça
##     pendurada, língua de fora, peito arfando, suor, saco escorregando e moedas no chão.
##   3 Corvo Velho: corvo corcunda de ombros altos, cabeça grisalha esticada com sobrancelha branca, bico grosso, papo de penas
##     arrepiadas, primárias falhadas, monóculo de ouro com correntinha e bengala de cabo curvo (bate no chão ao andar, avança na bicada).
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
	{"js": 8, "ms": 8, "ab": 3, "ct": 6.0, "cy": 0, "ex": 4, "ey": 5, "mb": 6, "rows": [   # Rei dos Ratos (desenhado à mão)
		"....llllll........",
		"..llllllllll......",
		".llllllllllllm....",
		"lllllllllllmmmm...",
		"llddddddmmmmmmmm..",
		"lllkkwkmmmmmmmmmmm",
		"mmmmkkmmmmmmmmmmnn",
		"mmmddmmmmmmmmmmmnn",
		".dmmmmmmmmmvvvvvv.",
		"..ddmmmvvvvvvvv...",
		"....ddVVVVV.......",
	]},
	{"js": 8, "ms": 11, "ab": 3, "ct": 7.0, "cy": 0, "ex": 5, "ey": 5, "mb": 7, "rows": [   # Guaxinim Glutão (desenhado à mão)
		".....mmmmm..........",
		"...mmlllllmm........",
		"..mllllllllllm......",
		".mlfffffffffflm.....",
		"mlaaaaaaaaaaafm.....",
		"mfaaawkaaaaaafffd...",
		"mffaakkaaaafffffdann",
		"mfffaaaaaffffffffffn",
		"mfffffffffffffffff..",
		".mffffffffffffff....",
		"..mfffffffffffv.....",
		"...vvvvvvvvvv.......",
	]},
	{"js": 6, "ms": 6, "ab": 3, "ct": 7.0, "cy": 0, "ex": 8, "ey": 4, "mb": 6, "rows": [   # Raposa Ligeira (desenhada à mão: máscara de bandido, olho de fenda)
		"...llllllll.......",
		"..lllllllllll.....",
		".llllllllllll.....",
		"lllllaaaaammmmmm..",
		"llaaaaaaYwammmmmnn",
		"mmmaaaaaammkmmmmnn",
		".mmmmvvvvvvvvvvvv.",
		"..dmvvvvvvvvvvv...",
		"...ddvvvvvvvv.....",
		".....dddvvvv......",
	]},
	{"js": 8, "ms": 9, "ab": 3, "ct": 5.0, "cy": 0, "ex": 5, "ey": 4, "mb": 7, "rows": [   # Corvo Velho (desenhado à mão)
		"...hhhhh...........",
		".hhhhhhhhW.........",
		"hhhWWWWWWWW........",
		"hmmmmmmmmmsss......",
		"mmmmmkkmmaaaaaaa...",
		"mmmmmkwmaaaaaaaaaa.",
		"mmmmmmmmaaaaaaaaaaa",
		"dmmmmmmmccccccccaac",
		"ddmmmmmaaaaaaaaa.c.",
		".dddmmmmaaaaa......",
		"..dddd.............",
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
	{"bx": -14, "bw": 26, "bh": 17, "pe": 3, "hx": 6, "hoff": 3, "pf": 5, "pt": -10, "lw": 3, "str": 2.5, "lift": 2.0, "dedo": "p", "socks": 0},
	{"bx": -14, "bw": 27, "bh": 20, "pe": 2, "hx": 7, "hoff": 4, "pf": 6, "pt": -10, "lw": 4, "str": 2.0, "lift": 2.0, "dedo": "a", "socks": 0},
	{"bx": -11, "bw": 20, "bh": 9, "pe": 10, "hx": 4, "hoff": -4, "pf": 5, "pt": -9, "lw": 1, "str": 5.0, "lift": 4.0, "dedo": "f", "socks": 4},
	{"bx": -12, "bw": 22, "bh": 16, "pe": 5, "hx": 6, "hoff": -5, "pf": 1, "pt": -3, "lw": 1, "str": 3.0, "lift": 3.0, "dedo": "p", "socks": 0},
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
				"P": Color("c47c92"), "n": Color("e8788f"), "e": Color("f6f2f4"), "E": Color("c8c4d6"), "V": Color("c0c2d8")}, true)
		1:   # guaxinim pardo, face e barriga cremes, máscara e patas quase pretas
			P.merge({"o": Color("2a1a1c"), "l": Color("c8aa92"), "m": Color("927462"), "d": Color("584640"), "a": Color("1e1416"), "f": Color("f6ead4"),
				"v": Color("e0c8a8"), "p": Color("d49a98"), "P": Color("9c6a68"), "n": Color("241a1e"), "s": Color("a8804a")}, true)
		2:   # raposa-vermelha viva, meias e pontas das orelhas pretas, ponta do rabo branca
			P.merge({"o": Color("3a1a10"), "l": Color("fcb858"), "m": Color("ee7c28"), "d": Color("b04a1c"), "v": Color("fff0d8"), "e": Color("3a2018"),
				"f": Color("2a1814"), "u": Color("fffaf0"), "n": Color("241a1e"),
				"a": Color("2a2232"), "A": Color("54486a"), "P": Color("5e3a7c"), "p": Color("8c62ac"), "S": Color("e0c080"), "s": Color("b08a4c"),
				"t": Color("6e4a28"), "G": Color("2c6a48"), "H": Color("4c9a68")}, true)
		3:   # corvo velho: carvão azulado, cabeça grisalha, bico de chifre, pele rosada nas falhas
			P.merge({"o": Color("0a0a14"), "l": Color("66708c"), "m": Color("3e4660"), "d": Color("252a40"), "s": Color("a8b4d8"), "h": Color("8c90a4"),
				"a": Color("5c5a68"), "c": Color("2a2834"), "e": Color("f0e8b0"), "p": Color("4c4656"), "P": Color("2e2a38"), "N": Color("e8b4a8")}, true)
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
	var e: float = BichoPx.curva_golpe(golpe)   # contato logo no passo do dano, volta desacelerando
	# o mesmo golpe um quadro antes (1/30 s): coroa, manto e guardanapo chegam atrasados
	var e_ant: float = BichoPx.curva_golpe(golpe + 1.0 / 30.0) if golpe > 0.0 else 0.0
	var pr: int = BichoPx.recuo(golpe)        # preparo: cabeça recua 1-2 px e o corpo agacha 1
	var dor: int = 1 if BichoPx.dor else 0
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
				bob = [0, 0, -1, -2, -1, 0][q]   # alto no esticão do galope
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
	# Rei dos Ratos e Glutão: no bote o corpo inteiro avança (os pés ficam) e a pata da frente sobe; manto, coroa e guardanapo
	# chegam um quadro depois (só pose: a arte deles não muda)
	var av: int = 0
	var lag: int = 0
	if ct == 0 or ct == 1 or ct == 2:
		av = roundi(3.0 * e) - pr
		lag = clampi(roundi(3.0 * e) - roundi(3.0 * e_ant), -2, 2)
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
	var bxo: int = 0
	if ct == 2:
		if sem_folego:
			pe = 5       # sem fôlego: o corpo desaba, pernas dobradas e abertas
			bh = 10
		elif andando:
			bxo = -1     # correndo: corpo esticado e mais baixo
			bw += 5
			bh = 8
	var by0: int = -pe - bh - salto + bob + (1 if pr > 0 else 0)
	if ct == 4:
		bh -= sq
		by0 = -pe - bh - salto + (1 if pr > 0 else 0)
	var hdx: int = ei - pr - dor + av
	var hdy: int = 0
	if ct == 0:
		hdy = ei / 2
	elif ct == 3:
		hdx += hbx
		hdy = ei / 2
	elif ct == 2:
		if andando:
			hdy = 4
			hdx += 4
		elif ei > 0:
			hdy = 2
		if sem_folego:
			hdx = -2
			hdy = 7
	if ct != 4 and ct != 1:   # o Glutão respira pelo barrigão (desenhado em _monta_glutao), não sobe o corpo
		by0 -= resp
		bh += resp
	var hx: int = int(esp["hx"]) + hdx
	var hy: int = by0 + int(esp["hoff"]) + hdy
	if ct == 4 and aire > 0:
		hx += 1
		hy -= 1
	if ct == 1:
		hy -= 0
	return {"ct": ct, "q": q, "e": e, "ei": ei, "boca": boca, "tl": tl, "ala": ala, "resp": resp, "bob": bob, "salto": salto, "aire": aire, "sq": sq,
		"sw": sw, "dr": dr, "esp": esp, "ch": ch, "hw": hw, "hh": hh, "bx": int(esp["bx"]) + av + bxo, "bw": bw, "bh": bh, "pe": pe, "by0": by0, "hx": hx, "hy": hy,
		"andando": andando, "parado": sem_folego, "av": av, "lag": lag, "pr": pr, "dor": dor, "ol": BichoPx.modo_olho()}

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
## Cabeça com o olho da pose (apertado na dor, X no nocaute: BichoPx.olhos) e a boca aberta ou fechada.
## [letras do olho, fundo, traço, ajuste de coluna]: Glutão e Corvo Velho redesenhados à mão (olho no meio da máscara/da cabeça)
const _OLHO: Array = [["kw", "m", "k", 0], ["wk", "a", "w", 0], ["Yw", "a", "w", 0], ["kw", "m", "k", 0], ["ek", "l", "k", -1]]
static func _cab_rows(ct: int, ch: Dictionary, boca: bool) -> Array:
	var o: Array = _OLHO[clampi(ct, 0, 4)]
	return BichoPx.olhos(_cab_rows0(ct, ch, boca), int(ch["ex"]) + int(o[3]), int(ch["ey"]), BichoPx.modo_olho(), o[0], o[1], o[2], 5)

static func _cab_rows0(ct: int, ch: Dictionary, boca: bool) -> Array:
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
	var av: int = g["av"]   # bote: o quadril vai junto com o corpo, o pé fica onde estava
	# [x do quadril, fase (as diagonais andam juntas), tom, camada]: as de longe (d) por baixo, as de perto (m) por cima
	var defs: Array = [[pt + 3, 0.5, "d", L1], [pf + 3, 0.0, "d", L1], [pt, 0.0, "m", L2], [pf, 0.5, "m", L2]]
	for k in defs.size():
		var d: Array = defs[k]
		var x: int = int(d[0]) + av
		var xf: int = int(d[0])
		var yf: int = -1
		if g["andando"]:
			var ph: float = fposmod(float(q) / 6.0 + float(d[1]), 1.0)
			var pp: Vector2i = BichoPx.pe_passo(x, ph, float(esp["str"]), float(esp["lift"]))   # pé no ar vai para a frente
			xf = pp.x
			yf = pp.y
		elif g["parado"]:
			xf = x + (-2 if k % 2 == 0 else 2) + (tre if k < 2 else 1 - tre)   # pernas abertas e bambas
		if ei > 0 and d[1] == 0.5 and d[2] == "m" and x == pf + av:
			xf = x + 2 + ei   # golpe: pata dianteira de perto sobe e avança
			yf = maxi(hip + 1, -2 - 2 * ei)
		_pata(d[3], x, hip, xf, yf, w, d[2], dedo, int(esp["socks"]))
		if ei > 0 and d[1] == 0.5 and d[2] == "m" and x == pf + av and w < 4:
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
	return "%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [g["ct"], int(g["andando"]), g["q"], g["ei"], int(g["boca"]), g["resp"], g["bob"], g["salto"], g["aire"], g["sq"], int(g["parado"]), g["sw"], g["dr"], g["ala"], g["tl"], int(BichoPx.cabeca_coberta) * 2 + int(BichoPx.corpo_coberto)] + "|%d|%d|%d|%d|%d" % [g["av"], g["lag"], g["pr"], g["dor"], g["ol"]]

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
## Desenhado à mão em camadas (rabo, patas de longe, orelha de longe, corpo, patas de perto, cabeça, orelha, manto, coroa, bigodes):
## rato gordo de lombo alto em corcova, cabeça baixa e focinho comprido, olho rabugento de pálpebra pesada e dentões à mostra.
const _RR_CORPO: Array = [
	"........llllllll..........",
	".....lllllllllllllll......",
	"...llllllllmmmmmmlllll....",
	"..lllllmmmmmmmmmmmmmlll...",
	".llllmmmmmmmmmmmmmmmmmll..",
	".lllmmmmmmmmmmmmmmmmmmmml.",
	"lllmmmmmmmmmmmmmmmmmmmmmmm",
	"llmmmmmmmmmmmmmmmmmmmmmmmm",
	"lmmmmmmmmmmmmmmmmmmmmmmmmv",
	"mmmmmmmmmmmmmmmmmmmmmmmmvv",
	"mmmmmmmmmmmmmmmmmmmmmmmvvv",
	"dmmmmmmmmmmmmmmmmmmmmvvvvv",
	"dmmmmmmmmmmmmmmmmmmvvvvvvv",
	".ddmmmmmmmmmmmmmvvvvvvvvv.",
	"..dddmmmmmmmmvvvvvvvvvvv..",
	"....dddddddddvvvvvvvvv....",
	"......ddddddd.VVVVVV......",
]
## Manto de veludo por cima do lombo, caindo pelo flanco até a barra de arminho (sai quando o rei veste roupa de corpo).
const _RR_MANTO: Array = [
	"................jjjjjjjj........",
	".............jjjjrrrrrrjjjj.....",
	"...........jjjrrrrrrrrrrrrrjjj..",
	"..........jrrrrrrrrrrrrrrrrrrrj.",
	".........jrrrrrrrrrrrrrrrrrrrrRR",
	"........jrrrrrRrrrrrrrrrrrrrrRR.",
	".......jrrrrrrRrrrrrrrrrrrrRR...",
	"......jrrrrrrrRrrrrrrrrrrrRR....",
	".....jrrRrrrrrRRrrrrrrrrRRe.....",
	"....jrrrRrrrrrRRrrrrrrRRee......",
	"...jrrrrRrrrrRRRRrrRRReek.......",
	"...rrrrrRRrrreekeeeekee.........",
	"..rrrrrrRRre....................",
	"..rrrrrRRRRe....................",
	".rrrrrRRRRe.....................",
	".rrrrRRRRRe.....................",
	"rrrrRRRRRRe.....................",
	"rrrRRRRRRe......................",
	"eekeeekeee......................",
	".eeeeeeee.......................",
]
const _RR_ORELHA: Array = ["..lll...", ".lpppl..", "lppPppl.", "lpPPPpm.", "lpPPPpm.", "mppPppm.", ".mpppm..", "..mmm..."]
const _RR_COROA: Array = ["Y..Y..Y", "YY.Y.YY", "YYYYYYY", "yrYBYry", "yyyyyyy"]

static func _monta_rei(G: PackedInt32Array, g: Dictionary) -> void:
	var ch: Dictionary = g["ch"]
	var bx: int = g["bx"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var ei: int = g["ei"]
	var sw: int = g["sw"]
	var q: int = g["q"]
	# rabo comprido e pelado
	var L := _nova()
	_rabo_fino(L, g, bx + 1, by0 + 11, 16, 3)
	_comp(G, L)
	# patas de longe e orelha de longe
	var L1 := _nova()
	var L2 := _nova()
	_pernas4(L1, L2, g)
	_comp(G, L1)
	var OL := _nova()
	var ol: Array = []
	for r in _RR_ORELHA:
		ol.append(String(r).replace("l", "d").replace("m", "d").replace("p", "P"))
	var od: int = g["dor"]   # dor: orelhas baixas e para trás
	_bmp(OL, hx - 5 - od, hy - 6 + od, ol)
	_comp(G, OL)
	# corpo (o molde do tronco é ele inteiro) e patas de perto
	var B := _nova()
	_bmp(B, bx, by0, _RR_CORPO)
	_tr = B.duplicate()
	_comp(G, B)
	_comp(G, L2)
	# manto por cima do lombo; a ponta de trás voa ao andar e no bote
	if not BichoPx.corpo_coberto:
		var C := _nova()
		# a cauda do manto arrasta no chão atrás do rei; ao andar e no bote ela fica para trás, e parado ondula de leve
		var lag: int = g["lag"]   # o manto chega um quadro atrasado no bote
		var vo: int = ([1, 2, 3, 3, 2, 1][q] if g["andando"] else sw % 2) + ei / 2 + (1 if lag > 0 else 0)
		for j in _RR_MANTO.size():
			var s: String = _RR_MANTO[j]
			var dx: int = -(vo * maxi(0, j - 8)) / 6
			for i in s.length():
				if s[i] != ".":
					_px(C, bx - 8 - lag + i + (dx if i < 12 else 0), by0 - 1 + j, s[i])
		_comp(G, C)
	# cabeça em camada própria (boca aberta no bote), dentões de roedor
	var H := _nova()
	var cab: Array = _cab_rows(0, ch, g["boca"])
	_bmp(H, hx, hy, cab)
	if not g["boca"]:
		_rect(H, hx + 13, hy + 9, 2, 2, "w")
		_rect(H, hx + 13, hy + 11, 2, 1, "E")
	BichoPx.tirar(_tr, _W, _H, hx + _OX, hy + _OY, cab)
	_comp(G, H)
	# orelha de perto, redonda e grande, atrás da coroa
	var OP := _nova()
	_bmp(OP, hx - 2 - od, hy - 7 + od, _RR_ORELHA)
	BichoPx.tirar(_tr, _W, _H, hx - 2 - od + _OX, hy - 7 + od + _OY, _RR_ORELHA)
	_comp(G, OP)
	# fecho de ouro do manto no pescoço
	if not BichoPx.corpo_coberto:
		var FE := _nova()
		_bmp(FE, hx - 1, hy + 6, [".Y.", "YyY", ".Y."])
		_comp(G, FE)
	# coroa de ouro com rubis
	if not BichoPx.cabeca_coberta:
		var CR := _nova()
		_bmp(CR, hx + 4 - int(g["lag"]), hy - 4 - (1 if int(g["lag"]) > 0 else 0), _RR_COROA)   # a coroa chega atrasada no bote
		_comp(G, CR)
	# bigodes longos e caídos (sem contorno)
	var WB := _nova()
	var wy: int = hy + 6 + (ei / 2)
	_rect(WB, hx + 13, wy, 5, 1, "W")
	_px(WB, hx + 18, wy + 1, "W")
	_px(WB, hx + 19, wy + 2, "W")
	_rect(WB, hx + 12, wy + 2, 5, 1, "W")
	_px(WB, hx + 17, wy + 3, "W")
	_px(WB, hx + 18, wy + 4, "W")
	_comp(G, WB, false)

# ================================================================ 1. GUAXINIM GLUTÃO
## Desenhado à mão em camadas (rabo, patas de longe, corpo, patas de perto, cabeça, orelha, guardanapo): uma bola de guaxinim,
## barrigão creme caído quase no chão sobre patinhas curtas, máscara preta, bochechas estufadas de comida e rabão anelado.
const _GX_CORPO: Array = [
	".........lllllllll.........",
	"......lllllllllllllll......",
	"....lllllllllllllllmmmm....",
	"...lllmmmmmmmmmmmmmmmmmm...",
	"..llmmmmmmmmmmmmmmmmmmmmm..",
	".lmmmmmmmmmmmmmmmmmmmmmmmm.",
	".lmmmmmmmmmmmmmmmmmmmmmmmm.",
	"lmmmmmmmmmmmmmmffffffmmmmmm",
	"mmmmmmmmmmmmfffffffffffmmmm",
	"dmmmmmmmmmffffffffffffffmmm",
	"dmmmmmmmmfffffffffffffffffm",
	"dmmmmmmmffffffffffffffffffm",
	"dmmmmmmmfffffffffffffffffff",
	"ddmmmmmffffffffffffffffffff",
	".ddmmmmffffffffffffffffffff",
	".dddmmmfffffffffffffffffff.",
	"..dddddvffffffffffffffffvv.",
	"....dddvvvfffffffffffvvvv..",
	"......dddvvvvvvvvvvvvvv....",
	".........ddvvvvvvvvv.......",
]
## Rabão felpudo com anéis pretos e ponta preta.
const _GX_RABO: Array = [
	"..aa.ll.aa.ll.aa.ll.",
	".aaaallaaallaaalllll",
	"aaaalllaaalllaaallll",
	"aaaammmaaammmaaammmm",
	"aaaammmaaammmaaammmm",
	"aaaammmaaammmaaammmm",
	".aaadmmaaadmmaaadmmm",
	"..aaddd.aaddd.aadd..",
]
const _GX_ORELHA: Array = ["..ff.", ".fmmf", "fmdmm", "fmdmm", "mmmmm"]

static func _monta_glutao(G: PackedInt32Array, g: Dictionary) -> void:
	var ch: Dictionary = g["ch"]
	var bx: int = g["bx"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var hh: int = g["hh"]
	var ei: int = g["ei"]
	var q: int = g["q"]
	var dr: int = g["dr"]
	var resp: int = g["resp"]
	# rabão anelado: balança ao andar, encolhe no bote
	var L := _nova()
	var wag: int = roundi(2.0 * sin(TAU * float(q) / 6.0)) if g["andando"] else 0
	if ei > 1:
		wag = -2
	for j in _GX_RABO.size():
		var s: String = _GX_RABO[j]
		for i in s.length():
			if s[i] != ".":
				_px(L, bx - 17 + i, by0 + 6 + j + roundi(float(wag) * float(19 - i) / 19.0), s[i])
	_comp(G, L)
	# patas de longe
	var L1 := _nova()
	var L2 := _nova()
	_pernas4(L1, L2, g)
	_comp(G, L1)
	# corpo (o molde do tronco é ele inteiro); o barrigão estufa ao respirar
	var B := _nova()
	_bmp(B, bx, by0, _GX_CORPO)
	if resp > 0:
		for j in range(9, 16):
			_rect(B, bx + 27, by0 + j, resp - (1 if j == 9 or j == 15 else 0), 1, "f")
	_tr = B.duplicate()
	_px(B, bx + 19, by0 + 14, "v")   # umbigo
	_px(B, bx + 20, by0 + 14, "v")
	_comp(G, B)
	_comp(G, L2)
	# orelha de longe, cabeça em camada própria (boca aberta no bote) e orelha de perto
	var OL := _nova()
	var od: int = g["dor"]   # dor: orelhas baixas e para trás
	_bmp(OL, hx - od, hy - 3 + od, [".ddd.", "daaad", "dadad", "ddddd"])
	BichoPx.tirar(_tr, _W, _H, hx - od + _OX, hy - 3 + od + _OY, [".ddd.", "daaad", "dadad", "ddddd"])
	_comp(G, OL)
	var H := _nova()
	var cab: Array = _cab_rows(1, ch, g["boca"])
	_bmp(H, hx, hy, cab)
	BichoPx.tirar(_tr, _W, _H, hx + _OX, hy + _OY, cab)
	_comp(G, H)
	var OP := _nova()
	_bmp(OP, hx + 3 - od, hy - 4 + od, _GX_ORELHA)
	BichoPx.tirar(_tr, _W, _H, hx + 3 - od + _OX, hy - 4 + od + _OY, _GX_ORELHA)
	_comp(G, OP)
	# guardanapo xadrez amarrado no pescoço, com migalhas (sai quando o guaxinim veste roupa de corpo)
	if not BichoPx.corpo_coberto:
		var N := _nova()
		var nx: int = hx - 1 - int(g["lag"])   # o guardanapo chega um quadro atrasado no bote
		var ny: int = hy + hh - 3
		var wids: Array = [12, 12, 11, 10, 9, 7, 5, 3]
		for j in wids.size():
			var wj: int = wids[j]
			for i in wj:
				_px(N, nx + i + (12 - wj) / 2, ny + j, "w" if (i / 2 + j / 2) % 2 == 0 else "r")
		_rect(N, nx - 3, ny - 1, 3, 2, "r")   # nó atrás do pescoço
		_rect(N, nx - 4, ny + 1, 2, 3, "R")
		_comp(G, N)
		var MG := _nova()
		_px(MG, nx + 3, ny + 3, "y")
		_px(MG, nx + 8, ny + 5, "b")
		_px(MG, nx + 5, ny + 6, "y")
		_comp(G, MG, false)
	# baba pingando e migalhas no queixo
	var DR := _nova()
	var bxx: int = hx + 13
	for k in dr + 1:
		_px(DR, bxx, hy + hh - 1 + k, "u")
	_px(DR, hx + 16, hy + 9, "y")
	_px(DR, hx + 11, hy + hh - 2, "b")
	_comp(G, DR, false)

# ================================================================ 2. RAPOSA LIGEIRA
## Desenhada à mão em camadas (rabo, saco, patas de longe, orelha de longe, corpo, patas de perto, pescoço + cabeça, orelha de perto,
## cartola, língua, suor): raposa LADRA ELEGANTE, esguia, de pernas finas e meias pretas, máscara de bandido, olho de fenda, cartola
## ameixa entre as orelhas e saco de pilhagem nas costas. Três poses bem distintas: parada alerta (rabo ondulando), correndo
## (corpo esticado, rabo reto, passada longa, saco balançando atrasado) e sem fôlego (`parado`: corpo caído, cabeça pendurada,
## língua de fora, peito arfando, suor, saco escorregando, moedas no chão).
const _RP_OREL: Array = [
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
const _RP_CARTOLA: Array = [
	".pPPPPPP.",
	".PPPPPPP.",
	".PPPPPPP.",
	".YyyyyyY.",
	"PPPPPPPPP",
]
## Saco de pilhagem de juta com cifrão; o gargalo amarrado fica para cima.
const _RP_SACO: Array = [
	"...tt.....",
	"..tsst....",
	".sSSSSSSs.",
	"sSSSkSSSSs",
	"SSSkkkSSSs",
	"SSSkSSSSSs",
	"SSSkkkSSSs",
	"SSSSSkSSSs",
	"SSSkkkSSSs",
	"sSSSkSSSSs",
	".ssSSSSss.",
	"..ssssss..",
]

## Cabeça da pose: fechada, boca aberta (bote: dentes e vão escuro) ou ofegante (vão fino; a língua é outra camada).
static func _cab_rapo(ch: Dictionary, boca: bool, par: bool) -> Array:
	var rows: Array = ch["rows"]
	var r: Array = []
	if boca:
		for j in 6:
			r.append(rows[j])
		r.append(".mmmmvvvvvvwvvvwv.")
		r.append("..dmmmqqqqqqqqqqq.")
		r.append("...dmqqqqqqqqqqq..")
		r.append("...ddvvvvwvvvwvv..")
		r.append(".....dddvvvvvvv...")
	elif par:
		for j in 7:
			r.append(rows[j])
		r.append("..dmvvvvkkkkkkvv..")
		r.append("...ddvvvvvvvvvv...")
		r.append(".....dddvvvvv.....")
	else:
		r = rows.duplicate()
	var o: Array = _OLHO[2]
	return BichoPx.olhos(r, int(ch["ex"]), int(ch["ey"]), BichoPx.modo_olho(), o[0], o[1], o[2], 5)

## Tronco esguio: costas retas, peito fundo à frente, cintura fina e coxa na anca; `ch` = reforço do peito (arfando).
static func _tronco_rapo(L: PackedInt32Array, bx: int, by0: int, bw: int, bh: int, ch: int) -> void:
	var pts: Array = [[0.0, 0.5], [0.1, 0.8], [0.42, 0.5], [0.75, 1.0], [1.0, 0.8]]
	for i in bw:
		var u: float = float(i) / float(bw - 1)
		var hf: float = 0.8
		for k in range(1, pts.size()):
			var a: Array = pts[k - 1]
			var b: Array = pts[k]
			if u <= float(b[0]):
				hf = lerpf(float(a[1]), float(b[1]), (u - float(a[0])) / (float(b[0]) - float(a[0])))
				break
		var h: int = maxi(3, roundi(float(bh) * hf)) + (ch if u > 0.55 else 0)
		var y0: int = by0 - (1 if u > 0.66 else 0)
		for j in h:
			var c: String = "m"
			if j < 2:
				c = "l"
			elif j >= h - 2:
				c = "d"
			if u > 0.72 and j >= h / 2 and j < h - 1:
				c = "v"
			_px(L, bx + i, y0 + j, c)
	_elip(L, bx + 1, by0 + 1, 8, bh - 1)   # coxa

static func _pernas_rapo(L1: PackedInt32Array, L2: PackedInt32Array, g: Dictionary) -> void:
	var esp: Dictionary = g["esp"]
	var q: int = g["q"]
	var hip: int = int(g["by0"]) + int(g["bh"]) - 2
	var bx: int = g["bx"]
	var bw: int = g["bw"]
	var ei: int = g["ei"]
	var av: int = g["av"]
	var wob: int = g["sw"] % 2
	var pt: int = bx + 3
	var pf: int = bx + bw - 6
	# [x do quadril, fase, tom, camada, é de frente]: galope = as duas de trás e as duas da frente quase juntas, em oposição
	var defs: Array = [[pt + 3, 0.08, "d", L1, false], [pf + 3, 0.42, "d", L1, true], [pt, 0.0, "m", L2, false], [pf, 0.5, "m", L2, true]]
	for k in defs.size():
		var d: Array = defs[k]
		var x: int = int(d[0])
		var frente: bool = d[4]
		var xf: int = x
		var yf: int = -1
		if g["andando"]:
			var pp: Vector2i = BichoPx.pe_passo(x, float(d[1]) + float(q) / 6.0, float(esp["str"]), float(esp["lift"]))
			xf = pp.x
			yf = pp.y
		elif g["parado"]:
			xf = x + (3 if frente else -3) + (wob if k % 2 == 0 else -wob)
		else:
			xf = x if frente else x - av
		var garra: bool = false
		if ei > 0 and frente:
			if d[2] == "m":
				xf = x + 3 + ei
				yf = maxi(hip + 1, -3 - 2 * ei)
				garra = true
			else:
				xf = x + 1 + ei / 2
				yf = maxi(hip + 1, -2 - ei)
		_pata(d[3], x, hip, xf, yf, 1, d[2], "f", int(esp["socks"]))
		if garra:
			_rect(d[3], xf + 3, yf, 1, 1, "w")
			_rect(d[3], xf + 2, yf - 1, 1, 1, "w")

static func _monta_raposa(G: PackedInt32Array, g: Dictionary) -> void:
	var ch: Dictionary = g["ch"]
	var bx: int = g["bx"]
	var bw: int = g["bw"]
	var bh: int = g["bh"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var ei: int = g["ei"]
	var q: int = g["q"]
	var sw: int = g["sw"]
	var par: bool = g["parado"]
	var run: bool = g["andando"]
	var od: int = g["dor"]
	# rabão cheio de ponta branca: sobe e ondula parado, reto para trás correndo, arrasta no chão sem fôlego
	var L := _nova()
	var comp: int = 15
	var rsy: int = by0 + 2
	var wag: int = roundi(2.0 * sin(TAU * float(sw) / 6.0))
	var sobe: float = 6.0
	if run:
		wag = roundi(sin(TAU * float(q) / 6.0))
		sobe = 0.0
	elif par:
		wag = 12
		sobe = 3.0
	if ei > 1:
		wag = -3
		sobe = 3.0
	var n: int = comp * 2
	for i in n + 1:
		var t: float = float(i) / float(n)
		var cx: int = bx + 2 - roundi(t * comp)
		var cy: int = rsy + roundi(2.0 * sin(t * PI * 0.9) - sobe * t * t + float(wag) * t)
		if par:
			cy = mini(cy, -3)
		var rr: float = 5.0 * (0.35 + 0.65 * sin(PI * pow(t, 0.75))) * (1.0 - 0.35 * t * t)
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
				if t >= 0.8:
					c = "u"
				_px(L, cx + dx, cy + dy, c)
	_comp(G, L)
	# patas de longe
	var L1 := _nova()
	var L2 := _nova()
	_pernas_rapo(L1, L2, g)
	_comp(G, L1)
	# orelha de longe e orelha de perto (pendem para trás na dor e sem fôlego; com elmo só sobram as bases)
	var oy: int = 3 if par else (2 * od)
	var ox: int = -2 if par else -od
	var far: Array = []
	for s in _RP_OREL:
		far.append(String(s).replace("l", "d").replace("m", "d").replace("e", "d"))
	var OL := _nova()
	if BichoPx.cabeca_coberta:
		_bmp(OL, hx + ox, hy - 2, far.slice(5))
	else:
		_bmp(OL, hx + ox, hy - 7 + oy, far)
	_comp(G, OL)
	# corpo (o molde do tronco é ele inteiro) e patas de perto
	var B := _nova()
	_tronco_rapo(B, bx, by0, bw, bh, g["resp"] if par else 0)
	_tr = B.duplicate()
	_comp(G, B)
	_comp(G, L2)
	# saco de pilhagem nas costas, por cima do corpo e da roupa de corpo (não entra no molde do tronco): balança atrasado ao correr e escorrega sem fôlego
	var SA := _nova()
	var sx: int = bx + 3 - int(g["lag"])
	var sy: int = by0 - 9
	if run:
		sx -= 2
		sy += [0, 1, 0, -1, 0, 1][posmod(q - 2, 6)]
	elif par:
		sx = bx - 4
		sy = by0 + 1
	_bmp(SA, sx, sy, _RP_SACO)
	BichoPx.tirar(_tr, _W, _H, sx + _OX, sy + _OY, _RP_SACO)
	_comp(G, SA)
	# pescoço + cabeça (boca aberta no bote, ofegante sem fôlego)
	var H := _nova()
	var cab: Array = _cab_rapo(ch, g["boca"], par)
	var ny0: int = hy + 3
	var nh: int = maxi(5, by0 + bh - ny0 - 1)
	_elip(H, hx - 1, ny0, 9, nh)
	_bmp(H, hx, hy, cab)
	BichoPx.tirar(_tr, _W, _H, hx - 1 + _OX, ny0 + _OY, _nova_rows(9, nh))
	BichoPx.tirar(_tr, _W, _H, hx + _OX, hy + _OY, cab)
	_comp(G, H)
	var OP := _nova()
	if BichoPx.cabeca_coberta:
		_bmp(OP, hx + 10 + ox, hy - 2, _RP_OREL.slice(5))
	else:
		_bmp(OP, hx + 10 + ox, hy - 7 + oy, _RP_OREL)
	_comp(G, OP)
	# cartola ameixa entre as orelhas (sai quando ela veste peça de cabeça)
	if not BichoPx.cabeca_coberta:
		var HT := _nova()
		_bmp(HT, hx + 4 - int(g["lag"]) + ox, hy - 5 + (2 if par else 0), _RP_CARTOLA)
		_comp(G, HT)
	# sem fôlego: língua de fora (camada própria, com contorno) e suor; moedas caídas do saco
	if par:
		var TG := _nova()
		var tx0: int = hx + 9
		_rect(TG, tx0, hy + 8, 3, 3 + g["resp"], "T")
		_rect(TG, tx0 + 1, hy + 8 + 3 + g["resp"], 2, 1, "U")
		_rect(TG, tx0 + 1, hy + 8, 1, 3 + g["resp"], "U")
		_comp(G, TG)
		var SU := _nova()
		var gt: int = g["dr"]
		_rect(SU, hx + 1, hy - 3 + gt, 1, 2, "x")
		_rect(SU, hx + 14, hy + 1 + (gt + 1) % 3, 1, 2, "x")
		_rect(SU, hx - 3, hy + 4 + (gt + 2) % 3, 1, 2, "x")
		_rect(SU, bx + 12, by0 - 1 + gt, 1, 2, "x")
		_comp(G, SU, false)
		var MO := _nova()
		_rect(MO, bx - 7, -3, 2, 2, "Y")
		_rect(MO, bx - 11, -2, 2, 1, "y")
		_comp(G, MO)
	# rastro de velocidade (sem contorno)
	if run:
		var WB := _nova()
		for i in 3:
			_rect(WB, bx - 24 - i * 3, by0 + 2 + i * 3, 12 - i * 2, 1, "W")
		_comp(G, WB, false)

## Linhas "m" de `w` x `h` (só para tirar o pescoço do molde do tronco).
static func _nova_rows(w: int, h: int) -> Array:
	var r: Array = []
	for j in h:
		r.append("m".repeat(w))
	return r

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

## Desenhado à mão em camadas (cauda, perna de longe, corpo, perna de perto, asa, papo, cabeça, bengala, monóculo): corvo velho
## corcunda, ombros mais altos que a cabeça, cabeça grisalha esticada para a frente com sobrancelha branca, bico grosso de chifre,
## papo de penas arrepiadas, asa dobrada com as primárias falhadas e cauda comprida arrastando.
const _CV_CORPO: Array = [
	"..............llll....",
	"...........lllllllll..",
	".........llllllllllll.",
	".......lllmmmmmmmmmlll",
	"......llmmmmmmmmmmmmml",
	".....lmmmmmmmmmmmmmmmm",
	"....lmmmmmmmmmmmmmmmmm",
	"...lmmmmmmmmmmmmmmmmmm",
	"..lmmmmmmmmmmmmmmmmmmd",
	".lmmmmmmmmmmmmmmmmmmdd",
	"lmmmmmmmmmmmmmmmmmmdd.",
	"mmmmmmmmmmmmmmmmmmdd..",
	"dmmmmmmmmmmmmmmmddd...",
	".dmmmmmmmmmmmddd......",
	"..ddmmmmmmddd.........",
	"...ddddddd............",
]
const _CV_ASA: Array = [
	"...............sslll..",
	".............lllllmmml",
	"..........llllmmmmmmml",
	"........lllmmmmmmmmmmm",
	"......llmmmmdmmmmmmmmm",
	".....lmmmmdmmmmmdmmmmd",
	"....lmmmdmmmmmdmmmmmd.",
	"...lmmdmmmmmdmmmmmmd..",
	"..lmmmmmmmdmmmmmmdd...",
	".mmmmmmdmmmmmmmdd.....",
	"mmdmmmmmmmmdddd.......",
	"dmmmmmdmmdd...........",
	".dmdmdmdd.............",
	"d.d.d.d...............",
	"..d..d................",
]
const _CV_CAUDA: Array = [
	".......mmm",
	".....mmmmm",
	"...mmmmmmd",
	"..mmmdmmd.",
	".mmdmmmd..",
	"mmmmmdd...",
	"dmdmd.....",
	".d.d......",
]
const _CV_BARBA: Array = ["mmmmmmmmm", "mdmmdmmdm", "mm.dm.dm.", "d..d..d..", "...d....."]

static func _monta_corvo(G: PackedInt32Array, g: Dictionary) -> void:
	var esp: Dictionary = g["esp"]
	var ch: Dictionary = g["ch"]
	var bx: int = g["bx"]
	var bw: int = g["bw"]
	var bh: int = g["bh"]
	var by0: int = g["by0"]
	var hx: int = g["hx"]
	var hy: int = g["hy"]
	var ei: int = g["ei"]
	var q: int = g["q"]
	var ala: int = g["ala"]
	# cauda comprida e esfiapada, caída para trás
	var L := _nova()
	var wag: int = 0
	if g["andando"]:
		wag = 1 if q % 3 == 1 else 0
	if ei > 1:
		wag = -2
	for j in _CV_CAUDA.size():
		var s: String = _CV_CAUDA[j]
		for i in s.length():
			if s[i] != ".":
				_px(L, bx - 8 + i, by0 + 11 + j + (wag * (9 - i)) / 9, s[i])
	_comp(G, L)
	# pernas finas e escamosas, joelho ossudo, três dedos para a frente e um para trás
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
			var lx: int = roundi(lerpf(x, xf, float(i) / float(n)))
			_px(d[3], lx, hip + i, d[2])
			_px(d[3], lx + 1, hip + i, d[2])
		_px(d[3], roundi(lerpf(x, xf, 0.5)) - 1, hip + n / 2, d[2])   # joelho
		_rect(d[3], xf - 1, yf, 5, 1, d[2])
		_px(d[3], xf - 2, yf, d[2])
		_px(d[3], xf + 4, yf - 1, d[2])
	_comp(G, L1)
	# asa de longe (só aberta)
	if ala > 0:
		var AL := _nova()
		_asa_aberta(AL, bx + bw - 8, by0 + 3, ala, 15, "d", "d", "o", 2)
		_comp(G, AL)
	# corpo de ombros altos (o molde do tronco é ele inteiro) e perna de perto
	var B := _nova()
	_bmp(B, bx, by0, _CV_CORPO)
	_tr = B.duplicate()
	for i in 4:   # falhas de pena: pele nua rosada
		_tp(B, bx + [7, 8, 8, 12][i], by0 + [9, 9, 10, 12][i], "N")
	_comp(G, B)
	_comp(G, L2)
	# asa de perto: dobrada com as primárias esfiapadas passando da anca, ou aberta
	var W := _nova()
	if ala == 0 and int(g["dor"]) > 0:
		ala = 1   # dor: a asa de perto se solta meio aberta
	if ala > 0:
		_asa_aberta(W, bx + bw - 6, by0 + 2, ala, 16, "l", "m", "d", 2)
	else:
		_bmp(W, bx - 4, by0 + 2, _CV_ASA)
	_comp(G, W)
	# papo de penas arrepiadas (barba de corvo velho) e cabeça grisalha de sobrancelha branca
	var BA := _nova()
	_bmp(BA, hx, hy + 9, _CV_BARBA)
	BichoPx.tirar(_tr, _W, _H, hx + _OX, hy + 9 + _OY, _CV_BARBA)
	_comp(G, BA)
	var H := _nova()
	var cab: Array = _cab_rows(3, ch, g["boca"])
	_bmp(H, hx, hy, cab)
	BichoPx.tirar(_tr, _W, _H, hx + _OX, hy + _OY, cab)
	_comp(G, H)
	# bengala de cabo curvo, segura pela ponta da asa: bate no chão ao andar, avança na bicada
	var cx0: int = bx + bw + 8 + ei
	if g["andando"]:
		cx0 += [0, 1, 2, 2, 1, 0][q]
	var lift: int = 0
	if g["andando"]:
		lift = [0, 2, 2, 0, 0, 0][q]
	var ctop: int = by0 + 10
	var cxt: int = cx0 - 1 - ei / 2
	var MA := _nova()
	_trazo(MA, bx + bw - 6, by0 + 9, cxt - 3, ctop - 1, 2, "m")
	_rect(MA, cxt - 4, ctop - 2, 3, 3, "d")
	_comp(G, MA)
	var S := _nova()
	_trazo(S, cx0, -2 - lift, cxt, ctop, 2, "z")
	_bmp(S, cxt - 4, ctop - 3, [".zzzz.", "zZ..zz", "z....z"])
	_rect(S, cxt, ctop + 1, 2, 1, "Y")   # anel de ouro
	_comp(G, S)
	# monóculo de ouro com correntinha (sem contorno)
	var MO := _nova()
	var mx: int = hx + int(ch["ex"]) - 1
	var my: int = hy + int(ch["ey"]) - 1
	for i in 4:
		_px(MO, mx + i, my, "Y")
		_px(MO, mx + i + 1, my + 4, "y")
		_px(MO, mx, my + i + 1, "Y")
		_px(MO, mx + 4, my + i, "y")
	for i in 7:
		_px(MO, mx - 1 - i / 3, my + 5 + i, "Y" if i % 2 == 0 else "y")
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
	BichoPx.sprite(c, s, _pal(int(g["ct"]), alfa), f)

## Quadro em cache do chefe nesta pose (sprite "l", molde do tronco "t", crânio "c"), para as roupas acompanharem o desenho.
static func quadro(chefe_tipo: int, anim: float, andando: bool, golpe: float, parado: bool) -> Dictionary:
	var g: Dictionary = _geo(chefe_tipo, anim, andando, golpe, parado)
	var k: String = _chave(g)
	if not _cache.has(k):
		_cache[k] = _monta(g)
	return _cache[k]
