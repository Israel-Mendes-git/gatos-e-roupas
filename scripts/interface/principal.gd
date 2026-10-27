extends Control
## Tela principal: mapa da casa (campanha), fase de guarda-roupa (arrastar e soltar)
## e a ligação com o combate (Campo).

# Os valores de GUARDA/COMBATE/FIM ficam como eram; MAPA e TITULO entram no fim.
enum Modo { GUARDA, COMBATE, FIM, MAPA, TITULO }

# Mapa da casa: true = casa em corte (mapa_casa.gd); false = os cinco cartões de antes, intactos.
const MAPA_EM_CORTE := true
const V := preload("res://scripts/interface/vfx_px.gd")   # pedaços de pixel art dos efeitos (painel de fim)

const ESC_G := 1.875   # 6 px de tela por pixel do sprite (GATO_K 3,2): escala inteira, 2 quadradinhos da grade PX de 3 px
const PE_Y := 418.0
const TORRE_G := Vector2(24, 422)
const PAINEL := Rect2(215, 466, 760, 250)
const PREVIA := Rect2(990, 16, 275, 330)
const BIGORNA := Rect2(990, 358, 275, 196)   # painel "Promover": título, explicação e os dois alvos
const ALVO_CARRETEL := Rect2(998, 444, 129, 102)   # solta aqui: sobe o nível (custa blocos)
const ALVO_ESTRELA := Rect2(1135, 444, 129, 102)   # solta aqui: sobe a raridade (custa troféus)
const FUSAO_R := Rect2(340, 190, 600, 280)         # confirmação de fusão
const FUSAO_OK := Rect2(380, 408, 220, 48)
const FUSAO_NAO := Rect2(680, 408, 220, 48)
const TILE := 44.0
const TILE_PASSO := 48.0
const TILE_COLS := 14
const TILE_LINHAS := 4
const TILE_Y0 := 506.0
const ABA_TODAS := -1
const ABA_NOVAS := 4
const ABA_FANTASIAS := 5   # grade com as fantasias inteiras: um clique veste a fantasia no gato
const FANT_COLS := 7
const FANT_W := 98.0
const FANT_H := 102.0
const FANT_GAP := 4.0
const FANT_ESC := 0.78   # tamanho do gato dentro do cartão
const FANT_LINHAS := 2   # linhas de cartões visíveis (são 3 no total: a roda do mouse e as setas rolam)
# situação de cada peça de uma fantasia, em relação ao gato que vai vesti-la
const FS_GATO := 0    # o próprio gato já veste
const FS_GUARDA := 1  # parada no guarda-roupa
const FS_OUTRO := 2   # vestida por outro gato
const FS_NAO := 3     # o jogador ainda não tem
const ABA_NOMES: Array[String] = ["Cabeça", "Corpo", "Mão", "Acessório"]
const COR_SLOT: Array[Color] = [Color(0.3, 0.38, 0.55), Color(0.28, 0.5, 0.36), Color(0.55, 0.4, 0.28), Color(0.48, 0.32, 0.5)]
const COR_COMODO: Array[Color] = [Color(0.35, 0.5, 0.78), Color(0.72, 0.45, 0.3), Color(0.8, 0.7, 0.25), Color(0.55, 0.4, 0.7), Color(0.25, 0.55, 0.5), Color(0.4, 0.68, 0.32), Color(0.6, 0.6, 0.66), Color(0.3, 0.36, 0.7), Color(0.85, 0.6, 0.3), Color(0.6, 0.42, 0.3), Color(0.62, 0.12, 0.22), Color(0.95, 0.5, 0.15), Color(0.2, 0.7, 0.8), Color(0.85, 0.2, 0.12), Color(0.55, 0.3, 0.8)]
const VENCIDO_GENERO: Array[String] = ["vencido", "vencida", "vencida", "vencido", "vencido", "vencido", "vencida", "vencido", "vencida", "vencida", "vencido", "vencido", "vencido", "vencida", "vencidos"]
const ARTIGO: Array[String] = ["o", "a", "a", "o", "o", "o", "a", "o", "a", "a", "o", "o", "o", "a", "os"]
const CARTAO_W := 224.0
const CARTAO_H := 470.0
# Botão da oficina da torre: um lugar no mapa e outro no guarda-roupa (abaixo dos módulos montados)
const TORRE_BT_MAPA := Rect2(1040, 12, 160, 48)
const TORRE_BT_GUARDA := Rect2(20, 514, 160, 42)
const FICH_BT_MAPA := Rect2(866, 12, 164, 48)
const FICH_BT_GUARDA := Rect2(20, 666, 160, 36)
const ATELIE_BT_MAPA := Rect2(692, 12, 164, 48)   # só aparece com o fichário completo
const ATELIE_BT_GUARDA := Rect2(20, 624, 160, 36)
const ROTULO_ATELIE := "Ateliê"
const MOD_SLOT_Y := 484.0          # fileira dos módulos montados, junto da torre desenhada
const MOD_SLOT := 26.0
const MOD_SLOT_X0 := 20.0
const MOD_SLOT_PASSO := 30.0

# Molduras do pacote "Cryo's Mini GUI" (imagens em 4x: cada pixel original ocupa 4 pixels).
# Desenhamos sempre em 1x (4 px por pixel original) ou 0,5x (2 px), escalas inteiras do original.
const GUI_TEX: Texture2D = preload("res://assets/terceiros/gui/gui_4x.png")
const BOT_TEX: Texture2D = preload("res://assets/terceiros/gui/botoes_4x.png")
const R_MADEIRA := Rect2(8, 136, 80, 80)    # moldura de madeira com cantoneiras
const M_MADEIRA := Vector4(28, 28, 28, 28)
const R_FINA := Rect2(100, 4, 88, 88)       # contorno fino escuro
const M_FINA := Vector4(16, 16, 16, 16)
const R_PAPEL := Rect2(384, 0, 96, 96)      # papel
const M_PAPEL := Vector4(28, 28, 28, 28)
const R_BT_N := Rect2(132, 4, 88, 56)       # botão solto
const R_BT_P := Rect2(228, 8, 88, 52)       # botão apertado
const M_BT := Vector4(16, 16, 16, 16)
const ICO_VIDA := Rect2(256, 256, 32, 32)
const ICO_FORCA := Rect2(416, 256, 32, 32)
const ICO_AGIL := Rect2(320, 256, 32, 32)
const ICO_RAIO := Rect2(352, 256, 32, 32)
const ICO_ATR: Array[Rect2] = [ICO_VIDA, ICO_FORCA, ICO_AGIL]
const COR_MADEIRA := Color(0.36, 0.22, 0.13)
const COR_TINTA := Color(1.0, 0.94, 0.8)        # texto claro sobre madeira
const COR_TINTA_ESC := Color(0.22, 0.12, 0.06)  # texto escuro sobre bege

## Botão que se pinta com a moldura do pacote (a pintura é feita por `pintar`, no dono).
class BotaoArte extends Button:
	var tom: Color = Color.WHITE
	var tam_fonte: int = 24
	var esc: float = 1.0
	var brilho: bool = false
	var t_ui: float = 0.0
	var pintar: Callable
	var _sig: Array = []
	var _qd: int = 0
	func _process(delta: float) -> void:
		if visible:
			t_ui += delta
			# só repinta quando algo muda (estado do botão, texto, tamanho, cor) ou quando pulsa (brilho);
			# os botões com pintura própria (fichário, torre) leem estado externo: repintam a cada 6 quadros
			var sig: Array = [get_draw_mode(), disabled, text, size, tom, tam_fonte, esc]
			_qd += 1
			if brilho or sig != _sig or (pintar.is_valid() and pintar.get_method() != &"_pintar_botao" and _qd % 6 == 0):
				_sig = sig
				queue_redraw()
	func _draw() -> void:
		if pintar.is_valid():
			pintar.call(self)

## Nó que fica por último na árvore para ver o Esc antes dos menus (cancelar arrasto, fechar ajuda e resumo).
class Guardiao extends Node:
	var tratar: Callable
	func _input(ev: InputEvent) -> void:
		if tratar.is_valid() and bool(tratar.call(ev)):
			get_viewport().set_input_as_handled()

## Camada de topo: filha de `principal.gd`, fica acima de todos os botões. Dicas, arrasto, avisos e janelas modais são
## desenhadas aqui (Controls filhos sempre pintam por cima do `_draw` do pai; sem esta camada a caixa de texto ficava atrás dos botões).
class CamadaTopo extends Control:
	var dono: Control
	func _process(_delta: float) -> void:
		if visible:
			queue_redraw()
	func _draw() -> void:
		if dono != null:
			dono._desenhar_topo(self)

var _c: CanvasItem                   # onde as funções de desenho pintam: o próprio nó ou a camada de topo
var camada_topo: CamadaTopo
var _topo_fila: Array = []           # o que o `_draw` pediu para pintar por cima dos botões (Callables)
var modo: Modo = Modo.MAPA
var estado: Estado
var campo: Campo
const AQUECEDOR := preload("res://scripts/arte/aquecedor.gd")
var aquecedor: Node2D = null          # pré-aquece os caches de arte fora da vista (ver aquecedor.gd)
var t: float = 0.0
var mouse: Vector2 = Vector2(-500, -500)
var arrasto: Dictionary = {}
# Renomear gato no guarda-roupa: caixa de texto sobre a plaquinha do nome.
const NOME_MAX := 12
var nome_edit: LineEdit
var nome_idx: int = -1
var nome_aviso: String = ""
var nome_aviso_t: float = 0.0
## Sessão guardada ao sair para o menu principal no meio de um cômodo: -1, Modo.GUARDA ou Modo.COMBATE.
## "Continuar" no título devolve o jogador exatamente a ela.
var suspenso: int = -1
var fusao: Dictionary = {}          # confirmação aberta: {"base": Peca, "outra": Peca}
var fusao_bloq: Control             # cobre a tela (abaixo dos menus) enquanto a confirmação está aberta
var efeito_peca: Dictionary = {}    # brilho breve numa peça que acabou de fundir ou subir de raridade
var msg_painel: String = ""         # recado do painel "Promover" quando uma ação é negada
var msg_painel_t: float = 0.0
var _pares: Dictionary = {}         # tipo -> quantas peças existem quando alguma dupla ainda pode fundir
var faiscas: Array = []
var tijolos_voando: Array = []
var negado: float = 0.0
var velocidade: int = 1

# ---- polimento do guarda-roupa: seleção, atalhos, avisos, resumo e retorno visual
const MAPA_BT_GUARDA := Rect2(20, 560, 76, 34)      # coluna da esquerda: Mapa e pausa lado a lado
const PAUSA_BT_GUARDA := Rect2(100, 560, 80, 34)
const MELHOR_R := Rect2(20, 598, 160, 30)           # "Vestir melhor" (gato selecionado)
const VESTIR_TIME_R := Rect2(20, 632, 92, 30)
const DESFAZER_R := Rect2(116, 632, 64, 30)
const FILTRO_R := Rect2(229, 472, 158, 26)          # chip do filtro por fantasia (no lugar do título do painel)
const CHIP_AV := Rect2(990, 664, 235, 36)           # resumo dos avisos junto do LUTAR
const AJUDA_BT := Rect2(1229, 664, 36, 36)
const AJUDA_BT_TOPO := Rect2(1224, 66, 36, 34)    # "?" no mapa e na luta: sob o botão de pausa / velocidade
const VOO_DUR := 0.34
const RESUMO_PASSO := 0.3
const AJUDA_ATALHOS: Array[String] = [
	"Clique numa peça do guarda-roupa: veste no gato selecionado (ou no primeiro com o espaço livre). Clique numa peça vestida: devolve.",
	"Arraste uma peça: no gato veste; no carretel sobe o nível; na estrela sobe a raridade; sobre uma igual, funde. Esc cancela o arrasto.",
	"Clique num gato para selecioná-lo. Teclas 1 a 5 também. Clique na tarja de uma fantasia para filtrar o guarda-roupa por ela.",
	"Lápis acima do nome (ou duplo clique no nome): dá outro nome ao gato. Enter confirma, Esc desiste.",
	"Q / E ou Tab: troca de aba.   V: vestir o time.   Z: desfazer.   F: fichário.   T: oficina da torre.   ? : esta ajuda.",
	"Espaço ou Enter: LUTAR.   Botão direito numa peça: abre o fichário na fantasia dela.",
]
const AJUDA_REGRAS: Array[String] = [
	"Fantasia: grupo de peças da mesma família. Com 2 ou 3 peças da mesma fantasia num gato vem um bônus; com as 4 (cabeça, corpo, mão e acessório) ele libera o poder da fantasia.",
	"Raridade: comum, rara, épica, lendária, mítica e miaujestosa (esta só reforçando uma mítica). Mais raridade dá mais efeito e mais espaço para marcas.",
	"Marca: quando um gato cai na luta, a roupa dele ganha uma marca para sempre. Cada peça comporta um número limitado delas.",
	"Promover (carretel): sobe o nível da peça e custa blocos. Reforçar (estrela): sobe a raridade e custa troféus.",
	"Fundir: peça repetida que cai na luta se funde sozinha com a que você já tem, que fica melhor. Você nunca tem duas iguais paradas.",
	"Linha: Frente, Meio ou Fundo define onde o gato luta. Clique no botão dele para alternar.",
	"Números: passe o mouse no nome do gato para ver vida, dano e o resto. Antes de cada onda dá para arrastar os gatos, dar ordens e marcar um alvo.",
	"Treino: cada nível do gato dá 1 ponto. Gaste em Vida, Força ou Agilidade. A cada 10 níveis ele incorpora o poder da fantasia completa que veste e passa a soltá-lo sozinho na luta.",
]

var sel: int = -1                      # gato selecionado (-1 = nenhum)
var filtro_cj: int = -1                # fantasia que filtra o guarda-roupa (-1 = todas)
var desfazer: Dictionary = {}          # {"foto": roupas de cada gato, "rotulo": texto} da última montagem automática
var derrota_info: Dictionary = {}      # causa e dica da última derrota (ver _causa_derrota)
var derrota_chefe: int = -1
var aviso_cursor: String = ""          # recado junto do cursor (motivo de uma ação negada ou resultado)
var aviso_cursor_t: float = 0.0
var aviso_cursor_cor: Color = Color(1.0, 0.5, 0.45)
var ajuda_aberta: bool = false
var avisos_aberto: bool = false
var avisos_cache: Array = []
var guarda_t: float = 0.0              # tempo desde que o guarda-roupa abriu (Espaço não luta logo ao voltar)
var fant_recente: int = -1             # última fantasia completada (F abre o fichário nela)
var hover_id: String = ""              # o que está sob o mouse (som de hover ao trocar)
var _avisos_t: float = 0.0
var btn_melhor: BotaoArte
var btn_time: BotaoArte
var btn_desf: BotaoArte
var btn_ajuda: BotaoArte
var bloq_tela: Control                 # cobre a tela (abaixo dos menus) com o resumo ou a ajuda abertos
var pulos: Dictionary = {}             # Vector2i(gato, espaço) -> tempo desde que a peça encaixou
var voos: Array = []                   # peças voando de um lugar a outro
var flutuantes: Array = []             # textos que sobem e somem
var claroes: Array = []              # clarões de fantasia completada
var _rect_fant: Array = []             # [Rect2, fantasia, gato] das tarjas desenhadas no último quadro
var resumo_pend: Array = []            # o que mostrar ao voltar da luta
var resumo: Dictionary = {}            # resumo em exibição: {"itens", "t", "tocados", "fim"}
var guardiao: Guardiao

# guarda-roupa com abas e rolagem
var aba: int = ABA_TODAS
var _coberto_ant: bool = false   # fichário ou oficina estavam abertos no quadro anterior (ver _process)
var _coberto_q: int = 0
var _cont_aba_q: int = -1          # quadro em que _cont_aba foi calculado (cache só do desenho)
var _cont_aba: Array[int] = []
var _mapa_guarda_q: int = -1       # idem para o mapa "melhor peça de cada tipo" do desenho
var _mapa_guarda_c: Dictionary = {}
var _mapa_guarda_sig: int = 0
var _sig_q: int = -1
var _sig_v: int = 0
var _pares_sig: int = -1
var _quebrar_c: Dictionary = {}
var _tam_cabe_c: Dictionary = {}   # cache de _tam_cabe: a fonte não muda
var rolagem: int = 0  # primeira linha visível
var _lista: Array[Peca] = []
var _lista_suja: bool = true
var _lista_n: int = -1

# campanha
var drops_fase: Array[Peca] = []   # peças que caíram nesta fase (para o painel de fim)
var fim_pecas: Array[Peca] = []
var confirma_nova: float = 0.0
var _chefes_mapa: Array = []

# time: avisos de nocaute, subida de nível e boneco novo
var nocauteados: Array[Boneco] = []   # quem caiu na última onda (a lógica já os levantou)
var niveis_ini: Dictionary = {}       # Boneco -> nível ao entrar na fase (para o painel de fim)
var aviso: String = ""                # recado no guarda-roupa depois de uma onda
var aviso_t: float = 0.0
var novos_no_time: Array[String] = [] # nomes que entraram ao vencer a fase

var treino_explicado: bool = false     # a explicação de uma linha já foi mostrada
var btn_lutar: BotaoArte
var btn_vel: BotaoArte
var _idioma_vis: String = ""   # idioma para o qual os rótulos dos botões foram montados
var btn_mapa: BotaoArte
var mapa_casa: MapaCasa   # a casa em corte (só desenha e escolhe o destaque)
var btn_nova: BotaoArte
var btn_voltar: BotaoArte
var btn_pausa: BotaoArte
var btn_torre: BotaoArte
var oficina: Oficina
var fichario: Fichario
var btn_fich: BotaoArte
var btn_atelie: BotaoArte
var atelie_tela: AtelieTela
var menus: Menus
var tutorial: Tutorial     # tutorial guiado, treino do título e aulas de primeira vez (tutorial.gd)
var _real: Dictionary = {}  # sessão verdadeira, guardada enquanto o treino do título (partida descartável) roda
var tem_save: bool = false   # há campanha gravada em disco (mostra "Continuar" no título)
var fim_painel: ColorRect
var fim_titulo: Label
var fim_sub: Label
var fim_info: Label
var fim_torre: Label                  # troféus ganhos e módulo novo, no painel de fim
var trofeus_luta: int = 0             # troféus ao começar a luta atual
var trofeus_fase: int = 0             # troféus ganhos na fase em curso
var modulos_novos: Array[int] = []    # módulos liberados ao vencer esta fase
var fim_time: Label
var fim_rect: Rect2 = Rect2(170, 50, 940, 610)  # moldura do painel de fim, ajustada ao conteúdo
var fim_ic_y: float = 372.0                      # topo da fileira de peças ganhas
# pós-campanha: invasão sem fim, metas do fichário e tela de final
var metas_selo: Array[String] = []    # metas cumpridas que o jogador ainda não viu na aba "Metas" (selo no botão Fichário)
var invasao_rec_ini: int = 0          # recorde do cômodo ao começar a invasão (para "Novo recorde!")
var _rect_her_feita: Array = []        # [Rect2, índice do gato, fantasia] das caixas roxas de herança já incorporada (para a dica)
var _rect_heranca: Array = []       # [Rect2, índice do gato] das caixas "Herança pronta!" desenhadas neste quadro
var dicas_heranca: Array = []          # [id, texto] das heranças incorporadas na última onda (viram balão no guarda-roupa)
var fim_invasao: bool = false         # o painel de fim em exibição é de uma invasão que acabou
var fim_vitoria: bool = false         # ... e o último fim de fase foi vitória
var fim_t: float = 0.0                # s desde que o painel de fim abriu (entrada animada)
var fim_som_n: int = 0                # peças do painel de fim que já entraram (cada uma com som)
const FIM_PECA_0 := 0.75              # s até a primeira peça entrar no painel de fim

func _ready() -> void:
	_c = self
	randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Menus.carregar_opcoes()
	var cfg := ConfigFile.new()
	if cfg.load(Menus.cfg_caminho) == OK:
		treino_explicado = bool(cfg.get_value("ui", "treino_explicado", false))
	velocidade = Menus.velocidade_padrao
	if Menus.tela_cheia:
		Menus.aplicar_janela()
	estado = Estado.new()
	tem_save = estado.carregar()
	if tem_save and estado.em_curso:
		suspenso = Modo.GUARDA   # o jogo fechou no meio de um cômodo: "Continuar" volta ao guarda-roupa da mesma onda
	if tem_save:
		estado.persistir = true
	else:
		# sem gravação: o time de começo aparece no título, mas nada é gravado até "Nova campanha"
		estado.novo_jogo()
	for f in range(1, Fases.TOTAL * 3 + 1):
		_chefes_mapa.append(Balanco.assinatura(f, 0))
	mapa_casa = MapaCasa.new(self)
	_preparar_fundo()
	campo = Campo.new()
	campo.visible = false
	campo.terminou.connect(_on_campo_terminou)
	add_child(campo)
	btn_lutar = _botao(Idioma.t("LUTAR"), Rect2(990, 560, 275, 98), Color(1.0, 0.42, 0.34), 44)
	btn_lutar.pressed.connect(func() -> void: menus.ir(_lutar))
	btn_lutar.brilho = true
	btn_mapa = _botao(Idioma.t("Mapa"), MAPA_BT_GUARDA, Color(0.8, 0.62, 0.45), 18)
	btn_mapa.pressed.connect(func() -> void: menus.ir(_voltar_mapa))
	btn_vel = _botao("%dx" % velocidade, Rect2(1140, 12, 120, 52), Color(0.6, 0.72, 1.0), 28)
	btn_vel.pressed.connect(_trocar_velocidade)
	btn_vel.visible = false
	btn_nova = _botao(Idioma.t("Nova campanha"), Rect2(48, 652, 230, 48), Color(0.95, 0.5, 0.42), 18)
	btn_nova.pressed.connect(_pedir_nova_campanha)
	# tela de fim de fase (vitória ou derrota)
	fim_painel = ColorRect.new()
	fim_painel.color = Color(0, 0, 0, 0)
	fim_painel.position = Vector2.ZERO
	fim_painel.size = Vector2(1280, 720)
	fim_painel.visible = false
	add_child(fim_painel)
	fim_titulo = _rotulo_fim(Rect2(190, 92, 900, 80), 64, Desenho.DOURADO)
	fim_sub = _rotulo_fim(Rect2(250, 178, 780, 56), 18, Color(1, 0.95, 0.85))
	fim_time = _rotulo_fim(Rect2(250, 238, 780, 56), 18, Color(0.65, 1.0, 0.7))
	fim_torre = _rotulo_fim(Rect2(250, 322, 780, 34), 18, Color(1.0, 0.85, 0.35))
	fim_torre.autowrap_mode = TextServer.AUTOWRAP_OFF   # linhas curtas: sem quebra, altura previsível
	fim_info = _rotulo_fim(Rect2(250, 322, 780, 34), 22, Color(1, 0.92, 0.7))
	btn_voltar = _botao(Idioma.t("Voltar ao mapa"), Rect2(470, 566, 340, 72), Color(0.55, 0.9, 0.5), 30)
	btn_voltar.pressed.connect(func() -> void: menus.ir(_depois_do_fim))
	remove_child(btn_voltar)
	fim_painel.add_child(btn_voltar)
	btn_pausa = _botao("II", Rect2(1210, 12, 56, 48), Color(0.8, 0.62, 0.45), 22)
	btn_pausa.pressed.connect(func() -> void: menus.abrir_pausa())
	btn_melhor = _botao(Idioma.t("Vestir melhor"), MELHOR_R, Color(0.62, 0.92, 0.6), 16)
	btn_melhor.pressed.connect(_vestir_melhor)
	btn_melhor.tooltip_text = Idioma.t("Monta as melhores fantasias para o gato selecionado (V = o time todo).")
	btn_time = _botao(Idioma.t("Vestir o time"), VESTIR_TIME_R, Color(0.72, 0.9, 0.55), 13)
	btn_time.pressed.connect(_vestir_time)
	btn_time.tooltip_text = Idioma.t("Monta as melhores fantasias para todos os gatos (tecla V).")
	btn_desf = _botao(Idioma.t("Desfazer"), DESFAZER_R, Color(0.95, 0.78, 0.5), 13)
	btn_desf.pressed.connect(_desfazer)
	btn_desf.tooltip_text = Idioma.t("Volta as roupas como estavam antes da última montagem automática (tecla Z).")
	btn_ajuda = _botao("?", AJUDA_BT, Color(0.62, 0.8, 1.0), 22)
	btn_ajuda.pressed.connect(_ajuda_da_tela)
	btn_ajuda.tooltip_text = Idioma.t("Repete o tutorial desta tela (F1: atalhos e regras).")
	_botoes_guarda(false)
	# camada de menus por cima de tudo (título, pausa, opções, créditos, cortina, dicas)
	menus = Menus.new()
	add_child(menus)
	menus.iniciar(self)
	if Menus.gravar:
		Som.iniciar(self)   # nos testes (Menus.gravar = false) o jogo fica mudo
		Musica.iniciar(self)
	# oficina da torre: depois dos menus, para receber o teclado (Esc) antes deles
	btn_torre = _botao("", TORRE_BT_MAPA, Color(1.0, 0.82, 0.4), 20)
	btn_torre.pintar = _pintar_botao_torre
	btn_torre.pressed.connect(abrir_oficina)
	btn_torre.visible = false
	move_child(btn_torre, menus.get_index())
	fusao_bloq = Control.new()
	fusao_bloq.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fusao_bloq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fusao_bloq.visible = false
	fusao_bloq.gui_input.connect(_clique_fusao)
	add_child(fusao_bloq)
	move_child(fusao_bloq, menus.get_index())
	oficina = Oficina.new()
	add_child(oficina)
	oficina.iniciar(self)
	# fichário de fantasias: por último, para receber o teclado (Esc) antes da oficina e dos menus
	fichario = Fichario.new()
	fichario.estado = estado
	fichario.metas_vistas.connect(func() -> void: metas_selo.clear())
	fichario.ajuda_pedida.connect(func() -> void: tutorial.rever())
	add_child(fichario)
	btn_fich = _botao(Idioma.t("Fichário [F]"), FICH_BT_GUARDA, Color(0.62, 0.8, 1.0), 17)
	btn_fich.pintar = _pintar_botao_fichario
	btn_fich.pressed.connect(abrir_fichario)
	btn_fich.visible = false
	move_child(btn_fich, menus.get_index())
	atelie_tela = AtelieTela.new()
	add_child(atelie_tela)
	atelie_tela.iniciar(self)
	btn_atelie = _botao(Idioma.t("Ateliê"), ATELIE_BT_GUARDA, Color(0.95, 0.62, 0.85), 17)
	btn_atelie.pintar = _pintar_botao_atelie
	btn_atelie.text = ""   # o rótulo é desenhado por _pintar_botao_atelie (com o texto do botão ele saía em dobro: "Ateliêlié")
	btn_atelie.pressed.connect(abrir_atelie)
	btn_atelie.visible = false
	move_child(btn_atelie, menus.get_index())
	bloq_tela = Control.new()
	bloq_tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bloq_tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloq_tela.visible = false
	bloq_tela.gui_input.connect(_clique_bloq)
	add_child(bloq_tela)
	move_child(bloq_tela, menus.get_index())
	# tutorial: logo abaixo dos menus (a cortina e a pausa ficam por cima dele)
	tutorial = Tutorial.new()
	add_child(tutorial)
	move_child(tutorial, menus.get_index())
	camada_topo = CamadaTopo.new()
	camada_topo.dono = self
	camada_topo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	camada_topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(camada_topo)
	move_child(camada_topo, tutorial.get_index())   # acima dos botões, abaixo do tutorial e dos menus
	tutorial.iniciar(self)
	tutorial.migrar()
	tutorial.retomar_se_preciso()
	_montar_nome_edit()
	# por último: vê o Esc antes de todos os outros (arrasto, ajuda e resumo)
	guardiao = Guardiao.new()
	guardiao.tratar = _esc_guarda
	add_child(guardiao)
	aquecedor = AQUECEDOR.new()
	add_child(aquecedor)
	_aquecer_mapa()
	if Menus.pular_titulo:
		_entrar_mapa()
	else:
		ir_para_titulo()

## Monta, aos poucos e fora da vista, o que o mapa e o guarda-roupa desenham pela primeira vez (bichos do mapa,
## chefes dos retratos e as roupas do time): sem isto o primeiro desenho de cada tela travava por 100 a 250 ms.
func _aquecer_mapa() -> void:
	var vazio: Array = [null, null, null, null]
	for fam in 5:
		aquecedor.adicionar_bicho(vazio, Unidade.Tipo.COMUM, fam, false, false, -1, false)
	for li in mini(_chefes_mapa.size(), Fases.TOTAL * 3):
		aquecedor.adicionar_bicho(_chefes_mapa[li], Unidade.Tipo.COMUM, 0, true, false, Fases.chefe_base(li), false)
	for i in estado.bonecos.size():
		aquecedor.adicionar_gato(estado.bonecos[i].pecas, i)

## Ao fechar o jogo, grava o que a gravação adiada ainda não escreveu.
func _exit_tree() -> void:
	if _fundo_tarefa >= 0:
		WorkerThreadPool.wait_for_task_completion(_fundo_tarefa)
		_fundo_tarefa = -1
	Estado.gravar_pendente()

func _rotulo_fim(r: Rect2, tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", UIComum.tam(tam))
	l.add_theme_color_override("font_color", cor)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5 if tam > 30 else 3)
	fim_painel.add_child(l)
	return l

func _botao(txt: String, r: Rect2, cor: Color, tam: int) -> BotaoArte:
	var bt := BotaoArte.new()
	bt.text = txt
	bt.position = r.position
	bt.size = r.size
	bt.tom = cor
	bt.tam_fonte = tam
	bt.esc = 1.0
	bt.pintar = _pintar_botao
	bt.focus_mode = Control.FOCUS_NONE
	bt.add_theme_font_size_override("font_size", UIComum.tam(tam))
	# o texto é desenhado por _pintar_botao; o do próprio Button fica invisível
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_hover_pressed_color", "font_focus_color", "font_outline_color"]:
		bt.add_theme_color_override(k, Color(0, 0, 0, 0))
	for k in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		bt.add_theme_stylebox_override(k, StyleBoxEmpty.new())
	add_child(bt)
	bt.pressed.connect(func() -> void: Menus.reg("botão do jogo '%s' apertado" % (bt.text if bt.text != "" else bt.name)))
	bt.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bt.mouse_entered.connect(func() -> void: Som.tocar("hover", 1.0, 0.05, -10.0))
	bt.pressed.connect(func() -> void: Som.tocar("clique"))
	return bt

## Só diagnóstico: anota cada clique e as teclas de menu, com o controle que estava sob o mouse.
func _input(ev: InputEvent) -> void:
	if not Menus.registrar_entrada:
		return
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			var h: Control = get_viewport().gui_get_hovered_control()
			var nome: String = "nenhum"
			if h != null:
				nome = "%s (%s%s)" % [h.name, h.get_class(), (", texto '%s'" % (h as Button).text) if h is Button else ""]
			Menus.reg("CLIQUE %s botão %d em %s janela %s; modo=%d; sob o mouse: %s" % ["aperto" if mb.pressed else "soltura", mb.button_index, str(mb.position), str(get_window().size), modo, nome])
	elif ev is InputEventKey:
		var k: InputEventKey = ev as InputEventKey
		if k.pressed and not k.echo and k.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_F, KEY_T]:
			Menus.reg("TECLA %s; modo=%d" % [OS.get_keycode_string(k.keycode), modo])

# ------------------------------------------------------------------ fluxo
## Vai direto ao mapa da casa, sem passar pelo título (scripts de teste).
func ir_para_mapa() -> void:
	menus.fechar_tudo()
	_entrar_mapa()

func ir_para_titulo() -> void:
	if not _real.is_empty():
		encerrar_treino()   # saiu do treino pela pausa: a campanha verdadeira volta como estava
	# sair no meio de um cômodo guarda a sessão: "Continuar" devolve o jogador ao ponto exato
	# (guarda-roupa da mesma onda, ou a luta parada onde estava). Nada de recolher o time aqui.
	if modo == Modo.GUARDA or modo == Modo.COMBATE:
		suspenso = modo
		estado.salvar()
	fusao = {}
	menus.fechar_tudo()
	if suspenso == Modo.COMBATE:
		campo.process_mode = Node.PROCESS_MODE_DISABLED   # fechar_tudo() a destravou; a luta fica parada atrás do título
	_fechar_janelas()
	modo = Modo.TITULO
	arrasto = {}
	campo.visible = false
	for b in [btn_vel, btn_lutar, btn_mapa, btn_nova, btn_pausa, btn_torre, btn_fich]:
		b.visible = false
	btn_atelie.visible = false
	_botoes_guarda(false)
	resumo = {}
	ajuda_aberta = false
	avisos_aberto = false
	fim_painel.visible = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	menus.mostrar_titulo(tem_save)

## "Continuar" do título: volta ao que o jogador fazia nesta sessão; sem cômodo em curso, vai ao mapa.
func continuar() -> void:
	var s: int = suspenso
	suspenso = -1
	if s == Modo.GUARDA:
		menus.fechar_tudo()
		_entrar_guarda(true)
	elif s == Modo.COMBATE:
		_retomar_luta()
	else:
		ir_para_mapa()

## Joga fora a sessão guardada (campanha nova ou apagada); uma luta guardada é encerrada sem resultado.
func _descartar_sessao() -> void:
	if modo == Modo.COMBATE or suspenso == Modo.COMBATE:
		campo.finalizado = true
		campo.process_mode = Node.PROCESS_MODE_INHERIT
	suspenso = -1
	fusao = {}
	if modo != Modo.TITULO:
		modo = Modo.MAPA

func _retomar_luta() -> void:
	menus.fechar_tudo()
	modo = Modo.COMBATE
	arrasto = {}
	fusao = {}
	btn_lutar.visible = false
	btn_mapa.visible = false
	_botoes_guarda(false)
	btn_vel.visible = true
	_ajuda_em(AJUDA_BT_TOPO)
	btn_vel.text = "%dx" % velocidade
	btn_pausa.visible = true
	btn_pausa.position = Vector2(1070, 12)
	btn_pausa.size = Vector2(56, 48)
	btn_torre.visible = false
	btn_fich.visible = false
	_fechar_janelas()
	campo.visible = true
	campo.velocidade = velocidade
	campo.process_mode = Node.PROCESS_MODE_INHERIT
	mouse_default_cursor_shape = Control.CURSOR_ARROW

## Desistir da fase em curso (guarda-roupa ou luta) e voltar ao mapa; as roupas ficam.
func desistir_fase() -> void:
	suspenso = -1
	if modo == Modo.COMBATE:
		campo.finalizado = true
		estado.recolher()
		estado.salvar()
		_entrar_mapa()
	elif modo == Modo.GUARDA:
		_voltar_mapa()
	else:
		_entrar_mapa()

## Botão "Tutorial" do título: roda o roteiro guiado numa partida descartável (nada vai para o save).
func iniciar_treino() -> void:
	_real = {"estado": estado, "tem_save": tem_save, "suspenso": suspenso, "vel": velocidade}
	if suspenso == Modo.COMBATE:
		campo.finalizado = true   # a luta guardada é encerrada: o campo vai ser usado pelo treino
		campo.process_mode = Node.PROCESS_MODE_INHERIT
	suspenso = -1
	fusao = {}
	arrasto = {}
	estado = Estado.new()
	estado.persistir = false
	estado.novo_jogo()
	faiscas.clear()
	tijolos_voando.clear()
	drops_fase.clear()
	resumo = {}
	resumo_pend.clear()
	desfazer = {}
	nocauteados.clear()
	aviso = ""
	aviso_t = 0.0
	sel = -1
	filtro_cj = -1
	aba = ABA_TODAS
	rolagem = 0
	_lista_suja = true
	modo = Modo.MAPA
	_entrar_mapa()
	tutorial.comecar(Tutorial.Fonte.TREINO)

## Fim do treino (ou saída pela pausa): devolve a campanha verdadeira e vai ao título.
func sair_do_treino() -> void:
	encerrar_treino()
	ir_para_titulo()

func encerrar_treino() -> void:
	if _real.is_empty():
		return
	var r: Dictionary = _real
	_real = {}
	campo.finalizado = true
	campo.segurar = false
	campo.visible = false
	campo.process_mode = Node.PROCESS_MODE_INHERIT
	tutorial.parar()
	estado.tutorial_facil = false
	if int(r["suspenso"]) == Modo.COMBATE:
		# a luta guardada foi encerrada: volta ao guarda-roupa da mesma onda, como se o jogo tivesse sido reaberto
		estado = Estado.new()
		estado.persistir = true
		estado.carregar()
		suspenso = Modo.GUARDA if estado.em_curso else -1
	else:
		estado = r["estado"]
		suspenso = int(r["suspenso"])
	tem_save = bool(r["tem_save"])
	velocidade = int(r["vel"])
	btn_vel.text = "%dx" % velocidade
	campo.velocidade = velocidade
	modo = Modo.MAPA   # (assim ir_para_titulo não guarda o treino como sessão suspensa)
	arrasto = {}
	fusao = {}
	resumo = {}
	resumo_pend.clear()
	desfazer = {}
	nocauteados.clear()
	sel = -1
	aba = ABA_TODAS
	rolagem = 0
	_lista_suja = true
	menus.fila_dicas.clear()
	menus.dica_atual = {}

func nova_campanha_do_titulo() -> void:
	_descartar_sessao()
	tem_save = true
	_novo_jogo()

func apagar_campanha() -> void:
	_descartar_sessao()
	if estado.persistir:
		estado.cancelar_gravacao()   # a gravação adiada não pode recriar o arquivo apagado
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Estado.ARQUIVO))
	estado = Estado.new()
	estado.persistir = false
	estado.novo_jogo()
	Menus.final_visto = false
	metas_selo.clear()
	tem_save = false
	arrasto = {}
	drops_fase.clear()
	_lista_suja = true
	ir_para_titulo()

func definir_velocidade(v: int) -> void:
	velocidade = clampi(v, 1, 3)
	btn_vel.text = "%dx" % velocidade
	campo.velocidade = velocidade

func _entrar_mapa() -> void:
	modo = Modo.MAPA
	btn_fich.position = FICH_BT_MAPA.position
	btn_fich.size = FICH_BT_MAPA.size
	btn_fich.visible = true
	arrasto = {}
	campo.visible = false
	btn_vel.visible = false
	btn_lutar.visible = false
	btn_mapa.visible = false
	_botoes_guarda(false)
	_ajuda_em(AJUDA_BT_TOPO)
	btn_nova.visible = false   # "Nova campanha" mora no menu principal
	btn_pausa.visible = true
	btn_pausa.position = Vector2(1210, 12)
	btn_pausa.size = Vector2(56, 48)
	resumo = {}
	ajuda_aberta = false
	avisos_aberto = false
	_fechar_janelas()
	_posicionar_torre(TORRE_BT_MAPA)
	fim_painel.visible = false
	confirma_nova = 0.0
	btn_nova.text = Idioma.t("Nova campanha")
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	if mapa_casa != null:
		mapa_casa.reiniciar()
		if estado.schro_liberado() and not estado.feitos.has("schro") and not Menus.dicas_vistas.get("schro_caixa", false):
			# a primeira vez com o bestiário completo: a caixa já vem escolhida e o recado explica
			mapa_casa.escolher_caixa()
			menus.dica("schro_caixa", Idioma.t("Bestiário completo! Algo se mexe na caixa do Sótão. Clique na caixa que treme (ou aperte C) e depois em Abrir a caixa."), true)

func _entrar_guarda(retomando: bool = false) -> void:
	modo = Modo.GUARDA
	btn_fich.position = FICH_BT_GUARDA.position
	btn_fich.size = FICH_BT_GUARDA.size
	btn_fich.visible = true
	fusao = {}
	campo.visible = false
	btn_vel.visible = false
	btn_lutar.visible = true
	btn_mapa.visible = true
	_botoes_guarda(true)
	btn_nova.visible = false
	btn_pausa.visible = true
	btn_pausa.position = PAUSA_BT_GUARDA.position   # coluna da esquerda, ao lado de "Mapa"
	btn_pausa.size = PAUSA_BT_GUARDA.size
	_fechar_janelas()
	_posicionar_torre(TORRE_BT_GUARDA)
	fim_painel.visible = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	_lista_suja = true
	_atualizar_botoes()
	guarda_t = 0.0
	ajuda_aberta = false
	avisos_aberto = false
	voos.clear()
	flutuantes.clear()
	claroes.clear()
	pulos.clear()
	if sel < 0 or sel >= estado.bonecos.size():
		sel = 0
	if retomando:
		return
	filtro_cj = -1
	fant_recente = -1
	desfazer = {}
	_avisos_t = 0.0
	_abrir_resumo()
	menus.dica("vestir", Idioma.t("Clique ou arraste uma peça para vestir o gato."))
	menus.dica("blocos", Idioma.t("Blocos: vida da torre e moeda para promover peças."))
	_dicas_do_gato()

## Ordem do guarda-roupa: fantasia, espaço, raridade (maior primeiro), nível, marcas.
func _antes(a: Peca, b: Peca) -> bool:
	if a.conjunto() != b.conjunto():
		return a.conjunto() < b.conjunto()
	if a.slot() != b.slot():
		return a.slot() < b.slot()
	if a.raridade != b.raridade:
		return a.raridade > b.raridade
	if a.nivel != b.nivel:
		return a.nivel > b.nivel
	if a.marcas.size() != b.marcas.size():
		return a.marcas.size() > b.marcas.size()
	return a.tipo < b.tipo

## Peças da aba atual, ordenadas (guardadas em cache até algo mudar).
func _visiveis() -> Array[Peca]:
	if _lista_suja or _lista_n != estado.guarda.size():
		_lista.clear()
		for p in estado.guarda:
			if filtro_cj >= 0 and p.conjunto() != filtro_cj:
				continue
			if aba == ABA_TODAS or (aba == ABA_NOVAS and p.nova) or (aba >= 0 and aba < Pecas.SLOTS and p.slot() == aba):
				_lista.append(p)
		_lista.sort_custom(_antes)
		_lista_suja = false
		_lista_n = estado.guarda.size()
		rolagem = clampi(rolagem, 0, _rolagem_max())
	return _lista

func _linhas_total() -> int:
	return int(ceil(_visiveis().size() / float(TILE_COLS)))

func _rolagem_max() -> int:
	if aba == ABA_FANTASIAS:
		return maxi(0, int(ceil(_n_cartoes_fant() / float(FANT_COLS))) - FANT_LINHAS)
	var n: int = int(ceil(_lista.size() / float(TILE_COLS)))
	return maxi(0, n - TILE_LINHAS)

func _contar_aba(k: int) -> int:
	if k == ABA_FANTASIAS:
		return _fantasias_prontas()
	# só o desenho chama isto: uma varredura por quadro serve a todas as abas (antes eram 7 varreduras)
	var qd: int = Engine.get_process_frames()
	if _cont_aba_q != qd or _cont_aba.size() != Pecas.SLOTS + 2:
		_cont_aba_q = qd
		_cont_aba.clear()
		_cont_aba.resize(Pecas.SLOTS + 2)   # [0..SLOTS-1] por espaço, SLOTS = novas, SLOTS+1 = todas
		for p in estado.guarda:
			_cont_aba[Pecas.SLOT[p.tipo]] += 1
			if p.nova:
				_cont_aba[Pecas.SLOTS] += 1
		_cont_aba[Pecas.SLOTS + 1] = estado.guarda.size()
	if k == ABA_TODAS:
		return _cont_aba[Pecas.SLOTS + 1]
	if k == ABA_NOVAS:
		return _cont_aba[Pecas.SLOTS]
	if k >= 0 and k < Pecas.SLOTS:
		return _cont_aba[k]
	return 0

func _atualizar_botoes() -> void:
	pass  # (o botão de comprar boneco saiu: o time é fixo)

## Guarda o nível de cada boneco para comparar no fim da fase.
func _anotar_niveis() -> void:
	niveis_ini.clear()
	for b in estado.bonecos:
		niveis_ini[b] = b.nivel

## Nomes de quem subiu de nível desde `ref` (Boneco -> nível).
func _subiram(ref: Dictionary) -> Array[String]:
	var nomes: Array[String] = []
	for b in estado.bonecos:
		if ref.has(b) and b.nivel > int(ref[b]):
			nomes.append(b.nome)
	return nomes

## Texto "A, B e C".
func _lista_nomes(nomes: Array[String]) -> String:
	if nomes.size() <= 1:
		return "".join(nomes)
	return ", ".join(nomes.slice(0, nomes.size() - 1)) + Idioma.t(" e ") + nomes[nomes.size() - 1]

func _pontos_totais() -> int:
	var n: int = 0
	for b in estado.bonecos:
		n += b.pontos
	return n

func _soma_niveis() -> int:
	var n: int = 0
	for b in estado.bonecos:
		n += b.nivel
	return n

## Invasão sem fim no cômodo f (só depois de zerar a campanha).
func _escolher_invasao(f: int) -> void:
	_escolher_fase(f, true)

## Luta secreta da caixa do Sótão (Gato de Schrödinger): só com o bestiário completo.
func _escolher_secreto() -> void:
	if estado.schro_liberado():
		_escolher_fase(4, false, false, true)

func _escolher_fase(f: int, invasao: bool = false, rejogo_casa: bool = false, secreto: bool = false) -> void:
	if f < 1 or f > estado.fase_liberada:
		return
	if mapa_casa != null and mapa_casa.vista_ruas() and not estado.lugar_aberto(3, f):
		return   # Arena e Telhados ainda fechados
	if invasao:
		if not estado.campanha_vencida():
			return
		var fora: bool = mapa_casa != null and mapa_casa.vista_fora() and estado.vencido[f - 1] >= 2
		var ruas: bool = fora and mapa_casa.vista_ruas() and estado.tudo_vencido()
		invasao_rec_ini = estado.recordes[Fases.TOTAL * 2 if ruas else f - 1 + (Fases.TOTAL if fora else 0)]
		estado.iniciar_invasao(f, fora, ruas)
	elif secreto:
		estado.iniciar_secreto()
	elif rejogo_casa:
		estado.iniciar_fase_casa(f)
	else:
		estado.iniciar_fase(f)
	fim_invasao = false
	_anotar_niveis()
	nocauteados.clear()
	aviso = ""
	aviso_t = 0.0
	novos_no_time.clear()
	drops_fase.clear()
	trofeus_fase = 0
	modulos_novos.clear()
	arrasto = {}
	faiscas.clear()
	tijolos_voando.clear()
	aba = ABA_TODAS
	rolagem = 0
	sel = -1
	filtro_cj = -1
	desfazer = {}
	resumo_pend.clear()
	resumo = {}
	estado.salvar()   # o cômodo começado já fica gravado
	_entrar_guarda()

func _voltar_mapa() -> void:
	if modo != Modo.GUARDA:
		return
	estado.recolher()
	estado.salvar()
	_entrar_mapa()

func _pedir_nova_campanha() -> void:
	if confirma_nova > 0.0:
		_novo_jogo()
	else:
		confirma_nova = 3.0
		btn_nova.text = Idioma.t("Confirmar: apagar")

func _lutar() -> void:
	if modo != Modo.GUARDA:
		return
	if not resumo.is_empty():
		_fechar_resumo()   # o clique que pulou o resumo não vira LUTAR sem querer
		return
	modo = Modo.COMBATE
	arrasto = {}
	desfazer = {}
	ajuda_aberta = false
	avisos_aberto = false
	btn_lutar.visible = false
	btn_mapa.visible = false
	_botoes_guarda(false)
	btn_vel.visible = true
	_ajuda_em(AJUDA_BT_TOPO)
	btn_pausa.visible = true
	btn_pausa.position = Vector2(1070, 12)
	btn_pausa.size = Vector2(56, 48)
	campo.visible = true
	campo.velocidade = velocidade
	btn_torre.visible = false
	btn_fich.visible = false   # o fichário não abre na luta nem no painel de fim
	_fechar_janelas()
	trofeus_luta = estado.trofeus
	campo.iniciar(estado)

func _trocar_velocidade() -> void:
	velocidade = velocidade % 3 + 1
	btn_vel.text = "%dx" % velocidade
	campo.velocidade = velocidade

func _on_campo_terminou(vitoria: bool) -> void:
	var bau_onda: Array = campo.sim.bau.duplicate()
	var ganho_tr: int = maxi(0, estado.trofeus - trofeus_luta)
	for p in campo.sim.bau:
		drops_fase.append(p)
	# anota quem caiu e os níveis antes de a lógica levantar o time e dar a experiência
	nocauteados.clear()
	for b in estado.bonecos:
		if not b.vivo:
			nocauteados.append(b)
	var niveis_antes: Dictionary = {}
	for b in estado.bonecos:
		niveis_antes[b] = b.nivel
	var tamanho_antes: int = estado.bonecos.size()
	var vencidas_antes: int = estado.fases_vencidas
	var liberados_antes: Array[int] = []
	for m in Torre.MODULO_NOME.size():
		if estado.modulo_liberado(m):
			liberados_antes.append(m)
	var era_invasao: bool = estado.invasao
	trofeus_fase += maxi(0, estado.trofeus - trofeus_luta)
	trofeus_luta = estado.trofeus
	modulos_novos.clear()
	if vitoria:
		var acabou: bool = estado.encerrar_onda(campo.sim)
		for m in Torre.MODULO_NOME.size():
			if estado.modulo_liberado(m) and not (m in liberados_antes):
				modulos_novos.append(m)
		novos_no_time.clear()
		for k in range(tamanho_antes, estado.bonecos.size()):
			novos_no_time.append(estado.bonecos[k].nome)
		_montar_aviso(_subiram(niveis_antes))
		# resumo da volta: peças, níveis, marcas e troféus (mostrado ao abrir o guarda-roupa)
		resumo_pend.clear()
		var ja_resumo: Array = []
		for q in bau_onda:
			var qr: Peca = estado.fundida_em.get(q, q)   # repetida: mostra a peça que ficou melhor
			if not ja_resumo.has(qr) and (estado.guarda.has(qr) or estado.dono_de(qr) != null):
				ja_resumo.append(qr)
				resumo_pend.append({"tipo": "peca", "p": qr})
		if not estado.fundida_em.is_empty():
			tutorial.pedir("a_fusao")
		estado.fundida_em.clear()
		for b in estado.bonecos:
			if niveis_antes.has(b) and b.nivel > int(niveis_antes[b]):
				resumo_pend.append({"tipo": "nivel", "b": b, "de": int(niveis_antes[b]), "ate": b.nivel})
		for b in nocauteados:
			resumo_pend.append({"tipo": "marca", "b": b})
		if ganho_tr > 0:
			resumo_pend.append({"tipo": "trofeu", "n": ganho_tr})
		if acabou:
			resumo_pend.clear()
		if acabou:
			fim_invasao = false
			menus.ir(_fim_fase.bind(true))
		else:
			menus.ir(_entrar_guarda)
	else:
		derrota_info = _causa_derrota(campo.sim)
		estado.encerrar_derrota(campo.sim)
		fim_invasao = era_invasao
		aviso = ""
		aviso_t = 0.0
		menus.ir(_fim_fase.bind(false))

## Por que a onda foi perdida: {"causa": frase, "dica": conselho}. Lê o que a simulação deixa no fim da luta.
## Se a simulação tiver `perdas` ({Unidade.Tipo ou "chefe": blocos tirados da torre}), usa a contagem exata;
## senão, deduz pelos bichos que sobraram junto da torre.
func _causa_derrota(sim: Simulacao) -> Dictionary:
	derrota_chefe = -1
	var dica_poder: String = Idioma.t("Atordoe o bicho durante o aviso (!) para cancelar o poder.")
	var vivos: int = 0
	for a in sim.aliados:
		if a.vivo and not a.clone:
			vivos += 1
	if estado.tijolos > 0:
		return {"causa": Idioma.t("A onda demorou demais e o tempo acabou."), "dica": Idioma.t("Mais dano ajuda: treine Força, vista armas melhores e use os poderes das fantasias.")}
	if vivos == 0:
		if sim.gatos_por_poder_bicho > 0:
			return {"causa": Idioma.t("Todos os gatos caíram e a torre ficou sozinha (%d por poder de bicho).") % sim.gatos_por_poder_bicho, "dica": dica_poder + Idioma.t(" Vida e peças de corpo seguram o resto.")}
		return {"causa": Idioma.t("Todos os gatos caíram e a torre ficou sozinha."), "dica": Idioma.t("Treine Vida e vista peças de corpo. Gatos fortes na frente protegem os de trás.")}
	var perdas: Variant = sim.get("perdas")
	var chave: Variant = null
	var blocos: int = 0
	if perdas is Dictionary and not (perdas as Dictionary).is_empty():
		for k in perdas:
			if int(perdas[k]) > blocos:
				blocos = int(perdas[k])
				chave = k
	else:
		var cont: Dictionary = {}
		for u in sim.inimigos:
			if u.vivo and u.x < Balanco.TORRE_X + 170.0:
				var kk: Variant = "chefe" if u.chefe else u.tipo
				cont[kk] = int(cont.get(kk, 0)) + 1
				if u.chefe:
					cont[kk] = 99
					derrota_chefe = estado.lugar_chefe()
		for k in cont:
			if int(cont[k]) > blocos:
				blocos = int(cont[k])
				chave = k
		blocos = 0   # sem contagem exata de blocos: a frase fica sem número
	if chave is String and chave == "chefe":
		var ct: int = clampi(derrota_chefe if derrota_chefe >= 0 else estado.lugar_chefe(), 0, Fases.TOTAL * 3)
		return {"causa": Idioma.t("O chefe %s acabou com a torre.") % Idioma.t(Fases.nome_do_chefe(ct)), "dica": Idioma.t(Fases.fraqueza_do_chefe(ct)) + "." + ((" " + dica_poder) if sim.gatos_por_poder_bicho > 0 else "")}
	var q: String = (Idioma.t(" (%d bloco)") % blocos if blocos == 1 else Idioma.t(" (%d blocos)") % blocos) if blocos > 0 else ""
	match chave:
		Unidade.Tipo.LADRAO:
			return {"causa": (Idioma.t("Os ladrões levaram %d blocos.") % blocos) if blocos > 0 else Idioma.t("Os ladrões levaram os blocos da torre."), "dica": Idioma.t("Marque o Ladrão como alvo na preparação e deixe gatos na linha da frente.")}
		Unidade.Tipo.SALTADOR:
			return {"causa": Idioma.t("Os saltadores pularam os gatos e chegaram à torre%s.") % q, "dica": Idioma.t("Recuar deixa gatos perto da torre para pegar os saltadores.")}
		Unidade.Tipo.GIGANTE:
			return {"causa": Idioma.t("O Grandalhão derrubou a torre%s.") % q, "dica": Idioma.t("Marque o Grandalhão como alvo: o time inteiro foca nele. Dano alto e poderes ajudam.")}
		Unidade.Tipo.BOMBA:
			return {"causa": Idioma.t("Os bichos-bomba explodiram na torre%s.") % q, "dica": Idioma.t("Gatos de longe derrubam as bombas antes de elas chegarem.")}
		Unidade.Tipo.ATIRADOR:
			return {"causa": Idioma.t("Os atiradores derrubaram a torre de longe%s.") % q, "dica": Idioma.t("Deixe gatos em Avançar para alcançá-los, ou marque o Atirador como alvo.")}
	if sim.gatos_por_poder_bicho > 0:
		var causa_pb: String = Idioma.t("Os bichos chegaram à torre e a derrubaram%s, e poderes de bicho derrubaram %d gato.") if sim.gatos_por_poder_bicho == 1 else Idioma.t("Os bichos chegaram à torre e a derrubaram%s, e poderes de bicho derrubaram %d gatos.")
		return {"causa": causa_pb % [q, sim.gatos_por_poder_bicho], "dica": dica_poder + Idioma.t(" Mais gatos na linha da frente seguram o bando.")}
	return {"causa": Idioma.t("Os bichos chegaram à torre e a derrubaram%s.") % q, "dica": Idioma.t("Mais gatos na linha da frente seguram o bando. Treine Força e Vida.")}

## Dicas no balão do gato ao entrar no guarda-roupa: herança (aviso, pendente, feita), números e segundo ato.
func _dicas_do_gato() -> void:
	for d in dicas_heranca:
		menus.dica(str(d[0]), str(d[1]), true)
	dicas_heranca.clear()
	var passo: int = Balanco.HERANCA_NIVEIS
	for b in estado.bonecos:
		var bb: Boneco = b
		if bb.herancas_pendentes() > 0:
			var fc: int = bb.fantasia_completa()
			if fc >= 0:
				menus.dica("her_pend_%s_%d" % [bb.nome, bb.incorporacoes()], Idioma.t("%s: clique em \"Herança pronta!\" para guardar %s.") % [bb.nome, _txt_incorporar(bb, fc)], true)
			else:
				menus.dica("her_falta_%s_%d" % [bb.nome, bb.incorporacoes()], Idioma.t("%s pode guardar um poder: vista uma fantasia completa.") % bb.nome, true)
		elif bb.incorporacoes() < Balanco.BONECO_NIVEL_MAX / passo and bb.nivel % passo >= passo - 2:
			menus.dica("her_aviso_%d" % (bb.incorporacoes() + 1), Idioma.t("No nível %d o gato guarda o poder da fantasia vestida (a mesma de novo sobe o grau).") % ((bb.incorporacoes() + 1) * passo))
	if estado.ato > 1:
		menus.dica("ato_%d" % estado.ato, (Idioma.t("%s: gatos rivais de gangue, que brigam com o seu time antes de ir à torre.") if estado.ato >= 3 else Idioma.t("%s: bichos misturados e com truques novos.")) % Idioma.t(Balanco.ATO_NOME[estado.ato - 1]))
	if estado.fases_vencidas >= 1:
		menus.dica("ficha", Idioma.t("Mouse no nome do gato: vida, dano e números."))

## Nome do ato no meio de uma frase: minúsculo em português ("O ato dois"); em inglês fica "Act Two" (nome próprio).
func _ato_em_frase(i: int) -> String:
	var n: String = Idioma.t(Balanco.ATO_NOME[i])
	return n.to_lower() if Idioma.atual == Idioma.PADRAO else n

## Recado do guarda-roupa depois de uma onda vencida.
func _montar_aviso(subiram: Array[String]) -> void:
	var partes: Array[String] = []
	for hn in estado.herancas_novas:
		var bh: Boneco = hn[0]
		dicas_heranca.append(["her_ok_%s_%d" % [bh.nome, bh.incorporacoes()], Idioma.t("%s incorporou %s.") % [bh.nome, Simulacao.heranca_nome_curto(int(hn[1]), bh.grau_de(int(hn[1])))]])
		partes.append(Idioma.t("%s incorporou %s!") % [bh.nome, Simulacao.heranca_nome(int(hn[1]), bh.grau_de(int(hn[1])))])
	estado.herancas_novas.clear()
	if subiram.size() > 0:
		partes.append(Idioma.t("Subiu de nível: %s.") % _lista_nomes(subiram))
	if nocauteados.size() > 0:
		var nn: Array[String] = []
		for b in nocauteados:
			nn.append(b.nome)
		partes.append(Idioma.t("Nocaute: %s.") % _lista_nomes(nn))
	aviso = "  ".join(partes)
	aviso_t = 9.0 if aviso != "" else 0.0

func _fim_fase(vitoria: bool) -> void:
	modo = Modo.FIM
	campo.visible = false
	btn_pausa.visible = false
	btn_vel.visible = false
	btn_lutar.visible = false
	btn_mapa.visible = false
	_botoes_guarda(false)
	btn_nova.visible = false
	btn_torre.visible = false
	btn_fich.visible = false   # o fichário não abre na luta nem no painel de fim
	_fechar_janelas()
	fim_painel.visible = true
	var fi: int = estado.lugar()
	var nome: String = Idioma.t(Fases.nome_do_lugar(fi))
	var era_secreto: bool = estado.secreto
	var linhas_time: Array[String] = []
	fim_vitoria = vitoria
	if not vitoria and fim_invasao:
		# invasão sem fim: a torre caiu
		var rec: int = estado.recordes[estado.indice_recorde()]
		fim_titulo.text = Idioma.t("Invasão encerrada")
		fim_titulo.add_theme_color_override("font_color", Color(1, 0.55, 0.4))
		fim_sub.text = Idioma.t("Invasão encerrada na onda %d em %s. O time se levantou; o que caiu e os troféus ficam com você.") % [estado.onda_invasao, nome]
		if rec > invasao_rec_ini:
			linhas_time.append((Idioma.t("Novo recorde! Você venceu %d onda em %s (antes: %d).") if rec == 1 else Idioma.t("Novo recorde! Você venceu %d ondas em %s (antes: %d).")) % [rec, nome, invasao_rec_ini])
		elif rec > 0:
			linhas_time.append(Idioma.t("Recorde de %s: onda %d.") % [nome, rec])
		else:
			linhas_time.append(Idioma.t("Nenhuma onda vencida desta vez. Tente de novo!"))
	elif vitoria and era_secreto:
		fim_titulo.text = Idioma.t("Gato de Schrödinger vencido!")
		fim_titulo.add_theme_color_override("font_color", Desenho.DOURADO)
		fim_sub.text = Idioma.t("Vivo e morto ao mesmo tempo, e agora de vez só um. A caixa do Sótão guarda um prêmio para quem a abre de novo.")
	elif vitoria:
		fim_titulo.text = Idioma.t("%s %s!") % [nome, Idioma.t(VENCIDO_GENERO[fi])]
		fim_titulo.add_theme_color_override("font_color", Desenho.DOURADO)
		var sub: String = Idioma.t("O time descansou e segue vestido como estava.")
		if estado.tudo_vencido():
			sub = Idioma.t("A campanha está completa: a casa inteira é sua!")
		elif estado.campanha_vencida():
			var a_at: int = estado.ato_atual()
			var faltam: int = Fases.TOTAL - estado.vencidos_no_ato(a_at)
			if faltam >= Fases.TOTAL and a_at >= 3:
				sub = Idioma.t("%s vencido! Mas as ruas são de gangues de gatos rivais, que vestem as fantasias do lugar. O %s está no mapa: Mercadão, Ferro-velho, Beco, Arena e Telhados.") % [Idioma.t(Balanco.ATO_NOME[a_at - 2]), _ato_em_frase(a_at - 1)]
			elif faltam >= Fases.TOTAL:
				sub = Idioma.t("%s vencido! A casa é sua, mas os bichos fugiram para fora. O %s está no mapa: quintal, garagem, telhado, rua e toca, na ordem que quiser.") % [Idioma.t(Balanco.ATO_NOME[a_at - 2]), _ato_em_frase(a_at - 1)]
			else:
				sub = (Idioma.t("%s: falta %d lugar. Os que ficam para depois chegam mais fortes.") if faltam == 1 else Idioma.t("%s: faltam %d lugares. Os que ficam para depois chegam mais fortes.")) % [Idioma.t(Balanco.ATO_NOME[a_at - 1]), faltam]
		elif estado.fase < Fases.TOTAL:
			sub += Idioma.t(" Próximo: %s.") % Idioma.t(Fases.NOME[estado.fase])
		fim_sub.text = sub
		if novos_no_time.size() > 0:
			linhas_time.append(Idioma.t("Gato novo no time: %s! Agora são %d gatos.") % [_lista_nomes(novos_no_time), estado.bonecos.size()])
	else:
		fim_titulo.text = Idioma.t("Derrota")
		fim_titulo.add_theme_color_override("font_color", Color(1, 0.4, 0.35))
		fim_sub.text = Idioma.t("Desta vez, %s resistiu. O time se levantou; as peças de quem caiu ganharam marcas e o que caiu ficou com você.") % (Idioma.t(ARTIGO[fi]) + " " + nome)
	fim_time.add_theme_color_override("font_color", Color(0.65, 1.0, 0.7))
	if not vitoria and not derrota_info.is_empty():
		# causa e dica (ver _causa_derrota), no topo do bloco de texto, em tom de aviso
		fim_time.add_theme_color_override("font_color", Color(1.0, 0.86, 0.6))
		linhas_time.insert(0, Idioma.t("Dica: %s") % str(derrota_info.get("dica", "")))
		linhas_time.insert(0, Idioma.t("O que houve: %s") % str(derrota_info.get("causa", "")))
	var subiram: Array[String] = _subiram(niveis_ini)
	if subiram.size() > 0:
		linhas_time.append(Idioma.t("Subiram de nível: %s. Gaste os pontos de treino.") % _lista_nomes(subiram))
	fim_time.text = "
".join(linhas_time)
	var linhas_torre: Array[String] = []
	if trofeus_fase > 0:
		linhas_torre.append(Idioma.t("Troféus ganhos: +%d (você tem %d)") % [trofeus_fase, estado.trofeus])
	for m in modulos_novos:
		linhas_torre.append(Idioma.t("Módulo novo na oficina: %s") % Idioma.t(Torre.MODULO_NOME[m]))
	fim_torre.text = "
".join(linhas_torre)
	fim_pecas.clear()
	for p in drops_fase:
		if estado.guarda.has(p):
			fim_pecas.append(p)
	fim_info.text = Idioma.t("Peças ganhas: %d") % fim_pecas.size() if fim_pecas.size() > 0 else Idioma.t("Nenhuma peça nova desta vez.")
	_lista_suja = true
	_ajustar_fim()
	fim_t = 0.0
	fim_som_n = 0
	_animar_fim(0.0)

## Distribui título, textos, peças e botão do fim de fase de cima para baixo e
## encaixa a moldura na altura do conteúdo, centrada na tela.
func _ajustar_fim() -> void:
	var n_sub: int = _quebrar(fim_sub.text, 18, 770.0).size()
	var n_time: int = 0
	if fim_time.text != "":
		for l in fim_time.text.split("
"):
			n_time += _quebrar(l, 18, 770.0).size()
	var n: int = fim_pecas.size()
	var linhas_ic: int = mini(3, int(ceil(n / 16.0)))
	var h_sub: float = n_sub * 23.0 + 6.0
	var h_time: float = n_time * 23.0 + (10.0 if n_time > 0 else 0.0)
	var n_torre: int = 0
	if fim_torre.text != "":
		n_torre = fim_torre.text.split("
").size()
	var h_torre: float = n_torre * 27.0 + (6.0 if n_torre > 0 else 0.0)
	var h_ic: float = 0.0
	if n > 0:
		h_ic = linhas_ic * 56.0 + (28.0 if n > 48 else 0.0) + 10.0
	var total: float = 34.0 + 80.0 + h_sub + h_time + h_torre + 40.0 + h_ic + 16.0 + 72.0 + 34.0
	var topo: float = maxf(20.0, (720.0 - total) * 0.5)
	var larg: float = 940.0 if linhas_ic > 1 else 860.0
	fim_rect = Rect2(640.0 - larg * 0.5, topo, larg, total)
	var y: float = topo + 34.0
	fim_titulo.position = Vector2(190, y)
	fim_titulo.size = Vector2(900, 80)
	y += 80.0
	fim_sub.position = Vector2(250, y)
	fim_sub.size = Vector2(780, n_sub * 23.0 + 4.0)
	y += h_sub
	fim_time.position = Vector2(250, y)
	fim_time.size = Vector2(780, maxf(1.0, n_time * 23.0))
	y += h_time
	fim_torre.position = Vector2(250, y)
	fim_torre.size = Vector2(780, maxf(1.0, n_torre * 27.0))
	y += h_torre
	fim_info.position = Vector2(250, y)
	fim_info.size = Vector2(780, 34)
	y += 40.0
	fim_ic_y = y
	y += h_ic + 16.0
	btn_voltar.position = Vector2(470, y)

## Metas recém-cumpridas viram avisos em sequência (mapa e guarda-roupa) e ganham o selo no Fichário.
func _conferir_avisos_metas() -> void:
	if not _real.is_empty():
		estado.metas_novas.clear()   # no treino as metas não contam nem avisam
		return
	if estado.metas_novas.is_empty():
		return
	if not (modo == Modo.MAPA or modo == Modo.GUARDA) or menus.em_transicao() or menus.tela == Menus.Tela.TITULO:
		return
	var nomes: Dictionary = {}
	for m in Metas.lista():
		nomes[m["id"]] = m
	var extra: int = 0
	var extra_tr: int = 0
	var n: int = 0
	for id in estado.metas_novas:
		metas_selo.append(id)
		if not nomes.has(id):
			continue
		n += 1
		if n <= 3:
			menus.aviso_meta(Idioma.t("Meta cumprida: %s") % String(nomes[id]["nome"]), int(nomes[id]["premio"]))
		else:
			extra += 1
			extra_tr += int(nomes[id]["premio"])
	if extra > 0:
		menus.aviso_meta(Idioma.t("Mais %d metas cumpridas") % extra, extra_tr)
	estado.metas_novas.clear()

## "Voltar ao mapa" do painel de fim: na primeira vitória sobre o Porão, passa pela tela de final.
func _depois_do_fim() -> void:
	_entrar_mapa()
	if fim_vitoria and not fim_invasao and estado.tudo_vencido() and Menus.final_atos < Balanco.ATOS:
		Menus.final_atos = Balanco.ATOS
		menus.mostrar_final()

func _novo_jogo() -> void:
	Menus.final_visto = false
	metas_selo.clear()
	estado = Estado.new()
	estado.persistir = true
	estado.novo_jogo()
	arrasto = {}
	faiscas.clear()
	tijolos_voando.clear()
	drops_fase.clear()
	velocidade = Menus.velocidade_padrao
	btn_vel.text = "%dx" % velocidade
	aba = ABA_TODAS
	rolagem = 0
	_lista_suja = true
	_entrar_mapa()
	tutorial.guiar_campanha_nova()

# ------------------------------------------------------------------ geometria do guarda-roupa
func pos_boneco(i: int) -> Vector2:
	return Vector2(289.0 + i * 153.0, PE_Y)

func pos_slot(i: int, s: int) -> Vector2:
	return pos_boneco(i) + Desenho.ponto_gato(s) * ESC_G

## Retângulo do ladrilho de índice i na lista da aba (leva a rolagem em conta);
## fora da janela visível devolve um retângulo vazio.
func rect_tile(i: int) -> Rect2:
	var lin: int = i / TILE_COLS - rolagem
	if lin < 0 or lin >= TILE_LINHAS:
		return Rect2()
	return Rect2(PAINEL.position.x + 14 + (i % TILE_COLS) * TILE_PASSO, TILE_Y0 + lin * TILE_PASSO, TILE, TILE)

func pos_tile(i: int) -> Vector2:
	return rect_tile(i).get_center()

func rect_aba(k: int) -> Rect2:
	# ordem na tela: Todas, Fantasias, Cabeça, Corpo, Mão, Acessório, Novas
	var pos: int = 0
	if k == ABA_FANTASIAS:
		pos = 1
	elif k == ABA_NOVAS:
		pos = Pecas.SLOTS + 2
	elif k != ABA_TODAS:
		pos = k + 2
	return Rect2(PAINEL.position.x + 176 + pos * 80.0, PAINEL.position.y + 12, 78, 26)

## Abas na ordem da tela: Todas, Fantasias, um por espaço, Novas.
func _abas() -> Array[int]:
	var r: Array[int] = [ABA_TODAS, ABA_FANTASIAS]
	for k in Pecas.SLOTS:
		r.append(k)
	r.append(ABA_NOVAS)
	return r

func _aba_em(p: Vector2) -> int:
	for k in _abas():
		if rect_aba(k).has_point(p):
			return k
	return -2

func _trocar_aba(k: int) -> void:
	if k != aba:
		Som.tocar("aba")
	aba = k
	rolagem = 0
	_lista_suja = true

func centro_bigorna() -> Vector2:
	return BIGORNA.get_center()

func _tile_em(p: Vector2) -> int:
	var lista: Array[Peca] = _visiveis()
	var col: int = int((p.x - (PAINEL.position.x + 14)) / TILE_PASSO)
	var lin: int = int((p.y - TILE_Y0) / TILE_PASSO)
	if p.x < PAINEL.position.x + 14 or p.y < TILE_Y0 or col < 0 or col >= TILE_COLS or lin < 0 or lin >= TILE_LINHAS:
		return -1
	var i: int = (lin + rolagem) * TILE_COLS + col
	if i < lista.size() and rect_tile(i).has_point(p):
		return i
	return -1

# ---- aba "Fantasias": a fantasia inteira com um clique
## A fantasia c tem cartão na aba: as do fichário e, depois de criada, a do Ateliê (que fica fora das contas do fichário).
func _tem_cartao_fant(c: int) -> bool:
	return not Pecas.retirada(c) or (c == Pecas.Conjunto.ATELIE and Atelie.criada())

## Posição do cartão na grade: as do fichário na ordem delas e a do Ateliê por último; -1 se não tem cartão.
func _pos_cartao_fant(c: int) -> int:
	if c == Pecas.Conjunto.ATELIE:
		return Pecas.n_ativas() if Atelie.criada() else -1
	return Pecas.posicao_ativa(c)

func _n_cartoes_fant() -> int:
	return Pecas.n_ativas() + (1 if Atelie.criada() else 0)

## Retângulo do cartão da fantasia c (grade de 7 colunas por 3 linhas).
func rect_cartao_fant(c: int) -> Rect2:
	var pos: int = _pos_cartao_fant(c)
	if pos < 0:
		return Rect2()
	var lin: int = pos / FANT_COLS - rolagem
	if lin < 0 or lin >= FANT_LINHAS:
		return Rect2()
	return Rect2(PAINEL.position.x + 14 + (pos % FANT_COLS) * (FANT_W + FANT_GAP), TILE_Y0 + lin * (FANT_H + FANT_GAP), FANT_W, FANT_H)

## Fantasia sob o ponto p (só vale na aba Fantasias); -1 se nenhuma.
func _cartao_fant_em(p: Vector2) -> int:
	if aba != ABA_FANTASIAS:
		return -1
	for c in Pecas.CONJUNTO_PECAS.size():
		if not _tem_cartao_fant(c):
			continue
		if rect_cartao_fant(c).has_point(p):
			return c
	return -1

## Melhor peça parada no guarda-roupa de cada tipo: {tipo: Peca}.
func _mapa_guarda() -> Dictionary:
	var m: Dictionary = {}
	var ql: Dictionary = {}
	for q in estado.guarda:
		var qq: float = _qualidade(q)
		if not m.has(q.tipo) or qq > float(ql[q.tipo]):
			m[q.tipo] = q
			ql[q.tipo] = qq
	return m

## Igual a _mapa_guarda, mas uma vez por quadro: só para o desenho (a lógica de vestir usa sempre a versão fresca).
func _mapa_guarda_desenho() -> Dictionary:
	var qd: int = Engine.get_process_frames()
	if _mapa_guarda_q != qd:
		_mapa_guarda_q = qd
		var sg: int = _sig_colecao()
		if sg != _mapa_guarda_sig:   # a coleção não mudou: o mesmo mapa serve (só o que o desenho lê entra na assinatura)
			_mapa_guarda_sig = sg
			_mapa_guarda_c = _mapa_guarda()
	return _mapa_guarda_c

## Assinatura barata (uma vez por quadro) da coleção: guarda-roupa e roupas vestidas, com identidade, ordem,
## tipo, nível, raridade, marcas e flag de nova. Muda quando qualquer coisa que os caches do desenho leem muda.
func _sig_colecao() -> int:
	var qd: int = Engine.get_process_frames()
	if _sig_q == qd:
		return _sig_v
	_sig_q = qd
	var h: int = estado.guarda.size() + 7
	for q in estado.guarda:
		h = h * 31 + q.get_instance_id() + q.tipo * 100003 + q.nivel * 1009 + q.raridade * 17 + q.marcas.size() * 3 + (1 if q.nova else 0)
	h = h * 31 + 13
	for b in estado.bonecos:
		for q in b.pecas:
			h = h * 31 + (0 if q == null else q.get_instance_id() + q.tipo * 100003 + q.nivel * 1009 + q.raridade * 17 + q.marcas.size() * 3)
	_sig_v = h
	return h

## Situação da fantasia c para o gato `alvo`: {"pecas": [Peca ou null], "onde": [FS_*], "dono": [índice do gato ou -1],
## "tipos": [tipo], "gato": n, "guarda": n, "outro": n, "nao": n}. Cada lista tem 4 itens, na ordem das peças da fantasia.
func _situacao_fantasia(c: int, alvo: int, mapa: Dictionary = {}) -> Dictionary:
	if mapa.is_empty():
		mapa = _mapa_guarda()
	var r: Dictionary = {"pecas": [], "onde": [], "dono": [], "tipos": [], "gato": 0, "guarda": 0, "outro": 0, "nao": 0}
	for tp in Pecas.CONJUNTO_PECAS[c]:
		var s: int = Pecas.SLOT[tp]
		var q: Peca = null
		var onde: int = FS_NAO
		var dono: int = -1
		if alvo >= 0 and alvo < estado.bonecos.size():
			var v: Peca = estado.bonecos[alvo].pecas[s]
			if v != null and v.tipo == tp:
				q = v
				onde = FS_GATO
		if q == null and mapa.has(tp):
			q = mapa[tp]
			onde = FS_GUARDA
		if q == null:
			for bi in estado.bonecos.size():
				var w: Peca = estado.bonecos[bi].pecas[s]
				if bi != alvo and w != null and w.tipo == tp:
					q = w
					onde = FS_OUTRO
					dono = bi
					break
		r["pecas"].append(q)
		r["onde"].append(onde)
		r["dono"].append(dono)
		r["tipos"].append(tp)
		var chave: String = ["gato", "guarda", "outro", "nao"][onde]
		r[chave] = int(r[chave]) + 1
	return r

## Quantas fantasias o gato escolhido pode vestir inteiras agora (e ainda não veste).
func _fantasias_prontas() -> int:
	var alvo: int = _alvo_vestir()
	var mapa: Dictionary = _mapa_guarda_desenho()
	var n: int = 0
	for c in Pecas.CONJUNTO_PECAS.size():
		if not _tem_cartao_fant(c):
			continue
		var st: Dictionary = _situacao_fantasia(c, alvo, mapa)
		if int(st["gato"]) + int(st["guarda"]) >= Pecas.SLOTS:
			n += 1
	return n

## Texto "Capacete (com Mimi), Colete (você ainda não tem)" das peças que não dá para vestir.
func _faltas_fantasia(st: Dictionary) -> String:
	var itens: Array[String] = []
	for i in Pecas.SLOTS:
		var nome: String = Idioma.t(Pecas.NOME[int(st["tipos"][i])])
		match int(st["onde"][i]):
			FS_OUTRO:
				itens.append(Idioma.t("%s (com %s)") % [nome, estado.bonecos[int(st["dono"][i])].nome])
			FS_NAO:
				itens.append(Idioma.t("%s (você ainda não tem)") % nome)
	return ", ".join(itens)

## Clique num cartão: veste no gato escolhido tudo o que está livre da fantasia c. Peças de outros gatos ficam onde estão.
func _vestir_fantasia(c: int) -> void:
	if modo != Modo.GUARDA:
		return
	var bi: int = _alvo_vestir()
	if bi < 0:
		_negar(Idioma.t("Não há gato para vestir."))
		return
	var b: Boneco = estado.bonecos[bi]
	var nome_f: String = Idioma.t(Pecas.CONJUNTO_NOME[c])
	var st: Dictionary = _situacao_fantasia(c, bi)
	var plano: Array = b.pecas.duplicate()
	var trocas: int = 0
	for i in Pecas.SLOTS:
		if int(st["onde"][i]) == FS_GUARDA:
			plano[Pecas.SLOT[int(st["tipos"][i])]] = st["pecas"][i]
			trocas += 1
	var faltas: String = _faltas_fantasia(st)
	if trocas == 0:
		if int(st["gato"]) >= Pecas.SLOTS:
			_toast(Idioma.t("%s já veste %s inteira.") % [b.nome, nome_f])
			Som.tocar("clique", 0.8)
		elif int(st["outro"]) + int(st["gato"]) == 0:
			_negar(Idioma.t("Você ainda não tem nenhuma peça de %s.") % nome_f)
		else:
			_negar(Idioma.t("Nada livre de %s para %s. Faltam: %s.") % [nome_f, b.nome, faltas])
		return
	var foto: Dictionary = {bi: b.pecas.duplicate()}
	var antes: Array[int] = Pecas.contar_conjuntos(b.pecas)
	_trocar_roupas({bi: plano})
	desfazer = {"foto": foto, "rotulo": Idioma.t("Vestir %s") % nome_f}
	sel = bi
	b.pop = maxf(b.pop, 0.55)
	var depois: int = Pecas.contar_conjuntos(b.pecas)[c]
	if depois >= Pecas.SLOTS and antes[c] < Pecas.SLOTS:
		_celebrar_fantasia(bi, c)
	else:
		Som.tocar("vestir", 1.1)
	menus.dica_cumprida("vestir")
	if faltas == "":
		_toast(Idioma.t("%s veste %s (%d/%d). Z desfaz.") % [b.nome, nome_f, depois, Pecas.SLOTS])
	else:
		_toast(Idioma.t("%s veste %d/%d de %s. Faltam: %s. Z desfaz.") % [b.nome, depois, Pecas.SLOTS, nome_f, faltas])
		aviso_cursor_t = 5.5
		aviso_cursor_cor = Color(1.0, 0.82, 0.4)

## Botão de linha (frente/meio/fundo) sob a barra de saúde do boneco i.
func rect_linha(i: int) -> Rect2:
	var c: Vector2 = pos_boneco(i)
	return Rect2(c.x - 46, c.y + 28, 92, 18)

## Botão de atributo (Vida, Força, Agilidade) no alto do vão do boneco i.
## Com ponto de treino ele vira um botão grande (ícone, nome e ganho); sem ponto, uma fichinha.
func rect_atr(i: int, a: int) -> Rect2:
	var c: Vector2 = pos_boneco(i)
	var tem: bool = i >= 0 and i < estado.bonecos.size() and estado.bonecos[i].pontos > 0
	if tem:
		return Rect2(c.x - 72.0 + a * 49.0, 62.0, 46.0, 40.0)
	return Rect2(c.x - 72.0 + a * 49.0, 66.0, 46.0, 24.0)

func _atr_em(p: Vector2) -> Vector2i:
	for i in estado.bonecos.size():
		for a in Balanco.ATR_NOMES.size():
			if rect_atr(i, a).has_point(p):
				return Vector2i(i, a)
	return Vector2i(-1, -1)

## O que um ponto no atributo a dá.
func _atr_efeito(a: int) -> String:
	match a:
		Boneco.Atr.VIDA:
			return Idioma.t("+%d%% de vida máxima") % int(round(Balanco.ATR_VIDA * 100.0))
		Boneco.Atr.FORCA:
			return Idioma.t("+%d%% de dano") % int(round(Balanco.ATR_FORCA * 100.0))
		Boneco.Atr.AGILIDADE:
			return Idioma.t("+%d%% de velocidade de ataque e +%d%% de movimento") % [int(round(Balanco.ATR_AGIL * 100.0)), int(round(Balanco.ATR_AGIL_VEL * 100.0))]
	return ""

## Ganho curto de um ponto, para o botão de treino.
func _atr_ganho(a: int) -> String:
	match a:
		Boneco.Atr.VIDA:
			return Idioma.t("+%d%% de vida") % int(round(Balanco.ATR_VIDA * 100.0))
		Boneco.Atr.FORCA:
			return Idioma.t("+%d%% de dano") % int(round(Balanco.ATR_FORCA * 100.0))
		Boneco.Atr.AGILIDADE:
			return Idioma.t("+%d%% de velocidade de ataque") % int(round(Balanco.ATR_AGIL * 100.0))
	return ""

func _linha_em(p: Vector2) -> int:
	for i in estado.bonecos.size():
		if rect_linha(i).has_point(p):
			return i
	return -1

func _boneco_em(p: Vector2) -> int:
	# o espaço da boca fica para fora do retângulo do gato: soltar nele também vale
	var sl: Vector2i = _slot_em(p)
	if sl.x >= 0:
		return sl.x
	for i in estado.bonecos.size():
		var c: Vector2 = pos_boneco(i)
		if Rect2(c.x - 72, c.y - 112, 144, 127).has_point(p):
			return i
	return -1

func _slot_em(p: Vector2) -> Vector2i:
	var melhor := Vector2i(-1, -1)
	var dmin: float = 26.0
	for i in estado.bonecos.size():
		for s in Pecas.SLOTS:
			var d: float = pos_slot(i, s).distance_to(p)
			if d < dmin:
				dmin = d
				melhor = Vector2i(i, s)
	return melhor

func _peca_sob_mouse() -> Peca:
	var ti: int = _tile_em(mouse)
	if ti >= 0:
		return _visiveis()[ti]
	var ss: Vector2i = _slot_em(mouse)
	if ss.x >= 0:
		return estado.bonecos[ss.x].pecas[ss.y]
	return null

# ------------------------------------------------------------------ ações
func _faisca(p: Vector2, cor: Color, n: int, vel: float = 160.0) -> void:
	for i in n:
		var a: float = randf() * TAU
		faiscas.append({"p": p, "v": Vector2(cos(a), sin(a) - 0.5) * randf_range(vel * 0.3, vel), "vida": randf_range(0.3, 0.7), "max": 0.7, "cor": cor, "r": randf_range(2.0, 4.5)})

func _gastar_tijolos(n: int, destino: Vector2) -> void:
	for k in n:
		var idx: int = estado.tijolos + k
		var r: Rect2 = Desenho.rect_tijolo(idx, TORRE_G, 1.0)
		tijolos_voando.append({"ini": r.get_center(), "fim": destino, "t": -0.08 * k, "cor": Desenho.cor_tijolo(idx), "idx": idx, "rot": randf_range(-1, 1)})
	_atualizar_botoes()

func vestir(bi: int, peca: Peca) -> void:
	if bi < 0 or bi >= estado.bonecos.size():
		return
	var b: Boneco = estado.bonecos[bi]
	var ef: Vector2i = _efeito_conjunto(b, peca)
	var de: Vector2 = _pos_peca(peca)
	if de.x < 0.0:
		de = mouse
	estado.vestir(b, peca)
	sel = bi
	_lista_suja = true
	var destino: Vector2 = pos_slot(bi, peca.slot())
	_voar(peca, de, destino, Vector2i(bi, peca.slot()))
	pulos[Vector2i(bi, peca.slot())] = 0.0
	_faisca(destino, Color(1, 1, 0.7), 14, 150.0)
	if ef.y >= Pecas.SLOTS and ef.x < Pecas.SLOTS:
		_celebrar_fantasia(bi, peca.conjunto())
	else:
		Som.tocar("vestir")
		if ef.y > ef.x and ef.y >= Pecas.CONJUNTO_MIN:
			_flutuar("%s %d/%d" % [Idioma.t(Pecas.CONJUNTO_NOME[peca.conjunto()]), ef.y, Pecas.SLOTS], destino + Vector2(0, -30), Pecas.CONJUNTO_COR[peca.conjunto()].lightened(0.4), 16, 1.1)
	menus.dica_cumprida("vestir")

func tirar(bi: int, s: int) -> void:
	var q: Peca = estado.bonecos[bi].pecas[s]
	var de: Vector2 = pos_slot(bi, s)
	estado.tirar(estado.bonecos[bi], s)
	_lista_suja = true
	if q != null:
		_voar(q, de, _pos_peca(q))
	_faisca(de, Color(0.8, 0.8, 0.9), 6, 100.0)
	Som.tocar("tirar")

## Recado curto no painel "Promover" (por que a ação não deu) e junto do cursor.
func _recado(txt: String) -> void:
	msg_painel = txt
	msg_painel_t = 2.6
	negado = 0.5
	_negar(txt)

## Ação negada: som, e o motivo escrito junto do cursor.
func _negar(txt: String) -> void:
	Som.tocar("negado")
	aviso_cursor = txt
	aviso_cursor_t = 2.4
	aviso_cursor_cor = Color(1.0, 0.5, 0.45)

## Recado positivo junto do cursor (resultado de uma montagem, por exemplo).
func _toast(txt: String) -> void:
	aviso_cursor = txt
	aviso_cursor_t = 3.0
	aviso_cursor_cor = Color(0.55, 0.95, 0.6)

func _voar(peca: Peca, de: Vector2, para: Vector2, dest: Vector2i = Vector2i(-1, -1)) -> void:
	if para.x < 0.0 or de.distance_to(para) < 6.0:
		return
	voos.append({"peca": peca, "de": de, "para": para, "t": 0.0, "dest": dest})

func _flutuar(txt: String, pos: Vector2, cor: Color, tam: int = 18, dur: float = 1.2) -> void:
	flutuantes.append({"txt": txt, "p": pos, "cor": cor, "tam": tam, "t": 0.0, "dur": dur})

## Fantasia completada: clarão, pulinho do gato, faíscas, som e o poder liberado.
func _celebrar_fantasia(bi: int, c: int) -> void:
	var b: Boneco = estado.bonecos[bi]
	b.pop = 1.0
	var cor: Color = Pecas.CONJUNTO_COR[c]
	var pos: Vector2 = pos_boneco(bi) + Vector2(0, -60)
	_faisca(pos, cor.lightened(0.3), 34, 300.0)
	_faisca(pos, Color(1, 1, 0.8), 18, 220.0)
	claroes.append({"bi": bi, "t": 0.0, "cor": cor})
	fant_recente = c
	_flutuar(Idioma.t("F abre o fichário nela"), pos + Vector2(0, -50), Color(1, 1, 1, 0.85), 13, 2.2)
	_flutuar(Idioma.t("Poder liberado: %s") % Idioma.t(Pecas.PODER_NOME[c]), pos + Vector2(0, -80), Desenho.DOURADO, 20, 2.2)
	Som.tocar("fantasia")

## Resumo da volta da luta: monta a lista do que foi ganho (peças primeiro, as melhores por último).
func _abrir_resumo() -> void:
	if resumo_pend.is_empty():
		resumo = {}
		return
	var pecas: Array = []
	var resto: Array = []
	for it in resumo_pend:
		if it["tipo"] == "peca":
			pecas.append(it)
		else:
			resto.append(it)
	resumo_pend.clear()
	pecas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["p"] as Peca).raridade < (b["p"] as Peca).raridade)
	resumo = {"itens": pecas + resto, "t": 0.0, "tocados": 0}

func _fechar_resumo() -> void:
	resumo = {}

func _som_resumo(it: Dictionary, k: int) -> void:
	match str(it["tipo"]):
		"peca":
			var r: int = (it["p"] as Peca).raridade
			if r >= 2:
				Som.tocar("meta")
			elif r == 1:
				Som.tocar("raridade")
			else:
				Som.tocar("pegar", 1.0 + 0.04 * mini(k, 8), 0.03, -4.0)
		"nivel":
			Som.tocar("nivel")
		"marca":
			Som.tocar("marca")
		"trofeu":
			Som.tocar("trofeu")

func _botoes_guarda(v: bool) -> void:
	for b in [btn_melhor, btn_time, btn_desf, btn_ajuda]:
		if b != null:
			b.visible = v
	if v and btn_ajuda != null:
		btn_ajuda.position = AJUDA_BT.position
		btn_ajuda.size = AJUDA_BT.size

## Mostra o "?" num lugar fora do guarda-roupa (mapa e luta).
func _ajuda_em(r: Rect2) -> void:
	btn_ajuda.position = r.position
	btn_ajuda.size = r.size
	btn_ajuda.visible = true

## Botão "?": repete o tutorial da tela à vista (guarda-roupa, mapa, preparação ou luta), sem gravar progresso.
func _ajuda_da_tela() -> void:
	if menus.ativo() or menus.em_transicao() or tutorial == null or tutorial.guiado_ativo():
		return
	if modo == Modo.GUARDA and (ajuda_aberta or not resumo.is_empty() or not fusao.is_empty()):
		return
	tutorial.rever()

func _alternar_ajuda() -> void:
	if modo != Modo.GUARDA or menus.ativo() or menus.em_transicao():
		return
	ajuda_aberta = not ajuda_aberta
	avisos_aberto = false
	arrasto = {}
	Som.tocar("abrir" if ajuda_aberta else "fechar")

func _clique_bloq(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
		if not resumo.is_empty():
			_fechar_resumo()
		elif ajuda_aberta:
			ajuda_aberta = false
			Som.tocar("fechar")

## Esc visto antes dos menus: fecha a ajuda, o resumo ou a lista de avisos e cancela o arrasto. Devolve true se usou a tecla.
func _esc_guarda(ev: InputEvent) -> bool:
	var k: InputEventKey = ev as InputEventKey
	if k == null or not k.pressed or k.echo or k.keycode != KEY_ESCAPE:
		return false
	if nome_idx >= 0:
		_cancelar_nome()   # Esc na caixa do nome só cancela a edição (não abre a pausa)
		return true
	if modo != Modo.GUARDA or menus.ativo() or menus.em_transicao() or not fusao.is_empty():
		return false
	if oficina != null and oficina.aberta:
		return false
	if fichario != null and fichario.aberto():
		return false
	if not resumo.is_empty():
		_fechar_resumo()
		return true
	if ajuda_aberta:
		ajuda_aberta = false
		Som.tocar("fechar")
		return true
	if avisos_aberto:
		avisos_aberto = false
		Som.tocar("fechar")
		return true
	if not arrasto.is_empty():
		arrasto = {}
		return true
	return false

# ---- seleção, vestir por clique e montagem automática
func _selecionar(i: int) -> void:
	if i < 0 or i >= estado.bonecos.size():
		return
	if sel != i:
		sel = i
		Som.tocar("pegar", 1.25, 0.04, -3.0)
	estado.bonecos[i].pop = maxf(estado.bonecos[i].pop, 0.55)

## Teclas 1 a 5: seleciona o gato; apertar a tecla do que já está selecionado desfaz a seleção.
func _selecionar_ou_soltar(i: int) -> void:
	if i < 0 or i >= estado.bonecos.size():
		return
	if sel == i:
		_desselecionar()
	else:
		_selecionar(i)

func _desselecionar() -> void:
	if sel < 0:
		return
	sel = -1
	Som.tocar("pegar", 0.9, 0.04, -6.0)

## Coluna do gato no palco (nome, corpo, chão): o clique em qualquer ponto dela seleciona. -1 se fora.
func _coluna_em(p: Vector2) -> int:
	if p.y < 0.0 or p.y > 446.0:
		return -1
	for i in estado.bonecos.size():
		var cx: float = pos_boneco(i).x
		if p.x >= cx - 76.5 and p.x < cx + 76.5:
			return i
	return -1

## Gato que recebe a peça num clique: o selecionado.
func _alvo_vestir() -> int:
	if sel >= 0 and sel < estado.bonecos.size():
		return sel
	return 0 if not estado.bonecos.is_empty() else -1

## Soltou no mesmo lugar (sem arrastar): clique.
func _clicar(a: Dictionary) -> void:
	if a.has("peca"):
		var pc: Peca = a["peca"]
		var origem: Boneco = a["origem"]
		if origem == null:
			var bi: int = _alvo_vestir()
			if bi < 0:
				_negar(Idioma.t("Não há gato para vestir."))
				return
			vestir(bi, pc)
		else:
			var idx: int = estado.bonecos.find(origem)
			sel = idx
			tirar(idx, pc.slot())
	elif a.has("boneco"):
		if int(a["idx"]) == sel:
			_desselecionar()   # clicar de novo no gato escolhido desfaz a seleção
		else:
			_selecionar(int(a["idx"]))

func _qualidade(p: Peca) -> float:
	return p.raridade * 10.0 + p.nivel + p.marcas.size() * 0.1

## Plano de roupas para os gatos `bis`: devolve {gato: [4 peças]}. Completa fantasias primeiro, depois 3 e 2 peças;
## o que sobra é preenchido pelo que já vestem e, depois, pelas melhores peças livres (raridade e nível desempatam).
func _planejar(bis: Array) -> Dictionary:
	var reserva: Array = []
	reserva.append_array(estado.guarda)
	var plano: Dictionary = {}
	for bi in bis:
		plano[bi] = [null, null, null, null]
		for q in estado.bonecos[bi].pecas:
			if q != null:
				reserva.append(q)
	# peças da reserva agrupadas por (fantasia, espaço), na mesma ordem da reserva: a busca do melhor candidato
	# olha só o grupo certo em vez de varrer a reserva inteira (o resultado é idêntico)
	var grupos: Dictionary = {}
	for q in reserva:
		var gk: int = q.conjunto() * 8 + q.slot()
		if not grupos.has(gk):
			grupos[gk] = []
		(grupos[gk] as Array).append(q)
	var livres: Array = bis.duplicate()
	while not livres.is_empty():
		var melhor: float = 0.0
		var m_bi: int = -1
		var m_pecas: Array = []
		for bi in livres:
			var b: Boneco = estado.bonecos[bi]
			for c in Pecas.Conjunto.size():
				if Pecas.retirada(c):
					continue
				var pcs: Array = [null, null, null, null]
				var k: int = 0
				var soma: float = 0.0
				for s in Pecas.SLOTS:
					var bp: Peca = null
					var bq: float = -1.0
					for q in grupos.get(c * 8 + s, []):
						var qq: float = _qualidade(q) + (0.5 if b.pecas[s] == q else 0.0)
						if qq > bq:
							bq = qq
							bp = q
					if bp != null:
						pcs[s] = bp
						k += 1
						soma += bq
				if k < Pecas.CONJUNTO_MIN:
					continue
				var sc: float = (10000.0 if k >= Pecas.SLOTS else (3000.0 if k == 3 else 1000.0)) + soma
				if sc > melhor:
					melhor = sc
					m_bi = bi
					m_pecas = pcs
		if m_bi < 0:
			break
		for s in Pecas.SLOTS:
			if m_pecas[s] != null:
				plano[m_bi][s] = m_pecas[s]
				reserva.erase(m_pecas[s])
				(grupos[m_pecas[s].conjunto() * 8 + s] as Array).erase(m_pecas[s])
		livres.erase(m_bi)
	# o que sobrou: primeiro o que já vestem, depois a melhor peça livre do espaço
	for bi in bis:
		for s in Pecas.SLOTS:
			var atual: Peca = estado.bonecos[bi].pecas[s]
			if plano[bi][s] == null and atual != null and reserva.has(atual):
				plano[bi][s] = atual
				reserva.erase(atual)
	for bi in bis:
		for s in Pecas.SLOTS:
			if plano[bi][s] != null:
				continue
			var bp2: Peca = null
			for q in reserva:
				if q.slot() == s and (bp2 == null or _qualidade(q) > _qualidade(bp2)):
					bp2 = q
			if bp2 != null:
				plano[bi][s] = bp2
				reserva.erase(bp2)
	return plano

## Aplica um plano {gato: [4 peças]} com voos e pulinhos; devolve quantos espaços mudaram.
func _trocar_roupas(plano: Dictionary) -> int:
	var mudou: int = 0
	var movs: Array = []
	for bi in plano:
		var b: Boneco = estado.bonecos[bi]
		for s in Pecas.SLOTS:
			var q: Peca = plano[bi][s]
			if q != b.pecas[s]:
				mudou += 1
				if q != null:
					movs.append([q, _pos_peca(q), bi, s])
	if mudou == 0:
		return 0
	for bi in plano:
		estado.tirar_tudo(estado.bonecos[bi])
	for bi in plano:
		for s in Pecas.SLOTS:
			if plano[bi][s] != null:
				estado.vestir(estado.bonecos[bi], plano[bi][s])
	_lista_suja = true
	for m in movs:
		var dest: Vector2 = pos_slot(int(m[2]), int(m[3]))
		var de: Vector2 = m[1]
		_voar(m[0], de if de.x >= 0.0 else dest + Vector2(0, 80), dest, Vector2i(int(m[2]), int(m[3])))
		pulos[Vector2i(int(m[2]), int(m[3]))] = 0.0
		_faisca(dest, Color(1, 1, 0.7), 8, 130.0)
	return mudou

func _montar(bis: Array, rotulo: String) -> void:
	if modo != Modo.GUARDA or bis.is_empty():
		return
	var plano: Dictionary = _planejar(bis)
	var foto: Dictionary = {}
	var antes: Dictionary = {}
	for bi in bis:
		foto[bi] = estado.bonecos[bi].pecas.duplicate()
		antes[bi] = Pecas.contar_conjuntos(estado.bonecos[bi].pecas)
	var n: int = _trocar_roupas(plano)
	if n == 0:
		_toast(Idioma.t("%s já está vestido do melhor jeito.") % (estado.bonecos[bis[0]].nome if bis.size() == 1 else Idioma.t("O time")))
		Som.tocar("clique", 0.8)
		return
	desfazer = {"foto": foto, "rotulo": rotulo}
	var completas: int = 0
	for bi in bis:
		var dep: Array[int] = Pecas.contar_conjuntos(estado.bonecos[bi].pecas)
		for c in dep.size():
			if dep[c] >= Pecas.SLOTS and int(antes[bi][c]) < Pecas.SLOTS:
				completas += 1
				_celebrar_fantasia(bi, c)
	if completas == 0:
		Som.tocar("vestir", 1.1)
	var txt: String = Idioma.t("%d peça trocada") % n if n == 1 else Idioma.t("%d peças trocadas") % n
	if completas > 0:
		txt += Idioma.t(" · %d fantasia completa") % completas if completas == 1 else Idioma.t(" · %d fantasias completas") % completas
	_toast(txt + Idioma.t(". Z desfaz."))
	menus.dica_cumprida("vestir")

func _vestir_melhor() -> void:
	if sel >= 0 and sel < estado.bonecos.size():
		_montar([sel], Idioma.t("Vestir melhor"))

func _vestir_time() -> void:
	var todos: Array = []
	for i in estado.bonecos.size():
		todos.append(i)
	_montar(todos, Idioma.t("Vestir o time"))

func _desfazer() -> void:
	if modo != Modo.GUARDA:
		return
	if desfazer.is_empty():
		_negar(Idioma.t("Não há montagem para desfazer."))
		return
	var foto: Dictionary = desfazer["foto"]
	var presentes: Array = []
	presentes.append_array(estado.guarda)
	for bi in foto:
		if bi >= estado.bonecos.size():
			desfazer = {}
			return
		for q in estado.bonecos[bi].pecas:
			if q != null:
				presentes.append(q)
	for bi in foto:
		for q in foto[bi]:
			if q != null and not presentes.has(q):
				desfazer = {}
				_negar(Idioma.t("Não dá mais para desfazer: uma peça mudou."))
				return
	_trocar_roupas(foto)
	desfazer = {}
	Som.tocar("tirar", 0.9)
	_toast(Idioma.t("Roupas de volta como estavam."))

## O que muda ao vestir `p` no gato `bi`: peça que sai e que entra, e o efeito nas fantasias. Itens para _caixa_dica.
func _comparar(bi: int, p: Peca) -> Array:
	var b: Boneco = estado.bonecos[bi]
	var s: int = p.slot()
	var atual: Peca = b.pecas[s]
	var verde := Color(0.65, 1.0, 0.7)
	var verm := Color(1.0, 0.6, 0.55)
	if atual == p:
		return [["t", Idioma.t("%s já veste esta peça.") % b.nome, 13, Color(1, 1, 1, 0.7)]]
	var itens: Array = [["t", Idioma.t("Em %s (%s):") % [b.nome, Idioma.t(Pecas.SLOT_NOME[s]).to_lower()], 13, Color(1.0, 0.9, 0.5)]]
	itens.append(["t", Idioma.t("Sai: %s") % (_rot_peca(atual) if atual != null else Idioma.t("nada, o espaço está livre")), 13, Color(1, 1, 1, 0.75)])
	itens.append(["t", Idioma.t("Entra: %s") % _rot_peca(p), 13, Color(1, 1, 1)])
	var novas: Array = b.pecas.duplicate()
	novas[s] = p
	var antes: Array[int] = Pecas.contar_conjuntos(b.pecas)
	var depois: Array[int] = Pecas.contar_conjuntos(novas)
	var algum: bool = false
	for c in antes.size():
		var a: int = antes[c]
		var d: int = depois[c]
		if a == d or (a < Pecas.CONJUNTO_MIN and d < Pecas.CONJUNTO_MIN):
			continue
		var nome: String = Idioma.t(Pecas.CONJUNTO_NOME[c])
		var cab: String = "%s %d/%d → %d/%d" % [nome, a, Pecas.SLOTS, d, Pecas.SLOTS]
		if d > a:
			if d >= Pecas.SLOTS:
				itens.append(["t", Idioma.t("%s: ganha o poder %s") % [cab, Idioma.t(Pecas.PODER_NOME[c])], 13, verde])
			elif a < Pecas.CONJUNTO_MIN:
				itens.append(["t", Idioma.t("%s: ganha o bônus de %s") % [cab, nome], 13, verde])
			else:
				itens.append(["t", Idioma.t("%s: mais perto do poder") % cab, 13, verde])
		else:
			if a >= Pecas.SLOTS:
				itens.append(["t", Idioma.t("%s: perde o poder %s") % [cab, Idioma.t(Pecas.PODER_NOME[c])], 13, verm])
			elif d < Pecas.CONJUNTO_MIN:
				itens.append(["t", Idioma.t("%s: perde o bônus de %s") % [cab, nome], 13, verm])
			else:
				itens.append(["t", Idioma.t("%s: mantém o bônus") % cab, 13, Color(1, 1, 1, 0.8)])
		algum = true
	if not algum:
		itens.append(["t", Idioma.t("Não muda nenhuma fantasia."), 13, Color(1, 1, 1, 0.55)])
	return itens

# ---- avisos do LUTAR (nunca bloqueiam)
func _calcular_avisos() -> Array:
	var r: Array = []
	for i in estado.bonecos.size():
		var b: Boneco = estado.bonecos[i]
		var vest: int = 0
		for q in b.pecas:
			if q != null:
				vest += 1
		if vest == 0:
			r.append({"txt": Idioma.t("%s está sem roupa.") % b.nome, "tipo": "gato", "bi": i})
	for i in estado.bonecos.size():
		var b2: Boneco = estado.bonecos[i]
		if b2.pontos > 0:
			r.append({"txt": (Idioma.t("%s: %d ponto de treino.") if b2.pontos == 1 else Idioma.t("%s: %d pontos de treino.")) % [b2.nome, b2.pontos], "tipo": "gato", "bi": i})
	var novas: int = 0
	for q in estado.guarda:
		if q.nova:
			novas += 1
	if novas > 0:
		r.append({"txt": Idioma.t("%d peça nova.") % novas if novas == 1 else Idioma.t("%d peças novas.") % novas, "tipo": "novas"})
	for i in estado.bonecos.size():
		var b3: Boneco = estado.bonecos[i]
		var cont: Array[int] = Pecas.contar_conjuntos(b3.pecas)
		for c in cont.size():
			if cont[c] != Pecas.SLOTS - 1:
				continue
			var falta: int = -1
			for s in Pecas.SLOTS:
				if b3.pecas[s] == null or b3.pecas[s].conjunto() != c:
					falta = s
			var tem: bool = false
			for q in estado.guarda:
				if q.slot() == falta and q.conjunto() == c:
					tem = true
					break
			if tem:
				r.append({"txt": Idioma.t("%s: falta 1 peça de %s (você tem).") % [b3.nome, Idioma.t(Pecas.CONJUNTO_NOME[c])], "tipo": "fantasia", "bi": i, "c": c})
	return r

func _rect_aviso_lista() -> Rect2:
	var n: int = mini(6, avisos_cache.size())
	var h: float = 16.0 + n * 36.0
	return Rect2(990, 554.0 - h, 275, h)

func _rect_aviso_linha(k: int) -> Rect2:
	var r: Rect2 = _rect_aviso_lista()
	return Rect2(r.position.x + 10, r.position.y + 8 + k * 36.0, r.size.x - 20, 34)

func _clicar_avisos(p: Vector2) -> void:
	if CHIP_AV.has_point(p):
		avisos_aberto = false
		Som.tocar("fechar")
		return
	for k in mini(6, avisos_cache.size()):
		if _rect_aviso_linha(k).has_point(p):
			var av: Dictionary = avisos_cache[k]
			avisos_aberto = false
			Som.tocar("clique")
			match str(av["tipo"]):
				"gato":
					_selecionar(int(av["bi"]))
				"novas":
					_trocar_aba(ABA_NOVAS)
				"fantasia":
					_selecionar(int(av["bi"]))
					filtro_cj = int(av["c"])
					_lista_suja = true
					_trocar_aba(ABA_TODAS)
			return
	avisos_aberto = false   # clicou fora: fecha

# ---- atalhos
func _tecla_guarda(k: InputEventKey) -> bool:
	var kc: Key = k.keycode
	var confirma: bool = kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE
	if not resumo.is_empty():
		if confirma:
			_fechar_resumo()
		return true
	if ajuda_aberta:
		if confirma or kc == KEY_F1 or kc == KEY_H or k.unicode == 63 or kc == KEY_SLASH:
			ajuda_aberta = false
			Som.tocar("fechar")
		return true
	if not arrasto.is_empty():
		return false
	if kc >= KEY_1 and kc <= KEY_5:
		_selecionar_ou_soltar(kc - KEY_1)
		return true
	if kc >= KEY_KP_1 and kc <= KEY_KP_5:
		_selecionar_ou_soltar(kc - KEY_KP_1)
		return true
	if kc == KEY_0 or kc == KEY_KP_0:
		_desselecionar()
		return true
	if aba == ABA_FANTASIAS and (kc == KEY_UP or kc == KEY_DOWN):
		rolagem = clampi(rolagem + (-1 if kc == KEY_UP else 1), 0, _rolagem_max())
		Som.tocar("aba", 1.2, 0.04, -8.0)
		return true
	var abas_l: Array[int] = _abas()
	if kc == KEY_Q or kc == KEY_E or kc == KEY_TAB:
		var passo: int = -1 if (kc == KEY_Q or (kc == KEY_TAB and k.shift_pressed)) else 1
		var pos: int = (abas_l.find(aba) + passo + abas_l.size()) % abas_l.size()
		_trocar_aba(abas_l[pos])
		return true
	if kc == KEY_V:
		_vestir_time()
		return true
	if kc == KEY_Z:
		_desfazer()
		return true
	if kc == KEY_F1 or kc == KEY_H or k.unicode == 63 or kc == KEY_SLASH:
		_alternar_ajuda()
		return true
	if confirma:
		if guarda_t >= 0.6 and btn_lutar.visible and not avisos_aberto:
			menus.ir(_lutar)
		return true
	return false

## Motivo de a peça não poder subir de nível agora (vazio se pode).
func _motivo_nivel(p: Peca) -> String:
	if p.nivel >= Balanco.NIVEL_MAX:
		return Idioma.t("Nível máximo")
	if estado.tijolos < Balanco.custo_promocao(p.nivel):
		return Idioma.t("Faltam blocos")
	if estado.blocos_livres() < Balanco.custo_promocao(p.nivel):
		return Idioma.t("Reserva da torre")
	return ""

## Motivo de a peça não poder subir de raridade agora (vazio se pode).
func _motivo_reforco(p: Peca) -> String:
	if p.raridade >= Pecas.Raridade.MIAUJESTOSA:
		return Idioma.t("Raridade máxima")
	if estado.trofeus < Balanco.custo_reforco(p.raridade):
		return Idioma.t("Faltam troféus")
	return ""

func centro_carretel() -> Vector2:
	return ALVO_CARRETEL.get_center()

func promover(peca: Peca) -> bool:
	var m: String = _motivo_nivel(peca)
	if m == "" and estado.promover(peca):
		estado.salvar()
		_lista_suja = true
		_gastar_tijolos(Balanco.custo_promocao(peca.nivel - 1), centro_carretel())
		_faisca(centro_carretel() + Vector2(0, -20), Desenho.DOURADO, 18, 220.0)
		efeito_peca = {"peca": peca, "t": 0.0}
		Som.tocar("promover")
		menus.dica_cumprida("blocos")
		_flutuar(Idioma.t("Nível %d") % peca.nivel, centro_carretel() + Vector2(0, -50), Desenho.DOURADO, 18, 1.1)
		return true
	elif m == Idioma.t("Nível máximo"):
		_recado(Idioma.t("Nível máximo."))
	elif m == Idioma.t("Reserva da torre"):
		_recado(Idioma.t("A torre guarda %d blocos de reserva: promover não gasta esses.") % Balanco.RESERVA_PROMOCAO)
	else:
		_recado(Idioma.t("Faltam blocos (custa %d).") % Balanco.custo_promocao(peca.nivel))
	return false

func reforcar(peca: Peca) -> bool:
	var m: String = _motivo_reforco(peca)
	if m == "" and estado.reforcar(peca):
		_lista_suja = true
		_faisca(ALVO_ESTRELA.get_center() + Vector2(0, -16), Color(1.0, 0.9, 0.4), 22, 240.0)
		efeito_peca = {"peca": peca, "t": 0.0}
		Som.tocar("raridade")
		_flutuar(Idioma.t(Pecas.RARIDADE_NOME[peca.raridade]), ALVO_ESTRELA.get_center() + Vector2(0, -50), Pecas.cor_rar(peca.raridade).lightened(0.3), 18, 1.3)
		return true
	elif m == Idioma.t("Raridade máxima"):
		_recado(Idioma.t("Já é miaujestosa, a raridade máxima."))
	else:
		_recado(Idioma.t("Faltam troféus (custa %d).") % Balanco.custo_reforco(peca.raridade))
	return false

# ---- promover a fantasia inteira
func rect_promover(i: int) -> Rect2:
	var c: Vector2 = pos_boneco(i)
	var tem: bool = i >= 0 and i < estado.bonecos.size() and estado.bonecos[i].pontos > 0
	return Rect2(c.x - 72.0, 106.0 if tem else 94.0, 76.0, 20.0)

## Botão "raridade da fantasia inteira" do gato i, ao lado do de nível.
func rect_reforcar(i: int) -> Rect2:
	var r: Rect2 = rect_promover(i)
	return Rect2(r.end.x + 4.0, r.position.y, 64.0, 20.0)

func _reforcar_em(p: Vector2) -> int:
	for i in estado.bonecos.size():
		if rect_reforcar(i).has_point(p):
			return i
	return -1

## {"custo": troféus para subir todas, "ok": dá para ao menos uma, "motivo": por que não}.
func _estado_reforcar_tudo(b: Boneco) -> Dictionary:
	var custo: int = estado.custo_reforcar_fantasia(b)
	var motivo: String = ""
	var barata: int = 99
	var vestidas: int = 0
	for q in b.pecas:
		if q != null:
			vestidas += 1
			if q.raridade < Pecas.Raridade.MIAUJESTOSA:
				barata = mini(barata, Balanco.custo_reforco(q.raridade))
	if custo == 0:
		motivo = Idioma.t("%s está sem roupa.") % b.nome if vestidas == 0 else Idioma.t("Tudo já é mítico.")
	elif estado.trofeus < barata:
		motivo = Idioma.t("Faltam troféus (mínimo %d).") % barata
	return {"custo": custo, "ok": motivo == "", "motivo": motivo}

func _acao_reforcar_tudo(i: int) -> void:
	var b: Boneco = estado.bonecos[i]
	var st: Dictionary = _estado_reforcar_tudo(b)
	if not st["ok"]:
		negado = 0.5
		_negar(str(st["motivo"]))
		return
	var n: int = estado.reforcar_fantasia(b)
	if n <= 0:
		negado = 0.5
		_negar(Idioma.t("Nada para reforçar agora."))
		return
	Som.tocar("raridade")
	_flutuar(Idioma.t("%d peça mais rara") % n if n == 1 else Idioma.t("%d peças mais raras") % n, pos_boneco(i) + Vector2(0, -150), Color(0.8, 0.7, 1.0), 16, 1.4)
	estado.salvar()
	_lista_suja = true
	_faisca(rect_reforcar(i).get_center(), Color(0.8, 0.7, 1.0), 16, 200.0)
	for s in Pecas.SLOTS:
		if b.pecas[s] != null:
			_faisca(pos_slot(i, s), Color(0.85, 0.75, 1.0), 5, 110.0)
	b.pop = 1.0

func _promover_em(p: Vector2) -> int:
	for i in estado.bonecos.size():
		if rect_promover(i).has_point(p):
			return i
	return -1

## {"custo": blocos que a fantasia inteira custaria, "ok": dá para ao menos uma peça, "motivo": por que não}.
func _estado_promover_tudo(b: Boneco) -> Dictionary:
	var custo: int = estado.custo_promover_fantasia(b)
	var motivo: String = ""
	var vestidas: int = 0
	var barato: int = 99
	for q in b.pecas:
		if q != null:
			vestidas += 1
			if q.nivel < Balanco.NIVEL_MAX:
				barato = mini(barato, Balanco.custo_promocao(q.nivel))
	if custo == 0:
		motivo = Idioma.t("%s está sem roupa.") % b.nome if vestidas == 0 else Idioma.t("Tudo no nível máximo.")
	elif estado.tijolos < barato:
		motivo = Idioma.t("Faltam blocos (mínimo %d).") % barato
	elif estado.blocos_livres() < barato:
		motivo = Idioma.t("A torre guarda %d blocos de reserva: promover não gasta esses.") % Balanco.RESERVA_PROMOCAO
	return {"custo": custo, "ok": motivo == "", "motivo": motivo}

func _acao_promover_tudo(i: int) -> void:
	var b: Boneco = estado.bonecos[i]
	var st: Dictionary = _estado_promover_tudo(b)
	if not st["ok"]:
		negado = 0.5
		_negar(str(st["motivo"]))
		return
	var antes: int = estado.tijolos
	var n: int = estado.promover_fantasia(b)
	if n <= 0:
		negado = 0.5
		_negar(Idioma.t("Nada para promover agora."))
		return
	Som.tocar("promover", 1.1)
	menus.dica_cumprida("blocos")
	_flutuar(Idioma.t("%d peça promovida") % n if n == 1 else Idioma.t("%d peças promovidas") % n, pos_boneco(i) + Vector2(0, -150), Desenho.DOURADO, 16, 1.4)
	estado.salvar()
	_lista_suja = true
	var destino: Vector2 = rect_promover(i).get_center()
	_gastar_tijolos(antes - estado.tijolos, destino)
	_faisca(destino, Desenho.DOURADO, 16, 200.0)
	for s in Pecas.SLOTS:
		if b.pecas[s] != null:
			_faisca(pos_slot(i, s), Color(1.0, 0.92, 0.5), 5, 110.0)
	b.pop = 1.0

# ---- fusão
func _resultado_fusao(base: Peca, outra: Peca) -> Peca:
	var r := Peca.new(base.tipo, maxi(base.nivel, outra.nivel), maxi(base.raridade, outra.raridade))
	if r.nivel < Balanco.NIVEL_MAX:
		r.nivel += 1
	else:
		r.raridade += 1
	var soma: Array[int] = []
	soma.append_array(base.marcas)
	soma.append_array(outra.marcas)
	for m in soma:
		r.marcar(m)
	return r

func _rot_peca(q: Peca) -> String:
	return Idioma.t("%s%s nível %d") % [Idioma.t(Pecas.NOME[q.tipo]), (" " + Idioma.t(Pecas.RARIDADE_NOME[q.raridade]).to_lower()) if q.raridade > 0 else "", q.nivel]

func _rot_marcas(n: int) -> String:
	return Idioma.t("sem marcas") if n == 0 else (Idioma.t("1 marca") if n == 1 else Idioma.t("%d marcas") % n)

## A peça sob o ponto que `solta` pode fundir (mesmo tipo, outra peça, ainda há o que melhorar); null se nenhuma.
func _alvo_fusao(p: Vector2, solta: Peca) -> Peca:
	var ss: Vector2i = _slot_em(p)
	if ss.x >= 0:
		var q: Peca = estado.bonecos[ss.x].pecas[ss.y]
		if q != null and q != solta and estado.pode_fundir(q, solta):
			return q
	var ti: int = _tile_em(p)
	if ti >= 0:
		var q2: Peca = _visiveis()[ti]
		if q2 != solta and estado.pode_fundir(q2, solta):
			return q2
	return null

func _pedir_fusao(alvo: Peca, solta: Peca) -> void:
	var base: Peca = alvo
	var outra: Peca = solta
	# a que está vestida fica no lugar (a fundida não pode sumir do gato nem trocar de lugar)
	if estado.dono_de(solta) != null and estado.dono_de(alvo) == null:
		base = solta
		outra = alvo
	fusao = {"base": base, "outra": outra}
	Som.tocar("abrir")

func _cancelar_fusao() -> void:
	fusao = {}
	Som.tocar("fechar")

func _confirmar_fusao() -> void:
	if fusao.is_empty():
		return
	var base: Peca = fusao["base"]
	var outra: Peca = fusao["outra"]
	fusao = {}
	if estado.fundir(base, outra):
		_lista_suja = true
		desfazer = {}   # uma peça deixou de existir: a foto antiga não vale mais
		efeito_peca = {"peca": base, "t": 0.0}
		Som.tocar("fundir")
		var pos: Vector2 = _pos_peca(base)
		if pos.x >= 0.0:
			_faisca(pos, Color(1.0, 0.95, 0.6), 22, 230.0)
			_faisca(pos, Color(0.6, 1.0, 0.7), 12, 160.0)
	else:
		negado = 0.5

func _clique_fusao(ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = ev as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or mb.pressed:
		return
	if FUSAO_OK.has_point(mb.position):
		_confirmar_fusao()
	elif FUSAO_NAO.has_point(mb.position):
		_cancelar_fusao()

## Centro na tela da peça (no gato ou no guarda-roupa); (-1, -1) se não está à vista.
func _pos_peca(q: Peca) -> Vector2:
	var d: Boneco = estado.dono_de(q)
	if d != null:
		return pos_slot(estado.bonecos.find(d), q.slot())
	var i: int = _visiveis().find(q)
	if i >= 0:
		var r: Rect2 = rect_tile(i)
		if r.size.x > 0.0:
			return r.get_center()
	return Vector2(-1, -1)

## Recalcula, para cada tipo com peças repetidas, se alguma dupla ainda pode fundir.
func _atualizar_pares() -> void:
	var sg: int = _sig_colecao()
	if sg == _pares_sig:
		return
	_pares_sig = sg
	_pares.clear()
	var por_tipo: Dictionary = {}
	for q in estado.guarda:
		if not por_tipo.has(q.tipo):
			por_tipo[q.tipo] = []
		por_tipo[q.tipo].append(q)
	for b in estado.bonecos:
		for q in b.pecas:
			if q != null:
				if not por_tipo.has(q.tipo):
					por_tipo[q.tipo] = []
				por_tipo[q.tipo].append(q)
	for tp in por_tipo:
		var l: Array = por_tipo[tp]
		if l.size() < 2:
			continue
		var achou: bool = false
		for x in l:
			for y in l:
				if x != y and estado.pode_fundir(x, y):
					achou = true
					break
			if achou:
				break
		if achou:
			_pares[tp] = l.size()

# ------------------------------------------------------------------ entrada
func _gui_input(ev: InputEvent) -> void:
	if oficina != null and oficina.aberta:
		return   # a oficina cobre a tela e fica com todos os cliques
	if modo == Modo.MAPA:
		_entrada_mapa(ev)
		return
	if modo != Modo.GUARDA:
		return
	if ev is InputEventMouseMotion:
		mouse = (ev as InputEventMouseMotion).position
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		mouse = mb.position
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if nome_idx >= 0:
				_fim_nome_por_clique()
				return
			var ln: int = _lapis_em(mb.position)
			if ln < 0 and mb.double_click:
				ln = _ficha_em(mb.position)
			if ln >= 0 and _pode_renomear():
				arrasto = {}
				_iniciar_nome(ln)
				return
		if mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			if PAINEL.has_point(mb.position):
				_visiveis()
				var d: int = -1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1
				rolagem = clampi(rolagem + d, 0, _rolagem_max())
			return
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and arrasto.is_empty():
			var pr: Peca = _peca_sob_mouse()
			if pr != null:
				abrir_fichario(pr.conjunto())   # botão direito numa peça: fichário na fantasia dela
			return
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_apertar(mb.position)
		else:
			_soltar(mb.position)

func _entrada_mapa(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		mouse = (ev as InputEventMouseMotion).position
		mapa_casa.usar_mouse = true
		var f: int = _comodo_em(mouse)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if f >= 1 and f <= estado.fase_liberada else Control.CURSOR_ARROW
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		mouse = mb.position
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			if MAPA_EM_CORTE:
				if estado.schro_liberado() and MapaCasa.caixa_em(mb.position):
					mapa_casa.escolher_caixa()   # o painel mostra o chefe secreto; "Abrir a caixa" entra
					return
				var bt: int = MapaCasa.botao_em(mb.position, estado.campanha_vencida())
				if bt != MapaCasa.BOTAO_NENHUM:
					_botao_do_mapa(bt)
					return
			var f: int = _comodo_em(mb.position)
			if f >= 1 and f <= estado.fase_liberada:
				if MAPA_EM_CORTE and estado.campanha_vencida():
					mapa_casa.escolher(f)   # campanha vencida: o clique escolhe; "Jogar de novo" e "Invasão sem fim" entram
				else:
					menus.ir(_escolher_fase.bind(f))

## Botões do mapa depois de zerar: "Jogar o cômodo", "Invasão sem fim" (do cômodo em destaque) e "Final".
func _botao_do_mapa(bt: int) -> void:
	if menus.ativo() or menus.em_transicao():
		return
	if bt == MapaCasa.BOTAO_FINAL:
		menus.ir(menus.mostrar_final)
		return
	if mapa_casa.botao_troca_vista(bt):   # segundo ato: "Ver a casa" / "Ver lá fora" / "Ir lá fora"
		return
	var f: int = mapa_casa.destaque()
	if f == MapaCasa.CAIXA:
		if bt == MapaCasa.BOTAO_JOGAR:
			menus.ir(_escolher_secreto)
		return
	if f < 1 or f > estado.fase_liberada:
		return
	if bt == MapaCasa.BOTAO_INVASAO:
		menus.ir(_escolher_invasao.bind(f))
	else:
		menus.ir(_escolher_fase.bind(f, false, mapa_casa.casa_rejogo()))

## Cômodo (ou cartão) sob o ponto, conforme o mapa em uso; -1 se nenhum.
func _comodo_em(pos: Vector2) -> int:
	return MapaCasa.comodo_em(pos) if MAPA_EM_CORTE else _cartao_em(pos)

## Teclado no mapa da casa: setas trocam o cômodo destacado, Enter/Espaço entram.
func _unhandled_key_input(ev: InputEvent) -> void:
	if oficina != null and oficina.aberta:
		return
	var k: InputEventKey = ev as InputEventKey
	if nome_idx >= 0:
		return   # digitando o nome de um gato: nenhum atalho dispara
	if not fusao.is_empty():
		if k != null and k.pressed and not k.echo and (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER):
			_confirmar_fusao()
		return
	if k != null and k.pressed and not k.echo and modo == Modo.GUARDA and not menus.ativo() and not menus.em_transicao() and (fichario == null or not fichario.aberto()):
		if _tecla_guarda(k):
			return
	if k != null and k.pressed and not k.echo and k.keycode == KEY_T and (modo == Modo.MAPA or modo == Modo.GUARDA):
		abrir_oficina()   # atalho da oficina da torre
		return
	if k != null and k.pressed and not k.echo and k.keycode == KEY_F and (modo == Modo.MAPA or modo == Modo.GUARDA):
		var fr0: int = fant_recente if modo == Modo.GUARDA else -1
		fant_recente = -1
		abrir_fichario(fr0)
		return
	if not MAPA_EM_CORTE or modo != Modo.MAPA or mapa_casa == null:
		return
	if menus.ativo() or menus.em_transicao():
		return
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_C and estado.schro_liberado():
		mapa_casa.escolher_caixa()   # atalho da caixa do Sótão: escolhe a caixa (Enter ou "Abrir a caixa" entram)
		return
	if k.keycode == KEY_I and estado.campanha_vencida():
		if mapa_casa.vista_fora():
			# lá fora só o lugar já vencido no 2º ato oferece a invasão sem fim
			var fo_i: int = mapa_casa.destaque()
			if mapa_casa.invasao_fora_liberada(fo_i):
				menus.ir(_escolher_invasao.bind(fo_i))
			return
		var fi_i: int = mapa_casa.destaque()
		if fi_i >= 1 and fi_i <= estado.fase_liberada:
			menus.ir(_escolher_invasao.bind(fi_i))
		return
	var f: int = mapa_casa.tecla(k.keycode)
	if f == MapaCasa.CAIXA:
		menus.ir(_escolher_secreto)
		return
	if f >= 1 and f <= estado.fase_liberada:
		menus.ir(_escolher_fase.bind(f, false, mapa_casa.casa_rejogo()))

func _fechar_janelas() -> void:
	oficina.fechar()
	if atelie_tela != null:
		atelie_tela.fechar()
	if fichario != null:
		fichario.fechar()

## Abre o fichário (mapa e guarda-roupa; nunca na luta, com menu, cortina, oficina ou confirmação).
func abrir_fichario(fantasia: int = -1) -> void:
	if modo != Modo.MAPA and modo != Modo.GUARDA:
		return
	if menus.ativo() or menus.em_transicao() or oficina.aberta or not fusao.is_empty():
		return
	arrasto = {}
	fichario.estado = estado
	fichario.metas_novas = metas_selo.duplicate()
	fichario.abrir(fantasia)

func _pintar_botao_fichario(bt: BotaoArte) -> void:
	_pintar_botao(bt)
	var d: int = bt.get_draw_mode()
	var dy: float = 3.0 if (d == BaseButton.DRAW_PRESSED or d == BaseButton.DRAW_HOVER_PRESSED) else 0.0
	# livro: capa, páginas e lombada
	var o := Vector2(12, bt.size.y * 0.5 - 9.0 + dy)
	bt.draw_rect(Rect2(o.x, o.y, 22, 18), Color(0.22, 0.12, 0.08))
	bt.draw_rect(Rect2(o.x + 2, o.y + 2, 18, 14), Color(0.55, 0.28, 0.25))
	bt.draw_rect(Rect2(o.x + 4, o.y + 4, 14, 10), Color(1.0, 0.95, 0.8))
	bt.draw_rect(Rect2(o.x + 10, o.y + 2, 2, 14), Color(0.22, 0.12, 0.08))
	if not metas_selo.is_empty():
		# selo: há meta cumprida que o jogador ainda não viu na aba "Metas"
		# disco de pixel: contorno escuro, miolo vermelho, sombra embaixo e um brilho em cima
		var c: Vector2 = Vector2(bt.size.x - 8.0, 6.0)
		VFX.disco(bt, c, 12.0, Color(0.2, 0.08, 0.08), PX)
		VFX.disco(bt, c, 9.0, Color(0.72, 0.16, 0.18), PX)
		VFX.disco(bt, c, 6.0, Color(0.95, 0.3, 0.3), PX)
		VFX.ponto(bt, c + Vector2(-PX * 2.0, -PX * 2.0), Color(1.0, 0.68, 0.62), PX)
		Desenho.texto(bt, str(metas_selo.size()), Vector2(c.x - 12.0, c.y + 5.0), 14, Color.WHITE, 24.0)

## Botão do Ateliê: aparece no mapa e no guarda-roupa quando o fichário está completo.
func _atualizar_atelie() -> void:
	if btn_atelie == null:
		return
	var livre: bool = (modo == Modo.MAPA or modo == Modo.GUARDA) and btn_fich.visible and Atelie.liberado(estado) and not menus.ativo() and not menus.em_transicao()
	btn_atelie.visible = livre
	if livre:
		var r: Rect2 = ATELIE_BT_MAPA if modo == Modo.MAPA else ATELIE_BT_GUARDA
		btn_atelie.position = r.position
		btn_atelie.size = r.size
	elif atelie_tela.aberta:
		atelie_tela.fechar()

## Abre o Ateliê (só no mapa e no guarda-roupa, com o fichário completo e sem outra janela por cima).
func abrir_atelie() -> void:
	if modo != Modo.MAPA and modo != Modo.GUARDA:
		return
	if menus.ativo() or menus.em_transicao() or oficina.aberta or (fichario != null and fichario.aberto()) or not fusao.is_empty():
		return
	arrasto = {}
	atelie_tela.abrir()

func _pintar_botao_atelie(bt: BotaoArte) -> void:
	_pintar_botao(bt)
	var d: int = bt.get_draw_mode()
	var dy: float = 3.0 if (d == BaseButton.DRAW_PRESSED or d == BaseButton.DRAW_HOVER_PRESSED) else 0.0
	# estrela de pixel (a fantasia secreta)
	var o := Vector2(12, bt.size.y * 0.5 - 9.0 + dy)
	var ouro := Color(1.0, 0.85, 0.3)
	var esc := Color(0.45, 0.28, 0.0)
	bt.draw_rect(Rect2(o.x + 8, o.y, 4, 18), esc)
	bt.draw_rect(Rect2(o.x, o.y + 7, 20, 4), esc)
	bt.draw_rect(Rect2(o.x + 4, o.y + 4, 12, 10), esc)
	bt.draw_rect(Rect2(o.x + 9, o.y + 1, 2, 16), ouro)
	bt.draw_rect(Rect2(o.x + 1, o.y + 8, 18, 2), ouro)
	bt.draw_rect(Rect2(o.x + 5, o.y + 5, 10, 8), ouro)
	var fonte: Font = UIComum.FONTE
	var tam: int = bt.tam_fonte
	var y: float = (bt.size.y - fonte.get_height(UIComum.tam(tam))) * 0.5 + fonte.get_ascent(UIComum.tam(tam)) - 3.0 + dy
	bt.draw_string_outline(fonte, Vector2(40, y), ROTULO_ATELIE, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam), 6, Color(0.16, 0.07, 0.05, 0.95))
	bt.draw_string(fonte, Vector2(40, y), Idioma.t(ROTULO_ATELIE), HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam), Color.WHITE)

## Abre a oficina da torre (só no mapa e no guarda-roupa, sem menu nem cortina por cima).
func abrir_oficina() -> void:
	if modo != Modo.MAPA and modo != Modo.GUARDA:
		return
	if menus.ativo() or menus.em_transicao():
		return
	arrasto = {}
	oficina.abrir()

func _posicionar_torre(r: Rect2) -> void:
	btn_torre.position = r.position
	btn_torre.size = r.size
	btn_torre.visible = true

## Há algo para fazer na oficina: troféus que pagam uma melhoria ou módulo liberado com vaga livre.
func oficina_tem_novidade() -> bool:
	for m in Torre.MELHORIA_NOME.size():
		if estado.pode_melhorar(m):
			return true
	if estado.modulos.size() < estado.vagas_modulos():
		for m in Torre.MODULO_NOME.size():
			if estado.modulo_liberado(m) and not estado.tem_modulo(m):
				return true
	return false

## Pinta o botão "Torre": moldura de botão, troféu, nome e a contagem de troféus à direita.
func _pintar_botao_torre(bt: BotaoArte) -> void:
	bt.brilho = oficina_tem_novidade()
	_pintar_botao(bt)
	var d: int = bt.get_draw_mode()
	var apertado: bool = d == BaseButton.DRAW_PRESSED or d == BaseButton.DRAW_HOVER_PRESSED
	var dy: float = 3.0 if apertado else 0.0
	var fonte: Font = UIComum.FONTE
	var tam: int = bt.tam_fonte
	var y: float = (bt.size.y - fonte.get_height(UIComum.tam(tam))) * 0.5 + fonte.get_ascent(UIComum.tam(tam)) - 3.0 + dy
	Oficina.trofeu(bt, Vector2(16, (bt.size.y - 20.0) * 0.5 - 1.0 + dy), 2.0)
	var tam_l: int = mini(tam, 17)
	bt.draw_string_outline(fonte, Vector2(42, y), Idioma.t("Torre [T]"), HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam_l), 6, Color(0.16, 0.07, 0.05, 0.95))
	bt.draw_string(fonte, Vector2(42, y), Idioma.t("Torre [T]"), HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam_l), Color.WHITE)
	var n: String = str(estado.trofeus)
	var xn: float = bt.size.x - 14.0 - fonte.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam)).x
	bt.draw_string_outline(fonte, Vector2(xn, y), n, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam), 6, Color(0.16, 0.07, 0.05, 0.95))
	bt.draw_string(fonte, Vector2(xn, y), n, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam), Color(1.0, 0.92, 0.45))

func _apertar(p: Vector2) -> void:
	if avisos_aberto:
		_clicar_avisos(p)
		return
	if not avisos_cache.is_empty() and CHIP_AV.has_point(p):
		avisos_aberto = true
		Som.tocar("abrir")
		return
	if filtro_cj >= 0 and FILTRO_R.has_point(p):
		filtro_cj = -1
		_lista_suja = true
		rolagem = 0
		Som.tocar("aba")
		return
	for fr in _rect_fant:
		if (fr[0] as Rect2).has_point(p):
			filtro_cj = -1 if filtro_cj == int(fr[1]) else int(fr[1])
			_selecionar(int(fr[2]))
			_lista_suja = true
			rolagem = 0
			Som.tocar("aba")
			return
	var ab: int = _aba_em(p)
	if ab != -2:
		_trocar_aba(ab)
		return
	var ai: Vector2i = _atr_em(p)
	if ai.x >= 0:
		var bt: Boneco = estado.bonecos[ai.x]
		if bt.pontos > 0 and estado.treinar(bt, ai.y):
			Som.tocar("treino")
			_flutuar("+1 " + Idioma.t(Balanco.ATR_NOMES[ai.y]), pos_boneco(ai.x) + Vector2(0, -170), Color(0.7, 1.0, 0.6), 16, 1.0)
			_faisca(pos_boneco(ai.x) + Vector2(0, -150), Color(0.7, 1.0, 0.6), 14, 150.0)
			_faisca(rect_atr(ai.x, ai.y).get_center(), Color(1.0, 0.9, 0.4), 10, 120.0)
			_marcar_treino_explicado()
		return
	var ri: int = _reforcar_em(p)
	if ri >= 0:
		_acao_reforcar_tudo(ri)
		return
	var pi: int = _promover_em(p)
	if pi >= 0:
		_acao_promover_tudo(pi)
		return
	if _clique_heranca(p):
		return
	var li: int = _linha_em(p)
	if li >= 0:
		var bl: Boneco = estado.bonecos[li]
		bl.linha = (bl.linha + 1) % Boneco.LINHA_NOMES.size()  # frente -> meio -> fundo
		bl.posto = Boneco.SEM_POSTO   # escolher a linha aqui desfaz o posto e a ordem dados na preparação da luta
		bl.postura = -1
		Som.tocar("clique", 0.9)
		return
	var fc: int = _cartao_fant_em(p)
	if fc >= 0:
		_vestir_fantasia(fc)
		return
	var ti: int = _tile_em(p)
	if ti >= 0:
		var pc: Peca = _visiveis()[ti]
		pc.nova = false
		arrasto = {"peca": pc, "origem": null, "p0": p}
		Som.tocar("pegar")
		return
	var ss: Vector2i = _slot_em(p)
	if ss.x >= 0:
		var b: Boneco = estado.bonecos[ss.x]
		if b.pecas[ss.y] != null:
			arrasto = {"peca": b.pecas[ss.y], "origem": b, "p0": p}
			Som.tocar("pegar")
			return
	var bi: int = _boneco_em(p)
	if bi >= 0:
		arrasto = {"boneco": estado.bonecos[bi], "idx": bi, "p0": p}
		return
	# nome ou chão da coluna: só seleciona (arrastar dali não tira a roupa)
	var ci: int = _coluna_em(p)
	if ci >= 0:
		arrasto = {"boneco": estado.bonecos[ci], "idx": ci, "p0": p, "so_selecao": true}
		return
	# fundo vazio do palco: desseleciona
	if Rect2(208, 0, 772, 446).has_point(p):
		_desselecionar()

func _marcar_treino_explicado() -> void:
	if treino_explicado:
		return
	treino_explicado = true
	if estado.persistir and Menus.gravar:
		var cfg := ConfigFile.new()
		cfg.load(Menus.cfg_caminho)
		cfg.set_value("ui", "treino_explicado", true)
		cfg.save(Menus.cfg_caminho)

func _soltar(p: Vector2) -> void:
	if arrasto.is_empty():
		return
	var a: Dictionary = arrasto
	arrasto = {}
	if a.has("p0") and p.distance_to(a["p0"]) < 8.0:
		_clicar(a)
		return
	if a.has("peca"):
		var pc: Peca = a["peca"]
		var origem: Boneco = a["origem"]
		if ALVO_CARRETEL.has_point(p):
			promover(pc)
		elif ALVO_ESTRELA.has_point(p):
			reforcar(pc)
		elif BIGORNA.has_point(p):
			pass   # soltou no título do painel: não é nenhum dos alvos
		else:
			var alvo: Peca = _alvo_fusao(p, pc)
			if alvo != null:
				_pedir_fusao(alvo, pc)
				return
			var bi: int = _boneco_em(p)
			if bi >= 0:
				vestir(bi, pc)
			elif PAINEL.has_point(p) and origem != null:
				tirar(estado.bonecos.find(origem), pc.slot())
	elif a.has("boneco") and not a.has("so_selecao"):
		var b: Boneco = a["boneco"]
		if PAINEL.has_point(p):
			var idx: int = estado.bonecos.find(b)
			for s in Pecas.SLOTS:
				if b.pecas[s] != null:
					tirar(idx, s)

# ------------------------------------------------------------------ atualização
## Os botões guardam o texto ao montar: remonta os rótulos fixos quando o idioma muda.
func _rotular_botoes() -> void:
	btn_lutar.text = Idioma.t("LUTAR")
	btn_mapa.text = Idioma.t("Mapa")
	btn_voltar.text = Idioma.t("Voltar ao mapa")
	btn_time.text = Idioma.t("Vestir o time")
	btn_desf.text = Idioma.t("Desfazer")
	btn_fich.text = Idioma.t("Fichário [F]")
	if confirma_nova <= 0.0:
		btn_nova.text = Idioma.t("Nova campanha")
	btn_melhor.tooltip_text = Idioma.t("Monta as melhores fantasias para o gato selecionado (V = o time todo).")
	btn_time.tooltip_text = Idioma.t("Monta as melhores fantasias para todos os gatos (tecla V).")
	btn_desf.tooltip_text = Idioma.t("Volta as roupas como estavam antes da última montagem automática (tecla Z).")
	btn_ajuda.tooltip_text = Idioma.t("Repete o tutorial desta tela (F1: atalhos e regras).")

func _process(delta: float) -> void:
	t += delta
	if Idioma.atual != _idioma_vis:
		_idioma_vis = Idioma.atual
		_rotular_botoes()
	Musica.atualizar(self, delta)   # a faixa segue a tela (título, mapa, luta por ato, chefe, fim, final)
	# posição real do ponteiro a cada quadro: um botão filho captura o movimento e a posição guardada ficava velha;
	# com menu, oficina ou cortina por cima o ponteiro "some" para a tela de baixo (sem dicas nem destaques fantasmas)
	if menus.ativo() or menus.em_transicao() or (oficina != null and oficina.aberta) or (atelie_tela != null and atelie_tela.aberta):
		mouse = Vector2(-500, -500)
	else:
		mouse = get_local_mouse_position()
	negado = maxf(0.0, negado - delta)
	nome_aviso_t = maxf(0.0, nome_aviso_t - delta)
	if nome_idx >= 0 and (modo != Modo.GUARDA or menus.ativo() or menus.em_transicao() or not fusao.is_empty()):
		_fechar_nome()
	msg_painel_t = maxf(0.0, msg_painel_t - delta)
	if not efeito_peca.is_empty():
		efeito_peca["t"] = float(efeito_peca["t"]) + delta
		if float(efeito_peca["t"]) > 0.8:
			efeito_peca = {}
	# nada pendurado: a confirmação de fusão só vive no guarda-roupa, sem menu, cortina ou oficina por cima
	if not fusao.is_empty() and (modo != Modo.GUARDA or menus.ativo() or menus.em_transicao() or (oficina != null and oficina.aberta)):
		fusao = {}
	if fichario != null:
		fichario.estado = estado
		if fichario.aberto() and (not (modo == Modo.MAPA or modo == Modo.GUARDA) or menus.ativo() or menus.em_transicao()):
			fichario.fechar()
	_atualizar_atelie()
	fusao_bloq.visible = not fusao.is_empty()
	fusao_bloq.mouse_filter = Control.MOUSE_FILTER_STOP if not fusao.is_empty() else Control.MOUSE_FILTER_IGNORE
	aviso_t = maxf(0.0, aviso_t - delta)
	_conferir_avisos_metas()
	if confirma_nova > 0.0:
		confirma_nova -= delta
		if confirma_nova <= 0.0 and modo == Modo.MAPA:
			btn_nova.text = Idioma.t("Nova campanha")
	for b in estado.bonecos:
		b.pop = maxf(0.0, b.pop - delta * 3.0)
		b.nasc = minf(1.0, b.nasc + delta * 3.5)
	for i in range(faiscas.size() - 1, -1, -1):
		var f: Dictionary = faiscas[i]
		f["vida"] -= delta
		if f["vida"] <= 0.0:
			faiscas.remove_at(i)
			continue
		var v: Vector2 = f["v"]
		v.y += 400.0 * delta
		f["v"] = v
		f["p"] = f["p"] + v * delta
	for i in range(tijolos_voando.size() - 1, -1, -1):
		var tv: Dictionary = tijolos_voando[i]
		tv["t"] += delta / 0.8
		if tv["t"] >= 1.0:
			tijolos_voando.remove_at(i)
	_atualizar_guarda(delta)
	if modo == Modo.FIM:
		_animar_fim(delta)
	if modo != Modo.COMBATE:
		# fichário ou oficina abertos: o fundo fica atrás de uma cortina preta de 74% e de um painel cheio,
		# então basta redesenhá-lo nos quadros da abertura (o mapa e o guarda-roupa custam 15 a 30 ms por desenho);
		# depois fica congelado: redesenhar a cada 4 quadros fazia uma trava de ~30 ms bem na janela
		var coberto: bool = (fichario != null and fichario.aberto()) or (oficina != null and oficina.aberta)
		if coberto and _coberto_ant:
			_coberto_q = mini(_coberto_q + 1, 99)
			if _coberto_q <= 3:
				queue_redraw()
		else:
			_coberto_q = 0
			queue_redraw()
		_coberto_ant = coberto

# ------------------------------------------------------------------ utilidades de texto
## Quebra o texto em linhas que cabem em `larg` pixels.
func _quebrar(txt: String, tam: int, larg: float) -> Array[String]:
	# a fonte não muda: a mesma quebra é pedida a cada quadro pelos avisos e dicas (cópia, para ninguém mexer no cache)
	var chave: int = hash([txt, tam, larg])
	var ent: Array = _quebrar_c.get(chave, [])
	if not ent.is_empty() and ent[0] == txt and ent[1] == tam and ent[2] == larg:
		var cop: Array[String] = []
		cop.assign(ent[3])
		return cop
	var res: Array[String] = _quebrar_calc(txt, tam, larg)
	if _quebrar_c.size() > 400:
		_quebrar_c.clear()
	_quebrar_c[chave] = [txt, tam, larg, res.duplicate()]
	return res

func _quebrar_calc(txt: String, tam: int, larg: float) -> Array[String]:
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

## Escreve um parágrafo quebrado; devolve o y logo abaixo da última linha.
func _paragrafo(txt: String, pos: Vector2, tam: int, cor: Color, larg: float, passo: float, centro: bool = false, contorno: int = 0) -> float:
	var y: float = pos.y
	for l in _quebrar(txt, tam, larg):
		Desenho.texto(_c, l, Vector2(pos.x, y), tam, cor, larg if centro else -1.0, contorno)
		y += passo
	return y

func _com_alfa(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, c.a * a)

# ------------------------------------------------------------------ pintura com as molduras do pacote
## Repete (em ladrilho, sem esticar) o recorte `s` da imagem dentro de `d`, em escala `esc`.
static func ladrilhar(c: CanvasItem, tex: Texture2D, s: Rect2, d: Rect2, esc: float, cor: Color) -> void:
	if d.size.x <= 0.5 or d.size.y <= 0.5 or s.size.x <= 0.0 or s.size.y <= 0.0:
		return
	var sw: float = s.size.x * esc
	var sh: float = s.size.y * esc
	var y: float = d.position.y
	while y < d.end.y - 0.01:
		var h: float = minf(sh, d.end.y - y)
		var x: float = d.position.x
		while x < d.end.x - 0.01:
			var w: float = minf(sw, d.end.x - x)
			c.draw_texture_rect_region(tex, Rect2(x, y, w, h), Rect2(s.position, Vector2(w / esc, h / esc)), cor)
			x += sw
		y += sh

## Recorte em 9 fatias: cantos fixos, bordas e miolo repetidos. `m` = margens (esq, topo, dir, base) em px da imagem.
static func nove(c: CanvasItem, tex: Texture2D, src: Rect2, m: Vector4, dst: Rect2, esc: float, cor: Color = Color.WHITE, miolo: bool = true) -> void:
	var e: float = minf(esc, minf(dst.size.x / maxf(1.0, m.x + m.z), dst.size.y / maxf(1.0, m.y + m.w)))
	var ml: float = m.x * e
	var mt: float = m.y * e
	var mr: float = m.z * e
	var mb: float = m.w * e
	var x0: float = dst.position.x
	var y0: float = dst.position.y
	var x1: float = x0 + ml
	var y1: float = y0 + mt
	var x2: float = dst.end.x - mr
	var y2: float = dst.end.y - mb
	var sx: float = src.position.x
	var sy: float = src.position.y
	var iw: float = src.size.x - m.x - m.z
	var ih: float = src.size.y - m.y - m.w
	c.draw_texture_rect_region(tex, Rect2(x0, y0, ml, mt), Rect2(sx, sy, m.x, m.y), cor)
	c.draw_texture_rect_region(tex, Rect2(x2, y0, mr, mt), Rect2(sx + src.size.x - m.z, sy, m.z, m.y), cor)
	c.draw_texture_rect_region(tex, Rect2(x0, y2, ml, mb), Rect2(sx, sy + src.size.y - m.w, m.x, m.w), cor)
	c.draw_texture_rect_region(tex, Rect2(x2, y2, mr, mb), Rect2(sx + src.size.x - m.z, sy + src.size.y - m.w, m.z, m.w), cor)
	ladrilhar(c, tex, Rect2(sx + m.x, sy, iw, m.y), Rect2(x1, y0, x2 - x1, mt), e, cor)
	ladrilhar(c, tex, Rect2(sx + m.x, sy + src.size.y - m.w, iw, m.w), Rect2(x1, y2, x2 - x1, mb), e, cor)
	ladrilhar(c, tex, Rect2(sx, sy + m.y, m.x, ih), Rect2(x0, y1, ml, y2 - y1), e, cor)
	ladrilhar(c, tex, Rect2(sx + src.size.x - m.z, sy + m.y, m.z, ih), Rect2(x2, y1, mr, y2 - y1), e, cor)
	if miolo:
		ladrilhar(c, tex, Rect2(sx + m.x, sy + m.y, iw, ih), Rect2(x1, y1, x2 - x1, y2 - y1), e, cor)

## Painel: miolo colorido com moldura de madeira por cima.
func _painel(r: Rect2, fundo: Color, esc: float = 0.5, moldura: Color = Color.WHITE) -> void:
	_c.draw_rect(r.grow(-6.0 * esc * 2.0), fundo)
	_c.draw_rect(r.grow(-12.0 * esc * 2.0), Color(0, 0, 0, 0.18), false, 2.0)
	nove(_c, GUI_TEX, R_MADEIRA, M_MADEIRA, r, esc, moldura, false)

## Botão de papel/bege com tinta `cor` (usa o recorte de botão solto ou apertado).
func _botao_arte(r: Rect2, cor: Color, apertado: bool = false, esc: float = 0.5) -> void:
	if apertado:
		var rr := Rect2(r.position.x, r.position.y + 4.0 * esc, r.size.x, r.size.y - 4.0 * esc)
		nove(_c, BOT_TEX, R_BT_P, M_BT, rr, esc, cor)
	else:
		nove(_c, BOT_TEX, R_BT_N, M_BT, r, esc, cor)

func _pintar_botao(bt: BotaoArte) -> void:
	var d: int = bt.get_draw_mode()
	var apertado: bool = d == BaseButton.DRAW_PRESSED or d == BaseButton.DRAW_HOVER_PRESSED
	var sobre: bool = d == BaseButton.DRAW_HOVER or d == BaseButton.DRAW_HOVER_PRESSED
	var cor: Color = bt.tom
	if bt.disabled:
		cor = Color(0.55, 0.55, 0.58)
	elif apertado:
		cor = cor.darkened(0.14)
	elif sobre:
		cor = cor.lightened(0.2)
	var r := Rect2(Vector2.ZERO, bt.size)
	if bt.brilho and not bt.disabled:
		var pu: float = 0.5 + 0.5 * sin(bt.t_ui * 3.0)
		bt.draw_rect(r.grow(5.0), Color(1.0, 0.82, 0.3, 0.18 + 0.28 * pu), false, 4.0)
		bt.draw_rect(r.grow(9.0), Color(1.0, 0.82, 0.3, 0.06 + 0.1 * pu), false, 3.0)
	var dy: float = 0.0
	if apertado:
		var rr := Rect2(0, 4.0 * bt.esc, bt.size.x, bt.size.y - 4.0 * bt.esc)
		nove(bt, BOT_TEX, R_BT_P, M_BT, rr, bt.esc, cor)
		dy = 3.0
	else:
		nove(bt, BOT_TEX, R_BT_N, M_BT, r, bt.esc, cor)
	var fonte: Font = UIComum.FONTE
	var tam: int = bt.tam_fonte
	var y: float = (bt.size.y - fonte.get_height(UIComum.tam(tam))) * 0.5 + fonte.get_ascent(UIComum.tam(tam)) - 3.0 + dy
	var ct: Color = Color(1, 1, 1, 0.55) if bt.disabled else Color.WHITE
	bt.draw_string_outline(fonte, Vector2(0, y), bt.text, HORIZONTAL_ALIGNMENT_CENTER, bt.size.x, UIComum.tam(tam), 7, Color(0.16, 0.07, 0.05, 0.95))
	bt.draw_string(fonte, Vector2(0, y), bt.text, HORIZONTAL_ALIGNMENT_CENTER, bt.size.x, UIComum.tam(tam), ct)

## Barra em pixel: contorno escuro de um quadradinho com as quinas cortadas, trilho escuro e miolo `cor`
## com faixa clara em cima e escura embaixo. Altura e preenchimento andam de PX em PX.
func _barra(r: Rect2, frac: float, cor: Color, atras: float = -1.0, cor_atras: Color = Color(0.55, 0.8, 1.0, 0.75)) -> void:
	var rr := Rect2(roundf(r.position.x), roundf(r.position.y), maxf(PX * 2.0, roundf(r.size.x / PX) * PX), maxf(PX * 2.0, roundf(r.size.y / PX) * PX))
	UIComum.forma(self, rr.grow(PX), Color(0.07, 0.04, 0.08), PX)
	draw_rect(rr, Color(0.2, 0.14, 0.16))
	draw_rect(Rect2(rr.position.x, rr.end.y - PX, rr.size.x, PX), Color(0.14, 0.09, 0.11))
	if atras > 0.0:
		var wa: float = minf(rr.size.x, _sn(rr.size.x * clampf(atras, 0.0, 1.0) + PX * 0.5))
		if wa > 0.0:
			draw_rect(Rect2(rr.position, Vector2(wa, rr.size.y)), cor_atras)
	var f: float = clampf(frac, 0.0, 1.0)
	if f > 0.0:
		var w: float = clampf(_sn(rr.size.x * f + PX * 0.5), PX, rr.size.x)
		draw_rect(Rect2(rr.position, Vector2(w, rr.size.y)), cor)
		draw_rect(Rect2(rr.position, Vector2(w, PX)), cor.lightened(0.35))
		if rr.size.y >= PX * 3.0:
			draw_rect(Rect2(rr.position.x, rr.end.y - PX, w, PX), cor.darkened(0.3))

func _ruido(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)

# ------------------------------------------------------------------ pixel art da interface (grade de 3 px)
## O guarda-roupa é desenhado na grade de 3 px da moldura de madeira (gui_4x a 0,75) e dos efeitos (VfxPx):
## nada de círculo liso, linha fina ou degradê contínuo. Formas em faixas de PX, sem alocar nada por quadro.
const PX := 3.0
const VFX := preload("res://scripts/interface/vfx_px.gd")
const CONT_PX := Color(0.16, 0.08, 0.06)   # contorno escuro dos ícones de grade

func _sn(v: float) -> float:
	return floorf(v / PX) * PX

## Meia largura (já na grade) da linha `j` de uma elipse de `n` linhas e raio horizontal `rx`.
func _meia_px(j: int, n: int, rx: float) -> float:
	if j < 0 or j >= n:
		return 0.0
	var fy: float = ((j + 0.5) / n) * 2.0 - 1.0
	return maxf(PX, _sn(rx * sqrt(maxf(0.0, 1.0 - fy * fy)) + PX * 0.5))

## Elipse cheia em faixas de PX (as faixas não se sobrepõem: aceita alfa).
func _elipse_px(ce: Vector2, rx: float, ry: float, cor: Color) -> void:
	var n: int = maxi(1, int(roundf(ry * 2.0 / PX)))
	var cx: float = _sn(ce.x)
	var y0: float = _sn(ce.y - n * PX * 0.5 + PX * 0.5)
	for j in n:
		var w: float = _meia_px(j, n, rx)
		_c.draw_rect(Rect2(cx - w, y0 + j * PX, w * 2.0, PX), cor)

## Duas elipses concêntricas sem sobreposição: a de fora em `cor`, a de dentro em `cor2` (luz de pedestal).
func _elipse2_px(ce: Vector2, rx: float, ry: float, cor: Color, rx2: float, ry2: float, cor2: Color) -> void:
	var n: int = maxi(1, int(roundf(ry * 2.0 / PX)))
	var n2: int = maxi(1, int(roundf(ry2 * 2.0 / PX)))
	if (n - n2) % 2 != 0:
		n2 -= 1
	var d: int = (n - n2) / 2
	var cx: float = _sn(ce.x)
	var y0: float = _sn(ce.y - n * PX * 0.5 + PX * 0.5)
	for j in n:
		var w: float = _meia_px(j, n, rx)
		var y: float = y0 + j * PX
		var j2: int = j - d
		if n2 <= 0 or j2 < 0 or j2 >= n2:
			_c.draw_rect(Rect2(cx - w, y, w * 2.0, PX), cor)
			continue
		var w2: float = minf(_meia_px(j2, n2, rx2), w - PX)
		_c.draw_rect(Rect2(cx - w, y, w - w2, PX), cor)
		_c.draw_rect(Rect2(cx - w2, y, w2 * 2.0, PX), cor2)
		_c.draw_rect(Rect2(cx + w2, y, w - w2, PX), cor)

## Aro de elipse contínuo, um quadradinho de espessura: cada linha desenha só a borda que a separa das vizinhas.
func _aro_px(ce: Vector2, rx: float, ry: float, cor: Color) -> void:
	var n: int = maxi(1, int(roundf(ry * 2.0 / PX)))
	var cx: float = _sn(ce.x)
	var y0: float = _sn(ce.y - n * PX * 0.5 + PX * 0.5)
	for j in n:
		var w: float = _meia_px(j, n, rx)
		var lo: float = minf(minf(_meia_px(j - 1, n, rx), _meia_px(j + 1, n, rx)), w - PX)
		var y: float = y0 + j * PX
		if j == 0 or j == n - 1 or lo <= 0.0:
			_c.draw_rect(Rect2(cx - w, y, w * 2.0, PX), cor)
		else:
			_c.draw_rect(Rect2(cx - w, y, w - lo, PX), cor)
			_c.draw_rect(Rect2(cx + lo, y, w - lo, PX), cor)

## Feixe de luz em degraus: trapézio da base (y0, meia largura m0) até o topo (y1, m1), com o alfa
## caindo de a0 para a1 em `bandas` faixas. Linhas iguais seguidas viram um retângulo só.
func _feixe_px(cx: float, y0: float, m0: float, y1: float, m1: float, cor: Color, a0: float, a1: float, bandas: int = 4) -> void:
	var yb: float = _sn(y0)
	var n: int = int((yb - _sn(y1)) / PX)
	if n <= 0:
		return
	var cxs: float = _sn(cx)
	var run_j: int = 0
	var run_w: float = -1.0
	var run_b: int = -1
	for j in n + 1:
		var w: float = 0.0
		var b: int = -1
		if j < n:
			var k: float = (j + 0.5) / n
			w = _sn(lerpf(m0, m1, k) + PX * 0.5)
			b = mini(bandas - 1, int(k * bandas))
		if j == n or w != run_w or b != run_b:
			if run_b >= 0 and j > run_j:
				var a: float = lerpf(a0, a1, (run_b + 0.5) / bandas)
				if a > 0.004:
					_c.draw_rect(Rect2(cxs - run_w, yb - j * PX, run_w * 2.0, (j - run_j) * PX), Color(cor.r, cor.g, cor.b, cor.a * a))
			run_j = j
			run_w = w
			run_b = b

## Sombra/luz achatada no chão (elipse em faixas de pixel).
func _ellipse_sombra(p: Vector2, rx: float, ry: float, cor: Color) -> void:
	_elipse_px(p, rx, ry, cor)

## Estrela de 4 pontas em pixel (astroide em faixas): braços de `n` quadradinhos, sem sobreposição.
## Com `losango` (as miúdas, até 2 quadradinhos de braço) vira um losango: a astroide pequena virava um "+".
func _astro_px(cx: float, cy: float, n: int, cor: Color, losango: bool = false) -> void:
	for j in range(-n, n + 1):
		var w: int
		if losango:
			w = n - absi(j)
		else:
			var f: float = absf(j) / float(n)
			w = int(n * pow(maxf(0.0, 1.0 - pow(f, 0.6667)), 1.5) + 0.4)
		_c.draw_rect(Rect2(cx - w * PX, cy + j * PX, (2 * w + 1) * PX, PX), cor)

## Ícone de grade: cada letra é um quadradinho de `esc` px; letras iguais seguidas viram um retângulo só.
## k contorno, c cor, l cor clara, d cor escura, w creme, p rosa, m/n madeira clara/escura,
## r/R/q linha vermelha (média/escura/clara), y/Y ouro (claro/escuro). Ponto é transparente.
func _grade_px(cv: CanvasItem, g: Array[String], pos: Vector2, esc: float, cor: Color, alfa: float = 1.0) -> void:
	var x0: float = roundf(pos.x)
	var y0: float = roundf(pos.y)
	for y in g.size():
		var lin: String = g[y]
		var tam: int = lin.length()
		var x: int = 0
		while x < tam:
			var ch: int = lin.unicode_at(x)
			var x1: int = x + 1
			while x1 < tam and lin.unicode_at(x1) == ch:
				x1 += 1
			if ch != 46:   # "."
				var col: Color
				match ch:
					107: col = CONT_PX                       # k
					99: col = cor                            # c
					108: col = cor.lightened(0.45)           # l
					100: col = cor.darkened(0.35)            # d
					119: col = COR_TINTA                     # w
					112: col = Color(0.95, 0.55, 0.6)        # p
					109: col = Color(0.78, 0.58, 0.34)       # m
					110: col = Color(0.5, 0.33, 0.17)        # n
					114: col = Color(0.85, 0.2, 0.25)        # r
					82: col = Color(0.55, 0.08, 0.14)        # R
					113: col = Color(1.0, 0.5, 0.5)          # q
					121: col = Desenho.DOURADO               # y
					89: col = Color(0.72, 0.45, 0.08)        # Y
					_: col = cor
				cv.draw_rect(Rect2(x0 + x * esc, y0 + y * esc, (x1 - x) * esc, esc), Color(col.r, col.g, col.b, col.a * alfa))
			x = x1

const ICO_X: Array[String] = ["c...c", ".c.c.", "..c..", ".c.c.", "c...c"]
const ICO_MAIS: Array[String] = ["..lc..", "..lc..", "lllccc", "cccddd", "..cd..", "..dd.."]
const ICO_SETA: Array[String] = ["....c...", "....cc..", "lllllcc.", "cccccccc", "dddddcd.", "....cd..", "....d..."]
const ICO_NOVA: Array[String] = [".kkk.", "klcck", "kccck", "kccdk", ".kkk."]
const ICO_LAPIS: Array[String] = [".kkkkkk", "kwcccpk", "kkwddpk", ".kkkkkk"]
const ICO_CARRETEL: Array[String] = [
	"kkkkkkkkkkkk",
	"kmmmmmmmmmmk",
	"knnnnnnnnnnk",
	"kkkkkkkkkkkk",
	".kqrrRrrrRk.",
	".kqrRrrrRrk.",
	".kqRrrrRrrk.",
	".kRrrrRrrrk.",
	".kqrrRrrrRk.",
	".kqrRrrrRrk.",
	".kqRrrrRrrk.",
	"kkkkkkkkkkkk",
	"kmmmmmmmmmmk",
	"knnnnnnnnnnk",
	"kkkkkkkkkkkk",
]

func _texto_dir(txt: String, x_dir: float, y: float, tam: int, cor: Color, contorno: int = 0) -> void:
	var fonte: Font = UIComum.FONTE
	if contorno > 0:
		draw_string_outline(fonte, Vector2(x_dir - 400.0, y), txt, HORIZONTAL_ALIGNMENT_RIGHT, 400.0, UIComum.tam(tam), contorno, Color(0, 0, 0, 0.85))
	draw_string(fonte, Vector2(x_dir - 400.0, y), txt, HORIZONTAL_ALIGNMENT_RIGHT, 400.0, UIComum.tam(tam), cor)

## Maior tamanho (da lista) em que o texto cabe em `larg`.
func _tam_cabe(txt: String, tams: Array, larg: float) -> int:
	var chave: int = hash([txt, tams, larg])
	var ent: Array = _tam_cabe_c.get(chave, [])
	if not ent.is_empty() and ent[0] == txt and ent[1] == tams and ent[2] == larg:
		return int(ent[3])
	var res: int = int(tams[tams.size() - 1])
	var fonte: Font = UIComum.FONTE
	for tm in tams:
		if fonte.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(int(tm))).x <= larg:
			res = int(tm)
			break
	if _tam_cabe_c.size() > 400:
		_tam_cabe_c.clear()
	_tam_cabe_c[chave] = [txt, tams.duplicate(), larg, res]
	return res

func _icone_gui(ico: Rect2, centro: Vector2, esc: float, cor: Color = Color.WHITE) -> void:
	var tam: Vector2 = ico.size * esc
	draw_texture_rect_region(GUI_TEX, Rect2((centro - tam * 0.5).round(), tam), ico, cor)

## Estrelinha de 4 pontas na grade (braços de ~r px). `cont` com alfa > 0 põe contorno escuro (só em cor opaca).
## Lado do selo de herança (12 pixels da grade): aro de 1 + ícone de poder de 10 (IconesPoder na escala 3) + aro de 1.
const SELO_HER := 36.0
const SELO_MIOLO := Color(0.16, 0.08, 0.26)

## Selo de herança: o ícone do poder (IconesPoder, escala 3 = a grade de 3 px) num miolo escuro opaco, dentro de um aro
## de cantos cortados na cor `aro` (roxo = herança; o mesmo ícone sem aro é o poder da fantasia vestida). `c` = centro.
func _selo_heranca(c: Vector2, poder: int, aro: Color) -> void:
	var x: float = _sn(c.x - SELO_HER * 0.5 + PX * 0.5)
	var y: float = _sn(c.y - SELO_HER * 0.5 + PX * 0.5)
	var l: float = SELO_HER
	# aro de 1 pixel com os cantos cortados, brilho em cima à esquerda e sombra embaixo à direita (lê como um selo)
	_c.draw_rect(Rect2(x + PX, y, l - PX * 2.0, l), aro)
	_c.draw_rect(Rect2(x, y + PX, l, l - PX * 2.0), aro)
	_c.draw_rect(Rect2(x + PX, y, PX * 4.0, PX), aro.lightened(0.55))
	_c.draw_rect(Rect2(x, y + PX, PX, PX * 3.0), aro.lightened(0.55))
	_c.draw_rect(Rect2(x + l - PX * 5.0, y + l - PX, PX * 4.0, PX), aro.darkened(0.45))
	_c.draw_rect(Rect2(x + l - PX, y + l - PX * 4.0, PX, PX * 3.0), aro.darkened(0.45))
	# miolo escuro opaco (o ícone não soma alfa com a caixa) e o ícone (8 + contorno = 10 pixels) cobrindo o miolo
	_c.draw_rect(Rect2(x + PX, y + PX, l - PX * 2.0, l - PX * 2.0), SELO_MIOLO)
	IconesPoder.desenhar(_c, poder, Vector2(x + l * 0.5, y + l * 0.5), 3, 1.0, PX)

func _estrela4(p: Vector2, r: float, cor: Color, cont: Color = Color(0, 0, 0, 0)) -> void:
	var n: int = maxi(1, int(r / PX + 0.5))
	var cx: float = _sn(p.x)
	var cy: float = _sn(p.y)
	var los: bool = n == 2
	if cont.a > 0.0 and cor.a >= 0.99:
		_astro_px(cx, cy, n + 1, cont, los)
	_astro_px(cx, cy, n, cor, los)
	if n >= 2:
		_c.draw_rect(Rect2(cx, cy, PX, PX), Color(1.0, 1.0, 0.92, cor.a))

# ------------------------------------------------------------------ desenho
func _draw() -> void:
	_topo_fila.clear()   # pedidos de pintura por cima dos botões feitos durante este desenho (a camada de topo os executa)
	if modo == Modo.COMBATE or modo == Modo.TITULO:
		return
	if modo == Modo.MAPA:
		_mapa()
		return
	_fundo()
	if modo == Modo.FIM:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.72))
		_painel(fim_rect, Color(0.14, 0.09, 0.12, 0.98), 0.75)
		_fim_icones()
		_fim_gatos()
		return
	var n: int = estado.tijolos
	var tremor: Vector2 = Vector2.ZERO
	if negado > 0.0:
		tremor = Vector2(sin(t * 80.0) * 4.0, 0)
	draw_set_transform(tremor, 0.0, Vector2.ONE)
	TorrePx.desenhar(self, Vector2(24, 420), n, estado.tijolos_max(), estado.melhorias, estado.modulos, t, 0.0, {"luta": false})
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var cor_n: Color = Color(1, 0.35, 0.3) if negado > 0.0 else Color(1, 0.88, 0.72)
	_icone_gui(Rect2(288, 288, 32, 32), Vector2(40, 468), 0.5)
	Desenho.texto(self, "%d/%d" % [n, estado.tijolos_max()], Vector2(56, 476), 22, cor_n, -1.0, 4)
	_modulos_montados()
	var fi: int = estado.lugar()
	if estado.invasao:
		# a coluna da esquerda é estreita (o palco dos gatos começa em x = 200): o título vai em três linhas curtas
		var t_inv: String = Idioma.t("Invasão · %s") % Idioma.t(Fases.nome_do_lugar(fi))
		Desenho.texto(self, t_inv, Vector2(24, 36), _tam_cabe(t_inv, [24, 22, 20, 18], 170.0), Color(1, 1, 1), -1.0, 5)
		Desenho.texto(self, Idioma.t("Onda %d") % estado.onda_invasao, Vector2(24, 62), 24, Color(1, 0.95, 0.75), -1.0, 5)
		var r_inv: int = estado.recordes[estado.indice_recorde()]
		Desenho.texto(self, Idioma.t("Recorde: onda %d") % r_inv if r_inv > 0 else Idioma.t("Sem recorde ainda"), Vector2(26, 78), 14, Desenho.DOURADO, -1.0, 3)
	else:
		Desenho.texto(self, Idioma.t(Fases.nome_do_lugar(fi)), Vector2(24, 50), 34, Color(1, 1, 1), -1.0, 6)
		Desenho.texto(self, Idioma.t("Onda %d de %d") % [mini(estado.onda, Balanco.ONDAS_TOTAIS), Balanco.ONDAS_TOTAIS], Vector2(26, 76), 16, Color(1, 0.9, 0.7), -1.0, 4)
	_bonecos()
	_painel_guarda()
	_previa()
	_bigorna()
	_aviso_lutar()
	_efeitos()
	_aviso_time()

## Pintura da camada de topo: roda o que o `_draw` deixou na fila, com `_c` apontando para a camada.
func _desenhar_topo(cv: CanvasItem) -> void:
	if modo != Modo.GUARDA and modo != Modo.MAPA:
		return
	_c = cv
	if modo == Modo.GUARDA:
		# por cima dos botões (ver CamadaTopo): arrasto, dicas, recados e janelas, sempre com o estado de agora
		for f in [_arrasto, _dica, _dica_modulo, _aviso_cursor_tela, _confirma_fusao, _tela_resumo, _tela_ajuda]:
			(f as Callable).call()
	for f2 in _topo_fila:   # o que o `_draw` pediu (dicas do mapa, lista de avisos): dados fixos, repetir é inofensivo
		(f2 as Callable).call()
	_c = self

## Retângulo do k-ésimo encaixe de módulo, ao lado da torre desenhada.
func rect_mod_slot(k: int) -> Rect2:
	return Rect2(MOD_SLOT_X0 + k * MOD_SLOT_PASSO, MOD_SLOT_Y, MOD_SLOT, MOD_SLOT)

## Ícones pequenos dos módulos montados (encaixes vazios aparecem apagados).
func _modulos_montados() -> void:
	for k in estado.vagas_modulos():
		var r: Rect2 = rect_mod_slot(k)
		draw_rect(r, Color(0.08, 0.05, 0.07, 0.85))
		var cheio: bool = k < estado.modulos.size()
		draw_rect(r, Color(1.0, 0.85, 0.4, 0.7) if cheio else Color(1, 1, 1, 0.18), false, 2.0)
		if cheio:
			Oficina.icone_modulo(self, estado.modulos[k], r.position + Vector2(1, 1), 2.0)
	var rot: String = Idioma.t("%d/%d módulos") % [estado.modulos.size(), estado.vagas_modulos()]
	Desenho.texto(self, rot, Vector2(MOD_SLOT_X0 + estado.vagas_modulos() * MOD_SLOT_PASSO + 4.0, MOD_SLOT_Y + 18.0), 13, Color(1, 1, 1, 0.65), -1.0, 3)

## Dica do mouse sobre um módulo montado.
func _dica_modulo() -> void:
	for k in estado.modulos.size():
		if rect_mod_slot(k).has_point(mouse):
			var m: int = estado.modulos[k]
			var itens: Array = [["t", Idioma.t(Torre.MODULO_NOME[m]), 22, Desenho.DOURADO], ["t", Idioma.t(Torre.MODULO_DICA[m]), 13, Color(1, 1, 1, 0.9)]]
			_caixa_dica(itens, 300.0, Desenho.DOURADO, Desenho.DOURADO, mouse, Vector2(16, -20))
			return

## Recado depois da onda (subiu de nível, nocaute), na coluna à esquerda do guarda-roupa.
func _aviso_time() -> void:
	if aviso_t <= 0.0 or aviso == "":
		return
	var al: float = clampf(aviso_t, 0.0, 1.0)
	var linhas: Array[String] = _quebrar(aviso, 13, 124.0)
	var alt: float = 30.0 + linhas.size() * 16.0
	var r := Rect2(12, 100, 164, alt)
	_painel(r, Color(0.12, 0.07, 0.05, 0.94 * al), 0.5, Color(1, 1, 1, al))
	var y: float = r.position.y + 28.0
	for l in linhas:
		Desenho.texto(self, l, Vector2(r.position.x + 18, y), 13, _com_alfa(Color(1, 0.95, 0.75), al))
		y += 16.0

## Atualiza tudo que é só retorno visual do guarda-roupa (voos, textos, clarões, pulos), os avisos, o resumo e o hover.
func _atualizar_guarda(delta: float) -> void:
	aviso_cursor_t = maxf(0.0, aviso_cursor_t - delta)
	for i in range(voos.size() - 1, -1, -1):
		voos[i]["t"] = float(voos[i]["t"]) + delta / VOO_DUR
		if float(voos[i]["t"]) >= 1.0:
			voos.remove_at(i)
	for i in range(flutuantes.size() - 1, -1, -1):
		flutuantes[i]["t"] = float(flutuantes[i]["t"]) + delta
		if float(flutuantes[i]["t"]) >= float(flutuantes[i]["dur"]):
			flutuantes.remove_at(i)
	for i in range(claroes.size() - 1, -1, -1):
		claroes[i]["t"] = float(claroes[i]["t"]) + delta
		if float(claroes[i]["t"]) >= 1.0:
			claroes.remove_at(i)
	for k in pulos.keys():
		pulos[k] = float(pulos[k]) + delta
		if float(pulos[k]) > 0.5:
			pulos.erase(k)
	var cobre: bool = modo == Modo.GUARDA and (not resumo.is_empty() or ajuda_aberta)
	bloq_tela.visible = cobre
	bloq_tela.mouse_filter = Control.MOUSE_FILTER_STOP if cobre else Control.MOUSE_FILTER_IGNORE
	var tom: Color = Color(0.55, 0.55, 0.6) if cobre else Color.WHITE
	for b in [btn_lutar, btn_mapa, btn_pausa, btn_fich, btn_torre, btn_melhor, btn_time, btn_desf, btn_ajuda]:
		b.modulate = tom
	if modo != Modo.GUARDA:
		return
	guarda_t += delta
	btn_desf.disabled = desfazer.is_empty()
	btn_melhor.disabled = estado.bonecos.is_empty()
	var rot_melhor: String = Idioma.t("Vestir melhor")
	if sel >= 0 and sel < estado.bonecos.size():
		rot_melhor = Idioma.t("Vestir %s") % estado.bonecos[sel].nome   # diz em quem age
	if btn_melhor.text != rot_melhor:
		btn_melhor.text = rot_melhor
	_avisos_t -= delta
	if _avisos_t <= 0.0:
		_avisos_t = 0.25
		avisos_cache = _calcular_avisos()
		if avisos_cache.is_empty():
			avisos_aberto = false
	if not resumo.is_empty() and not menus.ativo() and not menus.em_transicao():
		resumo["t"] = float(resumo["t"]) + delta
		var itens: Array = resumo["itens"]
		while int(resumo["tocados"]) < itens.size() and float(resumo["t"]) >= 0.25 + int(resumo["tocados"]) * RESUMO_PASSO:
			_som_resumo(itens[int(resumo["tocados"])], int(resumo["tocados"]))
			resumo["tocados"] = int(resumo["tocados"]) + 1
		if float(resumo["t"]) > 0.25 + itens.size() * RESUMO_PASSO + 3.0:
			_fechar_resumo()
	var id: String = "" if (cobre or not arrasto.is_empty() or menus.ativo() or menus.em_transicao()) else _id_hover()
	if id != hover_id:
		hover_id = id
		if id != "":
			Som.tocar("hover", 1.15 if id.begins_with("t") else 1.0, 0.05, -17.0 if id.begins_with("t") else -11.0)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if id != "" else Control.CURSOR_ARROW

## Identifica o que está sob o mouse (só para o som de hover e o cursor).
func _id_hover() -> String:
	if mouse.x < 0.0:
		return ""
	if avisos_aberto:
		for k in mini(6, avisos_cache.size()):
			if _rect_aviso_linha(k).has_point(mouse):
				return "av%d" % k
		return ""
	var ti: int = _tile_em(mouse)
	if ti >= 0:
		return "t%d" % ti
	var fc: int = _cartao_fant_em(mouse)
	if fc >= 0:
		return "q%d" % fc
	var ab: int = _aba_em(mouse)
	if ab != -2:
		return "a%d" % ab
	var ai: Vector2i = _atr_em(mouse)
	if ai.x >= 0:
		return "r%d_%d" % [ai.x, ai.y]
	var pi: int = _promover_em(mouse)
	if pi >= 0:
		return "p%d" % pi
	var li: int = _linha_em(mouse)
	if li >= 0:
		return "l%d" % li
	for fr in _rect_fant:
		if (fr[0] as Rect2).has_point(mouse):
			return "f%d_%d" % [fr[2], fr[1]]
	if filtro_cj >= 0 and FILTRO_R.has_point(mouse):
		return "flt"
	if not avisos_cache.is_empty() and CHIP_AV.has_point(mouse):
		return "chip"
	var ss: Vector2i = _slot_em(mouse)
	if ss.x >= 0 and estado.bonecos[ss.x].pecas[ss.y] != null:
		return "s%d_%d" % [ss.x, ss.y]
	var bi: int = _boneco_em(mouse)
	if bi < 0:
		bi = _coluna_em(mouse)
	if bi >= 0:
		return "g%d" % bi
	return ""

## Gato cujo clique selecionaria agora (sob o mouse); -1 se o mouse não está num ponto que seleciona.
func _gato_sob_mouse() -> int:
	if not arrasto.is_empty() or mouse.x < 0.0:
		return -1
	var id: String = _id_hover()
	if id.begins_with("g"):
		return int(id.substr(1))
	if id.begins_with("s"):
		return int(id.substr(1).split("_")[0])
	return -1

func _em_voo(p: Peca) -> bool:
	for v in voos:
		if v["peca"] == p and (v["dest"] as Vector2i).x < 0 and float(v["t"]) < 0.9:
			return true
	return false

## Peça de uma fantasia que avança ou completa a do gato selecionado: realce no ladrilho.
func _realce_fantasia(r: Rect2, p: Peca) -> void:
	if sel < 0 or sel >= estado.bonecos.size():
		return
	var b: Boneco = estado.bonecos[sel]
	if b.pecas[p.slot()] == p:
		return
	var ef: Vector2i = _efeito_conjunto(b, p)
	if ef.y <= ef.x or ef.y < Pecas.CONJUNTO_MIN:
		return
	var cc: Color = Pecas.CONJUNTO_COR[p.conjunto()]
	var pu: float = 0.5 + 0.5 * sin(t * 6.0)
	var completa: bool = ef.y >= Pecas.SLOTS
	if completa:
		draw_rect(r.grow(2.0), _com_alfa(Desenho.DOURADO, 0.6 + 0.4 * pu), false, 3.0)
		_estrela4(r.position + Vector2(5, 5), 5.0 + 2.0 * pu, Color(1, 0.95, 0.5))
	else:
		draw_rect(r.grow(1.0), cc.lightened(0.35), false, 2.0)
	var tg := Rect2(r.end.x - 27, r.end.y - 16, 25, 14)
	draw_rect(tg, Color(0.05, 0.03, 0.05, 0.92))
	Desenho.texto(self, "%d/%d" % [ef.y, Pecas.SLOTS], Vector2(tg.position.x, tg.end.y - 1), 13, Desenho.DOURADO if completa else cc.lightened(0.5), tg.size.x)

## Foco do gato no palco: SEL_FORTE (selecionado), SEL_PRE (mouse em cima) e SEL_ALVO (ninguém selecionado: quem receberia a ação).
const SEL_NENHUM := 0
const SEL_FORTE := 1
const SEL_PRE := 2
const SEL_ALVO := 3

## Foco que o gato `i` tem agora. `sob` é o gato sob o mouse (-1 se nenhum).
func _foco_gato(i: int, sob: int) -> int:
	if i == sel:
		return SEL_FORTE
	if i == sob:
		return SEL_PRE
	if sel < 0 and i == _alvo_vestir():
		return SEL_ALVO
	return SEL_NENHUM

## Luz e pedestal do gato em foco: feixe de luz na coluna dele e anel no tapete (mais fraco no pré-destaque e no alvo).
func _anel_sel(base: Vector2, foco: int = SEL_FORTE) -> void:
	var forca: float = 1.0 if foco == SEL_FORTE else (0.5 if foco == SEL_PRE else 0.4)
	var pu: float = 0.5 + 0.5 * sin(t * 3.0)
	var luz: Color = Color(1.0, 0.93, 0.62)
	var a_base: float = (0.46 + 0.08 * pu) * forca
	var a_topo: float = 0.12 * forca
	# feixe em degraus (4 faixas de luz) e, no escolhido, pedestal de luz em dois tons
	_feixe_px(base.x, base.y + 3.0, 74.0, 66.0, 60.0, luz, a_base, a_topo, 4)
	var pe: Vector2 = base + Vector2(0, 3)
	if foco == SEL_FORTE:
		_elipse2_px(pe, 72.0, 16.0, Color(1.0, 0.85, 0.3, 0.3 + 0.1 * pu), 54.0, 12.0, Color(1.0, 0.95, 0.6, 0.45 + 0.12 * pu))
		_aro_px(pe, 74.0, 16.0, Color(1.0, 0.97, 0.7))
		_aro_px(pe, 71.0, 13.0, Color(0.85, 0.6, 0.18, 0.95))
	else:
		_aro_px(pe, 74.0, 16.0, Color(1.0, 0.9, 0.5, 0.55 if foco == SEL_PRE else 0.5))

func _titulo_ou_filtro() -> void:
	if filtro_cj < 0:
		var titulo: String = Idioma.t("Guarda-roupa")
		var alvo_t: int = _alvo_vestir()
		if aba == ABA_FANTASIAS and alvo_t >= 0:
			titulo = Idioma.t("Fantasias de %s") % estado.bonecos[alvo_t].nome   # diz para quem o clique vai vestir
		Desenho.texto(self, titulo, PAINEL.position + Vector2(22, 34), _tam_cabe(titulo, [22, 19, 17, 15], 158.0), COR_TINTA, -1.0, 3)
		return
	var cor: Color = Pecas.CONJUNTO_COR[filtro_cj]
	var sob: bool = FILTRO_R.has_point(mouse)
	_botao_arte(FILTRO_R, cor.lightened(0.5 if sob else 0.38), sob and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	var nome: String = Idioma.t("Só %s") % Idioma.t(Pecas.CONJUNTO_NOME[filtro_cj])
	Desenho.texto(self, nome, FILTRO_R.position + Vector2(12, 18), _tam_cabe(nome, [15, 13], 112.0), COR_TINTA_ESC)
	var xc: Vector2 = Vector2(FILTRO_R.end.x - 18, FILTRO_R.position.y + 13)
	_grade_px(self, ICO_X, xc - Vector2(7.5, 7.5), PX, COR_TINTA_ESC)

## Clarões, peças voando e textos flutuantes (por cima de tudo, abaixo das dicas).
func _camada_voos() -> void:
	for c in claroes:
		var k: float = clampf(float(c["t"]), 0.0, 1.0)
		var base: Vector2 = pos_boneco(int(c["bi"]))
		var cor: Color = c["cor"]
		# poça de luz que se abre no chão, feixe em faixas acima dela e onda de quadradinhos que some pontilhando
		var ry_c: float = 9.0 + 20.0 * k
		_elipse_px(base + Vector2(0, 3), 40.0 + 90.0 * k, ry_c, _com_alfa(cor.lightened(0.3), 0.5 * (1.0 - k)))
		_feixe_px(base.x, base.y + 3.0 - ry_c, 46.0, base.y - 150.0, 30.0, cor.lightened(0.4), 0.45 * (1.0 - k), 0.0, 4)
		var rc: float = 30.0 + 110.0 * k
		VFX.aro(_c, base + Vector2(0, -50), rc, rc, Color(1, 0.95, 0.7), 1.0 - k, 2.0 if k < 0.35 else 1.0, PX)
	for v in voos:
		var k2: float = clampf(float(v["t"]), 0.0, 1.0)
		var e: float = 1.0 - pow(1.0 - k2, 3.0)
		var pos: Vector2 = (v["de"] as Vector2).lerp(v["para"], e) + Vector2(0, -46.0 * sin(PI * k2))
		var pc: Peca = v["peca"]
		Desenho.icone(self, pc.tipo, pos, 44.0 + 14.0 * sin(PI * k2), pc.nivel, 0.0, 0.0, pc.marcas, pc.raridade)
	for f in flutuantes:
		var k3: float = float(f["t"]) / float(f["dur"])
		var al: float = clampf((1.0 - k3) / 0.35, 0.0, 1.0)
		var pf: Vector2 = f["p"] + Vector2(0, -34.0 * ease(k3, 0.4))
		var cx: float = clampf(pf.x, 160.0, 1120.0)
		Desenho.texto(self, str(f["txt"]), Vector2(cx - 160.0, pf.y), int(f["tam"]), _com_alfa(f["cor"], al), 320.0, 4)

## Recado junto do cursor: o motivo de uma ação negada, ou o resultado de uma montagem.
func _aviso_cursor_tela() -> void:
	if aviso_cursor_t <= 0.0 or aviso_cursor == "" or mouse.x < 0.0:
		return
	var al: float = clampf(aviso_cursor_t / 0.5, 0.0, 1.0)
	var linhas: Array[String] = _quebrar(aviso_cursor, 14, 236.0)
	var alt: float = 16.0 + linhas.size() * 18.0
	var r := Rect2(mouse + Vector2(18, 22), Vector2(262, alt))
	r.position.x = minf(r.position.x, 1272.0 - r.size.x)
	r.position.y = clampf(r.position.y, 6.0, 714.0 - alt)
	r.position.x = maxf(r.position.x, 6.0)
	_c.draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.35 * al))
	_c.draw_rect(r, Color(0.1, 0.05, 0.06, 0.95 * al))
	_c.draw_rect(r, _com_alfa(aviso_cursor_cor, al), false, 2.0)
	var y: float = r.position.y + 21.0
	for l in linhas:
		Desenho.texto(_c, l, Vector2(r.position.x + 12, y), 14, _com_alfa(aviso_cursor_cor.lightened(0.45), al))
		y += 18.0

func _tela_resumo() -> void:
	if resumo.is_empty():
		return
	var itens: Array = resumo["itens"]
	var tt: float = float(resumo["t"])
	var pecas: Array = []
	var linhas: Array = []
	for k in itens.size():
		if itens[k]["tipo"] == "peca":
			pecas.append(k)
		else:
			linhas.append(k)
	var por_linha: int = 10
	var lin_p: int = int(ceil(pecas.size() / float(por_linha)))
	var alt: float = 120.0 + lin_p * 66.0 + (16.0 if lin_p > 0 and linhas.size() > 0 else 0.0) + linhas.size() * 32.0
	alt = clampf(alt, 230.0, 640.0)
	var r := Rect2(300, (720.0 - alt) * 0.5, 680, alt)
	_c.draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.6 * clampf(tt / 0.2, 0.0, 1.0)))
	_painel(r, Color(0.14, 0.09, 0.12, 0.98), 0.75)
	Desenho.texto(_c, Idioma.t("Volta da luta"), Vector2(r.position.x, r.position.y + 54), 30, Desenho.DOURADO, r.size.x, 5)
	var y0: float = r.position.y + 76.0
	for j in pecas.size():
		var k2: int = pecas[j]
		var age: float = tt - (0.25 + k2 * RESUMO_PASSO)
		if age < 0.0:
			continue
		var p: Peca = itens[k2]["p"]
		var wtot: float = mini(pecas.size(), por_linha) * 62.0
		var cx: float = r.position.x + (r.size.x - wtot) * 0.5 + (j % por_linha) * 62.0 + 31.0
		var cy: float = y0 + (j / por_linha) * 66.0 + 30.0
		var esc: float = 1.0 + 0.7 * maxf(0.0, 1.0 - age * 4.0)
		if p.raridade > 0:
			var cc: Color = Pecas.cor_rar(p.raridade)
			var pu: float = 0.5 + 0.5 * sin(t * 5.0 + j)
			_elipse_px(Vector2(cx, cy), 27.0, 27.0, _com_alfa(cc, 0.16 + 0.14 * pu))
			_aro_px(Vector2(cx, cy), 30.0, 30.0, _com_alfa(cc, 0.9))
			if age < 0.6:
				_estrela4(Vector2(cx, cy - 24.0 - age * 30.0), 8.0 * (1.0 - age / 0.6) + 2.0, Color(1, 0.95, 0.5))
			var rar_txt: String = Idioma.t(Pecas.RARIDADE_NOME[p.raridade])
			Desenho.texto(_c, rar_txt, Vector2(cx - 31, cy + 40), _tam_cabe(rar_txt, [13, 12, 11, 10], 62.0), cc.lightened(0.3), 62.0, 3)
		Desenho.icone(_c, p.tipo, Vector2(cx, cy), 44.0 * esc, p.nivel, 0.0, 0.0, p.marcas, p.raridade)
	var y: float = y0 + lin_p * 66.0 + (22.0 if lin_p > 0 else 8.0)
	for k3 in linhas:
		var it: Dictionary = itens[k3]
		var age2: float = tt - (0.25 + int(k3) * RESUMO_PASSO)
		if age2 >= 0.0:
			var al: float = clampf(age2 * 6.0, 0.0, 1.0)
			var dx: float = (1.0 - al) * -30.0
			var txt: String = ""
			var cor: Color = Color(1, 0.95, 0.8)
			match str(it["tipo"]):
				"nivel":
					var b: Boneco = it["b"]
					var pts: int = int(it["ate"]) - int(it["de"])
					txt = (Idioma.t("%s subiu para o nível %d  (+%d ponto de treino)") if pts == 1 else Idioma.t("%s subiu para o nível %d  (+%d pontos de treino)")) % [b.nome, int(it["ate"]), pts]
					cor = Color(0.6, 0.85, 1.0)
				"marca":
					var b2: Boneco = it["b"]
					txt = Idioma.t("%s caiu na luta: a roupa ganhou uma marca") % b2.nome
					cor = Color(1.0, 0.7, 0.6)
				"trofeu":
					txt = Idioma.t("+%d troféu") % int(it["n"]) if int(it["n"]) == 1 else Idioma.t("+%d troféus") % int(it["n"])
					cor = Desenho.DOURADO
			Desenho.texto(_c, txt, Vector2(r.position.x + 50 + dx, y + 18), 18, _com_alfa(cor, al), -1.0, 3)
		y += 32.0
	Desenho.texto(_c, Idioma.t("Clique para continuar"), Vector2(r.position.x, r.end.y - 22), 14, Color(1, 1, 1, 0.45 + 0.25 * sin(t * 3.0)), r.size.x)

func _tela_ajuda() -> void:
	if not ajuda_aberta:
		return
	var r := Rect2(190, 22, 790, 676)
	_c.draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.6))
	_painel(r, Color(0.14, 0.09, 0.12, 0.98), 0.75)
	Desenho.texto(_c, Idioma.t("Atalhos e regras"), Vector2(r.position.x, r.position.y + 56), 30, Desenho.DOURADO, r.size.x, 5)
	var x: float = r.position.x + 36.0
	var y: float = r.position.y + 92.0
	Desenho.texto(_c, Idioma.t("Atalhos"), Vector2(x, y), 20, Color(0.7, 1.0, 0.75), -1.0, 3)
	y += 10.0
	for l in AJUDA_ATALHOS:
		y = _paragrafo(Idioma.t(l), Vector2(x, y + 12.0), 14, Color(1, 0.96, 0.88), 718.0, 18.0)
	y += 14.0
	Desenho.texto(_c, Idioma.t("Regras"), Vector2(x, y), 20, Color(1.0, 0.85, 0.5), -1.0, 3)
	y += 10.0
	for l in AJUDA_REGRAS:
		y = _paragrafo(Idioma.t(l), Vector2(x, y + 12.0), 14, Color(1, 0.96, 0.88), 718.0, 18.0)
	Desenho.texto(_c, Idioma.t("Clique, Esc ou ? para fechar"), Vector2(r.position.x, r.end.y - 22), 14, Color(1, 1, 1, 0.5), r.size.x)

## Chip discreto junto do LUTAR: quantos avisos há; abre a lista, que leva ao item com um clique. Nunca bloqueia o LUTAR.
func _aviso_lutar() -> void:
	if avisos_cache.is_empty():
		return
	var n: int = avisos_cache.size()
	var sob: bool = CHIP_AV.has_point(mouse)
	var cor: Color = Color(1.0, 0.84, 0.45)
	_botao_arte(CHIP_AV, cor.lightened(0.2) if (sob or avisos_aberto) else cor, avisos_aberto)
	var c: Vector2 = CHIP_AV.position + Vector2(22, 18)
	UIComum.emblema(self, "aviso", c + Vector2(-10, -8), 2.0, Color(0.95, 0.35, 0.2))
	Desenho.texto(self, Idioma.t("%d aviso") % n if n == 1 else Idioma.t("%d avisos") % n, CHIP_AV.position + Vector2(42, 24), 16, COR_TINTA_ESC)
	if not avisos_aberto:
		return
	_topo_fila.append(_aviso_lista)

## Lista de avisos aberta (por cima do LUTAR e dos outros botões).
func _aviso_lista() -> void:
	var n: int = avisos_cache.size()
	var lr: Rect2 = _rect_aviso_lista()
	_painel(lr, Color(0.14, 0.09, 0.1, 0.98), 0.5)
	for k in mini(6, n):
		var rl: Rect2 = _rect_aviso_linha(k)
		var sob_l: bool = rl.has_point(mouse)
		_c.draw_rect(rl, Color(1, 0.9, 0.5, 0.22) if sob_l else Color(1, 1, 1, 0.06))
		var linhas: Array[String] = _quebrar(str(avisos_cache[k]["txt"]), 13, rl.size.x - 14.0)
		var yl: float = rl.position.y + (20.0 if linhas.size() == 1 else 14.0)
		for i in mini(2, linhas.size()):
			Desenho.texto(_c, linhas[i], Vector2(rl.position.x + 8, yl + i * 15.0), 13, COR_TINTA)

# ------------------------------------------------------------------ fundo do guarda-roupa (pixel art pintada uma vez)
## Parede, assoalho e closet não se mexem: são pintados uma vez numa imagem de 427 x 240 pixels, em que cada pixel
## vira um quadradinho de PX (3 px) na tela, e desenhados com uma chamada só. Os degradês viram 4 a 6 faixas com
## pontilhado ordenado só na emenda; tábuas, veios, nós, luz do teto, cabides, tapete e rodapés são pixels da grade.
const FUNDO_W := 427
const FUNDO_H := 240
const BAYER4: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const CL_X0 := 69     # closet, em pixels da imagem (208 a 980 px na tela)
const CL_X1 := 327
const CL_Y1 := 149    # base do closet (446 px)
## Cabide com a roupa pendurada (11 x 20): w arame, k contorno, c pano, l pano claro, d pano escuro.
const CABIDE: Array[String] = [
	"......w....",
	".....w.w...",
	".....w.....",
	".....w.....",
	".....w.....",
	".....w.....",
	"....w.w....",
	"...w...w...",
	"..w.....w..",
	".kkkkkkkkk.",
	".klcccccdk.",
	".klccdccdk.",
	".klccdccdk.",
	".klccdccdk.",
	"kllccdcccdk",
	"klcccdcccdk",
	"klcccdcccdk",
	"klcccdcccdk",
	"klcccdcccdk",
	"kkkkkkkkkkk",
]
var _fundo_tex: ImageTexture = null
var _fundo_img: Image = null
var _fundo_tarefa: int = -1

func _fundo() -> void:
	if _fundo_tex == null:
		if _fundo_tarefa >= 0:
			WorkerThreadPool.wait_for_task_completion(_fundo_tarefa)
			_fundo_tarefa = -1
		if _fundo_img == null:
			_fundo_img = _gerar_fundo()
		_fundo_tex = ImageTexture.create_from_image(_fundo_img)
		_fundo_img = null
	draw_texture_rect(_fundo_tex, Rect2(0, 0, FUNDO_W * PX, FUNDO_H * PX), false)
	# moldura (as laterais descem por trás do painel do guarda-roupa)
	nove(self, GUI_TEX, R_MADEIRA, M_MADEIRA, Rect2(184, -100, 812, 845), 0.75, Color.WHITE, false)

## Começa a pintar o fundo numa linha de trabalho (no _ready); o primeiro desenho só espera se ela ainda não acabou.
func _preparar_fundo() -> void:
	if _fundo_tex == null and _fundo_tarefa < 0:
		_fundo_tarefa = WorkerThreadPool.add_task(_pintar_fundo_tarefa)

func _pintar_fundo_tarefa() -> void:
	_fundo_img = _gerar_fundo()

static func _ruido_s(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)

## Degrau de `v` (0..1) em `n` tons; só a emenda de cada faixa (os últimos 35%) pontilha, pela matriz de Bayer 4x4.
static func _degrau(v: float, n: int, x: int, y: int) -> float:
	var l: float = clampf(v, 0.0, 1.0) * (n - 1)
	var b: int = int(l)
	var fr: float = l - b
	if b < n - 1 and (fr - 0.65) / 0.35 > (BAYER4[(y & 3) * 4 + (x & 3)] + 0.5) / 16.0:
		b += 1
	return float(b) / (n - 1)

## Mistura um pixel da imagem com `cor` (k = quanto da cor nova).
static func _tingir(im: Image, x: int, y: int, cor: Color, k: float) -> void:
	if x < 0 or y < 0 or x >= FUNDO_W or y >= FUNDO_H:
		return
	im.set_pixel(x, y, im.get_pixel(x, y).lerp(cor, k))

static func _escurecer(im: Image, x: int, y: int, k: float) -> void:
	if x < 0 or y < 0 or x >= FUNDO_W or y >= FUNDO_H:
		return
	im.set_pixel(x, y, im.get_pixel(x, y).darkened(k))

static func _gerar_fundo() -> Image:
	var im := Image.create(FUNDO_W, FUNDO_H, false, Image.FORMAT_RGB8)
	# --- parede: roxo em cima, rosado embaixo, em 4 faixas; listras do papel e losangos claros (o closet cobre o meio)
	var c1 := Color(0.3, 0.2, 0.3)
	var c2 := Color(0.4, 0.27, 0.32)
	for y in 137:
		for x in FUNDO_W:
			if x >= CL_X0 and x < CL_X1:
				continue
			var cor: Color = c1.lerp(c2, _degrau(y / 136.0, 4, x, y))
			if x % 21 < 11:
				cor = cor.lerp(Color.WHITE, 0.035)
			im.set_pixel(x, y, cor)
	var losango := Color(0.95, 0.75, 0.5)
	for row in 4:
		for col in 11:
			var qx: int = int((32.0 + col * 120.0 + (row % 2) * 60.0) / PX)
			var qy: int = int((70.0 + row * 90.0) / PX)
			if qx >= CL_X0 - 1 and qx <= CL_X1:
				continue
			_tingir(im, qx, qy - 1, losango, 0.13)
			_tingir(im, qx - 1, qy, losango, 0.13)
			_tingir(im, qx, qy, losango, 0.22)
			_tingir(im, qx + 1, qy, losango, 0.13)
			_tingir(im, qx, qy + 1, losango, 0.13)
	# rodapé da parede: friso claro, faixa, sombra
	im.fill_rect(Rect2i(0, 137, FUNDO_W, 1), Color(0.78, 0.66, 0.55))
	im.fill_rect(Rect2i(0, 138, FUNDO_W, 7), Color(0.62, 0.5, 0.42))
	im.fill_rect(Rect2i(0, 145, FUNDO_W, 1), Color(0.47, 0.36, 0.3))
	im.fill_rect(Rect2i(0, 146, FUNDO_W, 1), Color(0.24, 0.15, 0.12))
	# --- assoalho: fileiras de tábuas, cada fileira num tom (5 tons, do claro junto da parede ao escuro embaixo)
	var w1 := Color(0.46, 0.3, 0.19)
	var w2 := Color(0.3, 0.19, 0.14)
	var ys: Array[float] = [440.0, 462.0, 490.0, 524.0, 566.0, 616.0, 676.0, 740.0]
	for r in range(1, ys.size()):
		var ya: int = roundi(ys[r - 1] / PX)
		var yb: int = mini(FUNDO_H, roundi(ys[r] / PX))
		if ya >= FUNDO_H:
			break
		var tom: Color = w1.lerp(w2, roundf(clampf(((ya + yb) * 0.5 - 147.0) / 93.0, 0.0, 1.0) * 4.0) / 4.0)
		var passo: float = 140.0 + (ys[r] - ys[r - 1]) * 3.0
		var xj: float = float((r * 83) % int(passo))
		var x_ant: int = 0
		var tab: int = 0
		while x_ant < FUNDO_W:
			var xf: int = mini(FUNDO_W, int(xj / PX))
			var f: float = 0.95 + 0.09 * _ruido_s(r * 31.0 + tab * 7.3)
			var tt := Color(tom.r * f, tom.g * f, tom.b * f)
			if xf > x_ant:
				im.fill_rect(Rect2i(x_ant, ya, xf - x_ant, yb - ya), tt)
			if xf >= FUNDO_W:
				break
			im.fill_rect(Rect2i(xf, ya, 1, yb - ya), tt.darkened(0.2))   # junta entre tábuas
			x_ant = xf + 1
			xj += passo
			tab += 1
		im.fill_rect(Rect2i(0, ya, FUNDO_W, 1), tom.darkened(0.3))      # vão escuro entre fileiras
		if ya + 1 < FUNDO_H:
			for x in FUNDO_W:
				_tingir(im, x, ya + 1, Color.WHITE, 0.06)               # quina clara da fileira
	# --- closet: tábuas em pé, sombra nas bordas e a luz quente do teto (cones e halo), tudo em degraus
	var luz := Color(1.0, 0.82, 0.45)
	var sombra := Color(0.06, 0.03, 0.02)
	var n: int = 15
	for k in n:
		var bx0: int = CL_X0 + roundi(k * (CL_X1 - CL_X0) / float(n))
		var bx1: int = CL_X0 + roundi((k + 1) * (CL_X1 - CL_X0) / float(n))
		var tm: float = 0.88 + 0.24 * _ruido_s(k + 1.0)
		var base := Color(0.40 * tm, 0.25 * tm, 0.145 * tm)
		for y in CL_Y1:
			var ysc: float = (y + 0.5) * PX
			var fy: float = ysc / 420.0
			var xa: float = lerpf(540.0, 250.0, fy)
			var xb: float = lerpf(640.0, 930.0, fy)
			var xa2: float = lerpf(570.0, 400.0, fy)
			var xb2: float = lerpf(610.0, 780.0, fy)
			for x in range(bx0, bx1):
				var xsc: float = (x + 0.5) * PX
				var l: float = 0.0
				if fy <= 1.0:
					if xsc >= xa and xsc <= xb:
						l += 0.2 * (1.0 - fy)
					if xsc >= xa2 and xsc <= xb2:
						l += 0.18 * (1.0 - fy)
				if ysc < 54.0:
					for e in 5:
						var dx: float = (xsc - 590.0) / (40.0 + e * 34.0)
						var dy: float = ysc / (14.0 + e * 10.0)
						if dx * dx + dy * dy <= 1.0:
							l += 0.07
				var d: int = mini(x - CL_X0, CL_X1 - 1 - x)
				var sq: float = 0.0
				if d < 30:
					sq = _degrau(1.0 - d / 30.0, 4, x, y) * 0.5
				im.set_pixel(x, y, base.lerp(sombra, sq).lerp(luz, _degrau(l / 0.6, 6, x, y) * 0.6))
		# veios: riscos de um pixel com um degrau no meio
		for g in 10:
			var gx: int = bx0 + 2 + int(_ruido_s(k * 5.0 + g * 1.7) * maxf(1.0, bx1 - bx0 - 4))
			var gy: int = int(_ruido_s(k * 13.0 + g * 3.1) * CL_Y1)
			var gl: int = 5 + int(_ruido_s(k * 7.0 + g) * 15.0)
			var ddx: int = 1 if _ruido_s(k + g * 2.2) > 0.5 else -1
			for j in gl:
				var xx: int = gx + (ddx if (j > gl / 3 and j < gl * 2 / 3) else 0)
				var yy: int = gy + j
				if yy < CL_Y1 and xx > bx0 + 1 and xx < bx1:
					_escurecer(im, xx, yy, 0.14)
		# nó da madeira: oval escuro com miolo mais escuro
		if _ruido_s(k * 3.3) > 0.5:
			var ny: int = int((90.0 + _ruido_s(k * 9.1) * 240.0) / PX)
			var nx: int = bx0 + int((bx1 - bx0) * (0.3 + 0.4 * _ruido_s(k * 2.7)))
			for kx in range(-1, 2):
				_escurecer(im, nx + kx, ny, 0.35)
				_escurecer(im, nx + kx, ny + 1, 0.3)
			_escurecer(im, nx, ny, 0.45)
			_escurecer(im, nx - 2, ny + 1, 0.15)
			_escurecer(im, nx + 2, ny, 0.15)
			_escurecer(im, nx, ny - 1, 0.12)
			_escurecer(im, nx, ny + 2, 0.12)
		# emenda das tábuas: vão escuro e quina clara
		for y in CL_Y1:
			_escurecer(im, bx0, y, 0.38)
			_tingir(im, bx0 + 1, y, Color(1.0, 0.8, 0.5), 0.08)
	# varão do cabideiro
	im.fill_rect(Rect2i(CL_X0, 2, CL_X1 - CL_X0, 1), Color(0.95, 0.82, 0.55))
	im.fill_rect(Rect2i(CL_X0, 3, CL_X1 - CL_X0, 1), Color(0.72, 0.56, 0.33))
	im.fill_rect(Rect2i(CL_X0, 4, CL_X1 - CL_X0, 1), Color(0.4, 0.28, 0.14))
	for x in range(CL_X0, CL_X1):
		_escurecer(im, x, 5, 0.25)
	# cabides com roupa (entre as plaquinhas dos nomes)
	var cores_pano: Array[Color] = [Color(0.5, 0.6, 0.78), Color(0.78, 0.4, 0.38), Color(0.5, 0.72, 0.5), Color(0.86, 0.72, 0.4), Color(0.7, 0.55, 0.78)]
	for k in range(1, 5):
		var hx: int = int((289.0 - 76.5 + k * 153.0) / PX)
		var pano: Color = cores_pano[(k * 2) % cores_pano.size()].darkened(0.08)
		for yy in CABIDE.size():
			var lin: String = CABIDE[yy]
			for xx in lin.length():
				var ch: int = lin.unicode_at(xx)
				var px_x: int = hx - 5 + xx
				var px_y: int = 1 + yy
				match ch:
					119: im.set_pixel(px_x, px_y, Color(0.85, 0.85, 0.9))   # w
					107: im.set_pixel(px_x, px_y, Color(0.14, 0.08, 0.06))  # k
					99: im.set_pixel(px_x, px_y, pano)                      # c
					108: im.set_pixel(px_x, px_y, pano.lightened(0.25))     # l
					100: im.set_pixel(px_x, px_y, pano.darkened(0.25))      # d
	# tapete onde os gatos pisam: borda, friso dourado e losangos
	var tx0: int = 75
	var tx1: int = 319
	var ty0: int = 131
	var ty1: int = 143
	for y in range(ty0 + 1, ty1):
		_escurecer(im, tx1, y, 0.3)
		_escurecer(im, tx1 + 1, y, 0.3)
	var miolo := Color(0.45, 0.15, 0.2)
	im.fill_rect(Rect2i(tx0, ty0, tx1 - tx0, ty1 - ty0), Color(0.55, 0.2, 0.22))
	im.fill_rect(Rect2i(tx0 + 1, ty0 + 1, tx1 - tx0 - 2, ty1 - ty0 - 2), miolo)
	var friso: Color = miolo.lerp(Color(0.95, 0.82, 0.55), 0.9)
	im.fill_rect(Rect2i(tx0 + 2, ty0 + 2, tx1 - tx0 - 4, 1), friso)
	im.fill_rect(Rect2i(tx0 + 2, ty1 - 3, tx1 - tx0 - 4, 1), friso)
	im.fill_rect(Rect2i(tx0 + 2, ty0 + 2, 1, ty1 - ty0 - 4), friso)
	im.fill_rect(Rect2i(tx1 - 3, ty0 + 2, 1, ty1 - ty0 - 4), friso)
	var los: Color = miolo.lerp(Color(0.95, 0.75, 0.45), 0.5)
	var lx: int = tx0 + 5
	while lx + 4 < tx1 - 3:
		im.fill_rect(Rect2i(lx + 1, 135, 2, 1), los)
		im.fill_rect(Rect2i(lx, 136, 4, 2), los)
		im.fill_rect(Rect2i(lx + 1, 138, 2, 1), los)
		lx += 7
	# rodapé do closet: madeira clara com friso e sombra
	im.fill_rect(Rect2i(CL_X0, 143, CL_X1 - CL_X0, 1), Color(0.82, 0.62, 0.4))
	im.fill_rect(Rect2i(CL_X0, 144, CL_X1 - CL_X0, 4), Color(0.6, 0.42, 0.26))
	im.fill_rect(Rect2i(CL_X0, 148, CL_X1 - CL_X0, 1), Color(0.3, 0.19, 0.1))
	return im

## Quantas peças da fantasia da peça `p` o boneco tem antes e depois de vesti-la.
func _efeito_conjunto(b: Boneco, p: Peca) -> Vector2i:
	var c: int = p.conjunto()
	var antes: int = 0
	var depois: int = 0
	for s in Pecas.SLOTS:
		var q: Peca = b.pecas[s]
		var mesma: bool = q != null and q.conjunto() == c
		if mesma:
			antes += 1
		if s == p.slot():
			depois += 1
		elif mesma:
			depois += 1
	return Vector2i(antes, depois)

func _bonecos() -> void:
	_rect_fant.clear()
	var destaque_peca: Peca = null
	if arrasto.has("peca"):
		destaque_peca = arrasto["peca"]
	var sob_gato: int = _gato_sob_mouse()
	for i in Balanco.MAX_BONECOS:
		var base: Vector2 = pos_boneco(i)
		var existe: bool = i < estado.bonecos.size()
		var foco: int = _foco_gato(i, sob_gato) if existe else SEL_NENHUM
		# luz e anel no tapete (sob o gato), depois a sombra dele
		if foco != SEL_NENHUM:
			_anel_sel(base, foco)
		_ellipse_sombra(base + Vector2(0, 3), 52.0, 11.0, Color(0, 0, 0, 0.4 if existe else 0.16))
		if not existe:
			var vazio: Array = [null, null, null, null]
			Desenho.boneco(self, base.snapped(Vector2(PX, PX)), ESC_G, 1.0, 0, vazio, 0.0, 0.0, false, 0.0, 0.12)
			var yv: float = 300.0
			for l in _quebrar(Idioma.t("Vença o próximo cômodo"), 13, 120.0):
				Desenho.texto(self, l, Vector2(base.x - 60, yv), 13, Color(1, 1, 1, 0.6), 120.0, 3)
				yv += 16.0
			continue
		var b: Boneco = estado.bonecos[i]
		var tem: bool = b.pontos > 0
		if tem:
			_brilho_treino(base)
		var nasc_e: float = 0.4 + 0.6 * ease(b.nasc, 0.4)
		var esc: float = ESC_G * (1.0 + 0.1 * sin(b.pop * PI)) * nasc_e
		if foco == SEL_FORTE:
			esc *= 1.0 + 0.012 * sin(t * 3.0)   # respira de leve
		var bob: float = sin(t * 2.0 + i) * 2.0
		if foco == SEL_FORTE:
			bob -= sin(b.pop * PI) * 10.0       # pulinho ao ser selecionado
		# quando há um escolhido, os outros ficam um pouco mais apagados (o mouse em cima acende de novo)
		var alfa_gato: float = 1.0
		if sel >= 0 and foco != SEL_FORTE:
			alfa_gato = 0.9 if foco == SEL_PRE else 0.7
		var sobre: bool = false
		var slot_dest: int = -1
		if destaque_peca != null:
			slot_dest = destaque_peca.slot()
			sobre = _boneco_em(mouse) == i
		var area := Rect2(base.x - 72, base.y - 112, 144, 127)
		if sobre:
			draw_rect(area, Color(0.5, 1.0, 0.6, 0.14))
			draw_rect(area, Color(0.5, 1.0, 0.6, 0.6), false, 2.0)
		# a peça arrastada avança ou completa uma fantasia neste boneco?
		if destaque_peca != null:
			var ef: Vector2i = _efeito_conjunto(b, destaque_peca)
			if ef.y > ef.x and ef.y >= Pecas.CONJUNTO_MIN:
				var cj: int = destaque_peca.conjunto()
				var cc: Color = Pecas.CONJUNTO_COR[cj]
				var pulso: float = 0.5 + 0.5 * sin(t * 7.0)
				draw_rect(area, _com_alfa(cc, 0.1 + 0.1 * pulso))
				draw_rect(area, cc.lightened(0.2), false, 3.0)
				var rotulo: String = "%s %d/%d%s" % [Idioma.t(Pecas.CONJUNTO_NOME[cj]), ef.y, Pecas.SLOTS, Idioma.t("  completa!") if ef.y >= Pecas.SLOTS else ""]
				Desenho.texto(self, rotulo, Vector2(area.position.x, area.position.y - 4.0), 13, cc.lightened(0.35), area.size.x, 3)
		var escondida: Peca = null
		if arrasto.has("peca") and arrasto["origem"] == b:
			escondida = arrasto["peca"]
		var mostradas: Array = b.pecas.duplicate()
		if escondida != null:
			mostradas[escondida.slot()] = null
		for v in voos:
			var dv: Vector2i = v["dest"]
			if dv.x == i and float(v["t"]) < 0.9:
				mostradas[dv.y] = null
		var pulo: float = 0.0
		for s2 in Pecas.SLOTS:
			var kp := Vector2i(i, s2)
			if pulos.has(kp) and float(pulos[kp]) < 0.4:
				pulo = maxf(pulo, sin(PI * float(pulos[kp]) / 0.4) * 14.0)
		var pose: Vector2 = (base + Vector2(0, bob - pulo)).snapped(Vector2(PX, PX))   # na grade de 3 px (pixel do gato = 6)
		Desenho.boneco(self, pose, esc, 1.0, 0, mostradas, 0.0, t * 3.0, false, 0.0, alfa_gato, true, slot_dest, 0.0, 0, false, false, 0, false, -1, false, false, i, false)
		if tem:
			_estrelas_treino(base, b.pontos)
		# barra de saúde: a ferida fica de uma onda para a outra
		var barra := Rect2(base.x - 44, base.y + 14, 88, 9)
		var cor_saude: Color = Color(0.4, 0.85, 0.4) if b.saude > 0.5 else (Color(0.95, 0.75, 0.25) if b.saude > 0.25 else Color(0.95, 0.3, 0.25))
		_barra(barra, b.saude, cor_saude, minf(1.0, b.saude + estado.cura_atual()))
		if arrasto.has("boneco") and arrasto["boneco"] == b:
			draw_rect(area, Color(1, 1, 1, 0.1))
		if nocauteados.has(b):
			draw_rect(barra.grow(2.0), Color(0.8, 0.15, 0.15, 0.4))
			Desenho.texto(self, Idioma.t("NOCAUTE"), barra.position + Vector2(0, 9), 13, Color(1, 0.9, 0.85), barra.size.x, 3)
		_cabecalho_boneco(b, base, i, foco)
		_treino_boneco(b, i, base)
		_botao_promover_tudo(b, i)
		if destaque_peca != null:
			for s2 in Pecas.SLOTS:
				var q: Peca = b.pecas[s2]
				if q != null and q != destaque_peca and estado.pode_fundir(q, destaque_peca):
					_destaque_fusao(pos_slot(i, s2), 24.0)
		# botão de linha: clique alterna frente / meio / fundo
		var rl: Rect2 = rect_linha(i)
		var cores_linha: Array[Color] = [Color(1.0, 0.58, 0.52), Color(1.0, 0.86, 0.5), Color(0.62, 0.78, 1.0)]
		var sob_linha: bool = rl.has_point(mouse)
		_botao_arte(rl, cores_linha[b.linha].lightened(0.15) if sob_linha else cores_linha[b.linha], sob_linha and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
		Desenho.texto(self, Idioma.t("Linha: %s") % Idioma.t(Boneco.LINHA_NOMES[b.linha]), rl.position + Vector2(0, 14), 13, COR_TINTA_ESC, rl.size.x)
		_fantasias_boneco(b, base)

## Luz dourada no chão do gato que tem ponto de treino.
func _brilho_treino(base: Vector2) -> void:
	var pu: float = 0.5 + 0.5 * sin(t * 5.0)
	_elipse2_px(base + Vector2(0, 2), 76.0, 17.0, Color(1.0, 0.8, 0.2, 0.16 + 0.14 * pu), 54.0, 12.0, Color(1.0, 0.92, 0.45, 0.32 + 0.24 * pu))
	_feixe_px(base.x, base.y + 2.0, 40.0, base.y - 130.0, 28.0, Color(1.0, 0.85, 0.35), 0.22 + 0.12 * pu, 0.0, 4)

## Faíscas girando em volta do gato e selo "+N" saltitando sobre a cabeça.
func _estrelas_treino(base: Vector2, pontos: int) -> void:
	var c: Vector2 = base + Vector2(0, -62)
	for k in 6:
		var a: float = t * 1.6 + k * TAU / 6.0
		var p: Vector2 = c + Vector2(cos(a) * 64.0, sin(a) * 52.0)
		_estrela4(p, 5.0 + 3.5 * sin(t * 6.0 + k * 1.7), Color(1.0, 0.95, 0.55))
	# selo de moeda em pixel: contorno escuro, aro claro, miolo dourado com sombra embaixo e brilho em cima
	var bp: Vector2 = Vector2(base.x + 54.0, _sn(base.y - 118.0 - absf(sin(t * 4.0)) * 9.0))
	VFX.disco(self, bp, 22.0, Color(0.1, 0.05, 0.02), PX)
	VFX.disco(self, bp, 19.0, Color(1.0, 0.97, 0.7), PX)
	VFX.disco(self, bp, 16.0, Color(0.86, 0.58, 0.1), PX)
	VFX.disco(self, bp + Vector2(-PX, -PX), 13.0, Color(1.0, 0.8, 0.2), PX)
	VFX.ponto(self, bp + Vector2(-PX * 3.0, -PX * 3.0), Color(1.0, 0.97, 0.7), PX)
	Desenho.texto(self, "+%d" % pontos, bp + Vector2(-18, 7), 18, COR_TINTA_ESC, 40.0)

## Nome grande, nível e barra de experiência no alto do vão do boneco.
func _cabecalho_boneco(b: Boneco, base: Vector2, i: int, foco: int = SEL_NENHUM) -> void:
	var maximo: bool = b.nivel >= Balanco.BONECO_NIVEL_MAX
	var escolhido: bool = foco == SEL_FORTE
	var pl := Rect2(base.x - 76, 14, 152, 48)
	if escolhido:
		# plaquinha clara: o nome do gato escolhido é o ponto mais claro da tela
		draw_rect(pl.grow(2.0), Color(0.25, 0.14, 0.04, 0.9))
		draw_rect(pl, Color(1.0, 0.92, 0.6))
		draw_rect(Rect2(pl.position.x, pl.position.y, pl.size.x, 3.0), Color(1.0, 0.98, 0.82))
		draw_rect(Rect2(pl.position.x, pl.end.y - 3.0, pl.size.x, 3.0), Color(0.82, 0.6, 0.2))
	elif foco == SEL_PRE:
		draw_rect(pl, Color(1.0, 0.88, 0.45, 0.14))
		draw_rect(pl, Color(1.0, 0.88, 0.4, 0.55), false, 2.0)
	elif foco == SEL_ALVO:
		draw_rect(pl, Color(1.0, 0.88, 0.45, 0.07))
		draw_rect(pl, Color(1.0, 0.88, 0.4, 0.3), false, 1.0)
	var tinta: Color = COR_TINTA_ESC if escolhido else COR_TINTA
	Desenho.texto(self, "[%d]" % (i + 1), Vector2(base.x - 74, base.y + 22), 13, Color(1, 1, 1, 0.55))
	if nome_idx == i:
		# editando: a caixa de texto cobre o nome; embaixo, a instrução (ou o motivo de recusa)
		draw_rect(pl.grow(2.0), Color(0.25, 0.14, 0.04, 0.9))
		draw_rect(pl, Color(1.0, 0.92, 0.6))
		var msg: String = nome_aviso if nome_aviso_t > 0.0 else Idioma.t("Enter ok · Esc sai")
		Desenho.texto(self, msg, Vector2(pl.position.x, pl.end.y - 3.0), 12, Color(0.6, 0.12, 0.08) if nome_aviso_t > 0.0 else COR_TINTA_ESC, pl.size.x)
		return
	Desenho.texto(self, b.nome, Vector2(base.x - 73, 36), 22, tinta, 146.0, 0 if escolhido else 5)
	if arrasto.is_empty() and nome_idx < 0 and _pode_renomear():
		# sempre à vista (apagado) para o jogador achar onde renomear; acende com o mouse na plaquinha ou no lápis
		var perto: bool = pl.has_point(mouse) or rect_lapis(i).has_point(mouse)
		_lapis(rect_lapis(i), rect_lapis(i).has_point(mouse), 1.0 if perto else 0.5)
	if maximo:
		Desenho.texto(self, Idioma.t("Nível máximo"), Vector2(base.x - 73, 56), 13, Color(0.5, 0.3, 0.0) if escolhido else Desenho.DOURADO, 146.0, 0 if escolhido else 3)
		return
	Desenho.texto(self, Idioma.t("Nv %d") % b.nivel, Vector2(base.x - 70, 57), 16, COR_TINTA_ESC if escolhido else Color(1, 0.9, 0.5), -1.0, 0 if escolhido else 4)
	_barra(Rect2(base.x - 24, 49, 92, 8), float(b.xp) / float(maxi(1, b.xp_para_subir())), Color(0.4, 0.7, 1.0))

## Abinha com um lápis desenhado (renomear o gato).
func _lapis(r: Rect2, forte: bool, alfa: float = 1.0) -> void:
	# abinha de quinas cortadas e um lápis de grade (ponta de grafite, madeira, corpo laranja, borracha rosa)
	UIComum.forma(self, r, Color(0.25, 0.14, 0.04, 0.95 * alfa), PX)
	UIComum.forma(self, r.grow(-PX), Color(1.0, 0.92, 0.6, alfa) if forte else Color(0.95, 0.8, 0.45, alfa), PX)
	var c: Vector2 = r.get_center()
	_grade_px(self, ICO_LAPIS, c - Vector2(10.5, 6.0), PX, Color(0.85, 0.45, 0.15), alfa)

## Treino: botões grandes com ganho escrito quando há ponto; fichinhas com os valores quando não há.
func _treino_boneco(b: Boneco, i: int, base: Vector2) -> void:
	var tem: bool = b.pontos > 0
	var pu: float = 0.5 + 0.5 * sin(t * 6.0)
	for a in Balanco.ATR_NOMES.size():
		var r: Rect2 = rect_atr(i, a)
		var sob: bool = r.has_point(mouse) and arrasto.is_empty()
		if tem:
			# o botão de treino toma o lugar da fichinha: ícone em cima, "+1" embaixo
			var apert: bool = sob and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			var cor: Color = Color(0.62, 0.95, 0.55)
			if sob:
				cor = cor.lightened(0.25)
			_botao_arte(r, cor, apert)
			if not apert:
				draw_rect(r.grow(2.0), Color(1.0, 0.95, 0.5, 0.25 + 0.4 * pu), false, 2.0)
			var dy: float = 2.0 if apert else 0.0
			_icone_gui(ICO_ATR[a], Vector2(r.get_center().x - 9.0, r.position.y + 14 + dy), 0.5)
			Desenho.texto(self, str(b.atr[a]), Vector2(r.get_center().x + 2.0, r.position.y + 19 + dy), 13, Color(0.5, 0.25, 0.0), 20.0)
			Desenho.texto(self, "+1", Vector2(r.position.x, r.position.y + 34 + dy), 16, Color(0.08, 0.36, 0.1), r.size.x)
		else:
			draw_rect(r, Color(0.08, 0.04, 0.04, 0.7 if sob else 0.42))
			draw_rect(r, Color(1, 0.9, 0.7, 0.55 if sob else 0.18), false, 1.0)
			_icone_gui(ICO_ATR[a], Vector2(r.position.x + 13, r.position.y + 12), 0.5, Color(1, 1, 1, 0.9))
			_texto_dir(str(b.atr[a]), r.end.x - 6.0, r.position.y + 18, 16, COR_TINTA)

## Botão pequeno "Promover tudo (N)" do gato, abaixo dos botões de treino.
func _botao_promover_tudo(b: Boneco, i: int) -> void:
	var r: Rect2 = rect_promover(i)
	var st: Dictionary = _estado_promover_tudo(b)
	var sob: bool = r.has_point(mouse) and arrasto.is_empty()
	var cor: Color = Color(1.0, 0.84, 0.4) if st["ok"] else Color(0.6, 0.58, 0.6)
	if sob and st["ok"]:
		cor = cor.lightened(0.2)
	_botao_arte(r, cor, sob and st["ok"] and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	# carretel pequeno + custo em blocos
	var ca: float = 1.0 if st["ok"] else 0.5
	var cy: float = r.get_center().y
	draw_rect(Rect2(r.position.x + 7.0, cy - 6.0, 10.0, 12.0), Color(0.85, 0.2, 0.25, ca))
	draw_rect(Rect2(r.position.x + 5.0, cy - 7.0, 14.0, 3.0), Color(0.45, 0.28, 0.12, ca))
	draw_rect(Rect2(r.position.x + 5.0, cy + 4.0, 14.0, 3.0), Color(0.45, 0.28, 0.12, ca))
	var txt: String = "+1 (%d)" % st["custo"] if st["custo"] > 0 else Idioma.t("máx.")
	Desenho.texto(self, txt, Vector2(r.position.x + 22.0, r.position.y + 15), 12, COR_TINTA_ESC if st["ok"] else Color(0.3, 0.28, 0.3), r.size.x - 24.0)
	# raridade da fantasia inteira, paga em troféus
	var rr: Rect2 = rect_reforcar(i)
	var sr: Dictionary = _estado_reforcar_tudo(b)
	var sob_r: bool = rr.has_point(mouse) and arrasto.is_empty()
	var cor_r: Color = Color(0.8, 0.7, 1.0) if sr["ok"] else Color(0.6, 0.58, 0.6)
	if sob_r and sr["ok"]:
		cor_r = cor_r.lightened(0.2)
	_botao_arte(rr, cor_r, sob_r and sr["ok"] and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	_estrela4(Vector2(rr.position.x + 12.0, rr.get_center().y), 6.5, Color(1.0, 0.8, 0.22) if sr["ok"] else Color(0.4, 0.38, 0.4))
	Desenho.texto(self, "(%d)" % sr["custo"] if sr["custo"] > 0 else Idioma.t("máx."), Vector2(rr.position.x + 22.0, rr.position.y + 15), 12, COR_TINTA_ESC if sr["ok"] else Color(0.3, 0.28, 0.3), rr.size.x - 24.0)

## Anel verde que pulsa em volta de uma peça que a arrastada pode fundir.
func _destaque_fusao(c: Vector2, raio: float) -> void:
	var pulso: float = 0.5 + 0.5 * sin(t * 7.0)
	_elipse_px(c, raio - PX, raio - PX, Color(0.5, 1.0, 0.6, 0.1 + 0.08 * pulso))
	_aro_px(c, raio, raio, Color(0.5, 1.0, 0.6, 0.55 + 0.4 * pulso))

## Fantasias ativas (2 ou mais peças): nome, quantas peças, o bônus e, completa, o poder.
## Clique na caixa "Herança pronta!": pede confirmação e só então o poder da fantasia vestida fica com o gato.
func _clique_heranca(p: Vector2) -> bool:
	for rh in _rect_heranca:
		if (rh[0] as Rect2).has_point(p):
			var b: Boneco = estado.bonecos[int(rh[1])]
			var fc: int = b.fantasia_completa()
			if fc < 0:
				_negar(Idioma.t("Vista as 4 peças da fantasia em %s.") % b.nome)
				return true
			if b.grau_de(fc) >= Balanco.HERANCA_GRAU_MAX:
				_negar(Idioma.t("%s já tem %s no grau máximo. Vista outra fantasia completa.") % [b.nome, Simulacao.heranca_nome_curto(fc, b.grau_de(fc))])
				return true
			var g_novo: int = b.grau_de(fc) + 1
			var corpo: String
			if g_novo > 1:
				corpo = Idioma.t("%s já tem %s: a herança sobe para o grau %s, com mais força (+%d%%) e solta a cada %d s. Isso é para sempre.") % [b.nome, Idioma.t(Pecas.PODER_NOME[fc]), Balanco.heranca_grau_romano(g_novo), int(round(Balanco.HERANCA_GRAU_FORCA * 100.0)), int(Balanco.heranca_intervalo(g_novo))]
			else:
				corpo = Idioma.t("%s passa a soltar %s sozinho na luta, a cada %d s, com qualquer roupa (%s). Isso é para sempre e não dá para trocar depois. Incorporar a mesma fantasia de novo sobe o grau.") % [b.nome, Idioma.t(Pecas.PODER_NOME[fc]), int(Balanco.HERANCA_INTERVALO), Idioma.t(Pecas.PODER_DICA[fc])]
			menus.confirmar(("%s?" % _txt_incorporar(b, fc)) if b.grau_de(fc) > 0 else (Idioma.t("Incorporar %s?") % Idioma.t(Pecas.PODER_NOME[fc])), corpo, Idioma.t("Incorporar"), Idioma.t("Ainda não"), Callable(self, "_incorporar").bind(int(rh[1])))
			return true
	return false

## "Relâmpago" (herança nova) ou "Relâmpago sobe para II" (a mesma de novo).
func _txt_incorporar(b: Boneco, fc: int) -> String:
	var g: int = b.grau_de(fc)
	if g <= 0:
		return Idioma.t(Pecas.PODER_NOME[fc])
	if g >= Balanco.HERANCA_GRAU_MAX:
		return Idioma.t("%s (grau máximo)") % Simulacao.heranca_nome_curto(fc, g)
	return Idioma.t("%s sobe para %s") % [Idioma.t(Pecas.PODER_NOME[fc]), Balanco.heranca_grau_romano(g + 1)]

func _incorporar(i: int) -> void:
	var b: Boneco = estado.bonecos[i]
	var hc: int = b.incorporar()
	if hc < 0:
		return
	b.pop = 1.0
	Som.tocar("fantasia")
	_faisca(pos_boneco(i) + Vector2(0, -60), Color(0.8, 0.65, 1.0), 26, 220.0)
	_recado(Idioma.t("%s incorporou %s!") % [b.nome, Simulacao.heranca_nome_curto(hc, b.grau_de(hc))])
	estado.conferir_metas()
	estado.salvar()

func _fantasias_boneco(b: Boneco, base: Vector2) -> void:
	if estado.bonecos.find(b) == 0:
		_rect_heranca.clear()
		_rect_her_feita.clear()
	var cont: Array[int] = Pecas.contar_conjuntos(b.pecas)
	var fonte: Font = UIComum.FONTE
	var y: float = 130.0 if b.pontos > 0 else 118.0
	for c in Pecas.Conjunto.size():
		var grau: int = Pecas.grau_conjunto(cont[c])
		if grau == 0:
			continue
		var cor: Color = Pecas.CONJUNTO_COR[c]
		var completa: bool = grau == 2
		# uma linha só: nome e N/4 (bônus e poder moram na dica do mouse da caixa)
		var nome_cj: String = Idioma.t(Pecas.CONJUNTO_NOME[c])
		# nome longo (Patrulheiro Espacial) quebra em duas linhas em vez de vazar
		var nome_l: Array[String] = [nome_cj]
		var tm: int = 16
		if fonte.get_string_size(nome_cj, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(16)).x > 100.0:
			tm = 13
			if fonte.get_string_size(nome_cj, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(13)).x > 100.0:
				nome_l = _quebrar(nome_cj, 13, 100.0)
		var alt: float = 12.0 + (nome_l.size() - 1) * 15.0 + 14.0
		var r := Rect2(base.x - 74, y, 148, alt)
		var pulso: float = 0.5 + 0.5 * sin(t * 4.0)
		draw_rect(r, Color(0.07, 0.03, 0.03, 0.6))
		_rect_fant.append([r, c, estado.bonecos.find(b)])
		if filtro_cj == c:
			draw_rect(r.grow(1.0), Color(1, 1, 1, 0.9), false, 2.0)
		elif r.has_point(mouse) and arrasto.is_empty():
			draw_rect(r, Color(1, 1, 1, 0.16))
		if completa:
			draw_rect(r, _com_alfa(cor, 0.14 + 0.1 * pulso))
			draw_rect(r, Desenho.DOURADO, false, 2.0)
		draw_rect(Rect2(r.position.x, r.position.y, 5, alt), cor)
		var cor_t: Color = Desenho.DOURADO if completa else cor.lightened(0.4)
		var yl: float = r.position.y + 18.0
		for l in nome_l:
			Desenho.texto(self, l, Vector2(r.position.x + 11, yl), tm, cor_t, -1.0, 3)
			yl += 15.0 if tm == 13 else 18.0
		_texto_dir("%d/%d" % [cont[c], Pecas.SLOTS], r.end.x - 6.0, r.position.y + 18, 13, cor_t, 3)
		y += alt + 4.0
	# heranças: poderes que o gato solta sozinho, com qualquer roupa (e o aviso de herança pronta)
	var roxo := Color(0.72, 0.56, 1.0)
	if b.herancas.size() >= 3:
		# muitas heranças: uma fileira só de selos (o nome e a explicação vêm na dica do mouse); grau II+ em algarismo no canto
		var x0: float = _sn(base.x - SELO_HER * 0.5 * b.herancas.size() + PX * 0.5)
		for hi in b.herancas.size():
			var h: int = b.herancas[hi]
			var rs := Rect2(x0 + hi * SELO_HER, y, SELO_HER, SELO_HER)
			_rect_her_feita.append([rs, estado.bonecos.find(b), h])
			var sob: bool = rs.has_point(mouse) and arrasto.is_empty()
			_selo_heranca(rs.get_center(), Pecas.PODER_TIPO[h], roxo.lightened(0.35) if sob else roxo)
			var g_h: int = b.grau_de(h)
			if g_h > 1:
				IconesPoder.texto(_c, str(g_h), Vector2(rs.end.x - PX * 4.0, rs.end.y - PX * 6.0), Color(1, 1, 1), 3)
		y += SELO_HER + 4.0
	for h in b.herancas:
		if b.herancas.size() >= 3:
			break   # já foram na fileira de selos
		# uma linha: selo roxo com o ícone do poder herdado e o nome (a explicação vem na dica do mouse)
		var rh := Rect2(base.x - 74, y, 148, SELO_HER)
		draw_rect(rh, Color(0.12, 0.06, 0.2, 0.78))
		draw_rect(rh, _com_alfa(roxo, 0.9), false, 2.0)
		if rh.has_point(mouse) and arrasto.is_empty():
			draw_rect(rh, Color(1, 1, 1, 0.12))
		_rect_her_feita.append([rh, estado.bonecos.find(b), h])
		_selo_heranca(Vector2(rh.position.x + SELO_HER * 0.5, rh.get_center().y), Pecas.PODER_TIPO[h], roxo)
		var nome_h: String = Simulacao.heranca_nome_curto(h, b.grau_de(h))
		Desenho.texto(self, nome_h, Vector2(rh.position.x + SELO_HER + 5.0, rh.position.y + 24), _tam_cabe(nome_h, [16, 14, 13, 12], 148.0 - SELO_HER - 8.0), Color(1, 1, 1), -1.0, 3)
		y += SELO_HER + 4.0
	if b.herancas_pendentes() > 0:
		var pu_h: float = 0.5 + 0.5 * sin(t * 5.0)
		var fc_h: int = b.fantasia_completa()
		var pronta_h: bool = fc_h >= 0
		var rp := Rect2(base.x - 74, y, 148, SELO_HER if pronta_h else 28.0)
		draw_rect(rp, Color(0.12, 0.06, 0.2, 0.78 if pronta_h else 0.5))
		draw_rect(rp, _com_alfa(Desenho.DOURADO, 0.55 + 0.45 * pu_h) if pronta_h else Color(0.6, 0.55, 0.5, 0.45), false, 2.0)
		if rp.has_point(mouse) and arrasto.is_empty():
			draw_rect(rp, Color(1, 1, 1, 0.16))
		_rect_heranca.append([rp, estado.bonecos.find(b)])
		if pronta_h:
			# o poder da fantasia vestida, que vai ser herdado: selo com o aro piscando entre o dourado e o roxo
			_selo_heranca(Vector2(rp.position.x + SELO_HER * 0.5, rp.get_center().y), Pecas.PODER_TIPO[fc_h], Desenho.DOURADO if pu_h > 0.5 else roxo)
			Desenho.texto(self, Idioma.t("Herança pronta!"), Vector2(rp.position.x + SELO_HER + 5.0, rp.position.y + 24), _tam_cabe(Idioma.t("Herança pronta!"), [15, 14, 13], 148.0 - SELO_HER - 8.0), Desenho.DOURADO, -1.0, 3)
		else:
			_estrela4(Vector2(rp.position.x + 18.0, rp.get_center().y), 4.0, Color(0.55, 0.5, 0.42))
			# o poder está à espera, mas só se incorpora com a fantasia completa: tom apagado, sem prometer "pronta"
			Desenho.texto(self, Idioma.t("Herança: vista 4/4"), Vector2(rp.position.x + 28.0, rp.position.y + 19), 13, Color(0.78, 0.73, 0.65, 0.85), -1.0, 3)

## Ladrilho de uma peça: fundo do espaço, tarja da fantasia, moldura da raridade e ícone.
func _ladrilho(r: Rect2, p: Peca, escondida: bool = false, sob: bool = false) -> void:
	var fundo: Color = COR_SLOT[p.slot()]
	if escondida:
		fundo = fundo.darkened(0.6)
	elif sob:
		fundo = fundo.lightened(0.22)
	_c.draw_rect(r.grow(-2), fundo.darkened(0.2))
	_c.draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, r.size.y * 0.55), fundo)
	if escondida:
		nove(_c, GUI_TEX, R_FINA, M_FINA, r, 0.5, Color(1, 1, 1, 0.5))
		return
	match p.raridade:
		0:
			_c.draw_rect(r.grow(-2), Color(1, 1, 1, 0.22), false, 1.0)
		1:
			_c.draw_rect(r.grow(-2), Pecas.RARIDADE_COR[1], false, 2.0)
		_:
			var pulso: float = 0.5 + 0.5 * sin(t * 3.0)
			var cr_r: Color = Pecas.cor_rar(p.raridade)
			_c.draw_rect(r.grow(1), Color(cr_r.r, cr_r.g, cr_r.b, 0.2 + 0.25 * pulso), false, 2.0)
			_c.draw_rect(r.grow(-2), cr_r, false, 2.0)
			if p.raridade == 4:
				_c.draw_rect(r.grow(-5), Color.from_hsv(fposmod(t * 0.3 + 0.5, 1.0), 0.6, 1.0, 0.5), false, 1.0)
			elif p.raridade >= 5:
				_c.draw_rect(r.grow(-5), Color(1.0, 1.0, 1.0, 0.45 + 0.4 * pulso), false, 1.0)
				_c.draw_rect(r.grow(3), Color(cr_r.r, cr_r.g, cr_r.b, 0.12 + 0.18 * pulso), false, 1.0)
	# moldura + tarja e ícone + pips + marcas não mudam de um quadro para o outro: vão para texturas pré-compostas
	# (ver CacheDesenho). O brilho de raridade pulsa, então fica de fora e é desenhado a cada quadro, entre as duas.
	var cj: int = p.conjunto()
	var inteiro: bool = r.position == r.position.round() and r.size == r.size.round()
	var c: Vector2 = r.get_center() + Vector2(0, 2)
	var tam: float = r.size.x * 0.72
	var k1: int = hash([1, r.size, cj]) if inteiro else 0
	if not (inteiro and CacheDesenho.desenhar(_c, k1, r)):
		if inteiro and CacheDesenho.pode_criar(_c, k1):
			CacheDesenho.criar(_c, k1, r.size, func(a: CanvasItem) -> void: _ladrilho_moldura(a, Rect2(Vector2.ZERO, r.size), cj))
		_ladrilho_moldura(_c, r, cj)
	if p.raridade > 0:
		Desenho.icone_brilho(_c, p.tipo, c, tam, p.raridade)
	var k2: int = hash([2, r.size, p.tipo, p.nivel, p.marcas, Atelie.forma(p.tipo), CacheDesenho.atelie_sig() if p.tipo >= Pecas.Tipo.ATELIE_CABECA else 0]) if inteiro else 0
	if not (inteiro and CacheDesenho.desenhar(_c, k2, r)):
		if inteiro and CacheDesenho.pode_criar(_c, k2):
			var tp: int = p.tipo
			var nv: int = p.nivel
			var mc: Array = p.marcas.duplicate()
			CacheDesenho.criar(_c, k2, r.size, func(a: CanvasItem) -> void: _ladrilho_peca(a, Rect2(Vector2.ZERO, r.size), tp, nv, mc))
		_ladrilho_peca(_c, r, p.tipo, p.nivel, p.marcas)
	if sob:
		_c.draw_rect(r.grow(1.0), Desenho.DOURADO, false, 2.0)

## Moldura de madeira fina e tarja da cor da fantasia de um ladrilho (só depende do tamanho e do conjunto).
func _ladrilho_moldura(a: CanvasItem, r: Rect2, cj: int) -> void:
	nove(a, GUI_TEX, R_FINA, M_FINA, r, 0.5)
	a.draw_rect(Rect2(r.position.x + 4, r.position.y + 4, r.size.x - 8, 4), Pecas.CONJUNTO_COR[cj])

## Ícone (sem o brilho de raridade), pips de nível e marcas de um ladrilho.
func _ladrilho_peca(a: CanvasItem, r: Rect2, tipo: int, nivel: int, marcas: Array) -> void:
	var c: Vector2 = r.get_center() + Vector2(0, 2)
	Desenho.icone(a, tipo, c, r.size.x * 0.72, 0, 0.0, 0.0, [], 0)
	var k: float = r.size.x / 46.0
	if nivel > 0:
		Desenho.pips(a, Vector2(c.x, r.end.y - 5.0 * k), nivel, 1.8 * k, 5.0 * k)
	if marcas.size() > 0:
		Desenho.pontos_marcas(a, Vector2(r.position.x + 6.0 * k, c.y), marcas, 2.2 * k, 5.6 * k, true)

## Grade da aba Fantasias: um cartão por fantasia, com as 4 peças, o nome e quantas dá para vestir.
func _cartoes_fantasias() -> void:
	var alvo: int = _alvo_vestir()
	var mapa: Dictionary = _mapa_guarda_desenho()
	var fonte: Font = UIComum.FONTE
	var sob_c: int = _cartao_fant_em(mouse) if arrasto.is_empty() else -1
	for c in Pecas.CONJUNTO_PECAS.size():
		if not _tem_cartao_fant(c):
			continue
		var r: Rect2 = rect_cartao_fant(c)
		if r.size.x <= 0.0:
			continue
		var cor: Color = Pecas.CONJUNTO_COR[c]
		var st: Dictionary = _situacao_fantasia(c, alvo, mapa)
		var disp: int = int(st["gato"]) + int(st["guarda"])
		var vestida: bool = int(st["gato"]) >= Pecas.SLOTS
		var pronta: bool = disp >= Pecas.SLOTS and not vestida
		var em_uso: bool = disp < Pecas.SLOTS and disp + int(st["outro"]) >= Pecas.SLOTS
		var sob: bool = c == sob_c
		var fundo: Color = Color(0.13, 0.08, 0.08)
		if vestida:
			fundo = cor.darkened(0.6)
		elif pronta:
			fundo = cor.darkened(0.45)
		elif em_uso:
			fundo = Color(0.2, 0.12, 0.08)
		elif disp > 0:
			fundo = cor.darkened(0.78)
		if sob:
			fundo = fundo.lightened(0.18)
		draw_rect(r.grow(-2), fundo)
		draw_rect(Rect2(r.position.x + 2, r.position.y + 2, r.size.x - 4, 4), cor if (pronta or vestida or disp > 0) else cor.darkened(0.55))
		if pronta:
			var pulso: float = 0.5 + 0.5 * sin(t * 4.0)
			draw_rect(r.grow(-2), Color(1.0, 0.85, 0.35, 0.55 + 0.3 * pulso), false, 2.0)
		elif vestida:
			draw_rect(r.grow(-2), Color(0.5, 1.0, 0.6, 0.7), false, 2.0)
		elif em_uso:
			draw_rect(r.grow(-2), Color(1.0, 0.6, 0.25, 0.6), false, 1.0)
		else:
			draw_rect(r.grow(-2), Color(1, 1, 1, 0.12), false, 1.0)
		nove(self, GUI_TEX, R_FINA, M_FINA, r, 0.5)
		# nome na cor da fantasia
		var nome: String = Idioma.t(Pecas.CONJUNTO_NOME[c])
		var cn: Color = cor.lightened(0.5) if (disp > 0 or em_uso) else cor.lightened(0.2).darkened(0.25)
		Desenho.texto(self, Fichario.cortar(nome, 19, r.size.x - 6.0), Vector2(r.position.x, r.position.y + 19), 19, cn, r.size.x)
		# o gato escolhido vestindo a fantasia (peças que faltam: espaço vazio e fantasminha; sem nenhuma peça: silhueta escura)
		var nenhuma: bool = int(st["gato"]) + int(st["guarda"]) + int(st["outro"]) == 0
		var vestes: Array = [null, null, null, null]
		for i in Pecas.SLOTS:
			var tp0: int = int(st["tipos"][i])
			var q0: Peca = st["pecas"][i]
			if q0 != null:
				vestes[Pecas.SLOT[tp0]] = q0
			elif nenhuma:
				vestes[Pecas.SLOT[tp0]] = Peca.new(tp0)
		var pe := Vector2(r.get_center().x - 2.0, r.position.y + 75.0)
		_ellipse_sombra(pe + Vector2(0, 2), 24.0, 4.5, Color(0, 0, 0, 0.35))
		Desenho.boneco(self, pe, FANT_ESC, 1.0, 0, vestes, 0.0, 0.0, false, 0.0, 1.0, not nenhuma, -1, 0.0, 0, false, false, 0, false, -1, false, false, posmod(maxi(alvo, 0), Desenho.PELAGENS.size()), false)
		if nenhuma:
			draw_rect(Rect2(r.position.x + 3, r.position.y + 22, r.size.x - 6, 58), Color(fundo.r, fundo.g, fundo.b, 0.84))
		# quatro pontinhos: situação de cada peça (verde: já no gato; azul: guarda-roupa; laranja: outro gato; cinza: não tem)
		for i in Pecas.SLOTS:
			var cor_p: Color = [Color(0.45, 0.95, 0.55), Color(0.5, 0.75, 1.0), Color(1.0, 0.6, 0.25), Color(0.4, 0.4, 0.46)][int(st["onde"][i])]
			var pr := Rect2(r.get_center().x - 21.0 + i * 11.0, r.position.y + 81.0, 9.0, 5.0)
			draw_rect(pr.grow(1.0), Color(0, 0, 0, 0.6))
			draw_rect(pr, cor_p)
		# rodapé: N/4 e a situação
		var yb: float = r.end.y - 6.0
		var cnt: String = "%d/%d" % [disp, Pecas.SLOTS]
		var ccnt: Color = Color(0.75, 1.0, 0.8) if disp >= Pecas.SLOTS else (Color(1, 1, 1, 0.85) if disp > 0 else Color(1, 1, 1, 0.4))
		Desenho.texto(self, cnt, Vector2(r.position.x + 9, yb), 13, ccnt)
		var tag: String = ""
		var ctag: Color = Color.WHITE
		if vestida:
			tag = Idioma.t("vestida")
			ctag = Color(0.6, 1.0, 0.65)
		elif pronta:
			tag = Idioma.t("vestir!")
			ctag = Desenho.DOURADO
		elif em_uso:
			tag = Idioma.t("em uso")
			ctag = Color(1.0, 0.7, 0.35)
		elif int(st["outro"]) > 0:
			tag = Idioma.t("+%d em uso") % int(st["outro"])
			ctag = Color(1.0, 0.7, 0.35, 0.85)
		if tag != "":
			var lt: float = fonte.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(11)).x
			Desenho.texto(self, tag, Vector2(r.end.x - 7.0 - lt, yb), 11, ctag)

func _barra_fantasias() -> void:
	if _rolagem_max() <= 0:
		return
	var h: float = FANT_LINHAS * (FANT_H + FANT_GAP) - FANT_GAP
	var trilho := Rect2(PAINEL.end.x - 30, TILE_Y0, 10, h)
	draw_rect(trilho.grow(2.0), Color(0.07, 0.04, 0.05))
	draw_rect(trilho, Color(0.2, 0.13, 0.12))
	var total: int = int(ceil(_n_cartoes_fant() / float(FANT_COLS)))
	var alt: float = h * FANT_LINHAS / float(total)
	var topo: float = (h - alt) * rolagem / float(maxi(1, total - FANT_LINHAS))
	draw_rect(Rect2(trilho.position.x, trilho.position.y + topo, trilho.size.x, alt), Color(0.85, 0.65, 0.4))
	draw_rect(Rect2(trilho.position.x, trilho.position.y + topo, 3, alt), Color(1.0, 0.88, 0.62))

func _painel_guarda() -> void:
	_atualizar_pares()
	_painel(PAINEL, Color(0.18, 0.1, 0.09, 0.97))
	_titulo_ou_filtro()
	# abas
	for k in _abas():
		var ra: Rect2 = rect_aba(k)
		var nome: String = Idioma.t("Todas")
		if k == ABA_FANTASIAS:
			nome = Idioma.t("Fantasias")
		elif k == ABA_NOVAS:
			nome = Idioma.t("Novas")
		elif k != ABA_TODAS:
			nome = Idioma.t(ABA_NOMES[k])
		var ativa: bool = k == aba
		var sob: bool = ra.has_point(mouse)
		var qtd: int = _contar_aba(k)
		var cf: Color = Color(1.0, 0.86, 0.55) if ativa else (Color(0.78, 0.6, 0.45) if sob else Color(0.5, 0.37, 0.3))
		if k == ABA_NOVAS and qtd > 0 and not ativa:
			cf = cf.lerp(Color(1.0, 0.85, 0.3), 0.3 + 0.3 * (0.5 + 0.5 * sin(t * 6.0)))
		if ativa:
			ra = Rect2(ra.position.x, ra.position.y - 3.0, ra.size.x, ra.size.y + 3.0)
		_botao_arte(ra, cf, false)
		var ct: Color = COR_TINTA_ESC if ativa else (Color(0.2, 0.1, 0.05) if (sob or (k == ABA_NOVAS and qtd > 0)) else Color(1, 0.94, 0.8, 0.8 if qtd > 0 else 0.5))
		var rot: String = "%s %d" % [nome, qtd]
		if UIComum.FONTE.get_string_size(rot, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x > ra.size.x - 6.0:
			rot = "%s %d" % [{Idioma.t("Fantasias"): Idioma.t("Fantas."), Idioma.t("Acessório"): Idioma.t("Acess.")}.get(nome, nome), qtd]   # o rótulo inteiro não cabe na aba
		Desenho.texto(self, rot, ra.position + Vector2(0, ra.size.y - 8.0), _tam_cabe(rot, [13, 12, 11], ra.size.x - 8.0), ct, ra.size.x)
	if aba == ABA_FANTASIAS:
		_cartoes_fantasias()
		_barra_fantasias()
		if (arrasto.has("peca") and arrasto["origem"] != null) or arrasto.has("boneco"):
			draw_rect(PAINEL.grow(-10), Color(1, 0.9, 0.5, 0.16 + 0.1 * sin(t * 8.0)))
		return
	var lista: Array[Peca] = _visiveis()
	var oculta: Peca = null
	if arrasto.has("peca") and arrasto["origem"] == null:
		oculta = arrasto["peca"]
	if lista.is_empty():
		Desenho.texto(self, Idioma.t("Nenhuma peça aqui."), Vector2(PAINEL.position.x, TILE_Y0 + 80), 16, Color(1, 1, 1, 0.5), PAINEL.size.x)
	var primeiro: int = rolagem * TILE_COLS
	var ultimo: int = mini(lista.size(), (rolagem + TILE_LINHAS) * TILE_COLS)
	var sob_ti: int = _tile_em(mouse) if arrasto.is_empty() else -1
	for i in range(primeiro, ultimo):
		var r: Rect2 = rect_tile(i)
		var p: Peca = lista[i]
		_ladrilho(r, p, p == oculta or _em_voo(p), i == sob_ti)
		if p != oculta and not _em_voo(p):
			_realce_fantasia(r, p)
		if _pares.has(p.tipo) and p != oculta:
			_selo_pares(r, int(_pares[p.tipo]))
		if arrasto.has("peca") and p != arrasto["peca"] and estado.pode_fundir(p, arrasto["peca"]):
			_destaque_fusao(r.get_center(), 25.0)
		if p.nova:
			var pulso: float = 0.5 + 0.5 * sin(t * 6.0)
			draw_rect(r.grow(1), Color(1, 1, 0.5, 0.25 + 0.45 * pulso), false, 1.0)
			_grade_px(self, ICO_NOVA, r.position + Vector2(r.size.x - 13.0, -2.0), PX, Desenho.DOURADO)
	# barra de rolagem
	var total: int = int(ceil(lista.size() / float(TILE_COLS)))
	if total > TILE_LINHAS:
		var trilho := Rect2(PAINEL.end.x - 30, TILE_Y0, 10, TILE_LINHAS * TILE_PASSO - 4)
		draw_rect(trilho.grow(2.0), Color(0.07, 0.04, 0.05))
		draw_rect(trilho, Color(0.2, 0.13, 0.12))
		var alt: float = trilho.size.y * TILE_LINHAS / float(total)
		var topo: float = (trilho.size.y - alt) * rolagem / float(maxi(1, total - TILE_LINHAS))
		draw_rect(Rect2(trilho.position.x, trilho.position.y + topo, trilho.size.x, alt), Color(0.85, 0.65, 0.4))
		draw_rect(Rect2(trilho.position.x, trilho.position.y + topo, 3, alt), Color(1.0, 0.88, 0.62))
	# destaque quando arrastando um boneco ou peça usada para tirar
	if (arrasto.has("peca") and arrasto["origem"] != null) or arrasto.has("boneco"):
		draw_rect(PAINEL.grow(-10), Color(1, 0.9, 0.5, 0.16 + 0.1 * sin(t * 8.0)))

## Selo "×N" (peças iguais que podem se fundir): pílula pequena no canto de cima à esquerda do ladrilho,
## em fonte 3x5, para não cobrir a peça. A grade é a da arte do guarda-roupa (PX), um passo abaixo.
func _selo_pares(r: Rect2, n: int) -> void:
	var e: int = maxi(int(PX) - 1, 1)
	var ef: float = float(e)
	var txt: String = "x%d" % n
	var w: float = float(txt.length() * 4 + 1) * ef   # miolo: 1 de folga, o texto, 1 de folga
	var h: float = 7.0 * ef
	var o := Vector2(floorf(r.position.x / ef) * ef + ef, floorf(r.position.y / ef) * ef + ef)
	var cont := Color(0.05, 0.14, 0.08)
	# pílula: retângulo com os quatro cantos cortados, contorno escuro de 1 pixel
	draw_rect(Rect2(o.x + ef, o.y, w, h), cont)
	draw_rect(Rect2(o.x, o.y + ef, w + 2.0 * ef, h - 2.0 * ef), cont)
	draw_rect(Rect2(o.x + ef, o.y + ef, w, h - 2.0 * ef), Color(0.24, 0.62, 0.34))
	IconesPoder.texto(self, txt, Vector2(o.x + ef, o.y), Color(0.97, 1.0, 0.9), e, false)

## Conjunto de fantasia mais frequente nas peças de um inimigo (-1 se ninguém passa de 1).
func _fantasia_de(pecas: Array) -> int:
	var cont: Array[int] = Pecas.contar_conjuntos(pecas)
	var melhor: int = -1
	var maior: int = 1
	for c in cont.size():
		if cont[c] > maior:
			maior = cont[c]
			melhor = c
	return melhor

## Agrupa a onda por tipo (e elite): cada grupo guarda o primeiro inimigo e a contagem.
func _grupos_previa() -> Array:
	var grupos: Array = []
	for e in estado.plano:
		var d: Dictionary = e
		var chave: String = "%d|%s" % [int(d["tipo"]), str(d.get("elite", false))]
		var achou: bool = false
		for g in grupos:
			if g["chave"] == chave:
				g["n"] = int(g["n"]) + 1
				achou = true
				break
		if not achou:
			grupos.append({"chave": chave, "ini": d, "n": 1})
	return grupos

## Desenha uma célula da prévia: o bicho inteiro (quatro patas), "×N" e o rótulo do tipo.
func _celula_previa(g: Dictionary, topo_esq: Vector2, larg: float, alt: float, esc_base: float, fi: int, idx: int) -> void:
	var ini: Dictionary = g["ini"]
	var tp: int = ini["tipo"]
	var eli: bool = ini.get("elite", false)
	var rotulo: String = ""
	var cor_r: Color = Color.WHITE
	if eli:
		var cj: int = _fantasia_de(ini["pecas"])
		rotulo = Idioma.t(Pecas.CONJUNTO_NOME[cj]) if cj >= 0 else Idioma.t("Fantasiado")
		cor_r = Pecas.CONJUNTO_COR[cj].lightened(0.35) if cj >= 0 else Desenho.DOURADO
	elif tp != Unidade.Tipo.COMUM or (ini.get("rival", false) and Balanco.nome_rival(int(ini.get("gangue", -1)), tp) != Balanco.TIPO_NOMES[tp]):
		rotulo = Idioma.t(Balanco.nome_rival(int(ini.get("gangue", -1)), tp) if ini.get("rival", false) else Balanco.TIPO_NOMES[tp])
		cor_r = Desenho.COR_TIPO[tp].lightened(0.45)
	var reserva: float = 0.0
	var linhas_r: Array[String] = []
	if rotulo != "":
		linhas_r = _quebrar(rotulo, 13, larg - 2.0)
		reserva = 4.0 + linhas_r.size() * 15.0
	var esc: float = esc_base * lerpf(1.0, Balanco.TIPO_ESCALA[tp], 0.35)
	# os bichos olham para a esquerda (o corpo cresce para lá): o centro fica dentro da moldura do painel nos dois lados
	var cx_b: float = clampf(topo_esq.x + larg * 0.5 + 8.0, PREVIA.position.x + 18.0 + 70.0 * esc, PREVIA.end.x - 16.0 - 44.0 * esc)
	var pe: Vector2 = Vector2(cx_b, topo_esq.y + alt - reserva - 3.0)
	_ellipse_sombra(pe + Vector2(0, 2), 30.0 * esc, 5.0 * esc, Color(0, 0, 0, 0.35))
	Desenho.boneco(self, pe, esc, -1.0, 1, ini["pecas"], 0.0, t * 2.0 + idx, false, 0.0, 1.0, false, -1, 0.0, tp, false, false, fi, eli, -1, false, false, 0, false, int(ini.get("gangue", -1)) if ini.get("rival", false) else -1)
	var y: float = pe.y + 17.0
	for l in linhas_r:
		Desenho.texto(self, l, Vector2(topo_esq.x, y), 13, cor_r, larg, 3)
		y += 15.0
	var cnt: int = g["n"]
	if cnt > 1:
		var tx: float = topo_esq.x + larg - 4.0
		_texto_dir("×%d" % cnt, tx, topo_esq.y + 16.0, 16, Color(1, 0.95, 0.6), 4)

func _previa() -> void:
	var fi: int = estado.lugar_chefe()
	_painel(PREVIA, Color(0.24, 0.1, 0.12, 0.96))
	var xi: float = PREVIA.position.x + 18.0
	var li: float = PREVIA.size.x - 36.0
	UIComum.emblema(self, "inimigo", PREVIA.position + Vector2(20, 26), 2.0, Desenho.COR_INIMIGO)
	var tem_chefe: bool = not estado.chefe.is_empty()
	var tit_prev: String = Idioma.t("Próxima onda: CHEFE") if tem_chefe else Idioma.t("Próxima onda")
	if estado.invasao:
		tit_prev = Idioma.t("Onda %d: CHEFE!") % estado.onda_invasao if tem_chefe else Idioma.t("Onda %d") % estado.onda_invasao
	Desenho.texto(self, tit_prev, PREVIA.position + Vector2(48, 42), 18 if tem_chefe else 22, Color(1, 0.85, 0.82), -1.0, 3)
	var grupos: Array = _grupos_previa()
	var cols: int = 3
	var larg_c: float = li / cols
	var topo: float = PREVIA.position.y + 56.0
	var yt: float
	if tem_chefe:
		var cx: float = PREVIA.position.x + PREVIA.size.x * 0.5
		var pe: Vector2 = Vector2(cx, PREVIA.position.y + 124.0)
		_ellipse_sombra(pe + Vector2(0, 3), 46.0, 8.0, Color(0, 0, 0, 0.4))
		Desenho.boneco(self, pe, 1.2, -1.0, 1, estado.chefe, 0.0, t * 2.0, false, 0.0, 1.0, false, -1, 0.0, 0, false, true, Fases.chefe_base(fi), false, Fases.chefe_base(fi))
		var linhas_e: int = int(ceil(grupos.size() / float(cols)))
		var alt_e: float = 52.0 if linhas_e <= 1 else 44.0
		for i in grupos.size():
			var c: int = i % cols
			var l: int = i / cols
			var n_linha: int = mini(cols, grupos.size() - l * cols)
			var x0: float = xi + (li - n_linha * larg_c) * 0.5 + c * larg_c
			_celula_previa(grupos[i], Vector2(x0, PREVIA.position.y + 132.0 + l * alt_e), larg_c, alt_e, 0.5 if linhas_e <= 1 else 0.4, fi, i)
		yt = PREVIA.position.y + 132.0 + linhas_e * alt_e + (22.0 if linhas_e <= 1 else 14.0)
		Desenho.texto(self, Idioma.t(Fases.nome_do_chefe(fi)), Vector2(xi, yt), 16, Desenho.DOURADO, -1.0, 3)
		yt = _paragrafo(Idioma.t("Ataque: %s") % Idioma.t(Fases.ataque_do_chefe(fi)), Vector2(xi, yt + 17), 13, Color(1, 0.88, 0.82), li, 15.0)
		_paragrafo(Idioma.t("Fraqueza: %s") % Idioma.t(Fases.fraqueza_do_chefe(fi)), Vector2(xi, yt + 1), 13, Color(0.7, 1.0, 0.75), li, 15.0)
	else:
		var linhas: int = int(ceil(grupos.size() / float(cols)))
		var area_h: float = 196.0
		var alt_c: float = minf(86.0, area_h / maxf(1.0, linhas))
		var esc_b: float = clampf((alt_c - 26.0) / 56.0, 0.45, 0.8)   # até 0,8: os bichos grandes não passam da borda do painel
		var desloc: float = (area_h - minf(area_h, linhas * alt_c)) * 0.5
		for i in grupos.size():
			var c: int = i % cols
			var l: int = i / cols
			var n_linha: int = mini(cols, grupos.size() - l * cols)
			var x0: float = xi + (li - n_linha * larg_c) * 0.5 + c * larg_c
			_celula_previa(grupos[i], Vector2(x0, topo + desloc + l * alt_c), larg_c, alt_c, esc_b, fi, i)
		yt = PREVIA.position.y + 272.0
		Desenho.texto(self, Idioma.t(Fases.grupo_nome(fi)), Vector2(xi, yt), 16, Color(1, 0.88, 0.8), -1.0, 3)
		# a frase da família vive na dica do mouse do painel

func _bigorna() -> void:
	var pc: Peca = arrasto["peca"] if arrasto.has("peca") else null
	_painel(BIGORNA, Color(0.34, 0.19, 0.26, 0.97))
	Desenho.texto(self, Idioma.t("Promover"), Vector2(BIGORNA.position.x, BIGORNA.position.y + 32), 22, COR_TINTA, BIGORNA.size.x, 4)
	var expl: String = ""   # a explicação fixa foi para a dica do mouse do painel
	var cor_expl: Color = Color(1.0, 0.92, 0.78, 0.9)
	if msg_painel_t > 0.0:
		expl = msg_painel
		cor_expl = Color(1.0, 0.55, 0.5)
	if expl != "":
		_paragrafo(expl, Vector2(BIGORNA.position.x + 20.0, BIGORNA.position.y + 52.0), 12, cor_expl, BIGORNA.size.x - 40.0, 14.0, true)
	# alvo 1: carretel (nível, custa blocos)
	var m1: String = _motivo_nivel(pc) if pc != null else ""
	var c1: String = "" if pc == null else (Idioma.t("−%d blocos") % Balanco.custo_promocao(pc.nivel))
	_alvo_promover(ALVO_CARRETEL, pc, m1, Idioma.t("Nível"), c1 if pc != null else Idioma.t("%d a %d blocos") % [Balanco.PROMOCAO_CUSTO[0], Balanco.PROMOCAO_CUSTO[-1]], false)
	# alvo 2: estrela (raridade, custa troféus)
	var m2: String = _motivo_reforco(pc) if pc != null else ""
	var c2: String = ""
	if pc != null and pc.raridade < Pecas.Raridade.MIAUJESTOSA:
		c2 = Idioma.t("−%d troféus") % Balanco.custo_reforco(pc.raridade)
	elif pc == null:
		c2 = Idioma.t("%d a %d troféus") % [Balanco.REFORCO_CUSTO[0], Balanco.REFORCO_CUSTO[-1]]
	_alvo_promover(ALVO_ESTRELA, pc, m2, Idioma.t("Raridade"), c2, true)

## Borda tracejada de pixel: traços de 2 quadradinhos com 2 de vão, de PX de espessura.
func _tracejado_px(r: Rect2, cor: Color) -> void:
	var x: float = r.position.x
	while x < r.end.x - 0.5:
		var w: float = minf(PX * 2.0, r.end.x - x)
		draw_rect(Rect2(x, r.position.y, w, PX), cor)
		draw_rect(Rect2(x, r.end.y - PX, w, PX), cor)
		x += PX * 4.0
	var y: float = r.position.y + PX * 4.0
	while y < r.end.y - PX - 0.5:
		var h: float = minf(PX * 2.0, r.end.y - PX - y)
		draw_rect(Rect2(r.position.x, y, PX, h), cor)
		draw_rect(Rect2(r.end.x - PX, y, PX, h), cor)
		y += PX * 4.0

## Um dos dois alvos do painel: apagado com o motivo quando a peça arrastada não pode, aceso com o custo quando pode.
func _alvo_promover(r: Rect2, pc: Peca, motivo: String, nome: String, custo: String, estrela: bool) -> void:
	var ativo: bool = pc != null
	var bloqueado: bool = ativo and motivo != ""
	var sobre: bool = ativo and r.has_point(mouse)
	var fundo: Color = Color(0.2, 0.1, 0.14, 0.9)
	if sobre and not bloqueado:
		fundo = Color(0.5, 0.3, 0.2, 0.95)
	draw_rect(r, fundo)
	var borda: Color = Color(0.9, 0.75, 0.55, 0.5)
	if ativo and not bloqueado:
		borda = Desenho.DOURADO
	elif bloqueado:
		borda = Color(0.7, 0.4, 0.4, 0.5)
	_tracejado_px(r, borda)
	var alfa: float = 0.4 if bloqueado else 1.0
	var c: Vector2 = Vector2(r.get_center().x, r.position.y + 38.0)
	var vivo: bool = sobre and not bloqueado
	if estrela:
		# com a peça em cima, a estrela pula um quadradinho em vez de girar (giro tira o desenho da grade)
		var pulo: float = -PX if (vivo and fposmod(t, 0.4) < 0.2) else 0.0
		var cont: Color = CONT_PX if alfa >= 1.0 else Color(0, 0, 0, 0)
		_estrela4(c + Vector2(0, pulo), 26.0, Color(1.0, 0.82, 0.25, alfa), cont)
		_estrela4(c + Vector2(15, -17 + pulo), 8.0, Color(1.0, 0.95, 0.6, alfa), cont)
	else:
		var pulo_c: float = -PX if (vivo and fposmod(t, 0.4) < 0.2) else 0.0
		_grade_px(self, ICO_CARRETEL, c - Vector2(18.0, 22.0 - pulo_c), PX, Color.WHITE, alfa)
	Desenho.texto(self, nome, Vector2(r.position.x, r.position.y + 76.0), 17, Color(1, 1, 1, alfa + 0.1 if not bloqueado else 0.55), r.size.x, 3)
	if bloqueado:
		Desenho.texto(self, motivo, Vector2(r.position.x, r.position.y + 94.0), 13, Color(1.0, 0.6, 0.55), r.size.x, 3)
	else:
		Desenho.texto(self, custo, Vector2(r.position.x, r.position.y + 94.0), 13, Color(1.0, 0.92, 0.55) if ativo else Color(1, 1, 1, 0.6), r.size.x, 3)

## Confirmação de fusão: as duas peças, o resultado e o que acontece com a outra.
func _confirma_fusao() -> void:
	if fusao.is_empty():
		return
	var base: Peca = fusao["base"]
	var outra: Peca = fusao["outra"]
	var res: Peca = _resultado_fusao(base, outra)
	_c.draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.55))
	_painel(FUSAO_R, Color(0.14, 0.09, 0.12, 0.99), 0.75)
	Desenho.texto(_c, Idioma.t("Fundir peças iguais?"), Vector2(FUSAO_R.position.x, FUSAO_R.position.y + 46.0), 26, Desenho.DOURADO, FUSAO_R.size.x, 5)
	var y: float = FUSAO_R.position.y + 62.0
	_ladrilho(Rect2(512, y, 56, 56), base)
	_grade_px(_c, ICO_MAIS, Vector2(590.0 - 9.0, y + 28.0 - 9.0), PX, COR_TINTA)
	_ladrilho(Rect2(612, y, 56, 56), outra)
	_grade_px(_c, ICO_SETA, Vector2(690.0 - 12.0, y + 28.0 - 10.5), PX, Desenho.DOURADO)
	_ladrilho(Rect2(712, y, 56, 56), res)
	var texto: String = Idioma.t("%s + %s → %s, %s") % [_rot_peca(base), _rot_peca(outra), _rot_peca(res), _rot_marcas(res.marcas.size())]
	var yt: float = _paragrafo(texto, Vector2(FUSAO_R.position.x + 30.0, y + 88.0), 18, Color(1, 0.95, 0.85), FUSAO_R.size.x - 60.0, 23.0, true, 3)
	var soma: int = base.marcas.size() + outra.marcas.size()
	var nota: String = Idioma.t("Sai de graça. A outra peça some.")
	if soma > res.marcas.size():
		var perdem: int = soma - res.marcas.size()
		nota += Idioma.t(" %d marca a mais não cabe e se perde.") % perdem if perdem == 1 else Idioma.t(" %d marcas a mais não cabem e se perdem.") % perdem
	_paragrafo(nota, Vector2(FUSAO_R.position.x + 30.0, yt + 4.0), 14, Color(0.8, 0.9, 0.8, 0.85), FUSAO_R.size.x - 60.0, 17.0, true)
	var sob_ok: bool = FUSAO_OK.has_point(mouse_fusao())
	var sob_nao: bool = FUSAO_NAO.has_point(mouse_fusao())
	_botao_arte(FUSAO_OK, Color(0.62, 0.9, 0.55).lightened(0.2 if sob_ok else 0.0), sob_ok and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	Desenho.texto(_c, Idioma.t("Fundir"), FUSAO_OK.position + Vector2(0, 31), 24, COR_TINTA_ESC, FUSAO_OK.size.x)
	_botao_arte(FUSAO_NAO, Color(1.0, 0.7, 0.62).lightened(0.2 if sob_nao else 0.0), sob_nao and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	Desenho.texto(_c, Idioma.t("Cancelar"), FUSAO_NAO.position + Vector2(0, 31), 24, COR_TINTA_ESC, FUSAO_NAO.size.x)

## Posição do ponteiro para a confirmação (o `mouse` normal fica fora da tela com menus por cima).
func mouse_fusao() -> Vector2:
	return get_local_mouse_position()

func _efeitos() -> void:
	if not efeito_peca.is_empty():
		var pe: Vector2 = _pos_peca(efeito_peca["peca"])
		if pe.x >= 0.0:
			var k: float = clampf(float(efeito_peca["t"]) / 0.8, 0.0, 1.0)
			# clarão que encolhe, duas ondas de quadradinhos que somem pontilhando e uma estrelinha subindo
			if k < 0.6:
				_elipse_px(pe, 24.0 * (1.0 - k / 0.6), 24.0 * (1.0 - k / 0.6), Color(1, 1, 0.8, 0.45))
			var r1: float = 18.0 + 40.0 * k
			var r2: float = 10.0 + 24.0 * k
			VFX.aro(_c, pe, r1, r1, Color(1.0, 0.95, 0.6), 1.0 - k, 2.0 if k < 0.4 else 1.0, PX)
			VFX.aro(_c, pe, r2, r2, Color(0.6, 1.0, 0.75), 0.8 * (1.0 - k), 1.0, PX)
			if k < 0.85:
				_estrela4(pe + Vector2(0, -30.0 * k), 6.0 + 8.0 * (1.0 - k), Color(1.0, 0.95, 0.5), CONT_PX)
	for tv in tijolos_voando:
		var d: Dictionary = tv
		var k: float = d["t"]
		if k < 0.0:
			continue
		var ini: Vector2 = d["ini"]
		var fim: Vector2 = d["fim"]
		var e: float = k * k
		var p: Vector2 = ini.lerp(fim, e) + Vector2(0, -90.0 * sin(PI * k))
		_tijolo_px(p, d["cor"], float(d["rot"]) * k * 6.0, 1.0 - k * 0.5)
	for fa in faiscas:
		# faísca quadrada: encolhe de 2 para 1 quadradinho e some pontilhando (sem alfa)
		var f: Dictionary = fa
		var a: float = clampf(f["vida"] / f["max"], 0.0, 1.0)
		var raio: float = float(f["r"]) * (0.4 + 0.6 * a)
		if a < 0.25 and int(float(f["r"]) * 97.0) % 2 == 0:
			continue
		var s: float = PX * 2.0 if raio > 2.6 else PX
		var pf: Vector2 = f["p"]
		var c: Color = f["cor"]
		draw_rect(Rect2(_sn(pf.x - s * 0.5), _sn(pf.y - s * 0.5), s, s), Color(c.r, c.g, c.b, 1.0))
	_camada_voos()

## Tijolo voando em pixel: em vez de girar (o giro tira da grade), troca entre deitado, inclinado e em pé,
## e encolhe de PX em PX. Contorno escuro, miolo na cor do bloco e uma faixa clara em cima.
func _tijolo_px(p: Vector2, cor: Color, ang: float, esc: float) -> void:
	var fr: int = posmod(int(roundf(ang / (PI * 0.25))), 4)
	var w: float = maxf(PX * 4.0, _sn(40.0 * esc))
	var h: float = maxf(PX * 2.0, _sn(20.0 * esc))
	var cont: Color = Color(0.25, 0.12, 0.1)
	var x: float = _sn(p.x)
	var y: float = _sn(p.y)
	if fr == 0 or fr == 2:
		if fr == 2:
			var tr: float = w
			w = h
			h = tr
		var rr := Rect2(_sn(x - w * 0.5), _sn(y - h * 0.5), w, h)
		draw_rect(rr.grow(PX), cont)
		draw_rect(rr, cor)
		draw_rect(Rect2(rr.position, Vector2(rr.size.x, PX)), cor.lightened(0.3))
		return
	# inclinado: três degraus quadrados em diagonal (primeiro todos os contornos, depois os miolos)
	var dir: float = 1.0 if fr == 1 else -1.0
	var passo: float = _sn(h * 0.5 + PX * 0.5)
	for camada in 2:
		for q in 3:
			var o := Vector2((q - 1) * passo, -(q - 1) * passo * dir)
			var rq := Rect2(_sn(x - h * 0.5) + o.x, _sn(y - h * 0.5) + o.y, h, h)
			if camada == 0:
				draw_rect(rq.grow(PX), cont)
			else:
				draw_rect(rq, cor)
				draw_rect(Rect2(rq.position, Vector2(h, PX)), cor.lightened(0.3))

func _arrasto() -> void:
	if not arrasto.has("peca"):
		if arrasto.has("boneco"):
			Desenho.boneco(_c, mouse + Vector2(0, 50), 1.3, 1.0, 0, (arrasto["boneco"] as Boneco).pecas, 0.0, 0.0, false, 0.0, 0.8, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, estado.bonecos.find(arrasto["boneco"]), false)
		return
	var p: Peca = arrasto["peca"]
	_ellipse_sombra(mouse + Vector2(4, 40), 30.0, 8.0, Color(0, 0, 0, 0.35))
	_elipse_px(mouse, 33.0, 33.0, Color(1, 1, 1, 0.16))
	_aro_px(mouse, 36.0, 36.0, Color(1.0, 0.9, 0.5, 0.7))
	Desenho.icone(_c, p.tipo, mouse, 62.0, p.nivel, 0.0, 0.0, p.marcas, p.raridade)
	var bi_c: int = _boneco_em(mouse)
	if bi_c >= 0:
		_caixa_dica(_comparar(bi_c, p), 290.0, Pecas.CONJUNTO_COR[p.conjunto()], Desenho.DOURADO, mouse, Vector2(48, -40))

# ------------------------------------------------------------------ dicas
## Caixa de dica com a moldura de madeira. Itens: ["t", texto, tam, cor], ["sep"] ou
## ["m", texto, tam, cor, cor_da_situação, ícone]: linha com marcador à esquerda. `ícone` é o tipo de uma peça (int, ícone da roupa em
## pixel art numa plaquinha da cor da situação) ou o nome de um emblema (String, ver UIComum.EMBLEMAS). O marcador aparece UMA vez, na
## primeira linha; se o texto quebrar, as linhas seguintes recuam sob o texto da primeira, sem marcador novo.
## A largura é fixa (caixa estável) e a caixa nunca sai da tela. A pintura vai para a camada de topo (acima dos botões).
func _caixa_dica(itens: Array, larg: float, cor_faixa: Color, cor_borda: Color, ancora: Vector2, desl: Vector2) -> Rect2:
	var pad_x: float = 20.0
	var pad_y: float = 18.0
	var interno: float = larg - 2.0 * pad_x - 4.0
	var lin: Array = []
	var y: float = 0.0
	for it in itens:
		var tipo: String = it[0]
		if tipo == "sep":
			y += 5.0
			lin.append(["sep", y])
			y += 6.0
			continue
		var tam: int = it[2]
		var ic: Variant = it[5] if it.size() > 5 else null
		# Vector2i(poder, 0) = selo de herança (ícone do poder no aro roxo) à esquerda do texto; (poder, 1) = aro dourado
		var selo: bool = ic is Vector2i
		var ml: float = 0.0 if tipo == "t" else (SELO_HER + 8.0 if selo else 26.0)
		var y_selo: float = y
		if selo:
			lin.append(["selo", y, ic, it[4] if it.size() > 4 else Color(0.72, 0.56, 1.0)])
			ic = null
		var passo: float = float(tam) + 4.0
		var primeira: bool = true
		var quebradas: Array = _quebrar(it[1], tam, interno - ml)
		if selo:
			y += maxf(0.0, (SELO_HER - passo * quebradas.size()) * 0.5)   # texto curto fica no meio da altura do selo
		for l in quebradas:
			if primeira and ic is int:
				y += 3.0   # a plaquinha da peça é mais alta que a linha de texto
			lin.append([tipo, y + tam * 0.9, l, tam, it[3], it[4] if it.size() > 4 else Color.WHITE, ml, ic if primeira else null])
			y += passo
			if primeira and ic is int:
				y += 3.0
			primeira = false
		if selo:
			y = maxf(y, y_selo + SELO_HER + 4.0)
	var alt: float = y + 2.0 * pad_y
	var caixa := Rect2(ancora + desl, Vector2(larg, alt))
	if caixa.end.x > 1272.0:
		caixa.position.x = ancora.x - desl.x - caixa.size.x
	caixa.position.x = maxf(6.0, caixa.position.x)
	caixa.position.y = clampf(caixa.position.y, 6.0, 714.0 - alt)
	if _c == self:
		_topo_fila.append(_pintar_dica.bind(caixa, lin, cor_faixa, cor_borda))
	else:
		_pintar_dica(caixa, lin, cor_faixa, cor_borda)
	return caixa

func _pintar_dica(caixa: Rect2, lin: Array, cor_faixa: Color, cor_borda: Color) -> void:
	var pad_x: float = 20.0
	var pad_y: float = 18.0
	var alt: float = caixa.size.y
	_c.draw_rect(Rect2(caixa.position + Vector2(4, 5), caixa.size), Color(0, 0, 0, 0.35))
	_painel(caixa, Color(0.08, 0.05, 0.09, 0.98))
	_c.draw_rect(caixa.grow(-10.0), _com_alfa(cor_borda, 0.8), false, 1.5)
	_c.draw_rect(Rect2(caixa.position.x + 14.0, caixa.position.y + 14.0, 3.0, alt - 28.0), cor_faixa)
	var ox: float = caixa.position.x + pad_x + 4.0
	var oy: float = caixa.position.y + pad_y
	for l in lin:
		if l[0] == "sep":
			# separador pontilhado: quadradinhos de PX com um de vão
			var ys: float = roundf(oy + float(l[1]) - PX * 0.5)
			var xs: float = ox
			while xs + PX <= caixa.end.x - pad_x:
				_c.draw_rect(Rect2(xs, ys, PX, PX), Color(1, 1, 1, 0.2))
				xs += PX * 2.0
			continue
		if l[0] == "selo":
			var iv: Vector2i = l[2]
			_selo_heranca(Vector2(ox + SELO_HER * 0.5, oy + float(l[1]) + SELO_HER * 0.5), Pecas.PODER_TIPO[iv.x], Desenho.DOURADO if iv.y == 1 else l[3])
			continue
		if l[0] == "m" and l[7] != null:
			var base_y: float = oy + float(l[1])
			if l[7] is int:
				var cc := Vector2(ox + 10.0, base_y - 5.0)
				var cs: Color = l[5]
				_c.draw_rect(Rect2(cc - Vector2(11, 11), Vector2(22, 22)), Color(cs.r, cs.g, cs.b, 0.4))
				_c.draw_rect(Rect2(cc - Vector2(11, 11), Vector2(22, 22)), Color(cs.r, cs.g, cs.b, 0.95), false, 1.5)
				Desenho.icone(_c, int(l[7]), cc, 18.0)
			else:
				UIComum.emblema(_c, str(l[7]), Vector2(ox + 1.0, base_y - 12.0), 2.0, l[5])
		Desenho.texto(_c, l[2], Vector2(ox + float(l[6]), oy + float(l[1])), l[3], l[4])

## Dica do botão "Promover tudo" de um gato.
func _dica_promover_tudo(i: int) -> void:
	var b: Boneco = estado.bonecos[i]
	var st: Dictionary = _estado_promover_tudo(b)
	var itens: Array = [["t", Idioma.t("Promover a fantasia inteira"), 22, Desenho.DOURADO]]
	itens.append(["t", Idioma.t("Sobe um nível de cada peça que %s veste e ainda pode subir, pagando os blocos de cada peça (o nível mais alto custa mais) enquanto houver blocos.") % [b.nome], 13, Color(1, 1, 1)])
	itens.append(["sep"])
	if st["ok"]:
		var n_pecas: int = 0
		for q in b.pecas:
			if q != null and q.nivel < Balanco.NIVEL_MAX:
				n_pecas += 1
		itens.append(["t", (Idioma.t("Custo total: %d blocos para %d peça (a torre tem %d).") if n_pecas == 1 else Idioma.t("Custo total: %d blocos para %d peças (a torre tem %d).")) % [st["custo"], n_pecas, estado.tijolos], 13, Color(0.7, 1.0, 0.7)])
	else:
		itens.append(["t", st["motivo"], 13, Color(1.0, 0.6, 0.55)])
	_caixa_dica(itens, 300.0, Desenho.DOURADO, Desenho.DOURADO, mouse, Vector2(16, 24))

## Faixa do nome do gato i, no alto do vão: o mouse em cima abre a ficha em números.
func rect_ficha(i: int) -> Rect2:
	return Rect2(pos_boneco(i).x - 76.0, 14.0, 152.0, 48.0)

## Lápis do nome: abinha que sai pela quina de cima da plaquinha (aparece com o mouse em cima).
func rect_lapis(i: int) -> Rect2:
	return Rect2(pos_boneco(i).x + 48.0, 0.0, 28.0, 20.0)

func _lapis_em(p: Vector2) -> int:
	if modo != Modo.GUARDA:
		return -1
	for i in estado.bonecos.size():
		if rect_lapis(i).has_point(p):
			return i
	return -1

func _pode_renomear() -> bool:
	return modo == Modo.GUARDA and arrasto.is_empty() and fusao.is_empty() and resumo.is_empty() and not ajuda_aberta and not avisos_aberto and not menus.ativo() and not menus.em_transicao() and (oficina == null or not oficina.aberta) and (fichario == null or not fichario.aberto())

func _montar_nome_edit() -> void:
	nome_edit = LineEdit.new()
	nome_edit.visible = false
	nome_edit.max_length = NOME_MAX
	nome_edit.context_menu_enabled = false
	nome_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome_edit.add_theme_font_size_override("font_size", 28)
	nome_edit.add_theme_color_override("font_color", COR_TINTA_ESC)
	nome_edit.add_theme_color_override("caret_color", COR_TINTA_ESC)
	nome_edit.add_theme_color_override("selection_color", Color(0.85, 0.4, 0.08, 0.95))
	nome_edit.add_theme_color_override("font_selected_color", Color(1, 1, 1))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.96, 0.78)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.85, 0.6, 0.15)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	nome_edit.add_theme_stylebox_override("normal", sb)
	nome_edit.add_theme_stylebox_override("focus", sb)
	nome_edit.text_submitted.connect(func(_t: String) -> void: _confirmar_nome())
	add_child(nome_edit)

func _iniciar_nome(i: int) -> void:
	if i < 0 or i >= estado.bonecos.size():
		return
	nome_idx = i
	nome_aviso = ""
	nome_aviso_t = 0.0
	var r: Rect2 = rect_ficha(i)
	nome_edit.position = Vector2(r.position.x + 2.0, r.position.y + 2.0)
	nome_edit.size = Vector2(r.size.x - 4.0, 28.0)
	nome_edit.text = estado.bonecos[i].nome
	nome_edit.visible = true
	nome_edit.grab_focus()
	nome_edit.select_all()
	Som.tocar("abrir")

## Texto limpo do nome: sem espaços sobrando.
static func _nome_limpo(txt: String) -> String:
	var partes: PackedStringArray = txt.strip_edges().split(" ", false)
	return " ".join(partes)

## Motivo de o nome não servir ("" se serve).
func _nome_invalido(txt: String, i: int) -> String:
	if txt.is_empty():
		return Idioma.t("Escreva um nome.")
	for j in estado.bonecos.size():
		if j != i and estado.bonecos[j].nome.to_lower() == txt.to_lower():
			return Idioma.t("Nome já em uso.")
	return ""

func _confirmar_nome() -> void:
	if nome_idx < 0:
		return
	var txt: String = _nome_limpo(nome_edit.text)
	var motivo: String = _nome_invalido(txt, nome_idx)
	if motivo != "":
		nome_aviso = motivo
		nome_aviso_t = 2.5
		Som.tocar("negado")
		nome_edit.grab_focus()
		return
	var b: Boneco = estado.bonecos[nome_idx]
	var mudou: bool = b.nome != txt
	b.nome = txt
	_fechar_nome()
	if mudou:
		estado.salvar()
		Som.tocar("clique", 1.1)
		_toast(Idioma.t("O gato agora se chama %s.") % txt)

func _cancelar_nome() -> void:
	if nome_idx < 0:
		return
	_fechar_nome()
	Som.tocar("fechar")

func _fechar_nome() -> void:
	nome_idx = -1
	nome_aviso = ""
	nome_edit.release_focus()
	nome_edit.visible = false

## Clique fora da caixa: guarda se o nome serve, senão volta ao que era.
func _fim_nome_por_clique() -> void:
	if nome_edit.get_global_rect().has_point(mouse):
		return
	var txt: String = _nome_limpo(nome_edit.text)
	if _nome_invalido(txt, nome_idx) == "":
		_confirmar_nome()
	else:
		_cancelar_nome()

func _ficha_em(p: Vector2) -> int:
	for i in estado.bonecos.size():
		if rect_ficha(i).has_point(p):
			return i
	return -1

## Linhas da ficha em números do gato (como ele entra na luta agora), para uma caixa de dica.
## `destaque`: atributo de treino cujas linhas ficam em dourado (-1 = nenhum).
func _itens_ficha(b: Boneco, destaque: int = -1) -> Array:
	var u: Unidade = Simulacao.ficha_de(estado, b)
	var de: Array = [[Idioma.t("Vida")], [Idioma.t("Dano por golpe"), Idioma.t("Dano por segundo")], [Idioma.t("Golpes por segundo"), Idioma.t("Velocidade"), Idioma.t("Dano por segundo")]]
	var itens: Array = []
	for par in Simulacao.ficha_linhas(u):
		var forte: bool = destaque >= 0 and (de[destaque] as Array).has(par[0])
		itens.append(["t", "%s: %s" % [par[0], par[1]], 16 if itens.size() < 4 else 13, Desenho.DOURADO if forte else Color(1, 1, 1)])
	return itens

## Ficha completa do gato: nível, linha, postura e todos os números.
func _dica_ficha(i: int) -> void:
	var b: Boneco = estado.bonecos[i]
	var itens: Array = [
		["t", b.nome, 22, Desenho.DOURADO],
		["t", Idioma.t("Nível %d  ·  %s  ·  %s") % [b.nivel, Idioma.t(Boneco.LINHA_NOMES[b.linha]), Idioma.t(Boneco.POSTURA_NOMES[b.postura_atual()])], 13, Color(1, 1, 1, 0.75)],
		["sep"],
	]
	itens.append_array(_itens_ficha(b))
	var rec: float = estado.mult_recupera(b)
	if rec > 1.0 and b.nivel < Balanco.BONECO_NIVEL_MAX:
		itens.append(["t", Idioma.t("Alcançando o time: XP x%s") % String.num(rec, 2).trim_suffix("0").trim_suffix("."), 14, Color(0.6, 0.9, 1.0)])
	itens.append(["sep"])
	itens.append(["t", Idioma.t("Duplo clique no nome (ou no lápis) troca o nome."), 12, Color(1, 1, 1, 0.55)])
	itens.append(["t", Idioma.t("Heranças (%d de %d)") % [b.incorporacoes(), Balanco.BONECO_NIVEL_MAX / Balanco.HERANCA_NIVEIS], 16, Color(0.8, 0.7, 1.0)])
	for h in b.herancas:
		itens.append(["m", "%s: %s; %s" % [Simulacao.heranca_nome(h, b.grau_de(h)), Idioma.t(Pecas.PODER_DICA[h]), _efeito_heranca(b.grau_de(h))], 13, Color(0.9, 0.85, 1.0), Color(0.72, 0.56, 1.0), Vector2i(h, 0)])
	if b.herancas_pendentes() > 0:
		var fc: int = b.fantasia_completa()
		if fc >= 0:
			itens.append(["m", Idioma.t("Pronto para incorporar %s: clique em \"Herança pronta!\".") % Simulacao.heranca_nome(fc), 13, Color(0.7, 1.0, 0.7), Desenho.DOURADO, Vector2i(fc, 1)])
		else:
			itens.append(["t", Idioma.t("Pronto para incorporar um poder: vista uma fantasia completa."), 13, Color(1.0, 0.8, 0.5)])
	elif b.herancas.size() < Balanco.BONECO_NIVEL_MAX / Balanco.HERANCA_NIVEIS:
		itens.append(["t", Idioma.t("No nível %d ele incorpora o poder da fantasia completa que estiver vestindo e passa a soltá-lo sozinho.") % ((b.herancas.size() + 1) * Balanco.HERANCA_NIVEIS), 13, Color(1, 1, 1, 0.6)])
	itens.append(["sep"])
	itens.append(["t", Idioma.t("Números com as roupas, a fantasia e o treino de agora. A posição e a ordem (avançar, segurar, recuar) se escolhem na preparação da luta."), 13, Color(1, 1, 1, 0.6)])
	_caixa_dica(itens, 300.0, Desenho.DOURADO, Desenho.DOURADO, mouse, Vector2(16, 22))

## Dica de um botão de atributo do time.
func _dica_atributo(ai: Vector2i) -> void:
	var b: Boneco = estado.bonecos[ai.x]
	var itens: Array = [
		["t", (Idioma.t("%s: %d ponto") if b.atr[ai.y] == 1 else Idioma.t("%s: %d pontos")) % [Idioma.t(Balanco.ATR_NOMES[ai.y]), b.atr[ai.y]], 22, Desenho.DOURADO],
		["t", Idioma.t("Cada ponto dá %s") % _atr_efeito(ai.y), 16, Color(1, 1, 1)],
		["sep"],
		["t", Idioma.t("Clique para gastar um ponto de treino.") if b.pontos > 0 else Idioma.t("Sem pontos de treino: cada nível novo dá um."), 13, Color(0.7, 1.0, 0.7) if b.pontos > 0 else Color(1, 1, 1, 0.6)],
		["sep"],
		["t", Idioma.t("%s agora, em números:") % b.nome, 13, Color(1, 0.9, 0.5)],
	]
	itens.append_array(_itens_ficha(b, ai.y))
	_caixa_dica(itens, 300.0, Desenho.DOURADO, Desenho.DOURADO, mouse, Vector2(16, 22))

## Dica de um cartão da aba Fantasias: bônus, poder e a situação de cada peça.
func _dica_fantasia(c: int) -> void:
	var bi: int = _alvo_vestir()
	var st: Dictionary = _situacao_fantasia(c, bi)
	var cor: Color = Pecas.CONJUNTO_COR[c]
	var verde := Color(0.7, 1.0, 0.7)
	var laranja := Color(1.0, 0.75, 0.4)
	var cinza := Color(1, 1, 1, 0.55)
	var disp: int = int(st["gato"]) + int(st["guarda"])
	var nome_g: String = estado.bonecos[bi].nome if bi >= 0 else Idioma.t("o gato")
	var acao: String
	var cor_acao: Color
	if int(st["gato"]) >= Pecas.SLOTS:
		acao = Idioma.t("%s já veste a fantasia inteira.") % nome_g
		cor_acao = verde
	elif int(st["guarda"]) == 0:
		acao = Idioma.t("Nada livre para vestir em %s.") % nome_g
		cor_acao = cinza
	elif disp >= Pecas.SLOTS:
		acao = Idioma.t("Clique: veste as 4 peças em %s.") % nome_g
		cor_acao = verde
	else:
		acao = Idioma.t("Clique: veste %d de 4 peças em %s.") % [disp, nome_g]
		cor_acao = Color(1.0, 0.9, 0.5)
	var itens: Array = [
		["t", Idioma.t(Pecas.CONJUNTO_NOME[c]), 22, cor.lightened(0.35)],
		["t", acao, 13, cor_acao],
		["sep"],
		["t", Idioma.t("2 a 3 peças: %s") % Pecas.conjunto_bonus(c, 1), 13, cor.lightened(0.4)],
		["t", Idioma.t("4 peças: %s") % Pecas.conjunto_bonus(c, 2), 13, cor.lightened(0.4)],
		["t", Idioma.t("Poder: %s, %s (a cada %d s)") % [Idioma.t(Pecas.PODER_NOME[c]), Idioma.t(Pecas.PODER_DICA[c]), Balanco.poder_recarga(c)], 13, Color(1.0, 0.9, 0.5)],
		["sep"],
	]
	for i in Pecas.SLOTS:
		var nome: String = "%s (%s)" % [Idioma.t(Pecas.NOME[int(st["tipos"][i])]), Idioma.t(Pecas.SLOT_NOME[Pecas.SLOT[int(st["tipos"][i])]])]
		match int(st["onde"][i]):
			FS_GATO:
				itens.append(["m", Idioma.t("%s: já com %s") % [nome, nome_g], 13, verde, Color(0.4, 0.9, 0.5), int(st["tipos"][i])])
			FS_GUARDA:
				itens.append(["m", Idioma.t("%s: no guarda-roupa") % nome, 13, Color(0.85, 0.95, 1.0), Color(0.5, 0.75, 1.0), int(st["tipos"][i])])
			FS_OUTRO:
				itens.append(["m", Idioma.t("%s: com %s") % [nome, estado.bonecos[int(st["dono"][i])].nome], 13, laranja, Color(1.0, 0.6, 0.25), int(st["tipos"][i])])
			_:
				itens.append(["m", Idioma.t("%s: você ainda não tem") % nome, 13, cinza, Color(0.45, 0.45, 0.5), int(st["tipos"][i])])
	if int(st["outro"]) > 0:
		itens.append(["t", Idioma.t("Peças de outro gato não saem sozinhas: tire do gato primeiro."), 13, cinza])
	_caixa_dica(itens, 340.0, cor, Desenho.DOURADO, mouse, Vector2(18, -92))

## Dica da caixa de fantasia sob o gato: bônus, poder e o clique que filtra a lista.
func _dica_caixa_fantasia(c: int, bi: int) -> void:
	var cor: Color = Pecas.CONJUNTO_COR[c]
	var n: int = Pecas.contar_conjuntos(estado.bonecos[bi].pecas)[c]
	var itens: Array = [
		["t", "%s  %d/%d" % [Idioma.t(Pecas.CONJUNTO_NOME[c]), n, Pecas.SLOTS], 22, cor.lightened(0.35)],
		["t", Idioma.t("2 a 3 peças: %s") % Pecas.conjunto_bonus(c, 1), 13, Color(1, 1, 1) if n < Pecas.SLOTS else Color(1, 1, 1, 0.6)],
		["t", Idioma.t("4 peças: %s") % Pecas.conjunto_bonus(c, 2), 13, Color(1, 1, 1) if n >= Pecas.SLOTS else Color(1, 1, 1, 0.6)],
		["t", Idioma.t("Poder: %s, %s (a cada %d s)") % [Idioma.t(Pecas.PODER_NOME[c]), Idioma.t(Pecas.PODER_DICA[c]), Balanco.poder_recarga(c)], 13, Color(1.0, 0.9, 0.5)],
		["sep"],
		["t", Idioma.t("Clique: mostra só as peças desta fantasia."), 13, Color(1, 1, 1, 0.6)],
	]
	_caixa_dica(itens, 320.0, cor, Desenho.DOURADO, mouse, Vector2(18, 10))

## Frase do efeito de uma herança no grau dado.
func _efeito_heranca(grau: int) -> String:
	return Idioma.t("solta sozinho a cada %d s, com %d%% da força do grau I") % [int(Balanco.heranca_intervalo(grau)), int(round(Balanco.heranca_mult(grau) * 100.0))] if grau > 1 else Balanco.heranca_efeito(0)

## Dica de uma herança já incorporada.
func _dica_heranca_feita(bi: int, h: int) -> void:
	var itens: Array = [
		["m", Idioma.t("Herança: %s") % Simulacao.heranca_nome_curto(h, estado.bonecos[bi].grau_de(h)), 22, Color(0.8, 0.7, 1.0), Color(0.72, 0.56, 1.0), Vector2i(h, 0)],
		["t", "%s; %s" % [Idioma.t(Pecas.PODER_DICA[h]), _efeito_heranca(estado.bonecos[bi].grau_de(h))], 13, Color(1, 1, 1)],
		["t", Idioma.t("Grau %s de %s. A mesma fantasia incorporada de novo sobe o grau.") % [Balanco.heranca_grau_romano(estado.bonecos[bi].grau_de(h)), Balanco.heranca_grau_romano(Balanco.HERANCA_GRAU_MAX)], 13, Color(0.85, 0.78, 1.0)],
		["t", Idioma.t("%s solta sozinho na luta, com qualquer roupa.") % estado.bonecos[bi].nome, 13, Color(1, 1, 1, 0.6)],
	]
	_caixa_dica(itens, 320.0, Color(0.72, 0.56, 1.0), Color(0.72, 0.56, 1.0), mouse, Vector2(18, 10))

## Dica da caixa "Herança pronta!".
func _dica_heranca_pronta(bi: int) -> void:
	var b: Boneco = estado.bonecos[bi]
	var fc: int = b.fantasia_completa()
	var itens: Array = [["m", Idioma.t("Herança pronta!"), 22, Desenho.DOURADO, Desenho.DOURADO, Vector2i(fc, 1)] if fc >= 0 else ["t", Idioma.t("Herança pronta!"), 22, Desenho.DOURADO]]
	if fc >= 0:
		itens.append(["t", Idioma.t("Clique para incorporar %s: %s solta sozinho na luta, para sempre.") % [_txt_incorporar(b, fc), b.nome], 13, Color(0.7, 1.0, 0.7)])
	else:
		itens.append(["t", Idioma.t("Vista uma fantasia completa (4 peças) em %s e clique aqui.") % b.nome, 13, Color(1.0, 0.8, 0.5)])
	_caixa_dica(itens, 320.0, Desenho.DOURADO, Desenho.DOURADO, mouse, Vector2(18, 10))

func _dica() -> void:
	if not arrasto.is_empty() or not resumo.is_empty() or ajuda_aberta or avisos_aberto:
		return
	var ai: Vector2i = _atr_em(mouse)
	if ai.x >= 0:
		_dica_atributo(ai)
		return
	if not fusao.is_empty():
		return
	var fi: int = _ficha_em(mouse)
	if fi >= 0:
		_dica_ficha(fi)
		return
	var ri: int = _reforcar_em(mouse)
	if ri >= 0:
		var br: Boneco = estado.bonecos[ri]
		var sr: Dictionary = _estado_reforcar_tudo(br)
		var it_r: Array = [["t", Idioma.t("Raridade da fantasia inteira"), 22, Color(0.85, 0.75, 1.0)], ["t", Idioma.t("Sobe uma raridade em cada peça que %s veste (de %d a %d troféus por peça, conforme a raridade).") % [br.nome, Balanco.REFORCO_CUSTO[0], Balanco.REFORCO_CUSTO[-1]], 13, Color(1, 1, 1)], ["sep"]]
		it_r.append(["t", Idioma.t("Custo total: %d troféus (você tem %d).") % [sr["custo"], estado.trofeus] if sr["ok"] else str(sr["motivo"]), 13, Color(0.7, 1.0, 0.7) if sr["ok"] else Color(1.0, 0.6, 0.55)])
		_caixa_dica(it_r, 300.0, Color(0.8, 0.7, 1.0), Color(0.8, 0.7, 1.0), mouse, Vector2(16, 24))
		return
	var pi: int = _promover_em(mouse)
	if pi >= 0:
		_dica_promover_tudo(pi)
		return
	var fc: int = _cartao_fant_em(mouse)
	if fc >= 0:
		_dica_fantasia(fc)
		return
	if arrasto.is_empty() and BIGORNA.has_point(mouse):
		_caixa_dica([["t", Idioma.t("Promover"), 22, Desenho.DOURADO], ["t", Idioma.t("Arraste uma peça: carretel sobe o nível (blocos), estrela sobe a raridade (troféus)."), 13, Color(1, 1, 1)], ["t", Idioma.t("Peça sobre peça igual: funde, de graça."), 13, Color(0.7, 1.0, 0.7)]], 300.0, Desenho.DOURADO, Desenho.DOURADO, mouse, Vector2(-320, 10))
		return
	if arrasto.is_empty() and PREVIA.has_point(mouse) and estado.chefe.is_empty():
		_caixa_dica([["t", Idioma.t(Fases.grupo_nome(estado.lugar())), 22, Color(1, 0.88, 0.8)], ["t", Idioma.t(Fases.grupo_dica(estado.lugar())), 13, Color(1, 1, 1)]], 300.0, Desenho.COR_INIMIGO, Desenho.DOURADO, mouse, Vector2(-320, 10))
		return
	if arrasto.is_empty():
		for fr in _rect_fant:
			if (fr[0] as Rect2).has_point(mouse):
				_dica_caixa_fantasia(int(fr[1]), int(fr[2]))
				return
		for hr in _rect_her_feita:
			if (hr[0] as Rect2).has_point(mouse):
				_dica_heranca_feita(int(hr[1]), int(hr[2]))
				return
		for pr in _rect_heranca:
			if (pr[0] as Rect2).has_point(mouse):
				_dica_heranca_pronta(int(pr[1]))
				return
	var p: Peca = _peca_sob_mouse()
	if p == null:
		return
	var cj: int = p.conjunto()
	var cor_cj: Color = Pecas.CONJUNTO_COR[cj]
	var cor_r: Color = Pecas.cor_rar(p.raridade)
	var verde := Color(0.7, 1.0, 0.7)
	var cinza := Color(1, 1, 1, 0.55)
	# essencial: nome, raridade, o que faz, a fantasia do gato escolhido e uma linha de ação
	var itens: Array = [
		["t", Idioma.t(Pecas.NOME[p.tipo]) + (Idioma.t("  nível %d") % p.nivel if p.nivel > 0 else ""), 22, cor_r.lightened(0.15) if p.raridade > 0 else Desenho.DOURADO],
		["t", "%s  ·  %s" % [Idioma.t(Pecas.RARIDADE_NOME[p.raridade]), Idioma.t(Pecas.SLOT_NOME[p.slot()])], 13, cor_r],
		["t", Idioma.t(Pecas.dica(p.tipo)), 16, Color(1, 1, 1)],
	]
	var fant: String = Idioma.t("Fantasia: %s") % Idioma.t(Pecas.CONJUNTO_NOME[cj])
	if sel >= 0 and sel < estado.bonecos.size():
		var ef: Vector2i = _efeito_conjunto(estado.bonecos[sel], p)
		fant += "  %d/%d" % [ef.x, Pecas.SLOTS]
		if ef.y > ef.x and estado.bonecos[sel].pecas[p.slot()] != p:
			fant += " → %d/%d" % [ef.y, Pecas.SLOTS]
	itens.append(["t", fant, 16, cor_cj.lightened(0.25)])
	for m in Pecas.Marca.values():
		var qtd: int = p.contar_marca(m)
		if qtd > 0:
			itens.append(["m", Pecas.marca_linha(m, qtd), 13, Pecas.MARCA_COR[m].lightened(0.3), Pecas.MARCA_COR[m], "marca%d" % int(m)])
	# uma linha de ação: nível, senão fundir, senão o motivo
	var par: int = 0
	for q in estado.guarda:
		if q != p and q.tipo == p.tipo and estado.pode_fundir(p, q):
			par += 1
	for bq in estado.bonecos:
		var qv: Peca = bq.pecas[p.slot()]
		if qv != null and qv != p and qv.tipo == p.tipo and estado.pode_fundir(p, qv):
			par += 1
	itens.append(["sep"])
	var mn: String = _motivo_nivel(p)
	if mn == "":
		itens.append(["t", Idioma.t("Arraste ao carretel: nível +1 (%d blocos)") % Balanco.custo_promocao(p.nivel), 13, verde])
	elif par > 0:
		itens.append(["t", Idioma.t("Solte sobre outra igual: funde, de graça"), 13, verde])
	elif p.nivel >= Balanco.NIVEL_MAX:
		itens.append(["t", Idioma.t("Nível máximo"), 13, cinza])
	elif mn == Idioma.t("Reserva da torre"):
		itens.append(["t", Idioma.t("A torre guarda %d blocos de reserva") % Balanco.RESERVA_PROMOCAO, 13, cinza])
	else:
		itens.append(["t", Idioma.t("Faltam blocos para o nível (custa %d)") % Balanco.custo_promocao(p.nivel), 13, cinza])
	_caixa_dica(itens, 320.0, cor_cj, cor_r if p.raridade > 0 else Desenho.DOURADO, mouse, Vector2(18, -92))

# ------------------------------------------------------------------ fim de fase
## Intervalo entre duas peças entrando no painel de fim: 0,14 s, encurtando se forem muitas (no máximo ~2,5 s ao todo).
func _fim_gap() -> float:
	return minf(0.14, 2.5 / maxf(1.0, float(mini(fim_pecas.size(), 48))))

## Entrada do painel de fim: o título dá um pop, os textos aparecem em seguida e as peças entram uma a uma,
## cada uma com o som de drop da sua raridade. O botão funciona desde o começo (ninguém espera a animação).
func _animar_fim(delta: float) -> void:
	fim_t += delta
	# título: escondido 0,1 s, pop grande, encolhe um pouco e assenta (degraus, sem easing liso)
	fim_titulo.pivot_offset = fim_titulo.size * 0.5
	var esc_t: float = 1.0
	if fim_t < 0.1:
		esc_t = 0.0
	elif fim_t < 0.18:
		esc_t = 1.3
	elif fim_t < 0.26:
		esc_t = 0.9
	elif fim_t < 0.32:
		esc_t = 1.05
	fim_titulo.scale = Vector2(esc_t, esc_t)
	if fim_t >= 0.1 and fim_t - delta < 0.1:
		Som.tocar("trofeu" if fim_vitoria else "bloco_perdido", 1.1 if fim_vitoria else 0.8)
	# textos: aparecem em sequência, meio apagados por um instante antes de firmar
	var ordem: Array = [fim_sub, fim_time, fim_torre, fim_info]
	for i in ordem.size():
		var l: Label = ordem[i]
		var ti: float = fim_t - 0.3 - i * 0.1
		l.modulate.a = 0.0 if ti < 0.0 else (0.5 if ti < 0.06 else 1.0)
	# peças: som na hora em que cada uma entra (no máximo as 48 que aparecem)
	var gap: float = _fim_gap()
	while fim_som_n < mini(fim_pecas.size(), 48) and fim_t >= FIM_PECA_0 + fim_som_n * gap:
		var rar: int = clampi(fim_pecas[fim_som_n].raridade, 0, 4)
		Som.tocar(["drop", "drop_raro", "drop_raro", "drop_lendario", "drop_lendario"][rar], 1.0 + 0.03 * mini(fim_som_n, 10), 0.03, -4.0)
		fim_som_n += 1

## Time em cima da moldura do painel de fim: na vitória os gatos pulam (cada um no seu tempo); na derrota
## dormem deitados, com um "z" cada, e blocos da torre caídos entre eles. Só quando sobra espaço acima do painel.
func _fim_gatos() -> void:
	if fim_invasao and fim_vitoria:
		return
	var topo: float = fim_rect.position.y
	if topo < 64.0 or estado == null:
		return
	var n: int = estado.bonecos.size()
	if n == 0:
		return
	var esp: float = minf(150.0, (fim_rect.size.x - 160.0) / maxf(1.0, n - 1.0))
	var x0: float = 640.0 - esp * (n - 1) * 0.5
	var y_pe: float = topo + 10.0
	var entra: float = clampf((fim_t - 0.2) / 0.3, 0.0, 1.0)   # sobem de trás da moldura
	if entra <= 0.0:
		return
	if not fim_vitoria:
		# blocos da torre caídos no meio do time (um em pé, outro deitado, um terceiro meio de lado)
		for k in mini(n - 1, 4):
			var xb: float = floorf((x0 + esp * (k + 0.5)) / 4.0) * 4.0
			var cor_b: Color = Desenho.cor_tijolo(k * 5 + 1)
			if k % 2 == 0:
				TorrePx._bloco(self, Vector2(xb - 20.0, y_pe - 20.0), cor_b, "", 0, true)
			else:
				TorrePx._bloco(self, Vector2(xb - 24.0, y_pe - 20.0), cor_b, "", 0, true)
				TorrePx._bloco(self, Vector2(xb - 4.0, y_pe - 40.0), Desenho.cor_tijolo(k * 3 + 2), "", 0, true)
	for i in n:
		var bn: Boneco = estado.bonecos[i]
		var x: float = x0 + esp * i
		var dy: float = (1.0 - entra) * 40.0
		if fim_vitoria:
			# pulo em parábola, cada gato defasado; no chão um instante de "agachado"
			var fase: float = fposmod(fim_t * 1.6 + i * 0.37, 1.0)
			var alt: float = 0.0 if fase > 0.7 else sin(fase / 0.7 * PI) * 34.0
			dy -= floorf(alt / PX) * PX
			Desenho.boneco(self, Vector2(x, y_pe + dy), 0.8, 1.0 if i % 2 == 0 else -1.0, 0, bn.pecas, 0.0, t * 3.0 + i, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, i, false)
			if fase > 0.72 and fase < 0.8:
				V.brilho(self, Vector2(x + 26.0, y_pe - 46.0), 5.0, Desenho.DOURADO, Color(0.3, 0.18, 0.0))
		else:
			Desenho.boneco(self, Vector2(x, y_pe + dy), 0.8, 1.0, 0, bn.pecas, 0.0, 0.0, false, 0.0, 0.9, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, i, true)
			var wz: float = fposmod(t * 0.5 + i * 0.29, 1.0)
			if sin(wz * PI) > 0.25 and entra >= 1.0:
				V.zzz(self, Vector2(x + 22.0 + wz * 10.0, y_pe - 40.0 - wz * 26.0), 2.0 if sin(wz * PI) > 0.7 else 1.0, Color(0.8, 0.9, 1.0))

func _fim_icones() -> void:
	var n: int = fim_pecas.size()
	if n == 0:
		return
	var por_linha: int = 16
	var maximo: int = por_linha * 3
	var mostrar: int = mini(n, maximo)
	var passo: float = 56.0
	var x0: float = 640.0 - (mini(mostrar, por_linha) * passo) / 2.0 + 3.0
	var gap: float = _fim_gap()
	for i in mostrar:
		var r := Rect2(x0 + (i % por_linha) * passo, fim_ic_y + (i / por_linha) * passo, 50.0, 50.0)
		# entra uma a uma: cai de cima em degraus de PX, passa um pouco do lugar e assenta
		var ti: float = fim_t - FIM_PECA_0 - i * gap
		if ti < 0.0:
			continue
		var k: float = clampf(ti / 0.16, 0.0, 1.0)
		var dy: float = -floorf(30.0 * (1.0 - k) * (1.0 - k) / PX) * PX
		if ti >= 0.16 and ti < 0.24:
			dy = PX   # quique de 1 pixel ao assentar
		_ladrilho(Rect2(r.position + Vector2(0, dy), r.size), fim_pecas[i])
		if ti < 0.1:
			draw_rect(Rect2(r.position + Vector2(0, dy), r.size), Color(1, 1, 0.9, 0.5))
	if n > maximo:
		Desenho.texto(self, "+%d" % (n - maximo), Vector2(640, fim_ic_y + 3 * passo + 18.0), 22, Color(1, 0.92, 0.7), 0.0)

# ------------------------------------------------------------------ mapa da casa
func rect_cartao(f: int) -> Rect2:
	return Rect2(48.0 + (f - 1) * (CARTAO_W + 16.0), 104.0, CARTAO_W, CARTAO_H)

func _cartao_em(p: Vector2) -> int:
	for f in range(1, Fases.NOME.size() + 1):
		if rect_cartao(f).has_point(p):
			return f
	return -1

## Centro do ícone da k-ésima fantasia que cai no cômodo f.
func _centro_fantasia(f: int, k: int) -> Vector2:
	var r: Rect2 = rect_cartao(f)
	var n: int = Fases.lista_do_lugar(f - 1).size()
	if n > 5:   # listas longas (provisório do 2º ato): duas fileiras
		var por: int = ceili(n / 2.0)
		var nl: int = por if k / por == 0 else n - por
		return Vector2(r.get_center().x - (nl - 1) * 20.0 + (k % por) * 40.0, r.position.y + 400.0 + (k / por) * 36.0)
	return Vector2(r.get_center().x - (n - 1) * 20.0 + k * 40.0, r.position.y + 414.0)

func _fundo_mapa() -> void:
	var c1: Color = Color(0.17, 0.12, 0.2)
	var c2: Color = Color(0.3, 0.2, 0.28)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(0, 720)]), PackedColorArray([c1, c1, c2, c2]))
	for row in 8:
		for col in 12:
			var q: Vector2 = Vector2(40.0 + col * 120.0 + (row % 2) * 60.0, 30.0 + row * 90.0)
			draw_colored_polygon(PackedVector2Array([q + Vector2(0, -6), q + Vector2(5, 0), q + Vector2(0, 6), q + Vector2(-5, 0)]), Color(0.95, 0.75, 0.5, 0.07))
	_tabua_rodape()

## Rodapé: tábua larga de madeira onde o time fica (usada pelos dois mapas).
func _tabua_rodape() -> void:
	draw_rect(Rect2(0, 600, 1280, 120), Color(0.2, 0.12, 0.1))
	for k in 12:
		draw_rect(Rect2(0, 612 + k * 10.0, 1280, 1.5), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(0, 600, 1280, 5), Color(0.78, 0.6, 0.4))
	draw_rect(Rect2(0, 605, 1280, 3), Color(0.35, 0.22, 0.14))

func _mapa() -> void:
	if MAPA_EM_CORTE:
		mapa_casa.desenhar()
		return
	_fundo_mapa()
	Desenho.texto(self, Idioma.t("Mapa da casa"), Vector2(0, 56), 34, Color(1, 0.92, 0.75), 1280.0, 6)
	if estado.campanha_vencida():
		Desenho.texto(self, Idioma.t("Campanha vencida! Jogue qualquer cômodo de novo para caçar peças."), Vector2(0, 86), 16, Desenho.DOURADO, 1280.0, 4)
	else:
		Desenho.texto(self, Idioma.t("Escolha um cômodo: cada um tem %d ondas e um chefe.") % Balanco.ONDAS_TOTAIS, Vector2(0, 86), 16, Color(1, 1, 1, 0.8), 1280.0, 4)
	for f in range(1, Fases.NOME.size() + 1):
		_cartao(f)
		if f < Fases.TOTAL:
			var r: Rect2 = rect_cartao(f)
			var m: Vector2 = Vector2(r.end.x + 8.0, r.position.y + 36.0)
			var ca: Color = Color(1, 0.9, 0.7, 0.85 if f < estado.fase_liberada else 0.25)
			draw_colored_polygon(PackedVector2Array([m + Vector2(-4, -8), m + Vector2(5, 0), m + Vector2(-4, 8)]), ca)
	_rodape_mapa()
	_dica_mapa()

func _rodape_mapa() -> void:
	if estado.ato_atual() > 1:
		Desenho.texto(self, Idioma.t("%s: %d/%d lugares vencidos") % [Idioma.t(Balanco.ATO_NOME[estado.ato_atual() - 1]), estado.vencidos_no_ato(estado.ato_atual()), Fases.TOTAL], Vector2(48, 640), 16, Color(1, 0.92, 0.75), -1.0, 4)
	else:
		Desenho.texto(self, Idioma.t("Cômodos vencidos: %d/%d") % [estado.fases_vencidas, Fases.TOTAL], Vector2(48, 640), 16, Color(1, 0.92, 0.75), -1.0, 4)
	# o time, vestido
	Desenho.texto(self, Idioma.t("Seu time"), Vector2(430, 636), 19, Color(1, 1, 1, 0.6), -1.0, 3)
	for i in Balanco.MAX_BONECOS:
		var pos := Vector2(430.0 + i * 98.0, 696.0)
		_ellipse_sombra(pos + Vector2(0, 2), 26.0, 6.0, Color(0, 0, 0, 0.35))
		if i < estado.bonecos.size():
			var b: Boneco = estado.bonecos[i]
			Desenho.boneco(self, pos, 0.66, 1.0, 0, b.pecas, 0.0, t * 3.0 + i, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, i, false)
			var rot_b: String = Idioma.t("%s · Nv %d") % [b.nome, b.nivel]
			if UIComum.FONTE.get_string_size(rot_b, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x > 96.0:
				rot_b = "%s · %d" % [b.nome, b.nivel]
			Desenho.texto(self, rot_b, Vector2(pos.x - 48, 716), 19, Color(1, 0.94, 0.8), 96.0, 3)
			if b.pontos > 0:
				_estrela4(pos + Vector2(26, -62 + sin(t * 5.0 + i) * 3.0), 8.0, Color(1.0, 0.9, 0.4))
		else:
			Desenho.boneco(self, pos, 0.66, 1.0, 0, [null, null, null, null], 0.0, 0.0, false, 0.0, 0.14, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, i, false)
			Desenho.texto(self, "?", Vector2(pos.x - 48, 716), 19, Color(1, 1, 1, 0.3), 96.0, 2)
	_texto_dir(Idioma.t("Guarda-roupa: %d peças") % estado.guarda.size(), 1236.0, 640.0, 16, Color(1, 1, 1, 0.8), 4)
	var pt: int = _pontos_totais()
	if pt > 0:
		var r := Rect2(940, 656, 296, 36)
		_botao_arte(r, Color(1.0, 0.8 + 0.12 * (0.5 + 0.5 * sin(t * 5.0)), 0.35))
		_icone_gui(ICO_RAIO, r.position + Vector2(24, 18), 0.5)
		Desenho.texto(self, Idioma.t("%d ponto de treino por gastar") % pt if pt == 1 else Idioma.t("%d pontos de treino por gastar") % pt, Vector2(r.position.x + 40, r.position.y + 24), 16, COR_TINTA_ESC, r.size.x - 48.0)
	elif estado.bonecos.size() < Balanco.MAX_BONECOS:
		_texto_dir(Idioma.t("Cada lugar vencido na casa traz um gato novo") if estado.ato_atual() <= 1 else Idioma.t("O time chega a %d gatos vencendo lugares da casa") % Balanco.MAX_BONECOS, 1236.0, 690.0, 13, Color(0.75, 0.9, 1.0), 3)
	var rod: Array[String] = [Idioma.t("Esc ou II: menu de pausa"), Idioma.t("T: oficina da torre")]
	if estado.campanha_vencida() and mapa_casa != null:
		var dst: int = mapa_casa.destaque()
		var inv_ok: bool = mapa_casa.invasao_fora_liberada(dst) if mapa_casa.vista_fora() else (dst >= 1 and dst <= estado.fase_liberada)
		if inv_ok:
			rod.append(Idioma.t("I: invasão sem fim"))
		if estado.ato_atual() > 1:
			rod.append(Idioma.t("V: casa, lá fora ou ruas") if estado.ato_atual() > 2 else Idioma.t("V: casa ou lado de fora"))
	for k in rod.size():
		Desenho.texto(self, rod[k], Vector2(48, 662.0 + 18.0 * k), 19, Color(1, 1, 1, 0.5), -1.0, 3)
	if confirma_nova > 0.0:
		Desenho.texto(self, Idioma.t("Isso apaga o progresso e as peças."), Vector2(48, 724), 13, Color(1, 0.55, 0.5), -1.0, 3)

func _cartao(f: int) -> void:
	var r: Rect2 = rect_cartao(f)
	var fi: int = f - 1
	var bloqueada: bool = f > estado.fase_liberada
	var vencida: bool = f <= estado.fases_vencidas
	var proxima: bool = not bloqueada and not vencida and f == estado.fase_liberada
	var sob: bool = not bloqueada and r.has_point(mouse)
	var al: float = 0.45 if bloqueada else 1.0
	var tom: Color = COR_COMODO[fi]
	var cx: float = r.get_center().x
	# corpo do cartão
	var fundo: Color = tom.darkened(0.72).lerp(Color(0.1, 0.08, 0.12), 0.3)
	if sob:
		fundo = fundo.lightened(0.12)
	var moldura: Color = Color(0.55, 0.5, 0.5) if bloqueada else Color.WHITE
	if proxima:
		moldura = Color(1.0, 0.9 + 0.1 * sin(t * 4.0), 0.55 + 0.2 * sin(t * 4.0))
	elif vencida:
		moldura = Color(0.75, 1.0, 0.8)
	elif sob:
		moldura = Color(1.2, 1.2, 1.2)
	_painel(r, _com_alfa(fundo, 0.97), 0.5, moldura)
	draw_rect(Rect2(r.position.x + 12, r.position.y + 12, r.size.x - 24, 50), _com_alfa(tom.darkened(0.15), al))
	draw_rect(Rect2(r.position.x + 12, r.position.y + 12, r.size.x - 24, 4), _com_alfa(tom.lightened(0.3), al))
	Desenho.texto(self, Idioma.t(Fases.nome_do_lugar(fi)), Vector2(r.position.x, r.position.y + 49), 34, _com_alfa(Color(1, 1, 1), al), r.size.x, 6)
	Desenho.texto(self, str(f), Vector2(r.position.x + 20, r.position.y + 32), 16, _com_alfa(Color(1, 1, 1), 0.7 * al), -1.0, 3)
	# estado
	var rc := Rect2(r.position.x + 36, r.position.y + 74, r.size.x - 72, 28)
	if vencida:
		_botao_arte(rc, Color(0.6, 0.95, 0.6))
		var kx: float = rc.position.x + 20
		var ky: float = rc.position.y + 14
		draw_polyline(PackedVector2Array([Vector2(kx - 6, ky), Vector2(kx - 2, ky + 5), Vector2(kx + 7, ky - 6)]), Color(0.1, 0.4, 0.15), 3.0)
		Desenho.texto(self, Idioma.t(VENCIDO_GENERO[fi].capitalize()), Vector2(rc.position.x + 30, rc.position.y + 20), 16, COR_TINTA_ESC, rc.size.x - 30.0)
	elif bloqueada:
		_botao_arte(rc, Color(0.45, 0.45, 0.5))
		var lx: float = rc.position.x + 22
		var ly: float = rc.position.y + 12
		draw_arc(Vector2(lx, ly - 1), 4.5, PI, TAU, 8, Color(0.9, 0.9, 0.95), 2.0)
		draw_rect(Rect2(lx - 6, ly - 1, 12, 9), Color(0.9, 0.9, 0.95))
		Desenho.texto(self, Idioma.t("Bloqueado"), Vector2(rc.position.x + 30, rc.position.y + 20), 16, Color(0.95, 0.95, 1, 0.85), rc.size.x - 30.0)
	else:
		_botao_arte(rc, Color(1.0, 0.82 + 0.1 * sin(t * 4.0), 0.35) if proxima else Color(0.75, 0.85, 1.0))
		Desenho.texto(self, Idioma.t("Próximo") if proxima else Idioma.t("Liberado"), rc.position + Vector2(0, 20), 16, COR_TINTA_ESC, rc.size.x)
	# retratos: um bicho da família e o chefe
	var vazio: Array = [null, null, null, null]
	# o chefe fica atrás, maior; o bicho da família na frente e à esquerda; tudo dentro do cartão
	var yc: float = r.position.y + 222.0
	var yb: float = r.position.y + 250.0
	var xc: float = cx + 22.0
	var xb: float = cx - 50.0
	_ellipse_sombra(Vector2(xc, yc + 3), 40.0, 7.0, Color(0, 0, 0, 0.35 * al))
	_ellipse_sombra(Vector2(xb, yb + 3), 28.0, 6.0, Color(0, 0, 0, 0.35 * al))
	Desenho.boneco(self, Vector2(xc, yc), 1.2, -1.0, 1, _chefes_mapa[fi], 0.0, t * 2.0 + f * 2.0, false, 0.0, al, false, -1, 0.0, 0, false, true, Fases.chefe_base(fi), false, Fases.chefe_base(fi))
	Desenho.boneco(self, Vector2(xb, yb), 0.85, -1.0, 1, vazio, 0.0, t * 2.0 + f, false, 0.0, al, false, -1, 0.0, 0, false, false, fi, false, -1)
	Desenho.texto(self, Idioma.t(Fases.grupo_nome(fi)), Vector2(xb - 45, yb + 17), 13, _com_alfa(Color(1, 0.88, 0.8), 0.85 * al), 90.0, 3)
	Desenho.texto(self, Idioma.t("Chefe"), Vector2(xc + 5, yc + 17), 13, _com_alfa(Color(1, 0.88, 0.8), 0.85 * al), 60.0, 3)
	Desenho.texto(self, Idioma.t(Fases.nome_do_chefe(fi)), Vector2(r.position.x, r.position.y + 296), 22, _com_alfa(Desenho.DOURADO, al), r.size.x, 4)
	var lf: Array[String] = _quebrar(Idioma.t("Fraqueza: %s") % Idioma.t(Fases.fraqueza_do_chefe(fi)), 13, r.size.x - 36.0)
	for k in mini(lf.size(), 2):
		Desenho.texto(self, lf[k], Vector2(r.position.x, r.position.y + 318 + k * 16.0), 13, _com_alfa(Color(0.75, 1.0, 0.8), al), r.size.x)
	# fantasias que caem aqui, só os ícones das cabeças (o nome vai na dica do mouse)
	draw_line(Vector2(r.position.x + 24, r.position.y + 358), Vector2(r.end.x - 24, r.position.y + 358), Color(1, 1, 1, 0.16 * al), 1.0)
	Desenho.texto(self, Idioma.t("Fantasias que caem"), Vector2(r.position.x, r.position.y + 380), 13, _com_alfa(Color(1, 1, 1, 0.65), al), r.size.x)
	var conjs: Array = Fases.lista_do_lugar(fi)
	for k in conjs.size():
		var c: int = conjs[k]
		var pc: Vector2 = _centro_fantasia(f, k)
		var cor_c: Color = Pecas.CONJUNTO_COR[c]
		var sobre_i: bool = not bloqueada and mouse.distance_to(pc) < 18.0
		draw_circle(pc, 18.0, _com_alfa(Color(0.05, 0.03, 0.06), 0.8 * al))
		draw_circle(pc, 16.0, _com_alfa(cor_c.darkened(0.55), al))
		draw_arc(pc, 16.0, 0.0, TAU, 24, _com_alfa(cor_c.lightened(0.15) if not sobre_i else Color.WHITE, al), 2.0)
		Desenho.icone(self, Pecas.CONJUNTO_PECAS[c][0], pc + Vector2(0, 1), 24.0)
	if sob and not bloqueada:
		Desenho.texto(self, Idioma.t("Clique para entrar"), Vector2(r.position.x, r.position.y + 454), 13, Color(1, 0.95, 0.7, 0.9), r.size.x, 3)
	elif bloqueada:
		Desenho.texto(self, Idioma.t("Vença antes: %s") % Idioma.t(Fases.NOME[fi - 1]) if fi > 0 else "", Vector2(r.position.x, r.position.y + 454), 13, Color(1, 1, 1, 0.5), r.size.x, 3)

## Dica do mapa: nome completo da fantasia sob o mouse.
func _dica_mapa() -> void:
	for f in range(1, estado.fase_liberada + 1):
		var conjs: Array = Fases.lista_do_lugar(f - 1)
		for k in conjs.size():
			if mouse.distance_to(_centro_fantasia(f, k)) < 18.0:
				var c: int = conjs[k]
				var cor: Color = Pecas.CONJUNTO_COR[c]
				var itens: Array = [
					["t", Idioma.t(Pecas.CONJUNTO_NOME[c]), 22, cor.lightened(0.3)],
					["t", Idioma.t("2 a 3 peças: %s") % Pecas.conjunto_bonus(c, 1), 13, Color(1, 1, 1, 0.9)],
					["t", Idioma.t("4 peças: %s") % Pecas.conjunto_bonus(c, 2), 13, Color(1, 1, 1, 0.9)],
					["t", Idioma.t("Poder: %s") % Idioma.t(Pecas.PODER_NOME[c]), 13, Color(1.0, 0.9, 0.5)],
				]
				_caixa_dica(itens, 300.0, cor, cor, mouse, Vector2(16, -20))
				return
