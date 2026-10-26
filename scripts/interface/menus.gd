class_name Menus
extends Control
## Camada de menus por cima da tela principal: título, pausa, opções, créditos,
## confirmações, cortina de transição e dicas de primeira vez.
## Tudo é desenhado por código, com as molduras do pacote "Cryo's Mini GUI" que o
## `principal.gd` já usa. O dono (`principal.gd`) recebe as ações por métodos públicos.

enum Tela { NENHUMA, TITULO, PAUSA, OPCOES, CREDITOS, CONFIRMA, FINAL }

const TITULO_JOGO := "Gatos e Roupas"
const AUTOR_JOGO := "Israel"
const DURACAO_TRANSICAO := 0.25

# ---- opções (lidas por `campo.gd` e por quem mais precisar) ----
## Tremor de tela ligado. `campo.gd` deve consultar `Menus.tremor_tela` antes de sacudir a tela.
static var tremor_tela: bool = true
## Números de dano ligados. `campo.gd` deve consultar `Menus.numeros_dano` antes de criar os números flutuantes.
static var numeros_dano: bool = true
## true: os poderes de fantasia dos gatos disparam sozinhos; false (padrão): o jogador dispara na luta.
static var poder_automatico: bool = false
static var preparacao_onda: bool = true   # desligada: a onda começa direto, com os postos e ordens gravados
## Altura de cada linha da tela de Opções (a do "Poder automático" é mais alta: tem três linhas de explicação).
const OPC_Y: Array[float] = [0.0, 44.0, 88.0, 132.0, 176.0, 220.0, 264.0, 308.0, 352.0, 420.0, 464.0]   # idioma, tela, velocidade, som, efeitos, música, tremor, dano, poderes, preparação, campanha
const OPC_TOPO := 92.0   # da borda do painel até a primeira linha
const OPC_H := 42.0      # altura dos botões de cada linha
static var tela_cheia: bool = false
static var velocidade_padrao: int = 1
static var dicas_vistas: Dictionary = {}
## A tela de final já foi mostrada nesta campanha (guardado em interface.cfg, seção "ui").
static var final_visto: bool = false
## Quantos atos existiam quando o jogador viu a tela de final (ato novo = final de novo ao vencê-lo).
static var final_atos: int = 0
## Arquivo de configuração (os testes apontam para outro caminho para não tocar no real).
static var cfg_caminho: String = "user://interface.cfg"
## Quando falso, nada é gravado em disco (testes).
static var gravar: bool = true
## Quando verdadeiro, o jogo abre direto no mapa (scripts de teste antigos).
static var pular_titulo: bool = false
## Quando falso, as trocas de tela são imediatas (sem cortina).
static var transicoes: bool = true

const GUI_TEX: Texture2D = preload("res://assets/terceiros/gui/gui_4x.png")
const BOT_TEX: Texture2D = preload("res://assets/terceiros/gui/botoes_4x.png")
const R_MADEIRA := Rect2(8, 136, 80, 80)
const M_MADEIRA := Vector4(28, 28, 28, 28)
const R_BT_N := Rect2(132, 4, 88, 56)
const R_BT_P := Rect2(228, 8, 88, 52)
const M_BT := Vector4(16, 16, 16, 16)
const COR_TINTA := Color(1.0, 0.94, 0.8)
const COR_FUNDO_PAINEL := Color(0.14, 0.09, 0.12, 0.98)

var dono: Variant = null
var tela: Tela = Tela.NENHUMA
var tela_volta: Tela = Tela.TITULO   # para onde Opções/Créditos voltam
var tem_save: bool = false
var botoes: Array[Dictionary] = []
var foco: int = 0
var apertado: int = -1
var t: float = 0.0
var conf: Dictionary = {}
var rolagem_cred: float = 0.0
var rolagem_manual: bool = false
var painel: Rect2 = Rect2()
var area_cred: Rect2 = Rect2()
var cred_altura: float = 0.0
var pausa_em_combate: bool = false
# transição
var tr_t: float = -1.0
var tr_acao: Callable = Callable()
var tr_feita: bool = false
# dicas
var fila_dicas: Array[Dictionary] = []
var dica_atual: Dictionary = {}
var dica_t: float = 0.0
# avisos de meta cumprida (um por vez, em sequência)
var fila_metas: Array[Dictionary] = []
var meta_atual: Dictionary = {}
var meta_t: float = 0.0
const META_DURACAO := 3.6
# juice
var anim: Dictionary = {}           # animação de cada botão (hover/apertado)
var tela_t: float = 0.0             # segundos desde que a tela atual foi montada (salto do painel, cascata)
var faiscas := UIComum.Faiscas.new()
var _foco_som: int = -1             # último botão em foco que já tocou o "hover"
var _tela_som: int = -1
var pulo_gato: Array[float] = []    # tempo de cada gato do título no pulinho de reação (-1 = parado)
var acorda_t: float = 0.0           # o gato da pausa acordando depois que o painel fecha
var acorda_x: float = 640.0
var acorda_y: float = 300.0
var espera_dica: float = 0.0        # folga antes de mostrar uma dica (depois de trocar de tela)
var _modo_ant: int = -99
var fim_t: float = 0.0
var meta_burst: bool = false
var entrando: bool = false   # a cortina atual é a entrada num cômodo (o mapa anima a porta)

# ------------------------------------------------------------------ opções em disco
static func carregar_opcoes() -> void:
	var cfg := ConfigFile.new()
	var tem_cfg: bool = cfg.load(cfg_caminho) == OK
	# idioma: o gravado; na primeira execução, o do sistema (os testes, que não gravam, ficam em português)
	if tem_cfg and cfg.has_section_key("opcoes", "idioma"):
		Idioma.definir(str(cfg.get_value("opcoes", "idioma", Idioma.PADRAO)))
	elif gravar:
		Idioma.definir(Idioma.detectar())
	if not tem_cfg:
		return
	tremor_tela = bool(cfg.get_value("opcoes", "tremor", true))
	numeros_dano = bool(cfg.get_value("opcoes", "numeros_dano", true))
	tela_cheia = bool(cfg.get_value("opcoes", "tela_cheia", false))
	poder_automatico = bool(cfg.get_value("opcoes", "poder_automatico", false))
	preparacao_onda = bool(cfg.get_value("opcoes", "preparacao", true))
	Som.volume = clampf(snappedf(float(cfg.get_value("opcoes", "volume", 0.7)), 0.1), 0.0, 1.0)
	Som.mudo = not bool(cfg.get_value("opcoes", "som", true))
	Musica.volume = clampf(snappedf(float(cfg.get_value("opcoes", "musica", 0.5)), 0.1), 0.0, 1.0)
	velocidade_padrao = clampi(int(cfg.get_value("opcoes", "velocidade", 1)), 1, 3)
	final_visto = bool(cfg.get_value("ui", "final_visto", false))
	final_atos = int(cfg.get_value("ui", "final_atos", 0))
	dicas_vistas.clear()
	if cfg.has_section("dicas"):
		for k in cfg.get_section_keys("dicas"):
			dicas_vistas[k] = bool(cfg.get_value("dicas", k, false))

static func gravar_opcoes() -> void:
	if not gravar:
		return
	var cfg := ConfigFile.new()
	cfg.load(cfg_caminho)   # preserva as outras chaves (ex.: "ui")
	cfg.set_value("opcoes", "idioma", Idioma.atual)
	cfg.set_value("opcoes", "tremor", tremor_tela)
	cfg.set_value("opcoes", "numeros_dano", numeros_dano)
	cfg.set_value("opcoes", "tela_cheia", tela_cheia)
	cfg.set_value("opcoes", "poder_automatico", poder_automatico)
	cfg.set_value("opcoes", "preparacao", preparacao_onda)
	cfg.set_value("opcoes", "volume", Som.volume)
	cfg.set_value("opcoes", "som", not Som.mudo)
	cfg.set_value("opcoes", "musica", Musica.volume)
	cfg.set_value("opcoes", "velocidade", velocidade_padrao)
	cfg.set_value("ui", "final_visto", final_visto)
	cfg.set_value("ui", "final_atos", final_atos)
	for k in dicas_vistas:
		cfg.set_value("dicas", k, dicas_vistas[k])
	cfg.save(cfg_caminho)

static func aplicar_janela() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if tela_cheia else DisplayServer.WINDOW_MODE_WINDOWED)

# ------------------------------------------------------------------ registro de entrada (diagnóstico)
## Com true, cada clique, tecla de menu e troca de tela é anotado em user://registro_menu.log,
## para achar defeitos de menu que só aparecem com o mouse de verdade. Só liga fora do build de lançamento.
var tr_fila: Callable = Callable()   # troca de tela pedida enquanto outra cortina rodava
static var registrar_entrada: bool = OS.is_debug_build()
static var _reg_arq: FileAccess = null
static var _reg_linhas: int = 0

static func reg(txt: String) -> void:
	if not registrar_entrada or not gravar:
		return
	if _reg_arq == null:
		_reg_arq = FileAccess.open("user://registro_menu.log", FileAccess.WRITE)
		if _reg_arq == null:
			registrar_entrada = false
			return
		_reg_arq.store_line("registro iniciado em " + Time.get_datetime_string_from_system())
	if _reg_linhas > 20000:
		return
	_reg_linhas += 1
	_reg_arq.store_line("%8.2f  %s" % [Time.get_ticks_msec() / 1000.0, txt])
	_reg_arq.flush()

func _estado_txt() -> String:
	return "tela=%s cortina=%.2f filtro=%d modo=%s" % [Tela.keys()[tela], tr_t, mouse_filter, str(dono.modo) if dono != null else "?"]

# ------------------------------------------------------------------ ciclo
func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE

func iniciar(d: Variant) -> void:
	dono = d
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

var _tela_desenhada: int = -1   # tela do último redesenho pedido (ver o fim de _process)

func _process(delta: float) -> void:
	t += delta
	tela_t += delta
	_juice(delta)
	if tr_t >= 0.0:
		tr_t += minf(delta, 1.0 / 30.0) / DURACAO_TRANSICAO   # um quadro lento (a troca de tela pesa) não pode pular a abertura
		if tr_t >= 0.5 and not tr_feita:
			tr_feita = true
			if tr_acao.is_valid():
				tr_acao.call()
		if tr_t >= 1.0:
			tr_t = -1.0
			queue_redraw()   # sem isto, o último quadro desenhado da cortina ficava na tela até outra coisa pedir redesenho
			reg("cortina terminou; " + _estado_txt())
			if tr_fila.is_valid():
				# uma troca de tela pedida durante a cortina não se perde: roda em seguida
				var prox: Callable = tr_fila
				tr_fila = Callable()
				ir(prox)
	# regra única, conferida todo quadro: o menu só segura o mouse com uma tela aberta ou durante a cortina
	var quer: int = Control.MOUSE_FILTER_STOP if (tela != Tela.NENHUMA or tr_t >= 0.0) else Control.MOUSE_FILTER_IGNORE
	if mouse_filter != quer:
		reg("filtro do mouse corrigido de %d para %d; %s" % [mouse_filter, quer, _estado_txt()])
		mouse_filter = quer
	if tela == Tela.CREDITOS:
		var maxr: float = maxf(0.0, cred_altura - area_cred.size.y)
		if not rolagem_manual:
			rolagem_cred = minf(maxr, rolagem_cred + 28.0 * delta)
	_tocar_dicas(delta)
	_tocar_metas(delta)
	# redesenha também no quadro em que a tela muda: sem isto, fechar uma caixa (ex.: confirmar a herança) deixava a imagem
	# dela congelada por cima do jogo, que parecia travado
	if tela != Tela.NENHUMA or tr_t >= 0.0 or not dica_atual.is_empty() or not meta_atual.is_empty() or acorda_t > 0.0 or not faiscas.vazio() or int(tela) != _tela_desenhada:
		_tela_desenhada = int(tela)
		queue_redraw()

