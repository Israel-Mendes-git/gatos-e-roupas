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
const _FAIXA := 21   # tipos por arquivo: A 0..20, B 21..41, C 42..62, D 63..83, E 84..99, F 100 em diante (expansão)

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
	if tipo >= RoupaGatoI.PRIMEIRO:
		o = RoupaGatoI.onde(tipo)
	elif tipo >= RoupaGatoH.PRIMEIRO:
		o = RoupaGatoH.onde(tipo)
	elif tipo >= RoupaGatoG.PRIMEIRO:
		o = RoupaGatoG.onde(tipo)
	elif tipo >= RoupaGatoF.PRIMEIRO:
		o = RoupaGatoF.onde(tipo)
	else:
		o = _onde_arquivo(tipo)
	if o >= 0:
		return o
	# sem escolha do arquivo da peça: a de mão vai na boca; o acessório, na traseira
	return Onde.BOCA if Pecas.SLOT[tipo] == Pecas.SLOT_MAO else Onde.TRASEIRA

static func _onde_arquivo(tipo: int) -> int:
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
	_tipo_vez = tipo
	if tipo >= RoupaGatoI.PRIMEIRO:
		RoupaGatoI.desenhar(c, tipo, f, anim)
		return
	if tipo >= RoupaGatoH.PRIMEIRO:
		RoupaGatoH.desenhar(c, tipo, f, anim)
		return
	if tipo >= RoupaGatoG.PRIMEIRO:
		RoupaGatoG.desenhar(c, tipo, f, anim)
		return
	if tipo >= RoupaGatoF.PRIMEIRO:
		RoupaGatoF.desenhar(c, tipo, f, anim)
		return
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

## Desenha a peça de cabeça `e` colunas mais larga e `e.y` linhas mais alta (bicho de cabeça maior que a do gato): cada camada da
## peça (boné e bigode, faixa e pontas) corta na mesma coluna e na mesma linha, escolhidas pela primeira camada, e repete ali o
## trecho liso dela (ver _trecho). O pixel continua do mesmo tamanho; o centro fica no lugar e a aba fica embaixo (cresce para cima).
static func desenhar_esticada(c: CanvasItem, tipo: int, f: float, anim: float, e: Vector2i) -> void:
	if e == Vector2i.ZERO:
		desenhar(c, tipo, f, anim)
		return
	esticar_cab = e
	_corte_ok = false
	desenhar(c, tipo, f, anim)
	esticar_cab = Vector2i.ZERO
	_corte_ok = false

## 0 = todas as camadas da peça (ícone); 1 = só as que ficam ATRÁS do corpo; 2 = só as da frente (ver RoupaGatoF.tem_atras).
static var passo: int = 0
static var esticar_cab: Vector2i = Vector2i.ZERO
static var _corte_ok: bool = false
static var _corte: Vector4 = Vector4.ZERO      # coluna do trecho, largura, linha do trecho, altura (coordenadas da peça)
static var _cache_corte: Dictionary = {}
static var _cache_cab: Dictionary = {}

## Um retângulo de pixels.
static func r(c: CanvasItem, x: float, y: float, w: float, h: float, cor: Color, f: float = 0.0) -> void:
	if esticar_cab != Vector2i.ZERO:
		var ox: float = -floorf(esticar_cab.x * 0.5)
		var oy: float = -esticar_cab.y
		if _corte_ok:
			if x >= _corte.x + _corte.y:
				ox += esticar_cab.x
			if y >= _corte.z + _corte.w:
				oy += esticar_cab.y
		x += ox
		y += oy
	c.draw_rect(Rect2(x, y, w + 0.03, h + 0.03), Desenho.b(cor, f))

## Uma camada da peça de cabeça esticada (ver desenhar_esticada).
static func _sprite_cabeca(c: CanvasItem, x: float, y: float, linhas: Array, paleta: Dictionary, f: float) -> void:
	var e: Vector2i = esticar_cab
	if not _corte_ok:
		var kc: int = linhas.hash()
		if not _cache_corte.has(kc):
			if _cache_corte.size() > 300:
				_cache_corte.clear()
			var w0: int = 0
			for l in linhas:
				w0 = maxi(w0, String(l).length())
			var pad0: Array = []
			for l in linhas:
				pad0.append(String(l).rpad(w0, "."))
			var lp0: Array = _limpo(_emblemas(pad0)[0])
			var tx: Array = _trecho(_transposta(lp0), 1, w0 - 2, _letras_raras(lp0), _mistura(lp0), w0 * 0.5, 1)
			var ty: Array = _trecho(lp0, 1, lp0.size() - 2, _letras_raras(lp0), _mistura(lp0), lp0.size() * 0.5, 1)
			_cache_corte[kc] = Vector4i(tx[0], tx[1], ty[0], ty[1])
		var cc: Vector4i = _cache_corte[kc]
		_corte = Vector4(x + cc.x, cc.y, y + cc.z, cc.w)
		_corte_ok = true
	var a: int = roundi(_corte.x - x)
	var ay: int = roundi(_corte.z - y)
	var ch: int = hash([linhas.hash(), paleta.hash(), a, int(_corte.y), ay, int(_corte.w), e])
	var m: Array = _cache_cab.get(ch, [])
	if m.is_empty() or m[0] != linhas or m[1] != paleta:
		if _cache_cab.size() > 600:
			_cache_cab.clear()
		m = _montar_sprite(_cabeca_esticada(linhas, a, int(_corte.y), e.x, ay, int(_corte.w), e.y), paleta)
		m[0] = linhas.duplicate(true)
		_cache_cab[ch] = m
	_retangulos(c, x - floorf(e.x * 0.5), y - e.y, m[2], m[3], f)

