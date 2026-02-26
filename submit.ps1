$ErrorActionPreference = "Stop"

# ── Colors ──────────────────────────────────────────────────────
function Write-Header($text) {
    $pad = [math]::Floor((48 - $text.Length) / 2)
    $padR = 48 - $text.Length - $pad
    Write-Host ""
    Write-Host "  +-$('-' * 48)-+" -ForegroundColor Cyan
    Write-Host "  | $(' ' * $pad)$text$(' ' * $padR) |" -ForegroundColor Cyan
    Write-Host "  +-$('-' * 48)-+" -ForegroundColor Cyan
}

function Write-Step($num, $label) {
    Write-Host ""
    Write-Host "  [$num] $label" -ForegroundColor Cyan
    Write-Host "  $('.' * 50)" -ForegroundColor DarkGray
}

function Write-Info($label, $value) {
    Write-Host ("  {0,-12} {1}" -f $label, $value)
}

function Write-Success($msg) {
    Write-Host "  [ok] $msg" -ForegroundColor Green
}

function Write-Fail($msg) {
    Write-Host "  [X]  $msg" -ForegroundColor Red
}

function Write-Line {
    Write-Host "  $('-' * 52)" -ForegroundColor DarkGray
}

# ── Helper: get relative path safely ───────────────────────────
function Get-RelativeTo($base, $full) {
    $basePath = $base.TrimEnd('\', '/')
    if ($full.StartsWith($basePath)) {
        return $full.Substring($basePath.Length).TrimStart('\', '/').Replace('\', '/')
    }
    return $full.Replace('\', '/')
}

# ── Check for required tools ────────────────────────────────────
if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Fail "node is required but not installed."
    Write-Host "  Download it from https://nodejs.org" -ForegroundColor DarkGray
    exit 1
}

if (-not (Get-Command "npx" -ErrorAction SilentlyContinue)) {
    Write-Fail "npx is required but not installed."
    exit 1
}

# ── Config ──────────────────────────────────────────────────────
$GITHUB_TOKEN = node -e @'
const e='FAcbHxYNMRUSGjBGUi5bUiNZOyZTGwBWRhsDEiInAFQVMRpHCVwhKxc7PzEtNgtRIVxdRiwBJRIkFwM+Al4nBBELFSYPNy9UNgwdPDskXDI/N106MBgaURpXXR8z';
const k='snowcone';
const d=Buffer.from(e,'base64');
process.stdout.write(Array.from(d).map((b,i)=>String.fromCharCode(b^k.charCodeAt(i%k.length))).join(''));
'@

if ([string]::IsNullOrWhiteSpace($GITHUB_TOKEN)) {
    Write-Fail "Failed to extract GitHub token. Is Node.js working?"
    exit 1
}

$REPO_OWNER = "woustachemaxd"
$REPO_NAME = "data-apps-spec-submissions"
$API_BASE = "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

# ── Validate input ──────────────────────────────────────────────
if ($args.Count -eq 0 -or [string]::IsNullOrWhiteSpace($args[0])) {
    Write-Host ""
    Write-Host "  Error: No email provided." -ForegroundColor Red
    Write-Host "  Usage: .\submit.ps1 your.name@datamavericks.com" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

$EMAIL = $args[0]

if ($EMAIL -notmatch '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') {
    Write-Host ""
    Write-Fail "Invalid email format."
    Write-Host "  Usage: .\submit.ps1 your.name@datamavericks.com" -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

$DOMAIN = ($EMAIL -split '@')[1].ToLower()
if ($DOMAIN -ne "datamavericks.com") {
    Write-Host ""
    Write-Fail "Only @datamavericks.com emails are allowed."
    Write-Host ""
    exit 1
}

$SLUG = ($EMAIL -split '@')[0].Replace('.', '-').ToLower()

# ── Header ──────────────────────────────────────────────────────
Write-Header "The Snowcone Warehouse - Submit"
Write-Host ""
Write-Info "Email" $EMAIL
Write-Info "Slug" $SLUG
Write-Info "Target" "data-apps-spec-submissions"
Write-Host ""
Write-Line

# ── Build ───────────────────────────────────────────────────────
Write-Step "1/3" "Building your app"

& npx vite build --base="/submission/$SLUG/" 2>&1 | Tee-Object -Variable buildOutput | ForEach-Object {
    Write-Host "    $_" -ForegroundColor DarkGray
}
$buildExitCode = $LASTEXITCODE

if ($buildExitCode -ne 0) {
    Write-Fail "Build failed. Fix the errors above and try again."
    exit 1
}

if (-not (Test-Path "dist") -or @(Get-ChildItem "dist" -Recurse -File).Count -eq 0) {
    Write-Fail "Build produced no output in dist/. Aborting."
    exit 1
}

Write-Success "Build succeeded"

# ── Upload helper ───────────────────────────────────────────────
function Upload-File($filePath, $repoPath) {
    $contentBytes = [System.IO.File]::ReadAllBytes($filePath)
    $content = [Convert]::ToBase64String($contentBytes)

    $headers = @{
        "Authorization" = "token $GITHUB_TOKEN"
        "Accept"        = "application/vnd.github.v3+json"
    }

    $existingSha = ""
    try {
        $response = Invoke-RestMethod -Uri "$API_BASE/$repoPath" -Headers $headers -Method Get -ErrorAction Stop
        if ($response -and $response.sha) {
            $existingSha = $response.sha
        }
    } catch {
        # File doesn't exist yet (404) — that's fine
    }

    $payload = @{
        message = "Submit: $SLUG - $repoPath"
        content = $content
    }
    if ($existingSha) {
        $payload.sha = $existingSha
    }

    $jsonPayload = $payload | ConvertTo-Json -Compress
    $jsonBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonPayload)

    try {
        $result = Invoke-WebRequest -Uri "$API_BASE/$repoPath" -Headers $headers -Method Put -Body $jsonBytes -ContentType "application/json" -UseBasicParsing
        if ($result.StatusCode -ne 200 -and $result.StatusCode -ne 201) {
            Write-Fail "Failed  $repoPath  (HTTP $($result.StatusCode))"
            return $false
        }
    } catch {
        $code = 0
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        Write-Fail "Failed  $repoPath  (HTTP $code)"
        return $false
    }
    return $true
}

# ── Upload built files ──────────────────────────────────────────
Write-Step "2/3" "Uploading built app"

$distRoot = (Resolve-Path "dist").Path
$fileCount = 0
$failed = $false
foreach ($file in (Get-ChildItem "dist" -Recurse -File)) {
    $relPath = Get-RelativeTo $distRoot $file.FullName
    $repoPath = "submission/$SLUG/$relPath"
    Write-Host "  ->  $relPath" -ForegroundColor DarkGray
    if (-not (Upload-File $file.FullName $repoPath)) {
        $failed = $true
    }
    $fileCount++
}

if ($failed) {
    Write-Host ""
    Write-Fail "Some files failed to upload. Try running the script again."
    exit 1
}

Write-Success "Built app uploaded  ($fileCount files)"

# ── Upload source code ──────────────────────────────────────────
Write-Step "3/3" "Uploading source code"

$srcCount = 0
$srcFiles = @()
if (Test-Path "src") {
    $srcFiles += Get-ChildItem "src" -Recurse -File
}
foreach ($f in @("index.html", "package.json", "vite.config.ts", "tsconfig.json", "tsconfig.app.json")) {
    if (Test-Path $f) { $srcFiles += Get-Item $f }
}

$srcRoot = ""
if (Test-Path "src") { $srcRoot = (Resolve-Path "src").Path }

foreach ($file in $srcFiles) {
    if ($srcRoot -and $file.FullName.StartsWith($srcRoot)) {
        $relPath = "src/" + (Get-RelativeTo $srcRoot $file.FullName)
    } else {
        $relPath = $file.Name
    }
    $repoPath = "source/$SLUG/$relPath"
    Write-Host "  ->  $relPath" -ForegroundColor DarkGray
    Upload-File $file.FullName $repoPath | Out-Null
    $srcCount++
}

Write-Success "Source code uploaded  ($srcCount files)"

# ── Done ────────────────────────────────────────────────────────
Write-Host ""
Write-Line
Write-Host ""
Write-Host "  SUBMISSION COMPLETE" -ForegroundColor Green
Write-Host ""
Write-Host "  Your app will be live at:" -ForegroundColor White
Write-Host ""
Write-Host "     https://data-apps-spec-submissions.deepanshu.tech/submission/$SLUG" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Ready in ~60 seconds. Share the link!" -ForegroundColor DarkGray
Write-Host "  View all submissions at https://data-apps-spec-submissions.deepanshu.tech" -ForegroundColor DarkGray
Write-Host ""
Write-Line
Write-Host ""
