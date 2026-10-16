class_name Pecas
extends RefCounted
## Dados estáticos das peças: 100 tipos, 4 espaços, 25 fantasias, 3 raridades.
## As 36 primeiras têm efeito próprio; as demais copiam o efeito de uma delas (MOLDE) com outra força.

enum Tipo {
	PORRETE, ESTILINGUE, ESCUDO, COLETE, CAPA, ESPINHOS, CAPACETE, CHAPEU, MASCARA, LANCA, TOCHA, AVENTAL, BARRIL, COROA, CHIFRES,
	CETRO, REGADOR, SABRE, VARINHA,
	CARTOLA, CAUBOI, TRICORNIO, PONTUDO,
	PELE, PONCHO, CASACO, MANTO,
	BOTAS, JOELHEIRAS, BANDEIRA, NARIZ, COLAR, SEMENTES, CANTIL, GANCHO, AMULETO,
	# fantasias de referência (4 por linha: cabeça, corpo, mão, acessório)
	BONE_ENCANADOR, MACACAO, DESENTUPIDOR, COGUMELO,
	CAPUZ_MORCEGO, CAPA_MORCEGO, BUMERANGUE, CINTO,
	MASCARA_TEIA, COLANTE, LANCA_TEIA, ARANHA_PET,
	CAPUZ_ESTELAR, TUNICA, SABRE_LUZ, CRISTAL,
	ELMO_SOMBRIO, ARMADURA_SOMBRIA, SABRE_RUBRO, RESPIRADOR,
	GORRO, TUNICA_VERDE, ESPADA_LENDARIA, OCARINA,
	BANDANA, CASCO, NUNCHAKU, PIZZA,
	TOPETE, PELO_AZUL, LUVAS, TENIS,
	CAPACETE_FERRO, ARMADURA_FERRO, REPULSOR, REATOR,
	ELMO_ALADO, CAPA_RUBRA, MARTELO, CINTURAO,
	TIARA, VESTIDO, CETRO_GELO, FLOCO,
	CAPACETE_BOLHA, TRAJE, LASER, JATO,
	# fantasias do lado de fora (índices 84 a 99): poderes novos
	BANDANA_FOLHA, MACACAO_LARANJA, KUNAI, PERGAMINHO,
	CAPACETE_AZUL, ARMADURA_AZUL, CANHAO_BRACO, TANQUE,
	CAPUZ_TUBARAO, ROUPA_TUBARAO, MORDIDA, BOIA,
	ANTENAS, COLETE_LISTRADO, FERRAO, POTE_MEL,
	# expansão das fantasias, lote 1 (índices 100 a 123): sem arte própria ainda, desenham com o molde (ver RoupaGatoF)
	FRANJA_HEROICA, COLLANT_S, PUNHO_ACO, CAPA_VERMELHA,
	CAPUZ_ARQUEIRO, COLETE_FOLHAS, ARCO_RECURVO, ALJAVA,
	CAVEIRA_CHAMAS, JAQUETA_ESPETOS, CORRENTE_FOGO, RODA_FOGO,
	FRANJA_ADVOGADO, TERNO_TRIBUNAL, LUVA_APONTAR, DISTINTIVO,
	CAPUZ_PELUCIA, DISFARCE_AMARELO, PATA_MISTERIOSA, RABO_PAPELAO,
	CORINGA_CHAPEU, COLETE_BARALHO, LEQUE_POQUER, FICHAS,
}
const PROPRIAS := 36   # tipos com efeito próprio

enum Marca { CICATRIZ, CERCO, FURO, BRASA, POLVORA }

const MARCA_NOME: Array[String] = ["Cicatriz", "Estilhaço", "Couraça", "Brasa", "Pólvora"]
const MARCA_DICA: Array[String] = [
	"vida máxima",
	"golpes ferem em volta",
	"projéteis ferem menos",
	"golpes queimam",
	"explode ao morrer",
]
const MARCA_COR: Array[Color] = [
	Color(1.0, 0.3, 0.5),    # cicatriz
	Color(0.72, 0.45, 1.0),  # cerco
	Color(0.35, 0.85, 1.0),  # furo
	Color(1.0, 0.5, 0.05),   # brasa
	Color(0.6, 1.0, 0.3),    # pólvora
]

