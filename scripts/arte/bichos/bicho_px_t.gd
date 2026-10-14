class_name BichoPxT
extends RefCounted
## Bichos de truque (Atirador, Curandeiro, Escudeiro, Bomba) em pixel art, para as cinco famílias.
## O corpo é o do bicho da família (BichoPxA/BichoPxB): o Escudeiro usa o corpo de Grandalhão (mais parrudo), os outros o comum.
## Por cima, cada truque ganha roupa e adereço presos às âncoras do corpo (as mesmas de RoupaGato.ORIGEM + BichoPx.desloc),
## por isso acompanham o passo e o golpe e nunca flutuam. Olhando para a direita, pé em y = 0, 1 unidade = 1 pixel do bicho.

const O := Color("#1a0f0a")
const COURO := Color("#8c5a32")
const COURO_L := Color("#c48a54")
const COURO_S := Color("#5e3a1f")
const CORDA := Color("#e8e0c8")
const VERDE := Color("#3f8f3a")
const VERDE_L := Color("#7fd05a")
const VERDE_S := Color("#245a26")
const PENA := Color("#e0453d")
const BRANCO := Color("#f6f4ea")
const CINZA := Color("#c4c2c4")
const VERM := Color("#e0353d")
const AZUL := Color("#5c7fd0")
const AZUL_L := Color("#bcd2ff")
const AZUL_S := Color("#3a55a0")
const OURO := Color("#f4d24e")
const ACO := Color("#9aa4b4")
const ACO_L := Color("#dfe6f2")
const ACO_S := Color("#5a6478")
const BOMBA_K := Color("#3a3a4a")
const BOMBA_L := Color("#8a8aa0")
const BOMBA_D := Color("#22222c")
const PAVIO := Color("#a07a4a")

const CAP_ARQ: Array = [
	"....ooo...",
	"..ooVVVoo.",
	".oVVVvVVVo",
	"oooooooooo",
]
const CAP_CURA: Array = [
	"..ooooo..",
	".oWWRWWo.",
	"oWWRRRWWo",
	"oSSSRSSSo",
	".ooooooo.",
]
const BOLSA: Array = [
	".ooooooo.",
	"oWWWRWWWo",
	"oWWRRRWWo",
	"oWWWRWWWo",
	"oSSSSSSSo",
	".ooooooo.",
]
const ELMO: Array = [
	"..ooooo..",
	".oAaAAAo.",
	"oAaAAAADo",
	"oooooooDo",
]
const ESCUDO: Array = [
	".oooooooo.",
	"oLLLBBBBDo",
	"oLBBBBBBDo",
	"oLBBYYBBDo",
	"oLBYYYYBDo",
	"oBBYYYYBDo",
	"oBBBYYBBDo",
	"oBBBBBBDDo",
	".oBBBBBDo.",
	".oBBBBDDo.",
	"..oBBBDo..",
	"...oBDo...",
	"....oo....",
]
const ALJAVA: Array = [
	".g.y.",
	".o.o.",
	"ooooo",
	"oLBBo",
	"oLBDo",
	"oSSSo",
	"oBBDo",
	"oBBDo",
	".ooo.",
]
const BOMBA: Array = [
	"....ooo....",
	"..ooKggoo..",
	".oKLLKKKKo.",
	"oKLLKKKKKKo",
	"oKLKKKKKKDo",
	"oKKKKKKKKDo",
	"oKKKKKKKDDo",
	".oKKKKKDDo.",
	"..ooKDDoo..",
	"....ooo....",
]

static func _base(tipo: int) -> int:
	return Unidade.Tipo.GIGANTE if tipo == Unidade.Tipo.ESCUDEIRO else Unidade.Tipo.COMUM

## Âncora absoluta (em pixels do bicho) do lugar `onde`, na pose atual do corpo base.
static func _a(onde: int, fam: int, tipo: int, anim: float, andando: bool, golpe: float) -> Vector2:
	return RoupaGato.ORIGEM[onde] + BichoPx.desloc(onde, fam, tipo, anim, andando, golpe, -1, false)

