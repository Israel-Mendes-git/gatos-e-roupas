class_name Atelie
extends RefCounted
## Ateliê: a fantasia secreta. Ao completar o fichário o jogador CRIA a própria fantasia (fase 1: catálogo).
## Escolhe a forma de cada peça entre as que já teve (o desenho é o da peça escolhida, com cor e estampa por cima),
## 1 poder e 1 bônus de kit entre os das fantasias do fichário, e dá um nome. Tudo isso custa pontos de um ORÇAMENTO;
## o efeito de cada peça é o molde da forma (força fixa 1,0), o poder é o da fantasia escolhida (com a mesma força e
## recarga medidas dela) e o bônus é o do kit da fantasia escolhida.
##
## Tabela de custo (orçamento de 14; mínimo possível 8, máximo possível 16: o melhor de tudo não cabe):
##   molde de peça   1 ponto (efeito simples) ou 2 pontos (efeito forte), por peça: 4 a 8
##   poder           3, 4 ou 5 pontos pelo índice FORCA / INTERVALO que Balanco mediu para a fantasia de origem
##                   (PODER_KIT_FORCA / PODER_KIT_INTERVALO): até 1,0 = 3; até 2,6 = 4; acima = 5
##   bônus de kit    1 a 3 pontos (BONUS_CUSTO)
## Cor (13 matizes, o 0 é a cor original) e estampa (8, a 0 é nenhuma) não custam nada.
## O save guarda as escolhas num campo opcional "atelie" (Estado.atelie); sem ele o Ateliê está vazio.

const ORCAMENTO := 14
const NOME_MAX := 16
const NOME_VAZIO := "Fantasia sem nome"
const MATIZES := 13
const ESTAMPA_NOME: Array[String] = ["Sem estampa", "Listras", "Bolinhas", "Xadrez", "Coração", "Estrela", "Camuflagem", "Remendos"]
const MATIZ_NOME: Array[String] = ["Original", "Vermelho", "Laranja", "Âmbar", "Amarelo", "Lima", "Verde", "Menta", "Ciano", "Azul", "Violeta", "Roxo", "Rosa"]

## Moldes de efeito forte (2 pontos); os outros custam 1.
const MOLDES_FORTES: Array[int] = [
	Pecas.Tipo.COROA, Pecas.Tipo.CHIFRES, Pecas.Tipo.CARTOLA, Pecas.Tipo.CAUBOI, Pecas.Tipo.PELE, Pecas.Tipo.CASACO,
	Pecas.Tipo.MANTO, Pecas.Tipo.VARINHA, Pecas.Tipo.CETRO, Pecas.Tipo.COLAR, Pecas.Tipo.GANCHO, Pecas.Tipo.AMULETO,
]
## Fantasias que dão cada bônus de kit disponível no Ateliê (um por tipo de bônus; o Disfarce do Mimiau e a Apara do Meon
## ficam de fora por serem kits compostos) e o custo em pontos.
const BONUS_CUSTO: Dictionary = {
	Pecas.Conjunto.CAVALEIRO: 2, Pecas.Conjunto.GUARDIAO: 3, Pecas.Conjunto.REI: 2, Pecas.Conjunto.CIRCO: 1,
	Pecas.Conjunto.VIKING: 3, Pecas.Conjunto.JARDINEIRO: 2, Pecas.Conjunto.CAUBOI: 2, Pecas.Conjunto.PIRATA: 2,
	Pecas.Conjunto.MAGO: 1, Pecas.Conjunto.SUPER_MIAU: 2, Pecas.Conjunto.ARQUEIRO_MIAU: 3, Pecas.Conjunto.JIMIAU: 1,
	Pecas.Conjunto.DISPARAMIAU: 2, Pecas.Conjunto.GIRAMIAU: 2, Pecas.Conjunto.STARDEW_MIAULLEY: 2,
	Pecas.Conjunto.DONATEMIAU: 2, Pecas.Conjunto.RAFAMIAU: 2, Pecas.Conjunto.ROCKET_MIAUGUE: 1,
	Pecas.Conjunto.MIAU_NOIR: 2, Pecas.Conjunto.HOLLOWMIAU: 1, Pecas.Conjunto.SILKMIAU: 2, Pecas.Conjunto.SUPER_MIAUJIN: 2,
	Pecas.Conjunto.ARQUEOLOGO: 2, Pecas.Conjunto.TREINADOR: 2, Pecas.Conjunto.MIAUZILLA: 1,
	Pecas.Conjunto.SUBMIAUTICA: 2, Pecas.Conjunto.CATCHULLU: 1,
}
const FORMA_PADRAO: Array[int] = [Pecas.Tipo.CAPACETE, Pecas.Tipo.COLETE, Pecas.Tipo.PORRETE, Pecas.Tipo.BOTAS]
const _PREFIXOS: Array[String] = ["Super", "Mega", "Capitão", "Doutor", "Mestre", "Sombra", "Estrela", "Relâmpago", "Turbo", "Ninja"]

