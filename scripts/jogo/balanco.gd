class_name Balanco
extends RefCounted
## TODAS as constantes de equilíbrio ficam aqui.

# ---------- Regras gerais ----------
const DT := 1.0 / 30.0          # passo fixo da simulação (jogo e simulador)
const ONDAS_TOTAIS := 5         # ondas por fase; o chefe vem na última
const TIJOLOS_INICIAIS := 30
const CUSTO_BONECO := 3
# promover o nível de uma peça com blocos: custo por nível atual da peça (0 -> 1, 1 -> 2, ...); os primeiros níveis custam o de sempre
const PROMOCAO_CUSTO: Array[int] = [2, 2, 2, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7]
# reforçar a raridade de uma peça com troféus, por raridade atual: [comum -> rara, rara -> épica, épica -> lendária, lendária -> mítica, mítica -> miaujestosa]
const REFORCO_CUSTO: Array[int] = [3, 5, 8, 12, 18]
const MAX_BONECOS := 5
const BONECOS_INICIAIS := 3     # o time é fixo; cresce ao vencer fases, até MAX_BONECOS
const NIVEL_MAX := 15           # nível máximo de uma peça (do 11 ao 15 cada nível rende menos: BONUS_NIVEL_ALTO)
const NIVEL_BASE := 10          # até aqui cada nível soma BONUS_NIVEL
const DROP_NIVEL_MAX := 10      # peça que cai de bicho nunca vem acima disto
const INIMIGO_NIVEL_MAX := 5    # (1º e 2º atos; o 3º usa INIMIGO_NIVEL_MAX_ATO)
const INIMIGO_NIVEL_MAX_ATO: Array[int] = [5, 5, 8]   # nível máximo das peças dos bichos por ato (os rivais do 3º ato enfrentam peças de nível 10 a 15)
# ...e o das peças que os bichos vestem (a curva deles não acompanha a das peças do jogador)
const ABATES_BASE := 2          # abates p/ 1º nível; +1 a cada nível
const BONUS_NIVEL := 0.5        # cada nível (até NIVEL_BASE) soma 50% ao efeito numérico
const BONUS_NIVEL_ALTO := 0.25  # ...e cada nível de NIVEL_BASE a NIVEL_MAX soma só 25% (nível 15 = 1 + 5 + 1,25 = 7,25x; antes, 6x no 10)
const DROP_CHANCE := 0.35
const COPIAS_MAX := 2            # o guarda-roupa guarda até 2 de cada peça; a pior sobra
const DROP_NIVEL_POR_PROG := 0.3   # peça largada já vem com nível: cresce com o progresso na campanha
const DROP_MARCA_CHANCE := 0.35   # chance de a peça largada vir com a marca da morte do inimigo
const TORRE_DANO := 1           # tijolos perdidos por golpe de inimigo na torre
const TORRE_INTERVALO_MULT := 1.0
const FERIDA_PERSISTE := true   # boneco não cura entre ondas: corpo gasta, roupa fica
const CURA_MAX := 0.6           # cura entre ondas com a torre cheia; cai junto com os tijolos
# A torre atira: a cadência cai junto com os tijolos
const TORRE_TIRO_DANO := 10.0
const TORRE_TIRO_INTERVALO := 1.0   # segundos entre tiros com a torre cheia
const TORRE_TIRO_ALCANCE := 850.0
const TORRE_TIRO_MIN_TIJOLOS := 4   # abaixo disso a torre não atira

# ---------- Boneco pelado ----------
const BASE_VIDA := 30.0
const BASE_DANO := 2.5
const BASE_INTERVALO := 1.0
const BASE_ALCANCE := 30.0
const BASE_VEL := 80.0
const DANO_MINIMO := 1.0

# ---------- Peças (valores no nível 0) ----------
const PORRETE_DANO := 9.0
const PORRETE_INTERVALO := 1.15
const ESTILINGUE_DANO := 4.5
const ESTILINGUE_INTERVALO := 0.95
const ESTILINGUE_ALCANCE := 250.0
const ESCUDO_REDUCAO := 0.55
const ESCUDO_REDUCAO_NIVEL := 0.07
const ESCUDO_REDUCAO_MAX := 0.8
const ESCUDO_PROVOCA_RAIO := 300.0
const COLETE_VIDA := 32.0
const CAPA_VEL := 1.4
const CAPA_ESQUIVA := 0.40
const CAPA_ESQUIVA_NIVEL := 0.05
const CAPA_ESQUIVA_MAX := 0.65
const ESPINHOS_DANO := 2.5
const ESPINHOS_VIDA := 10.0
const CAPACETE_ARMADURA := 3.5
const CHAPEU_REGEN := 5.0
const MASCARA_RAIO := 130.0
const MASCARA_LENTIDAO := 0.45  # multiplicador de velocidade (menor = mais lento)
const MASCARA_LENTIDAO_NIVEL := 0.06
const MASCARA_LENTIDAO_MIN := 0.3
const LANCA_DANO := 8.0
const LANCA_INTERVALO := 1.1
const LANCA_ALCANCE := 75.0
const TOCHA_DANO := 5.0
const TOCHA_INTERVALO := 1.0
const TOCHA_DPS := 5.5             # dano por segundo da queimadura (x multiplicador de nível)
const TOCHA_DURACAO := 3.0         # segundos; cada golpe renova
const AVENTAL_CURA := 5.5          # vida/s no aliado ferido mais próximo (x nível)
const AVENTAL_RAIO := 130.0
const BARRIL_DANO := 18.0          # explosão ao morrer (x nível)
const BARRIL_RAIO := 90.0
const COROA_BONUS := 0.60          # +60% de dano nos aliados (x nível)
const COROA_RAIO := 140.0
const CHIFRES_BONUS := 1.8         # +180% de dano com vida perto de zero (x nível), linear
const CHIFRES_BONUS_MAX := 3.0     # teto do bônus dos chifres, em qualquer nível

# ---------- Peças novas (valores no nível 0) ----------
const CETRO_DANO := 6.0
const CETRO_INTERVALO := 1.2
const CETRO_AREA := 0.6            # fração do dano nos vizinhos do alvo (soma com a marca Cerco)
const REGADOR_DANO := 3.5
const REGADOR_INTERVALO := 0.9
const REGADOR_ALCANCE := 110.0
const REGADOR_LENTIDAO := 0.5      # multiplicador de velocidade do alvo molhado
const REGADOR_DURACAO := 2.5
const SABRE_DANO := 4.5
const SABRE_INTERVALO := 0.5
const VARINHA_DANO := 9.0
const VARINHA_INTERVALO := 1.6
const VARINHA_ALCANCE := 280.0
const CARTOLA_CRITICO := 0.25
const CARTOLA_CRITICO_NIVEL := 0.04
const CARTOLA_CRITICO_MAX := 0.5
const CARTOLA_MULT := 2.5
const CAUBOI_RAPIDEZ := 0.22       # ataca 22% mais rápido
const CAUBOI_RAPIDEZ_NIVEL := 0.03
const CAUBOI_RAPIDEZ_MAX := 0.45
const TRICORNIO_SAQUE := 0.25      # chance de +1 bloco por abate
const TRICORNIO_SAQUE_NIVEL := 0.05
const TRICORNIO_SAQUE_MAX := 0.6
const PONTUDO_DPS := 2.5           # dano/s nos inimigos em volta (x nível)
const PONTUDO_RAIO := 110.0
const PELE_VIDA := 18.0
const PELE_CURA := 0.25            # fração da vida máxima curada a cada abate
const PONCHO_VIDA := 10.0
const PONCHO_FURO := 0.5           # redução do dano de projéteis (soma com a marca Furo)
const CASACO_VIDA := 16.0
const CASACO_EMBALO := 0.10        # +dano por abate nesta luta
const CASACO_EMBALO_MAX := 1.0
const MANTO_INTERVALO := 5.0       # segundos entre barreiras
const MANTO_INTERVALO_NIVEL := 0.5
const MANTO_INTERVALO_MIN := 2.5
const BOTAS_VEL := 1.35
const BOTAS_VIDA := 6.0
const JOELHEIRAS_REDUCAO := 0.15
const JOELHEIRAS_REDUCAO_NIVEL := 0.03
const JOELHEIRAS_REDUCAO_MAX := 0.35
const BANDEIRA_REGEN := 2.0        # vida/s nos aliados em volta (x nível)
const BANDEIRA_RAIO := 140.0
const NARIZ_ESQUIVA := 0.15
const NARIZ_ESQUIVA_NIVEL := 0.03
const NARIZ_ESQUIVA_MAX := 0.35
const ESQUIVA_MAX := 0.75          # teto da esquiva somada
const COLAR_DANO := 0.2            # +20% de dano (x nível)
const SEMENTES_CURA := 0.3         # fração da vida máxima curada nos aliados ao morrer
const SEMENTES_CURA_NIVEL := 0.05
const CANTIL_LIMIAR := 0.35        # bebe abaixo desta fração de vida
const CANTIL_CURA := 0.45
const CANTIL_CURA_NIVEL := 0.05
const GANCHO_ROUBO := 0.2          # fração do dano causado que volta em vida
const GANCHO_ROUBO_NIVEL := 0.04
const ROUBO_MAX := 0.6             # teto do roubo de vida somado

# ---------- Fantasias: [bônus com 2 ou 3 peças, bônus com as 4] ----------
const CONJ_CAVALEIRO_ARMADURA: Array[float] = [2.0, 5.0]
const CONJ_GUARDIAO_VIDA: Array[float] = [0.2, 0.5]
const CONJ_REI_DANO: Array[float] = [0.1, 0.25]
const CONJ_CIRCO_EXPLOSAO: Array[float] = [10.0, 25.0]
const CONJ_VIKING_DANO: Array[float] = [0.15, 0.4]
const CONJ_JARDINEIRO_REGEN: Array[float] = [2.0, 5.0]
const CONJ_CAUBOI_RAPIDEZ: Array[float] = [0.1, 0.25]
const CONJ_PIRATA_ROUBO: Array[float] = [0.1, 0.25]
const CONJ_MAGO_QUEIMA: Array[float] = [2.0, 5.0]
# Fantasias da expansão (lote 1): [2 ou 3 peças, 4 peças]. O tipo de bônus está em Pecas.CONJUNTO_MOLDE.
const CONJ_NOVOS: Dictionary = {
	Pecas.Conjunto.SUPER_MIAU: [0.25, 0.5],           # cantil: fração da vida curada uma vez
	Pecas.Conjunto.ARQUEIRO_MIAU: [0.15, 0.35],       # chance de crítico
	Pecas.Conjunto.MOTOQUEIRO_MIAUSMA: [3.0, 6.0],    # queimadura por segundo
	Pecas.Conjunto.FENIX_MIAUSSIMO: [3.0, 7.0],       # armadura
	Pecas.Conjunto.MIMIAU: [7.0, 3.0],                # 2 ou 3 peças: segundos entre barreiras; 4 peças: Disfarce (segundos de atordoamento)
	Pecas.Conjunto.JIMIAU: [0.05, 0.12],              # recarga do poder mais curta
	# lote 2
	Pecas.Conjunto.DISPARAMIAU: [0.15, 0.35],         # chance de atirar duas vezes
	Pecas.Conjunto.MILHAU: [0.25, 0.5],               # chance de o golpe deixar o alvo lento
	Pecas.Conjunto.GIRAMIAU: [1.5, 4.0],              # vida/s nos aliados em volta
	Pecas.Conjunto.STARDEW_MIAULLEY: [0.25, 0.5],     # sementes: fração da vida curada nos aliados ao cair
	Pecas.Conjunto.MIAUCRAFT: [12.0, 30.0],           # explode ao morrer (Circo)
	Pecas.Conjunto.MIAULAX: [0.1, 0.15],              # vida a mais (Guardião)
	# lote 3
	Pecas.Conjunto.LEONARMIAU: [0.1, 0.25],           # aliados por perto: dano a mais (aura do Rei)
	Pecas.Conjunto.DONATEMIAU: [0.08, 0.18],          # chance de o golpe atordoar
	Pecas.Conjunto.RAFAMIAU: [0.5, 1.4],              # chifres: dano a mais com a vida perto de zero
	Pecas.Conjunto.ROCKET_MIAUGUE: [0.2, 0.45],       # velocidade de movimento
	Pecas.Conjunto.DEADMIAU: [3.0, 6.0],              # regeneração por segundo
	Pecas.Conjunto.MEON: [0.2, 0.4],                  # chance de aparar um golpe corpo a corpo com a faca
	# lote 4
	Pecas.Conjunto.MIAU_NOIR: [1.8, 2.5],             # emboscada: multiplicador do 1º golpe em cada inimigo
	Pecas.Conjunto.HOLLOWMIAU: [20.0, 50.0],          # alcance a mais
	Pecas.Conjunto.SILKMIAU: [0.2, 0.45],             # cerco: fração do dano que fere em volta
	Pecas.Conjunto.SUPER_MIAUJIN: [0.3, 0.6],         # execução: dano a mais em quem está abaixo de EXECUCAO_LIMIAR
	Pecas.Conjunto.ARQUEOLOGO: [0.1, 0.25],           # esquiva
	Pecas.Conjunto.TREINADOR: [0.04, 0.1],            # cura por abate (fração da vida máxima)
	# lote 5
	Pecas.Conjunto.RANGER_MIAU: [0.1, 0.25],          # ataca mais rápido (molde do Caubói)
	Pecas.Conjunto.MIAUZILLA: [4.0, 10.0],            # espinho: dano devolvido a quem bate de perto
	Pecas.Conjunto.KING_MIAU: [0.15, 0.4],            # dano a mais (molde do Viking)
	Pecas.Conjunto.ARTHUR_MIAURGON: [0.25, 0.5],      # cantil: fração da vida curada uma vez
	Pecas.Conjunto.SUBMIAUTICA: [0.2, 0.4],           # segundo fôlego: levanta uma vez com esta fração da vida
	Pecas.Conjunto.CATCHULLU: [0.08, 0.18],           # chance de o golpe assustar o alvo
}
const SUSTO_KIT_T := 0.8        # Catchullu: segundos de medo de um golpe que assusta
const EXECUCAO_LIMIAR := 0.25   # Super Miaujin: vida abaixo da qual o golpe fere mais
const CRITICO_MAX := 0.8   # teto do crítico somado (Cartola + kit do Arqueiro)

