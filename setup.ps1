# Goose + Ollama MiniMax - One-Step Setup for Windows 11
#
# If you see "running scripts is disabled on this system", run this first:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
#
# Then re-run: .\setup.ps1

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $PROJECT_DIR

function Step  { param($n,$msg) Write-Host "`n[$n/8] $msg" -ForegroundColor Blue }
function Ok    { param($msg)    Write-Host "  OK $msg" -ForegroundColor Green }
function Warn  { param($msg)    Write-Host "  !! $msg" -ForegroundColor Yellow }
function Fail  { param($msg)    Write-Host "  FAIL $msg" -ForegroundColor Red; exit 1 }

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

# -- 1. Prerequisites --------------------------------------------------------
Step 1 "Checking prerequisites..."

# Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Python..."
    winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements --silent
    Refresh-Path
}
if (Get-Command python -ErrorAction SilentlyContinue) {
    Ok "Python $(python --version 2>&1)"
} else {
    Fail "Python not found. Install from https://www.python.org/downloads/"
}

# Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Git..."
    winget install Git.Git --accept-source-agreements --accept-package-agreements --silent
    Refresh-Path
}
if (Get-Command git -ErrorAction SilentlyContinue) {
    Ok "Git installed"
} else {
    Fail "Git not found. Install from https://git-scm.com/"
}

# -- 2. Ollama ---------------------------------------------------------------
Step 2 "Checking Ollama..."

Refresh-Path
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Ollama (official installer)..."
    irm https://ollama.com/install.ps1 | iex
    Refresh-Path
    Start-Sleep -Seconds 3
}
if (Get-Command ollama -ErrorAction SilentlyContinue) {
    Ok "Ollama installed"
} else {
    Fail "Ollama not found. Install from https://ollama.com/download"
}

# -- 3. Ollama service -------------------------------------------------------
Step 3 "Ensuring Ollama is running..."

$ollamaUp = $false
try {
    $null = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 3
    $ollamaUp = $true
} catch {}

if (-not $ollamaUp) {
    # Try Windows Service first
    $svc = Get-Service -Name "Ollama" -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -ne 'Running') {
        Start-Service "Ollama" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    } else {
        # Fall back to starting ollama serve in background
        Write-Host "  Starting ollama serve..."
        Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 5
    }
    try {
        $null = Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 5
        $ollamaUp = $true
    } catch {}
}

if ($ollamaUp) {
    Ok "Ollama service is running"
} else {
    Fail "Could not start Ollama. Try manually: ollama serve"
}

# -- 4. Ollama cloud sign-in -------------------------------------------------
Step 4 "Checking Ollama cloud sign-in..."

# Ollama writes progress to stderr - temporarily allow errors
$ErrorActionPreference = "Continue"

$models = ollama list 2>&1 | Out-String
if ($models -match ":cloud") {
    $ErrorActionPreference = "Stop"
    Ok "Signed in to Ollama cloud"
} else {
    $pullResult = ollama pull minimax-m2.7:cloud 2>&1 | Out-String
    if ($pullResult -match "success|up to date") {
        $ErrorActionPreference = "Stop"
        Ok "Signed in to Ollama cloud"
    } else {
        Warn "You need to sign in to Ollama for cloud model access."
        Write-Host ""
        Write-Host "  Run this now (it will open a browser link):"
        Write-Host "    ollama signin"
        Write-Host ""
        Read-Host "  Press Enter after you have signed in"
        $pullResult2 = ollama pull minimax-m2.7:cloud 2>&1 | Out-String
        $ErrorActionPreference = "Stop"
        if ($pullResult2 -notmatch "success|up to date") {
            Fail "Still not signed in. Run 'ollama signin' and try setup again."
        }
        Ok "Signed in to Ollama cloud"
    }
}

# -- 5. Pull cloud models ----------------------------------------------------
Step 5 "Pulling cloud models..."

$ErrorActionPreference = "Continue"
$models = ollama list 2>&1 | Out-String
$cloudModels = @(
    @{ name = "qwen3.5:cloud";            desc = "Qwen 3.5 - multimodal, default" }
    @{ name = "qwen3-coder:480b-cloud";   desc = "Qwen3-Coder 480B - #1 coding model" }
    @{ name = "deepseek-v3.1:671b-cloud"; desc = "DeepSeek V3.1 671B - strong coding/reasoning" }
    @{ name = "gemma4:31b-cloud";         desc = "Gemma 4 31B - multimodal, 256K context" }
    @{ name = "minimax-m2.7:cloud";       desc = "MiniMax M2.7 - balanced text generation" }
)
foreach ($m in $cloudModels) {
    if ($models -match [regex]::Escape($m.name)) {
        Ok "$($m.name) already pulled"
    } else {
        Write-Host "  Pulling $($m.name) ($($m.desc))..."
        ollama pull $m.name 2>&1 | Out-Null
        Ok "$($m.name) pulled"
    }
}
$ErrorActionPreference = "Stop"

# -- 6. Python virtual environment -------------------------------------------
Step 6 "Setting up Python environment..."

$venvActivate = Join-Path $PROJECT_DIR "venv\Scripts\Activate.ps1"

if (-not (Test-Path $venvActivate)) {
    # Remove broken venv if exists
    $venvDir = Join-Path $PROJECT_DIR "venv"
    if (Test-Path $venvDir) { Remove-Item $venvDir -Recurse -Force }
    Write-Host "  Creating virtual environment..."
    python -m venv venv
    if (-not (Test-Path $venvActivate)) {
        Fail "venv creation failed"
    }
    Ok "Virtual environment created"
} else {
    Ok "Virtual environment already exists"
}

