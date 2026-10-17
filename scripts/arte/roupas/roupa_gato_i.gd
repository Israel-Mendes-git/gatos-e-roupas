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
## Miau-Noir (frio e quase monocromático, como a referência dos quadrinhos): o contorno; h/H/s chapéu (médio, luz, sombra); f/F/e faixa do chapéu
## (médio, luz, sombra); c/C/S sobretudo grafite-azulado (médio, luz, sombra); m máscara cinza; g linha de teia; L lente branca (só ela é branca pura);
## l vidro do lampião; q branco sujo (quadros do filme); t/T/u latão (médio, luz, sombra); p película; w arame e cinto.
const _PAL_NOIR := {
	"o": Color("0a0c12"), "h": Color("1c2029"), "H": Color("3a4658"), "s": Color("10131a"),
	"f": Color("4a566c"), "F": Color("8c9ab2"), "e": Color("2c3444"),
	"c": Color("3e4a60"), "C": Color("7a8eac"), "S": Color("222a3a"),
	"m": Color("a8b2c2"), "g": Color("1a202c"), "L": Color("f6f8fc"), "l": Color("c4ccd8"), "q": Color("e8eaee"),
	"t": Color("a68a5a"), "T": Color("d2b882"), "u": Color("6e5a38"), "p": Color("22262e"), "w": Color("5a6478"),
}
## Hollowmiau: o contorno; w/W/d osso (médio, luz, sombra); k/e olho (preto, brilho); a/b/D manto grafite-azulado (médio, luz, sombra); n/N/s aço
## do prego (médio, luz, sombra); u couro do punho; g vidro da ampola (e a alma, em W).
const _PAL_HOLLOW := {
	"o": Color("0c0b14"), "w": Color("edeae0"), "W": Color("ffffff"), "d": Color("b9b6b0"),
	"k": Color("14121c"), "e": Color("3a3850"),
	"a": Color("3d414f"), "b": Color("5e647a"), "D": Color("262833"),
	"n": Color("b8c0cc"), "N": Color("e8eef4"), "s": Color("6e7888"), "u": Color("3a2e3e"), "g": Color("8ec8f0"),
	"l": Color("b6afd2"), "m": Color("726a95"), "r": Color("2a2438"),
}
## Silkmiau: o contorno; w/W/d osso (médio, luz, sombra); k olho; a/b/D capa bordô (médio, luz, sombra); n/N/m fio e novelo (médio, luz,
## sombra); s/S/z aço da agulha (médio, luz, sombra).
const _PAL_SILK := {
	"o": Color("0c0b14"), "w": Color("edeae0"), "W": Color("ffffff"), "d": Color("b9b6b0"), "k": Color("14121c"),
	"a": Color("7c3048"), "b": Color("a65870"), "D": Color("4c1c2e"),
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
## Treinador de Miaumons: o contorno (e a faixa e o botão da bola); r/R/d vermelho (médio, luz, sombra); w/W branco (médio, sombra); a/b/v colete
## azul (médio, luz, sombra); K camiseta preta; g/G/n verde (médio, claro, escuro: luvas e mochila); y laranja da mochila; p/P/q Pikachu (médio, luz,
## sombra); z base marrom do rabo.
const _PAL_TREI := {
	"o": Color("1a0a10"), "k": Color("1a0a10"), "r": Color("d63c3c"), "R": Color("f27872"), "d": Color("8c1e26"),
	"w": Color("f0f0f0"), "W": Color("b8bac4"),
	"a": Color("3a62b8"), "b": Color("6c92e0"), "v": Color("223c7c"), "K": Color("2a2a3c"),
	"g": Color("4a9a50"), "G": Color("a8d070"), "n": Color("2a6034"), "y": Color("e8883a"),
	"p": Color("f2d040"), "P": Color("ffee88"), "q": Color("c09a20"), "z": Color("8a5a30"),
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

## Capa bordô da Silkmiau em sino, atrás do corpo: acompanha o dorso, alarga para trás e para baixo e a barra acaba em bicos
## (os bicos andam 2 px entre os dois quadros, `fase` 0 ou 1).
static func _capa_silk(fase: int) -> Dictionary:
	var cv: Dictionary = {}
	var lobo: Array = [0, 1, 2, 1]
	for x in range(-14, 5):
		var topo: int
		if x >= -8:
			topo = int(_TOPO_CORPO[x]) + 2
		else:
			topo = mini(-8 + (-9 - x), -4)
		var hem: int = -1 - int(lobo[((x + fase * 2 + 1) % 4 + 4) % 4])
		if x < -9:
			hem = mini(hem, -1 + int(ceil((x + 9) * 0.7)))
		for y in range(topo, hem + 1):
			cv[Vector2i(x, y)] = "a"
	return cv

## Colunas ocupadas (topo e base) de `cv` na coluna x; [99, -99] se vazia.
static func _extremos(cv: Dictionary, x: int) -> Array:
	var t: int = 99
	var b: int = -99
	for y in range(-20, 3):
		if cv.has(Vector2i(x, y)):
			t = mini(t, y)
			b = maxi(b, y)
	return [t, b]

## Manto do Hollowmiau: poncho grafite de dobras verticais inclinadas e barra em pontas (período de 5 colunas: 0, 2, 0, 3, 1 px de ponta),
## mais alto nos lados e em arco sob a barriga e no peito para as patas aparecerem; a camada de trás cai pela anca.
static func _manto_hollow() -> Array:
	var cv: Dictionary = {}
	var dente: Array = [0, 2, 0, 3, 1]
	for x in range(-8, 9):
		var base: int = -6
		if x == -8 or x == 8:
			base = -8
		elif x == -7 or x == 7:
			base = -7
		elif x >= -2 and x <= 2:
			base = -7
		elif x >= 4 and x <= 6:
			base = -5
		var hem: int = base - 2 + int(dente[posmod(x + 1, 5)])
		for y in range(int(_TOPO_CORPO[x]) - (1 if (x >= -3 and x <= 2) else 0), hem + 1):
			cv[Vector2i(x, y)] = "a"
	_gola(cv, "a")
	for x in range(-8, 9):
		if posmod(x + 1, 5) != 0:
			continue
		var ci: Array = _extremos(cv, x)
		var t0: int = int(ci[0])
		for y in range(t0 + 3, int(ci[1]) + 1):
			var xx: int = x - int((y - t0) / 4.0)
			if cv.has(Vector2i(xx, y)):
				cv[Vector2i(xx, y)] = "D"
			if cv.has(Vector2i(xx + 1, y)) and cv[Vector2i(xx + 1, y)] == "a" and y < int(ci[1]):
				cv[Vector2i(xx + 1, y)] = "b"
	for x2 in range(-8, 9):
		var tp := Vector2i(x2, int(_extremos(cv, x2)[0]))
		if cv.get(tp) == "a":
			cv[tp] = "b"
	_px(cv, 3, -15, "D")
	_px(cv, 3, -14, "D")
	_px(cv, 4, -8, "W")
	_cont(cv, "o", true)
	var bk: Dictionary = {}
	for x3 in range(-14, -1):
		var top: int = -9
		if x3 < -8:
			top = -9 + (-8 - x3)
		var hm: int = -5 + int(dente[posmod(x3 + 1, 5)])
		if x3 < -9:
			hm = mini(hm, -5 - (-9 - x3) + int(dente[posmod(x3 + 1, 5)]))
		for y in range(top, hm + 1):
			bk[Vector2i(x3, y)] = "a"
	for x4 in range(-14, -1):
		if posmod(x4 + 1, 5) != 0:
			continue
		var cb: Array = _extremos(bk, x4)
		for y in range(int(cb[0]) + 2, int(cb[1]) + 1):
			var xb: int = x4 - int((y - int(cb[0])) / 4.0)
			if bk.has(Vector2i(xb, y)):
				bk[Vector2i(xb, y)] = "D"
			if bk.has(Vector2i(xb + 1, y)) and bk[Vector2i(xb + 1, y)] == "a" and y < int(cb[1]):
				bk[Vector2i(xb + 1, y)] = "b"
	_cont(bk, "o", true)
	return [_lay(bk, RoupaGato.Onde.CORPO, _PAL_HOLLOW, true), _lay(cv, RoupaGato.Onde.CORPO, _PAL_HOLLOW)]

## Máscara da Hornet: casco branco em gota invertida (largo no alto, afina até o queixo), dois chifres grossos na base que abrem em U
## e afinam até a ponta (o da frente, maior, arqueia para a frente e a ponta volta para dentro; o de trás, sombreado, abre para trás e
## a ponta também volta) e dois olhos pretos triangulares grandes, com a ponta para dentro e para baixo.
static func _mascara_silk() -> Dictionary:
	var cv: Dictionary = {}
	_txt(cv, 4, -19, [".wwwww.", "wwwwwww", "wwwwwww", "wwwwwww", "wwwwwww", "wwwwwww", ".wwwwww", ".wwwww.", "..wwww.", "...www.", "....w.."])
	_canto(cv, "w", "d")
	var h: Dictionary = {}
	for s in [[-20, 7, 9], [-21, 8, 10], [-22, 9, 11], [-23, 9, 11], [-24, 9, 10], [-25, 9, 10], [-26, 9, 10], [-27, 8, 9], [-28, 8, 8]]:
		for x in range(int(s[1]), int(s[2]) + 1):
			h[Vector2i(x, int(s[0]))] = "w"
	_canto(h, "w", "d")
	for s2 in [[-20, 4, 6], [-21, 3, 5], [-22, 3, 4], [-23, 2, 3], [-24, 2, 3], [-25, 1, 2], [-26, 1, 2], [-27, 2, 2], [-28, 2, 2]]:
		for x2 in range(int(s2[1]), int(s2[2]) + 1):
			h[Vector2i(x2, int(s2[0]))] = "d"
	for k in h.keys():
		if not cv.has(k):
			cv[k] = h[k]
	for s3 in [[-17, 8, 10], [-16, 8, 10], [-15, 8, 9], [-14, 8, 9], [-13, 8, 8], [-17, 4, 6], [-16, 4, 6], [-15, 5, 6], [-14, 5, 6], [-13, 6, 6]]:
		for x3 in range(int(s3[1]), int(s3[2]) + 1):
			cv[Vector2i(x3, int(s3[0]))] = "k"
	_px(cv, 6, -18, "W")
	_px(cv, 5, -17, "W")
	_cont(cv, "o")
	return cv

## Agulha da Hornet (17 px): anel redondo na ponta de trás (o fio passa por ele) e haste de 1 px até a ponta.
static func _agulha_silk() -> Dictionary:
	var cv: Dictionary = {}
	for r in [[-13, 12, 14], [-12, 11, 11], [-12, 15, 15], [-11, 11, 11], [-11, 15, 15], [-10, 11, 11], [-10, 15, 15], [-9, 12, 14]]:
		for x in range(int(r[1]), int(r[2]) + 1):
			cv[Vector2i(x, int(r[0]))] = "s"
	for x2 in range(16, 28):
		cv[Vector2i(x2, -11)] = "s"
	for x3 in range(12, 15):
		cv[Vector2i(x3, -13)] = "S"
		cv[Vector2i(x3, -9)] = "z"
	for t in [Vector2i(12, -12), Vector2i(12, -11), Vector2i(12, -10), Vector2i(12, -9), Vector2i(12, -8), Vector2i(13, -7), Vector2i(13, -6), Vector2i(12, -5), Vector2i(12, -4)]:
		cv[t] = "n"
	_cont(cv, "o")
	return cv

## Topo do corpo vestido justo (costas rente ao dorso do gato), usado pelas roupas refeitas pela referência (lote 4: Miaujin, Arqueólogo, Treinador).
const _TOPO_VEST := {-8: -9, -7: -10, -6: -11, -5: -12, -4: -12, -3: -12, -2: -12, -1: -12, 0: -12, 1: -12, 2: -12, 3: -11, 4: -10, 5: -9, 6: -9, 7: -9, 8: -8}

## Triângulo de pixels: base x0..x1 (última linha `by`) e ponta em (tx, ty).
static func _tri(cv: Dictionary, x0: int, x1: int, by: int, tx: int, ty: int, ch: String) -> void:
	_poli(cv, [x0, by + 1, x1 + 1, by + 1, tx + 0.5, ty - 0.3], ch)

## Luz pelo lado: o pixel `base` sem vizinho à esquerda ou em cima vira `luz`; sem vizinho à direita ou embaixo, `sombra`.
static func _luz_lado(cv: Dictionary, base: String, luz: String, sombra: String) -> void:
	var m: Dictionary = {}
	for k in cv.keys():
		var v: Vector2i = k
		if cv[v] != base:
			continue
		if not cv.has(v + Vector2i(-1, 0)) or not cv.has(v + Vector2i(0, -1)):
			m[v] = luz
		elif not cv.has(v + Vector2i(1, 0)) or not cv.has(v + Vector2i(0, 1)):
			m[v] = sombra
	for k2 in m.keys():
		cv[k2] = m[k2]


## Corpo vestido justo: `th` = barra sobre a anca e a pata de trás, `bh` = sob a barriga, `fh` = sobre o peito e a pata da frente.
static func _corpo_vest(cv: Dictionary, ch: String, th: int, bh: int, fh: int, topo: Dictionary = _TOPO_VEST) -> void:
	for x in range(-8, 9):
		var b: int
		if x == -8:
			b = th - 1
		elif x <= -4:
			b = th
		elif x == -3:
			b = (th + bh) / 2
		elif x <= 2:
			b = bh
		elif x == 3:
			b = (bh + fh) / 2
		elif x <= 7:
			b = fh
		else:
			b = fh - 1
		for y in range(int(topo[x]), b + 1):
			cv[Vector2i(x, y)] = ch

## Cabelo do Super Miaujin: cinco espetos dourados de alturas desiguais inclinados para trás, mecha na testa e sobrancelha brava.
static func _mj_cabelo() -> Array:
	var cv: Dictionary = {}
	_ret(cv, 2, -18, 12, -15, "h")
	_ret(cv, 3, -15, 5, -13, "h")
	_tri(cv, 1, 3, -19, 0, -23, "h")
	_tri(cv, 3, 5, -19, 1, -26, "h")
	_tri(cv, 5, 7, -19, 4, -27, "h")
	_tri(cv, 7, 9, -19, 7, -26, "h")
	_tri(cv, 9, 11, -19, 11, -24, "h")
	_tri(cv, 8, 11, -16, 11, -13, "h")
	_luz_lado(cv, "h", "H", "d")
	_cont(cv, "o")
	_ret(cv, 8, -14, 11, -13, "o")
	return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_MIAUJIN)]

