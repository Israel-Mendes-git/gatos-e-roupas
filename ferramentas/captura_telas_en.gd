extends SceneTree
## Capturas de TODAS as telas do jogo no idioma escolhido (padrão: inglês), para conferir o que estoura caixa,
## o que ficou em português e o que não faz sentido. Uma execução por grupo (cada captura tem timeout de 180 s):
##   CAPTURA_USERDIR=gr_telas_en python -I notas/captura.py --script res://ferramentas/captura_telas_en.gd -- <pasta> <grupo> [idioma]
## Grupos: menus mapa guarda luta fim ficha atelie tutorial
## Em build de depuração, as chaves sem tradução vão para user://textos_sem_traducao.log (pasta gr_telas_en).
const C := Pecas.Conjunto

var p: Node = null
var saida: String = ""
var idioma: String = "en"
var limpar_tutorial: bool = true

# ------------------------------------------------------------------ utilidades
func _quadros(n: int = 3) -> void:
	for i in n:
		await process_frame
		_limpar()

func _limpar() -> void:
	if p == null:
		return
	p.menus.fila_dicas.clear()
	p.menus.dica_atual = {}
	if limpar_tutorial:
		p.tutorial.fonte = Tutorial.Fonte.NENHUM
		p.tutorial.aula = {}
		p.tutorial.fila.clear()

func _salvar(nome: String, esperar: int = 4) -> void:
	await _quadros(esperar)
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img.get_size() != Vector2i(1280, 720):
		img.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	img.save_png("%s/%s.png" % [saida, nome])
	print("salvo ", nome)

