# HiClaw

[English](./README.md) | [中文](./README.zh-CN.md)

<p align="center">
  <a href="https://deepwiki.com/higress-group/hiclaw"><img src="https://img.shields.io/badge/DeepWiki-Ask_AI-navy.svg?logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAyCAYAAAAnWDnqAAAAAXNSR0IArs4c6QAAA05JREFUaEPtmUtyEzEQhtWTQyQLHNak2AB7ZnyXZMEjXMGeK/AIi+QuHrMnbChYY7MIh8g01fJoopFb0uhhEqqcbWTp06/uv1saEDv4O3n3dV60RfP947Mm9/SQc0ICFQgzfc4CYZoTPAswgSJCCUJUnAAoRHOAUOcATwbmVLWdGoH//PB8mnKqScAhsD0kYP3j/Yt5LPQe2KvcXmGvRHcDnpxfL2zOYJ1mFwrryWTz0advv1Ut4CJgf5uhDuDj5eUcAUoahrdY/56ebRWeraTjMt/00Sh3UDtjgHtQNHwcRGOC98BJEAEymycmYcWwOprTgcB6VZ5JK5TAJ+fXGLBm3FDAmn6oPPjR4rKCAoJCal2eAiQp2x0vxTPB3ALO2CRkwmDy5WohzBDwSEFKRwPbknEggCPB/imwrycgxX2NzoMCHhPkDwqYMr9tRcP5qNrMZHkVnOjRMWwLCcr8ohBVb1OMjxLwGCvjTikrsBOiA6fNyCrm8V1rP93iVPpwaE+gO0SsWmPiXB+jikdf6SizrT5qKasx5j8ABbHpFTx+vFXp9EnYQmLx02h1QTTrl6eDqxLnGjporxl3NL3agEvXdT0WmEost648sQOYAeJS9Q7bfUVoMGnjo4AZdUMQku50McDcMWcBPvr0SzbTAFDfvJqwLzgxwATnCgnp4wDl6Aa+Ax283gghmj+vj7feE2KBBRMW3FzOpLOADl0Isb5587h/U4gGvkt5v60Z1VLG8BhYjbzRwyQZemwAd6cCR5/XFWLYZRIMpX39AR0tjaGGiGzLVyhse5C9RKC6ai42ppWPKiBagOvaYk8lO7DajerabOZP46Lby5wKjw1HCRx7p9sVMOWGzb/vA1hwiWc6jm3MvQDTogQkiqIhJV0nBQBTU+3okKCFDy9WwferkHjtxib7t3xIUQtHxnIwtx4mpg26/HfwVNVDb4oI9RHmx5WGelRVlrtiw43zboCLaxv46AZeB3IlTkwouebTr1y2NjSpHz68WNFjHvupy3q8TFn3Hos2IAk4Ju5dCo8B3wP7VPr/FGaKiG+T+v+TQqIrOqMTL1VdWV1DdmcbO8KXBz6esmYWYKPwDL5b5FA1a0hwapHiom0r/cKaoqr+27/XcrS5UwSMbQAAAABJRU5ErkJggg==" alt="DeepWiki"></a>
  <a href="https://discord.gg/n6mV8xEYUF"><img src="https://img.shields.io/badge/Discord-Join_Us-blueviolet.svg?logo=discord" alt="Discord"></a>
  <a href="https://qr.dingtalk.com/action/joingroup?code=v1,k1,0etR5l8fxeb/6/mzE5hRE1uy4tkiwxvPV9+TdBv7sEM=&_dt_no_comment=1&origin=11"><img src="https://img.shields.io/badge/DingTalk-Join_Us-orange.svg" alt="DingTalk"></a>
</p>

**5 分钟部署一支 AI Agent 团队。Manager 协调 Worker，全程在 IM 里可见。**

