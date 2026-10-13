class_name BichoPxC
extends RefCounted
## Chefes do segundo ato (fora da casa), em pixel art: 5 Toupeira Mineira, 6 Gambá Fedido, 7 Coruja da Meia-Noite,
## 8 Vira-Lata Chefão, 9 Texugo Rei (ver BichoPx para as convenções: olhando para a direita, patas no chão em y = 0).
## Cada chefe é montado com o pincel `BichoPxB._K` (elipses com volume, traços com contorno) e alguns bitmaps de texto,
## com contorno quase preto de 1 pixel, 2 tons de corpo e 1 de luz. A pose sai de `_pose` e as âncoras das roupas de `_anc`,
## usada por `desloc`, para a roupa nunca se descolar do corpo.
## Chefe ainda sem desenho próprio cai no desenho do chefe antigo de índice (chefe_tipo - 5).

const PRIMEIRO := 5   # índice do primeiro chefe deste arquivo

# --- Toupeira Mineira
const TP_O := Color("#1a121c")
const TP_A := Color("#3a2f3c")
const TP_B := Color("#5a4a5a")
const TP_L := Color("#85738a")
const TP_P := Color("#e39a9a")
const TP_PS := Color("#b5636f")
const GARRA := Color("#f1e6c4")
const GARRA_S := Color("#a89868")
const CAP_Y := Color("#f4c21f")
const CAP_L := Color("#fff08a")
const CAP_S := Color("#b8860f")
const LAMPADA := Color("#fffbd0")
const METAL := Color("#8d98a4")
const TERRA := Color("#6d4c30")
const TERRA_S := Color("#43301f")
const TERRA_L := Color("#946b44")

# --- Gambá Fedido
const GA_O := Color("#050408")
const GA_A := Color("#15121b")
const GA_B := Color("#2d2837")
const GA_L := Color("#4a4258")
const GA_W := Color("#f4f2f6")
const GA_WS := Color("#b9b8cc")
const GA_NARIZ := Color("#d67b8a")
const GA_OLHO := Color("#ffe14a")
const FEDOR := Color("#8fe04a")
const FEDOR_S := Color("#5fae2c")

# --- Coruja da Meia-Noite
const CR_O := Color("#140d08")
const CR_A := Color("#4a3320")
const CR_B := Color("#6f5136")
const CR_L := Color("#a07c52")
const CR_V := Color("#dcc7a0")
const CR_VS := Color("#b09468")
const CR_M := Color("#8a6a44")
const CR_OLHO := Color("#ffd21a")
const CR_OLHO_S := Color("#e08a10")
const CR_BICO := Color("#f0a81c")
const CR_BICO_S := Color("#a86a0c")
const CR_ASA := Color("#3a2818")

# --- Vira-Lata Chefão
const VL_O := Color("#1c120a")
const VL_A := Color("#8a6038")
const VL_B := Color("#b98652")
const VL_L := Color("#e0b67e")
const VL_P := Color("#5e3b20")
const VL_PS := Color("#3f2614")
const VL_V := Color("#eadfc8")
const VL_LINGUA := Color("#e8607c")
const VL_LINGUA_S := Color("#b83a58")
const VL_COLEIRA := Color("#26262e")
const VL_PREGO := Color("#d8dde6")
const VL_PREGO_S := Color("#7e8696")

# --- Texugo Rei
const TX_O := Color("#121218")
const TX_A := Color("#4c4c5a")
const TX_B := Color("#7d7d8a")
const TX_L := Color("#b4b4c2")
const TX_K := Color("#26262e")
const TX_KL := Color("#44444f")
const TX_W := Color("#f2f2f6")
const TX_WS := Color("#b4b4c8")
const TX_OLHO := Color("#ffd23a")

const COROA := BichoPxB.COROA
const COROA_S := BichoPxB.COROA_S
const GEMA := BichoPxB.GEMA
const COROA_BM: Array = BichoPxB.COROA_BM

const PAL_CAP := {"o": TP_O, "Y": CAP_Y, "l": CAP_L, "y": CAP_S, "g": METAL, "W": LAMPADA}

# Capacete de mineiro (16 colunas por 7 linhas), com a lanterna na frente (à direita).
const CAPACETE: Array = [
	".....oooooo.....",
	"...ooYYlYYYoo...",
	"..oYYYllYYYYYo..",
	".oYYYYYYYYYYYYo.",
	"oYYYYYYYYYYYoggo",
	"oyyyyyyyyyyyyoWo",
	".oooooooooooooo.",
]


# --- bitmaps (letras: o = contorno, a = tom escuro, b = tom médio, c/l = luz, w = branco, v = branco na sombra, p/q = rosa, n = nariz, y = amarelo, e = olho)
# Toupeira: corpo de 24 colunas por 16 linhas (tronco de veludo, sem a cabeça)
const TP_CORPO: Array = [
	"......oooooooooooo......",
	"....ooabbbbbbbbbbboo....",
	"...oabbbcccbbbbbbbbbo...",
	"..oabbbcccccbbbbbbbbbo..",
	".oabbbbccccbbbbbbbbbbbo.",
	".oabbbbbbbbbbbbbbbbbbbo.",
	"oaabbbbbbbbbbbbbbbbbbbbo",
	"oaabbbbbbbbbbbbbbbbbbbbo",
	"oaaabbbbbbbbbbbbbbbbbbbo",
	"oaaabbbbbbbbbbbbbbbbbbao",
	"oaaaabbbbbbbbbbbbbbbbaao",
	".oaaaabbbbbbbbbbbbbbaaao",
	".oaaaaabbbbbbbbbbbbaaaao",
	"..oaaaaaaabbbbbbaaaaaao.",
	"...ooaaaaaaaaaaaaaaaoo..",
	".....oooooooooooooooo...",
]
# Toupeira: cabeça de 19 colunas por 12 linhas, focinho rosa comprido, dentes e olhinho
const TP_CAB: Array = [
	"....oooooooo.......",
	"...oabbbbbbbo......",
	"..oabbbbbbbbbo.....",
	".oabbbbbbbbbbboo...",
	".oabbbbbbbbbbbppoo.",
	".oabbbbwebbbbbpppno",
	".oabbbbbbbbbbppppqo",
	"..oabbbbbbbbbppppoo",
	"..oaabbbbbbbbbpqoo.",
	"...oaabbbbbwwboo...",
	"....ooaaaaaaaoo....",
	"......ooooooo......",
]
# Gambá: corpo de 24 colunas por 11 linhas, listra branca no alto das costas
const GA_CORPO: Array = [
	"...oooooooooooooooooo...",
	"..owwwwwwwwwwwwwwwwwwo..",
	"..ovvvvvvvvvvvvvvvvvvo..",
	".olllbbbbbbbbbbbbbbbbbo.",
	"olbbbbbbbbbbbbbbbbbbbbao",
	"obbbbbbbbbbbbbbbbbbbbbao",
	"oabbbbbbbbbbbbbbbbbbbaao",
	"oaabbbbbbbbbbbbbbbbbaaao",
	".oaaabbbbbbbbbbbbbaaaao.",
	"..oaaaaaaaaaaaaaaaaaao..",
	"...oooooooooooooooooo...",
]
# Gambá: cabeça de 17 colunas por 11 linhas, focinho fino, listra branca da testa ao focinho, orelhas redondas
const GA_CAB: Array = [
	"..oo...oo........",
	".opao.oaao.......",
	".oaaoooaaoo......",
	"oaabbwwwwaaoo....",
	"oaabbbwwwwaaaoo..",
	"oaaabbbwwwaaaaaoo",
	"oaaaabbbwoyyaaaao",
	"oaaaaabbbaaaaanno",
	".oaaaaaaaaaaaoooo",
	"..ooaaaaaaaaoo...",
	"....oooooooo.....",
]

