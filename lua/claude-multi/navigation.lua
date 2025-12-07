local M = {}

-- Module dependencies
local state = require("claude-multi.state")
local ui = require("claude-multi.ui")
local terminal = require("claude-multi.terminal")
local window = require("claude-multi.window")

---Switch to specific session
---@param id number Session ID
---@param skip_hide_current? boolean Skip hiding current session
---@param config table Configuration object
function M.switch_session(id, skip_hide_current, config)
  -- Sync state with actual visibility
  if not terminal.is_window_visible() then
    state.set_visible(false)
    return
  end

  local active_id = state.get_active_session_id()
  if id == active_id then return end

  local snacks = require("snacks")
  local win_opts = window.get_win_opts(config)

  -- Get session objects
  local target_session = state.get_session_by_id(id)
  local current_session = state.get_active_session()

  if not target_session then return end

  -- Hide current session
  if not skip_hide_current and current_session then
    snacks.terminal.toggle(terminal.get_cmd(current_session), {
      count = current_session.id,
      win = win_opts,
      auto_close = true,
    })
  end

  -- Show new session (with startinsert)
  terminal.show(target_session, win_opts)

  state.set_active_session_id(id)
  ui.update_winbar()
end

---Navigate to next session (wrap around)
---@param config table Configuration object
function M.next_session(config)
  -- Sync state with actual visibility
  if not terminal.is_window_visible() then
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
    M.switch_session(sessions[1].id, false, config)
  else
    M.switch_session(sessions[idx + 1].id, false, config)
  end
end

---Navigate to previous session (wrap around)
---@param config table Configuration object
function M.prev_session(config)
  -- Sync state with actual visibility
  if not terminal.is_window_visible() then
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
    M.switch_session(sessions[#sessions].id, false, config)
  else
    M.switch_session(sessions[idx - 1].id, false, config)
  end
end

return M
