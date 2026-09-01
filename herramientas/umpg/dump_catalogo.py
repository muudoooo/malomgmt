# -*- coding: utf-8 -*-
"""Vuelca de Supabase los dos TSV de referencia que usan los scripts de UMPG.

Por que existe: catalogo_malo.tsv y clientes_malo.tsv se hicieron a mano y se
quedaron rancios (118 canciones cuando ya habia 177). Cualquier script que los use
para cruzar da falsos «HUERFANA». Esto los regenera en 2 segundos.

Credenciales: de ~/.royalties-keys (SUPABASE_URL y SUPABASE_KEY). No se imprimen.
Solo lee: hace GET a la API REST, nunca escribe.

Uso:  python3 dump_catalogo.py
"""

import io, os, csv, json, re, urllib.parse, urllib.request

AQUI = os.path.dirname(os.path.abspath(__file__))
CLAVES = os.path.expanduser("~/.royalties-keys")


def credenciales():
    if not os.path.exists(CLAVES):
        raise SystemExit("No existe %s" % CLAVES)
    d = {}
    for ln in io.open(CLAVES, encoding="utf-8"):
        m = re.match(r"\s*(?:export\s+)?(\w+)\s*=\s*(.*)", ln)
        if m:
            d[m.group(1)] = m.group(2).strip().strip("'\"")
    url, key = d.get("SUPABASE_URL"), d.get("SUPABASE_KEY")
    if not url or not key:
        raise SystemExit("Faltan SUPABASE_URL o SUPABASE_KEY en %s" % CLAVES)
    return url.rstrip("/"), key


def trae(url, key, tabla, campos):
    """Paginado: la API corta a 1000 filas por defecto."""
    filas, desde, TRAMO = [], 0, 1000
    while True:
        q = "%s/rest/v1/%s?select=%s&order=id" % (url, tabla, urllib.parse.quote(campos))
        req = urllib.request.Request(q, headers={
            "apikey": key, "Authorization": "Bearer %s" % key,
            "Range-Unit": "items", "Range": "%d-%d" % (desde, desde + TRAMO - 1)})
        with urllib.request.urlopen(req, timeout=30) as r:
            lote = json.loads(r.read().decode("utf-8"))
        filas.extend(lote)
        if len(lote) < TRAMO:
            return filas
        desde += TRAMO


def escribe(ruta, cols, filas):
    with io.open(ruta, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, delimiter="\t")
        w.writerow(cols)
        for f in filas:
            w.writerow([(f.get(c) or "") for c in cols])
    print("  %-22s %3d filas" % (os.path.basename(ruta), len(filas)))


def main():
    url, key = credenciales()
    print("Volcando de Supabase...")
    can = trae(url, key, "canciones", "id,titulo,isrc")
    cli = trae(url, key, "clientes", "id,nombre,nombre_real")
    can.sort(key=lambda r: (r.get("titulo") or "").upper())
    cli.sort(key=lambda r: (r.get("nombre") or "").upper())
    escribe(os.path.join(AQUI, "catalogo_malo.tsv"), ["id", "titulo", "isrc"], can)
    escribe(os.path.join(AQUI, "clientes_malo.tsv"), ["id", "nombre", "nombre_real"], cli)
    con = sum(1 for r in can if r.get("isrc"))
    print("\ncanciones con ISRC: %d de %d" % (con, len(can)))


if __name__ == "__main__":
    main()
