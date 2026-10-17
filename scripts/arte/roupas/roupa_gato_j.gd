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
		Pecas.Tipo.PULSEIRA_TRANSFORMAR:
			return RoupaGato.Onde.CORPO
	return -1

## Peças com camada atrás do corpo do gato (asas do manto do Catchullu).
static func tem_atras(tipo: int) -> bool:
	return tipo == Pecas.Tipo.MANTO_ABISSAL

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
			return _sub_barbatana()
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
			return _rg_sabre()
		Pecas.Tipo.PULSEIRA_TRANSFORMAR:
			return _rg_pulseira()
		_:
			pass
	return []

# ------------------------------------------------------------------ Arthur Miaurgon (Arthur Morgan, RDR2): couro preto com brilho azulado
## c/C/S couro preto (médio, brilho cinza-azulado, sombra); v/V camisa e colete; m/M cinto e tira de couro marrom, faixa do chapéu e cabo; F/G fivela
## dourada; t/T/u aço do revólver; r/R/p caderninho (capa vermelho-escura, brilho, folhas).
const _PAL_ARTHUR := {
	"o": Color("08080c"), "c": Color("2a2d38"), "C": Color("7388a6"), "S": Color("14151b"),
	"v": Color("3e4252"), "V": Color("6a7188"),
	"m": Color("5e3a22"), "M": Color("96622e"), "F": Color("e2b13c"), "G": Color("ffe58a"),
	"t": Color("6a7484"), "T": Color("b4bece"), "u": Color("363c48"),
	"r": Color("7a2c2c"), "R": Color("b0504a"), "p": Color("e6dcc0"),
}

## Chapéu de caubói preto gasto: copa vincada (dois picos), faixa marrom, aba média (10 px) com as pontas viradas para cima.
static func _ar_chapeu() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, 1, -23, [
		"...cccccc...",
		"..cccccccc..",
		"..cccccccc..",
		".cMMMMMMMMc.",
		".cccccccccc.",
		"..SSSSSSSS..",
	])
	RoupaGatoI._luz(cv, "c", "C", "S")
	cv[Vector2i(6, -23)] = "S"
	cv[Vector2i(7, -23)] = "S"
	cv[Vector2i(6, -22)] = "S"
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CABECA, _PAL_ARTHUR)]

## Jaqueta de couro preta curta (gola alta, brilho no ombro), camisa escura aparecendo no peito, tira a tiracolo e cinto-cartucheira com fivela dourada.
static func _ar_casaco() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._corpo_vest(cv, "c", -6, -8, -6)
	RoupaGatoI._gola(cv, "c", 3)
	for y in range(-10, -6):
		for x in range(5, 8):
			if cv.has(Vector2i(x, y)) and not (x == 5 and y == -10):
				cv[Vector2i(x, y)] = "v"
	RoupaGatoI._luz(cv, "c", "C", "S")
	RoupaGatoI._linsobre(cv, Vector2i(4, -11), Vector2i(-3, -6), "m")
	for x in range(-8, 9):
		var b: int = -99
		for y in range(-14, 0):
			if cv.has(Vector2i(x, y)):
				b = y
		if b > -99:
			cv[Vector2i(x, b + 1)] = "M" if posmod(x, 2) == 0 else "m"
	for x2 in range(4, 7):
		var b2: int = -99
		for y2 in range(-14, 0):
			if cv.has(Vector2i(x2, y2)):
				b2 = y2
		cv[Vector2i(x2, b2)] = "F"
		cv[Vector2i(x2, b2 - 1)] = "G" if x2 == 4 else "F"
	RoupaGatoI._cont(cv, "o", false)
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_ARTHUR)]

## Revólver: martelo, armação e cano de aço com o tambor, guarda-mato e cabo de madeira.
static func _ar_revolver() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, 11, -14, [
		"..uu.........",
		".tTTTTTTTTTTT",
		".tttutttttttt",
		".tttutuuuuuu.",
		"mmtt.........",
		"mMm..........",
		".mm..........",
	])
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.BOCA, _PAL_ARTHUR)]

