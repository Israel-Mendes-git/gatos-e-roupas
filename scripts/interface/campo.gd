class_name Campo
extends Node2D
## Vista do combate: desenha a Simulacao e transforma eventos em efeitos.

signal terminou(vitoria: bool)

const ESC := 1.35
## Pixel uniforme: no desenho das unidades 1 pixel do sprite = PX_SPRITE px de tela (a grade do cenário, 4 px).
## ESC_PX = PX_SPRITE / Desenho.GATO_K. Bicho com Unidade.escala() >= ESCALA_GRADE_2 (o grandalhão) usa a escala 2
## da grade (8 px); chefe usa CHEFE_GRADE (Gambá e Esquilo ficam em 4 px: já são grandes na própria grade e a 8 px
## passariam de 4x a altura de um gato). Só o desenho: Unidade.escala() e as distâncias do jogo não mudam.
const PX_SPRITE := 4.0
const ESC_PX := 1.25
const ESCALA_GRADE_2 := 1.3
const CHEFE_GRADE: Array[float] = [2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 1.0, 1.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0]   # por Fases.Chefe (10..15: chefes gatos do 3º ato e Schrödinger)
static func esc_tela(u: Unidade) -> float:
	if u.chefe:
		return ESC_PX * CHEFE_GRADE[clampi(u.chefe_tipo, 0, CHEFE_GRADE.size() - 1)]
	return ESC_PX * (2.0 if u.escala() >= ESCALA_GRADE_2 else 1.0)
static func px_grade(p: Vector2) -> Vector2:
	return Vector2(roundf(p.x / PX_SPRITE) * PX_SPRITE, roundf(p.y / PX_SPRITE) * PX_SPRITE)
const V := preload("res://scripts/interface/vfx_px.gd")   # pedaços de pixel art dos efeitos
const BAU_POS := Vector2(1205, 672)
const TORRE_BASE := Vector2(10, 652)
## Base da torre alinhada à grade de 4 px quando ela é desenhada em pixel.
static func torre_base_grade() -> Vector2:
	return Vector2(roundf(TORRE_BASE.x / 4.0) * 4.0, TORRE_BASE.y) if TORRE_EM_PIXEL else TORRE_BASE
## Corpo baixo e comprido (gato e bichos de quatro patas): ~70 de largura por ~55 de altura
## em unidades locais, antes da escala. Tudo que fica "em cima" ou "no meio" do corpo usa isto.
const CORPO_ALT := 58.0     # topo da cabeça/orelhas
const CORPO_MEIO := 28.0    # centro do corpo
const CORPO_LARG := 38.0    # meia largura (nariz a rabo)
const TIRO_ALT := 30.0      # altura em que projéteis saem e acertam

# ---- Chaves de liga/desliga do cenário em pixel art (troque true por false para voltar atrás) ----
const CENARIO_TONS := 20              # tons por canal do sombreador (menos tons = pontilhado mais ruidoso)
const CENARIO_PONTILHADO := true      # false: só quantiza as cores, sem pontilhar
const CENARIO_PISO_MATERIAL := true   # false: piso liso antigo (tábuas simples) em todos os cômodos
const CENARIO_SOMBRAS := true         # sombras de móveis num tom só, para o lado oposto à luz
const CENARIO_LUZ := true             # luz principal em degraus
const CENARIO_SILHUETAS := true       # silhuetas de primeiro plano e vinheta
const TORRE_EM_PIXEL := true          # blocos da torre na grade de pixel (letras em resolução cheia)
const CAIXA_EM_PIXEL := true          # caixa de peças na grade de pixel
const CENARIOS_DE_FORA := true         # cenas 6..10 (quintal, garagem, telhado, rua, toca) desenhadas; false: o ato 2 reaproveita os cômodos 1..5
const TORRE_FORTALEZA := true         # false: volta à pilha de blocos antiga (os efeitos dos módulos continuam)
const TORRE_VIGIA := true             # false: sem o gatinho vigia no alto da torre
const TROFEU_CONTADOR := Vector2(14, 694)   # canto de cima do ícone do contador de troféus (HUD)

# ---- Barra de poderes (um botão por gato com fantasia completa) ----
# Fica abaixo do chão da luta (que termina em Balanco.CHAO_Y1 = 640), à direita da torre
# (que ocupa x < TorrePx.FAIXA_LUTA_X = 200) e à esquerda da caixa de peças (x > 1170).
const PB_W := 164.0
const PB_H := 62.0
const PB_GAP := 6.0
const PB_Y := 650.0
const PB_CENTRO_X := 640.0
const BOT_TEX: Texture2D = preload("res://assets/terceiros/gui/botoes_4x.png")
const GUI_TEX: Texture2D = preload("res://assets/terceiros/gui/gui_4x.png")
const R_BT_N := Rect2(132, 4, 88, 56)     # botão solto
const R_BT_P := Rect2(228, 8, 88, 52)     # botão apertado
const M_BT := Vector4(16, 16, 16, 16)
const R_MADEIRA := Rect2(8, 136, 80, 80)  # moldura de madeira
const M_MADEIRA := Vector4(28, 28, 28, 28)
const SOMBRA_COR := Color(0.03, 0.02, 0.07)
const SOMBRA_ALFA := 0.32

# ---- Paleta por cômodo ----
## Luminância no mesmo critério usado para checar a legibilidade (0,3R + 0,59G + 0,11B).
static func lum_cor(c: Color) -> float:
	return 0.3 * c.r + 0.59 * c.g + 0.11 * c.b

## Mantém o matiz e a saturação da cor e ajusta só o brilho até a luminância "alvo".
static func tom_lum(c: Color, alvo: float) -> Color:
	var k: float = alvo / maxf(lum_cor(c), 0.001)
	return Color(minf(c.r * k, 1.0), minf(c.g * k, 1.0), minf(c.b * k, 1.0))

## Paleta limitada do cômodo (fase 1 a 5). Os tons do chão e da parede baixa são calculados
## pela luminância-alvo, para os personagens claros e escuros se destacarem:
##   chão (piso_*, junta, tapete_*): 0,245 a 0,30  |  parede junto ao chão (parede_baixa, rodape): 0,165 a 0,20.
## "luz_extra" é a luminância que a luz do cômodo soma ao chão no pior ponto, "vinheta" o quanto
## as bordas escurecem; o script de conta (checa_cenarios.gd) usa os dois.
static func paleta(fase: int) -> Dictionary:
	match fase:
		2:  # SALA: vinho e madeira, luz laranja da lareira
			return {
				"nome": "Sala", "luz_dir": 1.0, "luz_extra": 0.04, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.30, 0.11, 0.15),
				"parede_baixa": tom_lum(Color(0.36, 0.17, 0.15), 0.165),
				"rodape": tom_lum(Color(0.45, 0.28, 0.20), 0.20),
				"piso_a": tom_lum(Color(0.50, 0.37, 0.30), 0.29),
				"piso_b": tom_lum(Color(0.50, 0.37, 0.30), 0.265),
				"junta": tom_lum(Color(0.45, 0.33, 0.28), 0.245),
				"tapete_borda": tom_lum(Color(0.50, 0.28, 0.28), 0.285),
				"tapete_meio": tom_lum(Color(0.42, 0.21, 0.23), 0.26),
				"tapete_dentro": tom_lum(Color(0.47, 0.26, 0.26), 0.275),
				"tapete_motivo": tom_lum(Color(0.58, 0.45, 0.33), 0.30),
				"franja": Color(0.85, 0.72, 0.5),
				"madeira": Color(0.42, 0.27, 0.18), "movel": Color(0.10, 0.07, 0.11),
				"acento_a": Color(0.17, 0.25, 0.38), "acento_b": Color(0.80, 0.55, 0.25),
				"luz": Color(1.0, 0.55, 0.20),
			}
		3:  # COZINHA: verde-água e creme, luz branca fria
			return {
				"nome": "Cozinha", "luz_dir": 1.0, "luz_extra": 0.03, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": tom_lum(Color(0.28, 0.50, 0.48), 0.205),
				"parede_baixa": tom_lum(Color(0.30, 0.45, 0.42), 0.165),
				"rodape": tom_lum(Color(0.45, 0.55, 0.52), 0.20),
				"piso_a": tom_lum(Color(0.55, 0.58, 0.52), 0.30),
				"piso_b": tom_lum(Color(0.50, 0.58, 0.55), 0.275),
				"junta": tom_lum(Color(0.45, 0.52, 0.50), 0.245),
				"tapete_borda": tom_lum(Color(0.55, 0.58, 0.52), 0.30),
				"tapete_meio": tom_lum(Color(0.55, 0.58, 0.52), 0.30),
				"tapete_dentro": tom_lum(Color(0.55, 0.58, 0.52), 0.30),
				"tapete_motivo": tom_lum(Color(0.55, 0.58, 0.52), 0.30),
				"franja": Color(0.9, 0.88, 0.75),
				"madeira": tom_lum(Color(0.60, 0.50, 0.38), 0.225), "movel": Color(0.20, 0.30, 0.30),
				"acento_a": Color(0.93, 0.90, 0.78), "acento_b": Color(0.85, 0.50, 0.30),
				"luz": Color(0.85, 0.93, 1.0),
			}
		4:  # SÓTÃO: anil e madeira clara, luar azul
			return {
				"nome": "Sótão", "luz_dir": 1.0, "luz_extra": 0.03, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.15, 0.14, 0.30),
				"parede_baixa": tom_lum(Color(0.25, 0.24, 0.42), 0.165),
				"rodape": tom_lum(Color(0.40, 0.33, 0.38), 0.20),
				"piso_a": tom_lum(Color(0.58, 0.50, 0.42), 0.30),
				"piso_b": tom_lum(Color(0.58, 0.50, 0.42), 0.27),
				"junta": tom_lum(Color(0.50, 0.44, 0.40), 0.245),
				"tapete_borda": tom_lum(Color(0.58, 0.50, 0.42), 0.30),
				"tapete_meio": tom_lum(Color(0.58, 0.50, 0.42), 0.30),
				"tapete_dentro": tom_lum(Color(0.58, 0.50, 0.42), 0.30),
				"tapete_motivo": tom_lum(Color(0.58, 0.50, 0.42), 0.30),
				"franja": Color(0.7, 0.7, 0.8),
				"madeira": Color(0.52, 0.40, 0.30), "movel": Color(0.14, 0.12, 0.24),
				"acento_a": Color(0.45, 0.45, 0.70), "acento_b": Color(0.85, 0.80, 0.65),
				"luz": Color(0.65, 0.78, 1.0),
			}
		5:  # PORÃO: tijolo e cinza, luz amarela fraca
			return {
				"nome": "Porão", "luz_dir": 1.0, "luz_extra": 0.03, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.26, 0.14, 0.13),
				"parede_baixa": tom_lum(Color(0.40, 0.22, 0.20), 0.165),
				"rodape": tom_lum(Color(0.45, 0.45, 0.48), 0.20),
				"piso_a": tom_lum(Color(0.50, 0.50, 0.52), 0.30),
				"piso_b": tom_lum(Color(0.50, 0.50, 0.52), 0.27),
				"junta": tom_lum(Color(0.45, 0.45, 0.50), 0.245),
				"tapete_borda": tom_lum(Color(0.50, 0.50, 0.52), 0.30),
				"tapete_meio": tom_lum(Color(0.50, 0.50, 0.52), 0.30),
				"tapete_dentro": tom_lum(Color(0.50, 0.50, 0.52), 0.30),
				"tapete_motivo": tom_lum(Color(0.50, 0.50, 0.52), 0.30),
				"franja": Color(0.6, 0.6, 0.64),
				"madeira": Color(0.40, 0.28, 0.18), "movel": Color(0.30, 0.31, 0.36),
				"acento_a": Color(0.55, 0.30, 0.25), "acento_b": Color(0.45, 0.60, 0.50),
				"luz": Color(1.0, 0.85, 0.40),
			}
		6:  # QUINTAL: entardecer, grama verde, cerca de madeira
			return {
				"nome": "Quintal", "luz_dir": 1.0, "luz_extra": 0.03, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.14, 0.17, 0.36),
				"parede_baixa": tom_lum(Color(0.40, 0.28, 0.34), 0.185),
				"rodape": tom_lum(Color(0.30, 0.42, 0.22), 0.20),
				"piso_a": tom_lum(Color(0.45, 0.52, 0.38), 0.29),
				"piso_b": tom_lum(Color(0.42, 0.50, 0.38), 0.265),
				"junta": tom_lum(Color(0.38, 0.45, 0.34), 0.245),
				"tapete_borda": tom_lum(Color(0.34, 0.55, 0.26), 0.29),
				"tapete_meio": tom_lum(Color(0.34, 0.55, 0.26), 0.29),
				"tapete_dentro": tom_lum(Color(0.34, 0.55, 0.26), 0.29),
				"tapete_motivo": tom_lum(Color(0.34, 0.55, 0.26), 0.29),
				"franja": Color(0.7, 0.8, 0.5),
				"madeira": Color(0.50, 0.36, 0.24), "movel": Color(0.05, 0.08, 0.07),
				"acento_a": Color(0.85, 0.40, 0.50), "acento_b": Color(0.95, 0.80, 0.35),
				"luz": Color(1.0, 0.70, 0.40),
			}
		7:  # GARAGEM: bloco cinza-azulado, cimento, luz fluorescente
			return {
				"nome": "Garagem", "luz_dir": 1.0, "luz_extra": 0.03, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.20, 0.23, 0.28),
				"parede_baixa": tom_lum(Color(0.30, 0.34, 0.40), 0.185),
				"rodape": tom_lum(Color(0.45, 0.48, 0.52), 0.20),
				"piso_a": tom_lum(Color(0.52, 0.52, 0.50), 0.29),
				"piso_b": tom_lum(Color(0.52, 0.52, 0.50), 0.265),
				"junta": tom_lum(Color(0.46, 0.46, 0.46), 0.245),
				"tapete_borda": tom_lum(Color(0.52, 0.52, 0.50), 0.29),
				"tapete_meio": tom_lum(Color(0.52, 0.52, 0.50), 0.29),
				"tapete_dentro": tom_lum(Color(0.52, 0.52, 0.50), 0.29),
				"tapete_motivo": tom_lum(Color(0.52, 0.52, 0.50), 0.29),
				"franja": Color(0.6, 0.6, 0.64),
				"madeira": Color(0.45, 0.32, 0.20), "movel": Color(0.10, 0.11, 0.15),
				"acento_a": Color(0.75, 0.25, 0.20), "acento_b": Color(0.85, 0.72, 0.25),
				"luz": Color(0.85, 0.95, 1.0),
			}
		8:  # TELHADO: noite funda, telhas de barro azuladas, lua
			return {
				"nome": "Telhado", "luz_dir": -1.0, "luz_extra": 0.03, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.05, 0.07, 0.20),
				"parede_baixa": tom_lum(Color(0.18, 0.20, 0.40), 0.185),
				"rodape": tom_lum(Color(0.45, 0.30, 0.30), 0.20),
				"piso_a": tom_lum(Color(0.55, 0.36, 0.36), 0.29),
				"piso_b": tom_lum(Color(0.50, 0.34, 0.38), 0.262),
				"junta": tom_lum(Color(0.42, 0.28, 0.32), 0.245),
				"tapete_borda": tom_lum(Color(0.55, 0.36, 0.36), 0.29),
				"tapete_meio": tom_lum(Color(0.55, 0.36, 0.36), 0.29),
				"tapete_dentro": tom_lum(Color(0.55, 0.36, 0.36), 0.29),
				"tapete_motivo": tom_lum(Color(0.55, 0.36, 0.36), 0.29),
				"franja": Color(0.7, 0.7, 0.85),
				"madeira": Color(0.35, 0.25, 0.22), "movel": Color(0.03, 0.04, 0.10),
				"acento_a": Color(0.45, 0.50, 0.75), "acento_b": Color(0.95, 0.88, 0.60),
				"luz": Color(0.70, 0.80, 1.0),
			}
		9:  # RUA: asfalto, calçada, poste de luz sódio
			return {
				"nome": "Rua", "luz_dir": 1.0, "luz_extra": 0.04, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.10, 0.10, 0.22),
				"parede_baixa": tom_lum(Color(0.36, 0.22, 0.22), 0.185),
				"rodape": tom_lum(Color(0.50, 0.48, 0.46), 0.20),
				"piso_a": tom_lum(Color(0.58, 0.55, 0.50), 0.30),
				"piso_b": tom_lum(Color(0.52, 0.50, 0.48), 0.27),
				"junta": tom_lum(Color(0.46, 0.44, 0.42), 0.245),
				"tapete_borda": tom_lum(Color(0.45, 0.45, 0.50), 0.25),
				"tapete_meio": tom_lum(Color(0.45, 0.45, 0.50), 0.25),
				"tapete_dentro": tom_lum(Color(0.45, 0.45, 0.50), 0.25),
				"tapete_motivo": tom_lum(Color(0.45, 0.45, 0.50), 0.25),
				"franja": Color(0.8, 0.75, 0.5),
				"madeira": Color(0.40, 0.30, 0.22), "movel": Color(0.05, 0.05, 0.09),
				"acento_a": Color(0.80, 0.15, 0.12), "acento_b": Color(0.95, 0.80, 0.30),
				"luz": Color(1.0, 0.78, 0.38),
			}
		10:  # TOCA: terra, raízes, lanternas âmbar
			return {
				"nome": "Toca", "luz_dir": 1.0, "luz_extra": 0.04, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.17, 0.10, 0.07),
				"parede_baixa": tom_lum(Color(0.34, 0.20, 0.12), 0.185),
				"rodape": tom_lum(Color(0.40, 0.26, 0.16), 0.20),
				"piso_a": tom_lum(Color(0.50, 0.42, 0.35), 0.29),
				"piso_b": tom_lum(Color(0.47, 0.40, 0.34), 0.263),
				"junta": tom_lum(Color(0.42, 0.35, 0.30), 0.245),
				"tapete_borda": tom_lum(Color(0.52, 0.36, 0.24), 0.29),
				"tapete_meio": tom_lum(Color(0.52, 0.36, 0.24), 0.29),
				"tapete_dentro": tom_lum(Color(0.52, 0.36, 0.24), 0.29),
				"tapete_motivo": tom_lum(Color(0.52, 0.36, 0.24), 0.29),
				"franja": Color(0.6, 0.45, 0.3),
				"madeira": Color(0.42, 0.28, 0.16), "movel": Color(0.07, 0.04, 0.03),
				"acento_a": Color(0.45, 0.60, 0.30), "acento_b": Color(0.90, 0.72, 0.30),
				"luz": Color(1.0, 0.65, 0.25),
			}
		11:  # MERCADÃO DO PEIXE: madrugada azul-petróleo, concreto molhado, toldos vinho, néon
			return {
				"nome": "Mercadão do Peixe", "luz_dir": 1.0, "luz_extra": 0.04, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.04, 0.10, 0.15),
				"parede_baixa": tom_lum(Color(0.18, 0.30, 0.38), 0.185),
				"rodape": tom_lum(Color(0.35, 0.42, 0.45), 0.20),
				"piso_a": tom_lum(Color(0.42, 0.50, 0.52), 0.285),
				"piso_b": tom_lum(Color(0.40, 0.48, 0.52), 0.262),
				"junta": tom_lum(Color(0.34, 0.42, 0.46), 0.245),
				"tapete_borda": tom_lum(Color(0.42, 0.50, 0.52), 0.285),
				"tapete_meio": tom_lum(Color(0.42, 0.50, 0.52), 0.285),
				"tapete_dentro": tom_lum(Color(0.42, 0.50, 0.52), 0.285),
				"tapete_motivo": tom_lum(Color(0.42, 0.50, 0.52), 0.285),
				"franja": Color(0.6, 0.7, 0.75),
				"madeira": Color(0.42, 0.28, 0.20), "movel": Color(0.03, 0.05, 0.08),
				"acento_a": Color(0.62, 0.12, 0.22), "acento_b": Color(0.93, 0.88, 0.75),
				"luz": Color(0.55, 0.85, 1.0),
			}
		12:  # FERRO-VELHO: pôr do sol alaranjado, terra e sucata
			return {
				"nome": "Ferro-velho", "luz_dir": -1.0, "luz_extra": 0.04, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.20, 0.10, 0.22),
				"parede_baixa": tom_lum(Color(0.40, 0.28, 0.22), 0.185),
				"rodape": tom_lum(Color(0.45, 0.32, 0.25), 0.20),
				"piso_a": tom_lum(Color(0.52, 0.40, 0.30), 0.285),
				"piso_b": tom_lum(Color(0.50, 0.38, 0.30), 0.262),
				"junta": tom_lum(Color(0.45, 0.34, 0.26), 0.245),
				"tapete_borda": tom_lum(Color(0.52, 0.40, 0.30), 0.285),
				"tapete_meio": tom_lum(Color(0.52, 0.40, 0.30), 0.285),
				"tapete_dentro": tom_lum(Color(0.52, 0.40, 0.30), 0.285),
				"tapete_motivo": tom_lum(Color(0.52, 0.40, 0.30), 0.285),
				"franja": Color(0.7, 0.5, 0.3),
				"madeira": Color(0.38, 0.26, 0.16), "movel": Color(0.06, 0.04, 0.05),
				"acento_a": Color(0.95, 0.50, 0.15), "acento_b": Color(0.85, 0.75, 0.35),
				"luz": Color(1.0, 0.60, 0.25),
			}
		13:  # BECO DO FLIPERAMA: tijolo arroxeado, néon ciano e laranja, chão em grade
			return {
				"nome": "Beco do Fliperama", "luz_dir": 1.0, "luz_extra": 0.04, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.08, 0.05, 0.18),
				"parede_baixa": tom_lum(Color(0.28, 0.22, 0.40), 0.17),
				"rodape": tom_lum(Color(0.35, 0.30, 0.50), 0.20),
				"piso_a": tom_lum(Color(0.38, 0.46, 0.62), 0.28),
				"piso_b": tom_lum(Color(0.36, 0.44, 0.60), 0.258),
				"junta": tom_lum(Color(0.35, 0.50, 0.65), 0.245),
				"tapete_borda": tom_lum(Color(0.38, 0.46, 0.62), 0.28),
				"tapete_meio": tom_lum(Color(0.38, 0.46, 0.62), 0.28),
				"tapete_dentro": tom_lum(Color(0.38, 0.46, 0.62), 0.28),
				"tapete_motivo": tom_lum(Color(0.38, 0.46, 0.62), 0.28),
				"franja": Color(0.4, 0.8, 0.9),
				"madeira": Color(0.30, 0.20, 0.20), "movel": Color(0.04, 0.03, 0.09),
				"acento_a": Color(0.20, 0.85, 0.95), "acento_b": Color(1.0, 0.55, 0.15),
				"luz": Color(0.30, 0.90, 1.0),
			}
		14:  # ARENA DA PRAÇA: céu de tempestade, pedra clara, vermelho da legião
			return {
				"nome": "Arena da Praça", "luz_dir": 1.0, "luz_extra": 0.04, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.12, 0.10, 0.18),
				"parede_baixa": tom_lum(Color(0.45, 0.38, 0.34), 0.19),
				"rodape": tom_lum(Color(0.50, 0.44, 0.40), 0.20),
				"piso_a": tom_lum(Color(0.58, 0.50, 0.42), 0.295),
				"piso_b": tom_lum(Color(0.56, 0.48, 0.42), 0.268),
				"junta": tom_lum(Color(0.48, 0.42, 0.36), 0.245),
				"tapete_borda": tom_lum(Color(0.58, 0.50, 0.42), 0.295),
				"tapete_meio": tom_lum(Color(0.58, 0.50, 0.42), 0.295),
				"tapete_dentro": tom_lum(Color(0.58, 0.50, 0.42), 0.295),
				"tapete_motivo": tom_lum(Color(0.58, 0.50, 0.42), 0.295),
				"franja": Color(0.8, 0.6, 0.4),
				"madeira": Color(0.40, 0.28, 0.18), "movel": Color(0.05, 0.04, 0.06),
				"acento_a": Color(0.85, 0.20, 0.12), "acento_b": Color(0.95, 0.78, 0.35),
				"luz": Color(1.0, 0.65, 0.30),
			}
		15:  # TELHADOS E ANTENAS: noite roxa com raios, terraço de manta asfáltica
			return {
				"nome": "Telhados e Antenas", "luz_dir": -1.0, "luz_extra": 0.04, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.07, 0.04, 0.16),
				"parede_baixa": tom_lum(Color(0.30, 0.20, 0.42), 0.18),
				"rodape": tom_lum(Color(0.40, 0.32, 0.50), 0.20),
				"piso_a": tom_lum(Color(0.45, 0.42, 0.52), 0.28),
				"piso_b": tom_lum(Color(0.42, 0.40, 0.50), 0.26),
				"junta": tom_lum(Color(0.36, 0.34, 0.44), 0.245),
				"tapete_borda": tom_lum(Color(0.45, 0.42, 0.52), 0.28),
				"tapete_meio": tom_lum(Color(0.45, 0.42, 0.52), 0.28),
				"tapete_dentro": tom_lum(Color(0.45, 0.42, 0.52), 0.28),
				"tapete_motivo": tom_lum(Color(0.45, 0.42, 0.52), 0.28),
				"franja": Color(0.6, 0.5, 0.8),
				"madeira": Color(0.30, 0.24, 0.28), "movel": Color(0.04, 0.03, 0.08),
				"acento_a": Color(0.62, 0.30, 0.90), "acento_b": Color(0.75, 0.95, 1.0),
				"luz": Color(0.70, 0.50, 1.0),
			}
		_:  # QUARTO: ameixa e rosa, luz âmbar do abajur
			return {
				"nome": "Quarto", "luz_dir": -1.0, "luz_extra": 0.04, "vinheta": 0.08,   # i18n-ok: nome do cenário (identidade, não é desenhado)
				"parede_alta": Color(0.26, 0.17, 0.32),
				"parede_baixa": tom_lum(Color(0.40, 0.22, 0.32), 0.165),
				"rodape": tom_lum(Color(0.55, 0.32, 0.40), 0.20),
				"piso_a": tom_lum(Color(0.52, 0.40, 0.38), 0.29),
				"piso_b": tom_lum(Color(0.52, 0.40, 0.38), 0.265),
				"junta": tom_lum(Color(0.46, 0.35, 0.34), 0.245),
				"tapete_borda": tom_lum(Color(0.50, 0.32, 0.40), 0.285),
				"tapete_meio": tom_lum(Color(0.42, 0.24, 0.34), 0.26),
				"tapete_dentro": tom_lum(Color(0.50, 0.34, 0.42), 0.275),
				"tapete_motivo": tom_lum(Color(0.56, 0.42, 0.46), 0.30),
				"franja": Color(0.88, 0.74, 0.66),
				"madeira": Color(0.45, 0.30, 0.30), "movel": Color(0.14, 0.09, 0.17),
				"acento_a": Color(0.34, 0.22, 0.42), "acento_b": Color(0.80, 0.38, 0.50),
				"luz": Color(1.0, 0.74, 0.36),
			}

var sim: Simulacao
var estado: Estado
var velocidade: int = 1
var acum: float = 0.0
var particulas: Array = []
var numeros: Array = []
var voando: Array = []
var tremor: float = 0.0
var bau_pulso: float = 0.0
var bau_n: int = 0
var fim_t: float = 0.0
var finalizado: bool = false
var rel: float = 0.0
var torre_pulso: float = 0.0
var mensagem_t: float = 0.0
var chefe_t: float = 0.0
var fx: Array = []       # efeitos longos dos poderes: {poder, p, alvos, cor, t, dur, sem}
var queimados: Array = [] # marcas de queimado no chão (Relâmpago, Trovoada): {p, t, dur, r, cor}
var caidos: Array = []   # gatos nocauteados: ficam dormindo onde caíram até o fim da onda
var tranco: Dictionary = {}   # Unidade -> Vector2(direção, tempo restante) do recuo ao apanhar
var fundo: Fundo = null       # cenário estático (nó filho que não redesenha)
var fundo_ok: bool = false

# ---- estado visual da torre-fortaleza (só visual; a lógica fica na Simulacao)
var golpe_torre: float = 0.0     # 1 ao levar golpe, decai: abaixa o vigia, treme e levanta poeira
var recuo_canhao: float = 0.0    # 0..1, calculado dos tiros da torre em voo
var ratoeira_t: float = 0.0      # s restantes da ratoeira estalada
var catapulta_t: float = -1.0    # s desde o disparo da catapulta (-1 = armada)
var sirene_t: float = 0.0
var balista_t: float = 0.0
var caldeirao_t: float = 0.0
var fosso_t: float = 0.0
var reforco_t: float = 0.0
var luneta_t: float = 0.0
var novo_s: float = -1.0         # s desde que o Caldeirão repôs um bloco (-1 = nenhum)
var novo_idx: int = -1
var trofeu_pulso: float = 0.0
var tfx: Array = []              # efeitos dos módulos e troféus: {k, t, dur, ...}

# ---- game juice da luta (só apresentação: nada aqui muda a simulação)
const PAUSA_QUADRO := 1.0 / 60.0   # um quadro de hit-stop, em segundos reais
const ANTECIP_PODER := 0.14        # s (da luta) entre o clarão no gato e o efeito do poder
var pausa_t: float = 0.0           # hit-stop restante (s reais): a simulação não avança
var pausa_cd: float = 0.0          # intervalo mínimo entre dois hit-stops comuns
var _ico_ids := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])   # buffers dos ícones de estado (sem alocar por quadro)
var _ico_t := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var lento_t: float = 0.0           # câmera lenta do último bicho (s reais)
var sons_quadro: int = 0           # sons fortes já tocados neste quadro
var ju: Dictionary = {}            # Unidade -> {sq, forte, clar, andava, poeira, antecip, hop}
var fantasmas: Array = []          # bichos derrotados voando para trás: {u, x, y, vx, t, dur, forte}
var her_fx: Array = []             # selinho da herança que acabou de disparar, sobre o gato: {u, poder, t}
var agenda: Array = []             # ações atrasadas (clarões do chefe etc.): {t, k, p, ...}
var faixas: Array = []             # faixas que cruzam a tela: {txt, sub, cor, t, dur}
var ant_inim: Array = []           # inimigos vivos antes do último passo (para achar quem morreu)
var vinheta_poder: float = 0.0     # bordas escurecem por um instante ao disparar um poder
var perigo_tocou: bool = false
var tiros_torre: int = 0           # tiros da torre já vistos (som e clarão na boca do canhão)
var fim_tratado: bool = false      # o desfecho (som, câmera lenta, desabamento) já foi disparado
var segurar: bool = false          # o tutorial segura a luta (como um hit-stop) enquanto explica algo

# ---- barra de poderes (só visual e entrada; a lógica fica na Simulacao)
var poder_btns: Array = []       # {u, conj, poder, cor, nome, dica, tecla, rect, pronto, trancado, carga_ant, flash, tremor, motivo, motivo_t, variante}
var poder_de: Dictionary = {}    # Unidade -> índice em poder_btns
var poder_hover: int = -1
var poder_preso: int = -1        # botão em que o mouse foi apertado
var poder_dica_ok: bool = false  # a dica de primeira vez já foi dada nesta luta
var poder_seta: int = -1         # botão apontado pela seta de primeira vez
var poder_seta_t: float = 0.0
var poder_sem_aviso: bool = false   # primeira luta sem nenhum poder: mostra a linha explicando

# ---- preparação da onda (posto, postura, alvo prioritário) e leitura da luta (unidade sob o mouse)
## false: a luta começa direto, sem a parada de preparação (scripts de teste).
static var preparacao: bool = true
const PREP_BT_Y := 652.0
const PREP_BT_H := 56.0
const PREP_BT_X: Array[float] = [352.0, 506.0, 660.0]   # Avançar, Segurar, Recuar
const PREP_BT_W := 148.0
const PREP_COMECAR := Rect2(836.0, 648.0, 220.0, 62.0)
const PREP_COR: Array[Color] = [Color(1.0, 0.62, 0.5), Color(1.0, 0.86, 0.5), Color(0.62, 0.8, 1.0)]
const PREP_TECLA: Array[String] = ["Q", "W", "E"]
const PREP_DICA: Array[String] = [
	"Avançar: vai atrás de qualquer bicho que apareça, onde estiver.",
	"Segurar: fica no posto e só sai para quem chega perto (o fundo, só para quem encosta).",
	"Recuar: fica colado na torre e só luta com quem chega nela.",
]
const TIPO_DICA: Array[String] = [
	"Bate nos gatos que encontra e depois na torre.",
	"Pula por cima dos gatos e vai direto à torre.",
	"Rouba blocos da torre e foge com eles.",
	"Muita vida, lento; derruba 2 blocos por golpe.",
	"Ao cair, vira dois filhotes.",
	"Atira de longe nos gatos e na torre.",
	"Cura o bicho ferido mais próximo.",
	"Leva pouco dano e atrai os golpes dos gatos.",
	"Corre, encosta num gato ou na torre e explode.",
]
var prep: bool = false           # a onda ainda não começou: o jogador arruma o time
var prep_sel: Unidade = null     # gato selecionado (as ordens valem só para ele); null = time todo
var prep_arr: Unidade = null     # gato sendo arrastado
var prep_arr_d: Vector2 = Vector2.ZERO
var prep_arr_p0: Vector2 = Vector2.ZERO
var prep_arr_moveu: bool = false
var prep_previa: Array = []      # grupos da onda que vem: {u, n, prio, nome, dica, pos}
var prep_anim: Dictionary = {}
var prep_press: String = ""
var mouse_c: Vector2 = Vector2(-1.0, -1.0)   # mouse em coordenadas do campo; x < 0 = fora
var foco_u: Unidade = null       # unidade sob o mouse: mostra a ficha e em quem ela bate

func iniciar(e: Estado) -> void:
	estado = e
	sim = Simulacao.new()
	sim.iniciar(e)
	sim.poder_manual = not Menus.poder_automatico
	_montar_poderes()
	_montar_preparacao()
	particulas.clear()
	numeros.clear()
	voando.clear()
	caidos.clear()
	fx.clear()
	queimados.clear()
	tranco.clear()
	tfx.clear()
	golpe_torre = 0.0
	recuo_canhao = 0.0
	ratoeira_t = 0.0
	catapulta_t = -1.0
	sirene_t = 0.0
	balista_t = 0.0
	caldeirao_t = 0.0
	fosso_t = 0.0
	reforco_t = 0.0
	luneta_t = 0.0
	novo_s = -1.0
	novo_idx = -1
	trofeu_pulso = 0.0
	fundo_ok = false
	acum = 0.0
	fim_t = 0.0
	finalizado = false
	bau_n = 0
	tremor = 0.0
	mensagem_t = 0.0
	chefe_t = 0.0
	position = Vector2.ZERO
	pausa_t = 0.0
	pausa_cd = 0.0
	lento_t = 0.0
	ju.clear()
	fantasmas.clear()
	her_fx.clear()
	agenda.clear()
	faixas.clear()
	ant_inim.clear()
	vinheta_poder = 0.0
	perigo_tocou = false
	tiros_torre = 0
	fim_tratado = false
	# faixa de entrada da onda (o som toca quando ela começa a andar, depois da cortina)
	var onda_n: int = estado.onda_invasao if estado.invasao else estado.onda
	var nome_fase: String = Fases.nome_do_lugar(estado.lugar())
	_faixa(Idioma.t("Onda %d") % onda_n, Idioma.t(nome_fase), Color(1.0, 0.9, 0.5), 1.7, 0.35, "onda")

func _process(delta: float) -> void:
	if sim == null or not visible:
		return
	sons_quadro = 0
	var parado: bool = pausa_t > 0.0 or segurar   # hit-stop: a luta espera, a tela continua tremendo
	pausa_t = maxf(0.0, pausa_t - delta)
	pausa_cd = maxf(0.0, pausa_cd - delta)
	var dt: float = delta * velocidade
	if lento_t > 0.0:
		dt *= 0.3   # câmera lenta do último bicho: só a exibição
		lento_t = maxf(0.0, lento_t - delta)
	var dt_cheio: float = delta * velocidade
	var dtv: float = 0.0 if parado else dt
	rel += dtv
	sim.poder_manual = not Menus.poder_automatico   # a opção pode mudar no menu de pausa
	_atualizar_foco(delta)
	if prep:
		rel += delta   # a onda espera o jogador; os gatos respiram no posto
	elif not sim.terminada:
		if not parado:
			acum += dt
		var n: int = 0
		while not parado and acum >= Balanco.DT and n < 24:
			ant_inim = sim.inimigos.duplicate()
			sim.passo(Balanco.DT)
			acum -= Balanco.DT
			n += 1
			_consumir()
			if pausa_t > 0.0:
				break   # um golpe forte acabou de acontecer: segura aqui
		if sim.terminada:
			_desfecho()
	else:
		_consumir()
		fim_t += dt_cheio
		if sim.vitoria:
			mensagem_t += dt_cheio
		if not finalizado and fim_t > 1.6 and voando.is_empty():
			finalizado = true
			terminou.emit(sim.vitoria)
	_atualizar_visual(dtv, delta)
	_atualizar_juice(dtv, delta)
	_atualizar_poderes(delta)
	queue_redraw()

# ---------------------------------------------------------------- game juice (só apresentação)
## Ajuste de volume dos sons comuns conforme a velocidade: em 2x e 3x os golpes ficam mais baixos.
func _gdb_vel() -> float:
	return 0.0 if velocidade <= 1 else (-3.0 if velocidade == 2 else -6.0)

## Toca um efeito. `forte` conta no limite de 3 sons fortes por quadro e não leva o desconto da velocidade.
func _som(nome: String, tom: float = 1.0, ganho: float = 0.0, forte: bool = false, variar: float = 0.06) -> void:
	if forte:
		if sons_quadro >= 3:
			return
		sons_quadro += 1
	else:
		ganho += _gdb_vel()
	Som.tocar(nome, tom, variar, ganho)

## Micro-pausa: a simulação espera `quadros` quadros (de 1/60 s); encurta em 2x e 3x.
## `prioridade` ignora o intervalo mínimo entre pausas (morte de chefe).
func _pausa(quadros: float, prioridade: bool = false) -> void:
	if pausa_cd > 0.0 and not prioridade:
		return
	var k: float = 1.0 if velocidade <= 1 else (0.6 if velocidade == 2 else 0.4)
	pausa_t = maxf(pausa_t, quadros * PAUSA_QUADRO * k)
	pausa_cd = 0.28

func _ju(u: Unidade) -> Dictionary:
	if not ju.has(u):
		ju[u] = {"sq": -1.0, "forte": false, "clar": 0, "andava": false, "poeira": 0.0, "antecip": 0.0, "hop": -1.0}
	return ju[u]

func _faixa(txt: String, sub: String, cor: Color, dur: float, atraso: float, som: String) -> void:
	faixas.append({"txt": txt, "sub": sub, "cor": cor, "t": -atraso, "dur": dur, "som": som})

func _poeira(p: Vector2, dir: float, n: int, forca: float = 1.0) -> void:
	if particulas.size() > 420:
		return
	for k in n:
		var v: Vector2 = Vector2(-dir * randf_range(8, 36) * forca + randf_range(-10, 10), randf_range(-26, -6) * forca)
		particulas.append({"p": p + Vector2(randf_range(-4, 4), -2), "v": v, "vida": randf_range(0.3, 0.5), "max": 0.5, "cor": Color(0.82, 0.76, 0.66, 0.4), "r": randf_range(3.5, 6.0), "g": -10.0, "tipo": 1})

## Estrelinhas e quadradinhos de festa que caem de cima (chuva de troféus e peças do chefe).
func _chuva(centro: Vector2, n: int) -> void:
	for k in n:
		var cor: Color = [Desenho.DOURADO, Color(1, 1, 1), Color(1.0, 0.6, 0.3), Color(0.5, 0.85, 1.0)][k % 4]
		var p0: Vector2 = Vector2(centro.x + randf_range(-130, 130), centro.y - randf_range(60, 200))
		if k % 2 == 0:
			particulas.append({"p": p0, "v": Vector2(randf_range(-40, 40), randf_range(-30, 40)), "vida": randf_range(0.9, 1.4), "max": 1.4, "cor": cor, "r": randf_range(5, 8), "g": 300.0, "tipo": 4, "rot": randf() * TAU, "vrot": randf_range(-8, 8)})
		else:
			particulas.append({"p": p0, "v": Vector2(randf_range(-40, 40), randf_range(-30, 40)), "vida": randf_range(0.9, 1.4), "max": 1.4, "cor": cor, "r": randf_range(3.5, 5.5), "g": 300.0, "tipo": 0})

## Desfecho da luta (uma vez): som, câmera lenta do último bicho e desabamento da torre.
func _desfecho() -> void:
	if fim_tratado:
		return
	fim_tratado = true
	if sim.vitoria:
		lento_t = 0.4 if velocidade <= 1 else (0.32 if velocidade == 2 else 0.26)
		var ultima: bool = estado.onda >= Balanco.ONDAS_TOTAIS and not estado.invasao
		_som("vitoria" if ultima else "vitoria_onda", 1.0, 0.0, true)
		for k in 4:
			agenda.append({"t": 0.12 * k, "k": "confete", "p": Vector2(300.0 + 260.0 * k, 120.0)})
	else:
		_som("derrota", 1.0, 0.0, true)
		tremor = maxf(tremor, 12.0)
		for k in 12:
			agenda.append({"t": 0.07 * k, "k": "desaba"})
		for k in 3:
			agenda.append({"t": 0.2 * k, "k": "fumo", "p": Vector2(90.0 + 30.0 * k, TORRE_BASE.y - 60.0 * k)})

func _agenda_exec(a: Dictionary) -> void:
	match str(a["k"]):
		"clarao":
			var p: Vector2 = a["p"]
			particulas.append({"p": p, "v": Vector2.ZERO, "vida": 0.3, "max": 0.3, "cor": Color(1, 1, 0.9, 0.9), "r": 30.0, "g": 0.0, "tipo": 1})
			particulas.append({"p": p, "v": Vector2.ZERO, "vida": 0.35, "max": 0.35, "cor": Color(1.0, 0.9, 0.4), "r": 30.0, "g": 0.0, "tipo": 4, "rot": randf() * TAU, "vrot": 4.0})
			_faisca(p, Color(1.0, 0.85, 0.35), 10, 260.0, 0.5, 3.4)
			tremor = maxf(tremor, 6.0)
			_som("critico", randf_range(0.8, 1.0), -4.0, true)
		"chuva":
			_chuva(a["p"], 26)
			tremor = maxf(tremor, 14.0)
			_som("trofeu", 0.9, -3.0, true)
		"poder_fx":
			_poder_fx(int(a["poder"]), a["po"], a["alvos"], a["cor"], a.get("ex", {}))
		"confete":
			_chuva(a["p"], 10)
		"fumo":
			var pfu: Vector2 = a["p"]
			for kf in 3:
				particulas.append({"p": pfu + Vector2(randf_range(-30, 30), randf_range(-20, 20)), "v": Vector2(randf_range(-10, 30), randf_range(-60, -25)), "vida": 1.0, "max": 1.0, "cor": Color(0.4, 0.34, 0.36, 0.5), "r": randf_range(10, 16), "g": 0.0, "tipo": 1})
		"desaba":
			var idx: int = randi() % 16
			var pb: Vector2 = Vector2(randf_range(20, 150), randf_range(500, 640))
			particulas.append({"p": pb, "v": Vector2(randf_range(10, 120), randf_range(-170, -40)), "vida": 1.4, "max": 1.4, "cor": Desenho.cor_tijolo(idx), "idx": idx, "r": 0.0, "g": 700.0, "tipo": 2, "rot": 0.0, "vrot": randf_range(-6, 6), "chao": TORRE_BASE.y + 6.0, "q": 2})
			_poeira(Vector2(pb.x, TORRE_BASE.y + 4.0), -1.0, 3, 1.8)
			if randi() % 3 == 0:
				_som("bloco_perdido", randf_range(0.8, 1.0), -6.0)

## Relógios do juice: unidades (esmaga-e-estica, poeira, antecipação), fantasmas, agenda, faixas e alertas.
func _atualizar_juice(dtv: float, delta: float) -> void:
	var vivos: Dictionary = {}
	for lista in [sim.aliados, sim.inimigos]:
		for u in lista:
			var uu: Unidade = u
			vivos[uu] = true
			var j: Dictionary = _ju(uu)
			if float(j["sq"]) >= 0.0:
				j["sq"] = float(j["sq"]) + dtv
				if float(j["sq"]) > 0.26:
					j["sq"] = -1.0
			if int(j["clar"]) > 0 and dtv > 0.0:
				j["clar"] = int(j["clar"]) - 1
			j["antecip"] = maxf(0.0, float(j["antecip"]) - dtv)
			if float(j["hop"]) >= 0.0:
				j["hop"] = float(j["hop"]) + dtv
				if float(j["hop"]) > 0.3:
					j["hop"] = -1.0
			# poeira nos pés ao correr e ao frear
			if dtv > 0.0:
				var dir_u: float = 1.0 if uu.equipe == 0 else -1.0
				var pe: Vector2 = Vector2(uu.vx, uu.vy)
				if uu.equipe == 1 and uu.tipo == Unidade.Tipo.GIGANTE and not uu.chefe and uu.andando and uu.vivo:
					# grandalhão: cada pisada (quadro de apoio do passo) levanta poeira dos dois lados do pé
					var qp: int = posmod(int(uu.anim * BichoPx.PASSO_ANIM), BichoPx.QUADROS_PASSO)
					if qp != int(j.get("qp", -1)) and qp % 3 == 0:
						_poeira(pe + Vector2(dir_u * 8.0, 0), dir_u, 2, 0.7)
						_poeira(pe - Vector2(dir_u * 8.0, 0), -dir_u, 1, 0.6)
					j["qp"] = qp
				if uu.andando and uu.vivo:
					j["poeira"] = float(j["poeira"]) - dtv
					if float(j["poeira"]) <= 0.0:
						j["poeira"] = randf_range(0.08, 0.13)
						_poeira(pe + Vector2(-dir_u * 14.0, 0), dir_u, 1)
				elif bool(j["andava"]) and uu.vivo:
					_poeira(pe + Vector2(dir_u * 12.0, 0), -dir_u, 3, 0.9)
				j["andava"] = uu.andando
	for k in ju.keys():
		if not vivos.has(k):
			ju.erase(k)
	# bichos derrotados: voam para trás, esmagam e somem
	for i in range(fantasmas.size() - 1, -1, -1):
		var f: Dictionary = fantasmas[i]
		var tf0: float = float(f["t"])
		f["t"] = float(f["t"]) + dtv
		f["x"] = float(f["x"]) + float(f["vx"]) * dtv
		var pouso: float = float(f["dur"]) * (FANT_POUSO_CHEFE if bool(f.get("chefe", false)) else FANT_POUSO)
		if tf0 < pouso and float(f["t"]) >= pouso:
			# caiu de costas: poeira dos dois lados; o chefe solta o adereço, que sai rolando
			_poeira(Vector2(float(f["x"]), float(f["y"])), 1.0, 3 if not bool(f.get("chefe", false)) else 6, 1.0 if not bool(f.get("chefe", false)) else 1.6)
			_poeira(Vector2(float(f["x"]), float(f["y"])), -1.0, 2 if not bool(f.get("chefe", false)) else 5, 0.9 if not bool(f.get("chefe", false)) else 1.4)
			if bool(f.get("chefe", false)):
				f["vx"] = 0.0
				f["rola"] = 0.0
		if f.has("rola"):
			f["rola"] = float(f["rola"]) + dtv
		f["vx"] = float(f["vx"]) * (1.0 - minf(1.0, 3.5 * dtv))
		if float(f["t"]) >= float(f["dur"]):
			var pf: Vector2 = Vector2(float(f["x"]), float(f["y"]))
			_poeira(pf, -1.0, 4, 1.4)
			for s in 3:
				var ang_s: float = -PI * 0.5 + randf_range(-1.0, 1.0)
				particulas.append({"p": pf + Vector2(0, -30), "v": Vector2(cos(ang_s), sin(ang_s)) * randf_range(60, 140), "vida": 0.5, "max": 0.5, "cor": Desenho.DOURADO if s % 2 == 0 else Color(1, 1, 1), "r": randf_range(3.5, 5.5), "g": 260.0, "tipo": 4, "rot": randf() * TAU, "vrot": randf_range(-9, 9)})
			fantasmas.remove_at(i)
	# gatos nocauteados: gira, cai, levanta poeira ao pousar
	for cd in caidos:
		var t0: float = float(cd.get("t", 1.0))
		var t1: float = t0 + dtv
		cd["t"] = t1
		if t0 < 0.4 and t1 >= 0.4:
			_poeira(Vector2(cd["x"], cd["y"]), 1.0, 5, 1.3)
			_poeira(Vector2(cd["x"], cd["y"]), -1.0, 3, 1.0)
	for i in range(agenda.size() - 1, -1, -1):
		var a: Dictionary = agenda[i]
		a["t"] = float(a["t"]) - dtv
		if float(a["t"]) <= 0.0:
			agenda.remove_at(i)
			_agenda_exec(a)
	# faixas: andam em tempo de tela, um pouco mais rápidas em 2x e 3x
	var dtf: float = delta * (1.0 if velocidade <= 1 else 1.4)
	for i in range(faixas.size() - 1, -1, -1):
		var fx_f: Dictionary = faixas[i]
		var tf0: float = float(fx_f["t"])
		fx_f["t"] = tf0 + dtf
		if tf0 < 0.0 and float(fx_f["t"]) >= 0.0 and str(fx_f["som"]) != "":
			_som(str(fx_f["som"]), 1.0, -2.0, true)
		if float(fx_f["t"]) >= float(fx_f["dur"]):
			faixas.remove_at(i)
	vinheta_poder = maxf(0.0, vinheta_poder - delta * 3.5)
	# torre em perigo: som uma vez por queda abaixo de 30%
	var frac_t: float = float(estado.tijolos) / maxf(1.0, float(estado.tijolos_max()))
	if frac_t < 0.3 and estado.tijolos > 0 and not sim.terminada:
		if not perigo_tocou:
			perigo_tocou = true
			_som("torre_perigo", 1.0, -2.0, true)
	elif frac_t > 0.45:
		perigo_tocou = false
	# tiros da torre: som e clarão na boca do canhão (o dicionário do projétil só ganha uma marca de "visto")
	for pr in sim.projeteis:
		var d: Dictionary = pr
		if d["dono"] == null and not d.has("visto"):
			d["visto"] = true
			_som("tiro_torre", 1.0, -6.0)
			if TORRE_FORTALEZA:
				var boca: Vector2 = TorrePx.boca_canhao(_base_f(), estado.tijolos, estado.tijolos_max(), estado.melhorias, rel, golpe_torre, 0.0)
				particulas.append({"p": boca, "v": Vector2.ZERO, "vida": 0.12, "max": 0.12, "cor": Color(1.0, 0.95, 0.6, 0.85), "r": 15.0, "g": 0.0, "tipo": 1})
				_centelha(boca, 1.0, Color(1.0, 0.9, 0.5), 5)

## Altura do salto de um gato (comemoração da vitória e pulinho do poder), em pixels.
func _salto(uu: Unidade) -> float:
	var h: float = 0.0
	if uu.equipe == 0 and uu.vivo and sim.terminada and sim.vitoria and mensagem_t < 1.5:
		var fase: float = float(uu.get_instance_id() % 7) * 0.5
		h = absf(sin(mensagem_t * 8.0 + fase)) * 20.0 * clampf((1.5 - mensagem_t) * 3.0, 0.0, 1.0)
	if ju.has(uu):
		var hp: float = float(ju[uu]["hop"])
		if hp >= 0.0:
			h = maxf(h, sin(clampf(hp / 0.3, 0.0, 1.0) * PI) * 12.0)
	return h

## Bordas escuras ou coloridas: faixas com degradê para dentro (alfa máximo na borda).
func _vinheta(cor: Color, alfa: float, esp: float = 150.0) -> void:
	if alfa <= 0.003:
		return
	var c0: Color = Color(cor.r, cor.g, cor.b, alfa)
	var c1: Color = Color(cor.r, cor.g, cor.b, 0.0)
	var w: float = 1280.0
	var h: float = 720.0
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, esp), Vector2(0, esp)]), PackedColorArray([c0, c0, c1, c1]))
	draw_polygon(PackedVector2Array([Vector2(0, h), Vector2(w, h), Vector2(w, h - esp), Vector2(0, h - esp)]), PackedColorArray([c0, c0, c1, c1]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(esp, 0), Vector2(esp, h), Vector2(0, h)]), PackedColorArray([c0, c1, c1, c0]))
	draw_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w - esp, 0), Vector2(w - esp, h), Vector2(w, h)]), PackedColorArray([c0, c1, c1, c0]))

func _desenhar_faixas() -> void:
	for fx_f in faixas:
		var f: Dictionary = fx_f
		var t: float = float(f["t"])
		if t < 0.0:
			continue
		var dur: float = float(f["dur"])
		var cor: Color = f["cor"]
		var cy: float = 250.0
		var h: float = 78.0 * clampf(minf(t / 0.12, (dur - t) / 0.18), 0.0, 1.0)
		var y0: float = V.sn(cy - h * 0.5)
		var yb: float = V.sn(cy + h * 0.5)
		V.quadro(self, 0.0, y0, 1280.0, maxf(V.Q, yb - y0), Color(0.04, 0.02, 0.07, 0.7))
		V.quadro(self, 0.0, y0 - V.Q, 1280.0, V.Q, V.CONT)
		V.quadro(self, 0.0, yb, 1280.0, V.Q, V.CONT)
		if h > 20.0:
			# faixa de perigo em listras que correm
			var desl: float = fposmod(t * 60.0, 48.0)
			for k in 28:
				var xs: float = V.sn(k * 48.0 - 48.0 + desl)
				V.quadro(self, xs, y0, 24.0, V.Q * 2.0, cor)
				V.quadro(self, 1280.0 - 24.0 - xs, yb - V.Q * 2.0, 24.0, V.Q * 2.0, cor)
		# o texto entra da esquerda (freia), repousa devagar e sai para a direita (acelera)
		var x: float = 640.0
		var ent: float = 0.28
		var sai: float = 0.22
		if t < ent:
			var w0: float = 1.0 - t / ent
			x = 640.0 - 900.0 * w0 * w0 * w0
		elif t > dur - sai:
			var w1: float = (t - (dur - sai)) / sai
			x = 640.0 + 900.0 * w1 * w1 * w1
		else:
			x = 640.0 + (t - ent - (dur - ent - sai) * 0.5) * 14.0
		Desenho.texto(self, str(f["txt"]), Vector2(x - 400.0, cy + 6.0), 54, cor, 800.0, 8)
		if h > 60.0:
			var lw: float = 40.0 + 12.0 * float(str(f["txt"]).length())
			V.brilho(self, Vector2(x - lw, cy - 8.0), 6.0 + 2.0 * sin(t * 8.0), V.tom(cor, 1.4))
			V.brilho(self, Vector2(x + lw, cy - 8.0), 6.0 + 2.0 * sin(t * 8.0 + 2.0), V.tom(cor, 1.4))
		if str(f["sub"]) != "":
			Desenho.texto(self, str(f["sub"]), Vector2(x - 400.0, cy + 30.0), 18, Color(1, 0.95, 0.85), 800.0, 4)

# ---------------------------------------------------------------- efeitos
func _faisca(p: Vector2, cor: Color, n: int, vel: float = 140.0, vida: float = 0.45, r: float = 3.0) -> void:
	for i in n:
		var a: float = randf() * TAU
		var v: Vector2 = Vector2(cos(a), sin(a) * 0.8 - 0.4) * randf_range(vel * 0.4, vel)
		particulas.append({"p": p, "v": v, "vida": vida * randf_range(0.7, 1.2), "max": vida, "cor": cor, "r": r * randf_range(0.7, 1.2), "g": 260.0, "tipo": 0})

func _numero(p: Vector2, txt: String, cor: Color, tam: int = 20, vida: float = 0.9, larg: float = 80.0) -> void:
	numeros.append({"p": p + Vector2(randf_range(-8, 8), 0), "txt": txt, "cor": cor, "vida": vida, "tam": tam, "larg": larg})

func _consumir() -> void:
	for ev in sim.eventos:
		var e: Dictionary = ev
		match e["t"]:
			"golpe":
				var p: Vector2 = Vector2(e["x"], e["y"] - 34 * ESC)
				var alvo_j: Unidade = _unidade_perto(Vector2(e["x"], e["y"]), int(e["eq"]))
				var eq: int = e["eq"]
				var cor: Color = Color(1, 1, 1) if eq == 1 else Color(1.0, 0.45, 0.4)
				if e.has("espinho"):
					cor = Color(0.8, 1.0, 0.5)
				# número proporcional ao dano; grande tem contorno grosso (mais legível)
				var dn: float = float(e["dano"])
				var tam_n: int = clampi(int(10.0 + 4.4 * log(dn + 1.0)), 13, 36)
				if eq == 0:
					tam_n = maxi(13, tam_n - 2)
				var contorno_n: int = 2 if tam_n < 20 else (4 if tam_n < 28 else 6)
				if Menus.numeros_dano:  # opção do menu
					numeros.append({"p": p + Vector2(randf_range(-10, 10), -8), "txt": str(int(round(dn))), "cor": cor, "vida": 0.7 + 0.015 * tam_n, "tam": tam_n, "larg": 90.0, "ct": contorno_n, "vy": -230.0 if tam_n >= 20 else -170.0})
				# golpe forte: dano alto ou uma boa fatia da vida do alvo
				var forte_g: bool = (alvo_j != null and dn >= 0.3 * alvo_j.vida_max) or (alvo_j == null and dn >= 10.0)   # relativo ao alvo: com números altos nem todo golpe é "forte"
				# faísca direcional: sai no sentido do golpe + tranco no alvo
				var dir_g: float = 1.0 if eq == 1 else -1.0
				_centelha(p + Vector2(0, 8), dir_g, Color(1, 0.95, 0.7) if eq == 1 else Color(1.0, 0.6, 0.5), 4 + mini(5, tam_n / 8) + (5 if forte_g else 0))
				var alvo_g: Unidade = alvo_j
				if alvo_g != null:
					tranco[alvo_g] = Vector2(dir_g, 0.16)
					var jg: Dictionary = _ju(alvo_g)
					jg["sq"] = 0.0
					jg["forte"] = forte_g
					jg["clar"] = 2 if forte_g else 1
				# som: comuns baixos (o tom desce com o dano), golpe forte em destaque
				var tom_g: float = clampf(1.45 - tam_n * 0.025, 0.8, 1.15) * (0.93 if eq == 0 else 1.0)
				if e.has("espinho"):
					_som("golpe1", 1.25, -9.0)
				elif forte_g:
					_som("golpe_forte", tom_g, -3.0, true)
					_pausa(2.0 if dn < 20.0 else 3.0)
					tremor = maxf(tremor, 1.5 + minf(2.0, dn * 0.06))
					particulas.append({"p": p, "v": Vector2.ZERO, "vida": 0.18, "max": 0.18, "cor": Color(1, 1, 0.9, 0.6), "r": 16.0 + tam_n * 0.5, "g": 0.0, "tipo": 1})
				else:
					_som(["golpe1", "golpe2", "golpe3"][randi() % 3], tom_g, lerpf(-8.0, -4.0, clampf((tam_n - 13.0) / 12.0, 0.0, 1.0)), false, 0.08)
			"esquiva":
				_numero(Vector2(e["x"], e["y"] - 60 * ESC), Idioma.t("esquiva"), Color(0.6, 0.9, 1.0), 15)
				_som("esquiva", 1.0, -7.0)
			"tiro":
				var cor_t: Color = Color(0.85, 0.92, 1.0) if int(e.get("eq", 0)) == 0 else Color(1.0, 0.65, 0.5)
				_faisca(Vector2(e["x"], e["y"] - TIRO_ALT * ESC), cor_t, 3, 60.0, 0.25, 2.0)
				_som("tiro", 1.0 if int(e.get("eq", 0)) == 0 else 0.8, -9.0)
			"morte":
				var p2: Vector2 = Vector2(e["x"], e["y"] - 28 * ESC)
				if e["eq"] == 0:
					# gato: não explode, adormece. Fumacinha azul e bolinhas de sono
					for k in 4:
						particulas.append({"p": p2 + Vector2(randf_range(-14, 14), randf_range(-6, 10)), "v": Vector2(randf_range(-20, 20), randf_range(-30, -8)), "vida": 0.7, "max": 0.7, "cor": Color(0.65, 0.78, 1.0, 0.4), "r": 8.0, "g": 0.0, "tipo": 1})
					_faisca(p2, Color(0.7, 0.85, 1.0), 6, 70.0, 0.6, 2.4)
					tremor = maxf(tremor, 3.0)
					tfx.append({"k": "nocaute", "p": Vector2(e["x"], e["y"] - 20 * ESC), "t": 0.0, "dur": 0.8})
					caidos.append({"x": e["x"], "y": e["y"], "pecas": e["pecas"], "var": estado.bonecos.find(e["boneco"]), "t": 0.0})
					_som("nocaute", 1.0, -3.0, true)
				else:
					# bicho: arremessado para trás, some em poeira com estrelinhas
					var mu: Unidade = null
					for uq in ant_inim:
						var uqq: Unidade = uq
						if not uqq.vivo and absf(uqq.x - float(e["x"])) < 0.01 and absf(uqq.y - float(e["y"])) < 0.01:
							mu = uqq
							break
					var eh_chefe: bool = mu != null and mu.chefe
					if mu != null:
						fantasmas.append({"u": mu, "x": e["x"], "y": e["y"], "vx": 150.0 if not eh_chefe else 20.0, "t": 0.0, "dur": 0.55 if not eh_chefe else 1.2, "chefe": eh_chefe})
					if eh_chefe:
						_pausa(4.0, true)
						tremor = maxf(tremor, 14.0)
						_som("bicho_cai", 0.6, -2.0, true)
						_som("poder_explosao", 0.75, -4.0, true)
						for k in 5:
							agenda.append({"t": 0.1 + 0.13 * k, "k": "clarao", "p": p2 + Vector2(randf_range(-55, 55), randf_range(-50, 40))})
						agenda.append({"t": 0.45, "k": "chuva", "p": p2})
					else:
						_som("bicho_cai", randf_range(0.95, 1.15), -6.0)
					for k in 6:
						var ang_p: float = randf() * TAU
						particulas.append({"p": p2 + Vector2(cos(ang_p), sin(ang_p) * 0.6) * 10.0, "v": Vector2(cos(ang_p), sin(ang_p) * 0.6) * randf_range(30, 80), "vida": randf_range(0.5, 0.8), "max": 0.8, "cor": Color(0.82, 0.76, 0.66, 0.55), "r": randf_range(8, 13), "g": -20.0, "tipo": 1})
					for k in 5:
						var ang_s: float = -PI * 0.5 + randf_range(-1.2, 1.2)
						particulas.append({"p": p2, "v": Vector2(cos(ang_s), sin(ang_s)) * randf_range(120, 220), "vida": 0.7, "max": 0.7, "cor": Color(1.0, 0.9, 0.4) if k % 2 == 0 else Color(1, 1, 1), "r": randf_range(4.5, 7.0), "g": 380.0, "tipo": 4, "rot": randf() * TAU, "vrot": randf_range(-9, 9)})
			"poder":
				# poder da fantasia completa: nome em cima de quem usou, clarão na cor da fantasia e um risco até cada alvo
				var cp: Color = _cor_legivel(Pecas.CONJUNTO_COR[e["conj"]], 0.62)
				var po: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				# antecipação: clarão no gato, pulinho, bordas escurecem; o efeito entra ANTECIP_PODER depois
				var gato_p: Unidade = _unidade_perto(Vector2(e["x"], e["y"]), 0)
				# poder de bicho (eq 1): quem usou, para o rasante do Esquilo e para subir o nome acima de um chefe alto
				var bicho_p: Unidade = _unidade_perto(Vector2(e["x"], e["y"]), 1) if int(e.get("eq", 0)) == 1 else null
				var sobe_p: float = _topo_extra(bicho_p) * 1.6 if bicho_p != null else 0.0
				if gato_p != null:
					var jp: Dictionary = _ju(gato_p)
					jp["antecip"] = ANTECIP_PODER * 1.5
					jp["hop"] = 0.0
				vinheta_poder = 0.45 if e.get("heranca", false) else 1.0   # herança dispara sozinha e com frequência: escurece menos
				var snd_p: String = "poder"
				var tom_p: float = 1.0
				match int(e.get("poder", 0)):
					Pecas.Poder.RAIO: snd_p = "poder_raio"
					Pecas.Poder.EXPLOSAO: snd_p = "poder_explosao"
					Pecas.Poder.CURA: snd_p = "poder_cura"
					Pecas.Poder.GELO: snd_p = "poder_gelo"
					Pecas.Poder.SAQUE: snd_p = "tiro"
					Pecas.Poder.TROVOADA: snd_p = "poder_raio"
					Pecas.Poder.CANHAO, Pecas.Poder.MISSEIS: snd_p = "poder_explosao"
					Pecas.Poder.CANTEIRO, Pecas.Poder.TRIAGEM: snd_p = "poder_cura"
					Pecas.Poder.RAIZ:
						snd_p = "poder_gelo"
						tom_p = 1.5
					Pecas.Poder.INVESTIDA: snd_p = "golpe_forte"
					Pecas.Poder.PISAO:
						snd_p = "golpe_forte"
						tom_p = 0.75
					Pecas.Poder.FUMACA:
						snd_p = "poder"
						tom_p = 0.7
					Pecas.Poder.FURIA:
						snd_p = "poder"
						tom_p = 0.6
					Pecas.Poder.CANCAO: snd_p = "poder_pronto"
					Pecas.Poder.MARCA:
						snd_p = "poder_raio"
						tom_p = 1.6
					Pecas.Poder.BOLA:
						snd_p = "poder"
						tom_p = 1.4
					Pecas.Poder.SALVAMENTO:
						snd_p = "golpe_forte"
						tom_p = 1.2
					Pecas.Poder.RICOCHETE: snd_p = "tiro"
					Pecas.Poder.OLHAR:
						snd_p = "poder_explosao"
						tom_p = 0.8
					Pecas.Poder.OBJECAO:
						snd_p = "poder_pronto"
						tom_p = 1.5
					Pecas.Poder.IMITAR: snd_p = "poder_pronto"
					Pecas.Poder.POQUER:
						snd_p = "poder"
						tom_p = 1.25
					Pecas.Poder.TORRE:
						snd_p = "poder"
						tom_p = 1.6
					Pecas.Poder.MANTEIGA:
						snd_p = "poder_gelo"
						tom_p = 0.8
					Pecas.Poder.REVIVER: snd_p = "poder_cura"
					Pecas.Poder.COLHEITA:
						snd_p = "poder_cura"
						tom_p = 1.4
					Pecas.Poder.CONSTRUIR:
						snd_p = "golpe_forte"
						tom_p = 0.7
					Pecas.Poder.COCHILO:
						snd_p = "poder"
						tom_p = 0.5
					Pecas.Poder.PLANO:
						snd_p = "poder_pronto"
						tom_p = 1.3
					Pecas.Poder.DOMO:
						snd_p = "poder_gelo"
						tom_p = 1.2
					Pecas.Poder.LOBO:
						snd_p = "poder"
						tom_p = 0.55
					Pecas.Poder.TURBO:
						snd_p = "golpe_forte"
						tom_p = 1.4
					Pecas.Poder.ESFORCO:
						snd_p = "poder_cura"
						tom_p = 0.7
					Pecas.Poder.CHUTE:
						snd_p = "golpe_forte"
						tom_p = 1.1
					Pecas.Poder.APAGAO:
						snd_p = "poder"
						tom_p = 0.5
					Pecas.Poder.ESPIRITO:
						snd_p = "poder"
						tom_p = 0.7
					Pecas.Poder.LACO:
						snd_p = "poder_pronto"
						tom_p = 1.0
					Pecas.Poder.KAMEHA:
						snd_p = "poder_pronto"
						tom_p = 0.6
					Pecas.Poder.PEDRA:
						snd_p = "golpe_forte"
						tom_p = 0.6
					Pecas.Poder.CAPTURA:
						snd_p = "poder_pronto"
						tom_p = 1.5
					Pecas.Poder.MEGAZORD:
						snd_p = "poder_pronto"
						tom_p = 0.7
					Pecas.Poder.SOPRO:
						snd_p = "golpe_forte"
						tom_p = 0.5
					Pecas.Poder.BRADO:
						snd_p = "golpe_forte"
						tom_p = 0.4
					Pecas.Poder.RECOMPENSA:
						snd_p = "poder_pronto"
						tom_p = 1.2
					Pecas.Poder.ESTASE:
						snd_p = "poder"
						tom_p = 1.4
					Pecas.Poder.LOUCURA:
						snd_p = "poder"
						tom_p = 0.4
				_som(snd_p, tom_p, -1.0, true, 0.03)
				# nome do poder: cor da fantasia clareada até uma luminância mínima + contorno escuro grosso
				# empilha: se já há um nome de poder aqui perto, este sobe uma linha (sem sobrepor)
				var nivel_nome: int = 0
				for on in numeros:
					if on.get("placa", false) and absf(on["p"].x - clampf(e["x"], 140.0, 1140.0)) < 280.0 and on["vida"] > 0.3:
						nivel_nome += 1
				# herança: a placa leva o selo com o ícone do poder (pela fantasia herdada: na Carga de lança o evento sai com poder -1)
				var her_p: int = Pecas.PODER_TIPO[clampi(int(e["conj"]), 0, Pecas.PODER_TIPO.size() - 1)] if e.get("heranca", false) else -1
				numeros.append({"p": Vector2(clampf(e["x"], 140.0, 1140.0), e["y"] - 92 * ESC - sobe_p - nivel_nome * 46.0), "txt": (Idioma.t("Herança: %s!") if e.get("heranca", false) else "%s!") % Idioma.t(Simulacao.heranca_nome_curto(e["conj"], int(e.get("grau", 1)))), "cor": _cor_legivel(Pecas.CONJUNTO_COR[e["conj"]], 0.78), "vida": 1.5, "tam": 28, "larg": 380.0, "ct": 8, "placa": true, "her": her_p})
				if her_p >= 0 and gato_p != null:
					var her_k: int = 0   # duas heranças do mesmo gato juntas: o selinho novo vai ao lado, sem cobrir o outro
					for hf0 in her_fx:
						if hf0["u"] == gato_p:
							her_k += 1
					her_fx.append({"u": gato_p, "poder": her_p, "t": 0.0, "k": her_k})
				particulas.append({"p": po, "v": Vector2.ZERO, "vida": 0.4, "max": 0.4, "cor": Color(cp.r, cp.g, cp.b, 0.5), "r": 22.0, "g": 0.0, "tipo": 1})
				var alvos_p: Array = []
				for pt in e["pontos"]:
					alvos_p.append(Vector2(pt.x, pt.y - 24 * ESC))
				if int(e.get("poder", 0)) == Pecas.Poder.TELEPORTE:
					alvos_p = [Vector2(float(e.get("x0", e["x"])), float(e.get("y0", e["y"])) - 24 * ESC)]   # no teleporte, o risco vai da origem ao destino
				if e.has("texto"):
					var pt_txt: Vector2 = Vector2(clampf(e["x"], 140.0, 1140.0), e["y"] - 150 * ESC - sobe_p - nivel_nome * 46.0)
					if not alvos_p.is_empty() and int(e.get("poder", 0)) == Pecas.Poder.POQUER:
						pt_txt = Vector2(clampf(alvos_p[0].x, 140.0, 1140.0), alvos_p[0].y - 70.0)
					_numero(pt_txt, Idioma.t(String(e["texto"])), cp.lightened(0.25), 24, 1.5, 300.0)
				agenda.append({"t": ANTECIP_PODER, "k": "poder_fx", "poder": int(e.get("poder", 0)), "po": po, "alvos": alvos_p, "cor": cp,
					"ex": {"x0": float(e.get("x0", e["x"])), "y0": float(e.get("y0", e["y"])), "x1": float(e.get("x1", e["x"])), "raio": float(e.get("raio", 0.0)), "dur": float(e.get("dur", 0.0)), "combos": int(e.get("combos", 0)),
						"eq": int(e.get("eq", 0)), "u": bicho_p}})
			"aviso":
				# um bicho carrega o poder: ping de alerta (o desenho da área sai de _desenhar_avisos)
				_som("poder_pronto", 0.6 if e.get("chefe", false) else 0.8, -2.0, true)
			"aviso_cortado":
				# o bicho foi atordoado no meio da carga: o "!" do balão se parte e o poder se perde
				var pcv: Vector2 = Vector2(e["x"], e["y"] - (CORPO_ALT + 40.0) * ESC - _topo_extra(_unidade_perto(Vector2(e["x"], e["y"]), 1)))
				tfx.append({"k": "aviso_cortado", "p": pcv, "t": 0.0, "dur": 0.75})
				_faisca(pcv, Color(1.0, 0.85, 0.4), 6, 130.0, 0.4, 2.6)
				_numero(pcv + Vector2(0, -34), Idioma.t("cortado!"), Color(1.0, 0.85, 0.5), 15, 0.9, 120.0)
				_som("esquiva", 0.7, -4.0)
			"clone_fim":
				# clone que some (fim do tempo ou derrotado): fumacinha, sem som e sem nocaute
				var pcl: Vector2 = Vector2(e["x"], e["y"] - 22 * ESC)
				for kc in 5:
					particulas.append({"p": pcl + Vector2(randf_range(-10, 10), randf_range(-8, 8)), "v": Vector2(randf_range(-25, 25), randf_range(-45, -10)), "vida": 0.5, "max": 0.5, "cor": Color(0.85, 0.85, 0.85, 0.55), "r": randf_range(7, 11), "g": 0.0, "tipo": 1})
			"explosao":
				_som("poder_explosao", 1.1, -5.0, true)
				var pe: Vector2 = Vector2(e["x"], e["y"] - 20 * ESC)
				var rr: float = e["raio"]
				_faisca(pe, Color(1.0, 0.6, 0.1), 22, 320.0, 0.6, 5.0)
				_faisca(pe, Color(1.0, 0.95, 0.5), 10, 200.0, 0.4, 3.5)
				particulas.append({"p": pe, "v": Vector2.ZERO, "vida": 0.5, "max": 0.5, "cor": Color(1.0, 0.55, 0.1, 0.55), "r": rr / 2.0, "g": 0.0, "tipo": 1})
				tremor = maxf(tremor, 6.0)
			"chefe":
				chefe_t = 2.2
				var nome_ch: String = Idioma.t(Fases.nome_do_chefe(estado.lugar_chefe()))
				_faixa(nome_ch, Idioma.t("CHEFE!"), Color(1.0, 0.35, 0.3), 2.0, 0.0, "chefe")
				tfx.append({"k": "chefe_chega", "p": Vector2(1120.0, 520.0), "t": 0.0, "dur": 1.0})
				tremor = maxf(tremor, 8.0)
			"critico":
				var pk: Vector2 = Vector2(e["x"], e["y"] - 66 * ESC)
				_som("critico", 1.0, -2.0, true)
				_pausa(3.0)
				numeros.append({"p": pk + Vector2(0, -6), "txt": Idioma.t("CRÍTICO!"), "cor": Color(1.0, 0.9, 0.2), "vida": 1.1, "tam": 34, "larg": 220.0, "ct": 7})
				_faisca(pk + Vector2(0, 26), Color(1.0, 0.9, 0.3), 12, 260.0, 0.45, 3.4)
				# estrela grande de impacto + clarão
				var pest: Vector2 = Vector2(e["x"], e["y"] - 40 * ESC)
				particulas.append({"p": pest, "v": Vector2.ZERO, "vida": 0.4, "max": 0.4, "cor": Color(1.0, 0.95, 0.4), "r": 34.0, "g": 0.0, "tipo": 4, "rot": 0.3, "vrot": 2.0})
				particulas.append({"p": pest, "v": Vector2.ZERO, "vida": 0.28, "max": 0.28, "cor": Color(1, 1, 1), "r": 20.0, "g": 0.0, "tipo": 4, "rot": 0.0, "vrot": -3.0})
				particulas.append({"p": pest, "v": Vector2.ZERO, "vida": 0.22, "max": 0.22, "cor": Color(1.0, 0.95, 0.5, 0.5), "r": 16.0, "g": 0.0, "tipo": 1})
			"barreira":
				var pb2: Vector2 = Vector2(e["x"], e["y"] - 34 * ESC)
				_som("barreira", 1.0, -5.0)
				particulas.append({"p": pb2, "v": Vector2.ZERO, "vida": 0.4, "max": 0.4, "cor": Color(0.45, 0.7, 1.0, 0.6), "r": 22.0, "g": 0.0, "tipo": 1})
				_faisca(pb2, Color(0.6, 0.85, 1.0), 10, 200.0, 0.4, 3.0)
				_numero(pb2 + Vector2(0, -34), Idioma.t("barreira"), Color(0.6, 0.85, 1.0), 16)
			"disfarce_rasga":
				var pd: Vector2 = Vector2(e["x"], e["y"] - 36 * ESC)
				_som("barreira", 0.8, -4.0)
				_faisca(pd, Color(1.0, 0.9, 0.3), 14, 220.0, 0.8, 5.0)
				_faisca(pd, Color(0.98, 0.75, 0.2), 8, 160.0, 0.9, 4.0)
				_faisca(pd, Color(0.35, 0.2, 0.15), 6, 190.0, 0.7, 3.0)
				particulas.append({"p": pd, "v": Vector2.ZERO, "vida": 0.35, "max": 0.35, "cor": Color(1.0, 0.95, 0.5, 0.6), "r": 26.0, "g": 0.0, "tipo": 1})
				_numero(pd + Vector2(0, -36), Idioma.t("Disfarce rasgou!"), Color(1.0, 0.9, 0.35), 20, 1.3, 190.0)
			"disfarce_refaz":
				var pr2: Vector2 = Vector2(e["x"], e["y"] - 36 * ESC)
				_faisca(pr2, Color(1.0, 0.92, 0.45), 10, 120.0, 0.6, 3.0)
			"reflete":
				var prf: Vector2 = Vector2(e["x"], e["y"] - 20 * ESC)
				_som("barreira", 1.4, -5.0, true)
				_faisca(prf, Color(0.7, 0.95, 1.0), 8, 200.0, 0.4, 3.0)
			"apara":
				# faca brilhando no aparo: clarão, faíscas e o texto
				var ppy: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				_som("barreira", 1.6, -2.0, true)
				_faisca(ppy, Color(1.0, 1.0, 0.9), 12, 240.0, 0.4, 3.5)
				_numero(ppy + Vector2(0, -26), Idioma.t("Aparou!"), Color(0.9, 0.95, 1.0), 20, 1.0, 140.0)
				tremor = maxf(tremor, 2.5)
				fx.append({"poder": -2, "p": ppy, "c": ppy, "alvos": [Vector2(float(e["ax"]), float(e["ay"]) - 30 * ESC)], "cor": Color(0.9, 0.95, 1.0), "t": 0.0, "dur": 0.45, "sem": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], "ex": {}})
			"kameha":
				_som("golpe_forte", 0.5, -1.0, true)
				fx.append({"poder": -3, "p": Vector2(e["x"], e["y"]), "c": Vector2(e["x"], e["y"]), "alvos": [], "cor": Color(0.4, 0.75, 1.0), "t": 0.0, "dur": Balanco.PODER_KAMEHA_FEIXE_T,
					"sem": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], "ex": {"x0": float(e["x"]), "y0": float(e["y"]), "x1": float(e["x1"])}})
				tremor = maxf(tremor, 6.0)
			"carga_corta":
				var pcc: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				_som("barreira", 0.6, -2.0, true)
				_faisca(pcc, Color(0.5, 0.7, 1.0), 10, 200.0, 0.4, 3.0)
				_numero(pcc + Vector2(0, -24), Idioma.t("Interrompido!"), Color(1.0, 0.5, 0.4), 20, 1.0, 140.0)
			"laco_passa":
				var plp: Vector2 = Vector2(e["x"], e["y"] - 20 * ESC)
				_faisca(plp, Color(1.0, 0.4, 0.5), 8, 160.0, 0.4, 3.0)
			"captura":
				var pcp: Vector2 = Vector2(e["x"], e["y"] - 24 * ESC)
				_som("poder_pronto", 1.7, -2.0, true)
				_faisca(pcp, Color(1.0, 1.0, 0.9), 14, 220.0, 0.5, 3.5)
				_numero(pcp + Vector2(0, -26), Idioma.t("Capturado!"), Color(1.0, 0.5, 0.45), 22, 1.2, 160.0)
			"medo":
				_faisca(Vector2(e["x"], e["y"] - 40 * ESC), Color(1.0, 0.9, 0.3), 3, 90.0, 0.3, 2.5)
			"folego":
				var pfo: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				_som("poder_pronto", 1.3, -1.0, true)
				_faisca(pfo, Color(0.6, 1.0, 0.9), 14, 220.0, 0.5, 3.5)
				_numero(pfo + Vector2(0, -26), Idioma.t("Segundo fôlego!"), Color(0.6, 1.0, 0.9), 22, 1.2, 160.0)
			"estase_fim":
				var pef: Vector2 = Vector2(e["x"], e["y"] - 24 * ESC)
				_som("golpe_forte", 0.9, -2.0, true)
				_faisca(pef, Color(0.7, 0.9, 1.0), 12, 240.0, 0.45, 3.5)
			"radio_explode":
				var per: Vector2 = Vector2(e["x"], e["y"] - 20 * ESC)
				_som("golpe_forte", 0.8, -1.0, true)
				_faisca(per, Color(0.55, 1.0, 0.3), 18, 280.0, 0.55, 4.0)
				fx.append({"poder": -4, "p": per, "c": per, "alvos": [], "cor": Color(0.55, 1.0, 0.3), "t": 0.0, "dur": 0.45, "sem": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], "ex": {"raio": float(e["raio"])}})
				tremor = maxf(tremor, 2.5)
			"recompensa_paga":
				var prp: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				_som("poder_pronto", 1.5, -1.0, true)
				_faisca(prp, Color(1.0, 0.85, 0.2), 16, 240.0, 0.55, 3.5)
				_numero(prp + Vector2(0, -26), Idioma.t("Recompensa paga!"), Color(1.0, 0.85, 0.2), 22, 1.3, 180.0)
			"escudo_quebra":
				_faisca(Vector2(e["x"], e["y"] - 30 * ESC), Color(0.6, 0.9, 1.0), 6, 160.0, 0.3, 2.5)
			"fala":
				_numero(Vector2(e["x"], e["y"] - 110 * ESC), Idioma.t(String(e["txt"])), Color(1.0, 0.35, 0.35), 26, 1.4, 220.0)
			"schro_caixa":
				# Schrödinger fecha a caixa: nuvem de papelão e o frasco que quebra
				var pc_s: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				_som("poder_explosao", 0.8, -8.0, true)
				_faisca(pc_s, Color(0.75, 0.58, 0.36), 14, 220.0, 0.5, 4.0)
				_faisca(pc_s, Color(0.55, 1.0, 0.35), 10, 160.0, 0.6, 3.0)
				_numero(pc_s + Vector2(0, -70), Idioma.t("Caixa fechada!"), Color(0.7, 1.0, 0.5), 22, 1.2, 180.0)
			"veneno":
				# veneno do frasco: bolhas verdes no raio, a cada pulso
				var pv: Vector2 = Vector2(e["x"], e["y"] - 10 * ESC)
				var rv: float = float(e["raio"])
				for k in 6:
					var a_v: float = randf() * TAU
					var d_v: float = randf() * rv
					particulas.append({"p": pv + Vector2(cos(a_v) * d_v, sin(a_v) * d_v * 0.45), "v": Vector2(0, -40), "vida": 0.6, "max": 0.6, "cor": Color(0.45, 1.0, 0.3, 0.8), "r": 5.0, "g": 0.0, "tipo": 0})
				particulas.append({"p": pv, "v": Vector2.ZERO, "vida": 0.4, "max": 0.4, "cor": Color(0.35, 0.9, 0.25, 0.22), "r": rv * 0.5, "g": 0.0, "tipo": 1})
			"schro_divide":
				# superposição: chiado azul entre as duas posições e o aviso
				var p1: Vector2 = Vector2(e["x"], float(e["y"]) - 30 * ESC)
				var p2: Vector2 = Vector2(e["x"], float(e["y2"]) - 30 * ESC)
				_som("poder_raio", 1.4, -6.0, true)
				_faisca(p1, Color(0.4, 0.9, 1.0), 12, 200.0, 0.5, 3.0)
				_faisca(p2, Color(0.4, 0.9, 1.0), 12, 200.0, 0.5, 3.0)
				_numero(p1.lerp(p2, 0.5) + Vector2(0, -80), Idioma.t("Superposição!"), Color(0.5, 0.9, 1.0), 24, 1.4, 220.0)
			"schro_some":
				_faisca(Vector2(e["x"], e["y"] - 30 * ESC), Color(0.6, 0.9, 1.0), 14, 160.0, 0.5, 3.0)
			"muda":
				var pm: Vector2 = Vector2(e["x"], e["y"] - 10 * ESC)
				match int(e["res"]):
					0:
						_som("poder_explosao", 1.4, -6.0, true)
						var rpm: float = float(e.get("raio", 70.0))
						_faisca(pm, Color(1.0, 0.45, 0.1), 16, 260.0, 0.6, 4.0)
						_faisca(pm, Color(1.0, 0.9, 0.4), 8, 180.0, 0.4, 3.0)
						particulas.append({"p": pm, "v": Vector2.ZERO, "vida": 0.45, "max": 0.45, "cor": Color(1.0, 0.4, 0.15, 0.55), "r": rpm * 0.6, "g": 0.0, "tipo": 1})
						_numero(pm + Vector2(0, -30), Idioma.t("Pimenta!"), Color(1.0, 0.55, 0.3), 20, 1.0, 140.0)
					1:
						_som("poder_cura", 1.5, -7.0)
						_faisca(pm, Color(1.0, 0.45, 0.6), 10, 150.0, 0.6, 3.0)
						_faisca(Vector2(float(e.get("ax", e["x"])), float(e.get("ay", e["y"])) - 40 * ESC), Color(0.45, 1.0, 0.55), 8, 100.0, 0.6, 3.0)
						_numero(pm + Vector2(0, -30), Idioma.t("Morango!"), Color(1.0, 0.6, 0.7), 20, 1.0, 140.0)
					_:
						_faisca(pm, Color(0.55, 0.4, 0.25), 6, 90.0, 0.5, 2.5)
						_numero(pm + Vector2(0, -24), Idioma.t("murchou"), Color(0.7, 0.6, 0.5), 14, 0.8, 100.0)
			"cantil":
				var pc2: Vector2 = Vector2(e["x"], e["y"] - 46 * ESC)
				_faisca(pc2, Color(0.4, 0.95, 0.6), 8, 110.0, 0.6, 3.0)
				_numero(pc2, Idioma.t("glub! cura"), Color(0.5, 1.0, 0.65), 18)
				_som("poder_cura", 1.3, -9.0)
			"sementes":
				var ps: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				_faisca(ps, Color(0.55, 0.9, 0.3), 16, 280.0, 0.7, 3.4)
				_faisca(ps, Color(0.95, 0.85, 0.4), 8, 180.0, 0.6, 2.4)
				particulas.append({"p": ps, "v": Vector2.ZERO, "vida": 0.6, "max": 0.6, "cor": Color(0.5, 0.9, 0.35, 0.35), "r": 40.0, "g": 0.0, "tipo": 1})
				_numero(ps + Vector2(0, -30), Idioma.t("sementes!"), Color(0.6, 1.0, 0.4), 18, 1.1, 120.0)
				_som("poder", 1.3, -8.0)
			"saque":
				var pq: Vector2 = Vector2(e["x"], e["y"] - 60 * ESC)
				_faisca(pq, Color(0.95, 0.7, 0.35), 8, 160.0, 0.5, 3.0)
				_numero(pq, Idioma.t("+1 bloco"), Color(1.0, 0.8, 0.45), 20, 1.2, 120.0)
				_som("drop", 1.2, -7.0)
			"reforco":
				var pf: Vector2 = Vector2(e["x"], e["y"] - 50 * ESC)
				_faisca(pf, Color(1.0, 0.4, 0.3), 16, 240.0, 0.6, 3.6)
				particulas.append({"p": pf, "v": Vector2.ZERO, "vida": 0.5, "max": 0.5, "cor": Color(1.0, 0.35, 0.25, 0.4), "r": 30.0, "g": 0.0, "tipo": 1})
				_numero(pf + Vector2(0, -40), Idioma.t("Reforços!"), Color(1.0, 0.5, 0.4), 26, 1.4, 180.0)
				_som("poder", 0.8, -4.0, true)
				tremor = maxf(tremor, 6.0)
			"corda":
				var pw: Vector2 = Vector2(e["x"], e["y"] - 70 * ESC)
				if e.get("parado", false):
					_numero(pw, Idioma.t("sem fôlego..."), Color(0.6, 0.85, 1.0), 24, 1.6, 200.0)
					_faisca(pw, Color(0.55, 0.82, 1.0), 8, 90.0, 0.7, 3.0)
				else:
					_numero(pw, Idioma.t("disparou!"), Color(1.0, 0.7, 0.3), 24, 1.2, 160.0)
					_faisca(pw, Color(1.0, 0.7, 0.3), 12, 200.0, 0.5, 3.0)
			"partes":
				var pp2: Vector2 = Vector2(e["x"], e["y"] - 40 * ESC)
				_faisca(pp2, Color(0.3, 0.6, 0.28), 18, 300.0, 0.7, 5.0)
				_faisca(pp2, Color(0.45, 0.72, 0.36), 12, 260.0, 0.6, 4.0)
				_som("bicho_cai", 0.7, -3.0, true)
				particulas.append({"p": pp2, "v": Vector2.ZERO, "vida": 0.5, "max": 0.5, "cor": Color(0.45, 0.72, 0.36, 0.5), "r": 40.0, "g": 0.0, "tipo": 1})
				tremor = maxf(tremor, 7.0)
			"drop":
				var rar: int = int(e.get("raridade", 0))
				voando.append({"ini": Vector2(e["x"], e["y"] - 40 * ESC), "tipo": e["tipo"], "t": 0.0, "marca": e.get("marca", -1), "rar": rar,
					"py": float(e["y"]) - 40.0 * ESC, "vy": -240.0, "vx": randf_range(-45.0, 45.0), "chao": float(e["y"]) - 6.0, "esp": 0.5, "quicou": 0})
				if rar > 0:
					var cr: Color = Pecas.cor_rar(rar)
					var pr0: Vector2 = Vector2(e["x"], e["y"] - 60 * ESC)
					# faíscas: a Mítica solta várias cores; a Miaujestosa, pérola e rosa
					var nf: int = 8 + 6 * rar
					for kf in nf:
						var cf: Color = cr
						if rar == Pecas.Raridade.MITICA:
							cf = Color.from_hsv(float(kf) / nf, 0.55, 1.0)
						elif rar >= Pecas.Raridade.MIAUJESTOSA:
							cf = Color(1.0, 0.97, 0.9) if kf % 2 == 0 else Color(1.0, 0.72, 0.88)
						_faisca(pr0, cf, 1, 220.0, 0.8, 3.6)
					tfx.append({"k": "drop_rar", "p": pr0 + Vector2(0, 40 * ESC), "rar": rar, "t": 0.0, "dur": 0.9 + 0.1 * rar})
					_numero(pr0 + Vector2(0, -30), Idioma.t("%s!") % Idioma.t(Pecas.RARIDADE_NOME[clampi(rar, 0, Pecas.RARIDADE_NOME.size() - 1)]), cr, 22 + 2 * rar, 1.4, 280.0)
					if rar >= 3:
						tremor = maxf(tremor, 5.0 + (rar - 3) * 1.5)
			"marca":
				# a morte marcou a roupa: nome da marca sobe na cor dela
				var mk: int = e["marca"]
				var cm: Color = Pecas.MARCA_COR[mk]
				var pm: Vector2 = Vector2(e["x"], e["y"] - 84 * ESC)
				_faisca(pm + Vector2(0, 20), cm, 10 + 5 * int(e["n"]), 210.0, 0.8, 3.6)
				_faisca(pm + Vector2(0, 20), Color(1, 1, 1), 5, 140.0, 0.45, 2.4)
				_som("marca", 1.0, -4.0)
				_numero(pm, Idioma.t(Pecas.MARCA_NOME[mk]), cm, 24, 1.5, 140.0)
			"nivel":
				var p3: Vector2 = Vector2(e["x"], e["y"] - 60 * ESC)
				_faisca(p3, Desenho.DOURADO, 14, 170.0, 0.7, 3.5)
				_numero(p3 + Vector2(0, -22), Idioma.t("nível %d") % int(e["nivel"]), Desenho.DOURADO, 18)
				_som("poder_pronto", 1.35, -7.0)
			"devolve":
				var pd: Vector2 = Vector2(e["x"], e["y"] - 70 * ESC)
				_faisca(pd, Color(0.9, 0.55, 0.35), 10, 200.0, 0.6, 3.5)
				_numero(pd, Idioma.t("+%d blocos") % int(e["n"]), Color(0.6, 1.0, 0.6), 22, 1.4, 160.0)
				_som("drop", 1.1, -6.0)
			"fuga":
				if int(e["n"]) > 0:
					_numero(Vector2(1180, e["y"] - 70 * ESC), (Idioma.t("fugiu! -%d bloco") if int(e["n"]) == 1 else Idioma.t("fugiu! -%d blocos")) % int(e["n"]), Color(1.0, 0.5, 0.4), 22, 1.4, 160.0)
					_som("negado", 0.9, -6.0)
			"oferta":
				# Mensageiro da Família Gatíssima: o gato leva uma oferta que não pode recusar
				var pof: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				tremor = maxf(tremor, 4.0)
				_som("negado", 0.7, -2.0, true)
				_faisca(pof, Color(0.75, 0.2, 0.3), 14, 220.0, 0.5, 3.5)
				_faisca(Vector2(e["mx"], e["my"] - 30 * ESC), Color(0.2, 0.15, 0.2), 8, 160.0, 0.4, 3.0)
				_numero(pof + Vector2(0, -30), Idioma.t("Dorme com os peixes!"), Color(1.0, 0.55, 0.6), 22, 1.4, 200.0)
			"acorda":
				var pac: Vector2 = Vector2(e["x"], e["y"] - 40 * ESC)
				_faisca(pac, Color(0.85, 0.92, 1.0), 8, 150.0, 0.4, 3.0)
				_numero(pac, Idioma.t("Acordou!"), Color(0.85, 0.95, 1.0), 18, 0.9, 100.0)
			"atropelo":
				var pat: Vector2 = Vector2(e["x"], e["y"] - 24 * ESC)
				_som("golpe_forte", 1.1, -3.0, true)
				_faisca(pat, Color(1.0, 0.6, 0.2), 10, 240.0, 0.4, 3.5)
				_poeira(Vector2(e["x"], e["y"]), 1.0, 4, 1.2)
			"recompila":
				var prc: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				_som("poder_pronto", 1.5, -2.0, true)
				_faisca(prc, Color(0.3, 0.9, 1.0), 16, 260.0, 0.5, 3.5)
				_numero(prc + Vector2(0, -26), Idioma.t("Recompilando!"), Color(0.4, 0.95, 1.0), 20, 1.2, 160.0)
			"telepata":
				var ptp: Vector2 = Vector2(e["x"], e["y"] - 40 * ESC)
				_som("negado", 1.3, -4.0, true)
				_faisca(ptp, Color(0.8, 0.5, 1.0), 10, 200.0, 0.5, 3.0)
				_numero(ptp + Vector2(0, -20), Idioma.t("Confuso!"), Color(0.85, 0.6, 1.0), 20, 1.0, 120.0)
			"mutacao":
				var pmu: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				_som("poder_pronto", 0.7, -2.0, true)
				_faisca(pmu, Color(0.7, 0.3, 1.0), 12, 240.0, 0.5, 3.5)
				_faisca(pmu, Color(1.0, 0.9, 0.2), 6, 180.0, 0.4, 3.0)
				_numero(pmu + Vector2(0, -26), Idioma.t("Mutação!"), Color(0.85, 0.5, 1.0), 20, 1.2, 140.0)
			"gemeos":
				_faisca(Vector2(e["x"], e["y"] - 30 * ESC), Desenho.COR_TIPO[Unidade.Tipo.GEMEO], 12, 200.0, 0.5, 3.5)
			"torre":
				tremor = maxf(tremor, 7.0)
				torre_pulso = 1.0
				golpe_torre = 1.0
				_som("bloco_perdido", 1.0, -2.0, true)
				_poeira(Vector2(110, TORRE_BASE.y + 2.0), -1.0, 5, 1.6)
				var i: int = estado.tijolos
				var n_perdidos: int = int(e["n"])
				for k in n_perdidos:
					# com a fortaleza, o bloco sai do lugar que tinha na torre antes do golpe
					var r: Rect2 = TorrePx.rect_bloco(_base_f(), i + k, i + n_perdidos, estado.tijolos_max(), rel, 0.0) if TORRE_FORTALEZA else Desenho.rect_tijolo(i + k, TORRE_BASE, 1.0)
					particulas.append({"p": r.get_center(), "v": Vector2(randf_range(40, 140), randf_range(-220, -90)), "vida": 1.5, "max": 1.5, "cor": Desenho.cor_tijolo(i + k), "idx": i + k, "r": 0.0, "g": 700.0, "tipo": 2, "rot": 0.0, "vrot": randf_range(-6, 6), "chao": TORRE_BASE.y + 6.0, "q": 2})
				_faisca(Vector2(Balanco.TORRE_X, e["y"] - 30), Color(0.9, 0.55, 0.35), 6, 150.0, 0.4, 3.0)
			"trofeu":
				# troféu dourado sobe do bicho e voa em arco até o contador do HUD
				var nt: int = int(e.get("n", 1))
				var pt: Vector2 = Vector2(e["x"], e["y"] - 44 * ESC)
				tfx.append({"k": "trofeu", "ini": pt, "t": 0.0, "dur": 1.2, "n": nt})
				_faisca(pt, Desenho.DOURADO, 6 + 2 * mini(nt, 5), 150.0, 0.5, 3.0)
				_numero(pt + Vector2(0, -34), "+%d" % nt, Desenho.DOURADO, 22 if nt < 5 else 32, 1.2, 100.0)
			"ratoeira":
				# a ratoeira estala: clarão, "PLAC!" e faísca no bicho que bateu
				ratoeira_t = 0.45
				_som("ratoeira", 1.0, -3.0, true)
				var cr: Vector2 = _centro_modulo(Torre.Modulo.RATOEIRA)
				numeros.append({"p": cr + Vector2(0, -40), "txt": Idioma.t("PLAC!"), "cor": Color(1.0, 0.9, 0.3), "vida": 0.9, "tam": 26, "larg": 120.0, "ct": 6})
				var pr_r: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				_faisca(pr_r, Color(1.0, 0.95, 0.6), 10, 240.0, 0.35, 2.6)
				_faisca(cr, Color(1.0, 0.9, 0.5), 6, 120.0, 0.3, 2.2)
				particulas.append({"p": pr_r, "v": Vector2.ZERO, "vida": 0.25, "max": 0.25, "cor": Color(1.0, 1.0, 0.8, 0.6), "r": 12.0, "g": 0.0, "tipo": 1})
			"catapulta":
				# o braço dispara; o saco voa em arco até (x, y) e estoura em ração
				catapulta_t = 0.0
				_som("catapulta", 1.0, -3.0, true)
				var ini_c: Vector2 = TorrePx.ponta_catapulta(_base_f(), maxi(_slot_modulo(Torre.Modulo.CATAPULTA), 0), estado.modulos.size())
				tfx.append({"k": "saco", "ini": ini_c, "fim": Vector2(e["x"], e["y"]), "t": 0.0, "dur": 0.85, "raio": float(e.get("raio", Torre.CATAPULTA_RAIO))})
				_faisca(ini_c + Vector2(0, 8), Color(0.85, 0.65, 0.35), 5, 100.0, 0.3, 2.4)
			"sirene":
				# a luz gira, ondas vermelhas varrem a tela e os bichos ganham estrelas
				sirene_t = 2.0
				_som("sirene", 1.0, -3.0, true)
				var cs: Vector2 = _centro_modulo(Torre.Modulo.SIRENE)
				for k in 3:
					tfx.append({"k": "onda", "p": cs, "raio": 1300.0, "cor": Color(1.0, 0.25, 0.2), "t": -0.3 * k, "dur": 1.1, "chao": false})
				numeros.append({"p": cs + Vector2(0, -44), "txt": Idioma.t("ALARME!"), "cor": Color(1.0, 0.4, 0.35), "vida": 1.2, "tam": 24, "larg": 160.0, "ct": 6})
				tremor = maxf(tremor, 2.0)
				for u in sim.inimigos:
					var ui: Unidade = u
					for k in 3:
						var ang_e: float = -PI * 0.5 + randf_range(-1.0, 1.0)
						particulas.append({"p": Vector2(ui.x, ui.y - 52 * ESC), "v": Vector2(cos(ang_e), sin(ang_e)) * randf_range(40, 90), "vida": 0.8, "max": 0.8, "cor": Desenho.DOURADO, "r": 5.5, "g": 90.0, "tipo": 4, "rot": randf() * TAU, "vrot": randf_range(-6, 6)})
			"balista":
				# traço de pena do alvo original até o bicho de trás
				balista_t = 0.3
				_som("tiro", 1.4, -6.0)
				var pa_b: Vector2 = Vector2(e["x0"], e["y0"] - 30 * ESC)
				var pb_b: Vector2 = Vector2(e["x"], e["y"] - 30 * ESC)
				tfx.append({"k": "pena", "a": pa_b, "b": pb_b, "t": 0.0, "dur": 0.4})
				_faisca(pb_b, Color(1.0, 0.85, 0.85), 6, 90.0, 0.6, 2.4)
			"fosso":
				# o bicho mais perto cai no buraco: poeira, "PLOFT!" e estrelas
				fosso_t = 0.6
				_som("pancada", 0.8, -4.0, true)
				var pf: Vector2 = Vector2(e["x"], e["y"] - 10 * ESC)
				numeros.append({"p": pf + Vector2(0, -40), "txt": Idioma.t("PLOFT!"), "cor": Color(0.85, 0.7, 0.45), "vida": 0.9, "tam": 24, "larg": 140.0, "ct": 6})
				_faisca(pf, Color(0.7, 0.55, 0.38), 12, 150.0, 0.5, 3.0)
				tfx.append({"k": "fosso", "p": pf, "t": 0.0, "dur": 0.7})
				for k in 3:
					var ang_f: float = -PI * 0.5 + randf_range(-1.0, 1.0)
					particulas.append({"p": pf + Vector2(0, -40 * ESC), "v": Vector2(cos(ang_f), sin(ang_f)) * randf_range(40, 80), "vida": 0.9, "max": 0.9, "cor": Desenho.DOURADO, "r": 5.0, "g": 80.0, "tipo": 4, "rot": randf() * TAU, "vrot": randf_range(-6, 6)})
			"reforco":
				# o golpe na torre não derruba bloco: clarão azulado e "FIRME!"
				reforco_t = 0.45
				_som("escudo", 1.0, -4.0, true)
				var pr2: Vector2 = _centro_modulo(Torre.Modulo.REFORCO)
				numeros.append({"p": pr2 + Vector2(0, -44), "txt": Idioma.t("FIRME!"), "cor": Color(0.7, 0.88, 1.0), "vida": 0.9, "tam": 22, "larg": 120.0, "ct": 6})
				_faisca(Vector2(e["x"], e["y"] - 30 * ESC), Color(0.7, 0.88, 1.0), 8, 160.0, 0.35, 2.6)
				tfx.append({"k": "reforco", "p": _centro_modulo(Torre.Modulo.REFORCO) + Vector2(20, -10), "t": 0.0, "dur": 0.5})
			"luneta":
				luneta_t = 0.5
				tfx.append({"k": "luneta", "p": Vector2(e["x"], e["y"] - 40 * ESC), "t": 0.0, "dur": 0.5})
				_faisca(Vector2(e["x"], e["y"] - 50 * ESC), Color(1.0, 0.95, 0.5), 5, 80.0, 0.4, 2.4)
			"luneta_crit":
				_numero(Vector2(e["x"], e["y"] - 70 * ESC), "×2", Color(1.0, 0.9, 0.3), 20, 0.8, 80.0)
				_faisca(Vector2(e["x"], e["y"] - 40 * ESC), Color(1.0, 0.9, 0.3), 6, 140.0, 0.3, 2.6)
			"caldeirao":
				# bolha sobe até o topo e um bloco novo assenta com brilho
				caldeirao_t = 1.0
				_som("caldeirao", 1.0, -4.0, true)
				if TORRE_FORTALEZA:
					novo_idx = estado.tijolos - 1
					novo_s = 0.0
				var cc: Vector2 = _centro_modulo(Torre.Modulo.CALDEIRAO)
				var topo_c: Vector2 = TorrePx.centro_topo(_base_f(), estado.tijolos, estado.tijolos_max(), rel, 0.0) if TORRE_FORTALEZA else Vector2(90, 480)
				tfx.append({"k": "bolha", "ini": cc + Vector2(0, -14), "fim": topo_c, "t": 0.0, "dur": 0.6})
				_numero(topo_c + Vector2(0, -30), "+1", Color(0.55, 1.0, 0.55), 20, 1.0, 80.0)
	sim.eventos.clear()

## Base da torre-fortaleza (canto esquerdo do corpo, no chão), alinhada à grade de 4 px.
func _base_f() -> Vector2:
	return Vector2(roundf(TORRE_BASE.x / 4.0) * 4.0, TORRE_BASE.y)

## Em qual encaixe (0 = direito, 1 = esquerdo) está o módulo; -1 se não está montado.
func _slot_modulo(m: int) -> int:
	var idx: int = estado.modulos.find(m)
	return idx if idx >= 0 and idx < 4 else -1

func _centro_modulo(m: int) -> Vector2:
	var s: int = _slot_modulo(m)
	if s < 0:
		return _base_f() + Vector2(80, -40)
	return TorrePx.rect_encaixe(_base_f(), s, estado.modulos.size()).get_center()

## Aliados e inimigos do fundo para a frente (menor vy primeiro; empate: aliados antes, na ordem da lista).
## Ordena uma chave numérica (vy em 1/64 px * 65536 + posição) com o sort nativo: sem lambda, sem comparação em GDScript.
var _ord_unid: Array[Unidade] = []
var _ord_chaves: PackedFloat64Array = PackedFloat64Array()
var _ord_saida: Array = []
func _ordem_profundidade() -> Array:
	_ord_unid.clear()
	_ord_unid.append_array(sim.aliados)
	_ord_unid.append_array(sim.inimigos)
	var n: int = _ord_unid.size()
	_ord_chaves.resize(n)
	for i in n:
		_ord_chaves[i] = floorf(_ord_unid[i].vy * 64.0) * 65536.0 + float(i)
	_ord_chaves.sort()
	_ord_saida.resize(n)
	for i in n:
		_ord_saida[i] = _ord_unid[int(_ord_chaves[i]) & 65535]
	return _ord_saida

func _op_torre() -> Dictionary:
	return {
		"recuo": recuo_canhao, "pulso": torre_pulso * 0.6, "vitoria": sim.terminada and sim.vitoria,
		"luta": not sim.terminada, "vigia": TORRE_VIGIA, "ratoeira": ratoeira_t, "catapulta": catapulta_t,
		"sirene": sirene_t, "balista": balista_t, "caldeirao": caldeirao_t, "fosso": fosso_t, "reforco": reforco_t, "luneta": luneta_t, "novo_idx": novo_idx, "novo_s": novo_s,
	}

## Quanto o tiro da torre ainda está "preso" à boca do canhão (o simulador o cria em x = TORRE_X - 70):
## vira um desvio que vai a zero em ~90 px de voo, para o tiro nascer na boca do canhão.
func _desvio_boca(x: float) -> Vector2:
	if not TORRE_FORTALEZA:
		return Vector2.ZERO
	var ini: Vector2 = Vector2(Balanco.TORRE_X - 70.0, Balanco.CHAO_Y0 + 20.0 - TIRO_ALT * ESC)
	var k: float = clampf(1.0 - (x - ini.x) / 90.0, 0.0, 1.0)
	if k <= 0.0:
		return Vector2.ZERO
	var boca: Vector2 = TorrePx.boca_canhao(_base_f(), estado.tijolos, estado.tijolos_max(), estado.melhorias, rel, golpe_torre, recuo_canhao)
	return (boca - ini) * (k * k * (3.0 - 2.0 * k))

## Fim de um efeito da torre (aterrissagem do saco, chegada do troféu).
func _fim_tfx(f: Dictionary) -> void:
	match f["k"]:
		"saco":
			var fim: Vector2 = f["fim"]
			var raio: float = f["raio"]
			var pc: Vector2 = fim + Vector2(0, -14)
			_faisca(pc, Color(0.75, 0.5, 0.25), 16, 240.0, 0.6, 3.5)
			_faisca(pc, Color(0.9, 0.75, 0.45), 10, 160.0, 0.5, 2.6)
			particulas.append({"p": pc, "v": Vector2.ZERO, "vida": 0.6, "max": 0.6, "cor": Color(0.8, 0.6, 0.35, 0.5), "r": raio * 0.35, "g": 0.0, "tipo": 1})
			tfx.append({"k": "onda", "p": fim, "raio": raio, "cor": Color(0.9, 0.7, 0.4), "t": 0.0, "dur": 0.5, "chao": true})
			tremor = maxf(tremor, 3.0)
		"trofeu":
			trofeu_pulso = 1.0
			_som("trofeu", 1.0, -3.0, true)
			_faisca(TROFEU_CONTADOR + Vector2(9, 8), Desenho.DOURADO, 6, 110.0, 0.4, 2.6)
		"bolha":
			var fb: Vector2 = f["fim"]
			_faisca(fb, Color(0.6, 1.0, 0.6), 8, 130.0, 0.5, 2.8)
			_faisca(fb, Color(1.0, 0.95, 0.7), 5, 90.0, 0.4, 2.2)

## Faíscas em linha, saindo em leque no sentido do golpe (dir = +1 direita, -1 esquerda).
## Clareia a cor (em direção ao branco) até atingir a luminância mínima.
func _cor_legivel(c: Color, lum_min: float) -> Color:
	var r := Color(c.r, c.g, c.b, 1.0)
	for i in 10:
		if r.get_luminance() >= lum_min:
			break
		r = r.lerp(Color(1, 1, 1), 0.18)
	return r

## Texto com contorno escuro que acompanha o alfa da cor (some junto com o texto).
func _texto_c(txt: String, pos: Vector2, tam: int, cor: Color, larg: float, ct: int) -> void:
	var fonte: Font = UIComum.FONTE
	if ct > 0:
		draw_string_outline(fonte, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, larg, UIComum.tam(tam), ct, Color(0.04, 0.02, 0.06, 0.92 * cor.a))
	draw_string(fonte, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, larg, UIComum.tam(tam), cor)

func _centelha(p: Vector2, dir: float, cor: Color, n: int) -> void:
	for i in n:
		var a: float = randf_range(-0.7, 0.7)
		var v: Vector2 = Vector2(cos(a) * dir, sin(a) - 0.25) * randf_range(180.0, 330.0)
		particulas.append({"p": p, "v": v, "vida": randf_range(0.14, 0.24), "max": 0.24, "cor": cor, "r": randf_range(1.6, 2.6), "g": 200.0, "tipo": 3})
	particulas.append({"p": p, "v": Vector2.ZERO, "vida": 0.1, "max": 0.1, "cor": Color(1, 1, 0.9, 0.55), "r": 9.0, "g": 0.0, "tipo": 1})

func _unidade_perto(p: Vector2, eq: int) -> Unidade:
	var melhor: Unidade = null
	var dm: float = 48.0
	for u in (sim.inimigos if eq == 1 else sim.aliados):
		var uu: Unidade = u
		var d: float = Vector2(uu.x, uu.y).distance_to(p)
		if d < dm:
			dm = d
			melhor = uu
	return melhor

## Quanto o sprite de um chefe passa (px de tela) acima do topo padrão de corpo (CORPO_ALT): o balão do "!" e o nome
## do poder sobem isso para não cobrir a cara. Só o Esquilo Acrobata (cabeção + rabão por cima) precisa hoje.
func _topo_extra(uu: Unidade) -> float:
	if uu == null or not uu.chefe:
		return 0.0
	if uu.chefe_tipo == Fases.Chefe.CORUJA:
		return 55.0
	return 0.0

func _anel(c: Vector2, rx: float, ry: float, cor: Color, larg: float) -> void:
	var pts := PackedVector2Array()
	for i in 25:
		var a: float = TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, cor, larg)

func _poder_fx(poder: int, po: Vector2, alvos: Array, cor: Color, ex: Dictionary = {}) -> void:
	var dur: float = 0.9
	var centro: Vector2 = po + Vector2(70, 20)
	if not alvos.is_empty():
		centro = Vector2.ZERO
		for a in alvos:
			centro += a
		centro /= alvos.size()
	match poder:
		Pecas.Poder.RAIO:
			dur = 0.7
			tremor = maxf(tremor, 4.0)
		Pecas.Poder.EXPLOSAO:
			dur = 0.7
			tremor = maxf(tremor, 5.0)
			_faisca(centro, Color(1.0, 0.6, 0.15), 18, 300.0, 0.6, 4.5)
			_faisca(centro, Color(1.0, 0.95, 0.5), 8, 200.0, 0.4, 3.0)
		Pecas.Poder.ATORDOA:
			dur = 1.4
		Pecas.Poder.CURA:
			dur = 1.1
		Pecas.Poder.PROTEGE:
			dur = 1.2
		Pecas.Poder.FRENESI:
			dur = 0.9
		Pecas.Poder.ATRAVESSA:
			dur = 0.55 if int(ex.get("eq", 0)) == 0 else 0.7   # rasante de bicho: tempo para o salto atravessar a faixa
		Pecas.Poder.RAJADA:
			dur = 0.85
		Pecas.Poder.GELO:
			dur = 1.3
		Pecas.Poder.EMPURRA:
			dur = 0.7
			tremor = maxf(tremor, 3.0)
		Pecas.Poder.GIRO:
			dur = 0.75
		Pecas.Poder.DRENO:
			dur = 1.1
		Pecas.Poder.INVOCA:
			dur = 0.7
			for a in alvos:
				for kc in 6:
					particulas.append({"p": a + Vector2(randf_range(-12, 12), randf_range(-10, 24)), "v": Vector2(randf_range(-40, 40), randf_range(-60, -15)), "vida": 0.6, "max": 0.6, "cor": Color(0.9, 0.9, 0.9, 0.6), "r": randf_range(8, 13), "g": 0.0, "tipo": 1})
		Pecas.Poder.TELEPORTE:
			dur = 0.5
			tremor = maxf(tremor, 3.0)
			_faisca(po, Color(0.4, 0.8, 1.0), 12, 220.0, 0.4, 3.0)
		Pecas.Poder.PUXA:
			dur = 0.8
		Pecas.Poder.ENXAME:
			dur = 0.4
		Pecas.Poder.RAIZ:
			dur = 1.2
		Pecas.Poder.SAQUE:
			dur = 0.12 * alvos.size() + 0.5
		Pecas.Poder.TROVOADA:
			dur = 0.9
			tremor = maxf(tremor, 5.0)
		Pecas.Poder.CANHAO:
			dur = 1.0
			tremor = maxf(tremor, 6.0)
		Pecas.Poder.MISSEIS:
			dur = 0.18 * alvos.size() + 0.9
			tremor = maxf(tremor, 5.0)
		Pecas.Poder.CANCAO:
			dur = 1.4
		Pecas.Poder.INVESTIDA:
			dur = 0.7
			tremor = maxf(tremor, 4.0)
		Pecas.Poder.FUMACA:
			dur = 1.8
		Pecas.Poder.FURIA:
			dur = 0.9
			tremor = maxf(tremor, 3.0)
		Pecas.Poder.PISAO:
			dur = 0.2 * alvos.size() + 0.8
			tremor = maxf(tremor, 4.0)
		Pecas.Poder.CANTEIRO:
			dur = 1.1
		Pecas.Poder.TRIAGEM:
			dur = 1.2
		Pecas.Poder.MARCA:
			dur = 1.0
		Pecas.Poder.BOLA:
			dur = 0.7
		Pecas.Poder.SALVAMENTO:
			dur = 1.1
			tremor = maxf(tremor, 4.0)
		Pecas.Poder.RICOCHETE:
			dur = 0.12 * alvos.size() + 0.5
		Pecas.Poder.OLHAR:
			dur = 1.1
			tremor = maxf(tremor, 3.0)
		Pecas.Poder.OBJECAO:
			dur = 0.9
		Pecas.Poder.IMITAR:
			dur = 0.9
		Pecas.Poder.POQUER:
			dur = 1.1
			tremor = maxf(tremor, 3.0)
		Pecas.Poder.TORRE, Pecas.Poder.COLHEITA:
			dur = 0.8
		Pecas.Poder.MANTEIGA:
			dur = 0.9
		Pecas.Poder.REVIVER:
			dur = 1.3
		Pecas.Poder.CONSTRUIR:
			dur = 0.8
			tremor = maxf(tremor, 3.0)
		Pecas.Poder.COCHILO:
			dur = 1.2
		Pecas.Poder.PLANO:
			dur = 1.0
		Pecas.Poder.DOMO:
			dur = 0.9
		Pecas.Poder.LOBO:
			dur = 1.0
			tremor = maxf(tremor, 2.0)
		Pecas.Poder.TURBO:
			dur = 0.7
			tremor = maxf(tremor, 4.0)
		Pecas.Poder.ESFORCO:
			dur = 1.0
		Pecas.Poder.APAGAO:
			dur = 1.0
		Pecas.Poder.ESPIRITO:
			dur = 0.7
			tremor = maxf(tremor, 3.0)
		Pecas.Poder.LACO:
			dur = 1.0
		Pecas.Poder.KAMEHA:
			dur = Balanco.PODER_KAMEHA_CARGA
		Pecas.Poder.PEDRA:
			dur = 0.6
			tremor = maxf(tremor, 3.0)
		Pecas.Poder.CAPTURA:
			dur = 0.9
		Pecas.Poder.MEGAZORD:
			dur = 1.0
		Pecas.Poder.SOPRO:
			dur = 0.8
			tremor = maxf(tremor, 3.0)
		Pecas.Poder.BRADO:
			dur = 0.8
			tremor = maxf(tremor, 5.0)
		Pecas.Poder.RECOMPENSA:
			dur = 1.0
		Pecas.Poder.ESTASE:
			dur = 1.0
		Pecas.Poder.LOUCURA:
			dur = 1.0
		-4:
			dur = 0.45
		-3:
			dur = Balanco.PODER_KAMEHA_FEIXE_T
			tremor = maxf(tremor, 6.0)
		Pecas.Poder.CHUTE:
			dur = 0.6
			tremor = maxf(tremor, 4.0)
			_faisca(centro, Color(1.0, 0.95, 0.7), 10, 260.0, 0.5, 4.0)
			if int(ex.get("combos", 0)) > 0:
				_numero(centro + Vector2(0, -50), Idioma.t("Combo!"), Color(1.0, 0.85, 0.3), 24, 1.2, 160.0)
	var sem: Array = []
	for i in 8:
		sem.append(randf())
	fx.append({"poder": poder, "p": po, "c": centro, "alvos": alvos, "cor": cor, "t": 0.0, "dur": dur, "sem": sem, "ex": ex})
	if poder == Pecas.Poder.RAIO or poder == Pecas.Poder.TROVOADA:
		# o raio deixa o chão chamuscado onde caiu; a marca some sozinha em alguns segundos
		for a in (alvos if not alvos.is_empty() else [po]):
			queimados.append({"p": (a as Vector2) + Vector2(0, 24 * ESC), "t": 0.0, "dur": 3.2, "r": 36.0 if poder == Pecas.Poder.RAIO else 42.0, "cor": Color(1.0, 0.75, 0.25) if poder == Pecas.Poder.RAIO else Color(0.8, 0.62, 1.0)})
		while queimados.size() > 12:
			queimados.pop_front()

## Bolota do Esquilo que acabou de sair: a simulação cria o projétil no mesmo passo do golpe, enquanto o sprite ainda está na
## fase 1 (noz erguida atrás da cabeça, primeiros 20% de 0,22 s). Nesse instante, e só perto do dono, a bolota do voo fica
## escondida; ela aparece quando o braço já estica para a frente (fase 2), saindo da mão.
func _bolota_na_mao(d: Dictionary) -> bool:
	var dono: Unidade = d["dono"]
	if dono == null or not dono.chefe or dono.chefe_tipo != Fases.Chefe.CORUJA:
		return false
	return dono.golpe > 0.22 * 0.8 and absf(float(d["x"]) - dono.x) < 40.0

## Bolota em pixel (quadradinhos de V.Q): corpo marrom com luz e sombra, chapéu mais escuro com escamas e cabinho, contorno
## escuro de 1. `giro` 0..3 = quartos de volta (0 = chapéu para cima), em torno da célula (3, 3): coordenada inteira, sem meio pixel.
## O chapéu é mais largo que o corpo (a aba sobra dos dois lados) e o corpo afina numa ponta: silhueta de bolota, não de losango.
const _BOLOTA: Array = ["...s..", ".CcCC.", "CcCcCC", ".lbbb.", ".lbbd.", ".lbdd.", "..bd.."]
func _bolota(ce: Vector2, giro: int) -> void:
	var q: float = V.Q
	var cores: Dictionary = {"s": Color(0.3, 0.18, 0.08), "C": Color(0.36, 0.22, 0.11), "c": Color(0.54, 0.36, 0.18),
		"b": Color(0.84, 0.57, 0.26), "l": Color(0.98, 0.8, 0.5), "d": Color(0.6, 0.37, 0.15)}
	var ox: float = V.sn(ce.x)
	var oy: float = V.sn(ce.y)
	for passo in 2:
		for j in _BOLOTA.size():
			var lin: String = _BOLOTA[j]
			for i in lin.length():
				var ch: String = lin[i]
				if ch == ".":
					continue
				var cx: int = i - 3
				var cy: int = j - 3
				for r in giro:
					var t0: int = cx
					cx = -cy
					cy = t0
				var x: float = ox + cx * q
				var y: float = oy + cy * q
				if passo == 0:
					draw_rect(Rect2(x - q, y, q * 3.0, q), V.CONT)
					draw_rect(Rect2(x, y - q, q, q * 3.0), V.CONT)
				else:
					draw_rect(Rect2(x, y, q, q), cores[ch])

## Rasante do Esquilo Acrobata: a simulação só aplica o dano (o chefe não sai do lugar), então o salto é só de desenho —
## três cópias translúcidas do sprite em arco, indo por cima da faixa até `x_fim` e voltando (a de trás com atraso).
## `base` = pés do chefe quando o rasante saiu; `u` = 0..1 do efeito.
## Preparo (0..1) da pose: na janela antes do golpe (recarga quase no fim) o boneco arma o golpe (BichoPx.preparo).
func _pose_preparo(uu: Unidade) -> float:
	if uu.vivo and uu.golpe <= 0.0 and not uu.andando and uu.cd > 0.0 and uu.cd < BichoPx.PREPARO_T and (uu.alvo != null or uu.equipe == 1):
		return 1.0 - uu.cd / BichoPx.PREPARO_T
	return 0.0

## Dor da pose: os primeiros ~0,12 s do tranco de um golpe levado (BichoPx.dor).
func _pose_dor(uu: Unidade) -> bool:
	return tranco.has(uu) and Vector2(tranco[uu]).y > 0.04

func _rasante_saltos(ue: Unidade, base: Vector2, x_fim: float, u: float) -> void:
	var esc_g: float = esc_tela(ue)
	var tp_g: int = Unidade.Tipo.GEMEO if ue.pequeno else ue.tipo
	var alfas: Array = [0.6, 0.4, 0.24]
	for k in 3:
		var w: float = u * 1.2 - k * 0.1
		if w <= 0.0 or w >= 1.0:
			continue
		var ida: float = sin(w * PI)                       # 0 -> 1 (no fim da faixa) -> 0
		var x_g: float = lerpf(base.x, x_fim + 30.0, ida)
		var y_g: float = base.y - absf(sin(w * TAU)) * 70.0  # um arco na ida e outro na volta, por cima dos gatos
		var dir_g: float = -1.0 if w < 0.5 else 1.0
		Desenho.boneco(self, px_grade(Vector2(x_g, y_g)), esc_g, dir_g, 1, ue.pecas, 0.0, ue.anim, false, 0.12, alfas[k], false, -1, 0.0, tp_g, false, ue.chefe, ue.familia, ue.elite, ue.chefe_tipo, ue.parte, false, 0, false, ue.gangue, _pose_preparo(ue), _pose_dor(ue))

## Bola de fogo em pixel: lóbulos com contorno vinho, laranja, amarelo e miolo claro. `calor` 1 = recém-explodiu
## (miolo branco), 0 = brasa apagando.
func _bola_fogo(ce: Vector2, rr: float, calor: float) -> void:
	if rr < 4.0:
		return
	var lr: float = rr * 0.55
	var off: float = rr * 0.5
	var cont := Color(0.3, 0.06, 0.07)
	for k in 6:
		var a: float = k * 1.0472 + 0.4
		V.disco(self, ce + Vector2(cos(a) * off, sin(a) * off * 0.85), lr + V.Q, cont)
	V.disco(self, ce, rr * 0.75 + V.Q, cont)
	for k in 6:
		var a2: float = k * 1.0472 + 0.4
		V.disco(self, ce + Vector2(cos(a2) * off, sin(a2) * off * 0.85), lr, Color(0.88, 0.25, 0.08))
	V.disco(self, ce, rr * 0.75, Color(0.88, 0.25, 0.08))
	for k in 6:
		var a3: float = k * 1.0472 + 0.4
		V.disco(self, ce + Vector2(cos(a3) * off * 0.7, sin(a3) * off * 0.6), lr * 0.62, Color(1.0, 0.58, 0.14))
	V.disco(self, ce, rr * 0.55, Color(1.0, 0.58, 0.14))
	V.disco(self, ce + Vector2(0, -rr * 0.05), rr * 0.36, Color(1.0, 0.88, 0.38))
	if calor > 0.35:
		V.disco(self, ce, rr * 0.18, Color(1.0, 0.98, 0.82))

## Nuvem de fumaça em bolhas que sobem e encolhem (`u` 0..1 do tempo dela).
func _fumaca_px(base: Vector2, raio: float, n: int, u: float, cor: Color, sem: float) -> void:
	for k in n:
		var ang: float = k * 2.399 + sem * 6.0
		var rr: float = raio * (0.2 + 0.8 * fposmod(k * 0.382 + sem, 1.0))
		var sobe: float = u * (18.0 + 26.0 * fposmod(k * 0.618, 1.0))
		var tam: float = (7.0 + 5.0 * (k % 3)) * (1.0 - u * 0.75) * (0.4 + 0.6 * minf(1.0, u * 5.0))
		if tam < 3.0:
			continue
		V.bolha(self, base + Vector2(cos(ang) * rr, sin(ang) * rr * 0.4 - sobe), tam, cor)

## Clarão do raio: 2 quadros (de 1/30 s) com a tela inteira clara, o 1º forte e o 2º pela metade; depois nada.
func _clarao_raio(t: float, cor: Color) -> void:
	if t < 1.0 / 30.0:
		draw_rect(Rect2(-20, -20, 1320, 760), Color(cor.r, cor.g, cor.b, 0.55))
	elif t < 2.0 / 30.0:
		draw_rect(Rect2(-20, -20, 1320, 760), Color(cor.r, cor.g, cor.b, 0.25))

## Largura do raio: grosso no impacto (12 quadradinhos) e afinando em degraus até 4 enquanto ele dura (`fim` = u final).
func _larg_raio(u: float, fim: float) -> float:
	var k: float = clampf(u / fim, 0.0, 1.0)
	return V.sn(lerpf(V.Q * 12.0, V.Q * 4.0, sqrt(k))) + V.Q

## Marcas de queimado no chão: mancha escura achatada com brasas que apagam; encolhe em degraus até sumir.
func _desenhar_queimados() -> void:
	for qm in queimados:
		var uq: float = clampf(float(qm["t"]) / float(qm["dur"]), 0.0, 1.0)
		var degrau: float = ceilf((1.0 - uq) * 4.0) / 4.0     # 1, .75, .5, .25: some em 4 passos
		var rq: float = float(qm["r"]) * (0.55 + 0.45 * degrau)
		var pq: Vector2 = qm["p"]
		V.elipse(self, pq, rq, rq * 0.3, Color(0.06, 0.03, 0.05, 0.6 * degrau))
		V.elipse(self, pq, rq * 0.55, rq * 0.17, Color(0.02, 0.01, 0.02, 0.45 * degrau))
		if uq < 0.45:
			# brasas: alguns quadradinhos na cor do raio piscando dentro da mancha
			var cq: Color = qm["cor"]
			for k in 5:
				if int(rel * 12.0 + k * 3) % 4 == 0:
					continue
				var ax: float = (fposmod(k * 0.618 + pq.x * 0.01, 1.0) - 0.5) * rq * 1.3
				var ay: float = (fposmod(k * 0.382, 1.0) - 0.5) * rq * 0.35
				V.quadro(self, pq.x + ax, pq.y + ay, V.Q, V.Q, cq if uq < 0.25 else V.tom(cq, 0.6))

func _desenhar_fx(f: Dictionary) -> void:
	var t: float = f["t"]
	var u: float = clampf(t / float(f["dur"]), 0.0, 1.0)
	var a: float = 1.0 - u
	var c: Color = f["cor"]
	var p: Vector2 = f["p"]
	var ce: Vector2 = f["c"]
	var alvos: Array = f["alvos"]
	var sem: Array = f["sem"]
	var ex: Dictionary = f.get("ex", {})
	var gp: Vector2 = p + Vector2(0, 30.0 * ESC)   # chão sob quem usou
	var qtd: Array = alvos if not alvos.is_empty() else [p]
	var q: float = V.Q
	var esc_c: Color = V.tom(c, 0.42)   # tom escuro da cor da fantasia (contorno interno)
	var clr_c: Color = V.tom(c, 1.6)    # tom claro
	match int(f["poder"]):
		Pecas.Poder.RAIO:
			var quad: int = int(t * 18.0)
			_clarao_raio(t, Color(1, 1, 0.9))
			for k in qtd.size():
				var b: Vector2 = qtd[k]
				var pe: Vector2 = b + Vector2(0, 24 * ESC)
				var ue: float = 1.0 - pow(1.0 - u, 2.0)
				V.elipse(self, pe, 46.0 * minf(1.0, u * 8.0), 13.0 * minf(1.0, u * 8.0), Color(0.08, 0.05, 0.1, 0.4 * a))
				if u < 0.45:
					var topo := Vector2(b.x + (sem[k % 8] - 0.5) * 60.0, -10.0)
					V.raio(self, topo, b, Color(1.0, 0.9, 0.35), sem[k % 8] * 9.0 + quad * 1.7, _larg_raio(u, 0.45))
				V.aro(self, pe, 12.0 + 70.0 * ue, (12.0 + 70.0 * ue) * 0.35, Color(1.0, 0.92, 0.4), a * 1.2, 1.0)
				if u < 0.3:
					V.disco_c(self, b, 20.0 * (1.0 - u / 0.3) + 3.0, Color(1.0, 0.98, 0.8), Color(0.5, 0.3, 0.05))
				for j in 6:
					var ang: float = j * TAU / 6.0 + sem[k % 8] * 3.0
					var d: float = 16.0 + 52.0 * ue
					if a > 0.2:
						V.brilho(self, b + Vector2(cos(ang) * d, sin(ang) * d * 0.8), 6.0 * a, Color(1.0, 0.9, 0.3), Color(0.35, 0.2, 0.05))
		Pecas.Poder.EXPLOSAO:
			var rr: float = 30.0 + 150.0 * (1.0 - pow(1.0 - u, 3.0))
			if u < 0.15:
				draw_rect(Rect2(-20, -20, 1320, 760), Color(1.0, 0.9, 0.6, 0.22 * (1.0 - u / 0.15)))
			V.elipse(self, ce + Vector2(0, 26), rr * 1.1, rr * 0.34, Color(0.12, 0.05, 0.03, 0.4 * a))
			_bola_fogo(ce, rr * (1.0 - maxf(0.0, u - 0.55) / 0.45 * 0.6), 1.0 - u * 1.5)
			V.aro(self, ce + Vector2(0, 26), rr * 1.25, rr * 0.4, Color(1.0, 0.85, 0.4), a * 1.3, 1.5)
			V.aro(self, ce + Vector2(0, 26), rr * 0.95, rr * 0.3, Color(1.0, 0.5, 0.15), a * 1.1, 1.0)
			for k in 12:
				var ang_e: float = k * 0.5236 + sem[k % 8]
				var d: float = (40.0 + 150.0 * sem[(k + 3) % 8]) * (1.0 - pow(1.0 - u, 2.0))
				var pf: Vector2 = ce + Vector2(cos(ang_e) * d, sin(ang_e) * d * 0.7 + 180.0 * u * u - 30.0 * u)
				if a > 0.15:
					V.disco_c(self, pf, (3.0 + 3.0 * (k % 2)) * a + 2.0, Color(1.0, 0.7, 0.2) if k % 3 != 0 else Color(1.0, 0.95, 0.5), Color(0.35, 0.08, 0.05))
			if u > 0.35:
				_fumaca_px(ce + Vector2(0, 14), rr * 0.8, 7, (u - 0.35) / 0.65, Color(0.42, 0.36, 0.38), sem[0])
		Pecas.Poder.ATORDOA:
			var fade_s: float = minf(1.0, a * 3.0)
			for b in qtd:
				var cab: Vector2 = b + Vector2(0, -50 * ESC * 0.8)
				if u < 0.25:
					for k in 6:
						var ang_r: float = k * TAU / 6.0
						var dr: float = 10.0 + 104.0 * u
						V.linha(self, cab + Vector2(cos(ang_r), sin(ang_r) * 0.7) * dr, cab + Vector2(cos(ang_r), sin(ang_r) * 0.7) * (dr + 8.0), Color(1.0, 0.95, 0.5), q)
				if fade_s > 0.2:
					for k in 3:
						var ang: float = t * 7.0 + k * TAU / 3.0
						var sp: Vector2 = cab + Vector2(cos(ang) * 22.0, sin(ang) * 7.0)
						V.brilho(self, sp, 5.0, Color(1.0, 0.86, 0.2), Color(0.35, 0.2, 0.02))
			V.aro(self, p + Vector2(0, 30), 14.0 + 90.0 * u, (14.0 + 90.0 * u) * 0.4, clr_c, a * 1.2, 1.0)
		Pecas.Poder.CURA:
			var verde := Color(0.38, 0.95, 0.5)
			var vesc := Color(0.04, 0.3, 0.18)
			for bi in qtd.size():
				var b: Vector2 = qtd[bi]
				var pe: Vector2 = b + Vector2(0, 24 * ESC)
				V.elipse(self, pe, 36.0 * minf(1.0, u * 4.0), 11.0 * minf(1.0, u * 4.0), Color(0.3, 1.0, 0.5, 0.22 * a))
				V.aro(self, pe, 14.0 + 30.0 * u, (14.0 + 30.0 * u) * 0.34, verde, a * 1.3, 1.0)
				for k in 4:
					var w: float = fposmod(u * 1.1 + k * 0.25, 1.0)
					var cp: Vector2 = b + Vector2((k - 1.5) * 14.0 + sin(t * 4.0 + k) * 3.0, 10.0 - w * 76.0 - (k % 2) * 10.0)
					if sin(w * PI) * minf(1.0, a * 3.0) > 0.25:
						V.cruz(self, cp, 5.0 if k % 2 == 0 else 3.0, verde, vesc)
				for k in 4:
					var w2: float = fposmod(u * 1.3 + k * 0.25 + 0.12, 1.0)
					if a > 0.25:
						V.brilho(self, b + Vector2((k - 1.5) * 20.0, 20.0 - w2 * 70.0), 3.0, Color(0.85, 1.0, 0.9), vesc)
		Pecas.Poder.PROTEGE:
			var pop: float = minf(1.0, u * 6.0)
			var dourado := Color(1.0, 0.9, 0.45)
			for b in qtd:
				var bc: Vector2 = b + Vector2(0, 2)
				var rx: float = 30.0 * (0.55 + 0.45 * pop)
				var ry: float = 34.0 * (0.55 + 0.45 * pop)
				V.elipse(self, bc, rx, ry, Color(c.r, c.g, c.b, 0.12 * minf(1.0, a * 2.0)))
				V.aro(self, bc, rx + q, ry + q, V.CONT, minf(1.0, a * 2.5), 2.0)
				V.aro(self, bc, rx, ry, dourado, minf(1.0, a * 2.5), 1.0)
				if a > 0.3:
					V.brilho(self, bc + Vector2(-rx * 0.55, -ry * 0.6), 4.0, Color(1, 1, 0.95), Color(0.4, 0.3, 0.05))
		Pecas.Poder.FRENESI:
			var lista: Array = qtd.duplicate()
			lista.append(p)
			for bi in lista.size():
				var b: Vector2 = lista[bi]
				for k in 5:
					var w: float = fposmod(u * 2.2 + k * 0.21, 1.0)
					var yy: float = b.y + (k - 2.0) * 12.0
					var x1: float = b.x - 22.0 - w * 24.0
					var comp: float = 28.0 + sem[(k + bi) % 8] * 28.0
					if a > 0.2 and w < 0.85:
						V.quadro(self, x1 - comp - q, yy - q, comp + q * 2.0, q * 3.0, V.CONT)
						V.quadro(self, x1 - comp, yy, comp, q, Color(1.0, 0.68, 0.22))
						V.quadro(self, x1 - comp * 0.4, yy, comp * 0.4, q, Color(1.0, 0.97, 0.7))
				if a > 0.3:
					V.brilho(self, b + Vector2(8, -34 + sin(t * 10.0 + bi) * 4.0), 4.0, Color(1.0, 0.82, 0.25), Color(0.4, 0.2, 0.02))
		Pecas.Poder.ATRAVESSA:
			var alt: float = V.sn(3.0 + 14.0 * a)
			var x_ini: float = p.x
			var ancho: float = 1320.0 - x_ini
			if int(ex.get("eq", 0)) == 1:
				# rasante de bicho (Esquilo Acrobata): o feixe vai para a ESQUERDA, cruzando a faixa dos gatos até o mais
				# distante dela (com folga), e o esquilo salta em arco por cima dela (cópias translúcidas do sprite)
				var x_fim: float = p.x - 160.0
				for b in alvos:
					x_fim = minf(x_fim, b.x - 70.0)
				x_fim = maxf(0.0, x_fim)
				var cresce_r: float = minf(1.0, u / 0.35)   # o feixe acompanha o salto e depois apaga
				x_ini = p.x - (p.x - x_fim) * cresce_r
				ancho = p.x - x_ini
				var ue: Unidade = ex.get("u", null)
				if ue != null and is_instance_valid(ue):
					_rasante_saltos(ue, p + Vector2(0, 30.0 * ESC), x_fim, u)
			V.quadro(self, x_ini, p.y - alt - q, ancho, alt * 2.0 + q * 2.0, V.CONT)
			V.quadro(self, x_ini, p.y - alt, ancho, alt * 2.0, c)
			V.quadro(self, x_ini, p.y - alt * 0.55, ancho, alt * 1.1, clr_c)
			V.quadro(self, x_ini, p.y - maxf(q, alt * 0.22), ancho, maxf(q, alt * 0.44), V.BRANCO)
			var sent_a: float = -1.0 if int(ex.get("eq", 0)) == 1 else 1.0   # as faíscas correm no sentido do rasante
			for k in 8:
				var xk: float = x_ini + fposmod(k / 8.0 + u * 1.2 * sent_a, 1.0) * ancho
				V.quadro(self, xk, p.y - alt - q * 3.0 - (k % 3) * q, q, q * 2.0, clr_c)
			for b in alvos:
				V.estrela(self, b, 16.0 * a + 4.0, Color(1.0, 0.95, 0.6))
		Pecas.Poder.RAJADA:
			var destinos: Array = alvos if not alvos.is_empty() else [p + Vector2(300, 0)]
			for bi in destinos.size():
				var b: Vector2 = destinos[bi]
				for j in 3:
					var w: float = (t - j * 0.1 - bi * 0.03) / 0.3
					if w > 0.0 and w < 1.0:
						var off := Vector2(0, (j - 1) * 6.0 * (1.0 - w))
						for tr in 3:
							var wt: float = maxf(0.0, w - (tr + 1) * 0.06)
							V.disco_c(self, p.lerp(b, wt) + off, 3.0 - tr, V.tom(c, 1.0 - tr * 0.2), esc_c)
						V.disco_c(self, p.lerp(b, w) + off, 6.0, c, esc_c)
						V.disco(self, p.lerp(b, w) + off + Vector2(-q, -q), 3.0, V.BRANCO)
					elif w >= 1.0 and w < 1.4:
						V.brilho(self, b, 14.0 * (1.4 - w) / 0.4 + 3.0, clr_c, esc_c)
		Pecas.Poder.GELO:
			if u < 0.8:
				draw_rect(Rect2(-20, -20, 1320, 760), Color(0.3, 0.6, 1.0, 0.15 * (1.0 - u / 0.8)))
			var gelo := Color(0.5, 0.82, 1.0)
			var gesc := Color(0.1, 0.18, 0.45)
			for bi in qtd.size():
				var b: Vector2 = qtd[bi]
				var pe: Vector2 = b + Vector2(0, 24 * ESC)
				var cresce: float = minf(1.0, u * 5.0)
				var salto: float = 1.0 if a > 0.3 else a / 0.3
				V.elipse(self, pe + Vector2(0, 4), 66.0 * cresce, 18.0 * cresce, Color(0.3, 0.6, 0.95, 0.42 * minf(1.0, a * 2.5)))
				V.elipse(self, pe + Vector2(0, 3), 46.0 * cresce, 11.0 * cresce, Color(0.7, 0.92, 1.0, 0.5 * minf(1.0, a * 2.5)))
				for k in 7:
					var dx: float = (k - 3) * 12.0
					var h: float = (40.0 + (k % 3) * 20.0 - absf(k - 3) * 4.0) * cresce * salto
					if h >= q:
						V.cristal(self, pe + Vector2(dx, 5.0 - absf(k - 3) * 2.0), 9.0, h, gelo, gesc)
				for k in 5:
					var w: float = fposmod(t * 0.9 + k * 0.2 + sem[k] * 0.3, 1.0)
					if a > 0.2:
						V.brilho(self, b + Vector2((k - 2) * 15.0 + sin(t * 3.0 + k) * 5.0, -56.0 + w * 84.0), 3.0, V.BRANCO, gesc)
			V.aro(self, p + Vector2(0, 30), 10.0 + 120.0 * u, (10.0 + 120.0 * u) * 0.35, Color(0.7, 0.92, 1.0), a * 1.2, 1.0)
		Pecas.Poder.EMPURRA:
			for k in 3:
				var w: float = u - k * 0.1
				if w > 0.0:
					var rr: float = w * 200.0
					V.arco(self, p, rr + q, -0.9, 0.9, V.CONT, 1.0 - w, 2.0)
					V.arco(self, p, rr, -0.9, 0.9, c, 1.0 - w, 1.0)
			V.aro(self, p + Vector2(0, 40), 20.0 + 200.0 * u, (20.0 + 200.0 * u) * 0.25, Color(1, 1, 1), a * 0.9, 1.0)
			for b in alvos:
				V.seta(self, b + Vector2(u * 40.0, 0), 1.0, Color(1, 1, 0.95))
		Pecas.Poder.GIRO:
			var ang0: float = u * TAU * 2.0
			for k in 12:
				var ak: float = ang0 - k * 0.13
				var s: float = (11.0 - k * 0.7) * minf(1.0, a * 3.0)
				if s < q:
					continue
				var pk: Vector2 = p + Vector2(cos(ak), sin(ak)) * 78.0
				V.quadro(self, pk.x - s * 0.5 - q, pk.y - s * 0.5 - q, s + q * 2.0, s + q * 2.0, V.CONT)
			for k in 12:
				var ak2: float = ang0 - k * 0.13
				var s2: float = (11.0 - k * 0.7) * minf(1.0, a * 3.0)
				if s2 < q:
					continue
				var pk2: Vector2 = p + Vector2(cos(ak2), sin(ak2)) * 78.0
				V.quadro(self, pk2.x - s2 * 0.5, pk2.y - s2 * 0.5, s2, s2, V.BRANCO if k < 3 else (clr_c if k < 7 else c))
			V.brilho(self, p + Vector2(cos(ang0), sin(ang0)) * 78.0, 7.0, V.BRANCO, esc_c)
		Pecas.Poder.DRENO:
			var rosa := Color(0.98, 0.3, 0.5)
			var vin := Color(0.35, 0.04, 0.16)
			var fd: float = minf(1.0, a * 3.0)
			for bi in qtd.size():
				var b: Vector2 = qtd[bi]
				var nrm: Vector2 = (p - b).orthogonal().normalized()
				if fd > 0.15:
					for passo in 2:
						for i in 13:
							var w: float = i / 12.0
							var pt: Vector2 = b.lerp(p, w) + nrm * sin(w * 14.0 - t * 18.0) * 7.0 * sin(w * PI)
							var s: float = q * 2.0 + (q if passo == 0 else 0.0)
							V.quadro(self, pt.x - s * 0.5, pt.y - s * 0.5, s, s, vin if passo == 0 else rosa)
					for k in 3:
						var w2: float = fposmod(u * 1.8 + k * 0.33 + bi * 0.1, 1.0)
						V.gota(self, b.lerp(p, w2) + Vector2(0, sin(w2 * 6.0) * 4.0), Color(1.0, 0.45, 0.6), vin)
				V.disco_c(self, b, 14.0 * a + 3.0, Color(0.9, 0.22, 0.42), vin)
			V.cruz(self, p + Vector2(0, -34.0 - 20.0 * u), 5.0, Color(0.4, 1.0, 0.55), Color(0.04, 0.3, 0.18))
		Pecas.Poder.INVOCA:
			for b in qtd:
				var pe: Vector2 = b + Vector2(0, 22.0)
				V.aro(self, pe, 10.0 + 26.0 * u, (10.0 + 26.0 * u) * 0.4, c, a * 1.4, 1.0)
				V.aro(self, pe, (10.0 + 26.0 * u) * 0.6, (10.0 + 26.0 * u) * 0.24, clr_c, a * 1.4, 1.0)
				for k in 5:
					var ang: float = t * 4.0 + k * TAU / 5.0
					if a > 0.2:
						V.ponto(self, pe + Vector2(cos(ang) * 22.0 * (0.4 + u), sin(ang) * 9.0 * (0.4 + u)), V.BRANCO)
				_fumaca_px(b + Vector2(0, 14), 16.0, 4, u, Color(0.86, 0.86, 0.9), sem[1])
			V.aro(self, p + Vector2(0, 30), 8.0 + 40.0 * u, (8.0 + 40.0 * u) * 0.4, Color(1, 1, 1), a * 1.2, 1.0)
		Pecas.Poder.TELEPORTE:
			var ori: Vector2 = alvos[0] if not alvos.is_empty() else p
			var cian := Color(0.45, 0.85, 1.0)
			var cesc := Color(0.05, 0.15, 0.4)
			if a > 0.2:
				for passo in 2:
					var n_t: int = 14
					for i in n_t:
						var w: float = float(i) / (n_t - 1)
						if w > a * 1.4:
							continue
						var s: float = (q * 3.0 if passo == 0 else q) * (0.5 + 0.5 * w)
						var pt: Vector2 = ori.lerp(p, w)
						V.quadro(self, pt.x - s * 0.5, pt.y - s * 0.5 + sin(i * 2.0) * 3.0, s, s, cesc if passo == 0 else (cian if i % 2 == 0 else Color(0.9, 1, 1)))
			if a > 0.1:
				V.disco_c(self, ori, 20.0 * a + 3.0, cian, cesc)
			V.aro(self, p + Vector2(0, 28), 8.0 + 60.0 * u, (8.0 + 60.0 * u) * 0.4, cian, a * 1.3, 1.0)
			for k in 5:
				var ang: float = k * TAU / 5.0 + u * 6.0
				if a > 0.25:
					V.brilho(self, p + Vector2(cos(ang), sin(ang)) * (50.0 * a), 4.0, Color(0.85, 1.0, 1.0), cesc)
		Pecas.Poder.PUXA:
			for k in qtd.size():
				var b2: Vector2 = qtd[k]
				var alvo_p: Vector2 = p + Vector2(46.0 + (k % 3) * 14.0, 0.0)
				var cabeca: Vector2 = b2.lerp(alvo_p, minf(1.0, u * 2.0))
				if a > 0.15:
					V.linha(self, b2, cabeca, V.CONT, q * 3.0)
					V.linha(self, b2, cabeca, c, q * 2.0)
					V.linha(self, b2, cabeca, V.BRANCO, q)
					V.estrela(self, cabeca, 5.0, V.BRANCO, esc_c)
			V.aro(self, p + Vector2(0, 30), 140.0 * (1.0 - u) + 10.0, (140.0 * (1.0 - u) + 10.0) * 0.35, c, a * 1.2, 1.0)
		Pecas.Poder.ENXAME:
			var am := Color(1.0, 0.82, 0.12)
			V.aro(self, p + Vector2(0, 30), 10.0 + 70.0 * u, (10.0 + 70.0 * u) * 0.4, am, a * 1.3, 1.5)
			for k in 8:
				var ang: float = k * TAU / 8.0 + u * 5.0
				var d: float = 14.0 + 60.0 * u
				if a > 0.15:
					var pb: Vector2 = p + Vector2(cos(ang) * d, sin(ang) * d * 0.5 - 14.0)
					V.quadro(self, pb.x - q * 2.0, pb.y - q * 2.0, q * 4.0, q * 3.0, V.CONT)
					V.quadro(self, pb.x - q, pb.y - q, q * 2.0, q * 2.0, am)
					V.quadro(self, pb.x, pb.y - q, q, q * 2.0, V.CONT)
		Pecas.Poder.RAIZ:
			var branco := Color(0.96, 0.97, 1.0)
			var cinza := Color(0.28, 0.3, 0.42)
			for b in qtd:
				var pe: Vector2 = b + Vector2(0, 24 * ESC)
				var cr: float = minf(1.0, u * 5.0)
				var br: float = minf(1.0, a * 2.0)
				if cr < 1.0 or br > 0.3:
					var fio: Vector2 = p.lerp(b, minf(1.0, u * 6.0))
					V.linha(self, p, fio, cinza, q * 2.0)
					V.linha(self, p, fio, branco, q)
					V.elipse(self, pe, 34.0 * cr, 11.0 * cr, Color(0.85, 0.9, 1.0, 0.2 * br))
					for k in 8:
						var ang: float = k * TAU / 8.0
						V.linha(self, pe, pe + Vector2(cos(ang) * 34.0, sin(ang) * 11.0) * cr, branco, q)
					for rr in [12.0, 23.0, 34.0]:
						V.aro(self, pe, rr * cr, rr * 0.32 * cr, branco, br, 1.0)
		Pecas.Poder.SAQUE:
			if u < 0.25:
				V.estrela(self, p + Vector2(22, 0), 10.0 * (1.0 - u / 0.25) + 3.0, Color(1.0, 0.92, 0.5), Color(0.4, 0.25, 0.05))
			var queijo := Color(1.0, 0.8, 0.28)
			for bi in qtd.size():
				var b: Vector2 = qtd[bi]
				var w: float = (t - bi * 0.12) / 0.14
				if w > 0.0 and w < 1.0:
					for tr in 3:
						V.disco(self, p.lerp(b, maxf(0.0, w - (tr + 1) * 0.1)), 3.0 - tr * 0.8, Color(1.0, 0.95, 0.7))
					V.disco_c(self, p.lerp(b, w), 5.0, queijo, Color(0.45, 0.25, 0.05))
				elif w >= 1.0 and w < 2.0:
					var e2: float = w - 1.0
					V.brilho(self, b, 12.0 * (1.0 - e2) + 3.0, Color(1.0, 0.9, 0.45), Color(0.4, 0.25, 0.05))
					V.aro(self, b + Vector2(0, 24), 10.0 + 24.0 * e2, (10.0 + 24.0 * e2) * 0.4, Color(1.0, 0.9, 0.5), 1.0 - e2, 1.0)
		Pecas.Poder.TROVOADA:
			var quadro_t: int = int(t * 18.0)
			var roxo := Color(0.78, 0.65, 1.0)
			_clarao_raio(t, Color(0.86, 0.82, 1.0))
			for k in qtd.size():
				var b: Vector2 = qtd[k]
				var pe: Vector2 = b + Vector2(0, 24 * ESC)
				var rr_t: float = float(ex.get("raio", 70.0)) * minf(1.0, u * 6.0)
				V.elipse(self, pe, rr_t, rr_t * 0.34, Color(0.6, 0.45, 1.0, 0.25 * a))
				V.aro(self, pe, rr_t, rr_t * 0.34, roxo, minf(1.0, a * 2.0), 1.5)
				if u < 0.45:
					V.raio(self, Vector2(b.x + (sem[k % 8] - 0.5) * 50.0, -10.0), b, roxo, sem[k % 8] * 9.0 + quadro_t * 1.7, _larg_raio(u, 0.45))
				if u < 0.3:
					V.disco_c(self, b, 16.0 * (1.0 - u / 0.3) + 3.0, Color(0.95, 0.9, 1.0), Color(0.25, 0.15, 0.5))
				for j in 4:
					var ang: float = j * TAU / 4.0 + sem[k % 8] * 3.0 + u * 2.0
					if a > 0.25:
						V.brilho(self, pe + Vector2(cos(ang) * rr_t * 0.8, sin(ang) * rr_t * 0.3), 4.0, roxo, Color(0.2, 0.1, 0.4))
		Pecas.Poder.CANHAO:
			if u < 0.28:
				var wc: float = u / 0.28
				for k in 5:
					var wt: float = maxf(0.0, wc - (k + 1) * 0.07)
					V.bolha(self, p.lerp(ce, wt) + Vector2(0, -90.0 * sin(PI * wt)), 6.0 - k, Color(0.72, 0.72, 0.76))
				var bc: Vector2 = p.lerp(ce, wc) + Vector2(0, -90.0 * sin(PI * wc))
				V.disco_c(self, bc, 9.0, Color(0.2, 0.2, 0.26), V.CONT)
				V.disco(self, bc + Vector2(-3, -3), 3.0, Color(0.7, 0.72, 0.8))
			else:
				var we: float = (u - 0.28) / 0.72
				var rc: float = float(ex.get("raio", 100.0)) * (1.0 - pow(1.0 - minf(1.0, we * 2.5), 3.0))
				if we < 0.15:
					draw_rect(Rect2(-20, -20, 1320, 760), Color(1.0, 0.85, 0.5, 0.18 * (1.0 - we / 0.15)))
				V.elipse(self, ce + Vector2(0, 26), rc * 1.1, rc * 0.34, Color(0.12, 0.05, 0.03, 0.35 * (1.0 - we)))
				_bola_fogo(ce, rc * (1.0 - maxf(0.0, we - 0.5) * 0.9), 1.0 - we * 1.6)
				V.aro(self, ce + Vector2(0, 26), rc * 1.15, rc * 0.38, Color(1.0, 0.85, 0.4), (1.0 - we) * 1.3, 1.5)
				if we > 0.25:
					_fumaca_px(ce + Vector2(0, 10), rc * 0.7, 6, (we - 0.25) / 0.75, Color(0.42, 0.36, 0.38), sem[2])
		Pecas.Poder.MISSEIS:
			var raio_m: float = float(ex.get("raio", 80.0))
			for bi in qtd.size():
				var b: Vector2 = qtd[bi]
				var wm: float = (t - bi * 0.18) / 0.3
				if wm > 0.0 and wm < 1.0:
					var cab: Vector2 = Vector2(b.x, lerpf(-40.0, b.y, wm * wm))
					for k in 4:
						V.bolha(self, cab + Vector2(sin(k * 2.0 + t * 20.0) * 3.0, -22.0 - k * 12.0), 5.0 - k, Color(0.8, 0.78, 0.76))
					V.chama(self, cab + Vector2(0, -12), q * 3.0, 14.0, t)
					V.quadro(self, cab.x - q * 2.0, cab.y - 15.0, q * 4.0 + q, 16.0 + q, V.CONT)
					V.quadro(self, cab.x - q, cab.y - 12.0, q * 2.0, 12.0, Color(0.78, 0.8, 0.88))
					V.quadro(self, cab.x - q, cab.y - 3.0, q * 2.0, q, Color(0.85, 0.2, 0.15))
					V.quadro(self, cab.x - q, cab.y, q * 2.0, q, Color(0.85, 0.2, 0.15))
				elif wm >= 1.0:
					var em: float = (wm - 1.0) / 0.9
					if em < 1.0:
						var rm: float = raio_m * (1.0 - pow(1.0 - minf(1.0, em * 2.5), 2.0))
						V.elipse(self, b + Vector2(0, 24 * ESC), rm * 1.1, rm * 0.35, Color(0.12, 0.05, 0.03, 0.35 * (1.0 - em)))
						_bola_fogo(b, rm * (1.0 - maxf(0.0, em - 0.5) * 0.9), 1.0 - em * 1.6)
						V.aro(self, b + Vector2(0, 24 * ESC), rm * 1.1, rm * 0.35, Color(1.0, 0.85, 0.4), (1.0 - em) * 1.3, 1.0)
		Pecas.Poder.CANCAO:
			var fontes: Array = [p]
			fontes.append_array(alvos)
			var turq := Color(0.5, 1.0, 0.85)
			var tesc := Color(0.04, 0.25, 0.3)
			for fi in fontes.size():
				var f0: Vector2 = fontes[fi]
				for k in 3:
					var wn: float = fposmod(u * 1.3 + k * 0.33 + fi * 0.11, 1.0)
					var np: Vector2 = f0 + Vector2((k - 1) * 18.0 + sin(t * 6.0 + k + fi) * 6.0, -10.0 - wn * 70.0)
					if sin(wn * PI) * minf(1.0, a * 3.0) > 0.2:
						V.nota(self, np, turq if (k + fi) % 2 == 0 else Color(0.95, 1.0, 0.9), tesc)
				if fi > 0:
					V.aro(self, f0 + Vector2(0, 22), 8.0 + 24.0 * u, (8.0 + 24.0 * u) * 0.4, turq, a * 1.3, 1.0)
			V.aro(self, gp, 10.0 + 130.0 * u, (10.0 + 130.0 * u) * 0.34, turq, a * 1.3, 1.0)
			V.aro(self, gp, 6.0 + 80.0 * u, (6.0 + 80.0 * u) * 0.34, Color(0.9, 1.0, 0.95), a * 1.3, 1.0)
		Pecas.Poder.INVESTIDA:
			var o := Vector2(float(ex.get("x0", p.x)), float(ex.get("y0", p.y)) - 30.0 * ESC)
			if absf(p.x - o.x) > 2.0 and a > 0.1:
				var larg: float = V.sn(q + 12.0 * a)
				var xa: float = minf(o.x, p.x)
				var comp: float = absf(p.x - o.x)
				V.quadro(self, xa, p.y - larg - q, comp, larg * 2.0 + q * 2.0, V.CONT)
				V.quadro(self, xa, p.y - larg, comp, larg * 2.0, c)
				V.quadro(self, xa, p.y - larg * 0.4, comp, larg * 0.8, V.BRANCO)
				for k in 5:
					var xk: float = o.x + (p.x - o.x) * fposmod(k / 5.0 + u * 0.4, 1.0)
					V.seta(self, Vector2(xk, p.y), 1.0, V.BRANCO, esc_c)
			for b in alvos:
				V.estrela(self, b, 18.0 * a + 5.0, Color(1.0, 0.95, 0.5), Color(0.4, 0.2, 0.05))
			V.aro(self, gp, 14.0 + 60.0 * u, (14.0 + 60.0 * u) * 0.4, c, a * 1.3, 1.5)
		Pecas.Poder.FUMACA:
			var raio_f: float = float(ex.get("raio", 130.0))
			var cresce_f: float = minf(1.0, u * 4.0)
			var al_f: float = minf(1.0, a * 1.6)
			for k in 12:
				var ang_n: float = k * 2.399
				var rr_n: float = raio_f * (0.15 + 0.85 * fposmod(k * 0.382, 1.0)) * cresce_f
				var pc: Vector2 = gp + Vector2(cos(ang_n) * rr_n, sin(ang_n) * rr_n * 0.38 - 8.0 - 6.0 * sin(t * 2.0 + k))
				var tam: float = (16.0 + 7.0 * (k % 3)) * al_f
				if tam >= 5.0:
					V.bolha(self, pc, tam, Color(0.5, 0.44, 0.58))
			for b in alvos:
				if al_f > 0.4:
					V.bolha(self, b + Vector2(0, 8), 20.0 * cresce_f * al_f, Color(0.56, 0.5, 0.64))
			V.aro(self, gp, raio_f * cresce_f, raio_f * 0.38 * cresce_f, Color(0.72, 0.64, 0.88), al_f * 0.9, 1.0)
		Pecas.Poder.FURIA:
			var verm := Color(1.0, 0.28, 0.16)
			V.aro(self, gp, 16.0 + 90.0 * u, (16.0 + 90.0 * u) * 0.4, verm, a * 1.3, 2.0)
			for k in 5:
				var xf: float = p.x + (k - 2) * 14.0
				if a > 0.15:
					V.chama(self, Vector2(xf, gp.y - 4.0), 12.0, (30.0 + 26.0 * (k % 2)) * (0.6 + 0.4 * a), t + k)
			for k in 3:
				var wr: float = u - k * 0.12
				if wr > 0.0:
					V.arco(self, p, 20.0 + wr * 110.0, -0.8, 0.8, Color(1, 0.85, 0.65), 1.0 - wr, 1.5)
					V.arco(self, p, 20.0 + wr * 110.0, PI - 0.8, PI + 0.8, Color(1, 0.85, 0.65), 1.0 - wr, 1.5)
			V.estrela(self, p + Vector2(0, -34), 8.0 * a + 3.0, Color(1.0, 0.5, 0.2), Color(0.4, 0.05, 0.05))
		Pecas.Poder.PISAO:
			var o2 := Vector2(float(ex.get("x0", p.x)), float(ex.get("y0", p.y)) - 30.0 * ESC)
			var ant: Vector2 = o2
			for i in alvos.size():
				var dest: Vector2 = alvos[i]
				var wp: float = (t - i * 0.2) / 0.2
				if wp > 0.0:
					if wp < 1.0:
						var pos_p: Vector2 = ant.lerp(dest, wp) + Vector2(0, -80.0 * sin(PI * wp))
						V.elipse(self, ant.lerp(dest, wp) + Vector2(0, 34), 10.0, 3.0, Color(0, 0, 0, 0.28))
						V.disco_c(self, pos_p, 9.0, c, esc_c)
						V.disco(self, pos_p + Vector2(-3, -3), 3.0, V.BRANCO)
					else:
						var ep: float = (wp - 1.0) / 1.6
						if ep < 1.0:
							var pe: Vector2 = dest + Vector2(0, 24 * ESC)
							V.aro(self, pe, 10.0 + 60.0 * ep, (10.0 + 60.0 * ep) * 0.35, Color(1.0, 0.92, 0.55), 1.0 - ep, 1.5)
							if ep < 0.5:
								V.estrela(self, dest + Vector2(0, -34.0 - 24.0 * ep), 9.0, Color(1.0, 0.9, 0.3), Color(0.4, 0.22, 0.02))
							for k in 4:
								var sx: float = (k - 1.5) * 18.0 * (0.4 + ep)
								V.bolha(self, pe + Vector2(sx, -6.0 - ep * 16.0), 5.0 * (1.0 - ep), Color(0.78, 0.72, 0.62))
				ant = dest
		Pecas.Poder.CANTEIRO:
			var rc2: float = float(ex.get("raio", 110.0)) * u
			var rosa := Color(1.0, 0.55, 0.78)
			V.aro(self, gp, rc2, rc2 * 0.34, rosa, a * 1.4, 1.0)
			for k in 12:
				var ang_c: float = k * TAU / 12.0
				var wk: float = fposmod(u * 0.9 + k * 0.13, 1.0)
				if a > 0.2:
					var pet: Vector2 = gp + Vector2(cos(ang_c) * rc2, sin(ang_c) * rc2 * 0.34) + Vector2(0, -wk * 36.0)
					V.flor(self, pet, rosa if k % 2 == 0 else Color(1.0, 0.95, 0.5), Color(1.0, 0.85, 0.2) if k % 2 == 0 else Color(0.9, 0.4, 0.6), Color(0.3, 0.08, 0.2))
		Pecas.Poder.TRIAGEM:
			var verde := Color(0.38, 0.95, 0.5)
			var vesc := Color(0.04, 0.3, 0.18)
			for bi in qtd.size():
				var b: Vector2 = qtd[bi]
				if bi == 0:
					var wq: float = minf(1.0, u * 3.0)
					var fp: Vector2 = b + Vector2(0, -90.0 * (1.0 - wq) - 40.0)
					if a > 0.25:
						V.quadro(self, fp.x - q * 6.0, fp.y - q * 5.0, q * 12.0, q * 9.0, V.CONT)
						V.quadro(self, fp.x - q * 5.0, fp.y - q * 4.0, q * 10.0, q * 7.0, Color(0.98, 0.96, 0.9))
						V.quadro(self, fp.x - q * 5.0, fp.y - q * 4.0, q * 10.0, q, Color(0.8, 0.75, 0.68))
						V.quadro(self, fp.x - q, fp.y - q * 3.0, q * 2.0, q * 5.0, Color(0.85, 0.15, 0.12))
						V.quadro(self, fp.x - q * 2.0, fp.y - q, q * 5.0, q * 2.0, Color(0.85, 0.15, 0.12))
					V.elipse(self, b + Vector2(0, 24 * ESC), 32.0 * minf(1.0, u * 4.0), 10.0 * minf(1.0, u * 4.0), Color(0.3, 1.0, 0.5, 0.22 * a))
					V.aro(self, b + Vector2(0, 24 * ESC), 14.0 + 28.0 * u, (14.0 + 28.0 * u) * 0.34, verde, a * 1.3, 1.0)
					for k in 4:
						var wh: float = fposmod(u * 1.1 + k * 0.25, 1.0)
						if sin(wh * PI) * minf(1.0, a * 2.5) > 0.25:
							V.cruz(self, b + Vector2((k - 1.5) * 13.0, 10.0 - wh * 76.0), 5.0, verde, vesc)
				else:
					var wh2: float = fposmod(u * 1.1 + bi * 0.2, 1.0)
					if sin(wh2 * PI) * minf(1.0, a * 2.5) > 0.25:
						V.cruz(self, b + Vector2(0, 10.0 - wh2 * 60.0), 3.0, verde, vesc)
		Pecas.Poder.MARCA:
			var alt_m: float = V.sn(q + 5.0 * a)
			var verm := Color(1.0, 0.22, 0.22)
			V.quadro(self, p.x, p.y - alt_m - q, 1320.0 - p.x, alt_m * 2.0 + q * 2.0, V.CONT)
			V.quadro(self, p.x, p.y - alt_m, 1320.0 - p.x, alt_m * 2.0, verm)
			V.quadro(self, p.x, p.y - q * 0.5, 1320.0 - p.x, q, Color(1, 0.92, 0.9))
			for b in alvos:
				var r_m: float = 26.0 - 10.0 * minf(1.0, u * 4.0)
				var am2: float = minf(1.0, a * 1.5)
				V.aro(self, b, r_m + q, r_m + q, V.CONT, am2, 2.0)
				V.aro(self, b, r_m, r_m, verm, am2, 1.0)
				if am2 > 0.2:
					for k in 4:
						var dv := Vector2(cos(k * PI * 0.5), sin(k * PI * 0.5))
						V.quadro(self, b.x + dv.x * (r_m + q) - q * 0.5, b.y + dv.y * (r_m + q) - q * 0.5, q * (1.0 + absf(dv.x) * 2.0), q * (1.0 + absf(dv.y) * 2.0), Color(1.0, 0.4, 0.35))
					V.ponto(self, b, Color(1, 0.85, 0.85))
		Pecas.Poder.BOLA:
			var brc := Color(0.92, 0.96, 1.0)
			if a > 0.1:
				for k in 12:
					var ang_b: float = k * TAU / 12.0 + u * 3.0
					var r0: float = 14.0 + 56.0 * u
					var dvb := Vector2(cos(ang_b), sin(ang_b))
					V.linha(self, p + dvb * r0, p + dvb * (r0 + 14.0 * a + 4.0), V.CONT, q * 3.0)
				for k in 12:
					var ang_b2: float = k * TAU / 12.0 + u * 3.0
					var r1: float = 14.0 + 56.0 * u
					var dvb2 := Vector2(cos(ang_b2), sin(ang_b2))
					V.linha(self, p + dvb2 * r1, p + dvb2 * (r1 + 14.0 * a + 4.0), c, q * 2.0)
					V.linha(self, p + dvb2 * (r1 + 4.0), p + dvb2 * (r1 + 14.0 * a + 4.0), brc, q)
			V.aro(self, gp, 20.0 + 70.0 * u, (20.0 + 70.0 * u) * 0.4, c, a * 1.3, 1.0)
		Pecas.Poder.SALVAMENTO:
			# o herói voa do ponto de origem até o ferido, o traz ao posto e soca o chão onde ele estava
			var azul := Color(0.3, 0.5, 1.0)
			var verm_s := Color(1.0, 0.3, 0.3)
			var a0: Vector2 = alvos[0] if not alvos.is_empty() else p
			var o0 := Vector2(float(ex.get("x0", p.x)), float(ex.get("y0", p.y)) - 24.0 * ESC)
			if u < 0.35:
				var w_s: float = u / 0.35
				for k in 7:
					var pos_s: Vector2 = o0.lerp(a0, clampf(w_s - k * 0.07, 0.0, 1.0))
					V.disco_c(self, pos_s, 7.0 - k * 0.8, azul if k % 2 == 0 else verm_s, V.CONT)
			if u > 0.25:
				var w2: float = clampf((u - 0.25) / 0.75, 0.0, 1.0)
				var pe_s: Vector2 = a0 + Vector2(0, 24 * ESC)
				var rr_s: float = float(ex.get("raio", 90.0)) * (1.0 - pow(1.0 - w2, 3.0))
				V.elipse(self, pe_s, rr_s, rr_s * 0.34, Color(0.3, 0.5, 1.0, 0.22 * (1.0 - w2)))
				V.aro(self, pe_s, rr_s, rr_s * 0.34, azul, 1.0 - w2, 1.5)
				V.aro(self, pe_s, rr_s * 0.6, rr_s * 0.2, Color(1, 1, 1), 1.0 - w2, 1.0)
				for k in 6:
					var ang_s: float = k * TAU / 6.0 + 0.4
					if w2 < 0.7:
						V.estrela(self, pe_s + Vector2(cos(ang_s) * rr_s * 0.8, sin(ang_s) * rr_s * 0.3 - 10.0 * w2), 5.0, Color(1.0, 0.9, 0.3), Color(0.4, 0.25, 0.05))
			var verde_s := Color(0.35, 0.9, 0.4)
			for k in 3:
				var wh_s: float = fposmod(u * 1.2 + k * 0.3, 1.0)
				if u > 0.3 and sin(wh_s * PI) * minf(1.0, a * 2.5) > 0.25:
					V.cruz(self, p + Vector2((k - 1) * 16.0, -10.0 - wh_s * 56.0), 5.0, verde_s, Color(0.1, 0.4, 0.2))
		Pecas.Poder.RICOCHETE:
			# a flecha segue a linha quebrada de alvo em alvo
			var verde_r := Color(0.45, 0.95, 0.35)
			var pts_r: Array = [p + Vector2(22, 0)]
			for b in alvos:
				pts_r.append(b)
			var wr: float = t / 0.12
			for k in range(1, pts_r.size()):
				var seg: float = wr - (k - 1)
				if seg <= 0.0:
					break
				var fim_r: Vector2 = (pts_r[k - 1] as Vector2).lerp(pts_r[k], minf(1.0, seg))
				V.linha(self, pts_r[k - 1], fim_r, V.CONT, q * 2.0)
				V.linha(self, pts_r[k - 1], fim_r, verde_r, q)
				if seg >= 1.0 and seg < 2.0:
					V.brilho(self, pts_r[k], 11.0 * (2.0 - seg) + 3.0, Color(1.0, 0.95, 0.5), Color(0.2, 0.4, 0.1))
			if not alvos.is_empty():
				var ult: Vector2 = alvos[alvos.size() - 1]
				V.aro(self, ult + Vector2(0, 24 * ESC), 10.0 + 26.0 * u, (10.0 + 26.0 * u) * 0.4, verde_r, a, 1.0)
		Pecas.Poder.OLHAR:
			# olhar em brasa: raios laranja do gato aos alvos e chamas em cima de cada um
			var laranja := Color(1.0, 0.5, 0.1)
			for k in qtd.size():
				var b: Vector2 = qtd[k]
				if u < 0.3:
					var wo: float = u / 0.3
					V.linha(self, p + Vector2(18, -8), p.lerp(b, wo) + Vector2(0, -8 * (1.0 - wo)), V.CONT, q * 3.0)
					V.linha(self, p + Vector2(18, -8), p.lerp(b, wo) + Vector2(0, -8 * (1.0 - wo)), laranja, q * 2.0)
				if u > 0.15:
					var ch: float = clampf((u - 0.15) / 0.85, 0.0, 1.0)
					V.chama(self, b + Vector2(0, 26 * ESC), 38.0 * minf(1.0, ch * 5.0), 70.0 * (1.0 - 0.4 * ch), t * 1.5 + k)
					V.aro(self, b + Vector2(0, 24 * ESC), 14.0 + 40.0 * ch, (14.0 + 40.0 * ch) * 0.35, laranja, 1.0 - ch, 1.0)
		Pecas.Poder.OBJECAO:
			# balão "!" sobre o bicho cortado e uma onda de choque
			var rosa := Color(1.0, 0.35, 0.4)
			for b in qtd:
				var bal: Vector2 = b + Vector2(0, -52.0 - 10.0 * minf(1.0, u * 6.0))
				var esc_b: float = minf(1.0, u * 8.0) * (1.0 if u < 0.7 else (1.0 - (u - 0.7) / 0.3))
				if esc_b > 0.05:
					V.quadro(self, bal.x - 18.0 * esc_b - q, bal.y - 24.0 * esc_b - q, 36.0 * esc_b + q * 2.0, 48.0 * esc_b + q * 2.0, V.CONT)
					V.quadro(self, bal.x - 18.0 * esc_b, bal.y - 24.0 * esc_b, 36.0 * esc_b, 48.0 * esc_b, Color(1, 1, 1))
					V.quadro(self, bal.x - q, bal.y - 15.0 * esc_b, q * 2.0, 20.0 * esc_b, rosa)
					V.quadro(self, bal.x - q, bal.y + 10.0 * esc_b, q * 2.0, q * 2.0, rosa)
				V.aro(self, b + Vector2(0, 24 * ESC), 10.0 + 60.0 * u, (10.0 + 60.0 * u) * 0.4, rosa, a * 1.2, 1.5)
			V.aro(self, gp, 14.0 + 50.0 * u, (14.0 + 50.0 * u) * 0.4, c, a, 1.0)
		Pecas.Poder.IMITAR:
			# pano amarelo: bolhas de fumaça sobem e um aro marca o gato
			_fumaca_px(gp, 34.0, 8, u, Color(c.r, c.g, c.b, 0.8 * a), sem[0])
			V.aro(self, gp, 16.0 + 40.0 * u, (16.0 + 40.0 * u) * 0.4, c, a * 1.3, 1.0)
			for k in 4:
				var ang_i: float = k * TAU / 4.0 + u * 4.0
				if a > 0.2:
					V.estrela(self, p + Vector2(cos(ang_i) * 28.0, sin(ang_i) * 16.0 - 6.0), 4.0, clr_c, esc_c)
		Pecas.Poder.POQUER:
			# cartas caem sobre o bando e estouram
			var pk: Vector2 = (qtd[0] as Vector2)
			var raio_q: float = float(ex.get("raio", 110.0))
			for k in 5:
				var wq: float = clampf(u * 2.2 - k * 0.1, 0.0, 1.0)
				if wq > 0.0 and wq < 1.0:
					var cx_q: float = pk.x + (k - 2) * 22.0
					var cy_q: float = lerpf(-30.0, pk.y, wq)
					V.quadro(self, cx_q - 9.0 - q, cy_q - 13.0 - q, 18.0 + q * 2.0, 26.0 + q * 2.0, V.CONT)
					V.quadro(self, cx_q - 9.0, cy_q - 13.0, 18.0, 26.0, Color(1, 1, 1))
					V.quadro(self, cx_q - q, cy_q - q * 1.5, q * 2.0, q * 3.0, Color(0.9, 0.2, 0.3) if k % 2 == 0 else V.CONT)
			if u > 0.45:
				var wp: float = clampf((u - 0.45) / 0.55, 0.0, 1.0)
				var pe_q: Vector2 = pk + Vector2(0, 24 * ESC)
				V.aro(self, pe_q, raio_q * (1.0 - pow(1.0 - wp, 3.0)), raio_q * (1.0 - pow(1.0 - wp, 3.0)) * 0.34, c, 1.0 - wp, 1.5)
				for k in 8:
					var ang_q: float = k * TAU / 8.0 + 0.3
					if wp < 0.7:
						V.cruz(self, pe_q + Vector2(cos(ang_q) * raio_q * wp, sin(ang_q) * raio_q * wp * 0.4 - 12.0), 4.0, Color(1.0, 0.9, 0.3) if k % 2 == 0 else Color(0.95, 0.3, 0.4), V.CONT)
		Pecas.Poder.TORRE:
			# a semente estoura no chão onde a torre nasce: anel verde, folhas e ervilhas voando
			var verde_t := Color(0.45, 0.9, 0.35)
			var bt: Vector2 = qtd[0] + Vector2(0, 24 * ESC)
			V.aro(self, bt, 10.0 + 60.0 * u, (10.0 + 60.0 * u) * 0.36, verde_t, a * 1.3, 1.5)
			for k in 6:
				var ang_t: float = k * TAU / 6.0 + sem[k % 8]
				if a > 0.15:
					V.folha(self, bt + Vector2(cos(ang_t) * (10.0 + 44.0 * u), -6.0 - 30.0 * u + sin(ang_t) * 10.0), 1.0 if k % 2 == 0 else -1.0, verde_t)
			for k in 3:
				V.disco_c(self, bt + Vector2((k - 1) * 14.0, -14.0 - 70.0 * u * (0.6 + 0.2 * k)), 3.0 * a + 1.0, Color(0.5, 0.95, 0.35), V.CONT)
		Pecas.Poder.MANTEIGA:
			# a poça se espalha: anel dourado e gotas que escorrem
			var ouro := Color(1.0, 0.88, 0.3)
			var bm: Vector2 = qtd[0] + Vector2(0, 24 * ESC)
			var rm: float = float(ex.get("raio", 110.0)) * (1.0 - pow(1.0 - u, 3.0))
			V.aro(self, bm, rm, rm * 0.36, ouro, a * 1.3, 1.5)
			for k in 6:
				var ang_m: float = k * TAU / 6.0 + 0.5
				if a > 0.2:
					V.gota(self, bm + Vector2(cos(ang_m) * rm * 0.8, sin(ang_m) * rm * 0.3 - 16.0 * (1.0 - u)), ouro)
		Pecas.Poder.REVIVER:
			# coluna de luz dourada sobre o gato que levanta, com cruzes de cura subindo
			var luz := Color(1.0, 0.92, 0.45)
			var br: Vector2 = qtd[0]
			var larg_r: float = 26.0 * (1.0 - u * 0.5)
			V.quadro(self, br.x - larg_r * 0.5, br.y - 190.0, larg_r, 190.0 + 24.0 * ESC, Color(1.0, 0.95, 0.6, 0.35 * a))
			V.quadro(self, br.x - larg_r * 0.25, br.y - 190.0, larg_r * 0.5, 190.0 + 24.0 * ESC, Color(1.0, 1.0, 0.9, 0.5 * a))
			V.aro(self, br + Vector2(0, 24 * ESC), 12.0 + 60.0 * u, (12.0 + 60.0 * u) * 0.36, luz, a * 1.3, 1.5)
			for k in 4:
				var wr2: float = fposmod(u * 1.4 + k * 0.25, 1.0)
				V.cruz(self, br + Vector2((k - 1.5) * 16.0, 10.0 - wr2 * 70.0), 5.0, Color(0.4, 0.95, 0.5), Color(0.05, 0.3, 0.2))
			if p.distance_to(br) > 30.0:
				V.linha(self, p, br, Color(1.0, 0.92, 0.45, 0.5 * a), q)
		Pecas.Poder.COLHEITA:
			# terra revirada e brotinhos onde cada muda é plantada
			for b in qtd:
				var bc: Vector2 = b + Vector2(0, 24 * ESC)
				V.aro(self, bc, 8.0 + 26.0 * u, (8.0 + 26.0 * u) * 0.36, Color(0.7, 0.5, 0.3), a * 1.2, 1.0)
				for k in 4:
					var ang_c: float = k * TAU / 4.0 + 0.7
					if a > 0.2:
						V.quadro(self, bc.x + cos(ang_c) * 16.0 * u - q, bc.y - 6.0 - 22.0 * u * absf(sin(ang_c)), q * 2.0, q * 2.0, Color(0.5, 0.33, 0.18))
				V.cruz(self, bc + Vector2(0, -10.0 - 20.0 * u), 4.0, Color(0.5, 0.95, 0.35), Color(0.1, 0.3, 0.1))
		Pecas.Poder.CONSTRUIR:
			# poeira de pedra e lascas onde cada bloco sobe
			for b in qtd:
				var bq: Vector2 = b + Vector2(0, 24 * ESC)
				V.aro(self, bq, 8.0 + 34.0 * u, (8.0 + 34.0 * u) * 0.36, Color(0.75, 0.76, 0.82), a * 1.2, 1.5)
				for k in 5:
					var ang_b: float = k * TAU / 5.0 + sem[k % 8]
					if a > 0.2:
						V.quadro(self, bq.x + cos(ang_b) * (8.0 + 30.0 * u) - q, bq.y - 4.0 - 24.0 * u * absf(sin(ang_b)) - q, q * 2.0, q * 2.0, Color(0.62, 0.63, 0.68))
		Pecas.Poder.COCHILO:
			# ondas de sono saem do gato e os "z" sobem; azul calmo
			var azul_s := Color(0.55, 0.7, 1.0)
			var rs: float = float(ex.get("raio", 120.0))
			V.aro(self, gp, rs * (1.0 - pow(1.0 - u, 2.0)), rs * (1.0 - pow(1.0 - u, 2.0)) * 0.36, azul_s, a * 1.4, 2.0)
			V.aro(self, gp, rs * 0.6 * (1.0 - pow(1.0 - u, 2.0)), rs * 0.6 * (1.0 - pow(1.0 - u, 2.0)) * 0.36, Color(0.8, 0.88, 1.0), a, 1.0)
			for b in qtd:
				# um "z" por gato, cada um na sua fase (a posição desencontra as subidas)
				var wz: float = fposmod(u * 1.2 + fposmod(b.x * 0.013, 1.0), 1.0)
				V.zzz(self, b + Vector2(8.0 + wz * 10.0, -30.0 - wz * 36.0), 2.0 if wz > 0.4 else 1.0, Color(0.85, 0.92, 1.0))
		Pecas.Poder.PLANO:
			# mira azul fecha sobre o alvo e riscos saem do líder
			for b in qtd:
				var rm: float = 46.0 - 28.0 * minf(1.0, u * 3.0)
				V.aro(self, b + Vector2(0, 20 * ESC), rm, rm * 0.5, Color(1.0, 0.3, 0.3), a * 1.4, 1.5)
				V.cruz(self, b + Vector2(0, -6.0), 8.0 + 6.0 * a, Color(1.0, 0.95, 0.9), esc_c)
				if p.distance_to(b) > 30.0 and a > 0.2:
					V.linha(self, p, b, Color(c.r, c.g, c.b, 0.7 * a), q)
			V.aro(self, gp, 14.0 + 50.0 * u, (14.0 + 50.0 * u) * 0.4, c, a * 1.2, 1.0)
		Pecas.Poder.DOMO:
			# o domo sobe do chão; a cúpula persistente sai de _desenhar_domos
			V.aro(self, gp, 10.0 + float(ex.get("raio", 130.0)) * minf(1.0, u * 2.0), (10.0 + float(ex.get("raio", 130.0)) * minf(1.0, u * 2.0)) * 0.34, c, a * 1.4, 1.5)
			for k in 6:
				V.cruz(self, gp + Vector2((k - 2.5) * 20.0, -10.0 - 50.0 * u * (0.5 + 0.1 * k)), 4.0, V.BRANCO, esc_c)
		Pecas.Poder.LOBO:
			# anel vermelho abre até o raio de provocação e as sais cruzam
			var rl: float = float(ex.get("raio", 150.0)) * (1.0 - pow(1.0 - u, 3.0))
			V.aro(self, gp, rl, rl * 0.36, c, a * 1.5, 2.0)
			for k in 8:
				var ang_l: float = k * TAU / 8.0 + 0.2
				if a > 0.2:
					V.seta(self, gp + Vector2(cos(ang_l) * rl * 0.9, sin(ang_l) * rl * 0.32 - 10.0), -cos(ang_l), V.BRANCO, esc_c)
			V.estrela(self, p + Vector2(0, -10.0), 16.0 * a + 4.0, Color(1.0, 0.85, 0.7), esc_c)
		Pecas.Poder.TURBO:
			# risco azul da largada até o destino, com labaredas de pixel e faíscas
			var o_t := Vector2(float(ex.get("x0", p.x)), float(ex.get("y0", p.y)) - 30.0 * ESC)
			var d_t := Vector2(float(ex.get("x1", p.x)), o_t.y)
			if absf(d_t.x - o_t.x) > 2.0 and a > 0.1:
				var larg_t: float = V.sn(q + 12.0 * a)
				var xa_t: float = minf(o_t.x, d_t.x)
				var comp_t: float = absf(d_t.x - o_t.x)
				V.quadro(self, xa_t, o_t.y - larg_t - q, comp_t, larg_t * 2.0 + q * 2.0, V.CONT)
				V.quadro(self, xa_t, o_t.y - larg_t, comp_t, larg_t * 2.0, Color(0.15, 0.55, 1.0))
				V.quadro(self, xa_t, o_t.y - larg_t * 0.4, comp_t, larg_t * 0.8, Color(0.85, 1.0, 1.0))
				for k in 6:
					var xk_t: float = o_t.x + (d_t.x - o_t.x) * fposmod(k / 6.0 + u * 0.5, 1.0)
					V.chama_azul(self, Vector2(xk_t, o_t.y + 26.0 * ESC), 14.0, 22.0 * a, t + k)
			for b in alvos:
				V.estrela(self, b, 16.0 * a + 5.0, Color(0.7, 0.95, 1.0), Color(0.05, 0.15, 0.4))
		Pecas.Poder.ESFORCO:
			# aura vermelha sobe do gato, estrelinhas brancas e raios de energia
			for k in 10:
				var wk: float = fposmod(u * 1.5 + k * 0.1, 1.0)
				var xk_e: float = p.x + (k - 4.5) * 8.0
				V.quadro(self, xk_e - q, gp.y - wk * 80.0 - q, q * 3.0, q * 5.0, V.CONT)
				V.quadro(self, xk_e, gp.y - wk * 80.0, q, q * 3.0, Color(1.0, 0.25, 0.25) if k % 2 == 0 else Color(1.0, 0.85, 0.8))
			V.aro(self, gp, 12.0 + 50.0 * u, (12.0 + 50.0 * u) * 0.36, c, a * 1.4, 1.5)
			V.estrela(self, p + Vector2(0, -30.0), 10.0 * a + 4.0, V.BRANCO, esc_c)
		Pecas.Poder.CHUTE:
			# chute em arco: a perna varre meia-lua em volta do gato e a onda abre até o raio
			var rc: float = float(ex.get("raio", 95.0)) * (1.0 - pow(1.0 - u, 2.0))
			V.aro(self, gp, rc, rc * 0.36, c, a * 1.4, 2.0)
			V.aro(self, gp, rc * 0.7, rc * 0.7 * 0.36, V.BRANCO, a, 1.0)
			V.chute_arco(self, p + Vector2(0, -10.0), 46.0, u, esc_c)
			for b in alvos:
				V.estrela(self, b + Vector2(0, -20.0), 12.0 * a + 4.0, Color(1.0, 0.95, 0.7), esc_c)
		Pecas.Poder.APAGAO:
			# Modo Noir: flash branco em quadradinhos que some, grão de filme em volta do gato e aro branco
			var fl_n: float = clampf(1.0 - u / 0.4, 0.0, 1.0)
			if fl_n > 0.0:
				V.grao_filme(self, p + Vector2(0, -30.0), 46.0, 44.0, rel, fl_n, 60, V.Q * 1.5)
				V.estrela(self, p + Vector2(0, -30.0), 10.0 + 22.0 * fl_n, V.BRANCO, Color(0.1, 0.1, 0.12))
			var ra_a: float = 70.0 * (1.0 - pow(1.0 - u, 3.0))
			V.aro(self, p + Vector2(0, 20.0), ra_a, ra_a * 0.36, V.BRANCO, a * 1.2, 2.0)
			V.grao_filme(self, p + Vector2(0, -30.0), 40.0, 40.0, rel, a, 24)
		Pecas.Poder.ESPIRITO:
			# a Sombra do Knight viaja pela fileira com rastro escuro e olhos brancos; a menor (herança) é mais fina
			var o_e := Vector2(float(ex.get("x0", p.x)), float(ex.get("y0", p.y)) - 26.0 * ESC)
			var x1_e: float = float(ex.get("x1", p.x + 400.0))
			var sd_e: float = 1.0 if x1_e >= o_e.x else -1.0
			var cab: float = lerpf(o_e.x, x1_e, minf(1.0, u * 2.5))
			var menor_e: bool = float(ex.get("menor", 0.0)) > 0.5
			var cel_e: float = V.sn((3.0 if menor_e else 4.0) + (0.0 if menor_e else 2.0) * float(ex.get("raio", 0.5)))
			var viva_e: float = 1.0 - maxf(0.0, (u - 0.7) / 0.3)
			if absf(cab - o_e.x) > 2.0:
				var xa_e: float = minf(o_e.x, cab)
				var lg_e: float = cel_e * 2.0
				V.quadro(self, xa_e, o_e.y - lg_e - q, absf(cab - o_e.x), lg_e * 2.0 + q * 2.0, Color(0.42, 0.3, 0.62, 0.35 * viva_e))
				V.quadro(self, xa_e, o_e.y - lg_e, absf(cab - o_e.x), lg_e * 2.0, Color(0.03, 0.02, 0.08, 0.55 * viva_e))
			V.sombra(self, Vector2(cab, o_e.y), sd_e, cel_e, t, viva_e, q)
		Pecas.Poder.LACO:
			# fios vermelhos partem do gato e atam os bichos ligados (os fios que ficam saem de _desenhar_lacos)
			for b in alvos:
				var pb: Vector2 = p.lerp(b, minf(1.0, u * 3.0)) + Vector2(0, -20.0)
				V.fio(self, p + Vector2(0, -20.0), pb, Color(0.9, 0.2, 0.3), t)
				V.estrela(self, pb, 6.0 * a + 2.0, Color(1.0, 0.6, 0.65), esc_c)
		Pecas.Poder.KAMEHA:
			# carga: esfera azul cresce entre as mãos e faíscas douradas sobem (a aura persistente sai de _estados)
			var rb: float = 6.0 + 16.0 * minf(1.0, u)
			V.disco_c(self, p + Vector2(14.0, -22.0), rb, Color(0.35, 0.7, 1.0), Color(0.05, 0.15, 0.45))
			V.disco(self, p + Vector2(13.0, -23.0), rb * 0.5, V.BRANCO)
			V.aro(self, gp, 12.0 + 40.0 * minf(1.0, u), (12.0 + 40.0 * minf(1.0, u)) * 0.36, Color(1.0, 0.85, 0.2), a * 1.4, 1.5)
		-3:
			# feixe azul que cruza o campo
			var o_k := Vector2(float(ex.get("x0", p.x)), float(ex.get("y0", p.y)) - 26.0 * ESC)
			var x1_k: float = float(ex.get("x1", 1300.0))
			var cresce: float = minf(1.0, u * 10.0) * (1.0 - maxf(0.0, (u - 0.7) / 0.3))
			var lg_k: float = V.sn((16.0 + 8.0 * sin(t * 30.0)) * cresce)
			if lg_k >= q:
				var cmp_k: float = absf(x1_k - o_k.x)
				V.quadro(self, o_k.x, o_k.y - lg_k - q, cmp_k, lg_k * 2.0 + q * 2.0, Color(0.05, 0.15, 0.45))
				V.quadro(self, o_k.x, o_k.y - lg_k, cmp_k, lg_k * 2.0, Color(0.3, 0.65, 1.0))
				V.quadro(self, o_k.x, o_k.y - lg_k * 0.45, cmp_k, lg_k * 0.9, V.BRANCO)
			V.estrela(self, o_k, 16.0 * cresce + 4.0, Color(0.8, 0.95, 1.0), Color(0.05, 0.15, 0.45))
		Pecas.Poder.PEDRA:
			# poeira no lugar onde a pedra nasce (a pedra que rola sai de _desenhar_pedras)
			var o_p := Vector2(float(ex.get("x0", p.x)), float(ex.get("y0", p.y)))
			for k in 6:
				V.cruz(self, o_p + Vector2(-k * 8.0 * u, -10.0 - k * 6.0 * u), 3.0, Color(0.75, 0.68, 0.55), esc_c)
		Pecas.Poder.CAPTURA:
			# a Miaubola voa até o bicho, balança e estala
			var d_c: Vector2 = (alvos[0] as Vector2) if not alvos.is_empty() else p + Vector2(100, 0)
			var voo: float = minf(1.0, u * 2.5)
			var pc: Vector2 = (p + Vector2(0, -30.0)).lerp(d_c + Vector2(0, -24.0), voo) + Vector2(0, -sin(voo * PI) * 30.0)
			V.disco_c(self, pc, 6.0, Color(0.95, 0.2, 0.2), Color(0.3, 0.05, 0.05))
			V.quadro(self, pc.x - 6.0, pc.y, 12.0, 6.0, Color(1, 1, 1))
			V.ponto(self, pc, V.CONT)
			if voo >= 1.0:
				V.estrela(self, d_c + Vector2(0, -24.0), 14.0 * a + 4.0, Color(1.0, 0.95, 0.8), esc_c)
		Pecas.Poder.MEGAZORD:
			# anéis verdes sobem do Ranger e os ligados recebem uma estrela
			var ra_m: float = 24.0 + 90.0 * u
			V.aro(self, gp, ra_m, ra_m * 0.4, Color(0.4, 1.0, 0.5), a * 1.4, 2.0)
			V.aro(self, gp + Vector2(0, -20.0), ra_m * 0.6, ra_m * 0.24, Color(0.9, 1.0, 0.7), a * 1.2, 1.5)
			for b in alvos:
				V.estrela(self, (b as Vector2) + Vector2(0, -34.0), 8.0 * a + 3.0, Color(0.7, 1.0, 0.8), esc_c)
		Pecas.Poder.SOPRO:
			# jato verde em cone: bolinhas que se abrem a partir da boca
			var an_s: float = float(ex.get("ang", 0.0))
			var al_s: float = float(ex.get("alc", 260.0))
			var ab_s: float = deg_to_rad(float(ex.get("abre", 60.0))) * 0.5
			var o_s: Vector2 = p + Vector2(0, -24.0 * ESC)
			for k in 18:
				var fr_s: float = fposmod(float(sem[k % 8]) * 0.5 + k * 0.137 + u * 0.8, 1.0)
				var aa_s: float = an_s + (fposmod(k * 0.618, 1.0) - 0.5) * 2.0 * ab_s * fr_s
				var rr_s: float = al_s * fr_s * minf(1.0, u * 4.0)
				V.disco(self, o_s + Vector2(cos(aa_s), sin(aa_s)) * rr_s, 3.0 + 9.0 * fr_s, Color(0.45, 0.95, 0.55, 0.85 * a + 0.15))
			for b in alvos:
				V.estrela(self, (b as Vector2) + Vector2(0, -24.0), 8.0 * a + 3.0, Color(0.7, 1.0, 0.4), esc_c)
		Pecas.Poder.BRADO:
			# o rugido: anéis que se abrem até o raio
			var ra_b: float = float(ex.get("raio", 230.0)) * (1.0 - pow(1.0 - u, 2.0))
			V.aro(self, gp, ra_b, ra_b * 0.4, Color(1.0, 0.85, 0.5), a * 1.4, 3.0)
			V.aro(self, gp, ra_b * 0.7, ra_b * 0.28, Color(1.0, 0.6, 0.3), a * 1.2, 2.0)
			for b in alvos:
				V.cruz(self, (b as Vector2) + Vector2(0, -48.0), 4.0 + 4.0 * a, Color(1.0, 0.9, 0.3), esc_c)
		Pecas.Poder.RECOMPENSA:
			# a mira dourada cai sobre o marcado
			var d_r: Vector2 = ((alvos[0] as Vector2) if not alvos.is_empty() else p) + Vector2(0, -24.0)
			var ra_r: float = 12.0 + 40.0 * a
			V.aro(self, d_r, ra_r, ra_r, Color(1.0, 0.85, 0.2), 1.0, 2.0)
			V.cruz(self, d_r, ra_r * 0.8, Color(1.0, 0.85, 0.2), esc_c)
		Pecas.Poder.ESTASE:
			# bolha de estase abre sobre o bando
			var cx_e: Vector2 = Vector2(float(ex.get("x", p.x)), float(ex.get("y", p.y)) + 24.0 * ESC)
			V.domo(self, cx_e, float(ex.get("raio", 110.0)), rel, minf(1.0, u * 5.0), Color(0.55, 0.85, 1.0))
		Pecas.Poder.LOUCURA:
			# tentáculos roxos sobem do chão sob os enlouquecidos
			for b in alvos:
				var pe_l: Vector2 = (b as Vector2) + Vector2(0, 24.0 * ESC)
				for k in 3:
					var topo: Vector2 = pe_l + Vector2((k - 1) * 12.0 + sin(rel * 9.0 + k) * 8.0, -46.0 * minf(1.0, u * 4.0) * (1.0 - 0.25 * k))
					V.linha(self, pe_l + Vector2((k - 1) * 10.0, 0.0), topo, Color(0.55, 0.35, 0.8), 4.0)
					V.ponto(self, topo, Color(0.85, 0.7, 1.0))
		-4:
			# explosão radioativa
			var ra_x: float = float(ex.get("raio", 75.0)) * (1.0 - pow(1.0 - u, 2.0))
			V.aro(self, p + Vector2(0, 20.0), ra_x, ra_x * 0.4, Color(0.55, 1.0, 0.3), a * 1.4, 2.0)
			V.estrela(self, p, 18.0 * a + 4.0, Color(0.8, 1.0, 0.5), esc_c)
		-2:
			# Aparar com a faca: lâmina cruza o golpe e brilha
			V.faca_brilho(self, p, u, esc_c)
		_:
			V.aro(self, p + Vector2(0, 30), 10.0 + 80.0 * u, (10.0 + 80.0 * u) * 0.4, c, a * 1.3, 1.5)

## Canteiro (Jardineiro): chão florido com flores balançando; no chão, sob os gatos.
func _desenhar_canteiros() -> void:
	for zz in sim.zonas:
		var z: Dictionary = zz
		if z.get("tipo", "enxame") != "canteiro":
			continue
		var cx: float = float(z["x"])
		var cy: float = float(z["y"])
		var raio: float = float(z["raio"])
		var viva: float = clampf(float(z["t"]) / 0.5, 0.0, 1.0) * clampf((float(z["dur"]) - float(z["t"])) / 0.25, 0.0, 1.0)
		var pulso: float = 0.5 + 0.5 * sin(rel * 3.0)
		V.elipse(self, Vector2(cx, cy), raio, raio * 0.36, Color(0.45, 0.85, 0.35, (0.2 + 0.05 * pulso) * viva))
		V.aro(self, Vector2(cx, cy), raio, raio * 0.36, Color(0.95, 0.55, 0.8), viva, 1.0)
		for k in 12:
			var ang: float = k * 2.399
			var rr: float = raio * 0.92 * sqrt((k + 0.5) / 12.0)
			var fp := Vector2(cx + cos(ang) * rr, cy + sin(ang) * rr * 0.36)
			var balanco: float = roundf(sin(rel * 2.0 + k) * 1.5 / V.Q) * V.Q
			if viva > 0.2:
				V.quadro(self, fp.x, fp.y - V.Q * 2.0, V.Q, V.Q * 3.0, Color(0.25, 0.6, 0.25))
				var cor_f: Color = [Color(1.0, 0.55, 0.78), Color(1.0, 0.92, 0.45), Color(1, 1, 1)][k % 3]
				V.flor(self, fp + Vector2(balanco, -V.Q * 4.0), cor_f, Color(0.9, 0.6, 0.1), Color(0.3, 0.1, 0.2))
		for k in 3:
			var wk: float = fposmod(rel * 0.7 + k * 0.33, 1.0)
			if sin(wk * PI) * viva > 0.3:
				V.brilho(self, Vector2(cx + (k - 1.0) * raio * 0.5, cy - wk * 50.0), 3.0, Color(0.7, 1.0, 0.75), Color(0.1, 0.3, 0.15))

## Repelente (módulo da torre): a faixa do chão até REPELENTE_RAIO da torre, onde os bichos ficam lentos.
## Discreto: divisa pontilhada na grade e uns fiapos de névoa verde que sobem devagar; acende com bicho dentro.
func _desenhar_repelente() -> void:
	if not estado.tem_modulo(Torre.Modulo.REPELENTE):
		return
	var q: float = V.Q
	var xb: float = V.sn(Balanco.TORRE_X + Torre.REPELENTE_RAIO)
	var y0: float = V.sn(Balanco.CHAO_Y0)
	var y1: float = V.sn(Balanco.CHAO_Y1)
	var dentro: bool = false
	for v in sim.inimigos:
		var vv: Unidade = v
		if vv.vivo and vv.x - Balanco.TORRE_X <= Torre.REPELENTE_RAIO:
			dentro = true
			break
	var cor := Color(0.62, 0.95, 0.72, 0.55 if dentro else 0.3)
	var passo: float = q * 4.0
	var desl: float = V.sn(fposmod(rel * 9.0, passo))   # os pontinhos descem devagar pela divisa
	var yy: float = y0 + desl
	while yy < y1:
		draw_rect(Rect2(xb, yy, q, q * 2.0), cor)
		yy += passo
	# névoa: 7 fiapos de 2 quadradinhos que sobem e somem por encolhimento
	var larg: float = xb - V.sn(Balanco.TORRE_X)
	for k in 7:
		var w: float = fposmod(rel * 0.35 + k * 0.143, 1.0)
		var fx_: float = Balanco.TORRE_X + fposmod(k * 0.618, 1.0) * larg + sin(rel * 1.3 + k) * 6.0
		var fy_: float = y1 - fposmod(k * 0.382, 1.0) * (y1 - y0) * 0.8 - w * 40.0
		var s_n: float = q * (2.0 if w < 0.6 else 1.0)
		if w < 0.9:
			draw_rect(Rect2(V.sn(fx_), V.sn(fy_), s_n, q), Color(0.62, 0.95, 0.72, 0.4 if dentro else 0.25))

## Estruturas do lote 2 (torre de ervilha e bloco de pedra).
func _desenhar_estrutura(uu: Unidade, pos: Vector2, fl: float, dir: float) -> void:
	var frac: float = uu.vida / maxf(uu.vida_max, 1.0)
	var esc_e: float = ESC * 1.5
	if uu.estr_tipo == Simulacao.ESTR_TORRE:
		V.torre_ervilha(self, pos, esc_e, dir, uu.golpe, frac)
	else:
		V.bloco_pedra(self, pos, esc_e, frac)
	if fl > 0.05:
		V.disco(self, pos + Vector2(0, -28.0 * esc_e), 16.0 * esc_e, Color(1, 1, 1, 0.45 * fl))
	if uu.clone_t < 1.0:
		V.aro(self, pos + Vector2(0, -20.0 * esc_e), 20.0 * esc_e, 14.0 * esc_e, Color(1, 1, 1), 0.5 + 0.5 * sin(rel * 30.0), 1.0)

## Manteiga escorregadia: poça amarela brilhante no chão, com setas de deslizamento.
func _desenhar_manteigas() -> void:
	for zz in sim.zonas:
		var z: Dictionary = zz
		if z.get("tipo", "") != "manteiga":
			continue
		var cx: float = float(z["x"])
		var cy: float = float(z["y"]) + 24.0 * ESC
		var raio: float = float(z["raio"])
		var viva: float = clampf(float(z["t"]) / 0.5, 0.0, 1.0) * clampf((float(z["dur"]) - float(z["t"])) / 0.2, 0.0, 1.0)
		V.elipse(self, Vector2(cx, cy), raio * viva, raio * 0.36 * viva, Color(1.0, 0.88, 0.3, 0.55))
		V.elipse(self, Vector2(cx - raio * 0.12, cy - 3.0), raio * 0.62 * viva, raio * 0.2 * viva, Color(1.0, 0.96, 0.62, 0.7))
		V.aro(self, Vector2(cx, cy), raio * viva, raio * 0.36 * viva, Color(0.95, 0.7, 0.15), viva, 1.0)
		var sent: float = 1.0 if int(z["eq"]) == 0 else -1.0
		for k in 4:
			var w: float = fposmod(rel * 0.9 + k * 0.25, 1.0)
			var px_: float = cx + sent * (w - 0.5) * raio * 1.3
			var py_: float = cy + (k - 1.5) * raio * 0.1
			if viva > 0.3:
				V.seta(self, Vector2(px_, py_), sent, Color(1.0, 0.95, 0.55), Color(0.55, 0.35, 0.05))
		if viva > 0.3:
			for k in 3:
				var wb: float = fposmod(rel * 1.1 + k * 0.33, 1.0)
				V.brilho(self, Vector2(cx + (k - 1.0) * raio * 0.45, cy - 2.0 - wb * 18.0), 2.5, Color(1, 1, 0.8), Color(0.5, 0.35, 0.05))

## Mudas da Colheita: brotos que crescem até o momento de amadurecer.
func _desenhar_domos() -> void:
	for zz in sim.zonas:
		var z: Dictionary = zz
		if z.get("tipo", "") != "domo":
			continue
		var viva: float = clampf(float(z["t"]) / 0.5, 0.0, 1.0) * clampf((float(z["dur"]) - float(z["t"])) / 0.3, 0.0, 1.0)
		V.domo(self, Vector2(float(z["x"]), float(z["y"]) + 24.0 * ESC), float(z["raio"]), rel, viva, Color(0.55, 0.75, 1.0))

## Pedra rolante: a rocha em movimento, com poeira atrás.
func _desenhar_rastros() -> void:
	for rr in sim.rastros:
		var r: Dictionary = rr
		var a: float = clampf(float(r["t"]) / Balanco.RASTRO_T, 0.0, 1.0)
		var p := Vector2(V.sn(float(r["x"])), V.sn(float(r["y"])))
		V.quadro(self, p.x - V.Q * 4.0, p.y - V.Q, V.Q * 8.0, V.Q * 2.0, Color(0.3, 0.95, 1.0, 0.35 + 0.5 * a))
		V.quadro(self, p.x - V.Q * 2.0, p.y - V.Q * 0.0, V.Q * 4.0, V.Q, Color(1, 1, 1, 0.3 + 0.6 * a))

func _desenhar_pedras() -> void:
	for oo in sim.ondas:
		var o: Dictionary = oo
		var pe := Vector2(float(o["x"]), float(o["y"]) + 4.0)
		var sx: float = signf(float(o["vx"]))
		V.elipse(self, pe + Vector2(0, 16.0), 26.0, 8.0, Color(0, 0, 0, 0.3))
		for k in 3:
			V.cruz(self, pe + Vector2(-sx * (26.0 + k * 14.0), 8.0 - k * 5.0 + sin(rel * 12.0 + k) * 2.0), 3.0, Color(0.75, 0.68, 0.55), V.CONT)
		V.rocha(self, pe, 24.0, float(o["x"]) / 90.0)

## Laço de seda: fio entre os bichos ligados (em ordem) e um anel vermelho em cada um.
func _desenhar_lacos() -> void:
	for ll in sim.lacos:
		var l: Dictionary = ll
		var ms: Array = l["membros"]
		var viva: float = clampf(float(l["t"]) / 0.4, 0.0, 1.0)
		for i in ms.size():
			var m: Unidade = ms[i]
			var pm := Vector2(m.vx, m.vy - 30.0 * ESC)
			V.aro(self, pm + Vector2(0, 14.0), 20.0, 10.0, Color(0.9, 0.2, 0.3), viva, 1.0)
			if i > 0:
				var m0: Unidade = ms[i - 1]
				V.fio(self, Vector2(m0.vx, m0.vy - 30.0 * ESC), pm, Color(0.9, 0.2, 0.3, viva), rel)

## Rastro de chamas azuis do Turbo: uma labareda por zona.
func _desenhar_chamas() -> void:
	for zz in sim.zonas:
		var z: Dictionary = zz
		if z.get("tipo", "") != "chama":
			continue
		var viva: float = clampf(float(z["t"]) / 0.6, 0.0, 1.0)
		var bz := Vector2(float(z["x"]), float(z["y"]) + 24.0 * ESC)
		V.elipse(self, bz, float(z["raio"]) * viva, float(z["raio"]) * 0.36 * viva, Color(0.15, 0.5, 1.0, 0.3))
		V.chama_azul(self, bz, float(z["raio"]) * 1.2, 30.0 * viva, rel + float(z["x"]) * 0.05)

func _desenhar_mudas() -> void:
	for zz in sim.zonas:
		var z: Dictionary = zz
		if z.get("tipo", "") != "muda":
			continue
		var w: float = 1.0 - clampf(float(z["t"]) / maxf(float(z["dur"]), 0.01), 0.0, 1.0)
		V.muda(self, Vector2(float(z["x"]), float(z["y"]) + 24.0 * ESC), w)

## Enxame: pontinhos amarelos e pretos girando sobre a área de cada nuvem ativa (sim.zonas).
func _desenhar_zonas() -> void:
	for zz in sim.zonas:
		var z: Dictionary = zz
		if z.get("tipo", "enxame") in ["canteiro", "manteiga", "muda", "domo", "chama", "apagao"]:
			continue
		var centro: Vector2 = Vector2(float(z["x"]), float(z["y"]) - 34.0 * ESC)
		var raio: float = float(z["raio"])
		var viva: float = clampf(float(z["t"]) / 0.4, 0.0, 1.0)
		V.elipse(self, centro + Vector2(0, 30.0), raio, raio * 0.35, Color(1.0, 0.85, 0.15, 0.12 * viva))
		V.aro(self, centro + Vector2(0, 30.0), raio, raio * 0.35, Color(1.0, 0.85, 0.15), viva, 1.0)
		if viva > 0.3:
			for k in 14:
				var ang: float = rel * (2.5 + (k % 3)) + k * 2.399
				var rr: float = raio * (0.25 + 0.75 * fposmod(k * 0.382, 1.0))
				var pb: Vector2 = centro + Vector2(cos(ang) * rr, sin(ang * 1.3) * rr * 0.45 - 6.0 * sin(rel * 9.0 + k))
				V.quadro(self, pb.x - V.Q, pb.y - V.Q, V.Q * 3.0, V.Q * 2.0, V.CONT)
				V.quadro(self, pb.x - V.Q, pb.y - V.Q + 0.0, V.Q, V.Q, Color(1.0, 0.85, 0.15) if k % 2 == 0 else Color(0.2, 0.15, 0.15))
				V.quadro(self, pb.x, pb.y - V.Q, V.Q, V.Q, Color(0.2, 0.15, 0.15) if k % 2 == 0 else Color(1.0, 0.85, 0.15))
				if sin(rel * 30.0 + k) > 0.0:
					V.ponto(self, pb + Vector2(0, -V.Q * 2.0), Color(0.9, 0.95, 1.0))

## Estados visíveis de uma unidade (corpo baixo e comprido): queimando, gelo, atordoada,
## protegida, frenesi, fúria. `pos` são os pés; `esc_u` já inclui ESC.
func _estados(uu: Unidade, pos: Vector2, esc_u: float, dir: float) -> void:
	var h: float = CORPO_ALT * esc_u
	var meio: Vector2 = pos + Vector2(0, -CORPO_MEIO * esc_u)
	if uu.queima_t > 0.0:
		_chamas(pos, esc_u)
	if uu.sequestro_t > 0.0:
		# dormindo com os peixes: sombra vazia no chão, "zzz" e um peixinho de pixel
		V.elipse(self, pos + Vector2(0, 2), CORPO_LARG * 1.05 * esc_u, 8.0 * esc_u, Color(0.1, 0.05, 0.12, 0.6))
		for k in 3:
			var wzs: float = fposmod(rel * 0.7 + k * 0.33, 1.0)
			V.zzz(self, pos + Vector2(8.0 * esc_u + wzs * 16.0, -h - 4.0 - wzs * 30.0), 1.0 + (1.0 if k == 2 else 0.0), Color(0.85, 0.92, 1.0))
		var pe_x: float = V.sn(pos.x)
		var pe_y: float = V.sn(pos.y - h - 22.0)
		V.quadro(self, pe_x - V.Q * 3.0, pe_y - V.Q, V.Q * 6.0, V.Q * 3.0, V.CONT)
		V.quadro(self, pe_x - V.Q * 2.0, pe_y, V.Q * 3.0, V.Q, Color(0.55, 0.8, 0.95))
		V.quadro(self, pe_x + V.Q, pe_y - V.Q * 0.0, V.Q * 2.0, V.Q, Color(0.3, 0.5, 0.75))
	if uu.comboio:
		for k in 2:
			var wcb: float = fposmod(rel * 2.2 + k * 0.5, 1.0)
			V.quadro(self, pos.x + (10.0 + wcb * 18.0) * esc_u, pos.y - h * (0.35 + 0.3 * k), V.Q * 3.0, V.Q, Color(1.0, 0.55, 0.15, 1.0 - wcb))
	if uu.mutante:
		V.aro(self, meio, (CORPO_LARG + 4.0) * esc_u, (CORPO_MEIO + 6.0) * esc_u, Color(0.75, 0.35, 1.0), 0.6 + 0.3 * sin(rel * 14.0), 1.5)
		V.ponto(self, pos + Vector2(cos(rel * 7.0) * 14.0 * esc_u, -h - 6.0), Color(1.0, 0.9, 0.2))
	if uu.falange > 0:
		for k in uu.falange:
			V.quadro(self, pos.x - (CORPO_LARG * 0.9 + 4.0 * k) * esc_u, pos.y - h * 0.8 + 6.0 * k, V.Q, V.Q * 4.0, Color(0.9, 0.55, 0.35))
	if uu.recompilou and uu.vivo:
		V.quadro(self, pos.x + CORPO_LARG * 0.5 * esc_u, pos.y - h * 0.5, V.Q, V.Q, Color(0.3, 0.9, 1.0, 0.6 + 0.3 * sin(rel * 20.0)))
	if uu.sono_t > 0.0 or uu.cochilo_t > 0.0:
		# um "z" só por unidade, que sobe em diagonal e cresce no meio; a fase vem da unidade, então
		# vizinhos dormindo não sobem juntos (antes eram 3 caixas por gato, empilhadas)
		var wz: float = fposmod(rel * 0.55 + float(uu.get_instance_id() % 89) * 0.173, 1.0)
		if wz < 0.9:
			V.zzz(self, pos + Vector2(8.0 * esc_u + wz * 18.0, -h - 10.0 - wz * 30.0), 2.0 if wz > 0.35 else 1.0, Color(0.85, 0.92, 1.0))
	if uu.frio_t > 0.0:
		V.elipse(self, pos + Vector2(0, 2), CORPO_LARG * 1.05 * esc_u, 8.0 * esc_u, Color(0.6, 0.85, 1.0, 0.4))
		for k in 5:
			var hh: float = (14.0 + (k % 2) * 8.0 - absf(k - 2) * 2.0) * esc_u
			V.cristal(self, pos + Vector2((k - 2) * 15.0 * esc_u, 3.0), 5.0, hh, Color(0.55, 0.85, 1.0), Color(0.1, 0.18, 0.45))
		for k in 3:
			var fr: float = fposmod(rel * 1.6 + k * 0.33, 1.0)
			V.ponto(self, pos + Vector2((k - 1) * 22.0, -h + fr * 36.0), Color(0.85, 0.95, 1.0))
	if uu.carga_t > 0.0:
		var pc_k: float = 1.0 - uu.carga_t / maxf(uu.carga_dur, 0.01)
		V.aro(self, meio, (CORPO_LARG + 6.0 + 8.0 * pc_k) * esc_u, (CORPO_MEIO + 8.0 + 8.0 * pc_k) * esc_u, Color(1.0, 0.85, 0.2), 0.6 + 0.4 * sin(rel * 18.0), 1.5)
		for k in 5:
			var wk_k: float = fposmod(rel * 2.0 + k * 0.2, 1.0)
			V.quadro(self, pos.x + (k - 2) * 8.0 * esc_u - V.Q * 0.5, pos.y - h * wk_k, V.Q, V.Q * 3.0, Color(1.0, 0.9, 0.35))
	if uu.gigante_t > 0.0:
		V.aro(self, meio, (CORPO_LARG + 8.0) * esc_u, (CORPO_MEIO + 10.0) * esc_u, Color(0.4, 1.0, 0.5), 0.6 + 0.4 * sin(rel * 8.0), 1.5)
	if uu.escudo > 0.0:
		V.aro(self, meio, (CORPO_LARG + 3.0) * esc_u, (CORPO_MEIO + 5.0) * esc_u, Color(0.6, 0.9, 1.0), 0.8, 2.0)
	if uu.medo_t > 0.0:
		V.quadro(self, pos.x - V.Q * 0.5, pos.y - h - 26.0, V.Q, V.Q * 3.0, Color(1.0, 0.9, 0.3))
		V.quadro(self, pos.x - V.Q * 0.5, pos.y - h - 26.0 + V.Q * 4.0, V.Q, V.Q, Color(1.0, 0.9, 0.3))
	if uu.radio_t > 0.0:
		V.aro(self, meio, (CORPO_LARG + 2.0) * esc_u, (CORPO_MEIO + 3.0) * esc_u, Color(0.5, 1.0, 0.3), 0.5 + 0.4 * sin(rel * 12.0), 1.5)
		for k in 3:
			var fr_r: float = fposmod(rel * 1.2 + k * 0.33, 1.0)
			V.ponto(self, pos + Vector2((k - 1) * 12.0 * esc_u, -h * fr_r), Color(0.6, 1.0, 0.35))
	if uu.estase_t > 0.0:
		V.aro(self, meio, (CORPO_LARG + 8.0) * esc_u, (CORPO_MEIO + 10.0) * esc_u, Color(0.6, 0.85, 1.0), 0.9, 2.0)
		V.elipse(self, pos + Vector2(0, 2), CORPO_LARG * 1.05 * esc_u, 8.0 * esc_u, Color(0.6, 0.85, 1.0, 0.4))
		V.ponto(self, meio + Vector2(-CORPO_LARG * 0.6 * esc_u, -CORPO_MEIO * 0.6 * esc_u), Color(1, 1, 1))
	if uu.confuso_t > 0.0:
		for k in 3:
			var ar_c: float = rel * 7.0 + k * 2.1
			V.quadro(self, V.sn(pos.x + cos(ar_c) * 13.0 * esc_u), V.sn(pos.y - h - 10.0 + sin(ar_c) * 4.0), V.Q, V.Q, Color(1.0, 0.9, 0.3) if k % 2 == 0 else Color(0.8, 0.5, 1.0))
	if uu.louco_t > 0.0:
		for k in 3:
			var ar_l: float = rel * 6.0 + k * 2.1
			V.ponto(self, pos + Vector2(cos(ar_l) * 14.0 * esc_u, -h - 8.0 + sin(ar_l) * 5.0), Color(0.8, 0.5, 1.0))
	if uu.rec_t > 0.0:
		V.aro(self, meio, 18.0 * esc_u, 18.0 * esc_u, Color(1.0, 0.85, 0.2), 0.9, 1.5)
		V.cruz(self, meio, 12.0 * esc_u, Color(1.0, 0.85, 0.2), V.CONT)
	if uu.alma > 0.0:
		var larg_a: float = 24.0
		V.quadro(self, pos.x - larg_a * 0.5 - V.Q, pos.y - h - 16.0 - V.Q, larg_a + V.Q * 2.0, V.Q * 3.0, V.CONT)
		V.quadro(self, pos.x - larg_a * 0.5, pos.y - h - 16.0, larg_a * uu.alma / Balanco.ALMA_MAX, V.Q, V.BRANCO)
	if uu.noir_t > 0.0:
		# Modo Noir: contorno branco leve e grão de filme sobre o gato em preto e branco
		V.aro(self, meio, (CORPO_LARG + 2.0) * esc_u, (CORPO_MEIO + 4.0) * esc_u, V.BRANCO, 0.35 + 0.15 * sin(rel * 9.0), 1.0)
		V.grao_filme(self, meio, CORPO_LARG * 0.8 * esc_u, CORPO_MEIO * 0.9 * esc_u, rel, 0.8, 8)
	if uu.foco_t > 0.0:
		var pf_m: float = 0.5 + 0.5 * sin(rel * 10.0)
		V.aro(self, meio, (CORPO_LARG + 6.0) * esc_u, (CORPO_MEIO + 8.0) * esc_u, Color(1.0, 0.3, 0.3), 0.6 + 0.4 * pf_m, 1.5)
		V.cruz(self, pos + Vector2(0, -h - 14.0 - 4.0 * pf_m), 5.0, Color(1.0, 0.4, 0.4), V.CONT)
	if uu.lobo_t > 0.0:
		var rl_u: float = Balanco.PODER_LOBO_RAIO * (0.97 + 0.03 * sin(rel * 6.0))
		V.aro(self, pos + Vector2(0, 2), rl_u, rl_u * 0.36, Color(0.95, 0.25, 0.25), 0.8, 1.0)
		V.elipse(self, pos + Vector2(0, 2), CORPO_LARG * 1.1 * esc_u, 9.0 * esc_u, Color(1.0, 0.2, 0.15, 0.22))
	if uu.esforco_t > 0.0:
		for k in 4:
			var we: float = fposmod(rel * 1.4 + k * 0.25, 1.0)
			var xe: float = pos.x + (k - 1.5) * 12.0 * esc_u
			V.quadro(self, xe - V.Q, pos.y - h * we - V.Q, V.Q * 3.0, V.Q * 5.0, V.CONT)
			V.quadro(self, xe, pos.y - h * we, V.Q, V.Q * 3.0, Color(1.0, 0.25, 0.25))
	if uu.protegido_t > 0.0:
		var rx: float = (CORPO_LARG + 2.0) * esc_u
		var ry: float = (CORPO_MEIO + 4.0) * esc_u
		V.aro(self, meio, rx, ry, Color(1.0, 0.9, 0.5), 1.0, 1.0)
		V.brilho(self, meio + Vector2(-rx * 0.6, -ry * 0.6), 3.0, Color(1, 1, 0.95), Color(0.4, 0.3, 0.05))
	if uu.frenesi_t > 0.0:
		for k in 4:
			var w: float = fposmod(rel * 3.0 + k * 0.25, 1.0)
			var yy: float = pos.y - (9.0 + k * 12.0) * esc_u
			var x1: float = pos.x - dir * (CORPO_LARG * 0.95 * esc_u + w * 16.0)
			if w < 0.8:
				V.quadro(self, minf(x1, x1 - dir * 24.0), yy, 24.0, V.Q, Color(1.0, 0.7, 0.25))
	if uu.furia > 0.0:
		var fa: float = clampf(uu.furia, 0.0, 1.0)
		# poça vermelha no chão (alfa em 2 degraus, piscando) e brasas de raiva que sobem e encolhem
		var pisca_f: float = 0.08 if sin(rel * 8.0) > 0.0 else 0.0
		V.elipse(self, pos + Vector2(0, 2), CORPO_LARG * 1.1 * esc_u, 9.0 * esc_u, Color(1.0, 0.2, 0.15, 0.2 * fa + pisca_f))
		for k in 3:
			var w: float = fposmod(rel * 1.5 + k * 0.33, 1.0)
			if w > 0.85 or fa < 0.15:
				continue
			var pf: Vector2 = pos + Vector2((k - 1) * 22.0, -h * 0.9 - w * 18.0)
			var sf: float = V.Q * (2.0 if w < 0.45 else 1.0)
			V.quadro(self, pf.x - V.Q, pf.y - V.Q, sf + V.Q * 2.0, sf + V.Q * 2.0, Color(0.3, 0.04, 0.04))
			V.quadro(self, pf.x, pf.y, sf, sf, Color(1.0, 0.4, 0.3) if w < 0.45 else Color(1.0, 0.7, 0.45))
	if uu.preso_t > 0.0:
		var pe_t: Vector2 = pos + Vector2(0, 2)
		var wx: float = CORPO_LARG * esc_u
		var wy: float = 9.0 * esc_u
		V.elipse(self, pe_t, wx, wy, Color(0.9, 0.93, 1.0, 0.3))
		V.quadro(self, pe_t.x - wx, pe_t.y, wx * 2.0, V.Q * 0.5, Color(1, 1, 1))
		V.quadro(self, pe_t.x, pe_t.y - wy, V.Q * 0.5, wy * 2.0, Color(1, 1, 1))
		V.linha(self, pe_t - Vector2(wx, wy) * 0.7, pe_t + Vector2(wx, wy) * 0.7, Color(1, 1, 1), V.Q * 1.5)
		V.linha(self, pe_t + Vector2(-wx, wy) * 0.7, pe_t + Vector2(wx, -wy) * 0.7, Color(1, 1, 1), V.Q * 1.5)
		V.aro(self, pe_t, wx * 0.55, wy * 0.55, Color(1, 1, 1), 1.0, 1.0)
		V.aro(self, pe_t, wx, wy, Color(1, 1, 1), 1.0, 1.0)
	if uu.marcado_t > 0.0:
		var pr_m: float = 0.5 + 0.5 * sin(rel * 8.0)
		V.aro(self, meio, (CORPO_LARG + 4.0) * esc_u, (CORPO_MEIO + 6.0) * esc_u, Color(1.0, 0.25, 0.25), 0.55 + 0.45 * pr_m, 1.0)
	if uu.furor_t > 0.0:
		V.elipse(self, pos + Vector2(0, 2), CORPO_LARG * 1.15 * esc_u, 10.0 * esc_u, Color(1.0, 0.2, 0.1, 0.28 + 0.1 * sin(rel * 12.0)))
		for k in 3:
			V.chama(self, pos + Vector2((k - 1) * 20.0 * esc_u, -2.0), 10.0, h * (0.35 + 0.15 * (k % 2)), rel + k)
	if uu.bola_t > 0.0:
		for k in 8:
			var ang_s: float = rel * 6.0 + k * TAU / 8.0
			var dv_s := Vector2(cos(ang_s) * (CORPO_LARG + 2.0) * esc_u, sin(ang_s) * (CORPO_MEIO + 4.0) * esc_u)
			V.quadro(self, meio.x + dv_s.x * 1.2 - V.Q, meio.y + dv_s.y * 1.2 - V.Q, V.Q * 3.0, V.Q * 3.0, V.CONT)
			V.quadro(self, meio.x + dv_s.x * 1.2, meio.y + dv_s.y * 1.2, V.Q, V.Q, Color(0.92, 0.96, 1.0))
			V.quadro(self, meio.x + dv_s.x, meio.y + dv_s.y, V.Q, V.Q, Color(0.92, 0.96, 1.0))
	if uu.oculto_t > 0.0:
		for k in 3:
			var wo: float = fposmod(rel * 0.8 + k * 0.33, 1.0)
			var tam_o: float = (9.0 + 5.0 * wo) * esc_u * 0.8 * (1.0 - wo * 0.6)
			if tam_o >= 4.0:
				V.bolha(self, meio + Vector2((k - 1) * 20.0 * esc_u, 14.0 - wo * 30.0 * esc_u), tam_o, Color(0.5, 0.45, 0.6))
	if uu.atordoado_t > 0.0:
		for k in 3:
			var ang: float = rel * 6.0 + k * TAU / 3.0
			V.brilho(self, pos + Vector2(cos(ang) * 22.0, -h - 6.0 + sin(ang) * 6.0), 4.0, Desenho.DOURADO, Color(0.3, 0.18, 0.0))

## Coroa dourada de pixel sobre o rival-líder (3º ato): `c` é o centro da base da coroa.
func _coroa_lider(c: Vector2) -> void:
	var q: float = V.Q
	var ouro := Color(1.0, 0.82, 0.2)
	var sombra := Color(0.78, 0.5, 0.08)
	draw_rect(Rect2(c.x - 3.0 * q, c.y - 3.0 * q, 6.0 * q, 4.0 * q), V.CONT)
	draw_rect(Rect2(c.x - 2.0 * q, c.y - 2.0 * q, q, q), ouro)
	draw_rect(Rect2(c.x, c.y - 2.0 * q, q, q), ouro)
	draw_rect(Rect2(c.x + q, c.y - 2.0 * q, q, q), ouro)
	draw_rect(Rect2(c.x - 2.0 * q, c.y - q, 4.0 * q, q), ouro)
	draw_rect(Rect2(c.x - 2.0 * q, c.y, 4.0 * q, q), sombra)

## Fileira de ícones de estado sobre a barra de vida (ver IconesEstado): até `maximo` ícones, na ordem de
## prioridade (controle primeiro); se sobrar estado, o último é o "…". Pisca no último 0,5 s.
## Devolve quantos ícones desenhou.
func _fila_estados(uu: Unidade, bx: float, by: float, maximo: int) -> int:
	var n: int = IconesEstado.ativos(uu, sim.zonas, _ico_ids, _ico_t)
	if n == 0:
		return 0
	var mostra: int = mini(n, maximo)
	var corta: bool = n > maximo
	var largura: float = mostra * 21.0 - 1.0   # ícones em escala 2 (20 px), legíveis na luta
	var x0: float = bx - largura * 0.5 + 10.0
	var piscar: bool = fposmod(rel * 5.0, 1.0) < 0.5
	for i in mostra:
		var id: int = _ico_ids[i]
		var tp: float = _ico_t[i]
		if corta and i == mostra - 1:
			id = IconesEstado.E.MAIS
		elif tp < 0.5 and piscar:
			continue
		IconesEstado.desenhar(self, id, Vector2(x0 + i * 21.0, by - 13.0), 2)
	return mostra

func _halo(c: Vector2, r: float, cor: Color, n: int = 9) -> void:
	for g in n:
		draw_circle(c, r * float(n - g) / n, cor)

## Relógios visuais da torre-fortaleza e vida dos efeitos de módulos/troféus.
func _atualizar_torre(dt: float) -> void:
	golpe_torre = move_toward(golpe_torre, 0.0, dt * 1.8)
	ratoeira_t = maxf(0.0, ratoeira_t - dt)
	sirene_t = maxf(0.0, sirene_t - dt)
	balista_t = maxf(0.0, balista_t - dt)
	caldeirao_t = maxf(0.0, caldeirao_t - dt)
	fosso_t = maxf(0.0, fosso_t - dt)
	reforco_t = maxf(0.0, reforco_t - dt)
	luneta_t = maxf(0.0, luneta_t - dt)
	trofeu_pulso = move_toward(trofeu_pulso, 0.0, dt * 3.0)
	if catapulta_t >= 0.0:
		catapulta_t += dt
		if catapulta_t > 1.8:
			catapulta_t = -1.0
	if novo_s >= 0.0:
		novo_s += dt
		if novo_s > 1.4:
			novo_s = -1.0
			novo_idx = -1
	# recuo do canhão: enquanto um tiro da torre está perto da boca
	recuo_canhao = 0.0
	for pr in sim.projeteis:
		var d: Dictionary = pr
		if d["dono"] == null:
			recuo_canhao = maxf(recuo_canhao, clampf(1.0 - (float(d["x"]) - (Balanco.TORRE_X - 70.0)) / 70.0, 0.0, 1.0))
	for i in range(tfx.size() - 1, -1, -1):
		var f: Dictionary = tfx[i]
		f["t"] = float(f["t"]) + dt
		if float(f["t"]) >= float(f["dur"]):
			_fim_tfx(f)
			tfx.remove_at(i)

## Posição do troféu em voo: sobe do bicho (0..25%) e depois voa em arco até o contador do HUD.
func _pos_trofeu(f: Dictionary, u: float) -> Vector2:
	var ini: Vector2 = f["ini"]
	var alvo: Vector2 = TROFEU_CONTADOR + Vector2(9, 8)
	if u < 0.25:
		var w0: float = u / 0.25
		return ini + Vector2(0, -46.0 * (1.0 - (1.0 - w0) * (1.0 - w0)))
	var w: float = (u - 0.25) / 0.75
	var e: float = w * w * (3.0 - 2.0 * w)
	return (ini + Vector2(0, -46)).lerp(alvo, e) + Vector2(0, -110.0 * sin(PI * w))

func _desenhar_tfx() -> void:
	for fx_t in tfx:
		var f: Dictionary = fx_t
		var t: float = f["t"]
		if t < 0.0:
			continue
		var u: float = clampf(t / float(f["dur"]), 0.0, 1.0)
		match f["k"]:
			"trofeu":
				var cel: float = 3.0 if int(f["n"]) < 5 else 4.0
				for k in range(4, 0, -1):
					var uu: float = maxf(u - k * 0.03, 0.0)
					var sk: float = 8.0 - k * 1.5
					var pk: Vector2 = _pos_trofeu(f, uu)
					V.quadro(self, pk.x - sk * 0.5, pk.y - sk * 0.5, sk, sk, Color(1.0, 0.85, 0.3))
				var p: Vector2 = _pos_trofeu(f, u)
				V.brilho(self, p + Vector2(18.0, -16.0), 4.0 + 2.0 * sin(rel * 14.0), Color(1.0, 0.95, 0.6), Color(0.4, 0.25, 0.05))
				TorrePx.desenhar_trofeu(self, p, cel)
			"onda":
				var r: float = float(f["raio"]) * (1.0 - (1.0 - u) * (1.0 - u))
				var cor: Color = f["cor"]
				var ry: float = 0.4 if f["chao"] else 0.3
				var pc: Vector2 = f["p"]
				if f["chao"]:
					V.elipse(self, pc, r, r * ry, Color(cor.r, cor.g, cor.b, 0.16 * (1.0 - u)))
				V.aro(self, pc, r + V.Q, r * ry + V.Q, V.CONT, 1.0 - u, 2.0)
				V.aro(self, pc, r, r * ry, cor, 1.0 - u, 2.0 if u < 0.5 else 1.0)
				V.aro(self, pc, r * 0.9, r * ry * 0.9, Color(1, 0.9, 0.8), (1.0 - u) * 0.7, 1.0)
			"pena":
				var a: Vector2 = f["a"]
				var b: Vector2 = f["b"]
				var cabeca: Vector2 = a.lerp(b, minf(1.0, u / 0.45))
				var cauda: Vector2 = a.lerp(b, clampf((u - 0.15) / 0.5, 0.0, 1.0))
				var al: float = 1.0 - clampf((u - 0.6) / 0.4, 0.0, 1.0)
				if al > 0.15:
					V.linha(self, cauda, cabeca, V.CONT, V.Q * 3.0)
					V.linha(self, cauda, cabeca, Color(1.0, 0.95, 0.9), V.Q * 1.5)
					var dirp: Vector2 = (b - a).normalized()
					var nrm: Vector2 = dirp.orthogonal()
					var dist: float = cauda.distance_to(cabeca)
					for k in mini(int(dist / 28.0), 6):
						var qq: Vector2 = cabeca - dirp * (k * 28.0 + 6.0)
						V.linha(self, qq, qq - dirp * 9.0 + nrm * 7.0, Color(1.0, 0.8, 0.85), V.Q)
						V.linha(self, qq, qq - dirp * 9.0 - nrm * 7.0, Color(1.0, 0.8, 0.85), V.Q)
					V.brilho(self, cabeca, 5.0, Color(1, 1, 1), V.CONT)
			"bolha":
				var ini_b: Vector2 = f["ini"]
				var fim_b: Vector2 = f["fim"]
				var pb: Vector2 = ini_b.lerp(fim_b, u) + Vector2(sin(u * 18.0) * 8.0, 0.0)
				V.bolha(self, pb, 7.0 + 3.0 * sin(u * 20.0), Color(0.55, 1.0, 0.55), Color(0.1, 0.35, 0.15))
			"saco":
				var ini_s: Vector2 = f["ini"]
				var fim_s: Vector2 = f["fim"]
				var ps: Vector2 = ini_s.lerp(fim_s, u) + Vector2(0, -190.0 * sin(PI * u))
				var sombra: Vector2 = ini_s.lerp(fim_s, u)
				V.elipse(self, Vector2(sombra.x, fim_s.y if u > 0.5 else sombra.y + 40.0), 12.0 * (1.0 - 0.4 * sin(PI * u)), 4.0, Color(0, 0, 0, 0.25))
				var gi: float = floorf(u * 6.0)   # o saco gira em 4 posições (viradas de 90 graus)
				var sx: float = V.sn(ps.x)
				var sy: float = V.sn(ps.y)
				V.quadro(self, sx - 12.0, sy - 12.0, 24.0, 24.0, V.CONT)
				V.quadro(self, sx - 9.0, sy - 9.0, 18.0, 18.0, Color(0.78, 0.58, 0.32))
				V.quadro(self, sx - 9.0, sy - 9.0, 18.0, 6.0 if int(gi) % 2 == 0 else 3.0, Color(0.92, 0.74, 0.46))
				V.quadro(self, sx - 6.0 + (6.0 if int(gi) % 2 == 1 else 0.0), sy - 15.0, 6.0, 6.0, Color(0.55, 0.12, 0.14))
			"drop_rar":
				# pilar de luz que sobe, aros e brilhos na cor da raridade; mais raridade, mais coisa
				var rar_d: int = int(f["rar"])
				var cd: Color = Pecas.cor_rar(rar_d)
				var pd: Vector2 = f["p"]
				var alt_d: float = 120.0 + 30.0 * rar_d
				var l_d: float = V.sn(18.0 + 6.0 * rar_d)
				var fd: float = 1.0 - u
				V.quadro(self, pd.x - l_d * 0.5, pd.y - alt_d * minf(1.0, u * 5.0), l_d, alt_d * minf(1.0, u * 5.0), Color(cd.r, cd.g, cd.b, 0.22 * fd))
				V.quadro(self, pd.x - l_d * 0.2, pd.y - alt_d * minf(1.0, u * 5.0), l_d * 0.4, alt_d * minf(1.0, u * 5.0), Color(1, 1, 1, 0.35 * fd))
				for k in 1 + rar_d / 2:
					var wd: float = clampf(u * 1.6 - k * 0.2, 0.0, 1.0)
					V.aro(self, pd + Vector2(0, 28), 10.0 + 60.0 * wd, (10.0 + 60.0 * wd) * 0.35, cd, 1.0 - wd, 1.5)
				for k in 2 + rar_d:
					var ad: float = rel * 2.0 + k * TAU / (2.0 + rar_d)
					var rd: float = 20.0 + 34.0 * u
					if fd > 0.2:
						V.brilho(self, pd + Vector2(cos(ad) * rd, sin(ad) * rd * 0.7 - 20.0 * u), 3.0 + rar_d * 0.6, V.tom(cd, 1.3), V.CONT)
				if rar_d >= 5:
					draw_rect(Rect2(-20, -20, 1320, 760), Color(1.0, 0.92, 0.96, 0.12 * clampf(1.0 - u * 4.0, 0.0, 1.0)))
			"nocaute":
				var pn: Vector2 = f["p"]
				var fn: float = 1.0 - u
				V.aro(self, pn + Vector2(0, 24), 10.0 + 44.0 * u, (10.0 + 44.0 * u) * 0.35, Color(0.8, 0.88, 1.0), fn, 1.0)
				for k in 3:
					var an: float = u * 10.0 + k * TAU / 3.0
					V.brilho(self, pn + Vector2(cos(an) * 20.0, -50.0 + sin(an) * 6.0 - 10.0 * u), 4.0, Color(1.0, 0.95, 0.6) if fn > 0.3 else Color(0.8, 0.88, 1.0), Color(0.15, 0.12, 0.3))
			"aviso_cortado":
				# balão do aviso estoura: aro que se abre em pontilhado, o "!" partido em dois e um X por cima
				var pv: Vector2 = f["p"]
				var fv: float = 1.0 - u
				var rv: float = 20.0 + 26.0 * u
				V.aro(self, pv, rv + V.Q, rv + V.Q, V.CONT, fv, 2.0)
				V.aro(self, pv, rv, rv, Color(1.0, 0.85, 0.4), fv, 1.0)
				if fv > 0.25 or fposmod(rel * 18.0, 1.0) < 0.5:
					_exclamacao(pv, Color(1.0, 0.93, 0.7), 1 + int(u * 3.0), true)
				if u < 0.6:
					var bx_v: float = 13.0
					V.linha(self, pv + Vector2(-bx_v, -bx_v), pv + Vector2(bx_v, bx_v), V.CONT, V.Q * 3.0)
					V.linha(self, pv + Vector2(-bx_v, bx_v), pv + Vector2(bx_v, -bx_v), V.CONT, V.Q * 3.0)
					V.linha(self, pv + Vector2(-bx_v, -bx_v), pv + Vector2(bx_v, bx_v), Color(1.0, 0.3, 0.25), V.Q)
					V.linha(self, pv + Vector2(-bx_v, bx_v), pv + Vector2(bx_v, -bx_v), Color(1.0, 0.3, 0.25), V.Q)
				for k in 4:
					var ak: float = k * TAU / 4.0 + PI * 0.25
					var dk: float = 14.0 + 40.0 * u
					if fv > 0.2:
						V.quadro(self, pv.x + cos(ak) * dk - V.Q, pv.y + sin(ak) * dk + 30.0 * u * u - V.Q, V.Q * 3.0, V.Q * 3.0, V.CONT)
						V.quadro(self, pv.x + cos(ak) * dk, pv.y + sin(ak) * dk + 30.0 * u * u, V.Q, V.Q, Color(1.0, 0.85, 0.4))
			"chefe_chega":
				var pch: Vector2 = f["p"]
				var fc: float = 1.0 - u
				if u < 0.15:
					draw_rect(Rect2(-20, -20, 1320, 760), Color(1.0, 0.3, 0.25, 0.14 * (1.0 - u / 0.15)))
				V.aro(self, pch + Vector2(0, 30), 30.0 + 360.0 * u, (30.0 + 360.0 * u) * 0.3, Color(1.0, 0.5, 0.35), fc, 2.0)
				V.aro(self, pch + Vector2(0, 30), 20.0 + 240.0 * u, (20.0 + 240.0 * u) * 0.3, Color(1.0, 0.9, 0.7), fc, 1.0)
				_fumaca_px(pch + Vector2(0, 20), 90.0, 9, u, Color(0.5, 0.44, 0.42), 0.3)
			"fosso":
				var pf: Vector2 = f["p"]
				var ff: float = 1.0 - u
				V.elipse(self, pf + Vector2(0, 10), 30.0, 9.0, Color(0.1, 0.05, 0.04, 0.8 * minf(1.0, ff * 2.0)))
				V.aro(self, pf + Vector2(0, 10), 32.0, 10.0, Color(0.55, 0.4, 0.28), ff, 1.5)
				_fumaca_px(pf, 24.0, 5, u, Color(0.62, 0.5, 0.38), 0.7)
				for k in 3:
					V.brilho(self, pf + Vector2((k - 1) * 18.0, -34.0 - 10.0 * sin(u * 8.0 + k)), 4.0, Color(1.0, 0.86, 0.3), Color(0.35, 0.2, 0.02))
			"reforco":
				var pr: Vector2 = f["p"]
				var fr: float = 1.0 - u
				var rxr: float = 56.0 * (0.7 + 0.3 * minf(1.0, u * 5.0))
				V.elipse(self, pr, rxr, rxr * 1.2, Color(0.7, 0.88, 1.0, 0.16 * fr))
				V.aro(self, pr, rxr + V.Q, rxr * 1.2 + V.Q, V.CONT, fr, 2.0)
				V.aro(self, pr, rxr, rxr * 1.2, Color(0.7, 0.88, 1.0), fr, 1.0)
				V.brilho(self, pr + Vector2(-rxr * 0.55, -rxr * 0.7), 5.0, Color(1, 1, 1), Color(0.1, 0.2, 0.45))
			"luneta":
				var pl: Vector2 = f["p"]
				var fl: float = 1.0 - u
				var rl: float = 22.0 - 10.0 * minf(1.0, u * 4.0)
				V.aro(self, pl, rl + V.Q, rl + V.Q, V.CONT, fl, 2.0)
				V.aro(self, pl, rl, rl, Color(1.0, 0.92, 0.4), fl, 1.0)
				for k in 4:
					var dl := Vector2(cos(k * PI * 0.5), sin(k * PI * 0.5))
					V.quadro(self, pl.x + dl.x * (rl + V.Q) - V.Q * 0.5, pl.y + dl.y * (rl + V.Q) - V.Q * 0.5, V.Q * (1.0 + absf(dl.x) * 2.0), V.Q * (1.0 + absf(dl.y) * 2.0), Color(1.0, 0.95, 0.6))
				V.ponto(self, pl, Color(1, 1, 1))

## Bicho derrotado ("fantasma"): voa para trás num arco girando de 90 em 90 graus (BichoPx.queda), cai de barriga para cima e some.
## O chefe cambaleia, tomba de costas, levanta poeira e o adereço da cabeça sai rolando. Sem esticar: a escala é a da unidade.
const FANT_POUSO := 0.62         # fração da duração em que o bicho comum toca o chão
const FANT_POUSO_CHEFE := 0.5    # ...e o chefe
const ADERECO_COROA: Array = ["Y.Y.Y", "YYYYY", "yyryy"]
const ADERECO_CAPACETE: Array = [".YYY.", "YYYYY", "yyyyy"]

func _desenhar_fantasma(fan: Dictionary) -> void:
	var ug: Unidade = fan["u"]
	var uf: float = clampf(float(fan["t"]) / float(fan["dur"]), 0.0, 1.0)
	var esc_f: float = esc_tela(ug)
	var px_f: float = Desenho.GATO_K * esc_f
	var tp_f: int = Unidade.Tipo.GEMEO if ug.pequeno else ug.tipo
	var x_f: float = float(fan["x"])
	var y_f: float = float(fan["y"])
	var queda: float
	var alfa: float = 1.0
	if bool(fan.get("chefe", false)):
		var pc: float = FANT_POUSO_CHEFE
		if uf < 0.32:
			queda = 0.1   # cambaleia: olho apertado, balança de um lado para o outro em pixels inteiros
			x_f += (1.0 if int(uf * 18.0) % 2 == 0 else -1.0) * px_f
		elif uf < pc:
			queda = 0.3   # tomba: 90 graus
			y_f -= roundf(sin((uf - 0.32) / (pc - 0.32) * PI) * 3.0) * px_f
		else:
			queda = 0.8   # de costas no chão
		if uf > 0.85:
			alfa = 1.0 - (uf - 0.85) / 0.15
		if fan.has("rola"):
			_desenhar_adereco_rolando(ug, float(fan["x"]), float(fan["y"]), float(fan["rola"]), esc_f, alfa)
	else:
		var po: float = FANT_POUSO
		var ua: float = minf(uf / po, 1.0)
		y_f -= roundf(sin(ua * PI) * 26.0 / px_f) * px_f
		# arco: dor (golpe que matou) -> 90 graus -> de barriga para cima no ar -> deitado no chão
		queda = 0.1 if ua < 0.2 else (0.35 if ua < 0.5 else (0.6 if uf < po else 0.9))
		if uf > 0.8:
			alfa = 1.0 - (uf - 0.8) / 0.2
	Desenho.boneco(self, px_grade(Vector2(x_f, y_f)), esc_f, -1.0, 1, ug.pecas, 0.35, 0.0, false, 0.0, alfa, false, -1, 0.0, tp_f, false, ug.chefe, ug.familia, ug.elite, ug.chefe_tipo, ug.parte, false, 0, false, ug.gangue, 0.0, false, queda)

func _desenhar_adereco_rolando(ug: Unidade, x0: float, y0: float, t: float, esc: float, alfa: float) -> void:
	var ct: int = ug.chefe_tipo
	if not BichoPx.coroa_fixa(ct):
		return
	var rows: Array = ADERECO_CAPACETE if ct == 5 else ADERECO_COROA
	var d: float = 34.0 * (1.0 - exp(-t * 2.2))     # rola para trás e para
	var giro: int = int(d / 6.0) % 4
	var s: Dictionary = {"x": -2, "y": -3, "l": rows}
	if giro == 1:
		s = BichoPx.girar(s, 1, false)
	elif giro == 2:
		s = BichoPx.girar(s, 2, false)
	elif giro == 3:
		s = BichoPx.girar(BichoPx.girar(s, 2, false), 1, false)
	var cor_y: Color = Color("f6c61f")
	var pal: Dictionary = {"Y": Color(cor_y.r, cor_y.g, cor_y.b, alfa), "y": Color(0.72, 0.53, 0.06, alfa), "r": Color(0.85, 0.19, 0.24, alfa), "l": Color(0.72, 0.53, 0.06, alfa), "d": Color(cor_y.r, cor_y.g, cor_y.b, alfa), "o": Color(0.1, 0.07, 0.05, alfa)}
	var px: float = Desenho.GATO_K * esc
	Desenho._tr(self, px_grade(Vector2(x0 + d * esc * 1.5, y0 - 2.0 * px)), esc, 1.0, Vector2.ZERO, 0.0, Desenho.GATO_K)
	RoupaGato.sprite(self, s["x"], s["y"], s["l"], pal, 0.0)
	Desenho.resetar(self)

func _atualizar_visual(dt: float, delta_real: float) -> void:
	for lista in [sim.aliados, sim.inimigos]:
		for u in lista:
			var uu: Unidade = u
			if uu.vx < -9000.0:
				uu.vx = uu.x
				uu.vy = uu.y
			var k: float = 1.0 - exp(-delta_real * 22.0 * maxf(1.0, velocidade * 0.6))
			var vx0: float = uu.vx
			uu.vx += (uu.x - uu.vx) * k
			uu.vy += (uu.y - uu.vy) * k
			if uu.andando:
				if uu.estrutura or uu.cao:
					uu.anim += dt * 14.0 * uu.lento
				else:
					# o passo avança pela distância andada (|dx| / (passada x escala)): o pé fica parado no chão, o grandalhão
					# lento anda num ritmo pesado e o ladrão fugindo corre
					uu.anim += absf(uu.vx - vx0) * Desenho.anim_por_px_tela(uu.equipe, esc_tela(uu), uu.chefe_tipo if uu.chefe else -1, uu.fugindo and uu.tipo == Unidade.Tipo.LADRAO and not uu.chefe)
	for i in range(particulas.size() - 1, -1, -1):
		var p: Dictionary = particulas[i]
		p["vida"] -= dt
		if p["vida"] <= 0.0:
			particulas.remove_at(i)
			continue
		var vel: Vector2 = p["v"]
		vel.y += p["g"] * dt
		p["v"] = vel
		p["p"] = p["p"] + vel * dt
		if p.has("chao") and p["p"].y > float(p["chao"]) and vel.y > 0.0 and int(p["q"]) > 0:
			var pq2: Vector2 = p["p"]
			pq2.y = float(p["chao"])
			p["p"] = pq2
			p["v"] = Vector2(vel.x * 0.7, -vel.y * 0.42)
			p["vrot"] = float(p["vrot"]) * 0.5
			p["q"] = int(p["q"]) - 1
		if p["tipo"] == 2 or p["tipo"] == 4:
			p["rot"] += p["vrot"] * dt
	for i in range(fx.size() - 1, -1, -1):
		fx[i]["t"] += dt
		if fx[i]["t"] >= fx[i]["dur"]:
			fx.remove_at(i)
	for i in range(queimados.size() - 1, -1, -1):
		queimados[i]["t"] += dt
		if queimados[i]["t"] >= queimados[i]["dur"]:
			queimados.remove_at(i)
	for k in tranco.keys():
		var tv: Vector2 = tranco[k]
		tv.y -= dt
		if tv.y <= 0.0:
			tranco.erase(k)
		else:
			tranco[k] = tv
	# rastro dos projéteis: cada tipo de atirador deixa um rastro diferente
	if dt > 0.0:
		for pr in sim.projeteis:
			var d: Dictionary = pr
			var dono: Unidade = d["dono"]
			var ppos: Vector2 = Vector2(d["x"], d["y"] - TIRO_ALT * ESC)
			if dono == null:
				ppos += _desvio_boca(float(d["x"]))
				# rastro da torre: brasinha dourada que murcha no ar (antes eram estrelinhas girando, soltas pela tela)
				particulas.append({"p": ppos, "v": Vector2(randf_range(-8, 8), randf_range(-8, 8)), "vida": 0.22, "max": 0.22, "cor": Color(1.0, 0.82, 0.3, 0.7), "r": 3.0, "g": 0.0, "tipo": 0})
			elif dono.equipe == 0:
				particulas.append({"p": ppos, "v": Vector2.ZERO, "vida": 0.22, "max": 0.22, "cor": Color(0.7, 0.85, 1.0, 0.6), "r": 3.2, "g": 0.0, "tipo": 0})
			elif dono.chefe and dono.chefe_tipo == Fases.Chefe.CORUJA:
				# bolota do Esquilo: só um grãozinho marrom de vez em quando, atrás da noz (nunca por cima dela)
				if randf() < 0.35 and not _bolota_na_mao(d):
					var alvo_r: Unidade = d["alvo"]
					var sx_r: float = signf((Balanco.TORRE_X if alvo_r == null else alvo_r.x) - float(d["x"]))
					particulas.append({"p": ppos + Vector2(-sx_r * randf_range(14.0, 20.0), randf_range(-3.0, 3.0)), "v": Vector2(-sx_r * 10.0, randf_range(-6.0, 4.0)), "vida": 0.16, "max": 0.16, "cor": Color(0.55, 0.36, 0.18) if randf() < 0.5 else Color(0.78, 0.55, 0.28), "r": V.Q, "g": 120.0, "tipo": 5})
			else:
				particulas.append({"p": ppos, "v": Vector2(randf_range(-10, 10), randf_range(-14, 6)), "vida": 0.3, "max": 0.3, "cor": Color(1.0, 0.4, 0.25, 0.6), "r": 3.0, "g": 0.0, "tipo": 0})
	for i in range(her_fx.size() - 1, -1, -1):
		var hf: Dictionary = her_fx[i]
		hf["t"] = float(hf["t"]) + dt
		if float(hf["t"]) >= HER_FX_DUR:
			her_fx.remove_at(i)
	for i in range(numeros.size() - 1, -1, -1):
		var n: Dictionary = numeros[i]
		n["vida"] -= dt
		if n["vida"] <= 0.0:
			numeros.remove_at(i)
			continue
		n["idade"] = float(n.get("idade", 0.0)) + dt
		var vy_n: float = float(n.get("vy", -45.0))
		vy_n = minf(-45.0, vy_n + 900.0 * dt)
		n["vy"] = vy_n
		n["p"] = n["p"] + Vector2(0, vy_n * dt)
	for i in range(voando.size() - 1, -1, -1):
		var v: Dictionary = voando[i]
		if float(v["esp"]) > 0.0:
			# a peça salta do bicho, quica no chão e só então voa para a caixa
			v["esp"] = float(v["esp"]) - dt
			v["vy"] = float(v["vy"]) + 1500.0 * dt
			v["py"] = float(v["py"]) + float(v["vy"]) * dt
			var ini_q: Vector2 = v["ini"]
			ini_q.x += float(v["vx"]) * dt
			if float(v["py"]) > float(v["chao"]) and float(v["vy"]) > 0.0:
				v["py"] = float(v["chao"])
				if int(v["quicou"]) < 2:
					v["vy"] = -float(v["vy"]) * 0.5
					v["quicou"] = int(v["quicou"]) + 1
					if int(v["rar"]) > 0:
						_faisca(Vector2(ini_q.x, float(v["chao"])), Pecas.cor_rar(int(v["rar"])), 4, 90.0, 0.3, 2.6)
					else:
						_poeira(Vector2(ini_q.x, float(v["chao"]) + 6.0), 1.0, 2, 0.8)
				else:
					v["vy"] = 0.0
					v["esp"] = minf(float(v["esp"]), 0.06)
			ini_q.y = float(v["py"])
			v["ini"] = ini_q
			continue
		v["t"] += dt / 1.1
		if v["t"] >= 1.0:
			voando.remove_at(i)
			bau_n += 1
			bau_pulso = 1.0
			_faisca(BAU_POS + Vector2(0, -10), Desenho.DOURADO, 8 + 4 * int(v["rar"]), 160.0, 0.5, 2.8)
			_som(["drop", "drop_raro", "drop_raro", "drop_lendario", "drop_lendario"][clampi(int(v["rar"]), 0, 4)], 1.0, -3.0, int(v["rar"]) > 0)
	tremor = move_toward(tremor, 0.0, dt * 28.0)
	chefe_t = maxf(0.0, chefe_t - delta_real)
	bau_pulso = move_toward(bau_pulso, 0.0, dt * 3.0)
	torre_pulso = move_toward(torre_pulso, 0.0, dt * 5.0)
	_atualizar_torre(dt)
	position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (tremor if Menus.tremor_tela else 0.0)  # opção do menu

# ---------------------------------------------------------------- desenho
func _draw() -> void:
	if sim == null:
		return
	_cenario()
	if TORRE_FORTALEZA:
		TorrePx.desenhar(self, _base_f(), estado.tijolos, estado.tijolos_max(), estado.melhorias, estado.modulos, rel, golpe_torre, _op_torre())
	elif TORRE_EM_PIXEL:
		_torre_letras()
	else:
		Desenho.torre(self, TORRE_BASE, estado.tijolos, 1.0, torre_pulso * 0.6)
	var txt_bl: String = str(estado.tijolos)
	var tw_bl: float = UIComum.FONTE.get_string_size(txt_bl, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(22)).x
	IconesPoder.desenhar(self, IconesPoder.BLOCO, Vector2(90.0 - tw_bl * 0.5 - 16.0, 678.0), 2)   # ícone do bloco junto do contador
	Desenho.texto(self, txt_bl, Vector2(10, 686), 22, Color(1, 0.85, 0.7), 160.0, 3)
	if prep:
		_desenhar_prep_chao()
	_desenhar_repelente()
	_desenhar_canteiros()
	_desenhar_manteigas()
	_desenhar_domos()
	_desenhar_chamas()
	_desenhar_mudas()
	_desenhar_queimados()
	_desenhar_rastros()
	_desenhar_pedras()
	_desenhar_lacos()
	# unidades ordenadas por profundidade
	var todos: Array = _ordem_profundidade()
	# auras e sombras primeiro
	for u in todos:
		var uu: Unidade = u
		var alt_s: float = _salto(uu)
		var pe_u: Vector2 = Vector2(uu.vx, uu.vy)
		V.elipse(self, pe_u, 32.0 * esc_tela(uu) * (1.0 - minf(alt_s, 20.0) * 0.012), 32.0 * esc_tela(uu) * 0.3 * (1.0 - minf(alt_s, 20.0) * 0.012), Color(0, 0, 0, 0.22 * (1.0 - minf(alt_s, 20.0) * 0.01)))
		if uu.coroa_bonus > 0.0:
			var pc: float = 0.5 + 0.5 * sin(rel * 2.0)
			V.aro(self, pe_u, Balanco.COROA_RAIO, Balanco.COROA_RAIO * 0.3, Color(1.0, 0.82, 0.2), 0.5 + 0.3 * pc, 1.0)
		if uu.aura_raio > 0.0:
			var pulso: float = 0.5 + 0.5 * sin(rel * 3.0)
			V.aro(self, pe_u, uu.aura_raio, uu.aura_raio * 0.3, Color(0.7, 0.3, 0.9), 0.55 + 0.3 * pulso, 1.5)
		_anel_poder_chao(uu)
	for cd in caidos:
		var tq: float = float(cd.get("t", 1.0))
		if tq < 0.4:
			# nocaute: gira no ar, cai de lado; depois dorme
			var uq: float = tq / 0.4
			var giro_q: float = cos(uq * TAU * 1.5)
			var dir_q: float = signf(giro_q) * maxf(absf(giro_q), 0.18)
			var alt_q: float = sin(uq * PI) * 34.0
			Desenho.boneco(self, px_grade(Vector2(cd["x"], cd["y"] - alt_q)), ESC_PX, dir_q, 0, cd["pecas"], 0.6 * (1.0 - uq), 0.0, false, 0.0, 1.0, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, cd["var"], false)
			continue
		var pouso: float = clampf((tq - 0.4) / 0.18, 0.0, 1.0)
		var sq_q: float = 1.0 - 0.14 * sin(pouso * PI)
		Desenho.boneco(self, px_grade(Vector2(cd["x"], cd["y"])), ESC_PX * sq_q, 1.0 / sq_q, 0, cd["pecas"], 0.0, 0.0, false, 0.0, 0.85, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, cd["var"], true)
		# um "z" por gato, subindo devagar; a fase vem da posição, então gatos caídos lado a lado não sobem
		# juntos. Nasce pequeno, cresce no meio da subida e some (sem alfa); contorno só em volta dos traços
		var wz: float = fposmod(rel * 0.45 + fposmod(float(cd["x"]) * 0.0137, 1.0), 1.0)
		var vz: float = sin(wz * PI)
		if vz > 0.25:
			V.zzz(self, Vector2(cd["x"] + 30.0 + wz * 10.0, cd["y"] - 66.0 - wz * 26.0), 2.0 if vz > 0.7 else 1.0, Color(0.8, 0.9, 1.0))
	for fa in fantasmas:
		_desenhar_fantasma(fa)
	var ico_max: int = 3 if todos.size() > 24 else 4   # luta pesada: menos ícones por unidade
	for u in todos:
		var uu2: Unidade = u
		var dir: float = 1.0 if uu2.equipe == 0 else -1.0
		var pos: Vector2 = Vector2(uu2.vx, uu2.vy)
		var esc_u: float = esc_tela(uu2)
		var px_u: float = Desenho.GATO_K * esc_u   # um pixel do sprite na tela: os deslocamentos andam em pixels inteiros
		if uu2.golpe > 0.0 and not uu2.distancia:
			# bote: o corpo já está à frente no passo do dano (contato) e volta desacelerando (BichoPx.curva_golpe)
			pos.x += dir * roundf(BichoPx.curva_golpe(uu2.golpe) * 6.0 / px_u) * px_u
		var dor_u: bool = false
		if tranco.has(uu2):
			# tranco: recuo curto no sentido do golpe recebido; nos primeiros ~0,12 s, a pose de dor
			var trc: Vector2 = tranco[uu2]
			pos.x += trc.x * roundf(sin(clampf(trc.y / 0.16, 0.0, 1.0) * PI) * 7.0 / px_u) * px_u
		dor_u = _pose_dor(uu2)
		var tp: int = Unidade.Tipo.GEMEO if uu2.pequeno else uu2.tipo
		# preparo: na janela antes do golpe (recarga quase no fim) o boneco arma o golpe (cabeça recua, agacha, corda puxada)
		var prep_u: float = _pose_preparo(uu2)
		if prep_u > 0.0 and not uu2.distancia:
			pos.x -= dir * roundf(prep_u * 4.0 / px_u) * px_u   # recua um pixel da grade antes do bote
		pos.y -= _salto(uu2)
		# sem esmaga-e-estica nem respiração por escala: escala fora do inteiro quebrava a grade de pixels e dobrava a respiração de
		# 1 px que cada bicho já tem; o golpe levado virou a pose de dor
		var sx_u: float = 1.0
		var sy_u: float = 1.0
		var fl_u: float = uu2.flash
		if ju.has(uu2):
			var jj: Dictionary = ju[uu2]
			if int(jj["clar"]) > 0:
				fl_u = 1.0
			if float(jj["antecip"]) > 0.0:
				fl_u = maxf(fl_u, float(jj["antecip"]) / (ANTECIP_PODER * 1.5) * 0.8)
				sx_u -= 0.06
				sy_u += 0.1
		var esc_d: float = esc_u * sy_u
		var dir_d: float = dir * sx_u / sy_u
		if uu2.estrutura:
			_desenhar_estrutura(uu2, pos, fl_u, dir_d)
		elif uu2.cao:
			# cão de guarda da Casinha: sprite próprio, do tamanho de um bicho comum (a escala da unidade é a do desenho antigo do chefe)
			CaoGuarda.desenhar(self, px_grade(pos), ESC_PX * sy_u, dir_d, uu2.anim, uu2.andando, uu2.golpe, fl_u)
		else:
			Desenho.noir = uu2.noir_t > 0.0   # Modo Noir: gato e roupa em preto e branco
			# Schrödinger: caixa fechada e cópia falsa vêm da unidade (ChefeGangue lê durante o desenho)
			ChefeGangue.schro_caixa = uu2.caixa_t
			ChefeGangue.schro_ilusao = uu2.ilusao
			Desenho.boneco(self, px_grade(pos), esc_d, dir_d, (1 if uu2.capturado else uu2.equipe), (uu2.pecas_visuais if uu2.clone else uu2.pecas), fl_u, uu2.anim, uu2.andando, uu2.golpe, (0.6 if uu2.clone else (0.4 if uu2.oculto_t > 0.0 else 1.0)), false, -1, uu2.furia, tp, uu2.pequeno or uu2.fugindo, uu2.chefe, uu2.familia, uu2.elite, uu2.chefe_tipo, uu2.parte, (uu2.parado or uu2.morto), (estado.bonecos.find(uu2.dono.boneco if uu2.dono != null else uu2.boneco) if uu2.equipe == 0 else 0), false, uu2.gangue, prep_u, dor_u)
			ChefeGangue.schro_caixa = 0.0
			ChefeGangue.schro_ilusao = false
			Desenho.noir = false
		_estados(uu2, pos, esc_u, dir)
		_icone_poder_gato(uu2, pos, esc_u)
		if uu2.barreira_int > 0.0 and uu2.barreira_cd <= 0.0:
			var bc: Vector2 = pos + Vector2(0, -CORPO_MEIO * esc_u)
			var brx: float = (CORPO_LARG + 2.0) * esc_u
			var bry: float = (CORPO_MEIO + 4.0) * esc_u
			V.aro(self, bc, brx, bry, Color(0.6, 0.85, 1.0), 0.75, 1.0)
		if uu2.disfarcado:
			var dc: Vector2 = pos + Vector2(0, -CORPO_MEIO * esc_u)
			V.aro(self, dc, (CORPO_LARG + 4.0) * esc_u, (CORPO_MEIO + 6.0) * esc_u, Color(1.0, 0.9, 0.35), 0.55 + 0.2 * sin(rel * 4.0), 1.0)
		if uu2.cura_alvo != null:
			var al: Unidade = uu2.cura_alvo
			var pa: Vector2 = pos + Vector2(0, -40 * ESC)
			var pb: Vector2 = Vector2(al.vx, al.vy - 40 * ESC)
			for k in 4:
				var wc: float = fposmod(rel * 1.6 + k * 0.25, 1.0)
				V.cruz(self, pa.lerp(pb, wc), 3.0, Color(0.38, 0.95, 0.5), Color(0.04, 0.3, 0.18))
			V.disco_c(self, pb, 5.0 + 2.0 * sin(rel * 10.0), Color(0.38, 0.95, 0.5), Color(0.04, 0.3, 0.18))
			# cruzinha de pixel subindo sobre quem recebe a cura (no lugar do "+" de texto)
			var wcr: float = fposmod(rel * 2.0, 1.0)
			if wcr < 0.85:
				V.cruz(self, pb + Vector2(0, -22.0 - 9.0 * wcr), 6.0 if wcr < 0.5 else 3.0, Color(0.5, 1.0, 0.6), Color(0.04, 0.3, 0.18))
		if uu2.vida < uu2.vida_max - 0.01 or uu2.equipe == 0:
			# barra fina: contorno escuro de 1px, fundo e cor pela fração (gato: verde->amarelo->vermelho)
			var w: float = 70.0 if uu2.chefe else 44.0
			# em pixel: uma faixa de 1 quadradinho na grade, contorno escuro de 1 e a vida em quadradinhos inteiros
			var nq_b: int = int(w / V.Q)
			var bx: float = V.sn(pos.x) - float(nq_b / 2) * V.Q
			var by: float = V.sn(pos.y - (CORPO_ALT + 6.0) * esc_u)
			var frac: float = clampf(uu2.vida / uu2.vida_max, 0.0, 1.0)
			var cheio: int = clampi(ceili(frac * nq_b - 0.01), 1 if frac > 0.0 else 0, nq_b)
			draw_rect(Rect2(bx - V.Q, by - V.Q, (nq_b + 2) * V.Q, V.Q * 3.0), V.CONT)
			var cor_b: Color = Color(0.95, 0.3, 0.28)
			if uu2.equipe == 0:
				cor_b = Color(0.4, 0.92, 0.45) if frac > 0.55 else (Color(0.98, 0.85, 0.3) if frac > 0.28 else Color(0.98, 0.35, 0.3))
			if cheio < nq_b:
				draw_rect(Rect2(bx + cheio * V.Q, by, (nq_b - cheio) * V.Q, V.Q), V.tom(cor_b, 0.3))
			if cheio > 0:
				draw_rect(Rect2(bx, by, cheio * V.Q, V.Q), cor_b)
				draw_rect(Rect2(bx, by, V.Q, V.Q), V.tom(cor_b, 1.45))
		var n_ico: int = _fila_estados(uu2, pos.x, pos.y - (CORPO_ALT + 6.0) * esc_u, ico_max)
		if uu2.lider and uu2.vivo:
			_coroa_lider(Vector2(V.sn(pos.x), V.sn(pos.y - (CORPO_ALT + 6.0) * esc_u - 6.0 - (22.0 if n_ico > 0 else 0.0))))
		if uu2.equipe == 1 and sim.prioritario(uu2):
			_mira(pos + Vector2(0, -(CORPO_ALT + 22.0) * esc_u - (22.0 if n_ico > 0 else 0.0)), 9.0, 1.0)
	_desenhar_avisos()
	# projéteis: torre (estrela dourada grande), gatos (cometa azulado), bichos (losango vermelho), Esquilo Acrobata (bolota)
	for pr in sim.projeteis:
		var d: Dictionary = pr
		var alvo: Unidade = d["alvo"]
		var dono: Unidade = d["dono"]
		var altura: float = TIRO_ALT * ESC
		var pp: Vector2 = Vector2(d["x"], d["y"] - altura)
		var sx: float = signf(Balanco.TORRE_X - pp.x if alvo == null else alvo.x - pp.x)
		if dono == null:
			pp += _desvio_boca(float(d["x"]))   # o tiro da torre nasce na boca do canhão
		if dono != null and _bolota_na_mao(d):
			continue
		V.elipse(self, pp + Vector2(0, altura - 2), 6.0, 2.0, Color(0, 0, 0, 0.25))
		if dono == null:
			for tr in 3:
				V.quadro(self, pp.x - sx * (10.0 + tr * 9.0), pp.y - 2.0, 6.0 - tr * 1.5, 6.0 - tr * 1.5, Color(1.0, 0.82, 0.3))
			V.disco_c(self, pp, 7.0, Color(1.0, 0.84, 0.28), Color(0.4, 0.22, 0.04))
			V.disco(self, pp + Vector2(-2, -2), 3.0, Color(1, 1, 0.85))
		elif dono.equipe == 0:
			for tr in 3:
				V.quadro(self, pp.x - sx * (8.0 + tr * 7.0), pp.y - 1.5, 6.0 - tr * 1.5, 3.0, Color(0.7, 0.88, 1.0))
			V.disco_c(self, pp, 4.0, Color(0.78, 0.92, 1.0), Color(0.1, 0.2, 0.45))
			V.disco(self, pp + Vector2(-1, -1), 2.0, Color(1, 1, 1))
		elif dono.chefe and dono.chefe_tipo == Fases.Chefe.CORUJA:
			# bolota do Esquilo Acrobata: noz com chapéu, girando no ar em 4 quartos de volta (pelo tempo). Enquanto o
			# sprite ainda mostra a noz erguida atrás da cabeça (fase 1 do golpe), a do voo não aparece: nada de bolota dupla.
			# (a escondida já saiu acima, antes da sombra). Rola no sentido do voo: para a esquerda, anti-horário.
			_bolota(pp, posmod(int(rel * 14.0) * (1 if sx > 0.0 else -1), 4))
		elif d.get("disco", false):
			# disco de luz da Tropa do Grid: ciano com miolo claro, piscando como se girasse
			for tr in 3:
				V.quadro(self, pp.x - sx * (8.0 + tr * 7.0), pp.y - 1.5, 6.0 - tr * 1.5, 3.0, Color(0.3, 0.9, 1.0))
			V.disco_c(self, pp, 6.0, Color(0.3, 0.9, 1.0), Color(0.04, 0.2, 0.4))
			V.quadro(self, pp.x - V.Q, pp.y - V.Q * (1.0 if sin(rel * 30.0) > 0.0 else 3.0), V.Q * 2.0, V.Q * 2.0, Color(0.9, 1.0, 1.0))
		else:
			for tr in 3:
				V.quadro(self, pp.x - sx * (8.0 + tr * 7.0), pp.y - 1.5, 6.0 - tr * 1.5, 3.0, Color(1.0, 0.45, 0.25))
			V.disco_c(self, pp, 4.0, Color(1.0, 0.45, 0.3), Color(0.35, 0.04, 0.04))
			V.disco(self, pp + Vector2(-1, -1), 2.0, Color(1.0, 0.9, 0.7))
	# poderes das fantasias
	for f in fx:
		_desenhar_fx(f)
	_desenhar_zonas()
	# partículas
	for pa in particulas:
		var p: Dictionary = pa
		var a: float = clampf(p["vida"] / p["max"], 0.0, 1.0)
		var c: Color = p["cor"]
		c.a *= a
		if p["tipo"] == 2:
			# giro em quartos de volta e posição na grade: o bloco de pixel nunca fica torto nem em meio pixel
			var giro_b: float = roundf(float(p["rot"]) / (PI * 0.5)) * (PI * 0.5)
			draw_set_transform(Vector2(V.sn(p["p"].x), V.sn(p["p"].y)), giro_b, Vector2.ONE)
			Desenho.bloco(self, Rect2(-20, -10, 40, 20), p["cor"], Desenho.letra_tijolo(int(p["idx"])), a)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		elif p["tipo"] == 1:
			# fumaça/clarão: bolha de pixel que incha e some por encolhimento (sem alfa sobre alfa)
			var rb: float = p["r"] * (2.2 - a)
			if rb >= 4.0:
				if p["r"] >= 14.0 and p["cor"].a < 0.7:
					V.disco(self, p["p"], rb * a * 1.1 + V.Q, Color(c.r, c.g, c.b, minf(0.55, p["cor"].a)))
				else:
					V.bolha(self, p["p"], rb * (0.55 + 0.45 * a), Color(c.r, c.g, c.b, 1.0))
		elif p["tipo"] == 3:
			# faísca direcional: quadradinhos alinhados ao movimento
			var vv: Vector2 = p["v"]
			var dd: Vector2 = vv.normalized()
			var s0: float = V.Q if p["r"] < 2.4 else V.Q * 2.0
			V.quadro(self, p["p"].x - V.Q, p["p"].y - V.Q, s0 + V.Q * 2.0, s0 + V.Q * 2.0, V.CONT)
			V.quadro(self, p["p"].x, p["p"].y, s0, s0, Color(c.r, c.g, c.b, 1.0))
			if a > 0.4:
				V.quadro(self, p["p"].x - dd.x * V.Q * 2.0, p["p"].y - dd.y * V.Q * 2.0, V.Q, V.Q, V.tom(Color(c.r, c.g, c.b, 1.0), 0.7))
		elif p["tipo"] == 4:
			V.brilho(self, p["p"], maxf(V.Q, p["r"] * (0.5 + 0.5 * a)), Color(c.r, c.g, c.b, 1.0))
		elif p["tipo"] == 5:
			# grãozinho: um quadradinho só, sem contorno (farelo da bolota do Esquilo)
			V.quadro(self, p["p"].x, p["p"].y, V.Q, V.Q, Color(c.r, c.g, c.b, 1.0))
		else:
			# fagulha: quadradinho com contorno que encolhe
			var rf: float = maxf(V.Q, p["r"] * (0.4 + a * 0.6))
			V.quadro(self, p["p"].x - V.Q, p["p"].y - V.Q, rf + V.Q * 2.0, rf + V.Q * 2.0, V.CONT)
			V.quadro(self, p["p"].x, p["p"].y, rf, rf, Color(c.r, c.g, c.b, 1.0))
	_desenhar_tfx()
	# peças voando para o baú: rastro, brilho e anel na cor da raridade
	if not voando.is_empty():
		var bp: float = 0.5 + 0.5 * sin(rel * 8.0)
		V.aro(self, BAU_POS + Vector2(0, -10), 40.0 + 4.0 * bp, 30.0 + 3.0 * bp, Color(1.0, 0.9, 0.4), 0.6 + 0.4 * bp, 1.0)
	for vo in voando:
		var v: Dictionary = vo
		var t: float = v["t"]
		var e: float = t * t * (3.0 - 2.0 * t)
		var ini: Vector2 = v["ini"]
		var rar_v: int = int(v.get("rar", 0))
		var cor_r: Color = Pecas.cor_rar(rar_v) if rar_v > 0 else Color(1.0, 0.9, 0.4)
		for k in range(5, 0, -1):
			var tt: float = maxf(t - k * 0.035, 0.0)
			var ee: float = tt * tt * (3.0 - 2.0 * tt)
			var pt: Vector2 = ini.lerp(BAU_POS + Vector2(0, -16), ee) + Vector2(0, -130.0 * sin(PI * tt))
			var sk: float = (9.0 - k * 1.4)
			V.quadro(self, pt.x - sk * 0.5, pt.y - sk * 0.5, sk, sk, V.tom(cor_r, 1.0 - k * 0.1))
		var pos2: Vector2 = ini.lerp(BAU_POS + Vector2(0, -16), e) + Vector2(0, -130.0 * sin(PI * t))
		V.aro(self, pos2, 24.0 + 2.0 * rar_v, 24.0 + 2.0 * rar_v, V.CONT, 1.0, 2.0)
		V.aro(self, pos2, 24.0 + 2.0 * rar_v, 24.0 + 2.0 * rar_v, cor_r, 1.0, 1.0 + 0.4 * minf(rar_v, 3))
		if rar_v >= 3:
			for k in rar_v - 1:
				var ak: float = rel * 3.0 + k * TAU / (rar_v - 1)
				V.brilho(self, pos2 + Vector2(cos(ak), sin(ak)) * (28.0 + 2.0 * rar_v), 3.0 + 0.5 * rar_v, V.tom(cor_r, 1.3), V.CONT)
		var mk_v: int = v["marca"]
		var marcas_v: Array = [mk_v] if mk_v >= 0 else []
		Desenho.icone(self, v["tipo"], pos2, 34.0 * (1.0 + 0.2 * sin(PI * t)), 0, 0.0, 0.0, marcas_v, rar_v)
	for hf in her_fx:
		_selo_heranca_gato(hf)
	# números (tamanho proporcional ao dano; "ct" é a espessura do contorno)
	for nu in numeros:
		var n: Dictionary = nu
		var a2: float = clampf(n["vida"] / 0.5, 0.0, 1.0)
		var c2: Color = n["cor"]
		c2.a = a2
		var p2: Vector2 = n["p"]
		var lg: float = n["larg"]
		# sobressalto de escala: nasce grande e assenta; o nome do poder cresce de pequeno e passa do ponto
		var id_n: float = float(n.get("idade", 0.0))
		var esc_n: float = 1.0 + 0.6 * exp(-id_n * 9.0) * cos(id_n * 22.0)
		if n.get("placa", false):
			var q_n: float = clampf(id_n / 0.2, 0.0, 1.0)
			esc_n = 0.3 + 0.7 * q_n + 0.28 * sin(q_n * PI) 
		var p2_real: Vector2 = p2
		draw_set_transform(p2_real, 0.0, Vector2(esc_n, esc_n))
		p2 = Vector2.ZERO
		var her_n: int = int(n.get("her", -1))
		var selo_c: Vector2 = Vector2.ZERO
		if n.get("placa", false):
			# placa escura semitransparente atrás do nome do poder (legível sobre qualquer parede)
			var tw: float = UIComum.FONTE.get_string_size(n["txt"], HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(int(n["tam"]))).x + 20.0
			if her_n >= 0:
				tw += HER_SELO + V.Q   # herança: espaço para o selo à esquerda do nome
			var pl: Rect2 = Rect2(p2.x - tw * 0.5, p2.y - float(n["tam"]) - 2.0, tw, float(n["tam"]) + 12.0)
			draw_rect(pl.grow(2.0), Color(0, 0, 0, 0.35 * a2))
			draw_rect(pl, Color(0.04, 0.03, 0.08, 0.72 * a2))
			draw_rect(Rect2(pl.position, Vector2(pl.size.x, 2.0)), Color(c2.r, c2.g, c2.b, 0.7 * a2))
			if her_n >= 0:
				p2.x += (HER_SELO + V.Q) * 0.5
				selo_c = p2_real + Vector2(pl.position.x + V.Q + HER_SELO * 0.5, pl.get_center().y) * esc_n
		_texto_c(n["txt"], p2 - Vector2(lg * 0.5, 0), n["tam"], c2, lg, int(n.get("ct", 4)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if her_n >= 0 and a2 > 0.5 and id_n >= 0.2:
			# selo fora da escala do pulo da placa: entra quando ela assenta, fica inteiro na grade da luta e some de uma vez no fim (sem alfa)
			_selo_heranca(selo_c, her_n, false)
	# vinhetas: poder (escurece as bordas), torre em perigo (vermelho que pulsa)
	_vinheta(Color(0.02, 0.0, 0.05), 0.5 * vinheta_poder * vinheta_poder, 170.0)
	var frac_p: float = float(estado.tijolos) / maxf(1.0, float(estado.tijolos_max()))
	if frac_p < 0.3 and estado.tijolos > 0 and not sim.terminada:
		_vinheta(Color(0.9, 0.05, 0.05), 0.2 + 0.2 * (0.5 + 0.5 * sin(rel * 6.0)), 150.0)
	_bau_desenho()
	_hud()
	if prep:
		_desenhar_prep()
	else:
		_barra_poderes()
	_desenhar_foco()
	_desenhar_faixas()

## Letras dos blocos da torre em resolução cheia, por cima dos blocos de pixel do viewport animado.
func _torre_letras() -> void:
	var base: Vector2 = torre_base_grade()
	for i in estado.tijolos:
		var rb: Rect2 = Desenho.rect_tijolo(i, base, 1.0)
		var cor: Color = Desenho.b(Desenho.cor_tijolo(i), torre_pulso * 0.6)
		var ce: Vector2 = rb.get_center()
		var rr: float = rb.size.y * 0.33
		var tam: int = maxi(8, int(rb.size.y * 0.6))
		Desenho.texto(self, Desenho.letra_tijolo(i), Vector2(ce.x - rr, ce.y + tam * 0.35), tam, cor.darkened(0.4), rr * 2.0)

func _chamas(pos: Vector2, esc_u: float) -> void:
	for i in 5:
		var fxx: float = (i - 2.0) * 13.0 * esc_u
		V.chama(self, pos + Vector2(fxx, -(24.0 + (i % 2) * 12.0 - absf(i - 2.0) * 3.0) * esc_u), 12.0, (16.0 + 8.0 * sin(rel * 14.0 + i * 1.7)) * esc_u, rel + i)

# ---------------------------------------------------------------- cenários
## Fundo estático (parede, móveis, chão): desenhado uma única vez num nó filho
## (show_behind_parent) que não redesenha a cada quadro. Só o que se mexe
## (cortina, chama, pêndulo, gota, poeira) é desenhado por Campo._animado().
## Base dos nós de cenário: tudo é desenhado numa grade de 320x180 (1 pixel = 4 px de tela
## do jogo). Estes atalhos arredondam espessuras e raios para que nada fique mais fino
## que 1 pixel de cenário (linhas finas somem na redução).
class Pixel extends Node2D:
	const G := 4.0
	func _w(w: float) -> float:
		return G if w < 6.0 else (2.0 * G if w < 10.0 else roundf(w / G) * G)
	func _ln(a: Vector2, b: Vector2, c: Color, w: float = 1.0) -> void:
		draw_line(a, b, c, _w(w))
	func _pl(pts: PackedVector2Array, c: Color, w: float = 1.0) -> void:
		draw_polyline(pts, c, _w(w))
	func _ar(ctr: Vector2, r: float, a0: float, a1: float, n: int, c: Color, w: float = 1.0) -> void:
		draw_arc(ctr, r, a0, a1, n, c, _w(w))
	func _ci(p: Vector2, r: float, c: Color) -> void:
		draw_circle(p, maxf(r, 3.0), c)
	func _contorno(r: Rect2, c: Color, w: float = 1.0) -> void:
		var e: float = _w(w)
		draw_rect(Rect2(r.position, Vector2(r.size.x, e)), c)
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - e), Vector2(r.size.x, e)), c)
		draw_rect(Rect2(r.position + Vector2(0, e), Vector2(e, r.size.y - 2.0 * e)), c)
		draw_rect(Rect2(r.position + Vector2(r.size.x - e, e), Vector2(e, r.size.y - 2.0 * e)), c)

	## Letras de 5x5 pixels de cenário, para letreiros de néon (só as do "FLIPERAMA").
	const GLIFOS := {
		"F": ["11111", "10000", "11110", "10000", "10000"],
		"L": ["10000", "10000", "10000", "10000", "11111"],
		"I": ["11111", "00100", "00100", "00100", "11111"],
		"P": ["11110", "10001", "11110", "10000", "10000"],
		"E": ["11111", "10000", "11110", "10000", "11111"],
		"R": ["11110", "10001", "11110", "10010", "10001"],
		"A": ["01110", "10001", "11111", "10001", "10001"],
		"M": ["10001", "11011", "10101", "10001", "10001"],
	}

	## Letreiro: cada célula do glifo vira um quadrado de `esc` px de tela; `x` é a esquerda, `y` o topo.
	func _letras(x: float, y: float, txt: String, esc: float, cor: Color, so_letra: int = -1) -> void:
		var cx: float = x
		var n: int = 0
		for ch in txt:
			if so_letra < 0 or so_letra == n:
				var g: Array = GLIFOS[ch]
				for r in 5:
					var linha: String = g[r]
					for c in 5:
						if linha[c] == "1":
							draw_rect(Rect2(cx + c * esc, y + r * esc, esc, esc), cor)
			cx += esc * 6.0
			n += 1

	## Peixe de néon de lado (contorno): corpo, cauda e olho. `c` é o centro do corpo.
	func _neon_peixe(c: Vector2, cor: Color, w: float = 2.0) -> void:
		_pl(PackedVector2Array([c + Vector2(-30, 0), c + Vector2(-14, -14), c + Vector2(10, -14), c + Vector2(24, 0), c + Vector2(10, 14), c + Vector2(-14, 14), c + Vector2(-30, 0)]), cor, w)
		_pl(PackedVector2Array([c + Vector2(24, 0), c + Vector2(40, -14), c + Vector2(40, 14), c + Vector2(24, 0)]), cor, w)
		_ci(c + Vector2(-16, -4), 3.0, cor)

	## Fantasminha de néon (contorno): cabeça redonda, saia ondulada e dois olhos.
	func _neon_fantasma(c: Vector2, cor: Color, w: float = 2.0) -> void:
		var pts := PackedVector2Array()
		for i in 9:
			var a: float = PI + PI * i / 8.0
			pts.append(c + Vector2(cos(a) * 18.0, sin(a) * 18.0))
		pts.append(c + Vector2(18, 20))
		pts.append(c + Vector2(9, 12))
		pts.append(c + Vector2(0, 20))
		pts.append(c + Vector2(-9, 12))
		pts.append(c + Vector2(-18, 20))
		pts.append(c + Vector2(-18, 0))
		_pl(pts, cor, w)
		_ci(c + Vector2(-7, -3), 3.0, cor)
		_ci(c + Vector2(7, -3), 3.0, cor)


class Fundo extends Pixel:
	const YS: Array[float] = [447.0, 466.0, 490.0, 520.0, 556.0, 600.0, 652.0, 712.0]
	## Objetos de primeiro plano por cômodo (18 colunas x até 8 linhas, quadradinhos de G): k corpo, r borda acesa,
	## m meio-tom. Ficam no canto de baixo à direita, fora da faixa da barra de poderes.
	const SIL_FRENTE: Dictionary = {
		1: [  # chinelo esquecido
			"..................", "........rrrr......", ".......rkkkkr.....", "......rkk..kkr....",
			"..rrrrkkrrrrkkrr..", ".rkkkkkkkkkkkkkkr.", ".kmmkkkkkkkkkkkkk.", "..kkkkkkkkkkkkkk..",
		],
		2: [  # pé torneado de poltrona com a barra da saia
			"rrrrrrrrrrrrrrrr..", "kkkkkkkkkkkkkkkk..", "kmkmkmkmkmkmkmkk..", "...........rkr....",
			"..........rkkkr...", "...........kmk....", "..........rkkkr...", "...........kkk....",
		],
		3: [  # pé de cadeira com a travessa
			"rrrrrrrrrrrrrr....", "kkkkkkkkkkkkkk....", ".rk.........rk....", ".kk.........kk....",
			".kkrrrrrrrrrkk....", ".kkkkkkkkkkkkk....", ".kk.........kk....", ".kk.........kk....",
		],
		4: [  # caixa de papelão fechada com fita
			"..rrrrrrrrrrrrr...", "..kkkkkkmkkkkkk...", "..kkkkkkmkkkkkk...", "..kkkkkkmkkkkkk...",
			"..kmkkkkmkkkkkk...", "..kkkkkkmkkkkkk...", "..kkkkkkkkkkkkk...", "..kkkkkkkkkkkkk...",
		],
		5: [  # balde com alça
			"....rrrrrrrr......", "...r........r.....", "..rrrrrrrrrrrr....", "..kkkkkkkkkkkk....",
			"..kmkkkkkkkkkk....", "...kkkkkkkkkk.....", "...kmmmmmmmmk.....", "...kkkkkkkkkk.....",
		],
		6: [  # tufos de mato alto
			"..r.......r.......", "..k..r....k...r...", ".rk.rk...rk..rk...", ".kk.kk.r.kk.rkk.r.",
			"rkkrkkrk.kkrkkkrk.", "kkkkkkkkrkkkkkkkk.", "kkkkkkkkkkkkkkkkk.", "kkkkkkkkkkkkkkkkk.",
		],
		7: [  # pneu deitado de pé, encostado
			"....rrrrrrrr......", "..rrkkkkkkkkrr....", ".rkkkkmmmmkkkkr...", ".kkkkm....mkkkk...",
			".kkkkm....mkkkk...", ".kkkkkmmmmkkkkk...", "..kkkkkkkkkkkk....", "....kkkkkkkk......",
		],
		8: [  # boca de ventilação com chapéu
			"....rrrrrrrrrr....", "....kkkkkkkkkk....", "......rkkkkr......", "......kmmmmk......",
			"......kkkkkk......", "......kmmmmk......", "....rrkkkkkkrr....", "....kkkkkkkkkk....",
		],
		9: [  # cone de trânsito
			"........rr........", ".......rkkr.......", ".......kmmk.......", "......rkkkkr......",
			"......kkkkkk......", ".....kmmmmmmk.....", "...rrkkkkkkkkrr...", "...kkkkkkkkkkkk...",
		],
		10: [  # pedra com raiz por cima
			"...r..............", "...kr.....rrr.....", "....kr..rrkkkrr...", ".....krrkkkkkkkr..",
			"....rkkkkkkkmkkkr.", "...rkkkmkkkkkkkkk.", "..rkkkkkkkkkkkkkk.", "..kkkkkkkkkkkkkkk.",
		],
		11: [  # caixote de peixe com o rabo para fora
			"..............r...", "..rrrrrrrrrrrrkr..", "..kkkkkkkkkkkkkk..", "..kmmmmmmmmmmmmk..",
			"..kkkkkkkkkkkkkk..", "..kmmmmmmmmmmmmk..", "..kkkkkkkkkkkkkk..", "..kk..........kk..",
		],
		12: [  # pneu encostado
			"....rrrrrrrr......", "..rrkkkkkkkkrr....", ".rkkkkmmmmkkkkr...", ".kkkkm....mkkkk...",
			".kkkkm....mkkkk...", ".kkkkkmmmmkkkkk...", "..kkkkkkkkkkkk....", "....kkkkkkkk......",
		],
		13: [  # lata de lixo com tampa
			"......rrrr........", "...rrrkkkkrrr.....", "..rkkkkkkkkkkr....", "...kkkkkkkkkk.....",
			"...kmkkmkkmkk.....", "...kmkkmkkmkk.....", "...kmkkmkkmkk.....", "...kkkkkkkkkk.....",
		],
		14: [  # pedaço de coluna tombado
			"..................", "..................", ".rrrrrrrrrrrrrr...", "rkkkkkkkkkkkkkkr..",
			"kmkkkkkkkkkkkkkk..", "kmmmmmmmmmmmmmmk..", "kmkkkkkkkkkkkkkk..", ".kkkkkkkkkkkkkk...",
		],
		15: [  # duto de ventilação com chapéu
			"....rrrrrrrrrr....", "....kkkkkkkkkk....", "......rkkkkr......", "......kmmmmk......",
			"......kkkkkk......", "......kmmmmk......", "....rrkkkkkkrr....", "....kkkkkkkkkk....",
		],
	}

	## Desenha um bitmap de texto com quadradinhos de G; `o` é o canto de cima à esquerda.
	func _bitmap(o: Vector2, linhas: Array, pal: Dictionary) -> void:
		for y in linhas.size():
			var ln: String = linhas[y]
			var x: int = 0
			while x < ln.length():
				var ch: String = ln[x]
				var x1: int = x + 1
				while x1 < ln.length() and ln[x1] == ch:
					x1 += 1
				if pal.has(ch):
					draw_rect(Rect2(o.x + x * G, o.y + y * G, (x1 - x) * G, G), pal[ch])
				x = x1

	var fase: int = 1

	func _draw() -> void:
		_cena_base()

	func _cena_base() -> void:
		match fase:
			2:
				_sala()
			3:
				_cozinha()
			4:
				_sotao()
			5:
				_porao()
			6:
				_quintal()
			7:
				_garagem()
			8:
				_telhado()
			9:
				_rua()
			10:
				_toca()
			11:
				_mercado()
			12:
				_ferrovelho()
			13:
				_beco()
			14:
				_arena()
			15:
				_antenas()
			_:
				_quarto()

	# ---- ferramentas
	func _grad(r: Rect2, a: Color, b: Color) -> void:
		draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([a, a, b, b]))

	func _pts_elipse(c: Vector2, rx: float, ry: float, n: int = 20) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in n:
			var a: float = TAU * i / float(n)
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		return pts

	func _elipse(c: Vector2, rx: float, ry: float, cor: Color) -> void:
		draw_colored_polygon(_pts_elipse(c, rx, ry), cor)

	func _halo(c: Vector2, r: float, cor: Color, n: int = 9) -> void:
		for g in n:
			_ci(c, r * float(n - g) / n, cor)

	func _losango(q: Vector2, rx: float, ry: float, cor: Color) -> void:
		draw_colored_polygon(PackedVector2Array([q + Vector2(0, -ry), q + Vector2(rx, 0), q + Vector2(0, ry), q + Vector2(-rx, 0)]), cor)

	## Feixe de luz: topo com a cor, base transparente.
	func _feixe(a0: Vector2, a1: Vector2, b0: Vector2, b1: Vector2, cor: Color) -> void:
		var c0 := Color(cor.r, cor.g, cor.b, 0.0)
		draw_polygon(PackedVector2Array([a0, a1, b1, b0]), PackedColorArray([cor, cor, c0, c0]))

	## Mancha de luz no chão (janela projetada): grade 2x2 de vidraças.
	func _mancha(tl: Vector2, tr: Vector2, bl: Vector2, br: Vector2, cor: Color) -> void:
		for i in 2:
			for j in 2:
				var u0: float = i * 0.5 + 0.02
				var u1: float = (i + 1) * 0.5 - 0.02
				var v0: float = j * 0.5 + 0.02
				var v1: float = (j + 1) * 0.5 - 0.02
				var f := func(u: float, v: float) -> Vector2:
					return tl.lerp(tr, u).lerp(bl.lerp(br, u), v)
				draw_colored_polygon(PackedVector2Array([f.call(u0, v0), f.call(u1, v0), f.call(u1, v1), f.call(u0, v1)]), cor)

	## Sombra de móvel num tom só (Campo.SOMBRA_COR/ALFA), para o lado oposto ao da luz do cômodo
	## (dir = +1 sombra para a direita, -1 para a esquerda). Chame ANTES de desenhar o móvel:
	## na parede (se "topo" > 0) vira a silhueta do móvel deslocada, da qual só sobra a faixa ao
	## lado dele; no chão vira um paralelogramo, guardado para ser pintado depois do piso
	## (em _sombra_vinheta). O parâmetro "a" só serve para desligar (a = 0).
	var _pend: Array = []
	func _sombra(x0: float, x1: float, prof: float, dir: float, a: float = 0.3, topo: float = -1.0) -> void:
		if not Campo.CENARIO_SOMBRAS or a <= 0.0:
			return
		var cor := Color(Campo.SOMBRA_COR.r, Campo.SOMBRA_COR.g, Campo.SOMBRA_COR.b, Campo.SOMBRA_ALFA)
		if topo > 0.0:
			var dx: float = dir * clampf(prof * 0.35, 10.0, 28.0)
			draw_rect(Rect2(minf(x0, x1) + dx, topo + 8.0, absf(x1 - x0), 447.0 - topo - 8.0), cor)
		_pend.append([x0, x1, prof, dir])

	func _sombras_chao() -> void:
		var cor := Color(Campo.SOMBRA_COR.r, Campo.SOMBRA_COR.g, Campo.SOMBRA_COR.b, Campo.SOMBRA_ALFA)
		for s in _pend:
			var x0: float = s[0]
			var x1: float = s[1]
			var prof: float = s[2]
			var dir: float = s[3]
			draw_colored_polygon(PackedVector2Array([Vector2(x0, 447), Vector2(x1, 447), Vector2(x1 + dir * prof, 447 + prof * 0.4), Vector2(x0 + dir * prof, 447 + prof * 0.4)]), cor)
		_pend.clear()

	func _rodape(cor: Color) -> void:
		draw_rect(Rect2(-40, 420, 1360, 27), cor)
		draw_rect(Rect2(-40, 420, 1360, 3), cor.lightened(0.22))
		draw_rect(Rect2(-40, 444, 1360, 3), Color(0, 0, 0, 0.45))

	func _chao(c1: Color, c2: Color, linha: Color) -> void:
		draw_polygon(PackedVector2Array([Vector2(-40, 447), Vector2(1320, 447), Vector2(1320, 740), Vector2(-40, 740)]), PackedColorArray([c1, c1, c2, c2]))
		for r in range(1, YS.size()):
			_ln(Vector2(-40, YS[r]), Vector2(1320, YS[r]), linha, 2.0)
			var passo: float = 140.0 + (YS[r] - YS[r - 1]) * 3.0
			var xj: float = -40.0 + (r * 83) % int(passo)
			while xj < 1320.0:
				_ln(Vector2(xj, YS[r - 1]), Vector2(xj, YS[r]), Color(linha.r, linha.g, linha.b, linha.a * 0.7), 1.5)
				xj += passo

	## Tapete em pixel: borda, faixa, miolo e franja. Cores opacas e quase iguais em luminância
	## (ver Campo.paleta). "persa" soma um losango central e losangos pequenos, discretos.
	func _tapete(P: Dictionary, persa: bool = false) -> void:
		draw_colored_polygon(PackedVector2Array([Vector2(215, 458), Vector2(1300, 458), Vector2(1350, 730), Vector2(165, 730)]), P.tapete_borda)
		draw_colored_polygon(PackedVector2Array([Vector2(224, 466), Vector2(1300, 466), Vector2(1338, 730), Vector2(184, 730)]), P.tapete_meio)
		draw_colored_polygon(PackedVector2Array([Vector2(246, 480), Vector2(1300, 480), Vector2(1324, 730), Vector2(214, 730)]), P.tapete_dentro)
		_pl(PackedVector2Array([Vector2(250, 492), Vector2(1300, 492)]), P.tapete_motivo, 2.0)
		if persa:
			_losango(Vector2(740, 592), 250, 66, P.tapete_meio)
			_losango(Vector2(740, 592), 170, 44, P.tapete_motivo)
			_losango(Vector2(740, 592), 96, 25, P.tapete_borda)
			_losango(Vector2(740, 592), 40, 11, P.tapete_motivo)
			for qx in [330.0, 1150.0]:
				_losango(Vector2(qx, 560), 40, 12, P.tapete_motivo)
				_losango(Vector2(qx, 630), 44, 13, P.tapete_motivo)
		else:
			for yy in [540.0, 600.0]:
				_ln(Vector2(256, yy), Vector2(1300, yy), P.tapete_meio, 2.0)
		for fx in range(224, 1300, 12):
			_ln(Vector2(fx, 458), Vector2(fx, 450), P.franja, 1.5)

	# ---- piso em pixel (desenhado na grade de baixa resolução; perspectiva: linhas mais juntas no alto)
	func _x_prof(k: float, esp: float, y: float) -> float:
		# x da linha de fuga k (espaçamento "esp" no horizonte y=447) na altura y; ponto de fuga em (640, 180)
		var x0: float = 640.0 + k * esp
		var xe: float = 640.0 + (x0 - 640.0) * ((740.0 - 180.0) / (447.0 - 180.0))
		return x0 + (xe - x0) * (y - 447.0) / 293.0

	func _piso(P: Dictionary) -> void:
		var a: Color = P.piso_a
		var b: Color = P.piso_b
		var j: Color = P.junta
		draw_rect(Rect2(-40, 447, 1360, 293), a)
		var ys: Array = YS.duplicate()
		ys.append(740.0)
		if not Campo.CENARIO_PISO_MATERIAL or fase == 1 or fase == 2:
			# tábuas largas no sentido do olhar: fileiras alternadas, juntas desencontradas
			for r in range(1, ys.size()):
				if r % 2 == 0:
					draw_rect(Rect2(-40, ys[r - 1], 1360, ys[r] - ys[r - 1]), b)
				_ln(Vector2(-40, ys[r]), Vector2(1320, ys[r]), j, 1.5)
				var passo: float = 140.0 + (ys[r] - ys[r - 1]) * 3.0
				var xj: float = -40.0 + (r * 83) % int(passo)
				while xj < 1320.0:
					_ln(Vector2(xj, ys[r - 1]), Vector2(xj, ys[r]), j, 1.5)
					xj += passo
		elif fase == 3:
			# ladrilho em xadrez de dois tons quase iguais
			for i in range(ys.size() - 1):
				for k in range(-14, 14):
					if (i + k + 40) % 2 == 0:
						draw_colored_polygon(PackedVector2Array([Vector2(_x_prof(k, 70.0, ys[i]), ys[i]), Vector2(_x_prof(k + 1, 70.0, ys[i]), ys[i]), Vector2(_x_prof(k + 1, 70.0, ys[i + 1]), ys[i + 1]), Vector2(_x_prof(k, 70.0, ys[i + 1]), ys[i + 1])]), b)
			for r in range(1, ys.size()):
				_ln(Vector2(-40, ys[r]), Vector2(1320, ys[r]), j, 1.5)
			for k in range(-14, 15):
				_ln(Vector2(_x_prof(k, 70.0, 447.0), 447), Vector2(_x_prof(k, 70.0, 740.0), 740), j, 1.5)
		elif fase == 4:
			# tábuas largas na direção da profundidade, com pregos nas emendas
			for k in range(-8, 8):
				if (k + 40) % 2 == 0:
					draw_colored_polygon(PackedVector2Array([Vector2(_x_prof(k, 150.0, 447.0), 447), Vector2(_x_prof(k + 1, 150.0, 447.0), 447), Vector2(_x_prof(k + 1, 150.0, 740.0), 740), Vector2(_x_prof(k, 150.0, 740.0), 740)]), b)
				_ln(Vector2(_x_prof(k, 150.0, 447.0), 447), Vector2(_x_prof(k, 150.0, 740.0), 740), j, 1.5)
				var yj: float = ys[1 + (k + 40) % 5]
				_ln(Vector2(_x_prof(k, 150.0, yj), yj), Vector2(_x_prof(k + 1, 150.0, yj), yj), j, 1.5)
				for sd in [0.18, 0.82]:
					var xp: float = lerpf(_x_prof(k, 150.0, yj - 8.0), _x_prof(k + 1, 150.0, yj - 8.0), sd)
					_ci(Vector2(xp, yj - 8.0), 2.0, j.darkened(0.15))
		else:
			# laje de cimento: placas com juntas desencontradas, rachaduras e um ralo na frente
			for i in range(ys.size() - 1):
				for k in range(-8, 8):
					if (i * 7 + (k + 40) * 13) % 5 == 0:
						draw_colored_polygon(PackedVector2Array([Vector2(_x_prof(k * 2.0 + (i % 2), 130.0, ys[i]), ys[i]), Vector2(_x_prof(k * 2.0 + (i % 2) + 2.0, 130.0, ys[i]), ys[i]), Vector2(_x_prof(k * 2.0 + (i % 2) + 2.0, 130.0, ys[i + 1]), ys[i + 1]), Vector2(_x_prof(k * 2.0 + (i % 2), 130.0, ys[i + 1]), ys[i + 1])]), b)
				for k in range(-8, 8):
					var kk: float = k * 2.0 + (i % 2)
					_ln(Vector2(_x_prof(kk, 130.0, ys[i]), ys[i]), Vector2(_x_prof(kk, 130.0, ys[i + 1]), ys[i + 1]), j, 1.5)
			for r in range(1, ys.size()):
				_ln(Vector2(-40, ys[r]), Vector2(1320, ys[r]), j, 1.5)
			var rach: Color = j.darkened(0.08)
			_pl(PackedVector2Array([Vector2(520, 500), Vector2(548, 540), Vector2(528, 580), Vector2(572, 620)]), rach, 2.0)
			_pl(PackedVector2Array([Vector2(548, 540), Vector2(590, 548)]), rach, 2.0)
			_pl(PackedVector2Array([Vector2(900, 488), Vector2(924, 532), Vector2(968, 548), Vector2(952, 606)]), rach, 2.0)
			_pl(PackedVector2Array([Vector2(240, 560), Vector2(262, 600), Vector2(250, 636)]), rach, 2.0)
			# ralo (fora da faixa da luta)
			_elipse(Vector2(480, 690), 42, 10, j.darkened(0.45))
			_elipse(Vector2(480, 689), 34, 7, j.darkened(0.7))
			for sx in range(-3, 4):
				_ln(Vector2(480 + sx * 9.0, 683), Vector2(480 + sx * 9.0, 695), j.darkened(0.3), 1.5)
		draw_rect(Rect2(-40, 447, 1360, 4), j.darkened(0.25))

	func _quadro(r: Rect2, moldura: Color, fundo: Color, morro: Color) -> void:
		draw_rect(r.grow(5), moldura)
		draw_rect(r, fundo)
		draw_colored_polygon(PackedVector2Array([r.position + Vector2(0, r.size.y), r.position + Vector2(r.size.x * 0.35, r.size.y * 0.45), r.position + Vector2(r.size.x * 0.6, r.size.y * 0.75), r.position + Vector2(r.size.x * 0.8, r.size.y * 0.5), r.end]), morro)
		_ci(r.position + Vector2(r.size.x * 0.78, r.size.y * 0.22), r.size.y * 0.1, Color(1, 0.95, 0.7, 0.75))

	func _teia(canto: Vector2, sx: float, tam: float, cor: Color = Color(0.85, 0.85, 0.92, 0.22)) -> void:
		for k in 5:
			var a: float = PI * 0.5 * k / 4.0
			_ln(canto, canto + Vector2(cos(a) * sx, sin(a)) * tam, cor, 1.2)
		for rr in [0.25, 0.5, 0.75, 1.0]:
			var pts := PackedVector2Array()
			for k in 5:
				var a2: float = PI * 0.5 * k / 4.0
				var sag: float = 0.88 if k % 2 == 1 else 1.0
				pts.append(canto + Vector2(cos(a2) * sx, sin(a2)) * tam * rr * sag)
			_pl(pts, cor, 1.0)

	func _buraco(x: float, y: float, larg: float) -> void:
		# buraco de rato no rodapé: arco escuro com olhinhos e migalhas
		var pts := PackedVector2Array([Vector2(x - larg * 0.5, y)])
		for i in 9:
			var a: float = PI + PI * i / 8.0
			pts.append(Vector2(x + cos(a) * larg * 0.5, y + sin(a) * larg * 0.55))
		pts.append(Vector2(x + larg * 0.5, y))
		draw_colored_polygon(pts, Color(0.02, 0.01, 0.03))
		_pl(pts, Color(0, 0, 0, 0.6), 2.5)
		_ci(Vector2(x - 4, y - larg * 0.2), 1.6, Color(1.0, 0.85, 0.3, 0.9))
		_ci(Vector2(x + 4, y - larg * 0.2), 1.6, Color(1.0, 0.85, 0.3, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(x + larg * 0.7, y + 12), Vector2(x + larg * 0.7 + 14, y + 16), Vector2(x + larg * 0.7, y + 22)]), Color(0.95, 0.78, 0.25))
		for m in [Vector2(10, 18), Vector2(26, 14), Vector2(-14, 20)]:
			_ci(Vector2(x + larg * 0.7, y) + m, 1.5, Color(0.9, 0.75, 0.3, 0.8))

	func _almofada(c: Vector2, rx: float, cor: Color) -> void:
		_elipse(c + Vector2(0, 6), rx + 6, rx * 0.26, Color(0, 0, 0, 0.3))
		_elipse(c, rx, rx * 0.26, cor.darkened(0.25))
		_elipse(c + Vector2(0, -4), rx * 0.92, rx * 0.22, cor)
		_elipse(c + Vector2(0, -3), rx * 0.55, rx * 0.12, cor.darkened(0.15))
		_ci(c + Vector2(0, -rx * 0.27), 2.5, cor.lightened(0.3))

	func _pote(c: Vector2, rx: float, cor: Color, racao: Color) -> void:
		_elipse(c + Vector2(0, 5), rx + 5, rx * 0.28, Color(0, 0, 0, 0.3))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-rx, -8), c + Vector2(rx, -8), c + Vector2(rx * 0.75, 8), c + Vector2(-rx * 0.75, 8)]), cor)
		_elipse(c + Vector2(0, -8), rx, rx * 0.28, cor.lightened(0.2))
		_elipse(c + Vector2(0, -8), rx * 0.82, rx * 0.2, racao)
		for k in 6:
			_ci(c + Vector2((k - 2.5) * rx * 0.25, -9 - (k % 2) * 2.0), 2.0, racao.lightened(0.2))

	func _novelo(c: Vector2, r: float, cor: Color) -> void:
		_elipse(c + Vector2(0, r * 0.8), r * 1.2, r * 0.3, Color(0, 0, 0, 0.3))
		_ci(c, r, cor)
		for k in 4:
			_ar(c, r * (0.35 + k * 0.17), 0.4 + k, 2.4 + k, 10, cor.darkened(0.3), 1.5)
		_ci(c + Vector2(-r * 0.3, -r * 0.3), r * 0.25, Color(1, 1, 1, 0.15))
		var fio := PackedVector2Array()
		for k in 14:
			fio.append(c + Vector2(r * 0.7 + k * 9.0, r * 0.7 + sin(k * 0.7) * 6.0 + k * 0.5))
		_pl(fio, cor, 2.0)

	func _caixa(r: Rect2, cor: Color) -> void:
		draw_rect(r, cor)
		_contorno(r, Color(0.08, 0.05, 0.04, 0.9), 2.5)
		_ln(r.position + Vector2(0, r.size.y * 0.5), r.position + Vector2(r.size.x, r.size.y * 0.5), Color(0.08, 0.05, 0.04, 0.5), 2.0)
		draw_rect(Rect2(r.position + Vector2(r.size.x * 0.36, r.size.y * 0.38), Vector2(r.size.x * 0.28, r.size.y * 0.2)), Color(0.75, 0.68, 0.5))

	func _livros(x0: float, y_base: float, n: int, w_total: float, cores: Array[Color], semente: int) -> void:
		var bx: float = x0
		for bk in n:
			var bw: float = 8.0 + (bk * 5 + semente * 3) % 5
			var bh: float = 22.0 + (bk * 7 + semente) % 11
			draw_rect(Rect2(bx, y_base - bh, bw, bh), cores[(bk + semente) % cores.size()])
			_ln(Vector2(bx + 2, y_base - bh + 4), Vector2(bx + 2, y_base - 3), Color(1, 1, 1, 0.12), 1.0)
			bx += bw + 1.5
			if bx > x0 + w_total:
				break

	# ---------------------------------------------------------------- 1 QUARTO (rosa/ameixa, abajur âmbar)
	func _quarto() -> void:
		var P: Dictionary = Campo.paleta(1)
		# paleta do Quarto (ameixa e rosa, luz âmbar): nomes usados nesta função
		var ameixa: Color = P.parede_alta
		var ameixa_escura: Color = P.parede_baixa
		var rosa: Color = P.acento_b
		var lilas: Color = P.acento_a
		var madeira: Color = P.madeira
		var ambar: Color = P.luz
		var sil: Color = P.movel
		_grad(Rect2(-40, -40, 1360, 455), ameixa, ameixa.lerp(ameixa_escura, 0.55))
		for i in 24:
			draw_rect(Rect2(i * 60.0 - 40.0, -40, 30, 455), Color(1, 1, 1, 0.028))
		for row in 4:
			for col in 12:
				var q := Vector2(32.0 + col * 120.0 + (row % 2) * 60.0, 64.0 + row * 82.0)
				_losango(q, 6, 7, Color(rosa.r, rosa.g, rosa.b, 0.12))
				_ci(q + Vector2(0, 22), 1.6, Color(rosa.r, rosa.g, rosa.b, 0.12))
		# lambri baixo (meia-parede) com friso
		draw_rect(Rect2(-40, 340, 1360, 82), ameixa_escura)
		draw_rect(Rect2(-40, 336, 1360, 6), P.rodape)
		for k in 28:
			_ln(Vector2(k * 50.0 - 30.0, 350), Vector2(k * 50.0 - 30.0, 416), Color(0, 0, 0, 0.18), 2.0)
		# quadros
		_quadro(Rect2(470, 92, 70, 86), madeira, Color(0.2, 0.26, 0.4), Color(0.14, 0.2, 0.28))
		_quadro(Rect2(570, 130, 60, 50), madeira, lilas, ameixa_escura)
		# janela com lua (luz fria) e cortina
		var jan := Rect2(690, 70, 150, 200)
		draw_rect(jan.grow(8), Color(0.55, 0.4, 0.34))
		draw_rect(jan, Color(0.08, 0.1, 0.26))
		_halo(Vector2(765, 150), 52, Color(1.0, 0.95, 0.75, 0.03), 6)
		_ci(Vector2(765, 150), 24, Color(1.0, 0.96, 0.8))
		_ci(Vector2(775, 144), 21, Color(0.08, 0.1, 0.26))
		for s in [Vector2(710, 100), Vector2(810, 120), Vector2(720, 220), Vector2(800, 240), Vector2(825, 90)]:
			_ci(s, 1.6, Color(1, 1, 0.9, 0.8))
		draw_rect(Rect2(jan.position.x + jan.size.x * 0.5 - 3, jan.position.y, 6, jan.size.y), Color(0.55, 0.4, 0.34))
		draw_rect(Rect2(jan.position.x, jan.position.y + jan.size.y * 0.55 - 3, jan.size.x, 6), Color(0.55, 0.4, 0.34))
		draw_rect(Rect2(jan.position.x - 14, jan.end.y + 8, jan.size.x + 28, 8), Color(0.5, 0.36, 0.3))
		_ln(Vector2(656, 58), Vector2(874, 58), Color(0.72, 0.56, 0.36), 4.0)
		# cama (cortada pela borda esquerda), sombra para longe do abajur
		_sombra(-40, 340, 46, -1.0, 0.3, 238.0)
		draw_rect(Rect2(-40, 238, 56, 209), sil.lightened(0.05))
		draw_rect(Rect2(-40, 238, 56, 8), sil.lightened(0.18))
		draw_rect(Rect2(-40, 398, 380, 49), sil)
		draw_rect(Rect2(-40, 332, 380, 74), lilas)
		for k in 9:
			draw_rect(Rect2(-40 + k * 44.0, 332, 22, 74), lilas.lightened(0.12))
		draw_rect(Rect2(-40, 332, 380, 5), lilas.lightened(0.35))
		_elipse(Vector2(40, 322), 58, 17, Color(0.85, 0.8, 0.88))
		_elipse(Vector2(40, 319), 50, 12, Color(0.95, 0.92, 0.96))
		draw_rect(Rect2(318, 396, 16, 51), sil.lightened(0.04))
		# poste arranhador (base no fundo do chão), com bolinha pendurada
		_sombra(398, 458, 24, -1.0, 0.25, 322.0)
		draw_rect(Rect2(396, 436, 70, 12), madeira)
		draw_rect(Rect2(418, 336, 26, 102), Color(0.62, 0.5, 0.36))
		for k in 13:
			_ln(Vector2(418, 342 + k * 8.0), Vector2(444, 346 + k * 8.0), Color(0.35, 0.26, 0.18, 0.7), 1.5)
		draw_rect(Rect2(398, 322, 66, 16), madeira)
		draw_rect(Rect2(398, 322, 66, 4), madeira.lightened(0.3))
		_ln(Vector2(456, 338), Vector2(456, 372), Color(0.8, 0.7, 0.5), 1.5)
		_ci(Vector2(456, 378), 7, rosa)
		# estante com livros e brinquedos
		_sombra(930, 1060, 36, -1.0, 0.3, 190.0)
		draw_rect(Rect2(930, 190, 130, 228), sil)
		draw_rect(Rect2(930, 190, 130, 4), sil.lightened(0.2))
		var cores: Array[Color] = [Color(0.45, 0.2, 0.26), Color(0.22, 0.28, 0.44), Color(0.45, 0.38, 0.2), Color(0.24, 0.38, 0.3)]
		for sh in 4:
			var sy: float = 190.0 + 18.0 + sh * 52.0
			draw_rect(Rect2(936, sy + 30, 118, 4), Color(0.28, 0.18, 0.2))
			if sh == 1:
				_ci(Vector2(1000, sy + 18), 11, Color(0.75, 0.55, 0.38))
				_ci(Vector2(993, sy + 9), 4, Color(0.75, 0.55, 0.38))
				_ci(Vector2(1007, sy + 9), 4, Color(0.75, 0.55, 0.38))
				_livros(940, sy + 30, 3, 40, cores, sh)
			else:
				_livros(940, sy + 30, 8, 112, cores, sh)
		# criado-mudo e abajur (fonte de luz)
		_sombra(1100, 1210, 50, -1.0, 0.35, 362.0)
		draw_rect(Rect2(1104, 366, 102, 81), sil.lightened(0.04))
		draw_rect(Rect2(1112, 376, 86, 28), Color(0.2, 0.14, 0.2))
		_ci(Vector2(1155, 390), 3, Color(0.8, 0.65, 0.4))
		draw_rect(Rect2(1110, 362, 90, 6), Color(0.3, 0.21, 0.24))
		draw_rect(Rect2(1150, 336, 8, 28), Color(0.3, 0.22, 0.22))
		_halo(Vector2(1154, 316), 210, Color(1.0, 0.72, 0.32, 0.026), 9)
		draw_colored_polygon(PackedVector2Array([Vector2(1126, 340), Vector2(1182, 340), Vector2(1166, 290), Vector2(1142, 290)]), Color(1.0, 0.84, 0.5))
		draw_colored_polygon(PackedVector2Array([Vector2(1126, 340), Vector2(1182, 340), Vector2(1180, 334), Vector2(1128, 334)]), Color(0.9, 0.62, 0.3))
		# livro e relógio sobre o criado-mudo
		draw_rect(Rect2(1112, 354, 24, 8), Color(0.5, 0.2, 0.25))
		# cone de luz do abajur subindo/descendo na parede
		_feixe(Vector2(1142, 290), Vector2(1166, 290), Vector2(1090, 130), Vector2(1218, 130), Color(1.0, 0.8, 0.45, 0.07))
		_rodape(P.rodape)
		# buraco de rato no rodapé
		_buraco(640, 446, 38)
		# piso: tábuas em pixel; tapete com borda e franja por cima
		_piso(P)
		# luar projetado no chão (fria) e poça quente do abajur
		_mancha(Vector2(500, 452), Vector2(700, 452), Vector2(370, 640), Vector2(610, 640), Color(0.6, 0.72, 1.0, 0.03))
		_elipse(Vector2(1154, 468), 130, 16, Color(ambar.r, ambar.g, ambar.b, 0.05))
		_tapete(P)
		# migalhas e frente do chão: almofada, pote de ração, novelo
		for m in [Vector2(690, 454), Vector2(704, 460), Vector2(676, 462), Vector2(722, 456)]:
			_ci(m, 1.8, Color(0.9, 0.78, 0.45, 0.7))
		_almofada(Vector2(330, 700), 64, rosa)
		_novelo(Vector2(640, 698), 17, Color(0.85, 0.3, 0.35))
		_pote(Vector2(860, 702), 34, Color(0.35, 0.55, 0.8), Color(0.55, 0.32, 0.2))
		_sombra_vinheta()

	## Luz principal em degraus (anéis de tom, o pontilhado do sombreador suaviza as bordas),
	## primeiro plano em silhueta escura nos cantos e vinheta em degraus. Fica fora da faixa
	## da luta (y 475 a 640).
	func _luz_degraus(c: Vector2, r: float, cor: Color, n: int = 4) -> void:
		for k in n:
			var f: float = float(n - k) / n
			_elipse(c, r * f, r * f * 0.8, Color(cor.r, cor.g, cor.b, cor.a))

	## Regras de segurança (conferidas por conta): as silhuetas ficam abaixo de y = 676 (faixa da luta
	## termina em 640), longe da torre (x < 200) e da caixa de peças (x >= 1160, y >= 630); a luz soma
	## no máximo "luz_extra" (Campo.paleta) de luminância ao chão da faixa; a vinheta lateral escurece
	## no máximo 2 x 4% e só nas bordas (x < 100 e x > 1180).
	func _sombra_vinheta() -> void:
		_sombras_chao()
		var P: Dictionary = Campo.paleta(fase)
		var sil: Color = Color(0.03, 0.02, 0.05, 0.92)
		if Campo.CENARIO_LUZ:
			match fase:
				2:
					_luz_degraus(Vector2(592, 340), 300.0, Color(1.0, 0.55, 0.2, 0.02))
				3:
					# luz fria sob o armário alto, caindo na bancada (acima da faixa)
					_feixe(Vector2(0, 176), Vector2(450, 176), Vector2(-20, 300), Vector2(470, 300), Color(1.0, 0.95, 0.75, 0.10))
					_luz_degraus(Vector2(722, 150), 200.0, Color(0.6, 0.75, 1.0, 0.03), 3)
				4:
					# facho da claraboia em degraus na parede e no fundo do chão (termina em y = 447)
					for k in 3:
						var w: float = 40.0 * (3 - k)
						draw_colored_polygon(PackedVector2Array([Vector2(820 - w, 140), Vector2(960 + w, 140), Vector2(1020 + w * 2.0, 447), Vector2(740 - w * 2.0, 447)]), Color(0.65, 0.78, 1.0, 0.03))
				5:
					_luz_degraus(Vector2(600, 200), 320.0, Color(1.0, 0.8, 0.4, 0.03), 5)
				6:
					# último clarão do entardecer sobre a cerca
					_luz_degraus(Vector2(980, 330), 300.0, Color(1.0, 0.7, 0.4, 0.025), 4)
				7:
					# fluorescente no teto: facho frio caindo no chão
					_feixe(Vector2(480, 96), Vector2(780, 96), Vector2(330, 447), Vector2(930, 447), Color(0.85, 0.95, 1.0, 0.05))
				8:
					_luz_degraus(Vector2(760, 130), 330.0, Color(0.7, 0.8, 1.0, 0.025), 4)
				9:
					# cone do poste de luz
					_feixe(Vector2(676, 100), Vector2(724, 100), Vector2(470, 447), Vector2(930, 447), Color(1.0, 0.78, 0.4, 0.07))
					_luz_degraus(Vector2(700, 480), 200.0, Color(1.0, 0.78, 0.4, 0.02), 3)
				10:
					_luz_degraus(Vector2(340, 190), 220.0, Color(1.0, 0.65, 0.25, 0.03), 4)
					_luz_degraus(Vector2(940, 190), 220.0, Color(1.0, 0.65, 0.25, 0.03), 4)
				11:
					_feixe(Vector2(622, 146), Vector2(668, 146), Vector2(470, 447), Vector2(830, 447), Color(1.0, 0.85, 0.55, 0.05))
					_luz_degraus(Vector2(1180, 150), 150.0, Color(0.3, 0.9, 1.0, 0.03), 3)
				12:
					_luz_degraus(Vector2(900, 330), 360.0, Color(1.0, 0.6, 0.25, 0.022), 4)
				13:
					_luz_degraus(Vector2(640, 150), 360.0, Color(0.2, 0.85, 0.95, 0.02), 4)
				14:
					_luz_degraus(Vector2(590, 330), 170.0, Color(1.0, 0.6, 0.25, 0.03), 3)
					_luz_degraus(Vector2(790, 330), 170.0, Color(1.0, 0.6, 0.25, 0.03), 3)
				15:
					_luz_degraus(Vector2(1010, 230), 300.0, Color(0.7, 0.5, 1.0, 0.02), 4)
				_:
					var luz: Color = P.luz
					_luz_degraus(Vector2(1154, 316), 280.0, Color(luz.r, luz.g, luz.b, 0.035), 4)
					_elipse(Vector2(1154, 468), 170, 22, Color(luz.r, luz.g, luz.b, 0.04))
		if not Campo.CENARIO_SILHUETAS:
			return
		# objeto de primeiro plano no canto de baixo, ENTRE a barra de poderes (termina em x ~ 1075) e a caixa de
		# peças (x >= 1160): antes eram blocos pretos lisos atrás da barra e pareciam defeito. Agora é um objeto
		# reconhecível do cômodo, escuro mas com a borda de cima acesa pela luz do cenário (k = corpo, r = borda).
		var luz_b: Color = P.luz
		var pal_sil: Dictionary = {"k": Color(sil.r, sil.g, sil.b, 1.0), "r": Color(sil.r, sil.g, sil.b, 1.0).lerp(luz_b, 0.38), "m": Color(sil.r, sil.g, sil.b, 1.0).lerp(luz_b, 0.16)}
		var bm: Array = SIL_FRENTE.get(fase, SIL_FRENTE[1])
		_bitmap(Vector2(1090.0, 720.0 - bm.size() * G), bm, pal_sil)
		# vinheta em degraus: base (abaixo da faixa) e bordas laterais estreitas
		for k in 2:
			draw_rect(Rect2(-40, 700 + k * 14.0, 1360, 60), Color(0, 0, 0.04, 0.10))
			draw_rect(Rect2(-40, 0, 60 + k * 40.0, 740), Color(0, 0, 0.04, 0.04))
			draw_rect(Rect2(1220 - k * 40.0, 0, 120, 740), Color(0, 0, 0.04, 0.04))

	# ---------------------------------------------------------------- 2 SALA (vinho, lareira, azul do luar)
	func _sala() -> void:
		var P: Dictionary = Campo.paleta(2)
		# paleta da Sala (vinho e madeira, luz laranja da lareira): nomes usados nesta função
		var vinho: Color = P.parede_alta
		var vinho_escuro: Color = P.parede_baixa
		var madeira: Color = P.madeira
		var azul_luar: Color = P.acento_a
		var ouro: Color = P.acento_b
		var brasa: Color = P.luz
		var sil: Color = P.movel
		_grad(Rect2(-40, -40, 1360, 350), vinho, vinho.lerp(vinho_escuro, 0.5))
		for i in 24:
			draw_rect(Rect2(i * 60.0 - 40.0, -40, 5, 350), Color(ouro.r, ouro.g, ouro.b, 0.06))
		for row in 3:
			for col in 12:
				var q := Vector2(10.0 + col * 120.0 + (row % 2) * 60.0 + 30, 50.0 + row * 85.0)
				_losango(q, 7, 9, Color(ouro.r, ouro.g, ouro.b, 0.08))
				_ci(q, 2.2, Color(ouro.r, ouro.g, ouro.b, 0.1))
		# lambri de madeira
		draw_rect(Rect2(-40, 298, 1360, 128), vinho_escuro)
		for k in 28:
			var px: float = k * 50.0 - 30.0
			draw_rect(Rect2(px, 314, 38, 92), vinho_escuro.lightened(0.12))
			_contorno(Rect2(px, 314, 38, 92), vinho_escuro.darkened(0.45), 2.0)
		draw_rect(Rect2(-40, 292, 1360, 10), madeira)
		draw_rect(Rect2(-40, 292, 1360, 3), madeira.lightened(0.4))
		# estante de livros (esquerda, cortada)
		_sombra(-30, 145, 40, -1.0, 0.3, 100.0)
		draw_rect(Rect2(-30, 100, 175, 325), sil)
		var cores: Array[Color] = [Color(0.5, 0.2, 0.22), Color(0.22, 0.3, 0.45), Color(0.5, 0.42, 0.2), Color(0.25, 0.4, 0.3)]
		for sh in 5:
			var sy: float = 100.0 + 56.0 + sh * 62.0
			draw_rect(Rect2(-24, sy, 163, 5), Color(0.3, 0.19, 0.14))
			_livros(-20, sy, 10, 155, cores, sh + 1)
		# relógio de pé (pêndulo é animado)
		_sombra(255, 325, 36, -1.0, 0.3, 138.0)
		draw_rect(Rect2(256, 150, 68, 280), madeira.darkened(0.2))
		draw_rect(Rect2(250, 138, 80, 22), Color(0.36, 0.22, 0.15))
		draw_rect(Rect2(262, 158, 56, 56), Color(0.14, 0.08, 0.06))
		_ci(Vector2(290, 186), 23, Color(0.92, 0.86, 0.7))
		_ar(Vector2(290, 186), 23, 0, TAU, 24, Color(0.3, 0.18, 0.1), 2.0)
		_ln(Vector2(290, 186), Vector2(290, 170), Color(0.15, 0.1, 0.08), 2.0)
		_ln(Vector2(290, 186), Vector2(300, 190), Color(0.15, 0.1, 0.08), 2.0)
		draw_rect(Rect2(268, 232, 44, 124), Color(0.07, 0.04, 0.05))
		_contorno(Rect2(268, 232, 44, 124), Color(0.5, 0.35, 0.2), 2.0)
		# quadros
		_quadro(Rect2(360, 90, 96, 66), Color(0.55, 0.4, 0.22), Color(0.2, 0.26, 0.36), Color(0.14, 0.2, 0.26))
		_quadro(Rect2(380, 180, 50, 62), Color(0.55, 0.4, 0.22), Color(0.3, 0.2, 0.26), Color(0.2, 0.14, 0.2))
		# lareira (fonte de luz quente; chamas animadas)
		_sombra(470, 710, 0, 1.0, 0.0)
		draw_rect(Rect2(474, 236, 232, 190), Color(0.24, 0.16, 0.16))
		for r in 6:
			for c in 5:
				draw_rect(Rect2(478 + c * 45.0 + (r % 2) * 20.0, 244 + r * 30.0, 40, 26), Color(0.3 + 0.02 * ((r + c) % 3), 0.2, 0.19), true)
		draw_rect(Rect2(450, 216, 280, 22), Color(0.42, 0.28, 0.2))
		draw_rect(Rect2(450, 216, 280, 4), Color(0.62, 0.45, 0.32))
		draw_rect(Rect2(530, 296, 120, 130), Color(0.04, 0.02, 0.03))
		draw_rect(Rect2(522, 290, 136, 8), Color(0.18, 0.12, 0.12))
		_ln(Vector2(550, 412), Vector2(630, 404), Color(0.3, 0.17, 0.1), 9.0)
		_ln(Vector2(550, 404), Vector2(632, 412), Color(0.25, 0.14, 0.09), 8.0)
		# quadro sobre a lareira + castiçais
		_quadro(Rect2(520, 80, 140, 100), Color(0.6, 0.45, 0.25), Color(0.18, 0.22, 0.34), Color(0.12, 0.17, 0.26))
		draw_rect(Rect2(470, 190, 8, 26), Color(0.8, 0.75, 0.6))
		draw_rect(Rect2(700, 190, 8, 26), Color(0.8, 0.75, 0.6))
		_halo(Vector2(590, 360), 330, Color(1.0, 0.55, 0.22, 0.003), 9)
		# janela com lua e cortina, sofá embaixo (cortado pela borda direita)
		var jan := Rect2(900, 56, 150, 190)
		draw_rect(jan.grow(8), Color(0.38, 0.28, 0.28))
		draw_rect(jan, Color(0.07, 0.1, 0.26))
		_ci(Vector2(1000, 112), 21, Color(0.95, 0.95, 0.85, 0.9))
		_ci(Vector2(1008, 106), 18, Color(0.07, 0.1, 0.26))
		for st in [Vector2(930, 90), Vector2(960, 150), Vector2(1030, 190), Vector2(930, 215)]:
			_ci(st, 1.6, Color(1, 1, 0.9, 0.8))
		draw_rect(Rect2(jan.position.x + 72, jan.position.y, 6, jan.size.y), Color(0.38, 0.28, 0.28))
		_ln(Vector2(850, 44), Vector2(1100, 44), Color(0.65, 0.5, 0.3), 4.0)
		_sombra(790, 1340, 56, 1.0, 0.3, 268.0)
		draw_rect(Rect2(806, 268, 540, 90), azul_luar.darkened(0.25))
		draw_rect(Rect2(806, 268, 540, 6), Color(0.22, 0.3, 0.44))
		draw_rect(Rect2(790, 316, 40, 112), Color(0.15, 0.22, 0.34))
		draw_rect(Rect2(830, 340, 520, 70), Color(0.17, 0.25, 0.38))
		for k in 3:
			draw_rect(Rect2(836 + k * 182.0, 346, 176, 56), Color(0.2, 0.29, 0.43))
			_contorno(Rect2(836 + k * 182.0, 346, 176, 56), Color(0.08, 0.1, 0.18, 0.8), 2.0)
		draw_rect(Rect2(830, 410, 520, 18), Color(0.1, 0.14, 0.22))
		draw_colored_polygon(PackedVector2Array([Vector2(850, 306), Vector2(906, 300), Vector2(912, 352), Vector2(846, 356)]), Color(0.78, 0.55, 0.22))
		draw_colored_polygon(PackedVector2Array([Vector2(1140, 300), Vector2(1196, 304), Vector2(1190, 352), Vector2(1130, 350)]), Color(0.72, 0.3, 0.3))
		# planta em vaso
		draw_rect(Rect2(730, 384, 46, 44), Color(0.5, 0.28, 0.2))
		draw_rect(Rect2(726, 380, 54, 8), Color(0.6, 0.35, 0.25))
		for k in 7:
			var a: float = -PI * 0.5 + (k - 3) * 0.38
			var tip: Vector2 = Vector2(753, 382) + Vector2(cos(a), sin(a)) * (62.0 - abs(k - 3) * 6.0)
			draw_colored_polygon(PackedVector2Array([Vector2(753, 382), tip + Vector2(-9, 4), tip, tip + Vector2(9, 6)]), Color(0.14, 0.34 + 0.02 * k, 0.2))
		_rodape(P.rodape)
		_buraco(1000, 446, 36)
		_piso(P)
		_mancha(Vector2(920, 452), Vector2(1060, 452), Vector2(980, 640), Vector2(1220, 640), Color(0.6, 0.72, 1.0, 0.03))
		# tapete persa simples: borda, losango central e losangos pequenos (tons próximos do piso)
		_tapete(P, true)
		for m in [Vector2(1030, 455), Vector2(1044, 460), Vector2(1018, 462)]:
			_ci(m, 1.8, Color(0.9, 0.78, 0.45, 0.7))
		_almofada(Vector2(330, 700), 62, azul_luar.lightened(0.4))
		_pote(Vector2(800, 702), 32, Color(0.7, 0.7, 0.75), Color(0.5, 0.3, 0.2))
		_novelo(Vector2(560, 698), 16, Color(0.9, 0.75, 0.3))
		_sombra_vinheta()

	# ---------------------------------------------------------------- 3 COZINHA (azulejo verde-água, luz fria)
	func _cozinha() -> void:
		var P: Dictionary = Campo.paleta(3)
		# paleta da Cozinha (verde-água e creme, luz branca fria): nomes usados nesta função
		var az: Color = P.parede_alta
		var verde_escuro: Color = P.parede_baixa
		var armario: Color = P.madeira
		var creme: Color = P.acento_a
		var laranja: Color = P.acento_b
		draw_rect(Rect2(-40, -40, 1360, 470), az)
		for r in 16:
			for col in 25:
				var rc := Rect2(col * 56.0 - 40.0 - (r % 2) * 28.0, r * 30.0 - 12.0, 54, 28)
				var v: float = 0.01 * float((r * 5 + col * 3) % 4)
				draw_rect(rc, Color(az.r + v, az.g + v, az.b + v))
				draw_rect(Rect2(rc.position, Vector2(rc.size.x, 2)), Color(1, 1, 1, 0.06))
		_grad(Rect2(-40, -40, 1360, 300), Color(0, 0.02, 0.05, 0.4), Color(0, 0.02, 0.05, 0.0))
		# armários altos (esquerda, cortados) + luz sob os armários
		for k in 4:
			var ax: float = -40.0 + k * 122.0
			draw_rect(Rect2(ax, 30, 118, 142), Color(0.34, 0.24, 0.18))
			draw_rect(Rect2(ax + 8, 38, 102, 126), Color(0.4, 0.29, 0.21))
			_contorno(Rect2(ax + 8, 38, 102, 126), Color(0.15, 0.09, 0.07, 0.7), 2.0)
			draw_rect(Rect2(ax + (92 if k % 2 == 0 else 14), 120, 6, 18), Color(0.85, 0.8, 0.62))
		draw_rect(Rect2(-40, 172, 490, 5), Color(0.2, 0.13, 0.1))
		_feixe(Vector2(-40, 177), Vector2(450, 177), Vector2(-60, 292), Vector2(500, 292), Color(1.0, 0.92, 0.65, 0.1))
		# varão com panelas (panelas são animadas)
		_ln(Vector2(240, 196), Vector2(430, 196), Color(0.6, 0.62, 0.68), 3.0)
		# coifa + fogão
		draw_colored_polygon(PackedVector2Array([Vector2(470, 100), Vector2(560, 100), Vector2(590, 180), Vector2(440, 180)]), Color(0.45, 0.47, 0.52))
		draw_rect(Rect2(500, 60, 30, 42), Color(0.4, 0.42, 0.47))
		draw_rect(Rect2(-40, 290, 1040, 14), Color(0.55, 0.57, 0.62))
		draw_rect(Rect2(-40, 290, 1040, 3), Color(0.8, 0.82, 0.88))
		_sombra(450, 570, 40, -1.0, 0.3, 262.0)
		draw_rect(Rect2(-40, 304, 1040, 118), verde_escuro)
		for k in 10:
			draw_rect(Rect2(-30 + k * 106.0, 312, 96, 102), armario)
			_contorno(Rect2(-30 + k * 106.0, 312, 96, 102), Color(0.12, 0.07, 0.07, 0.6), 2.0)
			draw_rect(Rect2(8 + k * 106.0, 322, 18, 5), Color(0.82, 0.78, 0.62))
		draw_rect(Rect2(450, 262, 120, 30), Color(0.14, 0.14, 0.17))
		draw_rect(Rect2(450, 296, 120, 124), Color(0.22, 0.23, 0.27))
		draw_rect(Rect2(462, 330, 96, 70), Color(0.08, 0.09, 0.11))
		_contorno(Rect2(462, 330, 96, 70), Color(0.5, 0.52, 0.58), 2.0)
		for bx in [472.0, 500.0, 528.0, 556.0]:
			_ci(Vector2(bx, 312), 5, Color(0.55, 0.56, 0.6))
		draw_rect(Rect2(470, 246, 80, 18), Color(0.45, 0.46, 0.5))
		# janela sobre a pia, luar frio
		var jan := Rect2(640, 76, 130, 120)
		draw_rect(jan.grow(7), Color(0.6, 0.58, 0.52))
		draw_rect(jan, Color(0.07, 0.11, 0.25))
		_ci(Vector2(730, 118), 15, Color(1, 0.96, 0.82, 0.9))
		_ci(Vector2(737, 113), 13, Color(0.07, 0.11, 0.25))
		draw_rect(Rect2(jan.position.x + 62, jan.position.y, 6, jan.size.y), Color(0.6, 0.58, 0.52))
		draw_rect(Rect2(jan.position.x, jan.position.y + 56, jan.size.x, 6), Color(0.6, 0.58, 0.52))
		# pia e torneira
		draw_rect(Rect2(640, 284, 130, 10), Color(0.08, 0.09, 0.11))
		_ln(Vector2(706, 252), Vector2(706, 284), Color(0.7, 0.72, 0.78), 5.0)
		_ln(Vector2(706, 254), Vector2(722, 254), Color(0.7, 0.72, 0.78), 5.0)
		_ln(Vector2(722, 254), Vector2(722, 264), Color(0.7, 0.72, 0.78), 5.0)
		# lixeira e vassoura
		_sombra(1005, 1067, 28, 1.0, 0.3, 350.0)
		draw_rect(Rect2(1005, 360, 62, 87), Color(0.5, 0.52, 0.56))
		draw_rect(Rect2(1000, 350, 72, 14), Color(0.38, 0.4, 0.44))
		_contorno(Rect2(1005, 360, 62, 87), Color(0.1, 0.1, 0.12, 0.7), 2.0)
		_ln(Vector2(1000, 262), Vector2(988, 436), Color(0.55, 0.4, 0.25), 4.0)
		draw_colored_polygon(PackedVector2Array([Vector2(976, 410), Vector2(1002, 412), Vector2(1008, 446), Vector2(968, 446)]), Color(0.7, 0.6, 0.3))
		# geladeira (cortada pela borda direita), com ímãs e bilhete
		_sombra(1090, 1330, 50, 1.0, 0.35, 100.0)
		_grad(Rect2(1090, 100, 240, 325), Color(0.5, 0.58, 0.6), Color(0.62, 0.7, 0.72))
		_contorno(Rect2(1090, 100, 240, 325), Color(0.1, 0.12, 0.14), 3.0)
		_ln(Vector2(1090, 220), Vector2(1330, 220), Color(0.1, 0.12, 0.14), 3.0)
		draw_rect(Rect2(1104, 130, 7, 62), Color(0.25, 0.28, 0.32))
		draw_rect(Rect2(1104, 240, 7, 88), Color(0.25, 0.28, 0.32))
		draw_rect(Rect2(1150, 140, 46, 56), Color(0.95, 0.93, 0.8))
		_ln(Vector2(1156, 156), Vector2(1190, 156), Color(0.3, 0.3, 0.4), 1.5)
		_ln(Vector2(1156, 166), Vector2(1186, 166), Color(0.3, 0.3, 0.4), 1.5)
		_ln(Vector2(1156, 176), Vector2(1176, 176), Color(0.3, 0.3, 0.4), 1.5)
		_ci(Vector2(1173, 142), 4, Color(0.85, 0.3, 0.3))
		draw_colored_polygon(PackedVector2Array([Vector2(1220, 260), Vector2(1244, 270), Vector2(1220, 280)]), Color(0.9, 0.7, 0.3))
		_ci(Vector2(1250, 270), 5, Color(0.9, 0.7, 0.3))
		_rodape(P.rodape)
		_buraco(1078, 446, 30)
		# piso de ladrilho em xadrez de dois tons quase iguais, em perspectiva (ver _piso)
		_piso(P)
		_mancha(Vector2(660, 452), Vector2(790, 452), Vector2(560, 640), Vector2(800, 640), Color(0.7, 0.85, 1.0, 0.04))
		# frente: potes, leite derramado, espinha de peixe
		_elipse(Vector2(600, 704), 56, 9, Color(0.9, 0.93, 0.95, 0.35))
		_pote(Vector2(830, 700), 30, laranja, Color(0.5, 0.3, 0.2))
		_pote(Vector2(900, 704), 26, Color(0.4, 0.62, 0.8), Color(0.35, 0.5, 0.7))
		_ln(Vector2(420, 696), Vector2(470, 700), Color(0.9, 0.9, 0.85, 0.8), 2.0)
		_ci(Vector2(418, 696), 5, Color(0.9, 0.9, 0.85, 0.8))
		_almofada(Vector2(300, 702), 56, creme)
		_sombra_vinheta()

	# ---------------------------------------------------------------- 4 SÓTÃO (anil, vigas, claraboia)
	func _sotao() -> void:
		var P: Dictionary = Campo.paleta(4)
		# paleta do Sótão (anil e madeira clara, luar azul): nomes usados nesta função
		var anil: Color = P.parede_alta
		var anil_claro: Color = P.parede_baixa
		var madeira: Color = P.madeira
		var lencol: Color = P.acento_a
		var creme: Color = P.acento_b
		var luar: Color = P.luz
		var sil: Color = P.movel
		_grad(Rect2(-40, -40, 1360, 485), anil, anil.lerp(anil_claro, 0.7))
		for k in 17:
			var yy: float = k * 28.0 + 10.0
			_ln(Vector2(-40, yy), Vector2(1320, yy), Color(0, 0, 0, 0.2), 2.0)
			var xj: float = fmod(k * 197.0, 300.0)
			while xj < 1320.0:
				_ln(Vector2(xj, yy), Vector2(xj, yy + 28), Color(0, 0, 0, 0.12), 1.5)
				xj += 300.0
		var viga: Color = madeira.darkened(0.3)
		for k in 7:
			var bx: float = 90.0 + k * 190.0
			_ln(Vector2(bx, 440), Vector2(640 + (bx - 640.0) * 0.35, 20), viga, 14.0)
			_ln(Vector2(bx - 5, 440), Vector2(640 + (bx - 640.0) * 0.35 - 5, 20), viga.lightened(0.15), 3.0)
		_ln(Vector2(-40, 24), Vector2(1320, 24), viga.darkened(0.2), 22.0)
		_ln(Vector2(-40, 250), Vector2(1320, 250), viga.darkened(0.1), 10.0)
		# armário velho com espelho (esquerda, cortado)
		_sombra(-40, 150, 40, -1.0, 0.3, 112.0)
		draw_rect(Rect2(-40, 120, 190, 327), sil.lerp(madeira, 0.35))
		draw_rect(Rect2(-40, 112, 190, 12), Color(0.28, 0.19, 0.16))
		draw_rect(Rect2(22, 150, 80, 220), Color(0.35, 0.42, 0.55))
		_contorno(Rect2(22, 150, 80, 220), Color(0.34, 0.24, 0.18), 5.0)
		_ln(Vector2(34, 170), Vector2(60, 340), Color(1, 1, 1, 0.12), 3.0)
		_ln(Vector2(60, 250), Vector2(96, 240), Color(0.05, 0.05, 0.1, 0.6), 1.5)
		# caixas, baú e manequim
		_sombra(165, 320, 30, -1.0, 0.25, 330.0)
		for bx2 in [Vector2(170, 380), Vector2(240, 392), Vector2(200, 330)]:
			_caixa(Rect2(bx2, Vector2(70, 56)), madeira.darkened(0.15))
		_sombra(340, 444, 30, -1.0, 0.3, 366.0)
		draw_rect(Rect2(340, 376, 104, 71), madeira.darkened(0.45))
		draw_rect(Rect2(334, 366, 116, 18), Color(0.4, 0.26, 0.18))
		draw_rect(Rect2(380, 380, 16, 16), Color(0.75, 0.65, 0.3))
		draw_rect(Rect2(346, 366, 6, 80), Color(0.6, 0.5, 0.3, 0.6))
		draw_rect(Rect2(432, 366, 6, 80), Color(0.6, 0.5, 0.3, 0.6))
		_ln(Vector2(500, 250), Vector2(500, 430), Color(0.2, 0.15, 0.13), 4.0)
		draw_colored_polygon(PackedVector2Array([Vector2(474, 262), Vector2(526, 262), Vector2(518, 345), Vector2(482, 345)]), Color(0.36, 0.24, 0.32))
		_ci(Vector2(500, 244), 11, Color(0.36, 0.24, 0.32))
		draw_rect(Rect2(480, 424, 40, 8), Color(0.2, 0.15, 0.13))
		# poltrona coberta por lençol
		_sombra(870, 1040, 40, 1.0, 0.3, 300.0)
		draw_colored_polygon(PackedVector2Array([Vector2(868, 447), Vector2(878, 340), Vector2(900, 308), Vector2(960, 300), Vector2(1000, 312), Vector2(1030, 345), Vector2(1040, 447), Vector2(1020, 442), Vector2(996, 447), Vector2(960, 440), Vector2(920, 447), Vector2(896, 441)]), lencol.lightened(0.35))
		_pl(PackedVector2Array([Vector2(900, 330), Vector2(912, 440)]), Color(0.3, 0.3, 0.42, 0.5), 2.0)
		_pl(PackedVector2Array([Vector2(960, 320), Vector2(956, 436)]), Color(0.3, 0.3, 0.42, 0.5), 2.0)
		_pl(PackedVector2Array([Vector2(1004, 335), Vector2(1000, 440)]), Color(0.3, 0.3, 0.42, 0.5), 2.0)
		# pilha de caixas à direita e tapete enrolado (cortado)
		_sombra(1070, 1226, 30, 1.0, 0.25, 316.0)
		for bx3 in [Vector2(1070, 372), Vector2(1100, 316), Vector2(1150, 380)]:
			_caixa(Rect2(bx3, Vector2(76, 62)), madeira.darkened(0.2))
		draw_rect(Rect2(1244, 250, 80, 197), Color(0.4, 0.2, 0.22))
		_ar(Vector2(1244, 250), 34, 0, TAU, 18, Color(0.55, 0.3, 0.28), 4.0)
		_elipse(Vector2(1244, 250), 14, 34, Color(0.3, 0.14, 0.17))
		# claraboia e feixe de luar no ar
		var cl := Rect2(520, 38, 240, 90)
		draw_rect(cl.grow(8), Color(0.32, 0.22, 0.18))
		draw_rect(cl, Color(0.1, 0.14, 0.32))
		_ci(Vector2(640, 80), 22, Color(1, 0.97, 0.88, 0.95))
		_ci(Vector2(646, 76), 18, Color(0.1, 0.14, 0.32))
		_ln(Vector2(640, 38), Vector2(640, 128), Color(0.32, 0.22, 0.18), 5.0)
		_feixe(Vector2(540, 128), Vector2(740, 128), Vector2(380, 450), Vector2(930, 450), Color(luar.r, luar.g, luar.b, 0.10))
		# teias nos cantos
		_teia(Vector2(1320, 34), -1.0, 190.0)
		_teia(Vector2(-40, 34), 1.0, 150.0)
		_rodape(P.rodape)
		_buraco(700, 446, 34)
		# tábuas largas com pregos (ver _piso); o luar cai em manchas fracas
		_piso(P)
		_mancha(Vector2(470, 452), Vector2(810, 452), Vector2(330, 650), Vector2(950, 650), Color(0.6, 0.75, 1.0, 0.03))
		# frente: livro velho, cubos, cama de gato
		draw_colored_polygon(PackedVector2Array([Vector2(530, 696), Vector2(600, 690), Vector2(608, 708), Vector2(538, 714)]), Color(0.5, 0.2, 0.22))
		draw_colored_polygon(PackedVector2Array([Vector2(532, 700), Vector2(600, 694), Vector2(604, 700), Vector2(536, 706)]), Color(0.9, 0.85, 0.7))
		draw_rect(Rect2(840, 690, 20, 20), Color(0.8, 0.3, 0.3))
		draw_rect(Rect2(862, 696, 20, 20), Color(0.3, 0.5, 0.8))
		_almofada(Vector2(310, 702), 60, lencol.lightened(0.2))
		_novelo(Vector2(980, 700), 15, Color(0.4, 0.7, 0.55))
		_sombra_vinheta()

	# ---------------------------------------------------------------- 5 PORÃO (tijolo, lâmpada, caldeira)
	func _porao() -> void:
		var P: Dictionary = Campo.paleta(5)
		# paleta do Porão (tijolo e cinza, luz amarela fraca): nomes usados nesta função
		var tijolo: Color = P.parede_baixa
		var argamassa: Color = P.parede_alta.darkened(0.5)
		var cinza: Color = P.movel
		var madeira: Color = P.madeira
		var ferrugem: Color = P.acento_a
		var musgo: Color = P.acento_b
		draw_rect(Rect2(-40, -40, 1360, 490), argamassa)
		for r in 17:
			for col in 27:
				var off: float = 26.0 * (r % 2)
				var br := Rect2(col * 52.0 - 40.0 - off, r * 28.0 - 6.0, 50, 26)
				var v: float = 0.015 * float((r * 7 + col * 3) % 4)
				draw_rect(br, Color(tijolo.r + v, tijolo.g + v * 0.6, tijolo.b + v * 0.5))
		_grad(Rect2(-40, -40, 1360, 300), Color(0, 0, 0.03, 0.45), Color(0, 0, 0.03, 0.0))
		# umidade e musgo na base da parede
		_grad(Rect2(-40, 330, 1360, 92), Color(0.1, 0.25, 0.2, 0.0), Color(0.1, 0.25, 0.2, 0.28))
		# canos com junta que goteja
		var cano: Color = cinza.lightened(0.5)
		draw_rect(Rect2(-40, 90, 1360, 16), cano)
		draw_rect(Rect2(-40, 90, 1360, 4), cano.lightened(0.25))
		draw_rect(Rect2(500, 90, 14, 70), cano)
		draw_rect(Rect2(930, 90, 14, 130), cano)
		for jx in [260.0, 440.0, 740.0, 930.0]:
			draw_rect(Rect2(jx - 6, 86, 26, 24), cano.darkened(0.2))
		_ci(Vector2(1030, 98), 11, Color(0.6, 0.15, 0.12))
		_ci(Vector2(1030, 98), 4, Color(0.3, 0.05, 0.05))
		# prateleira com potes (esquerda) e caixotes empilhados
		draw_rect(Rect2(-30, 224, 190, 6), Color(0.38, 0.27, 0.2))
		for k in 6:
			draw_rect(Rect2(-18 + k * 28.0, 196, 20, 28), Color(0.3, 0.45, 0.4, 0.8) if k % 2 == 0 else Color(0.6, 0.35, 0.25))
			draw_rect(Rect2(-18 + k * 28.0, 192, 20, 5), Color(0.7, 0.7, 0.6))
		_sombra(-30, 140, 40, -1.0, 0.3, 300.0)
		_caixa(Rect2(-30, 360, 100, 87), madeira)
		_caixa(Rect2(60, 392, 80, 55), madeira.darkened(0.1))
		_caixa(Rect2(-10, 300, 80, 60), madeira.darkened(0.05))
		# caldeira (direita, cortada) com visor de fogo; luz no centro: sombra para a direita
		_sombra(1090, 1330, 50, 1.0, 0.35, 190.0)
		_grad(Rect2(1090, 190, 250, 240), Color(0.22, 0.25, 0.3), Color(0.32, 0.35, 0.4))
		_contorno(Rect2(1090, 190, 250, 240), Color(0.06, 0.06, 0.08), 3.0)
		draw_rect(Rect2(1090, 230, 250, 6), Color(0.1, 0.1, 0.12))
		draw_rect(Rect2(1090, 390, 250, 6), Color(0.1, 0.1, 0.12))
		draw_rect(Rect2(1130, 330, 70, 48), Color(0.05, 0.03, 0.03))
		draw_rect(Rect2(1134, 346, 62, 28), Color(1.0, 0.5, 0.15, 0.7))
		_contorno(Rect2(1130, 330, 70, 48), Color(0.4, 0.4, 0.45), 2.5)
		_ci(Vector2(1260, 280), 24, Color(0.92, 0.88, 0.72))
		_ar(Vector2(1260, 280), 24, 0, TAU, 20, Color(0.08, 0.08, 0.1), 3.0)
		_ln(Vector2(1260, 280), Vector2(1274, 268), Color(0.75, 0.1, 0.1), 2.5)
		draw_rect(Rect2(1170, 100, 18, 92), cano)
		# janelinha gradeada no alto, luar fraco
		draw_rect(Rect2(780, 42, 120, 64), Color(0.45, 0.45, 0.5))
		draw_rect(Rect2(788, 50, 104, 48), Color(0.08, 0.12, 0.24))
		for k in 4:
			_ln(Vector2(802 + k * 25.0, 50), Vector2(802 + k * 25.0, 98), Color(0.3, 0.3, 0.34), 3.0)
		_feixe(Vector2(788, 98), Vector2(892, 98), Vector2(780, 440), Vector2(1000, 440), Color(0.6, 0.75, 1.0, 0.045))
		# teias
		_teia(Vector2(-40, 100), 1.0, 170.0)
		_teia(Vector2(1320, 110), -1.0, 130.0)
		_rodape(P.rodape)
		# toca de rato, grande
		_buraco(240, 446, 56)
		# laje de cimento com rachaduras e ralo (ver _piso)
		_piso(P)
		_mancha(Vector2(790, 452), Vector2(900, 452), Vector2(780, 640), Vector2(980, 640), Color(0.6, 0.75, 1.0, 0.025))
		_elipse(Vector2(440, 456), 40, 5, Color(0.15, 0.22, 0.32, 0.55))
		# frente: poça, lata, almofada
		_elipse(Vector2(1000, 700), 70, 10, Color(0.12, 0.18, 0.28, 0.45))
		draw_rect(Rect2(780, 684, 22, 26), ferrugem)
		_elipse(Vector2(791, 684), 11, 3, Color(0.7, 0.7, 0.7))
		_almofada(Vector2(320, 702), 60, musgo)
		_pote(Vector2(660, 704), 28, Color(0.55, 0.55, 0.6), Color(0.5, 0.3, 0.2))
		_sombra_vinheta()

	# ================================================================ CENAS DE FORA (ato 2: 6 a 10)
	func _estrelas(n: int, y_max: float, semente: int, cor: Color = Color(1, 1, 0.9, 0.8)) -> void:
		for k in n:
			var sx: float = fposmod(k * 197.0 + semente * 53.0, 1280.0)
			var sy: float = fposmod(k * 83.0 + semente * 29.0, y_max)
			if sy < 56.0 and sx < 360.0:
				continue   # fica fora da faixa do título da luta (um pixel pálido atrás do espaço do título)
			_ci(Vector2(sx, sy), 1.6, Color(cor.r, cor.g, cor.b, cor.a * (0.5 + 0.25 * float(k % 3))))

	func _montinho(x: float, y: float, r: float, terra: Color) -> void:
		# montinho de terra de toupeira: sombra, monte em dois tons, buraco no alto e torrões
		_elipse(Vector2(x + r * 0.2, y + r * 0.18), r * 1.15, r * 0.3, Color(0, 0, 0, 0.3))
		_elipse(Vector2(x, y), r, r * 0.5, terra.darkened(0.25))
		_elipse(Vector2(x, y - r * 0.12), r * 0.85, r * 0.4, terra)
		_elipse(Vector2(x, y - r * 0.3), r * 0.4, r * 0.15, Color(0.04, 0.02, 0.02))
		for k in 4:
			_ci(Vector2(x + (k - 1.5) * r * 0.5, y + r * 0.3 + (k % 2) * 4.0), 3.0, terra.lightened(0.15))

	func _lata_c(x: float, yb: float, w: float, h: float, cor: Color) -> void:
		draw_rect(Rect2(x, yb - h, w, h), cor)
		draw_rect(Rect2(x, yb - h, w, 4), cor.lightened(0.3))
		draw_rect(Rect2(x, yb - h * 0.62, w, h * 0.3), Color(0.9, 0.85, 0.7, 0.75))
		draw_rect(Rect2(x, yb - 4, w, 4), cor.darkened(0.35))
		draw_rect(Rect2(x + 4, yb - h, 4, h), Color(1, 1, 1, 0.12))

	# ---------------------------------------------------------------- 6 QUINTAL (entardecer, cerca, varal, canteiro)
	func _quintal() -> void:
		var P: Dictionary = Campo.paleta(6)
		var ceu: Color = P.parede_alta
		var tabua: Color = Campo.tom_lum(P.madeira, 0.215)
		var madeira: Color = P.madeira
		var rosa: Color = P.acento_a
		var amarelo: Color = P.acento_b
		var grama: Color = P.piso_a
		var terra: Color = Campo.tom_lum(Color(0.5, 0.34, 0.22), 0.26)
		var longe := Color(0.10, 0.10, 0.22)
		_grad(Rect2(-40, -40, 1360, 470), ceu, Color(0.60, 0.36, 0.42))
		_estrelas(26, 170.0, 6)
		_halo(Vector2(1040, 96), 70, Color(1.0, 0.95, 0.75, 0.03), 6)
		_ci(Vector2(1040, 96), 22, Color(1.0, 0.97, 0.82))
		_ci(Vector2(1052, 90), 19, Color(0.27, 0.225, 0.377))
		_elipse(Vector2(520, 190), 130, 11, Color(0.80, 0.52, 0.55, 0.35))
		_elipse(Vector2(820, 240), 160, 12, Color(0.80, 0.52, 0.55, 0.30))
		# casa do vizinho e copas de árvores atrás da cerca
		draw_rect(Rect2(600, 236, 200, 90), longe)
		draw_colored_polygon(PackedVector2Array([Vector2(586, 240), Vector2(814, 240), Vector2(700, 190)]), longe.darkened(0.15))
		draw_rect(Rect2(640, 262, 22, 28), Color(1.0, 0.82, 0.4, 0.9))
		draw_rect(Rect2(730, 262, 22, 28), Color(1.0, 0.82, 0.4, 0.9))
		for t in [Vector2(110, 296), Vector2(450, 280), Vector2(900, 290), Vector2(1210, 280)]:
			for k in 5:
				_ci(t + Vector2((k - 2) * 38.0, -absf(k - 2) * 12.0), 44, longe.darkened(0.2))
		# cerca de madeira: tábuas com ponta, duas travessas e pregos
		for k in 36:
			var px: float = -40.0 + k * 38.0
			var v: float = 0.012 * float((k * 5) % 4)
			var tc := Color(tabua.r + v, tabua.g + v * 0.7, tabua.b + v * 0.5)
			draw_rect(Rect2(px, 312, 34, 135), tc)
			draw_colored_polygon(PackedVector2Array([Vector2(px, 312), Vector2(px + 34, 312), Vector2(px + 17, 298)]), tc)
			draw_rect(Rect2(px, 312, 4, 135), tc.lightened(0.15))
			draw_rect(Rect2(px + 34, 298, 4, 149), Color(0.02, 0.02, 0.06, 0.8))
		for ry in [350.0, 410.0]:
			draw_rect(Rect2(-40, ry, 1360, 12), tabua.darkened(0.3))
			draw_rect(Rect2(-40, ry, 1360, 3), tabua.darkened(0.1))
			for k in 36:
				draw_rect(Rect2(-40.0 + k * 38.0 + 14.0, ry + 4, 4, 4), Color(0.05, 0.04, 0.05))
		_grad(Rect2(-40, 380, 1360, 67), Color(0, 0, 0.03, 0.0), Color(0, 0.03, 0.02, 0.5))
		# postes do varal (o varal e as roupas são animados)
		for pxv in [330.0, 990.0]:
			_sombra(pxv - 6.0, pxv + 8.0, 24, 1.0, 0.25, 150.0)
			draw_rect(Rect2(pxv - 6, 150, 12, 297), madeira.darkened(0.4))
			draw_rect(Rect2(pxv - 6, 150, 4, 297), madeira.darkened(0.2))
			var sg: float = -1.0 if pxv < 600.0 else 1.0
			_ln(Vector2(pxv, 190), Vector2(pxv + sg * 22.0, 156), madeira.darkened(0.4), 6.0)
		# canteiro com flores
		_sombra(560, 800, 18, 1.0, 0.25)
		draw_rect(Rect2(560, 424, 240, 23), Color(0.42, 0.22, 0.18))
		for k in 8:
			_contorno(Rect2(560 + k * 30.0, 424, 30, 23), Color(0.22, 0.1, 0.09), 1.0)
		draw_rect(Rect2(560, 398, 240, 28), terra.darkened(0.5))
		for k in 8:
			var fx: float = 578.0 + k * 29.0
			var alt: float = 38.0 + float((k * 7) % 4) * 13.0
			var tp := Vector2(fx, 398.0 - alt)
			_ln(Vector2(fx, 400), tp, Color(0.16, 0.36, 0.2), 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(fx, 396 - alt * 0.4), Vector2(fx + 14, 388 - alt * 0.4), Vector2(fx + 4, 400 - alt * 0.3)]), Color(0.18, 0.4, 0.22))
			var fc: Color = rosa if k % 2 == 0 else amarelo
			for pp in 5:
				var a: float = TAU * pp / 5.0
				_ci(tp + Vector2(cos(a), sin(a)) * 7.0, 5, fc)
			_ci(tp, 4, Color(0.95, 0.8, 0.3) if k % 2 == 0 else Color(0.4, 0.2, 0.15))
		# pé da cerca coberto de mato
		for k in 60:
			var gx: float = -40.0 + k * 23.0
			var gh: float = 14.0 + float((k * 7) % 3) * 5.0
			draw_colored_polygon(PackedVector2Array([Vector2(gx, 449), Vector2(gx + 16, 449), Vector2(gx + 6 + float(k % 3) * 3.0, 447.0 - gh)]), Color(0.10, 0.22, 0.11))
		# gramado em faixas de corte
		draw_rect(Rect2(-40, 447, 1360, 293), grama)
		var ys: Array = YS.duplicate()
		ys.append(740.0)
		for r in range(1, ys.size()):
			if r % 2 == 0:
				draw_rect(Rect2(-40, ys[r - 1], 1360, ys[r] - ys[r - 1]), P.piso_b)
		_elipse(Vector2(880, 545), 90, 12, Color(terra.r, terra.g, terra.b, 0.55))
		_elipse(Vector2(420, 600), 60, 9, Color(terra.r, terra.g, terra.b, 0.5))
		for k in 70:
			var tx: float = fposmod(k * 173.0, 1360.0) - 40.0
			var ty: float = 456.0 + fposmod(k * 97.0, 270.0)
			_ln(Vector2(tx, ty), Vector2(tx - 5, ty - 9), P.junta, 1.0)
			_ln(Vector2(tx, ty), Vector2(tx + 5, ty - 9), P.junta, 1.0)
		draw_rect(Rect2(-40, 447, 1360, 4), P.junta.darkened(0.3))
		# montinhos de toupeira (fundo e frente; o meio da faixa fica livre)
		_montinho(470, 466, 34, terra)
		_montinho(1050, 462, 28, terra)
		_montinho(760, 706, 38, terra)
		_montinho(1180, 456, 22, terra)
		# regador e mangueira na frente
		_elipse(Vector2(540, 716), 38, 8, Color(0, 0, 0, 0.3))
		draw_colored_polygon(PackedVector2Array([Vector2(512, 676), Vector2(566, 676), Vector2(560, 714), Vector2(518, 714)]), Color(0.32, 0.46, 0.66))
		draw_rect(Rect2(512, 676, 54, 4), Color(0.55, 0.7, 0.9))
		_ln(Vector2(564, 696), Vector2(596, 672), Color(0.32, 0.46, 0.66), 6.0)
		_ar(Vector2(530, 676), 16, PI, TAU, 10, Color(0.25, 0.38, 0.56), 4.0)
		_pl(PackedVector2Array([Vector2(300, 724), Vector2(380, 712), Vector2(450, 722), Vector2(500, 734)]), Color(0.16, 0.36, 0.2), 6.0)
		_sombra_vinheta()

	# ---------------------------------------------------------------- 7 GARAGEM (bloco, prateleiras, bicicleta, portão)
	func _garagem() -> void:
		var P: Dictionary = Campo.paleta(7)
		var metal: Color = Color(0.30, 0.35, 0.45)
		var madeira: Color = P.madeira
		var verm: Color = P.acento_a
		var amar: Color = P.acento_b
		_grad(Rect2(-40, -40, 1360, 462), P.parede_alta, P.parede_baixa)
		for r in 17:
			var yy: float = r * 28.0 + 4.0
			_ln(Vector2(-40, yy), Vector2(1320, yy), Color(0, 0, 0, 0.22), 2.0)
			var xj: float = -40.0 + (r % 2) * 32.0
			while xj < 1320.0:
				_ln(Vector2(xj, yy), Vector2(xj, yy + 28), Color(0, 0, 0, 0.16), 1.5)
				xj += 64.0
		# faixa de tinta mais escura na meia-parede
		draw_rect(Rect2(-40, 330, 1360, 92), Color(0.05, 0.07, 0.12, 0.35))
		draw_rect(Rect2(-40, 328, 1360, 4), Color(0.6, 0.65, 0.72, 0.18))
		# portão de enrolar (direita): caixa de enrolar, réguas e fresta de luz embaixo
		_sombra(860, 1240, 30, -1.0, 0.25, 110.0)
		draw_rect(Rect2(860, 100, 380, 26), metal.darkened(0.45))
		draw_rect(Rect2(860, 100, 380, 4), metal.darkened(0.2))
		var pr: float = 126.0
		var k2: int = 0
		while pr < 420.0:
			var rc: Color = metal.darkened(0.35) if k2 % 2 == 0 else metal.darkened(0.25)
			draw_rect(Rect2(866, pr, 368, 12), rc)
			draw_rect(Rect2(866, pr, 368, 3), rc.lightened(0.18))
			pr += 12.0
			k2 += 1
		draw_rect(Rect2(852, 100, 14, 322), metal.darkened(0.5))
		draw_rect(Rect2(1234, 100, 14, 322), metal.darkened(0.5))
		draw_rect(Rect2(866, 414, 368, 8), Color(0.55, 0.62, 0.45, 0.55))
		draw_rect(Rect2(1010, 396, 60, 10), metal.lightened(0.3))
		# lâmpada fluorescente (brilho animado)
		_ln(Vector2(500, 20), Vector2(500, 78), Color(0.15, 0.15, 0.18), 2.0)
		_ln(Vector2(760, 20), Vector2(760, 78), Color(0.15, 0.15, 0.18), 2.0)
		draw_rect(Rect2(470, 78, 320, 10), metal.darkened(0.35))
		draw_rect(Rect2(478, 88, 304, 10), Color(0.92, 0.98, 1.0))
		_halo(Vector2(630, 96), 190, Color(0.8, 0.92, 1.0, 0.016), 7)
		# painel de ferramentas
		draw_rect(Rect2(600, 134, 240, 110), madeira.darkened(0.2))
		_contorno(Rect2(600, 134, 240, 110), madeira.darkened(0.55), 2.0)
		for hx in range(612, 836, 24):
			for hy in range(146, 240, 24):
				draw_rect(Rect2(hx, hy, 4, 4), Color(0, 0, 0, 0.5))
		_ln(Vector2(630, 150), Vector2(630, 210), Color(0.62, 0.64, 0.7), 4.0)
		draw_rect(Rect2(618, 146, 26, 12), Color(0.5, 0.52, 0.58))
		draw_rect(Rect2(690, 150, 8, 56), Color(0.62, 0.64, 0.7))
		_ci(Vector2(694, 214), 12, Color(0.62, 0.64, 0.7))
		_ci(Vector2(694, 214), 5, madeira.darkened(0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(750, 150), Vector2(800, 150), Vector2(800, 190), Vector2(750, 210)]), Color(0.55, 0.58, 0.62))
		draw_rect(Rect2(740, 150, 12, 14), verm.darkened(0.2))
		# prateleiras de aço com latas e caixas (esquerda), cortadas pela torre
		_sombra(230, 570, 40, 1.0, 0.3, 120.0)
		for pxs in [230.0, 560.0]:
			draw_rect(Rect2(pxs, 120, 10, 327), metal)
			draw_rect(Rect2(pxs, 120, 3, 327), metal.lightened(0.2))
		for sy in [196.0, 288.0, 380.0]:
			draw_rect(Rect2(230, sy, 340, 8), metal.lightened(0.1))
			draw_rect(Rect2(230, sy + 8, 340, 3), Color(0, 0, 0, 0.35))
		var latas: Array[Color] = [verm, amar, Color(0.25, 0.45, 0.7), Color(0.3, 0.55, 0.35)]
		for k in 6:
			_lata_c(246.0 + k * 22.0, 196.0, 18.0, 26.0 + (k % 3) * 6.0, latas[k % 4])
		_caixa(Rect2(392, 148, 66, 48), madeira.darkened(0.1))
		_lata_c(472, 196, 34, 34, latas[1])
		_lata_c(512, 196, 30, 44, latas[0])
		_caixa(Rect2(250, 228, 80, 60), madeira.darkened(0.2))
		for k in 4:
			_lata_c(346.0 + k * 20.0, 288.0, 16.0, 22.0 + (k % 2) * 8.0, latas[(k + 2) % 4])
		_ci(Vector2(470, 270), 18, Color(0.5, 0.6, 0.7, 0.55))
		draw_rect(Rect2(462, 242, 16, 12), Color(0.5, 0.6, 0.7, 0.55))
		_caixa(Rect2(500, 236, 56, 52), madeira)
		_caixa(Rect2(244, 316, 110, 64), madeira.darkened(0.15))
		_caixa(Rect2(366, 330, 80, 50), madeira.darkened(0.05))
		_lata_c(466, 380, 38, 40, latas[3])
		_lata_c(512, 380, 34, 28, latas[2])
		# bicicleta encostada
		_elipse(Vector2(722, 449), 130, 6, Color(0, 0, 0, 0.3))
		var roda_ct: Array[Vector2] = [Vector2(650, 403), Vector2(790, 403)]
		for c in roda_ct:
			_ar(c, 44, 0, TAU, 28, Color(0.06, 0.06, 0.08), 8.0)
			_ar(c, 36, 0, TAU, 28, Color(0.55, 0.58, 0.64), 2.0)
			for sp in 8:
				var aa: float = TAU * sp / 8.0
				_ln(c, c + Vector2(cos(aa), sin(aa)) * 36.0, Color(0.6, 0.62, 0.68, 0.45), 1.0)
			_ci(c, 6, Color(0.7, 0.72, 0.78))
		var qd: Color = verm
		_ln(Vector2(650, 403), Vector2(692, 340), qd, 4.0)
		_ln(Vector2(650, 403), Vector2(710, 403), qd, 4.0)
		_ln(Vector2(710, 403), Vector2(692, 340), qd, 6.0)
		_ln(Vector2(692, 340), Vector2(770, 338), qd, 6.0)
		_ln(Vector2(710, 403), Vector2(770, 338), qd, 6.0)
		_ln(Vector2(770, 338), Vector2(790, 403), Color(0.55, 0.58, 0.64), 4.0)
		_ln(Vector2(770, 338), Vector2(778, 312), Color(0.55, 0.58, 0.64), 4.0)
		_ln(Vector2(764, 310), Vector2(802, 306), Color(0.15, 0.15, 0.18), 6.0)
		draw_colored_polygon(PackedVector2Array([Vector2(672, 332), Vector2(710, 330), Vector2(706, 340), Vector2(676, 342)]), Color(0.12, 0.1, 0.12))
		_ci(Vector2(710, 403), 9, Color(0.5, 0.52, 0.58))
		draw_rect(Rect2(706, 410, 8, 20), Color(0.15, 0.15, 0.18))
		_rodape(P.rodape)
		# cimento: piso com rachaduras e ralo; mancha de óleo, marcas de pneu e luz embaixo do portão
		_piso(P)
		_mancha(Vector2(880, 452), Vector2(1180, 452), Vector2(800, 640), Vector2(1250, 640), Color(0.8, 0.9, 0.6, 0.025))
		_elipse(Vector2(950, 540), 70, 11, Color(0.02, 0.02, 0.04, 0.35))
		_elipse(Vector2(950, 539), 40, 6, Color(0.1, 0.12, 0.2, 0.3))
		_pl(PackedVector2Array([Vector2(300, 490), Vector2(420, 520), Vector2(540, 600), Vector2(660, 640)]), Color(0, 0, 0, 0.14), 4.0)
		# frente: balde de tinta e chave inglesa
		_elipse(Vector2(520, 718), 34, 7, Color(0, 0, 0, 0.3))
		draw_rect(Rect2(494, 682, 52, 36), Color(0.6, 0.62, 0.68))
		draw_rect(Rect2(494, 682, 52, 6), Color(0.78, 0.8, 0.86))
		draw_rect(Rect2(494, 696, 52, 10), amar)
		_ar(Vector2(520, 682), 22, PI, TAU, 10, Color(0.3, 0.3, 0.34), 2.0)
		_ln(Vector2(660, 712), Vector2(740, 700), Color(0.55, 0.58, 0.64), 6.0)
		_ci(Vector2(660, 712), 8, Color(0.55, 0.58, 0.64))
		_sombra_vinheta()

	# ---------------------------------------------------------------- 8 TELHADO (telhas, chaminé, antena, lua, telhados ao fundo)
	func _telhado() -> void:
		var P: Dictionary = Campo.paleta(8)
		var ceu: Color = P.parede_alta
		var telha: Color = P.piso_a
		_grad(Rect2(-40, -40, 1360, 470), ceu, Color(0.17, 0.19, 0.42))
		_estrelas(60, 300.0, 8)
		var lc := Vector2(760, 130)
		_halo(lc, 140, Color(0.75, 0.82, 1.0, 0.02), 8)
		_ci(lc, 50, Color(0.97, 0.96, 0.86))
		for cr in [Vector2(-14, -12), Vector2(16, 8), Vector2(-6, 20), Vector2(20, -20)]:
			_ci(lc + cr, 8, Color(0.86, 0.85, 0.75))
		_elipse(Vector2(520, 150), 120, 10, Color(0.35, 0.38, 0.6, 0.30))
		_elipse(Vector2(950, 230), 150, 12, Color(0.35, 0.38, 0.6, 0.25))
		_elipse(Vector2(300, 260), 110, 9, Color(0.35, 0.38, 0.6, 0.25))
		# telhados ao fundo, em duas camadas, com janelas acesas
		var casas: Array = [[-20, 120, 70], [100, 90, 100], [210, 130, 60], [350, 100, 120], [470, 140, 80], [620, 90, 105], [720, 120, 60], [900, 150, 90], [1060, 110, 130], [1170, 140, 75]]
		for i in casas.size():
			var cs: Array = casas[i]
			var cx: float = cs[0]
			var cw: float = cs[1]
			var ch: float = cs[2]
			var cc: Color = Color(0.08, 0.09, 0.23) if i % 2 == 0 else Color(0.11, 0.12, 0.29)
			var topo: float = 436.0 - ch
			if i % 3 == 0:
				draw_rect(Rect2(cx + cw * 0.68, topo - 40, 16, 40), cc)
			draw_rect(Rect2(cx, topo, cw, ch + 12), cc)
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 8, topo + 2), Vector2(cx + cw + 8, topo + 2), Vector2(cx + cw * 0.5, topo - 26)]), cc.darkened(0.12))
			for w in 2:
				if (i + w) % 2 == 0:
					draw_rect(Rect2(cx + 16 + w * 40.0, topo + 22, 14, 18), Color(1.0, 0.82, 0.4, 0.85))
		# antena de TV
		_sombra(420, 440, 30, 1.0, 0.0)
		var ant: Color = Color(0.42, 0.47, 0.64)
		_ln(Vector2(430, 168), Vector2(430, 440), ant, 4.0)
		for k in 6:
			var ay: float = 188.0 + k * 24.0
			var hl: float = 54.0 - k * 6.0
			_ln(Vector2(430 - hl, ay), Vector2(430 + hl, ay), ant, 4.0)
			_ln(Vector2(430 - hl, ay - 8), Vector2(430 - hl, ay + 8), ant, 2.0)
			_ln(Vector2(430 + hl, ay - 8), Vector2(430 + hl, ay + 8), ant, 2.0)
		_ln(Vector2(430, 300), Vector2(340, 440), Color(ant.r, ant.g, ant.b, 0.55), 1.0)
		_ln(Vector2(430, 300), Vector2(520, 440), Color(ant.r, ant.g, ant.b, 0.55), 1.0)
		# chaminé de tijolo (fumaça animada)
		var tij: Color = Campo.tom_lum(Color(0.55, 0.28, 0.24), 0.2)
		_sombra(1010, 1100, 30, 1.0, 0.3, 240.0)
		draw_rect(Rect2(1010, 240, 90, 200), tij)
		for r in 12:
			var ry: float = 244.0 + r * 16.0
			_ln(Vector2(1010, ry), Vector2(1100, ry), tij.darkened(0.4), 1.0)
			var xj: float = 1010.0 + (r % 2) * 22.0
			while xj < 1100.0:
				_ln(Vector2(xj, ry), Vector2(xj, ry + 16), tij.darkened(0.4), 1.0)
				xj += 44.0
		draw_rect(Rect2(1010, 240, 8, 200), tij.lightened(0.18))
		draw_rect(Rect2(1000, 224, 110, 20), tij.lightened(0.12))
		draw_rect(Rect2(1000, 224, 110, 4), tij.lightened(0.35))
		_elipse(Vector2(1055, 226), 40, 6, Color(0.02, 0.02, 0.05))
		# cumeeira (linha do topo do telhado) com capas arredondadas
		draw_rect(Rect2(-40, 426, 1360, 21), telha.darkened(0.35))
		for k in 38:
			_elipse(Vector2(-40.0 + k * 36.0 + 18.0, 428), 19, 9, telha.darkened(0.15))
			_ln(Vector2(-40.0 + k * 36.0, 428), Vector2(-40.0 + k * 36.0, 447), telha.darkened(0.5), 1.0)
		draw_rect(Rect2(-40, 426, 1360, 3), telha.lightened(0.15))
		draw_rect(Rect2(-40, 442, 1360, 5), Color(0, 0, 0, 0.45))
		# telhas de barro em fileiras desencontradas (a perspectiva aumenta a fileira para a frente)
		draw_rect(Rect2(-40, 447, 1360, 293), telha)
		var ys: Array = YS.duplicate()
		ys.append(740.0)
		for r in range(1, ys.size()):
			var y0: float = ys[r - 1]
			var y1: float = ys[r]
			if r % 2 == 0:
				draw_rect(Rect2(-40, y0, 1360, y1 - y0), P.piso_b)
			var tw: float = 52.0 + (y1 - 447.0) * 0.2
			var xj: float = -40.0 + fmod(r * 31.0, tw)
			while xj < 1320.0:
				_ln(Vector2(xj, y0), Vector2(xj, y1), P.junta, 1.5)
				_ar(Vector2(xj + tw * 0.5, y1 - 2.0), tw * 0.5 - 3.0, 0.0, PI, 8, Color(P.junta.r, P.junta.g, P.junta.b, 0.8), 1.5)
				xj += tw
			_ln(Vector2(-40, y1), Vector2(1320, y1), P.junta.darkened(0.2), 2.0)
			_ln(Vector2(-40, y0 + 4), Vector2(1320, y0 + 4), telha.lightened(0.12), 1.0)
		# musgo, telha quebrada e luar
		_elipse(Vector2(640, 520), 70, 8, Color(0.2, 0.35, 0.28, 0.3))
		_elipse(Vector2(330, 610), 50, 7, Color(0.2, 0.35, 0.28, 0.3))
		draw_colored_polygon(PackedVector2Array([Vector2(880, 570), Vector2(930, 566), Vector2(918, 590), Vector2(886, 592)]), P.junta.darkened(0.45))
		_mancha(Vector2(560, 452), Vector2(760, 452), Vector2(460, 640), Vector2(760, 640), Color(0.6, 0.72, 1.0, 0.025))
		draw_rect(Rect2(-40, 447, 1360, 4), P.junta.darkened(0.3))
		# frente: calha com folhas
		draw_rect(Rect2(-40, 716, 1360, 24), telha.darkened(0.55))
		draw_rect(Rect2(-40, 716, 1360, 4), Color(0.45, 0.5, 0.65, 0.35))
		for k in 8:
			_elipse(Vector2(140.0 + k * 140.0, 726), 10, 4, Color(0.4, 0.28, 0.12))
		_sombra_vinheta()

	# ---------------------------------------------------------------- 9 RUA (muro, calçada, asfalto, poste, latas de lixo, hidrante)
	func _rua() -> void:
		var P: Dictionary = Campo.paleta(9)
		var ceu: Color = P.parede_alta
		var verm: Color = P.acento_a
		var muro: Color = Campo.tom_lum(Color(0.5, 0.32, 0.28), 0.19)
		_grad(Rect2(-40, -40, 1360, 340), ceu, Color(0.24, 0.16, 0.30))
		_estrelas(16, 120.0, 9)
		_ci(Vector2(480, 70), 14, Color(1.0, 0.97, 0.85))
		_ci(Vector2(488, 66), 12, Color(0.12, 0.1, 0.24))
		# prédios ao fundo com janelas
		var preds: Array = [[-20, 130, 140], [120, 100, 90], [230, 150, 170], [390, 110, 110], [510, 140, 200], [660, 100, 130], [770, 160, 90], [940, 120, 180], [1070, 110, 120], [1190, 150, 160]]
		for i in preds.size():
			var pd: Array = preds[i]
			var bx: float = pd[0]
			var bw: float = pd[1]
			var topo: float = 300.0 - float(pd[2])
			var bc: Color = Color(0.08, 0.08, 0.18) if i % 2 == 0 else Color(0.12, 0.11, 0.24)
			draw_rect(Rect2(bx, topo, bw, 300.0 - topo + 10), bc)
			var wy: float = topo + 14.0
			while wy < 280.0:
				var wx: float = bx + 12.0
				while wx < bx + bw - 18.0:
					var h: int = (int(wx) * 7 + int(wy) * 3 + i) % 5
					var wc: Color = Color(0.05, 0.05, 0.12)
					if h == 0:
						wc = Color(1.0, 0.8, 0.4, 0.9)
					elif h == 1:
						wc = Color(0.5, 0.7, 1.0, 0.75)
					draw_rect(Rect2(wx, wy, 14, 18), wc)
					wx += 30.0
				wy += 40.0
		# muro de tijolo com capa de concreto e pilares
		_sombra(-40, 1320, 0, 1.0, 0.0)
		draw_rect(Rect2(-40, 300, 1360, 147), muro)
		for r in 5:
			var yy: float = 316.0 + r * 22.0
			_ln(Vector2(-40, yy), Vector2(1320, yy), muro.darkened(0.4), 1.0)
			var xj: float = -40.0 + (r % 2) * 30.0
			while xj < 1320.0:
				_ln(Vector2(xj, yy - 22), Vector2(xj, yy), muro.darkened(0.4), 1.0)
				xj += 60.0
		draw_rect(Rect2(-40, 292, 1360, 14), muro.lightened(0.3))
		draw_rect(Rect2(-40, 292, 1360, 3), muro.lightened(0.55))
		for px in [180.0, 520.0, 900.0, 1240.0]:
			draw_rect(Rect2(px, 288, 28, 142), muro.lightened(0.15))
			draw_rect(Rect2(px - 4, 284, 36, 10), muro.lightened(0.4))
		_grad(Rect2(-40, 380, 1360, 50), Color(0, 0, 0.03, 0.0), Color(0, 0, 0.03, 0.45))
		# cartaz de peixe rasgado e pichação
		draw_rect(Rect2(560, 330, 70, 74), Color(0.62, 0.6, 0.5))
		draw_colored_polygon(PackedVector2Array([Vector2(566, 352), Vector2(595, 342), Vector2(618, 366), Vector2(595, 390), Vector2(566, 380)]), Color(0.3, 0.4, 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(566, 366), Vector2(556, 350), Vector2(556, 382)]), Color(0.3, 0.4, 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(630, 330), Vector2(630, 354), Vector2(612, 330)]), muro)
		_pl(PackedVector2Array([Vector2(260, 360), Vector2(290, 330), Vector2(310, 370), Vector2(340, 336)]), Color(0.3, 0.7, 0.6, 0.6), 4.0)
		_ci(Vector2(780, 350), 14, Color(0.8, 0.3, 0.5, 0.55))
		_ci(Vector2(780, 350), 7, muro)
		# poste de luz (lâmpada e luz animadas)
		_sombra(634, 650, 30, 1.0, 0.25, 100.0)
		var ferro: Color = Color(0.18, 0.2, 0.26)
		draw_rect(Rect2(634, 100, 14, 350), ferro)
		draw_rect(Rect2(634, 100, 4, 350), ferro.lightened(0.25))
		draw_rect(Rect2(626, 410, 30, 40), ferro.darkened(0.1))
		_ln(Vector2(641, 104), Vector2(660, 88), ferro, 8.0)
		_ln(Vector2(660, 88), Vector2(704, 86), ferro, 8.0)
		draw_colored_polygon(PackedVector2Array([Vector2(680, 84), Vector2(728, 84), Vector2(736, 96), Vector2(672, 96)]), ferro.lightened(0.1))
		draw_rect(Rect2(684, 96, 40, 6), Color(1.0, 0.9, 0.6))
		# latas de lixo
		_sombra(240, 410, 30, 1.0, 0.3, 360.0)
		var lata: Color = Color(0.30, 0.32, 0.36)
		draw_rect(Rect2(240, 372, 80, 75), lata)
		for k in 7:
			_ln(Vector2(248.0 + k * 11.0, 380), Vector2(248.0 + k * 11.0, 444), lata.darkened(0.3), 1.0)
		draw_rect(Rect2(240, 372, 5, 75), lata.lightened(0.2))
		draw_rect(Rect2(234, 366, 92, 10), lata.lightened(0.15))
		draw_colored_polygon(PackedVector2Array([Vector2(246, 364), Vector2(326, 346), Vector2(330, 354), Vector2(250, 372)]), lata.lightened(0.05))
		_ln(Vector2(284, 372), Vector2(292, 352), Color(0.7, 0.7, 0.62), 2.0)
		_ci(Vector2(278, 370), 4, Color(0.7, 0.7, 0.62))
		var verde: Color = Color(0.18, 0.36, 0.26)
		draw_rect(Rect2(338, 392, 66, 55), verde)
		draw_rect(Rect2(334, 388, 74, 8), verde.lightened(0.2))
		draw_rect(Rect2(338, 392, 4, 55), verde.lightened(0.2))
		_elipse(Vector2(430, 436), 22, 15, Color(0.04, 0.04, 0.07))
		_ci(Vector2(430, 418), 5, Color(0.04, 0.04, 0.07))
		_ln(Vector2(430, 418), Vector2(442, 412), Color(0.04, 0.04, 0.07), 2.0)
		# hidrante
		_sombra(1060, 1100, 24, 1.0, 0.3, 390.0)
		draw_rect(Rect2(1060, 432, 40, 15), verm.darkened(0.35))
		draw_rect(Rect2(1066, 394, 28, 40), verm)
		draw_rect(Rect2(1066, 394, 5, 40), verm.lightened(0.3))
		_elipse(Vector2(1080, 394), 14, 12, verm)
		draw_rect(Rect2(1074, 372, 12, 10), P.acento_b)
		draw_rect(Rect2(1052, 406, 14, 14), verm.darkened(0.1))
		draw_rect(Rect2(1094, 406, 14, 14), verm.darkened(0.1))
		draw_rect(Rect2(1048, 408, 6, 10), P.acento_b)
		draw_rect(Rect2(1106, 408, 6, 10), P.acento_b)
		# calçada em lajes, meio-fio e asfalto
		draw_rect(Rect2(-40, 447, 1360, 100), P.piso_a)
		var ys: Array = [447.0, 466.0, 490.0, 520.0, 548.0]
		for r in range(1, ys.size()):
			var y0: float = ys[r - 1]
			var y1: float = ys[r]
			if r % 2 == 0:
				draw_rect(Rect2(-40, y0, 1360, y1 - y0), P.piso_b)
			_ln(Vector2(-40, y1), Vector2(1320, y1), P.junta, 1.5)
			var passo: float = 100.0 + (y1 - y0) * 3.0
			var xj: float = -40.0 + (r * 71) % int(passo)
			while xj < 1320.0:
				_ln(Vector2(xj, y0), Vector2(xj, y1), P.junta, 1.5)
				xj += passo
		_pl(PackedVector2Array([Vector2(820, 470), Vector2(840, 500), Vector2(830, 534)]), P.junta.darkened(0.15), 2.0)
		draw_rect(Rect2(-40, 447, 1360, 4), P.junta.darkened(0.3))
		var asf: Color = P.tapete_meio
		draw_rect(Rect2(-40, 556, 1360, 190), asf)
		draw_rect(Rect2(-40, 540, 1360, 14), P.piso_a.lightened(0.18))
		draw_rect(Rect2(-40, 540, 1360, 3), P.piso_a.lightened(0.4))
		draw_rect(Rect2(-40, 554, 1360, 4), Color(0, 0, 0, 0.5))
		for k in 80:
			var sx: float = fposmod(k * 211.0, 1360.0) - 40.0
			var sy: float = 562.0 + fposmod(k * 61.0, 170.0)
			draw_rect(Rect2(sx, sy, 4, 4), asf.lightened(0.12) if k % 2 == 0 else asf.darkened(0.2))
		draw_rect(Rect2(700, 580, 120, 40), asf.darkened(0.1))
		_pl(PackedVector2Array([Vector2(300, 570), Vector2(330, 600), Vector2(320, 636), Vector2(360, 660)]), asf.darkened(0.3), 2.0)
		for k in 9:
			draw_rect(Rect2(40.0 + k * 160.0, 688, 84, 8), Color(0.85, 0.78, 0.5, 0.55))
		_elipse(Vector2(560, 712), 80, 9, Color(0.2, 0.28, 0.45, 0.35))
		_elipse(Vector2(700, 456), 120, 14, Color(1.0, 0.78, 0.4, 0.04))
		_sombra_vinheta()

	# ---------------------------------------------------------------- 10 TOCA (túnel de terra, raízes, lanternas, coisas roubadas)
	func _toca() -> void:
		var P: Dictionary = Campo.paleta(10)
		var terra: Color = P.parede_alta
		var terra2: Color = P.parede_baixa
		var madeira: Color = P.madeira
		var raiz: Color = Color(0.46, 0.31, 0.18)
		var ouro: Color = P.acento_b
		_grad(Rect2(-40, -40, 1360, 490), terra, terra2)
		for k in 7:
			var pts := PackedVector2Array()
			for j in 15:
				pts.append(Vector2(-40.0 + j * 100.0, 120.0 + k * 52.0 + sin(j * 0.9 + k * 1.7) * 12.0))
			_pl(pts, Color(0, 0, 0, 0.16), 3.0)
		for k in 110:
			var sx: float = fposmod(k * 173.0, 1360.0) - 40.0
			var sy: float = fposmod(k * 91.0, 410.0) + 20.0
			var sz: float = 4.0 + float(k % 3) * 4.0
			draw_rect(Rect2(sx, sy, sz, sz * 0.7), terra2.lightened(0.18) if k % 2 == 0 else terra.darkened(0.3))
		# teto irregular e raízes penduradas
		var teto := PackedVector2Array([Vector2(-40, -40), Vector2(1320, -40), Vector2(1320, 70), Vector2(1200, 92), Vector2(1050, 60), Vector2(900, 100), Vector2(760, 64), Vector2(600, 96), Vector2(450, 60), Vector2(300, 100), Vector2(150, 66), Vector2(0, 92), Vector2(-40, 70)])
		draw_colored_polygon(teto, Color(0.06, 0.035, 0.025))
		_pl(teto.slice(3, 12), Color(0.2, 0.12, 0.08), 4.0)
		for k in 17:
			var x0: float = 20.0 + k * 78.0 + float((k * 37) % 30)
			var ln: float = 70.0 + float((k * 53) % 110)
			var pa := Vector2(x0, 80.0)
			for sgm in 6:
				var pb: Vector2 = pa + Vector2(sin(k * 1.3 + sgm * 0.9) * 9.0, ln / 6.0)
				_ln(pa, pb, raiz if k % 2 == 0 else raiz.darkened(0.25), 5.0 if sgm < 3 else 2.0)
				if sgm == 2:
					_ln(pb, pb + Vector2(14.0 - (k % 3) * 12.0, 22), raiz.darkened(0.2), 1.0)
				pa = pb
		# escoras de madeira
		for ex in [470.0, 810.0]:
			_sombra(ex, ex + 18.0, 20, 1.0, 0.25, 70.0)
			draw_rect(Rect2(ex, 60, 18, 387), madeira.darkened(0.3))
			draw_rect(Rect2(ex, 60, 5, 387), madeira.darkened(0.05))
			for k in 6:
				_ln(Vector2(ex + 4, 100 + k * 56.0), Vector2(ex + 14, 112 + k * 56.0), Color(0, 0, 0, 0.35), 1.0)
		draw_rect(Rect2(440, 60, 410, 24), madeira.darkened(0.3))
		draw_rect(Rect2(440, 60, 410, 5), madeira.darkened(0.05))
		# boca do túnel mais fundo
		draw_rect(Rect2(540, 276, 14, 171), madeira.darkened(0.35))
		draw_rect(Rect2(726, 276, 14, 171), madeira.darkened(0.35))
		draw_rect(Rect2(532, 258, 216, 22), madeira.darkened(0.25))
		draw_rect(Rect2(532, 258, 216, 4), madeira.darkened(0.05))
		_grad(Rect2(554, 280, 172, 167), Color(0.07, 0.04, 0.03), Color(0.01, 0.005, 0.005))
		_ci(Vector2(618, 380), 3, Color(1.0, 0.8, 0.3, 0.85))
		_ci(Vector2(642, 380), 3, Color(1.0, 0.8, 0.3, 0.85))
		# lanternas penduradas por correntes (brilho animado)
		for lx in [340.0, 940.0]:
			_ln(Vector2(lx, 80), Vector2(lx, 170), Color(0.22, 0.2, 0.2), 2.0)
			draw_rect(Rect2(lx - 14, 166, 28, 6), Color(0.2, 0.18, 0.18))
			draw_rect(Rect2(lx - 12, 172, 24, 34), Color(1.0, 0.78, 0.3))
			draw_rect(Rect2(lx - 4, 180, 8, 18), Color(1.0, 0.95, 0.6))
			_contorno(Rect2(lx - 12, 172, 24, 34), Color(0.2, 0.15, 0.1), 2.0)
			draw_rect(Rect2(lx - 14, 206, 28, 6), Color(0.2, 0.18, 0.18))
			_halo(Vector2(lx, 190), 110, Color(1.0, 0.65, 0.25, 0.018), 6)
		# pilha de coisas roubadas, à esquerda: meias, relógio, livros, coroa
		_sombra(215, 450, 30, 1.0, 0.0)
		_elipse(Vector2(330, 447), 130, 60, Color(0.28, 0.2, 0.3))
		_elipse(Vector2(330, 438), 112, 44, Color(0.38, 0.28, 0.4))
		_elipse(Vector2(290, 410), 38, 14, Color(0.7, 0.3, 0.3))
		_elipse(Vector2(385, 416), 34, 12, Color(0.3, 0.5, 0.65))
		for k in 3:
			draw_rect(Rect2(366.0 + (k % 2) * 4.0, 392 - k * 12.0, 40, 12), [Color(0.5, 0.2, 0.2), Color(0.25, 0.4, 0.3), Color(0.5, 0.4, 0.2)][k])
		_ci(Vector2(262, 388), 18, Color(0.88, 0.82, 0.65))
		_ar(Vector2(262, 388), 18, 0, TAU, 16, Color(0.4, 0.28, 0.15), 3.0)
		_ln(Vector2(262, 388), Vector2(262, 376), Color(0.2, 0.12, 0.1), 2.0)
		_ln(Vector2(262, 388), Vector2(272, 392), Color(0.2, 0.12, 0.1), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(310, 392), Vector2(350, 392), Vector2(354, 366), Vector2(340, 378), Vector2(330, 360), Vector2(320, 378), Vector2(306, 366)]), ouro)
		draw_rect(Rect2(310, 388, 40, 5), ouro.darkened(0.3))
		for k in 7:
			_ci(Vector2(236.0 + k * 22.0, 440.0 + (k % 2) * 4.0), 4, ouro)
		# pilha de coisas roubadas, à direita: almofada, abajur, bota, ursinho, colher
		_sombra(870, 1170, 30, 1.0, 0.0)
		_elipse(Vector2(1020, 447), 150, 74, Color(0.3, 0.22, 0.16))
		_elipse(Vector2(1020, 436), 128, 52, Color(0.42, 0.3, 0.2))
		draw_rect(Rect2(920, 372, 66, 40), Color(0.78, 0.4, 0.5))
		_contorno(Rect2(920, 372, 66, 40), Color(0.4, 0.15, 0.25), 2.0)
		draw_rect(Rect2(1010, 380, 10, 36), Color(0.5, 0.45, 0.4))
		draw_colored_polygon(PackedVector2Array([Vector2(990, 384), Vector2(1040, 384), Vector2(1032, 354), Vector2(998, 354)]), Color(0.95, 0.85, 0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(1056, 416), Vector2(1082, 416), Vector2(1086, 384), Vector2(1074, 372), Vector2(1058, 384)]), Color(0.3, 0.2, 0.15))
		draw_rect(Rect2(1052, 410, 38, 8), Color(0.18, 0.12, 0.1))
		_ci(Vector2(1120, 412), 16, Color(0.55, 0.38, 0.25))
		_ci(Vector2(1108, 396), 7, Color(0.55, 0.38, 0.25))
		_ci(Vector2(1132, 396), 7, Color(0.55, 0.38, 0.25))
		_ci(Vector2(1120, 416), 7, Color(0.7, 0.55, 0.4))
		_ln(Vector2(956, 424), Vector2(996, 404), Color(0.78, 0.78, 0.8), 4.0)
		_ci(Vector2(950, 428), 7, Color(0.78, 0.78, 0.8))
		for k in 6:
			_ci(Vector2(930.0 + k * 24.0, 442.0 + (k % 2) * 6.0), 4, ouro)
		# chão de terra batida
		draw_rect(Rect2(-40, 447, 1360, 293), P.piso_a)
		for k in 24:
			var ex2: float = fposmod(k * 211.0, 1400.0) - 60.0
			var ey: float = 470.0 + fposmod(k * 67.0, 250.0)
			_elipse(Vector2(ex2, ey), 60.0 + float(k % 4) * 20.0, 8.0 + float(k % 3) * 3.0, Color(P.piso_b.r, P.piso_b.g, P.piso_b.b, 0.7))
		for k in 80:
			var sx2: float = fposmod(k * 197.0, 1360.0) - 40.0
			var sy2: float = 460.0 + fposmod(k * 83.0, 270.0)
			draw_rect(Rect2(sx2, sy2, 8, 4), P.junta)
			draw_rect(Rect2(sx2 + 2, sy2 - 4, 4, 4), P.piso_a.lightened(0.1))
		_pl(PackedVector2Array([Vector2(240, 520), Vector2(480, 560), Vector2(720, 548), Vector2(980, 590)]), Color(P.junta.r, P.junta.g, P.junta.b, 0.7), 2.0)
		draw_rect(Rect2(-40, 447, 1360, 4), P.junta.darkened(0.35))
		# frente: moedas caídas e pedrinhas
		for k in 8:
			_ci(Vector2(420.0 + k * 38.0, 700.0 + float((k * 7) % 3) * 8.0), 4, ouro)
		_sombra_vinheta()


	# ================================================================ CENAS DO 3º ATO (11 a 15: as ruas das gangues)
	## Peixe de lado (olha para o lado `dir`): corpo oval, cauda, barriga clara e olho. `c` é o centro do corpo.
	func _peixe(c: Vector2, comp: float, dir: float, cor: Color) -> void:
		_elipse(c, comp * 0.5, comp * 0.2, cor)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-dir * comp * 0.42, 0), c + Vector2(-dir * comp * 0.74, -comp * 0.22), c + Vector2(-dir * comp * 0.74, comp * 0.22)]), cor.darkened(0.2))
		_elipse(c + Vector2(0, comp * 0.09), comp * 0.38, comp * 0.09, cor.lightened(0.35))
		_ci(c + Vector2(dir * comp * 0.3, -comp * 0.05), 3.0, Color(0.05, 0.05, 0.08))

	## Peixe pendurado pelo focinho (cabeça em cima).
	func _peixe_v(c: Vector2, comp: float, cor: Color) -> void:
		_elipse(c, comp * 0.17, comp * 0.5, cor)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, comp * 0.42), c + Vector2(-comp * 0.2, comp * 0.78), c + Vector2(comp * 0.2, comp * 0.78)]), cor.darkened(0.2))
		_elipse(c + Vector2(comp * 0.05, comp * 0.1), comp * 0.07, comp * 0.28, cor.lightened(0.35))
		_ci(c + Vector2(0, -comp * 0.3), 3.0, Color(0.05, 0.05, 0.08))

	## Toldo listrado de barraca: trapézio que desce para a frente, listras alternadas e barra recortada.
	func _toldo(x0: float, x1: float, ytop: float, ybase: float, n: int, c1: Color, c2: Color) -> void:
		var rec: float = 26.0
		for i in n:
			var u0: float = float(i) / n
			var u1: float = float(i + 1) / n
			var cc: Color = c1 if i % 2 == 0 else c2
			var t0: float = lerpf(x0 + rec, x1 - rec, u0)
			var t1: float = lerpf(x0 + rec, x1 - rec, u1)
			var b0: float = lerpf(x0, x1, u0)
			var b1: float = lerpf(x0, x1, u1)
			draw_colored_polygon(PackedVector2Array([Vector2(t0, ytop), Vector2(t1, ytop), Vector2(b1, ybase), Vector2(b0, ybase)]), cc)
			_elipse(Vector2((b0 + b1) * 0.5, ybase), (b1 - b0) * 0.5, 9.0, cc)
		draw_rect(Rect2(x0 + rec, ytop - 4, x1 - x0 - 2.0 * rec, 5), c2.lightened(0.2))
		_ln(Vector2(x0 + 4.0, ybase + 10.0), Vector2(x1 - 4.0, ybase + 10.0), Color(0, 0, 0, 0.25), 2.0)

	## Caixote de madeira com gelo picado em cima e peixes espiando.
	func _caixote_gelo(x: float, yb: float, w: float, h: float, mad: Color, peixes: int, semente: int) -> void:
		draw_rect(Rect2(x, yb - h, w, h), mad)
		for k in 2:
			_ln(Vector2(x, yb - h + (k + 1) * h / 3.0), Vector2(x + w, yb - h + (k + 1) * h / 3.0), mad.darkened(0.35), 1.0)
		_contorno(Rect2(x, yb - h, w, h), mad.darkened(0.55), 2.0)
		draw_rect(Rect2(x, yb - h, w, 4), mad.lightened(0.15))
		var gelo := Color(0.66, 0.86, 0.94)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 2, yb - h), Vector2(x + 8, yb - h - 12), Vector2(x + w * 0.35, yb - h - 8), Vector2(x + w * 0.6, yb - h - 16), Vector2(x + w - 6, yb - h - 8), Vector2(x + w + 2, yb - h)]), gelo)
		for k in 4:
			draw_rect(Rect2(x + 4.0 + k * (w - 16.0) / 4.0, yb - h - 12.0 - float(k % 2) * 4.0, 8, 8), Color(0.88, 0.97, 1.0, 0.9))
		var cores: Array[Color] = [Color(0.62, 0.72, 0.82), Color(0.9, 0.5, 0.42), Color(0.9, 0.78, 0.35)]
		for k in peixes:
			var fx: float = x + 22.0 + float(k) * (w - 44.0) / maxf(float(peixes - 1), 1.0)
			_peixe(Vector2(fx, yb - h - 10.0 - float((k + semente) % 2) * 6.0), 34.0, 1.0 if (k + semente) % 2 == 0 else -1.0, cores[(k + semente) % 3])

	## Barraca do mercado: poste, fundo escuro com peixes pendurados, toldo listrado e balcão com bandeja de gelo.
	func _barraca(x0: float, x1: float, c1: Color, c2: Color, mad: Color, semente: int) -> void:
		_sombra(x0, x1, 30, 1.0, 0.25)
		draw_rect(Rect2(x0 + 8, 288, x1 - x0 - 16, 100), Color(0.04, 0.06, 0.09))
		_ln(Vector2(x0 + 8, 304), Vector2(x1 - 8, 304), Color(0.5, 0.55, 0.6), 2.0)
		var cores: Array[Color] = [Color(0.62, 0.72, 0.82), Color(0.9, 0.5, 0.42), Color(0.9, 0.78, 0.35), Color(0.5, 0.7, 0.62)]
		var n: int = int((x1 - x0 - 50.0) / 44.0)
		for k in n:
			var fx: float = x0 + 38.0 + k * 44.0
			_ln(Vector2(fx, 304), Vector2(fx, 318), Color(0.7, 0.7, 0.75), 1.0)
			_peixe_v(Vector2(fx, 340.0 + float((k * 3 + semente) % 3) * 5.0), 44.0, cores[(k + semente) % 4])
		for px in [x0, x1 - 10.0]:
			draw_rect(Rect2(px, 232, 10, 215), mad.darkened(0.25))
			draw_rect(Rect2(px, 232, 3, 215), mad.lightened(0.05))
		_toldo(x0 - 10.0, x1 + 10.0, 226.0, 290.0, 8, c1, c2)
		draw_rect(Rect2(x0, 386, x1 - x0, 61), mad)
		for k in 4:
			var lx: float = x0 + float(k + 1) * (x1 - x0) / 5.0
			_ln(Vector2(lx, 392), Vector2(lx, 447), mad.darkened(0.4), 1.0)
		draw_rect(Rect2(x0 - 8, 378, x1 - x0 + 16, 10), mad.lightened(0.2))
		draw_rect(Rect2(x0 - 8, 378, x1 - x0 + 16, 3), mad.lightened(0.4))
		draw_colored_polygon(PackedVector2Array([Vector2(x0 + 8, 378), Vector2(x0 + 16, 364), Vector2(x1 - 16, 362), Vector2(x1 - 8, 378)]), Color(0.62, 0.82, 0.9))
		for k in 5:
			_peixe(Vector2(x0 + 40.0 + k * 52.0, 366.0 - float((k + semente) % 2) * 3.0), 38.0, 1.0 if (k + semente) % 2 == 0 else -1.0, cores[(k + semente + 1) % 4])

	# ---------------------------------------------------------------- 11 MERCADÃO DO PEIXE (madrugada, cais, barracas listradas, gelo, carro preto)
	func _mercado() -> void:
		var P: Dictionary = Campo.paleta(11)
		var vinho: Color = P.acento_a
		var creme: Color = P.acento_b
		var mad: Color = P.madeira
		var longe := Color(0.04, 0.08, 0.12)
		_grad(Rect2(-40, -40, 1360, 340), P.parede_alta, Color(0.16, 0.30, 0.38))
		_estrelas(30, 190.0, 11)
		_ci(Vector2(470, 84), 20, Color(0.92, 0.96, 0.88))
		_ci(Vector2(481, 78), 17, Color(0.085, 0.17, 0.235))
		# água do porto com o reflexo da lua
		_grad(Rect2(-40, 300, 1360, 74), Color(0.07, 0.15, 0.21), Color(0.04, 0.09, 0.14))
		for k in 5:
			_ln(Vector2(452.0 + (k % 2) * 10.0, 308.0 + k * 11.0), Vector2(494.0 - k * 4.0, 308.0 + k * 11.0), Color(0.85, 0.95, 0.9, 0.3), 1.0)
		# navio no cais da esquerda
		draw_colored_polygon(PackedVector2Array([Vector2(90, 330), Vector2(430, 330), Vector2(400, 372), Vector2(130, 372)]), longe)
		draw_rect(Rect2(170, 290, 120, 40), longe.lightened(0.04))
		draw_rect(Rect2(200, 268, 60, 24), longe)
		draw_rect(Rect2(246, 238, 12, 32), longe)
		for k in 4:
			draw_rect(Rect2(182.0 + k * 26.0, 304, 12, 10), Color(1.0, 0.82, 0.4, 0.8))
		# contêineres empilhados na direita
		var cont: Array[Color] = [Color(0.34, 0.12, 0.14), Color(0.12, 0.24, 0.30), Color(0.30, 0.24, 0.10)]
		for k in 6:
			var cx2: float = 1000.0 + (k % 3) * 96.0
			var cy2: float = 338.0 - floorf(k / 3.0) * 36.0
			draw_rect(Rect2(cx2, cy2, 92, 34), cont[k % 3])
			for r in 4:
				_ln(Vector2(cx2 + 12.0 + r * 22.0, cy2 + 2), Vector2(cx2 + 12.0 + r * 22.0, cy2 + 32), cont[k % 3].darkened(0.35), 1.0)
			draw_rect(Rect2(cx2, cy2, 92, 3), cont[k % 3].lightened(0.2))
		# guindaste do cais (a luz vermelha pisca no animado)
		var gui := Color(0.06, 0.11, 0.15)
		for lx in [884.0, 936.0]:
			draw_rect(Rect2(lx, 124, 6, 250), gui)
		for k in 6:
			var gy: float = 130.0 + k * 40.0
			_ln(Vector2(890, gy), Vector2(938, gy + 40), gui, 1.0)
			_ln(Vector2(938, gy), Vector2(890, gy + 40), gui, 1.0)
		draw_rect(Rect2(640, 112, 420, 10), gui)
		draw_rect(Rect2(880, 96, 64, 32), gui.lightened(0.04))
		draw_rect(Rect2(1040, 104, 40, 28), gui.lightened(0.05))
		_ln(Vector2(912, 96), Vector2(650, 114), gui, 1.0)
		_ln(Vector2(700, 122), Vector2(700, 236), Color(0.12, 0.18, 0.22), 1.0)
		draw_rect(Rect2(682, 236, 36, 18), Color(0.34, 0.12, 0.14))
		draw_rect(Rect2(682, 236, 36, 3), Color(0.5, 0.2, 0.2))
		# muro do cais com cabeços de amarração
		draw_rect(Rect2(-40, 372, 1360, 75), P.parede_baixa)
		draw_rect(Rect2(-40, 372, 1360, 6), P.parede_baixa.lightened(0.35))
		for k in 12:
			_ln(Vector2(-40.0 + k * 120.0, 378), Vector2(-40.0 + k * 120.0, 447), P.parede_baixa.darkened(0.3), 1.0)
		_grad(Rect2(-40, 400, 1360, 47), Color(0, 0, 0.04, 0.0), Color(0, 0, 0.04, 0.4))
		for bx in [130.0, 1220.0]:
			draw_rect(Rect2(bx - 10, 424, 20, 23), Color(0.12, 0.16, 0.2))
			draw_rect(Rect2(bx - 16, 418, 32, 8), Color(0.2, 0.26, 0.3))
		# barraca da esquerda
		_barraca(250.0, 560.0, vinho, creme, mad, 0)
		_caixote_gelo(266.0, 447.0, 72.0, 52.0, mad, 3, 0)
		_caixote_gelo(274.0, 395.0, 56.0, 42.0, mad, 2, 1)
		_caixote_gelo(470.0, 447.0, 78.0, 48.0, mad, 3, 2)
		# poste de luz entre as barracas
		_sombra(576, 592, 24, 1.0, 0.25)
		var ferro := Color(0.14, 0.17, 0.22)
		draw_rect(Rect2(578, 134, 10, 313), ferro)
		draw_rect(Rect2(578, 134, 3, 313), ferro.lightened(0.25))
		_ln(Vector2(584, 138), Vector2(640, 130), ferro, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(618, 128), Vector2(668, 128), Vector2(674, 142), Vector2(612, 142)]), ferro.lightened(0.1))
		draw_rect(Rect2(622, 142, 46, 5), Color(1.0, 0.92, 0.65))
		# carro preto parado, de lado
		var pr := Color(0.02, 0.025, 0.04)
		_elipse(Vector2(712, 448), 108, 6, Color(0, 0, 0, 0.35))
		draw_colored_polygon(PackedVector2Array([Vector2(612, 432), Vector2(612, 410), Vector2(650, 404), Vector2(676, 380), Vector2(742, 380), Vector2(770, 404), Vector2(808, 410), Vector2(808, 432)]), pr)
		draw_colored_polygon(PackedVector2Array([Vector2(686, 386), Vector2(738, 386), Vector2(758, 402), Vector2(668, 402)]), Color(0.08, 0.14, 0.2))
		_ln(Vector2(712, 386), Vector2(712, 402), pr, 1.0)
		draw_rect(Rect2(618, 418, 184, 3), Color(0.36, 0.42, 0.5))
		draw_rect(Rect2(676, 380, 66, 3), Color(0.3, 0.36, 0.44))
		for rx in [652.0, 770.0]:
			_ci(Vector2(rx, 433), 14, Color(0.01, 0.01, 0.02))
			_ar(Vector2(rx, 433), 10, 0.0, TAU, 14, Color(0.8, 0.82, 0.85), 2.0)
			_ci(Vector2(rx, 433), 5, Color(0.5, 0.55, 0.6))
		_ci(Vector2(806, 420), 4, Color(1.0, 0.95, 0.7))
		draw_rect(Rect2(610, 414, 5, 8), Color(0.9, 0.12, 0.12))
		# barraca da direita
		_barraca(820.0, 1130.0, creme, vinho, mad, 1)
		_caixote_gelo(836.0, 447.0, 74.0, 50.0, mad, 3, 1)
		_caixote_gelo(1034.0, 447.0, 72.0, 54.0, mad, 3, 0)
		_caixote_gelo(1042.0, 393.0, 54.0, 40.0, mad, 2, 2)
		# placa de néon em forma de peixe (o brilho é animado), pendurada num poste
		draw_rect(Rect2(1172, 160, 8, 287), ferro)
		draw_rect(Rect2(1136, 100, 92, 70), Color(0.03, 0.05, 0.09))
		_contorno(Rect2(1136, 100, 92, 70), ferro.lightened(0.15), 2.0)
		_neon_peixe(Vector2(1180, 136), Color(0.10, 0.28, 0.32), 2.0)
		# chão de concreto molhado
		_chao(P.piso_a, P.piso_b, P.junta)
		draw_rect(Rect2(-40, 447, 1360, 4), P.junta.darkened(0.3))
		_elipse(Vector2(560, 560), 110, 12, Color(0.9, 0.3, 0.5, 0.10))
		_elipse(Vector2(920, 610), 130, 13, Color(0.3, 0.85, 1.0, 0.10))
		_elipse(Vector2(400, 690), 90, 9, Color(0.3, 0.85, 1.0, 0.08))
		for k in 36:
			var sx: float = fposmod(k * 191.0, 1360.0) - 40.0
			var sy: float = 456.0 + fposmod(k * 71.0, 240.0)
			draw_rect(Rect2(sx, sy, 4, 4), Color(0.75, 0.86, 0.92, 0.35))
		_sombra_vinheta()

	# ---------------------------------------------------------------- 12 FERRO-VELHO (pôr do sol, pilhas de carros, pneus, torre de sucata; Estrada Furiosa)
	## Carro amassado de lado, com a base no chão em `p` (rot inclina em torno da base).
	func _carro_velho(p: Vector2, rot: float, w: float, cor: Color) -> void:
		draw_set_transform(p, rot, Vector2.ONE)
		var h: float = w * 0.3
		var hw: float = w * 0.5
		draw_colored_polygon(PackedVector2Array([Vector2(-hw, 0), Vector2(-hw, -h * 0.55), Vector2(-hw * 0.55, -h * 0.65), Vector2(-hw * 0.3, -h * 1.05), Vector2(hw * 0.35, -h * 1.05), Vector2(hw * 0.6, -h * 0.65), Vector2(hw, -h * 0.55), Vector2(hw, 0)]), cor)
		draw_colored_polygon(PackedVector2Array([Vector2(-hw * 0.25, -h * 0.7), Vector2(-hw * 0.15, -h * 0.98), Vector2(hw * 0.3, -h * 0.98), Vector2(hw * 0.5, -h * 0.7)]), Color(0.05, 0.07, 0.1))
		_ln(Vector2(hw * 0.05, -h * 0.98), Vector2(hw * 0.05, -h * 0.7), cor, 1.0)
		draw_rect(Rect2(-hw, -h * 0.34, w, h * 0.12), cor.darkened(0.3))
		draw_rect(Rect2(-hw, -h * 0.58, w * 0.2, 4), cor.lightened(0.25))
		draw_colored_polygon(PackedVector2Array([Vector2(hw * 0.2, -h * 0.5), Vector2(hw * 0.5, -h * 0.55), Vector2(hw * 0.44, -h * 0.3), Vector2(hw * 0.22, -h * 0.25)]), Color(0.45, 0.2, 0.1))
		for rx in [-hw * 0.62, hw * 0.58]:
			_ci(Vector2(rx, -h * 0.2), h * 0.3, Color(0.03, 0.03, 0.04))
			_ci(Vector2(rx, -h * 0.2), h * 0.13, Color(0.45, 0.45, 0.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	## Pilha de pneus deitados (a pilha é torta de propósito).
	func _pilha_pneus(x: float, yb: float, n: int, r: float) -> void:
		_elipse(Vector2(x + r * 0.15, yb + 1.0), r * 1.1, 6.0, Color(0, 0, 0, 0.3))
		for k in n:
			var yy: float = yb - r * 0.42 - k * r * 0.62
			var xo: float = float((k * 7) % 3 - 1) * 5.0
			_elipse(Vector2(x + xo, yy), r, r * 0.42, Color(0.05, 0.05, 0.06))
			_elipse(Vector2(x + xo, yy - r * 0.1), r * 0.62, r * 0.22, Color(0.17, 0.17, 0.19))
			_elipse(Vector2(x + xo, yy - r * 0.06), r * 0.32, r * 0.11, Color(0.02, 0.02, 0.03))

	## Barril de óleo (a gangue pinta de laranja); `fogo` desenha só a boca apagada.
	func _barril(x: float, yb: float, cor: Color) -> void:
		draw_rect(Rect2(x - 22, yb - 62, 44, 62), cor)
		draw_rect(Rect2(x - 22, yb - 62, 6, 62), cor.lightened(0.2))
		draw_rect(Rect2(x + 16, yb - 62, 6, 62), cor.darkened(0.3))
		for ry in [yb - 54.0, yb - 32.0, yb - 10.0]:
			draw_rect(Rect2(x - 22, ry, 44, 4), cor.darkened(0.4))
		_elipse(Vector2(x, yb - 62), 22, 6, cor.darkened(0.45))

	func _ferrovelho() -> void:
		var P: Dictionary = Campo.paleta(12)
		var laranja: Color = P.acento_a
		var ferr := Color(0.42, 0.22, 0.13)
		var chapa := Color(0.30, 0.22, 0.20)
		var longe := Color(0.20, 0.09, 0.15)
		_grad(Rect2(-40, -40, 1360, 380), P.parede_alta, Color(0.86, 0.42, 0.20))
		_estrelas(14, 90.0, 12, Color(1, 0.9, 0.85, 0.7))
		_elipse(Vector2(420, 170), 220, 10, Color(0.42, 0.18, 0.30, 0.55))
		_elipse(Vector2(760, 130), 260, 11, Color(0.42, 0.18, 0.30, 0.5))
		_elipse(Vector2(1000, 220), 200, 9, Color(0.50, 0.22, 0.28, 0.45))
		_halo(Vector2(900, 326), 160, Color(1.0, 0.7, 0.3, 0.05), 8)
		_ci(Vector2(900, 326), 56, Color(1.0, 0.8, 0.4))
		# montes de sucata e o comboio ao longe
		var mont := PackedVector2Array([Vector2(-40, 342)])
		for k in 30:
			mont.append(Vector2(-40.0 + k * 48.0, 314.0 + sin(k * 1.7) * 14.0 + float((k * 5) % 3) * 6.0))
		mont.append(Vector2(1320, 342))
		draw_colored_polygon(mont, longe)
		for k in 4:
			var tx: float = 300.0 + k * 170.0
			draw_rect(Rect2(tx, 304, 78, 28), longe.lightened(0.05))
			draw_rect(Rect2(tx + 78, 312, 26, 20), longe.lightened(0.05))
			_ci(Vector2(tx + 14, 334), 6, Color(0.1, 0.05, 0.08))
			_ci(Vector2(tx + 90, 334), 6, Color(0.1, 0.05, 0.08))
		# cerca de chapa corrugada com arame farpado
		draw_rect(Rect2(-40, 340, 1360, 107), chapa)
		for k in 90:
			var lx: float = -40.0 + k * 15.0
			_ln(Vector2(lx, 340), Vector2(lx, 447), chapa.darkened(0.3) if k % 2 == 0 else chapa.lightened(0.12), 1.0)
		draw_rect(Rect2(-40, 336, 1360, 6), chapa.lightened(0.28))
		for px in [60.0, 330.0, 640.0, 1000.0, 1240.0]:
			draw_rect(Rect2(px, 318, 8, 129), chapa.darkened(0.5))
		_ln(Vector2(-40, 322), Vector2(1320, 322), Color(0.1, 0.07, 0.08), 1.0)
		for k in 44:
			_ln(Vector2(-30.0 + k * 31.0, 316), Vector2(-20.0 + k * 31.0, 328), Color(0.1, 0.07, 0.08), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(110, 356), Vector2(170, 350), Vector2(160, 420), Vector2(120, 400)]), ferr)
		draw_colored_polygon(PackedVector2Array([Vector2(760, 360), Vector2(820, 356), Vector2(806, 430), Vector2(770, 410)]), ferr.darkened(0.15))
		_grad(Rect2(-40, 390, 1360, 57), Color(0, 0, 0.03, 0.0), Color(0, 0, 0.03, 0.4))
		# pilha de carros amassados (esquerda)
		_sombra(250, 520, 34, 1.0, 0.3)
		_carro_velho(Vector2(380, 447), 0.0, 180.0, Color(0.55, 0.22, 0.17))
		_carro_velho(Vector2(398, 399), -0.05, 156.0, Color(0.26, 0.36, 0.46))
		_carro_velho(Vector2(372, 354), 0.09, 130.0, Color(0.62, 0.5, 0.2))
		_carro_velho(Vector2(560, 447), 0.0, 120.0, Color(0.30, 0.34, 0.30))
		# pneus ao fundo e barris de óleo
		_pilha_pneus(640.0, 447.0, 5, 44.0)
		_barril(716.0, 447.0, laranja.darkened(0.25))
		_barril(758.0, 447.0, laranja.darkened(0.4))
		_pilha_pneus(1150.0, 447.0, 4, 40.0)
		# pilha de carros da direita, diante do sol
		_sombra(790, 940, 30, 1.0, 0.3)
		_carro_velho(Vector2(860, 447), 0.0, 150.0, Color(0.42, 0.18, 0.2))
		_carro_velho(Vector2(872, 404), 0.06, 126.0, Color(0.58, 0.58, 0.54))
		# torre de sucata soldada (a faísca do soldador é animada)
		_sombra(960, 1100, 26, 1.0, 0.3)
		var viga: Color = ferr.lightened(0.12)
		_ln(Vector2(985, 447), Vector2(1020, 124), viga, 10.0)
		_ln(Vector2(1097, 447), Vector2(1062, 124), viga, 10.0)
		for k in 7:
			var ty: float = 447.0 - k * 46.0
			var ty2: float = ty - 46.0
			var u0: float = (447.0 - ty) / 323.0
			var u1: float = (447.0 - ty2) / 323.0
			var l0: float = lerpf(985.0, 1020.0, u0)
			var r0: float = lerpf(1097.0, 1062.0, u0)
			var l1: float = lerpf(985.0, 1020.0, u1)
			var r1: float = lerpf(1097.0, 1062.0, u1)
			_ln(Vector2(l0, ty), Vector2(r1, ty2), viga.darkened(0.2), 4.0)
			_ln(Vector2(r0, ty), Vector2(l1, ty2), viga.darkened(0.2), 4.0)
			_ln(Vector2(l0, ty), Vector2(r0, ty), viga, 4.0)
		draw_rect(Rect2(1004, 300, 74, 44), Color(0.2, 0.42, 0.44))
		_contorno(Rect2(1004, 300, 74, 44), Color(0.08, 0.14, 0.16), 2.0)
		draw_rect(Rect2(1006, 384, 66, 30), laranja.darkened(0.2))
		_contorno(Rect2(1006, 384, 66, 30), laranja.darkened(0.6), 2.0)
		draw_rect(Rect2(1010, 228, 58, 26), Color(0.7, 0.62, 0.3))
		_contorno(Rect2(1010, 228, 58, 26), Color(0.25, 0.2, 0.08), 2.0)
		_ar(Vector2(1041, 118), 20, 0.0, TAU, 18, Color(0.06, 0.05, 0.06), 8.0)
		_ar(Vector2(1041, 118), 12, 0.0, TAU, 14, Color(0.5, 0.5, 0.55), 2.0)
		_ln(Vector2(1041, 98), Vector2(1041, 70), viga, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(1041, 70), Vector2(1084, 80), Vector2(1041, 92)]), laranja)
		# chão de terra e cascalho, com marcas de pneu e poças de óleo
		draw_rect(Rect2(-40, 447, 1360, 293), P.piso_a)
		var ys: Array = YS.duplicate()
		ys.append(740.0)
		for r in range(1, ys.size()):
			if r % 2 == 0:
				draw_rect(Rect2(-40, ys[r - 1], 1360, ys[r] - ys[r - 1]), P.piso_b)
		for k in 90:
			var sx: float = fposmod(k * 197.0, 1360.0) - 40.0
			var sy: float = 456.0 + fposmod(k * 83.0, 270.0)
			draw_rect(Rect2(sx, sy, 8, 4), P.junta)
			draw_rect(Rect2(sx + 2, sy - 4, 4, 4), P.piso_a.lightened(0.1))
		_pl(PackedVector2Array([Vector2(240, 520), Vector2(480, 566), Vector2(720, 552), Vector2(980, 600)]), Color(P.junta.r, P.junta.g, P.junta.b, 0.8), 4.0)
		_pl(PackedVector2Array([Vector2(300, 600), Vector2(560, 640), Vector2(840, 618)]), Color(P.junta.r, P.junta.g, P.junta.b, 0.7), 4.0)
		_elipse(Vector2(880, 560), 70, 10, Color(0.03, 0.02, 0.04, 0.4))
		_elipse(Vector2(880, 559), 38, 5, Color(0.5, 0.25, 0.5, 0.18))
		_elipse(Vector2(420, 690), 80, 9, Color(0.03, 0.02, 0.04, 0.35))
		draw_rect(Rect2(-40, 447, 1360, 4), P.junta.darkened(0.35))
		_sombra_vinheta()

	# ---------------------------------------------------------------- 13 BECO DO FLIPERAMA (tijolo, néon, fileira de fliperamas, chão em grade; Tropa do Grid)
	## Fliperama de pé, base em `yb`: lados e letreiro na cor `cor`, tela apagada (a tela acesa é animada).
	func _fliper(x: float, yb: float, cor: Color) -> void:
		var top: float = yb - 168.0
		_sombra(x, x + 80.0, 28, 1.0, 0.25, top)
		draw_rect(Rect2(x, top, 80, 168), Color(0.07, 0.06, 0.15))
		draw_rect(Rect2(x, top, 6, 168), cor.darkened(0.55))
		draw_rect(Rect2(x + 74, top, 6, 168), cor.darkened(0.65))
		draw_rect(Rect2(x + 6, top + 6, 68, 22), cor.darkened(0.5))
		draw_rect(Rect2(x + 10, top + 10, 60, 4), cor.darkened(0.15))
		draw_rect(Rect2(x + 8, top + 32, 64, 60), Color(0.02, 0.03, 0.07))
		draw_rect(Rect2(x + 12, top + 36, 56, 52), Color(cor.r * 0.2, cor.g * 0.2, cor.b * 0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(x + 4, top + 96), Vector2(x + 76, top + 96), Vector2(x + 80, top + 120), Vector2(x, top + 120)]), Color(0.13, 0.12, 0.24))
		_ln(Vector2(x + 24, top + 108), Vector2(x + 24, top + 100), Color(0.6, 0.6, 0.7), 1.0)
		_ci(Vector2(x + 24, top + 98), 4, Color(0.85, 0.2, 0.25))
		_ci(Vector2(x + 46, top + 108), 3, cor)
		_ci(Vector2(x + 58, top + 108), 3, Color(1.0, 0.6, 0.2))
		draw_rect(Rect2(x + 28, top + 134, 24, 14), Color(0.03, 0.03, 0.06))
		draw_rect(Rect2(x + 36, top + 138, 8, 3), cor.darkened(0.2))
		draw_rect(Rect2(x, yb - 10, 80, 10), Color(0.04, 0.03, 0.08))

	func _beco() -> void:
		var P: Dictionary = Campo.paleta(13)
		var cian: Color = P.acento_a
		var laranja: Color = P.acento_b
		var metal := Color(0.08, 0.07, 0.17)
		_grad(Rect2(-40, -40, 1360, 487), P.parede_alta, P.parede_baixa)
		# tijolos
		for r in 26:
			var yy: float = r * 18.0 + 6.0
			_ln(Vector2(-40, yy), Vector2(1320, yy), Color(0, 0, 0.06, 0.28), 1.0)
			var xj: float = -40.0 + (r % 2) * 24.0
			while xj < 1320.0:
				_ln(Vector2(xj, yy), Vector2(xj, yy + 18.0), Color(0, 0, 0.06, 0.2), 1.0)
				xj += 48.0
		_halo(Vector2(640, 140), 300, Color(cian.r, cian.g, cian.b, 0.010), 8)
		_grad(Rect2(-40, 380, 1360, 67), Color(0, 0, 0.05, 0.0), Color(0, 0, 0.05, 0.4))
		# janela com grade na esquerda, acesa
		draw_rect(Rect2(86, 238, 90, 70), Color(0.05, 0.04, 0.1))
		draw_rect(Rect2(92, 244, 78, 58), Color(0.62, 0.42, 0.2))
		for k in 3:
			_ln(Vector2(106.0 + k * 22.0, 244), Vector2(106.0 + k * 22.0, 302), Color(0.05, 0.04, 0.1), 1.0)
		draw_rect(Rect2(80, 304, 102, 8), Color(0.3, 0.26, 0.4))
		# letreiro FLIPERAMA (o brilho de néon é animado) e fantasma/peixe de néon dos lados
		draw_rect(Rect2(404, 88, 480, 92), Color(0.03, 0.02, 0.08))
		_contorno(Rect2(404, 88, 480, 92), metal.lightened(0.2), 2.0)
		_letras(436.0, 112.0, "FLIPERAMA", 8.0, Color(cian.r * 0.28, cian.g * 0.28, cian.b * 0.28))
		_neon_fantasma(Vector2(340, 138), Color(laranja.r * 0.3, laranja.g * 0.3, laranja.b * 0.3), 2.0)
		_neon_fantasma(Vector2(948, 138), Color(laranja.r * 0.3, laranja.g * 0.3, laranja.b * 0.3), 2.0)
		# escada de incêndio e cano (direita)
		draw_rect(Rect2(1244, -40, 12, 487), metal.lightened(0.05))
		draw_rect(Rect2(1244, -40, 3, 487), metal.lightened(0.3))
		for k in 6:
			draw_rect(Rect2(1240, 20.0 + k * 70.0, 20, 6), metal.lightened(0.15))
		var fe := Color(0.12, 0.11, 0.24)
		for py in [226.0, 330.0]:
			draw_rect(Rect2(1010, py, 220, 8), fe)
			draw_rect(Rect2(1010, py, 220, 3), fe.lightened(0.3))
			_ln(Vector2(1010, py - 40), Vector2(1230, py - 40), fe, 1.0)
			for k in 11:
				_ln(Vector2(1010.0 + k * 22.0, py - 40), Vector2(1010.0 + k * 22.0, py), fe, 1.0)
		_ln(Vector2(1030, 234), Vector2(1130, 330), fe, 2.0)
		_ln(Vector2(1046, 234), Vector2(1146, 330), fe, 2.0)
		_ln(Vector2(1130, 338), Vector2(1214, 440), fe, 2.0)
		_ln(Vector2(1146, 338), Vector2(1230, 440), fe, 2.0)
		for k in 8:
			var u: float = k / 7.0
			_ln(Vector2(lerpf(1030, 1130, u), lerpf(234, 330, u)), Vector2(lerpf(1046, 1146, u), lerpf(234, 330, u)), fe.lightened(0.2), 1.0)
		# a fileira de fliperamas (cores se alternam)
		var cores: Array[Color] = [cian, Color(0.9, 0.25, 0.65), laranja]
		for k in 8:
			_fliper(250.0 + k * 92.0, 447.0, cores[k % 3])
		# latas de lixo ao lado da escada
		var lata := Color(0.16, 0.16, 0.26)
		for lx in [1052.0, 1110.0]:
			_sombra(lx, lx + 44.0, 20, 1.0, 0.3)
			draw_rect(Rect2(lx, 396, 44, 51), lata)
			draw_rect(Rect2(lx, 396, 5, 51), lata.lightened(0.2))
			draw_rect(Rect2(lx - 4, 390, 52, 8), lata.lightened(0.12))
			for k in 4:
				_ln(Vector2(lx + 10.0 + k * 9.0, 402), Vector2(lx + 10.0 + k * 9.0, 444), lata.darkened(0.3), 1.0)
		# chão: pista escura com a grade de luz (a pulsação é animada)
		_chao(P.piso_a, P.piso_b, P.junta.darkened(0.1))
		var grade := Color(cian.r, cian.g, cian.b, 0.12)
		for k in range(-12, 13):
			_ln(Vector2(_x_prof(k, 110.0, 447.0), 447), Vector2(_x_prof(k, 110.0, 740.0), 740), grade, 1.0)
		for r in range(1, YS.size()):
			_ln(Vector2(-40, YS[r]), Vector2(1320, YS[r]), grade, 1.0)
		_elipse(Vector2(760, 566), 120, 12, Color(0.9, 0.25, 0.65, 0.09))
		_elipse(Vector2(430, 640), 90, 9, Color(cian.r, cian.g, cian.b, 0.08))
		draw_rect(Rect2(-40, 447, 1360, 4), P.junta.darkened(0.45))
		_sombra_vinheta()

	# ---------------------------------------------------------------- 14 ARENA DA PRAÇA (tempestade, arquibancada de falange, colunas, estátua; Legião Miauparta)
	## Gato-soldado em silhueta, de pé na arquibancada: capacete com crista, lança e escudo redondo.
	func _falangista(x: float, yb: float, crista: Color, escudo: Color) -> void:
		var sil := Color(0.06, 0.045, 0.08)
		draw_rect(Rect2(x - 7, yb - 24, 14, 24), sil)
		_ci(Vector2(x, yb - 31), 8, sil)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 8, yb - 34), Vector2(x - 6, yb - 44), Vector2(x - 2, yb - 36)]), sil)
		draw_colored_polygon(PackedVector2Array([Vector2(x + 8, yb - 34), Vector2(x + 6, yb - 44), Vector2(x + 2, yb - 36)]), sil)
		draw_rect(Rect2(x - 3, yb - 46, 6, 8), crista)
		_ln(Vector2(x + 10, yb - 2), Vector2(x + 10, yb - 54), sil, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x + 7, yb - 54), Vector2(x + 13, yb - 54), Vector2(x + 10, yb - 64)]), Color(0.55, 0.55, 0.6))
		_ci(Vector2(x - 6, yb - 12), 9, escudo)
		_ci(Vector2(x - 6, yb - 12), 4, escudo.darkened(0.4))

	## Coluna dórica: base, fuste com caneluras e capitel (ou o topo quebrado).
	func _coluna(x: float, ytop: float, quebrada: bool, pedra: Color) -> void:
		var w: float = 56.0
		_sombra(x - w * 0.5, x + w * 0.5, 30, 1.0, 0.3)
		draw_rect(Rect2(x - w * 0.5 - 8, 436, w + 16, 11), pedra.darkened(0.15))
		draw_rect(Rect2(x - w * 0.5 - 8, 436, w + 16, 3), pedra.lightened(0.1))
		var y0: float = ytop + (16.0 if quebrada else 0.0)
		draw_rect(Rect2(x - w * 0.5, y0, w, 436.0 - y0), pedra)
		draw_rect(Rect2(x - w * 0.5, y0, 6, 436.0 - y0), pedra.lightened(0.2))
		draw_rect(Rect2(x + w * 0.5 - 8, y0, 8, 436.0 - y0), pedra.darkened(0.25))
		for k in 3:
			_ln(Vector2(x - 17.0 + k * 17.0, y0), Vector2(x - 17.0 + k * 17.0, 436), pedra.darkened(0.3), 1.0)
		if quebrada:
			draw_colored_polygon(PackedVector2Array([Vector2(x - w * 0.5, y0 + 2), Vector2(x - 20, ytop - 8), Vector2(x - 6, ytop + 10), Vector2(x + 6, ytop - 16), Vector2(x + 18, ytop + 8), Vector2(x + 28, ytop - 4), Vector2(x + 28, y0 + 2)]), pedra)
		else:
			draw_rect(Rect2(x - w * 0.5 - 4, ytop + 4, w + 8, 10), pedra.darkened(0.1))
			draw_rect(Rect2(x - w * 0.5 - 12, ytop - 10, w + 24, 14), pedra.lightened(0.08))
			draw_rect(Rect2(x - w * 0.5 - 12, ytop - 10, w + 24, 3), pedra.lightened(0.3))

	func _arena() -> void:
		var P: Dictionary = Campo.paleta(14)
		var verm: Color = P.acento_a
		var ouro: Color = P.acento_b
		var pedra: Color = Campo.tom_lum(Color(0.55, 0.5, 0.48), 0.3)
		_grad(Rect2(-40, -40, 1360, 340), P.parede_alta, Color(0.42, 0.30, 0.36))
		# nuvens de tempestade
		for k in 8:
			var nx: float = -80.0 + k * 190.0
			var ny: float = 70.0 + float((k * 5) % 3) * 44.0
			_elipse(Vector2(nx, ny), 170, 30, Color(0.07, 0.05, 0.12, 0.6))
			_elipse(Vector2(nx + 20, ny + 26), 130, 12, Color(0.55, 0.38, 0.48, 0.25))
		_estrelas(8, 60.0, 14)
		# arquibancada em degraus, com os gatos da falange nos dois degraus de trás
		var degr: Array[Color] = [Color(0.20, 0.17, 0.22), Color(0.26, 0.22, 0.26), Color(0.32, 0.27, 0.30), Color(0.38, 0.32, 0.34)]
		for t in 4:
			var ty: float = 290.0 + t * 40.0
			draw_rect(Rect2(-40, ty, 1360, 40.0 + 20.0 if t == 3 else 40.0), degr[t])
			draw_rect(Rect2(-40, ty, 1360, 4), degr[t].lightened(0.3))
			var xj: float = -40.0 + (t % 2) * 40.0
			while xj < 1320.0:
				_ln(Vector2(xj, ty + 4.0), Vector2(xj, ty + 40.0), degr[t].darkened(0.3), 1.0)
				xj += 80.0
		for t in 2:
			var yb: float = 330.0 + t * 40.0
			var x: float = 20.0 + (t % 2) * 22.0
			var k: int = 0
			while x < 1300.0:
				var esc: Color = Color(0.5, 0.12, 0.1) if k % 3 != 1 else Color(0.34, 0.1, 0.1)
				_falangista(x, yb, verm if k % 2 == 0 else ouro.darkened(0.3), esc)
				x += 44.0
				k += 1
		_grad(Rect2(-40, 380, 1360, 67), Color(0, 0, 0.03, 0.0), Color(0, 0, 0.03, 0.4))
		# estátua do gato-hoplita no meio da praça
		_sombra(630, 750, 30, 1.0, 0.3)
		draw_rect(Rect2(644, 382, 92, 65), pedra.lightened(0.14))
		draw_rect(Rect2(644, 382, 8, 65), pedra.lightened(0.2))
		draw_rect(Rect2(728, 382, 8, 65), pedra.darkened(0.3))
		draw_rect(Rect2(634, 372, 112, 14), pedra.lightened(0.1))
		draw_rect(Rect2(634, 372, 112, 3), pedra.lightened(0.3))
		draw_rect(Rect2(636, 438, 108, 9), pedra.darkened(0.2))
		var est: Color = pedra.lightened(0.32)
		draw_colored_polygon(PackedVector2Array([Vector2(664, 372), Vector2(668, 300), Vector2(712, 300), Vector2(716, 372)]), est.darkened(0.12))
		draw_rect(Rect2(666, 250, 48, 54), est)
		draw_rect(Rect2(706, 250, 8, 54), est.darkened(0.25))
		_ci(Vector2(690, 232), 20, est)
		draw_colored_polygon(PackedVector2Array([Vector2(672, 222), Vector2(676, 198), Vector2(688, 216)]), est)
		draw_colored_polygon(PackedVector2Array([Vector2(708, 222), Vector2(704, 198), Vector2(692, 216)]), est)
		draw_rect(Rect2(678, 196, 24, 10), est.darkened(0.2))
		draw_rect(Rect2(686, 178, 8, 20), est.darkened(0.1))
		_ci(Vector2(660, 296), 28, est.darkened(0.15))
		_ci(Vector2(660, 296), 16, est.darkened(0.3))
		_ln(Vector2(738, 372), Vector2(738, 150), est.darkened(0.1), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(730, 150), Vector2(746, 150), Vector2(738, 120)]), est.lightened(0.2))
		# colunas dóricas (uma quebrada à esquerda, duas inteiras, uma tombada)
		_coluna(330.0, 150.0, false, pedra)
		_coluna(480.0, 296.0, true, pedra)
		_coluna(900.0, 330.0, true, pedra)
		_coluna(1070.0, 150.0, false, pedra)
		# braseiros nos postes (as chamas e os estandartes vermelhos são animados)
		for bx in [590.0, 790.0]:
			_sombra(bx - 6, bx + 6, 16, 1.0, 0.25)
			draw_rect(Rect2(bx - 4, 332, 8, 115), Color(0.16, 0.12, 0.12))
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 17, 330), Vector2(bx + 17, 330), Vector2(bx + 11, 348), Vector2(bx - 11, 348)]), Color(0.2, 0.15, 0.14))
			draw_rect(Rect2(bx - 17, 328, 34, 4), Color(0.4, 0.3, 0.26))
		# praça de pedra com a marca da arena
		_chao(P.piso_a, P.piso_b, P.junta)
		var anel: PackedVector2Array = _pts_elipse(Vector2(700, 596), 560.0, 112.0, 48)
		anel.append(anel[0])
		_pl(anel, P.junta.darkened(0.22), 6.0)
		var anel2: PackedVector2Array = _pts_elipse(Vector2(700, 596), 400.0, 78.0, 40)
		anel2.append(anel2[0])
		_pl(anel2, Color(P.junta.r, P.junta.g, P.junta.b, 0.8), 4.0)
		_elipse(Vector2(700, 596), 330, 60, Color(0.7, 0.6, 0.45, 0.06))
		for k in 40:
			var sx: float = fposmod(k * 193.0, 1360.0) - 40.0
			var sy: float = 456.0 + fposmod(k * 79.0, 250.0)
			draw_rect(Rect2(sx, sy, 8, 4), P.junta)
		_pl(PackedVector2Array([Vector2(300, 520), Vector2(330, 556), Vector2(316, 590)]), P.junta.darkened(0.2), 2.0)
		_pl(PackedVector2Array([Vector2(960, 640), Vector2(990, 610), Vector2(1030, 624)]), P.junta.darkened(0.2), 2.0)
		draw_rect(Rect2(-40, 447, 1360, 4), P.junta.darkened(0.3))
		_sombra_vinheta()

	# ---------------------------------------------------------------- 15 TELHADOS E ANTENAS (noite com raios, torre de rádio, caixa d'água; Irmandade Mutante)
	## Fio com barriga entre dois pontos.
	func _fio(a: Vector2, b: Vector2, barriga: float, cor: Color) -> void:
		var pts := PackedVector2Array()
		for i in 13:
			var u: float = i / 12.0
			pts.append(a.lerp(b, u) + Vector2(0, sin(u * PI) * barriga))
		_pl(pts, cor, 1.0)

	func _antenas() -> void:
		var P: Dictionary = Campo.paleta(15)
		var roxo: Color = P.acento_a
		var metal := Color(0.20, 0.16, 0.32)
		_grad(Rect2(-40, -40, 1360, 340), P.parede_alta, Color(0.34, 0.18, 0.42))
		_estrelas(36, 200.0, 15)
		for k in 6:
			var nx: float = -60.0 + k * 250.0
			var ny: float = 100.0 + float((k * 7) % 3) * 40.0
			_elipse(Vector2(nx, ny), 190, 22, Color(0.05, 0.02, 0.1, 0.55))
			_elipse(Vector2(nx + 30, ny + 20), 150, 8, Color(roxo.r, roxo.g, roxo.b, 0.22))
		# horizonte de arranha-céus em duas camadas, com janelas acesas
		var pred: Array = [[-20, 100, 230], [70, 120, 280], [180, 90, 200], [270, 130, 300], [390, 100, 240], [480, 140, 270], [610, 90, 320], [690, 120, 220], [800, 110, 290], [900, 140, 250], [1030, 100, 310], [1120, 130, 230], [1240, 100, 270]]
		for i in pred.size():
			var bd: Array = pred[i]
			var bx: float = bd[0]
			var bw: float = bd[1]
			var topo: float = 436.0 - float(bd[2]) * 0.62 - 40.0
			var bc: Color = Color(0.09, 0.05, 0.19) if i % 2 == 0 else Color(0.12, 0.07, 0.24)
			draw_rect(Rect2(bx, topo, bw, 447.0 - topo), bc)
			if i % 3 == 0:
				_ln(Vector2(bx + bw * 0.5, topo), Vector2(bx + bw * 0.5, topo - 34.0), bc.lightened(0.2), 1.0)
			var wy: float = topo + 14.0
			while wy < 400.0:
				var wx: float = bx + 10.0
				while wx < bx + bw - 14.0:
					var h: int = (int(wx) * 7 + int(wy) * 3 + i) % 6
					if h == 0:
						draw_rect(Rect2(wx, wy, 10, 14), Color(1.0, 0.82, 0.45, 0.8))
					elif h == 1:
						draw_rect(Rect2(wx, wy, 10, 14), Color(0.55, 0.45, 1.0, 0.7))
					wx += 26.0
				wy += 34.0
		# caixa d'água em palafitas
		_sombra(320, 450, 28, 1.0, 0.3)
		var tq := Color(0.17, 0.13, 0.30)
		for lx in [330.0, 438.0]:
			draw_rect(Rect2(lx, 316, 8, 120), metal)
		_ln(Vector2(334, 330), Vector2(442, 420), metal, 1.0)
		_ln(Vector2(442, 330), Vector2(334, 420), metal, 1.0)
		draw_rect(Rect2(326, 316, 120, 8), metal.lightened(0.15))
		draw_rect(Rect2(322, 206, 128, 112), tq)
		draw_rect(Rect2(322, 206, 14, 112), tq.lightened(0.2))
		draw_rect(Rect2(436, 206, 14, 112), tq.darkened(0.3))
		for ry in [230.0, 262.0, 294.0]:
			draw_rect(Rect2(322, ry, 128, 4), tq.darkened(0.4))
		draw_colored_polygon(PackedVector2Array([Vector2(322, 206), Vector2(450, 206), Vector2(436, 184), Vector2(336, 184)]), tq.lightened(0.1))
		_ln(Vector2(386, 184), Vector2(386, 166), metal, 1.0)
		_ln(Vector2(454, 214), Vector2(454, 436), metal, 1.0)
		for k in 10:
			_ln(Vector2(454, 226.0 + k * 22.0), Vector2(470, 226.0 + k * 22.0), metal, 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(386, 240), Vector2(410, 282), Vector2(362, 282)]), roxo.darkened(0.2))
		draw_rect(Rect2(383, 252, 6, 16), tq)
		draw_rect(Rect2(383, 272, 6, 5), tq)
		# mastro de antenas de TV e a parabólica
		var ant := Color(0.42, 0.36, 0.60)
		_ln(Vector2(640, 220), Vector2(640, 430), ant, 1.0)
		for k in 5:
			var ay: float = 232.0 + k * 22.0
			var hl: float = 46.0 - k * 6.0
			_ln(Vector2(640.0 - hl, ay), Vector2(640.0 + hl, ay), ant, 1.0)
		_ln(Vector2(640, 330), Vector2(570, 440), Color(ant.r, ant.g, ant.b, 0.5), 1.0)
		_ln(Vector2(640, 330), Vector2(712, 440), Color(ant.r, ant.g, ant.b, 0.5), 1.0)
		_ln(Vector2(820, 430), Vector2(820, 364), ant, 2.0)
		_ar(Vector2(822, 350), 36, PI * 0.15, PI * 0.9, 12, ant.lightened(0.15), 4.0)
		_ln(Vector2(822, 350), Vector2(860, 320), ant, 1.0)
		_ci(Vector2(860, 320), 4, ant.lightened(0.3))
		# torre de rádio (as luzes vermelhas e o campo magnético são animados)
		var tc: float = 1010.0
		for k in 14:
			var t0: float = k / 14.0
			var t1: float = (k + 1) / 14.0
			var y0: float = lerpf(436.0, 34.0, t0)
			var y1: float = lerpf(436.0, 34.0, t1)
			var h0: float = lerpf(66.0, 7.0, t0)
			var h1: float = lerpf(66.0, 7.0, t1)
			_ln(Vector2(tc - h0, y0), Vector2(tc + h0, y0), metal.lightened(0.1), 1.0)
			_ln(Vector2(tc - h0, y0), Vector2(tc + h1, y1), metal, 1.0)
			_ln(Vector2(tc + h0, y0), Vector2(tc - h1, y1), metal, 1.0)
		_ln(Vector2(tc - 66, 436), Vector2(tc - 7, 34), metal.lightened(0.2), 6.0)
		_ln(Vector2(tc + 66, 436), Vector2(tc + 7, 34), metal.lightened(0.05), 6.0)
		_ln(Vector2(tc, 34), Vector2(tc, 2), metal.lightened(0.2), 1.0)
		for k in 3:
			_ar(Vector2(tc + 34.0 - k * 8.0, 210.0 - k * 44.0), 14, -PI * 0.5, PI * 0.5, 8, metal.lightened(0.25), 2.0)
		for ly in [34.0, 168.0, 300.0]:
			_ci(Vector2(tc, ly), 4, Color(0.3, 0.05, 0.08))
		# fios entre a torre, o mastro e a caixa d'água
		_fio(Vector2(tc - 8, 120), Vector2(640, 232), 34.0, Color(0.05, 0.03, 0.1))
		_fio(Vector2(640, 250), Vector2(446, 214), 22.0, Color(0.05, 0.03, 0.1))
		_fio(Vector2(tc + 8, 150), Vector2(1330, 200), 26.0, Color(0.05, 0.03, 0.1))
		# mureta do terraço, com tijolos
		draw_rect(Rect2(-40, 420, 1360, 27), P.parede_baixa)
		draw_rect(Rect2(-40, 420, 1360, 5), P.parede_baixa.lightened(0.35))
		for k in 40:
			_ln(Vector2(-40.0 + k * 36.0, 425), Vector2(-40.0 + k * 36.0, 444), P.parede_baixa.darkened(0.35), 1.0)
		draw_rect(Rect2(-40, 444, 1360, 3), Color(0, 0, 0, 0.45))
		# chão do terraço: manta asfáltica com emendas, cascalho e poças
		_chao(P.piso_a, P.piso_b, P.junta)
		for k in 70:
			var sx: float = fposmod(k * 199.0, 1360.0) - 40.0
			var sy: float = 456.0 + fposmod(k * 73.0, 260.0)
			draw_rect(Rect2(sx, sy, 4, 4), P.junta.lightened(0.1) if k % 2 == 0 else P.junta.darkened(0.2))
		_elipse(Vector2(560, 600), 120, 12, Color(roxo.r, roxo.g, roxo.b, 0.10))
		_elipse(Vector2(880, 520), 80, 8, Color(roxo.r, roxo.g, roxo.b, 0.08))
		draw_colored_polygon(PackedVector2Array([Vector2(300, 560), Vector2(350, 556), Vector2(346, 584), Vector2(306, 586)]), P.junta.darkened(0.4))
		draw_rect(Rect2(-40, 447, 1360, 4), P.junta.darkened(0.3))
		_sombra_vinheta()

# ---------------------------------------------------------------- animados
## Elementos animados do cenário, em baixa resolução (outro SubViewport, atualizado
## sempre). O tempo vem do Campo já em passos de 1/12 s: o movimento anda em quadros.
class Animado extends Pixel:
	var rel: float = 0.0
	var fase: int = 1
	var tijolos: int = 0
	var pulso_torre: float = 0.0
	var pulso_bau: float = 0.0
	var torre_pixel: bool = false
	var caixa_pixel: bool = false

	## Retângulo alinhado à grade de 4 px (1 pixel do viewport), no mínimo 1 pixel de lado.
	func _rq(r: Rect2, c: Color) -> void:
		var x0: float = roundf(r.position.x / G) * G
		var y0: float = roundf(r.position.y / G) * G
		var x1: float = maxf(roundf(r.end.x / G) * G, x0 + G)
		var y1: float = maxf(roundf(r.end.y / G) * G, y0 + G)
		draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), c)

	## Torre de blocos: mesma geometria de Desenho.torre, mas em blocos de pixel. As letras
	## ficam por conta do Campo (resolução cheia, por cima), na mesma posição.
	func _torre_pixel() -> void:
		var base: Vector2 = Campo.torre_base_grade()
		for i in tijolos:
			var rb: Rect2 = Desenho.rect_tijolo(i, base, 1.0)
			var cor: Color = Desenho.b(Desenho.cor_tijolo(i), pulso_torre)
			var p: Vector2 = rb.position
			draw_rect(rb, cor.darkened(0.55))
			draw_rect(Rect2(p.x + G, p.y + G, rb.size.x - 2.0 * G, rb.size.y - 2.0 * G), cor)
			draw_rect(Rect2(p.x + G, p.y + G, rb.size.x - 2.0 * G, G), cor.lightened(0.3))
			draw_rect(Rect2(p.x + G, p.y + rb.size.y - 2.0 * G, rb.size.x - 2.0 * G, G), cor.darkened(0.22))
			draw_rect(Rect2(p.x + 16.0, p.y + 4.0, 8.0, 12.0), Color(0.99, 0.95, 0.82))
			draw_rect(Rect2(p.x + 12.0, p.y + 8.0, 16.0, 4.0), Color(0.99, 0.95, 0.82))
		if tijolos > 0:
			var topo: Rect2 = Desenho.rect_tijolo(tijolos - 1, base, 1.0)
			var cx: float = base.x + Desenho.TIJ_COLS * Desenho.TIJ_W * 0.5
			draw_rect(Rect2(cx - 2.0, topo.position.y - 36.0, G, 36.0), Color(0.88, 0.76, 0.55))
			var pano: Color = Color(0.9, 0.35, 0.3)
			draw_rect(Rect2(cx + 2.0, topo.position.y - 36.0, 20.0, G), pano)
			draw_rect(Rect2(cx + 2.0, topo.position.y - 32.0, 16.0, G), pano)
			draw_rect(Rect2(cx + 2.0, topo.position.y - 28.0, 8.0, G), pano)

	## Caixa de peças em pixel (formas); o "B" e o contador ficam no Campo.
	func _caixa_pixel() -> void:
		var sc: float = 1.0 + 0.25 * pulso_bau
		var bp: Vector2 = Campo.BAU_POS
		var f := func(rc: Rect2) -> Rect2:
			return Rect2(bp + rc.position * sc, rc.size * sc)
		var escuro := Color(0.12, 0.2, 0.4)
		_rq(f.call(Rect2(-23, -43, 18, 18)), Color(0.9, 0.3, 0.3))
		_rq(f.call(Rect2(1, -42, 14, 14)), Color(0.96, 0.78, 0.3))
		_rq(f.call(Rect2(15, -38, 10, 10)), Color(0.9, 0.7, 0.55))
		_rq(f.call(Rect2(-30, -26, 60, 34)), escuro)
		_rq(f.call(Rect2(-27, -23, 54, 28)), Color(0.3, 0.5, 0.8))
		_rq(f.call(Rect2(-33, -29, 66, 8)), Color(0.4, 0.28, 0.08))
		_rq(f.call(Rect2(-31, -27, 62, 4)), Color(0.95, 0.76, 0.3))
		_rq(f.call(Rect2(-8, -16, 16, 16)), Color(0.99, 0.95, 0.82))

	func _draw() -> void:
		if torre_pixel:
			_torre_pixel()
		if caixa_pixel:
			_caixa_pixel()
		match fase:
			2:
				_anim_sala()
			3:
				_anim_cozinha()
			4:
				_anim_sotao()
			5:
				_anim_porao()
			6:
				_anim_quintal()
			7:
				_anim_garagem()
			8:
				_anim_telhado()
			9:
				_anim_rua()
			10:
				_anim_toca()
			11:
				_anim_mercado()
			12:
				_anim_ferrovelho()
			13:
				_anim_beco()
			14:
				_anim_arena()
			15:
				_anim_antenas()
			_:
				_anim_quarto()

	func _halo(c: Vector2, r: float, cor: Color, n: int = 9) -> void:
		for g in n:
			draw_circle(c, r * float(n - g) / n, cor)

	func _poeira(caixa: Rect2, n: int, cor: Color, vel: float = 8.0) -> void:
		for k in n:
			var fx: float = fposmod(k * 0.6180339 + rel * 0.004 * (1.0 + k % 3), 1.0)
			var fy: float = fposmod(k * 0.3819660 + rel * vel * 0.001 * (1.0 + k % 2), 1.0)
			var p: Vector2 = caixa.position + Vector2(fx * caixa.size.x + sin(rel * 0.6 + k) * 8.0, fy * caixa.size.y)
			var tw: float = 0.5 + 0.5 * sin(rel * 1.3 + k * 2.1)
			_ci(p, 1.3 + (k % 2) * 0.5, Color(cor.r, cor.g, cor.b, cor.a * (0.35 + 0.65 * tw)))

	func _cortina(x0: float, x1: float, sg: float, cor: Color, fase_t: float, y1: float = 285.0) -> void:
		# cortina balançando devagar: topo fixo, barra oscila
		var sw: float = sin(rel * 0.7 + fase_t) * 5.0 * sg
		var pts: PackedVector2Array = PackedVector2Array([Vector2(x0, 58), Vector2(x1, 58), Vector2(x1 + sw * 0.7, y1), Vector2(x0 + sw, y1)])
		draw_colored_polygon(pts, cor)
		for k in 3:
			var u: float = (k + 1) / 4.0
			_ln(Vector2(lerpf(x0, x1, u), 60), Vector2(lerpf(x0 + sw, x1 + sw * 0.7, u), y1 - 2.0), Color(0, 0, 0, 0.2), 2.0)

	func _anim_quarto() -> void:
		_cortina(672, 718, -1.0, Color(0.55, 0.2, 0.28), 0.0)
		_cortina(862, 816, 1.0, Color(0.55, 0.2, 0.28), 1.7)
		# feixe de luar no ar com poeira
		draw_polygon(PackedVector2Array([Vector2(700, 270), Vector2(830, 270), Vector2(690, 450), Vector2(520, 450)]), PackedColorArray([Color(0.7, 0.8, 1.0, 0.06), Color(0.7, 0.8, 1.0, 0.06), Color(0.7, 0.8, 1.0, 0.0), Color(0.7, 0.8, 1.0, 0.0)]))
		_poeira(Rect2(560, 280, 220, 160), 12, Color(0.85, 0.92, 1.0, 0.55), 10.0)
		# abajur com leve oscilar da luz
		var fl: float = 0.012 * sin(rel * 3.0)
		_ci(Vector2(1154, 318), 70.0, Color(1.0, 0.8, 0.45, 0.05 + fl))

	func _anim_sala() -> void:
		# chamas da lareira
		var fo: float = 0.5 + 0.5 * sin(rel * 9.0) * sin(rel * 5.3)
		for i in 5:
			var fx: float = 548.0 + i * 22.0
			var h: float = 34.0 + 22.0 * sin(rel * 11.0 + i * 1.9) * (1.0 - absf(i - 2) * 0.18)
			var base := Vector2(fx, 408.0)
			draw_colored_polygon(PackedVector2Array([base + Vector2(-11, 0), base + Vector2(sin(rel * 7.0 + i) * 4.0, -h), base + Vector2(11, 0)]), Color(1.0, 0.42, 0.1, 0.95))
			draw_colored_polygon(PackedVector2Array([base + Vector2(-6, 0), base + Vector2(0, -h * 0.6), base + Vector2(6, 0)]), Color(1.0, 0.85, 0.3, 0.95))
		_halo(Vector2(592, 380), 250.0, Color(1.0, 0.55, 0.2, 0.004 + 0.0015 * fo), 18)
		_halo(Vector2(592, 398), 90.0, Color(1.0, 0.75, 0.3, 0.012 + 0.004 * fo), 12)
		draw_colored_polygon(PackedVector2Array([Vector2(500, 452), Vector2(680, 452), Vector2(800, 600), Vector2(380, 600)]), Color(1.0, 0.55, 0.2, 0.012 + 0.008 * fo))
		# faíscas subindo
		for k in 4:
			var t: float = fposmod(rel * 0.7 + k * 0.27, 1.0)
			_ci(Vector2(560 + k * 22.0 + sin(rel * 3.0 + k) * 8.0, 400.0 - t * 90.0), 1.6, Color(1.0, 0.75, 0.3, 1.0 - t))
		# pêndulo do relógio
		var ang: float = sin(rel * 3.1) * 0.35
		var tip: Vector2 = Vector2(290, 240) + Vector2(sin(ang), cos(ang)) * 90.0
		_ln(Vector2(290, 240), tip, Color(0.8, 0.65, 0.3), 2.0)
		_ci(tip, 9.0, Color(0.9, 0.72, 0.3))
		# cortina
			# cortinas ao lado da moldura da janela (892 a 1058), curtas o bastante para não cobrir o sofá (topo em y=268)
		_cortina(860, 896, 1.0, Color(0.5, 0.17, 0.24), 0.4, 258.0)
		_cortina(1054, 1090, 1.0, Color(0.5, 0.17, 0.24), 2.1, 258.0)
		_poeira(Rect2(930, 260, 200, 180), 8, Color(0.85, 0.9, 1.0, 0.5), 8.0)

	func _anim_cozinha() -> void:
		# panelas penduradas balançando levemente
		for i in 3:
			var x0: float = 270.0 + i * 70.0
			var sw: float = sin(rel * 1.2 + i * 1.3) * 3.0
			var base := Vector2(x0 + sw, 232.0)
			_ln(Vector2(x0, 196), base, Color(0.5, 0.5, 0.55), 2.0)
			if i == 1:
				_ci(base + Vector2(0, 14), 14.0, Color(0.55, 0.57, 0.62))
				draw_rect(Rect2(base + Vector2(-9, 8), Vector2(18, 4)), Color(0.8, 0.82, 0.88, 0.5))
			else:
				draw_colored_polygon(PackedVector2Array([base + Vector2(-16, 0), base + Vector2(16, 0), base + Vector2(13, 26), base + Vector2(-13, 26)]), Color(0.3 + 0.1 * i, 0.3, 0.34))
				_ln(base + Vector2(16, 6), base + Vector2(34, 6), Color(0.2, 0.2, 0.23), 3.0)
		# gota da torneira e ondinha na pia
		var t: float = fposmod(rel * 0.7, 1.0)
		var gy: float = 266.0 + t * t * 26.0
		if t < 0.92:
			_ci(Vector2(722, gy), 2.6, Color(0.6, 0.8, 1.0, 0.9))
		else:
			var rp: float = (t - 0.92) / 0.08
			_ar(Vector2(722, 290), 3.0 + rp * 8.0, PI, TAU, 10, Color(0.6, 0.8, 1.0, 1.0 - rp), 1.5)
		# vapor da panela no fogão
		for k in 3:
			var tt: float = fposmod(rel * 0.45 + k * 0.33, 1.0)
			_ci(Vector2(510 + sin(rel * 2.0 + k * 2.0) * 7.0 + k * 10.0, 244.0 - tt * 50.0), 5.0 + tt * 7.0, Color(0.9, 0.95, 1.0, 0.16 * (1.0 - tt)))
		_poeira(Rect2(640, 200, 120, 220), 6, Color(0.9, 0.95, 1.0, 0.5), 6.0)

	func _anim_sotao() -> void:
		_poeira(Rect2(450, 130, 380, 310), 22, Color(0.85, 0.92, 1.0, 0.6), 7.0)
		# aranha descendo no fio, subindo devagar
		var ay: float = 120.0 + (0.5 + 0.5 * sin(rel * 0.5)) * 90.0
		_ln(Vector2(1160, 24), Vector2(1160, ay), Color(0.85, 0.85, 0.95, 0.4), 1.0)
		_ci(Vector2(1160, ay + 3), 4.0, Color(0.05, 0.04, 0.07))
		for s in [-1.0, 1.0]:
			_ln(Vector2(1160, ay + 3), Vector2(1160 + s * 8.0, ay + 8), Color(0.05, 0.04, 0.07), 1.0)
			_ln(Vector2(1160, ay + 3), Vector2(1160 + s * 8.0, ay - 2), Color(0.05, 0.04, 0.07), 1.0)
		# manequim: pano balançando
		draw_colored_polygon(PackedVector2Array([Vector2(518, 300), Vector2(524 + sin(rel * 1.1) * 3.0, 344), Vector2(510, 344)]), Color(0.45, 0.3, 0.4))

	func _anim_porao() -> void:
		# varal com roupas balançando
		var a := Vector2(330, 150)
		var b := Vector2(960, 172)
		var pts := PackedVector2Array()
		for i in 13:
			var u: float = i / 12.0
			pts.append(a.lerp(b, u) + Vector2(0, sin(u * PI) * 26.0))
		_pl(pts, Color(0.75, 0.7, 0.55, 0.8), 1.5)
		var roupas: Array = [[0.2, Color(0.75, 0.3, 0.3), 30.0, 52.0], [0.38, Color(0.35, 0.5, 0.75), 16.0, 34.0], [0.5, Color(0.9, 0.85, 0.5), 16.0, 34.0], [0.72, Color(0.45, 0.65, 0.4), 34.0, 58.0]]
		for i in roupas.size():
			var rr: Array = roupas[i]
			var u2: float = rr[0]
			var ap: Vector2 = a.lerp(b, u2) + Vector2(0, sin(u2 * PI) * 26.0)
			var sw: float = sin(rel * 1.3 + i * 1.1) * 4.0
			var w: float = rr[2]
			var h: float = rr[3]
			draw_colored_polygon(PackedVector2Array([ap + Vector2(-w * 0.5, 0), ap + Vector2(w * 0.5, 0), ap + Vector2(w * 0.5 + sw, h), ap + Vector2(-w * 0.5 + sw, h)]), rr[1])
			draw_rect(Rect2(ap + Vector2(-3, -4), Vector2(6, 8)), Color(0.8, 0.8, 0.8))
		# gota do cano caindo até a poça
		var t: float = fposmod(rel * 0.55, 1.0)
		var gy: float = 112.0 + t * t * 340.0
		if gy < 452.0:
			_ln(Vector2(440, gy - 6), Vector2(440, gy), Color(0.6, 0.8, 1.0, 0.5), 2.0)
			_ci(Vector2(440, gy), 2.4, Color(0.65, 0.85, 1.0, 0.95))
		var rp: float = clampf((t - 0.97) * 33.0, 0.0, 1.0)
		if t > 0.9:
			_ar(Vector2(440, 456), 3.0 + rp * 18.0, 0, TAU, 14, Color(0.7, 0.85, 1.0, 0.8 * (1.0 - rp)), 1.5)
		# lâmpada pendurada balançando, com luz que acompanha
		var bal: float = sin(rel * 1.1) * 7.0
		var lx: float = 600.0 + bal
		_ln(Vector2(600.0, -20), Vector2(lx, 180), Color(0.04, 0.04, 0.05), 2.0)
		_halo(Vector2(lx, 192), 250.0, Color(1.0, 0.82, 0.4, 0.024), 9)
		draw_colored_polygon(PackedVector2Array([Vector2(lx - 15, 190), Vector2(lx + 15, 190), Vector2(lx + 6, 174), Vector2(lx - 6, 174)]), Color(0.15, 0.15, 0.17))
		_ci(Vector2(lx, 196), 8, Color(1.0, 0.94, 0.65))
		# sombra da lâmpada no chão acompanha o balanço
		draw_colored_polygon(PackedVector2Array([Vector2(lx - 160, 452), Vector2(lx + 160, 452), Vector2(lx + 300, 560), Vector2(lx - 300, 560)]), Color(1.0, 0.82, 0.4, 0.03))
		_poeira(Rect2(520, 200, 160, 230), 8, Color(1.0, 0.92, 0.7, 0.5), 5.0)
		# fogo do visor da caldeira
		_ci(Vector2(1165, 360), 22.0, Color(1.0, 0.5, 0.15, 0.05 + 0.02 * sin(rel * 8.0)))

	# ---- cenas de fora (ato 2)
	func _anim_quintal() -> void:
		# varal entre os postes, com lençol, camisa, meias e toalha balançando
		var a := Vector2(330, 152)
		var b := Vector2(990, 156)
		var pts := PackedVector2Array()
		for i in 13:
			var u: float = i / 12.0
			pts.append(a.lerp(b, u) + Vector2(0, sin(u * PI) * 22.0))
		_pl(pts, Color(0.85, 0.82, 0.7, 0.85), 1.5)
		var roupas: Array = [[0.14, Color(0.9, 0.88, 0.8), 70.0, 84.0], [0.34, Color(0.8, 0.3, 0.3), 36.0, 54.0], [0.46, Color(0.95, 0.85, 0.4), 14.0, 30.0], [0.52, Color(0.35, 0.55, 0.8), 14.0, 30.0], [0.7, Color(0.45, 0.7, 0.5), 44.0, 62.0], [0.88, Color(0.9, 0.55, 0.65), 30.0, 44.0]]
		for i in roupas.size():
			var rr: Array = roupas[i]
			var u2: float = rr[0]
			var ap: Vector2 = a.lerp(b, u2) + Vector2(0, sin(u2 * PI) * 22.0)
			var sw: float = sin(rel * 1.4 + i * 1.1) * 5.0
			var w: float = rr[2]
			var h: float = rr[3]
			draw_colored_polygon(PackedVector2Array([ap + Vector2(-w * 0.5, 0), ap + Vector2(w * 0.5, 0), ap + Vector2(w * 0.5 + sw, h), ap + Vector2(-w * 0.5 + sw * 1.2, h)]), rr[1])
			draw_rect(Rect2(ap + Vector2(-w * 0.5, 0), Vector2(w, 4)), Color(1, 1, 1, 0.2))
			draw_rect(Rect2(ap + Vector2(-3, -4), Vector2(6, 8)), Color(0.9, 0.7, 0.3))
		# vaga-lumes
		for k in 8:
			var fx: float = 150.0 + fposmod(k * 157.0, 1000.0) + sin(rel * 0.7 + k * 1.9) * 24.0
			var fy: float = 480.0 + fposmod(k * 61.0, 150.0) + cos(rel * 0.9 + k) * 14.0
			var pisca: float = clampf(sin(rel * 2.0 + k * 2.3) * 1.6, 0.0, 1.0)
			_ci(Vector2(fx, fy), 2.0, Color(0.8, 1.0, 0.4, 0.9 * pisca))
			_halo(Vector2(fx, fy), 9.0, Color(0.8, 1.0, 0.4, 0.05 * pisca), 3)
		# terra saltando de um dos montinhos
		for k in 4:
			var t: float = fposmod(rel * 0.5 + k * 0.25, 1.0)
			_ci(Vector2(470 + (k - 1.5) * 8.0 * t * 2.0, 454.0 - sin(t * PI) * 22.0), 1.8, Color(0.5, 0.35, 0.22, 1.0 - t))

	func _anim_garagem() -> void:
		# fluorescente falhando: pisca de vez em quando
		var ciclo: float = fposmod(rel, 6.0)
		var luz: float = 1.0
		if ciclo > 4.2 and ciclo < 4.6:
			luz = 0.35 + 0.65 * (1.0 if int(rel * 12.0) % 2 == 0 else 0.0)
		draw_rect(Rect2(478, 88, 304, 10), Color(0.92, 0.98, 1.0, luz))
		_halo(Vector2(630, 100), 200.0, Color(0.8, 0.92, 1.0, 0.014 * luz), 8)
		draw_polygon(PackedVector2Array([Vector2(480, 98), Vector2(780, 98), Vector2(960, 450), Vector2(300, 450)]), PackedColorArray([Color(0.85, 0.95, 1.0, 0.035 * luz), Color(0.85, 0.95, 1.0, 0.035 * luz), Color(0.85, 0.95, 1.0, 0.0), Color(0.85, 0.95, 1.0, 0.0)]))
		# roda da bicicleta girando de leve (raio marcado)
		var ang: float = sin(rel * 0.6) * 0.4
		_ln(Vector2(650, 403), Vector2(650, 403) + Vector2(cos(ang), sin(ang)) * 36.0, Color(0.9, 0.9, 0.95, 0.5), 1.0)
		# gota da prateleira
		var t: float = fposmod(rel * 0.5, 1.0)
		if t < 0.9:
			_ci(Vector2(560, 392.0 + t * t * 56.0), 2.0, Color(0.6, 0.75, 0.9, 0.9))
		_poeira(Rect2(300, 130, 500, 300), 14, Color(0.9, 0.95, 1.0, 0.5), 5.0)

	func _anim_telhado() -> void:
		# fumaça da chaminé subindo e se desfazendo
		for k in 6:
			var t: float = fposmod(rel * 0.18 + k / 6.0, 1.0)
			_ci(Vector2(1055.0 + sin(rel * 0.8 + k * 1.7) * 10.0 + t * 70.0, 222.0 - t * 150.0), 8.0 + t * 20.0, Color(0.55, 0.6, 0.78, 0.22 * (1.0 - t)))
		# luz vermelha piscando na ponta da antena
		var on: bool = fposmod(rel, 1.6) < 0.5
		if on:
			_ci(Vector2(430, 164), 3.0, Color(1.0, 0.25, 0.2))
			_halo(Vector2(430, 164), 14.0, Color(1.0, 0.25, 0.2, 0.06), 3)
		# nuvem fina atravessando a lua devagar
		var cx: float = -200.0 + fposmod(rel * 6.0, 1700.0)
		_elipse_a(Vector2(cx, 150), 130, 11, Color(0.45, 0.5, 0.72, 0.28))
		_elipse_a(Vector2(cx + 60, 160), 90, 8, Color(0.45, 0.5, 0.72, 0.22))
		# estrelas cintilando
		for k in 10:
			var sx: float = fposmod(k * 197.0 + 8 * 53.0, 1280.0)
			var sy: float = fposmod(k * 83.0 + 8 * 29.0, 280.0)
			var tw: float = 0.5 + 0.5 * sin(rel * 2.0 + k * 1.7)
			_ci(Vector2(sx, sy), 2.0, Color(1, 1, 0.95, 0.35 * tw))

	func _elipse_a(c: Vector2, rx: float, ry: float, cor: Color) -> void:
		var pts := PackedVector2Array()
		for i in 18:
			var a: float = TAU * i / 18.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, cor)

	func _anim_rua() -> void:
		# lâmpada do poste tremendo, com mariposas em volta
		var fl: float = 0.5 + 0.5 * sin(rel * 17.0) * sin(rel * 3.1)
		_halo(Vector2(704, 106), 150.0, Color(1.0, 0.78, 0.4, 0.012 + 0.003 * fl), 9)
		_ci(Vector2(704, 100), 6.0, Color(1.0, 0.95, 0.7))
		for k in 4:
			var mx: float = 704.0 + cos(rel * (1.6 + k * 0.4) + k * 1.9) * (22.0 + k * 8.0)
			var my: float = 104.0 + sin(rel * (2.1 + k * 0.3) + k) * (14.0 + k * 4.0)
			_ci(Vector2(mx, my), 1.6, Color(0.95, 0.9, 0.75, 0.9))
		# janelas dos prédios piscando (tevê)
		var tv: float = 0.5 + 0.5 * sin(rel * 4.0)
		draw_rect(Rect2(528, 112, 14, 18), Color(0.5, 0.7, 1.0, 0.25 + 0.35 * tv))
		# papel de bala rolando pela calçada, com o vento
		var px: float = fposmod(rel * 40.0, 1500.0) - 100.0
		draw_rect(Rect2(px, 500.0 + sin(rel * 6.0) * 3.0, 12, 8), Color(0.85, 0.85, 0.75, 0.85))
		# gotinha do hidrante
		var t: float = fposmod(rel * 0.8, 1.0)
		if t < 0.9:
			_ci(Vector2(1054, 420.0 + t * t * 26.0), 2.0, Color(0.6, 0.8, 1.0, 0.9))
		# vapor do bueiro
		for k in 3:
			var tt: float = fposmod(rel * 0.4 + k * 0.33, 1.0)
			_ci(Vector2(1050 + sin(rel * 1.5 + k) * 8.0 + k * 10.0, 704.0 - tt * 40.0), 6.0 + tt * 8.0, Color(0.85, 0.88, 0.95, 0.12 * (1.0 - tt)))

	func _anim_toca() -> void:
		# chama das lanternas tremendo
		for i in 2:
			var lx: float = 340.0 + i * 600.0
			var fo: float = 0.5 + 0.5 * sin(rel * 9.0 + i * 2.0) * sin(rel * 5.3 + i)
			_halo(Vector2(lx, 190), 130.0, Color(1.0, 0.65, 0.25, 0.010 + 0.004 * fo), 10)
			_halo(Vector2(lx, 190), 45.0, Color(1.0, 0.85, 0.4, 0.03 + 0.012 * fo), 6)
		# terra caindo do teto
		for k in 5:
			var t: float = fposmod(rel * 0.35 + k * 0.2, 1.0)
			var x: float = 160.0 + fposmod(k * 233.0, 980.0)
			_ci(Vector2(x, 90.0 + t * 330.0), 1.8, Color(0.55, 0.38, 0.25, 0.9 * (1.0 - t * 0.6)))
		# brilho das moedas
		for k in 4:
			var br: float = clampf(sin(rel * 2.0 + k * 1.6) * 2.0, 0.0, 1.0)
			_ci(Vector2(236.0 + k * 66.0, 440.0), 3.0, Color(1.0, 0.95, 0.6, 0.8 * br))
		_poeira(Rect2(260, 100, 780, 340), 20, Color(1.0, 0.85, 0.6, 0.5), 5.0)
	# ---- cenas das ruas (ato 3)
	func _anim_mercado() -> void:
		# placa de néon do peixe: pisca de vez em quando
		var ciclo: float = fposmod(rel, 5.0)
		var luz: float = 1.0
		if ciclo > 3.6 and ciclo < 4.0:
			luz = 0.3 + 0.7 * (1.0 if int(rel * 14.0) % 2 == 0 else 0.0)
		_neon_peixe(Vector2(1180, 136), Color(0.3, 0.95, 1.0, luz), 2.0)
		_halo(Vector2(1180, 136), 70.0, Color(0.3, 0.9, 1.0, 0.018 * luz), 5)
		# lâmpada do poste, tremendo de leve
		var fl: float = 0.5 + 0.5 * sin(rel * 13.0) * sin(rel * 2.3)
		_halo(Vector2(645, 148), 130.0, Color(1.0, 0.85, 0.5, 0.012 + 0.003 * fl), 8)
		draw_rect(Rect2(622, 142, 46, 5), Color(1.0, 0.95, 0.7))
		# luz vermelha do guindaste
		if fposmod(rel, 1.8) < 0.6:
			_ci(Vector2(912, 90), 3.0, Color(1.0, 0.25, 0.2))
			_halo(Vector2(912, 90), 16.0, Color(1.0, 0.25, 0.2, 0.06), 3)
		# brilhos na água do porto
		for k in 8:
			var t: float = fposmod(rel * 0.2 + k * 0.137, 1.0)
			var gx: float = fposmod(k * 211.0, 1280.0)
			var gy: float = 306.0 + fposmod(k * 29.0, 60.0)
			_ln(Vector2(gx, gy), Vector2(gx + 28.0, gy), Color(0.8, 0.95, 1.0, 0.3 * sin(t * PI)), 1.0)
		# neblina baixa passando rente ao cais
		for k in 5:
			var nx: float = fposmod(rel * 14.0 + k * 300.0, 1700.0) - 200.0
			_elipse_a(Vector2(nx, 436.0 + (k % 2) * 8.0), 150, 9, Color(0.7, 0.85, 0.95, 0.07))

	func _anim_ferrovelho() -> void:
		# faíscas do soldador, saltando da junta da torre
		var pisca: float = 0.5 + 0.5 * sin(rel * 40.0)
		_halo(Vector2(1041, 296), 26.0, Color(1.0, 0.9, 0.5, 0.04 + 0.04 * pisca), 4)
		_ci(Vector2(1041, 296), 4.0, Color(1.0, 0.97, 0.8))
		for k in 8:
			var t: float = fposmod(rel * 1.4 + k * 0.125, 1.0)
			var dx: float = (float((k * 5) % 7) - 3.0) * 18.0 * t
			var py: float = 296.0 - 46.0 * t + 120.0 * t * t
			_ci(Vector2(1041.0 + dx, py), 2.0, Color(1.0, 0.85 - 0.45 * t, 0.3, 1.0 - t))
		# barril em chamas
		var fo: float = 0.5 + 0.5 * sin(rel * 9.0) * sin(rel * 5.3)
		for i in 3:
			var h: float = 34.0 + 16.0 * sin(rel * 11.0 + i * 1.9)
			var fx: float = 716.0 - 11.0 + i * 11.0
			draw_colored_polygon(PackedVector2Array([Vector2(fx - 9, 386), Vector2(fx + sin(rel * 7.0 + i) * 4.0, 386.0 - h), Vector2(fx + 9, 386)]), Color(1.0, 0.42, 0.1, 0.95))
			draw_colored_polygon(PackedVector2Array([Vector2(fx - 5, 386), Vector2(fx, 386.0 - h * 0.6), Vector2(fx + 5, 386)]), Color(1.0, 0.85, 0.3, 0.95))
		_halo(Vector2(716, 370), 120.0, Color(1.0, 0.55, 0.2, 0.012 + 0.004 * fo), 8)
		for k in 4:
			var tt: float = fposmod(rel * 0.6 + k * 0.25, 1.0)
			_ci(Vector2(716.0 + sin(rel * 3.0 + k) * 10.0, 380.0 - tt * 90.0), 1.6, Color(1.0, 0.75, 0.3, 1.0 - tt))
		# calor do sol baixo e poeira no ar
		_halo(Vector2(900, 326), 150.0, Color(1.0, 0.7, 0.3, 0.012 + 0.004 * sin(rel * 2.0)), 6)
		_poeira(Rect2(300, 300, 700, 140), 16, Color(1.0, 0.8, 0.5, 0.5), 4.0)

	## Sprites de 7x5 das telas dos fliperamas.
	const INVASOR: Array[String] = ["0010100", "0111110", "1101011", "1111111", "1010101"]
	const FANTASMA: Array[String] = ["0111110", "1111111", "1011101", "1111111", "1010101"]

	## x na altura y da linha de fuga k da grade do chão (mesma conta do Fundo).
	func _xp(k: float, esp: float, y: float) -> float:
		var x0: float = 640.0 + k * esp
		var xe: float = 640.0 + (x0 - 640.0) * ((740.0 - 180.0) / (447.0 - 180.0))
		return x0 + (xe - x0) * (y - 447.0) / 293.0

	func _anim_beco() -> void:
		var cian := Color(0.2, 0.85, 0.95)
		var laranja := Color(1.0, 0.55, 0.15)
		# letreiro: néon aceso; a letra "I" (a 3ª) falha de vez em quando
		var cic: float = fposmod(rel, 4.0)
		for n in 9:
			var apagada: bool = n == 2 and cic > 2.6 and cic < 3.2 and int(rel * 10.0) % 2 == 0
			if not apagada:
				_letras(436.0, 112.0, "FLIPERAMA", 8.0, cian, n)
		_halo(Vector2(640, 140), 230.0, Color(cian.r, cian.g, cian.b, 0.012), 6)
		_neon_fantasma(Vector2(340, 138), laranja, 2.0)
		if fposmod(rel, 3.0) < 2.4:
			_neon_fantasma(Vector2(948, 138), Color(0.9, 0.25, 0.65), 2.0)
		# telas dos fliperamas
		var cores: Array[Color] = [cian, Color(0.9, 0.25, 0.65), laranja]
		for k in 8:
			var x: float = 250.0 + k * 92.0
			var cor: Color = cores[k % 3]
			var sx: float = x + 12.0
			var sy: float = 447.0 - 168.0 + 36.0
			var pulso: float = 0.7 + 0.3 * sin(rel * 3.0 + k)
			draw_rect(Rect2(sx, sy, 56, 52), Color(cor.r * 0.4 * pulso, cor.g * 0.4 * pulso, cor.b * 0.4 * pulso))
			var spr: Array[String] = INVASOR if k % 2 == 0 else FANTASMA
			var ox: float = sx + 12.0 + float(int(rel * 2.0 + k) % 3 - 1) * 4.0
			var oy: float = sy + 10.0 + float(int(rel + k) % 2) * 4.0
			for r in 5:
				for c in 7:
					if spr[r][c] == "1":
						draw_rect(Rect2(ox + c * 4.0, oy + r * 4.0, 4, 4), cor.lightened(0.55))
			draw_rect(Rect2(sx + 4, sy + 44, 48, 4), Color(cor.r, cor.g, cor.b, 0.6))
			draw_rect(Rect2(x + 10, 447.0 - 168.0 + 10.0, 60, 4), cor.lightened(0.25))
			_elipse_a(Vector2(x + 40.0, 458.0), 56.0, 7.0, Color(cor.r, cor.g, cor.b, 0.05))
		# a grade do chão pulsa em onda, do fundo para a frente
		for k in range(-12, 13):
			var al: float = 0.16 * (0.5 + 0.5 * sin(rel * 2.5 - k * 0.5))
			_ln(Vector2(_xp(k, 110.0, 447.0), 447), Vector2(_xp(k, 110.0, 740.0), 740), Color(cian.r, cian.g, cian.b, al), 1.0)
		var ys: Array[float] = [466.0, 490.0, 520.0, 556.0, 600.0, 652.0, 712.0]
		for r in ys.size():
			var al2: float = 0.16 * (0.5 + 0.5 * sin(rel * 2.5 - r * 0.9))
			_ln(Vector2(-40, ys[r]), Vector2(1320, ys[r]), Color(cian.r, cian.g, cian.b, al2), 1.0)
		# fumaça baixa
		for k in 5:
			var nx: float = fposmod(rel * 10.0 + k * 300.0, 1700.0) - 200.0
			_elipse_a(Vector2(nx, 440.0 + (k % 2) * 8.0), 140, 9, Color(0.6, 0.5, 0.8, 0.07))

	func _anim_arena() -> void:
		# relâmpago: a cada 7 s o céu acende e um raio aparece entre as nuvens
		var ciclo: float = fposmod(rel, 7.0)
		if ciclo > 5.2 and ciclo < 5.6:
			var f: float = 1.0 if int(rel * 12.0) % 2 == 0 else 0.5
			draw_rect(Rect2(-40, -40, 1360, 330), Color(0.85, 0.88, 1.0, 0.14 * f))
			_pl(PackedVector2Array([Vector2(820, 20), Vector2(790, 90), Vector2(812, 100), Vector2(764, 200), Vector2(786, 206), Vector2(748, 284)]), Color(0.95, 0.95, 1.0, 0.95), 2.0)
		# estandartes vermelhos balançando nas colunas inteiras
		for bx in [330.0, 1070.0]:
			var sw: float = sin(rel * 1.6 + bx) * 5.0
			draw_rect(Rect2(bx - 26, 164, 52, 5), Color(0.55, 0.42, 0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 22, 169), Vector2(bx + 22, 169), Vector2(bx + 22 + sw, 284), Vector2(bx + sw, 262), Vector2(bx - 22 + sw, 284)]), Color(0.72, 0.14, 0.1))
			_pl(PackedVector2Array([Vector2(bx - 10 + sw * 0.4, 236), Vector2(bx + sw * 0.4, 190), Vector2(bx + 10 + sw * 0.4, 236)]), Color(0.95, 0.78, 0.35), 2.0)
		# braseiros
		for bx in [590.0, 790.0]:
			var fo: float = 0.5 + 0.5 * sin(rel * 9.0 + bx) * sin(rel * 5.3)
			for i in 3:
				var h: float = 28.0 + 14.0 * sin(rel * 11.0 + i * 1.9 + bx)
				var fx: float = bx - 10.0 + i * 10.0
				draw_colored_polygon(PackedVector2Array([Vector2(fx - 9, 330), Vector2(fx + sin(rel * 7.0 + i) * 4.0, 330.0 - h), Vector2(fx + 9, 330)]), Color(1.0, 0.42, 0.1, 0.95))
				draw_colored_polygon(PackedVector2Array([Vector2(fx - 5, 330), Vector2(fx, 330.0 - h * 0.6), Vector2(fx + 5, 330)]), Color(1.0, 0.85, 0.3, 0.95))
			_halo(Vector2(bx, 312), 120.0, Color(1.0, 0.6, 0.25, 0.012 + 0.004 * fo), 8)
		_poeira(Rect2(500, 200, 380, 240), 12, Color(1.0, 0.75, 0.4, 0.5), 6.0)

	func _anim_antenas() -> void:
		var roxo := Color(0.62, 0.30, 0.90)
		var tc: float = 1010.0
		# raio entre os arranha-céus, a cada 6 s
		var ciclo: float = fposmod(rel + 2.0, 6.0)
		if ciclo > 4.4 and ciclo < 4.8:
			var f: float = 1.0 if int(rel * 12.0) % 2 == 0 else 0.5
			draw_rect(Rect2(-40, -40, 1360, 300), Color(0.8, 0.7, 1.0, 0.12 * f))
			_pl(PackedVector2Array([Vector2(560, 10), Vector2(540, 80), Vector2(566, 90), Vector2(520, 190), Vector2(544, 196), Vector2(500, 270)]), Color(0.95, 0.9, 1.0, 0.95), 2.0)
		# luzes de aviso da torre, em revezamento
		var ly: Array[float] = [34.0, 168.0, 300.0]
		for k in 3:
			if fposmod(rel + k * 0.5, 1.5) < 0.6:
				_ci(Vector2(tc, ly[k]), 3.0, Color(1.0, 0.25, 0.2))
				_halo(Vector2(tc, ly[k]), 16.0, Color(1.0, 0.25, 0.2, 0.06), 3)
		# campo magnético: linhas de força que saem da torre e se abrem, sumindo
		for k in 4:
			var fase: float = fposmod(rel * 0.4 + k * 0.25, 1.0)
			var rx: float = 36.0 + fase * 180.0
			var pts := PackedVector2Array()
			for i in 25:
				var a: float = TAU * i / 24.0
				pts.append(Vector2(tc + cos(a) * rx, 232.0 + sin(a) * 196.0))
			_pl(pts, Color(0.78, 0.55, 1.0, 0.5 * (1.0 - fase)), 1.0)
		_halo(Vector2(tc, 34), 44.0, Color(roxo.r, roxo.g, roxo.b, 0.03 + 0.02 * sin(rel * 6.0)), 4)
		# faísca na ponta da parabólica
		if fposmod(rel, 2.2) < 0.25:
			_ci(Vector2(860, 320), 3.0, Color(0.9, 0.8, 1.0))
			_halo(Vector2(860, 320), 14.0, Color(0.8, 0.6, 1.0, 0.06), 3)
		# estrelas cintilando
		for k in 8:
			var sx: float = fposmod(k * 197.0 + 15 * 53.0, 1280.0)
			var sy: float = fposmod(k * 83.0 + 15 * 29.0, 200.0)
			var tw: float = 0.5 + 0.5 * sin(rel * 2.0 + k * 1.7)
			_ci(Vector2(sx, sy), 2.0, Color(1, 1, 0.95, 0.35 * tw))
		_poeira(Rect2(300, 250, 700, 180), 10, Color(0.8, 0.7, 1.0, 0.45), 4.0)

## Sombreador do cenário: quantiza as cores em poucos tons e as mistura com pontilhado
## ordenado (Bayer 4x4) na grade de 320x180, e escurece 1 pixel no lado escuro das bordas.
const SHADER_PIXEL := """
shader_type canvas_item;
uniform vec2 res = vec2(320.0, 180.0);
uniform float niveis = 12.0;
uniform float contorno = 0.0;
uniform float alfa_niveis = 0.0;
uniform float pontilhado = 1.0;
const float B[16] = float[16](0.0,8.0,2.0,10.0,12.0,4.0,14.0,6.0,3.0,11.0,1.0,9.0,15.0,7.0,13.0,5.0);
float lum(vec3 c) { return dot(c, vec3(0.3, 0.55, 0.15)); }
void fragment() {
	vec2 px = floor(UV * res);
	int i = int(mod(px.x, 4.0)) + 4 * int(mod(px.y, 4.0));
	float d = ((B[i] + 0.5) / 16.0 - 0.5) * pontilhado;
	vec2 uv = (px + 0.5) / res;
	vec4 c = texture(TEXTURE, uv);
	if (contorno > 0.5) {
		float l = lum(c.rgb);
		float m = 0.0;
		m = max(m, lum(texture(TEXTURE, uv + vec2(1.0, 0.0) / res).rgb) - l);
		m = max(m, lum(texture(TEXTURE, uv + vec2(-1.0, 0.0) / res).rgb) - l);
		m = max(m, lum(texture(TEXTURE, uv + vec2(0.0, 1.0) / res).rgb) - l);
		m = max(m, lum(texture(TEXTURE, uv + vec2(0.0, -1.0) / res).rgb) - l);
		c.rgb *= 1.0 - 0.45 * step(0.07, m);
	}
	c.rgb = floor(c.rgb * niveis + d + 0.5) / niveis;
	if (alfa_niveis > 0.5) {
		c.a = floor(c.a * alfa_niveis + d + 0.5) / alfa_niveis;
	}
	COLOR = c;
}
"""
const AQUECEDOR := preload("res://scripts/arte/aquecedor.gd")
var aquecedor: Node2D = null          # pré-aquece as poses dos bichos da onda enquanto o jogador arruma o time
var vp_fundo: SubViewport = null
var vp_anim: SubViewport = null
var anim: Animado = null
var fundo_rep: int = 0

## A animação da torre é um SubViewport que renderiza todo quadro; com o campo escondido (mapa, guarda-roupa, menus)
## ele não precisa renderizar.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and vp_anim != null:
		vp_anim.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED

func _novo_vp(transparente: bool) -> SubViewport:
	var v := SubViewport.new()
	v.size = Vector2i(320, 180)
	v.transparent_bg = transparente
	v.disable_3d = true
	v.msaa_2d = Viewport.MSAA_DISABLED
	v.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS if transparente else SubViewport.UPDATE_ONCE
	add_child(v)
	return v

func _nova_tela(v: SubViewport, transparente: bool) -> void:
	var s := Sprite2D.new()
	s.texture = v.get_texture()
	s.centered = false
	s.scale = Vector2(4, 4)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.show_behind_parent = true
	var sh := Shader.new()
	sh.code = SHADER_PIXEL
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("contorno", 0.0 if transparente else 1.0)
	m.set_shader_parameter("alfa_niveis", 10.0 if transparente else 0.0)
	m.set_shader_parameter("niveis", float(CENARIO_TONS))  # menos tons = pontilhado mais ruidoso; 12 ficava com cara de tela
	m.set_shader_parameter("pontilhado", 1.0 if CENARIO_PONTILHADO else 0.0)
	s.material = m
	add_child(s)

func _cenario() -> void:
	if fundo == null:
		vp_fundo = _novo_vp(false)
		fundo = Fundo.new()
		fundo.scale = Vector2(0.25, 0.25)
		vp_fundo.add_child(fundo)
		_nova_tela(vp_fundo, false)
		vp_anim = _novo_vp(true)
		anim = Animado.new()
		anim.scale = Vector2(0.25, 0.25)
		vp_anim.add_child(anim)
		_nova_tela(vp_anim, true)
	var cena: int = _cena()
	if fundo.fase != cena or not fundo_ok:
		fundo.fase = cena
		fundo.queue_redraw()
		fundo_ok = true
		fundo_rep = 3
	if fundo_rep > 0:
		# atualização única do fundo; repetida por alguns quadros só para garantir o primeiro desenho
		fundo_rep -= 1
		vp_fundo.render_target_update_mode = SubViewport.UPDATE_ONCE
	anim.fase = cena
	anim.tijolos = estado.tijolos
	anim.pulso_torre = torre_pulso * 0.6
	anim.pulso_bau = bau_pulso
	anim.torre_pixel = TORRE_EM_PIXEL and not TORRE_FORTALEZA
	anim.caixa_pixel = CAIXA_EM_PIXEL
	anim.rel = floorf(rel * 12.0) / 12.0
	anim.queue_redraw()

## Número do cenário: 1..5 os cômodos, 6..10 os lugares de fora (quando desenhados; senão, o cômodo de mesmo número).
func _cena() -> int:
	return estado.lugar() + 1 if CENARIOS_DE_FORA else estado.fase

func _bau_desenho() -> void:
	var sc: float = 1.0 + 0.25 * bau_pulso
	var pulo_b: float = sin(bau_pulso * PI) * 12.0
	draw_set_transform(BAU_POS + Vector2(0, -pulo_b), 0.0, Vector2(sc, sc))
	if CAIXA_EM_PIXEL:
		# etiqueta da caixa: uma roupinha de pixel (o que vai para lá são peças de roupa)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		IconesPoder.desenhar(self, IconesPoder.PECA, BAU_POS + Vector2(0, -8.0 - roundf(pulo_b)), 2 if sc < 1.12 else 3)
		var sc_n: float = 1.0 + 0.7 * bau_pulso * bau_pulso
		draw_set_transform(Vector2(BAU_POS.x, BAU_POS.y + 38), 0.0, Vector2(sc_n, sc_n))
		Desenho.texto(self, str(bau_n), Vector2(-40, 0), 18, Color(1, 0.95 - 0.1 * bau_pulso, 0.7), 80.0, 3)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	# caixa de brinquedos
	draw_circle(Vector2(-14, -34), 9.0, Color(0.9, 0.3, 0.3))
	draw_circle(Vector2(8, -35), 7.0, Color(0.96, 0.78, 0.3))
	draw_circle(Vector2(20, -33), 5.0, Color(0.9, 0.7, 0.55))
	draw_rect(Rect2(-30, -26, 60, 34), Color(0.3, 0.5, 0.8))
	draw_rect(Rect2(-30, -26, 60, 34), Color(0.12, 0.2, 0.4), false, 2.5)
	draw_rect(Rect2(-33, -29, 66, 8), Color(0.95, 0.76, 0.3))
	draw_rect(Rect2(-33, -29, 66, 8), Color(0.4, 0.28, 0.08), false, 2.0)
	draw_circle(Vector2(0, -8), 8.0, Color(0.99, 0.95, 0.82))
	Desenho.texto(self, "B", Vector2(-8, -3), 14, Color(0.2, 0.35, 0.6), 16.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Desenho.texto(self, str(bau_n), Vector2(BAU_POS.x - 40, BAU_POS.y + 38), 18, Color(1, 0.95, 0.7), 80.0, 3)

# ---------------------------------------------------------------- barra de poderes
## Recorte em 9 fatias (cópia do que `principal.gd` faz): cantos fixos, bordas e miolo repetidos.
static func _ladrilhar(c: CanvasItem, tex: Texture2D, s: Rect2, d: Rect2, esc: float, cor: Color) -> void:
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

static func _nove(c: CanvasItem, tex: Texture2D, src: Rect2, m: Vector4, dst: Rect2, esc: float, cor: Color = Color.WHITE, miolo: bool = true) -> void:
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
	_ladrilhar(c, tex, Rect2(sx + m.x, sy, iw, m.y), Rect2(x1, y0, x2 - x1, mt), e, cor)
	_ladrilhar(c, tex, Rect2(sx + m.x, sy + src.size.y - m.w, iw, m.w), Rect2(x1, y2, x2 - x1, mb), e, cor)
	_ladrilhar(c, tex, Rect2(sx, sy + m.y, m.x, ih), Rect2(x0, y1, ml, y2 - y1), e, cor)
	_ladrilhar(c, tex, Rect2(sx + src.size.x - m.z, sy + m.y, m.z, ih), Rect2(x2, y1, mr, y2 - y1), e, cor)
	if miolo:
		_ladrilhar(c, tex, Rect2(sx + m.x, sy + m.y, iw, ih), Rect2(x1, y1, x2 - x1, y2 - y1), e, cor)

## A camada de menus (filha de `principal.gd`), para dicas e para saber se há menu aberto.
func _menus() -> Menus:
	var pai: Node = get_parent()
	if pai != null:
		var m: Variant = pai.get("menus")
		if m is Menus:
			return m
	return null

## Cria um botão por gato do time com fantasia completa e posiciona a barra, centralizada.
func _montar_poderes() -> void:
	poder_btns.clear()
	poder_de.clear()
	poder_hover = -1
	poder_preso = -1
	poder_dica_ok = false
	poder_seta = -1
	poder_seta_t = 0.0
	poder_sem_aviso = false
	for u in sim.aliados:
		var uu: Unidade = u
		if uu.poder < 0:
			continue
		var cj: int = clampi(uu.poder_conj, 0, Pecas.PODER_NOME.size() - 1)
		var b: Dictionary = {
			"u": uu, "conj": cj, "poder": uu.poder, "cor": _cor_legivel(Pecas.CONJUNTO_COR[cj], 0.55),
			"nome": Pecas.PODER_NOME[cj], "dica": Pecas.PODER_DICA[cj], "tecla": poder_btns.size() + 1,
			"rect": Rect2(), "pronto": false, "trancado": false, "carga_ant": 0.0, "flash": 0.0,
			"tremor": 0.0, "motivo": "", "motivo_t": 0.0, "variante": estado.bonecos.find(uu.boneco),
		}
		poder_de[uu] = poder_btns.size()
		poder_btns.append(b)
	var n: int = poder_btns.size()
	var larg: float = n * PB_W + maxf(0.0, n - 1.0) * PB_GAP
	var x0: float = roundf(PB_CENTRO_X - larg * 0.5)
	for i in n:
		poder_btns[i]["rect"] = Rect2(x0 + i * (PB_W + PB_GAP), PB_Y, PB_W, PB_H)
	if n == 0 and not Menus.dicas_vistas.get("sem_poder", false):
		poder_sem_aviso = true
		Menus.dicas_vistas["sem_poder"] = true   # só na primeira luta sem nenhum poder

## Relógios e transições da barra (carga, pronto, clarão, tremida) e a dica de primeira vez.
func _atualizar_poderes(delta: float) -> void:
	poder_seta_t = maxf(0.0, poder_seta_t - delta)
	for i in poder_btns.size():
		var b: Dictionary = poder_btns[i]
		var u: Unidade = b["u"]
		var carga: float = sim.carga_poder(u) if u.vivo else 0.0
		if float(b["carga_ant"]) >= 0.99 and carga < 0.5:
			b["flash"] = 1.0   # o poder saiu (clique, tecla ou automático)
			b["pop"] = 1.0
			if i == poder_seta:
				poder_seta_t = 0.0
		b["carga_ant"] = carga
		var pronto: bool = u.vivo and u.poder_cd <= 0.0
		b["trancado"] = u.vivo and u.atordoado_t > 0.0
		if pronto and not bool(b["pronto"]) and sim.poder_manual and not poder_dica_ok:
			poder_dica_ok = true
			poder_seta = i
			poder_seta_t = 7.0
			# a explicação do botão vem da aula "a_poder" (tutorial.gd)
		if pronto and not bool(b["pronto"]) and rel > 0.5:
			_som("poder_pronto", 1.0, -3.0, true)
			b["brilho"] = 1.0
		b["pronto"] = pronto
		b["brilho"] = maxf(0.0, float(b.get("brilho", 0.0)) - delta * 1.6)
		b["pop"] = maxf(0.0, float(b.get("pop", 0.0)) - delta * 5.0)
		b["flash"] = maxf(0.0, float(b["flash"]) - delta * 3.0)
		b["tremor"] = maxf(0.0, float(b["tremor"]) - delta)
		b["motivo_t"] = maxf(0.0, float(b["motivo_t"]) - delta)

## O sinal no campo (anel no chão e ícone na cabeça) só aparece com o poder carregado e à espera do jogador.
func _poder_aguarda(u: Unidade) -> int:
	if not sim.poder_manual or not poder_de.has(u):
		return -1
	var i: int = poder_de[u]
	var b: Dictionary = poder_btns[i]
	if u.vivo and bool(b["pronto"]) and not bool(b["trancado"]) and not u.poder_armado:
		return i
	return -1

## Anel na cor da fantasia embaixo do gato com poder carregado; mais forte sob o mouse no botão.
## Chamado com a transformação achatada do chão já ativa (origem nos pés).
func _anel_poder_chao(u: Unidade) -> void:
	if u.equipe != 0 or not poder_de.has(u):
		return
	var i: int = poder_de[u]
	var b: Dictionary = poder_btns[i]
	var cor: Color = b["cor"]
	var esc_u: float = esc_tela(u)
	var destaque: bool = poder_hover == i and u.vivo
	var pe_u: Vector2 = Vector2(u.vx, u.vy)
	if _poder_aguarda(u) >= 0:
		var pu: float = 0.5 + 0.5 * sin(rel * 5.0 + i)
		V.elipse(self, pe_u, 40.0 * esc_u, 12.0 * esc_u, Color(cor.r, cor.g, cor.b, 0.10 + 0.08 * pu))
		V.aro(self, pe_u, 42.0 * esc_u + V.Q, 13.0 * esc_u + V.Q, V.CONT, 1.0, 2.0)
		V.aro(self, pe_u, 42.0 * esc_u, 13.0 * esc_u, cor, 0.7 + 0.3 * pu, 1.5)
		V.aro(self, pe_u, 36.0 * esc_u, 11.0 * esc_u, Color(1, 1, 1), 0.3 + 0.3 * pu, 1.0)
	if destaque:
		V.aro(self, pe_u, 50.0 * esc_u, 15.0 * esc_u, V.CONT, 1.0, 3.0)
		V.aro(self, pe_u, 50.0 * esc_u, 15.0 * esc_u, Color(1.0, 0.97, 0.8), 1.0, 2.0)

const HER_SELO := 48.0               # selo de herança: aro de 1 + ícone de 10 + aro de 1 quadradinhos de V.Q
const HER_FX_DUR := 0.9              # quanto o selinho fica sobre o gato quando a herança dispara (s)
const HER_ROXO := Color(0.72, 0.56, 1.0)
const HER_MIOLO := Color(0.16, 0.08, 0.26)

## Selo de herança (o mesmo do guarda-roupa): ícone do poder no miolo escuro, aro roxo de cantos cortados com brilho
## e sombra; `contorno` põe a borda escura de fora (sobre o cenário). Tudo na grade V.Q, opaco.
func _selo_heranca(c: Vector2, poder: int, contorno: bool) -> void:
	var q: float = V.Q
	var l: float = HER_SELO
	var x: float = V.sn(c.x - l * 0.5 + q * 0.5)
	var y: float = V.sn(c.y - l * 0.5 + q * 0.5)
	if contorno:
		draw_rect(Rect2(x, y - q, l, l + q * 2.0), V.CONT)
		draw_rect(Rect2(x - q, y, l + q * 2.0, l), V.CONT)
	draw_rect(Rect2(x + q, y, l - q * 2.0, l), HER_ROXO)
	draw_rect(Rect2(x, y + q, l, l - q * 2.0), HER_ROXO)
	draw_rect(Rect2(x + q, y, q * 4.0, q), V.tom(HER_ROXO, 1.55))
	draw_rect(Rect2(x, y + q, q, q * 3.0), V.tom(HER_ROXO, 1.55))
	draw_rect(Rect2(x + l - q * 5.0, y + l - q, q * 4.0, q), V.tom(HER_ROXO, 0.55))
	draw_rect(Rect2(x + l - q, y + l - q * 4.0, q, q * 3.0), V.tom(HER_ROXO, 0.55))
	draw_rect(Rect2(x + q, y + q, l - q * 2.0, l - q * 2.0), HER_MIOLO)
	IconesPoder.desenhar(self, poder, Vector2(x + l * 0.5, y + l * 0.5), int(V.Q), 1.0, q)

## Selinho da herança que acabou de disparar: nasce rente à cabeça do gato, sobe um pouco, atrás do balão do poder
## carregado (para não cobri-lo), e pisca antes de sumir (sem alfa).
func _selo_heranca_gato(hf: Dictionary) -> void:
	var u: Unidade = hf["u"]
	if u == null or not u.vivo:
		return
	var tt: float = float(hf["t"])
	if tt > HER_FX_DUR - 0.25 and int(tt / 0.06) % 2 == 1:
		return
	var esc_u: float = esc_tela(u)
	var sobe: float = minf(tt / 0.14, 1.0)
	var p := Vector2(u.vx - 40.0 - (HER_SELO + V.Q * 3.0) * int(hf.get("k", 0)), u.vy - (CORPO_ALT + 6.0) * esc_u - 12.0 - 16.0 * sobe - 9.0 * tt)
	_selo_heranca(p, int(hf["poder"]), true)

## Ícone sobre a cabeça do gato com poder carregado: o número da tecla, na cor da fantasia.
func _icone_poder_gato(u: Unidade, pos: Vector2, esc_u: float) -> void:
	var i: int = _poder_aguarda(u)
	if i < 0:
		return
	var b: Dictionary = poder_btns[i]
	var cor: Color = b["cor"]
	var bob: float = sin(rel * 5.0 + i) * 3.0
	var p: Vector2 = Vector2(pos.x, pos.y - (CORPO_ALT + 6.0) * esc_u - 26.0 + bob)
	var px_: float = V.sn(p.x)
	var py_: float = V.sn(p.y)
	# balão na cor da fantasia com o ícone do poder (escala V.Q = a grade da luta) e a ponta para o gato
	V.quadro(self, px_ - V.Q * 3.0, py_ + V.Q * 4.0, V.Q * 7.0, V.Q * 2.0, V.CONT)
	V.quadro(self, px_ - V.Q * 2.0, py_ + V.Q * 6.0, V.Q * 5.0, V.Q * 2.0, V.CONT)
	V.quadro(self, px_ - V.Q, py_ + V.Q * 8.0, V.Q * 3.0, V.Q, V.CONT)
	V.quadro(self, px_ - V.Q, py_ + V.Q * 4.0, V.Q * 3.0, V.Q * 4.0, cor)
	V.disco_c(self, p, V.Q * 5.0, cor, V.CONT)
	V.quadro(self, px_ - V.Q * 4.0, py_ - V.Q * 3.0, V.Q, V.Q, V.tom(cor, 1.7))
	IconesPoder.desenhar(self, int(b["poder"]), Vector2(px_ + V.Q * 0.5, py_ + V.Q * 0.5), int(V.Q), 1.0, V.Q)
	# a tecla, em algarismo de pixel, na borda direita do balão
	IconesPoder.texto(self, String.num_int64(int(b["tecla"])), Vector2(px_ + V.Q * 4.0, py_ - V.Q), Color(1, 1, 1), int(V.Q))

func _btn_em(p: Vector2) -> int:
	for i in poder_btns.size():
		var r: Rect2 = poder_btns[i]["rect"]
		if r.grow(2.0).has_point(p):
			return i
	return -1

## A entrada vale com a luta visível, em andamento, sem menu aberto nem cortina.
func _poder_entrada_ok() -> bool:
	if sim == null or poder_btns.is_empty() or not is_visible_in_tree() or finalizado or sim.terminada:
		return false
	if not can_process():
		return false   # o menu de pausa desliga o processamento do Campo
	var m: Menus = _menus()
	if m != null and (m.ativo() or m.em_transicao()):
		return false
	return true

func _input(ev: InputEvent) -> void:
	if ev is InputEventMouse:
		mouse_c = (make_input_local(ev) as InputEventMouse).position if _entrada_ok() else Vector2(-1.0, -1.0)
	if prep:
		if _entrada_ok():
			_entrada_prep(ev)
		return
	if not _poder_entrada_ok():
		poder_hover = -1
		poder_preso = -1
		return
	if ev is InputEventMouseMotion:
		poder_hover = _btn_em((make_input_local(ev) as InputEventMouseMotion).position)
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = make_input_local(ev) as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		var i: int = _btn_em(mb.position)
		poder_hover = i
		if mb.pressed:
			if i >= 0:
				poder_preso = i
				get_viewport().set_input_as_handled()   # o clique não vaza para o que está por baixo
				_pedir_poder(i)
		elif poder_preso >= 0:
			poder_preso = -1
			if i >= 0:
				get_viewport().set_input_as_handled()
	elif ev is InputEventKey:
		var k: InputEventKey = ev as InputEventKey
		if not k.pressed or k.echo or k.ctrl_pressed or k.alt_pressed or k.meta_pressed:
			return
		var code: Key = k.keycode if k.keycode != KEY_NONE else k.physical_keycode
		var idx: int = -1
		match code:
			KEY_1, KEY_KP_1: idx = 0
			KEY_2, KEY_KP_2: idx = 1
			KEY_3, KEY_KP_3: idx = 2
			KEY_4, KEY_KP_4: idx = 3
			KEY_5, KEY_KP_5: idx = 4
		if idx >= 0 and idx < poder_btns.size():
			get_viewport().set_input_as_handled()
			_pedir_poder(idx)

## O jogador pede o poder do botão `i`. Não carregado: nada acontece. Sem alvo ou atordoado: o botão treme
## e o poder fica armado (sai sozinho quando aparecer alvo).
func _pedir_poder(i: int) -> void:
	if not sim.poder_manual:
		return   # modo automático: os cliques não são necessários
	var b: Dictionary = poder_btns[i]
	var u: Unidade = b["u"]
	if not u.vivo or u.poder_cd > 0.0:
		return
	var atordoado: bool = u.atordoado_t > 0.0
	if sim.disparar_poder(u):
		b["flash"] = 1.0
		b["pop"] = 1.0
		poder_seta_t = 0.0
	else:
		_recusar_poder(b, Idioma.t("atordoado") if atordoado else Idioma.t("sem alvo"))
		poder_seta_t = 0.0

func _recusar_poder(b: Dictionary, motivo: String) -> void:
	b["tremor"] = 0.4
	b["motivo"] = motivo
	b["motivo_t"] = 1.4

func _desenhar_barra_poderes_placa(n: int) -> void:
	var larg: float = n * PB_W + maxf(0.0, n - 1.0) * PB_GAP
	var r: Rect2 = Rect2(roundf(PB_CENTRO_X - larg * 0.5) - 12.0, PB_Y - 6.0, larg + 24.0, PB_H + 12.0)
	draw_rect(r, Color(0.14, 0.08, 0.1, 0.62))
	_nove(self, GUI_TEX, R_MADEIRA, M_MADEIRA, r, 0.3, Color(1, 1, 1, 0.9), false)

func _barra_poderes() -> void:
	if poder_btns.is_empty():
		if poder_sem_aviso:
			Desenho.texto(self, Idioma.t("Vista as 4 peças de uma fantasia para ganhar um poder"), Vector2(PB_CENTRO_X - 300.0, 690.0), 15, Color(1, 0.95, 0.85, 0.7), 600.0, 3)
		return
	_desenhar_barra_poderes_placa(poder_btns.size())
	for i in poder_btns.size():
		_botao_poder(i)
	var m: Menus = _menus()
	var livre: bool = m == null or not m.ativo()
	if poder_seta >= 0 and poder_seta_t > 0.0 and poder_hover != poder_seta and bool(poder_btns[poder_seta]["pronto"]) and sim.poder_manual and livre:
		_seta_primeira_vez(poder_seta)
	if poder_hover >= 0 and livre:
		_dica_poder(poder_hover)

func _botao_poder(i: int) -> void:
	var b: Dictionary = poder_btns[i]
	var u: Unidade = b["u"]
	var cor: Color = b["cor"]
	var r: Rect2 = b["rect"]
	var viva: bool = u.vivo
	var pronto: bool = bool(b["pronto"])
	var trancado: bool = bool(b["trancado"])
	var auto: bool = not sim.poder_manual
	var tr: float = float(b["tremor"])
	r = r.grow(float(b.get("pop", 0.0)) * 5.0)
	if tr > 0.0:
		r.position.x += sin(rel * 70.0) * 5.0 * clampf(tr / 0.4, 0.0, 1.0)
	var carga: float = clampf(float(b["carga_ant"]), 0.0, 1.0)
	var sobre: bool = poder_hover == i
	var apertado: bool = poder_preso == i and sobre
	var pu: float = 0.5 + 0.5 * sin(rel * 7.0 + i)
	# tinta do botão: escurecido enquanto carrega, aceso e pulsando quando pronto
	var tom: Color = Color(0.5, 0.45, 0.5)
	if not viva:
		tom = Color(0.34, 0.32, 0.38)
	elif trancado:
		tom = Color(0.5, 0.5, 0.58)
	elif pronto:
		tom = Color(1, 1, 1).lerp(cor, 0.38).lerp(Color(1, 1, 1), 0.12 * pu)
	if sobre and viva:
		tom = tom.lightened(0.14)
	if pronto and viva and not trancado:
		# moldura de pixel em volta do botão pronto: contorno escuro e a cor da fantasia, que acende em degraus
		var mold: Rect2 = _rect_grade(r.grow(V.Q * 2.0))
		_moldura_px(mold.grow(V.Q), V.CONT)
		_moldura_px(mold.grow(-V.Q), V.CONT)
		_moldura_px(mold, V.tom(cor, 1.0 + 0.2 * floorf(pu * 2.99)))
		if pu > 0.66:
			V.brilho(self, mold.position + Vector2(V.Q, V.Q), 4.0, Color(1, 1, 0.9))
			V.brilho(self, mold.end - Vector2(V.Q * 2.0, V.Q * 2.0), 4.0, Color(1, 1, 0.9))
	draw_rect(Rect2(r.position + Vector2(0, 5), r.size), Color(0, 0, 0, 0.3))
	var rb: Rect2 = r
	if apertado:
		rb = Rect2(r.position.x, r.position.y + 2.0, r.size.x, r.size.y - 2.0)
		_nove(self, BOT_TEX, R_BT_P, M_BT, rb, 0.5, tom)
	else:
		_nove(self, BOT_TEX, R_BT_N, M_BT, rb, 0.5, tom)
	var dentro: Rect2 = rb.grow(-7.0)
	# carga: sobe de baixo para cima na cor da fantasia
	if viva and carga > 0.0:
		# sobe em degraus de um quadradinho; a borda de cima é uma faixa clara de 1 quadradinho
		var alt: float = minf(dentro.size.y, V.sn(dentro.size.y * carga + V.Q * 0.5))
		if alt >= V.Q:
			var fr: Rect2 = Rect2(dentro.position.x, dentro.end.y - alt, dentro.size.x, alt)
			if carga < 1.0 and alt > V.Q:
				draw_rect(Rect2(fr.position.x, fr.position.y + V.Q, fr.size.x, alt - V.Q), Color(cor.r, cor.g, cor.b, 0.5))
				draw_rect(Rect2(fr.position.x, fr.position.y, fr.size.x, V.Q), V.tom(cor, 1.5))
			else:
				draw_rect(fr, Color(cor.r, cor.g, cor.b, 0.5 if not pronto else 0.62))
	# retrato do gato vestido (ou dormindo)
	var painel: Rect2 = Rect2(dentro.position.x + 1.0, dentro.position.y + 1.0, 48.0, dentro.size.y - 2.0)
	draw_rect(painel, Color(0.1, 0.06, 0.13, 0.62))
	draw_rect(painel, Color(0.04, 0.02, 0.06, 0.8), false, 1.0)
	Desenho.boneco(self, Vector2(painel.get_center().x, painel.end.y - 6.0), 0.58, 1.0, 0, u.pecas, 0.0, 0.0, false, 0.0, 1.0 if viva else 0.85, false, -1, 0.0, 0, false, false, 0, false, -1, false, false, int(b["variante"]), not viva)
	if trancado:
		# estrelinhas de pixel rodando sobre a cabeça (a posição gira; o desenho não)
		for k in 3:
			var ang: float = rel * 6.0 + k * TAU / 3.0
			var sp: Vector2 = Vector2(painel.get_center().x + cos(ang) * 14.0, painel.position.y + 9.0 + sin(ang) * 3.0)
			V.brilho(self, sp, 3.0, Desenho.DOURADO, Color(0.3, 0.18, 0.0))
	Desenho.texto(self, str(b["tecla"]), Vector2(painel.position.x + 3.0, painel.position.y + 14.0), 15, Color(1, 1, 1), -1.0, 4)
	# nome do poder e situação
	var tx: float = painel.end.x + 5.0
	var larg_t: float = dentro.end.x - tx - 1.0
	var nome: String = Idioma.t(str(b["nome"]))
	var tam_n: int = 19
	nome = UIComum.caber(nome, tam_n, larg_t + 6.0)   # nome comprido abrevia (não há fonte nítida menor que 19); o vizinho pronto cresce por cima da borda
	var cor_nome: Color = Color(1, 1, 1) if viva else Color(0.75, 0.75, 0.8)
	Desenho.texto(self, nome, Vector2(tx, dentro.position.y + 17.0), tam_n, cor_nome, -1.0, 4)
	var txt: String
	var cor_s: Color
	if not viva:
		txt = Idioma.t("caído")
		cor_s = Color(0.8, 0.85, 1.0)
	elif float(b["motivo_t"]) > 0.0:
		txt = str(b["motivo"])
		cor_s = Color(1.0, 0.55, 0.45)
	elif trancado:
		txt = Idioma.t("atordoado")
		cor_s = Desenho.DOURADO
	elif pronto and u.poder_armado and not auto:
		txt = Idioma.t("ARMADO")   # pedido sem alvo: sai sozinho quando aparecer
		cor_s = Desenho.DOURADO.lerp(Color(1, 1, 1), 0.3 * pu)
	elif pronto:
		txt = Idioma.t("PRONTO")
		cor_s = Color(1, 1, 1).lerp(cor, 0.25 * (1.0 - pu))
	else:
		txt = Idioma.t("%d s") % ceili(maxf(u.poder_cd, 0.0))
		cor_s = Color(1.0, 0.95, 0.85)
	# ícone do poder no começo da linha de situação (escala 2: a mesma grade de 2 px da arte do botão)
	IconesPoder.desenhar(self, int(b["poder"]), Vector2(tx + 10.0, dentro.end.y - 10.0), 2, 1.0 if viva else 0.55)
	Desenho.texto(self, txt, Vector2(tx + 23.0, dentro.end.y - 4.0), 17 if pronto and viva else 15, cor_s, -1.0, 4)
	if auto:
		# selo AUTO de pixel: plaquinha dourada com contorno e letras 3x5 na grade da luta
		var sl: float = IconesPoder.largura("AUTO", int(V.Q)) + V.Q * 2.0   # i18n-ok: selo na fonte de pixel 3x5, fixo
		var sr: Rect2 = Rect2(V.sn(r.end.x - sl - 6.0), V.sn(r.position.y - 9.0), sl, V.Q * 7.0)
		draw_rect(sr.grow(V.Q), V.CONT)
		draw_rect(sr, Desenho.DOURADO)
		draw_rect(Rect2(sr.position.x, sr.end.y - V.Q, sr.size.x, V.Q), V.tom(Desenho.DOURADO, 0.75))
		draw_rect(Rect2(sr.position.x, sr.position.y, sr.size.x, V.Q), V.tom(Desenho.DOURADO, 1.4))
		IconesPoder.texto(self, "AUTO", sr.position + Vector2(V.Q, 0.0), Color(0.3, 0.14, 0.04), int(V.Q), false)   # i18n-ok: selo na fonte de pixel 3x5, fixo
	# brilho que corre pelo botão quando o poder fica pronto: faixa inclinada em degraus de quadradinho
	var bri: float = float(b.get("brilho", 0.0))
	if bri > 0.0:
		var forca: float = sin(bri * PI)
		var cor_bri := Color(1, 1, 0.92, 0.5 if forca > 0.5 else 0.25)
		var xb: float = lerpf(r.end.x + 20.0, r.position.x - 40.0, bri)
		var y_b: float = V.sn(r.position.y)
		var passo_b: int = 0
		while y_b < r.end.y:
			var hb: float = minf(V.Q * 2.0, r.end.y - y_b)
			var xa: float = V.sn(xb + 14.0 - passo_b * V.Q)   # sobe para a direita, um quadradinho a cada 2 de altura
			var xf: float = minf(xa + V.Q * 7.0, r.end.x)
			xa = maxf(xa, r.position.x)
			if xf > xa:
				draw_rect(Rect2(xa, maxf(y_b, r.position.y), xf - xa, hb), cor_bri)
			y_b += V.Q * 2.0
			passo_b += 1
	# clarão ao disparar: miolo claro em 3 degraus e moldura de pixel que se abre
	var fl: float = float(b["flash"])
	if fl > 0.0:
		draw_rect(r, Color(1, 1, 1, 0.25 * ceilf(fl * 3.0)))
		var mf: Rect2 = _rect_grade(r.grow(V.sn((1.0 - fl) * 22.0)))
		if fl > 0.15:
			_moldura_px(mf.grow(V.Q), V.CONT)
		_moldura_px(mf, V.tom(cor, 1.3))

## Seta de primeira vez, só no primeiro poder pronto de cada luta.
func _seta_primeira_vez(i: int) -> void:
	var r: Rect2 = poder_btns[i]["rect"]
	var cor: Color = poder_btns[i]["cor"]
	var q: float = V.Q
	var bob: float = V.sn(absf(sin(rel * 4.0)) * 7.0)
	var tip: Vector2 = Vector2(V.sn(r.get_center().x), V.sn(r.position.y - 8.0) - bob)
	# seta para baixo em degraus: 5 faixas que afinam até 1 quadradinho, com contorno escuro
	for k in 5:
		var hw: float = (4 - k) * q
		draw_rect(Rect2(tip.x - hw - q, tip.y - (5 - k) * q, hw * 2.0 + q * 3.0, q), V.CONT)
	draw_rect(Rect2(tip.x, tip.y, q, q), V.CONT)
	draw_rect(Rect2(tip.x - q * 5.0, tip.y - q * 6.0, q * 11.0, q), V.CONT)
	for k in 5:
		var hw2: float = (4 - k) * q
		draw_rect(Rect2(tip.x - hw2, tip.y - (5 - k) * q, hw2 * 2.0 + q, q), Desenho.DOURADO if k > 0 else V.tom(Desenho.DOURADO, 1.4))
	var txt: String = Idioma.t("Clique ou aperte %d") % int(poder_btns[i]["tecla"])
	var tw: float = V.sn(UIComum.FONTE.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(15)).x + 18.0)
	var pl: Rect2 = Rect2(V.sn(tip.x - tw * 0.5), tip.y - q * 15.0, tw, q * 8.0)
	draw_rect(pl.grow(q), V.CONT)
	draw_rect(pl, Color(0.08, 0.05, 0.1))
	draw_rect(Rect2(pl.position, Vector2(pl.size.x, q)), cor)
	Desenho.texto(self, txt, Vector2(pl.position.x, pl.position.y + 18.0), 15, Color(1, 0.97, 0.85), pl.size.x)

## Dica ao passar o mouse: nome e texto do poder.
func _dica_poder(i: int) -> void:
	var b: Dictionary = poder_btns[i]
	var cor: Color = b["cor"]
	var r: Rect2 = b["rect"]
	var nome: String = Idioma.t(str(b["nome"]))
	var d: String = Idioma.t(str(b["dica"]))
	d = d.substr(0, 1).to_upper() + d.substr(1)
	var fonte: Font = UIComum.FONTE
	var larg: float = maxf(fonte.get_string_size(nome, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(17)).x, fonte.get_string_size(d, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(14)).x) + 22.0
	var pl: Rect2 = Rect2(clampf(r.get_center().x - larg * 0.5, 8.0, 1272.0 - larg), r.position.y - 62.0, larg, 52.0)
	draw_rect(pl.grow(2.0), Color(0, 0, 0, 0.4))
	draw_rect(pl, Color(0.07, 0.04, 0.09, 0.94))
	draw_rect(Rect2(pl.position, Vector2(pl.size.x, 3.0)), cor)
	draw_rect(pl, Color(cor.r, cor.g, cor.b, 0.6), false, 1.0)
	Desenho.texto(self, nome, Vector2(pl.position.x + 11.0, pl.position.y + 24.0), 17, cor, -1.0, 3)
	Desenho.texto(self, d, Vector2(pl.position.x + 11.0, pl.position.y + 43.0), 14, Color(1, 0.96, 0.88), -1.0, 3)

func _hud() -> void:
	var nome_fase: String = Idioma.t(Fases.nome_do_lugar(estado.lugar()))
	if estado.invasao:
		Desenho.texto(self, Idioma.t("Invasão · %s · Onda %d") % [Idioma.t("as ruas") if estado.invasao_ruas() else nome_fase, estado.onda_invasao], Vector2(20, 40), 30, Color(1, 1, 1), -1.0, 4)
		var rec_h: int = estado.recordes[estado.indice_recorde()]
		Desenho.texto(self, (Idioma.t("Recorde: onda %d") % rec_h) if rec_h > 0 else Idioma.t("Sem recorde ainda"), Vector2(22, 62), 16, Desenho.DOURADO, -1.0, 3)
		if estado.onda == Balanco.ONDAS_TOTAIS:
			Desenho.texto(self, Idioma.t("Onda de chefe"), Vector2(190, 62), 16, Color(1.0, 0.45, 0.4), -1.0, 3)
	else:
		Desenho.texto(self, Idioma.t("%s · Onda %d/%d") % [nome_fase, estado.onda, Balanco.ONDAS_TOTAIS], Vector2(20, 40), 30, Color(1, 1, 1), -1.0, 4)
		if estado.ato > 1:
			Desenho.texto(self, Idioma.t(Balanco.ATO_NOME[estado.ato - 1]), Vector2(22, 62), 16, Desenho.DOURADO, -1.0, 3)
	# contador de inimigos restantes
	var restam: int = sim.inimigos.size() + sim.fila.size()
	UIComum.emblema(self, "inimigo", Vector2(546, 16), 2.0, Desenho.COR_INIMIGO)   # cabecinha de rato em pixel art, não uma bola
	Desenho.texto(self, str(restam), Vector2(580, 40), 28, Color(1, 1, 1), -1.0, 4)
	# barra grande do chefe com nome, no topo
	for u in sim.inimigos:
		var ub: Unidade = u
		if ub.chefe and ub.vida_max > 0.0 and not ub.ilusao:
			var fr_b: float = clampf(ub.vida / ub.vida_max, 0.0, 1.0)
			var nome_b: String = Idioma.t(Fases.nome_do_chefe(estado.lugar_chefe()))
			Desenho.texto(self, nome_b, Vector2(632, 42), 22, Color(1.0, 0.85, 0.8), 424.0, 4)
			# barra de pixel: 420 px em quadradinhos de V.Q, 3 de altura, contorno escuro, brilho em cima e sombra embaixo
			var q: float = V.Q
			var x0: float = 632.0
			var y0: float = 52.0
			var nq: int = int(420.0 / q)
			var cheio: int = clampi(ceili(fr_b * nq - 0.01), 1 if fr_b > 0.0 else 0, nq)
			var ver := Color(0.92, 0.25, 0.22)
			draw_rect(Rect2(x0 - q, y0 - q, (nq + 2) * q, q * 5.0), V.CONT)
			draw_rect(Rect2(x0 + cheio * q, y0, (nq - cheio) * q, q * 3.0), Color(0.25, 0.08, 0.08))
			if cheio > 0:
				draw_rect(Rect2(x0, y0, cheio * q, q * 3.0), ver)
				draw_rect(Rect2(x0, y0, cheio * q, q), V.tom(ver, 1.4))
				draw_rect(Rect2(x0, y0 + q * 2.0, cheio * q, q), V.tom(ver, 0.72))
			for k in range(1, 4):
				draw_rect(Rect2(x0 + nq * q * k * 0.25, y0, q, q * 3.0), V.CONT)   # marcas de quarto de vida
			break
	# contador de troféus (perto do contador de blocos): o total já desconta os que ainda estão em voo
	var mostrados: int = estado.trofeus
	for ft in tfx:
		if ft["k"] == "trofeu":
			mostrados -= int(ft["n"])
	var pc_t: Vector2 = TROFEU_CONTADOR + Vector2(9, 8)
	TorrePx.desenhar_trofeu(self, pc_t, 2.0 + 0.8 * trofeu_pulso)
	Desenho.texto(self, str(maxi(mostrados, 0)), Vector2(TROFEU_CONTADOR.x + 26.0, TROFEU_CONTADOR.y + 18.0), 20, Desenho.b(Desenho.DOURADO, trofeu_pulso * 0.6), -1.0, 3)
	if sim.terminada and sim.vitoria and mensagem_t > 0.1:
		var tm: float = mensagem_t - 0.1
		var em: float = 1.0 + 0.7 * exp(-tm * 7.0) * cos(tm * 16.0)   # entra com sobressalto
		draw_set_transform(Vector2(640, 300), 0.0, Vector2(em, em))
		Desenho.texto(self, Idioma.t("Onda vencida!"), Vector2(-300, 0), 54, Desenho.DOURADO, 600.0, 7)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---------------------------------------------------------------- preparação da onda e leitura da luta
## A entrada do campo vale com a luta visível, sem menu aberto nem cortina.
func _entrada_ok() -> bool:
	if sim == null or not is_visible_in_tree() or finalizado or not can_process():
		return false
	var m: Menus = _menus()
	return m == null or not (m.ativo() or m.em_transicao())

## Põe os gatos nos postos e monta a prévia da onda (um bicho por tipo, com a quantidade).
func _montar_preparacao() -> void:
	# a opção "Preparação da onda" pode pular esta etapa; até a aula da preparação ser vista, ela sempre aparece
	prep = preparacao and (Menus.preparacao_onda or not Menus.dicas_vistas.get("tut_a_prep", false))
	prep_sel = null
	prep_arr = null
	prep_previa.clear()
	prep_anim.clear()
	prep_press = ""
	foco_u = null
	if not prep:
		return
	for u in sim.aliados:
		var a: Unidade = u
		a.x = a.casa_x
		a.y = a.casa_y
	var por_prio: Dictionary = {}
	for it in sim.fila:
		var item: Dictionary = it
		var chefe: bool = item.has("chefe")
		var elite: bool = item.get("elite", false)
		var pr: int = Simulacao.prio_de(int(item["tipo"]), elite, chefe)
		if por_prio.has(pr):
			por_prio[pr]["n"] = int(por_prio[pr]["n"]) + 1
			continue
		var b := Unidade.new()
		b.equipe = 1
		b.tipo = int(item["tipo"])
		b.pecas = item["pecas"]
		b.chefe = chefe
		b.elite = elite
		b.familia = clampi(int(item.get("fam", estado.fase - 1)), 0, Fases.TOTAL - 1)
		b.rival = item.get("rival", false)
		b.gangue = int(item.get("gangue", -1)) if b.rival else -1
		b.chefe_tipo = Fases.chefe_base(estado.lugar_chefe()) if chefe else -1
		var nome: String = Idioma.t(Balanco.TIPO_NOMES[clampi(b.tipo, 0, Balanco.TIPO_NOMES.size() - 1)])
		var dica: String = Idioma.t(TIPO_DICA[clampi(b.tipo, 0, TIPO_DICA.size() - 1)])
		if b.rival:
			nome = Idioma.t(Balanco.nome_rival(b.gangue, b.tipo))
			var dica_g: String = Balanco.dica_rival(b.gangue, b.tipo)
			if dica_g != "":
				dica = Idioma.t(dica_g)
		if chefe:
			nome = Idioma.t(Fases.nome_do_chefe(estado.lugar_chefe()))
			dica = Idioma.t("O chefe do cômodo. Chega por último.")
		elif elite:
			nome = Idioma.t("Fantasiado")
			dica = Idioma.t("Mais forte: veste uma fantasia e larga uma peça dela ao cair.")
		por_prio[pr] = {"u": b, "n": 1, "prio": pr, "nome": nome, "dica": dica, "pos": Vector2.ZERO}
	var chaves: Array = por_prio.keys()
	chaves.sort()
	var k: int = 0
	for pr in chaves:
		var g: Dictionary = por_prio[pr]
		if int(pr) == Simulacao.PRIO_CHEFE:
			g["pos"] = Vector2(1195.0, 610.0)
		else:
			g["pos"] = Vector2(900.0 + (k % 2) * 150.0, 520.0 + (k / 2) * 40.0 + (k % 2) * 20.0)
			k += 1
		prep_previa.append(g)
	prep_previa.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["pos"] as Vector2).y < (b["pos"] as Vector2).y)
	_aquecer_poses()
	# (a explicação da preparação e dos bichos novos vem das aulas de tutorial.gd)

## Monta, fora da vista e aos poucos, as poses dos bichos desta onda: o primeiro quadro de cada pose custa vários
## milissegundos e travava a luta quando o bicho aparecia.
func _aquecer_poses() -> void:
	if aquecedor == null:
		aquecedor = AQUECEDOR.new()
		add_child(aquecedor)
	aquecedor.limpar()
	for g in prep_previa:
		var u: Unidade = g["u"]
		aquecedor.adicionar_bicho(u.pecas, u.tipo, u.familia, u.chefe, u.elite, u.chefe_tipo)

func _prep_rect(i: int) -> Rect2:
	return Rect2(PREP_BT_X[i], PREP_BT_Y, PREP_BT_W, PREP_BT_H)

## Botão da preparação sob o ponto: "o0".."o2" (ordens), "ir" (começar) ou "".
func _prep_bt_em(p: Vector2) -> String:
	for i in 3:
		if _prep_rect(i).has_point(p):
			return "o%d" % i
	if PREP_COMECAR.has_point(p):
		return "ir"
	return ""

func _caixa_unidade(u: Unidade) -> Rect2:
	var e: float = esc_tela(u)
	return Rect2(u.vx - (CORPO_LARG + 4.0) * e, u.vy - (CORPO_ALT + 4.0) * e, (CORPO_LARG + 4.0) * 2.0 * e, (CORPO_ALT + 12.0) * e)

## Unidade viva sob o ponto (a mais à frente, isto é, a de maior y).
func _unidade_em(p: Vector2, so_aliados: bool = false) -> Unidade:
	var melhor: Unidade = null
	var listas: Array = [sim.aliados] if so_aliados else [sim.aliados, sim.inimigos]
	for lista in listas:
		for u in lista:
			var uu: Unidade = u
			if uu.vivo and _caixa_unidade(uu).has_point(p) and (melhor == null or uu.vy > melhor.vy):
				melhor = uu
	return melhor

func _previa_em(p: Vector2) -> int:
	var achou: int = -1
	for i in prep_previa.size():
		var g: Dictionary = prep_previa[i]
		var pos: Vector2 = g["pos"]
		var e: float = esc_tela(g["u"] as Unidade)
		if Rect2(pos.x - (CORPO_LARG + 4.0) * e, pos.y - (CORPO_ALT + 4.0) * e, (CORPO_LARG + 4.0) * 2.0 * e, (CORPO_ALT + 12.0) * e).has_point(p):
			achou = i
	return achou

## Ordem de postura: para o gato selecionado ou, sem seleção, para o time todo.
func _prep_ordem(p: int) -> void:
	var alvos: Array = [prep_sel] if prep_sel != null else sim.aliados.duplicate()
	for u in alvos:
		var a: Unidade = u
		sim.definir_postura(a, p)
		a.x = a.casa_x
		a.y = a.casa_y
	Som.tocar("clique", 1.0 + 0.08 * (1 - p))

## Postura comum aos gatos que receberiam a ordem agora (-1 se cada um tem a sua).
func _prep_postura_atual() -> int:
	if prep_sel != null:
		return prep_sel.postura
	var p: int = -1
	for u in sim.aliados:
		var a: Unidade = u
		if p >= 0 and a.postura != p:
			return -1
		p = a.postura
	return p

func _prep_comecar() -> void:
	if not prep:
		return
	if prep_arr != null:
		_prep_largar()
	prep = false
	prep_sel = null
	rel = 0.0
	Som.tocar("onda", 1.1, 0.0, -2.0)
	estado.salvar()   # postos e posturas ficam para as próximas ondas

func _prep_largar() -> void:
	var u: Unidade = prep_arr
	prep_arr = null
	if u == null or not prep_arr_moveu:
		return
	sim.definir_posto(u, u.x, u.y)
	u.x = u.casa_x
	u.y = u.casa_y
	Som.tocar("vestir", 1.15, 0.04, -4.0)

func _entrada_prep(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		if prep_arr != null:
			var p: Vector2 = mouse_c + prep_arr_d
			if not prep_arr_moveu and mouse_c.distance_to(prep_arr_p0) > 6.0:
				prep_arr_moveu = true
			if prep_arr_moveu:
				prep_arr.x = clampf(p.x, Balanco.POSTO_X0, Balanco.POSTO_X1)
				prep_arr.y = clampf(p.y, Balanco.POSTO_Y0, Balanco.POSTO_Y1)
				prep_arr.vx = prep_arr.x
				prep_arr.vy = prep_arr.y
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if not mb.pressed:
			var solto: String = _prep_bt_em(mouse_c)
			if prep_press != "" and solto == prep_press:
				get_viewport().set_input_as_handled()
				if solto == "ir":
					_prep_comecar()
				else:
					_prep_ordem(int(solto.substr(1)))
			prep_press = ""
			if prep_arr != null:
				get_viewport().set_input_as_handled()
				_prep_largar()
			return
		var bt: String = _prep_bt_em(mouse_c)
		if bt != "":
			prep_press = bt
			get_viewport().set_input_as_handled()
			return
		var gato: Unidade = _unidade_em(mouse_c, true)
		if gato != null:
			get_viewport().set_input_as_handled()
			if prep_sel != gato:
				Som.tocar("pegar", 1.0, 0.04, -3.0)
			prep_sel = gato
			prep_arr = gato
			prep_arr_d = Vector2(gato.x, gato.y) - mouse_c
			prep_arr_p0 = mouse_c
			prep_arr_moveu = false
			return
		var gi: int = _previa_em(mouse_c)
		if gi >= 0:
			get_viewport().set_input_as_handled()
			var pr: int = int(prep_previa[gi]["prio"])
			sim.prioridade = -1 if sim.prioridade == pr else pr
			Som.tocar("clique", 0.85 if sim.prioridade < 0 else 1.2)
			return
		if mouse_c.y > Balanco.CHAO_Y0 - 60.0 and mouse_c.y < PREP_BT_Y - 6.0 and mouse_c.x > 200.0:
			prep_sel = null   # clique no chão vazio: as ordens voltam a valer para o time todo
	elif ev is InputEventKey:
		var k: InputEventKey = ev as InputEventKey
		if not k.pressed or k.echo or k.ctrl_pressed or k.alt_pressed or k.meta_pressed:
			return
		var code: Key = k.keycode if k.keycode != KEY_NONE else k.physical_keycode
		var feito: bool = true
		match code:
			KEY_Q: _prep_ordem(Boneco.Postura.AVANCAR)
			KEY_W: _prep_ordem(Boneco.Postura.SEGURAR)
			KEY_E: _prep_ordem(Boneco.Postura.RECUAR)
			KEY_SPACE, KEY_ENTER, KEY_KP_ENTER: _prep_comecar()
			KEY_1, KEY_KP_1: _prep_selecionar(0)
			KEY_2, KEY_KP_2: _prep_selecionar(1)
			KEY_3, KEY_KP_3: _prep_selecionar(2)
			KEY_4, KEY_KP_4: _prep_selecionar(3)
			KEY_5, KEY_KP_5: _prep_selecionar(4)
			KEY_0, KEY_KP_0: prep_sel = null
			_: feito = false
		if feito:
			get_viewport().set_input_as_handled()

func _prep_selecionar(i: int) -> void:
	if i < sim.aliados.size():
		prep_sel = null if prep_sel == sim.aliados[i] else sim.aliados[i]
		Som.tocar("pegar", 1.0, 0.04, -3.0)

## Unidade sob o mouse (para a ficha) e animação dos botões da preparação.
func _atualizar_foco(delta: float) -> void:
	foco_u = null
	if mouse_c.x < 0.0 or sim == null or sim.terminada or not _entrada_ok():
		return
	if prep:
		var sob: String = _prep_bt_em(mouse_c)
		for id in ["o0", "o1", "o2", "ir"]:
			UIComum.anim_passo(prep_anim, id, sob == id, prep_press == id and sob == id, delta)
		if prep_arr != null and prep_arr_moveu:
			return
	if _btn_em(mouse_c) >= 0 and not prep:
		return
	foco_u = _unidade_em(mouse_c)

## Mira vermelha do alvo prioritário.
## Em pixel: aro de quadradinhos com contorno, quatro marcas que pulsam um quadradinho e o ponto no meio.
func _mira(c: Vector2, r: float, alfa: float) -> void:
	if alfa <= 0.05:
		return
	var q: float = V.Q
	var cor := Color(1.0, 0.3, 0.25)
	var x: float = V.sn(c.x)
	var y: float = V.sn(c.y)
	var rr: float = maxf(q * 4.0, V.sn(r + 5.0))
	var pu: float = q if sin(rel * 6.0) > 0.0 else 0.0
	_anel_px(Vector2(x, y), rr + q, rr + q, V.CONT, 3)
	_anel_px(Vector2(x, y), rr, rr, cor, 1)
	var perto: float = rr - q + pu         # marca: 3 quadradinhos cruzando o aro, empurrados pelo pulso
	var longe: float = rr + q * 2.0 + pu
	for k in 4:
		var mx: float = x
		var my: float = y
		var mw: float = q
		var mh: float = q
		if k == 0:
			mx = x + perto
			mw = q * 3.0
		elif k == 1:
			mx = x + q - longe
			mw = q * 3.0
		elif k == 2:
			my = y + perto
			mh = q * 3.0
		else:
			my = y + q - longe
			mh = q * 3.0
		draw_rect(Rect2(mx - q, my - q, mw + q * 2.0, mh + q * 2.0), V.CONT)
		draw_rect(Rect2(mx, my, mw, mh), cor)
	draw_rect(Rect2(x - q, y - q, q * 3.0, q * 3.0), V.CONT)
	draw_rect(Rect2(x, y, q, q), V.tom(cor, 1.5))

## Aro (elipse ou círculo) cheio de quadradinhos alinhados à grade, sem falhas: por faixa, a diferença entre a
## elipse de fora e a de dentro (`esp` quadradinhos de espessura). `ce` é o centro; 2 retângulos por faixa.
func _anel_px(ce: Vector2, rx: float, ry: float, cor: Color, esp: int = 1) -> void:
	var q: float = V.Q
	var ny: int = int(ry / q + 0.5)
	var nx: float = rx / q
	var cx: float = floorf(ce.x / q)
	var cy: float = floorf(ce.y / q)
	var nyi: int = ny - esp
	var nxi: float = nx - esp
	var dn: float = ny * ny + ny * 0.8
	var dni: float = nyi * nyi + nyi * 0.8
	for j in range(-ny, ny + 1):
		var wo: int = int(nx * sqrt(maxf(0.0, 1.0 - float(j * j) / maxf(dn, 0.5))))
		var wi: int = -1
		if nyi >= 0 and absi(j) <= nyi and nxi >= 0.0:
			wi = int(nxi * sqrt(maxf(0.0, 1.0 - float(j * j) / maxf(dni, 0.5))))
			if nyi == 0:
				wi = int(nxi)
		if wi < 0:
			draw_rect(Rect2((cx - wo) * q, (cy + j) * q, (2 * wo + 1) * q, q), cor)
		elif wo > wi:
			draw_rect(Rect2((cx - wo) * q, (cy + j) * q, (wo - wi) * q, q), cor)
			draw_rect(Rect2((cx + wi + 1) * q, (cy + j) * q, (wo - wi) * q, q), cor)

## "!" de pixel (2 quadradinhos de largura) centrado em `ce`. `abre` > 0 parte o sinal: a haste sobe para a
## esquerda e o pé desce para a direita, `abre` quadradinhos cada (aviso cortado). `cont` desenha a borda escura.
func _exclamacao(ce: Vector2, cor: Color, abre: int = 0, cont: bool = false) -> void:
	var q: float = V.Q
	var x: float = V.sn(ce.x) - q
	var y: float = V.sn(ce.y) - q * 4.0
	var dx: float = abre * q
	if cont:
		draw_rect(Rect2(x - dx - q, y - dx - q, q * 4.0, q * 5.0), V.CONT)
		draw_rect(Rect2(x + dx - q, y + dx + q * 2.0, q * 4.0, q * 4.0), V.CONT)
		draw_rect(Rect2(x + dx - q, y + dx + q * 5.0, q * 4.0, q * 4.0), V.CONT)
	draw_rect(Rect2(x - dx, y - dx, q * 2.0, q * 3.0), cor)          # haste de cima
	draw_rect(Rect2(x + dx, y + dx + q * 3.0, q * 2.0, q * 2.0), cor)  # haste de baixo
	draw_rect(Rect2(x + dx, y + dx + q * 6.0, q * 2.0, q * 2.0), cor)  # ponto

## Retângulo encostado na grade (cantos arredondados para o quadradinho mais próximo).
func _rect_grade(r: Rect2) -> Rect2:
	var x0: float = roundf(r.position.x / V.Q) * V.Q
	var y0: float = roundf(r.position.y / V.Q) * V.Q
	return Rect2(x0, y0, roundf(r.end.x / V.Q) * V.Q - x0, roundf(r.end.y / V.Q) * V.Q - y0)

## Moldura de 1 quadradinho por dentro de `r` (4 retângulos), com os cantos cortados (canto de pixel).
func _moldura_px(r: Rect2, cor: Color) -> void:
	var q: float = V.Q
	draw_rect(Rect2(r.position.x + q, r.position.y, r.size.x - q * 2.0, q), cor)
	draw_rect(Rect2(r.position.x + q, r.end.y - q, r.size.x - q * 2.0, q), cor)
	draw_rect(Rect2(r.position.x, r.position.y + q, q, r.size.y - q * 2.0), cor)
	draw_rect(Rect2(r.end.x - q, r.position.y + q, q, r.size.y - q * 2.0), cor)

## Caixa escura com linhas de texto: [texto, tamanho, cor] ou [nome, valor, tamanho, cor] (duas colunas).
func _caixa_info(linhas: Array, ancora: Vector2, larg: float, borda: Color) -> void:
	var alt: float = 20.0
	for l in linhas:
		alt += float(l[l.size() - 2]) + 5.0
	var r := Rect2(ancora + Vector2(22.0, -alt * 0.5), Vector2(larg, alt))
	if r.end.x > 1272.0:
		r.position.x = ancora.x - 22.0 - larg
	r.position.x = maxf(6.0, r.position.x)
	r.position.y = clampf(r.position.y, 76.0, 640.0 - alt)
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, Color(0.07, 0.05, 0.1, 0.93))
	draw_rect(r, Color(borda.r, borda.g, borda.b, 0.9), false, 2.0)
	var y: float = r.position.y + 10.0
	for l in linhas:
		var tam: int = int(l[l.size() - 2])
		var cor: Color = l[l.size() - 1]
		y += tam
		if l.size() == 5:
			# estado: ícone, nome e tempo restante à direita
			IconesEstado.desenhar(self, int(l[0]), Vector2(r.position.x + 18.0, y - tam * 0.35))
			Desenho.texto(self, str(l[1]), Vector2(r.position.x + 30.0, y), tam, cor)
			var tw5: float = UIComum.FONTE.get_string_size(str(l[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam)).x
			Desenho.texto(self, str(l[2]), Vector2(r.end.x - 12.0 - tw5, y), tam, Color(1.0, 0.95, 0.6))
		elif l.size() == 4:
			Desenho.texto(self, str(l[0]), Vector2(r.position.x + 12.0, y), tam, Color(1, 1, 1, 0.7))
			var tw: float = UIComum.FONTE.get_string_size(str(l[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(tam)).x
			Desenho.texto(self, str(l[1]), Vector2(r.end.x - 12.0 - tw, y), tam, cor)
		else:
			Desenho.texto(self, str(l[0]), Vector2(r.position.x + 12.0, y), tam, cor)
		y += 5.0

func _nome_unidade(u: Unidade) -> String:
	if u.equipe == 0:
		return u.boneco.nome if u.boneco != null else Idioma.t("Gato")
	if u.chefe:
		return Idioma.t(Fases.nome_do_chefe(estado.lugar_chefe()))
	if u.parte:
		return Idioma.t("Sapinho")
	if u.pequeno:
		return Idioma.t("Filhote")
	var n: String = Idioma.t(Balanco.nome_rival(u.gangue, u.tipo) if u.rival else Balanco.TIPO_NOMES[clampi(u.tipo, 0, Balanco.TIPO_NOMES.size() - 1)])
	if not u.elite:
		return n
	return (Idioma.t("%s fantasiada") if u.tipo == Unidade.Tipo.GEMEO else Idioma.t("%s fantasiado")) % n

## Linhas da ficha com os estados em vigor: [ícone, nome, tempo, tamanho, cor]; no fim, bônus sem ícone.
func _estados_linhas(u: Unidade) -> Array:
	var saida: Array = []
	var n: int = IconesEstado.ativos(u, sim.zonas, _ico_ids, _ico_t)
	for i in n:
		var id: int = _ico_ids[i]
		var tp: float = _ico_t[i]
		var nome: String = Idioma.t(IconesEstado.NOME[id])
		match id:
			IconesEstado.E.LENTO:
				nome = Idioma.t("Molhado, lento") if u.frio_t > 0.0 else Idioma.t("Lento a %s") % Simulacao.pct(u.lento)
			IconesEstado.E.MARCADO:
				nome = Idioma.t("Marcado: +%s de dano") % Simulacao.pct(u.marcado_bonus)
			IconesEstado.E.OCULTO:
				nome = Idioma.t("Oculto na fumaça")
			IconesEstado.E.DISFARCADO:
				nome = Idioma.t("Disfarçado: anula o próximo golpe")
			IconesEstado.E.FURIA:
				nome = Idioma.t("Em fúria")
			IconesEstado.E.CURA:
				nome = Idioma.t("Curando no canteiro")
			IconesEstado.E.ABALADO:
				nome = Idioma.t("Abalado: -%s de dano e de velocidade") % Simulacao.pct(Balanco.MORAL_DANO)
			IconesEstado.E.FUGINDO:
				nome = ((Idioma.t("Fugindo com %d bloco") if u.carga == 1 else Idioma.t("Fugindo com %d blocos")) % u.carga) if u.carga > 0 else Idioma.t("Fugindo")
			IconesEstado.E.DORMINDO:
				nome = Idioma.t("Dormindo com os peixes: fora da luta")
			IconesEstado.E.MUTANTE:
				nome = Idioma.t("Mutante: +%s de dano e de velocidade") % Simulacao.pct(Balanco.MUTACAO_DANO)
			IconesEstado.E.CONFUSO:
				nome = Idioma.t("Confuso: ataca o aliado mais perto")
		saida.append([id, nome, (Idioma.t("%s s") % Simulacao.num(tp)) if tp < IconesEstado.SEM_TEMPO else "", 13, Color(0.85, 1.0, 0.85)])
	var extra: Array[String] = []
	if u.bonus_dano > 1.01:
		extra.append(Idioma.t("dano +%s") % Simulacao.pct(u.bonus_dano - 1.0))
	if u.embalo > 0.0:
		extra.append(Idioma.t("embalo +%s") % Simulacao.pct(u.embalo))
	if not extra.is_empty():
		saida.append([", ".join(extra), 13, Color(0.8, 1.0, 0.8)])
	return saida

## Ficha em números da unidade sob o mouse e a linha até quem ela está atacando.
func _desenhar_foco() -> void:
	var u: Unidade = foco_u
	if u == null or not u.vivo:
		if prep:
			_desenhar_foco_previa()
		return
	var aliado: bool = u.equipe == 0
	var cor: Color = Color(0.55, 0.85, 1.0) if aliado else Color(1.0, 0.5, 0.42)
	var esc_u: float = esc_tela(u)
	# elipse no chão em quadradinhos: contorno escuro de 3 e a cor no meio
	var pe_f: Vector2 = Vector2(u.vx, u.vy)
	var rx_f: float = 46.0 * esc_u
	_anel_px(pe_f, rx_f + V.Q, rx_f * 0.3 + V.Q, V.CONT, 3)
	_anel_px(pe_f, rx_f, rx_f * 0.3, cor, 1)
	var alvo: Unidade = u.alvo
	if not prep and alvo != null and alvo.vivo:
		var pa: Vector2 = Vector2(u.vx, u.vy - CORPO_MEIO * esc_u)
		var pb: Vector2 = Vector2(alvo.vx, alvo.vy - CORPO_MEIO * esc_tela(alvo))
		var n: int = maxi(2, int(pa.distance_to(pb) / 15.0))
		for i in n:
			# trilha de quadradinhos que crescem (1 -> 2) e clareiam a caminho do alvo
			var w: float = fposmod((i + rel * 3.0) / n, 1.0)
			var pt: Vector2 = pa.lerp(pb, w)
			var s_t: float = V.Q * (2.0 if w > 0.55 else 1.0)
			V.quadro(self, pt.x - V.Q, pt.y - V.Q, s_t + V.Q * 2.0, s_t + V.Q * 2.0, V.CONT)
			V.quadro(self, pt.x, pt.y, s_t, s_t, V.tom(cor, 0.75 + 0.6 * w))
		_anel_px(pb, 18.0, 18.0, V.CONT, 3)
		_anel_px(pb, 15.0, 15.0, cor, 1)
	var linhas: Array = [[_nome_unidade(u), 20, cor.lightened(0.3)]]
	if aliado:
		var sub: String = Idioma.t("%s · %s") % [Idioma.t(Boneco.LINHA_NOMES[u.linha]), Idioma.t(Boneco.POSTURA_NOMES[u.postura])]
		if u.boneco != null:
			sub = Idioma.t("Nível %d · %s") % [u.boneco.nivel, sub]
		linhas.append([sub, 13, Color(1, 1, 1, 0.75)])
	elif sim.prioritario(u):
		linhas.append([Idioma.t("Alvo prioritário do time"), 13, Color(1.0, 0.55, 0.45)])
	for par in Simulacao.ficha_linhas(u):
		linhas.append([par[0], par[1], 14, Color(1, 1, 1)])
	if aliado and not u.herancas.is_empty():
		var nomes: Array[String] = []
		for hi in u.herancas.size():
			nomes.append(Idioma.t(Simulacao.heranca_nome_curto(u.herancas[hi], u.heranca_graus[hi] if hi < u.heranca_graus.size() else 1)))
		linhas.append([Idioma.t("Herança: %s") % ", ".join(nomes), 13, Color(0.85, 0.78, 1.0)])
	if u.poder >= 0 and aliado:
		var cj: int = clampi(u.poder_conj, 0, Pecas.PODER_NOME.size() - 1)
		linhas.append([Idioma.t("Poder: %s") % Idioma.t(Pecas.PODER_NOME[cj]), Idioma.t("pronto") if u.poder_cd <= 0.0 else Idioma.t("em %s s") % Simulacao.num(u.poder_cd), 14, Color(1.0, 0.9, 0.5)])
	if not prep:
		if alvo != null and alvo.vivo:
			linhas.append([Idioma.t("Atacando"), _nome_unidade(alvo), 14, cor.lightened(0.3)])
		elif not aliado:
			linhas.append([Idioma.t("Indo para"), Idioma.t("a torre"), 14, Color(1.0, 0.8, 0.5)])
		linhas.append_array(_estados_linhas(u))
	_caixa_info(linhas, Vector2(u.vx + 30.0, u.vy - CORPO_MEIO * esc_u), 262.0, cor)

## "Avançar: vai atrás..." -> só a explicação (o nome da ordem já vai no título); sem ": " devolve tudo.
func _dica_sem_titulo(t: String) -> String:
	return t.get_slice(": ", 1) if ": " in t else t

## Quebra o texto em linhas de até `n` letras, sem partir palavra.
func _quebra(txt: String, n: int) -> Array[String]:
	var saida: Array[String] = []
	var resto: String = txt.strip_edges()
	while resto.length() > 0:
		var corte: int = resto.length() if resto.length() <= n else resto.rfind(" ", n)
		if corte <= 0:
			corte = resto.length()
		saida.append(resto.substr(0, corte))
		resto = resto.substr(corte).strip_edges()
	return saida

func _desenhar_foco_previa() -> void:
	if mouse_c.x < 0.0:
		return
	var bt: String = _prep_bt_em(mouse_c)
	if bt.begins_with("o"):
		var i: int = int(bt.substr(1))
		var lo: Array = [[Idioma.t(Boneco.POSTURA_NOMES[i]), 18, PREP_COR[i]]]
		for t in _quebra(_dica_sem_titulo(Idioma.t(PREP_DICA[i])), 44):
			lo.append([t, 13, Color(1, 1, 1)])
		lo.append([Idioma.t("Vale para %s.") % (Idioma.t("o time todo") if prep_sel == null else _nome_unidade(prep_sel)), 13, Color(1.0, 0.9, 0.5)])
		_caixa_info(lo, Vector2(_prep_rect(i).position.x - 22.0, 590.0), 320.0, PREP_COR[i])
		return
	var gi: int = _previa_em(mouse_c)
	if gi < 0:
		return
	var g: Dictionary = prep_previa[gi]
	var marcado: bool = sim.prioridade == int(g["prio"])
	var linhas: Array = [["%s  ×%d" % [g["nome"], g["n"]], 18, Color(1.0, 0.7, 0.6)]]
	for t in _quebra(str(g["dica"]), 40):
		linhas.append([t, 13, Color(1, 1, 1)])
	linhas.append([Idioma.t("Alvo prioritário: clique para tirar") if marcado else Idioma.t("Clique: o time bate nele primeiro"), 13, Color(1.0, 0.55, 0.45) if marcado else Color(0.7, 1.0, 0.7)])
	_caixa_info(linhas, (g["pos"] as Vector2) + Vector2(-330.0, -40.0), 286.0, Color(1.0, 0.5, 0.42))

## Faixas das linhas no chão e o posto de cada gato (por baixo das unidades).
func _desenhar_prep_chao() -> void:
	var xs: Array[float] = [Balanco.POSTO_X0 - 30.0, (Balanco.LINHA_X[2] + Balanco.LINHA_X[1]) * 0.5, (Balanco.LINHA_X[1] + Balanco.LINHA_X[0]) * 0.5, Balanco.POSTO_X1 + 30.0]
	var y0: float = Balanco.CHAO_Y0 - 6.0
	var y1: float = Balanco.CHAO_Y1 + 4.0
	var arr_linha: int = Boneco.linha_de_x(prep_arr.x) if prep_arr != null and prep_arr_moveu else -1
	var q: float = V.Q
	y0 = V.sn(y0)
	y1 = V.sn(y1)
	for z in 3:
		var li: int = 2 - z   # da torre para fora: fundo, meio, frente
		var cz: Color = PREP_COR[2 - li]
		# faixas na grade, sem se sobrepor (a divisa tracejada fica entre elas)
		var xa: float = V.sn(xs[z]) + q
		var r := Rect2(xa, y0, V.sn(xs[z + 1]) - xa, y1 - y0)
		draw_rect(r, Color(cz.r, cz.g, cz.b, 0.2 if arr_linha == li else 0.08))
	for z in range(0, 4):
		# divisa tracejada: traços de 3 quadradinhos com 2 de folga, numa coluna só da grade
		var xz: float = V.sn(xs[z])
		var yy: float = y0
		while yy < y1:
			draw_rect(Rect2(xz, yy, q, minf(q * 3.0, y1 - yy)), Color(1, 1, 1, 0.32))
			yy += q * 5.0
	# a prévia da onda fica do lado de fora, atrás de uma linha
	draw_rect(Rect2(V.sn(848.0) + q, y0, V.sn(404.0), y1 - y0), Color(0.6, 0.1, 0.1, 0.12))
	var sob_prep: Unidade = null   # gato sob o mouse (pré-destaque), enquanto ninguém é arrastado
	if prep_arr == null and mouse_c.x >= 0.0:
		sob_prep = _unidade_em(mouse_c, true)
	for u in sim.aliados:
		var a: Unidade = u
		var sel: bool = a == prep_sel
		var cp: Color = PREP_COR[a.postura]
		var pe_a: Vector2 = Vector2(a.vx, a.vy)
		var ouro := Color(1.0, 0.92, 0.5)
		if sel:
			# feixe de luz subindo do gato escolhido: degraus de 2 quadradinhos que afinam, em 3 tons de alfa
			# (cada faixa do feixe é desenhada uma vez só: nada de alfa sobre alfa)
			var luz := Color(1.0, 0.93, 0.62)
			var xc: float = V.sn(a.vx)
			var yb: float = V.sn(a.vy) - q * 6.0   # começa acima do halo do chão
			for k in 24:
				var f: float = float(k) / 24.0
				var hw: float = V.sn(lerpf(60.0, 36.0, f))
				var al_l: float = 0.24 if f < 0.34 else (0.15 if f < 0.67 else 0.07)
				draw_rect(Rect2(xc - hw, yb - (k + 1) * q * 2.0, hw * 2.0 + q, q * 2.0), Color(luz, al_l))
			V.elipse(self, pe_a, 54.0, 16.0, Color(ouro, 0.18))
			_anel_px(pe_a, 58.0 + q, 17.4 + q, V.CONT, 4)
			_anel_px(pe_a, 58.0, 17.4, V.tom(ouro, 1.0 if sin(rel * 6.0) > -0.2 else 0.8), 2)
		elif a == sob_prep:
			_anel_px(pe_a, 52.0 + q, 15.6 + q, V.CONT, 3)
			_anel_px(pe_a, 52.0, 15.6, V.tom(ouro, 0.8), 1)
		_anel_px(pe_a, 42.0 + q, 12.6 + q, V.CONT, 3)
		_anel_px(pe_a, 42.0, 12.6, cp, 1)

## Prévia da onda, etiquetas dos gatos, botões de ordem e "Começar" (por cima de tudo).
func _desenhar_prep() -> void:
	for gd in prep_previa:
		var g: Dictionary = gd
		var b: Unidade = g["u"]
		var pos: Vector2 = g["pos"]
		var e: float = esc_tela(b)
		var marcado: bool = sim.prioridade == int(g["prio"])
		V.elipse(self, pos, 32.0 * e, 32.0 * e * 0.3, Color(0, 0, 0, 0.22))
		var resp: float = 1.0 + sin(rel * 2.6 + pos.x) * 0.016
		Desenho.boneco(self, px_grade(pos), e * resp, -1.0 / resp, 1, b.pecas, 0.0, 0.0, false, 0.0, 1.0, false, -1, 0.0, b.tipo, false, b.chefe, b.familia, b.elite, b.chefe_tipo, false, false, 0, false, b.gangue)
		if marcado:
			_mira(pos + Vector2(0, -(CORPO_ALT + 22.0) * e), 10.0, 1.0)
		if not b.chefe:
			IconesPoder.texto(self, "x%d" % int(g["n"]), pos + Vector2(CORPO_LARG * e * 0.55, -12.0), Color(1, 1, 1), 3)
	for i in sim.aliados.size():
		var a: Unidade = sim.aliados[i]
		var ea: float = esc_tela(a)
		var cp: Color = PREP_COR[a.postura]
		var rot: String = Idioma.t(Boneco.POSTURA_NOMES[a.postura])
		var y_rot: float = a.vy - (CORPO_ALT + 12.0) * ea
		if a == prep_sel:
			# plaquinha clara com o nome: é para ele que valem as ordens
			var nm: String = a.boneco.nome if a.boneco != null else Idioma.t("Gato")
			var pl := Rect2(a.vx - 40.0, y_rot - 40.0, 80.0, 20.0)
			draw_rect(pl.grow(2.0), Color(0.25, 0.14, 0.04, 0.9))
			draw_rect(pl, Color(1.0, 0.92, 0.6))
			Desenho.texto(self, nm, Vector2(pl.position.x, pl.end.y - 5.0), 14, Color(0.2, 0.1, 0.03), pl.size.x)
		Desenho.texto(self, rot, Vector2(a.vx - 70.0, y_rot), 14, cp.lightened(0.25), 140.0, 4)
	# nomes das faixas e da prévia, numa régua logo acima do chão (por cima de tudo, para não sumirem atrás dos gatos)
	var xs: Array[float] = [Balanco.POSTO_X0 - 30.0, (Balanco.LINHA_X[2] + Balanco.LINHA_X[1]) * 0.5, (Balanco.LINHA_X[1] + Balanco.LINHA_X[0]) * 0.5, Balanco.POSTO_X1 + 30.0]
	var yr: float = Balanco.CHAO_Y0 - 30.0
	for z in 3:
		var cz: Color = PREP_COR[z]
		var rz := Rect2(xs[z] + 3.0, yr, xs[z + 1] - xs[z] - 6.0, 22.0)
		draw_rect(rz, Color(0.05, 0.03, 0.08, 0.78))
		draw_rect(Rect2(rz.position.x, rz.end.y - 3.0, rz.size.x, 3.0), cz)
		Desenho.texto(self, Idioma.t(Boneco.LINHA_NOMES[2 - z]), Vector2(rz.position.x, yr + 17.0), 15, cz.lightened(0.3), rz.size.x, 3)
	var rv := Rect2(851.0, yr, 398.0, 22.0)
	draw_rect(rv, Color(0.05, 0.03, 0.08, 0.78))
	draw_rect(Rect2(rv.position.x, rv.end.y - 3.0, rv.size.x, 3.0), Color(1.0, 0.45, 0.4))
	Desenho.texto(self, Idioma.t("Onda que vem"), Vector2(rv.position.x, yr + 17.0), 15, Color(1.0, 0.75, 0.65), rv.size.x, 3)
	draw_rect(Rect2(198.0, 646.0, 148.0, 68.0), Color(0.05, 0.03, 0.08, 0.72))
	# faixa de baixo: para quem vale a ordem, os três botões e "Começar"
	var quem: String = Idioma.t("o time todo") if prep_sel == null else (prep_sel.boneco.nome if prep_sel.boneco != null else Idioma.t("o gato"))
	Desenho.texto(self, Idioma.t("Ordem para"), Vector2(206.0, 672.0), 14, Color(1, 1, 1, 0.8), 140.0, 3)
	if prep_sel != null:
		var rq := Rect2(204.0, 678.0, 132.0, 26.0)
		draw_rect(rq, Color(1.0, 0.92, 0.6))
		Desenho.texto(self, quem, Vector2(rq.position.x, rq.end.y - 6.0), 20, Color(0.2, 0.1, 0.03), rq.size.x)
	else:
		Desenho.texto(self, quem, Vector2(206.0, 696.0), 20, Desenho.DOURADO, 140.0, 4)
	var atual: int = _prep_postura_atual()
	for i in 3:
		var id: String = "o%d" % i
		UIComum.botao(self, _prep_rect(i), Idioma.t(Boneco.POSTURA_NOMES[i]), PREP_COR[i], {"h": UIComum.anim_h(prep_anim, id), "p": UIComum.anim_p(prep_anim, id), "marcado": atual == i, "sub": PREP_TECLA[i], "tam": 20}, rel)
	UIComum.botao(self, PREP_COMECAR, Idioma.t("Começar a onda"), UIComum.B_VERDE, {"h": UIComum.anim_h(prep_anim, "ir"), "p": UIComum.anim_p(prep_anim, "ir"), "sub": Idioma.t("Espaço"), "tam": 22, "foco": fposmod(rel, 1.6) < 0.8 and UIComum.anim_h(prep_anim, "ir") < 0.05}, rel)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var alvo_txt: String = ""
	for gd2 in prep_previa:
		if int(gd2["prio"]) == sim.prioridade:
			alvo_txt = Idioma.t("Alvo: %s") % gd2["nome"]
	if alvo_txt != "":
		Desenho.texto(self, alvo_txt, Vector2(851.0, Balanco.CHAO_Y0 - 40.0), 15, Color(1.0, 0.7, 0.6), 398.0, 4)

## Aviso dos poderes de bicho (fantasiado e chefe): enquanto carrega (~1 s) o bicho para, um balão com o nome
## do poder pisca sobre ele e a área ou o alvo aparece marcado no chão. Atordoar o bicho corta o poder.
func _desenhar_avisos() -> void:
	for u in sim.inimigos:
		var uu: Unidade = u
		if uu.vivo and uu.troca_t > 0.0:
			# Gato de Schrödinger prestes a trocar de estado: balão que pisca com o que vem a seguir
			var pk: float = 0.5 + 0.5 * sin(rel * 22.0)
			var esc_s: float = ESC * uu.escala()
			var ps: Vector2 = Vector2(uu.vx, uu.vy - (CORPO_ALT + 40.0) * esc_s)
			var cs: Color = Color(0.75, 0.9, 1.0) if not uu.morto else Color(1.0, 0.85, 0.5)
			Desenho.texto(self, Idioma.t("Vai virar fantasma!") if not uu.morto else Idioma.t("Vai voltar à vida!"), ps + Vector2(-110, -6.0), 22, Color(cs.r, cs.g, cs.b, 0.6 + 0.4 * pk), 220.0, 5)
		if not uu.vivo or uu.aviso_t <= 0.0:
			continue
		var cj: int = clampi(uu.poder_conj, 0, Pecas.PODER_NOME.size() - 1)
		var cor: Color = _cor_legivel(Pecas.CONJUNTO_COR[cj], 0.7)
		var prog: float = clampf(1.0 - uu.aviso_t / maxf(uu.aviso_dur, 0.01), 0.0, 1.0)
		var pisca: float = 0.5 + 0.5 * sin(rel * 22.0)
		var forma: Dictionary = uu.aviso_forma
		var q: float = V.Q
		var cont_a := Color(0.1, 0.03, 0.05)
		var fade_a: float = 0.7 + 0.3 * pisca
		for c in forma.get("circ", []):
			var cc: Vector3 = c
			var centro := Vector2(cc.x, cc.y)
			V.elipse(self, centro, cc.z, cc.z * 0.35, Color(cor.r, cor.g, cor.b, 0.10 + 0.14 * pisca))
			V.elipse(self, centro, cc.z * prog, cc.z * 0.35 * prog, Color(cor.r, cor.g, cor.b, 0.22))
			V.aro(self, centro, cc.z + q, cc.z * 0.35 + q, cont_a, 1.0, 2.0)
			V.aro(self, centro, cc.z, cc.z * 0.35, cor, fade_a, 1.0)
		for r in forma.get("ret", []):
			var rc: Rect2 = r
			var rq: Rect2 = Rect2(V.sn(rc.position.x), V.sn(rc.position.y), V.sn(rc.size.x), V.sn(rc.size.y))
			# miolo na grade, em duas partes que não se sobrepõem: o que já encheu (da direita) e o resto
			var ench: float = V.sn(rq.size.x * prog)
			var al_r: float = 0.12 if pisca < 0.5 else 0.22
			if rq.size.x - ench > 0.0:
				draw_rect(Rect2(rq.position.x, rq.position.y, rq.size.x - ench, rq.size.y), Color(cor.r, cor.g, cor.b, al_r))
			if ench > 0.0:
				draw_rect(Rect2(rq.end.x - ench, rq.position.y, ench, rq.size.y), Color(cor.r, cor.g, cor.b, al_r + 0.14))
			V.quadro(self, rq.position.x - q, rq.position.y - q, rq.size.x + q * 2.0, q, cont_a)
			V.quadro(self, rq.position.x - q, rq.end.y, rq.size.x + q * 2.0, q, cont_a)
			V.quadro(self, rq.position.x - q, rq.position.y, q, rq.size.y, cont_a)
			V.quadro(self, rq.end.x, rq.position.y, q, rq.size.y, cont_a)
			V.quadro(self, rq.position.x, rq.position.y, rq.size.x, q, cor)
			V.quadro(self, rq.position.x, rq.end.y - q, rq.size.x, q, cor)
			V.quadro(self, rq.position.x, rq.position.y, q, rq.size.y, cor)
			V.quadro(self, rq.end.x - q, rq.position.y, q, rq.size.y, cor)
		for l in forma.get("lin", []):
			var a0: Vector2 = l[0] + Vector2(0, -24.0 * ESC)
			var a1: Vector2 = l[1] + Vector2(0, -24.0 * ESC)
			V.linha(self, a0, a1, cont_a, q * 3.0)
			V.linha(self, a0, a1, cor, q * 1.5)
		for al in forma.get("alvos", []):
			var pa: Vector2 = al + Vector2(0, -30.0 * ESC)
			var rr: float = 26.0 + 14.0 * (1.0 - prog)
			V.aro(self, pa, rr + q, rr + q, cont_a, 1.0, 2.0)
			V.aro(self, pa, rr, rr, cor, fade_a, 1.0)
			for k in 4:
				var ang: float = k * TAU / 4.0 + rel * 2.0
				V.quadro(self, pa.x + cos(ang) * (rr + 4.0) - q, pa.y + sin(ang) * (rr + 4.0) - q, q * 2.0, q * 2.0, Color(1, 1, 1))
		# balão sobre o bicho, piscando
		var esc_u: float = esc_tela(uu)
		var pb: Vector2 = Vector2(uu.vx, uu.vy - (CORPO_ALT + 40.0) * esc_u - _topo_extra(uu) + sin(rel * 14.0) * 2.0)
		var raio_b: float = 19.0 + 4.0 * pisca
		V.quadro(self, V.sn(pb.x) - q * 2.0, V.sn(pb.y + raio_b) - q, q * 5.0, q * 3.0, cont_a)
		V.quadro(self, V.sn(pb.x) - q, V.sn(pb.y + raio_b) + q * 2.0, q * 3.0, q * 2.0, cont_a)
		V.disco_c(self, pb, raio_b, cor.lerp(Color(1, 1, 1), 0.35 * pisca), cont_a)
		V.arco(self, pb, raio_b - 5.0, -PI * 0.5, -PI * 0.5 + TAU * prog, cont_a, 1.0, 1.5)   # enche até soltar
		_exclamacao(pb, Color(0.1, 0.04, 0.12))
		Desenho.texto(self, (Idioma.t(uu.aviso_nome) if uu.aviso_nome != "" else Idioma.t("%s!") % Idioma.t(Pecas.PODER_NOME[cj])), pb + Vector2(-100, -raio_b - 8.0), 22, Color(1, 1, 1, 0.6 + 0.4 * pisca), 200.0, 5)