## Empurra um movimento de mouse para a janela (sem tocar no ponteiro de verdade).
func _mouse(pos: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	ev.global_position = pos
	root.push_input(ev, false)
	await process_frame

func _tirar_mouse() -> void:
	await _mouse(Vector2(-300, -300))

func _vestir(e: Estado, time: Array, nivel: int = 10, rar: int = 3) -> void:
	var ln: Array = [Boneco.Linha.FRENTE, Boneco.Linha.FRENTE, Boneco.Linha.MEIO, Boneco.Linha.MEIO, Boneco.Linha.FUNDO]
	for i in mini(e.bonecos.size(), time.size()):
		e.bonecos[i].nivel = 12 + i
		e.bonecos[i].atr = [6, 6, 6]
		e.bonecos[i].linha = ln[i]
		for k in Pecas.SLOTS:
			e.bonecos[i].pecas[k] = Peca.new(Pecas.CONJUNTO_PECAS[time[i]][k], nivel, rar)

func _bestiario(e: Estado) -> void:
	for i in 5:
		e.bichos_vistos["f%d" % i] = true
		e.bichos_vistos["b%d" % i] = true
		e.bichos_vistos["g%d" % i] = true
	for t in 10:
		e.bichos_vistos["t%d" % t] = true
	for c in 10:
		e.bichos_vistos["c%d" % c] = true

func _preparar(e: Estado, vencido: int, tudo_visto: bool = true) -> void:
	e.persistir = false
	e.rng.seed = 7
	e.novo_jogo()
	e.persistir = false
	e.fases_vencidas = Fases.TOTAL if vencido > 0 else 2
	e.fase_liberada = Fases.TOTAL if vencido > 0 else 3
	e.vencido = [vencido, vencido, vencido, vencido, vencido]
	if tudo_visto:
		_bestiario(e)
	e._completar_time()
	e.guarda.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for t in Pecas.SLOT.size():
		if Pecas.retirada(Pecas.CONJUNTO_DE[t]):
			continue
		e.registrar(t)
		if rng.randf() < 0.72:
			e.guarda.append(Peca.new(t, rng.randi_range(2, 12), rng.randi_range(0, 4)))
	e.trofeus = 140
	e.tijolos = 48

func _time_variado() -> Array:
	return [C.SUPER_MIAU, C.MIAU_NOIR, C.MIMIAU, C.ESTELAR, C.BOSQUE]

func _novo_jogo_cena(tela_inicial: bool) -> void:
	Menus.pular_titulo = not tela_inicial
	p = load("res://cenas/principal.tscn").instantiate()
	root.add_child(p)
	for i in 6:
		await process_frame   # a cena monta os menus nos primeiros quadros
	Idioma.definir(idioma)
	Menus.dicas_vistas["tut_guiado"] = true
	Menus.dicas_vistas["tut_a_prep"] = true
	await _quadros(2)

func _fechar_cena() -> void:
	p.queue_free()
	p = null
	await process_frame
	await process_frame

# ------------------------------------------------------------------ início
func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	saida = a[0] if a.size() > 0 else "user://"
	var grupos: PackedStringArray = (a[1] if a.size() > 1 else "menus").split(",")
	if a.size() > 2:
		idioma = a[2]
	DirAccess.make_dir_recursive_absolute(saida)
	Menus.gravar = false
	Menus.transicoes = false
	Menus.cfg_caminho = "user://telas_en.cfg"
	Menus.poder_automatico = false
	Menus.preparacao_onda = true
	Menus.numeros_dano = true
	for g in grupos:
		await call("g_" + g)
	if Idioma.faltas.size() > 0:
		print("CHAVES SEM TRADUCAO: ", Idioma.faltas.size())
		for k in Idioma.faltas:
			print("  FALTA: ", str(k).replace("\n", "\\n"))
	quit()

# ------------------------------------------------------------------ grupo: menus
func g_menus() -> void:
	await _novo_jogo_cena(true)
	var e: Estado = p.estado
	_preparar(e, 1)
	e.vencido = [1, 1, 1, 0, 0]
	e.fases_vencidas = 3
	e.fase_liberada = 4
	var mn: Menus = p.menus
	p.tem_save = true
	p.ir_para_titulo()
	await _salvar("m01_titulo_com_save", 30)
	mn.confirmar(Idioma.t("Nova campanha?"), Idioma.t("A campanha gravada (%s) será apagada, com o guarda-roupa e os gatos treinados.") % mn._resumo_save(), Idioma.t("Apagar e começar"), Idioma.t("Cancelar"), Callable(mn, "_nova_campanha"))
	await _salvar("m02_confirma_nova", 10)
	mn._cancelar_conf()
	p.tem_save = false
	mn.mostrar_titulo(false)
	await _salvar("m03_titulo_sem_save", 10)
	mn.tela_volta = Menus.Tela.TITULO
	mn._ir_tela(Menus.Tela.OPCOES)
	await _salvar("m04_opcoes", 20)
	mn._acionar("o_apagar")
	await _salvar("m05_confirma_apagar", 10)
	mn._cancelar_conf()
	mn._ir_tela(Menus.Tela.CREDITOS)
	await _salvar("m06_creditos_0", 20)
	mn.rolagem_cred = 420.0
	await _salvar("m07_creditos_1", 5)
	mn.rolagem_cred = 900.0
	await _salvar("m08_creditos_2", 5)
	mn.rolagem_cred = 100000.0
	await _salvar("m09_creditos_fim", 5)
	mn.tela = Menus.Tela.NENHUMA
	mn._montar()
	# pausa no mapa
	p._entrar_mapa()
	await _quadros(6)
	mn.abrir_pausa()
	await _salvar("m10_pausa_mapa", 20)
	mn.fechar_tudo()
	await _quadros(3)
	# finais do 2º e do 3º ato
	for ato in [2, 3]:
		e.vencido = [ato, ato, ato, ato, ato]
		e.fases_vencidas = Fases.TOTAL
		e.estat = {"ondas": 63, "nocautes": 21, "abates": 1234, "tempo": 5400.0, "derrotas": 3}
		mn.tela = Menus.Tela.NENHUMA
		mn.mostrar_final()
		await _salvar("m%d_final_ato%d" % [10 + ato, ato], 170)
		mn.fechar_tudo()
		mn.tela = Menus.Tela.NENHUMA
		await _quadros(2)
	await _fechar_cena()

# ------------------------------------------------------------------ grupo: mapa
func _painel(f: int, nome: String) -> void:
	var m: MapaCasa = p.mapa_casa
	m.escolher(f)
	await _salvar(nome, 8)

func g_mapa() -> void:
	# 3º ato: ruas, lado de fora, casa, caixa
	await _novo_jogo_cena(false)
	var e: Estado = p.estado
	_preparar(e, 2)
	e.recordes = [4, 6, 0, 9, 12, 3, 0, 0, 0, 0, 7]
	p._entrar_mapa()
	await _quadros(10)
	var m: MapaCasa = p.mapa_casa
	m.reiniciar()
	for f in range(1, 6):
		await _painel(f, "p%d_ruas_%d" % [10 + f, f])   # vista das ruas (3º ato)
	m.alternar_vista()
	m.escolher(1)
	for f in range(1, 6):
		await _painel(f, "p%d_fora_%d" % [20 + f, f])
	m.alternar_vista()
	for f in range(1, 6):
		await _painel(f, "p%d_casa_%d" % [30 + f, f])
	m.escolher_caixa()
	await _salvar("p40_caixa_casa", 10)
	# caixa nas vistas de fora e das ruas
	m.alternar_vista()
	await _salvar("p41_vista_fora", 10)
	m.alternar_vista()
	await _salvar("p42_vista_ruas", 10)
	await _fechar_cena()
	# 2º ato com o 2º ato incompleto ("falta") e 3º ato ainda bloqueado
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 1)
	e.vencido = [2, 1, 1, 0, 0]
	p._entrar_mapa()
	await _quadros(10)
	m = p.mapa_casa
	m.reiniciar()
	m.escolher(2)
	await _salvar("p50_fora_falta_2", 8)
	m.escolher(4)
	await _salvar("p51_fora_falta_4", 8)
	m.alternar_vista()
	m.escolher(3)
	await _salvar("p52_casa_ato2_3", 8)
	await _fechar_cena()
	# 1º ato em andamento: cômodo bloqueado, próximo, liberado (sem campanha vencida)
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 0, false)
	e.fases_vencidas = 1
	e.fase_liberada = 2
	e.vencido = [1, 0, 0, 0, 0]
	p._entrar_mapa()
	await _quadros(10)
	m = p.mapa_casa
	m.reiniciar()
	for f in [1, 2, 4]:
		m.foco = f
		m.escolhido = f
		await _salvar("p6%d_ato1_%d" % [f, f], 8)
	await _fechar_cena()

