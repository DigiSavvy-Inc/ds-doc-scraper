#!/usr/bin/env python3
"""
Check for missing documents by comparing URLs in a CSV with existing files.
"""
import os
import argparse
import pandas as pd
import logging
from urllib.parse import urlparse
import re

from utils import clean_filename

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def get_filename_from_url(url):
    """Generate the expected filename for a URL."""
    return clean_filename(url)

def extract_url_pattern(url):
    """Extract a pattern from URL for fuzzy matching."""
    parsed = urlparse(url)
    path = parsed.path.rstrip('/')
    
    # Get the last component of the path
    if '/' in path:
        last_component = path.split('/')[-1]
    else:
        last_component = path
    
    # Clean the component for better matching
    pattern = re.sub(r'[^a-z0-9]', '-', last_component.lower())
    pattern = re.sub(r'-+', '-', pattern)
    return pattern

def find_matching_file(url, docs_dir):
    """Find a file that matches the URL in the docs directory."""
    expected_filename = get_filename_from_url(url)
    
    # Direct match
    if os.path.exists(os.path.join(docs_dir, expected_filename)):
        return expected_filename
    
    # Try to find a file with similar name
    pattern = extract_url_pattern(url)
    if not pattern:
        return None
    
    # Look for files that might be a match
    for filename in os.listdir(docs_dir):
        if filename.lower().endswith('.md'):
            cleaned_name = re.sub(r'[^a-z0-9]', '-', filename.lower())
            if pattern in cleaned_name:
                return filename
    
    return None

def check_missing_docs(csv_path, docs_dir, column_name='url'):
    """Check which URLs from the CSV file are missing in the docs directory."""
    if not os.path.exists(docs_dir):
        logger.error(f"Docs directory not found: {docs_dir}")
        return None
    
    # Read CSV
    try:
        df = pd.read_csv(csv_path)
    except Exception as e:
        logger.error(f"Error reading CSV file: {str(e)}")
        return None
    
    # Check if URL column exists
    if column_name not in df.columns:
        # Try to find any column that might contain URLs
        url_columns = [col for col in df.columns if any(
            'url' in col.lower() or 'link' in col.lower() or 'http' in str(df[col].iloc[0]).lower()
        )]
        
        if url_columns:
            column_name = url_columns[0]
            logger.info(f"Using column '{column_name}' for URLs")
        else:
            logger.error(f"No URL column found in CSV. Available columns: {df.columns.tolist()}")
            return None
    
    # Get all URLs
    urls = df[column_name].dropna().unique()
    logger.info(f"Found {len(urls)} unique URLs in CSV")
    
    # Check each URL
    results = []
    missing_count = 0
    
    for url in urls:
        matching_file = find_matching_file(url, docs_dir)
        
        if matching_file:
            results.append({
                'url': url,
                'file': matching_file,
                'status': 'found'
            })
        else:
            results.append({
                'url': url,
                'file': None,
                'status': 'missing'
            })
            missing_count += 1
    
    # Create result dataframe
    results_df = pd.DataFrame(results)
    
    # Save missing URLs to CSV
    missing_df = results_df[results_df['status'] == 'missing']
    if not missing_df.empty:
        missing_file = 'missing_urls.csv'
        missing_df.to_csv(missing_file, index=False)
        logger.info(f"Saved {len(missing_df)} missing URLs to {missing_file}")
    
    # Log results
    logger.info(f"Results: {len(urls) - missing_count} found, {missing_count} missing")
    
    return results_df

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Check for missing documents')
    parser.add_argument('csv_path', help='Path to CSV file containing URLs')
    parser.add_argument('docs_dir', help='Directory containing markdown documents')
    parser.add_argument('--column', default='url', help='Column name in CSV that contains URLs')
    
    args = parser.parse_args()
    
    logger.info(f"Starting missing docs check with CSV: {args.csv_path}")
    check_missing_docs(args.csv_path, args.docs_dir, args.column)
    logger.info("Check completed")

if __name__ == "__main__":
    main()