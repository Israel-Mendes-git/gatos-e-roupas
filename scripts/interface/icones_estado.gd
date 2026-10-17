class_name IconesEstado
extends RefCounted
## Ícones de estado da luta (pixel art 8x8 + contorno escuro = 10x10), um por estado, no mesmo padrão.
## A ordem do enum é a prioridade: controle primeiro, depois dano, depois os bônus.
## Os mesmos ícones aparecem sobre os bichos, na ficha do mouse e na legenda do Fichário.

enum E { ATORDOADO, PRESO, LENTO, MARCADO, QUEIMA, SEM_FOLEGO, OCULTO, PROTEGIDO, DISFARCADO, FRENESI, FURIA, BOLA, CURA, FUGINDO, ABALADO, MAIS }

const TAM := 10           # lado de um ícone no atlas (8 + contorno de 1 px)
const QTD := 15           # estados de verdade (MAIS é só o "…" do excesso)
const SEM_TEMPO := 99.0   # estado sem relógio (dura enquanto a condição valer)

const NOME: Array[String] = ["Atordoado", "Preso na teia", "Lento", "Marcado", "Queimando", "Sem fôlego", "Oculto", "Protegido", "Disfarçado", "Frenesi", "Fúria", "Bola de espinhos", "Curando", "Fugindo", "Abalado", "Mais"]
const CURTO: Array[String] = ["Atordoado", "Preso", "Lento", "Marcado", "Queimando", "Sem fôlego", "Oculto", "Protegido", "Disfarçado", "Frenesi", "Fúria", "Espinhos", "Curando", "Fugindo", "Abalado", "Mais"]
const DICA: Array[String] = [
	"não age e não anda",
	"não anda, mas ataca quem alcançar",
	"anda e ataca mais devagar",
	"recebe mais dano de todos",
	"perde vida a cada segundo",
	"robô sem corda: parado",
	"os inimigos não o escolhem como alvo",
	"escudo: aguenta mais dano",
	"o próximo golpe é anulado e quem bateu fica atordoado",
	"ataca mais rápido",
	"golpes em área e rouba vida",
	"veloz, espinhento e não atordoa",
	"recupera vida no canteiro",
	"corre com um bloco roubado",
	"o líder caiu: dano e velocidade menores",
	"há mais estados nele",
]

# cores das letras do desenho (maiúscula = sombra da mesma cor)
const PALETA := {
	"w": Color("ffffff"), "W": Color("b8c4dc"),
	"y": Color("ffd93a"), "Y": Color("d9921a"),
	"o": Color("ff8a1c"), "O": Color("d2420e"),
	"r": Color("ff3a3a"), "R": Color("a8142a"),
	"c": Color("7fe6ff"), "C": Color("2e9edb"),
	"b": Color("4a7aff"), "B": Color("1f3fa8"),
	"l": Color("c2a8f0"), "L": Color("7c64bc"),
	"g": Color("8c88a4"), "G": Color("54506c"),
	"m": Color("ff7eb0"), "M": Color("c42c72"),
	"x": Color("b6f23a"), "X": Color("62a21a"),
	"n": Color("d29448"), "N": Color("7c4a1e"),
	"s": Color("e6e6ee"), "S": Color("8c8ca0"),
	"v": Color("e82468"), "V": Color("8c1244"),
}
const CONTORNO := Color("140c1c")

