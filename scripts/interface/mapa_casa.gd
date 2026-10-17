class_name MapaCasa
extends RefCounted
## Mapa da casa em corte: uma casa de bonecas vista de frente, com um quadro clicável por cômodo.
## Tudo é desenhado com retângulos alinhados a uma grade de 4 pixels de tela (estilo pixel art em blocos).
## Só desenha e decide qual cômodo está destacado; quem entra na fase é o `principal.gd`
## (o clique e o Enter chamam o mesmo caminho do cartão antigo: menus.ir(_escolher_fase.bind(f))).
##
## Mapa do layout (pixels de tela, 1280x720):
##   telhado   : triângulo, ponta (400, 100), base y = 240, de x = 80 a 720
##   Sótão  (4): (316, 148) 168x92  dentro do telhado
##   Quarto (1): (128, 252) 264x100   Sala (2): (408, 252) 264x100   (andar de cima)
##   Cozinha(3): (128, 364) 332x100   vão da escada: (472, 364) 200x100 (decorativo)
##   chão em y = 464; Porão (5): (148, 476) 504x92, abaixo da linha do chão
##   painel lateral: (860, 100) 388x492 ; rodapé do jogo a partir de y = 600

const COMODOS: Array[Rect2] = [
	Rect2(128, 252, 264, 100),
	Rect2(408, 252, 264, 100),
	Rect2(128, 364, 332, 100),
	Rect2(316, 148, 168, 92),
	Rect2(148, 476, 504, 92),
]
const ESCADA := Rect2(472, 364, 200, 100)
const PAINEL := Rect2(860, 100, 388, 492)
const PONTE := Rect2(460, 100, 400, 492)       # faixa entre a casa e o painel: o destaque não some ao atravessá-la
# Botões do painel lateral (só depois de zerar a campanha) e o botão discreto "Final"
const BT_JOGAR := Rect2(1044, 294, 180, 34)
const BT_INVASAO := Rect2(1044, 332, 180, 34)
const BT_FINAL := Rect2(20, 14, 92, 34)
const BT_VISTA := Rect2(120, 14, 112, 34)      # "Ver a casa" / "Ver lá fora": alterna a vista (só no segundo ato)
const BOTAO_VISTA := 4
const RETRATO := Rect2(880, 238, 160, 124)     # área própria do retrato do chefe no painel
const RETRATO_ESCALA := 1.0
const BOTAO_NENHUM := 0
const BOTAO_JOGAR := 1
const BOTAO_INVASAO := 2
const BOTAO_FINAL := 3
const CASA_CX := 400.0
const TOPO_TELHADO := 100.0
const BASE_TELHADO := 240.0
const MEIA_BASE := 320.0
const CHAO_Y := 464.0
const LUA := Vector2(788, 148)
const ICONE_Y := 540.0
const ICONE_X0 := 902.0
const ICONE_PASSO := 44.0
const VAZIO: Array = [null, null, null, null]
## Moldura redonda das "fantasias que caem" (10 x 10 células de 4 px): o = contorno, a = aro, b = miolo, c = brilho.
const PX_MOEDA: Array = ["...oooo...", ".ooaaaaoo.", ".oacbbbao.", "oacbbbbbao", "oabbbbbbao", "oabbbbbbao", "oabbbbbbao", ".oabbbbao.", ".ooaaaaoo.", "...oooo..."]
# Segundo ato: o lado de fora da casa, de noite. Mesma ordem das tabelas de Fases (5..9):
# Quintal, Garagem, Telhado, Rua, Toca. Cada retângulo é a área clicável do lugar.
const FORA: Array[Rect2] = [
	Rect2(28, 344, 216, 176),    # Quintal: à esquerda da casa
	Rect2(616, 384, 216, 136),   # Garagem: anexo à direita
	Rect2(372, 196, 136, 80),    # Telhado: no alto da casa
	Rect2(28, 536, 804, 60),     # Rua: faixa na frente, calçada e asfalto
	Rect2(28, 196, 188, 128),    # Toca: buraco no barranco, no canto
]
const VIZINHOS_FORA: Array = [
	[[], [3, 2], [5], [4]],
	[[3, 1], [], [3], [4]],
	[[5, 1], [2], [], [1, 2]],
	[[], [], [1, 2], []],
	[[], [3], [], [1]],
]
# Terceiro ato: o bairro em corte, de cima. Mesma ordem das tabelas de Fases (10..14):
# Mercadão do Peixe, Ferro-velho, Beco do Fliperama, Arena da Praça, Telhados e Antenas.
const RUAS: Array[Rect2] = [
	Rect2(28, 300, 224, 176),    # Mercadão: à esquerda
	Rect2(596, 240, 240, 140),   # Ferro-velho: ao fundo, à direita
	Rect2(300, 444, 236, 136),   # Beco: no meio, embaixo
	Rect2(300, 240, 236, 148),   # Arena: na praça central
	Rect2(300, 108, 236, 96),    # Telhados: no alto
]
const VIZINHOS_RUAS: Array = [
	[[], [4, 3], [], []],
	[[4, 3], [], [], []],
	[[1], [2], [4], []],
	[[1], [2], [5], [3]],
	[[], [], [], [4]],
]
const FORA_CX := 444.0         # eixo da casa vista de fora; corpo de x = 288 a 600, chão em y = 520
const FORA_TOPO := 140.0       # ponta do telhado
const FORA_BASE := 284.0       # base do telhado
const FORA_MEIA := 192.0       # meia largura da base do telhado
const C_GRAMA_N := Color(0.13, 0.31, 0.17)
const C_GRAMA_N2 := Color(0.2, 0.42, 0.23)
const C_PAREDE_N := Color(0.55, 0.47, 0.4)
const C_VIDRO := Color(1.0, 0.86, 0.45)
# onde cada plaquinha fica dentro da área do lugar (deslocamento a partir do canto; y < 0 = a partir de baixo)
const PLACA_FORA: Array[Vector2] = [Vector2(4, -54), Vector2(4, 4), Vector2(4, 4), Vector2(4, 6), Vector2(4, 4)]
# onde o bicho da família fica (absoluto) e a escala dele
const BICHO_FORA: Array[Vector3] = [Vector3(196, 508, 0.8), Vector3(796, 512, 0.8), Vector3(486, 274, 0.6), Vector3(764, 588, 0.6), Vector3(190, 322, 0.7)]
# Navegação pelo teclado: para cada cômodo, [esquerda, direita, cima, baixo], com candidatos por prioridade.
const VIZINHOS: Array = [
	[[], [2], [4], [3, 5]],
	[[1], [], [4], [3, 5]],
	[[], [2], [1, 4], [5]],
	[[], [], [], [1, 2]],
	[[], [], [3, 1], []],
]

# --- paleta (3 tons por superfície quando cabe)
const C_CONTORNO := Color(0.1, 0.07, 0.09)
const C_CEU: Array[Color] = [Color(0.04, 0.05, 0.14), Color(0.07, 0.08, 0.2), Color(0.11, 0.12, 0.28)]
const C_GRAMA := Color(0.2, 0.45, 0.2)
const C_GRAMA_CL := Color(0.32, 0.62, 0.28)
const C_TERRA := Color(0.32, 0.2, 0.14)
const C_TERRA_ESC := Color(0.23, 0.14, 0.1)
const C_TERRA_CL := Color(0.43, 0.29, 0.2)
const C_EXT := Color(0.76, 0.64, 0.5)
const C_EXT_CL := Color(0.86, 0.76, 0.62)
const C_EXT_ESC := Color(0.6, 0.48, 0.38)
const C_PEDRA := Color(0.46, 0.46, 0.5)
const C_PEDRA_CL := Color(0.58, 0.58, 0.62)
const C_PEDRA_ESC := Color(0.32, 0.32, 0.37)
const C_TEL_A := Color(0.55, 0.2, 0.18)
const C_TEL_B := Color(0.46, 0.15, 0.15)
const C_TEL_CL := Color(0.7, 0.32, 0.26)
const C_TEL_ESC := Color(0.34, 0.1, 0.12)
const C_MADEIRA := Color(0.55, 0.36, 0.22)
const C_MADEIRA_ESC := Color(0.38, 0.23, 0.14)
const C_MADEIRA_CL := Color(0.75, 0.55, 0.35)
const C_OURO := Color(1.0, 0.82, 0.3)
# por cômodo: parede, listra/junta, rodapé, chão, chão (detalhe)
const PAL: Array = [
	[Color(0.66, 0.32, 0.52), Color(0.74, 0.4, 0.6), Color(0.44, 0.2, 0.36), Color(0.6, 0.42, 0.3), Color(0.5, 0.34, 0.24)],
	[Color(0.46, 0.12, 0.2), Color(0.54, 0.17, 0.26), Color(0.3, 0.07, 0.13), Color(0.5, 0.34, 0.22), Color(0.4, 0.26, 0.17)],
	[Color(0.38, 0.7, 0.66), Color(0.46, 0.78, 0.73), Color(0.24, 0.5, 0.48), Color(0.9, 0.9, 0.85), Color(0.5, 0.58, 0.58)],
	[Color(0.24, 0.26, 0.54), Color(0.3, 0.33, 0.62), Color(0.14, 0.15, 0.36), Color(0.44, 0.32, 0.22), Color(0.34, 0.24, 0.17)],
	[Color(0.58, 0.28, 0.2), Color(0.36, 0.16, 0.13), Color(0.3, 0.13, 0.1), Color(0.42, 0.42, 0.45), Color(0.33, 0.33, 0.37)],
]
# x (dentro do cômodo) onde o bicho da família fica, e da lâmpada
const CRIATURA_X: Array[float] = [220.0, 216.0, 144.0, 96.0, 160.0]
const LAMPADA_X: Array[float] = [112.0, 100.0, 216.0, 72.0, 232.0]

## Vista em uso, para as funções estáticas que o `principal.gd` chama (clique e cursor):
## `_fora` = mostra o lado de fora (segundo ato); `_ato` = ato em curso quando o mapa foi aberto.
static var _fora: bool = false
static var _ato: int = 1
static var _ruas: bool = false   # terceiro ato: a vista das ruas (sempre junto com `_fora`)

var p                       # o `principal` (Control); sem tipo para não depender da ordem de carga
var cv: CanvasItem
var foco: int = 0           # cômodo escolhido pelo teclado (0 = nenhum: vale o próximo a jogar)
var usar_mouse: bool = false
var escolhido: int = 0         # cômodo clicado (depois de zerar a campanha): fica escolhido até outro clique
var _ult: int = 0           # último cômodo sob o mouse (fica enquanto o mouse está na ponte/painel)
var _o: Vector2 = Vector2.ZERO   # canto do interior do cômodo em desenho
var _iw: float = 0.0
var _ih: float = 0.0
var _fy: float = 0.0        # y (local) do topo do chão do cômodo
var _anim: Dictionary = {}
var _t_ant: float = 0.0
var _d_ant: int = -1
var _troca_t: float = -9.0
var desenhos: int = 0       # quantas vezes o mapa foi desenhado (os testes conferem)
var _estrelas: Array = []
var _lascas: Array = []     # pontinhos da terra: [Rect2, cor]
var _capim: Array = []
var _tufos: Array = []      # tufos do gramado de fora: [Rect2, cor]

func _init(dono: Object = null) -> void:
	p = dono
	cv = dono as CanvasItem
	for i in 64:
		var x: float = snappedf(8.0 + _ruido(i * 2.0 + 1.0) * 1264.0, 4.0)
		var y: float = snappedf(96.0 + _ruido(i * 2.0 + 2.0) * 360.0, 4.0)
		_estrelas.append([x, y, 1 if i % 6 == 0 else 0, _ruido(i + 40.0) * 6.28])
	var cx: float = 0.0
	while cx < 860.0:
		var cy: float = 476.0
		while cy < 600.0:
			var n: float = _ruido(cx * 0.37 + cy * 1.91)
			if n > 0.86:
				_lascas.append([Rect2(cx, cy, 8, 4), C_TERRA_ESC])
			elif n < 0.07:
				_lascas.append([Rect2(cx, cy, 4, 4), C_TERRA_CL])
			elif n > 0.5 and n < 0.52:
				_lascas.append([Rect2(cx, cy, 8, 8), C_PEDRA_ESC])
			cy += 8.0
		cx += 8.0
	cx = 0.0
	while cx < 860.0:
		if _ruido(cx * 0.71 + 3.0) > 0.55:
			_capim.append(Rect2(cx, 460, 4, 4))
		cx += 8.0
	# tufos do gramado do lado de fora: [Rect2, cor]
	for ix in range(0, 1280, 8):
		for iy in range(344, 536, 12):
			var n2: float = _ruido(ix * 0.53 + iy * 1.37)
			if n2 > 0.8:
				_tufos.append([Rect2(ix, iy, 4, 4), C_GRAMA_N2])
			elif n2 < 0.07:
				_tufos.append([Rect2(ix, iy, 8, 4), Color(0.09, 0.23, 0.13)])

func reiniciar() -> void:
	foco = 0
	escolhido = 0
	usar_mouse = false
	_ult = 0
	_ato = p.estado.ato_atual() if p != null and p.estado != null else 1
	_fora = _ato > 1      # a vista começa no lugar onde o jogador joga agora
	_ruas = _ato >= 3

