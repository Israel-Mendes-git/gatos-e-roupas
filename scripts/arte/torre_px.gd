class_name TorrePx
extends RefCounted
## Torre-fortaleza de brinquedo em pixel art, desenhada por código na grade de 4 px da tela.
## Serve à tela da luta (Campo) e, depois, ao guarda-roupa: tudo é função estática que recebe
## o CanvasItem onde desenhar, a posição da base e o estado da torre.
##
## Geometria (px de tela, G = 4): `base` é o canto esquerdo do CORPO de blocos, na altura do chão
## (a caixa de papelão sai 8 px para cada lado). O corpo tem 4 colunas de blocos 40x20. Acima da
## última fileira cheia vai a plataforma (tábuas, ameias, vigia, bandeira, canhão); os 0 a 3
## blocos que sobram da fileira de cima ficam soltos em cima da plataforma. Os dois módulos
## ficam no chão, na frente da caixa (ver `rect_encaixe`).
##
## `op` (Dictionary opcional de `desenhar`), todas as chaves são opcionais:
##   "recuo": 0..1 recuo do canhão       "vitoria": bool, o vigia comemora
##   "pulso": 0..1 clareia os blocos      "luta": bool (padrão true), brilho da enfermaria
##   "vigia": bool (padrão true)          "ratoeira": s restantes da ratoeira estalada
##   "catapulta": s desde o disparo (-1 = armada, com o saco)
##   "sirene": s restantes do alarme      "balista": s restantes do disparo
##   "caldeirao": s restantes da fervura  "novo_idx"/"novo_s": bloco novo assentando (Caldeirão)

const G := 4.0
const COLS := 4
const BW := 40.0
const BH := 20.0
const LARG := 160.0
const CAIXA_H := 16.0
const FAIXA_LUTA_X := 200.0
const JANELA_I := 9      # bloco que vira janelinha
const ENGRENAGEM_I := 10 # bloco da engrenagem (Cadência)
const CRUZ_I := 14       # bloco da cruz (Enfermaria)

const ESTR := 0
const CANH := 1
const CADE := 2
const ENFE := 3

# ---- paletas
const COR_CONTORNO := Color(0.14, 0.09, 0.12)
const KRAFT := Color(0.74, 0.56, 0.34)
const KRAFT_CLARO := Color(0.84, 0.67, 0.43)
const KRAFT_ESCURO := Color(0.58, 0.41, 0.24)
const FITA := Color(0.9, 0.82, 0.56)
const PEDRA := Color(0.50, 0.52, 0.62)
const PEDRA_CLARA := Color(0.64, 0.66, 0.76)
const TABUA := Color(0.62, 0.42, 0.22)
const METAL: Array[Color] = [
	Color(0, 0, 0, 0), Color(0.62, 0.66, 0.74), Color(0.68, 0.72, 0.80),
	Color(0.55, 0.70, 0.92), Color(0.62, 0.78, 0.96), Color(0.97, 0.80, 0.28),
	Color(1.0, 0.62, 0.26), Color(0.45, 0.92, 0.78), Color(0.78, 0.60, 1.0),   # 6 cobre, 7 esmeralda, 8 ametista
]
const CANHAO_COR: Array[Color] = [
	Color(0.58, 0.38, 0.22), Color(0.58, 0.61, 0.66), Color(0.30, 0.52, 0.86),
	Color(0.30, 0.72, 0.42), Color(0.68, 0.42, 0.88), Color(0.96, 0.78, 0.25),
	Color(0.95, 0.46, 0.18), Color(0.28, 0.84, 0.76), Color(0.80, 0.52, 1.0),
]
const CANHAO_ESP: Array[float] = [12.0, 12.0, 16.0, 16.0, 20.0, 20.0, 24.0, 24.0, 24.0]

const PAL_VIGIA := {
	"k": Color(0.14, 0.09, 0.13), "o": Color(0.93, 0.58, 0.26), "w": Color(0.99, 0.93, 0.80),
	"e": Color(0.10, 0.08, 0.10), "p": Color(0.95, 0.50, 0.55), "m": Color(0.62, 0.10, 0.16),
}
const PAL_MOD := {
	"k": Color(0.13, 0.09, 0.12), "m": Color(0.66, 0.45, 0.24), "M": Color(0.45, 0.29, 0.15),
	"a": Color(0.78, 0.80, 0.86), "A": Color(0.46, 0.50, 0.58), "y": Color(0.98, 0.82, 0.30),
	"r": Color(0.90, 0.25, 0.22), "R": Color(0.55, 0.12, 0.14), "w": Color(0.99, 0.95, 0.82),
	"g": Color(0.45, 0.90, 0.40), "G": Color(0.25, 0.60, 0.28), "P": Color(0.27, 0.27, 0.33),
	"p": Color(0.45, 0.45, 0.55), "o": Color(0.98, 0.55, 0.15), "f": Color(0.95, 0.40, 0.45),
	"B": Color(0.55, 0.38, 0.20), "t": Color(0.85, 0.88, 0.92),
}

