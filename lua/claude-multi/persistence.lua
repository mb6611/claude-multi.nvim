local M = {}

---Get the data directory path for the current project
---@return string
function M.get_data_path()
  local cwd = vim.fn.getcwd()
  return cwd .. "/.claude-multi"
end

---Get the sessions file path
---@return string
function M.get_sessions_file()
  return M.get_data_path() .. "/sessions.json"
end

---Ensure the data directory exists
---@return boolean success
---@return string? error_message
function M.ensure_data_dir()
  local data_path = M.get_data_path()

  -- Check if directory exists
  if vim.fn.isdirectory(data_path) == 1 then
    return true
  end

  -- Try to create directory
  local ok = vim.fn.mkdir(data_path, "p")
  if ok == 0 then
    return false, "Failed to create directory: " .. data_path
  end

  return true
end

---Save state to JSON file
---@param state table The state object from state.lua
---@return boolean success
---@return string? error_message
function M.save(state)
  -- Ensure directory exists
  local ok, err = M.ensure_data_dir()
  if not ok then
    return false, err
  end

  -- Prepare data for persistence
  local data = {
    version = 1,
    next_id = state.next_id,
    active_session_id = state.active_session_id,
    sessions = state.sessions,
  }

  -- Encode to JSON
  local json_ok, json_str = pcall(vim.fn.json_encode, data)
  if not json_ok then
    return false, "Failed to encode JSON: " .. tostring(json_str)
  end

  -- Write to file
  local file_path = M.get_sessions_file()
  local write_ok = pcall(vim.fn.writefile, { json_str }, file_path)
  if not write_ok then
    return false, "Failed to write file: " .. file_path
  end

  return true
end

---Load state from JSON file
---@return table? state_data Returns nil if file doesn't exist
---@return string? error_message
function M.load()
  local file_path = M.get_sessions_file()

  -- Check if file exists
  if vim.fn.filereadable(file_path) == 0 then
    return nil, nil  -- Not an error, just no saved state
  end

  -- Read file
  local read_ok, lines = pcall(vim.fn.readfile, file_path)
  if not read_ok then
    return nil, "Failed to read file: " .. file_path
  end

  -- Join lines (should be single line JSON)
  local json_str = table.concat(lines, "\n")

  -- Decode JSON
  local decode_ok, data = pcall(vim.fn.json_decode, json_str)
  if not decode_ok then
    return nil, "Failed to decode JSON: " .. tostring(data)
  end

  -- Migrate if needed
  data = M.migrate(data)

  return data
end

---Migrate data from older versions
---@param data table Raw loaded data
---@return table migrated_data
function M.migrate(data)
  -- Ensure version field exists
  if not data.version then
    data.version = 1
  end

  -- Version 1 migrations (current version, no changes needed)
  if data.version == 1 then
    -- Ensure required fields exist
    data.next_id = data.next_id or 1
    data.active_session_id = data.active_session_id or nil
    data.sessions = data.sessions or {}

    -- Validate each session has required fields
    for i, session in ipairs(data.sessions) do
      session.id = session.id or i
      session.name = session.name or ("Session " .. session.id)
      session.type = session.type or "chat"
      session.created_at = session.created_at or os.time()
      -- Default started to false for old sessions (safe: will use --session-id)
      if session.started == nil then
        session.started = false
      end
    end
  end

  -- Future version migrations would go here
  -- if data.version == 2 then ... end

  return data
end

return M
