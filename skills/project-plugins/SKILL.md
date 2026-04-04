# Skill: project-plugins
> Version: 4.2

## Purpose
Discover, evaluate, and recommend tools across 7 categories -- MCP servers, direct APIs, CLI tools, npm/pip packages, Claude Code features, standalone skills, and plugins -- for a project. Uses web search to get current information -- never relies solely on training data.

## When to Use
- During project initialization (called by project-init Phase 7)
- When the user asks "what plugins should I use", "are there any tools for X", or similar
- When starting a new phase of a project that involves different integrations
- When the user encounters a limitation and there might be a plugin that solves it
- Periodically (every 4-6 weeks) to check for new relevant tools
- **Ordering**: If called during init, runs after project structure is created (Phase 7).

---

## Curated Registry
This skill uses a curated tool registry at `Corsox-Tech/claude-tool-registry` as its **primary** discovery source (Step 2a), with web search (Step 2b) only for gaps not covered by the registry. The registry contains pre-vetted entries with safety ratings, overlap detection, and MCP scope documentation. To check the current entry count, read `registry.json` directly -- do not rely on hardcoded counts in documentation.

> **Reference**: `REGISTRY_SCHEMA.md` in this skill folder documents the registry JSON schema. The live registry lives at `Corsox-Tech/claude-tool-registry/registry.json` -- that is the source of truth.

---

## DISCOVERY PROCESS

### Step 1: Understand Project Needs

Before searching, build a needs profile from:

1. **Project type and tech stack** (from CLAUDE.md or discovery)
2. **External services and APIs** involved
3. **Current integrations** already set up (MCP connectors, SSH, API keys)
4. **Current pain points** or workflow bottlenecks the user has mentioned
5. **Upcoming work** that might need new tools

Categorize needs into:
- **Platform access**: Does Claude need to talk to Zoho, AWS, GitHub, Google, Slack, etc.?
- **Development workflow**: Linting, testing, building, deploying, database access?
- **Content/asset creation**: Image generation, email building, PDF creation, document formatting?
- **Research/analysis**: Web search, data analysis, SEO tools, competitive analysis?
- **Project management**: Task tracking, time tracking, team communication?
- **Domain-specific operations**: DNS management, email deliverability, server administration, monitoring, etc.?

6. **Installed tool inventory** -- scan all three configuration scopes to build a full picture of what's already loaded:
   - **User global**: `~/.claude/settings.json` → `mcpServers` (loads on EVERY project)
   - **Project shared**: `.mcp.json` in project root (loads for all collaborators)
   - **Project local**: `.claude/settings.local.json` → `mcpServers` (loads for this user only)

   For each installed tool, note: which scope it's in, whether it's relevant to this project's type/stack, and whether it conflicts or overlaps with another installed tool. This inventory feeds into the Scope & Cleanup section of Step 5.

### Step 2a: Check Curated Registry (MANDATORY -- complete before any web search)

> **HARD GATE**: DO NOT proceed to Step 2b until Step 2a is complete. The registry contains pre-vetted tools with safety ratings, overlap notes, and scope docs. Skipping it wastes search budget on tools already curated and misses critical intelligence like overlap warnings.

**1. Access the registry** -- use the most efficient method available:

- **If `views/` directory exists** in the registry repo: Read `views/_manifest.json`, select the view matching the project type, read only that file. Filter by categories within the view. *(Phase 2 scaling -- auto-detected when available.)*
- **If `registry-index.md` exists** in the registry repo: Read the compact markdown table, identify relevant slugs by scanning `project_types` and `categories` columns against the needs profile, then run `python filter_registry.py --slugs "slug1,slug2,..."` in the registry repo to extract only matching full entries. *(Phase 1 scaling -- compact markdown table vs the full registry JSON.)*
- **Fallback** (neither index nor views exist): Read the full `registry.json` via one of:
  - Local clone of the registry repo, if available (fastest -- check for a local `claude-tool-registry` or `corsox-claude-skills` directory)
  - Remote raw content: `gh api repos/Corsox-Tech/claude-tool-registry/contents/registry.json -H "Accept: application/vnd.github.raw"`
  - Direct URL: fetch `https://raw.githubusercontent.com/Corsox-Tech/claude-tool-registry/main/registry.json`
  - **Do NOT use** `gh api` without the raw header -- it returns base64-encoded content wrapped in metadata, not usable JSON.

