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
	_moral()
	_tipos_gangue()
	_truques()
	_chefes()
	_save_antigo()
	_torre_niveis()
	_modulos_ruas()
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
		_ok(Fases.chefe_base(10 + i) == Fases.Chefe.DOM_GATLEONE + i, "chefe próprio do lugar %d" % (10 + i))
		_ok(Balanco.CHEFE_PODER_CONJ.size() > Fases.chefe_base(10 + i) and Balanco.CHEFE_ESCALA_TIPO.size() > Fases.chefe_base(10 + i), "tabelas do chefe %d" % (10 + i))
		_ok(Fases.fraqueza_do_chefe(10 + i).length() < 80 and Fases.ataque_do_chefe(10 + i) != "" and not "provisório" in Fases.ataque_do_chefe(10 + i), "textos do chefe %d" % (10 + i))
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

func _moral() -> void:
	# todo plano do 3º ato tem exatamente um líder; o 2º ato não tem
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for fase in range(1, 6):
		for onda in range(1, Balanco.ONDAS_TOTAIS + 1):
			var n: int = 0
			for it in Balanco.gerar_plano(fase, onda, rng, 3, 0):
				if it.get("lider", false):
					n += 1
			_ok(n == 1, "plano do 3º ato com 1 líder (fase %d onda %d: %d)" % [fase, onda, n])
	for it in Balanco.gerar_plano(1, 3, rng, 2, 0):
		_ok(not it.get("lider", false), "2º ato sem líder")
	var e: Estado = _estado()
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [2, 2, 2, 2, 2]
	e.iniciar_fase(1)
	e.onda = 3
	e.preparar_onda()
	var sim := Simulacao.new()
	sim.gerar_eventos = false
	sim.iniciar(e, 99)
	var pecas: Array = [null, null, null, null]
	sim.inimigos.clear()
	sim._spawnar({"pecas": pecas, "tipo": Unidade.Tipo.COMUM, "rival": true, "gangue": 0, "lider": true})
	sim._spawnar({"pecas": pecas, "tipo": Unidade.Tipo.COMUM, "rival": true, "gangue": 0})
	sim._spawnar({"pecas": pecas, "tipo": Unidade.Tipo.COMUM})   # bicho comum: não é rival
	var lid: Unidade = sim.inimigos[0]
	var riv: Unidade = sim.inimigos[1]
	var bicho: Unidade = sim.inimigos[2]
	_ok(lid.lider and not riv.lider and not bicho.lider, "só o marcado é líder")
	sim.passo(0.1)
	_ok(riv.abalado_t == 0.0 and absf(riv.bonus_dano - 1.0) < 0.001 and riv.lento > 0.99, "antes de o líder cair ninguém está abalado")
	sim._matar(lid, null)
	_ok(riv.abalado_t > Balanco.MORAL_T - 0.01, "rival vivo abalado %.2f s" % riv.abalado_t)
	_ok(bicho.abalado_t == 0.0, "bicho que não é rival não abala")
	sim.passo(0.1)
	_ok(absf(riv.bonus_dano - (1.0 - Balanco.MORAL_DANO)) < 0.001, "abalado: -30%% de dano (%.2f)" % riv.bonus_dano)
	_ok(riv.lento <= 1.0 - Balanco.MORAL_VEL + 0.001, "abalado: -30%% de velocidade (%.2f)" % riv.lento)
	var ids := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var tps := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var na: int = IconesEstado.ativos(riv, [], ids, tps)
	var achou: bool = false
	for i in na:
		if ids[i] == IconesEstado.E.ABALADO:
			achou = true
	_ok(achou, "ícone de abalado aparece")
	for k in int(Balanco.MORAL_T / 0.5) + 2:
		sim.passo(0.5)
	_ok(riv.vivo == false or (riv.abalado_t <= 0.0 and absf(riv.bonus_dano - 1.0) < 0.001), "o abalo passa depois de %.0f s" % Balanco.MORAL_T)

func _luta(gangue: int) -> Simulacao:
	var e: Estado = _estado()
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [2, 2, 2, 2, 2]
	e.iniciar_fase(gangue + 1)
	e.onda = 3
	e.preparar_onda()
	var sim := Simulacao.new()
	sim.gerar_eventos = false
	sim.iniciar(e, 99)
	sim.inimigos.clear()
	sim.fila.clear()
	return sim

