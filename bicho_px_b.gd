class_name BichoPxB
extends RefCounted
## Bichos em pixel art, famílias 3 e 4: corvos e sapos, os chefes Corvo Velho e Sapo-Rei, e os sapinhos (ver BichoPx para as convenções).
## O corpo, a cabeça, a pata e o braço são bitmaps (linhas de texto, via `_K.spr`), pixel a pixel, com contorno quase preto de 1 pixel,
## 2 tons de corpo e 1 de luz. Os tipos grandes (Grandalhão, Corvo Velho, Sapo-Rei) esticam o mesmo bitmap duplicando colunas e linhas (`_est`).
## A pose (cabeça, altura do salto, quadro de passo) sai de UMA função, `_pose`, usada por `desenhar` e por `desloc`.

# --- corvos ---
const CO_O := Color("#0b0f1c")
const CO_A := Color("#1d2740")
const CO_B := Color("#334568")
const CO_C := Color("#5870a0")
const CO_D := Color("#121a2e")
const SP_D := Color("#2c6e33")
const SL_D := Color("#5fb04a")
const BICO := Color("#f7c81e")
const BICO_S := Color("#b9860f")
const PERNA := Color("#e3a626")
const PERNA_S := Color("#8f6410")
const OLHO := Color("#fff7b0")
const PUPILA := Color("#1a0a0a")
# --- Corvo Velho ---
const CV_O := Color("#07090f")
const CV_A := Color("#262d3c")
const CV_B := Color("#3f4a60")
const CV_C := Color("#76829a")
const PELE := Color("#8d7b79")
const LEITE := Color("#dbe5f2")
const CICATRIZ := Color("#7a3b3b")
const BICO_V := Color("#d4a62a")
const BICO_VS := Color("#8a6a14")
const CACHE := Color("#7c3a2c")
const CACHE_S := Color("#4a2018")
# --- ladrão ---
const RED := Color("#d63a3a")
const RED_S := Color("#8a1c24")
const SACO := Color("#b68e57")
const SACO_O := Color("#5b4020")
const BL1 := Color("#e8504a")
const BL2 := Color("#4aa8e8")
const BL3 := Color("#f2d03b")
# --- sapos ---
const SP_O := Color("#1b4a26")
const SP_A := Color("#3f9140")
const SP_B := Color("#72c34c")
const SP_V := Color("#e9e3a6")
const SL_O := Color("#3f8f3a")
const SL_A := Color("#86d460")
const SL_B := Color("#c4f294")
const SP_OLHO := Color("#f6ea6a")
const BOCA := Color("#7a1f2a")
const LINGUA := Color("#e8647f")
const PAPO := Color("#efd98a")
const COROA := Color("#f4c430")
const COROA_S := Color("#b88a14")
const GEMA := Color("#d03030")

const PAL_C := {"o": CO_O, "a": CO_A, "b": CO_B, "c": CO_C, "d": CO_D, "e": OLHO, "p": PUPILA, "y": BICO, "z": BICO_S, "m": BOCA}
const PAL_V := {"o": CV_O, "a": CV_A, "b": CV_B, "c": CV_C, "d": CV_O, "e": LEITE, "p": Color("#8c96a8"), "y": BICO_V, "z": BICO_VS, "m": BOCA}
const PAL_S := {"o": SP_O, "a": SP_A, "b": SP_B, "d": SP_D, "v": SP_V, "e": SP_OLHO, "p": PUPILA}
const PAL_SL := {"o": SL_O, "a": SL_A, "b": SL_B, "d": SL_D, "v": SP_V, "e": SP_OLHO, "p": PUPILA}
const PAL_SACO := {"o": SACO_O, "S": SACO, "s": Color("#d9b77c")}

