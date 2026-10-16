class_name RoupaBicho
extends RefCounted
## As fantasias redesenhadas para os bichos: em vez de converter o desenho do gato, cada fantasia tem um chapéu pequeno feito à mão
## (no alto do crânio, deixando olhos e focinho à mostra) e uma peça de corpo curta (colete, capa, casco, cinto) moldada no tronco
## de cada bicho, com contorno, luz e sombra próprios. Unidade: 1 = um pixel do bicho; o bicho olha para a direita (+x).

# ------------------------------------------------------------------ cores
## Paleta de cada fantasia: a = cor principal, A = luz, d = sombra, b = segunda cor, B = luz da segunda, e = enfeite.
## As letras comuns (o, w, k, y, Y) valem para todas (ver _COMUM).
const _COMUM: Dictionary = {
	"o": Color("1e1822"), "w": Color("f4f2ea"), "W": Color("c8c6cc"), "k": Color("2a2630"), "y": Color("f2c230"), "Y": Color("fff09a"),
	"r": Color("d8323a"), "R": Color("ff7a6a"), "g": Color("8a8e9c"), "G": Color("c8ccd8"),
}
const _PAL: Array = [
	{"a": Color("9aa6b8"), "A": Color("dce4ee"), "d": Color("5e6880"), "b": Color("c83838"), "B": Color("ff6a5a"), "e": Color("f2c230")},   # cavaleiro
	{"a": Color("3e9a68"), "A": Color("7ad49a"), "d": Color("23603e"), "b": Color("e8e2c8"), "B": Color("ffffff"), "e": Color("c8a040")},   # guardião
	{"a": Color("c42a36"), "A": Color("ee5a5e"), "d": Color("7c1424"), "b": Color("f4f0e8"), "B": Color("ffffff"), "e": Color("f2c230")},   # rei
	{"a": Color("e04038"), "A": Color("ff8070"), "d": Color("901c20"), "b": Color("a0663a"), "B": Color("d0945a"), "e": Color("2a2630")},   # circo
	{"a": Color("8a5a34"), "A": Color("c89060"), "d": Color("54341c"), "b": Color("d8c8a8"), "B": Color("f4ead0"), "e": Color("9aa0aa")},   # viking
	{"a": Color("e8dcb4"), "A": Color("fff6d8"), "d": Color("b0a07a"), "b": Color("5aa83a"), "B": Color("8ad860"), "e": Color("d0a040")},   # jardineiro
	{"a": Color("c87a3a"), "A": Color("eca866"), "d": Color("844a20"), "b": Color("d8423a"), "B": Color("f2c230"), "e": Color("5a3a20")},   # caubói
	{"a": Color("2c3e78"), "A": Color("4a64b0"), "d": Color("18224a"), "b": Color("c8323a"), "B": Color("f2c230"), "e": Color("f4f0e8")},   # pirata
	{"a": Color("6a3cb0"), "A": Color("9a6ae0"), "d": Color("3c1e70"), "b": Color("f2c230"), "B": Color("fff09a"), "e": Color("a8e0ff")},   # mago
	{"a": Color("2e58c8"), "A": Color("5a86f0"), "d": Color("1a3480"), "b": Color("d8302e"), "B": Color("ff6a5a"), "e": Color("f2c230")},   # encanador
	{"a": Color("3a3c4c"), "A": Color("62667e"), "d": Color("1e1e2a"), "b": Color("f2c230"), "B": Color("fff09a"), "e": Color("8a8e9c")},   # homem-morcego
	{"a": Color("d42a34"), "A": Color("ff6064"), "d": Color("80141e"), "b": Color("2e58c8"), "B": Color("5a86f0"), "e": Color("1e1822")},   # garoto-aranha
	{"a": Color("dcc89a"), "A": Color("f6ead0"), "d": Color("a08c64"), "b": Color("6a4a2c"), "B": Color("8e6a44"), "e": Color("66c8ff")},   # cavaleiro estelar
	{"a": Color("2a2a34"), "A": Color("5a5c70"), "d": Color("121218"), "b": Color("8a8e9c"), "B": Color("c8ccd8"), "e": Color("e83a3a")},   # lorde sombrio
	{"a": Color("3a9a3a"), "A": Color("70d060"), "d": Color("1e5e24"), "b": Color("8a5a30"), "B": Color("b07a44"), "e": Color("f2c230")},   # herói do bosque
	{"a": Color("5e9440"), "A": Color("92c468"), "d": Color("3c6a2e"), "b": Color("e3cf8c"), "B": Color("f5e8b4"), "e": Color("e8873a")},   # tartaruga ninja (Miauchelangelo)
	{"a": Color("2a5ae0"), "A": Color("6a92ff"), "d": Color("16308c"), "b": Color("f0d0a0"), "B": Color("fff0d8"), "e": Color("d8302e")},   # ouriço veloz
	{"a": Color("c8282a"), "A": Color("f2605a"), "d": Color("7a1418"), "b": Color("e8b030"), "B": Color("fff09a"), "e": Color("8ae8ff")},   # armadura de ferro
	{"a": Color("b82430"), "A": Color("e85a5a"), "d": Color("6c1018"), "b": Color("8a8e9c"), "B": Color("dce0ea"), "e": Color("f2c230")},   # deus do trovão
	{"a": Color("8ad0f4"), "A": Color("dcf4ff"), "d": Color("4a8ec0"), "b": Color("ffffff"), "B": Color("ffffff"), "e": Color("2e7ac0")},   # princesa do gelo
	{"a": Color("eeeef2"), "A": Color("ffffff"), "d": Color("a8a8b8"), "b": Color("7a4ac0"), "B": Color("a87ae8"), "e": Color("7ae040")},   # patrulheiro espacial
	{"a": Color("f08a1e"), "A": Color("ffb458"), "d": Color("a85410"), "b": Color("2a2630"), "B": Color("4a4654"), "e": Color("9aa6b8")},   # ninja da folha
	{"a": Color("2e78e0"), "A": Color("6ab4ff"), "d": Color("1a4490"), "b": Color("a8e0ff"), "B": Color("e4f6ff"), "e": Color("f2c230")},   # robô azul
	{"a": Color("7a90a8"), "A": Color("b0c4d8"), "d": Color("4a5a70"), "b": Color("f2f2ec"), "B": Color("ffffff"), "e": Color("d8302e")},   # tubarão
	{"a": Color("f2c230"), "A": Color("ffe68a"), "d": Color("b08418"), "b": Color("2a2630"), "B": Color("4a4654"), "e": Color("c8ecff")},   # abelha
	# lote 1 da expansão (25 a 30)
	{"a": Color("3366f2"), "A": Color("73a6ff"), "d": Color("1a38a8"), "b": Color("db1f29"), "B": Color("ff6157"), "e": Color("ffdb33")},   # super miau
	{"a": Color("339947"), "A": Color("73d980"), "d": Color("1a5c29"), "b": Color("80511f"), "B": Color("c78f4a"), "e": Color("e62e2e")},   # arqueiro miau
	{"a": Color("33333f"), "A": Color("666680"), "d": Color("14141c"), "b": Color("ff8519"), "B": Color("ffdb40"), "e": Color("949bb8"), "r": Color("e63814")},   # motoqueiro miausma
	{"a": Color("385cc7"), "A": Color("7aa3f7"), "d": Color("1f3380"), "b": Color("db1f29"), "B": Color("fafaff"), "e": Color("ffd138")},   # fênix miaussimo
	{"a": Color("fadb57"), "A": Color("fff59e"), "d": Color("cca32e"), "b": Color("eb3333"), "B": Color("ff8066"), "e": Color("734d24")},   # mimiau
	{"a": Color("8c40d9"), "A": Color("bf80f2"), "d": Color("592194"), "b": Color("4dc24d"), "B": Color("99e68c"), "e": Color("ffd638")},   # jimiau
	# lote 2 da expansão (31 a 36)
	{"a": Color("6fc845"), "A": Color("a9e27b"), "d": Color("43923a"), "b": Color("2f9440"), "B": Color("58b64c"), "e": Color("0e1a12")},   # disparamiau
	{"a": Color("f2de59"), "A": Color("fff59e"), "d": Color("c8b030"), "b": Color("4aa83a"), "B": Color("8ad860"), "e": Color("f2c230")},   # milhau
	{"a": Color("f4c430"), "A": Color("ffe98a"), "d": Color("d99a12"), "b": Color("7a4a1e"), "B": Color("9a6a32"), "e": Color("1a0f08")},   # giramiau
	{"a": Color("e3bf6a"), "A": Color("f5de9a"), "d": Color("b88e40"), "b": Color("3f66b0"), "B": Color("6b90d0"), "e": Color("6a4220")},   # stardew miaulley
	{"a": Color("4a2f1b"), "A": Color("5e3f25"), "d": Color("33200f"), "b": Color("3b3fa0"), "B": Color("5a5fc8"), "e": Color("35e6c4")},   # miaucraft
	{"a": Color("3b7f86"), "A": Color("62a8a8"), "d": Color("285a66"), "b": Color("f6e7bd"), "B": Color("fff6d8"), "e": Color("1b2a30")},   # miaulax
	# lote 3 da expansão (37 a 42)
	{"a": Color("3470d0"), "A": Color("7ba5ec"), "d": Color("22489c"), "b": Color("e3cf8c"), "B": Color("f5e8b4"), "e": Color("e8bf3c")},   # leonarmiau
	{"a": Color("8a4fc0"), "A": Color("b98ae0"), "d": Color("5c3492"), "b": Color("e3cf8c"), "B": Color("5fd08a"), "e": Color("e8bf3c")},   # donatemiau
	{"a": Color("d03a34"), "A": Color("f0786a"), "d": Color("8c2024"), "b": Color("e3cf8c"), "B": Color("f5e8b4"), "e": Color("e8bf3c")},   # rafamiau
	{"a": Color("26a0ff"), "A": Color("7fd0ff"), "d": Color("1060b0"), "b": Color("ff8a1c"), "B": Color("ffc060"), "e": Color("ffffff"), "v": Color("1a2a3e"), "V": Color("4a6a88")},   # rocket miaugue
	{"a": Color("cc1a26"), "A": Color("ff5a60"), "d": Color("80101a"), "b": Color("2a2630"), "B": Color("5a5666"), "e": Color("ffffff")},   # deadmiau
	{"a": Color("94603a"), "A": Color("bc8a5e"), "d": Color("5e3a22"), "b": Color("cda85a"), "B": Color("f0d58c"), "e": Color("d8c8a0")},   # meon
]

