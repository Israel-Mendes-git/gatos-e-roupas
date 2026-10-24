class_name ChefeGangue
extends RefCounted
## Os cinco chefes de gangue do 3º ato (Fases.Chefe 10 a 14): o gato do jogo com pelagem, traços e marca próprios.
## A fantasia que o chefe veste continua por cima (é o prêmio); o que é dele fica em três camadas, na grade do sprite
## do gato (1 unidade = 1 pixel do sprite), com a origem já posta por Desenho em cada lugar do corpo (RoupaGato.origem):
##   atras(): atrás do gato e das roupas (capa, cabelo, disco);
##   corpo(): sobre o pelo e sob as roupas (bochechas, barba, circuitos);
##   marca(): por cima de tudo, para a roupa não esconder quem ele é (rosa, máscara, olho, crista, metais).
## Gato virado para a direita: +x é a frente, -y é para cima.

enum G { GATLEONE, IMORTAL, MESTRE, MIAUNIDAS, MAGNETO }

## Pelagem de cada chefe ([textura, tinta]): diferente da dos rivais da gangue (Fases.GANGUE_PELAGEM).
const PELAGEM: Array = [
	[2, Color(0.66, 0.66, 0.72)],   # Dom Gatleone: persa cinza
	[2, Color(1.0, 1.0, 0.98)],     # Imortal Miau: branco-giz
	[0, Color(0.42, 0.44, 0.52)],   # Programa Mestre: preto-azulado
	[1, Color(1.0, 0.86, 0.58)],    # Rei Miaunidas: dourado
	[2, Color(0.8, 0.82, 0.9)],      # Magnetomiau: prata
]

const CONT := Color(0.09, 0.06, 0.08)

static func _p(c: CanvasItem, x: int, y: int, w: int, h: int, cor: Color, alfa: float) -> void:
	c.draw_rect(Rect2(x, y, w, h), Color(cor.r, cor.g, cor.b, cor.a * alfa))

## Quantos pixels a coisa sobe/desce com o passo (o corpo balança 1 px nos quadros de andar).
static func _balanco(anim: float) -> int:
	return 1 if posmod(int(anim * 1.3), 4) >= 2 else 0

# ------------------------------------------------------------------ atrás
## Origem: TRASEIRA (alto da anca). `onde` diz ao Desenho onde pôr a origem.
const ATRAS_ONDE: Array[int] = [-1, -1, RoupaGato.Onde.TRASEIRA, RoupaGato.Onde.PESCOCO, RoupaGato.Onde.PESCOCO]

static func atras(c: CanvasItem, g: int, anim: float, andando: bool, alfa: float) -> void:
	var on: int = 1 if andando and posmod(int(anim * 1.3), 2) == 1 else 0   # capa e cabelo ondulam no passo
	match g:
		G.MESTRE:
			# disco de luz preso nas costas: aparece por cima do lombo (origem: alto da anca)
			var vm := Color(1.0, 0.18, 0.12)
			_p(c, 2, -5, 7, 7, CONT, alfa)
			_p(c, 3, -4, 5, 5, vm, alfa)
			_p(c, 4, -3, 3, 3, Color(0.25, 0.04, 0.05), alfa)
			_p(c, 5, -2, 1, 1, Color(1.0, 0.75, 0.6), alfa)
		G.MIAUNIDAS, G.MAGNETO:
			# capa presa no pescoço caindo para trás até perto do chão (origem: pescoço)
			var ca: Color = Color(0.78, 0.1, 0.08) if g == G.MIAUNIDAS else Color(0.5, 0.18, 0.62)
			var cs2: Color = ca.darkened(0.45)
			var fim: int = 9 if g == G.MIAUNIDAS else 7   # a capa do rei é a mais comprida
			_p(c, -13 - on, -2, 15, fim + 1, CONT, alfa)
			_p(c, -12 - on, -1, 13, fim - 1, ca, alfa)
			_p(c, -12 - on, fim - 3, 13, 1, cs2, alfa)
			for k in 3:
				_p(c, -10 + k * 4 - on, 0, 1, fim - 3, cs2, alfa)   # dobras

# ------------------------------------------------------------------ sobre o corpo
const CORPO_ONDE: Array[int] = [RoupaGato.Onde.CORPO, RoupaGato.Onde.PESCOCO, RoupaGato.Onde.PESCOCO, RoupaGato.Onde.BOCA, RoupaGato.Onde.ROSTO]