const SLOTS := 4
const SLOT_CABECA := 0
const SLOT_CORPO := 1
const SLOT_MAO := 2
const SLOT_ACESSORIO := 3
const SLOT_NOME: Array[String] = ["Cabeça", "Corpo", "Mão", "Acessório"]

const SLOT: Array[int] = [
	2, 2, 2, 1, 1, 1, 0, 0, 0, 2, 2, 1, 1, 0, 0,
	2, 2, 2, 2,
	0, 0, 0, 0,
	1, 1, 1, 1,
	3, 3, 3, 3, 3, 3, 3, 3, 3,
	0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,
]
const NOME: Array[String] = [
	"Porrete", "Estilingue", "Escudo", "Colete", "Capa", "Espinhos", "Capacete", "Chapéu de palha", "Máscara", "Lança", "Tocha", "Avental", "Barril", "Coroa", "Chifres",
	"Cetro", "Regador", "Sabre", "Varinha",
	"Cartola", "Chapéu de caubói", "Chapéu de pirata", "Chapéu pontudo",
	"Pele de urso", "Poncho", "Casaco", "Manto",
	"Botas", "Joelheiras", "Bandeira", "Nariz vermelho", "Colar de dentes", "Saco de sementes", "Cantil", "Gancho", "Amuleto",
	"Boné de encanador", "Macacão", "Desentupidor", "Cogumelo",
	"Capuz de morcego", "Capa de morcego", "Bumerangue", "Cinto de utilidades",
	"Máscara de teia", "Colante de aranha", "Lança-teia", "Aranha de estimação",
	"Capuz estelar", "Túnica estelar", "Espada de luz", "Cristal estelar",
	"Elmo sombrio", "Armadura sombria", "Espada rubra", "Respirador",
	"Gorro verde", "Túnica verde", "Espadiau Mestre", "Ocarina",
	"Bandana ninja", "Casco de tartaruga", "Nunchaku", "Fatia de pizza",
	"Topete de ouriço", "Pelo azul", "Luvas brancas", "Tênis vermelhos",
	"Capacete de ferro", "Armadura de ferro", "Luva repulsora", "Reator",
	"Elmo alado", "Capa rubra", "Miaulnir", "Cinturão de força",
	"Tiara de gelo", "Vestido de gelo", "Cetro de gelo", "Floco de neve",
	"Capacete de bolha", "Traje espacial", "Laser de pulso", "Mochila a jato",
	"Bandana com placa", "Macacão laranja", "Kunai", "Pergaminho",
	"Capacete azul", "Armadura azul", "Canhão de braço", "Tanque de energia",
	"Capuz de tubarão", "Roupa de tubarão", "Dentadura", "Boia de salva-vidas",
	"Antenas", "Colete listrado", "Ferrão", "Pote de mel",
	"Franja Heroica", "Collant Azul com Peito em S", "Punho de Aço", "Capa Vermelha Esvoaçante",
	"Capuz Verde com Pluma", "Colete de Folhas Costuradas", "Arco Recurvo de Brinquedo", "Aljava de Flechas-Truque",
	"Caveira em Chamas", "Jaqueta de Couro com Espetos", "Corrente Flamejante", "Roda de Fogo Portátil",
	"Franja de Advogado", "Terno Azul de Tribunal", "Luva de Apontar Dedo", "Distintivo de Advogado Dourado",
	"Capuz de Pelúcia Mal Costurado", "Disfarce Amarelo Remendado", "Pata Misteriosa", "Rabo de Raio de Papelão",
	"Chapéu de Coringa de Três Pontas", "Colete de Baralho", "Mão de Pôquer em Leque", "Fichas de Cassino Empilhadas",
]
const DICA: Array[String] = [
	"Pancada forte de perto",
	"Atira de longe",
	"Reduz dano e atrai inimigos",
	"Muita vida",
	"Rápido e esquiva golpes",
	"Devolve dano a quem bate",
	"Armadura contra golpes",
	"Regenera vida",
	"Inimigos próximos ficam lentos",
	"Alcance médio, bate por trás do escudo",
	"Golpe fraco que deixa o alvo queimando",
	"Cura o aliado ferido mais próximo",
	"Explode ao morrer, ferindo inimigos",
	"Aliados por perto causam mais dano",
	"Quanto menos vida, mais dano",
	"Golpe lento que fere todos em volta do alvo",
	"Jato curto que deixa o alvo lento",
	"Golpes fracos e muito rápidos",
	"Tiro lento e forte que ignora armadura",
	"Chance de golpe crítico",
	"Ataca mais rápido",
	"Abates podem render blocos para a torre",
	"Fere aos poucos os inimigos em volta",
	"Vida, e cura ao abater",
	"Projéteis ferem bem menos",
	"Vida, e mais dano a cada abate na luta",
	"Anula um golpe de tempos em tempos",
	"Anda mais rápido",
	"Reduz todo dano recebido",
	"Aliados por perto regeneram vida",
	"Atrai inimigos e esquiva golpes",
	"Mais dano em todo ataque",
	"Ao morrer, cura todos os aliados",
	"Uma vez por luta, cura quando a vida está baixa",
	"Golpes devolvem vida a quem bate",
	"As marcas das outras peças valem em dobro",
]
## Texto do efeito de uma peça (as de referência usam o do molde).
static func dica(tipo: int) -> String:
	return DICA[MOLDE[tipo]]

