## Jira Response Pattern

**For quick responses to existing Jira tickets (not comprehensive feature estimation)**

### Structure Requirements

1. **Dual-audience format** - PM section first, technical details below with `---` separator
2. **Time estimates in hours** (not days) for development work
3. **Team language** - Match team's working language (German for German teams, etc.)
4. **NEVER post directly** - Always draft first and ask user for approval

### Contextual Information to Include

- **Frontend URLs** - Link to relevant pages when discussing user-facing features
- **Database Context** - Current database from `config/localconf_local.php` (for TYPO3 projects)
- **Git Branch** - Current branch when code changes are involved (skip for raw estimates on master/main)
- **Environment Details** - Dev/staging/live context when deployment relevant
- **Key File Paths** - Implementation files for future developer context

### Process

1. Analyze the issue and codebase thoroughly
2. Create response draft with both PM and technical sections
3. Present draft to user with "Should I post this to Jira?"
4. Only post after explicit user approval

### German Response Template

```markdown
**@User** - [Analysis summary]

**Schätzung: X Stunden**
[German business summary and breakdown]

**Für die Umsetzung:**
- [Task 1]: (X-Y Stunden)
- [Task 2]: (X-Y Stunden)
- [Task 3]: (X-Y Stunden)
- [Task 4]: (X-Y Stunden)

**Context:**
- Frontend: [URL if relevant]
- Database: [DB name if relevant]
- Branch: [branch if changes involved]
- Environment: [dev/staging/live if relevant]

---

**Technische Details für die Implementierung:**

**Betroffene Dateien:**
- [File path 1]
- [File path 2]

**Bestehende Struktur:**
- [System 1]: [Path and description]
- [System 2]: [Path and description]
- [Key info]: `'storage-key'` or similar

**Implementierung:**
1. [Technical step 1 with specific details]
2. [Technical step 2 with specific details]
3. [Technical step 3 with specific details]
4. [Technical step 4 with specific details]

**Relevante Code-Stellen:**
- `file.js:82-90` - [description of code section]
- `file.js:87-88` - [description of specific lines]
- `other.js:52-70` - [description of method/function]
- `form.js:110-114` - [description of integration point]

Die Lösung nutzt die komplette bestehende Infrastruktur und erweitert sie nur um die [specific functionality].
```

### English Response Template

```markdown
**@User** - [Analysis summary]

**Estimate: X hours**
[English business summary and breakdown]

**Implementation tasks:**
- [Task 1]: (X-Y hours)
- [Task 2]: (X-Y hours)
- [Task 3]: (X-Y hours)
- [Task 4]: (X-Y hours)

**Context:**
- Frontend: [URL if relevant]
- Database: [DB name if relevant]
- Branch: [branch if changes involved]
- Environment: [dev/staging/live if relevant]

---

**Technical Implementation Details:**

**Affected Files:**
- [File path 1]
- [File path 2]

**Existing Architecture:**
- [System 1]: [Path and description]
- [System 2]: [Path and description]
- [Key info]: `'storage-key'` or similar

**Implementation Steps:**
1. [Technical step 1 with specific details]
2. [Technical step 2 with specific details]
3. [Technical step 3 with specific details]
4. [Technical step 4 with specific details]

**Relevant Code Sections:**
- `file.js:82-90` - [description of code section]
- `file.js:87-88` - [description of specific lines]
- `other.js:52-70` - [description of method/function]
- `form.js:110-114` - [description of integration point]

The solution leverages the complete existing infrastructure and extends it only with [specific functionality].
```

### Key Principles

- **Future developer context** - Include enough technical detail to implement without current conversation context
- **Professional tone** - Business-focused for PM section, technical accuracy for developer section
- **Time granularity** - Hours for development estimates, not days
- **Quality control** - Always draft first, never post without explicit approval
- **Language matching** - Use the team's working language consistently
- **Context preservation** - Include all relevant project information for implementation

This pattern complements comprehensive feature estimation with quick, actionable responses for existing tickets.