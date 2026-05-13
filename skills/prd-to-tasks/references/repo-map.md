# Service & Repo Map · 服务与仓库映射

> **Team customization required · 团队必须自定义**: Replace service/repo names below with your actual services. This file is the skill's codebase map — accuracy here directly affects task quality.
>
> 将下方服务和仓库名称替换为你团队的实际服务。这个文件是 skill 的代码库地图 — 这里的准确性直接影响任务质量。

---

## 框架代别 · Framework Generations

| 框架 · Framework | 仓库示例 · Example Repos | 特征 · Characteristics |
|-----------------|------------------------|----------------------|
| **旧框架 · Legacy framework** | bff-service, order-service, platform-order-service, fulfillment-service | 入口 `dock.Run` (generic dock/DI framework)，Consul 配置，`goconf:"section:key"` |
| **现代 DI 框架 · Modern DI framework (e.g. Kodkod/Wire)** | voucher-service, order-sla-service, procurement-service | wire DI，YAML 配置，`service/<name>/cmd/` 布局 |

---

## 服务 → 仓库 速查 · Service → Repo Quick Reference

### 消费者侧（C 端）· Consumer-Facing

| 业务域 · Domain | 仓库 · Repo | 关键服务 · Key Services | 典型入口 · Typical Entry |
|----------------|------------|------------------------|------------------------|
| App / Web BFF | `bff-service` | app-srv, web-srv, admin-srv | `cmd/<srvname>/`, `internal/service/` |
| 搜索聚合 · Search aggregation | `bff-service` | search-srv | |
| 用户下单 / 购物车 · Checkout / cart | `bff-service` | app-srv, web-srv | `internal/service/booking/` |

### 订单域 · Order Domain

| 业务域 · Domain | 仓库 · Repo | 关键服务 · Key Services | 典型入口 · Typical Entry |
|----------------|------------|------------------------|------------------------|
| 订单核心（创建/状态推进）· Order core (create/state advance) | `order-service` | order-api-service | `cmd/order-api-service/`, `internal/service/booking/` |
| 退款 / 售后 · Refunds / after-sales | `order-service` | refund-service | `cmd/refund-service/` |
| 钱包 / 余额 · Wallet / balance | `order-service` | wallet-service | |
| SLA / 超时处理 · SLA / timeout handling | `order-sla-service` | order-sla-srv | `service/order-sla-srv/` |
| 支付 · Payments | `payment-service` | payment-srv | `cmd/payment-service/` |
| 优惠券 · Vouchers | `voucher-service` | voucher-srv | `service/voucher-srv/` |

### 平台履约 · Platform Fulfillment

| 业务域 · Domain | 仓库 · Repo | 关键服务 · Key Services | 典型入口 · Typical Entry |
|----------------|------------|------------------------|------------------------|
| 平台订单生命周期 · Platform order lifecycle | `platform-order-service` | platform-order-srv | `cmd/platform-order-srv/`, `internal/service/order_v2/` |
| 平台履约交付 · Platform fulfillment delivery | `fulfillment-service` | fulfillment-srv | |
| 采购 / 资源管理 · Procurement / resource management | `procurement-service` | procurement-srv | `service/procurement-srv/` |

### 共享层 · Shared Layer

| 业务域 · Domain | 仓库 · Repo | 说明 · Notes |
|----------------|------------|-------------|
| 跨服务 proto / 共享模型 · Cross-service proto / shared models | `shared-models` | 只能新增，不能修改已有 field number；提交到 master · Only additions allowed; never modify existing field numbers; commit to master |
| Go SDK | `foundation-sdk` | 底层工具库 · Low-level utilities |
| 第三方库（旧）· Third-party libs (legacy) | `libs/` | GOPATH-style vendor |

---

## 常用命令速查 · Common Commands

```bash
# 通用 · Universal
make build          # 编译 · compile
make dep            # go mod download
make lint           # golangci-lint (or project-specific linter wrapper)
make test           # go test ./...
make doc            # swagger docs
make gen            # regenerate protobuf (where applicable)

# 现代 DI 框架服务本地运行 · Modern DI framework service local run
./bin/<srvname> --config.loader=file --config.file.path=./service/<srvname>/cmd/service-local

# 单服务构建 · Single service build
CGO_ENABLED=0 go build -o bin/<srvname> ./cmd/<srvname>/main.go

# Wire DI 重生成（现代 DI 框架）· Wire DI regeneration (Modern DI framework)
wire ./service/<name>/internal/wire
```

---

## PRD 信号 → 受影响服务 映射启发式 · PRD Signal → Affected Service Heuristics

| PRD 关键词 · PRD Keywords | 优先检查 · Check First |
|--------------------------|----------------------|
| 用户下单、加购物车、商品详情 · User checkout, add to cart, product detail | `bff-service` app-srv/web-srv |
| 订单状态、取消、改单 · Order status, cancellation, modification | `order-service` order-api-service |
| 退款、售后、理赔 · Refunds, after-sales, claims | `order-service` refund-service |
| 钱包、余额、积分 · Wallet, balance, points | `order-service` wallet-service |
| 支付、收款 · Payments, collections | `payment-service` |
| 优惠券、折扣 · Vouchers, discounts | `voucher-service` |
| 平台履约、资源交付 · Platform fulfillment, resource delivery | `platform-order-service` + `fulfillment-service` |
| 供应商管理、采购 · Supplier management, procurement | `procurement-service` |
| 超时、SLA · Timeouts, SLA | `order-sla-service` |
| 跨服务接口变更 · Cross-service interface change | `shared-models`（proto）先动 · move first |