**2. Filter entries** by `project_types` and `categories` matching the needs profile from Step 1. When filtering by project type, also consider adjacent types -- e.g., `static-site` projects often benefit from `webapp`-typed frontend/design tools, and `saas-platform` projects benefit from `webapp`-typed tools. Use category matches as a secondary signal when project_type is a near-miss.

**3. Exclude entries** with `safety` = `unreviewed` or `flagged`.

**4. Resolve overlaps** -- when filtered entries reference each other via `overlaps_with`, classify each overlap cluster into one of three cases. **Core rule: no silent drops** -- every registry-matched entry MUST appear somewhere in the final output (tier table, overlap analysis, or "Not Recommended" with reason).

   **Case 1 -- Clear winner**: One tool is strictly better for this project's needs. Criteria: the project's specific needs fall entirely within one tool's capabilities, OR one is a strict superset and the project needs the extras, OR one has a critical advantage (official vs community, permissive vs restrictive license, actively maintained vs stale). Place the winner in the appropriate tier. Place the other(s) in "Not Recommended" with a one-line reason referencing the winner.

   **Case 2 -- Complementary**: Tools cover different aspects of the same need (different layers, different capabilities). Both are useful simultaneously. Place both in the appropriate tier with a note explaining why both are needed (e.g., "WordPress MCP Adapter for site operations + Claude WordPress Skills for code auditing").

   **Case 3 -- Genuine alternatives**: Tools cover the same need with comparable merit and no clear winner. This triggers **Step 4b (Comparative Analysis)** -- do not resolve here. Tag the cluster for Step 4b and continue. These will be presented in a dedicated comparison section.

   **Tie-breaking signals** (when classifying is borderline): higher safety rating > permissive license (MIT/Apache over GPL/ELv2/Commons Clause) > lower context overhead > better platform match > more recent maintenance. If a tool has a restrictive license, note it -- it may affect commercial use.

**5. Check scope docs** -- if filtered entries have a `scope_doc`, read it to verify the tool covers what the project actually needs.

**6. Check XLSX for pending entries** -- if `docs/registry-overview.xlsx` exists in the registry repo, check for rows with Status=`pending`. If found, note them as "pending registry review -- not yet vetted" and offer to process them (research, add to registry.json, regenerate XLSX).

**7. Record coverage** -- note which needs from Step 1 are already covered by registry matches. These needs **do not require web searching in Step 2b** -- skip those categories entirely.

**8. Carry forward** matched entries as **pre-vetted results** with priority over any web search findings.

**9. Output checkpoint** -- before proceeding to Step 2b, output a brief summary: how many registry entries matched, which needs are covered, and which needs still have gaps requiring web search. This makes the hard gate verifiable and helps the user see registry value.

**Registry failure handling:**
- **Repo unreachable** (network error, `gh` not configured, rate-limited): Warn the user that the curated registry was unavailable, then proceed to Step 2b. Web search is the fallback -- the skill works without the registry, just less efficiently.
- **JSON parse failure** (registry.json is malformed or truncated): If registry.json cannot be parsed as a valid JSON array, warn: "Registry JSON is malformed -- skipping registry, using web search only." Do NOT attempt to partially parse or silently return no results. Proceed to Step 2b.
- **Stale entries**: When filtering, check each entry's `last_verified` date. If older than 6 months, append "(last verified {date} -- may be outdated)" to the recommendation. If older than 12 months, downgrade the entry's effective safety rating by one tier (e.g., `verified` → `community`) and note: "Entry not verified in over a year -- confirm tool still exists before installing."

---

### Step 2b: Search Web for Gaps

Search the web **only for needs NOT already covered by registry matches** from Step 2a. Do not rely on training data. Search across ALL tool categories -- not just MCP servers.

