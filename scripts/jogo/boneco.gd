class_name Boneco
extends RefCounted
## Boneco do time fixo: carrega as peças, ganha nível e é treinado. Cair na luta é nocaute, não morte.

enum Linha { FRENTE, MEIO, FUNDO }
enum Atr { VIDA, FORCA, AGILIDADE }
enum Postura { AVANCAR, SEGURAR, RECUAR }
const LINHA_NOMES: Array[String] = ["Frente", "Meio", "Fundo"]
const POSTURA_NOMES: Array[String] = ["Avançar", "Segurar", "Recuar"]
const SEM_POSTO := Vector2(-1.0, -1.0)

var nome: String = ""
var pecas: Array = [null, null, null, null]  # cabeça, corpo, mão, acessório
var linha: int = Linha.MEIO  # onde fica na luta; o jogador escolhe no guarda-roupa
var postura: int = -1        # Postura escolhida na preparação da onda; -1 = a da linha (frente avança, o resto segura)
var posto: Vector2 = SEM_POSTO   # posto escolhido arrastando o gato na preparação; SEM_POSTO = o da linha
var herancas: Array[int] = []    # fantasias (Pecas.Conjunto) cujo poder o gato incorporou como passiva, sem repetição
var graus: Array[int] = []       # grau (1 a HERANCA_GRAU_MAX) de cada herança, na mesma ordem; incorporar a mesma fantasia de novo sobe o grau
var nivel: int = 0
var xp: int = 0              # experiência desde o último nível
var pontos: int = 0          # pontos de treino por gastar (um por nível)
var atr: Array[int] = [0, 0, 0]  # pontos em Vida, Força, Agilidade
var estrelas: int = 0        # (sem uso: as patentes viraram níveis)
var vivo: bool = true        # false = nocauteado na onda em curso
var saude: float = 1.0  # fração da vida; ferida não cura sozinha entre ondas
var pop: float = 0.0    # efeito visual ao vestir ou subir de nível
var nasc: float = 0.0   # efeito visual ao nascer (0 -> 1)

## Postura em vigor: a escolhida ou, sem escolha, a da linha.
func postura_atual() -> int:
	if postura >= 0:
		return postura
	return Postura.AVANCAR if linha == Linha.FRENTE else Postura.SEGURAR

## Linha que corresponde a uma posição x do campo (as faixas ficam no meio do caminho entre os postos).
static func linha_de_x(x: float) -> int:
	if x >= (Balanco.LINHA_X[Linha.FRENTE] + Balanco.LINHA_X[Linha.MEIO]) * 0.5:
		return Linha.FRENTE
	if x >= (Balanco.LINHA_X[Linha.MEIO] + Balanco.LINHA_X[Linha.FUNDO]) * 0.5:
		return Linha.MEIO
	return Linha.FUNDO

func xp_para_subir() -> int:
	return Balanco.XP_BASE + mini(nivel, Balanco.XP_NIVEL_TETO)

## Fantasia completa que o gato veste agora (Pecas.Conjunto), ou -1.
func fantasia_completa() -> int:
	var cont: Array[int] = Pecas.contar_conjuntos(pecas)
	for c in cont.size():
		if Pecas.grau_conjunto(cont[c]) == 2:
			return c
	return -1

## Quantas incorporações o gato já fez (cada grau conta uma).
func incorporacoes() -> int:
	var n: int = 0
	for g in graus:
		n += g
	return n

## Grau da herança desta fantasia (0 = ainda não tem).
func grau_de(conj: int) -> int:
	var i: int = herancas.find(conj)
	return 0 if i < 0 else (graus[i] if i < graus.size() else 1)

## Heranças a que o nível já dá direito e que ainda não foram incorporadas.
func herancas_pendentes() -> int:
	return maxi(0, nivel / Balanco.HERANCA_NIVEIS - incorporacoes())

