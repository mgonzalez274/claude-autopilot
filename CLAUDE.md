# claude-autopilot — Plugin Development

## Publishing

This repo is the **source project**. It's published to GitHub at `https://github.com/mgonzalez274/claude-autopilot`.

After any changes: commit, push to GitHub. Users (including locally) update via Claude Code's plugin update flow -- never manually copy files to `~/.claude/plugins/`.

## Structure

- `hooks/` — SessionStart and Stop hook scripts (bash)
- `commands/` — Slash command definitions that route to skills
- `skills/` — Core skill definitions (project-init, project-audit, project-plugins)
- `.claude-plugin/` — Plugin and marketplace metadata (plugin.json, marketplace.json)

## Rules

- Always bump the version in BOTH `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` when making changes
- Keep `skill_versions` in plugin.json in sync with the version declared in each SKILL.md header
- Hook scripts must be cross-platform (Linux, macOS BSD, Windows Git Bash)
- Test hooks with `bash -n <script>` for syntax before committing
