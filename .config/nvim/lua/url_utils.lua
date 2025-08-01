local M = {}

-- Always use ropen for URL handling - it handles local/remote detection
local function handle_action(url)
  if url then
    print("Opening URL: " .. url)
    vim.fn.jobstart("ropen " .. vim.fn.shellescape(url), { detach = true })
  else
    vim.api.nvim_echo({ { "No valid URL provided", "ErrorMsg" } }, false, {})
  end
end

-- Functions to get Git information
local function get_git_info(command)
  local f = io.popen(command)
  if not f then
    return nil
  end
  local l = f:read("*l")
  f:close()
  return l
end

local function get_git_repo()
  return get_git_info("git config --get remote.origin.url")
end

local function get_git_branch()
  return get_git_info("git rev-parse --abbrev-ref HEAD")
end

local function get_git_commit()
  return get_git_info("git rev-parse HEAD")
end

local function get_current_file()
  local git_root = get_git_info("git rev-parse --show-toplevel")
  if not git_root then
    return nil
  end
  local absolute_file_path = vim.fn.expand("%:p")
  return absolute_file_path:sub(#git_root + 2)
end

local function format_git_host(repo)
  if not repo then
    return nil, nil
  end
  local git_host, user_repo
  if repo:find("@") then
    git_host, user_repo = repo:match("git@([%w_%.%-]+):([%w_%.%-/]+)%.git")
  else
    git_host = repo:match("https?://([%w_%.%-]+)/")
    user_repo = repo:match("https?://[%w_%.%-]+/([%w_%.%-]+/[%w_%.%-]+)%.git")
  end
  return git_host, user_repo
end

-- URL Handling Functions
function M.open_url()
  local url_under_cursor = vim.fn.expand("<cfile>")
  if url_under_cursor ~= "" then
    handle_action(url_under_cursor)
  else
    vim.api.nvim_echo({ { "No URL found under cursor", "WarningMsg" } }, false, {})
  end
end

-- Helper function to extract a JIRA ticket ID from a string
local function extract_ticket_id(str)
  return string.match(str, "[A-Z]+%-[0-9]+")
end

-- Retrieve the JIRA workspace URL from the environment variable
local jira_workspace = os.getenv("JIRA_WORKSPACE")

-- Functions to open JIRA links
function M.open_jira_from_branch()
  local branch_name = get_git_info("git branch --show-current")
  local ticket_id = extract_ticket_id(branch_name)
  if ticket_id then
    local jira_url = string.format("%s/browse/%s", jira_workspace, ticket_id)
    handle_action(jira_url)
  else
    print("No JIRA ticket found in the branch name.")
  end
end

-- Process a URL from a string
function M.process_url(url)
  handle_action(url)
end

-- Open JIRA ticket from a selected commit using Telescope
function M.open_jira_from_commit()
  local ok, builtins = pcall(require, "telescope.builtin")
  if not ok then
    vim.api.nvim_echo({ { "Telescope not available. Install telescope.nvim plugin.", "ErrorMsg" } }, false, {})
    return
  end
  
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  
  builtins.git_commits({
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          local commit_msg = get_git_info("git log -1 --format=%B " .. selection.value)
          local ticket_id = extract_ticket_id(commit_msg)
          if ticket_id then
            local jira_url = string.format("%s/browse/%s", jira_workspace, ticket_id)
            handle_action(jira_url)
          else
            print("No JIRA ticket found in the commit message.")
          end
        end
      end)
      return true
    end,
  })
end

-- Git Link Functions
function M.open_repo()
  local repo = get_git_repo()
  local git_host, user_repo = format_git_host(repo)
  if git_host and user_repo then
    local url = string.format("https://%s/%s", git_host, user_repo)
    handle_action(url)
  else
    vim.api.nvim_echo({ { "Failed to determine Git repository information", "ErrorMsg" } }, false, {})
  end
end

function M.open_branch()
  local repo = get_git_repo()
  local branch = get_git_branch()
  local git_host, user_repo = format_git_host(repo)
  if git_host and user_repo and branch then
    local url = string.format("https://%s/%s/tree/%s", git_host, user_repo, branch)
    handle_action(url)
  else
    vim.api.nvim_echo({ { "Failed to determine Git branch information", "ErrorMsg" } }, false, {})
  end
end

function M.open_commit()
  local repo = get_git_repo()
  local commit = get_git_commit()
  local git_host, user_repo = format_git_host(repo)
  if git_host and user_repo and commit then
    local url = string.format("https://%s/%s/commit/%s", git_host, user_repo, commit)
    handle_action(url)
  else
    vim.api.nvim_echo({ { "Failed to determine Git commit information", "ErrorMsg" } }, false, {})
  end
end

function M.open_file()
  local repo = get_git_repo()
  local branch = get_git_branch()
  local file = get_current_file()
  local git_host, user_repo = format_git_host(repo)
  if git_host and user_repo and branch and file then
    local url = string.format("https://%s/%s/blob/%s/%s", git_host, user_repo, branch, file)
    handle_action(url)
  else
    vim.api.nvim_echo({ { "Failed to determine file path in Git repository", "ErrorMsg" } }, false, {})
  end
end

return M
