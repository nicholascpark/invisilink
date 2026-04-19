---
packet_id: DS-{YYYY-MM-DD}-{OBS_ID}
packet_type: discovery_signal
source_observation: OBS-CN-NN
signal_class: market_shift | competitive_threat | regulatory_change | opportunity | assumption_challenge
created: {YYYY-MM-DDTHH:MM:SSZ}
urgency: low | medium | high
relevance: "1-2 sentences on why this matters to this specific venture"
---

# Discovery Signal: {short title}

## Raw Observation
{The full observation content from `observations.md`, copied verbatim or faithfully summarized. This is the source material — the venture's Founder should be able to reconstruct the parent's finding without reaching back to observations.md.}

## Why This Was Routed
{The specific reason why this venture should care, beyond generic domain overlap. The discovery-relay already filtered for relevance — this field explains the filter's rationale so the venture Founder can decide whether to act.}

---

**Instructions for filers (parent discovery-relay):**

1. Assign a stable `packet_id`. Format: `DS-{YYYY-MM-DD}-{OBS_ID}` where `OBS_ID` is the observation ID from `observations.md` (e.g., `OBS-C9-04`). The observation ID provides natural deduplication — the same observation relayed to three ventures produces three packet files with the same ID stem but different venture destinations.
2. Name the file `{packet_id}.md` and place it in the target venture's `umbilical/inbox/`.
3. `signal_class` is the type of signal for the receiving venture. It replaces the old `type` field.
4. Discovery signals do NOT travel upward to become parent patterns. They are domain-specific observations routed for venture awareness. If a venture's experience with a discovery signal produces generalizable learning, the venture emits a `venture_evidence` packet that the curator then generalizes.
5. Also deposit a copy at `{child_repo}/knowledge/raw/imports/parent/{packet_id}.md` so the child's knowledge-librarian can compile it into the child's local `knowledge/wiki/signals/`. The umbilical-monitor does this automatically.
6. Silence is a valid routing outcome. Do not route a signal unless the relevance is clear and specific.
