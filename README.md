# claude-autopilot
> v1.2.1

Project scaffolding, auditing, and intelligent tool discovery for Claude Code.

Stop spending the first 20 minutes of every project explaining your conventions, file structure, and tool preferences to Claude. **claude-autopilot** interviews you once, scaffolds an optimized project structure, then continuously audits and improves it.

## What's a Router-Pattern CLAUDE.md?

Most CLAUDE.md files grow into monolithic documents -- 200+ lines of rules, context, task lists, and architecture notes all in one file. Claude tries to follow everything at once, compliance drops, and instructions start contradicting each other.

A router-pattern CLAUDE.md stays under 80 lines. It contains only core rules and a **navigation map** -- a table that tells Claude which file to read and when:

| File | Read When |
|------|-----------|
| `.claude/status.md` | Every session start |
| `.claude/architecture.md` | Making design decisions |
| `.claude/kb/permissions.md` | Working on auth or roles |

Everything else lives in dedicated files under `.claude/`. Claude reads only what it needs for the current task instead of loading everything into context at once.

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

- **SessionStart**: Checks status.md freshness, suggests audit when overdue (silent if no status.md)
- **Stop**: Blocks session exit once, prompting Claude to update status.md, tasks.md, and filemap.md. Allows exit on the second attempt.

Both hooks are no-ops on projects without `.claude/status.md` (i.e., projects not initialized with `/init`). To disable hooks, remove the hook entries from `hooks/hooks.json`.

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

## Context Cost

Skills load their name and description at startup (~300 tokens total for all three). The full skill content loads **only when you invoke a command**:

| Command | Tokens loaded | Duration |
|---------|--------------|----------|
| `/init` | ~6,000 | One-time setup |
| `/audit` | ~2,500 | During audit |
| `/quick-audit` | ~2,500 | During check |
| `/plugins` | ~3,500 | During discovery |

These unload after the command completes. For comparison, a typical project's `.claude/` reference files use ~2,000-5,500 tokens depending on size. The skills are transient; your reference files are persistent.

## Requirements

- Claude Code CLI
- **bash** -- hooks run as shell scripts (available natively on Linux/macOS; on Windows, Git Bash or WSL works)

### For full functionality

These aren't required to install or use the core skills, but enable additional features:

| Dependency | What needs it | Without it |
|------------|--------------|------------|
| `gh` (GitHub CLI) | `/plugins` curated registry access | Falls back to web search only -- still works, less comprehensive |
| Internet access | `/plugins` web search for tools | Registry-only if `gh` available, or manual recommendations |
| Git | `/audit` freshness checks, `/init` git recommendations | Hooks skip staleness checks; init omits git-specific advice |

> **Note**: The curated registry (103+ entries) lives in a separate repo ([Corsox-Tech/claude-tool-registry](https://github.com/Corsox-Tech/claude-tool-registry)) and is fetched on demand -- it is not bundled with this plugin.

## Platform Notes

The plugin works on Linux, macOS, and Windows. A few things to know:

- **Windows**: Hooks require bash (Git Bash or WSL). The skills automatically wrap MCP commands with `cmd /c` where needed.
- **macOS**: Works out of the box. No extra dependencies needed (hooks handle BSD `date` natively).
- **Linux**: Works out of the box.
- **File permissions**: If hooks don't fire after install, check that `hooks/*.sh` files are executable (`chmod +x hooks/*.sh`).

## Troubleshooting

**The stop hook keeps blocking my session exit**
The stop hook fires once, then allows exit on retry. If it loops, update to the latest version (fixed in v1.2.0). The hook is a no-op on projects without `.claude/status.md`.

**`/init` created files I don't want**
Say "undo init" in the same session. The plugin tracks every file it created in `.claude/.init-manifest` and can cleanly roll back without touching pre-existing files. Modified files are restored from `.backup` copies.

**The registry is unreachable during `/plugins`**
The curated registry requires `gh` CLI or internet access. If unreachable, the skill warns you and falls back to web search. Recommendations still work, just less curated.

**Hooks don't fire**
- Check that `hooks/*.sh` are executable: `chmod +x hooks/*.sh`
- On Windows, ensure Git Bash is available in your PATH
- Hooks only activate on projects with `.claude/status.md` -- they skip silently otherwise

**Something else?**
Open an issue at [github.com/Corsox-Tech/claude-autopilot/issues](https://github.com/Corsox-Tech/claude-autopilot/issues).

## License

MIT

## Author

[Corsox](https://github.com/Corsox-Tech)
