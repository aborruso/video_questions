#!/bin/bash

# Check for required dependencies
check_dependencies() {
  local dependencies=("yt-dlp" "curl" "llm" "jq")
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
  local url=""
  local question=""
  local sub_file=""
  local text_only=false
  local template=""
  local language=""
  local debug=false

  # Manual parsing of arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p)
        if [[ "$2" == "language" && -n "$3" ]]; then
          language="$3"
          shift 3
        else
          echo "Invalid option: -p $2"
          echo "Usage: qv <YouTube URL> <Question> [-p language <language>] [-sub <filename>]"
          return 1
        fi
        ;;
      -t|--template)
        if [[ -n "$2" ]]; then
          template="$2"
          shift 2
        else
          echo "Error: -t/--template requires a template name."
          echo "Usage: qv <YouTube URL> <Question> [-sub <filename>] [-t <template>]"
          return 1
        fi
        ;;
      -sub)
        if [[ -n "$2" ]]; then
          sub_file="$2"
          shift 2
        else
          echo "Error: -sub requires a file path."
          echo "Usage: qv <YouTube URL> <Question> [-sub <filename>]"
          return 1
        fi
        ;;
      -t|--text-only)
        text_only=true
        shift
        ;;
      --debug)
        debug=true
        shift
        ;;
      *)
        if [[ -z "$url" ]]; then
          url="$1"
        elif [[ -z "$question" ]]; then
          question="$1"
        else
          echo "Too many arguments."
          echo "Usage: qv <YouTube URL> <Question> [-sub <filename>]"
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
    echo "Usage: qv <YouTube URL> <Question> [-p language <language>] [-sub <filename>] [-t|--template <template>] [--text-only] [--debug]"
    echo
    echo "Example:"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this video about?'  # Ask a question about the video"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' -t andy  # Use a specific llm template"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this video about?' -p language Italian  # Get the answer in Italian"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only  # Output subtitles to stdout"
    echo "  qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this video about?' -sub subtitles.txt  # Save subtitles to a file"
    return 1
  fi

  # Gestione URL shorts
  # Se il formato è https://youtube.com/shorts/VIDEO_ID, lo converto in https://www.youtube.com/watch?v=VIDEO_ID
  if [[ "$url" =~ ^https://(www\.)?youtube\.com/shorts/([a-zA-Z0-9_-]{11}) ]]; then
    url="https://www.youtube.com/watch?v=${BASH_REMATCH[2]}"
  fi

  # Validate YouTube URL format
  # Ensure the provided URL is a valid YouTube link or convert short URLs to standard format
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

  # Extract Video ID for caching
  local video_id
  video_id=$(yt-dlp --get-id "$url" 2>/dev/null)
  if [[ -z "$video_id" ]]; then
    echo "Error: Could not extract video ID from URL '$url' for caching purposes."
    echo "Please ensure yt-dlp is working correctly and the URL is valid."
    return 1
  fi

  local cache_dir="${TMPDIR:-/tmp}/qv_cache"
  mkdir -p "$cache_dir" # Ensure cache directory exists

  # Clean up cache files older than 60 days
  find "$cache_dir" -type f -mtime +60 -delete

  local cache_file="${cache_dir}/${video_id}.txt"
  local content="" # Initialize content

  # Try to load from cache
  if [ -f "$cache_file" ] && [ -r "$cache_file" ]; then
    echo "Using cached subtitles from $cache_file"
    content=$(cat "$cache_file")
    # If cache is empty, treat as not found so it redownloads
    if [ -z "$content" ]; then
        echo "Cached file '$cache_file' is empty. Will attempt to re-download."
    fi
  fi

  # Check if the subtitles file already exists
  # If the user specifies a file for subtitles, confirm before overwriting an existing file
  if [ -n "$sub_file" ] && [ -f "$sub_file" ]; then
    read -p "File $sub_file already exists. Overwrite? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Operation canceled. Subtitles were not saved."
      return 1
    fi
  fi

  # If content is not loaded from cache (or cache was empty), then download
  if [ -z "$content" ]; then
    echo "Cached subtitles not found or empty. Downloading..."

    # Detect original audio language
    # Use yt-dlp to identify the original audio language of the video
    echo "Detecting original audio language..."
    local original_lang
    original_lang=$(yt-dlp -j "$url" | jq -r '.automatic_captions | keys[] | select(test("-orig"))' | sed 's/-orig//')

    # Try to fetch subtitles in the original language
    # Attempt to download subtitles in the detected original language
    local subtitle_url
    if [ -n "$original_lang" ]; then
      echo "Original audio language detected: $original_lang"
      subtitle_url=$(yt-dlp -q --skip-download --convert-subs srt --write-auto-sub --sub-langs "$original_lang" --print "requested_subtitles.$original_lang.url" "$url" 2>/dev/null)
    fi

    # If no subtitles in the original language, fallback to English
    # Attempt to download English subtitles if the original language subtitles are unavailable
    if [ -z "$subtitle_url" ]; then
      echo "Subtitles in original language not found, trying English..."
      subtitle_url=$(yt-dlp -q --skip-download --convert-subs srt --write-sub --sub-langs "en" --write-auto-sub --print "requested_subtitles.en.url" "$url" 2>/dev/null)
    fi

    # If no subtitles at all, try auto-generated subtitles in any available language
    # As a last resort, attempt to download auto-generated subtitles in any available language
    if [ -z "$subtitle_url" ]; then
      echo "English subtitles not found, trying auto-generated subtitles in any available language..."
      subtitle_url=$(yt-dlp -j "$url" | jq -r '.automatic_captions | to_entries[] | .value[] | select(.ext == "vtt") | .url' | head -n 1)
    fi

    # If still no subtitles, return an error
    # Exit with an error if no subtitles could be fetched
    if [ -z "$subtitle_url" ]; then
      echo "Error: Could not fetch subtitle URL."
      echo "This video might not have subtitles or auto-generated captions available."
      return 1
    fi

    # Download and clean subtitles
    # Fetch the subtitles from the URL and clean the content for further processing
    echo "Downloading and processing subtitles..."
    # 'content' variable is already declared, assign to it
    content=$(curl -s "$subtitle_url" | \
      sed '/^$/d' | \
      grep -v '^[0-9]*$' | \
      grep -v -e '-->' -e '\[.*\]' | \
      sed 's/<[^>]*>//g' | \
      tr '\n' ' ' | \
      sed 's/  */ /g')

    # If content was successfully fetched, save it to cache
    if [ -n "$content" ]; then
      echo "$content" > "$cache_file"
      echo "Subtitles cached to $cache_file"
    fi
  fi

  # Validate content
  # Ensure the fetched subtitles content is not empty
  if [ -z "$content" ]; then
    echo "Error: Failed to retrieve or process video content (from cache or download)."
    return 1
  fi

  # Check minimum content length
  # Warn the user if the subtitles content is unusually short
  if [ ${#content} -lt 100 ]; then
    echo "Warning: The retrieved content seems unusually short. The results might not be accurate."
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
    local temp_file
    temp_file=$(mktemp)

    # Get the video title
    local title
    title=$(yt-dlp -q --skip-download --get-title "$url")

    # Escape special characters for YAML
    content=$(printf '%s' "$content" | \
      sed 's/"/\\"/g' | \
      sed "s/'/\\'/g" | \
      sed 's/\\/\\\\/g')

    # Build system prompt with improved formatting
    if [ "$debug" = true ]; then
      cat <<EOF > "$temp_file"
You are a helpful assistant that can answer questions about YouTube videos.
${language:+Reply to me in $language}
Video title: $title
Content:
${content}
EOF
    else
      cat <<EOF > "$temp_file"
You are a helpful assistant that can answer questions about YouTube videos.
${language:+Reply to me in $language}
${content}
EOF
    fi

    # Process the question with LLM using stdin
    echo "Processing your question..."

    if [ "$debug" = true ]; then
      echo -e "\nDEBUG: First 3 lines sent to LLM:"
      head -n 3 "$temp_file"
      echo -e "\n"
      echo "DEBUG: Executing LLM command:"
      set -x
    fi

    if [ -n "$template" ]; then
      cat "$temp_file" | llm prompt "$question" -t "$template"
    else
      cat "$temp_file" | llm prompt "$question"
    fi

    if [ "$debug" = true ]; then
      set +x
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
  if [ "$#" -eq 1 ]; then
    echo "No question provided. Defaulting to --text-only mode."
    text_only=true
    qv "$1" --text-only
  elif [ "$#" -eq 0 ]; then
    echo "Error: Missing parameters. Defaulting to --text-only mode."
    text_only=true
    qv --text-only
  else
    qv "$@"
  fi
}

main "$@"
