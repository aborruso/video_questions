#!/bin/bash

# Check for required dependencies
check_dependencies() {
  local dependencies=("yt-dlp" "curl" "llm")
  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo "Error: $dep is required but not installed."
      return 1
    fi
  done
  return 0
}

qv() {
  # Default values
  local language="Italian"
  local llm_options="-p language Italian"
  local url=""
  local question=""
  local sub_file=""
  local text_only=false
  local template=""

  # Manual parsing of arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--template)
        if [[ -n "$2" ]]; then
          template="$2"
          shift 2
        else
          echo "Error: -t/--template requires a template name."
          echo "Usage: qv <YouTube URL> <Question> [-p language <language>] [-sub <filename>] [-t <template>]"
          return 1
        fi
        ;;
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
      -t|--text-only)
        text_only=true
        shift
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

  # Check dependencies before proceeding
  if ! check_dependencies; then
    return 1
  fi

  # Validate required parameters
  if [ -z "$url" ] || ([ -z "$question" ] && [ "$text_only" = false ] && [ -z "$template" ]); then
    echo "Error: Missing parameters."
    echo
    echo "Usage: qv <YouTube URL> <Question> [-p language <language>] [-sub <filename>] [-t|--template <template>] [--text-only]"
    echo
    echo "Example:"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this video about?'"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this video about?' -p language Italian"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this video about?' -sub subtitles.txt"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' -t andy  # Usa il template 'andy'"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only  # Solo scarica i sottotitoli"
    return 1
  fi

  # Validate YouTube URL format
  if [[ ! "$url" =~ ^https://(www\.)?youtube\.(com/watch\?v=[a-zA-Z0-9_-]{11}|be/[a-zA-Z0-9_-]{11})(\?.*)?$ ]]; then
    # Try to extract video ID from youtu.be format
    if [[ "$url" =~ ^https://youtu\.be/([a-zA-Z0-9_-]{11}) ]]; then
      url="https://www.youtube.com/watch?v=${BASH_REMATCH[1]}"
    else
      echo "Error: Invalid YouTube URL format."
      echo "Please provide a YouTube URL in one of these formats:"
      echo "  https://www.youtube.com/watch?v=VIDEO_ID"
      echo "  https://youtu.be/VIDEO_ID"
      echo "Note: VIDEO_ID must be exactly 11 characters long"
      echo "URL provided: $url"
      return 1
    fi
  fi

  # Check if the subtitles file already exists and ask for confirmation to overwrite
  if [ -n "$sub_file" ] && [ -f "$sub_file" ]; then
    read -p "File $sub_file already exists. Overwrite? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Operation canceled. Subtitles were not saved."
      return 1
    fi
  fi

  # Fetch subtitle URL
  echo "Fetching subtitles for video..."
  local subtitle_url=$(yt-dlp -q --skip-download --convert-subs srt --write-sub --sub-langs "en" --write-auto-sub --print "requested_subtitles.en.url" "$url")
    
    if [ -z "$subtitle_url" ]; then
      echo "Error: Could not fetch subtitle URL."
      echo "This video might not have English subtitles available."
      return 1
    fi

    # Cache functions
    get_cache_dir() {
        echo "${HOME}/.qv_cache"
        mkdir -p "${HOME}/.qv_cache" 2>/dev/null
    }

    get_video_id() {
        echo "$1" | sed -nE \
            's/.*(?:v=|be\/)([a-zA-Z0-9_-]{11}).*/\1/p' | \
            head -n 1
    }

    clean_cache() {
        find "$(get_cache_dir)" -type f -mtime +7 -delete
    }

    # Check cache first
    clean_cache
    local video_id=$(get_video_id "$url")
    local cache_dir=$(get_cache_dir)
    local cache_file="${cache_dir}/${video_id}.txt"
    
    if [ -s "$cache_file" ]; then
        echo "Using cached subtitles..."
        local content=$(cat "$cache_file")
    else
        # Download and clean subtitles
        echo "Downloading and processing subtitles..."
        local content=$(curl -s "$subtitle_url" | \
    sed '/^$/d' | \
    grep -v '^[0-9]*$' | \
    grep -v -e '-->' -e '\[.*\]' | \
    sed 's/<[^>]*>//g' | \
    tr '\n' ' ' | \
    sed 's/  */ /g')

        # Save to cache if we have a valid video ID
        if [ -n "$video_id" ]; then
            echo "$content" > "$cache_file"
        fi
    fi  # Close the cache check if/else block

  # Validate content
  if [ -z "$content" ]; then
    echo "Error: Failed to retrieve or process video content."
    return 1
  fi

  # Check minimum content length
  if [ ${#content} -lt 100 ]; then
    echo "Warning: The retrieved content seems unusually short. The results might not be accurate."
  fi

  # Only show content in text-only mode
  if [ "$text_only" = true ]; then
    echo "$content"
    return 0
  fi

  # Save the subtitles to a specific file if requested
  if [ -n "$sub_file" ]; then
    echo "$content" > "$sub_file"
    echo "Subtitles saved to $sub_file"
  fi

  # Only show content in text-only mode
  if [ "$text_only" = true ]; then
    echo "$content"
    return 0
  fi

  # Only proceed with LLM processing if not in text-only mode
  if [ "$text_only" = false ]; then
    # Create a temporary file for the system prompt
    local temp_file=$(mktemp)
    
    # Escape special characters for YAML
    content=$(printf '%s' "$content" | \
      sed 's/"/\\"/g' | \
      sed "s/'/\\'/g" | \
      sed 's/\\/\\\\/g')

    local title=$(yt-dlp -q --skip-download --get-title "$url")
    
    # Build system prompt with improved formatting
    cat <<EOF > "$temp_file"
Sei un assistente utile che può rispondere a domande sui video di YouTube.

Scrivi il testo in ${language}.

Il titolo: $title
Il contenuto:
${content}

defaults:
  language: ${language}
EOF

    # Process the question with LLM using stdin
    echo "Processing your question..."
    if [ -n "$template" ]; then
      cat "$temp_file" | llm prompt "$question" $llm_options -t "$template"
    else
      cat "$temp_file" | llm prompt "$question" $llm_options
    fi
    
    # Clean up
    rm -f "$temp_file"
    
    if [ $? -ne 0 ]; then
      echo "Error: Failed to process the question."
      return 1
    fi
  fi
}

# Main script execution
main() {
  if [ "$#" -eq 0 ]; then
    qv
  else
    qv "$@"
  fi
}

main "$@"
