class_name RoupaGatoJ
extends RefCounted
## Roupas do gato em pixel art, tipos 196 em diante (ver RoupaGato para as convenções): expansão das fantasias, lote 5
## (Ranger Miau 196-199, Miauzilla 200-203, King-Miau 204-207, Arthur Miaurgon 208-211, Submiautica 212-215, Catchullu 216-219).
##
## FALLBACK: enquanto uma peça não tem arte própria em `_camadas`, desenha a silhueta de uma peça do mesmo espaço (cabeça, corpo,
## mão ou acessório do lado de fora, em RoupaGatoE.PECAS) tingida com a cor da fantasia (Ranger verde, Miauzilla verde-água...).
## COMO O ARTISTA ENTRA: devolva em `_camadas` as camadas [x, y, linhas, paleta] da peça (mesmo formato de RoupaGatoE._camadas);
## `caixa` e `desenhar` já usam o que vier de lá. Descrição visual de cada peça: notas/lote5/para_arte.md.

const PRIMEIRO := 196
## Silhuetas de reserva por espaço (cabeça, corpo, mão, acessório); cada fantasia usa uma das 4 colunas, para não ficarem todas iguais.
const _MOLDE_FALLBACK: Array = [
	[Pecas.Tipo.CAPACETE_AZUL, Pecas.Tipo.BANDANA_FOLHA, Pecas.Tipo.CAPUZ_TUBARAO, Pecas.Tipo.ANTENAS],
	[Pecas.Tipo.COLETE_LISTRADO, Pecas.Tipo.MACACAO_LARANJA, Pecas.Tipo.ARMADURA_AZUL, Pecas.Tipo.ROUPA_TUBARAO],
	[Pecas.Tipo.KUNAI, Pecas.Tipo.CANHAO_BRACO, Pecas.Tipo.MORDIDA, Pecas.Tipo.FERRAO],
	[Pecas.Tipo.TANQUE, Pecas.Tipo.PERGAMINHO, Pecas.Tipo.BOIA, Pecas.Tipo.POTE_MEL],
]

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão (cabeça, corpo, boca e traseira).
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.TENTACULO_FOFO:
			return RoupaGato.Onde.CORPO
		Pecas.Tipo.TANQUE_PEIXINHO:
			return RoupaGato.Onde.CORPO
		Pecas.Tipo.CADERNINHO:
			return RoupaGato.Onde.CORPO
		Pecas.Tipo.PULSEIRA_TRANSFORMAR, Pecas.Tipo.CAUDA_RADIOATIVA, Pecas.Tipo.BIPLANO_PAPEL:
			return RoupaGato.Onde.CORPO
	return -1

## Peças com camada atrás do corpo do gato (asas do manto do Catchullu).
static func tem_atras(tipo: int) -> bool:
	return tipo == Pecas.Tipo.CAUDA_RADIOATIVA or tipo == Pecas.Tipo.MANTO_ABISSAL or tipo == Pecas.Tipo.TANQUE_PEIXINHO

