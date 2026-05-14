---
name: prd-to-tasks
description: "Translates a PRD / requirements document into codebase-aware engineering tasks, then routes to the right development workflow based on risk level.

Use this skill for any PRD / requirements document → engineering task conversion scenario. Even if the user just says 'help me analyze this requirement', 'break this PRD into tasks', 'the PM sent a requirements doc', or 'we need to build this feature for the sprint' — invoke this skill immediately, don't ask questions first.

Core difference from generic spec-driven-development:
(1) Scans the real codebase (services / interfaces / DB tables / MQ topics) using a user-maintained knowledge base — see ~/.claude/prd-to-tasks/ for your stack-specific mappings;
(2) Each task produced includes real file paths + line numbers + references to project-specific code patterns from your knowledge base;
(3) Automatically routes to cross-verified-feature-development or the standard superpowers workflow based on risk level.

Trigger phrases: PRD, requirements document, feature analysis, functional breakdown, sprint tasks, break down tasks, analyze requirements, how do we implement this, how should we build this."
---

# PRD → Tasks

> 从 PRD 到可执行工程任务的结构化转化流水线。核心价值：**代码库感知的任务拆解** + **风险驱动的工作流路由**。
>
> A structured pipeline from PRD to executable engineering tasks. Core value: **codebase-aware task breakdown** + **risk-driven workflow routing**.

## 本 skill 解决什么问题 · What Problem This Skill Solves

通用的 spec-driven-development 写出来的任务是"实现用户登录功能 → 修改 UserService" — 落地时还要花大量时间找代码。

Generic spec-driven-development produces tasks like "implement user login → modify UserService" — which still require significant time to locate the actual code when executing.

本 skill 写出来的任务是：
> 在 `order-service/internal/service/booking/booking_service.go:142` 的 `CreateBooking` 方法中加入 feature flag 检查，flag key 为 `new_order_flow_enabled`，使用项目 KB（`~/.claude/prd-to-tasks/service-patterns.md`）中记录的 ID 生成 helper 创建新单据 ID，写入数据库，写后按项目缓存失效协议执行失效 — 然后跑项目约定的 `build` + `test` 命令。

This skill produces tasks like:
> In the `CreateBooking` method at `order-service/internal/service/booking/booking_service.go:142`, add a feature flag check with key `new_order_flow_enabled`, use the ID generation helper documented in your project's KB (`~/.claude/prd-to-tasks/service-patterns.md`) to create the new record ID, write to the database, then execute your project's cache invalidation discipline — then run your project's `build` + `test` commands.

---

## 5 阶段工作流 · 5-Phase Workflow

```
Phase 0: PRD 摄取      → 读取文档 / 粘贴文本
         PRD Ingestion  → Read doc / paste text

Phase 1: 范围澄清      → 识别服务、风险定级（门控：人工确认）
         Scope Clarity  → Identify services, risk classification (gate: human confirmation)

Phase 2: 代码库扫描    → 找受影响的文件、接口、DB 表
         Codebase Scan  → Find affected files, interfaces, DB tables

Phase 3: Spec 生成     → 结构化设计文档（门控：人工确认）
         Spec Gen       → Structured design doc (gate: human confirmation)

Phase 4: 任务拆解      → 带路径 + 模式引用的可执行任务（门控：人工确认）
         Task Breakdown → Executable tasks with paths + pattern references (gate: human confirmation)

Phase 5: 工作流路由    → 决定接下来走哪个 superpowers 流程
         Workflow Route → Decide which superpowers flow to follow next
```

每个门控阶段必须等人工确认后才进入下一阶段。
Each gated phase must wait for explicit human confirmation before proceeding.

---

### Phase 0: PRD 摄取 · PRD Ingestion

接收 PRD 的三种形式：
Three ways to receive a PRD:

**A. Feishu/Lark 文档 URL · Feishu/Lark Doc URL**（`feishu.cn/docx/`、`feishu.cn/wiki/` etc.）
```bash
lark-cli docs +fetch --doc "<url>"
```
读取后提取：功能目标、验收标准、接口设计、状态机描述、上线时间节点。
After reading, extract: functional goals, acceptance criteria, interface design, state machine description, launch timeline.

