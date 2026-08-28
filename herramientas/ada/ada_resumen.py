import io, json, collections

filas = json.load(io.open("/tmp/malopatch/ada_filas.json"))

por_mes = collections.defaultdict(lambda: [0.0, 0.0, 0])
por_isrc = collections.defaultdict(lambda: [0.0, 0.0, 0, set(), set(), set()])
for x in filas:
    m = x["mes_liq"]
    por_mes[m][0] += x["bruto"]; por_mes[m][1] += x["neto"]; por_mes[m][2] += x["unidades"]
    k = x["isrc"] or "(SIN ISRC)"
    d = por_isrc[k]
    d[0] += x["bruto"]; d[1] += x["neto"]; d[2] += x["unidades"]
    d[3].add(x["tema"]); d[4].add(x["cuenta_artista"]); d[5].add(m)

print("=== BRUTO POR MES DE LIQUIDACION (lo que ADA reporto cada mes)")
tot = 0
for m in sorted(por_mes):
    b, n, u = por_mes[m]
    tot += b
    print("  %s  bruto %10.2f   neto %10.2f   unidades %12d" % (m, b, n, u))
print("  TOTAL      %10.2f" % tot)

print()
print("=== TOP 25 ISRC POR BRUTO")
orden = sorted(por_isrc.items(), key=lambda kv: -kv[1][0])
for k, d in orden[:25]:
    print("  %-14s %9.2f  %11d u  %d meses  %-32s %s" % (
        k, d[0], d[2], len(d[5]), sorted(d[3])[0][:32], ",".join(sorted(d[4]))))

json.dump({k: {"bruto": round(d[0], 4), "neto": round(d[1], 4), "unidades": d[2],
               "temas": sorted(d[3]), "cuentas": sorted(d[4]), "meses": sorted(d[5])}
           for k, d in por_isrc.items()},
          io.open("/tmp/malopatch/ada_por_isrc.json", "w"), ensure_ascii=False, indent=1)
json.dump({m: {"bruto": round(v[0], 4), "neto": round(v[1], 4), "unidades": v[2]}
           for m, v in por_mes.items()},
          io.open("/tmp/malopatch/ada_por_mes.json", "w"), ensure_ascii=False, indent=1)
print("\nguardados ada_por_isrc.json y ada_por_mes.json")
