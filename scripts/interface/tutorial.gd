class_name Tutorial
extends Control
## Tutorial do jogo, em três partes:
##  1. GUIADO: ao começar uma campanha nova, o Quarto vira um passo a passo (holofote no alvo, o gato-guia explica
##     e o passo só avança quando o jogador FAZ a ação, ou clica "Entendi" nos passos de explicação).
##  2. TREINO: o botão "Tutorial" do título roda o mesmo roteiro numa partida descartável (nada vai para o save).
##  3. AULAS: balões curtos, uma vez só, na primeira vez que cada mecânica aparece (substituem as dicas antigas).
## Fica entre o jogo e os menus (filho de `principal.gd`, antes de `Menus`). Só observa o estado do jogo (por consulta
## a cada quadro) e filtra a entrada do jogador durante o guiado; os ganchos nos outros arquivos são mínimos.
## Progresso: `Menus.dicas_vistas` (interface.cfg, seção "dicas"): "tut_guiado" (feito ou pulado), "tut_p_<passo>"
## (passos do guiado já cumpridos, para retomar) e "tut_<aula>" (aulas já dadas).

enum Fonte { NENHUM, GUIADO, TREINO }

# modos de `principal.gd` (o enum dele não é visível daqui)
const M_GUARDA := 0
const M_COMBATE := 1
const M_FIM := 2
const M_MAPA := 3
const M_TITULO := 4

## Na primeira onda do tutorial os bichos têm esta fração da vida e do dano (só com o tutorial ativo; ver Estado).
const FACIL := 0.6
const LARG_BALAO := 440.0
const TAM_TEXTO := 17
const COR_OURO := Color(1.0, 0.82, 0.3)

var p: Variant = null
var fonte: int = Fonte.NENHUM
var roteiro: Array[Dictionary] = []
var passo_i: int = 0
var _mostrando: bool = false      # o passo atual já apareceu (ini chamado)
var _t: float = 0.0
var _t_passo: float = 0.0
var _t_modo: float = 0.0
var _modo_ant: int = -99
var _press_ok: bool = false       # o último aperto do mouse foi permitido (a soltura acompanha)
var _piscar: float = 0.0          # clarão do holofote quando o jogador clica fora dele
var _pular_t: float = 0.0         # > 0: "Pular tutorial" foi clicado e espera a confirmação
var _rect_ok: Rect2 = Rect2()
var _rect_pular: Rect2 = Rect2()
var _snap: Dictionary = {}
var _vis_guiado: bool = false
# aulas
var fila: Array[Dictionary] = []
var aula: Dictionary = {}
var aula_i: int = 0
var _t_aula: float = 0.0
var _vigia_t: float = 0.0
var _no_topo: bool = false        # a aula de uma janela (Oficina, Fichário) está à vista e o tutorial foi para o topo

func iniciar(d: Variant) -> void:
	p = d
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	roteiro = _montar_roteiro()
	visible = false

# ------------------------------------------------------------------ roteiro do guiado
func _passo(id: String, modo: int, tipo: String, txt: String, alvo: String, extra: Dictionary = {}) -> Dictionary:
	var d: Dictionary = {"id": id, "modo": modo, "tipo": tipo, "txt": txt, "alvo": alvo, "teclas": [], "segura": false}
	d.merge(extra, true)
	return d

