extends SceneTree
## Perfil por função do _draw do guarda-roupa: dentro do sinal `draw` repete cada parte N vezes e imprime o tempo médio.
## Uso: python -I notas/captura.py --log-file <log> --script <abs>/ferramentas/perfil_guarda.gd -- [aba1]
var p: Node
var n_rep: int = 10
var acum: Dictionary = {}
var quadros: int = 0

func _initialize() -> void:
	Menus.gravar = false
	Menus.pular_titulo = true
	Menus.transicoes = false
	Menus.cfg_caminho = "user://teste_interface.cfg"
	p = load("res://cenas/principal.tscn").instantiate()
	root.add_child(p)
	for i in 5:
		await process_frame
	var e: Estado = p.estado
	e.persistir = false
	e.novo_jogo()
	e.persistir = false
	e.fases_vencidas = Fases.TOTAL
	e.fase_liberada = Fases.TOTAL
	e.vencido = [3, 3, 3, 3, 3]
	e.guarda.clear()
	for t in Pecas.SLOT.size():
		e.registrar(t)
		for n in 2:
			e.guarda.append(Peca.new(t, 3 + n * 4))
	var vest: Array = [Pecas.Conjunto.CAVALEIRO, Pecas.Conjunto.MAGO, Pecas.Conjunto.CIRCO, Pecas.Conjunto.VIKING, Pecas.Conjunto.CAUBOI]
	for i in mini(e.bonecos.size(), vest.size()):
		for k in Pecas.SLOTS:
			e.bonecos[i].pecas[k] = Peca.new(Pecas.CONJUNTO_PECAS[vest[i]][k], 10)
	p._lista_suja = true
	p._entrar_guarda()
	if "aba1" in OS.get_cmdline_user_args():
		p.aba = 1
		p._lista_suja = true
	for i in 120:
		await process_frame
	p.draw.connect(_perfil)
	for i in 60:
		p.queue_redraw()
		await process_frame
		_proc()
	p.draw.disconnect(_perfil)
	process_frame.connect(func(): t_ini = Time.get_ticks_usec())
	RenderingServer.frame_pre_draw.connect(func(): ocup.append((Time.get_ticks_usec() - t_ini) / 1000.0))
	await _ocupacao("normal")
	p.set_process(false)
	await _ocupacao("sem _process/_draw (congelado)")
	p.set_process(true)
	for c in p.get_children():
		if c is CanvasItem:
			print("FILHO ", c.name, " ", c.get_class(), " vis=", c.visible)
	var ks: Array = acum.keys()
	ks.sort_custom(func(a, b): return acum[a] > acum[b])
	for k in ks:
		print("PERFIL %-22s %6.3f ms" % [k, acum[k] / 1000.0 / quadros / n_rep])
	quit()

func _t(nome: String, f: Callable) -> void:
	var t0: int = Time.get_ticks_usec()
	for i in n_rep:
		f.call()
	acum[nome] = acum.get(nome, 0) + Time.get_ticks_usec() - t0

var t_ini: int = 0
var ocup: Array[float] = []
func _ocupacao(nome: String) -> void:
	ocup.clear()
	for i in 120:
		await process_frame
	ocup = ocup.slice(10)
	var so: float = 0.0
	for v in ocup:
		so += v
	ocup.sort()
	print("PERFIL ocupacao %s: medio %.2f p50 %.2f p95 %.2f" % [nome, so / ocup.size(), ocup[ocup.size() / 2], ocup[int(ocup.size() * 0.95)]])

func _proc() -> void:
	_t("P:process_total", func(): p._process(0.016))
	_t("P:conferir_metas", p._conferir_avisos_metas)
	_t("P:atelie", p._atualizar_atelie)
	_t("P:calc_avisos", p._calcular_avisos)
	_t("P:id_hover", p._id_hover)
	_t("P:atualizar_guarda", func(): p._atualizar_guarda(0.016))

func _perfil() -> void:
	quadros += 1
	_t("DRAW_total", p._draw)
	_t("fundo", p._fundo)
	_t("torre", func(): TorrePx.desenhar(p, Vector2(24, 420), 10, 20, p.estado.melhorias, p.estado.modulos, p.t, 0.0, {"luta": false}))
	_t("modulos", p._modulos_montados)
	_t("bonecos", p._bonecos)
	_t("painel_guarda", p._painel_guarda)
	_t("previa", p._previa)
	_t("bigorna", p._bigorna)
	_t("efeitos", p._efeitos)
	_t("sig_colecao", func(): p._sig_q = -1; p._sig_colecao())
	_t("visiveis", p._visiveis)
