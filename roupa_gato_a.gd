class_name RoupaGatoA
extends RefCounted
## Roupas do gato em pixel art, tipos 0 a 20 (ver RoupaGato para as convenções).

## Lugar do acessório no gato (RoupaGato.Onde); -1 = traseira. Só é consultado para acessórios.
static func onde(tipo: int) -> int:
	return -1

## Desenha a peça em torno da origem do lugar onde fica presa (1 unidade = 1 pixel do gato).
static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	match tipo:
		Pecas.Tipo.CAPACETE:
			# EXEMPLO de cabeça: origem no topo do crânio; a cabeça ocupa x de -4.5 a 4.5 e y de 0 a 6
			RoupaGato.sprite(c, -4.5, -3.0, [
				"..ooooo..",
				".oaaaaao.",
				"oaaabaaao",
				"oaaabaaao",
				"ooooooooo",
			], {"o": Color(0.2, 0.23, 0.3), "a": Color(0.62, 0.68, 0.78), "b": Color(0.88, 0.92, 1.0)}, f)
		Pecas.Tipo.COLETE:
			# colete justo: 6 linhas e 10 de largura, só peito e meio do tronco (anca e pernas à mostra)
			RoupaGato.sprite(c, -5.5, -3.0, [
				".oooooooo.",
				"ogggggggGo",
				"oggygggygo",
				"ogggggggGo",
				"oGGGGGGGGo",
				".oooooooo.",
			], {"o": Color(0.16, 0.2, 0.32), "g": Color(0.55, 0.64, 0.8), "G": Color(0.4, 0.5, 0.68), "y": Color(1.0, 0.85, 0.3)}, f)
		Pecas.Tipo.LANCA:
			# EXEMPLO de mão: o gato leva a arma na boca; origem na ponta do focinho, a arma aponta para a frente e para cima
			RoupaGato.sprite(c, -4.0, -9.0, [
				"...........s",
				"..........ss",
				".........rs.",
				"........mr..",
				".......m....",
				"......m.....",
				".....m......",
				"....m.......",
				"...m........",
				"..m.........",
				".m..........",
			], {"m": Color(0.6, 0.4, 0.2), "s": Color(0.85, 0.9, 1.0), "r": Color(0.85, 0.2, 0.2)}, f)
		Pecas.Tipo.PORRETE:
			RoupaGato.sprite(c, -3.0, -8.0, [
				"......ooo..",
				".....obbbo.",
				"....obBbbbo",
				"....obbbBbo",
				".....obbbo.",
				"....om.oo..",
				"...om......",
				"..om.......",
				".om........",
			], {"o": Color(0.2, 0.12, 0.06), "b": Color(0.55, 0.36, 0.2), "B": Color(0.85, 0.75, 0.55), "m": Color(0.45, 0.28, 0.14)}, f)
		Pecas.Tipo.ESTILINGUE:
			RoupaGato.sprite(c, -3.0, -9.0, [
				"m.....m",
				"mm...mm",
				"mrm.mrm",
				".mrrrm.",
				"..mgm..",
				"..mgm..",
				"...m...",
				"...m...",
				"...m...",
				"...m...",
			], {"m": Color(0.62, 0.4, 0.18), "r": Color(0.85, 0.15, 0.15), "g": Color(0.6, 0.62, 0.66)}, f)
		Pecas.Tipo.ESCUDO:
			# escudo levado na boca, à frente do focinho, sem tapar o rosto
			RoupaGato.sprite(c, -1.0, -4.0, [
				".oooo.",
				"oSbbSo",
				"oSyySo",
				"oSyybo",
				"obbbbo",
				".oooo.",
			], {"o": Color(0.07, 0.24, 0.17), "b": Color(0.3, 0.66, 0.48), "S": Color(0.82, 0.86, 0.93), "y": Color(1.0, 0.85, 0.3)}, f)
		Pecas.Tipo.CAPA:
			var o1: String = "ooRRRRRo..." if int(anim * 3.0) % 2 == 0 else "..ooRRRRRo."
			RoupaGato.sprite(c, -11.0, -4.0, [
				"....oooooyo",
				"..ooRRRRRRo",
				".oRRRRRdRRo",
				"oRRRRRdRRRo",
				"oRRRdRRRRo.",
				"oRRdRRRRo..",
				o1,
				"..oooooo...",
			], {"o": Color(0.4, 0.04, 0.1), "R": Color(0.85, 0.15, 0.22), "d": Color(0.6, 0.08, 0.16), "y": Color(1.0, 0.85, 0.3)}, f)
		Pecas.Tipo.ESPINHOS:
			# couraça de espinhos: 6 linhas no tronco e três pontas de aço no dorso
			RoupaGato.sprite(c, -5.5, -4.0, [
				"..s..s..s..",
				".ooooooooo.",
				"obbbbbbbbbo",
				"obBbbbbbBbo",
				"obbbbbbbbbo",
				"obBbbbbbBbo",
				".ooooooooo.",
			], {"o": Color(0.06, 0.2, 0.15), "b": Color(0.2, 0.42, 0.33), "B": Color(0.35, 0.6, 0.48), "s": Color(0.86, 0.88, 0.92)}, f)
		Pecas.Tipo.CHAPEU:
			# chapéu de palha: copa baixa e aba de 11, encostado no crânio
			RoupaGato.sprite(c, -5.5, -5.0, [
				"...ooooo...",
				"..oyyYyyo..",
				"..orrrrro..",
				".ooyyyyyoo.",
				"oyYyyyyyyyo",
				".ooooooooo.",
			], {"o": Color(0.5, 0.36, 0.1), "y": Color(0.97, 0.84, 0.4), "Y": Color(1.0, 0.95, 0.7), "r": Color(0.8, 0.2, 0.2)}, f)
		Pecas.Tipo.MASCARA:
			# máscara roxa: cobre o crânio e deixa o olho e o focinho de fora
			RoupaGato.sprite(c, -4.5, -1.0, [
				"...oooo..",
				"..opgppo.",
				".oppgdppo",
				"oppppwwpo",
				"oppdpwkpo",
				"opppo....",
				".ooo.....",
			], {"o": Color(0.07, 0.24, 0.17), "p": Color(0.3, 0.66, 0.48), "d": Color(0.2, 0.48, 0.35), "g": Color(1.0, 0.85, 0.3), "w": Color(1, 1, 1), "k": Color(0.1, 0.05, 0.15)}, f)
		Pecas.Tipo.TOCHA:
			var ch: String = "...r..." if int(anim * 5.0) % 2 == 0 else "....r.."
			RoupaGato.sprite(c, -1.0, -11.0, [
				ch,
				"..rfr..",
				".rfyfr.",
				".rfyfr.",
				"..rfr..",
				"..kkk..",
				"...m...",
				"...m...",
				"..m....",
				"..m....",
				".m.....",
				".m.....",
			], {"r": Color(0.9, 0.25, 0.05), "f": Color(1.0, 0.5, 0.1), "y": Color(1.0, 0.9, 0.3), "k": Color(0.2, 0.12, 0.08), "m": Color(0.55, 0.36, 0.18)}, f)
		Pecas.Tipo.AVENTAL:
			# avental: faixa verde na cintura, peitilho branco com bolso, só no tronco
			RoupaGato.sprite(c, -4.5, -3.0, [
				"ggggggggg",
				".owwwwwo.",
				".owhhhwo.",
				".owwwwwo.",
				"..owwwo..",
				"...ooo...",
			], {"o": Color(0.45, 0.45, 0.5), "w": Color(0.96, 0.95, 0.9), "h": Color(0.78, 0.78, 0.74), "g": Color(0.15, 0.7, 0.32)}, f)
		Pecas.Tipo.BARRIL:
			var fu: Color = Color(1.0, 0.8, 0.2) if int(anim * 6.0) % 2 == 0 else Color(1.0, 0.45, 0.1)
			RoupaGato.sprite(c, -4.0, -4.0, [
				"....y...",
				".oooooo.",
				"okkkkkko",
				"obBbbbbo",
				"obbrrbbo",
				"okkkkkko",
				".oooooo.",
			], {"o": Color(0.45, 0.08, 0.12), "b": Color(0.9, 0.3, 0.28), "B": Color(1.0, 0.6, 0.55), "k": Color(1.0, 0.82, 0.25), "r": Color(1, 1, 1), "y": fu}, f)
		Pecas.Tipo.COROA:
			RoupaGato.sprite(c, -3.5, -4.0, [
				"o.o.o.o",
				"yyoyoyy",
				"yyyyyyy",
				"yyyryyy",
				"ddddddd",
			], {"o": Color(0.55, 0.35, 0.03), "y": Color(1.0, 0.8, 0.15), "d": Color(0.6, 0.4, 0.05), "r": Color(0.9, 0.1, 0.2)}, f)
		Pecas.Tipo.CHIFRES:
			RoupaGato.sprite(c, -4.5, -6.0, [
				"ow.....wo",
				"owo...owo",
				".ow...wo.",
				".owo.owo.",
				".owo.owo.",
				"rrrrrrrrr",
			], {"o": Color(0.3, 0.18, 0.1), "w": Color(0.95, 0.9, 0.75), "r": Color(0.5, 0.3, 0.15)}, f)
		Pecas.Tipo.CETRO:
			var br: String = "..oyYo.." if int(anim * 3.0) % 2 == 0 else "..oyyo.."
			RoupaGato.sprite(c, -3.0, -11.0, [
				"...ooo..",
				"..oyyyo.",
				br.replace("Y", "y"),
				"..oyyyo.",
				"...ooo..",
				"....d...",
				"....d...",
				"...d....",
				"...d....",
				"...d....",
				"...d....",
				"...d....",
			], {"o": Color(0.4, 0.24, 0.05), "y": Color(1.0, 0.82, 0.25), "d": Color(0.85, 0.65, 0.15)}, f)
			RoupaGato.r(c, 0.0, -9.0, 2.0, 1.0, Color(0.9, 0.1, 0.2), f)
		Pecas.Tipo.REGADOR:
			var gota: String = "........w." if int(anim * 4.0) % 2 == 0 else ".........."
			RoupaGato.sprite(c, -1.0, -5.0, [
				"........sS",
				".ooooo.os.",
				"oGggggdo..",
				"o.gggdos..",
				".odddddo..",
				"..ooooo...",
			], {"o": Color(0.15, 0.3, 0.1), "g": Color(0.4, 0.74, 0.3), "G": Color(0.62, 0.86, 0.5), "d": Color(0.28, 0.55, 0.2), "s": Color(0.72, 0.8, 0.72), "S": Color(0.9, 0.95, 0.9), "w": Color(0.5, 0.8, 1.0)}, f)
			RoupaGato.sprite(c, 7.0, -7.0, [gota], {"w": Color(0.5, 0.8, 1.0)}, f)
		Pecas.Tipo.SABRE:
			RoupaGato.sprite(c, -1.0, -12.0, [
				"...........w",
				".........owS",
				"........owS.",
				".......owS..",
				"......owS...",
				".....owS....",
				"....owS.....",
				"...owS......",
				"..owS.......",
				".owS........",
				"gggg........",
				".m..........",
				".p..........",
			], {"w": Color(0.92, 0.95, 1.0), "S": Color(0.5, 0.58, 0.72), "o": Color(0.25, 0.3, 0.4), "g": Color(0.95, 0.75, 0.2), "m": Color(0.3, 0.17, 0.08), "p": Color(0.95, 0.75, 0.2)}, f)
		Pecas.Tipo.VARINHA:
			var fa: bool = int(anim * 4.0) % 2 == 0
			RoupaGato.sprite(c, -1.0, -11.0, [
				"....y...",
				"...yyy..",
				"..yyYyy.",
				"...yyy..",
				"..y.y...",
				"...p....",
				"...p....",
				"..p.....",
				"..y.....",
				".p......",
				".p......",
				".p......",
			], {"y": Color(1.0, 0.85, 0.3), "Y": Color(1, 1, 1), "p": Color(0.38, 0.22, 0.55)}, f)
			if fa:
				RoupaGato.r(c, -1.0, -10.0, 1.0, 1.0, Color(1, 0.95, 0.6), f)
			else:
				RoupaGato.r(c, 6.0, -8.0, 1.0, 1.0, Color(1, 0.95, 0.6), f)
		Pecas.Tipo.CARTOLA:
			RoupaGato.sprite(c, -4.5, -6.0, [
				".ooooooo.",
				".orrRrro.",
				".orrrrro.",
				".oyyyyyo.",
				"orrrrrrro",
				"ooooooooo",
			], {"o": Color(0.45, 0.08, 0.12), "r": Color(0.88, 0.2, 0.25), "R": Color(1.0, 0.5, 0.5), "y": Color(1.0, 0.85, 0.25)}, f)
		Pecas.Tipo.CAUBOI:
			RoupaGato.sprite(c, -5.5, -5.0, [
				"..ooo.ooo..",
				"..obbobbo..",
				"..obbbbbo..",
				"..orrrrro..",
				"obbBbbbBbbo",
				".ooooooooo.",
			], {"o": Color(0.4, 0.24, 0.1), "b": Color(0.8, 0.54, 0.26), "B": Color(0.92, 0.7, 0.4), "r": Color(0.45, 0.15, 0.1)}, f)
		_:
			# PROVISÓRIO: bloquinho na cor da fantasia
			RoupaGato.r(c, -2, -2, 4, 4, Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[tipo]], f)