**B. 粘贴的文本 · Pasted Text**：直接解析，梳理结构。
Parse directly and organize the structure.

**C. 本地文件路径 · Local File Path**：用 Read 工具读取。
Use the Read tool to read.

摄取完成后用 2-3 句话复述你理解的**核心业务目标**，让用户确认理解无误再继续。
After ingestion, summarize the **core business goal** in 2-3 sentences and ask the user to confirm your understanding before proceeding.

---

### Phase 1: 范围澄清与风险定级 · Scope Clarification & Risk Classification

#### 1.1 识别受影响的服务 · Identify Affected Services

参考 `references/repo-map.md` 把需求映射到具体仓库和服务：
Reference `references/repo-map.md` to map requirements to specific repos and services:

| 典型需求信号 · Typical Requirement Signal | 受影响的服务 · Affected Services |
|------------------------------------------|--------------------------------|
| 用户下单、购物车、商品详情 · User checkout, cart, product detail | `bff-service` |
| 订单状态、退款、钱包 · Order status, refunds, wallet | `order-service` (order-api-service / refund-service) |
| 平台订单履约 · Platform order fulfillment | `platform-order-service` |
| 供应商履约、资源交付 · Supplier fulfillment, resource delivery | `fulfillment-service` |
| 优惠券、库存 · Vouchers, inventory | `voucher-service` |
| 支付、收款 · Payments, collections | `payment-service` |
| 跨服务共享模型 / proto · Cross-service shared models / proto | `shared-models` |

#### 1.2 向用户澄清的问题模板 · Clarification Question Template

在问任何技术问题之前，先把你能从 PRD 和代码库中自行推断的信息全列出来（"我假设..." 格式），然后只问**无法自行判断**的事项：
Before asking any technical questions, list everything you can infer from the PRD and codebase ("I assume..." format), then only ask about what you **cannot determine yourself**:

```
我的初步判断（请确认或纠正）· My initial assessment (please confirm or correct):
1. 主要影响 order-service 的 order-api-service 和 platform-order-service
   Primarily affects order-service (order-api-service) and platform-order-service
2. 需要修改订单状态机（CreateOrder → ConfirmedOrder 路径）
   Need to modify the order state machine (CreateOrder → ConfirmedOrder path)
3. 有跨服务 MQ 协议变更（platform 侧需要新增消息类型）
   Cross-service MQ protocol change required (platform side needs new message type)

还需要你帮我确认 · Still need your confirmation:
Q1. 这个功能是否要分灰度上线，还是全量？（影响是否要加 feature flag）
    Should this feature roll out gradually (canary) or all at once? (affects whether we need a feature flag)
Q2. DB schema 是否有变更，还是纯逻辑改动？
    Is there a DB schema change, or is this purely logic?
Q3. 上线时间节点（影响拆解粒度和 task 优先级）
    Launch timeline (affects breakdown granularity and task priority)
```

#### 1.3 风险定级 · Risk Classification

定级结果决定后续工作流路由：
The classification result determines the downstream workflow routing:

| 风险层级 · Risk Level | 判定标准 · Criteria | 后续工作流 · Downstream Workflow |
|----------------------|--------------------|---------------------------------|
| 🔴 **Critical** | 资金流 / 退款 / 余额 / 状态机 / 分布式锁 / 跨服务 MQ 协议 / online schema 迁移 · Money flow / refunds / balance / state machine / distributed locks / cross-service MQ protocol / online schema migration | → `cross-verified-feature-development` |
| 🟡 **High** | 估算 ≥ 3 人日 / 多仓库联动 / 核心订单路径改造 · Estimated ≥ 3 person-days / multi-repo coordination / core order path changes | → `superpowers:brainstorming` → `writing-plans` → `subagent-driven-development` |
| 🟢 **Standard** | 纯新增接口 / 无状态机语义 / 单仓库 / < 3 人日 · Pure new endpoints / no state machine semantics / single repo / < 3 person-days | → `superpowers:writing-plans` → implement |

**呈现定级结果，等用户确认再继续。· Present the classification result and wait for user confirmation before proceeding.**

---

### Phase 2: 代码库扫描 · Codebase Scan

