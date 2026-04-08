# Install Python dependencies for the Telegram bot on Windows.
# Usage: Open PowerShell in this folder and run: .\install.ps1

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
Set-Location $ScriptDir

Write-Host "== Telegram bot Windows setup =="

function Test-Python {
    try {
        python --version | Out-Null
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-Python)) {
    Write-Host "python.exe not found. Attempting to install Python 3..."

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Installing Python via winget..."
        winget install --id Python.Python.3 -e --source winget
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing Python via Chocolatey..."
        choco install python -y
    } else {
        Write-Error "ERROR: Python not found and no winget/choco available. Install Python 3.9+ manually."
        exit 1
    }

    if (-not (Test-Python)) {
        Write-Error "ERROR: Python installation failed. Install Python 3.9+ manually."
        exit 1
    }
}

$pythonVersion = python -c "import sys; print(sys.version_info[:3])" 2>$null
if (-not $pythonVersion) {
    Write-Error "ERROR: Unable to determine Python version."
    exit 1
}

$versionTuple = ($pythonVersion -replace '[^0-9,]','').Split(',') | ForEach-Object { [int]$_ }
if ($versionTuple[0] -lt 3 -or ($versionTuple[0] -eq 3 -and $versionTuple[1] -lt 9)) {
    Write-Error "ERROR: Python 3.9 or newer is required. Current version: $(python --version)"
    exit 1
}

if (-not (Test-Path requirements.txt)) {
    Write-Error "ERROR: requirements.txt not found in $ScriptDir"
    exit 1
}

if (-not (Test-Path venv)) {
    Write-Host "Creating Python virtual environment..."
    python -m venv venv
}

Write-Host "Installing dependencies..."
& .\venv\Scripts\python.exe -m pip install --upgrade pip
& .\venv\Scripts\python.exe -m pip install -r requirements.txt

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Warning "WARNING: ffmpeg is not installed. Audio extraction will fail until ffmpeg is installed."
    Write-Warning "Install ffmpeg manually or via a package manager such as winget or choco."
}

if (-not (Test-Path downloads)) {
    New-Item -ItemType Directory -Path downloads | Out-Null
}

Write-Host "`nSetup complete. Run the bot with:"
Write-Host "  .\venv\Scripts\Activate.ps1"
Write-Host "  python bot.py"
Write-Host "or"
Write-Host "  .\venv\Scripts\python.exe bot.py"
