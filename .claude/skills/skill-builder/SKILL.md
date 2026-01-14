---
name: skill-builder
description: >
  Create and update Claude Code skills with proper YAML frontmatter, structure, and organization.
  Use when building new skills, updating existing skills, refactoring skill structure, validating skill format, or learning skill architecture.
  Covers SKILL.md creation, tool restrictions, hooks, context isolation, progressive disclosure, and security best practices.
allowed-tools:
  - Read
  - Write
  - Glob
  - Bash(mkdir:*, chmod:*)
---

# Skill Builder

Create and update properly structured Claude Code skills with correct YAML frontmatter and file organization.

**Use for**:
- Creating new skills from scratch
- Updating existing skills to follow current standards
- Refactoring skill structure and organization
- Validating skill format and best practices

## Skill Structure

### Required Files
- **SKILL.md**: Metadata + instructions (frontmatter + markdown)
- Optional: reference.md, examples.md, scripts/

### Directory Layout
```
.claude/skills/skill-name/       # Project skill
~/.claude/skills/skill-name/     # Personal skill
├── SKILL.md                     # Required
├── reference.md                 # Optional: detailed API docs
├── examples.md                  # Optional: usage examples
└── scripts/                     # Optional: utility scripts
    ├── helper.py
    └── validate.sh
```

## YAML Frontmatter Schema

```yaml
---
name: skill-name                          # Required: lowercase, hyphens, max 64 chars
description: >                            # Required: max 1024 chars, trigger keywords
  What skill does. When to use it.
  Specific capabilities: "Extract, merge, analyze"

# Optional fields:
allowed-tools: Read, Grep, Glob           # Tool restrictions
model: claude-opus-4-5-20251101           # Override model
context: fork                             # Isolate in sub-agent
agent: general-purpose                    # Sub-agent type
user-invocable: true                      # Show in slash menu (default)
disable-model-invocation: false           # Block Skill tool access

hooks:                                    # Lifecycle hooks
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/check.sh $TOOL_INPUT"
          once: true
  PostToolUse: [...]
  Stop: [...]
---
```

## Creating a Skill

### 1. Determine Scope
- **Project**: `.claude/skills/` (team via git)
- **Personal**: `~/.claude/skills/` (cross-project)

### 2. Create Directory
```bash
mkdir -p .claude/skills/skill-name
```

### 3. Write SKILL.md

**Frontmatter Requirements**:
- `name`: lowercase, hyphens only, max 64 chars
- `description`: Include trigger keywords users would say, max 1024 chars
- List specific capabilities: "Extract text, fill forms, merge PDFs"

**Instructions Section**:
- Keep under 500 lines
- Essential info only
- Link to reference.md for detailed docs
- Include quick start examples

### 4. Add Tool Restrictions (Optional)

Limit capabilities for security/focus:
```yaml
allowed-tools:
  - Read
  - Grep
  - Bash(python:*)
```

### 5. Configure Context (Optional)

For complex multi-step operations:
```yaml
context: fork              # Isolate in sub-agent
agent: general-purpose     # Or: Explore, Plan, custom
```

## Updating Existing Skills

Apply the same standards to existing skills to ensure consistency.

### 1. Identify Skills to Update

```bash
# Find all existing skills
find .claude/skills -name "SKILL.md"
find ~/.claude/skills -name "SKILL.md"
```

### 2. Validate Current State

Run validation script on existing skill:
```bash
./scripts/validate-skill.sh .claude/skills/existing-skill
```

Review validation errors and warnings.

### 3. Update Process

**Step-by-step**:

1. **Read existing skill**
   - Understand current functionality
   - Note what works well
   - Identify areas needing updates

2. **Update frontmatter**
   - Verify `name` follows lowercase-hyphen format
   - Enhance `description` with trigger keywords
   - Add `allowed-tools` if missing (for security)
   - Consider `context: fork` for complex workflows
   - Add hooks if validation/security needed

3. **Refactor instructions**
   - Keep SKILL.md under 500 lines
   - Move detailed docs to reference.md
   - Move examples to examples.md
   - Ensure clarity and actionability

