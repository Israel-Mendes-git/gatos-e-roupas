class_name DesenhoFC
extends RefCounted
## Desenho das peças das fantasias de referência, tipos 68 a 83.

const CTN := Color(0.1, 0.07, 0.12)

static func _p(c: CanvasItem, pts: Array, cor: Color, f: float, larg: float = 1.2) -> void:
	var v := PackedVector2Array()
	for p in pts:
		v.append(p)
	c.draw_colored_polygon(v, Desenho.b(cor, f))
	v.append(v[0])
	c.draw_polyline(v, Desenho.b(CTN, f), larg)

static func _disco(c: CanvasItem, p: Vector2, r: float, cor: Color, f: float) -> void:
	c.draw_circle(p, r + 1.0, Desenho.b(CTN, f))
	c.draw_circle(p, r, Desenho.b(cor, f))

## Floco de neve de seis pontas.
static func _floco(c: CanvasItem, p: Vector2, r: float, cor: Color, f: float) -> void:
	for k in 6:
		var a: float = -PI * 0.5 + k * PI / 3.0
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x)
		var pt: Vector2 = p + d * r
		var m: Vector2 = p + d * r * 0.6
		c.draw_line(p, pt, Desenho.b(CTN, f), 3.2)
		c.draw_line(m, m + (d + n) * r * 0.28, Desenho.b(CTN, f), 3.0)
		c.draw_line(m, m + (d - n) * r * 0.28, Desenho.b(CTN, f), 3.0)
	for k in 6:
		var a2: float = -PI * 0.5 + k * PI / 3.0
		var d2 := Vector2(cos(a2), sin(a2))
		var n2 := Vector2(-d2.y, d2.x)
		var m2: Vector2 = p + d2 * r * 0.6
		c.draw_line(p, p + d2 * r, Desenho.b(cor, f), 1.6)
		c.draw_line(m2, m2 + (d2 + n2) * r * 0.28, Desenho.b(cor, f), 1.4)
		c.draw_line(m2, m2 + (d2 - n2) * r * 0.28, Desenho.b(cor, f), 1.4)
	c.draw_circle(p, r * 0.18, Desenho.b(Color.WHITE, f))