## Animação dos botões, sons de foco, pulinhos dos gatos do título, faíscas.
func _juice(delta: float) -> void:
	for i in botoes.size():
		var sobre: bool = tela != Tela.NENHUMA and botoes[i]["on"] and i == foco
		UIComum.anim_passo(anim, _ak(i), sobre, sobre and i == apertado, delta)
	if tela != Tela.NENHUMA and tr_t < 0.0:
		if foco != _foco_som or int(tela) != _tela_som:
			if _tela_som == int(tela) and foco >= 0 and foco < botoes.size() and botoes[foco]["on"]:
				UIComum.som_hover()
				if tela == Tela.TITULO:
					_gato_reage(foco)
			_foco_som = foco
			_tela_som = int(tela)
	else:
		_foco_som = -1
		_tela_som = -1
	for k in pulo_gato.size():
		if pulo_gato[k] > -0.5:
			pulo_gato[k] += delta
			if pulo_gato[k] > 0.4:
				pulo_gato[k] = -1.0
	acorda_t = maxf(0.0, acorda_t - delta)
	espera_dica = maxf(0.0, espera_dica - delta)
	faiscas.passo(delta)
	if dono != null:
		var md: int = int(dono.modo)
		if md != _modo_ant:
			_modo_ant = md
			espera_dica = 1.1   # a tela nova se assenta antes de qualquer dica aparecer

func _ak(i: int) -> String:
	return "%d_%s" % [i, str(botoes[i]["id"]) if i < botoes.size() else ""]

## Um gato do título dá um pulinho quando o botão de `i` ganha o foco.
func _gato_reage(i: int) -> void:
	if dono == null or dono.estado.bonecos.is_empty():
		return
	var n: int = dono.estado.bonecos.size()
	if pulo_gato.size() != n:
		pulo_gato.resize(n)
		pulo_gato.fill(-1.0)
	pulo_gato[posmod(i * 2 + 1, n)] = 0.0
	if n > 2:
		pulo_gato[posmod(i * 2 + 2, n)] = -0.1

func ativo() -> bool:
	return tela != Tela.NENHUMA

func em_transicao() -> bool:
	return tr_t >= 0.0

## Faz a cortina fechar, executa `acao` no meio e abre de novo (0,25 s no total).
func ir(acao: Callable) -> void:
	if not transicoes:
		acao.call()
		return
	if tr_t >= 0.0:
		# já há uma cortina: guarda o pedido para logo depois, em vez de descartá-lo
		reg("ir() durante a cortina: pedido guardado na fila; " + _estado_txt())
		tr_fila = acao
		return
	reg("ir(): cortina começa; " + _estado_txt())
	Som.tocar("cortina")
	entrando = acao.get_method() in [&"_escolher_fase", &"_escolher_invasao"]
	tr_t = 0.0
	tr_feita = false
	tr_acao = acao
	mouse_filter = Control.MOUSE_FILTER_STOP   # a cortina engole os cliques até acabar

# ------------------------------------------------------------------ abrir e fechar
func mostrar_titulo(com_save: bool) -> void:
	reg("mostrar_titulo(com_save=%s); %s" % [str(com_save), _estado_txt()])
	tem_save = com_save
	tela = Tela.TITULO
	tela_volta = Tela.TITULO
	_ativar()
	foco = 0
	_montar()

## Abre a tela de final (cena de encerramento). Marca no cfg que já foi mostrada.
func mostrar_final() -> void:
	if tela != Tela.NENHUMA:
		return
	reg("mostrar_final(); " + _estado_txt())
	final_visto = true
	gravar_opcoes()
	Som.tocar("final")
	fim_t = 0.0
	tela = Tela.FINAL
	tela_volta = Tela.FINAL
	_ativar()
	foco = 0
	_montar()

func abrir_pausa() -> void:
	if tela != Tela.NENHUMA or tr_t >= 0.0:
		reg("abrir_pausa() recusada; " + _estado_txt())
		return   # nada de pausa durante a cortina: ela ficaria por cima da tela seguinte
	reg("abrir_pausa(); " + _estado_txt())
	dono.fusao = {}   # a confirmação de fusão não sobrevive à pausa
	pausa_em_combate = dono.modo == dono.Modo.COMBATE
	if pausa_em_combate:
		dono.campo.process_mode = Node.PROCESS_MODE_DISABLED
	dono.arrasto = {}
	Som.tocar("abrir")
	acorda_t = 0.0
	tela = Tela.PAUSA
	tela_volta = Tela.PAUSA
	_ativar()
	foco = 0
	_montar()

func fechar_tudo() -> void:
	reg("fechar_tudo(); " + _estado_txt())
	if tela == Tela.PAUSA:
		acorda_t = 0.55   # o gato dorminhoco acorda e salta quando a pausa fecha
		acorda_x = painel.position.x + painel.size.x * 0.5
		acorda_y = painel.position.y - 93.0
		Som.tocar("fechar")
	elif tela != Tela.NENHUMA and tela != Tela.TITULO and tela != Tela.FINAL:
		Som.tocar("fechar")
	if dono != null and dono.campo != null:
		dono.campo.process_mode = Node.PROCESS_MODE_INHERIT
	tela = Tela.NENHUMA
	conf = {}
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	botoes.clear()

func _ativar() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	apertado = -1
	conf = {}

func _ir_tela(nova: Tela) -> void:
	tela = nova
	foco = 0
	apertado = -1
	if nova == Tela.CREDITOS:
		rolagem_cred = 0.0
		rolagem_manual = false
	_montar()

func _voltar_de_sub() -> void:
	_ir_tela(tela_volta)

# ------------------------------------------------------------------ montagem dos botões
func _bt(id: String, txt: String, r: Rect2, cor: Color, tam: int = 22, extra: Dictionary = {}) -> void:
	var d: Dictionary = {"id": id, "txt": txt, "r": r, "cor": cor, "tam": tam, "on": true}
	d.merge(extra, true)
	botoes.append(d)

func _montar() -> void:
	botoes.clear()
	queue_redraw()
	tela_t = 0.0
	match tela:
		Tela.TITULO:
			# seis botões cabem acima do tapete (que começa em y ~ 590): os comuns ficam mais baixos
			var y: float = 210.0 if tem_save else 236.0
			var x: float = 490.0
			if tem_save:
				_bt("continuar", Idioma.t("Continuar"), Rect2(x, y, 300, 68), B_VERDE, 26, {"sub": _resumo_save()})
				y += 78.0
			_bt("nova", Idioma.t("Nova campanha"), Rect2(x, y, 300, 46), B_LARANJA)
			y += 54.0
			_bt("tutorial", Idioma.t("Tutorial"), Rect2(x, y, 300, 46), B_OURO)
			y += 54.0
			_bt("opcoes", Idioma.t("Opções"), Rect2(x, y, 300, 46), B_AZUL)
			y += 54.0
			_bt("creditos", Idioma.t("Créditos"), Rect2(x, y, 300, 46), B_MARROM)
			y += 54.0
			_bt("sair", Idioma.t("Sair"), Rect2(x, y, 300, 46), B_VERMELHO)
		Tela.PAUSA:
			var itens: Array = [["p_continuar", Idioma.t("Continuar"), B_VERDE], ["opcoes", Idioma.t("Opções"), B_AZUL]]
			if dono.modo != dono.Modo.MAPA:
				itens.append(["p_mapa", Idioma.t("Voltar ao mapa"), B_LARANJA])
			itens.append(["p_menu", Idioma.t("Menu principal"), B_VERMELHO])
			var h: float = 128.0 + itens.size() * 62.0
			painel = Rect2(450, roundf((720.0 - h) * 0.5) + 40.0, 380, h)
			for k in itens.size():
				_bt(itens[k][0], itens[k][1], Rect2(490, painel.position.y + 88.0 + k * 62.0, 300, 52), itens[k][2])
		Tela.OPCOES:
			painel = Rect2(290, 14, 700, 692)
			var xr: float = painel.end.x - 48.0
			var y0: float = painel.position.y + OPC_TOPO
			var h: float = OPC_H
			var lig_som: bool = not Som.mudo
			_bt("o_idioma", Idioma.nome_atual(), Rect2(xr - 230, y0 + OPC_Y[0], 230, h), B_ROSA_IDIOMA)
			_bt("o_tela", Idioma.t("Tela cheia") if tela_cheia else Idioma.t("Janela"), Rect2(xr - 230, y0 + OPC_Y[1], 230, h), B_AZUL)
			for k in 3:
				_bt("o_v%d" % (k + 1), "%dx" % (k + 1), Rect2(xr - 230 + k * 80, y0 + OPC_Y[2], 70, h), B_OURO if velocidade_padrao == k + 1 else B_CINZA, 22, {"marcado": velocidade_padrao == k + 1})
			_bt("o_som", Idioma.t("Ligado") if lig_som else Idioma.t("Desligado"), Rect2(xr - 230, y0 + OPC_Y[3], 230, h), B_VERDE if lig_som else B_CINZA, 22, {"icone": "ok" if lig_som else "x"})
			_bt("o_vm", "", Rect2(xr - 230, y0 + OPC_Y[4], 42, 42), Color.WHITE, 22, {"icone": "menos", "on": lig_som and Som.volume > 0.05})
			_bt("o_vp", "", Rect2(xr - 42, y0 + OPC_Y[4], 42, 42), Color.WHITE, 22, {"icone": "mais", "on": lig_som and Som.volume < 0.95})
			_bt("o_mm", "", Rect2(xr - 230, y0 + OPC_Y[5], 42, 42), Color.WHITE, 22, {"icone": "menos", "on": lig_som and Musica.volume > 0.05})
			_bt("o_mp", "", Rect2(xr - 42, y0 + OPC_Y[5], 42, 42), Color.WHITE, 22, {"icone": "mais", "on": lig_som and Musica.volume < 0.95})
			_bt("o_tremor", Idioma.t("Ligado") if tremor_tela else Idioma.t("Desligado"), Rect2(xr - 230, y0 + OPC_Y[6], 230, h), B_VERDE if tremor_tela else B_CINZA, 22, {"icone": "ok" if tremor_tela else "x"})
			_bt("o_dano", Idioma.t("Ligado") if numeros_dano else Idioma.t("Desligado"), Rect2(xr - 230, y0 + OPC_Y[7], 230, h), B_VERDE if numeros_dano else B_CINZA, 22, {"icone": "ok" if numeros_dano else "x"})
			_bt("o_poder", Idioma.t("Ligado") if poder_automatico else Idioma.t("Desligado"), Rect2(xr - 230, y0 + OPC_Y[8], 230, h), B_VERDE if poder_automatico else B_CINZA, 22, {"icone": "ok" if poder_automatico else "x"})
			_bt("o_prep", Idioma.t("Ligada") if preparacao_onda else Idioma.t("Desligada"), Rect2(xr - 230, y0 + OPC_Y[9], 230, h), B_VERDE if preparacao_onda else B_CINZA, 22, {"icone": "ok" if preparacao_onda else "x"})
			_bt("o_apagar", Idioma.t("Apagar..."), Rect2(xr - 230, y0 + OPC_Y[10], 230, h), B_VERMELHO, 22, {"on": tem_save})
			_bt("o_voltar", Idioma.t("Voltar"), Rect2(640 - 130, painel.end.y - 82, 260, 56), B_MARROM)
			_bt("o_voltar", "", Rect2(painel.end.x - 72, painel.position.y + 24, 42, 42), Color.WHITE, 22, {"icone": "x"})
		Tela.CREDITOS:
			painel = Rect2(240, 50, 800, 620)
			area_cred = Rect2(painel.position.x + 50, painel.position.y + 100, painel.size.x - 100, painel.size.y - 100 - 100)
			_bt("c_voltar", Idioma.t("Voltar"), Rect2(640 - 130, painel.end.y - 82, 260, 56), B_MARROM)
			_bt("c_voltar", "", Rect2(painel.end.x - 72, painel.position.y + 24, 42, 42), Color.WHITE, 22, {"icone": "x"})
		Tela.FINAL:
			_bt("f_creditos", Idioma.t("Créditos"), Rect2(388, 506, 230, 52), B_MARROM)
			_bt("f_voltar", Idioma.t("Voltar ao mapa"), Rect2(662, 506, 230, 52), B_VERDE)
		Tela.CONFIRMA:
			painel = Rect2(370, 200, 540, 320)
			_bt("cf_nao", conf.get("nao", Idioma.t("Cancelar")), Rect2(painel.position.x + 36, painel.end.y - 86, 224, 56), B_VERDE, 22, {"marcado": true})
			_bt("cf_ok", conf.get("ok", Idioma.t("Confirmar")), Rect2(painel.end.x - 260, painel.end.y - 86, 224, 56), B_VERMELHO)
	foco = clampi(foco, 0, maxi(0, botoes.size() - 1))

