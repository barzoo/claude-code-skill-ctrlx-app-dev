# ctrlX Dev Loop: Build → Upload → Verify (PowerShell)
# Usage: .\scripts\dev-loop.ps1 [-Arch amd64|arm64]
#
# Required env vars: CTRLX_HOST, CTRLX_USER, CTRLX_PASS

param(
    [string]$Arch = "amd64",
    [int]$MaxWait = 120
)

$ErrorActionPreference = "Stop"

$host_addr = $env:CTRLX_HOST
$user = if ($env:CTRLX_USER) { $env:CTRLX_USER } else { "admin" }
$pass = $env:CTRLX_PASS

if (-not $host_addr) { throw "Set CTRLX_HOST environment variable" }
if (-not $pass)      { throw "Set CTRLX_PASS environment variable" }

$startTime = Get-Date

# ── 1. Build ──────────────────────────────────────────────────────────────────
Write-Host "▶ [1/5] Building snap for $Arch..."
docker run --rm `
    -v "${PWD}:/build" -w /build `
    -e SNAPCRAFT_BUILD_ENVIRONMENT=host `
    ghcr.io/canonical/snapcraft:8_core22 `
    snapcraft --target-arch=$Arch

$snapFile = Get-ChildItem *.snap | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $snapFile) { throw "No .snap file found after build" }
$snapName = $snapFile.Name -replace '_\d.*', ''
Write-Host "  Built: $($snapFile.Name)"

# Disable SSL verification for self-signed cert on COREvirtual
add-type @"
using System.Net; using System.Security.Cryptography.X509Certificates;
public class TrustAll : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert,
        WebRequest req, int prob) { return true; }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAll

# ── 2. Auth ───────────────────────────────────────────────────────────────────
Write-Host "▶ [2/5] Authenticating with $host_addr..."
$authBody = @{ name = $user; password = $pass } | ConvertTo-Json
$authResp = Invoke-RestMethod -Method Post `
    -Uri "https://$host_addr/identity-manager/api/v1/auth/token" `
    -ContentType "application/json" -Body $authBody
$token = $authResp.access_token
Write-Host "  Token obtained"

$headers = @{ Authorization = "Bearer $token" }

# ── 3. Upload ─────────────────────────────────────────────────────────────────
Write-Host "▶ [3/5] Uploading $($snapFile.Name)..."
$form = @{ file = Get-Item $snapFile.FullName }
Invoke-RestMethod -Method Post `
    -Uri "https://$host_addr/package-manager/api/v1/packages" `
    -Headers $headers -Form $form | Out-Null
Write-Host "  Uploaded"

# ── 4. Wait ───────────────────────────────────────────────────────────────────
Write-Host "▶ [4/5] Waiting for installation (max ${MaxWait}s)..."
$elapsed = 0
$state = ""
while ($elapsed -lt $MaxWait) {
    $pkg = Invoke-RestMethod `
        -Uri "https://$host_addr/package-manager/api/v1/packages/$snapName" `
        -Headers $headers
    $state = $pkg.state
    Write-Host "  State: $state ($elapsed s)"
    if ($state -eq "Running") { break }
    if ($state -eq "Error")   { throw "App entered Error state" }
    Start-Sleep 3; $elapsed += 3
}
if ($state -ne "Running") { throw "App not running after ${MaxWait}s" }

# ── 5. Logs ───────────────────────────────────────────────────────────────────
Write-Host "▶ [5/5] Fetching recent logs..."
$logs = Invoke-RestMethod `
    -Uri "https://$host_addr/log/api/v1/entries?filter=$snapName&count=50" `
    -Headers $headers
$logs.entries | Select-Object -Last 20 | ForEach-Object {
    Write-Host "  [$($_.timestamp)] $($_.message)"
}

$elapsed = (Get-Date) - $startTime
Write-Host ""
Write-Host "✓ Dev loop complete in $([int]$elapsed.TotalSeconds)s"
Write-Host "  App '$snapName' is Running on $host_addr"
