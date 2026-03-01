## Manager Heartbeat Checklist

### 1. Read state.json

Read state.json locally (sync first with mc cp if not already):

```bash
mc cp hiclaw/hiclaw-storage/agents/manager/state.json ~/hiclaw-fs/agents/manager/state.json 2>/dev/null || true
cat ~/hiclaw-fs/agents/manager/state.json
```

The `active_tasks` field in state.json contains all in-progress tasks (both finite and infinite). No need to iterate over all meta.json files.

---

### 2. Check Status of Finite Tasks

Iterate over entries in `active_tasks` with `"type": "finite"`:

- Get the responsible Worker and corresponding Room from the entry's `assigned_to` and `room_id` fields
- @mention the Worker in their Room (or `project_room_id` if available) to ask for progress:
  ```
  @{worker}:{domain} How is your current task {task-id} going? Are you blocked on anything?
  ```
- Determine if the Worker is making normal progress based on their reply
- If the Worker has not responded (no response for more than one heartbeat cycle), flag the anomaly in the Room and notify the human admin
- If the Worker has replied that the task is complete but meta.json has not been updated, proactively update meta.json (status → completed, fill in completed_at), and remove the entry from `active_tasks` in state.json

---

### 3. Check Infinite Task Timeouts

Iterate over entries in `active_tasks` with `"type": "infinite"`. For each entry:

```
Current UTC time = now

Conditions (both must be met):
  1. last_executed_at < next_scheduled_at (not yet executed this cycle)
     OR last_executed_at is null (never executed)
  2. now > next_scheduled_at + 30 minutes (overdue)

If conditions are met, @mention the Worker in the corresponding room_id to trigger execution:
  @{worker}:{domain} It's time to run your scheduled task {task-id} "{task-title}". Please execute it now and report back with the keyword "executed".
```

**Note**: Infinite tasks are never removed from active_tasks. After the Worker reports `executed`, the Manager updates `last_executed_at` and `next_scheduled_at`, then syncs state.json via mc cp.

---

### 4. Project Progress Monitoring

Scan plan.md for all active projects under ~/hiclaw-fs/shared/projects/:

```bash
for meta in ~/hiclaw-fs/shared/projects/*/meta.json; do
  cat "$meta"
done
```

- Filter projects with `"status": "active"`
- For each active project, read plan.md and find tasks marked as `[~]` (in progress)
- If the responsible Worker has had no activity during this heartbeat cycle, @mention them in the project room:
  ```
  @{worker}:{domain} Any progress on your current task {task-id} "{title}"? Please let us know if you're blocked.
  ```
- If a Worker has reported task completion in the project room but plan.md has not been updated yet, handle it immediately (see the project management section in AGENTS.md)

---

### 5. Capacity Assessment

- Count the number of `type=finite` entries in state.json (finite tasks in progress) and identify idle Workers with no assigned tasks
- If Workers are insufficient, check in with the human admin about whether new Workers need to be created
- If Workers are idle, suggest reassigning tasks

---

### 6. Worker Container Lifecycle Management

Only execute when the container API is available (check first):

```bash
bash -c 'source /opt/hiclaw/scripts/lib/container-api.sh && container_api_available && echo available'
```

If the output is `available`, proceed with the following steps:

1. Sync status:
   ```bash
   bash /opt/hiclaw/agent/skills/worker-management/scripts/lifecycle-worker.sh --action sync-status
   ```

2. Detect idle Workers: For each Worker, if there are no finite tasks for them in state.json and container_status=running:
   - If idle_since is not set, set it to the current time
   - If (now - idle_since) > idle_timeout_minutes, perform auto-stop:
     ```bash
     bash /opt/hiclaw/agent/skills/worker-management/scripts/lifecycle-worker.sh --action check-idle
     ```
   - Log in the Manager's Room with that Worker:
     "Worker <name> container has been automatically paused due to idle timeout. It will be automatically resumed when a task is assigned."

3. If a Worker has a running finite task but its container status is stopped (anomaly), start it and send an alert:
   ```bash
   bash /opt/hiclaw/agent/skills/worker-management/scripts/lifecycle-worker.sh --action start --worker <name>
   ```

---

### 7. Daily Keepalive Reminder (Execute Once Between 10:00–10:59 Only)

Execution condition: `date +%H` outputs `10`, and `load-prefs` shows `PREFS_DATE` is not today.

```bash
HOUR=$(date +%H)
if [ "$HOUR" = "10" ]; then
    PREFS_DATE=$(bash /opt/hiclaw/scripts/session-keepalive.sh --action load-prefs | grep '^PREFS_DATE:' | cut -d' ' -f2)
    TODAY=$(date '+%Y-%m-%d')
    if [ "$PREFS_DATE" != "$TODAY" ]; then
        # Execute daily keepalive reminder flow (see below)
    fi
fi
```

When conditions are met, proceed as follows:

1. Get the current list of active rooms:
   ```bash
   bash /opt/hiclaw/scripts/session-keepalive.sh --action list-rooms
   ```
   Output format: `ROOM: room_id\ttype\tname`

2. Get yesterday's preferences:
   ```bash
   bash /opt/hiclaw/scripts/session-keepalive.sh --action load-prefs
   ```
   Output: `PREFS_DATE:`, `PREFS_APPLIED:`, `PREFS_ROOM:` lines

3. Attempt to send notification via the primary channel:

   ```bash
   NOTIFY_RESULT=$(bash /opt/hiclaw/scripts/notify-admin-keepalive.sh 2>&1)
   NOTIFY_EXIT=$?
   ```

   - If `NOTIFY_EXIT` is **0**: Notification has been distributed via the primary channel, mark-notified has been called. **Skip steps 4 and 5** and end this step.
   - If `NOTIFY_EXIT` is **1** (no non-Matrix primary channel or distribution failed): Continue with steps 4 and 5 (Matrix DM fallback).

4. (Only if step 3 returned 1) Send a keepalive reminder message in the **DM with Human Admin**, including:
   - The current list of active Worker rooms and project rooms (group type, reset after 2 days of inactivity)
   - Explanation of why keepalive is needed: without it, the Worker's conversation history in the corresponding room will be cleared within 2 days, causing loss of context in future conversations; keepalive is recommended if there are unfinished tasks
   - Explanation of the benefit of skipping keepalive: reduced token cost (longer history means more tokens consumed per LLM call)
   - List yesterday's keepalive choices (if `PREFS_ROOM:` lines exist) and ask whether to continue or adjust
   - Hint: reply "continue" to reuse yesterday's choices, provide a new list to update, or reply "skip" to skip today's keepalive

5. (Only if step 3 returned 1) Run mark-notified:
   ```bash
   bash /opt/hiclaw/scripts/session-keepalive.sh --action mark-notified
   ```

---

### 8. Reply

- If all Workers are healthy and there are no pending items: HEARTBEAT_OK
- Otherwise: Summarize findings and recommended actions, and notify the human admin
