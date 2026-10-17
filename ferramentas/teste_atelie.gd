extends SceneTree
## Teste headless do Ateliê (fantasia secreta): orçamento, validação, persistência (sem tocar no save real) e kit na simulação.
## Uso: godot --headless --path <projeto> --script res://ferramentas/teste_atelie.gd

var falhas: int = 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)

## Estado com o fichário completo (todas as peças já tidas), sem gravar.
func _estado_completo(semente: int) -> Estado:
	var e := Estado.new(semente)
	e.novo_jogo()
	e.persistir = false
	for t in Pecas.SLOT.size():
		e.registrar(t)
	return e

func _cfg(formas: Array, poder: int, bonus: int) -> Dictionary:
	return {"nome": "Teste", "formas": formas, "matizes": [0, 3, 0, 5], "estampa": 2, "poder": poder, "bonus": bonus}

func _init() -> void:
	_orcamento()
	_nome()
	_persistencia()
	_kit_na_simulacao()
	_desenho()
	Atelie.aplicar({})
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)

func _orcamento() -> void:
	var T = Pecas.Tipo
	var C = Pecas.Conjunto
	for t in Pecas.SLOT.size():
		if t < T.ATELIE_CABECA:
			var cm: int = Atelie.custo_forma(t)
			_ok(cm == 1 or cm == 2, "molde do tipo %d custa %d" % [t, cm])
	var pmin: int = 99
	var pmax: int = 0
	for c in Pecas.CONJUNTO_NOME.size():
		if c == C.ATELIE:
			continue
		var cp: int = Atelie.custo_poder(c)
		_ok(cp >= 3 and cp <= 5, "poder %d custa %d" % [c, cp])
		pmin = mini(pmin, cp)
		pmax = maxi(pmax, cp)
	_ok(pmin == 3 and pmax == 5, "poderes devem custar de 3 a 5 (achei %d a %d)" % [pmin, pmax])
	for c in Atelie.BONUS_CUSTO:
		_ok(Atelie.custo_bonus(c) >= 1 and Atelie.custo_bonus(c) <= 3, "bônus %d fora de 1 a 3" % c)
	# a melhor combinação possível não cabe; a mais barata cabe
	var melhor: Dictionary = _cfg([T.CARTOLA, T.CASACO, T.VARINHA, T.AMULETO], C.CIRCO, C.VIKING)
	_ok(Atelie.custo(melhor) > Atelie.ORCAMENTO, "o melhor de tudo (%d) devia estourar %d" % [Atelie.custo(melhor), Atelie.ORCAMENTO])
	var barata: Dictionary = _cfg([T.CAPACETE, T.COLETE, T.PORRETE, T.BOTAS], C.MIAULAX, C.CIRCO)
	_ok(Atelie.custo(barata) <= Atelie.ORCAMENTO and Atelie.custo(barata) == 4 + 3 + 1, "combinação barata custa %d" % Atelie.custo(barata))
	var e := _estado_completo(5)
	_ok(Atelie.liberado(e), "com tudo completo o Ateliê devia abrir")
	_ok(not Atelie.confirmar(e, melhor), "confirmar aceitou orçamento estourado")
	_ok(e.atelie.is_empty(), "orçamento estourado alterou o estado")
	var meio: Dictionary = _cfg([T.CARTOLA, T.COLETE, T.VARINHA, T.BOTAS], C.OURICO, C.ARQUEIRO_MIAU)
	_ok(Atelie.custo(meio) <= Atelie.ORCAMENTO, "combinação do meio custa %d" % Atelie.custo(meio))
	_ok(Atelie.confirmar(e, meio), "confirmar recusou combinação dentro do orçamento")
	var n_pecas: int = 0
	for p in e.todas_as_pecas():
		if p.tipo >= T.ATELIE_CABECA:
			n_pecas += 1
			_ok(p.raridade == Pecas.Raridade.RARA, "peça do Ateliê devia nascer Rara")
	_ok(n_pecas == 4, "esperava 4 peças do Ateliê, achei %d" % n_pecas)
	# refazer: troca as escolhas sem duplicar as peças
	_ok(Atelie.confirmar(e, barata), "refazer a fantasia falhou")
	n_pecas = 0
	for p in e.todas_as_pecas():
		if p.tipo >= T.ATELIE_CABECA:
			n_pecas += 1
	_ok(n_pecas == 4, "refazer duplicou as peças (%d)" % n_pecas)
	# fichário incompleto: Ateliê travado
	var f := Estado.new(6)
	f.novo_jogo()
	f.persistir = false
	_ok(not Atelie.liberado(f), "Ateliê aberto sem o fichário completo")
	_ok(not Atelie.confirmar(f, barata), "confirmar funcionou com o Ateliê travado")
	_ok(e.fantasias_completas() == Pecas.n_ativas(), "o Ateliê mexeu na contagem de fantasias")

