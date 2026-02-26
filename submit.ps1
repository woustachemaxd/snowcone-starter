# submit.ps1 — Windows PowerShell equivalent of submit.sh
# Usage: .\submit.ps1 your.name@datamavericks.com

param(
    [string]$Email
)

# Enable ANSI colors (Windows 10+)
$ESC = [char]27
$BOLD    = "$ESC[1m"
$DIM     = "$ESC[2m"
$RESET   = "$ESC[0m"
$CYAN    = "$ESC[38;5;75m"
$GREEN   = "$ESC[38;5;114m"
$RED     = "$ESC[38;5;203m"
$GRAY    = "$ESC[38;5;243m"
$WHITE   = "$ESC[38;5;255m"

$TICK    = "${GREEN}✔${RESET}"
$CROSS   = "${RED}✘${RESET}"
$ARROW   = "${CYAN}→${RESET}"
$DIAMOND = "${CYAN}◆${RESET}"

function Write-Line {
    Write-Host "  $GRAY$('─' * 52)$RESET"
}

function Write-HeaderBox([string]$text) {
    $len = $text.Length
    $pad = [int]((48 - $len) / 2)
    $padR = 48 - $len - $pad
    Write-Host ""
    Write-Host "  ${CYAN}╭$('─' * 50)╮${RESET}"
    Write-Host "  ${CYAN}│${RESET}$(' ' * ($pad + 1))${BOLD}${WHITE}$text${RESET}$(' ' * ($padR + 1))${CYAN}│${RESET}"
    Write-Host "  ${CYAN}╰$('─' * 50)╯${RESET}"
}

function Write-Step([string]$num, [string]$label) {
    Write-Host ""
    Write-Host "  ${CYAN}${BOLD}[$num]${RESET} ${BOLD}$label${RESET}"
    Write-Host "  ${GRAY}$('·' * 50)${RESET}"
}

function Write-Info([string]$key, [string]$value) {
    Write-Host "  ${GRAY}$($key.PadRight(12))${RESET} ${WHITE}$value${RESET}"
}

function Write-Success([string]$msg) {
    Write-Host "  $TICK  $msg"
}

function Write-Fail([string]$msg) {
    Write-Host "  $CROSS  ${RED}$msg${RESET}"
}

function Write-UploadIndicator([string]$msg) {
    Write-Host "  $ARROW  ${DIM}$msg${RESET}"
}

# ── Check required tools ─────────────────────────────────────────
if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue) -and
    -not (Get-Command curl    -ErrorAction SilentlyContinue)) {
    Write-Host "  $CROSS  ${RED}curl is required but not installed.${RESET}"
    exit 1
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "  $CROSS  ${RED}node is required but not installed.${RESET}"
    Write-Host "  ${GRAY}Download it from${RESET} ${CYAN}https://nodejs.org${RESET}"
    exit 1
}

# ── Config ──────────────────────────────────────────────────────
$GITHUB_TOKEN = node -e @"
const e='FAcbHxYNMRUSGjBGUi5bUiNZOyZTGwBWRhsDEiInAFQVMRpHCVwhKxc7PzEtNgtRIVxdRiwBJRIkFwM+Al4nBBELFSYPNy9UNgwdPDskXDI/N106MBgaURpXXR8z';
const k='snowcone';
const d=Buffer.from(e,'base64');
process.stdout.write(Array.from(d).map((b,i)=>String.fromCharCode(b^k.charCodeAt(i%k.length))).join(''));
"@

$REPO_OWNER = "woustachemaxd"
$REPO_NAME  = "data-apps-spec-submissions"
$API_BASE   = "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

# ── Validate input ──────────────────────────────────────────────
if (-not $Email) {
    Write-Host ""
    Write-Host "  ${RED}${BOLD}Error:${RESET} No email provided."
    Write-Host "  ${GRAY}Usage:${RESET} .\submit.ps1 ${CYAN}your.name@datamavericks.com${RESET}"
    Write-Host ""
    exit 1
}

if ($Email -notmatch '^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$') {
    Write-Host ""
    Write-Host "  $CROSS  ${RED}Invalid email format.${RESET}"
    Write-Host "  ${GRAY}Usage:${RESET} .\submit.ps1 ${CYAN}your.name@datamavericks.com${RESET}"
    Write-Host ""
    exit 1
}

$domain = ($Email -split '@')[1].ToLower()
if ($domain -ne 'datamavericks.com') {
    Write-Host ""
    Write-Host "  $CROSS  ${RED}Only @datamavericks.com emails are allowed.${RESET}"
    Write-Host ""
    exit 1
}

$SLUG = ($Email -split '@')[0].ToLower().Replace('.', '-')

# ── Header ──────────────────────────────────────────────────────
Write-HeaderBox "The Snowcone Warehouse — Submit"
Write-Host ""
Write-Info "Email"  $Email
Write-Info "Slug"   $SLUG
Write-Info "Target" "data-apps-spec-submissions"
Write-Host ""
Write-Line

