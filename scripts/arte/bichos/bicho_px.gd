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
