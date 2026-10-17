extends SceneTree
## Teste headless de "onde cai cada fantasia" (notas/onde_cai_final.md): dados das 15 listas, provisório, assinaturas,
## peças dos comuns, chefe com assinatura, sorteio ponderado (pity) e textos do fichário.
## Uso: godot --headless --path <projeto> --script res://ferramentas/teste_onde_cai.gd

var falhas: int = 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)

func _init() -> void:
	_dados()
	_provisorio()
	_comuns()
	_chefe()
	_ponderado()
	_fichario()
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)

func _dados() -> void:
	_ok(Fases.CONJUNTOS.size() == Fases.TOTAL * 3, "CONJUNTOS tem %d listas, esperado 15" % Fases.CONJUNTOS.size())
	_ok(Fases.CHEFE_ASSINATURA.size() == Fases.CONJUNTOS.size(), "CHEFE_ASSINATURA tem %d" % Fases.CHEFE_ASSINATURA.size())
	var casas: Dictionary = {}
	for i in Fases.CONJUNTOS.size():
		var l: Array = Fases.CONJUNTOS[i]
		_ok(l.size() >= 3 and l.size() <= 4, "lugar %d com %d fantasias (esperado 3 ou 4)" % [i, l.size()])
		for c in l:
			_ok(not Pecas.retirada(c), "fantasia retirada %d na lista %d" % [c, i])
			casas[c] = int(casas.get(c, 0)) + 1
		_ok(l.has(Fases.CHEFE_ASSINATURA[i]), "assinatura do lugar %d fora da lista" % i)
	for c in Pecas.Conjunto.size():
		if Pecas.retirada(c):
			_ok(not casas.has(c), "retirada %d tem casa" % c)
		else:
			_ok(int(casas.get(c, 0)) == 1, "fantasia %s está em %d casas (esperado 1)" % [Pecas.CONJUNTO_NOME[c], int(casas.get(c, 0))])
	_ok(casas.size() == Pecas.n_ativas(), "%d fantasias com casa, ativas %d" % [casas.size(), Pecas.n_ativas()])
	for a in 3:
		var n: int = 0
		for i in range(a * Fases.TOTAL, (a + 1) * Fases.TOTAL):
			n += (Fases.CONJUNTOS[i] as Array).size()
		_ok(n == 18, "ato %d com %d fantasias, esperado 18" % [a + 1, n])
	_ok(Balanco.ATOS == 3, "o 3º ato está ligado")
	_ok(Balanco.degrau_drop(1, 3, false, 0) == 10.0 and Balanco.degrau_drop(5, 3, false, 0) == 14.0, "degrau_drop do 3º ato")
	_ok(Fases.nome_do_lugar(10) == "Mercadão do Peixe" and Fases.nome_do_chefe(14) == "Magnetomiau", "nomes do 3º ato")

func _provisorio() -> void:
	_ok(Fases.PROVISORIO.size() == Fases.TOTAL, "PROVISORIO com %d listas" % Fases.PROVISORIO.size())
	var vistos: Dictionary = {}
	for i in Fases.CONJUNTOS.size():
		var l: Array = Fases.lista_do_lugar(i)
		if i < Fases.TOTAL or i >= Fases.TOTAL * 2 or Balanco.ATOS >= 3:   # com o 3º ato ligado o provisório deixa de valer
			_ok(l == Fases.CONJUNTOS[i], "lugar %d não devia ter provisório" % i)
		else:
			_ok(l.size() <= 8, "lugar %d provisório com %d (máximo 8)" % [i, l.size()])
			_ok(l.size() > (Fases.CONJUNTOS[i] as Array).size(), "lugar %d sem provisórias" % i)
			for c in Fases.PROVISORIO[i - Fases.TOTAL]:
				_ok(Fases.casa_final(c) >= Fases.TOTAL * 2, "provisória %s não é do 3º ato" % Pecas.CONJUNTO_NOME[c])
				_ok(not vistos.has(c), "provisória %s repetida" % Pecas.CONJUNTO_NOME[c])
				vistos[c] = true
	_ok(vistos.size() == (0 if Balanco.ATOS >= 3 else 18), "provisórias cobrem %d fantasias do 3º ato, esperado 18" % vistos.size())
	for c in Pecas.Conjunto.size():
		if not Pecas.retirada(c):
			_ok(Fases.lugar_atual(c) >= 0, "%s não cai em lugar nenhum" % Pecas.CONJUNTO_NOME[c])
	_ok(Fases.pool_anterior(2).size() == 18 and Fases.pool_anterior(3).size() == 36 and Fases.pool_anterior(1).is_empty(), "pool_anterior")

func _comuns() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var casa: Array = Fases.pool_anterior(2)
	var da_lista: int = 0
	var total: int = 4000
	for k in total:
		var tp: int = Fases.pecas_do_slot(7, 2, 2, rng)
		_ok(Pecas.SLOT[tp] == 2, "peça do comum no espaço errado")
		var c: int = Pecas.CONJUNTO_DE[tp]
		_ok(casa.has(c) or Fases.lista_do_lugar(7).has(c), "comum do Telhado vestiu fantasia de fora do lugar e do pool")
		if Fases.lista_do_lugar(7).has(c):
			da_lista += 1
	var frac: float = float(da_lista) / total
	_ok(absf(frac - Balanco.FRACAO_COMUM_DO_LUGAR) < 0.04, "fração do lugar %.3f" % frac)
	for k in 300:
		var c1: int = Pecas.CONJUNTO_DE[Fases.pecas_do_slot(0, 1, 1, rng)]
		_ok((Fases.CONJUNTOS[0] as Array).has(c1), "comum do Quarto vestiu fantasia de outro cômodo")
	var r1 := RandomNumberGenerator.new()
	var r2 := RandomNumberGenerator.new()
	r1.seed = 5
	r2.seed = 5
	var p1: Array = Balanco.gerar_plano(3, 4, r1, 2, 1)
	var p2: Array = Balanco.gerar_plano(3, 4, r2, 2, 1)
	_ok(p1.size() == p2.size(), "plano não repetível")

