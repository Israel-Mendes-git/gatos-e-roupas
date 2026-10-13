class_name Desenho
extends RefCounted
## Todo o desenho por código: bonecos, peças, torre, ícones.

const COR_ALIADO := Color(0.93, 0.83, 0.62)  # pano cru
const COR_INIMIGO := Color(0.78, 0.38, 0.2)  # laranja-raposa dos contadores
const COR_CHEFE := Color(0.5, 0.46, 0.5)
## Cor do corpo do inimigo por tipo (ordem de Unidade.Tipo): tons de vermelho, forma diferencia
## Cor de identificação de cada tipo (rótulos e faíscas); o corpo usa a cor da espécie.
const COR_TIPO: Array[Color] = [Color(0.72, 0.62, 0.52), Color(0.95, 0.62, 0.22), Color(0.78, 0.3, 0.4), Color(0.56, 0.4, 0.3), Color(0.88, 0.56, 0.74), Color(0.5, 0.75, 0.4), Color(0.95, 0.95, 0.9), Color(0.5, 0.65, 0.9), Color(0.25, 0.22, 0.28)]
const DOURADO :=Color(1.0, 0.82, 0.2)

# Âncoras das peças no boneco (coordenadas locais, pé em 0,0; y negativo é pra cima)
const ANCORAS: Array[Vector2] = [Vector2(0, -49), Vector2(0, -30), Vector2(11, -28), Vector2(-10, -18)]
# Ajuste para centralizar cada peça num ícone
const ICON_OFF: Array[Vector2] = [
	Vector2(6, -9),    # porrete
	Vector2(0, -4),    # estilingue
	Vector2(3, 0),     # escudo
	Vector2(0, 0),     # colete
	Vector2(-8, 2),    # capa
	Vector2(0, -2),    # espinhos
	Vector2(0, -2),    # capacete
	Vector2(0, -8),    # chapéu
	Vector2(0, 0),     # máscara
	Vector2(4, -14),   # lança
	Vector2(2, -9),    # tocha
	Vector2(0, 0),     # avental
	Vector2(0, 0),     # barril
	Vector2(0, -12),   # coroa
	Vector2(0, -12),   # chifres
	# peças novas (15..35): centro visual de cada desenho (acessórios compensam o deslocamento no corpo)
	Vector2(3, -9), Vector2(5, -3), Vector2(4, -14), Vector2(3, -8),       # cetro, regador, sabre, varinha
	Vector2(0, -15), Vector2(0, -11), Vector2(0, -10), Vector2(0, -18),    # cartola, caubói, tricórnio, pontudo
	Vector2(0, -2), Vector2(0, 0), Vector2(0, 1), Vector2(0, 1),           # pele, poncho, casaco, manto
	Vector2(10, 12), Vector2(10, 8), Vector2(-9, -18), Vector2(21, -29),   # botas, joelheiras, bandeira, nariz
	Vector2(10, -15), Vector2(0, -1), Vector2(5, -8), Vector2(3, 6), Vector2(11, -14),  # colar, sementes, cantil, gancho, amuleto
]

const TIJ_COLS := 4
const TIJ_W := 40.0
const TIJ_H := 20.0

static func b(cor: Color, f: float) -> Color:
	if f <= 0.0:
		return cor
	return cor.lerp(Color.WHITE, clampf(f, 0.0, 1.0))

static func resetar(c: CanvasItem) -> void:
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _tr(c: CanvasItem, pos: Vector2, esc: float, dir: float, local: Vector2 = Vector2.ZERO, rot: float = 0.0, extra: float = 1.0, alto: float = 1.0) -> void:
	c.draw_set_transform(pos + Vector2(local.x * dir * esc, local.y * esc), rot * dir, Vector2(esc * dir * extra, esc * extra * alto))

static func texto(c: CanvasItem, txt: String, pos: Vector2, tam: int, cor: Color, largura: float = -1.0, contorno: int = 0) -> void:
	var fonte: Font = ThemeDB.fallback_font
	var alin: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT if largura < 0.0 else HORIZONTAL_ALIGNMENT_CENTER
	if contorno > 0:
		c.draw_string_outline(fonte, pos, txt, alin, largura, tam, contorno, Color(0, 0, 0, 0.85))
	c.draw_string(fonte, pos, txt, alin, largura, tam, cor)

# ------------------------------------------------------------------ formas das peças
static func _arco(cx: float, cy: float, r: float, de: float = PI, ate: float = TAU, n: int = 12) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n + 1):
		var a: float = de + (ate - de) * i / float(n)
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	return pts

## Desenha a peça na origem do transform atual (âncora = 0,0).
## Ajuste para centralizar a peça num ícone, para qualquer tipo.
static func icon_off(tipo: int) -> Vector2:
	if tipo < Pecas.PROPRIAS:
		return ICON_OFF[tipo]
	if tipo < 52:
		return DesenhoFA.off(tipo)
	if tipo < 68:
		return DesenhoFB.off(tipo)
	if tipo >= 84:
		return Vector2.ZERO   # kits do lado de fora só existem em pixel (RoupaGatoE)
	return DesenhoFC.off(tipo)

static func forma(c: CanvasItem, tipo: int, f: float, anim: float = 0.0) -> void:
	if tipo >= Pecas.PROPRIAS:
		# fantasias de referência: cada faixa de tipos tem o seu arquivo
		if tipo < 52:
			DesenhoFA.forma(c, tipo, f, anim)
		elif tipo < 68:
			DesenhoFB.forma(c, tipo, f, anim)
		elif tipo >= 84:
			RoupaGatoE.desenhar(c, tipo, f, anim)
		else:
			DesenhoFC.forma(c, tipo, f, anim)
		return
	if tipo > Pecas.Tipo.CHIFRES:
		_forma_nova(c, tipo, f, anim)
		return
	match tipo:
		Pecas.Tipo.CAPACETE:
			c.draw_colored_polygon(_arco(0, 1, 10.8), b(Color(0.62, 0.68, 0.78), f))
			c.draw_line(Vector2(-12, 1), Vector2(12, 1), b(Color(0.33, 0.38, 0.48), f), 2.6)
			c.draw_line(Vector2(0, -9.5), Vector2(0, 1), b(Color(0.9, 0.93, 1.0), f), 2.0)
			c.draw_rect(Rect2(-1.6, 1, 3.2, 6.5), b(Color(0.4, 0.45, 0.56), f))
		Pecas.Tipo.CHAPEU:
			var brim := PackedVector2Array()
			for i in 16:
				var a: float = TAU * i / 16.0
				brim.append(Vector2(cos(a) * 16.0, sin(a) * 3.6 - 6.0))
			c.draw_colored_polygon(brim, b(Color(0.9, 0.74, 0.3), f))
			c.draw_colored_polygon(_arco(0, -6, 8.5), b(Color(0.97, 0.84, 0.4), f))
			c.draw_line(Vector2(-8.5, -7), Vector2(8.5, -7), b(Color(0.8, 0.2, 0.2), f), 2.6)
		Pecas.Tipo.MASCARA:
			c.draw_circle(Vector2.ZERO, 9.8, b(Color(0.5, 0.18, 0.62), f))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-7, -3.5), Vector2(-1.5, -1), Vector2(-1.5, 1.5), Vector2(-7.5, -0.5)]), b(Color(1, 1, 1), f))
			c.draw_colored_polygon(PackedVector2Array([Vector2(7, -3.5), Vector2(1.5, -1), Vector2(1.5, 1.5), Vector2(7.5, -0.5)]), b(Color(1, 1, 1), f))
			c.draw_line(Vector2(0, -9.5), Vector2(0, -4), b(DOURADO, f), 2.2)
			c.draw_line(Vector2(-4, 5.5), Vector2(4, 5.5), b(Color(0.95, 0.9, 1.0), f), 1.6)
		Pecas.Tipo.COLETE:
			c.draw_colored_polygon(PackedVector2Array([Vector2(-11, -11), Vector2(11, -11), Vector2(10, 11), Vector2(-10, 11)]), b(Color(0.2, 0.55, 0.32), f))
			c.draw_line(Vector2(0, -11), Vector2(0, 11), b(Color(0.1, 0.32, 0.18), f), 2.0)
			c.draw_rect(Rect2(-9, 2, 6, 6), b(Color(0.14, 0.4, 0.22), f))
			c.draw_rect(Rect2(3, 2, 6, 6), b(Color(0.14, 0.4, 0.22), f))
			c.draw_circle(Vector2(-2.5, -4), 1.4, b(DOURADO, f))
			c.draw_circle(Vector2(2.5, -4), 1.4, b(DOURADO, f))
		Pecas.Tipo.CAPA:
			var fl: float = sin(anim * 0.7) * 2.5
			c.draw_colored_polygon(PackedVector2Array([Vector2(1, -11), Vector2(-5, -11), Vector2(-21 - fl, 12), Vector2(-14, 17), Vector2(-8, 13), Vector2(-2, 18 + fl * 0.4), Vector2(3, 8)]), b(Color(0.85, 0.15, 0.22), f))
			c.draw_polyline(PackedVector2Array([Vector2(-4, -8), Vector2(-14 - fl * 0.5, 10)]), b(Color(0.55, 0.05, 0.12), f), 1.6)
			c.draw_circle(Vector2(0, -11), 2.8, b(DOURADO, f))
		Pecas.Tipo.ESPINHOS:
			c.draw_rect(Rect2(-6.5, -11, 13, 22), b(Color(0.35, 0.25, 0.2), f))
			var aco: Color = b(Color(0.86, 0.88, 0.92), f)
			for y in [-7.0, 0.0, 7.0]:
				c.draw_colored_polygon(PackedVector2Array([Vector2(-6.5, y - 3.5), Vector2(-6.5, y + 3.5), Vector2(-15, y)]), aco)
				c.draw_colored_polygon(PackedVector2Array([Vector2(6.5, y - 3.5), Vector2(6.5, y + 3.5), Vector2(15, y)]), aco)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-3.5, -11), Vector2(3.5, -11), Vector2(0, -18)]), aco)
		Pecas.Tipo.PORRETE:
			c.draw_line(Vector2(0, 5), Vector2(5, -13), b(Color(0.75, 0.52, 0.26), f), 3.6)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-0.5, -11), Vector2(8.5, -9), Vector2(13.5, -18), Vector2(9, -27), Vector2(0.5, -26), Vector2(-2, -17)]), b(Color(0.5, 0.29, 0.12), f))
			c.draw_circle(Vector2(4, -17), 1.5, b(Color(0.9, 0.85, 0.7), f))
			c.draw_circle(Vector2(9, -20), 1.5, b(Color(0.9, 0.85, 0.7), f))
			c.draw_circle(Vector2(5.5, -23), 1.5, b(Color(0.9, 0.85, 0.7), f))
		Pecas.Tipo.ESTILINGUE:
			var m: Color = b(Color(0.62, 0.4, 0.18), f)
			c.draw_line(Vector2(0, 7), Vector2(0, -3), m, 3.4)
			c.draw_line(Vector2(0, -3), Vector2(-7, -15), m, 3.0)
			c.draw_line(Vector2(0, -3), Vector2(7, -15), m, 3.0)
			c.draw_polyline(PackedVector2Array([Vector2(-7, -15), Vector2(0, -9), Vector2(7, -15)]), b(Color(0.85, 0.15, 0.15), f), 1.8)
			c.draw_circle(Vector2(0, -9.5), 2.8, b(Color(0.6, 0.62, 0.66), f))
		Pecas.Tipo.LANCA:
			c.draw_line(Vector2(-1, 16), Vector2(7, -30), b(Color(0.72, 0.5, 0.25), f), 2.8)
			c.draw_colored_polygon(PackedVector2Array([Vector2(3.2, -28.5), Vector2(10.8, -30), Vector2(9.5, -45)]), b(Color(0.88, 0.92, 0.97), f))
			c.draw_line(Vector2(7, -30), Vector2(9.2, -43), b(Color(0.45, 0.5, 0.6), f), 1.2)
			c.draw_line(Vector2(2.5, -24), Vector2(11, -26), b(Color(0.85, 0.15, 0.2), f), 3.0)
		Pecas.Tipo.TOCHA:
			var fl2: float = sin(anim * 0.9) * 1.6
			c.draw_line(Vector2(-1, 9), Vector2(2, -8), b(Color(0.5, 0.32, 0.16), f), 3.6)
			c.draw_circle(Vector2(2, -9), 4.2, b(Color(0.25, 0.15, 0.1), f))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-4, -11), Vector2(-5 + fl2, -20), Vector2(2 + fl2 * 1.5, -30), Vector2(8 - fl2, -20), Vector2(8, -11), Vector2(2, -8)]), b(Color(1.0, 0.45, 0.08), f))
			c.draw_colored_polygon(PackedVector2Array([Vector2(-1, -11), Vector2(0, -18), Vector2(2 + fl2, -24), Vector2(5, -18), Vector2(5, -11)]), b(Color(1.0, 0.9, 0.3), f))
		Pecas.Tipo.AVENTAL:
			c.draw_colored_polygon(PackedVector2Array([Vector2(-6, -12), Vector2(6, -12), Vector2(12, 12), Vector2(-12, 12)]), b(Color(0.96, 0.95, 0.9), f))
			c.draw_line(Vector2(-6, -12), Vector2(-9, -17), b(Color(0.6, 0.6, 0.65), f), 1.4)
			c.draw_line(Vector2(6, -12), Vector2(9, -17), b(Color(0.6, 0.6, 0.65), f), 1.4)
			c.draw_rect(Rect2(-2.2, -7, 4.4, 14), b(Color(0.15, 0.78, 0.35), f))
			c.draw_rect(Rect2(-7, -2.2, 14, 4.4), b(Color(0.15, 0.78, 0.35), f))
			c.draw_line(Vector2(-12, 12), Vector2(12, 12), b(Color(0.7, 0.7, 0.72), f), 1.6)
		Pecas.Tipo.BARRIL:
			c.draw_colored_polygon(PackedVector2Array([Vector2(-8, -13), Vector2(8, -13), Vector2(12, -6), Vector2(12, 6), Vector2(8, 13), Vector2(-8, 13), Vector2(-12, 6), Vector2(-12, -6)]), b(Color(0.58, 0.32, 0.14), f))
			c.draw_line(Vector2(-11.5, -6), Vector2(11.5, -6), b(Color(0.12, 0.1, 0.1), f), 2.4)
			c.draw_line(Vector2(-11.5, 6), Vector2(11.5, 6), b(Color(0.12, 0.1, 0.1), f), 2.4)
			c.draw_circle(Vector2(0, 0), 3.6, b(Color(0.9, 0.2, 0.15), f))
			c.draw_line(Vector2(2, -13), Vector2(6, -19), b(Color(0.3, 0.25, 0.2), f), 1.6)
			c.draw_circle(Vector2(6.5, -19.5), 2.4, b(Color(1.0, 0.8, 0.2), f))
		Pecas.Tipo.COROA:
			var ouro: Color = b(Color(1.0, 0.8, 0.15), f)
			var contorno: PackedVector2Array = PackedVector2Array([Vector2(-9, -6), Vector2(-10, -19), Vector2(-4.5, -12), Vector2(0, -21), Vector2(4.5, -12), Vector2(10, -19), Vector2(9, -6)])
			c.draw_colored_polygon(contorno, ouro)
			contorno.append(Vector2(-9, -6))
			c.draw_polyline(contorno, b(Color(0.6, 0.4, 0.05), f), 1.4)
			c.draw_circle(Vector2(0, -10), 2.2, b(Color(0.9, 0.1, 0.2), f))
			c.draw_circle(Vector2(-10, -19), 1.5, b(Color(1, 1, 1), f))
			c.draw_circle(Vector2(10, -19), 1.5, b(Color(1, 1, 1), f))
			c.draw_circle(Vector2(0, -21), 1.5, b(Color(1, 1, 1), f))
		Pecas.Tipo.CHIFRES:
			var osso: Color = b(Color(0.95, 0.9, 0.75), f)
			var borda: Color = b(Color(0.3, 0.18, 0.1), f)
			for sx in [-1.0, 1.0]:
				var pts := PackedVector2Array([Vector2(6 * sx, -5), Vector2(12 * sx, -7), Vector2(15 * sx, -13), Vector2(12 * sx, -21)])
				c.draw_polyline(pts, borda, 6.0)
				c.draw_polyline(pts, osso, 3.4)
			c.draw_line(Vector2(-7, -5), Vector2(7, -5), b(Color(0.7, 0.1, 0.1), f), 2.4)
		Pecas.Tipo.ESCUDO:
			c.draw_circle(Vector2(3, 0), 12, b(Color(0.22, 0.42, 0.88), f))
			c.draw_arc(Vector2(3, 0), 11.5, 0.0, TAU, 20, b(Color(0.82, 0.86, 0.93), f), 2.6)
			c.draw_line(Vector2(3, -10), Vector2(3, 10), b(Color(0.85, 0.9, 1.0), f), 1.4)
			c.draw_line(Vector2(-7, 0), Vector2(13, 0), b(Color(0.85, 0.9, 1.0), f), 1.4)
			c.draw_circle(Vector2(3, 0), 3.4, b(DOURADO, f))

