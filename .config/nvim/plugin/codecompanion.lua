local api_keys = {
  anthropic = string.format("cmd:cat %s/agenix/anthropic-api-key.age", vim.env.XDG_RUNTIME_DIR),
  gemini = string.format("cmd:cat %s/agenix/gemini-api-key.age", vim.env.XDG_RUNTIME_DIR),
  openai = string.format("cmd:cat %s/agenix/openai-api-key.age", vim.env.XDG_RUNTIME_DIR),
}

require("codecompanion").setup({
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        -- MCP Tools
        make_tools = true,                    -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
        show_server_tools_in_chat = true,     -- Show individual tools in chat completion (when make_tools=true)
        add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
        show_result_in_chat = true,           -- Show tool results directly in chat buffer
        format_tool = nil,                    -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
        -- MCP Resources
        make_vars = true,                     -- Convert MCP resources to #variables for prompts
        -- MCP Prompts
        make_slash_commands = true,           -- Add MCP prompts as /slash commands
      }
    }
  },
  adapters = {
    anthropic = function()
      return require("codecompanion.adapters").extend("anthropic", {
        env = {
          api_key = api_keys.anthropic,
        },
      })
    end,
    gemini = function()
      return require("codecompanion.adapters").extend("gemini", {
        env = {
          api_key = api_keys.gemini,
        },
      })
    end,
    openai = function()
      return require("codecompanion.adapters").extend("openai", {
        env = {
          api_key = api_keys.openai,
        },
      })
    end,
  },
})

vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
vim.keymap.set("v", "<leader>ae", ":CodeCompanion /buffer ", { noremap = true, silent = false })
vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })
