extends SceneTree
## Simulador headless da campanha: mesma lógica de combate (Simulacao), sem desenho.
## Uso: godot --headless --path <projeto> --script res://ferramentas/simulador.gd -- 30 [politica] [v]
## Modo kits: kits=todos|novos|antigos|lista [equipe=1] (equipe: os outros gatos também de fantasia completa).
## Cada campanha joga as fases em ordem; ao perder, tenta de novo (o guarda-roupa fica).

const PRIORIDADE: Array[int] = [
	5, 4, 3, 5, 3, 4, 5, 4, 3, 4, 3, 3, 3, 4, 4,
	3, 3, 4, 4,
	4, 4, 3, 3,
	4, 3, 4, 4,
	2, 4, 3, 2, 5, 2, 4, 4, 3,
]
const TENTATIVAS_MAX := 6   # por fase; depois disso a campanha conta como travada
const A_DISTANCIA: Array[int] = [Pecas.Tipo.ESTILINGUE, Pecas.Tipo.VARINHA, Pecas.Tipo.REGADOR]

var verboso: bool = false
var opcoes: Dictionary = {}   # argumentos "chave=valor" (ate=4, kits=todos, ...)
var ate: int = 9999           # para cada campanha depois desta fase (1..10 na ordem jogada); o resto do relatório sai igual

## Separa os argumentos posicionais dos "chave=valor".
func _argumentos() -> PackedStringArray:
	var pos := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if "=" in a:
			opcoes[a.get_slice("=", 0)] = a.get_slice("=", 1)
		else:
			pos.append(a)
	if opcoes.has("ate"):
		ate = int(opcoes["ate"])
	return pos

