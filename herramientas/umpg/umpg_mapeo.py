# -*- coding: utf-8 -*-
"""Propone el mapeo  Cod. Cancion (UMPG)  <->  cancion_id / ISRC  (catalogo MALO).

El detalle de UMPG NO trae ISRC ni ISWC: la unica forma de cruzar editorial con
master (ADA) es por titulo. Este script hace el trabajo pesado y deja para revision
manual solo lo dudoso.

Entrada:
  /tmp/malopatch/umpg_filas.json         <- de umpg_lee.py
  herramientas/umpg/catalogo_malo.tsv    <- volcado de canciones (id, titulo, isrc)

Salida:
  herramientas/umpg/mapeo_umpg.tsv       <- para revisar y corregir a mano

Niveles de confianza:
  EXACTO    titulo identico en el catalogo de la app   -> dar por bueno
  FUERTE    coincide quitando parentesis/feat           -> revision rapida
  DUDOSO    parecido >= UMBRAL por similitud            -> revisar si o si
  SOLO_ADA  no esta en la app pero si en ADA            -> falta en el catalogo
  HUERFANA  no esta ni en la app ni en ADA              -> ver nota abajo
  SIN_MATCH                                             -> mapear a mano

Una obra HUERFANA suele significar una de dos cosas:
  a) el artista escribio para un tema de OTRO que no distribuye MALO
     (trabajo de autor externo que la app no esta registrando), o
  b) el tema salio por otro canal / con otro titulo.
En ambos casos es informacion util: UMPG cobra por obras que MALO no tiene fichadas.
"""

import io, os, re, json, csv, glob, difflib, unicodedata

AQUI = os.path.dirname(os.path.abspath(__file__))
FILAS = "/tmp/malopatch/umpg_filas.json"
CATALOGO = os.path.join(AQUI, "catalogo_malo.tsv")
SALIDA = os.path.join(AQUI, "mapeo_umpg.tsv")
EXCLUIDOS = os.path.join(AQUI, "enlaces_excluidos.tsv")
UMBRAL = 0.82

ARTICULOS = ("la", "el", "los", "las", "un", "una")
ADA_RAIZ = os.path.expanduser("~/MALO/ADA ROYALTIES")


def sin_acentos(s):
    return unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode()


