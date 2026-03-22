# deploy-team

A Claude Code skill that deploys a 4-manager AI organizational hierarchy with lifecycle economics, validation engine, and adaptive learning to any existing repo.

## What It Does

Run `/deploy-team` in any repo to get a full AI-powered team with economic survival pressure:

- **Founder** (CEO) — owns strategy, priorities, economic survival, curriculum, pivot decisions
- **Builder** (CTO) — builds and ships the product, stewards the tech stack and tooling
- **Growth** (Validation Engine) — designs and runs parallel experiments from day one, measures outcomes, makes keep/kill decisions
- **Comms** — handles partnerships and external relationships

Each manager spawns domain-tuned subagent workers. Managers communicate through async channels. The human talks only to the Founder.

### Three Integrated Systems

**Lifecycle Economics (Sustenance System)**
Real-dollar tracking with mortality enforcement. The venture has a balance, burn rate, and runway. When balance hits zero, sessions are blocked. No abstractions — real money in, real money out. Includes `sustenance.sh` CLI, `sustenance.json` ledger, and hook scripts (death-gate, session briefing, cost capture).

**Validation Engine (Growth as Experiment Machine)**
Growth runs 3-5 parallel experiments from Phase 0, not after some readiness gate. Each experiment has a hypothesis, machine-verifiable metric, threshold, timeline, and cost cap. Autoresearch loop discipline: baseline → run → measure → decide (keep/kill/pivot) → inject learnings → log. Phase gates control blast radius (what capabilities are active), not whether you experiment.

**Adaptive Learning Engine**
Living curriculum in `program.md` with four stages: Does anyone care? → Will they pay? → Is it repeatable? → Can it grow profitably? Pivot detection triggers (signal drought, burn exceeds learning, phase deadline, external signal). C-suite debate protocol for pivot decisions. Meta-learnings that compound across experiments.

## Install

Add to your Claude Code settings:

```json
{
  "skills": [
    "/path/to/deploy-team/skills"
  ]
}
```

Or clone and add the path:

```bash
git clone https://github.com/nicholascpark/deploy-team.git
```

## Usage

```bash
cd ~/your-project
# then in Claude Code:
/deploy-team
```

The skill will:
1. Scan your repo (README, tech stack, code structure)
2. Ask 2-4 questions about your product and budget
3. Detect domain, tech stack, and measurement channels
4. Generate domain-tuned managers, workers, channels, and CLAUDE.md
5. Generate economic infrastructure (DNA.md, sustenance, hooks, experiments, curriculum)
6. Ask you to review before writing
7. Commit

## What Gets Created

```
.claude/agents/
  founder/          — CEO, strategy, economic survival, curriculum
    workers/        — researcher, analyst, financial-modeler (CFO)
  builder/          — CTO, product, technical execution, tooling
    workers/        — {tech-stack-specific workers}, tooling-auditor
  growth/           — validation engine, experiments, measurement
    workers/        — experiment-designer, measurement-builder, {domain worker}
  comms/            — partnerships, external relationships
    workers/        — partnership-researcher, etc.
.claude/hooks/
  death-gate.sh     — blocks sessions when balance <= $0
  sustenance-inject.sh — economic briefing at session start
  cost-capture.sh   — estimates and records session costs
.claude/settings.json — hooks wired up
channels/           — async inter-manager communication
data/inbox/         — automated cost capture inbox
DNA.md              — first-person economic creed
CLAUDE.md           — "You are the Founder" (merged with existing)
capabilities.md     — phase-gated actions (free capabilities active at Phase 0)
sustenance.json     — economic ledger (investments, transactions, projections)
sustenance.sh       — CLI for recording costs, revenue, investments
experiments.md      — parallel experiment swarm with autoresearch fields
program.md          — living curriculum (stages, loops, pivot history, meta-learnings)
```

## Architecture

Based on management science research (Ringelmann effect, Amazon two-pizza teams, YC founding team studies) plus economic survival mechanics:

- **4 managers** — optimal team size, clear ownership, no diffused responsibility
- **Workers are subagents** — spawned per task, single-purpose, stateless
- **Channels for communication** — async, timestamped, append-only markdown files
- **Founder has executive authority** — can halt any manager, access any department's workers
- **Mortality is structural** — death-gate hook enforces economic reality, not prose
- **Phase 0 = Experiment** — validation starts immediately, phase gates control blast radius
- **Autoresearch loops** — every experiment follows baseline → run → measure → decide → inject → log
- **Living curriculum** — program.md adapts based on evidence, not a static plan

## License

MIT
