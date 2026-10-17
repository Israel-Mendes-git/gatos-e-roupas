class_name AtelieArte
extends RefCounted
## Desenho das peças do Ateliê: cada uma delega ao desenho da peça escolhida (RoupaGato) e, enquanto desenha, troca a cor
## (matiz) e põe a estampa por cima. Os filtros ficam em RoupaGato.r e RoupaGato._retangulos, por onde passa todo pixel de roupa.

static var ativo: bool = false
static var _matiz: int = 0
static var _estampa: int = 0

## Desenha a peça do Ateliê `tipo` como a forma escolhida, com a cor e a estampa dela.
static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	_matiz = Atelie.matiz(tipo)
	_estampa = Atelie.estampa()
	ativo = true
	RoupaGato.desenhar(c, Atelie.forma(tipo), f, anim)
	ativo = false

## Cor do pixel com o matiz da peça: o matiz escolhido troca o da cor (luz e sombra ficam), e cinza, branco e preto não mudam.
static func cor(c: Color) -> Color:
	if _matiz <= 0 or c.s < 0.12:
		return c
	return Color.from_hsv(float(_matiz - 1) / 12.0, clampf(c.s, 0.45, 1.0), c.v, c.a)

## Quanto a estampa muda o pixel (ix, iy) da peça: 0 nada, 1 escurece, 2 clareia.
static func tom(ix: int, iy: int) -> int:
	match _estampa:
		1:   # listras na diagonal
			return 1 if posmod(ix + iy, 4) < 2 else 0
		2:   # bolinhas
			return 2 if posmod(ix, 5) < 2 and posmod(iy, 5) < 2 else 0
		3:   # xadrez
			return 1 if (posmod(ix, 4) < 2) == (posmod(iy, 4) < 2) else 0
		4:   # coração (azulejo de 8x8)
			var cx: int = posmod(ix, 8)
			var cy: int = posmod(iy, 8)
			const CORACAO: Array[String] = ["........", "..#..#..", ".######.", ".######.", "..####..", "...##...", "........", "........"]
			return 2 if CORACAO[cy][cx] == "#" else 0
		5:   # estrela
			var sx: int = posmod(ix, 8)
			var sy: int = posmod(iy, 8)
			const ESTRELA: Array[String] = ["........", "...#....", "...#....", ".#####..", "...#....", "..#.#...", "........", "........"]
			return 2 if ESTRELA[sy][sx] == "#" else 0
		6:   # camuflagem (manchas de 2x2)
			var h: int = posmod((ix / 2) * 7 + (iy / 2) * 13 + ((ix / 2) * (iy / 2)) * 5, 5)
			return 1 if h < 1 else (2 if h == 1 else 0)
		7:   # remendos quadrados de 4x4 com borda
			var bx: int = posmod(ix, 10)
			var by: int = posmod(iy, 10)
			if bx < 4 and by < 4:
				return 2 if (bx == 0 or by == 0 or bx == 3 or by == 3) else 1
	return 0

## Um retângulo de pixels da peça com matiz e estampa (cada pixel de 1 unidade recebe o tom da estampa).
static func rect(c: CanvasItem, x: float, y: float, w: float, h: float, base: Color, f: float) -> void:
	var cor_p: Color = cor(base)
	if _estampa <= 0 or cor_p.a < 0.99 or cor_p.v < 0.2:
		c.draw_rect(Rect2(x, y, w + 0.03, h + 0.03), Desenho.b(cor_p, f))
		return
	var escura: Color = Desenho.b(cor_p.darkened(0.28), f)
	var clara: Color = Desenho.b(cor_p.lightened(0.38), f)
	var normal: Color = Desenho.b(cor_p, f)
	var x0: int = floori(x + 0.001)
	var y0: int = floori(y + 0.001)
	var x1: int = ceili(x + w - 0.001)
	var y1: int = ceili(y + h - 0.001)
	for iy in range(y0, y1):
		var ry: float = maxf(float(iy), y)
		var rh: float = minf(float(iy + 1), y + h) - ry
		var ix: int = x0
		while ix < x1:
			# junta os pixels vizinhos da linha com o mesmo tom num retângulo só
			var t: int = tom(ix, iy)
			var jx: int = ix + 1
			while jx < x1 and tom(jx, iy) == t:
				jx += 1
			var rx: float = maxf(float(ix), x)
			var rw: float = minf(float(jx), x + w) - rx
			c.draw_rect(Rect2(rx, ry, rw + 0.03, rh + 0.03), escura if t == 1 else (clara if t == 2 else normal))
			ix = jx
