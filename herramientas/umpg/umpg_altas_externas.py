# -*- coding: utf-8 -*-
"""Da de alta en public.canciones las obras de UMPG que se distribuyeron FUERA de ADA.

De donde salen: son las obras del catalogo editorial que no estaban en la app ni en
ADA. Se buscaron en Deezer (umpg_buscar_isrc.py) y se recupero su ISRC, su release,
su fecha y su portada.

Como se sabe que no son de ADA: por el PREFIJO del ISRC, que identifica al
distribuidor que lo emitio. Las 118 canciones del catalogo actual empiezan todas por
«BK4DA» (ADA). Ninguna de estas lo hace: son QM/QZ/GB/UK, o sea otros distribuidores.

Entran con distribuidora = «Externa» para poder separarlas en la app sin inventar
ninguna columna nueva: el campo ya existia y hasta ahora solo tenia «ADA».

Salida: supabase/canciones-externas.sql   (NO se ejecuta solo)
"""

import io, os, csv, hashlib

AQUI = os.path.dirname(os.path.abspath(__file__))
TSV = os.path.join(AQUI, "isrc_encontrados.tsv")
CLIENTES = os.path.join(AQUI, "clientes_malo.tsv")
SALIDA = os.path.abspath(os.path.join(AQUI, "..", "..", "supabase", "canciones-externas.sql"))
REVISAR = os.path.join(AQUI, "revisar_externas.tsv")

# nombre artistico en Deezer -> como se llama en clientes
ALIAS = {"8belial": "8belial", "yyy891": "Ynestrosa", "roomtrash6": "roomtrash6",
         "cybernene": "cybernene", "aft3rlife": "Aft3rlife", "johnnyfuu": "JOHNNYFUU",
         "el wiwi": "El WiWi", "virtual flavor": "Virtual Flavor", "disobey": "DISOBEY",
         "nusar3000": "DISOBEY"}


def q(v):
    if v is None or v == "":
        return "null"
    return "'" + str(v).replace("'", "''") + "'"


def uid(pref, *p):
    return "%s_%s" % (pref, hashlib.sha1("|".join(p).encode("utf-8")).hexdigest()[:12])


