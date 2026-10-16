class_name RoupaGatoF
extends RefCounted
## Roupas do gato em pixel art, tipos 100 em diante (ver RoupaGato para as convenções): expansão das fantasias, lote 1
## (Super Miau 100-103, Arqueiro Miau 104-107, Motoqueiro Miausma 108-111, Fênix Miaussimo 112-115, Mimiau 116-119, Jimiau 120-123).
##
## FALLBACK: enquanto uma peça não tem arte própria em `_camadas`, desenha a silhueta de uma peça do mesmo espaço (cabeça, corpo,
## mão ou acessório do lado de fora, em RoupaGatoE.PECAS) tingida com a cor da fantasia.
## COMO O ARTISTA ENTRA: devolva em `_camadas` as camadas [x, y, linhas, paleta] da peça (mesmo formato de RoupaGatoE._camadas);
## `caixa` e `desenhar` já usam o que vier de lá. Descrição visual de cada peça: para_arte.md.

const PRIMEIRO := 100
const _MOLDE_FALLBACK: Array[int] = [Pecas.Tipo.CAPACETE_AZUL, Pecas.Tipo.COLETE_LISTRADO, Pecas.Tipo.KUNAI, Pecas.Tipo.TANQUE]   # por espaço

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão (cabeça, corpo, boca e traseira).
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.CAPA_VERMELHA:
			return RoupaGato.Onde.PESCOCO
		Pecas.Tipo.DISTINTIVO:
			return RoupaGato.Onde.CORPO
	return -1

# ------------------------------------------------------------------ paletas
## Super Miau: o contorno azul-noite, a/b/d azul (médio, claro, sombra), y amarelo, r/R/D vermelho (médio, claro, sombra),
## k/K cabelo preto (médio, brilho), s/S prata (claro, sombra), C contorno da capa.
const _PAL_SUPER := {
	"o": Color(0.05, 0.08, 0.25), "a": Color(0.2, 0.42, 0.95), "b": Color(0.5, 0.7, 1.0), "d": Color(0.1, 0.22, 0.68),
	"y": Color(1.0, 0.86, 0.2), "r": Color(0.86, 0.12, 0.16), "R": Color(1.0, 0.38, 0.34), "D": Color(0.6, 0.06, 0.1),
	"k": Color(0.27, 0.28, 0.42), "K": Color(0.68, 0.74, 0.98), "s": Color(0.9, 0.92, 0.98), "S": Color(0.55, 0.6, 0.74),
	"C": Color(0.36, 0.02, 0.07),
}
## Arqueiro: o verde-floresta, a/b/d verde (médio, claro, sombra), k máscara, r/R pluma, m/M madeira (médio, claro),
## t barbante, g fivela, c/n ponta de bomba e de rede, e luva de boxe, w pena.
const _PAL_ARQ := {
	"o": Color(0.05, 0.16, 0.08), "a": Color(0.2, 0.6, 0.28), "b": Color(0.5, 0.85, 0.5), "d": Color(0.1, 0.36, 0.16),
	"k": Color(0.08, 0.08, 0.1), "r": Color(0.9, 0.18, 0.18), "R": Color(1.0, 0.55, 0.45),
	"m": Color(0.55, 0.32, 0.12), "M": Color(0.82, 0.58, 0.3), "t": Color(0.97, 0.94, 0.82), "g": Color(1.0, 0.82, 0.2),
	"c": Color(0.18, 0.18, 0.22), "n": Color(0.75, 0.8, 0.85), "e": Color(0.9, 0.2, 0.2), "y": Color(1.0, 0.9, 0.3),
	"w": Color(1, 1, 1),
}
## Motoqueiro: o preto, k/K jaqueta (médio, brilho), w/W osso (claro, sombra), f/F/y fogo (laranja, vermelho, amarelo),
## s/S tachas de prata, c/C corrente (escuro, claro), a pneu, e raio.
const _PAL_MOTO := {
	"o": Color(0.03, 0.02, 0.05), "k": Color(0.2, 0.2, 0.27), "K": Color(0.42, 0.42, 0.55),
	"w": Color(0.96, 0.94, 0.86), "W": Color(0.7, 0.68, 0.6), "f": Color(1.0, 0.52, 0.1), "F": Color(0.9, 0.22, 0.05),
	"y": Color(1.0, 0.88, 0.25), "s": Color(0.92, 0.94, 1.0), "S": Color(0.58, 0.6, 0.72),
	"c": Color(0.45, 0.47, 0.55), "C": Color(0.8, 0.82, 0.9), "a": Color(0.14, 0.13, 0.17), "e": Color(0.02, 0.02, 0.03),
}
## Fênix: o azul-noite, a/b/d terno (médio, claro, sombra), k/K cabelo, w/W branco (claro, sombra), r/R gravata, g/G ouro.
const _PAL_FENIX := {
	"o": Color(0.04, 0.06, 0.2), "a": Color(0.22, 0.36, 0.78), "b": Color(0.48, 0.64, 0.97), "d": Color(0.12, 0.2, 0.5),
	"k": Color(0.32, 0.27, 0.45), "K": Color(0.72, 0.67, 0.92), "w": Color(0.98, 0.98, 1.0), "W": Color(0.74, 0.78, 0.9),
	"r": Color(0.86, 0.12, 0.16), "R": Color(1.0, 0.4, 0.36), "g": Color(1.0, 0.82, 0.22), "G": Color(0.78, 0.5, 0.1),
}
## Mimiau: o contorno preto, a/b/d pano amarelo (médio, claro, sombra), k lápis, r bochecha vermelha, s costura,
## t fita, p mão de sombra (roxo-escuro), c/C papelão (marrom, claro).
const _PAL_MIMI := {
	"o": Color(0.12, 0.09, 0.11), "a": Color(0.98, 0.86, 0.34), "b": Color(1.0, 0.96, 0.62), "d": Color(0.8, 0.64, 0.18),
	"k": Color(0.1, 0.08, 0.1), "r": Color(0.92, 0.2, 0.2), "s": Color(0.45, 0.3, 0.14), "t": Color(0.85, 0.82, 0.72),
	"p": Color(0.5, 0.38, 0.62), "c": Color(0.62, 0.42, 0.18), "C": Color(0.82, 0.6, 0.3),
}
## Jimiau: o roxo-noite, p/P/d roxo (médio, claro, sombra), g/G verde (médio, claro), y guizo, w/W carta, r/k naipes,
## b/B ficha azul, R ficha vermelha, a ficha preta.
const _PAL_JIMI := {
	"o": Color(0.13, 0.05, 0.22), "p": Color(0.58, 0.28, 0.85), "P": Color(0.78, 0.55, 0.97), "d": Color(0.36, 0.13, 0.58),
	"g": Color(0.3, 0.76, 0.3), "G": Color(0.6, 0.92, 0.55), "y": Color(1.0, 0.84, 0.22),
	"w": Color(0.98, 0.96, 0.92), "W": Color(0.62, 0.58, 0.74), "r": Color(0.86, 0.14, 0.2), "k": Color(0.12, 0.11, 0.16),
	"b": Color(0.22, 0.42, 0.92), "B": Color(0.55, 0.72, 1.0), "R": Color(0.92, 0.28, 0.3), "a": Color(0.22, 0.2, 0.28),
}

