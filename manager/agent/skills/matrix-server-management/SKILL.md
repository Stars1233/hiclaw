---
name: matrix-server-management
description: Manage the Tuwunel Matrix Homeserver (register users, create rooms, manage room membership). Use only for explicit standalone admin requests — Worker and project creation handle Matrix operations internally via their own scripts.
---

# Matrix Server Management

## Overview

This skill allows you to manage the Tuwunel Matrix Homeserver. Tuwunel is a conduwuit fork running at `http://127.0.0.1:6167`. Access the server directly (not through the Higress gateway).

## Environment Variables

These environment variables are pre-configured in the Manager container:

```bash
# Core configuration (set by hiclaw-install.sh)
HICLAW_MATRIX_DOMAIN       # Matrix server domain (e.g., matrix-local.hiclaw.io:8080)
HICLAW_ADMIN_USER          # Admin username
HICLAW_REGISTRATION_TOKEN  # Token for registering new Matrix users
HICLAW_MANAGER_PASSWORD    # Manager's Matrix password (for login)
```

No need to set defaults - these are always available in the container environment.

## User Registration

Tuwunel uses **single-step registration** with a registration token (no UIAA flow).

### Register a New User

```bash
curl -X POST http://127.0.0.1:6167/_matrix/client/v3/register \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "<USERNAME>",
    "password": "<PASSWORD>",
    "auth": {
      "type": "m.login.registration_token",
      "token": "'"${HICLAW_REGISTRATION_TOKEN}"'"
    }
  }'
```

Response includes `user_id` and `access_token`.

### Login (Get Access Token)

```bash
curl -X POST http://127.0.0.1:6167/_matrix/client/v3/login \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "m.login.password",
    "identifier": {"type": "m.id.user", "user": "<USERNAME>"},
    "password": "<PASSWORD>"
  }'
```

Response: `{"access_token": "...", "user_id": "@<USERNAME>:<DOMAIN>", ...}`

## Room Management

### Create a Room (3-party: Human + Manager + Worker)

When creating a Worker, always create a Room with the human admin, Manager, and Worker:

```bash
MANAGER_TOKEN="<manager_access_token>"
curl -X POST http://127.0.0.1:6167/_matrix/client/v3/createRoom \
  -H "Authorization: Bearer ${MANAGER_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Worker: <WORKER_NAME>",
    "topic": "Communication channel for <WORKER_NAME>",
    "invite": [
      "@'"${HICLAW_ADMIN_USER}"':'"${HICLAW_MATRIX_DOMAIN}"'",
      "@<WORKER_NAME>:'"${HICLAW_MATRIX_DOMAIN}"'"
    ],
    "preset": "trusted_private_chat"
  }'
```

Response: `{"room_id": "!<id>:<DOMAIN>"}`

### Send a Message in a Room

**Simple message (no mention):**
```bash
curl -X PUT "http://127.0.0.1:6167/_matrix/client/v3/rooms/<ROOM_ID>/send/m.room.message/$(date +%s)" \
  -H "Authorization: Bearer ${MANAGER_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "msgtype": "m.text",
    "body": "Hello, this is a general announcement..."
  }'
```

### Send a Message with @Mention (Critical for Workers)

**IMPORTANT**: When sending messages to Workers in group rooms, you MUST include the `m.mentions` field for them to receive the message. Workers have `requireMention: true` enabled, meaning they only process messages that properly @mention them.

```bash
# Mention a single user
curl -X PUT "http://127.0.0.1:6167/_matrix/client/v3/rooms/<ROOM_ID>/send/m.room.message/$(date +%s)" \
  -H "Authorization: Bearer ${MANAGER_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "msgtype": "m.text",
    "body": "@<WORKER_NAME>:'"${HICLAW_MATRIX_DOMAIN}"' Your task assignment: ...",
    "m.mentions": {
      "user_ids": ["@<WORKER_NAME>:'"${HICLAW_MATRIX_DOMAIN}"'"]
    }
  }'
```

```bash
# Mention multiple users
curl -X PUT "http://127.0.0.1:6167/_matrix/client/v3/rooms/<ROOM_ID>/send/m.room.message/$(date +%s)" \
  -H "Authorization: Bearer ${MANAGER_TOKEN}" \
  -H 'Content-Type: application/json' \
  -d '{
    "msgtype": "m.text",
    "body": "@alice:'"${HICLAW_MATRIX_DOMAIN}"' and @bob:'"${HICLAW_MATRIX_DOMAIN}"' please coordinate on this task...",
    "m.mentions": {
      "user_ids": [
        "@alice:'"${HICLAW_MATRIX_DOMAIN}"'",
        "@bob:'"${HICLAW_MATRIX_DOMAIN}"'"
      ]
    }
  }'
```

**Rules for @mentions:**
- The `user_ids` array in `m.mentions` MUST contain the full Matrix user ID (e.g., `@alice:matrix-local.hiclaw.io:8080`)
- The user ID in the body text and in `m.mentions.user_ids` must match exactly
- Without `m.mentions`, Workers will receive the message but will NOT process it (it will be ignored)
- This follows Matrix MSC3952 (Intentional Mentions) specification

### List Joined Rooms

```bash
curl -s http://127.0.0.1:6167/_matrix/client/v3/joined_rooms \
  -H "Authorization: Bearer ${MANAGER_TOKEN}" | jq
```

### Get Room Messages

```bash
curl -s "http://127.0.0.1:6167/_matrix/client/v3/rooms/<ROOM_ID>/messages?dir=b&limit=20" \
  -H "Authorization: Bearer ${MANAGER_TOKEN}" | jq
```

## Important Notes

- **Environment prefix**: Tuwunel uses `CONDUWUIT_` environment variable prefix (NOT `TUWUNEL_`)
- **Server name**: Set in `CONDUWUIT_SERVER_NAME`, usually `${HICLAW_MATRIX_DOMAIN}`
- **User ID format**: `@<username>:${HICLAW_MATRIX_DOMAIN}`
- **Registration token**: Stored in `HICLAW_REGISTRATION_TOKEN` env var
- **Direct access**: Use `http://127.0.0.1:6167` for server management (not through Higress Gateway port 8080)

