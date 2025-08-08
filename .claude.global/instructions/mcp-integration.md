## MCP Integration

**Context7 (Documentation) - FIRST PRIORITY:**

- Always check before implementing: `mcp__context7__resolve-library-id`
- Get latest docs: `mcp__context7__get-library-docs`
- Use before adding dependencies or implementing library features
- MUST check Context7 for up-to-date documentation when working with 3rd party libraries, packages, frameworks

**GitHub/GitLab - CODE DISCOVERY:**

- Search implementations: `mcp__github__search_repositories`
- Read examples: `mcp__github__get_file_contents`
- Manage issues/PRs: `mcp__github__create_issue` / `mcp__gitlab__create_issue`

**Playwright - BROWSER AUTOMATION:**

- Always `mcp__playwright__browser_snapshot` before actions
- Navigate: `mcp__playwright__browser_navigate`
- Interact: click/type/select_option with element descriptions
- Debug: `mcp__playwright__browser_console_messages`
- MUST use Playwright MCP server when making visual changes to front-end to check your work

**Figma - DESIGN INTEGRATION:**

- Fetch designs: `mcp__figma__get_figma_data` with fileKey from URLs
- Download assets: `mcp__figma__download_figma_images` to project directories
- Extract component data for implementation

**Cloudinary - ASSET MANAGEMENT:**

- Upload: `mcp__cloudinary-asset-mgmt__upload-asset` from local files
- Manage: search/list/update assets with structured metadata
- Generate archives and download links as needed

