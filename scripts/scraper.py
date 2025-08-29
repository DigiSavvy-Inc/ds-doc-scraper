#!/usr/bin/env python3
"""
Main scraper for converting web content to Markdown.
"""
import os
import sys
import argparse
import pandas as pd
from urllib.parse import urlparse
from tqdm import tqdm
import logging

# Check for virtual environment (optional warning)
try:
    from check_venv import warn_if_not_venv
    warn_if_not_venv()
except ImportError:
    pass  # check_venv is optional

from utils import (
    setup_directory,
    clean_filename,
    fetch_url,
    html_to_markdown,
    save_markdown
)

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def process_url(url, output_dir, delay=1):
    """Process a single URL and save as markdown."""
    # Fetch content
    soup, response = fetch_url(url, delay)
    if not soup:
        logger.error(f"Failed to process {url}")
        return None
    
    # Extract title for filename if available
    title = None
    if soup.title:
        title = soup.title.string
    
    # Generate filename
    filename = clean_filename(url, title)
    
    # Convert to markdown
    base_url = f"{urlparse(url).scheme}://{urlparse(url).netloc}"
    markdown_content = html_to_markdown(soup, base_url)
    
    # Add source URL at the top of the markdown content
    if markdown_content.startswith('# '):
        # If content starts with a title, insert after the title
        lines = markdown_content.split('\n', 1)
        if len(lines) > 1:
            markdown_content = f"{lines[0]}\n\n> **Source**: [{url}]({url})\n\n{lines[1]}"
        else:
            markdown_content = f"{lines[0]}\n\n> **Source**: [{url}]({url})"
    else:
        # Insert at the beginning
        markdown_content = f"> **Source**: [{url}]({url})\n\n{markdown_content}"
    
    # Save to file
    filepath = save_markdown(markdown_content, output_dir, filename)
    
    return filepath

def process_csv(csv_path, output_dir, delay=1, column_name='url'):
    """Process all URLs in a CSV file."""
    # Create output directory
    setup_directory(output_dir)
    
    # Read CSV
    try:
        df = pd.read_csv(csv_path)
    except Exception as e:
        logger.error(f"Error reading CSV file: {str(e)}")
        return
    
    # Check if URL column exists
    if column_name not in df.columns:
        # Try to find any column that might contain URLs
        url_columns = []
        for col in df.columns:
            if ('url' in col.lower() or 
                'link' in col.lower() or 
                (not df[col].empty and 'http' in str(df[col].iloc[0]).lower())):
                url_columns.append(col)
        
        if url_columns:
            column_name = url_columns[0]
            logger.info(f"Using column '{column_name}' for URLs")
        else:
            logger.error(f"No URL column found in CSV. Available columns: {df.columns.tolist()}")
            return
    
    # Process each URL
    urls = df[column_name].dropna().unique()
    logger.info(f"Found {len(urls)} unique URLs to process")
    
    results = []
    for url in tqdm(urls, desc="Processing URLs"):
        filepath = process_url(url, output_dir, delay)
        if filepath:
            results.append({
                'url': url, 
                'file': filepath,
                'status': 'success'
            })
        else:
            results.append({
                'url': url, 
                'file': None,
                'status': 'failed'
            })
    
    # Save results
    results_df = pd.DataFrame(results)
    results_path = os.path.join(output_dir, 'scraping_results.csv')
    results_df.to_csv(results_path, index=False)
    logger.info(f"Saved results to {results_path}")
    
    # Print summary
    success_count = results_df[results_df['status'] == 'success'].shape[0]
    logger.info(f"Completed: {success_count}/{len(urls)} URLs successfully processed")
    return results_df

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Scrape URLs from CSV and convert to Markdown')
    parser.add_argument('csv_path', help='Path to CSV file containing URLs')
    parser.add_argument('--output', default='knowledge_base', help='Output directory')
    parser.add_argument('--delay', type=float, default=1, help='Delay between requests in seconds')
    parser.add_argument('--column', default='url', help='Column name in CSV that contains URLs')
    
    args = parser.parse_args()
    
    logger.info(f"Starting scraper with CSV: {args.csv_path}")
    process_csv(args.csv_path, args.output, args.delay, args.column)
    logger.info("Scraping completed")

if __name__ == "__main__":
    main()