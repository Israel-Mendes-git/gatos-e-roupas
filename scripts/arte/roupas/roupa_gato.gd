class_name RoupaGato
extends RefCounted
## As roupas na versão para o gato: pixel art desenhado por código, na mesma grade de pixels do sprite do gato.
## Unidade de desenho: 1 = um pixel do gato. O gato olha para a direita (+x); y negativo é para cima.
## Cada peça é desenhada em torno da ORIGEM do lugar onde fica presa (ver Onde).

enum Onde { CABECA, CORPO, BOCA, TRASEIRA, PESCOCO, PATAS, ROSTO }

## Origem de cada lugar no gato parado, em pixels do gato, relativa ao centro do quadro (x) e ao chão (y):
## CABECA = topo do crânio, entre as orelhas; CORPO = centro do tronco; BOCA = ponta do focinho;
## TRASEIRA = alto da anca, onde nasce o rabo; PESCOCO = entre a cabeça e o tronco;
## PATAS = chão sob UMA pata: a peça desenha um só calçado em torno da origem (x de -3 a +3, y de -5 a 0)
## e quem chama a repete em cada pata, acompanhando o passo (ver patas()); ROSTO = entre os olhos.
const ORIGEM: Array[Vector2] = [
	Vector2(5.5, -16.0), Vector2(-0.5, -9.0), Vector2(11.0, -11.0), Vector2(-8.0, -12.0),
	Vector2(2.0, -11.0), Vector2(6.0, 0.0), Vector2(7.0, -13.0),
]
# qual linha de GatoDados.ANCORAS dá o movimento de cada lugar ao longo da animação
const _SEGUE: Array[int] = [0, 1, 0, 3, 0, 2, 0]
const _FAIXA := 21   # tipos por arquivo: A 0..20, B 21..41, C 42..62, D 63..83, E 84..99

## Origem do lugar `onde` no quadro `quadro` do atlas (acompanha a animação).
static func origem(onde: int, quadro: int) -> Vector2:
	var k: int = _SEGUE[onde]
	var d: Vector2 = GatoDados.ANCORAS[k][quadro] - GatoDados.ANCORAS[k][GatoDados.ATACAR]
	if onde == Onde.PATAS:
		d.y = 0.0
	return ORIGEM[onde] + d

## Patas do bicho parado quando não há dados de animação (frente e trás).
const PATAS_PADRAO: Array[Vector2] = [Vector2(-5.0, 0.0), Vector2(6.0, 0.0)]

## Pontos do chão sob cada pata do gato no quadro `quadro` (vazio quando ele está deitado ou sentado).
static func patas(quadro: int) -> Array:
	return GatoDados.PATAS[quadro]

## Peças de pata que vão numa pata só (a da frente), em vez de em todas.
static func so_pata_da_frente(tipo: int) -> bool:
	return Pecas.MOLDE[tipo] == Pecas.Tipo.GANCHO or tipo == Pecas.Tipo.LUVAS

## Onde a peça fica presa. Cabeça e corpo têm lugar fixo; a peça de mão vai na boca e o acessório na traseira,
## a não ser que o arquivo da peça escolha outro lugar em onde().
static func onde(tipo: int) -> int:
	match Pecas.SLOT[tipo]:
		Pecas.SLOT_CABECA:
			return Onde.CABECA
		Pecas.SLOT_CORPO:
			return Onde.CORPO
	var o: int = -1
	match tipo / _FAIXA:
		0:
			o = RoupaGatoA.onde(tipo)
		1:
			o = RoupaGatoB.onde(tipo)
		2:
			o = RoupaGatoC.onde(tipo)
		3:
			o = RoupaGatoD.onde(tipo)
		_:
			o = RoupaGatoE.onde(tipo)
	if o >= 0:
		return o
	# sem escolha do arquivo da peça: a de mão vai na boca; o acessório, na traseira
	return Onde.BOCA if Pecas.SLOT[tipo] == Pecas.SLOT_MAO else Onde.TRASEIRA

