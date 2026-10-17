class_name Estado
extends RefCounted
## Estado da campanha e da fase em curso (tijolos, bonecos, guarda-roupa).
## Compartilhado pelo jogo e pelo simulador.

const ARQUIVO := "user://campanha.json"

var fase: int = 1             # cômodo em curso (1..Fases.TOTAL)
var fase_liberada: int = 1    # maior fase que o jogador pode escolher no mapa
var fases_vencidas: int = 0   # maior fase já vencida (Fases.TOTAL = campanha terminada)
var persistir: bool = false   # o jogo grava em disco; o simulador não
var tutorial_facil: bool = false   # tutorial ativo: a 1ª onda vem mais fraca (ver Tutorial.FACIL); nunca é gravado
var tijolos: int = Balanco.TIJOLOS_INICIAIS
# fichário: tipos de peça que o jogador já teve alguma vez (índice = Pecas.Tipo)
var colecao: Array[bool] = []
# bestiário (aba "Bichos" do fichário): chaves dos bichos já vistos numa prévia de onda.
# "f0".."f4" famílias da casa, "b0".."b4" bandos de fora, "t0".."t8" tipos (Unidade.Tipo), "t9" fantasiado, "c0".."c9" chefes
const BICHOS_TOTAL := 30
var bichos_vistos: Dictionary = {}
# torre: troféus (moeda permanente), melhorias compradas e módulos montados
var trofeus: int = 0
var melhorias: Array[int] = [0, 0, 0, 0]      # nível de cada Torre.Melhoria
var modulos: Array[int] = []                  # Torre.Modulo montados (até vagas_modulos())
var onda: int = 1
# invasão sem fim: mesmo cômodo, ondas até cair; `onda` gira de 1 a 5 (chefe a cada cinco) e esta conta o total
var invasao: bool = false
var onda_invasao: int = 0
var recordes: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]    # melhor onda vencida na invasão, por lugar (ver lugar())
# números da campanha (tela de final) e feitos anotados para as metas do fichário
var ato: int = 1                             # ato do cômodo em curso (1 na campanha de ida e na invasão)
var vencido: Array[int] = [0, 0, 0, 0, 0]    # maior ato já vencido em cada cômodo
var fundida_em: Dictionary = {}               # peça que caiu -> peça do jogador em que ela se fundiu (a tela lê e esvazia)
var em_curso: bool = false                   # há um cômodo (ou invasão) começado: vai para a gravação e volta ao abrir o jogo
var herancas_novas: Array = []   # [boneco, fantasia] incorporadas na última onda vencida (a tela lê e esvazia)
var estat: Dictionary = {"ondas": 0, "nocautes": 0, "abates": 0, "tempo": 0.0, "derrotas": 0}
var feitos: Dictionary = {}
var metas_pagas: Dictionary = {}
var metas_novas: Array[String] = []           # metas cumpridas e ainda não mostradas ao jogador
var nocautes_fase: int = 0
var bonecos: Array[Boneco] = []   # o time fixo: atravessa as fases junto com o guarda-roupa
var guarda: Array[Peca] = []  # atravessa as fases: é o que a campanha acumula
var plano: Array = []
var chefe: Array = []    # peças do chefe da próxima onda; vazio se não há
var rng := RandomNumberGenerator.new()

func _init(semente: int = 0) -> void:
	if semente == 0:
		rng.randomize()
	else:
		rng.seed = semente

## Campanha nova: guarda-roupa do começo, só o Quarto liberado.
func novo_jogo() -> void:
	fase_liberada = 1
	fases_vencidas = 0
	ato = 1
	vencido = [0, 0, 0, 0, 0]
	trofeus = 0
	melhorias = [0, 0, 0, 0]
	modulos.clear()
	invasao = false
	onda_invasao = 0
	recordes = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	estat = {"ondas": 0, "nocautes": 0, "abates": 0, "tempo": 0.0, "derrotas": 0}
	feitos.clear()
	metas_pagas.clear()
	metas_novas.clear()
	bonecos.clear()
	guarda.clear()
	for t in [Pecas.Tipo.PORRETE, Pecas.Tipo.ESTILINGUE, Pecas.Tipo.COLETE, Pecas.Tipo.CAPACETE]:
		guarda.append(Peca.new(t))
	colecao.clear()
	bichos_vistos.clear()
	_registrar_tudo()
	_completar_time()
	iniciar_fase(1)
	salvar()

## Tamanho do time: começa com BONECOS_INICIAIS e ganha um a cada fase vencida, até MAX_BONECOS.
func tamanho_time() -> int:
	return mini(Balanco.MAX_BONECOS, Balanco.BONECOS_INICIAIS + fases_vencidas)

## Cria os bonecos que faltam. Devolve quantos entraram.
func _completar_time() -> int:
	var novos: int = 0
	while bonecos.size() < tamanho_time():
		var b := Boneco.new()
		b.nome = Balanco.NOMES_BONECOS[bonecos.size() % Balanco.NOMES_BONECOS.size()]
		bonecos.append(b)
		novos += 1
	return novos