# ---- bitmaps (cada letra é um pixel de 4 px; ponto é transparente)
const VIGIA_NORMAL: Array[String] = [
	"...k....k.",
	"..kookkook",
	"..kooooook",
	"..kooeooek",
	"..koooowpk",
	".kooowwwk.",
	"kooooooook",
	".kkkkkkkk.",
]
const VIGIA_ABAIXADO: Array[String] = [
	"..kkkkkkk.",
	".kooooooek",
	".kooooowpk",
	"kooooooook",
	".kkkkkkkk.",
]
const VIGIA_FESTA: Array[String] = [
	"...k....k.",
	"..kookkook",
	"..kooooook",
	"..kooeooek",
	"..koooommk",
	".kooowwwk.",
	"kooooooook",
	".kkkkkkkk.",
]
const SPR_RATOEIRA: Array[String] = [
	"............",
	"..aaaaaaaa..",
	".a........a.",
	".a........a.",
	".a....yy..a.",
	".a...yyyy.a.",
	"kkkkkkkkkkkk",
	"kmmmmmmmmmmk",
	"kmMmmmaamMmk",
	"kmmmmmaAmmmk",
	"kMMMMMMMMMMk",
	".kkkkkkkkkk.",
]
const SPR_RATOEIRA_ESTALADA: Array[String] = [
	"............",
	"............",
	"............",
	"............",
	"............",
	"............",
	"kaaaaaaaaaak",
	"kAAAAAAAAAAk",
	"kmMmmmaamMmk",
	"kmmmmmaAmmmk",
	"kMMMMMMMMMMk",
	".kkkkkkkkkk.",
]
const SPR_CATAPULTA: Array[String] = [
	"............",
	"............",
	"............",
	"............",
	"............",
	"............",
	".....kk.....",
	"....kmmk....",
	"...kmMMmk...",
	"..kmM..Mmk..",
	"kmAmmmmmmAmk",
	".kkkkkkkkkk.",
]
const SPR_SIRENE: Array[String] = [
	"............",
	"....kkkk....",
	"...krrrrk...",
	"..krrwrrRk..",
	"..krrrrrRk..",
	"..kRRRRRRk..",
	"..kkkkkkkk..",
	"...kAAAAk...",
	"....kAAk....",
	"....kAAk....",
	"..kkkkkkkk..",
	"..kAAAAAAk..",
]
const SPR_BALISTA: Array[String] = [
	"............",
	"......kmk...",
	"......wmmk..",
	"......w.mmk.",
	"......w..mk.",
	"......w..mk.",
	"ffBBBBwBBttk",
	"kmmmmmwmk...",
	".kMMMMwMmk..",
	"..kmmmw..mk.",
	"....kk.w.mk.",
	"......kmk...",
]
const SPR_CALDEIRAO_A: Array[String] = [
	"............",
	"............",
	"............",
	"..kkkkkkkk..",
	".kgGgggGggk.",
	".kkkkkkkkkk.",
	"kPPPPPPPPPPk",
	"kPppPPPPPPPk",
	"kPpPPPPPPPPk",
	".kPPPPPPPPk.",
	"..kkkkkkkk..",
	".o.oyo.oo.o.",
]
const SPR_CALDEIRAO_B: Array[String] = [
	"............",
	"............",
	"............",
	"..kkkkkkkk..",
	".kgggGgggGk.",
	".kkkkkkkkkk.",
	"kPPPPPPPPPPk",
	"kPppPPPPPPPk",
	"kPpPPPPPPPPk",
	".kPPPPPPPPk.",
	"..kkkkkkkk..",
	"o.oyo.oo.o.o",
]
const SPR_TROFEU: Array[String] = [
	".kkkkkkk.",
	"kkywyyykk",
	"k.kyyyk.k",
	".kkyyykk.",
	"...kyk...",
	"....k....",
	"...kyk...",
	"..kkkkk..",
]
const ENGR_A: Array[String] = [
	"...g...",
	".ggggg.",
	".gg.gg.",
	"gg.k.gg",
	".gg.gg.",
	".ggggg.",
	"...g...",
]
const ENGR_B: Array[String] = [
	"g.....g",
	".g.g.g.",
	"..ggg..",
	".ggkgg.",
	"..ggg..",
	".g.g.g.",
	"g.....g",
]

const SPR_FOSSO: Array[String] = [
	"............",
	"............",
	"............",
	"............",
	"............",
	"............",
	"...kkkkkk...",
	".kkMMMMMMkk.",
	"kMMkkkkkkMMk",
	"kMkPPPPPPkMk",
	"kMkPPppPPkMk",
	".kkkkkkkkkk.",
]
const SPR_REPELENTE: Array[String] = [
	"............",
	"....kkkk....",
	"....kyyk....",
	"...kkkkkk...",
	"...kGGGGk...",
	"...kGggGk...",
	"...kGwwGk...",
	"...kGggGk...",
	"...kGggGk...",
	"...kGGGGk...",
	"...kkkkkk...",
	"............",
]
const SPR_LUNETA: Array[String] = [
	"............",
	"........kk..",
	".......kaak.",
	"......kayyk.",
	".....kaAak..",
	"....kaAak...",
	"...kaAak....",
	"..kkAak.....",
	"....kmk.....",
	"...k.m.k....",
	"..k..m..k...",
	".kk..M..kk..",
]
const SPR_CASINHA: Array[String] = [
	"............",
	"....kkkk....",
	"...krrrrk...",
	"..krrrrrRk..",
	".krrrrrrrRk.",
	"kRRRRRRRRRRk",
	"kmmmkkkkmmmk",
	"kmmkPPPPkmmk",
	"kmmkPPPPkmmk",
	"kmmkPPPPkmmk",
	"kMMkPPPPkMMk",
	"kkkkkkkkkkkk",
]
const SPR_REFORCO: Array[String] = [
	"............",
	"kkkkkkkkkkkk",
	"kAAAAAAAAAAk",
	"kAkAAAAAAkAk",
	"kAAkAAAAkAAk",
	"kAAAkAAkAAAk",
	"kAAAAkkAAAAk",
	"kAAAkAAkAAAk",
	"kAAkAAAAkAAk",
	"kAkAAAAAAkAk",
	"kAAAAAAAAAAk",
	"kkkkkkkkkkkk",
]

# ---------------------------------------------------------------- utilidades
static func _r(c: Object, x: float, y: float, w: float, h: float, cor: Color) -> void:
	c.draw_rect(Rect2(x, y, w, h), cor)

## Desenha um bitmap de texto com pixels de G px; (x, y) é o canto de cima à esquerda.
static func spr(c: CanvasItem, x: float, y: float, linhas: Array, pal: Dictionary, f: float = 0.0, cel: float = G) -> void:
	for r in _corridas(linhas):
		var ch: String = r[3]
		if pal.has(ch):
			c.draw_rect(Rect2(x + int(r[0]) * cel, y + int(r[1]) * cel, int(r[2]) * cel, cel), Desenho.b(pal[ch], f))

static var _corridas_cache: Dictionary = {}

## Corridas horizontais de pixels iguais do bitmap, [coluna, linha, tamanho, letra], calculadas uma vez por bitmap.
static func _corridas(linhas: Array) -> Array:
	var chave: int = linhas.hash()
	var lista: Variant = _corridas_cache.get(chave)
	if lista != null:
		return lista
	var out: Array = []
	for j in linhas.size():
		var l: String = linhas[j]
		var i: int = 0
		while i < l.length():
			var ch: String = l[i]
			if ch == ".":
				i += 1
				continue
			var n: int = 1
			while i + n < l.length() and l[i + n] == ch:
				n += 1
			out.append([i, j, n, ch])
			i += n
	_corridas_cache[chave] = out
	return out

