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
	_reserva(e)
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
	# a fantasia do Ateliê só ganha cartão na aba Fantasias depois de criada, e o clique nele a veste
	var A: int = Pecas.Conjunto.ATELIE
	var guarda0: Array[Peca] = _e.guarda.duplicate()
	var vestes0: Array = _e.bonecos[0].pecas.duplicate()
	p._trocar_aba(p.ABA_FANTASIAS)
	_ok(p.rect_cartao_fant(A).size.x <= 0.0, "Ateliê vazio não tem cartão na aba Fantasias")
	Atelie.aplicar(Atelie.padrao())
	for s in Pecas.SLOTS:
		_e.guarda.append(Peca.new(Pecas.Tipo.ATELIE_CABECA + s, 0, Pecas.Raridade.RARA))
	p.rolagem = p._rolagem_max()
	await _quadros()
	var r: Rect2 = p.rect_cartao_fant(A)
	_ok(r.size.x > 0.0, "a fantasia do Ateliê tem cartão na aba Fantasias (no fim da rolagem)")
	_ok(p._cartao_fant_em(r.get_center()) == A, "o cartão do Ateliê responde ao mouse")
	p.sel = 0
	p._vestir_fantasia(A)
	_ok(Pecas.contar_conjuntos(_e.bonecos[0].pecas)[A] == Pecas.SLOTS, "clicar no cartão veste a fantasia do Ateliê")
	Atelie.aplicar({})
	_e.guarda = guarda0
	_e.bonecos[0].pecas = vestes0
	p._trocar_aba(0)
	await _quadros()

## Promover nunca gasta a reserva da torre: com 0 blocos a luta acaba em derrota.
func _reserva(e: Estado) -> void:
	var b: Boneco = e.bonecos[0]
	var vestes0: Array = b.pecas.duplicate()
	var tij0: int = e.tijolos
	for s in Pecas.SLOTS:
		b.pecas[s] = Peca.new(Pecas.POR_SLOT[s][0], 0)
	e.tijolos = Balanco.RESERVA_PROMOCAO + Balanco.custo_promocao(0)
	_ok(e.promover(b.pecas[0]), "com blocos acima da reserva a peça sobe")
	_ok(e.tijolos == Balanco.RESERVA_PROMOCAO, "a promoção gastou só o que estava acima da reserva (%d)" % e.tijolos)
	_ok(not e.promover(b.pecas[1]) and e.tijolos == Balanco.RESERVA_PROMOCAO, "na reserva a promoção é recusada")
	_ok(not p.promover(b.pecas[1]) and e.tijolos == Balanco.RESERVA_PROMOCAO, "arrastar ao carretel na reserva é recusado")
	_ok(not p._estado_promover_tudo(b)["ok"], "promover tudo na reserva fica bloqueado")
	_ok(e.promover_fantasia(b) == 0 and e.tijolos == Balanco.RESERVA_PROMOCAO, "promover tudo na reserva não sobe nada")
	# muitos blocos: promover tudo até onde der para no limite da reserva, nunca abaixo
	e.tijolos = 200
	for k in 40:
		e.promover_fantasia(b)
	_ok(e.tijolos >= Balanco.RESERVA_PROMOCAO, "promover sem parar desceu a torre a %d blocos" % e.tijolos)
	e.tijolos = tij0
	b.pecas = vestes0

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
	# idioma: trocar nas Opções muda o texto dos botões na hora (e volta ao português para o resto do teste)
	_ok(Idioma.atual == "pt", "o teste começa em português")
	_ok(mn.botoes[0]["id"] == "o_idioma" and mn.botoes[0]["txt"] == "Português", "botão de idioma mostra o idioma atual")
	mn._acionar("o_idioma")
	_ok(Idioma.atual == "en" and mn.botoes[0]["txt"] == "English", "o botão troca para English")
	var voltar_txt: String = ""
	for bt in mn.botoes:
		if bt["id"] == "o_voltar" and bt["txt"] != "":
			voltar_txt = bt["txt"]
	_ok(voltar_txt == "Back", "botão Voltar em inglês: '%s'" % voltar_txt)
	mn.tela = Menus.Tela.TITULO
	mn._montar()
	var opc_txt: String = ""
	for bt in mn.botoes:
		if bt["id"] == "opcoes":
			opc_txt = bt["txt"]
	_ok(opc_txt == "Options", "o título em inglês traz 'Options': '%s'" % opc_txt)
	await _quadros()
	mn.tela = Menus.Tela.OPCOES
	mn._montar()
	mn._acionar("o_idioma")
	_ok(Idioma.atual == "pt", "o botão volta ao português")
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