# ------------------------------------------------------------------ ferramentas (usam as de RoupaGatoF e RoupaGatoG)
static func _ret(cv: Dictionary, x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	RoupaGatoF._ret(cv, x0, y0, x1, y1, ch)

static func _px(cv: Dictionary, x: int, y: int, ch: String) -> void:
	cv[Vector2i(x, y)] = ch

static func _lin(cv: Dictionary, a: Vector2i, b: Vector2i, ch: String) -> void:
	RoupaGatoF._lin(cv, a, b, ch)

static func _poli(cv: Dictionary, p: Array, ch: String) -> void:
	RoupaGatoF._poli(cv, p, ch)

static func _cont(cv: Dictionary, ch: String, baixo: bool = true) -> void:
	RoupaGatoF._cont(cv, ch, baixo)

static func _luz(cv: Dictionary, base: String, luz: String, sombra: String = "") -> void:
	RoupaGatoF._luz(cv, base, luz, sombra)

static func _lay(cv: Dictionary, lugar: int, pal: Dictionary, atras: bool = false) -> Array:
	return RoupaGatoF._lay(cv, lugar, pal, atras)

static func _txt(cv: Dictionary, x: int, y: int, linhas: Array) -> void:
	RoupaGatoG._txt(cv, x, y, linhas)

## Camadas da peça com arte própria; vazio = usa o fallback.
static func _camadas(tipo: int, anim: float, maxima: bool = false) -> Array:
	if _cache.has(tipo):
		return _cache[tipo]
	var r: Array = _montar(tipo)
	_cache[tipo] = r
	return r

static var _cache: Dictionary = {}

static func _montar(tipo: int) -> Array:
	var cv: Dictionary = {}
	match tipo:
		Pecas.Tipo.CHAPEU_FORA_LEI:
			return _ar_chapeu()
		Pecas.Tipo.CASACO_LENCO:
			return _ar_casaco()
		Pecas.Tipo.RIFLE_CACADOR:
			return _ar_revolver()
		Pecas.Tipo.CADERNINHO:
			return _ar_diario()
		Pecas.Tipo.CAPACETE_AQUARIO:
			return _sub_capuz()
		Pecas.Tipo.MACACAO_PRESSURIZADO:
			return _sub_pele()
		Pecas.Tipo.RIFLE_ESTASE:
			return _sub_rifle()
		Pecas.Tipo.TANQUE_PEIXINHO:
			return _sub_cauda()
		Pecas.Tipo.CABECA_POLVO:
			return _cth_cabeca()
		Pecas.Tipo.MANTO_ABISSAL:
			return _cth_manto()
		Pecas.Tipo.NECRONOMIAU:
			return _cth_livro()
		Pecas.Tipo.TENTACULO_FOFO:
			return _cth_tentaculo()
		Pecas.Tipo.CAPACETE_VISEIRA:
			return _rg_capacete()
		Pecas.Tipo.MACACAO_LYCRA:
			return _rg_macacao()
		Pecas.Tipo.SABRE_BLASTER:
			return _rg_luva()
		Pecas.Tipo.PULSEIRA_TRANSFORMAR:
			return _rg_pulseira()
		Pecas.Tipo.CRISTA_PLACAS:
			return _mz_crista()
		Pecas.Tipo.PELE_ATOMICA:
			return _mz_pele()
		Pecas.Tipo.GARRAS_MONSTRO:
			return _mz_bafo()
		Pecas.Tipo.CAUDA_RADIOATIVA:
			return _mz_cauda()
		Pecas.Tipo.CABECA_GORILA:
			return _km_gorila()
		Pecas.Tipo.PELAGEM_GORILA:
			return _km_pelagem()
		Pecas.Tipo.PREDIO_BRINQUEDO:
			return _km_mao()
		Pecas.Tipo.BIPLANO_PAPEL:
			return _km_banana()
		_:
			pass
	return []

# ------------------------------------------------------------------ Arthur Miaurgon (Arthur Morgan, RDR2): couro preto com brilho azulado
## c/C/S couro preto (médio, brilho cinza-azulado, sombra); K/k camisa clara e v colete; m/M couro marrom (cinto, tira, faixa do chapéu, cabo, caderninho);
## F/G balas e fivela dourada; t/T/u aço do revólver; p folhas do caderninho.
const _PAL_ARTHUR := {
	"o": Color("08080c"), "c": Color("2a2d38"), "C": Color("8aa4c4"), "S": Color("14151b"),
	"v": Color("3e4252"), "K": Color("ddd6c0"), "k": Color("a8a088"),
	"m": Color("5e3a22"), "M": Color("a06a32"), "F": Color("e8b83c"), "G": Color("fff0a0"),
	"t": Color("6a7484"), "T": Color("b4bece"), "u": Color("363c48"),
	"p": Color("e6dcc0"),
}

## Linha mais baixa ocupada de `cv` na coluna x (-99 se vazia).
static func _topo_col(cv: Dictionary, x: int) -> int:
	var b: int = -99
	for y in range(-16, 3):
		if cv.has(Vector2i(x, y)):
			b = y
	return b

## Mandíbula em foice, preenchida: o contorno `q` (pontos x, y) com a base grossa (3 px) que afina até a ponta curva de 1 px; luz ferrugem em cima e
## sombra embaixo. `k` 0 e 1 = par da frente e de trás em cima; 2 e 3 = o espelho embaixo (a de trás embaixo é menor); `s` = abertura.
static func _mand(cv: Dictionary, k: int, s: float) -> void:
	var ps: Array = [
		[11, -16, 13, -18, 15, -19.5, 17.5, -19.5, 19.5, -17, 19, -15.5, 17, -17.5, 15, -17, 13, -14.5, 11, -13],
		[8, -17, 8, -20, 9.5, -22.5, 12, -24, 14.5, -24, 16.5, -22, 16.5, -20, 14.5, -22, 12, -21.5, 10.5, -19.5, 11, -16],
	]
	var q: Array = ps[k % 2]
	var f: float = 1.0 if k % 2 == 0 else 0.8
	var pts: Array = []
	for n in range(0, q.size(), 2):
		var x: float = 11.0 + (float(q[n]) - 11.0) * s
		var y: float = -12.5 + (float(q[n + 1]) + 12.5) * s * (f if k >= 2 else 1.0)
		if k >= 2:
			y = -12.5 - (y + 12.5)
		pts.append(x)
		pts.append(y)
	var m: Dictionary = {}
	RoupaGatoI._poli(m, pts, "r")
	RoupaGatoI._luz(m, "r", "R", "D")
	for kk in m.keys():
		cv[kk] = m[kk]

## Asa de morcego: do ombro `sh` até as pontas `tips` (x, y), a membrana (recortada em arcos entre as pontas) e, se `osso`, os três dedos claros.
static func _asa(cv: Dictionary, sh: Vector2, tips: Array, esc: float, osso: bool) -> void:
	var ts: Array = []
	for t in tips:
		ts.append(sh + (Vector2(t[0], t[1]) - sh) * esc)
	var pts: Array = [sh.x, sh.y]
	for i in ts.size():
		var t2: Vector2 = ts[i]
		pts.append(t2.x)
		pts.append(t2.y)
		if i < ts.size() - 1:
			var n: Vector2 = ts[i + 1]
			var m: Vector2 = (t2 + n) * 0.5
			m = m + (sh - m) * 0.28
			pts.append(m.x)
			pts.append(m.y)
	var last: Vector2 = ts[ts.size() - 1]
	pts.append(last.x)
	pts.append(last.y)
	pts.append(sh.x - 4)
	pts.append(sh.y + 1)
	RoupaGatoI._poli(cv, pts, "w")
	if osso:
		for t3 in ts:
			var q: Vector2 = t3
			RoupaGatoI._lin(cv, Vector2i(roundi(sh.x), roundi(sh.y)), Vector2i(roundi(q.x), roundi(q.y)), "W")

## Chapéu de caubói preto gasto: copa alta (5 px) que afina em cima com o vinco em V dos dois lados, faixa marrom e aba larga (14 px) em sela
## (sobe nos lados, desce na frente e atrás) com a sombra por baixo.
static func _ar_chapeu() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, 0, -23, [
		"....cc..cc....",
		"....ccSScc....",
		"...cccSSccc...",
		"...cccSSccc...",
		"...cccccccc...",
		"c..MMMMMMMM..c",
		".cccccccccccc.",
		"..cccccccccc..",
		"...SSSSSSSS...",
	])
	RoupaGatoI._luz(cv, "c", "C", "S")
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CABECA, _PAL_ARTHUR)]

