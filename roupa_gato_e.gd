class_name RoupaGatoE
extends RefCounted
## Roupas do gato em pixel art, tipos 84 a 99 (ver RoupaGato para as convenções).
## Fantasias do lado de fora: Ninja da Folha (84-87), Robô Azul (88-91), Tubarão (92-95) e Abelha (96-99).
##
## Cada peça é uma lista de CAMADAS: [x, y, linhas, paleta], em pixels do gato, relativas à origem do lugar
## onde a peça prende (cabeça = topo do crânio; corpo = centro do tronco; boca = ponta do focinho;
## traseira = alto da anca; pescoço = entre cabeça e tronco). `desenhar` pinta as camadas na ordem e
## `caixa` (usada pelo ícone) é a união delas, então desenho e caixa nunca ficam fora de sincronia.
## Peças de kit ainda sem arte própria caem na tabela provisória `PECAS` (formas simples na cor do kit).

const _PRETO := Color(0.12, 0.1, 0.14)

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão.
static func onde(tipo: int) -> int:
	if tipo == Pecas.Tipo.BOIA:
		return RoupaGato.Onde.PESCOCO
	return -1

# ------------------------------------------------------------------ tabela provisória (kits sem arte própria)
const PECAS := {
	Pecas.Tipo.BANDANA_FOLHA: [-4.5, -2.0, [
		"..ooooooo..", ".oaaaaaaao.", "oaassssaaao", "oaassssaaao", "oooooooooo.", ]],
	Pecas.Tipo.MACACAO_LARANJA: [-5.5, -3.0, [
		".ooooooooo.", "oaaaaaaaaao", "oabbaaabbao", "oaaaaaaaaao", "oaaaaaaaaao", ".ooooooooo.", ]],
	Pecas.Tipo.KUNAI: [-3.0, -3.0, [
		"..oo....", ".oso...", "osso...", ".ooo...", "..oao..", "..oao..", "...o...", ]],
	Pecas.Tipo.PERGAMINHO: [-3.0, -3.0, [
		"oooooo.", "obbbbbo", "oboobbo", "obbbbbo", "oaaaaao", "oooooo.", ]],
	Pecas.Tipo.CAPACETE_AZUL: [-4.5, -2.0, [
		"..ooooooo..", ".oaaaaaaao.", "oabbaaaaaao", "oaaaaaaaaao", "oaaooooaaao", "ooo.....ooo", ]],
	Pecas.Tipo.ARMADURA_AZUL: [-5.5, -3.0, [
		".ooooooooo.", "oaaaaaaaaao", "oabbsssbbao", "oaaassaaaao", "oaaaaaaaaao", ".ooooooooo.", ]],
	Pecas.Tipo.CANHAO_BRACO: [-3.0, -3.0, [
		"..oooooo", "oaabbssso", "oaaaasso.", "oooooooo", ]],
	Pecas.Tipo.TANQUE: [-3.0, -4.0, [
		".oooo.", "oaaaao", "obbbbo", "obbbbo", "oaaaao", ".oooo.", ]],
	Pecas.Tipo.ANTENAS: [-4.5, -7.0, [
		"o.......o.", "bo.....ob.", ".o.....o..", ".ooo.ooo..", ]],
	Pecas.Tipo.COLETE_LISTRADO: [-5.5, -3.0, [
		".ooooooooo.", "oaaaaaaaaao", "okkkkkkkkko", "oaaaaaaaaao", "okkkkkkkkko", ".ooooooooo.", ]],
	Pecas.Tipo.FERRAO: [-3.0, -3.0, [
		"oooo....", "oaaaooo.", "oaaaabbo", "oaaaooo.", "oooo....", ]],
	Pecas.Tipo.POTE_MEL: [-3.0, -4.0, [
		".oooo.", "ommmmo", "oaaaao", "oabbao", "oaaaao", ".oooo.", ]],
}

## Paleta provisória do kit: o = contorno, a = cor principal, b = realce, s = detalhe claro, k = listra, r/w/m = extras.
static func _paleta(tipo: int) -> Dictionary:
	var cor: Color = Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[tipo]]
	var p: Dictionary = {"o": cor.darkened(0.65), "a": cor, "b": cor.lightened(0.45), "s": Color(0.85, 0.88, 0.92),
		"k": _PRETO, "r": Color(0.9, 0.2, 0.2), "w": Color(1, 1, 1), "m": Color(1.0, 0.75, 0.15)}
	if Pecas.CONJUNTO_DE[tipo] == Pecas.Conjunto.ABELHA:
		p["a"] = Color(1.0, 0.85, 0.15)
	return p