## Cores da roupa de corpo que diferem das do chapéu (o barril do circo é de madeira, o avental do jardineiro é verde).
const _PAL_CORPO: Dictionary = {
	0: {"a": Color("7a88a4"), "A": Color("d0dcee"), "d": Color("4a5672")},
	3: {"a": Color("d8323a"), "A": Color("ff7066"), "d": Color("8a1820")},
	4: {"a": Color("cfc4ae"), "A": Color("f2ead6"), "d": Color("8e8270")},
	5: {"a": Color("4a9a34"), "A": Color("82d05a"), "d": Color("2a5e1e"), "b": Color("e8dcb4")},
	10: {"a": Color("2c2e3c"), "A": Color("50546a"), "d": Color("16161e")},
	23: {"a": Color("5a7894"), "A": Color("98b4cc"), "d": Color("34485e")},
	30: {"a": Color("f6f2ea"), "A": Color("ffffff"), "d": Color("bfb9c6")},
	31: {"a": Color("2f9440"), "A": Color("58b64c"), "d": Color("1d5e2c"), "b": Color("8edb5a"), "B": Color("d6f5a8")},
	32: {"a": Color("4aa83a"), "A": Color("8ad860"), "d": Color("2f7a34"), "b": Color("f2de59")},
	33: {"a": Color("3c9a3c"), "A": Color("6cc15a"), "d": Color("256e2e"), "b": Color("f4c430"), "B": Color("ffe98a")},
	34: {"a": Color("3f66b0"), "A": Color("6b90d0"), "d": Color("284585"), "b": Color("c8453c"), "B": Color("e8776a")},
	35: {"a": Color("2eb8b8"), "A": Color("5ed6d0"), "d": Color("1b8a8c"), "b": Color("3b3fa0"), "B": Color("5a5fc8")},
	15: _CASCO_BICHO, 37: _CASCO_BICHO, 38: _CASCO_BICHO, 39: _CASCO_BICHO,
}
## Casco do kit Tartaruga nos bichos: verde, plastrão bege na borda e a fivela dourada (e).
const _CASCO_BICHO: Dictionary = {"a": Color("5e9440"), "A": Color("92c468"), "d": Color("3c6a2e"), "b": Color("e3cf8c"), "B": Color("f5e8b4"), "e": Color("e8bf3c"), "t": Color("8a5a30")}
static var corpo_vez: bool = false

static func _cor(conj: int, ch: String) -> Color:
	if corpo_vez and _PAL_CORPO.has(conj) and _PAL_CORPO[conj].has(ch):
		return _PAL_CORPO[conj][ch]
	var p: Dictionary = _PAL[conj]
	if p.has(ch):
		return p[ch]
	return _COMUM.get(ch, Color.MAGENTA)

