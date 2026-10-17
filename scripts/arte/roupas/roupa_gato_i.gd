class_name RoupaGatoI
extends RefCounted
## Roupas do gato em pixel art, tipos 172 em diante (ver RoupaGato para as convenções): expansão das fantasias, lote 4
## (Miau-Noir 172-175, Hollowmiau 176-179, Silkmiau 180-183, Super Miaujin 184-187, O Arqueólogo 188-191, Treinador de Miaumons 192-195).
##
## COMO ENCAIXA NO GATO: igual ao RoupaGatoG/H, cada peça é escrita em letras (`_txt`) em COORDENADAS DO GATO (x para a frente, y para
## cima, pé em 0; cabeça em x 3..10 / y -17..-10, olho em x 8 / y -13..-12, focinho em x 10 / y -11, tronco em x -8..7 / y -12..-5) e
## convertida para o lugar onde fica presa. Contorno de 1 px nos 4 vizinhos (sem a borda de baixo do corpo) e luz/sombra por regra
## (`_cont`, `_luz`); sem ruído nem alfa. Camada [x, y, linhas, paleta, true] = ATRÁS do corpo (manto, capa, ponta da mochila).
## Ficha visual: notas/lote4_ficha_visual.md; ids: notas/lote4/para_arte.md.
##
## FALLBACK: peça sem arte própria em `_montar` desenha a silhueta de uma peça do lado de fora, tingida.

const PRIMEIRO := 172
## Silhuetas de reserva por espaço (cabeça, corpo, mão, acessório); cada fantasia usa uma das 4 colunas, para não ficarem todas iguais.
const _MOLDE_FALLBACK: Array = [
	[Pecas.Tipo.CAPACETE_AZUL, Pecas.Tipo.BANDANA_FOLHA, Pecas.Tipo.CAPUZ_TUBARAO, Pecas.Tipo.ANTENAS],
	[Pecas.Tipo.COLETE_LISTRADO, Pecas.Tipo.MACACAO_LARANJA, Pecas.Tipo.ARMADURA_AZUL, Pecas.Tipo.ROUPA_TUBARAO],
	[Pecas.Tipo.KUNAI, Pecas.Tipo.CANHAO_BRACO, Pecas.Tipo.MORDIDA, Pecas.Tipo.FERRAO],
	[Pecas.Tipo.TANQUE, Pecas.Tipo.PERGAMINHO, Pecas.Tipo.BOIA, Pecas.Tipo.POTE_MEL],
]

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão (cabeça, corpo, boca e traseira). Os acessórios do lote 4 vão no dorso.
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.ROLO_FILME, Pecas.Tipo.FRASCO_ALMA, Pecas.Tipo.NOVELO_SEDA, Pecas.Tipo.ESFERA_ESTRELAS, Pecas.Tipo.IDOLO_ATUM, Pecas.Tipo.RATO_ELETRICO:
			return RoupaGato.Onde.CORPO
	return -1

## Peças com camada atrás do corpo do gato (manto do Hollowmiau, capa da Silkmiau, ponta da mochila do Treinador).
static func tem_atras(tipo: int) -> bool:
	return tipo == Pecas.Tipo.MANTO_PRETINHO or tipo == Pecas.Tipo.CAPA_CARMESIM or tipo == Pecas.Tipo.MOCHILA_AMARELA