func _nome() -> void:
	_ok(Atelie.limpar_nome("") == Atelie.NOME_VAZIO, "nome vazio")
	_ok(Atelie.limpar_nome("   ") == Atelie.NOME_VAZIO, "nome só de espaços")
	_ok(Atelie.limpar_nome("  Gato   Forte  ") == "Gato Forte", "nome com espaços: " + Atelie.limpar_nome("  Gato   Forte  "))
	_ok(Atelie.limpar_nome("Miau\n\t[b]x[/b]").find("[") < 0, "colchetes passaram")
	_ok(Atelie.limpar_nome("A".repeat(40)).length() == Atelie.NOME_MAX, "limite de caracteres")
	_ok(Atelie.limpar_nome("😀😀") == Atelie.NOME_VAZIO, "emoji passou")
	_ok(Atelie.limpar_nome("Ação Épica") == "Ação Épica", "acentos")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 20:
		var s: String = Atelie.sugerir_nome(rng)
		_ok(s.length() > 0 and s.length() <= Atelie.NOME_MAX, "nome sugerido " + s)

func _persistencia() -> void:
	var T = Pecas.Tipo
	var C = Pecas.Conjunto
	var c0: Dictionary = _cfg([T.CARTOLA, T.COLETE, T.VARINHA, T.BOTAS], C.OURICO, C.ARQUEIRO_MIAU)
	var js: String = JSON.stringify({"atelie": c0})
	var lido: Dictionary = Atelie.ler((JSON.parse_string(js) as Dictionary).get("atelie", {}))
	_ok(not lido.is_empty() and lido["formas"] == c0["formas"] and lido["poder"] == C.OURICO and lido["bonus"] == C.ARQUEIRO_MIAU and lido["estampa"] == 2 and lido["matizes"] == c0["matizes"], "ida e volta do JSON perdeu dados: " + str(lido))
	# save antigo (sem o campo) e lixo
	_ok(Atelie.ler({}).is_empty() and Atelie.ler(null).is_empty() and Atelie.ler("x").is_empty(), "save antigo devia dar vazio")
	var ruim: Dictionary = c0.duplicate(true)
	ruim["formas"] = [T.COLETE, T.COLETE, T.PORRETE, T.BOTAS]
	_ok(Atelie.ler(ruim).is_empty(), "forma no espaço errado passou")
	ruim = c0.duplicate(true)
	ruim["bonus"] = C.MIMIAU
	_ok(Atelie.ler(ruim).is_empty(), "bônus fora do catálogo passou")
	ruim = c0.duplicate(true)
	ruim["formas"][0] = T.ATELIE_CABECA
	_ok(Atelie.ler(ruim).is_empty(), "forma recursiva passou")
	ruim = c0.duplicate(true)
	ruim["matizes"] = [99, -4, 0, 0]
	ruim["estampa"] = 77
	var l2: Dictionary = Atelie.ler(ruim)
	_ok(l2["matizes"] == [Atelie.MATIZES - 1, 0, 0, 0] and l2["estampa"] == Atelie.ESTAMPA_NOME.size() - 1, "matiz e estampa sem limite")
	var e := _estado_completo(8)
	_ok(Atelie.confirmar(e, c0), "confirmar")
	_ok(Pecas.CONJUNTO_NOME[C.ATELIE] == "Teste", "o nome da fantasia não chegou à tabela")
	_ok(Pecas.NOME[T.ATELIE_CABECA] == Pecas.NOME[T.CARTOLA], "a peça do Ateliê não ganhou o nome da forma")
	_ok(Pecas.molde_de(T.ATELIE_MAO) == Pecas.MOLDE[T.VARINHA] and Pecas.molde_de(T.ATELIE_CABECA) == Pecas.MOLDE[T.CARTOLA], "molde da forma")
	var novo := Estado.new(9)
	novo.novo_jogo()
	novo.persistir = false
	_ok(novo.atelie.is_empty() and not Atelie.criada() and Pecas.CONJUNTO_NOME[C.ATELIE] == "Ateliê", "campanha nova devia esvaziar o Ateliê")
	novo.atelie = Atelie.ler(JSON.parse_string(JSON.stringify(e.atelie)))
	Atelie.aplicar(novo.atelie)
	_ok(Pecas.CONJUNTO_NOME[C.ATELIE] == "Teste" and Atelie.poder_conj() == C.OURICO, "recarregar o Ateliê")
	var pd: Dictionary = Peca.new(T.ATELIE_MAO, 3, 1).para_dados()
	_ok(Peca.de_dados(pd).tipo == T.ATELIE_MAO, "peça do Ateliê no save")

