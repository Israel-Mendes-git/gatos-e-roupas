class_name IconeDados
extends RefCounted
## Gerado por mede_icones.gd: caixa ocupada pelo desenho em pixel de cada peça (RoupaGato),
## em pixels do gato, relativa à origem do desenho. Refaça depois de mudar os desenhos das roupas.

const CAIXA: Array[Rect2] = [
	Rect2(-2, -8, 10, 9),  # 0 Porrete
	Rect2(-3, -9, 7, 10),  # 1 Estilingue
	Rect2(-1, -4, 6, 6),  # 2 Escudo
	Rect2(-6, -3, 11, 6),  # 3 Colete
	Rect2(-11, -4, 11, 8),  # 4 Capa
	Rect2(-6, -4, 12, 7),  # 5 Espinhos
	Rect2(-5, -3, 10, 5),  # 6 Capacete
	Rect2(-6, -5, 12, 6),  # 7 Chapéu de palha
	Rect2(-5, -1, 10, 7),  # 8 Máscara
	Rect2(-3, -9, 11, 11),  # 9 Lança
	Rect2(0, -11, 5, 12),  # 10 Tocha
	Rect2(-5, -3, 10, 6),  # 11 Avental
	Rect2(-4, -4, 8, 7),  # 12 Barril
	Rect2(-4, -4, 8, 5),  # 13 Coroa
	Rect2(-5, -6, 10, 6),  # 14 Chifres
	Rect2(-1, -11, 5, 12),  # 15 Cetro
	Rect2(-1, -7, 17, 8),  # 16 Regador
	Rect2(-1, -12, 12, 13),  # 17 Sabre
	Rect2(-1, -11, 7, 12),  # 18 Varinha
	Rect2(-5, -6, 10, 6),  # 19 Cartola
	Rect2(-6, -5, 12, 6),  # 20 Chapéu de caubói
	Rect2(-5, -5, 12, 6),  # 21 Chapéu de pirata
	Rect2(-5, -7, 12, 8),  # 22 Chapéu pontudo
	Rect2(-6, -3, 12, 7),  # 23 Pele de urso
	Rect2(-6, -3, 12, 7),  # 24 Poncho
	Rect2(-6, -3, 12, 7),  # 25 Casaco
	Rect2(-10, -4, 13, 10),  # 26 Manto
	Rect2(-3, -4, 7, 4),  # 27 Botas
	Rect2(-3, -5, 6, 4),  # 28 Joelheiras
	Rect2(-9, -14, 11, 15),  # 29 Bandeira
	Rect2(-1, 1, 4, 4),  # 30 Nariz vermelho
	Rect2(-4, -2, 8, 4),  # 31 Colar de dentes
	Rect2(-3, -3, 6, 6),  # 32 Saco de sementes
	Rect2(-4, -2, 7, 6),  # 33 Cantil
	Rect2(-2, -6, 5, 5),  # 34 Gancho
	Rect2(-2, -1, 5, 5),  # 35 Amuleto
	Rect2(-5, -4, 13, 12),  # 36 Boné de encanador
	Rect2(-6, -3, 12, 6),  # 37 Macacão
	Rect2(-3, -9, 11, 9),  # 38 Desentupidor
	Rect2(-3, -3, 6, 6),  # 39 Cogumelo
	Rect2(-5, -4, 10, 10),  # 40 Capuz de morcego
	Rect2(-8, -3, 11, 8),  # 41 Capa de morcego
	Rect2(-4, -5, 9, 6),  # 42 Bumerangue
	Rect2(-3, -3, 6, 6),  # 43 Cinto de utilidades
	Rect2(-5, -1, 10, 8),  # 44 Máscara de teia
	Rect2(-6, -3, 12, 6),  # 45 Colante de aranha
	Rect2(0, -9, 12, 9),  # 46 Lança-teia
	Rect2(-4, -6, 8, 5),  # 47 Aranha de estimação
	Rect2(-5, -2, 10, 8),  # 48 Capuz de monge
	Rect2(-6, -3, 12, 6),  # 49 Túnica
	Rect2(-1, -10, 13, 11),  # 50 Espada de luz
	Rect2(-3, -2, 7, 7),  # 51 Cristal
	Rect2(-6, -3, 12, 11),  # 52 Elmo sombrio
	Rect2(-6, -3, 12, 6),  # 53 Armadura sombria
	Rect2(-1, -10, 13, 11),  # 54 Espada rubra
	Rect2(0, 0, 7, 6),  # 55 Respirador
	Rect2(-9, -5, 14, 9),  # 56 Gorro verde
	Rect2(-6, -3, 12, 6),  # 57 Túnica verde
	Rect2(-1, -11, 14, 12),  # 58 Espada lendária
	Rect2(-3, -1, 7, 5),  # 59 Ocarina
	Rect2(-8, 2, 13, 4),  # 60 Bandana ninja
	Rect2(-8, -4, 13, 8),  # 61 Casco
	Rect2(-1, -4, 8, 10),  # 62 Nunchaku
	Rect2(0, -11, 12, 11),  # 63 Fatia de pizza
	Rect2(-4, -4, 10, 5),  # 64 Topete de ouriço
	Rect2(-6, -4, 12, 8),  # 65 Pelo azul
	Rect2(-3, -9, 6, 5),  # 66 Luvas brancas
	Rect2(-3, -4, 6, 4),  # 67 Tênis vermelhos
	Rect2(-5, -2, 12, 9),  # 68 Capacete de ferro
	Rect2(-6, -3, 12, 7),  # 69 Armadura de ferro
	Rect2(-3, -3, 9, 5),  # 70 Luva repulsora
	Rect2(-3, -1, 6, 4),  # 71 Reator
	Rect2(-8, -6, 12, 8),  # 72 Elmo alado
	Rect2(-8, -4, 11, 8),  # 73 Capa rubra
	Rect2(-1, -10, 11, 10),  # 74 Martelo
	Rect2(-3, -3, 6, 6),  # 75 Cinturão de força
	Rect2(-5, -4, 10, 10),  # 76 Tiara de gelo
	Rect2(-6, -3, 12, 6),  # 77 Vestido de gelo
	Rect2(0, -11, 8, 11),  # 78 Cetro de gelo
	Rect2(-3, -2, 6, 5),  # 79 Floco de neve
	Rect2(-6, -2, 12, 10),  # 80 Capacete bolha
	Rect2(-6, -3, 12, 6),  # 81 Traje espacial
	Rect2(0, -3, 10, 6),  # 82 Laser de pulso
	Rect2(-6, -5, 13, 7),  # 83 Mochila a jato
]
