# Project Overview
This project provides a script to fetch YouTube video subtitles and use them as a prompt for a language model.

## Usage
To use the script, simply run it with the YouTube video URL and the question you want to ask.

## Requirements
The script requires the following commands to be installed:
- `yt-dlp`
- `curl`
- `llm` (LLM command-line tool)

## Installation
To install the required commands:

1. Install yt-dlp:
```bash
pip install yt-dlp
```

2. Install llm CLI tool:
```bash
pip install llm
```

3. Install curl (if not already installed):
```bash
# On Debian/Ubuntu
sudo apt install curl

# On macOS (with Homebrew)
brew install curl
```

4. Verify installations:
```bash
yt-dlp --version
llm --version
curl --version
```

## Options

The script supports the following options:

- `-p language <language>`: Specify the language for the response (e.g., "Italian", "English")
- `-sub <filename>`: Save the extracted subtitles to a file
- `-t` or `--template <template>`: Use a specific template for the LLM response
- `--text-only`: Only download and display subtitles without processing with LLM

## Example Usage
```bash
# Example with Italian language response
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What are the main topics covered in this video?' -p language Italian

# Example with English subtitles
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What are the main topics covered in this video?'

# Save subtitles to a file
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' -sub my_subtitles.txt

# Use a specific template for the response
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' -t andy

# Just download subtitles without asking questions
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only

# Combine options: save subtitles and ask in Italian
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'Qual è il messaggio principale?' -p language Italian -sub my_subtitles.txt
