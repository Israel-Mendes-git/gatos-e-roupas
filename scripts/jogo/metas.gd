class_name Metas
extends RefCounted
## Objetivos do fichário: metas com prêmio em troféus, pagas uma vez só (ver Estado.conferir_metas).

const PREMIO_FANTASIA := 3
const PREMIO_SEM_NOCAUTE := 3

## Todas as metas, na ordem em que aparecem: {"id", "nome", "texto", "premio", "grupo"}.
static func lista() -> Array:
	var l: Array = []
	l.append({"id": "campanha", "nome": "Casa segura", "texto": "Vença os cinco cômodos", "premio": 5, "grupo": "Campanha"})
	for f in Fases.TOTAL:
		l.append({"id": "sem_nocaute_%d" % f, "nome": "%s sem um arranhão" % Fases.NOME[f], "texto": "Vença o cômodo sem nenhum gato nocauteado", "premio": PREMIO_SEM_NOCAUTE, "grupo": "Campanha"})
	l.append({"id": "time_fantasiado", "nome": "Desfile", "texto": "Vença um cômodo com todos os gatos de fantasia completa", "premio": 5, "grupo": "Campanha"})
	l.append({"id": "ato2", "nome": "Vizinhança segura", "texto": "Vença os cinco lugares de fora da casa", "premio": 10, "grupo": "Lado de fora"})
	for f in range(Fases.TOTAL, Fases.NOME.size()):
		l.append({"id": "sem_nocaute_%d" % f, "nome": "%s sem um arranhão" % Fases.NOME[f], "texto": "Vença o lugar sem nenhum gato nocauteado", "premio": PREMIO_SEM_NOCAUTE, "grupo": "Lado de fora"})
	l.append({"id": "heranca", "nome": "De pai para filhote", "texto": "Um gato incorpora o poder de uma fantasia", "premio": 5, "grupo": "Lado de fora"})
	l.append({"id": "marcada", "nome": "Roupa de guerra", "texto": "Tenha uma peça com 4 marcas", "premio": 5, "grupo": "Guarda-roupa"})
	l.append({"id": "colecao_42", "nome": "Meio armário", "texto": "Junte 50 peças diferentes", "premio": 5, "grupo": "Guarda-roupa"})
	l.append({"id": "colecao_84", "nome": "Armário cheio", "texto": "Junte todas as %d peças" % Pecas.SLOT.size(), "premio": 10, "grupo": "Guarda-roupa"})
	l.append({"id": "invasao_10", "nome": "Casa sitiada", "texto": "Passe da onda 10 na Invasão sem fim", "premio": 5, "grupo": "Invasão"})
	l.append({"id": "invasao_20", "nome": "Muralha de gatos", "texto": "Passe da onda 20 na Invasão sem fim", "premio": 10, "grupo": "Invasão"})
	for c in Pecas.CONJUNTO_NOME.size():
		l.append({"id": "fantasia_%d" % c, "nome": "Fantasia de %s" % Pecas.CONJUNTO_NOME[c], "texto": "Junte as 4 peças", "premio": PREMIO_FANTASIA, "grupo": "Fantasias"})
	return l

## A meta `id` já está cumprida no estado `e`?
static func cumprida(id: String, e: Estado) -> bool:
	if id == "campanha":
		return e.campanha_vencida()
	if id == "ato2":
		return e.vencidos_no_ato(2) >= Fases.TOTAL
	if id == "heranca":
		for b in e.bonecos:
			if not b.herancas.is_empty():
				return true
		return false
	if id == "marcada":
		for p in e.todas_as_pecas():
			if p.marcas.size() >= 4:
				return true
		return false
	if id == "colecao_42":
		return e.pecas_tidas() >= 50
	if id == "colecao_84":
		return e.pecas_tidas() >= Pecas.SLOT.size()
	if id == "invasao_10":
		return e.melhor_invasao() >= 10
	if id == "invasao_20":
		return e.melhor_invasao() >= 20
	if id.begins_with("fantasia_"):
		return e.pecas_da_fantasia(int(id.substr(9))) >= Pecas.SLOTS
	# as demais (sem_nocaute_N, time_fantasiado) são anotadas pelo jogo quando acontecem
	return e.feitos.has(id)
