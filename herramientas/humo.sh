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

# mktemp portable: GNU/coreutils exige que la plantilla acabe en XXXXXX y con
# set -e abortaba el script antes incluso de mirar si hay motor de JavaScript,
# asi que en Linux el pre-commit lo leia como "una vista revienta" y cancelaba
# el commit. Un directorio temporal se comporta igual en macOS y en Linux.
DIR=$(mktemp -d "${TMPDIR:-/tmp}/malo-humo.XXXXXX")
trap 'rm -rf "$DIR"' EXIT INT TERM
TMP="$DIR/app.js"
python3 - "$TMP" <<'PY'
import re, sys, io
h = io.open("index.html", encoding="utf-8").read()
bloques = re.findall(r'<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>', h, re.S)
io.open(sys.argv[1], "w", encoding="utf-8").write("\n".join(bloques))
PY

# Con que ejecutarlo: node en cualquier sistema, jsc si estamos en un Mac. Sin
# ninguno de los dos no se puede EJECUTAR nada, asi que se avisa y se sigue: es
# una comprobacion de mas, no un requisito para poder commitear.
JSC=/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Helpers/jsc
if command -v node >/dev/null 2>&1; then
  MOTOR=node
elif [ -x "$JSC" ]; then
  MOTOR="$JSC"
else
  echo "  !!  sin node ni jsc: me salto la prueba de humo"
  echo "      (en Arch/CachyOS: sudo pacman -S nodejs)"
  exit 0
fi

RUN="$DIR/humo.js"
# jsc trae print() como funcion global; node no, y sin esto el arnes se cae con
# "ReferenceError: print is not defined" y el pre-commit lo lee como que una
# vista revienta. Va antes de todo y no pisa el print de jsc.
cat > "$RUN" <<'SHIM'
if (typeof globalThis.print !== "function") {
  globalThis.print = function () {
    console.log(Array.prototype.map.call(arguments, String).join(" "));
  };
}
SHIM
cat herramientas/humo.js >> "$RUN"
cat "$TMP" >> "$RUN"
cat herramientas/humo-casos.js >> "$RUN"

RES=$("$MOTOR" "$RUN" 2>&1) || true
echo "$RES"
echo "$RES" | grep -q "X " && exit 1
exit 0
