# Goose Runner - Native Windows
# Run: powershell -ExecutionPolicy Bypass -File run-goose.ps1

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $PROJECT_DIR

# Ensure Goose is in PATH
$gooseDir = Join-Path $env:LOCALAPPDATA "Programs\goose"
if (Test-Path $gooseDir) { $env:Path = "$gooseDir;$env:Path" }

# Detect Goose
$gooseCmd = Get-Command goose -ErrorAction SilentlyContinue
if (-not $gooseCmd) {
    Write-Host "Error: Goose AI not found. Run .\setup.ps1 first." -ForegroundColor Red
    exit 1
}
$ver = goose --version 2>&1 | Out-String
Write-Host "Using Goose AI: $($gooseCmd.Source)" -ForegroundColor Green
Write-Host "Version: $($ver.Trim())"
Write-Host ""

# Ensure Ollama is running
$ollamaUp = $false
try {
    $null = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3
    $ollamaUp = $true
} catch {}

if (-not $ollamaUp) {
    Write-Host "Ollama not running. Starting..."
    $svc = Get-Service -Name "Ollama" -ErrorAction SilentlyContinue
    if ($svc) {
        Start-Service "Ollama" -ErrorAction SilentlyContinue
    } else {
        Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
    }
    Start-Sleep -Seconds 5
    try {
        $null = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 5
        $ollamaUp = $true
    } catch {}
}
if (-not $ollamaUp) {
    Write-Host "Error: Ollama not responding. Start it manually: ollama serve" -ForegroundColor Red
    exit 1
}

# Check cloud models
$models = ollama list 2>&1 | Out-String
$cloudCount = ($models -split "`n" | Where-Object { $_ -match ":cloud" }).Count
if ($cloudCount -eq 0) {
    Write-Host "Warning: No cloud models found. Run scripts/setup/configure-cloud-models.sh" -ForegroundColor Yellow
}

Write-Host "Starting Goose with Ollama Cloud Models..."
Write-Host "Available cloud models:"
ollama list 2>&1 | Out-String -Stream | Where-Object { $_ -match ":cloud" } | Select-Object -First 5 | ForEach-Object { "  - $_" }
Write-Host ""

# Activate Python venv
$venvActivate = Join-Path $PROJECT_DIR "venv\Scripts\Activate.ps1"
if (Test-Path $venvActivate) {
    & $venvActivate
}

# Set Goose env vars
$env:GOOSE_PROVIDER = "ollama"
$env:GOOSE_MODEL = "qwen3.5:cloud"

# Launch Goose
goose session --name minimax-ollama