## Traço fino de 1 pixel entre dois pontos.
static func _traco(k: BichoPxB._K, x0: float, y0: float, x1: float, y1: float, col: Color) -> void:
	var n: int = maxi(1, int(maxf(absf(x1 - x0), absf(y1 - y0))))
	for i in n + 1:
		var t: float = float(i) / float(n)
		k.r(roundf(lerpf(x0, x1, t)), roundf(lerpf(y0, y1, t)), 1.0, 1.0, col)

static func sobre(c: CanvasItem, fam: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float) -> void:
	var k := BichoPxB._K.new(c, f, alfa)
	var sn: float = 0.0
	if golpe > 0.0:
		sn = sin(PI * clampf(1.0 - golpe / 0.22, 0.0, 1.0))
	var cab: Vector2 = _a(RoupaGato.Onde.CABECA, fam, tipo, anim, andando, golpe)
	var tr: Vector2 = _a(RoupaGato.Onde.TRASEIRA, fam, tipo, anim, andando, golpe)
	var pe: Vector2 = _a(RoupaGato.Onde.PESCOCO, fam, tipo, anim, andando, golpe)
	var bo: Vector2 = _a(RoupaGato.Onde.BOCA, fam, tipo, anim, andando, golpe)
	var co: Vector2 = _a(RoupaGato.Onde.CORPO, fam, tipo, anim, andando, golpe)
	match tipo:
		Unidade.Tipo.ATIRADOR:
			_atirador(k, cab, tr, pe, bo, sn)
		Unidade.Tipo.CURANDEIRO:
			_curandeiro(k, cab, tr, pe, co)
		Unidade.Tipo.ESCUDEIRO:
			_escudeiro(k, cab, pe, bo, co, sn)
		Unidade.Tipo.BOMBA:
			_bomba(k, cab, tr, pe)

static func _atirador(k: BichoPxB._K, cab: Vector2, tr: Vector2, pe: Vector2, bo: Vector2, sn: float) -> void:
	var tx: int = roundi(tr.x)
	var ty: int = roundi(tr.y)
	var bx: int = roundi(bo.x)
	var by: int = roundi(bo.y)
	# alça de couro em diagonal, do ombro à aljava, e aljava nas costas
	_traco(k, pe.x + 1.0, pe.y + 1.0, float(tx), float(ty - 3), COURO_S)
	_traco(k, pe.x + 1.0, pe.y + 2.0, float(tx), float(ty - 2), COURO_L)
	k.spr(tx - 3, ty - 9, ALJAVA, {"o": O, "L": COURO_L, "B": COURO, "D": COURO_S, "S": CORDA, "g": VERDE_L, "y": PENA})
	# boné verde com pena (sai se o bicho veste peça de cabeça)
	if not BichoPx.cabeca_coberta:
		k.spr(roundi(cab.x) - 5, roundi(cab.y) - 2, CAP_ARQ, {"o": O, "V": VERDE, "v": VERDE_L})
		k.r(roundi(cab.x) - 7, roundi(cab.y) - 4, 1, 3, PENA)
	# braço com manga de couro até a empunhadura do arco, que fica diante do focinho
	# braço curto e esticado: do ombro (adiantado, junto ao peito) à empunhadura, para não parecer um bastão atravessado
	k.lin(pe.x + 4.0, pe.y + 3.0, float(bx + 2), float(by + 1), 1.0, COURO, O)
	var gx: int = bx + 4
	k.r(gx - 1, by - 1, 3, 3, O)
	k.r(gx, by, 2, 2, COURO_L)
	# arco de madeira: arco do alto à ponta de baixo, corda e flecha (a corda recua no golpe)
	var pux: int = roundi(3.0 * sn)
	k.lin(float(gx - 1), float(by - 8), float(gx + 2), float(by - 4), 1.0, COURO_L, O)
	k.lin(float(gx + 2), float(by - 4), float(gx + 3), float(by + 1), 2.0, COURO, O)
	k.lin(float(gx + 3), float(by + 1), float(gx - 1), float(by + 6), 1.0, COURO_L, O)
	_traco(k, float(gx - 1), float(by - 8), float(gx - pux), float(by - 1), CORDA)
	_traco(k, float(gx - pux), float(by - 1), float(gx - 1), float(by + 6), CORDA)
	if sn > 0.1:
		_traco(k, float(gx - pux), float(by - 1), float(gx + 6), float(by - 1), CORDA)
		k.r(gx + 6, by - 2, 2, 3, ACO_L)
		k.r(gx - pux - 1, by - 2, 2, 3, PENA)