# ------------------------------------------------------------------ grupo: guarda
func g_guarda() -> void:
	await _novo_jogo_cena(false)
	var e: Estado = p.estado
	_preparar(e, 0, false)
	e.fases_vencidas = 2
	e.fase_liberada = 3
	e.vencido = [1, 1, 0, 0, 0]
	_vestir(e, _time_variado())
	e.iniciar_fase(3)
	e.tijolos = 48
	Menus.dicas_vistas["tut_a_fantasia"] = true
	p._entrar_guarda()
	p.resumo = {}
	p.sel = 0
	await _quadros(60)
	await _tirar_mouse()
	await _salvar("g01_todas", 20)
	# ficha do gato (mouse no nome)
	await _mouse(p.rect_ficha(0).get_center())
	await _salvar("g02_ficha_gato0", 12)
	await _mouse(p.rect_ficha(4).get_center())
	await _salvar("g03_ficha_gato4", 12)
	# dica de peça do painel, de atributo, de linha
	await _mouse(p.rect_tile(0).get_center())
	await _salvar("g04_dica_peca", 12)
	await _mouse(p.rect_tile(7).get_center())
	await _salvar("g05_dica_peca2", 12)
	await _mouse(p.rect_atr(0, 0).get_center())
	await _salvar("g06_dica_atributo", 12)
	await _mouse(p.rect_atr(1, 2).get_center())
	await _salvar("g06b_dica_atributo2", 12)
	await _mouse(p.rect_linha(0).get_center())
	await _salvar("g07_dica_linha", 12)
	await _mouse(p.rect_promover(0).get_center())
	await _salvar("g07b_dica_promover", 12)
	await _mouse(p.rect_reforcar(0).get_center())
	await _salvar("g07c_dica_reforcar", 12)
	# slot vestido
	await _mouse(p.pos_slot(0, 0) + Vector2(0, 0))
	await _salvar("g08_dica_slot", 12)
	# abas
	await _tirar_mouse()
	p._trocar_aba(p.ABA_FANTASIAS)
	await _salvar("g10_fantasias", 20)
	await _mouse(p.rect_cartao_fant(C.SUPER_MIAU).get_center())
	await _salvar("g11_dica_fantasia", 12)
	await _mouse(p.rect_cartao_fant(C.MIAUZILLA).get_center())
	await _salvar("g11b_dica_fantasia2", 12)
	await _tirar_mouse()
	for k in [0, 1, 2, 3, p.ABA_NOVAS]:
		p._trocar_aba(k)
		await _salvar("g12_aba_%d" % k, 14)
	# hover nas abas
	for k in [p.ABA_TODAS, p.ABA_FANTASIAS, 0, 3, p.ABA_NOVAS]:
		await _mouse(p.rect_aba(k).get_center())
		await _salvar("g13_dica_aba_%d" % k, 10)
	await _tirar_mouse()
	p._trocar_aba(p.ABA_TODAS)
	await _quadros(4)
	# ajuda "?" (tela de regras F1)
	p._alternar_ajuda()
	await _salvar("g20_ajuda", 20)
	p._alternar_ajuda()
	# avisos
	p.avisos_aberto = true
	await _salvar("g21_avisos", 12)
	p.avisos_aberto = false
	# resumo da volta
	p.resumo_pend.clear()
	var q0: Peca = e.guarda[0]
	p.resumo_pend.append({"tipo": "peca", "p": q0})
	p.resumo_pend.append({"tipo": "nivel", "b": e.bonecos[0], "de": 4, "ate": 5})
	p.resumo_pend.append({"tipo": "marca", "b": e.bonecos[1]})
	p.resumo_pend.append({"tipo": "trofeu", "n": 6})
	p._abrir_resumo()
	await _salvar("g22_resumo", 30)
	p._fechar_resumo()
	p._fechar_resumo()
	p._fechar_resumo()
	p._fechar_resumo()
	p.resumo = {}
	# aviso de fim de onda na faixa
	p.aviso = Idioma.t("%s incorporou %s!") % ["Mimi", "Super Meow"] + "  " + Idioma.t("Subiu de nível: %s.") % "Mimi, Bolota" + "  " + Idioma.t("Nocaute: %s.") % "Bolota"
	p.aviso_t = 9.0
	await _salvar("g23_aviso_fim_onda", 10)
	p.aviso = ""
	# time pequeno (2 gatos) e guarda quase vazio
	await _fechar_cena()
	await _novo_jogo_cena(false)
	e = p.estado
	e.persistir = false
	e.novo_jogo()
	e.persistir = false
	p._entrar_guarda()
	await _quadros(30)
	await _salvar("g30_inicio", 10)
	await _fechar_cena()

