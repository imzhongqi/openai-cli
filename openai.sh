#!/usr/bin/env bash

ENDPOINT=https://api.openai.com/v1

function openai::call() {
  if [[ -z "$OPENAI_API_KEY" ]]; then
    echo 'missing "OPENAI_API_KEY" environment variables' 1>&2
    return 1
  fi

  result=$(curl -s --url "${ENDPOINT}$1" -H "Authorization: Bearer $OPENAI_API_KEY" "${@:2}")

  if echo "$result" | jq -e 'has("error")' &>/dev/null; then
    echo -e "Error: $result" 1>&2
    return 1
  fi

  echo "$result"
}

function openai::get() {
  openai::call "$1" -H 'Content-Type: application/json' "${@:2}"
}

function openai::delete() {
  openai::call "$1" -X DELETE -H 'Content-Type: application/json' "${@:2}"
}

function openai::post() {
  if [[ -n "$DEBUG" ]]; then
    jq -n "$2" 1>&2
  fi

  openai::call "$1" -X POST -H 'Content-Type: application/json' -d "$2" "${@:3}"
}

function openai::form_data() {
  openai::call "$1" -X POST -H 'Content-Type: multipart/form-data' "${@:2}"
}

function models() {
  openai::get /models "${@:1}"
}

function chat::completions() {
  openai::post /chat/completions "$(jq -nrc --arg model "$1" --argjson messages "$2" '{
    model: $model,
    messages: $messages,
    temperature: 1,
    presence_penalty: 0,
  }')" "${@:3}"
}

function edits() {
  openai::post /edits "$(jq -n --arg model "$1" --arg instruction "$2" --arg input "$3"  '{
    model: $model,
    input: $input,
    instruction: $instruction,
    temperature: 1
  }')"
}
