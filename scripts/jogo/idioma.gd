class_name Idioma
extends RefCounted
## Tradução dos textos do jogo. O português é o idioma-fonte: o PRÓPRIO TEXTO EM PORTUGUÊS é a chave.
## `Idioma.t("Onda %d/%d") % [a, b]` devolve o texto no idioma atual; em português (ou sem tradução) devolve a chave.
## As traduções vivem em res://idiomas/textos.csv (coluna "keys" = português, uma coluna por idioma, hoje só "en").
## Convenção completa para quem embrulha textos: docs/traducao.md.

const PADRAO := "pt"
## Idiomas oferecidos nas Opções: código do locale, nome NO PRÓPRIO IDIOMA (nunca traduzir) e nome do jogo.
const CODIGOS: Array[String] = ["pt", "en"]
const NOMES: Array[String] = ["Português", "English"]
const TITULOS: Array[String] = ["Gatos e Roupas", "Cats & Costumes"]

static var atual: String = PADRAO
## Com true (só em build de depuração) anota em `faltas` e em user://textos_sem_traducao.log as chaves
## pedidas fora do português que não têm tradução no CSV. Os testes ficam em português: nunca anotam nada.
static var registrar_faltas: bool = OS.is_debug_build()
static var faltas: Dictionary = {}
static var _cache: Dictionary = {}   # texto em português -> texto no idioma atual (a fonte não muda durante o idioma)

## Traduz um texto escrito em português. Texto vazio e idioma português voltam como vieram.
static func t(pt: String) -> String:
	if atual == PADRAO or pt == "":
		return pt
	var c: Variant = _cache.get(pt)
	if c != null:
		return c
	var r: String = TranslationServer.translate(pt)
	if r == pt and registrar_faltas:
		_anotar_falta(pt)
	_cache[pt] = r
	return r

static func _anotar_falta(pt: String) -> void:
	var obj: Translation = TranslationServer.get_translation_object(atual)
	if obj != null and not String(obj.get_message(pt)).is_empty():
		return   # traduzido com o mesmo texto (ex.: "Tutorial"): não é falta
	if faltas.has(pt):
		return
	faltas[pt] = true
	var f := FileAccess.open("user://textos_sem_traducao.log", FileAccess.READ_WRITE if FileAccess.file_exists("user://textos_sem_traducao.log") else FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line("%s\t%s" % [atual, pt.replace("\n", "\n")])

## Troca o idioma na hora (as telas são redesenhadas a cada quadro) e atualiza o título da janela.
static func definir(codigo: String) -> void:
	if not (codigo in CODIGOS):
		codigo = PADRAO
	atual = codigo
	TranslationServer.set_locale(codigo)
	_cache.clear()
	DisplayServer.window_set_title(titulo_jogo())

## Idioma da primeira execução: inglês, a não ser que o sistema esteja em português.
static func detectar() -> String:
	return PADRAO if OS.get_locale_language() == "pt" else "en"

static func indice() -> int:
	return maxi(0, CODIGOS.find(atual))

## Passa para o idioma seguinte da lista (usado pelo botão das Opções).
static func proximo() -> void:
	definir(CODIGOS[(indice() + 1) % CODIGOS.size()])

static func nome_atual() -> String:
	return NOMES[indice()]

static func titulo_jogo() -> String:
	return TITULOS[indice()]
