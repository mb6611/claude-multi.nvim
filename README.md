# claude-multi.nvim

A multi-session Claude Code terminal manager for Neovim. Manage multiple Claude AI conversations in parallel with a clean, tab-based interface powered by `snacks.nvim`.

## Features

- **Multi-session management**: Run multiple Claude Code instances simultaneously
- **Tab-based interface**: Navigate between sessions with a visual winbar
- **Recall integration**: Browse and resume previous conversations using the [recall](https://github.com/hrishioa/recall) CLI
- **Flexible layouts**: Choose between floating window or sidebar modes
- **Session persistence**: Automatically handles terminal lifecycle
- **Keyboard-first navigation**: Efficiently switch between sessions without touching your mouse

## Requirements

- **Neovim 0.9+**
- **[snacks.nvim](https://github.com/folke/snacks.nvim)**: Terminal window management
- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)**: The official Anthropic CLI tool
- **[recall CLI](https://github.com/hrishioa/recall)**: (Optional but recommended) For browsing conversation history

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "mb6611/claude-multi.nvim",
  dependencies = { "folke/snacks.nvim" },
  event = "VeryLazy",
  config = function()
    require("claude-multi").setup({
      layout = "float", -- "float" or "sidebar"
    })
  end,
  keys = {
    { "<C-a>", function() require("claude-multi").toggle() end, mode = { "n", "t" }, desc = "Toggle Claude" },
    { "<C-r>", function() require("claude-multi").open_recall() end, mode = { "n", "t" }, desc = "Open Recall" },
    { "<C-n>", function() require("claude-multi").new_session() end, mode = { "n", "t" }, desc = "New Session" },
    { "<M-h>", function() require("claude-multi").prev_session() end, mode = { "n", "t" }, desc = "Previous Session" },
    { "<M-l>", function() require("claude-multi").next_session() end, mode = { "n", "t" }, desc = "Next Session" },
    { "<C-w>", function() require("claude-multi").close_tab() end, mode = "t", desc = "Close Tab" },
  },
}
```

## Default Keybindings

All keybindings work in both normal (`n`) and terminal (`t`) modes unless specified otherwise.

| Key       | Mode | Action                                           |
|-----------|------|--------------------------------------------------|
| `<C-a>`   | n, t | Toggle Claude panel (opens recall if no sessions) |
| `<C-r>`   | n, t | Open recall TUI to browse conversation history   |
| `<C-n>`   | n, t | Create a new fresh Claude session               |
| `<M-h>`   | n, t | Navigate to previous session (wraps around)      |
| `<M-l>`   | n, t | Navigate to next session (wraps around)          |
| `<C-w>`   | t    | Close current tab/session                        |

**Note**: `<M-h>` and `<M-l>` use the Meta/Alt key to avoid conflicts with tmux default keybindings.

## Configuration

### Options

```lua
require("claude-multi").setup({
  layout = "float",         -- "float" or "sidebar"
  float_width = 0.85,       -- Float mode width (0.0-1.0)
  float_height = 0.85,      -- Float mode height (0.0-1.0)
  sidebar_width = 0.4,      -- Sidebar mode width (0.0-1.0)
})
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

### Customizing Keybindings

The keybindings shown in the installation example are just suggestions. You can customize them to your preference:

```lua
keys = {
  -- Use different keys
  { "<leader>cc", function() require("claude-multi").toggle() end, mode = { "n", "t" }, desc = "Toggle Claude" },
  { "<leader>cr", function() require("claude-multi").open_recall() end, mode = { "n", "t" }, desc = "Open Recall" },

  -- Or use arrow keys for navigation
  { "<M-Left>", function() require("claude-multi").prev_session() end, mode = { "n", "t" }, desc = "Previous Session" },
  { "<M-Right>", function() require("claude-multi").next_session() end, mode = { "n", "t" }, desc = "Next Session" },
}
```

## Usage

### Basic Workflow

1. **Open Claude**: Press `<C-a>` to toggle the Claude panel
   - If no sessions exist, it opens the recall TUI automatically
   - Select a conversation from history or start a new one

2. **Create new sessions**: Press `<C-n>` to spawn a fresh Claude session
   - Each session runs independently
   - Sessions appear as tabs in the winbar

3. **Navigate sessions**: Use `<M-h>` and `<M-l>` to move between active sessions
   - Sessions wrap around (after last, goes to first)

4. **Close sessions**: Press `<C-w>` in terminal mode to close the current session
   - Automatically switches to the previous session
   - Panel closes if no sessions remain

### Session Indicators

The winbar displays all active sessions with these prefixes:
- `[R]`: Session resumed from recall history
- `[N]`: Fresh new session

Active session is highlighted in blue with bold text.

## Architecture

The plugin is structured into modular components:

- **init.lua**: Main entry point and public API
- **state.lua**: Centralized state management with change listeners
- **session.lua**: Session creation, validation, and lifecycle
- **ui.lua**: Winbar rendering and highlight groups
- **picker.lua**: Quick-jump mode for session selection (future feature)
- **persistence.lua**: Session state persistence (future feature)

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
