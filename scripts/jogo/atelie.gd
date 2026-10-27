class_name Atelie
extends RefCounted
## Ateliê: a fantasia secreta. Ao completar o fichário o jogador CRIA a própria fantasia (fase 1: catálogo).
## Escolhe a forma de cada peça entre as que já teve (o desenho é o da peça escolhida, com cor e estampa por cima),
## 1 poder e 1 bônus de kit entre os das fantasias do fichário, e dá um nome. Não há orçamento: é a recompensa de
## completar o fichário, então vale escolher o melhor de tudo. O efeito de cada peça é o molde da forma (força fixa 1,0),
## o poder é o da fantasia escolhida (com a força e a recarga medidas dela, ajustadas por PODER_FORCA_FATOR e
## PODER_RECARGA_FATOR) e o bônus é o do kit da fantasia escolhida. Cor (13 matizes, o 0 é a cor original) e estampa
## (8, a 0 é nenhuma) completam o visual.
## O save guarda as escolhas num campo opcional "atelie" (Estado.atelie); sem ele o Ateliê está vazio.
##
## Pintura (opcional, de graça): o jogador pode repintar cada peça pixel a pixel. Ela parte da "foto" da forma escolhida
## (AtelieArte.fotografar) e, pintada, substitui o desenho da forma; a forma continua dando o efeito e o lugar no gato.
## Formato em cfg["pintura"][espaço] ({} = sem pintura): {"x", "y": canto da grade na unidade da peça; "w", "h": tamanho;
## "pal": cores "rrggbbaa"; "frente", "atras": w*h letras de ALFABETO (índice na paleta) ou "." (vazio)}. "atras" é a camada
## que fica atrás do corpo (capa); peça sem essa camada a deixa toda vazia.

## Ajuste do poder da fantasia criada: a mesma recarga da fantasia de origem e 20% mais força (recompensa do fichário completo).
const PODER_FORCA_FATOR := 1.2
const PODER_RECARGA_FATOR := 1.0
const NOME_MAX := 16
const NOME_VAZIO := "Fantasia sem nome"
const MATIZES := 13
const ESTAMPA_NOME: Array[String] = ["Sem estampa", "Listras", "Bolinhas", "Xadrez", "Coração", "Estrela", "Camuflagem", "Remendos"]
const MATIZ_NOME: Array[String] = ["Original", "Vermelho", "Laranja", "Amarelo", "Lima", "Verde", "Menta", "Ciano", "Azul", "Anil", "Violeta", "Magenta", "Rosa"]

## Fantasias que dão cada bônus de kit disponível no Ateliê (um por tipo de bônus; o Disfarce do Mimiau e a Apara do Meon
## ficam de fora por serem kits compostos).
const BONUS_KITS: Array[int] = [
	Pecas.Conjunto.CAVALEIRO, Pecas.Conjunto.GUARDIAO, Pecas.Conjunto.REI, Pecas.Conjunto.CIRCO, Pecas.Conjunto.VIKING,
	Pecas.Conjunto.JARDINEIRO, Pecas.Conjunto.CAUBOI, Pecas.Conjunto.PIRATA, Pecas.Conjunto.MAGO,
	Pecas.Conjunto.SUPER_MIAU, Pecas.Conjunto.ARQUEIRO_MIAU, Pecas.Conjunto.JIMIAU, Pecas.Conjunto.DISPARAMIAU,
	Pecas.Conjunto.GIRAMIAU, Pecas.Conjunto.STARDEW_MIAULLEY, Pecas.Conjunto.DONATEMIAU, Pecas.Conjunto.RAFAMIAU,
	Pecas.Conjunto.ROCKET_MIAUGUE, Pecas.Conjunto.MIAU_NOIR, Pecas.Conjunto.HOLLOWMIAU, Pecas.Conjunto.SILKMIAU,
	Pecas.Conjunto.SUPER_MIAUJIN, Pecas.Conjunto.ARQUEOLOGO, Pecas.Conjunto.TREINADOR, Pecas.Conjunto.MIAUZILLA,
	Pecas.Conjunto.SUBMIAUTICA, Pecas.Conjunto.CATCHULLU,
]
## Pintura: maior grade, maior paleta e as letras que indexam a paleta.
const PINTURA_MAX := 40
const PINTURA_MIN := 12
const PINTURA_MARGEM := 2
const ALFABETO := "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
const PALETA_MAX := 62
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

## Pintura da peça do Ateliê `tipo` ({} = desenho da forma).
static func pintura(tipo: int) -> Dictionary:
	var ps: Array = cfg.get("pintura", [])
	var s: int = _slot_de(tipo)
	return ps[s] if s >= 0 and s < ps.size() and typeof(ps[s]) == TYPE_DICTIONARY else {}

static func pintada(tipo: int) -> bool:
	return not pintura(tipo).is_empty()

