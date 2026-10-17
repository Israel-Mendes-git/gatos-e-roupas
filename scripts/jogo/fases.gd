class_name Fases
extends RefCounted
## Dados da campanha: os cômodos da casa, a família de bichos invasores e o chefe de cada um.
## (Os nomes internos dos enums vêm de quando os inimigos eram brinquedos: LATA = ratos, PELUCIA = guaxinins,
## CORDA = raposas, PORCELANA = corvos, MASSINHA = sapos; GENERAL = Rei dos Ratos, URSO = Guaxinim Glutão,
## ROBO = Raposa Ligeira, BONECA = Corvo Velho, REI_MASSINHA = Sapo-Rei; e CORUJA = Esquilo Acrobata, que entrou no lugar da coruja.)

enum Familia { LATA, PELUCIA, CORDA, PORCELANA, MASSINHA }
enum Chefe { GENERAL, URSO, ROBO, BONECA, REI_MASSINHA, TOUPEIRA, GAMBA, CORUJA, VIRALATA, TEXUGO, DOM_GATLEONE, IMORTAL_MIAU, PROGRAMA_MESTRE, REI_MIAUNIDAS, MAGNETOMIAU }

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
	"Esquilo Acrobata",
	"Vira-Lata Chefão",
	"Texugo-Rei",
]
const CHEFE_ATAQUE: Array[String] = [
	"Chama ratos de reforço. Poder: Ordem real (os ratos atacam em dobro)",
	"Cada patada fere todos em volta. Poder: Pisão no gato mais forte",
	"Dispara em direção à torre. Poder: Carga de lança",
	"Atira penas de longe em quem está atrás. Poder: Trovoada",
	"Regenera e se desfaz em sapinhos ao cair. Poder: Teia (prende os gatos mais perto)",
	"Cava e some; reaparece em cima do gato mais atrás. Poder: Arrastão (puxa os gatos para o buraco)",
	"O fedor deixa os gatos lentos e, de tempos em tempos, tontos. Poder: Enxame",
	"Arremessa bolotas de longe e dá saltos acrobáticos que ferem a fileira inteira. Poder: Relâmpago",
	"Late e joga os gatos para trás; chama a matilha. Poder: Fúria",
	"Couro grosso: golpe fraco não fere. Ferido, ataca em dobro. Poder: Bola de espinhos",
]
const CHEFE_FRAQUEZA: Array[String] = [
	"Lento: tiros de longe têm tempo de sobra",
	"Pelo seco: fogo fere em dobro",
	"Quando perde o fôlego, fica parada e frágil",
	"Ossos ocos: golpes de perto ferem mais",
	"Explosões ferem em dobro",
	"Sai tonta do buraco: um instante parada e frágil",
	"Gás inflamável: fogo fere em dobro",
	"Explosões o derrubam no meio do salto: ferem em dobro",
	"Depois de latir fica sem fôlego e recebe dano em dobro",
	"Varinha, poderes e fogo passam pelo couro",
]

