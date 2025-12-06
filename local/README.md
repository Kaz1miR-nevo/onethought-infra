# Local Development Guide

## Overview

This guide explains how to run OneThought locally without Docker or Kubernetes.

## Prerequisites

- Node.js 18+ (20 recommended)
- npm 9+
- Git

## Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/your-org/onethought.git
cd onethought

# Run setup script
./infra/local/setup-local.sh
```

### 2. Configure Environment

Copy the example environment file:
```bash
cp infra/local/.env.local.example .env.local
```

Update `.env.local` with your Supabase credentials:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 3. Start Development Server

```bash
npm run dev
```

Open http://localhost:3000 in your browser.

## Development Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server on port 3000 |
| `npm run dev:mobile` | Start with network access (for mobile testing) |
| `npm run build` | Build for production |
| `npm run start` | Start production build locally |
| `npm run lint` | Run ESLint |
| `npm run test` | Run all tests |
| `npm run test:unit` | Run unit tests only |
| `npm run test:watch` | Run tests in watch mode |

## Environment Configuration

### Local Environment

Local development uses the **STAGE** Supabase instance by default. This is safe for development and testing.

```env
NEXT_PUBLIC_APP_ENV=local
NEXT_PUBLIC_SUPABASE_URL=https://cgiqlvscetphwvvffdlj.supabase.co
```

### Switching Environments

To test with different environments, update `.env.local`:

```env
# For stage
NEXT_PUBLIC_APP_ENV=stage

# For production (⚠️ Use with caution!)
# NEXT_PUBLIC_APP_ENV=prod
```

## Project Structure

```
onethought/
├── app/                 # Next.js app directory
│   ├── api/            # API routes
│   ├── (routes)/       # Page routes
│   └── layout.tsx      # Root layout
├── components/         # React components
├── lib/               # Utility functions
│   ├── actions/       # Server actions
│   ├── security/      # Security utilities
│   └── supabase/      # Supabase client & migrations
├── locales/           # i18n translations
├── public/            # Static assets
└── types/             # TypeScript types
```

## Debugging

### VSCode Debug Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Next.js: debug",
      "type": "node-terminal",
      "request": "launch",
      "command": "npm run dev"
    }
  ]
}
```

### Chrome DevTools

1. Open Chrome DevTools (F12)
2. Go to Sources tab
3. Use breakpoints in your code

### Server-Side Debugging

```bash
NODE_OPTIONS='--inspect' npm run dev
```

Then connect Chrome DevTools to `chrome://inspect`.

## Common Issues

### Port Already in Use

```bash
# Find and kill process on port 3000
lsof -i :3000
kill -9 <PID>
```

### Node Modules Issues

```bash
# Clean reinstall
rm -rf node_modules .next
npm install
```

### Environment Not Loading

```bash
# Verify environment
npm run env:check
```

## Mobile Testing

To test on a mobile device:

1. Start with network access:
   ```bash
   npm run dev:mobile
   ```

2. Find your local IP:
   ```bash
   ./get-local-ip.sh
   ```

3. Open `http://<your-ip>:3000` on your mobile device

## Hot Reload

The development server includes hot reload for:
- React components
- CSS/Tailwind
- API routes

Changes are reflected immediately without page refresh.

## Database Migrations

Local development uses the stage database. To run migrations:

```bash
# Check migration status
npm run migrate:check

# Apply to stage
npm run migrate:stage
```

⚠️ **Never** run `migrate:prod` from local development!

