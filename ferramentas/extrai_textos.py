"""Extrator de textos para tradução (só biblioteca padrão).

Uso (da raiz do projeto):
    python -I ferramentas/extrai_textos.py             acrescenta ao CSV as chaves novas achadas em Idioma.t("...")
    python -I ferramentas/extrai_textos.py --seco      só mostra o que faria, sem gravar
    python -I ferramentas/extrai_textos.py --faltando  lista os literais que PARECEM texto de jogador e ainda
                                                       NÃO estão em Idioma.t, por arquivo e linha
    ... --faltando --resumo   só a contagem por arquivo
    ... --faltando --tudo     inclui também palavras soltas começadas em maiúscula (menos certeza)

O CSV (idiomas/textos.csv) é o formato de tradução do Godot: coluna "keys" (o texto em português), uma coluna por
idioma ("en") e colunas "_..." (comentários, ignoradas pelo importador). As traduções já preenchidas e a ordem
das linhas são preservadas; as chaves novas entram no fim. Chaves que sumiram do código NÃO são apagadas (só
listadas como órfãs). Depois de mexer no CSV, rode o Godot com --headless --import para regerar a tradução.
"""
import csv
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CSV_PADRAO = RAIZ / "idiomas" / "textos.csv"
PASTA_SCRIPTS = RAIZ / "scripts"

# Chamadas cujos argumentos de texto NÃO são para o jogador (caminhos, ações, nomes de nós, depuração...).
IGNORA_CHAMADAS = {
    "preload", "load", "print", "prints", "printt", "printerr", "print_rich", "push_warning", "push_error",
    "assert", "get_node", "get_node_or_null", "has_node", "find_child", "add_user_signal", "connect", "emit_signal",
    "has_signal", "is_action_pressed", "is_action_just_pressed", "is_action_just_released", "is_action", "get_action_strength",
    "add_to_group", "is_in_group", "call", "call_deferred", "has_method", "get_meta", "set_meta", "has_meta",
    "begins_with", "ends_with", "export_group", "export_subgroup", "export_category", "export_file", "export_dir",
    "export_enum", "export_multiline", "export_range", "icon", "tocar", "tocar_um", "reg", "file_exists", "open",
    "get_value", "set_value", "has_section", "has_section_key", "get_section_keys", "get_setting", "get_ticks_msec",
    "find", "split", "replace", "trim_prefix", "trim_suffix", "strip_edges", "format", "contains", "count", "rfind",
    "load_threaded_request", "get", "has", "erase", "set", "get_or_add", "StringName", "NodePath",
    "compile", "to_lower", "to_upper", "sha256_text", "md5_text", "str_to_var", "set_script", "new_method",
}

# Dessas, só o PRIMEIRO argumento é chave/padrão (o resto, ex.: d.get("nao", "Cancelar"), pode ser texto de jogador).
SO_PRIMEIRO_ARG = {"get", "has", "set", "erase", "get_or_add", "find", "split", "replace", "count", "contains", "format",
                   "get_value", "set_value", "rfind", "trim_prefix", "trim_suffix", "begins_with", "ends_with"}

ID = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
ESCAPES = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "'": "'", "\\": "\\", "a": "\a", "b": "\b", "f": "\f", "v": "\v"}


def decodificar(cru, bruto):
    """Resolve as sequências de escape de um literal do GDScript."""
    if bruto or "\\" not in cru:
        return cru
    saida = []
    i = 0
    while i < len(cru):
        c = cru[i]
        if c == "\\" and i + 1 < len(cru):
            n = cru[i + 1]
            if n in ESCAPES:
                saida.append(ESCAPES[n])
                i += 2
                continue
            if n in "uU":
                tam = 4 if n == "u" else 6
                hexa = cru[i + 2:i + 2 + tam]
                try:
                    saida.append(chr(int(hexa, 16)))
                    i += 2 + tam
                    continue
                except ValueError:
                    pass
        saida.append(c)
        i += 1
    return "".join(saida)


def tokenizar(fonte):
    """Devolve tokens (tipo, valor, linha, extra): 'str' (extra = prefixo & ou ^), 'id', 'op' e 'num'."""
    toks = []
    i, n, linha = 0, len(fonte), 1
    while i < n:
        c = fonte[i]
        if c == "\n":
            linha += 1
            i += 1
        elif c in " \t\r":
            i += 1
        elif c == "#":
            while i < n and fonte[i] != "\n":
                i += 1
        elif c in "\"'":
            bruto = i > 0 and fonte[i - 1] == "r" and not (i > 1 and (fonte[i - 2].isalnum() or fonte[i - 2] == "_"))
            prefixo = fonte[i - 1] if i > 0 and fonte[i - 1] in "&^" else ""
            triplo = fonte.startswith(c * 3, i)
            ini_linha = linha
            i += 3 if triplo else 1
            ini = i
            while i < n:
                if fonte[i] == "\\" and not bruto:
                    i += 2
                    continue
                if fonte[i] == "\n":
                    linha += 1
                    if not triplo:
                        break   # literal quebrado: não deveria existir
                if triplo and fonte.startswith(c * 3, i):
                    break
                if not triplo and fonte[i] == c:
                    break
                i += 1
            cru = fonte[ini:i]
            i += 3 if triplo else 1
            toks.append(("str", decodificar(cru, bruto), ini_linha, prefixo))
        elif c.isalpha() or c == "_":
            m = ID.match(fonte, i)
            toks.append(("id", m.group(), linha, ""))
            i = m.end()
        elif c.isdigit():
            j = i
            while j < n and (fonte[j].isalnum() or fonte[j] in "._"):
                j += 1
            toks.append(("num", fonte[i:j], linha, ""))
            i = j
        else:
            dois = fonte[i:i + 2]
            if dois in ("==", "!=", "<=", ">=", "+=", "-=", "*=", "/=", "%=", "->", ":=", "&&", "||", "<<", ">>", "**"):
                toks.append(("op", dois, linha, ""))
                i += 2
            else:
                toks.append(("op", c, linha, ""))
                i += 1
    return toks


