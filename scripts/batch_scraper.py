#!/usr/bin/env python3
"""
Batch scraper for parallel processing of multiple URLs.
"""
import os
import argparse
import pandas as pd
import logging
from concurrent.futures import ThreadPoolExecutor
from tqdm import tqdm

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
    try:
        # Fetch content
        soup, response = fetch_url(url, delay)
        if not soup:
            logger.error(f"Failed to process {url}")
            return {
                'url': url,
                'file': None,
                'status': 'failed',
                'error': 'Failed to fetch content'
            }
        
        # Extract title for filename if available
        title = None
        if soup.title:
            title = soup.title.string
        
        # Generate filename
        filename = clean_filename(url, title)
        
        # Convert to markdown
        from urllib.parse import urlparse
        base_url = f"{urlparse(url).scheme}://{urlparse(url).netloc}"
        markdown_content = html_to_markdown(soup, base_url)
        
        # Save to file
        filepath = save_markdown(markdown_content, output_dir, filename)
        
        return {
            'url': url,
            'file': filepath,
            'status': 'success',
            'error': None
        }
    
    except Exception as e:
        logger.error(f"Error processing {url}: {str(e)}")
        return {
            'url': url,
            'file': None,
            'status': 'failed',
            'error': str(e)
        }

def batch_process(urls, output_dir, delay=1, workers=5):
    """Process multiple URLs in parallel."""
    # Create output directory
    setup_directory(output_dir)
    
    results = []
    
    # Process URLs in parallel
    with ThreadPoolExecutor(max_workers=workers) as executor:
        # Submit all tasks
        future_to_url = {
            executor.submit(process_url, url, output_dir, delay): url 
            for url in urls
        }
        
        # Process as they complete
        for future in tqdm(
            future_to_url, 
            desc=f"Processing URLs with {workers} workers",
            total=len(future_to_url)
        ):
            try:
                result = future.result()
                results.append(result)
            except Exception as e:
                url = future_to_url[future]
                logger.error(f"Exception processing {url}: {str(e)}")
                results.append({
                    'url': url,
                    'file': None,
                    'status': 'failed',
                    'error': str(e)
                })
    
    return results

def process_csv(csv_path, output_dir, delay=1, column_name='url', workers=5):
    """Process all URLs in a CSV file using parallel workers."""
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
    
    # Process each URL
    urls = df[column_name].dropna().unique()
    logger.info(f"Found {len(urls)} unique URLs to process")
    
    # Batch process URLs
    results = batch_process(urls, output_dir, delay, workers)
    
    # Save results
    results_df = pd.DataFrame(results)
    results_path = os.path.join(output_dir, 'batch_scraping_results.csv')
    results_df.to_csv(results_path, index=False)
    logger.info(f"Saved results to {results_path}")
    
    # Print summary
    success_count = results_df[results_df['status'] == 'success'].shape[0]
    logger.info(f"Completed: {success_count}/{len(urls)} URLs successfully processed")
    
    return results_df

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Batch scrape URLs from CSV and convert to Markdown')
    parser.add_argument('csv_path', help='Path to CSV file containing URLs')
    parser.add_argument('--output', default='knowledge_base', help='Output directory')
    parser.add_argument('--delay', type=float, default=1, help='Delay between requests in seconds')
    parser.add_argument('--column', default='url', help='Column name in CSV that contains URLs')
    parser.add_argument('--workers', type=int, default=5, help='Number of parallel workers')
    
    args = parser.parse_args()
    
    logger.info(f"Starting batch scraper with CSV: {args.csv_path}")
    process_csv(args.csv_path, args.output, args.delay, args.column, args.workers)
    logger.info("Batch scraping completed")

if __name__ == "__main__":
    main()