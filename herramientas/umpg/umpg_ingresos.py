# -*- coding: utf-8 -*-
"""Carga los ingresos editoriales de UMPG en public.obra_ingresos.

Lee los «Detalle de la liquidacion de royalties» (.TAB dentro de zip) que hay en
~/MALO/UMPG PUBLISHING/<CODIGO>/ y genera supabase/editorial-ingresos.sql.

La cascada editorial es MAS SIMPLE que la de distribucion: UMPG ya se queda su parte
dentro del propio statement (columna Importe -> Royalties), asi que:

    importe_bruto = lo que recauda UMPG
    importe_neto  = lo que cobra el cliente   (ya neto del deal editorial)
    comision MALO = importe_neto * clientes.comisiones.management / 100

No hay que aplicar ninguna cascada extra: hacerlo descontaria dos veces.

Requiere supabase/editorial.sql y editorial-datos.sql aplicados (las obras tienen
que existir para poder enlazarlas).
"""

import io, os, re, csv, glob, json, hashlib, zipfile, unicodedata, collections

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.expanduser("~/MALO/UMPG PUBLISHING")
CLIENTES = os.path.join(AQUI, "clientes_malo.tsv")
SALIDA = os.path.abspath(os.path.join(AQUI, "..", "..", "supabase", "editorial-ingresos.sql"))

PARTICULAS = {"de", "del", "la", "las", "los", "y", "i"}


def palabras(s):
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    s = re.sub(r"[^a-z ]", " ", s)
    return set(w for w in s.split() if len(w) > 1 and w not in PARTICULAS)


def casan(a, b):
    if not a or not b:
        return False
    c = a & b
    return len(c) >= 2 and (c == a or c == b)


def uid(prefijo, *partes):
    h = hashlib.sha1("|".join(partes).encode("utf-8")).hexdigest()[:12]
    return "%s_%s" % (prefijo, h)


def q(v):
    if v is None or v == "":
        return "null"
    return "'" + str(v).replace("'", "''") + "'"


def num(s):
    s = (s or "").strip().lstrip("+")
    try:
        return float(s)
    except ValueError:
        return 0.0


def parte_procedencia(p):
    """'APPLE MUSIC - MEXICO' -> ('APPLE MUSIC', 'MEXICO')."""
    p = (p or "").strip()
    if " - " in p:
        a, b = p.rsplit(" - ", 1)
        return a.strip(), b.strip()
    return p, ""


def periodo_de(nombre):
    """AHC3_2026-01_detalle.TAB -> '2026-01'."""
    m = re.search(r"(\d{4}-\d{2})", nombre or "")
    return m.group(1) if m else ""


def abre(ruta):
    if ruta.lower().endswith(".zip"):
        z = zipfile.ZipFile(ruta)
        tabs = [n for n in z.namelist() if n.lower().endswith(".tab")]
        if not tabs:
            return None
        return io.TextIOWrapper(z.open(tabs[0]), encoding="utf-8-sig", errors="replace")
    return io.open(ruta, encoding="utf-8-sig", errors="replace")


def carga_clientes():
    out = []
    with io.open(CLIENTES, encoding="utf-8") as fh:
        for f in csv.DictReader(fh, delimiter="\t"):
            real = (f.get("nombre_real") or "").strip()
            if real:
                out.append((palabras(real), f["id"].strip(), f["nombre"].strip()))
    return out