## Camada com `ex` colunas a mais depois do trecho [a, a + L) e `ey` linhas a mais depois de [ay, ay + Ly) (o trecho pode cair fora
## da camada: aí ela só anda, inteira). As cópias saem da camada limpa (sem pontinhos soltos).
static func _cabeca_esticada(linhas: Array, a: int, L: int, ex: int, ay: int, Ly: int, ey: int) -> Array:
	var w: int = 0
	for l in linhas:
		w = maxi(w, String(l).length())
	var pad0: Array = []
	for l in linhas:
		pad0.append(String(l).rpad(w, "."))
	var em: Array = _emblemas(pad0)   # a caveira do tricórnio, a estrela: não se repetem, voltam inteiras no fim
	var pad: Array = em[0]
	var lp: Array = _limpo(pad)
	var h: int = pad.size()
	var b: int = a + L
	var larg: int = w + ex
	var cols: Array = []
	for j in h:
		var s: String = ""
		for o in larg:
			var src: int = o
			var fonte: Array = pad
			if o >= b and o < b + ex:
				src = a + (o - b) % maxi(1, L)
				fonte = lp
			elif o >= b + ex:
				src = o - ex
			s += String(fonte[j])[src] if src >= 0 and src < w else "."
		cols.append(s)
	var r: Array = cols
	var by: int = ay + Ly
	if ey > 0:
		r = []
		var lp2: Array = _limpo(cols)
		for o in h + ey:
			if o < by:
				r.append(cols[o] if o < h else ".".repeat(larg))
			elif o < by + ey:
				var src2: int = ay + (o - by) % maxi(1, Ly)
				r.append(lp2[src2] if src2 >= 0 and src2 < h else ".".repeat(larg))
			else:
				var src3: int = o - ey
				r.append(cols[src3] if src3 >= 0 and src3 < h else ".".repeat(larg))
	if Array(em[1]).is_empty():
		return r
	var g: Array = []
	for l in r:
		g.append(Array(String(l).split("")))
	for it in em[1]:
		var cx: Rect2i = it[1]
		var dx: int = _anda([[b, ex]], cx.position.x, cx.end.x)
		var dy: int = _anda([[by, ey]], cx.position.y, cx.end.y) if ey > 0 else 0
		for p in Dictionary(it[0]).keys():
			var v: Vector2i = p
			if v.y + dy >= 0 and v.y + dy < g.size() and v.x + dx >= 0 and v.x + dx < Array(g[v.y + dy]).size():
				g[v.y + dy][v.x + dx] = it[0][p]
	var out: Array = []
	for linha in g:
		out.append("".join(linha))
	return out

## Desenho em pixels a partir de linhas de texto: cada letra é um pixel da cor `paleta[letra]`;
## ponto ou espaço é transparente. (x, y) é o canto de cima à esquerda.
## Retângulos já mesclados de cada sprite (chave: hash do desenho + paleta; a entrada guarda os dois para conferir).
## Os chamadores montam as linhas e a paleta de novo a cada quadro, então a chave é pelo conteúdo.
static var _cache_sprite: Dictionary = {}

## Molde ({Vector2i: true}, em pixels do bicho) do tronco onde a peça de corpo é refeita (ver _alfaiate). `mascara_origem` = onde
## está a origem da peça nesse mesmo sistema; `mascara_id` = identidade do molde (uma por pose, ver BichoPx.quadro).
## Quem desenha liga antes e esvazia depois (também `cobre` e `molde_quadro`).
static var mascara: Dictionary = {}
static var mascara_origem: Vector2 = Vector2.ZERO
static var mascara_id: int = 0
## Quanto da altura do tronco a roupa de corpo cobre num bicho comum: o resto (barriga, patas) fica à mostra e a peça lê como
## roupa vestida. Os chefes gravam o deles no quadro ("cobre"): só o dorso.
const COBRE_BICHO := 0.72
static var cobre: float = COBRE_BICHO
## Quadro do bicho ("l", "x", "y"): a bainha só nasce onde a roupa encosta em corpo à mostra (não no contorno nem no vazio).
static var molde_quadro: Dictionary = {}
## Peças de corpo já refeitas no molde, prontas para desenhar: [retângulos, cores]; [] = capa (vai como no gato).
static var _cache_aparado: Dictionary = {}
## Leitura de cada peça de corpo (ver _analisar), por desenho + paleta + tipo.
static var _cache_analise: Dictionary = {}
## Tipo da peça que está sendo desenhada (para as dicas de _DICAS).
static var _tipo_vez: int = -1

static func sprite(c: CanvasItem, x: float, y: float, linhas: Array, paleta: Dictionary, f: float = 0.0) -> void:
	if esticar_cab != Vector2i.ZERO:
		_sprite_cabeca(c, x, y, linhas, paleta, f)
		return
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

## Peça de corpo num bicho: em vez de esticar o desenho do gato, a peça é refeita sobre o tronco do bicho (ver _alfaiate).
## Devolve false quando a peça pende para fora do tronco (capa) e deve ir como no gato.
static func _sprite_vestido(c: CanvasItem, x: float, y: float, linhas: Array, paleta: Dictionary, f: float) -> bool:
	var ca: int = hash([linhas.hash(), paleta.hash(), _tipo_vez, mascara_id, cobre, mascara_origem])
	var pronto: Array = _cache_aparado.get(ca, [null])
	if pronto.size() == 1:
		pronto = [] if _fracao_no_molde(linhas, x, y) < 0.5 else _alfaiate(_analise(linhas, paleta, _tipo_vez))
		if _cache_aparado.size() > 3000:
			_cache_aparado.clear()
		_cache_aparado[ca] = pronto
	if pronto.is_empty():
		return false
	_retangulos(c, -mascara_origem.x, -mascara_origem.y, pronto[0], pronto[1], f)
	return true

## Fração dos pixels da peça (como no gato) que caem sobre o molde do tronco.
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

## Dicas por tipo de peça, para o que a leitura automática (_analisar) não dá conta:
##  "base"  = letra do pano (o colante é vermelho com laterais azuis, mas o azul é a letra mais comum);
##  "lados" = letra das laterais (painéis nas duas pontas do tronco);
##  "ladrilho" = estampa desenhada à mão para o pano, repetida no período dela (as placas do casco são poucas e irregulares no
##  desenho do gato: esticadas viravam borrão);
##  "alcas" = [letra da alça, letra do botão, linhas do peito]: macacão — peito da camisa em cima, alças descendo até o pano;
##  "tex"   = o pano é pelagem: sem período achado, ele inteiro se repete (pele de urso);
##  "gola"  = letra da gola junto ao pescoço (as lapelas em V da túnica ficam nas pontas do desenho do gato).
const _DICAS: Dictionary = {
	Pecas.Tipo.COLANTE: {"base": "r", "lados": "b"},
	Pecas.Tipo.CASCO: {"base": "q", "ladrilho": [
		"pPPPPp.",
		"pPPPPpq",
		"qpppppq",
		"PPpq.pP",
		"PPpqqpP",
		"pppqqpp",
	]},
	Pecas.Tipo.MACACAO: {"base": "B", "alcas": ["B", "g", "R"]},
	Pecas.Tipo.PELE: {"tex": true},
	Pecas.Tipo.TUNICA: {"gola": "d"},
	Pecas.Tipo.BARRIL: {"base": "b"},
	Pecas.Tipo.ARMADURA_AZUL: {"base": "A"},
}

