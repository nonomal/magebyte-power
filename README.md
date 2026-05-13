<div align="center">

<img src="images/cross-verified-skill-intro/cross-verified-skill-intro-cover.png" alt="MageByte Power Skills" width="900"/>

# ⚡ MageByte Power Skills

**Claude Code skills for high-stakes backend features — codebase-aware task breakdown + 4-round AI verification**

<br/>

[![GitHub Stars](https://img.shields.io/github/stars/MageByte-Zero/magebyte-power?style=social)](https://github.com/MageByte-Zero/magebyte-power/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT%20%E2%80%94%20Use%20it%2C%20modify%20it%2C%20share%20it-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Compatible-8B5CF6?logo=anthropic&logoColor=white)](https://claude.ai/code)
[![Last Commit](https://img.shields.io/github/last-commit/MageByte-Zero/magebyte-power)](https://github.com/MageByte-Zero/magebyte-power/commits/main)
[![中文文档](https://img.shields.io/badge/文档-中文版（推荐）-red)](README.zh-CN.md)

</div>

> 🇨🇳 **中文用户推荐阅读 [中文文档](README.zh-CN.md)** — 包含完整故事背景、设计原理和使用指南。

---

## Why This Exists

A payment refund API passed two code reviews — including the author's own — and still shipped with a concurrency race condition. Users got double-refunded within two hours of launch.

The root cause wasn't carelessness. **Code review has a structural blind spot**: every reviewer shares the author's design assumptions. The more context you give reviewers, the harder it is for them to spot holes in your belief system.

**This workflow fixes that with 4 independent AI verification passes:**

- 🔍 **Catches 5–15 concurrency & idempotency bugs per review** — by an AI that sees only the code, not the design doc
- ⚡ **Parallel subagents for phases 4.3–4.5** — behavior diff, cross-repo scan, and business invariant check run simultaneously
- 🏗️ **No extra plugins required** — every phase has a built-in fallback using Claude Code's native tools

---

## When To Use

```
Does the feature involve any of the following?

├── 💰 Financial transactions, payments, refunds, settlements?      → YES → Use this workflow
├── 🔄 Order / inventory state machines with status transitions?    → YES → Use this workflow
├── 🔒 Distributed locks, concurrency control, idempotent retry?    → YES → Use this workflow
├── 🔗 Cross-service MQ/RPC contracts or shared proto/model change? → YES → Use this workflow
├── 🗄️ Online schema migration or dual-write strategy?              → YES → Use this workflow
└── ⏱️ Estimated effort ≥ 3 person-days with high cost-of-failure?  → YES → Use this workflow

None of the above? → Standard workflow is fine ✓
```

---

## How It Works

**7-phase Claude Code workflow for high-stakes backend feature development:**

```
① Requirements & Design    → brainstorming skill
①.5 Architecture Review    → ADR (required for high-risk features)
② Implementation Plan      → writing-plans skill
③ Implementation           → subagent-driven-development skill
④ 🔥 4 Cross-Verification Passes   ← the core innovation
⑤ Fix Iteration            → writing-plans + subagent-driven-development
⑥ Careful Simplification   → skeptical optimization with anti-pattern checklist
⑦ Doc Sync                 → backfill evolution log + notify downstream
```

**The 4 AI verification passes:**

| Pass | Perspective | Typical yield |
|------|-------------|--------------|
| 4.1 Systematic self-review | Author as bug hunter | 1–3 bugs |
| **4.2 Cold-context review ⭐** | **AI reviewer with no design docs** | **5–15 concurrency / idempotency bugs** |
| 4.3 Behavior-preservation diff | Side-effect comparison vs master | 2–5 regressions |
| 4.4 Cross-repo impact scan | External services that may break | 0–3 impact points |
| 4.5 Business invariant matrix | Hard constraints: money / state / inventory | 0–2 violations |

> **Phase 4.2 is the highest-value step.** The AI reviewer sees only the code — not the design doc assumptions baked in by the author. That's exactly where systematic concurrency and idempotency bugs hide.

![Single-perspective review blind spot vs multi-round independent verification](images/cross-verified-skill-intro/review-blindspot-diagram.png)

Passes 4.3–4.5 are dispatched in parallel via subagents.

---

## Skills

| Skill | What it does | When to use |
|-------|-------------|-------------|
| [`prd-to-tasks`](#prd-to-tasks) | PRD → **codebase-aware task breakdown** with risk-driven workflow routing | Any PRD or requirements doc that needs to be translated into concrete engineering tasks |
| [`cross-verified-feature-development`](#cross-verified-feature-development) | 7-phase workflow with **4 independent AI verification passes** | Payments, state machines, distributed locks, cross-service contracts, schema migrations |

---

## Install (4 platforms supported)

Skills in this repo use the **Open Agent Skills standard format** (`SKILL.md` + YAML frontmatter) — natively compatible with Claude Code, Codex CLI, and OpenClaw. OpenCode requires manual adaptation.

**Step 1: Clone the repo**

```bash
git clone https://github.com/MageByte-Zero/magebyte-power.git
export SKILLS_REPO="$PWD/magebyte-power"
```

**Step 2: Install for your platform**

| Platform | Format compatibility | Skills directory |
|----------|---------------------|-----------------|
| **Claude Code** | ✅ Native | `~/.claude/skills/` |
| **Codex CLI** | ✅ Native | `~/.agents/skills/` |
| **OpenClaw** | ✅ Native | `~/.openclaw/skills/` |
| **OpenCode** | ⚠️ Requires adaptation | `~/.config/opencode/agents/` |

```bash
# Claude Code
mkdir -p ~/.claude/skills
ln -sf "$SKILLS_REPO/skills/cross-verified-feature-development" \
       ~/.claude/skills/cross-verified-feature-development
ln -sf "$SKILLS_REPO/skills/prd-to-tasks" \
       ~/.claude/skills/prd-to-tasks

# Codex CLI
mkdir -p ~/.agents/skills
ln -sf "$SKILLS_REPO/skills/cross-verified-feature-development" \
       ~/.agents/skills/cross-verified-feature-development
ln -sf "$SKILLS_REPO/skills/prd-to-tasks" \
       ~/.agents/skills/prd-to-tasks

# OpenClaw
mkdir -p ~/.openclaw/skills
ln -sf "$SKILLS_REPO/skills/cross-verified-feature-development" \
       ~/.openclaw/skills/cross-verified-feature-development
ln -sf "$SKILLS_REPO/skills/prd-to-tasks" \
       ~/.openclaw/skills/prd-to-tasks
```

> **Cross-platform tip:** `~/.agents/skills/` is the standard user-scoped directory in the Open Agent Skills ecosystem. Claude Code, Codex CLI, and OpenClaw all scan it automatically — install once, works across all three.

<details>
<summary><b>OpenCode adaptation</b> (click to expand)</summary>

OpenCode uses its own agent file format and does not read SKILL.md directly.  
Copy the skill content as a system prompt into an OpenCode agent file:

```bash
mkdir -p ~/.config/opencode/agents
# Create ~/.config/opencode/agents/cross-verified.md
# Example frontmatter:
# ---
# description: 7-phase high-stakes feature workflow with 4 independent AI verification passes
# mode: primary
# ---
# (paste SKILL.md body as the system prompt)
```

See [opencode.ai/docs/agents](https://opencode.ai/docs/agents) for the full format spec.

</details>

**Verify:**

```bash
# Claude Code
ls ~/.claude/skills/cross-verified-feature-development/SKILL.md
ls ~/.claude/skills/prd-to-tasks/SKILL.md

# Codex CLI / OpenClaw (shared path)
ls ~/.agents/skills/cross-verified-feature-development/SKILL.md
ls ~/.agents/skills/prd-to-tasks/SKILL.md
```

**Usage:**

```bash
# prd-to-tasks — paste a PRD link or describe the requirement
"help me break down this PRD into tasks"
"turn this requirements doc into engineering tasks"

# cross-verified-feature-development
/cross-verified-workflow implement idempotent refund API with distributed lock
```

---

## prd-to-tasks

### The core problem

PRD documents describe *what* to build. They don't tell you *where* in the codebase to build it, which services are affected, or what patterns are required. The gap between "PM handed me a doc" and "I have executable tasks with file paths and verify commands" is where hours disappear.

**This skill closes that gap with a 5-phase structured pipeline:**

```
Phase 0: PRD Ingestion      → Feishu/Lark URL, pasted text, or local file
Phase 1: Scope & Risk       → Map to affected services, classify 🔴/🟡/🟢 (gate)
Phase 2: Codebase Scan      → Locate real file paths, interfaces, DB tables
Phase 3: Spec Generation    → Structured design doc with invariants & failure modes (gate)
Phase 4: Task Breakdown      → Tasks with file paths, line numbers, verify commands (gate)
Phase 5: Workflow Routing   → Auto-route to cross-verified or standard superpowers flow
```

### What makes tasks different

Generic spec tools produce: *"implement user login → modify UserService"*

This skill produces:
> In the `CreateBooking` method at `order-service/internal/service/booking/booking_service.go:142`, add a feature flag check with key `platform_order_v2_enabled`, use `idgen.NextID()` to generate the new record ID, write to `db.WriteDB`, then execute `cache.DoubleDelete(ctx, key)` after the write — `make build && make test`.

### Risk routing

| Risk level | Criteria | Routes to |
|-----------|----------|-----------|
| 🔴 Critical | Financial flows, state machines, distributed locks, MQ contracts, schema migration | `cross-verified-feature-development` |
| 🟡 High | ≥ 3 person-days, multi-repo, core order path | `brainstorming` → `writing-plans` → `subagent-driven-development` |
| 🟢 Standard | New endpoints, stateless, single repo, < 3 days | `writing-plans` → implement |

### Setup required

`references/repo-map.md` is a team-customizable service map — replace the placeholder service names with your actual repos and services. **Accuracy here directly affects task quality.**

### Bundled reference files

| File | When to read |
|------|-------------|
| `references/service-patterns.md` | Phase 4 — 8 Go microservice patterns every task should check |
| `references/repo-map.md` | Phase 1 — customize with your team's services and repos |

---

## cross-verified-feature-development

### The core problem

Code Review has a structural blind spot: every reviewer shares the same design assumptions as the author. The more context you give reviewers, the harder it becomes for them to spot holes in your belief system. This is why the concurrency race in a payment refund API passed two reviewers — including the author himself.

**The fix:** multiple independent perspectives. N reviewers who don't share context produce a bug set that approaches a *union*, not a duplicate. This workflow operationalizes that insight:

> Design → Implement → **4 independent AI verification passes** → Fix → Simplify → Sync docs

![4-round cross-verification comparison](images/cross-verified-skill-intro/4-rounds-comparison.png)

### The 7 phases

```
① Requirements & Design    → superpowers:brainstorming
①.5 Architecture Review    → ADR (required for high-risk features)
② Implementation Plan      → superpowers:writing-plans
③ Implementation           → superpowers:subagent-driven-development
④ 🔥 4 Cross-Verification Passes   ← the core innovation
⑤ Fix Iteration            → writing-plans + subagent-driven-development
⑥ Careful Simplification   → skeptical optimization with anti-pattern checklist
⑦ Doc Sync                 → backfill evolution log + notify downstream
```

Each phase has explicit **Exit Criteria** — a checklist that must pass before moving forward.

![7-phase workflow diagram](images/cross-verified-skill-intro/7-phase-workflow.png)

### Cost vs. benefit

| Metric | Standard workflow | This workflow |
|--------|------------------|---------------|
| Extra time | — | **+40–50%** |
| Critical bug detection rate | ~40% | **~95%** |
| Phase 4.2 typical yield | 0 | **5–15 High/Critical bugs** |

40% more time for a 55-point improvement in bug detection rate. In payment and core state machine features, that trade-off is worth it.

### Bundled reference files

| File | When to read |
|------|-------------|
| `references/cross-verification-techniques.md` | Before Phase 4 — agent prompt templates for all 4 passes |
| `references/anti-patterns.md` | Before Phase 6 — 12 high-frequency trap patterns |
| `references/doc-sync-playbook.md` | Before Phase 7 — structured doc backfill playbook |
| `references/case-studies.md` | Optional — real-world bug museum from e-commerce order domain |

---

## Contributing

The best contributions are **workflows proven in production** — not perfect methodology, just processes that solved real problems.

```bash
mkdir -p skills/<skill-name>/references
# Create skills/<skill-name>/SKILL.md with name + description frontmatter
# Test on real tasks, then open a PR describing the domain and the problem it solves
```

---

## Read the story

📖 **[How I distilled 4 years of production incidents into a Claude Code Skill](articles/cross-verified-skill-intro.md)** (Chinese) — the production outage that started this, the "context contamination" insight, and the full design rationale.

---

<div align="center">

If this helped you, a **⭐ Star** goes a long way.

<br/>

Maintainer: [MageByte-Zero](https://github.com/MageByte-Zero) · [MIT License](LICENSE)

</div>

<!-- awesome list entry:
[magebyte-power](https://github.com/MageByte-Zero/magebyte-power) —
Claude Code skill for high-stakes backend features — 4-round AI review catches concurrency & idempotency bugs before prod
-->
