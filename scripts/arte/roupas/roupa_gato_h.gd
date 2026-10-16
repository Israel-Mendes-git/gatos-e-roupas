class_name RoupaGatoH
extends RefCounted
## Roupas do gato em pixel art, tipos 148 em diante (ver RoupaGato para as convenções): expansão das fantasias, lote 3
## (Leonarmiau 148-151, Donatemiau 152-155, Rafamiau 156-159, Rocket Miaugue 160-163, Deadmiau 164-167, Meon 168-171).
##
## COMO ENCAIXA NO GATO: igual ao RoupaGatoG, cada peça é escrita em letras (`_txt`) em COORDENADAS DO GATO (x para a frente, y para
## cima, pé em 0; cabeça em x 3..10 / y -17..-10, tronco em x -8..7 / y -12..-5) e convertida para o lugar onde fica presa. O contorno
## de 1 px (nos 4 vizinhos, sem a borda de baixo do corpo) e a luz/sombra vêm por regra (`_cont`, `_luz`); sem ruído nem alfa.
## Camada [x, y, linhas, paleta, true] = ATRÁS do corpo (asa do Rocket, cabos das katanas do Deadmiau, propulsor).
##
## KIT TARTARUGA: o casco, o cinto e a fivela são os mesmos nas quatro (Leonarmiau, Donatemiau, Rafamiau e a Miauchelangelo, que o
## pega daqui por `casco_miau`): só mudam a bandana, a arma e o detalhe do casco. Ficha: notas/lote3_ficha_visual.md.
##
## FALLBACK: peça sem arte própria em `_montar` desenha a silhueta de uma peça do lado de fora, tingida.

const PRIMEIRO := 148
## Silhuetas de reserva por espaço (cabeça, corpo, mão, acessório); cada fantasia usa uma das 4 colunas, para não ficarem todas iguais.
const _MOLDE_FALLBACK: Array = [
	[Pecas.Tipo.CAPACETE_AZUL, Pecas.Tipo.BANDANA_FOLHA, Pecas.Tipo.CAPUZ_TUBARAO, Pecas.Tipo.ANTENAS],
	[Pecas.Tipo.COLETE_LISTRADO, Pecas.Tipo.MACACAO_LARANJA, Pecas.Tipo.ARMADURA_AZUL, Pecas.Tipo.ROUPA_TUBARAO],
	[Pecas.Tipo.KUNAI, Pecas.Tipo.CANHAO_BRACO, Pecas.Tipo.MORDIDA, Pecas.Tipo.FERRAO],
	[Pecas.Tipo.TANQUE, Pecas.Tipo.PERGAMINHO, Pecas.Tipo.BOIA, Pecas.Tipo.POTE_MEL],
]

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão (cabeça, corpo, boca e traseira).
static func onde(tipo: int) -> int:
	match tipo:
		Pecas.Tipo.CINTO_L, Pecas.Tipo.COMPUTADOR_PULSO, Pecas.Tipo.CINTO_R, Pecas.Tipo.CHIMICHANGA, Pecas.Tipo.MALETA_MERCADOR:
			return RoupaGato.Onde.CORPO
	return -1

## Peças com camada atrás do corpo do gato.
static func tem_atras(tipo: int) -> bool:
	return tipo == Pecas.Tipo.CARROCERIA_TURBO or tipo == Pecas.Tipo.TRAJE_REMENDADO or tipo == Pecas.Tipo.PROPULSOR_TURBO

