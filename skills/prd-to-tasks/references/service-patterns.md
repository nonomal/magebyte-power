# Service Code Patterns · 服务代码模式速查

任务拆解（Phase 4）时，检查每个 task 是否触及以下模式并在任务里显式标注。
During task breakdown (Phase 4), check whether each task touches any of the following patterns and explicitly annotate tasks that do.

---

## P1: ID 生成 · ID Generation

**规则 · Rule**：所有主键必须来自分布式 ID 服务，禁止 DB 自增 ID。
All primary keys must come from the distributed ID service. DB auto-increment IDs are forbidden.

```go
id, err := idgen.NextID()
if err != nil {
    return err
}
```

**触发时机 · When to apply**：任何需要创建新业务实体（订单、履约单、退款单、优惠券等）的 task。
Any task that creates a new business entity (orders, fulfillment records, refund records, vouchers, etc.).

---

## P2: DB 读写分离 · DB Read/Write Splitting

**规则 · Rule**：写走 `db.WriteDB`，读走 `db.ReadDB`（读副本）。
Writes go to `db.WriteDB`, reads go to `db.ReadDB` (read replica).

```go
// 写 Write
writeDB := db.WriteDB

// 读（开启读副本路由）· Read (enable read-replica routing)
ctx = db.WithReadReplica(ctx)

// 或 middleware 层开启 · or enable at middleware level
// read replica middleware
```

**触发时机 · When to apply**：所有 DB 访问 task。事务内不拆分读写。
All DB access tasks. Do not split reads and writes inside a transaction.

---

## P3: Redis 缓存双删 · Redis Cache Double-Delete

**规则 · Rule**：每次 DB 写操作后，对有 Redis mirror 的 key 执行延迟双删。
After every DB write, execute a delayed double-delete on any Redis-mirrored key.

```go
cache.DoubleDelete(ctx, key)
```

**触发时机 · When to apply**：任何写 DB 且有对应 Redis 缓存的 task。不写双删 = 缓存可能长期脏读。
Any task that writes to DB and has a corresponding Redis cache. Skipping the double-delete risks persistent stale reads from the cache.

---

## P4: MQ Topics 同步 · MQ Topics Sync

**规则 · Rule**：`internal/facade/mq/topic.go` 里有两个 slice 必须**同时**更新：`BrokerTopics`（内部 broker）和 `KafkaTopics`（直连 Kafka）。
The file `internal/facade/mq/topic.go` contains two slices that must be updated **simultaneously**: `BrokerTopics` (internal broker) and `KafkaTopics` (direct Kafka).

```go
// 两个都要加，缺一不可 · Both must be updated — neither can be omitted
var BrokerTopics = []string{
    "order.booking.created",
    // 新增 topic 加这里 · add new topics here
}
var KafkaTopics = []string{
    "order.booking.created",
    // 同步加这里 · keep in sync here
}
```

**触发时机 · When to apply**：任何新增或修改 MQ 消息的 task。
Any task that adds or modifies MQ messages.

---

## P5: proto / shared-models 兼容性 · proto / shared-models Compatibility

**规则 · Rules**：
- 只允许**新增** field，不能修改或删除已有 field number
  Only **adding** fields is allowed; modifying or deleting existing field numbers is forbidden
- 不能重命名已有 service name、method name、field name
  Renaming existing service names, method names, or field names is forbidden
- 跨项目 proto 放 `shared-models`；项目内部 proto 放 `<project>/srvproto/`
  Cross-project proto goes in `shared-models`; project-internal proto goes in `<project>/srvproto/`
- package name 以 `pb` 结尾 · Package names end in `pb`
- 只提交到 master 分支 · Only commit to the master branch

```protobuf
// 正确：新增 field（用下一个可用 number）
// Correct: adding a new field (use the next available number)
message OrderInfo {
  int64 order_id = 1;
  string status = 2;
  // 新增 · new:
  string platform_order_id = 3;  // ✅ 新增 field · adding new field
}

// 错误：修改已有 field number
// Wrong: modifying an existing field number
// int64 old_field = 1; → string new_field = 1;  ❌
```

**触发时机 · When to apply**：任何需要修改跨服务接口契约的 task。
Any task that modifies a cross-service interface contract.

---

## P6: 日志规范 · Logging Standards

**规则 · Rule**：所有日志必须带 `requestID`，使用项目 logger helper。
All log entries must include `requestID` and use the project logger helper.

```go
log.InfoCtx(ctx, "doing X, param=%v order_id=%v", val, orderID)
log.ErrorCtx(ctx, "failed to do X, err=%v", err)
```

**触发时机 · When to apply**：所有新增业务逻辑路径的 task（入参、关键状态变更、错误路径至少各一条日志）。
All tasks that add new business logic paths (at minimum: one log for input, one for key state change, one for error path).

---

## P7: Service 层模式（旧框架）· Service Layer Pattern (Legacy Framework)

所有 Service 暴露接口 + impl，scoped 到请求 context：
All Services expose interface + impl, scoped to the request context:

```go
type BookingService interface {
    CreateBooking(ctx context.Context, req *CreateBookingReq) (*CreateBookingResp, error)
}

type BookingServiceImpl struct {
    base.SessionResource
    // 依赖注入 · dependency injection
}

func NewBookingService(ctx context.Context) BookingService {
    return &BookingServiceImpl{}
}
```

**触发时机 · When to apply**：任何新增 Service 方法的 task。
Any task that adds a new Service method.

---

## P8: 事务内 DB 传递 · DB Handle in Transactions

**规则 · Rule**：事务内传 `*sqlx.Tx` 或 `db.Execer` 接口，不共享全局 DB 句柄。
Inside a transaction, pass `*sqlx.Tx` or the `db.Execer` interface — never share the global DB handle.

```go
// 正确：通过参数传递 tx · Correct: pass tx via parameter
func (s *BookingServiceImpl) createWithTx(ctx context.Context, execer db.Execer, ...) error {
    // execer 可以是 *sqlx.DB 或 *sqlx.Tx，统一接口
    // execer can be *sqlx.DB or *sqlx.Tx — uniform interface
}
```

**触发时机 · When to apply**：任何涉及多表写入、需要事务保证原子性的 task。
Any task involving multi-table writes that require transactional atomicity.

---

## 快速 checklist（Phase 4 每个 task 过一遍）· Quick Checklist (run through for every task in Phase 4)

```
□ 创建新业务实体？  → P1 idgen.NextID()
  Creating new business entity?

□ 写 DB？          → P2 读写分离 read/write split + P3 双删 Redis double-delete（如有缓存 if cached）
  Writing to DB?

□ 新增 MQ topic？   → P4 BrokerTopics + KafkaTopics 同步 sync both slices
  Adding new MQ topic?

□ 改 proto？        → P5 只新增 field，不改 field number · only add fields, never change field numbers
  Modifying proto?

□ 写业务日志？      → P6 带 requestID · include requestID
  Writing business logs?

□ 新增 Service？    → P7 接口 + impl 模式 · interface + impl pattern
  Adding new Service?

□ 跨表事务？        → P8 传 db.Execer 接口 · pass db.Execer interface
  Cross-table transaction?
```
