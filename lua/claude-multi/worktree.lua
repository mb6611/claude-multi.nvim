local M = {}

local git = require("claude-multi.git")
local health = require("claude-multi.health")

---Pick an existing worktree or create a new one
---@param callback function Called with (path) when worktree is ready
---@param prompt? string Custom prompt text
function M.pick(callback, prompt)
  local worktrees = git.list_worktrees()
  local snacks = require("snacks")

  -- Build items for picker
  local items = {}
  for _, wt in ipairs(worktrees) do
    table.insert(items, {
      text = wt.branch or "detached",
      path = wt.path,
      branch = wt.branch,
    })
  end

  snacks.picker.select(items, {
    prompt = prompt or "Worktree",
    format_item = function(item)
      return item.text
    end,
    snacks = {
      actions = {
        confirm = function(picker, item)
          local typed = picker.input:get()
          local match_count = picker.list:count()

          if match_count == 0 and typed ~= "" then
            -- No matches - create new worktree from typed text
            picker:close()
            local path = git.get_worktree_path(typed)
            git.create_worktree(path, typed, function(success)
              if success then
                callback(path)
              end
            end)
          elseif item then
            -- Selected existing worktree
            picker:close()
            callback(item.path)
          else
            picker:close()
          end
        end,
      },
    },
  }, function() end)
end

---Open new session with worktree picker
---@param new_session_fn function Function to create new session (receives cwd)
function M.new_session(new_session_fn)
  M.pick(function(path)
    new_session_fn(path)
  end, "Select worktree for new session:")
end

---Open recall with worktree picker
---@param open_recall_fn function Function to open recall (receives cwd)
function M.open_recall(open_recall_fn)
  if not health.has_recall() then
    vim.notify("claude-multi: 'recall' CLI not found. Install from https://github.com/hrishioa/recall", vim.log.levels.ERROR)
    return
  end

  M.pick(function(path)
    open_recall_fn(path)
  end, "Select worktree for recall:")
end

return M