func _resumo_save() -> String:
	var e: Estado = dono.estado
	if dono.suspenso >= 0:
		# há um cômodo em curso nesta sessão: o botão diz onde o jogador vai voltar
		if e.invasao:
			return Idioma.t("Invasão · %s · Onda %d%s") % [Idioma.t(Fases.nome_do_lugar(e.lugar())), e.onda_invasao, Idioma.t(" · na luta") if dono.suspenso == dono.Modo.COMBATE else ""]
		return Idioma.t("%s · Onda %d de %d%s") % [Idioma.t(Fases.nome_do_lugar(e.lugar())), mini(e.onda, Balanco.ONDAS_TOTAIS), Balanco.ONDAS_TOTAIS, Idioma.t(" · na luta") if dono.suspenso == dono.Modo.COMBATE else ""]
	if e.campanha_vencida():
		var rec: int = e.melhor_invasao()
		if e.tudo_vencido():
			return Idioma.t("Tudo vencido · recorde: onda %d") % rec if rec > 0 else Idioma.t("Tudo vencido · %d gatos") % e.bonecos.size()
		return Idioma.t("%dº ato · %d de %d lugares") % [e.ato_atual(), e.vencidos_no_ato(e.ato_atual()), Fases.TOTAL]
	return Idioma.t("Cômodo %d de %d · %d gatos") % [clampi(e.fase_liberada, 1, Fases.TOTAL), Fases.TOTAL, e.bonecos.size()]

func confirmar(titulo: String, texto: String, ok: String, nao: String, acao: Callable) -> void:
	conf = {"titulo": titulo, "texto": texto, "ok": ok, "nao": nao, "acao": acao, "volta": tela}
	tela = Tela.CONFIRMA
	apertado = -1
	mouse_filter = Control.MOUSE_FILTER_STOP
	_montar()
	foco = 0

# ------------------------------------------------------------------ ações
func _acionar(id: String) -> void:
	if tr_t >= 0.0:
		reg("botão do menu '%s' IGNORADO (cortina em curso); %s" % [id, _estado_txt()])
		return   # durante a cortina nenhum botão responde (a tela de baixo ainda vai trocar)
	reg("botão do menu '%s' acionado; %s" % [id, _estado_txt()])
	if id in ["o_voltar", "c_voltar", "cf_nao", "p_continuar", "f_voltar"]:
		Som.tocar("fechar")
	elif id in ["opcoes", "creditos", "f_creditos"]:
		Som.tocar("abrir")
	elif not (id in ["o_vm", "o_vp", "o_mm", "o_mp", "o_som"]):
		Som.tocar("clique")
	if id in ["continuar", "nova"]:
		for k in pulo_gato.size():
			pulo_gato[k] = 0.0 if k % 2 == 0 else -0.1
	match id:
		"continuar":
			ir(dono.continuar)
		"nova":
			if tem_save:
				confirmar(Idioma.t("Nova campanha?"), Idioma.t("A campanha gravada (%s) será apagada, com o guarda-roupa e os gatos treinados.") % _resumo_save(), Idioma.t("Apagar e começar"), Idioma.t("Cancelar"), Callable(self, "_nova_campanha"))
			else:
				_nova_campanha()
		"tutorial":
			if dono.suspenso == dono.Modo.COMBATE:
				confirmar(Idioma.t("Fazer o tutorial?"), Idioma.t("Há uma luta guardada. Fazer o tutorial agora encerra essa luta (as roupas e o progresso gravado ficam)."), Idioma.t("Fazer o tutorial"), Idioma.t("Cancelar"), Callable(self, "_treino_ok"))
			else:
				_treino_ok()
		"opcoes":
			_ir_tela(Tela.OPCOES)
		"creditos":
			_ir_tela(Tela.CREDITOS)
		"sair":
			dono.get_tree().quit()
		"p_continuar":
			fechar_tudo()
		"p_mapa":
			var luta: bool = dono.modo == dono.Modo.COMBATE
			if dono.estado.invasao:
				confirmar(Idioma.t("Encerrar a invasão?"), Idioma.t("Sair agora termina a invasão. O recorde das ondas vencidas fica gravado, mas o que caiu nesta luta se perde. As roupas ficam como estão.") if luta else Idioma.t("Sair agora termina a invasão. O recorde das ondas vencidas fica gravado. As roupas ficam como estão."), Idioma.t("Voltar ao mapa"), Idioma.t("Continuar invasão"), Callable(self, "_voltar_mapa_ok"))
				return
			confirmar(Idioma.t("Voltar ao mapa?"), (Idioma.t("Sair da luta conta como desistir dela: o que caiu nela se perde. As roupas ficam como estão.") if luta else Idioma.t("A luta em curso termina aqui. As roupas ficam como estão.")), Idioma.t("Voltar ao mapa"), Idioma.t("Continuar luta"), Callable(self, "_voltar_mapa_ok"))
		"f_creditos":
			_ir_tela(Tela.CREDITOS)
		"f_voltar":
			fechar_tudo()
		"p_menu":
			if dono.modo == dono.Modo.MAPA:
				_menu_principal_ok()
			else:
				confirmar(Idioma.t("Ir ao menu principal?"), Idioma.t("A invasão fica guardada: \"Continuar\" no menu principal volta a este ponto. Se você fechar o jogo, ela se perde (as roupas ficam).") if dono.estado.invasao else Idioma.t("A luta fica guardada: \"Continuar\" no menu principal volta a este ponto. Se você fechar o jogo, ela se perde (as roupas ficam)."), Idioma.t("Menu principal"), Idioma.t("Continuar luta"), Callable(self, "_menu_principal_ok"))
		"o_idioma":
			Idioma.proximo()
			_opcao_mudou()
		"o_tela":
			tela_cheia = not tela_cheia
			aplicar_janela()
			_opcao_mudou()
		"o_som":
			Som.mudo = not Som.mudo
			Som.tocar("clique")   # ao religar, o clique confirma que voltou
			_opcao_mudou()
		"o_vm", "o_vp":
			Som.volume = clampf(snappedf(Som.volume + (0.1 if id == "o_vp" else -0.1), 0.1), 0.0, 1.0)
			Som.tocar("clique")   # o clique já sai no volume novo
			_opcao_mudou()
		"o_mm", "o_mp":
			Musica.volume = clampf(snappedf(Musica.volume + (0.1 if id == "o_mp" else -0.1), 0.1), 0.0, 1.0)
			Som.tocar("clique")
			_opcao_mudou()
		"o_v1", "o_v2", "o_v3":
			velocidade_padrao = int(id.substr(3))
			dono.definir_velocidade(velocidade_padrao)
			_opcao_mudou()
		"o_tremor":
			tremor_tela = not tremor_tela
			_opcao_mudou()
		"o_dano":
			numeros_dano = not numeros_dano
			_opcao_mudou()
		"o_poder":
			poder_automatico = not poder_automatico
			_opcao_mudou()
		"o_prep":
			preparacao_onda = not preparacao_onda
			_opcao_mudou()
		"o_apagar":
			confirmar(Idioma.t("Apagar a campanha?"), Idioma.t("Isso apaga o progresso, o guarda-roupa e os gatos treinados."), Idioma.t("Sim, apagar"), Idioma.t("Cancelar"), Callable(self, "_apagar_etapa2"))
		"o_voltar", "c_voltar":
			_voltar_de_sub()
		"cf_nao":
			_cancelar_conf()
		"cf_ok":
			var a: Callable = conf.get("acao", Callable())
			var volta: Tela = conf.get("volta", Tela.TITULO)
			conf = {}
			tela = volta
			_montar()
			if a.is_valid():
				a.call()

func _opcao_mudou() -> void:
	gravar_opcoes()
	var f: int = foco
	var tt: float = tela_t
	_montar()
	tela_t = tt
	foco = f

func _cancelar_conf() -> void:
	var volta: Tela = conf.get("volta", Tela.TITULO)
	conf = {}
	foco = 0
	tela = volta
	_montar()

func _apagar_etapa2() -> void:
	confirmar(Idioma.t("Tem certeza?"), Idioma.t("Não dá para desfazer. Todo o progresso desta campanha será perdido."), Idioma.t("Apagar de vez"), Idioma.t("Cancelar"), Callable(self, "_apagar_ok"))

func _apagar_ok() -> void:
	fechar_tudo()
	ir(dono.apagar_campanha)

func _nova_campanha() -> void:
	fechar_tudo()
	ir(dono.nova_campanha_do_titulo)

func _treino_ok() -> void:
	fechar_tudo()
	ir(dono.iniciar_treino)

func _voltar_mapa_ok() -> void:
	fechar_tudo()
	ir(dono.desistir_fase)

func _menu_principal_ok() -> void:
	if dono.modo == dono.Modo.COMBATE:
		conf = {}   # a luta continua parada por baixo da cortina
	else:
		fechar_tudo()
	ir(dono.ir_para_titulo)

# ------------------------------------------------------------------ entrada
func _botao_em(p: Vector2) -> int:
	for i in botoes.size():
		if (botoes[i]["r"] as Rect2).has_point(p):
			return i
	return -1

func _gui_input(ev: InputEvent) -> void:
	if tela == Tela.NENHUMA:
		return
	if ev is InputEventMouseMotion:
		var i: int = _botao_em((ev as InputEventMouseMotion).position)
		if i >= 0:
			foco = i
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if tela == Tela.CREDITOS:
				_rolar_cred(-50.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 50.0)
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		var i: int = _botao_em(mb.position)
		reg("menu recebeu %s em %s; botão sob o mouse: %s (apertado antes: %d); %s" % ["APERTO" if mb.pressed else "SOLTURA", str(mb.position), (botoes[i]["id"] if i >= 0 else "nenhum"), apertado, _estado_txt()])
		if mb.pressed:
			apertado = i
			if i >= 0:
				foco = i
		else:
			var a: int = apertado
			apertado = -1
			if i >= 0 and i == a and botoes[i]["on"]:
				_acionar(botoes[i]["id"])
			elif i >= 0 and i == a and tr_t < 0.0:
				UIComum.som_negado()

func _rolar_cred(d: float) -> void:
	rolagem_manual = true
	rolagem_cred = clampf(rolagem_cred + d, 0.0, maxf(0.0, cred_altura - area_cred.size.y))