## Polígono chapado com contorno escuro (cor base escurecida).
static func _pol(c: CanvasItem, pts: PackedVector2Array, cor: Color, f: float, larg: float = 1.3) -> void:
	c.draw_colored_polygon(pts, b(cor, f))
	var l := PackedVector2Array(pts)
	l.append(pts[0])
	c.draw_polyline(l, b(cor.darkened(0.55), f), larg)

static func _elipse(cx: float, cy: float, rx: float, ry: float, n: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a: float = TAU * i / float(n)
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return pts

static func _estrela_p(c: CanvasItem, p: Vector2, r: float, cor: Color, contorno: bool = true) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var rr: float = r if k % 2 == 0 else r * 0.45
		var a: float = -PI * 0.5 + k * PI / 5.0
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	c.draw_colored_polygon(pts, cor)
	if contorno:
		var l := PackedVector2Array(pts)
		l.append(pts[0])
		c.draw_polyline(l, cor.darkened(0.5), 1.0)

## Peças 15..35 (fantasias novas). Origem = âncora do espaço; acessórios ficam deslocados
## para o lugar certo do corpo (botas nos pés, nariz no rosto...) e ICON_OFF compensa.
static func _forma_nova(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	match tipo:
		Pecas.Tipo.CETRO:
			c.draw_line(Vector2(-1, 9), Vector2(3, -17), b(Color(0.4, 0.24, 0.05), f), 5.2)
			c.draw_line(Vector2(-1, 9), Vector2(3, -17), b(Color(1.0, 0.8, 0.25), f), 3.0)
			c.draw_line(Vector2(-3, -2), Vector2(3, -1), b(Color(1.0, 0.8, 0.25), f), 3.0)
			c.draw_circle(Vector2(3.4, -22), 6.4, b(Color(0.4, 0.24, 0.05), f))
			c.draw_circle(Vector2(3.4, -22), 5.2, b(Color(1.0, 0.82, 0.25), f))
			c.draw_circle(Vector2(3.4, -22), 2.9, b(Color(0.9, 0.1, 0.2), f))
			c.draw_circle(Vector2(2.6, -23), 0.9, b(Color.WHITE, f))
			for px in [-4.0, 11.0]:
				c.draw_circle(Vector2(3.4 + (px - 3.4) * 0.9, -25), 1.6, b(Color(1, 1, 1), f))
		Pecas.Tipo.REGADOR:
			var verde: Color = Color(0.4, 0.74, 0.3)
			c.draw_arc(Vector2(-8, 0), 5.0, PI * 0.5, PI * 1.5, 8, b(verde.darkened(0.5), f), 3.4)
			c.draw_arc(Vector2(-8, 0), 5.0, PI * 0.5, PI * 1.5, 8, b(verde.lightened(0.1), f), 1.8)
			c.draw_line(Vector2(6, 1), Vector2(17, -11), b(verde.darkened(0.5), f), 5.0)
			c.draw_line(Vector2(6, 1), Vector2(17, -11), b(Color(0.7, 0.8, 0.7), f), 2.8)
			_pol(c, PackedVector2Array([Vector2(-7, -6), Vector2(7, -6), Vector2(8.5, 7), Vector2(-8.5, 7)]), verde, f)
			c.draw_rect(Rect2(-7, -6, 14, 3), b(verde.lightened(0.3), f))
			c.draw_line(Vector2(-8, 1), Vector2(8, 1), b(verde.darkened(0.3), f), 1.2)
			_pol(c, PackedVector2Array([Vector2(14, -15), Vector2(21, -12), Vector2(19, -7), Vector2(13, -10)]), Color(0.75, 0.8, 0.75), f)
			for k in 3:
				var fr: float = fposmod(t * 1.4 + k * 0.33, 1.0)
				c.draw_circle(Vector2(18.5 + k * 1.6 - 1.5, -6 + fr * 14.0), 1.3, Color(0.5, 0.8, 1.0, 1.0 - fr))
		Pecas.Tipo.SABRE:
			c.draw_line(Vector2(0, 9), Vector2(0, 1), b(Color(0.3, 0.17, 0.08), f), 4.0)
			c.draw_circle(Vector2(0, 10), 2.2, b(Color(0.95, 0.75, 0.2), f))
			_pol(c, PackedVector2Array([Vector2(-1.8, -1), Vector2(0.5, -12), Vector2(4, -22), Vector2(9, -30), Vector2(14, -34), Vector2(12.5, -24), Vector2(8, -13), Vector2(3.8, -1)]), Color(0.86, 0.9, 0.97), f)
			c.draw_polyline(PackedVector2Array([Vector2(1, -3), Vector2(3, -14), Vector2(7, -24), Vector2(12, -32)]), b(Color(1, 1, 1), f), 0.9)
			c.draw_arc(Vector2(1, -1), 6.0, PI * 1.05, PI * 1.95, 8, b(Color(0.95, 0.75, 0.2), f), 2.4)
		Pecas.Tipo.VARINHA:
			c.draw_line(Vector2(-1, 9), Vector2(6, -15), b(Color(0.2, 0.1, 0.3), f), 4.6)
			c.draw_line(Vector2(-1, 9), Vector2(6, -15), b(Color(0.38, 0.22, 0.55), f), 2.6)
			c.draw_line(Vector2(3.2, -3), Vector2(4.3, -7), b(Color(1.0, 0.85, 0.3), f), 3.0)
			_estrela_p(c, Vector2(7, -21), 7.0, b(Color(1.0, 0.85, 0.3), f))
			var sp: float = 0.5 + 0.5 * sin(t * 6.0)
			c.draw_line(Vector2(7 + 8, -27), Vector2(7 + 8, -27) + Vector2(0, 4) * sp, b(Color.WHITE, f), 1.2)
			c.draw_circle(Vector2(-2, -24), 1.2 + sp, Color(1, 0.95, 0.6, 0.8))
			c.draw_circle(Vector2(16, -15), 1.0 + (1.0 - sp), Color(1, 0.95, 0.6, 0.8))
		Pecas.Tipo.CARTOLA:
			var verm: Color = Color(0.88, 0.2, 0.25)
			_pol(c, _elipse(0, -7, 15, 3.4), verm.darkened(0.15), f)
			_pol(c, PackedVector2Array([Vector2(-8.5, -8), Vector2(8.5, -8), Vector2(7.5, -26), Vector2(-7.5, -26)]), verm, f)
			c.draw_colored_polygon(_elipse(0, -26, 7.5, 2.3), b(verm.lightened(0.25), f))
			c.draw_rect(Rect2(-8.3, -14, 16.6, 4.6), b(Color(1.0, 0.85, 0.25), f))
			_estrela_p(c, Vector2(0, -11.7), 2.6, b(Color(0.9, 0.2, 0.25), f), false)
			c.draw_line(Vector2(-6.5, -22), Vector2(-6, -16), b(Color(1, 1, 1, 0.35), f), 1.6)
		Pecas.Tipo.CAUBOI:
			var bege: Color = Color(0.8, 0.54, 0.26)
			_pol(c, PackedVector2Array([Vector2(-8, -6), Vector2(-9, -15), Vector2(-4, -19), Vector2(0, -15.5), Vector2(4, -19), Vector2(9, -15), Vector2(8, -6)]), bege, f)
			c.draw_line(Vector2(-8.6, -9), Vector2(8.6, -9), b(Color(0.45, 0.15, 0.1), f), 3.0)
			_pol(c, PackedVector2Array([Vector2(-20, -12), Vector2(-14, -4), Vector2(-6, -2), Vector2(6, -2), Vector2(14, -4), Vector2(20, -12), Vector2(13, -7), Vector2(0, -6), Vector2(-13, -7)]), bege.darkened(0.2), f)
		Pecas.Tipo.TRICORNIO:
			var azul: Color = Color(0.15, 0.2, 0.34)
			var ouro: Color = Color(0.92, 0.76, 0.25)
			_pol(c, PackedVector2Array([Vector2(-18, -3), Vector2(-12, -14), Vector2(-4, -12), Vector2(0, -18), Vector2(4, -12), Vector2(12, -14), Vector2(18, -3), Vector2(0, -5.5)]), azul, f)
			c.draw_polyline(PackedVector2Array([Vector2(-18, -3), Vector2(0, -5.5), Vector2(18, -3)]), b(ouro, f), 1.8)
			c.draw_circle(Vector2(0, -11), 3.8, b(Color(0.95, 0.95, 0.9), f))
			c.draw_rect(Rect2(-2, -8.5, 4, 3), b(Color(0.95, 0.95, 0.9), f))
			c.draw_circle(Vector2(-1.4, -11.4), 0.9, b(Color(0.1, 0.1, 0.12), f))
			c.draw_circle(Vector2(1.4, -11.4), 0.9, b(Color(0.1, 0.1, 0.12), f))
		Pecas.Tipo.PONTUDO:
			var rox: Color = Color(0.5, 0.3, 0.82)
			_pol(c, _elipse(0, -6, 15, 3.5), rox.darkened(0.2), f)
			_pol(c, PackedVector2Array([Vector2(-12, -6), Vector2(12, -6), Vector2(5, -20), Vector2(11, -33), Vector2(-1, -25), Vector2(-6, -15)]), rox, f)
			c.draw_polyline(PackedVector2Array([Vector2(-11, -8), Vector2(11, -8)]), b(Color(1.0, 0.85, 0.3), f), 2.6)
			_estrela_p(c, Vector2(0, -15), 2.2, b(Color(1.0, 0.9, 0.5), f), false)
			c.draw_circle(Vector2(4, -23), 1.1, b(Color(1, 1, 1), f))
		Pecas.Tipo.PELE:
			var pelo: Color = Color(0.46, 0.3, 0.18)
			_pol(c, PackedVector2Array([Vector2(-13, -11), Vector2(-5, -12), Vector2(5, -12), Vector2(13, -11), Vector2(15, -3), Vector2(12, 0), Vector2(10, 5), Vector2(6, 1), Vector2(3, 6), Vector2(0, 1), Vector2(-4, 6), Vector2(-7, 1), Vector2(-10, 5), Vector2(-12, 0), Vector2(-15, -3)]), pelo, f)
			for x in [-9.0, -3.0, 4.0, 10.0]:
				c.draw_line(Vector2(x, -8), Vector2(x + 1, -2), b(pelo.lightened(0.25), f), 1.4)
			c.draw_circle(Vector2(0, -9), 4.5, b(Color(0.2, 0.12, 0.08), f))
			for x2 in [-12.0, 12.0]:
				for k in 3:
					c.draw_line(Vector2(x2 + (k - 1) * 2.0, 1), Vector2(x2 + (k - 1) * 2.4, 5), b(Color(0.95, 0.92, 0.8), f), 1.3)
		Pecas.Tipo.PONCHO:
			var lar: Color = Color(0.9, 0.55, 0.25)
			_pol(c, PackedVector2Array([Vector2(-5, -11), Vector2(5, -11), Vector2(15, 6), Vector2(15, 11), Vector2(-15, 11), Vector2(-15, 6)]), lar, f)
			for yy in [-1.0, 3.0, 7.0]:
				var hw: float = 5.0 + (yy + 11.0) * 0.588 - 1.0
				c.draw_line(Vector2(-hw, yy), Vector2(hw, yy), b(Color(0.72, 0.2, 0.15) if int(yy) % 8 != 3 else Color(0.98, 0.9, 0.7), f), 2.0)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-4, -11), Vector2(4, -11), Vector2(0, -4)]), b(Color(0.25, 0.12, 0.08), f))
			for x in range(-14, 15, 4):
				c.draw_line(Vector2(x, 11), Vector2(x, 14.5), b(Color(0.98, 0.9, 0.7), f), 1.3)
		Pecas.Tipo.CASACO:
			var az: Color = Color(0.2, 0.34, 0.7)
			_pol(c, PackedVector2Array([Vector2(-10.5, -11), Vector2(10.5, -11), Vector2(11.5, 13), Vector2(-11.5, 13)]), az, f)
			c.draw_line(Vector2(0, -3), Vector2(0, 13), b(az.darkened(0.5), f), 1.4)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-1, -11), Vector2(-8, -11), Vector2(-3.5, -1)]), b(Color(0.92, 0.9, 0.8), f))
			c.draw_colored_polygon(PackedVector2Array([Vector2(1, -11), Vector2(8, -11), Vector2(3.5, -1)]), b(Color(0.92, 0.9, 0.8), f))
			c.draw_line(Vector2(-11, 5), Vector2(11, 5), b(Color(0.1, 0.08, 0.1), f), 2.4)
			c.draw_rect(Rect2(-2, 3, 4, 4), b(Color(0.95, 0.78, 0.25), f))
			for y in [-5.0, 9.0]:
				c.draw_circle(Vector2(4.5, y), 1.3, b(Color(0.95, 0.78, 0.25), f))
		Pecas.Tipo.MANTO:
			var rox2: Color = Color(0.46, 0.26, 0.7)
			_pol(c, PackedVector2Array([Vector2(-9, -11), Vector2(9, -11), Vector2(15, 13), Vector2(8, 10), Vector2(0, 14), Vector2(-8, 10), Vector2(-15, 13)]), rox2, f)
			c.draw_polyline(PackedVector2Array([Vector2(-3, -9), Vector2(-5, 3), Vector2(-4, 11)]), b(rox2.darkened(0.4), f), 1.3)
			c.draw_polyline(PackedVector2Array([Vector2(3, -9), Vector2(5, 3), Vector2(4, 11)]), b(rox2.darkened(0.4), f), 1.3)
			c.draw_circle(Vector2(0, -10), 2.9, b(Color(1.0, 0.82, 0.25), f))
			for sp in [Vector2(-9, 4), Vector2(8, -2), Vector2(10, 8), Vector2(-2, 8)]:
				_estrela_p(c, sp, 1.9, b(Color(1.0, 0.92, 0.55), f), false)
		Pecas.Tipo.BOTAS:
			var aco: Color = Color(0.5, 0.57, 0.7)
			for px in [5.5, 14.5]:
				_pol(c, PackedVector2Array([Vector2(px - 3.5, 6.5), Vector2(px + 3.5, 6.5), Vector2(px + 3.5, 13.5), Vector2(px + 8.5, 14.5), Vector2(px + 8.5, 18), Vector2(px - 3.5, 18)]), aco, f)
				c.draw_rect(Rect2(px - 4, 6.5, 8, 2.6), b(aco.lightened(0.35), f))
				c.draw_rect(Rect2(px - 3.5, 17, 12, 1.6), b(Color(0.15, 0.15, 0.2), f))
		Pecas.Tipo.JOELHEIRAS:
			var vd: Color = Color(0.35, 0.72, 0.55)
			for px in [5.5, 14.5]:
				c.draw_circle(Vector2(px, 8), 5.6, b(vd.darkened(0.55), f))
				c.draw_circle(Vector2(px, 8), 4.4, b(vd, f))
				c.draw_circle(Vector2(px - 1.0, 7.0), 1.7, b(vd.lightened(0.5), f))
				c.draw_line(Vector2(px - 5, 8), Vector2(px + 5, 8), b(vd.darkened(0.4), f), 1.0)
		Pecas.Tipo.BANDEIRA:
			var fl: float = sin(t * 3.0) * 1.8
			c.draw_line(Vector2(-2, 8), Vector2(-2, -44), b(Color(0.35, 0.22, 0.1), f), 2.4)
			c.draw_circle(Vector2(-2, -45), 2.2, b(Color(1.0, 0.82, 0.25), f))
			_pol(c, PackedVector2Array([Vector2(-2, -43), Vector2(-21 - fl, -38), Vector2(-17, -34.5), Vector2(-21 + fl, -31), Vector2(-2, -27)]), Color(0.86, 0.15, 0.2), f)
			_estrela_p(c, Vector2(-9, -35), 2.8, b(Color(1.0, 0.85, 0.3), f), false)
		Pecas.Tipo.NARIZ:
			c.draw_circle(Vector2(21, -29.5), 5.6, b(Color(0.4, 0.04, 0.06), f))
			c.draw_circle(Vector2(21, -29.5), 4.5, b(Color(0.95, 0.15, 0.15), f))
			c.draw_circle(Vector2(19.8, -31), 1.4, b(Color(1, 0.85, 0.85), f))
		Pecas.Tipo.COLAR:
			c.draw_arc(Vector2(10, -23), 8.5, PI * 0.12, PI * 0.88, 10, b(Color(0.3, 0.18, 0.1), f), 1.6)
			for k in 5:
				var a: float = PI * (0.18 + 0.16 * k)
				var pb: Vector2 = Vector2(10, -23) + Vector2(cos(a), sin(a)) * 8.5
				var nrm: Vector2 = Vector2(cos(a), sin(a))
				var tg: Vector2 = Vector2(-nrm.y, nrm.x)
				c.draw_colored_polygon(PackedVector2Array([pb - tg * 2.3, pb + tg * 2.3, pb + nrm * 6.0]), b(Color(0.96, 0.92, 0.78), f))
				c.draw_line(pb, pb + nrm * 5.5, b(Color(0.5, 0.4, 0.3), f), 0.7)
		Pecas.Tipo.SEMENTES:
			var jt: Color = Color(0.78, 0.62, 0.36)
			_pol(c, PackedVector2Array([Vector2(-3, -9), Vector2(3, -9), Vector2(8, -3), Vector2(8, 5), Vector2(0, 9), Vector2(-8, 5), Vector2(-8, -3)]), jt, f)
			c.draw_line(Vector2(-4, -8), Vector2(4, -8), b(Color(0.7, 0.2, 0.15), f), 2.0)
			c.draw_colored_polygon(PackedVector2Array([Vector2(-3, -9), Vector2(-5, -13), Vector2(-1, -11)]), b(Color(0.4, 0.78, 0.25), f))
			c.draw_colored_polygon(PackedVector2Array([Vector2(3, -9), Vector2(5, -14), Vector2(1, -11)]), b(Color(0.4, 0.78, 0.25), f))
			for sd in [Vector2(-3, 0), Vector2(2, 3), Vector2(3, -2), Vector2(-2, 5)]:
				c.draw_circle(sd, 1.1, b(Color(0.4, 0.28, 0.12), f))
		Pecas.Tipo.CANTIL:
			c.draw_line(Vector2(0, -8), Vector2(11, -21), b(Color(0.4, 0.26, 0.14), f), 2.4)
			var cu: Color = Color(0.56, 0.4, 0.22)
			_pol(c, PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(6, 4), Vector2(3, 7), Vector2(-3, 7), Vector2(-6, 4)]), cu, f)
			c.draw_rect(Rect2(-2.2, -9, 4.4, 4), b(Color(0.7, 0.72, 0.78), f))
			c.draw_arc(Vector2(0, 0), 3.0, 0.0, TAU, 10, b(cu.lightened(0.3), f), 1.0)
		Pecas.Tipo.GANCHO:
			var ch: Color = Color(0.8, 0.84, 0.9)
			var hk := PackedVector2Array([Vector2(0, 3), Vector2(0, 10), Vector2(2, 14), Vector2(6, 14), Vector2(8, 10), Vector2(7, 7)])
			c.draw_polyline(hk, b(Color(0.15, 0.17, 0.22), f), 5.0)
			c.draw_polyline(hk, b(ch, f), 2.8)
			_pol(c, PackedVector2Array([Vector2(-3.5, -4), Vector2(3.5, -4), Vector2(3, 4), Vector2(-3, 4)]), Color(0.4, 0.24, 0.12), f)
			c.draw_line(Vector2(-3.4, -1), Vector2(3.4, -1), b(Color(0.95, 0.78, 0.25), f), 1.2)
		Pecas.Tipo.AMULETO:
			c.draw_polyline(PackedVector2Array([Vector2(5.5, -21), Vector2(11, -10), Vector2(16.5, -21)]), b(Color(1.0, 0.85, 0.3), f), 1.4)
			c.draw_circle(Vector2(11, -8), 5.2, b(Color(0.4, 0.25, 0.05), f))
			c.draw_circle(Vector2(11, -8), 4.2, b(Color(1.0, 0.82, 0.25), f))
			c.draw_circle(Vector2(11, -8), 2.6, b(Color(0.7, 0.35, 1.0), f))
			c.draw_circle(Vector2(10.2, -9), 0.9, b(Color(1, 1, 1), f))

