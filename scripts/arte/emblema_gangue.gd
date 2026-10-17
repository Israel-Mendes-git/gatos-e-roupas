class_name EmblemaGangue
extends RefCounted
## Emblema (brasão) de cada gangue do 3º ato, em pixel art por código: grade de 16x16 (miolo 14x14 + contorno quase preto
## de 1 px), 3 tons por cor, sem alfa, na cor da gangue (Fases.GANGUE_COR). Ampliação sempre inteira: 16 px (x1), 32 (x2), 48 (x3).
## Uso: EmblemaGangue.desenhar(canvas, g, centro, tamanho, visto). Se `visto` é falso, vira a silhueta cinza com "?".
const L := 16
const N := 14
## Variante escolhida de cada gangue (0 = A, 1 = B).
const ESCOLHA: Array[int] = [0, 1, 1, 0, 1]
const COR_CONTORNO := Color(0.09, 0.07, 0.1)
static var _cache: Dictionary = {}

static func _paleta(g: int) -> Dictionary:
	var cor: Color = Fases.GANGUE_COR[g]
	return {
		"d": cor.darkened(0.5), "m": cor, "l": cor.lerp(Color(1, 1, 1), 0.5),
		"w": Color(0.97, 0.93, 0.8), "W": Color(0.76, 0.7, 0.6), "k": Color(0.15, 0.12, 0.14), "n": Color(0.05, 0.09, 0.18),
		"g": Color(0.78, 0.8, 0.86), "G": Color(0.45, 0.48, 0.56), "y": Color(0.98, 0.8, 0.25), "Y": Color(0.72, 0.5, 0.12),
		"r": Color(0.92, 0.2, 0.14), "R": Color(0.6, 0.1, 0.1), "c": Color(0.35, 0.95, 1.0), "p": Color(0.95, 0.6, 0.65),
	}

## Corridas horizontais [x, y, largura, cor] da grade 16x16 já com contorno (ou em silhueta cinza com "?").
static func _corridas(g: int, v: int, visto: bool) -> Array:
	var chave: int = g * 100 + v * 10 + (1 if visto else 0)
	if _cache.has(chave):
		return _cache[chave]
	var pal: Dictionary = _paleta(g)
	var arte: Array = DADOS[g][v]
	var cel: Array = []   # 16x16 de Color ou null
	for j in L:
		var lin: Array = []
		for i in L:
			lin.append(null)
		cel.append(lin)
	for j in N:
		var s: String = arte[j]
		for i in N:
			var ch: String = s[i]
			if ch == ".":
				continue
			var c: Color = pal[ch]
			if not visto:
				c = Color(0.42, 0.39, 0.38) if (ch in "dkGYWRn") else Color(0.56, 0.52, 0.5)
			cel[j + 1][i + 1] = c
	var cont: Color = COR_CONTORNO if visto else Color(0.2, 0.18, 0.19)
	var grade: Array = []
	for j in L:
		var lin2: Array = []
		for i in L:
			var c2 = cel[j][i]
			if c2 == null:
				for dj in range(-1, 2):
					for di in range(-1, 2):
						var jj: int = j + dj
						var ii: int = i + di
						if jj >= 0 and jj < L and ii >= 0 and ii < L and cel[jj][ii] != null and (dj == 0 or di == 0):
							c2 = cont
			lin2.append(c2)
		grade.append(lin2)
	if not visto:   # o "?" claro no meio
		for p in [Vector2i(7, 5), Vector2i(8, 5), Vector2i(6, 6), Vector2i(9, 6), Vector2i(8, 7), Vector2i(7, 8), Vector2i(7, 10)]:
			grade[p.y][p.x] = Color(0.92, 0.88, 0.8)
	var res: Array = []
	for j in L:
		var i := 0
		while i < L:
			var c3 = grade[j][i]
			if c3 == null:
				i += 1
				continue
			var k := i
			while k + 1 < L and grade[j][k + 1] == c3:
				k += 1
			res.append([i, j, k - i + 1, c3])
			i = k + 1
	_cache[chave] = res
	return res

## Desenha o emblema da gangue `g` centrado em `centro`. `tam` vira a ampliação inteira mais próxima (16, 32, 48...).
## `variante` -1 usa a escolhida; 0/1 força A/B (a folha de opções).
static func desenhar(c: CanvasItem, g: int, centro: Vector2, tam: float, visto: bool = true, variante: int = -1) -> void:
	g = clampi(g, 0, DADOS.size() - 1)
	var v: int = ESCOLHA[g] if variante < 0 else variante
	var esc: int = maxi(1, roundi(tam / float(L)))
	var o: Vector2 = (centro - Vector2(L, L) * esc * 0.5).round()
	for r in _corridas(g, v, visto):
		c.draw_rect(Rect2(o + Vector2(r[0], r[1]) * esc, Vector2(r[2], 1) * esc), r[3])

