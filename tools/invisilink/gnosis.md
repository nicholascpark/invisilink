---
name: gnosis
version: "1.0"
description: Establish umbilical connection to the parent (business-machine) for pre-existing repos. Creates communication directories and requests linkage approval from the parent. Not for incubator-spawned ventures.
user-invocable: true
command: /gnosis
---

# Gnosis

Establish an umbilical connection between this repo and the parent (business-machine). This creates the communication directories, writes the configuration, and drops a linkage request that the parent must approve.

**Scope:** This skill is exclusively for pre-existing repos that were NOT spawned by the parent's incubator. Incubator-spawned ventures are born linked — they already have umbilical directories, a `ventures.md` entry, `umbilical/config.md`, and a `/download` stub. If this venture is already linked or parent-spawned, run `/download` instead.

## Process

### Step 1: Guard — Reject if Already Linked

Check for `umbilical/config.md`. If it exists, read it.

- If it contains `linked: true` → STOP. Tell the user: "This venture is already linked to the parent. Run `/download` to upgrade." Do not proceed.
- If it contains `linked: pending` → Warn: "A gnosis request was previously dropped but not yet approved. Check with the parent." Allow proceeding if user confirms.

### Step 2: Guard — Reject if Incubator-Spawned

Check for ALL THREE of:
- `.claude/agents/founder/founder.md`
- `umbilical/inbox/`
- `umbilical/outbox/`

If all three exist, this is likely an incubator-spawned venture. STOP. Tell the user: "This venture appears to be parent-spawned. Run `/download` to upgrade. `/gnosis` is for pre-existing repos only."

### Step 3: Create Umbilical Directories

```bash
mkdir -p umbilical/inbox umbilical/outbox
```

### Step 4: Confirm Parent Path

Ask the user: "Parent repo path? (default: ~/Documents/business-machine)"

Allow override. Store the confirmed path for subsequent steps.

### Step 5: Validate Parent

Check that the confirmed path:
1. Exists and is a directory
2. Contains `ventures.md`
3. Contains `tools/invisilink/download.md`

If any check fails, report the specific error and stop. Do not drop a request to an invalid parent.

### Step 6: Check for Existing Registration

Read the parent's `ventures.md`. Search for this venture's name or path.

If the venture already has an entry, STOP. Tell the user: "This venture is already registered in the parent's ventures.md. Run `/download` to upgrade."

### Step 7: Drop Gnosis Request

Create the directory if needed:

```bash
mkdir -p {parent_path}/data/gnosis-requests
```

Write a request file to `{parent_path}/data/gnosis-requests/{venture-name}.md`:

```markdown
# Gnosis Request: {venture-name}
- path: {absolute path to this venture repo}
- requested: {today's date in YYYY-MM-DD}
- requested_by: {from git config user.name, or whoami if not set}
```

### Step 8: Write Umbilical Config

Write `umbilical/config.md` in this repo:

```markdown
# Umbilical Configuration
- parent_path: {confirmed parent path}
- linked: pending
- requested: {today's date in YYYY-MM-DD}
```

### Step 9: Write Local `/download` Stub

Create the directory if needed:

```bash
mkdir -p .claude/skills/invisilink
```

Write `.claude/skills/invisilink/download.md`:

```markdown
---
name: download
command: /download
---
# Download

Read and follow the instructions at `{confirmed parent path}/tools/invisilink/download.md`.
```

### Step 10: Report

Tell the user:

> "Gnosis request dropped. Umbilical directories created. Next time you start a session in business-machine, you'll be asked to approve the connection. After approval, run `/download` here to complete the setup."

## What Gnosis Does NOT Do

- Write to the parent's `ventures.md` — that requires parent-side approval
- Deliver catch-up learnings — that happens post-approval in the parent session
- Modify existing agents or skills beyond writing the `/download` stub
- Run `/download` automatically — the human decides when
- Work on incubator-spawned or already-linked ventures — those use `/download` directly
