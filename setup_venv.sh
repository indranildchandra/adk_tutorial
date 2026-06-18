#!/bin/bash

# ADK Agent Virtual Environment Setup Script
# Usage:
#   ./setup_venv.sh                    # Vertex AI (default)
#   ./setup_venv.sh --use-gemini-api-key  # Gemini API key

set -e  # Exit on any error

# Parse flags
USE_GEMINI=0
for arg in "$@"; do
    case $arg in
        --use-gemini-api-key) USE_GEMINI=1 ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

echo "Setting up ADK Agent virtual environment..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 is required but not installed. Please install Python 3.9 or higher."
    exit 1
fi

# Check Python version
python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
required_version="3.9"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "ERROR: Python $required_version or higher is required. Current version: $python_version"
    exit 1
fi

echo "Python $python_version detected."

# Create virtual environment
echo "Creating virtual environment (.adk_env)..."
python3 -m venv .adk_env

# Activate virtual environment
echo "Activating virtual environment..."
source .adk_env/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip --quiet

# Install requirements
echo "Installing dependencies..."
pip install -r requirements.txt --quiet

# --- Authentication setup ---
echo ""
echo "--- Authentication Setup ---"

if [[ "$USE_GEMINI" == "1" ]]; then
    # --- Gemini API key ---
    echo ""
    echo "Get a free API key at: https://aistudio.google.com/apikey"
    read -p "Please enter your Gemini API key: " user_api_key

    if [[ -z "$user_api_key" ]]; then
        echo "ERROR: No API key was entered. Please re-run the script and provide your key."
        exit 1
    fi

    echo "Creating .env file..."
    cat > .env << EOL
# Environment variables for ADK Agent, created by setup_venv.sh
GOOGLE_GENAI_USE_VERTEXAI=FALSE
GOOGLE_API_KEY=${user_api_key}
EOL

else
    # --- Vertex AI ---
    echo ""
    echo "Checking gcloud authentication status..."
    if ! gcloud auth application-default print-access-token > /dev/null 2>&1; then
        echo "ERROR: Not authenticated with Google Cloud."
        echo "Please run: gcloud auth application-default login"
        exit 1
    fi
    echo "Authenticated with Google Cloud."

    read -p "Please enter your Google Cloud project ID: " user_project_id
    if [[ -z "$user_project_id" ]]; then
        echo "ERROR: No project ID was entered. Please re-run the script."
        exit 1
    fi

    echo "Creating .env file..."
    cat > .env << EOL
# Environment variables for ADK Agent, created by setup_venv.sh
GOOGLE_GENAI_USE_VERTEXAI=TRUE
GOOGLE_CLOUD_PROJECT=${user_project_id}
GOOGLE_CLOUD_LOCATION=us-central1
EOL

fi

# --- Set up the MCP trip database ---
echo ""
echo "Setting up the trip database for module g_agents_mcp..."
python3 setup_trip_database.py
echo "Trip database created."

echo ""
echo "Setup complete. A '.env' file has been created with your configuration."
echo ""
echo "To activate the virtual environment, run:"
echo "   source .adk_env/bin/activate"
echo ""
echo "To start the ADK web UI, run:"
echo "   ./run.sh"
echo ""
echo "To deactivate the virtual environment when done, run:"
echo "   deactivate"
