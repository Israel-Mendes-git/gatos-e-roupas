#!/usr/bin/env python3
"""Trilha sonora do jogo, composta e sintetizada aqui mesmo (chiptune: quadrada, triângulo e ruído).

Uso:  python ferramentas/gera_musica.py            (todas as faixas)
      python ferramentas/gera_musica.py luta1 chefe (só algumas)

Grava assets/musica/<nome>.wav (22050 Hz, mono, 16 bits) e o .import de cada uma com o loop ligado
(loop_mode Forward do começo ao fim) e compressão QOA, para o build ficar pequeno. Depois de gerar,
rode o Godot uma vez com --headless --import para ele reimportar.

Cada faixa em loop é renderizada "em círculo": a cauda das notas, o eco e o filtro que passariam do
fim voltam para o começo, então a emenda do loop é a mesma música continuando, sem clique nem buraco.
Só biblioteca padrão + numpy. Nenhuma melodia vem de outro jogo ou música: tudo foi escrito para este.

Notação das melodias (estilo tracker): cada palavra é um passo (colcheia, salvo `passo` diferente);
"C5", "F#4", "Bb3" tocam uma nota; "." segura o que vinha antes (nota ou pausa); "_" é pausa; "|" só
separa compassos para leitura (o gerador confere se cada seção tem o número certo de passos).
"""
import math
import os
import struct
import sys

import numpy as np

SR = 22050
RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "assets", "musica")
CAUDA_S = 4.0          # segundos de folga depois do fim (caudas que voltam ao começo no loop)
RMS_ALVO = 0.16        # volume médio de todas as faixas (igual entre elas); o tocador baixa mais no jogo

# ---------------------------------------------------------------------------------------- notas e acordes
LETRAS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
QUALIDADES = {
    "": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10], "maj7": [0, 4, 7, 11],
    "dim": [0, 3, 6], "aug": [0, 4, 8], "sus4": [0, 5, 7], "m6": [0, 3, 7, 9], "6": [0, 4, 7, 9],
}


def _raiz(txt):
    semi = LETRAS[txt[0].upper()]
    i = 1
    while i < len(txt) and txt[i] in "#b":
        semi += 1 if txt[i] == "#" else -1
        i += 1
    return semi, i


def midi(nome):
    semi, i = _raiz(nome)
    return 12 * (int(nome[i:]) + 1) + semi


def acorde(nome):
    """'Am7' -> (classe da fundamental 0..11, intervalos)."""
    semi, i = _raiz(nome)
    return semi % 12, QUALIDADES[nome[i:]]


def hz(m):
    return 440.0 * 2.0 ** ((np.asarray(m, dtype=np.float64) - 69.0) / 12.0)


# ---------------------------------------------------------------------------------------- osciladores
def _blep(t, dt):
    out = np.zeros_like(t)
    m = t < dt
    x = t[m] / dt[m]
    out[m] = x + x - x * x - 1.0
    m = t > 1.0 - dt
    x = (t[m] - 1.0) / dt[m]
    out[m] = x * x + x + x + 1.0
    return out


def _fase(f, fase0=0.0):
    return (np.cumsum(f) / SR + fase0) % 1.0


def quadrada(f, duty=0.5, fase0=0.0):
    """Onda de pulso com PolyBLEP (menos chiado de aliasing que a quadrada crua, mesmo timbre de chip)."""
    t = _fase(f, fase0)
    dt = np.minimum(f / SR, 0.5)
    y = np.where(t < duty, 1.0, -1.0)
    y += _blep(t, dt)
    y -= _blep((t - duty) % 1.0, dt)
    return y - (2.0 * duty - 1.0)


def triangulo(f, fase0=0.0):
    """Triângulo em 16 degraus, como o canal de baixo dos consoles de 8 bits."""
    t = _fase(f, fase0)
    y = 4.0 * np.abs(t - 0.5) - 1.0
    return np.round((y + 1.0) * 7.5) / 7.5 - 1.0


class Ruido:
    def __init__(self, semente):
        self.rng = np.random.default_rng(semente)

    def amostra(self, n, taxa=SR):
        """Ruído de chip: valor ±1 segurado em degraus (taxa baixa = ruído mais grave)."""
        k = int(n * taxa / SR) + 2
        base = self.rng.choice(np.array([-1.0, 1.0]), size=k)
        return base[(np.arange(n) * taxa / SR).astype(np.int64)]


# ---------------------------------------------------------------------------------------- envelopes
def envelope(n_lig, a, d, s, r):
    """ADSR em amostras: ataque linear, queda exponencial até o sustain, soltura linear depois de n_lig."""
    n_r = max(1, int(r * SR))
    n = n_lig + n_r
    t = np.arange(n) / SR
    na = max(1, int(a * SR))
    e = np.empty(n)
    ate = min(na, n)
    e[:ate] = np.arange(ate) / na
    if n > na:
        td = t[na:] - a
        e[na:] = s + (1.0 - s) * np.exp(-td / max(d, 1e-4))
    nivel = e[min(n_lig, n - 1)] if n_lig < n else e[-1]
    if n_lig < n:
        e[n_lig:] = nivel * (1.0 - np.arange(n - n_lig) / n_r)
    return np.clip(e, 0.0, 1.0)