func _init() -> void:
	var args: PackedStringArray = _argumentos()
	var n_jogos: int = 30
	if args.size() > 0 and args[0] == "drops":
		_modo_drops(int(args[1]) if args.size() > 1 else 40)
		quit()
		return
	if args.size() > 0:
		n_jogos = int(args[0])
	var politicas: Array[String] = ["veste", "misto", "sacrifica", "fantasia"]
	if args.size() > 1 and args[1] != "todas":
		politicas = [args[1]]
	if opcoes.has("kits"):
		_modo_kits(n_jogos, args[1] if args.size() > 1 and args[1] != "todas" else "veste")
		quit()
		return
	var so_q: bool = args.size() > 2 and args[2] == "q"   # só o primeiro cômodo (medição rápida)
	verboso = args.size() > 2 and not so_q
	Simulacao.medir = true
	for pol in politicas:
		var de_primeira: Array[int] = []   # campanhas que venceram a fase na 1ª tentativa
		var tentativas: Array[int] = []    # soma das tentativas até vencer
		var venceram: Array[int] = []      # campanhas que venceram a fase (em até TENTATIVAS_MAX)
		var jogaram: Array[int] = []       # campanhas que chegaram a jogar a fase
		var onda_derrota: Array = []       # por fase: {onda: vezes} na 1ª tentativa
		for f in Fases.TOTAL * Balanco.ATOS:
			de_primeira.append(0)
			tentativas.append(0)
			venceram.append(0)
			jogaram.append(0)
			onda_derrota.append({})
		var inv_casa: Array[int] = []      # ondas vencidas na invasão sem fim de um cômodo, por campanha que zerou tudo
		var inv_fora: Array[int] = []      # idem, num lugar de fora
		var nivel_fim: Array[float] = []
		var torre_fim: Array[float] = []   # soma dos níveis das 4 melhorias ao fim de cada ato
		var mods_fim: Array[float] = []    # módulos liberados ao fim de cada ato
		for a in Balanco.ATOS:
			nivel_fim.append(0.0)
			torre_fim.append(0.0)
			mods_fim.append(0.0)
		var inv_ruas: Array[int] = []      # idem, nas ruas (cinco gangues misturadas)
		var completas: int = 0
		var pecas_fim: float = 0.0
		var marcas_fim: float = 0.0
		var raras: float = 0.0
		var lendarias: float = 0.0
		for g in range(int(opcoes.get("g0", 0)), int(opcoes.get("g0", 0)) + n_jogos):   # g0=N: começa a numerar as campanhas em N (para rodar em partes, em paralelo)
			var e := Estado.new(1000 + g * 7)
			e.novo_jogo()
			var travou: bool = false
			for fa in range(1, Fases.TOTAL * Balanco.ATOS + 1):
				# nos atos seguintes a ordem é livre; aqui os cômodos são jogados na ordem de sempre
				var ato_sim: int = (fa - 1) / Fases.TOTAL
				var f: int = ((fa - 1) + (g if ato_sim > 0 else 0)) % Fases.TOTAL + 1   # cada campanha começa o ato por um cômodo diferente
				var ia: int = ato_sim * Fases.TOTAL + f - 1   # as contas ficam por cômodo, não pela ordem
				var venceu: bool = false
				jogaram[ia] += 1
				for t in TENTATIVAS_MAX:
					e.iniciar_fase(f)
					var r: Dictionary = _jogar_fase(pol, e, 1000 + g * 7 + f * 101 + t * 977)
					if r["vitoria"]:
						venceu = true
						venceram[ia] += 1
						tentativas[ia] += t + 1
						if t == 0:
							de_primeira[ia] += 1
						break
					elif t == 0:
						onda_derrota[ia][r["onda"]] = onda_derrota[ia].get(r["onda"], 0) + 1
				if not venceu:
					travou = true
					break
				if so_q or fa >= ate:
					break
				if fa % Fases.TOTAL == 0:
					var soma_nv: float = 0.0
					for b in e.bonecos:
						soma_nv += b.nivel
					nivel_fim[(fa - 1) / Fases.TOTAL] += soma_nv / maxf(1.0, e.bonecos.size())
					torre_fim[(fa - 1) / Fases.TOTAL] += e.melhorias[0] + e.melhorias[1] + e.melhorias[2] + e.melhorias[3]
					var nm: int = 0
					for mm in Torre.MODULO_NOME.size():
						if e.modulo_liberado(mm):
							nm += 1
					mods_fim[(fa - 1) / Fases.TOTAL] += nm
			if not travou and not so_q and ate >= Fases.TOTAL * Balanco.ATOS:
				completas += 1
				# invasão sem fim com o time do fim do jogo: um cômodo e um lugar de fora, um por campanha
				inv_casa.append(_jogar_invasao(pol, e, g % Fases.TOTAL + 1, false, 5000 + g))
				inv_fora.append(_jogar_invasao(pol, e, (g + 2) % Fases.TOTAL + 1, true, 7000 + g))
			var todas: Array = e.guarda.duplicate()
			for b in e.bonecos:
				for p in b.pecas:
					if p != null:
						todas.append(p)
			pecas_fim += todas.size()
			for p in todas:
				inv_ruas.append(_jogar_invasao(pol, e, (g + 3) % Fases.TOTAL + 1, false, 9000 + g, true))
				marcas_fim += p.marcas.size()
				if p.raridade == Pecas.Raridade.RARA:
					raras += 1
				elif p.raridade >= Pecas.Raridade.EPICA:
					lendarias += 1
		print("%-9s campanhas completas %d/%d | pecas ao fim %.1f (raras %.1f, lendarias %.1f, marcas %.1f)" % [pol, completas, n_jogos, pecas_fim / n_jogos, raras / n_jogos, lendarias / n_jogos, marcas_fim / n_jogos])
		for fa in Fases.TOTAL * Balanco.ATOS:
			var f: int = fa % Fases.TOTAL
			var ks: Array = onda_derrota[fa].keys()
			ks.sort()
			var dist: String = ""
			for k in ks:
				dist += "onda%d:%d " % [k, onda_derrota[fa][k]]
			print("   ato %d fase %d %-8s de primeira %2d/%2d (%3d%%) | venceram %2d | tentativas medias %.2f | derrotas (1a tentativa): %s" % [fa / Fases.TOTAL + 1, f + 1, Fases.nome_do_lugar(fa), de_primeira[fa], jogaram[fa], int(round(100.0 * de_primeira[fa] / maxf(1.0, jogaram[fa]))), venceram[fa], float(tentativas[fa]) / maxf(1.0, venceram[fa]), dist])
			if f == Fases.TOTAL - 1:
				print("      nivel medio dos gatos ao fim do ato %d: %.1f (entre as campanhas que chegaram)" % [fa / Fases.TOTAL + 1, nivel_fim[fa / Fases.TOTAL] / maxf(1.0, completas if fa / Fases.TOTAL == Balanco.ATOS - 1 else n_jogos)])
				print("      torre ao fim do ato %d: soma dos niveis das melhorias %.1f (de %d), modulos liberados %.1f" % [fa / Fases.TOTAL + 1, torre_fim[fa / Fases.TOTAL] / maxf(1.0, completas if fa / Fases.TOTAL == Balanco.ATOS - 1 else n_jogos), 4 * Torre.MELHORIA_NIVEL_MAX, mods_fim[fa / Fases.TOTAL] / maxf(1.0, completas if fa / Fases.TOTAL == Balanco.ATOS - 1 else n_jogos)])
		print("   invasao sem fim (time do fim do jogo): comodo %s | lugar de fora %s | ruas %s" % [_resumo_inv(inv_casa), _resumo_inv(inv_fora), _resumo_inv(inv_ruas)])
		_imprimir_poderes(n_jogos)
	quit()

