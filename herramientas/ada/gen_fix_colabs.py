import io, json, collections

filas = json.load(io.open("/tmp/malopatch/ada_filas.json"))

por = collections.defaultdict(lambda: {"bruto": 0.0, "neto": 0.0,
                                       "u": collections.defaultdict(int),
                                       "b": collections.defaultdict(float), "tema": set()})
for x in filas:
    if not x["isrc"]:
        continue
    d = por[(x["isrc"], x["mes_liq"])]
    d["bruto"] += x["bruto"]; d["neto"] += x["neto"]
    d["u"][x["cuenta_artista"]] += x["unidades"]
    d["b"][x["cuenta_artista"]] += x["bruto"]
    d["tema"].add(x["tema"])

# ISRC de colaboracion = lo reportan dos o mas cuentas de MALO
cuentas_isrc = collections.defaultdict(set)
for (isrc, mes), d in por.items():
    cuentas_isrc[isrc] |= set(d["b"].keys())
colabs = {i for i, c in cuentas_isrc.items() if len(c) >= 2}

def q(s):
    return "'" + str(s).replace("'", "''") + "'"

vals = []
for (isrc, mes), d in sorted(por.items()):
    if isrc not in colabs:
        continue
    u = max(d["u"].values()) if d["u"] else 0
    vals.append("(%s,%s,%.4f,%.4f,%d,%d)" % (q(isrc), q(mes), d["bruto"], d["neto"], u, len(d["b"])))

resumen = collections.defaultdict(lambda: [0.0, set(), set()])
for (isrc, mes), d in por.items():
    if isrc not in colabs:
        continue
    r = resumen[isrc]
    r[0] += d["bruto"]; r[1] |= set(d["b"].keys()); r[2] |= d["tema"]

cab = """-- ════════════════════════════════════════════════════════════════════════════
--  MALO · royalties de las colaboraciones                        28 ago 2026
-- ════════════════════════════════════════════════════════════════════════════
-- ADA manda un extracto por artista y en cada uno pone LA PARTE DE ESE ARTISTA,
-- no lo que genero el tema. Las unidades, en cambio, son las del tema completo y
-- vienen repetidas en todos los extractos, que es lo que despista.
--
-- Prueba: en SUPERGORDO, YYY891 cobra 1.527,74 y cybernene y roomtrash6 190,97
-- cada uno (80/10/10) con las MISMAS 1.364.366 unidades. Si el importe fuera del
-- tema completo seria identico en los tres, como pasa en RIRI (25/25/25/25).
--
-- En la app se cargo un solo extracto por tema, asi que en las colaboraciones
-- falta la parte de los demas. Y como el reparto entre participantes se aplica
-- DESPUES sobre ese bruto, cada artista salia con la cuarta parte de la cuarta
-- parte.
--
-- Solo se tocan los %d ISRC que reportan dos o mas cuentas. Los temas en
-- solitario se dejan como estan: cuadran al centimo con los extractos.
""" % len(colabs)

sql = [cab]
sql.append("CREATE TEMP TABLE ada_colab(isrc text, mes text, bruto numeric, neto numeric,")
sql.append("  unidades bigint, cuentas int, PRIMARY KEY (isrc,mes)) ON COMMIT DROP;")
sql.append("INSERT INTO ada_colab VALUES\n" + ",\n".join(vals) + ";")
sql.append("""
CREATE TEMP TABLE toca AS
SELECT i.id, c.titulo, to_char(i.mes,'YYYY-MM') AS mes,
       coalesce((regexp_match(i.canal,'B[KQ][A-Z0-9]{10,12}'))[1], c.isrc) AS isrc,
       i.bruto AS antes, i.unidades AS u_antes
FROM cancion_ingresos i JOIN canciones c ON c.id=i.cancion_id;
""")
mira = "\n".join(sql) + """
-- Lo que cambiaria, por cancion
SELECT t.titulo, t.isrc, max(a.cuentas) AS artistas_malo,
       round(sum(t.antes),2) AS bruto_ahora, round(sum(a.bruto),2) AS bruto_correcto,
       round(sum(a.bruto)-sum(t.antes),2) AS suma
FROM toca t JOIN ada_colab a ON a.isrc=t.isrc AND a.mes=t.mes
GROUP BY 1,2 ORDER BY 6 DESC;
"""
io.open("/tmp/malopatch/colabs_mira.sql", "w", encoding="utf-8").write(mira)

aplica = "\n".join(sql) + """
BEGIN;
CREATE SCHEMA IF NOT EXISTS respaldo;
DROP TABLE IF EXISTS respaldo.ingresos_antes_colabs;
CREATE TABLE respaldo.ingresos_antes_colabs AS SELECT * FROM cancion_ingresos;

UPDATE cancion_ingresos i
SET bruto    = a.bruto,
    unidades = greatest(coalesce(i.unidades,0), a.unidades)
FROM toca t JOIN ada_colab a ON a.isrc=t.isrc AND a.mes=t.mes
WHERE i.id = t.id AND a.bruto > i.bruto + 0.005;
COMMIT;

SELECT 'bruto total' AS control, round(sum(bruto),2)::text AS valor FROM cancion_ingresos
UNION ALL SELECT 'unidades', sum(unidades)::text FROM cancion_ingresos
UNION ALL SELECT 'filas', count(*)::text FROM cancion_ingresos;
"""
io.open("/tmp/malopatch/colabs_aplica.sql", "w", encoding="utf-8").write(aplica)

print("ISRC de colaboracion:", len(colabs))
print("pares (isrc,mes):", len(vals))
print()
print("%-32s %-14s %-42s %10s" % ("TEMA", "ISRC", "ARTISTAS MALO", "BRUTO OK"))
for isrc, r in sorted(resumen.items(), key=lambda kv: -kv[1][0]):
    print("%-32s %-14s %-42s %10.2f" % (sorted(r[2])[0][:32], isrc, ",".join(sorted(r[1])), r[0]))
print("TOTAL correcto de las colaboraciones: %.2f" % sum(r[0] for r in resumen.values()))
