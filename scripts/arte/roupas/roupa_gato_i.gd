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

## Topo do corpo vestido em cada coluna x (-8..8): garupa redonda, costas com uma leve corcova, ombro que desce em diagonal até o peito.
const _TOPO_CORPO := {-8: -9, -7: -10, -6: -11, -5: -12, -4: -12, -3: -13, -2: -13, -1: -13, 0: -13, 1: -12, 2: -12, 3: -11, 4: -10, 5: -9, 6: -9, 7: -9, 8: -9}

## Corpo vestido que SEGUE A SILHUETA do gato (em vez do bloco): `th` = última linha da barra sobre a anca, `bh` = sob a barriga (a barra sobe
## em arco entre as patas), `fh` = sobre o peito/patas da frente; as pontas atrás e na frente arredondam um pixel.
static func _corpo(cv: Dictionary, ch: String, th: int, bh: int, fh: int) -> void:
	for x in range(-8, 9):
		var b: int
		if x == -8:
			b = th - 1
		elif x <= -3:
			b = th
		elif x == -2:
			b = (th + bh) / 2
		elif x <= 2:
			b = bh
		elif x == 3:
			b = (bh + fh) / 2
		elif x <= 7:
			b = fh
		else:
			b = fh - 1
		for y in range(_TOPO_CORPO[x], b + 1):
			cv[Vector2i(x, y)] = ch

## Gola levantada atrás do pescoço: cunha que acompanha a nuca da cabeça (x 0..3, até 4 linhas, y -16..-13).
static func _gola(cv: Dictionary, ch: String, alta: int = 4) -> void:
	var l: Array = [[3, 3], [2, 3], [1, 3], [0, 3]]
	for i in alta:
		var r: Array = l[4 - alta + i]
		for x in range(int(r[0]), int(r[1]) + 1):
			cv[Vector2i(x, -16 + (4 - alta) + i)] = ch

