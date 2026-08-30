# -*- coding: utf-8 -*-
"""Recoge de ~/Downloads lo que se acaba de bajar de UMPG Window y lo archiva.

El problema que resuelve: UMPG descarga TODOS los extractos con el mismo nombre,
«magmedia.zip». Chrome los va numerando magmedia (1).zip, magmedia (2).zip… y a los
cinco minutos no hay forma de saber de quien es cada uno. Renombrarlos a mano
mientras se descargan es tedioso y facil de equivocar.

La solucion: NO fiarse del nombre del fichero. Abrir el zip y leer el codigo de
cliente de dentro (columna «Cliente Principal» del .TAB). El fichero se identifica
solo. Los de Obras si llevan el codigo en el nombre, asi que esos van directos.

Uso:
    python3 umpg_recoge.py              # archiva y deja los datos listos
    python3 umpg_recoge.py 2025-02      # si el periodo no es el ultimo

Despues:
    python3 umpg_obras.py       -> supabase/editorial-datos.sql
    python3 umpg_ingresos.py    -> supabase/editorial-ingresos.sql
    python3 umpg_resumen.py     -> CSVs en resumenes-vault/
"""

import io, os, re, sys, csv, glob, shutil, zipfile, datetime

DESCARGAS = os.path.expanduser("~/Downloads")
RAIZ = os.path.expanduser("~/MALO/UMPG PUBLISHING")


def periodo_por_defecto():
    """La editorial liquida por semestres, ~40 dias despues del cierre.

    Hoy         -> ultimo periodo disponible
    ago 2026    -> 2026-01 (ene-jun 2026, publicado ~9 ago)
    """
    h = datetime.date.today()
    if h.month >= 8:
        return "%d-01" % h.year          # el primer semestre ya esta publicado
    if h.month >= 2:
        return "%d-02" % (h.year - 1)    # el segundo del año anterior
    return "%d-01" % (h.year - 1)


def cliente_del_zip(ruta):
    """Abre el zip y lee el codigo de cliente de la primera fila de datos.

    Devuelve (codigo, filas) o (None, 0) si el periodo venia vacio.
    """
    try:
        z = zipfile.ZipFile(ruta)
    except zipfile.BadZipFile:
        return None, 0
    tabs = [n for n in z.namelist() if n.lower().endswith(".tab")]
    if not tabs:
        return None, 0                    # «No hay detalle para este periodo»
    fh = io.TextIOWrapper(z.open(tabs[0]), encoding="utf-8-sig", errors="replace")
    r = csv.reader(fh, delimiter="\t")
    try:
        cab = [c.strip() for c in next(r)]
    except StopIteration:
        return None, 0
    if "Cliente Principal" not in cab:
        return None, 0
    i = cab.index("Cliente Principal")
    cod, n = None, 0
    for fila in r:
        if len(fila) > i:
            n += 1
            if cod is None:
                cod = fila[i].strip()
    return cod, n


def main():
    periodo = sys.argv[1] if len(sys.argv) > 1 else periodo_por_defecto()
    if not re.match(r"^\d{4}-\d{2}$", periodo):
        print("Periodo raro: %s (esperaba AAAA-01 o AAAA-02)" % periodo)
        return
    print("Periodo: %s\n" % periodo)

    movidos, vacios, saltados = [], [], []

    # ── 1. extractos: el nombre no dice nada, hay que mirar dentro
    for ruta in sorted(glob.glob(os.path.join(DESCARGAS, "magmedia*.zip"))):
        cod, filas = cliente_del_zip(ruta)
        if not cod:
            vacios.append(os.path.basename(ruta))
            os.remove(ruta)
            continue
        destino = os.path.join(RAIZ, cod)
        if not os.path.isdir(destino):
            os.makedirs(destino)
        nz = os.path.join(destino, "%s_%s_detalle.zip" % (cod, periodo))
        shutil.move(ruta, nz)
        with zipfile.ZipFile(nz) as z:
            tab = [n for n in z.namelist() if n.lower().endswith(".tab")][0]
            with z.open(tab) as src, io.open(
                    os.path.join(destino, "%s_%s_detalle.TAB" % (cod, periodo)), "wb") as dst:
                shutil.copyfileobj(src, dst)
        movidos.append(("extracto", cod, filas))

    # ── 2. obras y reparto: estos si llevan el codigo en el nombre
    for patron, etiqueta in (("Works-Copyright-Splits-*.zip", "reparto"), ("Works-*.zip", "obras")):
        for ruta in sorted(glob.glob(os.path.join(DESCARGAS, patron))):
            base = os.path.basename(ruta)
            if etiqueta == "obras" and "Copyright-Splits" in base:
                continue
            m = re.search(r"-(AH[A-Z0-9]{2})-", base)
            if not m:
                saltados.append(base)
                continue
            cod = m.group(1)
            destino = os.path.join(RAIZ, cod)
            if not os.path.isdir(destino):
                os.makedirs(destino)
            shutil.move(ruta, os.path.join(destino, base))
            with zipfile.ZipFile(os.path.join(destino, base)) as z:
                z.extractall(destino)
            movidos.append((etiqueta, cod, ""))

    # ── informe
    if not movidos and not vacios:
        print("No habia nada de UMPG en ~/Downloads.")
        print("Baja del portal los extractos (Liquidaciones -> Detalle) o los")
        print("ficheros de Obras, y vuelve a ejecutar esto.")
        return

    for tipo, cod, filas in movidos:
        print("  %-9s %-6s %s" % (tipo, cod, ("%d filas" % filas) if filas else ""))
    if vacios:
        print("\n  %d zip sin datos (periodo vacio), borrados" % len(vacios))
    if saltados:
        print("\n  sin identificar: %s" % ", ".join(saltados))

    # ── que falta
    print("\n=== ESTADO POR CLIENTE ===")
    codigos = sorted(set(os.path.basename(d) for d in glob.glob(os.path.join(RAIZ, "AH*"))))
    falta = []
    for c in codigos:
        d = os.path.join(RAIZ, c)
        ext = bool(glob.glob(os.path.join(d, "*%s_detalle.TAB" % periodo)))
        obr = bool(glob.glob(os.path.join(d, "Works-%s-*.csv" % c)))
        rep = bool(glob.glob(os.path.join(d, "Works-Copyright-Splits-%s-*.csv" % c)))
        print("  %-6s extracto:%s  obras:%s  reparto:%s" % (
            c, "OK" if ext else "--", "OK" if obr else "--", "OK" if rep else "--"))
        if not ext:
            falta.append(c)
    if falta:
        print("\n  Sin extracto de %s: %s" % (periodo, ", ".join(falta)))
    else:
        print("\n  Todos los clientes completos para %s." % periodo)
    print("\nAhora: python3 umpg_ingresos.py  &&  python3 umpg_resumen.py")


if __name__ == "__main__":
    main()
