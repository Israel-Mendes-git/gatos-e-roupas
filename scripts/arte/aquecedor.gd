extends Node2D
## Pré-aquece, fora da vista, os caches de pose dos bichos e das roupas.
## Montar um quadro de pixel art pela primeira vez custa vários milissegundos; sem isto o custo caía no meio do
## desenho (a travada ao começar a onda, ao ver um bicho novo ou abrir o guarda-roupa). Aqui ele é pago aos poucos,
## alguns milissegundos por quadro, enquanto o jogador está no título, no mapa ou arrumando o time.
## Sem class_name de propósito: usa-se por preload.

const ORCAMENTO_US := 3000   # tempo máximo de aquecimento por quadro

## Cada item é um pedido de desenho de Desenho.boneco: {eq, pecas, anim, andando, golpe, tipo, carregando, chefe,
## familia, elite, chefe_tipo, variante}.
var itens: Array = []
var feitos: int = 0

func _init() -> void:
	position = Vector2(-4000.0, -4000.0)   # fora da tela: só interessa o cache que o desenho deixa pronto

func _novo(eq: int, pecas: Array, anim: float, andando: bool, golpe: float, tipo: int, carregando: bool, chefe: bool, familia: int, elite: bool, chefe_tipo: int, variante: int) -> void:
	itens.append([eq, pecas, anim, andando, golpe, tipo, carregando, chefe, familia, elite, chefe_tipo, variante])

## Poses de um bicho: andando (todos os quadros do passo e do pulo), parado (as duas respirações) e golpe.
func adicionar_bicho(pecas: Array, tipo: int, familia: int, chefe: bool, elite: bool, chefe_tipo: int, completo: bool = true) -> void:
	var carregos: Array = [false, true] if (tipo == Unidade.Tipo.LADRAO or tipo == Unidade.Tipo.GEMEO) else [false]
	for car in carregos:
		for a in [0.0, 0.2]:
			_novo(1, pecas, a, false, 0.0, tipo, car, chefe, familia, elite, chefe_tipo, 0)
		if not completo:
			continue
		for k in 32:
			_novo(1, pecas, k * 0.25 + 0.05, true, 0.0, tipo, car, chefe, familia, elite, chefe_tipo, 0)
		for j in range(1, 10):
			_novo(1, pecas, 0.0, false, 0.22 * (1.0 - j / 10.0), tipo, car, chefe, familia, elite, chefe_tipo, 0)
	_acordar()

## Um gato com a roupa que veste (o desenho guarda as peças recortadas).
func adicionar_gato(pecas: Array, variante: int) -> void:
	_novo(0, pecas, 0.0, false, 0.0, 0, false, false, 0, false, -1, variante)
	_novo(0, pecas, 0.3, true, 0.0, 0, false, false, 0, false, -1, variante)
	_acordar()

func limpar() -> void:
	itens.clear()
	feitos = 0

func pronto() -> bool:
	return feitos >= itens.size()

func _acordar() -> void:
	queue_redraw()

func _draw() -> void:
	var t0: int = Time.get_ticks_usec()
	while feitos < itens.size() and Time.get_ticks_usec() - t0 < ORCAMENTO_US:
		var it: Array = itens[feitos]
		feitos += 1
		Desenho.boneco(self, Vector2.ZERO, 1.0, 1.0, int(it[0]), it[1], 0.0, float(it[2]), bool(it[3]), float(it[4]), 1.0, false, -1, 0.0, int(it[5]), bool(it[6]), bool(it[7]), int(it[8]), bool(it[9]), int(it[10]), false, false, int(it[11]), false)
	if feitos < itens.size():
		queue_redraw()
	else:
		itens.clear()
		feitos = 0