static func pips(c: CanvasItem, centro: Vector2, nivel: int, raio: float = 2.2, passo: float = 5.6) -> void:
	if nivel <= 0:
		return
	var n: int = nivel
	for i in n:
		var p: Vector2 = centro + Vector2((i - (n - 1) * 0.5) * passo, 0)
		c.draw_circle(p, raio + 0.9, Color(0.25, 0.15, 0.0, 0.9))
		c.draw_circle(p, raio, DOURADO)

## Pontinhos coloridos das marcas (uma cor por tipo), com contorno escuro.
static func pontos_marcas(c: CanvasItem, centro: Vector2, marcas: Array, raio: float, passo: float, vertical: bool = false) -> void:
	var n: int = marcas.size()
	for i in n:
		var d: float = (i - (n - 1) * 0.5) * passo
		var p: Vector2 = centro + (Vector2(0, d) if vertical else Vector2(d, 0))
		c.draw_circle(p, raio + 1.0, Color(0.05, 0.03, 0.08, 0.9))
		c.draw_circle(p, raio, Pecas.MARCA_COR[marcas[i]])

# ------------------------------------------------------------------ boneco
## Estrelas de patente (polígonos de 5 pontas) centradas em `centro`.
static func estrelas(c: CanvasItem, centro: Vector2, n: int, raio: float = 6.0, passo: float = 14.0) -> void:
	for i in n:
		var p0: Vector2 = centro + Vector2((i - (n - 1) * 0.5) * passo, 0)
		var pts := PackedVector2Array()
		for k in 10:
			var r: float = raio if k % 2 == 0 else raio * 0.45
			var a: float = -PI * 0.5 + k * PI / 5.0
			pts.append(p0 + Vector2(cos(a), sin(a)) * r)
		var borda := PackedVector2Array(pts)
		borda.append(pts[0])
		c.draw_colored_polygon(pts, DOURADO)
		c.draw_polyline(borda, Color(0.3, 0.18, 0.0, 0.95), 1.4)

