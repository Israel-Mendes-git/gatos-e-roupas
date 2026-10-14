class_name Simulacao
extends RefCounted
## Lógica de combate pura (sem desenho). Usada pelo jogo e pelo simulador headless.

var estado: Estado
var aliados: Array[Unidade] = []
var inimigos: Array[Unidade] = []
var fila: Array = []
var nascidos: Array[Unidade] = []
var nascidos_aliados: Array[Unidade] = []   # clones dos gatos: entram fora dos laços
var zonas: Array = []   # nuvens do Enxame: {x, y, t, dur, raio, dps, dono, eq}
var projeteis: Array = []
var eventos: Array = []
var bau: Array[Peca] = []
var tempo: float = 0.0
var rng := RandomNumberGenerator.new()
var terminada: bool = false
var vitoria: bool = false
var gerar_eventos: bool = true
var torre_cd: float = 1.0
## true: os poderes dos gatos esperam o jogador (disparar_poder); false: saem sozinhos. Os bichos sempre saem sozinhos.
var poder_manual: bool = false
var catapulta_cd: float = Torre.CATAPULTA_INTERVALO
var caldeirao_cd: float = Torre.CALDEIRAO_INTERVALO
var sirene_usada: bool = false
## Alvo prioritário do time, escolhido na preparação: -1 nenhum, 0..4 um Unidade.Tipo, ou PRIO_ELITE / PRIO_CHEFE.
const PRIO_ELITE := 10
const PRIO_CHEFE := 11
var prioridade: int = -1
var em_heranca: bool = false   # o poder em disparo é uma herança (cura, proteção e frenesi saem reduzidos)
var heranca_grau: int = 1      # grau da herança em disparo

func iniciar(e: Estado, semente: int = 0) -> void:
	estado = e
	if semente == 0:
		rng.randomize()
	else:
		rng.seed = semente
	var n: int = e.bonecos.size()
	var cura: float = e.cura_atual()
	var na_linha: Array[int] = [0, 0, 0]
	for i in n:
		var b: Boneco = e.bonecos[i]
		b.saude = minf(1.0, b.saude + cura)  # a torre cura na hora de sair para a luta
		var u := Unidade.new()
		u.equipe = 0
		u.boneco = b
		u.pecas = b.pecas.duplicate()
		u.linha = b.linha
		u.postura = b.postura_atual()
		u.herancas = b.herancas.duplicate()
		u.heranca_graus = b.graus.duplicate()
		u.atr = b.atr.duplicate()
		# saem correndo da torre para o posto: o da linha ou o que o jogador escolheu na preparação
		var desvio: float = rng.randf_range(0.0, 25.0)
		u.y = lerpf(Balanco.CHAO_Y0 + 15.0, Balanco.CHAO_Y1 - 15.0, (i + 0.5) / n)
		if b.posto.x >= 0.0:
			u.casa_x = b.posto.x
			u.y = b.posto.y
		else:
			# colegas de linha alternam um passo para frente e para trás (não ficam um em cima do outro)
			u.casa_x = Balanco.LINHA_X[b.linha] + desvio + (Balanco.LINHA_ALTERNA if na_linha[b.linha] % 2 == 1 else 0.0)
			na_linha[b.linha] += 1
		u.casa_y = u.y
		if u.postura == Boneco.Postura.RECUAR:
			u.casa_x = Balanco.RECUAR_X
		u.x = Balanco.TORRE_X + 10.0
		calcular(u)
		u.vida = u.vida_max * (b.saude if Balanco.FERIDA_PERSISTE else 1.0)
		aliados.append(u)
	var t: float = Balanco.SPAWN_INICIO
	for spec in e.plano:
		t += rng.randf_range(Balanco.SPAWN_MIN, Balanco.SPAWN_MAX)
		fila.append({"t": t, "pecas": spec["pecas"], "tipo": spec["tipo"], "elite": spec.get("elite", false)})
	if not e.chefe.is_empty():
		fila.append({"t": t + Balanco.CHEFE_ATRASO, "pecas": e.chefe, "tipo": Unidade.Tipo.COMUM, "chefe": true})

## Posto do gato sem contar a postura Recuar (que o segura junto da torre).
func posto_de(u: Unidade) -> Vector2:
	var b: Boneco = u.boneco
	if b != null and b.posto.x >= 0.0:
		return b.posto
	return Vector2(u.casa_x if u.postura != Boneco.Postura.RECUAR else Balanco.LINHA_X[u.linha], u.casa_y)

## O jogador largou o gato em (x, y) na preparação: vira o posto dele, e a linha sai da posição.
func definir_posto(u: Unidade, x: float, y: float) -> void:
	var p := Vector2(clampf(x, Balanco.POSTO_X0, Balanco.POSTO_X1), clampf(y, Balanco.POSTO_Y0, Balanco.POSTO_Y1))
	var b: Boneco = u.boneco
	u.linha = Boneco.linha_de_x(p.x)
	if b != null:
		b.posto = p
		b.linha = u.linha
		if b.postura == Boneco.Postura.RECUAR:
			b.postura = Boneco.Postura.SEGURAR   # arrastar tira o gato de junto da torre
		u.postura = b.postura_atual()
	elif u.postura == Boneco.Postura.RECUAR:
		u.postura = Boneco.Postura.SEGURAR
	u.casa_x = p.x
	u.casa_y = p.y

## Ordem de postura (Boneco.Postura) para um gato; fica gravada no boneco para as próximas ondas.
func definir_postura(u: Unidade, p: int) -> void:
	var posto: Vector2 = posto_de(u)
	u.postura = p
	if u.boneco != null:
		u.boneco.postura = p
	u.casa_x = Balanco.RECUAR_X if p == Boneco.Postura.RECUAR else posto.x
	u.casa_y = posto.y

## Código de prioridade (ver `prioridade`) de um item da fila ou de um bicho já em campo.
static func prio_de(tipo: int, elite: bool, chefe: bool) -> int:
	if chefe:
		return PRIO_CHEFE
	if elite:
		return PRIO_ELITE
	return tipo

func prioritario(v: Unidade) -> bool:
	if prioridade < 0 or v.equipe != 1:
		return false
	if v.parte:
		return prioridade == PRIO_CHEFE   # pedaços do Rei de Massinha contam como o chefe
	if v.pequeno:
		return prioridade == Unidade.Tipo.GEMEO
	return prio_de(v.tipo, v.elite, v.chefe) == prioridade

func _ev(d: Dictionary) -> void:
	if gerar_eventos:
		eventos.append(d)

