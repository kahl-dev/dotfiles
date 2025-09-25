# Claude Code Agent Architecture Philosophy

## Core Principle: Agents Research, Claude Acts

**Agents are researchers and analysts, not implementers.** They gather information, analyze patterns, and provide recommendations. The main Claude thread maintains context and performs all actions.

## Why This Architecture

1. **Context Preservation**: Main thread sees all reasoning and decisions
2. **Visibility**: Every change is deliberate and reviewable  
3. **Learning**: Main thread accumulates knowledge from agent research
4. **Control**: No surprising side effects from autonomous agents
5. **Debugging**: Clear audit trail of what was done and why

## Agent Patterns

### ✅ Correct Pattern: Research & Report
```
Main Claude: "I need to fix this authentication bug"
    └→ @agent: Investigates thoroughly
        └→ Returns: Comprehensive analysis with findings
    └→ Main Claude: Implements with full context
```

### ❌ Anti-Pattern: Autonomous Action  
```
Main Claude: "Fix this bug"
    └→ @agent: Makes changes independently
        └→ Returns: "Done!" (but what was done?)
    └→ Main Claude: Lost context and control
```

## Agent Guidelines

**Agents Should:**
- Analyze and investigate thoroughly
- Return comprehensive findings
- Provide multiple solution options
- Include trade-offs and recommendations
- Preserve all discovered context

**Agents Should NOT:**
- Modify files independently
- Make decisions without visibility
- Hide reasoning from main thread
- Perform actions that affect state
- Work without returning full context

## Context-Preserving Orchestration

### Orchestration Principle

**Orchestration coordinates research, not work distribution.** Multiple agents gather different perspectives, but implementation remains in the main thread with full visibility.

### Orchestration Patterns

#### 1. Parallel Research Pattern
```markdown
For complex analysis:
1. Multiple agents research simultaneously:
   - @security-analyst: Security implications
   - @performance: Performance impact  
   - @architect: Design considerations
2. Main thread synthesizes all findings
3. Main thread implements informed solution
4. Agents validate (research) the implementation
```

#### 2. Progressive Analysis Pattern
```markdown
For increasing complexity:
1. @reviewer: Initial assessment
2. If complex → @architect: Deep analysis
3. If security-relevant → @security: Threat modeling
4. Main thread implements with accumulated context
```

#### 3. Validation Orchestra Pattern
```markdown
After implementation:
1. Main thread completes changes
2. Parallel validation:
   - @reviewer: Verify correctness
   - @security: Check vulnerabilities
   - @performance: Measure impact
3. All return findings (not fixes)
4. Main thread adjusts based on research
```

### Orchestration Anti-Patterns to Avoid

❌ **Work Distribution**: Splitting implementation across agents
❌ **Hidden Changes**: Agents modifying without visibility
❌ **Context Fragmentation**: Each agent having partial view
❌ **Blind Automation**: Trusting agents to "handle it"

## Progressive Thinking Modes

### When to Think Deeper

Use thinking modes to improve analysis quality without adding complexity:

#### Thinking Hierarchy
- **Default**: Routine tasks, simple fixes
- **`think`**: Debugging, exploring options
- **`think hard`**: Architecture decisions, complex trade-offs
- **`think harder`**: Security analysis, system design
- **`ultrathink`**: Critical decisions, paradigm shifts

#### Automatic Triggers

**By Scope:**
- < 5 files: Default thinking
- 5-20 files: `think` about interactions
- 20-50 files: `think hard` about system impact
- > 50 files: `think harder` about architecture

**By Domain:**
- Security changes: Always `think hard` minimum
- Architecture changes: Always `think harder`
- Performance critical: `think hard` about implications
- Data model changes: `think harder` about migrations

**By Risk:**
- Low risk: Default thinking
- Medium risk: `think` through implications
- High risk: `think hard` about all aspects
- Critical: `ultrathink` with maximum analysis

### Integration Examples

```markdown
# In commit workflows
"Complex changes detected. Let me think hard about the implications..."

# In review processes  
"Security-sensitive code. I'll think harder about attack vectors..."

# In architecture decisions
"This is a fundamental change. Let me ultrathink the long-term impact..."
```

## Parallel Execution Patterns

### Always Parallelize (Independent Operations)
- `git status` + `git diff` + `git log`
- Multiple file reads for exploration
- Independent agent analyses
- Multiple search operations
- Read-only investigations

### Never Parallelize (Dependent Operations)
- Sequential writes to same file
- Operations requiring order
- Resource-intensive operations
- State-modifying commands
- Build → test → deploy sequences

### Intelligent Parallelization

Let Claude decide based on:
- Task independence
- System load (load protection handles this)
- Expected resource usage
- Error recovery requirements

### Parallel Pattern Examples

```markdown
# Good: Independent research
Parallel:
  - @security: Analyze authentication
  - @performance: Check bottlenecks
  - @architect: Review design

# Bad: Dependent modifications  
Sequential:
  1. Update schema
  2. Generate migrations
  3. Update models
  4. Run tests
```

## Decision Framework

### For Every Complex Task

1. **Research First**: What do we need to know?
2. **Think Appropriately**: How deep should analysis go?
3. **Parallelize Wisely**: What can happen simultaneously?  
4. **Implement Visibly**: All changes in main thread
5. **Validate Thoroughly**: Agents verify without modifying

### Quality Over Speed

- **Visible implementation** > Hidden automation
- **Informed decisions** > Quick actions
- **Context preservation** > Task distribution
- **Research depth** > Execution speed

---

*This philosophy guides all agent development. When working in this directory, these principles are automatically loaded to ensure consistent agent architecture.*