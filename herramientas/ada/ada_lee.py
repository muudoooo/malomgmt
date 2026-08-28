import io, os, glob, json, collections

RAIZ = os.path.expanduser("~/MALO/ADA ROYALTIES")

def num(s):
    s = (s or "").strip().replace(".", "").replace(",", ".")
    if not s:
        return 0.0
    try:
        return float(s)
    except ValueError:
        return 0.0

filas = []
for f in sorted(glob.glob(os.path.join(RAIZ, "*", "Statement_*.txt"))):
    artista = os.path.basename(os.path.dirname(f))
    with io.open(f, encoding="utf-8", errors="replace") as fh:
        cab = fh.readline().rstrip("\n").split("\t")
        ix = {c: i for i, c in enumerate(cab)}
        for ln in fh:
            p = ln.rstrip("\n").split("\t")
            if len(p) < len(cab) - 2:
                continue
            def g(c):
                i = ix.get(c)
                return p[i] if i is not None and i < len(p) else ""
            filas.append({
                "cuenta_artista": artista,
                "fichero": os.path.basename(f),
                "mes_liq": g("Recdate Month ID"),
                "mes_venta": g("Repdate Month ID"),
                "isrc": g("ISRC").strip().upper(),
                "tema": g("Product Title").strip(),
                "proyecto": g("Project Title").strip(),
                "artista_credito": g("Artist Name").strip(),
                "cuenta": g("Account"),
                "payee": g("Payee").strip(),
                "dsp": g("Digital Service Provider(DSP)").strip(),
                "config": g("Config Desc").strip(),
                "unidades": num(g("Sale Units")),
                "bruto": num(g("Royalty Payable")),
                "fees": num(g("Deductible Fees")),
                "neto": num(g("Net Royalty Payable")),
            })

print("ficheros:", len(set(x["fichero"] for x in filas)))
print("filas:", len(filas))
print("meses de liquidacion:", sorted(set(x["mes_liq"] for x in filas)))
print("cuentas:", sorted(set((x["cuenta_artista"], x["cuenta"]) for x in filas)))
print("BRUTO TOTAL  : %.2f" % sum(x["bruto"] for x in filas))
print("FEES TOTAL   : %.2f" % sum(x["fees"] for x in filas))
print("NETO TOTAL   : %.2f" % sum(x["neto"] for x in filas))
print("UNIDADES     : %d" % sum(x["unidades"] for x in filas))
print("ISRC distintos:", len(set(x["isrc"] for x in filas if x["isrc"])))
print("filas sin ISRC:", sum(1 for x in filas if not x["isrc"]))

json.dump(filas, io.open("/tmp/malopatch/ada_filas.json", "w"), ensure_ascii=False)
print("guardado ada_filas.json")