func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and tela == Tela.NENHUMA and not dica_atual.is_empty():
		var mbd: InputEventMouseButton = ev as InputEventMouseButton
		if mbd.pressed and mbd.button_index == MOUSE_BUTTON_LEFT and _rect_dica().has_point(mbd.position):
			dica_t = 0.0   # um clique no balão da dica a dispensa
			get_viewport().set_input_as_handled()
			return
	if not (ev is InputEventKey):
		return
	var k: InputEventKey = ev as InputEventKey
	if not k.pressed or k.echo:
		return
	if tela == Tela.NENHUMA:
		if k.keycode == KEY_ESCAPE and dono != null and not dono.fusao.is_empty():
			dono.fusao = {}   # Esc cancela a confirmação de fusão antes de abrir a pausa
			get_viewport().set_input_as_handled()
			return
		if k.keycode == KEY_ESCAPE and dono != null and tr_t < 0.0 and dono.modo in [dono.Modo.GUARDA, dono.Modo.COMBATE, dono.Modo.MAPA]:
			abrir_pausa()
			get_viewport().set_input_as_handled()
		return
	var usada: bool = true
	match k.keycode:
		KEY_UP, KEY_W, KEY_LEFT, KEY_A:
			if tela == Tela.CREDITOS and (k.keycode == KEY_UP or k.keycode == KEY_W):
				_rolar_cred(-60.0)
			else:
				_mover_foco(-1)
		KEY_DOWN, KEY_S, KEY_RIGHT, KEY_D:
			if tela == Tela.CREDITOS and (k.keycode == KEY_DOWN or k.keycode == KEY_S):
				_rolar_cred(60.0)
			else:
				_mover_foco(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if foco >= 0 and foco < botoes.size() and botoes[foco]["on"]:
				_acionar(botoes[foco]["id"])
		KEY_ESCAPE:
			match tela:
				Tela.PAUSA:
					fechar_tudo()
				Tela.OPCOES, Tela.CREDITOS:
					_voltar_de_sub()
				Tela.CONFIRMA:
					_cancelar_conf()
				Tela.FINAL:
					fechar_tudo()
				_:
					usada = false
		_:
			usada = false
	if usada:
		get_viewport().set_input_as_handled()

func _mover_foco(d: int) -> void:
	var n: int = botoes.size()
	if n == 0:
		return
	for k in n:
		foco = posmod(foco + d, n)
		if botoes[foco]["on"]:
			return

# ------------------------------------------------------------------ pintura: peças comuns
## Recortes do pacote "Cat User Interface" (ToffeeCraft), sempre em escala inteira.
const GATO_TEX: Texture2D = preload("res://assets/terceiros/gui/gato_ui.png")
const R_BALAO: Array[Rect2] = [Rect2(5, 39, 21, 18), Rect2(37, 39, 21, 18), Rect2(5, 71, 21, 18), Rect2(37, 71, 21, 18)]
const R_DORMINDO := Rect2(66, 90, 43, 32)
## Botõezinhos redondos: (fileira, coluna) dentro de cada bloco de 4x4.
const ICONES := {"play": Vector2i(0, 0), "pausa": Vector2i(0, 1), "mais": Vector2i(1, 0), "ok": Vector2i(1, 1), "x": Vector2i(2, 0), "menos": Vector2i(2, 1), "ajuda": Vector2i(3, 0), "cifrao": Vector2i(3, 1)}
# paleta pastel com contorno escuro
const C_CONT := Color(0.24, 0.17, 0.19)
const C_CREME := Color(1.0, 0.94, 0.88)
const C_ROSA := Color(1.0, 0.82, 0.76)
const C_TEXTO := Color(0.28, 0.17, 0.19)
const C_TEXTO2 := Color(0.46, 0.32, 0.33)
const C_OURO := Color(1.0, 0.8, 0.3)
const C_NOME := Color(0.8, 0.32, 0.4)
const C_LINK := Color(0.25, 0.4, 0.72)
const B_VERDE := Color(0.62, 0.88, 0.6)
const B_LARANJA := Color(1.0, 0.76, 0.5)
const B_AZUL := Color(0.65, 0.8, 1.0)
const B_MARROM := Color(0.88, 0.72, 0.6)
const B_VERMELHO := Color(1.0, 0.5, 0.48)
const B_ROSA_IDIOMA := Color(1.0, 0.8, 0.86)
const B_CINZA := Color(0.86, 0.82, 0.8)
const B_OURO := Color(1.0, 0.84, 0.4)

func _nove(src: Rect2, m: Vector4, dst: Rect2, esc: float, cor: Color = Color.WHITE, miolo: bool = true, tex: Texture2D = GUI_TEX) -> void:
	dono.nove(self, tex, src, m, dst, esc, cor, miolo)

func _desl(r: Rect2, v: Vector2) -> Rect2:
	return Rect2(r.position + v, r.size)

func _ri(r: Rect2) -> Rect2:
	return Rect2(r.position.round(), r.size.round())

## Retângulo de cantos "cortados" em degraus de `u` pixels (arredondado em pixel art).
func _forma(r: Rect2, cor: Color, u: float = 3.0) -> void:
	if r.size.x <= 2.0 * u or r.size.y <= 2.0 * u:
		draw_rect(r, cor)
		return
	draw_rect(Rect2(r.position.x + u, r.position.y, r.size.x - 2.0 * u, r.size.y), cor)
	draw_rect(Rect2(r.position.x, r.position.y + u, r.size.x, r.size.y - 2.0 * u), cor)

func _caixa(r: Rect2, contorno: Color, fundo: Color, u: float = 3.0) -> void:
	_forma(r, contorno, u)
	_forma(r.grow(-u), fundo, u)

func _spr(src: Rect2, pos: Vector2, esc: int, cor: Color = Color.WHITE) -> void:
	draw_texture_rect_region(GATO_TEX, Rect2(pos.round(), src.size * float(esc)), src, cor)

func _pata(i: int, pos: Vector2, esc: int) -> void:
	_spr(Rect2(65 + 16 * (i % 3), 33 + 16 * ((i / 3) % 3), 15, 14), pos, esc)

## `estilo`: 0 branco, 1 marrom, 2 bege, 3 rosa.
func _icone(k: String, estilo: int, pos: Vector2, esc: int, apertado_i: bool = false) -> void:
	var rc: Vector2i = ICONES.get(k, Vector2i(0, 0))
	var sx: int = 128 + (estilo % 2) * 64 + 32 * rc.y + (16 if apertado_i else 0) + 1
	var sy: int = (estilo / 2) * 64 + 16 * rc.x + 1
	_spr(Rect2(sx, sy, 14, 14), pos, esc)

## Orelha de gato em degraus: `x,y` é o canto de cima; `esq` deixa a borda vertical à esquerda.
func _orelha(x: float, y: float, esq: bool, ue: float, miolo: Color) -> void:
	for i in 6:
		var w: float = (i + 2) * ue
		var rx: float = x if esq else x + 7.0 * ue - w
		draw_rect(Rect2(rx, y + i * ue, w, ue), C_CONT)
		if i >= 1:
			var iw: float = i * ue
			var ix: float = rx + ue if esq else rx + w - ue - iw
			draw_rect(Rect2(ix, y + i * ue, iw, ue), miolo)

## Orelha do logotipo (degraus de 4 px, 7 de largura por 7 de altura). `fase` 0: silhueta escura, antes dos
## contornos das letras; 1: borda creme e miolo rosa, depois do contorno escuro e antes do contorno rosa e do miolo
## da letra (o pé da orelha fica escondido atrás do "G", como se saísse dele).
func _orelha_logo(x: float, y: float, esq: bool, fase: int) -> void:
	# Orelha de gato em pixels de 5 px: 6 fileiras da ponta à base (borda de fora reta, a de dentro em diagonal)
	# mais 2 de pé escondidas atrás do "G". Contorno escuro, borda rosa-clara e miolo rosa forte.
	var u: float = 5.0
	var cols: int = 5
	var alt: int = 6
	for r in alt + 2:
		var wc: int = cols if r >= alt else 1 + int(ceilf(r * (cols - 1.0) / (alt - 1.0)))
		var rx: float = x if esq else x + (cols - wc) * u
		if fase == 0:
			draw_rect(Rect2(rx, y + r * u, wc * u, u), C_CONT)
			continue
		if wc < 3:
			continue
		draw_rect(Rect2(rx + u, y + r * u, (wc - 2) * u, u), Color(1.0, 0.72, 0.8))
		if r >= 3 and wc >= 4:
			draw_rect(Rect2(rx + u, y + r * u, (wc - 3) * u if esq else (wc - 3) * u, u), Color(0.96, 0.4, 0.56))

## Painel pastel com borda rosa, contorno escuro e orelhinhas nos cantos de cima.
func _painel_gato(r: Rect2, orelhas: bool = true, fundo: Color = C_CREME) -> void:
	var u: float = 3.0
	r = _ri(r)
	_forma(_desl(r, Vector2(0, 6)), Color(0, 0, 0, 0.3), u)
	_caixa(r, C_CONT, C_ROSA, u)
	_forma(r.grow(-3.0 * u), fundo, u)
	if orelhas:
		var ue: float = 4.0
		_orelha(r.position.x + 22.0, r.position.y - 5.0 * ue, true, ue, C_ROSA)
		_orelha(r.end.x - 22.0 - 7.0 * ue, r.position.y - 5.0 * ue, false, ue, C_ROSA)

func _t(txt: String, pos: Vector2, tam: int, cor: Color, larg: float = -1.0) -> void:
	var alin: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT if larg < 0.0 else HORIZONTAL_ALIGNMENT_CENTER
	draw_string(UIComum.FONTE, pos, txt, alin, larg, UIComum.tam(tam), cor)

## Título do painel (o mesmo desenho das outras telas: UIComum.titulo).
func _cabecalho(txt: String, r: Rect2, y: float) -> void:
	UIComum.titulo(self, txt, r.position.x + r.size.x * 0.5, r.position.y + y, 34, C_TEXTO, C_ROSA, t, false)

func _pop_ini() -> void:
	UIComum.ini_pop(self, painel.get_center(), UIComum.pop(tela_t))

func _pop_fim() -> void:
	UIComum.fim_pop(self)

func _texto(txt: String, pos: Vector2, tam: int, cor: Color, larg: float = -1.0, _contorno: int = 0) -> void:
	_t(txt, pos, tam, cor, larg)

func _botao_pintar(i: int) -> void:
	var b: Dictionary = botoes[i]
	var ativo_b: bool = b["on"]
	var sobre: bool = ativo_b and i == foco
	var o: Dictionary = {"on": ativo_b, "foco": sobre, "h": UIComum.anim_h(anim, _ak(i)), "p": UIComum.anim_p(anim, _ak(i)), "marcado": b.get("marcado", false), "tam": b["tam"]}
	if b.has("icone"):
		o["icone"] = b["icone"]
	if b.has("sub"):
		o["sub"] = b["sub"]
	var r: Rect2 = b["r"]
	if sobre and r.size.x >= 120.0:
		o["balao"] = 3 if b["id"] in ["cf_ok", "o_apagar", "sair"] else 0
	# lista que entra em cascata (título, pausa, final)
	if tela == Tela.TITULO or tela == Tela.PAUSA or tela == Tela.FINAL:
		var k: float = UIComum.cascata(tela_t, i, 0.06, 0.22, 0.05)
		if k <= 0.0:
			return
		var e: float = 1.0 - k
		r.position.x -= roundf(60.0 * e * e)
	UIComum.botao(self, r, b["txt"], b["cor"], o, t)

func _botoes_pintar() -> void:
	for i in botoes.size():
		_botao_pintar(i)

func _rotulos_linha(y: float, txt: String, x: float, _larg: float, dica_txt: String = "") -> void:
	_t(txt, Vector2(x, y + 22.0), 22, C_TEXTO)
	if dica_txt != "":
		_t(dica_txt, Vector2(x, y + 43.0), 14, C_TEXTO2)

# ------------------------------------------------------------------ _draw
func _draw() -> void:
	if dono == null:
		return
	UIComum.base = Transform2D.IDENTITY
	match tela:
		Tela.TITULO:
			_cena_titulo()
			_botoes_pintar()
		Tela.PAUSA:
			draw_rect(Rect2(0, 0, 1280, 720), Color(0.1, 0.05, 0.12, minf(0.6, 0.6 * tela_t / 0.15)))
			_pop_ini()
			_painel_gato(painel)
			# o gato dorme em cima do painel, respirando devagar, com os zês subindo
			var resp: float = roundf(1.5 + 1.5 * sin(t * 1.9))
			var gx: float = painel.position.x + painel.size.x * 0.5 - 64.0
			_spr(R_DORMINDO, Vector2(gx, painel.position.y - 93.0 + resp), 3)
			for z in 3:
				var fz: float = fposmod(t * 0.45 + z / 3.0, 1.0)
				_t("z", Vector2(gx + 112.0 + fz * 26.0, painel.position.y - 70.0 - fz * 44.0), int(14 + fz * 12.0), Color(C_CREME.r, C_CREME.g, C_CREME.b, sin(fz * PI)))
			_cabecalho(Idioma.t("Pausado"), painel, 68.0)
			_botoes_pintar()
			_t(Idioma.t("Esc fecha"), Vector2(painel.position.x, painel.end.y - 26), 14, C_TEXTO2, painel.size.x)
			_pop_fim()
		Tela.OPCOES:
			_fundo_sub()
			_pop_ini()
			_tela_opcoes()
			_pop_fim()
		Tela.CREDITOS:
			_fundo_sub()
			_pop_ini()
			_tela_creditos()
			_pop_fim()
		Tela.CONFIRMA:
			_fundo_confirma()
		Tela.FINAL:
			_cena_final()
			_botoes_pintar()
	if tela == Tela.NENHUMA:
		if acorda_t > 0.0:
			_gato_acorda()
		_banner_dica()
		_banner_meta()
	faiscas.desenhar(self)
	if tr_t >= 0.0:
		_cortina()

## O gato da pausa acorda: dá um salto, o corpo some e aparece uma exclamação.
func _gato_acorda() -> void:
	var k: float = 1.0 - acorda_t / 0.55
	var y: float = acorda_y - sin(clampf(k * 1.4, 0.0, 1.0) * PI) * 46.0
	var a: float = clampf((1.0 - k) * 1.8, 0.0, 1.0)
	_spr(R_DORMINDO, Vector2(acorda_x - 64.0, y), 3, Color(1, 1, 1, a))
	if k < 0.75:
		_t("!", Vector2(acorda_x + 22.0, y + 6.0), 44, Color(C_NOME.r, C_NOME.g, C_NOME.b, a))

## Fundo das sub-telas: sobre o título (escuro) ou sobre o jogo parado (pausa).
func _fundo_sub() -> void:
	if tela_volta == Tela.FINAL:
		_cena_final()
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.1, 0.05, 0.12, 0.7))
	elif tela_volta == Tela.TITULO:
		_cena_titulo(false)
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.1, 0.05, 0.12, 0.62))
	else:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.1, 0.05, 0.12, 0.7))

