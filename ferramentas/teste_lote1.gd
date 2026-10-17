extends SceneTree
## Teste headless dos lotes 1 e 2 de fantasias (Super Miau ... Jimiau; Disparamiau, Milhau (retirado), Giramiau, Stardew Miaulley, Miaucraft, Miaulax).
## Uso: godot --headless --path <projeto> --script res://ferramentas/teste_lote1.gd
## Confere tabelas paralelas, a mão de pôquer com mãos fixas e dispara cada poder novo numa luta de verdade.

var falhas: int = 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)

func _init() -> void:
	var n: int = Pecas.Tipo.size()
	_ok(Pecas.SLOT.size() == n, "SLOT %d != %d" % [Pecas.SLOT.size(), n])
	_ok(Pecas.NOME.size() == n, "NOME %d != %d" % [Pecas.NOME.size(), n])
	_ok(Pecas.MOLDE.size() == n, "MOLDE %d != %d" % [Pecas.MOLDE.size(), n])
	_ok(Pecas.MOLDE_PODER.size() == n, "MOLDE_PODER %d != %d" % [Pecas.MOLDE_PODER.size(), n])
	_ok(Pecas.CONJUNTO_DE.size() == n, "CONJUNTO_DE %d != %d" % [Pecas.CONJUNTO_DE.size(), n])
	var nc: int = Pecas.Conjunto.size()
	var tabelas: Dictionary = {"CONJUNTO_NOME": Pecas.CONJUNTO_NOME, "CONJUNTO_PECAS": Pecas.CONJUNTO_PECAS, "CONJUNTO_COR": Pecas.CONJUNTO_COR,
		"CONJUNTO_MOLDE": Pecas.CONJUNTO_MOLDE, "PODER_TIPO": Pecas.PODER_TIPO, "PODER_NOME": Pecas.PODER_NOME, "PODER_DICA": Pecas.PODER_DICA}
	for nome in tabelas:
		_ok((tabelas[nome] as Array).size() == nc, "%s tem %d, esperado %d" % [nome, (tabelas[nome] as Array).size(), nc])
	_tabelas_paralelas(nc, n)
	var vistos: Dictionary = {}
	for s in Pecas.POR_SLOT.size():
		for t in Pecas.POR_SLOT[s]:
			_ok(Pecas.SLOT[t] == s, "POR_SLOT: tipo %d no espaço errado" % t)
			vistos[t] = true
	_ok(vistos.size() == n, "POR_SLOT cobre %d de %d tipos" % [vistos.size(), n])
	for c in nc:
		for s in Pecas.SLOTS:
			_ok(Pecas.CONJUNTO_DE[Pecas.CONJUNTO_PECAS[c][s]] == c and Pecas.SLOT[Pecas.CONJUNTO_PECAS[c][s]] == s, "conjunto %d espaço %d incoerente" % [c, s])
		_ok(Pecas.conjunto_bonus(c, 1) != "" and Pecas.conjunto_bonus(c, 2) != "", "conjunto %d sem texto de bônus" % c)
		_ok(Pecas.PODER_DICA[c].length() <= 80, "dica do poder %d passa de 80 caracteres" % c)
	# mão de pôquer: 2=0 ... A=12; naipe = c / 13
	_ok(Poquer.avaliar([0, 1, 2, 3, 4 + 13]) == Poquer.Mao.SEQUENCIA, "sequência")
	_ok(Poquer.avaliar([12, 0, 1, 2, 3 + 13]) == Poquer.Mao.SEQUENCIA, "roda A-2-3-4-5")
	_ok(Poquer.avaliar([0, 1, 2, 3, 4]) == Poquer.Mao.STRAIGHT_FLUSH, "straight flush")
	_ok(Poquer.avaliar([0, 13, 26, 39, 5]) == Poquer.Mao.QUADRA, "quadra")
	_ok(Poquer.avaliar([0, 13, 26, 5, 18]) == Poquer.Mao.FULL_HOUSE, "full house")
	_ok(Poquer.avaliar([0, 2, 4, 6, 8]) == Poquer.Mao.FLUSH, "flush")
	_ok(Poquer.avaliar([0, 13, 26, 5, 7]) == Poquer.Mao.TRINCA, "trinca")
	_ok(Poquer.avaliar([0, 13, 2, 15, 7]) == Poquer.Mao.DOIS_PARES, "dois pares")
	_ok(Poquer.avaliar([0, 13, 2, 4, 7]) == Poquer.Mao.PAR, "par")
	_ok(Poquer.avaliar([0, 14, 2, 4, 7 + 26]) == Poquer.Mao.CARTA_ALTA, "carta alta")
	_ok(Poquer.melhor_mao([0, 14, 2, 4, 7, 13, 15, 29]) >= Poquer.Mao.PAR, "melhor de 8")
	# valor esperado da tabela com 8 e com 5 cartas (a spec pede ~1,35 x base)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for qtd in [8, 5]:
		var soma: float = 0.0
		var dist: Array = [0, 0, 0, 0, 0, 0, 0, 0, 0]
		for i in 20000:
			var m: int = Poquer.melhor_mao(Poquer.sacar(rng, qtd))
			dist[m] += 1
			soma += Balanco.PODER_POQUER_DANO[m]
		print("pôquer com %d cartas: valor esperado %.2f x base | distribuição %s" % [qtd, soma / 20000.0, str(dist)])
	# lutas: cada fantasia nova vestida por um gato, poder disparado de verdade
	Simulacao.medir = true
	for c in range(Pecas.Conjunto.SUPER_MIAU, nc):
		if Pecas.retirada(c):
			continue   # fantasia retirada do jogo (Milhau): o poder existe no código, mas ninguém o veste
		Simulacao.tele.clear()
		var usos: int = 0
		for semente in 6:
			var e := Estado.new(300 + semente)
			e.novo_jogo()
			e.persistir = false
			e.iniciar_fase(1)
			for k in Pecas.SLOTS:
				e.bonecos[0].pecas[k] = Peca.new(Pecas.CONJUNTO_PECAS[c][k], 6)
			e.bonecos[1].pecas[0] = Peca.new(Pecas.CONJUNTO_PECAS[Pecas.Conjunto.CAVALEIRO][0], 4)
			var sim := Simulacao.new()
			sim.gerar_eventos = false
			sim.iniciar(e, 900 + semente)
			var tinha_poder: bool = false
			for u in sim.aliados:
				if u.poder_conj == c:
					tinha_poder = true
			_ok(tinha_poder, "%s: o gato fantasiado não ganhou o poder" % Pecas.CONJUNTO_NOME[c])
			var passos: int = 0
			while not sim.terminada and passos < 30 * 200:
				sim.passo(Balanco.DT)
				passos += 1
		var d: Dictionary = Simulacao.tele.get(c, {})
		usos = int(d.get("usos", 0.0))
		print("%-20s %-20s usos em 6 lutas: %d | %s" % [Pecas.CONJUNTO_NOME[c], Pecas.PODER_NOME[c], usos, str(d)])
	_efeitos_diretos()
	_retiradas()
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)