static func nivel(melhorias: Array, m: int) -> int:
	return clampi(int(melhorias[m]), 0, Torre.MELHORIA_NIVEL_MAX) if melhorias.size() > m else 0

# ---------------------------------------------------------------- geometria
static func y_corpo(base: Vector2) -> float:
	return base.y - CAIXA_H

static func linhas_cheias(n: int) -> int:
	return maxi(n, 0) / COLS

## Deslocamento horizontal (múltiplo de G) da fileira r: a torre fica torta quando perde blocos
## (as fileiras de cima entortam mais) e treme quando leva golpe.
static func desl(r: int, n: int, nmax: int, t: float, golpe: float) -> float:
	if r <= 0:
		return 0.0
	var dano: float = clampf(1.0 - float(n) / float(maxi(nmax, 1)), 0.0, 1.0)
	var torto: float = clampf((dano - 0.1) * 1.6, 0.0, 1.0)
	var k: float = minf(1.0, float(r) / 3.0)
	var d: float = sin(r * 2.1 + 0.7) * torto * 2.0 * k
	d += sin(t * 46.0) * golpe * k
	return roundf(d) * G

## Superfície da plataforma, onde pisam o vigia e o canhão.
static func y_piso(base: Vector2, n: int) -> float:
	return y_corpo(base) - linhas_cheias(n) * BH - 4.0

## Y do ponto mais alto da torre (topo da bandeira ou da pilha de blocos soltos).
static func topo_y(base: Vector2, n: int) -> float:
	var sobra: int = maxi(n, 0) % COLS
	return y_piso(base, n) - maxf(56.0, sobra * BH)

static func altura(base: Vector2, n: int) -> float:
	return base.y - topo_y(base, n)

## Retângulo do bloco i (0 = primeiro de baixo) numa torre com `n` blocos.
static func rect_bloco(base: Vector2, i: int, n: int, nmax: int, t: float = 0.0, golpe: float = 0.0) -> Rect2:
	var nf: int = linhas_cheias(n)
	var yc: float = y_corpo(base)
	if i < nf * COLS:
		var r: int = i / COLS
		var col: int = i % COLS
		return Rect2(base.x + col * BW + desl(r, n, nmax, t, golpe), yc - (r + 1) * BH, BW, BH)
	var k: int = i - nf * COLS
	return Rect2(base.x + 48.0 + desl(nf, n, nmax, t, golpe), y_piso(base, n) - (k + 1) * BH, BW, BH)

## Centro do bloco do topo (onde o Caldeirão assenta o bloco novo).
static func centro_topo(base: Vector2, n: int, nmax: int, t: float = 0.0, golpe: float = 0.0) -> Vector2:
	return rect_bloco(base, maxi(n - 1, 0), n, nmax, t, golpe).get_center()

## Retângulo do cano do canhão (já com o recuo).
static func rect_canhao(base: Vector2, n: int, nmax: int, melhorias: Array, t: float = 0.0, golpe: float = 0.0, recuo: float = 0.0) -> Rect2:
	var lv: int = nivel(melhorias, CANH)
	var th: float = CANHAO_ESP[lv]
	var comp: float = 24.0 + 8.0 * mini(lv, 5)   # 24 a 64 px (do nível 6 em diante o cano muda de cor e ganha anéis, não cresce); com a torre torta (até 12 px) a boca ainda fica em x <= 200
	var dxp: float = desl(linhas_cheias(n), n, nmax, t, golpe)
	var dxr: float = -roundf(recuo * 2.0) * G
	var x0: float = base.x + 112.0 + dxp + dxr
	return Rect2(x0, y_piso(base, n) - 8.0 - th, comp, th)

## Boca do canhão (de onde sai o tiro).
static func boca_canhao(base: Vector2, tijolos: int, tijolos_max: int, melhorias: Array, t: float = 0.0, golpe: float = 0.0, recuo: float = 0.0) -> Vector2:
	var r: Rect2 = rect_canhao(base, tijolos, tijolos_max, melhorias, t, golpe, recuo)
	return Vector2(r.end.x, r.position.y + r.size.y * 0.5)

## Encaixe do módulo i, de `n` montados. Até 3: 48x48 no chão, na frente da caixa (0 = lado direito, perto dos bichos;
## 1 = lado esquerdo; 2 = meio). Com 4: todos 36x36 em fila, para caberem na frente da caixa.
static func rect_encaixe(base: Vector2, i: int, n: int = 2) -> Rect2:
	if n >= 4:
		return Rect2(base.x + [124.0, 4.0, 84.0, 44.0][clampi(i, 0, 3)], base.y - 32.0, 36.0, 36.0)
	return Rect2(base.x + [112.0, 4.0, 58.0][clampi(i, 0, 2)], base.y - 44.0, 48.0, 48.0)

## Posição de onde o saco da catapulta parte (acima do encaixe).
static func ponta_catapulta(base: Vector2, i: int, n: int = 2) -> Vector2:
	var r: Rect2 = rect_encaixe(base, i, n)
	return r.position + Vector2(26.0, -4.0) * (r.size.x / 48.0)

# ---------------------------------------------------------------- desenho da torre
static func desenhar(c: CanvasItem, base: Vector2, tijolos: int, tijolos_max: int, melhorias: Array, modulos: Array, t: float, golpe: float, op: Dictionary = {}) -> void:
	var n: int = maxi(tijolos, 0)
	var nmax: int = maxi(tijolos_max, 1)
	var nf: int = linhas_cheias(n)
	var yc: float = y_corpo(base)
	var ys: float = y_piso(base, n)
	var pulso: float = float(op.get("pulso", 0.0))
	var recuo: float = float(op.get("recuo", 0.0))
	var luta: bool = bool(op.get("luta", true))
	var lv_est: int = nivel(melhorias, ESTR)
	var lv_cad: int = nivel(melhorias, CADE)
	var lv_enf: int = nivel(melhorias, ENFE)
	var dano: float = clampf(1.0 - float(n) / float(nmax), 0.0, 1.0)
	var dxp: float = desl(nf, n, nmax, t, golpe)
	var novo_i: int = int(op.get("novo_idx", -1))
	var novo_s: float = float(op.get("novo_s", -1.0))

	# Camada fixa (sombra, caixa, ameias, tábuas, blocos, reforços): vira malha em cache quando não há brilho
	# de pulso nem bloco novo assentando. O tremor do golpe entra na chave (deslocamento arredondado por fileira).
	if pulso <= 0.0 and not (novo_i >= 0 and novo_s >= 0.0 and novo_s < 1.4):
		_tocar(c, _camada_cache(base, n, nmax, nf, lv_est, lv_cad, lv_enf, t, golpe), t, luta, lv_est, lv_cad, lv_enf)
	else:
		_camada(c, base, n, nmax, nf, lv_est, lv_cad, lv_enf, t, golpe, luta, pulso, novo_i, novo_s)
	_bandeira(c, base.x + dxp, ys, t, lv_est)
	if bool(op.get("vigia", true)):
		_vigia(c, base.x + dxp + 8.0, ys, t, golpe, bool(op.get("vitoria", false)))
	_canhao(c, base, n, nmax, melhorias, t, golpe, recuo)
	for i in mini(modulos.size(), 4):
		_modulo(c, int(modulos[i]), rect_encaixe(base, i, modulos.size()), t, op)
	if golpe > 0.02:
		_poeira(c, base, golpe)

