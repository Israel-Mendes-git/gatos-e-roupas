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
static func sprite(c: CanvasItem, x: float, y: float, linhas: Array, paleta: Dictionary, f: float = 0.0) -> void:
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
			c.draw_rect(Rect2(x + i, y + j, n + 0.03, 1.03), Desenho.b(paleta[ch], f))
			i += n
