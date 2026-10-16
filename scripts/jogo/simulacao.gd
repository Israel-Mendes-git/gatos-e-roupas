class_name Simulacao
extends RefCounted
## Lógica de combate pura (sem desenho). Usada pelo jogo e pelo simulador headless.

var estado: Estado
var aliados: Array[Unidade] = []
var inimigos: Array[Unidade] = []
var fila: Array = []
var nascidos: Array[Unidade] = []
var gatos_por_poder_bicho: int = 0   # gatos derrubados por poder de bicho (dica da tela de derrota)
var perdas: Dictionary = {}   # blocos tirados da torre por tipo de bicho ("chefe" para chefe), para a tela de derrota
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
var fosso_cd: float = Torre.FOSSO_INTERVALO
var reforco_usados: int = 0   # golpes na torre já absorvidos pelo Reforço nesta onda
## Alvo prioritário do time, escolhido na preparação: -1 nenhum, 0..4 um Unidade.Tipo, ou PRIO_ELITE / PRIO_CHEFE.
const PRIO_ELITE := 10
const PRIO_CHEFE := 11
var prioridade: int = -1
const ESTR_TORRE := 0   # Unidade.estr_tipo: torre de ervilha (atira) ou bloco do Construir (provoca e explode)
const ESTR_BLOCO := 1
var caidos: Array = []   # gatos derrubados nesta luta, para o Reviver: {u, t, x, y, causa, marcas: [[peca, era_nova]]}
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
		u.disfarcado = u.disfarce_atordoa > 0.0   # a onda começa disfarçado
		u.vida = u.vida_max * (b.saude if Balanco.FERIDA_PERSISTE else 1.0)
		aliados.append(u)
	if e.tem_modulo(Torre.Modulo.CASINHA):
		var cao := Unidade.new()
		cao.equipe = 0
		cao.clone = true
		cao.cao = true
		cao.clone_t = 99999.0
		cao.postura = Boneco.Postura.SEGURAR
		cao.vida_max = Torre.CASINHA_VIDA
		cao.vida = Torre.CASINHA_VIDA
		cao.dano = Torre.CASINHA_DANO
		cao.intervalo = Torre.CASINHA_INTERVALO
		cao.vel = Torre.CASINHA_VEL
		cao.alcance = Balanco.BASE_ALCANCE
		cao.x = Balanco.TORRE_X + 40.0
		cao.y = (Balanco.CHAO_Y0 + Balanco.CHAO_Y1) * 0.5
		cao.casa_x = Balanco.RECUAR_X + 40.0
		cao.casa_y = cao.y
		cao.linha = Boneco.Linha.MEIO
		aliados.append(cao)
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
	u.apara = 0.0
	u.critico = 0.0
	u.saque = 0.0
	u.aura_dano = 0.0
	u.cura_abate = 0.0
	u.embalo_k = 0.0
	u.barreira_int = 0.0
	u.disfarce_atordoa = 0.0
	u.disfarce_garra = false
	u.regen_aura = 0.0
	u.sementes = 0.0
	u.cantil = 0.0
	u.roubo = 0.0
	u.recarga_menos = 0.0
	u.tiro_duplo = 0.0
	u.atordoa_chance = 0.0
	var vel_kit: float = 0.0
	var gelo_kit: float = 0.0
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
		var kv: float = Balanco.conj_valor(c, g)
		match Pecas.CONJUNTO_MOLDE[c]:
			Pecas.Conjunto.CAVALEIRO:
				u.armadura += kv
			Pecas.Conjunto.GUARDIAO:
				vida_mult += kv
			Pecas.Conjunto.REI:
				u.coroa_bonus += kv
			Pecas.Conjunto.CIRCO:
				u.barril_dano += kv
			Pecas.Conjunto.VIKING:
				dano_mult += kv
			Pecas.Conjunto.JARDINEIRO:
				u.regen += kv
			Pecas.Conjunto.CAUBOI:
				rapidez += kv
			Pecas.Conjunto.PIRATA:
				u.roubo += kv
			Pecas.Conjunto.MAGO:
				u.tocha_dps += kv
			Pecas.BONUS_CANTIL:
				u.cantil += kv
			Pecas.BONUS_CRITICO:
				u.critico = minf(Balanco.CRITICO_MAX, u.critico + kv)
			Pecas.BONUS_BARREIRA:
				if g == 1:
					# Mimiau completo: Disfarce (kv = segundos de atordoamento; o bicho fantasiado atordoa menos)
					u.disfarce_atordoa = kv * (Balanco.DISFARCE_BICHO_FATOR if u.equipe == 1 else 1.0)
					u.disfarce_garra = u.equipe == 0
					if u.equipe == 0:
						dano_mult += Balanco.DISFARCE_KIT_DANO
						u.critico = minf(Balanco.CRITICO_MAX, u.critico + Balanco.DISFARCE_KIT_CRIT)
					kv = Balanco.conj_valor(c, 0)   # o kit completo também mantém a barreira do kit parcial
				u.barreira_int = kv if u.barreira_int <= 0.0 else minf(u.barreira_int, kv)
			Pecas.BONUS_CARGA:
				u.recarga_menos += kv
			Pecas.BONUS_TIRO_DUPLO:
				u.tiro_duplo += kv
			Pecas.BONUS_ESCORREGA:
				gelo_kit += kv
			Pecas.BONUS_AURA_REGEN:
				u.regen_aura += kv
			Pecas.BONUS_SEMENTES:
				u.sementes += kv
			Pecas.BONUS_ATORDOA:
				u.atordoa_chance += kv
			Pecas.BONUS_CHIFRES:
				u.furia_k += kv
			Pecas.BONUS_VELOCIDADE:
				vel_kit += kv
			Pecas.BONUS_APARA:
				u.apara += kv
	if u.equipe == 0 and Pecas.Conjunto.MIMIAU in u.herancas:
		u.disfarce_atordoa = maxf(u.disfarce_atordoa, Balanco.DISFARCE_HER_ATORDOA)   # herança: o Disfarce, mais fraco
	if u.equipe == 1:
		# poder de bicho: só fantasiado com a fantasia completa (já em u.poder) e chefe (poder fixo por chefe)
		if u.chefe and u.chefe_tipo >= 0:
			var cj: int = Balanco.CHEFE_PODER_CONJ[u.chefe_tipo]
			u.poder = Pecas.PODER_TIPO[cj]
			u.poder_conj = cj
		elif not u.elite or u.poder in Pecas.PODER_SO_GATO:
			u.poder = -1   # o fantasiado só ganha o bônus de kit
			u.poder_conj = -1
	if u.equipe == 0 and u.poder == Pecas.Poder.IMITAR:
		u.recarga_menos += Balanco.PODER_IMITAR_RECARGA
	u.gelo_chance = gelo_kit
	u.furo = minf(u.furo, Balanco.MARCA_FURO_MAX)
	u.esquiva = minf(u.esquiva, Balanco.ESQUIVA_MAX)
	u.roubo = minf(u.roubo, Balanco.ROUBO_MAX)
	vida *= vida_mult
	dano *= dano_mult
	inter /= 1.0 + rapidez
	vel *= 1.0 + vel_kit
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
	u.disfarcado = u.disfarce_atordoa > 0.0
	u.furioso_t = 0.0
	u.vida = u.vida_max
	u.cd = rng.randf_range(0.0, 0.5)
	u.poder_cd = Balanco.PODER_CHEFE_PRIMEIRO if chefe else Balanco.PODER_INIMIGO_PRIMEIRO + rng.randf_range(0.0, 4.0)
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
	_limpar_estruturas()
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
		if not a.vivo or a.chefe or a.fugindo or a.estrutura or a.tipo == Unidade.Tipo.SALTADOR:
			continue
		for j in range(i + 1, n):
			var b: Unidade = lista[j]
			if not b.vivo or b.chefe or b.fugindo or b.estrutura or b.tipo == Unidade.Tipo.SALTADOR:
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
			if a.atordoado_t <= 0.0 and a.preso_t <= 0.0:
				a.x -= sx * f * 0.35
				a.y = clampf(a.y - sy * f, Balanco.CHAO_Y0, Balanco.CHAO_Y1)
			if b.atordoado_t <= 0.0 and b.preso_t <= 0.0:
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
	var luneta: bool = estado.tem_modulo(Torre.Modulo.LUNETA)
	var alvo_prio: Unidade = null
	for v in inimigos:
		if v.vivo and v.x - Balanco.TORRE_X <= Balanco.TORRE_TIRO_ALCANCE:
			if alvo == null or v.x < alvo.x:
				alvo = v
			if luneta and prioritario(v) and (alvo_prio == null or v.x < alvo_prio.x):
				alvo_prio = v
	if alvo == null:
		return
	if alvo_prio != null:
		alvo = alvo_prio   # Luneta: a torre também enxerga a ordem de alvo prioritário
	torre_cd = Balanco.TORRE_TIRO_INTERVALO
	var dano: float = estado.torre_dano()
	if luneta:
		if rng.randf() < Torre.LUNETA_CRITICO:
			dano *= 2.0
			_ev({"t": "luneta_crit", "x": alvo.x, "y": alvo.y})
		if alvo.marcado_t <= 0.0:
			alvo.marcado_t = Torre.LUNETA_MARCA_T
			alvo.marcado_bonus = Torre.LUNETA_MARCA
			alvo.marcado_conj = -1
			_ev({"t": "luneta", "x": alvo.x, "y": alvo.y})
	projeteis.append({"x": Balanco.TORRE_X - 70.0, "y": Balanco.CHAO_Y0 + 20.0, "alvo": alvo, "dono": null, "dano": dano, "torre": true})

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
	if estado.tem_modulo(Torre.Modulo.FOSSO):
		fosso_cd -= dt
		if fosso_cd <= 0.0:
			var perto: Unidade = null
			for v in inimigos:
				if v.vivo and not v.chefe and v.tipo != Unidade.Tipo.GIGANTE and not v.fugindo and v.x <= Balanco.VISIVEL_X and (perto == null or v.x < perto.x):
					perto = v
			if perto != null:
				fosso_cd = Torre.FOSSO_INTERVALO
				perto.atordoado_t = maxf(perto.atordoado_t, Torre.FOSSO_T)
				perto.vida -= Torre.FOSSO_DANO * _vul(perto)
				perto.flash = 1.0
				_ev({"t": "fosso", "x": perto.x, "y": perto.y})
				_ev({"t": "golpe", "x": perto.x, "y": perto.y, "dano": Torre.FOSSO_DANO * _vul(perto), "eq": 1})
				if perto.vida <= 0.0:
					_matar(perto, null, Pecas.Marca.CICATRIZ)
	if estado.tem_modulo(Torre.Modulo.REPELENTE):
		for v in inimigos:
			if v.vivo and v.x - Balanco.TORRE_X <= Torre.REPELENTE_RAIO:
				v.lento = minf(v.lento, Torre.REPELENTE_LENTO)
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
						v.vida -= Torre.CATAPULTA_DANO * _vul(v)
						v.flash = 1.0
						_ev({"t": "golpe", "x": v.x, "y": v.y, "dano": Torre.CATAPULTA_DANO * _vul(v), "eq": 1})
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
		if u.manteiga_t > 0.0:
			u.manteiga_t -= dt
			u.lento = minf(u.lento, Balanco.PODER_MANTEIGA_LENTO)

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
				v.vida -= u.aura_dano * dt * _vul(v)
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

## Fumaça: quem está oculto só é visto por chefe bem de perto.
func _enxerga_oculto(u: Unidade, v: Unidade) -> bool:
	if not u.chefe:
		return false
	var dx: float = v.x - u.x
	var dy: float = v.y - u.y
	return dx * dx + dy * dy <= Balanco.FUMACA_CHEFE_VISAO * Balanco.FUMACA_CHEFE_VISAO

## Multiplicador de dano recebido: fraqueza do chefe x marca do Alvo travado.
func _vul(v: Unidade) -> float:
	return v.vulneravel * ((1.0 + v.marcado_bonus) if v.marcado_t > 0.0 else 1.0) * ((1.0 + v.foco_bonus) if v.foco_t > 0.0 else 1.0)

