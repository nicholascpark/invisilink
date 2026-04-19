---
name: gnosis
version: "1.1"
description: Establish umbilical connection AND knowledge participation for a pre-existing repo. Run after the parent has blessed this repo. Not for incubator-spawned ventures.
user-invocable: true
command: /gnosis
---

# Gnosis

Establish an umbilical connection between this repo and the parent (business-machine) AND install the federated knowledge base scaffolding so the linked repo becomes a first-class knowledge participant. This creates the communication directories, writes the configuration, registers the venture in the parent's `ventures.md`, installs the child-side knowledge vault (schema.md, config.json, log.md, index.md, hot.md, raw/imports/parent/, wiki/parent/), imports the parent's current generalized learnings as a catch-up batch, and installs the `/flash` upgrade stub.

**Scope:** This skill is exclusively for pre-existing repos that were NOT spawned by the parent's incubator. Incubator-spawned ventures are born linked — they already have umbilical directories, a `ventures.md` entry, `umbilical/config.md`, a `knowledge/` vault, and a `/flash` stub. If this venture is already linked or parent-spawned, run `/flash` instead.

**Prerequisite:** The parent must have run `/bless` on this repo first. That delivers this skill. If you're reading this, the blessing already happened.

**What gnosis 1.1 adds (Phase 6):** v1.0 of gnosis established the umbilical only. v1.1 makes the linked repo a **knowledge participant** — it gets the same local vault structure that spawned ventures get, it receives parent learnings as typed packets, and it can emit venture_evidence packets upward. Status tracking in `ventures.md` gains two new fields: `knowledge_exchange` (enabled|disabled) and `operational_state` (incubating|operating|pivoting|dormant|unknown). Agents route to linked repos based on these fields, not on the legacy `status: linked` alone.

## Process

### Step 1: Guard — Reject if Already Linked

Check for `umbilical/config.md`. If it exists, read it.

- If it contains `linked: true` → STOP. Tell the user: "This venture is already linked to the parent. Run `/flash` to upgrade." Do not proceed.

### Step 2: Guard — Reject if Incubator-Spawned

Check for ALL THREE of:
- `.claude/agents/founder/founder.md`
- `umbilical/inbox/`
- `umbilical/outbox/`

If all three exist, this is likely an incubator-spawned venture. STOP. Tell the user: "This venture appears to be parent-spawned. Run `/flash` to upgrade. `/gnosis` is for pre-existing repos only."

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
3. Contains `tools/invisilink/flash.md`

If any check fails, report the specific error and stop.

### Step 6: Check for Existing Registration

Read the parent's `ventures.md`. Search for this venture's name or path.

If the venture already has an entry, STOP. Tell the user: "This venture is already registered in the parent's ventures.md. Run `/flash` to upgrade."

### Step 7: Register in Parent's ventures.md

Append an entry to `{parent_path}/ventures.md`:

```markdown
## {Venture Name}
- repo: {absolute path to this venture repo}
- spawned: pre-existing
- linked: {today's date in YYYY-MM-DD}
- source: gnosis (blessed by parent)
- status: linked
- operational_state: unknown
- knowledge_exchange: enabled
- current_phase: unknown
- last_sync: {today's date in YYYY-MM-DD}
```

**Field semantics:**
- `status` — connection state: `linked`, `active`, `dead`, `graduated`. Controls whether the parent registers the venture at all.
- `operational_state` — business state: `incubating`, `operating`, `pivoting`, `dormant`, `unknown`. Agents that care about the venture's business lifecycle (heartbeat, curator) check this.
- `knowledge_exchange` — knowledge protocol state: `enabled`, `disabled`. When `enabled`, the venture receives discovery_signal and parent_learning packets AND can emit venture_evidence packets upward. When `disabled`, the umbilical exists but the knowledge base channel is silent. Newly-gnosis'd repos default to `enabled`.