const POR_SLOT: Array = [
	[6, 7, 8, 13, 14, 19, 20, 21, 22, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120],    # cabeça
	[3, 4, 5, 11, 12, 23, 24, 25, 26, 37, 41, 45, 49, 53, 57, 61, 65, 69, 73, 77, 81, 85, 89, 93, 97, 101, 105, 109, 113, 117, 121],    # corpo
	[0, 1, 2, 9, 10, 15, 16, 17, 18, 38, 42, 46, 50, 54, 58, 62, 66, 70, 74, 78, 82, 86, 90, 94, 98, 102, 106, 110, 114, 118, 122],     # mão
	[27, 28, 29, 30, 31, 32, 33, 34, 35, 39, 43, 47, 51, 55, 59, 63, 67, 71, 75, 79, 83, 87, 91, 95, 99, 103, 107, 111, 115, 119, 123], # acessório
]
## Tipo cujo efeito cada peça usa (as 36 primeiras usam o próprio).
const MOLDE: Array[int] = [
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
	16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
	32, 33, 34, 35, 6, 3, 0, 33, 8, 4, 1, 28, 19, 4, 16, 34,
	7, 26, 17, 35, 6, 5, 10, 31, 20, 24, 9, 29, 14, 3, 17, 33,
	22, 25, 17, 27, 6, 3, 18, 35, 13, 23, 15, 31, 8, 26, 16, 28,
	19, 3, 1, 27,
	# lado de fora: Ninja (rápido e esquivo), Robô (blindado, tiro forte), Tubarão (pancada e vida), Abelha (ferrão que queima, enxame que fere)
	20, 4, 17, 27,
	6, 3, 18, 33,
	14, 23, 0, 34,
	22, 5, 10, 32,
	# lote 1 (Telhado, Garagem, Rua, Toca): Super Miau, Arqueiro Miau, Motoqueiro Miausma, Fênix Miaussimo, Mimiau, Jimiau
	Tipo.CAPACETE, Tipo.COLETE, Tipo.PORRETE, Tipo.CANTIL,
	Tipo.CAUBOI, Tipo.PONCHO, Tipo.ESTILINGUE, Tipo.COLAR,
	Tipo.CHIFRES, Tipo.CASACO, Tipo.TOCHA, Tipo.GANCHO,
	Tipo.CARTOLA, Tipo.COLETE, Tipo.CETRO, Tipo.AMULETO,
	Tipo.MASCARA, Tipo.MANTO, Tipo.VARINHA, Tipo.NARIZ,
	Tipo.CARTOLA, Tipo.COLETE, Tipo.VARINHA, Tipo.AMULETO,
]
## Força do efeito em relação ao molde.
const MOLDE_PODER: Array[float] = [
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
	1.1, 1.1, 1.1, 1.2, 1.0, 1.0, 1.15, 1.0, 1.0, 1.0, 1.3, 1.0,
	1.0, 1.0, 1.25, 1.0, 1.25, 1.2, 1.2, 1.0, 1.0, 1.2, 1.2, 1.2,
	1.0, 1.25, 1.1, 1.0, 1.2, 1.0, 1.15, 1.3, 1.15, 1.2, 1.1, 1.0,
	0.8, 1.2, 1.3, 1.2, 1.0, 1.0, 1.4, 1.0, 1.0, 1.15, 1.3, 1.2,
	1.15, 1.15, 1.2, 1.1,
	1.2, 1.15, 1.3, 1.1,
	1.2, 1.2, 1.2, 1.15,
	1.15, 1.15, 1.25, 1.15,
	1.1, 1.1, 1.15, 1.1,
	1.1, 1.1, 1.15, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
]