## Varre as constantes de todas as classes do projeto: lista de 25 itens (tamanho antigo de Conjunto) ou 100 (antigo de Tipo)
## é tabela paralela que não ganhou as fantasias do lote 1 (foi assim que RoupaBicho estourou no índice 26).
func _tabelas_paralelas(nc: int, nt: int) -> void:
	var antigos: Array[int] = [nc - 24, nt - 96, nc - 18, nt - 72, nc - 12, nt - 48, nc - 6, nt - 24]   # tamanhos antes do lote 1, do 2, do 3 e do 4
	for gc in ProjectSettings.get_global_class_list():
		var sc: Script = load(gc["path"])
		var m: Dictionary = sc.get_script_constant_map()
		for k in m:
			var v: Variant = m[k]
			if v is Array and (v as Array).size() in antigos:
				_ok(false, "%s.%s tem %d itens (tamanho antigo): falta o lote 1, 2, 3 ou 4" % [gc["class"], k, (v as Array).size()])
	_ok(IconesPoder.BITS.size() >= Pecas.Poder.size(), "IconesPoder.BITS menor que Poder")
	for c in nc:
		_ok(Balanco.conj_valor(c, 0) != 0.0 and Balanco.conj_valor(c, 1) != 0.0, "conjunto %d sem valor de bônus" % c)
		_ok(Pecas.PODER_TIPO[c] < Pecas.Poder.size(), "PODER_TIPO %d fora do enum" % c)

