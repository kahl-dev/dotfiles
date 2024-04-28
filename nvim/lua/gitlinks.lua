local M = {}

local function get_git_repo()
  local f = io.popen("git config --get remote.origin.url")
  local l = f:read("*l")
  f:close()
  return l
end

local function get_git_branch()
  local f = io.popen("git rev-parse --abbrev-ref HEAD")
  local l = f:read("*l")
  f:close()
  return l
end

local function get_git_commit()
  local f = io.popen("git rev-parse HEAD")
  local l = f:read("*l")
  f:close()
  return l
end

local function get_current_file()
  -- Get the absolute path of the current file
  local absolute_file_path = vim.fn.expand("%:p")

  -- Find the root directory of the Git repository
  local f = io.popen("git rev-parse --show-toplevel")
  local git_root = f:read("*l")
  f:close()

  -- Calculate the relative path by removing the Git root from the absolute path
  local relative_file_path = absolute_file_path:sub(#git_root + 2) -- +2 to remove the leading slash

  return relative_file_path
end

local function format_git_host(repo)
  local git_host, user_repo
  if string.find(repo, "@") then -- SSH format
    git_host, user_repo = string.match(repo, "git@([%w_%.%-]+):([%w_%.%-/]+)%.git")
  else -- HTTP format
    git_host = string.match(repo, "https?://([%w_%.%-]+)/")
    if git_host == "github.com" then
      user_repo = string.match(repo, "https?://[%w_%.%-]+/([%w_%.%-]+/[%w_%.%-]+)%.git")
    elseif git_host == "gitlab.louis-net.de" then
      user_repo = string.match(repo, "https?://[%w_%.%-]+/dashboard/(.*)%.git")
    end
  end
  return git_host, user_repo
end

local osc52 = require("osc52")

local function is_remote()
  return vim.env.SSH_CONNECTION ~= nil
end

local function execute_remote_action(url)
  print("Copying URL to clipboard: " .. url)
  osc52.copy(url)
end

local function execute_local_action(url)
  print("Opening URL in browser: " .. url)
  vim.fn.jobstart("open " .. vim.fn.shellescape(url), { detach = true })
end

local function handle_action(url)
  if is_remote() then
    execute_remote_action(url)
  else
    execute_local_action(url)
  end
end

function M.open_repo()
  local repo = get_git_repo()
  local git_host, user_repo = format_git_host(repo)
  local url = string.format("https://%s/%s", git_host, user_repo)
  print("Copying URL to clipboard: " .. url)
  handle_action(url)
end

function M.open_branch()
  local repo = get_git_repo()
  local branch = get_git_branch()
  local git_host, user_repo = format_git_host(repo)
  local url = string.format("https://%s/%s/tree/%s", git_host, user_repo, branch)
  print("Copying URL to clipboard: " .. url)
  handle_action(url)
end

function M.open_commit()
  local repo = get_git_repo()
  local commit = get_git_commit()
  local git_host, user_repo = format_git_host(repo)
  local url = string.format("https://%s/%s/commit/%s", git_host, user_repo, commit)
  print("Copying URL to clipboard: " .. url)
  handle_action(url)
end

function M.open_file()
  local repo = get_git_repo()
  local branch = get_git_branch()
  local file = get_current_file()
  local git_host, user_repo = format_git_host(repo)
  local url = string.format("https://%s/%s/blob/%s/%s", git_host, user_repo, branch, file)
  print("Copying URL to clipboard: " .. url)
  handle_action(url)
end

return M
