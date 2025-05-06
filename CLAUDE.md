# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a content scraper tool designed to download content from websites, convert it to Markdown files, and ensure proper formatting and organization. It supports reading from CSV files or sitemap.xml to determine what content to scrape.

## Project Structure

```
content-scraper/
├── scripts/
│   ├── scraper.py            # Main scraper for CSV input
│   ├── sitemap_parser.py     # Parse sitemap.xml files
│   ├── utils.py              # Helper functions
│   ├── batch_scraper.py      # Parallel version for multiple URLs
│   ├── check_missing.py      # Compare URLs with existing files
│   └── organize_docs.sh      # Organize markdown files
├── knowledge_base/           # Default output directory
├── requirements.txt          # Python dependencies
└── README.md                 # Project documentation
```

## Scripts and Tools

### Python Scripts

```
python scripts/scraper.py <input_path> [--output <dir>] [--delay <seconds>]
```
- Scrapes URLs listed in a CSV file and converts content to Markdown
- `<input_path>`: Path to CSV file with URLs to scrape
- `--output`: Specify the output directory (default: 'knowledge_base')
- `--delay`: Time delay between requests (default: 1 second)

```
python scripts/sitemap_parser.py <sitemap_url> [--output <file.csv>]
```
- Parses a sitemap.xml file and extracts URLs
- `<sitemap_url>`: URL to the sitemap.xml file
- `--output`: Specify the output CSV file (default: 'urls.csv')

```
python scripts/batch_scraper.py <input_path> [--output <dir>] [--delay <seconds>] [--workers <num>]
```
- Parallel version of the scraper for processing multiple URLs simultaneously
- `--workers`: Number of parallel workers (default: 5)

```
python scripts/check_missing.py <input_path> <docs_dir>
```
- Checks for missing documents by comparing URLs in the CSV with existing files

### Bash Scripts

```
bash scripts/organize_docs.sh <input_dir> [--output <dir>]
```
- Organizes scraped markdown files using predefined categories
- Improves filenames for better readability (removes trailing underscores, etc.)

```
bash scripts/interactive_organize.sh
```
- Interactive script for organizing markdown files
- Allows custom categories and keywords
- Provides options to maintain existing structure
- Offers file organization previews and summaries

```
bash prepare_for_deployment.sh
```
- Prepares the documentation for deployment to GitHub
- Creates a clean deployment directory with organized documentation
- Generates a new README.md for the GitHub repository

## Dependencies

The Python scripts require the following dependencies (from requirements.txt):

- beautifulsoup4 - For HTML parsing
- requests - For HTTP requests
- pandas - For data manipulation and CSV handling
- tqdm - For progress bars
- Other standard libraries (datetime, json, etc.)

Install dependencies with:
```
pip install -r requirements.txt
```

## Best Practices When Working with This Repository

1. **Running Scripts**:
   - Run scripts from the repository root
   - Use appropriate delay parameters to be considerate to web servers
   - Use the batch versions for large-scale scraping

2. **File Naming Convention**:
   - Use kebab-case for filenames (e.g., `article-name.md`)
   - Avoid special characters or spaces in filenames

3. **Input Format**:
   - CSV files should have a column named 'url' (or similar) containing the URLs to scrape
   - Sitemap.xml files should follow the standard sitemap protocol