## Desenha a peça na origem do transform atual (mesma convenção de Desenho.forma).
static func forma(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	var verm := Color(0.82, 0.14, 0.16)
	var ouro := Color(1.0, 0.8, 0.22)
	var prata := Color(0.82, 0.86, 0.92)
	var gelo := Color(0.62, 0.86, 1.0)
	var roxo := Color(0.5, 0.25, 0.7)
	var verde := Color(0.3, 0.78, 0.35)
	match tipo:
		Pecas.Tipo.CAPACETE_FERRO:
			_p(c, [Vector2(-9, 6), Vector2(-9, -3), Vector2(-5, -9), Vector2(5, -9), Vector2(9, -3), Vector2(9, 6), Vector2(6, 13), Vector2(-6, 13)], verm, f)
			_p(c, [Vector2(-6.5, -4), Vector2(6.5, -4), Vector2(7, 5), Vector2(4, 12), Vector2(-4, 12), Vector2(-7, 5)], ouro, f)
			_p(c, [Vector2(-6, 0), Vector2(-1, 0.8), Vector2(-1.5, 3), Vector2(-6, 2.2)], Color.WHITE, f, 0.8)
			_p(c, [Vector2(6, 0), Vector2(1, 0.8), Vector2(1.5, 3), Vector2(6, 2.2)], Color.WHITE, f, 0.8)
			c.draw_line(Vector2(0, 5), Vector2(0, 10), Desenho.b(ouro.darkened(0.4), f), 1.0)
			c.draw_line(Vector2(-3, 8), Vector2(3, 8), Desenho.b(ouro.darkened(0.4), f), 1.0)
			c.draw_line(Vector2(-4, -7), Vector2(0, -8), Desenho.b(Color(1, 0.6, 0.55), f), 1.4)
		Pecas.Tipo.ARMADURA_FERRO:
			_p(c, [Vector2(-9, -10), Vector2(9, -10), Vector2(9, 3), Vector2(5, 10), Vector2(-5, 10), Vector2(-9, 3)], verm, f)
			_p(c, [Vector2(-9, -10), Vector2(-3, -10), Vector2(-4, -5), Vector2(-9, -4)], ouro, f, 0.8)
			_p(c, [Vector2(9, -10), Vector2(3, -10), Vector2(4, -5), Vector2(9, -4)], ouro, f, 0.8)
			_p(c, [Vector2(-5, 4), Vector2(5, 4), Vector2(4, 9), Vector2(-4, 9)], ouro, f, 0.8)
			c.draw_circle(Vector2(0, -2), 3.8, Desenho.b(CTN, f))
			c.draw_circle(Vector2(0, -2), 2.8, Desenho.b(Color(0.7, 0.95, 1.0), f))
			c.draw_circle(Vector2(0, -2), 1.3, Desenho.b(Color.WHITE, f))
			c.draw_line(Vector2(-6, -7), Vector2(-6, 1), Desenho.b(Color(1, 0.5, 0.5), f), 1.2)
		Pecas.Tipo.REPULSOR:
			var pul: float = 0.5 + 0.5 * sin(anim * 8.0)
			_p(c, [Vector2(-5, 2), Vector2(-5.5, -10), Vector2(0, -15), Vector2(7, -12), Vector2(7.5, 2)], verm, f)
			_p(c, [Vector2(-6, 2), Vector2(8, 2), Vector2(8, 7), Vector2(-6, 7)], ouro, f)
			c.draw_circle(Vector2(1, -7), 7.5 + pul * 2.0, Desenho.b(Color(0.5, 0.85, 1.0, 0.28 + 0.2 * pul), f))
			_disco(c, Vector2(1, -7), 4.6, Color(0.7, 0.93, 1.0), f)
			c.draw_circle(Vector2(1, -7), 2.4 + pul * 0.8, Desenho.b(Color.WHITE, f))
		Pecas.Tipo.REATOR:
			c.draw_circle(Vector2.ZERO, 9.0 + sin(anim * 5.0) * 0.5, Desenho.b(Color(0.45, 0.8, 1.0, 0.3), f))
			_disco(c, Vector2.ZERO, 7.5, Color(0.6, 0.64, 0.7), f)
			c.draw_circle(Vector2.ZERO, 5.6, Desenho.b(Color(0.35, 0.65, 0.9), f))
			c.draw_circle(Vector2.ZERO, 4.2, Desenho.b(Color(0.72, 0.95, 1.0), f))
			_p(c, [Vector2(0, -3), Vector2(2.8, 2), Vector2(-2.8, 2)], Color.WHITE, f, 0.6)
		Pecas.Tipo.ELMO_ALADO:
			for s in [-1.0, 1.0]:
				_p(c, [Vector2(s * 8, -4), Vector2(s * 15, -13), Vector2(s * 22, -14), Vector2(s * 18, -8), Vector2(s * 23, -6), Vector2(s * 17, -2), Vector2(s * 9, 0)], Color(0.97, 0.97, 1.0), f)
				c.draw_line(Vector2(s * 10, -3), Vector2(s * 20, -9), Desenho.b(Color(0.7, 0.78, 0.9), f), 1.0)
			var dome: Array = []
			for i in 9:
				var a: float = PI + PI * i / 8.0
				dome.append(Vector2(cos(a) * 9.0, 2.0 + sin(a) * 11.0))
			_p(c, dome, prata, f)
			c.draw_rect(Rect2(-9.5, -1, 19, 4), Desenho.b(Color(0.6, 0.66, 0.76), f))
			c.draw_rect(Rect2(-9.5, -1, 19, 4), Desenho.b(CTN, f), false, 1.0)
			c.draw_line(Vector2(-4, -6), Vector2(-1, -8), Desenho.b(Color.WHITE, f), 1.6)
		Pecas.Tipo.CAPA_RUBRA:
			var cap := Color(0.8, 0.1, 0.14)
			_p(c, [Vector2(-11, -10), Vector2(11, -10), Vector2(14, 10), Vector2(6, 8), Vector2(0, 11), Vector2(-6, 8), Vector2(-14, 10)], cap, f)
			for x in [-6.0, 0.0, 6.0]:
				c.draw_line(Vector2(x, -6), Vector2(x * 1.5, 9), Desenho.b(cap.darkened(0.35), f), 1.4)
			c.draw_line(Vector2(-9, -9), Vector2(9, -9), Desenho.b(prata.darkened(0.3), f), 1.4)
			c.draw_line(Vector2(-9, -7), Vector2(-4, -3), Desenho.b(Color(1, 0.5, 0.5), f), 1.2)
			_disco(c, Vector2(-9, -9), 3.0, prata, f)
			_disco(c, Vector2(9, -9), 3.0, prata, f)
			c.draw_circle(Vector2(-9.7, -9.8), 1.0, Desenho.b(Color.WHITE, f))
			c.draw_circle(Vector2(8.3, -9.8), 1.0, Desenho.b(Color.WHITE, f))
		Pecas.Tipo.MARTELO:
			var cinza := Color(0.58, 0.62, 0.68)
			c.draw_line(Vector2(0, 8), Vector2(2, -9), Desenho.b(CTN, f), 5.0)
			c.draw_line(Vector2(0, 8), Vector2(2, -9), Desenho.b(Color(0.5, 0.3, 0.16), f), 3.2)
			for y in [2.0, -2.0]:
				c.draw_line(Vector2(-1.5, y + 1), Vector2(1.5, y - 1), Desenho.b(Color(0.3, 0.16, 0.08), f), 1.0)
			_p(c, [Vector2(-8, -20), Vector2(11, -20), Vector2(11, -9), Vector2(-8, -9)], cinza, f)
			c.draw_rect(Rect2(-8, -20, 19, 3), Desenho.b(Color(0.82, 0.86, 0.92), f))
			c.draw_rect(Rect2(-8, -12, 19, 3), Desenho.b(cinza.darkened(0.25), f))
			c.draw_rect(Rect2(-3, -20, 2, 11), Desenho.b(cinza.darkened(0.3), f))
			var fa: float = 0.6 + 0.4 * sin(anim * 10.0)
			c.draw_line(Vector2(13, -26), Vector2(13, -22 - fa * 2), Desenho.b(Color(1, 0.95, 0.4), f), 1.6)
			c.draw_line(Vector2(10, -24), Vector2(16, -24), Desenho.b(Color(1, 0.95, 0.4), f), 1.6)
			c.draw_circle(Vector2(13, -24), 1.2, Desenho.b(Color.WHITE, f))
		Pecas.Tipo.CINTURAO:
			_p(c, [Vector2(-11, -3.5), Vector2(11, -3.5), Vector2(11, 3.5), Vector2(-11, 3.5)], ouro, f)
			for x in [-9.0, -6.5, 6.5, 9.0]:
				c.draw_line(Vector2(x, -2), Vector2(x, 2), Desenho.b(ouro.darkened(0.4), f), 1.0)
			c.draw_line(Vector2(-10, -2.3), Vector2(-3, -2.3), Desenho.b(Color(1, 0.95, 0.6), f), 1.0)
			_disco(c, Vector2.ZERO, 4.6, Color(1.0, 0.9, 0.4), f)
			c.draw_circle(Vector2.ZERO, 2.2, Desenho.b(ouro.darkened(0.25), f))
			c.draw_circle(Vector2(-1.4, -1.4), 0.9, Desenho.b(Color.WHITE, f))
		Pecas.Tipo.TIARA:
			var loira := Color(1.0, 0.85, 0.35)
			# trança descendo de lado
			for i in 5:
				var p := Vector2(-9.5 - i * 0.4 + sin(i * 1.7) * 1.2, 3.0 + i * 3.6)
				c.draw_circle(p, 2.9 - i * 0.2, Desenho.b(CTN, f))
				c.draw_circle(p, 2.1 - i * 0.2, Desenho.b(loira if i % 2 == 0 else loira.darkened(0.15), f))
			c.draw_circle(Vector2(-11.5, 21), 2.0, Desenho.b(gelo, f))
			_p(c, [Vector2(-9, 3), Vector2(-9, -1), Vector2(9, -1), Vector2(9, 3), Vector2(0, 5)], Color(0.7, 0.88, 1.0), f)
			var xs: Array = [-7.0, -3.5, 0.0, 3.5, 7.0]
			var hs: Array = [5.0, 8.0, 12.0, 8.0, 5.0]
			for i in 5:
				_p(c, [Vector2(xs[i] - 2.0, -1), Vector2(xs[i], -1 - hs[i]), Vector2(xs[i] + 2.0, -1)], Color(0.85, 0.96, 1.0) if i % 2 == 0 else gelo, f, 1.0)
			c.draw_circle(Vector2(0, 1.5), 1.3, Desenho.b(Color.WHITE, f))
		Pecas.Tipo.VESTIDO:
			var azul := Color(0.55, 0.8, 0.97)
			_p(c, [Vector2(-9, -10), Vector2(9, -10), Vector2(13, 11), Vector2(-13, 11)], Color(0.75, 0.92, 1.0, 0.55), f, 0.8)
			_p(c, [Vector2(-6, -10), Vector2(6, -10), Vector2(5, -2), Vector2(10, 10), Vector2(-10, 10), Vector2(-5, -2)], azul, f)
			c.draw_rect(Rect2(-5, -3, 10, 2), Desenho.b(Color(0.85, 0.96, 1.0), f))
			c.draw_line(Vector2(-4, 4), Vector2(-7, 9), Desenho.b(azul.lightened(0.3), f), 1.2)
			c.draw_line(Vector2(4, 4), Vector2(7, 9), Desenho.b(azul.darkened(0.2), f), 1.2)
			for q in [Vector2(-3, -7), Vector2(4, 3), Vector2(-5, 7), Vector2(2, 8)]:
				c.draw_line(q + Vector2(-1.5, 0), q + Vector2(1.5, 0), Desenho.b(Color.WHITE, f), 1.0)
				c.draw_line(q + Vector2(0, -1.5), q + Vector2(0, 1.5), Desenho.b(Color.WHITE, f), 1.0)
		Pecas.Tipo.CETRO_GELO:
			c.draw_line(Vector2(0, 9), Vector2(1, -9), Desenho.b(CTN, f), 4.4)
			c.draw_line(Vector2(0, 9), Vector2(1, -9), Desenho.b(Color(0.75, 0.88, 1.0), f), 2.6)
			c.draw_line(Vector2(-2.5, -6), Vector2(4.5, -6), Desenho.b(prata, f), 2.0)
			_floco(c, Vector2(1, -18), 9.0, Color(0.85, 0.96, 1.0), f)
		Pecas.Tipo.FLOCO:
			c.draw_circle(Vector2.ZERO, 11.0, Desenho.b(Color(0.6, 0.85, 1.0, 0.22), f))
			_floco(c, Vector2.ZERO, 10.0, Color(0.88, 0.97, 1.0), f)
		Pecas.Tipo.CAPACETE_BOLHA:
			c.draw_circle(Vector2(0, 5), 12.0, Desenho.b(CTN, f))
			c.draw_circle(Vector2(0, 5), 10.8, Desenho.b(roxo, f))
			c.draw_circle(Vector2(0, 6), 6.5, Desenho.b(Color(0.96, 0.8, 0.65), f))
			c.draw_circle(Vector2(0, 5), 9.0, Desenho.b(Color(0.7, 0.9, 1.0, 0.22), f))
			c.draw_arc(Vector2(0, 5), 9.0, 0.0, TAU, 20, Desenho.b(Color(0.85, 0.97, 1.0, 0.9), f), 1.2)
			c.draw_arc(Vector2(0, 5), 6.5, PI * 1.1, PI * 1.45, 6, Desenho.b(Color.WHITE, f), 1.8)
			c.draw_rect(Rect2(-10, 12, 20, 3.5), Desenho.b(Color.WHITE, f))
			c.draw_rect(Rect2(-10, 12, 20, 3.5), Desenho.b(CTN, f), false, 1.0)
			c.draw_circle(Vector2(0, 0), 1.0, Desenho.b(verde, f))
		Pecas.Tipo.TRAJE:
			_p(c, [Vector2(-9, -10), Vector2(9, -10), Vector2(9, 10), Vector2(-9, 10)], Color(0.96, 0.96, 1.0), f)
			_p(c, [Vector2(-9, -10), Vector2(-5, -10), Vector2(-5, 4), Vector2(-9, 4)], roxo, f, 0.8)
			_p(c, [Vector2(9, -10), Vector2(5, -10), Vector2(5, 4), Vector2(9, 4)], roxo, f, 0.8)
			_p(c, [Vector2(-5, -9), Vector2(5, -9), Vector2(5, 3), Vector2(-5, 3)], verde, f, 0.8)
			var bc: Array = [Color(0.9, 0.2, 0.25), Color(1.0, 0.85, 0.2), Color(0.3, 0.5, 0.95)]
			for i in 3:
				c.draw_circle(Vector2(-3 + i * 3.0, -4), 1.3, Desenho.b(bc[i], f))
				c.draw_circle(Vector2(-3.3 + i * 3.0, -4.3), 0.4, Desenho.b(Color.WHITE, f))
			c.draw_rect(Rect2(-9, 6, 18, 2.5), Desenho.b(roxo, f))
		Pecas.Tipo.LASER:
			var branco := Color(0.94, 0.96, 1.0)
			var br: float = 0.5 + 0.5 * sin(anim * 9.0)
			_p(c, [Vector2(-3, 4), Vector2(3, 4), Vector2(3, -2), Vector2(-3, -2)], roxo, f)
			_p(c, [Vector2(-5, -2), Vector2(6, -2), Vector2(6, -15), Vector2(-5, -15)], branco, f)
			c.draw_rect(Rect2(-5, -9, 11, 3), Desenho.b(verde, f))
			_p(c, [Vector2(-3, -15), Vector2(4, -15), Vector2(3, -20), Vector2(-2, -20)], Color(0.35, 0.3, 0.42), f, 1.0)
			c.draw_circle(Vector2(0.5, -24), 4.0 + br, Desenho.b(Color(1, 0.2, 0.2, 0.3), f))
			_disco(c, Vector2(0.5, -23), 2.6, Color(1.0, 0.25, 0.25), f)
			c.draw_circle(Vector2(0, -23.8), 0.9, Desenho.b(Color.WHITE, f))
		Pecas.Tipo.JATO:
			var fl: float = 5.0 + 3.0 * sin(anim * 14.0)
			_p(c, [Vector2(-3, 6), Vector2(0, 6 + fl + 3), Vector2(3, 6)], Color(1.0, 0.55, 0.15), f, 0.8)
			_p(c, [Vector2(-1.5, 6), Vector2(0, 6 + fl), Vector2(1.5, 6)], Color(1.0, 0.92, 0.4), f, 0.5)
			for s in [-1.0, 1.0]:
				_p(c, [Vector2(s * 5, -4), Vector2(s * 12, -10), Vector2(s * 13, 1), Vector2(s * 5, 4)], Color.WHITE, f)
				c.draw_line(Vector2(s * 7, -1), Vector2(s * 12, -5), Desenho.b(verde, f), 1.6)
				c.draw_line(Vector2(s * 7, 2), Vector2(s * 12.5, -2), Desenho.b(roxo, f), 1.6)
			_p(c, [Vector2(-5, -8), Vector2(5, -8), Vector2(5, 6), Vector2(-5, 6)], Color(0.94, 0.96, 1.0), f)
			c.draw_rect(Rect2(-5, -2, 10, 2.5), Desenho.b(roxo, f))
			c.draw_circle(Vector2(0, -5), 1.3, Desenho.b(Color(0.9, 0.25, 0.25), f))

## Ajuste para centralizar a peça num ícone (mesma convenção de Desenho.ICON_OFF).
static func off(tipo: int) -> Vector2:
	match tipo:
		Pecas.Tipo.CAPACETE_FERRO: return Vector2(0, 2)
		Pecas.Tipo.REPULSOR: return Vector2(1, -5)
		Pecas.Tipo.ELMO_ALADO: return Vector2(0, -6)
		Pecas.Tipo.MARTELO: return Vector2(1.5, -8)
		Pecas.Tipo.TIARA: return Vector2(-2, 5)
		Pecas.Tipo.CETRO_GELO: return Vector2(1, -6)
		Pecas.Tipo.CAPACETE_BOLHA: return Vector2(0, 4)
		Pecas.Tipo.LASER: return Vector2(0, -10)
		Pecas.Tipo.JATO: return Vector2(0, 3)
	return Vector2.ZERO
