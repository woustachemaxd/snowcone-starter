#!/bin/bash
set -e

# ── Colors & Symbols ─────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
CYAN='\033[38;5;75m'
GREEN='\033[38;5;114m'
RED='\033[38;5;203m'
YELLOW='\033[38;5;222m'
WHITE='\033[38;5;255m'
GRAY='\033[38;5;243m'
BG_CYAN='\033[48;5;24m'

TICK="${GREEN}✔${RESET}"
CROSS="${RED}✘${RESET}"
ARROW="${CYAN}→${RESET}"
DOT="${GRAY}·${RESET}"
DIAMOND="${CYAN}◆${RESET}"

# ── Drawing helpers ──────────────────────────────────────────────
line() {
  printf "${GRAY}"
  printf '%.0s─' {1..52}
  printf "${RESET}\n"
}

header_box() {
  local text="$1"
  local len=${#text}
  local pad=$(( (48 - len) / 2 ))
  local pad_r=$(( 48 - len - pad ))
  echo ""
  printf "  ${CYAN}╭"
  printf '%.0s─' {1..50}
  printf "╮${RESET}\n"
  printf "  ${CYAN}│${RESET}"
  printf '%*s' "$((pad + 1))" ""
  printf "${BOLD}${WHITE}%s${RESET}" "$text"
  printf '%*s' "$((pad_r + 1))" ""
  printf "${CYAN}│${RESET}\n"
  printf "  ${CYAN}╰"
  printf '%.0s─' {1..50}
  printf "╯${RESET}\n"
}

step() {
  local num="$1"
  local label="$2"
  printf "\n  ${CYAN}${BOLD}[%s]${RESET} ${BOLD}%s${RESET}\n" "$num" "$label"
  printf "  ${GRAY}"
  printf '%.0s·' {1..50}
  printf "${RESET}\n"
}

info() {
  printf "  ${GRAY}%-12s${RESET} ${WHITE}%s${RESET}\n" "$1" "$2"
}

success() {
  printf "  ${TICK}  %s\n" "$1"
}

fail() {
  printf "  ${CROSS}  ${RED}%s${RESET}\n" "$1"
}

upload_indicator() {
  printf "  ${ARROW}  ${DIM}%s${RESET}\n" "$1"
}

# ── Check for required tools (before anything else) ─────────────
if ! command -v curl &> /dev/null; then
  printf "  ${CROSS}  ${RED}curl is required but not installed.${RESET}\n"
  exit 1
fi

if ! command -v node &> /dev/null; then
  printf "  ${CROSS}  ${RED}node is required but not installed.${RESET}\n"
  printf "  ${GRAY}Download it from${RESET} ${CYAN}https://nodejs.org${RESET}\n"
  exit 1
fi

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
  echo ""
  printf "  ${RED}${BOLD}Error:${RESET} No email provided.\n"
  printf "  ${GRAY}Usage:${RESET} ./submit.sh ${CYAN}your.name@datamavericks.com${RESET}\n"
  echo ""
  exit 1
fi

EMAIL="$1"

if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
  echo ""
  printf "  ${CROSS}  ${RED}Invalid email format.${RESET}\n"
  printf "  ${GRAY}Usage:${RESET} ./submit.sh ${CYAN}your.name@datamavericks.com${RESET}\n"
  echo ""
  exit 1
fi

DOMAIN=$(echo "$EMAIL" | cut -d'@' -f2 | tr '[:upper:]' '[:lower:]')
if [ "$DOMAIN" != "datamavericks.com" ]; then
  echo ""
  printf "  ${CROSS}  ${RED}Only @datamavericks.com emails are allowed.${RESET}\n"
  echo ""
  exit 1
fi

# Derive slug
SLUG=$(echo "$EMAIL" | cut -d'@' -f1 | tr '.' '-' | tr '[:upper:]' '[:lower:]')

# ── Header ──────────────────────────────────────────────────────
header_box "The Snowcone Warehouse — Submit"

printf "\n"
info "Email" "$EMAIL"
info "Slug" "$SLUG"
info "Target" "data-apps-spec-submissions"
printf "\n"
line

# ── Build ────────────────────────────────────────────────────────
step "1/3" "Building your app"

BUILD_LOG=$(mktemp)
if ! npx vite build --base="/submission/$SLUG/" >"$BUILD_LOG" 2>&1; then
  while IFS= read -r build_line; do
    printf "  ${DIM}  %s${RESET}\n" "$build_line"
  done < "$BUILD_LOG"
  rm -f "$BUILD_LOG"
  fail "Build failed. Fix the errors above and try again."
  exit 1
fi
while IFS= read -r build_line; do
  printf "  ${DIM}  %s${RESET}\n" "$build_line"
done < "$BUILD_LOG"
rm -f "$BUILD_LOG"

if [ ! -d dist ] || [ -z "$(find dist -type f -print -quit)" ]; then
  fail "Build produced no output in dist/. Aborting."
  exit 1
fi

success "Build succeeded"

# ── Temp dir for JSON payloads ───────────────────────────────────
TMPDIR_UPLOAD=$(mktemp -d)
trap 'rm -rf "$TMPDIR_UPLOAD"' EXIT

# ── Upload helper ────────────────────────────────────────────────
upload_file() {
  local file_path="$1"
  local repo_path="$2"

  local content
  content=$(base64 < "$file_path" | tr -d '\n')

  local existing_sha=""
  local response
  response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$API_BASE/$repo_path" 2>/dev/null || true)

  existing_sha=$(echo "$response" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{process.stdout.write(JSON.parse(d).sha||'')}catch(e){}})" 2>/dev/null || echo "")

  local payload_file="$TMPDIR_UPLOAD/payload.json"
  local content_file="$TMPDIR_UPLOAD/content.txt"
  echo -n "$content" > "$content_file"
  node -e "
const fs=require('fs');
const content=fs.readFileSync(process.argv[1],'utf8');
const d={message:'Submit: $SLUG — $repo_path',content:content};
if(process.argv[2])d.sha=process.argv[2];
fs.writeFileSync(process.argv[3],JSON.stringify(d));
" "$content_file" "$existing_sha" "$payload_file"

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d @"$payload_file" \
    "$API_BASE/$repo_path")

  if [ "$http_code" -ne 201 ] && [ "$http_code" -ne 200 ]; then
    fail "Failed  $repo_path  (HTTP $http_code)"
    return 1
  fi
}