static func _ruido(n: float) -> float:
	return fposmod(sin(n * 12.9898) * 43758.5453, 1.0)

# ------------------------------------------------------------------ lógica (sem desenho)
## Garante que a vista condiz com o ato (no primeiro ato nunca há lado de fora).
func _sincronizar() -> void:
	_ato = p.estado.ato_atual()
	if _ato <= 1:
		_fora = false
	if _ato < 3:
		_ruas = false

## A vista de fora está na tela? (a invasão sem fim e o atalho I só valem para a casa)
func vista_fora() -> bool:
	return _fora

## A vista das ruas (3º ato) está na tela?
func vista_ruas() -> bool:
	return _ruas

## Ato que a vista mostra: 1 a casa, 2 o lado de fora, 3 as ruas.
static func _av() -> int:
	return 3 if _ruas else (2 if _fora else 1)

## Áreas clicáveis da vista em uso.
static func lugares() -> Array[Rect2]:
	return RUAS if _ruas else (FORA if _fora else COMODOS)

## Casa vista no segundo ato: dá para passar o mouse e ver os cômodos, mas não para iniciar um.
static func _casa_so_para_ver() -> bool:
	return _ato > 1 and not _fora

static func _sob(pos: Vector2) -> int:
	var rs: Array[Rect2] = lugares()
	for f in range(1, Fases.TOTAL + 1):
		if rs[f - 1].has_point(pos):
			return f
	return -1

## Lugar clicável sob o ponto (-1 se nenhum). Na casa do segundo ato nada é clicável: ela só mostra.
static func comodo_em(pos: Vector2) -> int:
	return _sob(pos)

## Clique num cômodo com a campanha vencida: escolhe (destaque que fica) em vez de entrar; os botões do painel agem nele.
func escolher(f: int) -> void:
	if f < 1 or f > Fases.TOTAL:
		return
	escolhido = f
	foco = f
	_ult = f
	usar_mouse = true
	Som.tocar("clique", 1.1, 0.04, -6.0)

## Na casa depois do 1º ato, "Jogar de novo" repete o cômodo com a força do 1º ato (o 2º ato é lá fora).
func casa_rejogo() -> bool:
	_sincronizar()
	return _ato > 1 and not _fora

func alternar_vista() -> void:
	if _ato <= 1:
		return
	if _ato >= 3:
		# casa -> lado de fora -> ruas -> casa
		if _ruas:
			_ruas = false
			_fora = false
		elif _fora:
			_ruas = true
		else:
			_fora = true
	else:
		_fora = not _fora
	foco = 0
	escolhido = 0
	_ult = 0
	_d_ant = -1
	Som.tocar("hover", 1.0, 0.05, -10.0)

## Botão do painel que só troca de vista? Devolve true se tratou o clique (o `principal.gd` então não faz mais nada).
## Vista de fora: "Ver a casa" fica no lugar da invasão. Casa no segundo ato: "Ir lá fora" fica no lugar de "Jogar".
func botao_troca_vista(bt: int) -> bool:
	_sincronizar()
	if _ato <= 1:
		return false
	if bt == BOTAO_VISTA:
		alternar_vista()
		return true
	# lá fora, a invasão só existe para o lugar já vencido no 2º ato: nos outros o clique é engolido
	# (senão o `principal.gd` o trataria como invasão de um cômodo)
	if _fora and bt == BOTAO_INVASAO:
		var d: int = destaque()
		return d < 1 or not invasao_fora_liberada(d)
	return false

## Lugar de fora (1..5) que já foi vencido no 2º ato e por isso oferece a invasão sem fim.
func invasao_fora_liberada(f: int) -> bool:
	return not _ruas and f >= 1 and f <= Fases.TOTAL and p.estado.vencido[f - 1] >= 2

## Qual botão do mapa está sob o ponto (só existem com a campanha vencida).
static func botao_em(pos: Vector2, vencida: bool) -> int:
	if _ato > 1 and BT_VISTA.has_point(pos):
		return BOTAO_VISTA
	if not vencida:
		return BOTAO_NENHUM
	if BT_FINAL.has_point(pos):
		return BOTAO_FINAL
	if BT_JOGAR.has_point(pos):
		return BOTAO_JOGAR
	if BT_INVASAO.has_point(pos):
		return BOTAO_INVASAO
	return BOTAO_NENHUM

static func proximo(liberada: int) -> int:
	return clampi(liberada, 1, Fases.TOTAL)

## Cômodo liberado para onde a seta `d` leva a partir de `atual` (tabela VIZINHOS); 0 se não houver.
static func vizinho(atual: int, d: Vector2i, liberada: int) -> int:
	var di: int = 0 if d.x < 0 else (1 if d.x > 0 else (2 if d.y < 0 else 3))
	var tabela: Array = VIZINHOS_RUAS if _ruas else (VIZINHOS_FORA if _fora else VIZINHOS)
	for f in tabela[atual - 1][di]:
		if f <= liberada:
			return f
	return 0

static func centro_fantasia(k: int) -> Vector2:
	return Vector2(ICONE_X0 + k * ICONE_PASSO, ICONE_Y)

## Cômodo cujos detalhes o painel mostra: o sob o mouse; senão o do teclado; senão o próximo a jogar.
func destaque() -> int:
	_sincronizar()
	if usar_mouse:
		var m: Vector2 = p.mouse
		var h: int = _sob(m)
		if h > 0:
			_ult = h
			return h
		if escolhido > 0:
			return escolhido
		if _ult > 0 and (PAINEL.has_point(m) or PONTE.has_point(m)):
			return _ult
		_ult = 0
	if foco >= 1 and foco <= Fases.TOTAL:
		return foco
	var est: Estado = p.estado
	if _fora:
		# sem ordem: sugere o primeiro lugar de fora que ainda falta no ato atual
		for i in Fases.TOTAL:
			if est.vencido[i] < _av() and est.lugar_aberto(_av(), i + 1):
				return i + 1
		return 1
	return proximo(est.fase_liberada)

## Tecla no mapa. Devolve a fase a entrar (Enter/Espaço no cômodo liberado) ou 0.
## Na casa do segundo ato Enter/Espaço levam para fora (nenhum cômodo é jogado dali); V alterna a vista.
func tecla(k: int) -> int:
	var est: Estado = p.estado
	var cur: int = destaque()
	if _ato > 1 and k == KEY_V:
		alternar_vista()
		return 0
	var d := Vector2i.ZERO
	match k:
		KEY_LEFT, KEY_A:
			d = Vector2i(-1, 0)
		KEY_RIGHT, KEY_D:
			d = Vector2i(1, 0)
		KEY_UP, KEY_W:
			d = Vector2i(0, -1)
		KEY_DOWN, KEY_S:
			d = Vector2i(0, 1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			return cur if cur <= est.fase_liberada and (not _ruas or est.lugar_aberto(3, cur)) else 0
		_:
			return 0
	var n: int = vizinho(cur, d, est.fase_liberada)
	usar_mouse = false
	_ult = 0
	escolhido = 0
	foco = n if n > 0 else cur
	return 0

# ------------------------------------------------------------------ primitivas
func _r(x: float, y: float, w: float, h: float, c: Color) -> void:
	cv.draw_rect(Rect2(x, y, w, h), c)

func _rr(r: Rect2, c: Color) -> void:
	cv.draw_rect(r, c)

func _l(x: float, y: float, w: float, h: float, c: Color) -> void:
	cv.draw_rect(Rect2(_o.x + x, _o.y + y, w, h), c)

func _moldura(r: Rect2, g: float, c: Color) -> void:
	_r(r.position.x, r.position.y, r.size.x, g, c)
	_r(r.position.x, r.end.y - g, r.size.x, g, c)
	_r(r.position.x, r.position.y + g, g, r.size.y - 2.0 * g, c)
	_r(r.end.x - g, r.position.y + g, g, r.size.y - 2.0 * g, c)

## Disco em faixas de 4 px (centro e raio múltiplos de 4).
func _disco(cx: float, cy: float, raio: float, c: Color) -> void:
	var y: float = -raio
	while y < raio:
		var dy: float = y + 2.0
		var hw: float = floorf(sqrt(maxf(0.0, raio * raio - dy * dy)) / 4.0) * 4.0
		if hw > 0.0:
			_r(cx - hw, cy + y, 2.0 * hw, 4.0, c)
		y += 4.0

func _largura(txt: String, tam: int) -> float:
	return UIComum.FONTE.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam)).x

# ------------------------------------------------------------------ desenho geral
func desenhar() -> void:
	desenhos += 1
	_sincronizar()
	var t: float = p.t
	var est: Estado = p.estado
	var d: int = destaque()
	var dt: float = clampf(t - _t_ant, 0.0, 0.1)
	_t_ant = t
	if d != _d_ant:
		if _d_ant >= 0:
			_troca_t = t
			Som.tocar("hover", 1.0, 0.05, -10.0)
		_d_ant = d
	for id in [BOTAO_JOGAR, BOTAO_INVASAO, BOTAO_FINAL, BOTAO_VISTA]:
		var r0: Rect2 = _rect_botao(id)
		var so: bool = p.mouse != Vector2(-500, -500) and r0.has_point(p.mouse)
		UIComum.anim_passo(_anim, str(id), so, so and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), dt)
		if so and not _anim.get("so" + str(id), false):
			Som.tocar("hover", 1.0, 0.05, -10.0)
		_anim["so" + str(id)] = so
	if _ruas:
		_cena_ruas(t, est, d)
	elif _fora:
		_cena_fora(t, est, d)
	else:
		_cena_casa(t, est, d)
	_entrada_comodo(d)
	_cabecalho()
	if est.campanha_vencida():
		_botao_final()
	if _ato > 1:
		_botao_vista()
	p._tabua_rodape()
	p._rodape_mapa()
	_painel_lateral(d)
	var kt: float = clampf((t - _troca_t) / 0.2, 0.0, 1.0)
	if kt < 1.0:
		# o painel troca de conteúdo com um fade curto e uma linha dourada varrendo de cima para baixo
		cv.draw_rect(PAINEL.grow(-4.0), Color(0.1, 0.06, 0.1, (1.0 - kt) * 0.85))
		cv.draw_rect(Rect2(PAINEL.position.x + 4.0, PAINEL.position.y + 4.0 + kt * (PAINEL.size.y - 12.0), PAINEL.size.x - 8.0, 3.0), Color(1.0, 0.82, 0.3, 1.0 - kt))
	_dica_casa(d)

## A casa em corte, com os cinco cômodos (primeiro ato).
func _cena_casa(t: float, est: Estado, d: int) -> void:
	_ceu(t)
	_lua()
	_chao()
	_arvore(44.0, CHAO_Y)
	_arvore(792.0, CHAO_Y)
	_disco(100.0, CHAO_Y - 12.0, 16.0, C_CONTORNO)
	_disco(100.0, CHAO_Y - 12.0, 12.0, Color(0.18, 0.42, 0.2))
	_disco(732.0, CHAO_Y - 12.0, 16.0, C_CONTORNO)
	_disco(732.0, CHAO_Y - 12.0, 12.0, Color(0.18, 0.42, 0.2))
	_chamine(t)
	_telhado()
	_corpo()
	for f in range(1, Fases.TOTAL + 1):
		_comodo(f, t)
	# molduras por cima de tudo: o próximo a jogar (dourada, pulsando) e o destaque
	var pu: float = 0.5 + 0.5 * sin(t * 4.0)
	for f in range(1, Fases.TOTAL + 1):
		var prox: bool = f <= est.fase_liberada and f > est.fases_vencidas and f == est.fase_liberada
		if prox:
			var r: Rect2 = COMODOS[f - 1]
			_moldura(r.grow(4.0), 4.0, C_OURO.lerp(Color(1.0, 0.97, 0.7), pu))
			_moldura(r.grow(8.0), 4.0, Color(1.0, 0.82, 0.3, 0.2 + 0.35 * pu))
	if d >= 1:
		var rd: Rect2 = COMODOS[d - 1]
		var bloq: bool = d > est.fase_liberada
		_moldura(rd.grow(4.0), 4.0, Color(0.7, 0.7, 0.78, 0.8) if bloq else Color(0.97, 0.97, 1.0))
	_marca_escolhido(COMODOS, t)

## Cômodo escolhido por clique: moldura dourada grossa e etiqueta, bem mais forte que o simples destaque do mouse.
func _marca_escolhido(rs: Array[Rect2], t: float) -> void:
	if escolhido < 1 or escolhido > Fases.TOTAL:
		return
	var r: Rect2 = rs[escolhido - 1]
	var pu: float = 0.5 + 0.5 * sin(t * 5.0)
	_moldura(r.grow(6.0), 6.0, C_OURO.lerp(Color(1.0, 0.97, 0.7), pu))
	_moldura(r.grow(12.0), 4.0, Color(1.0, 0.82, 0.3, 0.25 + 0.3 * pu))
	var w: float = ceilf((_largura("Escolhido", 14) + 16.0) / 4.0) * 4.0
	var x: float = r.position.x + 8.0
	var y: float = r.end.y - 36.0
	_r(x, y, w, 28, C_CONTORNO)
	_r(x + 4, y + 4, w - 8, 20, C_OURO)
	_r(x + 4, y + 4, w - 8, 4, Color(1.0, 0.94, 0.6))
	Desenho.texto(cv, "Escolhido", Vector2(x + 8, y + 19), 14, Color(0.22, 0.12, 0.06))

