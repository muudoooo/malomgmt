# -*- coding: utf-8 -*-
"""Resumen de la editorial, equivalente a ada_resumen.py pero para publishing.

Lee los extractos de UMPG y el catalogo de obras, saca las cifras por pantalla y
deja CSVs por cliente en ~/MALO/UMPG PUBLISHING/resumenes-vault/ (mismo sitio y
mismo espiritu que los de ADA en ~/MALO/ADA ROYALTIES/resumenes-vault/).

Los ejes NO son los de ADA, porque editorial y distribucion no se miden igual:

    ADA        mes de liquidacion x ISRC x DSP
    UMPG       periodo x OBRA x tipo de uso x plataforma x territorio
               + el desfase entre devengo y cobro
               + el estado de registro de cada obra (lo que ADA no tiene)

Genera por cliente:
    <CLI>-obra-periodo.csv    periodo;work_code;titulo;iswc;bruto;neto
    <CLI>-fuente-periodo.csv  periodo;tipo_uso;dsp;territorio;bruto;neto
Y uno global:
    ALERTAS-registro.csv      las obras con autoria sin dueno, sin sociedad o sin control

Uso:  python3 umpg_resumen.py
"""

import io, os, re, csv, glob, shutil, collections

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.expanduser("~/MALO/UMPG PUBLISHING")
SALIDA = os.path.join(RAIZ, "resumenes-vault")
# Copia al vault de Obsidian, que es donde se consulta de verdad.
# (Los de ADA acaban sueltos en la raiz de «03 Projects/MALO APP»; aqui van
#  ordenados dentro de la carpeta del proyecto.)
VAULT = os.path.expanduser(
    "~/MALO MAINFRAME/03 Projects/Royalties Editorial/03 Liquidaciones")
CLIENTES = os.path.join(AQUI, "clientes_malo.tsv")

ALIAS = {"AHC3": "8BELIAL", "AHC4": "ROOMTRASH6", "AHC5": "CYBERNENE",
         "AHC6": "YYY891", "AHC8": "ELWIWI", "AHC9": "JOHNNYFUU",
         "AHDA": "VIRTUALFLAVOR", "AHDB": "AFT3RLIFE"}


def num(s):
    s = (s or "").strip().lstrip("+")
    try:
        return float(s)
    except ValueError:
        return 0.0


def parte(p):
    p = (p or "").strip()
    return tuple(x.strip() for x in p.rsplit(" - ", 1)) if " - " in p else (p, "")


def leer_csv(ruta):
    fh = io.open(ruta, encoding="utf-8-sig")
    fh.readline()
    return list(csv.DictReader(fh))


def lee_extractos():
    """[(cliente, periodo, fila…)] de todos los *detalle*.TAB."""
    out = []
    for ruta in sorted(glob.glob(os.path.join(RAIZ, "*", "*detalle*.TAB"))):
        base = os.path.basename(ruta)
        cli = base.split("_")[0]
        m = re.search(r"(\d{4}-\d{2})", base)
        per = m.group(1) if m else "?"
        r = csv.reader(io.open(ruta, encoding="utf-8-sig", errors="replace"), delimiter="\t")
        cab = [c.strip() for c in next(r)]
        ix = {c: i for i, c in enumerate(cab)}
        g = lambda p, c: (p[ix[c]].strip() if c in ix and ix[c] < len(p) else "")
        for p in r:
            if len(p) < 5:
                continue
            dsp, terr = parte(g(p, "Procedencia"))
            out.append({
                "cli": cli, "periodo": per, "obra": g(p, "Cod. Canción"),
                "titulo": g(p, "Título Canción"), "tipo": g(p, "Subtipo de Ingresos"),
                "dsp": dsp, "territorio": terr,
                "devengo": "%s-%s" % (g(p, "Devengo Desde"), g(p, "Hasta")),
                "bruto": num(g(p, "Importe")), "neto": num(g(p, "Royalties")),
                "cont": num(g(p, "% a Pagar")),
            })
    return out


def lee_catalogo():
    """{work_code: {titulo, iswc}} y las filas de reparto."""
    obras, splits = {}, []
    for p in glob.glob(os.path.join(RAIZ, "*", "Works-*.csv")):
        if "Copyright-Splits" in p:
            for r in leer_csv(p):
                splits.append(r)
        else:
            for r in leer_csv(p):
                c = (r.get("Work Code") or "").strip()
                if not c:
                    continue
                iswc = (r.get("ISWC") or "").strip()
                o = obras.setdefault(c, {"titulo": (r.get("Work Title") or "").strip(), "iswc": ""})
                if iswc and iswc != "-":
                    o["iswc"] = iswc
    return obras, splits