func _rival(sim: Simulacao, gangue: int, tipo: int, x: float, y: float) -> Unidade:
	sim._spawnar({"pecas": [null, null, null, null], "tipo": tipo, "rival": true, "gangue": gangue})
	var u: Unidade = sim.inimigos[sim.inimigos.size() - 1]
	u.x = x
	u.y = y
	return u

func _tipos_gangue() -> void:
	_ok(Balanco.GANGUE_TIPOS.size() == 5 and Balanco.GANGUE_TIPO_NOME.size() == 5 and Balanco.GANGUE_TIPO_DICA.size() == 5, "tabelas de tipos das 5 gangues")
	for g in 5:
		_ok((Balanco.GANGUE_TIPO_NOME[g] as Array).size() == Balanco.TIPO_NOMES.size() and (Balanco.GANGUE_TIPO_DICA[g] as Array).size() == Balanco.TIPO_NOMES.size(), "nomes e dicas completos da gangue %d" % g)
		for d in Balanco.GANGUE_TIPO_DICA[g]:
			_ok(String(d).length() < 80, "dica curta: " + String(d))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for g in 5:
		var permitidos: Array = [0]
		for par in Balanco.GANGUE_TIPOS[g]:
			permitidos.append(int(par[0]))
		var vistos: Dictionary = {}
		for onda in range(1, Balanco.ONDAS_TOTAIS + 1):
			for it in Balanco.gerar_plano(g + 1, onda, rng, 3, 0):
				_ok(int(it["tipo"]) in permitidos, "gangue %d só sorteia seus tipos (tipo %d)" % [g, it["tipo"]])
				vistos[int(it["tipo"])] = true
		_ok(vistos.size() >= 3, "gangue %d tem variedade de tipos (%d)" % [g, vistos.size()])
	_ok(Balanco.nome_rival(0, Unidade.Tipo.LADRAO) == "Mensageiro" and Balanco.nome_rival(3, Unidade.Tipo.ESCUDEIRO) == "Hoplita", "nomes dos rivais")
	_ok(Balanco.nome_rival(0, Unidade.Tipo.ESCUDEIRO) == Balanco.TIPO_NOMES[Unidade.Tipo.ESCUDEIRO], "nome de reserva")

func _estados_de(u: Unidade) -> Array:
	var ids := PackedInt32Array()
	var tps := PackedFloat32Array()
	ids.resize(IconesEstado.QTD + 2)
	tps.resize(IconesEstado.QTD + 2)
	var n: int = IconesEstado.ativos(u, [], ids, tps)
	var r: Array = []
	for i in n:
		r.append(ids[i])
	return r

## Luta de chefe de gangue: o chefe em campo, parado no meio, com um gato do time na frente.
func _luta_chefe(g: int) -> Array:
	var sim: Simulacao = _luta(g)
	sim._spawnar({"pecas": [null, null, null, null], "tipo": Unidade.Tipo.COMUM, "chefe": true})
	var ch: Unidade = sim.inimigos[sim.inimigos.size() - 1]
	ch.x = 900.0
	ch.y = 550.0
	return [sim, ch]

