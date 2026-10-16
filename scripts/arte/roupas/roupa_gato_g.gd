class_name RoupaGatoG
extends RefCounted
## Roupas do gato em pixel art, tipos 124 em diante (ver RoupaGato para as convenções): expansão das fantasias, lote 2
## (Disparamiau 124-127, Milhau 128-131 [retirado do jogo: só silhuetas simples], Giramiau 132-135, Stardew Miaulley 136-139,
## Miaucraft 140-143, Miaulax 144-147).
##
## COMO ENCAIXA NO GATO: igual ao RoupaGatoF, as peças são desenhadas em COORDENADAS DO GATO (x para a frente, y para cima, pé em 0;
## cabeça em x 3..10 / y -17..-10, tronco em x -8..7 / y -12..-6) e convertidas para o lugar onde ficam presas. A cabeça cobre a do
## gato (ou, no chapéu, só o alto dela), o corpo cobre o tronco, os acessórios ficam no dorso (Onde.CORPO, de y -13 para cima) e as
## peças de mão na boca. Camada [x, y, linhas, paleta, true] = ATRÁS do corpo (vagem do Disparamiau).
##
## ESTILO (ficha visual do lote 2): contorno quase preto de 1 px nos 4 vizinhos, a borda de baixo do corpo sem contorno; 3 tons por
## material com luz em cima e sombra embaixo feitas por regra (`_luz`); sem ruído, pontilhado nem alfa; no máximo 18 cores por fantasia.
## Cada peça é escrita em letras (`_txt`) em coordenadas do gato e o contorno e a luz vêm por regra.
##
## FALLBACK: peça sem arte própria em `_montar` desenha a silhueta de uma peça do lado de fora, tingida.

const PRIMEIRO := 124
## Silhuetas de reserva por espaço (cabeça, corpo, mão, acessório); cada fantasia usa uma das 4 colunas.
const _MOLDE_FALLBACK: Array = [
	[Pecas.Tipo.CAPACETE_AZUL, Pecas.Tipo.BANDANA_FOLHA, Pecas.Tipo.CAPUZ_TUBARAO, Pecas.Tipo.ANTENAS],
	[Pecas.Tipo.COLETE_LISTRADO, Pecas.Tipo.MACACAO_LARANJA, Pecas.Tipo.ARMADURA_AZUL, Pecas.Tipo.ROUPA_TUBARAO],
	[Pecas.Tipo.KUNAI, Pecas.Tipo.CANHAO_BRACO, Pecas.Tipo.MORDIDA, Pecas.Tipo.FERRAO],
	[Pecas.Tipo.TANQUE, Pecas.Tipo.PERGAMINHO, Pecas.Tipo.BOIA, Pecas.Tipo.POTE_MEL],
]

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão (cabeça, corpo, boca e traseira). Os acessórios do lote 2 vão no dorso.
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.VAGEM_MUNICAO, Pecas.Tipo.TABLETE_MANTEIGA, Pecas.Tipo.VASO_SORRISO, Pecas.Tipo.GALINHA, Pecas.Tipo.MINI_CREEPER, Pecas.Tipo.PRATO_VAZIO:
			return RoupaGato.Onde.CORPO
	return -1

## Peças com camada atrás do corpo do gato.
static func tem_atras(tipo: int) -> bool:
	return tipo == Pecas.Tipo.VAGEM_MUNICAO

