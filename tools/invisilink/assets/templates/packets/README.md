# Umbilical Packet System

The umbilical between the parent venture OS and each child venture is a **typed packet bus**. Three packet families flow across it:

| Packet type | Direction | Sender | Receiver |
|---|---|---|---|
| `venture_evidence` | child → parent | venture Founder | parent learning-curator |
| `parent_learning` | parent → child | parent learning-curator | venture Founder (via umbilical-monitor) |
| `discovery_signal` | parent → child | parent discovery-relay | venture Founder (via umbilical-monitor) |

All three packet types share a common **envelope** so a single child-side ingest worker can handle all of them:

```yaml
packet_id: <unique stable ID — see format below>
packet_type: venture_evidence | parent_learning | discovery_signal
created: YYYY-MM-DDTHH:MM:SSZ     # ISO 8601 UTC
urgency: low | medium | high
```

Body fields diverge by packet type. See each template file for the full schema.

---

## Packet ID conventions

Packet IDs are stable, citable, and monotonic. Lineage records cite packet IDs, so regenerating or reusing an ID would break the audit trail.

| Type | Format | Example |
|---|---|---|
| venture_evidence | `EV-{VENTURE-UPPER}-{YYYY-MM-DD}-{NNN}` | `EV-APPEALENGINE-2026-03-26-001` |
| parent_learning | `PL-{YYYY-MM-DD}-{NNN}` | `PL-2026-04-13-001` |
| discovery_signal | `DS-{YYYY-MM-DD}-{SOURCE-OBS-ID}` | `DS-2026-04-13-OBS-C9-04` |

`NNN` is a zero-padded sequence number per day (001, 002, ...). The sender is responsible for assigning the next sequence — for venture_evidence it's the venture Founder, for parent_learning it's the parent learning-curator, for discovery_signal the observation ID from the Forager provides the suffix.

---

## Filename == packet ID

A packet file MUST be named `{packet_id}.md`. This makes packets citable by filename alone:

```
umbilical/outbox/EV-APPEALENGINE-2026-03-26-001.md
umbilical/inbox/PL-2026-04-13-001.md
umbilical/inbox/DS-2026-04-13-OBS-C9-04.md
```

Any file in `umbilical/outbox/` or `umbilical/inbox/` that does NOT follow this pattern is either a legacy file (pre-v1.4) or an error. The umbilical-monitor and learning-curator treat legacy files as "proto-packets" — they're still processed, but their evidence attribution is weaker (the lineage record notes "legacy, no packet_id").

---

## Legacy filename prefixes

Before the packet system, venture outboxes used filename prefixes to classify content:

| Prefix | Significance | New home |
|---|---|---|
| `pivot-` | venture thesis change | `event_class: pivot` inside a venture_evidence packet |
| `death-` | venture death | `event_class: death` inside a venture_evidence packet |
| `phase-transition-` | phase gate crossed | `event_class: phase_transition` |
| `learning-` | assumption update | `event_class: learning` |
| `cycle-` | periodic progress report | `event_class: cycle` |
| `capability-unlock-` | new capability earned | `event_class: capability_unlock` |

These prefixes are now **classification hints in the packet body** (`event_class`), not packet types. The packet type for all venture outputs is `venture_evidence`.

Existing legacy files are left in place. New files written by venture Founders use the packet format. The curator accepts both during the transition window and marks legacy-derived lineage records with `legacy_source: true`.

---

## Templates

- [`venture_evidence.md`](venture_evidence.md) — filed by venture Founders to `umbilical/outbox/`
- [`parent_learning.md`](parent_learning.md) — filed by parent learning-curator to `umbilical/inbox/`
- [`discovery_signal.md`](discovery_signal.md) — filed by parent discovery-relay to `umbilical/inbox/`

See also the spec at `docs/superpowers/specs/2026-04-13-karpathy-aligned-federated-knowledge-architecture-design.md` § Umbilical as Knowledge Transport for the full design rationale.
