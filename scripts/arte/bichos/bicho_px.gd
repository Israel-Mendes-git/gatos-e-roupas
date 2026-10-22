class_name BichoPx
extends RefCounted
## Os bichos inimigos em pixel art, de quatro patas, desenhados por código na mesma grade de pixels do gato.
## Unidade: 1 = um pixel. O bicho é desenhado olhando para a DIREITA (+x), com as patas no chão em y = 0
## e centrado em x = 0; quem chama espelha para ele olhar para a esquerda.
## O corpo segue a mesma planta do gato para vestir as mesmas roupas (ver RoupaGato.ORIGEM):
## topo do crânio em (5.5, -16), centro do tronco em (-0.5, -9), ponta do focinho em (11, -11),
## alto da anca em (-8, -12), pescoço em (2, -11), patas da frente no chão em x = 4.5.
## Bichos comuns com arte nova ficam um arquivo por família (ver NOVOS), os chefes em dois (NOVOS_CHEFES); quem ainda não tem arquivo
## novo segue em BichoPxA (0 a 2) e BichoPxB (3 e 4). Todos os novos gravam o quadro com o molde do tronco e o crânio (ver quadro()).

## Pose de truque em curso (Unidade.Tipo do truque, ou -1): lida por BichoPxA._geo e BichoPxB._pose para dar ao Escudeiro, à Bomba e ao Atirador
## uma postura própria (cabeça baixa, inclinado, ereto). Só vale durante a chamada de desenhar()/desloc().
static var pose_truque: int = -1

## O bicho veste uma peça de cabeça: os gorros, bonés e elmos que já vêm no desenho do tipo saem, para o chapéu não ficar por cima deles.
## Só vale durante a chamada de desenhar().
static var cabeca_coberta: bool = false

## O bicho veste uma roupa de corpo: capas, golas e mantos que já vêm no desenho do chefe saem, para a roupa não brigar com eles.
## Só vale durante a chamada de desenhar().
static var corpo_coberto: bool = false

# ---------------------------------------------------------------- ganchos de animação
## Estados de pose que não cabem nos parâmetros de desenhar(): Desenho.boneco liga antes de desenhar o bicho e desliga depois
## (valem só durante a chamada). Cada família lê em _geo e põe na chave do cache.
## `preparo` 0..1 = janela antes do golpe (a recarga está acabando): cabeça recua, corpo agacha, corda puxada.
static var preparo: float = 0.0
## `dor` = acabou de apanhar (~0,12 s): olhos apertados, cabeça 1 px para trás, orelhas baixas.
static var dor: bool = false
## `queda` < 0 = vivo; 0..1 = nocaute em curso (o "fantasma" do bicho derrotado): olho em X e o quadro gira de 90 em 90 graus
## até ficar de barriga para cima (ver sprite()). `queda_giro` = quartos de volta (0, 1, 2) e `queda_chao` = deitado no chão.
static var queda: float = -1.0
static var queda_giro: int = 0
static var queda_chao: bool = false
## `fuga` = Ladrão fugindo com a carga: corre (galope) em vez de andar, saco balançando fora de fase.
static var fuga: bool = false

const DUR_GOLPE := 0.22    # duração do golpe (golpe vai de 0.22 a 0)
const PREPARO_T := 0.16    # janela de preparo antes do golpe (s de recarga restante)

## Extensão do golpe (0..1). O dano sai no passo em que golpe = 0,22: o contato aparece LOGO ali (1), segura uns dois quadros
## e volta desacelerando (rápido no começo, assentando no fim). Antes era um seno que só chegava ao ápice 0,11 s depois do dano.
static func curva_golpe(golpe: float) -> float:
	if golpe <= 0.0:
		return 0.0
	var r: float = clampf(golpe / DUR_GOLPE, 0.0, 1.0)
	if r >= 0.72:
		return 1.0
	var u: float = r / 0.72
	return u * u