# ------------------------------------------------------------------ paletas das peças novas
## Ninja: o contorno marrom, a/A/u laranja (médio, claro, sombra), B/b azul do macacão; O/n/m faixa azul-marinho
## (contorno, tom, realce); S/s metal (claro, sombra), k escuro, G cabo, W/p/P pergaminho (madeira, papel), R corda.
const _PAL_NINJA := {
	"o": Color(0.45, 0.18, 0.03), "a": Color(1.0, 0.55, 0.1), "A": Color(1.0, 0.76, 0.36), "u": Color(0.8, 0.38, 0.05),
	"B": Color(0.13, 0.2, 0.58), "b": Color(0.3, 0.42, 0.9),
	"O": Color(0.04, 0.06, 0.22), "n": Color(0.2, 0.3, 0.75), "m": Color(0.4, 0.55, 0.98),
	"S": Color(0.92, 0.95, 1.0), "s": Color(0.6, 0.66, 0.78), "k": Color(0.1, 0.1, 0.18), "G": Color(0.5, 0.3, 0.12),
	"W": Color(0.6, 0.3, 0.12), "p": Color(0.88, 0.78, 0.52), "P": Color(0.98, 0.93, 0.74), "R": Color(0.82, 0.18, 0.15),
}
## Robô: o contorno azul-noite, a azul, d azul-escuro, A/B azul-claro, S metal, W branco, y/Y luz amarela.
const _PAL_ROBO := {
	"o": Color(0.04, 0.09, 0.3), "a": Color(0.2, 0.45, 0.95), "d": Color(0.11, 0.27, 0.7),
	"A": Color(0.5, 0.76, 1.0), "B": Color(0.62, 0.86, 1.0), "S": Color(0.78, 0.82, 0.9), "W": Color(1, 1, 1),
	"y": Color(1.0, 0.78, 0.1), "Y": Color(1.0, 0.86, 0.2), "k": Color(0.06, 0.08, 0.2),
}
## Tubarão: o contorno azul-noite, a/b/d cinza-azulado (médio, claro, sombra), w dentes e barriga, k olho e boca, r gengiva.
const _PAL_TUBARAO := {
	"o": Color(0.09, 0.15, 0.25), "a": Color(0.47, 0.6, 0.72), "b": Color(0.68, 0.79, 0.88),
	"d": Color(0.32, 0.43, 0.57), "w": Color(0.97, 0.98, 1.0), "k": Color(0.08, 0.06, 0.1),
	"r": Color(0.82, 0.18, 0.22), "s": Color(0.8, 0.86, 0.92),
}
## Boia: contorno vinho, r vermelho, R vermelho claro, w branco, s branco na sombra.
const _PAL_BOIA := {
	"o": Color(0.36, 0.06, 0.1), "r": Color(0.9, 0.17, 0.17), "R": Color(1.0, 0.45, 0.4),
	"w": Color(1, 1, 1), "s": Color(0.74, 0.76, 0.84), "d": Color(0.62, 0.1, 0.12),
}

## Abelha: o contorno marrom-escuro, Y amarelo, H mel-claro/realce, h brilho, U amarelo na sombra, k listra preta,
## v/W/w asinha (contorno, vidro, brilho), K ferrão escuro, P/p/q barro (borda, corpo, sombra).
const _PAL_ABELHA := {
	"o": Color(0.27, 0.16, 0.03), "Y": Color(1.0, 0.85, 0.15), "H": Color(1.0, 0.76, 0.12), "h": Color(1.0, 0.95, 0.6),
	"U": Color(0.85, 0.6, 0.08), "k": Color(0.13, 0.09, 0.07),
	"v": Color(0.4, 0.55, 0.75), "W": Color(0.78, 0.92, 1.0), "w": Color(1, 1, 1),
	"K": Color(0.6, 0.47, 0.28),
	"P": Color(0.78, 0.5, 0.3), "p": Color(0.62, 0.34, 0.2), "q": Color(0.42, 0.22, 0.12), "c": Color(0.98, 0.92, 0.7),
}

## Anel da boia: elipse de 11 x 9 com buraco no meio, listras vermelhas e brancas por ângulo.
static var _boia_cache: Array = []
static func _boia_linhas() -> Array:
	if not _boia_cache.is_empty():
		return _boia_cache
	var rx: float = 5.5
	var ry: float = 4.5
	for j in 9:
		var l: String = ""
		for i in 11:
			var dx: float = (i + 0.5 - 5.5) / rx
			var dy: float = (j + 0.5 - 4.5) / ry
			var d: float = sqrt(dx * dx + dy * dy)
			var ch: String = "."
			if d <= 1.0:
				var dxi: float = (i + 0.5 - 5.5) / 3.5
				var dyi: float = (j + 0.5 - 4.5) / 2.6
				var di: float = sqrt(dxi * dxi + dyi * dyi)
				if di < 0.85:
					ch = "."
				elif d > 0.86 or di < 1.12:
					ch = "o"
				else:
					var ang: float = atan2(j + 0.5 - 4.5, (i + 0.5 - 5.5) * 0.82)
					var seg: int = int(floor((ang + PI) / (PI / 3.0))) % 2
					ch = "r" if seg == 0 else "w"
					if ch == "r" and j <= 2:
						ch = "R" if d < 0.82 and j <= 1 else "r"
					elif ch == "w" and j >= 6:
						ch = "s"
			l += ch
		_boia_cache.append(l)
	return _boia_cache