## Modo drops (notas/onde_cai_final.md, seção 6, item 2): sem combate, todo fantasiado e todo chefe morre e o comum larga com
## DROP_CHANCE. Por lugar, `n` campanhas com coleção vazia lutam o lugar até completar todas as fantasias dele (máx. 80 lutas).
## Mede peças por luta por origem, % da lista do lugar, lutas até a 1ª fantasia e o lugar inteiro (média, mediana, p95),
## a mediana das lutas da última peça que falta e a taxa da assinatura do chefe. Roda com e sem pity (Simulacao.sem_pity).
func _modo_drops(n: int) -> void:
	for pity in [true, false]:
		Simulacao.sem_pity = not pity
		print("=== drops: %d campanhas por lugar, %s ===" % [n, "COM pity" if pity else "SEM pity"])
		var tot_med: float = 0.0
		for lugar in Fases.TOTAL * Balanco.ATOS:
			var lista: Array = Fases.lista_do_lugar(lugar)
			var ato: int = lugar / Fases.TOTAL + 1
			var f: int = lugar % Fases.TOTAL + 1
			var pecas_lista: Array = []
			for c in lista:
				for tp in Pecas.CONJUNTO_PECAS[c]:
					pecas_lista.append(tp)
			var org: Array = [0, 0, 0]   # comum, fantasiado, chefe
			var da_lista: Array = [0, 0, 0]
			var lutas_total: int = 0
			var ate_uma: Array[int] = []
			var ate_tudo: Array[int] = []
			var ultima: Array[int] = []
			var assin: int = 0
			var lutas_assin: int = 0
			for g in n:
				var e := Estado.new(3000 + g * 13 + lugar * 101)
				e.persistir = false
				e.novo_jogo()
				e.colecao.fill(false)
				var sim := Simulacao.new()
				sim.estado = e
				sim.rng.seed = 9000 + g * 17 + lugar
				var uma: int = -1
				var falta1: int = -1
				var lutas: int = 0
				while lutas < 80:
					e.iniciar_fase(f)
					e.ato = ato
					e._pesos_validos = false
					for w in range(1, Balanco.ONDAS_TOTAIS + 1):
						e.onda = w
						e.preparar_onda()
						if w == Balanco.ONDAS_TOTAIS and not e.chefe.is_empty():
							lutas_assin += 1
							if Pecas.CONJUNTO_DE[e.chefe[0].tipo] == Fases.CHEFE_ASSINATURA[lugar]:
								assin += 1
						var fontes: Array = []
						for it in e.plano:
							var pcs: Array = []
							for pc in it["pecas"]:
								if pc != null:
									pcs.append(pc)
							fontes.append([pcs, 1 if it["elite"] else 0, 0])
						if not e.chefe.is_empty():
							fontes.append([e.chefe.duplicate(), 2, 2])
						for ft in fontes:
							var vest: Array = ft[0]
							if vest.is_empty():
								continue
							var o: int = ft[1]
							if o == 0 and sim.rng.randf() >= Balanco.DROP_CHANCE:
								continue
							for k in mini(vest.size(), 2 if o == 2 else 1):
								var i: int = sim._sortear_peca_vestida(vest, o > 0)
								var tp: int = vest[i].tipo
								vest.remove_at(i)
								org[o] += 1
								if pecas_lista.has(tp):
									da_lista[o] += 1
								e.registrar(tp)
					lutas += 1
					var feitas: int = 0
					var pecas_t: int = 0
					for c in lista:
						var q: int = e.pecas_da_fantasia(c)
						pecas_t += q
						if q >= Pecas.SLOTS:
							feitas += 1
					if uma < 0 and feitas > 0:
						uma = lutas
					if falta1 < 0 and pecas_t >= lista.size() * Pecas.SLOTS - 1:
						falta1 = lutas
					if feitas >= lista.size():
						break
				lutas_total += lutas
				ate_uma.append(uma if uma > 0 else 80)
				ate_tudo.append(lutas)
				ultima.append(lutas - falta1 if falta1 > 0 else 0)
			ate_uma.sort()
			ate_tudo.sort()
			ultima.sort()
			var nl: float = float(lutas_total)
			tot_med += float(lutas_total) / n
			print("%-9s (%d fantasias) pecas/luta comum %.1f fantasiado %.1f chefe %.1f | da lista: comum %.0f%% fant %.0f%% chefe %.0f%% | 1a fantasia: media %.1f p95 %d | lugar inteiro: media %.1f mediana %d p95 %d | ultima peca (mediana) %d | assinatura %.0f%%" % [
				Fases.NOME[lugar], lista.size(), org[0] / nl, org[1] / nl, org[2] / nl,
				100.0 * da_lista[0] / maxf(1.0, org[0]), 100.0 * da_lista[1] / maxf(1.0, org[1]), 100.0 * da_lista[2] / maxf(1.0, org[2]),
				_media(ate_uma), ate_uma[int(n * 0.95)], _media(ate_tudo), ate_tudo[n / 2], ate_tudo[mini(n - 1, int(n * 0.95))],
				ultima[n / 2], 100.0 * assin / maxf(1.0, lutas_assin)])
		print("   soma das medias de lutas (lugares jogados): %.1f" % tot_med)
	Simulacao.sem_pity = false

