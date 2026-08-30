# -*- coding: utf-8 -*-
"""Lee los detalles de liquidacion de UMPG Window (editorial / publishing).

Equivalente a ada_lee.py pero para el lado de la obra, no de la grabacion.

Entrada : ~/MALO/UMPG PUBLISHING/<CODIGO>/*.TAB   (o los .zip sin descomprimir)
Salida  : /tmp/malopatch/umpg_filas.json

Diferencias con ADA que hay que respetar:
  - decimales con PUNTO (ADA usa coma)
  - encoding utf-8 con BOM
  - todos los campos con padding de espacios
  - numericos con signo y ceros a la izquierda: +00000000000.0560233
  - NO trae ISRC ni ISWC: la clave es "Cod. Cancion" (work code de UMPG)
  - liquidacion SEMESTRAL, y el devengo va aparte del periodo de pago
"""

import io, os, csv, json, glob, zipfile, collections

RAIZ = os.path.expanduser("~/MALO/UMPG PUBLISHING")
SALIDA = "/tmp/malopatch"

# El deal con UMPG. Va escrito en "Nombre del Cliente" (ej: "... (DISOBEY) 75/25").
# "% a Pagar" = share del autor en la obra * DEAL. Dividiendo se recupera el share.
DEAL_POR_DEFECTO = 0.75


def num(s):
    """+00000000000.0560233 -> 0.0560233 ; 026.2500 -> 26.25"""
    s = (s or "").strip().lstrip("+")
    if not s:
        return 0.0
    try:
        return float(s)
    except ValueError:
        return 0.0


def deal_del_nombre(nombre):
    """'Marcos ... (DISOBEY) 75/25' -> 0.75. Si no aparece, DEAL_POR_DEFECTO."""
    for trozo in (nombre or "").replace("/", " ").split():
        if trozo.isdigit() and 1 <= int(trozo) <= 100:
            return int(trozo) / 100.0
    return DEAL_POR_DEFECTO


def parte_procedencia(p):
    """'APPLE MUSIC - MEXICO' -> ('APPLE MUSIC', 'MEXICO')"""
    p = (p or "").strip()
    if " - " in p:
        fuente, terr = p.rsplit(" - ", 1)
        return fuente.strip(), terr.strip()
    return p, ""


def abre_tab(ruta):
    """Devuelve un file-like del .TAB, este suelto o dentro de un .zip."""
    if ruta.lower().endswith(".zip"):
        z = zipfile.ZipFile(ruta)
        tabs = [n for n in z.namelist() if n.lower().endswith(".tab")]
        if not tabs:
            return None  # "No hay detalle para este periodo"
        return io.TextIOWrapper(z.open(tabs[0]), encoding="utf-8-sig", errors="replace")
    return io.open(ruta, encoding="utf-8-sig", errors="replace")


def lee_fichero(ruta):
    fh = abre_tab(ruta)
    if fh is None:
        return []
    r = csv.reader(fh, delimiter="\t")
    try:
        cab = [c.strip() for c in next(r)]
    except StopIteration:
        return []
    ix = {c: i for i, c in enumerate(cab)}

    def g(p, c):
        i = ix.get(c)
        return p[i].strip() if i is not None and i < len(p) else ""

    cliente_dir = os.path.basename(os.path.dirname(ruta))
    filas = []
    for p in r:
        if len(p) < 5:
            continue
        nombre = g(p, "Nombre del Cliente")
        deal = deal_del_nombre(nombre)
        pct_pagar = num(g(p, "% a Pagar"))
        fuente, territorio = parte_procedencia(g(p, "Procedencia"))
        filas.append({
            "carpeta":       cliente_dir,
            "fichero":       os.path.basename(ruta),
            "cliente":       g(p, "Cliente Principal"),
            "subcuenta":     g(p, "Cod. Cliente"),
            "cliente_nombre": nombre,
            "deal":          deal,
            "obra":          g(p, "Cod. Canción"),
            "titulo":        g(p, "Título Canción"),
            "autor_trunc":   g(p, "Autor"),   # OJO: cortado a 40 chars, no fiarse
            "tipo_ingreso":  g(p, "Tipo Ingreso"),
            "subtipo":       g(p, "Subtipo de Ingresos"),
            "fuente":        fuente,
            "territorio":    territorio,
            "devengo_desde": g(p, "Devengo Desde"),
            "devengo_hasta": g(p, "Hasta"),
            "unidades":      num(g(p, "Unidades")),
            "pct_recibido":  num(g(p, "% Recibido")),
            "importe":       num(g(p, "Importe")),     # lo que recauda UMPG
            "royalties":     num(g(p, "Royalties")),   # lo que cobra el cliente
            "pct_pagar":     pct_pagar,
            # share del autor en la obra, deshaciendo el deal
            "share_obra":    round(pct_pagar / deal, 4) if deal else 0.0,
        })
    return filas


def main():
    if not os.path.isdir(RAIZ):
        print("No existe %s" % RAIZ)
        return

    rutas = sorted(glob.glob(os.path.join(RAIZ, "*", "*.TAB")))
    if not rutas:
        rutas = sorted(glob.glob(os.path.join(RAIZ, "*", "*.zip")))

    filas, vacios = [], []
    for ruta in rutas:
        f = lee_fichero(ruta)
        if f:
            filas.extend(f)
        else:
            vacios.append(os.path.basename(ruta))

    print("ficheros con datos :", len(set(x["fichero"] for x in filas)))
    print("ficheros vacios    :", len(vacios), vacios if vacios else "")
    print("filas              :", len(filas))
    if not filas:
        return

    print("clientes           :", sorted(set(x["cliente"] for x in filas)))
    print("obras distintas    :", len(set(x["obra"] for x in filas)))
    print("subtipos de ingreso:", sorted(set(x["subtipo"] for x in filas)))
    print("fuentes            :", sorted(set(x["fuente"] for x in filas)))
    print("devengos           :", sorted(set((x["devengo_desde"], x["devengo_hasta"]) for x in filas)))
    print()
    print("IMPORTE (recauda UMPG): %.4f" % sum(x["importe"] for x in filas))
    print("ROYALTIES (al cliente): %.4f" % sum(x["royalties"] for x in filas))
    print("UNIDADES              : %d" % sum(x["unidades"] for x in filas))

    # los shares deben salir redondos; si no, el deal esta mal deducido
    raros = sorted(set(x["share_obra"] for x in filas if abs(x["share_obra"] * 100 - round(x["share_obra"] * 100)) > 0.5))
    print("shares no redondos    :", raros if raros else "ninguno (deal correcto)")

    if not os.path.isdir(SALIDA):
        os.makedirs(SALIDA)
    with io.open(os.path.join(SALIDA, "umpg_filas.json"), "w", encoding="utf-8") as fh:
        fh.write(json.dumps(filas, ensure_ascii=False))
    print("\nguardado %s/umpg_filas.json" % SALIDA)


if __name__ == "__main__":
    main()
