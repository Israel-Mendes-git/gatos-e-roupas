class_name RoupaGatoC
extends RefCounted
## Roupas do gato em pixel art, tipos 42 a 62 (ver RoupaGato para as convenções).

## Lugar do acessório no gato (RoupaGato.Onde); -1 = traseira. Só é consultado para acessórios.
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.CINTO:
			return RoupaGato.Onde.CORPO
		Pecas.Tipo.CRISTAL, Pecas.Tipo.OCARINA:
			return RoupaGato.Onde.PESCOCO
		Pecas.Tipo.RESPIRADOR:
			return RoupaGato.Onde.ROSTO
	return -1

## Lâmina diagonal de energia (sabres): do cabo em (0, 0) para frente e para cima.
static func _lamina(c: CanvasItem, ini: int, fim: int, halo: Color, miolo: Color, f: float) -> void:
	for i in range(ini, fim):
		var y: int = -int(round(i * 0.8)) - 1
		RoupaGato.r(c, i, y - 1, 1, 1, halo, f)
		RoupaGato.r(c, i, y + 1, 1, 1, halo, f)
		RoupaGato.r(c, i, y, 1, 1, miolo, f)
	var yp: int = -int(round(fim * 0.8)) - 1
	RoupaGato.r(c, fim, yp, 1, 1, halo, f)