## Quanto a peça do Ateliê `p` soma à força do poder: o mesmo que a peça da fantasia de origem `conj` no mesmo espaço,
## com o nível e a raridade de `p`. Assim o poder é o da origem (vezes PODER_FORCA_FATOR) em qualquer ponto do jogo,
## e não depende da força própria das peças do Ateliê (Pecas.MOLDE_PODER), que vale só para o efeito delas.
static func poder_peca(p: Peca, conj: int) -> float:
	var orig: int = int((Pecas.CONJUNTO_PECAS[conj] as Array)[p.slot()])
	return p.poder() / Pecas.MOLDE_PODER[p.tipo] * Pecas.MOLDE_PODER[orig]

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
	for c in BONUS_KITS:
		if not Pecas.retirada(c) and e.pecas_da_fantasia(c) >= Pecas.SLOTS:
			l.append(c)
	l.sort()
	return l

# ---------- Montar e validar ----------
static func padrao() -> Dictionary:
	return {"nome": NOME_VAZIO, "formas": FORMA_PADRAO.duplicate(), "matizes": [0, 0, 0, 0], "estampa": 0,
		"poder": Pecas.Conjunto.CAVALEIRO, "bonus": Pecas.Conjunto.CIRCO, "pintura": [{}, {}, {}, {}]}

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
	var f: String = ["Miau", "Gato", "Felino", "Bigode"][rng.randi() % 4] # i18n-ok: vira nome digitado/guardado
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
	if po < 0 or po >= Pecas.Conjunto.ATELIE or Pecas.retirada(po) or not BONUS_KITS.has(bo):
		return {}
	c["poder"] = po
	c["bonus"] = bo
	# pintura: a que não serve é descartada sozinha (a fantasia continua valendo)
	var ps: Array = o.get("pintura", []) if typeof(o.get("pintura", [])) == TYPE_ARRAY else []
	c["pintura"] = []
	for s in Pecas.SLOTS:
		c["pintura"].append(ler_pintura(ps[s]) if s < ps.size() else {})
	return c

# ---------- Pintura ----------
## Pintura conferida (tamanho, paleta, letras); {} se não serve.
static func ler_pintura(d: Variant) -> Dictionary:
	if typeof(d) != TYPE_DICTIONARY or (d as Dictionary).is_empty():
		return {}
	var o: Dictionary = d
	var w: int = int(o.get("w", 0))
	var h: int = int(o.get("h", 0))
	var x: int = int(o.get("x", 0))
	var y: int = int(o.get("y", 0))
	if w < 1 or h < 1 or w > PINTURA_MAX or h > PINTURA_MAX or absi(x) > PINTURA_MAX * 2 or absi(y) > PINTURA_MAX * 2:
		return {}
	var pal_in: Variant = o.get("pal", [])
	if typeof(pal_in) != TYPE_ARRAY or (pal_in as Array).size() > PALETA_MAX:
		return {}
	var pal: Array = []
	for c in pal_in:
		var hx: String = str(c)
		if hx.length() != 8 or not hx.is_valid_hex_number():
			return {}
		pal.append(hx.to_lower())
	var camadas: Dictionary = {}
	for k in ["frente", "atras"]:
		var txt: String = str(o.get(k, ""))
		if txt.length() != w * h:
			return {}
		for i in txt.length():
			var ch: String = txt[i]
			if ch == ".":
				continue
			var ix: int = ALFABETO.find(ch)
			if ix < 0 or ix >= pal.size():
				return {}
		camadas[k] = txt
	return {"x": x, "y": y, "w": w, "h": h, "pal": pal, "frente": camadas["frente"], "atras": camadas["atras"]}

## Grade de trabalho do pintor: {"x", "y", "w", "h", "frente", "atras": PackedColorArray (alfa 0 = vazio)}.
static func grade_da_pintura(p: Dictionary) -> Dictionary:
	var w: int = int(p["w"])
	var h: int = int(p["h"])
	var g: Dictionary = {"x": int(p["x"]), "y": int(p["y"]), "w": w, "h": h}
	var pal: Array[Color] = []
	for hx in p["pal"]:
		pal.append(Color.html(str(hx)))
	for k in ["frente", "atras"]:
		var cs := PackedColorArray()
		cs.resize(w * h)
		var txt: String = p[k]
		for i in w * h:
			cs[i] = Color(0, 0, 0, 0) if txt[i] == "." else pal[ALFABETO.find(txt[i])]
		g[k] = cs
	return g

