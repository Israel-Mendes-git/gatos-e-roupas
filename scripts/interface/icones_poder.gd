class_name IconesPoder
extends RefCounted
## Ícones dos poderes (Pecas.Poder) e alguns ícones de apoio da luta, em pixel art 8x8 + contorno escuro = 10x10,
## no mesmo padrão de IconesEstado (atlas montado uma vez e guardado por escala).
## Também guarda uma fonte de 3x5 (algarismos e poucas letras) para números desenhados na grade da luta:
## tecla do poder sobre o gato, "×N" da prévia da onda, selo AUTO, o "z" do sono e o "!" do aviso.

const TAM := 10           # lado de um ícone no atlas (8 + contorno de 1 px)
const CONTORNO := Color("140c1c")

## Ícones de apoio, depois dos 48 poderes.
const BLOCO := 48         # bloco da torre (contador de blocos)
const PECA := 49          # roupinha (caixa de peças)

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
	"k": Color("4a4660"), "K": Color("2c2840"),
}

# um desenho por valor de Pecas.Poder (mesma ordem do enum) e os de apoio no fim
const BITS: Array = [
	# RAIO: relâmpago
	["....yyyy", "...yyyy.", "..yyyy..", ".yyyyyyy", "....yyY.", "...yyY..", "..yY....", ".Y......"],
	# EXPLOSAO: estouro
	["o..o..o.", ".ooooo..", "ooyyyoo.", ".oywyyoo", "ooyyyyo.", ".ooyyoO.", "O.OooO.O", "...O...."],
	# ATORDOA (Buzina): corneta
	["......y.", ".....yy.", "y...yyy.", "yyyyyyyy", "yyyyyyyY", "Y...YYY.", ".....YY.", "......Y."],
	# CURA: cruz verde
	["..xxxx..", "..xwxx..", "xxxwxxxx", "xwxxxxxX", "xxxxxxxX", "XXxxxXXX", "..xxxX..", "..XXXX.."],
	# PROTEGE (Muralha): muro com ameias
	["ss.ss.ss", "ssssssss", "GGGGGGGG", "sssGssss", "sssGsssS", "GGGGGGGG", "sGsssGss", "SGSSSGSS"],
	# FRENESI (Ordem real): coroa
	["........", "y..yy..y", "yy.yy.yy", "yyyyyyyy", "yryybyry", "yyyyyyyy", "YYYYYYYY", "........"],
	# ATRAVESSA: flecha
	["........", "s....s..", ".s....s.", "nnnnnnss", "NNNNNNSs", ".S....S.", "S....S..", "........"],
	# RAJADA: três tiros
	["........", "oo.yyyy.", "........", ".oo.yyyy", "........", "oo.yyyy.", "........", "........"],
	# GELO (Nevasca): floco de neve
	["...c....", ".c.c.c..", "..ccc...", "cccwccc.", "..ccc...", ".c.c.c..", "...C....", "........"],
	# EMPURRA (Empurrão): luva de boxe
	["....o...", "....oo..", "s.ooooo.", "..oooooo", "s.oooooO", "....oO..", "....O...", "........"],
	# GIRO: redemoinho
	["..ssss..", ".s....s.", "s..ss..s", "s.s..s.s", "s.s....S", "s..S...S", ".S....S.", "..SSSS.."],
	# DRENO (Aperto sombrio): gota de vida numa garra
	["...rr...", "..rrrr..", ".rwrrrr.", ".rrrrrR.", "..rRRR..", "l......l", "lL.ll.Ll", ".LLLLLL."],
	# INVOCA (Clones): duas cabeças de gato
	["l..lw..w", "llllwwww", "lklkwkwk", "llllwwww", ".LL..WW.", "........", "........", "........"],
	# TELEPORTE: portal
	["..llll..", ".l....l.", "l..cc..l", "l.c..c.l", "l.c.cc.l", "l..c...l", ".L....L.", "..LLLL.."],
	# PUXA (Arrastão): ímã
	["ww....ww", "rr....rr", "rr....rr", "rr....rr", "rr....rR", "rrr..rrR", ".rrrrRR.", "..RRRR.."],
	# ENXAME: abelha
	["...ww.ww", "...wWwW.", ".yykyyk.", "yyykyykY", ".yykyyk.", "..YKYK..", "........", "........"],
	# RAIZ (Teia): teia
	["w..w..w.", ".w.w.w..", "..www...", "wwwwwww.", "..www...", ".w.w.w..", "w..w..w.", "........"],
	# SAQUE (Saque rápido): revólver
	["........", ".sssssss", ".sSSSSSS", ".nnS....", ".nnS.S..", "nnn.S...", "nnN.....", "........"],
	# TROVOADA: nuvem com raio
	["..gggg..", ".gggggg.", "gggggggg", "GGGGGGGG", "...yy...", "..yy....", ".yyyy...", "...y...."],
	# CANHAO: bala de canhão com pavio
	[".....oy.", "....n...", "..kkk...", ".kkkkk..", "kkwkkkk.", "kkkkkkK.", ".kkkkK..", "..KKK..."],
	# MISSEIS: foguete
	["...rr...", "..rwwr..", "..wwwW..", "..wbwW..", "..wwwW..", ".rwwwWr.", ".r.yy.R.", "...oo..."],
	# CANCAO (Canção do tempo): ampulheta
	["nnnnnnnn", ".wyyyyw.", "..wyyw..", "...yy...", "...ww...", "..wyyw..", ".wyyyyw.", "NNNNNNNN"],
	# INVESTIDA (Carga de lança): lança com flâmula
	[".......w", "......ws", ".....ss.", "....ss..", ".r.ss...", "..rs....", ".nnr....", "nN......"],
	# FUMACA: fumaça
	["....ggg.", "...ggggg", ".gg.ggG.", "ggggGG..", "gggggg..", ".GGGG...", "........", "........"],
	# FURIA: machado duplo
	["rr.nn.rr", "rrrnnrrr", "rwrnnrrr", "rrrnnrrR", "rR.nn.RR", "...nn...", "...nn...", "...NN..."],
	# PISAO: bota
	["..nnnn..", "..nnnn..", "..nnnn..", "..nnnn..", "..nnnnn.", ".nnnnnnn", "nnnnnnnN", "NNNNNNNN"],
	# CANTEIRO (Chuva de pétalas): flor
	["..m..m..", ".mmmmmm.", "..myym..", ".mmyymm.", "..mmmM..", ".x.x....", "..xx.x..", "...X...."],
	# TRIAGEM (Pizza para todos): fatia de pizza
	["NNNNNNNN", "nnnnnnnn", "yyyyyyyy", ".yryyry.", "..yyyy..", "..yyry..", "...yy...", "...Y...."],
	# MARCA (Alvo travado): mira com cantoneiras
	["rr....rr", "r..rr..r", "...rr...", ".rrwwrr.", ".rrwwrR.", "...rR...", "R..RR..R", "RR....RR"],
	# BOLA (Bola de espinhos): bola azul espinhenta
	["b..bb..b", ".bbbbbb.", ".bcbbbb.", "bbbbbbbb", "bbbbbbBb", ".bbbbBB.", ".bbBBBB.", "B..BB..B"],
	# SALVAMENTO (Super Miau): escudo azul com peito amarelo e capa vermelha
	["r.bbbb.r", "rrbyybrr", "rbbybbbr", ".bbyybb.", ".bbbybb.", "..byyb..", "...bb...", "........"],
	# RICOCHETE (Flecha ricochete): flecha em zigue-zague
	["........", "x......s", "xx....ss", ".xX..s.s", "..xx.s..", "...xxs..", "....xX..", "........"],
	# OLHAR (Olhar da Penitência): caveira em chamas
	["..o.o.o.", "..ooyoo.", ".oowwwoo", ".wkwwkw.", ".wwwwww.", "..wkkw..", "..wwww..", "...ww..."],
	# OBJECAO (Objeção!): balão com exclamação
	["wwwwwwww", "wwwrrwww", "wwwrrwww", "wwwrrwww", "wwwwwwww", "wwwrrwww", "WwwwwwwW", ".WW....."],
	# IMITAR (Mimiau): pano amarelo com carinha riscada
	["..yyyy..", ".yyyyyy.", "yykyykyy", "yyyyyyyy", "yrryyrry", "yyykkyyy", "yYyyyyYy", "Y.Y.Y.Y."],
	# POQUER (Mão de pôquer): carta com copas
	["..sssss.", ".swwwwwS", "swrwrwwS", "swrrrwwS", "swwrwwwS", "swwwwwwS", ".SSSSSS.", "........"],
	# TORRE (Torre de ervilha): ervilha verde com cano
	["..xxxx..", ".xxxxxx.", "xxkxxkxx", "xxxxxxxx", "xxxxsssN", "xxxxsSSN", ".xxxxxX.", "..XXXX.."],
	# MANTEIGA: tablete de manteiga escorregando
	["........", "..yyyyyy", ".ywwwwyY", "yywwwyYY", "yyyyyYYY", "YYYYYYY.", ".w..w...", "........"],
	# REVIVER: girassol com coração de luz
	["y.y.y.y.", ".yyyyyy.", "yyNNNNyy", "yyNkkNyy", "yyNNNNyy", ".yyyyyy.", "...XX...", "..XXXX.."],
	# COLHEITA: pimenta e morango
	["...X....", "..XX..X.", ".rrr.XXX", "rrrrrvvv", "rrRR.vvv", ".RR..vvv", "......vV", "........"],
	# CONSTRUIR: bloco de pedra
	["GGGGGGGG", "Gssssssg", "GsggggsG", "GsgGGgsg", "GsgGGgsG", "GsggggsG", "GgsssssG", "GGGGGGGG"],
	# COCHILO: zzz sobre a barriga
	["..wwww..", "....w...", "...w.ww.", "..wwww..", "bbbbbbbb", "bwwwwwwB", "bwwwwwwB", ".BBBBBB."],
	# PLANO (Plano de ataque): mira azul com o alvo vermelho
	["...bb...", "..b..b..", ".b.bb.b.", "bb.rr.bb", "bb.rr.bb", ".b.bb.b.", "..b..b..", "...bb..."],
	# DOMO (Domo refletor): cúpula de energia com núcleo roxo
	["..cccc..", ".cCCCCc.", "cC....Cc", "cC.ll.Cc", "cC.lL.Cc", "cC....Cc", "CCCCCCCC", "........"],
	# LOBO (Lobo solitário): par de sais
	["r.....r.", "rr...rr.", ".rr.rr..", "..rrr...", "..rrr...", "...R....", "...R....", "...R...."],
	# TURBO: carro azul com chamas
	["........", "...cccc.", "..cCCCCc", "cccccwcc", "cCCCCCCC", "oo.kk.kk", "yo.kk.kk", "........"],
	# ESFORCO (Esforço máximo): máscara vermelha de olhos brancos
	["..rrrr..", ".rrrrrr.", "rwwrrwwr", "rwkrrkwr", "rrrrrrrr", ".rrkkrr.", "..rrrr..", "...RR..."],
	# PARRY (Parry de faca): faca cruzando o golpe
	["......ss", "....ssS.", "...ssS..", "..ssS...", "nnsS....", ".nN.....", "nN......", "........"],
	# BLOCO: bloco de brinquedo da torre
	["yyyyyyyY", "yooooooO", "yowwooOO", "yowoooOO", "yooooOOO", "yooooOOO", "yOOOOOOO", "YOOOOOOO"],
	# PECA: camiseta (caixa de peças)
	[".wwyyww.", "wwwwwwww", "wwwwwwwW", ".wwmmwW.", ".wwmmwW.", ".wwwwwW.", ".wwwwwW.", ".WWWWWW."],
]