## Entrar num cômodo: a luz dele acende e o quarto cresce sobre o mapa antes de a cortina fechar.
func _entrada_comodo(d: int) -> void:
	var mn: Variant = p.menus
	if mn == null or not mn.entrando or mn.tr_t < 0.0 or d < 1:
		return
	var k: float = clampf(mn.tr_t / 0.5, 0.0, 1.0)
	cv.draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.5 * k))
	var r: Rect2 = lugares()[d - 1].grow(k * 70.0)
	cv.draw_rect(r, Color(1.0, 0.9, 0.55, 0.35 * k))
	_moldura(r, 4.0, Color(1.0, 0.95, 0.7, k))
func _cabecalho() -> void:
	var est: Estado = p.estado
	Desenho.texto(cv, "As ruas do bairro" if _ruas else ("Lado de fora da casa" if _fora else "Mapa da casa"), Vector2(0, 48), 32, Color(1, 0.92, 0.75), 800.0, 6)
	var sub: String = "Escolha um cômodo: cada um tem %d ondas e um chefe." % Balanco.ONDAS_TOTAIS
	var cor: Color = Color(1, 1, 1, 0.8)
	if _ruas:
		sub = "Terceiro ato: siga a trilha dourada, do Mercadão aos Telhados. Cada lugar tem %d ondas e um chefe." % Balanco.ONDAS_TOTAIS
		if est.tudo_vencido():
			sub = "Tudo vencido! Clique num lugar e escolha: Jogar de novo."
			cor = Desenho.DOURADO
	elif _fora:
		sub = "Segundo ato: escolha um lugar, na ordem que quiser. Cada um tem %d ondas e um chefe." % Balanco.ONDAS_TOTAIS
		if est.tudo_vencido():
			sub = "Tudo vencido! Clique num lugar e escolha: Jogar de novo ou Invasão sem fim."
			cor = Desenho.DOURADO
	elif _ato > 1:
		sub = "Clique num cômodo e escolha: Jogar de novo ou Invasão sem fim. O 2º ato fica lá fora."
		cor = Desenho.DOURADO
	elif est.campanha_vencida():
		sub = "Campanha vencida! Cace peças nos cômodos ou encare a Invasão sem fim."
		cor = Desenho.DOURADO
	var tam: int = p._tam_cabe(sub, [16, 14, 13], 780.0)
	Desenho.texto(cv, sub, Vector2(0, 76), tam, cor, 800.0, 4)

# ------------------------------------------------------------------ cenário
func _ceu(t: float) -> void:
	_r(0, 0, 1280, 160, C_CEU[0])
	_r(0, 160, 1280, 140, C_CEU[1])
	_r(0, 300, 1280, 164, C_CEU[2])
	# faixa pontilhada entre os tons
	for x in range(0, 1280, 8):
		_r(x, 156, 4, 4, C_CEU[1])
		_r(x + 4, 160, 4, 4, C_CEU[0])
		_r(x, 296, 4, 4, C_CEU[2])
		_r(x + 4, 300, 4, 4, C_CEU[1])
	for e in _estrelas:
		var x: float = e[0]
		var y: float = e[1]
		var a: float = 0.55 + 0.45 * sin(t * 2.0 + float(e[3]))
		var cor := Color(1.0, 0.97, 0.8, a)
		if int(e[2]) == 1:
			_r(x, y - 4, 4, 12, cor)
			_r(x - 4, y, 12, 4, cor)
		else:
			_r(x, y, 4, 4, cor)

func _lua() -> void:
	_disco(LUA.x, LUA.y, 44.0, Color(0.95, 0.9, 0.7, 0.08))
	_disco(LUA.x, LUA.y, 36.0, C_CONTORNO)
	_disco(LUA.x, LUA.y, 32.0, Color(0.96, 0.93, 0.76))
	# lado sombreado e crateras
	var y: float = -32.0
	while y < 32.0:
		var dy: float = y + 2.0
		var hw: float = floorf(sqrt(maxf(0.0, 32.0 * 32.0 - dy * dy)) / 4.0) * 4.0
		if hw > 0.0:
			_r(LUA.x - hw, LUA.y + y, 8, 4, Color(0.86, 0.82, 0.62))
		y += 4.0
	_r(LUA.x - 8, LUA.y - 12, 12, 8, Color(0.84, 0.8, 0.6))
	_r(LUA.x + 8, LUA.y + 4, 8, 8, Color(0.84, 0.8, 0.6))
	_r(LUA.x - 4, LUA.y + 16, 8, 4, Color(0.84, 0.8, 0.6))

func _chao() -> void:
	_r(0, CHAO_Y, 1280, 12, C_GRAMA)
	_r(0, CHAO_Y, 1280, 4, C_GRAMA_CL)
	for c in _capim:
		_rr(c, C_GRAMA_CL)
	_r(0, 476, 1280, 124, C_TERRA)
	for l in _lascas:
		_rr(l[0], l[1])

func _arvore(x: float, yg: float) -> void:
	_r(x - 8, yg - 52, 16, 52, C_CONTORNO)
	_r(x - 4, yg - 52, 8, 52, C_MADEIRA)
	_r(x, yg - 52, 4, 52, C_MADEIRA_ESC)
	_disco(x, yg - 80.0, 36.0, C_CONTORNO)
	_disco(x, yg - 80.0, 32.0, Color(0.16, 0.4, 0.2))
	_disco(x - 8.0, yg - 88.0, 20.0, Color(0.22, 0.52, 0.26))
	_disco(x - 12.0, yg - 92.0, 8.0, Color(0.34, 0.66, 0.32))

func _chamine(t: float) -> void:
	_r(544, 112, 40, 108, C_CONTORNO)
	_r(548, 116, 32, 104, Color(0.5, 0.25, 0.22))
	_r(548, 116, 8, 104, Color(0.6, 0.32, 0.27))
	_r(572, 116, 8, 104, Color(0.4, 0.19, 0.18))
	for k in range(0, 104, 16):
		_r(548, 128 + k, 32, 4, Color(0.34, 0.16, 0.15))
	_r(540, 104, 48, 12, C_CONTORNO)
	_r(544, 108, 40, 8, Color(0.58, 0.3, 0.25))
	# fumaça: subindo devagar, sempre abaixo da linha do texto do cabeçalho
	for k in 3:
		var fase: float = fposmod(t * 0.35 + k / 3.0, 1.0)
		var tam: float = 8.0 + 4.0 * floorf(fase * 2.0)
		var y: float = snappedf(100.0 - fase * 12.0, 4.0)
		var x: float = snappedf(556.0 + fase * 12.0, 4.0)
		_r(x, y, tam, tam, Color(0.85, 0.85, 0.92, 0.5 * (1.0 - fase)))

static func _meia(y: float) -> float:
	return maxf(4.0, snappedf(MEIA_BASE * (y + 2.0 - TOPO_TELHADO) / (BASE_TELHADO - TOPO_TELHADO), 4.0))

func _telhado() -> void:
	var y: float = TOPO_TELHADO
	while y < BASE_TELHADO:
		var hw: float = _meia(y)
		_r(CASA_CX - hw - 4.0, y - 4.0, 2.0 * hw + 8.0, 12.0, C_CONTORNO)
		y += 4.0
	y = TOPO_TELHADO
	var linha: int = 0
	while y < BASE_TELHADO:
		var hw2: float = _meia(y)
		_r(CASA_CX - hw2, y, 2.0 * hw2, 4.0, C_TEL_A if linha % 2 == 0 else C_TEL_B)
		_r(CASA_CX - hw2, y, 4.0, 4.0, C_TEL_CL)
		_r(CASA_CX + hw2 - 4.0, y, 4.0, 4.0, C_TEL_ESC)
		# juntas das telhas, deslocadas a cada fileira
		var xj: float = CASA_CX - hw2 + 12.0 + (12.0 if linha % 2 == 0 else 0.0)
		while xj < CASA_CX + hw2 - 8.0:
			_r(xj, y, 4.0, 4.0, C_TEL_ESC)
			xj += 24.0
		y += 4.0
		linha += 1
	# beiral
	_r(76, 240, 648, 16, C_CONTORNO)
	_r(80, 240, 640, 12, C_TEL_ESC)
	_r(80, 240, 640, 4, C_TEL_CL)

func _corpo() -> void:
	# paredes externas
	_r(112, 252, 576, 212, C_CONTORNO)
	_r(116, 252, 568, 212, C_EXT)
	_r(116, 252, 4, 212, C_EXT_CL)
	_r(124, 252, 4, 212, C_EXT_ESC)
	_r(672, 252, 4, 212, C_EXT_CL)
	_r(680, 252, 4, 212, C_EXT_ESC)
	# laje entre os andares
	_r(116, 352, 568, 12, C_EXT)
	_r(116, 352, 568, 4, C_EXT_CL)
	_r(116, 360, 568, 4, C_EXT_ESC)
	# fundação, na linha do chão
	_r(104, 464, 592, 16, C_CONTORNO)
	_r(108, 464, 584, 12, C_PEDRA)
	_r(108, 464, 584, 4, C_PEDRA_CL)
	_r(108, 472, 584, 4, C_PEDRA_ESC)
	# paredes de pedra do porão
	_r(136, 476, 528, 108, C_CONTORNO)
	_r(140, 476, 520, 104, C_PEDRA)
	_r(140, 476, 8, 104, C_PEDRA_CL)
	_r(652, 476, 8, 104, C_PEDRA_ESC)
	_r(148, 568, 504, 12, C_PEDRA_ESC)
	_escada()

## Vão da escada ao lado da cozinha: decorativo, não clicável.
func _escada() -> void:
	var r: Rect2 = ESCADA
	_rr(r, C_CONTORNO)
	var i: Rect2 = r.grow(-4.0)
	_rr(i, Color(0.3, 0.24, 0.27))
	_r(i.position.x, i.position.y, 4, i.size.y, Color(0.36, 0.29, 0.31))
	var fundo: float = i.end.y
	_r(i.position.x, fundo - 12, i.size.x, 12, Color(0.4, 0.28, 0.2))
	for k in 7:
		var x: float = 488.0 + 16.0 * k
		var topo: float = fundo - 12.0 * (k + 1)
		_r(x, topo, 16, fundo - topo, C_MADEIRA)
		_r(x, topo, 16, 4, C_MADEIRA_CL)
		_r(x + 12, topo + 4, 4, fundo - topo - 4, C_MADEIRA_ESC)
	# corrimão
	for k in 7:
		_r(488.0 + 16.0 * k, fundo - 12.0 * (k + 1) - 28.0, 16, 4, C_MADEIRA_ESC)
	_r(488, fundo - 40, 4, 28, C_MADEIRA_ESC)
	# quadro na parede e porta do corredor
	_r(492, 376, 28, 24, C_CONTORNO)
	_r(496, 380, 20, 16, Color(0.4, 0.62, 0.78))
	_r(496, 388, 20, 8, Color(0.28, 0.5, 0.3))
	_r(632, 392, 32, 68, C_CONTORNO)
	_r(636, 396, 24, 64, C_MADEIRA_ESC)
	_r(636, 396, 24, 4, C_MADEIRA)
	_r(652, 428, 4, 4, C_OURO)

# ------------------------------------------------------------------ cômodos
func _comodo(f: int, t: float) -> void:
	var fi: int = f - 1
	var est: Estado = p.estado
	var r: Rect2 = COMODOS[fi]
	var i: Rect2 = r.grow(-4.0)
	_o = i.position
	_iw = i.size.x
	_ih = i.size.y
	_fy = _ih - 16.0
	var bloq: bool = f > est.fase_liberada
	var venc: bool = f <= est.fases_vencidas
	var prox: bool = not bloq and not venc and f == est.fase_liberada
	_rr(r, C_CONTORNO)
	_parede(fi)
	_mobilia(fi, t)
	if not venc and not bloq:
		_l(0, 0, _iw, _ih, Color(0.02, 0.02, 0.08, 0.24))   # luz apagada
	if venc:
		_luz(fi)
	if bloq:
		_l(0, 0, _iw, _ih, Color(0.03, 0.03, 0.08, 0.84))
		_cadeado()
		_olhinhos(t, f)
	else:
		var anim: float = t * 2.0 + f
		var hov: bool = destaque() == f
		var pulo: float = absf(sin(t * 7.0)) * 8.0 if hov else 0.0
		if hov and not venc:
			_l(0, 0, _iw, _ih, Color(1.0, 0.88, 0.5, 0.10 + 0.04 * sin(t * 6.0)))   # acende a luz
		var pos := Vector2(_o.x + CRIATURA_X[fi], _o.y + _fy + 10.0 - pulo)
		Desenho.boneco(cv, pos, 0.8, -1.0, 1, VAZIO, 0.0, anim, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, fi, false, -1)
	_plaquinha(fi, bloq)
	if venc:
		_selo()
	elif prox:
		_tag_jogar(t)
	# passar o mouse ou escolher com o teclado clareia um pouco
	if not bloq and destaque() == f:
		_l(0, 0, _iw, _ih, Color(1, 1, 1, 0.07))

