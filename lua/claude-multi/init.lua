local M = {}

-- Re-entry guard for terminal close handler (prevents infinite loops)
local _handling_close = false

-- Module requirements
local state = require("claude-multi.state")
local session = require("claude-multi.session")
local ui = require("claude-multi.ui")
local picker = require("claude-multi.picker")

-- Configuration
M.config = {
  layout = "float",      -- "float" or "sidebar"
  float_width = 0.85,
  float_height = 0.85,
  sidebar_width = 0.4,
}

-- Setup function (called from plugin spec)
function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})

  -- Setup highlights
  ui.setup_highlights()

  -- Initialize with empty state (ephemeral working memory)
  state.init()

  -- Setup terminal close handler
  M.setup_terminal_close_handler()
end

-- Get shell command for a session
---@param sess table Session object
---@return string command
function M.get_cmd(sess)
  if sess.source == "recall" then
    -- Recall TUI - user selects conversation
    return "zsh -i -c 'recall'"
  else
    -- Fresh claude session
    return "zsh -i -c 'claude'"
  end
end

-- Get window options based on layout mode
function M.get_win_opts()
  local opts = {
    wo = {
      winbar = M.get_winbar(),
    },
  }

  if M.config.layout == "sidebar" then
    opts.position = "right"
    opts.width = M.config.sidebar_width
    opts.height = 1.0
    opts.border = "single"
  else
    opts.position = "float"
    opts.width = M.config.float_width
    opts.height = M.config.float_height
    opts.border = "rounded"
  end

  return opts
end

-- Get winbar string (delegates to ui module)
function M.get_winbar()
  return ui.get_winbar()
end

-- Check if terminal window is actually visible
function M.is_window_visible()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then
      return true
    end
  end
  return false
end

-- Handle terminal process exit
-- Delete the session and switch to left session (or close if none)
function M.on_terminal_close(buf)
  -- Re-entry guard to prevent infinite loops
  if _handling_close then return end
  _handling_close = true

  -- Get the session id from buffer metadata
  local metadata = vim.b[buf].snacks_terminal
  if not metadata then
    _handling_close = false
    return
  end

  local session_id = metadata.id

  -- Find the session and its index
  local sessions = state.get_sessions()
  local closed_idx = nil
  for i, sess in ipairs(sessions) do
    if sess.id == session_id then
      closed_idx = i
      break
    end
  end

  -- If this wasn't one of our sessions, ignore
  if not closed_idx then
    _handling_close = false
    return
  end

  local active_id = state.get_active_session_id()

  vim.schedule(function()
    -- Delete the closed session from state
    state.remove_session(session_id)

    -- Get remaining sessions
    local remaining = state.get_sessions()

    if #remaining == 0 then
      -- No sessions left, close window
      state.set_visible(false)
      state.set_active_session_id(nil)
      ui.update_winbar()
    elseif active_id == session_id then
      -- The active session was closed, switch to left (or first if was leftmost)
      local new_idx = math.max(1, closed_idx - 1)
      if new_idx > #remaining then new_idx = #remaining end
      local next_session = remaining[new_idx]

      if next_session then
        state.set_active_session_id(next_session.id)
        -- Show the next session
        local snacks = require("snacks")
        snacks.terminal.toggle(M.get_cmd(next_session), {
          count = next_session.id,
          win = M.get_win_opts(),
          auto_close = true,
        })
        ui.update_winbar()
      end
    end

    _handling_close = false
  end)
end

-- Setup autocmd for terminal close (called once on first toggle)
function M.setup_terminal_close_handler()
  if M._close_handler_setup then return end
  M._close_handler_setup = true

  vim.api.nvim_create_autocmd("TermClose", {
    pattern = "*",
    callback = function(event)
      M.on_terminal_close(event.buf)
    end,
  })
end