## Desenha a peça em torno da origem do transform atual (1 unidade = 1 pixel do gato).
static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	match tipo / _FAIXA:
		0:
			RoupaGatoA.desenhar(c, tipo, f, anim)
		1:
			RoupaGatoB.desenhar(c, tipo, f, anim)
		2:
			RoupaGatoC.desenhar(c, tipo, f, anim)
		3:
			RoupaGatoD.desenhar(c, tipo, f, anim)
		_:
			RoupaGatoE.desenhar(c, tipo, f, anim)

## Um retângulo de pixels.
static func r(c: CanvasItem, x: float, y: float, w: float, h: float, cor: Color, f: float = 0.0) -> void:
	c.draw_rect(Rect2(x, y, w + 0.03, h + 0.03), Desenho.b(cor, f))

## Desenho em pixels a partir de linhas de texto: cada letra é um pixel da cor `paleta[letra]`;
## ponto ou espaço é transparente. (x, y) é o canto de cima à esquerda.
## Retângulos já mesclados de cada sprite (chave: hash do desenho + paleta; a entrada guarda os dois para conferir).
## Os chamadores montam as linhas e a paleta de novo a cada quadro, então a chave é pelo conteúdo.
static var _cache_sprite: Dictionary = {}

## Colunas e linhas a mais para a peça cobrir um tronco maior que o do gato (bichos). Quem desenha liga antes e zera depois.
## Na largura a peça repete um trecho do meio, na altura linhas lisas de tecido: o pixel continua do mesmo tamanho e o centro no lugar.
static var esticar: Vector2i = Vector2i.ZERO
static var _cache_esticado: Dictionary = {}
## Molde ({Vector2i: true}, em pixels do bicho) que apara a peça: só fica o que cai sobre o tronco. `mascara_origem` = onde está
## a origem da peça nesse mesmo sistema; `mascara_id` = identidade do molde (uma por pose, ver BichoPx.quadro).
## Quem desenha liga antes e esvazia depois.
static var mascara: Dictionary = {}
static var mascara_origem: Vector2 = Vector2.ZERO
static var mascara_id: int = 0
## Peças já esticadas e aparadas, prontas para desenhar: [retângulos, cores, sombra, posição]; [] = capa (vai como no gato).
static var _cache_aparado: Dictionary = {}

static func sprite(c: CanvasItem, x: float, y: float, linhas: Array, paleta: Dictionary, f: float = 0.0) -> void:
	if not mascara.is_empty():
		if _sprite_vestido(c, x, y, linhas, paleta, f):
			return
	var chave: int = linhas.hash() * 31 + paleta.hash()
	var e: Array = _cache_sprite.get(chave, [])
	if e.is_empty() or e[0] != linhas or e[1] != paleta:
		e = _montar_sprite(linhas, paleta)
		if _cache_sprite.size() > 600:
			_cache_sprite.clear()
		_cache_sprite[chave] = e
	_retangulos(c, x, y, e[2], e[3], f)

static func _retangulos(c: CanvasItem, x: float, y: float, rs: Array, cs: PackedColorArray, f: float) -> void:
	if f <= 0.0:
		for k in rs.size():
			var q: Rect2 = rs[k]
			c.draw_rect(Rect2(x + q.position.x, y + q.position.y, q.size.x, q.size.y), cs[k])
	else:
		for k in rs.size():
			var q2: Rect2 = rs[k]
			c.draw_rect(Rect2(x + q2.position.x, y + q2.position.y, q2.size.x, q2.size.y), Desenho.b(cs[k], f))