## Gi do Goku: decote em V azul-escuro, faixa azul em volta da barriga (nó e pontas), calça e mangas com munhequeiras e botas azuis.
static func _mj_gi() -> Array:
	var cv: Dictionary = {}
	_corpo_vest(cv, "a", -5, -7, -5)
	_luz(cv, "a", "b", "D")
	# decote em V: camisa azul-escura no peito
	for p in [Vector2i(5, -10), Vector2i(6, -10), Vector2i(7, -10), Vector2i(5, -9), Vector2i(6, -9), Vector2i(7, -9), Vector2i(6, -8), Vector2i(7, -8), Vector2i(7, -7)]:
		if cv.has(p):
			cv[p] = "V"
	_linsobre(cv, Vector2i(3, -11), Vector2i(5, -9), "b")
	_linsobre(cv, Vector2i(4, -11), Vector2i(5, -10), "b")
	# faixa: banda de 3 colunas em volta da barriga, com no e pontas
	var fx: int = -3
	for y in range(-13, -4):
		for x in range(fx, fx + 3):
			if cv.has(Vector2i(x, y)):
				cv[Vector2i(x, y)] = "u" if x == fx + 1 else ("U" if x == fx else "V")
	_px(cv, fx + 3, -8, "u")
	_px(cv, fx + 4, -8, "V")
	_px(cv, fx + 3, -7, "V")
	_px(cv, fx + 3, -6, "V")
	# dobras do pano
	_dobras(cv, [-6, 2], "D")
	# munhequeiras e botas azuis
	for x in range(5, 8):
		cv[Vector2i(x, -5)] = "u"
		cv[Vector2i(x, -4)] = "V"
	for x2 in range(-8, -4):
		cv[Vector2i(x2, -5)] = "u"
		cv[Vector2i(x2, -4)] = "V"
	_cont(cv, "o", false)
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_MIAUJIN)]

