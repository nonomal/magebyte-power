# README 曝光度提升设计文档

**日期：** 2026-05-13  
**目标：** 提升 magebyte-power 仓库的 GitHub 搜索发现性、awesome list 收录率和 README 转化率  
**当前状态：** 17 stars，6 forks，仓库建立 9 天，已通过微信公众号推广一次

---

## 背景与问题

Skill 质量经过生产验证，但曝光不足。问题分两层：

1. **流量层**：GitHub 搜索发现性差，没有进入任何 awesome list
2. **转化层**：有访客进来但 README 前屏没有快速传达核心价值

目标受众三类：Claude Code 用户、AI 辅助开发的后端工程师、中文开发者。GitHub organic 搜索优先。

---

## 方案：全漏斗改造（Section 1 + 2 + 3）

### Section 1：README 结构重组

#### 当前结构问题

- "What is this?" 区块过于抽象，首屏扫一眼看不出价值
- 核心数字（每次发现 5–15 个 bug）埋在文档第四节
- GitHub 爬虫权重最高的 H1/H2 和前 200 字关键词密度不足

#### 新结构（英文 README）

```
[Hero image]
[Title]
[One-liner tagline]
[Badges]

## Why This Exists
  3 bullet TL;DR，每条 ≤12 词，包含核心数字（5–15 bugs）

## When To Use
  决策树（从现有第四节前移）

## How It Works
  7 phases 流程图 + 4 passes 对比表格（精简版）

## Install
## Deep Dive（原有详细内容）
## Contributing
```

#### 新结构（中文 README）

结构与英文保持一致。"先说一个故事" 保留，但移入 `## 为什么做这个` 区块内，不再单独置顶。故事是转化率最强资产，不删，但要服从结构。

#### 关键词策略

前 200 字需自然出现以下词：

- `claude code workflow`
- `ai code review`
- `concurrency bug`
- `idempotency`
- `backend feature development`
- `production incident`

---

### Section 2：Awesome List 适配

#### Canonical one-liner（93 chars）

```
Claude Code skill for high-stakes backend features — 4-round AI review catches concurrency & idempotency bugs before prod
```

同时用作：
- GitHub repo description（替换现有 description）
- README 首行 tagline
- 各 awesome list PR 的 entry 文本

#### README 底部隐藏注释

```markdown
<!-- awesome list entry:
[magebyte-power](https://github.com/MageByte-Zero/magebyte-power) —
Claude Code skill for high-stakes backend features — 4-round AI review
catches concurrency & idempotency bugs before prod
-->
```

供 awesome list 维护者查 source 时直接取用，无需自己概括。

#### "Maintained" 信号

- 添加 `last commit` badge（自动读取 push date）
- issue template 已存在 ✅

---

### Section 3：Awesome List 提交清单

#### 第一档（现在提交，无 star 门槛）

| 列表 | Stars | 提交描述侧重点 |
|------|-------|--------------|
| [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | 43.5k | Skills / workflows 类目，强调 skill 格式兼容 |
| [awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | 19.7k | 强调 subagent 并行 dispatch |
| [awesome-claude-code-plugins](https://github.com/ccplugins/awesome-claude-code-plugins) | 780 | Skill 类目，强调生产验证背景 |
| [Awesome-LLM](https://github.com/Hannibal046/Awesome-LLM) | 26.8k | Tools 类目，强调 workflow 完整性 |

#### 第二档（star ≥ 50 后提交）

| 列表 | 侧重点 |
|------|-------|
| awesome-prompt-engineering | Skill/prompt 格式，强调 SKILL.md 标准 |
| awesome-ai-agents | Multi-agent orchestration，强调 subagent 并行 |
| awesome-code-review | 强调 Phase 4.2 冷上下文评审的独特价值 |

#### 第三档（star ≥ 50 批量）

- awesome-chatgpt
- awesome-devtools
- awesome-software-engineering
- awesome-backend

#### PR 提交策略

- 每个 PR 描述：canonical one-liner + "When to use" 决策树截图
- 不同列表微调描述（code-review 列表突出 Phase 4.2，llm 列表突出 skill 格式）
- 第一档 PR 本周内提交

---

## 实施范围

| 工作项 | 文件 | 预估改动量 |
|-------|------|---------|
| README.md 结构重组 | `README.md` | 中（保留 80% 内容，调整顺序+前屏） |
| README.zh-CN.md 同步 | `README.zh-CN.md` | 中 |
| GitHub repo description 更新 | GitHub 设置 | 小 |
| README 底部加 awesome list 注释 | `README.md` | 小 |
| 第一档 awesome list PR × 3 | 外部仓库 | 小（各一个 PR） |

**不在此次范围内：** 新增 skill、修改 SKILL.md 内容、改变仓库 topics（已经很好）

---

## 成功指标

- 30 天内 star 从 17 → 80+
- 至少 1 个 awesome list 收录
- GitHub 搜索 "claude code workflow" 出现在前 3 页