func _kit_na_simulacao() -> void:
	var T = Pecas.Tipo
	var C = Pecas.Conjunto
	Simulacao.medir = true
	var cfg: Dictionary = _cfg([T.COROA, T.COLETE, T.VARINHA, T.BOTAS], C.OURICO, C.ARQUEIRO_MIAU)
	var e := _estado_completo(11)
	_ok(Atelie.confirmar(e, cfg), "confirmar para a simulação")
	e.iniciar_fase(1)
	var gato: Boneco = e.bonecos[0]
	for s in Pecas.SLOTS:
		for p in e.guarda.duplicate():
			if p.tipo == T.ATELIE_CABECA + s:
				e.vestir(gato, p)
	_ok(Pecas.contar_conjuntos(gato.pecas)[C.ATELIE] == 4, "o gato devia vestir as 4 peças do Ateliê")
	Simulacao.tele.clear()
	var sim := Simulacao.new()
	sim.gerar_eventos = false
	sim.iniciar(e, 123)
	var u: Unidade = null
	for a in sim.aliados:
		if a.boneco == gato:
			u = a
	_ok(u != null, "gato do Ateliê não entrou na luta")
	if u != null:
		_ok(u.poder == Pecas.PODER_TIPO[C.OURICO] and u.poder_conj == C.OURICO, "poder escolhido não chegou (poder_conj %d)" % u.poder_conj)
		_ok(u.critico >= Balanco.conj_valor(C.ARQUEIRO_MIAU, 1) - 0.0001, "bônus de crítico do kit não chegou (%.2f)" % u.critico)
	var passos: int = 0
	while not sim.terminada and passos < 30 * 200:
		sim.passo(Balanco.DT)
		passos += 1
	_ok(float(Simulacao.tele.get(C.OURICO, {}).get("usos", 0.0)) > 0.0, "o poder do Ateliê nunca foi usado: " + str(Simulacao.tele))
	# todos os poderes do catálogo chegam ao gato do Ateliê e a luta roda sem quebrar
	var bonus_l: Array = Atelie.BONUS_CUSTO.keys()
	for pc in Atelie.poderes(e):
		var bo: int = bonus_l[pc % bonus_l.size()]
		var c2: Dictionary = _cfg([T.CAPACETE, T.COLETE, T.PORRETE, T.BOTAS], pc, bo)
		var e2 := _estado_completo(20 + pc)
		Atelie.aplicar(c2)   # depois do estado: novo_jogo esvazia o Ateliê
		e2.iniciar_fase(1)
		for s in Pecas.SLOTS:
			e2.bonecos[0].pecas[s] = Peca.new(T.ATELIE_CABECA + s, 5, 1)
		var s2 := Simulacao.new()
		s2.gerar_eventos = false
		s2.iniciar(e2, 50 + pc)
		var ok_poder: bool = false
		for a in s2.aliados:
			if a.poder_conj == pc and a.poder == Pecas.PODER_TIPO[pc]:
				ok_poder = true
		_ok(ok_poder, "poder %s não chegou ao gato do Ateliê" % Pecas.CONJUNTO_NOME[pc])
		var pp: int = 0
		while not s2.terminada and pp < 30 * 90:
			s2.passo(Balanco.DT)
			pp += 1
	Atelie.aplicar({})

func _desenho() -> void:
	var T = Pecas.Tipo
	Atelie.aplicar(_cfg([T.COROA, T.CAPA, T.VARINHA, T.BOTAS], Pecas.Conjunto.CAVALEIRO, Pecas.Conjunto.CIRCO))
	_ok(RoupaGato.onde(T.ATELIE_CABECA) == RoupaGato.onde(T.COROA), "lugar da cabeça")
	_ok(RoupaGato.onde(T.ATELIE_ACESSORIO) == RoupaGato.onde(T.BOTAS), "lugar do acessório")
	_ok(RoupaGato.so_pata_da_frente(T.ATELIE_ACESSORIO) == RoupaGato.so_pata_da_frente(T.BOTAS), "pata da frente")
	_ok(RoupaGato.tem_atras(T.ATELIE_CORPO) == RoupaGato.tem_atras(T.CAPA), "camada de trás")
	# (o desenho de verdade só roda dentro de _draw: as capturas de notas/atelie cobrem as estampas)
	for estampa in Atelie.ESTAMPA_NOME.size():
		AtelieArte._estampa = estampa
		var n: int = 0
		for x in 16:
			for y in 16:
				n += 1 if AtelieArte.tom(x, y) != 0 else 0
		_ok(estampa == 0 or n > 0, "a estampa %d não marca nenhum pixel" % estampa)
	_ok(not AtelieArte.ativo, "o filtro do Ateliê ficou ligado")