# ---------------------------------------------------------------- camada fixa em cache
## Grava as chamadas de desenho (retângulos e letras) da camada fixa para virarem malhas.
## Tem os mesmos métodos de desenho que o CanvasItem usa aqui, então `_r`/`_bloco` servem aos dois.
## Os blocos animados (engrenagem, cruz) cortam a gravação em segmentos: cada um vira uma malha e
## entre eles o gancho é desenhado ao vivo, na mesma ordem de antes.
class Grav extends RefCounted:
	var vs: PackedVector2Array = PackedVector2Array()
	var cs: PackedColorArray = PackedColorArray()
	var letras: Array = []
	var segmentos: Array = []   # {"malha": ArrayMesh, "letras": Array, "gancho": [tipo, posição, dy] ou null}

	func draw_rect(r: Rect2, cor: Color) -> void:
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			return
		vs.append(r.position)
		vs.append(Vector2(r.end.x, r.position.y))
		vs.append(r.end)
		vs.append(Vector2(r.position.x, r.end.y))
		for _k in 4:
			cs.append(cor)

	func draw_string(fonte: Font, pos: Vector2, txt: String, alin: int, larg: float, tam: int, cor: Color) -> void:
		letras.append([fonte, pos, txt, alin, larg, tam, cor])

	func cortar(gancho: Variant) -> void:
		var malha: ArrayMesh = null
		if vs.size() > 0:
			var idx: PackedInt32Array = PackedInt32Array()
			for q in vs.size() / 4:
				var b: int = q * 4
				idx.append_array(PackedInt32Array([b, b + 1, b + 2, b, b + 2, b + 3]))
			var arr: Array = []
			arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = vs
			arr[Mesh.ARRAY_COLOR] = cs
			arr[Mesh.ARRAY_INDEX] = idx
			malha = ArrayMesh.new()
			malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		segmentos.append({"malha": malha, "letras": letras, "gancho": gancho})
		vs = PackedVector2Array()
		cs = PackedColorArray()
		letras = []

static var _cache_camada: Dictionary = {}

static func _camada_cache(base: Vector2, n: int, nmax: int, nf: int, lv_est: int, lv_cad: int, lv_enf: int, t: float, golpe: float) -> Grav:
	var chave: String = "%s|%d|%d|%d|%d|%d" % [base, n, nmax, lv_est, int(lv_cad > 0), int(lv_enf > 0)]
	for r in range(1, nf + 1):
		chave += "|%d" % int(desl(r, n, nmax, t, golpe))
	var g: Grav = _cache_camada.get(chave)
	if g == null:
		if _cache_camada.size() > 48:
			_cache_camada.clear()
		g = Grav.new()
		_camada(g, base, n, nmax, nf, lv_est, lv_cad, lv_enf, t, golpe, true, 0.0, -1, -1.0)
		g.cortar(null)
		_cache_camada[chave] = g
	return g

static func _tocar(c: CanvasItem, g: Grav, t: float, luta: bool, lv_est: int, lv_cad: int, lv_enf: int) -> void:
	for s in g.segmentos:
		var malha: ArrayMesh = s["malha"]
		if malha != null:
			c.draw_mesh(malha, null)
		for l in s["letras"]:
			c.draw_string(l[0], l[1], l[2], l[3], l[4], l[5], l[6])
		var gancho: Variant = s["gancho"]
		if gancho != null:
			_gancho(c, int(gancho[0]), gancho[1], float(gancho[2]), t, luta, lv_est, lv_cad, lv_enf)

## Parte animada de um bloco especial (engrenagem da Cadência, cruz da Enfermaria): sempre ao vivo.
static func _gancho(c: CanvasItem, tipo: int, pos: Vector2, dy: float, t: float, luta: bool, lv_est: int, lv_cad: int, lv_enf: int) -> void:
	if tipo == 3:
		var cel: int = int(t * (2.0 + 1.6 * lv_cad)) % 2
		var pg: Dictionary = {"g": METAL[maxi(lv_est, 1)].lerp(Color(0.85, 0.85, 0.9), 0.2), "k": COR_CONTORNO}
		spr(c, pos.x + 4.0, pos.y - 4.0 + dy, ENGR_A if cel == 0 else ENGR_B, pg)
	elif tipo == 2 and luta:
		var pg2: float = 0.10 + 0.07 * sin(t * 3.0) + 0.02 * lv_enf
		_r(c, pos.x - 4.0, pos.y - 4.0, BW + 8.0, BH + 8.0, Color(0.4, 1.0, 0.5, pg2))
		var w: float = fposmod(t * 0.6, 1.0)   # + verde que sobe da cruz
		var cy: float = pos.y - 4.0 - w * 24.0
		var ax: float = roundf((pos.x + 28.0) / G) * G
		_r(c, ax, roundf(cy / G) * G, 4.0, 12.0, Color(0.5, 1.0, 0.6, 1.0 - w))
		_r(c, ax - 4.0, roundf(cy / G) * G + 4.0, 12.0, 4.0, Color(0.5, 1.0, 0.6, 1.0 - w))