# Corpo do corvo: 15 colunas (x = -9 a 5), 9 linhas. Costas no alto, peito estufado à direita, barriga escura.
const CORVO_CORPO: Array = [
	"....ooooooo....",
	"..ooaaaaaaaoo..",
	".oabbbbcbbbaaoo",
	"oabbbbbcbbbbaao",
	"oabbbbbbbbbbaao",
	"oaabbbbbbbbaaao",
	".oaaabbbbaaaaao",
	"..ooaaaaaaaaoo.",
	"....oodddddoo..",
]
# Cauda curta em leque, caída para trás (6 colunas por 5 linhas).
const CORVO_CAUDA: Array = [
	"....oo",
	"..ooaa",
	"ooaaab",
	"obbaao",
	".oooo.",
]
# Cabeça redonda com bico forte: 12 colunas (olho nas colunas 5 e 6). Bico fechado e aberto.
const CORVO_CAB: Array = [
	"..ooooo.....",
	".oaacbbo....",
	"oaabbeeoooo.",
	"oaabbepoyyyo",
	"oaaabbboyzzo",
	".oaaaaaoooo.",
	"..oaaaao....",
	"...oaao.....",
]
const CORVO_CAB_AB: Array = [
	"..ooooo.....",
	".oaacbbo....",
	"oaabbeeoooo.",
	"oaabbepoyyyo",
	"oaaabbbommo.",
	".oaaaaaozzzo",
	"..oaaaaooooo",
	"...oaao.....",
]
# Asa aberta (batida do Saltador) e saco do ladrão.
const CORVO_ASA: Array = [
	"o......",
	"ooo....",
	"obbo...",
	"obbbo..",
	".obbbo.",
	".obbbco",
	"..oooo.",
]
const CORVO_SACO: Array = [
	"...oo...",
	"..oSSo..",
	".oSSSSo.",
	"oSSsSSSo",
	"oSSSSSSo",
	".oSSSSo.",
	"..oooo..",
]
# Filhote de corvo (Ninhada): corpo pequeno, cabeça grande.
const CORVO_FIL: Array = [
	"....ooooo..",
	"...oaabbbo.",
	".ooabbeeooo",
	"oaaabbepoyy",
	"oabbbaaaooo",
	".oaaaaaaoo.",
	"..ooooooo..",
]

# Sapo: 22 colunas (x = -10 a 11), 13 linhas (y = -13 a -1). Olhos saltados no alto, boca larga, papo claro.
const SAPO_CORPO: Array = [
	".....ooooooooo..",
	".....oeeeoeeeo..",
	".....oepeoepeo..",
	"..oooobbbbbbboo.",
	".oobbbbbbbbbaaao",
	"obbbbaaaaaaaaaao",
	"obbaaaaaaaaaaaoo",
	"oaaaaaaaaaaooooo",
	"oaaaaaaaaaaaavvo",
	"oaaadaaaaaaaavvo",
	".oadddddddddvvvo",
	"..ooooooooooooo.",
]
# Perna traseira dobrada (13 colunas por 9 linhas), com o pé comprido para a frente.
const SAPO_PATA: Array = [
	"..oooo......",
	".oabbbo.....",
	"oabbbbao....",
	"oabbaaaoo...",
	"oaaaaaaaao..",
	".oaaaaaaaaoo",
	"..ooaaaaaoo.",
	"....ooooooo.",
]
const SAPO_BRACO: Array = [
	"oaao.",
	"oabo.",
	"oabo.",
	"oabbo",
	"oaaoo",
]
# Sapinho (Ninhada e partes do Sapo-Rei): 12 colunas por 7 linhas.
const SAPO_PQ: Array = [
	"..oo.oo..",
	".oepoepo.",
	"oabbbbbao",
	"oaaaaaaao",
	"oaavvvaao",
	".ooooooo.",
]
const COROA_BM: Array = [
	"Y.Y...Y.Y",
	"YYYYYYYYY",
	"yYRYYyYRy",
	".yyyyyyy.",
]