## Valor do bônus de kit da fantasia `c` no grau `g` (0 = 2 ou 3 peças, 1 = as 4).
static func conj_valor(c: int, g: int) -> float:
	c = Pecas.conj_do_bonus(c)   # o Ateliê usa o valor do bônus que o jogador escolheu
	if CONJ_NOVOS.has(c):
		return float((CONJ_NOVOS[c] as Array)[g])
	match Pecas.CONJUNTO_MOLDE[c]:
		Pecas.Conjunto.CAVALEIRO: return CONJ_CAVALEIRO_ARMADURA[g]
		Pecas.Conjunto.GUARDIAO: return CONJ_GUARDIAO_VIDA[g]
		Pecas.Conjunto.REI: return CONJ_REI_DANO[g]
		Pecas.Conjunto.CIRCO: return CONJ_CIRCO_EXPLOSAO[g]
		Pecas.Conjunto.VIKING: return CONJ_VIKING_DANO[g]
		Pecas.Conjunto.JARDINEIRO: return CONJ_JARDINEIRO_REGEN[g]
		Pecas.Conjunto.CAUBOI: return CONJ_CAUBOI_RAPIDEZ[g]
		Pecas.Conjunto.PIRATA: return CONJ_PIRATA_ROUBO[g]
		Pecas.Conjunto.MAGO: return CONJ_MAGO_QUEIMA[g]
	return 0.0

# ---------- Raridades (comum, rara, épica, lendária, mítica, miaujestosa) ----------
# A Miaujestosa não cai de bicho nem nasce de fusão: só se chega a ela reforçando uma Mítica (ou como prêmio do chefe secreto).
const RARIDADE_PODER: Array[float] = [1.0, 1.15, 1.3, 1.45, 1.6, 1.8]   # multiplicador do efeito
const RARIDADE_MARCAS: Array[int] = [2, 3, 3, 4, 5, 6]                # marcas que a peça aguenta
# Chances de drop. `g` = "degrau" do lugar: 0..4 nos cômodos, 5..9 fora da casa; a invasão soma mais (INVASAO_DROP_*).
# Cada raridade só passa a cair depois do degrau `*_DESDE`; a chance cresce `*_FASE` por degrau.
const DROP_RARA := 0.06            # inimigo comum
const DROP_RARA_FASE := 0.03
const DROP_RARA_TETO := 5.0        # degrau a partir do qual a chance de rara para de crescer
const DROP_EPICA_FASE := 0.01
const DROP_LENDARIA_FASE := 0.006
const DROP_LENDARIA_DESDE := 3.0
const DROP_MITICA_FASE := 0.004
const DROP_MITICA_DESDE := 6.0
const ELITE_RARA := 0.45           # fantasiado
const ELITE_EPICA := 0.05
const ELITE_EPICA_FASE := 0.02
const ELITE_LENDARIA_FASE := 0.02
const ELITE_MITICA_FASE := 0.01
const CHEFE_EPICA := 0.25          # o chefe larga no mínimo rara
const CHEFE_EPICA_FASE := 0.1
const CHEFE_EPICA_TETO := 4.0
const CHEFE_LENDARIA_FASE := 0.06
const CHEFE_MITICA_FASE := 0.03
const CHEFE_MITICA_DESDE := 5.0
const INVASAO_DROP_DEGRAU := 0.4   # na invasão, cada onda vencida sobe o degrau de drop...
const INVASAO_DROP_DEGRAU_MAX := 4.0   # ...até este tanto
# Onde cai cada fantasia (notas/onde_cai_final.md, seção 5.9)
const FRACAO_COMUM_DO_LUGAR := 0.25    # 2º e 3º atos: fração das peças dos comuns que vem da lista do lugar (o resto, dos atos anteriores)
const CHEFE_ASSINATURA_CHANCE := 0.6   # chance de o chefe vestir a fantasia-assinatura do lugar
const PESO_PECA_FALTA := 3.0           # fantasiado e chefe: peso de largar uma peça que o jogador ainda não teve (as outras pesam 1)
const PESO_FANTASIA_FALTA := 2.0       # peso, no sorteio de fantasiados e do chefe, da fantasia que o jogador ainda não completou
const DEGRAU_RARIDADE_MAX := 12.0      # teto do degrau de drop nas curvas de raridade (3º ato: degraus 10..14; sem teto o fantasiado somava 108% no último lugar)

## Blocos para subir a peça do nível `nivel` para o seguinte.
static func custo_promocao(nivel: int) -> int:
	return PROMOCAO_CUSTO[clampi(nivel, 0, PROMOCAO_CUSTO.size() - 1)]

## Troféus para subir uma peça da raridade `rar` para a seguinte.
static func custo_reforco(rar: int) -> int:
	return REFORCO_CUSTO[clampi(rar, 0, REFORCO_CUSTO.size() - 1)]

## Chances de raridade [mítica, lendária, épica, rara] de um drop no degrau `g` (já com o teto DEGRAU_RARIDADE_MAX);
## o resto é comum. A soma nunca passa de 1 (testado).
static func chances_raridade(g: float, chefe: bool, elite: bool) -> Array[float]:
	g = minf(g, DEGRAU_RARIDADE_MAX)
	var mitica: float
	var lend: float
	var epica: float
	var rara: float
	if chefe:
		# o chefe larga no mínimo rara
		mitica = maxf(0.0, g - CHEFE_MITICA_DESDE) * CHEFE_MITICA_FASE
		lend = maxf(0.0, g - DROP_LENDARIA_DESDE) * CHEFE_LENDARIA_FASE
		epica = CHEFE_EPICA + minf(g, CHEFE_EPICA_TETO) * CHEFE_EPICA_FASE
		rara = 1.0
	elif elite:
		mitica = maxf(0.0, g - DROP_MITICA_DESDE) * ELITE_MITICA_FASE
		lend = maxf(0.0, g - DROP_LENDARIA_DESDE) * ELITE_LENDARIA_FASE
		epica = ELITE_EPICA + g * ELITE_EPICA_FASE
		rara = ELITE_RARA
	else:
		mitica = maxf(0.0, g - DROP_MITICA_DESDE) * DROP_MITICA_FASE
		lend = maxf(0.0, g - DROP_LENDARIA_DESDE) * DROP_LENDARIA_FASE
		epica = g * DROP_EPICA_FASE
		rara = DROP_RARA + minf(g, DROP_RARA_TETO) * DROP_RARA_FASE
	return [mitica, lend, epica, rara]

## Degrau do lugar para os drops: 0..4 nos cômodos, 5..9 fora da casa, 10..14 no 3º ato, mais o avanço da invasão.
static func degrau_drop(fase: int, ato: int, invasao: bool, onda_invasao: int) -> float:
	var g: float = float(fase - 1) + float(Fases.TOTAL * (ato - 1))
	if invasao:
		g += minf(INVASAO_DROP_DEGRAU_MAX, INVASAO_DROP_DEGRAU * (onda_invasao - 1))
	return g

# ---------- Marcas (a morte do portador marca a peça) ----------
const MARCA_CICATRIZ_VIDA := 12.0  # vida máxima por marca
const MARCA_CERCO_MINIMO := 3      # inimigos vivos perto de quem morreu para contar como cerco
const MARCA_CERCO_RAIO_MORTE := 80.0
const MARCA_CERCO_RAIO_GOLPE := 60.0   # raio (em volta do alvo) do golpe em área
const MARCA_CERCO_DANO := 0.35     # fração do dano do golpe, por marca
const MARCA_FURO_REDUCAO := 0.25   # redução do dano de projéteis, por marca
const MARCA_FURO_MAX := 0.75
const MARCA_BRASA_DPS := 2.0       # dano/s da queimadura por marca (soma com a Tocha)
const MARCA_POLVORA_DANO := 10.0   # dano da explosão ao morrer por marca (soma com o Barril)

# ---------- Ondas / inimigos ----------
const INIMIGOS_BASE := 3.0
const INIMIGOS_POR_ONDA := 0.8
const INIMIGO_VIDA_MULT := 0.6
const INIMIGO_VIDA_ONDA := 0.06
const INIMIGO_DANO_ONDA := 0.03
const PECAS_BASE := 0.3
const PECAS_POR_ONDA := 0.25
const NIVEL_INIMIGO_POR_ONDA := 0.18
const SPAWN_INICIO := 0.2           # segundos até o primeiro inimigo poder entrar
const ENTRADA_VEL := 2.6            # inimigos entram correndo até ENTRADA_X; depois andam no passo normal
const ENTRADA_X := 880.0
const SPAWN_MIN := 0.4
const SPAWN_MAX := 1.3

# ---------- Chefes ----------
const CHEFE_VIDA_MULT := 5.0        # sobre a vida de um inimigo comum da mesma onda
const CHEFE_VIDA_FASE := 0.15       # crescimento extra por fase depois da primeira
const CHEFE_DANO_MULT := 1.4
const CHEFE_VEL := 0.65
const CHEFE_TORRE_DANO := 2         # tijolos por golpe do chefe na torre
const CHEFE_NIVEL_BONUS := 1        # níveis das peças do chefe acima dos inimigos da onda
const CHEFE_LACAIOS := 0.6          # fração dos inimigos comuns numa onda de chefe
const CHEFE_ATRASO := 2.5           # segundos depois do último lacaio
const CHEFE_ESCALA_TIPO: Array[float] = [1.0, 1.0, 1.0, 0.88, 1.0, 1.0, 0.8, 0.8, 0.8, 0.9, 0.78, 0.78, 0.78, 0.8, 0.8, 0.8]   # acerto por chefe: nenhum passa de ~2,1x a altura de um gato
const CHEFE_ESCALA := 1.7           # tamanho na tela

