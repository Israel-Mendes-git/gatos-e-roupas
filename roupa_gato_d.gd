class_name RoupaGatoD
extends RefCounted
## Roupas do gato em pixel art, tipos 63 a 83 (ver RoupaGato para as convenções).
## Fantasias: Tartaruga Ninja (fatia de pizza), Ouriço Veloz, Armadura de Ferro, Deus do Trovão,
## Princesa do Gelo e Patrulheiro Espacial.

# contornos e tons reaproveitados por várias peças
const _OURO := Color(1.0, 0.8, 0.22)
const _OURO_ESC := Color(0.75, 0.5, 0.1)
const _AZUL_ESC := Color(0.08, 0.13, 0.45)
const _GELO_ESC := Color(0.22, 0.4, 0.62)

## Lugar do acessório no gato (RoupaGato.Onde); -1 = traseira. Só é consultado para acessórios.
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.PIZZA:
			return RoupaGato.Onde.BOCA
		Pecas.Tipo.TENIS, Pecas.Tipo.LUVAS:
			return RoupaGato.Onde.PATAS
		Pecas.Tipo.REATOR, Pecas.Tipo.FLOCO:
			return RoupaGato.Onde.PESCOCO
		Pecas.Tipo.CINTURAO:
			return RoupaGato.Onde.CORPO
	return -1

