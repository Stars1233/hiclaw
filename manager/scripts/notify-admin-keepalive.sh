#!/bin/bash
# notify-admin-keepalive.sh
# Delivers the daily keepalive notification via the primary channel.
#
# Exit 0: dispatched to non-matrix primary channel (mark-notified already called)
# Exit 1: no non-matrix primary configured, or dispatch failed — use matrix DM fallback

set -euo pipefail

PRIMARY_FILE="${HOME}/manager-workspace/primary-channel.json"
GATEWAY_URL="http://localhost:18799"
GATEWAY_TOKEN="${MANAGER_GATEWAY_KEY:-}"

[ -z "$GATEWAY_TOKEN" ] && exit 1
[ -f "$PRIMARY_FILE" ] || exit 1

CONFIRMED=$(jq -r '.confirmed // false' "$PRIMARY_FILE" 2>/dev/null)
CHANNEL=$(jq -r '.channel // "matrix"' "$PRIMARY_FILE" 2>/dev/null)
TO=$(jq -r '.to // ""' "$PRIMARY_FILE" 2>/dev/null)

[ "$CONFIRMED" = "true" ] || exit 1
[ -z "$CHANNEL" ] && exit 1
[ "$CHANNEL" = "matrix" ] && exit 1
[ -z "$TO" ] && exit 1

# Mark notified immediately to prevent heartbeat from double-notifying
bash /opt/hiclaw/scripts/session-keepalive.sh --action mark-notified

# Trigger hook agent to generate and deliver notification via primary channel
HOOK_MSG="Daily keepalive notification trigger. Please:
1. Run: bash /opt/hiclaw/scripts/session-keepalive.sh --action list-rooms
2. Run: bash /opt/hiclaw/scripts/session-keepalive.sh --action load-prefs
3. Compose the keepalive notification message (see HEARTBEAT.md step 7 for format — include active room list, keepalive rationale, yesterday's prefs, and reply instructions)
4. Your response will be delivered to the admin in this channel — output the notification message directly.
Note: mark-notified has already been called; skip that step."

PAYLOAD=$(jq -n \
  --arg msg "$HOOK_MSG" \
  --arg channel "$CHANNEL" \
  --arg to "$TO" \
  '{message: $msg, name: "Keepalive", channel: $channel, to: $to, deliver: true, wakeMode: "now"}')

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${GATEWAY_URL}/hooks/agent" \
  -H "Authorization: Bearer ${GATEWAY_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" 2>/dev/null)

if [ "$HTTP_CODE" = "202" ]; then
    exit 0
else
    # Hook dispatch failed; matrix DM fallback will handle notification
    exit 1
fi