# ---------- Fantasias (conjuntos) ----------
enum Conjunto {
	CAVALEIRO, GUARDIAO, REI, CIRCO, VIKING, JARDINEIRO, CAUBOI, PIRATA, MAGO,
	ENCANADOR, MORCEGO, ARANHA, ESTELAR, SOMBRIO, BOSQUE, TARTARUGA, OURICO, FERRO, TROVAO, GELO, PATRULHEIRO,
	NINJA_FOLHA, ROBO_AZUL, TUBARAO, ABELHA,
	SUPER_MIAU, ARQUEIRO_MIAU, MOTOQUEIRO_MIAUSMA, FENIX_MIAUSSIMO, MIMIAU, JIMIAU,   # lote 1 da expansão
}

const CONJUNTO_NOME: Array[String] = ["Cavaleiro", "Guardamiau", "Sua Miauestade", "Palhamiau", "Vikingato", "Jardimiau", "Caubói", "Piramiau", "Miauerlin",
	"Miaurio", "Batmiau", "Garoto-Aranhiau", "Jedimiau", "Darth Miauder", "Linkmiau", "Miauchelangelo", "Sonimiau", "Iron Miau", "Thormiau", "Elsamiau", "Buzz Lightmiau",
	"Narutomiau", "Mega Miau", "Gatubarão", "Gatabelha",
	"Super Miau", "Arqueiro Miau", "Motoqueiro Miausma", "Fênix Miaussimo", "Mimiau", "Jimiau",
]
## Peças de cada fantasia, na ordem dos espaços: cabeça, corpo, mão, acessório.
const CONJUNTO_PECAS: Array = [
	[Tipo.CAPACETE, Tipo.COLETE, Tipo.LANCA, Tipo.BOTAS],
	[Tipo.MASCARA, Tipo.ESPINHOS, Tipo.ESCUDO, Tipo.JOELHEIRAS],
	[Tipo.COROA, Tipo.CAPA, Tipo.CETRO, Tipo.BANDEIRA],
	[Tipo.CARTOLA, Tipo.BARRIL, Tipo.TOCHA, Tipo.NARIZ],
	[Tipo.CHIFRES, Tipo.PELE, Tipo.PORRETE, Tipo.COLAR],
	[Tipo.CHAPEU, Tipo.AVENTAL, Tipo.REGADOR, Tipo.SEMENTES],
	[Tipo.CAUBOI, Tipo.PONCHO, Tipo.ESTILINGUE, Tipo.CANTIL],
	[Tipo.TRICORNIO, Tipo.CASACO, Tipo.SABRE, Tipo.GANCHO],
	[Tipo.PONTUDO, Tipo.MANTO, Tipo.VARINHA, Tipo.AMULETO],
	[Tipo.BONE_ENCANADOR, Tipo.MACACAO, Tipo.DESENTUPIDOR, Tipo.COGUMELO],
	[Tipo.CAPUZ_MORCEGO, Tipo.CAPA_MORCEGO, Tipo.BUMERANGUE, Tipo.CINTO],
	[Tipo.MASCARA_TEIA, Tipo.COLANTE, Tipo.LANCA_TEIA, Tipo.ARANHA_PET],
	[Tipo.CAPUZ_ESTELAR, Tipo.TUNICA, Tipo.SABRE_LUZ, Tipo.CRISTAL],
	[Tipo.ELMO_SOMBRIO, Tipo.ARMADURA_SOMBRIA, Tipo.SABRE_RUBRO, Tipo.RESPIRADOR],
	[Tipo.GORRO, Tipo.TUNICA_VERDE, Tipo.ESPADA_LENDARIA, Tipo.OCARINA],
	[Tipo.BANDANA, Tipo.CASCO, Tipo.NUNCHAKU, Tipo.PIZZA],
	[Tipo.TOPETE, Tipo.PELO_AZUL, Tipo.LUVAS, Tipo.TENIS],
	[Tipo.CAPACETE_FERRO, Tipo.ARMADURA_FERRO, Tipo.REPULSOR, Tipo.REATOR],
	[Tipo.ELMO_ALADO, Tipo.CAPA_RUBRA, Tipo.MARTELO, Tipo.CINTURAO],
	[Tipo.TIARA, Tipo.VESTIDO, Tipo.CETRO_GELO, Tipo.FLOCO],
	[Tipo.CAPACETE_BOLHA, Tipo.TRAJE, Tipo.LASER, Tipo.JATO],
	[Tipo.BANDANA_FOLHA, Tipo.MACACAO_LARANJA, Tipo.KUNAI, Tipo.PERGAMINHO],
	[Tipo.CAPACETE_AZUL, Tipo.ARMADURA_AZUL, Tipo.CANHAO_BRACO, Tipo.TANQUE],
	[Tipo.CAPUZ_TUBARAO, Tipo.ROUPA_TUBARAO, Tipo.MORDIDA, Tipo.BOIA],
	[Tipo.ANTENAS, Tipo.COLETE_LISTRADO, Tipo.FERRAO, Tipo.POTE_MEL],
	[Tipo.FRANJA_HEROICA, Tipo.COLLANT_S, Tipo.PUNHO_ACO, Tipo.CAPA_VERMELHA],
	[Tipo.CAPUZ_ARQUEIRO, Tipo.COLETE_FOLHAS, Tipo.ARCO_RECURVO, Tipo.ALJAVA],
	[Tipo.CAVEIRA_CHAMAS, Tipo.JAQUETA_ESPETOS, Tipo.CORRENTE_FOGO, Tipo.RODA_FOGO],
	[Tipo.FRANJA_ADVOGADO, Tipo.TERNO_TRIBUNAL, Tipo.LUVA_APONTAR, Tipo.DISTINTIVO],
	[Tipo.CAPUZ_PELUCIA, Tipo.DISFARCE_AMARELO, Tipo.PATA_MISTERIOSA, Tipo.RABO_PAPELAO],
	[Tipo.CORINGA_CHAPEU, Tipo.COLETE_BARALHO, Tipo.LEQUE_POQUER, Tipo.FICHAS],
]
## Fantasia de cada tipo de peça.
const CONJUNTO_DE: Array[int] = [
	4, 6, 1, 0, 2, 1, 0, 5, 1, 0, 3, 5, 3, 2, 4,
	2, 5, 7, 8,
	3, 6, 7, 8,
	4, 6, 7, 8,
	0, 1, 2, 3, 4, 5, 6, 7, 8,
	9, 9, 9, 9, 10, 10, 10, 10, 11, 11, 11, 11, 12, 12, 12, 12,
	13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16,
	17, 17, 17, 17, 18, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 20,
	21, 21, 21, 21, 22, 22, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24,
	25, 25, 25, 25, 26, 26, 26, 26, 27, 27, 27, 27, 28, 28, 28, 28, 29, 29, 29, 29, 30, 30, 30, 30,
]
const CONJUNTO_COR: Array[Color] = [
	Color(0.72, 0.78, 0.86),  # cavaleiro
	Color(0.35, 0.72, 0.55),  # guardião
	Color(1.0, 0.82, 0.25),   # rei
	Color(1.0, 0.35, 0.3),    # circo
	Color(0.75, 0.52, 0.32),  # viking
	Color(0.55, 0.85, 0.3),   # jardineiro
	Color(0.9, 0.62, 0.3),    # caubói
	Color(0.35, 0.6, 0.95),   # pirata
	Color(0.7, 0.45, 1.0),    # mago
	Color(0.9, 0.2, 0.2),  # encanador
	Color(0.35, 0.38, 0.5),  # homem-morcego
	Color(0.85, 0.15, 0.25),  # garoto-aranha
	Color(0.55, 0.8, 1.0),  # cavaleiro estelar
	Color(0.8, 0.25, 0.3),  # lorde sombrio
	Color(0.3, 0.7, 0.3),  # herói do bosque
	Color(0.4, 0.75, 0.3),  # tartaruga ninja
	Color(0.2, 0.4, 0.95),  # ouriço veloz
	Color(0.85, 0.25, 0.15),  # armadura de ferro
	Color(0.75, 0.2, 0.2),  # deus do trovão
	Color(0.6, 0.9, 1.0),  # princesa do gelo
	Color(0.6, 0.9, 0.4),  # patrulheiro espacial
	Color(1.0, 0.55, 0.1),  # ninja da folha
	Color(0.2, 0.5, 1.0),  # robô azul
	Color(0.5, 0.65, 0.78),  # tubarão
	Color(1.0, 0.85, 0.15),  # abelha
	Color(0.25, 0.45, 0.95),  # super miau
	Color(0.2, 0.65, 0.3),  # arqueiro miau
	Color(1.0, 0.45, 0.1),  # motoqueiro miausma
	Color(0.25, 0.35, 0.7),  # fênix miaussimo
	Color(0.95, 0.85, 0.3),  # mimiau
	Color(0.6, 0.3, 0.85),  # jimiau
]
## Tipo do bônus numérico de cada fantasia (os 9 primeiros valores são os de Conjunto.CAVALEIRO..MAGO; as novas fantasias usam BONUS_*).
const BONUS_CANTIL := 9      # cura única abaixo de 35% (Super Miau)
const BONUS_CRITICO := 10    # chance de golpe crítico (Arqueiro Miau)
const BONUS_BARREIRA := 11   # anula um golpe a cada N segundos (Mimiau)
const BONUS_CARGA := 12      # recarga do poder mais curta (Jimiau)
const CONJUNTO_MOLDE: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 1, 6, 6, 5, 8, 4, 0, 6, 0, 4, 1, 7, 6, 4, 7, 8,
	BONUS_CANTIL, BONUS_CRITICO, 8, 0, BONUS_BARREIRA, BONUS_CARGA]