## Leitura da peça em cache (ver _analisar).
static func _analise(linhas: Array, paleta: Dictionary, tipo: int) -> Dictionary:
	var ch: int = hash([linhas.hash(), paleta.hash(), tipo])
	var e: Array = _cache_analise.get(ch, [])
	if e.is_empty() or e[0] != linhas:
		if _cache_analise.size() > 200:
			_cache_analise.clear()
		e = [linhas.duplicate(), _analisar(linhas, paleta, tipo)]
		_cache_analise[ch] = e
	return e[1]

## Linha só de contorno (a borda de cima ou de baixo da peça).
static func _so_contorno(s: String) -> bool:
	var n: int = 0
	for ch in s:
		if ch == "o":
			n += 1
		elif ch != "." and ch != " ":
			return false
	return n >= s.length() * 0.6

## Mesma cor em tom mais claro ou mais escuro (luz e sombra do pano, não estampa).
static func _mesmo_tom(a: Color, b: Color) -> bool:
	if a.s < 0.16 and b.s < 0.16:
		return absf(a.v - b.v) < 0.12
	var dh: float = absf(a.h - b.h)
	dh = minf(dh, 1.0 - dh)
	return dh < 0.06 and absf(a.s - b.s) < 0.3 and absf(a.v - b.v) < 0.26

## Menor período `p` (2 períodos inteiros pelo menos) em que as linhas `rs` se repetem, nas colunas [a, b]; 0 = não se repetem.
## Autocorrelação: fração das células iguais à da coluna p adiante.
static func _periodo(rs: Array, a: int, b: int, limiar: float) -> int:
	var n: int = b - a + 1
	for p in range(1, n / 2 + 1):
		var iguais: int = 0
		var tot: int = 0
		for r in rs:
			var s: String = r
			for i in range(a, b - p + 1):
				tot += 1
				if s[i] == s[i + p]:
					iguais += 1
		if tot > 0 and float(iguais) / tot >= limiar:
			return p
	return 0

## Lê a peça de corpo do gato (12x8) e separa o que é dela, para refazê-la num tronco de outro tamanho:
##  - pano: as linhas de dentro do contorno, numa grade ("g"); a letra mais comum é a base;
##  - faixas: linhas tomadas por uma cor que não é a base (cinto, gola, barra, peito da camisa) — mantêm a espessura;
##  - lados: painéis de outra cor nas duas pontas (colante, robô);
##  - emblemas: manchas de cor única, que não se repetem e não são só luz/sombra do pano (reator, aranha, painel, bolso, lapela)
##    — voltam inteiros, no lugar correspondente, em dobro (scale2x) quando o tronco tem o dobro do tamanho;
##  - estampa: se o que sobra de outra cor no pano é bastante (>= 15%), ele é ladrilho: repete no período achado por
##    autocorrelação (listras da abelha, pelos da pele); senão é pano liso com detalhes no lugar (botões, rebites);
##  - crista e franja: o que fica acima e abaixo do contorno (espinhos, barbatana, asas, pavio; garras, franjas), repetidos no
##    período deles ao longo do dorso/bainha, ou inteiros no lugar;
##  - cores: contorno, luz e sombra do pano (tons da própria paleta quando há; senão calculados).
static func _analisar(linhas: Array, paleta: Dictionary, tipo: int) -> Dictionary:
	var dica: Dictionary = _DICAS.get(tipo, {})
	var w: int = 0
	for l in linhas:
		w = maxi(w, String(l).length())
	var pad: Array = []
	for l in linhas:
		pad.append(String(l).rpad(w, "."))
	var h: int = pad.size()
	# linhas de dentro: começam ou acabam no contorno e têm pano em boa parte da largura
	var dentro: Array = []
	var pano_n: Array = []
	for j in h:
		var s: String = pad[j]
		var a: int = -1
		var b: int = -1
		var n: int = 0
		for i in w:
			var c: String = s[i]
			if c != "." and c != " ":
				if a < 0:
					a = i
				b = i
				if c != "o":
					n += 1
		pano_n.append(n)
		dentro.append(a >= 0 and (s[a] == "o" or s[b] == "o") and n >= 0.4 * w)
	var j0: int = dentro.find(true)
	var j1: int = dentro.rfind(true)
	if j0 < 0:
		return {}
	if j0 > 0 and int(pano_n[j0 - 1]) >= 0.8 * w:
		j0 -= 1   # faixa cheia por cima do contorno (a cinta do avental)
	if j1 < h - 1 and int(pano_n[j1 + 1]) >= 0.8 * w:
		j1 += 1
	var c0: int = w
	var c1: int = -1
	for j in range(j0, j1 + 1):
		var s2: String = pad[j]
		for i in w:
			if s2[i] != "." and s2[i] != " " and s2[i] != "o":
				c0 = mini(c0, i)
				c1 = maxi(c1, i)
	var ws: int = c1 - c0 + 1
	var hs: int = j1 - j0 + 1
	# grade: o contorno e o vazio de fora de cada linha ficam "" (viram base ou faixa)
	var g: Array = []
	for j in range(j0, j1 + 1):
		var s3: String = pad[j]
		var ra: int = -1
		var rb: int = -1
		for i in range(c0, c1 + 1):
			if s3[i] != "." and s3[i] != " " and s3[i] != "o":
				if ra < 0:
					ra = i
				rb = i
		var row: Array = []
		for i in range(c0, c1 + 1):
			var c2: String = s3[i]
			row.append("" if (i < ra or i > rb or c2 == "." or c2 == " ") else c2)
		g.append(row)
	# base e faixas (duas passadas: a base sai das linhas que não são faixa)
	var base: String = dica.get("base", _mais_comum(g, []))
	var faixa: Array = []
	for passo in 2:
		faixa = []
		for row in g:
			var cont: Dictionary = {}
			var n2: int = 0
			for c3 in row:
				if c3 != "":
					cont[c3] = int(cont.get(c3, 0)) + 1
					n2 += 1
			var fx: String = ""
			for k in cont.keys():
				if k != base and k != "o" and int(cont[k]) >= 0.6 * maxi(n2, ws * 3 / 4):
					fx = k
			faixa.append(fx)
		if not dica.has("base"):
			var nb: String = _mais_comum(g, faixa)
			if nb == "" or nb == base:
				break
			base = nb
	for j in hs:
		for i in ws:
			if g[j][i] == "":
				g[j][i] = faixa[j] if faixa[j] != "" else base
	# lados: coluna das pontas com a mesma letra em todo o pano, diferente da base
	var lados: Array = [0, 0]
	var letra_lado: String = dica.get("lados", "")
	for ponta in 2:
		var lw: int = 0
		for d in ws / 3:
			var col: int = d if ponta == 0 else ws - 1 - d
			var ok: bool = true
			for j in hs:
				if faixa[j] != "":
					continue
				var c4: String = g[j][col]
				if letra_lado == "":
					letra_lado = c4 if c4 != base else ""
				if c4 != letra_lado or letra_lado == "":
					ok = false
					break
			if not ok:
				break
			lw += 1
		lados[ponta] = lw
	if lados[0] == 0 or lados[1] == 0:
		lados = [0, 0]   # painel só numa ponta é desenho (gola, lapela), não lateral
	# manchas (8 vizinhos) de cor que não é a base nem a faixa da linha (nem luz/sombra delas)
	var bcor: Color = paleta.get(base, Color.WHITE)
	var fundo_tom: Dictionary = {}
	for j in hs:
		for i in ws:
			var fu: String = _fundo_de(g, faixa, base, j)
			fundo_tom[Vector2i(i, j)] = g[j][i] == fu or (g[j][i] != "o" and _mesmo_tom(paleta.get(g[j][i], bcor), paleta.get(fu, bcor)))
	var visto: Dictionary = {}
	var manchas: Array = []
	for j in hs:
		for i in range(lados[0], ws - lados[1]):
			if visto.has(Vector2i(i, j)) or fundo_tom[Vector2i(i, j)]:
				continue
			var px: Dictionary = {}
			var pilha: Array = [Vector2i(i, j)]
			visto[Vector2i(i, j)] = true
			var so_faixa: bool = true
			while not pilha.is_empty():
				var p: Vector2i = pilha.pop_back()
				px[p] = g[p.y][p.x]
				if faixa[p.y] == "":
					so_faixa = false
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var q := Vector2i(p.x + dx, p.y + dy)
						if q.x < lados[0] or q.y < 0 or q.x >= ws - lados[1] or q.y >= hs or visto.has(q):
							continue
						if fundo_tom[q]:
							continue
						visto[q] = true
						pilha.append(q)
			var caixa := Rect2i()
			var letras: Dictionary = {}
			var prim: bool = true
			for p2 in px.keys():
				var v2: Vector2i = p2
				caixa = Rect2i(v2, Vector2i.ONE) if prim else caixa.expand(v2).expand(v2 + Vector2i.ONE)
				prim = false
				letras[px[p2]] = true
			var ks: Array = letras.keys()
			ks.sort()
			manchas.append([px, caixa, "%s:%d:%s:%s" % ["".join(ks), px.size(), caixa.size, so_faixa], ks])
	var cont_sig: Dictionary = {}
	for m in manchas:
		cont_sig[m[2]] = int(cont_sig.get(m[2], 0)) + 1
	var emblemas: Array = []
	var gola: String = ""
	# estampa periódica no pano (listras da abelha): achada antes, ela não vira emblema (a última listra cortada pelo contorno é
	# diferente das outras e parecia mancha única)
	var pano_rs0: Array = []
	var outras0: int = 0
	var tot0: int = 0
	for j in hs:
		if faixa[j] == "":
			pano_rs0.append("".join(g[j]))
			for i in range(lados[0], ws - lados[1]):
				tot0 += 1
				if g[j][i] != base:
					outras0 += 1
	var periodo0: int = 0
	if tot0 > 0 and float(outras0) / tot0 >= 0.15:
		periodo0 = _periodo(pano_rs0, lados[0], ws - 1 - lados[1], 0.9)
	for m in manchas:
		var pxm: Dictionary = m[0]
		if periodo0 > 0 or int(cont_sig[m[2]]) > 1 or pxm.size() < 3 or pxm.size() > ws * hs * 0.6:
			continue
		var tom: bool = true
		for le in m[3]:
			if le == "o" or not _mesmo_tom(paleta.get(le, bcor), bcor):
				tom = false
		if tom:
			continue
		var cx: Rect2i = m[1]
		var grade: Array = []
		for j in cx.size.y:
			var s4: String = ""
			for i in cx.size.x:
				var q2 := Vector2i(cx.position.x + i, cx.position.y + j)
				s4 += String(pxm[q2]) if pxm.has(q2) else "."
			grade.append(s4)
		for p3 in pxm.keys():
			var v3: Vector2i = p3
			g[v3.y][v3.x] = _fundo_de(g, faixa, base, v3.y)
		if cx.position.y == 0 and cx.end.x >= ws and cx.size.y < hs:
			# mancha no canto da frente, em cima: gola/lapela — vira a gola do bicho, junto do pescoço
			var cg: Dictionary = {}
			for p4 in pxm.keys():
				cg[pxm[p4]] = int(cg.get(pxm[p4], 0)) + 1
			for le4 in cg.keys():
				if gola == "" or int(cg[le4]) > int(cg[gola]):
					gola = le4
			continue
		emblemas.append([grade, cx])
	if dica.has("alcas"):
		# macacão: o pano é só a base; peito, alças e botões são desenhados por _alcas
		for j in hs:
			faixa[j] = ""
			for i in ws:
				g[j][i] = base
		emblemas = []
	# estampa: quanto de outra cor sobra no pano
	var outras: int = 0
	var tot_pano: int = 0
	var pano_rs: Array = []
	for j in hs:
		if faixa[j] != "":
			continue
		var s5: String = ""
		for i in ws:
			s5 += String(g[j][i])
			if i >= lados[0] and i < ws - lados[1]:
				tot_pano += 1
				if g[j][i] != base:
					outras += 1
		pano_rs.append(s5)
	var tex: bool = tot_pano > 0 and float(outras) / tot_pano >= 0.15
	var px_t: int = 0
	if tex or dica.has("tex"):
		px_t = _periodo(pano_rs, lados[0], ws - 1 - lados[1], 0.9)
		if px_t == 0:
			# sem período: só a dica "tex" (pelagem) faz do pano inteiro o ladrilho; o resto é desenho no lugar (lapelas em V)
			tex = dica.has("tex")
			px_t = ws - lados[0] - lados[1]
		else:
			tex = true
	var r: Dictionary = {"g": g, "faixa": faixa, "base": base, "lados": lados, "emblemas": emblemas, "tex": tex, "px": px_t,
		"ws": ws, "hs": hs, "paleta": paleta}
	gola = dica.get("gola", gola)
	if gola != "":
		r["gola"] = gola
	if dica.has("ladrilho"):
		r["ladrilho"] = dica["ladrilho"]
	if dica.has("alcas"):
		r["alcas"] = dica["alcas"]
	# crista (acima do contorno) e franja (abaixo)
	for parte in ["crista", "franja"]:
		var rs2: Array = []
		var faixa_j: Array = range(0, j0) if parte == "crista" else range(j1 + 1, h)
		for j in faixa_j:
			var s6: String = pad[j]
			if s6.replace(".", "").replace(" ", "") == "" or (_so_contorno(s6) and (j == j0 - 1 or j == j1 + 1)):
				continue
			rs2.append([s6, (j0 - j) if parte == "crista" else (j - j1)])
		if rs2.is_empty():
			continue
		var a2: int = w
		var b2: int = -1
		var so_rs: Array = []
		for it in rs2:
			var s7: String = it[0]
			so_rs.append(s7)
			for i in w:
				if s7[i] != "." and s7[i] != " ":
					a2 = mini(a2, i)
					b2 = maxi(b2, i)
		var per: int = _periodo(so_rs, a2, b2, 0.85) if b2 - a2 + 1 >= 5 else 0
		if per > (b2 - a2 + 1) / 2:
			per = 0
		r[parte] = {"rs": rs2, "p": per, "a": a2, "b": b2, "c0": c0}
	# cores: contorno, luz e sombra do pano (tons da paleta quando há)
	r["contorno"] = paleta.get("o", Color.from_hsv(bcor.h, minf(1.0, bcor.s * 1.1), bcor.v * 0.35))
	var luz: Color = Color.from_hsv(bcor.h, bcor.s * 0.8, minf(1.0, bcor.v * 1.18 + 0.04))
	var sombra: Color = Color.from_hsv(bcor.h, minf(1.0, bcor.s * 1.08), bcor.v * 0.76)
	var dl: float = 9.0
	var ds: float = 9.0
	var no_pano: Dictionary = {}
	for row2 in g:
		for le5 in row2:
			no_pano[le5] = true
	for le2 in paleta.keys():
		if le2 == "o" or le2 == base or not no_pano.has(le2):
			continue
		var cc: Color = paleta[le2]
		if not _mesmo_tom(cc, bcor):
			continue
		var dv: float = cc.v - bcor.v + (cc.s - bcor.s) * -0.3
		if dv > 0.04 and dv < dl:
			dl = dv
			luz = cc
		elif dv < -0.04 and -dv < ds and cc.v > bcor.v * 0.45:
			ds = -dv
			sombra = cc
	r["luz"] = luz
	r["sombra"] = sombra
	return r