# Vira-lata: cabeça de lado (Q = orelha caída, v = focinho claro, k = nariz)
const VL_CAB: Array = [
	"....oooooooo............",
	"...oabbbbbbbbo..........",
	"..oabbbbbbbbbbo.........",
	".oabbbbbbbbbbbboooooo...",
	".oabbbbbbbbbbblvvvvvvoo.",
	"oQabbbbbbbbbbbvvvvvvvkko",
	"oQQabbbbbbbbbbvvvvvvvkko",
	"oQQabbbbbbbbbbbvvvvvvoo.",
	"oQQQabbbbbbbbbbaaaaaao..",
	"oQQQabbbbbbbbbbbooooo...",
	".oQQabbbbbbbbbbo........",
	".oQQaabbbbbbbbo.........",
	"..oQQoaaaaaaao..........",
	"...ooo.ooooooo..........",
]
# Texugo: cabeça preta com duas listras brancas (K = luz, w/v = listra, n = nariz)
const TX_CAB: Array = [
	"....ooooooooooooo....",
	"..ooKkkkkkkkkkkkkoo..",
	".oKkkkwwwwwwkkkkkkkoo",
	"oKkkkkvvwwwwwwwwkkkko",
	"oKkkkkkkvvvvvvvvwwkko",
	"oKkkkkkkkkkkkkkkkkkko",
	"oKkkkkkkkkkkkkkkkkkko",
	"oKkkkkwwwwwwwwkkkkkko",
	"oKkkkkkvvvvvvvkkkknno",
	".okkkkkkkkkkkkkkkknno",
	".okkkkkkkkkkkkkkkkoo.",
	"..ookkkkkkkkkkkkkoo..",
	"....ooooooooooooo....",
]
# Coruja: cabeça com orelhas de pena, disco facial claro, dois olhos amarelos (O = aro do olho, i = pupila) e bico
const CR_CAB: Array = [
	"..oo.......oo...........",
	"..oao.....oao...........",
	"..oabo...oabo...........",
	"..oabbooooabbo..........",
	".oabbbbbbbbbbbboo.......",
	"oabbbvvvvvvvvvvvvo......",
	"oabbvvvvvvvvvvvvvvo.....",
	"oabbvvOyyOvvOyyOvvo.....",
	"oabbvvyyiyvvyyiyvvvkko..",
	"oabbvvyiiyvvyiiyvvkKko..",
	"oabbbvvyyOvvyyOvvvvkKo..",
	".oabbbvvvvvvvvvvvvvooo..",
	".oaabbbvvsvsvsvvvvvo....",
	"..oaabbbbbbbbbbbboo.....",
	"....ooooooooooooo.......",
]
# Coruja: peito claro com penugem em V (m = marca, s = sombra)
const CR_PEITO: Array = [
	"..vvvvv..",
	".vvvvvvv.",
	"vvvvvvvvv",
	"vvmvvvmvv",
	"vvvmvmvvv",
	"vvvvmvvvv",
	"vvvvvvvvv",
	"vvmvvvmvv",
	"vvvmvmvvv",
	"vvvvmvvvs",
	"vvvvvvvvs",
	"vvmvvvmvs",
	"vvvmvmvss",
	".vvvmvvss",
	".vvvvvvs.",
	"..vvvvs..",
	"...ssss..",
]