## A fantasia completa vestida pode ser incorporada agora? (Já ter a herança no grau máximo não deixa.)
func pode_incorporar(conj: int) -> bool:
	return herancas_pendentes() > 0 and conj >= 0 and grau_de(conj) < Balanco.HERANCA_GRAU_MAX

## Incorpora o poder da fantasia completa vestida, se há herança pendente: fantasia nova vira uma herança
## de grau I; a mesma de novo sobe o grau da que já existe. Devolve a fantasia ou -1.
func incorporar() -> int:
	var c: int = fantasia_completa()
	if not pode_incorporar(c):
		return -1
	var i: int = herancas.find(c)
	if i >= 0:
		graus[i] += 1
	else:
		herancas.append(c)
		graus.append(1)
	return c

## Soma experiência. Devolve quantos níveis subiu.
func ganhar_xp(n: int) -> int:
	var subiu: int = 0
	xp += n
	while nivel < Balanco.BONECO_NIVEL_MAX and xp >= xp_para_subir():
		xp -= xp_para_subir()
		nivel += 1
		pontos += 1
		subiu += 1
	if nivel >= Balanco.BONECO_NIVEL_MAX:
		xp = 0
	return subiu

## Gasta um ponto de treino num atributo (Atr). Devolve false se não há ponto.
func treinar(a: int) -> bool:
	if pontos <= 0:
		return false
	pontos -= 1
	atr[a] += 1
	return true

func para_dados() -> Dictionary:
	var ps: Array = []
	for p in pecas:
		ps.append(null if p == null else p.para_dados())
	return {"nome": nome, "linha": linha, "postura": postura, "posto": [posto.x, posto.y], "herancas": herancas.duplicate(), "graus": graus.duplicate(), "nivel": nivel, "xp": xp, "pontos": pontos, "atr": atr.duplicate(), "pecas": ps}

static func de_dados(d: Dictionary) -> Boneco:
	var b := Boneco.new()
	b.nome = str(d.get("nome", ""))
	b.linha = clampi(int(d.get("linha", Linha.MEIO)), 0, 2)
	b.postura = clampi(int(d.get("postura", -1)), -1, 2)
	var po: Variant = d.get("posto", [])
	if po is Array and (po as Array).size() == 2 and float(po[0]) >= 0.0:
		b.posto = Vector2(clampf(float(po[0]), Balanco.POSTO_X0, Balanco.POSTO_X1), clampf(float(po[1]), Balanco.POSTO_Y0, Balanco.POSTO_Y1))
	b.nivel = clampi(int(d.get("nivel", 0)), 0, Balanco.BONECO_NIVEL_MAX)
	b.xp = int(d.get("xp", 0))
	var hs: Variant = d.get("herancas", [])
	if hs is Array:
		# gravação antiga: a mesma fantasia repetida na lista vira grau (migração); a nova traz `graus` ao lado
		var gs: Array = d.get("graus", [])
		var k: int = 0
		for h in hs:
			var c: int = int(h)
			var g: int = clampi(int(gs[k]), 1, Balanco.HERANCA_GRAU_MAX) if k < gs.size() else 1
			k += 1
			if c < 0 or c >= Pecas.PODER_TIPO.size():
				continue
			var i: int = b.herancas.find(c)
			if i >= 0:
				b.graus[i] = mini(Balanco.HERANCA_GRAU_MAX, b.graus[i] + g)
			elif b.incorporacoes() < Balanco.BONECO_NIVEL_MAX / Balanco.HERANCA_NIVEIS:
				b.herancas.append(c)
				b.graus.append(g)
	b.pontos = int(d.get("pontos", 0))
	var at: Array = d.get("atr", [])
	for i in mini(3, at.size()):
		b.atr[i] = int(at[i])
	var ps: Array = d.get("pecas", [])
	for s in mini(Pecas.SLOTS, ps.size()):
		if typeof(ps[s]) == TYPE_DICTIONARY:
			var p: Peca = Peca.de_dados(ps[s])
			if p.tipo >= 0 and p.tipo < Pecas.SLOT.size() and p.slot() == s:
				b.pecas[s] = p
	return b