## Fedora do Indy: copa alta com vinco, faixa escura e aba que cai na frente.
static func _aq_chapeu() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 1, -23, ["...hhhhh....", "..hhhshhh...", "..hhhshhh...", "..hhhshhh...", "..ffffffff..", ".hhhhhhhhhhh", "hh.......hhh"])
	_luz(cv, "h", "H", "s")
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_ARQ4)]

## Jaqueta de couro aberta sobre a camisa cáqui, tira a tiracolo, bolsa no flanco e punhos cáqui.
static func _aq_jaqueta() -> Array:
	var cv: Dictionary = {}
	_corpo_vest(cv, "j", -5, -7, -5)
	_luz(cv, "j", "J", "S")
	# camisa cáqui aparecendo na frente aberta do peito e na gola
	for y in range(-10, -5):
		for x in range(5, 8):
			if cv.has(Vector2i(x, y)) and not (x == 5 and y == -10):
				cv[Vector2i(x, y)] = "k"
	_px(cv, 7, -6, "K")
	_px(cv, 6, -6, "K")
	_px(cv, 7, -7, "K")
	_ret(cv, 3, -12, 5, -10, "S")
	_px(cv, 4, -10, "k")
	# tira a tiracolo, do ombro ao quadril
	_linsobre(cv, Vector2i(4, -11), Vector2i(-3, -6), "l")
	_dobras(cv, [-6, 1], "S")
	# punhos cáqui nas mangas
	for x in range(5, 8):
		cv[Vector2i(x, -5)] = "K"
	_cont(cv, "o", false)
	var bolsa: Dictionary = {}
	_txt(bolsa, -7, -9, [".mmm.", "mlllm", "mlllm", "mllgm", ".mmm."])
	_cont(bolsa, "o")
	for k in bolsa.keys():
		cv[k] = bolsa[k]
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_ARQ4)]

