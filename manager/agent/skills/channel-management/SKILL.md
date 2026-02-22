---
name: channel-management
description: Manage multiple communication channels, admin identity recognition, and primary channel configuration
assign_when: Not assigned to workers — this is a manager-only capability
---

# Channel Management Skill

## Identity Recognition

See SOUL.md "多渠道身份识别与权限" for the priority rules. In brief:

1. **Human Admin**: any DM on any channel, OR group room message where sender_id matches `primary-channel.json`.`sender_id` (same channel type)
2. **Trusted Contact**: `{channel, sender_id}` found in `trusted-contacts.json` — respond, but withhold all sensitive info and deny all management operations
3. **Unknown**: silently ignore

## Trusted Contacts

File: `~/manager-workspace/trusted-contacts.json`

```json
{
  "contacts": [
    {
      "channel": "discord",
      "sender_id": "987654321098765432",
      "approved_at": "2026-02-23T10:00:00Z",
      "note": "optional label"
    }
  ]
}
```

### Adding a Trusted Contact

Trigger: unknown sender messages in a group room → silently ignore. If the human admin then says "you can talk to the person who just messaged" (or equivalent):

1. Identify the most recent unknown sender's `channel` and `sender_id` from the current session context
2. Append to `trusted-contacts.json`:
   ```bash
   # Read existing, append, write back (use jq)
   jq --arg ch "<channel>" --arg sid "<sender_id>" --arg ts "<ISO-8601 now>" \
     '.contacts += [{"channel": $ch, "sender_id": $sid, "approved_at": $ts, "note": ""}]' \
     ~/manager-workspace/trusted-contacts.json > /tmp/tc.json && \
     mv /tmp/tc.json ~/manager-workspace/trusted-contacts.json
   ```
   If file doesn't exist yet: `echo '{"contacts":[]}' > ~/manager-workspace/trusted-contacts.json` first.
3. Confirm to admin in their language, e.g.: "OK, I'll engage with them. Note: I won't share any sensitive information with them."

### Communicating with Trusted Contacts

When a trusted contact sends a message:
- Respond normally to general questions
- **Never share**: API keys, tokens, passwords, Worker credentials, internal system configuration, or any other sensitive operational data
- **Never execute**: management operations (create/delete workers, change config, assign tasks, etc.)
- If they ask for something outside their role, decline politely and suggest they contact the admin directly

### Removing a Trusted Contact

When admin revokes access ("don't talk to X anymore"):
```bash
jq --arg ch "<channel>" --arg sid "<sender_id>" \
  '.contacts |= map(select(.channel != $ch or .sender_id != $sid))' \
  ~/manager-workspace/trusted-contacts.json > /tmp/tc.json && \
  mv /tmp/tc.json ~/manager-workspace/trusted-contacts.json
```

## Primary Channel State

File: `~/manager-workspace/primary-channel.json`

```json
{
  "confirmed": true,
  "channel": "discord",
  "to": "user:123456789012345678",
  "sender_id": "123456789012345678",
  "channel_name": "Discord",
  "confirmed_at": "2026-02-22T10:00:00Z"
}
```

Fields:
- `confirmed`: `true` = use this channel for proactive notifications; `false` = Matrix DM fallback
- `channel`: channel identifier string passed to openclaw hook `channel` field (e.g. `"discord"`, `"telegram"`, `"slack"`)
- `to`: recipient identifier passed directly to openclaw hook `to` field. Format varies by channel:
  - Discord DM: `user:USER_ID` (e.g. `user:123456789012345678`)
  - Feishu DM: open_id，即 `ou_` 开头的字符串（e.g. `ou_abc123def456`）；群聊则用 `chat_id`（`oc_` 开头）
  - Telegram: chat ID (e.g. `123456789`)
  - WhatsApp/Signal: phone number (e.g. `+15551234567`)
- `sender_id`: the admin's raw ID on that channel (used for identity tracking)
- `channel_name`: human-readable name for display (e.g. `"Discord"`, `"飞书"`)
- `confirmed_at`: ISO-8601 timestamp when the admin confirmed this choice

Read with fallback:
```bash
cat ~/manager-workspace/primary-channel.json 2>/dev/null || echo '{"confirmed":false}'
```

## First-Contact Protocol

Trigger: admin sends a DM from a channel that doesn't match `primary-channel.json`'s `.channel`.

Steps:
1. Read `primary-channel.json` — check if `.channel` matches the current session's channel
2. Respond to the admin's message normally
3. Send a follow-up asking about primary channel preference, **in the same language the admin used in their message**:
   > I noticed this is your first time contacting me via [Channel Name]. Would you like to set [Channel Name] as your primary channel? If so, my daily reminders and proactive notifications will be sent here instead of Matrix DM. Reply "yes" to confirm, or "no" to keep using Matrix DM.
4. On **"yes" / "confirm" / 「是」/ 「确认」** (or equivalent in their language):
   ```bash
   cat > ~/manager-workspace/primary-channel.json << 'EOF'
   {
     "confirmed": true,
     "channel": "<channel>",
     "to": "<to>",
     "sender_id": "<sender_id>",
     "channel_name": "<Channel Name>",
     "confirmed_at": "<ISO-8601 now>"
   }
   EOF
   ```
5. On **「否」/ "no"**: write `{"confirmed": false}` or leave unchanged; Matrix DM remains primary
6. On no reply (session ends): leave unchanged; Matrix DM remains primary

## Changing Primary Channel

When admin requests a switch (e.g. "switch to Discord as primary", "切换到飞书作为主频道", etc.), in any language:

1. Read current `primary-channel.json`
2. Update: `channel`, `to`, `sender_id`, `channel_name`, `confirmed: true`, `confirmed_at` = now
3. Write updated file
4. Confirm in the admin's language, e.g.: "Primary channel switched to [Channel Name]. Daily reminders and proactive notifications will now be sent there."

## Proactive Notification Routing

The daily keepalive (HEARTBEAT.md step 7) calls `/opt/hiclaw/scripts/notify-admin-keepalive.sh`:
- Exit 0 → notification dispatched to primary channel + mark-notified already called; skip Matrix DM
- Exit 1 → no non-matrix primary or dispatch failed; use Matrix DM fallback

The script reads `primary-channel.json`, calls `mark-notified`, then triggers an openclaw hook session that generates and delivers the keepalive message to the admin's primary channel.

## Troubleshooting

**通知发送到错误目标**：管理员反映收不到通知。检查 `primary-channel.json` 的 `to` 字段是否正确，向管理员确认其频道 ID 后重新写入。

**Hook dispatch failure**: `notify-admin-keepalive.sh` exits 1 despite confirmed primary channel. Check:
1. Is openclaw running? (`ps aux | grep openclaw`)
2. Is `MANAGER_GATEWAY_KEY` set? (`echo $MANAGER_GATEWAY_KEY`)
3. Is the hooks API enabled in openclaw config? (check `manager-openclaw.json.tmpl` → `hooks.enabled`)
4. Fallback to Matrix DM is automatic; no manual intervention needed for individual failures

**Admin confirmed wrong channel**: Admin wants to revert to Matrix DM. Write `{"confirmed": false}` to `primary-channel.json`.
