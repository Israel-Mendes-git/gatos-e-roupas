class_name RoupaGatoE
extends RefCounted
## Roupas do gato em pixel art, tipos 84 a 99 (ver RoupaGato para as convenções).
## Fantasias do lado de fora: Ninja da Folha (84-87), Robô Azul (88-91), Tubarão (92-95) e Abelha (96-99).
##
## DESENHO PROVISÓRIO: formas simples na cor do kit, só para o jogo funcionar. A ARTISTA DEVE SUBSTITUIR:
##   - `desenhar(c, tipo, f, anim)`: o desenho de cada peça, em torno da origem do lugar onde ela fica presa
##     (cabeça = topo do crânio; corpo = centro do tronco; boca = ponta do focinho; traseira = alto da anca;
##     pescoço = entre cabeça e tronco). 1 unidade = 1 pixel do gato. Hoje usa a tabela `PECAS` + RoupaGato.sprite.
##   - `onde(tipo)`: o lugar das peças de mão e acessório (-1 = padrão: mão na boca, acessório na traseira).
##   - `caixa(tipo)`: caixa ocupada pelo desenho (para centralizar o ícone). Hoje é calculada da tabela `PECAS`;
##     se trocar o desenho por código livre, devolva um Rect2 à mão ou rode mede_icones.gd e copie para IconeDados.
## Como testar: abra o guarda-roupa/fichário (tecla F) e veja os ícones; vista as 4 peças de um kit num gato
##   (teste sem janela: `bugs\teste_kits.gd`; com imagem, use captura.py fora da tela, nunca abra janela do Godot).
##   Confira também a aba Fantasias, o fichário (seção "Lado de fora") e os inimigos fantasiados nos lugares de fora.

const _PRETO := Color(0.12, 0.1, 0.14)

## Lugar do acessório no gato (RoupaGato.Onde); -1 = padrão.
static func onde(tipo: int) -> int:
	if tipo == Pecas.Tipo.BOIA:
		return RoupaGato.Onde.PESCOCO
	return -1

## Tabela provisória: tipo -> [x, y, linhas]. A paleta é a do kit (ver _paleta).
const PECAS := {
	Pecas.Tipo.BANDANA_FOLHA: [-4.5, -2.0, [
		"..ooooooo..", ".oaaaaaaao.", "oaassssaaao", "oaassssaaao", "oooooooooo.", ]],
	Pecas.Tipo.MACACAO_LARANJA: [-5.5, -3.0, [
		".ooooooooo.", "oaaaaaaaaao", "oabbaaabbao", "oaaaaaaaaao", "oaaaaaaaaao", ".ooooooooo.", ]],
	Pecas.Tipo.KUNAI: [-3.0, -3.0, [
		"..oo....", ".oso...", "osso...", ".ooo...", "..oao..", "..oao..", "...o...", ]],
	Pecas.Tipo.PERGAMINHO: [-3.0, -3.0, [
		"oooooo.", "obbbbbo", "oboobbo", "obbbbbo", "oaaaaao", "oooooo.", ]],
	Pecas.Tipo.CAPACETE_AZUL: [-4.5, -2.0, [
		"..ooooooo..", ".oaaaaaaao.", "oabbaaaaaao", "oaaaaaaaaao", "oaaooooaaao", "ooo.....ooo", ]],
	Pecas.Tipo.ARMADURA_AZUL: [-5.5, -3.0, [
		".ooooooooo.", "oaaaaaaaaao", "oabbsssbbao", "oaaassaaaao", "oaaaaaaaaao", ".ooooooooo.", ]],
	Pecas.Tipo.CANHAO_BRACO: [-3.0, -3.0, [
		"..oooooo", "oaabbssso", "oaaaasso.", "oooooooo", ]],
	Pecas.Tipo.TANQUE: [-3.0, -4.0, [
		".oooo.", "oaaaao", "obbbbo", "obbbbo", "oaaaao", ".oooo.", ]],
	Pecas.Tipo.CAPUZ_TUBARAO: [-4.5, -4.0, [
		".....o.....", "....oao....", "...oaaao...", "..oaaaaao..", ".oaaaaaaao.", "oaassaassao", "oaaaaaaaaao", ]],
	Pecas.Tipo.ROUPA_TUBARAO: [-5.5, -3.0, [
		".ooooooooo.", "oaaaaaaaaao", "oaaaaaaaaao", "oasssssssao", "osssssssso.", ".ooooooooo.", ]],
	Pecas.Tipo.MORDIDA: [-3.0, -3.0, [
		"oooooooo", "osososos", "oaaaaaao", "osososos", "oooooooo", ]],
	Pecas.Tipo.BOIA: [-4.0, -3.0, [
		"..oooooo..", ".orrwwrro.", "orr....rro", "owr....rwo", "orr....rro", ".orrwwrro.", "..oooooo..", ]],
	Pecas.Tipo.ANTENAS: [-4.5, -7.0, [
		"o.......o.", "bo.....ob.", ".o.....o..", ".ooo.ooo..", ]],
	Pecas.Tipo.COLETE_LISTRADO: [-5.5, -3.0, [
		".ooooooooo.", "oaaaaaaaaao", "okkkkkkkkko", "oaaaaaaaaao", "okkkkkkkkko", ".ooooooooo.", ]],
	Pecas.Tipo.FERRAO: [-3.0, -3.0, [
		"oooo....", "oaaaooo.", "oaaaabbo", "oaaaooo.", "oooo....", ]],
	Pecas.Tipo.POTE_MEL: [-3.0, -4.0, [
		".oooo.", "ommmmo", "oaaaao", "oabbao", "oaaaao", ".oooo.", ]],
}

## Paleta do kit da peça: o = contorno, a = cor principal, b = realce, s = detalhe claro, k = listra, r/w/m = extras.
static func _paleta(tipo: int) -> Dictionary:
	var cor: Color = Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[tipo]]
	var p: Dictionary = {"o": cor.darkened(0.65), "a": cor, "b": cor.lightened(0.45), "s": Color(0.85, 0.88, 0.92),
		"k": _PRETO, "r": Color(0.9, 0.2, 0.2), "w": Color(1, 1, 1), "m": Color(1.0, 0.75, 0.15)}
	if Pecas.CONJUNTO_DE[tipo] == Pecas.Conjunto.ABELHA:
		p["a"] = Color(1.0, 0.85, 0.15)
	return p

## Caixa ocupada pelo desenho (pixels do gato, relativa à origem do lugar).
static func caixa(tipo: int) -> Rect2:
	if not PECAS.has(tipo):
		return Rect2(-4, -4, 8, 8)
	var d: Array = PECAS[tipo]
	var larg: int = 0
	for l in d[2]:
		larg = maxi(larg, (l as String).length())
	return Rect2(d[0], d[1], larg, (d[2] as Array).size())

static func desenhar(c: CanvasItem, tipo: int, f: float, _anim: float) -> void:
	if not PECAS.has(tipo):
		return
	var d: Array = PECAS[tipo]
	RoupaGato.sprite(c, d[0], d[1], d[2], _paleta(tipo), f)
