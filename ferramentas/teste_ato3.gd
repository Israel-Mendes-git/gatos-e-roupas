extends SceneTree
## Teste headless do 3º ato (notas/ato3_proposta.md, etapas 1 e 2): entrada, tabelas, raridade com teto,
## rivais vestidos com as fantasias do lugar e a Disputa parcial.
## Uso: godot --headless --path <projeto> --script res://ferramentas/teste_ato3.gd

var falhas: int = 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)

func _init() -> void:
	_entrada()
	_raridade()
	_plano_rival()
	_disputa()
	_save_antigo()
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)

func _estado() -> Estado:
	var e := Estado.new(4242)
	e.persistir = false
	e.novo_jogo()
	return e

func _entrada() -> void:
	_ok(Balanco.ATOS == 3, "ATOS = 3")
	var e: Estado = _estado()
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [2, 2, 2, 2, 1]
	_ok(e.ato_atual() == 2, "falta um lugar do 2º ato: ainda é o 2º ato")
	e.vencido = [2, 2, 2, 2, 2]
	_ok(e.ato_atual() == 3, "2º ato vencido entra no 3º")
	e.iniciar_fase(4)
	_ok(e.ato == 3 and e.lugar() == 13, "lugar global da Arena = 13 (ato %d, lugar %d)" % [e.ato, e.lugar()])
	_ok(Fases.nome_do_lugar(e.lugar()) == "Arena da Praça" and Fases.nome_do_chefe(e.lugar()) == "Rei Miaunidas", "nomes da Arena")
	_ok(Fases.lista_do_lugar(10) == Fases.CONJUNTOS[10] and Fases.lista_do_lugar(5) == Fases.CONJUNTOS[5], "o provisório deixou de valer")
	_ok(e.mult_vida() > 0.0 and e.mult_dano() > 0.0, "multiplicadores do 3º ato")
	_ok(Balanco.ATO_COMODO_VIDA.size() == 3 and Balanco.ATO_COMODO_DANO.size() == 3, "tabelas ATO_COMODO com 3 atos")
	for a in 3:
		_ok((Balanco.ATO_COMODO_VIDA[a] as Array).size() == 5 and (Balanco.ATO_COMODO_DANO[a] as Array).size() == 5, "ATO_COMODO do ato %d com 5 lugares" % (a + 1))
	_ok(Balanco.INIMIGO_NIVEL_MAX_ATO.size() == 3 and Balanco.INIMIGO_NIVEL_MAX_ATO[2] > Balanco.INIMIGO_NIVEL_MAX_ATO[1], "nível máximo dos bichos por ato")
	for i in 5:
		_ok(Fases.chefe_base(10 + i) >= 0 and Fases.chefe_base(10 + i) < Fases.CHEFE_NOME.size(), "chefe provisório do lugar %d" % (10 + i))
		_ok(Fases.CHEFE_ASSINATURA[10 + i] >= 0, "assinatura do chefe %d" % (10 + i))
	# o chefe do 3º ato veste a assinatura (60%) ou outra do lugar
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var c: Array = Balanco.gerar_chefe(4, Balanco.ONDAS_TOTAIS, rng, 3, 0)
	_ok(c.size() == 4 and Pecas.CONJUNTO_DE[c[0].tipo] in Fases.CONJUNTOS[13], "chefe da Arena veste fantasia do lugar")
	_ok(c[0].nivel <= Balanco.INIMIGO_NIVEL_MAX_ATO[2] + 0, "nível do chefe respeita o teto do ato")

func _raridade() -> void:
	_ok(Balanco.DEGRAU_RARIDADE_MAX >= 11.0 and Balanco.DEGRAU_RARIDADE_MAX <= 13.0, "DEGRAU_RARIDADE_MAX na faixa 11 a 13")
	for g in range(0, 15):
		for tipo in 3:
			var ch: Array[float] = Balanco.chances_raridade(float(g), tipo == 2, tipo == 1)
			# o chefe sorteia em cascata (a rara é o resto): conta mítica + lendária, e a épica ainda tem de caber
			var soma: float = ch[0] + ch[1] if tipo == 2 else ch[0] + ch[1] + ch[2] + ch[3]
			if tipo == 2:
				_ok(1.0 - soma >= 0.2, "sobra para a épica do chefe (g=%d: %.2f)" % [g, 1.0 - soma])
			_ok(soma <= 1.0 + 1e-6, "soma das chances %.3f > 1 (g=%d, tipo=%d)" % [soma, g, tipo])
			for v in ch:
				_ok(v >= 0.0, "chance negativa (g=%d)" % g)
	_ok(Balanco.chances_raridade(14.0, false, true) == Balanco.chances_raridade(Balanco.DEGRAU_RARIDADE_MAX, false, true), "g acima do teto vale o teto")
	_ok(Balanco.chances_raridade(5.0, false, true)[0] == Balanco.chances_raridade(5.0, false, true)[0], "determinístico")

