#!/bin/bash

# Interactive script to prepare documentation and deploy to GitHub
set -e  # Exit on any error

# Color setup for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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
echo -e "${BLUE}= Documentation Deployment Assistant    =${NC}"
echo -e "${BLUE}=========================================${NC}"
echo

echo -e "${YELLOW}Step 1: Preparing repository for deployment...${NC}"

# Check if organized_docs exists
if [ ! -d "organized_docs" ]; then
    echo "Warning: 'organized_docs' directory not found."
    if confirm "Do you want to organize your documentation first?"; then
        # Check if knowledge_base exists
        if [ ! -d "knowledge_base" ]; then
            echo "Error: 'knowledge_base' directory not found. Run the scraper first."
            exit 1
        fi
        echo "Running organization script..."
        bash scripts/organize_docs.sh knowledge_base --output organized_docs
    fi
fi

# Create deployment directory
echo "Creating clean deployment structure..."
rm -rf deployment
mkdir -p deployment

# Check which directory to use as source
source_dir="organized_docs"
if [ ! -d "$source_dir" ]; then
    source_dir="knowledge_base"
    if [ ! -d "$source_dir" ]; then
        echo "Error: No documentation directories found. Run the scraper first."
        exit 1
    fi
fi

# Copy documentation
cp -r $source_dir deployment/docs
cp -f README.md deployment/ 2>/dev/null || true

# Create README.md if it doesn't exist in deployment directory
if [ ! -f "deployment/README.md" ]; then
    # Prompt for repository title
    read -p "Enter the title for your documentation repository: " repo_title
    repo_title=${repo_title:-"Documentation Repository"}
    
    # Prompt for repository description
    read -p "Enter a brief description of this documentation: " repo_description
    repo_description=${repo_description:-"This repository contains comprehensive documentation."}
    
    cat > deployment/README.md << EOF
# $repo_title

$repo_description

## Documentation Structure

$(find deployment/docs -type d -maxdepth 1 -mindepth 1 | sort | while read dir; do
    dir_name=$(basename "$dir")
    echo "- [${dir_name^}](docs/$dir_name/): Documentation related to $dir_name"
done)

EOF
    
    echo -e "${GREEN}Created README.md in deployment directory${NC}"
fi

echo -e "${GREEN}Repository prepared for deployment in the 'deployment' directory.${NC}"
echo

# Interactive deployment
if confirm "${YELLOW}Step 2: Would you like to initialize a Git repository in the deployment directory?${NC}"; then
    cd deployment
    
    echo "Initializing git repository..."
    git init
    
    echo "Adding files to staging..."
    git add .
    
    # Commit message
    read -p "Enter a commit message [Initial documentation deployment]: " commit_msg
    commit_msg=${commit_msg:-"Initial documentation deployment"}
    
    echo "Creating commit..."
    git commit -m "$commit_msg"
    
    # GitHub repository
    if confirm "Would you like to add a remote GitHub repository?"; then
        read -p "Enter your GitHub repository URL: " repo_url
        
        if [ -n "$repo_url" ]; then
            echo "Adding remote repository..."
            git remote add origin "$repo_url"
            
            if confirm "Would you like to push to GitHub now?"; then
                branch_name="main"
                read -p "Enter branch name to push to [main]: " input_branch
                branch_name=${input_branch:-"main"}
                
                echo "Pushing to GitHub..."
                git push -u origin "$branch_name"
                echo -e "${GREEN}Successfully pushed to GitHub!${NC}"
            else
                echo -e "${YELLOW}Repository is ready to push. Use this command when ready:${NC}"
                echo "  git push -u origin main"
            fi
        else
            echo -e "${YELLOW}No repository URL provided. Add a remote later with:${NC}"
            echo "  git remote add origin YOUR_REPOSITORY_URL"
        fi
    fi
    
    echo -e "${GREEN}Deployment setup complete!${NC}"
    echo -e "${BLUE}Your documentation is ready in the 'deployment' directory.${NC}"
else
    echo -e "${YELLOW}Deployment prepared but not initialized as a Git repository.${NC}"
    echo "When you're ready, run these commands to deploy:"
    echo "  cd deployment"
    echo "  git init"
    echo "  git add ."
    echo "  git commit -m \"Initial documentation deployment\""
    echo "  git remote add origin YOUR_REPOSITORY_URL"
    echo "  git push -u origin main"
fi