## Cor de acessório (não muda com a fúria; clareia no flash e respeita o alfa).
static func _ac(base: Color, f: float, alfa: float) -> Color:
	var r: Color = b(base, f)
	r.a = alfa
	return r

## Membro grosso com contorno e pontas arredondadas.
static func _limb(c: CanvasItem, a: Vector2, z: Vector2, w: float, cor: Color, ctn: Color) -> void:
	c.draw_line(a, z, ctn, w + 2.6)
	c.draw_circle(a, w * 0.5 + 1.3, ctn)
	c.draw_circle(z, w * 0.5 + 1.3, ctn)
	c.draw_line(a, z, cor, w)
	c.draw_circle(a, w * 0.5, cor)
	c.draw_circle(z, w * 0.5, cor)

static func _bola(c: CanvasItem, p: Vector2, r: float, cor: Color, ctn: Color) -> void:
	c.draw_circle(p, r + 1.3, ctn)
	c.draw_circle(p, r, cor)

static func _caixa(c: CanvasItem, r: Rect2, cor: Color, ctn: Color) -> void:
	c.draw_rect(r.grow(1.3), ctn)
	c.draw_rect(r, cor)


# ---------------------------------------------------------------- aliado: boneco de pano
static func _pano(c: CanvasItem, cor: Color, ctn: Color, alfa: float, sw: float, braco_y: float) -> void:
	var fio: Color = Color(0.36, 0.22, 0.14, alfa)
	_limb(c, Vector2(-3.5, -19), Vector2(-6 + sw, -2), 6.6, cor, ctn)
	_limb(c, Vector2(3.5, -19), Vector2(6 - sw, -2), 6.6, cor, ctn)
	_limb(c, Vector2(0, -37), Vector2(-9, -27 + sw * 0.4), 5.6, cor, ctn)
	_limb(c, Vector2(0, -37), Vector2(0, -24), 15.0, cor, ctn)
	c.draw_dashed_line(Vector2(-0.5, -35), Vector2(-0.5, -19), fio, 1.2, 2.4)
	var remendo := Rect2(2.5, -31, 6, 6)
	c.draw_rect(remendo, Color(0.8, 0.45, 0.4, alfa))
	c.draw_rect(remendo, fio, false, 0.9)
	_limb(c, Vector2(2, -37), Vector2(11, braco_y), 5.6, cor, ctn)
	_bola(c, Vector2(0, -49), 12.0, cor, ctn)
	c.draw_dashed_line(Vector2(-6, -59), Vector2(-6, -39), fio, 1.2, 2.4)
	c.draw_circle(Vector2(8, -44.5), 2.6, Color(0.92, 0.5, 0.45, 0.5 * alfa))
	c.draw_arc(Vector2(5.2, -47.5), 3.0, 0.35, PI - 0.35, 6, fio, 1.3)
	# olhos de botão
	var bot: Color = Color(0.22, 0.13, 0.09, alfa)
	var brilho: Color = Color(0.95, 0.88, 0.7, alfa)
	for ex in [2.2, 8.0]:
		var p: Vector2 = Vector2(ex, -51.5)
		c.draw_circle(p, 2.7, bot)
		c.draw_circle(p + Vector2(-0.7, -0.7), 0.9, brilho)
		c.draw_line(p + Vector2(-1.4, 1.0), p + Vector2(1.4, 1.0), brilho, 0.7)

# ---------------------------------------------------------------- famílias de inimigos
## Quantos chefes o BichoPx sabe desenhar; os de índice maior caem no desenho de (índice % este número).
const BICHO_CHEFES_DESENHADOS := 10
const COR_FAM: Array[Color] = [Color(0.64, 0.64, 0.7), Color(0.5, 0.44, 0.42), Color(0.95, 0.5, 0.14), Color(0.2, 0.22, 0.36), Color(0.4, 0.7, 0.3)]
## Cor do corpo de cada chefe (Rei dos Ratos, Guaxinim Glutão, Raposa Ligeira, Corvo Velho, Sapo-Rei).
const COR_CHEFES: Array[Color] = [Color(0.52, 0.48, 0.54), Color(0.42, 0.36, 0.34), Color(0.92, 0.44, 0.1), Color(0.16, 0.18, 0.3), Color(0.3, 0.6, 0.28), Color(0.36, 0.3, 0.38), Color(0.14, 0.14, 0.16), Color(0.44, 0.34, 0.22), Color(0.6, 0.44, 0.26), Color(0.4, 0.4, 0.46)]

## Cor-base do bicho comum: a espécie (família) manda, o tipo só clareia ou escurece.
static func cor_inimigo(tipo: int, familia: int) -> Color:
	var base: Color = COR_FAM[clampi(familia, 0, 4)]
	match tipo:
		Unidade.Tipo.SALTADOR:
			return base.lightened(0.12)
		Unidade.Tipo.LADRAO:
			return base.darkened(0.14)
		Unidade.Tipo.GIGANTE:
			return base.darkened(0.22)
		Unidade.Tipo.GEMEO:
			return base.lightened(0.05)
		Unidade.Tipo.CURANDEIRO:
			return base.lightened(0.2)
		Unidade.Tipo.ESCUDEIRO:
			return base.darkened(0.1)
		Unidade.Tipo.BOMBA:
			return base.darkened(0.3)
	return base

static func _blob(cx: float, cy: float, rx: float, ry: float, seed: float, n: int = 18) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a: float = TAU * i / float(n)
		var k: float = 1.0 + 0.09 * sin(a * 3.0 + seed) + 0.06 * sin(a * 5.0 + seed * 2.0)
		pts.append(Vector2(cx + cos(a) * rx * k, cy + sin(a) * ry * k))
	return pts

static func _fechado(pts: PackedVector2Array) -> PackedVector2Array:
	var l := PackedVector2Array(pts)
	l.append(pts[0])
	return l

# ---------------------------------------------------------------- inimigos: bichos invasores
## Ponto relativo ao centro p, na escala k (cabeças pequenas dos filhotes usam k < 1).
static func _q(p: Vector2, k: float, x: float, y: float) -> Vector2:
	return p + Vector2(x, y) * k

## Elipse girada em torno do centro.
static func _elr(cx: float, cy: float, rx: float, ry: float, rot: float = 0.0, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a: float = TAU * i / float(n)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry).rotated(rot) + Vector2(cx, cy))
	return pts

## Elipse com contorno escuro.
static func _ov(c: CanvasItem, cx: float, cy: float, rx: float, ry: float, cor: Color, ctn: Color, rot: float = 0.0) -> void:
	c.draw_colored_polygon(_elr(cx, cy, rx + 1.3, ry + 1.3, rot), ctn)
	c.draw_colored_polygon(_elr(cx, cy, rx, ry, rot), cor)

## Traço grosso com pontas redondas e contorno, passando por vários pontos.
static func _fio(c: CanvasItem, pts: PackedVector2Array, w: float, cor: Color, ctn: Color) -> void:
	var ult: Vector2 = pts[pts.size() - 1]
	c.draw_polyline(pts, ctn, w + 2.6)
	c.draw_circle(pts[0], w * 0.5 + 1.3, ctn)
	c.draw_circle(ult, w * 0.5 + 1.3, ctn)
	c.draw_polyline(pts, cor, w)
	c.draw_circle(pts[0], w * 0.5, cor)
	c.draw_circle(ult, w * 0.5, cor)

## Triângulo com contorno.
static func _tri(c: CanvasItem, a: Vector2, b2: Vector2, d: Vector2, cor: Color, ctn: Color, larg: float = 2.4) -> void:
	var t := PackedVector2Array([a, b2, d])
	c.draw_polyline(_fechado(t), ctn, larg)
	c.draw_colored_polygon(t, cor)

## Asa do corvo no lugar do braço: penas penduradas e braço de penas por cima.
static func _asa(c: CanvasItem, s: Vector2, t: Vector2, w: float, cor: Color, ctn: Color) -> void:
	var d: Vector2 = t - s
	var n: Vector2 = Vector2(-d.y, d.x).normalized()
	for i in 4:
		var base: Vector2 = s + d * (0.35 + 0.22 * i)
		_fio(c, PackedVector2Array([base, base + n * (w * 0.9) + d * 0.12]), w * 0.55, cor, ctn)
	_fio(c, PackedVector2Array([s, t]), w, cor, ctn)

## Coroa de pontas (n par): ouro para reis, prata para a tampinha.
static func _coroa(c: CanvasItem, pos: Vector2, w: float, h: float, rot: float, n: int, cor: Color, ctn: Color) -> void:
	var pts := PackedVector2Array([Vector2(-w, 0)])
	for i in n + 1:
		pts.append(Vector2(-w + 2.0 * w * i / float(n), -h if i % 2 == 0 else -h * 0.45))
	pts.append(Vector2(w, 0))
	var g := PackedVector2Array()
	for v in pts:
		g.append(v.rotated(rot) + pos)
	c.draw_colored_polygon(g, cor)
	c.draw_polyline(_fechado(g), ctn, 1.5)

