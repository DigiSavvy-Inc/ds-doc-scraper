#!/bin/bash
# Interactive script to organize markdown files with customizable categories

# Color setup for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
INPUT_DIR="knowledge_base"
OUTPUT_DIR="organized_docs"

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

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}= Interactive Documentation Organizer   =${NC}"
echo -e "${BLUE}=========================================${NC}"
echo

# Get input directory
read -p "Enter the input directory containing markdown files [$INPUT_DIR]: " input
INPUT_DIR=${input:-$INPUT_DIR}

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo -e "${RED}Error: Input directory '$INPUT_DIR' not found.${NC}"
    exit 1
fi

# Count markdown files
md_count=$(find "$INPUT_DIR" -name "*.md" | wc -l)
if [ "$md_count" -eq 0 ]; then
    echo -e "${RED}Error: No markdown files found in '$INPUT_DIR'.${NC}"
    exit 1
fi
echo -e "${GREEN}Found $md_count markdown files in '$INPUT_DIR'.${NC}"

# Get output directory
read -p "Enter the output directory for organized files [$OUTPUT_DIR]: " output
OUTPUT_DIR=${output:-$OUTPUT_DIR}

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo "Files will be organized into '$OUTPUT_DIR'."

# Organization method
echo
echo -e "${YELLOW}Select an organization method:${NC}"
echo "1) Use predefined categories (getting-started, features, developers, etc.)"
echo "2) Define custom categories"
echo "3) Maintain existing structure (just clean filenames)"
read -p "Enter your choice [1]: " org_method
org_method=${org_method:-1}

# Initialize categories array
declare -a categories

case $org_method in
    1)
        # Predefined categories
        categories=("getting-started" "features" "developers" "integrations" "customization" "troubleshooting")
        echo -e "${GREEN}Using predefined categories.${NC}"
        ;;
    2)
        # Custom categories
        echo "Enter your custom categories (comma-separated, no spaces):"
        echo "Example: basics,advanced,reference,tutorials"
        read -p "> " custom_cats
        IFS=',' read -r -a categories <<< "$custom_cats"
        
        if [ ${#categories[@]} -eq 0 ]; then
            echo -e "${RED}No categories provided. Using 'docs' as the default category.${NC}"
            categories=("docs")
        else
            echo -e "${GREEN}Using custom categories: ${categories[*]}${NC}"
        fi
        ;;
    3)
        # Maintain structure
        echo -e "${GREEN}Maintaining existing structure and just cleaning filenames.${NC}"
        categories=()
        ;;
    *)
        echo -e "${RED}Invalid choice. Using predefined categories.${NC}"
        categories=("getting-started" "features" "developers" "integrations" "customization" "troubleshooting")
        ;;
esac

