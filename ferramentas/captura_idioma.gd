extends SceneTree
## Capturas do título e das Opções em português e inglês. Uso (captura na tela 3, sem foco):
##   CAPTURA_USERDIR=gr_idioma python -I notas/captura.py --script res://ferramentas/captura_idioma.gd -- <pasta de saída>
var p: Node = null

func _quadro(caminho: String, esperar: int = 40) -> void:
	for i in esperar:
		if p != null and p.tutorial != null:
			p.tutorial.fila.clear()
			p.tutorial.aula = {}
			p.tutorial.roteiro.clear()
			p.tutorial.visible = false
			p.menus.fila_dicas.clear()
			p.menus.dica_atual = {}
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(caminho)

func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var saida: String = a[0] if a.size() > 0 else "user://"
	Menus.gravar = false
	Menus.transicoes = false
	p = load("res://cenas/principal.tscn").instantiate()
	root.add_child(p)
	for cod in ["pt", "en"]:
		Idioma.definir(cod)
		p.menus.tela = Menus.Tela.TITULO
		p.menus._montar()
		await _quadro("%s/titulo_%s.png" % [saida, cod])
		p.menus.tela_volta = Menus.Tela.TITULO
		p.menus._ir_tela(Menus.Tela.OPCOES)
		await _quadro("%s/opcoes_%s.png" % [saida, cod])
	quit()
