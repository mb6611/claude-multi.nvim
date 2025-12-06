local M = {}

---Create a new session with optional name and source
---@param name? string
---@param source? string "recall" or "new" (default: "new")
---@return table session
function M.create(name, source)
  local state = require("claude-multi.state")
  local id = state.generate_next_id()

  local session = {
    id = id,
    name = name or M.get_default_name(),
    source = source or "new",  -- "recall" or "new"
    created_at = os.time(),
  }

  state.add_session(session)
  return session
end

---Create session with user prompt for name
---@param callback? function
function M.create_with_prompt(callback)
  vim.ui.input({
    prompt = "Session name (leave empty for auto-name): ",
  }, function(input)
    if input == nil then
      -- User cancelled
      if callback then callback(nil) end
      return
    end

    -- Empty string means use default name
    local name = input == "" and nil or input
    local session = M.create(name)

    if callback then callback(session) end
  end)
end

---Rename a session by ID
---@param id number
---@param new_name string
---@return boolean success
---@return string? error
function M.rename(id, new_name)
  if not new_name or new_name == "" then
    return false, "Name cannot be empty"
  end

  local state = require("claude-multi.state")
  return state.update_session(id, { name = new_name })
end

---Rename session with user prompt
---@param id number
---@param callback? function
function M.rename_with_prompt(id, callback)
  local state = require("claude-multi.state")
  local session = state.get_session_by_id(id)

  if not session then
    vim.notify("Session not found", vim.log.levels.ERROR)
    if callback then callback(false) end
    return
  end

  vim.ui.input({
    prompt = "New session name: ",
    default = session.name,
  }, function(input)
    if input == nil then
      -- User cancelled
      if callback then callback(false) end
      return
    end

    if input == "" then
      vim.notify("Name cannot be empty", vim.log.levels.WARN)
      if callback then callback(false) end
      return
    end

    local success = M.rename(id, input)
    if callback then callback(success) end
  end)
end

---Delete a session by ID
---@param id number
---@return boolean success
function M.delete(id)
  local state = require("claude-multi.state")
  return state.remove_session(id)
end

---Get display name for a session (formatted)
---@param session table
---@return string
function M.get_display_name(session)
  if not session then return "" end

  local name = session.name or "Unnamed"
  local prefix = ""

  -- Add source indicator
  if session.source == "recall" then
    prefix = "[R] "
  elseif session.source == "new" then
    prefix = "[N] "
  end

  return prefix .. name
end

---Get default session name based on count
---@return string
function M.get_default_name()
  local state = require("claude-multi.state")
  local sessions = state.get_sessions()
  return "Chat " .. (#sessions + 1)
end


---Validate session data structure
---@param session table
---@return boolean valid
---@return string? error_message
function M.validate(session)
  if type(session) ~= "table" then
    return false, "Session must be a table"
  end

  if not session.id or type(session.id) ~= "number" then
    return false, "Session must have a numeric id"
  end

  if not session.name or type(session.name) ~= "string" then
    return false, "Session must have a string name"
  end

  if not session.created_at or type(session.created_at) ~= "number" then
    return false, "Session must have a created_at timestamp"
  end

  local valid_sources = { recall = true, new = true }
  if session.source and not valid_sources[session.source] then
    return false, "Invalid session source: " .. tostring(session.source)
  end

  return true
end

return M
