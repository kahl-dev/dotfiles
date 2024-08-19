#!/usr/bin/env bash

API_KEY="$OPENAI_API_TOKEN"
TEXT_TO_TRANSLATE="$1"
MODEL="gpt-4"
PROMPT="Translate the following text to from German to English or English to German: $TEXT_TO_TRANSLATE"

# echo -e "\nTEST\n\n\n" >>~/.dotfiles/alfred_scripts/log.txt

# Build the JSON payload
JSON_PAYLOAD=$(
	cat <<EOF
{
  "model": "$MODEL",
  "messages": [{"role": "user", "content": "$PROMPT"}],
  "max_tokens": 1000,
  "temperature": 0.5
}
EOF
)

# Construct the curl command
CURL_COMMAND="curl -s -X POST https://api.openai.com/v1/chat/completions \
  -H 'Authorization: Bearer $API_KEY' \
  -H 'Content-Type: application/json' \
  -d '$JSON_PAYLOAD'"

# Echo the curl command for debugging
# echo -e "Constructed curl command:\n$CURL_COMMAND" >>~/.dotfiles/alfred_scripts/log.txt

# Execute the curl command and capture the response
RESPONSE=$(eval $CURL_COMMAND)

# echo -e "$RESPONSE" >>~/.dotfiles/alfred_scripts/log.txt

TRANSLATION=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

# echo -e "$TRANSLATION" >>~/.dotfiles/alfred_scripts/log.txt
#
# echo -e "END" >>~/.dotfiles/alfred_scripts/log.txt

echo "$TRANSLATION"