# ---------- Poder especial da fantasia completa ----------
## Os 16 primeiros são os da primeira leva; os de baixo foram acrescentados na rodada de poderes diversos (valores novos no fim: o save grava a fantasia, não este índice).
enum Poder { RAIO, EXPLOSAO, ATORDOA, CURA, PROTEGE, FRENESI, ATRAVESSA, RAJADA, GELO, EMPURRA, GIRO, DRENO, INVOCA, TELEPORTE, PUXA, ENXAME,
	RAIZ, SAQUE, TROVOADA, CANHAO, MISSEIS, CANCAO, INVESTIDA, FUMACA, FURIA, PISAO, CANTEIRO, TRIAGEM, MARCA, BOLA,
	SALVAMENTO, RICOCHETE, OLHAR, OBJECAO, IMITAR, POQUER }
const PODER_TIPO: Array[int] = [Poder.INVESTIDA, Poder.PROTEGE, Poder.FRENESI, Poder.ATORDOA, Poder.FURIA, Poder.CANTEIRO, Poder.SAQUE, Poder.CANHAO, Poder.RAIO,
	Poder.PISAO, Poder.FUMACA, Poder.RAIZ, Poder.EMPURRA, Poder.DRENO, Poder.CANCAO, Poder.TRIAGEM, Poder.BOLA, Poder.MISSEIS, Poder.TROVOADA, Poder.GELO, Poder.MARCA,
	Poder.INVOCA, Poder.TELEPORTE, Poder.PUXA, Poder.ENXAME,
	Poder.SALVAMENTO, Poder.RICOCHETE, Poder.OLHAR, Poder.OBJECAO, Poder.IMITAR, Poder.POQUER]
