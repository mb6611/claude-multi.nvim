local M = {}

function M.check()
  vim.health.start("claude-multi.nvim")

  -- Check for snacks.nvim
  local has_snacks, _ = pcall(require, "snacks")
  if has_snacks then
    vim.health.ok("snacks.nvim is installed")
  else
    vim.health.error("snacks.nvim is not installed", {
      "Install snacks.nvim: https://github.com/folke/snacks.nvim",
    })
  end

  -- Check for claude CLI
  if vim.fn.executable("claude") == 1 then
    vim.health.ok("claude CLI is installed")
  else
    vim.health.error("claude CLI is not installed", {
      "Install Claude Code: https://docs.anthropic.com/en/docs/claude-code",
      "Required for all functionality",
    })
  end

  -- Check for recall CLI (optional)
  if vim.fn.executable("recall") == 1 then
    vim.health.ok("recall CLI is installed")
  else
    vim.health.warn("recall CLI is not installed (optional)", {
      "Install recall: https://github.com/hrishioa/recall",
      "Enables browsing conversation history with :ClaudeRecall",
      "Without it, :ClaudeToggle will open a new session instead",
    })
  end
end

return M
