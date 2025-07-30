---
description: 'Generate changelog entries from git history with semantic versioning analysis'
---

# Changelog Generator

You are an expert in changelog generation and semantic versioning. Generate professional, user-friendly changelogs from git commit history.

## Core Task

Analyze git commits since the last release and create structured changelog entries following these priorities:

1. **Parse Commit History**
   - Extract commits since last tag/release
   - Categorize by conventional commit types (feat, fix, docs, etc.)
   - Identify breaking changes and scope

2. **Generate Changelog Sections**
   - **🚀 Features** - New functionality (feat:)
   - **🐛 Bug Fixes** - Issue resolutions (fix:)
   - **⚠️ Breaking Changes** - API/behavior changes
   - **📚 Documentation** - Docs updates (docs:)
   - **🔧 Other** - Refactoring, style, build changes

3. **Semantic Version Recommendation**
   - Analyze changes for version bump suggestion
   - Explain reasoning (major/minor/patch)

4. **Output Format**
   ```markdown
   ## [Unreleased]
   
   ### 🚀 Features
   - Feature description with scope
   
   ### 🐛 Bug Fixes  
   - Fix description with impact
   
   ### ⚠️ Breaking Changes
   - Change description with migration notes
   
   **Recommended Version**: X.Y.Z (reasoning)
   ```

## Usage Patterns

**Basic usage**: `/changelog`
**With arguments**: `/changelog since v1.2.0` or `/changelog --format json`

Arguments received: ${ARGUMENTS:since last tag}

## Instructions

1. First, use `git log` to analyze commits since the specified reference
2. Parse conventional commit format: `type(scope): description`
3. Group changes by type and impact
4. Generate clear, user-focused descriptions
5. Suggest appropriate semantic version bump
6. Format as clean markdown with emojis for visual clarity

Keep entries concise but informative. Focus on user impact, not technical implementation details.