# ---------------------------------------------------------------------------------------- faixa
class Faixa:
    def __init__(self, nome, bpm, compasso=4, passo=0.5, loop=True, semente=1):
        self.nome = nome
        self.bpm = bpm
        self.compasso = compasso
        self.passo = passo
        self.loop = loop
        self.ruido = Ruido(semente)
        self.rng = np.random.default_rng(semente + 100)
        self.canais = {}

    def s_beat(self):
        return 60.0 / self.bpm

    def amostra_de(self, beats):
        return int(round(beats * self.s_beat() * SR))

    def preparar(self, total_beats):
        self.total_beats = total_beats
        self.n = self.amostra_de(total_beats)
        self.cauda = int(CAUDA_S * SR)

    def canal(self, nome):
        if nome not in self.canais:
            self.canais[nome] = np.zeros(self.n + self.cauda)
        return self.canais[nome]

    def somar(self, canal, ini, y):
        buf = self.canal(canal)
        if ini >= len(buf):
            return
        fim = min(len(buf), ini + len(y))
        buf[ini:fim] += y[: fim - ini]

    # ------------------------------------------------------------ uma nota
    def nota(self, canal, beat, dur_beats, m, vol, onda="quadrada", duty=0.5, adsr=(0.005, 0.12, 0.6, 0.06),
             gate=0.92, vibrato=(0.0, 5.5, 0.18), de=None, deslize=0.0, miau=False, desafina=0.0, fase0=0.0):
        ini = self.amostra_de(beat)
        n_lig = max(1, int(self.amostra_de(dur_beats) * gate))
        env = envelope(n_lig, *adsr)
        n = len(env)
        t = np.arange(n) / SR
        semis = np.full(n, float(m) + desafina / 100.0)
        prof, taxa, atraso = vibrato
        if prof > 0.0 and n_lig / SR > atraso:
            entra = np.clip((t - atraso) / 0.15, 0.0, 1.0)
            semis += prof * entra * np.sin(2 * np.pi * taxa * t)
        if de is not None and deslize > 0.0:
            k = np.clip(t / deslize, 0.0, 1.0)
            semis += (float(de) - float(m)) * (1.0 - k) ** 2
        if miau and n_lig / SR > 0.3:
            # fim da nota escorrega para baixo, um "miau" de chip
            ini_m = n_lig * 0.62 / SR
            k = np.clip((t - ini_m) / (n_lig / SR * 0.5), 0.0, 1.0)
            semis -= 2.0 * k * k
        f = hz(semis)
        if onda == "quadrada":
            y = quadrada(f, duty, fase0)
        elif onda == "triangulo":
            y = triangulo(f, fase0)
        else:
            y = np.sin(2 * np.pi * _fase(f))
        self.somar(canal, ini, y * env * vol)

    # ------------------------------------------------------------ bateria
    def bumbo(self, beat, vol=1.0):
        n = int(0.14 * SR)
        t = np.arange(n) / SR
        f = 45.0 + 120.0 * np.exp(-t / 0.025)
        y = triangulo(f) * np.exp(-t / 0.06)
        clique = self.ruido.amostra(n, 9000) * np.exp(-t / 0.004) * 0.35
        self.somar("bateria", self.amostra_de(beat), (y + clique) * 0.9 * vol)

    def caixa(self, beat, vol=1.0):
        n = int(0.2 * SR)
        t = np.arange(n) / SR
        r = self.ruido.amostra(n, 11000) * np.exp(-t / 0.07)
        corpo = triangulo(np.full(n, 190.0) * (1.0 + 0.4 * np.exp(-t / 0.02))) * np.exp(-t / 0.035)
        self.somar("bateria", self.amostra_de(beat), (r * 0.5 + corpo * 0.45) * vol)

    def chimbal(self, beat, vol=1.0, aberto=False):
        dur = 0.16 if aberto else 0.035
        n = int((dur * 3) * SR)
        t = np.arange(n) / SR
        y = self.ruido.amostra(n, SR) * np.exp(-t / dur)
        y = y - np.concatenate(([0.0], y[:-1])) * 0.6   # tira o grave: chiado fino
        self.somar("bateria", self.amostra_de(beat), y * 0.22 * vol)

    def prato(self, beat, vol=1.0):
        n = int(1.4 * SR)
        t = np.arange(n) / SR
        y = self.ruido.amostra(n, 16000) * np.exp(-t / 0.45)
        self.somar("bateria", self.amostra_de(beat), y * 0.22 * vol)

    def tom(self, beat, vol=1.0, alto=1.0):
        n = int(0.2 * SR)
        t = np.arange(n) / SR
        f = (110.0 + 110.0 * np.exp(-t / 0.05)) * alto
        self.somar("bateria", self.amostra_de(beat), triangulo(f) * np.exp(-t / 0.08) * 0.7 * vol)

    def chiado(self, beat, dur_beats, vol):
        """Estática que cresce e some (a caixa do Schrödinger chiando)."""
        n = self.amostra_de(dur_beats)
        t = np.linspace(0.0, 1.0, n)
        y = self.ruido.amostra(n, 7000) * np.sin(np.pi * t) ** 2
        self.somar("efeito", self.amostra_de(beat), y * vol)

    # ------------------------------------------------------------ mixagem
    def mixar(self, ganhos, eco=None, filtro=True):
        y = np.zeros(self.n + self.cauda)
        for nome, buf in self.canais.items():
            g = ganhos.get(nome, 1.0)
            if eco and nome in eco:
                buf = self._eco(buf, *eco[nome])
            y += buf * g
        if self.loop:
            y = self._enrolar(y)
        if filtro:
            # passa-baixas suave (1-2-1): tira a aspereza do chip sem abafar
            if self.loop:
                y = 0.25 * np.roll(y, 1) + 0.5 * y + 0.25 * np.roll(y, -1)
            else:
                y = np.convolve(y, [0.25, 0.5, 0.25], mode="same")
        y -= np.mean(y)
        rms = math.sqrt(float(np.mean(y[: self.n] ** 2))) or 1.0
        y *= RMS_ALVO / rms
        y = 0.97 * np.tanh(y / 0.97)          # segura os picos sem estalar (ponto a ponto: não quebra o loop)
        if not self.loop:
            fim = len(y)
            while fim > 0 and abs(y[fim - 1]) < 2e-3:
                fim -= 1
            y = y[: fim + int(0.05 * SR)]
            nf = min(len(y), int(0.3 * SR))
            y[-nf:] *= np.linspace(1.0, 0.0, nf)
        return y

    def _eco(self, buf, atraso_beats, realim, mistura):
        d = self.amostra_de(atraso_beats)
        if self.loop:
            base = self._enrolar(buf)
            out = base.copy()
            for k in range(1, 6):
                out += mistura * realim ** (k - 1) * np.roll(base, d * k)
            return np.concatenate((out, np.zeros(self.cauda)))
        out = buf.copy()
        for k in range(1, 6):
            out[d * k:] += mistura * realim ** (k - 1) * buf[: len(buf) - d * k]
        return out

    def _enrolar(self, y):
        if len(y) == self.n:
            return y
        z = y[: self.n].copy()
        resto = y[self.n:]
        while len(resto) > 0:
            k = min(len(resto), self.n)
            z[:k] += resto[:k]
            resto = resto[k:]
        return z


# ---------------------------------------------------------------------------------------- composição
def ler_melodia(txt, passos_esperados, onde):
    """Tracker -> lista de (passo inicial, passos de duração, midi)."""
    fichas = [f for f in txt.replace("|", " ").split() if f]
    if len(fichas) != passos_esperados:
        raise ValueError("%s: %d passos, esperava %d" % (onde, len(fichas), passos_esperados))
    notas = []
    atual = None
    for i, f in enumerate(fichas):
        if f == ".":
            if atual is not None:
                atual[1] += 1
            continue
        if atual is not None:
            notas.append(tuple(atual))
            atual = None
        if f == "_":
            continue
        atual = [i, 1, midi(f)]
    if atual is not None:
        notas.append(tuple(atual))
    return notas