func _media(a: Array) -> float:
	var t: float = 0.0
	for x in a:
		t += x
	return t / maxf(1.0, a.size())

## Telemetria dos poderes (Simulacao.tele), por fantasia, média por campanha.
func _imprimir_poderes(n_jogos: int) -> void:
	print("   poderes (por campanha): usos | usos de heranca | dano | abates | extras")
	for c in Pecas.CONJUNTO_NOME.size():
		var d: Dictionary = Simulacao.tele.get(c, {})
		var extras: String = ""
		for k in d.keys():
			if not (k in ["usos", "usos_h", "dano", "abates"]):
				extras += " %s %.1f" % [k, float(d[k]) / n_jogos]
		print("     %-16s %-17s usos %6.1f | her %6.1f | dano %8.0f | abates %6.1f |%s" % [Pecas.CONJUNTO_NOME[c], Pecas.PODER_NOME[c], float(d.get("usos", 0.0)) / n_jogos, float(d.get("usos_h", 0.0)) / n_jogos, float(d.get("dano", 0.0)) / n_jogos, float(d.get("abates", 0.0)) / n_jogos, extras])
	print("   poderes dos bichos (por campanha): usos | dano nos gatos | gatos derrubados | extras")
	for c in Pecas.CONJUNTO_NOME.size():
		var di: Dictionary = Simulacao.tele_i.get(c, {})
		if di.is_empty():
			continue
		var ex_i: String = ""
		for k in di.keys():
			if not (k in ["usos", "usos_h", "dano", "abates"]):
				ex_i += " %s %.1f" % [k, float(di[k]) / n_jogos]
		print("     [bicho] %-16s %-17s usos %6.1f | dano %8.0f | derrubados %6.1f |%s" % [Pecas.CONJUNTO_NOME[c], Pecas.PODER_NOME[c], float(di.get("usos", 0.0)) / n_jogos, float(di.get("dano", 0.0)) / n_jogos, float(di.get("abates", 0.0)) / n_jogos, ex_i])
	Simulacao.tele.clear()
	Simulacao.tele_i.clear()