static func corpo(c: CanvasItem, g: int, alfa: float) -> void:
	match g:
		G.GATLEONE:
			# barriga caída de persa sob o tronco, peito e bochechas brancos (origem: centro do tronco)
			var cz := Color(0.6, 0.6, 0.66)
			var cl := Color(0.97, 0.96, 0.93)
			_p(c, -6, 4, 12, 3, CONT, alfa)
			_p(c, -5, 4, 10, 2, cz, alfa)
			_p(c, -3, 5, 6, 1, cl, alfa)
			_p(c, 6, -3, 3, 5, cl, alfa)    # peito
			_p(c, 9, -2, 3, 3, CONT, alfa)  # papada sob o focinho
			_p(c, 9, -2, 2, 2, cl, alfa)
		G.IMORTAL:
			# costelas pintadas no peito e o cabelo branco caindo da nuca pelas costas (origem: pescoço)
			var cr := Color(0.55, 0.55, 0.58)
			for k in 3:
				_p(c, -1 + k * 2, 2, 1, 3, cr, alfa)
			_p(c, -6, -4, 6, 3, CONT, alfa)
			_p(c, -8, -2, 4, 4, CONT, alfa)
			_p(c, -5, -3, 5, 1, Color(1, 1, 1), alfa)
			_p(c, -7, -1, 3, 2, Color(1, 1, 1), alfa)
			_p(c, -7, 0, 2, 1, Color(0.7, 0.7, 0.72), alfa)
		G.MESTRE:
			# circuitos vermelhos no pelo do peito e do flanco (origem: pescoço)
			var vm := Color(1.0, 0.25, 0.15)
			_p(c, -6, 3, 7, 1, vm, alfa)
			_p(c, -6, 3, 1, 3, vm, alfa)
			_p(c, 0, 1, 1, 3, vm, alfa)
		G.MIAUNIDAS:
			# barba castanha em ponta sob o focinho (origem: ponta do focinho)
			var br := Color(0.28, 0.15, 0.07)
			_p(c, -4, 1, 4, 3, CONT, alfa)
			_p(c, -3, 1, 3, 2, br, alfa)
			_p(c, -3, 3, 2, 2, CONT, alfa)
			_p(c, -3, 3, 1, 1, br, alfa)
		G.MAGNETO:
			# sobrancelha grossa e branca de velho (origem: entre os olhos)
			_p(c, -1, -1, 3, 1, Color(1, 1, 1), alfa)

# ------------------------------------------------------------------ marca (por cima da roupa)
const MARCA_ONDE: Array[int] = [RoupaGato.Onde.PESCOCO, RoupaGato.Onde.BOCA, RoupaGato.Onde.ROSTO, RoupaGato.Onde.CABECA, RoupaGato.Onde.CORPO]

static func marca(c: CanvasItem, g: int, anim: float, alfa: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	match g:
		G.GATLEONE:
			# rosa vermelha na lapela (origem: pescoço), com o cabo e uma folha
			var vr := Color(0.86, 0.1, 0.16)
			var ve := Color(0.5, 0.04, 0.1)
			_p(c, 2, 0, 5, 5, CONT, alfa)
			_p(c, 3, 1, 3, 3, vr, alfa)
			_p(c, 4, 2, 1, 1, ve, alfa)
			_p(c, 3, 1, 1, 1, Color(1.0, 0.45, 0.45), alfa)
			_p(c, 2, 5, 2, 1, Color(0.2, 0.55, 0.2), alfa)
		G.IMORTAL:
			# máscara de respirar com a dentadura pintada (origem: ponta do focinho) e o tubo para o pescoço
			var me := Color(0.62, 0.62, 0.66)
			_p(c, -4, -2, 6, 5, CONT, alfa)
			_p(c, -3, -1, 4, 3, me, alfa)
			for k in 2:
				_p(c, -3 + k * 2, 0, 1, 2, Color(1, 1, 1), alfa)
			_p(c, -7, 2, 4, 1, CONT, alfa)
			_p(c, -7, 3, 1, 2, CONT, alfa)
		G.MESTRE:
			# olho vermelho aceso que pulsa em dois degraus (origem: entre os olhos)
			var forte: bool = fmod(t, 0.8) < 0.4
			_p(c, 0, 0, 2, 1, Color(1.0, 0.2, 0.1) if forte else Color(0.8, 0.1, 0.05), alfa)
			if forte:
				_p(c, 2, 0, 1, 1, Color(1.0, 0.6, 0.4), alfa)
		G.MIAUNIDAS:
			# crista espartana de crina vermelha de trás para a frente, sobre qualquer chapéu (origem: topo do crânio)
			var cr := Color(0.86, 0.12, 0.1)
			_p(c, -6, -3, 10, 3, CONT, alfa)
			_p(c, -5, -4, 8, 1, CONT, alfa)
			_p(c, -5, -3, 8, 2, cr, alfa)
			_p(c, -5, -1, 8, 1, cr.darkened(0.35), alfa)
			_p(c, -2, 0, 3, 1, Color(0.8, 0.55, 0.2), alfa)   # base de bronze
		G.MAGNETO:
			# três pedaços de metal girando em volta do corpo (origem: centro do tronco), em degraus de pixel
			for k in 3:
				var a: float = t * 1.6 + k * TAU / 3.0
				var x: int = int(roundf(cos(a) * 12.0))
				var y: int = int(roundf(sin(a) * 5.0)) - 3
				_p(c, x - 1, y - 1, 4, 3, CONT, alfa)
				_p(c, x, y, 2, 1, Color(0.72, 0.74, 0.8), alfa)
				_p(c, x, y, 1, 1, Color(1, 1, 1), alfa)
				if posmod(int(t * 6.0) + k, 3) == 0:
					_p(c, x + 2, y - 2, 1, 1, Color(0.85, 0.5, 1.0), alfa)   # faísca magnética
