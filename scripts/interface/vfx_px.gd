## Peças de pixel art para os efeitos da luta (campo.gd). Tudo é desenhado em quadradinhos de Q px alinhados
## à grade, em faixas horizontais (draw_rect), sem alocar nada por quadro: sem arrays, sem polígonos, sem
## círculos lisos. Cada forma recebe a cor de miolo e a cor do contorno escuro; o apagar é feito por
## encolhimento ou por pontilhado (`fade`), nunca por alfa sobre alfa, para os tons ficarem limpos.

const Q := 4.0   # a grade da luta: a mesma dos sprites (Campo.PX_SPRITE) e do cenário
const CONT := Color(0.1, 0.06, 0.14)
const BRANCO := Color(1.0, 0.98, 0.9)

static func sn(v: float, q: float = Q) -> float:
	return floorf(v / q) * q

## Lado em múltiplo inteiro da grade (mínimo 1 quadradinho; meio quadradinho arredonda para baixo).
static func lado(v: float, q: float = Q) -> float:
	return maxf(q, ceilf(v / q - 0.5) * q)

## Clareia/escurece uma cor mantendo o matiz (tons do efeito: escuro 0.45, médio 1, claro 1.6...).
static func tom(c: Color, f: float) -> Color:
	if f <= 1.0:
		return Color(c.r * f, c.g * f, c.b * f, c.a)
	var k: float = minf(1.0, f - 1.0)
	return Color(lerpf(c.r, 1.0, k), lerpf(c.g, 1.0, k), lerpf(c.b, 1.0, k), c.a)

static func quadro(c: CanvasItem, x: float, y: float, w: float, h: float, cor: Color, q: float = Q) -> void:
	c.draw_rect(Rect2(sn(x, q), sn(y, q), lado(w, q), lado(h, q)), cor)

## Disco cheio em faixas (sem contorno).
static func disco(c: CanvasItem, ce: Vector2, r: float, cor: Color, q: float = Q) -> void:
	var n: int = int(r / q + 0.5)
	var cx: int = int(floorf(ce.x / q))
	var cy: int = int(floorf(ce.y / q))
	if n <= 0:
		c.draw_rect(Rect2(cx * q, cy * q, q, q), cor)
		return
	var nn: float = n * n + n * 0.8
	for j in range(-n, n + 1):
		var h: int = int(sqrt(maxf(0.0, nn - j * j)))
		c.draw_rect(Rect2((cx - h) * q, (cy + j) * q, (2 * h + 1) * q, q), cor)