## Pincel: guarda o canvas, o flash, a transparência e um deslocamento inteiro (para desenhar filhotes nas costas).
class _K:
	var c: CanvasItem
	var f: float = 0.0
	var a: float = 1.0
	var ox: float = 0.0
	var oy: float = 0.0

	func _init(c_: CanvasItem, f_: float, a_: float, ox_: float = 0.0, oy_: float = 0.0) -> void:
		c = c_
		f = f_
		a = a_
		ox = ox_
		oy = oy_

	func em(dx: float, dy: float) -> _K:
		return _K.new(c, f, a, ox + dx, oy + dy)

	func k(col: Color) -> Color:
		var q: Color = col
		q.a = col.a * a
		return q

	func r(x: float, y: float, w: float, h: float, col: Color) -> void:
		if w <= 0.0 or h <= 0.0:
			return
		RoupaGato.r(c, x + ox, y + oy, w, h, k(col), f)

	## Elipse preenchida em pixels inteiros (uma faixa por linha).
	func fill(cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
		var j0: int = int(floor(cy - ry))
		var j1: int = int(ceil(cy + ry))
		for j in range(j0, j1):
			var dy: float = (float(j) + 0.5 - cy) / ry
			if absf(dy) >= 1.0:
				continue
			var hw: float = rx * sqrt(1.0 - dy * dy)
			var x0: float = roundf(cx - hw)
			var x1: float = roundf(cx + hw)
			if x1 > x0:
				r(x0, float(j), x1 - x0, 1.0, col)

	## Elipse com contorno de 1 pixel.
	func el(cx: float, cy: float, rx: float, ry: float, col: Color, out: Color) -> void:
		fill(cx, cy, rx + 1.0, ry + 1.0, out)
		fill(cx, cy, rx, ry, col)

	## Traço grosso de `w` pixels entre dois pontos, com contorno.
	func lin(x0: float, y0: float, x1: float, y1: float, w: float, col: Color, out: Color) -> void:
		var n: int = maxi(1, int(maxf(absf(x1 - x0), absf(y1 - y0))))
		for pas in 2:
			for i in n + 1:
				var t: float = float(i) / float(n)
				var x: float = roundf(lerpf(x0, x1, t))
				var y: float = roundf(lerpf(y0, y1, t))
				if pas == 0:
					r(x - 1.0, y - 1.0, w + 2.0, w + 2.0, out)
				else:
					r(x, y, w, w, col)

	## Elipse com volume: contorno, sombra embaixo, tom base e brilho no alto (3 tons).
	func vol(cx: float, cy: float, rx: float, ry: float, base: Color, lite: Color, dark: Color, out: Color) -> void:
		fill(cx, cy, rx + 1.0, ry + 1.0, out)
		fill(cx, cy, rx, ry, dark)
		fill(cx, cy - 0.7, rx - 0.3, ry - 0.9, base)
		fill(cx - rx * 0.1, cy - ry * 0.5, rx * 0.55, ry * 0.28, lite)

	func spr(x: float, y: float, linhas: Array, pal: Dictionary) -> void:
		var q: Dictionary = {}
		for ch in pal:
			q[ch] = k(pal[ch])
		RoupaGato.sprite(c, x + ox, y + oy, linhas, q, f)

# ---------------------------------------------------------------------------------------------

## Estica um bitmap: duplica as colunas listadas em `cols` e as linhas listadas em `rows` (um índice repetido duplica mais de uma vez);
## `cortar` remove linhas. Assim o Grandalhão e os chefes saem do mesmo desenho, sem perder o pixel a pixel.
static func _est(linhas: Array, cols: Array, rows: Array, cortar: Array = []) -> Array:
	var sai: Array = []
	for j in linhas.size():
		if cortar.has(j):
			continue
		var l: String = linhas[j]
		var n: String = ""
		for i in l.length():
			n += l[i]
			for ci in cols:
				if int(ci) == i:
					n += l[i]
		sai.append(n)
		for rj in rows:
			if int(rj) == j:
				sai.append(n)
	return sai

## Pose comum a `desenhar` e `desloc`. Todos os valores são inteiros (pixels).
## hx, hy = cabeça em relação à posição de repouso; L = quanto o corpo todo está acima da planta (pernas longas,
## gigante, salto); air = parte de L que é salto no ar; fr = quadro do passo; sn = 0..1, força do golpe.
static func _pose(fam: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int) -> Dictionary:
	var hx: int = 0
	var hy: int = 0
	var base: int = 0
	var air: int = 0
	var fr: int = 0
	var bat: bool = false
	var sn: float = 0.0
	var sal: bool = tipo == Unidade.Tipo.SALTADOR
	var big: bool = tipo == Unidade.Tipo.GIGANTE
	var chefe: bool = chefe_tipo >= 0
	if golpe > 0.0:
		sn = sin(PI * clampf(1.0 - golpe / 0.22, 0.0, 1.0))
	if fam == 3:
		if not chefe:
			base = 2 if sal else (1 if big else 0)
		if andando:
			fr = int(anim * 1.3) % 4
			hx = [1, 0, -1, 0][fr]
			hy = [0, 0, 0, 1][fr]
			if sal and not chefe:
				air = [0, 2, 3, 1][fr]
				bat = air >= 2
		if sn > 0.0:
			hx += roundi(4.0 * sn)
			hy += roundi(3.0 * sn)
	else:
		if not chefe:
			base = 2 if sal else (1 if big else 0)
		if andando:
			fr = int(anim * 1.3) % 4
			var add: Array = [0, 1, 2, 1]
			if sal and not chefe:
				add = [0, 2, 3, 1]
			elif big or chefe:
				add = [0, 1, 1, 0]
			air = add[fr]
	return {"hx": hx, "hy": hy, "L": base + air, "air": air, "fr": fr, "bat": bat, "sn": sn, "and": andando}

static func desenhar(c: CanvasItem, fam: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var k := _K.new(c, f, alfa)
	var p: Dictionary = _pose(fam, tipo, anim, andando, golpe, chefe_tipo)
	if fam == 3:
		if filhote and chefe_tipo < 0:
			_corvo_filhote(k, p)
		else:
			_corvo(k, p, tipo, carregando, chefe_tipo)
	else:
		if chefe_tipo == 4:
			_sapo(k, p, tipo, false, 4, anim)
		elif parte:
			_sapo_pq(k, p, true)
		elif filhote:
			_sapo_pq(k, p, false)
		else:
			_sapo(k, p, tipo, carregando, -1, anim)

static func desloc(onde: int, fam: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Vector2:
	var p: Dictionary = _pose(fam, tipo, anim, andando, golpe, chefe_tipo)
	var L: float = float(p["L"])
	var air: float = float(p["air"])
	var big: bool = tipo == Unidade.Tipo.GIGANTE
	if fam == 3:
		var g: Dictionary = _gc(tipo, chefe_tipo, p)
		var hx0: float = float(g["hx0"])
		var hy0: float = float(g["hy0"])
		var bt: float = float(g["bt"])
		var w: float = float(g["W"])
		var h: float = float(g["H"])
		var hc: float = float(g["hc"])
		match onde:
			RoupaGato.Onde.CABECA: return Vector2(hx0 + 3.5 + hc * 0.5 - 5.5, hy0 + 16.0)
			RoupaGato.Onde.CORPO: return Vector2(-9.0 + w * 0.5 + 0.5, bt + h * 0.5 + 9.0)
			RoupaGato.Onde.BOCA: return Vector2(hx0 + 12.0 + hc - 11.0, hy0 + 3.5 + 11.0)
			RoupaGato.Onde.TRASEIRA: return Vector2(-6.0 + 8.0, bt + 12.0)
			RoupaGato.Onde.PESCOCO: return Vector2(hx0 + 3.0 - 2.0, hy0 + 7.0 + float(g["hr"]) + 11.0)
			RoupaGato.Onde.PATAS: return Vector2(0.0, -air)
			RoupaGato.Onde.ROSTO: return Vector2(hx0 + 5.0 + hc - 8.0, hy0 + 2.0 + 13.0)
		return Vector2.ZERO
	if chefe_tipo == 4:
		match onde:
			RoupaGato.Onde.CABECA: return Vector2(-4.5, 3.0 - L)
			RoupaGato.Onde.CORPO: return Vector2(-1.5, 1.5 - L)
			RoupaGato.Onde.BOCA: return Vector2(-4.0, 6.0 - L)
			RoupaGato.Onde.TRASEIRA: return Vector2(0.0, 3.0 - L)
			RoupaGato.Onde.PESCOCO: return Vector2(-2.0, 5.0 - L)
			RoupaGato.Onde.PATAS: return Vector2(0.0, 0.0)
			RoupaGato.Onde.ROSTO: return Vector2(-4.0, 3.0 - L)
		return Vector2.ZERO
	match onde:
		RoupaGato.Onde.CABECA: return Vector2(-4.5, (5.0 if big else 6.0) - L)
		RoupaGato.Onde.CORPO: return Vector2(-0.5, 3.0 - L)
		RoupaGato.Onde.BOCA: return Vector2(-4.0, 6.0 - L)
		RoupaGato.Onde.TRASEIRA: return Vector2(1.0, 4.0 - L)
		RoupaGato.Onde.PESCOCO: return Vector2(-2.0, 5.0 - L)
		RoupaGato.Onde.PATAS: return Vector2(0.0, -air * 0.5 if air >= 2.0 else 0.0)
		RoupaGato.Onde.ROSTO: return Vector2(-4.0, 4.0 - L)
	return Vector2.ZERO

# ------------------------------------------------ CORVOS ------------------------------------------------

## Geometria do corvo (comum, Grandalhão ou Corvo Velho): tamanho do corpo e onde fica a cabeça. Usada por desenho e por `desloc`.
static func _gc(tipo: int, chefe: int, p: Dictionary) -> Dictionary:
	var velho: bool = chefe >= 0
	var big: bool = tipo == Unidade.Tipo.GIGANTE
	var nc: int = 2 if big else (1 if velho else 0)
	var nr: int = 2 if (big or velho) else 0
	var hc: int = 1 if (big or velho) else 0
	var hr: int = 1 if (big or velho) else 0
	var L: int = p["L"]
	var w: int = 15 + nc
	var h: int = 9 + nr
	var bt: int = -L - 4 - h
	var hx0: int = w - 13 + int(p["hx"])
	var hy0: int = bt - 3 - hr + int(p["hy"]) + (2 if velho else 0)
	return {"W": w, "H": h, "nc": nc, "nr": nr, "hc": hc, "hr": hr, "bt": bt, "hx0": hx0, "hy0": hy0}

static func _perna(k: _K, x: int, ytopo: int, ybase: int, w: int, col: Color) -> void:
	k.r(x, ytopo, w, ybase - ytopo, col)
	k.r(x - 1, ybase - 1, w + 3, 1, col)          # dedos para a frente

static func _corvo(k: _K, p: Dictionary, tipo: int, carregando: bool, chefe: int) -> void:
	var velho: bool = chefe >= 0
	var big: bool = tipo == Unidade.Tipo.GIGANTE
	var g: Dictionary = _gc(tipo, chefe, p)
	var pal: Dictionary = PAL_V if velho else PAL_C
	var fr: int = p["fr"]
	var sn: float = p["sn"]
	var air: int = p["air"]
	var L: int = p["L"]
	var w: int = g["W"]
	var h: int = g["H"]
	var nc: int = g["nc"]
	var bt: int = g["bt"]
	var hx0: int = g["hx0"]
	var hy0: int = g["hy0"]
	var hc: int = g["hc"]
	var hr: int = g["hr"]
	var grosso: int = 2 if (big or velho) else 1
	var acor: Color = BICO_VS if velho else PERNA
	var bcor: Color = Color("#5a4510") if velho else PERNA_S
	# pernas (a de trás mais escura), sob o corpo
	var ax: int = 3 + nc
	var bx: int = -1
	var al: int = 0
	var bl: int = 0
	if p["and"]:
		ax = [3, 2, 0, 2][fr] + nc
		al = [0, 0, 0, 1][fr]
		bx = [-1, 0, 2, 0][fr]
		bl = [0, 1, 0, 0][fr]
	_perna(k, bx, bt + h - 1, -air - bl, grosso, bcor)
	_perna(k, ax, bt + h - 1, -air - al, grosso, acor)
	# cauda curta em leque
	var cauda: Array = CORVO_CAUDA
	k.spr(-14, bt + 2 + (1 if big else 0), cauda, pal)
	if velho:
		k.r(-15, bt + 5, 1, 1, CV_O)
		k.r(-13, bt + 8, 1, 1, CV_O)
		k.r(-12, bt + 7, 2, 1, CV_B)
	# corpo
	var ccols: Array = []
	for i in nc:
		ccols.append(6)
	var crows: Array = []
	for i in int(g["nr"]):
		crows.append(4)
	var corpo: Array = _est(CORVO_CORPO, ccols, crows)
	k.spr(-9, bt, corpo, pal)
	if velho:
		# penas arrepiadas e falhas de pele nua
		for i in 6:
			var sx: int = -8 + i * 2 + (i % 2)
			var sh: int = 1 + (i * 3) % 3
			k.r(sx, bt - sh, 1, sh, CV_A)
			k.r(sx, bt - sh - 1, 1, 1, CV_O)
			k.r(sx + 1, bt - 1, 1, 1, CV_O)
		k.r(-4, bt + 4, 2, 2, PELE)
		k.r(-3, bt + 6, 1, 1, PELE)
		k.r(0, bt + 6, 1, 1, PELE)
		k.r(-7, bt + 3, 2, 1, PELE)
		k.r(2, bt + 3, 1, 1, PELE)
	# asa batendo (Saltador no ar)
	if p["bat"]:
		k.spr(-8, bt - 6, CORVO_ASA, pal)
	# ladrão: saco nas costas
	if tipo == Unidade.Tipo.LADRAO:
		k.spr(-9, bt - 5, CORVO_SACO, PAL_SACO)
		if carregando:
			k.r(-8, bt - 7, 2, 2, BL1)
			k.r(-6, bt - 8, 2, 2, BL2)
			k.r(-4, bt - 7, 2, 2, BL3)
	# ninhada: dois filhotes montados
	if tipo == Unidade.Tipo.GEMEO:
		var pf: Dictionary = {"hx": 0, "hy": 0, "L": 0, "air": 0, "fr": 0, "sn": 0.0, "and": false}
		_corvo_filhote(k.em(-3.0, float(bt + 2)), pf)
		_corvo_filhote(k.em(3.0, float(bt + 1)), pf)
	# pescoço (quando a cabeça avança) e cabeça
	if hx0 + 3 > w - 10 or hy0 > bt - 3:
		var ny0: int = hy0 + 4
		var ny1: int = bt + 7
		if ny1 > ny0:
			k.r(w - 11, ny0, maxi(2, hx0 + 4 - (w - 11)), ny1 - ny0, CV_A if velho else CO_A)
	var cab: Array = CORVO_CAB_AB if sn > 0.5 else CORVO_CAB
	if hc > 0:
		cab = _est(cab, [3], [5] if hr > 0 else [])
	k.spr(hx0, hy0, cab, pal)
	var ex: int = hx0 + 5 + hc
	var ey: int = hy0 + 2
	if big:
		k.r(ex - 1, ey, 3, 1, CO_O)            # cara fechada: sobrancelha pesada
	if velho:
		# cicatriz sobre o olho leitoso e bico rachado
		k.r(ex + 1, ey - 1, 1, 1, CICATRIZ)
		k.r(ex + 1, ey, 1, 1, CICATRIZ)
		k.r(ex, ey + 1, 1, 1, CICATRIZ)
		k.r(ex - 1, ey + 2, 1, 1, CICATRIZ)
		k.r(hx0 + 9 + hc, hy0 + 3, 1, 2 if sn <= 0.5 else 1, CV_O)
		# cachecol velho e puído
		var sy: int = hy0 + 6 + hr
		k.r(hx0 + 1, sy, 6, 1, CACHE_S)
		k.r(hx0, sy + 1, 7, 2, CACHE)
		k.r(hx0 + 1, sy + 2, 5, 1, CACHE_S)
		k.r(hx0 - 1, sy + 3, 2, 3, CACHE)
		k.r(hx0 - 1, sy + 5, 1, 1, CACHE_S)
		k.r(hx0 + 1, sy + 3, 1, 1, CACHE_S)
	# ladrão: lenço vermelho no pescoço
	if tipo == Unidade.Tipo.LADRAO:
		var ly: int = hy0 + 6
		k.r(hx0 + 1, ly, 5, 1, RED)
		k.r(hx0 + 1, ly + 1, 5, 1, RED_S)
		k.r(hx0 - 1, ly + 1, 2, 1, RED)
		k.r(hx0 - 1, ly + 2, 1, 2, RED_S)

static func _corvo_filhote(k: _K, p: Dictionary) -> void:
	var fr: int = p["fr"]
	var pul: int = 1 if (p["and"] and fr == 1) else 0
	var hh: int = roundi(2.0 * float(p["sn"]))
	k.r(-2, -2 - pul, 1, 2, PERNA_S)
	k.r(1, -2 - pul, 1, 2, PERNA)
	k.r(-3, -1 - pul, 3, 1, PERNA_S)
	k.r(0, -1 - pul, 3, 1, PERNA)
	k.spr(-5 + hh, -9 - pul + hh / 2, CORVO_FIL, PAL_C)

# ------------------------------------------------- SAPOS -------------------------------------------------

## Geometria do sapo: colunas/linhas acrescentadas, canto superior esquerdo do bitmap e a linha da boca.
static func _gs(tipo: int, chefe: int, p: Dictionary) -> Dictionary:
	var rei: bool = chefe >= 0
	var big: bool = tipo == Unidade.Tipo.GIGANTE
	var sal: bool = tipo == Unidade.Tipo.SALTADOR
	var nc: int = 4 if rei else (2 if big else 0)
	var nr: int = 3 if rei else (1 if big else 0)
	var cort: int = 1 if sal else 0
	var L: int = p["L"]
	return {"nc": nc, "nr": nr, "cort": cort, "x0": -8 - nc, "y0": -12 - nr + cort - L, "boca": 7 + nr}

static func _sapo(k: _K, p: Dictionary, tipo: int, carregando: bool, chefe: int, anim: float) -> void:
	var rei: bool = chefe >= 0
	var g: Dictionary = _gs(tipo, chefe, p)
	var big: bool = tipo == Unidade.Tipo.GIGANTE
	var sal: bool = tipo == Unidade.Tipo.SALTADOR
	var nc: int = g["nc"]
	var nr: int = g["nr"]
	var x0: int = g["x0"]
	var y0: int = g["y0"]
	var sn: float = p["sn"]
	var air: int = p["air"]
	var L: int = p["L"]
	var ext: bool = air >= 2 or sal
	var cols: Array = []
	for i in nc:
		cols.append(2 + (i % 3))
	var rows: Array = []
	for i in nr:
		rows.append(5)
	var corpo: Array = _est(SAPO_CORPO, cols, rows, [9] if sal else [])
	var fundo: int = y0 + corpo.size()     # linha logo abaixo do corpo
	# perna traseira: no ar ou de pernas longas, estica para baixo e para trás, em diagonal curta
	if ext:
		var hipx: int = x0 + 4
		var hipy: int = fundo - 4
		var fy: int = -1 if sal else fundo + 1
		k.lin(float(hipx), float(hipy), float(hipx - 2), float(fy - 1), 2.0, SP_A, SP_O)
		k.r(hipx - 4, fy, 4, 1, SP_O)
		k.r(hipx - 3, fy - 1, 3, 1, SP_A)
	k.spr(x0, y0, corpo, PAL_S)
	if not ext:
		var pata: Array = _est(SAPO_PATA, [], [3] if nr > 0 else [])
		k.spr(x0 + 1, -pata.size() - L, pata, PAL_S)
	# ladrão: saco nas costas
	if tipo == Unidade.Tipo.LADRAO:
		k.spr(x0 + 1, y0 - 3, CORVO_SACO, PAL_SACO)
		if carregando:
			k.r(x0 + 2, y0 - 5, 2, 2, BL1)
			k.r(x0 + 4, y0 - 6, 2, 2, BL2)
			k.r(x0 + 6, y0 - 5, 2, 2, BL3)
	if tipo == Unidade.Tipo.GEMEO:
		var pq: Dictionary = {"L": 0, "sn": 0.0}
		_sapo_pq(k.em(float(x0 + 5), float(y0 + 4)), pq, false)
		_sapo_pq(k.em(float(x0 + 10), float(y0 + 3)), pq, false)
	# braço da frente
	if ext:
		k.lin(3.0, float(fundo - 4), 5.0, float(fundo - 2), 2.0, SP_A, SP_O)
	else:
		k.spr(3, -5 - L, SAPO_BRACO, PAL_S)
	# boca, língua e papo
	var my: int = y0 + int(g["boca"])
	if sn > 0.15:
		k.r(3, my + 1, 5, 2, BOCA)
		k.r(2, my + 3, 6, 1, SP_O)
		var ln: int = roundi(7.0 * sn)
		k.r(4, my + 1, 3 + ln, 1, LINGUA)
		k.r(4, my + 2, 3 + ln, 1, Color("#c04560"))
		k.r(7 + ln, my, 2, 3, LINGUA)
	elif rei:
		var pulso: float = 0.5 + 0.5 * sin(anim * 0.8)
		var py2: float = float(my) + 4.0
		k.el(4.0, py2, 2.6 + 1.4 * pulso, 1.4 + 1.0 * pulso, PAPO, SP_O)
		k.r(2, int(py2) - 1, 3, 1, SP_V)
	# expressão: sobrancelha pesada (cara fechada) no Grandalhão e no rei; ladrão com lenço
	if big or rei:
		k.r(-2, y0 + 1, 3, 1, SP_O)
		k.r(2, y0 + 1, 3, 1, SP_O)
	if tipo == Unidade.Tipo.LADRAO:
		k.r(-2, my, 3, 2, RED)
		k.r(-2, my + 2, 3, 1, RED_S)
		k.r(-3, my + 2, 1, 3, RED)
	# coroa torta do rei, sobre os olhos
	if rei:
		k.spr(-2, y0 - 4, COROA_BM, {"Y": COROA, "y": COROA_S, "R": GEMA})

static func _sapo_pq(k: _K, p: Dictionary, claro: bool) -> void:
	var L: int = p["L"]
	var sn: float = p["sn"]
	var pal: Dictionary = PAL_SL if claro else PAL_S
	k.spr(-4, -6 - L, SAPO_PQ, pal)
	k.r(-5, -1 - L, 2, 1, pal["o"])
	k.r(3, -1 - L, 2, 1, pal["o"])
	if sn > 0.15:
		k.r(4, -3 - L, 1 + roundi(4.0 * sn), 1, LINGUA)