Write-Host "  Installing pip packages (this may take a few minutes)..."
& $venvActivate
$ErrorActionPreference = "Continue"
pip install --upgrade pip 2>&1 | Out-Null
pip install -r config\requirements-core.txt 2>&1 | Select-String "^(Collecting|Installing|Successfully)" | ForEach-Object { "  $_" }
$ErrorActionPreference = "Stop"
deactivate
Ok "Python dependencies installed"

# -- 7. Skills integration ----------------------------------------------------
Step 7 "Integrating skills..."

$skillsDir = Join-Path $PROJECT_DIR ".agents\skills"
$skillCount = 0
if (Test-Path $skillsDir) {
    $skillCount = (Get-ChildItem $skillsDir -Directory -ErrorAction SilentlyContinue).Count
}

if ($skillCount -eq 0) {
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null

    if (-not (Test-Path "anthropic-skills")) {
        Write-Host "  Cloning Anthropic skills..."
        git clone --depth 1 -q https://github.com/anthropics/skills.git anthropic-skills
    }
    if (-not (Test-Path "minimax-skills")) {
        Write-Host "  Cloning MiniMax skills..."
        git clone --depth 1 -q https://github.com/MiniMax-AI/skills.git minimax-skills
    }

    if (Test-Path "anthropic-skills\skills") {
        Copy-Item -Recurse -Force "anthropic-skills\skills\*" $skillsDir -ErrorAction SilentlyContinue
    }
    if (Test-Path "minimax-skills\skills") {
        Copy-Item -Recurse -Force "minimax-skills\skills\*" $skillsDir -ErrorAction SilentlyContinue
    }

    $skillCount = (Get-ChildItem $skillsDir -Directory).Count
    Ok "$skillCount skills integrated"
} else {
    Ok "$skillCount skills already available"
}

# Junction in home directory so Desktop UI discovers skills
$homeAgents = Join-Path $env:USERPROFILE ".agents"
if (-not (Test-Path $homeAgents)) {
    cmd /c mklink /J "$homeAgents" "$PROJECT_DIR\.agents" | Out-Null
    Ok "Created .agents junction for Desktop UI skill discovery"
} elseif ((Get-Item $homeAgents).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    Ok ".agents junction already exists"
}

# -- 8. Goose AI --------------------------------------------------------------
Step 8 "Checking Goose AI..."

$gooseDir = Join-Path $env:LOCALAPPDATA "Programs\goose"
# Add to session PATH
if (Test-Path $gooseDir) { $env:Path = "$gooseDir;$env:Path" }

if (Get-Command goose -ErrorAction SilentlyContinue) {
    $ver = goose --version 2>&1 | Out-String
    Ok "Goose AI already installed ($($ver.Trim()))"
} else {
    Write-Host "  Installing Goose AI..."
    New-Item -ItemType Directory -Path $gooseDir -Force | Out-Null

    $zipPath = Join-Path $env:TEMP "goose-windows.zip"
    $url = "https://github.com/block/goose/releases/latest/download/goose-x86_64-pc-windows-msvc.zip"
    Write-Host "  Downloading Windows binary..."
    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing

    Write-Host "  Extracting..."
    Expand-Archive -Path $zipPath -DestinationPath $gooseDir -Force

    # Find goose.exe (may be nested)
    $gooseExe = Get-ChildItem $gooseDir -Recurse -Filter "goose.exe" | Select-Object -First 1
    if ($gooseExe -and $gooseExe.DirectoryName -ne $gooseDir) {
        # Flatten nested files to goose dir
        Get-ChildItem $gooseExe.DirectoryName -File | Move-Item -Destination $gooseDir -Force
    }

    Remove-Item $zipPath -ErrorAction SilentlyContinue

    # Add to user PATH permanently
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$gooseDir*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$gooseDir;$userPath", "User")
    }
    $env:Path = "$gooseDir;$env:Path"

    if (Get-Command goose -ErrorAction SilentlyContinue) {
        Ok "Goose AI installed"
    } else {
        Warn "Goose AI installed but may need a new terminal to appear in PATH"
    }
}

# Create Goose config if it doesn't exist (use full template with all extensions)
$configDir = Join-Path $env:USERPROFILE ".config\goose"
$configPath = Join-Path $configDir "config.yaml"
if (-not (Test-Path $configPath)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    $templatePath = Join-Path $PROJECT_DIR "config\goose-config-template.yaml"
    if (Test-Path $templatePath) {
        Copy-Item $templatePath $configPath
    } else {
        @"
extensions:
GOOSE_TELEMETRY_ENABLED: true
GOOSE_PROVIDER: ollama
GOOSE_MODEL: qwen3.5:cloud
"@ | Set-Content $configPath
    }
    Ok "Goose config created at $configPath"
} else {
    Ok "Goose config already exists"
}

# -- Done ---------------------------------------------------------------------
Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Run Goose:  .\run-goose.ps1"
Write-Host "  Validate:   .\validate.ps1"
Write-Host ""
Write-Host "Skills are auto-discovered - just ask naturally:"
Write-Host "  'Create a PowerPoint presentation'"
Write-Host "  'Help me build an iOS app'"
Write-Host "  'Generate a Word document'"