## Iguala a largura das linhas (ponto à direita).
static func _l(linhas: Array) -> Array:
	var w: int = 0
	for l in linhas:
		w = maxi(w, String(l).length())
	var r: Array = []
	for l in linhas:
		r.append(String(l).rpad(w, "."))
	return r

## Roda de fogo: círculo de 11 com o aro em chamas (alterna por ângulo e por quadro) e o miolo escuro com raios.
static func _roda(anim: float) -> Array:
	var fase: int = int(anim * 6.0) % 2
	var r: Array = []
	for j in 11:
		var l: String = ""
		for i in 11:
			var dx: float = i + 0.5 - 5.5
			var dy: float = j + 0.5 - 5.5
			var d: float = sqrt(dx * dx + dy * dy)
			var ch: String = "."
			if d <= 5.5:
				if d > 4.7:
					ch = "o"
				elif d > 3.3:
					var ang: int = int(floor((atan2(dy, dx) + PI) / (PI / 5.0)))
					ch = "f" if (ang + fase) % 2 == 0 else "F"
					if (ang + fase) % 5 == 0:
						ch = "y"
				elif d > 2.6:
					ch = "o"
				elif absf(dx) < 0.6 and absf(dy) < 0.6:
					ch = "S"
				elif absf(dx) < 0.6 or absf(dy) < 0.6 or absf(absf(dx) - absf(dy)) < 0.6:
					ch = "c"
				else:
					ch = "a"
			l += ch
		r.append(l)
	return r

