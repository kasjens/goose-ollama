# Full Dependency Installation - Windows
# Installs PyTorch, Node.js, FFmpeg, and all skill dependencies
#
# If blocked by execution policy:
#   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"
$PROJECT_DIR = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $PROJECT_DIR

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

Write-Host "============================================"
Write-Host "Full Dependency Installation (Windows)"
Write-Host "============================================"
Write-Host ""

# -- 1. System dependencies (portable installs - no admin needed) -------------
Write-Host "System Dependencies" -ForegroundColor Magenta
Write-Host "-------------------"

$ErrorActionPreference = "Continue"

# Node.js via fnm (Fast Node Manager - no admin needed)
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command fnm -ErrorAction SilentlyContinue)) {
        Write-Host "  Installing fnm (Fast Node Manager)..."
        winget install Schniz.fnm --accept-source-agreements --accept-package-agreements --silent
        Refresh-Path
    }
    if (Get-Command fnm -ErrorAction SilentlyContinue) {
        Write-Host "  Installing Node.js LTS via fnm..."
        fnm install --lts 2>&1 | Out-Null
        fnm default lts-latest 2>&1 | Out-Null
        fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

        # Add fnm shell hook to PowerShell profile for future sessions
        $profilePath = $PROFILE.CurrentUserAllHosts
        if (-not (Test-Path $profilePath)) {
            New-Item -ItemType File -Path $profilePath -Force | Out-Null
        }
        $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
        if (-not $profileContent -or $profileContent -notmatch "fnm env") {
            Add-Content $profilePath "`nfnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression"
        }

        # Also add fnm's node to permanent user PATH so Desktop UI and other apps can find npx
        $nodeExe = Get-ChildItem "$env:APPDATA\fnm\node-versions" -Recurse -Filter "node.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($nodeExe) {
            $nodeInstallDir = $nodeExe.DirectoryName
            $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
            if ($userPath -notlike "*$nodeInstallDir*") {
                [System.Environment]::SetEnvironmentVariable("Path", "$nodeInstallDir;$userPath", "User")
                $env:Path = "$nodeInstallDir;$env:Path"
            }
        }
    }
}
if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Host "  OK Node.js $(node --version) (via fnm)" -ForegroundColor Green
} else {
    Write-Host "  !! Node.js not installed. Install fnm manually: winget install Schniz.fnm" -ForegroundColor Yellow
}

# FFmpeg - portable zip (no admin)
$ffmpegDir = Join-Path $env:LOCALAPPDATA "Programs\ffmpeg"
if (Test-Path "$ffmpegDir\bin") { $env:Path = "$ffmpegDir\bin;$env:Path" }

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing FFmpeg (portable)..."
    $ffmpegZip = Join-Path $env:TEMP "ffmpeg.zip"
    Invoke-WebRequest -Uri "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -OutFile $ffmpegZip -UseBasicParsing
    Expand-Archive -Path $ffmpegZip -DestinationPath $env:TEMP -Force
    if (Test-Path $ffmpegDir) { Remove-Item $ffmpegDir -Recurse -Force }
    Move-Item (Join-Path $env:TEMP "ffmpeg-master-latest-win64-gpl") $ffmpegDir
    Remove-Item $ffmpegZip -ErrorAction SilentlyContinue
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$ffmpegDir*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$ffmpegDir\bin;$userPath", "User")
    }
    $env:Path = "$ffmpegDir\bin;$env:Path"
}
if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    Write-Host "  OK FFmpeg installed" -ForegroundColor Green
} else {
    Write-Host "  !! FFmpeg install failed (optional - needed for media skills)" -ForegroundColor Yellow
}

