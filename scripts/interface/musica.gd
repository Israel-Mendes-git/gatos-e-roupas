class_name Musica
extends RefCounted
## Trilha sonora: uma faixa por tela ou estado, trocada com um crossfade curto. Os arquivos ficam em
## res://assets/musica/<nome>.wav (compostos e sintetizados para o jogo por ferramentas/gera_musica.py; nada de terceiros).
## O principal chama Musica.atualizar(self, delta) todo quadro; a faixa certa sai de faixa_para(), que só lê o estado.
## Sem áudio em headless e nos testes (como o Som), mas a escolha da faixa roda igual e pode ser conferida.

## Volume da música (0 a 1), separado dos efeitos; Menus grava e carrega. Padrão abaixo dos efeitos.
static var volume: float = 0.5

const BASE_DB := -7.0          # a trilha fica por baixo dos efeitos mesmo com os dois volumes iguais
const TROCA := 1.2             # s do crossfade entre faixas
const TROCA_JINGLE := 0.35     # s para a faixa anterior sumir quando entra um jingle
const VOLTA_JINGLE := 2.5      # s para a faixa calma voltar depois de um jingle
## Jingles tocam uma vez; ao terminar, entra a faixa indicada.
const JINGLES := {"vitoria": "calma", "derrota": "calma"}
const ABAFA_PREP := 0.5        # na preparação da onda a luta toca baixinho e cresce quando a onda começa
const ABAFA_DESFECHO := 0.3    # a luta acabou: a música recua para o som da vitória ou da derrota aparecer
const ABAFA_PAUSA := 0.6

static var _toc: Array[AudioStreamPlayer] = []
static var _ganho: Array[float] = [0.0, 0.0]
static var _alvo: Array[float] = [0.0, 0.0]
static var _dur: Array[float] = [TROCA, TROCA]
static var _nome: Array[String] = ["", ""]
static var _ativo: int = 0
static var _pedida: String = ""
static var _abafa: float = 1.0
static var _fluxos: Dictionary = {}
static var _faltando: Dictionary = {}
# memória do que já aconteceu na tela atual
static var _modo_ant: int = -1
static var _chefe_visto: bool = false   # o chefe desta onda já entrou em campo (a luta vira música de chefe)
static var _jingle_fim: String = ""     # jingle do painel de fim em exibição
static var _jingle_feito: bool = false  # ... já tocou (fechar a tela de final por cima não o repete)

## Cria os dois tocadores (o crossfade usa um para a faixa que sai e outro para a que entra).
static func iniciar(pai: Node) -> void:
	_toc.clear()
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		pai.add_child(p)
		_toc.append(p)
	_ganho = [0.0, 0.0]
	_alvo = [0.0, 0.0]
	_nome = ["", ""]
	_pedida = ""

## Faixa pedida agora (para os testes conferirem a escolha).
static func pedida() -> String:
	return _pedida

## Chamado todo quadro pelo principal (`p`): escolhe a faixa, faz as trocas e os volumes.
static func atualizar(p: Node, delta: float) -> void:
	_observar(p)
	var f: String = faixa_para(p)
	if f != _pedida:
		var nome_at: String = _nome[_ativo]
		var jingle_tocando: bool = JINGLES.has(nome_at) and _tocando(_ativo)
		_pedida = f
		if JINGLES.has(f):
			_jingle_feito = true
		# o jingle não é cortado pela faixa que viria depois dele de qualquer jeito
		if not (jingle_tocando and JINGLES[nome_at] == f):
			_trocar(f, TROCA_JINGLE if JINGLES.has(f) else TROCA)
	if _toc.is_empty():
		return
	# jingle terminou: entra a faixa seguinte, devagar
	var na: String = _nome[_ativo]
	if JINGLES.has(na) and not _tocando(_ativo):
		_trocar(_pedida if not JINGLES.has(_pedida) else String(JINGLES[na]), VOLTA_JINGLE)
	var abafa_alvo: float = _abafa_para(p)
	_abafa = move_toward(_abafa, abafa_alvo, delta / 0.6)
	var mudo: bool = Som.mudo or volume <= 0.001
	for i in 2:
		var tp: AudioStreamPlayer = _toc[i]
		if not is_instance_valid(tp):
			continue
		_ganho[i] = move_toward(_ganho[i], _alvo[i], delta / maxf(0.05, _dur[i]))
		if _ganho[i] <= 0.0 and _alvo[i] <= 0.0:
			if tp.playing:
				tp.stop()
			continue
		var g: float = _ganho[i] * clampf(volume, 0.0, 1.0) * (_abafa if not JINGLES.has(_nome[i]) else 1.0)
		tp.volume_db = -80.0 if mudo else linear_to_db(maxf(g, 0.0001)) + BASE_DB