const BITS: Array = [
	# ATORDOADO: estrela amarela
	["...yy...", "...yy...", "yyyyyyyy", ".yyyyyY.", "..yyyY..", ".yyyyyY.", ".yyYYyY.", "yY....Yy"],
	# PRESO: teia branca
	["w..ww..w", ".w.ww.w.", "..w..w..", "ww....ww", "ww....ww", "..w..w..", ".w.ww.w.", "w..ww..w"],
	# LENTO: cristal de gelo
	["...cc...", ".c.cc.c.", "..cwwc..", "cccwwccc", "cccwwccc", "..cwwc..", ".c.cc.c.", "...CC..."],
	# MARCADO: mira vermelha
	["...rr...", "..r..r..", ".r....r.", "rr.ww.rr", "rr.ww.rr", ".r....R.", "..R..R..", "...RR..."],
	# QUEIMA: chama
	["....o...", "...oo...", "...oo.o.", "..oooo..", ".ooyyoo.", ".oyyyyo.", ".OyyyyO.", "..OyyO.."],
	# SEM FÔLEGO: zzz lilás
	["llllllll", ".....ll.", "....ll..", "...ll...", "..lL....", ".lL.....", "LLLLLLLL", "........"],
	# OCULTO: nuvem de fumaça
	["........", "...gg...", "..gggg.g", ".gggggg.", "gggggggg", "gGgggGgg", ".GGGGGG.", "........"],
	# PROTEGIDO: escudo azul
	["bbbbbbbb", "bccbbbbb", "bcbbbbbB", "bbbbbbbB", "bbbbbbBB", ".bbbbBB.", "..bBBB..", "...BB..."],
	# DISFARCADO: pano amarelo de carinha riscada
	[".yy..yy.", ".yyyyyy.", "yyyyyyyy", "yNyyyyNy", "yyyyyyyy", "ryyyyyyr", ".yyyyyY.", "..YYYY.."],
	# FRENESI: setas duplas verde-limão
	["x..x....", ".x..x...", "..x..x..", "...x..x.", "...X..X.", "..X..X..", ".X..X...", "X..X...."],
	# FÚRIA: chifres
	["v......v", "vv....vv", "vv....vv", ".vv..vv.", ".vvvvvV.", "..vvvV..", "...VV...", "........"],
	# BOLA DE ESPINHOS: bola prateada com pontas
	["s......s", ".s.ss.s.", "..ssss..", ".ssssSS.", ".ssssSS.", "..sSSS..", ".S.SS.S.", "S......S"],
	# CURA: coração rosa
	[".mm..mm.", "mmmmmmmm", "mwmmmmmm", "mmmmmmmM", ".mmmmmM.", "..mmmM..", "...mM...", "........"],
	# FUGINDO: saco de bloco roubado
	["...nn...", "..nNNn..", "...nn...", "..nnnn..", ".nnnnnN.", ".nnnnnN.", ".nnnnNN.", "..NNNN.."],
	# ABALADO: coroa rachada, escura e caída
	["........", "r..rr..r", "rr.rr.rr", "rRrrrrRr", "rrrrrrrr", "RRRRRRRR", "........", "........"],
	# MAIS: reticências
	["........", "........", "........", "w.w.w...", "w.w.w...", "........", "........", "........"],
]

static var _tex: Dictionary = {}   # escala (int) -> atlas ImageTexture, já com o contorno