# ---------- Chefes de cada fase (ver Fases.Chefe) ----------
const GENERAL_REFORCO_T := 13.0      # segundos entre chamadas
const GENERAL_REFORCO_N := 1
const GENERAL_VEL := 0.75           # multiplicador extra de velocidade
const URSO_AREA := 1.0              # fração do dano nos vizinhos do alvo
const URSO_FOGO := 2.0              # multiplicador do dano de fogo recebido
const ROBO_CORDA_T := 6.0           # segundos correndo para a torre
const ROBO_PARADO_T := 3.5          # segundos sem corda
const ROBO_VEL := 2.2
const ROBO_PARADO_DANO := 2.0       # multiplicador do dano recebido sem corda
const BONECA_ALCANCE := 340.0
const BONECA_VIDA := 0.75
const BONECA_CORPO := 1.5           # multiplicador do dano corpo a corpo recebido
const MASSINHA_REGEN := 0.012       # fração da vida máxima por segundo
const MASSINHA_PARTES := 3
const MASSINHA_PARTE_VIDA := 0.25   # vida de cada parte, fração da vida máxima do chefe
const MASSINHA_PARTE_ESCALA := 1.15
const MASSINHA_EXPLOSAO := 2.0      # multiplicador do dano de explosão recebido
# ---- chefes do segundo ato (fora da casa)
const TOUPEIRA_FORA_T := 6.0        # segundos na superfície entre um mergulho e outro
const TOUPEIRA_CAVA_T := 1.4        # segundos debaixo da terra (não leva dano)
const TOUPEIRA_TONTA_T := 1.2       # sai do buraco parada...
const TOUPEIRA_TONTA_DANO := 1.6    # ...e recebendo mais dano
const GAMBA_RAIO := 150.0           # fedor: gatos dentro ficam lentos
const GAMBA_LENTIDAO := 0.6
const GAMBA_GAS_T := 9.0            # segundos entre nuvens que atordoam
const GAMBA_GAS_ATORDOA := 1.0
const GAMBA_FOGO := 2.0
# CORUJA = Esquilo Acrobata (chefe do Telhado): arremessa bolotas de longe e o "rasante" é o salto acrobático pela faixa
const CORUJA_ALCANCE := 320.0
const CORUJA_VIDA := 0.8
const CORUJA_RASANTE_T := 10.0
const CORUJA_RASANTE_DANO := 0.9    # x o dano do golpe, em todos os gatos da faixa
const CORUJA_RASANTE_LARGURA := 70.0
const CORUJA_EXPLOSAO := 2.0
const VIRALATA_LATIDO_T := 10.0
const VIRALATA_LATIDO_RAIO := 210.0
const VIRALATA_EMPURRA := 90.0
const VIRALATA_ATORDOA := 0.5
const VIRALATA_FOLEGO_T := 2.2      # depois de latir: parado, recebendo VIRALATA_FOLEGO_DANO
const VIRALATA_FOLEGO_DANO := 2.0
const VIRALATA_MATILHA_T := 14.0
const VIRALATA_MATILHA_N := 2
const TEXUGO_COURO := 3.0           # armadura (x a escala de dano da onda): golpe fraco quase não fere
const TEXUGO_FURIA := 0.5           # abaixo desta fração da vida ataca em dobro

# ---------- Invasão sem fim (depois de zerar) ----------
const INVASAO_VIDA_ONDA2 := 0.010    # ...e mais isto vezes o quadrado das ondas vencidas: time forte também encontra o teto
const INVASAO_DANO_ONDA2 := 0.003
const INVASAO_FORA_VIDA := 0.38        # a invasão num lugar de fora começa abaixo da força do segundo ato...
const INVASAO_FORA_DANO := 0.5        # ...porque o time já entra nela no degrau mais alto
const INVASAO_RUAS_VIDA := 0.26        # invasão nas ruas (3º ato, 5 gangues misturadas): calibrar com o simulador (recorde mediano ~ o de fora)
const INVASAO_RUAS_DANO := 0.5
const INVASAO_VIDA_ONDA := 0.30     # +vida dos bichos por onda de invasão vencida
const INVASAO_DANO_ONDA := 0.13     # +dano dos bichos por onda de invasão vencida

# ---------- Campanha e inimigos fantasiados ----------
const PROG_POR_FASE := 3            # cada fase começa 3 ondas "à frente" da anterior em força
# o guarda-roupa do jogador cresce depressa nas primeiras fases e depois estabiliza:
# a força dos inimigos acompanha com um multiplicador por fase
const FASE_VIDA: Array[float] = [0.8, 1.3, 4.1, 2.8, 2.25]
const FASE_DANO: Array[float] = [0.85, 1.05, 2.0, 1.5, 1.4]
const INIMIGOS_POR_FASE := 1.0      # inimigos a mais por onda, por fase
const ELITE_ONDA_MIN := 2           # primeira onda da fase com inimigo fantasiado
const ELITE_ONDA_DOIS := 4          # a partir desta onda vêm dois (menos na onda do chefe)
const ELITE_PECAS: Array[int] = [3, 4, 4, 4, 4]   # peças da fantasia que o fantasiado veste, por fase
const ELITE_ESCALA := 1.12

# ---------- Tipos de inimigo (ordem de Unidade.Tipo: comum, saltador, ladrão, gigante, gêmeo, atirador, curandeiro, escudeiro, bomba) ----------
const TIPO_NOMES: Array[String] = ["Bicho comum", "Saltador", "Ladrão", "Grandalhão", "Ninhada", "Atirador", "Curandeiro", "Escudeiro", "Bicho-bomba"]
const TIPO_PROG_MIN: Array[int] = [1, 2, 3, 5, 6, 9, 13, 17, 21]        # primeiro progresso (ver progresso()) em que aparece
const TIPO_VIDA: Array[float] = [1.0, 1.0, 1.2, 8.0, 1.0, 0.8, 0.9, 1.8, 0.7]  # multiplicador de vida
const TIPO_VEL: Array[float] = [1.0, 1.8, 1.3, 0.6, 1.0, 0.9, 0.85, 0.8, 1.6]   # multiplicador de velocidade
const TIPO_ESCALA: Array[float] = [1.0, 0.92, 0.95, 1.4, 1.0, 0.98, 0.98, 1.12, 0.9]  # tamanho na tela
const ATIRADOR_ALCANCE := 230.0     # atira de longe nos gatos (e na torre)
const ATIRADOR_DANO := 0.8          # multiplicador do dano
const CURANDEIRO_CURA := 3.0        # vida/s no bicho ferido mais próximo (x a escala de vida da onda)
const CURANDEIRO_DANO := 0.5
const ESCUDEIRO_REDUCAO := 0.4      # leva menos dano e chama os golpes dos gatos para si
const BOMBA_DANO := 12.0            # explosão ao encostar num gato ou ao cair (x a escala de dano da onda)
const BOMBA_TORRE := 2              # blocos que leva junto se chega à torre
const ESPECIAL_FRACAO := 0.4       # no máximo esta fração da onda é especial
const ESPECIAL_CHANCE := 0.9        # chance de cada vaga livre (até o teto) virar especial
const LADRAO_ROUBO := 2             # tijolos roubados num golpe
const LADRAO_FUGA_VEL := 1.3       # multiplicador extra de velocidade ao fugir
const GIGANTE_TORRE_DANO := 2       # tijolos por golpe do gigante na torre
const GEMEO_VIDA := 0.6             # vida de cada filhote, fração da vida máxima do gêmeo
const GEMEO_ESCALA := 0.7

# ---------- Linhas (posição dos bonecos) ----------
const LINHA_X: Array[float] = [700.0, 560.0, 430.0]  # frente, meio, fundo: posto no meio do campo, para onde o gato corre ao sair da torre
const LINHA_MEIO_DIST := 420.0      # o meio só avança com inimigo a até esta distância
const LINHA_FUNDO_DIST := 120.0     # o fundo só luta com quem chega a esta distância (ou ao alcance, se atira)
const LINHA_ALTERNA := -62.0          # recuo do 2º, 4º... gato da mesma linha
const LINHA_CASA_MARGEM := 8.0
const LINHA_CORRIDA := 2.2            # sem alvo e longe do posto, o gato corre até ele (não fica esperando)
const LINHA_CORRIDA_DIST := 40.0

# ---------- Preparação da onda: posto, postura e alvo prioritário ----------
const POSTO_X0 := 250.0             # limites de onde o jogador pode largar um gato
const POSTO_X1 := 800.0
const POSTO_Y0 := 485.0
const POSTO_Y1 := 630.0
const RECUAR_X := 255.0             # postura Recuar: o gato fica junto da torre
const RECUAR_DIST := 170.0          # ...e só luta com quem chega a esta distância (ou ao alcance, se atira)
const PRIORIDADE_BONUS := 600.0     # desconto na "distância" do bicho do tipo marcado como alvo prioritário
const PRIORIDADE_VISAO := 1.5       # quem segura ou recua enxerga o alvo prioritário um pouco mais longe

# ---------- Escolha de alvo (gatos e bichos) ----------
const ALVO_APEGO := 45.0            # o alvo atual vale esta "distância" a menos: não fica trocando à toa
const ALVO_LOTADO := 34.0           # cada colega corpo a corpo já em cima do mesmo alvo afasta o próximo
const ALVO_LOTADO_MAX := 3          # ...até este número de colegas (chefe e grandalhão não contam)
const ALVO_TORRE := 110.0           # gato prefere o bicho que está batendo (ou vai bater) na torre
const ALVO_FERIDO := 40.0           # e o que está quase caindo
const SEPARA_RAIO := 30.0           # unidades do mesmo lado a menos disto se afastam (não viram um bolo)
const SEPARA_VEL := 46.0            # px/s do empurrão

# ---------- Time fixo: nível e treino dos bonecos ----------
const BONECO_NIVEL_MAX := 40       # 4 heranças (aos 10, 20, 30 e 40); a 4ª é prêmio de fim de jogo
const XP_NIVEL_TETO := 10           # depois deste nível, o custo de cada nível para de crescer

# ---------- Herança: a cada HERANCA_NIVEIS níveis o gato incorpora, como passiva, o poder da fantasia completa que veste ----------
const HERANCA_NIVEIS := 10
const HERANCA_INTERVALO := 14.0     # segundos entre disparos automáticos de um poder herdado
const HERANCA_PRIMEIRO := 6.0       # segundos até o primeiro disparo na luta
const HERANCA_FORCA := 0.45         # força do poder herdado (o da roupa usa a força das peças, perto de 1 ou mais)...
const HERANCA_FORCA_NIVEL := 0.02   # ...mais isto por nível do gato
const HERANCA_APOIO := 0.5          # cura, proteção e frenesi herdados valem esta fração
# Grau: incorporar a MESMA fantasia de novo sobe o grau da herança (I, II, III) em vez de criar outra igual.
const HERANCA_GRAU_MAX := 3
const HERANCA_GRAU_FORCA := 0.35    # cada grau acima do I soma isto à força (e à fração dos poderes de apoio)
const HERANCA_GRAU_INTERVALO := 2.0 # ...e tira estes segundos do intervalo entre disparos

static func heranca_grau_romano(grau: int) -> String:
	return ["I", "I", "II", "III"][clampi(grau, 0, 3)]

static func heranca_intervalo(grau: int) -> float:
	return HERANCA_INTERVALO - HERANCA_GRAU_INTERVALO * (maxi(grau, 1) - 1)

static func heranca_mult(grau: int) -> float:
	return 1.0 + HERANCA_GRAU_FORCA * (maxi(grau, 1) - 1)

## Texto curto de como a herança age (igual para todo poder: ele dispara sozinho).
static func heranca_efeito(_tipo: int) -> String:
	return "ele solta sozinho a cada %d s, mais fraco que o da roupa" % int(HERANCA_INTERVALO)

const XP_BASE := 2                  # experiência para o 1º nível; +1 a cada nível
const XP_ONDA_DE_PE := 2            # por onda vencida terminando de pé
const XP_ONDA_ATO: Array[int] = [2, 5, 5]   # ...por ato: cada ato leva o time uns 10 níveis adiante (quem cai ganha a metade)