## Ondas de invasão vencidas até a torre cair (limite de 60).
func _jogar_invasao(pol: String, e: Estado, f: int, fora: bool, semente: int, ruas: bool = false) -> int:
	e.iniciar_invasao(f, fora, ruas)
	var vencidas: int = 0
	while vencidas < 60:
		_preparar(pol, e, false)
		var sim := Simulacao.new()
		sim.gerar_eventos = false
		sim.iniciar(e, semente + vencidas * 17)
		while not sim.terminada:
			sim.passo(Balanco.DT)
		if not sim.vitoria:
			e.encerrar_derrota(sim)
			break
		e.encerrar_onda(sim)
		vencidas += 1
	if vencidas >= 60:
		e.recolher()
	return vencidas

func _resumo_inv(v: Array[int]) -> String:
	if v.is_empty():
		return "sem dados"
	var o: Array[int] = v.duplicate()
	o.sort()
	var soma: int = 0
	var d10: int = 0
	var d20: int = 0
	for x in o:
		soma += x
		if x >= 10:
			d10 += 1
		if x >= 20:
			d20 += 1
	return "media %.1f, mediana %d, min %d, max %d, passam de 10: %d/%d, de 20: %d/%d" % [float(soma) / o.size(), o[o.size() / 2], o[0], o[o.size() - 1], d10, o.size(), d20, o.size()]

func _jogar_fase(pol: String, e: Estado, semente: int) -> Dictionary:
	var primeira: bool = true
	while true:
		_preparar(pol, e, primeira)
		primeira = false
		for bh in e.bonecos:
			while bh.incorporar() >= 0:   # no jogo o jogador confirma; aqui incorpora o que estiver vestindo
				pass
		var sim := Simulacao.new()
		sim.gerar_eventos = false
		sim.iniciar(e, semente + e.onda * 13)
		while not sim.terminada:
			sim.passo(Balanco.DT)
		if verboso:
			print("  [", pol, "] fase ", e.fase, " onda ", e.onda, " bonecos ", e.bonecos.size(), " vivos_fim ", sim.aliados.size(), " tijolos ", e.tijolos, " t=", snappedf(sim.tempo, 0.1), " guarda ", e.guarda.size(), " vitoria ", sim.vitoria)
		if not sim.vitoria:
			var onda: int = e.onda
			e.encerrar_derrota(sim)
			return {"vitoria": false, "onda": onda}
		if e.encerrar_onda(sim):
			return {"vitoria": true, "onda": Balanco.ONDAS_TOTAIS}
	return {}

func _preparar(pol: String, e: Estado, _primeira: bool) -> void:
	# torre: gasta troféus em rodízio nas melhorias e monta os módulos liberados (os mais novos primeiro)
	var tentou: int = 0
	while e.trofeus >= Torre.MELHORIA_CUSTO and tentou < 4:
		var soma: int = e.melhorias[0] + e.melhorias[1] + e.melhorias[2] + e.melhorias[3]
		if e.melhorar((soma + tentou) % 4):
			tentou = 0
		else:
			tentou += 1
	for m in range(Torre.MODULO_NOME.size() - 1, -1, -1):
		if e.modulo_liberado(m) and not e.tem_modulo(m) and e.modulos.size() < e.vagas_modulos():
			e.alternar_modulo(m)
	# funde as peças repetidas que estão paradas no guarda-roupa
	var fundiu: bool = true
	while fundiu:
		fundiu = false
		for i in e.guarda.size():
			for j in range(i + 1, e.guarda.size()):
				if e.pode_fundir(e.guarda[i], e.guarda[j]):
					e.fundir(e.guarda[i], e.guarda[j])
					fundiu = true
					break
			if fundiu:
				break
	# treino: gasta os pontos em rodízio (vida, força, agilidade)
	for b in e.bonecos:
		while b.pontos > 0:
			b.treinar((b.atr[0] + b.atr[1] + b.atr[2]) % 3)
	match pol:
		"veste":
			_vestir_melhor(e)
		"sacrifica":
			# o último boneco veste as piores peças e vai à frente, para cair e marcá-las
			_vestir_melhor(e, 1 if e.bonecos.size() >= 2 else 0, 4)
		"fantasia":
			_vestir_fantasias(e)
		"misto":
			_vestir_melhor(e)
			while e.tijolos >= Balanco.custo_promocao(0) + 12:
				var q: Peca = _pior_vestida(e)
				if q == null or not e.promover(q):
					break
	_linhas(e, pol == "sacrifica")

