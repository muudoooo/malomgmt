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

import io, os, csv, glob, json, time, re, unicodedata, urllib.parse, urllib.request

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


def deezer(url):
    try:
        with urllib.request.urlopen(url, timeout=15) as r:
            return json.loads(r.read().decode("utf-8"))
    except Exception:
        return {}


def busca(titulo, artistas):
    """Devuelve el mejor candidato o None. Prioriza que el artista sea de los nuestros."""
    consultas = []
    for a in artistas[:2]:
        consultas.append("%s %s" % (titulo, a))
    consultas.append(titulo)

    mejor = None
    for q in consultas:
        d = deezer("https://api.deezer.com/search?q=%s&limit=8" % urllib.parse.quote(q))
        for t in d.get("data", []):
            art = norm(t.get("artist", {}).get("name", ""))
            tit = norm(t.get("title", ""))
            mismo_tit = tit == norm(titulo) or norm(titulo) in tit or tit in norm(titulo)
            nuestro = any(n in art for n in NUESTROS)
            if not mismo_tit:
                continue
            punt = (2 if nuestro else 0) + (1 if tit == norm(titulo) else 0)
            if mejor is None or punt > mejor[0]:
                mejor = (punt, t)
            if punt == 3:
                break
        if mejor and mejor[0] == 3:
            break
        time.sleep(0.25)
    return mejor[1] if mejor else None


def main():
    filas = list(csv.DictReader(io.open(MAPEO, encoding="utf-8"), delimiter="\t"))
    huer = [r for r in filas if r["confianza"] == "HUERFANA"]

    # «Recorded By» de cada obra, que es la mejor pista del artista
    rec = {}
    for p in glob.glob(os.path.join(RAIZ, "*", "Works-A*.csv")):
        if "Copyright-Splits" in p:
            continue
        fh = io.open(p, encoding="utf-8-sig"); fh.readline()
        for r in csv.DictReader(fh):
            c = (r.get("Work Code") or "").strip()
            v = (r.get("Recorded By") or "").strip()
            if c and v and v != "-" and c not in rec:
                rec[c] = [x.strip() for x in v.split(",") if x.strip()]

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
            out.append([cod, tit, isrc, t.get("artist", {}).get("name", ""),
                        alb.get("title", ""), det.get("release_date", ""),
                        alb.get("cover_medium", "") or alb.get("cover", ""),
                        "https://www.deezer.com/track/%s" % t["id"]])
            hallados += 1
            print("  %3d/%d  %-30s %-14s %s" % (i, len(huer), tit[:30], isrc or "(sin isrc)",
                                                alb.get("title", "")[:28]))
        else:
            out.append([cod, tit, "", "", "", "", "", ""])
            print("  %3d/%d  %-30s --" % (i, len(huer), tit[:30]))
        time.sleep(0.3)

    with io.open(SALIDA, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, delimiter="\t")
        w.writerow(["cod_obra", "titulo_umpg", "isrc", "artista_deezer", "album",
                    "fecha_lanzamiento", "portada", "url"])
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
