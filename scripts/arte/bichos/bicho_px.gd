class_name BichoPx
extends RefCounted
## Os bichos inimigos em pixel art, de quatro patas, desenhados por código na mesma grade de pixels do gato.
## Unidade: 1 = um pixel. O bicho é desenhado olhando para a DIREITA (+x), com as patas no chão em y = 0
## e centrado em x = 0; quem chama espelha para ele olhar para a esquerda.
## O corpo segue a mesma planta do gato para vestir as mesmas roupas (ver RoupaGato.ORIGEM):
## topo do crânio em (5.5, -16), centro do tronco em (-0.5, -9), ponta do focinho em (11, -11),
## alto da anca em (-8, -12), pescoço em (2, -11), patas da frente no chão em x = 4.5.
## Bichos comuns com arte nova ficam um arquivo por família (ver NOVOS); os chefes e as famílias ainda sem arquivo novo seguem em BichoPxA (0 a 2) e BichoPxB (3 e 4).

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

## Tronco do gato que as peças de corpo cobrem (largura e altura em pixels): os bichos maiores esticam a peça até o tronco deles.
const TRONCO_GATO := Vector2i(12, 8)

## Colunas e linhas que a peça de corpo ganha neste bicho (RoupaGato.esticar). Chefes e famílias sem arte nova: nada.
static func esticar_corpo(familia: int, tipo: int, anim: float, andando: bool, golpe: float, chefe_tipo: int, parte: bool) -> Vector2i:
	if chefe_tipo >= 0 or parte or _novo(familia) == null:
		return Vector2i.ZERO
	pose_truque = -1
	if _truque(tipo):
		pose_truque = tipo
		tipo = _tipo_corpo(tipo)
	var s: Script = _novo(familia)
	var g: Dictionary = s._geo(tipo, anim, andando, golpe, false) if familia == 4 else s._geo(tipo, anim, andando, golpe, false, false)
	pose_truque = -1
	return Vector2i(clampi(int(g["bw"]) - TRONCO_GATO.x, 0, 10), clampi(int(g["bh"]) - TRONCO_GATO.y, 0, 3))

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
