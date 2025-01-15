# Project Overview
This project provides a script to fetch YouTube video subtitles and use them as a prompt for a language model.

## Usage
To use the script, simply run it with the YouTube video URL and the question you want to ask.

## Requirements
The script requires the `yt-dlp` and `curl` commands to be installed.

## Installation
To install the required commands, run the following commands:
```bash
pip install yt-dlp
```
`curl` is usually pre-installed on most systems.

## Example Usage
```bash
# Example with an Italian culture video
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'Quali sono i principali temi trattati in questo video?' -p language Italian

# Example with English subtitles
qv.sh 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What are the main topics covered in this video?'
