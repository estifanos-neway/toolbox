# LocalStack Setup

A Docker Compose configuration for running LocalStack with S3 and AWS Secrets Manager services, including automatic initialization scripts.

## Overview

This setup provides a local AWS cloud stack using [LocalStack](https://localstack.cloud/) with the following services:
- **S3** - Object storage service
- **Secrets Manager** - Secure storage for secrets and credentials

The setup automatically:
- Creates an S3 bucket on startup
- Loads secrets from the `secrets/` directory into AWS Secrets Manager

## Prerequisites

- Docker and Docker Compose installed
- AWS CLI installed (for interacting with LocalStack)

## Quick Start

1. **Start LocalStack:**
   ```bash
   docker compose up -d
   ```

   Or use the convenience script:
   ```bash
   ./init.sh
   ```

2. **Verify LocalStack is running:**
   ```bash
   docker ps
   ```

3. **Test the setup:**
   ```bash
   # List S3 buckets
   aws --endpoint-url=http://localhost:4666 s3 ls

   # List secrets
   aws --endpoint-url=http://localhost:4666 secretsmanager list-secrets --region us-east-1
   ```

## Configuration

### Environment Variables

You can customize the setup using environment variables:

- `S3_BUCKET_NAME` - Name of the S3 bucket to create (default: `localstack-bucket`)
- `AWS_DEFAULT_REGION` - AWS region (default: `us-east-1`)
- `AWS_ACCESS_KEY_ID` - AWS access key (default: `test`)
- `AWS_SECRET_ACCESS_KEY` - AWS secret key (default: `test`)
- `DEBUG` - Enable debug mode (default: `0`)
- `DATA_DIR` - LocalStack data directory (default: `/tmp/localstack/data`)

### Ports

- **4666** - Main LocalStack endpoint (mapped to host port 4666)
- **4510-4559** - Additional service ports (mapped to host ports 4610-4659)

### Using Environment File

You can uncomment the `env_file` section in `docker-compose.yml` and create a `.env` file to manage environment variables:

```yaml
env_file:
  - .env
```

## Secrets Management

### Adding Secrets

1. Place secret files in the `secrets/` directory
2. The filename (without extension) becomes the secret name in AWS Secrets Manager
3. The file content becomes the secret value

Example:
- File: `secrets/my-api-key.txt`
- Content: `sk_live_1234567890`
- Creates secret: `my-api-key` in Secrets Manager

### Secret File Format

- Any text file format is supported (`.txt`, `.md`, `.json`, etc.)
- The entire file content is stored as the secret value
- Hidden files (starting with `.`) are ignored

### Sample Secret

A sample secret file (`sample-secret.txt`) is included for reference. All other files in `secrets/` are ignored by git (see `.gitignore`).

## Usage Examples

### S3 Operations

```bash
# Create a bucket
aws --endpoint-url=http://localhost:4666 s3 mb s3://my-bucket

# Upload a file
aws --endpoint-url=http://localhost:4666 s3 cp file.txt s3://localstack-bucket/

# List objects
aws --endpoint-url=http://localhost:4666 s3 ls s3://localstack-bucket/

# Download a file
aws --endpoint-url=http://localhost:4666 s3 cp s3://localstack-bucket/file.txt ./
```

### Secrets Manager Operations

```bash
# Get a secret value
aws --endpoint-url=http://localhost:4666 secretsmanager get-secret-value \
  --secret-id my-api-key \
  --region us-east-1

# List all secrets
aws --endpoint-url=http://localhost:4666 secretsmanager list-secrets \
  --region us-east-1

# Create a new secret
aws --endpoint-url=http://localhost:4666 secretsmanager create-secret \
  --name my-new-secret \
  --secret-string "secret-value" \
  --region us-east-1
```

## Stopping LocalStack

```bash
docker compose down
```

To remove volumes (this will delete all data):
```bash
docker compose down -v
```

## Troubleshooting

### Check LocalStack logs
```bash
docker logs localstack-1
```

### Verify setup script ran
The setup script (`setup.sh`) runs automatically when LocalStack is ready. Check the logs to see if it executed successfully.

### Reset LocalStack
```bash
docker compose down -v
docker compose up -d
```

## Project Structure

```
LocalStack/
├── docker-compose.yml    # Docker Compose configuration
├── setup.sh              # Initialization script (runs on startup)
├── init.sh               # Convenience script to start LocalStack
├── .gitignore            # Git ignore rules
├── secrets/              # Secrets directory (gitignored except sample)
│   └── sample-secret.txt # Example secret file
└── README.md             # This file
```

## Notes

- LocalStack data persists in a Docker volume (`localstack-data`)
- The setup script runs automatically when LocalStack is ready
- Secrets are loaded from the `secrets/` directory on every startup
- If a secret already exists, it will be updated with the file content