## Jaqueta de couro preta aberta no peito (camisa clara em cima, colete embaixo), gola e lapela viradas com brilho claro, tira a tiracolo,
## cartucheira de balas douradas com a fivela e o coldre no flanco.
static func _ar_casaco() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._corpo_vest(cv, "c", -6, -8, -6)
	RoupaGatoI._gola(cv, "c", 2)
	for y in range(-11, -5):
		for x in range(5, 8):
			if cv.has(Vector2i(x, y)):
				cv[Vector2i(x, y)] = "K" if y < -8 else "v"
	if cv.has(Vector2i(4, -11)):
		cv[Vector2i(4, -11)] = "K"
	cv[Vector2i(6, -7)] = "F"
	cv[Vector2i(6, -9)] = "k"
	RoupaGatoI._luz(cv, "c", "C", "S")
	for y2 in range(-12, -6):
		if cv.has(Vector2i(4, y2)) and cv[Vector2i(4, y2)] != "K":
			cv[Vector2i(4, y2)] = "C"
	for p in [Vector2i(3, -15), Vector2i(3, -14), Vector2i(2, -14), Vector2i(-6, -10), Vector2i(-5, -10), Vector2i(-4, -11), Vector2i(-1, -12), Vector2i(0, -12), Vector2i(1, -11), Vector2i(-7, -8), Vector2i(2, -9)]:
		if cv.has(p):
			cv[p] = "C"
	RoupaGatoI._linsobre(cv, Vector2i(3, -12), Vector2i(-3, -6), "m")
	for x in range(-8, 9):
		var b: int = _topo_col(cv, x)
		if b > -99:
			cv[Vector2i(x, b)] = "F" if posmod(x, 2) == 0 else "M"
			cv[Vector2i(x, b + 1)] = "m"
	for x2 in range(4, 7):
		var b2: int = _topo_col(cv, x2)
		cv[Vector2i(x2, b2 - 1)] = "F"
		cv[Vector2i(x2, b2)] = "G" if x2 == 5 else "F"
		cv[Vector2i(x2, b2 + 1)] = "F"
	var bc: int = _topo_col(cv, 0)
	for x3 in range(-1, 2):
		for y3 in range(bc + 1, bc + 3):
			cv[Vector2i(x3, y3)] = "M" if y3 == bc + 1 else "m"
	cv[Vector2i(0, bc)] = "u"
	cv[Vector2i(1, bc)] = "u"
	RoupaGatoI._cont(cv, "o", false)
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_ARTHUR)]

## Revólver curto (12 px): martelo, cano escuro com fio de luz no alto, tambor, guarda-mato e cabo de madeira.
static func _ar_revolver() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, 11, -13, [
		"..t.........",
		".uTTTTTTTTT.",
		".uuutuuuuuuu",
		".uuutuuuuuu.",
		"mmuu........",
		"mMm.........",
		".mm.........",
	])
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.BOCA, _PAL_ARTHUR)]

## Caderninho pequeno de couro marrom com a tira e o fecho dourado, folhas na borda.
static func _ar_diario() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, -7, -16, [
		"MMMMp",
		"MmmMp",
		"mFFmp",
		"MmmMp",
		"MMMMp",
	])
	for p in [Vector2i(-5, -11), Vector2i(-5, -10), Vector2i(-4, -9), Vector2i(-4, -8)]:
		cv[p] = "m"
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_ARTHUR)]