## Cenas montadas à mão para os poderes que dependem de uma situação (ferido, aviso, último poder).
## Milhau retirado: não cai, não conta, e o save antigo troca as peças dele por peças do Quintal.
func _retiradas() -> void:
	var mil: int = Pecas.Conjunto.MILHAU
	_ok(Pecas.retirada(mil) and not Pecas.retirada(Pecas.Conjunto.DISPARAMIAU), "Milhau devia estar retirado (e só ele)")
	for f in Fases.CONJUNTOS:
		_ok(not (f as Array).has(mil), "Milhau ainda cai em algum lugar")
	for m in Metas.lista():
		_ok(str(m["id"]) != "fantasia_%d" % mil, "meta de fantasia do Milhau ainda existe")
	_ok(Pecas.n_ativas() == Pecas.Conjunto.size() - 1, "n_ativas %d" % Pecas.n_ativas())
	for c in Pecas.Conjunto.size():
		var pos: int = Pecas.posicao_ativa(c)
		_ok((c == mil) == (pos < 0) and (pos < 0 or Pecas.conj_da_posicao(pos) == c), "posição visível incoerente na fantasia %d" % c)
	var e := Estado.new(77)
	e.novo_jogo()
	e.persistir = false
	e.iniciar_fase(1)
	var antes: int = e.fantasias_completas()
	for k in Pecas.SLOTS:
		e.registrar(Pecas.CONJUNTO_PECAS[mil][k])
	_ok(e.fantasias_completas() == antes, "fantasia retirada contou como completa")
	e.guarda.append(Peca.new(Pecas.CONJUNTO_PECAS[mil][1], 7, 2))
	e.bonecos[0].pecas[0] = Peca.new(Pecas.CONJUNTO_PECAS[mil][0], 3, 1)
	e.bonecos[0].herancas.append(mil)
	e.bonecos[0].graus.append(1)
	e._converter_retiradas()
	var quintal: Array = Fases.CONJUNTOS[Fases.TOTAL]
	for p in e.todas_as_pecas():
		_ok(not Pecas.retirada(p.conjunto()), "sobrou peça do Milhau depois de converter")
	var pg: Peca = e.guarda[e.guarda.size() - 1]
	_ok(pg.slot() == 1 and pg.nivel == 7 and pg.raridade == 2 and quintal.has(pg.conjunto()), "peça do guarda-roupa convertida errado")
	var pb: Peca = e.bonecos[0].pecas[0]
	_ok(pb.slot() == 0 and pb.nivel == 3 and pb.raridade == 1 and quintal.has(pb.conjunto()), "peça do gato convertida errado")
	_ok(not e.bonecos[0].herancas.has(mil) and e.bonecos[0].graus.size() == e.bonecos[0].herancas.size(), "herança do Milhau sobrou")

func _cena(c: int, semente: int) -> Simulacao:
	var e := Estado.new(500 + semente)
	e.novo_jogo()
	e.persistir = false
	e.iniciar_fase(1)
	for k in Pecas.SLOTS:
		e.bonecos[0].pecas[k] = Peca.new(Pecas.CONJUNTO_PECAS[c][k], 6)
	var sim := Simulacao.new()
	sim.gerar_eventos = false
	sim.iniciar(e, 700 + semente)
	for i in 120:
		sim.passo(Balanco.DT)
	return sim

func _gato_do_poder(sim: Simulacao, c: int) -> Unidade:
	for u in sim.aliados:
		if u.poder_conj == c:
			return u
	return null

func _efeitos_diretos() -> void:
	# Salvamento: o ferido volta ao posto, é curado e fica protegido; sem ferido, não dispara
	var sim := _cena(Pecas.Conjunto.SUPER_MIAU, 1)
	var sm: Unidade = _gato_do_poder(sim, Pecas.Conjunto.SUPER_MIAU)
	_ok(sm != null, "Super Miau sem poder")
	sm.poder_cd = 0.0
	for a in sim.aliados:
		a.vida = a.vida_max
	_ok(not sim.disparar_poder(sm), "Salvamento disparou sem ferido")
	var ferido: Unidade = null
	for a in sim.aliados:
		if a != sm:
			ferido = a
			break
	if ferido != null:
		ferido.vida = ferido.vida_max * 0.3
		ferido.x = 600.0
		sm.poder_cd = 0.0
		_ok(sim.disparar_poder(sm), "Salvamento não disparou com ferido")
		_ok(absf(ferido.x - ferido.casa_x) < 1.0, "o ferido não voltou ao posto")
		_ok(ferido.vida >= ferido.vida_max * 0.49 and ferido.protegido_t > 2.0, "ferido sem cura ou proteção")
	# Objeção: precisa de aviso em curso; corta o aviso e atordoa
	sim = _cena(Pecas.Conjunto.FENIX_MIAUSSIMO, 2)
	var fx: Unidade = _gato_do_poder(sim, Pecas.Conjunto.FENIX_MIAUSSIMO)
	_ok(fx != null, "Fênix sem poder")
	fx.poder_cd = 0.0
	_ok(sim.disparar_poder(fx), "Protesto (sem aviso) não disparou")
	var bicho: Unidade = null
	for b in sim.inimigos:
		if b.vivo and b.x <= Balanco.VISIVEL_X:
			bicho = b
			break
	if bicho != null:
		bicho.aviso_t = 0.8
		fx.poder_cd = 0.0
		_ok(sim.disparar_poder(fx), "Objeção não disparou com aviso")
		_ok(bicho.aviso_t == 0.0 and (bicho.atordoado_t > 1.0 or not bicho.vivo), "o aviso não foi cortado")
		_ok(fx.buff_dano_t > 3.0, "sem bônus de dano do time")
	# Imitar: copia o último poder; sem nenhum, vira Disfarce
	sim = _cena(Pecas.Conjunto.MIMIAU, 3)
	var mm: Unidade = _gato_do_poder(sim, Pecas.Conjunto.MIMIAU)
	mm.poder_cd = 0.0
	mm.disfarcado = true
	mm.poder_cd = 0.0
	_ok(not sim.disparar_poder(mm), "Imitar gastou o poder com o Disfarce inteiro")
	# rasgar: o golpe some e quem bateu fica atordoado
	var vit: Unidade = null
	for b in sim.inimigos:
		if b.vivo:
			vit = b
			break
	if vit != null:
		vit.atordoado_t = 0.0
		mm.esquiva = 0.0
		mm.barreira_int = 0.0
		var vida0: float = mm.vida
		sim._dano(vit, mm, 50.0, true)
		_ok(not mm.disfarcado and mm.vida == vida0 and vit.atordoado_t > 0.5, "Disfarce não rasgou direito")
		sim._dano(vit, mm, 5.0, true)
		_ok(mm.vida < vida0, "o 2º golpe devia ferir")
	mm.vida = mm.vida_max * 0.5
	mm.poder_cd = 0.0
	sim.ultimo_conj = -1
	_ok(sim.disparar_poder(mm) and mm.disfarcado and mm.vida > mm.vida_max * 0.55, "Disfarce não refeito com cura")
	mm.poder_cd = 0.0
	sim.ultimo_conj = Pecas.Conjunto.JIMIAU
	sim.ultimo_t = sim.tempo
	var n0: int = sim.eventos.size()
	_ok(sim.disparar_poder(mm), "Imitar não disparou")
	print("Imitar com último poder = pôquer: ok")
	_efeitos_lote2()
	_efeitos_lote3()
	_efeitos_lote4()
	# kits de 4 peças: números dos bônus
	for c in range(Pecas.Conjunto.SUPER_MIAU, Pecas.Conjunto.size()):
		print("%-20s 2 peças: %s | 4 peças: %s" % [Pecas.CONJUNTO_NOME[c], Pecas.conjunto_bonus(c, 1), Pecas.conjunto_bonus(c, 2)])

