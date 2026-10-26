extends SceneTree
## Exporta para idiomas/textos.csv os textos que vivem em TABELAS DE DADOS (nomes e descrições de fantasias, peças, poderes,
## raridades, marcas, chefes, lugares, famílias, gangues, bichos, metas, módulos da torre, truques, ajuda...). Esses textos
## não aparecem como Idioma.t("...") no código: a tabela fica em português (é identidade) e quem a desenha chama
## Idioma.t(Tabela[i]). Aqui só se garante que cada texto da tabela tem linha no CSV.
## Preserva traduções e ordem; acrescenta as chaves novas no fim, com "dados:Classe.TABELA" na coluna "_onde".
## Uso: godot --headless --path <projeto> --script res://ferramentas/extrai_dados.gd
## Depois: godot --headless --path <projeto> --import  (regera a tradução importada)

const CSV := "res://idiomas/textos.csv"

## script -> tabelas (constantes ou static var) com textos de jogador. Ao criar uma tabela nova de textos, acrescente aqui.
const TABELAS := {
	"res://scripts/jogo/pecas.gd": ["MARCA_NOME", "MARCA_DICA", "SLOT_NOME", "NOME", "DICA", "CONJUNTO_NOME", "PODER_NOME", "PODER_DICA", "RARIDADE_NOME"],
	"res://scripts/jogo/fases.gd": ["NOME", "NOME_ATO3", "FAMILIA_NOME", "FAMILIA_DICA", "CHEFE_NOME", "CHEFE_NOME_ATO3", "CHEFE_ATAQUE", "CHEFE_ATAQUE_ATO3",
		"CHEFE_FRAQUEZA", "CHEFE_FRAQUEZA_ATO3", "GANGUE_NOME", "GANGUE_DICA"],
	"res://scripts/jogo/balanco.gd": ["TIPO_NOMES", "GANGUE_TIPO_NOME", "GANGUE_TIPO_DICA", "ATR_NOMES", "NOMES_BONECOS", "ATO_NOME"],
	"res://scripts/jogo/boneco.gd": ["LINHA_NOMES", "POSTURA_NOMES"],
	"res://scripts/jogo/atelie.gd": ["ESTAMPA_NOME", "MATIZ_NOME", "_PREFIXOS"],
	"res://scripts/jogo/poquer.gd": ["NOME"],
	"res://scripts/jogo/simulacao.gd": ["_PIADAS_ESFORCO"],
	"res://scripts/arte/torre.gd": ["MELHORIA_NOME", "MODULO_NOME", "MODULO_DICA"],
	"res://scripts/interface/fichario.gd": ["FAM_ENFRENTAR", "TIPO_ENFRENTAR", "GANGUE_TRUQUE_NOME", "GANGUE_ENFRENTAR"],
	"res://scripts/interface/oficina.gd": ["ABAS_NOME"],
	"res://scripts/interface/campo.gd": ["PREP_DICA"],
	"res://scripts/interface/icones_estado.gd": ["NOME", "CURTO", "DICA"],
	"res://scripts/interface/principal.gd": ["ABA_NOMES", "AJUDA_ATALHOS", "AJUDA_REGRAS", "VENCIDO_GENERO", "ARTIGO"],
}
## Tabelas de índices/pixels com strings que NÃO são texto de jogador (para a lista de candidatas não cobertas).
const NAO_TEXTO := ["PX_", "ICO_", "PALETA", "CABIDE", "EMBLEMAS", "ICONES"]

var achados: Array = []   # [texto, origem]
var vistos: Dictionary = {}

func _initialize() -> void:
	var contagem: Dictionary = {}
	for caminho in TABELAS:
		var sc: GDScript = load(caminho)
		var mapa: Dictionary = sc.get_script_constant_map()
		for nome in TABELAS[caminho]:
			var v: Variant = mapa[nome] if mapa.has(nome) else sc.get(nome)
			if v == null:
				print("AVISO: tabela não encontrada: ", caminho.get_file(), " ", nome)
				continue
			var antes: int = achados.size()
			_coletar(v, "dados:%s.%s" % [_nome_script(sc), nome])
			contagem["%s.%s" % [_nome_script(sc), nome]] = achados.size() - antes
	# metas: a lista é montada por função, com os nomes já compostos ("Quarto sem um arranhão")
	for m in Metas.lista():
		for campo in ["nome", "texto", "grupo"]:
			_adicionar(str(m[campo]), "dados:Metas.lista")
	contagem["Metas.lista"] = achados.size() - int(contagem.values().reduce(func(a, b): return a + b, 0))
	_candidatas()
	for k in contagem:
		print("  %-40s %d" % [k, contagem[k]])
	print("Textos de tabelas encontrados: %d (distintos)" % achados.size())
	_gravar()
	quit(0)