# ------------------------------------------------------------------ Submiautica (Reaper Leviathan): azul-acinzentado, faixas ferrugem, mandíbulas em gancho
## a/A/d corpo azul-acinzentado (médio, luz, sombra); r/R/D faixas e barbatana vermelho-ferrugem; m/M mandíbulas verde-oliva escuras; k/E olho preto e aro;
## w barriga clara; s/S/e/h aço azul do rifle de estase e brilho ciano da câmara (halo, núcleo, miolo).
const _PAL_SUB := {
	"o": Color("0c1822"), "a": Color("7a9eb2"), "A": Color("b0cdd8"), "d": Color("46687e"),
	"r": Color("b0502c"), "R": Color("e8946a"), "D": Color("6e2a18"),
	"k": Color("0c1018"), "E": Color("d6e6ea"), "w": Color("dfe9e4"),
	"s": Color("96a6b6"), "S": Color("2a78b0"), "e": Color("4cc8f0"), "h": Color("eafbff"), "u": Color("2e3a48"),
}

## Cabeça do Reaper: crânio azul-acinzentado alongado para a frente com o olho pequeno e a boca de dentes, crista curta varrida para trás e as quatro
## mandíbulas ferrugem em foice grossa (abertura de 80%), em pinça em volta da boca (duas em cima, duas embaixo).
static func _sub_capuz() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._poli(cv, [2, -19, 8, -18, 13, -15, 15, -12, 14, -10, 9, -10, 3, -10], "a")
	RoupaGatoI._luz(cv, "a", "A", "d")
	for p in [Vector2i(8, -15), Vector2i(9, -15), Vector2i(8, -14), Vector2i(9, -14)]:
		cv[p] = "k"
	cv[Vector2i(8, -16)] = "E"
	cv[Vector2i(9, -16)] = "E"
	for x in range(11, 15):
		cv[Vector2i(x, -12)] = "k"
	cv[Vector2i(12, -11)] = "w"
	cv[Vector2i(14, -11)] = "w"
	RoupaGatoI._lin(cv, Vector2i(5, -19), Vector2i(0, -23), "r")
	RoupaGatoI._lin(cv, Vector2i(6, -19), Vector2i(1, -23), "R")
	RoupaGatoI._lin(cv, Vector2i(6, -18), Vector2i(2, -21), "r")
	for k in 4:
		_mand(cv, k, 0.8)
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CABECA, _PAL_SUB)]

## Pele do Leviatã: corpo azul-acinzentado justo com faixas ferrugem diagonais (período de 6 px) e a barriga clara.
static func _sub_pele() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._corpo_vest(cv, "a", -5, -7, -5)
	RoupaGatoI._luz(cv, "a", "A", "d")
	for k in cv.keys():
		var q: Vector2i = k
		if q.y < -5 and posmod(q.x + q.y, 6) < 2 and cv[q] != "A":
			cv[q] = "r"
	for x in range(-3, 4):
		for y in range(-7, 0):
			if cv.has(Vector2i(x, y)) and cv[Vector2i(x, y)] != "r":
				cv[Vector2i(x, y)] = "w"
	RoupaGatoI._cont(cv, "o", false)
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_SUB)]

## Rifle de estase: coronha, câmara larga com núcleo ciano e halo escuro, cano com anéis (começa depois das mandíbulas).
static func _sub_rifle() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, 16, -15, [
		"..SSSSS......",
		"ssSeeeSAAAAAA",
		"ssSehheSaaDaa",
		"ssSeeeSddddd.",
		"u.SSSSS...aa.",
		"uu...........",
	])
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.BOCA, _PAL_SUB)]

## Cauda do Reaper, atrás do corpo: sai da garupa na mesma pele e faixas do corpo, sobe um pouco e cai para trás afinando até o leque de nadadeiras finas.
static func _sub_cauda() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._poli(cv, [-6, -12.5, -10, -14.5, -14, -15, -18, -13.5, -21, -11, -23, -8.5, -23, -7.5, -22, -8, -19, -10, -15, -11.5, -11, -10, -8, -7, -6, -6.5], "a")
	RoupaGatoI._luz(cv, "a", "A", "d")
	for k in cv.keys():
		var q: Vector2i = k
		if posmod(q.x + q.y, 6) < 2 and cv[q] != "A":
			cv[q] = "r"
	RoupaGatoI._lin(cv, Vector2i(-23, -8), Vector2i(-26, -11), "r")
	RoupaGatoI._lin(cv, Vector2i(-23, -8), Vector2i(-26, -5), "r")
	RoupaGatoI._lin(cv, Vector2i(-23, -8), Vector2i(-27, -8), "r")
	RoupaGatoI._lin(cv, Vector2i(-22, -8), Vector2i(-25, -10), "R")
	RoupaGatoI._lin(cv, Vector2i(-22, -8), Vector2i(-25, -6), "R")
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_SUB, true)]