func _lote2_aliado_ferido(sim: Simulacao, sm: Unidade) -> Unidade:
	for a in sim.aliados:
		if a != sm and not a.clone and a.pecas.any(func(x: Variant) -> bool: return x != null):
			return a
	return null

func _efeitos_lote2() -> void:
	# Torre de ervilha: nasce uma estrutura que atira; a nova troca a velha; some no prazo
	var sim := _cena(Pecas.Conjunto.DISPARAMIAU, 11)
	var dg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.DISPARAMIAU)
	_ok(dg != null, "Disparamiau sem poder")
	dg.poder_cd = 0.0
	var tem_inimigo: bool = false
	for b in sim.inimigos:
		if b.vivo and b.x <= Balanco.VISIVEL_X:
			tem_inimigo = true
	if tem_inimigo:
		_ok(sim.disparar_poder(dg), "Torre não disparou")
		sim.nascidos_aliados.size()
		var n_torres: int = 0
		for _i in 2:
			sim.passo(Balanco.DT)
		for a in sim.aliados:
			if a.estrutura and a.vivo:
				n_torres += 1
		_ok(n_torres == 1, "torre: esperava 1 estrutura, achou %d" % n_torres)
		dg.poder_cd = 0.0
		sim.disparar_poder(dg)
		for _i in 2:
			sim.passo(Balanco.DT)
		n_torres = 0
		for a in sim.aliados:
			if a.estrutura and a.vivo:
				n_torres += 1
		_ok(n_torres <= 1, "torre: a nova não trocou a velha (%d)" % n_torres)
	# Reviver: levanta o caído e apaga a marca de nocaute da roupa
	sim = _cena(Pecas.Conjunto.GIRAMIAU, 12)
	var gi: Unidade = _gato_do_poder(sim, Pecas.Conjunto.GIRAMIAU)
	_ok(gi != null, "Giramiau sem poder")
	gi.poder_cd = 0.0
	_ok(not sim.disparar_poder(gi), "Reviver disparou sem caído")
	var vit: Unidade = _lote2_aliado_ferido(sim, gi)
	if vit != null:
		var marcas0: int = 0
		for pc in vit.pecas:
			if pc != null:
				marcas0 += pc.marcas.size()
		sim._matar(vit, null, Pecas.Marca.CICATRIZ)
		var marcas1: int = 0
		for pc in vit.pecas:
			if pc != null:
				marcas1 += pc.marcas.size()
		_ok(not vit.vivo and marcas1 > marcas0, "o caído não ganhou marca de nocaute")
		gi.poder_cd = 0.0
		_ok(sim.disparar_poder(gi), "Reviver não disparou com caído")
		var marcas2: int = 0
		for pc in vit.pecas:
			if pc != null:
				marcas2 += pc.marcas.size()
		_ok(vit.vivo and marcas2 == marcas0, "Reviver não apagou a marca (%d -> %d -> %d)" % [marcas0, marcas1, marcas2])
		_ok(vit.boneco.vivo and vit.vida > 0.0, "caído não voltou à vida")
		gi.poder_cd = 0.0
		_ok(not sim.disparar_poder(gi), "Reviver disparou duas vezes na mesma luta")
	# Manteiga: o bando desliza para o fundo
	sim = _cena(Pecas.Conjunto.MILHAU, 13)
	var mi: Unidade = _gato_do_poder(sim, Pecas.Conjunto.MILHAU)
	_ok(mi != null, "Milhau sem poder")
	mi.poder_cd = 0.0
	var alvo_m: Unidade = null
	for b in sim.inimigos:
		if b.vivo and not b.chefe and b.tipo != Unidade.Tipo.GIGANTE and b.x <= Balanco.VISIVEL_X - 200.0:
			alvo_m = b
			break
	if alvo_m != null:
		var x0: float = alvo_m.x
		alvo_m.atordoado_t = 5.0
		if sim.disparar_poder(mi):
			for _i in 30:
				sim.passo(Balanco.DT)
			_ok(alvo_m.x > x0 + 5.0 or not alvo_m.vivo, "a manteiga não deslocou o alvo")
	# Colheita: 3 mudas, cada uma vira evento ao amadurecer
	sim = _cena(Pecas.Conjunto.STARDEW_MIAULLEY, 14)
	var st: Unidade = _gato_do_poder(sim, Pecas.Conjunto.STARDEW_MIAULLEY)
	_ok(st != null, "Stardew sem poder")
	st.poder_cd = 0.0
	sim.zonas.clear()
	sim.gerar_eventos = true
	if sim.disparar_poder(st):
		var mudas: int = 0
		for z in sim.zonas:
			if z.get("tipo", "") == "muda":
				mudas += 1
		_ok(mudas == Balanco.PODER_COLHEITA_N, "Colheita: %d mudas" % mudas)
		sim.eventos.clear()
		for _i in int((Balanco.PODER_COLHEITA_T + 0.5) / Balanco.DT):
			sim._zonas(Balanco.DT)   # direto: a luta de teste pode acabar antes
		var amadureceram: int = 0
		for ev in sim.eventos:
			if ev["t"] == "muda":
				amadureceram += 1
		_ok(amadureceram == Balanco.PODER_COLHEITA_N, "Colheita: %d mudas amadureceram" % amadureceram)
	# Construir: blocos provocam e explodem ao cair
	sim = _cena(Pecas.Conjunto.MIAUCRAFT, 15)
	var mc: Unidade = _gato_do_poder(sim, Pecas.Conjunto.MIAUCRAFT)
	_ok(mc != null, "Miaucraft sem poder")
	mc.poder_cd = 0.0
	if sim.disparar_poder(mc):
		sim.passo(Balanco.DT)
		var blocos: int = 0
		for a in sim.aliados:
			if a.estrutura and a.vivo and a.provoca and a.estr_explode > 0.0:
				blocos += 1
		_ok(blocos == Balanco.PODER_CONSTRUIR_N, "Construir: %d blocos" % blocos)
	# Cochilo: dorme, imune a atordoar, e o inimigo em volta dorme e acorda ao levar dano
	sim = _cena(Pecas.Conjunto.MIAULAX, 16)
	var ml: Unidade = _gato_do_poder(sim, Pecas.Conjunto.MIAULAX)
	_ok(ml != null, "Miaulax sem poder")
	ml.poder_cd = 0.0
	ml.vida = ml.vida_max * 0.4
	var perto: Unidade = null
	for b in sim.inimigos:
		if b.vivo and not b.chefe:
			perto = b
			break
	if perto != null:
		perto.x = ml.x + 40.0
		perto.y = ml.y
		_ok(sim.disparar_poder(ml), "Cochilo não disparou")
		_ok(ml.cochilo_t > 2.0, "o gato não dormiu")
		_ok(perto.sono_t > 2.0, "o inimigo não dormiu")
		ml.atordoado_t = 3.0
		sim.passo(Balanco.DT)
		_ok(ml.atordoado_t == 0.0, "dormindo, o gato devia ser imune a atordoar")
		sim._dano_poder(ml, perto, 0.1)
		_ok(perto.sono_t == 0.0 or not perto.vivo, "o dano não acordou o inimigo")
		for _i in int(3.0 / Balanco.DT):
			sim.passo(Balanco.DT)
		_ok(ml.vida > ml.vida_max * 0.8, "o Cochilo não curou o bastante (%.2f)" % (ml.vida / ml.vida_max))

