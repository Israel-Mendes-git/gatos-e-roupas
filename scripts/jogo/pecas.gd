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
	# expansão das fantasias, lote 2 (índices 124 a 147): ver RoupaGatoG
	CABECA_ERVILHA, CAULE_FOLHAS, METRALHA_ERVILHA, VAGEM_MUNICAO,
	ESPIGA_MILHO, FOLHAS_MILHO, BAZUCA_PIPOCA, TABLETE_MANTEIGA,
	PETALAS_SOL, CAULE_RAIOS, LANTERNA_SOL, VASO_SORRISO,
	BONE_FAZENDA, MACACAO_JEANS, ENXADA, GALINHA,
	CUBO_PIXEL, CAMISETA_BLOCOS, PICARETA, MINI_CREEPER,
	TOUCA_SONECA, BARRIGA_CREME, TRAVESSEIRO, PRATO_VAZIO,
	# expansão das fantasias, lote 3 (índices 148 a 171): ver RoupaGatoH
	BANDANA_AZUL, CASCO_POLIDO, KATANAS_GEMEAS, CINTO_L,
	BANDANA_ROXA, CASCO_ENGENHOCAS, BASTAO_BO, COMPUTADOR_PULSO,
	BANDANA_VERMELHA, CASCO_ARRANHADO, PAR_DE_SAIS, CINTO_R,
	PARABRISA_CAPACETE, CARROCERIA_TURBO, BOLA_COSMICA, PROPULSOR_TURBO,
	MASCARA_VERMELHA, TRAJE_REMENDADO, KATANAS_PAPELAO, CHIMICHANGA,
	FRANJA_LOIRA, JAQUETA_COURO, FACA_TATICA, MALETA_MERCADOR,
	# expansão das fantasias, lote 4 (índices 172 a 195): ver RoupaGatoI
	FEDORA_TEIA, SOBRETUDO_CINZA, LANTERNA_BECO, ROLO_FILME,
	MASCARA_OCA, MANTO_PRETINHO, PREGO_AFIADO, FRASCO_ALMA,
	MASCARA_CASCA, CAPA_CARMESIM, AGULHA_GIGANTE, NOVELO_SEDA,
	CABELO_DOURADO, KIMONO_LARANJA, CONCHA_ENERGIA, ESFERA_ESTRELAS,
	CHAPEU_AMASSADO, JAQUETA_GASTA, CHICOTE_BARBANTE, IDOLO_ATUM,
	BONE_VERMELHO, MOCHILA_AMARELA, MIAUBOLA, RATO_ELETRICO,
	# expansão das fantasias, lote 5 (índices 196 a 219): ver RoupaGatoJ
	CAPACETE_VISEIRA, MACACAO_LYCRA, SABRE_BLASTER, PULSEIRA_TRANSFORMAR,
	CRISTA_PLACAS, PELE_ATOMICA, GARRAS_MONSTRO, CAUDA_RADIOATIVA,
	CABECA_GORILA, PELAGEM_GORILA, PREDIO_BRINQUEDO, BIPLANO_PAPEL,
	CHAPEU_FORA_LEI, CASACO_LENCO, RIFLE_CACADOR, CADERNINHO,
	CAPACETE_AQUARIO, MACACAO_PRESSURIZADO, RIFLE_ESTASE, TANQUE_PEIXINHO,
	CABECA_POLVO, MANTO_ABISSAL, NECRONOMIAU, TENTACULO_FOFO,
	# Ateliê (índices 220 a 223): a fantasia que o jogador cria; forma, molde e cor vêm de Atelie (desenham como a peça escolhida)
	ATELIE_CABECA, ATELIE_CORPO, ATELIE_MAO, ATELIE_ACESSORIO,
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
	0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3,
	0, 1, 2, 3,
]
## (static var: as quatro peças do Ateliê trocam de nome conforme a forma escolhida; ver Atelie.aplicar)
static var NOME: Array[String] = [
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
	"Franja de Advogado", "Terno Azul de Tribunal", "Martelo da Objeção", "Distintivo de Advogado Dourado",
	"Capuz de Pelúcia Mal Costurado", "Disfarce Amarelo Remendado", "Pata Misteriosa", "Rabo de Raio de Papelão",
	"Chapéu de Coringa de Três Pontas", "Colete de Baralho", "Mão de Pôquer em Leque", "Fichas de Cassino Empilhadas",
	"Cabeça de Ervilha com Canhão-Boca", "Caule com Folhas", "Metralhadora de Ervilha", "Vagem de Munição",
	"Espiga de Milho Careca", "Folhas de Milho Apertadas", "Bazuca de Pipoca", "Tablete de Manteiga",
	"Pétalas de Girassol", "Colete de Folhas de Girassol", "Flor de Mão do Girassol", "Sol do Quintal",
	"Chapéu de Palha de Fazendeiro", "Jardineira Azul e Camisa Vermelha", "Enxada de Fazenda", "Junimo Escondido",
	"Cabeça de Steve", "Camiseta Ciano e Calça Índigo", "Picareta de Diamante", "Bloco de Grama",
	"Touca de Soneca", "Barriga Gigante Creme", "Onigiri Quentinho", "Cesto de Frutas",
	"Bandana Azul de Líder", "Casco Verde Bem Polido", "Katanas Gêmeas Afiadas Demais", "Cinto Azul com Fivela L",
	"Bandana Roxa com Óculos de Soldador", "Casco Cheio de Engenhocas", "Bastão Extensível", "Computador de Pulso Gordinho",
	"Bandana Vermelha Torta", "Casco Cheio de Arranhões", "Par de Sais Prontas", "Cinto Vermelho Mal-Humorado",
	"Para-brisa de Capacete", "Carroceria Azul Turbo", "Bola Gigante de Futebol Cósmico", "Propulsor Turbo",
	"Máscara Vermelha de Olhos Brancos", "Traje Vermelho Cheio de Remendos", "Duas Katanas de Papelão", "Chimichanga Fatal",
	"Franja Rebelde Loira", "Jaqueta de Couro Marrom", "Pistola do Agente", "Maleta do Mercador",
	"Fedora com Máscara de Teia", "Sobretudo Cinza Pingando", "Pistola do Detetive", "Rolo de Filme P&B",
	"Máscara de Cavaleiro Oco", "Manto Preto Pequenino", "Prego Afiado", "Frasco de Alma",
	"Máscara de Casca Branca com Chifres Finos", "Capa Vermelha Esvoaçante", "Agulha de Costura Gigante", "Novelo de Seda",
	"Cabelo Dourado Espetado", "Kimono Laranja Rasgado", "Concha de Energia Azul", "Esfera de Quatro Estrelas",
	"Chapéu Amassado de Aventureiro", "Jaqueta de Couro Gasta", "Chicote de Barbante", "Ídolo Dourado de Atum",
	"Boné Vermelho e Branco", "Mochila Amarela de Aventureiro", "Miaubola", "Rato Elétrico de Pelúcia",
	"Capacete de Viseira Reluzente", "Macacão de Lycra Tamanho Gato", "Luvas do Ranger", "Pulseira de Transformar",
	"Crista de Placas Dorsais", "Pele de Dinossauro Atômico", "Bafo Atômico", "Cauda Radioativa Gigante",
	"Cabeça de Gorila Peluda", "Pelagem Preta de Gorila", "Mão de Gorila", "Banana",
	"Chapéu de Fora-da-Lei Surrado", "Casaco de Couro com Lenço Vermelho", "Rifle de Caçador", "Caderninho de Esboços",
	"Capuz de Leviatã com Mandíbulas", "Pele de Leviatã de Faixas Ferrugem", "Rifle de Estase", "Cauda de Leviatã com Nadadeiras",
	"Cabeça de Polvo com Barba de Tentáculos", "Manto Verde com Asinhas de Morcego", "Necronomiau", "Tentáculo Fofo",
	"Cabeça do Ateliê", "Corpo do Ateliê", "Mão do Ateliê", "Acessório do Ateliê",
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
	return DICA[molde_de(tipo)]

## Tipo cujo efeito a peça usa (as do Ateliê usam o molde da forma escolhida).
static func molde_de(tipo: int) -> int:
	if tipo >= Tipo.ATELIE_CABECA:
		return Atelie.molde(tipo)
	return MOLDE[tipo]

const POR_SLOT: Array = [
	[6, 7, 8, 13, 14, 19, 20, 21, 22, 36, 40, 44, 48, 52, 56, 60, 64, 68, 72, 76, 80, 84, 88, 92, 96, 100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144, 148, 152, 156, 160, 164, 168, 172, 176, 180, 184, 188, 192, 196, 200, 204, 208, 212, 216, 220],    # cabeça
	[3, 4, 5, 11, 12, 23, 24, 25, 26, 37, 41, 45, 49, 53, 57, 61, 65, 69, 73, 77, 81, 85, 89, 93, 97, 101, 105, 109, 113, 117, 121, 125, 129, 133, 137, 141, 145, 149, 153, 157, 161, 165, 169, 173, 177, 181, 185, 189, 193, 197, 201, 205, 209, 213, 217, 221],    # corpo
	[0, 1, 2, 9, 10, 15, 16, 17, 18, 38, 42, 46, 50, 54, 58, 62, 66, 70, 74, 78, 82, 86, 90, 94, 98, 102, 106, 110, 114, 118, 122, 126, 130, 134, 138, 142, 146, 150, 154, 158, 162, 166, 170, 174, 178, 182, 186, 190, 194, 198, 202, 206, 210, 214, 218, 222],     # mão
	[27, 28, 29, 30, 31, 32, 33, 34, 35, 39, 43, 47, 51, 55, 59, 63, 67, 71, 75, 79, 83, 87, 91, 95, 99, 103, 107, 111, 115, 119, 123, 127, 131, 135, 139, 143, 147, 151, 155, 159, 163, 167, 171, 175, 179, 183, 187, 191, 195, 199, 203, 207, 211, 215, 219, 223], # acessório
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
	# lote 2 (Quintal, Toca): Disparamiau, Milhau, Giramiau, Stardew Miaulley, Miaucraft, Miaulax
	Tipo.CHAPEU, Tipo.AVENTAL, Tipo.ESTILINGUE, Tipo.SEMENTES,
	Tipo.CHAPEU, Tipo.AVENTAL, Tipo.REGADOR, Tipo.SEMENTES,
	Tipo.CHAPEU, Tipo.AVENTAL, Tipo.CETRO, Tipo.BANDEIRA,
	Tipo.CHAPEU, Tipo.AVENTAL, Tipo.PORRETE, Tipo.SEMENTES,
	Tipo.CAPACETE, Tipo.COLETE, Tipo.PORRETE, Tipo.AMULETO,
	Tipo.CHAPEU, Tipo.COLETE, Tipo.ESCUDO, Tipo.SEMENTES,
	# lote 3 (Garagem, Telhado, Rua, Toca): Leonarmiau, Donatemiau, Rafamiau, Rocket Miaugue, Deadmiau, Meon
	Tipo.CAPACETE, Tipo.COLETE, Tipo.LANCA, Tipo.BOTAS,
	Tipo.CAPACETE, Tipo.COLETE, Tipo.LANCA, Tipo.BOTAS,
	Tipo.CAPACETE, Tipo.COLETE, Tipo.LANCA, Tipo.BOTAS,
	Tipo.CAPACETE, Tipo.COLETE, Tipo.PORRETE, Tipo.BOTAS,
	Tipo.MASCARA, Tipo.CASACO, Tipo.SABRE, Tipo.GANCHO,
	Tipo.CAPACETE, Tipo.PONCHO, Tipo.ESTILINGUE, Tipo.JOELHEIRAS,   # Meon: a mão é a Pistola do Agente (tiro de longe)
	# lote 4 (Telhado, Toca): Miau-Noir, Hollowmiau, Silkmiau, Super Miaujin, O Arqueólogo, Treinador de Miaumons
	Tipo.CARTOLA, Tipo.CASACO, Tipo.ESTILINGUE, Tipo.NARIZ,   # Miau-Noir: a mão é a pistola (tiro de longe, como o Meon)
	Tipo.CAPACETE, Tipo.MANTO, Tipo.LANCA, Tipo.AMULETO,
	Tipo.PONTUDO, Tipo.CAPA, Tipo.SABRE, Tipo.GANCHO,
	Tipo.COROA, Tipo.COLETE, Tipo.CETRO, Tipo.COLAR,
	Tipo.TRICORNIO, Tipo.CASACO, Tipo.SABRE, Tipo.GANCHO,
	Tipo.CAUBOI, Tipo.CASACO, Tipo.ESTILINGUE, Tipo.AMULETO,
	# lote 5 (Toca): Ranger Miau, Miauzilla, King-Miau, Arthur Miaurgon, Submiautica, Catchullu
	Tipo.CAPACETE, Tipo.COLETE, Tipo.SABRE, Tipo.COLAR,
	Tipo.CHIFRES, Tipo.ESPINHOS, Tipo.PORRETE, Tipo.JOELHEIRAS,
	Tipo.COROA, Tipo.PELE, Tipo.PORRETE, Tipo.COLAR,
	Tipo.CAUBOI, Tipo.CASACO, Tipo.ESTILINGUE, Tipo.CANTIL,
	Tipo.CAPACETE, Tipo.COLETE, Tipo.VARINHA, Tipo.CANTIL,
	Tipo.CHIFRES, Tipo.MANTO, Tipo.VARINHA, Tipo.AMULETO,
	# Ateliê: valores só de reserva; o molde real vem da forma escolhida (Pecas.molde_de)
	Tipo.CAPACETE, Tipo.COLETE, Tipo.PORRETE, Tipo.AMULETO,
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
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	0.6, 0.6, 0.6, 0.6,   # Super Miaujin: Coroa, Cetro e Colar já rendem muito
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	1.1, 1.1, 1.1, 1.1,
	0.6, 0.6, 0.6, 0.6,   # Ateliê: força fixa (calibrada com o simulador)
]

# ---------- Fantasias (conjuntos) ----------
enum Conjunto {
	CAVALEIRO, GUARDIAO, REI, CIRCO, VIKING, JARDINEIRO, CAUBOI, PIRATA, MAGO,
	ENCANADOR, MORCEGO, ARANHA, ESTELAR, SOMBRIO, BOSQUE, TARTARUGA, OURICO, FERRO, TROVAO, GELO, PATRULHEIRO,
	NINJA_FOLHA, ROBO_AZUL, TUBARAO, ABELHA,
	SUPER_MIAU, ARQUEIRO_MIAU, MOTOQUEIRO_MIAUSMA, FENIX_MIAUSSIMO, MIMIAU, JIMIAU,   # lote 1 da expansão
	DISPARAMIAU, MILHAU, GIRAMIAU, STARDEW_MIAULLEY, MIAUCRAFT, MIAULAX,   # lote 2 (Quintal e Toca)
	LEONARMIAU, DONATEMIAU, RAFAMIAU, ROCKET_MIAUGUE, DEADMIAU, MEON,   # lote 3 (Garagem, Telhado, Rua e Toca)
	MIAU_NOIR, HOLLOWMIAU, SILKMIAU, SUPER_MIAUJIN, ARQUEOLOGO, TREINADOR,   # lote 4 (Telhado e Toca)
	RANGER_MIAU, MIAUZILLA, KING_MIAU, ARTHUR_MIAURGON, SUBMIAUTICA, CATCHULLU,   # lote 5 (Toca, até o 3º ato existir)
	ATELIE,   # a fantasia secreta criada pelo jogador (escondida do fichário; ver Atelie)
}

static var CONJUNTO_NOME: Array[String] = ["Cavaleiro", "Guardamiau", "Sua Miauestade", "Palhamiau", "Vikingato", "Jardimiau", "Caubói", "Piramiau", "Miauerlin",
	"Miaurio", "Batmiau", "Garoto-Aranhiau", "Jedimiau", "Darth Miauder", "Linkmiau", "Miauchelangelo", "Sonimiau", "Iron Miau", "Thormiau", "Elsamiau", "Buzz Lightmiau",
	"Narutomiau", "Mega Miau", "Gatubarão", "Gatabelha",
	"Super Miau", "Arqueiro Miau", "Motoqueiro Miausma", "Fênix Miaussimo", "Mimiau", "Jimiau",
	"Disparamiau", "Milhau", "Giramiau", "Stardew Miaulley", "Miaucraft", "Miaulax",
	"Leonarmiau", "Donatemiau", "Rafamiau", "Rocket Miaugue", "Deadmiau", "Meon",
	"Miau-Noir", "Hollowmiau", "Silkmiau", "Super Miaujin", "O Arqueólogo", "Treinador de Miaumons",
	"Ranger Miau", "Miauzilla", "King-Miau", "Arthur Miaurgon", "Submiautica", "Catchullu",
	"Ateliê",
]
## Fantasias retiradas do jogo: os ids ficam nos enums (o save grava índices), mas não caem, não aparecem no fichário nem contam em metas.
const RETIRADAS: Array[int] = [Conjunto.MILHAU, Conjunto.ATELIE]   # o Ateliê não entra nas contas do fichário (tem tela própria)

static func retirada(c: int) -> bool:
	return c in RETIRADAS

## Retirada de verdade (peças viram de outra fantasia ao carregar o save); o Ateliê só fica escondido.
static func fora_do_jogo(c: int) -> bool:
	return c in RETIRADAS and c != Conjunto.ATELIE

## Quantas fantasias o jogador pode ver e juntar.
static func n_ativas() -> int:
	return CONJUNTO_NOME.size() - RETIRADAS.size()

## Posição da fantasia na lista visível (sem as retiradas); -1 se ela foi retirada.
static func posicao_ativa(c: int) -> int:
	if retirada(c):
		return -1
	var k: int = 0
	for r in RETIRADAS:
		if r < c:
			k += 1
	return c - k

## Fantasia da posição visível `i` (inverso de posicao_ativa).
static func conj_da_posicao(i: int) -> int:
	var c: int = i
	for r in RETIRADAS:
		if r <= c:
			c += 1
	return c

## Peças que o jogador pode ter (sem as das fantasias retiradas).
static func n_pecas_ativas() -> int:
	return SLOT.size() - SLOTS * RETIRADAS.size()

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
	[Tipo.CABECA_ERVILHA, Tipo.CAULE_FOLHAS, Tipo.METRALHA_ERVILHA, Tipo.VAGEM_MUNICAO],
	[Tipo.ESPIGA_MILHO, Tipo.FOLHAS_MILHO, Tipo.BAZUCA_PIPOCA, Tipo.TABLETE_MANTEIGA],
	[Tipo.PETALAS_SOL, Tipo.CAULE_RAIOS, Tipo.LANTERNA_SOL, Tipo.VASO_SORRISO],
	[Tipo.BONE_FAZENDA, Tipo.MACACAO_JEANS, Tipo.ENXADA, Tipo.GALINHA],
	[Tipo.CUBO_PIXEL, Tipo.CAMISETA_BLOCOS, Tipo.PICARETA, Tipo.MINI_CREEPER],
	[Tipo.TOUCA_SONECA, Tipo.BARRIGA_CREME, Tipo.TRAVESSEIRO, Tipo.PRATO_VAZIO],
	[Tipo.BANDANA_AZUL, Tipo.CASCO_POLIDO, Tipo.KATANAS_GEMEAS, Tipo.CINTO_L],
	[Tipo.BANDANA_ROXA, Tipo.CASCO_ENGENHOCAS, Tipo.BASTAO_BO, Tipo.COMPUTADOR_PULSO],
	[Tipo.BANDANA_VERMELHA, Tipo.CASCO_ARRANHADO, Tipo.PAR_DE_SAIS, Tipo.CINTO_R],
	[Tipo.PARABRISA_CAPACETE, Tipo.CARROCERIA_TURBO, Tipo.BOLA_COSMICA, Tipo.PROPULSOR_TURBO],
	[Tipo.MASCARA_VERMELHA, Tipo.TRAJE_REMENDADO, Tipo.KATANAS_PAPELAO, Tipo.CHIMICHANGA],
	[Tipo.FRANJA_LOIRA, Tipo.JAQUETA_COURO, Tipo.FACA_TATICA, Tipo.MALETA_MERCADOR],
	[Tipo.FEDORA_TEIA, Tipo.SOBRETUDO_CINZA, Tipo.LANTERNA_BECO, Tipo.ROLO_FILME],
	[Tipo.MASCARA_OCA, Tipo.MANTO_PRETINHO, Tipo.PREGO_AFIADO, Tipo.FRASCO_ALMA],
	[Tipo.MASCARA_CASCA, Tipo.CAPA_CARMESIM, Tipo.AGULHA_GIGANTE, Tipo.NOVELO_SEDA],
	[Tipo.CABELO_DOURADO, Tipo.KIMONO_LARANJA, Tipo.CONCHA_ENERGIA, Tipo.ESFERA_ESTRELAS],
	[Tipo.CHAPEU_AMASSADO, Tipo.JAQUETA_GASTA, Tipo.CHICOTE_BARBANTE, Tipo.IDOLO_ATUM],
	[Tipo.BONE_VERMELHO, Tipo.MOCHILA_AMARELA, Tipo.MIAUBOLA, Tipo.RATO_ELETRICO],
	[Tipo.CAPACETE_VISEIRA, Tipo.MACACAO_LYCRA, Tipo.SABRE_BLASTER, Tipo.PULSEIRA_TRANSFORMAR],
	[Tipo.CRISTA_PLACAS, Tipo.PELE_ATOMICA, Tipo.GARRAS_MONSTRO, Tipo.CAUDA_RADIOATIVA],
	[Tipo.CABECA_GORILA, Tipo.PELAGEM_GORILA, Tipo.PREDIO_BRINQUEDO, Tipo.BIPLANO_PAPEL],
	[Tipo.CHAPEU_FORA_LEI, Tipo.CASACO_LENCO, Tipo.RIFLE_CACADOR, Tipo.CADERNINHO],
	[Tipo.CAPACETE_AQUARIO, Tipo.MACACAO_PRESSURIZADO, Tipo.RIFLE_ESTASE, Tipo.TANQUE_PEIXINHO],
	[Tipo.CABECA_POLVO, Tipo.MANTO_ABISSAL, Tipo.NECRONOMIAU, Tipo.TENTACULO_FOFO],
	[Tipo.ATELIE_CABECA, Tipo.ATELIE_CORPO, Tipo.ATELIE_MAO, Tipo.ATELIE_ACESSORIO],
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
	31, 31, 31, 31, 32, 32, 32, 32, 33, 33, 33, 33, 34, 34, 34, 34, 35, 35, 35, 35, 36, 36, 36, 36,
	37, 37, 37, 37, 38, 38, 38, 38, 39, 39, 39, 39, 40, 40, 40, 40, 41, 41, 41, 41, 42, 42, 42, 42,
	43, 43, 43, 43, 44, 44, 44, 44, 45, 45, 45, 45, 46, 46, 46, 46, 47, 47, 47, 47, 48, 48, 48, 48,
	49, 49, 49, 49, 50, 50, 50, 50, 51, 51, 51, 51, 52, 52, 52, 52, 53, 53, 53, 53, 54, 54, 54, 54,
	55, 55, 55, 55,
]
static var CONJUNTO_COR: Array[Color] = [
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
	Color(0.45, 0.85, 0.35),  # disparamiau
	Color(0.95, 0.88, 0.35),  # milhau
	Color(1.0, 0.72, 0.15),  # giramiau
	Color(0.7, 0.55, 0.35),  # stardew miaulley
	Color(0.45, 0.7, 0.3),  # miaucraft
	Color(0.3, 0.55, 0.55),  # miaulax
	Color(0.2, 0.45, 0.95),  # leonarmiau
	Color(0.6, 0.3, 0.8),  # donatemiau
	Color(0.9, 0.2, 0.2),  # rafamiau
	Color(0.15, 0.6, 1.0),  # rocket miaugue
	Color(0.8, 0.1, 0.15),  # deadmiau
	Color(0.5, 0.45, 0.35),  # meon
	Color(0.55, 0.55, 0.6),  # miau-noir
	Color(0.85, 0.9, 0.95),  # hollowmiau
	Color(0.85, 0.2, 0.3),  # silkmiau
	Color(0.95, 0.65, 0.1),  # super miaujin
	Color(0.7, 0.5, 0.25),  # o arqueólogo
	Color(0.95, 0.3, 0.3),  # treinador de miaumons
	Color(0.2, 0.75, 0.35),  # ranger miau (verde, Green Ranger)
	Color(0.25, 0.7, 0.65),  # miauzilla (verde-água)
	Color(0.35, 0.28, 0.22),  # king-miau
	Color(0.45, 0.3, 0.25),  # arthur miaurgon
	Color(0.2, 0.75, 0.8),  # submiautica
	Color(0.25, 0.5, 0.45),  # catchullu
	Color(0.95, 0.55, 0.85),  # ateliê (muda com as cores escolhidas)
]
## Tipo do bônus numérico de cada fantasia (os 9 primeiros valores são os de Conjunto.CAVALEIRO..MAGO; as novas fantasias usam BONUS_*).
const BONUS_CANTIL := 9      # cura única abaixo de 35% (Super Miau)
const BONUS_CRITICO := 10    # chance de golpe crítico (Arqueiro Miau)
const BONUS_BARREIRA := 11   # anula um golpe a cada N segundos (Mimiau)
const BONUS_CARGA := 12      # recarga do poder mais curta (Jimiau)
const BONUS_TIRO_DUPLO := 13 # chance de atirar duas vezes (Disparamiau)
const BONUS_ESCORREGA := 14  # chance do golpe deixar o alvo lento (Milhau)
const BONUS_AURA_REGEN := 15 # aura de regeneração nos aliados em volta (Giramiau)
const BONUS_SEMENTES := 16   # sementes: cura os aliados ao cair (Stardew Miaulley)
const BONUS_ATORDOA := 17    # chance do golpe atordoar o alvo (Donatemiau)
const BONUS_CHIFRES := 18    # mais dano com menos vida (Rafamiau)
const BONUS_VELOCIDADE := 19 # velocidade de movimento (Rocket Miaugue)
const BONUS_EMBOSCADA := 21  # o 1º golpe em cada inimigo fere mais (Miau-Noir)
const BONUS_ALCANCE := 22    # alcance a mais (Hollowmiau)
const BONUS_CERCO := 23      # golpes ferem em volta (Silkmiau)
const BONUS_EXECUCAO := 24   # mais dano em quem está com pouca vida (Super Miaujin)
const BONUS_ESQUIVA := 25    # chance de esquivar (O Arqueólogo)
const BONUS_CURA_ABATE := 26 # cura ao abater (Treinador de Miaumons)
const BONUS_ESPINHO := 27    # espinho: devolve dano a quem bate de perto (Miauzilla)
const BONUS_FOLEGO := 28     # segundo fôlego: levanta uma vez com parte da vida (Submiautica)
const BONUS_SUSTO := 29      # chance de o golpe assustar o alvo (Catchullu)
const BONUS_APARA := 20      # chance de aparar golpe corpo a corpo com a faca e devolver uma facada (Meon)
const CONJUNTO_MOLDE: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 1, 6, 6, 5, 8, 4, 0, 6, 0, 4, 1, 7, 6, 4, 7, 8,
	BONUS_CANTIL, BONUS_CRITICO, 8, 0, BONUS_BARREIRA, BONUS_CARGA,
	BONUS_TIRO_DUPLO, BONUS_ESCORREGA, BONUS_AURA_REGEN, BONUS_SEMENTES, 3, 1,   # Miaucraft: Circo (explode ao morrer); Miaulax: Guardião (vida)
	2, BONUS_ATORDOA, BONUS_CHIFRES, BONUS_VELOCIDADE, 5, BONUS_APARA,
	BONUS_EMBOSCADA, BONUS_ALCANCE, BONUS_CERCO, BONUS_EXECUCAO, BONUS_ESQUIVA, BONUS_CURA_ABATE,
	6, BONUS_ESPINHO, 4, BONUS_CANTIL, BONUS_FOLEGO, BONUS_SUSTO,
	0]   # a última entrada é o Ateliê (reserva; o bônus real vem de molde_kit). lote 5: Ranger (rapidez do Caubói), King-Miau (dano do Viking)   # Leonarmiau: Rei (aura de dano); Deadmiau: Jardineiro (regeneração)