## Entra num cômodo: torre nova e time descansado; roupas e bonecos vêm como estavam.
## Ato que o jogador está jogando agora: 1 até vencer o Porão; depois, o primeiro ato em que
## ainda falta algum cômodo (com tudo vencido, o último ato fica para jogar de novo).
func ato_atual() -> int:
	if fases_vencidas < Fases.TOTAL:
		return 1
	var menor: int = Balanco.ATOS
	for v in vencido:
		menor = mini(menor, v)
	return clampi(menor + 1, 2, Balanco.ATOS)

## Cômodos já vencidos no ato `a` (os que ficam para depois chegam mais fortes).
func vencidos_no_ato(a: int) -> int:
	var n: int = 0
	for v in vencido:
		if v >= a:
			n += 1
	return n

## Degrau de força do cômodo em curso dentro do ato (0 no primeiro cômodo; jogar de novo vale o último degrau).
func degrau_ato() -> int:
	return mini(vencidos_no_ato(ato), Fases.TOTAL - 1)

## Índice do lugar em curso nas tabelas de Fases (0..4 cômodos; 5..9 lugares de fora, do segundo ato; 10..14 ruas do terceiro).
func lugar() -> int:
	return clampi(fase, 1, Fases.TOTAL) - 1 + Fases.TOTAL * (clampi(ato, 1, 3) - 1)

## Todos os cômodos vencidos em todos os atos.
func tudo_vencido() -> bool:
	return vencidos_no_ato(Balanco.ATOS) >= Fases.TOTAL

## Multiplicadores de vida e dano dos bichos do cômodo em curso (sem contar a invasão).
func mult_vida() -> float:
	if ato <= 1:
		return Balanco.FASE_VIDA[fase - 1] * _facil()
	return Balanco.ATO_VIDA[ato - 1] * Balanco.ATO_COMODO_VIDA[fase - 1] * (1.0 + Balanco.ATO_VIDA_DEGRAU * degrau_ato())

## Só com o tutorial ativo e só na primeira onda do cômodo; fora disso é 1 (o balanço normal não muda).
func _facil() -> float:
	return Tutorial.FACIL if tutorial_facil and onda <= 1 and not invasao else 1.0

func mult_dano() -> float:
	if ato <= 1:
		return Balanco.FASE_DANO[fase - 1] * _facil()
	return Balanco.ATO_DANO[ato - 1] * Balanco.ATO_COMODO_DANO[fase - 1] * (1.0 + Balanco.ATO_DANO_DEGRAU * degrau_ato())

## "Fase" que conta para a vida extra do chefe.
func degrau_chefe() -> float:
	if ato <= 1:
		return fase - 1.0
	return (Fases.TOTAL - 1.0) + (ato - 2) * Fases.TOTAL + degrau_ato()

var _pesos_fantasia: Dictionary = {}   # pesos do sorteio de fantasias da luta em curso (fixos até a luta acabar)
var _pesos_validos: bool = false

func iniciar_fase(f: int) -> void:
	_pesos_validos = false
	invasao = false
	onda_invasao = 0
	nocautes_fase = 0
	fase = clampi(f, 1, Fases.TOTAL)
	ato = ato_atual()
	tijolos = tijolos_max()
	onda = 1
	_completar_time()
	recolher()
	em_curso = true
	preparar_onda()

## Repete um cômodo da casa depois de o 1º ato estar vencido: família e força do 1º ato (o 2º ato é jogado lá fora).
func iniciar_fase_casa(f: int) -> void:
	iniciar_fase(f)
	ato = 1
	_pesos_validos = false
	preparar_onda()

## Invasão sem fim no cômodo `f` (só depois de zerar a campanha): ondas até a torre cair.
## `fora`: invasão num lugar de fora da casa (só depois de vencê-lo no segundo ato); senão, no cômodo.
func iniciar_invasao(f: int, fora: bool = false) -> void:
	iniciar_fase(f)
	ato = 2 if fora and vencido[clampi(f, 1, Fases.TOTAL) - 1] >= 2 else 1   # no cômodo: família da casa e a força de sempre
	invasao = true
	_pesos_validos = false
	onda_invasao = 1
	preparar_onda()

## Multiplicadores a mais dos bichos (só crescem na invasão).
func forca_vida() -> float:
	return (Balanco.INVASAO_FORA_VIDA if ato > 1 else 1.0) * (1.0 + Balanco.INVASAO_VIDA_ONDA * (onda_invasao - 1) + Balanco.INVASAO_VIDA_ONDA2 * (onda_invasao - 1) * (onda_invasao - 1)) if invasao else 1.0

func forca_dano() -> float:
	return (Balanco.INVASAO_FORA_DANO if ato > 1 else 1.0) * (1.0 + Balanco.INVASAO_DANO_ONDA * (onda_invasao - 1) + Balanco.INVASAO_DANO_ONDA2 * (onda_invasao - 1) * (onda_invasao - 1)) if invasao else 1.0

