extends SceneTree
## Teste headless do Ateliê (fantasia secreta): sem orçamento, validação, persistência (sem tocar no save real) e kit na simulação.
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
	_sem_orcamento()
	_nome()
	_persistencia()
	_kit_na_simulacao()
	_poder_contra_origem()
	_desenho()
	_pintura()
	Atelie.aplicar({})
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)

func _sem_orcamento() -> void:
	var T = Pecas.Tipo
	var C = Pecas.Conjunto
	for c in Atelie.BONUS_KITS:
		_ok(not Pecas.retirada(c) and c != C.ATELIE, "bônus %d do Ateliê vem de fantasia fora do jogo" % c)
	# sem orçamento: o melhor de tudo (moldes fortes, poder forte, bônus forte) é aceito, e a combinação simples também
	var melhor: Dictionary = _cfg([T.CARTOLA, T.CASACO, T.VARINHA, T.AMULETO], C.CIRCO, C.VIKING)
	var barata: Dictionary = _cfg([T.CAPACETE, T.COLETE, T.PORRETE, T.BOTAS], C.MIAULAX, C.CIRCO)
	var e := _estado_completo(5)
	_ok(Atelie.liberado(e), "com tudo completo o Ateliê devia abrir")
	_ok(Atelie.confirmar(e, melhor), "confirmar recusou o melhor de tudo (não há orçamento)")
	_ok(e.atelie.get("formas", []) == melhor["formas"] and int(e.atelie.get("bonus", -1)) == C.VIKING, "o melhor de tudo não ficou gravado")
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

## O poder do Ateliê é o da fantasia de origem, com a mesma recarga e PODER_FORCA_FATOR de força, com peças novas e no
## fim de jogo (nível máximo, raridade máxima): um gato veste o Ateliê, outro a fantasia original, com o mesmo nível.
func _poder_contra_origem() -> void:
	var T = Pecas.Tipo
	_ok(is_equal_approx(Atelie.PODER_FORCA_FATOR, 1.2) and is_equal_approx(Atelie.PODER_RECARGA_FATOR, 1.0), "o poder do Ateliê devia ser o da origem com 20% a mais")
	var e0 := _estado_completo(40)
	var piores: Array[String] = []
	for c in Atelie.poderes(e0):
		for nr in [[0, Pecas.Raridade.RARA], [Balanco.NIVEL_MAX, Pecas.Raridade.MIAUJESTOSA]]:
			var e := _estado_completo(41)
			# mesmo bônus de kit quando o Ateliê o oferece (o do Jimiau encurta a recarga); o do Meon é composto e fica de fora
			var bo: int = c if c in Atelie.BONUS_KITS else Atelie.BONUS_KITS[0]
			Atelie.aplicar(_cfg([T.CAPACETE, T.COLETE, T.PORRETE, T.BOTAS], c, bo))
			e.iniciar_fase(1)
			for s in Pecas.SLOTS:
				e.bonecos[0].pecas[s] = Peca.new(T.ATELIE_CABECA + s, nr[0], nr[1])
				e.bonecos[1].pecas[s] = Peca.new(int((Pecas.CONJUNTO_PECAS[c] as Array)[s]), nr[0], nr[1])
			var sim := Simulacao.new()
			sim.gerar_eventos = false
			sim.iniciar(e, 7)
			var ua: Unidade = null
			var uo: Unidade = null
			for a in sim.aliados:
				if a.boneco == e.bonecos[0]:
					ua = a
				elif a.boneco == e.bonecos[1]:
					uo = a
			if ua == null or uo == null or not ua.poder_atelie or ua.poder_conj != c or uo.poder_conj != c:
				_ok(false, "fantasia %d: os dois gatos deviam ter o poder dela" % c)
				continue
			var forca_a: float = ua.poder_forca * Atelie.PODER_FORCA_FATOR
			var razao: float = forca_a / uo.poder_forca
			var recarga_ok: bool = is_equal_approx(sim._intervalo_poder(ua), sim._intervalo_poder(uo)) or bo != c
			if absf(razao - 1.2) > 0.001 or not recarga_ok:
				piores.append("%s nv%d: %.2fx, recarga %.1f contra %.1f" % [Pecas.CONJUNTO_NOME[c], nr[0], razao, sim._intervalo_poder(ua), sim._intervalo_poder(uo)])
	_ok(piores.is_empty(), "poder do Ateliê fora de 1,2x a origem: " + ", ".join(piores.slice(0, 6)))
	Atelie.aplicar({})

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
	var bonus_l: Array = Atelie.BONUS_KITS
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