# ------------------------------------------------------------------ paletas
## Disparamiau: o contorno verde-noite; a/b/d cabeça e focinho (médio, luz, sombra); m/M/D folha e corpo (médio, luz, sombra);
## p/P ervilha (média, luz); k boca oca e pupila; w branco do olho; g/s aço do cano (médio, sombra).
const _PAL_DISP := {
	"o": Color("0a2914"), "a": Color("6fc845"), "b": Color("a9e27b"), "d": Color("43923a"),
	"m": Color("2f9440"), "M": Color("58b64c"), "D": Color("1d5e2c"), "p": Color("8edb5a"), "P": Color("d6f5a8"),
	"k": Color("0e1a12"), "w": Color("f4f8f0"), "g": Color("8c9aa6"), "s": Color("5a6672"),
}
const _PAL_MILHO := {
	"o": Color(0.35, 0.22, 0.04), "a": Color(0.98, 0.85, 0.25), "b": Color(1.0, 0.95, 0.55), "d": Color(0.85, 0.65, 0.12),
	"v": Color(0.3, 0.66, 0.25), "V": Color(0.6, 0.9, 0.45), "D": Color(0.16, 0.42, 0.16), "k": Color(0.15, 0.1, 0.08),
	"w": Color(1, 0.98, 0.9), "W": Color(0.9, 0.84, 0.66), "y": Color(1.0, 0.9, 0.4), "Y": Color(1.0, 0.97, 0.7),
	"g": Color(0.62, 0.66, 0.7), "G": Color(0.88, 0.9, 0.93), "s": Color(0.34, 0.36, 0.42), "r": Color(0.86, 0.22, 0.2),
	"x": Color(1.0, 0.7, 0.55), "m": Color(0.98, 0.9, 0.5), "M": Color(1.0, 0.98, 0.78), "n": Color(0.88, 0.7, 0.2),
}
## Giramiau: o marrom-noite; y/Y/f pétala (média, luz, sombra e pétala de trás); m/M/E miolo (médio, anel claro, sombra);
## g/G/D folha (média, luz, sombra); k olhos e sorriso.
const _PAL_SOL := {
	"o": Color("2a1608"), "y": Color("f4c430"), "Y": Color("ffe98a"), "f": Color("d99a12"),
	"m": Color("7a4a1e"), "M": Color("9a6a32"), "E": Color("4f2e10"),
	"g": Color("3c9a3c"), "G": Color("6cc15a"), "D": Color("256e2e"), "k": Color("1a0f08"),
}
## Stardew Miaulley: o marrom-noite; S/s/d palha (luz, média, sombra); R/r/E camisa; b/a/D jardineira (luz, média, sombra);
## y botão; x/w madeira (média, escura e fita do chapéu); I/i ferro; J/j Junimo (luz, médio); l folha do Junimo.
const _PAL_STAR := {
	"o": Color("2b1a10"), "S": Color("f5de9a"), "s": Color("e3bf6a"), "d": Color("b88e40"),
	"R": Color("e8776a"), "r": Color("c8453c"), "E": Color("8e2a28"),
	"b": Color("6b90d0"), "a": Color("3f66b0"), "D": Color("284585"), "y": Color("f2c94c"),
	"x": Color("a5703a"), "w": Color("6a4220"), "I": Color("c5d0d8"), "i": Color("8c9aa6"),
	"J": Color("8edb6a"), "j": Color("5bbf4c"), "l": Color("c6e04c"),
}
## Miaucraft: o preto-azulado; H/h cabelo (claro, médio); s/u pele (média, sombra do nariz); w branco do olho; a/A/d camiseta ciano
## (média, luz, sombra); p/P/q calça índigo (média, luz, sombra) e íris; T/U/D diamante; x madeira e barba; g/G bloco de grama.
const _PAL_CRAFT := {
	"o": Color("0c0c14"), "H": Color("5e3f25"), "h": Color("4a2f1b"), "s": Color("c9966f"), "u": Color("a3724d"), "w": Color("f2f2f8"),
	"a": Color("2eb8b8"), "A": Color("5ed6d0"), "d": Color("1b8a8c"),
	"p": Color("3b3fa0"), "P": Color("5a5fc8"), "q": Color("26296e"),
	"T": Color("35e6c4"), "U": Color("b8ffee"), "D": Color("17a890"), "x": Color("a5773a"),
	"g": Color("4db640"), "G": Color("7fd468"),
}
## Miaulax: o azul-petróleo escuro; a/b/d corpo teal (médio, luz, sombra); c/e creme (médio, sombra); k olhos e boca; w dentes e arroz;
## r baga vermelha; y pera; x/z vime (médio, escuro).
const _PAL_LAX := {
	"o": Color("0f2127"), "a": Color("3b7f86"), "b": Color("62a8a8"), "d": Color("285a66"),
	"c": Color("f6e7bd"), "e": Color("d9c28e"), "k": Color("1b2a30"), "w": Color("ffffff"),
	"r": Color("d8453a"), "y": Color("f2c94c"), "x": Color("a5773a"), "z": Color("6a4220"),
}