# ------------------------------------------------------------------ paletas
## Kit Tartaruga (igual nas quatro): o contorno verde-noite; a/b/d casco (médio, luz, sombra); e plastrão; t/u couro do cinto (médio,
## sombra); g/G fivela (média, sombra).
const _KIT := {
	"o": Color("0c1708"), "a": Color("5e9440"), "b": Color("92c468"), "d": Color("3c6a2e"), "e": Color("e3cf8c"), "E": Color("b09a55"),
	"t": Color("8a5a30"), "u": Color("5c3a1e"), "g": Color("e8bf3c"), "G": Color("b58a1e"),
}
## Bandanas: o contorno da cor, a/b/d (médio, luz, sombra); w branco do olho; k pupila.
const _BAND_LEO := {"o": Color("0a1233"), "a": Color("3470d0"), "b": Color("7ba5ec"), "d": Color("22489c")}
const _BAND_DONA := {"o": Color("1a0b2e"), "a": Color("8a4fc0"), "b": Color("b98ae0"), "d": Color("5c3492")}
const _BAND_RAFA := {"o": Color("2b0808"), "a": Color("d03a34"), "b": Color("f0786a"), "d": Color("8c2024")}
const _OLHO := {"w": Color("f4f6f0"), "k": Color("0c1708")}
## Rocket Miaugue: o azul-noite; a/b/d carroceria (média, luz, sombra); v/V vidro (escuro, brilho); k/K pneu (preto, brilho);
## m aro; M branco da bola (e miolo do aro); q sombra da bola; x/y brilho dos hexágonos (claro, escuro); f/n/F chama laranja
## (média, luz, sombra).
const _PAL_ROCKET := {
	"o": Color("0a1022"), "a": Color("2f72d8"), "b": Color("78a8f0"), "d": Color("1f4aa0"),
	"v": Color("1a2a3e"), "V": Color("4a6a88"), "k": Color("26242c"), "K": Color("46424e"),
	"m": Color("b4bcc6"), "M": Color("eef2f4"), "q": Color("9aa6b0"), "x": Color("6ee0e8"), "y": Color("2a9aa8"),
	"f": Color("f0922a"), "n": Color("ffd36a"), "F": Color("c25a14"),
}
## Deadmiau: o preto-vinho; a/b/d vermelho (médio, luz, sombra); p/P preto do traje (médio, luz); k mancha dos olhos; w branco do olho;
## C fivela e guarda; c/D papelão (médio, sombra) e papelão claro L; g fita cinza; m remendo; Y/y/z chimichanga (luz, média, sombra).
const _PAL_DEAD := {
	"o": Color("0a0608"), "a": Color("b8222c"), "b": Color("e0565a"), "d": Color("7c161f"),
	"p": Color("2b2630"), "P": Color("4a4350"), "k": Color("2b2630"), "w": Color("f4f2ee"),
	"C": Color("c9b98c"), "c": Color("c9a878"), "L": Color("e3cfa3"), "D": Color("9c7c4f"), "g": Color("8a8e98"), "m": Color("7a6a8c"),
	"Y": Color("f2cd7a"), "y": Color("d9a441"), "z": Color("a66f26"),
}
## Meon: o marrom-noite; h/H/s cabelo (médio, luz, sombra); j/J/d jaqueta (média, luz, sombra); C/c gola de pelo (média, sombra);
## p preto do couro; i/I/S metal (médio, luz, sombra); y trinco; e olhos; m/M/n maleta (média, luz, sombra).
const _PAL_MEON := {
	"o": Color("150c08"), "h": Color("cda85a"), "H": Color("f0d58c"), "s": Color("9a7430"),
	"j": Color("94603a"), "J": Color("bc8a5e"), "d": Color("5e3a22"), "C": Color("d8c8a0"), "c": Color("a8946a"),
	"p": Color("2e2a2c"), "i": Color("8c9aa6"), "I": Color("c5d0d8"), "S": Color("58626e"), "y": Color("c9a040"), "e": Color("fff0a0"),
	"m": Color("7a4a2a"), "M": Color("a87040"), "n": Color("4c2c18"),
}

# ------------------------------------------------------------------ ferramentas (usam as telas de RoupaGatoF e RoupaGatoG)
static func _ret(cv: Dictionary, x0: int, y0: int, x1: int, y1: int, ch: String) -> void:
	RoupaGatoF._ret(cv, x0, y0, x1, y1, ch)

static func _px(cv: Dictionary, x: int, y: int, ch: String) -> void:
	cv[Vector2i(x, y)] = ch