在扫描之前，先向用户确认仓库路径。不要自行假设目录位置。
Before scanning, confirm repo paths with the user. Do not assume directory locations.

#### 2.0 确认仓库目录 · Confirm Repo Directories

根据 Phase 1 识别的受影响服务，向用户提问：
Based on the affected services identified in Phase 1, ask the user:

```
我需要扫描以下仓库，请告诉我它们在你本地的路径：
I need to scan the following repos. Please tell me their local paths:

- order-service          → 路径 path？（例 e.g. ~/code/order-service）
- platform-order-service → 路径 path？（例 e.g. ~/code/platform-order-service）
- shared-models          → 路径 path？（如有 proto 变更 · if proto changes needed）

如果多个仓库在同一个父目录下（例如都在 ~/code/），
If multiple repos share a parent directory (e.g. all under ~/code/),
告诉我父目录就够了，我会自动定位子目录。
just tell me the parent directory — I'll locate subdirectories automatically.
```

用户确认路径后再开始扫描。如果用户说"我不确定"或"你自己找"，用 `find ~ -name "go.mod" -maxdepth 5` 辅助定位，但结果要让用户确认再扫。
Start scanning only after the user confirms paths. If the user says "I'm not sure" or "find it yourself", use `find ~ -name "go.mod" -maxdepth 5` to help locate repos, but confirm results with the user before scanning.

#### 2.1 扫描优先级 · Scan Priority

```bash
# 1. 找入口 handler（接口定义）· Find entry handlers (interface definitions)
grep -r "func.*Handler\|router\.\(GET\|POST\|PUT\)" <repo>/cmd/ --include="*.go" -l

# 2. 找受影响的 Service interface · Find affected Service interfaces
grep -r "type.*Service interface" <repo>/internal/ --include="*.go" -l

# 3. 找 DB 访问层（了解现有 schema）· Find DB access layer (understand existing schema)
grep -r "db\.WriteDB\|db\.ReadDB\|sqlx" <repo>/internal/ --include="*.go" -l

# 4. 找 MQ topics（跨服务消息）· Find MQ topics (cross-service messages)
grep -r "BrokerTopics\|KafkaTopics\|topic\." <repo>/internal/facade/mq/ --include="*.go"

# 5. 找 proto 定义（跨服务接口契约）· Find proto definitions (cross-service contracts)
find <repo> -name "*.proto" | head -20
```

#### 2.2 扫描产出 · Scan Output

整理出一张**受影响范围表**：
Produce an **affected scope table**:

```
受影响文件（初步）· Affected Files (preliminary):
├── order-service/internal/service/booking/booking_service.go  [修改 modify]
│   └── CreateBooking(): 需要加 platform_order 分支
│       needs platform_order branch
├── order-service/internal/facade/mq/topic.go                  [修改 modify]
│   └── BrokerTopics + KafkaTopics 需同步新增 topic
│       need to add topic to both slices in sync
├── shared-models/proto/order/order.proto                       [修改? modify?]
│   └── 待确认是否需要新增字段 · pending confirmation on new field
└── platform-order-service/internal/service/order_v2/          [新增消费者 new consumer]
```

扫描过程中发现的**隐性风险**（如发现并发写、无幂等保护、旧版本兼容问题）立刻标注 ⚠️ 并纳入 Phase 3 的不变式清单。
Any **hidden risks** discovered during scanning (e.g. concurrent writes, missing idempotency protection, backward compatibility issues) must be flagged immediately with ⚠️ and added to the Phase 3 invariants list.

---

### Phase 3: Spec 生成 · Spec Generation

基于摄取的 PRD + 代码扫描结果，生成结构化设计文档。
Based on the ingested PRD + codebase scan results, generate a structured design document.

**默认保存到 · Default save path**：`docs/specs/YYYY-MM-DD-<feature-name>.md`（in the primary affected repo）。

**Spec 模板 · Spec Template:**

