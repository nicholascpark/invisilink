# invisilink

A Claude Code skill that deploys a 4-manager AI organizational hierarchy with lifecycle economics, autonomous/interactive dual-mode operation, irrevocable action gates, session briefing digests, federated knowledge base, and domain-tuned workers to any existing repo.

> **Note:** This repo is a distribution mirror. Source of truth lives in the parent `business-machine` repo at `tools/invisilink/`. See [`tools/invisilink/CHANGELOG.md`](tools/invisilink/CHANGELOG.md) for version history.
>
> The skill was previously named `deploy-team`. Renamed to `invisilink` (system) / `/flash` (command) as of v1.2 (2026-03-28).

## What It Does

Run `/flash` in any repo to get a full AI-powered team with economic survival pressure and autonomous operation:

- **Founder** (CEO) — owns strategy, priorities, economic survival, curriculum, pivot decisions, autonomous/interactive mode switching
- **Builder** (CTO) — builds and ships the product, stewards the tech stack and tooling, manages execution infrastructure (Stripe, email, phone APIs)
- **Growth** (Validation Engine) — designs and runs parallel experiments from day one, measures outcomes, makes keep/kill decisions
- **Comms** — handles partnerships and external relationships

Each manager spawns domain-tuned subagent workers. Managers communicate through async channels. The human talks only to the Founder.

### Dual-Mode Operation

**Interactive Mode** — Human present. Founder delivers a 7-section session briefing (sustenance, experiments, assumptions, curriculum, pending decisions, team activity, key risks), then asks what to focus on. Full conversational access, decision authority, irrevocable action approvals.

**Autonomous Mode** — Cron-triggered via `venture-heartbeat.sh`. Founder operates within constrained boundaries: routine actions execute immediately, non-routine decisions queue in `decisions-pending.md`. Budget: $2.00/cycle. Detected by the prompt "Autonomous cycle."

### Lifecycle Economics (Sustenance System)

Real-dollar tracking with mortality enforcement. The venture has a balance, burn rate, and runway. When balance hits zero, sessions are blocked. No abstractions — real money in, real money out. Includes `sustenance.sh` CLI, `sustenance.json` ledger, and 7 hook scripts.

### Irrevocable Action Gates

Emails, payments, and phone calls are blocked by the `irrevocable-gate` hook. Blocked actions trigger Telegram notifications to the human and get queued in `decisions-pending.md` for approval in the next interactive session.

### Session Briefing Digests

The `session-briefing-email` hook sends an email digest at session start (configurable via `BRIEFING_EMAIL` env var). Includes sustenance status, active experiments, pending decisions.

### Validation Engine (Growth as Experiment Machine)

Growth runs 3-5 parallel experiments from Phase 0, not after some readiness gate. Each experiment has a hypothesis, machine-verifiable metric, threshold, timeline, and cost cap. Autoresearch loop discipline: baseline -> run -> measure -> decide (keep/kill/pivot) -> inject learnings -> log. Phase gates control blast radius (what capabilities are active), not whether you experiment.

### Adaptive Learning Engine

Living curriculum in `program.md` with four stages: Does anyone care? -> Will they pay? -> Is it repeatable? -> Can it grow profitably? Pivot detection triggers (signal drought, burn exceeds learning, phase deadline, external signal). C-suite debate protocol for pivot decisions. Meta-learnings that compound across experiments.

## Install

Clone the repo and point Claude Code at the skill file:

```bash
git clone https://github.com/nicholascpark/invisilink.git
```

The skill file is at `tools/invisilink/flash.md`. Add it to your Claude Code skills path (user-level `~/.claude/skills/flash/SKILL.md` as a copy, or symlink).

## Usage

```bash
cd ~/your-project
# then in Claude Code:
/flash
```

The skill will:
1. Scan your repo (README, tech stack, code structure)
2. Ask 2-5 questions about your product, budget, and email preferences
3. Detect domain, tech stack, and measurement channels
4. Generate domain-tuned managers, workers, channels, and CLAUDE.md
5. Generate economic infrastructure (DNA.md, sustenance, 7 hooks, experiments, curriculum, decisions-pending)
6. Generate NanoClaw skill templates, skill-runner.sh, and healthcheck.sh
7. Configure autonomous/interactive mode, irrevocable gates, session briefings
8. Ask you to review before writing
9. Commit and run healthcheck

### Upgrade Mode

If the repo already has agents deployed (`.claude/agents/founder/` exists), the skill automatically switches to **upgrade mode**. Instead of replacing your existing team, it retrofits the repo with:

- **DNA directive** — added to CLAUDE.md and all existing agent `.md` files (never overwrites agent content)
- **DNA enforcement hook** — catches agent definitions written without the DNA directive (PreToolUse on Write/Edit)
- **Lifecycle economics** — `DNA.md`, `sustenance.json`, `sustenance.sh`, and all hooks
- **All 7 hooks** — death-gate, sustenance-inject, cost-capture, dna-enforcement, irrevocable-gate, telegram-notify, session-briefing-email
- **Autonomous mode** — mode detection, decision boundaries, budget constraints added to Founder
- **Irrevocable action gates** — hook + decisions-pending.md queue
- **Session briefing** — Step 0.5 interactive briefing + email digest hook
- **Validation engine** — `experiments.md` with parallel experiment template
- **Adaptive learning** — `program.md` with living curriculum structure
- **Data infrastructure** — `data/inbox/`, snapshots, outbox directories
- **NanoClaw skills** — 5 skill templates with model selection, `skill-runner.sh`, `healthcheck.sh`
- **CLAUDE.md sections** — Sustenance, Validation Engine, Adaptive Learning, Autonomous Mode, Irrevocable Actions, NanoClaw Workforce sections appended

