class_name RoupaGatoB
extends RefCounted
## Roupas do gato em pixel art, tipos 21 a 41 (ver RoupaGato para as convenções).

## Lugar do acessório no gato (RoupaGato.Onde); -1 = traseira. Só é consultado para acessórios.
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.BOTAS, Pecas.Tipo.JOELHEIRAS, Pecas.Tipo.GANCHO:
			return RoupaGato.Onde.PATAS
		Pecas.Tipo.NARIZ:
			return RoupaGato.Onde.ROSTO
		Pecas.Tipo.COLAR, Pecas.Tipo.AMULETO:
			return RoupaGato.Onde.PESCOCO
		Pecas.Tipo.CANTIL:
			return RoupaGato.Onde.CORPO
	return -1

## Desenha a peça em torno da origem do lugar onde fica presa (1 unidade = 1 pixel do gato).
static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	var fase: int = int(floor(anim * 4.0)) % 2
	match tipo:
		Pecas.Tipo.TRICORNIO:
			# chapéu de pirata azul-marinho com borda dourada e caveira
			RoupaGato.sprite(c, -4.5, -5.0, [
				"...ooooo...",
				"..oaaaaao..",
				".oaawwwaao.",
				"oaaaowoaaao",
				"oyyyyyyyyyo",
				".ooooooooo.",
			], {"o": Color(0.06, 0.08, 0.16), "a": Color(0.18, 0.24, 0.42), "w": Color(0.95, 0.95, 0.88), "y": Color(0.92, 0.76, 0.25)}, f)
		Pecas.Tipo.PONTUDO:
			# chapéu de mago roxo, ponta caída para trás, faixa dourada e estrela
			RoupaGato.sprite(c, -4.5, -7.0, [
				"..oo.......",
				".oPPo......",
				"..oPPo.....",
				"...oPPo....",
				"...oPsPo...",
				"..oyyyyyo..",
				"odddddddddo",
				".ooooooooo.",
			], {"o": Color(0.2, 0.1, 0.35), "P": Color(0.5, 0.3, 0.82), "d": Color(0.36, 0.2, 0.62), "y": Color(1.0, 0.85, 0.3), "s": Color(1.0, 0.95, 0.6)}, f)
			if fase == 1:
				RoupaGato.r(c, -2.5, -7.0, 1, 1, Color(1.0, 0.95, 0.7), f)
		Pecas.Tipo.PELE:
			# pele de urso sobre o dorso: 11 de largura, pelos em ponta e garras claras na barra
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"oPPPPPPPPPo",
				"oPpPPPpPPPo",
				"oPPPpPPPPpo",
				"oPpPPPPpPPo",
				"opPoPPoPPpo",
				".w.w.ww.w.w",
			], {"o": Color(0.2, 0.12, 0.07), "P": Color(0.46, 0.3, 0.18), "p": Color(0.62, 0.44, 0.28), "w": Color(0.95, 0.92, 0.8)}, f)
		Pecas.Tipo.PONCHO:
			# manta laranja listrada com gola escura e franjas
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"oOOOOOOODDo",
				"oRRRRRRRRRo",
				"oOOOOOOOOOo",
				"oCCCCCCCCCo",
				"oRRRRRRRRRo",
				"ocococococo",
			], {"o": Color(0.38, 0.14, 0.08), "O": Color(0.9, 0.55, 0.25), "R": Color(0.72, 0.2, 0.15), "C": Color(0.98, 0.9, 0.7), "D": Color(0.25, 0.12, 0.08), "c": Color(0.98, 0.9, 0.7)}, f)
		Pecas.Tipo.CASACO:
			# casaco azul com lapela clara, cinto preto e botão dourado (7 linhas, 11 de largura)
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"oBBBBBBBWWo",
				"oBBBBBBBBWo",
				"okkkgkkkkko",
				"oBBBBBBBBgo",
				"oDDDDDDDDDo",
				".ooooooooo.",
			], {"o": Color(0.07, 0.12, 0.28), "B": Color(0.2, 0.34, 0.7), "D": Color(0.14, 0.24, 0.52), "W": Color(0.92, 0.9, 0.8), "k": Color(0.1, 0.08, 0.1), "g": Color(0.95, 0.78, 0.25)}, f)
		Pecas.Tipo.MANTO:
			# manto roxo que pende para trás sobre a anca, fecho dourado e estrelas
			RoupaGato.sprite(c, -10.0, -4.0, [
				"...oooooooooo",
				"..oMMMMMMMMyo",
				".oMMmMMMMMMMo",
				"oMMMMMsMMMMMo",
				"oMmMMMMMMMMo.",
				"oMMMMmMMMMo..",
				"oMsMMMMMMo...",
				"oMMmMMMMo....",
				"oMoMMoMMo....",
				".o.oo.oo.....",
			], {"o": Color(0.2, 0.1, 0.35), "M": Color(0.46, 0.26, 0.7), "m": Color(0.34, 0.18, 0.54), "y": Color(1.0, 0.82, 0.25), "s": Color(1.0, 0.92, 0.55)}, f)
		Pecas.Tipo.BOTAS:
			# uma bota de aço: quem chama desenha uma em cada pata (ver RoupaGato.Onde.PATAS)
			for bx in [-2.5]:
				RoupaGato.sprite(c, bx, -4.0, [
					"oLLLo.",
					"oaaao.",
					"oaaaao",
					"oDDDDo",
				], {"o": Color(0.15, 0.17, 0.25), "L": Color(0.78, 0.84, 0.95), "a": Color(0.5, 0.57, 0.7), "D": Color(0.22, 0.24, 0.32)}, f)
		Pecas.Tipo.JOELHEIRAS:
			# uma joelheira verde com brilho: quem chama desenha uma em cada pata
			for jx in [-2.5]:
				RoupaGato.sprite(c, jx, -5.0, [
					".ooo.",
					"obggo",
					"oggGo",
					".ooo.",
				], {"o": Color(0.1, 0.3, 0.2), "g": Color(0.35, 0.72, 0.55), "G": Color(0.24, 0.55, 0.4), "b": Color(0.75, 0.95, 0.85)}, f)
		Pecas.Tipo.BANDEIRA:
			# mastro na anca e bandeira vermelha grande com estrela, que ondula
			RoupaGato.r(c, 0.0, -12.0, 1, 13, Color(0.35, 0.22, 0.1), f)
			RoupaGato.r(c, -0.5, -14.0, 2, 2, Color(1.0, 0.82, 0.25), f)
			var bl: Array = [
				"ooooooooo",
				"orrrYrrro",
				"orrYYYrro",
				"orrrYrrro",
				"orrrrrrro",
				"ooooooooo",
			]
			var pa: Array = []
			var pb: Array = []
			for l in bl:
				pa.append(String(l).substr(0, 2))
				pb.append(String(l).substr(2))
			var pal := {"o": Color(0.4, 0.05, 0.08), "r": Color(0.86, 0.15, 0.2), "Y": Color(1.0, 0.85, 0.3)}
			RoupaGato.sprite(c, -9.0, -12.0 + fase, pa, pal, f)
			RoupaGato.sprite(c, -7.0, -12.0, pb, pal, f)
		Pecas.Tipo.NARIZ:
			# nariz de palhaço vermelha
			RoupaGato.sprite(c, -1.0, 1.0, [
				".oo.",
				"oRRo",
				"owRo",
				".oo.",
			], {"o": Color(0.4, 0.04, 0.06), "R": Color(0.95, 0.15, 0.15), "w": Color(1.0, 0.85, 0.85)}, f)
		Pecas.Tipo.COLAR:
			# cordão com dentes: dentes claros com contorno escuro, bem separados
			RoupaGato.sprite(c, -3.5, -2.0, [
				"kkkkkkk",
				"owowowo",
				"owowowo",
				".o.o.o.",
			], {"k": Color(0.3, 0.18, 0.1), "o": Color(0.22, 0.14, 0.07), "w": Color(0.98, 0.94, 0.78)}, f)
		Pecas.Tipo.SEMENTES:
			# saquinho de juta pequeno, com brotos
			RoupaGato.sprite(c, -3.0, -3.0, [
				"..g.g.",
				".oRRRo",
				"oSSSSo",
				"oSdSSo",
				"oSSdSo",
				".oooo.",
			], {"o": Color(0.35, 0.24, 0.1), "S": Color(0.78, 0.62, 0.36), "d": Color(0.4, 0.28, 0.12), "R": Color(0.8, 0.2, 0.15), "g": Color(0.4, 0.78, 0.25)}, f)
		Pecas.Tipo.CANTIL:
			# cantil de couro pendurado no flanco
			RoupaGato.sprite(c, -3.5, -2.0, [
				"..oo..",
				"..cc..",
				".oBBo.",
				"oBbBBo",
				"oBBBBo",
				".oooo.",
			], {"o": Color(0.25, 0.16, 0.08), "B": Color(0.56, 0.4, 0.22), "b": Color(0.76, 0.6, 0.4), "c": Color(0.7, 0.72, 0.78)}, f)
		Pecas.Tipo.GANCHO:
			# gancho de pirata: braçadeira de couro, argola dourada e curva de aço na pata da frente
			RoupaGato.sprite(c, -1.5, -6.0, [
				"BBB..",
				"YYY..",
				".H...",
				".H.H.",
				".HHH.",
			], {"B": Color(0.4, 0.24, 0.12), "Y": Color(0.95, 0.78, 0.25), "H": Color(0.78, 0.84, 0.95)}, f)
		Pecas.Tipo.AMULETO:
			# corrente dourada com gema roxa
			RoupaGato.sprite(c, -2.0, -1.0, [
				"y...y",
				".y.y.",
				".ooo.",
				"oPwPo",
				".ooo.",
			], {"y": Color(1.0, 0.85, 0.3), "o": Color(0.4, 0.25, 0.05), "P": Color(0.7, 0.35, 1.0), "w": Color(1, 1, 1)}, f)
		Pecas.Tipo.BONE_ENCANADOR:
			# boné vermelho com disco branco na frente e BIGODE preto grosso sobre o focinho
			RoupaGato.sprite(c, -4.5, -4.0, [
				"..ooooo....",
				".orrrrro...",
				"orrrWWWrro.",
				"orrrWWWrro.",
				"ooooooooDDo",
				"...........",
				"...........",
				".....k...k.",
				".....kkkkkk",
				"....kKkkkkk",
				".....kkkkk.",
			], {"o": Color(0.35, 0.04, 0.06), "r": Color(0.85, 0.12, 0.14), "D": Color(0.65, 0.08, 0.1), "W": Color(1, 1, 1), "k": Color(0.03, 0.02, 0.03), "K": Color(0.5, 0.4, 0.35)}, f)
		Pecas.Tipo.MACACAO:
			# macacão azul de alças sobre camisa vermelha, dois botões dourados (6 linhas, 11 de largura)
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"oRRRRRRRRRo",
				"oRRBRRRBRRo",
				"oBBgBBBgBBo",
				"oBbBBBBBBDo",
				".ooooooooo.",
			], {"o": Color(0.08, 0.14, 0.4), "R": Color(0.9, 0.15, 0.15), "B": Color(0.2, 0.36, 0.86), "b": Color(0.36, 0.52, 0.95), "D": Color(0.14, 0.26, 0.64), "g": Color(1.0, 0.85, 0.2)}, f)
		Pecas.Tipo.DESENTUPIDOR:
			# desentupidor: cabo de madeira e ventosa vermelha na ponta
			RoupaGato.sprite(c, -4.0, -9.0, [
				"........ooo.",
				".......orRRo",
				".......RRrRo",
				"......ommRo.",
				".....mmoo...",
				"....m.......",
				"...m........",
				"..m.........",
				".m..........",
			], {"m": Color(0.62, 0.4, 0.2), "o": Color(0.4, 0.04, 0.06), "R": Color(0.85, 0.13, 0.15), "r": Color(1.0, 0.6, 0.6)}, f)
		Pecas.Tipo.COGUMELO:
			# cogumelo pequeno com bolinhas
			RoupaGato.sprite(c, -2.5, -3.0, [
				".ooo.",
				"oRWRo",
				"oRRWo",
				"ooooo",
				".oSo.",
				"..o..",
			], {"o": Color(0.35, 0.05, 0.05), "R": Color(0.9, 0.16, 0.16), "W": Color(1, 1, 1), "S": Color(0.97, 0.9, 0.78)}, f)
		Pecas.Tipo.CAPUZ_MORCEGO:
			# capuz escuro com duas orelhas pontudas curtas e olhos brancos sem pupila; focinho e queixo livres
			RoupaGato.sprite(c, -4.5, -4.0, [
				"..o...o..",
				".ogo.ogo.",
				".ogggggo.",
				"ogggggggo",
				"ogggggggo",
				"ogggggggo",
				"oggggWWWo",
				"odddWWWW.",
				"oddo.....",
				".oo......",
			], {"o": Color(0.03, 0.03, 0.05), "g": Color(0.2, 0.21, 0.28), "d": Color(0.12, 0.12, 0.17), "W": Color(1, 1, 1)}, f)
		Pecas.Tipo.CAPA_MORCEGO:
			# capa preta com a barra recortada em pontas (como asa), presa por fecho dourado; não passa do tronco
			RoupaGato.sprite(c, -8.0, -3.0, [
				".oooooooooo",
				"oLLLLLLLLyo",
				"oPPPPPPPPPo",
				"oPlPPPPlPPo",
				"oPlPPPPlPo.",
				"oPPPPPPPPo.",
				"oPPoPPoPPo.",
				"oPo.oPo.oo.",
			], {"o": Color(0.03, 0.03, 0.05), "P": Color(0.15, 0.14, 0.2), "L": Color(0.3, 0.29, 0.38), "l": Color(0.22, 0.21, 0.29), "y": Color(1.0, 0.82, 0.25)}, f)
		_:
			RoupaGato.r(c, -2, -2, 4, 4, Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[tipo]], f)