```markdown
# Spec: <Feature Name>

## 业务目标 · Business Goal
[PRD 核心目标 + 验收标准，1-3 条 · PRD core objectives + acceptance criteria, 1-3 items]

## 受影响的服务与仓库 · Affected Services & Repos
| 服务 Service | 仓库 Repo | 影响类型 Impact Type（新增/修改/契约变更 add/modify/contract change）|
|-------------|----------|------------------------------------------------------------------|

## 技术方案 · Technical Approach
[核心技术路径。每个关键决策点写明：选了什么，为什么不选备选方案
Core technical path. For each key decision: what was chosen and why alternatives were rejected]

## API 契约变更 · API Contract Changes
[如有新增/修改 RPC / HTTP 接口，贴请求响应 schema
If new/modified RPC or HTTP interfaces, include request/response schema]

## 数据模型变更 · Data Model Changes
[DB schema diff / proto field 变更。shared-models rules：不得修改已有 field number
DB schema diff / proto field changes. shared-models rules: never modify existing field numbers]

## 不变式清单 · Invariants
[业务层硬约束，例："同一 booking_id 最多产生一次资金变动"
Hard business constraints, e.g. "a single booking_id can generate at most one financial transaction"]

## 失败模式分析 · Failure Mode Analysis
[至少列 4 种：正常路径崩溃 / 重试覆盖 / 并发竞态 / 下游超时
At least 4: happy-path crash / retry idempotency / concurrent race / downstream timeout]

## 部署策略 · Deployment Strategy
[ ] 全量 Full rollout
[ ] Feature Flag（key: ___）
[ ] 灰度 Canary（比例 percentage: ___）
[ ] 双写切换 Dual-write switch

## 风险层级 · Risk Level
🔴 Critical / 🟡 High / 🟢 Standard（见 Phase 1.3 · see Phase 1.3）

## 回滚标准 · Rollback Criteria
[什么指标异常时触发回滚，谁来决定
Which metric anomaly triggers rollback, and who decides]

## 成功标准 · Success Criteria
[具体可测量的完成条件 · Specific measurable completion conditions]

## 遗留问题 · Open Questions
[尚未确认的事项，带负责人 · Unresolved items with assigned owners]
```

**门控 · Gate**：把 spec 展示给用户，等待明确的"确认"或修改意见，再进入 Phase 4。
Show the spec to the user and wait for explicit confirmation or revision requests before entering Phase 4.

---

### Phase 4: 任务拆解 · Task Breakdown

Spec 确认后，拆解为**可独立执行、可独立验证**的工程任务。
After spec is confirmed, break down into **independently executable, independently verifiable** engineering tasks.

#### 4.1 任务格式 · Task Format

每个任务必须包含：
Each task must include:

```markdown
### Task N: <动词 + 宾语，描述做什么 · verb + object, describe what to do>

**仓库 Repo**: <service-name>
**文件 File**: `path/to/file.go`（如果是修改现有文件，带行号范围 · if modifying existing file, include line range）
**类型 Type**: 新增 add / 修改 modify / 删除 delete / 契约变更 contract change

**具体改动 · Specific Changes**:
[用代码片段说明，不用散文描述 · Use code snippets, not prose]

**关联代码模式** (见 `references/service-patterns.md`) **· Associated Code Patterns** (see `references/service-patterns.md`):
- [ ] 使用 `idgen.NextID()` 生成主键（不用自增 ID · not auto-increment ID）
- [ ] 写后执行 `cache.DoubleDelete(ctx, key)`（如有 Redis mirror · if Redis mirror exists）
- [ ] BrokerTopics + KafkaTopics 同步更新（如有新增 MQ topic · if new MQ topic added）
- [ ] shared-models proto 只新增 field（不修改已有 field number · never modify existing field numbers）

**验证命令 · Verification Commands**:
\`\`\`bash
make build   # 编译不出错 · compiles without error
make test    # 相关 test 通过 · relevant tests pass
make lint    # lint 无新增 error · no new lint errors
\`\`\`

**依赖 Dependencies**: Task X, Task Y（前置任务 · prerequisite tasks）
**风险标注 Risk Notes**: ⚠️ 并发写 concurrent write / ⚠️ 跨仓库契约变更 cross-repo contract change / ...（如有 if any）
```

#### 4.2 任务排序原则 · Task Ordering Principles

1. **契约先行 · Contract First**：修改 proto / shared-models 的任务排最前（其他仓库 depend on it）
   Tasks that modify proto / shared-models go first (other repos depend on them)
