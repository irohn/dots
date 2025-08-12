local M = {}

M.api_keys = {
  anthropic = string.format("cmd:cat %s/agenix/anthropic-api-key.age", vim.env.XDG_RUNTIME_DIR),
  gemini = string.format("cmd:cat %s/agenix/gemini-api-key.age", vim.env.XDG_RUNTIME_DIR),
  openai = string.format("cmd:cat %s/agenix/openai-api-key.age", vim.env.XDG_RUNTIME_DIR),
}

return M