# ------------------------------------------------------------------ paletas
## Miau-Noir (monocromático): o contorno; h/H/s chapéu (médio, luz, sombra); f/F/e faixa do chapéu e lente (médio, luz, sombra); c/C/S sobretudo
## (médio, luz, sombra); m máscara; l lente; q branco sujo (gotas, brilho, quadros do filme); t/T/u latão (médio, luz, sombra); p película; w arame.
const _PAL_NOIR := {
	"o": Color("0c0b10"), "h": Color("34323a"), "H": Color("56535e"), "s": Color("1e1c24"),
	"f": Color("8e8c94"), "F": Color("b4b2ba"), "e": Color("5e5c66"),
	"c": Color("6c6a74"), "C": Color("9290a0"), "S": Color("44424c"),
	"m": Color("4a4852"), "l": Color("d8d8dc"), "q": Color("e8e6e2"),
	"t": Color("a68a5a"), "T": Color("d2b882"), "u": Color("6e5a38"), "p": Color("2a2830"), "w": Color("5e5c66"),
}
## Hollowmiau: o contorno; w/W/d osso (médio, luz, sombra); k/e olho (preto, brilho); a/b/D manto azul-marinho (médio, luz, sombra); n/N/s aço
## do prego (médio, luz, sombra); u couro do punho; g vidro da ampola (e a alma, em W).
const _PAL_HOLLOW := {
	"o": Color("0c0b14"), "w": Color("edeae0"), "W": Color("ffffff"), "d": Color("b9b6b0"),
	"k": Color("14121c"), "e": Color("3a3850"),
	"a": Color("2f3e6a"), "b": Color("5666a0"), "D": Color("1b2442"),
	"n": Color("b8c0cc"), "N": Color("e8eef4"), "s": Color("6e7888"), "u": Color("3a2e3e"), "g": Color("8ec8f0"),
}
## Silkmiau: o contorno; w/W/d osso (médio, luz, sombra); k olho; a/b/D capa carmesim (médio, luz, sombra); n/N/m fio e novelo (médio, luz,
## sombra); s/S/z aço da agulha (médio, luz, sombra).
const _PAL_SILK := {
	"o": Color("0c0b14"), "w": Color("edeae0"), "W": Color("ffffff"), "d": Color("b9b6b0"), "k": Color("14121c"),
	"a": Color("b02a3a"), "b": Color("dc5a64"), "D": Color("721822"),
	"n": Color("e04858"), "N": Color("f59aa0"), "m": Color("8a1e2c"),
	"s": Color("c4cad4"), "S": Color("f0f4f8"), "z": Color("7a8494"),
}
## Super Miaujin: o contorno do dourado e do laranja; h/H/d cabelo (médio, luz, sombra); a/b/D gi laranja; u/U/V azul (médio, luz, sombra);
## e/E/S energia (média, núcleo, sombra); O contorno azul-noite; g/G/j esfera de 4 estrelas (média, brilho, sombra); r estrelas.
const _PAL_MIAUJIN := {
	"o": Color("1a0e08"), "h": Color("f2c238"), "H": Color("ffe88a"), "d": Color("c28a1e"),
	"a": Color("e8832e"), "b": Color("f8b070"), "D": Color("ae5018"),
	"u": Color("2f5aae"), "U": Color("6c92d8"), "V": Color("1c3478"),
	"e": Color("6cc8f0"), "E": Color("e4f8ff"), "S": Color("2e8acc"), "O": Color("0a1030"),
	"g": Color("f0a038"), "G": Color("ffd27a"), "j": Color("b86a18"), "r": Color("d03a30"),
}
## O Arqueólogo: o contorno; h/H/s chapéu (médio, luz, sombra); f faixa; j/J/S jaqueta; k/K camisa cáqui (médio, sombra); l/m couro da bolsa
## (médio, sombra); c/C/x chicote de corda (médio, luz, sombra); g/G/y ídolo e fivela (ouro, brilho, sombra).
const _PAL_ARQ4 := {
	"o": Color("1c120a"), "h": Color("7a5430"), "H": Color("a07a4c"), "s": Color("4e3320"), "f": Color("2e2118"),
	"j": Color("8e5e34"), "J": Color("b88556"), "S": Color("5a3a20"),
	"k": Color("cdb88a"), "K": Color("9c875a"), "l": Color("b08a5a"), "m": Color("7a5c38"),
	"c": Color("d9803a"), "C": Color("f2ae70"), "x": Color("9c4f20"),
	"g": Color("e3b53c"), "G": Color("ffe488"), "y": Color("a87a1e"),
}
## Treinador de Miaumons: o contorno (e a faixa e o botão da bola); r/R/d vermelho (médio, luz, sombra); w/W branco (médio, sombra);
## a/b/v colete azul (médio, luz, sombra); y/Y/z mochila (média, luz, sombra); p/P/q pelúcia (média, luz, sombra); k preto.
const _PAL_TREI := {
	"o": Color("1a0a10"), "k": Color("1a0a10"), "r": Color("d63c3c"), "R": Color("f27872"), "d": Color("8c1e26"),
	"w": Color("f0f0f0"), "W": Color("b8bac4"),
	"a": Color("3a62b8"), "b": Color("6c92e0"), "v": Color("223c7c"),
	"y": Color("e8b438"), "Y": Color("f8da78"), "z": Color("a87a1e"),
	"p": Color("f2d040"), "P": Color("ffee88"), "q": Color("c09a20"),
}