func calcular(u: Unidade) -> void:
	var vida: float = Balanco.BASE_VIDA * u.esc_vida
	var dano: float = Balanco.BASE_DANO * u.esc_dano
	var inter: float = Balanco.BASE_INTERVALO
	var alc: float = Balanco.BASE_ALCANCE
	var vel: float = Balanco.BASE_VEL
	var dano_mult: float = 1.0
	var vida_mult: float = 1.0
	var rapidez: float = 0.0
	u.distancia = false
	u.provoca = false
	u.armadura = 0.0
	u.reducao = 0.0
	u.esquiva = 0.0
	u.espinho = 0.0
	u.regen = 0.0
	u.aura_raio = 0.0
	u.aura_lentidao = 1.0
	u.tocha_dps = 0.0
	u.cura = 0.0
	u.barril_dano = 0.0
	u.coroa_bonus = 0.0
	u.furia_k = 0.0
	u.cerco = 0.0
	u.furo = 0.0
	u.critico = 0.0
	u.saque = 0.0
	u.aura_dano = 0.0
	u.cura_abate = 0.0
	u.embalo_k = 0.0
	u.barreira_int = 0.0
	u.regen_aura = 0.0
	u.sementes = 0.0
	u.cantil = 0.0
	u.roubo = 0.0
	u.molha = false
	u.perfura = false
	u.fraq_fogo = 1.0
	u.fraq_explosao = 1.0
	u.fraq_corpo = 1.0
	var amuleto: bool = false
	for p in u.pecas:
		if p != null and p.molde() == Pecas.Tipo.AMULETO:
			amuleto = true
	for p in u.pecas:
		if p == null:
			continue
		var m: float = p.poder()
		var nv: int = p.nivel_efetivo()
		match p.molde():
			Pecas.Tipo.PORRETE:
				dano = Balanco.PORRETE_DANO * m * u.esc_dano
				inter = Balanco.PORRETE_INTERVALO
			Pecas.Tipo.ESTILINGUE:
				dano = Balanco.ESTILINGUE_DANO * m * u.esc_dano
				inter = Balanco.ESTILINGUE_INTERVALO
				alc = Balanco.ESTILINGUE_ALCANCE
				u.distancia = true
			Pecas.Tipo.ESCUDO:
				u.reducao = 1.0 - (1.0 - u.reducao) * (1.0 - minf(Balanco.ESCUDO_REDUCAO_MAX, Balanco.ESCUDO_REDUCAO + Balanco.ESCUDO_REDUCAO_NIVEL * nv))
				u.provoca = true
			Pecas.Tipo.COLETE:
				vida += Balanco.COLETE_VIDA * m
			Pecas.Tipo.CAPA:
				vel *= Balanco.CAPA_VEL
				u.esquiva += minf(Balanco.CAPA_ESQUIVA_MAX, Balanco.CAPA_ESQUIVA + Balanco.CAPA_ESQUIVA_NIVEL * nv)
			Pecas.Tipo.ESPINHOS:
				u.espinho = Balanco.ESPINHOS_DANO * m
				vida += Balanco.ESPINHOS_VIDA * m
			Pecas.Tipo.CAPACETE:
				u.armadura += Balanco.CAPACETE_ARMADURA * m
			Pecas.Tipo.CHAPEU:
				u.regen += Balanco.CHAPEU_REGEN * m
			Pecas.Tipo.MASCARA:
				u.aura_raio = Balanco.MASCARA_RAIO
				u.aura_lentidao = maxf(Balanco.MASCARA_LENTIDAO_MIN, Balanco.MASCARA_LENTIDAO - Balanco.MASCARA_LENTIDAO_NIVEL * nv)
			Pecas.Tipo.LANCA:
				dano = Balanco.LANCA_DANO * m * u.esc_dano
				inter = Balanco.LANCA_INTERVALO
				alc = Balanco.LANCA_ALCANCE
			Pecas.Tipo.TOCHA:
				dano = Balanco.TOCHA_DANO * m * u.esc_dano
				inter = Balanco.TOCHA_INTERVALO
				u.tocha_dps += Balanco.TOCHA_DPS * m
			Pecas.Tipo.AVENTAL:
				u.cura = Balanco.AVENTAL_CURA * m
			Pecas.Tipo.BARRIL:
				u.barril_dano += Balanco.BARRIL_DANO * m
			Pecas.Tipo.COROA:
				u.coroa_bonus += Balanco.COROA_BONUS * m
			Pecas.Tipo.CHIFRES:
				u.furia_k = minf(Balanco.CHIFRES_BONUS_MAX, Balanco.CHIFRES_BONUS * m)
			Pecas.Tipo.CETRO:
				dano = Balanco.CETRO_DANO * m * u.esc_dano
				inter = Balanco.CETRO_INTERVALO
				u.cerco += Balanco.CETRO_AREA
			Pecas.Tipo.REGADOR:
				dano = Balanco.REGADOR_DANO * m * u.esc_dano
				inter = Balanco.REGADOR_INTERVALO
				alc = Balanco.REGADOR_ALCANCE
				u.distancia = true
				u.molha = true
			Pecas.Tipo.SABRE:
				dano = Balanco.SABRE_DANO * m * u.esc_dano
				inter = Balanco.SABRE_INTERVALO
			Pecas.Tipo.VARINHA:
				dano = Balanco.VARINHA_DANO * m * u.esc_dano
				inter = Balanco.VARINHA_INTERVALO
				alc = Balanco.VARINHA_ALCANCE
				u.distancia = true
				u.perfura = true
			Pecas.Tipo.CARTOLA:
				u.critico = minf(Balanco.CARTOLA_CRITICO_MAX, Balanco.CARTOLA_CRITICO + Balanco.CARTOLA_CRITICO_NIVEL * nv)
			Pecas.Tipo.CAUBOI:
				rapidez += minf(Balanco.CAUBOI_RAPIDEZ_MAX, Balanco.CAUBOI_RAPIDEZ + Balanco.CAUBOI_RAPIDEZ_NIVEL * nv)
			Pecas.Tipo.TRICORNIO:
				u.saque = minf(Balanco.TRICORNIO_SAQUE_MAX, Balanco.TRICORNIO_SAQUE + Balanco.TRICORNIO_SAQUE_NIVEL * nv)
			Pecas.Tipo.PONTUDO:
				u.aura_dano = Balanco.PONTUDO_DPS * m
			Pecas.Tipo.PELE:
				vida += Balanco.PELE_VIDA * m
				u.cura_abate = Balanco.PELE_CURA
			Pecas.Tipo.PONCHO:
				vida += Balanco.PONCHO_VIDA * m
				u.furo += Balanco.PONCHO_FURO
			Pecas.Tipo.CASACO:
				vida += Balanco.CASACO_VIDA * m
				u.embalo_k = Balanco.CASACO_EMBALO
			Pecas.Tipo.MANTO:
				u.barreira_int = maxf(Balanco.MANTO_INTERVALO_MIN, Balanco.MANTO_INTERVALO - Balanco.MANTO_INTERVALO_NIVEL * nv)
			Pecas.Tipo.BOTAS:
				vel *= Balanco.BOTAS_VEL
				vida += Balanco.BOTAS_VIDA * m
			Pecas.Tipo.JOELHEIRAS:
				u.reducao = 1.0 - (1.0 - u.reducao) * (1.0 - minf(Balanco.JOELHEIRAS_REDUCAO_MAX, Balanco.JOELHEIRAS_REDUCAO + Balanco.JOELHEIRAS_REDUCAO_NIVEL * nv))
			Pecas.Tipo.BANDEIRA:
				u.regen_aura = Balanco.BANDEIRA_REGEN * m
			Pecas.Tipo.NARIZ:
				u.provoca = true
				u.esquiva += minf(Balanco.NARIZ_ESQUIVA_MAX, Balanco.NARIZ_ESQUIVA + Balanco.NARIZ_ESQUIVA_NIVEL * nv)
			Pecas.Tipo.COLAR:
				dano_mult += Balanco.COLAR_DANO * m
			Pecas.Tipo.SEMENTES:
				u.sementes = Balanco.SEMENTES_CURA + Balanco.SEMENTES_CURA_NIVEL * nv
			Pecas.Tipo.CANTIL:
				u.cantil = Balanco.CANTIL_CURA + Balanco.CANTIL_CURA_NIVEL * nv
			Pecas.Tipo.GANCHO:
				u.roubo += Balanco.GANCHO_ROUBO + Balanco.GANCHO_ROUBO_NIVEL * nv
		# marcas: somam entre todas as peças vestidas (em dobro com o Amuleto)
		var vezes: float = 2.0 if amuleto and p.molde() != Pecas.Tipo.AMULETO else 1.0
		for mk in p.marcas:
			match mk:
				Pecas.Marca.CICATRIZ:
					vida += Balanco.MARCA_CICATRIZ_VIDA * vezes
				Pecas.Marca.CERCO:
					u.cerco += Balanco.MARCA_CERCO_DANO * vezes
				Pecas.Marca.FURO:
					u.furo += Balanco.MARCA_FURO_REDUCAO * vezes
				Pecas.Marca.BRASA:
					u.tocha_dps += Balanco.MARCA_BRASA_DPS * vezes
				Pecas.Marca.POLVORA:
					u.barril_dano += Balanco.MARCA_POLVORA_DANO * vezes
	# fantasias: bônus parcial com 2 ou 3 peças, completo com as 4
	var cont: Array[int] = Pecas.contar_conjuntos(u.pecas)
	u.poder = -1
	u.poder_conj = -1
	for c in cont.size():
		var g: int = Pecas.grau_conjunto(cont[c]) - 1
		if g < 0:
			continue
		if g == 1:
			# fantasia completa: ganha o poder especial
			u.poder = Pecas.PODER_TIPO[c]
			u.poder_conj = c
			var soma: float = 0.0
			for p in u.pecas:
				soma += p.poder()
			u.poder_forca = soma / Pecas.SLOTS
		match Pecas.CONJUNTO_MOLDE[c]:
			Pecas.Conjunto.CAVALEIRO:
				u.armadura += Balanco.CONJ_CAVALEIRO_ARMADURA[g]
			Pecas.Conjunto.GUARDIAO:
				vida_mult += Balanco.CONJ_GUARDIAO_VIDA[g]
			Pecas.Conjunto.REI:
				u.coroa_bonus += Balanco.CONJ_REI_DANO[g]
			Pecas.Conjunto.CIRCO:
				u.barril_dano += Balanco.CONJ_CIRCO_EXPLOSAO[g]
			Pecas.Conjunto.VIKING:
				dano_mult += Balanco.CONJ_VIKING_DANO[g]
			Pecas.Conjunto.JARDINEIRO:
				u.regen += Balanco.CONJ_JARDINEIRO_REGEN[g]
			Pecas.Conjunto.CAUBOI:
				rapidez += Balanco.CONJ_CAUBOI_RAPIDEZ[g]
			Pecas.Conjunto.PIRATA:
				u.roubo += Balanco.CONJ_PIRATA_ROUBO[g]
			Pecas.Conjunto.MAGO:
				u.tocha_dps += Balanco.CONJ_MAGO_QUEIMA[g]
	u.atordoa_chance = 0.0
	u.gelo_chance = 0.0
	u.furo = minf(u.furo, Balanco.MARCA_FURO_MAX)
	u.esquiva = minf(u.esquiva, Balanco.ESQUIVA_MAX)
	u.roubo = minf(u.roubo, Balanco.ROUBO_MAX)
	vida *= vida_mult
	dano *= dano_mult
	inter /= 1.0 + rapidez
	# treino do boneco, tipo e família de inimigo
	vida *= 1.0 + Balanco.ATR_VIDA * u.atr[Boneco.Atr.VIDA]
	dano *= 1.0 + Balanco.ATR_FORCA * u.atr[Boneco.Atr.FORCA]
	inter /= 1.0 + Balanco.ATR_AGIL * u.atr[Boneco.Atr.AGILIDADE]
	vel *= 1.0 + Balanco.ATR_AGIL_VEL * u.atr[Boneco.Atr.AGILIDADE]
	vida *= Balanco.TIPO_VIDA[u.tipo]
	vel *= Balanco.TIPO_VEL[u.tipo]
	if u.equipe == 1 and not u.chefe:
		match u.tipo:
			Unidade.Tipo.ATIRADOR:
				u.distancia = true
				alc = maxf(alc, Balanco.ATIRADOR_ALCANCE)
				dano *= Balanco.ATIRADOR_DANO
			Unidade.Tipo.CURANDEIRO:
				u.cura += Balanco.CURANDEIRO_CURA * u.esc_vida
				dano *= Balanco.CURANDEIRO_DANO
			Unidade.Tipo.ESCUDEIRO:
				u.reducao = 1.0 - (1.0 - u.reducao) * (1.0 - Balanco.ESCUDEIRO_REDUCAO)
				u.provoca = true
			Unidade.Tipo.BOMBA:
				u.barril_dano += Balanco.BOMBA_DANO * u.esc_dano
		vida *= Fases.FAMILIA_VIDA[u.familia]
		vel *= Fases.FAMILIA_VEL[u.familia]
		dano *= Fases.FAMILIA_DANO[u.familia]
		u.regen += Fases.FAMILIA_REGEN[u.familia]
	if u.chefe:
		vel *= Balanco.CHEFE_VEL
		match u.chefe_tipo:
			Fases.Chefe.GENERAL:
				vel *= Balanco.GENERAL_VEL
			Fases.Chefe.URSO:
				u.cerco += Balanco.URSO_AREA
				u.fraq_fogo = Balanco.URSO_FOGO
			Fases.Chefe.ROBO:
				vel *= Balanco.ROBO_VEL
			Fases.Chefe.BONECA:
				vida *= Balanco.BONECA_VIDA
				alc = maxf(alc, Balanco.BONECA_ALCANCE)
				u.distancia = true
				u.fraq_corpo = Balanco.BONECA_CORPO
			Fases.Chefe.REI_MASSINHA:
				u.regen += Balanco.MASSINHA_REGEN * vida
				u.fraq_explosao = Balanco.MASSINHA_EXPLOSAO
			Fases.Chefe.GAMBA:
				u.aura_raio = Balanco.GAMBA_RAIO
				u.aura_lentidao = Balanco.GAMBA_LENTIDAO
				u.fraq_fogo = Balanco.GAMBA_FOGO
			Fases.Chefe.CORUJA:
				vida *= Balanco.CORUJA_VIDA
				alc = maxf(alc, Balanco.CORUJA_ALCANCE)
				u.distancia = true
				u.fraq_explosao = Balanco.CORUJA_EXPLOSAO
			Fases.Chefe.TEXUGO:
				u.armadura += Balanco.TEXUGO_COURO * u.esc_dano
	var antiga: float = u.vida_max
	var frac: float = 1.0
	if antiga > 0.0:
		frac = u.vida / antiga
	u.vida_max = vida
	u.vida = vida * frac
	u.dano = dano
	u.intervalo = inter
	u.alcance = alc
	u.vel = vel

