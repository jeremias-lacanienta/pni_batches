#!/bin/bash
# Prompt Group Migration Utility Runner
# Usage: ./99-prompt-group-migration.sh dev|prod

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
PYTHON_SCRIPT="$SCRIPT_DIR/99-prompt-group-migration.py"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[PROMPT-GROUP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PROMPT-GROUP]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[PROMPT-GROUP]${NC} ❌ $1"
}

if [ "$#" -lt 1 ]; then
  log_error "Usage: $0 dev|prod [--output filename] [--verbose]"
  exit 1
fi

# Activate virtual environment
if [ ! -d "$VENV_DIR" ]; then
    log_error "Virtual environment not found at $VENV_DIR"
    log "Please run 01-setup-environment.sh first"
    exit 1
fi

log "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

ENV="$1"
shift

log "Running prompt group migration for $ENV environment..."
python3 "$PYTHON_SCRIPT" "$ENV" "$@"