func _chefes() -> void:
	for g in 5:
		var r: Array = _luta_chefe(g)
		var ch: Unidade = r[1]
		_ok(ch.chefe_tipo == Fases.Chefe.DOM_GATLEONE + g and ch.gangue == g and not ch.rival, "chefe %d: tipo e gangue" % g)
		# ciclo completo: avisa (1 s), solta, e a recarga recomeça
		var sim: Simulacao = r[0]
		ch.truque_cd = 0.0
		sim._chefe_gangue(ch, 0.1)
		_ok(ch.habil >= 0 and ch.aviso_t > 0.0 and ch.aviso_nome != "", "chefe %d: aviso de 1 s antes da habilidade" % g)
		var n: int = 0
		while ch.habil >= 0 and n < 40:
			sim._chefe_gangue(ch, 0.1)
			n += 1
		_ok(n >= 9 and n <= 11 and ch.truque_cd > 0.0, "chefe %d: solta depois do aviso (%d passos)" % [g, n])
		# atordoado no aviso: a habilidade se perde
		ch.truque_cd = 0.0
		sim._chefe_gangue(ch, 0.1)
		ch.aviso_t = 0.0
		sim._chefe_gangue(ch, 0.1)
		_ok(ch.habil == -1, "chefe %d: atordoar corta a habilidade" % g)
	# Dom Gatleone chama o Mensageiro
	var r0: Array = _luta_chefe(0)
	r0[1].truque_cd = 0.0
	for k in 14:
		r0[0]._chefe_gangue(r0[1], 0.1)
	_ok(not r0[0].fila.is_empty() and r0[0].fila[0]["tipo"] == Unidade.Tipo.LADRAO and r0[0].fila[0]["gangue"] == 0, "Dom Gatleone: chama o Mensageiro")
	# Programa Mestre: o disco deixa o gato em pixel e ele recompila uma vez
	var r2: Array = _luta_chefe(2)
	var s2: Simulacao = r2[0]
	var m2: Unidade = r2[1]
	var alvo: Unidade = s2.aliados[0]
	alvo.x = 800.0
	alvo.y = 550.0
	m2.truque_cd = 0.0
	for k in 14:
		s2._chefe_gangue(m2, 0.1)
	for k in 200:
		s2._mover_projeteis(0.05)
	var algum: bool = false
	for al in s2.aliados:
		if al.sequestro_t > 0.0 or not al.vivo:
			algum = true
	_ok(algum, "Programa Mestre: o disco deixa o gato em pixel")
	var vmax: float = m2.vida_max
	m2.vida = 1.0
	s2._matar(m2, null)
	_ok(m2.vivo and m2.recompilou and absf(m2.vida - vmax * Balanco.RECOMPILA_VIDA) < 1.0, "Programa Mestre: recompila uma vez")
	m2.vida = 1.0
	s2._matar(m2, null)
	_ok(not m2.vivo, "Programa Mestre: na segunda queda, cai")
	# Rei Miaunidas: de frente quase não leva dano, de flanco leva
	var r3: Array = _luta_chefe(3)
	var s3: Simulacao = r3[0]
	var rei: Unidade = r3[1]
	var atk: Unidade = s3.aliados[0]
	atk.x = rei.x - 40.0
	atk.y = rei.y
	var v0: float = rei.vida
	s3._dano(atk, rei, 100.0, true)
	var frontal: float = v0 - rei.vida
	atk.y = rei.y + 100.0
	v0 = rei.vida
	s3._dano(atk, rei, 100.0, true)
	var flanco: float = v0 - rei.vida
	_ok(frontal < flanco * 0.5 and flanco > 0.0, "Rei: frontal %.1f contra flanco %.1f" % [frontal, flanco])
	# Magnetomiau: o ímã suspende o bônus de conjunto por 6 s
	var r4: Array = _luta_chefe(4)
	var s4: Simulacao = r4[0]
	var mag: Unidade = r4[1]
	var gt: Unidade = s4.aliados[0]
	for k in Pecas.SLOTS:
		gt.pecas[k] = Peca.new(Pecas.CONJUNTO_PECAS[Pecas.Conjunto.CAVALEIRO][k], 10)
	s4.calcular(gt)
	var arm0: float = gt.armadura
	gt.x = mag.x - 200.0
	mag.truque_cd = 0.0
	for k in 14:
		s4._chefe_gangue(mag, 0.1)
	_ok(gt.sem_conjunto_t > 0.0 and gt.armadura < arm0, "Magnetomiau: bônus de conjunto suspenso (armadura %.1f -> %.1f)" % [arm0, gt.armadura])
	for k in 70:
		s4._sem_conjunto_tick(0.1)
	_ok(gt.sem_conjunto_t == 0.0 and absf(gt.armadura - arm0) < 0.01, "Magnetomiau: o bônus volta depois de 6 s")