# ------------------------------------------------------------------ lutas
func _luta(nome: String, tempos: Array, vel: int = 2, esperar_prep: bool = false) -> void:
	p._entrar_guarda()
	p.resumo = {}
	await _quadros(4)
	p._lutar()
	p.velocidade = vel
	p.campo.velocidade = vel
	await _quadros(4)
	if esperar_prep and p.campo.prep:
		await _quadros(30)
		await _salvar("%s_prep" % nome, 5)
		# bicho da prévia em destaque
		if p.campo.prep_previa.size() > 0:
			var g: Dictionary = p.campo.prep_previa[0]
			var pr: Rect2 = p.tutorial._alvos("tipo:%d" % int(g["prio"]))[0] if p.tutorial._alvos("tipo:%d" % int(g["prio"])).size() > 0 else Rect2()
			if pr.size.x > 0.0:
				await _mouse(pr.get_center())
				await _salvar("%s_prep_dica" % nome, 8)
				await _tirar_mouse()
		p.campo.prep = false
	var guarda_n: int = 0
	var k: int = 0
	while k < tempos.size() and guarda_n < 6000 and not p.campo.sim.terminada:
		await _quadros(1)
		guarda_n += 1
		if p.campo.sim.tempo >= float(tempos[k]):
			await _salvar("%s_t%02d" % [nome, int(tempos[k])], 1)
			k += 1
	if p.campo.sim.terminada:
		print("luta terminou antes: ", nome)