# ------------------------------------------------------------------ Catchullu (Cthulhu): verde-acinzentado escuro, roxo e olhos amarelos
## a/A/d pele verde-acinzentada (média, luz, sombra); m/M/D manto verde-azulado; w/W asa de morcego (membrana escura, luz); y/Y olho amarelo (e brilho);
## p/P/q tentáculos roxos (médio, luz, sombra); b/B/Q capa do livro (média, luz, lombo); F metal dourado; i gota d'água.
const _PAL_CTHU := {
	"o": Color("08141a"), "a": Color("3c7c68"), "A": Color("70b49c"), "d": Color("22483e"),
	"m": Color("245c6a"), "M": Color("3e8896"), "D": Color("143642"),
	"w": Color("48287a"), "W": Color("d6caf6"), "v": Color("2c1a44"),
	"y": Color("f0d848"), "Y": Color("fff6b0"),
	"p": Color("8a5aa8"), "P": Color("b88ad0"), "q": Color("5a3a7a"),
	"b": Color("6a3f7a"), "B": Color("9a66aa"), "Q": Color("3e2248"), "F": Color("c8a458"), "i": Color("cfeaf4"),
}

## Cabeça de polvo: domo bulboso verde-acinzentado com a sobrancelha pesada e os olhos amarelos brilhantes; sob o focinho, quatro tentáculos
## de 2 px (comprimentos 5, 7, 6 e 4, pontas roxas e enroladas).
static func _cth_cabeca() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, 1, -23, [
		"...aaaaaaaa...",
		"..aaaaaaaaaa..",
		".aaaaaaaaaaaa.",
		".aaaaaaaaaaaa.",
		".aaaaaaaaaaaaa",
		".dddddddddddda",
		".aayYaaaayYaaa",
		".aayyaaaayyaaa",
		"..aaaaaaaaaaa.",
	])
	RoupaGatoI._luz(cv, "a", "A", "d")
	# tentáculos da barba, a partir do queixo
	var ts: Array = [[5, 5], [7, 7], [9, 6], [11, 4]]
	for t in ts:
		var x0: int = int(t[0])
		var n: int = int(t[1])
		for k in n:
			var y: int = -14 + k
			var sx: int = 1 if (k >= n - 2 and x0 > 8) else 0
			cv[Vector2i(x0 + sx, y)] = "a" if k < n - 2 else "p"
			cv[Vector2i(x0 + sx + 1, y)] = "A" if k < n - 2 else "P"
		cv[Vector2i(x0 + (2 if x0 > 8 else 1), -14 + n - 1)] = "q"
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CABECA, _PAL_CTHU)]

## Duas asas de morcego atrás do corpo: a da frente maior (dedos lilás-claros, 3 pontas, membrana roxo-escura recortada) e, atrás, só a silhueta escura menor.
static func _cth_asa() -> Dictionary:
	var cv: Dictionary = {}
	var bk: Dictionary = {}
	_asa(bk, Vector2(5, -13), [[-1, -22], [-8, -20], [-11, -14]], 0.9, false)
	for k in bk.keys():
		cv[k] = "v"
	RoupaGatoI._cont(cv, "o", true)
	var f: Dictionary = {}
	_asa(f, Vector2(1, -13), [[-3, -25], [-12, -23], [-15, -15]], 1.0, true)
	RoupaGatoI._cont(f, "o", true)
	for k2 in f.keys():
		cv[k2] = f[k2]
	return cv

## Manto verde-azulado liso com um só fio de arcos de escama, gola aberta, duas gotas e a barra recortada; as asas vão atrás do corpo.
static func _cth_manto() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._corpo_vest(cv, "m", -4, -6, -5)
	RoupaGatoI._gola(cv, "m", 3)
	RoupaGatoI._luz(cv, "m", "M", "D")
	for x in range(-7, 7):
		if cv.get(Vector2i(x, -7)) == "m":
			cv[Vector2i(x, -7)] = "D"
	for g in [Vector2i(-4, -9), Vector2i(3, -9)]:
		cv[g] = "i"
		cv[g + Vector2i(0, 1)] = "i"
	for x2 in range(-7, 7):
		if posmod(x2, 4) == 1:
			var b: int = _topo_col(cv, x2)
			if b > -99 and b < -4:
				cv.erase(Vector2i(x2, b))
	RoupaGatoI._cont(cv, "o", false)
	return [RoupaGatoI._lay(_cth_asa(), RoupaGato.Onde.CORPO, _PAL_CTHU, true), RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_CTHU)]

## Necronomiau: livro de capa roxa com cantos dourados e um olho amarelo aberto no meio.
static func _cth_livro() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, 12, -17, [
		"FbbbbbbF",
		"QBbbbbbb",
		"QbbbbbbB",
		"QbbooobB",
		"QbyyooYb",
		"QbbooobB",
		"QbbbbbbB",
		"QbbbbbbB",
		"FbbbbbbF",
	])
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.BOCA, _PAL_CTHU)]