static func _curandeiro(k: BichoPxB._K, cab: Vector2, tr: Vector2, pe: Vector2, co: Vector2) -> void:
	# bolsa a tiracolo: alça do ombro ao quadril, bolsa branca com cruz vermelha no flanco
	var bx: int = roundi(co.x) - 4
	var by: int = roundi(co.y) + 1
	_traco(k, pe.x - 1.0, pe.y + 1.0, float(bx + 4), float(by), COURO_S)
	_traco(k, pe.x - 1.0, pe.y + 2.0, float(bx + 4), float(by + 1), COURO)
	k.spr(bx, by, BOLSA, {"o": O, "W": BRANCO, "S": CINZA, "R": VERM})
	# touca branca com cruz vermelha (sai se o bicho veste peça de cabeça)
	if not BichoPx.cabeca_coberta:
		k.spr(roundi(cab.x) - 5, roundi(cab.y) - 3, CAP_CURA, {"o": O, "W": BRANCO, "S": CINZA, "R": VERM})

static func _escudeiro(k: BichoPxB._K, cab: Vector2, pe: Vector2, bo: Vector2, co: Vector2, sn: float) -> void:
	# capacete de ferro (sai se o bicho veste peça de cabeça)
	if not BichoPx.cabeca_coberta:
		k.spr(roundi(cab.x) - 5, roundi(cab.y) - 2, ELMO, {"o": O, "A": ACO, "a": ACO_L, "D": ACO_S})
	# escudo grande diante do peito, preso ao braço (a manopla aparece na borda de trás); no golpe avança
	var avanco: int = roundi(3.0 * sn)
	var sx: int = roundi(pe.x) + 1 + avanco
	var sy: int = mini(roundi(cab.y) + 3, -12)   # topo do escudo logo abaixo dos olhos: o bicho espia por cima
	k.r(sx - 3 - avanco, sy + 5, 4 + avanco, 2, COURO_S)
	k.r(sx - 2 - avanco, sy + 5, 3 + avanco, 1, COURO_L)
	k.spr(sx, sy, ESCUDO, {"o": O, "L": AZUL_L, "B": AZUL, "D": AZUL_S, "Y": OURO})

static func _bomba(k: BichoPxB._K, cab: Vector2, tr: Vector2, pe: Vector2) -> void:
	var t: int = Time.get_ticks_msec()
	var jx: int = (int(t / 90) % 3) - 1        # tremor nervoso
	var tx: int = roundi(tr.x) + jx
	var ty: int = roundi(tr.y)
	# cintas que prendem a bomba ao peito
	_traco(k, pe.x, pe.y + 1.0, float(tx), float(ty - 4), COURO_S)
	_traco(k, pe.x, pe.y + 2.0, float(tx), float(ty - 3), COURO)
	var x0: int = tx - 5
	var y0: int = ty - 8
	k.spr(x0, y0, BOMBA, {"o": O, "K": BOMBA_K, "L": BOMBA_L, "D": BOMBA_D, "g": ACO})
	# pavio aceso com fagulhas que dançam
	k.r(x0 + 5, y0 - 1, 1, 1, PAVIO)
	k.r(x0 + 6, y0 - 2, 1, 1, PAVIO)
	k.r(x0 + 6, y0 - 3, 1, 1, PAVIO)
	var fase: int = int(t / 70) % 4
	var fx: Array = [0, 1, -1, 2]
	var fy: Array = [0, -1, 0, 1]
	k.r(x0 + 7 + fx[fase], y0 - 5 + fy[fase], 2, 2, Color("#fff08a"))
	k.r(x0 + 6 - fx[(fase + 1) % 4], y0 - 6 + fy[(fase + 2) % 4], 1, 1, Color("#ff7a2a"))
	k.r(x0 + 9 + fx[(fase + 2) % 4], y0 - 4, 1, 1, Color("#ffd24a"))
	# gota de suor da cabeça: o bichinho está com medo
	if int(t / 400) % 2 == 0:
		k.r(roundi(cab.x) + 3, roundi(cab.y) + 1, 1, 2, Color("#9fd8ff"))