## Sombra, caixa, ameias, tábuas, blocos e reforços. `c` é o CanvasItem (desenho direto) ou um Grav (gravação).
static func _camada(c: Object, base: Vector2, n: int, nmax: int, nf: int, lv_est: int, lv_cad: int, lv_enf: int, t: float, golpe: float, luta: bool, pulso: float, novo_i: int, novo_s: float) -> void:
	var dano: float = clampf(1.0 - float(n) / float(nmax), 0.0, 1.0)
	var dxp: float = desl(nf, n, nmax, t, golpe)
	var ys: float = y_piso(base, n)
	var gravando: bool = c is Grav
	_r(c, base.x - 4.0, base.y, 184.0, 8.0, Color(0, 0, 0, 0.22))   # sombra no chão
	_caixa(c, base)
	_caidos(c, base, dano, n)
	# ameias de pedra, atrás do vigia e do canhão
	_r(c, base.x + dxp, ys - 8.0, LARG, 8.0, PEDRA)
	_r(c, base.x + dxp, ys - 8.0, LARG, 4.0, PEDRA_CLARA)
	for k in 7:
		_r(c, base.x + dxp + 4.0 + k * 24.0, ys - 12.0, 12.0, 4.0, PEDRA_CLARA)
	# tábuas da plataforma
	_r(c, base.x - 4.0 + dxp, ys, 168.0, 4.0, METAL[lv_est] if lv_est >= 5 else TABUA)
	_r(c, base.x - 4.0 + dxp, ys, 4.0, 4.0, COR_CONTORNO)
	_r(c, base.x + 160.0 + dxp, ys, 4.0, 4.0, COR_CONTORNO)
	# blocos (fileiras cheias e os soltos de cima)
	for i in n:
		var rb: Rect2 = rect_bloco(base, i, n, nmax, t, golpe)
		var dy: float = 0.0
		var br: float = pulso
		if i == novo_i and novo_s >= 0.0 and novo_s < 1.4:
			if novo_s < 0.6:
				continue
			dy = roundf(-32.0 * (1.0 - clampf((novo_s - 0.6) / 0.3, 0.0, 1.0)) / G) * G
			br = maxf(br, clampf(1.0 - (novo_s - 0.6) / 0.8, 0.0, 1.0))
		var tipo: int = 0
		if i < nf * COLS:
			if i == JANELA_I:
				tipo = 1
			elif i == CRUZ_I and lv_enf > 0:
				tipo = 2
			elif i == ENGRENAGEM_I and lv_cad > 0:
				tipo = 3
		_bloco(c, rb.position + Vector2(0, dy), Desenho.b(Desenho.cor_tijolo(i), br), Desenho.letra_tijolo(i), tipo)
		if tipo >= 2:
			if gravando:
				c.cortar([tipo, rb.position, dy])
			else:
				_gancho(c, tipo, rb.position, dy, t, luta, lv_est, lv_cad, lv_enf)
	_reforcos(c, base, n, nmax, nf, lv_est, t, golpe)

static func _caixa(c: Object, base: Vector2) -> void:
	var x: float = base.x - 8.0
	var y: float = base.y - CAIXA_H
	_r(c, x, y, 176.0, CAIXA_H, COR_CONTORNO)
	_r(c, x + 4.0, y + 4.0, 168.0, 4.0, KRAFT_CLARO)
	_r(c, x + 4.0, y + 8.0, 168.0, 4.0, KRAFT)
	_r(c, x + 4.0, y + 12.0, 168.0, 0.0, KRAFT_ESCURO)
	_r(c, x + 76.0, y, 24.0, CAIXA_H, FITA)               # fita crepe
	_r(c, x + 76.0, y + 12.0, 24.0, 4.0, FITA.darkened(0.2))
	_r(c, x + 12.0, y + 8.0, 16.0, 4.0, KRAFT_ESCURO)    # etiqueta
	_r(c, x + 140.0, y + 8.0, 12.0, 4.0, KRAFT_ESCURO)

static func _bloco(c: Object, p: Vector2, cor: Color, letra: String, tipo: int = 0) -> void:
	_r(c, p.x, p.y, BW, BH, cor.darkened(0.55))
	_r(c, p.x + G, p.y + G, BW - 2.0 * G, BH - 2.0 * G, cor)
	_r(c, p.x + G, p.y + G, BW - 2.0 * G, G, cor.lightened(0.3))
	_r(c, p.x + G, p.y + BH - 2.0 * G, BW - 2.0 * G, G, cor.darkened(0.22))
	match tipo:
		0:
			_r(c, p.x + 16.0, p.y + 4.0, 8.0, 12.0, Color(0.99, 0.95, 0.82))
			_r(c, p.x + 12.0, p.y + 8.0, 16.0, 4.0, Color(0.99, 0.95, 0.82))
			c.draw_string(ThemeDB.fallback_font, Vector2(p.x + 20.0 - 6.6, p.y + 10.0 + 4.2), letra, HORIZONTAL_ALIGNMENT_CENTER, 13.2, 12, cor.darkened(0.4))
		1:  # janelinha acesa
			_r(c, p.x + 12.0, p.y + 4.0, 16.0, 12.0, Color(0.30, 0.18, 0.10))
			_r(c, p.x + 16.0, p.y + 8.0, 8.0, 4.0, Color(1.0, 0.90, 0.50))
			_r(c, p.x + 16.0, p.y + 8.0, 4.0, 4.0, Color(1.0, 0.97, 0.78))
		2:  # cruz da enfermaria
			_r(c, p.x + 16.0, p.y + 4.0, 8.0, 12.0, Color(0.30, 0.85, 0.45))
			_r(c, p.x + 12.0, p.y + 8.0, 16.0, 4.0, Color(0.30, 0.85, 0.45))
			_r(c, p.x + 16.0, p.y + 4.0, 8.0, 4.0, Color(0.55, 1.0, 0.65))

static func _meio(c: Object, x: float, y: float, w: float, h: float, cor: Color) -> void:
	_r(c, x, y, w, h, cor.darkened(0.55))
	_r(c, x + G, y + G, w - 2.0 * G, h - 2.0 * G, cor)

## Blocos caídos no chão, na frente da caixa: aparecem conforme a torre perde vida.
static func _caidos(c: Object, base: Vector2, dano: float, n: int) -> void:
	if n <= 0 or dano < 0.12:
		return
	var y: float = base.y + 4.0
	_bloco(c, Vector2(base.x + 76.0, y), Desenho.cor_tijolo(3), Desenho.letra_tijolo(3), 0)
	if dano >= 0.4:
		_meio(c, base.x + 124.0, y + 4.0, 20.0, 16.0, Desenho.cor_tijolo(6))
		_meio(c, base.x + 144.0, y, 20.0, 16.0, Desenho.cor_tijolo(6))

