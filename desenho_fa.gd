class_name DesenhoFA
extends RefCounted
## Desenho das peças das fantasias de referência, tipos 36 a 51:
## Encanador, Homem-Morcego, Garoto-Aranha e Cavaleiro Estelar.

const PRETO := Color(0.1, 0.09, 0.12)

static func _p(c: CanvasItem, pts: Array, cor: Color, f: float, larg: float = 1.2) -> void:
	Desenho._pol(c, PackedVector2Array(pts), cor, f, larg)

static func _e(pts: Array, k: float) -> Array:
	var r: Array = []
	for v in pts:
		r.append(v * k)
	return r

static func _lin(c: CanvasItem, a: Vector2, z: Vector2, cor: Color, f: float, larg: float) -> void:
	c.draw_line(a, z, Desenho.b(cor, f), larg)

static func _bola(c: CanvasItem, p: Vector2, r: float, cor: Color, f: float) -> void:
	c.draw_circle(p, r + 1.0, Desenho.b(cor.darkened(0.55), f))
	c.draw_circle(p, r, Desenho.b(cor, f))

## Desenha a peça na origem do transform atual (mesma convenção de Desenho.forma).
static func forma(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	match tipo:
		Pecas.Tipo.BONE_ENCANADOR:
			var v := Color(0.85, 0.12, 0.14)
			_p(c, Desenho._arco(0, 0, 9.5, PI, TAU, 10) + PackedVector2Array([Vector2(9.5, 1.5), Vector2(-9.5, 1.5)]), v, f)
			_p(c, [Vector2(2, 0.5), Vector2(14, 0.5), Vector2(14, 3), Vector2(2, 3)], v.darkened(0.2), f)
			c.draw_arc(Vector2(0, 0), 8.0, PI * 1.1, PI * 1.45, 6, Desenho.b(v.lightened(0.35), f), 1.4)
			c.draw_circle(Vector2(0, -6), 3.6, Desenho.b(Color(0.1, 0.05, 0.05), f))
			c.draw_circle(Vector2(0, -6), 3.0, Desenho.b(Color.WHITE, f))
			_lin(c, Vector2(-1.2, -7.6), Vector2(-1.2, -4.4), v, f, 1.2)
			_lin(c, Vector2(-1.2, -7.6), Vector2(1.4, -7.6), v, f, 1.2)
			_lin(c, Vector2(-1.2, -6), Vector2(0.8, -6), v, f, 1.2)
			# bigode
			_p(c, [Vector2(-8, 4), Vector2(-3, 3), Vector2(0, 4.5), Vector2(3, 3), Vector2(8, 4), Vector2(6, 8), Vector2(2, 6), Vector2(0, 6.5), Vector2(-2, 6), Vector2(-6, 8)], PRETO, f, 0.8)
		Pecas.Tipo.MACACAO:
			var az := Color(0.2, 0.36, 0.86)
			_p(c, [Vector2(-9, -10), Vector2(9, -10), Vector2(10, 10), Vector2(-10, 10)], az, f)
			_p(c, [Vector2(-9, -10), Vector2(-9, -2), Vector2(-5, -2), Vector2(-4, -10)], az.lightened(0.15), f, 0.6)
			c.draw_rect(Rect2(-5, -2, 10, 7), Desenho.b(az.darkened(0.2), f))
			_lin(c, Vector2(-4.5, -10), Vector2(-4.5, -3), az.darkened(0.45), f, 1.0)
			_lin(c, Vector2(4.5, -10), Vector2(4.5, -3), az.darkened(0.45), f, 1.0)
			_lin(c, Vector2(0, 5), Vector2(0, 10), az.darkened(0.5), f, 1.0)
			_p(c, [Vector2(-9, -10), Vector2(-4, -10), Vector2(-4, -6), Vector2(-9, -6)], Color(0.9, 0.15, 0.15), f, 0.6)
			_p(c, [Vector2(4, -10), Vector2(9, -10), Vector2(9, -6), Vector2(4, -6)], Color(0.9, 0.15, 0.15), f, 0.6)
			_bola(c, Vector2(-4.5, -3), 1.9, Desenho.DOURADO, f)
			_bola(c, Vector2(4.5, -3), 1.9, Desenho.DOURADO, f)
			c.draw_circle(Vector2(-5, -3.6), 0.6, Desenho.b(Color.WHITE, f))
			c.draw_rect(Rect2(-8, 3, 16, 1.2), Desenho.b(az.lightened(0.3), f))
		Pecas.Tipo.DESENTUPIDOR:
			var m := Color(0.62, 0.4, 0.2)
			_lin(c, Vector2(-0.5, 10), Vector2(2.5, -9), m.darkened(0.55), f, 4.6)
			_lin(c, Vector2(-0.5, 10), Vector2(2.5, -9), m, f, 3.0)
			_lin(c, Vector2(0.2, 9), Vector2(3.0, -8), m.lightened(0.3), f, 0.8)
			var r := Color(0.85, 0.13, 0.15)
			_p(c, [Vector2(2.5, -9), Vector2(-4, -14), Vector2(-5, -19), Vector2(1, -21), Vector2(9, -20), Vector2(10.5, -15), Vector2(7.5, -12)], r, f)
			_p(c, [Vector2(-4.5, -18), Vector2(10, -18.5), Vector2(10.5, -15), Vector2(-4, -14.5)], r.darkened(0.2), f, 0.7)
			c.draw_polyline(PackedVector2Array([Vector2(-3, -17), Vector2(0, -19.6), Vector2(5, -19.8)]), Desenho.b(Color(1, 0.6, 0.6), f), 1.0)
		Pecas.Tipo.COGUMELO:
			var r := Color(0.9, 0.16, 0.16)
			_p(c, [Vector2(-3, 1), Vector2(3, 1), Vector2(3.5, 7), Vector2(-3.5, 7)], Color(0.97, 0.9, 0.78), f)
			_p(c, Desenho._arco(0, 1, 9, PI, TAU, 12) + PackedVector2Array([Vector2(9, 2), Vector2(-9, 2)]), r, f)
			c.draw_circle(Vector2(-4.5, -3), 2.2, Desenho.b(Color.WHITE, f))
			c.draw_circle(Vector2(1, -6), 2.4, Desenho.b(Color.WHITE, f))
			c.draw_circle(Vector2(5.5, -2), 1.8, Desenho.b(Color.WHITE, f))
			c.draw_circle(Vector2(-1.2, 4), 0.8, Desenho.b(PRETO, f))
			c.draw_circle(Vector2(1.2, 4), 0.8, Desenho.b(PRETO, f))
		Pecas.Tipo.CAPUZ_MORCEGO:
			var g := Color(0.26, 0.27, 0.33)
			_p(c, [Vector2(-8, 0), Vector2(-8.5, -9), Vector2(-4, -2)], g, f)
			_p(c, [Vector2(8, 0), Vector2(8.5, -9), Vector2(4, -2)], g, f)
			_p(c, Desenho._elipse(0, 6, 9, 9.5, 16), g, f)
			_p(c, [Vector2(-8.5, 8), Vector2(-4, 10), Vector2(0, 15.5), Vector2(4, 10), Vector2(8.5, 8), Vector2(7, 14), Vector2(0, 17), Vector2(-7, 14)], g.darkened(0.3), f, 0.6)
			_p(c, [Vector2(-7, 5), Vector2(-1.6, 6.8), Vector2(-1.6, 8.6), Vector2(-6.5, 8)], Color.WHITE, f, 0.8)
			_p(c, [Vector2(7, 5), Vector2(1.6, 6.8), Vector2(1.6, 8.6), Vector2(6.5, 8)], Color.WHITE, f, 0.8)
			_lin(c, Vector2(-3, 1), Vector2(-1, -2), g.lightened(0.3), f, 1.0)
		Pecas.Tipo.CAPA_MORCEGO:
			var p := Color(0.13, 0.12, 0.17)
			_p(c, [Vector2(-9, -10), Vector2(9, -10), Vector2(13, 0), Vector2(11, 10), Vector2(8, 5), Vector2(6, 11), Vector2(3, 5), Vector2(0, 11), Vector2(-3, 5), Vector2(-6, 11), Vector2(-8, 5), Vector2(-11, 10), Vector2(-13, 0)], p, f)
			_p(c, [Vector2(-9, -10), Vector2(9, -10), Vector2(8, -6), Vector2(-8, -6)], p.lightened(0.25), f, 0.8)
			_lin(c, Vector2(-5, -5), Vector2(-6, 4), p.lightened(0.18), f, 1.0)
			_lin(c, Vector2(5, -5), Vector2(6, 4), p.lightened(0.18), f, 1.0)
			_bola(c, Vector2(0, -8), 1.6, Desenho.DOURADO, f)
		Pecas.Tipo.BUMERANGUE:
			var k := Color(0.2, 0.2, 0.26)
			_p(c, _e([Vector2(0, -6), Vector2(2, -13), Vector2(4, -10), Vector2(6, -10), Vector2(8, -13), Vector2(10, -6), Vector2(16, -9), Vector2(14, -15), Vector2(21, -10), Vector2(24, -4), Vector2(14, -6), Vector2(5, -2), Vector2(-4, -6), Vector2(-14, -4), Vector2(-24, -4), Vector2(-21, -10), Vector2(-14, -15), Vector2(-16, -9)], 0.62), k, f)
			_p(c, _e([Vector2(0, -6), Vector2(2, -13), Vector2(4, -10), Vector2(6, -10), Vector2(8, -13), Vector2(10, -6), Vector2(5, -2)], 0.62), k.lightened(0.15), f, 0.8)
			c.draw_circle(Vector2(3.1, -5), 0.7, Desenho.b(Color.WHITE, f))
			c.draw_circle(Vector2(4.3, -5), 0.7, Desenho.b(Color.WHITE, f))
		Pecas.Tipo.CINTO:
			var a := Color(0.98, 0.8, 0.18)
			_p(c, [Vector2(-10, -3.5), Vector2(10, -3.5), Vector2(10, 2.5), Vector2(-10, 2.5)], a.darkened(0.15), f)
			for x in [-8.5, 4.5]:
				_p(c, [Vector2(x, -1), Vector2(x + 4.5, -1), Vector2(x + 4.5, 6.5), Vector2(x, 6.5)], a, f, 0.9)
				c.draw_rect(Rect2(x, -1, 4.5, 1.6), Desenho.b(a.darkened(0.35), f))
			_p(c, [Vector2(-2, -3.5), Vector2(2, -3.5), Vector2(2, 2.5), Vector2(-2, 2.5)], Color(0.35, 0.35, 0.4), f, 0.9)
			c.draw_rect(Rect2(-1, -2, 2, 3), Desenho.b(a, f))
		Pecas.Tipo.MASCARA_TEIA:
			var v := Color(0.86, 0.14, 0.16)
			_p(c, Desenho._elipse(0, 9, 8.5, 9.5, 18), v, f)
			var fio := v.darkened(0.55)
			_lin(c, Vector2(0, -0.5), Vector2(0, 18), fio, f, 0.8)
			_lin(c, Vector2(-8, 5), Vector2(8, 5), fio, f, 0.8)
			_lin(c, Vector2(-7.5, 13), Vector2(7.5, 13), fio, f, 0.8)
			_lin(c, Vector2(-6, 0.5), Vector2(6, 17), fio, f, 0.8)
			_lin(c, Vector2(6, 0.5), Vector2(-6, 17), fio, f, 0.8)
			for s in [-1.0, 1.0]:
				_p(c, [Vector2(s * 1.2, 6), Vector2(s * 4.5, 3.4), Vector2(s * 8, 6.2), Vector2(s * 5.5, 10.5), Vector2(s * 2, 9.5)], Color.WHITE, f, 1.5)
		Pecas.Tipo.COLANTE:
			var v := Color(0.86, 0.14, 0.16)
			var az := Color(0.2, 0.32, 0.8)
			_p(c, [Vector2(-9, -10), Vector2(9, -10), Vector2(8, 10), Vector2(-8, 10)], v, f)
			_p(c, [Vector2(-9, -10), Vector2(-5, -10), Vector2(-5, 10), Vector2(-8, 10)], az, f, 0.8)
			_p(c, [Vector2(9, -10), Vector2(5, -10), Vector2(5, 10), Vector2(8, 10)], az, f, 0.8)
			var an := PRETO
			c.draw_circle(Vector2(0, -2.5), 2.0, Desenho.b(an, f))
			c.draw_circle(Vector2(0, 1.5), 2.8, Desenho.b(an, f))
			for s in [-1.0, 1.0]:
				for dy in [-2.0, 0.0, 2.0, 4.0]:
					_lin(c, Vector2(s * 1.5, 0.5 + dy * 0.3), Vector2(s * 5.2, -3.0 + dy * 1.1), an, f, 0.9)
		Pecas.Tipo.LANCA_TEIA:
			var az := Color(0.2, 0.32, 0.8)
			_p(c, [Vector2(-4.5, -3), Vector2(4.5, -3), Vector2(5, 4), Vector2(-5, 4)], az, f)
			c.draw_rect(Rect2(-4.5, -0.5, 9, 1.8), Desenho.b(Color(0.86, 0.14, 0.16), f))
			_p(c, [Vector2(2, -6), Vector2(6, -6), Vector2(6, -3), Vector2(2, -3)], Color(0.7, 0.72, 0.8), f, 0.9)
			_lin(c, Vector2(4, -6), Vector2(9, -14), Color(0.8, 0.8, 0.85), f, 1.0)
			c.draw_polyline(PackedVector2Array([Vector2(4, -6), Vector2(7, -10), Vector2(10, -13), Vector2(13, -19)]), Desenho.b(Color(0.96, 0.96, 1.0), f), 1.3)
			for r in [3.0, 5.5]:
				c.draw_arc(Vector2(13, -19), r, 0, TAU, 8, Desenho.b(Color(0.96, 0.96, 1.0, 0.9), f), 0.8)
			_lin(c, Vector2(13, -24), Vector2(13, -14), Color(0.96, 0.96, 1.0), f, 0.8)
			_lin(c, Vector2(8, -19), Vector2(18, -19), Color(0.96, 0.96, 1.0), f, 0.8)
		Pecas.Tipo.ARANHA_PET:
			_lin(c, Vector2(0, -9), Vector2(0, -1), Color(0.92, 0.92, 0.96), f, 0.9)
			var pt := Color(0.2, 0.18, 0.24)
			for s in [-1.0, 1.0]:
				for k in 3:
					var y: float = 1.0 + k * 1.8
					c.draw_polyline(PackedVector2Array([Vector2(s * 2, y), Vector2(s * 5, y - 1.8), Vector2(s * 6, y + 1.5)]), Desenho.b(pt, f), 1.0)
			c.draw_circle(Vector2(0, 4.2), 2.6, Desenho.b(pt, f))
			c.draw_circle(Vector2(0, 1.6), 2.4, Desenho.b(Color(0.86, 0.14, 0.16), f))
			c.draw_circle(Vector2(-1, 1.4), 0.9, Desenho.b(Color.WHITE, f))
			c.draw_circle(Vector2(1, 1.4), 0.9, Desenho.b(Color.WHITE, f))
		Pecas.Tipo.CAPUZ_ESTELAR:
			var mr := Color(0.5, 0.34, 0.2)
			_p(c, [Vector2(-9, 0), Vector2(-5, -3), Vector2(0, -4.5), Vector2(5, -3), Vector2(9, 0), Vector2(11, 12), Vector2(7, 16), Vector2(-7, 16), Vector2(-11, 12)], mr, f)
			_p(c, Desenho._elipse(0, 8, 5.6, 6.6, 14), Color(0.3, 0.2, 0.12), f, 0.8)
			_lin(c, Vector2(-6.5, -1), Vector2(-8.5, 13), mr.lightened(0.2), f, 1.0)
			_p(c, [Vector2(-8, 14), Vector2(8, 14), Vector2(7, 16.5), Vector2(-7, 16.5)], mr.darkened(0.2), f, 0.7)
		Pecas.Tipo.TUNICA:
			var bg := Color(0.88, 0.8, 0.62)
			var mr := Color(0.5, 0.34, 0.2)
			_p(c, [Vector2(-9, -10), Vector2(9, -10), Vector2(10, 10), Vector2(-10, 10)], bg, f)
			_p(c, [Vector2(-7, -10), Vector2(7, -10), Vector2(0, -2)], bg.darkened(0.2), f, 0.8)
			_lin(c, Vector2(-7, -10), Vector2(5, 3), bg.darkened(0.5), f, 1.2)
			_lin(c, Vector2(7, -10), Vector2(-5, 3), bg.darkened(0.5), f, 1.2)
			_p(c, [Vector2(-10, 2), Vector2(10, 2), Vector2(10, 6.5), Vector2(-10, 6.5)], mr, f)
			c.draw_rect(Rect2(-1.5, 2.5, 3, 4), Desenho.b(mr.lightened(0.3), f))
			_p(c, [Vector2(1, 6.5), Vector2(4, 6.5), Vector2(4.5, 11), Vector2(1.5, 11)], mr, f, 0.8)
		Pecas.Tipo.SABRE_LUZ:
			var pu: float = 0.5 + 0.5 * sin(anim * 6.0)
			var lz := Color(0.3, 0.65, 1.0)
			var halo := Color(0.35, 0.7, 1.0, 0.18 + 0.14 * pu)
			_lin(c, Vector2(0, -2), Vector2(0, -26), halo, f, 8.0 + 2.0 * pu)
			_lin(c, Vector2(0, -2), Vector2(0, -26), Color(lz.r, lz.g, lz.b, 0.9), f, 4.6)
			c.draw_circle(Vector2(0, -26), 2.3, Desenho.b(Color(lz.r, lz.g, lz.b, 0.9), f))
			_lin(c, Vector2(0, -2), Vector2(0, -26), Color(0.9, 0.97, 1.0).lerp(Color.WHITE, pu), f, 2.0)
			_lin(c, Vector2(0, 7), Vector2(0, -1.5), Color(0.2, 0.21, 0.27), f, 4.4)
			_lin(c, Vector2(0, 6.5), Vector2(0, -1), Color(0.65, 0.68, 0.76), f, 2.8)
			c.draw_rect(Rect2(-3.2, -2.6, 6.4, 1.8), Desenho.b(Color(0.45, 0.47, 0.55), f))
			for y in [1.0, 3.5]:
				_lin(c, Vector2(-1.4, y), Vector2(1.4, y), Color(0.25, 0.26, 0.32), f, 0.8)
		Pecas.Tipo.CRISTAL:
			var az := Color(0.25, 0.6, 0.98)
			c.draw_circle(Vector2.ZERO, 9.5, Desenho.b(Color(0.4, 0.75, 1.0, 0.18 + 0.1 * sin(anim * 4.0)), f))
			_p(c, [Vector2(0, -9), Vector2(6, -3), Vector2(4.5, 8), Vector2(0, 10), Vector2(-4.5, 8), Vector2(-6, -3)], az, f)
			_p(c, [Vector2(0, -9), Vector2(6, -3), Vector2(0, 0)], az.lightened(0.4), f, 0.7)
			_p(c, [Vector2(0, 0), Vector2(6, -3), Vector2(4.5, 8), Vector2(0, 10)], az.darkened(0.25), f, 0.7)
			_lin(c, Vector2(-6, -3), Vector2(0, 0), az.darkened(0.4), f, 0.8)
			c.draw_circle(Vector2(-2.4, -3.4), 1.1, Desenho.b(Color.WHITE, f))
		_:
			c.draw_circle(Vector2.ZERO, 8.0, Desenho.b(Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[tipo]], f))

## Ajuste para centralizar a peça num ícone (mesma convenção de Desenho.ICON_OFF):
## centro visual do desenho, em coordenadas locais.
static func off(tipo: int) -> Vector2:
	match tipo:
		Pecas.Tipo.BONE_ENCANADOR: return Vector2(0, -4)
		Pecas.Tipo.DESENTUPIDOR: return Vector2(2, -5)
		Pecas.Tipo.CAPUZ_MORCEGO: return Vector2(0, 4)
		Pecas.Tipo.CAPA_MORCEGO: return Vector2(0, 0)
		Pecas.Tipo.BUMERANGUE: return Vector2(0, -5)
		Pecas.Tipo.MASCARA_TEIA: return Vector2(0, 8.5)
		Pecas.Tipo.LANCA_TEIA: return Vector2(7, -10)
		Pecas.Tipo.ARANHA_PET: return Vector2(0, -3)
		Pecas.Tipo.CAPUZ_ESTELAR: return Vector2(0, 6)
		Pecas.Tipo.SABRE_LUZ: return Vector2(0, -11)
		Pecas.Tipo.COGUMELO: return Vector2(0, 0)
	return Vector2.ZERO
