class_name BichoPx
extends RefCounted
## Os bichos inimigos em pixel art, de quatro patas, desenhados por código na mesma grade de pixels do gato.
## Unidade: 1 = um pixel. O bicho é desenhado olhando para a DIREITA (+x), com as patas no chão em y = 0
## e centrado em x = 0; quem chama espelha para ele olhar para a esquerda.
## O corpo segue a mesma planta do gato para vestir as mesmas roupas (ver RoupaGato.ORIGEM):
## topo do crânio em (5.5, -16), centro do tronco em (-0.5, -9), ponta do focinho em (11, -11),
## alto da anca em (-8, -12), pescoço em (2, -11), patas da frente no chão em x = 4.5.
## Famílias 0 a 2 (ratos, guaxinins, raposas) e os chefes delas ficam em BichoPxA; 3 e 4 (corvos, sapos) em BichoPxB.

## `chefe_tipo` < 0 = não é chefe. `filhote` = filhote solto da Ninhada. `parte` = sapinho do Sapo-Rei.
## `carregando` = ladrão fugindo com blocos. `parado` = Raposa Ligeira sem fôlego.
static func desenhar(c: CanvasItem, familia: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var fam: int = chefe_tipo if chefe_tipo >= 0 else familia
	if chefe_tipo >= 5:
		BichoPxC.desenhar(c, familia, tipo, anim, andando, golpe, f, alfa, carregando, filhote, chefe_tipo, parte, parado)
	elif fam <= 2:
		BichoPxA.desenhar(c, fam, tipo, anim, andando, golpe, f, alfa, carregando, filhote, chefe_tipo, parte, parado)
	else:
		BichoPxB.desenhar(c, fam, tipo, anim, andando, golpe, f, alfa, carregando, filhote, chefe_tipo, parte, parado)

## Quanto o lugar `onde` (RoupaGato.Onde) se desloca, em pixels, em relação à planta parada, na pose atual
## (balanço do passo, cabeça que avança no golpe, chefe curvado). As roupas acompanham por aqui.
static func desloc(onde: int, familia: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Vector2:
	var fam: int = chefe_tipo if chefe_tipo >= 0 else familia
	if chefe_tipo >= 5:
		return BichoPxC.desloc(onde, familia, tipo, anim, andando, golpe, chefe_tipo, parado)
	if fam <= 2:
		return BichoPxA.desloc(onde, fam, tipo, anim, andando, golpe, chefe_tipo, parado)
	return BichoPxB.desloc(onde, fam, tipo, anim, andando, golpe, chefe_tipo, parado)