func _montar_roteiro() -> Array[Dictionary]:
	var ent: Array = [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	var r: Array[Dictionary] = []
	r.append(_passo("obj", M_MAPA, "ok", "Oi! Eu sou o gato-guia. Bichos invasores querem derrubar e roubar os blocos da torre. Sem blocos, a onda está perdida.", ""))
	r.append(_passo("mapa", M_MAPA, "acao", "A casa tem cinco cômodos, cada um com cinco ondas. Clique no Quarto para começar.", "comodo:0", {"cond": "_c_guarda", "teclas": ent}))
	r.append(_passo("time", M_GUARDA, "ok", "Estes são os seus gatos. Cada um luta sozinho e pode vestir até 4 peças.", "gatos"))
	r.append(_passo("sel", M_GUARDA, "acao", "Clique neste gato para escolhê-lo. O que você vestir vai para o escolhido.", "gato:0", {"ini": "_i_sel", "cond": "_c_sel", "teclas": [KEY_1]}))
	r.append(_passo("vestir", M_GUARDA, "acao", "Arraste o Capacete até o gato. Só clicar na peça também funciona.", "capacete", {"ini": "_i_vestir", "cond": "_c_vestir"}))
	r.append(_passo("espacos", M_GUARDA, "ok", "Cada gato tem 4 espaços: Cabeça, Corpo, Mão e Acessório. A mão é a arma. O resto dá vida, defesa e truques. Passe o mouse numa peça para ver o que ela faz.", "gato_sel"))
	r.append(_passo("outras", M_GUARDA, "acao", "Agora vista o Colete e uma arma: o Porrete ou o Estilingue.", "painel+gato_sel", {"cond": "_c_outras"}))
	r.append(_passo("fantasias", M_GUARDA, "ok", "Peças da mesma fantasia combinam. Com 2 ou 3 vem um bônus. Com as 4, o gato ganha um poder.", "painel"))
	r.append(_passo("botoes", M_GUARDA, "ok", "Com mais peças, estes botões vestem os gatos por você. Vestir o time é a tecla V.", "bt_vestir"))
	r.append(_passo("linha", M_GUARDA, "acao", "Cada gato luta numa linha: Frente, Meio ou Fundo. A frente apanha primeiro. Clique em Linha para trocar.", "linhas", {"ini": "_i_linha", "cond": "_c_linha"}))
	r.append(_passo("lutar", M_GUARDA, "acao", "Pronto! Clique em LUTAR para a onda começar.", "btn_lutar", {"cond": "_c_lutar", "teclas": ent}))
	r.append(_passo("prep_gatos", M_COMBATE, "acao", "A onda ainda não começou. Arraste um gato para escolher onde ele fica.", "prep_gatos", {"prep": true, "cond": "_c_posto", "solta_livre": true}))
	r.append(_passo("prep_postura", M_COMBATE, "acao", "Dê ordens ao time: Avançar ataca, Segurar espera no posto, Recuar fica junto da torre. Clique numa (ou Q, W, E).", "prep_ordens", {"prep": true, "ini": "_i_postura", "cond": "_c_postura", "teclas": [KEY_Q, KEY_W, KEY_E]}))
	r.append(_passo("prep_alvo", M_COMBATE, "acao", "Esta é a onda que vem. Clique num bicho para os gatos baterem nele primeiro.", "prep_previa", {"prep": true, "cond": "_c_alvo"}))
	r.append(_passo("prep_ir", M_COMBATE, "acao", "Tudo certo? Clique em Começar a onda (ou aperte Espaço).", "prep_comecar", {"prep": true, "cond": "_c_ir", "teclas": ent, "marca": "a_prep"}))
	r.append(_passo("luta_vel", M_COMBATE, "acao", "A luta corre sozinha. Este botão muda a velocidade: 1x, 2x ou 3x. Clique nele.", "vel", {"ini": "_i_vel", "cond": "_c_vel", "segura": true}))
	r.append(_passo("luta_pausa", M_COMBATE, "ok", "Este botão (ou a tecla Esc) pausa a luta. Lá dentro ficam as Opções.", "pausa", {"segura": true}))
	r.append(_passo("luta_ver", M_COMBATE, "ok", "Agora é só assistir! Se os blocos da torre acabarem, a onda está perdida.", "campo_torre", {"segura": true}))
	r.append(_passo("depois", M_GUARDA, "ok", "Onda vencida! Os bichos podem largar peças novas, que ficam na aba Novas. Os gatos ganham experiência.", "aba_novas"))
	r.append(_passo("treino", M_GUARDA, "acao", "Gato que sobe de nível ganha 1 ponto de treino. Gaste em Vida, Força ou Agilidade.", "atributos", {"ini": "_i_treino", "cond": "_c_treino", "marca": "a_treino"}))
	r.append(_passo("fim", M_GUARDA, "ok", "Isso é o básico! Vença as outras 4 ondas do Quarto. Na última vem o chefe. Boa sorte!", "", {"rotulo": "Vamos lá!", "txt_treino": "Fim do treino! Na campanha de verdade o Quarto continua por mais 4 ondas. Vou te levar de volta ao título."}))
	return r

# ---- condições e inícios dos passos
func _gato_sel() -> int:
	if p.sel >= 0 and p.sel < p.estado.bonecos.size():
		return p.sel
	return 0

func _vestidas(i: int) -> int:
	if i < 0 or i >= p.estado.bonecos.size():
		return 0
	var n: int = 0
	for q in p.estado.bonecos[i].pecas:
		if q != null:
			n += 1
	return n

func _c_guarda() -> bool:
	return int(p.modo) == M_GUARDA

func _i_sel() -> void:
	p._desselecionar()

func _c_sel() -> bool:
	return p.sel >= 0

func _i_vestir() -> void:
	p._trocar_aba(p.ABA_TODAS)
	p.filtro_cj = -1
	p._lista_suja = true

func _c_vestir() -> bool:
	return p.estado.bonecos[_gato_sel()].pecas[Pecas.SLOT_CABECA] != null

func _c_outras() -> bool:
	return _vestidas(_gato_sel()) >= 3

func _i_linha() -> void:
	var l: Array = []
	for b in p.estado.bonecos:
		l.append(b.linha)
	_snap["linhas"] = l

func _c_linha() -> bool:
	var l: Array = _snap.get("linhas", [])
	for i in mini(l.size(), p.estado.bonecos.size()):
		if p.estado.bonecos[i].linha != int(l[i]):
			return true
	return false

func _c_lutar() -> bool:
	return int(p.modo) == M_COMBATE

func _c_posto() -> bool:
	for b in p.estado.bonecos:
		if b.posto != Boneco.SEM_POSTO:
			return true
	return false

func _i_postura() -> void:
	var l: Array = []
	for bo in p.estado.bonecos:
		l.append(bo.postura)   # a ordem dada fica em Boneco.postura (-1 = a da linha)
	_snap["posturas"] = l

func _c_postura() -> bool:
	var l: Array = _snap.get("posturas", [])
	for i in mini(l.size(), p.estado.bonecos.size()):
		if p.estado.bonecos[i].postura != int(l[i]):
			return true
	return false

func _c_alvo() -> bool:
	return p.campo.sim.prioridade >= 0

func _c_ir() -> bool:
	return not p.campo.prep

func _i_vel() -> void:
	_snap["vel"] = p.velocidade

func _c_vel() -> bool:
	return p.velocidade != int(_snap.get("vel", p.velocidade))

func _i_treino() -> void:
	_snap["pontos"] = p._pontos_totais()

func _c_treino() -> bool:
	return p._pontos_totais() < int(_snap.get("pontos", 0)) or p._pontos_totais() == 0

# ------------------------------------------------------------------ API para o resto do jogo
func guiado_ativo() -> bool:
	return fonte != Fonte.NENHUM

func treino_ativo() -> bool:
	return fonte == Fonte.TREINO

## Começa o guiado numa campanha nova (se o jogador nunca o concluiu nem o pulou) ou o treino do título.
func comecar(f: int, retomar: bool = false) -> void:
	fonte = f
	passo_i = 0
	_mostrando = false
	_snap.clear()
	aula = {}
	fila.clear()
	if f == Fonte.GUIADO:
		if retomar:
			for i in roteiro.size():
				if not Menus.dicas_vistas.get("tut_p_" + str(roteiro[i]["id"]), false):
					passo_i = i
					break
		else:
			for s in roteiro:
				Menus.dicas_vistas["tut_p_" + str(s["id"])] = false
			Menus.gravar_opcoes()
	p.estado.tutorial_facil = true
	_pular_t = 0.0

## Só no começo de uma campanha nova: guia se o tutorial nunca foi concluído nem pulado.
func guiar_campanha_nova() -> void:
	if not Menus.dicas_vistas.get("tut_guiado", false):
		comecar(Fonte.GUIADO)
	else:
		fonte = Fonte.NENHUM

## Ao abrir o jogo: se o guiado ficou pelo meio, volta de onde parou.
func retomar_se_preciso() -> void:
	if Menus.dicas_vistas.get("tut_guiado", false) or not p.tem_save:
		return
	for s in roteiro:
		if Menus.dicas_vistas.get("tut_p_" + str(s["id"]), false):
			comecar(Fonte.GUIADO, true)
			return

func _concluir(pulado: bool) -> void:
	var era: int = fonte
	fonte = Fonte.NENHUM
	_mostrando = false
	_vis_guiado = false
	p.campo.segurar = false
	p.estado.tutorial_facil = false
	if era == Fonte.TREINO:
		p.menus.ir(p.sair_do_treino)
	else:
		Menus.dicas_vistas["tut_guiado"] = true
		Menus.dicas_vistas["tut_pulado"] = pulado
		Menus.gravar_opcoes()
	visible = false
	queue_redraw()

## Para tudo (saída do treino pela pausa, por exemplo).
func parar() -> void:
	fonte = Fonte.NENHUM
	_mostrando = false
	_vis_guiado = false
	aula = {}
	fila.clear()
	visible = false

func _marcar_passo(s: Dictionary) -> void:
	if fonte == Fonte.GUIADO:
		Menus.dicas_vistas["tut_p_" + str(s["id"])] = true
		Menus.gravar_opcoes()
	if s.has("marca"):
		_marcar_aula(str(s["marca"]))

func _marcar_aula(id: String) -> void:
	if fonte == Fonte.TREINO:
		return
	Menus.dicas_vistas["tut_" + id] = true
	Menus.gravar_opcoes()

func _avancar() -> void:
	var s: Dictionary = roteiro[passo_i]
	_marcar_passo(s)
	passo_i += 1
	_mostrando = false
	_t_passo = 0.0
	_pular_t = 0.0
	Som.tocar("aba", 1.2, 0.03, -6.0)
	if passo_i >= roteiro.size():
		_concluir(false)

## Gravação feita antes do tutorial existir: marca como vistas as aulas que o jogador já viveu.
func migrar() -> void:
	if Menus.dicas_vistas.get("tut_migrado", false):
		return
	Menus.dicas_vistas["tut_migrado"] = true
	var v: Dictionary = Menus.dicas_vistas
	for par in [["poder", "a_poder"], ["prep", "a_prep"], ["trofeu", "a_trofeu"], ["queda", "a_marcas"], ["fantasia", "a_fantasia"]]:
		if v.get(par[0], false):
			v["tut_" + par[1]] = true
	for t in range(1, 10):
		if v.get("bicho_%d" % t, false):
			v["tut_a_bicho_%d" % t] = true
	var e: Estado = p.estado
	if p.tem_save and (int(e.estat.get("ondas", 0)) > 0 or e.fases_vencidas > 0):
		v["tut_guiado"] = true
		v["tut_a_treino"] = true
		v["tut_a_prep"] = true
		v["tut_a_fusao"] = true
		if e.fantasias_completas() > 0:
			v["tut_a_fantasia"] = true
			v["tut_a_poder"] = true
		if e.trofeus > 0 or e.metas_pagas.size() > 0:
			v["tut_a_trofeu"] = true
		if e.fases_vencidas >= 1:
			v["tut_a_mapa"] = true
			v["tut_a_fichario"] = true
			v["tut_a_chefe"] = true
		if int(e.estat.get("nocautes", 0)) > 0:
			v["tut_a_marcas"] = true
		if e.campanha_vencida():
			v["tut_a_ato2"] = true
			v["tut_a_invasao"] = true
		for b in e.bonecos:
			if b.nivel >= Balanco.HERANCA_NIVEIS:
				v["tut_a_heranca"] = true
	Menus.gravar_opcoes()

# ------------------------------------------------------------------ alvos (retângulos que o holofote destaca)
func _rb(c: Control) -> Rect2:
	return Rect2(c.position, c.size)

func _alvos(id: String) -> Array[Rect2]:
	var r: Array[Rect2] = []
	if id == "":
		return r
	if id.contains("+"):
		for parte in id.split("+"):
			r.append_array(_alvos(parte))
		return r
	var e: Estado = p.estado
	var nome: String = id.get_slice(":", 0)
	var arg: String = id.get_slice(":", 1) if id.contains(":") else ""
	match nome:
		"gatos":
			r.append(Rect2(206, 8, 780, 440))
		"of_trofeus":
			r.append(Rect2(500.0, 50.0, 280.0, 100.0))
		"of_melhorias":
			r.append(Oficina.rect_linha(0).merge(Oficina.rect_linha(Torre.MELHORIA_NOME.size() - 1)))
		"of_modulos":
			r.append(Oficina.rect_aba(0).merge(Oficina.rect_aba(Oficina.ABAS_NOME.size() - 1)).merge(Oficina.rect_card(Torre.MODULOS_POR_ABA - 1)))
		"of_fechar":
			r.append(Oficina.BTN_FECHAR)
		"fi_pagina":
			r.append(Fichario.PG_E.merge(Fichario.PG_D))
		"fi_abas":
			r.append(Rect2(1096.0, 90.0, 150.0, 590.0))
		"fi_nav":
			r.append(Fichario.BTN_ANT.merge(Fichario.BTN_PROX))
		"gato":
			var i: int = int(arg)
			if i < e.bonecos.size():
				var c: Vector2 = p.pos_boneco(i)
				r.append(Rect2(c.x - 76.0, 8.0, 152.0, 440.0))
		"gato_sel":
			var c2: Vector2 = p.pos_boneco(_gato_sel())
			r.append(Rect2(c2.x - 76.0, 8.0, 152.0, 440.0))
		"capacete":
			var lista: Array = p._visiveis()
			var ti: int = 0
			for k in lista.size():
				if (lista[k] as Peca).tipo == Pecas.Tipo.CAPACETE:
					ti = k
					break
			if not lista.is_empty():
				r.append(p.rect_tile(ti))
			var c3: Vector2 = p.pos_boneco(_gato_sel())
			r.append(Rect2(c3.x - 72.0, c3.y - 112.0, 144.0, 127.0))
		"painel":
			r.append(p.PAINEL)
		"aba_novas":
			r.append(p.rect_aba(p.ABA_NOVAS))
		"bt_vestir":
			r.append(_rb(p.btn_melhor).merge(_rb(p.btn_time)).merge(_rb(p.btn_desf)))
		"linhas":
			for i2 in e.bonecos.size():
				r.append(p.rect_linha(i2))
		"atributos":
			for i3 in e.bonecos.size():
				if e.bonecos[i3].pontos > 0:
					r.append(p.rect_atr(i3, 0).merge(p.rect_atr(i3, 2)))
		"btn_lutar":
			r.append(_rb(p.btn_lutar))
		"vel":
			r.append(_rb(p.btn_vel))
		"pausa":
			r.append(_rb(p.btn_pausa))
		"torre_bt":
			r.append(_rb(p.btn_torre))
		"fich_bt":
			r.append(_rb(p.btn_fich))
		"previa":
			r.append(p.PREVIA)
		"comodo":
			var rs: Array[Rect2] = MapaCasa.lugares()
			var ci: int = int(arg)
			if ci >= 0 and ci < rs.size():
				r.append(rs[ci])
		"mapa_invasao":
			r.append(MapaCasa.BT_INVASAO)
		"mapa_vista":
			r.append(MapaCasa.BT_VISTA)
		"campo_torre":
			r.append(Rect2(0, 420, 215, 300))
		"prep_gatos":
			if p.campo.sim != null:
				for u in p.campo.sim.aliados:
					r.append(p.campo._caixa_unidade(u).grow(4.0))
		"prep_ordens":
			r.append(p.campo._prep_rect(0).merge(p.campo._prep_rect(2)))
		"prep_comecar":
			r.append(Campo.PREP_COMECAR)
		"prep_previa":
			for g in p.campo.prep_previa:
				r.append(_caixa_previa(g))
		"tipo":
			for g2 in p.campo.prep_previa:
				if int(g2["prio"]) == int(arg):
					r.append(_caixa_previa(g2))
		"poder":
			var bi: int = int(arg)
			if bi >= 0 and bi < p.campo.poder_btns.size():
				r.append(p.campo.poder_btns[bi]["rect"])
		"gato_fant":
			for i4 in e.bonecos.size():
				if e.bonecos[i4].fantasia_completa() >= 0:
					var c4: Vector2 = p.pos_boneco(i4)
					r.append(Rect2(c4.x - 76.0, 8.0, 152.0, 440.0))
					break
		"gato_caido":
			for b in p.nocauteados:
				var ix: int = e.bonecos.find(b)
				if ix >= 0:
					var c5: Vector2 = p.pos_boneco(ix)
					r.append(Rect2(c5.x - 76.0, 8.0, 152.0, 440.0))
					break
		"gato_heranca":
			for i5 in e.bonecos.size():
				if e.bonecos[i5].nivel >= Balanco.HERANCA_NIVEIS:
					var c6: Vector2 = p.pos_boneco(i5)
					r.append(Rect2(c6.x - 76.0, 8.0, 152.0, 440.0))
					break
	return r

func _caixa_previa(g: Dictionary) -> Rect2:
	var pos: Vector2 = g["pos"]
	var e: float = Campo.esc_tela(g["u"] as Unidade)
	return Rect2(pos.x - (Campo.CORPO_LARG + 6.0) * e, pos.y - (Campo.CORPO_ALT + 6.0) * e, (Campo.CORPO_LARG + 6.0) * 2.0 * e, (Campo.CORPO_ALT + 16.0) * e)

# ------------------------------------------------------------------ ciclo
## O jogo está num estado em que um balão pode aparecer (sem menu, cortina, janela ou resumo por cima).
func _ambiente_livre() -> bool:
	if p == null or p.menus.ativo() or p.menus.em_transicao():
		return false
	if (p.oficina != null and p.oficina.aberta) or (p.fichario != null and p.fichario.aberto()):
		return false
	var m: int = int(p.modo)
	if m == M_GUARDA and (not p.resumo.is_empty() or p.ajuda_aberta or p.avisos_aberto or not p.fusao.is_empty()):
		return false
	if m == M_COMBATE and (p.campo.sim == null or p.campo.sim.terminada):
		return false
	return m == M_GUARDA or m == M_COMBATE or m == M_MAPA

func _process(delta: float) -> void:
	if p == null:
		return
	_t += delta
	_piscar = maxf(0.0, _piscar - delta)
	_pular_t = maxf(0.0, _pular_t - delta)
	var m: int = int(p.modo)
	if m != _modo_ant:
		_modo_ant = m
		_t_modo = 0.0
	_t_modo += delta
	if fonte != Fonte.NENHUM:
		_passo_guiado(delta)
	else:
		_vigiar_aulas(delta)
		_vis_guiado = false
	p.campo.segurar = _quer_segurar()
	if _no_topo and aula.is_empty():
		_no_topo = false
		p.move_child(self, p.menus.get_index())   # volta para logo abaixo dos menus, como no início
	var vis: bool = _vis_guiado or not aula.is_empty() or (fonte != Fonte.NENHUM and _ambiente_livre())
	if vis != visible:
		visible = vis
	if visible:
		queue_redraw()

func _quer_segurar() -> bool:
	if _vis_guiado and fonte != Fonte.NENHUM and bool(roteiro[passo_i].get("segura", false)):
		return true
	if not aula.is_empty() and bool(aula.get("segura", false)) and int(p.modo) == M_COMBATE:
		return true
	return false

func _passo_guiado(delta: float) -> void:
	if passo_i >= roteiro.size():
		return
	var s: Dictionary = roteiro[passo_i]
	# o passo de ação vale assim que a condição se cumpre, mesmo no meio de uma troca de tela
	if _mostrando and s["tipo"] == "acao" and s.has("cond") and bool(call(str(s["cond"]))):
		_avancar()
		_vis_guiado = false
		return
	var m: int = int(p.modo)
	# o jogador saiu do caminho (voltou ao mapa, desistiu da luta): o roteiro volta ao ponto certo
	if m == M_MAPA and int(s["modo"]) != M_MAPA:
		var im: int = _indice("mapa")
		if im >= 0 and passo_i > im:
			passo_i = im
			_mostrando = false
			return
	elif m == M_GUARDA and int(s["modo"]) == M_COMBATE:
		var il: int = _indice("lutar")
		if il >= 0 and passo_i > il:
			passo_i = il
			_mostrando = false
			return
	var ok_modo: bool = m == int(s["modo"])
	if ok_modo and s.has("prep"):
		ok_modo = p.campo.sim != null and p.campo.prep == bool(s["prep"])
	if m == M_COMBATE and int(s["modo"]) == M_COMBATE and not s.has("prep"):
		ok_modo = ok_modo and p.campo.sim != null and not p.campo.prep
	var livre: bool = ok_modo and _ambiente_livre() and _t_modo > 0.7
	if not livre:
		_vis_guiado = false
		if not _mostrando:
			return
		# já tinha aparecido: continua aguardando (sem desenhar) até o ambiente voltar
		return
	if not _mostrando:
		_mostrando = true
		_t_passo = 0.0
		if s.has("ini"):
			call(str(s["ini"]))
	_vis_guiado = true
	_t_passo += delta

func _indice(id: String) -> int:
	for i in roteiro.size():
		if roteiro[i]["id"] == id:
			return i
	return -1

# ------------------------------------------------------------------ entrada (filtra o que o jogador pode fazer no guiado)
func _bloqueando() -> bool:
	return fonte != Fonte.NENHUM and _vis_guiado and passo_i < roteiro.size() and visible

func _permitido(pos: Vector2) -> bool:
	if _rect_pular.has_point(pos):
		return true
	var s: Dictionary = roteiro[passo_i]
	for h in _alvos(str(s["alvo"])):
		if h.grow(4.0).has_point(pos):
			return true
	return false

func _input(ev: InputEvent) -> void:
	if p == null or not visible:
		return
	# "Pular tutorial" vale sempre que o guiado está à vista
	if fonte != Fonte.NENHUM and ev is InputEventMouseButton:
		var mp: InputEventMouseButton = ev as InputEventMouseButton
		if mp.button_index == MOUSE_BUTTON_LEFT and mp.pressed and _rect_pular.has_point(mp.position) and not p.menus.ativo() and not p.menus.em_transicao():
			get_viewport().set_input_as_handled()
			if _pular_t > 0.0:
				_concluir(true)
			else:
				_pular_t = 3.0
				Som.tocar("clique")
			return
	# "Entendi" (aula ou passo de explicação)
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (ev as InputEventMouseButton).pressed:
		var mb0: InputEventMouseButton = ev as InputEventMouseButton
		if _rect_ok.size.x > 0.0 and _rect_ok.has_point(mb0.position) and (not aula.is_empty() or _bloqueando()):
			get_viewport().set_input_as_handled()
			Som.tocar("clique")
			_entendi()
			return
	if not aula.is_empty() and _no_topo and fonte == Fonte.NENHUM:
		# aula de uma janela: só o "Entendi" vale (Esc ainda fecha a janela e encerra a aula)
		if ev is InputEventMouseButton:
			get_viewport().set_input_as_handled()
		elif ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode != KEY_ESCAPE:
			if not (ev as InputEventKey).echo and ((ev as InputEventKey).keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]):
				_entendi()
			get_viewport().set_input_as_handled()
		return
	if not _bloqueando():
		return
	var s: Dictionary = roteiro[passo_i]
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			get_viewport().set_input_as_handled()
			return
		if mb.pressed:
			if s["tipo"] == "acao" and _permitido(mb.position):
				_press_ok = true
				return
			_press_ok = false
			get_viewport().set_input_as_handled()
			_piscar = 0.45
			UIComum.som_negado()
		else:
			if not _press_ok:
				get_viewport().set_input_as_handled()
				return
			if not _permitido(mb.position) and not bool(s.get("solta_livre", false)):
				# largou fora do holofote: o arrasto é cancelado em vez de cair onde não deve
				p.arrasto = {}
				get_viewport().set_input_as_handled()
			_press_ok = false
	elif ev is InputEventKey:
		var k: InputEventKey = ev as InputEventKey
		if not k.pressed:
			return
		if k.keycode == KEY_ESCAPE:
			return
		if s["tipo"] == "ok" and (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER or k.keycode == KEY_SPACE):
			get_viewport().set_input_as_handled()
			if not k.echo:
				_entendi()
			return
		if s["tipo"] == "acao" and k.keycode in (s["teclas"] as Array):
			return
		get_viewport().set_input_as_handled()