func _fundo_confirma() -> void:
	if tela_volta == Tela.TITULO:
		_cena_titulo(false)
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.1, 0.05, 0.12, 0.7))
	_pop_ini()
	_painel_gato(painel)
	# balão com a carinha preocupada: sobrancelhas caídas e uma gota de suor
	var bp: Vector2 = Vector2(painel.position.x + 34.0, painel.position.y + 46.0)
	_spr(R_BALAO[3], bp, 4)
	for px in [Vector2(7, 7), Vector2(8, 6), Vector2(12, 6), Vector2(13, 7)]:
		draw_rect(Rect2(bp + (px as Vector2) * 4.0, Vector2(4, 4)), C_CONT)
	draw_rect(Rect2(bp + Vector2(16, 3) * 4.0, Vector2(4, 8)), Color(0.5, 0.75, 1.0))
	var tx: float = painel.position.x + 140.0
	_t(conf.get("titulo", ""), Vector2(tx, painel.position.y + 74), 30, C_TEXTO)
	var y: float = painel.position.y + 112.0
	for l in dono._quebrar(conf.get("texto", ""), 17, painel.size.x - 140.0 - 34.0):
		_t(l, Vector2(tx, y), 17, C_TEXTO2)
		y += 23.0
	_botoes_pintar()
	_pop_fim()

# ------------------------------------------------------------------ título
## Grade de pixels do cenário do título: 4 px, a mesma dos gatos (escala 1.25 x GATO_K 3.2).
const QT := 4.0
## Tons da parede, do alto para o rodapé (o antigo degradê virou faixas com uma fileira pontilhada entre elas).
const PAREDE: Array[Color] = [Color(0.2, 0.14, 0.24), Color(0.245, 0.167, 0.26), Color(0.29, 0.193, 0.28), Color(0.34, 0.22, 0.3)]

## Disco em faixas na grade `q` (centro e raio em px de tela); com `r2` > 0 tira a "mordida" do disco
## centrado em `c2` (lua crescente). Só draw_rect, uma ou duas por fileira.
func _disco_px(ce: Vector2, r: float, cor: Color, q: float, c2: Vector2 = Vector2.ZERO, r2: float = 0.0) -> void:
	var n: int = int(ceilf(r / q))
	var cx: float = roundf(ce.x / q) * q
	var cy: float = roundf(ce.y / q) * q
	for j in range(-n, n):
		var yc: float = cy + (j + 0.5) * q
		var dy: float = yc - cy
		if absf(dy) > r:
			continue
		var h: float = roundf(sqrt(r * r - dy * dy) / q) * q
		if h <= 0.0:
			continue
		var x0: float = cx - h
		var x1: float = cx + h
		if r2 > 0.0 and absf(yc - c2.y) < r2:
			var h2: float = roundf(sqrt(r2 * r2 - (yc - c2.y) * (yc - c2.y)) / q) * q
			var m0: float = maxf(x0, roundf(c2.x / q) * q - h2)
			var m1: float = minf(x1, roundf(c2.x / q) * q + h2)
			if m1 > m0:
				if m0 > x0:
					draw_rect(Rect2(x0, cy + j * q, m0 - x0, q), cor)
				if x1 > m1:
					draw_rect(Rect2(m1, cy + j * q, x1 - m1, q), cor)
				continue
		draw_rect(Rect2(x0, cy + j * q, x1 - x0, q), cor)

## Losango de pixel com fileiras de 1, 3, 5, 3, 1 quadradinhos de `q` px, centrado em `p`.
func _losango_px(p: Vector2, q: float, cor: Color) -> void:
	var x: float = roundf(p.x / q) * q
	var y: float = roundf(p.y / q) * q
	for k in 5:
		var w: int = 2 - absi(k - 2)
		draw_rect(Rect2(x - w * q, y + (k - 2) * q, (2 * w + 1) * q, q), cor)

## Trapézio (o tapete) em fileiras de `q` px: largura de cima x0..x1 em `y0`, de baixo x2..x3 em `y1`.
func _trapezio_px(y0: float, y1: float, x0: float, x1: float, x2: float, x3: float, cor: Color, q: float) -> void:
	var n: int = int(roundf((y1 - y0) / q))
	for k in n:
		var f: float = (k + 0.5) / n
		var a: float = roundf(lerpf(x0, x2, f) / q) * q
		var b: float = roundf(lerpf(x1, x3, f) / q) * q
		draw_rect(Rect2(a, y0 + k * q, b - a, q), cor)

func _cena_titulo(com_placa: bool = true, final: bool = false) -> void:
	# parede com papel de parede: 4 faixas de tom, com uma fileira em xadrez de 4 px na emenda
	var fx: float = 560.0 / PAREDE.size()
	for k in PAREDE.size():
		draw_rect(Rect2(0, k * fx, 1280, fx), PAREDE[k])
		if k > 0:
			for i in int(1280.0 / (QT * 2.0)):
				draw_rect(Rect2(i * QT * 2.0, k * fx - QT, QT, QT), PAREDE[k])
				draw_rect(Rect2(i * QT * 2.0 + QT, k * fx, QT, QT), PAREDE[k - 1])
	for row in 7:
		for col in 12:
			var q: Vector2 = Vector2(40.0 + col * 120.0 + (row % 2) * 60.0, 30.0 + row * 84.0)
			_losango_px(q, 2.0, Color(0.95, 0.75, 0.5, 0.08))
	# janela com lua
	var jan := Rect2(70, 110, 190, 250)
	draw_rect(jan.grow(-14), Color(0.1, 0.12, 0.3))
	for k in 14:
		var sx: float = jan.position.x + 24 + fposmod(sin(k * 91.7) * 977.0, jan.size.x - 48)
		var sy: float = jan.position.y + 24 + fposmod(sin(k * 53.3) * 733.0, jan.size.y - 120)
		# estrelinhas na grade de 2 px, piscando em dois degraus
		var acesa: bool = sin(t * 2.0 + k) > -0.2
		draw_rect(Rect2(roundf(sx / 2.0) * 2.0, roundf(sy / 2.0) * 2.0, 4, 4) if acesa else Rect2(roundf(sx / 2.0) * 2.0 + 2.0, roundf(sy / 2.0) * 2.0 + 2.0, 2, 2), Color(1, 1, 0.85, 0.9 if acesa else 0.55))
	# lua crescente em pixels de 4 px: disco claro menos a mordida do céu
	var cl: Vector2 = jan.position + Vector2(130, 80)
	_disco_px(cl, 24.0, Color(1.0, 0.96, 0.78), QT, jan.position + Vector2(139, 72), 21.0)
	draw_rect(Rect2(jan.position.x + jan.size.x * 0.5 - 3, jan.position.y + 14, 6, jan.size.y - 28), Color(0.3, 0.18, 0.1))
	draw_rect(Rect2(jan.position.x + 14, jan.position.y + 110, jan.size.x - 28, 6), Color(0.3, 0.18, 0.1))
	_nove(R_MADEIRA, M_MADEIRA, jan, 0.5, Color.WHITE, false)
	# rodapé e chão de tábuas
	draw_rect(Rect2(0, 548, 1280, 14), Color(0.78, 0.6, 0.4))
	draw_rect(Rect2(0, 562, 1280, 6), Color(0.35, 0.22, 0.14))
	draw_rect(Rect2(0, 568, 1280, 152), Color(0.3, 0.18, 0.12))
	for k in 8:
		draw_rect(Rect2(0, 568 + k * 22.0, 1280, 2), Color(0, 0, 0, 0.2))
	for k in 13:
		var xj: float = k * 110.0 + (k % 3) * 25.0
		draw_rect(Rect2(xj, 570 + (k % 7) * 22.0, 2, 20), Color(0, 0, 0, 0.14))
	# tapete: três trapézios em degraus de 4 px e losangos de pixel na barra do meio
	_trapezio_px(596, 712, 190, 1090, 90, 1190, Color(0.45, 0.14, 0.17), QT)
	_trapezio_px(604, 704, 206, 1074, 114, 1166, Color(0.62, 0.22, 0.22), QT)
	_trapezio_px(612, 698, 230, 1050, 144, 1136, Color(0.52, 0.17, 0.2), QT)
	for k in 12:
		_losango_px(Vector2(270.0 + k * 66.0, 654.0), QT, Color(0.95, 0.75, 0.45, 0.55))
	# lâmpada de teto com luz: halo em duas faixas de 4 px (pulsando de degrau em degrau) e bulbo de pixel
	draw_rect(Rect2(638, 0, 4, 40), Color(0.15, 0.1, 0.1))
	var pl: float = 0.06 + (0.02 if sin(t * 2.0) > 0.0 else 0.0)
	_disco_px(Vector2(640, 52), 60.0, Color(1.0, 0.9, 0.55, pl), QT, Vector2(640, 52), 40.0)
	_disco_px(Vector2(640, 52), 40.0, Color(1.0, 0.9, 0.55, pl + 0.04), QT, Vector2(640, 52), 16.0)
	_disco_px(Vector2(640, 52), 16.0, Color(1.0, 0.9, 0.55), QT)
	draw_rect(Rect2(632, 40, 8, 4), Color(1.0, 0.97, 0.8))
	draw_rect(Rect2(628, 44, 4, 8), Color(1.0, 0.97, 0.8))
	if final:
		return
	# bichos espiando pelas bordas (sobem e descem)
	var vis1: float = clampf(sin(t * 0.55) * 2.2, 0.0, 1.0)
	var vis2: float = clampf(sin(t * 0.43 + 2.0) * 2.2, 0.0, 1.0)
	var vazio: Array = [null, null, null, null]
	var p1 := Vector2(1340.0 - 105.0 * vis1, 618.0)
	var p2 := Vector2(-60.0 + 105.0 * vis2, 700.0)
	Desenho.boneco(self, p1, 1.5, -1.0, 1, vazio, 0.0, t * 2.0, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1)
	Desenho.boneco(self, p2, 1.5, 1.0, 1, vazio, 0.0, t * 2.0 + 1.0, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 1, false, -1)
	# os gatos do time, sobre o tapete (a sombra fica no chão quando pulam: o boneco não desenha a dele)
	var bonecos: Array = dono.estado.bonecos
	var n: int = bonecos.size()
	Desenho.sem_sombra = true
	for i in n:
		var b: Boneco = bonecos[i]
		var base_x: float = 250.0 + i * (780.0 / maxf(1.0, n - 1.0)) if n > 1 else 640.0
		var anda: bool = i % 2 == 0
		var fase_i: float = t * 0.5 + i * 1.9
		var x: float = base_x + (sin(fase_i) * 80.0 if anda else 0.0)
		var dir: float = (1.0 if cos(fase_i) >= 0.0 else -1.0) if anda else (1.0 if i % 4 == 1 else -1.0)
		var y: float = 676.0 + (i % 2) * 8.0 - 6.0
		var hop: float = 0.0
		if i < pulo_gato.size() and pulo_gato[i] >= 0.0:
			hop = sin(clampf(pulo_gato[i] / 0.38, 0.0, 1.0) * PI) * 26.0
		_sombra(Vector2(x, y + 3), 34.0 - hop * 0.3, 7.0)
		Desenho.boneco(self, Vector2(x, y - hop), 1.25, dir, 0, b.pecas, 0.0, t * 3.0 + i, anda, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, i, false)
	Desenho.sem_sombra = false
	if com_placa:
		_placa_titulo()