func _truques() -> void:
	# Oferta: o Mensageiro toca a torre e o gato com mais peças dorme 6 s, fora da luta
	var sim: Simulacao = _luta(0)
	var gato: Unidade = sim.aliados[0]
	gato.pecas[0] = Peca.new(Pecas.Tipo.values()[0], 1)
	var m: Unidade = _rival(sim, 0, Unidade.Tipo.LADRAO, Balanco.TORRE_X + 10.0, 550.0)
	var tij: int = sim.estado.tijolos
	sim._bater_torre(m)
	_ok(gato.sequestro_t > Balanco.OFERTA_T - 0.01, "Oferta: o gato com mais peças dorme %.1f s" % gato.sequestro_t)
	_ok(sim.estado.tijolos == tij and m.fugindo and m.carga == 0, "Oferta: nenhum bloco roubado e o Mensageiro foge")
	_ok(sim._escolher(_rival(sim, 0, Unidade.Tipo.COMUM, 600.0, 550.0)) != gato, "Oferta: o gato dormindo não é alvo")
	var vida0: float = gato.vida
	sim._dano(m, gato, 50.0, true)
	_ok(gato.vida == vida0, "Oferta: o gato dormindo não leva dano")
	_ok(IconesEstado.E.DORMINDO in _estados_de(gato), "ícone de dormindo")
	for k in int(Balanco.OFERTA_T / 0.5) + 2:
		sim._agir(gato, 0.5)
	_ok(gato.sequestro_t == 0.0, "Oferta: o gato acorda")
	# sem gato para levar, volta a roubar blocos
	var sim_b: Simulacao = _luta(0)
	for a in sim_b.aliados:
		a.vivo = false
	var m2: Unidade = _rival(sim_b, 0, Unidade.Tipo.LADRAO, Balanco.TORRE_X + 10.0, 550.0)
	var t2: int = sim_b.estado.tijolos
	sim_b._bater_torre(m2)
	_ok(sim_b.estado.tijolos < t2, "Oferta: sem gato de pé, rouba blocos")
	# o ladrão de outra gangue só rouba blocos
	var sim_c: Simulacao = _luta(1)
	var l: Unidade = _rival(sim_c, 1, Unidade.Tipo.LADRAO, Balanco.TORRE_X + 10.0, 550.0)
	var t3: int = sim_c.estado.tijolos
	sim_c._bater_torre(l)
	_ok(sim_c.estado.tijolos < t3 and sim_c.aliados[0].sequestro_t == 0.0, "Saqueador da Estrada rouba blocos, não gatos")

	# Comboio: o Guitarrista acelera os rivais da gangue em volta; Motoqueiro acerta o gato de trás e segue à torre
	var sc: Simulacao = _luta(1)
	var g1: Unidade = _rival(sc, 1, Unidade.Tipo.ATIRADOR, 800.0, 550.0)
	var perto: Unidade = _rival(sc, 1, Unidade.Tipo.COMUM, 850.0, 560.0)
	var longe: Unidade = _rival(sc, 1, Unidade.Tipo.COMUM, 1250.0, 560.0)
	sc.passo(0.05)
	_ok(perto.comboio and g1.comboio and not longe.comboio, "Comboio: só quem está perto")
	_ok(perto.lento >= 1.0 + Balanco.COMBOIO_VEL - 0.01 and longe.lento <= 1.0, "Comboio: +velocidade (%.2f)" % perto.lento)
	var mo: Unidade = _rival(sc, 1, Unidade.Tipo.SALTADOR, 900.0, 550.0)
	var atras: Unidade = sc._mais_atras()
	_ok(sc._escolher(mo) == atras, "Motoqueiro vai ao gato da fileira de trás")
	mo.x = atras.x + 10.0
	mo.y = atras.y
	mo.cd = 0.0
	sc._atacar(mo, atras)
	_ok(mo.atropelou and sc._escolher(mo) == null, "Motoqueiro acerta uma vez e segue à torre")

	# Recompilação: o Programa volta uma vez com 40%
	var sg: Simulacao = _luta(2)
	var pr: Unidade = _rival(sg, 2, Unidade.Tipo.COMUM, 800.0, 550.0)
	var vm: float = pr.vida_max
	sg._matar(pr, null)
	_ok(pr.vivo and absf(pr.vida - vm * Balanco.RECOMPILA_VIDA) < 0.01 and pr.recompilou, "Recompilação: volta com 40%")
	sg._matar(pr, null)
	_ok(not pr.vivo, "Recompilação: só uma vez")
	var gr: Unidade = _rival(sg, 2, Unidade.Tipo.GIGANTE, 800.0, 550.0)
	sg._matar(gr, null)
	_ok(not gr.vivo, "Recompilação: só o Programa comum")
	# Disco: quica em até 3 alvos
	var sd: Simulacao = _luta(2)
	var base_g: Unidade = sd.aliados[0]
	while sd.aliados.size() < 3:
		var nu := Unidade.new()
		nu.boneco = base_g.boneco
		sd.aliados.append(nu)
	var k: int = 0
	for a in sd.aliados:
		a.x = 500.0 + k * 40.0
		a.y = 550.0
		a.vida_max = 9999.0
		a.vida = 9999.0
		k += 1
	var lan: Unidade = _rival(sd, 2, Unidade.Tipo.ATIRADOR, 900.0, 550.0)
	lan.cd = 0.0
	sd._atacar(lan, sd.aliados[0])
	for i in 400:
		sd._mover_projeteis(0.02)
	_ok(int(sd.truques_n.get("quica", 0)) == Balanco.DISCO_QUICAS, "Disco quica %d vezes (%d)" % [Balanco.DISCO_QUICAS, int(sd.truques_n.get("quica", 0))])
	var feridos: int = 0
	for a in sd.aliados:
		if a.vida < 9999.0:
			feridos += 1
	_ok(feridos == 3, "Disco fere 3 gatos diferentes (%d)" % feridos)

	# Falange: hoplitas juntos reduzem o dano de frente; o flanco fura
	var sf: Simulacao = _luta(3)
	var h1: Unidade = _rival(sf, 3, Unidade.Tipo.ESCUDEIRO, 800.0, 550.0)
	var h2: Unidade = _rival(sf, 3, Unidade.Tipo.ESCUDEIRO, 850.0, 560.0)
	var h3: Unidade = _rival(sf, 3, Unidade.Tipo.ESCUDEIRO, 1300.0, 560.0)
	sf.passo(0.05)
	_ok(h1.falange == 1 and h2.falange == 1 and h3.falange == 0, "Falange: vizinhos %d/%d/%d" % [h1.falange, h2.falange, h3.falange])
	var atk: Unidade = sf.aliados[0]
	atk.x = 700.0
	atk.y = 550.0
	atk.perfura = false
	for h in [h1, h3]:
		h.armadura = 0.0
		h.reducao = 0.0
		h.vida = 1000.0
		h.vida_max = 1000.0
	sf._dano(atk, h1, 100.0, true)
	sf._dano(atk, h3, 100.0, true)
	var com: float = 1000.0 - h1.vida
	var sem: float = 1000.0 - h3.vida
	_ok(absf(com / sem - (1.0 - Balanco.FALANGE_POR_VIZINHO)) < 0.01, "Falange: -15%% por vizinho de frente (%.1f x %.1f)" % [com, sem])
	h1.vida = 1000.0
	atk.y = 550.0 + Balanco.FALANGE_FLANCO + 20.0
	sf._dano(atk, h1, 100.0, true)
	_ok(absf((1000.0 - h1.vida) - sem) < 0.01, "Falange: o flanco fura (%.1f)" % (1000.0 - h1.vida))
	h1.vida = 1000.0
	atk.y = 550.0
	sf._dano_poder(atk, h1, 100.0)
	_ok(absf((1000.0 - h1.vida) - 100.0) < 0.5, "Falange: poderes furam")

	# Mutação: abaixo de 30% de vida, +30% de dano e de velocidade
	var sm: Simulacao = _luta(4)
	var mu: Unidade = _rival(sm, 4, Unidade.Tipo.COMUM, 800.0, 550.0)
	sm.passo(0.05)
	_ok(not mu.mutante and absf(mu.bonus_dano - 1.0) < 0.001, "Mutação: sadio não muda")
	mu.vida = mu.vida_max * 0.2
	sm.passo(0.05)
	_ok(mu.mutante and absf(mu.bonus_dano - (1.0 + Balanco.MUTACAO_DANO)) < 0.001 and mu.lento >= 1.0 + Balanco.MUTACAO_VEL - 0.001, "Mutação: +30%% dano e velocidade (%.2f/%.2f)" % [mu.bonus_dano, mu.lento])
	_ok(IconesEstado.E.MUTANTE in _estados_de(mu), "ícone de mutante")

