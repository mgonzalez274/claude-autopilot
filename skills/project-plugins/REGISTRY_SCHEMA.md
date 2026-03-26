# Tool Registry Schema
> Version: 2.0
> **Reference copy** -- The live registry is at `Corsox-Tech/claude-tool-registry/registry.json` (103+ entries). This file documents the schema for reference. It is NOT read during skill execution.

## Purpose
This document defines the schema for `registry.json` -- the curated tool registry that the project-plugins skill uses as its primary discovery source before web search.

## Where the Registry Lives
GitHub repo: `Corsox-Tech/claude-tool-registry`
Claude Code accesses it via GitHub CLI (`gh`) or by cloning/fetching the repo.

## Registry Structure
```
claude-tool-registry/
├── README.md                  ← What this is, how to contribute
├── registry.json              ← Master registry (machine-readable)
├── scope-docs/                ← MCP vs API scope documentation per service
│   ├── zoho.md
│   ├── cloudflare.md
│   ├── microsoft-365.md
│   └── github.md
├── reviews/                   ← Safety review notes per tool (when needed)
│   └── [tool-slug].md
└── sources.md                 ← List of upstream sources we pull from
```

## registry.json Schema

The file is a JSON array of tool entries. Each entry:

```json
{
  "slug": "cloudflare-mcp",
  "name": "Cloudflare MCP",
  "type": "mcp | skill | plugin | cli | api | package",
  "subtype": "official | community | commercial",
  "repo": "https://github.com/cloudflare/mcp",
  "install": "claude mcp add cloudflare -- npx @anthropic/claude-code-mcp cloudflare",
  "description": "Full Cloudflare API access including DNS, Workers, R2, Pages, etc.",
  "categories": ["dns", "infrastructure", "cdn", "email-deliverability", "hosting"],
  "project_types": ["webapp", "devops", "automation", "static-site"],
  "safety": "trusted | verified | community | unreviewed | flagged",
  "safety_reason": "Official Cloudflare repo, corporate maintainer",
  "stars": 2500,
  "last_verified": "2026-03-15",
  "scope_doc": "scope-docs/cloudflare.md",
  "overlaps_with": ["cloudflare-dns-analytics"],
  "overlap_notes": "cloudflare-mcp is comprehensive; dns-analytics adds reporting only",
  "platforms": ["claude-code", "claude-desktop"],
  "notes": "Requires Cloudflare API token with appropriate zone permissions",
  "added_by": "mateo | auto-import",
  "source": "https://github.com/quemsah/awesome-claude-plugins"
}
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `slug` | string | yes | Unique identifier, lowercase-kebab-case |
| `name` | string | yes | Human-readable display name |
| `type` | enum | yes | `mcp`, `skill`, `plugin`, `cli`, `api`, `package` |
| `subtype` | enum | yes | `official` (by Anthropic or the service vendor), `community`, `commercial` |
| `repo` | string | yes | GitHub URL, npm page, or documentation URL |
| `install` | string | no | Install command. Empty for APIs (no install -- just document endpoint) |
| `description` | string | yes | One-line description (≤150 chars) |
| `categories` | array | yes | Tags for matching against project needs. Use consistent values from the Categories list below |
| `project_types` | array | yes | Which project types benefit. Use values from: `webapp`, `wordpress`, `saas-platform`, `static-site`, `automation`, `devops`, `mixed`, `any` |
| `safety` | enum | yes | See Safety Ratings below |
| `safety_reason` | string | yes | One-line justification for the safety rating |
| `stars` | number | no | GitHub stars (null for non-GitHub tools) |
| `last_verified` | string | yes | Date the entry was last checked (YYYY-MM-DD) |
| `scope_doc` | string | no | Path to scope doc (for services with both MCP and API) |
| `overlaps_with` | array | no | Slugs of tools with overlapping functionality |
| `overlap_notes` | string | no | Brief comparison explaining the overlap |
| `platforms` | array | no | `claude-code`, `claude-desktop` (list each supported platform explicitly) |
| `notes` | string | no | Any additional context (auth requirements, limitations, etc.) |
| `added_by` | string | yes | Who added it: `mateo`, `auto-import`, `team-member-name` |
| `source` | string | no | Where this was discovered (awesome-list URL, Instagram post, etc.) |

### Install Command Formats
The `install` field varies by tool type. Use the appropriate format:
- **Plugins/Skills (marketplace)**: `/plugin marketplace add org/repo` -- this is real Claude Code syntax for marketplace-published tools
- **Plugins/Skills (from directory)**: `/plugin install name@claude-plugins-official` -- for plugins listed in Anthropic's official directory
- **Plugins/Skills (local)**: `/plugin add /path/to/skill-directory`
- **MCP servers**: `claude mcp add name -- npx @scope/package` or platform-specific setup
- **CLI tools**: `npm install -g package`, `pip install package`, `apt install package`, etc.
- **Packages**: `npm install package` or `pip install package` (project-local)
- **APIs**: Set to `null` -- APIs don't install, they're documented in credentials.md and scope-docs
- **Claude Code features**: `claude config set feature true` or enable in settings

Always verify install commands work on the target platform (Windows/Linux) before adding. If unsure, use a descriptive placeholder like `See repo README for install instructions`.

### Skill & Plugin Entry Guidance

For entries with `type: "skill"` or `type: "plugin"`, include these details in the `notes` field:
- **Skills**: Note the skill's line count (must be under 500), whether it has supporting files, and what trigger phrases activate it
- **Plugins**: Note what the plugin bundles (skills, hooks, agents, commands, MCP configs) and whether it requires any dependencies
- For both: note the context overhead (how many tokens it adds when loaded) if known or estimable
- `platforms` should reflect where the skill/plugin is installable (`claude-code` and/or `claude-desktop`)

### Safety Ratings

| Rating | Criteria | Recommendation Behavior |
|--------|----------|------------------------|
| `trusted` | Anthropic contributor in repo, OR official vendor repo (Cloudflare, Microsoft, etc.), OR in Anthropic's official plugin directory | Recommend freely |
| `verified` | 500+ GitHub stars, active maintenance (commits in last 3 months), multiple contributors, no open security issues | Recommend freely |
| `community` | Under 500 stars but actively maintained, code reviewed and no red flags found | Recommend with note: "Community tool -- reviewed, no issues found" |
| `unreviewed` | Newly added, not yet inspected | **Never recommend.** Show in a separate "Pending Review" section if relevant to the project |
| `flagged` | Known issues, abandoned (no commits in 6+ months), suspicious code patterns, or security concerns found | **Never recommend.** Note the issue if the user specifically asks about it |

### Categories (use these consistently)

**Development**: `code-review`, `testing`, `formatting`, `linting`, `debugging`, `git`, `ci-cd`, `deployment`, `monitoring`, `observability`, `documentation`, `database`, `frontend`, `backend`, `fullstack`, `mobile`, `mcp-development`

**Infrastructure**: `dns`, `hosting`, `cdn`, `ssl`, `email-deliverability`, `cloud-aws`, `cloud-gcp`, `cloud-azure`, `containerization`, `serverless`, `infrastructure`, `caching`

**Platforms**: `zoho`, `microsoft-365`, `google-workspace`, `wordpress`, `shopify`, `stripe`, `github`, `slack`, `notion`, `jira`

**Commerce**: `ecommerce`, `payments`

**Content & Marketing**: `seo`, `copywriting`, `image-generation`, `video`, `social-media`, `analytics`, `reporting`, `email-marketing`

**Design**: `design`, `forms`

**Productivity**: `project-management`, `task-tracking`, `note-taking`, `calendar`, `communication`, `messaging`, `chatbot`, `memory`, `context-management`

**AI/Agent**: `multi-agent`, `orchestration`, `prompt-engineering`, `rag`, `embeddings`, `model-tools`

**Security**: `security`, `vulnerability-scanning`, `code-audit`, `penetration-testing`, `secrets-management`

**Skills & Plugins**: `skill-scaffolding`, `skill-auditing`, `skill-discovery`, `plugin-bundle`, `project-setup`, `workflow-automation`, `code-generation`, `agent-framework`

**Domain-specific**: `legal`, `finance`, `healthcare`, `education`, `lms`, `research`, `data-science`

---

## Scope Docs Schema

For services where both MCP and API exist, create `scope-docs/[service].md`:

```markdown
# {Service Name}: MCP vs API Scope

