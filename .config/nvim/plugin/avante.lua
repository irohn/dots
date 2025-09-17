local avante_ok, avante = pcall(require, "avante")
if not avante_ok then return end

avante.setup({
  provider = "claude",
  providers = {
    claude = {
      api_key_name = "cmd:cat " .. vim.env.XDG_RUNTIME_DIR .. "/agenix/anthropic-api-key.age",
    },
    gemini = {
      api_key_name = "cmd:cat " .. vim.env.XDG_RUNTIME_DIR .. "/agenix/gemini-api-key.age",
    },
    openai = {
      api_key_name = "cmd:cat " .. vim.env.XDG_RUNTIME_DIR .. "/agenix/openai-api-key.age",
    },
  },
  windows = {
    width = 40,
  },
})

local render_markdown_ok, render_markdown = pcall(require, "render-markdown")
if not render_markdown_ok then return end

render_markdown.setup({
  file_types = { "markdown", "codecompanion", "Avante" },
  code = {
    border = "thin",
  },
})
