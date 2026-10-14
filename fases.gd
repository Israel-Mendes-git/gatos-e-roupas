class_name Fases
extends RefCounted
## Dados da campanha: os cômodos da casa, a família de bichos invasores e o chefe de cada um.
## (Os nomes internos dos enums vêm de quando os inimigos eram brinquedos: LATA = ratos, PELUCIA = guaxinins,
## CORDA = raposas, PORCELANA = corvos, MASSINHA = sapos; GENERAL = Rei dos Ratos, URSO = Guaxinim Glutão,
## ROBO = Raposa Ligeira, BONECA = Corvo Velho, REI_MASSINHA = Sapo-Rei.)

enum Familia { LATA, PELUCIA, CORDA, PORCELANA, MASSINHA }
enum Chefe { GENERAL, URSO, ROBO, BONECA, REI_MASSINHA, TOUPEIRA, GAMBA, CORUJA, VIRALATA, TEXUGO }

const TOTAL := 5
## Os índices 0..4 são os cômodos (primeiro ato); 5..9 são os lugares de fora da casa (segundo ato).
## `TOTAL` continua sendo o número de lugares por ato. Ver Estado.lugar().
const NOME: Array[String] = ["Quarto", "Sala", "Cozinha", "Sótão", "Porão", "Quintal", "Garagem", "Telhado", "Rua", "Toca"]
const FAMILIA_NOME: Array[String] = [
	"Ratos",
	"Guaxinins",
	"Raposas",
	"Corvos",
	"Sapos",
	"Bando do quintal",
	"Bando da garagem",
	"Bando do telhado",
	"Bando da rua",
	"Bando da toca",
]
const FAMILIA_DICA: Array[String] = [
	"Sem truques: avançam em bando",
	"Gordos e resistentes, mas lentos",
	"Rápidas e frágeis",
	"Bicam forte e caem fácil",
	"Regeneram vida o tempo todo",
	"Todas as famílias juntas, cavando por baixo da cerca",
	"Todas as famílias juntas, escondidas entre caixas e latas",
	"Todas as famílias juntas, pulando de telha em telha",
	"Todas as famílias juntas, donas da calçada",
	"Todas as famílias juntas, em casa: é aqui que elas moram",
]
# multiplicadores da família sobre o inimigo comum
const FAMILIA_VIDA: Array[float] = [1.0, 1.4, 0.9, 0.75, 1.0]
const FAMILIA_VEL: Array[float] = [1.0, 0.85, 1.25, 1.0, 0.9]
const FAMILIA_DANO: Array[float] = [1.0, 1.0, 1.0, 1.2, 1.0]
const FAMILIA_REGEN: Array[float] = [0.0, 0.0, 0.0, 0.0, 1.2]

const CHEFE_NOME: Array[String] = [
	"Rei dos Ratos",
	"Guaxinim Glutão",
	"Raposa Ligeira",
	"Corvo Velho",
	"Sapo-Rei",
	"Toupeira Escavadora",
	"Gambá Fedido",
	"Coruja da Meia-Noite",
	"Vira-Lata Chefão",
	"Texugo-Rei",
]
const CHEFE_ATAQUE: Array[String] = [
	"Chama ratos de reforço",
	"Cada patada fere todos em volta",
	"Dispara em direção à torre",
	"Atira penas de longe em quem está atrás",
	"Regenera e se desfaz em sapinhos ao cair",
	"Cava e some; reaparece em cima do gato mais atrás",
	"O fedor deixa os gatos lentos e, de tempos em tempos, tontos",
	"Atira de longe e dá rasantes que ferem a fileira inteira",
	"Late e joga os gatos para trás; chama a matilha",
	"Couro grosso: golpe fraco não fere. Ferido, ataca em dobro",
]
const CHEFE_FRAQUEZA: Array[String] = [
	"Lento: tiros de longe têm tempo de sobra",
	"Pelo seco: fogo fere em dobro",
	"Quando perde o fôlego, fica parada e frágil",
	"Ossos ocos: golpes de perto ferem mais",
	"Explosões ferem em dobro",
	"Sai tonta do buraco: um instante parada e frágil",
	"Gás inflamável: fogo fere em dobro",
	"Explosões a derrubam do ar: ferem em dobro",
	"Depois de latir fica sem fôlego e recebe dano em dobro",
	"Varinha, poderes e fogo passam pelo couro",
]

## Fantasias que os inimigos fantasiados e o chefe de cada fase vestem (e largam).
const CONJUNTOS: Array = [
	[Pecas.Conjunto.CAVALEIRO, Pecas.Conjunto.VIKING, Pecas.Conjunto.ENCANADOR, Pecas.Conjunto.BOSQUE],
	[Pecas.Conjunto.GUARDIAO, Pecas.Conjunto.JARDINEIRO, Pecas.Conjunto.CAUBOI, Pecas.Conjunto.TARTARUGA],
	[Pecas.Conjunto.CIRCO, Pecas.Conjunto.PIRATA, Pecas.Conjunto.MORCEGO, Pecas.Conjunto.ARANHA, Pecas.Conjunto.OURICO],
	[Pecas.Conjunto.REI, Pecas.Conjunto.MAGO, Pecas.Conjunto.ESTELAR, Pecas.Conjunto.GELO],
	[Pecas.Conjunto.SOMBRIO, Pecas.Conjunto.FERRO, Pecas.Conjunto.TROVAO, Pecas.Conjunto.PATRULHEIRO],
	# fora da casa caem as mesmas fantasias, redistribuídas, mais 4 kits novos só daqui: Abelha no Quintal, Robô Azul na Garagem, Ninja da Folha no Telhado, Tubarão na Rua
	[Pecas.Conjunto.CAVALEIRO, Pecas.Conjunto.JARDINEIRO, Pecas.Conjunto.BOSQUE, Pecas.Conjunto.OURICO, Pecas.Conjunto.ABELHA],
	[Pecas.Conjunto.ENCANADOR, Pecas.Conjunto.FERRO, Pecas.Conjunto.CIRCO, Pecas.Conjunto.TARTARUGA, Pecas.Conjunto.ROBO_AZUL],
	[Pecas.Conjunto.MORCEGO, Pecas.Conjunto.ARANHA, Pecas.Conjunto.MAGO, Pecas.Conjunto.TROVAO, Pecas.Conjunto.NINJA_FOLHA],
	[Pecas.Conjunto.CAUBOI, Pecas.Conjunto.PIRATA, Pecas.Conjunto.PATRULHEIRO, Pecas.Conjunto.ESTELAR, Pecas.Conjunto.GUARDIAO, Pecas.Conjunto.TUBARAO],
	[Pecas.Conjunto.REI, Pecas.Conjunto.SOMBRIO, Pecas.Conjunto.VIKING, Pecas.Conjunto.GELO],
]

## Tipos de peça que os inimigos comuns da fase podem vestir, por espaço:
## as fantasias desta fase e das anteriores.
static func pecas_do_slot(fase: int, slot: int) -> Array:
	var conj: Dictionary = {}
	for f in range(0, clampi(fase, 1, TOTAL)):
		for c in CONJUNTOS[f]:
			conj[c] = true
	var lista: Array = []
	for c in conj:
		lista.append(Pecas.CONJUNTO_PECAS[c][slot])
	return lista