## Cores de apoio da espécie: claro (barriga), rosa, escuro, branco, bico.
static func _pal(fam: int, cor: Color, f: float, alfa: float) -> Array:
	var claro: Color
	match fam:
		0:
			claro = Color(0.92, 0.87, 0.85)
		1:
			claro = Color(0.9, 0.84, 0.76)
		2:
			claro = Color(0.99, 0.96, 0.9)
		3:
			claro = cor.lightened(0.16)
		_:
			claro = Color(0.9, 0.94, 0.68)
	return [_ac(claro, f, alfa), _ac(Color(0.96, 0.58, 0.66), f, alfa), _ac(Color(0.1, 0.07, 0.1), f, alfa), _ac(Color(0.98, 0.97, 0.93), f, alfa), _ac(Color(0.98, 0.8, 0.2), f, alfa)]

## Olho de bicho: lid 1 = meio fechado (malandro), leitoso = olho cego do Corvo Velho.
static func _olho(c: CanvasItem, p: Vector2, r: float, lid: int, cor: Color, esc: Color, branco: Color, leitoso: bool = false) -> void:
	c.draw_circle(p, r + 1.0, esc)
	if leitoso:
		c.draw_circle(p, r, Color(0.82, 0.88, 0.92, branco.a))
		c.draw_circle(p + Vector2(r * 0.25, 0), r * 0.38, Color(0.68, 0.75, 0.82, branco.a))
		c.draw_line(p + Vector2(-r * 0.8, -r * 0.9), p + Vector2(r * 0.8, r * 0.9), esc, 0.9)
		return
	c.draw_circle(p, r, branco)
	c.draw_circle(p + Vector2(r * 0.38, r * 0.1), r * 0.55, esc)
	c.draw_circle(p + Vector2(r * 0.2, -r * 0.2), r * 0.18, branco)
	if lid == 1:
		var pts := PackedVector2Array()
		for i in 7:
			var a: float = lerpf(PI + 0.1, TAU - 0.1, i / 6.0)
			pts.append(p + Vector2(cos(a), sin(a)) * (r + 0.5))
		c.draw_colored_polygon(pts, cor)
		c.draw_line(pts[0], pts[6], esc, 1.1)

## Cabeça da espécie olhando para +x. k < 1 faz as cabecinhas dos filhotes nas costas.
## Opções: lid, brava, mask, lingua, faixa, leitoso, arrepio.
static func _cabeca(c: CanvasItem, fam: int, p: Vector2, k: float, cor: Color, ctn: Color, f: float, alfa: float, o: Dictionary) -> void:
	var pal: Array = _pal(fam, cor, f, alfa)
	var claro: Color = pal[0]
	var rosa: Color = pal[1]
	var esc: Color = pal[2]
	var branco: Color = pal[3]
	var bico: Color = pal[4]
	var lid: int = int(o.get("lid", 1))
	var brava: bool = o.get("brava", false)
	var ep: Vector2 = p
	var er: float = 3.2 * k
	if o.get("arrepio", false):
		_tri(c, _q(p, k, -8, -3), _q(p, k, -15, -10), _q(p, k, -2, -8), cor, ctn)
		_tri(c, _q(p, k, -4, -6), _q(p, k, -6, -16), _q(p, k, 2, -9), cor, ctn)
		_tri(c, _q(p, k, 1, -7), _q(p, k, 5, -16), _q(p, k, 7, -7), cor, ctn)
	match fam:
		0:  # rato: orelhas redondas enormes, focinho pontudo, dentão
			for oe in [Vector2(-5, -9.5), Vector2(3.5, -11)]:
				_bola(c, _q(p, k, oe.x, oe.y), 6.8 * k, cor, ctn)
				c.draw_circle(_q(p, k, oe.x, oe.y), 4.0 * k, rosa)
			_bola(c, p, 9.8 * k, cor, ctn)
			var s0 := PackedVector2Array([_q(p, k, 6, -5.5), _q(p, k, 19, 0.5), _q(p, k, 6, 5)])
			c.draw_polyline(s0, ctn, 2.6)
			c.draw_colored_polygon(s0, cor)
			c.draw_circle(_q(p, k, 19, 0.5), 2.4 * k, Color(0.9, 0.42, 0.52, alfa))
			c.draw_line(_q(p, k, 13, 1), _q(p, k, 23, -3), ctn, 0.9)
			c.draw_line(_q(p, k, 13, 2.2), _q(p, k, 23, 4), ctn, 0.9)
			c.draw_rect(Rect2(_q(p, k, 10.5, 3.6), Vector2(2.6, 3.2) * k), branco)
			c.draw_rect(Rect2(_q(p, k, 10.5, 3.6), Vector2(2.6, 3.2) * k), ctn, false, 0.7)
			ep = _q(p, k, 4.8, -3.2)
			er = 3.4 * k
		1:  # guaxinim: cabeça larga, orelhinhas, máscara preta
			for oe in [Vector2(-8, -9), Vector2(5, -11)]:
				_bola(c, _q(p, k, oe.x, oe.y), 4.8 * k, cor, ctn)
				c.draw_circle(_q(p, k, oe.x, oe.y), 2.4 * k, claro)
			_ov(c, p.x, p.y, 12.5 * k, 10.5 * k, cor, ctn)
			c.draw_colored_polygon(_elr(p.x + 5 * k, p.y + 5 * k, 8.5 * k, 4.8 * k), claro)
			_bola(c, _q(p, k, 13, 2.5), 4.6 * k, claro, ctn)
			c.draw_circle(_q(p, k, 17.5, 1.5), 2.5 * k, esc)
			c.draw_colored_polygon(_elr(p.x + 3 * k, p.y - 3.5 * k, 10.5 * k, 4.8 * k, 0.08), esc)
			c.draw_colored_polygon(_elr(p.x + 4 * k, p.y - 9.2 * k, 4.5 * k, 1.5 * k), claro)
			ep = _q(p, k, 5.5, -3.5)
			er = 2.9 * k
		2:  # raposa: orelhas pontudas, focinho comprido, mandíbula branca
			for oe in [[-9.0, -5.0, -7.0, -22.0, 0.0, -8.0], [0.0, -8.0, 5.0, -23.0, 9.0, -5.0]]:
				var a1: Vector2 = _q(p, k, oe[0], oe[1])
				var a2: Vector2 = _q(p, k, oe[2], oe[3])
				var a3: Vector2 = _q(p, k, oe[4], oe[5])
				_tri(c, a1, a2, a3, cor, ctn, 2.6)
				var cen: Vector2 = (a1 + a2 + a3) / 3.0
				c.draw_colored_polygon(PackedVector2Array([cen + (a1 - cen) * 0.45, cen + (a2 - cen) * 0.6, cen + (a3 - cen) * 0.45]), esc)
			_ov(c, p.x, p.y, 9.6 * k, 8.8 * k, cor, ctn)
			var jaw := PackedVector2Array([_q(p, k, 3, 2), _q(p, k, 20, 3.4), _q(p, k, 15, 8.5), _q(p, k, 3, 9)])
			c.draw_polyline(_fechado(jaw), ctn, 2.4)
			c.draw_colored_polygon(jaw, branco)
			var s2 := PackedVector2Array([_q(p, k, 4, -5.5), _q(p, k, 21, 2), _q(p, k, 4, 5.5)])
			c.draw_polyline(s2, ctn, 2.6)
			c.draw_colored_polygon(s2, cor)
			c.draw_circle(_q(p, k, 21, 1.8), 2.2 * k, esc)
			if o.get("lingua", false):
				c.draw_colored_polygon(_elr(p.x + 14 * k, p.y + 10.5 * k, 2.8 * k, 4.6 * k, 0.15), rosa)
				c.draw_line(_q(p, k, 14.2, 7.5), _q(p, k, 14.4, 13), Color(0.8, 0.35, 0.45, alfa), 0.9)
			ep = _q(p, k, 4.6, -3.0)
			er = 2.8 * k
		3:  # corvo: topete, bico amarelo
			_tri(c, _q(p, k, -7, -6), _q(p, k, -10, -14), _q(p, k, -2, -8.5), cor, ctn)
			_tri(c, _q(p, k, -2, -8), _q(p, k, -3, -16), _q(p, k, 4, -8), cor, ctn)
			_bola(c, p, 8.8 * k, cor, ctn)
			var bs: float = 1.25 if o.get("leitoso", false) else 1.0
			var cima := PackedVector2Array([_q(p, k, 6, -5), _q(p, k, 6 + 15 * bs, 2.0), _q(p, k, 6, 2.2)])
			var baixo := PackedVector2Array([_q(p, k, 6, 1.8), _q(p, k, 6 + 11 * bs, 3.0), _q(p, k, 6, 5.5)])
			c.draw_polyline(baixo, ctn, 2.4)
			c.draw_colored_polygon(baixo, Color(bico.r * 0.85, bico.g * 0.8, bico.b * 0.6, alfa))
			c.draw_polyline(cima, ctn, 2.4)
			c.draw_colored_polygon(cima, bico)
			c.draw_circle(_q(p, k, 11, -1.5), 0.8 * k, ctn)
			ep = _q(p, k, 3.4, -3.0)
			er = 3.0 * k
		_:  # sapo: cabeça larga, olhos saltados, boca enorme
			var olhos: Array = [Vector2(-3, -7.5), Vector2(7, -7.5)]
			for oe in olhos:
				_bola(c, _q(p, k, oe.x, oe.y), 5.3 * k, cor, ctn)
			_ov(c, p.x + 1.5 * k, p.y + 2 * k, 12.8 * k, 8.8 * k, cor, ctn)
			c.draw_colored_polygon(_elr(p.x + 4 * k, p.y + 8.2 * k, 8.5 * k, 2.6 * k), claro)
			c.draw_polyline(PackedVector2Array([_q(p, k, -9, 3.5), _q(p, k, -3, 7), _q(p, k, 5, 7.6), _q(p, k, 12, 5.8), _q(p, k, 16, 3.2)]), esc, 1.5)
			c.draw_circle(_q(p, k, 12.5, -0.5), 0.9 * k, esc)
			c.draw_circle(_q(p, k, -5, 2.5), 1.3 * k, ctn)
			c.draw_circle(_q(p, k, 1, 0.5), 1.0 * k, ctn)
			if o.get("mask", false):
				c.draw_line(_q(p, k, -9, -6.5), _q(p, k, 14, -6.5), esc, 3.6 * k)
			for oe in olhos:
				_olho(c, _q(p, k, oe.x + 0.2, oe.y - 0.3), 3.5 * k, 0 if brava else lid, cor, esc, branco)
			if brava:
				c.draw_line(_q(p, k, -7, -13.5), _q(p, k, 11, -9.5), esc, 2.4 * k)
			return
	# olho único (perfil) e adornos das demais espécies
	if o.get("mask", false) and fam != 1:
		c.draw_colored_polygon(_elr(ep.x + 2 * k, ep.y + 0.3 * k, 8.8 * k, 4.2 * k, 0.1), esc)
	_olho(c, ep, er, 0 if brava else lid, cor, esc, branco, o.get("leitoso", false))
	if brava:
		c.draw_line(ep + Vector2(-4.5, -4.6) * k, ep + Vector2(5.5, -1.0) * k, esc, 2.6 * k)
	if o.get("faixa", false):
		var verm: Color = Color(0.86, 0.15, 0.2, alfa)
		var fa: Vector2 = _q(p, k, -9.2, -3.5)
		var fz: Vector2 = _q(p, k, 8.0, -8.0)
		c.draw_line(fa, fz, ctn, 4.8 * k)
		c.draw_line(fa, fz, verm, 3.0 * k)
		var bal: float = sin(Time.get_ticks_msec() / 1000.0 * 6.0) * 1.5
		var fita := PackedVector2Array([fa, fa + Vector2(-6, 1 + bal), fa + Vector2(-12, 0)])
		c.draw_polyline(fita, ctn, 3.4)
		c.draw_polyline(fita, verm, 1.8)