func _spawnar(item: Dictionary) -> void:
	var chefe: bool = item.has("chefe")
	var u := Unidade.new()
	u.equipe = 1
	u.tipo = item["tipo"]
	u.pecas = item["pecas"]
	u.chefe = chefe
	u.elite = item.get("elite", false)
	u.familia = clampi(int(item.get("fam", estado.fase - 1)), 0, Fases.TOTAL - 1)
	var p: int = estado.progresso()
	u.esc_vida = Balanco.INIMIGO_VIDA_MULT * (1.0 + Balanco.INIMIGO_VIDA_ONDA * (p - 1)) * estado.mult_vida() * estado.forca_vida()
	u.esc_dano = (1.0 + Balanco.INIMIGO_DANO_ONDA * (p - 1)) * estado.mult_dano() * estado.forca_dano()
	if chefe:
		u.chefe_tipo = estado.lugar()
		u.truque_cd = Balanco.TOUPEIRA_FORA_T if u.chefe_tipo == Fases.Chefe.TOUPEIRA else 5.0
		u.esc_vida *= Balanco.CHEFE_VIDA_MULT * (1.0 + Balanco.CHEFE_VIDA_FASE * estado.degrau_chefe())
		u.esc_dano *= Balanco.CHEFE_DANO_MULT
		u.reforco_cd = Balanco.GENERAL_REFORCO_T
		u.corda_t = Balanco.ROBO_CORDA_T
		_ev({"t": "chefe"})
	u.x = Balanco.INIMIGO_X0
	u.y = rng.randf_range(Balanco.CHAO_Y0, Balanco.CHAO_Y1)
	calcular(u)
	u.vida = u.vida_max
	u.cd = rng.randf_range(0.0, 0.5)
	inimigos.append(u)

func passo(dt: float) -> void:
	if terminada:
		return
	tempo += dt
	while fila.size() > 0 and fila[0]["t"] <= tempo:
		var item: Dictionary = fila.pop_front()
		_spawnar(item)
	_torre_atira(dt)
	_modulos_da_torre(dt)
	# auras (máscara)
	for u in aliados:
		u.lento = 1.0
		u.bonus_dano = 1.0
	for u in inimigos:
		u.lento = 1.0
		u.bonus_dano = 1.0
	_aplicar_auras(aliados, inimigos)
	_aplicar_auras(inimigos, aliados)
	_frio(aliados, dt)
	_frio(inimigos, dt)
	_aura_dano(aliados, inimigos, dt)
	_aura_dano(inimigos, aliados, dt)
	_zonas(dt)
	_apoio(aliados, dt)
	_apoio(inimigos, dt)
	for u in aliados:
		if u.vivo:
			_agir(u, dt)
	for u in inimigos:
		if u.vivo:
			_agir(u, dt)
	_separar(aliados, dt)
	_separar(inimigos, dt)
	_mover_projeteis(dt)
	inimigos.append_array(nascidos)  # filhotes de gêmeo entram fora dos laços
	nascidos.clear()
	aliados.append_array(nascidos_aliados)
	nascidos_aliados.clear()
	for i in range(aliados.size() - 1, -1, -1):
		if not aliados[i].vivo:
			aliados.remove_at(i)
	for i in range(inimigos.size() - 1, -1, -1):
		if not inimigos[i].vivo:
			inimigos.remove_at(i)
	if estado.tijolos <= 0:
		terminada = true
		vitoria = false
	elif inimigos.is_empty() and fila.is_empty() and projeteis.is_empty():
		terminada = true
		vitoria = true
	elif tempo > Balanco.TEMPO_MAX:
		terminada = true
		vitoria = false

## Unidades do mesmo lado que ficaram uma em cima da outra se afastam de leve, mais na vertical
## (a luta é lida de lado). Chefes, quem pula, quem foge e quem está atordoado não são empurrados.
func _separar(lista: Array[Unidade], dt: float) -> void:
	var n: int = lista.size()
	for i in n:
		var a: Unidade = lista[i]
		if not a.vivo or a.chefe or a.fugindo or a.tipo == Unidade.Tipo.SALTADOR:
			continue
		for j in range(i + 1, n):
			var b: Unidade = lista[j]
			if not b.vivo or b.chefe or b.fugindo or b.tipo == Unidade.Tipo.SALTADOR:
				continue
			var dx: float = b.x - a.x
			var dy: float = b.y - a.y
			if absf(dx) >= Balanco.SEPARA_RAIO or absf(dy) >= Balanco.SEPARA_RAIO:
				continue
			var d: float = sqrt(dx * dx + dy * dy)
			if d >= Balanco.SEPARA_RAIO:
				continue
			var f: float = (1.0 - d / Balanco.SEPARA_RAIO) * Balanco.SEPARA_VEL * dt
			var sy: float = 1.0 if dy > 0.0 or (dy == 0.0 and (i + j) % 2 == 0) else -1.0
			var sx: float = signf(dx)
			if a.atordoado_t <= 0.0:
				a.x -= sx * f * 0.35
				a.y = clampf(a.y - sy * f, Balanco.CHAO_Y0, Balanco.CHAO_Y1)
			if b.atordoado_t <= 0.0:
				b.x += sx * f * 0.35
				b.y = clampf(b.y + sy * f, Balanco.CHAO_Y0, Balanco.CHAO_Y1)

## A torre atira no inimigo mais próximo dela; quanto menos tijolos, mais devagar.
func _torre_atira(dt: float) -> void:
	if estado.tijolos < Balanco.TORRE_TIRO_MIN_TIJOLOS:
		return
	torre_cd -= dt * estado.torre_rapidez() * float(estado.tijolos) / estado.tijolos_max()
	if torre_cd > 0.0:
		return
	var alvo: Unidade = null
	for v in inimigos:
		if v.vivo and v.x - Balanco.TORRE_X <= Balanco.TORRE_TIRO_ALCANCE and (alvo == null or v.x < alvo.x):
			alvo = v
	if alvo == null:
		return
	torre_cd = Balanco.TORRE_TIRO_INTERVALO
	projeteis.append({"x": Balanco.TORRE_X - 70.0, "y": Balanco.CHAO_Y0 + 20.0, "alvo": alvo, "dono": null, "dano": estado.torre_dano(), "torre": true})

func _aplicar_auras(donos: Array[Unidade], alvos: Array[Unidade]) -> void:
	for u in donos:
		if u.aura_raio <= 0.0 or not u.vivo:
			continue
		for v in alvos:
			var dx: float = v.x - u.x
			var dy: float = v.y - u.y
			if dx * dx + dy * dy <= u.aura_raio * u.aura_raio:
				v.lento = minf(v.lento, u.aura_lentidao)

## Módulos montados na torre que agem sozinhos durante a luta.
func _modulos_da_torre(dt: float) -> void:
	if estado.modulos.is_empty():
		return
	if estado.tem_modulo(Torre.Modulo.CATAPULTA):
		catapulta_cd -= dt
		if catapulta_cd <= 0.0:
			var alvo: Unidade = null
			for v in inimigos:
				if v.vivo and v.x <= Balanco.VISIVEL_X and (alvo == null or v.x < alvo.x):
					alvo = v
			if alvo != null:
				catapulta_cd = Torre.CATAPULTA_INTERVALO
				var cx: float = alvo.x
				var cy: float = alvo.y
				_ev({"t": "catapulta", "x": cx, "y": cy, "raio": Torre.CATAPULTA_RAIO})
				for v in inimigos:
					if v.vivo and _dentro(v, cx, cy, Torre.CATAPULTA_RAIO):
						v.vida -= Torre.CATAPULTA_DANO * v.vulneravel
						v.flash = 1.0
						_ev({"t": "golpe", "x": v.x, "y": v.y, "dano": Torre.CATAPULTA_DANO * v.vulneravel, "eq": 1})
						if v.vida <= 0.0:
							_matar(v, null, Pecas.Marca.POLVORA)
	if estado.tem_modulo(Torre.Modulo.SIRENE) and not sirene_usada and estado.tijolos > 0 and estado.tijolos <= int(estado.tijolos_max() * Torre.SIRENE_LIMIAR):
		sirene_usada = true
		for v in inimigos:
			if v.vivo:
				v.atordoado_t = maxf(v.atordoado_t, Torre.SIRENE_T * (Torre.SIRENE_CHEFE if v.chefe else 1.0))
		_ev({"t": "sirene"})
	if estado.tem_modulo(Torre.Modulo.CALDEIRAO):
		caldeirao_cd -= dt
		if caldeirao_cd <= 0.0:
			caldeirao_cd = Torre.CALDEIRAO_INTERVALO
			if estado.tijolos > 0 and estado.tijolos < estado.tijolos_max():
				estado.tijolos += 1
				_ev({"t": "caldeirao"})

## Balista: o tiro da torre segue e fere os bichos mais próximos atrás do alvo, na mesma faixa.
func _balista(alvo: Unidade, dano: float) -> void:
	var atras: Array[Unidade] = []
	for v in inimigos:
		if v != alvo and v.vivo and v.x >= alvo.x and absf(v.y - alvo.y) <= Torre.BALISTA_LARGURA:
			atras.append(v)
	atras.sort_custom(func(a: Unidade, b: Unidade) -> bool: return a.x < b.x)
	for i in mini(Torre.BALISTA_EXTRAS, atras.size()):
		_ev({"t": "balista", "x": atras[i].x, "y": atras[i].y, "x0": alvo.x, "y0": alvo.y})
		_dano(null, atras[i], dano, false)

## Regador: quem foi molhado anda e ataca mais devagar por um tempo.
func _frio(lista: Array[Unidade], dt: float) -> void:
	for u in lista:
		if u.frio_t > 0.0:
			u.frio_t -= dt
			u.lento = minf(u.lento, Balanco.REGADOR_LENTIDAO)

## Chapéu pontudo: fere aos poucos os inimigos em volta do dono.
func _aura_dano(donos: Array[Unidade], alvos: Array[Unidade], dt: float) -> void:
	var r2: float = Balanco.PONTUDO_RAIO * Balanco.PONTUDO_RAIO
	for u in donos:
		if u.aura_dano <= 0.0 or not u.vivo:
			continue
		for v in alvos:
			if not v.vivo:
				continue
			var dx: float = v.x - u.x
			var dy: float = v.y - u.y
			if dx * dx + dy * dy <= r2:
				v.vida -= u.aura_dano * dt * v.vulneravel
				if v.vida <= 0.0:
					_matar(v, u, Pecas.Marca.CICATRIZ)

