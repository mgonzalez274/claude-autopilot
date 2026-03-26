# Skill: project-audit
> Version: 3.1
> **Skill size note**: This skill is ~295 lines. The length is intentional -- the audit methodology requires comprehensive check definitions and detection procedures. Splitting would fragment the audit flow. The 150-line threshold in CLAUDE.md Rule #7 applies to `.claude/` reference files read during normal development, not to self-contained skill definitions.

## Purpose
Audit and optimize a Claude-managed project's reference files, structure, and efficiency. Detects bloat, contradictions, stale info, missing docs, context window risks, and organizational issues. Produces actionable recommendations and executes approved changes.

## When to Use
- User says "audit", "optimize", "clean up", "review project structure", or similar
- Periodically on long-running projects (suggest every 2-4 weeks or after major milestones)
- When Claude notices degraded accuracy, confusion between old/new instructions, or reference files growing large
- After a major scope change, requirement shift, or team change
- **Ordering**: If running alongside `project-init`, init runs first, audit runs after.

---

## AUDIT PROCESS

### Step 1: Inventory Scan

Read and catalog everything:

1. **Read CLAUDE.md** -- note line count, structure, rules, paths referenced
2. **Identify workstream directories** -- scan CLAUDE.md for sections that declare workstreams, directories, or scoped areas (e.g., a "Workstreams" section listing `skills/`, `registry/`). Record these as **audit-scope directories** -- all content checks (contradictions, encoding, staleness) must cover these directories in addition to `.claude/`. **Fallback**: If CLAUDE.md has no explicit workstream declarations, scan for top-level directories referenced in CLAUDE.md rules, navigation map entries, or file-placement rules that aren't `.claude/` itself (e.g., if a rule says "Skills in `skills/`", that's a workstream directory). If no directories are identified by either method, flag as ⚠️ Warning: "no workstream directories identified -- audit scope limited to `.claude/`".
3. **Read .claude/ directory** -- list all files and their sizes (line counts)
4. **Read workstream directories** -- for each audit-scope directory identified in step 2, list all files (especially `.md` files) and their sizes. These are part of the audit scope.
5. **If .claude/filemap.md exists** -- cross-reference it against actual files (find mismatches)
6. **If .claude/kb/ exists** -- list all KB files and their line counts
7. **Check project root** -- flag any files that shouldn't be there (generated assets, temp files, orphaned docs)
8. **Read each reference file** -- note last-updated dates, content quality, potential issues
9. **Check status.md for `Last audit` date** -- note how long since last audit

Build an internal inventory before proceeding. Do NOT output findings one file at a time -- complete the full scan first, then report.

### Step 2: Run Checks

Evaluate the project against these checks. Score each as ✅ Pass, ⚠️ Warning, or ❌ Fail.

**Scope integrity rule**: A check may only be scored ✅ Pass if it was verified across its FULL required scope. If a check's scope includes workstream directories but only `.claude/` was scanned, it MUST be scored ⚠️ Warning with a note like "passed within `.claude/` only -- workstream directories not scanned." If a directory is inaccessible (permission error, deleted, or unreadable), score affected checks as ⚠️ Warning with the specific failure reason (e.g., "skills/ directory not readable -- permission denied") -- do NOT silently skip it and do NOT treat it as a hard failure that blocks the entire audit. Never claim "no issues found" without qualifying exactly what was scanned. When reporting results, always state the scope (e.g., "Encoding check: scanned 14 .md files across `.claude/`, `skills/`, `registry/`").

#### Structural Checks