func _parede(fi: int) -> void:
	var pal: Array = PAL[fi]
	var fy: float = _fy
	_l(0, 0, _iw, fy, pal[0])
	match fi:
		0, 1, 3:
			var x: float = 0.0
			while x < _iw:
				_l(x, 0, 4, fy, pal[1])
				x += 16.0
		2:
			_l(0, fy - 56, _iw, 4, pal[2])
			for k in range(1, 4):
				_l(0, fy - 4 - 16 * k, _iw, 4, pal[1])
			var xv: float = 8.0
			while xv < _iw:
				_l(xv, fy - 52, 4, 48, pal[1])
				xv += 16.0
		4:
			for k in 4:
				var y: float = 16.0 * k
				_l(0, y + 12, _iw, 4, pal[1])
				var xb: float = 16.0 if k % 2 == 1 else 0.0
				while xb < _iw:
					_l(xb, y, 4, 12, pal[1])
					xb += 32.0
	_l(0, fy - 4, _iw, 4, pal[2])
	# chão
	_l(0, fy, _iw, 16, pal[3])
	if fi == 2:
		var k2: int = 0
		var x2: float = 0.0
		while x2 < _iw:
			var w: float = minf(8.0, _iw - x2)
			if k2 % 2 == 0:
				_l(x2, fy, w, 8, pal[4])
			else:
				_l(x2, fy + 8, w, 8, pal[4])
			x2 += 8.0
			k2 += 1
	else:
		_l(0, fy, _iw, 4, pal[4])
		var x3: float = 12.0
		while x3 < _iw - 4.0:
			_l(x3, fy + 4, 4, 12, pal[4])
			x3 += 24.0

func _mobilia(fi: int, t: float) -> void:
	var fy: float = _fy
	var iw: float = _iw
	match fi:
		0:  # Quarto: cama e janela com a noite
			_l(132, 8, 60, 48, C_MADEIRA_CL)
			_l(140, 16, 44, 32, Color(0.1, 0.13, 0.32))
			_l(160, 16, 4, 32, C_MADEIRA_CL)
			_l(140, 28, 44, 4, C_MADEIRA_CL)
			_l(148, 20, 4, 4, Color(1, 0.95, 0.6))
			_l(172, 36, 4, 4, Color(1, 0.95, 0.6))
			_l(132, 8, 8, 48, Color(0.86, 0.5, 0.68))
			_l(184, 8, 8, 48, Color(0.86, 0.5, 0.68))
			_l(8, fy - 12, 88, 12, C_MADEIRA)
			_l(8, fy - 32, 8, 32, C_MADEIRA_ESC)
			_l(92, fy - 20, 4, 20, C_MADEIRA_ESC)
			_l(16, fy - 20, 76, 8, Color(0.95, 0.92, 0.88))
			_l(36, fy - 24, 56, 12, Color(0.86, 0.4, 0.6))
			_l(36, fy - 24, 56, 4, Color(0.95, 0.55, 0.72))
			_l(16, fy - 28, 20, 8, Color(1, 1, 1))
		1:  # Sala: sofá e lareira acesa
			_l(8, fy - 36, 88, 24, Color(0.6, 0.42, 0.14))
			_l(8, fy - 16, 88, 16, Color(0.8, 0.6, 0.24))
			_l(8, fy - 24, 8, 24, Color(0.9, 0.72, 0.34))
			_l(88, fy - 24, 8, 24, Color(0.9, 0.72, 0.34))
			_l(24, fy - 28, 12, 12, Color(0.8, 0.25, 0.3))
			_l(112, fy - 52, 64, 52, Color(0.55, 0.5, 0.5))
			_l(112, fy - 40, 64, 4, Color(0.4, 0.36, 0.38))
			_l(136, fy - 52, 4, 12, Color(0.4, 0.36, 0.38))
			_l(108, fy - 56, 72, 4, Color(0.7, 0.66, 0.64))
			_l(124, fy - 36, 40, 36, Color(0.07, 0.04, 0.05))
			_l(128, fy - 4, 32, 4, C_MADEIRA_ESC)
			var j: float = 4.0 if sin(t * 9.0) > 0.0 else 0.0
			_l(132, fy - 16 - j, 24, 12 + j, Color(0.95, 0.45, 0.1))
			_l(140, fy - 20 - j, 8, 16 + j, Color(1.0, 0.85, 0.3))
		2:  # Cozinha: armário, fogão, geladeira
			_l(8, fy - 24, 92, 24, Color(0.85, 0.75, 0.55))
			_l(8, fy - 28, 92, 4, Color(0.97, 0.97, 0.94))
			_l(52, fy - 24, 4, 24, Color(0.62, 0.52, 0.36))
			_l(36, fy - 36, 12, 4, Color(0.7, 0.72, 0.78))
			_l(36, fy - 36, 4, 8, Color(0.7, 0.72, 0.78))
			_l(112, 12, 64, 28, Color(0.85, 0.75, 0.55))
			_l(140, 12, 4, 28, Color(0.62, 0.52, 0.36))
			_l(112, 36, 64, 4, Color(0.62, 0.52, 0.36))
			_l(192, fy - 32, 44, 32, Color(0.88, 0.88, 0.92))
			_l(192, fy - 36, 44, 4, Color(0.2, 0.2, 0.24))
			_l(198, fy - 40, 12, 4, Color(0.3, 0.3, 0.34))
			_l(218, fy - 40, 12, 4, Color(0.3, 0.3, 0.34))
			_l(200, fy - 20, 28, 14, Color(0.2, 0.2, 0.26))
			_l(204, fy - 16, 20, 6, Color(0.9, 0.55, 0.2) if sin(t * 3.0) > -0.5 else Color(0.6, 0.35, 0.15))
			_l(200, fy - 28, 4, 4, Color(0.8, 0.25, 0.25))
			_l(224, fy - 28, 4, 4, Color(0.8, 0.25, 0.25))
			_l(256, 16, 40, fy - 16, Color(0.82, 0.92, 0.96))
			_l(256, 16, 4, fy - 16, Color(0.95, 1.0, 1.0))
			_l(288, 16, 8, fy - 16, Color(0.64, 0.76, 0.82))
			_l(256, 44, 40, 4, Color(0.55, 0.66, 0.72))
			_l(284, 24, 4, 16, Color(0.3, 0.34, 0.4))
			_l(284, 56, 4, 16, Color(0.3, 0.34, 0.4))
		3:  # Sótão: vigas, claraboia, caixas
			_l(0, 0, 8, fy, Color(0.45, 0.3, 0.2))
			_l(iw - 8, 0, 8, fy, Color(0.45, 0.3, 0.2))
			_l(0, 16, iw, 8, Color(0.5, 0.34, 0.22))
			_l(0, 16, iw, 4, Color(0.62, 0.44, 0.3))
			for k in 5:
				_l(8 + 4 * k, 24 + 4 * k, 8, 4, Color(0.45, 0.3, 0.2))
				_l(iw - 16 - 4 * k, 24 + 4 * k, 8, 4, Color(0.45, 0.3, 0.2))
			_l(84, 0, 56, 16, Color(0.62, 0.44, 0.3))
			_l(88, 0, 48, 12, Color(0.3, 0.38, 0.7))
			_l(110, 0, 4, 12, Color(0.62, 0.44, 0.3))
			_l(98, 4, 4, 4, Color(1, 0.95, 0.7))
			_l(120, 4, 4, 4, Color(1, 0.95, 0.7))
			_l(88, 24, 48, 12, Color(0.8, 0.88, 1.0, 0.08))
			_l(84, 36, 56, 12, Color(0.8, 0.88, 1.0, 0.07))
			_l(80, 48, 64, fy - 48, Color(0.8, 0.88, 1.0, 0.06))
			_l(8, fy - 16, 24, 16, Color(0.72, 0.52, 0.32))
			_l(16, fy - 16, 4, 16, Color(0.86, 0.7, 0.46))
			_l(36, fy - 12, 20, 12, Color(0.64, 0.46, 0.28))
			_l(12, fy - 28, 16, 12, Color(0.78, 0.58, 0.36))
			_l(128, fy - 16, 28, 16, C_MADEIRA)
			_l(128, fy - 12, 28, 4, C_MADEIRA_ESC)
			_l(138, fy - 12, 8, 8, C_OURO)
		4:  # Porão: canos, caldeira, barril
			_l(0, 36, iw, 8, Color(0.46, 0.52, 0.6))
			_l(0, 36, iw, 4, Color(0.62, 0.68, 0.76))
			var x: float = 64.0
			while x < iw - 16.0:
				_l(x, 32, 8, 16, Color(0.3, 0.34, 0.42))
				x += 96.0
			_l(300, 44, 8, fy - 44, Color(0.46, 0.52, 0.6))
			_l(300, 44, 4, fy - 44, Color(0.62, 0.68, 0.76))
			_l(296, fy - 32, 16, 4, Color(0.8, 0.2, 0.2))
			_l(300, fy - 28, 8, 4, Color(0.8, 0.2, 0.2))
			_l(392, 0, 8, 16, Color(0.46, 0.52, 0.6))
			_l(372, fy - 48, 48, 48, Color(0.48, 0.52, 0.58))
			_l(372, fy - 48, 8, 48, Color(0.64, 0.68, 0.74))
			_l(412, fy - 48, 8, 48, Color(0.34, 0.38, 0.44))
			_l(372, fy - 36, 48, 4, Color(0.26, 0.28, 0.34))
			_l(372, fy - 12, 48, 4, Color(0.26, 0.28, 0.34))
			_l(380, fy - 52, 32, 4, Color(0.64, 0.68, 0.74))
			_l(388, fy - 32, 16, 12, C_CONTORNO)
			_l(392, fy - 28, 8, 4, Color(0.95, 0.92, 0.8))
			var brasa: float = 0.5 + 0.5 * sin(t * 5.0)
			_l(384, fy - 8, 24, 8, Color(0.95, 0.4 + 0.3 * brasa, 0.1))
			_l(440, fy - 28, 28, 28, C_MADEIRA)
			_l(440, fy - 28, 28, 4, C_MADEIRA_CL)
			_l(440, fy - 20, 28, 4, C_MADEIRA_ESC)
			_l(440, fy - 8, 28, 4, C_MADEIRA_ESC)

## Luz acesa (cômodo vencido): lâmpada pendurada com um halo quente.
func _luz(fi: int) -> void:
	var lx: float = LAMPADA_X[fi]
	_l(0, 0, _iw, _ih, Color(1.0, 0.85, 0.4, 0.07))
	_l(lx - 28, 0, 60, 44, Color(1.0, 0.9, 0.5, 0.08))
	_l(lx - 16, 0, 36, 32, Color(1.0, 0.92, 0.55, 0.12))
	_l(lx, 0, 4, 12, C_CONTORNO)
	_l(lx - 4, 12, 12, 8, Color(1.0, 0.95, 0.6))
	_l(lx - 4, 20, 12, 4, Color(1.0, 0.8, 0.3))

func _plaquinha(fi: int, bloq: bool) -> void:
	var nome: String = Fases.NOME[fi]
	var w: float = ceilf((_largura(nome, 14) + 16.0) / 4.0) * 4.0
	var x: float = _o.x + 4.0
	var y: float = _o.y + 4.0
	_r(x, y, w, 28, C_CONTORNO)
	_r(x + 4, y + 4, w - 8, 20, Color(0.42, 0.28, 0.17))
	_r(x + 4, y + 4, w - 8, 4, Color(0.58, 0.4, 0.24))
	Desenho.texto(cv, nome, Vector2(x + 8, y + 19), 14, Color(1, 0.94, 0.8, 0.7 if bloq else 1.0))

func _selo() -> void:
	var x: float = _o.x + _iw - 32.0
	var y: float = _o.y + 4.0
	_r(x, y, 28, 28, C_CONTORNO)
	_r(x + 4, y + 4, 20, 20, Color(0.35, 0.8, 0.4))
	_r(x + 4, y + 4, 20, 4, Color(0.55, 0.92, 0.55))
	for c in [Vector2(8, 12), Vector2(12, 16), Vector2(16, 12), Vector2(20, 8)]:
		_r(x + c.x, y + c.y, 4, 4, Color.WHITE)

func _tag_jogar(t: float) -> void:
	var w: float = ceilf((_largura("Jogar", 14) + 36.0) / 4.0) * 4.0
	var x: float = _o.x + _iw - w - 4.0
	var y: float = _o.y + 4.0
	_r(x, y, w, 28, C_CONTORNO)
	_r(x + 4, y + 4, w - 8, 20, C_OURO)
	_r(x + 4, y + 4, w - 8, 4, Color(1.0, 0.94, 0.6))
	var bob: float = 4.0 if sin(t * 6.0) > 0.0 else 0.0
	var ax: float = x + 8.0 + bob
	_r(ax, y + 8, 4, 12, C_CONTORNO)
	_r(ax + 4, y + 10, 4, 8, C_CONTORNO)
	_r(ax + 8, y + 12, 4, 4, C_CONTORNO)
	Desenho.texto(cv, "Jogar", Vector2(x + 24, y + 19), 14, Color(0.22, 0.12, 0.06))