## Peça de corpo num bicho: estica até o tronco, apara pelo molde, faz a bainha e o volume. Devolve false quando a peça
## pende para fora do tronco (capa) e deve ir como no gato.
static func _sprite_vestido(c: CanvasItem, x: float, y: float, linhas: Array, paleta: Dictionary, f: float) -> bool:
	var ca: int = hash([linhas.hash(), paleta.hash(), esticar, roundi((mascara_origem.x + x) * 2.0), roundi((mascara_origem.y + y) * 2.0), mascara_id])
	var pronto: Array = _cache_aparado.get(ca, [null])
	if pronto.size() == 1:
		pronto = _aparar(x, y, linhas, paleta)
		if _cache_aparado.size() > 3000:
			_cache_aparado.clear()
		_cache_aparado[ca] = pronto
	if pronto.is_empty():
		return false
	var pos: Vector2 = pronto[3]
	_retangulos(c, pos.x, pos.y, pronto[0], pronto[1], f)
	# volume: barra de baixo mais escura, alto mais claro (como o tronco do bicho por baixo)
	for sm in pronto[2]:
		var rq: Rect2 = sm[0]
		c.draw_rect(Rect2(pos.x + rq.position.x, pos.y + rq.position.y, rq.size.x, rq.size.y), sm[1])
	return true

static func _aparar(x: float, y: float, linhas: Array, paleta: Dictionary) -> Array:
	if _fracao_no_molde(linhas, x, y) < 0.5:
		return []
	if esticar != Vector2i.ZERO:
		var ce: int = linhas.hash() * 131 + esticar.x * 17 + esticar.y
		if not _cache_esticado.has(ce):
			if _cache_esticado.size() > 400:
				_cache_esticado.clear()
			_cache_esticado[ce] = _esticado(linhas, esticar)
		linhas = _cache_esticado[ce]
		x -= floorf(esticar.x * 0.5)
		y -= floorf(esticar.y * 0.5)
	# alinha a peça à grade do bicho e apaga o que sai do molde
	x = roundf(mascara_origem.x + x) - mascara_origem.x
	y = roundf(mascara_origem.y + y) - mascara_origem.y
	var bx: int = roundi(mascara_origem.x + x)
	var by: int = roundi(mascara_origem.y + y)
	var aparadas: Array = []
	for j in linhas.size():
		var l: String = linhas[j]
		var s: String = ""
		for i in l.length():
			s += l[i] if mascara.has(Vector2i(bx + i, by + j)) and l[i] != " " else "."
		aparadas.append(s)
	var final: Array = _bainha(aparadas, bx, by, paleta)
	var m: Array = _montar_sprite(final, paleta)
	return [m[2], m[3], _sombra(final), Vector2(x, y)]

## Fração dos pixels da peça (sem esticar) que caem sobre o molde do tronco.
static func _fracao_no_molde(linhas: Array, x: float, y: float) -> float:
	var bx: int = roundi(mascara_origem.x + x)
	var by: int = roundi(mascara_origem.y + y)
	var tot: int = 0
	var den: int = 0
	for j in linhas.size():
		var l: String = linhas[j]
		for i in l.length():
			if l[i] != "." and l[i] != " ":
				tot += 1
				if mascara.has(Vector2i(bx + i, by + j)):
					den += 1
	return float(den) / float(maxi(1, tot))

## Bainha: onde a peça aparada termina dentro do tronco (pescoço, anca), a borda vira contorno `o`, como na peça do gato.

## Bainha: onde a peça aparada termina dentro do tronco (pescoço, anca), a borda vira contorno `o`, como na peça do gato.
static func _bainha(linhas: Array, bx: int, by: int, paleta: Dictionary) -> Array:
	if not paleta.has("o"):
		return linhas
	var r: Array = []
	for j in linhas.size():
		var l: String = linhas[j]
		var s: String = ""
		for i in l.length():
			var ch: String = l[i]
			if ch != ".":
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var ni: int = i + d.x
					var nj: int = j + d.y
					var dentro: bool = nj >= 0 and nj < linhas.size() and ni >= 0 and ni < String(linhas[nj]).length() and String(linhas[nj])[ni] != "."
					if not dentro and mascara.has(Vector2i(bx + ni, by + nj)):
						ch = "o"
						break
			s += ch
		r.append(s)
	return r

