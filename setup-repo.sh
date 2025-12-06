#!/bin/bash
set -e

echo "Initializing git repository..."
cd /Users/1unoe/Desktop/code/claude-multi.nvim

# Initialize git if not already initialized
if [ ! -d .git ]; then
    git init
fi

# Add all files
git add .

# Create initial commit
if git rev-parse HEAD >/dev/null 2>&1; then
    echo "Repository already has commits"
else
    git commit -m "Initial commit: claude-multi.nvim v1.0.0"
    echo "Initial commit created"
fi

# Create GitHub repository and push
echo "Creating GitHub repository..."
gh repo create mb6611/claude-multi.nvim --public --source=. --push --description "Multi-session Claude Code terminal manager for Neovim"

echo ""
echo "Repository successfully created and pushed!"
echo "URL: https://github.com/mb6611/claude-multi.nvim"