func _plano_rival() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var do_lugar: int = 0
	var total: int = 0
	for fase in range(1, 6):
		var lista: Array = Fases.CONJUNTOS[10 + fase - 1]
		for onda in range(1, Balanco.ONDAS_TOTAIS + 1):
			var plano: Array = Balanco.gerar_plano(fase, onda, rng, 3, 0)
			_ok(plano.size() > 0, "plano vazio")
			for it in plano:
				_ok(it.get("rival", false) and int(it.get("gangue", -1)) == fase - 1, "inimigo do 3º ato é rival da gangue %d" % (fase - 1))
				_ok(not it.has("fam"), "sem mistura de famílias no 3º ato")
				var vest: int = 0
				for pc in it["pecas"]:
					if pc != null:
						vest += 1
						total += 1
						if Pecas.CONJUNTO_DE[pc.tipo] in lista:
							do_lugar += 1
						_ok(pc.nivel <= Balanco.INIMIGO_NIVEL_MAX_ATO[2], "nível da peça do rival")
				if it["elite"]:
					var cj: int = Pecas.CONJUNTO_DE[it["pecas"][1].tipo if it["pecas"][1] != null else it["pecas"][0].tipo]
					_ok(cj in lista, "fantasiado veste fantasia do lugar")
	_ok(total > 0 and float(do_lugar) / total > 0.45, "rivais vestem as fantasias do lugar (%d de %d)" % [do_lugar, total])
	var p2: Array = Balanco.gerar_plano(1, 3, rng, 2, 0)
	for it in p2:
		_ok(not it.get("rival", false), "o 2º ato não tem rivais")

func _disputa() -> void:
	var e: Estado = _estado()
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [2, 2, 2, 2, 2]
	e.iniciar_fase(1)
	e.onda = 3
	e.preparar_onda()
	var sim := Simulacao.new()
	sim.gerar_eventos = false
	sim.iniciar(e, 99)
	_ok(sim.aliados.size() > 0, "aliados na luta")
	var pecas: Array = [null, null, null, null]
	var tipos: Dictionary = {}
	for tp in [Unidade.Tipo.COMUM, Unidade.Tipo.ESCUDEIRO, Unidade.Tipo.ATIRADOR, Unidade.Tipo.SALTADOR, Unidade.Tipo.LADRAO, Unidade.Tipo.BOMBA]:
		sim._spawnar({"pecas": pecas, "tipo": tp, "elite": false, "rival": true, "gangue": 0})
		var u: Unidade = sim.inimigos[sim.inimigos.size() - 1]
		u.x = Balanco.INIMIGO_X0
		_ok(u.rival and u.gangue == 0, "rival marcado")
		tipos[tp] = sim._escolher(u)
	_ok(tipos[Unidade.Tipo.COMUM] != null and tipos[Unidade.Tipo.COMUM].equipe == 0, "Disputa: comum rival escolhe um gato de longe")
	_ok(tipos[Unidade.Tipo.ESCUDEIRO] != null and tipos[Unidade.Tipo.ATIRADOR] != null, "Disputa: escudeiro e atirador também")
	_ok(tipos[Unidade.Tipo.SALTADOR] == null and tipos[Unidade.Tipo.LADRAO] == null, "saltador e ladrão seguem para a torre")
	_ok(tipos[Unidade.Tipo.BOMBA] == null, "Suicida (bomba) segue para a torre")
	# bicho comum do 2º ato continua com o limite de AGGRO
	sim._spawnar({"pecas": pecas, "tipo": Unidade.Tipo.COMUM, "elite": false})
	var b: Unidade = sim.inimigos[sim.inimigos.size() - 1]
	b.x = Balanco.INIMIGO_X0
	_ok(not b.rival and sim._escolher(b) == null, "bicho comum (não rival) continua sem alvo de longe")
	# sem gato de pé, o rival vai à torre
	for a in sim.aliados:
		a.vivo = false
	var r: Unidade = sim.inimigos[0]
	_ok(sim._escolher(r) == null, "sem gato de pé o rival não tem alvo (vai à torre)")

func _save_antigo() -> void:
	var e: Estado = _estado()
	e.vencido = [2, 2, 2, 2, 2]
	_ok(e.vencido.size() == 5, "vencido continua com 5 índices (sem campo novo)")
	e.fases_vencidas = Fases.TOTAL
	_ok(e.campanha_vencida() and not e.tudo_vencido(), "pós-jogo aberto e o 3º ato ainda por vencer")
	e.vencido = [3, 3, 3, 3, 3]
	_ok(e.tudo_vencido() and e.atos_vencidos() == 3, "3º ato vencido")
