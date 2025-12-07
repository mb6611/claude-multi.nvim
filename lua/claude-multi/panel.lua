local M = {}

local constants = require("claude-multi.constants")
local state = require("claude-multi.state")
local session = require("claude-multi.session")
local ui = require("claude-multi.ui")
local terminal = require("claude-multi.terminal")
local window = require("claude-multi.window")
local health = require("claude-multi.health")

---Toggle the Claude panel visibility
---@param config table Plugin configuration
function M.toggle(config)
  if not health.has_claude() then
    vim.notify("claude-multi: 'claude' CLI not found. Install from https://docs.anthropic.com/en/docs/claude-code", vim.log.levels.ERROR)
    return
  end

  local snacks = require("snacks")
  terminal.setup_close_handler()

  local actually_visible = terminal.is_window_visible()

  if actually_visible then
    -- Window is visible, hide it
    local active_session = state.get_active_session()
    if active_session then
      snacks.terminal.toggle(terminal.get_cmd(active_session), {
        count = active_session.id,
        win = window.get_win_opts(config),
        auto_close = true,
      })
    end
    state.set_visible(false)
  else
    -- Window is hidden, show it
    local sessions = state.get_sessions()

    if #sessions == 0 then
      -- No tabs exist, open new session
      M.new_session(config)
    else
      -- Show existing active session
      local active_session = state.get_active_session()
      if active_session then
        terminal.show(active_session, window.get_win_opts(config))
        state.set_visible(true)
        ui.update_winbar()
      end
    end
  end
end

---Create a new Claude session
---@param config table Plugin configuration
---@param cwd? string Working directory path
function M.new_session(config, cwd)
  if not health.has_claude() then
    vim.notify("claude-multi: 'claude' CLI not found. Install from https://docs.anthropic.com/en/docs/claude-code", vim.log.levels.ERROR)
    return
  end

  -- Default to current working directory if no path provided
  if cwd then
    cwd = vim.fn.expand(cwd)
    if vim.fn.isdirectory(cwd) ~= 1 then
      vim.notify("claude-multi: Directory not found: " .. cwd, vim.log.levels.ERROR)
      return
    end
  else
    cwd = vim.fn.getcwd()
  end

  local snacks = require("snacks")
  terminal.setup_close_handler()

  local win_opts = window.get_win_opts(config)
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
  local new_session = session.create(nil, constants.Source.NEW, cwd)
  terminal.show(new_session, win_opts)

  state.set_active_session_id(new_session.id)
  state.set_visible(true)
  ui.update_winbar()
end

---Close the current tab
---@param config table Plugin configuration
function M.close_tab(config)
  local active_session = state.get_active_session()
  if not active_session then return end

  local snacks = require("snacks")

  -- Close the terminal (this will trigger on_terminal_close)
  snacks.terminal.toggle(terminal.get_cmd(active_session), {
    count = active_session.id,
    win = window.get_win_opts(config),
    auto_close = true,
  })
end

return M