## Recuo de preparo em pixels (0, 1 ou 2): só antes do golpe, nunca durante.
static func recuo(golpe: float) -> int:
	if golpe > 0.0 or preparo <= 0.0:
		return 0
	return 1 if preparo < 0.5 else 2

## Modo do olho: 0 aberto, 1 apertado (dor), 2 em X (nocaute).
static func modo_olho() -> int:
	if queda >= 0.0:
		return 1 if queda < 0.18 else 2
	return 1 if dor else 0

## Troca o olho de uma cabeça em linhas de letras. Procura as letras de `olho` numa janela em volta de (ex, ey), pinta-as com `fundo`
## e desenha por cima, com `traco`: apertado = risco fechado com a ruga de trás; X = xis de 3x3 no meio do olho.
static func olhos(rows: Array, ex: int, ey: int, modo: int, olho: String, fundo: String, traco: String, alcance: int = 4) -> Array:
	if modo == 0:
		return rows
	var r: Array = rows.duplicate()
	var x0: int = 999
	var y0: int = 999
	var x1: int = -1
	var y1: int = -1
	for j in range(maxi(0, ey), mini(r.size(), ey + 4)):
		var s: String = r[j]
		for i in range(maxi(0, ex - 1), mini(s.length(), ex + alcance)):
			if olho.contains(s[i]):
				x0 = mini(x0, i)
				y0 = mini(y0, j)
				x1 = maxi(x1, i)
				y1 = maxi(y1, j)
				s = s.substr(0, i) + fundo + s.substr(i + 1)
		r[j] = s
	if x1 < 0:
		return rows
	var pts: Array = []
	var cx: int = (x0 + x1 + 1) / 2
	var cy: int = (y0 + y1) / 2
	if modo == 1:
		var ym: int = (y0 + y1 + 1) / 2
		for i in range(x0, x1 + 1):
			pts.append(Vector2i(i, ym))
		pts.append(Vector2i(x0, ym - 1))   # ruga de trás: o olho fecha com força
		if x1 > x0:
			pts.append(Vector2i(x1 + 1, ym))
	else:
		for d in [-1, 0, 1]:
			pts.append(Vector2i(cx + d, cy + d))
			pts.append(Vector2i(cx + d, cy - d))
	for p in pts:
		var v: Vector2i = p
		if v.y < 0 or v.y >= r.size():
			continue
		var s2: String = r[v.y]
		if v.x < 0 or v.x >= s2.length() or s2[v.x] == ".":
			continue
		r[v.y] = s2.substr(0, v.x) + traco + s2.substr(v.x + 1)
	return r

## Passo dos bichos comuns: amplitude da passada (px que o pé anda para cada lado do quadril) e quanto a pata sobe na passagem.
const PASSADA := 3.0
const PATA_SOBE := 3.0
const QUADROS_PASSO := 6
const PASSO_ANIM := 1.3     # quadros de passo por unidade de anim (_PASSO das famílias)

## Pé no passo de fase `ph` (0..1): no ar (sin > 0) ele vai de trás para a frente, no chão volta de frente para trás, acompanhando
## o chão que passa (antes andava ao contrário: a pata no ar ia para trás e a do chão para a frente — o passo "patinava").
static func pe_passo(x: int, ph: float, passada: float = PASSADA, sobe: float = PATA_SOBE) -> Vector2i:
	var xf: int = x - roundi(passada * cos(TAU * ph))
	var yf: int = -1 - maxi(0, roundi(sobe * sin(TAU * ph)))
	return Vector2i(xf, yf)