def ler_acordes(txt, compassos, onde):
    cps = [c.split() for c in txt.split("|")]
    if len(cps) != compassos:
        raise ValueError("%s: %d compassos de acordes, esperava %d" % (onde, len(cps), compassos))
    return cps


def terca_abaixo(m, escala):
    """Harmonia: duas notas abaixo na escala da faixa (uma terça diatônica)."""
    pc = m % 12
    if pc in escala:
        i = escala.index(pc)
        alvo = escala[(i - 2) % len(escala)]
        d = (pc - alvo) % 12
        return m - d
    return m - 3


BATERIAS = {
    # pistas em semicolcheias por compasso de 4 tempos: x = batida, - = batida fraca
    "rock":    {"k": "x.......x.x.....", "s": "....x.......x...", "h": "x.x.x.x.x.x.x.x."},
    "pula":    {"k": "x.....x...x.....", "s": "....x.......x...", "h": "x.x.x-x.x.x.x-x."},
    "calma":   {"k": "x.......-.......", "s": "............-...", "h": "..-...-...-...-."},
    "galope":  {"k": "x.....x.x.....x.", "s": "....x.......x...", "h": "x-x-x-x-x-x-x-x-"},
    "urgente": {"k": "x..x..x.x..x..x.", "s": "....x.......x...", "h": "x-x-x-x-x-x-x-x-"},
    "chefe":   {"k": "x...x...x...x...", "s": "....x.......x..x", "h": "x.x.x.x.x.x.x.x."},
    "quebra":  {"k": "x.........x.....", "s": "............x...", "h": "x...x...x...x..."},
    "final":   {"k": "x.......x.......", "s": "....-.......-...", "h": "-.-.-.-.-.-.-.-."},
    "nada":    {},
}


def baixo_do_estilo(estilo, acordes_compasso, prox_raiz, beats, passo_baixo=0.5):
    """Notas do baixo de um compasso a partir dos acordes. Devolve [(beat no compasso, duração, midi)]."""
    out = []
    n_ac = len(acordes_compasso)
    fatia = beats / n_ac
    for j, nome in enumerate(acordes_compasso):
        r, iv = acorde(nome)
        raiz = 40 + (r - 4) % 12          # entre E2 e D#3
        quinta = raiz + iv[2]
        terca = raiz + iv[1]
        b0 = j * fatia
        if estilo == "oito":
            k = 0.0
            while k < fatia - 1e-6:
                out.append((b0 + k, 0.5, quinta if abs(k - (fatia - 0.5)) < 1e-6 and fatia >= 2 else raiz))
                k += 0.5
        elif estilo == "oitavas":
            k = 0.0
            i = 0
            while k < fatia - 1e-6:
                out.append((b0 + k, 0.5, raiz + (12 if i % 2 else 0)))
                k += 0.5
                i += 1
        elif estilo == "galope":
            k = 0.0
            while k < fatia - 1e-6:
                out.append((b0 + k, 0.5, raiz))
                out.append((b0 + k + 0.5, 0.25, raiz + 12))
                out.append((b0 + k + 0.75, 0.25, quinta))
                k += 1.0
        elif estilo == "pedal16":
            k = 0.0
            i = 0
            while k < fatia - 1e-6:
                out.append((b0 + k, 0.25, raiz + (12 if i % 4 == 3 else 0)))
                k += 0.25
                i += 1
        elif estilo == "caminhada":
            seq = [raiz, terca, quinta]
            k = 0
            while k < fatia - 1e-6:
                if k + 1 >= fatia - 1e-6 and j == n_ac - 1 and prox_raiz is not None:
                    alvo = 40 + (prox_raiz - 4) % 12
                    nota = alvo - 1 if alvo > raiz else alvo + 1
                else:
                    nota = seq[int(k) % 3]
                out.append((b0 + k, 1.0, nota))
                k += 1
        elif estilo == "metade":
            out.append((b0, fatia / 2, raiz))
            out.append((b0 + fatia / 2, fatia / 2, quinta - 12 if quinta - 12 >= 36 else quinta))
        elif estilo == "longo":
            out.append((b0, fatia, raiz))
    return out


