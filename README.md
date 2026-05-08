<div align="center">

<img src="images/cross-verified-skill-intro/cross-verified-skill-intro-cover.png" alt="MageByte Power Skills" width="900"/>

# ⚡ MageByte Power Skills

**Production-incident-distilled Claude Code Superpowers Skills**

Every line of SKILL.md is backed by a real production outage.

<br/>

[![GitHub Stars](https://img.shields.io/github/stars/MageByte-Zero/magebyte-power?style=social)](https://github.com/MageByte-Zero/magebyte-power/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Compatible-8B5CF6?logo=anthropic&logoColor=white)](https://claude.ai/code)
[![Superpowers](https://img.shields.io/badge/Superpowers-Enhanced-FF6B35)](https://superpowers.anthropic.com/)
[![中文文档](https://img.shields.io/badge/文档-中文版（推荐）-red)](README.zh-CN.md)

</div>

> 🇨🇳 **中文用户推荐阅读 [中文文档](README.zh-CN.md)** — 包含完整故事背景、设计原理和使用指南。

---

## What is this?

A library of **domain-specific orchestration skills** for the [Claude Code Superpowers](https://superpowers.anthropic.com/) ecosystem.

Superpowers provides general-purpose engineering skills: `brainstorming`, `writing-plans`, `code-reviewer`, `systematic-debugging`, `subagent-driven-development`. This repo wires them together into opinionated, field-tested workflows for specific high-stakes domains — so you get the full power of the ecosystem without manually chaining skills together.

```
Your prompt
    │
    ▼
cross-verified-feature-development   ← this repo
    │
    ├── Phase 1    →  superpowers:brainstorming
    ├── Phase 2    →  superpowers:writing-plans
    ├── Phase 3    →  superpowers:subagent-driven-development
    ├── Phase 4.1  →  superpowers:systematic-debugging
    ├── Phase 4.2  →  superpowers:code-reviewer  (cold-context — no design docs) ⭐
    ├── Phase 4.3–4.5 → custom agents            behavior diff / cross-repo / invariants
    └── Phase 5    →  writing-plans + subagent-driven-development
```

**Works without Superpowers** — every phase has a documented fallback using Claude Code's built-in tools.

---

## Skills

| Skill | What it does | When to use |
|-------|-------------|-------------|
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

# Codex CLI
mkdir -p ~/.agents/skills
ln -sf "$SKILLS_REPO/skills/cross-verified-feature-development" \
       ~/.agents/skills/cross-verified-feature-development

# OpenClaw
mkdir -p ~/.openclaw/skills
ln -sf "$SKILLS_REPO/skills/cross-verified-feature-development" \
       ~/.openclaw/skills/cross-verified-feature-development
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

**Step 3 (Claude Code only): Install Superpowers**

```bash
npm install -g @anthropic-ai/claude-code
claude mcp add --transport http superpowers https://superpowers.anthropic.com/mcp
```

Codex CLI / OpenClaw / OpenCode users can skip this — every phase has a documented fallback.

**Verify:**

```bash
# Claude Code
ls ~/.claude/skills/cross-verified-feature-development/SKILL.md

# Codex CLI / OpenClaw (shared path)
ls ~/.agents/skills/cross-verified-feature-development/SKILL.md
```

**Usage:**

```bash
# Claude Code
/cross-verified-workflow implement idempotent refund API with distributed lock

# Codex CLI / OpenClaw
$cross-verified-feature-development implement idempotent refund API
```

---

## cross-verified-feature-development

### The core problem

Code Review has a structural blind spot: every reviewer shares the same design assumptions as the author. The more context you give reviewers, the harder it becomes for them to spot holes in your belief system. This is why the concurrency race in a payment refund API passed two reviewers — including the author himself.

**The fix:** multiple independent perspectives. N reviewers who don't share context produce a bug set that approaches a *union*, not a duplicate. This workflow operationalizes that insight:

> Design → Implement → **4 independent AI verification passes** → Fix → Simplify → Sync docs

![Single-perspective review blind spot vs multi-round independent verification](images/cross-verified-skill-intro/review-blindspot-diagram.png)

### The 4 verification passes

| Pass | Perspective | Information scope | Typical yield |
|------|-------------|-------------------|--------------|
| 4.1 Systematic self-review | Author as bug hunter | Full context | 1–3 bugs |
| **4.2 Cold-context review ⭐** | **Reviewer with no design docs** | Code only | **5–15 concurrency / idempotency bugs** |
| 4.3 Behavior-preservation diff | Side-effect comparison vs master | Diff + dependency graph | 2–5 regressions |
| 4.4 Cross-repo impact scan | External services that may need changes | Multi-repo call graph | 0–3 impact points |
| 4.5 Business invariant matrix | Hard constraints: money / state / inventory | Business rules | 0–2 violations |

> **Phase 4.2 is the highest-value step.** Typical yield: 5–15 Critical/High bugs per review that standard code review systematically misses — because the reviewer only sees the code, not the assumptions the author embedded in the design doc.

![4-round cross-verification comparison](images/cross-verified-skill-intro/4-rounds-comparison.png)

Passes 4.3–4.5 are dispatched in parallel via subagents.

### When to use

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