## Comportamento próprio do chefe da fase. Devolve false se ele não age neste passo.
func _chefe_age(u: Unidade, dt: float) -> bool:
	match u.chefe_tipo:
		Fases.Chefe.GENERAL:
			u.reforco_cd -= dt
			if u.reforco_cd <= 0.0:
				u.reforco_cd = Balanco.GENERAL_REFORCO_T
				for k in Balanco.GENERAL_REFORCO_N:
					fila.push_front({"t": tempo, "pecas": [null, null, null, null], "tipo": Unidade.Tipo.COMUM})
				_ev({"t": "reforco", "x": u.x, "y": u.y})
		Fases.Chefe.ROBO:
			u.corda_t -= dt
			if u.corda_t <= 0.0:
				u.parado = not u.parado
				u.corda_t = Balanco.ROBO_PARADO_T if u.parado else Balanco.ROBO_CORDA_T
				u.vulneravel = Balanco.ROBO_PARADO_DANO if u.parado else 1.0
				u.alvo = null
				_ev({"t": "corda", "x": u.x, "y": u.y, "parado": u.parado})
			if u.parado:
				u.andando = false
				return false
		Fases.Chefe.TOUPEIRA:
			u.truque_cd -= dt
			if u.parado:
				# debaixo da terra: ninguém a alcança; ao sair, aparece junto do gato mais atrás, tonta
				u.andando = false
				if u.truque_cd <= 0.0:
					u.parado = false
					var atras: Unidade = _mais_atras()
					if atras != null:
						u.x = atras.x + 46.0
						u.y = atras.y
					u.vulneravel = Balanco.TOUPEIRA_TONTA_DANO
					u.atordoado_t = Balanco.TOUPEIRA_TONTA_T
					u.truque_cd = Balanco.TOUPEIRA_FORA_T
					u.alvo = null
					_ev({"t": "corda", "x": u.x, "y": u.y, "parado": false})
				return false
			if u.vulneravel > 1.0 and u.truque_cd < Balanco.TOUPEIRA_FORA_T - Balanco.TOUPEIRA_TONTA_T:
				u.vulneravel = 1.0
			if u.truque_cd <= 0.0 and u.x <= Balanco.VISIVEL_X:
				u.parado = true
				u.vulneravel = 0.0
				u.truque_cd = Balanco.TOUPEIRA_CAVA_T
				u.alvo = null
				_ev({"t": "corda", "x": u.x, "y": u.y, "parado": true})
				return false
		Fases.Chefe.GAMBA:
			u.truque_cd -= dt
			if u.truque_cd <= 0.0 and u.x <= Balanco.VISIVEL_X:
				u.truque_cd = Balanco.GAMBA_GAS_T
				var tontos: Array = []
				for v in aliados:
					if v.vivo and _dentro(v, u.x, u.y, Balanco.GAMBA_RAIO):
						v.atordoado_t = maxf(v.atordoado_t, Balanco.GAMBA_GAS_ATORDOA)
						tontos.append(Vector2(v.x, v.y))
				if not tontos.is_empty():
					_ev({"t": "poder", "x": u.x, "y": u.y, "eq": 1, "poder": Pecas.Poder.ATORDOA, "conj": Pecas.Conjunto.CIRCO, "pontos": tontos})
		Fases.Chefe.CORUJA:
			u.truque_cd -= dt
			if u.truque_cd <= 0.0 and u.x <= Balanco.VISIVEL_X:
				u.truque_cd = Balanco.CORUJA_RASANTE_T
				var feridos: Array = []
				for v in aliados.duplicate():
					if v.vivo and absf(v.y - u.y) <= Balanco.CORUJA_RASANTE_LARGURA:
						feridos.append(Vector2(v.x, v.y))
						_dano_poder(u, v, u.dano * Balanco.CORUJA_RASANTE_DANO)
				if not feridos.is_empty():
					_ev({"t": "poder", "x": u.x, "y": u.y, "eq": 1, "poder": Pecas.Poder.ATRAVESSA, "conj": Pecas.Conjunto.MORCEGO, "pontos": feridos})
		Fases.Chefe.VIRALATA:
			u.reforco_cd -= dt
			if u.reforco_cd <= 0.0:
				u.reforco_cd = Balanco.VIRALATA_MATILHA_T
				for k in Balanco.VIRALATA_MATILHA_N:
					fila.push_front({"t": tempo, "pecas": [null, null, null, null], "tipo": Unidade.Tipo.COMUM})
				_ev({"t": "reforco", "x": u.x, "y": u.y})
			u.truque_cd -= dt
			if u.parado:
				u.andando = false
				if u.truque_cd <= 0.0:
					u.parado = false
					u.vulneravel = 1.0
					u.truque_cd = Balanco.VIRALATA_LATIDO_T
				return false
			if u.truque_cd <= 0.0 and u.x <= Balanco.VISIVEL_X:
				var jogados: Array = []
				for v in aliados:
					if v.vivo and _dentro(v, u.x, u.y, Balanco.VIRALATA_LATIDO_RAIO):
						v.x = maxf(Balanco.TORRE_X + 20.0, v.x - Balanco.VIRALATA_EMPURRA)
						v.atordoado_t = maxf(v.atordoado_t, Balanco.VIRALATA_ATORDOA)
						jogados.append(Vector2(v.x, v.y))
				if jogados.is_empty():
					u.truque_cd = 1.0   # ninguém por perto: guarda o latido
				else:
					_ev({"t": "poder", "x": u.x, "y": u.y, "eq": 1, "poder": Pecas.Poder.EMPURRA, "conj": Pecas.Conjunto.ESTELAR, "pontos": jogados})
					u.parado = true   # sem fôlego
					u.vulneravel = Balanco.VIRALATA_FOLEGO_DANO
					u.truque_cd = Balanco.VIRALATA_FOLEGO_T
					u.alvo = null
					return false
		Fases.Chefe.TEXUGO:
			if u.vida < u.vida_max * Balanco.TEXUGO_FURIA:
				u.frenesi_t = maxf(u.frenesi_t, 0.5)   # ferido, ataca em dobro até cair
	return true

## Aliado vivo mais perto da torre (alvo da Boneca Rachada).
func _mais_atras() -> Unidade:
	var melhor: Unidade = null
	for v in aliados:
		if v.vivo and (melhor == null or v.x < melhor.x):
			melhor = v
	return melhor

## Até onde o aliado enxerga alvo, conforme a postura: quem avança vê o campo todo; quem segura
## só sai do posto para quem chega perto (o fundo, só para quem encosta); quem recua guarda a torre.
func _visao(u: Unidade) -> float:
	var tiro: float = u.alcance if u.distancia else 0.0
	match u.postura:
		Boneco.Postura.AVANCAR:
			return 1e9
		Boneco.Postura.RECUAR:
			return maxf(Balanco.RECUAR_DIST, tiro)
	if u.linha == Boneco.Linha.FUNDO:
		return maxf(Balanco.LINHA_FUNDO_DIST, tiro)
	return Balanco.LINHA_MEIO_DIST

## Quantos colegas corpo a corpo de `u` já estão em cima de `v`.
func _em_cima(u: Unidade, v: Unidade) -> int:
	var n: int = 0
	var colegas: Array[Unidade] = aliados if u.equipe == 0 else inimigos
	for c in colegas:
		if c != u and c.vivo and not c.distancia and c.alvo == v:
			n += 1
	return n

## O bicho está batendo na torre, ou é dos que só querem a torre (saltador, ladrão).
func _ameaca_torre(v: Unidade) -> bool:
	if v.tipo == Unidade.Tipo.SALTADOR or v.tipo == Unidade.Tipo.LADRAO:
		return true
	return v.alvo == null and v.x - Balanco.TORRE_X <= v.alcance + 40.0

func _escolher(u: Unidade) -> Unidade:
	# saltador e ladrão ignoram os bonecos e vão direto à torre
	if u.equipe == 1 and (u.tipo == Unidade.Tipo.SALTADOR or u.tipo == Unidade.Tipo.LADRAO):
		return null
	if u.chefe and u.chefe_tipo == Fases.Chefe.ROBO:
		return null  # com corda, o robô só enxerga a torre
	if u.chefe and u.chefe_tipo == Fases.Chefe.BONECA:
		return _mais_atras()
	var lista: Array[Unidade] = inimigos if u.equipe == 0 else aliados
	var melhor: Unidade = null
	var melhor_s: float = 1e9
	for v in lista:
		if not v.vivo:
			continue
		if u.equipe == 0 and v.x > Balanco.VISIVEL_X:
			continue
		var dx: float = v.x - u.x
		var dy: float = v.y - u.y
		var d: float = sqrt(dx * dx + dy * dy)
		var provocado: bool = v.provoca and d < Balanco.ESCUDO_PROVOCA_RAIO
		var prio: bool = u.equipe == 0 and prioritario(v)
		if u.equipe == 0 and d > _visao(u) * (Balanco.PRIORIDADE_VISAO if prio else 1.0):
			continue
		if u.equipe == 1 and d > Balanco.AGGRO + u.alcance * 0.5 and not provocado:
			continue
		var s: float = d
		if provocado:
			s -= Balanco.PROVOCA_BONUS
		if prio:
			s -= Balanco.PRIORIDADE_BONUS
		if v == u.alvo:
			s -= Balanco.ALVO_APEGO
		elif not u.distancia and not v.chefe and v.tipo != Unidade.Tipo.GIGANTE:
			s += Balanco.ALVO_LOTADO * mini(_em_cima(u, v), Balanco.ALVO_LOTADO_MAX)
		if u.equipe == 0:
			if _ameaca_torre(v):
				s -= Balanco.ALVO_TORRE
			s -= Balanco.ALVO_FERIDO * (1.0 - clampf(v.vida / maxf(v.vida_max, 1.0), 0.0, 1.0))
		if s < melhor_s:
			melhor_s = s
			melhor = v
	return melhor