HiClaw 是基于 [OpenClaw](https://github.com/nicepkg/openclaw) 的开源 Agent 团队系统。Manager Agent 是你的 AI 管家——它负责创建 Worker、分配任务、监控进度、汇报结果。你只需做决策，不用当 AI 的保姆。

```
你 → Manager → Worker Alice（前端）
            → Worker Bob（后端）
            → Worker ...
```

所有通信都发生在 Matrix 群聊房间里。你看得到一切，随时可以介入——就像在微信群里和一支团队协作。

## 为什么选 HiClaw

**安全设计**：Worker 永远不持有真实的 API Key 或 GitHub PAT，只有一个消费者令牌（类似"工牌"）。即使 Worker 被攻击，攻击者也拿不到任何真实凭证。

**真正开箱即用的 IM**：内置 Matrix 服务器，不需要申请飞书/钉钉机器人，不需要等待审批。浏览器打开 Element Web 就能对话，或者用手机上的 Matrix 客户端（Element、FluffyChat）随时指挥——iOS、Android、Web 全平台支持。

**一条命令启动**：一个 `curl | bash` 搞定所有组件——Higress AI 网关、Matrix 服务器、文件存储、Web 客户端和 Manager Agent 本身。

**技能生态**：Worker 可以按需从 [skills.sh](https://skills.sh) 获取技能（社区已有 80,000+ 个）。因为 Worker 本身就拿不到真实凭证，所以可以放心使用公开技能库。

## 快速开始

```bash
bash <(curl -sSL https://higress.ai/hiclaw/install.sh)
```

就这一条。脚本会询问你的 LLM API Key，然后自动完成所有配置。安装完成后：

```
=== HiClaw Manager Started! ===
  打开：http://127.0.0.1:18088
  登录：admin / [自动生成的密码]
  告诉 Manager："帮我创建一个名为 alice 的前端 Worker"
```

**Windows（PowerShell 7+）：**

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://higress.ai/hiclaw/install.ps1'))
```

**前置条件**：Docker Desktop（Windows/macOS）或 Docker Engine（Linux）。仅此而已。

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)（Windows / macOS）
- [Docker Engine](https://docs.docker.com/engine/install/)（Linux）或 [Podman Desktop](https://podman-desktop.io/)（替代方案）

**资源需求**：Docker 虚拟机至少需要分配 2 核 CPU 和 4 GB 内存。Docker Desktop 用户可在 Settings → Resources 中调整。

### 非交互式安装

```bash
HICLAW_LLM_API_KEY="sk-xxx" HICLAW_NON_INTERACTIVE=1 bash <(curl -sSL https://higress.ai/hiclaw/install.sh)
```

### 安装完成后

1. 浏览器打开 `http://127.0.0.1:18088`
2. 用安装时显示的账号密码登录
3. 告诉 Manager 创建 Worker 并分配任务

手机端：下载 Element 或 FluffyChat，连接你的 Matrix 服务器地址，随时随地管理你的 Agent 团队。

## 工作方式

### Manager 是你的 AI 管家

Manager 通过自然语言完成 Worker 的全生命周期管理：

```
你：帮我创建一个名为 alice 的前端 Worker

Manager：好的，Worker alice 已创建。
         房间：Worker: Alice
         可以直接在房间里给 alice 分配任务了。

你：@alice 帮我用 React 实现一个登录页面

Alice：收到，正在处理……[几分钟后]
       完成了！PR 已提交：https://github.com/xxx/pull/1
```

<p align="center">
  <img src="https://img.alicdn.com/imgextra/i3/O1CN01Kvz9CF1l8XwU7izC9_!!6000000004774-0-tps-589-1280.jpg" width="280" alt="Manager 创建 Worker" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://img.alicdn.com/imgextra/i2/O1CN01lifZMs1h7qscHxCsH_!!6000000004231-0-tps-589-1280.jpg" width="280" alt="人类直接指挥 Worker" />
</p>

Manager 还会定期发送心跳检查——如果某个 Worker 卡住了，它会自动提醒你。

### 安全模型

```
Worker（只持有消费者令牌）
    → Higress AI 网关（持有真实 API Key、GitHub PAT）
        → LLM API / GitHub API / MCP Server
```

Worker 只能看到自己的消费者令牌。网关统一管理所有真实凭证。Manager 知道 Worker 在做什么，但同样接触不到真实的 Key。

### 人工全程监督

每个 Matrix 房间里都有你、Manager 和相关 Worker。你可以随时跳进来：

```
你：@bob 等一下，密码规则改成至少 8 位
Bob：好的，已修改。
Alice：前端校验也更新了。
```

没有黑盒，没有隐藏的 Agent 间调用。

## HiClaw vs OpenClaw 原生

| | OpenClaw 原生 | HiClaw |
|---|---|---|
| 部署方式 | 单进程 | 分布式容器 |
| Agent 创建 | 手动配置 + 重启 | 对话式 |
| 凭证管理 | 每个 Agent 持有真实 Key | Worker 只持有消费者令牌 |
| 人工可见性 | 可选 | 内置（Matrix 房间） |
| 移动端访问 | 取决于渠道配置 | 任意 Matrix 客户端，零配置 |
| 监控 | 无 | Manager 心跳，房间内可见 |

## 架构

```
┌─────────────────────────────────────────────┐
│         hiclaw-manager-agent                │
│  Higress │ Tuwunel │ MinIO │ Element Web    │
│  Manager Agent (OpenClaw)                   │
└──────────────────┬──────────────────────────┘
                   │ Matrix + HTTP Files
┌──────────────────┴──────┐  ┌────────────────┐
│  hiclaw-worker-agent    │  │  hiclaw-worker │
│  Worker Alice (OpenClaw)│  │  Worker Bob    │
└─────────────────────────┘  └────────────────┘
```

| 组件 | 职责 |
|------|------|
| Higress AI 网关 | LLM 代理、MCP Server 托管、凭证集中管理 |
| Tuwunel（Matrix） | 所有 Agent 与人类通信的 IM 服务器 |
| Element Web | 浏览器客户端，零配置 |
| MinIO | 集中式文件存储，Worker 无状态 |
| OpenClaw | 带 Matrix 插件和技能系统的 Agent 运行时 |

## 文档

| | |
|---|---|
| [docs/quickstart.md](docs/quickstart.md) | 端到端快速入门，含验证检查点 |
| [docs/architecture.md](docs/architecture.md) | 系统架构详解 |
| [docs/manager-guide.md](docs/manager-guide.md) | Manager 配置与使用 |
| [docs/worker-guide.md](docs/worker-guide.md) | Worker 部署与故障排查 |
| [docs/development.md](docs/development.md) | 贡献指南与本地开发 |

## 构建与测试

```bash
make build               # 构建所有镜像
make test                # 构建 + 运行全部集成测试
make test SKIP_BUILD=1   # 不重新构建，直接运行测试
make test-quick          # 快速冒烟测试（仅 test-01）
```

## 其他命令

```bash
# 通过 CLI 向 Manager 发送任务
make replay TASK="创建一个名为 alice 的前端开发 Worker"

# 卸载所有内容
make uninstall

# 推送多架构镜像
make push VERSION=0.1.0 REGISTRY=ghcr.io REPO=higress-group/hiclaw

make help  # 查看所有可用目标
```

## 许可证

Apache License 2.0
