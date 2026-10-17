extends SceneTree
## Mede quantas ondas um gato que entra depois leva para chegar a 2 níveis da média dos outros.
## Uso: godot --headless --path <projeto> --script res://ferramentas/medir_recupera.gd
func _init() -> void:
	for ato in [1, 2, 3]:
		for nivel_time in [5, 10, 20, 30]:
			var tot: Array[int] = []
			for entra in [1, 4]:   # 4º gato (1 de diferença ao entrar) e 5º gato
				var e := Estado.new(1)
				e.novo_jogo()
				e.ato = ato
				e.bonecos.clear()
				for i in 3 + entra - 1:
					var b := Boneco.new()
					b.nivel = nivel_time
					e.bonecos.append(b)
				var novo := Boneco.new()   # entra no nível 1
				e.bonecos.append(novo)
				var ondas: int = 0
				while ondas < 200:
					var soma: float = 0.0
					for b in e.bonecos:
						if b != novo:
							soma += b.nivel
					if novo.nivel >= soma / (e.bonecos.size() - 1) - 2.0:
						break
					e.dar_xp_onda()
					ondas += 1
				tot.append(ondas)
			print("ato %d time nv %2d: ondas para chegar a 2 niveis da media: %d (time de %d) / %d (time de %d)" % [ato, nivel_time, tot[0], 4, tot[1], 7])
	quit()