## Sobe-e-desce do corpo no passo (quadro `q` de 0 a 5): [corpo, cabeça em relação ao corpo]. Comum: 1 px na passagem.
## Grandalhão: 2 px, desce pesado no apoio e a cabeça chega um quadro atrasada. Fuga (galope): 2 px, alto no voo do galope.
static func bob_passo(q: int, gig: bool, fuga: bool) -> Vector2i:
	if fuga:
		var gal: Array = [0, -1, -2, -2, -1, 0]
		return Vector2i(gal[q % 6], 0)
	if gig:
		var pes: Array = [0, -2, -1]
		var corpo: int = pes[q % 3]
		return Vector2i(corpo, int(pes[posmod(q - 1, 3)]) - corpo)
	return Vector2i(-1 if q % 3 == 1 else 0, 0)

## Saco do Ladrão fugindo: chega dois quadros atrasado ao sobe-e-desce do corpo (balança fora de fase). Pixels em relação ao corpo.
static func saco_passo(q: int) -> int:
	return bob_passo(posmod(q - 2, 6), false, true).x - bob_passo(q, false, true).x

## Unidades de `anim` por pixel andado, por bicho: a mesma conta de ANIM_POR_PX com a passada de cada um (galope do Ladrão
## fugindo, passada dos chefes). A Campo usa isto para o pé não deslizar.
static func anim_por_px(chefe_tipo: int, fuga_ladrao: bool) -> float:
	var passada: float = PASSADA
	if fuga_ladrao:
		passada = PASSADA_FUGA
	elif chefe_tipo >= 0:
		passada = [2.5, 2.0, 3.5, 3.0, 3.0, 2.0, 2.5, 2.5, 2.5, 2.5][clampi(chefe_tipo, 0, 9)]
	return (float(QUADROS_PASSO) * 0.5 / PASSO_ANIM) / (2.0 * passada)

const PASSADA_FUGA := 4.0

## Unidades de `anim` por pixel do sprite andado: meio ciclo (3 quadros) para o pé de apoio varrer 2 x PASSADA pixels.
## A Campo avança `anim` pela distância andada (|dx| / (GATO_K * escala)) vezes isto: o pé fica parado no chão.
const ANIM_POR_PX := (float(QUADROS_PASSO) * 0.5 / PASSO_ANIM) / (2.0 * PASSADA)

## Pulo do Saltador (fase 0..1 do ciclo de `_HOP` unidades de anim): [altura, no ar (0 chão, 1 subindo, 2 descendo), agacha
## (0, 1 = preparando o pulo, 2 = amortecendo a aterrissagem)].
const HOP := 6.3
const HOP_ALT := 9.0
const HOP_SAI := 0.26      # fase em que deixa o chão
const HOP_POUSA := 0.78    # fase em que toca o chão
static func pulo(anim: float) -> Vector3i:
	var fase: float = fposmod(anim / HOP, 1.0)
	if fase < HOP_SAI:
		return Vector3i(0, 0, 1 if fase >= HOP_SAI - 0.12 else 0)
	if fase < HOP_POUSA:
		var t: float = (fase - HOP_SAI) / (HOP_POUSA - HOP_SAI)
		var h: int = roundi(HOP_ALT * sin(PI * t))
		if h <= 0:
			return Vector3i(0, 0, 2 if t > 0.5 else 1)
		return Vector3i(h, 1 if t < 0.5 else 2, 0)
	return Vector3i(0, 0, 2 if fase < HOP_POUSA + 0.12 else 0)

## Deslocamento VISUAL em x (pixels do sprite) do Saltador: a unidade anda em velocidade constante na simulação; o desenho concentra
## o avanço no ar (parado no chão, voa no pulo). Média zero no ciclo, então ele nunca se afasta de onde a unidade está.
static func avanco_pulo(anim: float) -> int:
	var fase: float = fposmod(anim / HOP, 1.0)
	var g: float = clampf((fase - HOP_SAI) / (HOP_POUSA - HOP_SAI), 0.0, 1.0)
	g = g * g * (3.0 - 2.0 * g)
	var comp: float = HOP / ANIM_POR_PX   # pixels andados num ciclo
	return roundi(comp * (g - fase + (HOP_SAI + HOP_POUSA) * 0.5 - 0.5))

