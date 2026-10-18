class_name CacheDesenho
extends RefCounted
## Pré-composição de pedaços de interface que não mudam (moldura de nove fatias, ladrilho de peça): o desenho
## é feito uma vez numa SubViewport transparente, vira textura e dali em diante é um único `draw_texture_rect`.
## Enquanto a textura não existe (e no headless, que não renderiza) o chamador desenha direto, como sempre.
## A chave tem de conter TUDO que muda a aparência; o que anima por tempo fica fora do cache.

const MARGEM := 4          ## folga em volta do retângulo, em pixels lógicos (brilhos que passam da borda)
const MAX_ENTRADAS := 900
const POR_QUADRO := 6      ## quantas texturas novas por quadro (evita pico)

static var ligado: bool = true
static var pintando: bool = false     ## true dentro de um desenho de cache (nada de cache dentro de cache)
static var _tex: Dictionary = {}      ## chave -> Texture2D
static var _visto: Dictionary = {}    ## chave -> quadro em que foi pedida pela última vez sem textura
static var _host: Node = null
static var _criados_q: int = -1
static var _criados: int = 0
static var _escala: float = 1.0
static var atelie_hash: int = 0
static var _atelie_q: int = -1

class Pintor extends Node2D:
	var f: Callable
	func _draw() -> void:
		CacheDesenho.pintando = true
		f.call(self)
		CacheDesenho.pintando = false

class Host extends Node:
	var jobs: Array = []   ## [SubViewport, chave, idade]
	func _process(_d: float) -> void:
		for i in range(jobs.size() - 1, -1, -1):
			var j: Array = jobs[i]
			j[2] = int(j[2]) + 1
			if int(j[2]) < 2:
				continue
			var sv: SubViewport = j[0]
			var img: Image = sv.get_texture().get_image()
			if img == null or img.is_empty():
				CacheDesenho.ligado = false
			else:
				CacheDesenho._tex[j[1]] = ImageTexture.create_from_image(img)
			sv.queue_free()
			jobs.remove_at(i)

## Assinatura da configuração do Ateliê (muda a arte das peças criadas lá); uma vez por quadro.
static func atelie_sig() -> int:
	var qd: int = Engine.get_process_frames()
	if _atelie_q != qd:
		_atelie_q = qd
		atelie_hash = Atelie.cfg.hash()
	return atelie_hash

## Desenha a textura guardada em `r` (mais a margem). false: não há (ainda); desenhe direto.
static func desenhar(c: CanvasItem, chave: int, r: Rect2) -> bool:
	if not ligado or pintando:
		return false
	var tx: Texture2D = _tex.get(chave)
	if tx == null:
		return false
	c.draw_texture_rect(tx, r.grow(MARGEM), false)
	return true

## Vale criar a textura agora? Só na segunda vez que a mesma chave é pedida (formas animadas nunca repetem a chave).
static func pode_criar(c: CanvasItem, chave: int) -> bool:
	if not ligado or pintando or _tex.has(chave):
		return false
	var qd: int = Engine.get_process_frames()
	if _criados_q != qd:
		_criados_q = qd
		_criados = 0
	if _criados >= POR_QUADRO:
		return false
	var v: int = _visto.get(chave, -9)
	_visto[chave] = qd
	if v < 0 or qd - v > 90:
		return false
	if _visto.size() > 4000:
		_visto.clear()
	return true

## Pede a textura. `pintar(alvo)` desenha com a origem no canto de cima à esquerda do retângulo, tamanho `tam`.
static func criar(c: CanvasItem, chave: int, tam: Vector2, pintar: Callable) -> void:
	if DisplayServer.get_name() == "headless":
		ligado = false
		return
	var arvore: SceneTree = Engine.get_main_loop() as SceneTree
	if arvore == null:
		return
	if _host == null or not is_instance_valid(_host):
		_host = Host.new()
		arvore.root.add_child(_host)
	var esc: float = (c.get_viewport().get_final_transform() * c.get_global_transform_with_canvas()).get_scale().x
	if absf(esc - _escala) > 0.001:
		_escala = esc
		_tex.clear()
		_visto.clear()
		return
	if _tex.size() >= MAX_ENTRADAS:
		_tex.clear()
	_criados += 1
	var lg: Vector2 = tam + Vector2(MARGEM, MARGEM) * 2.0
	var px: Vector2i = Vector2i(roundi(lg.x * esc), roundi(lg.y * esc))
	var sv := SubViewport.new()
	sv.size = px
	sv.transparent_bg = true
	sv.disable_3d = true
	sv.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	var nd := Pintor.new()
	nd.f = pintar
	nd.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	nd.scale = Vector2(px.x / lg.x, px.y / lg.y)
	nd.position = Vector2(MARGEM, MARGEM) * nd.scale
	sv.add_child(nd)
	_host.add_child(sv)
	(_host as Host).jobs.append([sv, chave, 0])