# ---------- Atos: depois do Porão a casa é invadida de novo, na ordem que o jogador quiser ----------
const ATOS := 3
const ATO_NOME: Array[String] = ["Primeiro ato", "Segundo ato", "Terceiro ato"]
const ATO_VIDA: Array[float] = [1.0, 2.0, 2.6] # força dos bichos no primeiro cômodo vencido do ato
const ATO_DANO: Array[float] = [1.0, 1.3, 1.3]
const ATO_VIDA_DEGRAU := 0.10       # cada cômodo já vencido no ato deixa os que faltam mais fortes
const ATO_DANO_DEGRAU := 0.05
# acerto por lugar, uma lista por ato (o 1º ato não usa); chefe e família pesam diferente; 2º ato refeito com as listas novas (onde_cai_final.md)
const ATO_COMODO_VIDA: Array = [[1.0, 1.0, 1.0, 1.0, 1.0], [1.12, 0.92, 1.05, 1.15, 1.08], [0.68, 0.83, 0.47, 0.64, 0.37]]
const ATO_COMODO_DANO: Array = [[1.0, 1.0, 1.0, 1.0, 1.0], [1.08, 0.82, 1.0, 1.15, 1.06], [0.72, 0.85, 0.52, 0.7, 0.47]]
const RIVAL_FRACAO_DO_LUGAR := 0.6  # 3º ato: fração das peças vestidas pelos rivais comuns que vem da lista do lugar (o resto, dos atos anteriores)
const MORAL_T := 6.0                # 3º ato, Moral simples: segundos que os rivais ficam abalados quando o líder cai
const MORAL_DANO := 0.30            # abalado: -30% de dano
const MORAL_VEL := 0.30             # abalado: -30% de velocidade (anda e ataca mais devagar)
const AGGRO_RIVAL := 100000.0       # Disputa: o rival escolhe alvo entre todos os gatos de pé, sem o limite do AGGRO
# ---- Tipos de rival e truque de cada gangue (3º ato, etapa 4; notas/ato3_proposta.md, 1.2)
# Índices de Unidade.Tipo: 0 comum, 1 saltador, 2 ladrão, 3 grandalhão, 4 ninhada, 5 atirador, 6 curandeiro, 7 escudeiro, 8 bomba.
## Tipos especiais permitidos em cada gangue: [tipo, peso]. No 3º ato isto substitui o sorteio global de _sortear_tipos.
const GANGUE_TIPOS: Array = [
	[[1, 2], [2, 3], [3, 2], [4, 2]],                          # Família Gatíssima: Entregador, Mensageiro, Capanga, gata e gatinhos
	[[1, 3], [2, 1], [3, 1], [4, 1], [5, 2], [8, 2]],          # Estrada Furiosa: Motoqueiro, Saqueador, Brutamontes, motinhas, Guitarrista, Suicida
	[[1, 1], [2, 1], [3, 1], [4, 2], [5, 3]],                  # Tropa do Grid: Piloto, Programa-ladrão, Programa pesado, Pixels, Lançador de Discos
	[[1, 1], [2, 1], [4, 1], [7, 6]],                          # Legião Miauparta: Chutador, Batedor, novatos, Hoplita (a falange precisa de vários)
	[[1, 2], [2, 1], [3, 2], [4, 2], [5, 2]],                  # Irmandade Mutante: Garra-Fera, ladrão, Mutante Pesado, Ninhada, Telepata
]
const GANGUE_ESPECIAL_FRACAO: Array[float] = [0.4, 0.45, 0.4, 0.55, 0.4]   # fração da onda que é de tipo especial, por gangue
## Nome de cada tipo em cada gangue ("" = o nome de TIPO_NOMES), na ordem de Unidade.Tipo.
const GANGUE_TIPO_NOME: Array = [
	["Vira-lata de gangue", "Entregador de moto", "Mensageiro", "Capanga de sobretudo", "Gata e gatinhos", "", "", "", ""],
	["Vira-lata de gangue", "Motoqueiro", "Saqueador", "Brutamontes", "Ninhada de motinhas", "Guitarrista", "", "", "Suicida pintado"],
	["Programa", "Piloto de moto de luz", "Programa-ladrão", "Programa pesado", "Pixels", "Lançador de discos", "", "", ""],
	["Recruta da Legião", "Chutador", "Batedor", "", "Escudeiros novatos", "", "", "Hoplita", ""],
	["Mutante", "Garra-fera", "Ladrão mutante", "Mutante pesado", "Ninhada mutante", "Telepata", "", "", ""],
]
## Dica de cada tipo em cada gangue (menos de 80 caracteres; "" = a dica de sempre do tipo).
const GANGUE_TIPO_DICA: Array = [
	["", "Corre de moto direto à torre.", "Ao tocar a torre, leva um gato para dormir 6 s. Mate antes!", "Lento, muita vida; derruba 2 blocos por golpe.", "", "", "", "", ""],
	["", "Passa batido e acerta o gato de trás antes de ir à torre.", "Rouba blocos da torre e foge com eles.", "", "Ao cair, vira dois filhotes.", "Dá velocidade ao comboio em volta; atira de longe.", "", "", "Corre ao primeiro gato ou à torre e explode."],
	["Volta uma vez com 40% de vida ao ser derrotado.", "Corre à torre largando um rastro de luz que fere quem passa.", "Rouba blocos da torre e foge com eles.", "Lento, muita vida; derruba 2 blocos por golpe.", "", "Atira discos que quicam em até 3 gatos.", "", "", ""],
	["", "Corre direto à torre.", "Rouba blocos da torre e foge com eles.", "", "Ao cair, vira dois filhotes.", "", "", "Em falange, leva menos dano de frente. Ataque pelos flancos!", ""],
	["Abaixo de 30% de vida, fica mais forte e mais rápido.", "Corre à torre, regenera vida e enfurece com pouca vida.", "Rouba blocos da torre e foge com eles.", "Lento, muita vida; derruba 2 blocos por golpe.", "Ao cair, vira dois filhotes.", "Seu tiro confunde: o gato bate no aliado mais perto.", "", "", ""],
]
# Oferta (Família Gatíssima): o Mensageiro, ao tocar a torre, leva um gato para dormir com os peixes
const OFERTA_T := 6.0               # segundos que o gato sequestrado fica fora da luta
# Comboio (Estrada Furiosa): o Guitarrista acelera os rivais da gangue em volta
const COMBOIO_RAIO := 200.0
const COMBOIO_VEL := 0.35           # +35% de velocidade (anda e ataca)
# Disco (Tropa do Grid): o projétil do Lançador quica em mais alvos
const DISCO_QUICAS := 2             # quicadas depois do primeiro alvo (3 alvos no total)
const DISCO_RAIO := 200.0           # distância máxima de um alvo ao seguinte
const DISCO_FATOR := 0.8            # dano de cada quicada sobre o anterior
# Recompilação (Tropa do Grid): o Programa volta uma vez
const RECOMPILA_VIDA := 0.4         # fração da vida máxima com que volta
const RECOMPILA_PROTEGE := 1.0      # segundos protegido ao voltar
# Falange (Legião Miauparta): hoplitas juntos levam menos dano de frente
const FALANGE_POR_VIZINHO := 0.15   # redução a mais por hoplita vizinho
const FALANGE_MAX := 3
const FALANGE_RAIO := 110.0         # distância (x) em que um hoplita conta como vizinho
const FALANGE_RAIO_Y := 70.0
const FALANGE_FLANCO := 60.0        # golpe vindo de mais de |dy| = isto é de flanco e fura a falange
# Mutação (Irmandade Mutante): abaixo do limiar de vida, mais dano e velocidade
const MUTACAO_LIMIAR := 0.30
const MUTACAO_DANO := 0.30
const MUTACAO_VEL := 0.30
# Rastro de luz (Tropa do Grid): o Piloto deixa pedaços de luz pelo caminho que ferem os gatos que os atravessam
const RASTRO_T := 2.0               # segundos que cada pedaço dura
const RASTRO_PASSO := 36.0          # a cada tanto andado, o Piloto larga um pedaço
const RASTRO_RAIO := 30.0           # alcance (x) de um pedaço sobre o gato
const RASTRO_RAIO_Y := 24.0
const RASTRO_DANO := 0.7            # fração do dano do Piloto a cada ferroada
const RASTRO_INTERVALO := 0.6       # segundos entre ferroadas no mesmo gato
# Confusão (Irmandade Mutante): o tiro do Telepata faz o gato bater no aliado mais perto
const TELEPATA_T := 1.5             # segundos de confusão
const TELEPATA_RECARGA := 4.0       # depois de confuso, o gato fica imune por este tempo
# Regeneração (Irmandade Mutante): a Garra-Fera recupera esta fração da vida máxima por segundo
const GARRA_REGEN := 0.02
# ---- Gato de Schrödinger (chefe secreto, caixa do Sótão): alterna entre vivo e morto
const SCHRO_T := 6.0                # segundos em cada estado
const SCHRO_AVISO := 1.2            # aviso antes de cada troca
const SCHRO_VIDA := 4.0             # multiplicador de vida do chefe (calibrar com teste_secretos)
const SCHRO_DANO := 2.0
const SCHRO_ATORDOA := 0.6          # morto: a pata atordoa o gato atingido
const SCHRO_TROFEUS := 20           # troféus extras na primeira vitória
# ---- Chefes de gangue (3º ato, etapa 5; notas/ato3_proposta.md, seção 2)
# acerto por chefe de gangue (Dom Gatleone, Imortal Miau, Programa Mestre, Rei Miaunidas, Magnetomiau), sobre a vida e o dano do chefe
const CHEFE_GANGUE_VIDA: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.4]
const CHEFE_GANGUE_DANO: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.15]
const CHEFE_FASE2 := 0.5            # abaixo desta fração da vida o chefe entra na fase 2
const CHEFE_FASE3 := 0.25           # Magnetomiau: fase final
const GATLEONE_T := 18.0            # segundos entre as chamadas do Mensageiro
const GATLEONE_PRIMEIRO := 9.0
const GATLEONE_CAPANGAS := 2        # fase 2: a cada chamada, também chama Capangas
const IMORTAL_T := 11.0             # segundos entre varridas do comboio
const IMORTAL_PRIMEIRO := 7.0
const IMORTAL_FAIXA := 38.0         # meia-largura da faixa varrida (y)
const IMORTAL_DANO := 1.1           # x o dano do golpe, em cada gato da faixa
const IMORTAL_VEL2 := 1.35          # fase 2: +velocidade do chefe (guitarrista do comboio)
const MESTRE_T := 9.0
const MESTRE_PRIMEIRO := 6.0
const MESTRE_PIXEL_T := 3.0         # o gato atingido pelo disco vira pixel: não age nem sofre dano
const MESTRE_DISCO_DANO := 1.0
const MESTRE_RECOMPILA_DANO := 1.6  # recompilando fica frágil por um instante
const MESTRE_RECOMPILA_T := 1.5
const REI_FRENTE := 0.55            # redução do dano que vem de frente
const REI_FRENTE_FASE2 := 0.45
const REI_CHUTE_T := 13.0
const REI_CHUTE_PRIMEIRO := 8.0
const REI_CHUTE_RECUA := 240.0      # o gato da frente é jogado para o fundo
const REI_CHUTE_ATORDOA := 0.8
const REI_FLECHAS_T := 12.0         # fase 2: chuva de flechas
const REI_FLECHAS_N := 3
const REI_FLECHAS_RAIO := 90.0
const REI_FLECHAS_DANO := 0.9
const MAGNETO_T := 14.0
const MAGNETO_PRIMEIRO := 8.0
const MAGNETO_RAIO := 330.0
const MAGNETO_PUXA := 140.0
const MAGNETO_SEM_CONJUNTO_T := 6.0 # o bônus de conjunto fica suspenso neste tempo
const MAGNETO_CARRO_T := 12.0       # fase final: levanta um carro
const MAGNETO_CARRO_RAIO := 85.0
const MAGNETO_CARRO_DANO := 2.2
const ATO_FAMILIA_DA_CASA := 0.4    # fração dos bichos que ainda é da família do cômodo; o resto vem misturado
const XP_ONDA_NOCAUTE := 1          # por onda vencida tendo caído
const XP_RECUPERA_POR_NIVEL := 0.25  # XP de recuperação: +esta fração da XP da onda por nível que o gato está abaixo da média dos outros
const XP_RECUPERA_MAX := 3.0          # teto do multiplicador de recuperação
const NOCAUTE_SAUDE := 0.25         # quem caiu volta na onda seguinte com esta fração da vida
const ATR_NOMES: Array[String] = ["Vida", "Força", "Agilidade"]
const ATR_VIDA := 0.08              # +vida máxima por ponto
const ATR_FORCA := 0.06             # +dano por ponto
const ATR_AGIL := 0.05              # +velocidade de ataque por ponto
const ATR_AGIL_VEL := 0.03          # +velocidade de movimento por ponto
const NOMES_BONECOS: Array[String] = ["Fiapo", "Botão", "Retalho", "Feltro", "Novelo"]

