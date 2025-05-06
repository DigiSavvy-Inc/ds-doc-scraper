#!/bin/bash
# Script to organize markdown files into a GitHub-friendly structure

# Default values
INPUT_DIR="knowledge_base"
OUTPUT_DIR="organized_docs"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      INPUT_DIR="$1"
      shift
      ;;
  esac
done

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Organizing docs from $INPUT_DIR to $OUTPUT_DIR"

# Function to clean filenames
clean_filename() {
  local filename="$1"
  
  # Convert to lowercase
  filename=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
  
  # Replace spaces and special characters with hyphens
  filename=$(echo "$filename" | sed -E 's/[^a-z0-9\.]+/-/g')
  
  # Replace multiple hyphens with single hyphen
  filename=$(echo "$filename" | sed -E 's/-+/-/g')
  
  # Remove trailing hyphens and underscores
  filename=$(echo "$filename" | sed -E 's/[-_]+\.md$/.md/')
  
  echo "$filename"
}

# Create category folders
create_category_folders() {
  mkdir -p "$OUTPUT_DIR/getting-started"
  mkdir -p "$OUTPUT_DIR/features"
  mkdir -p "$OUTPUT_DIR/developers"
  mkdir -p "$OUTPUT_DIR/integrations"
  mkdir -p "$OUTPUT_DIR/customization"
  mkdir -p "$OUTPUT_DIR/troubleshooting"
  
  # Create README.md files for each category
  echo "# Getting Started" > "$OUTPUT_DIR/getting-started/README.md"
  echo "# Features" > "$OUTPUT_DIR/features/README.md"
  echo "# Developer Documentation" > "$OUTPUT_DIR/developers/README.md"
  echo "# Integrations" > "$OUTPUT_DIR/integrations/README.md"
  echo "# Customization" > "$OUTPUT_DIR/customization/README.md"
  echo "# Troubleshooting" > "$OUTPUT_DIR/troubleshooting/README.md"
}

# Function to determine which category a file belongs to
get_category() {
  local filename="$1"
  local content="$2"
  
  # Check filename keywords first
  if [[ "$filename" =~ (install|setup|config|start|begin|first) ]]; then
    echo "getting-started"
  elif [[ "$filename" =~ (api|hook|filter|develop|code|function|method) ]]; then
    echo "developers"
  elif [[ "$filename" =~ (google|calendar|payment|paypal|stripe|zapier|zoom) ]]; then
    echo "integrations"
  elif [[ "$filename" =~ (style|css|custom|theme|design|color) ]]; then
    echo "customization"
  elif [[ "$filename" =~ (troubleshoot|error|issue|fix|debug|problem|solve) ]]; then
    echo "troubleshooting"
  else
    # Default to features
    echo "features"
  fi
}

# Process each markdown file
process_files() {
  for file in "$INPUT_DIR"/*.md; do
    if [ -f "$file" ]; then
      # Get basename
      filename=$(basename "$file")
      
      # Clean the filename
      clean_name=$(clean_filename "$filename")
      
      # Read content to determine category
      content=$(cat "$file")
      category=$(get_category "$clean_name" "$content")
      
      # Copy to appropriate directory
      cp "$file" "$OUTPUT_DIR/$category/$clean_name"
      
      echo "Processed: $filename -> $category/$clean_name"
    fi
  done
}

# Update README files with links to documents
update_readme_files() {
  for category in getting-started features developers integrations customization troubleshooting; do
    # Get the README file
    readme="$OUTPUT_DIR/$category/README.md"
    
    # Add header for document list
    echo -e "\n## Documents\n" >> "$readme"
    
    # Add each document to the readme
    for doc in "$OUTPUT_DIR/$category"/*.md; do
      # Skip the README itself
      if [ "$(basename "$doc")" != "README.md" ]; then
        doc_name=$(basename "$doc")
        doc_title=$(head -n 1 "$doc" | sed 's/^# //')
        echo "- [${doc_title:-$doc_name}](./$doc_name)" >> "$readme"
      fi
    done
  done
}

# Create main README with directory structure
create_main_readme() {
  main_readme="$OUTPUT_DIR/README.md"
  echo "# Documentation" > "$main_readme"
  echo -e "\nThis repository contains organized documentation.\n" >> "$main_readme"
  echo -e "## Directory Structure\n" >> "$main_readme"
  
  # Add directory tree
  echo "- [📁 getting-started/](getting-started/)" >> "$main_readme"
  echo "  - [📄 README.md](getting-started/README.md)" >> "$main_readme"
  
  for doc in "$OUTPUT_DIR/getting-started"/*.md; do
    if [ "$(basename "$doc")" != "README.md" ]; then
      doc_name=$(basename "$doc")
      echo "  - [📄 $doc_name](getting-started/$doc_name)" >> "$main_readme"
    fi
  done
  
  echo "- [📁 features/](features/)" >> "$main_readme"
  echo "  - [📄 README.md](features/README.md)" >> "$main_readme"
  
  for doc in "$OUTPUT_DIR/features"/*.md; do
    if [ "$(basename "$doc")" != "README.md" ]; then
      doc_name=$(basename "$doc")
      echo "  - [📄 $doc_name](features/$doc_name)" >> "$main_readme"
    fi
  done
  
  echo "- [📁 developers/](developers/)" >> "$main_readme"
  echo "  - [📄 README.md](developers/README.md)" >> "$main_readme"
  
  for doc in "$OUTPUT_DIR/developers"/*.md; do
    if [ "$(basename "$doc")" != "README.md" ]; then
      doc_name=$(basename "$doc")
      echo "  - [📄 $doc_name](developers/$doc_name)" >> "$main_readme"
    fi
  done
  
  echo "- [📁 integrations/](integrations/)" >> "$main_readme"
  echo "  - [📄 README.md](integrations/README.md)" >> "$main_readme"
  
  for doc in "$OUTPUT_DIR/integrations"/*.md; do
    if [ "$(basename "$doc")" != "README.md" ]; then
      doc_name=$(basename "$doc")
      echo "  - [📄 $doc_name](integrations/$doc_name)" >> "$main_readme"
    fi
  done
  
  echo "- [📁 customization/](customization/)" >> "$main_readme"
  echo "  - [📄 README.md](customization/README.md)" >> "$main_readme"
  
  for doc in "$OUTPUT_DIR/customization"/*.md; do
    if [ "$(basename "$doc")" != "README.md" ]; then
      doc_name=$(basename "$doc")
      echo "  - [📄 $doc_name](customization/$doc_name)" >> "$main_readme"
    fi
  done
  
  echo "- [📁 troubleshooting/](troubleshooting/)" >> "$main_readme"
  echo "  - [📄 README.md](troubleshooting/README.md)" >> "$main_readme"
  
  for doc in "$OUTPUT_DIR/troubleshooting"/*.md; do
    if [ "$(basename "$doc")" != "README.md" ]; then
      doc_name=$(basename "$doc")
      echo "  - [📄 $doc_name](troubleshooting/$doc_name)" >> "$main_readme"
    fi
  done
}

# Main execution
create_category_folders
process_files
update_readme_files
create_main_readme

echo "Organization complete. Files organized into $OUTPUT_DIR"