## Chicote em S: laço enrolado no punho e a cauda de corda que sobe, desce e esfia.
static func _aq_chicote() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 11, -14, [".cc.", "cxxc", "cxxc", ".cc."])
	var pts: Array = [[15, -12], [16, -12], [17, -13], [18, -14], [19, -15], [20, -15], [21, -15], [22, -14], [23, -13], [24, -12], [25, -12]]
	for i in pts.size():
		var q: Array = pts[i]
		cv[Vector2i(q[0], q[1])] = "c"
		if i < 6:
			cv[Vector2i(q[0], q[1] + 1)] = "x" if i % 2 == 0 else "c"
	var l: Array = pts[pts.size() - 1]
	cv[Vector2i(l[0] + 1, l[1] + 1)] = "c"
	cv[Vector2i(l[0] + 1, l[1] - 1)] = "c"
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.BOCA, _PAL_ARQ4)]

## Boné de Kanto: copa vermelha, painel branco com o "L" verde e aba para a frente.
static func _tr_bone() -> Array:
	var cv: Dictionary = {}
	_txt(cv, 2, -23, ["..rrrrrr....", ".rrrrwwww...", "rrrrrwgwww..", "rrrrrwgwww..", "rrrrrwggww..", "rrrrrrrrrrrr", "........rrrr"])
	_luz(cv, "r", "R", "d")
	_luz(cv, "w", "w", "W")
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_TREI)]