# ------------------------------------------------------------------ ferramentas (usam as telas de RoupaGatoF)
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

static func _pico(cv: Dictionary, a: Vector2i, b: Vector2i, p: Vector2i, ch: String) -> void:
	RoupaGatoF._pico(cv, a, b, p, ch)

static func _cont(cv: Dictionary, ch: String, baixo: bool = true) -> void:
	RoupaGatoF._cont(cv, ch, baixo)

static func _luz(cv: Dictionary, base: String, luz: String, sombra: String = "") -> void:
	RoupaGatoF._luz(cv, base, luz, sombra)

static func _lay(cv: Dictionary, lugar: int, pal: Dictionary, atras: bool = false) -> Array:
	return RoupaGatoF._lay(cv, lugar, pal, atras)

static func _linhas(lugar: int, x: int, y: int, linhas: Array, pal: Dictionary, atras: bool = false) -> Array:
	return RoupaGatoF._linhas(lugar, x, y, linhas, pal, atras)

## Põe a tela `de` por cima da tela `cv`.
static func _sobre(cv: Dictionary, de: Dictionary) -> void:
	for k in de.keys():
		cv[k] = de[k]

## Texto escrito à mão sobre a tela: `x`, `y` = canto de cima à esquerda; "." = não pinta.
static func _txt(cv: Dictionary, x: int, y: int, linhas: Array) -> void:
	for j in linhas.size():
		var s: String = linhas[j]
		for i in s.length():
			if s[i] != ".":
				cv[Vector2i(x + i, y + j)] = s[i]

## Troca `de` por `para` nos pixels que têm um vizinho (4 direções) que não é de `de` nem de `tambem`: o anel de fora de uma mancha.
static func _anel(cv: Dictionary, de: String, para: String, tambem: String = "") -> void:
	var mud: Array = []
	for k in cv.keys():
		var v: Vector2i = k
		if cv[v] != de:
			continue
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: String = cv.get(v + d, "")
			if n != de and (tambem == "" or n != tambem):
				mud.append(v)
				break
	for v2 in mud:
		cv[v2] = para

# ------------------------------------------------------------------ peças
static var _cache: Dictionary = {}

## Camadas da peça com arte própria; vazio = usa o fallback.
static func _camadas(tipo: int, _anim: float, _maxima: bool = false) -> Array:
	if _cache.has(tipo):
		return _cache[tipo]
	var r: Array = _montar(tipo)
	_cache[tipo] = r
	return r