func melhor_invasao() -> int:
	var m: int = 0
	for r in recordes:
		m = maxi(m, r)
	return m

## Fim de fase (vitória, derrota ou desistência): o time se levanta e descansa. Ninguém tira a roupa.
func recolher() -> void:
	em_curso = false
	for b in bonecos:
		b.vivo = true
		b.saude = 1.0

func preparar_onda() -> void:
	if not _pesos_validos:
		_pesos_fantasia = pesos_fantasia_do_lugar()
		_pesos_validos = true
	plano = Balanco.gerar_plano(fase, onda, rng, ato, degrau_ato(), _pesos_fantasia)
	chefe = Balanco.gerar_chefe(fase, onda, rng, ato, degrau_ato(), _pesos_fantasia)
	_ver_onda()

## Peso de cada fantasia do lugar em curso no sorteio de fantasiados e chefe: PESO_FANTASIA_FALTA para as que o jogador
## ainda não completou, 1,0 para as completas (todas completas = sorteio uniforme). Calculado uma vez por luta.
func pesos_fantasia_do_lugar() -> Dictionary:
	var pesos: Dictionary = {}
	for c in Fases.lista_do_lugar(lugar()):
		pesos[c] = Balanco.PESO_FANTASIA_FALTA if pecas_da_fantasia(c) < Pecas.SLOTS else 1.0
	return pesos

## Anota no bestiário tudo o que a onda preparada mostra na prévia: famílias, tipos, fantasiados e chefe.
func _ver_onda() -> void:
	var lg: int = lugar()
	for it in plano:
		var d: Dictionary = it
		bichos_vistos["t%d" % int(d.get("tipo", 0))] = true
		if d.get("elite", false):
			bichos_vistos["t9"] = true
		if d.has("fam"):
			bichos_vistos["f%d" % int(d["fam"])] = true
		elif lg < Fases.TOTAL:
			bichos_vistos["f%d" % lg] = true
		else:
			bichos_vistos["b%d" % (lg - Fases.TOTAL)] = true
	if not chefe.is_empty():
		bichos_vistos["c%d" % lg] = true

func viu_bicho(chave: String) -> bool:
	return bichos_vistos.has(chave)

func bichos_vistos_total() -> int:
	return bichos_vistos.size()

## Gravação de antes do bestiário: deduz o que o jogador já deve ter visto pelo andamento da campanha.
func _inferir_bichos() -> void:
	bichos_vistos.clear()
	if int(estat.get("ondas", 0)) <= 0 and fase_liberada <= 1 and fases_vencidas <= 0:
		return
	var maxp: int = Balanco.progresso(fase_liberada, 1)
	if fases_vencidas > 0:
		maxp = maxi(maxp, Balanco.progresso(fases_vencidas, Balanco.ONDAS_TOTAIS))
	for t in Balanco.TIPO_NOMES.size():
		if t == 0 or maxp >= Balanco.TIPO_PROG_MIN[t]:
			bichos_vistos["t%d" % t] = true
	if int(estat.get("ondas", 0)) >= Balanco.ELITE_ONDA_MIN or fases_vencidas > 0:
		bichos_vistos["t9"] = true
	for i in mini(fase_liberada, Fases.TOTAL):
		bichos_vistos["f%d" % i] = true
	for i in Fases.TOTAL:
		if vencido[i] >= 1:
			bichos_vistos["c%d" % i] = true
			bichos_vistos["f%d" % i] = true
		if vencido[i] >= 2:
			bichos_vistos["c%d" % (i + Fases.TOTAL)] = true
			bichos_vistos["b%d" % i] = true

func progresso() -> int:
	if ato > 1:
		return Balanco.progresso_ato(ato, degrau_ato(), onda)
	return Balanco.progresso(fase, onda)

## Quanto a torre cura cada boneco antes da próxima onda (depende da altura dela agora).
func cura_atual() -> float:
	return (Balanco.CURA_MAX + Torre.enfermaria_cura(melhorias[Torre.Melhoria.ENFERMARIA])) * clampf(float(tijolos) / tijolos_max(), 0.0, 1.0)

# ---------- Fichário ----------
func _garantir_colecao() -> void:
	while colecao.size() < Pecas.SLOT.size():
		colecao.append(false)

## Anota no fichário que o jogador já teve uma peça deste tipo.
func registrar(tipo: int) -> void:
	_garantir_colecao()
	colecao[tipo] = true

func ja_teve(tipo: int) -> bool:
	if colecao.size() < Pecas.SLOT.size():
		_garantir_colecao()
	return colecao[tipo]

## Quantas das 4 peças da fantasia o jogador já teve.
func pecas_da_fantasia(c: int) -> int:
	if colecao.size() < Pecas.SLOT.size():
		_garantir_colecao()
	var n: int = 0
	for tp in Pecas.CONJUNTO_PECAS[c]:
		if colecao[tp]:
			n += 1
	return n

