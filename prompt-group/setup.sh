#!/bin/bash
# Setup script for prompt-group project
# Creates virtual environment and installs dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SETUP]${NC} ✅ $1"
}

log_error() {
    echo -e "${RED}[SETUP]${NC} ❌ $1"
}

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    log_error "Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    log "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
    log_success "Virtual environment created at $VENV_DIR"
else
    log "Virtual environment already exists at $VENV_DIR"
fi

# Activate virtual environment
log "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Upgrade pip
log "Upgrading pip..."
pip install --upgrade pip --quiet

# Install dependencies
if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    log "Installing Python dependencies..."
    pip install -r "$SCRIPT_DIR/requirements.txt" --quiet
    log_success "Dependencies installed successfully"
else
    log_error "requirements.txt not found"
    exit 1
fi

# Test the script
log "Testing prompt-group-migration script..."
if python "$SCRIPT_DIR/prompt-group-migration.py" --help > /dev/null 2>&1; then
    log_success "Script test passed"
else
    log_error "Script test failed"
    exit 1
fi

log_success "Setup completed successfully!"
echo ""
echo "To activate the virtual environment manually, run:"
echo "  source $VENV_DIR/bin/activate"
echo ""
echo "To test the script locally, run:"
echo "  python prompt-group-migration.py dev"