func _agir(u: Unidade, dt: float) -> void:
	if u.clone:
		u.clone_t -= dt
		if u.clone_t <= 0.0:
			u.vivo = false
			_ev({"t": "clone_fim", "x": u.x, "y": u.y, "eq": u.equipe, "tempo": true})
			return
	u.flash = maxf(0.0, u.flash - dt * 5.0)
	u.golpe = maxf(0.0, u.golpe - dt)
	u.cd -= dt * u.lento * (2.0 if u.frenesi_t > 0.0 else 1.0)
	u.frenesi_t = maxf(0.0, u.frenesi_t - dt)
	u.protegido_t = maxf(0.0, u.protegido_t - dt)
	u.barreira_cd = maxf(0.0, u.barreira_cd - dt)
	if u.queima_t > 0.0:
		u.queima_t -= dt
		u.vida -= u.queima_dps * dt * u.fraq_fogo * u.vulneravel
		if u.vida <= 0.0:
			var fonte: Unidade = u.queima_fonte
			_matar(u, fonte if fonte != null and fonte.vivo else null, Pecas.Marca.BRASA)
			return
	if u.fugindo:
		_fugir(u, dt)
		return
	if u.cantil > 0.0 and not u.cantil_usado and u.vida < u.vida_max * Balanco.CANTIL_LIMIAR:
		u.cantil_usado = true
		u.vida = minf(u.vida_max, u.vida + u.vida_max * u.cantil)
		_ev({"t": "cantil", "x": u.x, "y": u.y})
	if u.atordoado_t > 0.0:
		u.atordoado_t -= dt
		u.andando = false
		return
	if u.chefe and not _chefe_age(u, dt):
		return
	if u.poder >= 0:
		u.poder_cd -= dt
		u.poder_pronto = u.poder_cd <= 0.0
		if u.poder_pronto and not (poder_manual and u.equipe == 0) and _usar_poder(u):
			u.poder_cd = Balanco.PODER_INTERVALO
			u.poder_pronto = false
			if not u.vivo:
				return
	if not u.herancas.is_empty() and not _herancas_agem(u, dt):
		return
	if u.furia_k > 0.0:
		u.furia = clampf(1.0 - u.vida / u.vida_max, 0.0, 1.0)
	if u.regen > 0.0 and u.vida < u.vida_max:
		u.vida = minf(u.vida_max, u.vida + u.regen * dt)
	u.retarget -= dt
	if u.alvo == null or not u.alvo.vivo or u.retarget <= 0.0:
		u.alvo = _escolher(u)
		u.retarget = Balanco.RETARGET
	u.andando = false
	var a: Unidade = u.alvo
	if a != null:
		var dx: float = a.x - u.x
		var dy: float = a.y - u.y
		var d: float = sqrt(dx * dx + dy * dy)
		if d <= u.alcance:
			if u.cd <= 0.0:
				_atacar(u, a)
		else:
			var passo: float = minf(u.vel * u.lento * dt, d - u.alcance * 0.85)
			if passo > 0.0:
				u.x += dx / d * passo
				u.y += dy / d * passo
				u.andando = true
	elif u.equipe == 0:
		# sem alvo: volta ao posto da linha
		var cx: float = u.casa_x - u.x
		var cy: float = u.casa_y - u.y
		var cd2: float = sqrt(cx * cx + cy * cy)
		if cd2 > Balanco.LINHA_CASA_MARGEM:
			var pv: float = minf(u.vel * u.lento * dt * (Balanco.LINHA_CORRIDA if cd2 > Balanco.LINHA_CORRIDA_DIST else 1.0), cd2)
			u.x += cx / cd2 * pv
			u.y += cy / cd2 * pv
			u.andando = true
	elif u.equipe == 1:
		if u.x - Balanco.TORRE_X <= u.alcance:
			if u.cd <= 0.0:
				u.cd = u.intervalo * Balanco.TORRE_INTERVALO_MULT
				u.golpe = 0.22
				if u.distancia:
					projeteis.append({"x": u.x, "y": u.y, "alvo": null, "dono": u, "dano": u.dano})
					_ev({"t": "tiro", "x": u.x, "y": u.y, "eq": 1})
				else:
					_bater_torre(u)
		else:
			u.x -= u.vel * u.lento * dt * (Balanco.ENTRADA_VEL if u.x > Balanco.ENTRADA_X else 1.0)
			u.andando = true

func _atacar(u: Unidade, a: Unidade) -> void:
	if u.equipe == 1 and u.tipo == Unidade.Tipo.BOMBA and not u.chefe:
		_matar(u, null, Pecas.Marca.POLVORA)   # a bomba não bate: encosta e explode
		return
	u.cd = u.intervalo
	u.golpe = 0.22
	var dm: float = u.dano * u.bonus_dano * (1.0 + u.furia_k * u.furia) * (1.0 + u.embalo)
	if u.critico > 0.0 and rng.randf() < u.critico:
		dm *= Balanco.CARTOLA_MULT
		_ev({"t": "critico", "x": a.x, "y": a.y})
	if u.distancia:
		projeteis.append({"x": u.x, "y": u.y, "alvo": a, "dono": u, "dano": dm})
		_ev({"t": "tiro", "x": u.x, "y": u.y, "eq": u.equipe})
	else:
		_dano(u, a, dm, true)
		if u.cerco > 0.0 and u.vivo:
			_golpe_em_area(u, a, dm * u.cerco)

## Ladrão com a carga: corre de volta à borda direita; fora da tela, os tijolos se perdem.
func _fugir(u: Unidade, dt: float) -> void:
	u.andando = true
	u.x += u.vel * Balanco.LADRAO_FUGA_VEL * u.lento * dt
	if u.x >= Balanco.INIMIGO_X0:
		u.vivo = false
		_ev({"t": "fuga", "x": u.x, "y": u.y, "n": u.carga})

func _bater_torre(u: Unidade) -> void:
	var n: int = Balanco.TORRE_DANO
	if u.chefe:
		n = Balanco.CHEFE_TORRE_DANO
	elif u.tipo == Unidade.Tipo.GIGANTE:
		n = Balanco.GIGANTE_TORRE_DANO
	elif u.tipo == Unidade.Tipo.BOMBA:
		n = Balanco.BOMBA_TORRE
	elif u.tipo == Unidade.Tipo.LADRAO:
		if not u.vivo or u.fugindo:
			return
		n = Balanco.LADRAO_ROUBO  # rouba num golpe só e foge
		u.fugindo = true
		u.alvo = null
		u.carga = mini(n, estado.tijolos)
		u.golpe = 0.0
	n = mini(n, estado.tijolos)
	estado.tijolos -= n
	_ev({"t": "torre", "n": n, "x": u.x, "y": u.y})
	if u.tipo == Unidade.Tipo.BOMBA and not u.chefe and u.vivo:
		_matar(u, null, Pecas.Marca.POLVORA)   # explode na torre e some
		return
	if estado.tem_modulo(Torre.Modulo.RATOEIRA) and u.vivo and not u.distancia and not u.fugindo:
		_ev({"t": "ratoeira", "x": u.x, "y": u.y})
		u.vida -= Torre.RATOEIRA_DANO * u.vulneravel
		u.flash = 1.0
		_ev({"t": "golpe", "x": u.x, "y": u.y, "dano": Torre.RATOEIRA_DANO * u.vulneravel, "eq": 1})
		if u.vida <= 0.0:
			_matar(u, null, Pecas.Marca.CICATRIZ)

func _mover_projeteis(dt: float) -> void:
	for i in range(projeteis.size() - 1, -1, -1):
		var p: Dictionary = projeteis[i]
		var a: Unidade = p["alvo"]
		var tx: float
		var ty: float
		if a == null:
			tx = Balanco.TORRE_X
			ty = p["y"]
		else:
			if not a.vivo:
				projeteis.remove_at(i)
				continue
			tx = a.x
			ty = a.y
		var dx: float = tx - p["x"]
		var dy: float = ty - p["y"]
		var d: float = sqrt(dx * dx + dy * dy)
		var mv: float = Balanco.PROJETIL_VEL * dt
		if d <= mv + 6.0:
			projeteis.remove_at(i)
			if a == null:
				_bater_torre(p["dono"])
			else:
				_dano(p["dono"], a, p["dano"], false)
				if p.has("torre") and estado.tem_modulo(Torre.Modulo.BALISTA):
					_balista(a, p["dano"] * Torre.BALISTA_DANO)
		else:
			p["x"] += dx / d * mv
			p["y"] += dy / d * mv

## Marca Cerco: o golpe também fere os outros inimigos perto do alvo (sem refletir espinhos).
func _golpe_em_area(u: Unidade, centro: Unidade, dano: float) -> void:
	var lista: Array[Unidade] = inimigos if u.equipe == 0 else aliados
	var r2: float = Balanco.MARCA_CERCO_RAIO_GOLPE * Balanco.MARCA_CERCO_RAIO_GOLPE
	for v in lista:
		if v == centro or not v.vivo:
			continue
		var dx: float = v.x - centro.x
		var dy: float = v.y - centro.y
		if dx * dx + dy * dy <= r2:
			_dano(u, v, dano, true, true)

func _dano(atk: Unidade, alvo: Unidade, dano: float, corpo_a_corpo: bool, em_area: bool = false) -> void:
	if not alvo.vivo:
		return
	if alvo.esquiva > 0.0 and rng.randf() < alvo.esquiva:
		_ev({"t": "esquiva", "x": alvo.x, "y": alvo.y})
		return
	if alvo.barreira_int > 0.0 and alvo.barreira_cd <= 0.0:
		alvo.barreira_cd = alvo.barreira_int  # Manto: o golpe some
		_ev({"t": "barreira", "x": alvo.x, "y": alvo.y})
		return
	var d: float
	if atk != null and atk.perfura:
		d = maxf(Balanco.DANO_MINIMO, dano)  # Varinha: ignora armadura e redução
	else:
		d = maxf(Balanco.DANO_MINIMO, dano - alvo.armadura) * (1.0 - alvo.reducao)
	if corpo_a_corpo:
		d *= alvo.fraq_corpo
	else:
		d *= 1.0 - alvo.furo
	d *= alvo.vulneravel
	if alvo.protegido_t > 0.0:
		d *= Balanco.PODER_PROTEGE_DANO
	alvo.vida -= d
	alvo.flash = 1.0
	var sinal: float = -1.0 if alvo.equipe == 0 else 1.0
	if not alvo.chefe and alvo.tipo != Unidade.Tipo.GIGANTE:
		alvo.x += sinal * 6.0
	_ev({"t": "golpe", "x": alvo.x, "y": alvo.y, "dano": d, "eq": alvo.equipe})
	if atk != null and atk.vivo:
		if atk.roubo > 0.0:
			atk.vida = minf(atk.vida_max, atk.vida + d * atk.roubo)
		if atk.molha or (atk.gelo_chance > 0.0 and rng.randf() < atk.gelo_chance):
			alvo.frio_t = Balanco.REGADOR_DURACAO
	if atk != null and atk.tocha_dps > 0.0 and alvo.vida > 0.0:
		alvo.queima_t = Balanco.TOCHA_DURACAO
		alvo.queima_dps = atk.tocha_dps
		alvo.queima_fonte = atk
	if alvo.vida <= 0.0:
		_matar(alvo, atk, Pecas.Marca.CICATRIZ if corpo_a_corpo else Pecas.Marca.FURO)
	if corpo_a_corpo and not em_area and alvo.espinho > 0.0 and atk.vivo:
		atk.vida -= alvo.espinho
		atk.flash = 1.0
		_ev({"t": "golpe", "x": atk.x, "y": atk.y, "dano": alvo.espinho, "eq": atk.equipe, "espinho": true})
		if atk.vida <= 0.0:
			_matar(atk, alvo, Pecas.Marca.CICATRIZ)  # espinho conta como corpo a corpo

## Causa da morte (é a própria marca): fogo > explosão > projétil > cerco > cicatriz.
## `base` vem de quem matou: BRASA, POLVORA, FURO (projétil) ou CICATRIZ (corpo a corpo).
func _causa_da_morte(u: Unidade, base: int) -> int:
	if u.queima_t > 0.0:
		return Pecas.Marca.BRASA
	if base == Pecas.Marca.CICATRIZ and _cercado(u):
		return Pecas.Marca.CERCO
	return base