func _save_antigo() -> void:
	var e: Estado = _estado()
	e.vencido = [2, 2, 2, 2, 2]
	_ok(e.vencido.size() == 5, "vencido continua com 5 índices (sem campo novo)")
	e.fases_vencidas = Fases.TOTAL
	_ok(e.campanha_vencida() and not e.tudo_vencido(), "pós-jogo aberto e o 3º ato ainda por vencer")
	e.vencido = [3, 3, 3, 3, 3]
	_ok(e.tudo_vencido() and e.atos_vencidos() == 3, "3º ato vencido")

## Torre (etapa 7): níveis 9 e 10 só no 3º ato, preço 8, Enfermaria fecha em 100%, vagas e herança.
func _torre_niveis() -> void:
	var e: Estado = _estado()
	_ok(e.nivel_max_melhoria() == 8, "antes do 3º ato o teto é 8")
	e.melhorias[0] = 8
	e.trofeus = 100
	_ok(not e.pode_melhorar(0) and Oficina.motivo_melhoria(e, 0) == "Libera no 3º ato", "nível 9 trancado antes do 3º ato")
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [2, 2, 2, 2, 2]
	_ok(e.ato_atual() == 3 and e.nivel_max_melhoria() == 10, "entrar no 3º ato libera o 10")
	_ok(Torre.custo_melhoria(7) == 6 and Torre.custo_melhoria(8) == 8 and Torre.custo_melhoria(9) == 8, "preços: 6 até o 8, 8 nos níveis 9 e 10")
	_ok(e.melhorar(0) and e.melhorias[0] == 9 and e.trofeus == 92, "compra o nível 9 por 8")
	_ok(e.melhorar(0) and e.melhorias[0] == 10 and not e.pode_melhorar(0), "nível 10 e fim")
	_ok(e.tijolos_max() == Balanco.TIJOLOS_INICIAIS + Torre.ESTRUTURA_BLOCOS * 10, "Estrutura 10: +3 blocos por nível")
	_ok(absf(Balanco.CURA_MAX + Torre.enfermaria_cura(10) - 1.0) < 0.001, "Enfermaria 10 fecha em 100%% (%.4f)" % (Balanco.CURA_MAX + Torre.enfermaria_cura(10)))
	_ok(Balanco.CURA_MAX + Torre.enfermaria_cura(8) < Balanco.CURA_MAX + Torre.enfermaria_cura(9), "Enfermaria 9 > 8")
	# save antigo (níveis até 8) carrega igual; nível 10 sobrevive à gravação
	e.persistir = false
	var d: Dictionary = {"melhorias": [8, 3, 0, 8]}
	_ok(Torre.MELHORIA_NIVEL_MAX == 10 and clampi(int(d["melhorias"][0]), 0, Torre.MELHORIA_NIVEL_MAX) == 8, "save antigo: níveis até 8 continuam")
	# 4ª vaga ao vencer o 3º ato e 4ª herança aos 40
	_ok(e.vagas_modulos() == 3, "3 vagas com o 2º ato vencido")
	e.vencido = [3, 3, 3, 3, 3]
	_ok(e.vagas_modulos() == 4, "4ª vaga ao vencer o 3º ato")
	var b := Boneco.new()
	b.nivel = 40
	_ok(b.herancas_pendentes() == 4, "4ª herança no nível 40 (%d pendentes)" % b.herancas_pendentes())