# ---------- Poder especial da fantasia completa ----------
const PODER_INTERVALO := 9.0        # segundos entre usos
# Acerto da força do poder por fantasia (dano, duração e cura do poder da fantasia completa no gato; não vale para herança nem bicho).
const PODER_KIT_FORCA: Dictionary = {
	Pecas.Conjunto.JARDINEIRO: 1.5, Pecas.Conjunto.ESTELAR: 2.0, Pecas.Conjunto.MORCEGO: 2.2,
	Pecas.Conjunto.NINJA_FOLHA: 2.5, Pecas.Conjunto.CAVALEIRO: 1.3, Pecas.Conjunto.OURICO: 2.5,
	Pecas.Conjunto.VIKING: 1.7, Pecas.Conjunto.CIRCO: 3.0, Pecas.Conjunto.FENIX_MIAUSSIMO: 2.3,
	Pecas.Conjunto.ARANHA: 1.15, Pecas.Conjunto.ROCKET_MIAUGUE: 1.4, Pecas.Conjunto.SOMBRIO: 1.7, Pecas.Conjunto.TUBARAO: 1.2,
	Pecas.Conjunto.STARDEW_MIAULLEY: 2.2, Pecas.Conjunto.MEON: 1.7, Pecas.Conjunto.GELO: 1.3,
	Pecas.Conjunto.MAGO: 1.2, Pecas.Conjunto.MIAULAX: 0.7, Pecas.Conjunto.MIMIAU: 0.6,
	Pecas.Conjunto.SUPER_MIAUJIN: 0.7, Pecas.Conjunto.TREINADOR: 1.6,
	Pecas.Conjunto.MIAUZILLA: 2.8, Pecas.Conjunto.ARTHUR_MIAURGON: 2.6, Pecas.Conjunto.CATCHULLU: 0.5,
	Pecas.Conjunto.SUBMIAUTICA: 0.7,
}
# Acerto da recarga por fantasia (x PODER_INTERVALO), medido com o simulador (kits=todos): >1 recarrega mais devagar.
const PODER_KIT_INTERVALO: Dictionary = {
	Pecas.Conjunto.FERRO: 1.6, Pecas.Conjunto.CAUBOI: 1.55, Pecas.Conjunto.MIAULAX: 1.7,
	Pecas.Conjunto.JIMIAU: 1.55, Pecas.Conjunto.TROVAO: 1.6, Pecas.Conjunto.GUARDIAO: 1.55,
	Pecas.Conjunto.JARDINEIRO: 0.6, Pecas.Conjunto.ARANHA: 0.7, Pecas.Conjunto.ESTELAR: 0.6,
	Pecas.Conjunto.MORCEGO: 0.65, Pecas.Conjunto.NINJA_FOLHA: 0.7, Pecas.Conjunto.CAVALEIRO: 0.75,
	Pecas.Conjunto.OURICO: 0.75, Pecas.Conjunto.VIKING: 0.75, Pecas.Conjunto.CIRCO: 0.6,
	Pecas.Conjunto.ROCKET_MIAUGUE: 0.75, Pecas.Conjunto.STARDEW_MIAULLEY: 0.8, Pecas.Conjunto.SOMBRIO: 0.8,
	Pecas.Conjunto.GELO: 0.8, Pecas.Conjunto.FENIX_MIAUSSIMO: 0.8, Pecas.Conjunto.MEON: 0.85,
	Pecas.Conjunto.MAGO: 0.9, Pecas.Conjunto.PIRATA: 1.15,
	Pecas.Conjunto.SUPER_MIAUJIN: 1.5, Pecas.Conjunto.TREINADOR: 0.6, Pecas.Conjunto.MIAU_NOIR: 0.7,
	Pecas.Conjunto.ARTHUR_MIAURGON: 0.85, Pecas.Conjunto.MIAUZILLA: 0.6, Pecas.Conjunto.CATCHULLU: 1.45,
}
const PODER_PRIMEIRO := 3.5         # segundos até o primeiro uso
const PODER_DANO := 14.0            # dano de referência (x força média das peças)
const PODER_RAIO_DANO := 2.5        # multiplicadores do dano de referência
const PODER_EXPLOSAO_DANO := 1.2
const PODER_EXPLOSAO_RAIO := 100.0
const PODER_ATORDOA_T := 2.5
const PODER_ATORDOA_CHEFE := 0.4    # fração do tempo que vale para chefes
const PODER_ATORDOA_RAIO := 200.0
const PODER_ATORDOA_DANO := 0.3
const PODER_CURA := 0.25            # fração da vida máxima
const PODER_PROTEGE_T := 3.5
const PODER_PROTEGE_DANO := 0.3     # multiplicador do dano recebido enquanto protegido
const PODER_FRENESI_T := 4.0
const PODER_ATRAVESSA_DANO := 1.3
const PODER_ATRAVESSA_LARGURA := 45.0
const PODER_ATRAVESSA_ALCANCE := 520.0
const PODER_RAJADA_N := 4
const PODER_RAJADA_DANO := 1.0
const PODER_GELO_T := 4.5
const PODER_GELO_DANO := 0.3
const PODER_EMPURRA_RAIO := 200.0
const PODER_EMPURRA_DIST := 110.0
const PODER_EMPURRA_DANO := 0.8
const PODER_GIRO_RAIO := 95.0
const PODER_GIRO_DANO := 1.8
const PODER_DRENO_ALCANCE := 300.0
const PODER_DRENO_DANO := 1.6
# Clones (Ninja da Folha): N aliados temporários com fração da vida e do dano do dono. Dano total por uso ~ N x DANO x dano do golpe x T.
const PODER_INVOCA_N := 2
const PODER_INVOCA_T := 6.0         # segundos até sumirem
const PODER_INVOCA_VIDA := 0.35     # fração da vida máxima do dono
const PODER_INVOCA_DANO := 0.5      # fração do dano por golpe do dono
const PODER_INVOCA_DIST := 28.0     # distância do dono ao nascer
# Teletransporte (Robô Azul): vai até o inimigo mais ao fundo, golpe forte (perto do Raio, 2,5) e fica protegido um instante
const PODER_TELEPORTE_DANO := 2.2
const PODER_TELEPORTE_DIST := 34.0  # fica a esta distância do alvo, do lado do gato
const PODER_TELEPORTE_PROTEGE := 2.0
# Arrastão (Tubarão): puxa todos num raio grande; chefe e Grandalhão não se movem
const PODER_PUXA_RAIO := 320.0
const PODER_PUXA_DIST := 46.0       # fica a esta distância do gato (os puxados se espalham em leque)
const PODER_PUXA_DANO := 0.9
# Enxame (Abelha): nuvem sobre o grupo inimigo mais próximo; dano contínuo por inimigo = DPS x dano de referência x T
const PODER_ENXAME_T := 5.0
const PODER_ENXAME_RAIO := 90.0
const PODER_ENXAME_DPS := 0.45      # x PODER_DANO por segundo, em cada inimigo dentro da nuvem (31 em 5 s)
const PODER_ENXAME_SEGUE := 45.0    # a nuvem acompanha o grupo, nesta velocidade (px/s)
# ---- Poderes diversificados (rodada 2026-10-14). Na herança, nº de alvos e durações valem a fração de apoio (HERANCA_APOIO x grau); o dano já vem da força herdada.
# Teia (Garoto-Aranha): raiz nos que estão mais perto da torre; ainda atacam se alcançarem
const PODER_RAIZ_N := 4
const PODER_RAIZ_T := 4.0
const PODER_RAIZ_CHEFE := 0.4
const PODER_RAIZ_DANO := 0.3
# Saque rápido (Caubói): tiros no inimigo de menor vida atual (re-mira se morrer)
const PODER_SAQUE_N := 6
const PODER_SAQUE_DANO := 0.8
# Trovoada (Deus do Trovão): raios nos maiores aglomerados, atordoam
const PODER_TROVOADA_N := 3
const PODER_TROVOADA_RAIO := 70.0
const PODER_TROVOADA_DANO := 1.0
const PODER_TROVOADA_T := 1.2
const PODER_TROVOADA_CHEFE := 0.42
# Bala de canhão (Pirata): maior aglomerado, queima e devolve tijolos por bicho morto
const PODER_CANHAO_RAIO := 130.0
const PODER_CANHAO_DANO := 3.0
const PODER_CANHAO_QUEIMA_T := 3.0
const PODER_CANHAO_QUEIMA_DPS := 0.4   # x dano base por segundo
const PODER_CANHAO_SAQUE_MAX := 4
# Salva de mísseis (Armadura de Ferro): explosões na entrada da torre (distância à torre em x)
const PODER_MISSEIS_N := 3
const PODER_MISSEIS_ALCANCE := 800.0   # dispara com inimigo até esta distância da torre
const PODER_MISSEIS_RAIO := 100.0
const PODER_MISSEIS_DANO := 2.6
# Canção do tempo (Herói do Bosque): tira segundos da recarga do poder e das heranças dos outros gatos
const PODER_CANCAO_SEG := 3.5
# Carga de lança (Cavaleiro): investida em linha
const PODER_INVESTIDA_ALCANCE := 360.0
const PODER_INVESTIDA_DANO := 1.3
const PODER_INVESTIDA_DERRUBA := 1.0
const PODER_INVESTIDA_PROTEGE := 1.5
const PODER_INVESTIDA_HER_DANO := 1.0   # a herança não move o gato: dano menor, sem proteção
# Fumaça (Homem-Morcego): aliados em volta ficam ocultos
const PODER_FUMACA_RAIO := 130.0
const PODER_FUMACA_T := 3.0
const FUMACA_CHEFE_VISAO := 40.0    # chefe ainda enxerga a esta distância
# Fúria (Viking)
const PODER_FURIA_T := 4.0
const PODER_FURIA_CERCO := 1.0      # fração do golpe que vaza para os vizinhos do alvo
const PODER_FURIA_ROUBO := 0.3
# Pisão (Encanador): cadeia de pulos
const PODER_PISAO_N := 3
const PODER_PISAO_N_HER := 2        # pulos na herança
const PODER_PISAO_ALCANCE := 300.0
const PODER_PISAO_DANO := 0.7
const PODER_PISAO_CRESCE := 1.2     # cada pisão seguinte vale isto x o anterior
const PODER_PISAO_T := 0.6
const PODER_PISAO_PROTEGE := 1.0
# Canteiro (Jardineiro): zona parada que cura os aliados dentro e atrasa os inimigos
const PODER_CANTEIRO_T := 6.0
const PODER_CANTEIRO_RAIO := 110.0
const PODER_CANTEIRO_CURA := 0.05   # fração da vida máxima por segundo
const PODER_CANTEIRO_LENTO := 0.8   # multiplicador de velocidade dos inimigos dentro
# Triagem (Tartaruga): cura focada no mais ferido
const PODER_TRIAGEM_LIMIAR := 0.5
const PODER_TRIAGEM_CURA := 0.45
const PODER_TRIAGEM_OUTROS := 0.10
const PODER_TRIAGEM_PROTEGE := 2.0
# Alvo travado (Patrulheiro): laser que marca
const PODER_MARCA_DANO := 0.8
const PODER_MARCA_T := 5.0
const PODER_MARCA_BONUS := 0.25     # dano recebido a mais, de qualquer fonte
const PODER_MARCA_RECARGA := 2.0    # acertando 3 ou mais, a recarga do poder cai isto
const PODER_MARCA_RECARGA_MIN := 3
# Bola de espinhos (Ouriço)
const PODER_BOLA_T := 4.0
const PODER_BOLA_VEL := 1.8
const PODER_BOLA_ESPINHO := 0.7     # x dano base devolvido a cada golpe corpo a corpo recebido
# ---- Lote 1 da expansão de fantasias
# Salvamento (Super Miau): leva o aliado mais ferido ao posto, cura e soca o chão onde ele estava
const PODER_SALVAMENTO_LIMIAR := 0.7    # só dispara se alguém está abaixo desta fração de vida
const PODER_SALVAMENTO_CURA := 0.2
const PODER_SALVAMENTO_PROTEGE := 2.5
const PODER_SALVAMENTO_DANO := 1.4
const PODER_SALVAMENTO_RAIO := 90.0
const PODER_SALVAMENTO_ATORDOA := 0.8
const PODER_SALVAMENTO_HER_CURA := 0.10  # herança: só protege e cura o mais ferido, sem soco
# Flecha ricochete (Arqueiro Miau): salta de inimigo em inimigo, cada acerto mais forte
const PODER_RICOCHETE_ALCANCE := 520.0
const PODER_RICOCHETE_SALTO := 160.0
const PODER_RICOCHETE_ALVOS := 6        # acertos, contando o primeiro (a herança usa a fração de apoio: 3)
const PODER_RICOCHETE_DANO := 0.7
const PODER_RICOCHETE_CRESCE := 1.15
# Olhar da Penitência (Motoqueiro Miausma): dano em % da vida máxima dos de maior vida
const PODER_OLHAR_N := 3
const PODER_OLHAR_FRACAO := 0.25
const PODER_OLHAR_MIN := 1.0            # x dano base
const PODER_OLHAR_MAX := 7.0
const PODER_OLHAR_CHEFE_FRACAO := 0.05
const PODER_OLHAR_CHEFE_MAX := 4.0
const PODER_OLHAR_QUEIMA_T := 3.0
const PODER_OLHAR_QUEIMA_DPS := 0.3     # x dano base por segundo
const PODER_OLHAR_HER_FRACAO := 0.12    # herança: 1 alvo
const PODER_OLHAR_BICHO_FRACAO := 0.10  # bicho: 1 gato
# Objeção! (Fênix Miaussimo): corta o poder que um bicho carrega
const PODER_OBJECAO_ATORDOA := 2.0
const PODER_OBJECAO_ATORDOA_CHEFE := 0.8
const PODER_OBJECAO_DANO := 1.3
const PODER_OBJECAO_ATRASO := 6.0       # segundos a mais na recarga do poder do bicho
const PODER_OBJECAO_BONUS := 0.15       # dano do time
const PODER_OBJECAO_BONUS_T := 4.0
const PODER_PROTESTO_FATOR := 0.5      # sem aviso para cortar: atordoamento, dano e bônus do time nesta fração
# Imitar (Mimiau)
const PODER_IMITAR_JANELA := 12.0       # segundos em que o último poder ainda vale
const PODER_IMITAR_FORCA := 0.6    # o poder copiado sai mais fraco (em equipe o Imitar dominava: 82% no teste de equipe)
# Disfarce (Mimiau, Disguise do Mimikyu): a luta começa disfarçado; o 1º golpe é anulado e quem bateu fica atordoado
const DISFARCE_CHEFE_FATOR := 0.35      # chefe que rasga o Disfarce: atordoa nesta fração
const DISFARCE_BICHO_FATOR := 0.7       # bicho fantasiado de Mimiau: atordoa nesta fração
const DISFARCE_HER_ATORDOA := 0.7       # herança: segundos de atordoamento (uma vez por onda)
const DISFARCE_RASGA_CURA := 0.25       # Imitar sem o que copiar: refaz o Disfarce e cura esta fração da vida máxima
const DISFARCE_RASGA_CURA_HER := 0.12
const DISFARCE_SUSTO_RAIO := 90.0       # ao rasgar, quem está em volta também leva um susto
const DISFARCE_SUSTO_T := 0.8
const DISFARCE_REARMA_T := 7.0          # o pano rasgado se refaz sozinho depois disto (o Imitar refaz na hora)
const DISFARCE_REVIDE := 3.5            # quem rasga o Disfarce leva este tanto x dano de referência de volta
const DISFARCE_PROTEGE := 2.0           # segundos de proteção do Mimiau depois que o pano rasga
const PODER_IMITAR_RECARGA := 0.1       # o Imitar recarrega mais depressa (fração a menos)
const DISFARCE_KIT_DANO := 0.7        # kit completo do Mimiau: dano a mais
const DISFARCE_KIT_CRIT := 0.3        # kit completo do Mimiau: chance de crítico
const DISFARCE_GARRA := 0.8            # Garra Sombria: com o pano inteiro, os golpes causam este tanto a mais (kit completo)
const DISFARCE_FURIA_T := 6.0          # Furioso: segundos depois de rasgar o pano (kit completo)
const DISFARCE_FURIA_DANO := 1.0       # Furioso: dano a mais
const DISFARCE_FURIA_VEL := 0.5        # Furioso: golpes mais rápidos (fração)
const DISFARCE_REFAZ_PROTEGE := 3.0    # segundos de proteção ao refazer o Disfarce (só o poder do gato)
# Mão de pôquer (Jimiau): dano no maior bando, por categoria da mão (carta alta ... straight flush)
const PODER_POQUER_RAIO := 110.0
const PODER_POQUER_CARTAS := 7   # a spec fala em 8, mas o valor esperado dela (~1,35 x base) é o de 7 cartas: com 8 dava 1,68
const PODER_POQUER_CARTAS_HER := 5
# ---- Lote 2 da expansão
# Torre de ervilha (Disparamiau): estrutura parada que atira sozinha (a mesma Unidade-estrutura do Construir)
const PODER_TORRE_VIDA := 0.9          # fração da vida máxima do dono
const PODER_TORRE_T := 9.0
const PODER_TORRE_INTERVALO := 0.45
const PODER_TORRE_ALCANCE := 360.0
const PODER_TORRE_DANO := 0.25         # x dano base por ervilha
const PODER_TORRE_PERFURA := 90.0      # a ervilha também fere o vizinho do alvo neste raio
const PODER_TORRE_DX := 34.0           # a torre nasce um passo à frente do gato
const PODER_TORRE_HER_T := 5.0
const PODER_TORRE_HER_DANO := 0.7
# Manteiga escorregadia (Milhau): poça que desloca o bando para o fundo
const PODER_MANTEIGA_RAIO := 110.0
const PODER_MANTEIGA_T := 5.0
const PODER_MANTEIGA_VEL := 70.0       # px/s para o fundo
const PODER_MANTEIGA_LENTO := 0.6
const PODER_MANTEIGA_POS_T := 1.0      # segundos de lentidão depois de sair da poça
const PODER_MANTEIGA_DPS := 0.2        # x dano base por segundo
const PODER_MANTEIGA_HER_RAIO := 80.0
const PODER_MANTEIGA_HER_T := 3.0
# Reviver (Giramiau): levanta o aliado caído há pouco e apaga a marca de nocaute que ele levou
const PODER_REVIVER_JANELA := 12.0     # só quem caiu há menos que isto
const PODER_REVIVER_VIDA := 0.4
const PODER_REVIVER_PROTEGE := 2.0
const PODER_REVIVER_HER_VIDA := 0.2
# Colheita (Stardew Miaulley): mudas que amadurecem em pimenta, morango ou murcham
const PODER_COLHEITA_N := 3
const PODER_COLHEITA_LEQUE := 36.0
const PODER_COLHEITA_T := 5.0
const PODER_COLHEITA_VE_INIMIGO := 140.0   # inimigo perto: vira pimenta
const PODER_COLHEITA_VE_ALIADO := 200.0    # aliado ferido perto: vira morango
const PODER_COLHEITA_FERIDO := 0.8
const PODER_COLHEITA_DANO := 1.0
const PODER_COLHEITA_RAIO := 70.0
const PODER_COLHEITA_QUEIMA_T := 3.0
const PODER_COLHEITA_QUEIMA_DPS := 0.3
const PODER_COLHEITA_CURA := 0.14
const PODER_COLHEITA_HER_N := 2
const PODER_COLHEITA_HER_T := 6.0
# Construir (Miaucraft): blocos de pedra que provocam e explodem ao cair
const PODER_CONSTRUIR_N := 3
const PODER_CONSTRUIR_DIST := 36.0
const PODER_CONSTRUIR_VIDA := 0.6      # fração da vida máxima do dono, em cada bloco
const PODER_CONSTRUIR_T := 7.0
const PODER_CONSTRUIR_DANO := 0.8
const PODER_CONSTRUIR_RAIO := 70.0
const PODER_CONSTRUIR_HER_N := 2
const PODER_CONSTRUIR_HER_T := 5.0
# Cochilo (Miaulax): o gato dorme e se cura; o ronco adormece os inimigos em volta
const PODER_COCHILO_T := 2.5
const PODER_COCHILO_DANO := 0.5        # dano recebido durante o sono
const PODER_COCHILO_CURA := 0.35 
const PODER_SONO_RAIO := 120.0
const PODER_SONO_T := 3.0              # acorda antes se levar qualquer dano
const PODER_SONO_CHEFE := 1.2
const PODER_COCHILO_HER_CURA := 0.25
const PODER_COCHILO_HER_RAIO := 90.0
const PODER_COCHILO_HER_T := 2.0
# ---- Lote 3 da expansão
const ATORDOA_KIT_T := 0.8             # golpe que atordoa pelo kit do Donatemiau
# Plano de ataque (Leonarmiau): o time foca o inimigo de maior vida; o líder dá dois cortes
const PODER_PLANO_T := 5.0
const PODER_PLANO_BONUS := 0.45        # dano a mais no alvo focado
const PODER_PLANO_CORTE := 1.3         # x dano base, cada um dos dois cortes
const PODER_PLANO_RECARGA := 3.0       # segundos a menos na recarga se o alvo cair
const PODER_PLANO_HER_T := 3.0
const PODER_PLANO_HER_BONUS := 0.15
# Domo refletor (Donatemiau): destrói os tiros inimigos que entram e devolve ao atirador
const PODER_DOMO_RAIO := 130.0
const PODER_DOMO_T := 5.0
const PODER_DOMO_ARMADURA := 4.0       # aliados dentro
const PODER_DOMO_DANO := 1.0           # x o dano do tiro devolvido
const PODER_DOMO_HER_RAIO := 90.0
const PODER_DOMO_HER_T := 3.0
# Lobo solitário (Rafamiau): os bichos em volta só atacam ele
const PODER_LOBO_T := 5.0
const PODER_LOBO_CHEFE_T := 3.0        # o chefe só é provocado neste tempo
const PODER_LOBO_RAIO := 150.0
const PODER_LOBO_REDUCAO := 0.45       # dano recebido a menos
const PODER_LOBO_DANO := 0.5           # dano a mais
const PODER_LOBO_DANO_INIMIGO := 0.1   # mais por inimigo no raio ...
const PODER_LOBO_DANO_INIMIGO_MAX := 0.6
const PODER_LOBO_SOZINHO := 0.2        # ... e se não houver aliado perto
const PODER_LOBO_SOZINHO_RAIO := 120.0
const PODER_LOBO_HER_T := 3.0
const PODER_LOBO_HER_DANO := 0.3
# Turbo (Rocket Miaugue): corrida em linha com atropelo e rastro de chamas azuis
const PODER_TURBO_ALCANCE := 420.0
const PODER_TURBO_DANO := 1.3
const PODER_TURBO_DERRUBA := 0.4
const PODER_TURBO_PROTEGE := 2.0
const PODER_TURBO_RASTRO_N := 9
const PODER_TURBO_RASTRO_RAIO := 28.0
const PODER_TURBO_RASTRO_T := 4.0
const PODER_TURBO_RASTRO_DPS := 0.8
const PODER_TURBO_RASTRO_LENTO := 0.8
const PODER_TURBO_HER_N := 5
const PODER_TURBO_HER_T := 2.0
# Esforço máximo (Deadmiau): regenera, bate mais forte e levanta uma vez se cair
const PODER_ESFORCO_T := 8.0
const PODER_ESFORCO_REGEN := 0.05      # fração da vida máxima por segundo
const PODER_ESFORCO_DANO := 0.2
const PODER_ESFORCO_VIDA := 0.35       # vida com que levanta
const PODER_ESFORCO_EXPLODE := 0.8     # x dano base
const PODER_ESFORCO_RAIO := 100.0
const PODER_ESFORCO_HER_T := 4.0
const PODER_ESFORCO_HER_REGEN := 0.03
# Chute giratório (Meon): chute curto em volta, empurra e atordoa; quem já estava atordoado apanha muito mais
const PODER_CHUTE_RAIO := 170.0
const PODER_CHUTE_DANO := 3.0          # x dano base
const PODER_CHUTE_DANO_ATORDOADO := 6.5   # x dano base em quem já estava atordoado
const PODER_CHUTE_ATORDOA := 1.2
const PODER_CHUTE_CHEFE := 0.4         # fração do atordoamento que vale para chefe
const PODER_CHUTE_EMPURRA := 70.0
const PODER_CHUTE_HER_RAIO := 90.0
const PODER_CHUTE_HER_DANO := 1.2      # x dano base (já menor na herança)
const PODER_CHUTE_HER_ATORDOADO := 2.4
const PODER_CHUTE_HER_ATORDOA := 0.6
const PODER_CHUTE_HER_EMPURRA := 40.0
# Aparar com a faca (kit do Meon): o golpe corpo a corpo some (dano 0) e volta como facada
const MEON_TIRO_ATORDOA: Array[float] = [0.15, 0.4]   # kit do Meon: chance de o tiro (na perna) atordoar o alvo
const TIRO_ATORDOA_T := 1.0            # segundos de atordoamento do tiro na perna
const MEON_VIDA: Array[float] = [0.3, 0.8]        # kit do Meon: vida a mais
const MEON_RECARGA: Array[float] = [0.0, 0.35]    # kit do Meon: poder recarrega mais rápido
const APARA_DANO := 2.5                # x dano de ataque de quem aparou
const PODER_POQUER_DANO: Array[float] = [0.55, 0.75, 1.15, 1.7, 2.2, 2.35, 2.8, 4.2, 6.1]
# ---- Lote 4 da expansão
# Modo Noir (Miau-Noir, enum APAGAO): o gato fica em preto e branco; os bichos erram os golpes nele e os tiros dele ferem mais
const PODER_NOIR_T := 6.0
const PODER_NOIR_ERRA := 0.55
const PODER_NOIR_ERRA_CHEFE := 0.3
const PODER_NOIR_DANO := 2.2         # x no dano dos tiros enquanto em preto e branco
const PODER_NOIR_HER_T := 2.5
const PODER_NOIR_HER_ERRA := 0.3
const PODER_NOIR_HER_DANO := 1.2
# Alma Sombria (Hollowmiau): Alma que cresce com golpes e abates
const ALMA_GOLPE := 6.0
const ALMA_ABATE := 20.0
const ALMA_MAX := 100.0
const PODER_ESPIRITO_ALCANCE := 520.0
const PODER_ESPIRITO_LARGURA := 45.0
const PODER_ESPIRITO_ALMA := 2.2       # dano = base x (1 + isto x Alma/100)
const PODER_ESPIRITO_CURA := 0.25      # fração da vida x Alma/100
const PODER_ESPIRITO_HER_GASTO := 0.5  # a herança gasta metade da Alma
const PODER_ESPIRITO_HER_LARGURA := 32.0   # a Sombra menor é mais fina
const PODER_ESPIRITO_HER_PERFURA := 2       # e perfura só os 2 primeiros
const PODER_ESPIRITO_ASSOMBRA_T := 2.0    # quem a Sombra atravessa fica assombrado (lento)
const PODER_ESPIRITO_ASSOMBRA_LENTO := 0.6
# Laço de seda (Silkmiau): os mais fortes dividem o dano
const PODER_LACO_N := 4
const PODER_LACO_T := 6.0
const PODER_LACO_INICIAL := 0.4        # x dano base em cada ligado
const PODER_LACO_COMPART := 0.5        # fração do dano que os outros ligados também levam
const PODER_LACO_CHEFE := 0.25         # o chefe ligado só leva este tanto do compartilhado
const PODER_LACO_HER_N := 3
const PODER_LACO_HER_COMPART := 0.35
const PODER_LACO_HER_T := 4.0
# Camehamiau! (Super Miaujin): carrega parado, depois um feixe que cruza o campo
const PODER_KAMEHA_CARGA := 2.0
const PODER_KAMEHA_LARGURA := 55.0
const PODER_KAMEHA_DANO := 2.6
const PODER_KAMEHA_VIDA := 0.3         # abaixo disto no disparo, o dano dobra
const PODER_KAMEHA_VIDA_MULT := 2.0
const PODER_KAMEHA_HER_DANO := 1.5
const PODER_KAMEHA_FEIXE_T := 1.2      # só o desenho do feixe
# Pedra rolante (O Arqueólogo): onda viajante que atordoa o que cruza
const PODER_PEDRA_LARGURA := 70.0
const PODER_PEDRA_T := 2.2
const PODER_PEDRA_DANO := 1.1
const PODER_PEDRA_ATORDOA := 0.8
const PODER_PEDRA_CHEFE := 0.4
const PODER_PEDRA_GIGANTE := 0.4       # segundos de atordoamento do Gigante
const PODER_PEDRA_HER_DANO := 0.7
# Eu escolho você! (Treinador de Miaumons): captura o bicho de menor vida percentual
const PODER_CAPTURA_LIMIAR := 0.6
const PODER_CAPTURA_T := 8.0
const PODER_CAPTURA_VIDA := 0.3        # vida do aliado = vida atual + isto x vida máxima
const PODER_CAPTURA_LENTO := 0.6
const PODER_CAPTURA_LENTO_T := 2.0
const PODER_CAPTURA_BOLA := 0.5        # x dano base quando a bola balança
const PODER_CAPTURA_CHEFE := 1.0       # chefe e Gigante: "não é muito eficaz"
const PODER_CAPTURA_HER_T := 5.0
# ---- Lote 5 da expansão
# Megazord (Ranger Miau), versão enxuta: os aliados perto ficam "ligados" (escudo) e só o Ranger cresce
const PODER_MEGAZORD_RAIO := 240.0
const PODER_MEGAZORD_N := 2
const PODER_MEGAZORD_T := 7.0
const PODER_MEGAZORD_ESC := 1.7          # escala visual do Ranger gigante
const PODER_MEGAZORD_ALCANCE := 30.0
const PODER_MEGAZORD_DANO := 1.5         # dano x (isto + POR_LIGADO por aliado ligado)
const PODER_MEGAZORD_POR_LIGADO := 0.4
const PODER_MEGAZORD_ESCUDO_LIGADO := 0.25   # fração da vida máxima de cada aliado ligado
const PODER_MEGAZORD_ESCUDO_RANGER := 0.5    # fração da vida máxima do próprio Ranger
const PODER_MEGAZORD_SOLO_DANO := 1.4
const PODER_MEGAZORD_HER_T := 4.0
const PODER_MEGAZORD_HER_ESCUDO := 0.3
# Sopro radioativo (Miauzilla): cone que contamina; o contaminado explode ao cair
const PODER_SOPRO_ALCANCE := 260.0
const PODER_SOPRO_ANGULO := 60.0         # graus, abertura total
const PODER_SOPRO_DANO := 1.0
const PODER_SOPRO_T := 6.0
const PODER_SOPRO_HER_T := 4.0
const PODER_SOPRO_EXPL_RAIO := 75.0
const PODER_SOPRO_EXPL_DANO := 0.9
const PODER_SOPRO_GER_FATOR := 0.85      # a cada geração a explosão fere isto do anterior
const PODER_SOPRO_GER_MAX := 3
# Bater no peito (King-Miau): medo em volta; o King-Miau fica mais forte e mais duro
const PODER_BRADO_RAIO := 230.0
const PODER_BRADO_MEDO := 2.5
const PODER_BRADO_MEDO_ELITE := 1.5
const PODER_BRADO_DANO := 0.5
const PODER_BRADO_REDUZ := 0.2
const PODER_BRADO_T := 4.0
const PODER_BRADO_HER_MEDO := 1.5
const MEDO_VEL := 1.2                    # velocidade de fuga x velocidade normal
# Recompensa (Arthur Miaurgon): marca o bicho mais forte; se cair no prazo, o time é pago
const PODER_RECOMPENSA_T := 8.0
const PODER_RECOMPENSA_BONUS := 0.15     # dano a mais no marcado
const PODER_RECOMPENSA_CURA := 0.15
const PODER_RECOMPENSA_DANO := 0.2
const PODER_RECOMPENSA_DANO_T := 4.0
const PODER_RECOMPENSA_RECARGA := 3.0
const PODER_RECOMPENSA_HER_T := 6.0
const PODER_RECOMPENSA_HER_CURA := 0.08
# Rifle de estase (Submiautica): bolha que congela o tempo do bando e guarda o dano
const PODER_ESTASE_RAIO := 110.0
const PODER_ESTASE_T := 4.0
const PODER_ESTASE_LIBERA := 0.7         # fração do dano retido solta no fim
const PODER_ESTASE_EXTRA := 0.5          # x dano base a mais, em cada congelado
const PODER_ESTASE_CHEFE_T := 1.5
const PODER_ESTASE_HER_T := 2.0
const PODER_ESTASE_HER_LIBERA := 0.5
# Loucura (Catchullu): os mais fortes atacam o inimigo mais perto deles
const PODER_LOUCURA_N := 3
const PODER_LOUCURA_T := 4.0
const PODER_LOUCURA_DANO := 0.5          # dano a mais dos enlouquecidos
const PODER_LOUCURA_CHEFE := 1.0         # x dano base do tentáculo no chefe
const PODER_LOUCURA_HER_N := 2
const PODER_LOUCURA_HER_T := 3.0
# Poderes dos bichos (fantasiado com fantasia completa e chefe): avisam antes, recarga longa, intensidade menor
const PODER_INIMIGO_FATOR := 0.9       # dano, duração e quantidade, sobre o poder do gato
const PODER_INIMIGO_FATOR_ATO := 0.08   # soma por ato depois do primeiro
const PODER_INIMIGO_FATOR_CHEFE := 0.1  # o chefe usa o poder um pouco mais forte
const PODER_INIMIGO_PISAO := 0.7        # o Pisão do bicho fere menos (era o que mais derrubava gatos)
const PODER_AVISO_T := 1.0              # segundos de aviso (o bicho para e carrega)
const PODER_INIMIGO_INTERVALO := 10.0   # fantasiado
const PODER_INIMIGO_PRIMEIRO := 5.0     # primeiro uso do fantasiado (mais um sorteio de 0 a 4 s)
const PODER_CHEFE_INTERVALO := 8.0
const PODER_CHEFE_PRIMEIRO := 5.0
const PODER_INIMIGO_SEM_ALVO := 1.5     # sem ninguém para atingir: tenta de novo daqui a pouco
const PODER_INIMIGO_INTERROMPIDO := 4.0 # atordoado durante o aviso: perde a carga e espera isto
const PODER_CANCAO_INIMIGO := 3.5       # Canção do tempo do bicho: atrasa os poderes dos gatos (x fator)
## Poder fixo de cada chefe (Fases.Chefe); o valor é a fantasia que dá o poder (cor e nome do aviso)
const CHEFE_PODER_CONJ: Array[int] = [
	Pecas.Conjunto.REI,          # Rei dos Ratos: Ordem real (os ratos atacam em dobro)
	Pecas.Conjunto.ENCANADOR,    # Guaxinim Glutão: Pisão (barrigada no gato mais forte)
	Pecas.Conjunto.CAVALEIRO,    # Raposa Ligeira: Carga de lança
	Pecas.Conjunto.TROVAO,       # Corvo Velho: Trovoada
	Pecas.Conjunto.ARANHA,       # Sapo-Rei: Teia (prende os gatos mais perto)
	Pecas.Conjunto.TUBARAO,      # Toupeira: Arrastão (puxa os gatos para o buraco)
	Pecas.Conjunto.ABELHA,       # Gambá: Enxame (nuvem fedida)
	Pecas.Conjunto.MAGO,         # Esquilo Acrobata: Relâmpago
	Pecas.Conjunto.VIKING,       # Vira-Lata: Fúria
	Pecas.Conjunto.OURICO,       # Texugo-Rei: Bola de espinhos
	Pecas.Conjunto.TUBARAO,      # Dom Gatleone: Arrastão
	Pecas.Conjunto.CAVALEIRO,    # Imortal Miau: Carga de lança
	Pecas.Conjunto.TROVAO,       # Programa Mestre: Trovoada
	Pecas.Conjunto.VIKING,       # Rei Miaunidas: Fúria
	Pecas.Conjunto.MAGO,         # Magnetomiau: Relâmpago
	Pecas.Conjunto.MAGO,         # Gato de Schrödinger: Relâmpago
]