func g_luta() -> void:
	# 1º ato, poderes manuais e números de dano
	await _novo_jogo_cena(false)
	var e: Estado = p.estado
	_preparar(e, 0, false)
	e.fases_vencidas = 2
	e.fase_liberada = 3
	e.vencido = [1, 1, 0, 0, 0]
	_vestir(e, [C.SUPER_MIAU, C.ESTELAR, C.MIMIAU, C.BOSQUE, C.MIAUZILLA])
	e.iniciar_fase(3)
	e.onda = 3
	e.preparar_onda()
	await _luta("l01_ato1", [3, 6, 10, 16], 2, true)
	# pausa na luta
	p.menus.abrir_pausa()
	await _salvar("l02_pausa_luta", 20)
	p.menus._acionar("p_mapa")
	await _salvar("l03_confirma_mapa", 10)
	p.menus._cancelar_conf()
	p.menus._acionar("p_menu")
	await _salvar("l04_confirma_menu", 10)
	p.menus._cancelar_conf()
	p.menus.fechar_tudo()
	p.menus.tela = Menus.Tela.NENHUMA
	await _fechar_cena()
	# poderes automáticos ligados
	Menus.poder_automatico = true
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 0, false)
	e.fases_vencidas = 3
	e.fase_liberada = 4
	e.vencido = [1, 1, 1, 0, 0]
	_vestir(e, [C.MIAUZILLA, C.SUPER_MIAU, C.HOLLOWMIAU, C.ESTELAR, C.MIMIAU])
	e.iniciar_fase(4)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	Menus.preparacao_onda = false
	await _luta("l10_chefe_sotao", [1, 4, 9, 15, 24], 2)
	Menus.preparacao_onda = true
	await _fechar_cena()
	# 3º ato: gangue
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 2)
	_vestir(e, [C.MIAU_NOIR, C.SUPER_MIAU, C.BOSQUE, C.HOLLOWMIAU, C.MIAUZILLA])
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [2, 2, 2, 2, 2]
	e.vencido[4] = 2
	e.iniciar_fase(1)
	e.onda = 3
	e.preparar_onda()
	Menus.preparacao_onda = false
	await _luta("l20_gangue", [2, 5, 9, 14], 2)
	await _fechar_cena()
	# chefe de gangue (última onda, 3º ato, Arena)
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 2)
	_vestir(e, [C.MIAU_NOIR, C.SUPER_MIAU, C.BOSQUE, C.HOLLOWMIAU, C.MIAUZILLA])
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [2, 2, 2, 2, 2]
	e.iniciar_fase(4)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	await _luta("l21_chefe_gangue", [1, 4, 9, 15], 2)
	await _fechar_cena()
	# 2º ato lá fora (chefe) e invasão e secreta
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 1)
	_vestir(e, [C.MIAUZILLA, C.SUPER_MIAU, C.HOLLOWMIAU, C.ESTELAR, C.MIMIAU])
	e.vencido = [1, 1, 1, 1, 1]
	e.iniciar_fase(2)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	await _luta("l30_chefe_fora", [1, 4, 9, 15], 2)
	await _fechar_cena()
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 1)
	_vestir(e, [C.MIAUZILLA, C.ESTELAR, C.SUPER_MIAU, C.MIAU_NOIR, C.MIMIAU])
	e.iniciar_secreto()
	await _luta("l40_schro", [1, 4, 9, 16], 2)
	await _fechar_cena()
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 1)
	_vestir(e, [C.MIAUZILLA, C.ESTELAR, C.SUPER_MIAU, C.MIAU_NOIR, C.MIMIAU])
	e.iniciar_invasao(1)
	e.onda_invasao = 7
	e.onda = 2
	e.preparar_onda()
	await _luta("l50_invasao", [4, 10], 2)
	p.menus.abrir_pausa()
	await _quadros(5)
	p.menus._acionar("p_mapa")
	await _salvar("l51_confirma_invasao", 10)
	p.menus._cancelar_conf()
	p.menus.fechar_tudo()
	await _fechar_cena()
	Menus.poder_automatico = false

# ------------------------------------------------------------------ painel de fim
## Entra numa luta, marca o desfecho e mostra o painel de fim.
func _fim(nome: String, vitoria: bool, perdas: Dictionary = {}, tijolos: int = 0, poder_bicho: int = 0, drops: int = 3) -> void:
	var e: Estado = p.estado
	p._entrar_guarda()
	p.resumo = {}
	await _quadros(3)
	p._lutar()
	await _quadros(6)
	e.tijolos = tijolos
	p.campo.sim.perdas = perdas
	p.campo.sim.gatos_por_poder_bicho = poder_bicho
	for i in drops:
		p.campo.sim.bau.append(Peca.new(i * 7 + 2, 3 + i, 1))
	p.niveis_ini = {}
	p._on_campo_terminou(vitoria)
	await _quadros(10)
	await _salvar(nome, 90)
	p.menus.tela = Menus.Tela.NENHUMA