# ------------------------------------------------------------------ chapéus
## Chapéu de cada fantasia em linhas de letras, olhando para a direita. A última linha fica `_DESCE` pixels abaixo do topo do crânio
## (o chapéu abraça a cabeça). "cheio": o chapéu cresce até a largura do crânio (repete a coluna do meio); os outros têm tamanho fixo.
const _CHAPEU: Array = [
	# 0 cavaleiro: elmo de aço com pluma
	{"cheio": true, "l": [
		"......rR...",
		".....rRr...",
		"...ooooro..",
		"..oAAaaaoo.",
		".oAaaaaaado",
		".oaaaaaaado",
		".odkdkdkddo",
		"..ooooooooo"]},
	# 1 guardião: capuz verde com crista de espinhos
	{"cheio": true, "l": [
		"...o.o.o...",
		"..oBoBoBo..",
		"..oaaaaao..",
		".oAAaaaado.",
		".oAaaaaaddo",
		"oddddddddo.",
		".ooooooooo."]},
	# 2 rei: coroa de ouro com pedra
	{"cheio": false, "l": [
		".o..o..o.",
		"oYo.oYo.Yo",
		"oyyoyyyoyo",
		"oyyyryyyyo",
		"oyYyyyyYyo",
		".oooooooo."]},
	# 3 circo: cartola listrada, inclinada para trás
	{"cheio": false, "l": [
		"..ooooo...",
		".okkkkko..",
		".okAkkko..",
		".oaaaaao..",
		".okkkkko..",
		"ooooooooo.",
		"okkkkkkkko",
		".oooooooo."]},
	# 4 viking: capacete com chifres
	{"cheio": true, "l": [
		"o.........o",
		"wo.......ow",
		"Wwo.ooo.owW",
		"oWwoGggowWo",
		".oooGgggoo.",
		".oGGggggdo.",
		".oyyyyyyyo.",
		"..ooooooo.."]},
	# 5 jardineiro: chapéu de palha com fita verde
	{"cheio": false, "l": [
		"....ooooo....",
		"...oAAaaao...",
		"...oaaaado...",
		"...obbbbbo...",
		".ooaaaaaaaoo.",
		"oAAaAaAaAaado",
		".ooooooooooo."]},
	# 6 caubói: chapéu de aba virada
	{"cheio": false, "l": [
		"....ooooo....",
		"...oAaoaao...",
		"...oaaaaado..",
		"o..obbbbbbo.o",
		"oaoaaaaaaaoao",
		".oAaaaaaaaado",
		"..ooooooooo.."]},
	# 7 pirata: tricórnio com caveira
	{"cheio": false, "l": [
		"....ooooo....",
		"...okkkkko...",
		"..okkwwwkko..",
		".okkkwkwkkko.",
		"okkkkkkkkkkko",
		"oyykkkkkkkyyo",
		".ooo.....ooo."]},
	# 8 mago: chapéu pontudo com estrela e ponta caída para trás
	{"cheio": false, "l": [
		"oo.......",
		"oaoo.....",
		".oAaoo...",
		"..oAado..",
		"...oAado.",
		"...oayaao",
		"..oaYyado",
		".oAaaaaado",
		"oddddddddo",
		".oooooooo."]},
	# 9 encanador: boné com aba para a frente e emblema branco
	{"cheio": true, "l": [
		"...ooooo....",
		"..oAbbbbo...",
		".oAbwwwbbo..",
		".obbwbwbbo..",
		"obbbbbbbbbooo",
		"oBbbbbbbbbbBBo",
		".oooooooooooo."]},
	# 10 homem-morcego: capuz com orelhas pontudas
	{"cheio": true, "l": [
		"o........o.",
		"oo......oo.",
		"oAo....oao.",
		"oAaooooaao.",
		"oAaaaaaaado",
		"oaaaaaaaado",
		"oaaaaaaaddo",
		".ooooooooo."]},
	# 11 garoto-aranha: capuz vermelho com teia
	{"cheio": true, "l": [
		"...ooooo...",
		"..oaAkaao..",
		".oAakkkaao.",
		".oakakakado",
		".okkkkkkkdo",
		".oaakakaado",
		"..ooooooooo"]},
	# 12 cavaleiro estelar: capuz de pano caído para trás
	{"cheio": true, "l": [
		"...ooooo...",
		"..oAAaaao..",
		".oAaaaaaado",
		"oaaaaaaaado",
		"odaaaaaaddo",
		"oddo.oooooo",
		".oo........"]},
	# 13 lorde sombrio: elmo preto lustroso com aba larga
	{"cheio": true, "l": [
		"...ooooo...",
		"..oaAAaao..",
		".oaAaaaado.",
		".oaaaaaaddo",
		"oaaaaaaaaddo",
		"oddddddddddo",
		".ooooooooooo"]},
	# 14 herói do bosque: gorro verde caído para trás
	{"cheio": false, "l": [
		"o.........",
		"ooo.......",
		"oaaoo.....",
		".oAaaoooo.",
		"..oAaaaaao",
		"..oaaaaaado",
		".obbbbbbbo",
		"..oooooooo"]},
	# 15 tartaruga ninja: faixa azul com pontas soltas atrás
	{"cheio": true, "l": [
		"oo.........",
		"oeoo.......",
		".oeeoooooo.",
		"oeweeeeeeeo",
		"oeeeeeeeeeo",
		".ooooooooo."]},
	# 16 ouriço: topete de espinhos azuis para trás
	{"cheio": true, "l": [
		"oo.........",
		"oAoo..o....",
		".oAaooAo...",
		"oAaaaAaaoo.",
		".oaaaaaaado",
		"..ooooooooo"]},
	# 17 armadura de ferro: capacete vermelho com placa dourada na testa
	{"cheio": true, "l": [
		"...ooooo...",
		"..oAAaaao..",
		".oAaaaaaado",
		".oabbbbbado",
		".oaBbbbbado",
		".oaaaaaaddo",
		"..ooooooooo"]},
	# 18 deus do trovão: elmo de prata com asas brancas
	{"cheio": true, "l": [
		"o.........o",
		"wo..ooo..ow",
		"Wwo.oBbo.wW",
		"oWwoBbbbowo",
		".oooBbbbdo.",
		".obbbbbbdo.",
		".oyyyyyyyo.",
		"..ooooooo.."]},
	# 19 princesa do gelo: tiara de cristais
	{"cheio": false, "l": [
		"....o....",
		"...oAo...",
		".o.oAeo.o",
		"oAoaAeoAo",
		"oaeoaeoae",
		"oAAAAAAAo",
		".ooooooo."]},
	# 20 patrulheiro espacial: bolha de vidro (desenhada à parte, ver _bolha) com aro roxo
	{"cheio": true, "l": [
		".ooooooooo.",
		"obbBbbbbbbo",
		".ooooooooo."]},
	# 21 ninja da folha: faixa com placa de metal e pontas atrás
	{"cheio": true, "l": [
		"o..........",
		"ooo........",
		"okoooooooo.",
		"okkoeeeeeko",
		".okoGegegko",
		"..ooooooooo"]},
	# 22 robô azul: capacete azul com gema na testa
	{"cheio": true, "l": [
		"...ooooo...",
		"..oAAaaao..",
		".oAaaaaaado",
		".oaaaaaBodo",
		".oddddddddo",
		"..ooooooooo"]},
	# 23 tubarão: capuz cinza com barbatana
	{"cheio": true, "l": [
		"......o....",
		".....oAo...",
		"....oAado..",
		"...ooaaao..",
		"..oAAaaaao.",
		".oAaaaaaado",
		".obbbbbbbbo",
		"..ooooooooo"]},
	# 24 abelha: antenas com bolinhas
	{"cheio": false, "l": [
		"oo....oo.",
		"oyo..oyo.",
		"ooo..ooo.",
		".ko..ko..",
		"..k..k...",
		".okkkkko.",
		"okkkkkkko",
		".ooooooo."]},
	# 25 super miau: topete preto com o cacho caído na testa
	{"cheio": true, "l": [
		"...ooooo...",
		"..okgkkkoo.",
		".okkgkkkkko",
		"okkkkkkkkko",
		"ookk.ookkko",
		".o...ookko.",
		"......ooko."]},
	# 26 arqueiro miau: capuz verde com pluma vermelha atrás (como o do gato)
	{"cheio": false, "l": [
		"rR...ooo...",
		".rRoobAaoo.",
		"..oobAaaaoo",
		".oobAaaaaao",
		"oaaaaaaaaao",
		"oddddddddo."]},
	# 27 motoqueiro miausma: caveira em chamas (b laranja, B amarelo no miolo, r vermelho nas pontas; o fogo escorre pela nuca)
	{"cheio": true, "l": [
		"..r.........",
		".rbr....r...",
		"rbBr.rbr.rb.",
		"rbBbrbBbrbBr",
		"rbBbooooooBr",
		"rbowwwwwwwo.",
		"rowkkwwwkkwo",
		"rowkbwwwkbwo",
		"..owwwkwwwo.",
		"...owowowo.."]},
	# 28 fênix miaussimo: espetos de cabelo varridos para trás
	{"cheio": false, "l": [
		"ok.........",
		".kko.ok....",
		"..kkokko...",
		".okkkkkkoo.",
		"okkkkkkkkko",
		"okkkkkkkkko",
		".ooooooooo."]},
	# 29 mimiau: cabeça de pano com orelhas caídas e tortas de ponta preta, olhos riscados, bochechas e boca em zigue-zague
	{"cheio": false, "l": [
		"ok.......kk",
		"oao....oaoo",
		"oaaooooooao",
		"oaAaaaaaado",
		"oakkaaaakao",
		"orkkaaaakko",
		"orraakakaro",
		"ooooooooooo"]},
	# 30 jimiau: chapéu de bobo de três pontas
	{"cheio": false, "l": [
		"y....y....y",
		"ao..obo..oa",
		".ao.obo.oa.",
		"..ooaboaoo.",
		"..oAaaaado.",
		".oAaaaaaddo",
		"obBbBbBbBbo",
		".ooooooooo."]},
	# 31 disparamiau: cúpula de ervilha com tufo de folhas atrás e a sobrancelha de determinação
	{"cheio": false, "l": [
		"bB....bB...",
		"bBb..bBb...",
		".obooBbo...",
		"..oAAAaao..",
		".oAAaaaaado",
		".oaaaddddoo",
		".ooooooooo."]},
	# 32 milhau: espiga de grãos com as folhas verdes da palha como cabelo
	{"cheio": false, "l": [
		"b...bB...b.",
		"bb..bB..bb.",
		".bBbbBbbBb.",
		"..oYaYaao..",
		".oAdAdAdAdo",
		".odAdAdAdAo",
		".ooooooooo."]},
	# 33 giramiau: pétalas de girassol em volta do rosto, miolo marrom
	{"cheio": false, "l": [
		"d..a.A.a..d",
		".dAaAaAaAd.",
		"aAabBBBbaAa",
		"aaabebebaaa",
		".aabeeebaa.",
		"..ooooooo.."]},
	# 34 stardew miaulley: chapéu de palha de aba larga com fita verde e um broto
	{"cheio": false, "l": [
		"....ooooo....",
		"...oAAAaao...",
		"...oaaaaao...",
		"...oeeeeeo...",
		".oAAAAaaaaao.",
		"oaaaaaaaaaaao",
		".odddddddddo.",
		"..ooooooooo.."]},
	# 35 miaucraft: cabelo de bloco do Steve, com a franja quadrada
	{"cheio": true, "l": [
		"ooooooooooo",
		"oAAAAAAAAAo",
		"oaaaaaaaaao",
		"oaaaaaaaaao",
		"oaa.....aao"]},
	# 36 miaulax: capuz de Snorlax, de orelhas pontudas e a mancha creme na testa
	{"cheio": false, "l": [
		".oo.....oo.",
		"oaaoooooaao",
		"oAAaaaaaaao",
		"oaaaaaaaaao",
		".obbbbbbbo.",
		"..ooooooo.."]},
	# 37 leonarmiau: bandana azul com as duas pontas ao vento
	{"cheio": false, "l": [
		"..ooooooo..",
		".oAAaaaaao.",
		"oAaaaaaaaao",
		"oaaaaaawwko",
		"...oo...oo.",
		"..oao.oao.."]},
	# 38 donatemiau: bandana roxa com os óculos de soldador na testa
	{"cheio": false, "l": [
		"..ooooooo..",
		".oAAaaaaao.",
		"oaaaaaaaaao",
		"oGgoaaaoGgo",
		"ogBoaaaogBo",
		".oo.....oo."]},
	# 39 rafamiau: bandana vermelha torta, de sobrancelhas franzidas
	{"cheio": false, "l": [
		"..ooooooo..",
		".oAAaaaaaoo",
		"oAaaaaaaaao",
		"oeeoaaaoeeo",
		"oddddwwkddo",
		"..........o"]},
	# 40 rocket miaugue: capacete com a antena de rádio
	{"cheio": true, "l": [
		"..........o",
		"..ooooooo.o",
		".oAAaaaaaoo",
		"oAaaaaaaaao",
		"oaVvvvvvVao",
		"odddddddddo"]},
	# 41 deadmiau: máscara vermelha de olhos brancos
	{"cheio": true, "l": [
		"...ooooo...",
		"..oAaaaao..",
		".oakkaakkao",
		"oakeekkeeko",
		".oddddddo.."]},
	# 42 meon: cabelo repartido, curto atrás e a franja varrida para a frente, caindo na frente
	{"cheio": false, "l": [
		"...oooooo..",
		"..oBBBBBBo.",
		".oBBbBBBBBo",
		"obbbobBBBbo",
		"obo..obBbbo",
		".o....oobo."]},
]
## Quantos pixels a última linha do chapéu fica abaixo do topo do crânio.
const _DESCE := 1
## Quantos pixels o chapéu fica à frente da origem da cabeça (que cai sobre a orelha): a orelha sai por trás do chapéu.
const _FRENTE := 2