## Poderes que o bicho fantasiado NÃO usa (o fantasiado só ganha o bônus de kit).
const PODER_SO_GATO: Array[int] = [Poder.SALVAMENTO, Poder.OBJECAO, Poder.IMITAR]
## Fantasias cujo poder o Imitar não copia (evita laço infinito).
const IMITAR_EXCLUI: Array[int] = [Conjunto.MIMIAU]
const PODER_NOME: Array[String] = [
	"Carga de lança", "Muralha", "Ordem real", "Buzina", "Fúria",
	"Chuva de pétalas", "Saque rápido", "Bala de canhão", "Relâmpago", "Pisão",
	"Fumaça", "Teia", "Empurrão", "Aperto sombrio", "Canção do tempo",
	"Pizza para todos", "Bola de espinhos", "Salva de mísseis", "Trovoada", "Nevasca",
	"Alvo travado",
	"Clones", "Teletransporte", "Arrastão", "Enxame",
	"Salvamento", "Flecha ricochete", "Olhar da Penitência", "Objeção!", "Imitar", "Mão de pôquer",
]
const PODER_DICA: Array[String] = [
	"investe pela fileira, fere quem cruza, derruba o primeiro e fica protegido",
	"o time recebe bem menos dano por uns segundos",
	"o time ataca em dobro por uns segundos",
	"atordoa os inimigos em volta",
	"por uns segundos os golpes ferem em volta e roubam vida",
	"um canteiro cura os aliados dentro e atrasa os inimigos",
	"seis tiros, sempre no inimigo mais fraco",
	"explode o maior bando, queima e devolve blocos por bicho derrotado",
	"raio fortíssimo no inimigo mais resistente",
	"pula de inimigo em inimigo, esmagando os mais fortes",
	"esconde os aliados em volta: os bichos trocam de alvo",
	"prende os inimigos mais perto da torre: não andam, mas ainda atacam",
	"joga os inimigos para longe",
	"fere um inimigo e toma a vida dele",
	"adianta a recarga dos poderes dos outros gatos",
	"cura muito o mais ferido e um pouco os outros",
	"fica rápido, espinhento e firme contra atordoar",
	"três explosões na entrada da torre",
	"raios nos maiores bandos, atordoando",
	"deixa todos os inimigos lentos",
	"o laser marca quem atravessa: recebe mais dano de tudo",
	"dois clones lutam ao seu lado por uns segundos",
	"aparece junto do inimigo mais ao fundo, golpeia e fica protegido",
	"puxa os inimigos de longe para perto e fere cada um",
	"uma nuvem de abelhas fere os inimigos mais próximos por uns segundos",
	"leva o aliado mais ferido ao posto, cura e soca o chão onde ele estava",
	"uma flecha salta de inimigo em inimigo, mais forte a cada salto",
	"queima os 3 inimigos de maior vida: dano em % da vida máxima deles",
	"corta o poder que um bicho está carregando e anima o time (só com aviso)",
	"repete o último poder usado na luta; sem nenhum, vira um Disfarce",
	"saca cartas e joga a melhor mão: quanto melhor, mais dano no bando",
]
const CONJUNTO_MIN := 2   # peças para o bônus parcial; com as 4, bônus completo