func _cadeado() -> void:
	var bx: float = _o.x + snappedf(_iw * 0.5, 4.0) - 12.0
	var by: float = _o.y + snappedf(_ih * 0.5, 4.0) - 4.0
	_r(bx + 4, by - 16, 16, 16, Color(0.78, 0.78, 0.86))
	_r(bx + 8, by - 12, 8, 12, Color(0.03, 0.03, 0.08))
	_r(bx - 4, by - 4, 32, 24, C_CONTORNO)
	_r(bx, by, 24, 16, Color(0.82, 0.82, 0.9))
	_r(bx, by + 12, 24, 4, Color(0.56, 0.56, 0.64))
	_r(bx + 10, by + 4, 4, 8, C_CONTORNO)

func _olhinhos(t: float, f: int) -> void:
	var ex: float = _o.x + snappedf(_iw * 0.78, 4.0)
	var ey: float = _o.y + _fy - 8.0
	var pisca: bool = fposmod(t + f * 0.7, 3.5) < 0.15
	var olhar: float = 4.0 if sin(t * 0.8 + f) > 0.0 else 0.0
	for k in 2:
		var x: float = ex + 20.0 * k
		if pisca:
			_r(x, ey + 2, 8, 4, Color(1.0, 0.95, 0.55, 0.9))
		else:
			_r(x, ey, 8, 8, Color(1.0, 0.95, 0.55, 0.9))
			_r(x + olhar, ey + 2, 4, 4, C_CONTORNO)

# ------------------------------------------------------------------ lado de fora (segundo ato)
## A casa vista de frente, de noite, com os cinco lugares em volta. Mesmo traço do corte dos cômodos.
func _cena_fora(t: float, est: Estado, d: int) -> void:
	_ceu(t)
	_lua()
	_mata_distante()
	_barranco(t, d)
	_gramado()
	_quintal_fora(t)
	_casa_fora(t)
	_garagem_fora(t)
	_rua_fora()
	for f in range(1, Fases.TOTAL + 1):
		_lugar_fora(f, t, est, d)
	if d >= 1:
		_moldura(FORA[d - 1].grow(4.0), 4.0, Color(0.97, 0.97, 1.0))
	_marca_escolhido(FORA, t)

## Cada lugar: escurece se ainda falta, acende se está feito, bicho da família, plaquinha e selo.
func _lugar_fora(f: int, t: float, est: Estado, d: int) -> void:
	var fi: int = f - 1
	var r: Rect2 = FORA[fi]
	var feito: bool = est.vencido[fi] >= _av()
	var hov: bool = d == f
	_o = r.position + Vector2(4, 4)
	_iw = r.size.x - 8.0
	_ih = r.size.y - 8.0
	if feito:
		_rr(r, Color(1.0, 0.86, 0.45, 0.07))
	else:
		_rr(r, Color(0.02, 0.02, 0.08, 0.2))
		if hov:
			_rr(r, Color(1.0, 0.88, 0.5, 0.12 + 0.04 * sin(t * 6.0)))
	var b: Vector3 = BICHO_FORA[fi]
	var pulo: float = absf(sin(t * 7.0)) * 8.0 if hov else 0.0
	Desenho.boneco(cv, Vector2(b.x, b.y - pulo), b.z, -1.0, 1, VAZIO, 0.0, t * 2.0 + f, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, fi + Fases.TOTAL, false, -1, false, false, 0, false, -1)
	_placa_fora(fi, feito, t)
	if feito:
		_selo()
	if hov:
		_rr(r, Color(1, 1, 1, 0.07))

## Plaquinha de madeira com o nome e, logo abaixo, o estado: "falta" (dourado, pulsando) ou "feito" (verde).
func _placa_fora(fi: int, feito: bool, t: float) -> void:
	var nome: String = Fases.nome_do_lugar(fi + Fases.TOTAL * (_av() - 1))
	var off: Vector2 = PLACA_FORA[fi]
	var w: float = ceilf((_largura(nome, 14) + 16.0) / 4.0) * 4.0
	var x: float = FORA[fi].position.x + off.x
	var y: float = FORA[fi].position.y + (off.y if off.y >= 0.0 else FORA[fi].size.y + off.y)
	_r(x, y, w, 28, C_CONTORNO)
	_r(x + 4, y + 4, w - 8, 20, Color(0.42, 0.28, 0.17))
	_r(x + 4, y + 4, w - 8, 4, Color(0.58, 0.4, 0.24))
	Desenho.texto(cv, nome, Vector2(x + 8, y + 19), 14, Color(1, 0.94, 0.8))
	var txt: String = "feito" if feito else "falta"
	var cw: float = ceilf((_largura(txt, 13) + 20.0) / 4.0) * 4.0
	var cor: Color = Color(0.4, 0.82, 0.45) if feito else C_OURO.lerp(Color(1.0, 0.97, 0.7), 0.5 + 0.5 * sin(t * 4.0))
	_r(x, y + 26, cw, 24, C_CONTORNO)
	_r(x + 4, y + 30, cw - 8, 16, cor)
	_r(x + 4, y + 30, cw - 8, 4, cor.lightened(0.3))
	Desenho.texto(cv, txt, Vector2(x + 10, y + 43), 13, Color(0.14, 0.09, 0.05))

func _mata_distante() -> void:
	# fileira de copas escuras ao fundo, sem contorno, só para dar profundidade
	for i in 24:
		var x: float = 28.0 + 52.0 * i
		var y: float = 344.0 - snappedf(_ruido(i * 3.1) * 16.0, 4.0)
		var raio: float = 24.0 + 4.0 * floorf(_ruido(i * 1.7 + 5.0) * 3.0)
		_disco(x, y, raio, Color(0.05, 0.1, 0.14))
		_disco(x - 8.0, y - 8.0, raio - 12.0, Color(0.07, 0.13, 0.17))

func _gramado() -> void:
	_r(0, 340, 1280, 262, C_GRAMA_N)
	_r(0, 340, 1280, 4, C_GRAMA_N2)
	for tf in _tufos:
		_rr(tf[0], tf[1])

## O barranco do canto, com a árvore e o buraco da Toca no pé dela.
func _barranco(t: float, d: int) -> void:
	var y: float = 236.0
	while y < 344.0:
		var xr: float = snappedf(220.0 + (y - 240.0) * 0.9, 4.0)
		if y < 240.0:
			_r(0, y, 220, 4, C_CONTORNO)
		else:
			_r(xr, y, 8, 4, C_CONTORNO)
			_r(0, y, xr, 4, C_TERRA)
			if y == 240.0:
				_r(0, y, xr, 4, C_GRAMA_CL)
			elif y < 252.0:
				_r(0, y, xr, 4, C_GRAMA)
			else:
				var k: float = 0.0
				while k < xr:
					var n: float = _ruido(k * 0.41 + y * 1.13)
					if n > 0.84:
						_r(k, y, 8, 4, C_TERRA_ESC)
					elif n < 0.06:
						_r(k, y, 4, 4, C_TERRA_CL)
					k += 8.0
		y += 4.0
	_arvore(132.0, 240.0)
	# raízes e o buraco
	_r(112, 236, 8, 12, C_MADEIRA_ESC)
	_r(144, 236, 8, 12, C_MADEIRA_ESC)
	for k in 14:
		var hw: float = minf(24.0, 8.0 + 8.0 * k)
		_r(132.0 - hw - 4.0, 268.0 + 4.0 * k, 2.0 * hw + 8.0, 4, C_CONTORNO)
	for k in 14:
		var hw2: float = minf(24.0, 8.0 + 8.0 * k)
		_r(132.0 - hw2, 272.0 + 4.0 * k, 2.0 * hw2, 4, Color(0.04, 0.02, 0.05))
	# terra cavada na boca do buraco
	_r(96, 316, 16, 8, C_TERRA_CL)
	_r(156, 316, 20, 8, C_TERRA_CL)
	_r(104, 312, 8, 4, C_TERRA_CL)
	# olhinhos lá dentro (somem quando o mouse está na Toca: o bicho sai)
	if d != 5:
		var pisca: bool = fposmod(t + 1.3, 3.5) < 0.15
		for k in 2:
			_r(120.0 + 20.0 * k, 296.0 + (2.0 if pisca else 0.0), 8, 4 if pisca else 8, Color(1.0, 0.95, 0.55, 0.9))

# ---- quintal: grama, cerca e varal
func _quintal_fora(t: float) -> void:
	# cerca de ripas ao fundo
	_r(28, 362, 216, 4, C_MADEIRA_ESC)
	_r(28, 378, 216, 4, C_MADEIRA_ESC)
	for k in 14:
		var x: float = 28.0 + 16.0 * k
		_r(x, 356, 12, 36, C_MADEIRA)
		_r(x, 356, 4, 36, C_MADEIRA_CL)
		_r(x + 8, 356, 4, 36, C_MADEIRA_ESC)
		_r(x + 4, 352, 4, 4, C_MADEIRA)
	_r(28, 392, 216, 4, C_CONTORNO)
	# varal: dois postes e a corda com um pouco de barriga
	for px in [52.0, 216.0]:
		_r(px, 396, 8, 100, C_CONTORNO)
		_r(px + 4, 396, 4, 100, C_MADEIRA_ESC)
		_r(px, 396, 4, 100, C_MADEIRA)
		_r(px - 8, 396, 24, 4, C_MADEIRA_ESC)
	for xx in range(60, 216, 4):
		var u: float = (xx - 60.0) / 156.0
		_r(xx, 400.0 + snappedf(8.0 * 4.0 * u * (1.0 - u), 4.0), 4, 4, Color(0.85, 0.85, 0.9))
	# roupas penduradas: lençol, camiseta e meias
	var bal: float = 4.0 if sin(t * 1.6) > 0.55 else 0.0
	_r(84, 408, 36, 44, C_CONTORNO)
	_r(88, 408, 28, 40, Color(0.7, 0.82, 0.95))
	_r(88, 408, 28, 4, Color(0.85, 0.92, 1.0))
	_r(112, 412, 4, 36, Color(0.55, 0.66, 0.8))
	_r(128 + bal, 408, 28, 4, C_CONTORNO)
	_r(124 + bal, 412, 36, 12, C_CONTORNO)
	_r(128 + bal, 412, 28, 28, C_CONTORNO)
	_r(128 + bal, 412, 28, 24, Color(0.95, 0.8, 0.3))
	_r(124 + bal, 412, 8, 12, Color(0.95, 0.8, 0.3))
	_r(152 + bal, 412, 8, 12, Color(0.95, 0.8, 0.3))
	_r(128 + bal, 412, 28, 4, Color(1.0, 0.92, 0.55))
	for k in 2:
		var sx: float = 176.0 + 12.0 * k
		_r(sx, 408, 12, 28, C_CONTORNO)
		_r(sx + 4, 408, 4, 24, Color(0.9, 0.35, 0.4) if k == 0 else Color(0.4, 0.7, 0.9))
		_r(sx, 428, 8, 8, Color(0.9, 0.35, 0.4) if k == 0 else Color(0.4, 0.7, 0.9))
	# florzinhas
	for fl in [Vector2(40, 484), Vector2(72, 500), Vector2(196, 488), Vector2(228, 504)]:
		_r(fl.x, fl.y, 4, 8, C_GRAMA)
		_r(fl.x - 4, fl.y - 4, 12, 4, Color(0.95, 0.5, 0.65))
		_r(fl.x, fl.y - 8, 4, 12, Color(0.95, 0.5, 0.65))
		_r(fl.x, fl.y - 4, 4, 4, C_OURO)

# ---- a casa vista de frente
static func _meia_fora(y: float) -> float:
	return maxf(4.0, snappedf(FORA_MEIA * (y + 2.0 - FORA_TOPO) / (FORA_BASE - FORA_TOPO), 4.0))

