extends SceneTree
## Mede o tempo de quadro do guarda-roupa, do fichário, da oficina e da luta do 3º ato (janela real, sem gravar o save).
## Uso: python -I notas/captura.py --script <abs>/ferramentas/medir_quadro.gd -- [cenario ...]   (cenarios: guarda fantasias ficha oficina luta mapa)
var t_ini: int = 0
var t_ocup: float = 0.0   # soma do trabalho de CPU do quadro (process + _draw), sem a espera do vsync
var n_ocup: int = 0
var max_ocup: float = 0.0
var ocup: Array[float] = []

func _ao_iniciar() -> void:
	t_ini = Time.get_ticks_usec()

func _ao_pintar() -> void:
	ocup.append((Time.get_ticks_usec() - t_ini) / 1000.0)


func _initialize() -> void:
	Menus.gravar = false
	Menus.pular_titulo = true
	Menus.transicoes = false
	Menus.cfg_caminho = "user://teste_interface.cfg"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	process_frame.connect(_ao_iniciar)
	RenderingServer.frame_pre_draw.connect(_ao_pintar)
	var quais: PackedStringArray = OS.get_cmdline_user_args()
	var p: Node = load("res://cenas/principal.tscn").instantiate()
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
	print("pecas na guarda: ", e.guarda.size(), " gatos: ", e.bonecos.size())
	if quais.is_empty() or "guarda" in quais:
		p._entrar_guarda()
		await _medir("guarda (Todas)", 240)
		p.rolagem = 2
		await _medir("guarda (Todas, rolada)", 120)
		p.rolagem = 0
	if quais.is_empty() or "fantasias" in quais:
		p.aba = 1
		p._lista_suja = true
		await _medir("guarda (aba 1)", 120)
		p.aba = 0
		p._lista_suja = true
	if quais.is_empty() or "ficha" in quais:
		p.abrir_fichario(-1)
		p.fichario.abrir_t = 5.0
		await _medir("fichario (indice)", 120)
		p.fichario.fechar()
	if quais.is_empty() or "oficina" in quais:
		p.oficina.abrir()
		p.oficina.abrir_t = 5.0
		await _medir("oficina", 120)
		p.oficina.fechar()
	if quais.is_empty() or "mapa" in quais:
		p._entrar_mapa()
		await _medir("mapa", 120)
	if quais.is_empty() or "luta" in quais:
		await _luta(p, e)
	quit()

func _luta(p: Node, e: Estado) -> void:
	e.iniciar_fase(4)
	e.onda = 5
	e.preparar_onda()
	e.plano = []
	for g in 5:
		var pc: Array = [null, null, null, null]
		pc[0] = Peca.new(Pecas.CONJUNTO_PECAS[Fases.CONJUNTOS[13][g % 3]][0], 8)
		pc[1] = Peca.new(Pecas.CONJUNTO_PECAS[Fases.CONJUNTOS[13][g % 3]][1], 8)
		e.plano.append({"pecas": pc, "tipo": Unidade.Tipo.COMUM, "elite": false, "rival": true, "gangue": g})
		e.plano.append({"pecas": pc, "tipo": Unidade.Tipo.COMUM, "elite": false, "rival": true, "gangue": g})
	e.chefe = []
	p._entrar_guarda()
	for i in 5:
		await process_frame
	p._lutar()
	p.campo.prep = false
	await _medir("luta ato3 (rivais)", 360)

func _medir(nome: String, n: int) -> void:
	for i in 40:
		await process_frame
	var ms: Array[float] = []
	var dc: float = 0.0
	var cpu: float = 0.0
	var gpu: float = 0.0
	var vp := root.get_viewport_rid()
	ocup.clear()
	var ant: int = Time.get_ticks_usec()
	for i in n:
		await process_frame
		var agora: int = Time.get_ticks_usec()
		ms.append((agora - ant) / 1000.0)
		ant = agora
		dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
	var s: Array[float] = ms.duplicate()
	s.sort()
	var o: Array[float] = ocup.duplicate()
	o.sort()
	var so: float = 0.0
	for v in o:
		so += v
	var soma: float = 0.0
	for v in ms:
		soma += v
	print("MEDIDA %-26s medio %5.2f ms | p95 %5.2f | max %5.2f | fps %5.1f | draws %4d | renderCPU %4.2f | GPU %4.2f | CPU do quadro: medio %5.2f p95 %5.2f max %5.2f" % [nome, soma / n, s[int(n * 0.95)], s[n - 1], 1000.0 / (soma / n), int(dc / n), cpu / n, gpu / n, so / o.size(), o[int(o.size() * 0.95)], o[o.size() - 1]])