## Leque de cinco cartas abrindo para cima e para a frente; a da frente é o Coringa. Contorno só na borda do leque; onde uma
## carta passa por baixo de outra a divisa é cinza.
static func _leque() -> Array:
	var W: int = 15
	var H: int = 13
	var idx: Array = []
	var uu: Array = []
	var vv: Array = []
	for j in H:
		var a: Array = []
		a.resize(W)
		a.fill(-1)
		idx.append(a)
		uu.append(a.duplicate())
		vv.append(a.duplicate())
	for k in 5:
		var th: float = deg_to_rad(6.0 + k * 19.0)
		var d := Vector2(sin(th), -cos(th))
		var n := Vector2(cos(th), sin(th))
		for j in H:
			for i in W:
				var p := Vector2(i + 0.5 - 1.5, j + 0.5 - (H - 1.5))
				var u: float = p.dot(d)
				var v: float = p.dot(n)
				if u >= 0.0 and u <= 10.5 and absf(v) <= 2.2:
					idx[j][i] = k
					uu[j][i] = u
					vv[j][i] = v
	var r: Array = []
	for j in H:
		var s: String = ""
		for i in W:
			var k: int = idx[j][i]
			if k < 0:
				s += "."
				continue
			var borda: bool = false
			var divisa: bool = false
			for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var x: int = i + dd.x
				var y: int = j + dd.y
				var kn: int = idx[y][x] if (x >= 0 and x < W and y >= 0 and y < H) else -1
				if kn < 0:
					borda = true
				elif kn > k:
					divisa = true
			var ch: String = "w"
			if borda:
				ch = "o"
			elif divisa:
				ch = "W"
			elif k == 4:
				var u2: float = uu[j][i]
				var v2: float = vv[j][i]
				ch = "g" if (u2 > 2.5 and u2 < 8.5) else "w"
				if ch == "g" and u2 > 4.8 and u2 < 6.4 and absf(v2) < 0.9:
					ch = "r"
			s += ch
		r.append(s)
	return r

