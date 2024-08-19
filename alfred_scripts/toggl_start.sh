#!/usr/bin/env bash

if [ -z "$TOGGL_API_TOKEN" ]; then
	echo "{\"error\":\"No API token present\"}"
	exit 1
fi

if [ -z "$TOGGL_WORKSPACE_ID" ]; then
	echo "{\"error\":\"No workspace ID present\"}"
	exit 1
fi

query=$1
if [ -z "$query" ]; then
	echo "{\"error\":\"No query provided\"}"
	exit 1
fi

# Check if the query is a valid JSON
data=$(echo "$query" | jq -r . 2>/dev/null)
if [ $? -ne 0 ]; then
	# If not valid JSON, assume it's a bare JIRA issue ID
	issueId=$query
	url="$JIRA_URL/browse/$issueId"
	title="$issueId - LOUIS INTERNET | Jira"
else
	# If valid JSON, extract data
	url=$(echo "$data" | jq -r .url)
	title=$(echo "$data" | jq -r .title)
	issueId=$(echo "$url" | sed -n 's#.*/browse/\([A-Z][A-Z]*-[0-9][0-9]*\).*#\1#p')
fi

if [[ -z "$url" ]] || [[ -z "$title" ]] || [[ -z "$issueId" ]]; then
	echo "{\"error\":\"Invalid input data\"}"
	exit 1
fi

# Remove the "- LOUIS INTERNET | Jira" suffix from the title if it exists
issueTitle=$(echo "$title" | sed -n "s/.*\[$issueId\] \(.*\)/\1/p" | sed 's/ - LOUIS INTERNET | Jira$//')

description="$issueId - $issueTitle"
projectName=$(echo "$issueId" | sed -n 's/\([A-Z][A-Z]*\)-[0-9][0-9]*/\1/p')

getProjectId() {
	local projectName=$1
	local response=$(curl -s -u "$TOGGL_API_TOKEN:api_token" \
		-H "Content-Type: application/json" \
		-X GET "https://api.track.toggl.com/api/v9/workspaces/$TOGGL_WORKSPACE_ID/projects")

	echo "$response" | jq -r --arg projectName "$projectName" '.[] | select(.name == $projectName) | .id'
}

createProject() {
	local projectName=$1
	local response=$(curl -s -u "$TOGGL_API_TOKEN:api_token" \
		-H "Content-Type: application/json" \
		-d '{
      "name":"'"$projectName"'",
      "active":true,
      "auto_estimates":false,
      "currency":"EUR",
      "estimated_hours":10,
      "is_private":false
    }' \
		-X POST "https://api.track.toggl.com/api/v9/workspaces/$TOGGL_WORKSPACE_ID/projects")

	echo "$response" | jq -r '.id'
}

startTogglTimeEntry() {
	local description=$1
	local projectId=$2
	local start_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
	local response=$(curl -s -w "\n%{http_code}" -X POST \
		-u "$TOGGL_API_TOKEN:api_token" \
		-H "Content-Type: application/json" \
		-d '{
      "description":"'"$description"'",
      "start":"'"$start_time"'",
      "created_with":"Alfred",
      "workspace_id":'"$TOGGL_WORKSPACE_ID"',
      "pid":'"$projectId"',
      "stop":null,
      "duration":-1
    }' \
		"https://api.track.toggl.com/api/v9/workspaces/$TOGGL_WORKSPACE_ID/time_entries")

	local http_body=$(echo "$response" | sed '$d')
	local http_code=$(echo "$response" | tail -n1)

	if [ "$http_code" -ne 200 ]; then
		echo "{\"error\":\"Failed to start Toggl time entry. HTTP Status Code: $http_code\", \"response\":\"$http_body\"}"
		exit 1
	fi

	echo "$http_body"
}

projectId=$(getProjectId "$projectName")

if [ -z "$projectId" ]; then
	projectId=$(createProject "$projectName")
	if [ -z "$projectId" ]; then
		echo "{\"error\":\"Failed to create project\"}"
		exit 1
	fi
fi

response=$(startTogglTimeEntry "$description" "$projectId")
if [ -z "$response" ]; then
	echo "Error starting Toggl time entry"
	exit 1
fi

echo "Toggl time entry started"