## Desenha o chapéu da fantasia `conj` com o topo do crânio do bicho na origem do transform atual. `cranio` = largura do crânio.
static func cabeca(c: CanvasItem, conj: int, cranio: int, f: float, anim: float) -> void:
	var w0: int = 0
	var d: Dictionary = _CHAPEU[conj]
	var linhas: Array = d["l"]
	for l in linhas:
		w0 = maxi(w0, String(l).length())
	var alvo: int = w0
	if d["cheio"]:
		alvo = clampi(cranio + 1, 10, 20)
	elif cranio >= 14:
		alvo = w0 + 2
	var ch: int = hash([conj, alvo])
	var e: Array = _cache_cab.get(ch, [])
	if e.is_empty():
		var esticado: Array = _largura(linhas, w0, alvo)
		var px: Dictionary = {}
		var h: int = esticado.size()
		var x0: int = -alvo / 2 + _FRENTE
		for j in h:
			var s: String = esticado[j]
			for i in s.length():
				if s[i] != ".":
					px[Vector2i(x0 + i, j - h + 1 + _DESCE)] = _cor(conj, s[i])
		e = _runs(px)
		_cache_cab[ch] = e
	if conj == Pecas.Conjunto.PATRULHEIRO:
		_bolha(c, cranio, f)
	_desenhar_runs(c, e, f)
	if conj == Pecas.Conjunto.ABELHA:
		pass

static var _cache_cab: Dictionary = {}

## Linhas `w0` de largura levadas a `alvo` colunas: repete (ou tira) a coluna do meio, a mesma em todas as linhas.
static func _largura(linhas: Array, w0: int, alvo: int) -> Array:
	var r: Array = []
	var m: int = w0 / 2
	for l in linhas:
		var s: String = String(l).rpad(w0, ".")
		if alvo > w0:
			s = s.substr(0, m) + s[m].repeat(alvo - w0) + s.substr(m)
		elif alvo < w0:
			var tira: int = w0 - alvo
			s = s.substr(0, m - tira / 2) + s.substr(m - tira / 2 + tira)
		r.append(s)
	return r

## Bolha de vidro do capacete espacial: aro claro e reflexo, transparente por dentro.
static func _bolha(c: CanvasItem, cranio: int, f: float) -> void:
	var raio: float = cranio * 0.5 + 2.5
	var centro := Vector2(0.0, raio - 3.0)
	c.draw_circle(centro, raio, Desenho.b(Color(0.75, 0.92, 1.0, 0.16), f))
	c.draw_arc(centro, raio, 0.0, TAU, 28, Desenho.b(Color(0.85, 0.96, 1.0, 0.75), f), 1.0)
	c.draw_rect(Rect2(centro.x - raio * 0.55, centro.y - raio * 0.7, 2.0, 1.0), Desenho.b(Color(1, 1, 1, 0.9), f))
	c.draw_rect(Rect2(centro.x - raio * 0.7, centro.y - raio * 0.45, 1.0, 2.0), Desenho.b(Color(1, 1, 1, 0.8), f))

# ------------------------------------------------------------------ roupas de corpo
## Desenha a roupa de corpo da fantasia `conj` no tronco do quadro `q` do bicho (coordenadas do bicho, origem no transform atual).
static func corpo(c: CanvasItem, conj: int, q: Dictionary, f: float, anim: float) -> void:
	var m: Dictionary = q.get("t", {})
	if m.is_empty():
		return
	var ch: int = hash([conj, q.get("id", 0), int(anim * 4.0) % 4 if _anima(conj) else 0])
	var e: Array = _cache_corpo.get(ch, [])
	if e.is_empty():
		if _cache_corpo.size() > 2000:
			_cache_corpo.clear()
		corpo_vez = true
		e = _runs(_vestir(conj, q, anim))
		corpo_vez = false
		_cache_corpo[ch] = e
	_desenhar_runs(c, e, f)

static var _cache_corpo: Dictionary = {}
static var forma_vez: String = ""

## Fantasias cuja roupa mexe com o passo (capas que ondulam).
static func _anima(conj: int) -> bool:
	return _FORMA[conj] == "capa"

## Forma de cada roupa de corpo: colete (frente do tronco), capa (do pescoço para trás, por cima do dorso), casco, manta (curta, nos
## ombros). [forma, começo, fim, altura]: começo e fim em fração do tronco de trás (0) para a frente (1); altura em fração da coluna.
const _FORMA: Array[String] = [
	"colete", "colete", "capa", "colete", "manta", "colete", "manta", "colete", "capa", "colete", "capa", "colete", "colete",
	"colete", "colete", "casco", "colete", "colete", "capa", "capa", "colete", "colete", "colete", "colete", "colete",
	"colete", "colete", "colete", "colete", "colete", "colete",
	"colete", "colete", "colete", "colete", "colete", "colete",
	"casco", "casco", "casco", "colete", "colete", "colete",
]
const _MEDIDA: Array = [
	[0.06, 1.0, 0.80], [0.06, 1.0, 0.78], [0.0, 0.92, 0.85], [0.06, 1.0, 0.80], [0.10, 1.0, 0.58], [0.06, 1.0, 0.80],
	[0.10, 1.0, 0.70], [0.04, 1.0, 0.82], [0.0, 0.92, 0.85], [0.06, 1.0, 0.86], [0.0, 0.92, 0.80], [0.06, 1.0, 0.84],
	[0.06, 1.0, 0.82], [0.06, 1.0, 0.80], [0.06, 1.0, 0.84], [0.05, 0.95, 0.62], [0.06, 1.0, 0.62], [0.06, 1.0, 0.80],
	[0.0, 0.92, 0.82], [0.0, 0.94, 0.85], [0.06, 1.0, 0.84], [0.06, 1.0, 0.84], [0.06, 1.0, 0.80], [0.04, 1.0, 0.80],
	[0.04, 1.0, 0.84],
	[0.06, 1.0, 0.82], [0.06, 1.0, 0.80], [0.06, 1.0, 0.82], [0.06, 1.0, 0.82], [0.04, 1.0, 0.84], [0.06, 1.0, 0.80],
	[0.06, 1.0, 0.82], [0.06, 1.0, 0.84], [0.06, 1.0, 0.84], [0.06, 1.0, 0.82], [0.06, 1.0, 0.84], [0.04, 1.0, 0.92],
	[0.05, 0.95, 0.62], [0.05, 0.95, 0.62], [0.05, 0.95, 0.62], [0.06, 1.0, 0.84], [0.06, 1.0, 0.82], [0.06, 1.0, 0.84],
]

## Pixels pintados da roupa: {Vector2i: Color}.
static func _vestir(conj: int, q: Dictionary, anim: float) -> Dictionary:
	var g: Dictionary = _geometria(q)
	var forma: String = _FORMA[conj]
	var med: Array = _MEDIDA[conj]
	var area: Dictionary = {}
	match forma:
		"capa":
			area = _capa(g, med, anim)
		"casco":
			area = _casco(g, med)
		_:
			area = _colete(g, med)
	area = _arrumar(area)
	forma_vez = forma
	var px: Dictionary = _sombrear(conj, area, g)
	_enfeitar(conj, px, area, g)
	return px