## Caderninho de couro vermelho-escuro com fecho dourado, folhas na borda e o lápis amarelo.
static func _ar_diario() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, -9, -18, [
		"..F...",
		"..F...",
		"rrrrrp",
		"rRRRrp",
		"rMMMFp",
		"rRRRrp",
		"rrrrrp",
	])
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_ARTHUR)]

# ------------------------------------------------------------------ Submiautica (Reaper Leviathan): azul-acinzentado, faixas ferrugem, mandíbulas em gancho
## a/A/d corpo azul-acinzentado (médio, luz, sombra); r/R/D faixas e barbatana vermelho-ferrugem; m/M mandíbulas verde-oliva escuras; k/E olho preto e aro;
## w barriga clara; s/S/e/h aço azul do rifle de estase e brilho ciano da câmara (halo, núcleo, miolo).
const _PAL_SUB := {
	"o": Color("0c1822"), "a": Color("7a9eb2"), "A": Color("b0cdd8"), "d": Color("46687e"),
	"r": Color("b0502c"), "R": Color("dc7c4c"), "D": Color("78301c"),
	"m": Color("56503a"), "M": Color("8a8260"), "k": Color("0c1018"), "E": Color("d6e6ea"),
	"w": Color("dfe9e4"), "s": Color("96a6b6"), "S": Color("2a78b0"), "e": Color("4cc8f0"), "h": Color("eafbff"), "u": Color("2e3a48"),
}

## Cabeça do Reaper: a grande barbatana ferrugem inclinada para trás, o crânio azul-acinzentado com o olho grande preto de aro claro e
## quatro mandíbulas em gancho (duas sobem na frente, duas descem sob o queixo); o focinho do gato aparece entre elas.
static func _sub_capuz() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, 1, -24, [
		"rr.............",
		".rrrr..........",
		".rrrrr.........",
		"..rrrrrr.......",
		"..rrrrrrr......",
		"..arrrrraaa....",
		"..aaaaaaaaaa...",
		"..aaaEEEEEaaa.M",
		"..aaaEkkkEaaMMM",
		"..aadEkkkEaMMM.",
		"...ddaEEEaaMM..",
		"....dAaaaaa....",
	])
	RoupaGatoI._luz(cv, "a", "A", "d")
	# gancho de cima sobe na ponta
	RoupaGatoI._txt(cv, 14, -17, ["M", "M"])
	# mandíbulas de baixo: descem sob o queixo e voltam a curvar para a frente
	RoupaGatoI._txt(cv, 10, -12, ["mM", ".mMM", "..mMM", "....mM", ".....m"])
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CABECA, _PAL_SUB)]

## Pele do Leviatã: corpo azul-acinzentado justo, faixas vermelho-ferrugem na vertical seguindo o dorso e a barriga clara.
static func _sub_pele() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._corpo_vest(cv, "a", -5, -7, -5)
	RoupaGatoI._luz(cv, "a", "A", "d")
	for fx in [-6, -2, 2]:
		for y in range(-13, 0):
			for x in range(fx, fx + 2):
				if cv.has(Vector2i(x, y)) and cv[Vector2i(x, y)] != "o" and y < -5:
					cv[Vector2i(x, y)] = "r" if x == fx else "D"
	for x in range(-3, 4):
		for y in range(-9, 0):
			if cv.has(Vector2i(x, y)) and cv[Vector2i(x, y)] in ["a", "d"] and y >= -7:
				cv[Vector2i(x, y)] = "w"
	RoupaGatoI._cont(cv, "o", false)
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_SUB)]

## Rifle de estase: coronha, câmara larga com núcleo ciano e halo escuro, cano com anéis e as duas pontas do fim.
static func _sub_rifle() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, 13, -16, [
		"..SSSSS........",
		"ssSeeeSAAAAAAAA",
		"ssSehheSaaDaaDa",
		"ssSeeeSddddddd.",
		"u.SSSSS...aa.aa",
		"uu.............",
	])
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.BOCA, _PAL_SUB)]