# Vira-lata: tronco, coxa e peito fundo (P = mancha, V = peito claro) (origem x = -16, y = -24)
const VL_CORPO: Array = [
	"..............................",
	"....................oooo......",
	"...................ollllo.....",
	"........ooooooooooolbbbblo....",
	".....ooolllllllllllbbbbbblo...",
	"....olllPPPPPPPPbbbbbbbbbblo..",
	"...olbbbbPPPPPPbbbbbbbbbbbbo..",
	"..olbbbbbbbPPbbbbbbbbbbbbbbo..",
	"..obbbbbbbbbbbbbbbbbbbbbbbbo..",
	"..obbbbbbbbbbbbbbbbbbbbbbbbo..",
	"..obbbbbbbbbbbbbbbbbbbbbbbbo..",
	"..obbbbbbbbbbbbbbbbbbbVVbbbo..",
	"..obbbbbbbbaaaaaabbbbVVVVbbo..",
	"..oabbbbbbaaaaaaaabbVVVVVVao..",
	"..oaabbbbaaooooooaabVVVVVVao..",
	"...oaaaaaao......oaaVVVVVVo...",
	"....oaaaao........oaVVVVVo....",
	".....oooo..........oaVVVo.....",
	"....................oooo......",
	"..............................",
]
const VL_CORPO_X := -16
const VL_CORPO_Y := -24
# Texugo: corpo roliço grisalho com o rabo (origem x = -19, y = -23)
const TX_CORPO: Array = [
	"................................",
	"................................",
	"............oooooooooooo........",
	"..........oollbllllblllloo......",
	"........oolllbllllbllllblloo....",
	".......ollllbbbbbbbbblablllbo...",
	"......olllbabbbblbbbbbbbabbllo..",
	"......olbbblbabbbbbbbblbbbablo..",
	"...ooolbbbbbbbbablbbbbbbbbbblbo.",
	"..obllbbbbbblbbbbabbbbblbbbbbbo.",
	"..olllalbbbbbbbbbblabbbbbbbbblo.",
	"..oaaaababbbblbbbbbbbabblbbbbao.",
	"..oaaaaalbabbbbbbbblbbbabbbbaao.",
	"...oooaaaabbablbbbbbbbbbblaaao..",
	"......oaaaaabbabbbbblbbbaaaaao..",
	".......oaaaaaaaaaaaaaaaaaaaao...",
	"........ooaaaaaaaaaaaaaaaaoo....",
	"..........ooaaaaaaaaaaaaoo......",
	"............oooooooooooo........",
	"................................",
	"................................",
]
const TX_CORPO_X := -19
const TX_CORPO_Y := -23
# Coruja: corpo alto de penas (origem x = -11, y = -28)
const CR_CORPO: Array = [
	"......................",
	"........oooooo........",
	"......oolllllloo......",
	".....ollbbbbbbllo.....",
	"....olbbabbabbaalo....",
	"....olbbbbbbbbbaao....",
	"...olbbbbbbbbbbbaao...",
	"...olabbabbabbabaao...",
	"..olbbbbbbbbbbbbbaao..",
	"..olbbbbbbbbbbbbbaao..",
	"..olbabbabbabbabbaao..",
	"..olbbbbbbbbbbbbbaao..",
	"..olbbbbbbbbbbbbbaao..",
	"..olbabbabbabbabbaao..",
	"..olbbbbbbbbbbbbbaao..",
	"..olbbbbbbbbbbbbbaao..",
	"..olbabbabbabbabbaao..",
	"..olbbbbbbbbbbbbbaao..",
	"...olbbbbbbbbbbbaao...",
	"...olabbabbabbabaao...",
	"....olbbbbbbbbbaao....",
	"....olaabbbbbbaaao....",
	".....olaaaaaaaaao.....",
	"......ooaaaaaaoo......",
	"........oooooo........",
	"......................",
]
const CR_CORPO_X := -11
const CR_CORPO_Y := -28

# ---------------------------------------------------------------------------------------------

## Pose comum a `desenhar` e `desloc`: quadro do passo e força do golpe (0..1).
static func _pose(anim: float, andando: bool, golpe: float) -> Dictionary:
	var fr: int = 0
	var sn: float = 0.0
	if andando:
		fr = int(anim * 1.3) % 4
	if golpe > 0.0:
		sn = sin(PI * clampf(1.0 - golpe / 0.22, 0.0, 1.0))
	return {"fr": fr, "sn": sn, "and": andando}

## Âncoras das roupas (na ordem de RoupaGato.Onde), em pixels do bicho, na pose atual.
static func _anc(ct: int, p: Dictionary, parado: bool) -> Array[Vector2]:
	var fr: int = p["fr"]
	var sn: float = p["sn"]
	var a: Array[Vector2] = []
	match ct:
		5:
			if parado:
				return [Vector2(9, -14), Vector2(6, -9), Vector2(12, -9), Vector2(1, -9), Vector2(8, -9), Vector2(0, 0), Vector2(10, -9)]
			var L: int = [0, 1, 0, 1][fr] if p["and"] else 0
			var hx: int = roundi(4.0 * sn)
			a = [Vector2(10 + hx, -26 - L), Vector2(-2, -11 - L), Vector2(20 + hx, -13 - L), Vector2(-11, -15 - L),
				Vector2(5 + hx / 2, -12 - L), Vector2(0, 0), Vector2(15 + hx, -17 - L)]
		6:
			var L6: int = [0, 1, 0, 1][fr] if p["and"] else 0
			var hx6: int = roundi(4.0 * sn)
			a = [Vector2(12 + hx6, -20 - L6), Vector2(-1, -12 - L6), Vector2(19 + hx6, -13 - L6), Vector2(-9, -15 - L6),
				Vector2(6 + hx6 / 2, -12 - L6), Vector2(0, 0), Vector2(14 + hx6, -14 - L6)]
		7:
			var voa: bool = p["and"]
			if not voa and p["sn"] <= 0.35:
				return [Vector2(0, -37), Vector2(0, -15), Vector2(2, -25), Vector2(-8, -9), Vector2(0, -21), Vector2(0, 0), Vector2(0, -28)]
			var L7: int = (5 + [0, 1, 0, -1][fr]) if voa else 0
			var hx7: int = roundi(3.0 * sn)
			a = [Vector2(3 + hx7, -34 - L7), Vector2(0, -15 - L7), Vector2(14 + hx7, -25 - L7), Vector2(-8, -9 - L7),
				Vector2(1 + hx7 / 2, -21 - L7), Vector2(0, -L7), Vector2(7 + hx7, -27 - L7)]
		8:
			var L8: int = [0, 1, 0, 1][fr] if p["and"] else 0
			var hx8: int = 1 if parado else roundi(4.0 * sn)
			var hy8: int = 6 if parado else roundi(sn)
			a = [Vector2(11 + hx8, -29 - L8 + hy8), Vector2(-1, -14 - L8), Vector2(24 + hx8, -22 - L8 + hy8), Vector2(-11, -19 - L8),
				Vector2(8 + hx8 / 2, -19 - L8 + hy8 / 2), Vector2(0, 0), Vector2(12 + hx8, -24 - L8 + hy8)]
		9:
			var L9: int = [0, 1, 0, 1][fr] if p["and"] else 0
			var hx9: int = roundi(4.0 * sn)
			a = [Vector2(13 + hx9, -19 - L9), Vector2(-2, -12 - L9), Vector2(23 + hx9, -12 - L9), Vector2(-12, -16 - L9),
				Vector2(7 + hx9 / 2, -12 - L9), Vector2(0, 0), Vector2(14 + hx9, -14 - L9)]
	return a