## Arte de cada emblema: 14x14 de miolo (o contorno de 1 px nasce sozinho em volta). Cada gangue tem duas variantes (A, B).
## Letras: d m l = tons da cor da gangue; w W creme; k preto; n azul-noite; g G metal; y Y ouro; r R vermelho; c ciano; p rosa.
const DADOS: Array = [
	[
		["yyyyyyyyyyyyyy", "ymmmkkkkkkmmmy", "ymmmkkkkkkmmmy", "ymmmggggggmmmy", "ymkkkkkkkkkkmy", "ymmmddddddmmmy", "ymmmmmmmmmmmmy", "ymwwmmwmwmmwmy", "ymwkwwwwwwwwwy", "ymwwmmwmwmmwmy", "ymmmmmmmmmmmmy", ".ymmmmmmmmmmy.", "...ymmmmmmy...", ".....yyyy....."],
		["....yyyyyy....", "..yymmmmmmyy..", ".ymmmkkkkmmmy.", ".ymmkkkkkkmmy.", "ymmmggggggmmmy", "ymkkkkkkkkkkmy", "ymmgyggggygmmy", "ymmggggppggmmy", "ymmmgwggwgmmmy", ".ymmmggggmmmy.", ".ymmmmrrmmmmy.", "..yymmrrmmyy..", "....yyyyyy....", ".............."],
	],
	[
		["..ww......ww..", ".mwwwwwwwwwwm.", ".mwwwwwwwwwwm.", "lmwwkkwwkkwwml", "lmwwkkwwkkwwml", "lmmwwwkkwwwmml", "ylmmwwwwwwmmly", "yylmwkwkwkmlyy", ".ylmmwwwwmmly.", ".yylmmwwmmlyy.", "..yylmmmmlyy..", "...yymmmmyy...", "....yyllyy....", "......yy......"],
		["......mm......", "......mm......", "..mmmmmmmmmm..", "..mmmmmmmmmd..", "..mmwkkkkwdd..", "..mmwwwwwwdd..", "mmmmwkwwkwdddd", "mmmmwwkkwwdddd", "..mmkwwwwkdd..", "..mmmkkkkddd..", "..mmdddddddd..", "..mddddddddd..", "......dd......", "......dd......"],
	],
	[
		["..............", "......cc......", ".....cnnc.....", "....wnnnnw....", "...cwwnnwwc...", "..cnnwwwwnnc..", ".cnnwmmmmwnnc.", ".cnnwkmmkwnnc.", "..cnwmmmmwnc..", "...cwmwwmwc...", "....cwwwwc....", ".....cnnc.....", "......cc......", ".............."],
		["..c........c..", "..cc......cc..", "..ccc....ccc..", "....cccccc....", "...cnnnnnnc...", "..cnnmnnmnnc..", "..cnnnmmnnnc..", ".cnmwwnnwwmnc.", ".cnmnlnnlnmnc.", ".cnmnllllnmnc.", "..cnnnnnnnnc..", "..cnnmmmmnnc..", "...cnnnnnnc...", "....cccccc...."],
	],
	[
		["..y.rrrrrr.y..", "..yyrrrrrryy..", "..yyyrrrryyy..", "..yyyyyyyyyy..", ".yyyyyyyyyyyy.", ".yykkkyykkkyy.", ".yykkkyykkkyy.", ".yyYkkyykkYyy.", ".yyYkkkkkkYyy.", "..yYkkkkkkYy..", "..yYYkkkkYYy..", "...YYkkkkYY...", "....YYYYYY....", ".............."],
		["..y.rrrrrr.y..", "..yyrrrrrryy..", "..yyyyyyyyyy..", ".....YYYY.....", "...YymmmmyY...", "..YymmyymmyY..", "..ymmyyyymmy..", ".YmmyymmyymmY.", ".YmmyymmyymmY.", ".YmyymmmmyymY.", "..yyymmmmyyy..", "..YmmmmmmmmY..", "...ymmmmmmy...", "....YyyyyY...."],
	],
	[
		[".m..........m.", ".mm........mm.", ".mmlldddddmmm.", "...lmmmmmmd...", "..lwwmmmmwwd..", ".dlmwwmmwwmmd.", ".dmmmwwwwmmmd.", ".dmmmmwwmmmmd.", ".dmmmwwwwmmmd.", ".dmmwwmmwwmmd.", ".dmwwmmmmwwmd.", "..wwmmmmmmww..", "...dmmmmmmd...", "....dddddd...."],
		["..............", "....rrrrrr....", "...rrrrrrrr...", "..rrrrrrrrrr..", ".rrrr....rrrr.", ".Rrr......rRr.", ".Rrr......rRr.", ".Rrr......rRr.", "rrrr......rrrr", "rrrr..ll..rrrr", "Wggg.l..l.Wggg", "Wggg..ll..Wggg", "Wggg.l..l.Wggg", "Wggg......Wggg"],
	],
]