# ---------- Geometria do campo ----------
const TORRE_X := 175.0
const ALIADO_X0 := 215.0
const INIMIGO_X0 := 1340.0
const VISIVEL_X := 1250.0
const CHAO_Y0 := 475.0
const CHAO_Y1 := 640.0
const RETARGET := 0.3
const AGGRO := 170.0
const PROVOCA_BONUS := 140.0
const TEMPO_MAX := 400.0
const PROJETIL_VEL := 420.0

## Força acumulada na campanha: a onda 1 da fase 2 vale como a onda 4 da fase 1.
static func progresso(fase: int, onda: int) -> int:
	return (fase - 1) * PROG_POR_FASE + onda

static func tem_chefe(onda: int) -> bool:
	return onda == ONDAS_TOTAIS

## Progresso nos atos seguintes: continua de onde o Porão parou e sobe a cada cômodo já vencido no ato.
static func progresso_ato(ato: int, vencidos: int, onda: int) -> int:
	return Fases.TOTAL * PROG_POR_FASE * (ato - 1) + vencidos * PROG_POR_FASE + onda + (PROG_POR_FASE - 1) * (ato - 1)

## `ato` > 1: famílias misturadas e peças de qualquer cômodo; `vencidos` = cômodos já vencidos nesse ato.
## `pesos_fantasia` (fantasia -> peso) deixa a que falta cair mais; vazio = sorteio uniforme.
## `mistura` (só no 3º ato, invasão das ruas): cada rival é de uma gangue sorteada, com as peças e os tipos dela.
static func gerar_plano(fase: int, onda: int, rng: RandomNumberGenerator, ato: int = 1, vencidos: int = 0, pesos_fantasia: Dictionary = {}, mistura: bool = false) -> Array:
	var p: int = progresso(fase, onda) if ato <= 1 else progresso_ato(ato, vencidos, onda)
	var degrau: float = (fase - 1) if ato <= 1 else (Fases.TOTAL - 1) + vencidos * 0.5
	var lugar: int = Fases.TOTAL * (ato - 1) + fase   # lugar global, 1 a 15
	var n: int = int(round(INIMIGOS_BASE + onda * INIMIGOS_POR_ONDA + degrau * INIMIGOS_POR_FASE))
	if tem_chefe(onda):
		n = int(round(n * CHEFE_LACAIOS))
	var plano: Array = []
	var nivel: int = mini(INIMIGO_NIVEL_MAX_ATO[clampi(ato - 1, 0, 2)], int(floor((p - 1) * NIVEL_INIMIGO_POR_ONDA)))
	for i in n:
		var gi: int = rng.randi_range(0, Fases.TOTAL - 1) if mistura else fase - 1
		var q: float = PECAS_BASE + p * PECAS_POR_ONDA
		var qtd: int = int(floor(q))
		if rng.randf() < q - floor(q):
			qtd += 1
		qtd = clampi(qtd, 0, Pecas.SLOTS)
		var slots: Array = [0, 1, 2, 3]
		_embaralhar(slots, rng)
		if p == 1:
			slots = [0, 1, 3]  # onda de aquecimento: ninguém vem armado
			qtd = mini(qtd, 2)
		var pecas: Array = [null, null, null, null]
		for k in qtd:
			var s: int = slots[k]
			pecas[s] = Peca.new(Fases.pecas_do_slot(lugar - 1 + (gi - (fase - 1) if mistura else 0), s, ato, rng, RIVAL_FRACAO_DO_LUGAR if ato >= 3 else -1.0), nivel)
		var item: Dictionary = {"pecas": pecas, "tipo": Unidade.Tipo.COMUM, "elite": false}
		if ato >= 3:
			item["rival"] = true         # 3º ato: 100% gato da gangue do lugar (sem mistura)
			item["gangue"] = gi
		elif ato > 1 and rng.randf() >= ATO_FAMILIA_DA_CASA:
			item["fam"] = rng.randi_range(0, Fases.TOTAL - 1)
		plano.append(item)
	if mistura:
		for g in Fases.TOTAL:
			var grupo: Array = []
			for it in plano:
				if int(it["gangue"]) == g:
					grupo.append(it)
			_sortear_tipos_gangue(grupo, g, rng)
		_elites_mistos(plano, onda, nivel, rng, pesos_fantasia)
	else:
		if ato >= 3:
			_sortear_tipos_gangue(plano, fase - 1, rng)
		else:
			_sortear_tipos(plano, p, rng)
		_sortear_elites(plano, lugar, onda, nivel, rng, pesos_fantasia)
	if ato >= 3:
		_marcar_lider(plano)
	return plano