## Retângulos de sombra e luz de uma peça aparada: em cada coluna, os 2 pixels de baixo escurecem e o de cima clareia.

## Retângulos de sombra e luz de uma peça aparada: em cada coluna, os 2 pixels de baixo escurecem e o de cima clareia.
static func _sombra(linhas: Array) -> Array:
	var r: Array = []
	var w: int = 0
	for l in linhas:
		w = maxi(w, String(l).length())
	for i in w:
		var topo: int = -1
		var fundo: int = -1
		for j in linhas.size():
			var l: String = linhas[j]
			if i < l.length() and l[i] != "." and l[i] != "o":
				if topo < 0:
					topo = j
				fundo = j
		if topo < 0:
			continue
		r.append([Rect2(i, topo, 1.03, 1.03), Color(1, 1, 1, 0.12)])
		var n: int = fundo - topo + 1
		if n >= 4:
			r.append([Rect2(i, fundo - 1, 1.03, 2.03), Color(0, 0, 0, 0.2)])
		elif n >= 2:
			r.append([Rect2(i, fundo, 1.03, 1.03), Color(0, 0, 0, 0.2)])
	return r

## Letras raras da peça (menos de 8% dos pixels, fora contorno): emblemas, fivelas, estrelas.
static func _letras_raras(linhas: Array) -> Dictionary:
	var cont: Dictionary = {}
	var tot: int = 0
	for l in linhas:
		for ch in String(l):
			if ch != "." and ch != " " and ch != "o":
				cont[ch] = int(cont.get(ch, 0)) + 1
				tot += 1
	var r: Dictionary = {}
	for ch in cont.keys():
		if float(cont[ch]) < 0.08 * tot:
			r[ch] = true
	return r

## Cor de tecido da peça: a letra mais comum, fora o vazio e o contorno `o`.
static func _tecido(linhas: Array) -> String:
	var cont: Dictionary = {}
	for l in linhas:
		for ch in String(l):
			if ch != "." and ch != " " and ch != "o":
				cont[ch] = int(cont.get(ch, 0)) + 1
	var melhor: String = ""
	for ch in cont.keys():
		if melhor == "" or int(cont[ch]) > int(cont[melhor]):
			melhor = ch
	return melhor

## Quanto a coluna `i` destoa das vizinhas e do tecido (0 = lisa e de tecido, boa para repetir). Vazio no meio da peça conta caro,
## e cada letra que não é o tecido também (para não repetir o cinto ou a faixa de botões).
static func _rugosidade_col(linhas: Array, i: int) -> int:
	var n: int = 0
	var tec: String = _tecido(linhas)
	for l in linhas:
		var lt: String = l
		if lt[i] != tec and lt[i] != "o" and lt[i] != ".":
			n += 2
		var s: String = l
		var ch: String = s[i]
		if ch == "." and s.substr(0, i).strip_edges().replace(".", "") != "" and s.substr(i + 1).replace(".", "") != "":
			n += 3
		if i > 0 and s[i - 1] != ch:
			n += 1
		if i < s.length() - 1 and s[i + 1] != ch:
			n += 1
	return n

## A coluna mais lisa entre `de` e `ate` (inclusive); no empate, a mais perto de `meio`.
static func _col_lisa(linhas: Array, de: int, ate: int, meio: float) -> int:
	var melhor: int = de
	var nota: int = 1 << 30
	for i in range(de, ate + 1):
		var r: int = _rugosidade_col(linhas, i)
		if r < nota or (r == nota and absf(i - meio) < absf(melhor - meio)):
			melhor = i
			nota = r
	return melhor

## Transposta de um desenho em linhas (para escolher e repetir linhas com o mesmo código das colunas).
static func _transposta(linhas: Array) -> Array:
	var w: int = 0
	for l in linhas:
		w = maxi(w, String(l).length())
	var t: Array = []
	for i in w:
		var s: String = ""
		for l in linhas:
			var ls: String = l
			s += ls[i] if i < ls.length() else "."
		t.append(s)
	return t