# ImageMagick - winget first (reliable), fall back to the latest GitHub
# installer silently. The old imagemagick.org archive URL 404'd after upstream
# switched portable zips to .7z which Expand-Archive can't read.
if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing ImageMagick..."
    $installed = $false
    try {
        winget install --id ImageMagick.ImageMagick -e --source winget `
            --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $installed = $true }
    } catch { }
    Refresh-Path

    if (-not $installed -and -not (Get-Command magick -ErrorAction SilentlyContinue)) {
        try {
            Write-Host "  winget route unavailable - fetching latest installer from GitHub..."
            $release = Invoke-RestMethod "https://api.github.com/repos/ImageMagick/ImageMagick/releases/latest" -UseBasicParsing
            $asset = $release.assets | Where-Object { $_.name -match 'Q16-HDRI-x64-dll\.exe$' } | Select-Object -First 1
            if ($asset) {
                $magickExe = Join-Path $env:TEMP $asset.name
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $magickExe -UseBasicParsing
                Start-Process -FilePath $magickExe -ArgumentList "/VERYSILENT","/NORESTART","/SUPPRESSMSGBOXES" -Wait
                Remove-Item $magickExe -ErrorAction SilentlyContinue
                Refresh-Path
            }
        } catch { }
    }
}
if (Get-Command magick -ErrorAction SilentlyContinue) {
    Write-Host "  OK ImageMagick installed" -ForegroundColor Green
} else {
    Write-Host "  !! ImageMagick install failed (optional - needed for image skills)" -ForegroundColor Yellow
}

$ErrorActionPreference = "Stop"
Write-Host ""

# -- 2. Python venv -----------------------------------------------------------
Write-Host "Python Environment" -ForegroundColor Magenta
Write-Host "------------------"

$venvActivate = Join-Path $PROJECT_DIR "venv\Scripts\Activate.ps1"
if (-not (Test-Path $venvActivate)) {
    Write-Host "  Creating virtual environment..."
    python -m venv venv
}
Write-Host "  OK Virtual environment ready" -ForegroundColor Green

& $venvActivate
$ErrorActionPreference = "Continue"

# -- 3. Python dependencies ---------------------------------------------------
Write-Host ""
Write-Host "Python Dependencies (full)" -ForegroundColor Magenta
Write-Host "--------------------------"

Write-Host "  Installing core packages..."
pip install -q --upgrade pip 2>&1 | Out-Null
pip install -q pandas numpy pillow pypdf python-docx openpyxl matplotlib requests 2>&1 | Out-Null

Write-Host "  Installing document processing..."
pip install -q "markitdown[pptx]" python-pptx 2>&1 | Out-Null

Write-Host "  Installing AI/ML packages..."
pip install -q opencv-python scikit-image scikit-learn transformers 2>&1 | Out-Null

Write-Host "  Installing PyTorch (CPU)..."
pip install -q torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu 2>&1 | Out-Null

Write-Host "  Installing web tools..."
pip install -q beautifulsoup4 lxml html5lib 2>&1 | Out-Null

Write-Host "  Installing media processing..."
pip install -q moviepy pydub librosa soundfile 2>&1 | Out-Null

Write-Host "  Installing web frameworks..."
pip install -q fastapi uvicorn streamlit gradio jinja2 websockets aiofiles 2>&1 | Out-Null

Write-Host "  Installing utilities..."
pip install -q python-dotenv pyyaml jsonschema click rich 2>&1 | Out-Null

$ErrorActionPreference = "Stop"
Write-Host "  OK All Python packages installed" -ForegroundColor Green

deactivate

# -- 4. Node.js packages ------------------------------------------------------
Write-Host ""
Write-Host "Node.js Packages" -ForegroundColor Magenta
Write-Host "-----------------"

if (Get-Command node -ErrorAction SilentlyContinue) {
    $ErrorActionPreference = "Continue"
    if (-not (Test-Path "package.json")) {
        npm init -y 2>&1 | Out-Null
    }
    Write-Host "  Installing Node packages..."
    npm install --save pptxgenjs react react-dom react-icons sharp 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"
    Write-Host "  OK Node packages installed" -ForegroundColor Green
} else {
    Write-Host "  !! Skipping - Node.js not installed" -ForegroundColor Yellow
}

# -- 5. Goose AI (verify) ----------------------------------------------------
Write-Host ""
Write-Host "Goose AI" -ForegroundColor Magenta
Write-Host "--------"

$gooseDir = Join-Path $env:LOCALAPPDATA "Programs\goose"
if (Test-Path $gooseDir) { $env:Path = "$gooseDir;$env:Path" }

if (Get-Command goose -ErrorAction SilentlyContinue) {
    $v = goose --version 2>&1 | Out-String
    Write-Host "  OK Goose AI installed ($($v.Trim()))" -ForegroundColor Green
} else {
    Write-Host "  !! Goose AI not found. Run .\setup.ps1 first." -ForegroundColor Yellow
}

# -- Done ---------------------------------------------------------------------
Write-Host ""
Write-Host "============================================"
Write-Host "Full Dependency Installation Complete!" -ForegroundColor Green
Write-Host "============================================"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Set up web search: scripts\setup-brave-search.ps1"
Write-Host "  2. Validate: .\validate.ps1"
Write-Host "  3. Run Goose: .\run-goose.ps1"
