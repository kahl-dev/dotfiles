#!/usr/bin/env bash

log_file="$(dirname "$0")/script.log"

log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >>"$log_file"
}

if [ -z "$TOGGL_API_TOKEN" ]; then
  log "No API token present"
  echo "{\"error\":\"No API token present\"}"
  exit 1
fi

if [ -z "$TOGGL_WORKSPACE_ID" ]; then
  log "No workspace ID present"
  echo "{\"error\":\"No workspace ID present\"}"
  exit 1
fi

query=$1
if [ -z "$query" ]; then
  log "No query provided"
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
  log "Query is not valid JSON. Assuming JIRA issue ID: $issueId"
else
  # If valid JSON, extract data
  url=$(echo "$data" | jq -r .url)
  title=$(echo "$data" | jq -r .title)
  issueId=$(echo "$url" | sed -n 's#.*/browse/\([A-Z][A-Z]*-[0-9][0-9]*\).*#\1#p')
  log "Query is valid JSON. Extracted URL: $url, Title: $title, Issue ID: $issueId"
fi

if [[ -z "$url" ]] || [[ -z "$title" ]] || [[ -z "$issueId" ]]; then
  log "Invalid input data. URL: $url, Title: $title, Issue ID: $issueId"
  echo "{\"error\":\"Invalid input data\"}"
  exit 1
fi

# Remove the "- LOUIS INTERNET | Jira" suffix from the title if it exists
issueTitle=$(echo "$title" | sed -n "s/.*\[$issueId\] \(.*\)/\1/p" | sed 's/ - LOUIS INTERNET | Jira$//')
log "Formatted issue title: $issueTitle"

description="$issueId - $issueTitle"
projectName=$(echo "$issueId" | sed -n 's/\([A-Z][A-Z]*\)-[0-9][0-9]*/\1/p')
log "Extracted project name: $projectName"

getProjectId() {
  local projectName=$1
  log "Fetching project ID for project: $projectName"
  local response=$(curl -s -u "$TOGGL_API_TOKEN:api_token" \
    -H "Content-Type: application/json" \
    -X GET "https://api.track.toggl.com/api/v9/workspaces/$TOGGL_WORKSPACE_ID/projects")

  echo "$response" | jq -r --arg projectName "$projectName" '.[] | select(.name == $projectName) | .id'
}

createProject() {
  local projectName=$1
  log "Creating project: $projectName"
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
  log "Starting Toggl time entry. Description: $description, Project ID: $projectId"

  # Escape special characters in the description
  local escaped_description=$(echo "$description" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\//\\\//g')

  local start_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local response=$(curl -s -w "\n%{http_code}" -X POST \
    -u "$TOGGL_API_TOKEN:api_token" \
    -H "Content-Type: application/json" \
    -d '{
      "description":"'"$escaped_description"'",
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
    log "Failed to start Toggl time entry. HTTP Status Code: $http_code, Response: $http_body"
    echo "{\"error\":\"Failed to start Toggl time entry. HTTP Status Code: $http_code\", \"response\":\"$http_body\"}"
    exit 1
  fi

  log "Toggl time entry started successfully"
  echo "$http_body"
}

projectId=$(getProjectId "$projectName")

if [ -z "$projectId" ]; then
  projectId=$(createProject "$projectName")
  if [ -z "$projectId" ]; then
    log "Failed to create project: $projectName"
    echo "{\"error\":\"Failed to create project\"}"
    exit 1
  fi
fi

response=$(startTogglTimeEntry "$description" "$projectId")
if [ -z "$response" ]; then
  log "Error starting Toggl time entry"
  echo "Error starting Toggl time entry"
  exit 1
fi

log "Toggl time entry started"
echo "Toggl time entry started"