## Fantasias que os inimigos fantasiados e o chefe de cada lugar vestem (e largam). Cada fantasia ativa tem UMA casa.
## Índice = lugar global: 0..4 cômodos (1º ato), 5..9 lugares de fora (2º ato), 10..14 ruas das gangues (3º ato).
## Tabela final em notas/onde_cai_final.md (seção 2). Leia sempre por lista_do_lugar(): ela soma o PROVISORIO.
const CONJUNTOS: Array = [
	# 1º ato: a casa
	[Pecas.Conjunto.ENCANADOR, Pecas.Conjunto.BOSQUE, Pecas.Conjunto.PATRULHEIRO, Pecas.Conjunto.CAVALEIRO],        # Quarto: brinquedos e videogame
	[Pecas.Conjunto.ESTELAR, Pecas.Conjunto.CAUBOI, Pecas.Conjunto.FENIX_MIAUSSIMO, Pecas.Conjunto.JIMIAU],         # Sala: TV, cinema, mesa de jogo
	[Pecas.Conjunto.CIRCO, Pecas.Conjunto.MIAULAX, Pecas.Conjunto.ABELHA, Pecas.Conjunto.GUARDIAO],                 # Cozinha: comida, festa, mel
	[Pecas.Conjunto.MAGO, Pecas.Conjunto.REI, Pecas.Conjunto.MIMIAU],                                               # Sótão: baú, magia, fantasmas
	[Pecas.Conjunto.FERRO, Pecas.Conjunto.SOMBRIO, Pecas.Conjunto.ROBO_AZUL],                                       # Porão: oficina escura, energia, vilões
	# 2º ato: o lado de fora
	[Pecas.Conjunto.JARDINEIRO, Pecas.Conjunto.DISPARAMIAU, Pecas.Conjunto.GIRAMIAU, Pecas.Conjunto.STARDEW_MIAULLEY],   # Quintal: horta e jardim
	[Pecas.Conjunto.ROCKET_MIAUGUE, Pecas.Conjunto.MOTOQUEIRO_MIAUSMA, Pecas.Conjunto.OURICO],                      # Garagem: carros, motos, velocidade
	[Pecas.Conjunto.MORCEGO, Pecas.Conjunto.ARANHA, Pecas.Conjunto.TROVAO, Pecas.Conjunto.NINJA_FOLHA],             # Telhado: noite, antenas, tempestade
	[Pecas.Conjunto.TARTARUGA, Pecas.Conjunto.DONATEMIAU, Pecas.Conjunto.LEONARMIAU, Pecas.Conjunto.RAFAMIAU],      # Rua: as 4 tartarugas juntas
	[Pecas.Conjunto.HOLLOWMIAU, Pecas.Conjunto.SILKMIAU, Pecas.Conjunto.MIAUCRAFT],                                 # Toca: subterrâneo e masmorra
	# 3º ato: as ruas e telhados das gangues
	[Pecas.Conjunto.SUBMIAUTICA, Pecas.Conjunto.CATCHULLU, Pecas.Conjunto.TUBARAO, Pecas.Conjunto.PIRATA],          # Mercadão do Peixe
	[Pecas.Conjunto.ARTHUR_MIAURGON, Pecas.Conjunto.DEADMIAU, Pecas.Conjunto.ARQUEOLOGO, Pecas.Conjunto.VIKING],    # Ferro-velho
	[Pecas.Conjunto.TREINADOR, Pecas.Conjunto.MEON, Pecas.Conjunto.MIAU_NOIR],                                      # Beco do Fliperama
	[Pecas.Conjunto.MIAUZILLA, Pecas.Conjunto.SUPER_MIAUJIN, Pecas.Conjunto.RANGER_MIAU],                           # Arena da Praça
	[Pecas.Conjunto.SUPER_MIAU, Pecas.Conjunto.ARQUEIRO_MIAU, Pecas.Conjunto.GELO, Pecas.Conjunto.KING_MIAU],       # Telhados e Antenas
]

## Fantasias do 3º ato que caem nos lugares do 2º ato (índices 5..9, uma lista por lugar) enquanto Balanco.ATOS < 3.
## Por tema: água no Quintal (piscina, grama alta), motores e ferro-velho na Garagem, antenas e super-heróis no Telhado,
## monstros e lutadores na Rua, escuro e gelo na Toca. Ligar o 3º ato (Balanco.ATOS = 3) apaga o efeito sozinho.
const PROVISORIO: Array = [
	[Pecas.Conjunto.TUBARAO, Pecas.Conjunto.PIRATA, Pecas.Conjunto.TREINADOR, Pecas.Conjunto.SUBMIAUTICA],          # Quintal (8)
	[Pecas.Conjunto.SUPER_MIAUJIN, Pecas.Conjunto.DEADMIAU, Pecas.Conjunto.ARTHUR_MIAURGON, Pecas.Conjunto.RANGER_MIAU],   # Garagem (7)
	[Pecas.Conjunto.SUPER_MIAU, Pecas.Conjunto.ARQUEIRO_MIAU, Pecas.Conjunto.KING_MIAU],                            # Telhado (7)
	[Pecas.Conjunto.MEON, Pecas.Conjunto.MIAU_NOIR, Pecas.Conjunto.MIAUZILLA],                                      # Rua (7)
	[Pecas.Conjunto.GELO, Pecas.Conjunto.VIKING, Pecas.Conjunto.ARQUEOLOGO, Pecas.Conjunto.CATCHULLU],              # Toca (7)
]

