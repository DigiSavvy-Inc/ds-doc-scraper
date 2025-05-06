#!/bin/bash

# Script to prepare the repository for deployment by removing unnecessary files

echo "Preparing repository for deployment..."

# Create a clean directory structure
mkdir -p deployment
cp -r github_docs deployment/docs
cp CLAUDE.md deployment/

# Create new README.md in the root directory
cat > deployment/README.md << 'EOF'
# Simply Schedule Appointments Documentation

This repository contains comprehensive documentation for Simply Schedule Appointments WordPress plugin.

## Documentation Structure

- [Getting Started](docs/getting-started/): Installation, setup, and basic configuration
- [Features](docs/features/): Core functionality and features documentation
- [Developers](docs/developers/): API documentation, hooks, filters, and developer tools
- [Integrations](docs/integrations/): Connect with Google Calendar, payment processors, and other services
- [Customization](docs/customization/): Styling, CSS, and customization guides
- [Troubleshooting](docs/troubleshooting/): Common issues and their solutions

## About Simply Schedule Appointments

Simply Schedule Appointments is a WordPress plugin that allows you to easily manage appointments and bookings through your website.
EOF

echo "Repository prepared for deployment in the 'deployment' directory."
echo "Next steps:"
echo "1. Review the content in the deployment directory"
echo "2. Initialize a new git repository in the deployment directory"
echo "3. Commit and push to your GitHub repository"
echo ""
echo "Example commands:"
echo "  cd deployment"
echo "  git init"
echo "  git add ."
echo "  git commit -m \"Initial documentation deployment\""
echo "  git remote add origin YOUR_REPOSITORY_URL"
echo "  git push -u origin main"