func g_fim() -> void:
	var T := Unidade.Tipo
	# derrotas em vários contextos
	await _novo_jogo_cena(false)
	var e: Estado = p.estado
	_preparar(e, 0, false)
	e.fases_vencidas = 1
	e.fase_liberada = 2
	e.vencido = [1, 0, 0, 0, 0]
	_vestir(e, _time_variado())
	e.iniciar_fase(2)
	e.onda = 3
	e.preparar_onda()
	await _fim("f01_derrota_tempo", false, {}, 10)
	e.iniciar_fase(2)
	e.onda = 3
	e.preparar_onda()
	await _fim("f02_derrota_ladrao", false, {T.LADRAO: 6})
	e.iniciar_fase(2)
	e.onda = 3
	e.preparar_onda()
	await _fim("f03_derrota_um_bloco", false, {T.SALTADOR: 1})
	e.iniciar_fase(2)
	e.onda = 3
	e.preparar_onda()
	await _fim("f04_derrota_gigante_poder", false, {T.GIGANTE: 4}, 0, 2)
	e.iniciar_fase(2)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	await _fim("f05_derrota_chefe", false, {"chefe": 9})
	# vitória de onda comum (volta ao guarda-roupa) e do chefe do Quarto
	e.iniciar_fase(1)
	e.onda = Balanco.ONDAS_TOTAIS
	e.fases_vencidas = 0
	e.vencido = [0, 0, 0, 0, 0]
	e.preparar_onda()
	await _fim("f10_vitoria_quarto", true)
	# vitória do Porão, fim do 1º ato
	e.vencido = [1, 1, 1, 1, 0]
	e.fases_vencidas = 4
	e.fase_liberada = 5
	e.iniciar_fase(5)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	await _fim("f11_vitoria_ato1", true)
	# 2º ato: vencer o quinto lugar (falta ato 3 -> fim do 2º ato)
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [2, 2, 2, 2, 1]
	e.iniciar_fase(5)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	await _fim("f12_vitoria_ato2", true)
	# vence só um lugar de fora (faltam vários)
	e.vencido = [1, 1, 1, 1, 1]
	e.iniciar_fase(2)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	await _fim("f13_vitoria_fora_faltam", true)
	e.vencido = [2, 2, 2, 2, 1]
	e.iniciar_fase(2)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	await _fim("f13b_vitoria_fora_falta1", true)
	# 3º ato
	e.vencido = [3, 3, 3, 3, 2]
	e.iniciar_fase(5)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	await _fim("f14_vitoria_ato3", true)
	e.vencido = [2, 2, 2, 2, 2]
	e.iniciar_fase(1)
	e.onda = Balanco.ONDAS_TOTAIS
	e.preparar_onda()
	await _fim("f15_vitoria_ato3_lugar", true, {}, 0, 0, 0)
	# secreto
	e.iniciar_secreto()
	await _fim("f16_vitoria_schro", true)
	# invasão: derrota com recorde e sem
	e.iniciar_invasao(1)
	e.onda_invasao = 9
	e.recordes[0] = 4
	e.preparar_onda()
	p.invasao_rec_ini = 4
	await _fim("f20_invasao_sem_recorde", false, {T.LADRAO: 3})
	e.iniciar_invasao(1)
	e.onda_invasao = 1
	e.preparar_onda()
	await _fim("f21_invasao_zero", false, {})
	e.iniciar_invasao(1)
	e.onda_invasao = 8
	e.recordes[0] = 7
	e.preparar_onda()
	p.invasao_rec_ini = 3
	await _fim("f22_invasao_recorde", false, {T.ATIRADOR: 5})
	await _fechar_cena()

# ------------------------------------------------------------------ fichário, oficina e Ateliê
func g_ficha() -> void:
	await _novo_jogo_cena(false)
	var e: Estado = p.estado
	_preparar(e, 2)
	e.estat = {"ondas": 63, "nocautes": 21, "abates": 1234, "tempo": 5400.0, "derrotas": 3}
	_vestir(e, _time_variado())
	e.feitos["schro"] = true
	e.conferir_metas()
	p._entrar_mapa()
	await _quadros(10)
	var f: Fichario = p.fichario
	p.abrir_fichario()
	await _salvar("h01_indice", 40)
	f.pagina = 0
	for pg in [1, 2, 5, 9, 14, 20]:
		f.ir_para_pagina(pg)
		await _salvar("h02_fantasia_pg%02d" % pg, 24)
	f.ir_para_pagina(f.total_paginas() - 1)
	await _salvar("h03_pagina_atelie", 24)
	f.ir_para_pagina(0)
	await _quadros(10)
	for it in f.itens:
		if str(it["id"]).begins_with("aba") or str(it["id"]).begins_with("a"):
			pass
	# abas do fichário por dica de mouse
	f.fechar()
	p.abrir_fichario(Fichario.PAGINA_METAS)
	await _salvar("h10_metas_0", 40)
	f.ir_para_pagina(1)
	await _salvar("h11_metas_1", 24)
	f.fechar()
	p.abrir_fichario(Fichario.PAGINA_BICHOS)
	await _salvar("h20_bichos_indice", 40)
	for pg in [1, 2, 3, 6, 12, 20, 30, 33, 36, 38, 40]:
		if pg < f.total_paginas():
			f.ir_para_pagina(pg)
			await _salvar("h21_bichos_pg%02d" % pg, 24)
	f.fechar()
	# fichário com poucas coisas (início da campanha)
	await _quadros(3)
	await _fechar_cena()
	await _novo_jogo_cena(false)
	e = p.estado
	e.persistir = false
	e.novo_jogo()
	e.persistir = false
	p._entrar_mapa()
	await _quadros(10)
	f = p.fichario
	p.abrir_fichario()
	await _salvar("h30_indice_inicio", 40)
	f.ir_para_pagina(2)
	await _salvar("h31_fantasia_vazia", 24)
	f.fechar()
	p.abrir_fichario(Fichario.PAGINA_BICHOS)
	await _salvar("h32_bichos_inicio", 40)
	f.ir_para_pagina(3)
	await _salvar("h33_bichos_inicio_pg3", 24)
	f.fechar()
	p.abrir_fichario(Fichario.PAGINA_METAS)
	await _salvar("h34_metas_inicio", 40)
	f.fechar()
	await _fechar_cena()
	# oficina
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 2)
	e.trofeus = 320
	e.modulos = [0, 1]
	p._entrar_mapa()
	await _quadros(10)
	p.abrir_oficina()
	await _salvar("o01_aba0", 40)
	for ab in [1, 2]:
		p.oficina.acionar("a%d" % ab)
		await _salvar("o02_aba%d" % ab, 20)
	p.oficina.acionar("a0")
	for id in ["m0", "m1", "m2", "m3", "m4", "m5"]:
		pass
	# mouse nos itens da oficina
	await _quadros(4)
	var contador: int = 0
	for it in p.oficina.itens:
		if contador < 14 and str(it["id"]) != "":
			var r: Rect2 = it["r"]
			await _mouse(r.get_center())
			await _salvar("o03_hover_%02d_%s" % [contador, str(it["id"])], 6)
			contador += 1
	await _tirar_mouse()
	p.oficina.fechar()
	await _fechar_cena()
	# Ateliê
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 3)
	for t in Pecas.SLOT.size():
		e.registrar(t)
	e.fantasias_completas()
	p._entrar_mapa()
	await _quadros(10)
	p.abrir_atelie()
	await _salvar("a01_atelie", 40)
	var at = p.atelie_tela
	var contador2: int = 0
	for it in at.itens:
		if contador2 < 10:
			var r2: Rect2 = it["r"]
			await _mouse(r2.get_center())
			await _salvar("a02_hover_%02d_%s" % [contador2, str(it["id"])], 6)
			contador2 += 1
	await _tirar_mouse()
	at.fechar()
	await _fechar_cena()

