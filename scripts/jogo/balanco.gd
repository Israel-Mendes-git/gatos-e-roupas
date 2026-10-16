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
const INIMIGO_NIVEL_MAX := 5    # ...e o das peças que os bichos vestem (a curva deles não acompanha a das peças do jogador)
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
	Pecas.Conjunto.STARDEW_MIAULLEY: [0.15, 0.35],    # sementes: fração da vida curada nos aliados ao cair
	Pecas.Conjunto.MIAUCRAFT: [12.0, 30.0],           # explode ao morrer (Circo)
	Pecas.Conjunto.MIAULAX: [0.2, 0.5],               # vida a mais (Guardião)
	# lote 3
	Pecas.Conjunto.LEONARMIAU: [0.1, 0.25],           # aliados por perto: dano a mais (aura do Rei)
	Pecas.Conjunto.DONATEMIAU: [0.08, 0.18],          # chance de o golpe atordoar
	Pecas.Conjunto.RAFAMIAU: [0.5, 1.4],              # chifres: dano a mais com a vida perto de zero
	Pecas.Conjunto.ROCKET_MIAUGUE: [0.2, 0.45],       # velocidade de movimento
	Pecas.Conjunto.DEADMIAU: [3.0, 6.0],              # regeneração por segundo
	Pecas.Conjunto.MEON: [0.2, 0.4],                  # chance de aparar um golpe corpo a corpo com a faca
}
const CRITICO_MAX := 0.8   # teto do crítico somado (Cartola + kit do Arqueiro)

## Valor do bônus de kit da fantasia `c` no grau `g` (0 = 2 ou 3 peças, 1 = as 4).
static func conj_valor(c: int, g: int) -> float:
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

## Blocos para subir a peça do nível `nivel` para o seguinte.
static func custo_promocao(nivel: int) -> int:
	return PROMOCAO_CUSTO[clampi(nivel, 0, PROMOCAO_CUSTO.size() - 1)]

## Troféus para subir uma peça da raridade `rar` para a seguinte.
static func custo_reforco(rar: int) -> int:
	return REFORCO_CUSTO[clampi(rar, 0, REFORCO_CUSTO.size() - 1)]

## Degrau do lugar para os drops: 0..4 nos cômodos, 5..9 fora da casa, mais o avanço da invasão.
static func degrau_drop(fase: int, ato: int, invasao: bool, onda_invasao: int) -> float:
	var g: float = float(fase - 1) + (float(Fases.TOTAL) if ato > 1 else 0.0)
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
const CHEFE_ESCALA_TIPO: Array[float] = [1.0, 1.0, 1.0, 0.88, 1.0, 1.0, 0.8, 0.64, 0.8, 0.9]   # acerto por chefe: nenhum passa de ~2,1x a altura de um gato (a coruja é alta: em pé ocupa muito)
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
const ATOS := 2
const ATO_NOME: Array[String] = ["Primeiro ato", "Segundo ato", "Terceiro ato"]
const ATO_VIDA: Array[float] = [1.0, 2.0, 2.6] # força dos bichos no primeiro cômodo vencido do ato
const ATO_DANO: Array[float] = [1.0, 1.3, 1.3]
const ATO_VIDA_DEGRAU := 0.10       # cada cômodo já vencido no ato deixa os que faltam mais fortes
const ATO_DANO_DEGRAU := 0.05
const ATO_COMODO_VIDA: Array[float] = [1.06, 0.78, 0.97, 1.1, 1.0] # acerto por cômodo (chefe e família da casa pesam diferente)
const ATO_COMODO_DANO: Array[float] = [1.03, 0.7, 0.92, 1.1, 1.0]
const ATO_FAMILIA_DA_CASA := 0.4    # fração dos bichos que ainda é da família do cômodo; o resto vem misturado
const XP_ONDA_NOCAUTE := 1          # por onda vencida tendo caído
const NOCAUTE_SAUDE := 0.25         # quem caiu volta na onda seguinte com esta fração da vida
const ATR_NOMES: Array[String] = ["Vida", "Força", "Agilidade"]
const ATR_VIDA := 0.08              # +vida máxima por ponto
const ATR_FORCA := 0.06             # +dano por ponto
const ATR_AGIL := 0.05              # +velocidade de ataque por ponto
const ATR_AGIL_VEL := 0.03          # +velocidade de movimento por ponto
const NOMES_BONECOS: Array[String] = ["Fiapo", "Botão", "Retalho", "Feltro", "Novelo"]