## Tons extras de toda paleta de bicho: `#` = pata de longe (bem mais escura que o tom d, para as quatro patas lerem separadas).
static func pal_extra(P: Dictionary) -> void:
	if P.has("d") and not P.has("#"):
		var cd: Color = P["d"]
		var a: float = cd.a
		cd = cd.darkened(0.32)
		cd.a = a
		P["#"] = cd

## Desenha o quadro `s` ({"x", "y", "l"}) com a paleta `pal`. No nocaute (queda >= 0) o quadro gira em passos de 90 graus em volta
## do meio (a grade continua inteira) e, deitado, apoia o lombo no chão; de barriga para cima a luz troca (l <-> d).
static func sprite(c: CanvasItem, s: Dictionary, pal: Dictionary, f: float) -> void:
	if queda < 0.0 or (queda_giro == 0 and not queda_chao):
		RoupaGato.sprite(c, s["x"], s["y"], s["l"], pal, f)
		return
	var k: String = "g%d%d" % [queda_giro, int(queda_chao)]
	if not s.has(k):
		s[k] = girar(s, queda_giro, queda_chao)
	var r: Dictionary = s[k]
	RoupaGato.sprite(c, r["x"], r["y"], r["l"], pal, f)

static func girar(s: Dictionary, quartos: int, chao: bool) -> Dictionary:
	var lin: Array = s["l"]
	var h: int = lin.size()
	var w: int = String(lin[0]).length()
	var x0: int = s["x"]
	var y0: int = s["y"]
	var cx: int = x0 + w / 2
	var cy: int = y0 + h / 2
	var nw: int = h if quartos % 2 == 1 else w
	var nh: int = w if quartos % 2 == 1 else h
	var out: Array = []
	for j in nh:
		out.append(".".repeat(nw))
	var nx0: int = 0
	var ny0: int = 0
	if quartos % 4 == 1:
		# 90 graus no sentido anti-horário (focinho para cima): (dx, dy) -> (dy, -dx)
		nx0 = cx + (y0 - cy)
		ny0 = cy - (x0 + w - cx)
	else:
		nx0 = 2 * cx - (x0 + w)
		ny0 = 2 * cy - (y0 + h)
	for j in h:
		var src: String = lin[j]
		for i in w:
			var ch: String = src[i]
			if ch == ".":
				continue
			var ax: int = x0 + i
			var ay: int = y0 + j
			var bx: int
			var by: int
			if quartos % 4 == 1:
				bx = cx + (ay - cy)
				by = cy - (ax - cx) - 1
			else:
				bx = 2 * cx - ax - 1
				by = 2 * cy - ay - 1
				if ch == "l":
					ch = "d"
				elif ch == "d":
					ch = "l"
			var row: String = out[by - ny0]
			out[by - ny0] = row.substr(0, bx - nx0) + ch + row.substr(bx - nx0 + 1)
	if chao:
		ny0 = -nh   # lombo no chão
	return {"x": nx0, "y": ny0, "l": out}

## Arte nova (refeita do zero) de cada família de bichos comuns, um arquivo por família. Enquanto o arquivo
## de uma família não existe, ela continua com o desenho antigo (BichoPxA/BichoPxB).
const NOVOS: Array[String] = ["res://scripts/arte/bichos/bicho_px_rato.gd", "res://scripts/arte/bichos/bicho_px_guaxinim.gd", "res://scripts/arte/bichos/bicho_px_raposa.gd", "res://scripts/arte/bichos/bicho_px_corvo.gd", "res://scripts/arte/bichos/bicho_px_sapo.gd"]
static var _novos: Dictionary = {}

static func _novo(fam: int) -> Script:
	if not _novos.has(fam):
		var cam: String = NOVOS[fam] if fam >= 0 and fam < NOVOS.size() else ""
		_novos[fam] = load(cam) if cam != "" and ResourceLoader.exists(cam) else null
	return _novos[fam]