func _casa_fora(t: float) -> void:
	# telhado
	var y: float = FORA_TOPO
	while y < FORA_BASE:
		var hw: float = _meia_fora(y)
		_r(FORA_CX - hw - 4.0, y - 4.0, 2.0 * hw + 8.0, 12.0, C_CONTORNO)
		y += 4.0
	y = FORA_TOPO
	var linha: int = 0
	while y < FORA_BASE:
		var hw2: float = _meia_fora(y)
		_r(FORA_CX - hw2, y, 2.0 * hw2, 4.0, C_TEL_A if linha % 2 == 0 else C_TEL_B)
		_r(FORA_CX - hw2, y, 4.0, 4.0, C_TEL_CL)
		_r(FORA_CX + hw2 - 4.0, y, 4.0, 4.0, C_TEL_ESC)
		var xj: float = FORA_CX - hw2 + 12.0 + (12.0 if linha % 2 == 0 else 0.0)
		while xj < FORA_CX + hw2 - 8.0:
			_r(xj, y, 4.0, 4.0, C_TEL_ESC)
			xj += 24.0
		y += 4.0
		linha += 1
	# chaminé, de pé sobre a água direita do telhado
	_r(544, 164, 40, 88, C_CONTORNO)
	_r(548, 168, 32, 80, Color(0.5, 0.25, 0.22))
	_r(548, 168, 8, 80, Color(0.6, 0.32, 0.27))
	_r(572, 168, 8, 80, Color(0.4, 0.19, 0.18))
	for k in range(0, 80, 16):
		_r(548, 180 + k, 32, 4, Color(0.34, 0.16, 0.15))
	_r(540, 156, 48, 12, C_CONTORNO)
	_r(544, 160, 40, 8, Color(0.58, 0.3, 0.25))
	for k in 3:
		var fase: float = fposmod(t * 0.35 + k / 3.0, 1.0)
		var tam: float = 8.0 + 4.0 * floorf(fase * 2.0)
		var fy: float = snappedf(152.0 - fase * 28.0, 4.0)
		var fx: float = snappedf(556.0 + fase * 16.0, 4.0)
		_r(fx, fy, tam, tam, Color(0.85, 0.85, 0.92, 0.5 * (1.0 - fase)))
	# beiral
	_r(244, 284, 400, 16, C_CONTORNO)
	_r(248, 284, 392, 12, C_TEL_ESC)
	_r(248, 284, 392, 4, C_TEL_CL)
	# parede da frente, com tábuas
	_r(284, 296, 320, 224, C_CONTORNO)
	_r(288, 296, 312, 224, C_PAREDE_N)
	for k in range(0, 224, 12):
		_r(288, 308 + k, 312, 4, C_PAREDE_N.darkened(0.14))
	_r(288, 296, 4, 224, C_PAREDE_N.lightened(0.18))
	_r(596, 296, 4, 224, C_PAREDE_N.darkened(0.25))
	# fundação de pedra
	_r(280, 508, 328, 16, C_CONTORNO)
	_r(284, 508, 320, 12, C_PEDRA_ESC)
	_r(284, 508, 320, 4, C_PEDRA)
	# janelas acesas (num canto da esquerda, a silhueta de um gato)
	_janela_fora(316, 340, 56, 60, true)
	_janela_fora(516, 340, 56, 60, false)
	# porta com vidro aceso e lampião
	_r(416, 424, 56, 88, C_CONTORNO)
	_r(420, 428, 48, 84, C_MADEIRA)
	_r(420, 428, 4, 84, C_MADEIRA_CL)
	_r(464, 428, 4, 84, C_MADEIRA_ESC)
	_r(428, 436, 32, 20, C_CONTORNO)
	_r(432, 440, 24, 12, C_VIDRO)
	_r(442, 440, 4, 12, C_MADEIRA)
	_r(428, 468, 32, 4, C_MADEIRA_ESC)
	_r(428, 488, 32, 4, C_MADEIRA_ESC)
	_r(456, 472, 4, 8, C_OURO)
	_r(404, 512, 80, 8, C_CONTORNO)
	_r(408, 512, 72, 4, C_PEDRA_CL)
	_disco(396.0, 440.0, 24.0, Color(1.0, 0.9, 0.5, 0.06))
	_r(392, 428, 8, 4, C_CONTORNO)
	_r(392, 432, 8, 12, C_VIDRO)
	_r(392, 444, 8, 4, C_CONTORNO)

func _janela_fora(x: float, y: float, w: float, h: float, gato: bool) -> void:
	_r(x - 16, y - 12, w + 32, h + 28, Color(1.0, 0.9, 0.5, 0.06))
	_r(x - 4, y - 4, w + 8, h + 8, C_CONTORNO)
	_r(x, y, w, h, C_EXT_CL)
	_r(x + 4, y + 4, w - 8, h - 8, C_VIDRO)
	_r(x + 4, y + 4, w - 8, 8, Color(1.0, 0.94, 0.65))
	_r(x + w * 0.5 - 2.0, y + 4, 4, h - 8, C_EXT_CL)
	_r(x + 4, y + h * 0.5 - 2.0, w - 8, 4, C_EXT_CL)
	_r(x + 4, y + 4, 8, h - 8, Color(0.85, 0.4, 0.5, 0.75))
	_r(x + w - 12, y + 4, 8, h - 8, Color(0.85, 0.4, 0.5, 0.75))
	_r(x - 8, y + h, w + 16, 8, C_CONTORNO)
	_r(x - 4, y + h, w + 8, 4, C_PEDRA_CL)
	if gato:
		var gy: float = y + h - 4.0
		_r(x + 16, gy - 12, 16, 12, Color(0.12, 0.1, 0.16))
		_r(x + 20, gy - 20, 12, 8, Color(0.12, 0.1, 0.16))
		_r(x + 20, gy - 24, 4, 4, Color(0.12, 0.1, 0.16))
		_r(x + 28, gy - 24, 4, 4, Color(0.12, 0.1, 0.16))
		_r(x + 32, gy - 8, 8, 4, Color(0.12, 0.1, 0.16))

func _garagem_fora(t: float) -> void:
	# corpo anexo e teto plano
	_r(596, 368, 256, 156, C_CONTORNO)
	_r(600, 372, 248, 148, Color(0.45, 0.4, 0.44))
	_r(600, 372, 4, 148, Color(0.55, 0.5, 0.54))
	_r(844, 372, 4, 148, Color(0.34, 0.3, 0.34))
	_r(592, 352, 264, 20, C_CONTORNO)
	_r(596, 352, 256, 16, Color(0.3, 0.3, 0.37))
	_r(596, 352, 256, 4, Color(0.45, 0.45, 0.52))
	_r(596, 364, 256, 4, Color(0.2, 0.2, 0.26))
	# portão de enrolar com frestas, ripas e uma fileira de vidros
	_r(612, 380, 224, 140, C_CONTORNO)
	_r(616, 384, 216, 136, C_PEDRA)
	_r(616, 384, 216, 4, C_PEDRA_CL)
	_r(616, 384, 4, 136, C_PEDRA_CL)
	_r(828, 384, 4, 136, C_PEDRA_ESC)
	var yy: float = 396.0
	while yy < 516.0:
		_r(620, yy, 208, 4, C_PEDRA_ESC)
		yy += 16.0
	for k in 4:
		_r(640.0 + 48.0 * k, 388, 32, 8, C_VIDRO.darkened(0.25))
	_r(716, 496, 32, 8, C_CONTORNO)
	_r(720, 496, 24, 4, C_PEDRA_CL)
	# luz acima do portão
	_disco(724.0, 372.0, 20.0, Color(1.0, 0.9, 0.5, 0.07))
	_r(716, 368, 16, 4, C_CONTORNO)
	_r(720, 372, 8, 4, C_VIDRO)

func _rua_fora() -> void:
	# calçada, meio-fio e asfalto
	_r(0, 536, 1280, 28, Color(0.46, 0.46, 0.52))
	_r(0, 536, 1280, 4, Color(0.6, 0.6, 0.66))
	for x in range(0, 1280, 56):
		_r(x, 540, 4, 24, Color(0.34, 0.34, 0.4))
	_r(0, 556, 1280, 4, Color(0.38, 0.38, 0.44))
	_r(0, 560, 1280, 4, C_CONTORNO)
	_r(0, 564, 1280, 40, Color(0.17, 0.17, 0.22))
	for x in range(0, 1280, 8):
		if _ruido(x * 0.9 + 4.0) > 0.78:
			_r(x, 568.0 + 4.0 * floorf(_ruido(x * 1.3) * 7.0), 4, 4, Color(0.24, 0.24, 0.3))
	for x in range(8, 1280, 80):
		_r(x, 580, 40, 4, Color(0.85, 0.8, 0.45))
	# poste de luz, de pé na calçada diante do muro
	_disco(284.0, 436.0, 44.0, Color(1.0, 0.9, 0.5, 0.05))
	_disco(284.0, 436.0, 28.0, Color(1.0, 0.9, 0.5, 0.07))
	_r(252, 540, 24, 8, C_CONTORNO)
	_r(256, 540, 16, 4, C_PEDRA)
	_r(256, 424, 12, 120, C_CONTORNO)
	_r(260, 424, 4, 116, C_PEDRA)
	_r(264, 424, 4, 116, C_PEDRA_ESC)
	_r(256, 416, 36, 12, C_CONTORNO)
	_r(260, 420, 28, 4, C_PEDRA)
	_r(276, 424, 24, 12, C_CONTORNO)
	_r(280, 428, 16, 8, Color(1.0, 0.94, 0.65))
	_r(236, 540, 100, 4, Color(1.0, 0.9, 0.5, 0.1))

# ------------------------------------------------------------------ as ruas (terceiro ato)
## O bairro em corte: cinco lugares ligados por ruas; a trilha dourada vai do 1º ao 5º lugar.
func _cena_ruas(t: float, est: Estado, d: int) -> void:
	_ceu(t)
	_r(0, 96, 1280, 508, Color(0.10, 0.11, 0.17))
	_r(0, 96, 1280, 4, Color(0.2, 0.22, 0.32))
	for ix in range(0, 1280, 8):
		for iy in range(104, 600, 12):
			var n: float = _ruido(ix * 0.61 + iy * 1.27)
			if n > 0.86:
				_r(ix, iy, 4, 4, Color(0.15, 0.16, 0.24))
			elif n < 0.05:
				_r(ix, iy, 8, 4, Color(0.07, 0.08, 0.13))
	_ruas_asfalto()
	_trilha(t)
	for f in range(1, Fases.TOTAL + 1):
		_lugar_ruas(f, t, est, d)
	if d >= 1:
		_moldura(RUAS[d - 1].grow(4.0), 4.0, Color(0.97, 0.97, 1.0))
	_marca_escolhido(RUAS, t)

func _ruas_asfalto() -> void:
	var asf := Color(0.17, 0.17, 0.23)
	var meio := Color(0.46, 0.46, 0.52)
	# meio-fios primeiro e asfalto depois, para os cruzamentos se unirem
	_r(0, 392, 1280, 40, meio)
	_r(396, 200, 44, 48, meio)
	_r(396, 424, 44, 24, meio)
	_r(694, 376, 44, 24, meio)
	_r(0, 396, 1280, 32, asf)
	_r(402, 200, 32, 48, asf)
	_r(402, 428, 32, 20, asf)
	_r(700, 376, 32, 24, asf)
	for x in range(0, 1280, 56):
		_r(x, 396, 4, 4, Color(0.22, 0.22, 0.29))
		_r(x + 24, 424, 4, 4, Color(0.22, 0.22, 0.29))
	# faixa de pedestres no cruzamento da Arena
	for k in 4:
		_r(406 + k * 8, 388, 4, 8, Color(0.8, 0.8, 0.85, 0.55))
	# postes de luz nos cantos
	for px in [276.0, 660.0]:
		_disco(px, 384.0, 20.0, Color(1.0, 0.9, 0.5, 0.06))
		_r(px - 2, 384, 4, 12, C_CONTORNO)
		_r(px - 4, 380, 8, 4, Color(1.0, 0.94, 0.65))

## Trilha dourada pontilhada: do Mercadão ao Ferro-velho, daí ao Beco, à Arena e aos Telhados.
func _trilha(t: float) -> void:
	var trechos: Array = [[252.0, 412.0, 716.0, 412.0], [716.0, 380.0, 716.0, 412.0], [418.0, 204.0, 418.0, 240.0], [418.0, 388.0, 418.0, 444.0]]
	var kk: int = 0
	for s in trechos:
		var comp: float = maxf(absf(s[2] - s[0]), absf(s[3] - s[1]))
		var n: int = int(comp / 16.0)
		for k in range(0, n + 1):
			var u: float = float(k) / maxf(float(n), 1.0)
			var px: float = snappedf(lerpf(s[0], s[2], u), 4.0)
			var py: float = snappedf(lerpf(s[1], s[3], u), 4.0)
			var br: float = 0.5 + 0.5 * sin(t * 5.0 - float(kk) * 0.5)
			_r(px - 4, py - 4, 8, 8, C_CONTORNO)
			_r(px - 2, py - 2, 4, 4, C_OURO.lerp(Color(1.0, 0.97, 0.7), br))
			kk += 1

## Cada lugar: quadro com o tema, véu se falta ou se está fechado, bicho da gangue, plaquinha, número e selo.
func _lugar_ruas(f: int, t: float, est: Estado, d: int) -> void:
	var fi: int = f - 1
	var r: Rect2 = RUAS[fi]
	var aberto: bool = est.lugar_aberto(3, f)
	var feito: bool = est.vencido[fi] >= 3
	var hov: bool = d == f
	_o = r.position + Vector2(4, 4)
	_iw = r.size.x - 8.0
	_ih = r.size.y - 8.0
	_rr(r.grow(4.0), C_CONTORNO)
	_tema_ruas(fi, r, t)
	_moldura(r, 4.0, Fases.GANGUE_COR[fi].darkened(0.1))
	if feito:
		_rr(r, Color(1.0, 0.86, 0.45, 0.07))
	elif not aberto:
		_rr(r, Color(0.02, 0.02, 0.08, 0.6))
	else:
		_rr(r, Color(0.02, 0.02, 0.08, 0.15))
		if hov:
			_rr(r, Color(1.0, 0.88, 0.5, 0.12 + 0.04 * sin(t * 6.0)))
	var pulo: float = absf(sin(t * 7.0)) * 8.0 if hov and aberto else 0.0
	var esc: float = 0.7 if r.size.y > 120.0 else 0.5
	Desenho.boneco(cv, Vector2(r.end.x - 40.0, r.end.y - 10.0 - pulo), esc, -1.0, 1, VAZIO, 0.0, t * 2.0 + f, false, 0.0, 1.0 if aberto else 0.5, false, -1, 0.0, 0, false, false, fi + Fases.TOTAL * 2, false, -1, false, false, 0, false, fi)
	_placa_ruas(fi, feito, aberto, t)
	# número da ordem do caminho
	var bx: float = r.position.x + 8.0
	var by: float = r.end.y - 36.0
	_r(bx, by, 28, 28, C_CONTORNO)
	_r(bx + 4, by + 4, 20, 20, C_OURO)
	_r(bx + 4, by + 4, 20, 4, Color(1.0, 0.94, 0.6))
	Desenho.texto(cv, str(f), Vector2(bx + 8, by + 21), 16, Color(0.22, 0.12, 0.06))
	if feito:
		_selo()
	elif not aberto:
		_cadeado()
	if hov and aberto:
		_rr(r, Color(1, 1, 1, 0.07))