## Pintura: foto da forma, ida e volta pelo formato do save, save adulterado, camada de trás e confirmar com pintura.
func _pintura() -> void:
	var T = Pecas.Tipo
	var C = Pecas.Conjunto
	var cfg: Dictionary = _cfg([T.COROA, T.CAPA, T.VARINHA, T.BOTAS], C.CAVALEIRO, C.CIRCO)
	Atelie.aplicar(Atelie.ler(cfg))
	for s in Pecas.SLOTS:
		var g: Dictionary = AtelieArte.fotografar(T.ATELIE_CABECA + s)
		var n: int = 0
		for c in (g["frente"] as PackedColorArray) + (g["atras"] as PackedColorArray):
			n += 1 if c.a > 0.02 else 0
		_ok(n > 3, "a foto da peça %d saiu quase vazia (%d pixels)" % [s, n])
		_ok(int(g["w"]) >= Atelie.PINTURA_MIN and int(g["w"]) <= Atelie.PINTURA_MAX and int(g["h"]) <= Atelie.PINTURA_MAX, "tamanho da grade %d" % s)
		# ida e volta: grade -> save -> grade dá os mesmos pixels
		var p: Dictionary = Atelie.pintura_da_grade(g)
		_ok(Atelie.ler_pintura(p) == p, "a pintura %d não passa na própria leitura" % s)
		var g2: Dictionary = Atelie.grade_da_pintura(JSON.parse_string(JSON.stringify(p)))
		var iguais: bool = true
		for k in ["frente", "atras"]:
			var a: PackedColorArray = g[k]
			var b: PackedColorArray = g2[k]
			for i in a.size():
				var dif: Vector4 = Vector4(a[i].r - b[i].r, a[i].g - b[i].g, a[i].b - b[i].b, a[i].a - b[i].a).abs()
				if (a[i].a > 0.02) != (b[i].a > 0.02) or (a[i].a > 0.02 and maxf(maxf(dif.x, dif.y), maxf(dif.z, dif.w)) > 0.5 / 255.0 + 0.0001):   # o save guarda 8 bits por canal
					iguais = false
		_ok(iguais, "ida e volta mudou os pixels da peça %d" % s)
	# a capa tem camada atrás do corpo; a coroa não
	var capa: Dictionary = AtelieArte.fotografar(T.ATELIE_CORPO)
	var atras: int = 0
	for c in (capa["atras"] as PackedColorArray):
		atras += 1 if c.a > 0.02 else 0
	_ok(RoupaGato.tem_atras(T.CAPA) == (atras > 0), "camada de trás da capa (%d pixels)" % atras)
	var coroa: Dictionary = AtelieArte.fotografar(T.ATELIE_CABECA)
	var atras_coroa: int = 0
	for c in (coroa["atras"] as PackedColorArray):
		atras_coroa += 1 if c.a > 0.02 else 0
	_ok(atras_coroa == 0, "a coroa não tem camada de trás")
	# pintar um pixel muda a pintura; toda vazia vale (peça invisível)
	var gp: Dictionary = AtelieArte.fotografar(T.ATELIE_CABECA)
	var fr: PackedColorArray = gp["frente"]
	fr[0] = Color(0.1, 0.9, 0.2)
	gp["frente"] = fr
	var pp: Dictionary = Atelie.pintura_da_grade(gp)
	_ok(str(pp["frente"])[0] != ".", "o pixel pintado não chegou à pintura")
	var vazia: Dictionary = Atelie.grade_em_volta({}, {})
	var pv: Dictionary = Atelie.pintura_da_grade(vazia)
	_ok(not Atelie.ler_pintura(pv).is_empty(), "pintura toda vazia devia valer")
	# muitas cores: a paleta não passa do máximo
	var gm: Dictionary = Atelie.grade_em_volta({}, {})
	var fm: PackedColorArray = gm["frente"]
	for i in fm.size():
		fm[i] = Color.from_hsv(float(i) / fm.size(), 0.8, 0.9)
	gm["frente"] = fm
	var pm: Dictionary = Atelie.pintura_da_grade(gm)
	_ok((pm["pal"] as Array).size() <= Atelie.PALETA_MAX and not Atelie.ler_pintura(pm).is_empty(), "paleta grande demais (%d)" % (pm["pal"] as Array).size())
	# save adulterado: a pintura ruim cai, a fantasia fica
	var ruins: Array = [
		{"x": 0, "y": 0, "w": 2, "h": 1, "pal": ["ff0000ff"], "frente": "0", "atras": ".."},
		{"x": 0, "y": 0, "w": 2, "h": 1, "pal": ["ff0000ff"], "frente": "05", "atras": ".."},
		{"x": 0, "y": 0, "w": 2, "h": 1, "pal": ["zz0000ff"], "frente": "00", "atras": ".."},
		{"x": 0, "y": 0, "w": 999, "h": 1, "pal": [], "frente": "", "atras": ""},
		"lixo",
	]
	for r in ruins:
		var cr: Dictionary = cfg.duplicate(true)
		cr["pintura"] = [r, pp, {}, {}]
		var l: Dictionary = Atelie.ler(cr)
		_ok(not l.is_empty(), "pintura ruim derrubou a fantasia: " + str(r))
		_ok((l["pintura"][0] as Dictionary).is_empty() and not (l["pintura"][1] as Dictionary).is_empty(), "pintura ruim passou ou a boa caiu: " + str(r))
	_ok((Atelie.ler(cfg)["pintura"] as Array).size() == Pecas.SLOTS, "save sem pintura (antigo) devia ler 4 espaços vazios")
	# confirmar com pintura: grava, relê e a peça passa a desenhar a pintura
	var e := _estado_completo(31)
	var cp: Dictionary = cfg.duplicate(true)
	cp["pintura"] = [pp, {}, {}, {}]
	_ok(Atelie.confirmar(e, cp), "confirmar com pintura")
	_ok(Atelie.pintada(T.ATELIE_CABECA) and not Atelie.pintada(T.ATELIE_CORPO), "a pintura não ficou ativa só na cabeça")
	var relida: Dictionary = Atelie.ler(JSON.parse_string(JSON.stringify(e.atelie)))
	_ok(relida["pintura"][0] == pp, "a pintura não sobreviveu ao save")
	_ok(Desenho.caixa_peca(T.ATELIE_CABECA).size.x > 0.0, "caixa do ícone da peça pintada")
	Atelie.aplicar({})
