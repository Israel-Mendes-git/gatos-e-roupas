class_name Unidade
extends RefCounted
## Combatente dentro da simulação (boneco aliado ou inimigo).

enum Tipo { COMUM, SALTADOR, LADRAO, GIGANTE, GEMEO, ATIRADOR, CURANDEIRO, ESCUDEIRO, BOMBA }

var equipe: int = 0            # 0 aliado, 1 inimigo
var boneco: Boneco = null
var chefe: bool = false
var tipo: int = Tipo.COMUM
var pequeno: bool = false      # filhote de gêmeo
var linha: int = Boneco.Linha.MEIO
var heranca_cd: Array[float] = []   # relógio de cada herança (o poder incorporado dispara sozinho)
var heranca_graus: Array[int] = []   # grau de cada herança (mesma ordem)
var herancas: Array[int] = []   # passivas herdadas (Pecas.Conjunto); ver Balanco.HER_*
var atordoa_chance: float = 0.0  # herança Atordoa: chance de o golpe corpo a corpo atordoar
var gelo_chance: float = 0.0     # herança Gelo: chance de o golpe deixar o alvo lento
var postura: int = Boneco.Postura.SEGURAR   # só aliados; ver Simulacao._visao
var estrelas: int = 0
var atr: Array[int] = [0, 0, 0]  # treino do boneco (Boneco.Atr)
var casa_x: float = 0.0        # posto da linha; volta para lá sem alvo
var casa_y: float = 0.0
var fugindo: bool = false      # ladrão com a carga
var carga: int = 0
var elite: bool = false        # fantasiado: veste uma fantasia da fase e larga uma peça dela
var familia: int = 0           # Fases.Familia (só inimigos)
var rival: bool = false        # gato de gangue (3º ato): briga com o time antes de ir à torre (Disputa)
var gangue: int = -1           # gangue do rival (0..4, índice do lugar no 3º ato)
var chefe_tipo: int = -1       # Fases.Chefe; -1 se não é chefe
var parte: bool = false        # pedaço do Rei de Massinha
var pecas: Array = [null, null, null, null]
# clone invocado (Pecas.Poder.INVOCA): unidade temporária, sem roupa para drops e marcas, fora do time
var clone: bool = false
var cao: bool = false          # Casinha (módulo da torre): cão de guarda; é um clone sem dono que dura a onda toda
var clone_t: float = 0.0
var dono: Unidade = null
var pecas_visuais: Array = [null, null, null, null]   # só para desenhar o clone com a roupa do dono
var esc_vida: float = 1.0
var esc_dano: float = 1.0
var x: float = 0.0
var y: float = 0.0
var vida: float = 0.0
var vida_max: float = 0.0
var dano: float = 0.0
var intervalo: float = 1.0
var alcance: float = 30.0
var vel: float = 80.0
var armadura: float = 0.0
var reducao: float = 0.0
var esquiva: float = 0.0
var espinho: float = 0.0
var regen: float = 0.0
var provoca: bool = false
var aura_raio: float = 0.0
var aura_lentidao: float = 1.0
var tocha_dps: float = 0.0
var cura: float = 0.0
var barril_dano: float = 0.0
var coroa_bonus: float = 0.0
var furia_k: float = 0.0
var cerco: float = 0.0          # marca Cerco: fração do dano que vaza para os vizinhos do alvo
var furo: float = 0.0           # marca Furo: redução do dano de projéteis
var critico: float = 0.0        # Cartola: chance de golpe crítico
var saque: float = 0.0          # Chapéu de pirata: chance de +1 bloco por abate
var aura_dano: float = 0.0      # Chapéu pontudo: dano/s nos inimigos em volta
var cura_abate: float = 0.0     # Pele de urso: fração da vida curada por abate
var embalo_k: float = 0.0       # Casaco: +dano por abate
var embalo: float = 0.0         # acumulado nesta luta
var barreira_int: float = 0.0   # Manto: segundos entre barreiras (0 = sem manto)
var barreira_cd: float = 0.0
var regen_aura: float = 0.0     # Bandeira: vida/s nos aliados em volta
var sementes: float = 0.0       # Saco de sementes: cura nos aliados ao morrer
var cantil: float = 0.0         # Cantil: fração curada uma vez
var cantil_usado: bool = false
var roubo: float = 0.0          # Gancho: fração do dano que volta em vida
var molha: bool = false         # Regador: golpes deixam o alvo lento
var perfura: bool = false       # Varinha: ignora armadura e redução
var frio_t: float = 0.0         # molhado pelo regador
# poder especial da fantasia completa
var poder: int = -1             # Pecas.Poder; -1 sem fantasia completa
var poder_conj: int = -1        # Pecas.Conjunto que dá o poder
var poder_forca: float = 1.0    # força média das peças da fantasia
var poder_cd: float = Balanco.PODER_PRIMEIRO
var poder_pronto: bool = false  # carregado, esperando o jogador disparar (modo manual)
var atordoado_t: float = 0.0
var protegido_t: float = 0.0
var frenesi_t: float = 0.0
# estados dos poderes diversos (rodada 2026-10-14)
var preso_t: float = 0.0        # Teia: não anda (ainda ataca quem alcançar)
var marcado_t: float = 0.0      # Alvo travado: recebe mais dano de qualquer fonte
var marcado_bonus: float = 0.0
var marcado_conj: int = -1      # fantasia que marcou (só para a telemetria)
var oculto_t: float = 0.0       # Fumaça: os inimigos não o escolhem como alvo
var furor_t: float = 0.0        # Fúria: golpes em área e roubo de vida
var furor_cerco: float = 0.0
var furor_roubo: float = 0.0
var bola_t: float = 0.0         # Bola de espinhos: veloz, espinhento e imune a atordoar
var bola_vel: float = 1.0
var bola_espinho: float = 0.0
var poder_cd_menos: float = 0.0 # Alvo travado: segundos a menos na próxima recarga
var recarga_menos: float = 0.0  # kit do Jimiau: fração a menos no intervalo entre poderes
var disfarcado: bool = false     # Disfarce (Mimiau): o próximo golpe é anulado e quem bateu fica atordoado
var disfarce_atordoa: float = 0.0   # segundos de atordoamento em quem rasga o Disfarce (0 = sem a passiva)
var disfarce_rasgou_t: float = 99.0  # quanto tempo faz que rasgou (só desenho)
var disfarce_garra: bool = false     # kit completo do Mimiau: Garra Sombria e Furioso
var furioso_t: float = 0.0           # Furioso: segundos que faltam
var disfarce_rearma_t: float = 0.0   # segundos até o pano se refazer sozinho (0 = parado)
var buff_dano_t: float = 0.0    # Objeção!: dano a mais por alguns segundos
var buff_dano: float = 0.0
# lote 2 da expansão
var estrutura: bool = false     # Torre de ervilha e blocos do Construir: unidade parada com dono e prazo (também é clone)
var estr_tipo: int = 0          # Simulacao.ESTR_*
var estr_explode: float = 0.0   # bloco: dano da explosão ao cair ou expirar
var estr_conj: int = -1         # fantasia que a plantou (telemetria)
var estr_ataque: float = 0.0    # torre: dano por ervilha
var tiro_duplo: float = 0.0     # kit do Disparamiau: chance de atirar duas vezes
var sono_t: float = 0.0         # Cochilo (Miaulax): dorme, não age; acorda ao levar qualquer dano
var cochilo_t: float = 0.0      # o próprio Miaulax dormindo: não age, não atordoa, recebe menos dano e se cura
var cochilo_cura: float = 0.0   # fração da vida máxima por segundo enquanto dorme
var manteiga_t: float = 0.0     # Manteiga escorregadia: lento por mais um instante depois de sair da poça
var reviver_usado: bool = false # Reviver: uma vez por gato por luta
# lote 3 da expansão
var foco_t: float = 0.0         # Plano de ataque: este inimigo é o alvo forçado do time e leva dano a mais
var foco_bonus: float = 0.0
var foco_dono: Unidade = null   # quem fez o plano (ganha recarga se o alvo cair)
var foco_recarga: float = 0.0
var domo_t: float = 0.0         # dentro do Domo refletor: +armadura (renovado a cada passo)
var domo_arm: float = 0.0
var lobo_t: float = 0.0         # Lobo solitário (o próprio Rafamiau): provoca em volta, apanha menos e bate mais
var lobo_dur: float = 0.0
var lobo_prov: bool = false     # provoca de verdade (a herança só dá dano)
var lobo_dano: float = 0.0      # dano a mais fixo (herança)
var forcado_t: float = 0.0      # provocado pelo Lobo solitário: só ataca forcado_alvo
var forcado_alvo: Unidade = null
var esforco_t: float = 0.0      # Esforço máximo (Deadmiau): regenera e bate mais forte
var esforco_regen: float = 0.0
var esforco_usado: bool = true  # já levantou (ou não pode levantar)
var esforco_base: float = 0.0   # dano base da explosão ao levantar
var esforco_conj: int = -1
var tiro_atordoa: float = 0.0   # kit do Meon: chance de o tiro atordoar (tiro na perna)
var apara: float = 0.0          # kit do Meon: chance de aparar um golpe corpo a corpo com a faca
# lote 4 da expansão
var emboscada: float = 0.0      # kit do Miau-Noir: multiplicador do 1º golpe em cada inimigo (0 = sem kit)
var emboscou: Dictionary = {}   # inimigos que já levaram o 1º golpe (id da instância)
var execucao: float = 0.0       # kit do Super Miaujin: dano a mais em quem está abaixo de Balanco.EXECUCAO_LIMIAR
var alcance_kit: float = 0.0    # kit do Hollowmiau: alcance a mais
var alma: float = 0.0           # Hollowmiau: Alma acumulada (0 a Balanco.ALMA_MAX)
var assombrado_t: float = 0.0   # Alma Sombria: a Sombra o atravessou; fica lento
var noir_t: float = 0.0         # Modo Noir (Miau-Noir): em preto e branco, os bichos erram os golpes nele
var noir_erra: float = 0.0      # chance de o golpe/tiro errar este gato
var noir_dano: float = 1.0      # multiplicador do dano dos tiros dele
var laco: Dictionary = {}       # Laço de seda: o laço a que pertence (vazio = solto)
var carga_t: float = 0.0        # Camehamiau!: segundos que faltam para soltar o feixe (parado, vulnerável)
var carga_dur: float = 0.0
var carga_dano: float = 0.0
var capturado: bool = false     # aliado vindo de uma captura do Treinador: desenha como bicho
# lote 5 da expansão
var gigante_t: float = 0.0      # Megazord (Ranger Miau): cresce, alcança mais e não é atordoado
var escudo: float = 0.0         # escudo temporário: absorve dano antes da vida
var escudo_t: float = 0.0
var medo_t: float = 0.0         # King-Miau / Catchullu: foge para o fundo e não ataca
var radio_t: float = 0.0        # Sopro radioativo (Miauzilla): explode ao cair
var radio_dano: float = 0.0     # dano da explosão deste radioativo
var radio_gen: int = 1
var radio_cadeia: bool = true   # false na herança: só a primeira explosão
var radio_dono: Unidade = null
var radio_conj: int = -1
var resist_t: float = 0.0       # Bater no peito: recebe menos dano
var resist_k: float = 0.0
var rec_t: float = 0.0          # Recompensa (Arthur Miaurgon): este bicho tem a cabeça a prêmio
var rec_bonus: float = 0.0
var rec_cura: float = 0.0
var rec_dano: float = 0.0
var rec_recarga: float = 0.0
var rec_conj: int = -1
var estase_t: float = 0.0       # Rifle de estase (Submiautica): congelado no tempo, o dano fica retido
var estase_ret: float = 0.0
var estase_dono: Unidade = null
var estase_libera: float = 0.0
var estase_extra: float = 0.0
var estase_conj: int = -1
var louco_t: float = 0.0        # Loucura (Catchullu): ataca o inimigo mais perto, da própria equipe
var louco_dano: float = 0.0
var folego: float = 0.0         # kit da Submiautica: fração da vida com que levanta uma vez (0 = sem kit)
var folego_usado: bool = false
var susto: float = 0.0          # kit do Catchullu: chance de o golpe assustar o alvo
# aviso do poder de bicho (fantasiado e chefe): o bicho para e carrega; a tela desenha a forma
var aviso_t: float = 0.0        # segundos que faltam para soltar (0 = sem aviso)
var aviso_dur: float = 0.0
var aviso_forma: Dictionary = {}   # "circ": [Vector3(x, y, raio)], "ret": [Rect2], "lin": [[Vector2, Vector2]], "alvos": [Vector2]
# chefes
var truque_cd: float = 0.0      # chefes de fora: relógio do truque (mergulho, gás, rasante, latido)
var reforco_cd: float = 0.0     # General
var corda_t: float = 0.0        # Robô: tempo restante do estado atual
var parado: bool = false        # Robô sem corda
var fraq_fogo: float = 1.0      # multiplicadores do dano recebido
var fraq_explosao: float = 1.0
var fraq_corpo: float = 1.0
var vulneravel: float = 1.0
var furia: float = 0.0          # 0..1 visual/efetivo (só com chifres)
var bonus_dano: float = 1.0     # aura da coroa, recalculado a cada passo
var queima_t: float = 0.0
var queima_dps: float = 0.0
var queima_fonte: Unidade = null
var cura_alvo: Unidade = null   # visual: quem o avental está curando agora
var distancia: bool = false
var cd: float = 0.0
var lento: float = 1.0
var alvo: Unidade = null
var retarget: float = 0.0
var vivo: bool = true
# visual
var flash: float = 0.0
var golpe: float = 0.0
var andando: bool = false
var vx: float = -9999.0
var vy: float = 0.0
var anim: float = 0.0

func escala() -> float:
	if cao:
		return 0.55
	if chefe:
		return Balanco.CHEFE_ESCALA * Balanco.CHEFE_ESCALA_TIPO[clampi(chefe_tipo, 0, Balanco.CHEFE_ESCALA_TIPO.size() - 1)]
	if parte:
		return Balanco.MASSINHA_PARTE_ESCALA
	if pequeno:
		return Balanco.GEMEO_ESCALA
	return Balanco.TIPO_ESCALA[tipo] * (Balanco.ELITE_ESCALA if elite else 1.0) * (Balanco.PODER_MEGAZORD_ESC if gigante_t > 0.0 else 1.0)
