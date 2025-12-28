# Makefile for qv

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

.PHONY: install uninstall check_dependencies test help_install help

install:
	@make check_dependencies
	@echo "Installing qv to $(BINDIR)..."
	@if [ -w "$(BINDIR)" ]; then \
		install -m 755 scripts/qv.sh $(BINDIR)/qv; \
	else \
		sudo install -m 755 scripts/qv.sh $(BINDIR)/qv; \
	fi
	@echo "qv installed successfully."

uninstall:
	@echo "Uninstalling qv from $(BINDIR)..."
	@if [ -w "$(BINDIR)" ]; then \
		rm -f $(BINDIR)/qv; \
	else \
		sudo rm -f $(BINDIR)/qv; \
	fi
	@echo "qv uninstalled successfully."

check_dependencies:
	@echo "Checking dependencies..."
	@command -v yt-dlp >/dev/null 2>&1 || (echo "yt-dlp is not installed. Please install it first."; exit 1)
	@command -v curl >/dev/null 2>&1 || (echo "curl is not installed. Please install it first."; exit 1)
	@command -v llm >/dev/null 2>&1 || (echo "llm is not installed. Please install it first."; exit 1)
	@command -v jq >/dev/null 2>&1 || (echo "jq is not installed. Please install it first."; exit 1)
	@echo "All dependencies are satisfied."
	@keys_file=$$(llm keys path 2>/dev/null); \
	if [ ! -f "$$keys_file" ] || [ ! -s "$$keys_file" ]; then \
		echo ""; \
		echo "Warning: llm has no API keys configured."; \
		echo "Run 'llm keys set openai' or 'llm keys set anthropic' before using qv."; \
		echo "See: https://llm.datasette.io/en/stable/setup.html"; \
	fi

test:
	@echo "Testing qv installation..."
	@command -v qv >/dev/null 2>&1 || (echo "Error: qv not found. Run 'make install' first."; exit 1)
	@echo "Downloading test video subtitles..."
	@qv 'https://www.youtube.com/watch?v=OM6XIICm_qo' --text-only | head -5
	@echo ""
	@echo "Test completed successfully!"

help_install:
	@echo "Installation commands for dependencies:"
	@echo ""
	@echo "Ubuntu/Debian:"
	@echo "  sudo apt install curl jq"
	@echo "  pip3 install yt-dlp llm"
	@echo ""
	@echo "Fedora/RHEL:"
	@echo "  sudo dnf install curl jq"
	@echo "  pip3 install yt-dlp llm"
	@echo ""
	@echo "Arch Linux:"
	@echo "  sudo pacman -S curl jq"
	@echo "  pip3 install yt-dlp llm"
	@echo ""
	@echo "After installing dependencies, configure llm:"
	@echo "  For OpenAI:"
	@echo "    llm keys set openai"
	@echo "  For Anthropic Claude:"
	@echo "    llm install llm-anthropic"
	@echo "    llm keys set anthropic"
	@echo ""
	@echo "Then run: make install"

help:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  install            Install qv"
	@echo "  uninstall          Uninstall qv"
	@echo "  check_dependencies Check for required dependencies"
	@echo "  test               Test qv installation"
	@echo "  help_install       Show distribution-specific installation commands"
	@echo "  help               Show this help message"