static func _lin(cv: Dictionary, a: Vector2i, b: Vector2i, ch: String) -> void:
	RoupaGatoF._lin(cv, a, b, ch)

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

static func _pal(base: Dictionary, a: Dictionary, b: Dictionary = {}) -> Dictionary:
	var p: Dictionary = base.duplicate()
	p.merge(a, true)
	p.merge(b, true)
	return p

## Tira da tela o que não é tronco do gato (x -8..7 / y -12..-5): o casco e o traje não passam do corpo.
static func _so_tronco(cv: Dictionary) -> void:
	var m: Dictionary = {}
	RoupaGatoF._tronco(m, "x", -12, -5)
	for k in cv.keys():
		if not m.has(k):
			cv.erase(k)

# ------------------------------------------------------------------ kit Tartaruga
## Casco do kit: o desenho ORIGINAL da Miauchelangelo (domo de placas sobre o dorso e a faixa de plastrão embaixo, 12x8 em x -8..3 /
## y -13..-6), igual nas quatro; só as cores são as do kit. d = base do casco, a = placa média, b = placa clara, e = plastrão.
const _CASCO_LINHAS := [
	"...oooooo...",
	"..oddbbddo..",
	".odbaddabdo.",
	"oddabddbaddo",
	"odbaddddabdo",
	"oddbaaaabddo",
	"oeeeeeeeeeeo",
	".oooooooooo.",
]

## Escreve o casco do kit na tela (já com contorno, luz e sombra; não passa por `_cont` nem `_luz`).
static func _casco_kit(cv: Dictionary, _inicial: String = "", _torto: bool = false) -> void:
	_txt(cv, -8, -13, _CASCO_LINHAS)

## Casco do kit pronto (camada do corpo).
static func _casco_pronto(cv: Dictionary, pal: Dictionary) -> Array:
	return _lay(cv, RoupaGato.Onde.CORPO, pal)

## Casco do kit da Miauchelangelo, em camadas [x, y, linhas, paleta] para RoupaGatoC (corpo; o mesmo desenho das outras).
static var _cache_miau: Array = []
static func casco_miau() -> Array:
	if _cache_miau.is_empty():
		var cv: Dictionary = {}
		_casco_kit(cv)
		_cache_miau = [_casco_pronto(cv, _KIT)]
	return _cache_miau

# ------------------------------------------------------------------ bandanas
## Bandana-chapéu com a máscara do olho (branco com pupila) e as duas pontas atrás, que balançam em dois quadros (`fase` 0 ou 1).
## `modo`: 0 reto (Leonarmiau, sobrancelha reta), 1 de óculos (Donatemiau), 2 torta e brava (Rafamiau).
static func _bandana(cv: Dictionary, fase: int, modo: int) -> void:
	if modo == 2:
		_txt(cv, 2, -16, [
			"aaaa.....",
			"aaaaaaaaa",
			"aaaaawwwa",
			"....awwka",
			"....aaaaa",
		])
	else:
		_txt(cv, 2, -15, [
			"aaaaaaaaa",
			"aaaaawwwa",
			"aaaaawwka",
			"....aaaaa",
		])
	_luz(cv, "a", "b", "d")
	if modo == 0:
		_ret(cv, 7, -15, 10, -14, "o")
	if modo == 2:
		# sobrancelha grossa que desce para o focinho
		_ret(cv, 7, -15, 10, -14, "o")
		_px(cv, 9, -14, "o")
	# as pontas soltas: uma sobe, outra cai; no outro quadro trocam
	if modo == 2:
		if fase == 0:
			_txt(cv, -3, -18, ["...aa.", "..aaa.", ".aaaaa"])
			_txt(cv, -1, -13, ["aaa", "aa."])
		else:
			_txt(cv, -3, -19, ["..aa.", ".aaa.", "aaaaa", "..aaa"])
			_txt(cv, -2, -14, ["aaaa", "..aa"])
	elif fase == 0:
		_txt(cv, -2, -17, ["aa..", "aaa.", ".aaa"])
		_txt(cv, -3, -13, [".aaaa", "aaa.."])
	else:
		_txt(cv, -2, -18, ["...aa", "..aaa", ".aaaa", "..aaa"])
		_txt(cv, -4, -13, [".aaaaa", "aaa..."])
	if modo == 1:
		# óculos de soldador empurrados para a testa: duas lentes redondas de aro cinza e vidro verde, com a alça escura para trás
		_txt(cv, 3, -20, [
			".ii..ii.",
			"ivviivvi",
			"ivviivvi",
			".ii..ii.",
		])
		_px(cv, 4, -19, "V")
		_px(cv, 8, -19, "V")
		_ret(cv, 0, -18, 2, -17, "k")