## Fantasia-assinatura do chefe de cada lugar (índice = lugar global): ele a veste com Balanco.CHEFE_ASSINATURA_CHANCE.
const CHEFE_ASSINATURA: Array[int] = [
	Pecas.Conjunto.CAVALEIRO, Pecas.Conjunto.JIMIAU, Pecas.Conjunto.ABELHA, Pecas.Conjunto.MAGO, Pecas.Conjunto.SOMBRIO,
	Pecas.Conjunto.STARDEW_MIAULLEY, Pecas.Conjunto.MOTOQUEIRO_MIAUSMA, Pecas.Conjunto.ARANHA, Pecas.Conjunto.RAFAMIAU, Pecas.Conjunto.HOLLOWMIAU,
	Pecas.Conjunto.SUBMIAUTICA, Pecas.Conjunto.ARTHUR_MIAURGON, Pecas.Conjunto.TREINADOR, Pecas.Conjunto.MIAUZILLA, Pecas.Conjunto.KING_MIAU,
]

## Lugares e chefes do 3º ato (índices globais 10..14; ficam fora de NOME e CHEFE_NOME, que têm só 2 atos).
const NOME_ATO3: Array[String] = ["Mercadão do Peixe", "Ferro-velho", "Beco do Fliperama", "Arena da Praça", "Telhados e Antenas"]
const CHEFE_NOME_ATO3: Array[String] = ["Dom Gatleone", "Imortal Miau", "Programa Mestre", "Rei Miaunidas", "Magnetomiau"]
## As gangues de gatos rivais (uma por lugar do 3º ato), a cor da bandana e a pelagem (índice de Desenho.PELAGENS não usado pelo time).
const GANGUE_NOME: Array[String] = ["Família Gatíssima", "Estrada Furiosa", "Tropa do Grid", "Legião Miauparta", "Irmandade Mutante"]
const GANGUE_DICA: Array[String] = [
	"Gatos de gangue do Mercadão: enfrentam o time antes de ir à torre",
	"Gatos de gangue do Ferro-velho: enfrentam o time antes de ir à torre",
	"Gatos de gangue do Beco: enfrentam o time antes de ir à torre",
	"Gatos de gangue da Arena: enfrentam o time antes de ir à torre",
	"Gatos de gangue dos Telhados: enfrentam o time antes de ir à torre",
]
const GANGUE_COR: Array[Color] = [
	Color(0.62, 0.12, 0.22), Color(0.95, 0.5, 0.15), Color(0.2, 0.85, 0.95), Color(0.85, 0.2, 0.12), Color(0.62, 0.3, 0.9),
]
## Pelagem de cada gangue: [textura, tinta] (todas fora das 5 do time).
const GANGUE_PELAGEM: Array = [
	[0, Color(0.55, 0.5, 0.55)], [1, Color(0.7, 0.55, 0.4)], [2, Color(0.5, 0.58, 0.62)], [1, Color(0.6, 0.45, 0.4)], [0, Color(0.7, 0.62, 0.8)],
]
# multiplicadores da gangue sobre o rival comum (partem de 1,0; calibrar por truque nas próximas etapas)
const GANGUE_VIDA: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]
const GANGUE_VEL: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]
const GANGUE_DANO: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]
## Os chefes do 3º ato são gatos grandes com mecânica própria (Fases.Chefe 10 a 14; ver Simulacao._chefe_gangue).
const CHEFE_ATAQUE_ATO3: Array[String] = [
	"Chama o Mensageiro: se tocar a torre, leva um gato a dormir. Depois, Capangas. Poder: Arrastão",
	"O comboio varre faixas do campo (aviso de 1 s); depois, duas faixas e mais veloz. Poder: Carga de lança",
	"Lança disco que quica em 3 gatos e deixa em pixel por 3 s. Volta uma vez ao cair. Poder: Trovoada",
	"Falange: de frente quase não leva dano. Chuta o gato da frente; depois, chuva de flechas. Poder: Fúria",
	"Campo magnético puxa o time e anula o bônus de conjunto por 6 s; no fim, levanta um carro. Poder: Relâmpago",
]
const CHEFE_FRAQUEZA_ATO3: Array[String] = [
	"Mate o Mensageiro antes da torre; pelo seco, fogo fere em dobro",
	"Entre as faixas, nas fileiras livres, ele fica exposto",
	"Quando recompila, fica um instante frágil: guarde força",
	"Ataque pelos flancos e use poderes: de frente ele quase não sente",
	"Sem o bônus de conjunto o time fica fraco: espalhe-se e mate rápido",
]

