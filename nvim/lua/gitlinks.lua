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
  local f = io.popen("git rev-parse --show-prefix")
  local repo_relative_path = f:read("*l")
  f:close()

  -- Get the filename relative to the current directory
  local filename = vim.fn.expand("%")

  return repo_relative_path .. filename
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

function M.open_repo()
  local repo = get_git_repo()
  local git_host, user_repo = format_git_host(repo)
  local url = string.format("https://%s/%s", git_host, user_repo)
  print("Opening URL: " .. url)
  os.execute(string.format("open '%s'", url))
end

function M.open_branch()
  local repo = get_git_repo()
  local branch = get_git_branch()
  local git_host, user_repo = format_git_host(repo)
  local url = string.format("https://%s/%s/tree/%s", git_host, user_repo, branch)
  print("Opening URL: " .. url)
  os.execute(string.format("open '%s'", url))
end

function M.open_commit()
  local repo = get_git_repo()
  local commit = get_git_commit()
  local git_host, user_repo = format_git_host(repo)
  local url = string.format("https://%s/%s/commit/%s", git_host, user_repo, commit)
  print("Opening URL: " .. url)
  os.execute(string.format("open '%s'", url))
end

function M.open_file()
  local repo = get_git_repo()
  local branch = get_git_branch()
  local file = get_current_file()
  local git_host, user_repo = format_git_host(repo)
  local url = string.format("https://%s/%s/blob/%s/%s", git_host, user_repo, branch, file)
  print("Opening URL: " .. url)
  os.execute(string.format("open '%s'", url))
end

return M