# ---------- Raridades ----------
enum Raridade { COMUM, RARA, EPICA, LENDARIA, MITICA, MIAUJESTOSA }
const RARIDADE_NOME: Array[String] = ["Comum", "Rara", "Épica", "Lendária", "Mítica", "Miaujestosa"]
const RARIDADE_COR: Array[Color] = [Color(0.8, 0.8, 0.8), Color(0.35, 0.65, 1.0), Color(0.72, 0.38, 1.0), Color(1.0, 0.72, 0.15), Color(0.3, 0.95, 0.95), Color(1.0, 0.9, 0.95)]

## Cor da raridade. A Mítica gira pelo arco-íris (claro, perto do ciano); a Miaujestosa pulsa entre o branco-pérola e o rosa;
## as outras são fixas.
static func cor_rar(r: int) -> Color:
	var i: int = clampi(r, 0, RARIDADE_COR.size() - 1)
	if i == Raridade.MITICA:
		return Color.from_hsv(fposmod(Time.get_ticks_msec() / 1000.0 * 0.3 + 0.5, 1.0), 0.55, 1.0)
	if i == Raridade.MIAUJESTOSA:
		return Color(1.0, 0.97, 0.9).lerp(Color(1.0, 0.72, 0.88), 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 2.4))
	return RARIDADE_COR[i]