# ------------------------------------------------------------------ peças
static var _cache: Dictionary = {}

## Camadas da peça com arte própria; vazio = usa o fallback. As bandanas e o propulsor têm dois quadros (balançam).
static func _camadas(tipo: int, anim: float, maxima: bool = false) -> Array:
	var fase: int = 0
	if not maxima and (Pecas.SLOT[tipo] == Pecas.SLOT_CABECA or tipo == Pecas.Tipo.PROPULSOR_TURBO):
		fase = 1 if sin(anim * 4.0) > 0.0 else 0
	var chave: int = tipo * 2 + fase
	if _cache.has(chave):
		return _cache[chave]
	var r: Array = _montar(tipo, fase)
	_cache[chave] = r
	return r

static func _montar(tipo: int, fase: int) -> Array:
	var cv: Dictionary = {}
	match tipo:
		# ---------------------------------------------------------------- Leonarmiau (Leonardo)
		Pecas.Tipo.BANDANA_AZUL:
			_bandana(cv, fase, 0)
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _pal(_BAND_LEO, _OLHO))]
		Pecas.Tipo.CASCO_POLIDO:
			# o casco do kit com o polido: 3 px de brilho claro no canto de cima de uma placa
			_casco_kit(cv)
			_px(cv, -3, -12, "h")
			_px(cv, -2, -12, "h")
			_px(cv, -3, -11, "h")
			return [_casco_pronto(cv, _pal(_KIT, {"h": Color("d5f0aa")}))]
		Pecas.Tipo.KATANAS_GEMEAS:
			# uma katana reta na boca: cabo azul, guarda dourada e a lâmina longa e fina, com o fio mais claro em cima
			_ret(cv, 10, -11, 13, -9, "a")
			_ret(cv, 10, -10, 13, -9, "d")
			_ret(cv, 14, -12, 15, -8, "g")
			_ret(cv, 16, -11, 26, -10, "C")
			_ret(cv, 16, -10, 26, -9, "c")
			_px(cv, 27, -10, "C")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _pal(_KIT, {"a": _BAND_LEO["a"], "d": _BAND_LEO["d"], "C": Color("f0f4f8"), "c": Color("c8d0da")}))]
		Pecas.Tipo.CINTO_L:
			# cinto de campeão: plaquinha dourada no quadril (4x3) presa por uma tira curta de couro, com o L em azul escuro
			_txt(cv, -9, -9, [
				"tggg",
				"tgdg",
				"tGGG",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _pal(_KIT, {"d": _BAND_LEO["d"]}))]
		# ---------------------------------------------------------------- Donatemiau (Donatello)
		Pecas.Tipo.BANDANA_ROXA:
			_bandana(cv, fase, 1)
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _pal(_BAND_DONA, _OLHO, _pal(_PAL_FERRO, {"V": Color("c8f5d2")})))]
		Pecas.Tipo.CASCO_ENGENHOCAS:
			# o casco do kit com uma mochilinha de engenhocas sobre o domo: caixa cinza pequena, antena fina e a lâmpada acesa
			_casco_kit(cv)
			var mo: Dictionary = {}
			_ret(mo, -7, -15, -3, -14, "i")
			_px(mo, -5, -16, "i")
			_px(mo, -5, -17, "i")
			_ret(mo, -6, -19, -4, -18, "Y")
			_luz(mo, "i", "", "j")
			_cont(mo, "o")
			cv.merge(mo, true)
			return [_casco_pronto(cv, _pal(_KIT, _PAL_FERRO, {"Y": Color("ffe97a")}))]
		Pecas.Tipo.BASTAO_BO:
			# bô de madeira com ponteiras de ferro e uma faixa roxa na pegada, saindo da boca em diagonal suave
			_lin(cv, Vector2i(10, -9), Vector2i(26, -15), "u")
			_lin(cv, Vector2i(10, -10), Vector2i(26, -16), "t")
			_lin(cv, Vector2i(10, -9), Vector2i(12, -9), "i")
			_lin(cv, Vector2i(10, -10), Vector2i(12, -10), "i")
			_lin(cv, Vector2i(25, -15), Vector2i(26, -15), "i")
			_lin(cv, Vector2i(25, -16), Vector2i(26, -16), "i")
			for k in cv.keys():
				var v: Vector2i = k
				if v.x >= 17 and v.x <= 18 and cv[v] != "i":
					cv[v] = "a"
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _pal(_KIT, _PAL_FERRO, {"a": _BAND_DONA["a"]}))]
		Pecas.Tipo.COMPUTADOR_PULSO:
			# computador de pulso no dorso: caixa cinza, tela verde com a linha do gráfico e dois botões
			_txt(cv, -9, -19, [
				".iiiiii.",
				"ikkvkkki",
				"ikvkvkvi",
				"iiiiiiii",
				"iYiiiwii",
				".jjjjjj.",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _pal(_KIT, _PAL_FERRO, {"Y": Color("ffe97a"), "k": _KIT["o"], "w": _OLHO["w"]}))]
		# ---------------------------------------------------------------- Rafamiau (Raphael)
		Pecas.Tipo.BANDANA_VERMELHA:
			_bandana(cv, fase, 2)
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _pal(_BAND_RAFA, _OLHO))]
		Pecas.Tipo.CASCO_ARRANHADO:
			# o casco do kit, mais riscado: 3 arranhões fixos no domo
			_casco_kit(cv)
			for p in [Vector2i(-6, -11), Vector2i(-5, -10), Vector2i(-4, -9)]:
				_px(cv, p.x, p.y, "o")
			for p2 in [Vector2i(-2, -11), Vector2i(-1, -10), Vector2i(0, -9)]:
				_px(cv, p2.x, p2.y, "o")
			return [_casco_pronto(cv, _KIT)]
		Pecas.Tipo.PAR_DE_SAIS:
			# um sai só, de perfil: cabo escuro com a empunhadura, guarda em cruz e três pontas (espeto central longo e dois dentes
			# curtos que viram para a frente)
			_ret(cv, 10, -10, 14, -9, "u")
			_ret(cv, 11, -10, 12, -9, "t")
			_ret(cv, 15, -14, 16, -5, "i")
			_ret(cv, 17, -10, 26, -9, "i")
			_ret(cv, 17, -10, 26, -10, "I")
			_ret(cv, 17, -14, 21, -13, "i")
			_ret(cv, 17, -6, 21, -5, "i")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _pal(_KIT, _PAL_FERRO))]
		Pecas.Tipo.CINTO_R:
			# cinto mal-humorado: a plaquinha torta no quadril, com um trapo vermelho pendurado
			_txt(cv, -9, -9, [
				"tggg",
				"tgdg",
				"aGGG",
				"a...",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _pal(_KIT, {"a": _BAND_RAFA["a"], "d": _BAND_RAFA["d"]}))]
	return _montar_b(tipo, fase)