## Corpo do bicho. fam = espécie (0 rato, 1 guaxinim, 2 raposa, 3 corvo, 4 sapo); ct >= 0 = chefe.
static func _bicho(c: CanvasItem, fam: int, tipo: int, ct: int, parte: bool, parado: bool, carregando: bool, andando: bool, cor: Color, ctn: Color, f: float, alfa: float, sw: float, braco_y: float, anim: float) -> void:
	var chefe: bool = ct >= 0
	var pal: Array = _pal(fam, cor, f, alfa)
	var claro: Color = pal[0]
	var rosa: Color = pal[1]
	var branco: Color = pal[3]
	var filhote: bool = parte or (tipo == Unidade.Tipo.GEMEO and carregando and not chefe)
	var salt: bool = tipo == Unidade.Tipo.SALTADOR and not chefe and not parte
	var lad: bool = tipo == Unidade.Tipo.LADRAO and not chefe and not parte
	var gig: bool = tipo == Unidade.Tipo.GIGANTE and not chefe and not parte
	var ger: bool = tipo == Unidade.Tipo.GEMEO and not filhote and not chefe
	var tt: float = Time.get_ticks_msec() / 1000.0
	# medidas por espécie
	var bw: float = [8.8, 12.5, 7.2, 7.6, 10.5][fam]
	var bh: float = 13.0 if fam == 1 else 12.0
	var by: float = -29.0
	var hy: float = -49.0
	var lw: float = 3.0 if fam == 3 else 5.0
	var hk: float = 1.0
	var aw: float = 4.4
	if salt:
		bw *= 0.82
		by = -33.0
		hy = -52.0
	if gig:
		bw *= 1.3
		bh += 1.5
		aw = 6.2
	if chefe:
		match ct:
			0:
				bw = 12.5
				bh = 13.5
			1:
				bw = 16.5
				bh = 15.0
				by = -27.0
				aw = 6.4
			2:
				bw = 7.8
				bh = 13.5
				by = -30.0
			3:
				bw = 8.5
				bh = 13.0
				aw = 5.4
			4:
				bw = 16.5
				bh = 12.5
				by = -27.0
				hy = -47.0
				aw = 6.0
	if filhote:
		bw *= 0.78
		bh *= 0.62
		by = -17.0
		hy = -36.0
		hk = 1.38
		lw *= 0.9
		aw = 3.4
	var oy: float = 0.0
	if andando and salt:
		oy = -absf(sin(anim)) * 5.0
	elif andando and filhote:
		oy = -absf(sin(anim)) * 2.0
	var hp := Vector2(0, hy + oy)
	var inc: float = 0.0   # inclinação do tronco (Corvo Velho curvado)
	if ct == 3:
		hp += Vector2(5, 3)
		inc = 0.3
	if parado and ct == 2:
		hp += Vector2(5, 5)
		braco_y = -15.0
	var topo: float = by - bh + oy
	var ombro := Vector2(2.5, topo + 5.0)
	var tb := Vector2(-bw + 1.0, by + bh - 4.0 + oy)
	var s: float = sin(tt * 3.0) * 2.0
	# ---- atrás do corpo
	if ct == 0:
		var capa := PackedVector2Array([Vector2(-5, topo + 1), Vector2(3, topo + 2), Vector2(0, -8), Vector2(-5, -5), Vector2(-9, -8), Vector2(-13, -5), Vector2(-18, -9), Vector2(-15, -26)])
		c.draw_polyline(_fechado(capa), ctn, 2.6)
		c.draw_colored_polygon(capa, _ac(Color(0.72, 0.18, 0.24), f, alfa))
		c.draw_rect(Rect2(-12, -22, 5, 5), _ac(Color(0.92, 0.78, 0.35), f, alfa))
		c.draw_rect(Rect2(-9, -14, 5, 4), _ac(Color(0.4, 0.62, 0.7), f, alfa))
		c.draw_rect(Rect2(-12, -22, 5, 5), ctn, false, 0.8)
		c.draw_rect(Rect2(-9, -14, 5, 4), ctn, false, 0.8)
	if ger:
		for bb in [Vector2(-14, -41), Vector2(-15, -56)]:
			_cabeca(c, fam, bb + Vector2(0, oy), 0.55, cor.lightened(0.08), ctn, f, alfa, {"lid": 0})
		for mp in [Vector2(-7, -37), Vector2(-9, -45)]:
			_bola(c, mp + Vector2(0, oy), 2.3, cor, ctn)
	if lad:
		var sk := Vector2(-bw - 3.5, by - 2.0 + oy)
		var rs: float = 10.0 if carregando else 8.0
		var saco: Color = _ac(Color(0.72, 0.56, 0.32), f, alfa)
		if carregando:
			for i in 3:
				var br := Rect2(sk.x - 6 + i * 4.2, sk.y - rs - 4.5 - (i % 2) * 2.2, 5.5, 5.5)
				c.draw_rect(br.grow(1.0), ctn)
				c.draw_rect(br, b(COR_BLOCOS[i + 1], f))
		_bola(c, sk, rs, saco, ctn)
		c.draw_colored_polygon(PackedVector2Array([sk + Vector2(-3, -rs + 0.5), sk + Vector2(3, -rs + 0.5), sk + Vector2(5, -rs - 3), sk + Vector2(-5, -rs - 3)]), saco)
		c.draw_line(sk + Vector2(-4, -rs + 0.5), sk + Vector2(4, -rs + 0.5), ctn, 1.8)
		c.draw_line(sk + Vector2(-2, -2), sk + Vector2(2, 3), ctn, 0.9)
	# rabo
	match fam:
		0:
			_fio(c, PackedVector2Array([tb, tb + Vector2(-8, 2), tb + Vector2(-15, -2 + s * 0.5), tb + Vector2(-22, -9 + s)]), 2.2, rosa, ctn)
		1:
			var pr := PackedVector2Array([tb, tb + Vector2(-8, -1), tb + Vector2(-15, -6), tb + Vector2(-20, -13 + s * 0.5)])
			_fio(c, pr, 8.5, cor, ctn)
			var fe: Color = cor.darkened(0.6)
			for i in [1, 2]:
				var dd: Vector2 = (pr[i + 1] - pr[i - 1]).normalized().orthogonal()
				c.draw_line(pr[i] - dd * 4.2, pr[i] + dd * 4.2, fe, 3.0)
			c.draw_circle(pr[3], 4.3, fe)
		2:
			var pf := PackedVector2Array([tb, tb + Vector2(-9, 2), tb + Vector2(-18, -3), tb + Vector2(-26, -12 + s)])
			_fio(c, pf, 9.0, cor, ctn)
			c.draw_line(pf[2].lerp(pf[3], 0.4), pf[3], branco, 8.0)
			c.draw_circle(pf[3], 4.0, branco)
		3:
			for pe in [Vector2(-15, 2), Vector2(-17, -4), Vector2(-14, -10)]:
				_fio(c, PackedVector2Array([tb, tb + pe]), 3.4, cor.lightened(0.06), ctn)
	if ct == 3:
		for i in 5:
			var yy: float = topo + 2.0 + i * 5.2
			var xx: float = -bw + 2.0 + i * 0.4
			_tri(c, Vector2(xx, yy), Vector2(xx - 7.5, yy - 3.5), Vector2(xx + 1.0, yy + 4.0), cor.lightened(0.06), ctn, 2.2)
	# braço de trás
	var mao_t := Vector2(-9, -26 + sw * 0.4)
	if fam == 3:
		_asa(c, ombro + Vector2(-5, 0), mao_t, aw, cor, ctn)
	else:
		_limb(c, ombro + Vector2(-5, 0), mao_t, aw, cor, ctn)
	# ---- pernas
	var quadril: float = by + bh - 3.0 + oy
	var pe_cor: Color = cor if fam != 3 else cor.lightened(0.12)
	for lado in [-1.0, 1.0]:
		var lx: float = lado * bw * 0.45
		var fx: float = lx + (sw if lado < 0.0 else -sw) * 0.8
		if salt:
			_fio(c, PackedVector2Array([Vector2(lx, quadril), Vector2(lx + 7.0, (quadril - 2.0) * 0.5), Vector2(fx, -3.0)]), lw, pe_cor, ctn)
		elif fam == 3:
			_fio(c, PackedVector2Array([Vector2(lx, quadril), Vector2(fx, -3.0)]), lw, pe_cor, ctn)
		else:
			_limb(c, Vector2(lx, quadril), Vector2(fx, -3.5), lw, pe_cor, ctn)
		if fam == 3:
			for g in [-1.0, 0.0, 1.0]:
				c.draw_line(Vector2(fx, -2.5), Vector2(fx + 5.5, -1.0 + g * 1.6), ctn, 1.8)
		elif fam == 4:
			_ov(c, fx + 3.5, -2.0, 6.0, 2.6, pe_cor, ctn)
		else:
			_ov(c, fx + 2.5, -2.0, 4.6, 2.5, pe_cor, ctn)
	# ---- tronco
	var cy: float = by + oy
	_ov(c, 0.0, cy, bw, bh, cor, ctn, inc)
	c.draw_colored_polygon(_elr(bw * 0.28, cy + 2.0, bw * (0.7 if fam == 2 else 0.6), bh * 0.78, inc), claro)
	if gig or ct == 1 or ct == 4:
		for sx in [-0.75, 0.75]:
			_bola(c, Vector2(bw * sx, topo + 4.5), 6.5 if gig else 7.5, cor, ctn)
	if ct == 4:
		for wp in [Vector2(-8, -34), Vector2(6, -22), Vector2(-3, -18)]:
			c.draw_circle(wp + Vector2(0, oy), 1.5, ctn)
	# ---- cabeça
	var op: Dictionary = {"lid": 1}
	if gig or ct == 4:
		op = {"lid": 0, "brava": true}
	if lad:
		op["mask"] = true
	if ct == 2:
		op["faixa"] = true
		if parado:
			op["lingua"] = true
	if ct == 3:
		op["leitoso"] = true
		op["arrepio"] = true
		op["lid"] = 0
	if filhote:
		op["lid"] = 0
	_cabeca(c, fam, hp, hk, cor, ctn, f, alfa, op)
	if lad:
		var nk: Vector2 = hp + Vector2(1.5, 8.5 * hk)
		var verm: Color = _ac(Color(0.86, 0.15, 0.2), f, alfa)
		c.draw_colored_polygon(PackedVector2Array([nk + Vector2(-7, -1), nk + Vector2(-14, -4), nk + Vector2(-13, 3)]), verm)
		_fio(c, PackedVector2Array([nk + Vector2(-8, -0.5), nk + Vector2(0, 3.5), nk + Vector2(8, 0)]), 3.4, verm, ctn)
	if ct == 0:
		_coroa(c, hp + Vector2(-1, -9.5), 6.0, 6.5, -0.12, 6, _ac(Color(0.78, 0.8, 0.84), f, alfa), ctn)
	if ct == 4:
		_coroa(c, hp + Vector2(1.5, -11.5), 8.0, 9.0, 0.4, 4, _ac(DOURADO, f, alfa), Color(0.3, 0.18, 0.0, alfa))
	if parado and ct == 2:
		for i in 3:
			var fr: float = fposmod(tt * 1.2 + i * 0.34, 1.0)
			var dp: Vector2 = hp + Vector2(-9 - i * 3.0, -12 + fr * 16.0)
			var az: Color = Color(0.55, 0.82, 1.0, (1.0 - fr) * alfa)
			c.draw_circle(dp, 1.9, az)
			c.draw_colored_polygon(PackedVector2Array([dp + Vector2(0, -4.6), dp + Vector2(-1.8, -0.8), dp + Vector2(1.8, -0.8)]), az)
	# ---- braço da frente
	var mao := Vector2(11, braco_y + oy * 0.5)
	if fam == 3:
		_asa(c, ombro, mao, aw, cor, ctn)
	else:
		_limb(c, ombro, mao, aw, cor, ctn)
	if ct == 1:
		# osso na mão do Glutão
		var osso: Color = _ac(Color(0.97, 0.94, 0.84), f, alfa)
		var oa: Vector2 = mao + Vector2(4, -9)
		var oz: Vector2 = mao + Vector2(-2, 6)
		c.draw_line(oa, oz, ctn, 5.0)
		c.draw_line(oa, oz, osso, 2.8)
		for kn in [oa, oz]:
			for dx in [-1.7, 1.7]:
				_bola(c, kn + Vector2(dx, 0), 2.4, osso, ctn)