## Invasão das ruas: fantasiados da gangue de cada rival escolhido (os últimos comuns a entrar).
static func _elites_mistos(plano: Array, onda: int, nivel: int, rng: RandomNumberGenerator, pesos: Dictionary) -> void:
	if onda < ELITE_ONDA_MIN:
		return
	var quantos: int = 2 if onda >= ELITE_ONDA_DOIS and not tem_chefe(onda) else 1
	var comuns: Array = []
	for i in plano.size():
		if plano[i]["tipo"] == Unidade.Tipo.COMUM:
			comuns.append(i)
	for k in mini(quantos, comuns.size()):
		var i: int = comuns[comuns.size() - 1 - k]
		var g: int = int(plano[i]["gangue"])
		plano[i]["pecas"] = fantasia(Fases.TOTAL * 2 + g + 1, nivel, ELITE_PECAS[g], rng, pesos)
		plano[i]["elite"] = true

## 3º ato: o rival mais forte da onda é o líder (fantasiado, depois grandalhão, depois quem veste mais peças).
## Sem sorteio, para não mexer no rng da luta; em empate fica o primeiro.
static func _marcar_lider(plano: Array) -> void:
	var melhor: int = -1
	var nota_melhor: int = -1
	for i in plano.size():
		var it: Dictionary = plano[i]
		var n: int = 0
		for p in it["pecas"]:
			if p != null:
				n += 1
		var nota: int = n + (100 if it.get("elite", false) else 0) + (50 if int(it["tipo"]) == Unidade.Tipo.GIGANTE else 0)
		if nota > nota_melhor:
			nota_melhor = nota
			melhor = i
	if melhor >= 0:
		plano[melhor]["lider"] = true

