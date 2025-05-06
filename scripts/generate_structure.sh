#!/bin/bash
# Script to generate a clean folder structure README with links

# Color setup for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to prompt yes/no questions
confirm() {
    local prompt="$1"
    local default="${2:-y}"
    
    if [ "$default" = "y" ]; then
        options="[Y/n]"
    else
        options="[y/N]"
    fi
    
    read -p "$prompt $options " response
    response=${response:-$default}
    
    if [[ "$response" =~ ^[Yy] ]]; then
        return 0  # true
    else
        return 1  # false
    fi
}

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}= Documentation Structure Generator     =${NC}"
echo -e "${BLUE}=========================================${NC}"
echo

# Get input directory
read -p "Enter the directory containing your documentation: " INPUT_DIR
INPUT_DIR=${INPUT_DIR:-"organized_docs"}

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo -e "${RED}Error: Directory '$INPUT_DIR' not found.${NC}"
    exit 1
fi

# Get output file
read -p "Enter the output README file [structure.md]: " OUTPUT_FILE
OUTPUT_FILE=${OUTPUT_FILE:-"structure.md"}

# Get repository title
read -p "Enter the title for your documentation repository: " REPO_TITLE
REPO_TITLE=${REPO_TITLE:-"Documentation Repository"}

# Get repository description
read -p "Enter a brief description of this documentation: " REPO_DESCRIPTION
REPO_DESCRIPTION=${REPO_DESCRIPTION:-"This repository contains comprehensive documentation."}

# Create the structure README
echo -e "${YELLOW}Generating documentation structure...${NC}"

# Start the README content
cat > "$OUTPUT_FILE" << EOF
# $REPO_TITLE

$REPO_DESCRIPTION

## Directory Structure

EOF

# Function to generate structure recursively
generate_structure() {
    local dir=$1
    local prefix=$2
    local level=$3
    local base_path=$4
    
    # Get directories first
    find "$dir" -maxdepth 1 -mindepth 1 -type d | sort | while read subdir; do
        dirname=$(basename "$subdir")
        
        # Skip hidden directories
        if [[ "$dirname" == .* ]]; then
            continue
        fi
        
        # Calculate relative path
        rel_path="$base_path$dirname"
        
        # Add directory to structure with emoji
        echo "$prefix- [📁 $dirname]($rel_path/)" >> "$OUTPUT_FILE"
        
        # Add README if it exists
        if [ -f "$subdir/README.md" ]; then
            echo "$prefix  - [📄 README.md]($rel_path/README.md)" >> "$OUTPUT_FILE"
        fi
        
        # Recursively process subdirectory with increased indentation
        generate_structure "$subdir" "$prefix  " $((level + 1)) "$rel_path/"
    done
    
    # Only include individual files at the top level if explicitly requested
    if [ $level -eq 0 ] && confirm "Include individual files at the top level?"; then
        find "$dir" -maxdepth 1 -mindepth 1 -type f -name "*.md" | sort | while read file; do
            filename=$(basename "$file")
            
            # Skip README.md and this structure file
            if [ "$filename" == "README.md" ] || [ "$(realpath "$file")" == "$(realpath "$OUTPUT_FILE")" ]; then
                continue
            fi
            
            echo "$prefix- [📄 $filename]($filename)" >> "$OUTPUT_FILE"
        done
    fi
}

# Generate the structure
generate_structure "$INPUT_DIR" "" 0 ""

echo -e "${GREEN}Documentation structure has been generated in $OUTPUT_FILE${NC}"

# Ask if user wants to copy to input directory
if confirm "Would you like to copy this structure file to $INPUT_DIR/README.md?"; then
    cp "$OUTPUT_FILE" "$INPUT_DIR/README.md"
    echo -e "${GREEN}Copied structure to $INPUT_DIR/README.md${NC}"
fi

echo -e "${BLUE}Done! The folder structure has been generated with links.${NC}"