func _cercado(u: Unidade) -> bool:
	var lista: Array[Unidade] = inimigos if u.equipe == 0 else aliados
	var r2: float = Balanco.MARCA_CERCO_RAIO_MORTE * Balanco.MARCA_CERCO_RAIO_MORTE
	var n: int = 0
	for v in lista:
		if not v.vivo:
			continue
		var dx: float = v.x - u.x
		var dy: float = v.y - u.y
		if dx * dx + dy * dy <= r2:
			n += 1
	return n >= Balanco.MARCA_CERCO_MINIMO

func _matar(u: Unidade, killer: Unidade, base: int = Pecas.Marca.CICATRIZ) -> void:
	if not u.vivo:
		return
	if u.clone:
		# clone: some sem marcar roupa, sem largar peça, sem contar como gato caído nem como abate
		u.vivo = false
		_ev({"t": "clone_fim", "x": u.x, "y": u.y, "eq": u.equipe, "tempo": false})
		return
	u.vivo = false
	var causa: int = _causa_da_morte(u, base)
	_ev({"t": "morte", "x": u.x, "y": u.y, "eq": u.equipe, "pecas": u.pecas, "boneco": u.boneco})
	if u.barril_dano > 0.0:
		_explodir(u)
	if u.sementes > 0.0:
		_semear(u)
	if killer != null and killer.vivo:
		_ao_abater(killer)
	if u.equipe == 1:
		if u.fugindo and u.carga > 0:
			estado.tijolos += u.carga  # morreu fugindo: devolve os tijolos
			_ev({"t": "devolve", "x": u.x, "y": u.y, "n": u.carga})
			u.carga = 0
		if u.tipo == Unidade.Tipo.GEMEO and not u.pequeno:
			_nascer_gemeos(u)
		if u.chefe and u.chefe_tipo == Fases.Chefe.REI_MASSINHA:
			_partir(u)
		if killer != null and killer.equipe == 0:
			_creditar(killer)
		estado.estat["abates"] = int(estado.estat.get("abates", 0)) + 1
		if u.chefe or u.elite:
			var tr: int = Torre.TROFEU_CHEFE if u.chefe else Torre.TROFEU_ELITE
			estado.trofeus += tr  # moeda das melhorias da torre
			_ev({"t": "trofeu", "x": u.x, "y": u.y, "n": tr})
		_largar(u, causa)
	else:
		if u.boneco != null:
			u.boneco.vivo = false
		# a morte marca cada peça vestida (as mesmas instâncias do Boneco)
		var marcadas: int = 0
		for p in u.pecas:
			if p != null and p.marcar(causa):
				p.nova = true  # volta destacada ao guarda-roupa
				marcadas += 1
		if marcadas > 0:
			_ev({"t": "marca", "x": u.x, "y": u.y, "marca": causa, "n": marcadas})

## O que o inimigo morto deixa cair. Comum: às vezes; fantasiado: sempre; chefe: duas peças.
func _largar(u: Unidade, causa: int) -> void:
	var vestidas: Array = []
	for p in u.pecas:
		if p != null:
			vestidas.append(p)
	if vestidas.is_empty():
		return
	if not (u.chefe or u.elite or rng.randf() < Balanco.DROP_CHANCE):
		return
	var nivel: int = mini(Balanco.NIVEL_MAX, int(floor((estado.progresso() - 1) * Balanco.DROP_NIVEL_POR_PROG)))
	for k in mini(vestidas.size(), 2 if u.chefe else 1):
		var orig: Peca = vestidas.pop_at(rng.randi_range(0, vestidas.size() - 1))
		var nova := Peca.new(orig.tipo, nivel, _raridade_do_drop(u))
		if u.chefe:
			nova.nivel = maxi(nova.nivel, orig.nivel)  # o chefe larga no nível que usava
		var veio: int = -1
		if u.chefe or rng.randf() < Balanco.DROP_MARCA_CHANCE:
			nova.marcar(causa)  # o jeito de matar define o que cai
			veio = causa
		bau.append(nova)
		_ev({"t": "drop", "x": u.x, "y": u.y, "tipo": nova.tipo, "marca": veio, "raridade": nova.raridade})

func _raridade_do_drop(u: Unidade) -> int:
	var g: float = Balanco.degrau_drop(estado.fase, estado.ato, estado.invasao, estado.onda_invasao)
	var r: float = rng.randf()
	var mitica: float
	var lend: float
	var epica: float
	var rara: float
	if u.chefe:
		# o chefe larga no mínimo rara
		mitica = maxf(0.0, g - Balanco.CHEFE_MITICA_DESDE) * Balanco.CHEFE_MITICA_FASE
		lend = maxf(0.0, g - Balanco.DROP_LENDARIA_DESDE) * Balanco.CHEFE_LENDARIA_FASE
		epica = Balanco.CHEFE_EPICA + minf(g, Balanco.CHEFE_EPICA_TETO) * Balanco.CHEFE_EPICA_FASE
		rara = 1.0
	elif u.elite:
		mitica = maxf(0.0, g - Balanco.DROP_MITICA_DESDE) * Balanco.ELITE_MITICA_FASE
		lend = maxf(0.0, g - Balanco.DROP_LENDARIA_DESDE) * Balanco.ELITE_LENDARIA_FASE
		epica = Balanco.ELITE_EPICA + g * Balanco.ELITE_EPICA_FASE
		rara = Balanco.ELITE_RARA
	else:
		mitica = maxf(0.0, g - Balanco.DROP_MITICA_DESDE) * Balanco.DROP_MITICA_FASE
		lend = maxf(0.0, g - Balanco.DROP_LENDARIA_DESDE) * Balanco.DROP_LENDARIA_FASE
		epica = g * Balanco.DROP_EPICA_FASE
		rara = Balanco.DROP_RARA + minf(g, Balanco.DROP_RARA_TETO) * Balanco.DROP_RARA_FASE
	if r < mitica:
		return Pecas.Raridade.MITICA
	r -= mitica
	if r < lend:
		return Pecas.Raridade.LENDARIA
	r -= lend
	if r < epica:
		return Pecas.Raridade.EPICA
	r -= epica
	if r < rara:
		return Pecas.Raridade.RARA
	return Pecas.Raridade.COMUM

## O jogador manda o gato usar o poder da fantasia. Devolve false se não está carregado
## ou se agora não há em quem usar (o poder continua carregado).
func disparar_poder(u: Unidade) -> bool:
	if u == null or not u.vivo or u.poder < 0 or u.poder_cd > 0.0 or u.atordoado_t > 0.0:
		return false
	if not _usar_poder(u):
		return false
	u.poder_cd = Balanco.PODER_INTERVALO
	u.poder_pronto = false
	return true

## Fração dos poderes de apoio (cura, proteção, frenesi) quando o disparo é uma herança: sobe com o grau.
func _frac_apoio() -> float:
	return minf(1.0, Balanco.HERANCA_APOIO * Balanco.heranca_mult(heranca_grau)) if em_heranca else 1.0

## Heranças: cada poder incorporado dispara sozinho, mais fraco que o da roupa, no seu próprio relógio.
## Devolve false se o gato caiu por causa do disparo.
func _herancas_agem(u: Unidade, dt: float) -> bool:
	while u.heranca_graus.size() < u.herancas.size():
		u.heranca_graus.append(1)
	while u.heranca_cd.size() < u.herancas.size():
		u.heranca_cd.append(Balanco.HERANCA_PRIMEIRO + 2.5 * u.heranca_cd.size() + 1.7 * maxi(0, aliados.find(u)))   # cada gato no seu tempo: não saem todos juntos
	for i in u.herancas.size():
		u.heranca_cd[i] -= dt
		if u.heranca_cd[i] > 0.0:
			continue
		var conj: int = u.herancas[i]
		var p0: int = u.poder
		var c0: int = u.poder_conj
		var f0: float = u.poder_forca
		u.poder = Pecas.PODER_TIPO[conj]
		u.poder_conj = conj
		heranca_grau = u.heranca_graus[i]
		u.poder_forca = (Balanco.HERANCA_FORCA + Balanco.HERANCA_FORCA_NIVEL * (u.boneco.nivel if u.boneco != null else 10)) * Balanco.heranca_mult(heranca_grau)
		em_heranca = true
		var saiu: bool = _usar_poder(u)
		em_heranca = false
		u.poder = p0
		u.poder_conj = c0
		u.poder_forca = f0
		u.heranca_cd[i] = Balanco.heranca_intervalo(heranca_grau) if saiu else 1.0   # sem alvo agora: tenta de novo logo
		if not u.vivo:
			return false
	return true

## Fração da carga do poder do gato (1 = pronto).
func carga_poder(u: Unidade) -> float:
	if u == null or u.poder < 0:
		return 0.0
	return clampf(1.0 - u.poder_cd / Balanco.PODER_INTERVALO, 0.0, 1.0)