func fantasias_completas() -> int:
	var n: int = 0
	for c in Pecas.CONJUNTO_PECAS.size():
		if not Pecas.retirada(c) and pecas_da_fantasia(c) >= Pecas.SLOTS:
			n += 1
	return n

## Anota tudo o que está no guarda-roupa e nos gatos (para gravações antigas e para o começo da campanha).
func _registrar_tudo() -> void:
	for p in guarda:
		registrar(p.tipo)
	for b in bonecos:
		for p in b.pecas:
			if p != null:
				registrar(p.tipo)

# ---------- Torre ----------
## Blocos com que a torre começa cada cômodo (e teto dela na luta).
func tijolos_max() -> int:
	return Balanco.TIJOLOS_INICIAIS + Torre.ESTRUTURA_BLOCOS * melhorias[Torre.Melhoria.ESTRUTURA]

func torre_dano() -> float:
	return Balanco.TORRE_TIRO_DANO * (1.0 + Torre.CANHAO_DANO * melhorias[Torre.Melhoria.CANHAO])

## Multiplicador da cadência do tiro (1.0 sem melhoria).
func torre_rapidez() -> float:
	return 1.0 + Torre.CADENCIA_RAPIDEZ * melhorias[Torre.Melhoria.CADENCIA]

func pode_melhorar(m: int) -> bool:
	return melhorias[m] < Torre.MELHORIA_NIVEL_MAX and trofeus >= Torre.custo_melhoria(melhorias[m])

## Compra um nível da melhoria com troféus. A Estrutura vale a partir do próximo cômodo; as demais, já.
func melhorar(m: int) -> bool:
	if not pode_melhorar(m):
		return false
	trofeus -= Torre.custo_melhoria(melhorias[m])
	melhorias[m] += 1
	salvar()
	return true

## O módulo existe para montar? (O chefe que o guarda já foi vencido.)
func modulo_liberado(m: int) -> bool:
	if m >= Torre.MODULOS_POR_ABA:
		return m < Torre.MODULO_NOME.size() and vencido[m - Torre.MODULOS_POR_ABA] >= 2   # o chefe do lugar de fora (2º ato)
	return fases_vencidas > m

## Atos em que todos os lugares já foram vencidos (0 a ATOS).
func atos_vencidos() -> int:
	var n: int = 0
	for a in range(1, Balanco.ATOS + 1):
		if vencidos_no_ato(a) >= Fases.TOTAL:
			n += 1
		else:
			break
	return n

## Vagas de módulo na torre agora.
func vagas_modulos() -> int:
	return Torre.vagas(atos_vencidos())

func tem_modulo(m: int) -> bool:
	return m in modulos

## Monta ou desmonta um módulo. Devolve false se não está liberado ou se a torre já está cheia.
func alternar_modulo(m: int) -> bool:
	if m in modulos:
		modulos.erase(m)
		salvar()
		return true
	if not modulo_liberado(m) or modulos.size() >= vagas_modulos():
		return false
	modulos.append(m)
	salvar()
	return true

func dono_de(p: Peca) -> Boneco:
	for b in bonecos:
		if b.pecas[p.slot()] == p:
			return b
	return null

func vestir(b: Boneco, p: Peca) -> void:
	var s: int = p.slot()
	if b.pecas[s] == p:
		return
	var anterior: Peca = b.pecas[s]
	var dono: Boneco = dono_de(p)
	if dono != null:
		dono.pecas[s] = anterior
	else:
		guarda.erase(p)
		if anterior != null:
			guarda.append(anterior)
	b.pecas[s] = p
	b.pop = 1.0
	p.nova = false

func tirar(b: Boneco, s: int) -> void:
	var p: Peca = b.pecas[s]
	if p != null:
		b.pecas[s] = null
		guarda.append(p)

func tirar_tudo(b: Boneco) -> void:
	for s in Pecas.SLOTS:
		tirar(b, s)

## (O time é fixo: não se compra mais boneco. Mantido para chamadas antigas.)
func comprar_boneco() -> bool:
	return false

## Gasta um ponto de treino do boneco no atributo (Boneco.Atr).
func treinar(b: Boneco, a: int) -> bool:
	if not b.treinar(a):
		return false
	b.pop = 1.0
	salvar()
	return true

func promover(p: Peca) -> bool:
	if p.nivel >= Balanco.NIVEL_MAX or tijolos < Balanco.custo_promocao(p.nivel):
		return false
	tijolos -= Balanco.custo_promocao(p.nivel)
	p.nivel += 1
	return true

## Promove de uma vez as peças que o gato veste (as que ainda podem subir), enquanto houver blocos.
## Devolve quantas subiram.
func promover_fantasia(b: Boneco) -> int:
	var n: int = 0
	for p in b.pecas:
		if p != null and promover(p):
			n += 1
	return n

