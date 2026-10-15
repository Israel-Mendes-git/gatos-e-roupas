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

## Letras de faixa: as que enchem uma linha de dentro da peça (o cinto dourado, a barra da armadura) — linha que começa e acaba no
## contorno `o`. Repetir uma coluna com elas só alonga a faixa.
static func _letras_faixa(linhas: Array) -> Dictionary:
	var r: Dictionary = {}
	for l in linhas:
		var s: String = l
		var t: String = s.strip_edges().replace(".", " ").strip_edges()
		if t.length() < 2 or t[0] != "o" or t[t.length() - 1] != "o":
			continue
		var cont: Dictionary = {}
		var n: int = 0
		for ch in s:
			if ch != "." and ch != " " and ch != "o":
				cont[ch] = int(cont.get(ch, 0)) + 1
				n += 1
		for ch in cont.keys():
			if int(cont[ch]) >= maxi(3, int(s.length() * 0.5)) and float(cont[ch]) >= 0.75 * n:
				r[ch] = true
	return r

## A peça sem os pontinhos soltos (estrela, rebite, brilho de um pixel no meio do pano): cada um vira a cor do pano em volta.
## É dela que se escolhe e se copia o trecho repetido — repetir o pontinho fazia fileira de pontos (listra).
static func _limpo(pad: Array) -> Array:
	var h: int = pad.size()
	var w: int = String(pad[0]).length() if h > 0 else 0
	var r: Array = []
	for j in h:
		var s: String = pad[j]
		var o: String = ""
		for i in w:
			var ch: String = s[i]
			if ch == "." or ch == " " or ch == "o":
				o += ch
				continue
			var cont: Dictionary = {}
			var igual: bool = false
			var pano: int = 0
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var x: int = i + d.x
				var y: int = j + d.y
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var v: String = String(pad[y])[x]
				if v == ch:
					igual = true
				elif v != "." and v != " " and v != "o":
					cont[v] = int(cont.get(v, 0)) + 1
					pano += 1
			if igual or pano < 3:
				o += ch
				continue
			var melhor: String = ch
			for k in cont.keys():
				if melhor == ch or int(cont[k]) > int(cont[melhor]):
					melhor = k
			o += melhor
		r.append(o)
	return r

## Fração de cada letra entre os pixels da peça (fora vazio e contorno `o`).
static func _mistura(linhas: Array) -> Dictionary:
	var cont: Dictionary = {}
	var tot: int = 0
	var raras: Dictionary = _letras_raras(linhas)
	for l in linhas:
		for ch in String(l):
			if ch != "o" and ch != "." and ch != " " and not raras.has(ch):
				cont[ch] = int(cont.get(ch, 0)) + 1
				tot += 1
	for ch in cont.keys():
		cont[ch] = float(cont[ch]) / float(maxi(1, tot))
	return cont

## Quantos pixels mudam entre duas colunas (ou duas linhas).
static func _dif(a: String, b: String) -> int:
	var n: int = absi(a.length() - b.length())
	for k in mini(a.length(), b.length()):
		if a[k] != b[k]:
			n += 1
	return n

## Melhor trecho [a, a + L) de `cols` (colunas do desenho) para repetir, dentro de [de, ate]. Devolve [a, L, custo].
## Custo: (1) a emenda — repetir só fica liso quando o desenho fecha um período ali (a coluna depois do trecho igual à primeira
## dele, ou a de antes igual à última); repetir um trecho que não fecha (placa + rebite, meio círculo de luz) é o que fazia
## listras; (2) emblema — cores raras concentradas na coluna; (3) a mistura de cores do trecho longe da da peça inteira (repetir
## só a faixa preta da abelha, ou só a placa sem escama do casco, muda a cara da peça). Desempate: o trecho mais perto do `meio`.
static func _trecho(cols: Array, de: int, ate: int, raras: Dictionary, mistura: Dictionary, meio: float, max_l: int = 6) -> Array:
	var w: int = cols.size()
	var melhor: Array = [clampi(de, 1, maxi(1, w - 2)), 1, 1 << 20]
	var nota_m: int = 1 << 30
	for L in range(1, mini(max_l, maxi(1, (w - 2) / 2)) + 1):
		for a in range(maxi(1, de), mini(ate - L + 1, w - 1 - L) + 1):
			var b: int = a + L
			var emenda: int = mini(_dif(cols[a], cols[b]), _dif(cols[a - 1], cols[b - 1]))
			var em: int = 0
			var cont: Dictionary = {}
			var tot: int = 0
			for i in range(a, b):
				var na: int = 0
				for ch in String(cols[i]):
					if raras.has(ch):
						na += 1
					if ch != "o" and ch != "." and ch != " ":
						cont[ch] = int(cont.get(ch, 0)) + 1
						tot += 1
				em += na * na * 5
			var desvio: float = 0.0
			for ch in mistura.keys():
				desvio += absf(float(cont.get(ch, 0)) / float(maxi(1, tot)) - float(mistura[ch]))
			var custo: int = emenda * 3 + em + roundi(desvio * 4.0)
			var nota: int = custo * 10 + int(absf(a + L * 0.5 - meio))
			if nota < nota_m:
				nota_m = nota
				melhor = [a, L, custo]
	return melhor

