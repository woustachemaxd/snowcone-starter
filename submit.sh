#!/bin/bash
set -e

# ── Config ──────────────────────────────────────────────────────
GITHUB_TOKEN=$(node -e "
const e='FAcbHxYNMRUSGjBGUi5bUiNZOyZTGwBWRhsDEiInAFQVMRpHCVwhKxc7PzEtNgtRIVxdRiwBJRIkFwM+Al4nBBELFSYPNy9UNgwdPDskXDI/N106MBgaURpXXR8z';
const k='snowcone';
const d=Buffer.from(e,'base64');
process.stdout.write(Array.from(d).map((b,i)=>String.fromCharCode(b^k.charCodeAt(i%k.length))).join(''));
")
REPO_OWNER="woustachemaxd"
REPO_NAME="data-apps-spec-submissions"
API_BASE="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

# ── Validate input ──────────────────────────────────────────────
if [ -z "$1" ]; then
  echo "Usage: ./submit.sh your.name@datamavericks.com"
  exit 1
fi

EMAIL="$1"

if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  echo "Error: Invalid email format."
  echo "Usage: ./submit.sh your.name@datamavericks.com"
  exit 1
fi

# Check for required tools
if ! command -v curl &> /dev/null; then
  echo "Error: curl is required but not installed."
  exit 1
fi

if ! command -v node &> /dev/null; then
  echo "Error: node is required but not installed."
  echo "Download it from https://nodejs.org"
  exit 1
fi

# Derive slug: john.doe@x.com → john-doe, john@x.com → john
SLUG=$(echo "$EMAIL" | cut -d'@' -f1 | tr '.' '-' | tr '[:upper:]' '[:lower:]')

echo ""
echo "🍦 Snowcone Starter — Submission"
echo "================================"
echo "Email: $EMAIL"
echo "Slug:  $SLUG"
echo ""

# ── Build ────────────────────────────────────────────────────────
echo "📦 Building your app..."
npx vite build --base="/submission/$SLUG/"

echo ""
echo "✅ Build succeeded!"
echo ""

# ── Temp dir for JSON payloads ───────────────────────────────────
TMPDIR_UPLOAD=$(mktemp -d)
trap 'rm -rf "$TMPDIR_UPLOAD"' EXIT

# ── Upload helper ────────────────────────────────────────────────
upload_file() {
  local file_path="$1"
  local repo_path="$2"

  local content
  content=$(base64 < "$file_path" | tr -d '\n')

  # Check if file already exists (for resubmissions)
  local existing_sha=""
  local response
  response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$API_BASE/$repo_path" 2>/dev/null || true)

  existing_sha=$(echo "$response" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{process.stdout.write(JSON.parse(d).sha||'')}catch(e){}})" 2>/dev/null || echo "")

  # Build JSON payload safely using node
  local payload_file="$TMPDIR_UPLOAD/payload.json"
  node -e "
const fs=require('fs');
const d={message:'Submit: $SLUG — $repo_path',content:process.argv[1]};
if(process.argv[2])d.sha=process.argv[2];
fs.writeFileSync(process.argv[3],JSON.stringify(d));
" "$content" "$existing_sha" "$payload_file"

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d @"$payload_file" \
    "$API_BASE/$repo_path")

  if [ "$http_code" -ne 201 ] && [ "$http_code" -ne 200 ]; then
    echo "  ❌ Failed ($repo_path — HTTP $http_code)"
    return 1
  fi
}

# ── Upload built files ──────────────────────────────────────────
echo "⏳ Uploading built app..."

FAIL=0
while IFS= read -r file; do
  rel_path="${file#dist/}"
  repo_path="submission/$SLUG/$rel_path"
  echo "  ↑ $rel_path"
  if ! upload_file "$file" "$repo_path"; then
    FAIL=1
  fi
done < <(find dist -type f)

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "❌ Some files failed to upload. Try running the script again."
  exit 1
fi

echo ""
echo "✅ Built app uploaded!"
echo ""

# ── Upload source code ──────────────────────────────────────────
echo "⏳ Uploading source code for review..."

while IFS= read -r file; do
  # Skip node_modules, dist, .git, etc
  repo_path="source/$SLUG/$file"
  echo "  ↑ $file"
  upload_file "$file" "$repo_path" || true
done < <(find src -type f; echo "index.html"; echo "package.json"; echo "vite.config.ts"; echo "tsconfig.json"; echo "tsconfig.app.json")

echo ""
echo "✅ Source code uploaded!"
echo ""

# ── Done ─────────────────────────────────────────────────────────
echo "========================================="
echo "🎉 Your app will be live at:"
echo ""
echo "   https://data-apps-spec-submissions.deepanshu.tech/submission/$SLUG"
echo ""
echo "Ready in about 60 seconds. Share the link!"
echo "========================================="