## Sombra no chão em pixel art: elipse em fileiras de 4 px (a grade dos gatos), sem sobreposição.
func _sombra(p: Vector2, rx: float, ry: float) -> void:
	var ny: int = maxi(1, int(roundf(ry / QT)))
	var cx: float = roundf(p.x / QT) * QT
	var cy: float = roundf(p.y / QT) * QT
	for j in range(-ny, ny):
		var dy: float = (j + 0.5) / ny
		var w: float = roundf(rx * sqrt(maxf(0.0, 1.0 - dy * dy)) / QT) * QT
		if w > 0.0:
			draw_rect(Rect2(cx - w, cy + j * QT, w * 2.0, QT), Color(0, 0, 0, 0.35))

func _placa_titulo() -> void:
	var fonte: Font = UIComum.FONTE
	var tam: int = 94
	var letras: String = Idioma.titulo_jogo()
	var largs: Array[float] = []
	var total: float = 0.0
	for c in letras:
		var w: float = fonte.get_string_size(c, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam)).x
		largs.append(w)
		total += w
	var x0: float = roundf(640.0 - total * 0.5 - 52.0)
	var base: float = 134.0
	var ys: Array[float] = []
	for k in letras.length():
		ys.append(base + roundf(sin(t * 2.4 + k * 0.55) * 3.0))
	# orelhas de gato saindo do topo do "G": o pé fica por baixo do contorno e do miolo da letra
	var topo: float = ys[0] - 0.72 * tam
	var oy: float = topo - 6.0 * 5.0 + 6.0
	var ox_e: float = x0 - 3.0
	var ox_d: float = x0 + largs[0] - 22.0
	_orelha_logo(ox_e, oy, true, 0)
	_orelha_logo(ox_d, oy, false, 0)
	# contorno escuro com sombra, depois contorno rosa
	var x: float = x0
	for k in letras.length():
		draw_string_outline(fonte, Vector2(x, ys[k] + 6.0), letras[k], HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam), 24, Color(0, 0, 0, 0.3))
		draw_string_outline(fonte, Vector2(x, ys[k]), letras[k], HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam), 22, C_CONT)
		x += largs[k]
	_orelha_logo(ox_e, oy, true, 1)
	_orelha_logo(ox_d, oy, false, 1)
	x = x0
	for k in letras.length():
		draw_string_outline(fonte, Vector2(x, ys[k]), letras[k], HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam), 11, C_ROSA)
		x += largs[k]
	x = x0
	for k in letras.length():
		draw_string(fonte, Vector2(x, ys[k]), letras[k], HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam), Color(1.0, 0.62, 0.68) if (letras[k] == "-" or letras[k] == "&" or (letras[k] == "e" and k > 0 and k < letras.length() - 1 and letras[k - 1] == " " and letras[k + 1] == " ")) else C_CREME)
		x += largs[k]
	# novelo de lã rolando ao lado do nome, com a ponta do fio solta: pixels de 5 px, como as orelhas do logo
	var u: float = 5.0
	var cn: Vector2 = (Vector2(x0 + total + 66.0, base - 30.0) / u).round() * u
	var rosa_fio := Color(1.0, 0.6, 0.66)
	# fio: uma fileira de quadradinhos que sobe e desce em degraus, com o contorno escuro por baixo
	var y_ant: float = cn.y + 25.0
	for k in 22:
		var xf: float = cn.x + 15.0 + k * u
		var yf: float = roundf((cn.y + 26.0 + sin(k * 0.45 + t * 2.0) * 5.0 * minf(1.0, k / 6.0)) / u) * u
		var ya: float = minf(yf, y_ant)
		var yb: float = maxf(yf, y_ant)
		draw_rect(Rect2(xf, ya - u, u, yb - ya + 3.0 * u), C_CONT)
		draw_rect(Rect2(xf, ya, u, yb - ya + u), rosa_fio)
		y_ant = yf
	draw_rect(Rect2(cn.x + 15.0 + 22.0 * u, y_ant - u, u, 3.0 * u), C_CONT)
	_disco_px(cn, 35.0, C_CONT, u)
	_disco_px(cn, 30.0, rosa_fio, u)
	# voltas da lã girando, de quadradinho em quadradinho
	var rot: float = t * 1.2
	for k in 3:
		var ra: float = 8.0 + k * 7.5
		var a0: float = rot + k * 2.1
		var na: int = int(2.3 * ra / (u * 0.7)) + 1
		for i in na:
			var a: float = a0 + 2.3 * i / na
			draw_rect(Rect2(floorf((cn.x + cos(a) * ra) / u) * u, floorf((cn.y + sin(a) * ra) / u) * u, u, u), Color(0.82, 0.38, 0.5))
	for i in 3:
		var a2: float = rot + 3.6 + i * 0.22
		draw_rect(Rect2(floorf((cn.x + cos(a2) * 24.0) / u) * u, floorf((cn.y + sin(a2) * 24.0) / u) * u, u, u), Color(1.0, 0.85, 0.88))
	# faixa com o subtítulo
	var sw: float = 470.0
	var rf: Rect2 = Rect2(640.0 - sw * 0.5, base + 34.0, sw, 34.0)
	_forma(_desl(rf, Vector2(0, 5)), Color(0, 0, 0, 0.3))
	_caixa(rf, C_CONT, C_CREME)
	_t(Idioma.t("gatos fantasiados contra bichos invasores"), Vector2(rf.position.x, rf.position.y + 23.0), 17, C_TEXTO, rf.size.x)

# ------------------------------------------------------------------ opções
func _tela_opcoes() -> void:
	_painel_gato(painel)
	_cabecalho(Idioma.t("Opções"), painel, 70.0)
	var x: float = painel.position.x + 48.0
	var xr: float = painel.end.x - 48.0
	var y0: float = painel.position.y + OPC_TOPO
	var lig := func(v: bool) -> String: return Idioma.t("ligado") if v else Idioma.t("desligado")
	var poder_txt: String = Idioma.t("Ligado: os gatos usam o poder da fantasia sozinhos. Desligado: você dispara na luta. Agora: %s.") % lig.call(poder_automatico)
	var pct: int = int(round(Som.volume * 100.0))
	var pct_m: int = int(round(Musica.volume * 100.0))
	var rot: Array = [
		[Idioma.t("Idioma"), Idioma.t("Língua dos textos do jogo. Clique para trocar")],
		[Idioma.t("Tela"), Idioma.t("Agora: tela cheia. Clique para trocar") if tela_cheia else Idioma.t("Agora: em janela. Clique para trocar")],
		[Idioma.t("Velocidade da luta"), Idioma.t("Ao começar uma luta. Agora: %dx") % velocidade_padrao],
		[Idioma.t("Som"), Idioma.t("Efeitos e música. Agora: desligados") if Som.mudo else Idioma.t("Efeitos e música. Agora: ligados")],
		[Idioma.t("Volume dos efeitos"), Idioma.t("Agora: %d%% (de 10 em 10)") % pct if not Som.mudo else Idioma.t("Ligue o som para ajustar")],
		[Idioma.t("Volume da música"), Idioma.t("Agora: %d%% (de 10 em 10)") % pct_m if not Som.mudo else Idioma.t("Ligue o som para ajustar")],
		[Idioma.t("Tremor de tela"), Idioma.t("Sacudidas nos golpes fortes. Agora: %s") % lig.call(tremor_tela)],
		[Idioma.t("Números de dano"), Idioma.t("Valores que sobem dos golpes. Agora: %s") % lig.call(numeros_dano)],
		[Idioma.t("Poderes automáticos"), poder_txt],
		[Idioma.t("Preparação da onda"), Idioma.t("Arrumar o time antes da onda. Agora: ligada") if preparacao_onda else Idioma.t("Arrumar o time antes da onda. Agora: começa direto")],
		[Idioma.t("Campanha"), Idioma.t("Apaga o progresso gravado") if tem_save else Idioma.t("Nenhuma campanha gravada")],
	]
	for k in rot.size():
		var y: float = y0 + OPC_Y[k]
		_pata(k % 9, Vector2(x, y + 8.0), 2)
		if k == 8:
			_t(rot[k][0], Vector2(x + 42.0, y + 22.0), 22, C_TEXTO)
			var ly: float = y + 41.0
			for l in _quebra(poder_txt, 13, 290.0):
				_t(l, Vector2(x + 42.0, ly), 13, C_TEXTO2)
				ly += 15.0
		else:
			_rotulos_linha(y, rot[k][0], x + 42.0, 300.0, rot[k][1])
		if k < rot.size() - 1:
			var ys: float = y0 + OPC_Y[k + 1] - 8.0
			for d in int((painel.size.x - 96.0) / 14.0):
				draw_rect(Rect2(x + d * 14.0, ys, 6, 3), Color(0.9, 0.62, 0.6, 0.7))
	# réguas de volume (efeitos e música): dez quadradinhos entre o menos e o mais
	for linha in [[4, Som.volume], [5, Musica.volume]]:
		var yv: float = y0 + OPC_Y[linha[0]]
		var cheios: int = 0 if Som.mudo else int(round(float(linha[1]) * 10.0))
		for q in 10:
			var rq := Rect2(xr - 230.0 + 56.0 + q * 12.0, yv + 9.0, 10.0, 24.0)
			draw_rect(rq, C_CONT)
			draw_rect(rq.grow(-2.0), Color(1.0, 0.7, 0.72) if q < cheios else Color(0.92, 0.86, 0.82))
	_botoes_pintar()

