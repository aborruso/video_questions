#!/bin/bash

qv() {
  # Default values
  local language="English"
  local llm_options=""

  # Manual parsing of arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p)
        if [[ "$2" == "language" && -n "$3" ]]; then
          language="$3"
          llm_options="-p language ${language}"
          shift 3
        else
          echo "Invalid option: -p $2 $3"
          echo "Usage: qv <YouTube URL> <Question> [-p language <language>]"
          return 1
        fi
        ;;
      *)
        if [[ -z "$url" ]]; then
          url="$1"
        elif [[ -z "$question" ]]; then
          question="$1"
        else
          echo "Too many arguments."
          echo "Usage: qv <YouTube URL> <Question> [-p language <language>]"
          return 1
        fi
        shift
        ;;
    esac
  done

  # Check if the required parameters are provided
  if [ -z "$url" ] || [ -z "$question" ]; then
    echo "Error: Missing parameters."
    echo "Usage: qv <YouTube URL> <Question> [-p language <language>]"
    echo "Example: qv 'https://www.youtube.com/watch?v=example' 'What is this video about?' -p language Italian"
    return 1
  fi

  # Fetch the URL content through Jina
  local subtitle_url=$(yt-dlp -q --skip-download --convert-subs srt --write-sub --sub-langs "en" --write-auto-sub --print "requested_subtitles.en.url" "$url")
  if [ -z "$subtitle_url" ]; then
    echo "Error: Could not fetch subtitle URL."
    return 1
  fi

  local content=$(curl -s "$subtitle_url" | sed '/^$/d' | grep -v '^[0-9]*$' | grep -v '\-->\|\[.*\]' | sed 's/<[^>]*>//g' | tr '\n' ' ')

  # Check if the content was retrieved successfully
  if [ -z "$content" ]; then
    echo "Failed to retrieve content from the URL."
    return 1
  fi

  # Escape double quotes in content to avoid YAML issues
  content=$(printf '%s' "$content" | sed 's/"/\\"/g')

  system="
  You are a helpful assistant that can answer questions about YouTube videos.

  Write the text in ${language}.

  The content:
  ${content}

  defaults:
    language: ${language}
  "

  # Use llm with the fetched content as a system prompt
  llm prompt "$question" -s "$system" $llm_options
}

# Check if the script is being called with arguments
if [ "$#" -eq 0 ]; then
  # If no arguments are provided, call the function without arguments to show the usage message
  qv
else
  # Otherwise, pass all arguments to the function
  qv "$@"
fi