## Camadas da peça: lista de [x, y, linhas, paleta]. `maxima` pede a pose mais larga (para a caixa do ícone).
## Devolve lista vazia para peças que ainda usam o desenho provisório.
static func _camadas(tipo: int, anim: float, maxima: bool = false) -> Array:
	match tipo:
		Pecas.Tipo.BANDANA_FOLHA:
			# faixa azul-escura na testa com plaquinha de metal (folha gravada) e duas pontas soltas ao vento
			var sw: int = 0 if maxima else int(round(sin(anim * 4.0)))
			return [
				[-4.5, -1.0, [
					"....OOOOO.",
					"OOOOOSssOO",
					"OmmmOSkSOn",
					"OnnnOsSsOn",
					"OOOOOOOOOO",
				], _PAL_NINJA],
				[-7.5, 0.0 + sw, [
					"Onnn",
					"OnnO",
					"OO..",
				], _PAL_NINJA],
				[-8.5, 2.0 - sw, [
					"OnnO",
					"OOnO",
				], _PAL_NINJA],
			]
		Pecas.Tipo.MACACAO_LARANJA:
			# macacão laranja com gola e punhos azuis e a barra azul na cintura
			return [[-5.5, -3.0, [
				".ooooooooo.",
				"oAAAaaaaBBo",
				"oAaaaaaaBbo",
				"oaaaaaaaaBo",
				"ouuuuBBBuuo",
				".ooooooooo.",
			], _PAL_NINJA]]
		Pecas.Tipo.KUNAI:
			# kunai: argola, cabo enrolado, guarda e lâmina em folha
			return [[-3.5, -3.0, [
				"........oooooo...",
				".ooo.oooSSSSsssoo",
				"o...oGGGSSSssssso",
				".ooo.oooSSSSsssoo",
				"........oooooo...",
			], _PAL_NINJA]]
		Pecas.Tipo.PERGAMINHO:
			# pergaminho grande preso às costas com cordas vermelhas
			return [[-5.5, -3.0, [
				"..oooooooo..",
				".oWpPRPPRpWo",
				"oWWpPRppRpWo",
				".oWpPRPPRpWo",
				"..oooooooo..",
			], _PAL_NINJA]]
		Pecas.Tipo.CAPACETE_AZUL:
			# capacete azul com faixa central clara e orelhas redondas; olho e focinho de fora
			return [[-5.5, -3.0, [
				"...ooooo...",
				"..oaBBBBao.",
				".oaaBBBBaao",
				"oaaaaaaaaao",
				"oAAAoaaaao.",
				"oAwAoaao...",
				"oAAAoaao...",
				".oooodoo...",
			], _PAL_ROBO]]
		Pecas.Tipo.ARMADURA_AZUL:
			# peito azul-claro com luzes amarelas, ombros e laterais azul-escuro
			return [[-5.5, -3.0, [
				".ooooooooo.",
				"odyAAAAAydo",
				"odAAaaaAAdo",
				"oddAAAAAddo",
				"odddddddddo",
				".ooooooooo.",
			], _PAL_ROBO]]
		Pecas.Tipo.CANHAO_BRACO:
			# canhão redondo no lugar da pata: cano azul com anéis e luz amarela que pulsa na ponta
			var pal: Dictionary = _PAL_ROBO.duplicate()
			if sin(anim * 8.0) > 0.0:
				pal["Y"] = Color(1.0, 0.97, 0.55)
			return [[-3.5, -3.0, [
				"..oooooooo....",
				".oBBaaaaddoo..",
				"oBaaaaaaddkYy.",
				"oaaaaaaaddkYy.",
				".oaaaaaddoo...",
				"..oooooooo....",
			], pal]]
		Pecas.Tipo.TANQUE:
			# latinha de energia azul com tampa prateada e a letra E
			return [[-3.5, -5.0, [
				"..ooo..",
				".oSSSo.",
				"oBBaaao",
				"oaWWWao",
				"oaWaaao",
				"oaWWaao",
				"oaWaaao",
				"oaWWWao",
				"oddddao",
				".ooooo.",
			], _PAL_ROBO]]
		Pecas.Tipo.CAPUZ_TUBARAO:
			# cabeça de tubarão engolindo a do gato: dorsal para trás, olhinho, fileira de dentes na testa;
			# do olho do gato para baixo (olho, focinho, queixo) fica de fora
			return [[-5.5, -5.0, [
				"...o........",
				"...oo.......",
				"..oao.......",
				"..oaaooooo..",
				".oaaaaabbbo.",
				"oaaddaabbkao",
				"oaadddaaaaao",
				"owwwwwwwwwwo",
				"owowowowowo.",
			], _PAL_TUBARAO]]
		Pecas.Tipo.ROUPA_TUBARAO:
			# corpo cinza-azulado com barbatana dorsal para trás, fendas de guelra e barriga branca ondulada
			return [[-5.5, -8.0, [
				".o.........",
				".oo........",
				".oao.......",
				".oaao......",
				"..oaao.....",
				"..oaaao....",
				".oaaaaoooo.",
				"oaaaaaabbao",
				"oaaaaadadao",
				"owwawwwawwo",
				"owwwwwwwwwo",
				".ooooooooo.",
			], _PAL_TUBARAO]]
		Pecas.Tipo.MORDIDA:
			# dentadura de tubarão: gengiva vermelha e duas fileiras de dentes; abre e fecha devagar na boca do gato
			var abre: bool = maxima or sin(anim * 5.0) > 0.2
			var sup: Array = [
				".oooooo.",
				"orrrrrro",
				"owwwwwwo",
				"okwkwkwo",
			]
			var inf: Array = [
				"owkwkwko",
				"orrrrrro",
				".oooooo.",
			]
			var meio: Array = ["okkkkkko"] if abre else []
			return [[-3.0, -3.5, sup + meio + inf, _PAL_TUBARAO]]
		Pecas.Tipo.BOIA:
			return [[-5.5, -4.5, _boia_linhas(), _PAL_BOIA]]
		Pecas.Tipo.ANTENAS:
			# arquinho amarelo na cabeça com duas hastes curvas e bolinhas amarelas de contorno escuro (leem em qualquer pelo)
			var sw: int = 0 if maxima else int(round(sin(anim * 3.0)))
			return [
				[-4.5, -4.0, [
					".o......o.",
					"..o....o..",
					"...o..o...",
					"..oYYYYo..",
					".oYYhYYYo.",
					"..oooooo..",
				], _PAL_ABELHA],
				[-4.5 + sw, -7.0, [
					"ooo....ooo",
					"oYo....oYo",
					"ooo....ooo",
				], _PAL_ABELHA],
			]
		Pecas.Tipo.COLETE_LISTRADO:
			# listras amarelas e pretas atravessando o tronco e duas asinhas de vidro azuladas nas costas
			return [[-5.5, -8.0, [
				"..vv.......",
				".vWWv.vv...",
				"vWwWWvWWv..",
				"vWWWWvWWv..",
				".vvvvovvv..",
				".ooooooooo.",
				"oHHkkHHkkHo",
				"oYYkkYYkkYo",
				"oYYkkYYkkYo",
				"oUUkkUUkkUo",
				".ooooooooo.",
			], _PAL_ABELHA]]
		Pecas.Tipo.FERRAO:
			# ferrão comprido preso pelo bulbo listrado: ponta escura para a frente
			return [[-3.5, -3.0, [
				"..ooo........",
				".oYYYoooo....",
				"oYkYYhKKKooo.",
				"oYYkYKKKKKKoo",
				".oYYYoooooo..",
				"..ooo........",
			], _PAL_ABELHA]]
		Pecas.Tipo.POTE_MEL:
			# pote de barro com mel dourado transbordando e escorrendo pelas laterais
			return [[-4.0, -9.0, [
				"..oooo..",
				".oHhHHo.",
				"oHHHHHHo",
				"oPHPPPHo",
				"oppHppHo",
				"oppHppHo",
				"opppHpqo",
				"oqppppqo",
				".oqqqqo.",
				"..oooo..",
			], _PAL_ABELHA]]
	return []

## Caixa ocupada pelo desenho (pixels do gato, relativa à origem do lugar), para centralizar o ícone.
static func caixa(tipo: int) -> Rect2:
	var cs: Array = _camadas(tipo, 0.0, true)
	if cs.is_empty():
		if not PECAS.has(tipo):
			return Rect2(-4, -4, 8, 8)
		cs = [[PECAS[tipo][0], PECAS[tipo][1], PECAS[tipo][2], {}]]
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
	if not PECAS.has(tipo):
		return
	var d: Array = PECAS[tipo]
	RoupaGato.sprite(c, d[0], d[1], d[2], _paleta(tipo), f)
