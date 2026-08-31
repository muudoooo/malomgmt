#!/bin/zsh
# MALO · sonda de la API de Enterticket
#
# PARA QUÉ: conseguir el token de la API y ver qué forma tienen de verdad los
# datos, para poder escribir la sincronización automática sin adivinar nombres
# de campos.
#
# LA CONTRASEÑA NO SALE DE TU ORDENADOR. Se pide por teclado (no se ve al
# escribir), se usa una sola vez para llamar a /auth y no se guarda en ningún
# sitio. El token sí se guarda, en ~/.enterticket-token, solo legible por ti.
#
# Uso:  zsh herramientas/enterticket/sonda.sh
#
# La API está documentada en https://api2.enterticket.es:4200/doc/ (pública).

set -e
API="https://api2.enterticket.es:4200"
TOK=~/.enterticket-token
OUT=~/enterticket-sonda

echo "── Enterticket · sonda ──────────────────────────────────────────"

if [ -f "$TOK" ] && [ -s "$TOK" ]; then
  echo "Uso el token que ya hay en $TOK"
else
  print -n "Usuario o email de Enterticket: "; read USUARIO
  print -n "Contraseña (no se verá): "; read -s CLAVE; echo
  echo "Pidiendo token a /auth…"
  RESP=$(curl -sS -G "$API/auth" --data-urlencode "email=$USUARIO" --data-urlencode "password=$CLAVE")
  unset CLAVE
  echo "$RESP" | python3 -c '
import json,sys
d=json.load(sys.stdin)
if d.get("error"):
    sys.exit("ERROR de Enterticket: %s"%d.get("errorDetalles"))
print(d["token"])
' > "$TOK"
  chmod 600 "$TOK"
  echo "$RESP" | python3 -c '
import json,sys
d=json.load(sys.stdin)
print("  token guardado · expira:", d.get("expira"))
for p in d.get("permisos",[]):
    print("  cliente", p.get("id_cliente"), "· ver ventas:", p.get("eventos_ventas_ver"), "· exportar bbdd:", p.get("bbdd_exportar"))
'
fi

T=$(cat "$TOK")
mkdir -p "$OUT"
llama(){ curl -sS -H "Authorization: Bearer $T" "$API$1" ; }

echo "Descargando muestras a $OUT …"
llama "/clientes" > "$OUT/clientes.json"
CID=$(python3 -c '
import json;d=json.load(open("'"$OUT"'/clientes.json"));r=d.get("resultados") or []
print(r[0]["id"] if r else "")')
echo "  clienteId = $CID"
[ -n "$CID" ] || { echo "No hay clientes visibles con este usuario."; exit 1; }

llama "/clientes/$CID/eventos?_limite=50&_orden=-id" > "$OUT/eventos.json"
EV=$(python3 -c '
import json;d=json.load(open("'"$OUT"'/eventos.json"));r=d.get("resultados") or []
print(r[0]["id"] if r else "")')
echo "  evento de muestra = $EV"

llama "/clientes/$CID/eventos/$EV/entradas"                    > "$OUT/entradas.json"
llama "/clientes/$CID/ventas/tickets?id_evento=$EV&_limite=3"  > "$OUT/tickets.json"
llama "/clientes/$CID/ventas?id_evento=$EV&_limite=3"          > "$OUT/ventas.json"
llama "/clientes/$CID/ventas/tickets/estadisticas/dia?id_evento=$EV" > "$OUT/est_dia.json"

echo
echo "── Qué campos trae cada cosa (solo nombres, ningún dato personal) ──"
python3 - "$OUT" <<'PY'
import json,sys,os
base=sys.argv[1]
for f in ("clientes","eventos","entradas","tickets","ventas","est_dia"):
    p=os.path.join(base,f+".json")
    try: d=json.load(open(p))
    except Exception as e: print(f"{f}: no se pudo leer ({e})"); continue
    if d.get("error"): print(f"{f}: ERROR {d.get('errorCodigo')} {d.get('errorDetalles')}"); continue
    r=d.get("resultados") or []
    print(f"\n{f}: {len(r)} resultados")
    if r and isinstance(r[0],dict):
        for k,v in r[0].items():
            t=type(v).__name__
            print(f"   {k:<28} {t}")
PY
echo
echo "Listo. Pásame el contenido de $OUT (son nombres de campo y datos de tus"
echo "propios eventos, sin datos personales de compradores)."