func _coletar(v: Variant, origem: String) -> void:
	if v is String or v is StringName:
		_adicionar(str(v), origem)
	elif v is Array or v is PackedStringArray:
		for x in v:
			_coletar(x, origem)
	elif v is Dictionary:
		for k in v:
			_coletar(v[k], origem)

func _adicionar(txt: String, origem: String) -> void:
	if txt.strip_edges() == "" or vistos.has(txt):
		return
	vistos[txt] = true
	achados.append([txt, origem])

## Arrays de texto em outros scripts que não estão em TABELAS: para o dev conferir se falta alguma.
func _candidatas() -> void:
	var scripts: Array = ["res://scripts/jogo/pecas.gd", "res://scripts/jogo/fases.gd", "res://scripts/jogo/balanco.gd", "res://scripts/jogo/boneco.gd",
		"res://scripts/jogo/atelie.gd", "res://scripts/arte/torre.gd", "res://scripts/interface/fichario.gd", "res://scripts/interface/oficina.gd",
		"res://scripts/interface/principal.gd", "res://scripts/interface/menus.gd", "res://scripts/interface/tutorial.gd", "res://scripts/jogo/estado.gd"]
	for caminho in scripts:
		var sc: GDScript = load(caminho)
		var listadas: Array = TABELAS.get(caminho, [])
		var mapa: Dictionary = sc.get_script_constant_map()
		for nome in mapa:
			var skip := false
			for pref in NAO_TEXTO:
				if str(nome).begins_with(pref) or str(nome) == pref:
					skip = true
			var v: Variant = mapa[nome]
			if skip or nome in listadas or not (v is Array) or (v as Array).is_empty():
				continue
			var a: Array = v
			if (a[0] is String and str(a[0]).length() > 2 and " " in str(a[0]) + " ") or (a[0] is Array and not (a[0] as Array).is_empty() and (a[0] as Array)[0] is String):
				print("CANDIDATA fora de TABELAS: %s.%s  (ex.: %s)" % [sc.get_global_name(), nome, str(a[0]).left(40)])

# ------------------------------------------------------------------ CSV (mesmo formato do extrai_textos.py: aspas só quando preciso, \n)
func _gravar() -> void:
	var cab: PackedStringArray = PackedStringArray(["keys", "en", "_onde"])
	var linhas: Array = []
	var existentes: Dictionary = {}
	if FileAccess.file_exists(CSV):
		var f := FileAccess.open(CSV, FileAccess.READ)
		cab = f.get_csv_line()
		while not f.eof_reached():
			var l: PackedStringArray = f.get_csv_line()
			if l.size() == 0 or (l.size() == 1 and l[0] == ""):
				continue
			linhas.append(l)
			existentes[l[0]] = true
		f.close()
	var col_onde: int = cab.find("_onde")
	var novas: int = 0
	for a in achados:
		if existentes.has(a[0]):
			continue
		var nova := PackedStringArray()
		nova.resize(cab.size())
		nova[0] = a[0]
		if col_onde >= 0:
			nova[col_onde] = a[1]
		linhas.append(nova)
		novas += 1
	var out := FileAccess.open(CSV, FileAccess.WRITE)
	out.store_string(_linha(cab))
	for l in linhas:
		while (l as PackedStringArray).size() < cab.size():
			(l as PackedStringArray).append("")
		out.store_string(_linha(l))
	out.close()
	print("CSV: %d chaves novas de dados, %d linhas no total." % [novas, linhas.size()])

func _linha(campos: PackedStringArray) -> String:
	var partes: PackedStringArray = []
	for c in campos:
		if c.contains(",") or c.contains("\"") or c.contains("\n") or c.contains("\r"):
			partes.append("\"" + c.replace("\"", "\"\"") + "\"")
		else:
			partes.append(c)
	return ",".join(partes) + "\n"

func _nome_script(sc: GDScript) -> String:
	var n: String = str(sc.get_global_name())
	return n if n != "" else sc.resource_path.get_file().get_basename()
