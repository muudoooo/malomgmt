# -*- coding: utf-8 -*-
"""Busca en Deezer las obras de UMPG que no estan en el catalogo, para recuperar
su ISRC y saber de que release son.

Por que Deezer y no Spotify: su API publica devuelve el ISRC de cada track sin
autenticacion. Spotify y Apple exigen credenciales. Ademas la app ya usa Deezer
para las portadas, asi que es una fuente que ya esta en casa.

NO escribe nada en la base. Deja un TSV para revisar a mano:
    herramientas/umpg/isrc_encontrados.tsv

Uso:  python3 umpg_buscar_isrc.py
"""

import io, os, csv, glob, json, time, re, difflib, unicodedata, urllib.parse, urllib.request

AQUI = os.path.dirname(os.path.abspath(__file__))
MAPEO = os.path.join(AQUI, "mapeo_umpg.tsv")
SALIDA = os.path.join(AQUI, "isrc_encontrados.tsv")
RAIZ = os.path.expanduser("~/MALO/UMPG PUBLISHING")

# los nombres con los que publican, para reconocer al artista en Deezer
NUESTROS = ["8belial", "yyy891", "roomtrash6", "cybernene", "aft3rlife",
            "johnnyfuu", "el wiwi", "virtual flavor", "disobey", "nusar3000"]


def norm(s):
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    s = re.sub(r"\(.*?\)", " ", s)
    s = re.sub(r"[^a-z0-9 ]", " ", s)
    return re.sub(r"\s+", " ", s).strip()


# El titulo que UMPG cataloga NO es el que se publico. Los tres casos que se han
# visto de verdad (1 sep 2026), y que antes se descartaban en silencio:
#
#   «SIMON, EL»       se publico como «el simón»          articulo al final
#   «GLOCK CHAMPIONS» se publico como «GlockChampions»    sin espacio
#   «SOUTSHIDE»       se publico como «Southside»         una letra transpuesta
#
# Por eso la comparacion es por niveles y no por igualdad.

ARTICULOS = ("el", "la", "los", "las", "un", "una")


def desinvierte(s):
    """'SIMON, EL' -> 'EL SIMON'. UMPG cataloga con el articulo al final."""
    if "," in s:
        izq, der = s.rsplit(",", 1)
        if der.strip().lower() in ARTICULOS:
            return "%s %s" % (der.strip(), izq.strip())
    return s


def variantes(titulo):
    """El titulo tal cual y, si aplica, desinvertido. Para buscar por las dos formas."""
    v = [titulo]
    d = desinvierte(titulo)
    if norm(d) != norm(titulo):
        v.append(d)
    return v


def sinesp(s):
    return s.replace(" ", "")


def casa_titulo(umpg, deezer_tit):
    """Nivel de coincidencia entre el titulo de UMPG y el de Deezer.

    3 = identico (o identico ignorando espacios)
    2 = uno contiene al otro
    1 = casi igual, una o dos letras de diferencia
    0 = nada que ver
    """
    a, b = norm(umpg), norm(deezer_tit)
    if not a or not b:
        return 0
    if a == b or sinesp(a) == sinesp(b):
        return 3
    if a in b or b in a or sinesp(a) in sinesp(b) or sinesp(b) in sinesp(a):
        return 2
    if difflib.SequenceMatcher(None, sinesp(a), sinesp(b)).ratio() >= 0.88:
        return 1
    return 0


def deezer(url):
    try:
        with urllib.request.urlopen(url, timeout=15) as r:
            return json.loads(r.read().decode("utf-8"))
    except Exception:
        return {}


def busca(titulo, artistas):
    """Devuelve el mejor candidato o None. Prioriza que el artista sea de los nuestros.

    Se busca por todas las variantes del titulo (tal cual y desinvertido) cruzadas con
    los nombres artisticos de los autores.

    Regla dura: si el artista NO es del roster solo se acepta un titulo IDENTICO. Antes
    valia que uno contuviese al otro, y asi es como «GLOCK CHAMPIONS» acabo apuntando a
    un tema de BLACKPINK. Una coincidencia aproximada solo se admite cuando el artista
    si es nuestro.
    """
    tits = variantes(titulo)
    consultas = []
    for t in tits:
        for a in artistas[:3]:
            consultas.append("%s %s" % (t, a))
    consultas.extend(tits)

    MAXIMO = 13  # artista del roster (10) + titulo identico (3)
    mejor = None
    for q in consultas:
        d = deezer("https://api.deezer.com/search?q=%s&limit=8" % urllib.parse.quote(q))
        for t in d.get("data", []):
            art = norm(t.get("artist", {}).get("name", ""))
            nuestro = any(n in art for n in NUESTROS)
            nivel = max(casa_titulo(x, t.get("title", "")) for x in tits)
            if not nivel:
                continue
            if not nuestro and nivel < 3:
                continue
            punt = (10 if nuestro else 0) + nivel
            if mejor is None or punt > mejor[0]:
                mejor = (punt, t)
            if punt == MAXIMO:
                break
        if mejor and mejor[0] == MAXIMO:
            break
        time.sleep(0.25)
    return mejor[1] if mejor else None