## Arte nova dos chefes: 0 a 4 (primeiro ato) num arquivo, 5 a 9 (fora da casa) noutro. Sem o arquivo, fica o desenho antigo.
const NOVOS_CHEFES: Array[String] = ["res://scripts/arte/bichos/bicho_px_chefe_casa.gd", "res://scripts/arte/bichos/bicho_px_chefe_fora.gd"]
static var _novos_chefes: Dictionary = {}

static func _novo_chefe(ct: int) -> Script:
	var i: int = 0 if ct < 5 else 1
	if not _novos_chefes.has(i):
		var cam: String = NOVOS_CHEFES[i]
		_novos_chefes[i] = load(cam) if ResourceLoader.exists(cam) else null
	return _novos_chefes[i]

## `chefe_tipo` < 0 = não é chefe. `filhote` = filhote solto da Ninhada. `parte` = sapinho do Sapo-Rei.
## `carregando` = ladrão fugindo com blocos. `parado` = Raposa Ligeira sem fôlego.
static func desenhar(c: CanvasItem, familia: int, tipo: int, anim: float, andando: bool, golpe: float, f: float, alfa: float, carregando: bool, filhote: bool, chefe_tipo: int, parte: bool, parado: bool) -> void:
	var fam: int = chefe_tipo if chefe_tipo >= 0 else familia
	var truque: bool = chefe_tipo < 0 and not parte and not filhote and _truque(tipo)
	var tp: int = _tipo_corpo(tipo) if truque else tipo
	pose_truque = tipo if truque else -1
	if chefe_tipo >= 0 and _novo_chefe(chefe_tipo) != null:
		_novo_chefe(chefe_tipo).desenhar(c, familia, tipo, anim, andando, golpe, f, alfa, carregando, filhote, chefe_tipo, parte, parado)
	elif chefe_tipo >= 5:
		BichoPxC.desenhar(c, familia, tipo, anim, andando, golpe, f, alfa, carregando, filhote, chefe_tipo, parte, parado)
	elif chefe_tipo < 0 and _novo(fam) != null:
		_novo(fam).desenhar(c, fam, tp, anim, andando, golpe, f, alfa, carregando, filhote, chefe_tipo, parte, parado)
	elif fam <= 2:
		BichoPxA.desenhar(c, fam, tp, anim, andando, golpe, f, alfa, carregando, filhote, chefe_tipo, parte, parado)
	else:
		BichoPxB.desenhar(c, fam, tp, anim, andando, golpe, f, alfa, carregando, filhote, chefe_tipo, parte, parado)
	pose_truque = -1
	if truque:
		BichoPxT.sobre(c, fam, tipo, anim, andando, golpe, f, alfa)

## Bichos de truque (Atirador, Curandeiro, Escudeiro, Bomba): corpo da família mais roupa e adereço (BichoPxT).
static func _truque(tipo: int) -> bool:
	return tipo >= Unidade.Tipo.ATIRADOR and tipo <= Unidade.Tipo.BOMBA

## Pixels pintados de uma camada da grade de letras, em coordenadas do bicho (y = 0 no chão): {Vector2i: true}.
static func recorte(L: PackedInt32Array, w: int, h: int, ox: int, oy: int) -> Dictionary:
	var m: Dictionary = {}
	for j in h:
		for i in w:
			if L[j * w + i] != 0:
				m[Vector2i(i - ox, j - oy)] = true
	return m

