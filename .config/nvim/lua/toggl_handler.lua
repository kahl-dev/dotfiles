local M = {}
local job = require("plenary.job")

M.get_ticket_id = function()
  local toggl_api_token = os.getenv("T")
  if toggl_api_token == nil or toggl_api_token == "" then
    print("Error: Toggl API token is not set in the T environment variable.")
    return
  end
  print("Toggl API Token: " .. toggl_api_token)

  local cmd = string.format(
    'curl -s https://api.track.toggl.com/api/v9/me/time_entries/current -H "Content-Type: application/json" -u %s:api_token',
    toggl_api_token
  )
  print("Command to execute: " .. cmd)

  job
    :new({
      command = "sh",
      args = { "-c", cmd },
      on_exit = function(j, return_val)
        local output = j:result()
        print("Raw curl output: ", vim.inspect(output))

        if output and #output > 0 then
          local description = output[1] or ""
          local ticket_id = description:match("[A-Z]+-[0-9]+") or ""

          if ticket_id == "" then
            print("Error: No ticket ID found in the description.")
          else
            print("Extracted Ticket ID: " .. ticket_id)

            vim.schedule(function()
              vim.cmd("normal! l") -- Move cursor one character to the right first
              vim.api.nvim_put({ ticket_id }, "c", false, true)
              vim.cmd("startinsert") -- Enter insert mode
              if ticket_id ~= "" then
                print("Inserted Ticket ID into buffer.")
              else
                print("Inserted empty line into buffer as the ticket ID was empty.")
              end
            end)
          end
        else
          print("Error: No output from curl command.")
        end
      end,
    })
    :start()
end

return M
