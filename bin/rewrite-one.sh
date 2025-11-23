#!/usr/bin/env bash 
set -euo pipefail

MODEL="${MODEL:-gpt-5}"  # tu peux passer MODEL=... à l'exec
FILE="$1"
BASENAME="$(basename "$FILE")"
STEM="${BASENAME%.*}"

PROMPT="/Users/fdebuck/Scripts/NotesDeCours/Rewrite/PROMPT.txt"
TMPDIR="${TMPDIR:-/tmp}"
PAYLOAD="$TMPDIR/payload_${STEM}.json"
RESP_JSON="$TMPDIR/resp_${STEM}.json"

: "${OPENAI_API_KEY:?ERR: définis OPENAI_API_KEY}"
[ $# -eq 1 ] || { echo "Usage: $(basename "$0") <fichier.txt>"; exit 1; }
[ -f "$PROMPT" ] || { echo "ERR: $PROMPT introuvable"; exit 1; }

PROMPT_CONTENT="$(cat $PROMPT)"

# 1) Construire le payload Responses API
jq -Rs --arg model "$MODEL" --arg prompt "$PROMPT_CONTENT" --arg filename "$BASENAME" '
{
  "model": $model,
  "max_output_tokens": 16000,
  "input": [
    {"role":"system","content":[{"type":"input_text","text":$prompt}]},
    {"role":"user","content":[{"type":"input_text","text":("Nom de fichier: " + $filename + "\n\n" + .)}]}
  ]
}
' < "$FILE" > "$PAYLOAD"

# 2) Appel API + capture code HTTP + corps JSON
HTTP_CODE="$(
  curl -sS https://api.openai.com/v1/responses \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${OPENAI_API_KEY}" \
    -d @"$PAYLOAD" \
    -o "$RESP_JSON" \
    -w "%{http_code}"
)"

# 3) Gestion des erreurs HTTP
if [ "$HTTP_CODE" != "200" ]; then
  echo "ERR: HTTP $HTTP_CODE depuis /v1/responses"
  # Tente d’extraire le message d’erreur renvoyé par l’API
  if jq -e '.error' >/dev/null 2>&1 < "$RESP_JSON"; then
    echo "---- Détail erreur API ----"
    jq -r '.error.message // .error' < "$RESP_JSON"
    echo "---------------------------"
  else
    echo "---- Corps de réponse ----"
    head -c 2000 "$RESP_JSON"; echo
    echo "-------------------------"
  fi
  exit 1
fi

# 4) Extraction ROBUSTE du texte (plusieurs schémas possibles)
# - .output_text (helper dispo dans certains SDKs)
# - .output[]?.content[]? (nouveau schéma Responses)
# - .content[]? (autre variante Responses)
# - .choices[0].message.content (fallback type Chat Completions si jamais)
# 4) Extraction ROBUSTE du texte (type-safe)
TEXT="$(
  jq -r ' 
    def output_texts: 
      ( .output[]? 
        | select(type=="object") 
        | .content? 
        | select(type=="array")[]? 
        | select(type=="object" and .type=="output_text") 
        | .text 
      ), 
      ( .content? 
        | select(type=="array")[]? 
        | select(type=="object" and .type=="output_text") 
        | .text 
      ),
      ( .choices? | .[0]? | .message? | .content? 
        | select(type=="string") 
      ); 

    if .output_text then .output_text 
    else ( 
      [ output_texts ] 
      | map(select(type=="string")) 
      | unique 
      | join("\n") 
    ) 
    end 
  ' "$RESP_JSON"
)"


if [ -z "$TEXT" ] || [ "$TEXT" = "null" ]; then
  echo "ERR: impossible d’extraire le texte de la réponse JSON (format inattendu)."
  echo "---- Extrait JSON pour debug ----"
  head -c 2000 "$RESP_JSON"; echo
  echo "---------------------------------"
  exit 1
fi

# 5) Sauvegarde Markdown + conversion DOCX
echo "$TEXT" > "${STEM}.md"
pandoc -f markdown+lists_without_preceding_blankline "${STEM}.md" -t docx --reference-doc=custom-reference.docx -o "${STEM}.docx"


echo "Écrit: ${STEM}.docx"

