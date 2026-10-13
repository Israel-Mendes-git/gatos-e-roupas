class_name DesenhoFB
extends RefCounted
## Desenho das peças das fantasias de referência, tipos 52 a 67
## (Lorde Sombrio, Herói do Bosque, Tartaruga Ninja, Ouriço Veloz).

const CTN := Color(0.07, 0.06, 0.09)

# ------------------------------------------------------------------ auxiliares
static func _p(c: CanvasItem, pts: Array, cor: Color, f: float, larg: float = 1.2) -> void:
	Desenho._pol(c, PackedVector2Array(pts), cor, f, larg)

static func _hex(cx: float, cy: float, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 6:
		var a: float = PI / 6.0 + k * PI / 3.0
		pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	return pts

static func _brilho(c: CanvasItem, a: Vector2, z: Vector2, f: float, alfa: float = 0.7) -> void:
	c.draw_line(a, z, Desenho.b(Color(1, 1, 1, alfa), f), 1.0)

## Desenha a peça na origem do transform atual (mesma convenção de Desenho.forma).
static func forma(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	match tipo:
		Pecas.Tipo.ELMO_SOMBRIO:
			var preto := Color(0.13, 0.13, 0.18)
			# cimeira e sino do elmo
			_p(c, [Vector2(-10, 14), Vector2(-11, 5), Vector2(-7, -2), Vector2(0, -6), Vector2(7, -2), Vector2(11, 5), Vector2(10, 14), Vector2(5, 12), Vector2(-5, 12)], preto, f)
			_p(c, [Vector2(-1.5, -6), Vector2(1.5, -6), Vector2(2.5, 6), Vector2(-2.5, 6)], Color(0.22, 0.22, 0.3), f, 0.8)
			# viseira
			_p(c, [Vector2(-8, 4), Vector2(8, 4), Vector2(7, 10), Vector2(2.5, 12), Vector2(-2.5, 12), Vector2(-7, 10)], Color(0.05, 0.05, 0.08), f)
			c.draw_line(Vector2(-6, 7), Vector2(-2, 7.6), Desenho.b(Color(0.8, 0.85, 0.95), f), 1.4)
			c.draw_line(Vector2(6, 7), Vector2(2, 7.6), Desenho.b(Color(0.8, 0.85, 0.95), f), 1.4)
			c.draw_line(Vector2(-1, 9.5), Vector2(1, 9.5), Desenho.b(Color(0.4, 0.4, 0.5), f), 1.2)
			_brilho(c, Vector2(-7.5, 1.5), Vector2(-4.5, -2.5), f)
		Pecas.Tipo.ARMADURA_SOMBRIA:
			var preto := Color(0.14, 0.14, 0.19)
			_p(c, [Vector2(-11, -8), Vector2(-5, -10), Vector2(5, -10), Vector2(11, -8), Vector2(9, 0), Vector2(8, 10), Vector2(-8, 10), Vector2(-9, 0)], preto, f)
			c.draw_rect(Rect2(-8, 5, 16, 3), Desenho.b(Color(0.3, 0.3, 0.36), f))
			# painel de botões
			_p(c, [Vector2(-5.5, -4), Vector2(5.5, -4), Vector2(5.5, 2.5), Vector2(-5.5, 2.5)], Color(0.45, 0.46, 0.52), f, 1.0)
			c.draw_circle(Vector2(-3.4, -1.9), 1.2, Desenho.b(Color(0.95, 0.2, 0.2), f))
			c.draw_circle(Vector2(0, -1.9), 1.2, Desenho.b(Color(0.3, 0.9, 0.35), f))
			c.draw_circle(Vector2(3.4, -1.9), 1.2, Desenho.b(Color(1.0, 0.85, 0.2), f))
			c.draw_circle(Vector2(-1.7, 0.9), 1.0, Desenho.b(Color(0.3, 0.55, 1.0), f))
			c.draw_circle(Vector2(1.7, 0.9), 1.0, Desenho.b(Color(0.95, 0.2, 0.2), f))
			_brilho(c, Vector2(-8.5, -7), Vector2(-7.8, -1), f, 0.5)
		Pecas.Tipo.SABRE_RUBRO:
			var pulso: float = 0.5 + 0.5 * sin(anim * 5.0)
			var ponta := Vector2(3.5, -29)
			c.draw_line(Vector2(0, -4), ponta, Desenho.b(Color(1, 0.1, 0.1, 0.18 + 0.2 * pulso), f), 8.0 + 2.0 * pulso)
			c.draw_line(Vector2(0, -4), ponta, Desenho.b(Color(1, 0.15, 0.12, 0.6), f), 4.6)
			c.draw_line(Vector2(0, -4), ponta, Desenho.b(Color(1, 0.55, 0.5), f), 2.4)
			c.draw_circle(ponta, 1.6, Desenho.b(Color(1, 0.55, 0.5), f))
			# empunhadura
			c.draw_line(Vector2(0, 7), Vector2(0, -4), Desenho.b(CTN, f), 5.0)
			c.draw_line(Vector2(0, 6), Vector2(0, -3), Desenho.b(Color(0.62, 0.64, 0.7), f), 3.0)
			c.draw_rect(Rect2(-2.5, -5.5, 5, 2.5), Desenho.b(Color(0.85, 0.86, 0.92), f))
			c.draw_line(Vector2(-1.5, 2), Vector2(1.5, 2), Desenho.b(Color(0.3, 0.3, 0.36), f), 1.0)
			c.draw_line(Vector2(-1.5, -0.5), Vector2(1.5, -0.5), Desenho.b(Color(0.3, 0.3, 0.36), f), 1.0)
		Pecas.Tipo.RESPIRADOR:
			var cinza := Color(0.55, 0.57, 0.62)
			_p(c, [Vector2(-7, -6), Vector2(7, -6), Vector2(0, 7)], cinza, f)
			for k in 3:
				var yy: float = -3.0 + k * 2.6
				var h: float = 5.6 - (yy + 6.0) * 0.44
				c.draw_line(Vector2(-h, yy), Vector2(h, yy), Desenho.b(Color(0.12, 0.12, 0.16), f), 1.1)
			c.draw_line(Vector2(0, -5), Vector2(0, 5), Desenho.b(Color(0.12, 0.12, 0.16), f), 1.0)
			c.draw_rect(Rect2(-7, -8, 14, 2.5), Desenho.b(Color(0.3, 0.3, 0.36), f))
			_brilho(c, Vector2(-5.5, -4.5), Vector2(-1.5, 3), f, 0.5)
		Pecas.Tipo.GORRO:
			var verde := Color(0.2, 0.62, 0.22)
			var louro := Color(0.98, 0.84, 0.3)
			# gorro comprido caído para trás
			_p(c, [Vector2(9, 1), Vector2(8, -5), Vector2(3, -10), Vector2(-4, -12), Vector2(-12, -10), Vector2(-19, -4), Vector2(-24, 4), Vector2(-17, 1), Vector2(-12, -3), Vector2(-8, 1)], verde, f)
			c.draw_polyline(PackedVector2Array([Vector2(7, -4), Vector2(2, -8.5), Vector2(-5, -10), Vector2(-13, -7)]), Desenho.b(verde.lightened(0.3), f), 1.2)
			c.draw_circle(Vector2(-24, 4.5), 1.8, Desenho.b(Color(1, 0.95, 0.7), f))
			# faixa e franja loira
			_p(c, [Vector2(-9, -1), Vector2(9, -1), Vector2(9, 2), Vector2(-9, 2)], verde.darkened(0.2), f, 1.0)
			_p(c, [Vector2(-8, 2), Vector2(-3, 2), Vector2(-5, 6)], louro, f, 0.9)
			_p(c, [Vector2(-3, 2), Vector2(3, 2), Vector2(0, 7)], louro, f, 0.9)
			_p(c, [Vector2(3, 2), Vector2(8, 2), Vector2(6, 6)], louro, f, 0.9)
		Pecas.Tipo.TUNICA_VERDE:
			var verde := Color(0.2, 0.62, 0.22)
			_p(c, [Vector2(-10, -8), Vector2(-4, -10), Vector2(4, -10), Vector2(10, -8), Vector2(9, 0), Vector2(11, 10), Vector2(-11, 10), Vector2(-9, 0)], verde, f)
			_p(c, [Vector2(-4, -10), Vector2(4, -10), Vector2(0, -3)], Color(0.95, 0.88, 0.7), f, 1.0)
			c.draw_polyline(PackedVector2Array([Vector2(-4, -10), Vector2(0, -3), Vector2(4, -10)]), Desenho.b(verde.lightened(0.3), f), 1.2)
			c.draw_rect(Rect2(-10, 3, 20, 3.4), Desenho.b(Color(0.45, 0.27, 0.1), f))
			c.draw_rect(Rect2(-2.2, 2.6, 4.4, 4.2), Desenho.b(Color(1, 0.85, 0.25), f))
			c.draw_rect(Rect2(-0.9, 3.8, 1.8, 1.8), Desenho.b(Color(0.45, 0.27, 0.1), f))
			_brilho(c, Vector2(-7, -6), Vector2(-7.5, 0), f, 0.35)
		Pecas.Tipo.ESPADA_LENDARIA:
			var azul := Color(0.2, 0.4, 0.9)
			_p(c, [Vector2(-2.4, -3), Vector2(2.4, -3), Vector2(2.8, -21), Vector2(0, -28), Vector2(-2.8, -21)], Color(0.86, 0.92, 1.0), f)
			c.draw_line(Vector2(0, -4), Vector2(0, -24), Desenho.b(Color(0.6, 0.72, 0.9), f), 1.0)
			_brilho(c, Vector2(-1.5, -6), Vector2(-1.7, -20), f, 0.9)
			c.draw_line(Vector2(0, 7), Vector2(0, -2), Desenho.b(Color(0.4, 0.24, 0.1), f), 3.4)
			c.draw_circle(Vector2(0, 8), 1.8, Desenho.b(azul, f))
			# guarda em asa
			_p(c, [Vector2(0, -1), Vector2(-5, -4), Vector2(-11, -5), Vector2(-9, -1.5), Vector2(-6, 0), Vector2(-3, 1)], azul, f, 1.0)
			_p(c, [Vector2(0, -1), Vector2(5, -4), Vector2(11, -5), Vector2(9, -1.5), Vector2(6, 0), Vector2(3, 1)], azul, f, 1.0)
			c.draw_circle(Vector2(0, -1), 2.2, Desenho.b(Color(1.0, 0.85, 0.2), f))
			c.draw_circle(Vector2(-0.5, -1.6), 0.7, Desenho.b(Color.WHITE, f))
		Pecas.Tipo.OCARINA:
			var azul := Color(0.25, 0.5, 0.92)
			# bocal
			_p(c, [Vector2(-9, -2), Vector2(-5, -5), Vector2(-3, -2), Vector2(-6, 0)], azul.darkened(0.15), f, 1.0)
			# corpo ovalado
			_p(c, [Vector2(-5, -3), Vector2(-1, -9), Vector2(6, -10), Vector2(11, -6), Vector2(10, 0), Vector2(5, 3), Vector2(-1, 2)], azul, f)
			for p in [Vector2(2, -6), Vector2(5.5, -7), Vector2(8, -4.5), Vector2(5, -2.5)]:
				c.draw_circle(p, 1.15, Desenho.b(Color(0.08, 0.15, 0.4), f))
			c.draw_circle(Vector2(0.5, -3.5), 0.9, Desenho.b(Color(0.08, 0.15, 0.4), f))
			_brilho(c, Vector2(-1, -6), Vector2(2, -8.5), f, 0.8)
		Pecas.Tipo.BANDANA:
			var lar := Color(0.97, 0.52, 0.12)
			var sw: float = sin(anim * 4.0) * 1.5
			# pontas soltas atrás
			_p(c, [Vector2(-9, 7), Vector2(-16, 4 + sw), Vector2(-24, 1 + sw * 1.6), Vector2(-20, 7 + sw), Vector2(-9, 9)], lar.darkened(0.1), f, 1.0)
			_p(c, [Vector2(-9, 9), Vector2(-16, 10 + sw), Vector2(-24, 15 + sw * 1.6), Vector2(-18, 16 + sw), Vector2(-9, 12)], lar, f, 1.0)
			c.draw_circle(Vector2(-9.5, 9), 2.4, Desenho.b(lar.darkened(0.25), f))
			# faixa com furos de olho
			_p(c, [Vector2(-10, 5), Vector2(10, 5), Vector2(10.5, 13), Vector2(-10.5, 13)], lar, f)
			for xx in [-4.0, 4.0]:
				c.draw_colored_polygon(Desenho._elipse(xx, 9.2, 3.2, 2.5, 12), Desenho.b(Color(0.05, 0.05, 0.08), f))
				c.draw_circle(Vector2(xx, 9.2), 1.6, Desenho.b(Color.WHITE, f))
				c.draw_circle(Vector2(xx + 0.4, 9.3), 0.8, Desenho.b(CTN, f))
			c.draw_line(Vector2(-9, 5.9), Vector2(9, 5.9), Desenho.b(lar.lightened(0.35), f), 1.0)
		Pecas.Tipo.CASCO:
			var marrom := Color(0.42, 0.4, 0.17)
			c.draw_colored_polygon(Desenho._elipse(0, 0, 10, 11, 20), Desenho.b(marrom.darkened(0.35), f))
			c.draw_colored_polygon(Desenho._elipse(0, 0, 8.6, 9.6, 20), Desenho.b(marrom, f))
			var placa := Color(0.62, 0.55, 0.24)
			c.draw_colored_polygon(_hex(0, 0, 3.6), Desenho.b(placa, f))
			c.draw_polyline(_hex(0, 0, 3.6) + PackedVector2Array([_hex(0, 0, 3.6)[0]]), Desenho.b(marrom.darkened(0.55), f), 1.0)
			for k in 6:
				var a: float = PI / 6.0 + k * PI / 3.0
				var cen := Vector2(cos(a), sin(a)) * 6.6
				var pol := _hex(cen.x, cen.y, 2.5)
				c.draw_colored_polygon(pol, Desenho.b(placa.darkened(0.12), f))
				c.draw_polyline(pol + PackedVector2Array([pol[0]]), Desenho.b(marrom.darkened(0.55), f), 1.0)
			c.draw_arc(Vector2.ZERO, 10, 0, TAU, 20, Desenho.b(CTN, f), 1.2)
			_brilho(c, Vector2(-5, -6), Vector2(-2.5, -8.5), f, 0.7)
		Pecas.Tipo.NUNCHAKU:
			var m1 := Color(0.62, 0.38, 0.16)
			var sw: float = sin(anim * 4.0) * 1.5
			var junta := Vector2(1.5, -12)
			var ponta2 := Vector2(13 + sw, -4)
			# corrente
			c.draw_polyline(PackedVector2Array([junta, Vector2(6, -16 - sw * 0.3), ponta2 + Vector2(-2, -6)]), Desenho.b(CTN, f), 2.2)
			c.draw_polyline(PackedVector2Array([junta, Vector2(6, -16 - sw * 0.3), ponta2 + Vector2(-2, -6)]), Desenho.b(Color(0.7, 0.72, 0.78), f), 1.0)
			# bastão da mão
			c.draw_line(Vector2(-0.5, 8), junta, Desenho.b(CTN, f), 5.2)
			c.draw_line(Vector2(-0.5, 8), junta, Desenho.b(m1, f), 3.4)
			c.draw_line(Vector2(0.2, 3), Vector2(0.8, -9), Desenho.b(m1.lightened(0.3), f), 1.0)
			# bastão pendurado
			var topo := ponta2 + Vector2(-2, -6)
			c.draw_line(topo, ponta2 + Vector2(1.5, 5), Desenho.b(CTN, f), 5.2)
			c.draw_line(topo, ponta2 + Vector2(1.5, 5), Desenho.b(m1, f), 3.4)
			c.draw_rect(Rect2(-2.2, 3, 3.4, 1.6), Desenho.b(Color(0.85, 0.2, 0.15), f))
		Pecas.Tipo.PIZZA:
			var queijo := Color(1.0, 0.8, 0.25)
			_p(c, [Vector2(-8, -6), Vector2(8, -6), Vector2(1.5, 9), Vector2(-0.5, 9.5)], queijo, f)
			# queijo derretendo
			_p(c, [Vector2(-5, 2), Vector2(-2.5, 4), Vector2(-3.5, 8), Vector2(-5.5, 5)], queijo.lightened(0.15), f, 0.8)
			# borda
			_p(c, [Vector2(-9, -9), Vector2(9, -9), Vector2(8.6, -5.4), Vector2(-8.6, -5.4)], Color(0.82, 0.5, 0.18), f)
			for p in [Vector2(-3.5, -2), Vector2(3, -1.5), Vector2(0, 3)]:
				c.draw_circle(p, 2.0, Desenho.b(Color(0.78, 0.15, 0.12), f))
				c.draw_circle(p + Vector2(-0.5, -0.5), 0.7, Desenho.b(Color(0.95, 0.4, 0.3), f))
				c.draw_arc(p, 2.0, 0, TAU, 8, Desenho.b(Color(0.4, 0.07, 0.07), f), 0.8)
		Pecas.Tipo.TOPETE:
			var az := Color(0.2, 0.35, 0.95)
			# espinhos de trás para frente
			_p(c, [Vector2(-3, 3), Vector2(-9, 5), Vector2(-26, 2)], az.darkened(0.25), f)
			_p(c, [Vector2(0, 1), Vector2(-7, 3), Vector2(-24, -6)], az.darkened(0.1), f)
			_p(c, [Vector2(3, 0), Vector2(-4, 2), Vector2(-19, -13)], az, f)
			_p(c, [Vector2(7, 0), Vector2(0, 1), Vector2(-11, -17)], az.lightened(0.08), f)
			_p(c, [Vector2(10, 2), Vector2(5, -2), Vector2(2, -15)], az.lightened(0.15), f)
			c.draw_colored_polygon(Desenho._elipse(0, 2, 10, 3, 14), Desenho.b(az, f))
			_brilho(c, Vector2(6, -1), Vector2(3, -10), f, 0.6)
		Pecas.Tipo.PELO_AZUL:
			var az := Color(0.2, 0.35, 0.95)
			_p(c, [Vector2(-10, -8), Vector2(-4, -10), Vector2(4, -10), Vector2(10, -8), Vector2(11, 0), Vector2(8, 10), Vector2(-8, 10), Vector2(-11, 0)], az, f)
			# pelos arrepiados nas bordas
			for k in 4:
				var yy: float = -6.0 + k * 5.0
				c.draw_colored_polygon(PackedVector2Array([Vector2(-10.5, yy), Vector2(-14, yy + 1.5), Vector2(-10.2, yy + 3)]), Desenho.b(az, f))
				c.draw_colored_polygon(PackedVector2Array([Vector2(10.5, yy), Vector2(14, yy + 1.5), Vector2(10.2, yy + 3)]), Desenho.b(az, f))
			# barriga bege
			var bar := Desenho._elipse(0, 2, 6.2, 7.2, 14)
			c.draw_colored_polygon(bar, Desenho.b(Color(0.98, 0.82, 0.62), f))
			c.draw_polyline(bar + PackedVector2Array([bar[0]]), Desenho.b(Color(0.5, 0.35, 0.2), f), 1.0)
			_brilho(c, Vector2(-8, -6), Vector2(-8.5, -1), f, 0.4)
		Pecas.Tipo.LUVAS:
			var br := Color(0.97, 0.97, 1.0)
			# punho
			_p(c, [Vector2(-5, 1), Vector2(-5.5, -9), Vector2(-3, -13), Vector2(4, -13), Vector2(6.5, -9), Vector2(6, 1)], br, f)
			for yy in [-10.0, -7.0, -4.0]:
				c.draw_line(Vector2(-4.8, yy), Vector2(6, yy), Desenho.b(Color(0.6, 0.62, 0.72), f), 1.0)
			_p(c, [Vector2(-5, -3), Vector2(-9, -6), Vector2(-8, -10), Vector2(-5, -8)], br, f, 1.0)
			# punho da luva
			_p(c, [Vector2(-5.5, 1), Vector2(6.5, 1), Vector2(6.5, 6), Vector2(-5.5, 6)], Color(0.95, 0.85, 0.3), f, 1.0)
			c.draw_circle(Vector2(0.5, 3.5), 1.1, Desenho.b(Color(0.85, 0.15, 0.15), f))
			_brilho(c, Vector2(-2, -11), Vector2(-3, -6), f, 0.0)
		Pecas.Tipo.TENIS:
			for k in 2:
				var o := Vector2(-4.5, -3.0) if k == 0 else Vector2(4.0, 3.0)
				_p(c, [o + Vector2(-5, -5), o + Vector2(0, -5), o + Vector2(1, -1), o + Vector2(7, 0), o + Vector2(7.5, 3.5), o + Vector2(-5.5, 3.5)], Color(0.9, 0.12, 0.15), f, 1.1)
				c.draw_rect(Rect2(o.x - 5.4, o.y + 2.6, 13, 1.5), Desenho.b(Color(0.97, 0.97, 1.0), f))
				c.draw_line(o + Vector2(-5, -1.5), o + Vector2(0.5, -1.5), Desenho.b(Color(0.97, 0.97, 1.0), f), 1.6)
				c.draw_rect(Rect2(o.x - 2.0, o.y - 4.0, 2.4, 2.4), Desenho.b(Color(1.0, 0.82, 0.2), f))
		_:
			c.draw_circle(Vector2.ZERO, 8.0, Desenho.b(Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[tipo]], f))

## Ajuste para centralizar a peça num ícone (mesma convenção de Desenho.ICON_OFF).
static func off(tipo: int) -> Vector2:
	match tipo:
		Pecas.Tipo.ELMO_SOMBRIO: return Vector2(0, 4)
		Pecas.Tipo.ARMADURA_SOMBRIA: return Vector2(0, 0)
		Pecas.Tipo.SABRE_RUBRO: return Vector2(1.5, -11)
		Pecas.Tipo.RESPIRADOR: return Vector2(0, -0.5)
		Pecas.Tipo.GORRO: return Vector2(-7, -4)
		Pecas.Tipo.TUNICA_VERDE: return Vector2(0, 0)
		Pecas.Tipo.ESPADA_LENDARIA: return Vector2(0, -10)
		Pecas.Tipo.OCARINA: return Vector2(1, -4)
		Pecas.Tipo.BANDANA: return Vector2(-6, 9)
		Pecas.Tipo.CASCO: return Vector2(0, 0)
		Pecas.Tipo.NUNCHAKU: return Vector2(7, -5)
		Pecas.Tipo.PIZZA: return Vector2(0, 0)
		Pecas.Tipo.TOPETE: return Vector2(-8, -5)
		Pecas.Tipo.PELO_AZUL: return Vector2(0, 0)
		Pecas.Tipo.LUVAS: return Vector2(0, -4)
		Pecas.Tipo.TENIS: return Vector2(0, 0)
	return Vector2.ZERO