## Escolhas ativas ({} = nada criado ainda). Estado.atelie aponta para este mesmo dicionário.
static var cfg: Dictionary = {}

static func criada() -> bool:
	return not cfg.is_empty()

static func _slot_de(tipo: int) -> int:
	return tipo - Pecas.Tipo.ATELIE_CABECA

## Tipo da peça escolhida para o espaço da peça do Ateliê `tipo` (as peças comuns voltam como estão).
static func forma(tipo: int) -> int:
	if tipo < Pecas.Tipo.ATELIE_CABECA:
		return tipo
	var s: int = _slot_de(tipo)
	var fs: Array = cfg.get("formas", [])
	return int(fs[s]) if s < fs.size() else FORMA_PADRAO[s]

static func molde(tipo: int) -> int:
	return Pecas.MOLDE[forma(tipo)]

static func matiz(tipo: int) -> int:
	var ms: Array = cfg.get("matizes", [])
	var s: int = _slot_de(tipo)
	return int(ms[s]) if s >= 0 and s < ms.size() else 0

static func estampa() -> int:
	return int(cfg.get("estampa", 0))

static func poder_conj() -> int:
	return int(cfg.get("poder", Pecas.Conjunto.CAVALEIRO))

static func bonus_conj() -> int:
	return int(cfg.get("bonus", Pecas.Conjunto.CAVALEIRO))

static func nome() -> String:
	return str(cfg.get("nome", NOME_VAZIO))

# ---------- Custos ----------
static func custo_molde(m: int) -> int:
	return 2 if m in MOLDES_FORTES else 1

## Índice de potência do poder da fantasia `c` (força / recarga medidas em Balanco).
static func indice_poder(c: int) -> float:
	return float(Balanco.PODER_KIT_FORCA.get(c, 1.0)) / float(Balanco.PODER_KIT_INTERVALO.get(c, 1.0))

static func custo_poder(c: int) -> int:
	var ix: float = indice_poder(c)
	if ix <= 1.0:
		return 3
	return 4 if ix <= 2.6 else 5

static func custo_bonus(c: int) -> int:
	return int(BONUS_CUSTO.get(c, 3))

static func custo_forma(tipo: int) -> int:
	return custo_molde(Pecas.MOLDE[tipo])

## Custo total de um conjunto de escolhas.
static func custo(c: Dictionary) -> int:
	var total: int = custo_poder(int(c.get("poder", 0))) + custo_bonus(int(c.get("bonus", 0)))
	for t in c.get("formas", []):
		total += custo_forma(int(t))
	return total

static func dentro_do_orcamento(c: Dictionary) -> bool:
	return custo(c) <= ORCAMENTO

# ---------- O que o jogador pode escolher ----------
## O Ateliê abre quando todas as fantasias do fichário estão completas.
static func liberado(e: Estado) -> bool:
	return e.fantasias_completas() >= Pecas.n_ativas()

## Formas que o jogador pode usar no espaço `s`: peças que já teve, de fantasias que estão no jogo.
static func formas(e: Estado, s: int) -> Array[int]:
	var l: Array[int] = []
	for t in Pecas.POR_SLOT[s]:
		if t < Pecas.Tipo.ATELIE_CABECA and not Pecas.retirada(Pecas.CONJUNTO_DE[t]) and e.ja_teve(t):
			l.append(t)
	return l

## Fantasias cujo poder o jogador pode escolher (as que completou, fora o Ateliê).
static func poderes(e: Estado) -> Array[int]:
	var l: Array[int] = []
	for c in Pecas.CONJUNTO_NOME.size():
		if not Pecas.retirada(c) and e.pecas_da_fantasia(c) >= Pecas.SLOTS:
			l.append(c)
	return l

## Fantasias cujo bônus de kit o jogador pode escolher (as completas que têm bônus no catálogo).
static func bonus(e: Estado) -> Array[int]:
	var l: Array[int] = []
	for c in BONUS_CUSTO:
		if not Pecas.retirada(c) and e.pecas_da_fantasia(c) >= Pecas.SLOTS:
			l.append(c)
	l.sort()
	return l

# ---------- Montar e validar ----------
static func padrao() -> Dictionary:
	return {"nome": NOME_VAZIO, "formas": FORMA_PADRAO.duplicate(), "matizes": [0, 0, 0, 0], "estampa": 0,
		"poder": Pecas.Conjunto.CAVALEIRO, "bonus": Pecas.Conjunto.CIRCO}