## Colete azul sobre a camiseta preta, gola e mangas brancas, luvas verdes sem dedos; atrás, a ponta da mochila verde.
static func _tr_colete() -> Array:
	var cv: Dictionary = {}
	_corpo_vest(cv, "a", -5, -7, -5)
	_luz(cv, "a", "b", "v")
	# camiseta preta no peito aberto do colete, gola branca, manga curta branca
	for y in range(-10, -6):
		for x in range(5, 8):
			if cv.has(Vector2i(x, y)) and not (x == 5 and y == -10):
				cv[Vector2i(x, y)] = "K"
	_ret(cv, 3, -12, 6, -11, "w")
	_px(cv, 6, -11, "w")
	_px(cv, 7, -10, "w")
	for y in range(-7, -5):
		for x in range(5, 8):
			if cv.has(Vector2i(x, y)):
				cv[Vector2i(x, y)] = "w"
	# luvas verdes sem dedos, punho amarelo-esverdeado
	for x in range(5, 8):
		cv[Vector2i(x, -5)] = "G"
		cv[Vector2i(x, -4)] = "g"
	_linsobre(cv, Vector2i(1, -12), Vector2i(5, -9), "v")
	_dobras(cv, [-6, 0], "v")
	_px(cv, -3, -9, "b")
	_cont(cv, "o", false)
	var mo: Dictionary = {}
	_poli(mo, [-7, -11.5, -9.5, -11.5, -11.5, -10, -12, -7.5, -11.5, -4.5, -9, -4, -7, -5], "g")
	_luz(mo, "g", "G", "n")
	_ret(mo, -11, -8, -9, -6, "y")
	_cont(mo, "o")
	return [_lay(mo, RoupaGato.Onde.CORPO, _PAL_TREI, true), _lay(cv, RoupaGato.Onde.CORPO, _PAL_TREI)]

