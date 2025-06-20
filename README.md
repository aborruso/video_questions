# Project Overview

This project provides a script to fetch YouTube video subtitles and use them as a prompt for a language model.

## Usage

To use the script, simply run it with the YouTube video URL and the question you want to ask.

## Requirements

The script requires the following commands to be installed:

- `yt-dlp` ([GitHub repository](https://github.com/yt-dlp/yt-dlp))
- `curl` ([Official website](https://curl.se/))
- `llm` (LLM command-line tool, [GitHub repository](https://llm.datasette.io/en/stable/))
- `jq` ([GitHub repository](https://github.com/stedolan/jq))

### LLM Datasette CLI

The `llm` command-line tool is the core of this program. It allows you to interact with language models directly from the terminal. Below are some key features and links for more information:

- **GitHub Repository**: [https://github.com/simonw/llm](https://github.com/simonw/llm)
- **Documentation**: Detailed usage instructions and examples are available in the repository.
- **Installation**: Install via pip using the command `pip install llm`.

The `llm` tool is used in this script to process subtitles and generate responses based on the provided questions and templates.

## Options

The script supports the following options:

- `-sub <filename>`: Save the extracted subtitles to a file
- `-t` or `--template <template>`: Use a specific template for the LLM response
- `--text-only`: Only download and display subtitles without processing with LLM
- `-p language <language>`: Specify the response language (e.g., "Italian", "English")
- `--debug`: Show first 3 lines of content sent to LLM for debugging

## Example Usage

```bash
# Example with English subtitles
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What are the main topics covered in this video?'

# Save subtitles to a file
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' -sub my_subtitles.txt

# Use a specific template for the response
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' -t andy

# Just output the subtitles in stdout without asking questions
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only

# Combine options: save subtitles and ask questions
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is the main message?' -sub my_subtitles.txt

# Specify response language
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is the main message?' -p language French

# Debug mode to see input to LLM
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' --debug

