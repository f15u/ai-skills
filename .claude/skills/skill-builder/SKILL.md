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

## About Skills

Skills are modular, self-contained packages that extend Claude's capabilities by providing specialized knowledge, workflows, and tools. Think of them as "onboarding guides" for specific domains or tasks—they transform Claude from a general-purpose agent into a specialized agent equipped with procedural knowledge that no model can fully possess.

### What Skills Provide

1. Specialized workflows - Multi-step procedures for specific domains
2. Tool integrations - Instructions for working with specific file formats or APIs
3. Domain expertise - Company-specific knowledge, schemas, business logic
4. Bundled resources - Scripts, references, and assets for complex and repetitive tasks

## Core Principles

### Concise is Key

The context window is a public good. Skills share the context window with everything else Claude needs: system prompt, conversation history, other skills' metadata, and the actual user request.

**Default assumption: Claude is already very smart.** Only add context Claude doesn't already have. Challenge each piece of information: "Does Claude really need this explanation?" and "Does this paragraph justify its token cost?"

Prefer concise examples over verbose explanations.

### Set Appropriate Degrees of Freedom

Match the level of specificity to the task's fragility and variability:

**High freedom (text-based instructions)**: Use when multiple approaches are valid, decisions depend on context, or heuristics guide the approach.

**Medium freedom (pseudocode or scripts with parameters)**: Use when a preferred pattern exists, some variation is acceptable, or configuration affects behavior.

**Low freedom (specific scripts, few parameters)**: Use when operations are fragile and error-prone, consistency is critical, or a specific sequence must be followed.

Think of Claude as exploring a path: a narrow bridge with cliffs needs specific guardrails (low freedom), while an open field allows many routes (high freedom).

## Skill Structure

Every skill consists of a required SKILL.md file and optional bundled resources:

```
.claude/skills/skill-name/       # Project skill
~/.claude/skills/skill-name/     # Personal skill
├── SKILL.md                     # Required: metadata + instructions
├── reference.md                 # Optional: detailed API docs
├── examples.md                  # Optional: usage examples
├── scripts/                     # Optional: executable code
│   ├── helper.py
│   └── validate.sh
├── references/                  # Optional: additional documentation files
│   ├── api_docs.md
│   └── schemas.md
└── assets/                      # Optional: files used in output
    ├── template.html
    └── logo.png
```

### SKILL.md (Required)

Every SKILL.md consists of:

- **Frontmatter** (YAML): Contains `name` and `description` fields. These are the only fields Claude reads to determine when the skill gets used, thus it is critical to be clear and comprehensive.
- **Body** (Markdown): Instructions and guidance for using the skill. Only loaded AFTER the skill triggers.

### Bundled Resources (Optional)

#### reference.md and examples.md

Single-file references for common patterns:

- **reference.md**: Detailed API documentation, field specifications, advanced patterns
- **examples.md**: Real-world skill implementations, usage examples

These are Anthropic's recommended conventions for simple skills with moderate documentation needs.

#### Scripts (`scripts/`)

Executable code (Python/Bash/etc.) for tasks that require deterministic reliability or are repeatedly rewritten.

- **When to include**: When the same code is being rewritten repeatedly or deterministic reliability is needed
- **Example**: `scripts/rotate_pdf.py` for PDF rotation tasks
- **Benefits**: Token efficient, deterministic, may be executed without loading into context
- **Note**: Scripts may still need to be read by Claude for patching or environment-specific adjustments

#### References Directory (`references/`)

For skills requiring multiple documentation files, use a references/ directory to organize domain-specific documentation.

- **When to include**: For complex skills with multiple areas of documentation that Claude should reference while working
- **Examples**: `references/finance.md` for financial schemas, `references/api_docs.md` for API specifications
- **Use cases**: Database schemas, API documentation, domain knowledge, company policies, detailed workflow guides
- **Benefits**: Keeps SKILL.md lean, loaded only when Claude determines it's needed
- **Best practice**: If files are large (>10k words), include grep search patterns in SKILL.md
- **Avoid duplication**: Information should live in either SKILL.md or references files, not both. Prefer references files for detailed information unless it's truly core to the skill

#### Assets (`assets/`)

Files not intended to be loaded into context, but rather used within the output Claude produces.

- **When to include**: When the skill needs files that will be used in the final output
- **Examples**: `assets/logo.png` for brand assets, `assets/slides.pptx` for PowerPoint templates, `assets/frontend-template/` for HTML/React boilerplate
- **Use cases**: Templates, images, icons, boilerplate code, fonts, sample documents that get copied or modified
- **Benefits**: Separates output resources from documentation, enables Claude to use files without loading them into context

### What NOT to Include

A skill should only contain essential files that directly support its functionality. Do NOT create extraneous documentation or auxiliary files, including:

- README.md
- INSTALLATION_GUIDE.md
- QUICK_REFERENCE.md
- CHANGELOG.md
- etc.

The skill should only contain the information needed for an AI agent to do the job at hand. It should not contain auxiliary context about the process that went into creating it, setup and testing procedures, user-facing documentation, etc. Creating additional documentation files just adds clutter and confusion.

### Progressive Disclosure Design Principle

Skills use a three-level loading system to manage context efficiently:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words, ideally <500 lines)
3. **Bundled resources** - As needed by Claude (unlimited because scripts can be executed without reading into context window)