func _pior_vestida(e: Estado) -> Peca:
	var melhor: Peca = null
	for b in e.bonecos:
		for p in b.pecas:
			if p != null and p.nivel < Balanco.NIVEL_MAX:
				if melhor == null or p.nivel < melhor.nivel:
					melhor = p
	return melhor

func _valor(p: Peca, peso_marcas: int) -> int:
	return p.nivel * 10 + p.raridade * 8 + PRIORIDADE[p.molde()] + p.marcas.size() * peso_marcas

## Tira tudo e distribui as melhores peças (por nível, raridade e prioridade) entre os bonecos.
## `sacrificios`: quantos bonecos do fim da fila ficam com as peças de menor valor (para morrer).
## `peso_marcas`: quanto cada marca soma ao valor da peça (0 = ignora marcas).
func _vestir_melhor(e: Estado, sacrificios: int = 0, peso_marcas: int = 0) -> void:
	var todas: Array[Peca] = []
	for b in e.bonecos:
		for s in Pecas.SLOTS:
			if b.pecas[s] != null:
				todas.append(b.pecas[s])
			b.pecas[s] = null
	for p in e.guarda:
		todas.append(p)
	e.guarda.clear()
	for s in Pecas.SLOTS:
		var doslot: Array[Peca] = []
		for p in todas:
			if p.slot() == s:
				doslot.append(p)
		doslot.sort_custom(func(a: Peca, b: Peca) -> bool:
			return _valor(a, peso_marcas) > _valor(b, peso_marcas))
		var fortes: int = e.bonecos.size() - sacrificios
		for i in doslot.size():
			if i < fortes:
				e.bonecos[i].pecas[s] = doslot[i]
		# os sacrifícios levam as últimas da lista (menor valor)
		var fim: int = doslot.size() - 1
		for j in sacrificios:
			if fim >= fortes:
				e.bonecos[fortes + j].pecas[s] = doslot[fim]
				fim -= 1
		for i in range(fortes, fim + 1):
			e.guarda.append(doslot[i])

## Heurística de linha: Escudo/Colete na frente, quem atira no fundo, o resto no meio.
## Na política "sacrifica", o último boneco (o de sacrifício) vai para a frente.
func _linhas(e: Estado, sacrifica: bool) -> void:
	for i in e.bonecos.size():
		var b: Boneco = e.bonecos[i]
		var linha: int = Boneco.Linha.MEIO
		for p in b.pecas:
			if p == null:
				continue
			if p.molde() == Pecas.Tipo.ESCUDO or p.molde() == Pecas.Tipo.COLETE:
				linha = Boneco.Linha.FRENTE
				break
			if p.molde() in A_DISTANCIA:
				linha = Boneco.Linha.FUNDO
		if sacrifica and e.bonecos.size() >= 2 and i == e.bonecos.size() - 1:
			linha = Boneco.Linha.FRENTE
		b.linha = linha

## Jogador que caça fantasia: cada gato veste a fantasia de que há mais peças livres
## (desempate pelo valor), e completa os espaços vazios com as melhores sobras.
func _vestir_fantasias(e: Estado) -> void:
	var livres: Array[Peca] = []
	for b in e.bonecos:
		for s in Pecas.SLOTS:
			if b.pecas[s] != null:
				livres.append(b.pecas[s])
			b.pecas[s] = null
	livres.append_array(e.guarda)
	e.guarda.clear()
	for b in e.bonecos:
		var melhor_c: int = -1
		var melhor_n: int = 0
		var melhor_v: int = -1
		for c in Pecas.CONJUNTO_NOME.size():
			if Pecas.retirada(c):
				continue
			var n: int = 0
			var v: int = 0
			for s in Pecas.SLOTS:
				var p: Peca = _melhor_livre(livres, s, c)
				if p != null:
					n += 1
					v += _valor(p, 0)
			if n > melhor_n or (n == melhor_n and v > melhor_v):
				melhor_c = c
				melhor_n = n
				melhor_v = v
		for s in Pecas.SLOTS:
			var p: Peca = _melhor_livre(livres, s, melhor_c) if melhor_n >= Pecas.CONJUNTO_MIN else null
			if p == null:
				p = _melhor_livre(livres, s, -1)
			if p != null:
				b.pecas[s] = p
				livres.erase(p)
	e.guarda.append_array(livres)