# fonte 3x5 (branca; a cor vem do modulate)
const LETRAS := "0123456789AUTOx!z"
const GLIFOS: Array = [
	["www", "w.w", "w.w", "w.w", "www"], [".w.", "ww.", ".w.", ".w.", "www"], ["ww.", "..w", ".w.", "w..", "www"],
	["ww.", "..w", ".w.", "..w", "ww."], ["w.w", "w.w", "www", "..w", "..w"], ["www", "w..", "ww.", "..w", "ww."],
	[".ww", "w..", "www", "w.w", "www"], ["www", "..w", ".w.", ".w.", ".w."], ["www", "w.w", "www", "w.w", "www"],
	["www", "w.w", "www", "..w", "ww."],
	[".w.", "w.w", "www", "w.w", "w.w"], ["w.w", "w.w", "w.w", "w.w", "www"], ["www", ".w.", ".w.", ".w.", ".w."],
	["www", "w.w", "w.w", "w.w", "www"],
	["...", "w.w", ".w.", "w.w", "..."], [".w.", ".w.", ".w.", "...", ".w."], ["...", "www", ".w.", "w..", "www"],
]
const GL_W := 5           # célula de um glifo no atlas (3 + contorno)
const GL_H := 7

static var _tex: Dictionary = {}    # escala -> atlas dos ícones
static var _tex_l: Dictionary = {}  # escala -> atlas da fonte (linha 0 com contorno, linha 1 sem)