func _entendi() -> void:
	if not aula.is_empty():
		aula_i += 1
		_t_aula = 0.0
		if aula_i >= (aula["balaos"] as Array).size():
			if not bool(aula.get("rever", false)):
				_marcar_aula(str(aula["id"]))   # revisão (botão "?") não conta como progresso
			aula = {}
			p.menus.espera_dica = 0.8
		return
	if fonte != Fonte.NENHUM and passo_i < roteiro.size() and roteiro[passo_i]["tipo"] == "ok":
		_avancar()

# ------------------------------------------------------------------ aulas de primeira vez
func _visto(id: String) -> bool:
	return bool(Menus.dicas_vistas.get("tut_" + id, false))

func _na_fila(id: String) -> bool:
	for a in fila:
		if a["id"] == id:
			return true
	return false

## Pede uma aula (ganchos de fora). Ignorada se já foi dada ou já está na fila.
func pedir(id: String) -> void:
	if fonte != Fonte.NENHUM or _visto(id) or _na_fila(id) or (not aula.is_empty() and aula["id"] == id):
		return
	var a: Dictionary = _aula(id)
	if not a.is_empty():
		fila.append(a)

func _aula(id: String) -> Dictionary:
	var d: Dictionary = {"id": id, "modos": [M_GUARDA], "balaos": [], "segura": false}
	match id:
		"a_fantasia":
			d["balaos"] = [["Fantasia completa! Com as 4 peças da mesma fantasia, o gato ganha um poder.", "gato_fant"], ["Na luta o poder vira um botão lá embaixo. Você escolhe a hora de soltar.", ""]]
		"a_treino":
			d["balaos"] = [["Subiu de nível! Cada nível dá 1 ponto de treino. Gaste em Vida, Força ou Agilidade.", "atributos"]]
		"a_fusao":
			d["balaos"] = [["Peça repetida? Ela se funde sozinha com a que você já tem, e a peça fica melhor.", "painel"], ["Se as duas já estão no máximo, a repetida vira um troféu.", ""]]
		"a_trofeu":
			d["modos"] = [M_GUARDA, M_MAPA]
			d["balaos"] = [["Você ganhou troféus! Eles pagam melhorias permanentes da torre.", "torre_bt"], ["Abra a Oficina (tecla T) para gastá-los. Cada chefe vencido também libera um módulo.", "torre_bt"]]
		"a_heranca":
			d["balaos"] = [["Nível 10! O gato pode guardar o poder da fantasia completa que veste.", "gato_heranca"], ["Clique em \"Herança pronta!\" sob o gato. Depois o poder dispara sozinho na luta.", "gato_heranca"]]
		"a_marcas":
			d["balaos"] = [["Um gato caiu na luta! A roupa dele ganhou uma marca.", "gato_caido"], ["Marcas dão efeitos extras à peça. Cada peça aguenta poucas. Passe o mouse nela para ver.", "gato_caido"]]
		"a_chefe":
			d["balaos"] = [["Última onda do cômodo: vem o chefe! Ele tem vida de sobra e um truque só dele.", "previa"], ["Vencê-lo libera o próximo cômodo, um gato novo no time e um módulo para a torre.", ""]]
		"a_mapa":
			d["modos"] = [M_MAPA]
			d["balaos"] = [["Cômodo novo liberado! Cada um tem uma família de bichos e um chefe.", "comodo:%d" % clampi(p.estado.fase_liberada - 1, 0, Fases.TOTAL - 1)], ["Dá para voltar aos cômodos vencidos para treinar e juntar peças.", ""]]
		"a_fichario":
			d["modos"] = [M_MAPA]
			d["balaos"] = [["O Fichário [F] é o álbum das fantasias. Na aba Metas há prêmios em troféus.", "fich_bt"]]
		"a_ato2":
			d["modos"] = [M_MAPA]
			d["balaos"] = [["Casa limpa, mas os bichos fugiram para fora! É o segundo ato.", ""], ["Aperte V (ou o botão) para ver o mapa de fora: Quintal, Garagem, Telhado, Rua e Toca.", "mapa_vista"]]
		"a_invasao":
			d["modos"] = [M_MAPA]
			d["balaos"] = [["Agora existe a Invasão sem fim: ondas e mais ondas até a torre cair. Ela fica na vista da casa; este botão alterna as vistas.", "mapa_vista"], ["Na casa, escolha um cômodo e aperte I. O seu recorde fica gravado.", ""]]
		"a_prep":
			d["modos"] = [M_COMBATE]
			d["prep"] = true
			d["balaos"] = [["Antes de cada onda você arruma o time. Arraste os gatos para escolher onde ficam.", "prep_gatos"], ["Dê ordens: Avançar, Segurar ou Recuar (teclas Q, W, E). Com um gato escolhido, vale só para ele.", "prep_ordens"], ["Clique num bicho da onda que vem para marcar o alvo. Espaço começa a onda.", "prep_previa"]]
		"a_poder":
			d["modos"] = [M_COMBATE]
			d["segura"] = true
			d["balaos"] = [["Poder carregado! Clique neste botão (ou aperte o número dele) para soltar.", "poder:%d" % _poder_pronto()], ["Depois ele recarrega. Nas Opções dá para ligar o poder automático.", ""]]
		_:
			if id.begins_with("a_bicho_"):
				var pr: int = int(id.substr(8))
				for g in p.campo.prep_previa:
					if int(g["prio"]) == pr:
						d["modos"] = [M_COMBATE]
						d["prep"] = true
						d["balaos"] = [["%s: %s" % [g["nome"], str(g["dica"]).to_lower()], "tipo:%d" % pr]]
				if (d["balaos"] as Array).is_empty():
					return {}
			else:
				return {}
	return d

