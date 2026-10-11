#!/usr/bin/env bash
set -euo pipefail

OWNER="revtriever-vera"
NUMBER="${1:-}"

if [ -z "$NUMBER" ]; then
  echo "uso: $0 <numero-do-project>  (o Project da org $OWNER já existe; este script não cria outro)" >&2
  exit 1
fi
echo "   project #$NUMBER"

EXISTING=$(gh project field-list "$NUMBER" --owner "$OWNER" --format json | python3 -c "import json,sys; print('\n'.join(f['name'] for f in json.load(sys.stdin)['fields']))")

field() {
  if grep -qxF "$1" <<< "$EXISTING"; then
    echo "   campo já existe: $1"
    return
  fi
  gh project field-create "$NUMBER" --owner "$OWNER" --name "$1" --data-type "$2" ${3:+--single-select-options "$3"} > /dev/null
  echo "   campo: $1"
}

echo "== campos"
field "Priority"  SINGLE_SELECT "P0 — agora,P1 — próxima,P2 — planejado,P3 — algum dia"
field "Size"      SINGLE_SELECT "XS — até 2h,S — meio dia,M — 1-2 dias,L — 3-5 dias,XL — quebrar em partes"
field "Area"      SINGLE_SELECT "Plataforma,Patrimônio,Gastos,Frontend,Infra,DX"
field "Target"    DATE
field "Spent (h)" NUMBER

echo "== vinculando repositórios"
for repo in vera vera-api vera-fe vera-observability; do
  gh project link "$NUMBER" --owner "$OWNER" --repo "$repo" > /dev/null && echo "   $repo"
done

echo
echo "Pronto: https://github.com/orgs/$OWNER/projects/$NUMBER"
echo "Ajuste as colunas de Status na UI (sugestão: Backlog · Refinement · Ready · In progress · In review · Done)."
