class_name Torre
extends RefCounted
## Dados da torre: melhorias permanentes (pagas com troféus) e módulos (um por chefe vencido).

enum Melhoria { ESTRUTURA, CANHAO, CADENCIA, ENFERMARIA }
const MELHORIA_NOME: Array[String] = ["Estrutura", "Canhão", "Rapidez", "Enfermaria"]
const MELHORIA_NIVEL_MAX := 8
const MELHORIA_CUSTO := 4            # troféus por nível, do 1 ao 5 (preço fixo)
const MELHORIA_CUSTO_ALTO := 6       # ...e dos níveis 6 a 8
const NIVEL_BASE := 5                # até aqui valem os números "cheios"; depois cada nível rende menos em cura
const ESTRUTURA_BLOCOS := 3          # blocos iniciais a mais por nível
const CANHAO_DANO := 0.15            # +dano do tiro por nível
const CADENCIA_RAPIDEZ := 0.10       # +tiros por segundo por nível
const ENFERMARIA_CURA := 0.06        # +cura entre ondas por nível, até o 5 (somada a Balanco.CURA_MAX)
const ENFERMARIA_CURA_ALTO := 0.025  # ...e por nível do 6 ao 8 (passar de 100% de cura seria desperdício)

const TROFEU_ELITE := 1              # por inimigo fantasiado derrotado
const TROFEU_CHEFE_ATO: Array[int] = [5, 6, 8]   # por chefe derrotado, por ato
const TROFEU_CHEFE := 5              # (o do primeiro ato; para textos)

## Módulos: o índice é o do chefe que o libera (Fases.Chefe): vencer o chefe da fase N libera o módulo N-1.
## Os 5 primeiros vêm dos chefes da casa; os 5 últimos, dos chefes de fora (Toupeira, Gambá, Coruja, Vira-Lata, Texugo).
enum Modulo { RATOEIRA, CATAPULTA, SIRENE, BALISTA, CALDEIRAO, FOSSO, REPELENTE, LUNETA, CASINHA, REFORCO }
const MODULOS_POR_ABA := 5
const MODULO_NOME: Array[String] = ["Ratoeira", "Catapulta de ração", "Sirene", "Balista de penas", "Caldeirão", "Fosso", "Repelente", "Luneta", "Casinha", "Reforço"]
const MODULO_DICA: Array[String] = [
	"Quem bate na torre de perto leva o troco",
	"De tempos em tempos lança um saco de ração que fere em área",
	"Quando a torre cai à metade, um alarme atordoa todos os bichos (uma vez por onda)",
	"O tiro da torre atravessa e fere mais dois bichos atrás do alvo",
	"Durante a luta, repõe um bloco de tempos em tempos",
	"De tempos em tempos o bicho comum mais perto da torre cai num buraco: leva dano e fica tonto",
	"Bichos perto da torre andam e batem mais devagar",
	"O tiro mira o alvo prioritário, às vezes acerta em cheio e deixa o alvo mais frágil",
	"Um cão de guarda luta ao lado da torre a cada onda",
	"Os primeiros golpes de cada onda na torre não derrubam bloco; o chefe derruba no máximo um",
]
## Vagas de módulo por ato vencido (todos os lugares do ato): 2 no começo, 3 ao vencer o 2º ato, 4 ao vencer o 3º.
const VAGAS_POR_ATO: Array[int] = [2, 2, 3, 4]
const MODULOS_EQUIPADOS_MAX := 4
const RATOEIRA_DANO := 7.0
const CATAPULTA_INTERVALO := 5.0
const CATAPULTA_DANO := 9.0
const CATAPULTA_RAIO := 75.0
const SIRENE_LIMIAR := 0.5           # fração dos blocos máximos
const SIRENE_T := 3.0
const SIRENE_CHEFE := 0.4            # fração do tempo que vale para chefes
const BALISTA_EXTRAS := 2
const BALISTA_DANO := 0.6            # fração do dano do tiro nos bichos de trás
const BALISTA_LARGURA := 55.0
const CALDEIRAO_INTERVALO := 12.0
const FOSSO_INTERVALO := 9.0
const FOSSO_DANO := 12.0
const FOSSO_T := 3.0                 # segundos tonto, sem lutar
const REPELENTE_RAIO := 140.0
const REPELENTE_LENTO := 0.72        # vale para andar e para o ritmo dos golpes
const LUNETA_CRITICO := 0.25
const LUNETA_MARCA := 0.15           # dano a mais no alvo marcado
const LUNETA_MARCA_T := 4.0
const CASINHA_VIDA := 60.0
const CASINHA_DANO := 6.0
const CASINHA_INTERVALO := 1.0
const CASINHA_VEL := 100.0
const REFORCO_GOLPES := 3            # golpes por onda que não tiram bloco
const REFORCO_CHEFE_MAX := 1         # blocos por golpe do chefe


## Texto do que o próximo nível da melhoria dá.
static func melhoria_dica(m: int) -> String:
	match m:
		Melhoria.ESTRUTURA:
			return "+%d blocos no começo de cada cômodo" % ESTRUTURA_BLOCOS
		Melhoria.CANHAO:
			return "+%d%% de dano no tiro da torre" % int(round(CANHAO_DANO * 100.0))
		Melhoria.CADENCIA:
			return "a torre atira %d%% mais rápido" % int(round(CADENCIA_RAPIDEZ * 100.0))
		Melhoria.ENFERMARIA:
			return "+%d%% de cura entre ondas (do nível 6: +%s%%)" % [int(round(ENFERMARIA_CURA * 100.0)), ("%.1f" % (ENFERMARIA_CURA_ALTO * 100.0)).replace(".", ",")]
	return ""

## Troféus do próximo nível da melhoria que está no nível `n`.
static func custo_melhoria(n: int) -> int:
	return MELHORIA_CUSTO if n < NIVEL_BASE else MELHORIA_CUSTO_ALTO

static func trofeu_chefe(ato: int) -> int:
	return TROFEU_CHEFE_ATO[clampi(ato, 1, TROFEU_CHEFE_ATO.size()) - 1]

## Cura entre ondas da Enfermaria no nível `n` (somada a Balanco.CURA_MAX).
static func enfermaria_cura(n: int) -> float:
	return ENFERMARIA_CURA * mini(n, NIVEL_BASE) + ENFERMARIA_CURA_ALTO * maxi(0, n - NIVEL_BASE)

## Vagas de módulo com `atos` atos totalmente vencidos.
static func vagas(atos: int) -> int:
	return VAGAS_POR_ATO[clampi(atos + 1, 1, VAGAS_POR_ATO.size()) - 1]
