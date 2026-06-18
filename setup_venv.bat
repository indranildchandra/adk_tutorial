@echo off
REM ADK Agent Virtual Environment Setup Script for Windows
REM Usage:
REM   setup_venv.bat                       # Vertex AI (default)
REM   setup_venv.bat --use-gemini-api-key  # Gemini API key

setlocal enabledelayedexpansion

REM Parse flags
set USE_GEMINI=0
for %%a in (%*) do (
    if "%%a"=="--use-gemini-api-key" set USE_GEMINI=1
)

echo Setting up ADK Agent virtual environment...

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python is required but not installed. Please install Python 3.9 or higher.
    pause
    exit /b 1
)

REM Get Python version and check it is 3.9+
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set python_version=%%i
echo Python %python_version% detected.

python -c "import sys; exit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python 3.9 or higher is required. Current version: %python_version%
    pause
    exit /b 1
)

REM Create virtual environment
echo Creating virtual environment (.adk_env)...
python -m venv .adk_env

REM Activate virtual environment
echo Activating virtual environment...
call .adk_env\Scripts\activate.bat

REM Upgrade pip
echo Upgrading pip...
pip install --upgrade pip --quiet

REM Install requirements
echo Installing dependencies...
pip install -r requirements.txt --quiet

REM --- Authentication setup ---
echo.
echo --- Authentication Setup ---

if "!USE_GEMINI!"=="1" (
    REM --- Gemini API key ---
    echo.
    echo Get a free API key at: https://aistudio.google.com/apikey
    set /p user_api_key="Please enter your Gemini API key: "

    if not defined user_api_key (
        echo ERROR: No API key was entered. Please re-run the script and provide your key.
        exit /b 1
    )

    echo Creating .env file...
    (
        echo # Environment variables for ADK Agent, created by setup_venv.bat
        echo GOOGLE_GENAI_USE_VERTEXAI=FALSE
        echo GOOGLE_API_KEY=!user_api_key!
    ) > .env

) else (
    REM --- Vertex AI ---
    echo.
    echo Checking gcloud authentication status...
    gcloud auth application-default print-access-token >nul 2>&1
    if !errorlevel! neq 0 (
        echo ERROR: Not authenticated with Google Cloud.
        echo Please run: gcloud auth application-default login
        exit /b 1
    )
    echo Authenticated with Google Cloud.

    set /p user_project_id="Please enter your Google Cloud project ID: "
    if not defined user_project_id (
        echo ERROR: No project ID was entered. Please re-run the script.
        exit /b 1
    )

    echo Creating .env file...
    (
        echo # Environment variables for ADK Agent, created by setup_venv.bat
        echo GOOGLE_GENAI_USE_VERTEXAI=TRUE
        echo GOOGLE_CLOUD_PROJECT=!user_project_id!
        echo GOOGLE_CLOUD_LOCATION=us-central1
    ) > .env
)

REM --- Set up the MCP trip database ---
echo.
echo Setting up the trip database for module g_agents_mcp...
python setup_trip_database.py
echo Trip database created.

echo.
echo Setup complete. A '.env' file has been created with your configuration.
echo.
echo To activate the virtual environment, run:
echo    .adk_env\Scripts\activate
echo.
echo To start the ADK web UI, run:
echo    adk web
echo.
echo To deactivate the virtual environment when done, run:
echo    deactivate
echo.
pause
