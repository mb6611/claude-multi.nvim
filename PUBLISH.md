# Publishing claude-multi.nvim to GitHub

All repository files have been created. To publish to GitHub, run these commands:

## Step 1: Initialize Git Repository

```bash
cd ~/Desktop/code/claude-multi.nvim
git init
git add .
git commit -m "Initial commit: claude-multi.nvim v1.0.0"
```

## Step 2: Create GitHub Repository and Push

```bash
gh repo create mb6611/claude-multi.nvim --public --source=. --push --description "Multi-session Claude Code terminal manager for Neovim"
```

Or use the provided script:

```bash
chmod +x ~/Desktop/code/claude-multi.nvim/setup-repo.sh
~/Desktop/code/claude-multi.nvim/setup-repo.sh
```

## What's Been Done

✅ Created comprehensive README.md with:
  - Feature overview
  - Installation instructions
  - Default keybindings table
  - Configuration options
  - Usage guide
  - Architecture overview

✅ Created MIT LICENSE with copyright holder: mb6611

✅ Created .gitignore for Neovim/Lua plugin development

✅ Updated local plugin spec at ~/.config/nvim/lua/plugins/claude-multi.lua
  - Changed from local `dir` path to GitHub: "mb6611/claude-multi.nvim"
  - Cleaned up and standardized keybindings

## Repository Structure

```
claude-multi.nvim/
├── README.md
├── LICENSE
├── .gitignore
├── setup-repo.sh (helper script)
├── PUBLISH.md (this file)
└── lua/
    └── claude-multi/
        ├── init.lua
        ├── session.lua
        ├── state.lua
        ├── ui.lua
        ├── picker.lua
        └── persistence.lua
```

## After Publishing

1. Remove the local copy from ~/.config/nvim/lua/claude-multi if desired
2. Run `:Lazy sync` in Neovim to install from GitHub
3. The plugin will now be installed like any other lazy.nvim plugin

## Repository URL

https://github.com/mb6611/claude-multi.nvim