## Ferro e cinza compartilhados (óculos, mochila, sai, bô, computador, punho da faca): i/I/j médio, luz e sombra.
const _PAL_FERRO := {"i": Color("8c9aa6"), "I": Color("c5d0d8"), "j": Color("58626e"), "v": Color("5fd08a")}

static func _montar_b(tipo: int, fase: int) -> Array:
	var cv: Dictionary = {}
	match tipo:
		# ---------------------------------------------------------------- Rocket Miaugue (Octane, Rocket League)
		Pecas.Tipo.PARABRISA_CAPACETE:
			# capacete pequeno: touca azul no alto da cabeça e a viseira escura em cunha na testa (olho e focinho à mostra), com a antena atrás
			_txt(cv, 3, -15, [
				".aaaaa..",
				"aaaavvvv",
			])
			_luz(cv, "a", "b", "d")
			_px(cv, 9, -14, "V")
			_txt(cv, 0, -20, [
				"nn..",
				"nn..",
				".mm.",
				"..mm",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_ROCKET)]
		Pecas.Tipo.CARROCERIA_TURBO:
			# gato vestido de carro (Octane): nariz alto e grosso, capô comprido e reto, cabine curta e recuada com o para-brisa inclinado,
			# traseira mais alta com o aerofólio baixo atrás, rodas de trás maiores; azul com detalhes laranja
			var topo: Dictionary = {-10: -12, -9: -12, -8: -13, -7: -14, -6: -14, -5: -14, -4: -14, -3: -14, -2: -13, -1: -12, 0: -11}
			for xx in range(1, 10):
				topo[xx] = -10
			topo[10] = -8
			for xc in topo.keys():
				for yc in range(int(topo[xc]), -3):
					cv[Vector2i(xc, yc)] = "a"
			_txt(cv, -6, -13, [
				"vvvv.",
				"vvvvv",
				"vvvvvv",
			])
			_px(cv, -5, -12, "V")
			_px(cv, -4, -13, "V")
			_txt(cv, -3, -9, [
				"..ff.",
				".fffn",
				"fnnnf",
				".ffff",
			])
			_ret(cv, -9, -5, 9, -4, "d")
			_ret(cv, -9, -3, 9, -3, "k")
			_px(cv, 10, -7, "n")
			_px(cv, 10, -6, "n")
			_px(cv, -10, -10, "F")
			_px(cv, -10, -11, "F")
			_luz(cv, "a", "b", "")
			_ret(cv, 2, -10, 8, -10, "b")
			_roda6(cv, -11, -8)
			_roda(cv, 4, -7)
			_cont(cv, "o", false)
			var at: Dictionary = {}
			_txt(at, -14, -15, [
				"ffffff",
				"FFFFFF",
				"..d.d.",
			])
			_cont(at, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_ROCKET), _lay(at, RoupaGato.Onde.CORPO, _PAL_ROCKET, true)]
		Pecas.Tipo.BOLA_COSMICA:
			# bola de Rocket League: branca, sombreada embaixo, com um hexágono central de linhas ciano e meios hexágonos nas bordas
			_txt(cv, 12, -19, [
				"..MMMMMM..",
				".MMMMMMMM.",
				"MMMMMMMMMM",
				"MMMMMMMMMM",
				"MMMMMMMMMM",
				"MMMMMMMMMM",
				"MMMMMMMMMM",
				"MMMMMMMMMM",
				".MMMMMMMM.",
				"..MMMMMM..",
			])
			var hx: Dictionary = {}
			_poli(hx, [17.0, -17.0, 19.6, -15.5, 19.6, -12.5, 17.0, -11.0, 14.4, -12.5, 14.4, -15.5], "H")
			_anel(hx, "H", "x")
			for k in hx.keys():
				if hx[k] == "x":
					cv[k] = "x"
			_px(cv, 12, -15, "x")
			_px(cv, 12, -14, "x")
			_px(cv, 21, -16, "x")
			_px(cv, 20, -17, "x")
			_px(cv, 20, -11, "x")
			_px(cv, 21, -12, "x")
			for k2 in cv.keys():
				var v: Vector2i = k2
				if cv[v] == "M" and (v.x - 16) + (v.y + 14) > 3:
					cv[v] = "q"
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_ROCKET)]
		Pecas.Tipo.PROPULSOR_TURBO:
			# bocal cinza e chama laranja de três degraus (borda, miolo, núcleo claro) que alterna de tamanho
			var cp: int = 8 if fase == 0 else 6
			_ret(cv, -14 - cp, -10, -14, -7, "F")
			_ret(cv, -14 - cp + 2, -10, -14, -8, "f")
			_ret(cv, -14 - cp + 4, -9, -14, -8, "n")
			_ret(cv, -13, -10, -11, -7, "m")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.TRASEIRA, _PAL_ROCKET, true)]
		# ---------------------------------------------------------------- Deadmiau (Deadpool)
		Pecas.Tipo.MASCARA_VERMELHA:
			# cabeça redonda inteira de tecido vermelho, colada na do gato (cobre as orelhas): a mancha preta da frente, grande e inclinada
			# (desce para o focinho), com o olho branco dentro; a de trás aparece pequena no perfil; costura fina escura na testa
			_txt(cv, 3, -17, [
				".aaaaa.",
				"aaaaaaa",
				"aaaaaaa",
				"aaaaaaa",
				"aaaaaaa",
				"aaaaaaa",
				"aaaaaaa",
				".aaaaa.",
			])
			_luz(cv, "a", "b", "d")
			_px(cv, 6, -17, "d")
			_px(cv, 6, -16, "d")
			_txt(cv, 5, -15, [
				".kk..",
				"kkkk.",
				"kwwkk",
				".kwwk",
				"..kkk",
			])
			_px(cv, 3, -14, "k")
			_px(cv, 3, -13, "k")
			_px(cv, 4, -13, "w")
			_px(cv, 4, -12, "k")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_DEAD)]
		Pecas.Tipo.TRAJE_REMENDADO:
			# traje bicolor: vermelho no peito e preto nas costas e na barriga (divisão limpa), cinto preto fino com a fivela bege e um
			# remendo; atrás do corpo, os dois cabos das katanas cruzadas nas costas
			RoupaGatoF._tronco(cv, "a", -12, -5)
			_luz(cv, "a", "b", "d")
			for k in cv.keys():
				var v: Vector2i = k
				if v.x <= -7 + (v.y + 12) * 2 / 7:
					cv[v] = "p"
			_luz(cv, "p", "P", "")
			_ret(cv, -8, -7, 7, -6, "p")
			_ret(cv, 2, -7, 4, -6, "C")
			_px(cv, 3, -7, "c")
			_ret(cv, 0, -11, 1, -10, "m")
			_cont(cv, "o", false)
			var at: Dictionary = {}
			_txt(at, -9, -17, [
				"C.....C",
				"pp...pp",
				".pp.pp.",
				"..ppp..",
			])
			_cont(at, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_DEAD), _lay(at, RoupaGato.Onde.CORPO, _PAL_DEAD, true)]
		Pecas.Tipo.KATANAS_PAPELAO:
			# duas katanas de papelão (bege, fita cinza no cabo): uma reta na boca e outra cruzando, dobrada com um degrau e a ponta caída
			_ret(cv, 10, -11, 13, -9, "g")
			_ret(cv, 14, -12, 15, -8, "D")
			_ret(cv, 15, -11, 24, -10, "L")
			_ret(cv, 15, -10, 24, -9, "c")
			for i in 5:
				_px(cv, 13 + i, -6 - i, "c")
				_px(cv, 14 + i, -6 - i, "L")
			for i2 in 3:
				_px(cv, 13 + i2, -6 - i2, "g")
				_px(cv, 14 + i2, -6 - i2, "g")
			_px(cv, 19, -11, "L")
			_px(cv, 20, -11, "L")
			_px(cv, 21, -11, "L")
			_px(cv, 22, -10, "L")
			_px(cv, 22, -9, "c")
			_px(cv, 23, -9, "c")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_DEAD)]
		Pecas.Tipo.CHIMICHANGA:
			# chimichanga dourada no dorso, com duas dobras, o recheio saindo e a bandeirinha de palito
			_txt(cv, -15, -21, [
				"..xx....",
				"..xx.rrr",
				"..xx.rr.",
				"..xx....",
				"YYYYYYYY",
				"yyDyyDyr",
				"yyDyyDrr",
				"zzzzzzzz",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _pal(_PAL_DEAD, {"x": Color("9c7c4f"), "r": _PAL_DEAD["a"], "D": Color("a66f26")}))]
		# ---------------------------------------------------------------- Meon (Leon, Resident Evil 4 Remake)
		Pecas.Tipo.FRANJA_LOIRA:
			# cabelo do Leon: repartido no alto, curto na nuca e a franja varrida para a frente, caindo na frente do olho; as pontas
			# das orelhas ficam de fora (orelha da frente em x 6..8 / y -18..-16, olho em x 7 / y -13)
			_txt(cv, 3, -17, [
				"hhh......",
				"hhh...hhh",
				"hhh..hhhh",
				"hh.....hh",
				"h.......h",
			])
			_luz(cv, "h", "H", "s")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_MEON)]
		Pecas.Tipo.JAQUETA_COURO:
			# jaqueta de couro: gola de pelo creme com dentes, tira preta no peito e o coldre com o cabo da pistola
			# (tudo dentro do molde do tronco; a gola desce em diagonal pela costura do pescoço, do dorso até o peito)
			# a barra fica em y -6, na linha da barriga, com os cantos de baixo arredondados: o alto das patas fica à mostra
			RoupaGatoF._tronco(cv, "j", -12, -6)
			cv.erase(Vector2i(-8, -6))
			cv.erase(Vector2i(7, -6))
			_luz(cv, "j", "J", "d")
			_txt(cv, 0, -12, [
				"CCC..",
				"CCCC.",
				".cCCC",
				"...cC",
			])
			_lin(cv, Vector2i(6, -9), Vector2i(3, -6), "p")
			_lin(cv, Vector2i(7, -9), Vector2i(4, -6), "p")
			_ret(cv, -4, -9, -3, -6, "p")
			_ret(cv, -4, -11, -3, -10, "i")
			_px(cv, -5, -10, "I")
			_cont(cv, "o", false)
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MEON)]
		Pecas.Tipo.FACA_TATICA:
			# pistola semiautomática de perfil: ferrolho cinza-escuro reto com o cano na ponta, armação preta com a guarda do gatilho e o
			# punho inclinado para trás (o punho é onde o gato a segura); tamanho de uns 11 px, proporcional à pata
			_txt(cv, 10, -13, [
				"..IIIIIII.",
				"..SSSSSSSS",
				"..pppppp..",
				"..ppp.p.p.",
				".ppp.ppp..",
				".ppp......",
				"SSS.......",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_MEON)]
		Pecas.Tipo.MALETA_MERCADOR:
			# a maleta do Mercador pendurada no flanco: couro marrom com a tampa clara, alça curta em cima, costura no meio e dois
			# trincos dourados
			_txt(cv, -7, -10, [
				"..pppp..",
				"MMMMMMMM",
				"mymmmmym",
				"nnnnnnnn",
				"mmmmmmmm",
				"mmmmmmmm",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MEON)]
	return []

## Roda de trás do carro (6x6, maior): pneu preto com brilho, aro cinza e miolo claro.
static func _roda6(cv: Dictionary, x: int, y: int) -> void:
	_txt(cv, x, y, [
		".kkkk.",
		"kKkkkk",
		"kkmmkk",
		"kkmMkk",
		"kkkkkk",
		".kkkk.",
	])

## Roda do carro (5x5): pneu preto com brilho, aro cinza e miolo claro; (x, y) = canto de cima à esquerda.
static func _roda(cv: Dictionary, x: int, y: int) -> void:
	_txt(cv, x, y, [
		".kkk.",
		"kKmkk",
		"kmMmk",
		"kkmkk",
		".kkk.",
	])

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
