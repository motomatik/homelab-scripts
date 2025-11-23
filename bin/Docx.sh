#!/usr/bin/env bash
# Description: Conversion de fichier markdown en docx. Utilise un custom reference s'il existe
# Usage: Docx.sh [-f] fichier.md

set -euo pipefail

f_flag=''

print_usage() {
  echo "Usage: $(basename "$0") [-f] <fichier.md>"
}

while getopts 'f' flag; do
  case "${flag}" in
    f) f_flag='true' ;;
    *) print_usage
       exit 1 ;;
  esac
done

shift "$((OPTIND - 1))"

if [ "$#" -lt 1 ]; then
  echo "ERR: fichier manquant"
  print_usage
  exit 1
fi

REALPATH="$(realpath "$1")"
FILE="$(basename "$REALPATH")"
DIR="$(dirname "$REALPATH")"

[ -f "$REALPATH" ] || { echo "ERR: $REALPATH introuvable"; exit 1; }

case "$FILE" in
  *.md) ;;
  *)
    echo "ERR: $FILE n'est pas un fichier markdown"
    exit 1
    ;;
esac

FILO="${FILE%.md}.docx"

if [ -f "$DIR/$FILO" ] && [ "$f_flag" != 'true' ]; then
  echo "ERR: Le fichier de sortie $DIR/$FILO existe déjà. Utiliser -f pour forcer"
  exit 1
fi

CUSTOM_REF="$DIR/custom-reference.docx"

# --- TEST DU FICHIER REFERENCE ---
if [ -f "$CUSTOM_REF" ]; then
  echo "Using custom reference docx: $CUSTOM_REF"
  pandoc -f markdown+lists_without_preceding_blankline \
         -t docx \
         --reference-doc="$CUSTOM_REF" \
         "$REALPATH" \
         -o "$DIR/$FILO"
else
  echo "INFO: Aucun fichier custom-reference.docx trouvé dans $DIR."
  echo "INFO: Génération du .docx avec le style Pandoc par défaut."
  pandoc -f markdown+lists_without_preceding_blankline \
         -t docx \
         "$REALPATH" \
         -o "$DIR/$FILO"
fi