def guarda(nombre, cabecera, filas):
    if not os.path.isdir(SALIDA):
        os.makedirs(SALIDA)
    with io.open(os.path.join(SALIDA, nombre), "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, delimiter=";")
        w.writerow(cabecera)
        w.writerows(filas)


def main():
    filas = lee_extractos()
    obras, splits = lee_catalogo()
    if not filas:
        print("No hay extractos en %s" % RAIZ)
        return

    # ── por pantalla
    print("=== INGRESO EDITORIAL POR PERIODO")
    por_per = collections.defaultdict(lambda: [0.0, 0.0])
    for x in filas:
        por_per[x["periodo"]][0] += x["bruto"]
        por_per[x["periodo"]][1] += x["neto"]
    for p in sorted(por_per):
        b, n_ = por_per[p]
        print("  %s   recauda %9.2f   llega %9.2f   (%.1f %%)" % (p, b, n_, 100 * n_ / b if b else 0))

    print()
    print("=== POR CLIENTE  (convierte = el %% a Pagar medio del autor, o sea su parte de las obras)")
    por_cli = collections.defaultdict(lambda: [0.0, 0.0, set()])
    for x in filas:
        d = por_cli[x["cli"]]
        d[0] += x["bruto"]; d[1] += x["neto"]; d[2].add(x["obra"])
    print("  %-6s %-16s %10s %10s %9s %6s" % ("COD", "ALIAS", "RECAUDA", "LE LLEGA", "CONVIERTE", "OBRAS"))
    for c in sorted(por_cli, key=lambda k: -por_cli[k][1]):
        b, n_, obs = por_cli[c]
        print("  %-6s %-16s %9.2f€ %9.2f€ %8.1f%% %6d" % (c, ALIAS.get(c, c), b, n_, 100 * n_ / b if b else 0, len(obs)))

    print()
    print("  Nota: «convierte» NO mide un problema. Es el share del autor en sus obras")
    print("  (% a Pagar = cont_pct x deal). Quien es coautor con parte pequeña convierte")
    print("  menos, y es lo normal. Comprobado: las obras con registro incompleto apenas")
    print("  influyen en esta cifra.")
    print()
    print("=== DESFASE  (cuando sono -> cuando se cobra)")
    for d in sorted(set(x["devengo"] for x in filas)):
        tot = sum(x["neto"] for x in filas if x["devengo"] == d)
        print("  devengo %-16s  %9.2f€" % (d, tot))

    print()
    print("=== POR TIPO DE USO")
    por_tipo = collections.defaultdict(float)
    for x in filas:
        por_tipo[x["tipo"]] += x["neto"]
    for k, v in sorted(por_tipo.items(), key=lambda kv: -kv[1]):
        print("  %-28s %9.2f€" % (k, v))

    print()
    print("=== TOP 15 OBRAS")
    por_obra = collections.defaultdict(float)
    for x in filas:
        por_obra[x["obra"]] += x["neto"]
    for c, v in sorted(por_obra.items(), key=lambda kv: -kv[1])[:15]:
        o = obras.get(c, {})
        print("  %-8s %-34s %9.2f€  %s" % (c, (o.get("titulo") or "")[:34], v,
                                           o.get("iswc") or "SIN ISWC"))

    # ── CSVs por cliente
    for cli in sorted(por_cli):
        alias = ALIAS.get(cli, cli)
        ag = collections.defaultdict(lambda: [0.0, 0.0])
        for x in filas:
            if x["cli"] != cli:
                continue
            k = (x["periodo"], x["obra"])
            ag[k][0] += x["bruto"]; ag[k][1] += x["neto"]
        guarda("%s-obra-periodo.csv" % alias,
               ["periodo", "work_code", "titulo", "iswc", "bruto", "neto"],
               [[p, c, obras.get(c, {}).get("titulo", ""), obras.get(c, {}).get("iswc", ""),
                 "%.4f" % v[0], "%.4f" % v[1]] for (p, c), v in sorted(ag.items(), key=lambda kv: -kv[1][1])])

        ag2 = collections.defaultdict(lambda: [0.0, 0.0])
        for x in filas:
            if x["cli"] != cli:
                continue
            k = (x["periodo"], x["tipo"], x["dsp"], x["territorio"])
            ag2[k][0] += x["bruto"]; ag2[k][1] += x["neto"]
        guarda("%s-fuente-periodo.csv" % alias,
               ["periodo", "tipo_uso", "dsp", "territorio", "bruto", "neto"],
               [[a, b, c, d, "%.4f" % v[0], "%.4f" % v[1]] for (a, b, c, d), v in
                sorted(ag2.items(), key=lambda kv: -kv[1][1])])

    # ── alertas de registro (esto ADA no lo tiene: es propio de editorial)
    g = lambda r, c: (r.get(c) or "").strip()
    por_obra_split = collections.defaultdict(list)
    vistos = set()
    for s in splits:
        k = (g(s, "Work Code"), g(s, "Name"), g(s, "Capacity"), g(s, "Cont %"), g(s, "Mechanical"))
        if k in vistos:
            continue
        vistos.add(k)
        por_obra_split[g(s, "Work Code")].append(s)

    alertas = []
    for cod, ps in por_obra_split.items():
        huerf = sum(num(g(s, "Mechanical")) for s in ps if g(s, "Name") == "Unknown Publisher")
        ns = sum(1 for s in ps if g(s, "Society") == "NS")
        nc = sum(1 for s in ps if g(s, "Control") == "N")
        if huerf or ns or nc:
            o = obras.get(cod, {})
            alertas.append([cod, o.get("titulo", ""), o.get("iswc", "") or "SIN ISWC",
                            "%.2f" % huerf, ns, nc, "%.4f" % por_obra.get(cod, 0.0)])
    alertas.sort(key=lambda r: -float(r[3]))
    guarda("ALERTAS-registro.csv",
           ["work_code", "titulo", "iswc", "pct_sin_dueno", "filas_sin_sociedad",
            "filas_sin_control", "neto_del_periodo"], alertas)

    print()
    print("=== ALERTAS DE REGISTRO: %d obras" % len(alertas))
    print("  (%d de ellas generaron dinero este periodo)" % sum(1 for a in alertas if float(a[6]) > 0))
    n = len(por_cli) * 2 + 1
    print()
    print("guardados %d CSVs en %s" % (n, SALIDA))

    # y una copia en el vault, que es donde se leen
    if os.path.isdir(os.path.dirname(VAULT)):
        if not os.path.isdir(VAULT):
            os.makedirs(VAULT)
        for f in glob.glob(os.path.join(SALIDA, "*.csv")):
            shutil.copy2(f, VAULT)
        print("copiados al vault: %s" % VAULT)
    else:
        print("(no se encontro el vault, no se copio nada)")


if __name__ == "__main__":
    main()