## Área sem furinhos (até 6 pixels, onde o molde do chefe tem pintas) e sem pedaços soltos (menos de 10 pixels): a roupa não sai
## em retalhos nos troncos recortados dos chefes.
static func _arrumar(area: Dictionary) -> Dictionary:
	if area.is_empty():
		return area
	var cx: Rect2i = _caixa(area).grow(1)
	var visto: Dictionary = {}
	var r: Dictionary = area.duplicate()
	for y in range(cx.position.y, cx.end.y):
		for x in range(cx.position.x, cx.end.x):
			var v := Vector2i(x, y)
			if area.has(v) or visto.has(v):
				continue
			var comp: Array = _mancha(v, func(w: Vector2i) -> bool: return not area.has(w) and cx.has_point(w), visto)
			var borda: bool = false
			for w2 in comp:
				var u: Vector2i = w2
				if u.x == cx.position.x or u.y == cx.position.y or u.x == cx.end.x - 1 or u.y == cx.end.y - 1:
					borda = true
					break
			if not borda and comp.size() <= 6:
				for w3 in comp:
					r[w3] = true
	var visto2: Dictionary = {}
	for p in r.keys():
		if visto2.has(p):
			continue
		var comp2: Array = _mancha(p, func(w: Vector2i) -> bool: return r.has(w), visto2)
		if comp2.size() < 10:
			for w4 in comp2:
				r.erase(w4)
	return r

## Mancha de 4 vizinhos a partir de `v` em que `dentro` vale; marca em `visto`.
static func _mancha(v: Vector2i, dentro: Callable, visto: Dictionary) -> Array:
	var comp: Array = []
	var pilha: Array = [v]
	visto[v] = true
	while not pilha.is_empty():
		var p: Vector2i = pilha.pop_back()
		comp.append(p)
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = p + d
			if not visto.has(n) and dentro.call(n):
				visto[n] = true
				pilha.append(n)
	return comp

## Leitura do tronco: colunas (topo e base de cada x), extremos e o desenho inteiro do bicho (para saber o que é vazio).
static func _geometria(q: Dictionary) -> Dictionary:
	var m: Dictionary = q["t"]
	var topo: Dictionary = {}
	var base: Dictionary = {}
	var xa: int = 99999
	var xb: int = -99999
	for p in m.keys():
		var v: Vector2i = p
		topo[v.x] = mini(int(topo.get(v.x, 99999)), v.y)
		base[v.x] = maxi(int(base.get(v.x, -99999)), v.y)
		xa = mini(xa, v.x)
		xb = maxi(xb, v.x)
	var cheio: Dictionary = {}
	var linhas: Array = q.get("l", [])
	var x0: int = int(q.get("x", 0))
	var y0: int = int(q.get("y", 0))
	for j in linhas.size():
		var s: String = linhas[j]
		for i in s.length():
			if s[i] != ".":
				cheio[Vector2i(x0 + i, y0 + j)] = true
	return {"m": m, "topo": topo, "base": base, "xa": xa, "xb": xb, "cheio": cheio}

## Colete, avental, barril, manta e afins: a faixa [começo, fim] do tronco, do dorso até `altura` da coluna.
static func _colete(g: Dictionary, med: Array) -> Dictionary:
	var area: Dictionary = {}
	var xa: int = g["xa"]
	var w: int = int(g["xb"]) - xa + 1
	var de: int = xa + roundi(w * float(med[0]))
	var ate: int = xa + roundi(w * float(med[1])) - 1
	for p in g["m"].keys():
		var v: Vector2i = p
		if v.x > ate:
			continue
		var t: int = g["topo"][v.x]
		var b: int = g["base"][v.x]
		var alt: int = maxi(3, roundi((b - t + 1) * float(med[2])))
		# canto de baixo atrás arredondado
		if v.x < de:
			continue
		if v.x - de < 2:
			alt -= 2 - (v.x - de)
		if v.y < t + alt:
			area[v] = true
	return area

## Capa: nasce no pescoço, cobre o dorso e cai para trás além da anca, com a ponta balançando no passo.
static func _capa(g: Dictionary, med: Array, anim: float) -> Dictionary:
	var area: Dictionary = {}
	var xa: int = g["xa"]
	var xb: int = g["xb"]
	var w: int = xb - xa + 1
	var frente: int = xa + roundi(w * float(med[1])) - 1
	var onda: int = 1 if int(anim * 4.0) % 2 == 1 else 0
	for x in range(xa, frente + 1):
		if not g["topo"].has(x):
			continue
		var t: int = g["topo"][x]
		var b: int = g["base"][x]
		var k: float = float(frente - x) / maxf(1.0, float(frente - xa))   # 0 no pescoço, 1 na anca
		var alt: int = maxi(3, roundi((b - t + 1) * float(med[2]) * (0.45 + 0.55 * k)) + 1)
		for y in range(t - 1, t + alt):
			area[Vector2i(x, y)] = true
	# ponta caída para trás da anca
	if g["topo"].has(xa):
		var t2: int = g["topo"][xa]
		var b2: int = g["base"][xa]
		var alt2: int = maxi(3, roundi((b2 - t2 + 1) * float(med[2])))
		for i in 3:
			var x2: int = xa - 1 - i
			for y in range(t2 + i + onda, t2 + alt2 + 1 - (i / 2) + onda):
				area[Vector2i(x2, y)] = true
	return area

## Casco: domo sobre o dorso, um pixel acima da linha das costas.
static func _casco(g: Dictionary, med: Array) -> Dictionary:
	var area: Dictionary = {}
	var xa: int = g["xa"]
	var w: int = int(g["xb"]) - xa + 1
	var de: int = xa + roundi(w * float(med[0]))
	var ate: int = xa + roundi(w * float(med[1])) - 1
	for x in range(de, ate + 1):
		if not g["topo"].has(x):
			continue
		var t: int = g["topo"][x]
		var b: int = g["base"][x]
		var borda: int = mini(x - de, ate - x)
		var sobe: int = 1 if borda >= 2 else 0
		var alt: int = maxi(3, roundi((b - t + 1) * float(med[2])))
		for y in range(t - sobe, t + alt):
			area[Vector2i(x, y)] = true
	return area

## Cor de cada pixel da roupa: contorno escuro onde a roupa encosta no vazio, sombra onde encosta no corpo, luz na linha de cima
## e uma faixa de sombra logo acima da bainha.
static func _sombrear(conj: int, area: Dictionary, g: Dictionary) -> Dictionary:
	var px: Dictionary = {}
	var cheio: Dictionary = g["cheio"]
	for p in area.keys():
		var v: Vector2i = p
		var cor: String = "a"
		var fora: bool = false
		var borda: bool = false
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = v + d
			if not area.has(n):
				if cheio.has(n):
					borda = true
				else:
					fora = true
		if fora or (borda and area.has(v + Vector2i(0, -1))):
			cor = "o"
		elif borda:
			cor = "A"
		elif not area.has(v + Vector2i(0, -2)):
			cor = "A"
		elif not area.has(v + Vector2i(0, 2)):
			cor = "d"
		elif forma_vez == "capa" and posmod(v.x, 4) == 0 and area.has(v + Vector2i(0, -3)):
			cor = "d"
		px[v] = _cor(conj, cor)
	return px

## Pixel da roupa (só onde há roupa).
static func _p(px: Dictionary, area: Dictionary, v: Vector2i, cor: Color) -> void:
	if area.has(v):
		px[v] = cor

## Meio da área: x e y médios, e a caixa.
static func _caixa(area: Dictionary) -> Rect2i:
	var r := Rect2i()
	var primeiro: bool = true
	for p in area.keys():
		var v: Vector2i = p
		if primeiro:
			r = Rect2i(v, Vector2i.ONE)
			primeiro = false
		else:
			r = r.expand(v).expand(v + Vector2i.ONE)
	return r

## Topo da área em cada coluna.
static func _topos(area: Dictionary) -> Dictionary:
	var t: Dictionary = {}
	for p in area.keys():
		var v: Vector2i = p
		t[v.x] = mini(int(t.get(v.x, 99999)), v.y)
	return t

## Base da área em cada coluna.
static func _bases(area: Dictionary) -> Dictionary:
	var t: Dictionary = {}
	for p in area.keys():
		var v: Vector2i = p
		t[v.x] = maxi(int(t.get(v.x, -99999)), v.y)
	return t