## Letra mais comum da grade, fora as linhas de faixa (`faixa` vazio = todas).
static func _mais_comum(g: Array, faixa: Array) -> String:
	var cont: Dictionary = {}
	for j in g.size():
		if not faixa.is_empty() and faixa[j] != "":
			continue
		for c in g[j]:
			if c != "" and c != "o":
				cont[c] = int(cont.get(c, 0)) + 1
	var m: String = ""
	for k in cont.keys():
		if m == "" or int(cont[k]) > int(cont[m]):
			m = k
	return m

static func _fundo_de(_g: Array, faixa: Array, base: String, j: int) -> String:
	return faixa[j] if faixa[j] != "" else base

## Linha da grade da peça para cada uma das `k` linhas do pano no bicho: as faixas mantêm a espessura (em dobro quando há espaço),
## os trechos de pano repartem o resto na proporção do tamanho — liso: repete a linha mais lisa do trecho, como cópia limpa
## (índice negativo -j-1: só o que continua na vertical, lado, listra, fica; botão e lapela não se repetem); estampa: o trecho
## se repete inteiro.
static func _fila(an: Dictionary, k: int) -> PackedInt32Array:
	var hs: int = an["hs"]
	var faixa: Array = an["faixa"]
	var g: Array = an["g"]
	var base: String = an["base"]
	var r := PackedInt32Array()
	if k <= 0:
		return r
	var idx: Array = range(hs)
	if k < hs:
		# tira primeiro linhas de pano repetidas, depois as de pano, depois as faixas do meio
		while idx.size() > k:
			var tirou: bool = false
			for fase in 3:
				for m in range(idx.size() - 1, -1, -1):
					var j: int = idx[m]
					var e_pano: bool = faixa[j] == ""
					var ok: bool = false
					if fase == 0:
						ok = e_pano and m > 0 and g[idx[m - 1]] == g[j]
					elif fase == 1:
						ok = e_pano
					else:
						ok = m > 0 and m < idx.size() - 1
					if ok:
						idx.remove_at(m)
						tirou = true
						break
				if tirou:
					break
			if not tirou:
				idx.remove_at(idx.size() / 2)
		for j2 in idx:
			r.append(j2)
		return r
	var esp: Array = []
	esp.resize(hs)
	esp.fill(1)
	var nf: int = 0
	for j in hs:
		if faixa[j] != "":
			nf += 1
	if nf < hs and k >= 2 * hs:
		for j in hs:
			if faixa[j] != "":
				esp[j] = 2
	var soma: int = 0
	for e in esp:
		soma += e
	var sobra: int = k - soma
	if sobra < 0:
		esp.fill(1)
		sobra = k - hs
	# trechos de pano (linhas seguidas que não são faixa)
	var trechos: Array = []
	var j3: int = 0
	while j3 < hs:
		if faixa[j3] != "":
			j3 += 1
			continue
		var a: int = j3
		while j3 < hs and faixa[j3] == "":
			j3 += 1
		trechos.append([a, j3 - a])
	if trechos.is_empty():
		# só faixas (listras): cada uma engorda por igual
		var m2: int = 0
		while sobra > 0:
			esp[m2 % hs] += 1
			sobra -= 1
			m2 += 1
		for j4 in hs:
			for t in esp[j4]:
				r.append(j4)
		return r
	# a sobra se reparte entre os trechos de pano na proporção do tamanho deles: as faixas do meio (cinto) caem na mesma altura
	# relativa em todas as colunas e acompanham o dorso e a bainha
	var extra: Dictionary = {}
	var limpas: Dictionary = {}
	var tot_l: int = 0
	for t2 in trechos:
		tot_l += int(t2[1])
	var acum: int = 0
	var dado: int = 0
	for t3 in trechos:
		acum += int(t3[1])
		var ate: int = roundi(float(sobra) * acum / tot_l)
		extra[int(t3[0])] = ate - dado
		dado = ate
	for t4 in trechos:
		var ma: int = t4[0]
		var ml: int = t4[1]
		var ex: int = extra[ma]
		if an["tex"]:
			# estampa: o trecho se repete até encher; a primeira e a última linha (borda da peça) ficam nas pontas
			var ini: int = ma
			var fim: int = ma + ml - 1
			if ml >= 3:
				ini += 1
				fim -= 1
				esp[ma] = [ma]
			else:
				esp[ma] = []
			var n: int = fim - ini + 1
			for t5 in n + ex:
				esp[ma].append(ini + t5 % n)
			if ml >= 3:
				esp[ma].append(ma + ml - 1)
			for jj in range(ma + 1, ma + ml):
				esp[jj] = []
			continue
		# liso: a sobra repete a linha mais lisa do trecho (mais base; empate: a do meio)
		var lisa: int = ma
		var nota_l: float = -1.0
		for jj2 in range(ma, ma + ml):
			var nb: int = 0
			for c in g[jj2]:
				if c == base:
					nb += 1
			var nota: float = nb - absf(jj2 - (ma + (ml - 1) * 0.5)) * 0.1
			if nota > nota_l:
				nota_l = nota
				lisa = jj2
		limpas[lisa] = ex
	for j5 in hs:
		if esp[j5] is Array:
			for jj3 in esp[j5]:
				r.append(jj3)
		else:
			for t6 in int(esp[j5]):
				r.append(j5)
			for t7 in int(limpas.get(j5, 0)):
				r.append(-j5 - 1)   # cópia limpa: só fica o que continua de cima a baixo (ver _alfaiate)
	return r