func _chefe() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for lugar0 in [0, 4, 5, 7, 9]:
		var ato: int = lugar0 / Fases.TOTAL + 1
		var fase: int = lugar0 % Fases.TOTAL + 1
		var sig: int = 0
		var n: int = 1000
		for k in n:
			var pecas: Array = Balanco.gerar_chefe(fase, Balanco.ONDAS_TOTAIS, rng, ato, 0)
			_ok(pecas.size() == 4, "chefe sem 4 peças")
			var c: int = pecas[0].conjunto()
			_ok(Fases.lista_do_lugar(lugar0).has(c), "chefe do lugar %d vestiu fantasia de fora da lista" % lugar0)
			if c == Fases.CHEFE_ASSINATURA[lugar0]:
				sig += 1
		var taxa: float = float(sig) / n
		_ok(absf(taxa - Balanco.CHEFE_ASSINATURA_CHANCE) < 0.06, "assinatura do lugar %d em %.3f" % [lugar0, taxa])

func _ponderado() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var lista: Array = Fases.lista_do_lugar(0)
	var pesos: Dictionary = {lista[0]: 2.0}
	var cont: Dictionary = {}
	for k in 4000:
		var f: Array = Balanco.fantasia(1, 0, 4, rng, pesos, lista[3])
		var c: int = f[0].conjunto()
		cont[c] = int(cont.get(c, 0)) + 1
	_ok(not cont.has(lista[3]), "fantasia excluída saiu no sorteio")
	var r: float = float(cont.get(lista[0], 0)) / maxf(1.0, float(cont.get(lista[1], 1)))
	_ok(absf(r - 2.0) < 0.35, "razão de pesos %.2f (esperado 2)" % r)
	var e := Estado.new(7)
	e.persistir = false
	e.novo_jogo()
	e.colecao.fill(false)
	e.iniciar_fase(1)
	var pw: Dictionary = e.pesos_fantasia_do_lugar()
	_ok(pw.size() == 4 and pw[lista[0]] == Balanco.PESO_FANTASIA_FALTA, "pesos do Estado novo")
	for tp in Pecas.CONJUNTO_PECAS[lista[0]]:
		e.registrar(tp)
	pw = e.pesos_fantasia_do_lugar()
	_ok(pw[lista[0]] == 1.0 and pw[lista[1]] == Balanco.PESO_FANTASIA_FALTA, "fantasia completa devia pesar 1")
	for c in lista:
		for tp in Pecas.CONJUNTO_PECAS[c]:
			e.registrar(tp)
	pw = e.pesos_fantasia_do_lugar()
	for c in lista:
		_ok(pw[c] == 1.0, "todas completas devia ser uniforme")
	e.colecao.fill(false)
	var sim := Simulacao.new()
	sim.estado = e
	sim.rng.seed = 41
	var vest: Array = [Peca.new(Pecas.CONJUNTO_PECAS[lista[0]][0], 0), Peca.new(Pecas.CONJUNTO_PECAS[lista[0]][1], 0)]
	e.registrar(vest[1].tipo)
	var falta: int = 0
	for k in 4000:
		if sim._sortear_peca_vestida(vest, true) == 0:
			falta += 1
	var fr: float = float(falta) / 4000.0
	_ok(absf(fr - 0.75) < 0.04, "peça que falta caiu %.3f (esperado 0,75)" % fr)
	Simulacao.sem_pity = true
	falta = 0
	for k in 4000:
		if sim._sortear_peca_vestida(vest, true) == 0:
			falta += 1
	_ok(absf(float(falta) / 4000.0 - 0.5) < 0.04, "sem_pity devia ser uniforme")
	Simulacao.sem_pity = false

func _fichario() -> void:
	_ok(Fichario.ordem_das_fantasias().size() == Pecas.n_ativas(), "ordem do fichário com %d" % Fichario.ordem_das_fantasias().size())
	var fo: Array[int] = Fichario.fantasias_so_de_fora()
	_ok(fo.size() == Pecas.n_ativas() - 18, "só de fora: %d" % fo.size())
	var c: int = Pecas.Conjunto.CAVALEIRO
	_ok(Fichario.texto_chefe(c) == "Chefe: Rei dos Ratos (assinatura)", "texto_chefe: " + Fichario.texto_chefe(c))
	var tv: String = Fichario.texto_chefe(Pecas.Conjunto.VIKING)
	_ok(tv != "" and tv.find("assinatura") < 0, "Vikingato não é assinatura: " + tv)
	_ok(Fichario.texto_provisorio(c) == "", "casa final não tem aviso")
	var tp: String = Fichario.texto_provisorio(Pecas.Conjunto.SUBMIAUTICA)
	_ok(tp == ("" if Balanco.ATOS >= 3 else "por enquanto cai no Quintal"), "aviso provisório: " + tp)
	var to: String = Fichario.texto_onde(Pecas.Conjunto.MIAUZILLA)
	_ok(to.begins_with("Cai na Arena da Praça"), to)
	_ok(Fichario.lugar_de_fora(Pecas.Conjunto.HOLLOWMIAU) == 9 and Fichario.comodo_da_fantasia(Pecas.Conjunto.HOLLOWMIAU) == -1, "Hollowmiau")
