# Makefile for qv

.PHONY: dev install uninstall check_dependencies test help_install help

dev:
	@echo "Setting up development environment..."
	@uv venv
	@uv pip install -e .
	@echo "Done. Activate with: source .venv/bin/activate"

install:
	@make check_dependencies
	@echo "Installing qv..."
	@uv tool install .
	@echo "qv installed successfully."

uninstall:
	@echo "Uninstalling qv..."
	@uv tool uninstall qv
	@echo "qv uninstalled."

check_dependencies:
	@echo "Checking dependencies..."
	@command -v yt-dlp >/dev/null 2>&1 || (echo "yt-dlp is not installed. Please install it first."; exit 1)
	@command -v uv >/dev/null 2>&1 || (echo "uv is not installed. See https://docs.astral.sh/uv/"; exit 1)
	@echo "All dependencies are satisfied."
	@keys_file=$$(llm keys path 2>/dev/null); \
	if [ ! -f "$$keys_file" ] || [ ! -s "$$keys_file" ]; then \
		echo ""; \
		echo "Warning: llm has no API keys configured."; \
		echo "Run 'llm keys set openai' or 'llm keys set anthropic' before using qv."; \
		echo "See: https://llm.datasette.io/en/stable/setup.html"; \
	fi

test:
	@echo "Testing qv..."
	@command -v qv >/dev/null 2>&1 || (echo "Error: qv not found. Run 'make install' first."; exit 1)
	@qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only | head -5
	@echo ""
	@echo "Test completed successfully!"

help_install:
	@echo "Installation commands for dependencies:"
	@echo ""
	@echo "yt-dlp:"
	@echo "  pip3 install yt-dlp"
	@echo ""
	@echo "uv:"
	@echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
	@echo ""
	@echo "After installing dependencies, configure llm:"
	@echo "  For OpenAI:   llm keys set openai"
	@echo "  For Anthropic: llm install llm-anthropic && llm keys set anthropic"
	@echo "  See: https://llm.datasette.io/en/stable/setup.html"
	@echo ""
	@echo "Then run: make install"

help:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  dev                Set up uv venv for development"
	@echo "  install            Install qv globally via uv tool"
	@echo "  uninstall          Uninstall qv"
	@echo "  check_dependencies Check for required dependencies"
	@echo "  test               Test qv installation"
	@echo "  help_install       Show dependency installation commands"
	@echo "  help               Show this help message"