static func desloc(onde: int, familia: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Vector2:
	var ct: int = chefe_tipo
	if ct < PRIMEIRO or ct > 9:
		return Vector2.ZERO
	var a: Array[Vector2] = _anc(ct, _pose(anim, andando, golpe), parado)
	if a.is_empty():
		var q: int = ct - PRIMEIRO
		if q <= 2:
			return BichoPxA.desloc(onde, q, tipo, anim, andando, golpe, q, parado)
		return BichoPxB.desloc(onde, q, tipo, anim, andando, golpe, q, parado)
	if onde == RoupaGato.Onde.PATAS:
		return a[onde]
	return a[onde] - RoupaGato.ORIGEM[onde]

static func desenhar(c: CanvasItem, familia: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var k := BichoPxB._K.new(c, f, alfa)
	var p: Dictionary = _pose(anim, andando, golpe)
	match chefe_tipo:
		5:
			_toupeira(k, p, anim, parado)
		6:
			_gamba(k, p, anim)
		7:
			_coruja(k, p)
		8:
			_vira_lata(k, p, parado)
		9:
			_texugo(k, p)
		_:
			var q: int = chefe_tipo - PRIMEIRO
			if q <= 2:
				BichoPxA.desenhar(c, q, tipo, anim, andando, golpe, f, alfa, carregando, filhote, q, parte, parado)
			else:
				BichoPxB.desenhar(c, q, tipo, anim, andando, golpe, f, alfa, carregando, filhote, q, parte, parado)

# ----------------------------------------------------------------------------------------------

## Meia elipse (só acima do chão, y < 0) com contorno, para montinhos.
static func _meia(k: BichoPxB._K, cx: float, rx: float, ry: float, col: Color, out: Color) -> void:
	for pas in 2:
		var rr: float = rx + (1.0 if pas == 0 else 0.0)
		var ry2: float = ry + (1.0 if pas == 0 else 0.0)
		var cor: Color = out if pas == 0 else col
		for j in range(int(-ceil(ry2)), 0):
			var dy: float = (float(j) + 0.5) / ry2
			if absf(dy) >= 1.0:
				continue
			var hw: float = rr * sqrt(1.0 - dy * dy)
			var x0: float = roundf(cx - hw)
			var x1: float = roundf(cx + hw)
			if x1 > x0:
				k.r(x0, float(j), x1 - x0, 1.0, cor)

# ------------------------------------------------- TOUPEIRA MINEIRA -------------------------------------------------

static func _toupeira(k: BichoPxB._K, p: Dictionary, anim: float, parado: bool) -> void:
	var fr: int = p["fr"]
	var sn: float = p["sn"]
	if parado:
		_monte(k, anim)
		return
	var L: int = [0, 1, 0, 1][fr] if p["and"] else 0
	var hx: int = roundi(4.0 * sn)
	var hy: int = roundi(sn)
	var pal: Dictionary = {"o": TP_O, "a": TP_A, "b": TP_B, "c": TP_L, "p": TP_P, "q": TP_PS, "n": TP_PS, "w": Color("#ffffff"), "e": TP_O}
	# pés de trás
	var pe: int = [0, 2, 0, -2][fr] if p["and"] else 0
	k.el(-9.0 + pe, -1.5, 2.5, 1.5, TP_PS, TP_O)
	k.el(-2.0 - pe, -1.5, 2.5, 1.5, TP_P, TP_O)
	# braço de trás (longe)
	var bx: int = 2 + ([0, 1, 2, 1][fr] if p["and"] else 0)
	k.vol(float(bx), -7.0 - L, 3.0, 4.0, TP_A, TP_B, TP_O, TP_O)
	k.lin(float(bx + 3), -6.0 - L, float(bx + 8), -5.0 - L, 1.0, GARRA_S, TP_O)
	# corpo gordo e cabeça, em bitmap
	k.spr(-15, -17 - L, TP_CORPO, pal)
	k.r(-17, -9 - L, 3, 2, TP_O)
	k.r(-16, -9 - L, 2, 1, TP_P)
	k.spr(3 + hx, -24 - L + hy, BichoPxB._est(TP_CAB, [10, 11], [3, 4]), pal)
	k.r(10 + hx, -18 - L + hy, 4, 1, TP_O)      # sobrancelha mal-encarada
	# capacete com lanterna e feixe de luz
	var cx0: int = 2 + hx
	var cy0: int = -28 - L + hy
	k.spr(cx0, cy0, CAPACETE, PAL_CAP)
	var lx: int = cx0 + 16
	var ly: int = cy0 + 5
	for i in 4:
		k.r(lx + i * 3, ly - i, 3, 1 + 2 * i, Color(1.0, 0.93, 0.4, 0.28 - 0.05 * i))
	# braço da frente com garras enormes
	var ax: int = 5 + ([0, 2, 3, 1][fr] if p["and"] else 0) + roundi(5.0 * sn)
	var ay: int = -6 - L - roundi(3.0 * sn)
	k.vol(float(ax), float(ay), 3.5, 4.5, TP_B, TP_L, TP_A, TP_O)
	k.el(float(ax + 3), float(ay + 1), 2.5, 2.8, TP_P, TP_O)
	k.lin(float(ax + 4), float(ay - 1), float(ax + 10), float(ay - 3), 1.0, GARRA, TP_O)
	k.lin(float(ax + 5), float(ay + 1), float(ax + 11), float(ay + 1), 1.0, GARRA, TP_O)
	k.lin(float(ax + 4), float(ay + 3), float(ax + 9), float(ay + 6), 1.0, GARRA, TP_O)

## Toupeira debaixo da terra: só o montinho com o capacete aparecendo.
static func _monte(k: BichoPxB._K, anim: float) -> void:
	var bob: int = 1 if sin(anim * 0.9) > 0.3 else 0
	k.spr(-5, -17 - bob, CAPACETE.slice(0, 6), PAL_CAP)
	var lx: int = 11
	var ly: int = -17 - bob + 5
	for i in 3:
		k.r(lx + i * 3, ly - i, 3, 1 + 2 * i, Color(1.0, 0.93, 0.4, 0.28 - 0.06 * i))
	_meia(k, 0.0, 15.0, 8.0, TERRA, TERRA_S)
	# volume: luz no alto, sombra embaixo e torrões
	for j in range(-7, -3):
		var hw: float = 11.0 * sqrt(1.0 - pow((float(j) + 3.0) / 7.0, 2.0)) * 0.8
		k.r(roundf(-hw - 3.0), float(j), roundf(hw), 1.0, TERRA_L)
	k.r(-11, -3, 22, 2, TERRA_S)
	for t in [Vector2(-9, -5), Vector2(-4, -3), Vector2(4, -6), Vector2(8, -4), Vector2(11, -2), Vector2(-12, -2)]:
		k.r(t.x, t.y, 2, 1, TERRA_S)
		k.r(t.x + 1, t.y - 1, 1, 1, TERRA_L)
	# torrões soltos ao lado e farelo
	k.r(-19, -2, 3, 2, TERRA_S)
	k.r(-18, -2, 1, 1, TERRA_L)
	k.r(17, -2, 2, 2, TERRA_S)
	k.r(-22, -1, 1, 1, TERRA)
	k.r(21, -1, 2, 1, TERRA)

# ---------------------------------------------------- pedaços comuns ----------------------------------------------------

## Perna curta com contorno: topo em `ytop`, pé a `lift` pixels do chão (y = -lift é a linha logo abaixo do pé), dedo para a frente.
static func _perna(k: BichoPxB._K, x: int, ytop: int, lift: int, w: int, col: Color, out: Color) -> void:
	var yb: int = -lift
	if yb - ytop <= 1:
		return
	k.r(x - 1, ytop, w + 3, yb - ytop, out)
	k.r(x, ytop, w, yb - ytop - 1, col)
	k.r(x, yb - 2, w + 1, 1, col)

## Faixa que acompanha o alto de uma elipse (cx, cy, rx, ry) de x0 a x1, começando `desce` linhas abaixo do contorno, com `esp` linhas de grossura.
static func _banda(k: BichoPxB._K, cx: float, cy: float, rx: float, ry: float, x0: int, x1: int, desce: int, esp: int, col: Color, sombra: Color) -> void:
	for x in range(x0, x1 + 1):
		var dx: float = (float(x) + 0.5 - cx) / rx
		if absf(dx) >= 1.0:
			continue
		var yt: int = int(roundf(cy - ry * sqrt(1.0 - dx * dx)))
		k.r(x, yt + desce, 1, esp - 1, col)
		k.r(x, yt + desce + esp - 1, 1, 1, sombra)

# ----------------------------------------------------- GAMBÁ FEDIDO -----------------------------------------------------

## Tira `n` colunas de um bitmap a partir da coluna `de` (encurta o corpo sem refazer o desenho).
static func _sem_cols(linhas: Array, de: int, n: int) -> Array:
	var sai: Array = []
	for l in linhas:
		var t: String = l
		sai.append(t.substr(0, de) + t.substr(de + n))
	return sai

static func _gamba(k: BichoPxB._K, p: Dictionary, anim: float) -> void:
	var fr: int = p["fr"]
	var sn: float = p["sn"]
	var andando: bool = p["and"]
	var L: int = [0, 1, 0, 1][fr] if andando else 0
	var hx: int = roundi(4.0 * sn)
	var hy: int = roundi(sn)
	var la: int = [0, 1, 0, 0][fr] if andando else 0
	var lb: int = [0, 0, 0, 1][fr] if andando else 0
	var pal: Dictionary = {"o": GA_O, "a": GA_A, "b": GA_B, "l": GA_L, "w": GA_W, "v": GA_WS, "y": GA_OLHO, "n": GA_NARIZ, "p": GA_NARIZ}
	# pernas de longe (mais escuras)
	_perna(k, -7, -6 - L, lb, 2, GA_A, GA_O)
	_perna(k, 5, -6 - L, la, 2, GA_A, GA_O)
	# rabo enorme levantado, atrás do corpo
	var sway: int = ([0, 1, 0, -1][fr] if andando else 0) - roundi(3.0 * sn)
	_rabo(k, -10, -10 - L, 24, sway)
	_perna(k, -11, -6 - L, la, 2, GA_B, GA_O)
	_perna(k, 1, -6 - L, lb, 2, GA_B, GA_O)
	# corpo comprido com a listra branca, e cabeça pontuda, em bitmap
	k.spr(-11, -18 - L, _sem_cols(BichoPxB._est(GA_CORPO, [], [5, 6]), 7, 4), pal)
	k.spr(4 + hx, -21 - L + hy, GA_CAB, pal)
	k.r(10 + hx, -15 - L + hy, 3, 1, GA_O)        # sobrancelha pesada
	k.r(12 + hx, -14 - L + hy, 1, 1, GA_O)        # pupila
	if sn > 0.4:
		k.r(14 + hx, -12 - L + hy, 4, 1, GA_NARIZ)
		k.r(15 + hx, -11 - L + hy, 1, 1, GA_W)
	else:
		k.r(14 + hx, -12 - L + hy, 3, 1, GA_O)
		k.r(16 + hx, -13 - L + hy, 1, 1, GA_W)    # dentinho de lado
	_fedor(k, anim, L)

## Rabo-plumeiro: coluna de `alt` linhas que sobe da anca em (bx, by), larga no meio, com listra branca no centro.
static func _rabo(k: BichoPxB._K, bx: int, by: int, alt: int, sway: int) -> void:
	var cx: Array[float] = []
	var hw: Array[float] = []
	for j in alt:
		var t: float = float(j) / float(alt - 1)    # 0 = ponta, 1 = raiz
		var larg: float = 0.8 + 6.4 * sin(PI * pow(t, 0.7))
		if t > 0.8:
			larg = maxf(larg, 3.2)
		larg += 1.0 if (j * 7) % 5 == 0 else 0.0     # pelo arrepiado
		hw.append(larg)
		cx.append(float(bx) - 4.0 * sin(PI * (1.0 - t)) + 2.5 * (1.0 - t) + float(sway) * (1.0 - t))
	for pas in 2:
		for j in range(-1, alt + 1):
			var jj: int = clampi(j, 0, alt - 1)
			var w: float = hw[jj] + (1.0 if pas == 0 else 0.0)
			var x0: float = roundf(cx[jj] - w)
			var x1: float = roundf(cx[jj] + w)
			var y: float = float(by - alt + j)
			if pas == 0:
				k.r(x0, y, x1 - x0, 1.0, GA_O)
			elif j >= 0 and j < alt:
				k.r(x0, y, x1 - x0, 1.0, GA_B)
				k.r(x0, y, 1.0, 1.0, GA_L)
				k.r(x1 - 2.0, y, 2.0, 1.0, GA_A)
				var t2: float = float(j) / float(alt - 1)
				if t2 > 0.1 and t2 < 0.97:
					var ww: float = hw[jj] * 0.4
					var w0: float = roundf(cx[jj] + 0.5 - ww)
					var w1: float = roundf(cx[jj] + 0.5 + ww)
					k.r(w0, y, w1 - w0, 1.0, GA_W)
					k.r(w1 - 1.0, y, 1.0, 1.0, GA_WS)

## Fiapos de fedor esverdeado subindo, ondulando devagar.
static func _fedor(k: BichoPxB._K, anim: float, L: int) -> void:
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var bases: Array = [-17, -4, 6, 14]
	for w in bases.size():
		var bx: float = float(bases[w])
		var fase: float = fmod(t * 0.9 + float(w) * 0.37, 1.0)
		for i in 9:
			var h: float = float(i) * 3.0 + fase * 3.0
			var y: float = -22.0 - float(L) - h - float(w % 2) * 4.0
			var x: float = bx + roundf(sin(h * 0.45 + float(w) * 2.0 + t * 2.0) * 2.0)
			var al: float = clampf(1.0 - float(i) * 0.11, 0.0, 1.0)
			k.r(x, y, 2, 2, Color(FEDOR.r, FEDOR.g, FEDOR.b, al))
			k.r(x + 1.0, y + 1.0, 1, 1, Color(FEDOR_S.r, FEDOR_S.g, FEDOR_S.b, al * 0.7))

# ------------------------------------------------ CORUJA DA MEIA-NOITE ------------------------------------------------

## Asa cheia: lâmina que sai do ombro (sx, sy) a `ang` graus acima da horizontal, para trás, `comp` de comprimento e `ancho` de largura.
## Ombro largo, borda de ataque clara, miolo no tom-base, borda de fuga escura e recortada, penas primárias separadas por frestas na ponta.
static func _asa(k: BichoPxB._K, sx: float, sy: float, ang: float, comp: float, ancho: float, base: Color, luz: Color, sombra: Color) -> void:
	var r: float = deg_to_rad(ang)
	var d := Vector2(-cos(r), -sin(r))
	var n := Vector2(sin(r), -cos(r))
	var raio: int = int(ceil(comp + ancho)) + 2
	var lado: int = raio * 2 + 1
	var x0: int = int(floor(sx)) - raio
	var y0: int = int(floor(sy)) - raio
	var g := PackedByteArray()
	g.resize(lado * lado)
	for j in lado:
		for i in lado:
			var dx: float = float(x0 + i) + 0.5 - sx
			var dy: float = float(y0 + j) + 0.5 - sy
			var u: float = dx * d.x + dy * d.y
			var v: float = dx * n.x + dy * n.y
			var t: float = u / comp
			if t < 0.0 or t > 1.0:
				continue
			var w: float = ancho * (1.0 - 0.55 * t * t)
			if t > 0.86:
				w *= sqrt(maxf(0.0, 1.0 - pow((t - 0.86) / 0.14, 2.0)))
			var vmax: float = w * 0.42
			var vmin: float = -w * 0.58
			if t > 0.45:
				vmin += 2.0 * float(int(u / 3.0) % 2)
			if v < vmin or v > vmax:
				continue
			var q: float = (v - vmin) / maxf(0.1, vmax - vmin)
			var cod: int = 2
			if q > 0.78:
				cod = 1
			elif q < 0.3:
				cod = 3
			if t > 0.5 and int(floor(v + 20.0)) % 3 == 0 and q < 0.8:
				cod = 3
			g[j * lado + i] = cod
	var cores: Array = [Color(0, 0, 0, 0), luz, base, sombra]
	# contorno: vazio com vizinho preenchido
	for j in lado:
		var i: int = 0
		while i < lado:
			var cod: int = g[j * lado + i]
			var cor: Color
			if cod > 0:
				cor = cores[cod]
			else:
				var viz: bool = false
				for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var a: int = i + dd.x
					var b: int = j + dd.y
					if a >= 0 and a < lado and b >= 0 and b < lado and g[b * lado + a] > 0:
						viz = true
				if not viz:
					i += 1
					continue
				cod = 9
				cor = CR_O
			var n2: int = 1
			while i + n2 < lado:
				var c2: int = g[j * lado + i + n2]
				if cod == 9:
					if c2 > 0:
						break
					var viz2: bool = false
					for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var a2: int = i + n2 + dd.x
						var b2: int = j + dd.y
						if a2 >= 0 and a2 < lado and b2 >= 0 and b2 < lado and g[b2 * lado + a2] > 0:
							viz2 = true
					if not viz2:
						break
				elif c2 != cod:
					break
				n2 += 1
			k.r(float(x0 + i), float(y0 + j), float(n2), 1.0, cor)
			i += n2

## Coruja de frente (parada): corpo simétrico, asas dobradas dos dois lados, cara redonda com os dois olhos virados para quem olha.
static func _coruja_frente(k: BichoPxB._K) -> void:
	var piscar: bool = int(Time.get_ticks_msec() / 220) % 14 == 0
	# pés com garras
	for x in [-5, 2]:
		k.r(x - 1, -5, 5, 5, CR_O)
		k.r(x, -5, 3, 3, CR_V)
		k.r(x - 1, -2, 6, 2, CR_O)
		k.r(x - 1, -2, 5, 1, CR_BICO_S)
	# corpo e asas dobradas nas laterais (a de trás um pouco mais escura)
	k.vol(0.0, -14.0, 9.0, 11.0, CR_B, CR_L, CR_A, CR_O)
	k.vol(0.0, -12.0, 5.0, 8.0, CR_V, Color("#f2e6c8"), CR_VS, CR_O)
	for j in 4:
		k.r(-3 + (j % 2) * 3, -18 + j * 3, 2, 1, CR_M)
	k.vol(-8.0, -14.0, 3.5, 9.0, CR_A, CR_B, CR_ASA, CR_O)
	k.vol(8.0, -14.0, 3.5, 9.0, CR_A, CR_B, CR_ASA, CR_O)
	for j in 3:
		k.r(-9 + 0, -9 + j * 3, 1, 2, CR_O)
		k.r(8, -9 + j * 3, 1, 2, CR_O)
	# cabeça larga com orelhas de pena
	var cx: float = 0.0
	var cy: float = -29.0
	for sx in [-1.0, 1.0]:
		k.r(cx + sx * 8.0 - 1.0, cy - 11.0, 3, 5, CR_O)
		k.r(cx + sx * 8.0 - (1.0 if sx < 0.0 else 0.0), cy - 10.0, 2, 4, CR_A)
	k.el(cx, cy, 11.0, 8.5, CR_B, CR_O)
	k.fill(cx - 5.0, cy, 5.0, 6.0, CR_V)
	k.fill(cx + 5.0, cy, 5.0, 6.0, CR_V)
	k.r(cx - 1.0, cy - 7.0, 2, 14, CR_VS)
	for sx in [-1.0, 1.0]:
		var ex: float = cx + sx * 5.0
		if piscar:
			k.r(ex - 2.0, cy - 1.0, 4, 1, CR_O)
		else:
			k.el(ex, cy - 1.0, 3.0, 3.0, CR_OLHO, CR_OLHO_S)
			k.r(ex - 1.0, cy - 2.0, 2, 3, CR_O)
			k.r(ex - 1.0, cy - 2.0, 1, 1, Color.WHITE)
		k.r(ex - 3.0 + (3.0 if sx < 0.0 else 0.0), cy - 5.0, 4, 1, CR_O)   # sobrancelha pesada
	k.r(cx - 1.0, cy + 1.0, 3, 1, CR_O)
	k.r(cx - 1.0, cy + 1.0, 2, 3, CR_BICO)
	k.r(cx - 1.0, cy + 3.0, 2, 1, CR_BICO_S)

static func _coruja(k: BichoPxB._K, p: Dictionary) -> void:
	var fr: int = p["fr"]
	var sn: float = p["sn"]
	var voa: bool = p["and"]
	if not voa and sn <= 0.35:
		_coruja_frente(k)
		return
	var abre: bool = voa or sn > 0.35
	var L: int = (5 + [0, 1, 0, -1][fr]) if voa else 0
	var hx: int = roundi(3.0 * sn)
	var hy: int = roundi(sn)
	var ang: float = [68.0, 30.0, -28.0, 26.0][fr] if voa else 62.0
	var sx: float = -1.0
	var sy: float = -21.0 - float(L)
	# asa de longe, atrás do corpo
	if abre:
		_asa(k, sx + 2.0, sy + 1.0, ang + 14.0, 20.0, 9.0, CR_A, CR_B, CR_ASA)
	# cauda de penas e pernas emplumadas com garras
	k.r(-8, -6 - L, 5, 6, CR_O)
	k.r(-7, -6 - L, 3, 5, CR_A)
	k.r(-6, -3 - L, 1, 2, CR_B)
	var ty: int = -L
	for x in [0, 5]:
		k.r(x - 1, ty - 5, 4, 5, CR_O)
		k.r(x, ty - 5, 2, 3, CR_V)
		k.r(x - 2, ty - 2, 6, 2, CR_O)
		k.r(x - 2, ty - 2, 5, 1, CR_BICO_S)
		k.r(x - 1, ty - 1, 1, 1, CR_O)
	# corpo alto e redondo, barriga arredondada, peito claro com penugem em V
	k.spr(CR_CORPO_X, CR_CORPO_Y - L, CR_CORPO, {"o": CR_O, "a": CR_A, "b": CR_B, "l": CR_L})
	k.spr(0, -23 - L, CR_PEITO, {"v": CR_V, "s": CR_VS, "m": CR_M})
	k.r(-1, -10 - L, 1, 3, CR_A)
	# asa de perto: dobrada no corpo (com sombra por baixo) ou aberta
	if abre:
		_asa(k, sx, sy, ang, 25.0, 12.0, CR_B, CR_L, CR_A)
	else:
		k.vol(-4.0, -13.0 - L, 5.0, 9.5, CR_B, CR_L, CR_A, CR_O)
		for j in 3:
			k.r(-7 + j * 2, -7 - L + (j % 2), 1, 3, CR_A)
		k.r(-8, -3 - L, 7, 1, CR_O)
		k.r(-6, -2 - L, 4, 1, CR_A)
	# cabeça em bitmap: orelhas de pena, disco facial, olhos e bico
	var x0: int = -7 + hx
	var y0: int = -34 - L + hy
	k.spr(x0, y0, CR_CAB, {"o": CR_O, "a": CR_A, "b": CR_B, "v": CR_V, "s": CR_VS, "y": CR_OLHO, "O": CR_OLHO_S, "i": CR_O, "k": CR_BICO, "K": CR_BICO_S})
	k.r(x0 + 7, y0 + 8, 1, 1, Color.WHITE)
	k.r(x0 + 12, y0 + 8, 1, 1, Color.WHITE)
	k.r(x0 + 5, y0 + 6, 4, 1, CR_O)                 # sobrancelha pesada
	k.r(x0 + 11, y0 + 6, 5, 1, CR_O)
	k.r(x0 + 9, y0 + 7, 1, 1, CR_O)
	if sn > 0.4:
		k.r(x0 + 19, y0 + 11, 3, 1, CR_BICO_S)

# ------------------------------------------------- VIRA-LATA CHEFÃO -------------------------------------------------

static func _vira_lata(k: BichoPxB._K, p: Dictionary, parado: bool) -> void:
	var fr: int = p["fr"]
	var sn: float = p["sn"]
	var andando: bool = p["and"]
	var t: float = float(Time.get_ticks_msec()) / 1000.0
	var L: int = [0, 1, 0, 1][fr] if andando else 0
	var hx: int = 1 if parado else roundi(4.0 * sn)
	var hy: int = 6 if parado else roundi(sn)
	var ofeg: int = 1 if (parado and sin(t * 9.0) > 0.0) else 0     # arfando: o peito sobe e desce
	var la: int = [0, 2, 1, 0][fr] if andando else 0
	var lb: int = [1, 0, 0, 2][fr] if andando else 0
	# patas de longe (mais escuras)
	_perna(k, -9, -9 - L, lb, 2, VL_A, VL_O)
	_perna(k, 9, -9 - L, la, 2, VL_A, VL_O)
	# rabo curto levantado (caído quando sem fôlego)
	var wag: int = [0, 1, 0, -1][fr] if andando else 0
	if parado:
		k.lin(-13.0, -14.0 - L, -17.0, -8.0, 2.0, VL_B, VL_O)
	else:
		k.lin(-13.0, -17.0 - L, float(-17 + wag), -24.0 - L, 2.0, VL_B, VL_O)
	# orelha de pé (a outra é a caída), atrás da cabeça
	k.lin(float(11 + hx), -27.0 - L + hy, float(12 + hx), -33.0 - L + hy, 2.0, VL_A, VL_O)
	# tronco fino na cintura, coxa grossa atrás e peito fundo na frente
	k.spr(VL_CORPO_X, VL_CORPO_Y - L + ofeg, VL_CORPO, {"o": VL_O, "a": VL_A, "b": VL_B, "l": VL_L, "P": VL_P, "V": VL_V})
	# coxa traseira marcada: massa clara com contorno e sombra, e peito fundo com contorno
	k.vol(-9.0, -11.0 - float(L), 5.0, 5.5, VL_B, VL_L, VL_A, VL_O)
	k.r(-5, -15 - L, 1, 7, VL_A)
	k.vol(15.0, -12.0 - float(L) + float(ofeg), 3.5, 5.0, VL_V, Color("#ffffff"), Color("#b9a98a"), VL_O)
	# patas de perto: a traseira tem o jarrete dobrado
	_perna(k, -7, -8 - L, la, 3, VL_B, VL_O)
	k.r(-11, -7 - L - la, 2, 1, VL_A)
	_perna(k, 5, -9 - L, lb, 3, VL_B, VL_O)
	# pescoço grosso
	k.vol(10.0 + float(hx) * 0.5, -20.0 - L + float(hy) * 0.5, 4.5, 5.5, VL_B, VL_L, VL_A, VL_O)
	# cabeça em bitmap (orelha caída, focinho claro, nariz), com olho, sobrancelha e cicatriz por cima
	var x0: int = 3 + hx
	var y0: int = -29 - L + hy
	var hcx: float = float(x0) + 10.0
	var hcy: float = float(y0) + 6.0
	k.spr(x0, y0, VL_CAB, {"o": VL_O, "a": VL_A, "b": VL_B, "l": VL_L, "v": VL_L, "Q": VL_P, "k": VL_O})
	k.r(x0 + 7, y0 + 4, 5, 3, VL_P)
	k.r(x0 + 6, y0 + 4, 7, 1, VL_O)
	k.r(x0 + 8, y0 + 5, 2, 1, VL_V)
	k.r(x0 + 9, y0 + 5, 1, 1, VL_O)
	k.r(x0 + 14, y0 + 5, 1, 3, VL_V)
	k.r(x0 + 20, y0 + 5, 1, 1, VL_PREGO)
	var by: int = y0 + 8
	var bx: int = x0 + 13
	if sn > 0.4 or parado:
		k.r(bx, by, 9, 3, VL_O)
		k.r(bx + 1, by, 7, 2, Color("#7a1f2a"))
		k.r(bx + 2, by, 1, 1, VL_V)
		k.r(bx + 6, by, 1, 1, VL_V)
		if parado:
			var lg: int = 5 + ofeg
			k.r(bx + 3, by + 1, 4, lg, VL_O)
			k.r(bx + 4, by + 1, 2, lg - 1, VL_LINGUA)
			k.r(bx + 4, by + lg - 2, 2, 1, VL_LINGUA_S)
	else:
		k.r(bx + 1, by + 1, 8, 1, VL_O)
		k.r(bx + 6, by, 1, 1, VL_V)
		k.r(bx + 6, by - 1, 1, 1, VL_V)
	# coleira de espinhos no pescoço
	var nx: float = 6.0 + float(hx) * 0.5
	var ny: float = -21.0 - L + float(hy) * 0.5
	k.lin(nx + 1.0, ny, nx - 1.0, ny + 6.0, 1.0, VL_COLEIRA, VL_O)
	for i in 3:
		var yy: int = roundi(ny) + i * 2 + 1
		var xx: int = roundi(nx) - int(i * 0.6) + 3
		k.r(xx, yy, 3, 1, VL_PREGO_S)
		k.r(xx + 1, yy - 1, 1, 3, VL_PREGO)
		k.r(xx + 3, yy, 1, 1, VL_PREGO)
	if parado:
		k.r(roundi(hcx) - 2, roundi(hcy) - 9 + ofeg, 1, 2, Color("#9fd8ff"))

# --------------------------------------------------- TEXUGO REI ---------------------------------------------------

static func _texugo(k: BichoPxB._K, p: Dictionary) -> void:
	var fr: int = p["fr"]
	var sn: float = p["sn"]
	var andando: bool = p["and"]
	var L: int = [0, 1, 0, 1][fr] if andando else 0
	var hx: int = roundi(4.0 * sn)
	var hy: int = roundi(sn)
	var la: int = [0, 2, 1, 0][fr] if andando else 0
	var lb: int = [1, 0, 0, 2][fr] if andando else 0
	# pernas curtas e grossas
	_perna(k, -9, -7 - L, lb, 3, TX_K, TX_O)
	_perna(k, 7, -7 - L, la, 3, TX_K, TX_O)
	# rabo curto
	# corpo roliço de ombros altos, pelo grisalho
	k.spr(TX_CORPO_X, TX_CORPO_Y - L, TX_CORPO, {"o": TX_O, "a": TX_A, "b": TX_B, "l": TX_L})
	_perna(k, -5, -7 - L, la, 3, TX_A, TX_O)
	_perna(k, 3, -7 - L, lb, 3, TX_A, TX_O)
	# garras claras nas patas da frente
	k.r(6, -la - 1, 2, 1, TX_W)
	k.r(5, -lb - 1, 2, 1, TX_W)
	# cabeça em bitmap, preta com duas listras brancas; orelha, olho e coroa por cima
	var x0: int = 3 + hx
	var y0: int = -19 - L + hy
	k.vol(float(x0 + 4), float(y0 + 1), 1.8, 1.8, TX_K, TX_KL, TX_O, TX_O)
	k.r(x0 + 3, y0 - 1, 2, 1, TX_W)
	k.spr(x0, y0, TX_CAB, {"o": TX_O, "k": TX_K, "K": TX_KL, "w": TX_W, "v": TX_WS, "n": TX_KL})
	k.r(x0 + 9, y0 + 5, 4, 2, TX_OLHO)        # olho no vão preto entre as listras, não sobre o branco
	k.r(x0 + 12, y0 + 5, 1, 2, TX_O)          # pupila
	k.r(x0 + 8, y0 + 4, 5, 1, TX_O)           # sobrancelha pesada, sobre o preto
	if sn > 0.4:
		k.r(x0 + 12, y0 + 10, 6, 2, Color("#7a1f2a"))
		k.r(x0 + 13, y0 + 10, 1, 1, TX_W)
		k.r(x0 + 16, y0 + 10, 1, 1, TX_W)
	# coroa torta
	var cx0: int = x0 + 4
	var cy0: int = y0 - 3
	for i in 9:
		for j in COROA_BM.size():
			var ch: String = COROA_BM[j][i]
			var col: Color
			match ch:
				"Y": col = COROA
				"y": col = COROA_S
				"R": col = GEMA
				_: continue
			k.r(cx0 + i, cy0 + j + (1 if i < 4 else 0), 1, 1, col)
