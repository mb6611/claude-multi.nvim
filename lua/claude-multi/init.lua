local M = {}

-- Module requirements
local constants = require("claude-multi.constants")
local state = require("claude-multi.state")
local session = require("claude-multi.session")
local ui = require("claude-multi.ui")
local picker = require("claude-multi.picker")
local terminal = require("claude-multi.terminal")
local window = require("claude-multi.window")
local navigation = require("claude-multi.navigation")

-- Cached executable checks
local _has_claude = nil
local _has_recall = nil

---Check if an executable exists
---@param name string
---@return boolean
local function has_executable(name)
  return vim.fn.executable(name) == 1
end

---Check if claude CLI is available (cached)
---@return boolean
function M.has_claude()
  if _has_claude == nil then
    _has_claude = has_executable("claude")
  end
  return _has_claude
end

---Check if recall CLI is available (cached)
---@return boolean
function M.has_recall()
  if _has_recall == nil then
    _has_recall = has_executable("recall")
  end
  return _has_recall
end

-- Default configuration
M.defaults = {
  layout = constants.Layout.FLOAT,      -- FLOAT or SIDEBAR
  float_width = 0.85,
  float_height = 0.85,
  sidebar_width = 0.4,
  keymaps = {
    toggle = "<leader>cc",
    recall = "<leader>cr",
    new_session = "<leader>cn",
    prev_session = "<leader>ch",
    next_session = "<leader>cl",
    close_tab = "<leader>cx",
  },
}

-- Register user commands
function M.register_commands()
  local cmd = vim.api.nvim_create_user_command

  -- Always register these (they check dependencies at runtime)
  cmd("ClaudeToggle", M.toggle, { desc = "Toggle Claude panel" })
  cmd("ClaudeNew", M.new_session, { desc = "New Claude session" })
  cmd("ClaudeNext", M.next_session, { desc = "Next session" })
  cmd("ClaudePrev", M.prev_session, { desc = "Previous session" })
  cmd("ClaudeClose", M.close_tab, { desc = "Close current tab" })

  -- Only register recall command if recall is installed
  if M.has_recall() then
    cmd("ClaudeRecall", M.open_recall, { desc = "Open Recall TUI" })
  end
end

-- Register keymaps
function M.register_keymaps()
  local function map(mode, lhs, rhs, desc)
    if lhs then
      vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
    end
  end

  local km = M.config.keymaps
  map({ "n", "t" }, km.toggle, "<cmd>ClaudeToggle<cr>", "Toggle Claude")
  map({ "n", "t" }, km.new_session, "<cmd>ClaudeNew<cr>", "New Session")
  map({ "n", "t" }, km.prev_session, "<cmd>ClaudePrev<cr>", "Previous Session")
  map({ "n", "t" }, km.next_session, "<cmd>ClaudeNext<cr>", "Next Session")
  map({ "n", "t" }, km.close_tab, "<cmd>ClaudeClose<cr>", "Close Tab")

  -- Only register recall keymap if recall is installed
  if M.has_recall() then
    map({ "n", "t" }, km.recall, "<cmd>ClaudeRecall<cr>", "Open Recall")
  end
end

-- Setup function (called from plugin spec)
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})

  -- Setup highlights
  ui.setup_highlights()

  -- Initialize with empty state (ephemeral working memory)
  state.init()

  -- Setup terminal close handler
  terminal.setup_close_handler()

  -- Register commands and keymaps
  M.register_commands()
  M.register_keymaps()
end