## Coluna da grade da peça para cada uma das `w` colunas do bicho (pano liso e faixas): as pontas ficam, as colunas a mais
## repetem a coluna mais lisa do miolo, repartidas a partir do meio, como cópia limpa (-i-1) — nada de listra inventada.
static func _coluna(an: Dictionary, w: int) -> PackedInt32Array:
	var ws: int = an["ws"]
	var g: Array = an["g"]
	var r := PackedInt32Array()
	var cols: Array = []
	for i in ws:
		var s: String = ""
		for row in g:
			s += String(row[i])
		cols.append(s)
	var cont: Dictionary = {}
	for i in range(1, ws - 1):
		cont[cols[i]] = int(cont.get(cols[i], 0)) + 1
	# a mais lisa: mais pixels de base; empate: a mais comum
	var base: String = an["base"]
	var lisa: String = ""
	var nota_l: int = -1
	for k in cont.keys():
		var nb: int = 0
		for ch in String(k):
			if ch == base:
				nb += 1
		if nb * 100 + int(cont[k]) > nota_l:
			nota_l = nb * 100 + int(cont[k])
			lisa = k
	var lisas: Array = []
	for i in range(1, ws - 1):
		if cols[i] == lisa:
			lisas.append(i)
	lisas.sort_custom(func(a, b): return absf(a - (ws - 1) * 0.5) < absf(b - (ws - 1) * 0.5))
	if lisas.is_empty():
		lisas = [ws / 2]
	if w <= ws:
		var idx: Array = range(ws)
		var m: int = 0
		while idx.size() > w:
			var alvo: int = lisas[m % lisas.size()] if m < lisas.size() else idx[idx.size() / 2]
			var pos: int = idx.find(alvo)
			idx.remove_at(pos if pos >= 0 else idx.size() / 2)
			m += 1
		for i2 in idx:
			r.append(i2)
		return r
	var extra: Array = []
	extra.resize(ws)
	extra.fill(0)
	for t in w - ws:
		extra[lisas[t % lisas.size()]] += 1
	for i3 in ws:
		r.append(i3)
		for t2 in extra[i3]:
			r.append(-i3 - 1)   # cópia limpa: só fica o que continua na horizontal (faixa); botão e emblema não se repetem
	return r

## Scale2x (EPX): o emblema em dobro, com as quinas arredondadas pelo próprio desenho (mesmo pixel do bicho).
static func _dobro(gr: Array) -> Array:
	var h: int = gr.size()
	var w: int = String(gr[0]).length() if h > 0 else 0
	var r: Array = []
	for j in h:
		var s0: String = ""
		var s1: String = ""
		for i in w:
			var p: String = String(gr[j])[i]
			var a: String = String(gr[j - 1])[i] if j > 0 else "."
			var b: String = String(gr[j])[i + 1] if i < w - 1 else "."
			var c: String = String(gr[j])[i - 1] if i > 0 else "."
			var d: String = String(gr[j + 1])[i] if j < h - 1 else "."
			s0 += (a if (c == a and c != d and a != b) else p) + (b if (a == b and a != c and b != d) else p)
			s1 += (c if (d == c and d != b and c != a) else p) + (d if (b == d and b != a and d != c) else p)
		r.append(s0)
		r.append(s1)
	return r

## O emblema em dobro, cada pixel virando 2x2 (para desenhos vazados, que o scale2x embola).
static func _dobro_cheio(gr: Array) -> Array:
	var r: Array = []
	for lg in gr:
		var s: String = ""
		for ch in String(lg):
			s += ch + ch
		r.append(s)
		r.append(s)
	return r

