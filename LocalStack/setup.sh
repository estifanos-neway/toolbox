#!/bin/bash

# LocalStack setup script
# This script runs when LocalStack is ready and sets up:
# 1. S3 bucket
# 2. Secrets from the secrets folder into AWS Secrets Manager

set -e

# LocalStack endpoint
ENDPOINT="http://localhost:4566"
AWS_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# S3 bucket name (can be overridden via environment variable)
S3_BUCKET_NAME="${S3_BUCKET_NAME:-localstack-bucket}"

# Secrets directory
SECRETS_DIR="/opt/code/localstack/secrets"

echo "🚀 Starting LocalStack setup..."

# Configure AWS CLI to use LocalStack
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# Create S3 bucket
echo "📦 Creating S3 bucket: ${S3_BUCKET_NAME}"
aws --endpoint-url="${ENDPOINT}" s3 mb "s3://${S3_BUCKET_NAME}" --region "${AWS_REGION}" || {
    # Bucket might already exist, which is fine
    echo "⚠️  Bucket ${S3_BUCKET_NAME} might already exist, continuing..."
}

# Load secrets from secrets folder
if [ -d "${SECRETS_DIR}" ] && [ "$(ls -A ${SECRETS_DIR} 2>/dev/null | grep -v '^\.')" ]; then
    echo "🔐 Loading secrets from ${SECRETS_DIR}..."
    
    # Process each file in the secrets directory
    for secret_file in "${SECRETS_DIR}"/*; do
        # Skip if no files match the pattern
        [ -f "${secret_file}" ] || continue
        
        # Skip hidden files
        filename=$(basename "${secret_file}")
        [[ "${filename}" == .* ]] && continue
        
        # Get secret name from filename without extension
        secret_name="${filename%.*}"
        
        
        # Skip if secret name is empty
        [ -z "${secret_name}" ] && continue
        
        echo "  📝 Creating secret: ${secret_name}"
        
        # Read file content and create secret
        secret_value=$(cat "${secret_file}")
        
        # Create or update secret in Secrets Manager
        aws --endpoint-url="${ENDPOINT}" secretsmanager create-secret \
            --name "${secret_name}" \
            --secret-string "${secret_value}" \
            --region "${AWS_REGION}" 2>/dev/null || {
            # Secret might already exist, update it instead
            echo "    ⚠️  Secret ${secret_name} already exists, updating..."
            aws --endpoint-url="${ENDPOINT}" secretsmanager update-secret \
                --secret-id "${secret_name}" \
                --secret-string "${secret_value}" \
                --region "${AWS_REGION}" || {
                echo "    ❌ Failed to update secret: ${secret_name}"
            }
        }
    done
    
    echo "✅ Secrets loaded successfully"
else
    echo "ℹ️  No secrets found in ${SECRETS_DIR}, skipping..."
fi

echo "🎉 LocalStack setup completed!"
