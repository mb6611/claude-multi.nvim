local M = {}

M.letters = "abcdefghijklmnopqrstuvwxyz"

---Start pick mode: display letters and wait for key press
function M.start_pick()
  local state = require("claude-multi.state")
  local ui = require("claude-multi.ui")

  -- Check if visible and has sessions
  if not state.get_visible() then
    state.set_visible(false)
    return
  end

  local sessions = state.get_sessions()
  if #sessions <= 1 then
    return
  end

  -- Enter pick mode
  state.set_pick_mode(true)
  ui.update_winbar()

  -- Wait for key press (with timeout)
  local ok, char = pcall(function()
    return vim.fn.getcharstr()
  end)

  state.set_pick_mode(false)

  if ok and char then
    -- Convert letter to session index
    local idx = M.letters:find(char)
    if idx and idx <= #sessions then
      local session = sessions[idx]
      state.set_active_session_id(session.id)
      return
    end
  end

  ui.update_winbar()
end

---Get session by letter
---@param char string Single character
---@return table? session
function M.get_session_for_letter(char)
  local state = require("claude-multi.state")
  local sessions = state.get_sessions()

  local idx = M.letters:find(char)
  if idx and idx <= #sessions then
    return sessions[idx]
  end

  return nil
end

---Cancel pick mode without switching
function M.cancel_pick()
  local state = require("claude-multi.state")
  local ui = require("claude-multi.ui")
  state.set_pick_mode(false)
  ui.update_winbar()
end

return M
