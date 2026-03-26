# project-init: File Templates
> Version: 3.0

> Read this file during Phase 5 and Phase 6 of project-init. Do NOT read it during other phases.

---

## CLAUDE.md Template

```markdown
# {Project Name}

{One-line description}
**Type**: {type} | **Size**: {size}

## Core Rules (ALWAYS follow -- no exceptions)

1. **Change propagation**: When ANY requirement, permission, behavior, or business rule changes, BEFORE implementing: search all files in `.claude/kb/` and `.claude/` for mentions of the old behavior. Update reference files FIRST, then implement changes.
2. **No assumptions**: If a requirement, behavior, or user intent is ambiguous, ASK before proceeding.
3. **File placement**: Place generated assets in `assets/[type]/`. Create subfolder if needed.
4. **Session start**: Read `.claude/status.md` first (if it exists). It contains current state and what to do next.
5. **Session end / before compacting**: Update `.claude/status.md` (if it exists) with: current task state, what was done, what's next, any blockers. Update `.claude/tasks.md` if task statuses changed. If new files, modules, or directories were created, update `.claude/filemap.md`. Update "Last updated" dates on any `.claude/` files you modified this session.
6. **Context budget**: If you're reading more than 5 reference files for a single task, STOP and reconsider. Check `.claude/filemap.md` to find only the relevant file(s).
7. **Self-audit trigger**: If CLAUDE.md exceeds 80 lines or any `.claude/` reference file exceeds 150 lines, flag it to the user and suggest splitting/restructuring.

## Navigation Map

Read these files ONLY when their trigger condition applies:

| File | Read When | Purpose |
|------|-----------|---------|
| `.claude/filemap.md` | Unsure where something is, or creating new files | Project file and directory map |

{Include only rows below for files that were actually created in this project. Remove rows for files that don't exist:}
| `.claude/status.md` | Every session start, before compacting | Current state and continuity |
| `.claude/tasks.md` | Starting a task, completing a task, planning | Task tracking |
| `.claude/architecture.md` | Making design decisions, adding components | System design |
| `.claude/notes.md` | status.md references a prior decision or discovery | Session log |
| `.claude/credentials.md` | Need to access an external service | Service access info |
| `.claude/focus.md` | Starting any task (if file exists) | Current sprint scope and constraints |
| `.claude/kb/[topic].md` | Working on related topic | Domain knowledge |

## Tech Stack & Tools
{List from discovery -- for code projects: languages, frameworks, databases; for non-code projects: platforms, formats, key tools. If this section + Conventions pushes CLAUDE.md past 80 lines, move both to .claude/architecture.md and replace with: "See .claude/architecture.md"}

## Integrations & Access
{List what Claude has direct access to: GitHub, SSH, APIs, MCP connectors, etc.}

## Conventions
{For code: commit messages, branch naming, code style. For all: naming conventions, file organization, language preferences, review/approval process.}
```

---

## status.md Template

> **When to create**: Medium+ projects, multi-session work, or team projects. For small solo projects, Claude's built-in Auto Memory and `--continue`/`--resume` flags handle session continuity -- status.md is optional. When created, treat it as a human-readable handoff document, not the primary continuity mechanism.

```markdown
# Project Status
> Last updated: {date}
> Last audit: never
> Note: This file is a human-readable handoff doc. Claude's Auto Memory handles most session continuity automatically.

## Current State
- **Phase**: {Initialization / Active Work / Maintenance / etc.}
- **Active Task**: None yet
- **Blockers**: None

## Handoff Notes
{What a new session (human or Claude) should know. Updated at end of every session.}

## Recent Changes
- {date}: Project initialized with project-init skill
```

---

## filemap.md Template

```markdown
# Project File Map
> Last updated: {date}
> Update this file whenever creating, moving, or deleting .claude/ reference files or top-level project directories.
> Scope: .claude/ reference files + top-level project directories only.
> Excludes infrastructure files: `.init-manifest`, `settings.json`, and `skills/` are not tracked here.

## Reference Files (.claude/)
> Read triggers for each file are defined in CLAUDE.md's Navigation Map (the authoritative source).
| File | Purpose |
|------|---------|
{Generate from created files}

## Project Directories
| Path | Purpose |
|------|---------|
{Generate from existing top-level dirs or note planned structure}

## Assets
| Path | Purpose |
|------|---------|
{Generate or note "No assets yet"}
```

---

## tasks.md Template

```markdown
# Task Tracker
> Last updated: {date}
> Update after completing any task or subtask.

## Active
{None yet, or seed from discovery goals}

## Backlog
{Seed from discovery if goals/milestones were shared}

## Completed
{Empty}
```

---

## architecture.md Template (when created)