## Emblema de cada fantasia no meio da manta (letras como nos chapéus; "" = sem emblema).
const _EMBLEMA: Array = [
	[".r.", "rRr", ".r."],                       # cavaleiro: cruz
	[".B.", "BbB", "BbB", ".B."],                # guardião: escudo
	[],                                          # rei (capa)
	[".y.", "yYy", ".y."],                       # circo: estrela
	[],                                          # viking
	[".r.", "ryr", ".r."],                       # jardineiro: flor
	[],                                          # caubói
	["www", "wkw", ".w."],                       # pirata: caveira
	[],                                          # mago
	[],                                          # encanador
	["k.k", ".k.", "kkk", ".k.", "k.k"],         # homem-morcego (não usa: capa)
	["o.o", ".o.", "ooo", ".o.", "o.o"],         # garoto-aranha: aranha
	[],                                          # cavaleiro estelar
	["rGe", "GGG"],                              # lorde sombrio: painel
	[".y.", "y.y"],                              # herói do bosque: três triângulos
	[],                                          # tartaruga
	[],                                          # ouriço
	[".e.", "eWe", ".e."],                       # armadura de ferro: reator
	[],                                          # deus do trovão
	[],                                          # princesa do gelo
	["eee", "ggg"],                              # patrulheiro: painel
	[".r.", "r.r", ".r."],                       # ninja da folha: espiral
	[".B.", "BeB", ".B."],                       # robô azul: luz
	[],                                          # tubarão
	[],                                          # abelha
	["yrr", "ryy", "yry", "yyr", "rry"],            # super miau: o S do peito
	[],                                          # arqueiro miau
	[],                                          # motoqueiro miausma
	[],                                          # fênix miaussimo
	[],                                          # mimiau
	["r.r", "rrr", ".r."],                       # jimiau: copas
	[],                                          # disparamiau: folhas no enfeite
	[],                                          # milhau
	[".y.", "yey", ".y."],                       # giramiau: sol
	[],                                          # stardew miaulley: bolso no enfeite
	[],                                          # miaucraft
	[],                                          # miaulax: barriga no enfeite
	[],                                          # leonarmiau: o cinto fino vem no enfeite do casco
	[],                                          # donatemiau: o cinto fino vem no enfeite do casco
	[],                                          # rafamiau: o cinto fino vem no enfeite do casco
	["bB", "Bb"],                                # rocket miaugue: chama pintada
	["bB", "Bb"],                                # deadmiau: remendo
	[],                                          # meon
]
## Fantasias com barra de outra cor na bainha (a letra da barra).
const _BARRA: Dictionary = {0: "b", 1: "b", 3: "y", 4: "", 6: "b", 7: "B", 11: "b", 13: "b", 16: "", 17: "b", 20: "b", 21: "b", 22: "b", 25: "b", 27: "b", 30: "b"}