## Qual tela está à vista (para o botão "?"): guarda, mapa, prep (preparação da luta) ou luta.
func _contexto() -> String:
	var ov: String = _overlay()
	if ov != "":
		return ov
	match int(p.modo):
		M_GUARDA:
			return "guarda"
		M_MAPA:
			return "mapa"
		M_COMBATE:
			return "prep" if p.campo.prep else "luta"
	return ""

## Janela por cima do jogo que tem o próprio "?": "oficina", "fichario" ou "" (nenhuma).
func _overlay() -> String:
	if p == null:
		return ""
	if p.oficina != null and p.oficina.aberta:
		return "oficina"
	if p.fichario != null and p.fichario.aberto():
		return "fichario"
	return ""

## Botão "?": repete as aulas da tela atual (sem gravar progresso e sem mexer no guiado). Devolve false se não há o que repetir agora.
func rever() -> bool:
	if p == null or fonte != Fonte.NENHUM or p.menus.ativo() or p.menus.em_transicao():
		return false
	var ctx: String = _contexto()
	if ctx != "oficina" and ctx != "fichario" and not _ambiente_livre():
		return false
	var a: Dictionary = _aula_rever(ctx)
	if a.is_empty():
		return false
	a["rever"] = true
	a["ctx"] = ctx
	fila.clear()
	aula = a
	aula_i = 0
	_t_aula = 0.0
	if ctx == "oficina" or ctx == "fichario":
		# a janela fica acima do tutorial na árvore: o tutorial sobe para o topo enquanto a aula dura
		p.move_child(self, p.get_child_count() - 1)
		_no_topo = true
	Som.tocar("aba", 1.25, 0.03, -6.0)
	return true