| Check | Pass Criteria | How to Fix |
|-------|--------------|------------|
| CLAUDE.md line count | ≤ 80 lines | Split content to dedicated files, keep only rules + navigation |
| CLAUDE.md is router-only | Every line serves one of: rule, navigation pointer, or essential metadata. No detailed content. | Move detailed content to appropriate .claude/ files |
| Core rules present | Has change-propagation, no-assumptions, file-placement, session-start/end rules | Add missing rules |
| Navigation map valid | Has a table mapping files → read triggers; all referenced file paths exist on disk | Create navigation map; remove entries for deleted files |
| status.md exists and is current | Last updated within the last 2 weeks, or project is inactive (verify via `git log --oneline -1`) | Update or create |
| filemap.md matches reality | All listed files exist; all existing .claude/ reference files are listed (skip infrastructure files: `.init-manifest`, `settings.json`, `skills/`) | Sync filemap |
| No orphaned assets in root | Project root has only config, README, source dirs -- no generated outputs | Move to assets/ |
| Folder conventions followed | Generated assets in assets/, docs in docs/, etc. | Reorganize |
| MCP config platform-compatible | If `.mcp.json` exists and platform is `win32`: every entry where the command is `npx`, `uvx`, `pnpm`, or `bunx` must use `cmd /c` wrapper (`"command": "cmd", "args": ["/c", "npx", ...]`). On non-Windows, the inverse: no unnecessary `cmd /c` wrapping. | Fix command/args in `.mcp.json` to match platform |
| No irrelevant tools loaded | Scan user-global MCPs (`~/.claude/settings.json` → `mcpServers`) and check each against the project's type and tech stack (from CLAUDE.md metadata). Flag tools that have no relevance to this project (e.g., Prisma MCP on a project with no database, WordPress MCP on a React SPA). Also flag project-scoped tools in `.mcp.json` that no longer match the current stack (e.g., after a tech migration). | Suggest removing from user-global or moving to the specific project's `.mcp.json` that needs them |
| No conflicting/overlapping tools | Check all loaded MCPs (across all scopes) for tools that serve the same purpose (e.g., two database MCPs, two git integrations). Overlapping tools waste context tokens and confuse tool selection. | Recommend keeping one, removing the other, with justification |
| MCP scope appropriate | Project-specific MCPs should be in `.mcp.json` (project scope), not in user-global `~/.claude/settings.json`. Flag any user-global MCP that is clearly project-specific (e.g., a service MCP only used by one project). | Move to `.mcp.json` in the project that needs it |
| Self-maintenance rules complete | CLAUDE.md session-end rule covers: status.md, tasks.md, filemap.md (when files created), and "Last updated" date maintenance on modified reference files. Self-audit trigger distinguishes CLAUDE.md 80-line limit from reference file 150-line limit. | Add missing triggers to session-end rule; fix self-audit thresholds |
| Rules files valid | If `.claude/rules/` exists: (1) each file has `paths:` frontmatter with valid YAML, (2) glob patterns in `paths:` match at least one existing directory or file in the project, (3) each file is under 150 lines, (4) no two rules files have identical or fully overlapping `paths:` patterns (would cause redundant loading). If no rules/ directory exists, skip this check. | Fix frontmatter, update stale globs, split oversized files, deduplicate overlapping paths |
| Rules use positive phrasing | Scan `.claude/rules/` files for leading negative verbs ("Do NOT", "NEVER", "Don't", "Avoid"). Positive phrasing reduces violations by ~50%. | Suggest positive rewrites for each negative rule (see project-init Phase 5 positive-phrasing pass) |

#### Content Checks

| Check | Pass Criteria | How to Fix |
|-------|--------------|------------|
| No contradictions | See contradiction detection methodology below | Flag contradictions, ask user which version is correct |
| No stale information | Nothing references deprecated behavior, old endpoints, removed features | Update or remove |
| No duplicate content | Same information not repeated in multiple files | Consolidate to single source of truth, add cross-references |
| KB files are topic-scoped | Each KB file covers one topic, ≤ 150 lines | Split large files by topic |
| Reference files have headers | Each file has purpose description and maintenance rules | Add missing headers |
| Reference files have dates | Each file has "Last updated" line | Add dates |
| No credentials in plain text | No API keys, passwords, tokens in any reference file | Move to credentials.md as references only (not values) |
| No circular references | File A doesn't say "read B first" while B says "read A first" | Break cycles, establish clear read order |
| No encoding corruption | No non-ASCII characters in ALL `.md` files across the project (`.claude/`, workstream directories, root) except where intentional (e.g., accented characters in Spanish content). No em-dashes (use --), no curly quotes, no BOM markers. Scope: every `.md` file in the project, not just `.claude/` -- encoding conventions are project-wide (check `architecture.md` or CLAUDE.md conventions section if they exist) | Replace with ASCII equivalents |
| No merge artifacts | No references to external repos, old org paths, or URLs that point to resources now local to the project. Grep all `.md` files for these patterns: (1) `github.com/[org]/[repo]` URLs, (2) `[OrgName]/[repo-name]` shorthand references, (3) absolute paths like `/old/path/to/` that don't match current project structure. For each match, verify whether the referenced resource now exists locally in the project. E.g., a reference to `OrgName/old-repo-name` when the content now lives at `registry/` inside the monorepo is a merge artifact. | Replace external references with correct local paths |
| Nav map completeness (reverse) | Every file in `.claude/` (excluding infrastructure: `.init-manifest`, `settings.json`, `skills/`) has a corresponding entry in CLAUDE.md's navigation map | Add missing entries to nav map |

