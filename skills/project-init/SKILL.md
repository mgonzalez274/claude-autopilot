# Skill: project-init
> Version: 3.1

> **Skill size note**: This skill is ~438 lines plus a separate TEMPLATES.md file. For small projects, the Phase 3 file selection matrix will skip most files -- don't let the length of this skill suggest the output will be equally complex. A small project may only get CLAUDE.md + status.md + filemap.md.

## Purpose
Scaffold a new Claude-managed project or restructure an existing one. This skill interviews the user, determines the optimal project structure, creates all reference files with proper content, writes a lean "router-style" CLAUDE.md, and suggests plugins/skills/integrations.

## When to Use
- Starting any new project
- Restructuring or migrating an existing project to this system
- When the user says "init project", "set up project", "scaffold", or similar
- **Ordering**: If running alongside `project-audit` (e.g., "set up and audit this project"), init runs first, audit runs after.

## Relationship to Other Skills
- After init completes, use `project-audit` for ongoing health checks
- Init's plugin phase delegates to `project-plugins` -- do not duplicate discovery logic here
- This skill runs ONCE per project. For maintenance, use `project-audit`.

## Interaction with Claude Code Built-in Features
- Claude Code automatically reads `CLAUDE.md` at session start -- this skill creates that file
- If the project already has a `CLAUDE.md` from Claude Code's `/init` command, this skill will propose migrating it to the router pattern (with approval)
- This skill's `.claude/` folder does NOT conflict with Claude Code's `.claude/` config directory -- settings.json and skills/ coexist with the reference files

---

## PHASE 1: Discovery Interview

Before creating anything, gather all necessary context. Ask these questions **in a single batch** (do not drip-feed questions one at a time). Adapt phrasing naturally, skip questions that are already answered by context.

### Required Information

**Project Identity**
- Project name and short description (1-2 sentences)
- Project type (detect from context or ask):
  - `webapp` -- Web application (SPA, fullstack, API)
  - `wordpress` -- WordPress site, theme, or plugin
  - `saas-platform` -- SaaS product with infra, billing, multi-tenant
  - `static-site` -- Astro, Next.js static, landing pages, SEO-focused
  - `automation` -- CRM workflows, Zoho, API integrations, email deliverability
  - `devops` -- Infrastructure, CI/CD, server management
  - `documentation` -- Knowledge base, docs site, research workspace, planning hub (no source code)
  - `mixed` -- Multiple types combined (specify which)
  - `other` -- Describe (note: `other` is not a registry project_type -- when passing to project-plugins, map to the closest match or use `mixed`)

**Scope & Scale**
- Estimated size: `small` (< 1 week), `medium` (1-4 weeks), `large` (1-3 months), `xl` (3+ months)
- Is this a solo project or does it involve a team? If team, who and what roles?
- Is this a new project from scratch, or do existing files/repos already exist?
- If existing: where do the files live (repo, local folder, cloud drive), what's the current state, any known issues?
- *(Code projects only)* Is this a monorepo with multiple packages/services?

**Technical Context** *(adapt to project type -- skip irrelevant questions for non-code projects)*
- Tools and platforms in use (for code projects: languages, frameworks, databases; for docs/planning projects: writing tools, collaboration platforms, content formats)
- Hosting/infrastructure (if applicable -- AWS, Hostinger, Vercel, etc.)
- Repos and version control setup (GitHub orgs, branch strategy) -- or file storage location for non-repo projects
- External services/APIs involved (Zoho, Stripe, Google Cloud, etc.)
- Does Claude have direct access to any of these? (SSH, API keys, MCP connectors, GitHub CLI, etc.)

**Workflow Preferences**
- *(Code projects)* How does the user want to handle deployments? (manual, CI/CD, Claude-managed)
- Are there existing reference docs, specs, or requirements docs to ingest?
- Any specific conventions? (for code: commit messages, branch names, code style; for docs: naming, formatting, review process)
- *(If using git)* Does the user want Claude to auto-commit, or always ask first?
- What language should reference files be written in? (e.g., English, Spanish, or match conversation language)