## Desenha a peça em torno da origem do lugar onde fica presa (1 unidade = 1 pixel do gato).
static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	match tipo:
		Pecas.Tipo.BUMERANGUE:
			# batarangue: asa de morcego segurada pela ponta de baixo, na boca
			RoupaGato.sprite(c, -4.0, -5.0, [
				"oo.....oo",
				"ogo.o.ogo",
				"ogkgggkgo",
				".ogkkkgo.",
				"..ogkgo..",
				"...ooo...",
			], {"o": Color(0.07, 0.07, 0.1), "k": Color(0.32, 0.33, 0.42), "g": Color(0.6, 0.62, 0.74)}, f)
		Pecas.Tipo.CINTO:
			# cinto de utilidades: faixa amarela com fivela e bolsinhas, só no tronco
			RoupaGato.sprite(c, -2.5, -3.0, [
				"ooooo",
				"oYYYo",
				"oyfyo",
				"oyyyo",
				"oGoGo",
				"ooooo",
			], {"o": Color(0.3, 0.2, 0.02), "y": Color(1.0, 0.82, 0.12), "Y": Color(1.0, 0.95, 0.5), "f": Color(0.55, 0.4, 0.08), "G": Color(0.8, 0.6, 0.08)}, f)
		Pecas.Tipo.MASCARA_TEIA:
			# máscara vermelha com linhas de teia pretas e lente branca grande de contorno preto; focinho de fora
			RoupaGato.sprite(c, -4.5, -1.0, [
				"..ooooo..",
				".orrkrro.",
				"orrkrkrro",
				"orrkOOOOO",
				"orrrOwwwO",
				"orkrOwwwO",
				"orrkOOOOO",
				".oro.....",
			], {"o": Color(0.4, 0.04, 0.06), "r": Color(0.88, 0.12, 0.14), "k": Color(0.07, 0.05, 0.08), "O": Color(0.05, 0.05, 0.08), "w": Color(1, 1, 1)}, f)
		Pecas.Tipo.COLANTE:
			# colante vermelho com laterais azuis e uma aranha preta no centro (6 linhas, 11 de largura)
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"obbrkrkrbbo",
				"obbkkkkkbbo",
				"obbrkkkrbbo",
				"obbkrkrkbbo",
				".ooooooooo.",
			], {"o": Color(0.4, 0.04, 0.06), "r": Color(0.88, 0.12, 0.14), "k": Color(0.06, 0.05, 0.08), "b": Color(0.17, 0.28, 0.72)}, f)
		Pecas.Tipo.LANCA_TEIA:
			# lançador de teia no pulso e fio de teia branco com uma teia pequena na ponta
			RoupaGato.sprite(c, -1.0, -9.0, [
				"........w.w.w",
				".........www.",
				"........w.w.w",
				".......w.....",
				"......w......",
				".....w.......",
				"..ooow.......",
				".orgro.......",
				"..ooo........",
			], {"o": Color(0.1, 0.1, 0.16), "g": Color(0.55, 0.58, 0.68), "r": Color(0.9, 0.12, 0.14), "w": Color(0.97, 0.98, 1.0)}, f)
		Pecas.Tipo.ARANHA_PET:
			RoupaGato.sprite(c, -3.5, -6.0, [
				"o.ooo.o",
				".okkko.",
				"ookrkoo",
				"o.okko.",
				"...o.o.",
			], {"o": Color(0.05, 0.05, 0.08), "k": Color(0.2, 0.2, 0.26), "r": Color(0.9, 0.15, 0.15)}, f)
		Pecas.Tipo.CAPUZ_ESTELAR:
			# capuz de monge bege com ponta caída para trás e forro marrom na borda do rosto; olho, focinho e queixo de fora
			RoupaGato.sprite(c, -4.5, -2.0, [
				"...oooo..",
				"..ottTto.",
				".ottttddo",
				"ottttttdo",
				"ottttdd.o",
				"otttd....",
				".ootd....",
				"..oo.....",
			], {"o": Color(0.3, 0.2, 0.1), "t": Color(0.86, 0.74, 0.52), "T": Color(0.96, 0.9, 0.72), "d": Color(0.55, 0.38, 0.22)}, f)
		Pecas.Tipo.TUNICA:
			# túnica bege cruzada no peito (lapelas marrons em V), faixa de couro na cintura (6 linhas, 11 de largura)
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"odtttttttdo",
				"otdtTtttdto",
				"ottdtttdtto",
				"oBBBBBBBBBo",
				".ooooooooo.",
			], {"o": Color(0.3, 0.2, 0.1), "t": Color(0.86, 0.74, 0.52), "T": Color(0.96, 0.9, 0.72), "d": Color(0.55, 0.38, 0.22), "B": Color(0.42, 0.26, 0.12)}, f)
		Pecas.Tipo.SABRE_LUZ:
			RoupaGato.sprite(c, -1.0, -3.0, [
				"..m",
				".ms",
				"mso",
				"oo.",
			], {"o": Color(0.15, 0.15, 0.2), "m": Color(0.55, 0.58, 0.66), "s": Color(0.8, 0.82, 0.9)}, f)
			_lamina(c, 2, 11, Color(0.2, 0.55, 1.0), Color(0.85, 0.95, 1.0), f)
			if int(anim * 6.0) % 2 == 0:
				RoupaGato.r(c, 8, -8, 1, 1, Color(1, 1, 1), f)
		Pecas.Tipo.CRISTAL:
			# cristal azul facetado pendurado no pescoço
			RoupaGato.sprite(c, -2.5, -1.0, [
				"..o..",
				".obo.",
				"obBbo",
				"obBBo",
				".obbo",
				"..oo.",
			], {"o": Color(0.1, 0.25, 0.55), "b": Color(0.35, 0.75, 1.0), "B": Color(0.9, 0.98, 1.0)}, f)
			if int(anim * 3.0) % 2 == 0:
				RoupaGato.r(c, 3, -2, 1, 1, Color(1, 1, 1), f)
		Pecas.Tipo.ELMO_SOMBRIO:
			# elmo preto brilhante em forma de sino, descendo até a nuca; "olhos" redondos escuros e máscara
			RoupaGato.sprite(c, -5.5, -3.0, [
				"...ooooo...",
				"..okKKkko..",
				".okKkkkkko.",
				"okKkkkkkkko",
				"okkkkkkkkko",
				"okkkkkooooo",
				"okkkkko..ok",
				"okkkkkooook",
				".okkkkkkkko",
				".okkko.....",
				"..ooo......",
			], {"o": Color(0.02, 0.02, 0.04), "k": Color(0.11, 0.11, 0.16), "K": Color(0.5, 0.52, 0.64)}, f)
		Pecas.Tipo.ARMADURA_SOMBRIA:
			# peitoral preto com painel de botões coloridos (vermelho, verde, azul); beira clara para não sumir (6 linhas, 11 de largura)
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"okKkkkkkkko",
				"okkpppppkko",
				"okkrgbppkko",
				"okKpppppkko",
				".ooooooooo.",
			], {"o": Color(0.02, 0.02, 0.04), "k": Color(0.13, 0.13, 0.19), "K": Color(0.5, 0.52, 0.64), "p": Color(0.42, 0.43, 0.5), "r": Color(0.95, 0.15, 0.15), "g": Color(0.2, 0.9, 0.3), "b": Color(0.3, 0.5, 1.0)}, f)
		Pecas.Tipo.SABRE_RUBRO:
			RoupaGato.sprite(c, -1.0, -3.0, [
				"..m",
				".ms",
				"mso",
				"oo.",
			], {"o": Color(0.1, 0.1, 0.12), "m": Color(0.35, 0.35, 0.4), "s": Color(0.6, 0.6, 0.66)}, f)
			_lamina(c, 2, 11, Color(0.8, 0.05, 0.08), Color(1.0, 0.8, 0.7), f)
			# guarda cruzada
			RoupaGato.r(c, 2, -2, 1, 1, Color(0.8, 0.05, 0.08), f)
			RoupaGato.r(c, 3, -5, 1, 1, Color(0.8, 0.05, 0.08), f)
			if int(anim * 6.0) % 2 == 0:
				RoupaGato.r(c, 8, -8, 1, 1, Color(1, 0.9, 0.85), f)
		Pecas.Tipo.RESPIRADOR:
			# grade triangular do respirador sobre o focinho
			RoupaGato.sprite(c, 0.5, 0.5, [
				"ooooo.",
				"ogwgwo",
				".ogwgo",
				"..ogo.",
				"...o..",
			], {"o": Color(0.03, 0.03, 0.05), "g": Color(0.42, 0.44, 0.52), "w": Color(0.85, 0.87, 0.95)}, f)
		Pecas.Tipo.GORRO:
			# gorro verde comprido e pontudo, caído para trás, com franja loira na testa
			RoupaGato.sprite(c, -8.5, -5.0, [
				"....ooooo....",
				"...ogGggggo..",
				"..ogGgggggggo",
				".oggggggggggo",
				"ogggggggggggo",
				"oggggggdddddo",
				"ogo......yyyy",
				"ogo.......yy.",
				"oo...........",
			], {"o": Color(0.06, 0.25, 0.1), "g": Color(0.2, 0.62, 0.22), "G": Color(0.45, 0.85, 0.45), "d": Color(0.12, 0.42, 0.16), "y": Color(0.95, 0.8, 0.3)}, f)
		Pecas.Tipo.TUNICA_VERDE:
			# túnica verde justa: 6 linhas, 11 de largura
			RoupaGato.sprite(c, -5.5, -3.0, [
				".ooooooooo.",
				"ogggGgggggo",
				"obbbbyybbbo",
				"ogggggggGgo",
				"ogGgggggggo",
				".ooooooooo.",
			], {"o": Color(0.08, 0.3, 0.1), "g": Color(0.2, 0.62, 0.22), "G": Color(0.45, 0.85, 0.45), "b": Color(0.45, 0.27, 0.1), "y": Color(1.0, 0.85, 0.25)}, f)
		Pecas.Tipo.ESPADA_LENDARIA:
			RoupaGato.sprite(c, -1.0, -3.0, [
				"..m",
				".ms",
				"mso",
				"oo.",
			], {"o": Color(0.1, 0.15, 0.4), "m": Color(0.2, 0.4, 0.9), "s": Color(0.9, 0.8, 0.3)}, f)
			# lâmina de 4 pixels de espessura: contorno, tom médio e brilho
			for i in range(2, 12):
				var y: int = -int(round(i * 0.8))
				RoupaGato.r(c, i, y - 2, 1, 1, Color(0.2, 0.28, 0.5), f)
				RoupaGato.r(c, i, y - 1, 1, 1, Color(0.55, 0.65, 0.8), f)
				RoupaGato.r(c, i, y, 1, 1, Color(0.9, 0.95, 1.0), f)
				RoupaGato.r(c, i, y + 1, 1, 1, Color(0.2, 0.28, 0.5), f)
			RoupaGato.r(c, 12, -10, 1, 1, Color(0.55, 0.65, 0.8), f)
			# guarda azul-arroxeada em asa, com gema amarela
			var gw := Color(0.42, 0.3, 0.95)
			RoupaGato.r(c, 1, 0, 1, 1, gw, f)
			RoupaGato.r(c, 2, -1, 1, 1, gw, f)
			RoupaGato.r(c, 3, -4, 1, 1, gw, f)
			RoupaGato.r(c, 3, -5, 1, 1, gw, f)
			RoupaGato.r(c, 4, -6, 1, 1, gw, f)
			RoupaGato.r(c, 3, -3, 1, 1, Color(1.0, 0.9, 0.2), f)
			if int(anim * 4.0) % 2 == 0:
				RoupaGato.r(c, 9, -9, 1, 1, Color(1, 1, 1), f)
		Pecas.Tipo.OCARINA:
			RoupaGato.sprite(c, -3.0, -1.0, [
				".oooo..",
				"obbBbbo",
				"obdbdbo",
				".obbbo.",
				"..ooo..",
			], {"o": Color(0.08, 0.15, 0.4), "b": Color(0.25, 0.5, 0.92), "B": Color(0.7, 0.85, 1.0), "d": Color(0.08, 0.15, 0.4)}, f)
		Pecas.Tipo.BANDANA:
			# faixa ninja numa cor só, na testa, cobrindo o olho (que aparece branco); duas pontas soltas atrás
			var sw: int = int(round(sin(anim * 4.0)))
			RoupaGato.sprite(c, -4.5, 2.0, [
				"oaaaAaaao",
				"oaaaawwka",
				"ooooooooo",
			], {"o": Color("2e1206"), "a": Color("e8873a"), "A": Color("f8be80"), "w": Color(1, 1, 1), "k": Color(0.08, 0.06, 0.06)}, f)
			RoupaGato.sprite(c, -6.5, 3.0 + sw, [
				"oaao",
				"ooao",
			], {"o": Color("2e1206"), "a": Color("e8873a")}, f)
			RoupaGato.sprite(c, -7.5, 4.0 - sw, [
				"oaao",
				".oo.",
			], {"o": Color("2e1206"), "a": Color("a9531e")}, f)
		Pecas.Tipo.CASCO:
			# casco do kit Tartaruga (o mesmo das outras três, com o M na fivela): ver RoupaGatoH
			for cm in RoupaGatoH.casco_miau():
				RoupaGato.sprite(c, cm[0], cm[1], cm[2], cm[3], f)
		Pecas.Tipo.NUNCHAKU:
			var sw: int = int(round(sin(anim * 4.0)))
			var cb := {"o": Color("1e1008"), "m": Color(0.62, 0.38, 0.16), "M": Color(0.85, 0.6, 0.35), "c": Color(0.75, 0.77, 0.82)}
			# um bastão reto preso na boca, apontando para a frente (o cabo passa pela ponta do focinho)
			RoupaGato.sprite(c, -1.0, -4.0, [
				"ooooooo",
				"oMMmmmo",
				"ooooooo",
			], cb, f)
			# corrente curta e o segundo bastão pendurado, balançando: forma um L, não um estilingue
			# corrente grossa (2 de largura, elos claros e escuros alternados) ligando os dois bastões
			var elo := Color(0.96, 0.97, 1.0)
			RoupaGato.r(c, 5, -1, 1, 1, elo, f)
			RoupaGato.r(c, 6, -1, 1, 1, cb["o"], f)
			RoupaGato.r(c, 5 + sw, 0, 1, 1, cb["o"], f)
			RoupaGato.r(c, 6 + sw, 0, 1, 1, elo, f)
			RoupaGato.sprite(c, 4.0 + sw, 1.0, [
				"ooo",
				"oMo",
				"omo",
				"omo",
				"ooo",
			], cb, f)
		_:
			RoupaGato.r(c, -2, -2, 4, 4, Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[tipo]], f)
