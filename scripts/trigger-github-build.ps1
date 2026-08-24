# =============================================================
#  Trigger KSU kernel build on GitHub Actions + download artifact
#  Run on Windows PowerShell. Needs a GitHub PAT with `repo` +
#  `workflow` scopes. Will create the repo if it doesn't exist.
# =============================================================
[CmdletBinding()]
param(
    [string]$Pat = $env:GITHUB_TOKEN,
    [string]$Owner = "",
    [string]$Repo = "raphael-ksu-kernel",
    [Parameter(Mandatory=$false)]
    [switch]$Private = $false,
    [string]$Description = "KSU kernel build for Redmi K20 Pro (raphael)",
    [int]$PollIntervalSec = 30,
    [int]$MaxWaitMinutes = 150
)

$ErrorActionPreference = 'Stop'

if (-not $Pat) {
    Write-Host ""
    Write-Host "GitHub PAT missing. Create one at:" -ForegroundColor Yellow
    Write-Host "  https://github.com/settings/tokens/new?scopes=repo,workflow&description=KSU-raphael-build"
    Write-Host "Then re-run with -Pat ghp_xxx, or set `$env:GITHUB_TOKEN = 'ghp_xxx'" -ForegroundColor Yellow
    Write-Host ""
    $Pat = Read-Host "Or paste your PAT here (input hidden)"
    if (-not $Pat) { throw "PAT required" }
}