## Melhor peça livre do espaço `s`; com `c` >= 0, só as da fantasia `c`.
func _melhor_livre(livres: Array[Peca], s: int, c: int) -> Peca:
	var melhor: Peca = null
	for p in livres:
		if p.slot() != s or (c >= 0 and p.conjunto() != c):
			continue
		if melhor == null or _valor(p, 0) > _valor(melhor, 0):
			melhor = p
	return melhor

## Modo kits (kits=todos | novos | antigos | lista de índices de Pecas.Conjunto separados por vírgula; campanhas = 1º argumento).
## Cada campanha joga o 1º ato normalmente; depois, com o time do fim do 1º ato, o último gato veste cada fantasia completa
## (nível e raridade médios do time) e luta as MESMAS lutas fixas (invasão lá fora, ondas 2, 4 e 6 em dois lugares,
## mesmas sementes). Sem gravar nada no estado. A linha "sem kit" é a referência (o último gato com as próprias peças).
## Estado que uma luta muda (tijolos da torre; vivo, saúde, marcas e progresso das peças), para o modo kits restaurar entre lutas.
func _foto(e: Estado) -> Array:
	var f: Array = [e.tijolos]
	for b in e.bonecos:
		var ps: Array = []
		for p in b.pecas:
			ps.append(null if p == null else [p, p.nivel, p.abates, p.prog, p.nova, p.marcas.duplicate()])
		f.append([b, b.saude, b.vivo, b.postura, ps])
	return f

func _restaurar(e: Estado, f: Array) -> void:
	e.tijolos = f[0]   # a torre volta inteira: tijolo perdido numa luta não pesa na seguinte
	for fb in f.slice(1):
		var b: Boneco = fb[0]
		b.saude = fb[1]
		b.vivo = fb[2]
		b.postura = fb[3]
		for fp in fb[4]:
			if fp != null:
				var p: Peca = fp[0]
				p.nivel = fp[1]
				p.abates = fp[2]
				p.prog = fp[3]
				p.nova = fp[4]
				p.marcas.assign(fp[5])