# ---------- Poder especial da fantasia completa ----------
## Os 16 primeiros são os da primeira leva; os de baixo foram acrescentados na rodada de poderes diversos (valores novos no fim: o save grava a fantasia, não este índice).
enum Poder { RAIO, EXPLOSAO, ATORDOA, CURA, PROTEGE, FRENESI, ATRAVESSA, RAJADA, GELO, EMPURRA, GIRO, DRENO, INVOCA, TELEPORTE, PUXA, ENXAME,
	RAIZ, SAQUE, TROVOADA, CANHAO, MISSEIS, CANCAO, INVESTIDA, FUMACA, FURIA, PISAO, CANTEIRO, TRIAGEM, MARCA, BOLA,
	SALVAMENTO, RICOCHETE, OLHAR, OBJECAO, IMITAR, POQUER,
	TORRE, MANTEIGA, REVIVER, COLHEITA, CONSTRUIR, COCHILO,
	PLANO, DOMO, LOBO, TURBO, ESFORCO, CHUTE,
	APAGAO, ESPIRITO, LACO, KAMEHA, PEDRA, CAPTURA,
	MEGAZORD, SOPRO, BRADO, RECOMPENSA, ESTASE, LOUCURA }
const PODER_TIPO: Array[int] = [Poder.INVESTIDA, Poder.PROTEGE, Poder.FRENESI, Poder.ATORDOA, Poder.FURIA, Poder.CANTEIRO, Poder.SAQUE, Poder.CANHAO, Poder.RAIO,
	Poder.PISAO, Poder.FUMACA, Poder.RAIZ, Poder.EMPURRA, Poder.DRENO, Poder.CANCAO, Poder.TRIAGEM, Poder.BOLA, Poder.MISSEIS, Poder.TROVOADA, Poder.GELO, Poder.MARCA,
	Poder.INVOCA, Poder.TELEPORTE, Poder.PUXA, Poder.ENXAME,
	Poder.SALVAMENTO, Poder.RICOCHETE, Poder.OLHAR, Poder.OBJECAO, Poder.IMITAR, Poder.POQUER,
	Poder.TORRE, Poder.MANTEIGA, Poder.REVIVER, Poder.COLHEITA, Poder.CONSTRUIR, Poder.COCHILO,
	Poder.PLANO, Poder.DOMO, Poder.LOBO, Poder.TURBO, Poder.ESFORCO, Poder.CHUTE,
	Poder.APAGAO, Poder.ESPIRITO, Poder.LACO, Poder.KAMEHA, Poder.PEDRA, Poder.CAPTURA,
	Poder.MEGAZORD, Poder.SOPRO, Poder.BRADO, Poder.RECOMPENSA, Poder.ESTASE, Poder.LOUCURA,
	Poder.RAIO]   # Ateliê: reserva (o poder real vem de conj_do_poder)