def main():
    clientes = {}
    with io.open(CLIENTES, encoding="utf-8") as fh:
        for r in csv.DictReader(fh, delimiter="\t"):
            clientes[r["nombre"].strip().lower()] = r["id"].strip()

    filas = list(csv.DictReader(io.open(TSV, encoding="utf-8"), delimiter="\t"))
    altas, sin_cliente, descartadas = [], [], []

    for r in filas:
        isrc = (r.get("isrc") or "").strip()
        art = (r.get("artista_deezer") or "").strip()
        if not isrc or not art:
            descartadas.append((r, "sin ISRC en Deezer"))
            continue
        # solo si el artista es del roster: si no, es un tema de otro con el mismo titulo
        clave = next((k for k in ALIAS if k in art.lower()), None)
        if not clave:
            descartadas.append((r, "AUTORIA EXTERNA? el track en Deezer es de %s" % art))
            continue
        if isrc.startswith("BK4DA"):
            descartadas.append((r, "es de ADA, ya deberia estar"))
            continue
        cid = clientes.get(ALIAS[clave].lower())
        if not cid:
            sin_cliente.append(ALIAS[clave])
            continue
        altas.append({
            "id": uid("can", "umpg", r["cod_obra"]),
            # el titulo publicado si lo tenemos; si no, el que cataloga UMPG
            "titulo": (r.get("titulo_deezer") or "").strip() or r["titulo_umpg"].strip(),
            "titulo_umpg": r["titulo_umpg"].strip(),
            "artista_id": cid,
            "isrc": isrc,
            "mixtape": (r.get("album") or "").strip(),
            "fecha": (r.get("fecha_lanzamiento") or "").strip(),
            "portada": (r.get("portada") or "").strip(),
            "cod_obra": r["cod_obra"],
        })

    print("altas a generar : %d" % len(altas))
    print("descartadas     : %d" % len(descartadas))
    for r, m in descartadas[:8]:
        print("   %-30s %s" % (r["titulo_umpg"][:30], m))
    if len(descartadas) > 8:
        print("   ... y %d mas" % (len(descartadas) - 8))
    if sin_cliente:
        print("SIN ficha de cliente: %s" % sorted(set(sin_cliente)))

    # Los descartes NO se tiran: se dejan en un TSV para mirarlos a mano.
    #
    # El motivo de fondo: cuando el track que Deezer devuelve es de otro artista, el
    # caso interesante NO es que la busqueda fallara — es que un autor del roster haya
    # escrito para un tema de OTRO. Eso es autoria externa que la app no tiene fichada,
    # y es justo lo que este proyecto queria encontrar. Meterlo solo en un print se
    # perdia al cerrar la terminal.
    #
    # Siguen sin entrar solos en la base: hay que revisarlos y decidir uno por uno.
    with io.open(REVISAR, "w", encoding="utf-8") as fh:
        fh.write("motivo\tcod_obra\ttitulo_umpg\tartista_deezer\tisrc\talbum\tfecha\turl\n")
        for r, m in sorted(descartadas, key=lambda x: x[1]):
            fh.write("\t".join([
                m,
                r.get("cod_obra", ""), r.get("titulo_umpg", ""),
                r.get("artista_deezer", ""), r.get("isrc", ""),
                r.get("album", ""), r.get("fecha_lanzamiento", ""),
                r.get("url", "")]) + "\n")
    print("descartes para revisar -> %s" % REVISAR)
    externas = [x for x in descartadas if x[1].startswith("AUTORIA EXTERNA")]
    if externas:
        print("   de los cuales %d son posible AUTORIA EXTERNA (mirar primero)" % len(externas))

    L = ["-- Canciones distribuidas FUERA de ADA.",
         "--",
         "-- Son las obras del catalogo editorial que no estaban ni en la app ni en ADA.",
         "-- Se identificaron por el PREFIJO del ISRC: las 118 del catalogo actual empiezan",
         "-- todas por «BK4DA» (ADA) y ninguna de estas lo hace — salieron por otro",
         "-- distribuidor. ISRC, release, fecha y portada recuperados de la API de Deezer.",
         "--",
         "-- Entran con distribuidora = 'Externa' para poder separarlas en la app.",
         "-- fee_distribucion_pct = 0 a proposito: MALO no cobra fee de distribucion sobre",
         "-- lo que no distribuye. Revisar el mgmt_pct si en estas no aplica.",
         "-- Idempotente: ids deterministas y upsert por id.",
         "",
         "begin;",
         "",
         "insert into public.canciones",
         "  (id, titulo, artista_id, isrc, distribuidora, fee_distribucion_pct, mgmt_pct,",
         "   fecha_lanzamiento, mixtape, portada_url, notas) values"]
    filas_sql = []
    for a in altas:
        filas_sql.append("  (%s, %s, %s, %s, 'Externa', 0, 21, %s, %s, %s, %s)" % (
            q(a["id"]), q(a["titulo"]), q(a["artista_id"]), q(a["isrc"]),
            q(a["fecha"]) if a["fecha"] else "null",
            q(a["mixtape"]), q(a["portada"]),
            q("Obra UMPG %s%s. Distribuida fuera de ADA; ISRC y release de Deezer." % (
                a["cod_obra"],
                "" if a["titulo"].upper() == a["titulo_umpg"].upper()
                   else " (UMPG lo cataloga como «%s»)" % a["titulo_umpg"]))))
    L.append(",\n".join(filas_sql))
    L.append("on conflict (id) do update set")
    L.append("  isrc = excluded.isrc, mixtape = excluded.mixtape,")
    L.append("  portada_url = excluded.portada_url, fecha_lanzamiento = excluded.fecha_lanzamiento;")
    L.append("")
    L.append("-- y el puente con su obra editorial")
    L.append("insert into public.obra_canciones (obra_id, cancion_id, confianza) values")
    L.append(",\n".join("  ('%s', '%s', 'exacto')" % (uid("obr", a["cod_obra"]), a["id"]) for a in altas))
    L.append("on conflict (obra_id, cancion_id) do nothing;")
    L.append("")
    L.append("commit;")
    L.append("")
    L.append("select distribuidora, count(*) from public.canciones group by 1 order by 2 desc;")
    io.open(SALIDA, "w", encoding="utf-8").write("\n".join(L) + "\n")
    print("\ngenerado %s" % SALIDA)


if __name__ == "__main__":
    main()