# ------------------------------------------------------------------ ferramentas (usam as de RoupaGatoF e RoupaGatoG)
static func _ret(cv: Dictionary, x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	RoupaGatoF._ret(cv, x0, y0, x1, y1, ch)

static func _px(cv: Dictionary, x: int, y: int, ch: String) -> void:
	cv[Vector2i(x, y)] = ch

static func _lin(cv: Dictionary, a: Vector2i, b: Vector2i, ch: String) -> void:
	RoupaGatoF._lin(cv, a, b, ch)

static func _disco(cv: Dictionary, cx: float, cy: float, r: float, ch: String) -> void:
	RoupaGatoF._disco(cv, cx, cy, r, ch)

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

static func _anel(cv: Dictionary, de: String, para: String, tambem: String = "") -> void:
	RoupaGatoG._anel(cv, de, para, tambem)

## Sombra do osso: o pixel `base` sem vizinho à esquerda ou sem vizinho embaixo vira `sombra`.
static func _canto(cv: Dictionary, base: String, sombra: String) -> void:
	var mud: Array = []
	for k in cv.keys():
		var v: Vector2i = k
		if cv[v] == base and (not cv.has(v + Vector2i(-1, 0)) or not cv.has(v + Vector2i(0, 1))):
			mud.append(v)
	for v2 in mud:
		cv[v2] = sombra

# ------------------------------------------------------------------ peças
static var _cache: Dictionary = {}

## Camadas da peça com arte própria; vazio = usa o fallback. A capa da Silkmiau balança em 2 quadros.
static func _camadas(tipo: int, anim: float, maxima: bool = false) -> Array:
	var fase: int = 0
	if tipo == Pecas.Tipo.CAPA_CARMESIM and not maxima:
		fase = int(anim * 4.0) % 2
	var ch: int = tipo * 4 + fase
	if _cache.has(ch):
		return _cache[ch]
	var r: Array = _montar(tipo, fase)
	_cache[ch] = r
	return r

## Capa comprida da Silkmiau, atrás do corpo: nasce na nuca, esvoaça para trás e a barra acaba em duas pontas (`fase` 0 ou 1).
static func _capa_silk(fase: int) -> Dictionary:
	var cv: Dictionary = {}
	for k in 19:
		var x: int = 3 - k
		var u: float = k / 18.0
		var onda: float = sin(u * 5.0 - fase * PI * 0.9) * 1.5 * u
		var topo: int = floori(-13.0 + 4.0 * u + onda * 0.6)
		var base: int = ceili(-4.6 + 1.0 * u + onda)
		if base - topo < 2:
			continue
		for y in range(topo, base):
			cv[Vector2i(x, y)] = "a"
		# barra recortada em duas pontas: um entalhe no meio da ponta da capa
		var cortar: int = 0
		if k >= 15:
			cortar = 2
		elif k >= 13:
			cortar = 1
		if cortar > 0:
			var meio: int = (topo + base) / 2
			for y2 in range(meio - 1 + (1 if cortar == 1 else 0), meio - 1 + cortar + (1 if cortar == 1 else 0)):
				cv.erase(Vector2i(x, y2))
	return cv

static func _montar(tipo: int, fase: int) -> Array:
	var cv: Dictionary = {}
	match tipo:
		# ---------------------------------------------------------------- Miau-Noir (Spider-Man Noir): monocromático
		Pecas.Tipo.FEDORA_TEIA:
			# fedora de feltro preto (aba reta larga, copa amassada com vinco, faixa clara) e a máscara de teia cinza só sobre os olhos:
			# lente clara de aviador com brilho e rachaduras em V na máscara; o focinho, a boca e o bigode ficam livres
			_txt(cv, 1, -22, [
				"...hhhhh....",
				"..hhhhhhh...",
				"..hhhhhhh...",
				"..hhhhhhh...",
				"..fffffff...",
				"hhhhhhhhhhhh",
				".hhhhhhhhhh.",
			])
			_luz(cv, "h", "H", "s")
			_px(cv, 6, -22, "s")
			_px(cv, 6, -21, "s")
			_ret(cv, 4, -14, 10, -11, "m")
			_ret(cv, 7, -14, 10, -11, "l")
			_ret(cv, 7, -12, 10, -11, "f")
			_px(cv, 7, -14, "q")
			_px(cv, 5, -14, "o")
			_px(cv, 6, -13, "o")
			_px(cv, 5, -12, "o")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_NOIR)]
		Pecas.Tipo.SOBRETUDO_CINZA:
			# sobretudo longo cinza-grafite de gola alta levantada, abotoamento duplo, cinto com laço e três gotas de chuva
			RoupaGatoF._tronco(cv, "c", -12, -4)
			_ret(cv, 0, -15, 3, -12, "c")
			_luz(cv, "c", "C", "S")
			_ret(cv, -8, -7, 8, -6, "S")
			_px(cv, -1, -6, "o")
			for b in [Vector2i(3, -8), Vector2i(3, -5), Vector2i(6, -8), Vector2i(6, -5)]:
				cv[b] = "C"
			for g in [Vector2i(-5, -11), Vector2i(-2, -9), Vector2i(-4, -5)]:
				cv[g] = "q"
				cv[g + Vector2i(0, 1)] = "q"
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_NOIR)]
		Pecas.Tipo.LANTERNA_BECO:
			# lampião de beco APAGADO: alça de arame, tampa pontuda, vidro cinza rachado na diagonal e base de latão
			_txt(cv, 12, -15, [
				"..ww..",
				".w..w.",
				"..tt..",
				".tttt.",
				"tttttt",
				"tqllot",
				"tllolt",
				"tlolft",
				"tolllt",
				"tlfflt",
				".tttt.",
				"..uu..",
			])
			_luz(cv, "t", "T", "u")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_NOIR)]
		Pecas.Tipo.ROLO_FILME:
			# carretel preto com dois furos claros e a tira de película (quadros claros e escuros de 2 px) pendendo do carretel
			_txt(cv, -7, -20, [
				".ppppp.",
				"ppppppp",
				"ppqpppp",
				"pppfppp",
				"ppppqpp",
				"ppppppp",
				".ppppp.",
			])
			_luz(cv, "p", "H", "")
			_ret(cv, -4, -13, -2, -11, "q")
			_ret(cv, -4, -11, -2, -9, "p")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_NOIR)]
		# ---------------------------------------------------------------- Hollowmiau (O Cavaleiro): o casco branco de dois chifres curtos
		Pecas.Tipo.MASCARA_OCA:
			# casco branco em domo cobrindo o rosto todo, dois chifres grossos curtos e retos, olho oval preto grande (e outro parcial atrás),
			# uma rachadura no domo
			_txt(cv, 2, -22, [
				".ww.....ww.",
				".ww.....ww.",
				"..ww...ww..",
				"..ww...ww..",
				"..wwwwwww..",
				".wwwwwwwww.",
				"wwwwwwwwwww",
				"wwwwwwwwwww",
				"wwwwwwwwwww",
				"wwwwwwwwwww",
				"wwwwwwwwwww",
				".wwwwwwwwww",
				"..wwwwwwww.",
			])
			_canto(cv, "w", "d")
			_px(cv, 9, -15, "k")
			_px(cv, 10, -15, "k")
			_ret(cv, 8, -14, 11, -12, "k")
			_px(cv, 8, -12, "k")
			_px(cv, 9, -12, "k")
			_px(cv, 8, -14, "e")
			_ret(cv, 5, -14, 7, -11, "k")
			_px(cv, 7, -18, "d")
			_px(cv, 7, -17, "d")
			_px(cv, 6, -16, "d")
			_px(cv, 5, -17, "W")
			_px(cv, 4, -18, "W")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_HOLLOW)]
		Pecas.Tipo.MANTO_PRETINHO:
			# manto azul-marinho curto de gola alta e um broche branco; atrás do corpo, a capinha só se abre um pouco para trás (sem pregas)
			RoupaGatoF._tronco(cv, "a", -12, -5)
			_ret(cv, 0, -15, 2, -12, "a")
			_ret(cv, 2, -14, 3, -12, "a")
			_luz(cv, "a", "b", "D")
			_px(cv, 4, -8, "W")
			_cont(cv, "o", false)
			var capa: Dictionary = {}
			_poli(capa, [3, -13.5, -3, -13.5, -8, -12, -11, -9.5, -12.5, -6, -11.5, -3.5, -8, -4, 3, -4.5], "a")
			_luz(capa, "a", "b", "D")
			_cont(capa, "o")
			return [_lay(capa, RoupaGato.Onde.CORPO, _PAL_HOLLOW, true), _lay(cv, RoupaGato.Onde.CORPO, _PAL_HOLLOW)]
		Pecas.Tipo.PREGO_AFIADO:
			# o prego: punho preto curto, guarda de 1 px, lâmina larga e reta que afina em degraus até a ponta
			_ret(cv, 11, -12, 14, -9, "u")
			_ret(cv, 14, -13, 15, -8, "u")
			_ret(cv, 15, -12, 23, -9, "n")
			_ret(cv, 23, -11, 26, -10, "n")
			_luz(cv, "n", "N", "s")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_HOLLOW)]
		Pecas.Tipo.FRASCO_ALMA:
			# ampola de vidro azul-claro com a esfera branca de alma dentro e a rolha escura
			_txt(cv, -8, -21, [
				"..uu..",
				"..gg..",
				".gggg.",
				"gWWWgg",
				"gWWWgg",
				"gWWWgg",
				".gggg.",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_HOLLOW)]
		# ---------------------------------------------------------------- Silkmiau (Hornet): a máscara pontuda de chifres longos
		Pecas.Tipo.MASCARA_CASCA:
			# casco branco estreito de queixo em ponta cobrindo o rosto todo, olho em fenda inclinada e dois chifres LONGOS que sobem e
			# curvam para trás (o de trás, mais curto e escuro)
			_txt(cv, 3, -18, [
				"..wwwwww..",
				".wwwwwwww.",
				"wwwwwwwwww",
				"wwwwwwwwww",
				"wwwwwwwwww",
				"wwwwwwwwww",
				".wwwwwwwww",
				".wwwwwwww.",
				"..wwwwww..",
				"...wwww...",
			])
			_canto(cv, "w", "d")
			_px(cv, 8, -14, "k")
			_px(cv, 9, -14, "k")
			_px(cv, 9, -13, "k")
			_px(cv, 10, -13, "k")
			_px(cv, 6, -18, "W")
			_px(cv, 7, -18, "W")
			var hc: Dictionary = {}
			for q in [Vector2i(9, -19), Vector2i(10, -19), Vector2i(9, -20), Vector2i(10, -20), Vector2i(8, -21), Vector2i(9, -21),
					Vector2i(7, -22), Vector2i(8, -22), Vector2i(5, -23), Vector2i(6, -23), Vector2i(7, -23), Vector2i(3, -24), Vector2i(4, -24), Vector2i(5, -24)]:
				hc[q] = "w"
			_canto(hc, "w", "d")
			for q2 in [Vector2i(5, -19), Vector2i(6, -19), Vector2i(4, -20), Vector2i(5, -20), Vector2i(3, -21), Vector2i(4, -21), Vector2i(2, -22), Vector2i(3, -22)]:
				hc[q2] = "d"
			for kk in hc.keys():
				if not cv.has(kk):
					cv[kk] = hc[kk]
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_SILK)]
		Pecas.Tipo.CAPA_CARMESIM:
			# a capa carmesim comprida esvoaça ATRÁS do corpo (barra em duas pontas, balança em 2 quadros); na frente só o top vermelho curto
			# de gola alta, o cinto escuro e a barra em duas pontinhas
			var cp: Dictionary = _capa_silk(fase)
			_luz(cp, "a", "b", "D")
			_cont(cp, "o")
			RoupaGatoF._tronco(cv, "a", -12, -5)
			_ret(cv, 0, -15, 3, -12, "a")
			_ret(cv, -5, -4, -3, -3, "a")
			_ret(cv, 2, -4, 4, -3, "a")
			_luz(cv, "a", "b", "D")
			_ret(cv, -8, -7, 8, -6, "D")
			_cont(cv, "o", false)
			return [_lay(cp, RoupaGato.Onde.CORPO, _PAL_SILK, true), _lay(cv, RoupaGato.Onde.CORPO, _PAL_SILK)]
		Pecas.Tipo.AGULHA_GIGANTE:
			# agulha longa e fina: a cabeça com o olho grande (o fio vermelho passa por ele e cai ondulando) e a haste de 2 px que afina até a ponta
			_ret(cv, 11, -13, 15, -8, "s")
			for e in [Vector2i(12, -12), Vector2i(13, -12), Vector2i(12, -11), Vector2i(13, -11), Vector2i(12, -10), Vector2i(13, -10)]:
				cv.erase(e)
			_ret(cv, 15, -11, 23, -9, "s")
			_ret(cv, 23, -11, 27, -10, "s")
			_luz(cv, "s", "S", "z")
			for t in [Vector2i(12, -12), Vector2i(12, -11), Vector2i(12, -10), Vector2i(12, -9), Vector2i(12, -8), Vector2i(13, -7), Vector2i(13, -6), Vector2i(12, -5), Vector2i(12, -4)]:
				cv[t] = "n"
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_SILK)]
		Pecas.Tipo.NOVELO_SEDA:
			# novelo vermelho redondo com duas voltas de fio mais claras e a ponta solta pendendo
			_txt(cv, -9, -20, [
				".nnnn.",
				"nNNnnn",
				"nnnNnn",
				"NnnnNn",
				"nNNnnm",
				".nmmn.",
			])
			_px(cv, -6, -14, "n")
			_px(cv, -5, -13, "n")
			_px(cv, -5, -12, "m")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_SILK)]
		# ---------------------------------------------------------------- Super Miaujin (Super Saiyajin): o cabelo dourado espetado
		Pecas.Tipo.CABELO_DOURADO:
			# cabelo dourado em quatro espetos de alturas desiguais inclinados para trás, uma mecha na testa, sobrancelha reta e brava
			# e uma faísca azul-clara zigue-zagueando num espeto; o rosto do gato fica à mostra
			_txt(cv, 0, -25, [
				"...h.........",
				"..hh.....h...",
				".hhh..h..hh..",
				"hhhh.hh.hhh..",
				"hhhhhhh.hhhh.",
				".hhhhhhhhhhh.",
				".hhhhhhhhhhh.",
				"..hhhhhhhhhh.",
				"..hhhhhhhhhh.",
				"..hhhhhhhhhh.",
				"..hh......hh.",
				"..h.......h..",
			])
			_luz(cv, "h", "H", "d")
			_px(cv, 3, -24, "E")
			_px(cv, 2, -23, "E")
			_px(cv, 3, -22, "E")
			_cont(cv, "o")
			_ret(cv, 7, -14, 10, -13, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_MIAUJIN)]
		Pecas.Tipo.KIMONO_LARANJA:
			# gi laranja do Goku: decote em V e camisa azul no ombro rasgado, faixa azul na cintura com nó e as pontas, punhos azuis nas patas
			RoupaGatoF._tronco(cv, "a", -12, -4)
			_luz(cv, "a", "b", "D")
			_ret(cv, 3, -9, 6, -8, "u")
			_px(cv, 4, -8, "u")
			_ret(cv, -2, -11, 1, -8, "u")
			_px(cv, -2, -11, "a")
			_px(cv, 0, -9, "V")
			_ret(cv, -8, -7, 8, -6, "u")
			_ret(cv, -8, -6, 8, -5, "V")
			_ret(cv, -3, -8, 0, -5, "u")
			_px(cv, -2, -7, "U")
			_px(cv, -3, -5, "V")
			_px(cv, -1, -5, "V")
			_ret(cv, 4, -4, 8, -3, "u")
			_ret(cv, -7, -4, -3, -3, "u")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MIAUJIN)]
		Pecas.Tipo.CONCHA_ENERGIA:
			# esfera de energia azul-clara de 9 px, núcleo branco 3x3 e contorno azul-noite, segurada numa pata só
			_disco(cv, 16.5, -10.5, 4.5, "e")
			_anel(cv, "e", "S")
			_ret(cv, 15, -12, 18, -9, "E")
			_cont(cv, "O")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_MIAUJIN)]
		Pecas.Tipo.ESFERA_ESTRELAS:
			# a esfera do dragão: bola âmbar 8x8 com quatro estrelas vermelhas (um pixel cada, em quadrado) e o brilho no canto
			_disco(cv, -5.0, -17.0, 4.0, "g")
			_luz(cv, "g", "g", "j")
			for s in [Vector2i(-7, -19), Vector2i(-4, -19), Vector2i(-7, -16), Vector2i(-4, -16)]:
				cv[s] = "r"
			_px(cv, -8, -20, "G")
			_px(cv, -7, -21, "G")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MIAUJIN)]
		# ---------------------------------------------------------------- O Arqueólogo (Indiana Jones): tudo marrom, valor e acento
		Pecas.Tipo.CHAPEU_AMASSADO:
			# fedora marrom de copa baixa amassada (vinco na sombra), faixa escura e aba mole que cai nas pontas e sombreia os olhos
			_txt(cv, 1, -21, [
				"...hhhhh....",
				"..hhhhhhh...",
				"..hhhhhhh...",
				"..fffffff...",
				"hhhhhhhhhhhh",
				"hh......hhhh",
			])
			_luz(cv, "h", "H", "s")
			_px(cv, 6, -21, "s")
			_px(cv, 6, -20, "s")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_ARQ4)]
		Pecas.Tipo.JAQUETA_GASTA:
			# jaqueta de couro marrom com gola de lapela, camisa cáqui no peito (V), remendo no cotovelo, tira diagonal e a bolsa no flanco
			RoupaGatoF._tronco(cv, "j", -12, -4)
			_ret(cv, 1, -14, 3, -12, "j")
			_luz(cv, "j", "J", "S")
			_ret(cv, 3, -9, 6, -8, "k")
			_px(cv, 4, -8, "k")
			_px(cv, 2, -9, "J")
			_px(cv, 6, -8, "J")
			_ret(cv, 5, -6, 7, -4, "k")
			_lin(cv, Vector2i(3, -10), Vector2i(-4, -7), "l")
			_txt(cv, -7, -8, [
				"mmmm",
				"mllm",
				"mllm",
				"mmmm",
			])
			_px(cv, -6, -6, "g")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_ARQ4)]
		Pecas.Tipo.CHICOTE_BARBANTE:
			# chicote de corda laranja: laço enrolado de 4x4 no punho e a cauda em S suave de 2 px que acaba esfiapada em duas pontas
			_txt(cv, 11, -13, [
				".cc.",
				"cxxc",
				"cxxc",
				".cc.",
			])
			_ret(cv, 15, -12, 18, -10, "c")
			_ret(cv, 18, -13, 21, -11, "c")
			_ret(cv, 21, -12, 24, -10, "c")
			_ret(cv, 24, -11, 27, -9, "c")
			_px(cv, 27, -11, "c")
			_px(cv, 26, -8, "c")
			_luz(cv, "c", "C", "x")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_ARQ4)]
		Pecas.Tipo.IDOLO_ATUM:
			# ídolo dourado de atum: corpo oval em pé de olhos grandes e barbatana, sobre a base larga
			_txt(cv, -10, -21, [
				"..ggg..",
				".ggggg.",
				".gogog.",
				"ggggggg",
				".ggggg.",
				"gg.g.gg",
				"yyyyyyy",
				"yyyyyyy",
			])
			_luz(cv, "g", "G", "")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_ARQ4)]
		# ---------------------------------------------------------------- Treinador de Miaumons (Ash, Kanto)
		Pecas.Tipo.BONE_VERMELHO:
			# boné clássico de Kanto: copa vermelha, painel branco na frente com o emblema da bola e a aba curta para a frente
			_txt(cv, 2, -22, [
				"..rrrrr.....",
				".rrrrwwww...",
				"rrrrrwrrr...",
				"rrrrrwowo...",
				"rrrrrwwww...",
				"rrrrrrrrrrrr",
				"........rrrr",
			])
			_luz(cv, "r", "R", "d")
			_px(cv, 8, -19, "o")
			_px(cv, 9, -19, "w")
			_px(cv, 10, -19, "o")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_TREI)]
		Pecas.Tipo.MOCHILA_AMARELA:
			# colete azul aberto sobre a camisa branca (a barra dela aparece), bolso e duas alças escuras no peito; da mochila só aparece
			# a ponta amarela atrás da garupa
			RoupaGatoF._tronco(cv, "a", -12, -5)
			_ret(cv, 5, -9, 8, -4, "w")
			_ret(cv, -8, -5, 8, -3, "w")
			_luz(cv, "a", "b", "v")
			_luz(cv, "w", "", "W")
			_lin(cv, Vector2i(0, -12), Vector2i(3, -9), "v")
			_lin(cv, Vector2i(2, -12), Vector2i(5, -9), "v")
			_ret(cv, -3, -8, -1, -7, "b")
			_ret(cv, -3, -7, -1, -6, "v")
			_cont(cv, "o", false)
			var mo: Dictionary = {}
			_ret(mo, -11, -10, -6, -3, "y")
			_ret(mo, -11, -8, -6, -7, "z")
			_luz(mo, "y", "Y", "z")
			_cont(mo, "o")
			return [_lay(mo, RoupaGato.Onde.CORPO, _PAL_TREI, true), _lay(cv, RoupaGato.Onde.CORPO, _PAL_TREI)]
		Pecas.Tipo.MIAUBOLA:
			# a bola: metade de cima vermelha, a de baixo branca, a faixa preta e o botão central branco de contorno escuro
			_disco(cv, 16.5, -10.5, 4.5, "r")
			for k in cv.keys():
				var v: Vector2i = k
				if v.y == -11:
					cv[v] = "o"
				elif v.y > -11:
					cv[v] = "w"
			_luz(cv, "r", "R", "")
			_luz(cv, "w", "", "W")
			for yy in range(-13, -8):
				for xx in range(14, 19):
					if (xx == 14 or xx == 18) and (yy == -13 or yy == -9):
						continue
					cv[Vector2i(xx, yy)] = "o"
			_ret(cv, 15, -12, 18, -9, "w")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_TREI)]
		Pecas.Tipo.RATO_ELETRICO:
			# rato elétrico de pelúcia sentado no dorso: orelhas de ponta preta, bochechas vermelhas, olhos pretos e o rabo em raio
			_txt(cv, -10, -21, [
				"k....k..",
				"pp..pp..",
				"pp..pp..",
				"pppppp..",
				"poppop.p",
				"rppppr.p",
				".pppppp.",
				".pppp...",
			])
			_luz(cv, "p", "P", "q")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_TREI)]
	return []

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