```markdown
# Architecture
> Last updated: {date}
> Update this file when adding components, changing tech stack, or making structural decisions.

## Overview
{High-level description of components/areas and how they connect}

## Tech Stack & Tools
{For code: languages, frameworks, databases, services. For non-code: platforms, formats, key tools.}

## Component Map
| Component | Path | Purpose |
|-----------|------|---------|
{For code: list major modules, services, APIs. For non-code: list content areas, data sources, workflow stages.}

## Conventions
{For code: commit messages, branch naming, code style. For all: naming, organization, language preferences.}

## Key Decisions
{Record significant structural decisions with date and rationale}
```

---

## credentials.md Template (when created)

```markdown
# Service Credentials & Access
> Last updated: {date}
> ⚠️ This file contains REFERENCES to credentials, not the credentials themselves.
> Never put API keys, passwords, or tokens in this file.

## Services
| Service | Auth Method | How to Access | Status |
|---------|------------|---------------|--------|
{e.g., "Zoho CRM | OAuth via MCP | MCP connector configured | ✅ Active"}
{e.g., "AWS | IAM keys | Configured in ~/.aws/credentials | ✅ Active"}
{e.g., "GitHub | SSH key + CLI | gh auth configured | ✅ Active"}

## API Endpoints (when project uses direct REST APIs)
| Service | Endpoint | Auth | Example |
|---------|----------|------|---------|
{e.g., "Google Postmaster Tools | https://gmailpostmastertools.googleapis.com/v1/ | OAuth2 | curl -H 'Auth: Bearer TOKEN' URL/domains"}
{e.g., "MXToolbox | https://mxtoolbox.com/api/v1/ | API key header | curl -H 'Authorization: TOKEN' URL/lookup"}
```

---

## notes.md Template (when created)

```markdown
# Session Notes
> Last updated: {date}
> Append-only log. Add findings, decisions, and discoveries here. Do not edit or delete previous entries -- if a note is wrong, append a correction.
> Read when: status.md references a prior decision or discovery.

## {date} -- Initialization
- Project initialized with project-init skill
- {Any notable decisions or context from the discovery interview}
```

---

## focus.md Template (when created)

```markdown
# Current Focus
> Last updated: {date}
> Scope: {current sprint, task batch, or feature area}
> Expires: {expected end date or "until next sprint"}

## Active Work
{What Claude should focus on this sprint. Be specific about files, components, and goals.}

## Out of Scope (for now)
{What to explicitly NOT work on, even if related. Prevents scope creep.}

## Key Context
{Anything from other reference files that's critical for this sprint -- summarized here so Claude doesn't need to read the originals.}
```

---

## workflows.md Template (when created)

```markdown
# Workflows
> Last updated: {date}

## {Workflow Name, e.g., "Deploy to Production"}
### Prerequisites
{What must be true before running this workflow}

### Steps
1. {Step 1}
2. {Step 2}
3. ...

### Rollback
{What to do if something goes wrong}
```

---

## .claude/rules/coding.md Template (code projects with conventions)

```markdown
---
paths: ["{src-glob}", "{lib-glob}"]
---
# Coding Conventions

{Populate from discovery interview. Use imperative, positive phrasing.}
{Examples -- adapt to actual project stack:}

## Style
- Use named exports exclusively
- Use early returns to reduce nesting
- Keep functions under 50 lines; extract helpers when exceeding

## Naming
- Variables and functions: camelCase
- Classes and types: PascalCase
- Constants: UPPER_SNAKE_CASE
- Files: kebab-case

## Error Handling
- Wrap external calls in try/catch with specific error types
- Log errors with context (function name, input params)
- Return meaningful error messages to callers
```

> **Note on `paths:`**: Adapt the glob patterns to the project's actual source layout. Common patterns: `["src/**"]`, `["src/**", "lib/**"]`, `["app/**", "components/**"]`. For monorepos, scope to the relevant package: `["packages/api/src/**"]`.

---

## .claude/rules/testing.md Template (code projects with testing conventions)

```markdown
---
paths: ["{test-glob}"]
---
# Testing Conventions

{Populate from discovery interview. Use imperative, positive phrasing.}
{Examples -- adapt to actual project stack:}

## Structure
- One test file per source module, mirroring the source directory layout
- Use descriptive test names: "should [expected behavior] when [condition]"
- Group related tests with describe/context blocks

## Assertions
- Use specific assertions over generic ones (toBe over toBeTruthy)
- Assert one behavior per test case
- Include both positive and negative test cases

## Mocking
- Mock external dependencies at module boundaries
- Prefer dependency injection over module mocking when possible
- Reset mocks between test cases
```

> **Note on `paths:`**: Common patterns: `["tests/**"]`, `["**/*.test.*", "**/*.spec.*"]`, `["__tests__/**"]`. Match the project's test runner conventions.
