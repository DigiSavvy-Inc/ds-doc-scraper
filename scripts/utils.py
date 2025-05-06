import os
import re
import time
import logging
import requests
from bs4 import BeautifulSoup
from urllib.parse import urlparse, urljoin

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def setup_directory(output_dir):
    """Create output directory if it doesn't exist."""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        logger.info(f"Created output directory: {output_dir}")
    return output_dir

def clean_filename(url, title=None):
    """
    Generate a clean filename from URL or title.
    Removes invalid chars and trailing underscores.
    """
    # Use title if provided, otherwise extract from URL
    if title:
        raw_name = title
    else:
        # Extract the last part of the URL path
        path = urlparse(url).path
        raw_name = os.path.basename(path)
        
        # If the path ends with a slash, use the second-to-last component
        if not raw_name and path.endswith('/'):
            components = path.rstrip('/').split('/')
            if components:
                raw_name = components[-1]
        
        # If still empty, use the domain
        if not raw_name:
            raw_name = urlparse(url).netloc
    
    # Replace spaces and special characters with hyphens
    clean_name = re.sub(r'[^\w\-]', '-', raw_name)
    
    # Replace multiple hyphens with a single hyphen
    clean_name = re.sub(r'-+', '-', clean_name)
    
    # Remove any trailing hyphens or underscores
    clean_name = clean_name.rstrip('-_')
    
    # Convert to lowercase
    clean_name = clean_name.lower()
    
    # Add .md extension if not present
    if not clean_name.endswith('.md'):
        clean_name += '.md'
    
    return clean_name

def fetch_url(url, delay=1):
    """
    Fetch content from URL with specified delay between requests.
    Returns soup object and raw response.
    """
    time.sleep(delay)  # Be respectful to servers
    
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        }
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'html.parser')
        logger.info(f"Successfully fetched: {url}")
        return soup, response
    
    except requests.exceptions.RequestException as e:
        logger.error(f"Error fetching {url}: {str(e)}")
        return None, None

def html_to_markdown(soup, base_url):
    """
    Convert HTML content to Markdown.
    This is a simple implementation - for production use,
    consider a dedicated library like html2text or markdownify.
    """
    # Extract title
    title = ""
    if soup.title and soup.title.string:
        title = f"# {soup.title.string.strip()}\n\n"
    
    # Extract main content (customize this selector based on the target site)
    content_selectors = [
        "main", "article", ".content", "#content", 
        ".main-content", "#main-content", ".post-content"
    ]
    
    content = None
    for selector in content_selectors:
        content = soup.select_one(selector)
        if content:
            break
    
    # If no content found with selectors, use body
    if not content:
        content = soup.body
    
    # Process content if found
    markdown = title
    
    if content:
        # Process headings
        for h in content.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6']):
            level = int(h.name[1])
            h.replace_with(f"{'#' * level} {h.get_text().strip()}\n\n")
        
        # Process paragraphs
        for p in content.find_all('p'):
            p.replace_with(f"{p.get_text().strip()}\n\n")
        
        # Process links
        for a in content.find_all('a', href=True):
            url = urljoin(base_url, a['href'])
            a.replace_with(f"[{a.get_text().strip()}]({url})")
        
        # Process lists
        for ul in content.find_all('ul'):
            for li in ul.find_all('li'):
                li.replace_with(f"* {li.get_text().strip()}\n")
            ul.replace_with("\n")
        
        for ol in content.find_all('ol'):
            for i, li in enumerate(ol.find_all('li')):
                li.replace_with(f"{i+1}. {li.get_text().strip()}\n")
            ol.replace_with("\n")
        
        # Process images
        for img in content.find_all('img', src=True):
            alt = img.get('alt', '')
            src = urljoin(base_url, img['src'])
            img.replace_with(f"![{alt}]({src})")
        
        # Process code blocks
        for pre in content.find_all('pre'):
            code = pre.get_text().strip()
            pre.replace_with(f"```\n{code}\n```\n\n")
        
        # Process inline code
        for code in content.find_all('code'):
            code.replace_with(f"`{code.get_text().strip()}`")
        
        # Get the final text
        markdown = title + content.get_text()
        
        # Clean up excess whitespace
        markdown = re.sub(r'\n{3,}', '\n\n', markdown)
    
    return markdown

def save_markdown(content, output_dir, filename):
    """Save markdown content to file."""
    file_path = os.path.join(output_dir, filename)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    logger.info(f"Saved: {file_path}")
    return file_path