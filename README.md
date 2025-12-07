# claude-multi.nvim

A multi-session Claude Code terminal manager for Neovim. Manage multiple Claude AI conversations in parallel with a clean, tab-based interface powered by `snacks.nvim`.

## Features

- **Multi-session management**: Run multiple Claude Code instances simultaneously
- **Tab-based interface**: Navigate between sessions with a visual winbar
- **Recall integration**: Browse and resume previous conversations using the [recall](https://github.com/zippoxer/recall) CLI
- **Flexible layouts**: Choose between floating window or sidebar modes
- **Built-in commands**: User commands like `:ClaudeToggle`, `:ClaudeNew`, etc.
- **Sensible defaults**: Works out of the box with zero configuration

## Requirements

- **Neovim 0.9+**
- **[snacks.nvim](https://github.com/folke/snacks.nvim)**: Terminal window management
- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)**: The official Anthropic CLI tool
- **[recall CLI](https://github.com/zippoxer/recall)**: (Optional but recommended) For browsing conversation history

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "mb6611/claude-multi.nvim",
  dependencies = { "folke/snacks.nvim" },
  event = "VeryLazy",
  opts = {},
}
```

That's it! The plugin includes sensible default keymaps and registers user commands automatically.

## Commands

| Command | Description |
|---------|-------------|
| `:ClaudeToggle` | Toggle Claude panel (opens recall if no sessions) |
| `:ClaudeRecall` | Open recall TUI to browse conversation history |
| `:ClaudeNew` | Create a new fresh Claude session |
| `:ClaudeNext` | Navigate to next session |
| `:ClaudePrev` | Navigate to previous session |
| `:ClaudeClose` | Close current tab/session |

## Default Keymaps

All keymaps work in both normal and terminal modes.

| Key | Action |
|-----|--------|
| `<leader>cc` | Toggle Claude panel |
| `<leader>cr` | Open Recall TUI |
| `<leader>cn` | New session |
| `<leader>ch` | Previous session |
| `<leader>cl` | Next session |
| `<leader>cx` | Close tab |

## Configuration

### Default Options

```lua
{
  "mb6611/claude-multi.nvim",
  dependencies = { "folke/snacks.nvim" },
  event = "VeryLazy",
  opts = {
    layout = "float",         -- "float" or "sidebar"
    float_width = 0.85,       -- Float mode width (0.0-1.0)
    float_height = 0.85,      -- Float mode height (0.0-1.0)
    sidebar_width = 0.4,      -- Sidebar mode width (0.0-1.0)
    keymaps = {
      toggle = "<leader>cc",
      recall = "<leader>cr",
      new_session = "<leader>cn",
      prev_session = "<leader>ch",
      next_session = "<leader>cl",
      close_tab = "<leader>cx",
    },
  },
}
```

### Customizing Keymaps

Override any keymap or disable it by setting to `false`:

```lua
opts = {
  keymaps = {
    -- Use Alt+h/l for faster navigation
    prev_session = "<M-h>",
    next_session = "<M-l>",
    -- Disable a keymap
    close_tab = false,
  },
}
```

### Layout Modes

**Float mode** (default):
- Centered floating window
- Rounded borders
- Configurable size

**Sidebar mode**:
- Right-side vertical split
- Single border
- Full height

## Usage

### Basic Workflow

1. **Open Claude**: Press `<leader>cc` to toggle the Claude panel
   - If no sessions exist, it opens the recall TUI automatically
   - Select a conversation from history or start a new one

2. **Create new sessions**: Press `<leader>cn` to spawn a fresh Claude session
   - Each session runs independently
   - Sessions appear as tabs in the winbar

3. **Navigate sessions**: Use `<leader>ch` and `<leader>cl` to move between active sessions
   - Sessions wrap around (after last, goes to first)

4. **Close sessions**: Press `<leader>cx` to close the current session
   - Automatically switches to the previous session
   - Panel closes if no sessions remain

### Session Indicators

The winbar displays all active sessions with these prefixes:
- `[R]`: Session resumed from recall history
- `[N]`: Fresh new session

Active session is highlighted in blue with bold text.

## Architecture

```
lua/claude-multi/
├── init.lua        # Public API, commands, keymaps
├── constants.lua   # Enum values
├── terminal.lua    # Snacks.nvim terminal integration
├── navigation.lua  # Session traversal
├── window.lua      # Window configuration
├── session.lua     # Session creation
├── state.lua       # State management
├── ui.lua          # Winbar rendering
└── picker.lua      # Quick-jump mode
```

## Why claude-multi.nvim?

When working with Claude Code, you often need to:
- Compare responses from different conversation contexts
- Maintain separate sessions for different tasks
- Resume previous conversations while starting new ones
- Keep your workflow organized without leaving Neovim

This plugin provides a seamless, keyboard-driven interface for managing multiple Claude sessions without the overhead of tmux panes or separate terminal windows.

## Credits

Created by [mb6611](https://github.com/mb6611)

Powered by:
- [snacks.nvim](https://github.com/folke/snacks.nvim) by folke
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) by Anthropic
- [recall](https://github.com/hrishioa/recall) by hrishioa

## License

MIT License - see [LICENSE](LICENSE) for details
