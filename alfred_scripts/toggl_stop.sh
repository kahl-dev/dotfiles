#!/usr/bin/env bash

if [ -z "$TOGGL_API_TOKEN" ]; then
	echo "{\"error\":\"No API token present\"}"
	exit 1
fi

if [ -z "$TOGGL_WORKSPACE_ID" ]; then
	echo "{\"error\":\"No workspace ID present\"}"
	exit 1
fi

getRunningTimeEntry() {
	local response=$(curl -s -u "$TOGGL_API_TOKEN":api_token \
		-H "Content-Type: application/json" \
		-X GET "https://api.track.toggl.com/api/v9/me/time_entries/current")

	echo "$response" | jq -r '.'
}

stopTogglTimeEntry() {
	local timeEntryId=$1
	local stop_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	local response=$(curl -s -w "\n%{http_code}" -X PUT \
		-u "$TOGGL_API_TOKEN:api_token" \
		-H "Content-Type: application/json" \
		-d '{
      "stop":"'"$stop_time"'"
    }' \
		"https://api.track.toggl.com/api/v9/time_entries/$timeEntryId")

	local http_body=$(echo "$response" | sed '$d')
	local http_code=$(echo "$response" | tail -n1)

	if [ "$http_code" -ne 200 ]; then
		echo "{\"error\":\"Failed to stop Toggl time entry. HTTP Status Code: $http_code\", \"response\":\"$http_body\"}"
		exit 1
	fi

	echo "$http_body"
}

runningEntry=$(getRunningTimeEntry)

if [ -z "$runningEntry" ]; then
	echo "{\"error\":\"No running time entry found\"}"
	exit 1
fi

timeEntryId=$(echo "$runningEntry" | jq -r '.id')

response=$(stopTogglTimeEntry "$timeEntryId")
if [ -z "$response" ]; then
	echo "{\"error\":\"Error stopping Toggl time entry\"}"
	exit 1
fi

echo "Toggl time entry stopped"