static func _montar(tipo: int) -> Array:
	var cv: Dictionary = {}
	match tipo:
		# ---------------------------------------------------------------- Disparamiau (ervilha soldado, Garden Warfare 2)
		Pecas.Tipo.CABECA_ERVILHA:
			# esfera verde-clara cobrindo a cabeça, focinho-canhão da mesma cor com a boca escura oca, olho bravo de sobrancelha torta
			# e um topete de folhas curvado para trás
			_txt(cv, 1, -23, [
				".MM...........",
				".mMM.MM.......",
				"..mMMmMm......",
				"...mmmmm......",
				"....mmmm......",
			])
			_txt(cv, 2, -18, [
				"..aaaaaa.....",
				".aaaaaaaa....",
				"aaaaaaaaaa...",
				"aaaaaaaaaa...",
				"aaaaaaaaaa...",
				"aaaaaaaaaaaaa",
				"aaaaaaaaaaaaa",
				"aaaaaaaaaaaaa",
				".aaaaaaaaaaaa",
			])
			_luz(cv, "a", "b", "d")
			_px(cv, 4, -17, "b")
			_px(cv, 3, -16, "b")
			# olho: branco 3x3 com a pupila para a frente e a sobrancelha descendo para o focinho
			_ret(cv, 7, -14, 10, -11, "w")
			_ret(cv, 8, -13, 10, -11, "k")
			_px(cv, 6, -16, "D")
			_px(cv, 7, -16, "D")
			_ret(cv, 8, -15, 11, -14, "D")
			# boca oca do canhão
			_ret(cv, 13, -12, 15, -10, "k")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_DISP)]
		Pecas.Tipo.CAULE_FOLHAS:
			# colete de vagem verde-escuro no tronco, colarinho de folhas pontudas no pescoço e três ervilhas no flanco
			RoupaGatoF._tronco(cv, "m", -12, -5)
			_luz(cv, "m", "M", "D")
			for ex in [-6, -3, 0]:
				_txt(cv, ex, -9, ["Pp", "pp"])
			_txt(cv, 2, -9, ["MMMMMM", "MM.MM.", "M..M.."])
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_DISP)]
		Pecas.Tipo.METRALHA_ERVILHA:
			# canhão de vagem: casca gorda com duas ervilhas aparecendo em cima e o cano de aço curto com a boca escura
			_txt(cv, 10, -9, [
				"..Pp.Pp....",
				"..pp.pp....",
				"MMMMMMMMggg",
				"mmmmmmmmgkk",
				"mmmmmmmmgkk",
				"DDDDDDDDsss",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_DISP)]
		Pecas.Tipo.VAGEM_MUNICAO:
			# vagem aberta atrás do dorso com três ervilhas à mostra (camada de trás: o corpo cobre o fundo dela)
			_txt(cv, -12, -17, [
				"Pp.Pp.Pp",
				"pp.pp.pp",
				"MMMMMMMM",
				"mmmmmmmm",
				"mmmmmmmm",
				".DDDDDD.",
				"..DDDD..",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_DISP, true)]
		# ---------------------------------------------------------------- Milhau (milho): retirado do jogo, só uma silhueta simples
		Pecas.Tipo.ESPIGA_MILHO:
			_poli(cv, [2, -14, 3, -17, 5.5, -18.8, 8.5, -18.8, 10.5, -17, 11.5, -14, 11.5, -11, 10.5, -9.5, 4, -9.5, 2.5, -11], "a")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_MILHO)]
		Pecas.Tipo.FOLHAS_MILHO:
			RoupaGatoF._tronco(cv, "v", -12, -5)
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MILHO)]
		Pecas.Tipo.BAZUCA_PIPOCA:
			_ret(cv, 10, -14, 19, -9, "g")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_MILHO)]
		Pecas.Tipo.TABLETE_MANTEIGA:
			_ret(cv, -6, -17, 2, -12, "M")
			_cont(cv, "n")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MILHO)]
		# ---------------------------------------------------------------- Giramiau (girassol, Garden Warfare 2)
		Pecas.Tipo.PETALAS_SOL:
			# o girassol É a cabeça: oito pétalas (as de trás, nas diagonais, em tom mais escuro), miolo marrom com anel claro e o rosto simpático
			_txt(cv, 0, -19, [
				".....yyyy.....",
				"..ff.yyyy.ff..",
				".ffffmmmmffff.",
				".fffmmmmmmfff.",
				"yyymmmmmmmmyyy",
				"yyymmmmmmmmyyy",
				"yyymmmmmmmmyyy",
				"yyymmmmmmmmyyy",
				".fffmmmmmmfff.",
				".ffffmmmmffff.",
				"..ff.yyyy.ff..",
				".....yyyy.....",
			])
			_luz(cv, "y", "Y", "f")
			_anel(cv, "m", "M")
			_ret(cv, 5, -15, 6, -13, "k")
			_ret(cv, 8, -15, 9, -13, "k")
			_px(cv, 4, -13, "k")
			_px(cv, 9, -13, "k")
			_ret(cv, 5, -12, 9, -11, "k")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_SOL)]
		Pecas.Tipo.CAULE_RAIOS:
			# colete de folhas verdes com nervuras e a barra serrilhada em cinco pontas
			RoupaGatoF._tronco(cv, "g", -12, -6)
			for c in [-6, -3, 0, 3, 6]:
				_ret(cv, c - 1, -5, c + 2, -4, "g")
				_px(cv, c, -4, "g")
			_luz(cv, "g", "G", "D")
			for c2 in [-6, -3, 0, 3, 6]:
				_px(cv, c2, -7, "D")
				_px(cv, c2, -6, "D")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_SOL)]
		Pecas.Tipo.LANTERNA_SOL:
			# florzinha amarela de cabo curto (a mão-flor do Girassol)
			_lin(cv, Vector2i(11, -11), Vector2i(15, -8), "g")
			_px(cv, 13, -8, "G")
			_px(cv, 14, -7, "G")
			_txt(cv, 16, -10, [
				"..yy..",
				".yyyy.",
				"yymmyy",
				"yymmyy",
				".yyyy.",
				"..yy..",
			])
			_luz(cv, "y", "Y", "f")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_SOL)]
		Pecas.Tipo.VASO_SORRISO:
			# o sol do PvZ no dorso: disco claro com oito raios curtos
			_txt(cv, -9, -19, [
				"...y...",
				".y.y.y.",
				"..YYY..",
				"yyYYYyy",
				"..YYY..",
				".y.y.y.",
				"...y...",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_SOL)]
		# ---------------------------------------------------------------- Stardew Miaulley
		Pecas.Tipo.BONE_FAZENDA:
			# chapéu de palha de aba larga e levemente caída na frente, copa baixa com fita escura; o rosto do gato fica à mostra
			_txt(cv, 1, -22, [
				"....ssss....",
				"...ssssss...",
				"...ssssss...",
				"...wwwwww...",
				".ssssssssss.",
				"ssssssssssss",
				".sssssssssss",
			])
			_px(cv, 11, -15, "s")
			_px(cv, 12, -15, "s")
			_luz(cv, "s", "S", "d")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_STAR)]
		Pecas.Tipo.MACACAO_JEANS:
			# camisa vermelha por baixo de uma jardineira azul: alça do ombro ao peitilho, dois botões e bolso
			RoupaGatoF._tronco(cv, "r", -12, -5)
			for k in cv.keys():
				var v: Vector2i = k
				if (v.x < 3 and v.y >= -9) or (v.x >= 3 and v.y >= -8):
					cv[v] = "a"
			for k2 in cv.keys():
				var v2: Vector2i = k2
				if cv[v2] == "a" and cv.get(v2 + Vector2i(0, -1), "") == "r":
					cv[v2] = "b"
			_lin(cv, Vector2i(0, -12), Vector2i(3, -9), "a")
			_lin(cv, Vector2i(1, -12), Vector2i(4, -9), "a")
			_luz(cv, "r", "R", "E")
			_luz(cv, "a", "b", "D")
			_px(cv, 4, -8, "y")
			_px(cv, 7, -8, "y")
			_ret(cv, 4, -7, 7, -6, "D")
			_px(cv, 4, -6, "D")
			_px(cv, 6, -6, "D")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_STAR)]
		Pecas.Tipo.ENXADA:
			# enxada: cabo reto de madeira em diagonal (2 px) e a lâmina de ferro cinza-azulada em ângulo reto
			_lin(cv, Vector2i(11, -10), Vector2i(18, -17), "x")
			_lin(cv, Vector2i(12, -10), Vector2i(19, -17), "w")
			_txt(cv, 18, -19, [
				"iiiii",
				".iiii",
				"...ii",
				"...ii",
				"..iii",
			])
			_luz(cv, "i", "I", "")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_STAR)]
		Pecas.Tipo.GALINHA:
			# Junimo, o espiritinho verde de Stardew, pequeno no dorso
			_txt(cv, -6, -19, [
				"..l..",
				".jjj.",
				"jjjjj",
				"jojoj",
				"jojoj",
				"jjjjj",
			])
			_luz(cv, "j", "J", "")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_STAR)]
		# ---------------------------------------------------------------- Miaucraft
		Pecas.Tipo.CUBO_PIXEL:
			# cabeça de Steve: cubo de 8x8 (cabelo, olhos de branco por fora e íris por dentro, nariz e barba) cobrindo a cabeça
			_txt(cv, 3, -17, [
				"HHHHHHHH",
				"hhhhhhhh",
				"hssssssh",
				"ssssssss",
				"swpsspws",
				"sssuusss",
				"ssxxxxss",
				"sssxxsss",
			])
			_ret(cv, 2, -17, 3, -13, "h")
			_ret(cv, 2, -13, 3, -10, "s")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_CRAFT)]
		Pecas.Tipo.CAMISETA_BLOCOS:
			# camiseta ciano na frente, calça índigo na garupa e um toco de braço de pele
			RoupaGatoF._tronco(cv, "a", -12, -5)
			for k in cv.keys():
				var v: Vector2i = k
				if v.x <= -3:
					cv[v] = "p"
			_luz(cv, "a", "A", "d")
			_luz(cv, "p", "P", "q")
			_ret(cv, 4, -8, 7, -6, "s")
			_ret(cv, 4, -6, 7, -5, "u")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_CRAFT)]
		Pecas.Tipo.PICARETA:
			# picareta de diamante: cabo de madeira diagonal e a cabeça em arco turquesa
			_lin(cv, Vector2i(11, -10), Vector2i(19, -18), "x")
			_lin(cv, Vector2i(12, -10), Vector2i(20, -18), "h")
			var ar: Dictionary = {}
			for of in [Vector2i(-3, -3), Vector2i(-2, -3), Vector2i(-1, -3), Vector2i(0, -3), Vector2i(1, -2), Vector2i(2, -1), Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3),
					Vector2i(-2, -2), Vector2i(-1, -2), Vector2i(0, -2), Vector2i(1, -1), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2)]:
				ar[Vector2i(19, -18) + of] = "T"
			_luz(ar, "T", "U", "D")
			_sobre(cv, ar)
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_CRAFT)]
		Pecas.Tipo.MINI_CREEPER:
			# bloco de grama do Minecraft no dorso
			_txt(cv, -8, -18, [
				"GGGGGG",
				"gggggg",
				"gxgxgx",
				"xxxxxx",
				"xxxxxx",
				"hhhhhh",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_CRAFT)]
		# ---------------------------------------------------------------- Miaulax (Snorlax)
		Pecas.Tipo.TOUCA_SONECA:
			# cabeça de Snorlax: orelhas curtas e largas, rosto creme, olhos fechados em risco reto e a mandíbula com dois dentinhos
			_txt(cv, 2, -21, [
				"..aa...aa..",
				".aaaa.aaaa.",
				".aaaaaaaaa.",
				"aaaaaaaaaaa",
				"aaaaaaaaaaa",
				"aaaccccccaa",
				"aacccccccca",
				"aaccccccccc",
				"aaccccccccc",
				"aaccccccccc",
				"aaccccccccc",
				".aaccccccc.",
			])
			_luz(cv, "a", "b", "d")
			_luz(cv, "c", "", "e")
			_ret(cv, 5, -14, 8, -13, "k")
			_ret(cv, 9, -14, 12, -13, "k")
			_ret(cv, 6, -12, 10, -10, "k")
			_px(cv, 7, -12, "w")
			_px(cv, 9, -12, "w")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_LAX)]
		Pecas.Tipo.BARRIGA_CREME:
			# tronco teal com a barriga creme oval dentro dele, sem passar das costas nem das patas
			RoupaGatoF._tronco(cv, "a", -12, -5)
			_luz(cv, "a", "b", "d")
			var be: Dictionary = {}
			_ret(be, -3, -10, 3, -9, "c")
			_ret(be, -5, -9, 6, -8, "c")
			_ret(be, -6, -8, 7, -6, "c")
			_ret(be, -5, -6, 6, -5, "c")
			for k in be.keys():
				if cv.has(k):
					cv[k] = "c"
			_luz(cv, "c", "", "e")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_LAX)]
		Pecas.Tipo.TRAVESSEIRO:
			# onigiri na mão: triângulo de arroz com a tira de alga embaixo e uma ameixa no meio
			_txt(cv, 12, -14, [
				"...w...",
				"..www..",
				".wwrww.",
				"wwwwwww",
				"wkkkkkw",
				"wkkkkkw",
			])
			for k in cv.keys():
				var v: Vector2i = k
				if cv[v] == "w" and not cv.has(v + Vector2i(1, 0)):
					cv[v] = "e"
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_LAX)]
		Pecas.Tipo.PRATO_VAZIO:
			# cestinho de vime com duas frutas, no dorso
			_txt(cv, -9, -19, [
				".rr.yy..",
				"rrrryyy.",
				"xxxxxxxx",
				"zzzzzzzz",
				"xxxxxxxx",
				".zzzzzz.",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_LAX)]
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