##### Contradiction Detection Methodology
Do NOT rely on memory or skimming. Follow these steps:

**Fast path (use when last audit is recent):** Check file modification dates or `Last updated` headers. If two files haven't been modified since the last audit, skip cross-checking them -- contradictions only appear when something changes. Focus grep effort on recently changed files.

**Full scan (use on first audit or when last audit is stale/never):**
1. For each `.claude/` file (including kb/ files), extract key factual claims -- behaviors, permissions, endpoints, config values, roles, rules (e.g., "Standard users can only read dashboards", "API endpoint is /v2/users", "Deploy to staging branch first")
2. **Extract verifiable specifics**: Separately collect all version numbers (e.g., "v2.8", "Version: 2.3"), entry counts (e.g., "103 entries"), and path references (e.g., `registry/registry.json`, `skills/project-plugins/SKILL.md`) from the FULL audit scope: `.claude/` files, CLAUDE.md, AND all workstream/audit-scope directories (e.g., `skills/`, `registry/`). Workstream files often contain their own version numbers (e.g., `SKILL.md` line 2: "Version: X.Y"), entry counts, and cross-references that must be verified.
3. **Verify specifics against source files**: For each version number, check the actual source file it refers to (e.g., if `status.md` says "project-plugins v2.8", open `skills/project-plugins/SKILL.md` and check the real version). For each entry count, verify against the actual data (e.g., count entries in `registry.json`). For each path reference, verify the path exists on disk. This verification is bidirectional -- also check that version numbers and counts stated WITHIN workstream files match the canonical source (e.g., if `skills/project-plugins/SKILL.md` claims "73+ entries", verify against the actual `registry.json` count).
4. Use `grep` or search across the FULL project -- `.claude/`, all workstream/audit-scope directories, CLAUDE.md, and any other `.md` files -- for each entity/behavior mentioned. Do NOT limit searches to `.claude/` alone.
5. **Stale count sweep**: When a verified count is found (e.g., registry has 103 entries), do NOT only check for that number. Grep across the full project for ALL plausible variants -- the correct count, plus previously-known counts and round numbers that might be stale. To find previous counts, check: (a) `status.md` "Recent Changes" or changelog entries, (b) `git log --oneline -10` for commit messages mentioning counts, (c) counts found in other files during step 2 extraction that differ from the verified value. For example, if the verified count is 103, search for "73", "100", "101", "102", "103" in context of "entries", "tools", etc. Any file referencing an outdated count is a stale-info finding.
6. **Cross-scope contradiction check**: For each rule or convention found in `.claude/rules/` files, grep CLAUDE.md for the same topic (naming, exports, style, error handling). For each convention in CLAUDE.md's Conventions section, grep `.claude/rules/` files for the same topic. If skills are loaded, check their instructions against both. Flag any case where the same topic has different directives across scopes. The three scope pairs to check:
   - CLAUDE.md rules vs `.claude/rules/` file conventions (e.g., CLAUDE.md says "use default exports" but rules/coding.md says "use named exports")
   - `.claude/rules/` files vs each other (e.g., coding.md says "camelCase" but a domain-specific rules file says "snake_case")
   - CLAUDE.md/rules/ vs loaded skills (if skills contain conventions that conflict with project rules)
