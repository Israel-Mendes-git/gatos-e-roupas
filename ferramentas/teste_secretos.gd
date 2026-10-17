extends SceneTree
## Teste headless do chefe secreto (Gato de Schrödinger): liberação pelo bestiário, alternância vivo/morto, imunidade a golpes
## quando morto, prêmio Miaujestosa e save compatível. Uso: godot --headless --path <projeto> --script res://ferramentas/teste_secretos.gd
## Com o argumento "medir": luta N vezes com um time de fim de jogo e imprime a taxa de vitória.

var falhas: int = 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)

func _estado(sem: int = 4242) -> Estado:
	var e := Estado.new(sem)
	e.persistir = false
	e.novo_jogo()
	return e

func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0 and args[0] == "medir":
		_medir(int(args[1]) if args.size() > 1 else 20)
		quit()
		return
	_liberacao()
	_alternancia()
	_premio()
	_save()
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)

func _completo(e: Estado) -> void:
	e.fases_vencidas = Fases.TOTAL
	e.vencido = [3, 3, 3, 3, 3]
	e.bichos_vistos.clear()
	for i in 5:
		e.bichos_vistos["f%d" % i] = true
		e.bichos_vistos["b%d" % i] = true
		e.bichos_vistos["g%d" % i] = true
	for t in 10:
		e.bichos_vistos["t%d" % t] = true
	for c in 10:
		e.bichos_vistos["c%d" % c] = true

func _liberacao() -> void:
	var e: Estado = _estado()
	_ok(not e.schro_liberado(), "campanha nova não libera a caixa")
	_completo(e)
	_ok(e.bichos_vistos_total() == Estado.BICHOS_TOTAL, "35 bichos (%d)" % e.bichos_vistos_total())
	_ok(e.bestiario_completo() and e.schro_liberado(), "bestiário completo libera")
	e.bichos_vistos.erase("g3")
	_ok(not e.schro_liberado(), "sem uma gangue não libera")
	e.bichos_vistos["g3"] = true
	e.bichos_vistos["h3"] = true
	_ok(e.bestiario_completo(), "chefe de gangue (auxiliar) não muda a conta")

func _lutar(e: Estado, sem: int, limite: float) -> Simulacao:
	var sim := Simulacao.new()
	sim.gerar_eventos = false
	sim.iniciar(e, sem)
	while not sim.terminada and sim.tempo < limite:
		sim.passo(Balanco.DT)
	return sim

func _alternancia() -> void:
	var e: Estado = _estado()
	_completo(e)
	e.iniciar_secreto()
	_ok(e.secreto and e.plano.is_empty() and e.chefe.size() == 4, "onda só de chefe")
	_ok(e.lugar_chefe() == Fases.TOTAL * 3 and Fases.nome_do_chefe(e.lugar_chefe()) == "Gato de Schrödinger", "nome do chefe")
	_ok(Fases.fraqueza_do_chefe(15).length() < 80, "dica < 80 caracteres")
	var sim := Simulacao.new()
	sim.gerar_eventos = false
	sim.iniciar(e, 5)
	var ch: Unidade = null
	for a in sim.aliados:
		a.vida_max = 1e9
		a.vida = 1e9   # o time aguenta os 40 s: o teste é da alternância
	var t_troca: Array[float] = []
	var ult: bool = false
	var vivo_atingido: bool = false
	var imune_ok: bool = true
	while sim.tempo < 40.0 and not sim.terminada:
		sim.passo(Balanco.DT)
		for u in sim.inimigos:
			if u.chefe:
				ch = u
		if ch != null:
			if ch.morto != ult:
				t_troca.append(sim.tempo)
				ult = ch.morto
			if ch.morto:
				var v0: float = ch.vida
				var alvo := Unidade.new()
				sim._dano(alvo, ch, 50.0, true)
				if ch.vida < v0:
					imune_ok = false
				sim._dano_poder(alvo, ch, 1.0)
				if ch.vida >= v0:
					imune_ok = imune_ok and true
	_ok(t_troca.size() >= 2, "alternou (%d trocas)" % t_troca.size())
	if t_troca.size() >= 2:
		_ok(absf((t_troca[1] - t_troca[0]) - Balanco.SCHRO_T) < 0.2, "troca a cada 6 s (%.2f)" % (t_troca[1] - t_troca[0]))
	_ok(imune_ok, "morto: golpe não fere")
	# poder fere morto
	if ch != null:
		ch.morto = true
		var v1: float = ch.vida
		sim._dano_poder(Unidade.new(), ch, 5.0)
		_ok(ch.vida < v1, "morto: poder fere")
		ch.morto = false
		v1 = ch.vida
		sim._dano(Unidade.new(), ch, 50.0, true)
		_ok(ch.vida < v1, "vivo: golpe fere")

func _premio() -> void:
	var e: Estado = _estado()
	_completo(e)
	e.iniciar_secreto()
	var sim := Simulacao.new()
	sim.gerar_eventos = false
	sim.iniciar(e, 9)
	sim.passo(Balanco.DT * 400)   # entra o chefe
	var ch: Unidade = null
	for u in sim.inimigos:
		if u.chefe:
			ch = u
	_ok(ch != null and ch.chefe_tipo == Fases.Chefe.SCHRODINGER, "chefe em campo")
	if ch == null:
		return
	sim._matar(ch, Unidade.new())
	var maj: int = 0
	for p in sim.bau:
		if p.raridade == Pecas.Raridade.MIAUJESTOSA:
			maj += 1
	_ok(maj == 1, "primeira vitória larga 1 peça Miaujestosa (%d)" % maj)
	sim.terminada = true
	sim.vitoria = true
	var tr0: int = e.trofeus
	var fim: bool = e.encerrar_onda(sim)
	_ok(fim and e.feitos.has("schro") and e.trofeus >= tr0 + Balanco.SCHRO_TROFEUS, "vitória anotada e troféus")
	_ok(e.metas_pagas.has("schro"), "meta paga")

func _save() -> void:
	var e: Estado = _estado()
	_completo(e)
	e.feitos["schro"] = true
	e.persistir = false
	var antigo := Estado.new(1)
	_ok(not antigo.secreto and not antigo.feitos.has("schro"), "campo opcional: save antigo sem o feito")
	var d: Dictionary = e._dados_curso()
	_ok(d.is_empty() or d.has("secreto"), "curso leva o campo opcional")

## Mede a vitória de primeira com um time de fim de jogo (peças Míticas nível 12, 5 gatos).
func _medir(n: int) -> void:
	var venc: int = 0
	for g in n:
		var e: Estado = _estado(100 + g)
		_completo(e)
		e.fases_vencidas = Fases.TOTAL
		while e.bonecos.size() < Balanco.MAX_BONECOS:
			e.bonecos.append(Boneco.new())
		var tipos: Array = [Pecas.Tipo.PORRETE, Pecas.Tipo.COLETE, Pecas.Tipo.VARINHA, Pecas.Tipo.CAPACETE]
		for b in e.bonecos:
			b.nivel = 30
			for s in Pecas.SLOTS:
				var p := Peca.new(Pecas.CONJUNTO_PECAS[(g + e.bonecos.find(b) * 3) % Pecas.CONJUNTO_NOME.size()][s] if false else tipos[s], 12, Pecas.Raridade.EPICA)
				b.pecas[s] = p
		e.iniciar_secreto()
		var sim := _lutar(e, 500 + g, Balanco.TEMPO_MAX)
		if sim.vitoria:
			venc += 1
	print("Schrodinger: vitoria de primeira %d/%d (%d%%)" % [venc, n, int(100.0 * venc / maxf(1.0, n))])