## Insere `extra` colunas depois do trecho [a, a + L), repetindo-o (em todas as linhas); as cópias saem de `fonte` (a peça limpa).
static func _inserir(linhas: Array, a: int, L: int, extra: int, fonte: Array = []) -> Array:
	if extra <= 0:
		return linhas
	var f: Array = fonte if fonte.size() == linhas.size() else linhas
	var r: Array = []
	for j in linhas.size():
		var s: String = linhas[j]
		var t: String = String(f[j]).substr(a, L)
		var rep: String = ""
		while rep.length() < extra:
			rep += t if t != "" else "."
		r.append(s.substr(0, a + L) + rep.substr(0, extra) + s.substr(a + L))
	return r

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

## Onde _alargado inseriu na última chamada: [[b, n], ...] = n colunas novas logo antes da coluna original b.
static var _ins: Array = []

## Repete, nas colunas do desenho, o trecho que fecha o período dele (ver _trecho; `max_l` = largura máxima do trecho); para crescer
## na altura, chamar com a transposta.
## Quando os dois lados do meio têm um trecho tão bom quanto, a sobra se divide entre eles e o que fica no meio continua no meio.
## Grava as inserções em _ins.
static func _alargado(linhas: Array, extra: int, max_l: int = 6) -> Array:
	_ins = []
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
	var lp: Array = _limpo(pad)
	var cols: Array = _transposta(lp)
	var raras: Dictionary = _letras_raras(lp)
	var mistura: Dictionary = _mistura(lp)
	var meio: float = w * 0.5
	var tudo: Array = _trecho(cols, 1, w - 2, raras, mistura, meio, max_l)
	var partes: Array = [[tudo[0], tudo[1], extra]]
	if extra >= 2:
		var esq: Array = _trecho(cols, 1, int(floor(meio)) - 1, raras, mistura, meio, max_l)
		var dir: Array = _trecho(cols, int(ceil(meio)), w - 2, raras, mistura, meio, max_l)
		if int(esq[2]) <= int(tudo[2]) + 1 and int(dir[2]) <= int(tudo[2]) + 1:
			var ne: int = extra / 2
			partes = [[dir[0], dir[1], extra - ne], [esq[0], esq[1], ne]]   # a da direita antes: os índices da esquerda não mudam
	var r2: Array = pad
	var ins: Array = []
	for p in partes:
		r2 = _inserir(r2, p[0], p[1], p[2], lp)
		lp = _inserir(lp, p[0], p[1], p[2])
		ins.append([int(p[0]) + int(p[1]), int(p[2])])
	_ins = ins
	return r2

## Tecido e faixas contados só nos pixels de dentro da peça (os quatro vizinhos pintados): o contorno das asas da abelha não conta.
static func _neutras(pad: Array) -> Dictionary:
	var h: int = pad.size()
	var w: int = String(pad[0]).length() if h > 0 else 0
	var dentro: Array = []
	for j in h:
		var s: String = ""
		for i in w:
			var ch: String = String(pad[j])[i]
			var ok: bool = ch != "." and ch != " " and i > 0 and j > 0 and i < w - 1 and j < h - 1
			if ok:
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var c2: String = String(pad[j + d.y])[i + d.x]
					if c2 == "." or c2 == " ":
						ok = false
						break
			s += ch if ok else "."
		dentro.append(s)
	var r: Dictionary = _letras_faixa(pad)
	var tec: String = _tecido(dentro)
	if tec != "":
		r[tec] = true
	return r