-- Toggle the panel
function M.toggle()
  local snacks = require("snacks")

  -- Setup close handler on first use
  M.setup_terminal_close_handler()

  -- Sync state with actual window visibility
  local actually_visible = M.is_window_visible()

  if actually_visible then
    -- Window is visible, hide it
    local active_session = state.get_active_session()
    if active_session then
      snacks.terminal.toggle(M.get_cmd(active_session), {
        count = active_session.id,
        win = M.get_win_opts(),
        auto_close = true,
      })
    end
    state.set_visible(false)
  else
    -- Window is hidden, show it
    local sessions = state.get_sessions()

    if #sessions == 0 then
      -- No tabs exist, open recall
      M.open_recall()
    else
      -- Show existing active session
      local active_session = state.get_active_session()
      if active_session then
        snacks.terminal.toggle(M.get_cmd(active_session), {
          count = active_session.id,
          win = M.get_win_opts(),
          auto_close = true,
        })
        state.set_visible(true)
        ui.update_winbar()
      end
    end
  end
end

-- Switch to specific session
function M.switch_session(id, skip_hide_current)
  -- Sync state with actual visibility
  if not M.is_window_visible() then
    state.set_visible(false)
    return
  end

  local active_id = state.get_active_session_id()
  if id == active_id then return end

  local snacks = require("snacks")
  local win_opts = M.get_win_opts()

  -- Get session objects
  local target_session = state.get_session_by_id(id)
  local current_session = state.get_active_session()

  if not target_session then return end

  -- Hide current session
  if not skip_hide_current and current_session then
    snacks.terminal.toggle(M.get_cmd(current_session), {
      count = current_session.id,
      win = win_opts,
      auto_close = true,
    })
  end

  -- Show new session
  snacks.terminal.toggle(M.get_cmd(target_session), {
    count = target_session.id,
    win = win_opts,
    auto_close = true,
  })

  state.set_active_session_id(id)
  ui.update_winbar()
end

-- Navigate to next session
function M.next_session()
  -- Sync state with actual visibility
  if not M.is_window_visible() then
    state.set_visible(false)
    return
  end

  local sessions = state.get_sessions()
  local active_id = state.get_active_session_id()

  if #sessions == 0 then return end

  local idx = 1
  for i, sess in ipairs(sessions) do
    if sess.id == active_id then
      idx = i
      break
    end
  end

  -- Navigate to next session (wrap around to first)
  if idx >= #sessions then
    M.switch_session(sessions[1].id)
  else
    M.switch_session(sessions[idx + 1].id)
  end
end

-- Navigate to previous session
function M.prev_session()
  -- Sync state with actual visibility
  if not M.is_window_visible() then
    state.set_visible(false)
    return
  end

  local sessions = state.get_sessions()
  local active_id = state.get_active_session_id()

  if #sessions == 0 then return end

  local idx = 1
  for i, sess in ipairs(sessions) do
    if sess.id == active_id then
      idx = i
      break
    end
  end

  -- Navigate to previous session (wrap around to last)
  if idx <= 1 then
    M.switch_session(sessions[#sessions].id)
  else
    M.switch_session(sessions[idx - 1].id)
  end
end

-- Open recall TUI for session selection
function M.open_recall()
  local snacks = require("snacks")

  -- Setup close handler on first use
  M.setup_terminal_close_handler()

  -- Create a new session with recall source
  local new_session = session.create(nil, "recall")
  state.set_active_session_id(new_session.id)

  -- Open recall in terminal
  snacks.terminal.toggle(M.get_cmd(new_session), {
    count = new_session.id,
    win = M.get_win_opts(),
    auto_close = true,
  })

  state.set_visible(true)
  ui.update_winbar()
end

-- Create a fresh claude session
function M.new_session()
  local snacks = require("snacks")

  -- Setup close handler on first use
  M.setup_terminal_close_handler()

  local win_opts = M.get_win_opts()
  local currently_visible = M.is_window_visible()

  -- Hide current session if visible
  if currently_visible then
    local current_session = state.get_active_session()
    if current_session then
      snacks.terminal.toggle(M.get_cmd(current_session), {
        count = current_session.id,
        win = win_opts,
        auto_close = true,
      })
    end
  end

  -- Create and show new session
  local new_session = session.create(nil, "new")
  snacks.terminal.toggle(M.get_cmd(new_session), {
    count = new_session.id,
    win = win_opts,
    auto_close = true,
  })

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
  snacks.terminal.toggle(M.get_cmd(active_session), {
    count = active_session.id,
    win = M.get_win_opts(),
    auto_close = true,
  })
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
