class_name AtelieArte
extends RefCounted
## Desenho das peças do Ateliê: cada uma delega ao desenho da peça escolhida (RoupaGato) e, enquanto desenha, troca a cor
## (matiz) e põe a estampa por cima. Os filtros ficam em RoupaGato.r e RoupaGato._retangulos, por onde passa todo pixel de roupa.
## Peça pintada pelo jogador (Atelie.pintura) desenha a pintura no lugar da forma.

static var ativo: bool = false
static var _matiz: int = 0
static var _estampa: int = 0
## Fotografando (fotografar): os pixels vão para _foto em vez da tela.
static var _gravando: bool = false
static var _foto: Dictionary = {}
static var _cache_pint: Dictionary = {}   # hash da pintura -> {"frente": [rects, cores], "atras": [...], "caixa": Rect2}

## Desenha a peça do Ateliê `tipo` como a forma escolhida, com a cor e a estampa dela (ou a pintura, se tiver).
static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	var pint: Dictionary = Atelie.pintura(tipo)
	if not pint.is_empty():
		desenhar_pintura(c, pint, f)
		return
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
		4:   # coração (azulejo de 6x5, linhas alternadas deslocadas: cabem dois ou três numa peça pequena)
			var cy: int = posmod(iy, 5)
			var cx: int = posmod(ix + (3 if posmod(floori(iy / 5.0), 2) == 1 else 0), 6)
			const CORACAO: Array[String] = [".#.#..", "#####.", "#####.", ".###..", "..#..."]
			return 2 if CORACAO[cy][cx] == "#" else 0
		5:   # estrela (azulejo de 6x5, deslocado como o coração)
			var sy: int = posmod(iy, 5)
			var sx: int = posmod(ix + (3 if posmod(floori(iy / 5.0), 2) == 1 else 0), 6)
			const ESTRELA: Array[String] = ["..#...", "#####.", ".###..", ".#.#..", "......"]
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
	if _gravando:
		_gravar(x, y, w, h, base)
		return
	var cor_p: Color = cor(base)
	if _estampa <= 0 or cor_p.a < 0.99 or cor_p.v < 0.2:
		c.draw_rect(Rect2(x, y, w + 0.03, h + 0.03), Desenho.b(cor_p, f))
		return
	var escura: Color = Desenho.b(_tom_cor(cor_p, 1), f)
	var clara: Color = Desenho.b(_tom_cor(cor_p, 2), f)
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

## Cor do pixel no tom da estampa: 1 escurece; 2 clareia (em peça muito clara o clarear some: o desenho sai escuro).
static func _tom_cor(cor_p: Color, t: int) -> Color:
	if t == 1:
		return cor_p.darkened(0.38)
	if t == 2:
		return cor_p.lightened(0.5) if cor_p.get_luminance() < 0.62 else cor_p.darkened(0.3)
	return cor_p

# ---------- pintura ----------
## Guarda os pixels de um retângulo (com matiz e estampa) na foto; o que vem depois cobre o que veio antes.
static func _gravar(x: float, y: float, w: float, h: float, base: Color) -> void:
	var cor_p: Color = cor(base)
	if cor_p.a < 0.05:
		return
	var com_estampa: bool = _estampa > 0 and cor_p.a >= 0.99 and cor_p.v >= 0.2
	for iy in range(floori(y + 0.001), ceili(y + h - 0.001)):
		for ix in range(floori(x + 0.001), ceili(x + w - 0.001)):
			_foto[Vector2i(ix, iy)] = _tom_cor(cor_p, tom(ix, iy)) if com_estampa else cor_p

## Os pixels {Vector2i: Color} que a peça do Ateliê `tipo` desenharia com a forma, a cor e a estampa escolhidas
## (sem pintura), na camada `passo` (0 = tudo, 1 = atrás do corpo, 2 = frente; ver RoupaGato.passo).
static func _fotografar_camada(tipo: int, passo: int) -> Dictionary:
	_matiz = Atelie.matiz(tipo)
	_estampa = Atelie.estampa()
	_foto = {}
	ativo = true
	_gravando = true
	var passo0: int = RoupaGato.passo
	RoupaGato.passo = passo
	RoupaGato.desenhar(null, Atelie.forma(tipo), 0.0, 0.0)   # com _gravando nada chega ao CanvasItem
	RoupaGato.passo = passo0
	_gravando = false
	ativo = false
	var r: Dictionary = _foto
	_foto = {}
	return r

## Grade de pintura (Atelie.grade_em_volta) com o desenho atual da forma: o ponto de partida do pintor.
static func fotografar(tipo: int) -> Dictionary:
	if RoupaGato.tem_atras(Atelie.forma(tipo)):
		return Atelie.grade_em_volta(_fotografar_camada(tipo, 2), _fotografar_camada(tipo, 1))
	return Atelie.grade_em_volta(_fotografar_camada(tipo, 0), {})

## Retângulos prontos de uma pintura (linhas juntadas por cor), guardados pelo hash da pintura.
static func _montada(p: Dictionary) -> Dictionary:
	var k: int = p.hash()
	var m: Variant = _cache_pint.get(k)
	if m != null:
		return m
	if _cache_pint.size() > 64:
		_cache_pint.clear()
	var w: int = int(p["w"])
	var h: int = int(p["h"])
	var x0: int = int(p["x"])
	var y0: int = int(p["y"])
	var pal: Array[Color] = []
	for hx in p["pal"]:
		pal.append(Color.html(str(hx)))
	var r: Dictionary = {}
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-(1 << 20), -(1 << 20))
	for camada in ["atras", "frente"]:
		var txt: String = p[camada]
		var rs: Array[Rect2] = []
		var cs := PackedColorArray()
		for iy in h:
			var ix: int = 0
			while ix < w:
				var ch: String = txt[iy * w + ix]
				if ch == ".":
					ix += 1
					continue
				var jx: int = ix + 1
				while jx < w and txt[iy * w + jx] == ch:
					jx += 1
				rs.append(Rect2(x0 + ix, y0 + iy, jx - ix, 1))
				cs.append(pal[Atelie.ALFABETO.find(ch)])
				lo = Vector2i(mini(lo.x, x0 + ix), mini(lo.y, y0 + iy))
				hi = Vector2i(maxi(hi.x, x0 + jx), maxi(hi.y, y0 + iy + 1))
				ix = jx
		r[camada] = [rs, cs]
	r["caixa"] = Rect2(Vector2(lo), Vector2(hi - lo)) if hi.x > lo.x else Rect2(-4, -8, 8, 8)
	_cache_pint[k] = r
	return r

## Desenha a pintura na camada pedida por RoupaGato.passo (0 = as duas, atrás primeiro).
static func desenhar_pintura(c: CanvasItem, p: Dictionary, f: float) -> void:
	var m: Dictionary = _montada(p)
	var camadas: Array = ["atras", "frente"] if RoupaGato.passo == 0 else (["atras"] if RoupaGato.passo == 1 else ["frente"])
	for camada in camadas:
		var rs: Array[Rect2] = m[camada][0]
		var cs: PackedColorArray = m[camada][1]
		for i in rs.size():
			var q: Rect2 = rs[i]
			c.draw_rect(Rect2(q.position.x, q.position.y, q.size.x + 0.03, q.size.y + 0.03), Desenho.b(cs[i], f))

## Caixa (na unidade da peça) do que está pintado: o ícone se enquadra nela.
static func caixa_pintura(p: Dictionary) -> Rect2:
	return _montada(p)["caixa"]