Keep SKILL.md body to the essentials and under 500 lines to minimize context bloat. Split content into separate files when approaching this limit. When splitting out content into other files, reference them from SKILL.md and describe clearly when to read them.

**Key principle:** When a skill supports multiple variations, frameworks, or options, keep only the core workflow and selection guidance in SKILL.md. Move variant-specific details (patterns, examples, configuration) into separate reference files.

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

### The Five-Step Skill Creation Process

Follow these steps in order to create an effective skill:

1. Gather concrete examples of how the skill will be used
2. Plan the reusable skill contents (scripts, references, assets)
3. Initialize a new skill directory
4. Edit and refine the skill
5. Iterate based on real usage

Follow these steps in order, skipping only if there is a clear reason why they are not applicable.

### Step 1: Understanding the Skill with Concrete Examples

Skip this step only when the skill's usage patterns are already clearly understood.

To create an effective skill, clearly understand concrete examples of how the skill will be used. This understanding can come from either direct user examples or generated examples that are validated with user feedback.

For example, when building an image-editor skill, relevant questions include:

- "What functionality should the image-editor skill support? Editing, rotating, anything else?"
- "Can you give some examples of how this skill would be used?"
- "I can imagine users asking for things like 'Remove the red-eye from this image' or 'Rotate this image'. Are there other ways you imagine this skill being used?"
- "What would a user say that should trigger this skill?"

Avoid asking too many questions in a single message. Start with the most important questions and follow up as needed.

Conclude this step when there is a clear sense of the functionality the skill should support.

### Step 2: Planning the Reusable Skill Contents

Analyze each concrete example by:

1. Considering how to execute on the example from scratch
2. Identifying what scripts, references, and assets would be helpful when executing these workflows repeatedly

**Example:** When building a `pdf-editor` skill to handle queries like "Help me rotate this PDF," the analysis shows:
1. Rotating a PDF requires re-writing the same code each time
2. A `scripts/rotate_pdf.py` script would be helpful to store in the skill

**Example:** When designing a `frontend-webapp-builder` skill for queries like "Build me a todo app," the analysis shows:
1. Writing a frontend webapp requires the same boilerplate HTML/React each time
2. An `assets/hello-world/` template containing the boilerplate project files would be helpful

**Example:** When building a `big-query` skill to handle queries like "How many users have logged in today?" the analysis shows:
1. Querying BigQuery requires re-discovering the table schemas each time
2. A `references/schema.md` file documenting the table schemas would be helpful

### Step 3: Initialize the Skill Directory

**Determine Scope:**
- **Project**: `.claude/skills/` (team via git)
- **Personal**: `~/.claude/skills/` (cross-project)

**Option A: Use init script (recommended if available):**
```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

The script creates the skill directory, generates SKILL.md template with proper frontmatter, and creates example resource directories.

**Option B: Manual creation:**
```bash
mkdir -p .claude/skills/skill-name
```

### Step 4: Edit the Skill

When editing the skill, remember that the skill is being created for another instance of Claude to use. Include information that would be beneficial and non-obvious to Claude.

#### Learn Proven Design Patterns

Consult these helpful guides based on your skill's needs:

- **Multi-step processes**: See references/workflows.md for sequential workflows and conditional logic
- **Specific output formats or quality standards**: See references/output-patterns.md for template and example patterns

#### Start with Reusable Skill Contents

Begin implementation with the reusable resources identified above: `scripts/`, `references/`, and `assets/` files. Note that this step may require user input.

Added scripts must be tested by actually running them to ensure there are no bugs and that the output matches what is expected.

Delete any example files and directories not needed for the skill.

#### Update SKILL.md

**Writing Guidelines:** Always use imperative/infinitive form.

##### Frontmatter

Write the YAML frontmatter with `name` and `description`:

- `name`: The skill name (lowercase, hyphens, max 64 chars)
- `description`: This is the primary triggering mechanism for your skill
  - Include both what the skill does and specific triggers/contexts for when to use it
  - Include all "when to use" information here - NOT in the body. The body is only loaded after triggering
  - List specific capabilities: "Extract text, fill forms, merge PDFs"
  - Example: "Comprehensive document creation, editing, and analysis with support for tracked changes, comments, formatting preservation, and text extraction. Use when Claude needs to work with professional documents (.docx files) for: (1) Creating new documents, (2) Modifying or editing content, (3) Working with tracked changes, (4) Adding comments, or any other document tasks"

Do not include any other fields in YAML frontmatter unless needed (see YAML Frontmatter Schema section).

##### Body

Write instructions for using the skill and its bundled resources.

- Keep under 500 lines
- Essential info only
- Link to reference.md or references/ for detailed docs
- Include quick start examples

#### Optional: Add Tool Restrictions

Limit capabilities for security/focus:
```yaml
allowed-tools:
  - Read
  - Grep
  - Bash(python:*)
```

#### Optional: Configure Context

For complex multi-step operations:
```yaml
context: fork              # Isolate in sub-agent
agent: general-purpose     # Or: Explore, Plan, custom
```

### Step 5: Iterate

After testing the skill, users may request improvements. Often this happens right after using the skill, with fresh context of how the skill performed.

**Iteration workflow:**
1. Use the skill on real tasks
2. Notice struggles or inefficiencies
3. Identify how SKILL.md or bundled resources should be updated
4. Implement changes and test again

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