## Disco com contorno escuro de 1 quadradinho.
static func disco_c(c: CanvasItem, ce: Vector2, r: float, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	disco(c, ce, r + q, cont, q)
	disco(c, ce, r, cor, q)

## Bolha de fumaça/espuma: contorno, miolo, sombra embaixo à direita e um brilho em cima à esquerda.
static func bolha(c: CanvasItem, ce: Vector2, r: float, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	disco(c, ce, r + q, cont, q)
	disco(c, ce, r, tom(cor, 0.78), q)
	disco(c, ce + Vector2(-q * 0.6, -q * 0.6), maxf(0.0, r - q * 1.4), cor, q)
	if r >= q * 2.0:
		quadro(c, ce.x - r * 0.45, ce.y - r * 0.55, q, q, tom(cor, 1.7), q)

## Elipse achatada cheia (sombras e chão); aceita alfa porque as faixas não se sobrepõem.
static func elipse(c: CanvasItem, ce: Vector2, rx: float, ry: float, cor: Color, q: float = Q) -> void:
	var ny: int = int(ry / q + 0.5)
	var cx: float = ce.x
	var cy: int = int(floorf(ce.y / q))
	if ny <= 0:
		c.draw_rect(Rect2(sn(cx - rx, q), cy * q, sn(rx * 2.0, q) + q, q), cor)
		return
	for j in range(-ny, ny + 1):
		var k: float = 1.0 - float(j * j) / float(ny * ny + 1)
		var w: float = sn(rx * sqrt(maxf(0.0, k)), q)
		c.draw_rect(Rect2(sn(cx, q) - w, (cy + j) * q, w * 2.0 + q, q), cor)

## Aro de quadradinhos (elipse) com pontilhado: `fade` 1 = inteiro, 0 = sumido.
static func aro(c: CanvasItem, ce: Vector2, rx: float, ry: float, cor: Color, fade: float = 1.0, esp: float = 1.0, q: float = Q) -> void:
	if fade <= 0.02 or rx < 1.0:
		return
	var n: int = clampi(int(TAU * maxf(rx, ry * 2.0) / q * 0.62), 8, 64)
	var s: float = lado(q * esp, q)
	for i in n:
		if fposmod(i * 0.7548777, 1.0) >= fade:
			continue
		var a: float = TAU * i / n
		c.draw_rect(Rect2(sn(ce.x + cos(a) * rx - s * 0.5, q), sn(ce.y + sin(a) * ry - s * 0.5, q), s, s), cor)

## Linha de quadradinhos de lado `s` (passo = s): riscos, fios, rastros.
static func linha(c: CanvasItem, a: Vector2, b: Vector2, cor: Color, s: float = Q, q: float = Q) -> void:
	s = lado(s, q)
	var d: float = a.distance_to(b)
	var n: int = maxi(1, int(d / s))
	for i in n + 1:
		var p: Vector2 = a.lerp(b, float(i) / n)
		c.draw_rect(Rect2(sn(p.x - s * 0.5, q), sn(p.y - s * 0.5, q), s, s), cor)

## Faísca de 4 pontas (brilho): braços de comprimento `r`, contorno escuro e centro claro.
static func brilho(c: CanvasItem, ce: Vector2, r: float, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	var x: float = sn(ce.x, q)
	var y: float = sn(ce.y, q)
	var rr: float = maxf(q, sn(r, q))
	c.draw_rect(Rect2(x - rr - q, y - q, rr * 2.0 + q * 3.0, q * 3.0), cont)
	c.draw_rect(Rect2(x - q, y - rr - q, q * 3.0, rr * 2.0 + q * 3.0), cont)
	c.draw_rect(Rect2(x - rr, y, rr * 2.0 + q, q), cor)
	c.draw_rect(Rect2(x, y - rr, q, rr * 2.0 + q), cor)
	c.draw_rect(Rect2(x - q, y - q, q * 3.0, q * 3.0), tom(cor, 1.5))
	c.draw_rect(Rect2(x, y, q, q), BRANCO)

## Estrela de impacto de 8 pontas (golpe forte, crítico): brilho + diagonais.
static func estrela(c: CanvasItem, ce: Vector2, r: float, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	brilho(c, ce, r, cor, cont, q)
	var d: float = sn(r * 0.55, q)
	var x: float = sn(ce.x, q)
	var y: float = sn(ce.y, q)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			c.draw_rect(Rect2(x + sx * d - q * 0.0, y + sy * d, q, q), cont)
			c.draw_rect(Rect2(x + sx * (d - q), y + sy * (d - q), q, q), cor)

## Cruz de cura (mais): contorno, verde, brilho.
static func cruz(c: CanvasItem, ce: Vector2, s: float, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	var x: float = sn(ce.x, q)
	var y: float = sn(ce.y, q)
	var b: float = maxf(q, sn(s, q))   # meio-comprimento do braço
	c.draw_rect(Rect2(x - b - q, y - q * 2.0, b * 2.0 + q * 3.0, q * 4.0), cont)
	c.draw_rect(Rect2(x - q * 2.0, y - b - q, q * 4.0, b * 2.0 + q * 3.0), cont)
	c.draw_rect(Rect2(x - b, y - q, b * 2.0 + q, q * 2.0), cor)
	c.draw_rect(Rect2(x - q, y - b, q * 2.0, b * 2.0 + q), cor)
	c.draw_rect(Rect2(x - q, y - q, q, q), tom(cor, 1.7))

## Gota (pingo): 3 quadradinhos de largura, ponta em cima.
static func gota(c: CanvasItem, ce: Vector2, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	var x: float = sn(ce.x, q)
	var y: float = sn(ce.y, q)
	c.draw_rect(Rect2(x - q, y - q * 2.0, q * 3.0, q * 5.0), cont)
	c.draw_rect(Rect2(x - q * 2.0, y, q * 5.0, q * 3.0), cont)
	c.draw_rect(Rect2(x, y - q, q, q), cor)
	c.draw_rect(Rect2(x - q, y, q * 3.0, q * 2.0), cor)
	c.draw_rect(Rect2(x - q * 0.0, y + q * 2.0, q, q), cor)
	c.draw_rect(Rect2(x - q, y, q, q), tom(cor, 1.7))

## Folha: losango de 3x5 quadradinhos com nervura; `dir` +1/-1 inclina para um lado.
static func folha(c: CanvasItem, ce: Vector2, dir: float, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	var x: float = sn(ce.x, q)
	var y: float = sn(ce.y, q)
	c.draw_rect(Rect2(x - q, y - q * 2.0, q * 3.0, q * 5.0), cont)
	c.draw_rect(Rect2(x - q * 2.0, y - q, q * 5.0, q * 3.0), cont)
	c.draw_rect(Rect2(x, y - q, q, q * 3.0), tom(cor, 0.8))
	c.draw_rect(Rect2(x - q * 0.0 + dir * q, y - q * 2.0 + q, q, q * 2.0), cor)
	c.draw_rect(Rect2(x - dir * q, y, q, q), cor)
	c.draw_rect(Rect2(x, y - q * 2.0 + q, q, q), tom(cor, 1.6))

## Cristal de gelo: espeto de `h` px, base de `w` px, metade clara e metade média, contorno escuro.
static func cristal(c: CanvasItem, base: Vector2, w: float, h: float, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	var n: int = maxi(1, int(h / q))
	var wc: int = maxi(1, int(w / q))
	var x: float = sn(base.x, q)
	var y: float = sn(base.y, q)
	for k in n:
		var f: float = 1.0 - float(k) / n
		var cw: int = maxi(1, int(ceil(wc * f)))
		var yy: float = y - (k + 1) * q
		c.draw_rect(Rect2(x - cw * q - q, yy, cw * 2.0 * q + q * 3.0, q), cont) if k == 0 else c.draw_rect(Rect2(x - cw * q - q, yy, cw * 2.0 * q + q * 3.0, q), cont)
	for k in n:
		var f2: float = 1.0 - float(k) / n
		var cw2: int = maxi(1, int(ceil(wc * f2)))
		var yy2: float = y - (k + 1) * q
		c.draw_rect(Rect2(x - cw2 * q, yy2, cw2 * q, q), tom(cor, 1.55))
		c.draw_rect(Rect2(x, yy2, cw2 * q + q, q), tom(cor, 0.85))
	c.draw_rect(Rect2(x - q, y - q * 2.0, q, q * 2.0), BRANCO)

## Raio em degraus (zigue-zague com trechos retos), de cima `a` até o ponto `b`. `sem` muda o desenho;
## três camadas: contorno escuro, brilho na cor e miolo branco.
static func raio(c: CanvasItem, a: Vector2, b: Vector2, cor: Color, sem: float, larg: float = 12.0, q: float = Q) -> void:
	var n: int = 7
	for camada in 3:
		var s: float = larg if camada == 0 else (larg * 0.62 if camada == 1 else larg * 0.28)
		var cc: Color = CONT if camada == 0 else (cor if camada == 1 else BRANCO)
		var px: float = a.x
		var py: float = a.y
		for i in range(1, n + 1):
			var w: float = float(i) / n
			var ny: float = lerpf(a.y, b.y, w)
			var nx: float = lerpf(a.x, b.x, w)
			if i < n:
				nx += sin(i * 12.9898 + sem * 78.233) * 22.0
			var ex: float = nx if i < n else b.x
			c.draw_rect(Rect2(sn(px - s * 0.5, q), sn(py, q), maxf(q, s), sn(maxf(ny - py, q), q)), cc)
			c.draw_rect(Rect2(sn(minf(px, ex) - s * 0.5, q), sn(ny - s * 0.5, q), sn(absf(ex - px), q) + maxf(q, s), maxf(q, s)), cc)
			px = ex
			py = ny

## Labareda de pixel: colunas de altura variável, miolo amarelo, ponta laranja, borda vermelho-escura.
static func chama(c: CanvasItem, base: Vector2, larg: float, alt: float, t: float, q: float = Q) -> void:
	var n: int = maxi(2, int(larg / q))
	var x0: float = sn(base.x - larg * 0.5, q)
	var y: float = sn(base.y, q)
	for i in n:
		var f: float = 1.0 - absf((i + 0.5) / n * 2.0 - 1.0)
		var h: float = sn((alt * (0.3 + 0.7 * f)) * (0.75 + 0.25 * sin(t * 14.0 + i * 1.9)), q)
		if h < q:
			continue
		c.draw_rect(Rect2(x0 + i * q - 0.0, y - h - q, q, h + q), Color(0.55, 0.12, 0.08))
		c.draw_rect(Rect2(x0 + i * q, y - h, q, h), Color(0.98, 0.45, 0.1))
		if h > q * 2.0:
			c.draw_rect(Rect2(x0 + i * q, y - h * 0.62, q, h * 0.62), Color(1.0, 0.8, 0.25))
		if h > q * 4.0 and f > 0.6:
			c.draw_rect(Rect2(x0 + i * q, y - h * 0.3, q, h * 0.3), Color(1.0, 0.96, 0.7))

## Um quadradinho solto (fagulha, ponto de neve).
static func ponto(c: CanvasItem, p: Vector2, cor: Color, q: float = Q) -> void:
	c.draw_rect(Rect2(sn(p.x, q), sn(p.y, q), q, q), cor)

## Arco de quadradinhos entre dois ângulos (ondas de choque de um lado só).
static func arco(c: CanvasItem, ce: Vector2, r: float, a0: float, a1: float, cor: Color, fade: float = 1.0, esp: float = 1.0, q: float = Q) -> void:
	if fade <= 0.02 or r < 1.0:
		return
	var n: int = clampi(int(absf(a1 - a0) * r / q * 0.8), 3, 60)
	var s: float = lado(q * esp, q)
	for i in n + 1:
		if fposmod(i * 0.7548777, 1.0) >= fade:
			continue
		var a: float = lerpf(a0, a1, float(i) / n)
		c.draw_rect(Rect2(sn(ce.x + cos(a) * r - s * 0.5, q), sn(ce.y + sin(a) * r - s * 0.5, q), s, s), cor)

## Seta ">" (ou "<" com dir -1) de 4 degraus apontando para `ce`, com contorno.
static func seta(c: CanvasItem, ce: Vector2, dir: float, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	var x: float = sn(ce.x, q)
	var y: float = sn(ce.y, q)
	for passo in 2:
		var cc: Color = cont if passo == 0 else cor
		var e: float = q if passo == 0 else 0.0
		for k in 4:
			var xx: float = x - dir * k * q
			c.draw_rect(Rect2(xx - e, y + k * q - e, q + 2.0 * e, q + 2.0 * e), cc)
			c.draw_rect(Rect2(xx - e, y - k * q - e, q + 2.0 * e, q + 2.0 * e), cc)

## Nota musical: cabeça, haste e bandeira.
static func nota(c: CanvasItem, ce: Vector2, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	var x: float = sn(ce.x, q)
	var y: float = sn(ce.y, q)
	c.draw_rect(Rect2(x - q * 2.0, y + q * 2.0 - q, q * 4.0, q * 4.0), cont)
	c.draw_rect(Rect2(x + q * 1.0, y - q * 5.0, q * 3.0, q * 7.0), cont)
	c.draw_rect(Rect2(x + q * 2.0, y - q * 5.0 + q * 0.0, q * 4.0, q * 3.0), cont)
	c.draw_rect(Rect2(x - q, y + q * 2.0, q * 2.0, q * 2.0), cor)
	c.draw_rect(Rect2(x + q * 2.0, y - q * 4.0, q, q * 6.0), cor)
	c.draw_rect(Rect2(x + q * 3.0, y - q * 4.0, q, q * 2.0), cor)
	c.draw_rect(Rect2(x - q, y + q * 2.0, q, q), tom(cor, 1.7))

## Flor de 4 pétalas com miolo.
static func flor(c: CanvasItem, ce: Vector2, cor: Color, miolo: Color, cont: Color = CONT, q: float = Q) -> void:
	var x: float = sn(ce.x, q)
	var y: float = sn(ce.y, q)
	c.draw_rect(Rect2(x - q * 2.0, y - q, q * 5.0, q * 3.0), cont)
	c.draw_rect(Rect2(x - q, y - q * 2.0, q * 3.0, q * 5.0), cont)
	c.draw_rect(Rect2(x - q, y - q * 0.0, q * 3.0, q), cor)
	c.draw_rect(Rect2(x, y - q, q, q * 3.0), cor)
	c.draw_rect(Rect2(x, y, q, q), miolo)

# ---------------------------------------------------------------- lote 2 da expansão: estruturas, sono e mudas
## Letra "z" de sono em quadradinhos de `q`: barra de cima, diagonal e barra de baixo. O escuro é só uma sombra
## de 1 quadradinho embaixo e à direita de cada traço (contorno em volta inteira fechava o miolo e virava caixa).
## `tam` < 2 dá um z de 4x4 quadradinhos; 2 ou mais, de 5x5. `ce` é o canto de cima à esquerda.
static func zzz(c: CanvasItem, ce: Vector2, tam: float, cor: Color, cont: Color = CONT, q: float = Q) -> void:
	var x: float = sn(ce.x, q)
	var y: float = sn(ce.y, q)
	var n: int = 5 if tam >= 2.0 else 4
	for camada in 2:
		var o: float = q if camada == 0 else 0.0
		var cc: Color = cont if camada == 0 else cor
		c.draw_rect(Rect2(x + o, y + o, n * q, q), cc)
		c.draw_rect(Rect2(x + o, y + (n - 1) * q + o, n * q, q), cc)
		for k in range(1, n - 1):
			c.draw_rect(Rect2(x + (n - 1 - k) * q + o, y + k * q + o, q, q), cc)

## Torre de ervilha: caule, duas folhas, cabeça redonda e o cano que recua no tiro. `base` = pés; `dir` = para onde olha; `golpe` > 0 logo após atirar.
static func torre_ervilha(c: CanvasItem, base: Vector2, esc: float, dir: float, golpe: float, frac: float, q: float = Q) -> void:
	var verde := Color(0.42, 0.82, 0.3)
	var escuro := Color(0.16, 0.45, 0.2)
	var d: float = 1.0 if dir >= 0.0 else -1.0
	elipse(c, base + Vector2(0, 2), 17.0 * esc, 5.0 * esc, Color(0.0, 0.0, 0.0, 0.25), q)
	quadro(c, base.x - 3.0 * esc - q, base.y - 26.0 * esc - q, 6.0 * esc + q * 2.0, 26.0 * esc + q, CONT, q)
	quadro(c, base.x - 3.0 * esc, base.y - 26.0 * esc, 6.0 * esc, 26.0 * esc, escuro, q)
	folha(c, base + Vector2(-11.0 * esc, -10.0 * esc), -1.0, verde, CONT, q)
	folha(c, base + Vector2(11.0 * esc, -14.0 * esc), 1.0, verde, CONT, q)
	var cab: Vector2 = base + Vector2(0, -38.0 * esc)
	var recuo: float = minf(golpe, 0.2) * 20.0
	var x1: float = cab.x + d * (8.0 * esc - recuo)
	var x2: float = cab.x + d * 24.0 * esc
	quadro(c, minf(x1, x2) - q, cab.y - 4.0 * esc - q, absf(x2 - x1) + q * 2.0, 8.0 * esc + q * 2.0, CONT, q)
	quadro(c, minf(x1, x2), cab.y - 4.0 * esc, absf(x2 - x1), 8.0 * esc, escuro, q)
	disco_c(c, cab, 13.0 * esc, verde, CONT, q)
	disco(c, cab + Vector2(-4.0 * esc, -5.0 * esc), 4.0 * esc, tom(verde, 1.6), q)
	quadro(c, cab.x - d * 2.0 * esc, cab.y - 5.0 * esc, q, q * 2.0, CONT, q)
	quadro(c, cab.x + d * 5.0 * esc, cab.y - 5.0 * esc, q, q * 2.0, CONT, q)
	if frac < 0.999:
		quadro(c, base.x - 14.0 * esc, base.y - 62.0 * esc, 28.0 * esc, q, CONT, q)
		quadro(c, base.x - 14.0 * esc, base.y - 62.0 * esc, 28.0 * esc * clampf(frac, 0.0, 1.0), q, Color(0.4, 0.95, 0.4), q)

## Bloco de pedra do Construir; rachaduras conforme a vida que sobra.
static func bloco_pedra(c: CanvasItem, base: Vector2, esc: float, frac: float, q: float = Q) -> void:
	var w: float = 24.0 * esc
	var h: float = 26.0 * esc
	elipse(c, base + Vector2(0, 2), 15.0 * esc, 4.0 * esc, Color(0.0, 0.0, 0.0, 0.25), q)
	quadro(c, base.x - w * 0.5 - q, base.y - h - q, w + q * 2.0, h + q * 2.0, CONT, q)
	quadro(c, base.x - w * 0.5, base.y - h, w, h, Color(0.56, 0.57, 0.62), q)
	quadro(c, base.x - w * 0.5, base.y - h, w, h * 0.25, Color(0.78, 0.79, 0.84), q)
	quadro(c, base.x - w * 0.5, base.y - h * 0.22, w, h * 0.22, Color(0.36, 0.37, 0.42), q)
	quadro(c, base.x - w * 0.5 + q, base.y - h * 0.6, q * 2.0, q * 2.0, Color(0.4, 0.62, 0.35), q)
	if frac < 0.66:
		quadro(c, base.x - q, base.y - h * 0.75, q, h * 0.4, CONT, q)
		quadro(c, base.x - q * 3.0, base.y - h * 0.4, q * 3.0, q, CONT, q)
	if frac < 0.33:
		quadro(c, base.x + w * 0.2, base.y - h * 0.9, q, h * 0.5, CONT, q)
		quadro(c, base.x - w * 0.35, base.y - h * 0.6, q, h * 0.35, CONT, q)

## Muda da Colheita: broto que cresce com `w` (0..1); perto de amadurecer mostra o botão.
static func muda(c: CanvasItem, base: Vector2, w: float, q: float = Q) -> void:
	var h: float = 5.0 + 17.0 * clampf(w, 0.0, 1.0)
	var verde := Color(0.4, 0.82, 0.3)
	quadro(c, base.x - q * 3.0, base.y, q * 6.0, q, Color(0.4, 0.26, 0.14), q)
	quadro(c, base.x - q * 0.5, base.y - h, q * 2.0, h, CONT, q)
	quadro(c, base.x, base.y - h, q, h, Color(0.18, 0.5, 0.2), q)
	folha(c, base + Vector2(-5.0, -h * 0.6), -1.0, verde, CONT, q)
	folha(c, base + Vector2(5.0, -h * 0.8), 1.0, verde, CONT, q)
	if w > 0.7:
		disco_c(c, base + Vector2(0, -h - 3.0), 3.0 + 3.0 * (w - 0.7) / 0.3, Color(0.95, 0.35, 0.3), CONT, q)

# ---------------------------------------------------------------- lote 3 da expansão: domo, chama azul, chute e faca
## Labareda azul do Turbo (mesma forma de `chama`, em tons de azul).
static func chama_azul(c: CanvasItem, base: Vector2, larg: float, alt: float, t: float, q: float = Q) -> void:
	var n: int = maxi(2, int(larg / q))
	var x0: float = sn(base.x - larg * 0.5, q)
	var y: float = sn(base.y, q)
	for i in n:
		var f: float = 1.0 - absf((i + 0.5) / n * 2.0 - 1.0)
		var h: float = sn((alt * (0.3 + 0.7 * f)) * (0.75 + 0.25 * sin(t * 14.0 + i * 1.9)), q)
		if h < q:
			continue
		c.draw_rect(Rect2(x0 + i * q, y - h - q, q, h + q), Color(0.1, 0.2, 0.55))
		c.draw_rect(Rect2(x0 + i * q, y - h, q, h), Color(0.15, 0.55, 1.0))
		if h > q * 2.0:
			c.draw_rect(Rect2(x0 + i * q, y - h * 0.62, q, h * 0.62), Color(0.45, 0.85, 1.0))
		if h > q * 4.0 and f > 0.6:
			c.draw_rect(Rect2(x0 + i * q, y - h * 0.3, q, h * 0.3), Color(0.9, 1.0, 1.0))

## Domo de energia: cúpula de quadradinhos com uma grade hexagonal fraca. `ce` = chão sob o dono, `viva` 0..1.
static func domo(c: CanvasItem, ce: Vector2, rx: float, t: float, viva: float, cor: Color, q: float = Q) -> void:
	var ry: float = rx * 0.6
	elipse(c, ce, rx * viva, ry * 0.6 * viva, Color(cor.r, cor.g, cor.b, 0.22), q)
	aro(c, ce, rx * viva, ry * 0.6 * viva, cor, viva, 1.0, q)
	var alt: float = rx * 0.9 * viva
	var n: int = int(alt / (q * 3.0))
	for j in n:
		var k: float = (j + 1.0) / (n + 1.0)
		var w: float = rx * viva * sqrt(maxf(0.0, 1.0 - k * k))
		var y: float = ce.y - alt * k * 0.8
		aro(c, Vector2(ce.x, y), w, w * 0.18, Color(cor.r, cor.g, cor.b, 0.7), viva * 0.7, 1.0, q)
	for i in 5:
		var fx: float = fposmod(t * 0.6 + i * 0.2, 1.0)
		ponto(c, Vector2(ce.x + (fx * 2.0 - 1.0) * rx * 0.85 * viva, ce.y - alt * (0.15 + 0.65 * fposmod(i * 0.37 + t * 0.3, 1.0))), BRANCO, q)

## Chute giratório (Meon): meia-lua de pixels que varre em volta do gato (`u` 0..1 do efeito) com a bota na ponta.
static func chute_arco(c: CanvasItem, ce: Vector2, raio: float, u: float, cont: Color, q: float = Q) -> void:
	var fim: float = lerpf(-PI * 0.9, PI * 0.9, minf(1.0, u * 1.6))
	var n: int = 14
	for i in n:
		var k: float = float(i) / (n - 1)
		var ang: float = lerpf(-PI * 0.9, fim, k)
		var fade: float = 0.25 + 0.75 * k
		var pt := Vector2(ce.x + cos(ang) * raio, ce.y + sin(ang) * raio * 0.4)
		c.draw_rect(Rect2(sn(pt.x, q) - q, sn(pt.y, q) - q, q * 3.0, q * 3.0), Color(cont.r, cont.g, cont.b, fade))
		c.draw_rect(Rect2(sn(pt.x, q), sn(pt.y, q), q, q), Color(1.0, 1.0, 0.95, fade))
	# bota marrom na ponta do arco
	var bp := Vector2(ce.x + cos(fim) * raio, ce.y + sin(fim) * raio * 0.4)
	c.draw_rect(Rect2(sn(bp.x, q) - q * 2.0, sn(bp.y, q) - q * 2.0, q * 5.0, q * 4.0), CONT)
	c.draw_rect(Rect2(sn(bp.x, q) - q, sn(bp.y, q) - q, q * 3.0, q * 2.0), Color(0.45, 0.28, 0.14))
	c.draw_rect(Rect2(sn(bp.x, q) - q, sn(bp.y, q) - q, q * 3.0, q), Color(0.7, 0.45, 0.25))

## Faca brilhando no aparo (Meon): lâmina cruzada com um brilho que se abre e some.
static func faca_brilho(c: CanvasItem, ce: Vector2, u: float, cont: Color, q: float = Q) -> void:
	var a: float = 1.0 - u
	var l: float = 22.0 + 10.0 * u
	linha(c, ce + Vector2(-l, l * 0.7), ce + Vector2(l, -l * 0.7), CONT, q * 2.5, q)
	linha(c, ce + Vector2(-l, l * 0.7), ce + Vector2(l, -l * 0.7), Color(0.9, 0.93, 1.0), q * 1.5, q)
	linha(c, ce + Vector2(-l * 0.8, l * 0.5), ce + Vector2(l * 0.2, -l * 0.35), BRANCO, q, q)
	linha(c, ce + Vector2(-l * 0.6, -l * 0.7), ce + Vector2(l * 0.6, l * 0.7), Color(0.8, 0.82, 0.9, a), q, q)
	estrela(c, ce, 8.0 + 12.0 * a, Color(1.0, 1.0, 0.9), cont, q)

# ---------------------------------------------------------------- lote 4 da expansão: apagão, rocha, fio
## Grão de filme do Modo Noir: `n` quadradinhos brancos e pretos que mudam de lugar ~14 vezes por segundo
## dentro de uma elipse de raios (rx, ry) em volta de `ce`.
static func grao_filme(c: CanvasItem, ce: Vector2, rx: float, ry: float, t: float, viva: float, n: int = 30, q: float = Q) -> void:
	var fr: float = floorf(t * 14.0)
	for i in n:
		var h1: float = fposmod(sin(i * 12.9898 + fr * 78.233) * 43758.5453, 1.0)
		var h2: float = fposmod(sin(i * 39.346 + fr * 11.135) * 24634.6345, 1.0)
		var px: float = ce.x + (h1 * 2.0 - 1.0) * rx
		var py: float = ce.y + (h2 * 2.0 - 1.0) * ry
		var g: float = q * (2.0 if i % 4 == 0 else 1.0)
		if i % 3 == 0:
			quadro(c, px, py, g, g, Color(0.04, 0.04, 0.05, 0.85 * viva), q)
		else:
			quadro(c, px, py, g, g, Color(1.0, 1.0, 1.0, 0.9 * viva), q)

## Sombra do Knight (Alma Sombria): silhueta preta de chifres com dois olhos brancos e fiapos de fumaça escura atrás.
## `dir` +1/-1 é o lado para onde olha; `cel` é o tamanho do pixel da silhueta; `t` anima a fumaça.
const SOMBRA: Array[String] = [
	"......k..k..", ".....kk..kk.", "....kkkkkkk.", "...kkkkkkkkk", "..kkkkwwkwwk", "kkkkkkwwkwwk",
	".kkkkkkkkkkk", "k.kkkkkkkkk.", "..k.kkk.kk..",
]
static func sombra(c: CanvasItem, ce: Vector2, dir: float, cel: float, t: float, viva: float = 1.0, q: float = Q) -> void:
	var w: int = SOMBRA[0].length()
	var h: int = SOMBRA.size()
	var cor_c := Color(0.42, 0.3, 0.62, viva)
	var cor_s := Color(0.02, 0.01, 0.05, viva)
	for passo in 2:
		for yy in h:
			for xx in w:
				var ch: String = SOMBRA[yy][xx]
				if ch == ".":
					continue
				var gx: float = (xx - w * 0.5) * dir * cel if dir > 0.0 else (xx - w * 0.5) * dir * cel - cel
				var gy: float = (yy - h * 0.5) * cel
				var pos := ce + Vector2(gx, gy)
				if passo == 0:
					quadro(c, pos.x - q, pos.y - q, cel + q * 2.0, cel + q * 2.0, cor_c, q)
				elif ch == "w":
					quadro(c, pos.x, pos.y, cel, cel, Color(1.0, 1.0, 0.95, viva), q)
				else:
					quadro(c, pos.x, pos.y, cel, cel, cor_s, q)
	# fiapos de fumaça escura soltos atrás, sobem e somem
	for i in 9:
		var f: float = fposmod(t * 1.6 + i * 0.137, 1.0)
		var fx: float = -dir * (w * 0.5 * cel + f * cel * 7.0)
		var fy: float = (fposmod(i * 0.43, 1.0) - 0.5) * h * cel * 0.9 - f * cel * 2.0
		var al: float = (1.0 - f) * 0.85 * viva
		var tam: float = cel * (1.0 - f * 0.5)
		quadro(c, ce.x + fx - q, ce.y + fy - q, tam + q * 2.0, tam + q * 2.0, Color(0.42, 0.3, 0.62, al * 0.6), q)
		quadro(c, ce.x + fx, ce.y + fy, tam, tam, Color(0.03, 0.02, 0.07, al), q)

## Pedra rolante: rocha de pixels cinza girando (`rot` em voltas).
static func rocha(c: CanvasItem, ce: Vector2, r: float, rot: float, q: float = Q) -> void:
	disco_c(c, ce, r, Color(0.5, 0.48, 0.5), CONT, q)
	disco(c, ce + Vector2(-r * 0.25, -r * 0.3), r * 0.55, Color(0.66, 0.64, 0.66), q)
	for k in 3:
		var a: float = rot * TAU + k * 2.1
		ponto(c, ce + Vector2(cos(a), sin(a)) * r * 0.55, Color(0.3, 0.28, 0.32), q)
	ponto(c, ce + Vector2(-r * 0.4, -r * 0.45), Color(0.88, 0.86, 0.86), q)

## Fio de seda entre dois pontos, com uma leve barriga e nós de pixel.
static func fio(c: CanvasItem, a: Vector2, b: Vector2, cor: Color, t: float, q: float = Q) -> void:
	var n: int = maxi(3, int(a.distance_to(b) / 14.0))
	var ant: Vector2 = a
	for i in range(1, n + 1):
		var k: float = float(i) / n
		var pt: Vector2 = a.lerp(b, k) + Vector2(0, sin(k * PI) * 7.0 + sin(t * 6.0 + k * 9.0) * 1.5)
		linha(c, ant, pt, cor, q, q)
		ant = pt
	ponto(c, a, Color(1, 0.8, 0.85), q)
	ponto(c, b, Color(1, 0.8, 0.85), q)
