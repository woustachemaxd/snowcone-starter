#!/bin/bash
set -e

# ── Validate input ──────────────────────────────────────────────
if [ -z "$1" ]; then
  echo "Usage: ./submit.sh your.name@datamavericks.com"
  exit 1
fi

EMAIL="$1"

# Basic email format check
if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  echo "Error: Invalid email format."
  echo "Usage: ./submit.sh your.name@datamavericks.com"
  exit 1
fi

# Derive slug from email (john.doe@company.com → john-doe)
SLUG=$(echo "$EMAIL" | cut -d'@' -f1 | tr '.' '-')

echo ""
echo "🍦 Snowcone Starter — Submission"
echo "================================"
echo "Email: $EMAIL"
echo "Slug:  $SLUG"
echo ""

# ── Build ────────────────────────────────────────────────────────
echo "Building your app..."
npm run build

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Build failed. Fix the errors above and try again."
  exit 1
fi

echo ""
echo "✅ Build succeeded!"
echo ""

# ── Upload ───────────────────────────────────────────────────────
# TODO: Implement upload mechanism
# This will push the built app (dist/) to the submissions repo
echo "⏳ Uploading submission..."
echo ""
echo "⚠️  Upload not yet configured — coming soon."
echo ""

# ── Done ─────────────────────────────────────────────────────────
echo "🎉 Your app will be live at:"
echo ""
echo "   https://data-apps-spec.deepanshu.tech/submission/$SLUG"
echo ""
echo "Ready in about 60 seconds. Share the link!"