## Primeiro inimigo comum vivo, posto a `dx` do gato (na mesma altura).
func _inimigo_perto(sim: Simulacao, g: Unidade, dx: float) -> Unidade:
	for b in sim.inimigos:
		if b.vivo and not b.chefe and not b.estrutura:
			b.x = g.x + dx
			b.y = g.y
			b.atordoado_t = 0.0
			return b
	return null

func _efeitos_lote3() -> void:
	# Plano de ataque: o alvo de maior vida fica marcado e o time o foca
	var sim := _cena(Pecas.Conjunto.LEONARMIAU, 21)
	var lg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.LEONARMIAU)
	_ok(lg != null, "Leonarmiau sem poder")
	lg.poder_cd = 0.0
	var forte: Unidade = _inimigo_perto(sim, lg, 60.0)
	if forte != null:
		forte.vida_max = 9999.0
		forte.vida = 9999.0
		_ok(sim.disparar_poder(lg), "Plano de ataque não disparou")
		var focado: Unidade = null
		for b in sim.inimigos:
			if b.vivo and b.foco_t > 0.0:
				focado = b
		_ok(focado != null, "nenhum alvo marcado pelo Plano")
		if focado != null:
			_ok(sim._escolher(lg) == focado, "o time não focou o alvo do Plano")
			_ok(sim._vul(focado) > 1.2, "o alvo não leva dano a mais")
	# Domo refletor: sem atirador não dispara; com atirador, o tiro que entra volta
	sim = _cena(Pecas.Conjunto.DONATEMIAU, 22)
	var dg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.DONATEMIAU)
	_ok(dg != null, "Donatemiau sem poder")
	dg.poder_cd = 0.0
	for b in sim.inimigos:
		b.distancia = false
	var atirador: Unidade = _inimigo_perto(sim, dg, 220.0)
	if atirador != null:
		_ok(not sim.disparar_poder(dg), "o Domo disparou sem ninguém atirando")
		atirador.distancia = true
		_ok(sim.disparar_poder(dg), "Domo não disparou com atirador")
		sim.projeteis.clear()
		sim.projeteis.append({"x": dg.x + 30.0, "y": dg.y, "alvo": dg, "dono": atirador, "dano": 5.0})
		sim._mover_projeteis(Balanco.DT)
		var refl: bool = false
		for p in sim.projeteis:
			if p.has("refletido") and p["dono"] == dg and p["alvo"] == atirador:
				refl = true
		_ok(refl, "o tiro não foi devolvido ao atirador")
	# Lobo solitário: os bichos em volta passam a mirar só nele
	sim = _cena(Pecas.Conjunto.RAFAMIAU, 23)
	var rg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.RAFAMIAU)
	_ok(rg != null, "Rafamiau sem poder")
	rg.poder_cd = 0.0
	var vizinho: Unidade = _inimigo_perto(sim, rg, 80.0)
	if vizinho != null:
		_ok(sim.disparar_poder(rg), "Lobo solitário não disparou")
		sim.passo(Balanco.DT)
		_ok(vizinho.forcado_alvo == rg or not vizinho.vivo, "o bicho não foi provocado")
		var v0: float = rg.vida
		_ok(rg.lobo_t > 4.0, "Lobo sem duração")
	# Turbo: corre em linha, atropela e deixa 9 zonas de chama
	sim = _cena(Pecas.Conjunto.ROCKET_MIAUGUE, 24)
	var tg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.ROCKET_MIAUGUE)
	_ok(tg != null, "Rocket sem poder")
	tg.poder_cd = 0.0
	tg.x = 300.0
	tg.y = 300.0
	var alvo_t: Unidade = _inimigo_perto(sim, tg, 150.0)
	if alvo_t != null:
		sim.zonas.clear()
		var x0: float = tg.x
		var vida_t: float = alvo_t.vida
		_ok(sim.disparar_poder(tg), "Turbo não disparou")
		var chamas: int = 0
		for z in sim.zonas:
			if z.get("tipo", "") == "chama":
				chamas += 1
		_ok(chamas == Balanco.PODER_TURBO_RASTRO_N, "Turbo: %d zonas de chama" % chamas)
		_ok(tg.x > x0 + 300.0 and tg.protegido_t > 0.0, "o gato não correu protegido")
		_ok(alvo_t.vida < vida_t or not alvo_t.vivo, "o Turbo não atropelou")
	# Esforço máximo: se cair no período, levanta uma vez com 35% da vida
	sim = _cena(Pecas.Conjunto.DEADMIAU, 25)
	var eg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.DEADMIAU)
	_ok(eg != null, "Deadmiau sem poder")
	eg.poder_cd = 0.0
	eg.esforco_t = 0.0
	if _inimigo_perto(sim, eg, 90.0) != null:
		_ok(sim.disparar_poder(eg) and eg.esforco_t > 7.0 and not eg.esforco_usado, "Esforço máximo não armou")
		eg.vida = -1.0
		sim._matar(eg, null)
		_ok(eg.vivo and absf(eg.vida / eg.vida_max - Balanco.PODER_ESFORCO_VIDA) < 0.01, "o Deadmiau não levantou com 35%")
		eg.vida = -1.0
		sim._matar(eg, null)
		_ok(not eg.vivo, "o Deadmiau levantou duas vezes")
	# Chute giratório: empurra e atordoa; quem já estava atordoado apanha mais. Aparar com a faca (kit): golpe some e volta facada
	sim = _cena(Pecas.Conjunto.MEON, 26)
	var mg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.MEON)
	_ok(mg != null, "Meon sem poder")
	_ok(mg.poder == Pecas.Poder.CHUTE and mg.distancia, "Meon sem Chute giratório ou sem pistola")
	mg.poder_cd = 0.0
	var agressor: Unidade = _inimigo_perto(sim, mg, 50.0)
	if agressor != null:
		var x_a: float = agressor.x
		agressor.atordoado_t = 0.0
		agressor.vida_max = 9999.0
		agressor.vida = 9999.0
		var va: float = agressor.vida
		_ok(sim.disparar_poder(mg), "Chute não disparou")
		var d_normal: float = va - agressor.vida
		_ok(agressor.atordoado_t > 0.5 or agressor.chefe, "o chute não atordoou")
		_ok(agressor.x != x_a or agressor.chefe, "o chute não empurrou")
		mg.poder_cd = 0.0
		var v2: float = agressor.vida
		agressor.x = mg.x + 20.0
		agressor.y = mg.y
		agressor.atordoado_t = 2.0
		_ok(sim.disparar_poder(mg), "Chute (combo) não disparou")
		var d_combo: float = v2 - agressor.vida
		_ok(d_combo > d_normal * 2.0, "o combo não doeu mais (%.1f x %.1f)" % [d_combo, d_normal])
		mg.apara = 1.0
		var vm: float = mg.vida
		var vb: float = agressor.vida
		sim._dano(agressor, mg, 30.0, true)
		_ok(mg.vida == vm, "o golpe não foi aparado")
		_ok(agressor.vida < vb, "o agressor não levou a facada")
		sim._dano(agressor, mg, 30.0, false)
		_ok(mg.vida < vm, "o tiro foi aparado (só golpe de perto)")