if (-not $Owner) {
    # Resolve owner from /user endpoint
    $me = Invoke-RestMethod -Headers @{Authorization="Bearer $Pat"; Accept="application/vnd.github+json"} `
        -Uri "https://api.github.com/user" -Method Get
    $Owner = $me.login
    Write-Host "Detected GitHub user: $Owner"
}

$headers = @{
    Authorization = "Bearer $Pat"
    Accept        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"  = "KSU-raphael-builder"
}

# ---------- 1. Create repo if missing ----------
Write-Host "`n[1/6] Ensuring repo $Owner/$Repo exists..."
try {
    $null = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$Owner/$Repo" -Method Get
    Write-Host "  Repo already exists."
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        $body = @{
            name = $Repo
            description = $Description
            private = [bool]$Private
            auto_init = $false
        } | ConvertTo-Json
        $created = Invoke-RestMethod -Headers $headers `
            -Uri "https://api.github.com/user/repos" -Method Post -Body $body -ContentType "application/json"
        Write-Host "  Created $($created.html_url)"
    } else { throw }
}

# ---------- 2. Push local source to GitHub ----------
Write-Host "`n[2/6] Pushing E:\kernel-raphael -> $Owner/$Repo"
$src = "E:\kernel-raphael"
$authUrl = "https://x-access-token:${Pat}@github.com/$Owner/$Repo.git"
$tmp = Join-Path $env:TEMP "gh-push-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    git -C $tmp init -q -b main
    # Force LF line endings so .sh files stay Linux-native (build runs on Linux runner)
    git -C $tmp config core.autocrlf false
    git -C $tmp config core.eol lf
    git -C $tmp config user.name "ksu-builder"
    git -C $tmp config user.email "ksu@local"
    git -C $tmp remote add origin $authUrl
    # Mirror directory via Copy-Item (avoid tar pipe encoding traps on Windows)
    Get-ChildItem -Path $src -Force | Where-Object {
        $_.Name -notin @('.git','out','raphael','KernelSU')
    } | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $tmp -Recurse -Force
    }
    # Add a safety .gitignore for any future exclusions
    $gi = @'
out/
raphael/
KernelSU/
*.log
.DS_Store
Thumbs.db
'@
    Set-Content -Path (Join-Path $tmp '.gitignore') -Value $gi -Encoding UTF8
    git -C $tmp add -A
    git -C $tmp commit -q -m "Initial KSU build pipeline"
    # Retry up to 3 times on transient network errors
    $pushed = $false
    for ($i = 1; $i -le 3; $i++) {
        $pushOut = git -C $tmp push -q -u origin main 2>&1
        if ($LASTEXITCODE -eq 0) { $pushed = $true; break }
        Write-Host "  push attempt $i failed: $pushOut"
        Start-Sleep -Seconds ([Math]::Pow(2, $i))
    }
    if (-not $pushed) { throw "push failed after 3 retries" }
    Write-Host "  Pushed."
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

# ---------- 3. Trigger workflow_dispatch ----------
Write-Host "`n[3/6] Triggering workflow..."
$triggerBody = @{
    ref = "main"
    inputs = @{
        ksu_branch = "main"
        kernel_branch = "raphael"
        enable_susfs = "true"
    }
} | ConvertTo-Json
$run = Invoke-RestMethod -Headers $headers `
    -Uri "https://api.github.com/repos/$Owner/$Repo/actions/workflows/build.yml/dispatches" `
    -Method Post -Body $triggerBody -ContentType "application/json"
Write-Host "  Triggered."

# ---------- 4. Poll for completion ----------
Write-Host "`n[4/6] Waiting for run (up to $MaxWaitMinutes min)..."
$deadline = (Get-Date).AddMinutes($MaxWaitMinutes)
$runId = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 5
    $runs = Invoke-RestMethod -Headers $headers `
        -Uri "https://api.github.com/repos/$Owner/$Repo/actions/runs?per_page=1" -Method Get
    $latest = $runs.workflow_runs | Select-Object -First 1
    if ($latest.workflow_runs) { $latest = $latest.workflow_runs[0] }  # for paginated
    if ($latest.status -ne "in_progress" -and $latest.status -ne "queued" -and $latest.status) {
        $runId = $latest.id
        $status = $latest.conclusion
        $html   = $latest.html_url
        Write-Host "  Run #$runId finished: $status  -> $html"
        break
    }
    Write-Host ("  [{0:HH:mm:ss}] status: {1}" -f (Get-Date), $latest.status)
    Start-Sleep -Seconds $PollIntervalSec
}
if (-not $runId) { throw "build did not finish within $MaxWaitMinutes min; check the run URL on github.com" }
if ($status -ne "success") { throw "build concluded with $status; download log artifact 'build-log' for details" }

# ---------- 5. Download artifact ----------
Write-Host "`n[5/6] Downloading artifact 'KSU-raphael-zip'..."
$artifacts = Invoke-RestMethod -Headers $headers `
    -Uri "https://api.github.com/repos/$Owner/$Repo/actions/runs/$runId/artifacts" -Method Get
$zip = $artifacts.artifacts | Where-Object { $_.name -eq "KSU-raphael-zip" } | Select-Object -First 1
if (-not $zip) { throw "no artifact 'KSU-raphael-zip' on run $runId" }

$dst = "E:\kernel-raphael\out"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
$outFile = Join-Path $dst $zip.name
Invoke-WebRequest -Headers $headers -Uri $zip.archive_download_url -OutFile $outFile
Write-Host "  Saved: $outFile  ($([math]::Round((Get-Item $outFile).Length/1MB,2)) MB)"

# ---------- 6. Verify ----------
Write-Host "`n[6/6] Verifying zip..."
$verifyDir = Join-Path $env:TEMP "ksu-verify-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Force -Path $verifyDir | Out-Null
Expand-Archive -Path $outFile -DestinationPath $verifyDir -Force
Get-ChildItem $verifyDir | Select-Object Name, Length | Format-Table -AutoSize
$img = Get-Item (Join-Path $verifyDir "Image.gz") -ErrorAction SilentlyContinue
if ($img) {
    Write-Host "  Image.gz size: $([math]::Round($img.Length/1MB,2)) MB"
} else {
    Write-Warning "  Image.gz missing in zip"
}
Remove-Item -Recurse -Force $verifyDir

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  DONE. Flash this on your K20 Pro via TWRP:" -ForegroundColor Green
Write-Host "  $outFile" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next:" -ForegroundColor Cyan
Write-Host "  adb push `"$outFile`" /sdcard/"
Write-Host "  adb reboot recovery   # then Install zip in TWRP"
Write-Host "  adb install KernelSU_v3.2.5_32525-release.apk"
