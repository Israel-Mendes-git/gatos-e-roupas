class_name Som
extends RefCounted
## Efeitos sonoros: Som.tocar("golpe1"). Os arquivos ficam em res://assets/som/<nome>.wav
## (sintetizados por gera_sons.py; nenhum som de terceiros). Sem áudio em headless e nos testes.

## Volume geral dos efeitos (0 a 1) e chave de mudo; Menus grava e carrega os dois.
static var volume: float = 0.7
static var mudo: bool = false

const VOZES := 12            # sons simultâneos
const INTERVALO_MIN := 0.045 # segundos entre duas vezes do mesmo som (evita metralhadora na luta)

static var _vozes: Array[AudioStreamPlayer] = []
static var _proxima: int = 0
static var _fluxos: Dictionary = {}
static var _ultimo: Dictionary = {}
static var _faltando: Dictionary = {}

## Cria os tocadores como filhos de `pai` (chame uma vez, no nó principal).
static func iniciar(pai: Node) -> void:
	_vozes.clear()
	for i in VOZES:
		var v := AudioStreamPlayer.new()
		pai.add_child(v)
		_vozes.append(v)

## Toca um efeito. `tom` multiplica a altura (1 = original); `variar` sorteia a altura em torno dele
## para o mesmo som não soar idêntico toda vez; `ganho_db` ajusta este toque em relação ao volume geral.
static func tocar(nome: String, tom: float = 1.0, variar: float = 0.06, ganho_db: float = 0.0) -> void:
	if mudo or volume <= 0.001 or _vozes.is_empty():
		return
	var agora: float = Time.get_ticks_msec() / 1000.0
	if agora - float(_ultimo.get(nome, -10.0)) < INTERVALO_MIN:
		return
	var fluxo: AudioStream = _fluxo(nome)
	if fluxo == null:
		return
	_ultimo[nome] = agora
	var v: AudioStreamPlayer = _vozes[_proxima]
	_proxima = (_proxima + 1) % _vozes.size()
	if not is_instance_valid(v) or not v.is_inside_tree():
		return
	v.stream = fluxo
	v.pitch_scale = maxf(0.2, tom * (1.0 + randf_range(-variar, variar)))
	v.volume_db = linear_to_db(clampf(volume, 0.0, 1.0)) + ganho_db
	v.play()

## Um dos sons de uma lista, ao acaso (por exemplo os três golpes).
static func tocar_um(nomes: Array, tom: float = 1.0, variar: float = 0.08, ganho_db: float = 0.0) -> void:
	if not nomes.is_empty():
		tocar(nomes[randi() % nomes.size()], tom, variar, ganho_db)

static func _fluxo(nome: String) -> AudioStream:
	if _fluxos.has(nome):
		return _fluxos[nome]
	if _faltando.has(nome):
		return null
	var caminho: String = "res://assets/som/%s.wav" % nome
	if not ResourceLoader.exists(caminho):
		_faltando[nome] = true
		push_warning("Som: não existe o efeito '%s'" % nome)
		return null
	var s: AudioStream = load(caminho)
	_fluxos[nome] = s
	return s