func _modo_kits(n_jogos: int, pol: String) -> void:
	Simulacao.medir = true
	var primeiro_novo: int = Pecas.Conjunto.SUPER_MIAU
	var lista: Array[int] = []
	var k: String = str(opcoes["kits"])
	if k == "todos" or k == "novos" or k == "antigos":
		for c in Pecas.CONJUNTO_NOME.size():
			if Pecas.retirada(c):
				continue
			if k == "todos" or (k == "novos") == (c >= primeiro_novo):
				lista.append(c)
	else:
		for t in k.split(","):
			if not Pecas.retirada(int(t)):
				lista.append(int(t))
	var ondas: Array[int] = [2, 4, 6]
	# acumuladores por kit (-1 = sem kit)
	var acc: Dictionary = {}
	for c in lista + [-1]:
		acc[c] = {"lutas": 0, "vitorias": 0, "vivos": 0.0, "tempo": 0.0, "tele": {}}
	for g in n_jogos:
		var e := Estado.new(1000 + g * 7)
		e.novo_jogo()
		var travou: bool = false
		for f in range(1, Fases.TOTAL + 1):
			var venceu: bool = false
			for t in TENTATIVAS_MAX:
				e.iniciar_fase(f)
				if _jogar_fase(pol, e, 1000 + g * 7 + f * 101 + t * 977)["vitoria"]:
					venceu = true
					break
			if not venceu:
				travou = true
				break
		if travou:
			continue
		e.vencido = [2, 2, 2, 2, 2]   # os lugares de fora ficam abertos para a invasão lá fora
		_preparar(pol, e, false)
		var b0: Boneco = e.bonecos[e.bonecos.size() - 1]   # o kit vai no último gato; nível e raridade são a média do time
		var originais: Array = b0.pecas.duplicate()
		var soma_n: float = 0.0
		var soma_r: float = 0.0
		var npc: int = 0
		for bb in e.bonecos:
			for p in bb.pecas:
				if p != null:
					soma_n += p.nivel
					soma_r += p.raridade
					npc += 1
		var nivel: int = int(round(soma_n / maxi(1, npc)))
		var rar: int = int(round(soma_r / maxi(1, npc)))
		if opcoes.has("equipe"):
			# equipe=1: os outros gatos também vestem fantasias completas (parceiras fixas na campanha, variando entre campanhas),
			# para medir poderes de grupo (Canção do tempo, Imitar, auras); a linha "sem kit" é o último gato sem kit nesse time
			var todos_k: Array[int] = []
			for k2 in Pecas.CONJUNTO_NOME.size():
				if not Pecas.retirada(k2):
					todos_k.append(k2)
			for i in e.bonecos.size() - 1:
				var pk: int = todos_k[(g * 5 + i * 11) % todos_k.size()]
				for s in Pecas.SLOTS:
					e.bonecos[i].pecas[s] = Peca.new(Pecas.CONJUNTO_PECAS[pk][s], nivel, rar)
		var base: Array = _foto(e)   # o time antes de qualquer kit: cada kit parte dele
		for c in lista + [-1]:
			_restaurar(e, base)
			for s in Pecas.SLOTS:
				b0.pecas[s] = originais[s] if c < 0 else Peca.new(Pecas.CONJUNTO_PECAS[c][s], nivel, rar)
			_linhas(e, false)
			Simulacao.tele.clear()
			var foto: Array = _foto(e)
			for li in 2:
				for oi in ondas.size():
					_restaurar(e, foto)   # cada luta parte do mesmo time: sem nocaute nem marca herdados do kit anterior
					e.iniciar_invasao((g + li * 2) % Fases.TOTAL + 1, true)
					e.onda_invasao = ondas[oi]
					e.onda = (ondas[oi] - 1) % Balanco.ONDAS_TOTAIS + 1
					e.rng.seed = 50000 + g * 31 + li * 7 + oi   # as mesmas ondas para todos os kits
					e.preparar_onda()
					var sim := Simulacao.new()
					sim.gerar_eventos = false
					sim.iniciar(e, 40000 + g * 31 + li * 7 + oi)
					while not sim.terminada:
						sim.passo(Balanco.DT)
					var a: Dictionary = acc[c]
					if OS.get_environment("DBG") != "":
						print("DBG g%d kit%d li%d oi%d vit %s t %.3f vivos %d" % [g, c, li, oi, sim.vitoria, sim.tempo, sim.aliados.size()])
					a["lutas"] += 1
					a["vitorias"] += 1 if sim.vitoria else 0
					a["vivos"] += sim.aliados.size()
					a["tempo"] += sim.tempo
			var tel: Dictionary = acc[c]["tele"]
			var d: Dictionary = Simulacao.tele.get(c, {}) if c >= 0 else {}
			for kk in d:
				tel[kk] = float(tel.get(kk, 0.0)) + float(d[kk])
		for s in Pecas.SLOTS:
			b0.pecas[s] = originais[s]
	print("kits (%s), %d campanhas, 6 lutas fixas por campanha e kit; último gato veste o kit%s" % [pol, n_jogos, "; os outros vestem fantasias parceiras" if opcoes.has("equipe") else ""])
	print("  %-20s %-22s vitoria%% | vivos | tempo |  usos  |  dano  | abates | extras (por luta)" % ["fantasia", "poder"])
	for c in lista + [-1]:
		var a: Dictionary = acc[c]
		var nl: float = maxf(1.0, a["lutas"])
		var tel: Dictionary = a["tele"]
		var ex: String = ""
		for kk in tel:
			if not (kk in ["usos", "usos_h", "dano", "abates"]):
				ex += " %s %.2f" % [kk, float(tel[kk]) / nl]
		print("  %-20s %-22s %6.1f%% | %5.2f | %5.1f | %6.2f | %7.0f | %6.2f |%s" % [Pecas.CONJUNTO_NOME[c] if c >= 0 else "(sem kit)", Pecas.PODER_NOME[c] if c >= 0 else "-", 100.0 * a["vitorias"] / nl, a["vivos"] / nl, a["tempo"] / nl, float(tel.get("usos", 0.0)) / nl, float(tel.get("dano", 0.0)) / nl, float(tel.get("abates", 0.0)) / nl, ex])
