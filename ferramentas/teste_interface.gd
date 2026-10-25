extends SceneTree
## Teste headless da interface: abre o jogo e passa por todas as telas (título, mapa nas três vistas, caixa do Sótão,
## guarda-roupa, fichário com fantasias, Metas e Bichos, oficina, opções, pausa e o começo de uma luta com e sem a
## preparação), conferindo o que cada uma precisa garantir. Erros de script aparecem na saída do Godot.
## Uso: godot --headless --path <projeto> --script res://ferramentas/teste_interface.gd

var falhas: int = 0
var p: Node = null

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)

func _quadros(n: int = 3) -> void:
	for i in n:
		await process_frame

func _initialize() -> void:
	Menus.gravar = false
	Menus.transicoes = false
	Menus.cfg_caminho = "user://teste_interface.cfg"
	p = load("res://cenas/principal.tscn").instantiate()
	root.add_child(p)
	await _quadros(5)
	var e: Estado = p.estado
	e.persistir = false
	e.novo_jogo()
	e.persistir = false
	_tudo_vencido(e)
	p.menus.tela = Menus.Tela.NENHUMA
	await _mapa(e)
	await _guarda(e)
	await _fichario()
	await _oficina()
	await _opcoes()
	await _luta(e)
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)

## Campanha inteira vencida, bestiário completo e algumas peças no guarda-roupa: todas as telas têm o que mostrar.
func _tudo_vencido(e: Estado) -> void:
	e.fases_vencidas = Fases.TOTAL
	e.fase_liberada = Fases.TOTAL
	e.vencido = [3, 3, 3, 3, 3]
	for i in 5:
		e.bichos_vistos["f%d" % i] = true
		e.bichos_vistos["b%d" % i] = true
		e.bichos_vistos["g%d" % i] = true
	for t in 10:
		e.bichos_vistos["t%d" % t] = true
	for c in 10:
		e.bichos_vistos["c%d" % c] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for t in Pecas.SLOT.size():
		if rng.randf() < 0.4 and not Pecas.retirada(Pecas.CONJUNTO_DE[t]):
			e.registrar(t)
			e.guarda.append(Peca.new(t, rng.randi_range(2, 12)))

func _mapa(e: Estado) -> void:
	p._entrar_mapa()
	await _quadros()
	Musica.atualizar(p, 0.016)
	_ok(Musica.pedida() == "calma", "o mapa pede a música calma")
	var m = p.mapa_casa
	_ok(e.schro_liberado(), "bestiário completo libera a caixa")
	for v in 3:
		var d0: int = m.desenhos
		await _quadros()
		_ok(m.desenhos > d0, "mapa desenha na vista %d" % v)
		_ok(MapaCasa._caixa.size.x > 0.0, "a caixa aparece na vista %d" % v)
		_ok(MapaCasa.caixa_em(MapaCasa._caixa.get_center()), "a caixa responde ao clique na vista %d" % v)
		m.alternar_vista()
	m.escolher_caixa()
	_ok(m.destaque() == MapaCasa.CAIXA, "clicar na caixa a escolhe")
	_ok(m.tecla(KEY_ENTER) == MapaCasa.CAIXA, "Enter com a caixa escolhida abre a luta secreta")
	await _quadros()
	m.reiniciar()

func _guarda(_e: Estado) -> void:
	p._entrar_guarda()
	await _quadros(4)
	_ok(p.modo == p.Modo.GUARDA, "guarda-roupa abre")

func _fichario() -> void:
	p.abrir_fichario()
	var f: Fichario = p.fichario
	await _quadros()
	_ok(f.aberto(), "fichário abre")
	for pg in f.total_paginas():
		f.ir_para_pagina(pg)
		await _quadros(1)
	f.fechar()
	p.abrir_fichario(Fichario.PAGINA_METAS)
	await _quadros()
	# a lista de fantasias das Metas tem de caber até o pé da página
	var por_col: int = ceili(Pecas.n_ativas() / 2.0)
	var passo: float = minf(22.0, floorf((Fichario.METAS_FIM_Y - 118.0) / por_col))
	_ok(118.0 + por_col * passo <= Fichario.METAS_FIM_Y, "lista de fantasias das Metas cabe na página")
	f.ir_para_pagina(1)
	await _quadros()
	f.fechar()
	p.abrir_fichario(Fichario.PAGINA_BICHOS)
	for pg in f.total_paginas():
		f.ir_para_pagina(pg)
		await _quadros(1)
	f.fechar()
	await _quadros()

func _oficina() -> void:
	p.abrir_oficina()
	await _quadros()
	_ok(p.oficina.aberta, "oficina abre")
	p.oficina.fechar()
	await _quadros()

func _opcoes() -> void:
	var mn: Menus = p.menus
	mn.tela = Menus.Tela.OPCOES
	mn._montar()
	await _quadros()
	var antes: bool = Menus.preparacao_onda
	mn._acionar("o_prep")
	_ok(Menus.preparacao_onda != antes, "opção da preparação liga e desliga")
	mn._acionar("o_prep")
	var vm: float = Musica.volume
	mn._acionar("o_mm")
	_ok(is_equal_approx(Musica.volume, maxf(0.0, vm - 0.1)), "o volume da música desce sem mexer nos efeitos")
	mn._acionar("o_mp")
	_ok(is_equal_approx(Musica.volume, vm), "o volume da música sobe de volta")
	mn.tela = Menus.Tela.NENHUMA
	mn._montar()
	await _quadros()

func _luta(e: Estado) -> void:
	Menus.dicas_vistas["tut_a_prep"] = true
	for op in [true, false]:
		Menus.preparacao_onda = op
		e.iniciar_fase(1)
		e.preparar_onda()
		p._entrar_guarda()
		await _quadros(2)
		p._lutar()
		await _quadros(4)
		_ok(p.modo == p.Modo.COMBATE, "a luta começa (preparação %s)" % op)
		Musica.atualizar(p, 0.016)
		_ok(Musica.pedida() == "luta%d" % e.ato, "a luta pede a música do ato %d" % e.ato)
		_ok(p.campo.prep == op, "preparação %s: o campo %s" % [op, "espera o jogador" if op else "começa direto"])
		p.menus.abrir_pausa()
		await _quadros()
		_ok(p.menus.ativo(), "pausa abre na luta")
		p.menus.tela = Menus.Tela.NENHUMA
		p.menus._montar()
		await _quadros()
	Menus.preparacao_onda = true