## Pinta só onde já há roupa (detalhes não criam cantos novos).
static func _sobre(cv: Dictionary, x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			if cv.has(Vector2i(x, y)):
				cv[Vector2i(x, y)] = ch

static func _linsobre(cv: Dictionary, a: Vector2i, b: Vector2i, ch: String) -> void:
	var t: Dictionary = {}
	_lin(t, a, b, ch)
	for k in t.keys():
		if cv.has(k):
			cv[k] = ch

## Dobras: riscos de sombra de 2 px subindo da barra em x (acompanham o caimento do pano).
static func _dobras(cv: Dictionary, xs: Array, ch: String) -> void:
	for x in xs:
		var base: int = -99
		for y in range(-14, 0):
			if cv.has(Vector2i(x, y)):
				base = y
		if base > -99:
			_px(cv, x, base - 1, ch)
			_px(cv, x, base, ch)

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
		var topo: int = floori(-13.0 + 6.0 * u + onda * 0.5)
		var base: int = ceili(-4.6 + 2.2 * u + onda)
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
			# sobretudo longo cinza-grafite que segue o dorso curvo: gola alta levantada, lapela em diagonal, abotoamento duplo, cinto com laço,
			# a barra que abre atrás (fenda) e sobe em arco sob a barriga, deixando as patas saírem; três gotas de chuva
			_corpo(cv, "c", -5, -7, -5)
			_gola(cv, "c")
			_luz(cv, "c", "C", "S")
			_px(cv, 3, -15, "S")
			_px(cv, 3, -14, "S")
			_linsobre(cv, Vector2i(3, -11), Vector2i(6, -8), "C")
			_linsobre(cv, Vector2i(4, -11), Vector2i(7, -8), "S")
			_sobre(cv, -7, -8, 3, -7, "S")
			_px(cv, 2, -8, "o")
			_px(cv, -5, -5, "S")
			_px(cv, -5, -6, "S")
			_dobras(cv, [-3, 3], "S")
			for b in [Vector2i(4, -7), Vector2i(4, -6), Vector2i(6, -7), Vector2i(6, -6)]:
				if cv.has(b):
					cv[b] = "C"
			for g in [Vector2i(-5, -10), Vector2i(-2, -11), Vector2i(-4, -6)]:
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
			# casco branco arredondado cobrindo o rosto todo, dois chifres em lira (nascem juntos no topo, abrem para fora e sobem, com a ponta
			# voltada para dentro), dois olhos pretos ovais verticais (o da frente inteiro, o de trás meio escondido) e sem boca
			_txt(cv, 2, -24, [
				".ww.....ww.",
				"ww.......ww",
				"ww.......ww",
				".ww.....ww.",
				"..ww...ww..",
				"...wwwww...",
				".wwwwwwwww.",
				"wwwwwwwwwww",
				"wwwwwwwwwww",
				"wwwwwwwwwww",
				"wwwwwwwwwww",
				"wwwwwwwwwww",
				".wwwwwwwwww",
				"..wwwwwwww.",
				"...wwwwww..",
			])
			_canto(cv, "w", "d")
			_ret(cv, 9, -16, 11, -15, "k")
			_ret(cv, 8, -15, 11, -12, "k")
			_ret(cv, 9, -12, 11, -11, "k")
			_px(cv, 8, -15, "e")
			_ret(cv, 4, -14, 6, -12, "k")
			_px(cv, 5, -15, "k")
			_px(cv, 5, -12, "k")
			_px(cv, 6, -19, "W")
			_px(cv, 5, -18, "W")
			_px(cv, 4, -17, "W")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_HOLLOW)]
		Pecas.Tipo.MANTO_PRETINHO:
			# manto azul-marinho curto de gola alta, curva da garupa à barriga e um broche branco; atrás do corpo, a capa cai sobre a anca
			# (só se abre um pouco, sem pregas)
			_corpo(cv, "a", -6, -7, -6)
			_gola(cv, "a")
			_luz(cv, "a", "b", "D")
			_px(cv, 3, -15, "D")
			_px(cv, 3, -14, "D")
			_linsobre(cv, Vector2i(3, -11), Vector2i(5, -9), "b")
			_px(cv, 4, -8, "W")
			_dobras(cv, [-4, 2], "D")
			_cont(cv, "o", false)
			var capa: Dictionary = {}
			_poli(capa, [3, -14.5, 0, -14.8, -4, -14.2, -8, -13, -10.5, -10.5, -12, -7.5, -11.5, -4.5, -9.5, -5.2, -8, -6.5], "a")
			_luz(capa, "a", "b", "D")
			_cont(capa, "o")
			return [_lay(capa, RoupaGato.Onde.CORPO, _PAL_HOLLOW, true), _lay(cv, RoupaGato.Onde.CORPO, _PAL_HOLLOW)]
		Pecas.Tipo.PREGO_AFIADO:
			# o prego (Old Nail): cabo curto escuro, guarda pequena, lâmina reta de aço com o fio claro em cima e a ponta estreita e chanfrada
			_ret(cv, 11, -11, 14, -9, "u")
			_ret(cv, 14, -13, 15, -8, "u")
			_ret(cv, 15, -12, 24, -9, "n")
			_ret(cv, 24, -11, 26, -10, "n")
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
			# casco branco estreito de queixo pontudo cobrindo o rosto todo, olhos pretos em fenda triangular inclinada e dois chifres LONGOS
			# que sobem e curvam para trás em gancho (o de trás, mais curto e escuro)
			_txt(cv, 4, -19, [
				"..wwww..",
				".wwwwww.",
				"wwwwwwww",
				"wwwwwwww",
				"wwwwwwww",
				"wwwwwwww",
				".wwwwwww",
				".wwwwww.",
				"..wwwww.",
				"...wwww.",
				"....ww..",
			])
			_canto(cv, "w", "d")
			for q0 in [Vector2i(7, -15), Vector2i(8, -15), Vector2i(7, -14), Vector2i(8, -14), Vector2i(9, -14), Vector2i(10, -14), Vector2i(9, -13),
					Vector2i(10, -13), Vector2i(5, -15), Vector2i(5, -14)]:
				cv[q0] = "k"
			_px(cv, 7, -19, "W")
			_px(cv, 6, -18, "W")
			var hc: Dictionary = {}
			for q in [Vector2i(8, -20), Vector2i(9, -20), Vector2i(7, -21), Vector2i(8, -21), Vector2i(6, -22), Vector2i(7, -22), Vector2i(5, -23),
					Vector2i(6, -23), Vector2i(3, -24), Vector2i(4, -24), Vector2i(5, -24), Vector2i(3, -23)]:
				hc[q] = "w"
			_canto(hc, "w", "d")
			for q2 in [Vector2i(4, -19), Vector2i(5, -19), Vector2i(3, -20), Vector2i(4, -20), Vector2i(2, -21), Vector2i(3, -21), Vector2i(0, -22),
					Vector2i(1, -22), Vector2i(2, -22), Vector2i(0, -21)]:
				hc[q2] = "d"
			for kk in hc.keys():
				if not cv.has(kk):
					cv[kk] = hc[kk]
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_SILK)]
		Pecas.Tipo.CAPA_CARMESIM:
			# a capa carmesim comprida esvoaça ATRÁS do corpo (acompanha o dorso e cai pela anca; barra em duas pontas, balança em 2 quadros);
			# na frente só o top vermelho curto de gola alta, o cinto escuro e a saia que sobe em arco sob a barriga
			var cp: Dictionary = _capa_silk(fase)
			_luz(cp, "a", "b", "D")
			_cont(cp, "o")
			_corpo(cv, "a", -5, -7, -6)
			_gola(cv, "a")
			_luz(cv, "a", "b", "D")
			_px(cv, 3, -15, "D")
			_px(cv, 3, -14, "D")
			_linsobre(cv, Vector2i(3, -11), Vector2i(5, -9), "b")
			_sobre(cv, -7, -9, 3, -8, "D")
			_dobras(cv, [-5, -2], "D")
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
			# gi laranja do Goku que segue o corpo: decote em V com a camisa azul, faixa azul na cintura com nó e as pontas, punhos azuis
			# nas patas (as patas saem por baixo); a barra sobe em arco sob a barriga
			_corpo(cv, "a", -6, -7, -6)
			_luz(cv, "a", "b", "D")
			_linsobre(cv, Vector2i(5, -9), Vector2i(7, -7), "u")
			_linsobre(cv, Vector2i(6, -9), Vector2i(8, -7), "U")
			_sobre(cv, -8, -9, 5, -8, "u")
			_sobre(cv, -8, -8, 5, -7, "V")
			_ret(cv, -3, -8, 0, -6, "u")
			_px(cv, -2, -8, "U")
			_px(cv, -3, -6, "V")
			_px(cv, -1, -6, "V")
			_dobras(cv, [-5, 3], "D")
			_ret(cv, -5, -5, -1, -3, "u")
			_ret(cv, -5, -4, -1, -3, "V")
			_ret(cv, 6, -5, 8, -3, "u")
			_ret(cv, 6, -4, 8, -3, "V")
			_px(cv, 4, -5, "u")
			_px(cv, 4, -4, "V")
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
			# jaqueta de couro marrom na cintura que segue o dorso: gola de lapela, camisa cáqui no peito (V), tira diagonal e a bolsa
			# arredondada no flanco; mangas curtas deixam as patas aparecerem
			_corpo(cv, "j", -6, -7, -6)
			_gola(cv, "j", 3)
			_luz(cv, "j", "J", "S")
			_sobre(cv, 5, -9, 9, -8, "k")
			_sobre(cv, 6, -8, 8, -7, "k")
			_sobre(cv, 6, -7, 7, -6, "K")
			_linsobre(cv, Vector2i(3, -11), Vector2i(5, -9), "J")
			_linsobre(cv, Vector2i(2, -12), Vector2i(-4, -8), "l")
			_dobras(cv, [-2, 3], "S")
			_cont(cv, "o", false)
			var bolsa: Dictionary = {}
			_txt(bolsa, -7, -8, [
				".mm.",
				"mllm",
				"mllm",
				".mm.",
			])
			_px(bolsa, -6, -6, "g")
			_cont(bolsa, "o")
			for k in bolsa.keys():
				cv[k] = bolsa[k]
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
			# colete azul aberto que segue o dorso, camisa branca aparecendo no peito e nas mangas curtas, bolso e duas alças escuras;
			# da mochila só aparece a ponta amarela arredondada atrás da garupa
			_corpo(cv, "a", -6, -7, -6)
			_luz(cv, "a", "b", "v")
			_sobre(cv, 5, -9, 9, -7, "w")
			_sobre(cv, 6, -7, 9, -5, "w")
			_ret(cv, 6, -5, 8, -4, "w")
			_px(cv, 4, -5, "w")
			_luz(cv, "w", "", "W")
			_px(cv, 7, -4, "W")
			_px(cv, 6, -4, "W")
			_px(cv, 4, -5, "W")
			_sobre(cv, 5, -7, 6, -5, "b")
			_linsobre(cv, Vector2i(-1, -12), Vector2i(4, -8), "v")
			_linsobre(cv, Vector2i(1, -12), Vector2i(6, -8), "v")
			_sobre(cv, -4, -9, -2, -8, "b")
			_sobre(cv, -4, -8, -2, -7, "v")
			_dobras(cv, [-5, 2], "v")
			_cont(cv, "o", false)
			var mo: Dictionary = {}
			_poli(mo, [-6.5, -11.5, -9, -11.5, -11, -10, -11.8, -7.5, -11.5, -4.5, -10, -3.6, -7, -4.5], "y")
			_luz(mo, "y", "Y", "z")
			_ret(mo, -10, -8, -9, -5, "z")
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