def main():
    g = lambda r, c: (r.get(c) or "").strip()
    clientes = carga_clientes()

    rutas = sorted(glob.glob(os.path.join(RAIZ, "*", "*detalle*.TAB")))
    if not rutas:
        rutas = sorted(glob.glob(os.path.join(RAIZ, "*", "*detalle*.zip")))

    # agregamos por (obra, periodo, devengo, tipo, dsp, territorio): el detalle
    # trae una linea por cada micro-uso y no aporta nada guardarlas sueltas
    agg = collections.defaultdict(lambda: [0.0, 0.0, 0.0])
    cli_de = {}
    sin_obra = collections.Counter()
    sin_cliente = set()

    for ruta in rutas:
        fh = abre(ruta)
        if fh is None:
            print("  (vacio) %s" % os.path.basename(ruta))
            continue
        per = periodo_de(os.path.basename(ruta))
        r = csv.reader(fh, delimiter="\t")
        cab = [c.strip() for c in next(r)]
        ix = {c: i for i, c in enumerate(cab)}
        gg = lambda p, c: (p[ix[c]].strip() if c in ix and ix[c] < len(p) else "")
        for p in r:
            if len(p) < 5:
                continue
            cod = gg(p, "Cod. Canción")
            if not cod:
                continue
            cliente_cod = gg(p, "Cliente Principal")
            if cliente_cod not in cli_de:
                m = [cid for pal, cid, _ in clientes if casan(palabras(gg(p, "Nombre del Cliente")), pal)]
                cli_de[cliente_cod] = m[0] if len(m) == 1 else None
                if not cli_de[cliente_cod]:
                    sin_cliente.add(cliente_cod)
            fuente, terr = parte_procedencia(gg(p, "Procedencia"))
            k = (cod, cliente_cod, per, gg(p, "Devengo Desde"), gg(p, "Hasta"),
                 gg(p, "Subtipo de Ingresos"), fuente, terr)
            a = agg[k]
            a[0] += num(gg(p, "Importe"))
            a[1] += num(gg(p, "Royalties"))
            a[2] += num(gg(p, "Unidades"))

    tot_b = sum(v[0] for v in agg.values())
    tot_n = sum(v[1] for v in agg.values())
    print("ficheros procesados : %d" % len(rutas))
    print("filas agregadas     : %d" % len(agg))
    print("obras distintas     : %d" % len(set(k[0] for k in agg)))
    print("clientes            : %s" % sorted(set(k[1] for k in agg)))
    print("IMPORTE (UMPG)      : %.4f EUR" % tot_b)
    print("NETO (al cliente)   : %.4f EUR" % tot_n)
    if sin_cliente:
        print("codigos SIN cliente en Supabase: %s" % sorted(sin_cliente))

    L = []
    L.append("-- Ingresos editoriales de UMPG Window -> public.obra_ingresos.")
    L.append("-- Generado por herramientas/umpg/umpg_ingresos.py. Idempotente (ids deterministas).")
    L.append("-- OJO: importe_neto ya viene neto del deal con la editorial; la comision de")
    L.append("-- management se aplica encima, en la app, con clientes.comisiones.management.")
    L.append("-- Requiere editorial.sql y editorial-datos.sql aplicados.")
    L.append("")
    L.append("begin;")
    L.append("")
    L.append("insert into public.obra_ingresos")
    L.append("  (id, obra_id, cliente_id, fuente, periodo, devengo_desde, devengo_hasta,")
    L.append("   tipo_uso, dsp, territorio, unidades, importe_bruto, importe_neto) values")
    filas = []
    for k in sorted(agg):
        cod, cliente_cod, per, dd, dh, tipo, dsp, terr = k
        b, n_, u = agg[k]
        filas.append("  (%s, %s, %s, 'UMPG', %s, %s, %s, %s, %s, %s, %s, %.6f, %.6f)" % (
            q(uid("obi", *[str(x) for x in k])), q(uid("obr", cod)),
            q(cli_de.get(cliente_cod)) if cli_de.get(cliente_cod) else "null",
            q(per), q(dd), q(dh), q(tipo), q(dsp), q(terr),
            ("%.0f" % u) if u else "null", b, n_))
    L.append(",\n".join(filas))
    L.append("on conflict (id) do update set")
    L.append("  importe_bruto = excluded.importe_bruto,")
    L.append("  importe_neto  = excluded.importe_neto,")
    L.append("  unidades      = excluded.unidades;")
    L.append("")
    L.append("commit;")
    L.append("")
    L.append("-- comprobacion")
    L.append("select periodo, count(*) as filas, count(distinct obra_id) as obras,")
    L.append("       round(sum(importe_bruto)::numeric,2) as bruto,")
    L.append("       round(sum(importe_neto)::numeric,2) as neto")
    L.append("  from public.obra_ingresos group by periodo order by periodo;")

    with io.open(SALIDA, "w", encoding="utf-8") as fh:
        fh.write("\n".join(L) + "\n")
    print("\ngenerado %s" % SALIDA)


if __name__ == "__main__":
    main()
