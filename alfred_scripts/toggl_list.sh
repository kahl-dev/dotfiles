#!/usr/bin/env bash

# https://www.alfredapp.com/help/workflows/inputs/script-filter/
# https://engineering.toggl.com/docs/api/time_entry/index.html

cat <<EOF
{
  "items": [
    {
      "uid": "0",
      "type": "toggl entry",
      "title": "List Toggl Time Entries 1",
      "subtitle": "List all Toggl time entries 1",
      "arg": "list",
      "autocomplete": "List Toggl Time Entries 1",
    },
    {
      "uid": "1",
      "type": "toggl entry",
      "title": "List Toggl Time Entries 2",
      "subtitle": "List all Toggl time entries 2",
      "arg": "list",
      "autocomplete": "List Toggl Time Entries 2",
    }

  ]
}
EOF