def tocar(fx, cfg):
    """Monta a faixa a partir da descrição `cfg` (seções, ordem, timbres)."""
    secoes = cfg["secoes"]
    ordem = cfg["ordem"].split()
    bpc = fx.compasso                  # beats por compasso
    ppc = int(round(bpc / fx.passo))   # passos por compasso
    total = 0
    for nome in ordem:
        total += secoes[nome.rstrip("+")]["compassos"]
    fx.preparar(total * bpc)
    escala = cfg.get("escala", [0, 2, 4, 5, 7, 9, 11])
    lead = cfg["lead"]
    harm = cfg.get("harm", {})
    arpe = cfg.get("arpejo", {})
    baixo = cfg.get("baixo", {})
    bat_vol = cfg.get("bateria_vol", 1.0)
    compasso0 = 0
    ultima_nota = None
    for idx, nome_ord in enumerate(ordem):
        com_harm = nome_ord.endswith("+")
        sec = secoes[nome_ord.rstrip("+")]
        nc = sec["compassos"]
        onde = "%s/%s" % (fx.nome, nome_ord)
        b_ini = compasso0 * bpc
        acs = ler_acordes(sec["acordes"], nc, onde)
        # acorde seguinte (para o baixo caminhar até ele)
        prox_sec = secoes[ordem[(idx + 1) % len(ordem)].rstrip("+")]
        prox_primeiro = prox_sec["acordes"].split("|")[0].split()[0]
        # ---- melodia
        mel = sec.get("melodia")
        if mel == "eletrons":
            _eletrons(fx, b_ini, nc * bpc, cfg)
        elif mel:
            notas = ler_melodia(mel, nc * ppc, onde)
            sobe = sec.get("oitava", 0) * 12
            for (p0, pl, m) in notas:
                m += sobe
                beat = b_ini + p0 * fx.passo
                dur = pl * fx.passo
                gate = lead.get("gate", 0.9) if pl == 1 else 0.96
                kw = dict(onda="quadrada", duty=lead["duty"], adsr=lead["adsr"], gate=gate,
                          vibrato=lead.get("vibrato", (0.0, 5.5, 0.2)) if dur >= 1.0 else (0.0, 5.5, 0.2),
                          de=ultima_nota, deslize=lead.get("deslize", 0.0), miau=lead.get("miau", False) and pl >= 4)
                if lead.get("superposicao"):
                    # dois estados ao mesmo tempo: um pouco desafinados, e às vezes o segundo "colapsa" num trítono
                    alt = m + (6 if fx.rng.random() < 0.14 else 0)
                    fx.nota("lead", beat, dur, m, lead["vol"] * 0.62, desafina=+9, **kw)
                    kw2 = dict(kw)
                    kw2["duty"] = 0.25
                    fx.nota("lead", beat, dur, alt, lead["vol"] * 0.5, desafina=-9, fase0=0.37, **kw2)
                else:
                    fx.nota("lead", beat, dur, m, lead["vol"], **kw)
                if com_harm and harm:
                    fx.nota("harm", beat, dur, terca_abaixo(m, escala), harm["vol"], onda="quadrada", duty=harm["duty"],
                            adsr=harm.get("adsr", lead["adsr"]), gate=gate, vibrato=(0.0, 5.0, 0.3))
                ultima_nota = m
        # ---- contracanto escrito (opcional)
        if sec.get("contra"):
            for (p0, pl, m) in ler_melodia(sec["contra"], nc * ppc, onde + "/contra"):
                fx.nota("harm", b_ini + p0 * fx.passo, pl * fx.passo, m, harm.get("vol", 0.1), onda="quadrada",
                        duty=harm.get("duty", 0.25), adsr=harm.get("adsr", lead["adsr"]), gate=0.85)
        # ---- baixo
        estilo_b = sec.get("baixo", baixo.get("estilo", "oito"))
        if estilo_b and not estilo_b.startswith("txt:"):
            for c in range(nc):
                prox = acs[c + 1][0] if c + 1 < nc else prox_primeiro
                prox_r = acorde(prox)[0]
                for (bb, dd, m) in baixo_do_estilo(estilo_b, acs[c], prox_r, bpc):
                    fx.nota("baixo", b_ini + c * bpc + bb, dd, m, baixo.get("vol", 0.5), onda="triangulo",
                            adsr=baixo.get("adsr", (0.003, 0.2, 0.8, 0.03)), gate=baixo.get("gate", 0.88))
        elif estilo_b:
            for (p0, pl, m) in ler_melodia(estilo_b[4:], nc * ppc, onde + "/baixo"):
                fx.nota("baixo", b_ini + p0 * fx.passo, pl * fx.passo, m, baixo.get("vol", 0.5), onda="triangulo",
                        adsr=baixo.get("adsr", (0.003, 0.2, 0.8, 0.03)), gate=0.9)
        # ---- arpejo
        estilo_a = sec.get("arpejo", arpe.get("estilo"))
        if estilo_a:
            passo_a = 0.25 if estilo_a == "16" else 0.5
            for c in range(nc):
                n_ac = len(acs[c])
                fatia = bpc / n_ac
                for j, nome in enumerate(acs[c]):
                    r, iv = acorde(nome)
                    base = arpe.get("base", 60)
                    raiz = base + (r - base) % 12
                    tons = [raiz + i for i in iv] + [raiz + 12]
                    if estilo_a == "sobe_desce":
                        tons = tons + tons[-2:0:-1]
                    k = 0.0
                    i = 0
                    while k < fatia - 1e-6:
                        fx.nota("arpejo", b_ini + c * bpc + j * fatia + k, passo_a, tons[i % len(tons)],
                                arpe.get("vol", 0.08), onda="quadrada", duty=arpe.get("duty", 0.125),
                                adsr=arpe.get("adsr", (0.002, 0.06, 0.35, 0.02)), gate=0.8)
                        k += passo_a
                        i += 1
        # ---- bateria
        bat = sec.get("bateria", cfg.get("bateria", "rock"))
        pistas = BATERIAS[bat] if isinstance(bat, str) else bat
        n16 = int(round(bpc * 4))
        for c in range(nc):
            b_c = b_ini + c * bpc
            virada = sec.get("virada", True) and c == nc - 1 and bat != "nada"
            for pista, padrao in pistas.items():
                for s in range(n16):
                    ch = padrao[s % len(padrao)]
                    if virada and s >= n16 - 4:
                        continue
                    if ch == ".":
                        continue
                    v = (1.0 if ch == "x" else 0.5) * bat_vol
                    b = b_c + s * 0.25
                    if pista == "k":
                        fx.bumbo(b, v)
                    elif pista == "s":
                        fx.caixa(b, v)
                    elif pista == "h":
                        fx.chimbal(b, v)
                    elif pista == "o":
                        fx.chimbal(b, v, aberto=True)
            if virada:
                for s in range(4):
                    b = b_c + bpc - 1.0 + s * 0.25
                    if cfg.get("virada_tom"):
                        fx.tom(b, 0.8 * bat_vol, 1.3 - s * 0.12)
                    else:
                        fx.caixa(b, (0.55 + 0.15 * s) * bat_vol)
            if c == 0 and sec.get("prato", False):
                fx.prato(b_c, bat_vol)
        if sec.get("chiado"):
            for c in range(nc):
                fx.chiado(b_ini + c * bpc, bpc, sec["chiado"])
        compasso0 += nc
    return fx


def _eletrons(fx, b_ini, beats, cfg):
    """Seção 'medida': elétrons pulando em semicolcheias na escala de tons inteiros, com escorregões."""
    tons_inteiros = [0, 2, 4, 6, 8, 10]
    k = 0.0
    ant = None
    while k < beats - 1e-6:
        if fx.rng.random() < 0.8:
            m = 72 + int(fx.rng.choice(tons_inteiros)) + 12 * int(fx.rng.integers(0, 2))
            fx.nota("lead", b_ini + k, 0.25, m, cfg["lead"]["vol"] * 0.5, duty=0.125,
                    adsr=(0.002, 0.05, 0.3, 0.02), gate=0.7, de=ant, deslize=0.03)
            ant = m
        k += 0.25


# ---------------------------------------------------------------------------------------- as faixas
MAIOR = [0, 2, 4, 5, 7, 9, 11]