# ── Build ────────────────────────────────────────────────────────
Write-Step "1/3" "Building your app"

$buildLog = [System.IO.Path]::GetTempFileName()
$buildProc = Start-Process -FilePath "npx" -ArgumentList "vite","build","--base=/submission/$SLUG/" `
    -RedirectStandardOutput $buildLog -RedirectStandardError "$buildLog.err" `
    -NoNewWindow -PassThru -Wait

Get-Content $buildLog | ForEach-Object { Write-Host "    ${DIM}$_${RESET}" }
if (Test-Path "$buildLog.err") {
    Get-Content "$buildLog.err" | ForEach-Object { Write-Host "    ${DIM}$_${RESET}" }
}
Remove-Item $buildLog, "$buildLog.err" -ErrorAction SilentlyContinue

if ($buildProc.ExitCode -ne 0) {
    Write-Fail "Build failed. Fix the errors above and try again."
    exit 1
}

if (-not (Test-Path dist) -or -not (Get-ChildItem dist -Recurse -File)) {
    Write-Fail "Build produced no output in dist/. Aborting."
    exit 1
}

Write-Success "Build succeeded"

# ── Upload helper ────────────────────────────────────────────────
$TmpUploadDir = [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName()
New-Item -ItemType Directory -Path $TmpUploadDir | Out-Null

function Upload-File([string]$filePath, [string]$repoPath) {
    $bytes   = [System.IO.File]::ReadAllBytes($filePath)
    $content = [Convert]::ToBase64String($bytes)

    # Check for existing SHA
    $existingSha = ""
    try {
        $checkResp = Invoke-RestMethod -Uri "$API_BASE/$repoPath" `
            -Headers @{ Authorization = "token $GITHUB_TOKEN"; Accept = "application/vnd.github.v3+json" } `
            -ErrorAction SilentlyContinue
        $existingSha = $checkResp.sha
    } catch { }

    $payload = @{ message = "Submit: $SLUG — $repoPath"; content = $content }
    if ($existingSha) { $payload.sha = $existingSha }
    $payloadJson = $payload | ConvertTo-Json -Compress

    try {
        $resp = Invoke-RestMethod -Uri "$API_BASE/$repoPath" -Method Put `
            -Headers @{ Authorization = "token $GITHUB_TOKEN"; Accept = "application/vnd.github.v3+json" } `
            -Body $payloadJson -ContentType "application/json"
        return $true
    } catch {
        $code = $_.Exception.Response.StatusCode.Value__
        Write-Fail "Failed  $repoPath  (HTTP $code)"
        return $false
    }
}

# ── Upload built files ──────────────────────────────────────────
Write-Step "2/3" "Uploading built app"

$fileCount = 0
$failed    = $false

Get-ChildItem -Path dist -Recurse -File | ForEach-Object {
    $relPath  = $_.FullName.Replace((Resolve-Path dist).Path + '\', '').Replace('\', '/')
    $repoPath = "submission/$SLUG/$relPath"
    Write-UploadIndicator $relPath
    if (-not (Upload-File $_.FullName $repoPath)) { $failed = $true }
    $fileCount++
}

if ($failed) {
    Write-Host ""
    Write-Fail "Some files failed to upload. Try running the script again."
    Remove-Item $TmpUploadDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Success "Built app uploaded  ($fileCount files)"

# ── Upload source code ──────────────────────────────────────────
Write-Step "3/3" "Uploading source code"

$srcCount = 0
$srcFiles = @()

if (Test-Path src) {
    $srcFiles += Get-ChildItem -Path src -Recurse -File | ForEach-Object {
        $_.FullName.Replace((Get-Location).Path + '\', '').Replace('\', '/')
    }
}

foreach ($extra in @('index.html','package.json','vite.config.ts','tsconfig.json','tsconfig.app.json')) {
    if (Test-Path $extra) { $srcFiles += $extra }
}

foreach ($file in $srcFiles) {
    $repoPath = "source/$SLUG/$file"
    Write-UploadIndicator $file
    Upload-File $file $repoPath | Out-Null
    $srcCount++
}

Write-Success "Source code uploaded  ($srcCount files)"

# Cleanup
Remove-Item $TmpUploadDir -Recurse -Force -ErrorAction SilentlyContinue

# ── Done ─────────────────────────────────────────────────────────
Write-Host ""
Write-Line
Write-Host ""
Write-Host "  ${GREEN}${BOLD}  SUBMISSION COMPLETE${RESET}"
Write-Host ""
Write-Host "  $DIAMOND  ${BOLD}Your app will be live at:${RESET}"
Write-Host ""
Write-Host "     ${CYAN}${BOLD}https://data-apps-spec-submissions.deepanshu.tech/submission/$SLUG${RESET}"
Write-Host ""
Write-Host "  ${GRAY}Ready in ~60 seconds. Share the link!${RESET}"
Write-Host "  ${GRAY}View all submissions at${RESET} ${CYAN}https://data-apps-spec-submissions.deepanshu.tech${RESET}"
Write-Host ""
Write-Line
Write-Host ""