## Módulos das ruas (etapa 7): liberados por chefe de gangue (vencido >= 3) e efeitos na luta.
func _modulos_ruas() -> void:
	_ok(Torre.MODULO_NOME.size() == 15 and Torre.MODULO_DICA.size() == 15, "15 módulos com nome e dica")
	var e: Estado = _estado()
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [2, 2, 2, 2, 2]
	for m in range(10, 15):
		_ok(not e.modulo_liberado(m), "módulo %d fechado antes do chefe de gangue" % m)
	e.vencido = [3, 2, 2, 2, 3]
	_ok(e.modulo_liberado(Torre.Modulo.RECUSA) and e.modulo_liberado(Torre.Modulo.IMA) and not e.modulo_liberado(Torre.Modulo.SUCATA), "Dom Gatleone e Magnetomiau liberam os seus")
	_ok(e.modulo_liberado(Torre.Modulo.REFORCO) and e.modulo_liberado(0), "módulos antigos intactos")
	_ok(e.alternar_modulo(Torre.Modulo.IMA) and e.tem_modulo(Torre.Modulo.IMA), "monta o Ímã")
	_ok(Oficina.requisito_modulo(Torre.Modulo.MURALHA).contains("Rei Miaunidas") and Oficina.requisito_modulo(Torre.Modulo.MURALHA).contains("3º ato"), "requisito: " + Oficina.requisito_modulo(Torre.Modulo.MURALHA))
	for m in range(10, 15):
		_ok(Oficina.ICO_MODULO_RUAS[m - 10].size() == 12, "ícone %d com 12 linhas" % m)
		_ok(Torre.MODULO_DICA[m].length() < 80, "dica %d curta" % m)
	# Oferta recusada: o 1º ladrão desiste, o 2º rouba
	var s1: Simulacao = _luta(1)
	s1.estado.modulos = [Torre.Modulo.RECUSA]
	var l1: Unidade = _rival(s1, 1, Unidade.Tipo.LADRAO, Balanco.TORRE_X + 10.0, 550.0)
	var t1: int = s1.estado.tijolos
	s1._bater_torre(l1)
	_ok(not l1.vivo and s1.estado.tijolos == t1, "Oferta recusada: o 1º ladrão vai embora sem roubar")
	var l2: Unidade = _rival(s1, 1, Unidade.Tipo.LADRAO, Balanco.TORRE_X + 10.0, 550.0)
	s1._bater_torre(l2)
	_ok(s1.estado.tijolos < t1, "Oferta recusada: só o primeiro da onda")
	# Sucata: a 1ª bomba explode sem tirar bloco, a 2ª tira
	var s2: Simulacao = _luta(1)
	s2.estado.modulos = [Torre.Modulo.SUCATA]
	var t2: int = s2.estado.tijolos
	s2._bater_torre(_rival(s2, 1, Unidade.Tipo.BOMBA, Balanco.TORRE_X + 10.0, 550.0))
	_ok(s2.estado.tijolos == t2, "Sucata: a 1ª bomba não tira bloco")
	s2._bater_torre(_rival(s2, 1, Unidade.Tipo.BOMBA, Balanco.TORRE_X + 10.0, 550.0))
	_ok(s2.estado.tijolos == t2 - Balanco.BOMBA_TORRE, "Sucata: a 2ª bomba tira %d" % Balanco.BOMBA_TORRE)
	# Muralha: o gigante rival tira só 1 e um golpe em cada três é barrado
	var s3: Simulacao = _luta(3)
	s3.estado.modulos = [Torre.Modulo.MURALHA]
	var t3: int = s3.estado.tijolos
	var gg: Unidade = _rival(s3, 3, Unidade.Tipo.GIGANTE, Balanco.TORRE_X + 10.0, 550.0)
	s3._bater_torre(gg)
	s3._bater_torre(gg)
	_ok(s3.estado.tijolos == t3 - 2, "Muralha: dois golpes de gigante tiram 1 cada (%d)" % (t3 - s3.estado.tijolos))
	s3._bater_torre(gg)
	_ok(s3.estado.tijolos == t3 - 2, "Muralha: o 3º golpe é barrado")
	# Firewall: dois bichos perto da torre congelam, uma vez só
	var s4: Simulacao = _luta(2)
	s4.estado.modulos = [Torre.Modulo.FIREWALL]
	var f1: Unidade = _rival(s4, 2, Unidade.Tipo.COMUM, Balanco.TORRE_X + 60.0, 550.0)
	var f2: Unidade = _rival(s4, 2, Unidade.Tipo.COMUM, Balanco.TORRE_X + 100.0, 560.0)
	var longe: Unidade = _rival(s4, 2, Unidade.Tipo.COMUM, Balanco.TORRE_X + 600.0, 560.0)
	s4._modulos_da_torre(0.1)
	_ok(f1.atordoado_t >= Torre.FIREWALL_T - 0.01 and f2.atordoado_t >= Torre.FIREWALL_T - 0.01 and longe.atordoado_t <= 0.0, "Firewall congela quem está perto")
	f1.atordoado_t = 0.0
	s4._modulos_da_torre(0.1)
	_ok(f1.atordoado_t <= 0.0, "Firewall: uma vez por onda")
	# Ímã: o tiro da torre empurra o alvo; o chefe, só um pouco
	var s5: Simulacao = _luta(4)
	s5.estado.modulos = [Torre.Modulo.IMA]
	var al: Unidade = _rival(s5, 4, Unidade.Tipo.COMUM, 700.0, 550.0)
	al.vida = 9999.0
	s5.projeteis.append({"x": al.x, "y": al.y, "alvo": al, "dono": null, "dano": 1.0, "torre": true})
	s5._mover_projeteis(0.05)
	_ok(al.x - 700.0 >= Torre.IMA_PUXA - 0.5, "Ímã: o alvo recua %.0f px" % (al.x - 700.0))