Legacy (v1.0) gnosis entries lacking these two fields are treated as `operational_state: unknown` and `knowledge_exchange: disabled` by default. A `/flash` upgrade on such a venture will add the fields.

### Step 8: Write Umbilical Config

Write `umbilical/config.md` in this repo:

```markdown
# Umbilical Configuration
- parent_path: {confirmed parent path}
- linked: true
- linked_date: {today's date in YYYY-MM-DD}
- knowledge_exchange: enabled
```

### Step 9: Create Knowledge Vault Directory Structure

Create the child-side knowledge vault — same container model as spawned ventures, minus the Phase 7 iCloud migration (linked repos keep their vault repo-local by default):

```bash
mkdir -p knowledge/raw/processed \
         knowledge/raw/imports/parent \
         knowledge/wiki/patterns \
         knowledge/wiki/parent \
         knowledge/wiki/signals \
         knowledge/lineage \
         knowledge/meta
touch knowledge/raw/processed/.gitkeep \
      knowledge/wiki/patterns/.gitkeep \
      knowledge/wiki/parent/.gitkeep \
      knowledge/wiki/signals/.gitkeep \
      knowledge/lineage/.gitkeep
```

The key subdirectory for Phase 6 is `knowledge/raw/imports/parent/` — this is where the umbilical-monitor deposits incoming `parent_learning` packets so the child's knowledge-librarian can compile them into local wiki pages. Without this directory, parent learnings only reach `data/inbox/` for operational awareness and never enter the child's knowledge graph.

### Step 10: Copy Knowledge Templates from Parent

Copy the canonical templates from `{parent_path}/tools/invisilink/assets/templates/knowledge/` into this repo's `knowledge/` directory. The templates are the same ones spawned ventures receive:

```bash
cp {parent_path}/tools/invisilink/assets/templates/knowledge/schema.md knowledge/schema.md
cp {parent_path}/tools/invisilink/assets/templates/knowledge/index.md knowledge/index.md
cp {parent_path}/tools/invisilink/assets/templates/knowledge/hot.md knowledge/hot.md
cp {parent_path}/tools/invisilink/assets/templates/knowledge/log.md knowledge/log.md
cp {parent_path}/tools/invisilink/assets/templates/knowledge/capabilities.json knowledge/meta/capabilities.json
```

Then create this venture's config.json by copying the template and replacing the `{TBD_*}` tokens:

```bash
cp {parent_path}/tools/invisilink/assets/templates/knowledge/config.json knowledge/config.json
```

