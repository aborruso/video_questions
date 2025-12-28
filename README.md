# Project Overview

This project provides a script to fetch YouTube video subtitles and use them as a prompt for a language model.

## Requirements

The script requires the following commands to be installed:

- `yt-dlp` ([GitHub repository](https://github.com/yt-dlp/yt-dlp))
- `curl` ([Official website](https://curl.se/))
- `llm` (LLM command-line tool, [GitHub repository](https://llm.datasette.io/en/stable/))
- `jq` ([GitHub repository](https://github.com/stedolan/jq))

### Installing Dependencies

Choose the commands for your Linux distribution:

**Ubuntu/Debian:**

```bash
sudo apt install curl jq
pip3 install yt-dlp llm
```

**Fedora/RHEL:**

```bash
sudo dnf install curl jq
pip3 install yt-dlp llm
```

**Arch Linux:**

```bash
sudo pacman -S curl jq
pip3 install yt-dlp llm
```

Alternatively, run `make help_install` after cloning the repository to see these commands.

## LLM Configuration

The `llm` command-line tool is the core of this program. Before first use, you must configure an API key.

### Setting Up API Keys

Choose your preferred LLM provider:

**For OpenAI (GPT models):**

```bash
llm keys set openai
# Enter your API key when prompted
```

**For Anthropic (Claude models):**

```bash
# First install the Anthropic plugin
llm install llm-anthropic

# Then set your API key
llm keys set anthropic
# Enter your API key when prompted
```

**For other providers (Gemini, etc.):**

See the [LLM plugins directory](https://llm.datasette.io/en/stable/plugins/directory.html) for available providers.

### Verify LLM Setup

Test that llm is working correctly:

```bash
llm "Ten fun names for a pet pelican"
```

This uses the default gpt-4o-mini model. If this returns a response, your setup is complete.

To test with a specific model:

```bash
llm "Your question here" -m claude-3-5-sonnet-20241022
```

### LLM Documentation

The `llm` tool supports many providers and features:

- **GitHub Repository**: [https://github.com/simonw/llm](https://github.com/simonw/llm)
- **Documentation**: [https://llm.datasette.io/en/stable/](https://llm.datasette.io/en/stable/)
- **Setup Guide**: [https://llm.datasette.io/en/stable/setup.html](https://llm.datasette.io/en/stable/setup.html)
- **Templates**: [https://llm.datasette.io/en/stable/templates.html](https://llm.datasette.io/en/stable/templates.html)

## Installation

You have three main options to install and use this script.

### Option 1: Using Make (Recommended)

This is the easiest and recommended way to install the script.

1. Clone the repository:

```bash
git clone https://github.com/aborruso/video_questions.git
cd video_questions
```

2. Install dependencies (see [Installing Dependencies](#installing-dependencies) above)

3. Configure llm API keys (see [LLM Configuration](#llm-configuration) above)

4. Install the script using `make`:

```bash
make install
```

This will copy the script to `/usr/local/bin` and make it executable. The command will automatically use `sudo` if needed based on your permissions.

### Option 2: Run from Repository (No Install)

This is a good option if you want to easily receive updates and run the script from the repository folder.

1. Clone the repository to your local machine:

```bash
git clone https://github.com/aborruso/video_questions.git
cd video_questions
```

2. Install dependencies and configure llm (see sections above)

3. You can run the script directly from the `scripts` directory:

```bash
./scripts/qv.sh <YouTube URL> ...
```

### Option 3: Standalone Script

If you prefer to use `qv.sh` as a standalone command from anywhere on your system.

1. Download the script:

```bash
curl -o qv.sh -L https://raw.githubusercontent.com/aborruso/video_questions/main/scripts/qv.sh
```

2. Make it executable:

```bash
chmod +x qv.sh
```

3. Move it to a directory in your system's `PATH`. A common choice is `/usr/local/bin`:

```bash
sudo mv qv.sh /usr/local/bin/
```

4. Now you can run the script from any directory:

```bash
qv <YouTube URL> ...
```

#### Verify the script's integrity (Optional but recommended)

To ensure that the script you downloaded has not been tampered with, you can verify its SHA256 checksum.

1. Download the checksum file:

```bash
curl -o qv.sh.sha256 -L https://raw.githubusercontent.com/aborruso/video_questions/main/qv.sh.sha256
```

2. Verify the checksum:

```bash
sha256sum -c qv.sh.sha256
```

If the verification is successful, you will see the message: `qv.sh: OK`.

## Verify Installation

After installation, verify that everything works:

**Using Make:**

```bash
make test
```

**Manual test:**

```bash
qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only | head -5
```

If you see subtitle text, the installation is successful.

### Troubleshooting

**Error: command not found**
- Make sure `/usr/local/bin` is in your PATH
- Try running `./scripts/qv.sh` directly from the repository

**Error: yt-dlp/curl/jq/llm not installed**
- Run `make check_dependencies` to see which tools are missing
- Install missing dependencies using commands from [Installing Dependencies](#installing-dependencies)

**Warning: llm has no API keys configured**
- Follow steps in [LLM Configuration](#llm-configuration) section
- Run `llm keys path` to verify keys file location

## Usage

The basic syntax for the script is:

```bash
qv <YouTube URL> [<Question>] [OPTIONS]
```

### Arguments

- `<YouTube URL>`: (Required) The full URL of the YouTube video. Supported formats include `https://www.youtube.com/watch?v=VIDEO_ID`, `https://youtu.be/VIDEO_ID`, and `https://www.youtube.com/shorts/VIDEO_ID`.

- `<Question>`: (Optional) The question to ask about the video. If omitted, the script only outputs the subtitles (same as `--text-only`).

## Options

The script supports the following options:

- `-sub <filename>`: Save the extracted subtitles to a file.

- `-t, --template <template>`: Use a specific template for the LLM response.

- `--text-only`: Only download and display subtitles without processing with LLM. If you provide only a URL without a question, this mode is activated automatically.

- `-p language <language>`: Specify the response language (e.g., "Italian", "English").

- `--debug`: Show first 3 lines of content sent to LLM for debugging.

## Example Usage

```bash
# Example with English subtitles
qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What are the main topics covered in this video?'

# Save subtitles to a file
qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' -sub my_subtitles.txt

# Use a specific llm template for the response (https://llm.datasette.io/en/stable/templates.html)
qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' -t andy

# Just output the subtitles in stdout without asking questions
qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only

# Combine options: save subtitles and ask questions
qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is the main message?' -sub my_subtitles.txt

# Specify response language
qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is the main message?' -p language French

# Debug mode to see input to LLM
qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' 'What is this about?' --debug
```