## Na largura (`colunas`) repete um trecho do meio, para a estampa seguir; na altura repete linhas lisas de tecido, metade numa linha
## da metade de cima e metade numa da de baixo (cinto e barras ficam com a altura de sempre).
static func _alargado(linhas: Array, extra: int, colunas: bool = false) -> Array:
	if extra <= 0:
		return linhas
	var w: int = 0
	for l in linhas:
		w = maxi(w, String(l).length())
	var pad: Array = []
	for l in linhas:
		pad.append(String(l).rpad(w, "."))
	if w < 4:
		return pad
	if colunas:
		# largura: repete um trecho do meio, então estrelas, pelos e botões continuam; o trecho foge de emblemas (cores raras
		# concentradas, como o reator ou a fivela), que ficam um só
		var a: int = maxi(1, int(w * 0.25))
		var b: int = mini(w - 1, maxi(a + 1, int(ceil(w * 0.7))))
		var raras: Dictionary = _letras_raras(pad)
		var tec: String = _tecido(pad)
		var larg: int = clampi((w - 2) / 3, 2, 4)
		var melhor_a: int = a
		var nota_a: int = 1 << 30
		for ia in range(1, w - larg):
			var nota: int = 0
			for i in range(ia, ia + larg):
				var na: int = 0
				var nn: int = 0
				for l in pad:
					var ch: String = String(l)[i]
					if raras.has(ch):
						na += 1
					elif ch != tec and ch != "o" and ch != ".":
						nn += 1
				# pixel raro solto (estrela) não pesa; vários na coluna (emblema) pesam muito; cor grande que não é o tecido
				# (o círculo de luz da armadura) também pesa
				nota += maxi(0, na - 1) * maxi(0, na - 1) + nn
			nota = nota * 10 + int(absf(ia + larg * 0.5 - w * 0.5))
			if nota < nota_a:
				nota_a = nota
				melhor_a = ia
		a = melhor_a
		b = melhor_a + larg
		var r2: Array = []
		for l in pad:
			var s2: String = l
			var trecho: String = s2.substr(a, b - a)
			var meio2: String = ""
			while meio2.length() < extra:
				meio2 += trecho
			r2.append(s2.substr(0, b) + meio2.substr(0, extra) + s2.substr(b))
		return r2
	var meio: float = (w - 1) * 0.5
	var ce: int = _col_lisa(pad, maxi(1, int(w * 0.2)), maxi(1, int(meio)), meio)
	var cd: int = _col_lisa(pad, mini(w - 2, int(ceil(meio))), mini(w - 2, int(ceil(w * 0.8))), meio)
	var ne: int = int(ceil(extra * 0.5))
	var nd: int = extra - ne
	if cd == ce:
		ne = extra
		nd = 0
	var r: Array = []
	for l in pad:
		var s: String = l
		var o: String = ""
		for i in w:
			o += s[i]
			if i == ce:
				o += s[i].repeat(ne)
			elif i == cd:
				o += s[i].repeat(nd)
		r.append(o)
	return r

static func _esticado(linhas: Array, e: Vector2i) -> Array:
	var r: Array = _alargado(linhas, e.x, true)
	if e.y > 0:
		r = _transposta(_alargado(_transposta(r), e.y))
	return r

static func _montar_sprite(linhas: Array, paleta: Dictionary) -> Array:
	var rs: Array = []
	var cs := PackedColorArray()
	for j in linhas.size():
		var l: String = linhas[j]
		var i: int = 0
		while i < l.length():
			var ch: String = l[i]
			if ch == "." or ch == " " or not paleta.has(ch):
				i += 1
				continue
			var n: int = 1
			while i + n < l.length() and l[i + n] == ch:
				n += 1
			rs.append(Rect2(i, j, n + 0.03, 1.03))
			cs.append(paleta[ch])
			i += n
	return [linhas.duplicate(true), paleta.duplicate(true), rs, cs]
