---
packet_id: EV-{VENTURE_UPPER}-{YYYY-MM-DD}-{NNN}
packet_type: venture_evidence
venture: {venture_slug}
event_class: pivot | death | phase_transition | learning | cycle | capability_unlock | other
created: {YYYY-MM-DDTHH:MM:SSZ}
urgency: low | medium | high
confidence: high | moderate | low
generalization_candidate: true | false
local_refs:
  - outbox/pivot-2026-03-19.md
  - knowledge/wiki/local/experiment-attorney-outreach.md
---

# Venture Evidence: {short title}

## Local Fact Pattern
{What actually happened in this venture. Be specific. Include numbers, names of things the venture encountered, dates. This is the raw evidence the parent's learning-curator will generalize from.}

## Why This Might Generalize
{One paragraph: what about this is venture-agnostic? What's the underlying dynamic that would apply to a completely different venture? If you can't name a generalizable pattern, set `generalization_candidate: false` and explain in the next section why this is venture-local-only.}

## Local Context
{The conditions in which this fact pattern was observed. What had already been validated? What was happening operationally? This context helps the curator distinguish "this always applies" from "this applies when X."}

## Sanitization Hints
{Optional. If you want to flag specific pieces of information that should NOT land in the parent's generalized pattern page — customer names, proprietary numbers, competitor identities — list them here. The curator uses this to decide what to strip during abstraction.}

---

**Instructions for filers (venture Founders):**

1. Assign a stable `packet_id`. Format: `EV-{VENTURE_UPPER}-{YYYY-MM-DD}-{NNN}`. `NNN` is the next sequence number for today — check existing outbox files and increment.
2. Name the file `{packet_id}.md` and place it in `umbilical/outbox/`.
3. `event_class` is a classification hint. It replaces the legacy filename prefixes (`pivot-`, `learning-`, etc.). Pick the one that best describes the event.
4. `confidence` reflects how well-supported this evidence is LOCALLY. `high` = observed and verified; `moderate` = inferred from partial evidence; `low` = speculative. This is distinct from the parent pattern confidence, which is about cross-venture corroboration.
5. `generalization_candidate: true` means "you think this should travel up and become a parent pattern." The curator makes the final call.
6. `local_refs` cite the venture's own internal files (outbox files, local wiki pages) that contain the original evidence. Use relative paths from the venture repo root.
7. Sanitize aggressively. Anything that identifies the venture's specific customers, partners, or proprietary numbers should be flagged or omitted. The parent vault does not store venture-specific operational detail.
