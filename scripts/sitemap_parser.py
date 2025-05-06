#!/usr/bin/env python3
"""
Sitemap parser for extracting URLs to scrape.
"""
import argparse
import logging
import pandas as pd
import requests
from bs4 import BeautifulSoup
import re
from urllib.parse import urljoin
from tqdm import tqdm

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def fetch_sitemap(sitemap_url):
    """Fetch content from sitemap URL."""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        }
        response = requests.get(sitemap_url, headers=headers, timeout=30)
        response.raise_for_status()
        return response.text
    except requests.exceptions.RequestException as e:
        logger.error(f"Error fetching sitemap {sitemap_url}: {str(e)}")
        return None

def is_sitemap_index(content):
    """Check if the sitemap is an index with links to other sitemaps."""
    return '<sitemapindex' in content

def extract_urls_from_sitemap(content, base_url):
    """Extract URLs from a sitemap."""
    soup = BeautifulSoup(content, 'html.parser')
    urls = []
    
    # Check for standard sitemap format
    for loc in soup.find_all('loc'):
        urls.append(loc.text.strip())
    
    # If no URLs found, try alternative formats
    if not urls:
        # Try regex for non-standard sitemaps
        urls = re.findall(r'<loc>(.*?)<\/loc>', content)
    
    # Ensure URLs are absolute
    absolute_urls = [
        urljoin(base_url, url) if not url.startswith(('http://', 'https://')) else url
        for url in urls
    ]
    
    return absolute_urls

def process_sitemap(sitemap_url, output_file='urls.csv'):
    """Process a sitemap or sitemap index and extract all URLs."""
    logger.info(f"Processing sitemap: {sitemap_url}")
    
    content = fetch_sitemap(sitemap_url)
    if not content:
        return []
    
    # Get base URL for resolving relative links
    base_url = re.match(r'(https?://[^/]+)', sitemap_url).group(1)
    
    all_urls = []
    
    # Check if this is a sitemap index
    if is_sitemap_index(content):
        logger.info("Found sitemap index, processing child sitemaps...")
        child_sitemaps = extract_urls_from_sitemap(content, base_url)
        
        for child_url in tqdm(child_sitemaps, desc="Processing child sitemaps"):
            child_content = fetch_sitemap(child_url)
            if child_content:
                urls = extract_urls_from_sitemap(child_content, base_url)
                all_urls.extend(urls)
                logger.info(f"Found {len(urls)} URLs in {child_url}")
    else:
        # Regular sitemap
        all_urls = extract_urls_from_sitemap(content, base_url)
        logger.info(f"Found {len(all_urls)} URLs in sitemap")
    
    # Save to CSV
    if all_urls:
        df = pd.DataFrame({'url': all_urls})
        df.to_csv(output_file, index=False)
        logger.info(f"Saved {len(all_urls)} URLs to {output_file}")
    else:
        logger.warning("No URLs found in sitemap")
    
    return all_urls

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Parse a sitemap.xml file and extract URLs')
    parser.add_argument('sitemap_url', help='URL to the sitemap.xml file')
    parser.add_argument('--output', default='urls.csv', help='Output CSV file')
    
    args = parser.parse_args()
    
    logger.info(f"Starting sitemap parser with URL: {args.sitemap_url}")
    urls = process_sitemap(args.sitemap_url, args.output)
    logger.info(f"Sitemap parsing completed. Extracted {len(urls)} URLs")

if __name__ == "__main__":
    main()