## Enfeites de cada fantasia sobre a roupa já sombreada (barra, emblema, listras, golas).
static func _enfeitar(conj: int, px: Dictionary, area: Dictionary, g: Dictionary) -> void:
	var cx: Rect2i = _caixa(area)
	var tp: Dictionary = _topos(area)
	var bs: Dictionary = _bases(area)
	var x0: int = cx.position.x
	var x1: int = cx.end.x - 1
	var xm: int = x0 + cx.size.x / 2
	var C := func(ch: String) -> Color: return _cor(conj, ch)
	var dentro := func(v: Vector2i) -> bool: return area.has(v) and px.get(v) != _COMUM["o"]
	# barra da bainha: a linha logo acima do contorno de baixo
	var barra: String = _BARRA.get(conj, "")
	if barra != "":
		for x in range(x0, x1 + 1):
			if bs.has(x) and dentro.call(Vector2i(x, bs[x] - 1)) and bs[x] - 1 > tp[x] + 1:
				px[Vector2i(x, bs[x] - 1)] = C.call(barra)
	match conj:
		Pecas.Conjunto.CAVALEIRO:
			# placas: rebites na linha do ombro
			for x in range(x0 + 2, x1 - 1, 3):
				if tp.has(x) and dentro.call(Vector2i(x, tp[x] + 2)):
					px[Vector2i(x, tp[x] + 2)] = C.call("A")
		Pecas.Conjunto.GUARDIAO:
			# espinhos no dorso
			for x in range(x0 + 2, x1, 3):
				if tp.has(x):
					px[Vector2i(x, tp[x] - 1)] = C.call("b")
					px[Vector2i(x, tp[x] - 2)] = C.call("o")
					px[Vector2i(x - 1, tp[x] - 1)] = C.call("o")
					px[Vector2i(x + 1, tp[x] - 1)] = C.call("o")
		Pecas.Conjunto.REI:
			_gola_arminho(px, tp, x1, C)
		Pecas.Conjunto.CIRCO:
			# listras de lona de circo, vermelho e branco
			for p in area.keys():
				var v: Vector2i = p
				if dentro.call(v) and posmod(v.x, 4) < 2 and px[v] != C.call("y"):
					px[v] = _COMUM["w"] if px[v] != C.call("d") else _COMUM["W"]
		Pecas.Conjunto.VIKING:
			# pelo desgrenhado: bainha em dentes e tufos claros
			for x in range(x0, x1 + 1):
				if bs.has(x) and posmod(x, 2) == 0:
					px[Vector2i(x, bs[x] + 1)] = C.call("o")
					px[Vector2i(x, bs[x])] = C.call("d")
			for x in range(x0 + 1, x1, 3):
				if tp.has(x) and dentro.call(Vector2i(x, tp[x] + 2)):
					px[Vector2i(x, tp[x] + 2)] = C.call("A")
		Pecas.Conjunto.JARDINEIRO:
			# bolso claro
			var by: int = cx.position.y + cx.size.y / 2
			for y in range(by, by + 2):
				for x in range(x1 - 4, x1 - 1):
					if dentro.call(Vector2i(x, y)):
						px[Vector2i(x, y)] = C.call("b")
		Pecas.Conjunto.CAUBOI:
			# listras do poncho e franja
			for x in range(x0, x1 + 1):
				if not tp.has(x):
					continue
				for k in [2, 3]:
					if dentro.call(Vector2i(x, tp[x] + k)):
						px[Vector2i(x, tp[x] + k)] = C.call("b") if k == 2 else C.call("B")
				if posmod(x, 2) == 0:
					px[Vector2i(x, bs[x] + 1)] = C.call("d")
		Pecas.Conjunto.PIRATA:
			# botões dourados na frente
			for y in range(tp.get(x1 - 1, 0) + 2, bs.get(x1 - 1, 0) - 1, 2):
				if dentro.call(Vector2i(x1 - 1, y)):
					px[Vector2i(x1 - 1, y)] = C.call("B")
		Pecas.Conjunto.MAGO:
			var k: int = 0
			for p in area.keys():
				var v: Vector2i = p
				if px[v] == C.call("a") and posmod(v.x * 7 + v.y * 13, 11) == 0:
					px[v] = C.call("b") if k % 2 == 0 else C.call("B")
					k += 1
			_gola(px, tp, x1, C.call("b"), C.call("o"))
		Pecas.Conjunto.ENCANADOR:
			# camisa vermelha em cima, macacão azul, alças e botões
			for x in range(x0, x1 + 1):
				if not tp.has(x):
					continue
				for y in range(tp[x] + 1, tp[x] + 3):
					if dentro.call(Vector2i(x, y)):
						px[Vector2i(x, y)] = C.call("B") if y == tp[x] + 1 else C.call("b")
			for x in [x1 - 2, x0 + 3]:
				if not tp.has(x):
					continue
				for y in range(tp[x] + 1, tp[x] + 3):
					if dentro.call(Vector2i(x, y)):
						px[Vector2i(x, y)] = C.call("a")
				if dentro.call(Vector2i(x, tp[x] + 3)):
					px[Vector2i(x, tp[x] + 3)] = C.call("e")
		Pecas.Conjunto.MORCEGO:
			# bainha recortada em asa de morcego
			for x in range(x0, x1 + 1):
				if bs.has(x) and posmod(x, 3) == 0:
					px.erase(Vector2i(x, bs[x]))
					if area.has(Vector2i(x, bs[x] - 1)):
						px[Vector2i(x, bs[x] - 1)] = C.call("o")
			_gola(px, tp, x1, C.call("a"), C.call("o"))
			# cinto amarelo à mostra na frente
		Pecas.Conjunto.ARANHA:
			# vermelho em cima, azul embaixo, teia
			for p in area.keys():
				var v: Vector2i = p
				if not dentro.call(v):
					continue
				var t: int = tp[v.x]
				if v.y >= t + 5:
					px[v] = C.call("b") if px[v] != C.call("d") else C.call("o")
				elif px[v] == C.call("a") and (posmod(v.x, 3) == 0 or (v.y - t) == 3):
					px[v] = C.call("d")
		Pecas.Conjunto.ESTELAR:
			# túnica cruzada e cinto marrom
			for i in 4:
				if dentro.call(Vector2i(x1 - 1 - i, tp.get(x1 - 1 - i, 0) + 1 + i)):
					px[Vector2i(x1 - 1 - i, tp.get(x1 - 1 - i, 0) + 1 + i)] = C.call("d")
			for x in [xm - 1, xm]:
				for y in range(tp.get(x, 0) + 1, bs.get(x, 0)):
					if dentro.call(Vector2i(x, y)):
						px[Vector2i(x, y)] = C.call("b")
		Pecas.Conjunto.BOSQUE:
			# cinto marrom com fivela e gola branca
			for x in [xm + 2, xm + 3]:
				for y in range(tp.get(x, 0) + 1, bs.get(x, 0)):
					if dentro.call(Vector2i(x, y)):
						px[Vector2i(x, y)] = C.call("b")
			for y in range(tp.get(x1, 0), bs.get(x1, 0)):
				if dentro.call(Vector2i(x1, y)):
					px[Vector2i(x1, y)] = _COMUM["w"]
		Pecas.Conjunto.TARTARUGA, Pecas.Conjunto.LEONARMIAU, Pecas.Conjunto.DONATEMIAU, Pecas.Conjunto.RAFAMIAU:
			# placas do casco e borda amarela
			for p in area.keys():
				var v: Vector2i = p
				if not dentro.call(v):
					continue
				var lx: int = v.x - x0
				var ly: int = v.y - tp[v.x]
				if ly >= 1 and (posmod(lx + (ly / 3) * 2, 4) == 0 or ly % 3 == 0):
					px[v] = C.call("d")
			for x in range(x0, x1 + 1):
				if not bs.has(x):
					continue
				# plastrão bege embaixo
				if area.has(Vector2i(x, bs[x])):
					px[Vector2i(x, bs[x])] = C.call("b")
		Pecas.Conjunto.OURICO:
			# espinhos para trás no dorso
			for x in range(x0 + 2, x1 - 1, 3):
				if not tp.has(x):
					continue
				var t: int = tp[x]
				px[Vector2i(x, t - 1)] = C.call("a")
				px[Vector2i(x - 1, t - 1)] = C.call("A")
				px[Vector2i(x - 1, t - 2)] = C.call("o")
				px[Vector2i(x - 2, t - 1)] = C.call("o")
				px[Vector2i(x, t - 2)] = C.call("o")
		Pecas.Conjunto.FERRO:
			# placa dourada no peito
			for y in range(tp.get(x1 - 1, 0) + 1, bs.get(x1 - 1, 0)):
				if dentro.call(Vector2i(x1 - 1, y)):
					px[Vector2i(x1 - 1, y)] = C.call("b")
		Pecas.Conjunto.TROVAO:
			_gola(px, tp, x1, _COMUM["G"], C.call("o"))
		Pecas.Conjunto.GELO:
			for p in area.keys():
				var v: Vector2i = p
				if px[v] == C.call("a") and posmod(v.x * 5 + v.y * 11, 13) == 0:
					px[v] = Color.WHITE
			for x in range(x0, x1 + 1):
				if bs.has(x) and area.has(Vector2i(x, bs[x])):
					px[Vector2i(x, bs[x])] = C.call("b")
		Pecas.Conjunto.NINJA_FOLHA:
			# ombros pretos
			for x in range(x0, x1 + 1):
				if not tp.has(x):
					continue
				for y in range(tp[x] + 1, tp[x] + 3):
					if dentro.call(Vector2i(x, y)):
						px[Vector2i(x, y)] = C.call("B") if y == tp[x] + 1 else C.call("b")
		Pecas.Conjunto.TUBARAO:
			# barbatana no dorso e barriga branca
			var fx: int = xm
			if tp.has(fx):
				var t3: int = tp[fx]
				var fin: Array = ["...o.", "..oAo", ".oAao", "oAaao", "oaaao"]
				for j in fin.size():
					var s: String = fin[j]
					for i in s.length():
						if s[i] != ".":
							px[Vector2i(fx - 2 + i, t3 - fin.size() + j)] = C.call(s[i])
			for x in range(x0, x1 + 1):
				if not bs.has(x):
					continue
				for y in [bs[x] - 1, bs[x] - 2]:
					if dentro.call(Vector2i(x, y)) and y > tp[x] + 2:
						px[Vector2i(x, y)] = C.call("b") if y == bs[x] - 1 else C.call("B")
		Pecas.Conjunto.ARQUEIRO_MIAU:
			# cinto marrom na cintura do colete, com fivela dourada
			for x in range(x0, x1 + 1):
				if tp.has(x) and bs.has(x):
					var yc: int = (tp[x] + bs[x]) / 2 + 1
					if dentro.call(Vector2i(x, yc)) and yc < bs[x] - 1:
						px[Vector2i(x, yc)] = C.call("b")
			if tp.has(x1 - 2) and bs.has(x1 - 2):
				var yf: int = (tp[x1 - 2] + bs[x1 - 2]) / 2 + 1
				if dentro.call(Vector2i(x1 - 2, yf)):
					px[Vector2i(x1 - 2, yf)] = C.call("e") if false else _COMUM["y"]
		Pecas.Conjunto.MOTOQUEIRO_MIAUSMA:
			# jaqueta preta com tachas de prata nos ombros e na barra
			for x in range(x0 + 1, x1, 3):
				if tp.has(x) and dentro.call(Vector2i(x, tp[x] + 1)):
					px[Vector2i(x, tp[x] + 1)] = C.call("e")
				if bs.has(x) and dentro.call(Vector2i(x, bs[x] - 1)) and bs[x] - 1 > tp[x] + 2:
					px[Vector2i(x, bs[x] - 1)] = C.call("e")
		Pecas.Conjunto.FENIX_MIAUSSIMO:
			# camisa branca em V na frente e a gravata vermelha
			for k in 2:
				var xc: int = x1 - 3 + k
				if not tp.has(xc):
					continue
				for y in range(tp[xc] + 1, tp[xc] + 4 - k):
					if dentro.call(Vector2i(xc, y)):
						px[Vector2i(xc, y)] = C.call("B")
			if tp.has(x1 - 3):
				for y in range(tp[x1 - 3] + 1, bs[x1 - 3] - 1):
					if dentro.call(Vector2i(x1 - 3, y)):
						px[Vector2i(x1 - 3, y)] = C.call("b")
		Pecas.Conjunto.MIMIAU:
			# costura torta e a barra irregular escura embaixo (a sombra do pano)
			for x in range(x0 + 2, x1 - 5, 2):
				if tp.has(x) and dentro.call(Vector2i(x, tp[x] + 2)):
					px[Vector2i(x, tp[x] + 2)] = C.call("e")
			for x in range(x0, x1 + 1):
				if not bs.has(x):
					continue
				if posmod(x * 5, 3) != 1 and area.has(Vector2i(x, bs[x])):
					px[Vector2i(x, bs[x])] = _COMUM["k"]
				if posmod(x, 3) == 0:
					px[Vector2i(x, bs[x] + 1)] = _COMUM["k"]
				if posmod(x, 2) == 0 and dentro.call(Vector2i(x, bs[x] - 1)):
					px[Vector2i(x, bs[x] - 1)] = C.call("d")
		Pecas.Conjunto.JIMIAU:
			# colete de arlequim em losangos roxo e verde
			for p in area.keys():
				var v: Vector2i = p
				if dentro.call(v) and (floori((v.x + v.y + 100) / 3.0) + floori((v.x - v.y + 100) / 3.0)) % 2 == 0:
					px[v] = C.call("b") if px[v] != C.call("d") else C.call("B")
		Pecas.Conjunto.ABELHA:
			for p in area.keys():
				var v: Vector2i = p
				if dentro.call(v) and posmod(v.x - x1, 4) >= 2:
					px[v] = C.call("b") if px[v] != C.call("A") else C.call("B")
			_asas(px, tp, xm)
	_enfeitar_lote2(conj, px, area, cx, tp, bs, dentro, C)
	# emblema no meio da manta
	var em: Array = _EMBLEMA[conj]
	if not em.is_empty() and _FORMA[conj] != "capa":
		var h: int = em.size()
		var w: int = String(em[0]).length()
		var ex: int = xm - w / 2 + 1
		var ey: int = cx.position.y + (cx.size.y - h) / 2
		for j in h:
			var s2: String = em[j]
			for i in s2.length():
				var v2 := Vector2i(ex + i, ey + j)
				if s2[i] != "." and dentro.call(v2):
					px[v2] = C.call(s2[i])