def faixa_titulo():
    fx = Faixa("titulo", 132, semente=11)
    cfg = {
        "escala": MAIOR,
        "lead": {"duty": 0.25, "adsr": (0.004, 0.15, 0.65, 0.05), "vol": 0.32, "vibrato": (0.25, 5.8, 0.18)},
        "harm": {"duty": 0.125, "vol": 0.15},
        "arpejo": {"estilo": "16", "vol": 0.07, "base": 64},
        "baixo": {"estilo": "oitavas", "vol": 0.5},
        "bateria": "rock",
        "secoes": {
            "A1": {"compassos": 8, "prato": True,
                   "acordes": "C | Am | F | G | C | Am | Dm G | C",
                   "melodia": "E5 . C5 G4 C5 E5 G5 . | A5 . . G5 E5 . C5 D5 | F5 . E5 D5 C5 . A4 . | B4 . C5 D5 G4 . _ . |"
                              "E5 . C5 G4 C5 E5 G5 . | C6 . . B5 A5 . G5 E5 | F5 . D5 F5 B5 . A5 G5 | G5 . . . _ _ G4 ."},
            "A2": {"compassos": 8,
                   "acordes": "C | Am | F | G | C | Am | Dm G | C",
                   "melodia": "E5 . C5 G4 C5 E5 G5 . | A5 . . G5 E5 . C5 D5 | F5 . E5 D5 C5 . A4 . | B4 . C5 D5 G4 . _ . |"
                              "E5 . C5 G4 C5 E5 G5 . | C6 . . B5 A5 . G5 E5 | F5 . D5 F5 B5 . D6 . | C6 . . . G5 . E5 ."},
            "B": {"compassos": 8, "baixo": "caminhada", "arpejo": "sobe_desce",
                  "acordes": "F | G | Em | Am | Dm | Em | F | G7",
                  "melodia": "A5 . . . C6 . A5 . | G5 . . . D5 . . . | G5 . . . B5 . G5 . | E5 . . . . . . . |"
                             "F5 . . . A5 . F5 . | E5 . . . G5 . B5 . | A5 . C6 . A5 . F5 . | G5 . . . B5 . D6 ."},
            "C": {"compassos": 4, "bateria": "quebra", "arpejo": None,
                  "acordes": "Am | F | Dm | G",
                  "melodia": "A4 _ A4 _ C5 _ E5 _ | F5 _ E5 _ C5 _ A4 _ | D5 _ F5 _ A5 _ F5 _ | G5 _ B5 _ D6 . . ."},
        },
        "ordem": "A1 A2+ B A2 C",
    }
    tocar(fx, cfg)
    return fx.mixar({"lead": 1.0, "harm": 1.0, "arpejo": 1.0, "baixo": 1.0, "bateria": 0.9},
                    eco={"lead": (0.75, 0.35, 0.22)})


def faixa_calma():
    fx = Faixa("calma", 88, semente=12)
    cfg = {
        "escala": [5, 7, 9, 10, 0, 2, 4],
        "lead": {"duty": 0.5, "adsr": (0.02, 0.4, 0.55, 0.15), "vol": 0.26, "vibrato": (0.18, 5.0, 0.22), "gate": 0.85},
        "harm": {"duty": 0.25, "vol": 0.1, "adsr": (0.02, 0.4, 0.5, 0.15)},
        "arpejo": {"estilo": "sobe_desce", "vol": 0.055, "base": 60, "adsr": (0.004, 0.18, 0.3, 0.08)},
        "baixo": {"estilo": "caminhada", "vol": 0.45, "adsr": (0.004, 0.3, 0.7, 0.05)},
        "bateria": "calma", "bateria_vol": 0.7,
        "secoes": {
            "A": {"compassos": 8, "virada": False,
                  "acordes": "Fmaj7 | Dm7 | Gm7 | C7 | Fmaj7 | Am7 | Bbmaj7 | C7",
                  "melodia": "A4 . C5 . . . F5 . | E5 . D5 . . . A4 . | Bb4 . . D5 C5 . Bb4 . | A4 . G4 . . . . . |"
                             "A4 . C5 . F5 . A5 . | G5 . . E5 C5 . . . | D5 . F5 . A5 . G5 F5 | E5 . . . G5 . . ."},
            "B": {"compassos": 8, "virada": False,
                  "acordes": "Bbmaj7 | Am7 | Gm7 | Fmaj7 | Bbmaj7 | Am7 | Gm7 | C7",
                  "melodia": "F5 . . . D5 . . . | E5 . . . C5 . . . | D5 . Bb4 . G4 . A4 Bb4 | A4 . . . . . _ _ |"
                             "D5 . F5 . A5 . . G5 | G5 . E5 . C5 . . . | Bb4 . D5 . F5 . E5 D5 | C5 . . . . . _ _"},
            "C": {"compassos": 4, "virada": False, "bateria": "nada", "baixo": "metade",
                  "acordes": "Fmaj7 | Dm7 | Gm7 | C7",
                  "melodia": "C6 . . . A5 . . . | D6 . . . A5 . . . | Bb5 . . . G5 . F5 . | E5 . . . . . _ _"},
        },
        "ordem": "A B+ A C",
    }
    tocar(fx, cfg)
    return fx.mixar({"bateria": 0.8}, eco={"lead": (0.75, 0.4, 0.3), "arpejo": (0.5, 0.3, 0.25)})


def faixa_luta1():
    fx = Faixa("luta1", 144, semente=13)
    cfg = {
        "escala": [7, 9, 11, 0, 2, 4, 6],
        "lead": {"duty": 0.25, "adsr": (0.003, 0.1, 0.6, 0.04), "vol": 0.3, "vibrato": (0.2, 6.0, 0.15), "gate": 0.8},
        "harm": {"duty": 0.125, "vol": 0.14},
        "arpejo": {"estilo": "16", "vol": 0.06, "base": 62},
        "baixo": {"estilo": "galope", "vol": 0.48},
        "bateria": "pula",
        "secoes": {
            "A": {"compassos": 8, "prato": True,
                  "acordes": "G | G | C | D | Em | C | A7 | D",
                  "melodia": "D5 _ G5 _ B5 . A5 G5 | A5 _ B5 _ D6 . _ . | E6 . D6 C6 B5 _ A5 _ | A5 . F#5 . D5 . _ _ |"
                             "E5 _ G5 _ B5 . A5 G5 | E5 . G5 . C6 . B5 A5 | C#6 . A5 . E5 . G5 . | F#5 . A5 . D6 . _ _"},
            "B": {"compassos": 8, "baixo": "oito",
                  "acordes": "Em | C | Am | D | Em | C | Am | D7",
                  "melodia": "B4 B4 _ E5 _ G5 F#5 E5 | C5 C5 _ E5 _ G5 A5 G5 | A4 A4 _ C5 _ E5 D5 C5 | D5 . F#5 . A5 . _ _ |"
                             "B4 B4 _ E5 _ G5 F#5 E5 | G5 G5 _ E5 _ C6 B5 A5 | A5 . E5 . C6 . A5 . | F#5 . D5 . C6 . A5 ."},
            "C": {"compassos": 4, "bateria": "quebra", "arpejo": None, "baixo": "oitavas",
                  "acordes": "G | C | G | D",
                  "melodia": "_ _ _ _ _ _ _ _ | _ _ _ _ _ _ _ _ | _ _ _ _ _ _ _ _ | _ _ _ _ _ _ _ _",
                  "contra": "G5 _ _ G5 _ _ B5 _ | C6 _ _ C6 _ _ E6 _ | B5 _ _ B5 _ _ G5 _ | A5 _ F#5 _ D5 _ A4 _"},
        },
        "ordem": "A B A+ C B+ A",
    }
    tocar(fx, cfg)
    return fx.mixar({"bateria": 0.9}, eco={"lead": (0.5, 0.3, 0.18)})


