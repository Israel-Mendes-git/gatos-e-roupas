extends SceneTree
## Teste headless do sistema de idiomas: tradução por chave, fallback, formatos com %, aspas e vírgulas, integridade do CSV.
## Uso: godot --headless --path <projeto> --script res://ferramentas/teste_idioma.gd

var falhas: int = 0

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		print("FALHOU: ", msg)

func _initialize() -> void:
	Idioma.registrar_faltas = false
	Idioma.definir("pt")
	_ok(Idioma.t("Opções") == "Opções", "português devolve a chave")
	_ok(Idioma.t("") == "", "texto vazio")
	Idioma.definir("en")
	_ok(Idioma.t("Opções") == "Options", "inglês traduz: %s" % Idioma.t("Opções"))
	_ok(Idioma.t("Texto que ninguém traduziu") == "Texto que ninguém traduziu", "sem tradução devolve a chave (nunca vazio)")
	_ok(Idioma.t("Onda %d/%d inexistente") % [1, 2] == "Onda 1/2 inexistente", "formato sem tradução")
	_ok(Idioma.t("Agora: %d%% (de 10 em 10)") % 70 == "Now: 70%% (in steps of 10)".replace("%%", "%"), "formato com %%: %s" % (Idioma.t("Agora: %d%% (de 10 em 10)") % 70))
	_ok(Idioma.t("A luta fica guardada: \"Continuar\" no menu principal volta a este ponto. Se você fechar o jogo, ela se perde (as roupas ficam).").contains("\"Continue\""), "aspas e vírgulas")
	_ok(Idioma.titulo_jogo() == "Cats & Costumes", "título em inglês")
	Idioma.definir("pt")
	_ok(Idioma.titulo_jogo() == "Gatos e Roupas", "título em português")
	_ok(Idioma.t("Opções") == "Opções", "volta ao português")
	Idioma.definir("xx")
	_ok(Idioma.atual == "pt", "código inválido cai no português")
	# CSV: todas as linhas com o mesmo número de colunas; quebra de linha dentro de aspas lida pelo mesmo leitor do importador
	var f := FileAccess.open("res://idiomas/textos.csv", FileAccess.READ)
	var cab: PackedStringArray = f.get_csv_line()
	_ok(cab[0] == "keys" and cab[1] == "en", "cabeçalho do CSV")
	var n: int = 0
	var vistas: Dictionary = {}
	while not f.eof_reached():
		var l: PackedStringArray = f.get_csv_line()
		if l.size() == 1 and l[0] == "":
			continue
		n += 1
		_ok(l.size() == cab.size(), "linha %d com %d colunas" % [n, l.size()])
		_ok(not vistas.has(l[0]), "chave repetida: %s" % l[0])
		vistas[l[0]] = true
	_ok(n > 100, "CSV tem linhas")
	var tmp := FileAccess.open("user://teste_idioma.csv", FileAccess.WRITE)
	tmp.store_string("keys,en\n\"Linha 1\nlinha 2, com \"\"aspas\"\" e 50%\",\"Line 1\nline 2, with \"\"quotes\"\" and 50%\"\n")
	tmp.close()
	var r := FileAccess.open("user://teste_idioma.csv", FileAccess.READ)
	r.get_csv_line()
	var l2: PackedStringArray = r.get_csv_line()
	_ok(l2.size() == 2 and l2[0] == "Linha 1\nlinha 2, com \"aspas\" e 50%" and l2[1].contains("\n"), "CSV com quebra de linha, vírgula, aspas e %")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://teste_idioma.csv"))
	print("FALHAS: %d" % falhas)
	quit(1 if falhas > 0 else 0)
