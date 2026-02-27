-- LSP compatibility for legacy projects (old Node, old TypeScript)
local M = {}

--- Prepend global mise Node to PATH so Mason LSP servers don't use project-local Node
function M.ensure_modern_node()
  local host = os.getenv("NEOVIM_NODE_HOST")
  local bin_dir = host and vim.fn.fnamemodify(host, ":h")

  if not bin_dir then
    local result = vim.fn.system("mise where node@lts 2>/dev/null")
    if vim.v.shell_error == 0 and result ~= "" then
      bin_dir = vim.fn.trim(result) .. "/bin"
    end
  end

  if bin_dir and not (vim.env.PATH or ""):find(bin_dir, 1, true) then
    vim.env.PATH = bin_dir .. ":" .. vim.env.PATH
  end
end

--- Return Mason's bundled tsdk when project TypeScript is too old (<4.0)
function M.resolve_tsdk()
  local project_ts = vim.fn.findfile("node_modules/typescript/package.json", vim.fn.getcwd() .. ";")
  if project_ts ~= "" then
    local ok, lines = pcall(vim.fn.readfile, project_ts)
    if ok then
      local major = table.concat(lines, ""):match('"version"%s*:%s*"(%d+)%.')
      if major and tonumber(major) >= 4 then
        return nil
      end
    end
  end

  local mason_tsdk = vim.fn.expand(
    "$HOME/.local/share/nvim/mason/packages/vtsls/node_modules/@vtsls/language-server/node_modules/typescript/lib"
  )
  if vim.fn.isdirectory(mason_tsdk) == 1 then
    return mason_tsdk
  end
  return nil
end

--- Disable formatting for buffers inside Nuxt projects
function M.disable_nuxt_formatting(client, bufnr)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then return end
  local dir = vim.fn.fnamemodify(bufname, ":h")
  while dir ~= "/" do
    for _, cfg in ipairs({ "nuxt.config.ts", "nuxt.config.js", "nuxt.config.mjs" }) do
      if vim.fn.filereadable(dir .. "/" .. cfg) == 1 then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        return
      end
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
end

return M