## Pintura (formato do save) a partir da grade do pintor (toda vazia vale: a peça fica invisível). Com mais de PALETA_MAX cores,
## as que sobram viram a mais parecida da paleta.
static func pintura_da_grade(g: Dictionary) -> Dictionary:
	var w: int = int(g["w"])
	var h: int = int(g["h"])
	var pal: Array[Color] = []
	var idx: Dictionary = {}   # "rrggbbaa" -> índice
	var r: Dictionary = {"x": int(g["x"]), "y": int(g["y"]), "w": w, "h": h, "pal": [], "frente": "", "atras": ""}
	for k in ["frente", "atras"]:
		var cs: PackedColorArray = g[k]
		var txt: String = ""
		for i in w * h:
			var c: Color = cs[i]
			if c.a < 0.02:
				txt += "."
				continue
			var hx: String = c.to_html(true)
			if not idx.has(hx):
				if pal.size() < PALETA_MAX:
					idx[hx] = pal.size()
					pal.append(c)
				else:
					idx[hx] = _mais_parecida(pal, c)
			txt += ALFABETO[int(idx[hx])]
		r[k] = txt
	for c in pal:
		r["pal"].append(c.to_html(true))
	return r

static func _mais_parecida(pal: Array[Color], c: Color) -> int:
	var m: int = 0
	var md: float = INF
	for i in pal.size():
		var d: float = Vector4(pal[i].r - c.r, pal[i].g - c.g, pal[i].b - c.b, pal[i].a - c.a).length_squared()
		if d < md:
			md = d
			m = i
	return m

## Grade nova em torno dos pixels {Vector2i: Color} das duas camadas, com folga e tamanho mínimo, sem passar do máximo.
static func grade_em_volta(frente: Dictionary, atras: Dictionary) -> Dictionary:
	var lo := Vector2i(0, -4)
	var hi := Vector2i(0, -4)
	var primeiro: bool = true
	for camada in [frente, atras]:
		for p in camada:
			if primeiro:
				lo = p
				hi = p
				primeiro = false
			lo = Vector2i(mini(lo.x, p.x), mini(lo.y, p.y))
			hi = Vector2i(maxi(hi.x, p.x), maxi(hi.y, p.y))
	lo -= Vector2i(PINTURA_MARGEM, PINTURA_MARGEM)
	hi += Vector2i(PINTURA_MARGEM, PINTURA_MARGEM)
	for eixo in 2:
		var tam: int = hi[eixo] - lo[eixo] + 1
		if tam < PINTURA_MIN:
			var falta: int = PINTURA_MIN - tam
			lo[eixo] -= falta / 2
			hi[eixo] += falta - falta / 2
		elif tam > PINTURA_MAX:
			var sobra: int = tam - PINTURA_MAX
			lo[eixo] += sobra / 2
			hi[eixo] -= sobra - sobra / 2
	var w: int = hi.x - lo.x + 1
	var h: int = hi.y - lo.y + 1
	var g: Dictionary = {"x": lo.x, "y": lo.y, "w": w, "h": h}
	for k in ["frente", "atras"]:
		var cs := PackedColorArray()
		cs.resize(w * h)
		cs.fill(Color(0, 0, 0, 0))
		var camada: Dictionary = frente if k == "frente" else atras
		for p in camada:
			var q: Vector2i = p - lo
			if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h:
				cs[q.y * w + q.x] = camada[p]
		g[k] = cs
	return g

## Ativa as escolhas: nome, cor e nomes das peças passam a valer nas tabelas de Pecas. {} desativa.
static func aplicar(c: Dictionary) -> void:
	cfg = c
	var cj: int = Pecas.Conjunto.ATELIE
	Pecas.CONJUNTO_NOME[cj] = nome() if criada() else "Ateliê" # i18n-ok: identidade de CONJUNTO_NOME, traduzida ao desenhar
	var base: Color = Color(0.95, 0.55, 0.85)
	if criada():
		var h: int = matiz(Pecas.Tipo.ATELIE_CABECA)
		base = Pecas.CONJUNTO_COR[Pecas.CONJUNTO_DE[forma(Pecas.Tipo.ATELIE_CABECA)]]
		if h > 0:
			base = Color.from_hsv(fposmod(base.h + float(h) / 12.0, 1.0), clampf(base.s, 0.35, 1.0), base.v)
	Pecas.CONJUNTO_COR[cj] = base
	for s in Pecas.SLOTS:
		var t: int = Pecas.Tipo.ATELIE_CABECA + s
		Pecas.NOME[t] = Pecas.NOME[forma(t)] if criada() else Pecas.SLOT_NOME[s] + " do Ateliê" # i18n-ok: identidade de NOME, traduzida ao desenhar

## Confirma a criação (ou a refação): guarda as escolhas no estado e garante as 4 peças (Raras, na primeira vez)
## no guarda-roupa. Quem já tem as peças as mantém, com nível, raridade e marcas. Devolve false se as escolhas não
## servem ou o Ateliê ainda estiver fechado.
static func confirmar(e: Estado, c: Dictionary) -> bool:
	var v: Dictionary = ler(c)
	if v.is_empty() or not liberado(e):
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
