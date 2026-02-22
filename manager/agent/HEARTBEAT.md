## Manager Heartbeat Checklist

### 1. 读取 state.json

从本地读取 state.json（如未同步，先 mc cp 拉取）：

```bash
mc cp hiclaw/hiclaw-storage/agents/manager/state.json ~/hiclaw-fs/agents/manager/state.json 2>/dev/null || true
cat ~/hiclaw-fs/agents/manager/state.json
```

state.json 的 `active_tasks` 包含所有进行中的任务（有限任务和无限任务）。无需遍历所有 meta.json。

---

### 2. 有限任务状态询问

遍历 `active_tasks` 中 `"type": "finite"` 的条目：

- 从条目的 `assigned_to` 和 `room_id` 字段获取负责的 Worker 及对应 Room
- 在该 Worker 的 Room（或 project_room_id 若有）中 @mention Worker 询问进展：
  ```
  @{worker}:{domain} 你当前的任务 {task-id} 进展如何？有没有遇到阻塞？
  ```
- 根据 Worker 回复判断是否正常推进
- 如果 Worker 未回复（超过一个 heartbeat 周期无响应），在 Room 中标记异常并提醒人类管理员
- 如果 Worker 已回复完成但 meta.json 未更新，主动更新 meta.json（status → completed，填写 completed_at），并从 state.json 的 `active_tasks` 中删除该条目

---

### 3. 无限任务超时检查

遍历 `active_tasks` 中 `"type": "infinite"` 的条目，对每个条目：

```
当前时间 UTC = now

判断条件（同时满足）：
  1. last_executed_at < next_scheduled_at（本轮尚未执行）
     或 last_executed_at 为 null（从未执行）
  2. now > next_scheduled_at + 30分钟（已超时未执行）

若满足，在对应 room_id 中 @mention Worker 触发执行：
  @{worker}:{domain} 该执行你的定时任务 {task-id}「{task-title}」了，请现在执行并用 "executed" 关键字汇报。
```

**注意**：无限任务永不从 active_tasks 中删除。Worker 汇报 `executed` 后，Manager 更新 `last_executed_at` 和 `next_scheduled_at`，然后 mc cp 同步 state.json。

---

### 4. 项目进展监控

扫描 ~/hiclaw-fs/shared/projects/ 下所有活跃项目的 plan.md：

```bash
for meta in ~/hiclaw-fs/shared/projects/*/meta.json; do
  cat "$meta"
done
```

- 筛选 `"status": "active"` 的项目
- 对每个活跃项目，读取 plan.md，找出标记为 `[~]`（进行中）的任务
- 若该 Worker 在本 heartbeat 周期内没有活动，在项目群中 @mention：
  ```
  @{worker}:{domain} 你正在执行的任务 {task-id}「{title}」有进展吗？有遇到阻塞请告知。
  ```
- 如果项目群中有 Worker 汇报了任务完成但 plan.md 还没更新，立即处理（见 AGENTS.md 项目管理部分）

---

### 5. 容量评估

- 统计 state.json 中 type=finite 的条目数（有限任务进行中数量）和没有分配任务的空闲 Worker
- 如果 Worker 不足，循环人类管理员是否需要创建新的 Worker
- 如果有 Worker 空闲，建议重新分配任务

---

### 6. Worker 容器生命周期管理

仅当容器 API 可用时执行（先检查）：

```bash
bash -c 'source /opt/hiclaw/scripts/lib/container-api.sh && container_api_available && echo available'
```

若输出 `available`，继续执行以下步骤：

1. 同步状态：
   ```bash
   bash /opt/hiclaw/agent/skills/worker-management/scripts/lifecycle-worker.sh --action sync-status
   ```

2. 检测空闲：对每个 Worker，若 state.json 中无其 finite task 且 container_status=running：
   - 若 idle_since 未设置，设为当前时间
   - 若 (now - idle_since) > idle_timeout_minutes，执行自动停止：
     ```bash
     bash /opt/hiclaw/agent/skills/worker-management/scripts/lifecycle-worker.sh --action check-idle
     ```
   - 在 Manager 与该 Worker 的 Room 中记录：
     「Worker <name> 容器已因空闲超时自动暂停。有任务时将自动唤醒。」

3. 若有正在运行 finite task 的 Worker 但其容器状态为 stopped（异常情况），执行启动并告警：
   ```bash
   bash /opt/hiclaw/agent/skills/worker-management/scripts/lifecycle-worker.sh --action start --worker <name>
   ```

---

### 7. 每日保活提醒（仅在 10:00–10:59 执行一次）

执行条件：`date +%H` 输出 `10`，且 `load-prefs` 的 `PREFS_DATE` 不是今天。

```bash
HOUR=$(date +%H)
if [ "$HOUR" = "10" ]; then
    PREFS_DATE=$(bash /opt/hiclaw/scripts/session-keepalive.sh --action load-prefs | grep '^PREFS_DATE:' | cut -d' ' -f2)
    TODAY=$(date '+%Y-%m-%d')
    if [ "$PREFS_DATE" != "$TODAY" ]; then
        # 执行每日保活提醒流程（见下）
    fi
fi
```

满足条件时，流程如下：

1. 获取当前活跃房间列表：
   ```bash
   bash /opt/hiclaw/scripts/session-keepalive.sh --action list-rooms
   ```
   输出格式：`ROOM: room_id\ttype\tname`

2. 获取昨日偏好：
   ```bash
   bash /opt/hiclaw/scripts/session-keepalive.sh --action load-prefs
   ```
   输出：`PREFS_DATE:`、`PREFS_APPLIED:`、`PREFS_ROOM:` 行

3. 尝试通过主用频道发送通知：

   ```bash
   NOTIFY_RESULT=$(bash /opt/hiclaw/scripts/notify-admin-keepalive.sh 2>&1)
   NOTIFY_EXIT=$?
   ```

   - 若 `NOTIFY_EXIT` 为 **0**：通知已通过主用频道分发，mark-notified 已调用，**跳过步骤 4 和 5**，直接结束此步骤
   - 若 `NOTIFY_EXIT` 为 **1**（无非 Matrix 主用频道或分发失败）：继续执行步骤 4 和 5（Matrix DM 回退）

4. （仅在步骤 3 返回 1 时执行）在与 **Human Admin 的 DM** 中发送保活提醒消息，内容须包含：
   - 当前活跃的 Worker 房间和项目房间列表（group 类型，空闲超 2 天后重置）
   - 说明为何需要保活：若不保活，Worker 在对应房间的对话历史将在 2 天内清空，导致后续对话丢失上下文；如有未完成任务，建议保活
   - 说明不保活的好处：减少 token 开销（历史消息越长，每次 LLM 调用消耗越多）
   - 列出昨日保活选择（若有 `PREFS_ROOM:` 行），询问是否继续或调整
   - 提示：回复「继续」直接复用昨日选择，提供新列表则更新，回复「不需要」跳过今日保活

5. （仅在步骤 3 返回 1 时执行）运行 mark-notified：
   ```bash
   bash /opt/hiclaw/scripts/session-keepalive.sh --action mark-notified
   ```

---

### 8. 回复

- 如果所有 Worker 正常且无待处理事项：HEARTBEAT_OK
- 否则：汇总发现和建议的操作，通知人类管理员