## Embaralha com o rng da luta (o shuffle() do Godot usa o rng global e tira a repetibilidade das ondas).
static func _embaralhar(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t

## Distribui tipos especiais no plano: tipo novo entra garantido; teto de ESPECIAL_FRACAO.
static func _sortear_tipos(plano: Array, prog: int, rng: RandomNumberGenerator) -> void:
	var teto: int = int(floor(plano.size() * ESPECIAL_FRACAO))
	var disponiveis: Array[int] = []
	var novos: Array[int] = []
	for t in range(1, TIPO_NOMES.size()):
		if prog >= TIPO_PROG_MIN[t]:
			disponiveis.append(t)
			if prog == TIPO_PROG_MIN[t]:
				novos.append(t)
	if disponiveis.is_empty() or teto <= 0:
		return
	var vagas: Array = range(plano.size())
	_embaralhar(vagas, rng)
	var usados: int = 0
	for t in novos:
		if usados < teto:
			plano[vagas[usados]]["tipo"] = t
			usados += 1
	while usados < teto and usados < vagas.size():
		if rng.randf() < ESPECIAL_CHANCE:
			plano[vagas[usados]]["tipo"] = disponiveis[rng.randi_range(0, disponiveis.size() - 1)]
		usados += 1

## 3º ato: tipos especiais da onda sorteados só entre os da gangue (GANGUE_TIPOS), com peso; teto GANGUE_ESPECIAL_FRACAO.
static func _sortear_tipos_gangue(plano: Array, gangue: int, rng: RandomNumberGenerator) -> void:
	var g: int = clampi(gangue, 0, GANGUE_TIPOS.size() - 1)
	var lista: Array = GANGUE_TIPOS[g]
	var teto: int = int(floor(plano.size() * GANGUE_ESPECIAL_FRACAO[g]))
	var total: float = 0.0
	for par in lista:
		total += float(par[1])
	if teto <= 0 or total <= 0.0:
		return
	var vagas: Array = range(plano.size())
	_embaralhar(vagas, rng)
	for k in mini(teto, vagas.size()):
		if rng.randf() >= ESPECIAL_CHANCE:
			continue
		var r: float = rng.randf() * total
		var tipo: int = int(lista[lista.size() - 1][0])
		for par in lista:
			r -= float(par[1])
			if r < 0.0:
				tipo = int(par[0])
				break
		plano[vagas[k]]["tipo"] = tipo

## Nome do tipo `tipo` de rival da gangue `gangue` (ou o nome de sempre do tipo).
static func nome_rival(gangue: int, tipo: int) -> String:
	var t: int = clampi(tipo, 0, TIPO_NOMES.size() - 1)
	if gangue >= 0 and gangue < GANGUE_TIPO_NOME.size():
		var n: String = GANGUE_TIPO_NOME[gangue][t]
		if n != "":
			return n
	return TIPO_NOMES[t]

## Dica do tipo de rival (texto da prévia): a da gangue, ou "" para usar a dica de sempre do tipo.
static func dica_rival(gangue: int, tipo: int) -> String:
	var t: int = clampi(tipo, 0, TIPO_NOMES.size() - 1)
	if gangue >= 0 and gangue < GANGUE_TIPO_DICA.size():
		return GANGUE_TIPO_DICA[gangue][t]
	return ""

## Inimigos fantasiados: comuns que vestem uma fantasia da fase (e largam uma peça dela).
static func _sortear_elites(plano: Array, fase: int, onda: int, nivel: int, rng: RandomNumberGenerator, pesos_fantasia: Dictionary = {}) -> void:
	if onda < ELITE_ONDA_MIN:
		return
	var quantos: int = 2 if onda >= ELITE_ONDA_DOIS and not tem_chefe(onda) else 1
	var comuns: Array = []
	for i in plano.size():
		if plano[i]["tipo"] == Unidade.Tipo.COMUM:
			comuns.append(i)
	for k in mini(quantos, comuns.size()):
		var i: int = comuns[comuns.size() - 1 - k]  # os últimos a entrar
		plano[i]["pecas"] = fantasia(fase, nivel, ELITE_PECAS[(fase - 1) % Fases.TOTAL], rng, pesos_fantasia)
		plano[i]["elite"] = true

## Peças de uma fantasia sorteada entre as do lugar global `fase` (1 a 15); `quantas` < 4 deixa um espaço vazio.
## `pesos` (fantasia -> peso, 1,0 se faltar) pondera o sorteio; `excluir` tira uma fantasia da roleta.
static func fantasia(fase: int, nivel: int, quantas: int, rng: RandomNumberGenerator, pesos: Dictionary = {}, excluir: int = -1) -> Array:
	var conjs: Array = Fases.lista_do_lugar(fase - 1)
	var c: int = _sortear_conjunto(conjs, rng, pesos, excluir)
	var pecas: Array = [null, null, null, null]
	var fora: int = rng.randi_range(0, Pecas.SLOTS - 1) if quantas < Pecas.SLOTS else -1
	for s in Pecas.SLOTS:
		if s != fora:
			pecas[s] = Peca.new(Pecas.CONJUNTO_PECAS[c][s], nivel)
	return pecas

static func _sortear_conjunto(conjs: Array, rng: RandomNumberGenerator, pesos: Dictionary, excluir: int) -> int:
	if pesos.is_empty() and excluir < 0:
		return conjs[rng.randi_range(0, conjs.size() - 1)]
	var total: float = 0.0
	for c in conjs:
		if c != excluir:
			total += float(pesos.get(c, 1.0))
	var r: float = rng.randf() * total
	var ultimo: int = conjs[0]
	for c in conjs:
		if c == excluir:
			continue
		ultimo = c
		r -= float(pesos.get(c, 1.0))
		if r < 0.0:
			return c
	return ultimo

## Fantasia completa do conjunto-assinatura do chefe do lugar global `lugar` (1 a 15).
static func assinatura(lugar: int, nivel: int) -> Array:
	var sig: int = Fases.CHEFE_ASSINATURA[lugar - 1]
	var pecas: Array = [null, null, null, null]
	for s in Pecas.SLOTS:
		pecas[s] = Peca.new(Pecas.CONJUNTO_PECAS[sig][s], nivel)
	return pecas

## Peças do chefe da fase (fantasia completa, nível alto, uma marca cada). Vazio se a onda não tem chefe.
## Com CHEFE_ASSINATURA_CHANCE veste a fantasia-assinatura do lugar; senão, outra do lugar (sorteio ponderado por `pesos`).
static func gerar_chefe(fase: int, onda: int, rng: RandomNumberGenerator, ato: int = 1, vencidos: int = 0, pesos: Dictionary = {}) -> Array:
	if not tem_chefe(onda):
		return []
	var p: int = progresso(fase, onda) if ato <= 1 else progresso_ato(ato, vencidos, onda)
	var nivel: int = mini(INIMIGO_NIVEL_MAX_ATO[clampi(ato - 1, 0, 2)], int(floor((p - 1) * NIVEL_INIMIGO_POR_ONDA)) + CHEFE_NIVEL_BONUS)
	var lugar: int = Fases.TOTAL * (ato - 1) + fase
	var pecas: Array
	if rng.randf() < CHEFE_ASSINATURA_CHANCE:
		pecas = assinatura(lugar, nivel)
	else:
		pecas = fantasia(lugar, nivel, Pecas.SLOTS, rng, pesos, Fases.CHEFE_ASSINATURA[lugar - 1])
	for pc in pecas:
		pc.marcar(rng.randi_range(0, Pecas.Marca.size() - 1))
	return pecas
