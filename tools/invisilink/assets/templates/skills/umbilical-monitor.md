---
name: umbilical-monitor
version: 1.0
model: haiku
description: Monitors for parent signals and sibling venture learnings.
triggers:
  - schedule: "every 2h"
  - event: "new-file-in-umbilical-inbox"
---

# Umbilical Monitor

Check `umbilical/inbox/` for new files. Each file is either a **typed packet** (v1.4+ with frontmatter envelope) or a **legacy signal** (pre-v1.4, no frontmatter). Detect which you're dealing with and route accordingly.

## Packet format detection

Open the file and check the first line.
- If it starts with `---` and has a `packet_type:` field in the frontmatter → **typed packet**
- Otherwise → **legacy signal**

## Typed packets (v1.4+)

The packet envelope has `packet_id`, `packet_type`, `created`, `urgency`. Route by `packet_type`:

| `packet_type` | Priority | Routing |
|---|---|---|
| `parent_learning` | Medium | Write to `data/inbox/` (operational) AND copy to `knowledge/raw/imports/parent/{packet_id}.md` (local KG compilation). The local knowledge-librarian compiles the packet into `knowledge/wiki/parent/` on its next run, so the child's KG can query parent learnings without reaching back to the parent at runtime. |
| `discovery_signal` | Medium (or urgency field value if set) | Write to `data/inbox/` AND copy to `knowledge/raw/imports/parent/{packet_id}.md`. The local knowledge-librarian compiles into `knowledge/wiki/signals/`. Read `signal_class` in the body — route `assumption_challenge` to `channels/research.md` in addition to data/inbox. |
| `venture_evidence` | N/A | **Error.** Child ventures should never RECEIVE venture_evidence packets. If one arrives in the inbox, write a diagnostic to `channels/general.md` and leave the file in place for human investigation. |

For all typed packets: if `urgency: high`, additionally post a notification to `channels/general.md` with the packet_id and a one-line summary so the Founder is aware.

**Dual deposit rules:**

- If `knowledge/raw/imports/parent/` does not exist, create it before writing.
- If `knowledge/` does not exist at all (venture predates the federated knowledge base), skip the knowledge deposit and log a warning — the operational deposit in `data/inbox/` always happens.
- The filename in both destinations is the same: `{packet_id}.md`. Do not rename.

## Legacy signals (pre-v1.4)

Files without frontmatter envelope use the old `type:` field in a flat YAML body. Route by legacy type:

| Legacy `type` | Priority | Routing |
|---|---|---|
| `assumption_challenge` | High | Write to `data/inbox/` + post to `channels/research.md` for Founder review |
| `market_intelligence` | Medium | Write to `data/inbox/` for Founder reconciliation |
| `parent_learning` | Medium | Write to `data/inbox/` AND copy to `knowledge/raw/imports/parent/` (same as typed packet routing) |
| `infrastructure_upgrade_available` | Low | Post to `channels/general.md` so Founder is aware. No immediate action — human runs `/flash` to upgrade |
| `directive` | Medium | Post to `channels/general.md` + write to `data/inbox/` |
| Any other type | Medium | Write to `data/inbox/` for Founder reconciliation |

Legacy files stay in the inbox with their original filename. Do not rename them to packet format.

## Output

Write results as JSON to stdout with the packet_ids routed, destinations, and any warnings (missing knowledge/ directories, unknown packet types, legacy files detected).