Existing agents are never overwritten — only enhanced with the DNA directive. Healthcheck runs after upgrade to verify configuration.

## What Gets Created

```
.claude/agents/
  founder/          — CEO, strategy, economic survival, autonomous/interactive mode
    workers/        — researcher, analyst, financial-modeler (CFO)
  builder/          — CTO, product, technical execution, tooling, execution infrastructure
    workers/        — {tech-stack-specific workers}, tooling-auditor
  growth/           — validation engine, experiments, measurement
    workers/        — experiment-designer, measurement-builder, {domain worker}
  comms/            — partnerships, external relationships
    workers/        — partnership-researcher, etc.
.claude/hooks/
  death-gate.sh          — blocks sessions when balance <= $0
  sustenance-inject.sh   — economic briefing at session start
  cost-capture.sh        — estimates and records session costs
  dna-enforcement.sh     — catches agent defs without DNA directive
  irrevocable-gate.sh    — blocks email/payment/call, sends Telegram, queues in decisions-pending
  telegram-notify.sh     — utility for sending Telegram messages
  session-briefing-email.sh — emails briefing digest at session start
.claude/settings.json    — all hooks wired (5 hook events)
channels/                — async inter-manager communication
skills/                  — 5 NanoClaw skill templates (financial-engine, growth-ops, market-intel, source-monitors, umbilical-monitor)
data/inbox/              — automated cost capture inbox
DNA.md                   — first-person economic creed
CLAUDE.md                — "You are the Founder" with mode detection (merged with existing)
capabilities.md          — phase-gated actions (free capabilities active at Phase 0)
sustenance.json          — economic ledger (investments, transactions, projections)
sustenance.sh            — CLI for recording costs, revenue, investments
skill-runner.sh          — lightweight NanoClaw that executes SKILL.md files via Claude Code
healthcheck.sh           — verifies venture configuration is correct
experiments.md           — parallel experiment swarm with autoresearch fields
program.md               — living curriculum (stages, loops, pivot history, meta-learnings)
decisions-pending.md     — queue for items requiring human approval
```

## Hook Wiring

| Event | Hook | Purpose |
|-------|------|---------|
| UserPromptSubmit | death-gate.sh | Block if balance <= $0 |
| SessionStart | sustenance-inject.sh | Inject economic briefing |
| SessionStart | session-briefing-email.sh | Email digest to BRIEFING_EMAIL |
| Stop | cost-capture.sh | Record estimated session cost |
| PreToolUse (Write/Edit) | dna-enforcement.sh | Enforce DNA directive in agents |
| PreToolUse (Bash) | irrevocable-gate.sh | Block irrevocable actions |

## Environment Variables

| Variable | Purpose | Required |
|----------|---------|----------|
| `TELEGRAM_BOT_TOKEN` | Telegram bot token for irrevocable action notifications | Optional |
| `TELEGRAM_CHAT_ID` | Telegram chat ID for notifications | Optional |
| `BRIEFING_EMAIL` | Email address for session briefing digests | Optional |

## Architecture

Based on management science research (Ringelmann effect, Amazon two-pizza teams, YC founding team studies) plus economic survival mechanics:

- **4 managers** — optimal team size, clear ownership, no diffused responsibility
- **Workers are subagents** — spawned per task, single-purpose, stateless
- **Channels for communication** — async, timestamped, append-only markdown files
- **Founder has executive authority** — can halt any manager, access any department's workers
- **Mortality is structural** — death-gate hook enforces economic reality, not prose
- **Irrevocable actions are gated** — email, payment, phone calls blocked until human approves
- **Autonomous mode is constrained** — routine-only execution, non-routine items queued for human
- **Phase 0 = Experiment** — validation starts immediately, phase gates control blast radius
- **Autoresearch loops** — every experiment follows baseline -> run -> measure -> decide -> inject -> log
- **Living curriculum** — program.md adapts based on evidence, not a static plan
- **5 NanoClaw skills** — financial-engine, growth-ops, market-intel, source-monitors, umbilical-monitor with cost-appropriate model selection
- **skill-runner.sh** — lightweight NanoClaw that executes skills between sessions via Claude Code (haiku for monitoring, sonnet for analysis)
- **healthcheck.sh** — verifies venture configuration after deploy/upgrade

## Skill Runner

`skill-runner.sh` is a lightweight NanoClaw implementation. It reads SKILL.md files from `skills/`, checks their trigger schedules, and executes due skills via Claude Code. Each skill's YAML frontmatter includes a `model:` field that determines which Claude model runs it:

| Model | Used For | Skills |
|-------|----------|--------|
| haiku | Structured data, monitoring, routing (cheap) | financial-engine, source-monitors, umbilical-monitor |
| sonnet | Analysis, judgment, search (better reasoning) | market-intel, growth-ops |

Run manually: `./skill-runner.sh` (from venture root). The heartbeat daemon runs it automatically on every trigger event.

When real NanoClaw is deployed, it replaces this script. The SKILL.md format is forward-compatible.

## Healthcheck

`healthcheck.sh` verifies that a venture is correctly configured. Run it after deploy/upgrade or anytime to check system integrity:

```bash
./healthcheck.sh .
```

Checks: core files, all 7 hooks, settings.json, skill definitions, data directories, DNA directives in all agents, sustenance.sh functionality, skill-runner.sh and healthcheck.sh executability.

## License

MIT