## Desenha a peça em torno da origem do lugar onde fica presa (1 unidade = 1 pixel do gato).
static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	match tipo:
		Pecas.Tipo.PIZZA:
			# fatia de pizza em diagonal: ponta na boca, borda grossa de massa na outra ponta, queijo e duas calabresas
			var ang: float = deg_to_rad(42.0)
			var eixo := Vector2(cos(ang), -sin(ang))
			var perp := Vector2(sin(ang), cos(ang))
			var comp: float = 8.5
			var cel: Dictionary = {}
			for yy in range(-14, 2):
				for xx in range(-2, 14):
					var p := Vector2(xx + 0.5, yy + 0.5) - Vector2(0.5, -0.5)
					var t: float = p.dot(eixo)
					var s: float = p.dot(perp)
					if t >= 0.0 and t <= comp and absf(s) <= t * 0.5 + 0.3:
						var tom: String = "y"
						if t > comp - 2.2:
							tom = "B" if t < comp - 1.1 else "b"
						elif (absf(t - 3.8) < 1.3 and absf(s + 0.6) < 1.3) or (absf(t - 6.0) < 1.2 and absf(s - 1.6) < 1.2):
							tom = "r"
						cel[Vector2i(xx, yy)] = tom
			for k in cel:
				var viz: bool = cel.has(k + Vector2i(1, 0)) and cel.has(k + Vector2i(-1, 0)) and cel.has(k + Vector2i(0, 1)) and cel.has(k + Vector2i(0, -1))
				var cor: Color
				match cel[k]:
					"r":
						cor = Color(0.8, 0.14, 0.12)
					"B":
						cor = Color(0.93, 0.62, 0.25)
					"b":
						cor = Color(0.76, 0.44, 0.15)
					_:
						cor = Color(1.0, 0.82, 0.28)
				if not viz:
					cor = Color(0.5, 0.25, 0.06)
				RoupaGato.r(c, k.x, k.y, 1, 1, cor, f)
		Pecas.Tipo.TOPETE:
			# espinhos azuis varridos para trás
			RoupaGato.sprite(c, -3.5, -4.0, [
				"o..o.o...",
				"bo.obobo.",
				"obobbbbo.",
				".obbBbbbo",
				"..ooooooo",
			], {"o": _AZUL_ESC, "b": Color(0.2, 0.35, 0.95), "B": Color(0.5, 0.65, 1.0)}, f)
		Pecas.Tipo.PELO_AZUL:
			# pelagem azul com os espinhos nas costas e a barriga bege embaixo
			RoupaGato.sprite(c, -6.0, -4.0, [
				".o.o.oo.o.o.",
				"obbbbbbbbbbo",
				"obBbbbbbbbbo",
				"obbbbbbbbbbo",
				"obbbbbbbbbbo",
				"occcccccccco",
				"occCCCCCCcco",
				".oooooooooo.",
			], {"o": _AZUL_ESC, "b": Color(0.2, 0.35, 0.95), "B": Color(0.5, 0.65, 1.0),
				"c": Color(0.98, 0.82, 0.62), "C": Color(1.0, 0.92, 0.78)}, f)
		Pecas.Tipo.LUVAS:
			# luva branca de punho largo, calçada na pata da frente, acima do tênis (ver onde())
			RoupaGato.sprite(c, -3.0, -9.0, [
				".oooo.",
				"owwWwo",
				"owwwwo",
				"osssso",
				".oooo.",
			], {"o": Color(0.3, 0.32, 0.45), "w": Color(0.97, 0.97, 1.0), "W": Color(1, 1, 1), "s": Color(0.78, 0.8, 0.9)}, f)
		Pecas.Tipo.TENIS:
			# um tênis vermelho com faixa branca e fivela dourada: quem chama desenha um em cada pata
			var tenis: Array = [
				"oooo..",
				"orrroo",
				"owywro",
				"oooooo",
			]
			var pal := {"o": Color(0.45, 0.05, 0.08), "r": Color(0.92, 0.12, 0.15),
				"y": Color(1.0, 0.82, 0.2), "w": Color(0.97, 0.97, 1.0)}
			RoupaGato.sprite(c, -3.0, -4.0, tenis, pal, f)
		Pecas.Tipo.CAPACETE_FERRO:
			# capacete vermelho com máscara dourada na frente e olhos em fenda branco-azulados
			RoupaGato.sprite(c, -4.5, -2.0, [
				"..ooooo....",
				".orrrrro...",
				"orRrrrrro..",
				"orrrrggggo.",
				"orrrrggggo.",
				"orrrggwwwgo",
				"orrrrgggggo",
				".orrrggggo.",
				"..ooo.ooo..",
			], {"o": Color(0.35, 0.05, 0.08), "r": Color(0.82, 0.14, 0.16), "R": Color(1.0, 0.5, 0.45), "g": _OURO, "w": Color(0.75, 0.97, 1.0)}, f)
		Pecas.Tipo.ARMADURA_FERRO:
			# peitoral vermelho com detalhes dourados e um círculo de luz azul-clara no peito (6 linhas, 11 de largura)
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"orRrcccrrro",
				"orrcwwwcrro",
				"orrcwwwcrro",
				"orrrcccrrro",
				"oggggggggro",
				".ooooooooo.",
			], {"o": Color(0.35, 0.05, 0.08), "r": Color(0.82, 0.14, 0.16), "R": Color(1.0, 0.5, 0.45),
				"g": _OURO, "c": Color(0.45, 0.8, 1.0), "w": Color(0.9, 1.0, 1.0)}, f)
		Pecas.Tipo.REPULSOR:
			# manopla com disco azul, mirando para a frente, junto ao focinho
			var pisca: bool = sin(anim * 8.0) > 0.0
			RoupaGato.sprite(c, -3.0, -3.0, [
				"..oooooo.",
				"oggoccwco",
				"ogGoCCCCo",
				"oggocccco",
				"..oooooo.",
			], {"o": Color(0.2, 0.25, 0.35), "g": Color(0.6, 0.64, 0.7), "G": Color(0.8, 0.85, 0.9),
				"c": Color(0.45, 0.8, 1.0) if pisca else Color(0.35, 0.65, 0.95),
				"C": Color(0.72, 0.95, 1.0), "w": Color(1, 1, 1)}, f)
		Pecas.Tipo.REATOR:
			var luz: String = "w" if sin(anim * 5.0) > 0.0 else "c"
			RoupaGato.sprite(c, -2.5, -1.0, [
				".ggg.",
				"gc" + luz + "cg",
				"gcccg",
				".ggg.",
			], {"g": Color(0.5, 0.54, 0.6), "c": Color(0.45, 0.8, 1.0), "w": Color(0.9, 1.0, 1.0)}, f)
		Pecas.Tipo.ELMO_ALADO:
			# elmo prateado com duas asinhas brancas, uma de cada lado
			RoupaGato.sprite(c, -7.5, -6.0, [
				"w.w.....w.w",
				"wwWw...wWww",
				"owwWwo.owwo",
				".owwWooooo.",
				"...osssssso",
				"...osSsssso",
				"...osssssso",
				"...ooooooo.",
			], {"o": Color(0.3, 0.34, 0.45), "s": Color(0.6, 0.66, 0.76), "S": Color(0.9, 0.94, 1.0),
				"w": Color(0.97, 0.97, 1.0), "W": Color(0.7, 0.78, 0.9)}, f)
		Pecas.Tipo.CAPA_RUBRA:
			# capa vermelha presa aos ombros por discos prateados; não passa do tronco
			RoupaGato.sprite(c, -8.0, -4.0, [
				"..ooooooooo",
				".orrrrrrSSo",
				"orRrrrrrSSo",
				"orrrrrrrrro",
				"orrrrrrrrro",
				"orrrRrrrro.",
				".orrrrrro..",
				"..oooooo...",
			], {"o": Color(0.4, 0.04, 0.08), "r": Color(0.8, 0.1, 0.14), "R": Color(1.0, 0.5, 0.5), "S": Color(0.85, 0.88, 0.94)}, f)
		Pecas.Tipo.MARTELO:
			# martelo de cabeça retangular cinza e cabo curto
			RoupaGato.sprite(c, -2.0, -10.0, [
				"....oooooooo",
				"....oGGgggdo",
				"....oggyyggo",
				"....ogggdddo",
				"....oooooooo",
				".....mo.....",
				"....mo......",
				"...mo.......",
				"..mo........",
				".mo.........",
			], {"o": Color(0.2, 0.22, 0.28), "g": Color(0.58, 0.62, 0.68), "G": Color(0.85, 0.9, 0.95),
				"d": Color(0.4, 0.43, 0.5), "y": Color(1.0, 0.95, 0.4) if sin(anim * 9.0) > 0.0 else Color(1.0, 0.8, 0.25),
				"m": Color(0.5, 0.3, 0.16)}, f)
		Pecas.Tipo.CINTURAO:
			# faixa em volta do tronco com a fivela dourada
			RoupaGato.sprite(c, -2.5, -3.0, [
				"ooooo",
				"obbbo",
				"ogGgo",
				"ogygo",
				"obbbo",
				"ooooo",
			], {"o": Color(0.3, 0.12, 0.05), "b": Color(0.6, 0.25, 0.1), "g": _OURO, "G": Color(1.0, 0.95, 0.6), "y": Color(0.75, 0.5, 0.1)}, f)
		Pecas.Tipo.TIARA:
			# tiara de gelo e trança loira curta e fina caída atrás da cabeça, com laço azul
			RoupaGato.sprite(c, -6.5, -4.0, [
				".....w.w.w.",
				"....owowowo",
				"....oiiiiio",
				"..yyoooooo.",
				"..yYyy.....",
				"..nyYn.....",
				"..nYyn.....",
				"..nyYn.....",
				"..nbbn.....",
				"...nn......",
			], {"o": _GELO_ESC, "i": Color(0.62, 0.86, 1.0), "w": Color(0.9, 0.98, 1.0),
				"y": Color(1.0, 0.85, 0.35), "Y": Color(1.0, 0.95, 0.6), "n": Color(0.72, 0.5, 0.12), "b": Color(0.3, 0.55, 1.0)}, f)
		Pecas.Tipo.VESTIDO:
			# vestido de gelo justo: 6 linhas, 11 de largura
			RoupaGato.sprite(c, -5.5, -3.0, [
				"..ooooooo..",
				".obBbbbbbo.",
				"obbbbbbwwbo",
				"obbWbbbbbbo",
				"obbbbbbbbbo",
				"ooooooooooo",
			], {"o": _GELO_ESC, "b": Color(0.55, 0.8, 0.97), "B": Color(0.85, 0.96, 1.0),
				"W": Color(0.9, 0.98, 1.0), "w": Color(0.97, 1.0, 1.0)}, f)
		Pecas.Tipo.CETRO_GELO:
			RoupaGato.sprite(c, -3.0, -11.0, [
				"......i.w.i",
				".......iwi.",
				"......wwWww",
				".......iwi.",
				"......i.w.i",
				"........m..",
				".......m...",
				"......m....",
				".....m.....",
				"....m......",
				"...m.......",
			], {"i": Color(0.55, 0.82, 1.0), "w": Color(0.85, 0.96, 1.0), "W": Color(1, 1, 1),
				"m": Color(0.45, 0.65, 0.9)}, f)
		Pecas.Tipo.FLOCO:
			RoupaGato.sprite(c, -2.5, -2.0, [
				"i.w.i",
				".iwi.",
				"wwWww",
				".iwi.",
				"i.w.i",
			], {"i": Color(0.55, 0.82, 1.0), "w": Color(0.85, 0.96, 1.0), "W": Color(1, 1, 1)}, f)
		Pecas.Tipo.CAPACETE_BOLHA:
			# cúpula de vidro sobre capuz roxo: só contorno e brilho; o olho e o rosto do bicho aparecem por dentro
			RoupaGato.sprite(c, -5.5, -2.0, [
				"...ooooo...",
				"..oghhggo..",
				".ogPPPPPgo.",
				"ogPP.....go",
				"ohP......go",
				"ogP......go",
				"og.......go",
				".og.....go.",
				"occccccccco",
				".ooooooooo.",
			], {"o": Color(0.25, 0.42, 0.62), "g": Color(0.7, 0.92, 1.0), "h": Color(1, 1, 1), "c": Color(0.75, 0.8, 0.88), "P": Color(0.52, 0.28, 0.78)}, f)
		Pecas.Tipo.TRAJE:
			# traje branco com peito verde-limão e três botões (vermelho, verde, azul) (6 linhas, 11 de largura)
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"owWwLLLLwwo",
				"owwLrgbLwwo",
				"owwLLLLLwwo",
				"ossssssssso",
				".ooooooooo.",
			], {"o": Color(0.3, 0.33, 0.48), "w": Color(0.96, 0.96, 1.0), "W": Color(1, 1, 1),
				"s": Color(0.78, 0.82, 0.92), "r": Color(0.95, 0.15, 0.2), "g": Color(0.15, 0.8, 0.3),
				"b": Color(0.3, 0.5, 0.95), "L": Color(0.62, 0.95, 0.2)}, f)
		Pecas.Tipo.LASER:
			var ponta := Color(1.0, 0.25, 0.25) if sin(anim * 6.0) > 0.0 else Color(1.0, 0.6, 0.55)
			RoupaGato.sprite(c, -1.0, -3.0, [
				"...ooooooo.",
				"..owwwwwrro",
				"..ogggggoo.",
				".ooggo.....",
				".ogo.......",
				"..o........",
			], {"o": Color(0.3, 0.33, 0.45), "w": Color(0.94, 0.96, 1.0), "g": Color(0.7, 0.74, 0.85),
				"r": ponta}, f)
		Pecas.Tipo.JATO:
			# mochila a jato na anca, com asinhas listradas e chama para trás
			RoupaGato.sprite(c, -4.0, -2.0, [
				"....ooooooo",
				"....owWwwro",
				"....ogggggo",
				"....ooooooo",
			], {"o": Color(0.35, 0.38, 0.5), "w": Color(0.94, 0.96, 1.0), "W": Color(1, 1, 1),
				"g": Color(0.7, 0.74, 0.85), "r": Color(0.9, 0.25, 0.25)}, f)
			RoupaGato.sprite(c, 0.0, -5.0, [
				"rrrr....",
				"wwwwr...",
				"ggggwr..",
				"ooooooo.",
			], {"o": Color(0.35, 0.38, 0.5), "w": Color(0.96, 0.96, 1.0), "r": Color(0.9, 0.2, 0.25), "g": Color(0.2, 0.75, 0.3)}, f)
			var n: int = 3 if sin(anim * 14.0) > 0.0 else 2
			RoupaGato.r(c, -4.0 - n, -1.0, n, 2.0, Color(1.0, 0.55, 0.15), f)
			RoupaGato.r(c, -4.0 - n + 1.0, -0.5, n - 1.0, 1.0, Color(1.0, 0.92, 0.4), f)
		_:
			RoupaGato.r(c, -2, -2, 4, 4, Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[tipo]], f)