## Quantos blocos custaria promover tudo o que o gato veste.
func custo_promover_fantasia(b: Boneco) -> int:
	var n: int = 0
	for p in b.pecas:
		if p != null and p.nivel < Balanco.NIVEL_MAX:
			n += Balanco.custo_promocao(p.nivel)
	return n

## Duas peças iguais podem virar uma? (Mesmo tipo, e a fusão ainda tem o que melhorar.)
func pode_fundir(a: Peca, b: Peca) -> bool:
	if a == null or b == null or a == b or a.tipo != b.tipo:
		return false
	var nivel: int = maxi(a.nivel, b.nivel)
	var rar: int = maxi(a.raridade, b.raridade)
	return nivel < Balanco.NIVEL_MAX or rar < Pecas.Raridade.MITICA

## Funde `outra` em `base` (de graça): a base fica com a maior raridade das duas e um nível acima do
## maior; se o nível já está no teto, sobe a raridade. Marcas e abates se somam (até o que a peça aguenta).
## A outra peça some do guarda-roupa ou do gato que a vestia. Devolve false se não dá para fundir.
func fundir(base: Peca, outra: Peca) -> bool:
	if not pode_fundir(base, outra):
		return false
	var nivel: int = maxi(base.nivel, outra.nivel)
	var rar: int = maxi(base.raridade, outra.raridade)
	if nivel < Balanco.NIVEL_MAX:
		nivel += 1
	else:
		rar += 1
	base.nivel = nivel
	base.raridade = rar
	base.prog = 0
	base.abates += outra.abates
	for m in outra.marcas:
		base.marcar(m)
	base.nova = true
	var dono: Boneco = dono_de(outra)
	if dono != null:
		dono.pecas[outra.slot()] = null
	guarda.erase(outra)
	conferir_metas()
	salvar()
	return true

## Troféus que custaria subir uma raridade em cada peça vestida que ainda pode subir.
func custo_reforcar_fantasia(b: Boneco) -> int:
	var total: int = 0
	for p in b.pecas:
		if p != null and p.raridade < Pecas.Raridade.MIAUJESTOSA:
			total += Balanco.custo_reforco(p.raridade)
	return total

## Sobe uma raridade em cada peça vestida, das mais baratas para as mais caras, enquanto houver troféus.
## Devolve quantas subiram.
func reforcar_fantasia(b: Boneco) -> int:
	var n: int = 0
	for rar in [Pecas.Raridade.COMUM, Pecas.Raridade.RARA, Pecas.Raridade.EPICA, Pecas.Raridade.LENDARIA, Pecas.Raridade.MITICA]:
		for p in b.pecas:
			if p != null and not p.raridade_subiu and p.raridade == rar and pode_reforcar(p) and reforcar(p):
				n += 1
				p.raridade_subiu = true
	for p in b.pecas:
		if p != null:
			p.raridade_subiu = false
	return n

func pode_reforcar(p: Peca) -> bool:
	return p != null and p.raridade < Pecas.Raridade.MIAUJESTOSA and trofeus >= Balanco.custo_reforco(p.raridade)

## Paga troféus para subir a raridade da peça (mais efeito e mais espaço para marcas).
func reforcar(p: Peca) -> bool:
	if not pode_reforcar(p):
		return false
	trofeus -= Balanco.custo_reforco(p.raridade)
	p.raridade += 1
	p.nova = true
	salvar()
	return true

## Multiplicador de XP de recuperação: gato abaixo da média de nível dos OUTROS ganha mais XP (1x se empata ou passa).
func mult_recupera(b: Boneco) -> float:
	var soma: float = 0.0
	var n: int = 0
	for o in bonecos:
		if o != b:
			soma += o.nivel
			n += 1
	if n == 0:
		return 1.0
	var atras: float = soma / n - b.nivel
	if atras <= 0.0:
		return 1.0
	return minf(Balanco.XP_RECUPERA_MAX, 1.0 + Balanco.XP_RECUPERA_POR_NIVEL * atras)

## XP da onda para cada gato (metade, arredondada para cima, a quem caiu), com a recuperação de quem está atrás.
## Os multiplicadores são calculados antes de qualquer um subir, para a ordem do time não pesar.
func dar_xp_onda() -> void:
	var xp_onda: int = Balanco.XP_ONDA_ATO[clampi(ato, 1, Balanco.XP_ONDA_ATO.size()) - 1]
	var mults: Array[float] = []
	for b in bonecos:
		mults.append(mult_recupera(b))
	for i in bonecos.size():
		var b: Boneco = bonecos[i]
		var base: int = xp_onda if b.vivo else (xp_onda + 1) / 2
		if b.ganhar_xp(roundi(base * mults[i])) > 0:
			b.pop = 1.0