## Quadro em cache do bicho nesta pose: sprite ("x", "y", "l"), molde do tronco ("t") e crânio ("c"). Vazio para o sapinho do
## Sapo-Rei e para quem ainda não tem arte nova.
static func quadro(familia: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parte: bool, parado: bool = false) -> Dictionary:
	if parte:
		return {}
	if chefe_tipo >= 0:
		if _novo_chefe(chefe_tipo) == null:
			return {}
		var qc: Dictionary = ultimo_quadro
		if qc.is_empty():
			qc = _novo_chefe(chefe_tipo).quadro(chefe_tipo, anim, andando, golpe, parado)
		if not qc.has("id"):
			_ids_quadro += 1
			qc["id"] = _ids_quadro
		return qc
	if _novo(familia) == null:
		return {}
	var q: Dictionary = ultimo_quadro
	if q.is_empty():
		pose_truque = -1
		if _truque(tipo):
			pose_truque = tipo
			tipo = _tipo_corpo(tipo)
		q = _novo(familia).quadro(tipo, anim, andando, golpe)
		pose_truque = -1
	if not q.has("id"):
		_ids_quadro += 1
		q["id"] = _ids_quadro   # o mesmo dicionário fica no cache da família: a identidade vale enquanto a pose existir
	return q

static var _ids_quadro: int = 0
## Último quadro desenhado por uma família (cada uma grava aqui em desenhar()); quem desenha o bicho esvazia antes.
static var ultimo_quadro: Dictionary = {}

## Caixa do molde do tronco: Rect2i em pixels do bicho.
static func caixa_tronco(q: Dictionary) -> Rect2i:
	if q.has("caixa"):
		return q["caixa"]
	var m: Dictionary = q["t"]
	var r := Rect2i()
	var primeiro: bool = true
	for p in m.keys():
		var v: Vector2i = p
		if primeiro:
			r = Rect2i(v, Vector2i.ONE)
			primeiro = false
		else:
			r = r.expand(v).expand(v + Vector2i.ONE)
	q["caixa"] = r
	return r

## Tira do molde do tronco `TR` (grade de largura `w` e altura `h`) os pixels que as linhas `rows` pintam em (x, y): a cabeça e o
## que mais fica por cima do tronco. A roupa de corpo é desenhada depois do bicho; sem isso ela cobriria a cabeça.
static func tirar(TR: PackedInt32Array, w: int, h: int, x: int, y: int, rows: Array) -> void:
	for j in rows.size():
		var s: String = rows[j]
		for i in s.length():
			if s[i] != "." and x + i >= 0 and x + i < w and y + j >= 0 and y + j < h:
				TR[(y + j) * w + x + i] = 0

## Tira do molde `TR` (grade de largura `w`) as manchas grandes (12 pixels ou mais) que mudaram na camada `B` depois dele (chefes):
## cabeça, barriga e adereços pintados depois ficam por cima da roupa de corpo, à mostra. Marquinhas pequenas (pintas, pelos)
## ficam no molde: furar a manta nelas deixava a roupa em retalhos.
static func manter_iguais(TR: PackedInt32Array, B: PackedInt32Array, w: int) -> void:
	var visto: Dictionary = {}
	for k in TR.size():
		if TR[k] == 0 or B[k] == TR[k] or visto.has(k):
			continue
		var comp: Array = []
		var pilha: Array = [k]
		visto[k] = true
		while not pilha.is_empty():
			var p: int = pilha.pop_back()
			comp.append(p)
			for d in [1, -1, w, -w]:
				var q: int = p + d
				if q < 0 or q >= TR.size() or visto.has(q) or (absi(d) == 1 and q / w != p / w):
					continue
				if TR[q] != 0 and B[q] != TR[q]:
					visto[q] = true
					pilha.append(q)
		if comp.size() >= 12:
			for p2 in comp:
				TR[p2] = 0

## Chefes cuja coroa ou capacete é a identidade (Rei dos Ratos, Sapo-Rei, Toupeira, Texugo-Rei): não vestem peça de cabeça.
## A coroa fica; o chapéu da fantasia por cima dela tapava o rei, e um do lado do outro não cabe na cabeça.
static func coroa_fixa(chefe_tipo: int) -> bool:
	return chefe_tipo == 0 or chefe_tipo == 4 or chefe_tipo == 5 or chefe_tipo == 9