## Tentáculo de pelúcia roxo-claro com ventosas, enrolado na garupa.
static func _cth_tentaculo() -> Array:
	var cv: Dictionary = {}
	var pts: Array = [[-11, -6], [-11, -8], [-11, -10], [-10, -12], [-8, -13], [-6, -13], [-5, -12], [-5, -11], [-6, -10]]
	for i in pts.size():
		var q: Array = pts[i]
		cv[Vector2i(q[0], q[1])] = "P"
		cv[Vector2i(q[0] + 1, q[1])] = "p"
		if i % 3 == 1:
			cv[Vector2i(q[0], q[1])] = "i"
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_CTHU)]

# ------------------------------------------------------------------ Ranger Miau (Green Ranger, Mighty Morphin)
## Ranger Miau (Green Ranger): o contorno; a/A/d verde (médio, luz, sombra); k viseira preta e l reflexo; w/W branco; y/Y/z escudo dourado (médio, luz, sombra);
## g/G/s aço do sabre; m cabo; p forro rosa das orelhas.
const _PAL_RANGER := {
	"o": Color("0a1a10"), "a": Color("2fa050"), "A": Color("6cd486"), "d": Color("1a6234"),
	"k": Color("1c1c28"), "l": Color("8a98d0"), "w": Color("f2f2f4"), "W": Color("b8bac8"),
	"y": Color("e0b838"), "Y": Color("fff0a0"), "z": Color("9a7418"), "p": Color("f0a0b0"),
	"g": Color("b4bac6"), "G": Color("e4e8f0"), "s": Color("707888"), "m": Color("3a3440"),
}
# ------------------------------------------------------------------ Ranger Miau
static func _rg_capacete() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 0, -21, [
		".....aaaa....",
		"...aaAYYAaa..",
		"..aaaAyyAAaa.",
		".aaaaaaaaaaaa",
		"Aaaaaaaaaaaad",
		"AAaakkkkkkkkd",
		".Aaakkkkklkkd",
		"..aaakkklkkd.",
		"..aaadkkkkkd.",
		"...awwwwdd...",
		"....wWWd.....",
	])
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_RANGER)]

static func _rg_macacao() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._corpo_vest(cv, "a", -5, -7, -5)
	_luz(cv, "a", "A", "d")
	var tp: Dictionary = RoupaGatoI._TOPO_VEST
	for x in range(-3, 9):
		for y in range(int(tp[x]), int(tp[x]) + 3):
			if cv.has(Vector2i(x, y)):
				cv[Vector2i(x, y)] = "y"
	for y in range(-12, -8):
		for x in range(4, 9):
			if cv.has(Vector2i(x, y)):
				cv[Vector2i(x, y)] = "y"
	for x2 in range(-3, 9):
		var t: int = int(tp[x2])
		if cv.has(Vector2i(x2, t)):
			cv[Vector2i(x2, t)] = "Y"
		if cv.has(Vector2i(x2, t + 2)):
			cv[Vector2i(x2, t + 2)] = "z"
	for x3 in range(4, 9):
		if cv.has(Vector2i(x3, -9)):
			cv[Vector2i(x3, -9)] = "z"
	for p in [Vector2i(6, -12), Vector2i(5, -11), Vector2i(7, -11), Vector2i(6, -10)]:
		cv[p] = "z"
	cv[Vector2i(6, -11)] = "Y"
	for x4 in range(-8, 9):
		if cv.has(Vector2i(x4, -8)):
			cv[Vector2i(x4, -8)] = "w"
	cv[Vector2i(3, -8)] = "y"
	cv[Vector2i(4, -8)] = "Y"
	for x5 in range(5, 8):
		cv[Vector2i(x5, -6)] = "y"
		cv[Vector2i(x5, -5)] = "w"
		cv[Vector2i(x5, -4)] = "W"
	for x6 in range(-8, -4):
		cv[Vector2i(x6, -6)] = "y" if x6 > -8 else "a"
		cv[Vector2i(x6, -5)] = "w"
		cv[Vector2i(x6, -4)] = "W"
	_cont(cv, "o", false)
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_RANGER)]

static func _rg_luva() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 11, -16, [
		"..wwwwww..",
		"aawwwawwwW",
		"aAwwaAaWWW",
		"aAwwwawwwW",
		"aawwwwWWWW",
		"aawwwwwwwW",
		"..wwwWWWW.",
	])
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_RANGER)]

static func _rg_pulseira() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 5, -4, ["gggg", "gYyg", "gyyg"])
	_cont(cv, "o", false)
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_RANGER)]


