#!/bin/bash

qv() {
  # Default values
  local language="Italian"
  local llm_options="-p language Italian"

  # Manual parsing of arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p)
        if [[ "$2" == "language" && -n "$3" ]]; then
          language="$3"
          llm_options="-p language ${language}"
          shift 3
        else
          echo "Invalid option: -p $2"
          echo "Usage: qv <YouTube URL> <Question> [-p language <language>] [-sub <filename>]"
          return 1
        fi
        ;;
      -sub)
        if [[ -n "$2" ]]; then
          sub_file="$2"
          shift 2
        else
          echo "Error: -sub requires a file path."
          echo "Usage: qv <YouTube URL> <Question> [-p language <language>] [-sub <filename>]"
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
          echo "Usage: qv <YouTube URL> <Question> [-p language <language>] [-sub <filename>]"
          return 1
        fi
        shift
        ;;
    esac
  done

  # Check if the required parameters are provided
  if [ -z "$url" ] || [ -z "$question" ]; then
    echo "Error: Missing parameters."
    echo "Usage: qv <YouTube URL> <Question> [-p language <language>] [-sub <filename>]"
    echo "Example: qv 'https://www.youtube.com/watch?v=example' 'What is this video about?' -p language Italian -sub subtitles.txt"
    return 1
  fi

  # Check if the subtitles file already exists and ask for confirmation to overwrite
  if [ -n "$sub_file" ] && [ -f "$sub_file" ]; then
    read -p "File $sub_file already exists. Overwrite? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Operation canceled. Subtitles were not saved."
      return 1
    fi
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

  # Save the subtitles to a file if requested
  if [ -n "$sub_file" ]; then
    echo "$content" > "$sub_file"
    echo "Subtitles saved to $sub_file"
  fi

  # Escape double quotes in content to avoid YAML issues
  content=$(printf '%s' "$content" | sed 's/"/\\"/g')

  local title=$(yt-dlp -q --skip-download --get-title "$url")
  system="
  Sei un assistente utile che può rispondere a domande sui video di YouTube.

  Scrivi il testo in ${language}.

  Il titolo: $title
  Il contenuto:
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