4. **Update tool restrictions**
   - Add `allowed-tools` for security
   - Restrict to minimum needed
   - Use patterns like `Bash(python:*)` for specificity

5. **Validate updates**
   - Run validation script
   - Test skill invocation
   - Verify functionality preserved

### 4. Common Update Scenarios

#### Add Missing Frontmatter Fields
```yaml
# Before
---
name: my-skill
description: Does stuff
---

# After
---
name: my-skill
description: >
  Specific description with trigger keywords.
  Lists exact capabilities: analyze, generate, process.
allowed-tools:
  - Read
  - Grep
  - Glob
---
```

#### Improve Description for Triggering
```yaml
# Before (vague, won't trigger reliably)
description: Helps with documents

# After (specific, triggers reliably)
description: >
  Extract text from PDFs, fill forms, merge documents, split pages.
  Use when working with PDF files, form processing, or document extraction.
```

#### Add Tool Restrictions
```yaml
# Before (unrestricted, security risk)
---
name: code-analyzer
description: Analyze code patterns
---

# After (restricted, secure)
---
name: code-analyzer
description: Analyze code patterns, find issues, generate reports
allowed-tools:
  - Read
  - Grep
  - Glob
---
```

#### Add Context Isolation
```yaml
# Before (clutters main conversation)
---
name: complex-workflow
description: Multi-step data processing
---

# After (isolated, clean)
---
name: complex-workflow
description: Multi-step data processing with analysis and reports
context: fork
agent: general-purpose
---
```

#### Reorganize Content
```yaml
# Before: Single bloated SKILL.md (800 lines)

# After: Organized structure
SKILL.md        - 300 lines (essential instructions)
reference.md    - 400 lines (detailed API docs)
examples.md     - 200 lines (usage examples)
```

#### Add Validation Hooks
```yaml
# Before (no validation)
---
name: deploy-tool
description: Deploy code to servers
---

# After (validated, secure)
---
name: deploy-tool
description: Deploy code to servers with validation
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh $TOOL_INPUT"
          once: true
---
```

### 5. Migration Checklist

When updating existing skills:
- [ ] Read and understand current functionality
- [ ] Run validation script
- [ ] Update name format (lowercase-hyphen)
- [ ] Enhance description with trigger keywords
- [ ] Add tool restrictions for security
- [ ] Consider context isolation if complex
- [ ] Reorganize if over 500 lines
- [ ] Add hooks if validation needed
- [ ] Make scripts executable (`chmod +x`)
- [ ] Test skill invocation
- [ ] Verify functionality preserved
- [ ] Document changes in comments

### 6. Backward Compatibility

When updating skills:
- Preserve existing functionality
- Keep same skill name (unless intentionally renaming)
- Don't break existing workflows
- Test before and after behavior
- Document breaking changes if any

### 7. Update Examples

**Example 1: Basic Skill Enhancement**
```bash
# Original skill
.claude/skills/commit-msg/
└── SKILL.md  (basic format, no restrictions)

# Updated skill
.claude/skills/commit-msg/
├── SKILL.md        (enhanced description, tool restrictions)
└── examples.md     (commit message examples)
```

**Example 2: Complex Skill Refactoring**
```bash
# Original skill
.claude/skills/data-analyzer/
└── SKILL.md  (900 lines, everything in one file)

# Updated skill
.claude/skills/data-analyzer/
├── SKILL.md        (300 lines - core instructions)
├── reference.md    (400 lines - API documentation)
├── examples.md     (200 lines - usage examples)
└── scripts/
    └── validate.sh (data validation script)
```

## Best Practices

### Description Quality
- Include trigger keywords: "git commit", "PDF processing", "code analysis"
- Answer: What does it do? When should Claude use it?
- Vague descriptions won't trigger: avoid "Helps with documents"
- Differentiate similar skills with specific terms

### Progressive Disclosure
- SKILL.md: Essential quick-start info
- reference.md: Detailed API documentation
- examples.md: Usage examples
- scripts/: Utility scripts (not loaded into context)