-- Toggle the panel
function M.toggle()
  -- Check for claude CLI
  if not M.has_claude() then
    vim.notify("claude-multi: 'claude' CLI not found. Install from https://docs.anthropic.com/en/docs/claude-code", vim.log.levels.ERROR)
    return
  end

  local snacks = require("snacks")

  -- Setup close handler on first use
  terminal.setup_close_handler()

  -- Sync state with actual window visibility
  local actually_visible = terminal.is_window_visible()

  if actually_visible then
    -- Window is visible, hide it
    local active_session = state.get_active_session()
    if active_session then
      snacks.terminal.toggle(terminal.get_cmd(active_session), {
        count = active_session.id,
        win = window.get_win_opts(M.config),
        auto_close = true,
      })
    end
    state.set_visible(false)
  else
    -- Window is hidden, show it
    local sessions = state.get_sessions()

    if #sessions == 0 then
      -- No tabs exist, open recall (or new session if recall not available)
      if M.has_recall() then
        M.open_recall()
      else
        M.new_session()
      end
    else
      -- Show existing active session
      local active_session = state.get_active_session()
      if active_session then
        terminal.show(active_session, window.get_win_opts(M.config))
        state.set_visible(true)
        ui.update_winbar()
      end
    end
  end
end

-- Open recall TUI for session selection
function M.open_recall()
  -- Check for recall CLI
  if not M.has_recall() then
    vim.notify("claude-multi: 'recall' CLI not found. Install from https://github.com/hrishioa/recall", vim.log.levels.ERROR)
    return
  end

  -- Check for claude CLI (recall needs it too)
  if not M.has_claude() then
    vim.notify("claude-multi: 'claude' CLI not found. Install from https://docs.anthropic.com/en/docs/claude-code", vim.log.levels.ERROR)
    return
  end

  -- Setup close handler on first use
  terminal.setup_close_handler()

  -- Create a new session with recall source
  local new_session = session.create(nil, constants.Source.RECALL)
  state.set_active_session_id(new_session.id)

  -- Open recall in terminal
  terminal.show(new_session, window.get_win_opts(M.config))

  state.set_visible(true)
  ui.update_winbar()
end

-- Create a fresh claude session
function M.new_session()
  -- Check for claude CLI
  if not M.has_claude() then
    vim.notify("claude-multi: 'claude' CLI not found. Install from https://docs.anthropic.com/en/docs/claude-code", vim.log.levels.ERROR)
    return
  end

  local snacks = require("snacks")

  -- Setup close handler on first use
  terminal.setup_close_handler()

  local win_opts = window.get_win_opts(M.config)
  local currently_visible = terminal.is_window_visible()

  -- Hide current session if visible
  if currently_visible then
    local current_session = state.get_active_session()
    if current_session then
      snacks.terminal.toggle(terminal.get_cmd(current_session), {
        count = current_session.id,
        win = win_opts,
        auto_close = true,
      })
    end
  end

  -- Create and show new session
  local new_session = session.create(nil, constants.Source.NEW)
  terminal.show(new_session, win_opts)

  state.set_active_session_id(new_session.id)
  state.set_visible(true)
  ui.update_winbar()
end

-- Close current tab (remove from working memory)
function M.close_tab()
  local active_session = state.get_active_session()
  if not active_session then return end

  local snacks = require("snacks")

  -- Close the terminal (this will trigger on_terminal_close)
  snacks.terminal.toggle(terminal.get_cmd(active_session), {
    count = active_session.id,
    win = window.get_win_opts(M.config),
    auto_close = true,
  })
end

-- Thin wrapper for navigation.switch_session
function M.switch_session(id, skip_hide_current)
  navigation.switch_session(id, skip_hide_current, M.config)
end

-- Thin wrapper for navigation.next_session
function M.next_session()
  navigation.next_session(M.config)
end

-- Thin wrapper for navigation.prev_session
function M.prev_session()
  navigation.prev_session(M.config)
end

-- Quick-jump mode (delegates to picker module)
function M.pick_session()
  picker.start_pick()
end

-- Update winbar on current terminal window (delegates to ui module)
function M.update_winbar()
  ui.update_winbar()
end

---Get active session (for external use)
---@return table? session
function M.get_active_session()
  return state.get_active_session()
end

return M
