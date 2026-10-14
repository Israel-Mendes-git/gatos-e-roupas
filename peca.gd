class_name Peca
extends RefCounted
## Uma peça de roupa. É ELA quem tem nível, abates e histórico (o herói é a roupa).

var tipo: int = 0
var nivel: int = 0
var raridade: int = 0  # Pecas.Raridade: mais efeito e mais espaço para marcas
var abates: int = 0   # histórico total
var prog: int = 0     # abates desde o último nível
var raridade_subiu: bool = false   # só durante Estado.reforcar_fantasia
var nova: bool = false  # acabou de sair de um inimigo ou de ganhar marca na última luta
var marcas: Array[int] = []  # Pecas.Marca; a morte do portador marca a peça para sempre

func _init(t: int = 0, n: int = 0, r: int = 0) -> void:
	tipo = t
	nivel = n
	raridade = r

func slot() -> int:
	return Pecas.SLOT[tipo]

func conjunto() -> int:
	return Pecas.CONJUNTO_DE[tipo]

## Multiplicador do efeito numérico (nível e raridade).
func poder() -> float:
	return (1.0 + Balanco.BONUS_NIVEL * nivel) * Balanco.RARIDADE_PODER[raridade] * Pecas.MOLDE_PODER[tipo]

## Tipo cujo efeito esta peça usa.
func molde() -> int:
	return Pecas.MOLDE[tipo]

## Nível usado pelos efeitos em porcentagem (a raridade conta como nível a mais).
func nivel_efetivo() -> int:
	return nivel + raridade

func marcas_max() -> int:
	return Balanco.RARIDADE_MARCAS[raridade]

## Adiciona uma marca. Devolve false se a peça já está no teto (marca ignorada).
func marcar(m: int) -> bool:
	if marcas.size() >= marcas_max():
		return false
	marcas.append(m)
	return true

func contar_marca(m: int) -> int:
	return marcas.count(m)

func abates_para_subir() -> int:
	return Balanco.ABATES_BASE + nivel

## Registra um abate. Devolve true se subiu de nível.
func creditar_abate() -> bool:
	abates += 1
	if nivel >= Balanco.NIVEL_MAX:
		return false
	prog += 1
	if prog >= abates_para_subir():
		prog = 0
		nivel += 1
		return true
	return false

func para_dados() -> Dictionary:
	return {"tipo": tipo, "nivel": nivel, "raridade": raridade, "abates": abates, "prog": prog, "marcas": marcas.duplicate()}

static func de_dados(d: Dictionary) -> Peca:
	var p := Peca.new(int(d.get("tipo", 0)), clampi(int(d.get("nivel", 0)), 0, Balanco.NIVEL_MAX), clampi(int(d.get("raridade", 0)), 0, Balanco.RARIDADE_PODER.size() - 1))
	p.abates = int(d.get("abates", 0))
	p.prog = int(d.get("prog", 0))
	for m in d.get("marcas", []):
		p.marcas.append(int(m))
	return p