def faixa_luta2():
    fx = Faixa("luta2", 152, semente=14)
    cfg = {
        "escala": [2, 4, 5, 7, 9, 11, 0],    # ré dórico
        "lead": {"duty": 0.125, "adsr": (0.003, 0.12, 0.6, 0.05), "vol": 0.32, "vibrato": (0.22, 6.2, 0.16), "gate": 0.85},
        "harm": {"duty": 0.25, "vol": 0.13},
        "arpejo": {"estilo": "16", "vol": 0.06, "base": 62},
        "baixo": {"estilo": "oitavas", "vol": 0.5},
        "bateria": "galope", "virada_tom": True,
        "secoes": {
            "A": {"compassos": 8, "prato": True,
                  "acordes": "Dm | C | G | Dm | Dm | C | Bb | A",
                  "melodia": "D5 . A4 . D5 E5 F5 . | E5 . C5 . G5 . E5 . | D5 . B4 . G4 . B4 D5 | A4 . . . D5 . F5 . |"
                             "A5 . G5 F5 E5 . D5 . | E5 . G5 . C6 . G5 . | F5 . D5 . Bb4 . D5 F5 | E5 . . . C#5 . A4 ."},
            "B": {"compassos": 8,
                  "acordes": "F | C | Dm | Bb | F | C | G | A",
                  "melodia": "C6 . . . A5 . F5 . | G5 . . . E5 . C5 . | D5 . F5 . A5 . D6 . | D6 . C6 . Bb5 . F5 . |"
                             "A5 . C6 . F6 . C6 . | E6 . D6 . C6 . G5 . | B5 . A5 . G5 . D5 . | E5 . . . A5 . C#6 ."},
            "C": {"compassos": 8, "bateria": "quebra", "baixo": "longo", "arpejo": "sobe_desce",
                  "acordes": "Dm | Dm | Bb | C | Dm | Dm | Bb | A",
                  "melodia": "D5 _ _ D5 _ _ F5 _ | E5 _ _ C5 _ _ A4 _ | Bb4 _ _ D5 _ _ F5 _ | G5 _ _ E5 _ _ C5 _ |"
                             "D5 _ _ D5 _ _ F5 _ | A5 _ _ F5 _ _ D5 _ | Bb5 _ _ F5 _ _ D5 _ | C#5 . . . E5 . A5 ."},
        },
        "ordem": "A B A+ C+ B+ A",
    }
    tocar(fx, cfg)
    return fx.mixar({"bateria": 0.9}, eco={"lead": (0.75, 0.3, 0.2)})


def faixa_luta3():
    fx = Faixa("luta3", 168, semente=15)
    cfg = {
        "escala": [0, 2, 3, 5, 7, 8, 11],    # dó menor harmônico
        "lead": {"duty": 0.25, "adsr": (0.002, 0.08, 0.65, 0.04), "vol": 0.3, "vibrato": (0.25, 6.5, 0.14), "gate": 0.78},
        "harm": {"duty": 0.5, "vol": 0.11},
        "arpejo": {"estilo": "16", "vol": 0.065, "base": 60},
        "baixo": {"estilo": "oitavas", "vol": 0.55},
        "bateria": "urgente",
        "secoes": {
            "A": {"compassos": 8, "prato": True,
                  "acordes": "Cm | Cm | Ab | Bb | Cm | Cm | Ab | G",
                  "melodia": "C5 C5 _ C5 Eb5 . G5 . | G5 . F5 Eb5 D5 . Eb5 . | C5 C5 _ C5 Eb5 . Ab5 . | G5 . F5 . D5 . Bb4 . |"
                             "C5 C5 _ C5 Eb5 . G5 . | C6 . Bb5 . G5 . Eb5 . | F5 . Ab5 . C6 . Eb6 . | D6 . . . B5 . G5 ."},
            "B": {"compassos": 8, "baixo": "galope",
                  "acordes": "Fm | Cm | Fm | G | Ab | Eb | Fm | G7",
                  "melodia": "Ab5 . . . C6 . Ab5 . | G5 . . . Eb5 . C5 . | F5 . Ab5 . C6 . F6 . | D6 . . . B5 . . . |"
                             "C6 . Ab5 . Eb5 . C6 . | Bb5 . G5 . Eb5 . G5 . | Ab5 . F5 . C5 . F5 . | G5 . B5 . D6 . F6 ."},
            "C": {"compassos": 8, "bateria": "chefe", "baixo": "pedal16",
                  "acordes": "Cm | Cm | Db | Db | Cm | Cm | Bb | G",
                  "melodia": "G5 _ G5 _ G5 _ Ab5 G5 | Eb5 . . . C5 . . . | Ab5 _ Ab5 _ Ab5 _ Bb5 Ab5 | F5 . . . Db5 . . . |"
                             "G5 _ G5 _ C6 _ Bb5 G5 | Eb5 . G5 . C6 . Eb6 . | D6 . Bb5 . F5 . D5 . | B4 . D5 . G5 . B5 ."},
        },
        "ordem": "A B A+ C A+ B+",
    }
    tocar(fx, cfg)
    return fx.mixar({"bateria": 0.95}, eco={"lead": (0.5, 0.25, 0.15)})


