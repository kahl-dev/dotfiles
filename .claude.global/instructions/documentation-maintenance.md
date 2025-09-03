# 📚 Documentation Maintenance

## Core Principle

**Update documentation when changing documented code** - same session, same commit.

## Documentation Types & Audiences

**CLAUDE.md files (AI-optimized)**:
- Technical implementation details
- File paths, function names, exact commands
- Integration architecture and hook flows
- Troubleshooting with specific error patterns
- **Audience**: Claude Code for maintenance and fixes

**docs/*.md files (Human-readable)**:
- Conceptual overviews and workflows
- User guides and installation instructions  
- Feature explanations and use cases
- **Audience**: Developers and users

**Both types must be updated** when code changes affect documented functionality.

## When Documentation Updates Are Required

- Modifying scripts or configuration referenced in ANY documentation
- Changing behavior of documented functions or workflows  
- Adding/removing features that affect documented systems
- Updating file paths, commands, or configuration examples

## Documentation Standards by Type

**CLAUDE.md files**:
- Precise file paths and line references
- Complete technical context for maintenance
- Exact commands that work without modification

**Human documentation**:
- Clear conceptual explanations
- Step-by-step workflows
- Context and rationale for decisions

## Simple Process

1. Before changing code: Check if it's documented in CLAUDE.md OR docs/ files
2. Make the code change
3. Update BOTH types of related documentation to match
4. Test that all documented examples still work

**When in doubt, update both documentation types.**