## Passos de cada tela, na ordem do guiado (mesmos textos e alvos), só explicados: ninguém precisa fazer nada.
func _aula_rever(ctx: String) -> Dictionary:
	var e: Estado = p.estado
	var d: Dictionary = {"id": "rever_" + ctx, "modos": [], "balaos": [], "segura": false}
	var b: Array = []
	match ctx:
		"guarda":
			d["modos"] = [M_GUARDA]
			b = [
				["Estes são os seus gatos. Cada um luta sozinho e pode vestir até 4 peças. Clique num gato para escolhê-lo: o que você vestir vai para o escolhido.", "gatos"],
				["Arraste uma peça até o gato (só clicar nela também funciona). Cada gato tem 4 espaços: Cabeça, Corpo, Mão e Acessório. Passe o mouse numa peça para ver o que ela faz.", "painel"],
				["Peças da mesma fantasia combinam. Com 2 ou 3 vem um bônus. Com as 4, o gato ganha um poder.", "painel"],
				["Estes botões vestem os gatos por você. Vestir o time é a tecla V.", "bt_vestir"],
				["Cada gato luta numa linha: Frente, Meio ou Fundo. A frente apanha primeiro. Clique em Linha para trocar.", "linhas"],
				["Gato que sobe de nível ganha 1 ponto de treino. Gaste em Vida, Força ou Agilidade.", "atributos"],
				["Pronto? Clique em LUTAR para a onda começar. Atalhos e regras: tecla F1.", "btn_lutar"],
			]
		"mapa":
			d["modos"] = [M_MAPA]
			b = [
				["A casa tem cinco cômodos, cada um com cinco ondas. Clique num cômodo para entrar.", "comodo:%d" % clampi(e.fase_liberada - 1, 0, Fases.TOTAL - 1)],
				["Cada cômodo tem uma família de bichos e um chefe. Dá para voltar aos cômodos vencidos para treinar e juntar peças.", ""],
				["O Fichário [F] é o álbum das fantasias. Na aba Metas há prêmios em troféus.", "fich_bt"],
				["Troféus pagam melhorias permanentes da torre. Abra a Oficina (tecla T) para gastá-los.", "torre_bt"],
			]
			if e.campanha_vencida():
				b.append(["Casa limpa, mas os bichos fugiram para fora! Este botão (ou V) alterna as vistas: a casa, o Quintal e o resto. Na casa, I abre a Invasão sem fim.", "mapa_vista"])
		"oficina":
			d["modos"] = [M_GUARDA, M_MAPA]
			b = [
				["Troféus pagam melhorias permanentes da torre. " + Oficina.explicacao_trofeus() + ".", "of_trofeus"],
				["Cada botão Melhorar compra um nível da torre. O preço sobe a cada nível; botão apagado quer dizer que faltam troféus (passe o mouse para ver o motivo).", "of_melhorias"],
				["Cada chefe vencido libera um módulo. Monte nas vagas livres; as abas separam os da casa, de fora e das ruas.", "of_modulos"],
				["Setas e Enter também mexem aqui. Esc ou Fechar volta ao jogo.", "of_fechar"],
			]
		"fichario":
			d["modos"] = [M_GUARDA, M_MAPA]
			b = [
				["O Fichário é o álbum das fantasias: uma página para cada uma, com as 4 peças, o poder e onde achar. Peça que ainda não apareceu fica em silhueta.", "fi_pagina"],
				["As abas pulam para o Índice, para um cômodo, para as fantasias de fora, para as Metas (prêmios em troféus) e para o Bestiário dos bichos.", "fi_abas"],
				["Voltar e Avançar viram as páginas (também setas, A e D, ou a roda do mouse).", "fi_nav"],
				["A última página mostra a fantasia criada no Ateliê, que abre quando o fichário está completo.", "fi_pagina"],
			]
		"prep":
			var a_prep: Dictionary = _aula("a_prep")
			d["modos"] = [M_COMBATE]
			d["prep"] = true
			b = a_prep["balaos"]
		"luta":
			d["modos"] = [M_COMBATE]
			d["segura"] = true   # a luta fica parada enquanto o balão está aberto
			b = [
				["A luta corre sozinha. Este botão muda a velocidade: 1x, 2x ou 3x.", "vel"],
				["Este botão (ou a tecla Esc) pausa a luta. Lá dentro ficam as Opções.", "pausa"],
				["Se os blocos da torre acabarem, a onda está perdida.", "campo_torre"],
			]
			if p.campo.sim != null and p.campo.sim.poder_manual and not p.campo.poder_btns.is_empty():
				b.append(["Poderes das fantasias completas: clique no botão (ou aperte o número dele) quando estiver carregado. Nas Opções dá para ligar o poder automático.", "poder:%d" % _poder_pronto()])
	d["balaos"] = b
	if b.is_empty():
		return {}
	return d