static func _reforcos(c: Object, base: Vector2, n: int, nmax: int, nf: int, lv: int, t: float, golpe: float) -> void:
	if lv <= 0 or nf <= 0:
		return
	var cor: Color = METAL[lv]
	var claro: Color = cor.lightened(0.35)
	var yc: float = y_corpo(base)
	# cantos de baixo (nível 1)
	var x0: float = base.x
	var x1: float = base.x + LARG
	_r(c, x0, yc - 4.0, 16.0, 4.0, cor)
	_r(c, x0, yc - 16.0, 4.0, 16.0, cor)
	_r(c, x1 - 16.0, yc - 4.0, 16.0, 4.0, cor)
	_r(c, x1 - 4.0, yc - 16.0, 4.0, 16.0, cor)
	_r(c, x0 + 4.0, yc - 8.0, 4.0, 4.0, claro)
	_r(c, x1 - 8.0, yc - 8.0, 4.0, 4.0, claro)
	# cantos de cima (nível 2), na fileira do topo
	var rt0: Rect2 = rect_bloco(base, (nf - 1) * COLS, n, nmax, t, golpe)
	var rt3: Rect2 = rect_bloco(base, (nf - 1) * COLS + 3, n, nmax, t, golpe)
	if lv >= 2:
		_r(c, rt0.position.x, rt0.position.y, 16.0, 4.0, cor)
		_r(c, rt0.position.x, rt0.position.y, 4.0, 16.0, cor)
		_r(c, rt3.end.x - 16.0, rt3.position.y, 16.0, 4.0, cor)
		_r(c, rt3.end.x - 4.0, rt3.position.y, 4.0, 16.0, cor)
		_r(c, rt0.position.x + 4.0, rt0.position.y + 4.0, 4.0, 4.0, claro)
		_r(c, rt3.end.x - 8.0, rt3.position.y + 4.0, 4.0, 4.0, claro)
	# níveis 6 a 8: rebites em todas as fileiras, filete no topo e joia na fileira de cima
	if lv >= 6:
		for r in nf:
			var rr: Rect2 = rect_bloco(base, r * COLS, n, nmax, t, golpe)
			var rq: Rect2 = rect_bloco(base, r * COLS + 3, n, nmax, t, golpe)
			_r(c, rr.position.x + 8.0, rr.position.y + 8.0, 4.0, 4.0, claro)
			_r(c, rq.end.x - 12.0, rq.position.y + 8.0, 4.0, 4.0, claro)
		if lv >= 7:
			_r(c, rt0.position.x, rt0.position.y, rt3.end.x - rt0.position.x, 4.0, cor)
		if lv >= 8:
			var jx: float = (rt0.position.x + rt3.end.x) * 0.5 - 4.0
			_r(c, jx, rt0.position.y - 4.0, 8.0, 8.0, Color(1.0, 1.0, 1.0))
			_r(c, jx + 2.0, rt0.position.y - 2.0, 4.0, 4.0, cor)
	# placas no meio (nível 3) e barras ao longo de toda a lateral (nível 4)
	for r in nf:
		var ra: Rect2 = rect_bloco(base, r * COLS, n, nmax, t, golpe)
		var rd: Rect2 = rect_bloco(base, r * COLS + 3, n, nmax, t, golpe)
		if lv >= 4:
			_r(c, ra.position.x, ra.position.y, 4.0, BH, cor)
			_r(c, rd.end.x - 4.0, rd.position.y, 4.0, BH, cor)
			if r % 3 == 1:
				_r(c, ra.position.x, ra.position.y + 8.0, 4.0, 4.0, claro)
				_r(c, rd.end.x - 4.0, rd.position.y + 8.0, 4.0, 4.0, claro)
		elif lv >= 3 and r == nf / 2:
			_r(c, ra.position.x, ra.position.y + 4.0, 8.0, 12.0, cor)
			_r(c, rd.end.x - 8.0, rd.position.y + 4.0, 8.0, 12.0, cor)
			_r(c, ra.position.x + 4.0, ra.position.y + 8.0, 4.0, 4.0, claro)
			_r(c, rd.end.x - 8.0, rd.position.y + 8.0, 4.0, 4.0, claro)

static func _bandeira(c: CanvasItem, x: float, ys: float, t: float, lv_est: int) -> void:
	_r(c, x, ys - 52.0, 4.0, 52.0, Color(0.88, 0.76, 0.55))
	_r(c, x, ys - 56.0, 4.0, 4.0, METAL[maxi(lv_est, 5)])
	var pano := Color(0.90, 0.35, 0.30)
	for i in 5:
		var dy: float = G if sin(t * 5.0 - i * 1.2) > 0.4 else 0.0
		_r(c, x + 4.0 + i * G, ys - 52.0 + dy, G, 12.0, pano if i < 4 else pano.darkened(0.15))
		_r(c, x + 4.0 + i * G, ys - 40.0 + dy - 4.0, G, 4.0, pano.darkened(0.2))
	_r(c, x + 8.0, ys - 48.0, 4.0, 4.0, Color(1, 0.93, 0.75))

static func _vigia(c: CanvasItem, x: float, ys: float, t: float, golpe: float, vitoria: bool) -> void:
	var pal: Dictionary = PAL_VIGIA.duplicate()
	if fposmod(t, 3.4) > 3.25:
		pal["e"] = pal["o"]   # piscou
	var yb: float = ys - 32.0
	var linhas: Array = VIGIA_NORMAL
	var tail_top: float = ys - 4.0 - 16.0
	if vitoria:
		yb -= roundf(absf(sin(t * 7.0)) * 2.0) * G
		linhas = VIGIA_FESTA
		_r(c, x, yb + 8.0, 4.0, 16.0, pal["o"])
		_r(c, x, yb + 8.0, 4.0, 4.0, pal["w"])
		_r(c, x + 40.0, yb + 8.0, 4.0, 16.0, pal["o"])
		_r(c, x + 40.0, yb + 8.0, 4.0, 4.0, pal["w"])
	elif golpe > 0.25:
		yb = ys - 20.0
		linhas = VIGIA_ABAIXADO
		tail_top = ys - 4.0 - 8.0
	else:
		tail_top -= (G if sin(t * 2.5) > 0.0 else 0.0)
	_r(c, x - 4.0, tail_top, 4.0, ys - 4.0 - tail_top, pal["o"])
	_r(c, x - 4.0, tail_top, 4.0, 4.0, pal["w"])
	spr(c, x, yb, linhas, pal)