## Chefe (Fases.Chefe) cujo desenho e mecânica o chefe do lugar global `i` usa.
static func chefe_base(i: int) -> int:
	return clampi(i, 0, TOTAL * 3 - 1)

static func ataque_do_chefe(i: int) -> String:
	return CHEFE_ATAQUE[i] if i < CHEFE_ATAQUE.size() else CHEFE_ATAQUE_ATO3[clampi(i - CHEFE_ATAQUE.size(), 0, 4)]

static func fraqueza_do_chefe(i: int) -> String:
	return CHEFE_FRAQUEZA[i] if i < CHEFE_FRAQUEZA.size() else CHEFE_FRAQUEZA_ATO3[clampi(i - CHEFE_FRAQUEZA.size(), 0, 4)]

## Nome do grupo de bichos do lugar global `i` (família, bando ou gangue).
static func grupo_nome(i: int) -> String:
	return FAMILIA_NOME[i] if i < FAMILIA_NOME.size() else GANGUE_NOME[clampi(i - TOTAL * 2, 0, 4)]

static func grupo_dica(i: int) -> String:
	return FAMILIA_DICA[i] if i < FAMILIA_DICA.size() else GANGUE_DICA[clampi(i - TOTAL * 2, 0, 4)]

static func nome_do_lugar(i: int) -> String:
	return NOME[i] if i < NOME.size() else NOME_ATO3[clampi(i - NOME.size(), 0, NOME_ATO3.size() - 1)]

static func nome_do_chefe(i: int) -> String:
	return CHEFE_NOME[i] if i < CHEFE_NOME.size() else CHEFE_NOME_ATO3[clampi(i - CHEFE_NOME.size(), 0, CHEFE_NOME_ATO3.size() - 1)]

## Fantasias que caem no lugar `i` (0..14): a lista dele e, até o 3º ato existir, as provisórias do 2º ato.
static func lista_do_lugar(i: int) -> Array:
	var l: Array = CONJUNTOS[i]
	if Balanco.ATOS < 3 and i >= TOTAL and i < TOTAL * 2:
		l = l + (PROVISORIO[i - TOTAL] as Array)
	return l

## Lugar onde a fantasia está de verdade (a casa final, na tabela CONJUNTOS); -1 se não cai em lugar nenhum.
static func casa_final(c: int) -> int:
	for i in CONJUNTOS.size():
		if (CONJUNTOS[i] as Array).has(c):
			return i
	return -1

## Lugar onde ela cai agora (a casa final ou, até o 3º ato existir, o lugar provisório); -1 se não cai.
static func lugar_atual(c: int) -> int:
	for i in CONJUNTOS.size():
		if lista_do_lugar(i).has(c):
			return i
	return -1

## Fantasias das casas dos atos anteriores a `ato` (ato 2 = as da casa; ato 3 = casa e fora), sem repetir.
static func pool_anterior(ato: int) -> Array:
	var conj: Array = []
	for i in range(0, clampi(ato - 1, 0, 3) * TOTAL):
		for c in CONJUNTOS[i]:
			if not conj.has(c):
				conj.append(c)
	return conj

## Tipo de peça que um inimigo comum do lugar global `lugar` (0..14) veste no espaço `slot`.
## Ato 1: as fantasias dos cômodos até o atual. Atos 2 e 3: com chance FRACAO_COMUM_DO_LUGAR sai da lista do lugar,
## senão de uma fantasia dos atos anteriores (as velhas continuam caindo, para fundir e subir raridade).
static func pecas_do_slot(lugar: int, slot: int, ato: int, rng: RandomNumberGenerator, fracao: float = -1.0) -> int:
	var conj: Array = []
	if ato <= 1:
		for f in range(0, clampi(lugar + 1, 1, TOTAL)):
			for c in CONJUNTOS[f]:
				if not conj.has(c):
					conj.append(c)
	elif rng.randf() < (Balanco.FRACAO_COMUM_DO_LUGAR if fracao < 0.0 else fracao):
		conj = lista_do_lugar(clampi(lugar, 0, CONJUNTOS.size() - 1))
	else:
		conj = pool_anterior(ato)
	var c: int = conj[rng.randi_range(0, conj.size() - 1)]
	return Pecas.CONJUNTO_PECAS[c][slot]