func _poder_pronto() -> int:
	for i in p.campo.poder_btns.size():
		if bool(p.campo.poder_btns[i]["pronto"]):
			return i
	return 0

## Procura, a cada instante, o que merece uma aula (só quando nada guiado está rolando).
func _vigiar_aulas(delta: float) -> void:
	# aula da preparação só vale enquanto a preparação dura (a prévia some quando a onda começa): descarta sem marcar
	if int(p.modo) == M_COMBATE and p.campo.sim != null and not p.campo.prep:
		if not aula.is_empty() and bool(aula.get("prep", false)):
			aula = {}
		for i in range(fila.size() - 1, -1, -1):
			if bool(fila[i].get("prep", false)):
				fila.remove_at(i)
	if not aula.is_empty():
		_t_aula += delta
		if bool(aula.get("rever", false)):
			# revisão pedida pelo botão "?": se a tela mudou, simplesmente acaba (nada a lembrar, nada gravado)
			var ctx_a: String = str(aula["ctx"])
			if ctx_a == "oficina" or ctx_a == "fichario":
				if _contexto() != ctx_a or p.menus.ativo():
					aula = {}
			elif not _ambiente_livre() or _contexto() != ctx_a:
				aula = {}
			return
		if not _ambiente_livre() or not (int(p.modo) in (aula["modos"] as Array)):
			# trocou de tela no meio: a aula some e volta depois (não foi marcada)
			fila.push_front(aula)
			aula = {}
		return
	_vigia_t -= delta
	if _vigia_t <= 0.0:
		_vigia_t = 0.3
		_gatilhos()
	if fila.is_empty() or not _ambiente_livre() or _t_modo < 0.9:
		return
	if int(p.modo) == M_GUARDA and (not p.arrasto.is_empty() or p.menus.espera_dica > 0.0):
		return
	if int(p.modo) == M_COMBATE and not p.campo.faixas.is_empty():
		return   # espera o anúncio "Onda N" acabar
	for i in fila.size():
		if bool(fila[i].get("prep", false)) and not (p.campo.sim != null and p.campo.prep):
			continue
		if int(p.modo) in (fila[i]["modos"] as Array):
			aula = fila[i]
			fila.remove_at(i)
			aula_i = 0
			_t_aula = 0.0
			Som.tocar("aba", 1.25, 0.03, -6.0)
			return