## Depois de vencer a onda: mortos saem, baú vai pro guarda-roupa, próxima onda.
## Devolve true se a onda vencida era a última da fase (fase vencida).
func encerrar_onda(sim: Simulacao) -> bool:
	_anotar_luta(sim)
	for b in bonecos:
		b.saude = Balanco.NOCAUTE_SAUDE  # quem caiu; os de pé são corrigidos logo abaixo
	for u in sim.aliados:
		if u.boneco != null and u.vida_max > 0.0:
			u.boneco.saude = clampf(u.vida / u.vida_max, 0.05, 1.0)
	dar_xp_onda()
	for b in bonecos:
		b.vivo = true  # nocaute só dura a onda
	for p in sim.bau:
		guardar_drop(p)
	if invasao:
		# invasão: nunca "vence"; anota o recorde e segue para a onda seguinte
		recordes[lugar()] = maxi(recordes[lugar()], onda_invasao)
		onda_invasao += 1
		onda = (onda_invasao - 1) % Balanco.ONDAS_TOTAIS + 1
		preparar_onda()
		conferir_metas()
		salvar()
		return false
	onda += 1
	var venceu_fase: bool = onda > Balanco.ONDAS_TOTAIS
	if venceu_fase:
		fases_vencidas = maxi(fases_vencidas, fase)
		vencido[fase - 1] = maxi(vencido[fase - 1], ato)
		fase_liberada = maxi(fase_liberada, mini(fase + 1, Fases.TOTAL))
		if nocautes_fase == 0:
			feitos["sem_nocaute_%d" % lugar()] = true
		var todos: bool = not bonecos.is_empty()
		for b in bonecos:
			var cont: Array[int] = Pecas.contar_conjuntos(b.pecas)
			var cheio: bool = false
			for n in cont:
				if n >= Pecas.SLOTS:
					cheio = true
			if not cheio:
				todos = false
		if todos:
			feitos["time_fantasiado"] = true
		recolher()
		_completar_time()
	else:
		preparar_onda()
	conferir_metas()
	salvar()
	return venceu_fase

## Depois de perder a fase: as roupas (com as marcas novas) e o que caiu ficam; o resto se perde.
func encerrar_derrota(sim: Simulacao) -> void:
	_anotar_luta(sim)
	estat["derrotas"] = int(estat.get("derrotas", 0)) + 1
	for p in sim.bau:
		guardar_drop(p)
	recolher()
	conferir_metas()
	salvar()

## Soma aos números da campanha o que aconteceu na luta que acabou.
func _anotar_luta(sim: Simulacao) -> void:
	var caidos: int = 0
	for b in bonecos:
		if not b.vivo:
			caidos += 1
	nocautes_fase += caidos
	estat["nocautes"] = int(estat.get("nocautes", 0)) + caidos
	estat["ondas"] = int(estat.get("ondas", 0)) + 1
	estat["tempo"] = float(estat.get("tempo", 0.0)) + sim.tempo

# ---------- Metas do fichário ----------
func todas_as_pecas() -> Array[Peca]:
	var l: Array[Peca] = []
	l.append_array(guarda)
	for b in bonecos:
		for p in b.pecas:
			if p != null:
				l.append(p)
	return l

func pecas_tidas() -> int:
	_garantir_colecao()
	var n: int = 0
	for t in colecao.size():
		if colecao[t] and not Pecas.retirada(Pecas.CONJUNTO_DE[t]):
			n += 1
	return n

## Paga (uma vez só) as metas que acabaram de ser cumpridas. Devolve os ids pagos agora;
## eles também ficam em `metas_novas` até a interface mostrá-los.
func conferir_metas() -> Array[String]:
	var agora: Array[String] = []
	for m in Metas.lista():
		var id: String = m["id"]
		if metas_pagas.has(id) or not Metas.cumprida(id, self):
			continue
		metas_pagas[id] = true
		trofeus += int(m["premio"])
		agora.append(id)
		metas_novas.append(id)
	return agora

func metas_cumpridas() -> int:
	return metas_pagas.size()

## Peça igual à que o jogador já tem (vestida, de preferência; senão a melhor do guarda-roupa), ou null.
func _igual_a(p: Peca) -> Peca:
	for b in bonecos:
		var v: Peca = b.pecas[p.slot()]
		if v != null and v != p and v.tipo == p.tipo:
			return v
	var melhor: Peca = null
	for q in guarda:
		if q != p and q.tipo == p.tipo and (melhor == null or valor(q) > valor(melhor)):
			melhor = q
	return melhor

## Peça que caiu na luta. Repetida não empilha: funde-se sozinha com a que o jogador já tem
## (que sobe de nível ou de raridade); se as duas já estão no máximo, vira um troféu.
func guardar_drop(p: Peca) -> void:
	p.nova = true
	registrar(p.tipo)
	var igual: Peca = _igual_a(p)
	if igual == null:
		guarda.append(p)
		return
	if pode_fundir(igual, p):
		fundir(igual, p)
		fundida_em[p] = igual
	else:
		trofeus += 1
		fundida_em[p] = igual

