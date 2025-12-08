local M = {}

-- Module dependencies
local state = require("claude-multi.state")
local session = require("claude-multi.session")
local ui = require("claude-multi.ui")
local constants = require("claude-multi.constants")

-- Re-entry guard for terminal close handler (prevents infinite loops)
local _handling_close = false

-- Stored config reference (set during setup to avoid circular dependency)
---@type table?
local _config = nil

---Set config reference (called from init.setup)
---@param config table Plugin configuration
function M.set_config(config)
  _config = config
end

---Get shell command for a session
---@param sess table Session object
---@return string command
function M.get_cmd(sess)
  local cmd = sess.source == constants.Source.RECALL and "recall" or "claude"

  if sess.cwd then
    return string.format("zsh -i -c 'cd %s && %s'", vim.fn.shellescape(sess.cwd), cmd)
  else
    return "zsh -i -c '" .. cmd .. "'"
  end
end

---Show a terminal session and enter insert mode
---@param sess table Session object
---@param win_opts table Window options
function M.show(sess, win_opts)
  local snacks = require("snacks")
  snacks.terminal.toggle(M.get_cmd(sess), {
    count = sess.id,
    win = win_opts,
    auto_close = true,
  })
  -- Defer startinsert to ensure terminal is focused
  vim.defer_fn(function()
    vim.cmd("startinsert")
  end, 10)
end

---Check if terminal window is actually visible
---@return boolean
function M.is_window_visible()
  -- Get valid session IDs
  local sessions = state.get_sessions()
  local session_ids = {}
  for _, sess in ipairs(sessions) do
    session_ids[sess.id] = true
  end

  -- Check if any visible terminal belongs to our sessions
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == constants.BufferType.TERMINAL then
      -- Check if this terminal has snacks metadata and matches our session IDs
      local metadata = vim.b[buf].snacks_terminal
      if metadata and metadata.id and session_ids[metadata.id] then
        return true
      end
    end
  end
  return false
end

---Handle terminal process exit
---Delete the session and switch to left session (or close if none)
---@param buf number Buffer number
function M.on_terminal_close(buf)
  -- Re-entry guard to prevent infinite loops
  if _handling_close then return end
  _handling_close = true

  -- Check if buffer is still valid (may be deleted by the time autocmd fires)
  if not vim.api.nvim_buf_is_valid(buf) then
    _handling_close = false
    return
  end

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

      if next_session and _config then
        state.set_active_session_id(next_session.id)
        -- Show the next session
        local window = require("claude-multi.window")
        M.show(next_session, window.get_win_opts(_config))
        ui.update_winbar()
      end
    end

    _handling_close = false
  end)
end

---Setup autocmd for terminal close (called once on first toggle)
function M.setup_close_handler()
  if M._close_handler_setup then return end
  M._close_handler_setup = true

  vim.api.nvim_create_autocmd("TermClose", {
    pattern = "*",
    callback = function(event)
      M.on_terminal_close(event.buf)
    end,
  })
end

return M