def main():
    filas = list(csv.DictReader(io.open(MAPEO, encoding="utf-8"), delimiter="\t"))
    huer = [r for r in filas if r["confianza"] == "HUERFANA"]

    # Pista del artista para buscar en Deezer.
    #
    # OJO: «Recorded By» NO sirve solo. UMPG pone ahi «DISOBEY» (el nombre del
    # colectivo) en la mayoria, y DISOBEY no existe como artista en Deezer, asi que
    # la busqueda no encontraba nada. La pista buena son los AUTORES de la obra:
    # de ahi salen los nombres artisticos con los que si publican.
    APELLIDO_A_ALIAS = {
        "arenas castillo": "8belial", "perez de ynestrosa": "yyy891",
        "roa barrasa": "roomtrash6", "garcia garcia": "cybernene",
        "cabero gomez villaboa": "Aft3rlife", "sanchez vicent": "JOHNNYFUU",
        "blanco escudero": "El WiWi", "beltran fernandez": "Virtual Flavor"}

    rec = {}
    for p in glob.glob(os.path.join(RAIZ, "*", "Works-A*.csv")):
        if "Copyright-Splits" in p:
            continue
        fh = io.open(p, encoding="utf-8-sig"); fh.readline()
        for r in csv.DictReader(fh):
            c = (r.get("Work Code") or "").strip()
            if not c:
                continue
            pistas = []
            # 1º los autores, por orden de aparicion (el primero suele ser el principal)
            for w in (r.get("Writers") or "").replace("&", ",").split(","):
                w = norm(w)
                for ape, alias in APELLIDO_A_ALIAS.items():
                    if ape in w and alias not in pistas:
                        pistas.append(alias)
            # 2º «Recorded By», pero descartando «DISOBEY» que no es un artista de Deezer
            for v in (r.get("Recorded By") or "").split(","):
                v = v.strip()
                if v and v != "-" and v.lower() != "disobey" and v not in pistas:
                    pistas.append(v)
            if pistas and c not in rec:
                rec[c] = pistas

    print("Buscando %d obras en Deezer...\n" % len(huer))
    out, hallados = [], 0
    for i, r in enumerate(huer, 1):
        cod, tit = r["cod_obra"], r["titulo_umpg"]
        arts = rec.get(cod, [])
        t = busca(tit, arts)
        if t:
            det = deezer("https://api.deezer.com/track/%s" % t["id"])
            isrc = det.get("isrc", "")
            alb = det.get("album", {}) or t.get("album", {})
            # El titulo PUBLICADO, que no siempre es el que cataloga UMPG:
            # «SIMON, EL» se publico como «el simón». En el catalogo de la app tiene
            # que aparecer el publicado, que es el que ve el artista.
            out.append([cod, tit, isrc, t.get("artist", {}).get("name", ""),
                        alb.get("title", ""), det.get("release_date", ""),
                        alb.get("cover_medium", "") or alb.get("cover", ""),
                        "https://www.deezer.com/track/%s" % t["id"],
                        det.get("title", "") or t.get("title", "")])
            hallados += 1
            print("  %3d/%d  %-30s %-14s %s" % (i, len(huer), tit[:30], isrc or "(sin isrc)",
                                                alb.get("title", "")[:28]))
        else:
            out.append([cod, tit, "", "", "", "", "", "", ""])
            print("  %3d/%d  %-30s --" % (i, len(huer), tit[:30]))
        time.sleep(0.3)

    with io.open(SALIDA, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, delimiter="\t")
        w.writerow(["cod_obra", "titulo_umpg", "isrc", "artista_deezer", "album",
                    "fecha_lanzamiento", "portada", "url", "titulo_deezer"])
        w.writerows(out)

    print()
    print("encontrados: %d de %d" % (hallados, len(huer)))
    print("con ISRC   : %d" % sum(1 for o in out if o[2]))
    albs = {}
    for o in out:
        if o[4]:
            albs[o[4]] = albs.get(o[4], 0) + 1
    if albs:
        print("\n=== RELEASES a los que pertenecen ===")
        for a, c in sorted(albs.items(), key=lambda kv: -kv[1]):
            print("  %-44s %2d obras" % (a[:44], c))
    print("\nguardado %s" % SALIDA)


if __name__ == "__main__":
    main()