## Pikachu sentado no dorso: orelhas de ponta preta, bochecha vermelha e o rabo em raio.
static func _tr_pika() -> Array:
	var cv: Dictionary = {}
	_txt(cv, -11, -23, ["..k.k...", ".pp.pp..", ".pp.pp..", ".pppppp.", ".ppoppp.", ".pprprp.", "..pppp..", "qqpppp..", "z.pppp.."])
	_luz(cv, "p", "P", "q")
	_cont(cv, "o")
	return [_lay(cv, RoupaGato.Onde.CORPO, _PAL_TREI)]

static func _montar(tipo: int, fase: int) -> Array:
	var cv: Dictionary = {}
	match tipo:
		# ---------------------------------------------------------------- Miau-Noir (Spider-Man Noir): monocromático
		Pecas.Tipo.FEDORA_TEIA:
			# fedora preto de copa alta (faixa azulada e brilho vertical) e aba larga caída; sob a aba, a máscara cinza com duas lentes brancas
			# redondas de aviador (aro escuro nos cantos de fora) e a teia em linhas escuras de 1 px; o focinho do gato fica à mostra
			_txt(cv, -1, -25, [
				"....hhhhhh....",
				"...hhHHhhhs...",
				"...hhHHhhhs...",
				"...hhHHhhhs...",
				"...hhHHhhhs...",
				"...hhHhhhhs...",
				"...ffFffffe...",
				"...ffffffee...",
				"hhhhHHhhhhhHHhh",
				".sssssssssssss.",
			])
			_txt(cv, 3, -15, [
				"gLLggLLg",
				"LLLgLLLL",
				"gLLggLLg",
				"mgmmgmg.",
				"mmgggm..",
				".mmgm...",
			])
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_NOIR)]
		Pecas.Tipo.SOBRETUDO_CINZA:
			# sobretudo transpassado grafite-azulado que segue o dorso curvo: gola alta levantada, lapela larga em diagonal, fileira dupla de botões,
			# cinto com fivela e a barra que sobe em arco sob a barriga, deixando as patas saírem
			_corpo(cv, "c", -4, -7, -4)
			_gola(cv, "c")
			_luz(cv, "c", "C", "S")
			_px(cv, 3, -15, "S")
			_px(cv, 3, -14, "S")
			_linsobre(cv, Vector2i(2, -12), Vector2i(5, -9), "C")
			_linsobre(cv, Vector2i(3, -12), Vector2i(6, -9), "C")
			_linsobre(cv, Vector2i(4, -12), Vector2i(7, -9), "S")
			_sobre(cv, -7, -6, 3, -5, "w")
			_sobre(cv, 3, -6, 9, -5, "w")
			_px(cv, 6, -6, "F")
			_dobras(cv, [-3, 2], "S")
			for b in [Vector2i(5, -8), Vector2i(7, -8), Vector2i(5, -6), Vector2i(7, -6)]:
				if cv.has(b):
					cv[b] = "F"
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
			_txt(cv, 0, -23, [
				"..ww......ww..",
				".ww........ww.",
				"ww..........ww",
				"www........www",
				".www......www.",
				"...wwwwwwww...",
				"....wwwwww....",
				"...wwwwwwww...",
				"...wwwwwkww...",
				"...wkkwkkkw...",
				"...wkkwkkkw...",
				"...wkkwkkkw...",
				"...wkkwwkww...",
				"....wwwwww....",
			])
			_canto(cv, "w", "d")
			_px(cv, 5, -17, "W")
			_px(cv, 4, -16, "W")
			_cont(cv, "o")
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_HOLLOW)]
		Pecas.Tipo.MANTO_PRETINHO:
			# manto grafite-azulado que cobre o corpo todo como um poncho fechado (gola alta, broche branco): faixas verticais de 1 px que
			# se inclinam como penas (vinco escuro e fio de luz) e a barra esfarrapada em pontas irregulares, com as patas saindo por baixo;
			# atrás do corpo, a mesma capa cai pela anca e afina para trás
			return _manto_hollow()
		Pecas.Tipo.PREGO_AFIADO:
			# o Ferrão Velho (a estaca do Cavaleiro): cabo fino e curto perto da boca e, logo depois, a lâmina larga (4 px) que afina até a ponta de 1 px;
			# a face é dividida ao meio (metade clara em cima, escura embaixo) e duas rachaduras escuras cortam a lâmina na diagonal
			_txt(cv, 11, -12, [
				"..lrll........",
				"mmllrllrlll...",
				"mmmmmrmmrmmmmm",
				"..mmmmrmmr....",
			])
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
		# ---------------------------------------------------------------- Silkmiau (Hornet): a máscara pontuda de chifres em U
		Pecas.Tipo.MASCARA_CASCA:
			# casco branco em gota invertida cobrindo o rosto todo, dois chifres curvos em U e olhos triangulares grandes
			cv = _mascara_silk()
			return [_lay(cv, RoupaGato.Onde.CABECA, _PAL_SILK)]
		Pecas.Tipo.CAPA_CARMESIM:
			# a capa bordô em sino cai ATRÁS do corpo (acompanha o dorso e alarga para trás; barra em bicos, balança em 2 quadros);
			# na frente só o top vermelho curto de gola alta, o cinto escuro e a saia que sobe em arco sob a barriga
			var cp: Dictionary = _capa_silk(fase)
			_luz(cp, "a", "b", "D")
			_cont(cp, "o")
			_corpo(cv, "a", -4, -6, -5)
			_gola(cv, "a")
			_luz(cv, "a", "b", "D")
			_px(cv, 3, -15, "D")
			_px(cv, 3, -14, "D")
			_linsobre(cv, Vector2i(3, -11), Vector2i(5, -9), "b")
			_dobras(cv, [-5, -2, 1], "D")
			for xb in range(-7, 8):
				if ((xb + fase * 2) % 4 + 4) % 4 == 0:
					var yb: int = -99
					for yy in range(-14, 0):
						if cv.has(Vector2i(xb, yy)):
							yb = yy
					if yb > -99:
						cv.erase(Vector2i(xb, yb))
			_cont(cv, "o", false)
			return [_lay(cp, RoupaGato.Onde.CORPO, _PAL_SILK, true), _lay(cv, RoupaGato.Onde.CORPO, _PAL_SILK)]
		Pecas.Tipo.AGULHA_GIGANTE:
			# agulha longa e fina: anel na ponta de trás (o fio vermelho passa por ele e cai ondulando) e haste de 1 px
			cv = _agulha_silk()
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
			# cabelo dourado de espetos grandes inclinados para trás (alturas desiguais), mecha na testa; o rosto do gato fica à mostra
			return _mj_cabelo()
		Pecas.Tipo.KIMONO_LARANJA:
			# gi laranja do Goku que segue o corpo, com decote azul, faixa azul em volta da barriga e munhequeiras e botas azuis
			return _mj_gi()
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
			# fedora do Indy: copa alta de vinco, faixa escura e aba larga
			return _aq_chapeu()
		Pecas.Tipo.JAQUETA_GASTA:
			# jaqueta de couro aberta sobre a camisa cáqui, tira a tiracolo e bolsa no flanco
			return _aq_jaqueta()
		Pecas.Tipo.CHICOTE_BARBANTE:
			# chicote de corda laranja: laço no punho e cauda em S esfiapada
			return _aq_chicote()
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
			# boné de Kanto: vermelho, painel branco com o L verde, aba para a frente
			return _tr_bone()
		Pecas.Tipo.MOCHILA_AMARELA:
			# colete azul sobre camiseta preta, mangas brancas, luvas verdes; atrás, a ponta da mochila verde
			return _tr_colete()
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
			# Pikachu sentado no dorso
			return _tr_pika()
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