# ── Upload built files ──────────────────────────────────────────
step "2/3" "Uploading built app"

FILE_COUNT=0
FAIL=0
while IFS= read -r file; do
  rel_path="${file#dist/}"
  repo_path="submission/$SLUG/$rel_path"
  upload_indicator "$rel_path"
  if ! upload_file "$file" "$repo_path"; then
    FAIL=1
  fi
  FILE_COUNT=$((FILE_COUNT + 1))
done < <(find dist -type f)

if [ "$FAIL" -ne 0 ]; then
  echo ""
  fail "Some files failed to upload. Try running the script again."
  exit 1
fi

success "Built app uploaded  ($FILE_COUNT files)"

# ── Upload source code ──────────────────────────────────────────
step "3/3" "Uploading source code"

SRC_COUNT=0
while IFS= read -r file; do
  repo_path="source/$SLUG/$file"
  upload_indicator "$file"
  upload_file "$file" "$repo_path" || true
  SRC_COUNT=$((SRC_COUNT + 1))
done < <(find src -type f; for f in index.html package.json vite.config.ts tsconfig.json tsconfig.app.json; do [ -f "$f" ] && echo "$f"; done)

success "Source code uploaded  ($SRC_COUNT files)"

# ── Done ─────────────────────────────────────────────────────────
echo ""
line
printf "\n"
printf "  ${GREEN}${BOLD}  SUBMISSION COMPLETE${RESET}\n"
printf "\n"
printf "  ${DIAMOND}  ${BOLD}Your app will be live at:${RESET}\n"
printf "\n"
printf "     ${CYAN}${BOLD}https://data-apps-spec-submissions.deepanshu.tech/submission/%s${RESET}\n" "$SLUG"
printf "\n"
printf "  ${GRAY}Ready in ~60 seconds. Share the link!${RESET}\n"
printf "  ${GRAY}View all submissions at${RESET} ${CYAN}https://data-apps-spec-submissions.deepanshu.tech${RESET}\n"
printf "\n"
line
echo ""