## Nome limpo: sem espaços nas pontas, só letras (com acento), números, espaço e . - ' ! (sem controle nem emoji), até NOME_MAX.
static func limpar_nome(s: String) -> String:
	var r: String = ""
	for i in s.length():
		var u: int = s.unicode_at(i)
		var bom: bool = (u >= 48 and u <= 57) or (u >= 65 and u <= 90) or (u >= 97 and u <= 122) or (u >= 0xC0 and u <= 0x24F and u != 0xD7 and u != 0xF7)
		bom = bom or u == 32 or u == 45 or u == 46 or u == 39 or u == 33
		if bom:
			r += s[i]
	r = r.strip_edges()
	while "  " in r:
		r = r.replace("  ", " ")
	r = r.substr(0, NOME_MAX).strip_edges()
	return r if r != "" else NOME_VAZIO

static func sugerir_nome(rng: RandomNumberGenerator) -> String:
	var p: String = _PREFIXOS[rng.randi() % _PREFIXOS.size()]
	var f: String = ["Miau", "Gato", "Felino", "Bigode"][rng.randi() % 4]
	return limpar_nome(p + " " + f)

## Lê as escolhas do save com tudo conferido; devolve {} se não servem (save antigo, editado ou de outra versão).
static func ler(d: Variant) -> Dictionary:
	if typeof(d) != TYPE_DICTIONARY or not (d as Dictionary).has("formas"):
		return {}
	var o: Dictionary = d
	var fs: Array = o.get("formas", [])
	var ms: Array = o.get("matizes", [])
	if fs.size() != Pecas.SLOTS:
		return {}
	var c: Dictionary = {"nome": limpar_nome(str(o.get("nome", ""))), "formas": [], "matizes": [], "estampa": clampi(int(o.get("estampa", 0)), 0, ESTAMPA_NOME.size() - 1)}
	for s in Pecas.SLOTS:
		var t: int = int(fs[s])
		if t < 0 or t >= Pecas.Tipo.ATELIE_CABECA or Pecas.SLOT[t] != s:
			return {}
		c["formas"].append(t)
		c["matizes"].append(clampi(int(ms[s]) if s < ms.size() else 0, 0, MATIZES - 1))
	var po: int = int(o.get("poder", -1))
	var bo: int = int(o.get("bonus", -1))
	if po < 0 or po >= Pecas.Conjunto.ATELIE or Pecas.retirada(po) or not BONUS_CUSTO.has(bo):
		return {}
	c["poder"] = po
	c["bonus"] = bo
	return c

## Ativa as escolhas: nome, cor e nomes das peças passam a valer nas tabelas de Pecas. {} desativa.
static func aplicar(c: Dictionary) -> void:
	cfg = c
	var cj: int = Pecas.Conjunto.ATELIE
	Pecas.CONJUNTO_NOME[cj] = nome() if criada() else "Ateliê"
	var base: Color = Color(0.95, 0.55, 0.85)
	if criada():
		var h: int = matiz(Pecas.Tipo.ATELIE_CABECA)
		base = Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[forma(Pecas.Tipo.ATELIE_CABECA)]]
		if h > 0:
			base = Color.from_hsv(fposmod(base.h + float(h) / 12.0, 1.0), clampf(base.s, 0.35, 1.0), base.v)
	Pecas.CONJUNTO_COR[cj] = base
	for s in Pecas.SLOTS:
		var t: int = Pecas.Tipo.ATELIE_CABECA + s
		Pecas.NOME[t] = Pecas.NOME[forma(t)] if criada() else Pecas.SLOT_NOME[s] + " do Ateliê"

## Confirma a criação (ou a refação): guarda as escolhas no estado e garante as 4 peças (Raras, na primeira vez)
## no guarda-roupa. Quem já tem as peças as mantém, com nível, raridade e marcas. Devolve false se estourar o orçamento
## ou o Ateliê ainda estiver fechado.
static func confirmar(e: Estado, c: Dictionary) -> bool:
	var v: Dictionary = ler(c)
	if v.is_empty() or not dentro_do_orcamento(v) or not liberado(e):
		return false
	e.atelie = v
	aplicar(v)
	var tidas: Array[Peca] = e.todas_as_pecas()
	for s in Pecas.SLOTS:
		var t: int = Pecas.Tipo.ATELIE_CABECA + s
		var tem: bool = false
		for p in tidas:
			if p.tipo == t:
				tem = true
		if not tem:
			e.guarda.append(Peca.new(t, 0, Pecas.Raridade.RARA))
		e.registrar(t)
	e.conferir_metas()
	e.salvar()
	return true
