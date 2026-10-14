class_name Torre
extends RefCounted
## Dados da torre: melhorias permanentes (pagas com troféus) e módulos (um por chefe vencido).

enum Melhoria { ESTRUTURA, CANHAO, CADENCIA, ENFERMARIA }
const MELHORIA_NOME: Array[String] = ["Estrutura", "Canhão", "Rapidez", "Enfermaria"]
const MELHORIA_NIVEL_MAX := 5
const MELHORIA_CUSTO := 4            # troféus por nível (preço fixo)
const ESTRUTURA_BLOCOS := 3          # blocos iniciais a mais por nível
const CANHAO_DANO := 0.15            # +dano do tiro por nível
const CADENCIA_RAPIDEZ := 0.10       # +tiros por segundo por nível
const ENFERMARIA_CURA := 0.06        # +cura entre ondas por nível (somada a Balanco.CURA_MAX)

const TROFEU_ELITE := 1              # por inimigo fantasiado derrotado
const TROFEU_CHEFE := 5              # por chefe derrotado

## Módulos: o índice é o do chefe que o libera (Fases.Chefe): vencer o chefe da fase N libera o módulo N-1.
enum Modulo { RATOEIRA, CATAPULTA, SIRENE, BALISTA, CALDEIRAO }
const MODULO_NOME: Array[String] = ["Ratoeira", "Catapulta de ração", "Sirene", "Balista de penas", "Caldeirão"]
const MODULO_DICA: Array[String] = [
	"Quem bate na torre de perto leva o troco",
	"De tempos em tempos lança um saco de ração que fere em área",
	"Quando a torre cai à metade, um alarme atordoa todos os bichos (uma vez por onda)",
	"O tiro da torre atravessa e fere mais dois bichos atrás do alvo",
	"Durante a luta, repõe um bloco de tempos em tempos",
]
const MODULOS_EQUIPADOS_MAX := 2
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
			return "+%d%% de cura dos gatos entre as ondas" % int(round(ENFERMARIA_CURA * 100.0))
	return ""