### Tool Restrictions
- Read-only skills: `allowed-tools: Read, Grep, Glob`
- Python-only: `allowed-tools: Bash(python:*)`
- Security-sensitive: Restrict Bash access

### Context Isolation
- Use `context: fork` for complex workflows
- Prevents clutter in main conversation
- Runs in separate sub-agent with own history
- Specify agent type if needed

### Hook Patterns
- **PreToolUse**: Security checks before execution
- **PostToolUse**: Validation after completion
- **Stop**: Cleanup operations
- Use `once: true` for one-time checks

### File Organization
- One-level references from SKILL.md (avoid chains)
- Forward slashes: `scripts/helper.py`
- Scripts need execute permissions: `chmod +x`
- Case-sensitive: must be `SKILL.md`

### Dependencies
- List required packages in description
- Example: "Requires pypdf and pdfplumber packages"
- Must be pre-installed in environment

### Visibility Control
- `user-invocable: false`: Hidden from menu, Claude can use
- `disable-model-invocation: true`: Users only, Claude cannot
- Default: Visible everywhere

## Quick Start Templates

### Basic Skill
```yaml
---
name: my-skill
description: Short description with trigger keywords
---

# My Skill

## Instructions
1. Step one
2. Step two

## Example
\`\`\`bash
command example
\`\`\`
```

### Read-Only Skill
```yaml
---
name: code-analyzer
description: Analyze code patterns, find issues, generate reports
allowed-tools:
  - Read
  - Grep
  - Glob
---
```

### Isolated Complex Skill
```yaml
---
name: data-processor
description: Process datasets, clean data, generate statistics
context: fork
agent: general-purpose
allowed-tools:
  - Read
  - Write
  - Bash(python:*)
---
```

### Skill with Hooks
```yaml
---
name: secure-deploy
description: Deploy code with security checks and validation
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh $TOOL_INPUT"
          once: true
  Stop:
    - type: command
      command: "./scripts/cleanup.sh"
---
```

## Validation Checklist

**Apply to both NEW and UPDATED skills before completing**:

- [ ] SKILL.md exists with proper frontmatter
- [ ] Name is lowercase with hyphens only
- [ ] Description includes trigger keywords
- [ ] Description under 1024 characters
- [ ] Description mentions "update" or "refactor" if skill handles updates
- [ ] Instructions are clear and actionable
- [ ] Tool restrictions appropriate for security (add if missing)
- [ ] Supporting files linked (if used)
- [ ] Scripts have execute permissions
- [ ] Dependencies listed in description
- [ ] Context isolation considered for complex workflows
- [ ] Hooks added if validation/security needed
- [ ] SKILL.md under 500 lines (refactor if needed)
- [ ] Backward compatibility maintained (for updates)
- [ ] Validation script passes

## Common Patterns

### Capability-Specific Skills
Focus on specific tasks: commit messages, PDF processing, code review

### Tool-Restricted Skills
Limit to Read/Grep/Glob for safety, or Bash(python:*) for Python-only

### Forked Context Skills
Complex workflows that need isolation from main conversation

### Hook-Based Skills
Security checks, validation, cleanup operations

## Skill Lifecycle

1. **Discovery**: Claude loads names + descriptions at startup
2. **Activation**: User request matches description
3. **Confirmation**: Claude asks user to confirm skill usage
4. **Execution**: Full SKILL.md loaded, instructions followed
5. **Cleanup**: Supporting files unloaded, context returned

## Precedence Rules

Same skill name resolution order:
1. Enterprise (admin-deployed) - highest
2. Personal (~/.claude/skills/)
3. Project (.claude/skills/)
4. Plugin (skills/ in plugin root) - lowest

Higher precedence overrides lower.

## Reference Materials

For detailed schemas and advanced patterns, see:
- [REFERENCE.md](REFERENCE.md) - Complete field specifications
- [EXAMPLES.md](EXAMPLES.md) - Real-world skill implementations