func _escolher(u: Unidade) -> Unidade:
	# saltador e ladrão ignoram os bonecos e vão direto à torre
	if u.equipe == 1 and (u.tipo == Unidade.Tipo.SALTADOR or u.tipo == Unidade.Tipo.LADRAO):
		return null
	if u.equipe == 1 and u.forcado_t > 0.0 and u.forcado_alvo != null and u.forcado_alvo.vivo:
		return u.forcado_alvo   # Lobo solitário: só enxerga o Rafamiau
	if u.equipe == 0:
		for v in inimigos:
			if v.vivo and v.foco_t > 0.0 and v.x <= Balanco.VISIVEL_X:
				return v   # Plano de ataque: o time inteiro foca o alvo marcado
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
		if v.oculto_t > 0.0 and not _enxerga_oculto(u, v):
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
			if u.estrutura:
				_estrutura_cai(u)
			_ev({"t": "clone_fim", "x": u.x, "y": u.y, "eq": u.equipe, "tempo": true})
			return
	u.flash = maxf(0.0, u.flash - dt * 5.0)
	u.golpe = maxf(0.0, u.golpe - dt)
	u.cd -= dt * u.lento * (2.0 if u.frenesi_t > 0.0 else 1.0)
	u.frenesi_t = maxf(0.0, u.frenesi_t - dt)
	u.protegido_t = maxf(0.0, u.protegido_t - dt)
	if u.estrutura:
		_estrutura_age(u, dt)
		return
	u.preso_t = maxf(0.0, u.preso_t - dt)
	u.marcado_t = maxf(0.0, u.marcado_t - dt)
	u.oculto_t = maxf(0.0, u.oculto_t - dt)
	u.furor_t = maxf(0.0, u.furor_t - dt)
	u.bola_t = maxf(0.0, u.bola_t - dt)
	u.disfarce_rasgou_t += dt
	u.furioso_t = maxf(0.0, u.furioso_t - dt)
	if u.disfarce_rearma_t > 0.0:
		u.disfarce_rearma_t -= dt
		if u.disfarce_rearma_t <= 0.0 and not u.disfarcado:
			u.disfarcado = true
			_ev({"t": "disfarce_refaz", "x": u.x, "y": u.y})
	u.buff_dano_t = maxf(0.0, u.buff_dano_t - dt)
	u.foco_t = maxf(0.0, u.foco_t - dt)
	u.domo_t = maxf(0.0, u.domo_t - dt)
	u.forcado_t = maxf(0.0, u.forcado_t - dt)
	if u.bola_t > 0.0:
		u.atordoado_t = 0.0   # Bola de espinhos: ninguém atordoa
	u.barreira_cd = maxf(0.0, u.barreira_cd - dt)
	if u.queima_t > 0.0:
		u.queima_t -= dt
		u.sono_t = 0.0
		u.vida -= u.queima_dps * dt * u.fraq_fogo * _vul(u)
		if u.vida <= 0.0:
			var fonte: Unidade = u.queima_fonte
			_matar(u, fonte if fonte != null and fonte.vivo else null, Pecas.Marca.BRASA)
			return
	if u.lobo_t > 0.0:
		_lobo_tick(u, dt)
	if u.esforco_t > 0.0:
		u.esforco_t -= dt
		var antes_e: float = u.vida
		u.vida = minf(u.vida_max, u.vida + u.vida_max * u.esforco_regen * dt)
		_tele(u.esforco_conj, "cura", u.vida - antes_e)
		u.bonus_dano *= 1.0 + Balanco.PODER_ESFORCO_DANO
	if u.cochilo_t > 0.0:
		u.cochilo_t -= dt
		u.atordoado_t = 0.0
		u.andando = false
		u.vida = minf(u.vida_max, u.vida + u.vida_max * u.cochilo_cura * dt)
		return
	if u.sono_t > 0.0:
		u.sono_t -= dt
		u.andando = false
		if u.aviso_t > 0.0:
			u.aviso_t = 0.0
			u.aviso_forma = {}
			u.poder_cd = maxf(u.poder_cd, Balanco.PODER_INIMIGO_INTERROMPIDO)
			_ev({"t": "aviso_cortado", "x": u.x, "y": u.y})
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
		if u.aviso_t > 0.0:
			u.aviso_t = 0.0   # atordoado no meio da carga: o poder se perde
			u.aviso_forma = {}
			u.poder_cd = maxf(u.poder_cd, Balanco.PODER_INIMIGO_INTERROMPIDO)
			_ev({"t": "aviso_cortado", "x": u.x, "y": u.y})
		return
	if u.chefe and not _chefe_age(u, dt):
		return
	if u.equipe == 1 and u.poder >= 0:
		if not _poder_de_bicho(u, dt):
			return
	elif u.poder >= 0:
		u.poder_cd -= dt
		u.poder_pronto = u.poder_cd <= 0.0
		if u.poder_pronto and not (poder_manual and u.equipe == 0) and _usar_poder(u):
			u.poder_cd = _intervalo_poder(u)
			u.poder_cd_menos = 0.0
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
	if u.alvo != null and u.alvo.oculto_t > 0.0 and not _enxerga_oculto(u, u.alvo):
		u.alvo = null   # Fumaça: perdeu o alvo de vista
	if u.alvo == null or not u.alvo.vivo or u.retarget <= 0.0:
		u.alvo = _escolher(u)
		u.retarget = Balanco.RETARGET
	u.andando = false
	var mvel: float = u.vel * (u.bola_vel if u.bola_t > 0.0 else 1.0) * (0.0 if u.preso_t > 0.0 else 1.0)
	var a: Unidade = u.alvo
	if a != null:
		var dx: float = a.x - u.x
		var dy: float = a.y - u.y
		var d: float = sqrt(dx * dx + dy * dy)
		if d <= u.alcance:
			if u.cd <= 0.0:
				_atacar(u, a)
		else:
			var passo: float = minf(mvel * u.lento * dt, d - u.alcance * 0.85)
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
			var pv: float = minf(mvel * u.lento * dt * (Balanco.LINHA_CORRIDA if cd2 > Balanco.LINHA_CORRIDA_DIST else 1.0), cd2)
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
			u.x -= mvel * u.lento * dt * (Balanco.ENTRADA_VEL if u.x > Balanco.ENTRADA_X else 1.0)
			u.andando = true

func _atacar(u: Unidade, a: Unidade) -> void:
	if u.equipe == 1 and u.tipo == Unidade.Tipo.BOMBA and not u.chefe:
		_matar(u, null, Pecas.Marca.POLVORA)   # a bomba não bate: encosta e explode
		return
	u.cd = u.intervalo / ((1.0 + Balanco.DISFARCE_FURIA_VEL) if u.furioso_t > 0.0 else 1.0)
	u.golpe = 0.22
	var dm: float = u.dano * u.bonus_dano * (1.0 + u.furia_k * u.furia) * (1.0 + u.embalo) * (1.0 + (u.buff_dano if u.buff_dano_t > 0.0 else 0.0))
	if u.disfarce_garra:
		if u.disfarcado:
			dm *= 1.0 + Balanco.DISFARCE_GARRA   # Garra Sombria
		elif u.furioso_t > 0.0:
			dm *= 1.0 + Balanco.DISFARCE_FURIA_DANO   # Furioso
	if u.critico > 0.0 and rng.randf() < u.critico:
		dm *= Balanco.CARTOLA_MULT
		_ev({"t": "critico", "x": a.x, "y": a.y})
	if u.distancia:
		projeteis.append({"x": u.x, "y": u.y, "alvo": a, "dono": u, "dano": dm})
		if u.tiro_duplo > 0.0 and rng.randf() < u.tiro_duplo:
			projeteis.append({"x": u.x, "y": u.y - 7.0, "alvo": a, "dono": u, "dano": dm})
		_ev({"t": "tiro", "x": u.x, "y": u.y, "eq": u.equipe})
	else:
		_dano(u, a, dm, true)
		if u.atordoa_chance > 0.0 and a.vivo and not a.chefe and rng.randf() < u.atordoa_chance:
			a.atordoado_t = maxf(a.atordoado_t, Balanco.ATORDOA_KIT_T)
		var cerco: float = u.cerco + (u.furor_cerco if u.furor_t > 0.0 else 0.0)
		if cerco > 0.0 and u.vivo:
			_golpe_em_area(u, a, dm * cerco)

## Ladrão com a carga: corre de volta à borda direita; fora da tela, os tijolos se perdem.
func _fugir(u: Unidade, dt: float) -> void:
	if u.preso_t > 0.0:
		u.andando = false   # Teia: não foge
		return
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
		u.golpe = 0.0
	if estado.tem_modulo(Torre.Modulo.REFORCO) and n > 0:
		if reforco_usados < Torre.REFORCO_GOLPES:
			reforco_usados += 1
			n = 0
			_ev({"t": "reforco", "x": u.x, "y": u.y})
		elif u.chefe:
			n = mini(n, Torre.REFORCO_CHEFE_MAX)
	n = mini(n, estado.tijolos)
	if u.tipo == Unidade.Tipo.LADRAO and not u.chefe:
		u.carga = n
	var kp: Variant = "chefe" if u.chefe else u.tipo
	perdas[kp] = int(perdas.get(kp, 0)) + n
	estado.tijolos -= n
	_ev({"t": "torre", "n": n, "x": u.x, "y": u.y})
	if u.tipo == Unidade.Tipo.BOMBA and not u.chefe and u.vivo:
		_matar(u, null, Pecas.Marca.POLVORA)   # explode na torre e some
		return
	if estado.tem_modulo(Torre.Modulo.RATOEIRA) and u.vivo and not u.distancia and not u.fugindo:
		_ev({"t": "ratoeira", "x": u.x, "y": u.y})
		u.vida -= Torre.RATOEIRA_DANO * _vul(u)
		u.flash = 1.0
		_ev({"t": "golpe", "x": u.x, "y": u.y, "dano": Torre.RATOEIRA_DANO * _vul(u), "eq": 1})
		if u.vida <= 0.0:
			_matar(u, null, Pecas.Marca.CICATRIZ)

func _mover_projeteis(dt: float) -> void:
	for i in range(projeteis.size() - 1, -1, -1):
		var p: Dictionary = projeteis[i]
		if not p.has("refletido") and not p.has("poder") and not p.has("torre"):
			_domo_reflete(p)
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
			elif p.has("poder"):
				_acerta_ervilha(p, a)
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
	if alvo.apara > 0.0 and corpo_a_corpo and not em_area and atk != null and atk.vivo and rng.randf() < alvo.apara:
		_apara_faca(alvo, atk)   # Aparar com a faca (kit do Meon): o golpe some e volta como facada
		return
	if alvo.disfarcado and atk != null:
		# Disfarce (Mimiau): o 1º golpe some, o pano rasga e quem bateu leva um susto (chefe, menos)
		alvo.disfarcado = false
		alvo.disfarce_rasgou_t = 0.0
		alvo.disfarce_rearma_t = Balanco.DISFARCE_REARMA_T
		if atk.vivo and not atk.bola_t > 0.0:
			atk.atordoado_t = maxf(atk.atordoado_t, alvo.disfarce_atordoa * (Balanco.DISFARCE_CHEFE_FATOR if atk.chefe else 1.0))
		alvo.protegido_t = maxf(alvo.protegido_t, Balanco.DISFARCE_PROTEGE)
		if alvo.disfarce_garra:
			alvo.furioso_t = Balanco.DISFARCE_FURIA_T
		if atk.vivo:
			_dano_poder(alvo, atk, Balanco.PODER_DANO * alvo.esc_dano * Balanco.DISFARCE_REVIDE * (Balanco.DISFARCE_BICHO_FATOR if alvo.equipe == 1 else 1.0))
		var rivais: Array[Unidade] = inimigos if alvo.equipe == 0 else aliados
		for v in rivais:
			if v.vivo and v != atk and not v.chefe and _dentro(v, alvo.x, alvo.y, Balanco.DISFARCE_SUSTO_RAIO):
				v.atordoado_t = maxf(v.atordoado_t, Balanco.DISFARCE_SUSTO_T)
		_ev({"t": "disfarce_rasga", "x": alvo.x, "y": alvo.y, "eq": alvo.equipe})
		return
	var d: float
	if atk != null and atk.perfura:
		d = maxf(Balanco.DANO_MINIMO, dano)  # Varinha: ignora armadura e redução
	else:
		d = maxf(Balanco.DANO_MINIMO, dano - alvo.armadura - (alvo.domo_arm if alvo.domo_t > 0.0 else 0.0)) * (1.0 - alvo.reducao)
	if corpo_a_corpo:
		d *= alvo.fraq_corpo
	else:
		d *= 1.0 - alvo.furo
	d *= _vul(alvo)
	if alvo.protegido_t > 0.0:
		d *= Balanco.PODER_PROTEGE_DANO
	if alvo.cochilo_t > 0.0:
		d *= Balanco.PODER_COCHILO_DANO
	if alvo.lobo_t > 0.0 and alvo.lobo_prov:
		d *= 1.0 - Balanco.PODER_LOBO_REDUCAO
	_tele_marca(alvo, d)
	alvo.vida -= d
	alvo.sono_t = 0.0
	alvo.flash = 1.0
	var sinal: float = -1.0 if alvo.equipe == 0 else 1.0
	if not alvo.chefe and alvo.tipo != Unidade.Tipo.GIGANTE:
		alvo.x += sinal * 6.0
	_ev({"t": "golpe", "x": alvo.x, "y": alvo.y, "dano": d, "eq": alvo.equipe})
	if atk != null and atk.vivo:
		var roubo: float = atk.roubo + (atk.furor_roubo if atk.furor_t > 0.0 else 0.0)
		if roubo > 0.0:
			atk.vida = minf(atk.vida_max, atk.vida + d * roubo)
		if atk.molha or (atk.gelo_chance > 0.0 and rng.randf() < atk.gelo_chance):
			alvo.frio_t = Balanco.REGADOR_DURACAO
	if atk != null and atk.tocha_dps > 0.0 and alvo.vida > 0.0:
		alvo.queima_t = Balanco.TOCHA_DURACAO
		alvo.queima_dps = atk.tocha_dps
		alvo.queima_fonte = atk
	if alvo.vida <= 0.0:
		_matar(alvo, atk, Pecas.Marca.CICATRIZ if corpo_a_corpo else Pecas.Marca.FURO)
	var espinho: float = alvo.espinho + (alvo.bola_espinho if alvo.bola_t > 0.0 else 0.0)
	if corpo_a_corpo and not em_area and espinho > 0.0 and atk.vivo:
		atk.vida -= espinho
		atk.flash = 1.0
		_ev({"t": "golpe", "x": atk.x, "y": atk.y, "dano": espinho, "eq": atk.equipe, "espinho": true})
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
		if u.estrutura:
			_estrutura_cai(u)
		_ev({"t": "clone_fim", "x": u.x, "y": u.y, "eq": u.equipe, "tempo": false})
		return
	if u.esforco_t > 0.0 and not u.esforco_usado:
		_esforco_levanta(u)   # Esforço máximo (Deadmiau): "ainda não!"
		return
	u.vivo = false
	if u.foco_t > 0.0 and u.foco_dono != null and u.foco_dono.vivo and u.foco_recarga > 0.0:
		u.foco_dono.poder_cd -= u.foco_recarga   # Plano de ataque: o alvo caiu, o poder volta mais cedo
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
			var tr: int = Torre.trofeu_chefe(estado.ato) if u.chefe else Torre.TROFEU_ELITE
			estado.trofeus += tr  # moeda das melhorias da torre
			_ev({"t": "trofeu", "x": u.x, "y": u.y, "n": tr})
		_largar(u, causa)
	else:
		if u.boneco != null:
			u.boneco.vivo = false
		# a morte marca cada peça vestida (as mesmas instâncias do Boneco)
		var marcadas: int = 0
		var rec: Array = []
		for p in u.pecas:
			if p != null:
				var era_nova: bool = p.nova
				if p.marcar(causa):
					p.nova = true  # volta destacada ao guarda-roupa
					marcadas += 1
					rec.append([p, era_nova])
		caidos.append({"u": u, "t": tempo, "x": u.x, "y": u.y, "causa": causa, "marcas": rec})
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
	var nivel: int = mini(Balanco.DROP_NIVEL_MAX, int(floor((estado.progresso() - 1) * Balanco.DROP_NIVEL_POR_PROG)))
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
	u.poder_cd = _intervalo_poder(u)
	u.poder_cd_menos = 0.0
	u.poder_pronto = false
	return true

