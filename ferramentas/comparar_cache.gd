extends SceneTree
## Compara pixel a pixel o guarda-roupa desenhado direto (sem CacheDesenho) e com as texturas pré-compostas.
## Uso (janela real): python -I notas/captura.py --script <abs>/ferramentas/comparar_cache.gd -- <pasta_saida> [raridade_max]
## Só raridades 0 e 1 entram por padrão (as demais pulsam com o tempo e não dá para fotografar duas vezes igual).
var _p: Node

func _quadro() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _passo() -> int:
	return int(floorf((0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 3.0)) * 2.99))

func _initialize() -> void:
	var a: PackedStringArray = OS.get_cmdline_user_args()
	var rar_max: int = int(a[1]) if a.size() > 1 else 1
	Menus.gravar = false
	Menus.pular_titulo = true
	Menus.transicoes = false
	Menus.cfg_caminho = "user://teste_interface.cfg"
	_p = load("res://cenas/principal.tscn").instantiate()
	root.add_child(_p)
	for i in 5:
		await process_frame
	var e: Estado = _p.estado
	e.persistir = false
	e.novo_jogo()
	e.persistir = false
	e.fases_vencidas = Fases.TOTAL
	e.fase_liberada = Fases.TOTAL
	e.vencido = [3, 3, 3, 3, 3]
	e.guarda.clear()
	var n: int = 0
	for t in Pecas.SLOT.size():
		e.registrar(t)
		var q := Peca.new(t, (n * 3) % 12, n % (rar_max + 1))
		if n % 4 == 1:
			q.marcas.append(n % 3)
			q.marcas.append((n + 1) % 3)
		e.guarda.append(q)
		n += 1
	_p._lista_suja = true
	_p._entrar_guarda()
	var rolagens: Array = [0, 2, 5]
	var pior: int = 0
	for ro in rolagens:
		_p.rolagem = ro
		CacheDesenho.ligado = true
		for i in 45:
			await process_frame   # dá tempo de criar as texturas
		var img_a: Image
		var img_b: Image
		var achou: bool = false
		for rep in 60:
			CacheDesenho.ligado = false
			var pa: int = _passo()
			img_a = await _quadro()
			CacheDesenho.ligado = true
			var pb: int = _passo()
			img_b = await _quadro()
			if pa == pb and _passo() == pa:
				achou = true
				break
		if not achou:
			print("COMPARA rolagem %d: sem quadros no mesmo degrau do brilho" % ro)
			continue
		var dif: int = 0
		var maxd: int = 0
		var reg := Rect2i(220, 498, 730, 202)   # a grade de ladrilhos (o resto da tela tem animação própria)
		var w: int = reg.size.x * reg.size.y
		for y in range(reg.position.y, reg.end.y):
			for x in range(reg.position.x, reg.end.x):
				var ca: Color = img_a.get_pixel(x, y)
				var cb: Color = img_b.get_pixel(x, y)
				var d: int = int(maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b)) * 255.0 + 0.5)
				if d > 0:
					dif += 1
					maxd = maxi(maxd, d)
		print("COMPARA rolagem %d: pixels diferentes na grade %d de %d, diferenca maxima %d/255" % [ro, dif, w, maxd])
		pior = maxi(pior, dif)
		if a.size() > 0:
			img_a.save_png("%s/guarda_r%d_direto.png" % [a[0], ro])
			img_b.save_png("%s/guarda_r%d_cache.png" % [a[0], ro])
	print("COMPARA fim (pior=%d)" % pior)
	quit()