func _placa_ruas(fi: int, feito: bool, aberto: bool, t: float) -> void:
	var nome: String = Fases.nome_do_lugar(fi + Fases.TOTAL * 2)
	var w: float = ceilf((_largura(nome, 14) + 16.0) / 4.0) * 4.0
	var x: float = RUAS[fi].position.x + 4.0
	var y: float = RUAS[fi].position.y + 4.0
	_r(x, y, w, 28, C_CONTORNO)
	_r(x + 4, y + 4, w - 8, 20, Color(0.42, 0.28, 0.17))
	_r(x + 4, y + 4, w - 8, 4, Color(0.58, 0.4, 0.24))
	Desenho.texto(cv, nome, Vector2(x + 8, y + 19), 14, Color(1, 0.94, 0.8, 1.0 if aberto else 0.7))
	var txt: String = "feito" if feito else ("falta" if aberto else "fechado")
	var cw: float = ceilf((_largura(txt, 13) + 20.0) / 4.0) * 4.0
	var cor: Color = Color(0.4, 0.82, 0.45) if feito else (C_OURO.lerp(Color(1.0, 0.97, 0.7), 0.5 + 0.5 * sin(t * 4.0)) if aberto else Color(0.55, 0.55, 0.62))
	_r(x, y + 26, cw, 24, C_CONTORNO)
	_r(x + 4, y + 30, cw - 8, 16, cor)
	_r(x + 4, y + 30, cw - 8, 4, cor.lightened(0.3))
	Desenho.texto(cv, txt, Vector2(x + 10, y + 43), 13, Color(0.14, 0.09, 0.05))

## Miniatura de cada lugar, só com quadrados da grade de 4 px: o tema e a gangue à primeira vista.
func _tema_ruas(fi: int, r: Rect2, t: float) -> void:
	var x: float = r.position.x
	var y: float = r.position.y
	var w: float = r.size.x
	var h: float = r.size.y
	match fi:
		0:
			# Mercadão do Peixe: madrugada, barracas de toldo listrado, caixotes de gelo
			_r(x, y, w, h, Color(0.07, 0.15, 0.2))
			_r(x, y + h - 52, w, 52, Color(0.22, 0.3, 0.33))
			_r(x, y + 56, w, 4, Color(0.1, 0.2, 0.28))
			_disco(x + w - 36, y + 36, 12.0, Color(0.92, 0.96, 0.88))
			for b in 2:
				var bx: float = x + 12.0 + b * 104.0
				for s in 6:
					_r(bx + s * 16.0, y + 72, 16, 16, Color(0.62, 0.12, 0.22) if s % 2 == 0 else Color(0.93, 0.88, 0.75))
				_r(bx, y + 88, 96, 4, C_CONTORNO)
				_r(bx + 4, y + 92, 4, 28, C_MADEIRA_ESC)
				_r(bx + 88, y + 92, 4, 28, C_MADEIRA_ESC)
				_r(bx + 8, y + 108, 80, 16, C_MADEIRA)
				_r(bx + 8, y + 104, 80, 4, Color(0.66, 0.86, 0.94))
				_r(bx + 20, y + 100, 16, 4, Color(0.9, 0.5, 0.42))
				_r(bx + 52, y + 100, 20, 4, Color(0.62, 0.72, 0.82))
			_r(x + 188, y + 124, 20, 16, Color(0.66, 0.86, 0.94))
		1:
			# Ferro-velho: pôr do sol, pilha de carros, pneus, barril laranja
			_r(x, y, w, 40, Color(0.28, 0.12, 0.26))
			_r(x, y + 40, w, 36, Color(0.7, 0.34, 0.2))
			_disco(x + 52, y + 76, 20.0, Color(1.0, 0.78, 0.4))
			_r(x, y + 76, w, h - 76, Color(0.4, 0.28, 0.2))
			var cc: Array = [Color(0.55, 0.22, 0.17), Color(0.26, 0.36, 0.46), Color(0.62, 0.5, 0.2)]
			for c in 3:
				var cy: float = y + 108.0 - c * 20.0
				_r(x + 96 - c * 6, cy, 72, 20, cc[c])
				_r(x + 112 - c * 6, cy - 8, 36, 8, cc[c])
				_r(x + 104 - c * 6, cy + 16, 8, 8, C_CONTORNO)
				_r(x + 152 - c * 6, cy + 16, 8, 8, C_CONTORNO)
			for k in 4:
				_r(x + 16, y + 112 - k * 8, 40, 8, Color(0.06, 0.06, 0.08))
				_r(x + 24, y + 112 - k * 8, 24, 4, Color(0.18, 0.18, 0.2))
			_r(x + 184, y + 84, 28, 32, Color(0.8, 0.36, 0.1))
			_r(x + 184, y + 92, 28, 4, Color(0.4, 0.15, 0.05))
			_r(x + 196, y + 68, 8, 16, Color(1.0, 0.6, 0.2) if int(t * 6.0) % 2 == 0 else Color(1.0, 0.85, 0.3))
			_r(x + 220, y + 20, 4, 96, Color(0.42, 0.22, 0.13))
		2:
			# Beco do Fliperama: tijolo, letreiro de néon, fileira de fliperamas
			_r(x, y, w, h, Color(0.14, 0.1, 0.26))
			for by in range(int(y) + 8, int(y + h), 16):
				_r(x, by, w, 4, Color(0.08, 0.06, 0.17))
			_r(x + 28, y + 16, 180, 20, Color(0.03, 0.02, 0.08))
			_r(x + 36, y + 24, 164, 4, Color(0.2, 0.85, 0.95) if int(t * 3.0) % 5 != 0 else Color(0.1, 0.4, 0.45))
			var cores: Array = [Color(0.2, 0.85, 0.95), Color(0.9, 0.25, 0.65), Color(1.0, 0.55, 0.15)]
			for k in 5:
				var fx: float = x + 16.0 + k * 40.0
				_r(fx, y + 56, 32, 64, Color(0.07, 0.06, 0.15))
				_r(fx + 4, y + 64, 24, 20, cores[k % 3])
				_r(fx + 12, y + 72, 8, 4, Color(1, 1, 1, 0.8))
				_r(fx + 4, y + 92, 24, 4, Color(0.2, 0.18, 0.34))
			_r(x, y + h - 16, w, 16, Color(0.14, 0.2, 0.3))
			for k in range(0, int(w), 24):
				_r(x + k, y + h - 16, 4, 16, Color(0.2, 0.85, 0.95, 0.35))
		3:
			# Arena da Praça: praça de pedra, colunas, estandartes vermelhos, estátua
			_r(x, y, w, 56, Color(0.2, 0.15, 0.22))
			_r(x, y + 56, w, h - 56, Color(0.42, 0.37, 0.34))
			for k in 6:
				_r(x + 12 + k * 36, y + 40, 16, 16, Color(0.06, 0.04, 0.08))
				_r(x + 16 + k * 36, y + 32, 8, 8, Color(0.06, 0.04, 0.08))
			for cx in [x + 20.0, x + w - 40.0]:
				_r(cx, y + 24, 20, 8, Color(0.62, 0.58, 0.55))
				_r(cx + 4, y + 32, 12, 76, Color(0.55, 0.5, 0.48))
				_r(cx, y + 108, 20, 8, Color(0.62, 0.58, 0.55))
				_r(cx + 4, y + 36, 12, 28, Color(0.72, 0.14, 0.1))
			_r(x + w * 0.5 - 12, y + 84, 24, 32, Color(0.62, 0.58, 0.55))
			_r(x + w * 0.5 - 8, y + 52, 16, 32, Color(0.7, 0.66, 0.62))
			_r(x + w * 0.5 - 4, y + 44, 8, 8, Color(0.7, 0.66, 0.62))
			_r(x + w * 0.5 + 12, y + 40, 4, 44, Color(0.6, 0.6, 0.66))
			for k in 8:
				_r(x + 40 + k * 20, y + h - 20 + (k % 2) * 4, 12, 4, Color(0.32, 0.28, 0.27))
		_:
			# Telhados e Antenas: noite roxa, arranha-céus, torre de rádio com raio, caixa d'água
			_r(x, y, w, h, Color(0.12, 0.07, 0.24))
			for k in 7:
				var bh: float = 24.0 + float((k * 5) % 4) * 10.0
				_r(x + k * 34.0, y + h - bh, 30, bh, Color(0.09, 0.05, 0.19))
				for wy in range(int(y + h - bh + 6), int(y + h - 6), 12):
					if _ruido(k * 7.0 + wy) > 0.5:
						_r(x + k * 34.0 + 8, wy, 4, 4, Color(1.0, 0.82, 0.45))
			var tx: float = x + w - 60.0
			for k in 8:
				_r(tx - 12 + k * 1.5, y + 8 + k * 10, 24 - k * 3, 4, Color(0.4, 0.36, 0.55))
			_r(tx - 2, y + 8, 4, h - 8, Color(0.4, 0.36, 0.55))
			_r(tx - 2, y + 4, 4, 4, Color(1.0, 0.25, 0.2) if int(t * 2.0) % 2 == 0 else Color(0.4, 0.1, 0.1))
			_r(x + 140, y + h - 56, 36, 28, Color(0.17, 0.13, 0.3))
			_r(x + 144, y + h - 28, 4, 24, Color(0.3, 0.26, 0.4))
			_r(x + 168, y + h - 28, 4, 24, Color(0.3, 0.26, 0.4))
			if int(t * 2.5) % 6 == 0:
				for k in 5:
					_r(x + 180 - (k % 2) * 8 + k * 2, y + 4 + k * 12, 8, 8, Color(0.95, 0.9, 1.0))