## Poderes que o bicho fantasiado NÃO usa (o fantasiado só ganha o bônus de kit).
const PODER_SO_GATO: Array[int] = [Poder.SALVAMENTO, Poder.OBJECAO, Poder.IMITAR, Poder.MANTEIGA, Poder.REVIVER, Poder.CONSTRUIR, Poder.COCHILO, Poder.PLANO, Poder.DOMO, Poder.LOBO,
	Poder.ESPIRITO, Poder.LACO, Poder.KAMEHA, Poder.CAPTURA,
	Poder.MEGAZORD, Poder.SOPRO, Poder.BRADO, Poder.RECOMPENSA, Poder.ESTASE, Poder.LOUCURA]
## Fantasias cujo poder o Imitar não copia (evita laço infinito).
const IMITAR_EXCLUI: Array[int] = [Conjunto.MIMIAU, Conjunto.GIRAMIAU, Conjunto.TREINADOR]
const PODER_NOME: Array[String] = [
	"Carga de lança", "Muralha", "Ordem real", "Buzina", "Fúria",
	"Chuva de pétalas", "Saque rápido", "Bala de canhão", "Relâmpago", "Pisão",
	"Fumaça", "Teia", "Empurrão", "Aperto sombrio", "Canção do tempo",
	"Pizza para todos", "Bola de espinhos", "Salva de mísseis", "Trovoada", "Nevasca",
	"Alvo travado",
	"Clones", "Teletransporte", "Arrastão", "Enxame",
	"Salvamento", "Flecha ricochete", "Olhar da Penitência", "Objeção!", "Imitar", "Mão de pôquer",
	"Torre de ervilha", "Manteiga escorregadia", "Reviver", "Colheita", "Construir", "Cochilo",
	"Plano de ataque", "Domo refletor", "Lobo solitário", "Turbo", "Esforço máximo", "Chute giratório",
	"Modo Noir", "Alma Sombria", "Laço de seda", "Camehamiau!", "Pedra rolante", "Eu escolho você!",
	"Megazord", "Sopro radioativo", "Bater no peito", "Recompensa", "Rifle de estase", "Loucura",
	"Poder do Ateliê",
]
const PODER_DICA: Array[String] = [
	"investe pela fileira, fere quem cruza, derruba o primeiro e fica protegido",
	"o time recebe bem menos dano por uns segundos",
	"o time ataca em dobro por uns segundos",
	"atordoa os inimigos em volta",
	"por uns segundos os golpes ferem em volta e roubam vida",
	"um canteiro cura os aliados dentro e atrasa os inimigos",
	"seis tiros, sempre no inimigo mais fraco",
	"explode o maior bando e queima; devolve blocos ou, com a torre cheia, fere mais",
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
	"repete o último poder; sem nenhum, refaz o Disfarce e cura",
	"saca cartas e joga a melhor mão: quanto melhor, mais dano no bando",
	"planta uma torre de ervilhas que atira sozinha por uns segundos",
	"uma poça de manteiga faz o bando deslizar para o fundo, lento",
	"levanta o aliado caído, sem a marca de nocaute (1x por luta)",
	"planta 3 mudas: viram pimenta que explode, morango que cura, ou murcham",
	"ergue blocos que provocam os bichos e explodem ao cair",
	"dorme e se cura; o ronco adormece os inimigos em volta",
	"o time foca o bicho mais forte e bate mais nele; dois cortes do líder",
	"domo parado devolve os tiros inimigos ao atirador (só rende contra tiro)",
	"os bichos em volta só batem nele, que apanha menos e bate mais forte",
	"atropela em linha, protegido, e deixa um rastro de chamas azuis",
	"regenera e bate mais forte por uns segundos; se cair, levanta e explode",
	"chuta em volta: empurra e atordoa; quem já estava atordoado apanha muito",
	"preto e branco: os bichos erram golpes nele e os tiros dele ferem mais",
	"a Alma vira a Sombra: perfura a fileira, fere muito, deixa lento e cura",
	"liga os 4 bichos mais fortes: o dano de um se espalha pelos outros",
	"carrega parado e solta um feixe que cruza o campo todo",
	"uma pedra rola até a torre e atordoa quem tocar",
	"a bola captura o bicho mais fraco: ferido, vira aliado por uns segundos",
	"liga os aliados perto com escudo e vira um gigante por uns segundos",
	"sopro em cone: o bicho vira radioativo e explode ao cair, contagiando",
	"ruge: os bichos fogem e ele bate mais forte e apanha menos",
	"marca o bicho mais forte: se cair no prazo, o time cura e bate mais",
	"bolha que congela o bando: o dano retido sai de uma vez no fim",
	"os 3 bichos mais fortes enlouquecem e se atacam; o chefe leva tentáculo",
	"o poder que o criador do Ateliê escolheu",
]
## Fantasia cujo poder a fantasia `c` solta: ela mesma, ou (no Ateliê) a escolhida pelo jogador.
## É também o índice do poder nas tabelas por fantasia (nome, dica, PODER_KIT_FORCA e PODER_KIT_INTERVALO).
static func conj_do_poder(c: int) -> int:
	return Atelie.poder_conj() if c == Conjunto.ATELIE else c