## Fração dos poderes de apoio (cura, proteção, frenesi) quando o disparo é uma herança: sobe com o grau.
func _frac_apoio() -> float:
	return (minf(1.0, Balanco.HERANCA_APOIO * Balanco.heranca_mult(heranca_grau)) if em_heranca else 1.0) * _fi

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

## Intervalo até o próximo poder: o padrão, menos o kit do Jimiau e (se `com_menos`) os segundos tirados por Alvo travado.
func _intervalo_poder(u: Unidade, com_menos: bool = true) -> float:
	return maxf(1.0, Balanco.PODER_INTERVALO * (1.0 - u.recarga_menos) - (u.poder_cd_menos if com_menos else 0.0))

## Fração da carga do poder do gato (1 = pronto).
func carga_poder(u: Unidade) -> float:
	if u == null or u.poder < 0:
		return 0.0
	return clampf(1.0 - u.poder_cd / _intervalo_poder(u, false), 0.0, 1.0)

## Medição por fantasia (só o simulador liga): usos, dano, abates e efeitos de cada poder.
static var medir: bool = false
static var tele: Dictionary = {}
static var tele_i: Dictionary = {}   # idem, dos poderes dos bichos
var _eq_tele: int = 0
var ultimo_conj: int = -1   # fantasia do último poder disparado em campo (o Imitar copia)
var ultimo_t: float = -999.0
var _conj_tele: int = -1   # fantasia cujo poder está agindo agora (para a telemetria)

func _tele(conj: int, chave: String, v: float) -> void:
	if not medir or conj < 0:
		return
	var alvo_t: Dictionary = tele_i if _eq_tele == 1 else tele
	var d: Dictionary = alvo_t.get(conj, {})
	d[chave] = float(d.get(chave, 0.0)) + v
	alvo_t[conj] = d

## O dano extra de um alvo marcado (Alvo travado) conta para o poder que marcou.
func _tele_marca(v: Unidade, d: float) -> void:
	if medir and v.marcado_t > 0.0 and v.marcado_conj >= 0 and v.marcado_bonus > 0.0:
		_tele(v.marcado_conj, "dano", d - d / (1.0 + v.marcado_bonus))

## Dispara o poder da fantasia completa. Devolve false se agora não há em quem usar.
func _usar_poder(u: Unidade) -> bool:
	_conj_tele = u.poder_conj
	_eq_tele = u.equipe
	_fi = _fator_inimigo(u) if u.equipe == 1 else 1.0
	var ok: bool = _usar_poder_i(u)
	if ok:
		if not (u.poder_conj in Pecas.IMITAR_EXCLUI):
			ultimo_conj = u.poder_conj
			ultimo_t = tempo
		_tele(u.poder_conj, "usos_h" if em_heranca else "usos", 1.0)
	_conj_tele = -1
	_eq_tele = 0
	_fi = 1.0
	return ok

## Salvas da Salva de mísseis: cada uma cai no grupo mais perto da torre, depois no seguinte.
func _centros_misseis(alvos: Array) -> Array:
	var perto_t: Array = []
	for v in alvos:
		if v.x - Balanco.TORRE_X <= Balanco.PODER_MISSEIS_ALCANCE:
			perto_t.append(v)
	var centros: Array = []
	perto_t.sort_custom(func(a: Unidade, b: Unidade) -> bool: return a.x < b.x)
	for vm in perto_t:
		if not vm.vivo or centros.size() >= ceili(Balanco.PODER_MISSEIS_N * _frac_apoio()):
			continue
		var livre: bool = true
		for c0 in centros:
			if _dentro(vm, c0.x, c0.y, Balanco.PODER_MISSEIS_RAIO):
				livre = false
		if livre:
			centros.append(Vector2(vm.x, vm.y))
	return centros

# ---------- Poderes de bicho (fantasiado com fantasia completa e chefe) ----------
## Intensidade do poder do bicho em relação ao do gato: menor, e sobe um pouco com o ato.
var _fi: float = 1.0

func _fator_inimigo(u: Unidade) -> float:
	var f: float = Balanco.PODER_INIMIGO_FATOR + Balanco.PODER_INIMIGO_FATOR_ATO * (estado.ato - 1)
	if u.chefe:
		f += Balanco.PODER_INIMIGO_FATOR_CHEFE
	return f

## Relógio do poder de um bicho. Devolve false enquanto ele carrega o aviso (fica parado, sem golpear).
func _poder_de_bicho(u: Unidade, dt: float) -> bool:
	if u.aviso_t > 0.0:
		u.andando = false
		u.aviso_t -= dt
		if u.aviso_t > 0.0:
			return false
		u.aviso_forma = {}
		if _usar_poder(u):
			u.poder_cd = Balanco.PODER_CHEFE_INTERVALO if u.chefe else Balanco.PODER_INIMIGO_INTERVALO
		else:
			u.poder_cd = Balanco.PODER_INIMIGO_SEM_ALVO
		return u.vivo
	u.poder_cd -= dt
	if u.poder_cd > 0.0 or u.x > Balanco.VISIVEL_X:
		return true
	var forma: Dictionary = _forma_aviso(u)
	_fi = 1.0
	if forma.is_empty():
		u.poder_cd = Balanco.PODER_INIMIGO_SEM_ALVO
		return true
	u.aviso_forma = forma
	u.aviso_t = Balanco.PODER_AVISO_T
	u.aviso_dur = Balanco.PODER_AVISO_T
	_ev({"t": "aviso", "x": u.x, "y": u.y, "poder": u.poder, "conj": u.poder_conj, "chefe": u.chefe})
	u.andando = false
	return false

## O que o poder do bicho vai atingir se fosse solto agora (para o aviso). Vazio: nada a atingir, não carrega.
## Espelha a escolha de alvos de `_usar_poder_i`.
func _forma_aviso(u: Unidade) -> Dictionary:
	var gatos: Array[Unidade] = []
	for v in aliados:
		if v.vivo and v.x <= Balanco.VISIVEL_X:
			gatos.append(v)
	if gatos.is_empty():
		return {}
	_fi = _fator_inimigo(u)
	var circ: Array = []
	var ret: Array = []
	var lin: Array = []
	var alvos: Array = []
	var ux: float = u.x
	var uy: float = u.y
	match u.poder:
		Pecas.Poder.ATORDOA, Pecas.Poder.EMPURRA, Pecas.Poder.GIRO, Pecas.Poder.PUXA:
			var raio: float = Balanco.PODER_ATORDOA_RAIO
			if u.poder == Pecas.Poder.EMPURRA:
				raio = Balanco.PODER_EMPURRA_RAIO
			elif u.poder == Pecas.Poder.PUXA:
				raio = Balanco.PODER_PUXA_RAIO
			elif u.poder == Pecas.Poder.GIRO:
				raio = Balanco.PODER_GIRO_RAIO
			for v in gatos:
				if _dentro(v, ux, uy, raio):
					alvos.append(Vector2(v.x, v.y))
			if alvos.is_empty():
				return {}
			circ.append(Vector3(ux, uy, raio))
		Pecas.Poder.RAIO:
			var forte: Unidade = null
			for v in gatos:
				if forte == null or v.vida > forte.vida:
					forte = v
			alvos.append(Vector2(forte.x, forte.y))
		Pecas.Poder.DRENO:
			var perto: Unidade = _mais_perto(u, gatos, Balanco.PODER_DRENO_ALCANCE)
			if perto == null:
				return {}
			alvos.append(Vector2(perto.x, perto.y))
			lin.append([Vector2(ux, uy), Vector2(perto.x, perto.y)])
		Pecas.Poder.RAIZ:
			var ord: Array[Unidade] = gatos.duplicate()
			ord.sort_custom(func(a: Unidade, b: Unidade) -> bool: return (a.x - ux) * (a.x - ux) + (a.y - uy) * (a.y - uy) < (b.x - ux) * (b.x - ux) + (b.y - uy) * (b.y - uy))
			for k in mini(ceili(Balanco.PODER_RAIZ_N * _fi), ord.size()):
				alvos.append(Vector2(ord[k].x, ord[k].y))
		Pecas.Poder.SAQUE:
			var fraco: Unidade = null
			for v in gatos:
				if fraco == null or v.vida < fraco.vida:
					fraco = v
			alvos.append(Vector2(fraco.x, fraco.y))
		Pecas.Poder.GELO:
			for v in gatos:
				alvos.append(Vector2(v.x, v.y))
		Pecas.Poder.TROVOADA:
			for c in _aglomerados(gatos, Balanco.PODER_TROVOADA_RAIO, ceili(Balanco.PODER_TROVOADA_N * _fi)):
				circ.append(Vector3(c.x, c.y, Balanco.PODER_TROVOADA_RAIO))
			if circ.is_empty():
				return {}
		Pecas.Poder.CANHAO:
			var cs: Array = _aglomerados(gatos, Balanco.PODER_CANHAO_RAIO, 1)
			if cs.is_empty():
				return {}
			circ.append(Vector3(cs[0].x, cs[0].y, Balanco.PODER_CANHAO_RAIO))
		Pecas.Poder.MISSEIS:
			for c in _centros_misseis(gatos):
				circ.append(Vector3(c.x, c.y, Balanco.PODER_MISSEIS_RAIO))
			if circ.is_empty():
				return {}
		Pecas.Poder.ENXAME:
			var cen: Unidade = _mais_perto(u, gatos, 1e9)
			var sx: float = 0.0
			var sy: float = 0.0
			var n: int = 0
			for v in gatos:
				if _dentro(v, cen.x, cen.y, Balanco.PODER_ENXAME_RAIO * 1.2):
					sx += v.x
					sy += v.y
					n += 1
			circ.append(Vector3(sx / n, sy / n, Balanco.PODER_ENXAME_RAIO))
		Pecas.Poder.INVESTIDA, Pecas.Poder.MARCA, Pecas.Poder.TURBO:
			var alc: float = Balanco.PODER_ATRAVESSA_ALCANCE
			if u.poder == Pecas.Poder.INVESTIDA:
				alc = Balanco.PODER_INVESTIDA_ALCANCE + 30.0
			elif u.poder == Pecas.Poder.TURBO:
				alc = Balanco.PODER_TURBO_ALCANCE + 30.0
			for v in gatos:
				if ux - v.x >= -20.0 and ux - v.x <= alc and absf(v.y - uy) <= Balanco.PODER_ATRAVESSA_LARGURA:
					alvos.append(Vector2(v.x, v.y))
			if alvos.is_empty():
				return {}
			ret.append(Rect2(ux - alc, uy - Balanco.PODER_ATRAVESSA_LARGURA, alc + 20.0, Balanco.PODER_ATRAVESSA_LARGURA * 2.0))
		Pecas.Poder.TELEPORTE:
			var fundo: Unidade = null
			for v in gatos:
				if fundo == null or v.x < fundo.x:
					fundo = v
			alvos.append(Vector2(fundo.x, fundo.y))
			lin.append([Vector2(ux, uy), Vector2(fundo.x, fundo.y)])
		Pecas.Poder.PISAO:
			var cand: Array = gatos.duplicate()
			var px: float = ux
			var py: float = uy
			for k in Balanco.PODER_PISAO_N:
				var alvo_p: Unidade = null
				for v in cand:
					if _dentro(v, px, py, Balanco.PODER_PISAO_ALCANCE) and (alvo_p == null or v.vida > alvo_p.vida):
						alvo_p = v
				if alvo_p == null:
					break
				cand.erase(alvo_p)
				alvos.append(Vector2(alvo_p.x, alvo_p.y))
				lin.append([Vector2(px, py), Vector2(alvo_p.x, alvo_p.y)])
				px = alvo_p.x + 30.0
				py = alvo_p.y
			if alvos.is_empty():
				return {}
		Pecas.Poder.CANCAO:
			for v in gatos:
				if v.poder >= 0 or not v.heranca_cd.is_empty():
					alvos.append(Vector2(v.x, v.y))
			if alvos.is_empty():
				return {}
		Pecas.Poder.FUMACA:
			circ.append(Vector3(ux, uy, Balanco.PODER_FUMACA_RAIO))
		Pecas.Poder.CANTEIRO:
			var ferido: bool = false
			for v in inimigos:
				if v.vivo and v.vida < v.vida_max * 0.9:
					ferido = true
			if not ferido:
				return {}
			circ.append(Vector3(ux, uy, Balanco.PODER_CANTEIRO_RAIO))
		Pecas.Poder.TRIAGEM:
			var pior: Unidade = null
			for v in inimigos:
				if v.vivo and not v.clone and v.vida < v.vida_max * Balanco.PODER_TRIAGEM_LIMIAR and (pior == null or v.vida / v.vida_max < pior.vida / pior.vida_max):
					pior = v
			if pior == null:
				return {}
			circ.append(Vector3(pior.x, pior.y, 46.0))
		Pecas.Poder.RICOCHETE:
			var alvo_r: Unidade = _mais_perto(u, gatos, Balanco.PODER_RICOCHETE_ALCANCE)
			if alvo_r == null:
				return {}
			alvos.append(Vector2(alvo_r.x, alvo_r.y))
			lin.append([Vector2(ux, uy), Vector2(alvo_r.x, alvo_r.y)])
		Pecas.Poder.OLHAR:
			var forte_o: Unidade = null
			for v in gatos:
				if forte_o == null or v.vida > forte_o.vida:
					forte_o = v
			alvos.append(Vector2(forte_o.x, forte_o.y))
		Pecas.Poder.POQUER:
			var cs_p: Array = _aglomerados(gatos, Balanco.PODER_POQUER_RAIO, 1)
			if cs_p.is_empty():
				return {}
			circ.append(Vector3(cs_p[0].x, cs_p[0].y, Balanco.PODER_POQUER_RAIO))
		Pecas.Poder.PROTEGE, Pecas.Poder.FRENESI:
			for v in inimigos:
				if v.vivo and v.x <= Balanco.VISIVEL_X and not v.clone:
					circ.append(Vector3(v.x, v.y, 34.0))
		Pecas.Poder.INVOCA:
			circ.append(Vector3(ux, uy, 60.0))
		_:
			circ.append(Vector3(ux, uy, 50.0))   # Fúria, Bola de espinhos: ele mesmo
	return {"circ": circ, "ret": ret, "lin": lin, "alvos": alvos}