## Atlas com os ícones lado a lado, na escala inteira pedida (1 = 10 px por ícone).
static func atlas(escala: int = 1) -> Texture2D:
	if _tex.has(escala):
		return _tex[escala]
	var img := Image.create(TAM * BITS.size(), TAM, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for k in BITS.size():
		var linhas: Array = BITS[k]
		for yy in 8:
			var ln: String = linhas[yy]
			for xx in 8:
				var ch: String = ln[xx]
				if ch != ".":
					img.set_pixel(k * TAM + 1 + xx, 1 + yy, PALETA[ch])
		# contorno de 1 px (8 vizinhos) em volta de tudo que foi pintado
		for yy in TAM:
			for xx in TAM:
				if img.get_pixel(k * TAM + xx, yy).a > 0.0:
					continue
				var perto: bool = false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var px: int = xx + dx
						var py: int = yy + dy
						if px >= 0 and px < TAM and py >= 0 and py < TAM and img.get_pixel(k * TAM + px, py).a > 0.0 and img.get_pixel(k * TAM + px, py) != CONTORNO:
							perto = true
				if perto:
					img.set_pixel(k * TAM + xx, yy, CONTORNO)
	if escala > 1:
		img.resize(img.get_width() * escala, img.get_height() * escala, Image.INTERPOLATE_NEAREST)
	var t: Texture2D = ImageTexture.create_from_image(img)
	_tex[escala] = t
	return t

## Desenha o ícone `id` com o centro em `c` (posição arredondada para o pixel), na escala do atlas.
static func desenhar(ci: CanvasItem, id: int, c: Vector2, escala: int = 1, alfa: float = 1.0) -> void:
	var lado: float = float(TAM * escala)
	var o := Vector2(roundf(c.x - lado * 0.5), roundf(c.y - lado * 0.5))
	ci.draw_texture_rect_region(atlas(escala), Rect2(o, Vector2(lado, lado)), Rect2(id * lado, 0.0, lado, lado), Color(1, 1, 1, alfa))

## Segundos que faltam do estado `id` em `u`: -1 se não está nele, SEM_TEMPO se não tem relógio.
## O estado CURA depende do canteiro e é decidido por `no_canteiro`.
static func tempo(u: Unidade, id: int) -> float:
	match id:
		E.ATORDOADO:
			return u.atordoado_t if u.atordoado_t > 0.0 else -1.0
		E.PRESO:
			return u.preso_t if u.preso_t > 0.0 else -1.0
		E.LENTO:
			if u.frio_t > 0.0:
				return u.frio_t
			return SEM_TEMPO if u.lento < 0.99 else -1.0
		E.MARCADO:
			return u.marcado_t if u.marcado_t > 0.0 else -1.0
		E.QUEIMA:
			return u.queima_t if u.queima_t > 0.0 else -1.0
		E.SEM_FOLEGO:
			return SEM_TEMPO if u.parado else -1.0
		E.OCULTO:
			return u.oculto_t if u.oculto_t > 0.0 else -1.0
		E.PROTEGIDO:
			return u.protegido_t if u.protegido_t > 0.0 else -1.0
		E.DISFARCADO:
			return SEM_TEMPO if u.disfarcado else -1.0
		E.FRENESI:
			return u.frenesi_t if u.frenesi_t > 0.0 else -1.0
		E.FURIA:
			if u.furor_t > 0.0:
				return u.furor_t
			return SEM_TEMPO if u.furia > 0.05 else -1.0
		E.BOLA:
			return u.bola_t if u.bola_t > 0.0 else -1.0
		E.FUGINDO:
			return SEM_TEMPO if u.fugindo else -1.0
		E.ABALADO:
			return u.abalado_t if u.abalado_t > 0.0 else -1.0
	return -1.0

## A unidade está dentro de um canteiro do seu time (cura)?
static func no_canteiro(u: Unidade, zonas: Array) -> bool:
	for zz in zonas:
		var z: Dictionary = zz
		if z.get("tipo", "enxame") != "canteiro" or int(z["eq"]) != u.equipe or float(z["t"]) <= 0.0:
			continue
		var so: Variant = z.get("so", null)
		if so != null and so != u:
			continue
		var dx: float = u.x - float(z["x"])
		var dy: float = u.y - float(z["y"])
		var r: float = float(z["raio"])
		if dx * dx + dy * dy <= r * r:
			return true
	return false

## Preenche `ids` e `tempos` (buffers do chamador, para não alocar) com os estados ativos em ordem de
## prioridade e devolve quantos são.
static func ativos(u: Unidade, zonas: Array, ids: PackedInt32Array, tempos: PackedFloat32Array) -> int:
	var n: int = 0
	for id in QTD:
		var t: float
		if id == E.CURA:
			t = SEM_TEMPO if (not zonas.is_empty() and no_canteiro(u, zonas)) else -1.0
		else:
			t = tempo(u, id)
		if t > 0.0:
			ids[n] = id
			tempos[n] = t
			n += 1
	return n