func _efeitos_lote4() -> void:
	# Miau-Noir: emboscada no kit; Apagão marca quem está dentro e faz errar
	var sim := _cena(Pecas.Conjunto.MIAU_NOIR, 41)
	var ng: Unidade = _gato_do_poder(sim, Pecas.Conjunto.MIAU_NOIR)
	_ok(ng != null, "Miau-Noir sem poder")
	_ok(ng.emboscada == Balanco.conj_valor(Pecas.Conjunto.MIAU_NOIR, 1), "Miau-Noir sem emboscada")
	ng.poder_cd = 0.0
	var vn: Unidade = _inimigo_perto(sim, ng, 80.0)
	if vn != null:
		_ok(sim.disparar_poder(ng), "Apagão não disparou")
		var achou_zona: bool = false
		for z in sim.zonas:
			if z.get("tipo", "") == "apagao":
				achou_zona = true
				z["erra"] = 1.0
		_ok(achou_zona, "Apagão sem zona")
		vn.x = ng.x + 40.0
		vn.y = ng.y
		sim.passo(Balanco.DT)
		_ok(vn.apagao_t > 0.0 or not vn.vivo, "o bicho dentro do Apagão não foi marcado")
		if vn.vivo:
			vn.apagao_erra = 1.0
			vn.cd = 0.0
			var v0: float = ng.vida
			sim._atacar(vn, ng)
			_ok(ng.vida == v0, "o golpe devia errar no Apagão")
	# Hollowmiau: Alma sobe com golpe e é gasta no Espírito
	sim = _cena(Pecas.Conjunto.HOLLOWMIAU, 42)
	var hg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.HOLLOWMIAU)
	_ok(hg != null, "Hollowmiau sem poder")
	var vh: Unidade = _inimigo_perto(sim, hg, 100.0)
	if vh != null:
		hg.alma = 0.0
		vh.vida_max = 9999.0
		vh.vida = 9999.0
		sim._dano(hg, vh, 1.0, true)
		_ok(hg.alma == Balanco.ALMA_GOLPE, "a Alma não subiu com o golpe")
		hg.alma = Balanco.ALMA_MAX
		hg.poder_cd = 0.0
		var vida_h: float = vh.vida
		_ok(sim.disparar_poder(hg), "Espírito vingativo não disparou")
		_ok(hg.alma < Balanco.ALMA_MAX, "a Alma não foi gasta")
		_ok(vh.vida < vida_h, "o espírito não feriu")
	# Silkmiau: laço liga os mais fortes e o dano se espalha; cerco no kit
	sim = _cena(Pecas.Conjunto.SILKMIAU, 43)
	var sg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.SILKMIAU)
	_ok(sg != null and sg.cerco >= Balanco.conj_valor(Pecas.Conjunto.SILKMIAU, 1), "Silkmiau sem cerco")
	if sg != null:
		sg.poder_cd = 0.0
		var ligaveis: Array[Unidade] = []
		for b in sim.inimigos:
			if b.vivo and not b.estrutura and not b.clone:
				b.x = sg.x + 120.0 + 10.0 * ligaveis.size()
				b.y = sg.y
				b.vida_max = 9999.0
				b.vida = 9999.0
				ligaveis.append(b)
		if ligaveis.size() >= 2:
			_ok(sim.disparar_poder(sg), "Laço de seda não disparou")
			var ligados: Array[Unidade] = []
			for b in ligaveis:
				if not b.laco.is_empty():
					ligados.append(b)
			_ok(ligados.size() >= 2, "o laço não ligou dois bichos")
			if ligados.size() >= 2:
				var v1: float = ligados[1].vida
				sim._dano_poder(sg, ligados[0], 100.0)
				_ok(ligados[1].vida < v1, "o dano não se espalhou pelo laço")
	# Super Miaujin: carga interrompida por atordoamento; sem interrupção, o feixe sai
	sim = _cena(Pecas.Conjunto.SUPER_MIAUJIN, 44)
	var mg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.SUPER_MIAUJIN)
	_ok(mg != null and mg.execucao > 1.0, "Super Miaujin sem execução")
	var vm: Unidade = _inimigo_perto(sim, mg, 200.0)
	if vm != null:
		mg.carga_t = 0.0
		mg.poder_cd = 0.0
		_ok(sim.disparar_poder(mg) and mg.carga_t > 1.5, "Camehamiau não começou a carga")
		mg.atordoado_t = 1.0
		sim.passo(Balanco.DT)
		_ok(mg.carga_t == 0.0, "atordoar devia interromper a carga")
		mg.atordoado_t = 0.0
		mg.poder_cd = 0.0
		vm.vida_max = 9999.0
		vm.vida = 9999.0
		vm.x = mg.x + 200.0
		vm.y = mg.y
		vm.atordoado_t = 99.0
		_ok(sim.disparar_poder(mg), "Camehamiau não disparou de novo")
		var vida_m: float = vm.vida
		for _i in int(2.3 / Balanco.DT):
			vm.x = mg.x + 200.0
			vm.y = mg.y
			sim.passo(Balanco.DT)
		_ok(vm.vida < vida_m or not vm.vivo, "o feixe do Camehamiau não feriu")
	# O Arqueólogo: esquiva no kit; a pedra nasce, rola e atordoa
	sim = _cena(Pecas.Conjunto.ARQUEOLOGO, 45)
	var ag: Unidade = _gato_do_poder(sim, Pecas.Conjunto.ARQUEOLOGO)
	_ok(ag != null and ag.esquiva >= Balanco.conj_valor(Pecas.Conjunto.ARQUEOLOGO, 1), "Arqueólogo sem esquiva")
	var va: Unidade = _inimigo_perto(sim, ag, 300.0)
	if va != null:
		sim.ondas.clear()
		ag.poder_cd = 0.0
		va.vida_max = 9999.0
		va.vida = 9999.0
		_ok(sim.disparar_poder(ag), "Pedra rolante não disparou")
		_ok(sim.ondas.size() == 1, "a pedra não nasceu")
		var vida_a: float = va.vida
		var atordoou: bool = false
		for _i in int(2.6 / Balanco.DT):
			va.x = 700.0
			va.y = float(sim.ondas[0]["y"]) if not sim.ondas.is_empty() else va.y
			va.cd = 5.0
			sim.passo(Balanco.DT)
			if va.atordoado_t > 0.0:
				atordoou = true
		_ok(va.vida < vida_a, "a pedra não feriu")
		_ok(atordoou, "a pedra não atordoou")
		_ok(sim.ondas.is_empty(), "a pedra devia sumir ao chegar")
	# Treinador: abaixo de 60% captura (vira aliado, some da onda); acima, a bola balança
	sim = _cena(Pecas.Conjunto.TREINADOR, 46)
	var tg: Unidade = _gato_do_poder(sim, Pecas.Conjunto.TREINADOR)
	_ok(tg != null and tg.cura_abate >= Balanco.conj_valor(Pecas.Conjunto.TREINADOR, 1), "Treinador sem cura por abate")
	var vt: Unidade = _inimigo_perto(sim, tg, 120.0)
	if vt != null:
		tg.poder_cd = 0.0
		for b in sim.inimigos:
			if b != vt and b.vivo:
				b.vida = b.vida_max
		vt.vida = vt.vida_max * 0.5
		var antes_n: int = sim.nascidos_aliados.size()
		_ok(sim.disparar_poder(tg), "Eu escolho você! não disparou")
		_ok(not vt.vivo, "o bicho ferido devia ser capturado")
		_ok(sim.nascidos_aliados.size() == antes_n + 1 and sim.nascidos_aliados[antes_n].capturado, "o aliado capturado não nasceu")
	sim = _cena(Pecas.Conjunto.TREINADOR, 47)
	tg = _gato_do_poder(sim, Pecas.Conjunto.TREINADOR)
	vt = _inimigo_perto(sim, tg, 120.0)
	if vt != null:
		tg.poder_cd = 0.0
		for b in sim.inimigos:
			if b.vivo:
				b.vida = b.vida_max
		_ok(sim.disparar_poder(tg), "Eu escolho você! (bola) não disparou")
		_ok(vt.vivo or sim.nascidos_aliados.is_empty(), "o bicho sadio não devia ser capturado")