## Barbatana dorsal do Leviatã: vela vermelho-ferrugem com nervuras escuras, inclinada para trás.
static func _sub_barbatana() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._txt(cv, -11, -17, [
		"....R....",
		"...rrR...",
		"..rDrrR..",
		".rrDrDrR.",
		"rrDrrDrrR",
	])
	RoupaGatoI._cont(cv, "o")
	return [RoupaGatoI._lay(cv, RoupaGato.Onde.CORPO, _PAL_SUB)]

# ------------------------------------------------------------------ Catchullu (Cthulhu): verde-acinzentado escuro, roxo e olhos amarelos
## a/A/d pele verde-acinzentada (média, luz, sombra); m/M/D manto verde-azulado; w/W asa de morcego (membrana escura, luz); y/Y olho amarelo (e brilho);
## p/P/q tentáculos roxos (médio, luz, sombra); b/B/Q capa do livro (média, luz, lombo); F metal dourado; i gota d'água.
const _PAL_CTHU := {
	"o": Color("08141a"), "a": Color("3c7c68"), "A": Color("70b49c"), "d": Color("22483e"),
	"m": Color("245c6a"), "M": Color("3e8896"), "D": Color("143642"),
	"w": Color("3c3a5e"), "W": Color("6a66a0"),
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

## Asa de morcego atrás do corpo: ossos finos saindo do ombro, membrana escura de borda recortada em arcos e o gancho na ponta.
static func _cth_asa() -> Dictionary:
	var cv: Dictionary = {}
	RoupaGatoI._poli(cv, [-1, -12, -4, -23, -6, -19, -10, -21, -9, -17, -13, -17, -10, -14, -9, -12], "w")
	RoupaGatoI._lin(cv, Vector2i(-1, -13), Vector2i(-4, -23), "W")
	RoupaGatoI._lin(cv, Vector2i(-1, -13), Vector2i(-10, -21), "W")
	RoupaGatoI._lin(cv, Vector2i(-1, -13), Vector2i(-13, -17), "W")
	RoupaGatoI._cont(cv, "o", true)
	return cv

## Manto verde-azulado escamado (arcos de 3 px), gola aberta, barra recortada e três gotas; as asinhas vão atrás do corpo.
static func _cth_manto() -> Array:
	var cv: Dictionary = {}
	RoupaGatoI._corpo_vest(cv, "m", -4, -6, -5)
	RoupaGatoI._gola(cv, "m", 3)
	RoupaGatoI._luz(cv, "m", "M", "D")
	for y in [-10, -7]:
		for x in range(-8, 8):
			if posmod(x + (1 if y == -7 else 0), 3) == 0 and cv.get(Vector2i(x, y)) == "m":
				cv[Vector2i(x, y)] = "D"
				if cv.get(Vector2i(x + 1, y - 1)) == "m":
					cv[Vector2i(x + 1, y - 1)] = "M"
	for g in [Vector2i(-5, -8), Vector2i(1, -10), Vector2i(4, -8)]:
		cv[g] = "i"
		cv[g + Vector2i(0, 1)] = "i"
	for x2 in range(-7, 7):
		if posmod(x2, 3) == 1:
			var b: int = -99
			for y2 in range(-14, 0):
				if cv.has(Vector2i(x2, y2)):
					b = y2
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
	_txt(cv, 1, -21, [
		"..aa....aa..",
		".appa..appa.",
		".aaaaYYaaaa.",
		"aaaAAyyAAaaa",
		"aaaaaaaaaaad",
		"aaakkkkkkkkd",
		"aaakkkkklkkd",
		"aaaakkklkkkd",
		".aaakkkkkkd.",
		".aaadkkkkkd.",
		"..awwwwdd...",
		"...wWWd.....",
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

static func _rg_sabre() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 11, -13, [
		"..GGGGGGGG..",
		"mmmgggggggG.",
		"mmmsssssss..",
		"mm.m........",
		".mm.........",
	])
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_RANGER)]

static func _rg_pulseira() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 5, -4, ["gggg", "gYyg", "gyyg"])
	_cont(cv, "o", false)
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_RANGER)]


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