def analisar(toks):
    """Percorre os tokens. Devolve (chaves, avisos, dinamicas, soltos):
    chaves = [(texto, linha)] dos Idioma.t("literal"); avisos = [(linha, motivo)] de Idioma.t mal formados;
    dinamicas = nº de Idioma.t(expressão); soltos = literais fora de Idioma.t (com o contexto, para a heurística)."""
    chaves, avisos, soltos = [], [], []
    dinamicas = 0
    pilha = []   # (abre, nome_da_chamada, é_idioma_t)
    vazio = ("", "", 0, "")
    for k, (tipo, val, linha, extra) in enumerate(toks):
        if tipo == "op" and val in ("(", "[", "{"):
            nome, eh_t = "", False
            if val == "(" and k > 0 and toks[k - 1][0] == "id":
                nome = toks[k - 1][1]
                eh_t = nome == "t" and k > 2 and toks[k - 2][1] == "." and toks[k - 3][1] == "Idioma"
            pilha.append((val, nome, eh_t))
        elif tipo == "op" and val in (")", "]", "}"):
            if pilha:
                pilha.pop()
        elif tipo == "str" and not extra:
            prox = toks[k + 1] if k + 1 < len(toks) else vazio
            ant = toks[k - 1] if k > 0 else vazio
            topo = pilha[-1] if pilha else ("", "", False)
            if topo[2] and ant[1] == "(":
                if prox[1] == ")":
                    chaves.append((val, linha))
                elif prox[1] == "+":
                    avisos.append((linha, "concatenação dentro de Idioma.t: monte a frase inteira com marcadores %s/%d"))
                else:
                    avisos.append((linha, "Idioma.t com mais do que um literal simples"))
                continue
            if topo[2]:
                avisos.append((linha, "literal no meio de uma expressão dentro de Idioma.t"))
                continue
            soltos.append((val, linha, topo[1], topo[0], ant, prox))
        elif tipo == "id" and val == "t" and k > 2 and toks[k - 1][1] == "." and toks[k - 2][1] == "Idioma":
            if k + 2 < len(toks) and toks[k + 1][1] == "(" and toks[k + 2][0] != "str":
                dinamicas += 1
    return chaves, avisos, dinamicas, soltos


ACENTO = re.compile(r"[À-ÖØ-öø-ÿ]")
TRES_LETRAS = re.compile(r"[A-Za-zÀ-ÖØ-öø-ÿ]{3,}")
PALAVRA_SOLTA = re.compile(r"^[A-ZÀ-Ý][a-zà-ÿ]{2,}$")


def parece_texto(val, ant, prox, topo_nome, tudo):
    """Heurística: este literal parece texto para o jogador?"""
    if not val.strip() or "://" in val or val.startswith(("res:", "user:")):
        return False
    if not TRES_LETRAS.search(val):
        return False
    if prox[1] == ":" and ant[1] != "?":          # chave de dicionário / padrão de match
        return False
    if ant[1] == "[" and prox[1] == "]":          # d["chave"]
        return False
    if ant[1] in ("==", "!=") or prox[1] in ("==", "!=") or ant[1] == "in" or prox[1] == "in":
        return False                              # comparação de identidade
    if topo_nome in IGNORA_CHAMADAS and not (topo_nome in SO_PRIMEIRO_ARG and ant[1] != "("):
        return False
    if val.startswith(("%", "#", "@", ".", "/")) or val.endswith((".gd", ".png", ".tscn", ".ogg", ".wav", ".cfg", ".tres")):
        return False
    if "_" in val and " " not in val:
        return False
    if ACENTO.search(val) or (" " in val.strip() and len(TRES_LETRAS.findall(val)) >= 2):
        return True
    return bool(tudo and PALAVRA_SOLTA.match(val))