## Linha da dica para n marcas de um tipo (ex.: "Brasa ×2: golpes queimam (+4/s)").
static func marca_linha(m: int, n: int) -> String:
	var extra: String = ""
	match m:
		Marca.CICATRIZ:
			extra = "+%d" % int(round(Balanco.MARCA_CICATRIZ_VIDA * n))
		Marca.CERCO:
			extra = "%d%% do dano" % int(round(Balanco.MARCA_CERCO_DANO * n * 100.0))
		Marca.FURO:
			extra = "-%d%%" % int(round(minf(Balanco.MARCA_FURO_MAX, Balanco.MARCA_FURO_REDUCAO * n) * 100.0))
		Marca.BRASA:
			extra = "+%d/s" % int(round(Balanco.MARCA_BRASA_DPS * n))
		Marca.POLVORA:
			extra = "+%d" % int(round(Balanco.MARCA_POLVORA_DANO * n))
	return "%s ×%d: %s (%s)" % [MARCA_NOME[m], n, MARCA_DICA[m], extra]

## Quantas peças de cada fantasia estão vestidas (índice = Conjunto).
static func contar_conjuntos(pecas: Array) -> Array[int]:
	var cont: Array[int] = []
	cont.resize(Conjunto.size())
	cont.fill(0)
	for p in pecas:
		if p != null:
			cont[CONJUNTO_DE[p.tipo]] += 1
	return cont

## Grau do bônus de fantasia para n peças vestidas: 0 nada, 1 parcial, 2 completo.
static func grau_conjunto(n: int) -> int:
	if n >= SLOTS:
		return 2
	return 1 if n >= CONJUNTO_MIN else 0

## Texto do bônus de uma fantasia no grau dado (1 parcial, 2 completo).
static func conjunto_bonus(c: int, grau: int) -> String:
	var g: int = clampi(grau, 1, 2) - 1
	var v: float = Balanco.conj_valor(c, g)
	match CONJUNTO_MOLDE[c]:
		Conjunto.CAVALEIRO:
			return "+%d de armadura" % int(v)
		Conjunto.GUARDIAO:
			return "+%d%% de vida" % int(round(v * 100.0))
		Conjunto.REI:
			return "aliados por perto: +%d%% de dano" % int(round(v * 100.0))
		Conjunto.CIRCO:
			return "explode ao morrer (+%d)" % int(v)
		Conjunto.VIKING:
			return "+%d%% de dano" % int(round(v * 100.0))
		Conjunto.JARDINEIRO:
			return "regenera +%d de vida por segundo" % int(v)
		Conjunto.CAUBOI:
			return "ataca %d%% mais rápido" % int(round(v * 100.0))
		Conjunto.PIRATA:
			return "golpes devolvem %d%% do dano em vida" % int(round(v * 100.0))
		Conjunto.MAGO:
			return "golpes queimam (+%d/s)" % int(v)
		BONUS_CANTIL:
			return "cantil: cura %d%% da vida uma vez, abaixo de %d%%" % [int(round(v * 100.0)), int(round(Balanco.CANTIL_LIMIAR * 100.0))]
		BONUS_CRITICO:
			return "+%d%% de chance de golpe crítico" % int(round(v * 100.0))
		BONUS_BARREIRA:
			return "anula um golpe a cada %d s" % int(v)
		BONUS_CARGA:
			return "o poder recarrega %d%% mais depressa" % int(round(v * 100.0))
	return ""
