#!/bin/bash
# Quick deployment script for prod environment (eu-west-1)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Deploying to PROD environment (eu-west-1)..."

# Call main deployment script with prod-specific parameters
"$SCRIPT_DIR/deploy-lambda.sh" deploy-single prod eu-west-1

echo "✅ PROD deployment complete!"
echo "🔗 Function name: prompt-group-migration-prod"
echo "🌎 Region: eu-west-1"