## Quebra o texto em linhas que cabem em `larg` pixels.
func _quebra(txt: String, tam: int, larg: float) -> Array[String]:
	var fonte: Font = UIComum.FONTE
	var res: Array[String] = []
	var atual: String = ""
	for palavra in txt.split(" "):
		var tent: String = palavra if atual == "" else atual + " " + palavra
		if atual != "" and fonte.get_string_size(tent, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam)).x > larg:
			res.append(atual)
			atual = palavra
		else:
			atual = tent
	if atual != "":
		res.append(atual)
	return res

# ------------------------------------------------------------------ créditos
func _linhas_creditos() -> Array:
	var l: Array = []
	var peq: Color = C_TEXTO2
	l.append(["t", Idioma.titulo_jogo(), 26, C_NOME])
	l.append(["t", "Um jogo de %s" % AUTOR_JOGO, 17, C_TEXTO])
	l.append(["pata"])
	l.append(["t", "Gatos em pixel art", 14, peq])
	l.append(["t", "32x32 Pixel kittens Cats", 22, C_NOME])
	l.append(["t", "por Last tick", 17, C_TEXTO])
	l.append(["t", "last-tick.itch.io", 14, C_LINK])
	l.append(["pata"])
	l.append(["t", "Interface com tema de gato", 14, peq])
	l.append(["t", "Cat User Interface", 22, C_NOME])
	l.append(["t", "por ToffeeCraft", 17, C_TEXTO])
	l.append(["t", "toffeecraft.itch.io/cat-user-interface", 14, C_LINK])
	l.append(["pata"])
	l.append(["t", "Molduras, botões e ícones do jogo", 14, peq])
	l.append(["t", "Cryo's Mini GUI", 22, C_NOME])
	l.append(["t", "por PaperHatLizard", 17, C_TEXTO])
	l.append(["t", "Licença CC BY 4.0", 14, C_TEXTO])
	l.append(["t", "paperhatlizard.itch.io/cryos-mini-gui", 14, C_LINK])
	l.append(["pata"])
	l.append(["t", "Fonte", 14, peq])
	l.append(["t", "Jersey 10", 22, C_NOME])
	l.append(["t", "por Sarah Cadigan-Fried", 17, C_TEXTO])
	l.append(["t", "Licença SIL Open Font 1.1", 14, C_TEXTO])
	l.append(["pata"])
	l.append(["t", "Música", 14, peq])
	l.append(["t", "Trilha chiptune original", 22, C_NOME])
	l.append(["t", "composta e sintetizada para o jogo", 17, C_TEXTO])
	l.append(["pata"])
	l.append(["t", "Feito com", 14, peq])
	l.append(["t", "Godot Engine", 22, C_NOME])
	l.append(["t", "godotengine.org", 14, C_LINK])
	l.append(["pata"])
	l.append(["t", "Obrigado por jogar!", 20, C_NOME])
	return l

func _tela_creditos() -> void:
	_painel_gato(painel)
	var linhas: Array = _linhas_creditos()
	var y: float = area_cred.position.y - rolagem_cred + 4.0
	var cx: float = area_cred.position.x + area_cred.size.x * 0.5
	var np: int = 0
	for l in linhas:
		if l[0] == "pata":
			if y + 34.0 > area_cred.position.y and y < area_cred.end.y:
				_pata(np % 9, Vector2(cx - 15.0, y + 8.0), 2)
			np += 1
			y += 46.0
			continue
		var tam: int = UIComum.tam(l[2])
		var ys: float = y + tam
		if ys > area_cred.position.y - 4.0 and ys - tam < area_cred.end.y + 4.0:
			_t(l[1], Vector2(area_cred.position.x, ys), tam, l[3], area_cred.size.x)
		y += tam + 9.0
	cred_altura = y - (area_cred.position.y - rolagem_cred) + 4.0
	# faixas que escondem o que passa da área visível (por dentro da moldura)
	var ix: float = painel.position.x + 9.0
	var iw: float = painel.size.x - 18.0
	draw_rect(Rect2(ix, painel.position.y + 9.0, iw, area_cred.position.y - painel.position.y - 9.0), C_CREME)
	draw_rect(Rect2(ix, area_cred.end.y, iw, painel.end.y - area_cred.end.y - 9.0), C_CREME)
	_cabecalho("Créditos", painel, 70.0)
	if cred_altura > area_cred.size.y:
		var frac: float = rolagem_cred / maxf(1.0, cred_altura - area_cred.size.y)
		var barra := Rect2(area_cred.end.x + 14, area_cred.position.y, 6, area_cred.size.y)
		draw_rect(barra, Color(0.9, 0.62, 0.6, 0.45))
		var py: float = roundf(barra.position.y + frac * (barra.size.y - 40.0))
		_forma(Rect2(barra.position.x - 3.0, py, 12, 40), C_CONT, 3.0)
		_forma(Rect2(barra.position.x - 3.0 + 3.0, py + 3.0, 6, 34), Color(1.0, 0.7, 0.72), 3.0)
	_botoes_pintar()

# ------------------------------------------------------------------ transição: patinhas que fecham a tela
## Íris em blocos de 4 px: a tela rosa fecha num círculo em degraus até o centro e abre de novo pelo mesmo
## caminho. Cada faixa de 4 px de altura é o rosa à esquerda e à direita do furo; a borda do furo leva uma
## linha mais escura. As patas, numa grade desencontrada, carimbam quando a íris passa por elas (grandes e
## claras no 1º instante, depois assentadas e escuras). Sem alfa: o rosa é chapado, como o resto da arte.
const CORT_B := 4.0
const CORT_PATA: Array[String] = [
	"..xx.xx..", "..xx.xx..", "xx.....xx", "xx.xxx.xx",
	"..xxxxx..", ".xxxxxxx.", ".xxxxxxx.", "..xxxxx..",
]

func _cortina() -> void:
	var f: float = clampf(tr_t, 0.0, 1.0)
	var cob: float = 1.0 - absf(f * 2.0 - 1.0)
	cob = cob * cob * (3.0 - 2.0 * cob)
	if cob <= 0.0:
		return
	var ce := Vector2(640.0, 360.0)
	var rmax: float = 760.0
	var r: float = floorf(rmax * (1.0 - cob) / CORT_B) * CORT_B   # raio do furo, em degraus de 4 px
	var borda: Color = C_ROSA.darkened(0.22)
	var y: float = 0.0
	while y < 720.0:
		var dy: float = absf(y + CORT_B * 0.5 - ce.y)
		if dy >= r:
			draw_rect(Rect2(0.0, y, 1280.0, CORT_B), C_ROSA)
		else:
			var hw: float = floorf(sqrt(r * r - dy * dy) / CORT_B) * CORT_B
			var xa: float = ce.x - hw
			var xb: float = ce.x + hw
			if xa > 0.0:
				draw_rect(Rect2(0.0, y, xa, CORT_B), C_ROSA)
				draw_rect(Rect2(xa - CORT_B, y, CORT_B, CORT_B), borda)
			if xb < 1280.0:
				draw_rect(Rect2(xb, y, 1280.0 - xb, CORT_B), C_ROSA)
				draw_rect(Rect2(xb, y, CORT_B, CORT_B), borda)
		y += CORT_B
	# patas carimbadas: grade de 6 x 4, linhas alternadas meio passo deslocadas
	for j in 4:
		for i in 6:
			var pc := Vector2(130.0 + i * 205.0 + (102.0 if j % 2 == 1 else 0.0), 95.0 + j * 178.0)
			if pc.x > 1240.0:
				continue
			var d: float = pc.distance_to(ce) - r   # quanto o rosa já passou da pata
			if d < 24.0:
				continue
			var batida: bool = d < 70.0
			var cel: float = CORT_B * (2.0 if batida else 1.0)
			var cor_p: Color = C_ROSA.darkened(0.12) if batida else C_ROSA.darkened(0.3)
			var o := Vector2(floorf((pc.x - 4.5 * cel) / CORT_B) * CORT_B, floorf((pc.y - 4.0 * cel) / CORT_B) * CORT_B)
			for yy in CORT_PATA.size():
				var ln: String = CORT_PATA[yy]
				for xx in ln.length():
					if ln[xx] == "x":
						draw_rect(Rect2(o.x + xx * cel, o.y + yy * cel, cel, cel), cor_p)

# ------------------------------------------------------------------ dicas de primeira vez
## Ordem natural de um começo de jogo guiado: vestir, blocos, fantasia, queda, poder, troféu.
const ORDEM_DICAS: Array[String] = ["vestir", "blocos", "fantasia", "queda", "poder", "trofeu"]

func _pos_dica(id: String) -> int:
	var k: int = ORDEM_DICAS.find(id)
	return k if k >= 0 else 99

func dica(id: String, texto: String, urgente: bool = false) -> void:
	if dicas_vistas.get(id, false):
		return
	if dono != null and dono.tutorial != null and dono.tutorial.guiado_ativo():
		return   # durante o tutorial guiado só fala o gato-guia
	for d in fila_dicas:
		if d["id"] == id:
			return
	if not dica_atual.is_empty() and dica_atual["id"] == id:
		return
	var d: Dictionary = {"id": id, "txt": texto, "modo": -1 if (id == "trofeu" or dono == null) else dono.modo}   # -1: vale em qualquer tela
	if urgente:
		fila_dicas.push_front(d)
	else:
		var at: int = fila_dicas.size()
		for i in fila_dicas.size():
			if _pos_dica(fila_dicas[i]["id"]) > _pos_dica(id):
				at = i
				break
		fila_dicas.insert(at, d)

## O jogador fez o que a dica pedia: ela some logo.
func dica_cumprida(id: String) -> void:
	if not dica_atual.is_empty() and dica_atual["id"] == id:
		dica_atual["cumprida"] = true
		dica_t = minf(dica_t, 1.0)

func _tocar_dicas(delta: float) -> void:
	if dono != null:
		# dica é da tela em que nasceu: trocou de modo, ela some (e volta depois se nem chegou a ser cumprida)
		if not dica_atual.is_empty() and dica_atual.get("modo", -1) != -1 and dica_atual["modo"] != dono.modo:
			if not dica_atual.get("cumprida", false):
				dicas_vistas.erase(dica_atual["id"])
			dica_atual = {}
		for i in range(fila_dicas.size() - 1, -1, -1):
			if fila_dicas[i].get("modo", -1) != -1 and fila_dicas[i]["modo"] != dono.modo:
				fila_dicas.remove_at(i)
	if not dica_atual.is_empty():
		if tela == Tela.NENHUMA and tr_t < 0.0:
			dica_t -= delta
		if dica_t <= 0.0:
			dica_atual = {}
			espera_dica = 1.6   # uma por vez, com respiro entre elas
		return
	if fila_dicas.is_empty() or tela != Tela.NENHUMA or tr_t >= 0.0 or dono == null:
		return
	if not (dono.modo in [dono.Modo.GUARDA, dono.Modo.COMBATE]):
		return
	# só quando a tela se assentou e o jogador não está no meio de um gesto que a dica explicaria
	if espera_dica > 0.0 or not dono.arrasto.is_empty() or not dono.fusao.is_empty() or (dono.oficina != null and dono.oficina.aberta) or (dono.fichario != null and dono.fichario.aberto()):
		return
	Som.tocar("aba", 1.25, 0.03, -6.0)
	dica_atual = fila_dicas.pop_front()
	dica_atual["dur"] = clampf(4.0 + str(dica_atual["txt"]).length() * 0.07, 8.0, 15.0)   # texto longo fica mais tempo
	dica_t = float(dica_atual["dur"])
	dicas_vistas[dica_atual["id"]] = true
	gravar_opcoes()