> **Search budget**: Spend no more than **8--10 web searches** per discovery run. **Hard ceiling: 12 searches absolute maximum** -- if you reach 12 without covering all gaps, stop and note the remaining gaps in the Tooling Gaps section. If the registry covered most needs, 3--5 searches may suffice. Prioritize searches that address actual gaps from Step 1 that the registry didn't cover. Skip categories where the registry already has good matches. If the project's needs span only 1--2 categories, 4--6 searches is enough -- do not run all 25 queries for every project.

There are seven categories of tools Claude can use. Search for ALL that are relevant to the project:

#### Category A: MCP Servers
Persistent connections that give Claude live access to external platforms. Includes locally-installed MCPs (via `npx`/`uvx`) and remote/cloud-hosted MCPs (accessed via URL — no local install). Also includes first-party OAuth integrations available through Claude Code's built-in auth flow (check `claude.ai` and Anthropic docs for current integrations).

**Searches:**
1. Search: `site:github.com anthropics MCP server` -- official Anthropic MCP servers
2. Search: `site:github.com modelcontextprotocol servers` -- official MCP server repos
3. Fetch: `https://mcp.so` or `https://mcpservers.org` -- community MCP directories *(supplementary sources -- may be down or stale; GitHub and npm searches are the reliable backbone)*
4. Search: `"MCP server" [specific-service]` (e.g., `"MCP server" Zoho`, `"MCP server" Cloudflare`)
5. Search: `site:npmjs.com claude MCP [domain]` -- npm-published MCP servers

#### Category B: Direct APIs (via curl/fetch)
REST APIs Claude can call directly from bash using curl, wget, or scripts. These don't need MCP -- Claude makes HTTP requests directly. Many services have APIs even when no MCP server exists.

**Searches:**
6. Search: `[specific-service] REST API documentation` (e.g., `Google Postmaster Tools API`, `MXToolbox API`, `Cloudflare API`)
7. Search: `[domain-task] API free` (e.g., `email deliverability API`, `DNS lookup API`, `blacklist check API`)
8. For each service identified in Step 1, check if it has a public API -- search: `[service-name] API developer documentation`

**When to recommend APIs vs MCP**: If both exist, prefer MCP (richer integration). If no MCP exists but an API does, recommend the API with a note on how Claude would use it (curl commands, auth method). If the API requires paid access, note the cost.

#### Category C: CLI Tools
Command-line utilities Claude can install and run directly. Many domain-specific tasks have dedicated CLI tools that are more reliable than API calls.

**Searches:**
9. Search: `[domain] command line tool` (e.g., `DNS lookup CLI tool`, `email SMTP test CLI`, `SSL certificate checker CLI`)
10. Search: `[task] CLI github` (e.g., `DMARC validation CLI`, `SPF checker CLI`)
11. For development projects: search for linters, formatters, test runners, build tools specific to the stack

**Common CLI tools by domain** (search to confirm availability and current versions):
- DNS/Email: `dig`, `nslookup`, `swaks` (SMTP testing), `opendkim-testkey`, `spfquery`
- Web/SEO: `lighthouse`, `pagespeed`, `curl`, `wget`
- Infrastructure: `aws-cli`, `gcloud`, `az` (Azure), `terraform`, `kubectl`
- Development: `eslint`, `prettier`, `phpcs`, `wp-cli`, `composer`

#### Category D: npm/pip Packages & Libraries
Packages Claude can install and use in scripts for data processing, analysis, automation, or specialized tasks.

**Searches:**
12. Search: `site:npmjs.com [domain-task]` (e.g., `site:npmjs.com dns lookup`, `site:npmjs.com email validation`)
13. Search: `site:pypi.org [domain-task]` (e.g., `site:pypi.org dmarc parser`, `site:pypi.org spf check`)
14. Search: `[task] python library` or `[task] node package` for domain-specific needs

**When to recommend packages**: When Claude needs to process data, parse formats, generate reports, or automate multi-step operations that are too complex for raw bash commands.