## Dispara o poder da fantasia completa. Devolve false se agora não há em quem usar.
func _usar_poder(u: Unidade) -> bool:
	var meus: Array[Unidade] = aliados if u.equipe == 0 else inimigos
	var outros: Array[Unidade] = []
	for v in (inimigos if u.equipe == 0 else aliados):
		if v.vivo and v.x <= Balanco.VISIVEL_X:
			outros.append(v)
	if u.equipe == 1 and u.x > Balanco.VISIVEL_X:
		return false
	var base: float = Balanco.PODER_DANO * u.poder_forca * u.esc_dano
	var pontos: Array = []   # onde o efeito acertou (para o desenho)
	var extra: Dictionary = {}   # campos a mais do evento (teletransporte, enxame)
	match u.poder:
		Pecas.Poder.CURA:
			var ferido: bool = false
			for v in meus:
				if v.vivo and v.vida < v.vida_max * 0.85:
					ferido = true
			if not ferido:
				return false
			for v in meus:
				if v.vivo:
					v.vida = minf(v.vida_max, v.vida + v.vida_max * Balanco.PODER_CURA * _frac_apoio())
					pontos.append(Vector2(v.x, v.y))
		Pecas.Poder.PROTEGE, Pecas.Poder.FRENESI:
			if outros.is_empty():
				return false
			for v in meus:
				if v.vivo:
					if u.poder == Pecas.Poder.PROTEGE:
						v.protegido_t = maxf(v.protegido_t, Balanco.PODER_PROTEGE_T * _frac_apoio())
					else:
						v.frenesi_t = maxf(v.frenesi_t, Balanco.PODER_FRENESI_T * _frac_apoio())
					pontos.append(Vector2(v.x, v.y))
		Pecas.Poder.RAIO:
			var alvo: Unidade = null
			for v in outros:
				if alvo == null or v.vida > alvo.vida:
					alvo = v
			if alvo == null:
				return false
			pontos.append(Vector2(alvo.x, alvo.y))
			_dano_poder(u, alvo, base * Balanco.PODER_RAIO_DANO)
		Pecas.Poder.DRENO:
			var perto: Unidade = _mais_perto(u, outros, Balanco.PODER_DRENO_ALCANCE)
			if perto == null:
				return false
			pontos.append(Vector2(perto.x, perto.y))
			var tirou: float = _dano_poder(u, perto, base * Balanco.PODER_DRENO_DANO)
			u.vida = minf(u.vida_max, u.vida + tirou)
		Pecas.Poder.EXPLOSAO:
			var centro: Unidade = _mais_perto(u, outros, 1e9)
			if centro == null:
				return false
			var cx: float = centro.x
			var cy: float = centro.y
			pontos.append(Vector2(cx, cy))
			for v in outros:
				if _dentro(v, cx, cy, Balanco.PODER_EXPLOSAO_RAIO):
					_dano_poder(u, v, base * Balanco.PODER_EXPLOSAO_DANO)
		Pecas.Poder.RAJADA:
			if outros.is_empty():
				return false
			for k in Balanco.PODER_RAJADA_N:
				var v: Unidade = outros[rng.randi_range(0, outros.size() - 1)]
				if v.vivo:
					pontos.append(Vector2(v.x, v.y))
					_dano_poder(u, v, base * Balanco.PODER_RAJADA_DANO)
		Pecas.Poder.GELO:
			if outros.is_empty():
				return false
			for v in outros:
				v.frio_t = Balanco.PODER_GELO_T
				pontos.append(Vector2(v.x, v.y))
				_dano_poder(u, v, base * Balanco.PODER_GELO_DANO)
		Pecas.Poder.ATRAVESSA:
			var sentido: float = 1.0 if u.equipe == 0 else -1.0
			for v in outros:
				var dx: float = (v.x - u.x) * sentido
				if dx >= -20.0 and dx <= Balanco.PODER_ATRAVESSA_ALCANCE and absf(v.y - u.y) <= Balanco.PODER_ATRAVESSA_LARGURA:
					pontos.append(Vector2(v.x, v.y))
			if pontos.is_empty():
				return false
			for v in outros:
				var dx2: float = (v.x - u.x) * sentido
				if dx2 >= -20.0 and dx2 <= Balanco.PODER_ATRAVESSA_ALCANCE and absf(v.y - u.y) <= Balanco.PODER_ATRAVESSA_LARGURA:
					_dano_poder(u, v, base * Balanco.PODER_ATRAVESSA_DANO)
		Pecas.Poder.INVOCA:
			if u.clone:
				return false
			var fr: float = _frac_apoio()
			for k in Balanco.PODER_INVOCA_N:
				var s: float = -1.0 if k % 2 == 0 else 1.0
				var f := Unidade.new()
				f.equipe = u.equipe
				f.clone = true
				f.dono = u
				f.clone_t = Balanco.PODER_INVOCA_T
				f.linha = u.linha
				f.postura = Boneco.Postura.AVANCAR
				f.familia = u.familia
				f.pecas_visuais = u.pecas.duplicate()
				f.esc_vida = u.esc_vida
				f.esc_dano = u.esc_dano
				calcular(f)
				f.dano = u.dano * Balanco.PODER_INVOCA_DANO * fr
				f.intervalo = u.intervalo
				f.alcance = u.alcance
				f.vel = u.vel
				f.distancia = u.distancia
				f.perfura = u.perfura
				f.vida_max = u.vida_max * Balanco.PODER_INVOCA_VIDA * fr
				f.vida = f.vida_max
				f.x = u.x + s * Balanco.PODER_INVOCA_DIST
				f.y = clampf(u.y + s * 18.0, Balanco.CHAO_Y0, Balanco.CHAO_Y1)
				f.casa_x = f.x
				f.casa_y = f.y
				f.cd = 0.3
				if u.equipe == 0:
					nascidos_aliados.append(f)
				else:
					nascidos.append(f)
				pontos.append(Vector2(f.x, f.y))
		Pecas.Poder.TELEPORTE:
			var fundo: Unidade = null
			for v in outros:
				if fundo == null or (v.x > fundo.x if u.equipe == 0 else v.x < fundo.x):
					fundo = v
			if fundo == null:
				return false
			var sent: float = 1.0 if u.equipe == 0 else -1.0
			extra["x0"] = u.x
			extra["y0"] = u.y
			u.x = maxf(Balanco.TORRE_X + 20.0, fundo.x - sent * Balanco.PODER_TELEPORTE_DIST)
			u.y = fundo.y
			u.vx = -9999.0   # o desenho pula para o lugar novo, sem deslizar
			u.alvo = fundo
			u.protegido_t = maxf(u.protegido_t, Balanco.PODER_TELEPORTE_PROTEGE * _frac_apoio())
			pontos.append(Vector2(fundo.x, fundo.y))
			_dano_poder(u, fundo, base * Balanco.PODER_TELEPORTE_DANO)
		Pecas.Poder.PUXA:
			var presos: Array[Unidade] = []
			for v in outros:
				if _dentro(v, u.x, u.y, Balanco.PODER_PUXA_RAIO):
					presos.append(v)
			if presos.is_empty():
				return false
			var sp: float = 1.0 if u.equipe == 0 else -1.0
			for i in presos.size():
				var v: Unidade = presos[i]
				pontos.append(Vector2(v.x, v.y))
				if not v.chefe and v.tipo != Unidade.Tipo.GIGANTE and not v.fugindo:
					v.x = clampf(u.x + sp * (Balanco.PODER_PUXA_DIST + (i % 3) * 14.0), Balanco.TORRE_X + 20.0, Balanco.VISIVEL_X)
					v.y = clampf(u.y + ((i % 5) - 2) * 20.0, Balanco.CHAO_Y0, Balanco.CHAO_Y1)
					v.vx = -9999.0
					v.alvo = null
				_dano_poder(u, v, base * Balanco.PODER_PUXA_DANO)
		Pecas.Poder.ENXAME:
			var centro_e: Unidade = _mais_perto(u, outros, 1e9)
			if centro_e == null:
				return false
			var sx_e: float = 0.0
			var sy_e: float = 0.0
			var n_e: int = 0
			for v in outros:
				if _dentro(v, centro_e.x, centro_e.y, Balanco.PODER_ENXAME_RAIO * 1.2):
					sx_e += v.x
					sy_e += v.y
					n_e += 1
			var z: Dictionary = {"x": sx_e / n_e, "y": sy_e / n_e, "t": Balanco.PODER_ENXAME_T, "dur": Balanco.PODER_ENXAME_T,
				"raio": Balanco.PODER_ENXAME_RAIO, "dps": base * Balanco.PODER_ENXAME_DPS, "dono": u, "eq": u.equipe}
			zonas.append(z)
			pontos.append(Vector2(z["x"], z["y"]))
			extra["raio"] = z["raio"]
			extra["dur"] = z["dur"]
		Pecas.Poder.ATORDOA, Pecas.Poder.EMPURRA, Pecas.Poder.GIRO:
			var raio: float = Balanco.PODER_GIRO_RAIO
			if u.poder == Pecas.Poder.ATORDOA:
				raio = Balanco.PODER_ATORDOA_RAIO
			elif u.poder == Pecas.Poder.EMPURRA:
				raio = Balanco.PODER_EMPURRA_RAIO
			var perto2: Array[Unidade] = []
			for v in outros:
				if _dentro(v, u.x, u.y, raio):
					perto2.append(v)
			if perto2.is_empty():
				return false
			for v in perto2:
				pontos.append(Vector2(v.x, v.y))
				match u.poder:
					Pecas.Poder.ATORDOA:
						v.atordoado_t = Balanco.PODER_ATORDOA_T * (Balanco.PODER_ATORDOA_CHEFE if v.chefe else 1.0)
						_dano_poder(u, v, base * Balanco.PODER_ATORDOA_DANO)
					Pecas.Poder.EMPURRA:
						if not v.chefe and v.tipo != Unidade.Tipo.GIGANTE:
							if v.equipe == 1:
								v.x = minf(Balanco.VISIVEL_X, v.x + Balanco.PODER_EMPURRA_DIST)
							else:
								v.x = maxf(Balanco.TORRE_X + 20.0, v.x - Balanco.PODER_EMPURRA_DIST * 0.5)
						_dano_poder(u, v, base * Balanco.PODER_EMPURRA_DANO)
					Pecas.Poder.GIRO:
						_dano_poder(u, v, base * Balanco.PODER_GIRO_DANO)
	var evp: Dictionary = {"t": "poder", "x": u.x, "y": u.y, "eq": u.equipe, "poder": u.poder, "conj": u.poder_conj, "pontos": pontos, "heranca": em_heranca, "grau": heranca_grau if em_heranca else 0}
	evp.merge(extra)
	_ev(evp)
	return true

## Enxame: cada nuvem acompanha o grupo e fere, aos poucos, quem está dentro dela.
func _zonas(dt: float) -> void:
	for i in range(zonas.size() - 1, -1, -1):
		var z: Dictionary = zonas[i]
		z["t"] = float(z["t"]) - dt
		if float(z["t"]) <= 0.0:
			zonas.remove_at(i)
			continue
		var dono: Unidade = z["dono"]
		var alvos: Array[Unidade] = inimigos if int(z["eq"]) == 0 else aliados
		var raio: float = float(z["raio"])
		var sx: float = 0.0
		var sy: float = 0.0
		var n: int = 0
		for v in alvos:
			if v.vivo and v.x <= Balanco.VISIVEL_X and _dentro(v, float(z["x"]), float(z["y"]), raio * 1.6):
				sx += v.x
				sy += v.y
				n += 1
		if n > 0:
			var para := Vector2(sx / n - float(z["x"]), sy / n - float(z["y"]))
			var d: float = para.length()
			if d > 0.01:
				var m: float = minf(d, Balanco.PODER_ENXAME_SEGUE * dt)
				z["x"] = float(z["x"]) + para.x / d * m
				z["y"] = float(z["y"]) + para.y / d * m
		for v in alvos:
			if not v.vivo or not _dentro(v, float(z["x"]), float(z["y"]), raio):
				continue
			v.vida -= float(z["dps"]) * dt * v.vulneravel * (Balanco.PODER_PROTEGE_DANO if v.protegido_t > 0.0 else 1.0)
			v.flash = maxf(v.flash, 0.4)
			if v.vida <= 0.0:
				_matar(v, dono if dono != null and dono.vivo else null, Pecas.Marca.CICATRIZ)

## Dano direto de um poder (ignora armadura e esquiva). Devolve o dano causado.
func _dano_poder(u: Unidade, v: Unidade, dano: float) -> float:
	if not v.vivo:
		return 0.0
	var d: float = dano * v.vulneravel * (Balanco.PODER_PROTEGE_DANO if v.protegido_t > 0.0 else 1.0)
	v.vida -= d
	v.flash = 1.0
	_ev({"t": "golpe", "x": v.x, "y": v.y, "dano": d, "eq": v.equipe})
	if v.vida <= 0.0:
		_matar(v, u if u.vivo else null, Pecas.Marca.CICATRIZ)
	return d

func _dentro(v: Unidade, cx: float, cy: float, raio: float) -> bool:
	var dx: float = v.x - cx
	var dy: float = v.y - cy
	return dx * dx + dy * dy <= raio * raio