## Centros dos `n` maiores aglomerados (sem repetir bicho): cada centro é um bicho, contando quem está a `raio` dele.
func _aglomerados(lista: Array, raio: float, n: int) -> Array:
	var livres: Array = []
	for v in lista:
		if v.vivo:
			livres.append(v)
	var centros: Array = []
	for k in n:
		var melhor: Unidade = null
		var mn: int = 0
		for c in livres:
			var cnt: int = 0
			for v in livres:
				if _dentro(v, c.x, c.y, raio):
					cnt += 1
			if cnt > mn:
				mn = cnt
				melhor = c
		if melhor == null:
			break
		centros.append(Vector2(melhor.x, melhor.y))
		var resto: Array = []
		for v in livres:
			if not _dentro(v, melhor.x, melhor.y, raio):
				resto.append(v)
		livres = resto
	return centros

## Canteiro (Jardineiro): cura os aliados dentro e atrasa os inimigos dentro.
func _zona_canteiro(z: Dictionary, dt: float) -> void:
	var eq: int = int(z["eq"])
	var raio: float = float(z["raio"])
	var cx: float = float(z["x"])
	var cy: float = float(z["y"])
	var so: Variant = z.get("so", null)
	for v in (aliados if eq == 0 else inimigos):
		if v.vivo and _dentro(v, cx, cy, raio) and (so == null or v == so):
			var antes: float = v.vida
			v.vida = minf(v.vida_max, v.vida + v.vida_max * float(z["cura"]) * dt)
			_tele(int(z.get("conj", -1)), "cura", v.vida - antes)
	for v in (inimigos if eq == 0 else aliados):
		if v.vivo and _dentro(v, cx, cy, raio):
			v.lento = minf(v.lento, Balanco.PODER_CANTEIRO_LENTO)

