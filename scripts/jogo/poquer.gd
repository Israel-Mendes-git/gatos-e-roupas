class_name Poquer
extends RefCounted
## Mão de pôquer do poder do Jimiau (Jimbo, Balatro). Funções puras, testáveis com mãos fixas.
## Carta = 0..51: valor = c % 13 (0 = 2 ... 12 = Ás), naipe = c / 13.

enum Mao { CARTA_ALTA, PAR, DOIS_PARES, TRINCA, SEQUENCIA, FLUSH, FULL_HOUSE, QUADRA, STRAIGHT_FLUSH }
const NOME: Array[String] = ["Carta alta", "Par", "Dois pares", "Trinca", "Sequência", "Flush", "Full House", "Quadra", "Straight Flush"]

## Categoria de uma mão de exatamente 5 cartas.
static func avaliar(cartas: Array) -> int:
	var valores: Array[int] = []
	var naipes: Dictionary = {}
	var cont: Dictionary = {}
	for c in cartas:
		var v: int = int(c) % 13
		valores.append(v)
		naipes[int(c) / 13] = true
		cont[v] = int(cont.get(v, 0)) + 1
	valores.sort()
	var flush: bool = naipes.size() == 1
	var seq: bool = cont.size() == 5 and (valores[4] - valores[0] == 4 or (valores[0] == 0 and valores[1] == 1 and valores[2] == 2 and valores[3] == 3 and valores[4] == 12))   # a roda A-2-3-4-5 conta
	var grupos: Array[int] = []
	for k in cont:
		grupos.append(int(cont[k]))
	grupos.sort()
	grupos.reverse()
	if seq and flush:
		return Mao.STRAIGHT_FLUSH
	if grupos[0] == 4:
		return Mao.QUADRA
	if grupos[0] == 3 and grupos[1] == 2:
		return Mao.FULL_HOUSE
	if flush:
		return Mao.FLUSH
	if seq:
		return Mao.SEQUENCIA
	if grupos[0] == 3:
		return Mao.TRINCA
	if grupos[0] == 2 and grupos[1] == 2:
		return Mao.DOIS_PARES
	if grupos[0] == 2:
		return Mao.PAR
	return Mao.CARTA_ALTA

## Melhor categoria entre todas as combinações de 5 das cartas dadas (5 ou mais).
static func melhor_mao(cartas: Array) -> int:
	var n: int = cartas.size()
	if n <= 5:
		return avaliar(cartas)
	var melhor: int = 0
	for a in n:
		for b in range(a + 1, n):
			for c in range(b + 1, n):
				for d in range(c + 1, n):
					for e in range(d + 1, n):
						melhor = maxi(melhor, avaliar([cartas[a], cartas[b], cartas[c], cartas[d], cartas[e]]))
	return melhor

## Saca `n` cartas distintas do baralho de 52 com o gerador dado (reprodutível por semente).
static func sacar(rng: RandomNumberGenerator, n: int) -> Array:
	var baralho: Array = range(52)
	for i in range(51, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t: Variant = baralho[i]
		baralho[i] = baralho[j]
		baralho[j] = t
	return baralho.slice(0, n)
