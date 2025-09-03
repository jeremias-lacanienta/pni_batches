#!/bin/bash
# Step 1: Setup Environment and Dependencies
# Creates virtual environment and installs required packages

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENVIRONMENT=${1:-dev}
VENV_DIR="$SCRIPT_DIR/.venv"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SETUP]${NC} ✅ $1"
}

log_warning() {
    echo -e "${YELLOW}[SETUP]${NC} ⚠️ $1"
}

log "🔧 Setting up Python environment and dependencies"

# Check Python 3 availability
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: python3 not found. Please install Python 3."
    exit 1
fi

log "🐍 Python 3 found: $(python3 --version)"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    log "📦 Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
    log_success "Virtual environment created at $VENV_DIR"
else
    log "📦 Virtual environment already exists at $VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"
log_success "Activated virtual environment"

# Upgrade pip
log "📋 Upgrading pip..."
pip install --upgrade pip

# Install required packages
log "📋 Installing required packages..."
pip install boto3 psycopg2-binary tabulate python-dateutil

log_success "All dependencies installed successfully"

# Verify installations
log "🔍 Verifying package installations..."
python3 -c "import boto3; print(f'✅ boto3: {boto3.__version__}')"
python3 -c "import psycopg2; print(f'✅ psycopg2: {psycopg2.__version__}')"
python3 -c "import tabulate; print(f'✅ tabulate: {tabulate.__version__}')"

log_success "Environment setup completed successfully"

# Show environment info
echo ""
log "📊 Environment Summary:"
log "   🔧 Environment: $ENVIRONMENT"
log "   🐍 Python: $(python3 --version)"
log "   📦 Virtual env: $VENV_DIR"
log "   📍 Working dir: $SCRIPT_DIR"

echo ""
log_success "Step 1 completed: Environment setup ready"