## Retângulo do balão de dica: coluna da esquerda, abaixo do título da tela (não cobre cartões, gatos nem o campo).
func _rect_dica() -> Rect2:
	var linhas: Array = dono._quebrar(dica_atual["txt"], 14, 124.0)
	return Rect2(8.0, 84.0, 186.0, maxf(56.0, 22.0 + linhas.size() * 18.0))

func _banner_dica() -> void:
	if dica_atual.is_empty():
		return
	var al: float = clampf(dica_t / 0.6, 0.0, 1.0) * clampf((float(dica_atual.get("dur", 8.0)) - dica_t) / 0.3, 0.0, 1.0)
	var r: Rect2 = _rect_dica()
	r.position.x -= roundf((1.0 - al) * 240.0)   # desliza para dentro e para fora
	if r.end.x < 0.0:
		return
	_forma(_desl(r, Vector2(0, 5)), Color(0, 0, 0, 0.3))
	_caixa(r, C_CONT, C_CREME)
	_spr(R_BALAO[0], Vector2(r.position.x + 8.0, r.position.y + 10.0), 2)
	var y: float = r.position.y + 24.0
	for l in dono._quebrar(dica_atual["txt"], 14, 124.0):
		_t(l, Vector2(r.position.x + 56.0, y), 14, C_TEXTO)
		y += 18.0


# ------------------------------------------------------------------ aviso de meta cumprida
## Enfileira um aviso no estilo dos balões de dica: "Meta cumprida: Fantasia de Pirata · +3 troféus".
func aviso_meta(titulo: String, premio: int) -> void:
	fila_metas.append({"titulo": titulo, "premio": premio})

func _tocar_metas(delta: float) -> void:
	var livre: bool = tela == Tela.NENHUMA and tr_t < 0.0 and dono != null and (dono.modo == dono.Modo.MAPA or dono.modo == dono.Modo.GUARDA)
	if not meta_atual.is_empty():
		if not livre:
			# trocou de tela: o aviso volta para o começo da fila em vez de se perder
			fila_metas.push_front(meta_atual)
			meta_atual = {}
			return
		meta_t -= delta
		if meta_t <= 0.0:
			meta_atual = {}
		return
	if livre and not fila_metas.is_empty():
		meta_atual = fila_metas.pop_front()
		meta_t = META_DURACAO
		meta_burst = false
		Som.tocar("meta")

func _rect_meta() -> Rect2:
	var linhas: Array = dono._quebrar(meta_atual["titulo"], 15, 206.0)
	var y0: float = 84.0
	if not dica_atual.is_empty():
		y0 = _rect_dica().end.y + 8.0
	return Rect2(8.0, y0, 286.0, maxf(58.0, 30.0 + linhas.size() * 18.0 + 12.0))

func _banner_meta() -> void:
	if meta_atual.is_empty():
		return
	var al: float = clampf(meta_t / 0.5, 0.0, 1.0) * clampf((META_DURACAO - meta_t) / 0.3, 0.0, 1.0)
	var r: Rect2 = _rect_meta()
	if not meta_burst and META_DURACAO - meta_t > 0.3:
		meta_burst = true
		faiscas.emitir(r.get_center(), 22, UIComum.FAISCA_COR, 210.0, 0.8)
	r.position.x -= roundf((1.0 - al) * 320.0)
	if r.end.x < 0.0:
		return
	UIComum.clarao(self, r, clampf(1.0 - (META_DURACAO - meta_t - 0.25) / 0.5, 0.0, 1.0))
	_forma(_desl(r, Vector2(0, 5)), Color(0, 0, 0, 0.3))
	_caixa(r, C_CONT, C_CREME)
	_spr(R_BALAO[0], Vector2(r.position.x + 8.0, r.position.y + 10.0), 2)
	var y: float = r.position.y + 24.0
	for l in dono._quebrar(meta_atual["titulo"], 15, 206.0):
		_t(l, Vector2(r.position.x + 56.0, y), 15, C_TEXTO)
		y += 18.0
	var prem: int = int(meta_atual["premio"])
	var kc: float = clampf((META_DURACAO - meta_t - 0.35) / 0.8, 0.0, 1.0)
	var vis: int = int(round(prem * kc))
	_t("+%d troféus" % vis if prem != 1 else "+1 troféu", Vector2(r.position.x + 56.0, y + 2.0), 14, C_NOME)

# ------------------------------------------------------------------ tela de final
const CONFETE_COR: Array[Color] = [Color(1.0, 0.45, 0.5), Color(1.0, 0.8, 0.3), Color(0.55, 0.85, 0.6), Color(0.55, 0.75, 1.0), Color(0.85, 0.6, 1.0)]

func _confete() -> void:
	for k in 90:
		var vel: float = 40.0 + fposmod(k * 37.0, 70.0)
		var y: float = fposmod(t * vel + k * 53.0, 760.0) - 20.0
		var x: float = fposmod(k * 131.0, 1280.0) + sin(t * 1.5 + k) * 18.0
		var tam: float = 4.0 if k % 3 else 6.0
		draw_rect(Rect2(roundf(x / 2.0) * 2.0, roundf(y / 2.0) * 2.0, tam, tam * (1.0 if k % 2 else 1.6)), CONFETE_COR[k % CONFETE_COR.size()])

func _linha_ficha(txt: String, valor: String, x: float, y: float, larg: float) -> void:
	_t(txt, Vector2(x, y), 17, C_TEXTO)
	_t(valor, Vector2(x + larg - 160.0, y), 18, C_NOME, 160.0)
	for d in int(larg / 10.0):
		draw_rect(Rect2(x + d * 10.0, y + 6.0, 4, 2), Color(0.9, 0.62, 0.6, 0.55))

func _cena_final() -> void:
	var e: Estado = dono.estado
	_cena_titulo(false, true)
	# gatos do time comemorando: pulinhos escalonados
	var n: int = e.bonecos.size()
	for i in n:
		var b: Boneco = e.bonecos[i]
		var x: float = 250.0 + i * (780.0 / maxf(1.0, n - 1.0)) if n > 1 else 640.0
		var pulo: float = absf(sin(t * 4.2 + i * 1.1)) * 34.0
		var y: float = 676.0 + (i % 2) * 8.0 - 6.0
		_sombra(Vector2(x, y + 3), 34.0 - pulo * 0.3, 7.0)
		Desenho.sem_sombra = true   # a sombra já está no chão (_sombra)
		Desenho.boneco(self, Vector2(x, y - pulo), 1.25, 1.0 if i % 2 == 0 else -1.0, 0, b.pecas, 0.0, t * 3.0 + i, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, i, false)
		Desenho.sem_sombra = false
	_confete()
	# título
	var rt := Rect2(300, 30, 680, 82)
	_painel_gato(rt)
	# 3º ato vencido (Magnetomiau): o bairro também é dos gatos; antes disso, só a casa e o quintal
	var bairro: bool = e.tudo_vencido()
	_t("As ruas também são dos gatos!" if bairro else "A casa é dos gatos!", Vector2(rt.position.x, rt.position.y + 56.0), 40 if bairro else 46, C_TEXTO, rt.size.x)
	# ficha com os números da campanha
	var rf := Rect2(290, 140, 350, 350)
	_painel_gato(rf, false)
	_t("Números da campanha", Vector2(rf.position.x, rf.position.y + 44.0), 22, C_NOME, rf.size.x)
	var minutos: int = int(round(float(e.estat.get("tempo", 0.0)) / 60.0))
	var kf: float = clampf((tela_t - 0.5) / 1.8, 0.0, 1.0)
	kf = 1.0 - pow(1.0 - kf, 3.0)   # os números sobem até o valor, desacelerando
	var cnt := func(v: int) -> int: return int(round(v * kf))
	var linhas: Array = [
		["Tempo de luta", "%d min" % cnt.call(minutos)],
		["Ondas lutadas", str(cnt.call(int(e.estat.get("ondas", 0))))],
		["Gatos nocauteados", str(cnt.call(int(e.estat.get("nocautes", 0))))],
		["Bichos derrotados", str(cnt.call(int(e.estat.get("abates", 0))))],
		["Derrotas", str(cnt.call(int(e.estat.get("derrotas", 0))))],
		["Fantasias completas", "%d de %d" % [cnt.call(e.fantasias_completas()), Pecas.n_ativas()]],
		["Peças encontradas", "%d de %d" % [cnt.call(e.pecas_tidas()), Pecas.n_pecas_ativas()]],
		["Troféus", str(cnt.call(e.trofeus))],
	]
	for k in linhas.size():
		_linha_ficha(linhas[k][0], linhas[k][1], rf.position.x + 30.0, rf.position.y + 84.0 + k * 33.0, rf.size.x - 60.0)
	# gato de maior nível
	var melhor: Boneco = null
	for b in e.bonecos:
		if melhor == null or b.nivel > melhor.nivel:
			melhor = b
	var rg := Rect2(660, 140, 330, 190)
	_painel_gato(rg, false)
	_t("Gato de maior nível", Vector2(rg.position.x, rg.position.y + 40.0), 20, C_NOME, rg.size.x)
	if melhor != null:
		var cx: float = rg.position.x + 90.0
		var pulo2: float = absf(sin(t * 3.0)) * 8.0
		_sombra(Vector2(cx, rg.end.y - 28.0), 36.0, 7.0)
		Desenho.sem_sombra = true   # a sombra já está no chão (_sombra)
		Desenho.boneco(self, Vector2(cx, rg.end.y - 30.0 - pulo2), 1.5, 1.0, 0, melhor.pecas, 0.0, t * 3.0, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, 0, false)
		Desenho.sem_sombra = false
		_t(melhor.nome, Vector2(rg.position.x + 150.0, rg.position.y + 100.0), 26, C_TEXTO)
		_t("Nível %d" % melhor.nivel, Vector2(rg.position.x + 150.0, rg.position.y + 132.0), 20, C_TEXTO2)
	# o que se abriu
	var ro := Rect2(660, 345, 330, 145)
	_painel_gato(ro, false)
	_t("O que foi liberado", Vector2(ro.position.x, ro.position.y + 40.0), 20, C_NOME, ro.size.x)
	# 2º ato vencido: a casa e o lado de fora são dos gatos, e as ruas do bairro (3º ato) se abrem
	var liberados: Array = ["As ruas do bairro foram abertas: 3º ato", "Invasão sem fim e metas no fichário"]
	if bairro:
		liberados = ["Torre: quarta vaga de módulo", "Nível 40: quarta herança", "Invasão sem fim e metas"]
	var yo: float = ro.position.y + 68.0
	for txt in liberados:
		_pata(0, Vector2(ro.position.x + 26.0, yo - 20.0), 1)
		for l in _quebra(txt, 17, ro.size.x - 90.0):
			_t(l, Vector2(ro.position.x + 52.0, yo), 17, C_TEXTO)
			yo += 21.0
		yo += 3.0
