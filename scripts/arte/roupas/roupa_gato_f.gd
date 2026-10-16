class_name RoupaGatoF
extends RefCounted
## Roupas do gato em pixel art, tipos 100 em diante (ver RoupaGato para as convenções): expansão das fantasias, lote 1
## (Super Miau 100-103, Arqueiro Miau 104-107, Motoqueiro Miausma 108-111, Fênix Miaussimo 112-115, Mimiau 116-119, Jimiau 120-123).
##
## FALLBACK: enquanto uma peça não tem arte própria em `_camadas`, desenha a silhueta de uma peça do mesmo espaço (cabeça, corpo,
## mão ou acessório do lado de fora, em RoupaGatoE.PECAS) tingida com a cor da fantasia.
## COMO O ARTISTA ENTRA: devolva em `_camadas` as camadas [x, y, linhas, paleta] da peça (mesmo formato de RoupaGatoE._camadas);
## `caixa` e `desenhar` já usam o que vier de lá. Descrição visual de cada peça: para_arte.md.

const PRIMEIRO := 100
const _MOLDE_FALLBACK: Array[int] = [Pecas.Tipo.CAPACETE_AZUL, Pecas.Tipo.COLETE_LISTRADO, Pecas.Tipo.KUNAI, Pecas.Tipo.TANQUE]   # por espaço

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão (cabeça, corpo, boca e traseira).
static func onde(tipo: int) -> int:
	return -1

## Camadas da peça com arte própria; vazio = usa o fallback.
static func _camadas(_tipo: int, _anim: float, _maxima: bool = false) -> Array:
	return []

static func _fallback(tipo: int) -> Array:
	return RoupaGatoE.PECAS[_MOLDE_FALLBACK[Pecas.SLOT[tipo]]]

static func caixa(tipo: int) -> Rect2:
	var cs: Array = _camadas(tipo, 0.0, true)
	if cs.is_empty():
		var d: Array = _fallback(tipo)
		cs = [[d[0], d[1], d[2], {}]]
	var r := Rect2()
	var primeiro: bool = true
	for cm in cs:
		var larg: int = 0
		for l in cm[2]:
			larg = maxi(larg, (l as String).length())
		var rc := Rect2(cm[0], cm[1], larg, (cm[2] as Array).size())
		r = rc if primeiro else r.merge(rc)
		primeiro = false
	return r

static func desenhar(c: CanvasItem, tipo: int, f: float, anim: float) -> void:
	var cs: Array = _camadas(tipo, anim)
	if not cs.is_empty():
		for cm in cs:
			RoupaGato.sprite(c, cm[0], cm[1], cm[2], cm[3], f)
		return
	var d: Array = _fallback(tipo)
	RoupaGato.sprite(c, d[0], d[1], d[2], RoupaGatoE._paleta(tipo), f)