## Só o Ateliê: página do fichário, a tela e o pintor de cada peça (mais rápido que o grupo ficha).
func g_atelie() -> void:
	await _novo_jogo_cena(false)
	var e: Estado = p.estado
	_preparar(e, 3)
	for t in Pecas.SLOT.size():
		e.registrar(t)
	e.fantasias_completas()
	p._entrar_mapa()
	await _quadros(10)
	var f: Fichario = p.fichario
	p.abrir_fichario()
	f.ir_para_pagina(f.total_paginas() - 1)
	await _salvar("t01_pagina_atelie", 40)
	f.fechar()
	p.abrir_atelie()
	await _salvar("t02_atelie", 40)
	var at = p.atelie_tela
	for s in 4:
		at.pintor.abrir(at, s)
		await _salvar("t1%d_pintor_peca%d" % [s, s], 12)
		if at.pintor.tem_atras():
			at.pintor.acionar("cam")
			await _salvar("t1%d_pintor_peca%d_atras" % [s, s], 8)
		at.pintor.fechar()
	at.fechar()
	await _fechar_cena()

# ------------------------------------------------------------------ tutorial guiado e aulas
func g_tutorial() -> void:
	limpar_tutorial = false
	Menus.dicas_vistas.clear()
	await _novo_jogo_cena(false)
	Menus.dicas_vistas.clear()
	var e: Estado = p.estado
	e.persistir = false
	e.novo_jogo()
	e.persistir = false
	var tu: Tutorial = p.tutorial
	tu.fila.clear()
	tu.aula = {}
	tu.comecar(Tutorial.Fonte.GUIADO)
	p._entrar_mapa()
	await _quadros(60)
	# cada passo, na tela certa
	var passos: Array = tu.roteiro.duplicate()
	var estado_tela: int = -1
	for i in passos.size():
		var s: Dictionary = passos[i]
		var m: int = int(s["modo"])
		if m == Tutorial.M_MAPA:
			if int(p.modo) != p.Modo.MAPA:
				p._entrar_mapa()
		elif m == Tutorial.M_GUARDA:
			if int(p.modo) != p.Modo.GUARDA:
				if int(p.modo) == p.Modo.COMBATE:
					p.modo = p.Modo.GUARDA
				e.iniciar_fase(1)
				p._entrar_guarda()
				p.resumo = {}
		elif m == Tutorial.M_COMBATE:
			if int(p.modo) != p.Modo.COMBATE:
				e.iniciar_fase(1)
				p._entrar_guarda()
				p.resumo = {}
				await _quadros(3)
				p._lutar()
				await _quadros(6)
			p.campo.prep = bool(s.get("prep", false))
			if not p.campo.prep:
				p.campo.velocidade = 1
		tu.passo_i = i
		tu._mostrando = true
		tu._vis_guiado = true
		tu._t_modo = 1.0
		tu._t_passo = 1.0
		await _quadros(12)
		tu.passo_i = i
		tu._mostrando = true
		tu._t_modo = 1.0
		tu._t_passo = 1.0
		tu._vis_guiado = true
		await RenderingServer.frame_post_draw
		await _salvar("t%02d_guiado_%s" % [i + 1, str(s["id"])], 1)
	tu.fonte = Tutorial.Fonte.NENHUM
	tu._vis_guiado = false
	await _fechar_cena()
	# aulas soltas e "?" de cada tela
	limpar_tutorial = false
	await _novo_jogo_cena(false)
	Menus.dicas_vistas.clear()
	e = p.estado
	_preparar(e, 0, false)
	e.fases_vencidas = 2
	e.fase_liberada = 3
	e.vencido = [1, 1, 0, 0, 0]
	_vestir(e, _time_variado())
	tu = p.tutorial
	tu.fonte = Tutorial.Fonte.NENHUM
	p._entrar_mapa()
	await _quadros(30)
	await _aula_balaos("mapa", tu._aula_rever("mapa"), "u01_rever_mapa")
	for id in ["a_mapa", "a_fichario", "a_trofeu"]:
		await _aula_balaos(id, tu._aula(id), "u02_%s" % id)
	e.iniciar_fase(3)
	p._entrar_guarda()
	p.resumo = {}
	await _quadros(30)
	await _aula_balaos("guarda", tu._aula_rever("guarda"), "u03_rever_guarda")
	for id in ["a_fantasia", "a_treino", "a_fusao", "a_heranca", "a_marcas", "a_chefe"]:
		await _aula_balaos(id, tu._aula(id), "u04_%s" % id)
	# ato 2 no mapa
	e.vencido = [1, 1, 1, 1, 1]
	e.fases_vencidas = Fases.TOTAL
	p._entrar_mapa()
	await _quadros(30)
	for id in ["a_ato2", "a_invasao"]:
		await _aula_balaos(id, tu._aula(id), "u05_%s" % id)
	# combate: prep e luta
	e.iniciar_fase(1)
	p._entrar_guarda()
	p.resumo = {}
	await _quadros(3)
	p._lutar()
	await _quadros(30)
	await _aula_balaos("prep", tu._aula_rever("prep"), "u06_rever_prep")
	if p.campo.prep_previa.size() > 0:
		for g in p.campo.prep_previa:
			var d: Dictionary = tu._aula("a_bicho_%d" % int(g["prio"]))
			await _aula_balaos("bicho", d, "u07_bicho%d" % int(g["prio"]))
	p.campo.prep = false
	await _quadros(20)
	await _aula_balaos("luta", tu._aula_rever("luta"), "u08_rever_luta")
	await _aula_balaos("a_poder", tu._aula("a_poder"), "u09_a_poder")
	await _fechar_cena()
	# "?" do fichário e da oficina
	limpar_tutorial = false
	await _novo_jogo_cena(false)
	e = p.estado
	_preparar(e, 1)
	tu = p.tutorial
	tu.fonte = Tutorial.Fonte.NENHUM
	p._entrar_mapa()
	await _quadros(20)
	p.abrir_fichario()
	await _quadros(20)
	await _aula_balaos("fichario", tu._aula_rever("fichario"), "u10_rever_fichario")
	p.fichario.fechar()
	await _quadros(5)
	p.abrir_oficina()
	await _quadros(20)
	await _aula_balaos("oficina", tu._aula_rever("oficina"), "u11_rever_oficina")
	p.oficina.fechar()
	await _fechar_cena()
	limpar_tutorial = true

func _aula_balaos(_id: String, d: Dictionary, nome: String) -> void:
	if d.is_empty():
		print("sem aula: ", nome)
		return
	var tu: Tutorial = p.tutorial
	d["rever"] = true
	d["ctx"] = tu._contexto()
	var n: int = (d["balaos"] as Array).size()
	for i in n:
		tu.fonte = Tutorial.Fonte.NENHUM
		tu.aula = d
		tu.aula_i = i
		tu._t_aula = 1.0
		await _quadros(6)
		tu.aula = d
		tu.aula_i = i
		tu._t_aula = 1.0
		await _salvar("%s_%d" % [nome, i + 1], 2)
	tu.aula = {}
	await _quadros(2)
