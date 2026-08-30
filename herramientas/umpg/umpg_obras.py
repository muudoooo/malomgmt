# -*- coding: utf-8 -*-
"""Carga el catalogo de obras y el reparto de copyright de UMPG en la seccion Editorial.

Lee los dos CSV que exporta UMPG Window por cada cliente:
  Works-<CODIGO>-<AAAAMMDD>.csv                  -> obras (con ISWC y Recorded By)
  Works-Copyright-Splits-<CODIGO>-<AAAAMMDD>.csv -> obra_participantes

y genera  supabase/editorial-datos.sql  para pegar en el SQL Editor.

Por que genera SQL en vez de escribir en Supabase: el acceso desde aqui es de solo
lectura. El SQL resultante es idempotente (upsert por clave natural), asi que se puede
volver a ejecutar cuando lleguen periodos nuevos.

Entrada : ~/MALO/UMPG PUBLISHING/<CODIGO>/*.csv
          herramientas/umpg/clientes_malo.tsv   (volcado de public.clientes)
Salida  : supabase/editorial-datos.sql
"""

import io, os, re, csv, glob, hashlib, unicodedata, collections

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.expanduser("~/MALO/UMPG PUBLISHING")
CLIENTES = os.path.join(AQUI, "clientes_malo.tsv")
SALIDA = os.path.abspath(os.path.join(AQUI, "..", "..", "supabase", "editorial-datos.sql"))

EDITORIALES = ("Universal Music Publishing", "Unknown Publisher", "Universal Musica")


PARTICULAS = {"de", "del", "la", "las", "los", "y", "i"}


def palabras(s):
    """Nombre -> conjunto de palabras significativas, sin acentos ni particulas.

    UMPG escribe 'Perez De Ynestrosa Garcia, Francisco Jose' y en clientes esta como
    'Francisco Perez de Ynestrosa': mismo humano, distinto numero de apellidos. Por eso
    se compara por CONJUNTO y se acepta que uno sea subconjunto del otro.
    """
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    s = re.sub(r"[^a-z ]", " ", s)
    return set(w for w in s.split() if len(w) > 1 and w not in PARTICULAS)


def casan(a, b):
    """True si a y b son la misma persona: uno contiene al otro, con >=2 palabras."""
    if not a or not b:
        return False
    comun = a & b
    return len(comun) >= 2 and (comun == a or comun == b)


def uid(prefijo, *partes):
    """Id estable: mismo input -> mismo id, para que el SQL sea idempotente."""
    h = hashlib.sha1("|".join(partes).encode("utf-8")).hexdigest()[:12]
    return "%s_%s" % (prefijo, h)


def q(v):
    """Literal SQL. None/'' -> null en los campos que lo admiten."""
    if v is None or v == "":
        return "null"
    return "'" + str(v).replace("'", "''") + "'"


def num(v):
    v = (v or "").strip()
    if not v or v == "-":
        return "null"
    try:
        return "%.4f" % float(v)
    except ValueError:
        return "null"


def leer_csv(ruta):
    """Los CSV de UMPG llevan una linea de titulo antes de la cabecera."""
    fh = io.open(ruta, encoding="utf-8-sig")
    fh.readline()
    return list(csv.DictReader(fh))


def carga_clientes():
    out = []
    with io.open(CLIENTES, encoding="utf-8") as fh:
        for f in csv.DictReader(fh, delimiter="\t"):
            real = (f.get("nombre_real") or "").strip()
            if real:
                out.append((palabras(real), f["id"].strip(), f["nombre"].strip()))
    return out


def busca_cliente(nombre, clientes):
    """Devuelve (cliente_id, alias) o None. Si hay mas de un candidato, no arriesga."""
    p = palabras(nombre)
    hits = [(cid, alias) for pal, cid, alias in clientes if casan(p, pal)]
    return hits[0] if len(hits) == 1 else None