## Poder CURA: corpo separado de _usar_poder_i.
func _poder_cura(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
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
	return true

## Poder PROTEGE/FRENESI: corpo separado de _usar_poder_i.
func _poder_protege_frenesi(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	for v in meus:
		if v.vivo:
			if u.poder == Pecas.Poder.PROTEGE:
				v.protegido_t = maxf(v.protegido_t, Balanco.PODER_PROTEGE_T * _frac_apoio())
			else:
				v.frenesi_t = maxf(v.frenesi_t, Balanco.PODER_FRENESI_T * _frac_apoio())
			pontos.append(Vector2(v.x, v.y))
	return true

## Poder RAIO: corpo separado de _usar_poder_i.
func _poder_raio(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var alvo: Unidade = null
	for v in outros:
		if alvo == null or v.vida > alvo.vida:
			alvo = v
	if alvo == null:
		return false
	pontos.append(Vector2(alvo.x, alvo.y))
	_dano_poder(u, alvo, base * Balanco.PODER_RAIO_DANO)
	return true

## Poder DRENO: corpo separado de _usar_poder_i.
func _poder_dreno(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var perto: Unidade = _mais_perto(u, outros, Balanco.PODER_DRENO_ALCANCE)
	if perto == null:
		return false
	pontos.append(Vector2(perto.x, perto.y))
	var tirou: float = _dano_poder(u, perto, base * Balanco.PODER_DRENO_DANO)
	u.vida = minf(u.vida_max, u.vida + tirou)
	return true

## Poder EXPLOSAO: corpo separado de _usar_poder_i.
func _poder_explosao(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var centro: Unidade = _mais_perto(u, outros, 1e9)
	if centro == null:
		return false
	var cx: float = centro.x
	var cy: float = centro.y
	pontos.append(Vector2(cx, cy))
	for v in outros:
		if _dentro(v, cx, cy, Balanco.PODER_EXPLOSAO_RAIO):
			_dano_poder(u, v, base * Balanco.PODER_EXPLOSAO_DANO)
	return true

## Poder RAJADA: corpo separado de _usar_poder_i.
func _poder_rajada(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	for k in Balanco.PODER_RAJADA_N:
		var v: Unidade = outros[rng.randi_range(0, outros.size() - 1)]
		if v.vivo:
			pontos.append(Vector2(v.x, v.y))
			_dano_poder(u, v, base * Balanco.PODER_RAJADA_DANO)
	return true

## Poder GELO: corpo separado de _usar_poder_i.
func _poder_gelo(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	for v in outros:
		v.frio_t = Balanco.PODER_GELO_T * _fi
		pontos.append(Vector2(v.x, v.y))
		_dano_poder(u, v, base * Balanco.PODER_GELO_DANO)
	return true

## Poder ATRAVESSA: corpo separado de _usar_poder_i.
func _poder_atravessa(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
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
	return true

## Poder INVOCA: corpo separado de _usar_poder_i.
func _poder_invoca(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
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
	return true

## Poder TELEPORTE: corpo separado de _usar_poder_i.
func _poder_teleporte(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
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
	return true

## Poder PUXA: corpo separado de _usar_poder_i.
func _poder_puxa(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
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
	return true

## Poder ENXAME: corpo separado de _usar_poder_i.
func _poder_enxame(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
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
	return true

## Poder RAIZ: corpo separado de _usar_poder_i.
func _poder_raiz(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	var ord: Array[Unidade] = outros.duplicate()
	if u.equipe == 0:
		ord.sort_custom(func(a: Unidade, b: Unidade) -> bool: return a.x < b.x)   # os mais perto da torre
	else:
		ord.sort_custom(func(a: Unidade, b: Unidade) -> bool: return (a.x - u.x) * (a.x - u.x) + (a.y - u.y) * (a.y - u.y) < (b.x - u.x) * (b.x - u.x) + (b.y - u.y) * (b.y - u.y))
	for k in mini(ceili(Balanco.PODER_RAIZ_N * _frac_apoio()), ord.size()):
		var v: Unidade = ord[k]
		v.preso_t = maxf(v.preso_t, Balanco.PODER_RAIZ_T * _frac_apoio() * (Balanco.PODER_RAIZ_CHEFE if v.chefe else 1.0))
		pontos.append(Vector2(v.x, v.y))
		_tele(u.poder_conj, "presos", 1.0)
		_dano_poder(u, v, base * Balanco.PODER_RAIZ_DANO)
	return true

## Poder SAQUE: corpo separado de _usar_poder_i.
func _poder_saque(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	for k in ceili(Balanco.PODER_SAQUE_N * _frac_apoio()):
		var fraco: Unidade = null
		for v in outros:
			if v.vivo and (fraco == null or v.vida < fraco.vida):
				fraco = v
		if fraco == null:
			break
		pontos.append(Vector2(fraco.x, fraco.y))
		_dano_poder(u, fraco, base * Balanco.PODER_SAQUE_DANO)
	return true

## Poder TROVOADA: corpo separado de _usar_poder_i.
func _poder_trovoada(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var raios: Array = _aglomerados(outros, Balanco.PODER_TROVOADA_RAIO, ceili(Balanco.PODER_TROVOADA_N * _frac_apoio()))
	if raios.is_empty():
		return false
	for c in raios:
		pontos.append(c)
		for v in outros:
			if v.vivo and _dentro(v, c.x, c.y, Balanco.PODER_TROVOADA_RAIO):
				v.atordoado_t = maxf(v.atordoado_t, Balanco.PODER_TROVOADA_T * _frac_apoio() * (Balanco.PODER_TROVOADA_CHEFE if v.chefe else 1.0))
				_dano_poder(u, v, base * Balanco.PODER_TROVOADA_DANO)
	extra["raio"] = Balanco.PODER_TROVOADA_RAIO
	return true

## Poder CANHAO: corpo separado de _usar_poder_i.
func _poder_canhao(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var alvos_c: Array = _aglomerados(outros, Balanco.PODER_CANHAO_RAIO, 1)
	if alvos_c.is_empty():
		return false
	var cc: Vector2 = alvos_c[0]
	pontos.append(cc)
	var mortos: int = 0
	for v in outros:
		if v.vivo and _dentro(v, cc.x, cc.y, Balanco.PODER_CANHAO_RAIO):
			_dano_poder(u, v, base * Balanco.PODER_CANHAO_DANO)
			if not v.vivo:
				mortos += 1
			elif not em_heranca:
				v.queima_t = Balanco.PODER_CANHAO_QUEIMA_T
				v.queima_dps = base * Balanco.PODER_CANHAO_QUEIMA_DPS
				v.queima_fonte = u
	extra["raio"] = Balanco.PODER_CANHAO_RAIO
	if not em_heranca and u.equipe == 0 and mortos > 0:
		var saque: int = mini(mortos, Balanco.PODER_CANHAO_SAQUE_MAX)
		saque = mini(saque, maxi(0, estado.tijolos_max() - estado.tijolos))
		if saque > 0:
			estado.tijolos += saque
			_tele(u.poder_conj, "tijolos", saque)
			_ev({"t": "devolve", "x": cc.x, "y": cc.y, "n": saque})
	return true

## Poder MISSEIS: corpo separado de _usar_poder_i.
func _poder_misseis(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	# qualquer inimigo na metade da torre dispara; as explosões caem nos maiores bandos dessa metade
	var centros_m: Array = _centros_misseis(outros)
	if centros_m.is_empty():
		return false
	for c in centros_m:
		pontos.append(c)
		for v in outros:
			if v.vivo and _dentro(v, c.x, c.y, Balanco.PODER_MISSEIS_RAIO):
				_dano_poder(u, v, base * Balanco.PODER_MISSEIS_DANO)
	extra["raio"] = Balanco.PODER_MISSEIS_RAIO
	return true

## Poder CANCAO: corpo separado de _usar_poder_i.
func _poder_cancao(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	var seg: float = Balanco.PODER_CANCAO_SEG * _frac_apoio()
	if u.equipe == 1:
		# versão bicho: em vez de adiantar os aliados, atrasa a recarga dos poderes dos gatos
		var atraso: float = Balanco.PODER_CANCAO_INIMIGO * _fi
		for v in outros:
			var atrasou: bool = false
			if v.poder >= 0:
				v.poder_cd += atraso
				atrasou = true
			for i in v.heranca_cd.size():
				v.heranca_cd[i] += atraso
				atrasou = true
			if atrasou:
				pontos.append(Vector2(v.x, v.y))
				_tele(u.poder_conj, "segundos", atraso)
		if pontos.is_empty():
			return false
	for v in (meus if u.equipe == 0 else []):
		if v == u or not v.vivo:
			continue
		var mexeu: bool = false
		if v.poder >= 0 and v.poder_cd > 0.0:
			v.poder_cd = maxf(0.0, v.poder_cd - seg)
			mexeu = true
			_tele(u.poder_conj, "segundos", seg)
		for i in v.heranca_cd.size():
			if v.heranca_cd[i] > 0.0:
				v.heranca_cd[i] = maxf(0.0, v.heranca_cd[i] - seg)
				mexeu = true
				_tele(u.poder_conj, "segundos", seg)
		if mexeu:
			pontos.append(Vector2(v.x, v.y))
	if pontos.is_empty():
		return false
	return true

## Poder INVESTIDA: corpo separado de _usar_poder_i.
func _poder_investida(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var si: float = 1.0 if u.equipe == 0 else -1.0
	var linha_i: Array = []
	for v in outros:
		var dxi: float = (v.x - u.x) * si
		if dxi >= -20.0 and dxi <= Balanco.PODER_INVESTIDA_ALCANCE + 30.0 and absf(v.y - u.y) <= Balanco.PODER_ATRAVESSA_LARGURA:
			linha_i.append(v)
	if linha_i.is_empty():
		return false
	var primeiro: Unidade = null
	var longe: float = 0.0
	for v in linha_i:
		var dxv: float = (v.x - u.x) * si
		if primeiro == null or dxv < (primeiro.x - u.x) * si:
			primeiro = v
		longe = maxf(longe, dxv)
	for v in linha_i:
		pontos.append(Vector2(v.x, v.y))
	extra["x0"] = u.x
	extra["y0"] = u.y
	primeiro.atordoado_t = maxf(primeiro.atordoado_t, Balanco.PODER_INVESTIDA_DERRUBA * _frac_apoio() * (Balanco.PODER_RAIZ_CHEFE if primeiro.chefe else 1.0))
	for v in linha_i:
		_dano_poder(u, v, base * (Balanco.PODER_INVESTIDA_HER_DANO if em_heranca else Balanco.PODER_INVESTIDA_DANO))
	if not em_heranca:
		u.x = clampf(u.x + si * minf(longe + 30.0, Balanco.PODER_INVESTIDA_ALCANCE), Balanco.TORRE_X + 20.0, Balanco.VISIVEL_X)
		u.protegido_t = maxf(u.protegido_t, Balanco.PODER_INVESTIDA_PROTEGE)
		u.alvo = null
		u.retarget = 0.0
	return true

## Poder FUMACA: corpo separado de _usar_poder_i.
func _poder_fumaca(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	if em_heranca:
		u.oculto_t = maxf(u.oculto_t, Balanco.PODER_FUMACA_T * _frac_apoio())
		pontos.append(Vector2(u.x, u.y))
		_tele(u.poder_conj, "ocultos", 1.0)
	else:
		for v in meus:
			if v.vivo and _dentro(v, u.x, u.y, Balanco.PODER_FUMACA_RAIO):
				v.oculto_t = maxf(v.oculto_t, Balanco.PODER_FUMACA_T * _fi)
				pontos.append(Vector2(v.x, v.y))
				_tele(u.poder_conj, "ocultos", 1.0)
	for e in (inimigos if u.equipe == 0 else aliados):
		if e.alvo != null and e.alvo.oculto_t > 0.0 and not _enxerga_oculto(e, e.alvo):
			e.alvo = null
			e.retarget = 0.0
	extra["raio"] = Balanco.PODER_FUMACA_RAIO
	return true

## Poder FURIA: corpo separado de _usar_poder_i.
func _poder_furia(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	u.furor_t = Balanco.PODER_FURIA_T * _frac_apoio()
	u.furor_cerco = Balanco.PODER_FURIA_CERCO * _frac_apoio()
	u.furor_roubo = 0.0 if em_heranca else Balanco.PODER_FURIA_ROUBO
	pontos.append(Vector2(u.x, u.y))
	return true

## Poder PISAO: corpo separado de _usar_poder_i.
func _poder_pisao(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	var sp_i: float = 1.0 if u.equipe == 0 else -1.0
	var cand: Array = outros.duplicate()
	var px: float = u.x
	var py: float = u.y
	extra["x0"] = u.x
	extra["y0"] = u.y
	for k in (Balanco.PODER_PISAO_N_HER if em_heranca else Balanco.PODER_PISAO_N):
		var forte: Unidade = null
		for v in cand:
			if v.vivo and _dentro(v, px, py, Balanco.PODER_PISAO_ALCANCE) and (forte == null or v.vida > forte.vida):
				forte = v
		if forte == null:
			break
		cand.erase(forte)
		pontos.append(Vector2(forte.x, forte.y))
		forte.atordoado_t = maxf(forte.atordoado_t, Balanco.PODER_PISAO_T * _fi * (Balanco.PODER_RAIZ_CHEFE if forte.chefe else 1.0))
		var fx_x: float = forte.x
		var fx_y: float = forte.y
		_dano_poder(u, forte, base * Balanco.PODER_PISAO_DANO * pow(Balanco.PODER_PISAO_CRESCE, k) * (Balanco.PODER_INIMIGO_PISAO if u.equipe != 0 else 1.0))
		if not em_heranca:
			px = fx_x - sp_i * 30.0
			py = fx_y
	if pontos.is_empty():
		return false
	if not em_heranca:
		u.x = clampf(px, Balanco.TORRE_X + 20.0, Balanco.VISIVEL_X)
		u.y = clampf(py, Balanco.CHAO_Y0, Balanco.CHAO_Y1)
		u.protegido_t = maxf(u.protegido_t, Balanco.PODER_PISAO_PROTEGE)
		u.alvo = null
		u.retarget = 0.0
	return true

## Poder CANTEIRO: corpo separado de _usar_poder_i.
func _poder_canteiro(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var ferido_c: bool = false
	for v in meus:
		if v.vivo and v.vida < v.vida_max * 0.9:
			ferido_c = true
	if not ferido_c:
		return false
	var fr_c: float = _frac_apoio()
	zonas.append({"tipo": "canteiro", "x": u.x, "y": u.y, "t": Balanco.PODER_CANTEIRO_T * fr_c, "dur": Balanco.PODER_CANTEIRO_T * fr_c,
		"raio": Balanco.PODER_CANTEIRO_RAIO, "cura": Balanco.PODER_CANTEIRO_CURA * fr_c, "dono": u, "eq": u.equipe, "so": u if em_heranca else null, "conj": u.poder_conj})
	pontos.append(Vector2(u.x, u.y))
	extra["raio"] = Balanco.PODER_CANTEIRO_RAIO
	extra["dur"] = Balanco.PODER_CANTEIRO_T * fr_c
	return true

## Poder TRIAGEM: corpo separado de _usar_poder_i.
func _poder_triagem(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var pior: Unidade = null
	for v in meus:
		if v.vivo and not v.clone and v.vida < v.vida_max * Balanco.PODER_TRIAGEM_LIMIAR and (pior == null or v.vida / v.vida_max < pior.vida / pior.vida_max):
			pior = v
	if pior == null:
		return false
	var fr_t: float = _frac_apoio()
	for v in meus:
		if not v.vivo or v.clone:
			continue
		var antes_t: float = v.vida
		v.vida = minf(v.vida_max, v.vida + v.vida_max * (Balanco.PODER_TRIAGEM_CURA if v == pior else Balanco.PODER_TRIAGEM_OUTROS) * fr_t)
		_tele(u.poder_conj, "cura", v.vida - antes_t)
		if v == pior:
			pontos.push_front(Vector2(v.x, v.y))
		else:
			pontos.append(Vector2(v.x, v.y))
	if not em_heranca:
		pior.protegido_t = maxf(pior.protegido_t, Balanco.PODER_TRIAGEM_PROTEGE)
	return true

## Poder MARCA: corpo separado de _usar_poder_i.
func _poder_marca(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var sg: float = 1.0 if u.equipe == 0 else -1.0
	var alvos_m: Array = []
	for v in outros:
		var dxm: float = (v.x - u.x) * sg
		if dxm >= -20.0 and dxm <= Balanco.PODER_ATRAVESSA_ALCANCE and absf(v.y - u.y) <= Balanco.PODER_ATRAVESSA_LARGURA:
			alvos_m.append(v)
			pontos.append(Vector2(v.x, v.y))
	if alvos_m.is_empty():
		return false
	var fr_m: float = _frac_apoio()
	var bonus_m: float = minf(Balanco.PODER_MARCA_BONUS, Balanco.PODER_MARCA_BONUS * fr_m * 1.2)
	for v in alvos_m:
		_dano_poder(u, v, base * Balanco.PODER_MARCA_DANO)
		if v.vivo:
			v.marcado_bonus = maxf(bonus_m, v.marcado_bonus if v.marcado_t > 0.0 else 0.0)
			v.marcado_t = maxf(v.marcado_t, Balanco.PODER_MARCA_T * fr_m)
			v.marcado_conj = u.poder_conj
			_tele(u.poder_conj, "marcados", 1.0)
	if not em_heranca and alvos_m.size() >= Balanco.PODER_MARCA_RECARGA_MIN:
		u.poder_cd_menos = Balanco.PODER_MARCA_RECARGA
	return true

## Poder BOLA: corpo separado de _usar_poder_i.
func _poder_bola(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	u.bola_t = Balanco.PODER_BOLA_T * _frac_apoio()
	u.bola_vel = 1.0 if em_heranca else 1.0 + (Balanco.PODER_BOLA_VEL - 1.0) * _fi
	u.bola_espinho = base * Balanco.PODER_BOLA_ESPINHO
	u.atordoado_t = 0.0
	pontos.append(Vector2(u.x, u.y))
	return true

## Poder ATORDOA/EMPURRA/GIRO: corpo separado de _usar_poder_i.
func _poder_atordoa_empurra_giro(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
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
				v.atordoado_t = Balanco.PODER_ATORDOA_T * _fi * (Balanco.PODER_ATORDOA_CHEFE if v.chefe else 1.0)
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
	return true

# ---------- Lote 1 da expansão de fantasias (ver Balanco.PODER_SALVAMENTO_* e seguintes) ----------
## Salvamento (Super Miau): leva o aliado mais ferido de volta ao posto, cura e soca o chão onde ele estava.
func _poder_salvamento(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var ferido: Unidade = null
	for v in meus:
		if not v.vivo or v.clone or v.cao or (v == u and not em_heranca):
			continue
		if v.vida >= v.vida_max * Balanco.PODER_SALVAMENTO_LIMIAR:
			continue
		if ferido == null or v.vida / v.vida_max < ferido.vida / ferido.vida_max:
			ferido = v
	if ferido == null:
		return false
	var ax: float = ferido.x
	var ay: float = ferido.y
	pontos.append(Vector2(ax, ay))
	if em_heranca:
		var antes_h: float = ferido.vida
		ferido.vida = minf(ferido.vida_max, ferido.vida + ferido.vida_max * Balanco.PODER_SALVAMENTO_HER_CURA)
		ferido.protegido_t = maxf(ferido.protegido_t, Balanco.PODER_SALVAMENTO_PROTEGE * _frac_apoio())
		_tele(u.poder_conj, "cura", ferido.vida - antes_h)
		return true
	for v in outros:
		if v.vivo and _dentro(v, ax, ay, Balanco.PODER_SALVAMENTO_RAIO):
			v.atordoado_t = maxf(v.atordoado_t, Balanco.PODER_SALVAMENTO_ATORDOA * (Balanco.PODER_ATORDOA_CHEFE if v.chefe else 1.0))
			_dano_poder(u, v, base * Balanco.PODER_SALVAMENTO_DANO)
	extra["x0"] = u.x
	extra["y0"] = u.y
	extra["raio"] = Balanco.PODER_SALVAMENTO_RAIO
	ferido.x = clampf(ferido.casa_x, Balanco.TORRE_X + 20.0, Balanco.VISIVEL_X)
	ferido.y = ferido.casa_y
	ferido.vx = -9999.0
	ferido.alvo = null
	ferido.retarget = 0.0
	if ferido != u:
		u.x = ferido.x - 26.0
		u.y = ferido.y
		u.vx = -9999.0
		u.alvo = null
		u.retarget = 0.0
	var antes: float = ferido.vida
	ferido.vida = minf(ferido.vida_max, ferido.vida + ferido.vida_max * Balanco.PODER_SALVAMENTO_CURA)
	_tele(u.poder_conj, "cura", ferido.vida - antes)
	ferido.protegido_t = maxf(ferido.protegido_t, Balanco.PODER_SALVAMENTO_PROTEGE)
	u.protegido_t = maxf(u.protegido_t, Balanco.PODER_SALVAMENTO_PROTEGE)
	return true

## Flecha ricochete (Arqueiro Miau): acerta o mais perto e salta de inimigo em inimigo, cada acerto mais forte.
func _poder_ricochete(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var atual: Unidade = _mais_perto(u, outros, Balanco.PODER_RICOCHETE_ALCANCE)
	if atual == null:
		return false
	var dano: float = base * Balanco.PODER_RICOCHETE_DANO
	var acertados: Array[Unidade] = []
	for k in ceili(Balanco.PODER_RICOCHETE_ALVOS * _frac_apoio()):
		if atual == null:
			break
		acertados.append(atual)
		pontos.append(Vector2(atual.x, atual.y))
		var ax: float = atual.x
		var ay: float = atual.y
		_dano_poder(u, atual, dano)
		dano *= Balanco.PODER_RICOCHETE_CRESCE
		atual = null
		var md: float = Balanco.PODER_RICOCHETE_SALTO * Balanco.PODER_RICOCHETE_SALTO
		for v in outros:
			if not v.vivo or acertados.has(v):
				continue
			var d2: float = (v.x - ax) * (v.x - ax) + (v.y - ay) * (v.y - ay)
			if d2 <= md:
				md = d2
				atual = v
	return true

## Olhar da Penitência (Motoqueiro Miausma): dano em % da vida máxima dos de maior vida, mais queimadura.
func _poder_olhar(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty():
		return false
	var cand: Array[Unidade] = outros.duplicate()
	cand.sort_custom(func(a: Unidade, b: Unidade) -> bool: return a.vida > b.vida)
	var n: int = 1 if (em_heranca or u.equipe == 1) else Balanco.PODER_OLHAR_N
	var frac: float = Balanco.PODER_OLHAR_FRACAO
	if em_heranca:
		frac = Balanco.PODER_OLHAR_HER_FRACAO
	elif u.equipe == 1:
		frac = Balanco.PODER_OLHAR_BICHO_FRACAO * _fi
	for k in mini(n, cand.size()):
		var v: Unidade = cand[k]
		var fr: float = Balanco.PODER_OLHAR_CHEFE_FRACAO if v.chefe else frac
		var teto: float = Balanco.PODER_OLHAR_CHEFE_MAX if v.chefe else Balanco.PODER_OLHAR_MAX
		pontos.append(Vector2(v.x, v.y))
		_dano_poder(u, v, clampf(v.vida_max * fr, base * Balanco.PODER_OLHAR_MIN, base * teto))
		if v.vivo:
			v.queima_t = Balanco.PODER_OLHAR_QUEIMA_T
			v.queima_dps = base * Balanco.PODER_OLHAR_QUEIMA_DPS
			v.queima_fonte = u
	return true

## Objeção! (Fênix Miaussimo): com um bicho carregando poder, corta o aviso e anima o time; sem nenhum, vira o Protesto (mais fraco).
func _poder_objecao(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var alvo: Unidade = null
	for v in outros:
		if v.vivo and v.aviso_t > 0.0 and (alvo == null or (v.chefe and not alvo.chefe) or (v.chefe == alvo.chefe and v.vida > alvo.vida)):
			alvo = v
	var com_aviso: bool = alvo != null
	if alvo == null:
		# sem poder de bicho carregando: Protesto, a versão fraca (atordoa o mais forte à vista e anima menos o time)
		for v in outros:
			if v.vivo and v.x <= Balanco.VISIVEL_X and not v.clone and (alvo == null or v.vida > alvo.vida):
				alvo = v
		if alvo == null:
			return false
	var fr: float = 1.0 if com_aviso else Balanco.PODER_PROTESTO_FATOR
	if com_aviso:
		alvo.aviso_t = 0.0
		alvo.aviso_forma = {}
		alvo.poder_cd = maxf(alvo.poder_cd, 0.0) + Balanco.PODER_OBJECAO_ATRASO
	alvo.atordoado_t = maxf(alvo.atordoado_t, (Balanco.PODER_OBJECAO_ATORDOA_CHEFE if alvo.chefe else Balanco.PODER_OBJECAO_ATORDOA) * fr)
	_ev({"t": "aviso_cortado", "x": alvo.x, "y": alvo.y})
	pontos.append(Vector2(alvo.x, alvo.y))
	if not em_heranca:
		for v in meus:
			if v.vivo and not v.clone:
				v.buff_dano = Balanco.PODER_OBJECAO_BONUS * fr
				v.buff_dano_t = maxf(v.buff_dano_t, Balanco.PODER_OBJECAO_BONUS_T * fr)
		extra["texto"] = "Contra-prova!" if com_aviso else "Protesto!"
	_dano_poder(u, alvo, base * Balanco.PODER_OBJECAO_DANO * fr)
	return true

## Imitar (Mimiau): repete o último poder da luta; sem nenhum (ou sem alvo para ele), refaz o Disfarce rasgado e cura um pouco.
func _poder_imitar(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if ultimo_conj >= 0 and tempo - ultimo_t <= Balanco.PODER_IMITAR_JANELA:
		var p0: int = u.poder
		var f0: float = u.poder_forca
		u.poder = Pecas.PODER_TIPO[ultimo_conj]
		if not em_heranca:
			u.poder_forca *= Balanco.PODER_IMITAR_FORCA
		var deu: bool = _usar_poder_i(u)
		u.poder = p0
		u.poder_forca = f0
		if deu:
			extra["imitou"] = true
			return true
	if u.disfarcado or u.disfarce_atordoa <= 0.0:
		return false   # nada para copiar e o Disfarce está inteiro: espera um dos dois
	u.disfarcado = true
	u.disfarce_rearma_t = 0.0
	if not em_heranca:
		u.protegido_t = maxf(u.protegido_t, Balanco.DISFARCE_REFAZ_PROTEGE)
	u.vida = minf(u.vida_max, u.vida + u.vida_max * (Balanco.DISFARCE_RASGA_CURA_HER if em_heranca else Balanco.DISFARCE_RASGA_CURA))
	pontos.append(Vector2(u.x, u.y))
	extra["texto"] = "Disfarce refeito!"
	_ev({"t": "disfarce_refaz", "x": u.x, "y": u.y})
	return true

## Mão de pôquer (Jimiau): saca cartas, joga a melhor mão de 5 e fere o maior bando conforme a mão.
func _poder_poquer(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var cs: Array = _aglomerados(outros, Balanco.PODER_POQUER_RAIO, 1)
	if cs.is_empty():
		return false
	var cc: Vector2 = cs[0]
	var mao: int = Poquer.melhor_mao(Poquer.sacar(rng, Balanco.PODER_POQUER_CARTAS_HER if em_heranca else Balanco.PODER_POQUER_CARTAS))
	pontos.append(cc)
	for v in outros:
		if v.vivo and _dentro(v, cc.x, cc.y, Balanco.PODER_POQUER_RAIO):
			_dano_poder(u, v, base * Balanco.PODER_POQUER_DANO[mao])
	extra["raio"] = Balanco.PODER_POQUER_RAIO
	extra["texto"] = Poquer.NOME[mao] + "!"
	extra["mao"] = mao
	_tele(u.poder_conj, "mao", float(mao))
	return true

# ---------- Lote 2 da expansão de fantasias: estruturas, manteiga, reviver, mudas e sono ----------
## Estrutura aliada (torre de ervilha, bloco): unidade parada com dono e prazo; é um clone, então não conta como gato nem como bicho.
func _nova_estrutura(u: Unidade, tipo: int, x: float, y: float, vida: float, dur: float) -> Unidade:
	var f := Unidade.new()
	f.equipe = u.equipe
	f.clone = true
	f.estrutura = true
	f.estr_tipo = tipo
	f.estr_conj = u.poder_conj
	f.dono = u
	f.clone_t = dur
	f.linha = u.linha
	f.postura = Boneco.Postura.SEGURAR
	f.familia = u.familia
	f.esc_vida = u.esc_vida
	f.esc_dano = u.esc_dano
	f.vida_max = vida
	f.vida = vida
	f.vel = 0.0
	f.x = clampf(x, Balanco.TORRE_X + 20.0, Balanco.VISIVEL_X)
	f.y = clampf(y, Balanco.CHAO_Y0, Balanco.CHAO_Y1)
	f.casa_x = f.x
	f.casa_y = f.y
	f.cd = 0.3
	if u.equipe == 0:
		nascidos_aliados.append(f)
	else:
		nascidos.append(f)
	return f

## A estrutura nova troca a velha do mesmo dono e tipo (sem explodir).
func _remover_estruturas(u: Unidade, tipo: int) -> void:
	var listas: Array = [aliados, nascidos_aliados] if u.equipe == 0 else [inimigos, nascidos]
	for l in listas:
		for v in l:
			if v.estrutura and v.vivo and v.dono == u and v.estr_tipo == tipo:
				v.vivo = false
				_ev({"t": "clone_fim", "x": v.x, "y": v.y, "eq": v.equipe, "tempo": true})

## Torre: atira na cadência dela no mais perto dentro do alcance; bloco só fica (provoca).
func _estrutura_age(u: Unidade, dt: float) -> void:
	if u.estr_tipo != ESTR_TORRE:
		return
	u.cd -= dt
	if u.cd > 0.0:
		return
	var alvo: Unidade = null
	var md: float = u.alcance * u.alcance
	for v in (inimigos if u.equipe == 0 else aliados):
		if not v.vivo or v.x > Balanco.VISIVEL_X or v.oculto_t > 0.0:
			continue
		var d2: float = (v.x - u.x) * (v.x - u.x) + (v.y - u.y) * (v.y - u.y)
		if d2 <= md:
			md = d2
			alvo = v
	if alvo == null:
		return
	u.cd = u.intervalo
	u.golpe = 0.2
	var killer: Unidade = u.dono if u.dono != null and u.dono.vivo else u
	projeteis.append({"x": u.x, "y": u.y - 14.0, "alvo": alvo, "dono": killer, "dano": u.estr_ataque, "poder": true, "perfura": Balanco.PODER_TORRE_PERFURA, "conj": u.estr_conj})
	_ev({"t": "tiro", "x": u.x, "y": u.y, "eq": u.equipe})

## Ervilha da torre chegou: dano de poder (ignora armadura) no alvo e no vizinho mais perto dele.
func _acerta_ervilha(p: Dictionary, a: Unidade) -> void:
	var dono: Unidade = p["dono"]
	var c0: int = _conj_tele
	var e0: int = _eq_tele
	_conj_tele = int(p.get("conj", -1))
	_eq_tele = dono.equipe
	_dano_poder(dono, a, p["dano"])
	if p.has("perfura"):
		var viz: Unidade = null
		var md: float = float(p["perfura"]) * float(p["perfura"])
		for v in (inimigos if dono.equipe == 0 else aliados):
			if v == a or not v.vivo or v.x > Balanco.VISIVEL_X:
				continue
			var d2: float = (v.x - a.x) * (v.x - a.x) + (v.y - a.y) * (v.y - a.y)
			if d2 <= md:
				md = d2
				viz = v
		if viz != null:
			_dano_poder(dono, viz, p["dano"])
	_conj_tele = c0
	_eq_tele = e0

## Estrutura que caiu (destruída ou expirada): o bloco explode.
func _estrutura_cai(u: Unidade) -> void:
	if u.estr_explode <= 0.0:
		return
	var dono: Unidade = u.dono if u.dono != null and u.dono.vivo else u
	_ev({"t": "explosao", "x": u.x, "y": u.y, "raio": Balanco.PODER_CONSTRUIR_RAIO, "eq": u.equipe, "bloco": true})
	var c0: int = _conj_tele
	var e0: int = _eq_tele
	_conj_tele = u.estr_conj
	_eq_tele = u.equipe
	for v in (inimigos if u.equipe == 0 else aliados):
		if v.vivo and not v.estrutura and _dentro(v, u.x, u.y, Balanco.PODER_CONSTRUIR_RAIO):
			_dano_poder(dono, v, u.estr_explode)
	_conj_tele = c0
	_eq_tele = e0

## Quando só sobram estruturas inimigas e não vem mais ninguém, elas somem (não seguram o fim da onda).
func _limpar_estruturas() -> void:
	if inimigos.is_empty() or not fila.is_empty():
		return
	for v in inimigos:
		if v.vivo and not v.estrutura:
			return
	for v in inimigos:
		if v.vivo:
			v.vivo = false
			_ev({"t": "clone_fim", "x": v.x, "y": v.y, "eq": v.equipe, "tempo": true})

## Torre de ervilha (Disparamiau).
func _poder_torre(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if u.clone or outros.is_empty():
		return false
	_remover_estruturas(u, ESTR_TORRE)
	var dur: float = (Balanco.PODER_TORRE_HER_T if em_heranca else Balanco.PODER_TORRE_T) * _fi
	var sent: float = 1.0 if u.equipe == 0 else -1.0
	var f: Unidade = _nova_estrutura(u, ESTR_TORRE, u.x + sent * Balanco.PODER_TORRE_DX, u.y, u.vida_max * Balanco.PODER_TORRE_VIDA, dur)
	f.alcance = Balanco.PODER_TORRE_ALCANCE
	f.intervalo = Balanco.PODER_TORRE_INTERVALO
	f.estr_ataque = base * Balanco.PODER_TORRE_DANO * (Balanco.PODER_TORRE_HER_DANO if em_heranca else 1.0)
	pontos.append(Vector2(f.x, f.y))
	extra["dur"] = dur
	return true

## Blocos de pedra (Miaucraft).
func _poder_construir(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if u.clone or outros.is_empty():
		return false
	_remover_estruturas(u, ESTR_BLOCO)
	var n: int = Balanco.PODER_CONSTRUIR_HER_N if em_heranca else Balanco.PODER_CONSTRUIR_N
	var dur: float = Balanco.PODER_CONSTRUIR_HER_T if em_heranca else Balanco.PODER_CONSTRUIR_T
	for k in n:
		var ang: float = (float(k) - (n - 1) * 0.5) * (0.9 if n > 2 else 1.0)
		var f: Unidade = _nova_estrutura(u, ESTR_BLOCO, u.x + cos(ang) * Balanco.PODER_CONSTRUIR_DIST, u.y + sin(ang) * Balanco.PODER_CONSTRUIR_DIST, u.vida_max * Balanco.PODER_CONSTRUIR_VIDA, dur)
		f.provoca = true
		f.estr_explode = base * Balanco.PODER_CONSTRUIR_DANO
		pontos.append(Vector2(f.x, f.y))
	extra["dur"] = dur
	return true

## Manteiga escorregadia (Milhau): poça no maior bando.
func _poder_manteiga(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var raio: float = Balanco.PODER_MANTEIGA_HER_RAIO if em_heranca else Balanco.PODER_MANTEIGA_RAIO
	var cs: Array = _aglomerados(outros, raio, 1)
	if cs.is_empty():
		return false
	var dur: float = Balanco.PODER_MANTEIGA_HER_T if em_heranca else Balanco.PODER_MANTEIGA_T
	var c: Vector2 = cs[0]
	zonas.append({"tipo": "manteiga", "x": c.x, "y": c.y, "t": dur, "dur": dur, "raio": raio, "dps": base * Balanco.PODER_MANTEIGA_DPS, "dono": u, "eq": u.equipe, "conj": u.poder_conj})
	pontos.append(c)
	extra["raio"] = raio
	extra["dur"] = dur
	return true

## Dentro da poça: desliza para o fundo (chefe e Gigante só ficam lentos), fica lento e leva um pouco de dano.
func _zona_manteiga(z: Dictionary, dt: float) -> void:
	var eq: int = int(z["eq"])
	var dono: Unidade = z["dono"]
	var sent: float = 1.0 if eq == 0 else -1.0
	for v in (inimigos if eq == 0 else aliados):
		if not v.vivo or v.x > Balanco.VISIVEL_X or not _dentro(v, float(z["x"]), float(z["y"]), float(z["raio"])):
			continue
		v.manteiga_t = Balanco.PODER_MANTEIGA_POS_T
		if not v.chefe and v.tipo != Unidade.Tipo.GIGANTE and not v.estrutura:
			v.x = clampf(v.x + sent * Balanco.PODER_MANTEIGA_VEL * dt, Balanco.TORRE_X + 20.0, Balanco.VISIVEL_X)
		var d: float = float(z["dps"]) * dt * _vul(v) * (Balanco.PODER_PROTEGE_DANO if v.protegido_t > 0.0 else 1.0)
		_tele(int(z["conj"]), "dano", d)
		v.vida -= d
		v.sono_t = 0.0
		v.flash = maxf(v.flash, 0.3)
		if v.vida <= 0.0:
			_matar(v, dono if dono != null and dono.vivo else null, Pecas.Marca.CICATRIZ)

## Reviver (Giramiau): levanta o gato caído há menos tempo e APAGA a marca de nocaute que as roupas dele levaram.
func _poder_reviver(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if u.reviver_usado or u.clone:
		return false
	var rec: Dictionary = {}
	for c in caidos:
		if tempo - float(c["t"]) <= Balanco.PODER_REVIVER_JANELA and not (c["u"] as Unidade).vivo and (rec.is_empty() or float(c["t"]) > float(rec["t"])):
			rec = c
	if rec.is_empty():
		return false
	caidos.erase(rec)
	u.reviver_usado = true
	var g: Unidade = rec["u"]
	for r in rec["marcas"]:
		var p: Peca = r[0]
		if not p.marcas.is_empty() and p.marcas[p.marcas.size() - 1] == int(rec["causa"]):
			p.marcas.pop_back()
		p.nova = bool(r[1])
	g.vivo = true
	g.vida = g.vida_max * (Balanco.PODER_REVIVER_HER_VIDA if em_heranca else Balanco.PODER_REVIVER_VIDA)
	g.protegido_t = maxf(g.protegido_t, Balanco.PODER_REVIVER_PROTEGE)
	g.atordoado_t = 0.0
	g.queima_t = 0.0
	g.alvo = null
	g.retarget = 0.0
	g.x = float(rec["x"])
	g.y = float(rec["y"])
	g.vx = -9999.0
	if g.boneco != null:
		g.boneco.vivo = true
	if not aliados.has(g):
		nascidos_aliados.append(g)
	pontos.append(Vector2(g.x, g.y))
	extra["texto"] = "Reviveu!"
	_tele(u.poder_conj, "revividos", 1.0)
	return true

## Colheita (Stardew Miaulley): mudas em leque; amadurecem em Pimenta, Morango ou murcham.
func _poder_colheita(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if u.clone or outros.is_empty():
		return false
	var n: int = Balanco.PODER_COLHEITA_HER_N if em_heranca else Balanco.PODER_COLHEITA_N
	var t: float = Balanco.PODER_COLHEITA_HER_T if em_heranca else Balanco.PODER_COLHEITA_T
	var sent: float = 1.0 if u.equipe == 0 else -1.0
	for k in n:
		var off: float = (float(k) - (n - 1) * 0.5) * (Balanco.PODER_COLHEITA_LEQUE * 2.0 / maxf(1.0, n - 1))
		var z: Dictionary = {"tipo": "muda", "x": u.x + sent * (22.0 + absf(off) * 0.4), "y": clampf(u.y + off, Balanco.CHAO_Y0, Balanco.CHAO_Y1), "t": t, "dur": t,
			"dono": u, "eq": u.equipe, "base": base, "conj": u.poder_conj}
		zonas.append(z)
		pontos.append(Vector2(z["x"], z["y"]))
	extra["dur"] = t
	return true

## A muda amadureceu: inimigo perto = Pimenta; senão, aliado ferido perto = Morango; senão murcha. Bicho só faz Pimenta.
func _muda_amadurece(z: Dictionary) -> void:
	var eq: int = int(z["eq"])
	var cx: float = float(z["x"])
	var cy: float = float(z["y"])
	var dono: Unidade = z["dono"]
	var base: float = float(z["base"])
	var contra: Array[Unidade] = inimigos if eq == 0 else aliados
	var meus: Array[Unidade] = aliados if eq == 0 else inimigos
	var c0: int = _conj_tele
	var e0: int = _eq_tele
	_conj_tele = int(z["conj"])
	_eq_tele = eq
	var perto: bool = false
	for v in contra:
		if v.vivo and v.x <= Balanco.VISIVEL_X and _dentro(v, cx, cy, Balanco.PODER_COLHEITA_VE_INIMIGO):
			perto = true
			break
	if perto:
		_ev({"t": "muda", "x": cx, "y": cy, "res": 0, "raio": Balanco.PODER_COLHEITA_RAIO, "eq": eq})
		for v in contra:
			if v.vivo and _dentro(v, cx, cy, Balanco.PODER_COLHEITA_RAIO):
				_dano_poder(dono, v, base * Balanco.PODER_COLHEITA_DANO)
				if v.vivo:
					v.queima_t = Balanco.PODER_COLHEITA_QUEIMA_T
					v.queima_dps = base * Balanco.PODER_COLHEITA_QUEIMA_DPS
					v.queima_fonte = dono
	else:
		var ferido: Unidade = null
		if eq == 0:
			for v in meus:
				if not v.vivo or v.clone or v.vida >= v.vida_max * Balanco.PODER_COLHEITA_FERIDO or not _dentro(v, cx, cy, Balanco.PODER_COLHEITA_VE_ALIADO):
					continue
				if ferido == null or v.vida / v.vida_max < ferido.vida / ferido.vida_max:
					ferido = v
		if ferido != null:
			var antes: float = ferido.vida
			ferido.vida = minf(ferido.vida_max, ferido.vida + ferido.vida_max * Balanco.PODER_COLHEITA_CURA)
			_tele(_conj_tele, "cura", ferido.vida - antes)
			_ev({"t": "muda", "x": cx, "y": cy, "res": 1, "ax": ferido.x, "ay": ferido.y, "eq": eq})
		else:
			_ev({"t": "muda", "x": cx, "y": cy, "res": 2, "eq": eq})
	_conj_tele = c0
	_eq_tele = e0

## Cochilo (Miaulax): o gato dorme e se cura; o ronco adormece os inimigos em volta (acordam ao levar dano).
func _poder_cochilo(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var raio: float = Balanco.PODER_COCHILO_HER_RAIO if em_heranca else Balanco.PODER_SONO_RAIO
	var perto: Array[Unidade] = []
	for v in outros:
		if v.vivo and not v.estrutura and _dentro(v, u.x, u.y, raio):
			perto.append(v)
	if perto.is_empty() and u.vida >= u.vida_max * 0.9:
		return false
	var t: float = Balanco.PODER_COCHILO_HER_T if em_heranca else Balanco.PODER_SONO_T
	for v in perto:
		v.sono_t = maxf(v.sono_t, minf(t, Balanco.PODER_SONO_CHEFE) if v.chefe else t)
		pontos.append(Vector2(v.x, v.y))
	if em_heranca:
		var antes: float = u.vida
		u.vida = minf(u.vida_max, u.vida + u.vida_max * Balanco.PODER_COCHILO_HER_CURA)
		_tele(u.poder_conj, "cura", u.vida - antes)
	else:
		u.cochilo_t = Balanco.PODER_COCHILO_T
		u.cochilo_cura = Balanco.PODER_COCHILO_CURA / Balanco.PODER_COCHILO_T
		u.atordoado_t = 0.0
		u.alvo = null
		_tele(u.poder_conj, "cura", u.vida_max * Balanco.PODER_COCHILO_CURA)
	_tele(u.poder_conj, "dormiram", float(perto.size()))
	pontos.append(Vector2(u.x, u.y))
	extra["raio"] = raio
	return true

## Plano de ataque (Leonarmiau): o time inteiro foca o inimigo de maior vida e causa mais dano nele; o líder dá dois cortes.
func _poder_plano(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var alvo: Unidade = null
	for v in outros:
		if not v.estrutura and (alvo == null or v.vida > alvo.vida):
			alvo = v
	if alvo == null:
		return false
	alvo.foco_t = Balanco.PODER_PLANO_HER_T if em_heranca else Balanco.PODER_PLANO_T
	alvo.foco_bonus = Balanco.PODER_PLANO_HER_BONUS if em_heranca else Balanco.PODER_PLANO_BONUS
	alvo.foco_dono = u
	alvo.foco_recarga = 0.0 if em_heranca else Balanco.PODER_PLANO_RECARGA
	for m in meus:
		if m.vivo:
			m.alvo = alvo
			m.retarget = 0.5
	pontos.append(Vector2(alvo.x, alvo.y))
	extra["foco_t"] = alvo.foco_t
	_tele(u.poder_conj, "focos", 1.0)
	if not em_heranca:
		for k in 2:
			_dano_poder(u, alvo, base * Balanco.PODER_PLANO_CORTE)
		if not alvo.vivo:
			u.poder_cd_menos += Balanco.PODER_PLANO_RECARGA
	return true

## Domo refletor (Donatemiau): domo parado; os tiros inimigos que entram voltam ao atirador. Só rende contra bicho de tiro.
func _poder_domo(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var tem_tiro: bool = false
	for v in outros:
		if v.distancia and not v.estrutura:
			tem_tiro = true
			break
	if not tem_tiro:
		return false
	for z in zonas:
		if z.get("tipo", "") == "domo" and z["dono"] == u:
			z["t"] = 0.0
	var raio: float = Balanco.PODER_DOMO_HER_RAIO if em_heranca else Balanco.PODER_DOMO_RAIO
	var dur: float = Balanco.PODER_DOMO_HER_T if em_heranca else Balanco.PODER_DOMO_T
	zonas.append({"tipo": "domo", "x": u.x, "y": u.y, "t": dur, "dur": dur, "raio": raio, "dono": u, "eq": u.equipe, "conj": u.poder_conj})
	pontos.append(Vector2(u.x, u.y))
	extra["raio"] = raio
	extra["dur"] = dur
	return true

## Dentro do domo: aliados ganham armadura (renovada a cada passo).
func _zona_domo(z: Dictionary) -> void:
	for v in (aliados if int(z["eq"]) == 0 else inimigos):
		if v.vivo and _dentro(v, float(z["x"]), float(z["y"]), float(z["raio"])):
			v.domo_t = 0.1
			v.domo_arm = Balanco.PODER_DOMO_ARMADURA

## O tiro inimigo que entra num domo é destruído e volta ao atirador com o mesmo dano.
func _domo_reflete(p: Dictionary) -> void:
	var dono: Variant = p["dono"]
	if dono == null:
		return
	var d: Unidade = dono
	for z in zonas:
		if z.get("tipo", "") != "domo" or d.equipe == int(z["eq"]):
			continue
		var dx: float = p["x"] - float(z["x"])
		var dy: float = (p["y"] - float(z["y"])) / 0.6
		if dx * dx + dy * dy > float(z["raio"]) * float(z["raio"]):
			continue
		var dom: Unidade = z["dono"]
		p["dono"] = dom
		p["poder"] = true
		p["conj"] = int(z["conj"])
		p["refletido"] = true
		if d.vivo:
			p["alvo"] = d
			p["dano"] = float(p["dano"]) * Balanco.PODER_DOMO_DANO
			_tele(int(z["conj"]), "refletidos", 1.0)
			_ev({"t": "reflete", "x": p["x"], "y": p["y"], "eq": dom.equipe})
		else:
			p["alvo"] = dom   # o atirador já caiu: o tiro se desfaz no domo
			p["dano"] = 0.0
		return

## Lobo solitário (Rafamiau): os bichos em volta só atacam ele; ele apanha menos e bate mais forte.
func _poder_lobo(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var perto: int = 0
	for v in outros:
		if not v.estrutura and _dentro(v, u.x, u.y, Balanco.PODER_LOBO_RAIO):
			perto += 1
	if perto == 0:
		return false
	u.lobo_dur = Balanco.PODER_LOBO_HER_T if em_heranca else Balanco.PODER_LOBO_T
	u.lobo_t = u.lobo_dur
	u.lobo_prov = not em_heranca
	u.lobo_dano = Balanco.PODER_LOBO_HER_DANO if em_heranca else 0.0
	pontos.append(Vector2(u.x, u.y))
	extra["raio"] = Balanco.PODER_LOBO_RAIO
	extra["dur"] = u.lobo_dur
	_tele(u.poder_conj, "provocados", float(perto))
	return true

func _lobo_tick(u: Unidade, dt: float) -> void:
	u.lobo_t -= dt
	if u.lobo_t <= 0.0:
		u.lobo_prov = false
		return
	if not u.lobo_prov:
		u.bonus_dano *= 1.0 + u.lobo_dano
		return
	var n: int = 0
	for v in inimigos:
		if not v.vivo or v.estrutura or not _dentro(v, u.x, u.y, Balanco.PODER_LOBO_RAIO):
			continue
		n += 1
		if v.chefe and u.lobo_dur - u.lobo_t > Balanco.PODER_LOBO_CHEFE_T:
			continue
		v.forcado_alvo = u
		v.forcado_t = 0.3
	var sozinho: bool = true
	for a in aliados:
		if a != u and a.vivo and not a.clone and _dentro(a, u.x, u.y, Balanco.PODER_LOBO_SOZINHO_RAIO):
			sozinho = false
			break
	u.bonus_dano *= 1.0 + Balanco.PODER_LOBO_DANO + minf(Balanco.PODER_LOBO_DANO_INIMIGO_MAX, Balanco.PODER_LOBO_DANO_INIMIGO * n) + (Balanco.PODER_LOBO_SOZINHO if sozinho else 0.0)

## Turbo (Rocket Miaugue): corre em linha atropelando e deixa um rastro de chamas azuis.
func _poder_turbo(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var si: float = 1.0 if u.equipe == 0 else -1.0
	var linha_t: Array = []
	for v in outros:
		var dxt: float = (v.x - u.x) * si
		if dxt >= -20.0 and dxt <= Balanco.PODER_TURBO_ALCANCE + 30.0 and absf(v.y - u.y) <= Balanco.PODER_ATRAVESSA_LARGURA:
			linha_t.append(v)
	if linha_t.is_empty():
		return false
	var n: int = Balanco.PODER_TURBO_HER_N if em_heranca else Balanco.PODER_TURBO_RASTRO_N
	var dur: float = (Balanco.PODER_TURBO_HER_T if em_heranca else Balanco.PODER_TURBO_RASTRO_T) * _fi
	var x2: float = clampf(u.x + si * Balanco.PODER_TURBO_ALCANCE, Balanco.TORRE_X + 20.0, Balanco.VISIVEL_X)
	extra["x0"] = u.x
	extra["y0"] = u.y
	extra["x1"] = x2
	for k in n:
		var zx: float = lerpf(u.x, x2, (k + 0.5) / n)
		zonas.append({"tipo": "chama", "x": zx, "y": u.y, "t": dur, "dur": dur, "raio": Balanco.PODER_TURBO_RASTRO_RAIO,
			"dps": base * Balanco.PODER_TURBO_RASTRO_DPS, "dono": u, "eq": u.equipe, "conj": u.poder_conj})
	if em_heranca:
		pontos.append(Vector2(u.x, u.y))
		return true
	for v in linha_t:
		pontos.append(Vector2(v.x, v.y))
		_dano_poder(u, v, base * Balanco.PODER_TURBO_DANO)
		if v.vivo:
			v.atordoado_t = maxf(v.atordoado_t, Balanco.PODER_TURBO_DERRUBA * (Balanco.PODER_RAIZ_CHEFE if v.chefe else 1.0))
	u.x = x2
	u.protegido_t = maxf(u.protegido_t, Balanco.PODER_TURBO_PROTEGE)
	u.alvo = null
	u.retarget = 0.0
	return true

## Rastro de chamas azuis: fere e atrasa quem pisa.
func _zona_chama(z: Dictionary, dt: float) -> void:
	var eq: int = int(z["eq"])
	var dono: Unidade = z["dono"]
	for v in (inimigos if eq == 0 else aliados):
		if not v.vivo or v.x > Balanco.VISIVEL_X or v.estrutura or not _dentro(v, float(z["x"]), float(z["y"]), float(z["raio"])):
			continue
		v.lento = minf(v.lento, Balanco.PODER_TURBO_RASTRO_LENTO)
		var d: float = float(z["dps"]) * dt * _vul(v) * (Balanco.PODER_PROTEGE_DANO if v.protegido_t > 0.0 else 1.0)
		_tele(int(z["conj"]), "dano", d)
		v.vida -= d
		v.sono_t = 0.0
		v.flash = maxf(v.flash, 0.3)
		if v.vida <= 0.0:
			_tele(int(z["conj"]), "abates", 1.0)
			_matar(v, dono if dono != null and dono.vivo else null, Pecas.Marca.BRASA)

## Esforço máximo (Deadmiau): regenera e bate mais forte; se cair no período, levanta uma vez e explode.
const _PIADAS_ESFORCO: Array[String] = ["Esforço máximo!", "Isso vai pro trailer!", "Quebrando a quarta parede!", "Cadê meu spin-off?", "Sem spoilers, por favor!"]

func _poder_esforco(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	if outros.is_empty() or u.esforco_t > 0.0:
		return false
	u.esforco_t = Balanco.PODER_ESFORCO_HER_T if em_heranca else Balanco.PODER_ESFORCO_T
	u.esforco_regen = Balanco.PODER_ESFORCO_HER_REGEN if em_heranca else Balanco.PODER_ESFORCO_REGEN
	u.esforco_usado = em_heranca or u.equipe == 1 or u.clone
	u.esforco_base = base * Balanco.PODER_ESFORCO_EXPLODE
	u.esforco_conj = u.poder_conj
	pontos.append(Vector2(u.x, u.y))
	extra["texto"] = _PIADAS_ESFORCO[rng.randi_range(0, _PIADAS_ESFORCO.size() - 1)]
	extra["dur"] = u.esforco_t
	return true

func _esforco_levanta(u: Unidade) -> void:
	u.esforco_usado = true
	u.vida = u.vida_max * Balanco.PODER_ESFORCO_VIDA
	u.protegido_t = maxf(u.protegido_t, 0.6)
	u.atordoado_t = 0.0
	u.queima_t = 0.0
	_ev({"t": "explosao", "x": u.x, "y": u.y, "raio": Balanco.PODER_ESFORCO_RAIO, "eq": u.equipe})
	_ev({"t": "fala", "x": u.x, "y": u.y, "txt": "Ainda não!", "eq": u.equipe})
	var c0: int = _conj_tele
	var e0: int = _eq_tele
	_conj_tele = u.esforco_conj
	_eq_tele = u.equipe
	_tele(u.esforco_conj, "levantou", 1.0)
	for v in (inimigos if u.equipe == 0 else aliados):
		if v.vivo and not v.estrutura and _dentro(v, u.x, u.y, Balanco.PODER_ESFORCO_RAIO):
			_dano_poder(u, v, u.esforco_base)
	_conj_tele = c0
	_eq_tele = e0

## Chute giratório (Meon): chute curto em volta; empurra e atordoa. Quem já estava atordoado leva dano bem maior (atordoar -> chutar).
func _poder_chute(u: Unidade, meus: Array[Unidade], outros: Array[Unidade], base: float, pontos: Array, extra: Dictionary) -> bool:
	var raio: float = Balanco.PODER_CHUTE_HER_RAIO if em_heranca else Balanco.PODER_CHUTE_RAIO
	var perto: Array[Unidade] = []
	for v in outros:
		if v.vivo and not v.estrutura and _dentro(v, u.x, u.y, raio):
			perto.append(v)
	if perto.is_empty():
		return false
	var sent: float = 1.0 if u.equipe == 0 else -1.0
	var empurra: float = Balanco.PODER_CHUTE_HER_EMPURRA if em_heranca else Balanco.PODER_CHUTE_EMPURRA
	var atordoa: float = Balanco.PODER_CHUTE_HER_ATORDOA if em_heranca else Balanco.PODER_CHUTE_ATORDOA
	var mult_at: float = Balanco.PODER_CHUTE_HER_ATORDOADO if em_heranca else Balanco.PODER_CHUTE_DANO_ATORDOADO
	var mult: float = Balanco.PODER_CHUTE_HER_DANO if em_heranca else Balanco.PODER_CHUTE_DANO
	var combos: int = 0
	for v in perto:
		pontos.append(Vector2(v.x, v.y))
		var ja: bool = v.atordoado_t > 0.0
		if ja:
			combos += 1
		if not v.chefe and v.tipo != Unidade.Tipo.GIGANTE:
			v.x = clampf(v.x + sent * empurra, Balanco.TORRE_X + 20.0, Balanco.INIMIGO_X0)
		if not v.bola_t > 0.0:
			v.atordoado_t = maxf(v.atordoado_t, atordoa * _fi * (Balanco.PODER_CHUTE_CHEFE if v.chefe else 1.0))
		_dano_poder(u, v, base * (mult_at if ja else mult))
	_tele(u.poder_conj, "combos", float(combos))
	extra["raio"] = raio
	extra["combos"] = combos
	return true

## Aparar com a faca (kit do Meon): o golpe corpo a corpo some e quem bateu leva uma facada.
func _apara_faca(alvo: Unidade, atk: Unidade) -> void:
	var c0: int = _conj_tele
	var e0: int = _eq_tele
	_conj_tele = Pecas.Conjunto.MEON
	_eq_tele = alvo.equipe
	_tele(Pecas.Conjunto.MEON, "aparos", 1.0)
	_dano_poder(alvo, atk, alvo.dano * alvo.bonus_dano * Balanco.APARA_DANO)
	_conj_tele = c0
	_eq_tele = e0
	_ev({"t": "apara", "x": alvo.x, "y": alvo.y, "eq": alvo.equipe, "ax": atk.x, "ay": atk.y})

func _usar_poder_i(u: Unidade) -> bool:
	var meus: Array[Unidade] = aliados if u.equipe == 0 else inimigos
	var outros: Array[Unidade] = []
	for v in (inimigos if u.equipe == 0 else aliados):
		if v.vivo and v.x <= Balanco.VISIVEL_X:
			outros.append(v)
	if u.equipe == 1 and u.x > Balanco.VISIVEL_X:
		return false
	var base: float = Balanco.PODER_DANO * u.poder_forca * u.esc_dano * _fi
	var pontos: Array = []   # onde o efeito acertou (para o desenho)
	var extra: Dictionary = {}   # campos a mais do evento (teletransporte, enxame)
	match u.poder:
		Pecas.Poder.CURA:
			if not _poder_cura(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.PROTEGE, Pecas.Poder.FRENESI:
			if not _poder_protege_frenesi(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.RAIO:
			if not _poder_raio(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.DRENO:
			if not _poder_dreno(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.EXPLOSAO:
			if not _poder_explosao(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.RAJADA:
			if not _poder_rajada(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.GELO:
			if not _poder_gelo(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.ATRAVESSA:
			if not _poder_atravessa(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.INVOCA:
			if not _poder_invoca(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.TELEPORTE:
			if not _poder_teleporte(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.PUXA:
			if not _poder_puxa(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.ENXAME:
			if not _poder_enxame(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.RAIZ:
			if not _poder_raiz(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.SAQUE:
			if not _poder_saque(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.TROVOADA:
			if not _poder_trovoada(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.CANHAO:
			if not _poder_canhao(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.MISSEIS:
			if not _poder_misseis(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.CANCAO:
			if not _poder_cancao(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.INVESTIDA:
			if not _poder_investida(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.FUMACA:
			if not _poder_fumaca(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.FURIA:
			if not _poder_furia(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.PISAO:
			if not _poder_pisao(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.CANTEIRO:
			if not _poder_canteiro(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.TRIAGEM:
			if not _poder_triagem(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.MARCA:
			if not _poder_marca(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.BOLA:
			if not _poder_bola(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.SALVAMENTO:
			if not _poder_salvamento(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.RICOCHETE:
			if not _poder_ricochete(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.OLHAR:
			if not _poder_olhar(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.OBJECAO:
			if not _poder_objecao(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.IMITAR:
			if not _poder_imitar(u, meus, outros, base, pontos, extra):
				return false
			if extra.has("imitou"):
				return true   # o poder copiado já mandou o seu próprio evento
		Pecas.Poder.POQUER:
			if not _poder_poquer(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.TORRE:
			if not _poder_torre(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.MANTEIGA:
			if not _poder_manteiga(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.REVIVER:
			if not _poder_reviver(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.COLHEITA:
			if not _poder_colheita(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.CONSTRUIR:
			if not _poder_construir(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.COCHILO:
			if not _poder_cochilo(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.PLANO:
			if not _poder_plano(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.DOMO:
			if not _poder_domo(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.LOBO:
			if not _poder_lobo(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.TURBO:
			if not _poder_turbo(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.ESFORCO:
			if not _poder_esforco(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.CHUTE:
			if not _poder_chute(u, meus, outros, base, pontos, extra):
				return false
		Pecas.Poder.ATORDOA, Pecas.Poder.EMPURRA, Pecas.Poder.GIRO:
			if not _poder_atordoa_empurra_giro(u, meus, outros, base, pontos, extra):
				return false
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
			if z.get("tipo", "") == "muda":
				_muda_amadurece(z)
			zonas.remove_at(i)
			continue
		if z.get("tipo", "") == "muda":
			continue
		if z.get("tipo", "") == "manteiga":
			_zona_manteiga(z, dt)
			continue
		if z.get("tipo", "") == "domo":
			_zona_domo(z)
			continue
		if z.get("tipo", "") == "chama":
			_zona_chama(z, dt)
			continue
		if z.get("tipo", "enxame") == "canteiro":
			_zona_canteiro(z, dt)
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
			v.vida -= float(z["dps"]) * dt * _vul(v) * (Balanco.PODER_PROTEGE_DANO if v.protegido_t > 0.0 else 1.0)
			v.flash = maxf(v.flash, 0.4)
			if v.vida <= 0.0:
				_matar(v, dono if dono != null and dono.vivo else null, Pecas.Marca.CICATRIZ)

## Dano direto de um poder (ignora armadura e esquiva). Devolve o dano causado.
func _dano_poder(u: Unidade, v: Unidade, dano: float) -> float:
	if not v.vivo:
		return 0.0
	var d: float = dano * _vul(v) * (Balanco.PODER_PROTEGE_DANO if v.protegido_t > 0.0 else 1.0) * (Balanco.PODER_COCHILO_DANO if v.cochilo_t > 0.0 else 1.0) * ((1.0 - Balanco.PODER_LOBO_REDUCAO) if v.lobo_t > 0.0 and v.lobo_prov else 1.0)
	_tele_marca(v, d)
	_tele(_conj_tele, "dano", d)
	v.vida -= d
	v.sono_t = 0.0
	v.flash = 1.0
	_ev({"t": "golpe", "x": v.x, "y": v.y, "dano": d, "eq": v.equipe})
	if v.vida <= 0.0:
		if u.equipe != 0 and v.equipe == 0 and not v.clone:
			gatos_por_poder_bicho += 1
		_tele(_conj_tele, "abates", 1.0)
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
		var d: float = u.barril_dano * v.fraq_explosao * _vul(v)
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
	if u.tiro_duplo > 0.0:
		l.append(["Tiro duplo", pct(u.tiro_duplo)])
	return l

## Nome da herança: o poder e a fantasia de onde veio.
static func heranca_nome(conj: int, grau: int = 1) -> String:
	var c: int = clampi(conj, 0, Pecas.PODER_NOME.size() - 1)
	return "%s (%s)" % [heranca_nome_curto(c, grau), Pecas.CONJUNTO_NOME[c]]

## "Relâmpago" no grau I, "Relâmpago II" a partir do grau II.
static func heranca_nome_curto(conj: int, grau: int = 1) -> String:
	var c: int = clampi(conj, 0, Pecas.PODER_NOME.size() - 1)
	return Pecas.PODER_NOME[c] + ("" if grau <= 1 else " " + Balanco.heranca_grau_romano(grau))