static func boneco(c: CanvasItem, pos: Vector2, esc: float, dir: float, equipe: int, pecas: Array, f: float = 0.0, anim: float = 0.0, andando: bool = false, golpe: float = 0.0, alfa: float = 1.0, fantasma_slots: bool = false, destaque_slot: int = -1, furia: float = 0.0, tipo: int = 0, carregando: bool = false, chefe: bool = false, familia: int = 0, elite: bool = false, chefe_tipo: int = -1, parte: bool = false, parado: bool = false, variante: int = 0, nocaute: bool = false) -> void:
	if equipe == 0:
		_gato(c, pos, esc, dir, pecas, f, anim, andando, golpe, alfa, fantasma_slots, destaque_slot, furia, variante, nocaute)
		return
	_bicho_px(c, pos, esc, dir, pecas, f, anim, andando, golpe, alfa, tipo, carregando, chefe, familia, elite, chefe_tipo, parte, parado)
	return
	var cor: Color
	if equipe == 0:
		cor = b(COR_ALIADO, f)
	elif parte:
		cor = b(COR_CHEFES[4], f)
	elif chefe:
		cor = b(COR_CHEFES[clampi(chefe_tipo, 0, 9)] if chefe_tipo >= 0 else COR_CHEFE, f)
	else:
		cor = b(cor_inimigo(tipo, familia), f)
	if furia > 0.0:
		cor = cor.lerp(Color(0.95, 0.12, 0.08), clampf(furia, 0.0, 1.0) * 0.8)
	if parado:
		cor = cor.darkened(0.3)
	cor.a = alfa
	var ctn: Color = cor.darkened(0.5)
	ctn.a = alfa
	var sw: float = sin(anim) * 6.0 if andando else 0.0
	var corpo: Peca = pecas[1]
	var cabeca: Peca = pecas[0]
	var mao: Peca = pecas[2]
	var dy: float = 0.0
	if equipe == 1 and tipo == Unidade.Tipo.GEMEO and andando and not chefe:
		dy = -absf(sin(anim)) * 2.5
	var grande: bool = equipe == 1 and (chefe or parte)
	var mini: float = 0.62 if grande else 1.0           # peças discretas no chefe: o corpo aparece
	var giro: float = 0.55 if (parado and chefe) else 0.0  # Robô sem corda cai para a frente
	var alto: float = 1.14 if (equipe == 1 and chefe and chefe_tipo == 3) else 1.0
	# capa fica atrás
	if corpo != null and corpo.tipo == Pecas.Tipo.CAPA:
		_peca_no_boneco(c, pos, esc, dir, corpo, 1, f, anim, 0.0, dy, mini, giro, alto)
	_tr(c, pos, esc, dir, Vector2(0, dy), giro, 1.0, alto)
	# aura do inimigo fantasiado: pulsa na cor da fantasia que mais veste
	if elite and equipe == 1:
		var cont: Array[int] = Pecas.contar_conjuntos(pecas)
		var melhor: int = 0
		for i in cont.size():
			if cont[i] > cont[melhor]:
				melhor = i
		var ca: Color = Pecas.CONJUNTO_COR[melhor]
		var pu: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 4.0)
		var el := _elipse(0, -32, 20.0 + pu * 2.0, 38.0 + pu * 2.0, 24)
		c.draw_colored_polygon(el, Color(ca.r, ca.g, ca.b, 0.10 + 0.07 * pu))
		c.draw_polyline(_fechado(el), Color(ca.r, ca.g, ca.b, 0.55 + 0.3 * pu), 2.0)
		for k in 2:
			var ang: float = Time.get_ticks_msec() / 1000.0 * 2.4 + k * PI
			_estrela_p(c, Vector2(cos(ang) * 21.0, -32 + sin(ang) * 36.0), 2.6, Color(ca.r, ca.g, ca.b, 0.95), false)
	var braco_y: float = -28.0 - sin(golpe / 0.22 * PI) * 6.0 if golpe > 0.0 else -28.0
	if equipe == 0:
		_pano(c, cor, ctn, alfa, sw, braco_y)
	elif parte:
		_bicho(c, 4, tipo, -1, true, parado, carregando, andando, cor, ctn, f, alfa, sw, braco_y, anim)
	elif chefe:
		var ct: int = clampi(chefe_tipo, 0, 4)
		_bicho(c, ct, tipo, ct, false, parado, carregando, andando, cor, ctn, f, alfa, sw, braco_y, anim)
	else:
		_bicho(c, clampi(familia, 0, 4), tipo, -1, false, parado, carregando, andando, cor, ctn, f, alfa, sw, braco_y, anim)
	# slots vazios (fantasma) na tela do guarda-roupa
	if fantasma_slots:
		for s in Pecas.SLOTS:
			if pecas[s] == null:
				_slot_fantasma(c, ANCORAS[s], s, destaque_slot == s)
	# peças
	for s in [1, 0, 3, 2]:
		var p: Peca = pecas[s]
		if p == null or p.tipo == Pecas.Tipo.CAPA:
			continue
		var rot: float = 0.0
		if s == 2 and golpe > 0.0:
			rot = -sin(golpe / 0.22 * PI) * 1.1
		_peca_no_boneco(c, pos, esc, dir, p, s, f, anim, rot, dy, mini, giro, alto)
	resetar(c)

# ------------------------------------------------------------------ bichos (os inimigos), em pixel art
## Inimigo de quatro patas na grade de pixels do gato (ver BichoPx); veste as roupas do gato (RoupaGato).
static func _bicho_px(c: CanvasItem, pos: Vector2, esc: float, dir: float, pecas: Array, f: float, anim: float, andando: bool, golpe: float, alfa: float, tipo: int, carregando: bool, chefe: bool, familia: int, elite: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var ct: int = (chefe_tipo % BICHO_CHEFES_DESENHADOS) if chefe else -1
	var fam: int = 4 if parte else familia % 5
	var filhote: bool = tipo == Unidade.Tipo.GEMEO and carregando
	_tr(c, pos, esc, dir)
	c.draw_colored_polygon(_elipse(0, 0, 26.0, 5.0, 14), Color(0, 0, 0, 0.22 * alfa))
	if elite:
		# fantasiado: aura pulsando na cor da fantasia que mais veste
		var cont: Array[int] = Pecas.contar_conjuntos(pecas)
		var melhor: int = 0
		for i in cont.size():
			if cont[i] > cont[melhor]:
				melhor = i
		var ca: Color = Pecas.CONJUNTO_COR[melhor]
		var pu: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 4.0)
		var el := _elipse(0, -28, 40.0 + pu * 2.0, 34.0 + pu * 2.0, 24)
		c.draw_colored_polygon(el, Color(ca.r, ca.g, ca.b, 0.08 + 0.06 * pu))
		c.draw_polyline(_fechado(el), Color(ca.r, ca.g, ca.b, 0.5 + 0.3 * pu), 2.0)
	_tr(c, pos, esc, dir, Vector2.ZERO, 0.0, GATO_K)
	BichoPx.desenhar(c, fam, tipo, anim, andando, golpe, f, alfa, carregando and tipo == Unidade.Tipo.LADRAO, filhote, ct, parte, parado)
	if parte or filhote:
		resetar(c)
		return
	for s in [1, 3, 0, 2]:
		var p: Peca = pecas[s]
		if p == null:
			continue
		var onde: int = RoupaGato.onde(p.tipo)
		if onde == RoupaGato.Onde.PATAS:
			var dp: Vector2 = BichoPx.desloc(onde, fam, tipo, anim, andando, golpe, ct, parado)
			var pp: Array[Vector2] = RoupaGato.PATAS_PADRAO
			for k in pp.size():
				if RoupaGato.so_pata_da_frente(p.tipo) and k < pp.size() - 1:
					continue
				_tr(c, pos, esc, dir, (pp[k] + dp) * GATO_K, 0.0, GATO_K)
				RoupaGato.desenhar(c, p.tipo, f, anim)
			continue
		var rot: float = -sin(golpe / 0.22 * PI) * 0.5 if (onde == RoupaGato.Onde.BOCA and golpe > 0.0) else 0.0
		var o: Vector2 = RoupaGato.ORIGEM[onde] + BichoPx.desloc(onde, fam, tipo, anim, andando, golpe, ct, parado)
		# peça de mão (presa na boca) em bicho: menor, para não invadir o bicho vizinho; continua presa à boca
		var k_mao: float = GATO_K * (0.7 if onde == RoupaGato.Onde.BOCA else 1.0)
		_tr(c, pos, esc, dir, o * GATO_K, rot, k_mao)
		RoupaGato.desenhar(c, p.tipo, f, anim)
	if not chefe:
		_tr(c, pos, esc, dir)
		_adereco_tipo(c, tipo, alfa)
	resetar(c)

## Os adereços dos bichos de truque (aljava e arco, bolsa de curativo, escudo, bomba) agora são desenhados por BichoPxT,
## presos às âncoras do corpo, junto com o bicho. Esta função ficou só para não quebrar quem a chama.
static func _adereco_tipo(_c: CanvasItem, _tipo: int, _alfa: float) -> void:
	pass

# ------------------------------------------------------------------ gato (os heróis)
const GATO_TEX: Array[Texture2D] = [preload("res://assets/gato_0.png"), preload("res://assets/gato_1.png"), preload("res://assets/gato_2.png")]
const GATO_K := 3.2        # unidades locais por pixel do sprite original
const GATO_CHAO := 25.0    # y do pé dentro do quadro original

## Quadro do atlas para o estado do gato.
static func gato_quadro(anim: float, andando: bool, golpe: float, nocaute: bool = false) -> int:
	if nocaute:
		return GatoDados.DORMIR + (int(Time.get_ticks_msec() / 700.0) % GatoDados.DORMIR_N)
	if golpe > 0.0:
		return GatoDados.ATACAR + clampi(int((1.0 - golpe / 0.22) * GatoDados.ATACAR_N), 0, GatoDados.ATACAR_N - 1)
	if andando:
		return GatoDados.ANDAR + posmod(int(anim * 1.3), GatoDados.ANDAR_N)
	return GatoDados.ATACAR  # parado de pé, de lado

## Onde fica o centro visual da peça do espaço `s` no gato (coordenadas locais, pé em 0,0).
## `tipo` ajusta os acessórios que vão em lugares próprios (botas nas patas, nariz no rosto, colar no pescoço).
## Sem `quadro`, usa o gato parado: é o que o guarda-roupa usa para os espaços clicáveis.
static func ponto_gato(s: int, quadro: int = -1, tipo: int = -1) -> Vector2:
	var q: int = GatoDados.ATACAR if quadro < 0 else quadro
	var onde: int = [RoupaGato.Onde.CABECA, RoupaGato.Onde.CORPO, RoupaGato.Onde.BOCA, RoupaGato.Onde.TRASEIRA][s]
	if tipo >= 0:
		onde = RoupaGato.onde(tipo)
	var ajuste: Vector2 = [Vector2(0, -2), Vector2.ZERO, Vector2(3, 0), Vector2(0, -1)][s] if tipo < 0 else Vector2.ZERO
	return (RoupaGato.origem(onde, q) + ajuste) * GATO_K

