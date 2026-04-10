# Claude Autopilot — Guided Improvement Prompts

Run each prompt separately through your skill-creator. Each is self-contained and scoped to one area.

---

## Prompt 1: README Completeness

```
Read the README.md for this plugin. Then read every skill file, every hook script, and the plugin.json metadata.

Now answer these questions:

1. If a new user only read the README, what questions would they still have before installing? What's missing that would give them confidence to try it?

2. Compare the feature list in the README against what the skills actually do. Are there capabilities the skills have that the README doesn't mention? Are there claims in the README that overstate what the plugin delivers?

3. A user installs this plugin on macOS and runs /init on a new project. Another user installs it on Windows with Git Bash. A third uses Linux. Read the hook scripts — would each user have the same experience? Does the README set accurate expectations for all three?

4. The plugin loads skills that are 295-432 lines each. What impact does this have on context window usage? Would a user know about this cost before installing?

5. If something goes wrong — the stop hook keeps firing, or /init creates files in the wrong place — where in the README would the user find help? Is there a troubleshooting section?

Based on your findings, propose specific additions or changes to the README. Show the exact markdown you'd add.
```

---

## Prompt 2: Cross-Platform Hook Robustness

```
Read both hook scripts in the hooks/ directory (pre-session.sh and stop-session.sh).

For each script, trace the execution path on these three platforms:
- Linux (bash, GNU coreutils)
- macOS (zsh default, BSD coreutils, no GNU date)
- Windows (Git Bash bundled with Git for Windows)

For each platform, answer:

1. Will the shebang line (#!/usr/bin/env bash) resolve correctly? What if bash isn't installed or isn't the default shell?

2. Walk through each command in the script. Which ones are POSIX-standard, which are GNU extensions, and which might behave differently across platforms? Pay special attention to `date`, `grep`, `sed`, and `jq` or JSON parsing.

3. The stop hook reads JSON from stdin. What tool does it use to parse it? Is that tool available on all three platforms by default? What happens if the JSON format changes or the field is missing entirely?

4. What happens on each platform if the .claude/status.md file uses Windows-style line endings (CRLF)? Does `grep` still match correctly? Does `sed` handle the carriage return?

5. Are there any silent failures — cases where a command fails but the script continues without warning, potentially producing wrong results?

Propose fixes for any issues you find. Prioritize portability without adding dependencies.
```

---

## Prompt 3: Version & Metadata Consistency

```
Read these files and compare them:
- .claude-plugin/plugin.json
- .claude-plugin/marketplace.json
- Each SKILL.md file (check the version number in the frontmatter/header)

Now answer:

1. How many different version numbers exist across these files? Do they all agree? Should they?

2. If a user reports a bug and says "I'm on version 1.2.0," can you tell which version of each skill they have? How would you find out?

3. When a skill gets a major update (e.g., project-plugins goes from 4.1 to 5.0), what should happen to the plugin version? Is there a convention documented anywhere? Should there be?

4. Look at the keywords in plugin.json and marketplace.json. Are they identical? Should they be? Are there keywords that would help users discover this plugin that are currently missing?

5. Check the author/owner fields across both JSON files. Are they consistent? Do they point to the right places?

Propose a versioning strategy and any metadata fixes needed.
```

---

## Prompt 4: Audit & Init Edge Cases

```
Read skills/project-audit/SKILL.md and skills/project-init/SKILL.md completely.

Now imagine these scenarios and trace what would happen:

1. A user runs /init on a brand new empty directory. Then, before making any changes, they run /init again. What happens? Are any files overwritten? Is there a merge strategy? What does the .init-manifest do in this case?

2. A user runs /init, creates 50 files over the next two weeks, then runs /audit. The audit needs to scan all files, check for contradictions, and verify the filemap. What if the project has 500+ files? Is there a timeout risk? What happens if the audit is interrupted halfway through?

3. A user runs /audit on a monorepo with 5 packages, each with their own .claude/ directory. Does the audit know which scope to check? Could it accidentally flag contradictions between independent packages?

4. The audit checks for "stale counts" — numbers mentioned in reference files that may have changed. Walk through the contradiction detection methodology. Are there cases where it would produce false positives? False negatives? Is the approach robust or fragile?

5. A user runs /init, then manually deletes some of the generated files but keeps .init-manifest. Later they run /init again. Does the manifest accurately reflect reality? Could this cause problems?

For each scenario where you find a gap, propose a specific guard, check, or user-facing warning that would prevent confusion.
```

---

## Prompt 5: Registry Claims & Accuracy

```
Read skills/project-plugins/REGISTRY_SCHEMA.md and the relevant sections of skills/project-plugins/SKILL.md.

Answer these questions:

1. The schema doc says "103+ entries" in the live registry. When was this number last verified? If the registry has grown or shrunk since then, how would a user or maintainer know? Should this number be in the doc at all?

2. The skill says it uses the curated registry as its "primary discovery source before web search." Walk through what happens if:
   - The GitHub repo is unreachable (user is offline or rate-limited)
   - The registry.json file has a syntax error
   - A registry entry references a tool that no longer exists or has been renamed
   Does the skill handle each gracefully, or would it fail silently?

3. The REGISTRY_SCHEMA.md says it's a "reference copy" and is "NOT read during skill execution." If it's not read, what's its purpose? Could it become dangerously out of sync with the live schema? How would you prevent that?

4. Look at the 7 tool categories the skill discovers across. Are these categories still accurate and complete? Are there tool categories that have emerged in the Claude Code ecosystem since this was written that should be added?

5. The skill mentions "context cost estimation" for recommended tools. How is this calculated? Is it documented? Could a user verify the estimate themselves?

For each finding, propose a concrete improvement — whether it's a documentation fix, a code guard, or a schema change.
```

---

## Usage Notes

- Run these one at a time, in order (1-5)
- Review and apply each result before moving to the next
- Each prompt is designed so the AI discovers the issues through analysis rather than being told what's wrong
- If the AI misses something, that's useful signal about the prompt's effectiveness — iterate on the prompt wording