## Enfeites das fantasias do lote 2 (Quintal e Toca): nervuras de folha, palha de milho, sóis, macacão, blocos e barriga de Snorlax.
static func _enfeitar_lote2(conj: int, px: Dictionary, area: Dictionary, cx: Rect2i, tp: Dictionary, bs: Dictionary, dentro: Callable, C: Callable) -> void:
	var x0: int = cx.position.x
	var x1: int = cx.end.x - 1
	var xm: int = x0 + cx.size.x / 2
	match conj:
		Pecas.Conjunto.ROCKET_MIAUGUE:
			# carro: janela escura no alto de trás, rodas de aro claro nos pés da carroceria
			for x in range(xm - 3, xm + 1):
				if tp.has(x):
					for y in range(tp[x] + 1, tp[x] + 3):
						if dentro.call(Vector2i(x, y)):
							px[Vector2i(x, y)] = C.call("v") if (x + y) % 5 != 0 else C.call("V")
			for rx in [x0 + 2, x1 - 3]:
				if not bs.has(rx):
					continue
				var ry: int = bs[rx] - 1
				for dy in 4:
					for dx in 4:
						if (dx == 0 or dx == 3) and (dy == 0 or dy == 3):
							continue
						var vr := Vector2i(rx - 1 + dx, ry + dy)
						px[vr] = _COMUM["W"] if (dx in [1, 2] and dy in [1, 2]) else _COMUM["k"]
		Pecas.Conjunto.DEADMIAU:
			# traje bicolor: costas e barriga pretas
			for p in area.keys():
				var v: Vector2i = p
				if not dentro.call(v):
					continue
				if v.x < x0 + cx.size.x / 3 or (bs.has(v.x) and v.y >= bs[v.x] - 1):
					px[v] = C.call("b") if px[v] != C.call("A") else C.call("B")
		Pecas.Conjunto.MEON:
			# jaqueta de couro: gola de pelo creme no pescoço, costura escura descendo na frente e a tira do coldre no peito
			for x in range(x1 - 3, x1 + 1):
				if not tp.has(x):
					continue
				px[Vector2i(x, tp[x] - 1)] = C.call("e")
				px[Vector2i(x, tp[x])] = C.call("e") if x % 2 == 0 else C.call("b")
				px[Vector2i(x, tp[x] - 2)] = _COMUM["o"]
			for p in area.keys():
				var v: Vector2i = p
				if dentro.call(v) and v.x == x1 - 5 and tp.has(v.x) and v.y > tp[v.x] + 1:
					px[v] = C.call("d")
			for x in range(x0 + cx.size.x / 3, x0 + cx.size.x / 3 + 2):
				if tp.has(x) and bs.has(x):
					for y in range(tp[x] + 1, bs[x]):
						if dentro.call(Vector2i(x, y)):
							px[Vector2i(x, y)] = _COMUM["k"]
		Pecas.Conjunto.DISPARAMIAU:
			# três ervilhas no flanco
			var ym: int = cx.position.y + cx.size.y / 2
			for ex in [x0 + 2, x0 + 6, x0 + 10]:
				for dy in 2:
					for dx in 2:
						var ve := Vector2i(ex + dx, ym + dy)
						if dentro.call(ve):
							px[ve] = C.call("B") if (dx == 0 and dy == 0) else C.call("b")
			_gola(px, tp, x1, C.call("B"), C.call("o"))
		Pecas.Conjunto.MILHAU:
			for p in area.keys():
				var v: Vector2i = p
				if dentro.call(v) and px[v] == C.call("a") and posmod(v.x + v.y * 2, 4) == 0:
					px[v] = C.call("d")
			for x in range(xm, xm + 3):
				if tp.has(x):
					for y in range(tp[x] + 2, tp[x] + 5):
						if dentro.call(Vector2i(x, y)):
							px[Vector2i(x, y)] = C.call("b") if (x + y) % 2 == 0 else C.call("e")
			_gola(px, tp, x1, C.call("e"), _COMUM["Y"])
		Pecas.Conjunto.GIRAMIAU:
			for x in range(x0 + 1, x1, 2):
				if bs.has(x) and dentro.call(Vector2i(x, bs[x] - 1)):
					px[Vector2i(x, bs[x] - 1)] = C.call("A")
		Pecas.Conjunto.STARDEW_MIAULLEY:
			for x in range(x0, x1 + 1):
				if not tp.has(x):
					continue
				for y in range(tp[x] + 1, tp[x] + 3):
					if dentro.call(Vector2i(x, y)):
						px[Vector2i(x, y)] = C.call("B") if y == tp[x] + 1 else C.call("b")
			for x in [x1 - 3, x0 + 3]:
				if not tp.has(x):
					continue
				for y in range(tp[x] + 1, tp[x] + 4):
					if dentro.call(Vector2i(x, y)):
						px[Vector2i(x, y)] = C.call("A")
				if dentro.call(Vector2i(x, tp[x] + 3)):
					px[Vector2i(x, tp[x] + 3)] = _COMUM["y"]
			var by: int = cx.position.y + cx.size.y * 2 / 3
			for y in range(by, by + 2):
				for x in range(xm - 1, xm + 2):
					if dentro.call(Vector2i(x, y)):
						px[Vector2i(x, y)] = C.call("d")
		Pecas.Conjunto.MIAUCRAFT:
			for p in area.keys():
				var v: Vector2i = p
				if not dentro.call(v) or not tp.has(v.x):
					continue
				if v.x < xm and px[v] != C.call("d"):
					px[v] = C.call("B") if px[v] == C.call("A") else C.call("b")
		Pecas.Conjunto.MIAULAX:
			var cyy: float = cx.position.y + cx.size.y * 0.55
			for p in area.keys():
				var v: Vector2i = p
				if not dentro.call(v):
					continue
				var dx: float = (v.x - xm) / maxf(1.0, cx.size.x * 0.34)
				var dy: float = (v.y - cyy) / maxf(1.0, cx.size.y * 0.36)
				if dx * dx + dy * dy <= 1.0:
					px[v] = C.call("B") if dy < -0.55 else C.call("b")

## Gola alta na frente (pescoço): duas colunas um pixel acima do dorso.
static func _gola(px: Dictionary, tp: Dictionary, x1: int, cor: Color, borda: Color) -> void:
	for x in [x1 - 1, x1]:
		if tp.has(x):
			px[Vector2i(x, tp[x] - 1)] = cor
			px[Vector2i(x, tp[x] - 2)] = borda

## Gola de arminho (branca com pintas) da capa do rei.
static func _gola_arminho(px: Dictionary, tp: Dictionary, x1: int, C: Callable) -> void:
	for x in range(x1 - 3, x1 + 1):
		if not tp.has(x):
			continue
		for y in range(tp[x] - 1, tp[x] + 2):
			px[Vector2i(x, y)] = _COMUM["k"] if (x + y) % 3 == 0 else C.call("b")
		px[Vector2i(x, tp[x] - 2)] = _COMUM["o"]

## Ombreira arredondada clara perto da frente.
static func _ombreira(px: Dictionary, area: Dictionary, tp: Dictionary, x: int, luz: Color, meio: Color) -> void:
	if not tp.has(x):
		return
	var t: int = tp[x]
	for i in range(-1, 3):
		_p(px, area, Vector2i(x + i, t + 1), meio)
	_p(px, area, Vector2i(x, t + 1), luz)
	_p(px, area, Vector2i(x + 1, t + 1), luz)
	for i in range(-1, 3):
		_p(px, area, Vector2i(x + i, t + 2), _COMUM["o"])

## Aranha preta de cinco pixels.
static func _aranha(px: Dictionary, area: Dictionary, v: Vector2i) -> void:
	for d in [Vector2i(0, 0), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(0, 1)]:
		_p(px, area, v + d, _COMUM["o"])

## Asinhas translúcidas da abelha, acima do dorso.
static func _asas(px: Dictionary, tp: Dictionary, xm: int) -> void:
	if not tp.has(xm):
		return
	var t: int = tp[xm]
	var asa := Color(0.85, 0.95, 1.0, 0.85)
	var borda := Color(0.45, 0.6, 0.75)
	for d in [Vector2i(-1, -2), Vector2i(0, -2), Vector2i(-2, -3), Vector2i(-1, -3), Vector2i(-1, -4), Vector2i(1, -2), Vector2i(1, -3), Vector2i(2, -3), Vector2i(2, -4)]:
		px[Vector2i(xm, t) + d] = asa
	for d in [Vector2i(-2, -4), Vector2i(-1, -5), Vector2i(-3, -3), Vector2i(1, -4), Vector2i(2, -5), Vector2i(3, -4), Vector2i(3, -3), Vector2i(0, -1)]:
		px[Vector2i(xm, t) + d] = borda

# ------------------------------------------------------------------ desenho
## Pixels {Vector2i: Color} em tiras horizontais da mesma cor: [Rect2, ...] e [Color, ...].
static func _runs(px: Dictionary) -> Array:
	var rs: Array = []
	var cs: Array = []
	var por_linha: Dictionary = {}
	for p in px.keys():
		var v: Vector2i = p
		if not por_linha.has(v.y):
			por_linha[v.y] = []
		por_linha[v.y].append(v.x)
	for y in por_linha.keys():
		var xs: Array = por_linha[y]
		xs.sort()
		var i: int = 0
		while i < xs.size():
			var x0: int = xs[i]
			var cor: Color = px[Vector2i(x0, y)]
			var j: int = i + 1
			while j < xs.size() and xs[j] == xs[j - 1] + 1 and px[Vector2i(xs[j], y)] == cor:
				j += 1
			rs.append(Rect2(x0, y, j - i + 0.03, 1.03))
			cs.append(cor)
			i = j
	return [rs, cs]

static func _desenhar_runs(c: CanvasItem, e: Array, f: float) -> void:
	var rs: Array = e[0]
	var cs: Array = e[1]
	for k in rs.size():
		c.draw_rect(rs[k], Desenho.b(cs[k], f))