func _mais_perto(u: Unidade, lista: Array[Unidade], alcance: float) -> Unidade:
	var melhor: Unidade = null
	var md: float = alcance * alcance
	for v in lista:
		var dx: float = v.x - u.x
		var dy: float = v.y - u.y
		var d2: float = dx * dx + dy * dy
		if d2 <= md:
			md = d2
			melhor = v
	return melhor

## Pele de urso (cura) e Casaco (embalo): valem para quem dá o golpe final.
func _ao_abater(k: Unidade) -> void:
	if k.cura_abate > 0.0:
		k.vida = minf(k.vida_max, k.vida + k.vida_max * k.cura_abate)
	if k.embalo_k > 0.0:
		k.embalo = minf(Balanco.CASACO_EMBALO_MAX, k.embalo + k.embalo_k)

## Saco de sementes: quem morre cura todos os companheiros vivos.
func _semear(u: Unidade) -> void:
	var lista: Array[Unidade] = aliados if u.equipe == 0 else inimigos
	for v in lista:
		if v != u and v.vivo:
			v.vida = minf(v.vida_max, v.vida + v.vida_max * u.sementes)
	_ev({"t": "sementes", "x": u.x, "y": u.y, "eq": u.equipe})

## Rei de Massinha morto: desfaz-se em pedaços sem peças.
func _partir(pai: Unidade) -> void:
	for k in Balanco.MASSINHA_PARTES:
		var f := Unidade.new()
		f.equipe = 1
		f.parte = true
		f.familia = pai.familia
		f.esc_vida = pai.esc_vida
		f.esc_dano = pai.esc_dano
		f.x = pai.x + (k - 1) * 14.0
		f.y = clampf(pai.y + (k - 1) * 22.0, Balanco.CHAO_Y0, Balanco.CHAO_Y1)
		calcular(f)
		f.vida_max = pai.vida_max * Balanco.MASSINHA_PARTE_VIDA
		f.vida = f.vida_max
		f.cd = 0.4
		nascidos.append(f)
	_ev({"t": "partes", "x": pai.x, "y": pai.y})

## Gêmeo morto: dois pequenos sem peças, cada um com GEMEO_VIDA da vida máxima dele.
func _nascer_gemeos(pai: Unidade) -> void:
	for k in 2:
		var s: float = -1.0 if k == 0 else 1.0
		var f := Unidade.new()
		f.equipe = 1
		f.pequeno = true
		f.familia = pai.familia
		f.esc_vida = pai.esc_vida
		f.esc_dano = pai.esc_dano
		f.x = pai.x + s * 8.0
		f.y = clampf(pai.y + s * 16.0, Balanco.CHAO_Y0, Balanco.CHAO_Y1)
		calcular(f)
		f.vida_max = pai.vida_max * Balanco.GEMEO_VIDA
		f.vida = f.vida_max
		f.cd = 0.4
		nascidos.append(f)
	_ev({"t": "gemeos", "x": pai.x, "y": pai.y})

## Cura do avental e aura da coroa (dentro da mesma equipe).
func _apoio(lista: Array[Unidade], dt: float) -> void:
	for u in lista:
		u.cura_alvo = null
		if not u.vivo:
			continue
		if u.cura > 0.0:
			var melhor: Unidade = null
			var md: float = Balanco.AVENTAL_RAIO * Balanco.AVENTAL_RAIO
			for v in lista:
				if v == u or not v.vivo or v.vida >= v.vida_max - 0.01:
					continue
				var dx: float = v.x - u.x
				var dy: float = v.y - u.y
				var d2: float = dx * dx + dy * dy
				if d2 <= md:
					md = d2
					melhor = v
			if melhor != null:
				melhor.vida = minf(melhor.vida_max, melhor.vida + u.cura * dt)
				u.cura_alvo = melhor
		if u.regen_aura > 0.0:
			var b2: float = Balanco.BANDEIRA_RAIO * Balanco.BANDEIRA_RAIO
			for v in lista:
				if v == u or not v.vivo:
					continue
				var bx: float = v.x - u.x
				var by: float = v.y - u.y
				if bx * bx + by * by <= b2:
					v.vida = minf(v.vida_max, v.vida + u.regen_aura * dt)
		if u.coroa_bonus > 0.0:
			var r2: float = Balanco.COROA_RAIO * Balanco.COROA_RAIO
			for v in lista:
				if v == u or not v.vivo:
					continue
				var ex: float = v.x - u.x
				var ey: float = v.y - u.y
				if ex * ex + ey * ey <= r2:
					v.bonus_dano = maxf(v.bonus_dano, 1.0 + u.coroa_bonus)

## Barril: explode quando o dono morre, ferindo os inimigos dele. Não credita ninguém.
func _explodir(u: Unidade) -> void:
	var lista: Array[Unidade] = inimigos if u.equipe == 0 else aliados
	_ev({"t": "explosao", "x": u.x, "y": u.y, "raio": Balanco.BARRIL_RAIO, "eq": u.equipe})
	var r2: float = Balanco.BARRIL_RAIO * Balanco.BARRIL_RAIO
	for v in lista:
		if not v.vivo:
			continue
		var dx: float = v.x - u.x
		var dy: float = v.y - u.y
		if dx * dx + dy * dy > r2:
			continue
		var d: float = u.barril_dano * v.fraq_explosao * v.vulneravel
		v.vida -= d
		v.flash = 1.0
		_ev({"t": "golpe", "x": v.x, "y": v.y, "dano": d, "eq": v.equipe})
		if v.vida <= 0.0:
			_matar(v, null, Pecas.Marca.POLVORA)

func _creditar(k: Unidade) -> void:
	var subiu: bool = false
	for p in k.pecas:
		if p != null:
			if p.creditar_abate():
				subiu = true
				_ev({"t": "nivel", "x": k.x, "y": k.y, "tipo": p.tipo, "nivel": p.nivel})
	if subiu:
		calcular(k)
	if k.saque > 0.0 and rng.randf() < k.saque:
		estado.tijolos += 1  # Chapéu de pirata
		_ev({"t": "saque", "x": k.x, "y": k.y})

# ---------------------------------------------------------------- ficha em números (guarda-roupa e luta)
## Unidade calculada do boneco como ele entraria na luta agora (peças, fantasia, treino), sem luta nenhuma.
static func ficha_de(e: Estado, b: Boneco) -> Unidade:
	var s := Simulacao.new()
	s.estado = e
	var u := Unidade.new()
	u.equipe = 0
	u.boneco = b
	u.pecas = b.pecas.duplicate()
	u.linha = b.linha
	u.postura = b.postura_atual()
	u.herancas = b.herancas.duplicate()
	u.heranca_graus = b.graus.duplicate()
	u.atr = b.atr.duplicate()
	s.calcular(u)
	u.vida = u.vida_max
	return u

## Número curto com vírgula decimal: 12 / 12,5 / 0,75.
static func num(v: float, casas: int = 1) -> String:
	var t: String = String.num(v, casas)
	if t.contains("."):
		t = t.rstrip("0").rstrip(".")
	return t.replace(".", ",")

static func pct(v: float) -> String:
	return "%d%%" % int(round(v * 100.0))

## Atributos puros de uma unidade, em pares [nome, valor]. Os quatro primeiros existem sempre;
## o resto só aparece quando a unidade tem aquilo.
static func ficha_linhas(u: Unidade) -> Array:
	var gps: float = 1.0 / maxf(u.intervalo, 0.01)
	var l: Array = [
		["Vida", "%d / %d" % [int(ceil(maxf(u.vida, 0.0))), int(round(u.vida_max))] if u.vida < u.vida_max - 0.5 else str(int(round(u.vida_max)))],
		["Dano por golpe", num(u.dano)],
		["Golpes por segundo", num(gps, 2)],
		["Dano por segundo", num(u.dano * gps)],
		["Alcance", "%d%s" % [int(round(u.alcance)), " (atira)" if u.distancia else ""]],
		["Velocidade", str(int(round(u.vel)))],
	]
	if u.armadura > 0.0:
		l.append(["Armadura", "-%s por golpe" % num(u.armadura)])
	if u.reducao > 0.0:
		l.append(["Redução de dano", pct(u.reducao)])
	if u.esquiva > 0.0:
		l.append(["Esquiva", pct(u.esquiva)])
	if u.critico > 0.0:
		l.append(["Golpe crítico", pct(u.critico)])
	if u.regen > 0.0:
		l.append(["Regeneração", "%s de vida/s" % num(u.regen)])
	if u.espinho > 0.0:
		l.append(["Espinhos", "%s por golpe levado" % num(u.espinho)])
	if u.roubo > 0.0:
		l.append(["Roubo de vida", pct(u.roubo)])
	if u.cura > 0.0:
		l.append(["Cura em aliado", "%s de vida/s" % num(u.cura)])
	if u.tocha_dps > 0.0:
		l.append(["Queimadura", "%s de dano/s" % num(u.tocha_dps)])
	if u.aura_dano > 0.0:
		l.append(["Aura de dano", "%s de dano/s" % num(u.aura_dano)])
	if u.regen_aura > 0.0:
		l.append(["Aura de cura", "%s de vida/s" % num(u.regen_aura)])
	if u.coroa_bonus > 0.0:
		l.append(["Aura de força", "+%s de dano" % pct(u.coroa_bonus)])
	if u.aura_raio > 0.0:
		l.append(["Aura de lentidão", "bichos a %s" % pct(u.aura_lentidao)])
	if u.furia_k > 0.0:
		l.append(["Fúria", "até +%s de dano ferido" % pct(u.furia_k)])
	if u.cerco > 0.0:
		l.append(["Golpe em área", "%s nos vizinhos" % pct(u.cerco)])
	if u.barril_dano > 0.0:
		l.append(["Explosão ao cair", num(u.barril_dano)])
	if u.barreira_int > 0.0:
		l.append(["Barreira", "a cada %s s" % num(u.barreira_int)])
	if u.atordoa_chance > 0.0:
		l.append(["Atordoar no golpe", pct(u.atordoa_chance)])
	if u.gelo_chance > 0.0:
		l.append(["Deixar lento no golpe", pct(u.gelo_chance)])
	return l

## Nome da herança: o poder e a fantasia de onde veio.
static func heranca_nome(conj: int, grau: int = 1) -> String:
	var c: int = clampi(conj, 0, Pecas.PODER_NOME.size() - 1)
	return "%s (%s)" % [heranca_nome_curto(c, grau), Pecas.CONJUNTO_NOME[c]]

## "Relâmpago" no grau I, "Relâmpago II" a partir do grau II.
static func heranca_nome_curto(conj: int, grau: int = 1) -> String:
	var c: int = clampi(conj, 0, Pecas.PODER_NOME.size() - 1)
	return Pecas.PODER_NOME[c] + ("" if grau <= 1 else " " + Balanco.heranca_grau_romano(grau))