## Largura do crânio do gato (as três primeiras linhas da cabeça, sem orelhas): o tamanho para o qual as peças de cabeça foram feitas.
const CRANIO_GATO := 10

## Largura do crânio de uma cabeça desenhada em linhas de letras: o trecho pintado mais largo das três primeiras linhas, sem as
## letras de `fora` (bico do corvo), que não entram no chapéu.
static func cranio(rows: Array, fora: String = "") -> int:
	var r: int = 0
	for j in mini(3, rows.size()):
		var s: String = rows[j]
		var ini: int = -1
		var fim: int = -1
		for i in s.length():
			if s[i] != "." and not fora.contains(s[i]):
				if ini < 0:
					ini = i
				fim = i
		if ini >= 0:
			r = maxi(r, fim - ini + 1)
	return r

## Colunas e linhas que a peça de cabeça ganha neste quadro (RoupaGato.desenhar_esticada): acompanha o crânio do bicho ("c" do
## quadro); a altura cresce metade do que cresce a largura (até 3), para o chapéu não achatar nem virar torre.
static func esticar_cabeca(q: Dictionary) -> Vector2i:
	var cr: int = int(q.get("c", 0))
	if cr <= CRANIO_GATO:
		return Vector2i.ZERO
	var ex: int = mini(cr - CRANIO_GATO, 12)
	return Vector2i(ex, mini(ex / 2, 3))

## Pés do bicho no chão neste quadro, de trás para a frente (x do meio de cada pé, y do chão), lidos da última linha do desenho.
static func pes(q: Dictionary) -> Array[Vector2]:
	var r: Array[Vector2] = []
	var linhas: Array = q["l"]
	var base: String = linhas[linhas.size() - 1]
	var chao: float = float(q["y"]) + linhas.size()
	var i: int = 0
	while i < base.length():
		if base[i] == ".":
			i += 1
			continue
		var ini: int = i
		while i < base.length() and base[i] != ".":
			i += 1
		r.append(Vector2(float(q["x"]) + (ini + i) * 0.5, chao))
	return r

## Corpo-base de cada truque: o Escudeiro usa o corpo parrudo do Grandalhão, os outros o comum.
static func _tipo_corpo(tipo: int) -> int:
	return Unidade.Tipo.GIGANTE if tipo == Unidade.Tipo.ESCUDEIRO else Unidade.Tipo.COMUM

## Quanto o lugar `onde` (RoupaGato.Onde) se desloca, em pixels, em relação à planta parada, na pose atual
## (balanço do passo, cabeça que avança no golpe, chefe curvado). As roupas acompanham por aqui.
static func desloc(onde: int, familia: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parado: bool) -> Vector2:
	var fam: int = chefe_tipo if chefe_tipo >= 0 else familia
	pose_truque = -1
	if chefe_tipo < 0 and _truque(tipo):
		pose_truque = tipo
		tipo = _tipo_corpo(tipo)
	var r: Vector2
	if chefe_tipo >= 0 and _novo_chefe(chefe_tipo) != null:
		r = _novo_chefe(chefe_tipo).desloc(onde, familia, tipo, anim, andando, golpe, chefe_tipo, parado)
	elif chefe_tipo >= 5:
		r = BichoPxC.desloc(onde, familia, tipo, anim, andando, golpe, chefe_tipo, parado)
	elif chefe_tipo < 0 and _novo(fam) != null:
		r = _novo(fam).desloc(onde, fam, tipo, anim, andando, golpe, chefe_tipo, parado)
	elif fam <= 2:
		r = BichoPxA.desloc(onde, fam, tipo, anim, andando, golpe, chefe_tipo, parado)
	else:
		r = BichoPxB.desloc(onde, fam, tipo, anim, andando, golpe, chefe_tipo, parado)
	pose_truque = -1
	return r
