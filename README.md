# Content Scraper

A flexible tool for scraping website content and converting it to well-formatted Markdown files for enhanced AI-powered documentation.

## Purpose

This repository provides tools to gather documentation from websites and convert it to GitHub-friendly Markdown format. The resulting documentation repository creates a valuable resource for developers using AI-enhanced tools, enabling better knowledge access and management.

### Key Benefits

- **Enhanced AI Integration**: Modern development workflows leverage Large Language Model (LLM) tools like ChatGPT and Claude. These AI assistants can directly connect to GitHub repositories, allowing developers to have interactive conversations about documentation stored here.

- **Unified Knowledge Base**: By centralizing documentation in a GitHub repository, teams can maintain context while accessing information, creating a more seamless development experience.

- **Version Control and History**: Documentation changes are tracked with robust version control, making it easier to understand how documentation evolves alongside software.

- **Community Contributions**: GitHub's established contribution workflow (issues, pull requests, discussions) enables easier community suggestions for improvements or corrections to documentation.

## Features

- Scrape content from URLs listed in CSV files
- Parse sitemap.xml files to extract URLs for scraping
- Convert HTML content to clean Markdown format
- Organize content into appropriate directories
- Clean and format filenames
- Parallel processing for faster scraping

## Installation

### Option 1: Standard Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/content-scraper.git
cd content-scraper

# Install dependencies
pip install -r requirements.txt
```

### Option 2: Using Virtual Environment (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/content-scraper.git
cd content-scraper

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

## Step-by-Step Guide

Here's how to scrape your first website:

1. **Get URLs to scrape** (choose one method):
   ```bash
   # Method A: Extract URLs from a sitemap
   python scripts/sitemap_parser.py https://example.com/sitemap.xml --output urls.csv
   
   # Method B: Create your own CSV file with URLs to scrape
   # (Create a CSV file with a column named "url")
   ```

2. **Run the scraper**:
   ```bash
   # Option 1: Basic scraper
   python scripts/scraper.py urls.csv --output knowledge_base --delay 1
   
   # Option 2: Parallel scraper (faster)
   python scripts/batch_scraper.py urls.csv --output knowledge_base --workers 5
   ```

3. **Organize the content** (optional):
   ```bash
   bash scripts/organize_docs.sh knowledge_base --output organized_docs
   ```

4. **Prepare for GitHub deployment** (optional):
   ```bash
   bash prepare_for_deployment.sh
   ```

## Usage Examples

```bash
# Scrape URLs from a CSV file
python scripts/scraper.py input.csv --output knowledge_base --delay 1

# Parse a sitemap.xml and generate a CSV file
python scripts/sitemap_parser.py https://example.com/sitemap.xml --output urls.csv

# Scrape using multiple workers for faster processing
python scripts/batch_scraper.py input.csv --output knowledge_base --workers 5

# Check for missing documents
python scripts/check_missing.py input.csv knowledge_base

# Organize documents into a structured format
bash scripts/organize_docs.sh knowledge_base --output organized_docs

# Prepare for GitHub deployment
bash prepare_for_deployment.sh
```

### Input Format

- **CSV files** should have a column with URLs to scrape
- **sitemap.xml** should follow the standard sitemap protocol

## Output

By default, all scraped content is saved to the `knowledge_base` directory in Markdown format. The organized content is placed in the `organized_docs` directory, and prepared for deployment in the `deployment` directory.

## Deployment

The `prepare_for_deployment.sh` script helps you prepare the documentation for GitHub:

1. Creates a clean `deployment` directory with only necessary files
2. Organizes documentation into an appropriate structure
3. Generates a new README.md suitable for GitHub display

After running the deployment script, follow the on-screen instructions to initialize a new git repository and push to GitHub.

## License

MIT