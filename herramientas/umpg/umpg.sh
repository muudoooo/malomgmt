#!/bin/zsh
# MALO · Editorial (UMPG) — la rutina entera, a peticion.
#
# No hay cron a proposito: no se sabe que dia entra la liquidacion, asi que se
# ejecuta esto cuando llega. Mismo criterio que en ADA.
#
# Antes de ejecutar: bajar del portal los extractos de los 8 clientes
# (Liquidaciones -> Detalle de la liquidacion). NO hace falta renombrar nada:
# todos se llaman magmedia.zip y el paso 1 los identifica leyendo dentro.
#
# Uso:  ./umpg.sh            (periodo automatico segun la fecha)
#       ./umpg.sh 2025-02    (un periodo concreto)

set -e
cd "$(dirname "$0")"

PERIODO="$1"

echo "═══ 1/4 · Archivando lo descargado ═══"
python3 umpg_recoge.py $PERIODO

echo
echo "═══ 2/4 · Ingresos → SQL ═══"
python3 umpg_ingresos.py

echo
echo "═══ 3/4 · Catálogo de obras → SQL ═══"
python3 umpg_obras.py

echo
echo "═══ 4/4 · Resúmenes → CSVs del vault ═══"
python3 umpg_resumen.py

REPO="$(cd ../.. && pwd)"
echo
echo "═══ LISTO ═══"
echo
echo "Para cargar en Supabase:"
echo "  pbcopy < $REPO/supabase/editorial-ingresos.sql"
echo "  (y si cambió el catálogo: $REPO/supabase/editorial-datos.sql)"
echo
echo "Pegar en el SQL Editor y Run. Es idempotente."