func _gatilhos() -> void:
	var m: int = int(p.modo)
	var e: Estado = p.estado
	if m == M_GUARDA:
		for b in e.bonecos:
			if b.fantasia_completa() >= 0:
				pedir("a_fantasia")
			if b.pontos > 0:
				pedir("a_treino")
			if b.nivel >= Balanco.HERANCA_NIVEIS:
				pedir("a_heranca")
		if not p.nocauteados.is_empty():
			pedir("a_marcas")
		if e.onda == Balanco.ONDAS_TOTAIS:
			pedir("a_chefe")
	if (m == M_GUARDA or m == M_MAPA) and e.trofeus > 0:
		pedir("a_trofeu")
	if m == M_MAPA:
		if e.fases_vencidas >= 1 and not e.campanha_vencida():
			pedir("a_mapa")
		if e.fases_vencidas >= 1:
			pedir("a_fichario")
		if e.campanha_vencida():
			pedir("a_ato2")
			pedir("a_invasao")
	if m == M_COMBATE and p.campo.sim != null:
		if p.campo.prep:
			pedir("a_prep")
			for g in p.campo.prep_previa:
				var pr: int = int(g["prio"])
				if pr != Unidade.Tipo.COMUM and pr != Simulacao.PRIO_CHEFE and (g["pos"] as Vector2).x < 1180.0:
					pedir("a_bicho_%d" % pr)   # só com o bicho à vista na prévia
		elif p.campo.sim.poder_manual and not p.campo.sim.terminada:
			for b2 in p.campo.poder_btns:
				if bool(b2["pronto"]):
					pedir("a_poder")
					break

# ------------------------------------------------------------------ desenho
func _draw() -> void:
	if p == null:
		return
	_rect_ok = Rect2()
	_rect_pular = Rect2()
	_calc_pular()
	if _vis_guiado and fonte != Fonte.NENHUM and passo_i < roteiro.size():
		_desenhar_passo(roteiro[passo_i])
	elif not aula.is_empty() and fonte == Fonte.NENHUM:
		_desenhar_aula()
	if _rect_pular.size.x > 0.0:
		_desenhar_pular()   # por último: o botão fica acima do escurecimento

## Onde fica o "Pular tutorial": um canto livre de cada tela (mapa: entre o título e o Fichário; guarda-roupa e luta: ao lado do alto-direita).
func _calc_pular() -> void:
	if fonte == Fonte.NENHUM:
		return
	var m: int = int(p.modo)
	if not (m == M_GUARDA or m == M_COMBATE or m == M_MAPA) or p.menus.ativo() or p.menus.em_transicao():
		return
	if (p.oficina != null and p.oficina.aberta) or (p.fichario != null and p.fichario.aberto()):
		return
	if m == M_MAPA:
		_rect_pular = Rect2(560, 10, 150, 34)
	elif m == M_COMBATE:
		_rect_pular = Rect2(340, 8, 150, 34)   # entre o título da onda e o contador de bichos
	else:
		_rect_pular = Rect2(912, 8, 150, 34)

func _desenhar_pular() -> void:
	var r: Rect2 = _rect_pular
	var sob: bool = r.has_point(get_local_mouse_position())
	var txt: String = "Pular tutorial" if _pular_t <= 0.0 else "Clique de novo"
	var cor: Color = UIComum.B_MARROM if _pular_t <= 0.0 else UIComum.B_VERMELHO
	UIComum.botao(self, r, txt, cor, {"h": 1.0 if sob else 0.0, "tam": 15}, _t)

func _desenhar_passo(s: Dictionary) -> void:
	var holes: Array[Rect2] = _alvos(str(s["alvo"]))
	var a: float = clampf(_t_passo / 0.25, 0.0, 1.0)
	_escurecer(holes, 0.66 * a)
	_molduras(holes, a)
	var txt: String = str(s["txt"])
	if fonte == Fonte.TREINO and s.has("txt_treino"):
		txt = str(s["txt_treino"])
	var cont: String = "%d de %d" % [passo_i + 1, roteiro.size()]
	_balao(txt, holes, s["tipo"] == "ok", str(s.get("rotulo", "Entendi")), cont, a)

func _desenhar_aula() -> void:
	var bl: Array = aula["balaos"]
	if aula_i >= bl.size():
		return
	var holes: Array[Rect2] = _alvos(str(bl[aula_i][1]))
	var a: float = clampf(_t_aula / 0.25, 0.0, 1.0)
	_molduras(holes, a)
	var cont: String = "" if bl.size() == 1 else "%d de %d" % [aula_i + 1, bl.size()]
	_balao(str(bl[aula_i][0]), holes, true, "Entendi", cont, a)

## Escurece a tela inteira menos os buracos (faixas horizontais entre as bordas dos retângulos).
func _escurecer(holes: Array[Rect2], alfa: float) -> void:
	var cor: Color = Color(0.05, 0.03, 0.09, alfa)
	if holes.is_empty():
		draw_rect(Rect2(0, 0, 1280, 720), cor)
		return
	var hs: Array[Rect2] = []
	for h in holes:
		hs.append(h.grow(6.0).intersection(Rect2(0, 0, 1280, 720)))
	var ys: Array[float] = [0.0, 720.0]
	for h in hs:
		ys.append(h.position.y)
		ys.append(h.end.y)
	ys.sort()
	for k in ys.size() - 1:
		var y0: float = ys[k]
		var y1: float = ys[k + 1]
		if y1 - y0 < 0.5:
			continue
		var iv: Array = []
		for h in hs:
			if h.position.y <= y0 + 0.01 and h.end.y >= y1 - 0.01:
				iv.append([h.position.x, h.end.x])
		iv.sort_custom(func(u: Array, v: Array) -> bool: return u[0] < v[0])
		var x: float = 0.0
		for it in iv:
			if it[0] > x:
				draw_rect(Rect2(x, y0, it[0] - x, y1 - y0), cor)
			x = maxf(x, it[1])
		if x < 1280.0:
			draw_rect(Rect2(x, y0, 1280.0 - x, y1 - y0), cor)

