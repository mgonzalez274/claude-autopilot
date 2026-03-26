---
description: Initialize or restructure a Claude-managed project with router-pattern CLAUDE.md, reference files, and rules
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls:*), Bash(wc:*), Bash(git:*)
---

Run the project-init skill to scaffold this project.

If $ARGUMENTS is not empty, use it as context for the discovery interview (e.g., project type, tech stack, or goals). Otherwise, start the discovery interview from scratch.

Follow the skill's phases exactly -- do not skip the discovery interview or the user approval step before generating files.
