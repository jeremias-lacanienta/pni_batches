#!/bin/bash
# Quick deployment script for dev environment (us-east-1)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Deploying to DEV environment (us-east-1)..."

# Call main deployment script with dev-specific parameters
"$SCRIPT_DIR/deploy-lambda.sh" deploy-single dev us-east-1

echo "✅ DEV deployment complete!"
echo "🔗 Function name: prompt-group-migration-dev"
echo "🌎 Region: us-east-1"