# ------------------------------------------------------------------ painel lateral
func _painel_lateral(f: int) -> void:
	var est: Estado = p.estado
	var fi: int = f - 1
	var ato_m: int = _av()                          # ato que o painel descreve
	var li: int = fi + (Fases.TOTAL * (ato_m - 1) if _fora else 0)   # índice nas tabelas: fora da casa (2º ato) ou nas ruas (3º)
	var bloq: bool = f > est.fase_liberada or (_ruas and not est.lugar_aberto(3, f))
	var venc: bool = est.vencido[fi] >= ato_m if _fora else f <= est.fases_vencidas
	var prox: bool = not bloq and not venc and f == est.fase_liberada and not _fora
	var al: float = 0.55 if bloq else 1.0
	var tom: Color = p.COR_COMODO[li]
	p._painel(PAINEL, Color(0.1, 0.06, 0.1, 0.97), 0.5, Color.WHITE)
	var x0: float = PAINEL.position.x + 24.0     # 884
	var larg: float = PAINEL.size.x - 48.0       # 340
	# O retrato tem área própria (caixa `RETRATO`): o chefe e o bicho são desenhados nela e o que escapar
	# para cima, para a direita ou para baixo é coberto com a cor do painel ANTES de qualquer texto.
	var anim: float = p.t * 2.0 + f
	var chefes: Array = p._chefes_mapa
	var fundo_p := Color(0.1, 0.06, 0.1, 1.0)
	cv.draw_rect(RETRATO, Color(0.16, 0.1, 0.17))
	Desenho.boneco(cv, Vector2(RETRATO.position.x + 100.0, RETRATO.end.y - 6.0), RETRATO_ESCALA * Balanco.CHEFE_ESCALA_TIPO[Fases.chefe_base(li)], -1.0, 1, chefes[li], 0.0, anim, false, 0.0, al, false, -1, 0.0, 0, false, true, Fases.chefe_base(li), false, Fases.chefe_base(li))
	Desenho.boneco(cv, Vector2(RETRATO.position.x + 30.0, RETRATO.end.y - 6.0), 0.6, -1.0, 1, VAZIO, 0.0, anim + 1.0, false, 0.0, al, false, -1, 0.0, 0, false, false, li, false, -1, false, false, 0, false, (li - Fases.TOTAL * 2) if li >= Fases.TOTAL * 2 else -1)
	cv.draw_rect(Rect2(PAINEL.position.x + 8.0, PAINEL.position.y + 8.0, PAINEL.size.x - 16.0, RETRATO.position.y - PAINEL.position.y - 8.0), fundo_p)
	cv.draw_rect(Rect2(RETRATO.end.x, RETRATO.position.y - 2.0, PAINEL.end.x - 8.0 - RETRATO.end.x, RETRATO.size.y + 4.0), fundo_p)
	cv.draw_rect(Rect2(PAINEL.position.x + 8.0, RETRATO.end.y, PAINEL.size.x - 16.0, 366.0 - RETRATO.end.y), fundo_p)
	cv.draw_rect(RETRATO, Color(1, 1, 1, 0.18), false, 1.0)
	# nome e situação
	var nome: String = Fases.nome_do_lugar(li)
	var tn: int = p._tam_cabe(nome, [28, 26, 24], 200.0)
	Desenho.texto(cv, nome, Vector2(x0, 156), tn, p._com_alfa(Color(1, 0.95, 0.8), al), -1.0, 5)
	var chip := Rect2(x0 + larg - 120.0, 132.0, 120.0, 28.0)
	if venc:
		p._botao_arte(chip, Color(0.6, 0.95, 0.6))
	elif bloq:
		p._botao_arte(chip, Color(0.45, 0.45, 0.5))
	else:
		p._botao_arte(chip, Color(1.0, 0.82 + 0.1 * sin(p.t * 4.0), 0.35) if prox else Color(0.75, 0.85, 1.0))
	var rotulo: String = String(p.VENCIDO_GENERO[fi]).capitalize() if venc else ("Bloqueado" if bloq else ("Próximo" if prox else "Liberado"))
	var falta_ato: bool = _fora and not venc and not bloq
	if falta_ato:
		p._botao_arte(chip, Color(1.0, 0.82 + 0.1 * sin(p.t * 4.0), 0.35))
		rotulo = "%dº ato: falta" % ato_m
	elif _fora:
		rotulo = "%dº ato: feito" % ato_m
	Desenho.texto(cv, rotulo, Vector2(chip.position.x, chip.position.y + 20), 16, Color(0.95, 0.95, 1, 0.9) if bloq else p.COR_TINTA_ESC, chip.size.x)
	# família e a dica dela
	var fam_txt: String = "Família: " + Fases.FAMILIA_NOME[fi]
	var fam_dica: String = Fases.FAMILIA_DICA[fi]
	if _fora:
		var dg: int = mini(est.vencidos_no_ato(ato_m), Fases.TOTAL - 1)
		fam_txt = "%s · %s" % [Balanco.ATO_NOME[ato_m - 1], Fases.grupo_nome(li)]
		fam_dica = "%s. Lugar deixado para depois chega mais forte (agora: +%d%% de vida)." % [Fases.grupo_dica(li), int(round(Balanco.ATO_VIDA_DEGRAU * dg * 100.0))]
	Desenho.texto(cv, fam_txt, Vector2(x0, 182), 16, p._com_alfa(tom.lightened(0.4), al))
	var tam_d: int = 12 if _fora else 13     # lá fora a dica é mais longa (leva o aviso de vida extra)
	var ld: Array[String] = p._quebrar(fam_dica, tam_d, larg)
	for k in mini(ld.size(), 3 if _fora else 2):
		Desenho.texto(cv, ld[k], Vector2(x0, 200.0 + (14.0 if _fora else 16.0) * k + (0.0 if _fora else 2.0)), tam_d, Color(1, 1, 1, 0.85 * al))
	_sep(x0, larg, 232.0)
	# retratos: o chefe (atrás, maior) e um bicho da família na frente
	var xr: float = 1044.0
	var lr: float = PAINEL.end.x - 24.0 - xr      # 180
	Desenho.texto(cv, "Chefe", Vector2(xr, 262), 13, Color(1, 1, 1, 0.65 * al))
	var cn: String = Fases.nome_do_chefe(li)
	var tc: int = p._tam_cabe(cn, [22, 20, 18, 16], lr)
	Desenho.texto(cv, cn, Vector2(xr, 288), tc, p._com_alfa(Desenho.DOURADO, al), -1.0, 4)
	var oferta: bool = est.campanha_vencida() and not bloq
	if oferta:
		if _fora:
			# lá fora: jogar o lugar; a invasão sem fim só aparece depois de vencê-lo no 2º ato
			_botao_painel(BT_JOGAR, ("Jogar o %dº ato" % ato_m) if falta_ato else "Jogar de novo", UIComum.B_VERDE)
			if invasao_fora_liberada(f):
				_botao_painel(BT_INVASAO, "Invasão sem fim", UIComum.B_LARANJA)
			else:
				# nas ruas não existe invasão sem fim (por enquanto); no lado de fora ela abre ao vencer o lugar no 2º ato
				var aviso: String = "Nas ruas ainda não há invasão sem fim." if _ruas else "Vença no 2º ato para liberar a invasão"
				var lv: Array[String] = p._quebrar(aviso, 12, lr)
				for k in mini(lv.size(), 2):
					Desenho.texto(cv, lv[k], Vector2(xr, 348.0 + 14.0 * k), 12, Color(1, 1, 1, 0.5))
		elif _ato > 1:
			# a casa depois do 1º ato: repetir o cômodo (força do 1º ato) ou a invasão sem fim; o 2º ato fica lá fora
			_botao_painel(BT_JOGAR, "Jogar de novo", UIComum.B_VERDE)
			_botao_painel(BT_INVASAO, "Invasão sem fim", UIComum.B_LARANJA)
		else:
			# campanha zerada: o jogador escolhe entre o cômodo de sempre e a invasão sem fim
			_botao_painel(BT_JOGAR, "Jogar de novo", UIComum.B_VERDE)
			_botao_painel(BT_INVASAO, "Invasão sem fim", UIComum.B_LARANJA)
	else:
		var dica: String = "Clique ou Enter para entrar"
		if bloq:
			dica = _texto_bloqueio_ruas(f) if _ruas else "Vença antes: %s" % Fases.NOME[fi - 1]
		var lh: Array[String] = p._quebrar(dica, 13, lr)
		for k in mini(lh.size(), 3):
			Desenho.texto(cv, lh[k], Vector2(xr, 314.0 + 16.0 * k), 13, Color(1, 0.95, 0.7, 0.9) if not bloq else Color(1, 1, 1, 0.5))
	_sep(x0, larg, 366.0)
	# ataque e fraqueza do chefe
	Desenho.texto(cv, "Ataque do chefe", Vector2(x0, 386), 13, p._com_alfa(Color(1.0, 0.72, 0.55), al))
	var la: Array[String] = p._quebrar(Fases.ataque_do_chefe(li), 13, larg)
	for k in mini(la.size(), 3):
		Desenho.texto(cv, la[k], Vector2(x0, 402.0 + 15.0 * k), 13, Color(1, 1, 1, 0.9 * al))
	Desenho.texto(cv, "Fraqueza", Vector2(x0, 449), 13, p._com_alfa(Color(0.75, 1.0, 0.8), al))
	var lf: Array[String] = p._quebrar(Fases.fraqueza_do_chefe(li), 13, larg)
	for k in mini(lf.size(), 2):
		Desenho.texto(cv, lf[k], Vector2(x0, 465.0 + 15.0 * k), 13, p._com_alfa(Color(0.75, 1.0, 0.8), al))
	_sep(x0, larg, 492.0)
	# fantasias que caem (o nome completo sai na dica do mouse)
	Desenho.texto(cv, "Fantasias que caem", Vector2(x0, 512), 13, Color(1, 1, 1, 0.65 * al))
	var conjs: Array = Fases.lista_do_lugar(li)
	for k in conjs.size():
		var c: int = conjs[k]
		var pc: Vector2 = centro_fantasia(k)
		var cor_c: Color = Pecas.CONJUNTO_COR[c]
		var sobre: bool = not bloq and p.mouse.distance_to(pc) < 18.0
		# moldura em pixel: discos de faixas de 4 px (contorno, aro na cor da fantasia, miolo escuro), já
		# misturados com o fundo do painel em vez de alfa sobre alfa (cômodo bloqueado fica apagado)
		var pq := Vector2(snappedf(pc.x, 4.0), snappedf(pc.y, 4.0))
		var fundo_m := Color(0.1, 0.06, 0.1)
		var aro: Color = cor_c.lightened(0.15) if not sobre else Color.WHITE
		Oficina.grade(cv, PX_MOEDA, pq - Vector2(20.0, 20.0), 4.0, fundo_m.lerp(aro, al), fundo_m.lerp(cor_c.darkened(0.55), al), fundo_m.lerp(aro.lightened(0.5), al), fundo_m.lerp(Color(0.03, 0.02, 0.04), al))
		Desenho.icone(cv, Pecas.CONJUNTO_PECAS[c][0], pq, 24.0)
	if oferta and (not _fora or invasao_fora_liberada(f)):
		# recorde da invasão neste lugar (cômodo ou, lá fora, o lugar de fora: posições 5..9), ao lado das fantasias
		var rec: int = est.recordes[li]
		var txt_rec: String = "Recorde: onda %d" % rec if rec > 0 else "Sem recorde ainda"
		var chip_r := Rect2(x0, 563.0, larg, 26.0)
		cv.draw_rect(chip_r, Color(0.3, 0.22, 0.08, 0.9) if rec > 0 else Color(0.15, 0.1, 0.12, 0.9))
		cv.draw_rect(chip_r, Desenho.DOURADO if rec > 0 else Color(1, 1, 1, 0.2), false, 2.0)
		Desenho.texto(cv, "Invasão sem fim  ·  " + txt_rec, Vector2(x0, 582), 15, Desenho.DOURADO if rec > 0 else Color(1, 1, 1, 0.6), larg, 3)

## O que falta vencer no 3º ato para abrir o lugar `f` (4 = Arena da Praça, 5 = Telhados e Antenas).
static func _texto_bloqueio_ruas(f: int) -> String:
	if f == 4:
		return "Vença antes: %s, %s e %s" % [Fases.NOME_ATO3[0], Fases.NOME_ATO3[1], Fases.NOME_ATO3[2]]
	return "Vença antes: %s" % Fases.NOME_ATO3[3]

## Botão do painel lateral: moldura de papel com realce quando o mouse está em cima.
func _botao_painel(r: Rect2, txt: String, cor: Color) -> void:
	var id: int = BOTAO_JOGAR if r == BT_JOGAR else (BOTAO_INVASAO if r == BT_INVASAO else (BOTAO_VISTA if r == BT_VISTA else BOTAO_FINAL))
	var sobre: bool = p.mouse != Vector2(-500, -500) and r.has_point(p.mouse)
	UIComum.botao(cv, r, txt, cor, {"on": true, "foco": sobre, "h": UIComum.anim_h(_anim, str(id)), "p": UIComum.anim_p(_anim, str(id)), "tam": 16}, p.t)

## Botão discreto "Final", no canto do mapa, depois de zerar a campanha.
func _botao_final() -> void:
	_botao_painel(BT_FINAL, "Final", UIComum.B_MARROM)

static func _rect_botao(id: int) -> Rect2:
	match id:
		BOTAO_JOGAR:
			return BT_JOGAR
		BOTAO_INVASAO:
			return BT_INVASAO
		BOTAO_VISTA:
			return BT_VISTA
	return BT_FINAL

## Botão pequeno e discreto do canto: alterna entre a casa e o lado de fora (segundo ato).
func _botao_vista() -> void:
	var txt: String = "Ver lá fora"
	if _ato >= 3:
		txt = "Ver a casa" if _ruas else ("Ver as ruas" if _fora else "Ver lá fora")
	elif _fora:
		txt = "Ver a casa"
	_botao_painel(BT_VISTA, txt, UIComum.B_AZUL)

## Separador em pixel: pontilhado de quadradinhos de 4 px na grade do mapa (um a cada dois).
func _sep(x0: float, larg: float, y: float) -> void:
	var yy: float = floorf(y / 4.0) * 4.0
	var x: float = ceilf(x0 / 4.0) * 4.0
	while x + 4.0 <= x0 + larg:
		_r(x, yy, 4.0, 4.0, Color(1, 1, 1, 0.18))
		x += 8.0

## Dica do mouse: nome completo da fantasia sob o ícone (só em cômodo liberado, como no cartão).
func _dica_casa(f: int) -> void:
	var est: Estado = p.estado
	if f > est.fase_liberada:
		return
	var conjs: Array = Fases.lista_do_lugar(f - 1 + (Fases.TOTAL * (_av() - 1) if _fora else 0))
	for k in conjs.size():
		if p.mouse.distance_to(centro_fantasia(k)) < 18.0:
			var c: int = conjs[k]
			var cor: Color = Pecas.CONJUNTO_COR[c]
			var itens: Array = [
				["t", Pecas.CONJUNTO_NOME[c], 22, cor.lightened(0.3)],
				["t", "2 a 3 peças: " + Pecas.conjunto_bonus(c, 1), 13, Color(1, 1, 1, 0.9)],
				["t", "4 peças: " + Pecas.conjunto_bonus(c, 2), 13, Color(1, 1, 1, 0.9)],
				["t", "Poder: " + Pecas.PODER_NOME[c], 13, Color(1.0, 0.9, 0.5)],
			]
			p._caixa_dica(itens, 300.0, cor, cor, p.mouse, Vector2(16, -20))
			return