## Refaz a peça lida (_analisar) sobre o molde do tronco do bicho (mascara): cobre o dorso até `cobre` da altura de cada coluna
## (barriga e patas à mostra), as linhas acompanham a curva das costas, bainha de contorno onde a roupa acaba sobre o corpo,
## luz na linha de cima e sombra nas de baixo, faixas, lados, estampa no período dela, emblemas inteiros e crista/franja.
## Devolve [retângulos, cores] em pixels do bicho.
static func _alfaiate(an: Dictionary) -> Array:
	if an.is_empty() or mascara.is_empty():
		return []
	var paleta: Dictionary = an["paleta"]
	var base: String = an["base"]
	# colunas do molde: alto e altura
	var topo: Dictionary = {}
	var alt: Dictionary = {}
	var x0: int = 1 << 20
	var x1: int = -(1 << 20)
	for p in mascara.keys():
		var v: Vector2i = p
		topo[v.x] = mini(int(topo.get(v.x, v.y)), v.y)
		alt[v.x] = int(alt.get(v.x, 0)) + 1
		x0 = mini(x0, v.x)
		x1 = maxi(x1, v.x)
	var W: int = x1 - x0 + 1
	var roupa: Dictionary = {}   # Vector2i -> v (linha a partir do alto)
	var fundo: Dictionary = {}   # x -> k (linhas de pano da coluna, sem a bainha)
	# bainha reta: a roupa pende do dorso até a mesma linha em todas as colunas (como manta), a `cobre` da altura do tronco;
	# nas pontas, onde o dorso desce, fica pelo menos uma tira de 3 linhas
	var y_alto: int = 1 << 20
	var y_baixo: int = -(1 << 20)
	for x6 in topo.keys():
		y_alto = mini(y_alto, int(topo[x6]))
		y_baixo = maxi(y_baixo, int(topo[x6]) + int(alt[x6]) - 1)
	var y_linha: int = y_alto + roundi(cobre * (y_baixo - y_alto + 1))
	for x in range(x0, x1 + 1):
		if not topo.has(x):
			continue
		var n: int = alt[x]
		var d: int = clampi(y_linha - int(topo[x]), mini(3, n), n)
		fundo[x] = d - 1 if d < n else d
		for v2 in d:
			var q := Vector2i(x, int(topo[x]) + v2)
			if mascara.has(q):
				roupa[q] = v2
	# bainha: borda da roupa que encosta em corpo à mostra (molde fora da roupa, cabeça, pescoço)
	var borda: Dictionary = {}
	for p2 in roupa.keys():
		var v3: Vector2i = p2
		for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q2: Vector2i = v3 + dd
			if roupa.has(q2):
				continue
			if mascara.has(q2) or _corpo(q2):
				borda[v3] = true
				break
	# meio do dorso: média das colunas pesada pela altura da roupa (as colunas da frente, sob a cabeça, quase não têm pano)
	var soma_x: float = 0.0
	var soma_k: float = 0.0
	for x5 in fundo.keys():
		soma_x += float(x5) * int(fundo[x5])
		soma_k += int(fundo[x5])
	var xm: float = soma_x / maxf(1.0, soma_k) - x0 + 0.5   # em u
	var cor: Dictionary = {}   # Vector2i -> Color
	var colmap: PackedInt32Array = _coluna(an, W)
	var g: Array = an["g"]
	var faixa: Array = an["faixa"]
	var ws: int = an["ws"]
	var hs: int = an["hs"]
	var lados: Array = an["lados"]
	var tex: bool = an["tex"]
	var pxt: int = an["px"]
	var miolo: int = ws - lados[0] - lados[1]
	var fase: int = (W - ws) / 2 + lados[0]
	var ladr: Array = an.get("ladrilho", [])
	var luz: Color = an["luz"]
	var sombra: Color = an["sombra"]
	# linhas da peça na altura toda (K = do alto do dorso até a bainha): as faixas de cima (antes do primeiro pano) acompanham a
	# curva das costas; o resto (cinto, listras, barriga, barra) fica em linhas retas, paralelas à bainha
	var K: int = maxi(1, y_linha - y_alto)
	var fl: PackedInt32Array = _fila(an, K)
	var pano0: int = faixa.find("")
	var t_alto: int = 0
	while pano0 > 0 and t_alto < fl.size() and absi(fl[t_alto]) < pano0:
		t_alto += 1
	for p3 in roupa.keys():
		var v4: Vector2i = p3
		if borda.has(v4):
			cor[v4] = an["contorno"]
			continue
		var u: int = v4.x - x0
		var lv: int = roupa[v4]
		var va: int = v4.y - y_alto
		var ia: int = lv if lv < t_alto else clampi(va, t_alto, fl.size() - 1)
		var sr: int = fl[clampi(ia, 0, fl.size() - 1)] if fl.size() > 0 else 0
		var sc: int = colmap[u]
		var lin_limpa: bool = sr < 0
		var col_limpa: bool = sc < 0
		if lin_limpa:
			sr = -sr - 1
		if col_limpa:
			sc = -sc - 1
		var letra: String
		var lado: bool = sc < lados[0] or sc >= ws - lados[1]
		if faixa[sr] == "" and not lado and not ladr.is_empty():
			var tr: String = ladr[va % ladr.size()]
			letra = tr[posmod(u - fase, tr.length())]
			if letra == ".":
				letra = base
		elif faixa[sr] == "" and tex and not lado and u >= lados[0] and u < W - lados[1]:
			letra = g[sr][lados[0] + posmod(u - fase, pxt) % miolo]
		else:
			letra = g[sr][sc]
			var fu: String = faixa[sr] if faixa[sr] != "" else base
			if lin_limpa and letra != fu and not ((sr == 0 or g[sr - 1][sc] == letra) and (sr == hs - 1 or g[sr + 1][sc] == letra)):
				letra = fu
			if col_limpa and letra != fu and not ((sc == 0 or g[sr][sc - 1] == letra) and (sc == ws - 1 or g[sr][sc + 1] == letra)):
				letra = fu
		var c: Color = paleta.get(letra, an["contorno"])
		if letra == base:
			if lv == 0 and K >= 3:
				c = luz
			elif K >= 4 and (v4.y == y_linha - 1 or (K >= 8 and v4.y == y_linha - 2)):
				c = sombra
		cor[v4] = c
	# gola: a cor da lapela do gato numa tira junto do pescoço (frente da roupa), da metade de cima, mais a beira de cima perto dela
	if an.has("gola"):
		var c_gola: Color = paleta.get(an["gola"], an["contorno"])
		var gw: int = 2 if W >= ws * 2 - 2 else 1
		for p5 in roupa.keys():
			var v6: Vector2i = p5
			if borda.has(v6):
				continue
			var df: int = 0
			while df <= gw + 2 and roupa.has(v6 + Vector2i(df + 1, 0)) and not borda.has(v6 + Vector2i(df + 1, 0)):
				df += 1
			var lv2: int = roupa[v6]
			var kg: int = maxi(1, roundi(int(fundo[v6.x]) * 0.55))
			if (df < gw and lv2 <= kg) or (lv2 == 0 and df < gw + 2):
				cor[v6] = c_gola
	# alças (macacão): o peito (faixas de cima) é cortado por duas alças que descem até o pano, com botão na ponta
	if an.has("alcas"):
		_alcas(an, roupa, borda, cor, y_alto + maxi(2, roundi(K * 0.42)), x0 + roundi(xm), W)
	# emblemas: inteiros, no lugar correspondente (em dobro quando o tronco tem o dobro do tamanho), presos ao alto do tronco
	for em in an["emblemas"]:
		var gr: Array = em[0]
		var cx: Rect2i = em[1]
		var xc0: int = x0 + clampi(roundi(xm + ((cx.position.x + cx.size.x * 0.5) / ws - 0.5) * W), 0, W - 1)
		var kc: int = K
		if cx.size.y * 2 <= kc - 1 and cx.size.x * 2 <= W * 0.6:
			var vazios: int = 0
			for lg in gr:
				vazios += String(lg).count(".")
			# rendado (aranha: pernas e vãos) dobra pixel a pixel; o resto em scale2x, que arredonda as quinas
			gr = _dobro(gr) if vazios < cx.size.x * cx.size.y * 0.25 else _dobro_cheio(gr)
		var ew: int = String(gr[0]).length()
		var eh: int = gr.size()
		var ex: int
		if cx.position.x == 0:
			ex = 0
		elif cx.end.x >= ws:
			ex = W - ew
		else:
			ex = xc0 - x0 - ew / 2
		ex = clampi(ex, 0, maxi(0, W - ew))
		var ey: int
		if cx.size.y * 2 > hs:
			ey = roundi((cx.position.y + cx.size.y * 0.5) / hs * kc - eh * 0.5)   # emblema grande: no meio do pano
		elif cx.position.y == 0:
			ey = 0
		elif cx.end.y >= hs:
			ey = kc - eh
		else:
			ey = roundi((cx.position.y + cx.size.y * 0.5) / hs * kc - eh * 0.5)
		ey = clampi(ey, 0, maxi(0, kc - eh))
		var ya: int = y_alto
		for j in eh:
			for i in ew:
				var le: String = String(gr[j])[i]
				if le == ".":
					continue
				var q3 := Vector2i(x0 + ex + i, ya + ey + j)
				if roupa.has(q3) and not borda.has(q3):
					cor[q3] = paleta.get(le, an["contorno"])
	# crista (espinhos, barbatana, asas) no dorso e franja (garras, franjas) na bainha
	for parte in ["crista", "franja"]:
		if not an.has(parte):
			continue
		var cr: Dictionary = an[parte]
		var per: int = cr["p"]
		if per > 0:
			for u2 in range(1, W - 1):
				var x2: int = x0 + u2
				if not topo.has(x2):
					continue
				var sc2: int = int(cr["a"]) + posmod(u2 - 1, per)
				for it in cr["rs"]:
					var le2: String = String(it[0])[sc2]
					if le2 == "." or le2 == " ":
						continue
					var yy: int = int(topo[x2]) - int(it[1]) if parte == "crista" else int(topo[x2]) + int(fundo[x2]) - 1 + int(it[1])
					cor[Vector2i(x2, yy)] = paleta.get(le2, an["contorno"])
		else:
			var meio: float = (int(cr["a"]) + int(cr["b"]) + 1) * 0.5
			var xa2: int = x0 + clampi(roundi(xm + ((meio - int(cr["c0"])) / ws - 0.5) * W), 1, W - 2)
			if not topo.has(xa2):
				continue
			for it2 in cr["rs"]:
				var s8: String = it2[0]
				for i2 in range(int(cr["a"]), int(cr["b"]) + 1):
					var le3: String = s8[i2]
					if le3 == "." or le3 == " ":
						continue
					var x3: int = xa2 + i2 - roundi(meio)
					var yy2: int = int(topo[xa2]) - int(it2[1]) if parte == "crista" else int(topo[xa2]) + int(fundo[xa2]) - 1 + int(it2[1])
					var q4 := Vector2i(x3, yy2)
					if parte == "crista" and roupa.has(q4):
						continue
					cor[q4] = paleta.get(le3, an["contorno"])
	# retângulos por linha, juntando vizinhos da mesma cor
	var rs: Array = []
	var cs := PackedColorArray()
	var ys: Dictionary = {}
	for p4 in cor.keys():
		var v5: Vector2i = p4
		if not ys.has(v5.y):
			ys[v5.y] = []
		ys[v5.y].append(v5.x)
	for y in ys.keys():
		var xs: Array = ys[y]
		xs.sort()
		var i3: int = 0
		while i3 < xs.size():
			var c5: Color = cor[Vector2i(xs[i3], y)]
			var n3: int = 1
			while i3 + n3 < xs.size() and xs[i3 + n3] == xs[i3] + n3 and cor[Vector2i(xs[i3 + n3], y)] == c5:
				n3 += 1
			rs.append(Rect2(xs[i3], y, n3 + 0.03, 1.03))
			cs.append(c5)
			i3 += n3
	return [rs, cs]