func _molduras(holes: Array[Rect2], a: float) -> void:
	var pu: float = 0.5 + 0.5 * sin(_t * 5.0)
	for h in holes:
		var g: Rect2 = h.grow(6.0)
		var claro: float = 0.6 + 0.4 * pu + _piscar * 2.0
		draw_rect(g.grow(2.0), Color(0.15, 0.08, 0.04, 0.8 * a), false, 2.0)
		draw_rect(g, Color(COR_OURO.r, COR_OURO.g, COR_OURO.b, clampf(claro, 0.0, 1.0) * a), false, 3.0)
	if holes.is_empty():
		return
	# seta que balança apontando para o alvo
	var u: Rect2 = holes[0]
	for h in holes:
		u = u.merge(h)
	# o balanço anda de célula em célula (3 px), sem posição de meio pixel
	var bob: float = floorf(absf(sin(_t * 4.0)) * 2.99) * 3.0
	var cx: float = floorf(clampf(u.get_center().x, 30.0, 1250.0) / 3.0) * 3.0
	if u.position.y > 90.0:
		# a ponta (última fileira) fica 10 px acima do alvo
		_seta_px(cx, u.position.y - 10.0 - bob - 18.0, false, a)
	else:
		_seta_px(cx, u.end.y + 10.0 + bob, true, a)

## Seta em pixel de 9 x 6 células de 3 px (contorno escuro, miolo dourado e um brilho), com o meio em `cx` e o
## topo em `y`; `para_cima` a desenha virada. As fileiras não se sobrepõem, então o alfa `a` fica limpo.
const PX_SETA_ALVO: Array = ["ooooooooo", "occaaaaao", ".ocaaaao.", "..oaaao..", "...oao...", "....o...."]
func _seta_px(cx: float, y: float, para_cima: bool, a: float) -> void:
	var q: float = 3.0
	var x0: float = cx - q * 4.0
	var y0: float = floorf(y / q) * q
	var cont := Color(0.1, 0.05, 0.08, a)
	var ouro := Color(COR_OURO.r, COR_OURO.g, COR_OURO.b, a)
	var claro: Color = Color(1.0, 0.95, 0.7, a)
	var n: int = PX_SETA_ALVO.size()
	for k in n:
		var ln: String = PX_SETA_ALVO[n - 1 - k if para_cima else k]
		var x: int = 0
		while x < ln.length():
			var ch: String = ln[x]
			var x2: int = x
			while x2 + 1 < ln.length() and ln[x2 + 1] == ch:
				x2 += 1
			if ch != ".":
				draw_rect(Rect2(x0 + x * q, y0 + k * q, (x2 - x + 1) * q, q), cont if ch == "o" else (ouro if ch == "a" else claro))
			x = x2 + 1

func _balao(txt: String, holes: Array[Rect2], com_botao: bool, rotulo: String, cont: String, a: float) -> void:
	var fonte_f: Font = UIComum.FONTE
	var larg_txt: float = LARG_BALAO - 76.0
	var linhas: Array[String] = p._quebrar(txt, TAM_TEXTO, larg_txt)
	var alt: float = 26.0 + linhas.size() * 23.0 + 10.0 + (46.0 if com_botao else 0.0)
	alt = maxf(alt, 78.0)
	var r: Rect2 = _onde_balao(Vector2(LARG_BALAO, alt), holes)
	var off: float = (1.0 - a) * 14.0
	r.position.y += off
	var cm: float = a
	UIComum.forma(self, Rect2(r.position + Vector2(0, 5), r.size), Color(0, 0, 0, 0.35 * cm))
	UIComum.caixa(self, r, Color(Menus.C_CONT.r, Menus.C_CONT.g, Menus.C_CONT.b, cm), Color(Menus.C_CREME.r, Menus.C_CREME.g, Menus.C_CREME.b, cm))
	UIComum.spr(self, Menus.R_BALAO[0], Vector2(r.position.x + 12.0, r.position.y + 14.0), 2, Color(1, 1, 1, cm))
	var y: float = r.position.y + 28.0
	for l in linhas:
		draw_string(fonte_f, Vector2(r.position.x + 64.0, y), l, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(TAM_TEXTO), Color(Menus.C_TEXTO.r, Menus.C_TEXTO.g, Menus.C_TEXTO.b, cm))
		y += 23.0
	if cont != "":
		draw_string(fonte_f, Vector2(r.position.x + 12.0, r.end.y - 10.0), cont, HORIZONTAL_ALIGNMENT_LEFT, -1, UIComum.tam(12), Color(Menus.C_TEXTO2.r, Menus.C_TEXTO2.g, Menus.C_TEXTO2.b, cm))
	if com_botao:
		var rb: Rect2 = Rect2(r.end.x - 136.0, r.end.y - 50.0, 120.0, 38.0)
		_rect_ok = Rect2(rb.position - Vector2(0, off), rb.size)
		var sob: bool = _rect_ok.has_point(get_local_mouse_position())
		UIComum.botao(self, rb, rotulo, UIComum.B_VERDE, {"h": 1.0 if sob else 0.0, "tam": 19}, _t)
	else:
		_rect_ok = Rect2()

## Escolhe onde pôr o balão: o canto livre mais perto do alvo, sem cobri-lo nem o botão de pular.
func _onde_balao(tam: Vector2, holes: Array[Rect2]) -> Rect2:
	var u: Rect2 = Rect2()
	var tem: bool = false
	for h in holes:
		u = h.grow(14.0) if not tem else u.merge(h.grow(14.0))
		tem = true
	if not tem:
		return Rect2(Vector2((1280.0 - tam.x) * 0.5, 250.0), tam)
	var melhor: Rect2 = Rect2(Vector2((1280.0 - tam.x) * 0.5, 120.0), tam)
	var mel_d: float = INF
	var xs: Array[float] = [16.0, 220.0, 420.0, 620.0, 824.0]
	var ys: Array[float] = [84.0, 140.0, 200.0, 260.0, 330.0, 400.0, 460.0, 520.0, 580.0, 640.0]
	for x in xs:
		for y in ys:
			var c: Rect2 = Rect2(x, y, tam.x, tam.y)
			if c.end.x > 1272.0 or c.end.y > 712.0:
				continue
			var cobre: bool = false
			for h in holes:
				if c.intersects(h.grow(14.0)):
					cobre = true
					break
			if cobre or c.intersects(_rect_pular.grow(4.0)):
				continue
			var d: float = c.get_center().distance_to(u.get_center())
			if d < mel_d:
				mel_d = d
				melhor = c
	return melhor
