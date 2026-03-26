# claude-autopilot

Project scaffolding, auditing, and intelligent tool discovery for Claude Code.

Stop spending the first 20 minutes of every project explaining your conventions, file structure, and tool preferences to Claude. **claude-autopilot** interviews you once, scaffolds an optimized project structure, then continuously audits and improves it.

## What You Get

### 3 Skills

**project-init** -- Scaffold a new project or restructure an existing one.
- Interactive discovery interview that adapts to your project type and size
- Router-pattern CLAUDE.md (max 80 lines) with conditional navigation maps
- `.claude/rules/` files with `paths:` frontmatter for auto-loaded coding conventions
- Smart file selection: small projects get 2-3 files, large projects get the full reference suite
- Positive-phrasing pass that rewrites "don't do X" rules into "do Y instead" (reduces violations ~50%)
- Rollback support via `.init-manifest`

**project-audit** -- Detect and fix problems in your project's reference files.
- Contradiction detection across CLAUDE.md, `.claude/rules/`, and loaded skills with severity ratings
- Instruction budget analysis (~150 instruction capacity, warns when approaching saturation)
- Health score (0-100) across 4 dimensions: Structure, Content, Efficiency, Maintenance
- Stale count sweeps, encoding checks, merge artifact detection
- Output formats: interactive, markdown file, or JSON for CI/CD pipelines
- Quick audit mode for fast periodic checks (5-10 lines, under 1 minute)

**project-plugins** -- Discover tools across 7 categories, not just MCP servers.
- MCP servers, direct APIs, CLI tools, npm/pip packages, Claude Code features, skills, and plugins
- Curated registry (103+ pre-vetted entries) checked first, web search fills gaps
- Context cost estimation with 20% threshold warning
- Compatibility checking: Node version, OS, conflicts, plan tier
- Structured installation verification with pass/fail report
- Overlap analysis with side-by-side comparisons for genuine alternatives

### 4 Slash Commands

| Command | What it does |
|---------|-------------|
| `/init` | Run project-init with optional context arguments |
| `/audit` | Full audit with health score. Pass `json` or `file` for output format |
| `/quick-audit` | Fast periodic check -- 5-10 lines, no file writes |
| `/plugins` | Discover tools. Pass a scope like `"database tools"` to narrow search |

### 2 Hooks

- **SessionStart**: Checks status.md freshness, suggests audit when overdue
- **Stop**: Prompts Claude to update status.md, tasks.md, and filemap.md before ending

## Install

```bash
claude plugin add https://github.com/Corsox-Tech/claude-autopilot.git
```

Works standalone. No configuration required. Once published to the marketplace, install via `claude plugin add corsox/claude-autopilot`.

For richer tool recommendations, the plugin can optionally access the curated registry at [Corsox-Tech/claude-tool-registry](https://github.com/Corsox-Tech/claude-tool-registry).

## How It Works

**Init flow**: Discovery interview (5 questions) -> file selection matrix -> plan approval -> CLAUDE.md generation -> reference file generation -> rules/ generation -> positive-phrasing pass -> plugin/tool recommendations -> verification.

**Audit flow**: Inventory scan -> structural checks -> content checks -> efficiency checks -> contradiction detection -> health score -> report -> execute approved fixes -> rule reinforcement.

**Plugins flow**: Needs profile -> registry search -> web search for gaps -> evaluate + tier -> compatibility check -> present recommendations with context cost -> install + verify.

## Why This Exists

Claude Code works best when your project has clear, non-contradictory instructions in a lean CLAUDE.md with on-demand reference files. Most projects start well but drift: CLAUDE.md grows past 80 lines, instructions contradict each other across files, stale counts accumulate, and the context window fills with instructions Claude can't reliably follow.

claude-autopilot prevents that drift. Init sets up the right structure from day one. Audit catches problems before they degrade output quality. Plugins ensures you're using the right tools without overloading the context window.

## Comparison

| Feature | claude-autopilot | Manual setup | Other scaffolders |
|---------|-----------------|-------------|-------------------|
| Router-pattern CLAUDE.md | Yes (max 80 lines) | You'd need to know the pattern | Usually monolithic |
| Auto-loaded `.claude/rules/` | Yes, with glob-scoped frontmatter | Manual if you know about it | No |
| Contradiction detection | Cross-scope with severity ratings | Not possible manually | No |
| Instruction budget tracking | Yes (~150 capacity model) | No | No |
| Health score (0-100) | Yes, 4 dimensions | No | No |
| Tool discovery (7 categories) | Yes, with curated registry | Ad hoc searching | MCP-only if any |
| Context cost estimation | Yes, with threshold warnings | No | No |
| CI/CD report output | JSON + markdown file | No | No |
| Positive-phrasing optimization | Yes, with security exceptions | No | No |

## Requirements

- Claude Code CLI
- No additional dependencies

## License

MIT

## Author

[Corsox](https://github.com/Corsox-Tech)