def main():
    g = lambda r, c: (r.get(c) or "").strip()
    clientes = carga_clientes()

    obras = {}        # work_code -> dict
    parts = {}        # clave natural -> dict
    sin_cliente = collections.Counter()

    for ruta in sorted(glob.glob(os.path.join(RAIZ, "*", "Works-*.csv"))):
        base = os.path.basename(ruta)
        es_split = "Copyright-Splits" in base

        for r in leer_csv(ruta):
            cod = g(r, "Work Code")
            if not cod:
                continue

            if not es_split:
                iswc = g(r, "ISWC")
                rec = g(r, "Recorded By")
                o = obras.setdefault(cod, {"titulo": "", "iswc": "", "rec": ""})
                # nos quedamos con el valor mas completo que aparezca en cualquier cliente
                if g(r, "Work Title"):
                    o["titulo"] = g(r, "Work Title")
                if iswc and iswc != "-":
                    o["iswc"] = iswc
                if rec and rec != "-":
                    o["rec"] = rec
            else:
                nombre = g(r, "Name")
                cap = g(r, "Capacity") or "CA"
                clave = (cod, nombre, cap, g(r, "Cont %"), g(r, "Mechanical"))
                if clave in parts:
                    continue
                cid = None
                if cap == "CA":
                    m = busca_cliente(nombre, clientes)
                    if m:
                        cid = m[0]
                    elif not any(nombre.startswith(e) for e in EDITORIALES):
                        sin_cliente[nombre] += 1
                ctrl = g(r, "Control")
                parts[clave] = {
                    "obra": cod, "nombre": nombre, "cap": cap, "cid": cid,
                    "soc": g(r, "Society"),
                    "ctrl": "true" if ctrl == "Y" else ("false" if ctrl == "N" else "null"),
                    "cont": g(r, "Cont %"), "mec": g(r, "Mechanical"), "eje": g(r, "Performance"),
                }
                # la obra puede aparecer solo en el fichero de splits
                obras.setdefault(cod, {"titulo": g(r, "Work Title"), "iswc": g(r, "ISWC"), "rec": ""})

    # ── informe
    con_iswc = sum(1 for o in obras.values() if o["iswc"] and o["iswc"] != "-")
    autores = set(p["nombre"] for p in parts.values() if p["cap"] == "CA")
    mapeados = set(p["nombre"] for p in parts.values() if p["cap"] == "CA" and p["cid"])
    print("obras            : %d  (con ISWC: %d)" % (len(obras), con_iswc))
    print("filas de reparto : %d" % len(parts))
    print("autores distintos: %d  (mapeados a clientes: %d)" % (len(autores), len(mapeados)))
    if sin_cliente:
        print("\nautores SIN cliente en Supabase (%d):" % len(sin_cliente))
        for n, c in sin_cliente.most_common():
            print("   %-46s %3d obras" % (n[:46], c))

    # ── SQL
    L = []
    L.append("-- Datos de la seccion Editorial: catalogo de obras y reparto de copyright.")
    L.append("-- Generado por herramientas/umpg/umpg_obras.py a partir de los CSV de UMPG Window.")
    L.append("-- Idempotente: los ids son deterministas y hay upsert, se puede reejecutar.")
    L.append("-- Requiere supabase/editorial.sql aplicado antes.")
    L.append("")
    L.append("begin;")
    L.append("")
    L.append("-- ── obras (%d)" % len(obras))
    L.append("insert into public.obras (id, work_code, titulo, iswc, editorial, recorded_by) values")
    filas = []
    for cod in sorted(obras):
        o = obras[cod]
        iswc = o["iswc"] if o["iswc"] and o["iswc"] != "-" else ""
        filas.append("  (%s, %s, %s, %s, 'UMPG', %s)" % (
            q(uid("obr", cod)), q(cod), q(o["titulo"]), q(iswc), q(o["rec"])))
    L.append(",\n".join(filas))
    L.append("on conflict (work_code) do update set")
    L.append("  titulo = excluded.titulo,")
    L.append("  iswc = coalesce(excluded.iswc, public.obras.iswc),")
    L.append("  recorded_by = coalesce(excluded.recorded_by, public.obras.recorded_by);")
    L.append("")
    L.append("-- ── obra_participantes (%d)" % len(parts))
    L.append("delete from public.obra_participantes where obra_id in (select id from public.obras);")
    L.append("insert into public.obra_participantes")
    L.append("  (id, obra_id, cliente_id, nombre, capacidad, sociedad, controlada, cont_pct, mecanico_pct, ejecucion_pct) values")
    filas = []
    for clave in sorted(parts):
        p = parts[clave]
        filas.append("  (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)" % (
            q(uid("obp", *[str(x) for x in clave])), q(uid("obr", p["obra"])),
            q(p["cid"]) if p["cid"] else "null",
            q(p["nombre"]), q(p["cap"]), q(p["soc"]), p["ctrl"],
            num(p["cont"]), num(p["mec"]), num(p["eje"])))
    L.append(",\n".join(filas))
    L.append("on conflict (id) do nothing;")
    L.append("")
    L.append("commit;")
    L.append("")
    L.append("-- comprobacion")
    L.append("select 'obras' as tabla, count(*) from public.obras")
    L.append("union all select 'obra_participantes', count(*) from public.obra_participantes")
    L.append("union all select 'con cliente_id', count(*) from public.obra_participantes where cliente_id is not null;")

    with io.open(SALIDA, "w", encoding="utf-8") as fh:
        fh.write("\n".join(L) + "\n")
    print("\ngenerado %s" % SALIDA)


if __name__ == "__main__":
    main()