static func _canhao(c: CanvasItem, base: Vector2, n: int, nmax: int, melhorias: Array, t: float, golpe: float, recuo: float) -> void:
	var lv: int = nivel(melhorias, CANH)
	var r: Rect2 = rect_canhao(base, n, nmax, melhorias, t, golpe, recuo)
	var cor: Color = CANHAO_COR[lv]
	var ys: float = y_piso(base, n)
	var dxp: float = desl(linhas_cheias(n), n, nmax, t, golpe)
	# carreta e rodas
	_r(c, base.x + 112.0 + dxp, ys - 8.0, 40.0, 8.0, TABUA.darkened(0.2))
	for wx in [116.0, 140.0]:
		_r(c, base.x + float(wx) + dxp, ys - 8.0, 8.0, 8.0, COR_CONTORNO)
		_r(c, base.x + float(wx) + dxp + 2.0, ys - 6.0, 4.0, 4.0, KRAFT_CLARO)
	# cano
	_r(c, r.position.x, r.position.y, r.size.x, r.size.y, cor.darkened(0.55))
	_r(c, r.position.x + G, r.position.y + G, r.size.x - 2.0 * G, r.size.y - 2.0 * G, cor)
	_r(c, r.position.x + G, r.position.y + G, r.size.x - 2.0 * G, G, cor.lightened(0.3))
	if r.size.y >= 16.0:
		_r(c, r.position.x + G, r.end.y - 2.0 * G, r.size.x - 2.0 * G, G, cor.darkened(0.22))
	_r(c, r.position.x - G, r.position.y + G, G, r.size.y - 2.0 * G, cor.darkened(0.3))   # culatra
	_r(c, r.end.x - 8.0, r.position.y - 4.0, 8.0, r.size.y + 8.0, cor.darkened(0.55))      # boca reforçada
	_r(c, r.end.x - 8.0 + 0.0, r.position.y, 4.0, r.size.y, cor.darkened(0.15))
	if lv >= 3:
		_r(c, r.position.x + 12.0, r.position.y + G, G, r.size.y - 2.0 * G, METAL[5])
		_r(c, r.position.x + 20.0, r.position.y + G, G, r.size.y - 2.0 * G, METAL[5])
	if lv >= 6:   # anéis na cor do nível
		for ax in ([28.0, 36.0] if lv < 8 else [28.0, 36.0, 44.0]):
			_r(c, r.position.x + ax, r.position.y, G, r.size.y, METAL[lv])
	if recuo > 0.55:  # clarão na boca
		var b: Vector2 = Vector2(r.end.x, r.position.y + r.size.y * 0.5)
		_r(c, b.x, b.y - 8.0, 8.0, 16.0, Color(1.0, 0.85, 0.3, 0.9))
		_r(c, b.x, b.y - 4.0, 16.0, 8.0, Color(1.0, 0.97, 0.8, 0.95))

static func _poeira(c: CanvasItem, base: Vector2, golpe: float) -> void:
	var u: float = 1.0 - golpe
	for k in 7:
		var s: float = roundf((8.0 + u * 10.0) / G) * G
		var px: float = roundf((base.x - 4.0 + k * 28.0 + sin(k * 3.1) * 6.0) / G) * G
		var py: float = roundf((base.y - 8.0 - u * 26.0 * (0.5 + (k % 3) * 0.4)) / G) * G
		_r(c, px, py, s, s, Color(0.86, 0.80, 0.70, 0.55 * golpe))

