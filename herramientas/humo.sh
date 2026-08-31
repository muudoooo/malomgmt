#!/bin/zsh
# MALO · prueba de HUMO: ejecuta cada vista con un DOM y una BD falsos.
#
# Por que existe: el pre-commit comprueba que index.html COMPILA. Pero ya han
# pasado a produccion dos fallos que compilaban de sobra:
#   · v0.030  «t.dataset.v» cuando la variable en ambito era «el»  → las pestañas
#             de Editorial no cambiaban (ReferenceError al pulsar)
#   · v0.039  «precioMedio» leia «unidades» una linea ANTES de declararla con
#             const → ReferenceError, la seccion Merch entera en blanco
# Los dos son identificadores validos: el parser los da por buenos y solo
# revientan al EJECUTARSE. Esto los ejecuta.
#
# Uso:  herramientas/humo.sh
set -e
cd "$(git rev-parse --show-toplevel)"

TMP=$(mktemp -t malo-humo).js
python3 - "$TMP" <<'PY'
import re, sys, io
h = io.open("index.html", encoding="utf-8").read()
bloques = re.findall(r'<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>', h, re.S)
io.open(sys.argv[1], "w", encoding="utf-8").write("\n".join(bloques))
PY

JSC=/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Helpers/jsc
[ -x "$JSC" ] || { echo "  !!  no encuentro jsc, me salto la prueba de humo"; exit 0; }

RUN=$(mktemp -t malo-humo-run).js
cat herramientas/humo.js > "$RUN"
cat "$TMP" >> "$RUN"
cat herramientas/humo-casos.js >> "$RUN"

RES=$("$JSC" "$RUN" 2>&1) || true
rm -f "$TMP" "$RUN"
echo "$RES"
echo "$RES" | grep -q "X " && exit 1
exit 0