# ---------- Poder especial da fantasia completa ----------
const PODER_INTERVALO := 9.0        # segundos entre usos
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
const PODER_IMITAR_FORCA := 1.0
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
const PODER_IMITAR_RECARGA := 0.35      # o Imitar recarrega mais depressa (fração a menos)
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
const PODER_COCHILO_CURA := 0.5 
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
	Pecas.Conjunto.MAGO,         # Coruja: Relâmpago
	Pecas.Conjunto.VIKING,       # Vira-Lata: Fúria
	Pecas.Conjunto.OURICO,       # Texugo-Rei: Bola de espinhos
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
static func gerar_plano(fase: int, onda: int, rng: RandomNumberGenerator, ato: int = 1, vencidos: int = 0) -> Array:
	var p: int = progresso(fase, onda) if ato <= 1 else progresso_ato(ato, vencidos, onda)
	var degrau: float = (fase - 1) if ato <= 1 else (Fases.TOTAL - 1) + vencidos * 0.5
	var fase_pecas: int = fase if ato <= 1 else Fases.TOTAL
	var n: int = int(round(INIMIGOS_BASE + onda * INIMIGOS_POR_ONDA + degrau * INIMIGOS_POR_FASE))
	if tem_chefe(onda):
		n = int(round(n * CHEFE_LACAIOS))
	var plano: Array = []
	var nivel: int = mini(INIMIGO_NIVEL_MAX, int(floor((p - 1) * NIVEL_INIMIGO_POR_ONDA)))
	for i in n:
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
			var opcoes: Array = Fases.pecas_do_slot(fase_pecas, s)
			var tipo: int = opcoes[rng.randi_range(0, opcoes.size() - 1)]
			pecas[s] = Peca.new(tipo, nivel)
		var item: Dictionary = {"pecas": pecas, "tipo": Unidade.Tipo.COMUM, "elite": false}
		if ato > 1 and rng.randf() >= ATO_FAMILIA_DA_CASA:
			item["fam"] = rng.randi_range(0, Fases.TOTAL - 1)
		plano.append(item)
	_sortear_tipos(plano, p, rng)
	_sortear_elites(plano, fase + (Fases.TOTAL if ato > 1 else 0), onda, nivel, rng)
	return plano

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

## Inimigos fantasiados: comuns que vestem uma fantasia da fase (e largam uma peça dela).
static func _sortear_elites(plano: Array, fase: int, onda: int, nivel: int, rng: RandomNumberGenerator) -> void:
	if onda < ELITE_ONDA_MIN:
		return
	var quantos: int = 2 if onda >= ELITE_ONDA_DOIS and not tem_chefe(onda) else 1
	var comuns: Array = []
	for i in plano.size():
		if plano[i]["tipo"] == Unidade.Tipo.COMUM:
			comuns.append(i)
	for k in mini(quantos, comuns.size()):
		var i: int = comuns[comuns.size() - 1 - k]  # os últimos a entrar
		plano[i]["pecas"] = fantasia(fase, nivel, ELITE_PECAS[(fase - 1) % Fases.TOTAL], rng)
		plano[i]["elite"] = true

## Peças de uma fantasia sorteada entre as da fase; `quantas` < 4 deixa um espaço vazio.
static func fantasia(fase: int, nivel: int, quantas: int, rng: RandomNumberGenerator) -> Array:
	var conjs: Array = Fases.CONJUNTOS[fase - 1]
	var c: int = conjs[rng.randi_range(0, conjs.size() - 1)]
	var pecas: Array = [null, null, null, null]
	var fora: int = rng.randi_range(0, Pecas.SLOTS - 1) if quantas < Pecas.SLOTS else -1
	for s in Pecas.SLOTS:
		if s != fora:
			pecas[s] = Peca.new(Pecas.CONJUNTO_PECAS[c][s], nivel)
	return pecas

## Peças do chefe da fase (fantasia completa, nível alto, uma marca cada). Vazio se a onda não tem chefe.
static func gerar_chefe(fase: int, onda: int, rng: RandomNumberGenerator, ato: int = 1, vencidos: int = 0) -> Array:
	if not tem_chefe(onda):
		return []
	var p: int = progresso(fase, onda) if ato <= 1 else progresso_ato(ato, vencidos, onda)
	var nivel: int = mini(INIMIGO_NIVEL_MAX, int(floor((p - 1) * NIVEL_INIMIGO_POR_ONDA)) + CHEFE_NIVEL_BONUS)
	var pecas: Array = fantasia(fase + (Fases.TOTAL if ato > 1 else 0), nivel, Pecas.SLOTS, rng)
	for pc in pecas:
		pc.marcar(rng.randi_range(0, Pecas.Marca.size() - 1))
	return pecas
