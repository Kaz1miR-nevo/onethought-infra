# Local Development Without Docker or Kubernetes

## Overview

OneThought can be run entirely locally without Docker or Kubernetes. The application is a standard Next.js app that connects to Supabase for backend services.

## Prerequisites

- **Node.js** 18+ (v20 recommended)
- **npm** 9+
- **Git**

No Docker, Kubernetes, or cloud infrastructure required for local development.

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/your-org/onethought.git
cd onethought

# 2. Install dependencies
npm install

# 3. Setup environment
cp .env.local.example .env.local
# Edit .env.local with your Supabase credentials

# 4. Start development server
npm run dev
```

## Environment Configuration

### Default: Stage Environment

Local development uses the **STAGE** Supabase project by default:

```env
NEXT_PUBLIC_APP_ENV=local
NEXT_PUBLIC_SUPABASE_URL=https://cgiqlvscetphwvvffdlj.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-anon-key>
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL | Yes |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anonymous key | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (server-side) | For admin features |
| `NEXT_PUBLIC_APP_ENV` | Environment (local/stage/prod) | Yes |
| `NEXT_PUBLIC_SITE_URL` | Site URL | For auth redirects |

## NPM Scripts

### Development

```bash
npm run dev              # Start dev server (port 3000)
npm run dev:mobile       # Start with network access
npm run lint             # Run ESLint
npm run build            # Production build
npm run start            # Start production build
```

### Testing

```bash
npm run test             # Run all tests
npm run test:unit        # Unit tests only
npm run test:integration # Integration tests
npm run test:watch       # Watch mode
npm run test:coverage    # With coverage report
```

### Environment Management

```bash
npm run env:check        # Verify environment config
npm run migrate:stage    # Apply migrations to stage
npm run migrate:check    # Check migration status
```

## Bypassing Kubernetes Logic

The application automatically detects the environment and adjusts behavior:

### Environment Detection

```typescript
// lib/utils/env.ts
export const isLocal = process.env.NEXT_PUBLIC_APP_ENV === 'local';
export const isKubernetes = !!process.env.KUBERNETES_SERVICE_HOST;

// Use in application:
if (isLocal) {
  // Local development behavior
} else if (isKubernetes) {
  // Kubernetes-specific behavior
}
```

### Health Checks

In Kubernetes, health checks use `/api/health`. Locally, this endpoint still works but isn't required.

### Secrets

- **Local**: Environment variables from `.env.local`
- **Kubernetes**: AWS Secrets Manager via External Secrets Operator

The application code is identical; only the source of secrets differs.

## File Structure

```
onethought/
├── .env.local           # Local environment (git-ignored)
├── .env.local.example   # Template for local env
├── package.json         # Dependencies & scripts
├── app/                 # Next.js app directory
├── components/          # React components
├── lib/                 # Business logic
└── infra/              # Infrastructure (separate repo)
```

## Mobile Testing

Test on physical mobile devices:

```bash
# 1. Start server with network access
npm run dev:mobile

# 2. Get your local IP
./get-local-ip.sh  # Shows: http://192.168.1.x:3000

# 3. Open that URL on your mobile device
```

## Debugging

### VSCode

Add to `.vscode/launch.json`:

```json
{
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Next.js Debug",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "port": 9229,
      "cwd": "${workspaceFolder}"
    }
  ]
}
```

### Chrome DevTools

1. Start server: `npm run dev`
2. Open Chrome DevTools (F12)
3. Set breakpoints in Sources tab

### Server-side Debugging

```bash
NODE_OPTIONS='--inspect' npm run dev
# Open chrome://inspect in Chrome
```

## Common Issues

### Port 3000 in Use

```bash
lsof -i :3000
kill -9 <PID>
```

### Slow Startup

```bash
# Clear cache
rm -rf .next
npm run dev
```

### Module Not Found

```bash
rm -rf node_modules
npm install
```

### Environment Issues

```bash
npm run env:check
# Verify all required variables are set
```

## Comparison: Local vs Kubernetes

| Aspect | Local | Kubernetes |
|--------|-------|------------|
| Startup | `npm run dev` | Helm deploy |
| Secrets | `.env.local` | AWS Secrets Manager |
| Port | 3000 | ALB → 3000 |
| HTTPS | No (http) | Yes (ACM) |
| Scaling | Single instance | HPA (2-20 pods) |
| Logs | Console | Loki |
| Metrics | None | Prometheus |

## Production-like Testing

To test with production-like settings locally:

```bash
# Build production version
npm run build

# Start production server
npm run start
```

This uses the same optimizations as production but connects to your local/stage environment.