Edit `knowledge/config.json` to set `vault_uri` and `container_uri` to `file://./knowledge` (child vaults default to repo-local; they do NOT share the parent's iCloud container).

Create an empty device registry:

```bash
echo '{"devices": []}' > knowledge/meta/devices.json
```

Write the bootstrap config for this venture at `.claude/knowledge-config.json`:

```json
{
  "_comment": "Bootstrap pointer for this venture's knowledge base. Points to repo-local ./knowledge by default. The device_id is required for log attribution.",
  "container_uri": "file://./knowledge",
  "vault_uri": "file://./knowledge",
  "fallback_uri": "file://./knowledge",
  "schema_version": "1.0.0",
  "transport_mode": "umbilical",
  "allow_child_mounts": false,
  "device_id": "{hostname derived from $(hostname | cut -d. -f1)}"
}
```

Review the generated `device_id` with the user before writing — they may want a more meaningful identifier.

### Step 11: Install umbilical-monitor Skill

Copy the umbilical-monitor skill template so the venture can consume packets:

```bash
mkdir -p skills
cp {parent_path}/tools/invisilink/assets/templates/skills/umbilical-monitor.md skills/umbilical-monitor.md
```

The monitor detects both typed packets (packet_type frontmatter) and legacy signal formats. On receiving a `parent_learning` packet, it routes the content to `data/inbox/` for operational awareness AND copies the packet to `knowledge/raw/imports/parent/{packet_id}.md` for local knowledge graph compilation. On receiving a `discovery_signal`, it does the same. See the template's body for the full routing table.

### Step 12: Write Local `/flash` Stub

Create the directory if needed:

```bash
mkdir -p .claude/skills/invisilink
```

Write `.claude/skills/invisilink/flash.md`:

```markdown
---
name: flash
---
# Flash

Read and follow the instructions at `{confirmed parent path}/tools/invisilink/flash.md`.
```

### Step 13: Request Catch-Up Parent Learning Import

Tell the user:

> "The parent has N generalized pattern pages in its wiki (where N is the count of files in `{parent_path}/knowledge/wiki/patterns/` OR `{resolved iCloud vault path}/wiki/patterns/`, whichever the parent's `.claude/knowledge-config.json` points to). Run a catch-up import to bring this venture's local knowledge graph up to date?"

If the user confirms, for each pattern page in the parent's `wiki/patterns/` directory that is confidence `cross-venture-pattern` or `battle-tested`:

1. Read the pattern page to extract `id`, `lineage_id`, and a summary
2. Compose a `parent_learning` packet with:
   - `packet_id`: `PL-{today}-CATCHUP-{NNN}` where NNN starts at 001 and increments
   - `packet_type: parent_learning`
   - `learning_id`: the pattern page `id`
   - `lineage_id`: the pattern page `lineage_id`
   - `urgency: low` (catch-up is not time-sensitive)
   - `relevance`: "Catch-up import delivered by gnosis 1.1 — this pattern may or may not apply to your venture; the Founder should evaluate on next cycle"
   - Body: pattern summary + traceability
3. Write the packet to BOTH `umbilical/inbox/{packet_id}.md` AND `knowledge/raw/imports/parent/{packet_id}.md`
4. Log each deposit to `knowledge/log.md` with device_id and a catch-up summary entry

If the parent has 0 `cross-venture-pattern`+ patterns (current state as of 2026-04-14 — all 9 backfilled patterns are `single-venture-observation`), skip the import and tell the user: "Parent has no cross-venture patterns yet. No catch-up import needed. Future parent learnings will arrive through the umbilical as they are produced."

Patterns at `single-venture-observation` confidence are NOT part of the catch-up import — they are too weak to push down without a specific relevance match.

### Step 14: Report

Tell the user:

> "Gnosis complete. Umbilical established, knowledge vault scaffolded, umbilical-monitor installed, and catch-up import {executed with N packets | skipped because parent has no cross-venture patterns yet}. This venture is now a first-class knowledge participant. Run `/flash` to deploy or upgrade infrastructure if desired."

## What Gnosis 1.1 Does NOT Do

- Migrate this venture's vault to iCloud — linked repos default to repo-local, the parent vault is the one in iCloud. A future slice can add iCloud participation for linked repos if the user wants that.
- Backfill historical catch-up for `single-venture-observation` patterns — too weak to push without specific relevance.
- Run `/flash` automatically — the human decides when.
- Deploy the full invisilink agent stack (Founder/Builder/Growth/Comms) — that's `/flash`'s job.
- Work on incubator-spawned or already-linked ventures — those use `/flash` directly.

## What Gnosis 1.1 Does Do That v1.0 Did NOT

- Creates the full `knowledge/` vault structure with config.json, schema.md, log.md, index.md, hot.md, capabilities.json, devices.json
- Creates `raw/imports/parent/` specifically — the missing Phase 6 bridge between "parent sent a learning" and "the child's KG has it"
- Installs the `umbilical-monitor` skill so the venture can consume typed packets
- Registers `knowledge_exchange` and `operational_state` fields in `ventures.md`
- Offers a catch-up import of existing cross-venture parent patterns
- Makes the linked venture visible to parent's heartbeat, learning-curator, and discovery-relay as an active knowledge participant (via `knowledge_exchange: enabled`), not just as a connection artifact