## Gravação de antes da fusão automática: junta as repetidas paradas no guarda-roupa (as vestidas ficam como estão).
func _juntar_repetidas() -> void:
	var mudou: bool = true
	while mudou:
		mudou = false
		for q in guarda.duplicate():
			if not guarda.has(q):
				continue
			var igual: Peca = _igual_a(q)
			if igual != null and pode_fundir(igual, q):
				var nova_antes: bool = igual.nova
				var era_persistir: bool = persistir
				persistir = false   # uma gravação só, no fim
				fundir(igual, q)
				persistir = era_persistir
				igual.nova = nova_antes
				mudou = true

## Quanto uma peça vale na hora de decidir qual sobra: raridade, depois nível, depois marcas.
static func valor(p: Peca) -> int:
	return p.raridade * 100 + p.nivel * 10 + p.marcas.size()

func campanha_vencida() -> bool:
	return fases_vencidas >= Fases.TOTAL

# ---------- Gravação ----------
## O cômodo começado (vazio se não há): o bastante para voltar ao guarda-roupa da mesma onda.
func _dados_curso() -> Dictionary:
	if not em_curso:
		return {}
	var saudes: Array = []
	for b in bonecos:
		saudes.append(b.saude)
	return {"fase": fase, "ato": ato, "invasao": invasao, "onda": onda, "onda_invasao": onda_invasao, "tijolos": tijolos, "nocautes": nocautes_fase, "saudes": saudes}

func _carregar_curso(c: Variant) -> void:
	em_curso = false
	if typeof(c) != TYPE_DICTIONARY or not (c as Dictionary).has("fase"):
		return
	var d: Dictionary = c
	fase = clampi(int(d.get("fase", 1)), 1, Fases.TOTAL)
	ato = clampi(int(d.get("ato", 1)), 1, Balanco.ATOS)
	invasao = bool(d.get("invasao", false))
	onda = clampi(int(d.get("onda", 1)), 1, Balanco.ONDAS_TOTAIS)
	onda_invasao = maxi(0, int(d.get("onda_invasao", 0)))
	tijolos = clampi(int(d.get("tijolos", tijolos_max())), 1, tijolos_max())
	nocautes_fase = maxi(0, int(d.get("nocautes", 0)))
	var ss: Variant = d.get("saudes", [])
	if ss is Array:
		for i in mini((ss as Array).size(), bonecos.size()):
			bonecos[i].saude = clampf(float(ss[i]), 0.05, 1.0)
			bonecos[i].vivo = true
	em_curso = true
	_pesos_validos = false
	preparar_onda()

## Gravação adiada: várias ações no mesmo quadro (vestir o time, promover tudo...) viram uma gravação só, feita no
## início do quadro seguinte, em vez de uma escrita em disco por peça no meio do clique.
static var _pendente: Estado = null

func salvar() -> void:
	if not persistir:
		return
	var ml: MainLoop = Engine.get_main_loop()
	if not (ml is SceneTree):
		_gravar()
		return
	if _pendente == self:
		return
	gravar_pendente()   # outro estado (outra sessão) ainda esperava: grava antes de trocar
	_pendente = self
	(ml as SceneTree).process_frame.connect(gravar_pendente, CONNECT_ONE_SHOT)

## Grava agora o que ficou esperando (ao fechar o jogo, antes de ler o arquivo e no quadro seguinte).
static func gravar_pendente() -> void:
	var e: Estado = _pendente
	_pendente = null
	if e != null:
		e._gravar()

## Esquece a gravação esperando (o arquivo está sendo apagado).
func cancelar_gravacao() -> void:
	if _pendente == self:
		_pendente = null

func _gravar() -> void:
	if not persistir:
		return
	var pecas: Array = []
	for p in guarda:
		pecas.append(p.para_dados())
	var time: Array = []
	for b in bonecos:
		time.append(b.para_dados())
	var arq := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if arq != null:
		arq.store_string(JSON.stringify({"versao": 3, "fase_liberada": fase_liberada, "fases_vencidas": fases_vencidas, "vencido": vencido.duplicate(), "curso": _dados_curso(), "pecas": pecas, "bonecos": time, "trofeus": trofeus, "melhorias": melhorias.duplicate(), "modulos": modulos.duplicate(), "colecao": colecao.duplicate(), "bichos": bichos_vistos.keys(), "recordes": recordes.duplicate(), "estat": estat.duplicate(), "feitos": feitos.keys(), "metas_pagas": metas_pagas.keys()}))

## Gravação de antes da versão 3 (3 raridades): a Lendária era o índice 2 e agora é o 3 (o 2 virou Épica).
## Sem isto, toda Lendária gravada viraria Épica.
func _migrar_raridades(dados: Dictionary) -> void:
	if int(dados.get("versao", 1)) >= 3:
		return
	var listas: Array = [dados.get("pecas", [])]
	for bd in dados.get("bonecos", []):
		if typeof(bd) == TYPE_DICTIONARY:
			listas.append(bd.get("pecas", []))
	for l in listas:
		if l is Array:
			for pd in l:
				if typeof(pd) == TYPE_DICTIONARY and int(pd.get("raridade", 0)) >= 2:
					pd["raridade"] = int(pd["raridade"]) + 1

