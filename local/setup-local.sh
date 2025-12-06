#!/bin/bash
# =============================================================================
# Local Development Setup Script
# =============================================================================
# Sets up the local development environment
# Usage: ./setup-local.sh
# =============================================================================

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   OneThought Local Development Setup       ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Get the root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$ROOT_DIR"

# Check Node.js version
echo -e "${BLUE}Checking Node.js version...${NC}"
NODE_VERSION=$(node -v 2>/dev/null || echo "not installed")
if [[ "$NODE_VERSION" == "not installed" ]]; then
    echo -e "${YELLOW}Node.js is not installed. Please install Node.js 18 or later.${NC}"
    exit 1
fi
echo -e "${GREEN}[✓] Node.js: $NODE_VERSION${NC}"

# Check npm version
NPM_VERSION=$(npm -v)
echo -e "${GREEN}[✓] npm: $NPM_VERSION${NC}"

# Install dependencies
echo ""
echo -e "${BLUE}Installing dependencies...${NC}"
npm install
echo -e "${GREEN}[✓] Dependencies installed${NC}"

# Setup environment file
echo ""
echo -e "${BLUE}Setting up environment...${NC}"
if [ ! -f "$ROOT_DIR/.env.local" ]; then
    if [ -f "$SCRIPT_DIR/.env.local.example" ]; then
        cp "$SCRIPT_DIR/.env.local.example" "$ROOT_DIR/.env.local"
        echo -e "${YELLOW}[!] Created .env.local from template. Please update with your credentials.${NC}"
    else
        echo -e "${YELLOW}[!] No .env.local found. Please create one from the example.${NC}"
    fi
else
    echo -e "${GREEN}[✓] .env.local already exists${NC}"
fi

# Verify environment
echo ""
echo -e "${BLUE}Verifying environment...${NC}"
if npm run env:check 2>/dev/null; then
    echo -e "${GREEN}[✓] Environment configuration valid${NC}"
else
    echo -e "${YELLOW}[!] Environment check failed. Please verify your .env.local${NC}"
fi

# Setup complete
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   Setup Complete!                          ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Update .env.local with your Supabase credentials"
echo "  2. Run: npm run dev"
echo "  3. Open: http://localhost:3000"
echo ""
echo "Available commands:"
echo "  npm run dev          - Start development server"
echo "  npm run dev:mobile   - Start with mobile access"
echo "  npm run build        - Build for production"
echo "  npm run test         - Run tests"
echo ""