## Camadas da peça com arte própria; vazio = usa o fallback. `maxima` pede a pose mais larga (caixa do ícone).
static func _camadas(tipo: int, anim: float, maxima: bool = false) -> Array:
	var fase: int = 0 if maxima else int(anim * 4.0) % 2
	var chama: int = 0 if maxima else int(anim * 6.0) % 2
	match tipo:
		# ---------------------------------------------------------------- Super Miau
		Pecas.Tipo.FRANJA_HEROICA:
			# topete preto com o cacho caído em S na testa
			return [[-5.5, -4.0, _l([
				"...ooooo...",
				"..okKkkkoo.",
				".okKkkkkkko",
				"okkkkkkkkko",
				"ookk..okkko",
				".o....okko.",
				"......ooko.",
			]), _PAL_SUPER]]
		Pecas.Tipo.COLLANT_S:
			# collant azul justo e o escudo amarelo com o S vermelho no peito
			return [[-5.5, -4.0, _l([
				".ooooooooo.",
				"obayrrryaao",
				"obayryyyaao",
				"obayrrryaao",
				"obayyyryado",
				"obayrrryado",
				".ooooooooo.",
			]), _PAL_SUPER]]
		Pecas.Tipo.PUNHO_ACO:
			# luva vermelha de punho fechado com a pulseira prata
			return [[-2.0, -5.0, _l([
				"..oooooo.",
				"oSSorRRro",
				"osSorRrro",
				"osSorDrDo",
				"oSSorrrDo",
				".ooooooo.",
			]), _PAL_SUPER]]
		Pecas.Tipo.CAPA_VERMELHA:
			# capa vermelha presa por um fecho amarelo no pescoço, a ponta balança para trás
			var b6: String = "oRRdRRRo....." if fase == 0 else ".oRRdRRRo...."
			var b7: String = ".ooooooo...." if fase == 0 else "..ooooooo..."
			return [[-12.0, -4.0, _l([
				"......oooooyo",
				"....ooRRRRyyo",
				"...oRrRRRRdRo",
				"..oRRRRRdRRRo",
				".oRRRRdRRRRo.",
				"oRRdRRRRRRo..",
				"oRRRRRRRRo...",
				b6, b7,
			]), {"o": _PAL_SUPER["C"], "R": _PAL_SUPER["r"], "r": _PAL_SUPER["R"], "d": _PAL_SUPER["D"], "y": _PAL_SUPER["y"]}]]
		# ---------------------------------------------------------------- Arqueiro Miau
		Pecas.Tipo.CAPUZ_ARQUEIRO:
			# capuz verde de pluma vermelha atrás e a máscara preta acima dos olhos
			return [[-5.5, -5.0, _l([
				"rR...ooo...",
				".rRoobbaoo.",
				"..oobaaaaoo",
				".oobaaaaaao",
				"oaaaaaaaaao",
				"oddddddddo.",
				"..okkkkkkko",
				"...ookkkkoo",
			]), _PAL_ARQ]]
		Pecas.Tipo.COLETE_FOLHAS:
			# colete verde-escuro de folhas costuradas e cinto marrom com fivela
			return [[-5.5, -3.0, _l([
				".ooooooooo.",
				"obbaaaaaado",
				"oabaaabaado",
				"ommmmmgmmmo",
				"odaaabaaddo",
				".ooooooooo.",
			]), _PAL_ARQ]]
		Pecas.Tipo.ARCO_RECURVO:
			# arco de madeira com as pontas viradas para a frente e a corda de barbante
			return [[0.0, -8.0, _l([
				"tmm...",
				"t.mm..",
				"t..mm.",
				"t...mm",
				"t...Mm",
				"t...gm",
				"t...gm",
				"t...Mm",
				"t...mm",
				"t..mm.",
				"t.mm..",
				"tmm...",
			]), _PAL_ARQ]]
		Pecas.Tipo.ALJAVA:
			# aljava inclinada com três flechas: ponta de luva de boxe, bomba e rede
			return [[-4.5, -10.0, _l([
				"ee..y.nn.",
				"eee.c.nnn",
				".e.cc.nn.",
				"..w.w.w..",
				"..m.m.m..",
				"..ommmmo.",
				"..oMmmmo.",
				"..ogggmo.",
				"..oMmmmo.",
				"...ommo..",
				"....oo...",
			]), _PAL_ARQ]]
		# ---------------------------------------------------------------- Motoqueiro Miausma
		Pecas.Tipo.CAVEIRA_CHAMAS:
			# capacete de caveira com chamas no topo (animadas)
			var f0: Array = ["..f..y..f..", ".fFf.fF.fFf", ".fFyfFyfFyf"] if chama == 0 else ["..f.f..y.f.", ".fFfFf.fFf.", "fFyFfFfyFfF"]
			return [[-5.5, -7.0, _l(f0 + [
				"..ooooooo..",
				".owwwwwwwo.",
				"owwwWwwwWwo",
				"owkkowwkkwo",
				"owkkowwkkwo",
				".owwwwwwwo.",
				"..owowowo..",
			]), _PAL_MOTO]]
		Pecas.Tipo.JAQUETA_ESPETOS:
			# jaqueta de couro preta com tachas prateadas nos ombros, zíper e barra em brasa
			return [[-5.5, -3.0, _l([
				".ooooooooo.",
				"osSkkkkkSso",
				"okkkkKskkko",
				"okKkkKskkko",
				"offFfkskfFo",
				".ooooooooo.",
			]), _PAL_MOTO]]
		Pecas.Tipo.CORRENTE_FOGO:
			# corrente de elos de fogo que sai da boca e acaba numa bola em chamas
			var ch1: String = "........fyf." if chama == 0 else ".......fyfy."
			return [[-2.0, -9.0, _l([
				ch1,
				".......fFyFf",
				".......fFfFo",
				"......ofFfo.",
				".....ofCco..",
				"....occfo...",
				"...ofCco....",
				"..occfo.....",
				".ofCco......",
				"occo........",
			]), _PAL_MOTO]]
		Pecas.Tipo.RODA_FOGO:
			# roda de moto pequena, aro em chamas, presa na cintura
			return [[-5.5, -5.5, _roda(0.0 if maxima else anim), _PAL_MOTO]]
		# ---------------------------------------------------------------- Fênix Miaussimo
		Pecas.Tipo.FRANJA_ADVOGADO:
			# cabelo preto com três espetos para cima
			return [[-5.5, -6.0, _l([
				".o...o...o.",
				"oKo.oKo.oKo",
				"okkookkookk",
				"okKkkkkKkko",
				"okkkkkkkkko",
				".ookkkkkkoo",
				"..ooooooo..",
			]), _PAL_FENIX]]
		Pecas.Tipo.TERNO_TRIBUNAL:
			# terno azul, camisa branca em V e gravata vermelha
			return [[-5.5, -3.0, _l([
				".ooooooooo.",
				"obaawwwaado",
				"obaawrwaado",
				"obaaarraado",
				"odaaaraaddo",
				".ooooooooo.",
			]), _PAL_FENIX]]
		Pecas.Tipo.LUVA_APONTAR:
			# luva branca de punho azul com o indicador esticado: "Objeção!"
			return [[-2.0, -3.0, _l([
				".oooo.........",
				"obowwoooooooo.",
				"obowwwwwwwwwWo",
				"obowwoooooooo.",
				"obowwo........",
				".oooo.........",
			]), _PAL_FENIX]]
		Pecas.Tipo.DISTINTIVO:
			# broche dourado com a asa de fênix, preso no peito
			return [[1.0, -3.0, _l([
				".oooo.",
				"oGgGgo",
				"ogGgGo",
				"oggGgo",
				".oggo.",
				"..oo..",
			]), _PAL_FENIX]]
		# ---------------------------------------------------------------- Mimiau
		Pecas.Tipo.CAPUZ_PELUCIA:
			# capuz amarelo de pano com orelhas pontudas de ponta preta e olhos riscados a lápis
			return [[-5.5, -7.0, _l([
				"k.........k",
				"ok.......ko",
				"oao.....oao",
				"oaaooooooao",
				"oabaaaaaado",
				"oaaaaaaaaao",
				"oakkaaakkao",
				"oakaaaaakao",
				"oaaaaaaaaao",
				".ooooooooo.",
			]), _PAL_MIMI]]
		Pecas.Tipo.DISFARCE_AMARELO:
			# pano amarelo largo cobrindo o gato: costura torta, bochechas a caneta e a barra rasgada
			return [[-7.5, -5.0, _l([
				"....ooooooooo....",
				"..ooobbaaaaaaoo..",
				".obbaaaaaaaaaaao.",
				"oabaaasaaaaaaaado",
				"oaaaaasaaaarraado",
				"oaaaasaaaaarraado",
				"oaaaaasaaaaaaaddo",
				"oaaaasaaaaaaaddo.",
				"oaadoaaodaaoaadoo",
				".o.o.oo.o.oo.o.o.",
			]), _PAL_MIMI]]
		Pecas.Tipo.PATA_MISTERIOSA:
			# mão preta e fina de sombra que sai de dentro do pano
			return [[-2.0, -8.0, _l([
				"......o.o.o",
				"......ooooo",
				".....oppppo",
				"...ooppppo.",
				"..opppooo..",
				".oppoo.....",
				"oppo.......",
				"ooo........",
			]), _PAL_MIMI]]
		Pecas.Tipo.RABO_PAPELAO:
			# rabo em raio de papelão amarelo preso com fita
			return [[-6.0, -11.0, _l([
				"....oooooo",
				"....oaaabo",
				"....oaaaao",
				"....ooaaao",
				"...oaaaao.",
				"..oaaaoo..",
				"..oooaao..",
				"....oaao..",
				"...otttto.",
				"...oaaao..",
				"...oaao...",
				"...ooo....",
			]), _PAL_MIMI]]
		# ---------------------------------------------------------------- Jimiau
		Pecas.Tipo.CORINGA_CHAPEU:
			# chapéu de bobo de três pontas, roxo e verde, com guizos dourados
			return [[-5.5, -6.0, _l([
				"y....y....y",
				"po..ogo..op",
				".po.ogo.op.",
				"..oopgpoo..",
				"..oPpppdo..",
				".oPppppddo.",
				"ogGgGgGgGgo",
				".ooooooooo.",
			]), _PAL_JIMI]]
		Pecas.Tipo.COLETE_BARALHO:
			# colete branco estampado de naipes: copas, espadas
			return [[-5.5, -3.0, _l([
				".ooooooooo.",
				"owwwwwwwwWo",
				"owrwrwwkwWo",
				"owrrrwkkkWo",
				"owwrwwkwkWo",
				".ooooooooo.",
			]), _PAL_JIMI]]
		Pecas.Tipo.LEQUE_POQUER:
			# leque de cinco cartas; a da frente é o Coringa
			return [[-1.0, -11.0, _leque(), _PAL_JIMI]]
		Pecas.Tipo.FICHAS:
			# três pilhas de fichas: vermelhas, azuis e pretas
			return [[-5.5, -8.0, _l([
				"......ooooo",
				"......oawao",
				".ooo..ooooo",
				"oRwRo.obwbo",
				"ooooo.ooooo",
				"oRwRo.obwbo",
				"ooooo.ooooo",
				"oRwRo.obwbo",
				".ooo...ooo.",
			]), _PAL_JIMI]]
	return []

static func _fallback(tipo: int) -> Array:
	return RoupaGatoE.PECAS[_MOLDE_FALLBACK[Pecas.SLOT[tipo]]]

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
			RoupaGato.sprite(c, cm[0], cm[1], cm[2], cm[3], f)
		return
	var d: Array = _fallback(tipo)
	RoupaGato.sprite(c, d[0], d[1], d[2], RoupaGatoE._paleta(tipo), f)