## Pixel do bicho à mostra (nem vazio nem contorno) no quadro em desenho.
static func _corpo(p: Vector2i) -> bool:
	if molde_quadro.is_empty():
		return false
	var ls: Array = molde_quadro["l"]
	var j: int = p.y - int(molde_quadro["y"])
	var i: int = p.x - int(molde_quadro["x"])
	if j < 0 or j >= ls.size() or i < 0 or i >= String(ls[j]).length():
		return false
	var ch: String = String(ls[j])[i]
	return ch != "." and ch != "o"

## Alças do macacão (dica "alcas" = [alça, botão, peito]): o peito da camisa vai do dorso até a linha `y_peito` (pelo menos
## 2 linhas nas pontas), e duas alças da cor do macacão sobem por ele dos dois lados do meio `xm`, com o botão onde encontram o pano.
static func _alcas(an: Dictionary, roupa: Dictionary, borda: Dictionary, cor: Dictionary, y_peito: int, xm: int, W: int) -> void:
	var paleta: Dictionary = an["paleta"]
	var al: Array = an["alcas"]
	var c_alca: Color = paleta.get(al[0], an["contorno"])
	var c_botao: Color = paleta.get(al[1], an["contorno"])
	var c_peito: Color = paleta.get(al[2], an["contorno"])
	var c_peito_luz: Color = Color.from_hsv(c_peito.h, c_peito.s * 0.75, minf(1.0, c_peito.v * 1.12 + 0.05))
	var meia: int = maxi(2, roundi(W * 0.2))
	var xs: Array = [xm - meia, xm + meia - 1]
	for p in roupa.keys():
		var v: Vector2i = p
		if borda.has(v):
			continue
		var lv: int = roupa[v]
		if v.y >= y_peito and lv >= 2:
			continue
		var alca: bool = false
		for xa in xs:
			if v.x == xa or v.x == xa + 1:
				alca = true
		cor[v] = c_alca if alca else (c_peito_luz if lv == 0 else c_peito)
	for xa2 in xs:
		for dx in 2:
			var q := Vector2i(xa2 + dx, y_peito)
			if roupa.has(q) and not borda.has(q):
				cor[q] = c_botao

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