# Create category folders and README files
if [ ${#categories[@]} -gt 0 ]; then
    echo "Creating category directories..."
    for category in "${categories[@]}"; do
        mkdir -p "$OUTPUT_DIR/$category"
        echo "# ${category^}" > "$OUTPUT_DIR/$category/README.md"
        echo -e "\n## Documents\n" >> "$OUTPUT_DIR/$category/README.md"
        echo -e "${GREEN}Created $category directory and README.${NC}"
    done
fi

# Define keyword-to-category mappings if using categories
if [ ${#categories[@]} -gt 0 ] && [ "$org_method" -ne 3 ]; then
    echo
    echo -e "${YELLOW}Let's define keywords for categorizing files.${NC}"
    
    declare -A category_keywords
    
    # Default keywords for predefined categories
    if [ "$org_method" -eq 1 ]; then
        category_keywords["getting-started"]="install,setup,config,start,begin,first,introduction,intro,guide,quickstart"
        category_keywords["features"]="feature,functionality,overview,usage,using,use"
        category_keywords["developers"]="api,hook,filter,develop,code,function,method,class,programming,developer"
        category_keywords["integrations"]="google,calendar,payment,paypal,stripe,zapier,zoom,connect,integration,sync"
        category_keywords["customization"]="style,css,custom,theme,design,color,appearance,layout,personalize"
        category_keywords["troubleshooting"]="troubleshoot,error,issue,fix,debug,problem,solve,solution,faq,help"
        
        # Allow user to modify keywords
        if confirm "Would you like to modify the default keywords for categories?"; then
            for category in "${categories[@]}"; do
                current_keywords=${category_keywords[$category]}
                echo "Current keywords for '$category': $current_keywords"
                read -p "Enter new keywords (comma-separated) or press enter to keep current: " new_keywords
                if [ -n "$new_keywords" ]; then
                    category_keywords[$category]="$new_keywords"
                fi
            done
        fi
    else
        # Define keywords for custom categories
        for category in "${categories[@]}"; do
            echo "Define keywords for '$category' category (comma-separated):"
            read -p "> " keywords
            category_keywords[$category]="$keywords"
        fi
    fi
    
    # Set default category
    if [ "$org_method" -eq 1 ]; then
        default_category="features"
    else
        default_category=${categories[0]}
    fi
    read -p "Enter the default category for files that don't match any keywords [$default_category]: " def_cat
    default_category=${def_cat:-$default_category}
    
    # Process each markdown file
    echo
    echo -e "${YELLOW}Processing markdown files...${NC}"
    for file in $(find "$INPUT_DIR" -name "*.md"); do
        # Get basename
        filename=$(basename "$file")
        
        # Clean the filename
        clean_name=$(clean_filename "$filename")
        
        # Determine category
        assigned_category="$default_category"
        file_content=$(cat "$file")
        
        for category in "${categories[@]}"; do
            IFS=',' read -r -a keywords <<< "${category_keywords[$category]}"
            for keyword in "${keywords[@]}"; do
                if [[ "$filename" =~ $keyword ]] || [[ "$file_content" =~ $keyword ]]; then
                    assigned_category="$category"
                    break 2
                fi
            done
        done
        
        # Copy to appropriate directory
        cp "$file" "$OUTPUT_DIR/$assigned_category/$clean_name"
        
        # Add to README
        doc_title=$(head -n 1 "$file" | sed 's/^# //')
        echo "- [${doc_title:-$clean_name}](./$clean_name)" >> "$OUTPUT_DIR/$assigned_category/README.md"
        
        echo "Processed: $filename -> $assigned_category/$clean_name"
    done
else
    # Just clean filenames and maintain structure
    echo
    echo -e "${YELLOW}Processing files and maintaining structure...${NC}"
    
    find "$INPUT_DIR" -type d | while read dir; do
        # Get relative path
        rel_path=${dir#$INPUT_DIR}
        if [ -z "$rel_path" ]; then
            rel_path="/"
        fi
        
        # Create corresponding output directory
        if [ "$rel_path" = "/" ]; then
            target_dir="$OUTPUT_DIR"
        else
            target_dir="$OUTPUT_DIR$rel_path"
        fi
        mkdir -p "$target_dir"
        
        # Process files in this directory
        find "$dir" -maxdepth 1 -type f -name "*.md" | while read file; do
            filename=$(basename "$file")
            clean_name=$(clean_filename "$filename")
            cp "$file" "$target_dir/$clean_name"
            echo "Processed: $file -> $target_dir/$clean_name"
        done
    done
fi

# Create main README with directory structure
main_readme="$OUTPUT_DIR/README.md"
echo "# Documentation" > "$main_readme"
echo -e "\nThis repository contains organized documentation.\n" >> "$main_readme"
echo -e "## Directory Structure\n" >> "$main_readme"

if [ ${#categories[@]} -gt 0 ]; then
    # Add directory tree for categorized structure
    for category in "${categories[@]}"; do
        echo "- [📁 $category/]($category/)" >> "$main_readme"
        echo "  - [📄 README.md]($category/README.md)" >> "$main_readme"
        
        for doc in "$OUTPUT_DIR/$category"/*.md; do
            if [ -f "$doc" ] && [ "$(basename "$doc")" != "README.md" ]; then
                doc_name=$(basename "$doc")
                echo "  - [📄 $doc_name]($category/$doc_name)" >> "$main_readme"
            fi
        done
        echo "" >> "$main_readme"
    done
else
    # Add directory tree for maintained structure
    find "$OUTPUT_DIR" -type f -name "*.md" | sort | while read doc; do
        rel_path=${doc#$OUTPUT_DIR/}
        if [ "$rel_path" != "README.md" ]; then
            indent=""
            depth=$(echo "$rel_path" | tr -cd '/' | wc -c)
            for ((i=0; i<depth; i++)); do
                indent="$indent  "
            done
            echo "$indent- [📄 $(basename "$doc")]($rel_path)" >> "$main_readme"
        fi
    done
fi

echo -e "${GREEN}Organization complete! Files have been organized in '$OUTPUT_DIR'.${NC}"
echo -e "A main README.md file has been created with the directory structure."

if confirm "Would you like to view a summary of the organization?"; then
    echo
    echo -e "${BLUE}Organization Summary:${NC}"
    echo "Input Directory: $INPUT_DIR"
    echo "Output Directory: $OUTPUT_DIR"
    echo "Files Processed: $md_count"
    
    if [ ${#categories[@]} -gt 0 ]; then
        echo "Categories:"
        for category in "${categories[@]}"; do
            count=$(find "$OUTPUT_DIR/$category" -name "*.md" ! -name "README.md" | wc -l)
            echo "  - $category: $count files"
        done
    else
        echo "Files organized with original directory structure preserved."
    fi
fi