extends SceneTree
## Teste headless dos lotes 1 e 2 de fantasias (Super Miau ... Jimiau; Disparamiau, Milhau, Giramiau, Stardew Miaulley, Miaucraft, Miaulax).
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
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)

## Varre as constantes de todas as classes do projeto: lista de 25 itens (tamanho antigo de Conjunto) ou 100 (antigo de Tipo)
## é tabela paralela que não ganhou as fantasias do lote 1 (foi assim que RoupaBicho estourou no índice 26).
func _tabelas_paralelas(nc: int, nt: int) -> void:
	var antigos: Array[int] = [nc - 12, nt - 48, nc - 6, nt - 24]   # tamanhos antes do lote 1 e antes do lote 2
	for gc in ProjectSettings.get_global_class_list():
		var sc: Script = load(gc["path"])
		var m: Dictionary = sc.get_script_constant_map()
		for k in m:
			var v: Variant = m[k]
			if v is Array and (v as Array).size() in antigos:
				_ok(false, "%s.%s tem %d itens (tamanho antigo): falta o lote 1 ou 2" % [gc["class"], k, (v as Array).size()])
	_ok(IconesPoder.BITS.size() >= Pecas.Poder.size(), "IconesPoder.BITS menor que Poder")
	for c in nc:
		_ok(Balanco.conj_valor(c, 0) != 0.0 and Balanco.conj_valor(c, 1) != 0.0, "conjunto %d sem valor de bônus" % c)
		_ok(Pecas.PODER_TIPO[c] < Pecas.Poder.size(), "PODER_TIPO %d fora do enum" % c)

## Cenas montadas à mão para os poderes que dependem de uma situação (ferido, aviso, último poder).
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
