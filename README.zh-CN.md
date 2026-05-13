<div align="center">

<img src="images/cross-verified-skill-intro/cross-verified-skill-intro-cover.png" alt="MageByte Power Skills" width="900"/>

# ⚡ MageByte Power Skills

**为高风险后端特性设计的 Claude Code Skill — 4 轮 AI 交叉验证，在生产前拦截并发与幂等 bug**

<br/>

[![GitHub Stars](https://img.shields.io/github/stars/MageByte-Zero/magebyte-power?style=social)](https://github.com/MageByte-Zero/magebyte-power/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT%20%E2%80%94%20Use%20it%2C%20modify%20it%2C%20share%20it-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Compatible-8B5CF6?logo=anthropic&logoColor=white)](https://claude.ai/code)
[![Last Commit](https://img.shields.io/github/last-commit/MageByte-Zero/magebyte-power)](https://github.com/MageByte-Zero/magebyte-power/commits/main)
[![English](https://img.shields.io/badge/README-English-blue)](README.md)

</div>

---

## 为什么做这个

> 2024 年，我们一个支付退款接口上线两小时后出了问题：**用户重复收到退款**。
>
> 这段代码经过了两次 Code Review，包括我自己 review 了一遍。没有人发现那个并发竞态——两个请求在幂等键写入和读取之间的极短窗口里，各自独立完成了退款流程。
>
> 不是大家不认真。是 **Code Review 本身有一个结构性盲点**：所有 reviewer 共享同一套上下文和设计假设。你给的信息越多，reviewer 就越难发现你信念系统里的漏洞。

这就是我开发这个 Skill 的起点。

**这个工作流用 4 轮独立 AI 验证解决这个问题：**

- 🔍 **每次冷评审发现 5–15 个并发 / 幂等 bug** — reviewer 只拿到代码，不拿设计文档
- ⚡ **4.3–4.5 阶段并行执行** — 行为 diff、跨仓库扫描、业务不变式同时跑
- 🏗️ **无需额外插件** — 每个阶段都有 Claude Code 原生工具的 fallback

---

## 什么时候该用

```
特性是否命中以下任一项？
│
├── 💰 资金流 / 支付 / 退款 / 结算？                    → 是 → 走本工作流
├── 🔄 订单 / 库存状态机，有状态转换逻辑？               → 是 → 走本工作流
├── 🔒 分布式锁 / 并发控制 / 幂等重试？                  → 是 → 走本工作流
├── 🔗 跨服务 MQ/RPC 协议或共享 proto/model 变更？       → 是 → 走本工作流
├── 🗄️ 在线 schema 迁移或双写切换策略？                  → 是 → 走本工作流
└── ⏱️ 预估工作量 ≥ 3 人日，且失败代价高？              → 是 → 走本工作流

以上都不命中？ → 普通工作流即可 ✓
```

**一句话判定**：如果「这个 feature 最坏的 bug 会怎样」的答案包含**资金损失 / 数据错乱 / 订单卡死 / 权限越权**，就值得走本工作流。

---

## 怎么运作的

**7 阶段高风险后端特性开发工作流：**

```
① 需求/设计          → brainstorming skill
①.5 架构决策评审     → ADR：高风险特性必做
② 实施计划           → writing-plans skill
③ 实施              → subagent-driven-development skill
④ 🔥 4 轮独立交叉验证 ← 核心创新
⑤ 迭代修复           → writing-plans + subagent-driven-development
⑥ 谨慎简化           → 带怀疑的优化 + anti-patterns 清单
⑦ 文档同步           → 强制回填 evolution log
```

**4 轮 AI 独立验证：**

| 轮次 | 视角 | 典型产出 |
|------|------|---------|
| 4.1 系统自查 | 自己扮演 bug 猎人 | 1–3 个 bug |
| **4.2 冷上下文评审 ⭐** | **不读设计文档**的独立 AI reviewer | **5–15 个并发 / 幂等 bug** |
| 4.3 行为保持 diff | 对比 master vs feature 副作用 | 2–5 处语义回归 |
| 4.4 跨仓库影响扫描 | 识别其他服务联动影响 | 0–3 个外部影响点 |
| 4.5 业务不变式矩阵 | 验证资金 / 状态机 / 库存硬约束 | 0–2 个不变式被破坏 |

> **4.2 冷上下文评审是价值密度最高的步骤。** Reviewer 只拿到代码，不拿设计文档——这才是真正独立的视角，也最接近生产环境里陌生工程师维护你代码时的状态。

![单一视角 Review 盲点 vs 多轮独立验证](images/cross-verified-skill-intro/review-blindspot-diagram.png)

4.3–4.5 支持并行 dispatch 多个 subagent，时间开销几乎不叠加。

---

## 已收录 Skills

| Skill | 核心价值 | 适用场景 |
|-------|---------|---------|
| [`cross-verified-feature-development`](#cross-verified-feature-development-详解) | 7 阶段工作流 + **4 轮独立 AI 交叉验证** | 支付 / 状态机 / 并发控制 / 跨服务改造 / schema 迁移 |

> 更多 Skill 正在根据生产事故持续沉淀中。欢迎 Star 关注更新。

---

## 安装（支持 4 个平台）

本仓库的 Skill 使用 **Open Agent Skills 标准格式**（`SKILL.md` + YAML frontmatter），与 Claude Code、Codex CLI、OpenClaw 原生兼容，OpenCode 需要适配。

**第一步：克隆仓库**

```bash
git clone https://github.com/MageByte-Zero/magebyte-power.git
export SKILLS_REPO="$PWD/magebyte-power"
```

**第二步：按平台安装**

| 平台 | Skill 格式兼容性 | Skill 目录 |
|------|---------------|----------|
| **Claude Code** | ✅ 原生支持 | `~/.claude/skills/` |
| **Codex CLI** | ✅ 原生支持 | `~/.agents/skills/` |
| **OpenClaw** | ✅ 原生支持 | `~/.openclaw/skills/` |
| **OpenCode** | ⚠️ 需要适配 | `~/.config/opencode/agents/` |

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

> **跨平台通用路径提示：** `~/.agents/skills/` 是 Open Agent Skills 生态的标准用户目录，Claude Code、Codex CLI、OpenClaw 均会自动扫描——安装到这里一次，三端同时生效。

<details>
<summary><b>OpenCode 适配说明</b>（点击展开）</summary>

OpenCode 使用独立的 agent 文件格式，不直接读取 SKILL.md。  
将 `skills/cross-verified-feature-development/SKILL.md` 的正文内容作为 system prompt，写入 OpenCode agent 文件：

```bash
mkdir -p ~/.config/opencode/agents
# 创建 ~/.config/opencode/agents/cross-verified.md
# frontmatter 示例：
# ---
# description: 7-phase high-stakes feature workflow with 4 independent AI verification passes
# mode: primary
# ---
# （正文粘贴 SKILL.md 内容）
```

详细格式参考：[opencode.ai/docs/agents](https://opencode.ai/docs/agents)

</details>

**验证安装**

```bash
# Claude Code
ls ~/.claude/skills/cross-verified-feature-development/SKILL.md

# Codex CLI / OpenClaw 通用路径
ls ~/.agents/skills/cross-verified-feature-development/SKILL.md
```

**触发方式**

```bash
# Claude Code
/cross-verified-workflow 实现支付退款接口，需要保证幂等性和并发安全

# Codex CLI / OpenClaw
$cross-verified-feature-development 实现幂等退款接口
```

或者直接描述高风险特性，Skill 会自动检测相关模式并主动建议使用本工作流。

---

## cross-verified-feature-development 详解

### 核心洞察：独立视角 = 独立信号

用 N 个互不知情的 reviewer 审查同一段代码，**发现的 bug 集合接近并集，而不是重复集合**。

问题在于：传统 Code Review 里，所有 reviewer 都读过设计文档——他们共享同一套假设。「这里应该幂等」变成了「这里已经幂等了」的默认，真正的漏洞就在这个默认里溜走。

这个工作流把「独立视角」这个洞察系统化：

> **设计 → 实施 → 4 轮独立 AI 交叉验证 → 修复 → 谨慎简化 → 文档同步**

![4 轮独立视角验证对比](images/cross-verified-skill-intro/4-rounds-comparison.png)

### 7 个阶段

```
① 需求/设计          → 把模糊诉求结构化为含不变式、失败模式、风险表格的完整 spec
①.5 架构决策评审     → ADR：在动代码之前把关键技术决策显式验证一遍（高风险特性必做）
② 实施计划           → 把 spec 拆成有文件+行号+验证命令的可执行 task 清单
③ 实施              → 每个 task 在 fresh subagent 中独立执行，消除累积偏差
④ 🔥 4 轮独立交叉验证 ← 本工作流的核心创新
⑤ 迭代修复           → 发现问题再走一轮 plan + execute，修复阶段与实施同等严谨
⑥ 谨慎简化           → 带怀疑的优化，用 anti-patterns 清单守住「越优化越错」的陷阱
⑦ 文档同步           → 强制回填 evolution log，避免给下一个维护者埋雷
```

每个阶段都有明确的 Exit Criteria（完成标准检查列表），不满足不能进入下一阶段。

![7 阶段工作流](images/cross-verified-skill-intro/7-phase-workflow.png)

### 成本 vs 收益

| 指标 | 普通工作流 | 本工作流 |
|------|-----------|---------|
| 额外时间成本 | — | **+40–50%** |
| Critical Bug 发现率 | ~40% | **~95%** |
| 4.2 冷评审每次典型产出 | 0 | **5–15 个 High/Critical Bug** |

40% 的额外时间，换来 55 个百分点的 Bug 发现率提升。**在涉及资金和核心状态机的场景下，这是值得的。**

### 内含参考文件

| 文件 | 何时读 | 内容 |
|------|-------|------|
| `references/cross-verification-techniques.md` | Phase 4 开始前 | 每种验证的完整 agent prompt 模板 |
| `references/anti-patterns.md` | Phase 6 开始前 | 12 个高频踩坑模式（越简化越错的陷阱清单）|
| `references/doc-sync-playbook.md` | Phase 7 开始前 | 规范化文档回填流程 |
| `references/case-studies.md` | 选读 | 电商订单域的真实 Bug 博物馆 |

---

## 与通用 Skills 生态的关系

本仓库的 Skill 是**领域增强层**，可与通用工程 skill（`brainstorming`、`writing-plans`、`systematic-debugging` 等）配合使用：

- 通用 skill 告诉 Claude「如何思考」（brainstorming、planning、debugging）
- 本仓库告诉 Claude「在高风险后端特性开发中，每个阶段具体该做什么」

两者叠加，才能实现从「AI 辅助」到「AI 主导严谨工程流程」的真正跃迁。

> **没有通用 skill 也能用**——每个阶段都有详细的 fallback 说明。

---

## 贡献新 Skill

本仓库的 Skill 来自真实工程实践。**最有价值的贡献是在生产环境验证过的工作流**——不需要是完美的方法论，只需要是解决过真实问题的流程。

```bash
# 1. 创建 skill 目录
mkdir -p skills/<skill-name>/references

# 2. 编写 SKILL.md（必须有 name 和 description frontmatter）
cat > skills/<skill-name>/SKILL.md << 'EOF'
---
name: <skill-name>
description: <触发时机描述，尽量具体，包含关键词和场景>
---

# 正文内容
EOF

# 3. 验证安装
ln -sf "$PWD/skills/<skill-name>" ~/.claude/skills/<skill-name>
```

PR 中请说明：这个 Skill 解决了什么真实场景的问题，以及你在哪类项目中用过它。

---

## 延伸阅读

📖 **[我把 4 年踩坑经验「蒸馏」成 Claude Code Skill 开源了](articles/cross-verified-skill-intro.md)**

从退款接口的生产事故，到「上下文污染」的发现，到这套工作流的完整设计逻辑。如果你想理解「为什么要这么设计」而不只是「怎么用」，这篇文章值得一读。

---

<div align="center">

如果这个项目帮到了你，欢迎点一个 **⭐ Star**

每一个 Star 都是继续把生产经验开源出来的动力。

<br/>

Maintainer: [MageByte-Zero](https://github.com/MageByte-Zero) · [MIT License](LICENSE) · [English README](README.md)

</div>

<!-- awesome list entry:
[magebyte-power](https://github.com/MageByte-Zero/magebyte-power) —
Claude Code skill for high-stakes backend features — 4-round AI review catches concurrency & idempotency bugs before prod
-->