**Goals & Priorities**
- What's the primary goal of the project right now? (MVP, feature build, migration, maintenance, audit, research, content creation, planning)
- Are there hard deadlines or milestones?
- Any known risks, blockers, or dependencies?

### Size Sanity Check
After the user answers, if the project has existing files, run a quick check:

**For code projects (repo exists):**
- Count files and directories in the repo, **excluding** dependency/build/cache directories: `node_modules`, `.git`, `vendor`, `dist`, `.next`, `__pycache__`, `.cache`, `build`, `out`, `.parcel-cache`, `coverage`, `.turbo`, `.vercel`, `.output`, `target` (Rust), `bin`/`obj` (.NET). Rule of thumb: exclude any directory that wouldn't exist without a build/install step. Adapt further to the project's tech stack.
- If repo has >100 source files and user said "small", suggest at least "medium"
- If repo has >500 source files and user said "medium", suggest "large"

**For non-code projects (docs, planning, research):**
- Count total content files (markdown, documents, spreadsheets, etc.)
- If >30 content files and user said "small", suggest "medium"
- If >100 content files and user said "medium", suggest "large"

Present the suggestion; user has final say.

### Important
- **Never assume answers.** If something is unclear, ask.
- If the user provides a document, spec, or brief -- read it fully before asking questions, then only ask what's missing.
- The user may answer in English or Spanish. Respond in whichever language they use.

---

## PHASE 2: Scan Existing Project (skip if new project)

If the user is running init on an existing project (not new from scratch), scan before determining structure:

1. **Check for `.claude/.init-manifest`** -- if it exists, this project was previously initialized by this skill. Validate the manifest against disk and offer a re-init flow (see below).
2. **Read the current CLAUDE.md** (if any) -- note line count, content, rules, paths
3. **Check for existing reference files** -- any .claude/ folder, readme, status files, knowledge base docs, etc.
4. **List all existing files in .claude/** that would be affected by restructuring
5. **Catalog existing content** -- note what exists and where it would move in the standard structure
6. **Identify content to preserve** -- don't lose any existing instructions, rules, or knowledge

Feed all findings into Phase 3 (Structure Determination). Do NOT create, modify, or delete any files in this phase.

### Manifest Validation & Re-init Flow

When `.init-manifest` exists, validate each entry against disk before offering options:

| Manifest entry | On disk? | Category |
|---|---|---|
| Listed + exists | Yes | Available for backup/update |
| Listed + missing | No | Previously created, manually deleted |
| Not listed + exists in .claude/ | Yes | User-created, will not be touched |

Report the validation: "Init manifest lists {N} files. {X} still exist, {Y} were manually deleted since init, {Z} new files were created independently."

Then present re-init options:
- **(a) Re-init from scratch**: Backup all existing init-created files (skip backup for files that were manually deleted -- they don't need backing up), run discovery interview fresh, generate all files anew.
- **(b) Update only**: For each file in the manifest that still exists, compare the current content against what the template would generate from the CURRENT discovery answers (re-ask the interview or reuse answers if the user confirms they haven't changed). Apply these merge rules:
  - **File unchanged from original template**: Replace silently.
  - **File modified by the user** (content differs from what the template would have generated): Show the diff. Ask the user per-file: replace, keep current, or merge specific sections.
  - **File deleted by the user**: Ask whether to recreate it.
  - **Files not in manifest** (user-created): Never touch.
- **(c) Cancel**: Exit without changes.

**Quick exit**: After validation, if the existing structure and content match what Phase 3 would generate (same file set, same discovery answers), report: "Current setup matches what init would generate. No changes needed." Offer to re-run discovery if the user wants different answers.

---

## PHASE 3: Structure Determination

Based on discovery answers (and existing project scan if applicable), determine the project structure.

### File Selection Matrix

| File | When to Create | Purpose |
|------|---------------|---------|
| `CLAUDE.md` | **Always** | Router file. Core rules + navigation map. MAX 80 lines. |
| `.claude/status.md` | Size ≥ medium, OR multi-session projects, OR team projects | Human-readable handoff doc: current state, active task, blockers. Claude's built-in Auto Memory handles most session continuity for small/solo projects. |
| `.claude/filemap.md` | **Always** | Map of .claude/ files and top-level project directories with descriptions. |
| `.claude/tasks.md` | Size ≥ medium | Task tracker with status, priority, dependencies. |
| `.claude/architecture.md` | Any project with >3 components that need structural documentation (code: modules, services, APIs; non-code: content areas, data sources, workflows) | System design, component relationships, structural decisions. |
| `.claude/notes.md` | Size ≥ medium | Session findings, discoveries, decisions. Append-only log. |
| `.claude/credentials.md` | Project uses external services/APIs | Credential references (NOT actual secrets -- only labels and how to access them). |
| `.claude/focus.md` | Size ≥ large OR total reference files > 5 | Temporary focus file for current sprint/task batch. Updated per sprint, not per session. |
| `.claude/kb/` folder | Size ≥ large OR project has complex business rules | Knowledge base. Split into topic-specific files. |
| `.claude/kb/requirements.md` | KB folder exists + there are business rules | Business requirements, permissions, user roles, workflows. |
| `.claude/kb/api-specs.md` | KB folder exists + external API integrations | API endpoints, auth methods, rate limits, data schemas. |
| `.claude/kb/[topic].md` | As needed | Additional topic-specific KB files. |
| `.claude/workflows.md` | Project involves CI/CD, deployment pipelines, or multi-step processes | Step-by-step workflows for deploy, test, release, etc. |
| `.claude/rules/coding.md` | Code projects where the user specified style, naming, or pattern conventions in discovery | Auto-loaded coding conventions when Claude touches source files. Uses `paths:` frontmatter. |
| `.claude/rules/testing.md` | Code projects with a test suite or testing conventions specified in discovery | Auto-loaded testing conventions when Claude touches test files. Uses `paths:` frontmatter. |
| `README.md` | **Always** (if not existing) | Standard project readme for humans. |

### File Map Scope
`filemap.md` catalogs **only**:
- All reference files inside `.claude/` (with purpose descriptions) -- excludes infrastructure files (`.init-manifest`, `settings.json`, `skills/`)
- Top-level project directories (with one-line purpose descriptions)
- It does NOT list individual source files -- that's what `architecture.md` is for

### Folder Organization Rules

Apply these rules for ALL file creation throughout the project lifecycle (the critical rule is already in Core Rule #3; embed additional project-specific folder conventions in the Conventions section of CLAUDE.md if needed):

```
# Folder conventions (embed in CLAUDE.md -- adapt to project type)
# Code projects:
- Source code → `src/` or framework-standard location
- Tests → `tests/` or framework-standard location
- Scripts/utilities → `scripts/`
- Config files → project root (standard practice)
# All projects:
- Generated/output assets (emails, exports, reports) → `assets/[type]/` (e.g., `assets/emails/`, `assets/exports/`)
- Documentation for humans → `docs/`
- Claude reference files → `.claude/`
- NEVER put generated assets in the project root
- When creating a new type of asset, create its subfolder under `assets/` first
# Non-code projects (docs, planning, research):
- Content files → organized by topic or category in top-level folders
- Templates → `templates/`
- Research/sources → `research/` or `sources/`
```

### Monorepo Handling *(code projects only -- skip for non-code projects)*
Monorepo support is limited to basic routing for simple monorepos (2-4 packages):
- Create a **root-level CLAUDE.md** that routes to per-package reference files
- Each package gets its own `.claude/` folder with scoped reference files
- Root CLAUDE.md navigation map points to each package's CLAUDE.md
- Shared concerns (credentials, team conventions) stay at root level

**For complex monorepos with 5+ packages**, run `project-init` independently per package instead. This gives each package its own scoped structure without overwhelming the root router.

### Git Recommendations
Add to the plan which `.claude/` files should be committed vs. gitignored:
- **Commit**: `filemap.md`, `architecture.md`, `tasks.md`, `kb/`, `workflows.md`, `rules/`
- **Gitignore**: `status.md` (session-specific), `notes.md` (personal session log), `credentials.md` (even as references, safer to gitignore)
- For solo projects, committing everything is fine. For team projects, follow the split above.

---

## PHASE 4: Present Plan & Get Approval

**Do NOT create, modify, or delete any files until the user approves this plan.**

Present the full initialization plan in this format:

```markdown
## 📋 Initialization Plan: {Project Name}

**Project type**: {type} | **Size**: {size} | **New/Existing**: {new or existing}

### Files to Create
| File | Purpose | Why |
|------|---------|-----|
| `CLAUDE.md` | Router file with core rules | Always required |
{list all other files selected in Phase 3, with one-line justification for each}

### Files NOT being created (and why)
{list files from the matrix that were skipped, with reason -- e.g., "architecture.md -- project is small, <3 components"}

### Folders to Create
{list any new directories}

### Git Recommendations
{Which files to commit vs. gitignore, based on solo/team context}

### Rules Files (.claude/rules/)
{If rules/ files will be created, list them with their paths: frontmatter and a one-line description of what conventions they enforce. E.g.:}
| File | Paths | Conventions |
|------|-------|-------------|
| `.claude/rules/coding.md` | `src/**`, `lib/**` | Named exports, error handling, naming |
| `.claude/rules/testing.md` | `tests/**`, `__tests__/**` | Test structure, assertions, mocking |
{Omit this section if no rules/ files are being created (e.g., non-code projects).}

### CLAUDE.md Preview
{Show a condensed preview of the core rules and navigation map that will go into CLAUDE.md -- not the full file, but enough for the user to see the structure and flag anything wrong}
```

**For existing projects, also include:**
```markdown
### Existing Files Detected
| File | Current State | Proposed Action |
|------|--------------|-----------------|
| `CLAUDE.md` | 142 lines, monolithic | Rewrite as router (content moved to .claude/ files) |
| `readme.md` | Exists, up to date | Keep as-is |
{list each existing reference file and what will happen to it}

### Content Migration
{Describe where existing content will move -- e.g., "Task list currently in CLAUDE.md lines 45-90 → .claude/tasks.md"}

### ⚠️ Nothing will be deleted
Old files will be kept with a `.backup` extension until you confirm the migration is good. If a `.backup` already exists from a prior init run, use numbered backups (`.backup.1`, `.backup.2`, etc.) to preserve the full history.
```

**After presenting the plan, your FINAL line must be:**
`Reply **approve**, **modify**, or **cancel** to proceed.`

**Do not generate any further output until the user responds.**
- If the user requests changes: update the plan and present again with the same approval prompt.
- If the user approves with a modification (e.g., "looks good, but change X"): apply the tweak and proceed directly -- no need for a second full approval round.
- Only proceed to Phase 5 when the user explicitly approves (or approves-with-modification).

---

## PHASE 5: Generate CLAUDE.md (Router Pattern)

> **Only execute after user approves the plan in Phase 4.**

Read `TEMPLATES.md` (same directory as this SKILL.md -- Claude Code resolves skill-relative paths automatically) for the CLAUDE.md template and all file templates. Follow those templates to generate CLAUDE.md and proceed to Phase 6.

### If CLAUDE.md exceeds 80 lines after filling in real content
Move the Tech Stack and Conventions sections to `.claude/architecture.md` and replace them in CLAUDE.md with single-line references:
- `Tech Stack → see .claude/architecture.md`
- `Conventions → see .claude/architecture.md`

### Critical: What NOT to put in CLAUDE.md
- ❌ Detailed task lists (use tasks.md)
- ❌ Architecture details (use architecture.md)
- ❌ API specs or credentials (use dedicated files)
- ❌ Long instructions that could be in a workflow file
- ❌ Contents of other files (only paths and triggers)
- ❌ Instructions like "always read X before doing anything" (use conditional triggers instead)

---

## PHASE 6: Generate All Files

> **Only execute after user approves the plan in Phase 4.**

Read `TEMPLATES.md` (same directory as this SKILL.md) for file templates. Create all determined files with meaningful initial content -- not empty placeholders. **Windows note**: Always use forward slashes in file paths written to reference files (CLAUDE.md, filemap.md, nav map). Claude Code on Windows sometimes emits backslashes -- normalize to forward slashes for consistency. Each file should:

1. Have a clear header explaining its purpose
2. Have a "Last updated" line at the top
3. Have a "Maintenance rules" section explaining when/how to update it
4. Have initial content seeded from discovery answers
5. Be written in the language agreed upon in Phase 1

### Generate .claude/rules/ Files (code projects)

If the plan includes `.claude/rules/` files, generate them now using the templates in TEMPLATES.md. Rules files use `paths:` frontmatter so Claude Code auto-loads them when touching matching files -- this is more reliable than navigation map triggers for coding conventions.

**Key principles:**
- Keep each rules file focused on one concern (coding style, testing, etc.)
- Use `paths:` frontmatter with glob patterns matching the project's source layout. Inspect the project's actual directory structure (e.g., `src/`, `app/`, `lib/`, `tests/`) to determine the correct globs -- do not guess.
- Content should be imperative and positive ("Use named exports" not "Don't use default exports") -- positive phrasing reduces violations by ~50%
- These files complement the navigation map, not replace it. The nav map handles documentation files (architecture.md, credentials.md). Rules/ handles conventions that should auto-load.
- Conventions that apply project-wide (not path-scoped) stay in CLAUDE.md's Conventions section or architecture.md

### Positive-Phrasing Pass

After generating ALL files (CLAUDE.md, rules/, architecture.md conventions), scan every generated rule and convention for negative phrasing. Research shows positive rules ("Use named exports exclusively") have ~50% fewer violations than negative equivalents ("Do NOT use default exports").

**Scan for**: Any rule using "Do NOT", "NEVER", "Don't", "Avoid", "No" as the leading verb or emphasis -- across CLAUDE.md, `.claude/rules/` files, and any conventions in architecture.md.

**For each match**: Suggest a positive equivalent that conveys the same constraint. Examples:
- "Do NOT use default exports" -> "Use named exports exclusively"
- "NEVER commit directly to main" -> "Create feature branches for all changes"
- "Don't hardcode credentials" -> "Store credentials in environment variables or secret managers"

**Exceptions** (keep negative phrasing): Security rules and hard prohibitions where the negative form is clearer and the consequence of violation is severe (e.g., "NEVER put API keys in source files"). Use judgment -- if the positive form is equally clear, prefer it.

Present suggested rewrites to the user for approval before applying.

### Init Manifest (for safe rollback)
After creating all files, write `.claude/.init-manifest` -- a simple list of every file path that init created. This manifest is used by the ROLLBACK process to delete only what init created, leaving pre-existing files untouched.

Format:
```
# Files created by project-init on {date}
CLAUDE.md
.claude/status.md
.claude/filemap.md
.claude/tasks.md
...
```

---

## PHASE 7: Plugin/Skill Recommendations

After creating the project structure, **delegate to the `project-plugins` skill** for tool discovery and recommendations.

Pass along to project-plugins:
- Project type and tech stack (from Phase 1)
- External services and integrations (from Phase 1)
- What Claude has direct access to (from Phase 1)

If the `project-plugins` skill is not installed, use this minimal fallback:
1. If the curated registry at `Corsox-Tech/claude-tool-registry` is accessible, read `registry-index.md` and filter by project type to suggest relevant tools -- this provides better recommendations than guessing
2. Otherwise, based on project type, suggest the most obvious tools -- MCP servers (e.g., Zoho MCP for Zoho projects), CLI tools (e.g., wp-cli for WordPress, dig/swaks for DNS/email projects), and key APIs (e.g., service-specific REST APIs for automation projects)
3. Note that the full `project-plugins` skill should be installed for comprehensive recommendations across all tool categories
4. Ask the user which to install

### MCP Installation Scope
When installing or recommending MCP servers, **default to project-scoped `.mcp.json`** (in the project root). This ensures tools only load for projects that need them, reducing token waste and preventing wrong-tool selection.

| Scope | Config File | Use When |
|-------|------------|----------|
| **Project shared** | `.mcp.json` (project root) | Default. Tool is needed for this project. Shared with collaborators via git. |
| **Project local** | `.claude/settings.local.json` | Tool is only for you, not the team (e.g., personal dev tools, your-machine-only credentials). |
| **User global** | `~/.claude/settings.json` | Tool is needed across ALL your projects (rare -- e.g., a personal productivity MCP). |

Only use user-global scope if the user explicitly requests it. Project-specific MCPs installed globally waste tokens on every other project and can cause Claude to pick the wrong tool.

### MCP Config Platform Compatibility
When creating or recommending `.mcp.json` entries, check the platform (available in the environment context as `Platform:`). On `win32`, commands like `npx`, `uvx`, `pnpm`, and `bunx` cannot be invoked directly -- they must be wrapped with `cmd /c`:

```json
// WRONG on Windows:
{ "command": "npx", "args": ["prisma", "mcp"] }

// CORRECT on Windows:
{ "command": "cmd", "args": ["/c", "npx", "prisma", "mcp"] }
```

Apply this wrapping to ALL `.mcp.json` entries where the command is `npx`, `uvx`, `pnpm`, or `bunx` and the platform is `win32`. On non-Windows platforms, use the command directly.

---

## PHASE 8: Final Verification

After setup is complete:

1. Read CLAUDE.md from top to bottom -- verify it's under 80 lines, all paths exist, no contradictions.
2. Verify every line in CLAUDE.md serves one of: rule, navigation pointer, or essential metadata. Flag any line that's "content" rather than "routing."
3. Read each created file -- verify headers, maintenance rules, and content are correct.
4. Verify filemap.md matches actual file structure.
5. Verify `.claude/.init-manifest` lists all created files.
6. If `.claude/rules/` files were created, verify each has valid `paths:` frontmatter with glob patterns that match existing project directories. Invalid patterns silently prevent auto-loading.
7. Report to user: summary of what was created, file count, suggested next steps.

---

## ROLLBACK

If the user says "undo init", "rollback", or indicates the setup went wrong:

1. **Read `.claude/.init-manifest`** to get the list of files init created.
2. **Validate manifest against disk**: Check which listed files still exist. Report: "Manifest lists {N} files. {X} still exist, {Y} were already deleted."
3. **For new projects**: Delete only the manifest files that still exist on disk. Skip entries for files that were already manually deleted. Report accurately: "Deleted {X} files. {Y} manifest entries were already missing (skipped)."
4. **For existing projects**: Restore all `.backup` files to their original names, then delete manifest files that still exist and don't have a corresponding backup. Skip entries for files that were already manually deleted (no backup to restore, nothing to delete). This ensures pre-existing `.claude/settings.json`, `.claude/skills/`, etc. are never touched.
5. Delete the `.init-manifest` itself.
6. Ask the user if they want to re-run init with different answers.

If `.init-manifest` doesn't exist (e.g., init was run before this feature), fall back to asking the user which files to remove rather than guessing.

---

## Output Format

After completing all phases, present a summary:

```
## Project Initialized: {name}

**Structure Created:**
- CLAUDE.md (X lines)
- .claude/status.md
- .claude/filemap.md
- [list all created files]

**Git Recommendations:**
- Commit: [list]
- Gitignore: [list]

**Plugins/Skills:**
{Summary from project-plugins, or minimal fallback recommendations}

**Next Steps:**
1. [First thing to work on]
2. [Second thing]

**Notes:**
- [Any warnings, caveats, or things to revisit]
- To undo this setup: say "undo init"
```
