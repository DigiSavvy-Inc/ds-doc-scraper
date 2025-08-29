#!/bin/bash

# Setup script for documentation scraper
# This script creates a virtual environment and installs dependencies

set -e  # Exit on any error

# Color setup for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}= Documentation Scraper Setup           =${NC}"
echo -e "${BLUE}=========================================${NC}"
echo

# Check if Python is installed
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${RED}Error: Python is not installed. Please install Python 3.7+ first.${NC}"
    exit 1
fi

# Determine Python command
PYTHON_CMD="python3"
if ! command -v python3 &> /dev/null; then
    PYTHON_CMD="python"
fi

echo -e "${YELLOW}Using Python: $($PYTHON_CMD --version)${NC}"
echo

# Check if virtual environment already exists
if [ -d "venv" ]; then
    echo -e "${YELLOW}Virtual environment already exists.${NC}"
    read -p "Do you want to recreate it? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing virtual environment..."
        rm -rf venv
    else
        echo -e "${BLUE}Keeping existing virtual environment.${NC}"
    fi
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    $PYTHON_CMD -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi

# Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    # Windows
    source venv/Scripts/activate 2>/dev/null || venv\\Scripts\\activate
else
    # macOS/Linux
    source venv/bin/activate
fi

# Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
pip install --upgrade pip -q

# Install requirements
echo -e "${YELLOW}Installing required packages...${NC}"
pip install -r requirements.txt

echo -e "${GREEN}✓ All packages installed${NC}"

# Make scripts executable (Unix-like systems only)
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" && "$OSTYPE" != "win32" ]]; then
    echo -e "${YELLOW}Making scripts executable...${NC}"
    chmod +x scripts/*.py scripts/*.sh 2>/dev/null || true
    echo -e "${GREEN}✓ Scripts are now executable${NC}"
fi

echo
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}= Setup Complete!                       =${NC}"
echo -e "${GREEN}=========================================${NC}"
echo
echo -e "${BLUE}Virtual environment is now active and ready to use.${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. To scrape from a sitemap:"
echo "   python scripts/sitemap_parser.py https://example.com/sitemap.xml"
echo
echo "2. To scrape from URLs:"
echo "   python scripts/scraper.py urls.csv"
echo
echo "3. To deactivate the virtual environment when done:"
echo "   deactivate"
echo
echo -e "${YELLOW}Remember to activate the virtual environment in new terminal sessions:${NC}"
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    echo "   venv\\Scripts\\activate"
else
    echo "   source venv/bin/activate"
fi