# OneThought CI/CD

## Overview

GitHub Actions workflows for automated testing, building, and deployment.

> **Note**: The actual workflow files are located in `.github/workflows/` in the repository root,
> not in this directory. This ensures GitHub Actions can discover and run them.

## Workflow Files Location

```
/.github/workflows/
├── deploy-stage.yml    # Deploy to stage on push to main
├── deploy-prod.yml     # Deploy to production on release
└── tests.yml           # Run tests on PR and push
```

## Workflow Descriptions

### `tests.yml`
- **Trigger**: Push/PR to main, stage, release branches
- **Purpose**: Run linting, type checking, build, and Helm chart validation
- **Jobs**:
  - Lint & Type Check
  - Unit Tests
  - Build Test
  - Helm Chart Lint

### `deploy-stage.yml`
- **Trigger**: Push to `main` branch
- **Purpose**: Deploy to stage environment
- **Jobs**:
  - Build & Test application
  - Build Docker image
  - Push to ECR (stage)
  - Deploy with Helm

### `deploy-prod.yml`
- **Trigger**: GitHub Release or push to `release` branch
- **Purpose**: Deploy to production
- **Jobs**:
  - Validate release
  - Build Docker image
  - Manual approval gate
  - Deploy with Helm
  - Automatic rollback on failure

## Setup Requirements

### GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCOUNT_ID` | AWS account ID |

### GitHub Environments

Create two environments in repository settings:

1. **stage**
   - No protection rules
   
2. **production**
   - Required reviewers
   - Optional: wait timer

### AWS OIDC

The Terraform configuration creates:
- OIDC identity provider for GitHub
- IAM roles: `onethought-stage-github-actions`, `onethought-prod-github-actions`

No static AWS credentials are stored in GitHub.

## Usage

### Deploy to Stage

Push to `main`:
```bash
git push origin main
```

### Deploy to Production

1. Create a GitHub Release
2. Wait for approval (if configured)
3. Deployment proceeds automatically

### Manual Deployment

Use workflow dispatch in GitHub Actions UI:
1. Go to Actions → Select workflow
2. Click "Run workflow"
3. Enter image tag
4. Run

## Local Testing

To test workflows locally (with `act`):

```bash
# Install act
brew install act

# Run tests workflow
act push -W .github/workflows/tests.yml
```

## Rollback

Production workflow includes automatic rollback on failure.

Manual rollback:
```bash
cd infra/scripts
./rollback.sh
```
