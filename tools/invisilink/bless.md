---
name: bless
version: "1.1"
description: Deliver the /gnosis skill to a pre-existing repo so it can establish an umbilical connection to the parent. Run from the parent (business-machine).
user-invocable: true
---

# Bless

Deliver the `/gnosis` skill to a pre-existing repo that is not yet connected to the parent. This is the first step in establishing an umbilical — the venture must then run `/gnosis` to complete the connection.

**Run this from the parent (business-machine).** This skill writes to an external repo's filesystem.

## Process

### Step 1: Get Target Repo Path

Ask the user: "Which repo should I bless?" Accept an absolute path (e.g., `~/Documents/ventures/some-repo`).

Resolve `~` to the home directory. Verify the path exists and is a directory.

### Step 2: Guard — Reject if Already Linked

Check for `{target_path}/umbilical/config.md`. If it exists and contains `linked: true`, STOP. Tell the user: "This repo is already linked. Run `/flash` there to upgrade."

### Step 3: Guard — Reject if Incubator-Spawned

Check for ALL THREE of:
- `{target_path}/.claude/agents/founder/founder.md`
- `{target_path}/umbilical/inbox/`
- `{target_path}/umbilical/outbox/`

If all three exist, STOP. Tell the user: "This repo appears to be parent-spawned. It should already have `/flash`. Run `/flash` there to upgrade."

### Step 4: Deliver Gnosis Skill

Claude Code discovers skills at `.claude/skills/<skill-name>/SKILL.md` (one directory per skill, file named `SKILL.md`). Create the directory:

```bash
mkdir -p {target_path}/.claude/skills/gnosis
```

Write a pointer stub to `{target_path}/.claude/skills/gnosis/SKILL.md`:

```markdown
---
name: gnosis
description: Pointer to parent invisilink gnosis skill. Establishes umbilical link for a pre-existing repo.
user-invocable: true
---
# Gnosis

Read and follow the instructions at `{absolute path to business-machine}/tools/invisilink/gnosis.md`.
```

### Step 5: Report

Tell the user:

> "Blessed. The repo at {target_path} now has `/gnosis` available. Open a session there and run `/gnosis` to complete the connection."

## What Bless Does NOT Do

- Create umbilical directories — gnosis does that
- Write config or register in ventures.md — gnosis does that
- Deliver `/flash` — gnosis does that after connection
- Work on already-linked or incubator-spawned repos