static func _gato(c: CanvasItem, pos: Vector2, esc: float, dir: float, pecas: Array, f: float, anim: float, andando: bool, golpe: float, alfa: float, fantasma_slots: bool, destaque_slot: int, furia: float, variante: int, nocaute: bool) -> void:
	var q: int = gato_quadro(anim, andando, golpe, nocaute)
	var lado: float = GatoDados.FONTE * GATO_K
	var cel: float = GatoDados.CELULA
	var src := Rect2((q % GatoDados.COLUNAS) * cel, (q / GatoDados.COLUNAS) * cel, cel, cel)
	var dest := Rect2(-lado * 0.5, -GATO_CHAO * GATO_K, lado, lado)
	var tinta := Color(1.0, 1.0 - 0.45 * f, 1.0 - 0.45 * f, alfa)
	if furia > 0.0:
		tinta = tinta.lerp(Color(1.0, 0.35, 0.3, alfa), clampf(furia, 0.0, 1.0) * 0.7)
	_tr(c, pos, esc, dir)
	c.draw_colored_polygon(_elipse(0, 0, 26.0, 5.0, 14), Color(0, 0, 0, 0.22 * alfa))
	c.draw_texture_rect_region(GATO_TEX[posmod(variante, GATO_TEX.size())], dest, src, tinta)
	if fantasma_slots:
		for s in Pecas.SLOTS:
			if pecas[s] == null:
				_slot_fantasma(c, ponto_gato(s, q), s, destaque_slot == s)
	if nocaute:
		resetar(c)
		return  # dormindo: sem roupa por cima, para o gato enrolado aparecer
	# roupas na versão do gato: pixel art na grade do sprite (ver RoupaGato)
	for s in [1, 3, 0, 2]:
		var p: Peca = pecas[s]
		if p == null:
			continue
		var onde: int = RoupaGato.onde(p.tipo)
		if onde == RoupaGato.Onde.PATAS:
			# calçado: um em cada pata, acompanhando o passo
			var pts: Array = RoupaGato.patas(q)
			for k in pts.size():
				if RoupaGato.so_pata_da_frente(p.tipo) and k < pts.size() - 1:
					continue
				_tr(c, pos, esc, dir, pts[k] * GATO_K, 0.0, GATO_K)
				RoupaGato.desenhar(c, p.tipo, f, anim)
			continue
		var rot: float = -sin(golpe / 0.22 * PI) * 0.5 if (onde == RoupaGato.Onde.BOCA and golpe > 0.0) else 0.0
		_tr(c, pos, esc, dir, RoupaGato.origem(onde, q) * GATO_K, rot, GATO_K)
		RoupaGato.desenhar(c, p.tipo, f, anim)
		if p.raridade > 0 and s == 0:
			# raridade: cintilação discreta acima da cabeça
			var tw: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 5.0 + s)
			var cr: Color = Pecas.RARIDADE_COR[p.raridade]
			c.draw_rect(Rect2(-6.0, -9.0 - tw, 1.0, 1.0), Color(cr.r, cr.g, cr.b, 0.5 + 0.5 * tw))
	resetar(c)

## Brilho de raridade centrado em `centro` (coordenadas locais do transform atual).
## 1 = rara (azul discreto), 2 = lendária (dourado com cintilação).
static func brilho_raridade(c: CanvasItem, centro: Vector2, raio: float, raridade: int, suave: bool = false) -> void:
	if raridade <= 0:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var cor: Color = Pecas.RARIDADE_COR[clampi(raridade, 0, 2)]
	var pu: float = 0.5 + 0.5 * sin(t * 3.0)
	if suave:
		# vestida no boneco: só um anel fino e um pontinho cintilando na lendária
		c.draw_arc(centro, raio * 0.8, 0.0, TAU, 20, Color(cor.r, cor.g, cor.b, 0.12 + 0.08 * pu), 1.0)
		if raridade >= 2:
			var a2: float = t * 1.5
			var tw: float = 0.5 + 0.5 * sin(t * 7.0)
			c.draw_circle(centro + Vector2(cos(a2), sin(a2)) * raio * 0.8, 0.8 + 0.8 * tw, Color(1.0, 0.95, 0.7, 0.4 + 0.4 * tw))
		return
	c.draw_circle(centro, raio, Color(cor.r, cor.g, cor.b, 0.12 + 0.06 * pu))
	c.draw_arc(centro, raio, 0.0, TAU, 24, Color(cor.r, cor.g, cor.b, 0.35 + 0.2 * pu), 1.4)
	if raridade >= 2:
		c.draw_circle(centro, raio * 0.7, Color(1.0, 0.9, 0.5, 0.12))
		for k in 3:
			var a: float = t * 1.2 + k * TAU / 3.0
			var q: Vector2 = centro + Vector2(cos(a), sin(a) * 0.9) * raio
			var tw: float = 0.5 + 0.5 * sin(t * 7.0 + k * 2.1)
			var r: float = 1.4 + 2.2 * tw
			var cs: Color = Color(1.0, 0.95, 0.7, 0.5 + 0.5 * tw)
			c.draw_line(q - Vector2(r, 0), q + Vector2(r, 0), cs, 1.2)
			c.draw_line(q - Vector2(0, r), q + Vector2(0, r), cs, 1.2)

static func _peca_no_boneco(c: CanvasItem, pos: Vector2, esc: float, dir: float, p: Peca, s: int, f: float, anim: float, rot: float = 0.0, dy: float = 0.0, mini: float = 1.0, giro: float = 0.0, alto: float = 1.0) -> void:
	var extra: float = (1.0 + 0.05 * p.nivel) * mini
	_tr(c, pos, esc, dir, (ANCORAS[s] * Vector2(1.0, alto) + Vector2(0, dy)).rotated(giro), rot + giro, extra)
	if p.raridade > 0:
		brilho_raridade(c, icon_off(p.tipo), 17.0, p.raridade, true)
	if p.nivel >= 3:
		c.draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 20, Color(1.0, 0.85, 0.25, 0.18 + 0.07 * sin(anim * 0.5)), 1.0)
	forma(c, p.tipo, f, anim)
	# pontinhos de nível (fora da escala da peça)
	if p.nivel > 0:
		var off: Vector2
		match s:
			0:
				off = Vector2(0, -70)
			1:
				off = Vector2(-12, -12)
			_:
				off = Vector2(13, -14)
		_tr(c, pos, esc, dir)
		pips(c, off, p.nivel, 2.0, 5.4)
	if p.marcas.size() > 0:
		var moff: Vector2
		match s:
			0:
				moff = Vector2(0, -77)
			1:
				moff = Vector2(-17, -4)
			_:
				moff = Vector2(17, -6)
		_tr(c, pos, esc, dir)
		pontos_marcas(c, moff, p.marcas, 2.5, 6.2)

static func _slot_fantasma(c: CanvasItem, pos: Vector2, s: int, destaque: bool) -> void:
	var cor: Color = Color(0.5, 1.0, 0.6, 0.95) if destaque else Color(1, 1, 1, 0.3)
	# desenha no espaço local atual (o chamador já definiu o transform)
	var r: float = 14.0 if s != 1 else 15.0
	for i in 10:
		var a: float = TAU * i / 10.0
		c.draw_arc(pos, r, a, a + 0.38, 5, cor, 1.8)
	if destaque:
		c.draw_circle(pos, r - 1.0, Color(0.5, 1.0, 0.6, 0.25))
	var g: Color = Color(cor.r, cor.g, cor.b, cor.a * 0.8)
	match s:
		0:
			c.draw_arc(pos + Vector2(0, 2), 6.0, PI, TAU, 8, g, 1.8)
		1:
			c.draw_rect(Rect2(pos + Vector2(-5, -6), Vector2(10, 12)), g, false, 1.6)
		_:
			c.draw_circle(pos, 3.0, g)

## false volta aos ícones antigos, em traço liso (Desenho.forma).
const ICONE_PIXEL := true

# ------------------------------------------------------------------ ícone (guarda-roupa / voando)
static func icone(c: CanvasItem, tipo: int, centro: Vector2, tam: float, nivel: int = 0, f: float = 0.0, anim: float = 0.0, marcas: Array = [], raridade: int = 0) -> void:
	if ICONE_PIXEL:
		# o ícone é a própria roupa em pixel art que o gato veste (RoupaGato), ampliada para caber
		var cx: Rect2 = IconeDados.CAIXA[tipo] if tipo < IconeDados.CAIXA.size() else RoupaGatoE.caixa(tipo)
		var px: float = tam * 0.92 / maxf(9.0, maxf(cx.size.x, cx.size.y))
		if raridade > 0:
			c.draw_set_transform(centro, 0.0, Vector2(tam / 30.0, tam / 30.0))
			brilho_raridade(c, Vector2.ZERO, 17.0, raridade)
		c.draw_set_transform(centro - (cx.position + cx.size * 0.5) * px, 0.0, Vector2(px, px))
		RoupaGato.desenhar(c, tipo, f, anim)
		resetar(c)
	else:
		var sc: float = tam / 30.0
		c.draw_set_transform(centro - icon_off(tipo) * sc, 0.0, Vector2(sc, sc))
		if raridade > 0:
			brilho_raridade(c, icon_off(tipo), 17.0, raridade)
		forma(c, tipo, f, anim)
		resetar(c)
	if nivel > 0:
		pips(c, centro + Vector2(0, tam * 0.5 + 3.0), nivel, 2.0, 5.2)
	if marcas.size() > 0:
		pontos_marcas(c, centro + Vector2(-tam * 0.62, -2), marcas, maxf(2.6, tam * 0.115), tam * 0.29, true)

# ------------------------------------------------------------------ torre de blocos
const LETRAS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const COR_BLOCOS: Array[Color] = [Color(0.86, 0.32, 0.28), Color(0.3, 0.52, 0.84), Color(0.96, 0.76, 0.28), Color(0.36, 0.7, 0.4), Color(0.93, 0.56, 0.24)]

static func rect_tijolo(i: int, base: Vector2, esc: float) -> Rect2:
	var col: int = i % TIJ_COLS
	var row: int = i / TIJ_COLS
	return Rect2(base.x + col * TIJ_W * esc, base.y - (row + 1) * TIJ_H * esc, TIJ_W * esc, TIJ_H * esc)

## Cor do bloco i (cinco cores primárias suaves; vizinhos diferem).
static func cor_tijolo(i: int) -> Color:
	return COR_BLOCOS[(i + i / TIJ_COLS) % COR_BLOCOS.size()]

static func letra_tijolo(i: int) -> String:
	return LETRAS[(i * 7) % 26]

## Bloco de madeira pintado, com disco creme e letra.
static func bloco(c: CanvasItem, r: Rect2, cor: Color, letra: String, alfa: float = 1.0) -> void:
	var k: float = r.size.y / TIJ_H
	var ctn: Color = cor.darkened(0.55)
	ctn.a = alfa
	cor.a = alfa
	c.draw_rect(r, ctn)
	var ri: Rect2 = r.grow(-1.6 * k)
	c.draw_rect(ri, cor)
	c.draw_rect(Rect2(ri.position, Vector2(ri.size.x, ri.size.y * 0.2)), Color(1, 1, 1, 0.28 * alfa))
	c.draw_rect(Rect2(ri.position.x, ri.end.y - ri.size.y * 0.18, ri.size.x, ri.size.y * 0.18), Color(0, 0, 0, 0.2 * alfa))
	var ce: Vector2 = r.get_center()
	var rr: float = r.size.y * 0.33
	c.draw_circle(ce, rr, Color(0.99, 0.95, 0.82, alfa))
	if letra != "":
		var tam: int = maxi(8, int(r.size.y * 0.6))
		var tc: Color = cor.darkened(0.4)
		tc.a = alfa
		texto(c, letra, Vector2(ce.x - rr, ce.y + tam * 0.35), tam, tc, rr * 2.0)

static func torre(c: CanvasItem, base: Vector2, n: int, esc: float, pulso: float = 0.0) -> void:
	for i in n:
		var r: Rect2 = rect_tijolo(i, base, esc)
		bloco(c, r, b(cor_tijolo(i), pulso), letra_tijolo(i))
	# bandeirinha de pano no topo
	if n > 0:
		var topo: Rect2 = rect_tijolo(n - 1, base, esc)
		var cx: float = base.x + TIJ_COLS * TIJ_W * esc * 0.5
		var linha_y: float = topo.position.y
		c.draw_line(Vector2(cx, linha_y), Vector2(cx, linha_y - 38 * esc), Color(0.88, 0.76, 0.55), 2.5 * esc)
		c.draw_colored_polygon(PackedVector2Array([Vector2(cx, linha_y - 38 * esc), Vector2(cx + 22 * esc, linha_y - 31 * esc), Vector2(cx, linha_y - 24 * esc)]), Color(0.9, 0.35, 0.3))
		c.draw_dashed_line(Vector2(cx + 2 * esc, linha_y - 35 * esc), Vector2(cx + 15 * esc, linha_y - 31 * esc), Color(1, 0.9, 0.7), 1.0, 3.0)
