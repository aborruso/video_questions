#!/usr/bin/env python3
import sys
import subprocess
import tempfile
import re
import os
import time
from typing import Optional

class QVProcessor:
    def __init__(self):
        self.language = "Italian"
        self.llm_options = ["-p", "language", "Italian"]
        self.sub_file: Optional[str] = None
        self.text_only = False
        self.template: Optional[str] = None

    def check_dependencies(self) -> bool:
        """Check if required commands are installed"""
        required = ["yt-dlp", "curl", "llm"]
        for cmd in required:
            try:
                subprocess.run([cmd, "--version"], 
                             stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL,
                             check=True)
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"Error: {cmd} is required but not installed.")
                return False
        return True

    def validate_youtube_url(self, url: str) -> bool:
        """Validate YouTube URL format"""
        youtube_regex = (
            r'^https://(www\.)?youtube\.(com/watch\?v=[a-zA-Z0-9_-]{11}|'
            r'be/[a-zA-Z0-9_-]{11})(\?.*)?$'
        )
        return re.match(youtube_regex, url) is not None

    def get_cache_dir(self) -> str:
        """Get cache directory path"""
        cache_dir = os.path.expanduser("~/.qv_cache")
        os.makedirs(cache_dir, exist_ok=True)
        return cache_dir

    def get_video_id(self, url: str) -> str:
        """Extract video ID from YouTube URL"""
        video_id = None
        # Try standard YouTube URL format
        match = re.search(r'(?:v=|be/)([a-zA-Z0-9_-]{11})', url)
        if match:
            video_id = match.group(1)
        return video_id

    def clean_cache(self) -> None:
        """Clean up old cache files"""
        cache_dir = self.get_cache_dir()
        now = time.time()
        for filename in os.listdir(cache_dir):
            filepath = os.path.join(cache_dir, filename)
            if os.path.isfile(filepath):
                # Delete files older than 7 days
                if now - os.path.getmtime(filepath) > 7 * 86400:
                    os.remove(filepath)

    def get_subtitles(self, url: str) -> str:
        """Fetch and process subtitles from YouTube video"""
        try:
            # Get video ID for cache
            video_id = self.get_video_id(url)
            if not video_id:
                raise ValueError("Could not extract video ID from URL")

            # Check cache first
            cache_dir = self.get_cache_dir()
            cache_file = os.path.join(cache_dir, f"{video_id}.txt")
            
            if os.path.exists(cache_file):
                print("Using cached subtitles...")
                with open(cache_file, 'r') as f:
                    return f.read()

            # Clean up old cache files
            self.clean_cache()

            # Get subtitle URL
            result = subprocess.run(
                ["yt-dlp", "-q", "--skip-download", "--convert-subs", "srt",
                 "--write-sub", "--sub-langs", "en", "--write-auto-sub",
                 "--print", "requested_subtitles.en.url", url],
                capture_output=True,
                text=True,
                check=True
            )
            subtitle_url = result.stdout.strip()
            
            if not subtitle_url:
                raise ValueError("Could not fetch subtitle URL")

            # Download subtitles
            curl_result = subprocess.run(
                ["curl", "-s", subtitle_url],
                capture_output=True,
                text=True,
                check=True
            )
            
            # Clean subtitles
            content = curl_result.stdout

            # Save to cache
            with open(cache_file, 'w') as f:
                f.write(content)
            lines = [
                line for line in content.splitlines()
                if line.strip() and 
                not re.match(r'^\d+$', line) and  # Remove line numbers
                not re.match(r'^[\d:,]+ --> [\d:,]+$', line) and  # Remove timestamps
                not re.match(r'^\[.*\]$', line)  # Remove [music] etc
            ]
            cleaned_content = ' '.join(lines)
            cleaned_content = re.sub(r'<[^>]*>', '', cleaned_content)  # Remove HTML tags
            cleaned_content = re.sub(r'\s+', ' ', cleaned_content)  # Normalize spaces
            
            if len(cleaned_content) < 100:
                print("Warning: The retrieved content seems unusually short. Results might not be accurate.")
            
            return cleaned_content
            
        except subprocess.CalledProcessError as e:
            print(f"Error: Failed to process video - {str(e)}")
            sys.exit(1)
        except ValueError as e:
            print(f"Error: {str(e)}")
            sys.exit(1)

    def process_with_llm(self, content: str, question: str, url: str) -> None:
        """Process content with LLM"""
        try:
            with tempfile.NamedTemporaryFile(mode='w', delete=True) as temp_file:
                # Get video title
                title_result = subprocess.run(
                    ["yt-dlp", "-q", "--skip-download", "--get-title", url],
                    capture_output=True,
                    text=True,
                    check=True
                )
                title = title_result.stdout.strip()

                # Prepare system prompt
                prompt = f"""Sei un assistente utile che può rispondere a domande sui video di YouTube.

Scrivi il testo in {self.language}.

Il titolo: {title}
Il contenuto:
{content}

defaults:
  language: {self.language}
"""
                temp_file.write(prompt)
                temp_file.flush()

                # Build LLM command
                llm_cmd = ["llm", "prompt", question] + self.llm_options
                if self.template:
                    llm_cmd.extend(["-t", self.template])

                # Process with LLM
                print("Processing your question...")
                with open(temp_file.name, 'r') as f:
                    subprocess.run(llm_cmd, stdin=f, check=True)
                
        except subprocess.CalledProcessError as e:
            print(f"Error: Failed to process question - {str(e)}")
            sys.exit(1)

    def run(self, url: str, question: Optional[str] = None) -> None:
        """Main processing function"""
        if not self.check_dependencies():
            sys.exit(1)

        if not self.validate_youtube_url(url):
            print("Error: Invalid YouTube URL format")
            sys.exit(1)

        if self.sub_file and os.path.exists(self.sub_file):
            confirm = input(f"File {self.sub_file} exists. Overwrite? (y/n): ")
            if confirm.lower() != 'y':
                print("Operation canceled")
                sys.exit(0)

        content = self.get_subtitles(url)

        if self.sub_file:
            try:
                with open(self.sub_file, 'w') as f:
                    f.write(content)
                print(f"Subtitles saved to {self.sub_file}")
            except IOError as e:
                print(f"Error saving subtitles: {str(e)}")

        if self.text_only:
            print(content)
            return

        if question:
            self.process_with_llm(content, question, url)
        elif self.template:
            self.process_with_llm(content, "", url)
        else:
            print("Error: Either a question or template must be provided")
            sys.exit(1)

def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Process YouTube videos and ask questions about their content"
    )
    parser.add_argument('url', help="YouTube video URL")
    parser.add_argument('question', nargs='?', help="Question to ask about the video")
    parser.add_argument('-p', nargs=2, metavar=('PARAM', 'VALUE'),
                       help="LLM parameter (e.g., 'language English')")
    parser.add_argument('-sub', metavar='FILE', 
                       help="Save subtitles to file")
    parser.add_argument('-t', '--template', 
                       help="Use specific LLM template")
    parser.add_argument('--text-only', action='store_true',
                       help="Only download subtitles without processing")

    args = parser.parse_args()

    processor = QVProcessor()
    
    if args.p:
        if args.p[0] == 'language':
            processor.language = args.p[1]
            processor.llm_options = ["-p", "language", args.p[1]]
        else:
            print(f"Error: Unsupported parameter '{args.p[0]}'")
            sys.exit(1)
    
    if args.sub:
        processor.sub_file = args.sub
        
    if args.template:
        processor.template = args.template
        
    if args.text_only:
        processor.text_only = True

    processor.run(args.url, args.question)

if __name__ == "__main__":
    main()
