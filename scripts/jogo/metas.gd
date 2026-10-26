class_name Metas
extends RefCounted
## Objetivos do fichário: metas com prêmio em troféus, pagas uma vez só (ver Estado.conferir_metas).

const PREMIO_FANTASIA := 3
const PREMIO_SEM_NOCAUTE := 3

## Todas as metas, na ordem em que aparecem: {"id", "nome", "texto", "premio", "grupo"}.
static func lista() -> Array:
	var l: Array = []
	l.append({"id": "campanha", "nome": Idioma.t("Casa segura"), "texto": Idioma.t("Vença os cinco cômodos"), "premio": 5, "grupo": "Campanha"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	for f in Fases.TOTAL:
		l.append({"id": "sem_nocaute_%d" % f, "nome": Idioma.t("%s sem um arranhão") % Idioma.t(Fases.NOME[f]), "texto": Idioma.t("Vença o cômodo sem nenhum gato nocauteado"), "premio": PREMIO_SEM_NOCAUTE, "grupo": "Campanha"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "time_fantasiado", "nome": Idioma.t("Desfile"), "texto": Idioma.t("Vença um cômodo com todos os gatos de fantasia completa"), "premio": 5, "grupo": "Campanha"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "ato2", "nome": Idioma.t("Vizinhança segura"), "texto": Idioma.t("Vença os cinco lugares de fora da casa"), "premio": 10, "grupo": "Lado de fora"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	for f in range(Fases.TOTAL, Fases.NOME.size()):
		l.append({"id": "sem_nocaute_%d" % f, "nome": Idioma.t("%s sem um arranhão") % Idioma.t(Fases.NOME[f]), "texto": Idioma.t("Vença o lugar sem nenhum gato nocauteado"), "premio": PREMIO_SEM_NOCAUTE, "grupo": "Lado de fora"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "heranca", "nome": Idioma.t("De pai para filhote"), "texto": Idioma.t("Um gato incorpora o poder de uma fantasia"), "premio": 5, "grupo": "Lado de fora"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "schro", "nome": Idioma.t("Vivo e morto"), "texto": Idioma.t("Complete o bestiário e abra a caixa do Sótão"), "premio": 15, "grupo": "Secretos"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "atelie", "nome": Idioma.t("Feita sob medida"), "texto": Idioma.t("Complete o fichário e crie a sua fantasia no Ateliê"), "premio": 15, "grupo": "Secretos"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "marcada", "nome": Idioma.t("Roupa de guerra"), "texto": Idioma.t("Tenha uma peça com 4 marcas"), "premio": 5, "grupo": "Guarda-roupa"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "colecao_42", "nome": Idioma.t("Meio armário"), "texto": Idioma.t("Junte 50 peças diferentes"), "premio": 5, "grupo": "Guarda-roupa"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "colecao_84", "nome": Idioma.t("Armário cheio"), "texto": Idioma.t("Junte todas as %d peças") % Pecas.n_pecas_ativas(), "premio": 10, "grupo": "Guarda-roupa"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "invasao_10", "nome": Idioma.t("Casa sitiada"), "texto": Idioma.t("Passe da onda 10 na Invasão sem fim"), "premio": 5, "grupo": "Invasão"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	l.append({"id": "invasao_20", "nome": Idioma.t("Muralha de gatos"), "texto": Idioma.t("Passe da onda 20 na Invasão sem fim"), "premio": 10, "grupo": "Invasão"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
	for c in Pecas.CONJUNTO_NOME.size():
		if Pecas.retirada(c):
			continue
		l.append({"id": "fantasia_%d" % c, "nome": Idioma.t("Fantasia de %s") % Idioma.t(Pecas.CONJUNTO_NOME[c]), "texto": Idioma.t("Junte as 4 peças"), "premio": PREMIO_FANTASIA, "grupo": "Fantasias"}) # i18n-ok: "grupo" é identidade (o fichário compara); traduzido ao desenhar
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
		return e.pecas_tidas() >= Pecas.n_pecas_ativas()
	if id == "invasao_10":
		return e.melhor_invasao() >= 10
	if id == "invasao_20":
		return e.melhor_invasao() >= 20
	if id.begins_with("fantasia_"):
		return e.pecas_da_fantasia(int(id.substr(9))) >= Pecas.SLOTS
	# as demais (sem_nocaute_N, time_fantasiado) são anotadas pelo jogo quando acontecem
	return e.feitos.has(id)