## Carrega a campanha gravada. Devolve false se não há gravação válida.
## Fantasias retiradas do jogo (Pecas.RETIRADAS): as peças delas viram a peça do mesmo espaço de outra fantasia do Quintal, com a mesma
## raridade e nível, e as heranças delas somem. Roda ao carregar o save.
func _converter_retiradas() -> void:
	var alvos: Array[int] = []
	for c in Fases.lista_do_lugar(Fases.TOTAL):
		if not Pecas.retirada(c):
			alvos.append(c)
	if alvos.is_empty():
		return
	var k: int = 0
	var listas: Array = [guarda]
	for b in bonecos:
		listas.append(b.pecas)
	for l in listas:
		for p in l:
			if p != null and Pecas.retirada(p.conjunto()):
				p.tipo = Pecas.CONJUNTO_PECAS[alvos[k % alvos.size()]][p.slot()]
				k += 1
	for b in bonecos:
		for i in range(b.herancas.size() - 1, -1, -1):
			if Pecas.retirada(b.herancas[i]):
				b.herancas.remove_at(i)
				if i < b.graus.size():
					b.graus.remove_at(i)

func carregar() -> bool:
	gravar_pendente()
	if not FileAccess.file_exists(ARQUIVO):
		return false
	var dados: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
	if typeof(dados) != TYPE_DICTIONARY or not dados.has("pecas"):
		return false
	_migrar_raridades(dados)
	fase_liberada = clampi(int(dados.get("fase_liberada", 1)), 1, Fases.TOTAL)
	fases_vencidas = clampi(int(dados.get("fases_vencidas", 0)), 0, Fases.TOTAL)
	ato = 1
	vencido = [0, 0, 0, 0, 0]
	for i in fases_vencidas:
		vencido[i] = 1   # gravação de antes dos atos: o que foi vencido conta para o primeiro
	var vd: Variant = dados.get("vencido", [])
	if vd is Array:
		for i in mini((vd as Array).size(), vencido.size()):
			vencido[i] = clampi(maxi(vencido[i], int(vd[i])), 0, Balanco.ATOS)
	bonecos.clear()
	guarda.clear()
	for d in dados["pecas"]:
		if typeof(d) == TYPE_DICTIONARY and int(d.get("tipo", -1)) >= 0 and int(d.get("tipo", -1)) < Pecas.SLOT.size():
			guarda.append(Peca.de_dados(d))
	for d in dados.get("bonecos", []):
		if typeof(d) == TYPE_DICTIONARY and bonecos.size() < Balanco.MAX_BONECOS:
			bonecos.append(Boneco.de_dados(d))
	_converter_retiradas()
	trofeus = maxi(0, int(dados.get("trofeus", 0)))
	melhorias = [0, 0, 0, 0]
	var ml: Array = dados.get("melhorias", [])
	for i in mini(4, ml.size()):
		melhorias[i] = clampi(int(ml[i]), 0, Torre.MELHORIA_NIVEL_MAX)
	modulos.clear()
	for m in dados.get("modulos", []):
		if int(m) >= 0 and int(m) < Torre.MODULO_NOME.size() and modulo_liberado(int(m)) and modulos.size() < vagas_modulos() and not (int(m) in modulos):
			modulos.append(int(m))
	_completar_time()  # gravação antiga (sem time) ou time incompleto
	recordes = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var rc: Array = dados.get("recordes", [])
	for i in mini(rc.size(), recordes.size()):
		recordes[i] = maxi(0, int(rc[i]))
	estat = {"ondas": 0, "nocautes": 0, "abates": 0, "tempo": 0.0, "derrotas": 0}
	var es: Variant = dados.get("estat", {})
	if typeof(es) == TYPE_DICTIONARY:
		for k in es:
			estat[str(k)] = es[k]
	feitos.clear()
	for k in dados.get("feitos", []):
		feitos[str(k)] = true
	metas_pagas.clear()
	for k in dados.get("metas_pagas", []):
		metas_pagas[str(k)] = true
	metas_novas.clear()
	invasao = false
	_juntar_repetidas()
	_carregar_curso(dados.get("curso", {}))
	onda_invasao = 0
	colecao.clear()
	_garantir_colecao()
	var cl: Array = dados.get("colecao", [])
	for i in mini(cl.size(), colecao.size()):
		colecao[i] = bool(cl[i])
	_registrar_tudo()
	if dados.has("bichos"):
		bichos_vistos.clear()
		for k in dados["bichos"]:
			bichos_vistos[str(k)] = true
	else:
		_inferir_bichos()
	if em_curso:
		_ver_onda()
	return true
