class_name GatoDados
extends RefCounted
## Gerado por monta_gato.py a partir do pacote de sprites do gato: quadros do atlas e âncoras das peças.

const CELULA := 256   # tamanho de um quadro no atlas, em pixels
const FONTE := 32     # tamanho do quadro no sprite original
const COLUNAS := 7
const VARIANTES := 3

const ANDAR := 0
const ANDAR_N := 8
const ATACAR := 8
const ATACAR_N := 7
const DORMIR := 15
const DORMIR_N := 2
const SENTAR := 17
const SENTAR_N := 4

## Linha do chão dentro do quadro original (y do pé), por quadro.
const CHAO: Array[int] = [25, 24, 22, 24, 25, 24, 22, 24, 25, 25, 25, 25, 25, 25, 25, 24, 24, 25, 25, 25, 25]
## Âncoras por espaço (cabeça, corpo, mão, acessório) e por quadro, em pixels do sprite original,
## relativas ao centro do quadro em x e ao pé em y (y negativo é para cima). Gato virado para a direita.
const ANCORAS: Array = [
	[Vector2(4.5, -13.0), Vector2(4.5, -14.0), Vector2(4.5, -15.0), Vector2(4.5, -14.0), Vector2(4.5, -13.0), Vector2(4.5, -14.0), Vector2(4.5, -15.0), Vector2(4.5, -14.0), Vector2(4.5, -13.0), Vector2(4.5, -13.0), Vector2(5.5, -13.0), Vector2(5.5, -13.0), Vector2(5.5, -13.0), Vector2(5.5, -13.0), Vector2(4.5, -13.0), Vector2(4.0, -14.0), Vector2(4.0, -14.0), Vector2(0.0, -15.0), Vector2(0.0, -17.0), Vector2(0.0, -19.0), Vector2(0.0, -17.0)],
	[Vector2(-3.0, -8.0), Vector2(-3.0, -9.0), Vector2(-2.5, -11.0), Vector2(-4.0, -9.0), Vector2(-4.0, -8.0), Vector2(-3.5, -9.0), Vector2(-2.5, -11.0), Vector2(-3.0, -9.0), Vector2(-3.0, -8.0), Vector2(-3.0, -8.0), Vector2(-2.5, -8.0), Vector2(-2.5, -8.0), Vector2(-2.5, -8.0), Vector2(-2.5, -8.0), Vector2(-3.0, -8.0), Vector2(-3.5, -9.0), Vector2(-3.5, -9.0), Vector2(-1.0, -8.0), Vector2(-1.0, -8.0), Vector2(-1.0, -8.0), Vector2(-1.0, -8.0)],
	[Vector2(9.0, -6.0), Vector2(9.0, -7.0), Vector2(11.0, -8.0), Vector2(9.0, -7.0), Vector2(9.0, -6.0), Vector2(9.0, -7.0), Vector2(10.0, -8.0), Vector2(9.0, -7.0), Vector2(9.0, -6.0), Vector2(9.0, -6.0), Vector2(10.0, -6.0), Vector2(10.0, -6.0), Vector2(10.0, -6.0), Vector2(10.0, -6.0), Vector2(9.0, -6.0), Vector2(8.0, -7.0), Vector2(8.0, -7.0), Vector2(9.0, -8.0), Vector2(9.0, -10.0), Vector2(9.0, -12.0), Vector2(9.0, -10.0)],
	[Vector2(-5.0, -9.0), Vector2(-5.0, -10.0), Vector2(-6.0, -12.0), Vector2(-7.0, -10.0), Vector2(-7.0, -9.0), Vector2(-6.0, -10.0), Vector2(-5.0, -12.0), Vector2(-5.0, -10.0), Vector2(-5.0, -9.0), Vector2(-5.0, -9.0), Vector2(-5.0, -9.0), Vector2(-5.0, -9.0), Vector2(-5.0, -9.0), Vector2(-5.0, -9.0), Vector2(-5.0, -9.0), Vector2(-5.0, -10.0), Vector2(-5.0, -10.0), Vector2(-1.0, -9.0), Vector2(-1.0, -9.0), Vector2(-1.0, -9.0), Vector2(-1.0, -9.0)],
]
## Pes do gato por quadro: ponto do chao sob cada pata visivel (x relativo ao centro do quadro,
## y relativo ao chao; negativo = pata no ar). Quadros de dormir e sentar ficam vazios.
const PATAS: Array = [
	[Vector2(-5.0, 0.0), Vector2(6.0, 0.0)],
	[Vector2(-7.0, -1.0), Vector2(-1.5, -2.0), Vector2(4.5, -1.0), Vector2(8.5, -2.0)],
	[Vector2(-10.0, -3.0), Vector2(-1.5, -4.0), Vector2(3.0, -4.0), Vector2(11.5, -3.0)],
	[Vector2(-7.0, -1.0), Vector2(-1.5, -2.0), Vector2(4.5, -1.0), Vector2(8.5, -2.0)],
	[Vector2(-7.0, 0.0), Vector2(-3.0, 0.0), Vector2(5.0, 0.0)],
	[Vector2(-6.0, -1.0), Vector2(-1.5, -2.0), Vector2(3.5, -1.0), Vector2(8.5, -2.0)],
	[Vector2(-10.0, -3.0), Vector2(0.0, -3.0), Vector2(10.5, -3.0)],
	[Vector2(-6.0, -1.0), Vector2(-1.5, -2.0), Vector2(3.5, -1.0), Vector2(8.5, -2.0)],
	[Vector2(-5.0, 0.0), Vector2(6.0, 0.0)],
	[Vector2(-5.0, 0.0), Vector2(6.0, 0.0)],
	[Vector2(-5.0, 0.0), Vector2(6.0, 0.0)],
	[Vector2(-5.0, 0.0), Vector2(4.0, -1.0), Vector2(8.0, -1.0)],
	[Vector2(-5.0, 0.0), Vector2(4.0, -1.0)],
	[Vector2(-5.0, 0.0), Vector2(6.0, 0.0)],
	[Vector2(-5.0, 0.0), Vector2(6.0, 0.0)],
	[],
	[],
	[],
	[],
	[],
	[],
]