def linhas_de_tabela(linhas):
    """Números de linha (1 = primeira) das declarações const/var de coluna 0: as tabelas de dados, que o
    extrai_dados.gd cobre (traduz-se onde a tabela é desenhada, nunca a tabela)."""
    dentro, conj = False, set()
    for n, l in enumerate(linhas, 1):
        if l.startswith(("const ", "static var ", "var ", "@export var ", "static func _")) and not l.startswith("static func"):
            dentro = True
        elif l and l[0] not in " 	]})#":
            dentro = False
        if dentro:
            conj.add(n)
    return conj


def varrer():
    """Lê todos os .gd de scripts/. Devolve {caminho_relativo: (chaves, avisos, dinamicas, soltos, linhas_tabela, linhas_fonte)}."""
    res = {}
    for arq in sorted(PASTA_SCRIPTS.rglob("*.gd")):
        rel = arq.relative_to(RAIZ).as_posix()
        fonte = arq.read_text(encoding="utf-8")
        linhas = fonte.split(chr(10))
        res[rel] = analisar(tokenizar(fonte)) + (linhas_de_tabela(linhas), linhas)
    return res


def ler_csv(caminho):
    if not caminho.exists():
        return ["keys", "en", "_onde"], []
    with open(caminho, encoding="utf-8", newline="") as f:
        linhas = list(csv.reader(f))
    return linhas[0], linhas[1:]


def gravar_csv(caminho, cab, linhas):
    caminho.parent.mkdir(parents=True, exist_ok=True)
    with open(caminho, "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(cab)
        w.writerows(linhas)


def extrair(args):
    res = varrer()
    cab, linhas = ler_csv(CSV_PADRAO)
    existentes = {l[0] for l in linhas if l}
    col_onde = cab.index("_onde") if "_onde" in cab else -1
    achadas, origem = [], {}
    dinamicas = 0
    for rel, (chaves, avisos, din, _s, _t, _l) in res.items():
        dinamicas += din
        for txt, _linha in chaves:
            if txt not in origem:
                origem[txt] = rel.replace("scripts/", "", 1)
                achadas.append(txt)
        for linha, motivo in avisos:
            print("AVISO %s:%d: %s" % (rel, linha, motivo))
    novas = [t for t in achadas if t not in existentes]
    orfas = [l[0] for l in linhas if l and l[0] not in origem
             and not (col_onde >= 0 and len(l) > col_onde and l[col_onde].startswith("dados:"))]
    for t in novas:
        nova = [t] + [""] * (len(cab) - 1)
        if col_onde >= 0:
            nova[col_onde] = origem[t]
        linhas.append(nova)
    sem_traducao = sum(1 for l in linhas if len(l) > 1 and not l[1])
    print("Idioma.t com literal: %d chaves distintas em %d arquivos (+ %d chamadas com expressão) | novas: %d | já no CSV: %d | "
          "órfãs: %d | linhas do CSV sem 'en': %d"
          % (len(achadas), sum(1 for v in res.values() if v[0]), dinamicas, len(novas), len(achadas) - len(novas), len(orfas), sem_traducao))
    if orfas and not args.resumo:
        for t in orfas[:20]:
            print("  órfã:", repr(t))
    if novas and not args.seco:
        gravar_csv(CSV_PADRAO, cab, linhas)
        print("CSV atualizado:", CSV_PADRAO.relative_to(RAIZ).as_posix())
        print("Lembrete: godot --headless --import regera a tradução importada.")
    return 0


def faltando(args):
    res = varrer()
    total, em_tabelas = 0, 0
    por_arquivo = []
    for rel, (_c, _a, _d, soltos, tabela, fonte) in res.items():
        achados = []
        for v, l, nome, _abre, ant, prox in soltos:
            if not parece_texto(v, ant, prox, nome, args.tudo) or "i18n-ok" in fonte[l - 1]:
                continue
            if l in tabela:
                em_tabelas += 1
            else:
                achados.append((l, v))
        if achados:
            por_arquivo.append((rel, achados))
            total += len(achados)
    if not args.resumo:
        for rel, achados in por_arquivo:
            print("== %s (%d)" % (rel, len(achados)))
            for linha, v in achados:
                print("  %s:%d: %s" % (rel, linha, repr(v) if "\n" in v else '"%s"' % v))
    print("-- literais ainda fora de Idioma.t, por arquivo:")
    for rel, achados in sorted(por_arquivo, key=lambda x: -len(x[1])):
        print("%6d  %s" % (len(achados), rel))
    print("%6d  TOTAL em %d arquivos" % (total, len(por_arquivo)))
    print("%6d  literais em tabelas const/var (não contados acima: ferramentas/extrai_dados.gd cobre; traduza onde a tabela é desenhada)" % em_tabelas)
    return 0


def main():
    import argparse
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--faltando", action="store_true", help="lista literais de texto que não estão em Idioma.t")
    ap.add_argument("--resumo", action="store_true", help="com --faltando: só a contagem por arquivo")
    ap.add_argument("--tudo", action="store_true", help="com --faltando: inclui palavras soltas em maiúscula")
    ap.add_argument("--seco", action="store_true", help="não grava o CSV")
    args = ap.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    return faltando(args) if args.faltando else extrair(args)


if __name__ == "__main__":
    sys.exit(main())