## MCP: {mcp-name}
**Install**: {command}
**What it CAN do**:
- {capability 1}
- {capability 2}

**What it CANNOT do**:
- {limitation 1}
- {limitation 2}

## API: {api-name}
**Endpoint**: {base URL}
**Auth**: {method}
**What it CAN do**:
- {capability 1}
- {capability 2}

**What it CANNOT do / Limitations**:
- {limitation 1}

## Recommendation
{When to use MCP, when to use API, when to use both}
```

---

## How the Plugins Skill Uses This

1. **Fetch registry.json** from the Corsox-Tech repo (via `gh` CLI or raw GitHub URL)
2. **Filter** entries by `project_types` and `categories` matching the needs profile from Step 1
3. **Exclude** entries with `safety` = `unreviewed` or `flagged`
4. **Check overlaps**: If multiple filtered entries have `overlaps_with` references to each other, present them as alternatives with the `overlap_notes`
5. **Check scope docs**: If a filtered entry has a `scope_doc`, read it to verify the tool actually covers what the project needs
6. **Then run web searches** (Step 2b categories A-G) for tools NOT in the registry
7. **Merge results**: Registry entries get priority (pre-vetted), web search results are supplementary

---

## Maintenance Workflow

### V1 (Manual)
- Mateo adds entries manually from awesome-lists, Instagram/TikTok finds, project experience
- New entries go in as `"safety": "unreviewed"` unless from a trusted source
- Mateo or Claude reviews unreviewed entries (download repo, inspect code, check stars/contributors)
- Update `last_verified` dates when checking entries

### V2 (Semi-automated -- future)
- A Claude Code skill (`/registry-update`) that:
  1. Fetches current star counts for all entries via GitHub API
  2. Flags entries where stars dropped or repo was archived
  3. Checks the awesome-lists for new entries not in the registry
  4. Presents a diff for Mateo to approve before updating

### V3 (Automated -- future)
- GitHub Action that runs weekly:
  1. Scrapes upstream sources (awesome-lists)
  2. Checks repo health metrics
  3. Opens a PR with proposed additions/updates
  4. Mateo reviews and merges
