#!/usr/bin/env bash

set -e

. ./openai.sh

messages=()

histories=($(cat ./.chat_history 2>/dev/null))

# load history to messages
messages+=("$(echo "${histories[*]}" | jq -src '.[]' )")

write_history() {
  if [[ "$1" != "null" && "$1" != "" ]]; then
    echo "$1" >>./.chat_history
    histories+=("$1")
  fi

  if [[ "$2" != "null" && "$2" != "" ]]; then
    echo "$2" >>./.chat_history
    histories+=("$2")
  fi
}

process_input() {
  input="$1"
  case "$input" in
  models | "models "*)
    eval models "${input:7}"
    ;;

  history)
    echo "${histories[*]}" | jq -src 'map("\u001b[34m\(.role):\u001b[0m \(.content)") | join("\n")'
    ;;

  clear)
    echo -ne '\033[2J\033[H'
    ;;

  "get "*)
    get "${input:4}"
    ;;

  exit)
    exit 0
    ;;

  !*)
    command="${input:1}"
    $SHELL -ic "$command"
    ;;

  "") ;;

  *)
    process_completions "$input"
    ;;
  esac
}

process_completions() {
  input="$1"

  query=$(jq -nc --arg content "$input" '{"role": "user", "content": $content}')
  messages+=("$query")

  message=$(completions gpt-3.5-turbo "$(echo "${messages[@]}" | jq -src '.')" | jq -rc '.choices[0].message')
  messages+=("$message")

  echo "$message" | jq -r '.content' | bat --language markdown --plain --unbuffered --wrap character

  write_history "$query" "$message"
}

while echo -en "\033[0;35m❯\033[0m " && read -r input; do
  process_input "$input"
done