## Emblemas da peça: manchas de cor que não é tecido nem faixa e que não se repetem (o círculo de luz da armadura, a aranha, o
## painel do traje, as asas da abelha). Manchas cuja combinação de cores aparece de novo (listras, escamas, xadrez) são estampa e
## ficam no pano; mancha larga dentro do pano (as placas do casco) também. Devolve [base, emblemas]: base = a peça com cada
## emblema trocado pela cor que o cerca; emblema = [{Vector2i: letra}, Rect2i].
static func _emblemas(pad: Array) -> Array:
	var h: int = pad.size()
	var w: int = String(pad[0]).length() if h > 0 else 0
	var neutras: Dictionary = _neutras(pad)
	var total: int = 0
	for l in pad:
		total += String(l).replace(".", "").replace(" ", "").length()
	var visto: Dictionary = {}
	var manchas: Array = []
	for j in h:
		for i in w:
			var ch: String = String(pad[j])[i]
			if ch == "." or ch == " " or ch == "o" or neutras.has(ch) or visto.has(Vector2i(i, j)):
				continue
			var px: Dictionary = {}
			var letras: Dictionary = {}
			var pilha: Array = [Vector2i(i, j)]
			visto[Vector2i(i, j)] = true
			while not pilha.is_empty():
				var p: Vector2i = pilha.pop_back()
				var cp: String = String(pad[p.y])[p.x]
				px[p] = cp
				letras[cp] = true
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var q: Vector2i = p + d
					if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or visto.has(q):
						continue
					var c2: String = String(pad[q.y])[q.x]
					if c2 == "." or c2 == " " or c2 == "o" or neutras.has(c2):
						continue
					visto[q] = true
					pilha.append(q)
			var ks: Array = letras.keys()
			ks.sort()
			manchas.append([px, "".join(ks)])
	var g: Array = []
	for l in pad:
		g.append(Array(String(l).split("")))
	var r: Array = []
	for m in manchas:
		var px: Dictionary = m[0]
		var n: int = px.size()
		if n < 3 or n > total * 0.6:
			continue
		var repete: bool = false
		for m2 in manchas:
			if m2 != m and m2[1] == m[1]:
				repete = true
				break
		if repete:
			continue
		# fundo: a letra mais comum em volta da mancha (pano dentro da peça, vazio quando a mancha sai dela, como as asas)
		var cont: Dictionary = {}
		var caixa := Rect2i()
		var primeiro: bool = true
		for p in px.keys():
			var v: Vector2i = p
			caixa = Rect2i(v, Vector2i.ONE) if primeiro else caixa.expand(v).expand(v + Vector2i.ONE)
			primeiro = false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = v + d
				if px.has(q):
					continue
				var c3: String = "." if (q.x < 0 or q.y < 0 or q.x >= w or q.y >= h) else String(pad[q.y])[q.x]
				if c3 != "o":
					cont[c3] = int(cont.get(c3, 0)) + 1
		var fundo: String = "."
		var melhor: int = -1
		for k in cont.keys():
			if k != "." and int(cont[k]) > melhor:
				melhor = int(cont[k])
				fundo = k
		if int(cont.get(".", 0)) > melhor:
			fundo = "."
		if fundo != "." and caixa.size.x > w * 0.6:
			continue   # mancha larga dentro do pano: é estampa (placas do casco), fica e estica com ele
		for p in px.keys():
			var v2: Vector2i = p
			g[v2.y][v2.x] = fundo
		r.append([px, caixa])
	if r.is_empty():
		return [pad, []]
	var base: Array = []
	for linha in g:
		base.append("".join(linha))
	return [base, r]

## Quanto um emblema anda com as inserções `ins` ([[b, n], ...]) num eixo, sendo [de, ate) a faixa dele nesse eixo:
## inserção antes dele leva tudo, inserção no meio dele leva metade (o emblema segue inteiro, centrado no que cresceu).
static func _anda(ins: Array, de: int, ate: int) -> int:
	var s: int = 0
	for it in ins:
		var b: int = it[0]
		if b <= de:
			s += int(it[1])
		elif b < ate:
			s += int(it[1]) / 2
	return s

## Peça esticada: o pano (sem os emblemas) cresce repetindo trechos lisos; os emblemas voltam inteiros, no lugar correspondente.
static func _esticado(linhas: Array, e: Vector2i) -> Array:
	var w: int = 0
	for l in linhas:
		w = maxi(w, String(l).length())
	var pad: Array = []
	for l in linhas:
		pad.append(String(l).rpad(w, "."))
	var em: Array = _emblemas(pad)
	var r: Array = _alargado(em[0], e.x)
	var insx: Array = _ins
	var insy: Array = []
	if e.y > 0:
		r = _transposta(_alargado(_transposta(r), e.y, 1))   # na altura, uma linha lisa por vez: faixas repetidas viravam listras
		insy = _ins
	if Array(em[1]).is_empty():
		return r
	var g: Array = []
	for l in r:
		g.append(Array(String(l).split("")))
	for it in em[1]:
		var cx: Rect2i = it[1]
		var dx: int = _anda(insx, cx.position.x, cx.end.x)
		var dy: int = _anda(insy, cx.position.y, cx.end.y)
		for p in Dictionary(it[0]).keys():
			var v: Vector2i = p
			var y: int = v.y + dy
			var x: int = v.x + dx
			if y >= 0 and y < g.size() and x >= 0 and x < Array(g[y]).size():
				g[y][x] = it[0][p]
	var out: Array = []
	for linha in g:
		out.append("".join(linha))
	return out

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