7. Flag any case where the same entity, behavior, or rule is described differently in two or more files
8. **Assign severity** to each contradiction:
   - **Blocking**: Will cause incorrect behavior or failures (e.g., conflicting deployment targets, wrong API endpoints, contradictory permission rules)
   - **Degrading**: Will reduce instruction compliance or cause inconsistent output (e.g., conflicting style conventions, different naming patterns)
   - **Cosmetic**: Outdated but non-harmful (e.g., stale dates, old counts that don't affect behavior)
9. For each contradiction found, show both versions with file paths, the severity rating, and ask the user which is correct

#### Efficiency Checks

| Check | Pass Criteria | How to Fix |
|-------|--------------|------------|
| Total reference file volume | Within size-appropriate limits (see below) | Split, summarize, or archive old content |
| Read-path efficiency | No file says "always read X" -- uses conditional triggers instead | Convert to "read when [condition]" |
| No unnecessary re-reads | Session-start instructions don't require reading >2 files | Consolidate session-start info into status.md |
| Context budget viable | For a typical task, Claude needs ≤ 3 reference files (ideal); hard ceiling is 5 per CLAUDE.md Rule #6 | Restructure if typical tasks need more than 3 |
| Instruction budget healthy | Total instruction count across all sources is under ~150 (see methodology below) | Consolidate, deduplicate, or remove low-value instructions |
| Task granularity appropriate | Tasks in tasks.md are actionable (not vague epics) | Break down or restructure |

##### Instruction Budget Audit
Claude Code's system prompt consumes ~50 instructions of a model's ~150-200 reliable instruction-following capacity. This leaves ~100-150 slots for CLAUDE.md, `.claude/rules/` files, and loaded skills combined. Every instruction competes; compliance degrades uniformly as count increases.

**Counting methodology:**
1. **CLAUDE.md**: Count each discrete directive -- rules, conventions, "do X", "use Y". Navigation map entries count as instructions -- each row is a conditional trigger directive (a table with 8 rows = 8 instructions). A numbered rule with sub-bullets counts as 1 + number of actionable sub-bullets.
2. **`.claude/rules/` files**: Count instructions in each file. These auto-load based on `paths:` matches, so estimate how many rules files would load for a typical task (usually 1-2).
3. **Loaded skills**: Each loaded skill adds its instruction count. For installed plugins, check skill line counts as a rough proxy (~1 instruction per 3-5 lines of directive content).
4. **Sum**: CLAUDE.md instructions + rules/ instructions (for a typical task) + estimated skill instructions

**Thresholds:**
- Under 80 instructions: ✅ Pass -- healthy budget with room for growth
- 80-120 instructions: ⚠️ Warning -- approaching saturation, consider consolidating
- Over 120 instructions: ❌ Fail -- instruction compliance will degrade. Recommend: deduplicate overlapping rules, merge related conventions, remove instructions that codify obvious behavior (e.g., "write correct code")

**Report as**: "Instruction Budget: ~{count} / 150 ({percentage}%) -- {status}"

##### Reference File Volume Limits (total lines across all .claude/ files, excluding archive/, .init-manifest, settings.json, skills/)
Determine project size from the **Type/Size** metadata line in CLAUDE.md. If not present, ask the user.

**Validate declared size**: Count project files using the same approach as init's Size Sanity Check (for code projects: source files excluding dependency/build/cache dirs; for non-code projects: content files). Compare against declared size:
- Code projects: >100 source files = at least "medium"; >500 = at least "large"
- Non-code projects: >30 content files = at least "medium"; >100 = at least "large"
- If reclassification is needed, update CLAUDE.md metadata and apply the new volume limit

Volume limits by size:
- **Small projects**: < 300 lines
- **Medium projects**: < 500 lines
- **Large projects**: < 800 lines
- **XL projects**: < 1,200 lines

If volume exceeds the limit, prioritize: archive completed content, summarize verbose sections, split and scope files so only relevant ones are read per task.

#### Large Repository Checks (apply when repo is >500 files or >50k lines of code)

| Check | Pass Criteria | How to Fix |
|-------|--------------|------------|
| Architecture doc exists | .claude/architecture.md describes component boundaries | Create architecture.md |
| Component file map | filemap.md maps top-level directories with descriptions | Add project directories section to filemap |
| Task scoping | Tasks are scoped to specific components/files, not "fix the app" | Break into component-scoped tasks |
| KB is granular enough | KB has separate files per domain area, not one mega-file | Split by topic |
| Session scope signals | status.md indicates what part of codebase current work focuses on | Add focus area to status.md |
| Parallel work potential | Independent workstreams are identified and separable | Suggest parallel sessions for independent tracks |

---

### Step 3: Generate Report

**Output format** (ask the user, or auto-detect from context):
- **Interactive** (default): Formatted markdown displayed in conversation. Use for ad-hoc audits.
- **Markdown file**: Write report to `.claude/audit-report.md`. Use when user says "save the report", "write it to a file", or when running in CI/CD pipelines.
- **JSON**: Write structured results to `.claude/audit-report.json` with fields: `date`, `project`, `scores` (array of `{check, status, details}`), `health_score`, `summary`. Use when user says "JSON output", "machine-readable", or for integration with dashboards/scripts.

For markdown file and JSON formats, also display a brief summary in conversation (health score + critical issue count).

Present findings as a structured report:

```markdown
## 🔍 Project Audit Report: {Project Name}
**Date**: {date}
**Last audit**: {date from status.md, or "never"}
**Files Scanned**: {count}
**Total Reference Lines**: {count} / {limit for project size}

### Health Score: {score}/100 {grade}
{See scoring methodology below the template}

### Summary
- ✅ {X} checks passed
- ⚠️ {Y} warnings
- ❌ {Z} failures

### ❌ Critical Issues (fix now)
{List each failure with: what's wrong, where, and proposed fix}

### ⚠️ Warnings (fix soon)
{List each warning with: what's wrong, where, and proposed fix}

### ✅ What's Working Well
{Brief list of passing checks -- reinforce good patterns}

### 📋 Recommended Actions
{Numbered list of specific actions, ordered by priority}
1. [Action] -- fixes [issue] -- estimated effort: [low/medium/high]
2. ...

### 🔮 Proactive Suggestions
{Things that aren't broken yet but will become issues}
- Context window risk: {current load estimate vs. available budget}
- Files approaching split threshold: {list}
- Consider creating: {new files that would help}
- Consider archiving: {old content that's no longer active}
```

##### Health Score Methodology
Score 0-100 across four weighted dimensions. Each dimension scores 0-25 based on its checks.

| Dimension (25 pts each) | Inputs |
|--------------------------|--------|
| **Structure** | CLAUDE.md line count, router-only, core rules, nav map, filemap sync, rules/ validity |
| **Content** | No contradictions, no stale info, no duplicates, encoding clean, no merge artifacts |
| **Efficiency** | Volume within limits, read-path efficiency, instruction budget, context budget |
| **Maintenance** | status.md current, dates present, self-maintenance rules complete, last audit recency |

Each check maps to the dimension of the section it appears under: Structural Checks -> Structure, Content Checks -> Content, Efficiency Checks -> Efficiency. Maintenance dimension uses: status.md freshness, reference file dates present, self-maintenance rules complete, and last audit recency.

**Scoring per dimension**: Start at 25. Each ❌ Fail in the dimension subtracts 8. Each ⚠️ Warning subtracts 3. Minimum 0.

**Grades**: 90-100 = A (excellent), 75-89 = B (healthy), 60-74 = C (needs attention), 40-59 = D (significant issues), 0-39 = F (critical).

### Step 4: Execute Approved Changes

After presenting the report:

1. **Ask user which actions to execute** -- don't auto-execute structural changes
2. **For each approved action**:
   a. Make the change
   b. Update filemap.md to reflect the change
   c. Update any cross-references in other files
   d. Update CLAUDE.md navigation map if paths changed
3. **After all changes**: Re-run a quick verification (Step 1 + check fixed issues actually resolve)
4. **Rule reinforcement** (close the loop): For each issue that was fixed, ask: *"Could a CLAUDE.md rule have prevented this?"* If a rule exists but is incomplete (e.g., session-end rule missing filemap.md trigger), propose strengthening it. If no rule covers the class of issue (e.g., no rule about maintaining "Last updated" dates), propose adding one. Present rule changes as a "Rule Strengthening" section in the report. The goal: projects should get more self-maintaining over time -- the same issue should never appear in two consecutive audits.
5. **Update status.md**: Set `Last audit: {today's date}` and note changes made

---

## CHANGE PROPAGATION AUDIT (Special Mode)

When the user makes a requirement or behavior change (not just a code change), run this focused audit:

1. **Identify the change**: What behavior/requirement/permission changed?
2. **Search CLAUDE.md and all .claude/ files** for mentions of the old behavior -- use grep/search, don't rely on memory. CLAUDE.md is in the project root (not inside `.claude/`) and is the most likely file to contain stale version numbers, counts, or behavioral claims.
3. **Search .claude/kb/ files** for related content
4. **Search all workstream/audit-scope directories** (as identified in Step 1 of the main audit) for mentions of the old behavior -- SKILL.md files, schema docs, and other reference files in `skills/` and `registry/` often contain version numbers, counts, or behavioral claims that must stay in sync
5. **List all files that reference the old behavior**
6. **For each file**: Show the user the outdated content and propose the update
7. **Execute approved updates**
8. **Then proceed** with the code implementation

Claude should suggest this mode whenever it notices a requirement change mid-conversation -- it's Rule #1 in the standard CLAUDE.md. Note: this is not an automatic event hook; it depends on Claude recognizing the change or the user requesting it.

---

## CONTEXT WINDOW MANAGEMENT (for large projects)

When the audit detects context window pressure (total reference content is high, or tasks require reading many files), recommend strategies in priority order:

1. **Focus file**: Create `.claude/focus.md` -- a temporary file that contains ONLY what's needed for the current sprint/task batch. Updated per sprint, not per session.
2. **KB pruning**: Archive completed/obsolete KB entries to `.claude/archive/` (still accessible but not read routinely).
3. **Task batching**: Break remaining work into batches that can each be completed within a session without needing the full reference set.
4. **Component isolation**: If the project has independent components, suggest working on each in a focused session that only loads that component's reference files.
5. **Parallel sessions**: For truly independent workstreams, suggest the user run separate Claude Code sessions with different focus areas.
6. **Reference summarization**: If a KB file is very long but needs to stay, create a summary version and keep the full version as a deep-reference (read summary first, full only if needed).
7. **Agent delegation**: If a subtask is well-defined and independent, suggest whether another agent/session could handle it in parallel.

---

## SELF-TRIGGER CONDITIONS

Claude can detect these conditions **within a single session** and should suggest an audit when they occur:

**Detectable now (within current session):**
- CLAUDE.md exceeds 80 lines (check line count via Read tool or `wc -l` -- on Windows, use Git Bash or count lines via the Read tool)
- Any reference file exceeds 150 lines (same method)
- `status.md` shows `Last audit` date is more than 30 days ago, or is `never` (both exceed the threshold -- compare to today's date)
- A major milestone or feature was just completed
- The user reports that Claude "forgot" something or reverted a change
- Claude reads a file and finds content that seems to contradict something it just did

**Not detectable automatically** (rely on user or periodic scheduling):
- General drift in instruction quality across sessions
- Gradual accumulation of stale content
- Token waste from structural inefficiency

When detecting a triggerable condition, suggest: "It might be a good time to run a project audit. Want me to do a quick check?"

---

## QUICK AUDIT MODE

For fast periodic checks (not full audit), run only:
1. CLAUDE.md line count check
2. filemap.md vs. reality sync
3. status.md freshness (last updated + last audit dates)
4. Scan for any file > 150 lines
5. Quick contradiction check on recently changed files -- determine which files changed by first comparing `Last updated` dates in file headers (primary method -- works regardless of git state). As a supplement, if this is a git repo, also run `git log --name-only -3 --format='' -- .claude/` to catch files that were modified but whose headers weren't updated. If header dates and git dates diverge, flag the discrepancy as a warning.
6. Quick encoding spot-check on any recently changed `.md` files across the full project (not just `.claude/`) -- use the same recency determination as step 5 above (header dates + supplemental git log)

Report in 5-10 lines. Takes <1 minute. Suggest this after every major feature completion.
