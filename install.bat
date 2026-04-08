@echo off
REM Install Python dependencies for the Telegram bot on Windows (CMD).
REM Usage: install.bat

cd /d %~dp0

echo == Telegram bot Windows setup ==

where python >nul 2>&1
if errorlevel 1 (
    echo python.exe not found. Attempting auto-install via winget/choco...
    where winget >nul 2>&1
    if %errorlevel% EQU 0 (
        echo Installing Python via winget...
        winget install --id Python.Python.3 -e --source winget
    ) else (
        where choco >nul 2>&1
        if %errorlevel% EQU 0 (
            echo Installing Python via Chocolatey...
            choco install python -y
        ) else (
            echo ERROR: python.exe not found and no winget/choco available.
            echo Install Python 3.9+ manually.
            pause
            exit /b 1
        )
    )
)

where python >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python installation failed or python still not found.
    pause
    exit /b 1
)

echo.
for /f "tokens=2 delims=[]" %%v in ('python -c "import sys; print(sys.version_info[:3])"') do set PYVER=%%v
for /f "tokens=1,2 delims=, " %%a in ("%PYVER%") do (
    set PY_MAJOR=%%a
    set PY_MINOR=%%b
)

if %PY_MAJOR% LSS 3 (
    echo ERROR: Python 3.9 or newer is required. Current version: %PYVER%
    pause
    exit /b 1
)
if %PY_MAJOR% EQU 3 if %PY_MINOR% LSS 9 (
    echo ERROR: Python 3.9 or newer is required. Current version: %PYVER%
    pause
    exit /b 1
)

if not exist requirements.txt (
    echo ERROR: requirements.txt not found.
    pause
    exit /b 1
)

if not exist venv (
    echo Creating Python virtual environment...
    python -m venv venv
)

echo Installing dependencies...
venv\Scripts\python.exe -m pip install --upgrade pip
venv\Scripts\python.exe -m pip install -r requirements.txt

echo.
echo Setup complete. Run the bot with:
echo   venv\Scripts\Activate.ps1
echo   python bot.py

echo or
necho   venv\Scripts\python.exe bot.py
pause