## Fantasia cujo bônus de kit a fantasia `c` dá (no Ateliê, a escolhida pelo jogador).
static func conj_do_bonus(c: int) -> int:
	return Atelie.bonus_conj() if c == Conjunto.ATELIE else c

## Tipo do bônus de kit (valor de CONJUNTO_MOLDE) da fantasia `c`.
static func molde_kit(c: int) -> int:
	return CONJUNTO_MOLDE[conj_do_bonus(c)]

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
			extra = Idioma.t("%d%% do dano") % int(round(Balanco.MARCA_CERCO_DANO * n * 100.0))
		Marca.FURO:
			extra = "-%d%%" % int(round(minf(Balanco.MARCA_FURO_MAX, Balanco.MARCA_FURO_REDUCAO * n) * 100.0))
		Marca.BRASA:
			extra = "+%d/s" % int(round(Balanco.MARCA_BRASA_DPS * n))
		Marca.POLVORA:
			extra = "+%d" % int(round(Balanco.MARCA_POLVORA_DANO * n))
	return "%s ×%d: %s (%s)" % [Idioma.t(MARCA_NOME[m]), n, Idioma.t(MARCA_DICA[m]), extra]

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
	match molde_kit(c):
		Conjunto.CAVALEIRO:
			return Idioma.t("+%d de armadura") % int(v)
		Conjunto.GUARDIAO:
			return Idioma.t("+%d%% de vida") % int(round(v * 100.0))
		Conjunto.REI:
			return Idioma.t("aliados por perto: +%d%% de dano") % int(round(v * 100.0))
		Conjunto.CIRCO:
			return Idioma.t("explode ao morrer (+%d)") % int(v)
		Conjunto.VIKING:
			return Idioma.t("+%d%% de dano") % int(round(v * 100.0))
		Conjunto.JARDINEIRO:
			return Idioma.t("regenera +%d de vida por segundo") % int(v)
		Conjunto.CAUBOI:
			return Idioma.t("ataca %d%% mais rápido") % int(round(v * 100.0))
		Conjunto.PIRATA:
			return Idioma.t("golpes devolvem %d%% do dano em vida") % int(round(v * 100.0))
		Conjunto.MAGO:
			return Idioma.t("golpes queimam (+%d/s)") % int(v)
		BONUS_CANTIL:
			return Idioma.t("cantil: cura %d%% da vida uma vez, abaixo de %d%%") % [int(round(v * 100.0)), int(round(Balanco.CANTIL_LIMIAR * 100.0))]
		BONUS_CRITICO:
			return Idioma.t("+%d%% de chance de golpe crítico") % int(round(v * 100.0))
		BONUS_BARREIRA:
			if g == 1 and c == Conjunto.MIMIAU:
				return Idioma.t("Disfarce anula o 1º golpe, atordoa %s s; +%d%% dano; Furioso") % [Simulacao.num(v), int(round(Balanco.DISFARCE_KIT_DANO * 100.0))]
			return Idioma.t("anula um golpe a cada %d s") % int(v)
		BONUS_CARGA:
			return Idioma.t("o poder recarrega %d%% mais depressa") % int(round(v * 100.0))
		BONUS_TIRO_DUPLO:
			return Idioma.t("%d%% de chance de atirar duas vezes") % int(round(v * 100.0))
		BONUS_ESCORREGA:
			return Idioma.t("golpes deixam o alvo lento (%d%% de chance)") % int(round(v * 100.0))
		BONUS_AURA_REGEN:
			return Idioma.t("aliados em volta regeneram +%s de vida por segundo") % Simulacao.num(v)
		BONUS_SEMENTES:
			return Idioma.t("ao cair, cura os aliados em %d%% da vida") % int(round(v * 100.0))
		BONUS_ATORDOA:
			return Idioma.t("golpes atordoam o alvo (%d%% de chance)") % int(round(v * 100.0))
		BONUS_CHIFRES:
			return Idioma.t("mais dano com menos vida (até +%d%%)") % int(round(v * 100.0))
		BONUS_VELOCIDADE:
			return Idioma.t("anda %d%% mais rápido") % int(round(v * 100.0))
		BONUS_APARA:
			return Idioma.t("Apara %d%% dos golpes de perto; tiro na perna atordoa") % int(round(v * 100.0))
		BONUS_EMBOSCADA:
			return Idioma.t("o 1º golpe em cada inimigo fere ×%s") % Simulacao.num(v)
		BONUS_ALCANCE:
			return Idioma.t("+%d de alcance") % int(v)
		BONUS_CERCO:
			return Idioma.t("golpes ferem em volta (%d%% do dano)") % int(round(v * 100.0))
		BONUS_EXECUCAO:
			return Idioma.t("+%d%% de dano em quem tem menos de %d%% de vida") % [int(round(v * 100.0)), int(round(Balanco.EXECUCAO_LIMIAR * 100.0))]
		BONUS_ESQUIVA:
			return Idioma.t("%d%% de chance de esquivar") % int(round(v * 100.0))
		BONUS_CURA_ABATE:
			return Idioma.t("cura %d%% da vida a cada abate") % int(round(v * 100.0))
		BONUS_ESPINHO:
			return Idioma.t("espinhos: devolve %d de dano a quem bate de perto") % int(v)
		BONUS_FOLEGO:
			return Idioma.t("segundo fôlego: levanta uma vez com %d%% da vida") % int(round(v * 100.0))
		BONUS_SUSTO:
			return Idioma.t("golpes assustam o alvo (%d%% de chance)") % int(round(v * 100.0))
	return ""