# ------------------------------------------------------------------ Miauzilla (Godzilla do Monstroverso)
## Miauzilla (Godzilla do Monstroverso): o contorno; a/A/d pele grafite (médio, luz, sombra); b barriga; e/E/f placas azuis (médio, núcleo, base);
## w/W garras e dentes; y olho; k boca.
const _PAL_MIAUZILLA := {
	"o": Color("070b12"), "a": Color("3e4656"), "A": Color("5e6a7e"), "d": Color("232a36"), "b": Color("6a7688"),
	"e": Color("4cb8f0"), "E": Color("e8faff"), "f": Color("2478c0"), "w": Color("e8e4d4"), "W": Color("a8a498"),
	"y": Color("e8c838"), "k": Color("0e1118"),
}
# ------------------------------------------------------------------ Miauzilla
## Folha serrilhada azul: base de 3 px em y `by`, afina para cima até a ponta de 1 px.
static func _mz_placa(cv: Dictionary, cx: int, by: int, h: int) -> void:
	for i in h:
		var y: int = by - i
		var larg: int = 3 if i < h - 2 else 1
		for x in range(cx - larg / 2, cx + larg / 2 + 1):
			var ch: String = "e"
			if i == h - 1:
				ch = "E"
			elif i == 0:
				ch = "f"
			elif x == cx - larg / 2 and larg == 3:
				ch = "f" if i < 2 else "e"
			elif x == cx and larg == 3 and i == 1:
				ch = "E"
			cv[Vector2i(x, y)] = ch

static func _mz_crista() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 1, -18, [
		"..aAAAa......",
		".aaaAAAaa....",
		"aaaaaaaaaa...",
		"aaaaadddddaaa",
		"aaaaaadyaaaaa",
		"aaaaaaaaaaaka",
		"aaaaaawkwkwkw",
		"aaaaaakkkkkkk",
		"..aaaddddddd.",
	])
	_mz_placa(cv, 2, -17, 4)
	_mz_placa(cv, 5, -19, 3)
	_luz(cv, "a", "A", "d")
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_MIAUZILLA)]

static func _mz_pele() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._corpo_vest(cv, "a", -5, -7, -5)
	_luz(cv, "a", "A", "d")
	for r in range(0, 3):
		for k in range(-8, 8, 4):
			var x: int = k + (2 if r % 2 == 1 else 0)
			var y: int = -10 + r * 2
			for p in [Vector2i(x, y), Vector2i(x + 1, y + 1), Vector2i(x + 2, y)]:
				if cv.has(p) and cv[p] == "a":
					cv[p] = "d"
	for x2 in range(-2, 4):
		for y2 in range(-8, -5):
			if cv.has(Vector2i(x2, y2)) and cv[Vector2i(x2, y2)] != "d":
				cv[Vector2i(x2, y2)] = "b"
	for p2 in [Vector2i(-6, -9), Vector2i(-6, -8), Vector2i(-5, -7), Vector2i(1, -10), Vector2i(1, -9), Vector2i(2, -8), Vector2i(5, -9), Vector2i(5, -8)]:
		if cv.has(p2):
			cv[p2] = "e"
	var tp: Dictionary = RoupaGatoI._TOPO_VEST
	var pl: Dictionary = {}
	_mz_placa(pl, -7, int(tp[-7]) - 1, 3)
	_mz_placa(pl, -4, int(tp[-4]) - 1, 4)
	_mz_placa(pl, -1, int(tp[-1]) - 1, 5)
	cv.merge(pl, true)
	for x3 in range(5, 8):
		cv[Vector2i(x3, -5)] = "d"
	for x4 in range(-8, -4):
		cv[Vector2i(x4, -5)] = "d"
	_cont(cv, "o", false)
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MIAUZILLA)]

static func _mz_bafo() -> Array:
	var cv: Dictionary = {}
	RoupaGatoF._disco(cv, 17.0, -12.5, 3.0, "e")
	RoupaGatoG._anel(cv, "e", "f")
	RoupaGatoF._disco(cv, 17.0, -12.5, 1.6, "E")
	for p in [Vector2i(17, -17), Vector2i(17, -16), Vector2i(21, -16), Vector2i(22, -12), Vector2i(21, -9), Vector2i(17, -8), Vector2i(13, -9)]:
		cv[p] = "e"
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_MIAUZILLA)]

static func _mz_cauda() -> Array:
	var cv: Dictionary = {}
	var pts: Array = [[-9.0, -9.5, 2.6], [-12.0, -8.5, 2.5], [-15.0, -7.0, 2.3], [-18.0, -5.5, 2.0], [-21.0, -4.0, 1.7], [-23.5, -3.0, 1.3], [-25.5, -2.5, 1.0]]
	for p in pts:
		RoupaGatoF._disco(cv, p[0], p[1], p[2], "a")
	_luz(cv, "a", "A", "d")
	_mz_placa(cv, -11, -11, 3)
	_mz_placa(cv, -14, -10, 3)
	_mz_placa(cv, -17, -8, 3)
	_mz_placa(cv, -20, -6, 3)
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MIAUZILLA, true)]