def faixa_chefe():
    fx = Faixa("chefe", 152, semente=16)
    cfg = {
        "escala": [4, 6, 7, 9, 11, 0, 2],    # mi menor natural
        "lead": {"duty": 0.5, "adsr": (0.003, 0.15, 0.7, 0.05), "vol": 0.27, "vibrato": (0.3, 6.5, 0.12), "gate": 0.85},
        "harm": {"duty": 0.25, "vol": 0.13},
        "arpejo": {"estilo": None},
        "baixo": {"estilo": "pedal16", "vol": 0.55},
        "bateria": "chefe", "virada_tom": True,
        "secoes": {
            "A": {"compassos": 8, "prato": True,
                  "acordes": "Em | F | Em | F | Em | C | D | B",
                  "melodia": "E5 . G5 . F#5 . E5 . | F5 . . . C5 . A4 . | E5 . G5 . B5 . Bb5 . | A5 . . . F5 . . . |"
                             "G5 . B5 . E6 . D6 . | C6 . . . G5 . E5 . | F#5 . A5 . D6 . C6 . | B5 . . . D#5 . F#5 ."},
            "B": {"compassos": 8, "baixo": "oitavas", "arpejo": "16",
                  "acordes": "Am | Em | Am | B | C | D | Em | B7",
                  "melodia": "A5 . . . C6 . B5 A5 | G5 . . . E5 . . . | A5 . C6 . E6 . D6 C6 | B5 . . . F#5 . D#5 . |"
                             "E6 . . . C6 . G5 . | F#6 . . . D6 . A5 . | G6 . F#6 . E6 . B5 . | D#6 . B5 . F#5 . A5 ."},
            "C": {"compassos": 8, "bateria": "rock", "baixo": "oito",
                  "acordes": "Em | Em | F | F | Em | Em | F | B",
                  "melodia": "E5 E5 G5 E5 A5 E5 Bb5 A5 | E5 E5 G5 E5 Bb5 A5 G5 F#5 | F5 F5 Ab5 F5 Bb5 F5 B5 Bb5 | F5 F5 Ab5 F5 C6 B5 A5 Ab5 |"
                             "E5 E5 G5 E5 A5 E5 Bb5 A5 | E5 E5 G5 E5 Bb5 A5 G5 F#5 | F5 F5 Ab5 F5 Bb5 F5 B5 Bb5 | B5 . A5 . F#5 . D#5 ."},
        },
        "ordem": "A B C A+ B+",
    }
    tocar(fx, cfg)
    return fx.mixar({"bateria": 1.0, "lead": 1.0}, eco={"lead": (0.75, 0.3, 0.18)})


def faixa_schro():
    # 7/8 (2+2+3 colcheias): o compasso nunca "fecha" onde o ouvido espera
    fx = Faixa("schro", 112, compasso=3.5, semente=17)
    bat_78 = {"k": "x...x.......x.", "s": "........x.....", "h": "..x...x.x...x.", "o": ".............x"}
    bat_78b = {"k": "x.....x.......", "s": "....x.....x...", "h": "x.x.x.x.x.x.x."}
    cfg = {
        "escala": [0, 2, 4, 6, 8, 10],
        "lead": {"duty": 0.5, "adsr": (0.01, 0.25, 0.6, 0.12), "vol": 0.3, "vibrato": (0.35, 4.2, 0.2), "gate": 0.9,
                 "deslize": 0.06, "miau": True, "superposicao": True},
        "harm": {"duty": 0.125, "vol": 0.1},
        "arpejo": {"estilo": "sobe_desce", "vol": 0.06, "base": 60, "duty": 0.125},
        "baixo": {"vol": 0.5},
        "bateria": bat_78, "bateria_vol": 0.8,
        "secoes": {
            "A": {"compassos": 8, "virada": False, "chiado": 0.0,
                  "acordes": "Caug | Daug | Caug | Caug | Gaug | Faug | Eaug | Daug",
                  "baixo": "txt:C3 . G#2 . C3 D3 E3 | D3 . A#2 . D3 E3 F#3 | C3 . G#2 . C3 D3 E3 | C3 . . . E3 . G#3 |"
                           "B2 . G2 . B2 C#3 D#3 | C#3 . A2 . C#3 D#3 F3 | E3 . C3 . G#2 . E2 | D3 . F#3 . A#3 . D4",
                  "melodia": "C5 . E5 . G#5 . . | F#5 . D5 . A#4 . . | C5 D5 E5 F#5 G#5 . A#5 | C6 . . . . _ _ |"
                             "B5 . G5 . D#5 . . | C#5 . F5 . A5 . . | G#5 F#5 E5 D5 C5 . . | D5 . . . . _ _"},
            "B": {"compassos": 8, "virada": False, "bateria": bat_78b,
                  "acordes": "C | Cm | Ab | Abm | F | Fm | G | G7",
                  "baixo": "metade",
                  "melodia": "E5 . G5 . C6 . . | Eb5 . G5 . C6 . . | C5 . Eb5 . Ab5 . . | B4 . Eb5 . Ab5 . . |"
                             "A5 . . C6 . A5 . | Ab5 . . C6 . Ab5 . | G5 . B5 . D6 . F6 | E6 . . . . _ _"},
            "C": {"compassos": 4, "virada": False, "bateria": "nada", "chiado": 0.05, "arpejo": None,
                  "acordes": "Caug | Caug | Daug | Daug", "baixo": "longo",
                  "melodia": "eletrons"},
        },
        "ordem": "A B A+ C B+",
    }
    tocar(fx, cfg)
    # um fio de estática por baixo de tudo, que respira devagar (a caixa nunca fica quieta)
    n = fx.n
    t = np.arange(n) / SR
    voltas = max(1, int(round(fx.n / SR / 8.0)))
    resp = 0.5 + 0.5 * np.sin(2 * np.pi * voltas * t / (fx.n / SR))
    fx.somar("efeito", 0, fx.ruido.amostra(n, 5000) * 0.018 * resp)
    return fx.mixar({"efeito": 1.0, "bateria": 0.85}, eco={"lead": (0.5, 0.45, 0.3), "arpejo": (0.75, 0.4, 0.3)})


def faixa_final():
    fx = Faixa("final", 100, semente=18)
    cfg = {
        "escala": [10, 0, 2, 3, 5, 7, 9],
        "lead": {"duty": 0.5, "adsr": (0.01, 0.3, 0.6, 0.12), "vol": 0.28, "vibrato": (0.2, 5.2, 0.2), "gate": 0.88},
        "harm": {"duty": 0.25, "vol": 0.12, "adsr": (0.01, 0.3, 0.55, 0.12)},
        "arpejo": {"estilo": "sobe_desce", "vol": 0.055, "base": 58, "adsr": (0.003, 0.15, 0.3, 0.06)},
        "baixo": {"estilo": "caminhada", "vol": 0.45},
        "bateria": "final", "bateria_vol": 0.85,
        "secoes": {
            "A": {"compassos": 8, "prato": True,
                  "acordes": "Bb | Gm | Eb | F | Bb | Gm | Cm F | Bb",
                  "melodia": "D5 . Bb4 F4 Bb4 D5 F5 . | G5 . . F5 D5 . Bb4 C5 | Eb5 . D5 C5 Bb4 . G4 . | A4 . Bb4 C5 F4 . _ . |"
                             "D5 . Bb4 F4 Bb4 D5 F5 . | Bb5 . . A5 G5 . F5 D5 | Eb5 . C5 Eb5 A5 . G5 F5 | Bb5 . . . F5 . D5 ."},
            "B": {"compassos": 8,
                  "acordes": "Eb | F | Dm | Gm | Cm | F | Eb | F",
                  "melodia": "G5 . . . Bb5 . G5 . | F5 . . . C5 . . . | F5 . . . A5 . F5 . | D5 . . . . . . . |"
                             "Eb5 . . . G5 . Eb5 . | C5 . . . F5 . A5 . | G5 . Bb5 . G5 . Eb5 . | F5 . . . A5 . C6 ."},
        },
        "ordem": "A B A+ B+",
    }
    tocar(fx, cfg)
    return fx.mixar({"bateria": 0.8}, eco={"lead": (0.75, 0.4, 0.28), "arpejo": (0.5, 0.3, 0.2)})