2. **DB schema 先行 · DB Schema First**：online DDL 排在逻辑实现之前
   Online DDL before logic implementation
3. **单仓库内 · Within a single repo**：先写接口定义，再写实现，最后写 consumer
   Interface definition → implementation → consumer
4. **测试与实现并行 · Tests alongside implementation**：每个 task 在同一 batch 里包含对应的测试 task
   Each task includes corresponding test tasks in the same batch

#### 4.3 工作量估算 · Effort Estimation

每个 task 给出：S（< 2h）/ M（2-4h）/ L（> 4h）。L 级 task 应考虑进一步拆分。
Each task gets: S (< 2h) / M (2–4h) / L (> 4h). L-sized tasks should be considered for further breakdown.

**门控 · Gate**：展示完整任务列表（含风险标注），等待用户确认再进入 Phase 5。
Show the complete task list (including risk annotations) and wait for user confirmation before entering Phase 5.

---

### Phase 5: 工作流路由 · Workflow Routing

任务清单确认后，根据 Phase 1.3 的风险定级决定后续工作流：
After the task list is confirmed, decide the downstream workflow based on the Phase 1.3 risk classification:

```
风险层级 = 🔴 Critical?
Risk level = 🔴 Critical?
│
├── YES → 建议走 cross-verified-feature-development
│         Recommend cross-verified-feature-development
│         (额外 4 轮交叉验证：自查 / 冷评审 / 行为差异 diff / 跨仓库影响扫描
│          4 additional cross-verification rounds: self-review / cold review /
│          behavior diff / cross-repo impact scan)
│         预期额外成本：+40-50% 时间 · Expected additional cost: +40–50% time
│         说明：将把 Phase 3 的 spec 文档和 Phase 4 的任务清单作为输入
│         Note: Phase 3 spec doc and Phase 4 task list serve as inputs
│
├── 🟡 High → superpowers:brainstorming → superpowers:writing-plans
│              → superpowers:subagent-driven-development
│              说明：brainstorming 阶段可以把本 skill 产出的 spec 作为起点
│              Note: brainstorming phase can use this skill's spec output as a starting point
│
└── 🟢 Standard → superpowers:writing-plans → 直接实施 implement directly
                  说明：本 skill 产出的任务清单直接作为 writing-plans 的输入
                  Note: this skill's task list feeds directly into writing-plans
```

**向用户说明工作流选择的理由和代价，让用户决定**。不要强制拉人走高代价流程，但不要默默降级而不告知。
**Explain the rationale and cost of the workflow choice to the user and let them decide.** Don't force anyone into a high-cost workflow, but don't silently downgrade without disclosure.

---

## 常见合理化借口 · Common Rationalization Excuses

| 借口 · Excuse | 现实 · Reality |
|--------------|---------------|
| "需求很简单，直接写代码就好" · "The requirement is simple, let's just write code" | 简单需求也需要确认受影响的服务 — 越"简单"的改动越容易漏掉跨服务影响 · Simple requirements still need affected service confirmation — the "simpler" a change seems, the more likely cross-service impact is missed |
| "代码扫描耽误时间，我知道在哪改" · "Code scanning wastes time, I know where to make changes" | 扫描的目的是发现你**不知道**的依赖和隐患，不是找你已知的文件 · The point of scanning is to find dependencies and risks you **don't know about**, not to locate files you already know |
| "先做任务，spec 后面补" · "Start on tasks first, write the spec later" | Spec 的价值在于**在写代码前**暴露设计漏洞，事后补的是文档不是 spec · The value of a spec is exposing design flaws **before writing code** — writing it afterward produces documentation, not a spec |
| "风险不高，不用走 cross-verified" · "Risk isn't high, don't need cross-verified" | cross-verified 的价值来自独立视角，不是来自"这个功能我觉得危险" · The value of cross-verified comes from independent perspective, not from the developer's own risk assessment |

---

## 参考文件 · Reference Files

| 文件 · File | 何时读 · When to Read |
|------------|----------------------|
| `references/repo-map.md` | Phase 1 识别受影响服务时 · Phase 1: identifying affected services |
| `references/service-patterns.md` | Phase 4 拆任务时，检查关联代码模式 · Phase 4: breaking down tasks, checking associated code patterns |
