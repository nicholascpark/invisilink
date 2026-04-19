---
packet_id: PL-{YYYY-MM-DD}-{NNN}
packet_type: parent_learning
learning_id: pattern-{slug}
lineage_id: LIN-{YYYY-MM-DD}-{NNN}
created: {YYYY-MM-DDTHH:MM:SSZ}
urgency: low | medium | high
relevance: "1-2 sentences on why this matters to this specific child venture"
---

# Parent Learning: {pattern title}

## Pattern
{The generalizable pattern, copied from the parent's `knowledge/wiki/patterns/{learning_id}.md`. Be concise — one paragraph.}

## Why This Matters Here
{Why this pattern applies to this specific venture's blueprint, current experiments, or domain. The curator writes this; the venture reads it as context.}

## Traceability
- Parent page: `[[{learning_id}]]`
- Lineage: `{lineage_id}` (cite the lineage record, not the venture-specific evidence)
- Confidence: cross-venture-pattern | battle-tested
- Derived from: {N} ventures' evidence

---

**Instructions for filers (parent learning-curator):**

1. Assign a stable `packet_id`. Format: `PL-{YYYY-MM-DD}-{NNN}`. Check the parent's outbox-sent registry (or grep `umbilical/inbox/PL-*.md` across all active ventures) for today's max sequence and increment.
2. Name the file `{packet_id}.md` and place it in the target venture's `umbilical/inbox/`.
3. `learning_id` MUST match an existing parent pattern page in `{vault_uri}/wiki/patterns/`. Do not send parent learnings for single-venture-observation patterns — only `cross-venture-pattern` or `battle-tested`.
4. `lineage_id` MUST match an existing lineage record in `{vault_uri}/lineage/`. This gives the child a traceable path back to the evidence.
5. **Do not cite venture-specific evidence in this packet.** The pattern page and lineage record are the only authoritative references. The child can look up both via the parent's exported wiki (future) or via umbilical if it needs the full provenance trail.
6. Also deposit a copy at `{child_repo}/knowledge/raw/imports/parent/{packet_id}.md` so the child's knowledge-librarian can compile it into the child's local `knowledge/wiki/parent/`. The umbilical-monitor does this automatically on packet arrival.