## A faixa que combina com o que está na tela. Só lê o estado (a memória de chefe e jingle vem de _observar).
static func faixa_para(p: Node) -> String:
	var mn: Menus = p.menus
	if mn != null:
		if mn.tela == Menus.Tela.FINAL:
			return "final"
		if (mn.tela == Menus.Tela.CREDITOS or mn.tela == Menus.Tela.OPCOES) and mn.tela_volta == Menus.Tela.FINAL:
			return "final"
	var m: int = int(p.modo)
	if m == p.Modo.TITULO:
		return "titulo"
	if m == p.Modo.COMBATE:
		var e: Estado = p.estado
		if e.secreto:
			return "schro"
		if _chefe_visto:
			return "chefe"
		return "luta%d" % clampi(e.ato, 1, 3)
	if m == p.Modo.FIM:
		if _jingle_fim != "" and not _jingle_feito:
			return _jingle_fim
		return "calma"
	return "calma"   # mapa e guarda-roupa (com fichário, oficina e ateliê por cima)

static func _observar(p: Node) -> void:
	var m: int = int(p.modo)
	if m != _modo_ant:
		_modo_ant = m
		_chefe_visto = false
		if m == p.Modo.FIM:
			_jingle_fim = "vitoria" if bool(p.fim_vitoria) else "derrota"
			_jingle_feito = false
	if p.menus != null and p.menus.tela == Menus.Tela.FINAL:
		_jingle_feito = true   # a tela de final abriu por cima do fim: o jingle não toca atrasado depois
	if m == p.Modo.COMBATE and p.campo != null:
		if p.campo.prep:
			_chefe_visto = false
		elif float(p.campo.chefe_t) > 0.0 and not p.estado.secreto:
			_chefe_visto = true   # o chefe entrou: a música muda até o fim da luta

static func _abafa_para(p: Node) -> float:
	var a: float = 1.0
	if int(p.modo) == p.Modo.COMBATE and p.campo != null:
		if p.campo.prep:
			a = ABAFA_PREP
		elif p.campo.fim_tratado:
			a = ABAFA_DESFECHO
	if p.menus != null and p.menus.tela == Menus.Tela.PAUSA:
		a = minf(a, ABAFA_PAUSA)
	return a

static func _tocando(i: int) -> bool:
	return i < _toc.size() and is_instance_valid(_toc[i]) and _toc[i].playing

## Troca para `nome` em `dur` segundos: a faixa atual some num tocador enquanto a nova cresce no outro.
static func _trocar(nome: String, dur: float) -> void:
	if _toc.is_empty():
		return
	if nome == _nome[_ativo] and _tocando(_ativo):
		_alvo[_ativo] = 1.0
		_dur[_ativo] = dur
		return
	_alvo[_ativo] = 0.0
	_dur[_ativo] = dur
	var o: int = 1 - _ativo
	_ativo = o
	_nome[o] = nome
	var fluxo: AudioStream = _fluxo(nome)
	var tp: AudioStreamPlayer = _toc[o]
	if fluxo == null or not is_instance_valid(tp) or not tp.is_inside_tree():
		_nome[o] = ""
		return
	tp.stop()
	tp.stream = fluxo
	_ganho[o] = 1.0 if JINGLES.has(nome) else 0.0   # jingle entra inteiro; faixa em loop cresce
	_alvo[o] = 1.0
	_dur[o] = dur
	tp.volume_db = -80.0
	tp.play()

static func _fluxo(nome: String) -> AudioStream:
	if _fluxos.has(nome):
		return _fluxos[nome]
	if _faltando.has(nome):
		return null
	var caminho: String = "res://assets/musica/%s.wav" % nome
	if not ResourceLoader.exists(caminho):
		_faltando[nome] = true
		push_warning("Musica: não existe a faixa '%s'" % nome)
		return null
	var s: AudioStream = load(caminho)
	if s is AudioStreamWAV and not JINGLES.has(nome) and (s as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED:
		push_warning("Musica: a faixa '%s' veio sem loop no .import (rode gera_musica.py e reimporte)" % nome)
	_fluxos[nome] = s
	return s