#### Category E: Built-in Claude Code Features
Built-in Claude Code features, slash commands, hooks, and configuration options the user might not know about.

**Searches:**
15. Fetch: `https://docs.anthropic.com` -- check for recently documented features
16. Search: `site:anthropic.com claude code features {current_year}` -- recently shipped features
17. Search: `site:anthropic.com claude desktop MCP {current_year}` -- desktop-specific integrations
18. Search: `site:github.com "awesome-claude-code"` -- community curated lists

**What to look for**: New slash commands, hooks (pre-commit, post-push), built-in tool integrations, configuration options, experimental features, recently added capabilities.

#### Category F: Skills
Standalone SKILL.md files that extend Claude Code's capabilities for specific domains. Installable to `~/.claude/skills/` or via a marketplace.

**Searches:**
19. Fetch: `https://github.com/anthropics/skills` -- official Anthropic skills repository
20. Search: `site:github.com claude code skill [domain]` -- domain-specific skills
21. Search: `site:github.com "awesome-claude-skills" OR "awesome-agent-skills"` -- curated skill lists

**What to look for**: Skills that automate domain-specific workflows, enforce project conventions, or provide expert guidance for the project's tech stack. Check the skill's line count (must be under 500 lines) and whether it loads supporting files that add context overhead.

#### Category G: Plugins & Agent Frameworks
Installable packages that bundle skills, hooks, agents, MCP servers, and/or commands into a single distributable unit. Plugins are the primary distribution format for Claude Code extensions. This category also includes agent frameworks and multi-agent orchestration tools (e.g., Claude Agent SDK, custom agent definitions) that extend Claude's ability to delegate or coordinate work.

**Searches:**
22. Search: `site:github.com claude code plugin [domain]` -- domain-specific plugins
23. Search: `site:github.com "claude-plugin" OR ".claude-plugin"` -- plugin repos by convention
24. Fetch: claudecodeplugins.io or similar community plugin directories *(supplementary -- may be stale)*

**What to look for**: Plugins that bundle multiple related capabilities (e.g., a testing plugin with skills + hooks + commands). Check plugin.json for what's included. Prefer plugins over individual skills when the project needs the full bundle. For agent frameworks, check whether the project needs multi-agent coordination or if single-session Claude is sufficient.

#### General
25. Search: `site:github.com "awesome-mcp-servers"` -- curated MCP lists (but remember to also check other categories)

**Handling search failures:** Some URLs may be down or return unhelpful results. Skip broken URLs and continue. Do not report a URL failure as "no tools found" -- rely on GitHub, npm, and pypi searches as the reliable backbone.

**VERIFY before including in output**: For every web-discovered tool, verify it actually exists by fetching its repo URL or homepage before including it anywhere in the output -- including "Not Recommended". A hallucinated tool in any section undermines trust. Do not mention a tool based solely on a search snippet or training data -- confirm the URL resolves, the repo is not archived, and the project is not abandoned. If you cannot verify a tool, omit it entirely.

**CRITICAL: Do not stop after finding MCP servers.** For every need identified in Step 1, check ALL seven categories. A project might need an MCP server for Cloudflare (Category A), a direct API for Google Postmaster Tools (Category B), `dig` and `swaks` CLI tools for DNS testing (Category C), a Python DMARC parser for report analysis (Category D), Claude Code hooks for auto-formatting (Category E), a code-review skill for consistent PR reviews (Category F), and a testing plugin that bundles test skills + hooks + commands (Category G).

### Step 3: Evaluate and Categorize

For each discovered tool, evaluate:

