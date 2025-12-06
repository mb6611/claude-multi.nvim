local M = {}

-- Internal state
local _state = {
  visible = false,
  active_session_id = nil,
  sessions = {},
  pick_mode = false,
  next_id = 1,
}

-- Change listeners
local _listeners = {}

---Initialize state with defaults or provided values
---@param initial_state? table Initial state to merge
function M.init(initial_state)
  if initial_state then
    _state = vim.tbl_extend("force", _state, initial_state)
  end
end

---Get a deep copy of the entire state
---@return table
function M.get_state()
  return vim.deepcopy(_state)
end

---Get all sessions
---@return table[] sessions
function M.get_sessions()
  return vim.deepcopy(_state.sessions)
end

---Get active session object
---@return table? session
function M.get_active_session()
  if not _state.active_session_id then return nil end
  return M.get_session_by_id(_state.active_session_id)
end

---Get session by ID
---@param id number
---@return table? session
function M.get_session_by_id(id)
  for _, session in ipairs(_state.sessions) do
    if session.id == id then
      return vim.deepcopy(session)
    end
  end
  return nil
end

---Get active session ID
---@return number?
function M.get_active_session_id()
  return _state.active_session_id
end

---Get visibility state
---@return boolean
function M.get_visible()
  return _state.visible
end

---Get pick mode state
---@return boolean
function M.get_pick_mode()
  return _state.pick_mode
end

---Get next ID counter
---@return number
function M.get_next_id()
  return _state.next_id
end

---Set visibility state
---@param visible boolean
function M.set_visible(visible)
  _state.visible = visible
  M.notify_change()
end

---Set active session ID
---@param id number?
function M.set_active_session_id(id)
  if id and not M.get_session_by_id(id) then
    return false
  end
  _state.active_session_id = id
  M.notify_change()
  return true
end

---Set pick mode
---@param enabled boolean
function M.set_pick_mode(enabled)
  _state.pick_mode = enabled
  M.notify_change()
end

---Add a session
---@param session table
---@return boolean success
function M.add_session(session)
  if not session or not session.id then
    return false
  end
  table.insert(_state.sessions, vim.deepcopy(session))
  M.notify_change()
  return true
end

---Remove a session by ID
---@param id number
---@return boolean success
function M.remove_session(id)
  local found = false
  local new_sessions = {}
  for _, s in ipairs(_state.sessions) do
    if s.id ~= id then
      table.insert(new_sessions, s)
    else
      found = true
    end
  end
  if found then
    _state.sessions = new_sessions
    M.notify_change()
  end
  return found
end

---Update a session (partial update)
---@param id number
---@param updates table
---@return boolean success
function M.update_session(id, updates)
  for _, session in ipairs(_state.sessions) do
    if session.id == id then
      -- Modify the table in-place (don't reassign the loop variable!)
      for k, v in pairs(updates) do
        session[k] = v
      end
      M.notify_change()
      return true
    end
  end
  return false
end

---Generate and return next ID
---@return number
function M.generate_next_id()
  local id = _state.next_id
  _state.next_id = _state.next_id + 1
  M.notify_change()
  return id
end

---Register a change listener
---@param callback function Called with (state) when state changes
---@return function unsubscribe function to remove listener
function M.on_change(callback)
  table.insert(_listeners, callback)
  return function()
    for i, listener in ipairs(_listeners) do
      if listener == callback then
        table.remove(_listeners, i)
        break
      end
    end
  end
end

---Notify all listeners of state change
function M.notify_change()
  for _, listener in ipairs(_listeners) do
    local ok, err = pcall(listener, M.get_state())
    if not ok then
      vim.notify("State listener error: " .. err, vim.log.levels.ERROR)
    end
  end
end

---Reset state to defaults (testing helper)
function M.reset()
  _state = {
    visible = false,
    active_session_id = nil,
    sessions = {},
    pick_mode = false,
    next_id = 1,
  }
  _listeners = {}
end

return M