# ------------------------------------------------------------------ King-Miau (Kong de 2005)
## King-Miau (Kong de 2005): o contorno; h/H/D pelo (médio, luz, sombra); s/S/x cara de pele (médio, luz, sombra); n narinas e olhos;
## b/B/c prédio (médio, luz, sombra); j janelas; w/W/u/k avião de papel.
const _PAL_KING := {
	"o": Color("140c08"), "h": Color("5e4230"), "H": Color("84624a"), "D": Color("34241a"),
	"s": Color("6c665f"), "S": Color("8e8880"), "x": Color("3e3a36"), "n": Color("22180f"),
	"y": Color("f2d23a"), "Y": Color("fff08a"), "z": Color("b8921c"), "T": Color("5a3a1c"), "w": Color("e8dcb0"),
}

# ------------------------------------------------------------------ King-Miau
static func _km_gorila() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 1, -21, [
		"....hh......",
		"...hHHh.....",
		"..hhhhhhhh..",
		".hhhhhhhhhh.",
		"hhhDDDDDDDDh",
		"hhhhDnDDnDhh",
		"hhhhsssssshh",
		"hhhsssSSsshh",
		"hhssxnSnxssh",
		"hhsssssssssh",
		".hsxxxxxxxs.",
		"..hhssshhh..",
	])
	_luz(cv, "h", "H", "D")
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_KING)]

const _TOPO_KING := {-8: -9, -7: -10, -6: -11, -5: -12, -4: -13, -3: -14, -2: -15, -1: -15, 0: -15, 1: -15, 2: -14, 3: -13, 4: -12, 5: -11, 6: -10, 7: -9, 8: -8}

static func _km_pelagem() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._corpo_vest(cv, "h", -5, -7, -5, _TOPO_KING)
	for x in range(-8, 9):
		var t: int = int(_TOPO_KING[x])
		if posmod(x, 4) < 2:
			cv[Vector2i(x, t - 1)] = "h"
		var b: int = -99
		for y in range(-16, 0):
			if cv.has(Vector2i(x, y)):
				b = y
		if b > -99 and posmod(x, 4) >= 2:
			cv.erase(Vector2i(x, b))
	_luz(cv, "h", "H", "D")
	for y2 in range(-11, -6):
		var larg: int = 5 - (y2 + 11)
		for x2 in range(8 - larg + 1, 9):
			if x2 >= 4 and cv.has(Vector2i(x2, y2)):
				cv[Vector2i(x2, y2)] = "s" if y2 > -11 else "S"
	for p in [Vector2i(-3, -13), Vector2i(-2, -14), Vector2i(0, -14), Vector2i(1, -13), Vector2i(-5, -10), Vector2i(-4, -9)]:
		if cv.has(p):
			cv[p] = "H"
	for x3 in range(5, 8):
		cv[Vector2i(x3, -5)] = "D"
	for x4 in range(-8, -4):
		cv[Vector2i(x4, -5)] = "D"
	_cont(cv, "o", false)
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_KING)]

static func _km_mao() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 11, -16, [
		"..hhSSSss..",
		".hhhSssssS.",
		"hhhHsssssss",
		"hhhhsssxxx.",
		"hhhhSssssss",
		"hhhhsssxxx.",
		".hhhSssssss",
		".hhhhsssxx.",
		"..hhhsssss.",
	])
	_luz(cv, "h", "H", "D")
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_KING)]

static func _km_banana() -> Array:
	var cv: Dictionary = {}
	_txt(cv, -12, -17, [
		"T.......T",
		"yy.....yy",
		"yyy...yyz",
		".yyyyyyz.",
		"..zzzzz..",
	])
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_KING)]


static func _fallback(tipo: int) -> Array:
	var col: int = ((tipo - PRIMEIRO) / Pecas.SLOTS) % 4
	return RoupaGatoE.PECAS[(_MOLDE_FALLBACK[Pecas.SLOT[tipo]] as Array)[col]]

static func caixa(tipo: int) -> Rect2:
	var cs: Array = _camadas(tipo, 0.0, true)
	if cs.is_empty():
		var d: Array = _fallback(tipo)
		cs = [[d[0], d[1], d[2], {}]]
	var r := Rect2()
	var primeiro: bool = true
	for cm in cs:
		var larg: int = 0
		for l in cm[2]:
			larg = maxi(larg, (l as String).length())
		var rc := Rect2(cm[0], cm[1], larg, (cm[2] as Array).size())
		r = rc if primeiro else r.merge(rc)
		primeiro = false
	return r

static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	var cs: Array = _camadas(tipo, anim)
	if not cs.is_empty():
		for cm in cs:
			var atras: bool = (cm as Array).size() > 4
			if (RoupaGato.passo == 1 and not atras) or (RoupaGato.passo == 2 and atras):
				continue
			RoupaGato.sprite(c, cm[0], cm[1], cm[2], cm[3], f)
		return
	var d: Array = _fallback(tipo)
	RoupaGato.sprite(c, d[0], d[1], d[2], RoupaGatoE._paleta(tipo), f)