def faixa_vitoria():
    fx = Faixa("vitoria", 150, passo=0.25, loop=False, semente=19)
    cfg = {
        "escala": MAIOR,
        "lead": {"duty": 0.25, "adsr": (0.003, 0.12, 0.7, 0.2), "vol": 0.32, "vibrato": (0.3, 6.0, 0.15), "gate": 0.9},
        "harm": {"duty": 0.125, "vol": 0.16},
        "baixo": {"vol": 0.5},
        "secoes": {
            "A": {"compassos": 2, "virada": False, "prato": True,
                  "bateria": {"k": "x.......x.......", "s": "............xxxx"},
                  "acordes": "C | G",
                  "baixo": "txt:C3 . . . . . . . G2 . . . . . . . | G2 . . . . . . . G2 . . . B2 . D3 .",
                  "melodia": "G4 . C5 . E5 . G5 . . . E5 . G5 . . . | A5 . . . C6 . A5 . B5 . . . D6 . . ."},
            "B": {"compassos": 1, "virada": False, "prato": True, "bateria": {"k": "x..............."},
                  "acordes": "C", "baixo": "txt:C3 . . . . . . . . . . . . . . .",
                  "melodia": "C6 . . . . . . . . . . . . . _ _"},
        },
        "ordem": "A+ B+",
    }
    tocar(fx, cfg)
    return fx.mixar({}, eco={"lead": (0.375, 0.3, 0.2)})


def faixa_derrota():
    fx = Faixa("derrota", 100, loop=False, semente=20)
    cfg = {
        "escala": [9, 11, 0, 2, 4, 5, 8],
        "lead": {"duty": 0.5, "adsr": (0.01, 0.3, 0.6, 0.25), "vol": 0.3, "vibrato": (0.35, 5.0, 0.15), "gate": 0.92,
                 "miau": True, "deslize": 0.05},
        "harm": {"duty": 0.25, "vol": 0.12},
        "baixo": {"vol": 0.45},
        "secoes": {
            "A": {"compassos": 2, "virada": False, "bateria": {"k": "x...............", "s": "........-......."},
                  "acordes": "Am | E Am",
                  "baixo": "txt:A2 . . . . . . . | E2 . . . A2 . . .",
                  "melodia": "E5 . . A4 C5 . B4 . | G#4 . . . A4 . . ."},
        },
        "ordem": "A+",
    }
    tocar(fx, cfg)
    return fx.mixar({}, eco={"lead": (0.75, 0.3, 0.2)})


FAIXAS = {
    "titulo": (faixa_titulo, True),
    "calma": (faixa_calma, True),
    "luta1": (faixa_luta1, True),
    "luta2": (faixa_luta2, True),
    "luta3": (faixa_luta3, True),
    "chefe": (faixa_chefe, True),
    "schro": (faixa_schro, True),
    "final": (faixa_final, True),
    "vitoria": (faixa_vitoria, False),
    "derrota": (faixa_derrota, False),
}


# ---------------------------------------------------------------------------------------- arquivos
def gravar_wav(caminho, y, loop):
    dados = np.clip(np.round(y * 32767.0), -32768, 32767).astype("<i2").tobytes()
    n = len(y)
    fmt = struct.pack("<HHIIHH", 1, 1, SR, SR * 2, 2, 16)
    blocos = b"fmt " + struct.pack("<I", len(fmt)) + fmt
    blocos += b"data" + struct.pack("<I", len(dados)) + dados
    if loop:
        # bloco 'smpl' com o loop do começo ao fim (o .import também liga o loop, isto é só para outros programas)
        smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, n - 1, 0, 0)
        blocos += b"smpl" + struct.pack("<I", len(smpl)) + smpl
    with open(caminho, "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", 4 + len(blocos)) + b"WAVE" + blocos)


PARAMS_IMPORT = [
    ("force/8_bit", "false"), ("force/mono", "false"), ("force/max_rate", "false"), ("force/max_rate_hz", "44100"),
    ("edit/trim", "false"), ("edit/normalize", "false"),
]


def gravar_import(caminho_wav, n, loop):
    """Liga o loop (Forward, do começo ao fim) e a compressão QOA no .import, preservando o uid se já houver."""
    imp = caminho_wav + ".import"
    params = dict(PARAMS_IMPORT)
    params["edit/loop_mode"] = "2" if loop else "1"
    params["edit/loop_begin"] = "0"
    params["edit/loop_end"] = str(n) if loop else "-1"
    params["compress/mode"] = "2"
    if os.path.exists(imp):
        linhas = open(imp, encoding="utf-8").read().split("\n")
        fora = []
        em_params = False
        vistos = set()
        for ln in linhas:
            if ln.strip() == "[params]":
                em_params = True
                fora.append(ln)
                continue
            if em_params and "=" in ln:
                k = ln.split("=", 1)[0]
                if k in params:
                    ln = "%s=%s" % (k, params[k])
                    vistos.add(k)
            fora.append(ln)
        while fora and fora[-1] == "":
            fora.pop()
        for k, v in params.items():
            if k not in vistos:
                fora.append("%s=%s" % (k, v))
        open(imp, "w", encoding="utf-8", newline="\n").write("\n".join(fora) + "\n")
        return
    rel = "res://assets/musica/" + os.path.basename(caminho_wav)
    txt = '[remap]\n\nimporter="wav"\ntype="AudioStreamWAV"\n\n[deps]\n\nsource_file="%s"\n\n[params]\n\n' % rel
    txt += "".join("%s=%s\n" % (k, v) for k, v in params.items())
    open(imp, "w", encoding="utf-8", newline="\n").write(txt)


def main():
    os.makedirs(SAIDA, exist_ok=True)
    nomes = sys.argv[1:] or list(FAIXAS)
    for nome in nomes:
        func, loop = FAIXAS[nome]
        y = func()
        caminho = os.path.join(SAIDA, nome + ".wav")
        gravar_wav(caminho, y, loop)
        gravar_import(caminho, len(y), loop)
        print("%-8s %6.1f s  %5.0f KB  pico %.2f  %s" % (nome, len(y) / SR, os.path.getsize(caminho) / 1024.0,
                                                        float(np.max(np.abs(y))), "loop" if loop else "uma vez"))


if __name__ == "__main__":
    main()