static func _contornar(img: Image, x0: int, y0: int, w: int, h: int) -> void:
	for yy in h:
		for xx in w:
			if img.get_pixel(x0 + xx, y0 + yy).a > 0.0:
				continue
			var perto: bool = false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var px: int = xx + dx
					var py: int = yy + dy
					if px >= 0 and px < w and py >= 0 and py < h:
						var cp: Color = img.get_pixel(x0 + px, y0 + py)
						if cp.a > 0.0 and cp != CONTORNO:
							perto = true
			if perto:
				img.set_pixel(x0 + xx, y0 + yy, CONTORNO)

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
		_contornar(img, k * TAM, 0, TAM, TAM)
	if escala > 1:
		img.resize(img.get_width() * escala, img.get_height() * escala, Image.INTERPOLATE_NEAREST)
	var t: Texture2D = ImageTexture.create_from_image(img)
	_tex[escala] = t
	return t

static func atlas_letras(escala: int = 3) -> Texture2D:
	if _tex_l.has(escala):
		return _tex_l[escala]
	var img := Image.create(GL_W * GLIFOS.size(), GL_H * 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for k in GLIFOS.size():
		var linhas: Array = GLIFOS[k]
		for yy in 5:
			var ln: String = linhas[yy]
			for xx in 3:
				if ln[xx] != ".":
					img.set_pixel(k * GL_W + 1 + xx, 1 + yy, Color(1, 1, 1))
					img.set_pixel(k * GL_W + 1 + xx, GL_H + 1 + yy, Color(1, 1, 1))
		_contornar(img, k * GL_W, 0, GL_W, GL_H)
	if escala > 1:
		img.resize(img.get_width() * escala, img.get_height() * escala, Image.INTERPOLATE_NEAREST)
	var t: Texture2D = ImageTexture.create_from_image(img)
	_tex_l[escala] = t
	return t

## Desenha o ícone `id` com o centro em `c`. Com `grade` > 0 o canto é alinhado a essa grade (a da luta é 3).
static func desenhar(ci: CanvasItem, id: int, c: Vector2, escala: int = 2, alfa: float = 1.0, grade: float = 0.0) -> void:
	if id < 0 or id >= BITS.size():
		return
	var lado: float = float(TAM * escala)
	var o := Vector2(roundf(c.x - lado * 0.5), roundf(c.y - lado * 0.5))
	if grade > 0.0:
		o = Vector2(floorf((c.x - lado * 0.5) / grade + 0.5) * grade, floorf((c.y - lado * 0.5) / grade + 0.5) * grade)
	ci.draw_texture_rect_region(atlas(escala), Rect2(o, Vector2(lado, lado)), Rect2(id * lado, 0.0, lado, lado), Color(1, 1, 1, alfa))

## Largura em px de um texto da fonte 3x5 (passo de 4 px de fonte por letra).
static func largura(txt: String, escala: int = 3) -> float:
	return float((txt.length() * 4 + 1) * escala)

## Texto na fonte 3x5. `p` é o canto de cima à esquerda (alinhado à grade `escala`); `contorno` põe a borda escura.
static func texto(ci: CanvasItem, txt: String, p: Vector2, cor: Color, escala: int = 3, contorno: bool = true) -> void:
	var tex: Texture2D = atlas_letras(escala)
	var e: float = float(escala)
	var x: float = floorf(p.x / e) * e
	var y: float = floorf(p.y / e) * e
	var lw: float = GL_W * e
	var lh: float = GL_H * e
	var sy: float = 0.0 if contorno else lh
	for i in txt.length():
		var k: int = LETRAS.find(txt[i])
		if k >= 0:
			ci.draw_texture_rect_region(tex, Rect2(x, y, lw, lh), Rect2(k * lw, sy, lw, lh), cor)
		x += 4.0 * e