# ---------------------------------------------------------------- módulos
static func _modulo(c: CanvasItem, m: int, r: Rect2, t: float, op: Dictionary) -> void:
	var x: float = r.position.x
	var y: float = r.position.y
	var pal: Dictionary = PAL_MOD.duplicate()
	if r.size.x < 47.0:
		_modulo_pequeno(c, m, r, t, op, pal)
		return
	match m:
		Torre.Modulo.RATOEIRA:
			var estala: float = float(op.get("ratoeira", 0.0))
			spr(c, x, y, SPR_RATOEIRA_ESTALADA if estala > 0.0 else SPR_RATOEIRA, pal)
			if estala > 0.0:
				_r(c, x - 4.0, y + 20.0, 56.0, 24.0, Color(1.0, 0.95, 0.6, 0.55 * minf(1.0, estala / 0.3)))
		Torre.Modulo.CATAPULTA:
			spr(c, x, y, SPR_CATAPULTA, pal)
			var desde: float = float(op.get("catapulta", -1.0))
			var u: float = 0.0
			if desde >= 0.0 and desde < 1.8:
				if desde < 0.12:
					u = desde / 0.12
				elif desde < 1.0:
					u = 1.0
				else:
					u = 1.0 - (desde - 1.0) / 0.8
			var piv: Vector2 = Vector2(x + 24.0, y + 24.0)
			var ang: float = deg_to_rad(lerpf(-160.0, -35.0, u))
			var d: Vector2 = Vector2(cos(ang), sin(ang))
			for s in 7:
				var q: Vector2 = piv + d * (s * G)
				_r(c, floorf(q.x / G) * G, floorf(q.y / G) * G, G, G, pal["M"] if s % 2 == 0 else pal["m"])
			var tp: Vector2 = piv + d * (7.0 * G)
			var tx: float = floorf(tp.x / G) * G
			var ty: float = floorf(tp.y / G) * G
			_r(c, tx - 4.0, ty, 12.0, 4.0, pal["A"])           # colher
			if u <= 0.0:
				_r(c, tx - 4.0, ty - 12.0, 12.0, 12.0, COR_CONTORNO)
				_r(c, tx, ty - 8.0, 8.0, 8.0, Color(0.78, 0.58, 0.32))
				_r(c, tx, ty - 8.0, 8.0, 4.0, Color(0.9, 0.72, 0.45))
				_r(c, tx, ty - 16.0, 4.0, 4.0, pal["R"])
		Torre.Modulo.SIRENE:
			var ativo: float = float(op.get("sirene", 0.0))
			var ritmo: float = 16.0 if ativo > 0.0 else 2.2
			var p: float = 0.5 + 0.5 * sin(t * ritmo)
			pal["r"] = Color(0.70, 0.14, 0.14).lerp(Color(1.0, 0.50, 0.38), p)
			pal["R"] = Color(0.45, 0.08, 0.10).lerp(Color(0.8, 0.2, 0.2), p)
			spr(c, x, y, SPR_SIRENE, pal)
			if ativo > 0.0:
				var lado: float = 1.0 if sin(t * ritmo) > 0.0 else -1.0
				var bx: float = x + (36.0 if lado > 0.0 else -4.0)
				_r(c, bx, y + 8.0, 16.0, 8.0, Color(1.0, 0.3, 0.25, 0.55))
				_r(c, bx + (4.0 if lado > 0.0 else 8.0), y + 8.0, 4.0, 8.0, Color(1.0, 0.7, 0.6, 0.75))
		Torre.Modulo.BALISTA:
			if float(op.get("balista", 0.0)) > 0.0:
				pal.erase("f")
				pal.erase("B")
				pal.erase("t")
			spr(c, x, y, SPR_BALISTA, pal)
		Torre.Modulo.CALDEIRAO:
			var ferve: float = float(op.get("caldeirao", 0.0))
			var cel: int = int(t * (6.0 if ferve > 0.0 else 3.0)) % 2
			spr(c, x, y, SPR_CALDEIRAO_A if cel == 0 else SPR_CALDEIRAO_B, pal)
			for k in 3:
				var w: float = fposmod(t * (1.2 if ferve > 0.0 else 0.7) + k * 0.33, 1.0)
				var bs: float = G if ferve <= 0.0 else (G if w < 0.5 else 8.0)
				var bx2: float = x + (4 + k * 3) * G
				var by2: float = y + 3.0 * G - w * (3.0 if ferve <= 0.0 else 5.0) * G
				_r(c, bx2, floorf(by2 / G) * G, bs, bs, Color(0.7, 1.0, 0.6, 1.0 - w * 0.8))

		Torre.Modulo.FOSSO:
			spr(c, x, y, SPR_FOSSO, pal)
			var cai: float = float(op.get("fosso", 0.0))
			if cai > 0.0:
				_r(c, x + 16.0, y + 28.0 - minf(cai, 0.6) * 12.0, 16.0, 8.0, Color(1.0, 0.95, 0.6, minf(1.0, cai * 2.0)))
			for k in 2:
				var w2: float = fposmod(t * 0.5 + k * 0.5, 1.0)
				_r(c, x + (16.0 + k * 12.0), floorf((y + 36.0 - w2 * 12.0) / G) * G, G, G, Color(0.55, 0.45, 0.35, 1.0 - w2))
		Torre.Modulo.REPELENTE:
			spr(c, x, y, SPR_REPELENTE, pal)
			var nuvem: float = 0.35 + 0.3 * sin(t * 2.0)
			for k in 3:
				var w3: float = fposmod(t * 0.45 + k * 0.33, 1.0)
				_r(c, floorf((x + 28.0 + w3 * 20.0) / G) * G, floorf((y + 12.0 - sin(w3 * 3.0 + k) * 6.0) / G) * G, 8.0, 8.0, Color(0.6, 1.0, 0.5, (1.0 - w3) * (0.5 + nuvem)))
		Torre.Modulo.LUNETA:
			spr(c, x, y, SPR_LUNETA, pal)
			if fposmod(t, 2.4) > 2.2 or float(op.get("luneta", 0.0)) > 0.0:
				_r(c, x + 36.0, y + 4.0, 4.0, 4.0, Color(1, 1, 0.8))
		Torre.Modulo.CASINHA:
			spr(c, x, y, SPR_CASINHA, pal)
			if fposmod(t, 3.0) > 2.6:
				_r(c, x + 20.0, y + 28.0, 4.0, 4.0, pal["y"])
		Torre.Modulo.REFORCO:
			spr(c, x, y, SPR_REFORCO, pal)
			var rf: float = float(op.get("reforco", 0.0))
			if rf > 0.0:
				_r(c, x - 4.0, y - 4.0, 56.0, 56.0, Color(0.7, 0.85, 1.0, 0.45 * minf(1.0, rf / 0.3)))

## Os mesmos módulos em 36x36 (4 montados): bitmaps de 12x12 com pixels de 3 px, sem os efeitos animados.
static func _modulo_pequeno(c: CanvasItem, m: int, r: Rect2, t: float, _op: Dictionary, pal: Dictionary) -> void:
	var sprs: Array = [SPR_RATOEIRA, SPR_CATAPULTA, SPR_SIRENE, SPR_BALISTA, SPR_CALDEIRAO_A, SPR_FOSSO, SPR_REPELENTE, SPR_LUNETA, SPR_CASINHA, SPR_REFORCO]
	if m == Torre.Modulo.CALDEIRAO and int(t * 3.0) % 2 == 1:
		spr(c, r.position.x, r.position.y, SPR_CALDEIRAO_B, pal, 0.0, 3.0)
		return
	if m == Torre.Modulo.SIRENE:
		var p: float = 0.5 + 0.5 * sin(t * 2.2)
		pal["r"] = Color(0.70, 0.14, 0.14).lerp(Color(1.0, 0.50, 0.38), p)
	spr(c, r.position.x, r.position.y, sprs[clampi(m, 0, sprs.size() - 1)], pal, 0.0, 3.0)

# ---------------------------------------------------------------- avulsos
## Troféu dourado (9x8 pixels de `cel` px), centrado em `p`.
static func desenhar_trofeu(c: CanvasItem, p: Vector2, cel: float = 3.0, alfa: float = 1.0) -> void:
	var pal: Dictionary = {"k": Color(0.30, 0.18, 0.04, alfa), "y": Color(1.0, 0.82, 0.25, alfa), "w": Color(1.0, 0.97, 0.75, alfa)}
	spr(c, p.x - 4.5 * cel, p.y - 4.0 * cel, SPR_TROFEU, pal, 0.0, cel)

## Gato vigia isolado (para o guarda-roupa): x,y = canto de cima à esquerda do bitmap de 10x8.
static func desenhar_vigia(c: CanvasItem, pos: Vector2, t: float, abaixado: bool = false, festa: bool = false) -> void:
	_vigia(c, pos.x, pos.y + 32.0, t, 1.0 if abaixado else 0.0, festa)
