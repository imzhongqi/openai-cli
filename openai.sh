#!/usr/bin/env bash

ENDPOINT=https://api.openai.com/v1

call() {
  if [[ -z "$OPENAI_KEY" ]]; then
    echo 'missing "OPENAI_KEY" environment variables'
    exit 1
  fi

  result=$(curl -s --url "${ENDPOINT}$1" -H "Authorization: Bearer $OPENAI_KEY" "${@:2}")

  if echo "$result" | jq -e 'has("error")' &>/dev/null; then
    echo -e "Error: $result" 1>&2
    exit 1
  fi

  echo "$result"
}

get() {
  call "$1" -H 'Content-Type: application/json' "${@:2}"
}

post() {
  if [[ -n "$DEBUG" ]]; then
    jq -n "$2" 1>&2
  fi

  call "$1" -X POST -H 'Content-Type: application/json' -d "$2" "${@:3}"
}

form_data() {
  call "$1" -X POST -H 'Content-Type: multipart/form-data' "${@:2}"
}

models() {
  get /models "${@:1}"
}

completions() {
  post /chat/completions "$(jq -nrc --arg model "$1" --argjson messages "$2" '{
    model: $model,
    messages: $messages,
    temperature: 1,
    presence_penalty: 0,
  }')" "${@:3}"
}

edits() {
  post /edits "$(jq -n --arg model "$1" --arg instruction "$2" --arg input "$3"  '{
    model: $model,
    input: $input,
    instruction: $instruction,
    temperature: 1
  }')"
}
