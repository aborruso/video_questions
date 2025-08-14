# Makefile for qv

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

.PHONY: install uninstall check_dependencies help

install: check_dependencies
	@echo "Installing qv to $(BINDIR)..."
	@install -m 755 scripts/qv.sh $(BINDIR)/qv
	@echo "qv installed successfully."

uninstall:
	@echo "Uninstalling qv from $(BINDIR)..."
	@rm -f $(BINDIR)/qv
	@echo "qv uninstalled successfully."

check_dependencies:
	@echo "Checking dependencies..."
	@command -v yt-dlp >/dev/null 2>&1 || (echo "yt-dlp is not installed. Please install it first."; exit 1)
	@command -v curl >/dev/null 2>&1 || (echo "curl is not installed. Please install it first."; exit 1)
	@command -v llm >/dev/null 2>&1 || (echo "llm is not installed. Please install it first."; exit 1)
	@command -v jq >/dev/null 2>&1 || (echo "jq is not installed. Please install it first."; exit 1)
	@echo "All dependencies are satisfied."

help:
	@echo "Usage: make [target]"
	@echo "Targets:"
	@echo "  install            Install qv"
	@echo "  uninstall          Uninstall qv"
	@echo "  check_dependencies Check for required dependencies"
	@echo "  help               Show this help message"