1. **Registry cross-check**: Is this tool already in the registry under a different slug or name? Search the registry results from Step 2a before evaluating further -- avoid duplicate recommendations.
2. **Relevance**: Does it solve an actual need for THIS project? (not just "cool to have")
3. **Maturity**: Is it maintained? When was the last update? Are there known issues?
4. **Source**: Official, verified partner, or community? (note trust level)
5. **Overlap**: Does it duplicate something already set up or already recommended from the registry?
6. **Cost**: Free, freemium, paid? Any API costs?
7. **Tool type**: MCP server, API, CLI tool, package, Claude Code feature, skill, or plugin?
8. **Context overhead**: Large plugins/skills can consume significant context window. If a tool's `notes` field warns about context overhead or instability, include that warning in the recommendation. For broad skill bundles, note whether the project actually needs the full bundle or just a subset.
9. **Context cost estimate**: Estimate the token cost each tool adds to the context window when loaded. Use the approximation ~1 token per 4 characters (English text with Claude's tokenizer -- users can verify with `anthropic tokenizer` or by checking character count / 4).
   - MCP servers: ~200-500 tokens **per MCP server** at registration (each server registers its tool schemas into context). Servers with many tools (10+) trend toward the higher end. To estimate more precisely, count the number of tools a server exposes and budget ~30-50 tokens per individual tool.
   - Skills: ~100 tokens at startup (name + description only), full SKILL.md loads on activation (character count / 4).
   - Plugins: Sum of their bundled skills + hooks. A plugin with 3 skills and 2 hooks might add ~300 tokens at startup, ~2,000+ when active.
   - CLI tools / APIs / packages: ~0 tokens (no context cost -- they run externally)
   - Existing reference files: character count / 4 across all `.claude/` files. Quick proxy by project size: small ~2,000 tokens, medium ~3,500 tokens, large ~5,500 tokens.
   Track a running total across all recommendations. Instruction-following quality degrades as loaded instructions approach ~20% of context window capacity (200K standard = ~40K tokens, 1M Opus = ~200K tokens) -- this is an empirical guideline, not a hard cliff. Warn if the combined recommendations would push past this threshold when combined with the project's existing reference files. Present the estimate as approximate: "~{N} tokens (estimate -- actual may vary by ±30%)".
10. **Compatibility check**: Before recommending, verify:
   - **Node.js version**: If the tool requires a minimum Node version, check against `.nvmrc` or `package.json` engines. If neither exists, note: "Node version requirement unchecked -- no `.nvmrc` or engines field found."
   - **OS**: If the tool is OS-specific (e.g., Linux-only CLI), check against the user's platform. On `win32`, flag tools that require WSL or have no Windows support.
   - **Conflicts**: Check if the tool conflicts with anything already installed (same port, overlapping MCP tool names, incompatible dependency versions).
   - **Plan tier**: If the tool requires a specific Claude plan (e.g., Max for extended context), note the requirement.

Categorize into tiers:

**Essential** -- Project will have significant friction without these. Examples:
- MCP connector for a primary service (Zoho MCP for a Zoho project)
- CLI tool critical to the domain (`dig`/`swaks` for email deliverability)
- Direct API for a service with no MCP (Google Postmaster Tools API)
- GitHub CLI access for a code project with CI/CD

**Recommended** -- Will noticeably improve workflow or quality. Examples:
- Database MCP for a project with frequent DB queries
- npm package for parsing domain-specific data formats
- SEO CLI tools for a content-focused site project

**Optional** -- Nice to have, use if the user wants to optimize further. Examples:
- Slack MCP for team communication (if team is small, might not be needed)
- Python library for generating reports that could also be done manually

**Not recommended** -- Tools that seem relevant but aren't a good fit. Briefly explain why.

**Tier examples for skills and plugins:**
- Essential: A code-review skill for a team project with strict PR standards
- Recommended: A testing plugin that bundles test skills + pre-commit hooks for a project with growing test coverage
- Optional: A documentation skill for a project where docs are nice-to-have but not critical

### Step 4: Check for Custom Skill Opportunities

Evaluate whether the user should CREATE custom skills for this project. Since Claude can't know the user's repetitive workflows from a single session, **ask the user directly**:

- "Are there any multi-step workflows you repeat frequently? (e.g., creating a new page always requires X, Y, Z in a specific order)"
- "Are there tasks where consistency matters -- where the output should follow the same format/structure every time?"
- "Any procedures that involve 5+ steps that you'd want a fresh Claude session to handle correctly without re-explaining?"

A custom skill is worth creating when:

1. **Repeated pattern**: A multi-step process runs more than 3 times (e.g., "every time I create a new page, I need to do X, Y, Z in this specific order")
2. **Complex procedure**: A task requires reading specific files, following a checklist, and producing specific output (e.g., "deploy to staging" involves 8 steps)
3. **Quality consistency**: A task needs to produce consistent output every time (e.g., "create email template" should always follow brand guidelines, use specific HTML structure)
4. **Onboarding**: If another person (or fresh Claude session) needs to do something that requires context that would otherwise need to be re-explained

For each suggested custom skill:
- Describe what it would do
- Estimate the effort to create it (low/medium/high)
- Explain the payoff (how much time/tokens it saves over N uses)
- Offer to create it right now or add it to the task backlog

### Step 4b: Comparative Analysis (for Case 3 overlaps)

If Step 2a.4 tagged any overlap clusters as Case 3 (genuine alternatives), research each cluster now.

> **Comparison search budget**: Up to **2 web searches per Case 3 cluster**, capped at **6 comparison searches total**. This budget is separate from the Step 2b gap-search ceiling of 12. Prioritize clusters where the project will definitely need one of the tools.

For each Case 3 cluster, research the alternatives on these 6 dimensions:

| Dimension | What to check |
|-----------|---------------|
| **Scope** | What each tool can and cannot do -- feature overlap vs unique capabilities |
| **Maintenance** | Last commit/release, release frequency, open issue count, bus factor (single maintainer vs team) |
| **Community** | Stars, weekly downloads/installs, GitHub Discussions/issues activity. For non-GitHub tools (commercial, platform-native), search `"[tool name]" review` or `"[tool name]" experience` to find community sentiment |
| **Integration** | Setup complexity, auth requirements, token/context cost, platform support (Claude Code vs Desktop) |
| **License** | MIT/Apache (permissive) vs GPL/ELv2/Commons Clause (restrictive) -- note commercial implications |
| **Cost** | Free, freemium, paid tiers -- note if the free tier covers the project's needs |

**Search strategy**: For each cluster, search `"[tool-a]" vs "[tool-b]" review {current_year}` and check the tools' GitHub issues/discussions for known problems. For commercial tools without GitHub repos, search `"[tool name]" review` or `"[tool name]" alternative` to find community sentiment.

The comparison results feed into the **Overlap Analysis** section of the Step 5 output template.

---

### Step 5: Present Recommendations

Format output using the template below. **The header block is REQUIRED** -- never skip it. It anchors the recommendations to a specific project and date, making them reviewable and reproducible.

```markdown
## 🔌 Plugin & Tool Recommendations: {Project Name}
**Searched on**: {date}
**Project type**: {type}
**Current integrations**: {list what's already set up, or "None" if none}

### Essential
| Tool | Type | What It Does | Why You Need It | Install / Access | Source |
|------|------|-------------|-----------------|------------------|--------|
| {name} | MCP / API / CLI / Package / Feature / Skill / Plugin | {one-line description} | {one-line project-specific reason} | {install command, API docs URL, or setup link} | Registry / Web |

### Recommended
| Tool | Type | What It Does | Why It Helps | Install / Access | Source |
|------|------|-------------|-------------|------------------|--------|
| {name} | ... | ... | ... | ... | Registry / Web |

### Optional
| Tool | Type | What It Does | Nice-to-Have Because | Install / Access | Source |
|------|------|-------------|---------------------|------------------|--------|
| {name} | ... | ... | ... | ... | Registry / Web |

### Not Recommended (considered but skipped)
- {tool}: {why it's not a good fit for this project -- if dropped due to overlap, name the winner}

### ⚖️ Overlap Analysis: {Domain} Tools
{Include one section per Case 3 cluster from Step 4b. Omit if no Case 3 clusters exist.}

| Dimension | {Tool A} | {Tool B} | {Tool C (if any)} |
|-----------|----------|----------|-------------------|
| **Scope** | {what it does / unique features} | ... | ... |
| **Maintenance** | {last release, commit freq, contributors} | ... | ... |
| **Community** | {stars, downloads, sentiment} | ... | ... |
| **Integration** | {setup effort, auth, context cost} | ... | ... |
| **License** | {license type, commercial implications} | ... | ... |
| **Cost** | {pricing model} | ... | ... |

**For this project**: {1--2 sentence recommendation explaining which tool fits best for THIS project and why, or "both are viable -- choose based on X"}

### 🛠️ Custom Skills to Create
| Skill | Purpose | Effort | Payoff |
|-------|---------|--------|--------|
| {name} | {what it automates} | {low/med/high} | {saves X per use} |

### Context Cost Summary
**Estimated token overhead from recommendations**: ~{total} tokens
- Already loaded (existing tools): ~{existing} tokens
- New recommendations (Essential + Recommended): ~{new} tokens
- Combined: ~{combined} tokens / ~{threshold} token threshold ({percentage}%)
{If over 80% of threshold: "⚠️ Combined tool load is high. Consider deferring Optional tools or choosing lighter alternatives."}
{If under 50%: "Context budget is healthy -- room for additional tools if needed."}

### Tooling Gaps
{List any needs from Step 1 where no good tool exists in any category. Be explicit about what's missing and what the workaround is (e.g., "No MCP or API for Exchange Online administration -- requires manual access to Exchange admin center or local PowerShell")}

### 🧹 Scope & Cleanup
{Generated from the installed tool inventory in Step 1.6. Omit this section if no issues found.}

**Irrelevant tools loaded** (user-global MCPs that don't match this project):
| Tool | Scope | Why It Doesn't Belong | Action |
|------|-------|----------------------|--------|
| {name} | User global | {e.g., "Prisma MCP -- this project has no database"} | Disable or move to the project that needs it |

**Conflicting/overlapping tools** (multiple tools doing the same job):
| Tools | Conflict | Recommendation |
|-------|----------|----------------|
| {tool-a} vs {tool-b} | {what overlaps} | {keep one, remove the other, or explain why both are needed} |

**Scope misplacements** (tools at the wrong scope):
| Tool | Current Scope | Recommended Scope | Why |
|------|--------------|-------------------|-----|
| {name} | User global | Project (.mcp.json) | {e.g., "Only used in this project's stack"} |

### Already Set Up ✅
{List current integrations that are working well -- confirm they're still the right tools}
```

**Anti-drop verification** (do this before presenting output): Cross-check the final output against the registry matches from Step 2a. Every slug that matched in Step 2a.2 must appear in at least one of: Essential, Recommended, Optional, Not Recommended, or Overlap Analysis. If any are missing, add them to the appropriate section before presenting. This enforces the "no silent drops" rule.

### Step 6: Install Approved Tools

After the user reviews recommendations:

1. **Ask which to install** (or auto-install if user says "install all essential")
2. **For each installation** (varies by tool type):
   - **MCP servers**: Install to **project-scoped `.mcp.json` by default**. Only install to user-global (`~/.claude/settings.json`) if the user explicitly requests it or the tool is genuinely needed across all projects. If the user says "install for all projects", use user-global. If the platform is `win32`, apply `cmd /c` wrapping for `npx`/`uvx`/`pnpm`/`bunx` commands (see project-init Phase 7 for the pattern).
   - **APIs**: Document the endpoint, auth method, and example curl command in `.claude/credentials.md`
   - **CLI tools**: Install via apt, brew, npm -g, pip, or the tool's installer
   - **Packages**: Install via npm/pip into the project; note in `.claude/architecture.md` if it becomes a project dependency
   - **Claude Code features**: Enable in settings or configuration; document in CLAUDE.md if it affects workflow
   - **Skills**: Install to `~/.claude/skills/` (user-global) or `.claude/skills/` (project-scoped). Verify SKILL.md exists and is under 500 lines.
   - **Plugins**: Install via `claude plugin add <source>`. Verify plugin.json is valid and skills/hooks load correctly.
   - For all: Add auth info to `.claude/credentials.md` if needed
   - For all: Update CLAUDE.md integrations section if relevant
3. **Verify each installation** and produce a verification report:
   - **CLI tools**: Run `--version` or equivalent
   - **MCP servers**: Test a basic operation (e.g., list available tools)
   - **APIs**: Make a lightweight test call (health endpoint or list call)
   - **Packages**: Verify import/require succeeds
   - **Claude Code features**: Confirm the setting took effect
   - **Skills**: Verify SKILL.md exists at expected path and is under 500 lines
   - **Plugins**: Verify plugin.json is valid and plugin appears in installed list

   **Verification report** (present after all installations):
   ```
   ## Installation Verification
   | Tool | Type | Status | Details |
   |------|------|--------|---------|
   | {name} | MCP | ✅ Pass | Connected, {N} tools available |
   | {name} | CLI | ❌ Fail | Command not found -- check PATH |
   ```
   For each failure: include the error, a suggested fix, and whether it blocks other tools. Do not move on from a failed essential tool without user acknowledgment.
4. **For custom skills to create**: Either create them now or add to tasks.md

### Step 7: Contribute Web-Discovered Tools to Registry

After installing tools that were found via web search (Step 2b) and **not** already in the registry:

1. **Offer to add** the tool to `Corsox-Tech/claude-tool-registry` with appropriate metadata (slug, safety rating, categories, etc.)
2. If approved, add the entry to `registry.json` following the schema in `REGISTRY_SCHEMA.md`
3. **Run the three-step validation** in the registry repo: `python validate_registry.py` (must pass), `python generate_index.py`, `python docs/generate_xlsx.py`
4. Commit and push the registry update

---

## PERIODIC REFRESH

When running as a periodic check (not initial setup):

1. **Check registry XLSX for pending entries** -- if `docs/registry-overview.xlsx` has rows with Status=`pending`, process them first: research the links, create full registry.json entries, mark XLSX rows as `synced`, and regenerate XLSX via `python docs/generate_xlsx.py`
2. Re-fetch the curated registry and check for new entries, updated entries, or changed safety ratings since last check
3. Search for new tools released since last check across ALL categories (use date-bounded search queries) -- respect the search budget (8--10 max)
4. Check if any currently-installed tools have updates or deprecation notices
5. Re-evaluate current tool set against any project scope changes
6. Check Anthropic's official channels for new Claude Code features or MCP servers (the user has noted that Claude sometimes doesn't know about recently released features -- always verify with a web search)
7. Check if any "Tooling Gaps" from the last run now have solutions
8. **Contribute new finds** -- any web-discovered tools worth keeping should be offered for addition to the registry (Step 7). After adding, run the three-step validation (validate, index, XLSX).
9. Present only what's changed since last check -- don't re-list everything
10. **Record refresh state** in the project's `status.md`: `Last plugin check: {date}, {count} tools evaluated, {count} new recommendations`

---

## IMPORTANT NOTES

- **Always search the web.** Your training data about available plugins is likely outdated. New tools are released frequently.
- **Search ALL 7 tool categories, not just MCP.** MCP servers are one integration method. APIs, CLI tools, packages, Claude Code features, skills, and plugins are equally valid. A project might need tools from every category.
- **Be specific to the project.** Don't recommend a database MCP for a static site project. Every recommendation should have a project-specific justification.
- **Check platform compatibility.** The user works on both Claude Code (CLI) and Claude Desktop. Some tools work differently across platforms -- note any platform-specific limitations.
- **Don't oversell.** If the project genuinely doesn't need many tools, say so. But DO search thoroughly across all categories before concluding that -- the user has noted that Claude often under-recommends when it doesn't actively search.
- **Windows/Linux awareness.** Some tools are OS-specific. Ask or detect the user's OS if relevant.
- **Document the gaps.** When no tool exists for a need, say so explicitly in the "Tooling Gaps" section. This is valuable information -- the user can then decide whether to build a custom solution, use manual workarounds, or wait for a tool to be released.