def base(s):
    """Normalizacion suave: sin acentos, sin simbolos, minusculas."""
    s = sin_acentos(s).lower()
    s = s.replace("&", " and ")
    s = re.sub(r"[^a-z0-9 ]", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def desinvierte(s):
    """'nueva religion, la' -> 'la nueva religion'  (estilo catalogo UMPG)"""
    if "," in s:
        izq, der = s.rsplit(",", 1)
        if der.strip().lower() in ARTICULOS:
            return "%s %s" % (der.strip(), izq.strip())
    return s


def fuerte(s):
    """Normalizacion agresiva: quita parentesis, feat, remix, articulo inicial."""
    s = desinvierte(s or "")
    s = re.sub(r"\(.*?\)", " ", s)
    s = base(s)
    s = re.sub(r"\b(ft|feat|featuring)\b.*", " ", s)
    s = re.sub(r"\b(remix|bonus track|prerelease)\b", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    for a in ARTICULOS:
        if s.startswith(a + " "):
            s = s[len(a) + 1:]
            break
    return s


def carga_catalogo():
    if not os.path.exists(CATALOGO):
        print("FALTA %s -- generalo con la consulta a Supabase (id, titulo, isrc)" % CATALOGO)
        return []
    out = []
    with io.open(CATALOGO, encoding="utf-8") as fh:
        for fila in csv.DictReader(fh, delimiter="\t"):
            out.append({
                "cancion_id": (fila.get("id") or "").strip(),
                "titulo": (fila.get("titulo") or "").strip(),
                "isrc": (fila.get("isrc") or "").strip(),
            })
    return out


def carga_ada():
    """{titulo_normalizado: (bruto, {isrc,...})} desde los extractos de ADA."""
    def num_ada(s):
        s = (s or "").strip().replace(".", "").replace(",", ".")
        try:
            return float(s)
        except ValueError:
            return 0.0

    ada = {}
    for f in glob.glob(os.path.join(ADA_RAIZ, "*", "Statement_*.txt")):
        with io.open(f, encoding="utf-8", errors="replace") as fh:
            cab = fh.readline().rstrip("\n").split("\t")
            ix = {c: i for i, c in enumerate(cab)}
            for ln in fh:
                p = ln.rstrip("\n").split("\t")
                if len(p) < len(cab) - 2:
                    continue
                g = lambda c: (p[ix[c]] if c in ix and ix[c] < len(p) else "")
                t = base(g("Product Title"))
                if not t:
                    continue
                d = ada.setdefault(t, [0.0, set()])
                d[0] += num_ada(g("Royalty Payable"))
                if g("ISRC").strip():
                    d[1].add(g("ISRC").strip())
    return ada


def main():
    if not os.path.exists(FILAS):
        print("Falta %s: corre antes umpg_lee.py" % FILAS)
        return
    filas = json.load(io.open(FILAS, encoding="utf-8")) if os.path.exists(FILAS) else []
    cat = carga_catalogo()
    if not cat:
        return

    # El catalogo COMPLETO de obras (los CSV de Works-*), no solo las que
    # generaron dinero: hay que mapear las 157, no las 31 que facturaron.
    obras = {}
    for ruta in glob.glob(os.path.join(os.path.expanduser("~/MALO/UMPG PUBLISHING"), "*", "Works-A*.csv")):
        if "Copyright-Splits" in ruta:
            continue
        fh = io.open(ruta, encoding="utf-8-sig"); fh.readline()
        for r in csv.DictReader(fh):
            cod = (r.get("Work Code") or "").strip()
            if cod and cod not in obras:
                obras[cod] = {"titulo": (r.get("Work Title") or "").strip(),
                              "royalties": 0.0, "shares": set()}
    # y encima el dinero, para poder priorizar la revision
    for x in filas:
        o = obras.setdefault(x["obra"], {"titulo": x["titulo"], "royalties": 0.0, "shares": set()})
        o["royalties"] += x["royalties"]
        o["shares"].add(x["share_obra"])

    # indices del catalogo
    por_base = {}
    por_fuerte = {}
    for c in cat:
        por_base.setdefault(base(c["titulo"]), []).append(c)
        por_fuerte.setdefault(fuerte(c["titulo"]), []).append(c)
    claves_fuertes = list(por_fuerte)

    ada = carga_ada()
    NIVELES = ["EXACTO", "FUERTE", "DUDOSO", "SOLO_ADA", "HUERFANA", "SIN_MATCH"]
    res, conteo = [], dict((k, 0) for k in NIVELES)
    for cod, o in sorted(obras.items(), key=lambda kv: -kv[1]["royalties"]):
        t = o["titulo"]
        cand, nivel = None, "SIN_MATCH"

        if base(t) in por_base:
            cand, nivel = por_base[base(t)][0], "EXACTO"
        elif fuerte(t) in por_fuerte:
            cand, nivel = por_fuerte[fuerte(t)][0], "FUERTE"
        else:
            cerca = difflib.get_close_matches(fuerte(t), claves_fuertes, n=1, cutoff=UMBRAL)
            if cerca:
                cand, nivel = por_fuerte[cerca[0]][0], "DUDOSO"

        isrc_ada = ""
        if nivel == "SIN_MATCH":
            d = ada.get(base(t))
            if d:
                nivel = "SOLO_ADA"
                isrc_ada = ",".join(sorted(d[1]))
            else:
                nivel = "HUERFANA"

        conteo[nivel] += 1
        res.append({
            "cod_obra": cod,
            "titulo_umpg": t,
            "royalties": round(o["royalties"], 4),
            "share_obra": "/".join("%.2f" % s for s in sorted(o["shares"], reverse=True)),
            "confianza": nivel,
            "cancion_id": cand["cancion_id"] if cand else "",
            "titulo_malo": cand["titulo"] if cand else "",
            "isrc": (cand["isrc"] if cand else "") or isrc_ada,
        })

    cols = ["cod_obra", "titulo_umpg", "royalties", "share_obra", "confianza",
            "cancion_id", "titulo_malo", "isrc"]
    with io.open(SALIDA, "w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols, delimiter="\t")
        w.writeheader()
        for r in res:
            w.writerow(r)

    print("obras UMPG: %d" % len(res))
    for k in NIVELES:
        print("  %-10s %3d" % (k, conteo[k]))
    aut = conteo["EXACTO"] + conteo["FUERTE"]
    print("\nresueltas automaticamente: %d de %d (%.0f%%)" % (aut, len(res), 100.0 * aut / len(res)))
    print("a revisar a mano         : %d" % (len(res) - aut))
    if conteo["HUERFANA"]:
        print("\nOJO: %d obras HUERFANAS -- UMPG cobra por obras que no estan ni en la app ni en ADA."
              % conteo["HUERFANA"])

    pend = [r for r in res if r["confianza"] not in ("EXACTO", "FUERTE")]
    if pend:
        print("\n--- PENDIENTES (por dinero) ---")
        print("%-8s %-32s %9s  %-9s %s" % ("COD", "TITULO UMPG", "ROYALTY", "NIVEL", "PROPUESTA"))
        for r in pend:
            print("%-8s %-32s %9.4f  %-9s %s" % (
                r["cod_obra"], r["titulo_umpg"][:32], r["royalties"],
                r["confianza"], r["titulo_malo"] or "-"))
    print("\nguardado %s" % SALIDA)

    # ── SQL del puente obra <-> cancion
    #
    # Solo EXACTO y FUERTE: lo DUDOSO no entra automatico, que un puente mal
    # puesto ensucia el informe cruzado y cuesta mas de arreglar que de revisar.
    import hashlib
    def obr_id(cod):
        return "obr_" + hashlib.sha1(cod.encode("utf-8")).hexdigest()[:12]

    # Enlaces vetados a mano. Existen porque el titulo puede casar y aun asi ser la
    # obra equivocada: «INTRO» de EL PRINCIPE caso con DDJ534, que es la intro del
    # DISOBEY VOL. I. Se borro a mano el 31 ago y la siguiente regeneracion del puente
    # lo volvio a meter, porque el script no sabia nada de esa decision.
    #
    # Ahora sí lo sabe: lo que este en enlaces_excluidos.tsv no vuelve a entrar.
    vetados = set()
    if os.path.exists(EXCLUIDOS):
        for r in csv.DictReader(io.open(EXCLUIDOS, encoding="utf-8"), delimiter="\t"):
            cod, can = (r.get("cod_obra") or "").strip(), (r.get("cancion_id") or "").strip()
            if cod and can:
                vetados.add((cod, can))

    buenos = [r for r in res if r["confianza"] in ("EXACTO", "FUERTE") and r["cancion_id"]
              and (r["cod_obra"], r["cancion_id"]) not in vetados]
    fuera = [r for r in res if r["confianza"] in ("EXACTO", "FUERTE") and r["cancion_id"]
             and (r["cod_obra"], r["cancion_id"]) in vetados]
    if fuera:
        print()
        print("ENLACES VETADOS A MANO (no entran en el puente):")
        for r in fuera:
            print("   %-8s %-28s -> %s" % (r["cod_obra"], r["titulo_umpg"][:28], r["cancion_id"]))
    L = ["-- Puente obra <-> grabacion (public.obra_canciones).",
         "-- Generado por herramientas/umpg/umpg_mapeo.py.",
         "-- Solo entradas EXACTO y FUERTE; lo dudoso se revisa a mano en mapeo_umpg.tsv.",
         "-- Los pares de enlaces_excluidos.tsv quedan FUERA: son enlaces que casaban por",
         "-- titulo pero apuntaban a la obra equivocada, verificado a mano.",
         "-- Idempotente: clave primaria (obra_id, cancion_id).",
         "",
         "begin;",
         "",
         "insert into public.obra_canciones (obra_id, cancion_id, confianza) values"]
    filas_sql = ["  ('%s', '%s', '%s')" % (obr_id(r["cod_obra"]), r["cancion_id"], r["confianza"].lower())
                 for r in buenos]
    L.append(",\n".join(filas_sql))
    L.append("on conflict (obra_id, cancion_id) do update set confianza = excluded.confianza;")
    L.append("")
    L.append("commit;")
    L.append("")
    L.append("-- comprobacion")
    L.append("select confianza, count(*) from public.obra_canciones group by confianza order by confianza;")
    ruta_sql = os.path.abspath(os.path.join(AQUI, "..", "..", "supabase", "editorial-puente.sql"))
    io.open(ruta_sql, "w", encoding="utf-8").write("\n".join(L) + "\n")
    print("guardado %s  (%d enlaces)" % (ruta_sql, len(buenos)))


if __name__ == "__main__":
    main()
