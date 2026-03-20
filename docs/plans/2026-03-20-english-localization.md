# English Localization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Translate all ctrlx-app-dev skill documentation from Chinese to English, create a Chinese README-cn.md, and rewrite README.md as the English primary file.

**Architecture:** Replace Chinese text in-place across 7 skill docs + SKILL.md. Create README-cn.md from current README.md. Rewrite README.md in English. Push to GitHub. No file structure changes.

**Tech Stack:** Markdown, git

---

## Task 1: Translate SKILL.md

**Files:**
- Modify: `SKILL.md`

**Step 1: Replace entire file content with English translation**

```markdown
---
name: ctrlx-app-dev
description: Modular ctrlX App development assistant (SDK 2.4.x). Supports project initialization, Data Layer implementation, Snap packaging, build/deploy, and compliance checks. Includes smart phase detection and diagnostic mode.
argument-hint: [init|datalayer|snap|build|compliance|overview|diagnose]
---

# ctrlX App Development Assistant

## On Startup: Auto-Detect Project Phase

**Each time the skill is invoked, scan the current directory, determine the development phase, and provide proactive guidance:**

```
Detection logic (priority order):
1. No snap/ directory              → Phase: Uninitialized → Prompt to run init
2. Has snap/ but missing build-info/ → Phase: Config missing → Warn and provide fix steps
3. Has snap/ but no *.snap files   → Phase: In development  → Ask what user is working on
4. Has *.snap files                → Phase: Ready to deploy → Guide through dev loop
```

Example response (Phase 1):
> "No snap/ directory found. This project has not been initialized yet.
> Run the following command to get started: `/ctrlx-app-dev init my-app --lang python`"

---

## Command Routing

### `/ctrlx-app-dev init [name] --lang [python|cpp|csharp]`
1. Read the directory structure spec from @02-project-scaffold.md
2. Select templates based on language:
   - Python: @templates/snapcraft-python.yaml + @templates/provider-template.py
   - C++: @templates/snapcraft-cpp.yaml + @templates/provider-template-cpp.cpp + @templates/CMakeLists.txt
   - C#: @templates/snapcraft-csharp.yaml + @templates/provider-template-csharp.cs
3. Copy @templates/package-manifest.json to build-info/
4. Guide user through "Post-initialization steps" in @02-project-scaffold.md

### `/ctrlx-app-dev datalayer [add-node|provider|consumer]`
1. Consult @03-datalayer-dev.md (SDK 2.4.x)
2. Select the code section matching the user's language (Python/C++/C#)
3. For Flatbuffers usage, refer to the Schema Design section in chapter 1

### `/ctrlx-app-dev build [--arch amd64|arm64]`
1. Read the "Fast Dev Loop" section in @05-build-deploy.md (preferred)
2. If dev-loop script is not set up, provide the Docker build command

### `/ctrlx-app-dev compliance`
1. Load the Category 1/2/3 checklists from @06-compliance.md
2. Scan current project files and verify each item
3. Output compliance report (pass/fail/missing)

### `/ctrlx-app-dev diagnose`
Trigger diagnostic mode (see below)

---

## Diagnostic Mode

When the user describes a problem (rather than entering a command), **ask 2 diagnostic questions before providing an answer**:

**Question 1: Confirm the symptom**
> "Which situation are you experiencing?
> A. Node is not visible in Data Layer Browser
> B. Node is visible but read returns an error code
> C. Data format error (Flatbuffers deserialization failed)
> D. Build or packaging failure"

**Question 2: Confirm the environment**
> "Which environment are you running in?
> A. COREvirtual (local virtual machine)
> B. Physical ctrlX CORE device
> C. Local development environment (not inside a snap)"

After receiving answers, provide targeted steps for that symptom + environment combination. Reference @03-datalayer-dev.md section 7 or the troubleshooting table in @05-build-deploy.md.

---

## Core Constraints (Enforced)

- **SDK version**: ctrlx-datalayer >= 2.4 (Python) | comm.datalayer >= 2.4 (C++) | Datalayer >= 2.4 (.NET)
- **Naming convention**: `ctrlx-{company}-{app}_{version}_{arch}.snap`
- **Base image**: `core22` or `core24`, strict confinement
- **Communication**: Unix Socket (IPC), not TCP ports
- **Resource limits**: RAM < 75 MB, Snap < 100 MB
- **Required files**: package-manifest.json, manual.md, test-setup.md, release-notes.md
```

**Step 2: Commit**

```bash
git add SKILL.md
git commit -m "i18n: translate SKILL.md to English"
```

---

## Task 2: Translate 01-overview.md

**Files:**
- Modify: `01-overview.md`

**Step 1: Replace entire file with English translation**

```markdown
# ctrlX App Development Overview

> **Current baseline**: ctrlX OS 2.x | ctrlX SDK 2.4.x | snapcraft 8.x | Ubuntu Core 22/24

## What is a ctrlX App?

A ctrlX App is an industrial automation application packaged in Ubuntu Core Snap format, running on the Bosch Rexroth ctrlX CORE control platform.

## Technology Stack

| Language | Use Case | Performance | Dev Speed |
|----------|----------|-------------|-----------|
| **Python** | Data processing, algorithm prototyping | Medium | ⭐⭐⭐⭐⭐ (ctrlx-datalayer>=2.4) |
| **C++** | Real-time control, high performance | High | ⭐⭐⭐ |
| **.NET/C#** | Enterprise integration, HMI | Medium-High | ⭐⭐⭐⭐ |

## Architecture Principles

### 1. Security Model
- **Strict isolation**: Snap's strict confinement restricts filesystem access
- **Least privilege**: Declare only required plugs (network, network-bind, ctrlx-datalayer)
- **Secure communication**: Unix Socket preferred over TCP; all communication encrypted

### 2. Data Flow Architecture

```
[Physical Layer] → [ctrlX CORE Data Layer] → [Your App (Provider/Consumer)]
       ↑                      ↓
[Other Apps] ←────────────────┘
```

### 3. Lifecycle Management
- **Install**: Atomic Snap installation
- **Start**: Managed by systemd, supports automatic restart
- **Upgrade**: Transactional updates with automatic rollback on failure
- **Config**: Via Data Layer or environment variables

## Development Phases

1. **Phase 1: Scaffold** → Project structure, Snap configuration, base code
2. **Phase 2: Develop** → Data Layer nodes, business logic, Flatbuffers schemas
3. **Phase 3: Build** → Compile in Docker or App Build Environment (ABE)
4. **Phase 4: Test** → Local testing with COREvirtual
5. **Phase 5: Compliance** → Documentation, resource checks, security audit
6. **Phase 6: Publish** → Bosch Rexroth signing, store submission

## Key Design Decisions

### Why Unix Socket?
- ✅ Avoids port conflicts (ctrlX system already uses 80/443/4840, etc.)
- ✅ No firewall configuration required
- ✅ Complies with the Snap security model
- ✅ Web services can be exposed through the reverse proxy

### Data Layer vs REST API
- **Data Layer**: Real-time data, state synchronization, machine-to-machine communication (recommended)
- **REST API**: Configuration management, historical queries, third-party integration (optional)

## Resource Limits

| Metric | Limit | How to Check |
|--------|-------|--------------|
| RAM | < 75 MB | `top` or system monitor |
| Storage | < 100 MB | `du -sh $SNAP` |
| CPU | < 5% average | `htop` |
| Startup time | < 10 s | System logs |

## Further Reading

- Snap configuration details: @04-snap-config.md
- Build guide: @05-build-deploy.md
- Compliance checklist: @06-compliance.md
```

**Step 2: Commit**

```bash
git add 01-overview.md
git commit -m "i18n: translate 01-overview.md to English"
```

---

## Task 3: Translate 02-project-scaffold.md

**Files:**
- Modify: `02-project-scaffold.md`

**Step 1: Replace entire file with English translation**

```markdown
# Project Scaffold Guide

## Directory Structure

All projects must strictly follow this structure:

```
{app-name}/
├── snap/
│   └── snapcraft.yaml          # Snap packaging definition (see @04-snap-config.md)
├── src/
│   ├── main.py                 # Application entry point (see templates/)
│   └── helper/                 # Helper modules
├── schema/
│   └── {app}.fbs               # Flatbuffers schema (if using Data Layer)
├── build-info/                 # Build metadata (required)
│   ├── package-manifest.json   # Reverse proxy and license configuration
│   ├── slotplug-description.json
│   ├── portlist-description.json   # Recommended: empty list
│   └── unixsocket-description.json
├── docs/                       # Documentation (required for compliance)
│   ├── manual.md               # User manual
│   ├── test-setup.md           # Test scenarios
│   └── release-notes.md        # Release changelog
└── scripts/
    └── dev-loop.[sh|ps1]       # Dev loop script (see @05-build-deploy.md)
```

## Initialization Steps

### Step 1: Create Directories

```bash
mkdir -p {app-name}/{snap,src,schema,build-info,docs,scripts}
```

### Step 2: Select Templates

Copy the templates for your language:

**Python project:**
- Entry point: @templates/provider-template.py → src/main.py
- Snap config: @templates/snapcraft-python.yaml → snap/snapcraft.yaml

**C++ project:**
- Entry point: @templates/provider-template-cpp.cpp → src/main.cpp
- Build file: @templates/CMakeLists.txt → CMakeLists.txt
- Snap config: @templates/snapcraft-cpp.yaml → snap/snapcraft.yaml

C++ dependency installation (inside App Build Environment):
```bash
# Add Bosch APT repository
curl -s https://nexus.boschrexroth.com/repository/apt-hosted/gpg.key | sudo apt-key add -
echo "deb https://nexus.boschrexroth.com/repository/apt-hosted focal main" \
  | sudo tee /etc/apt/sources.list.d/bosch.list
sudo apt update
sudo apt install libctrlx-datalayer-dev libflatbuffers-dev flatbuffers-compiler -y
```

**.NET project:**
- Entry point: @templates/provider-template-csharp.cs → src/Program.cs
- Snap config: @templates/snapcraft-csharp.yaml → snap/snapcraft.yaml
- Also create: `{app}.csproj` (see template below)

.NET csproj template:
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <RuntimeIdentifier>linux-x64</RuntimeIdentifier>
    <SelfContained>true</SelfContained>
    <AssemblyName>ctrlx-{company}-{app}</AssemblyName>
  </PropertyGroup>
  <ItemGroup>
    <!-- Bosch NuGet feed: https://nexus.boschrexroth.com/repository/nuget-hosted/ -->
    <PackageReference Include="Datalayer" Version="2.4.*" />
    <PackageReference Include="Google.FlatBuffers" Version="24.*" />
  </ItemGroup>
</Project>
```

NuGet.Config (place in project root):
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="bosch-nexus"
         value="https://nexus.boschrexroth.com/repository/nuget-hosted/" />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
</configuration>
```

### Step 3: Fill in Metadata

Edit the placeholders in:
- `snap/snapcraft.yaml`: Replace `{app-name}`, `{company}`, and version number
- `build-info/package-manifest.json`: Update socket path and license config
- `docs/manual.md`: Describe application functionality and installation steps

## Post-Initialization Steps

After creating the directories, guide the user through:

Validate Snap configuration:
```bash
cd {app-name}
snapcraft lint  # Check syntax
```

Install dependencies (local development):
```bash
pip install ctrlx-datalayer flatbuffers  # Python
```

## First Build Test

Refer to the "Fast Dev Loop" section in @05-build-deploy.md.

## Common Mistakes to Avoid

❌ Forgetting to create the `build-info/` directory → reverse proxy will not work
❌ Using TCP ports instead of Unix Sockets → will fail compliance review
❌ Skipping the `docs/` directory → compliance check will not pass
✅ Always fill in all placeholders using the templates as the reference
```

**Step 2: Commit**

```bash
git add 02-project-scaffold.md
git commit -m "i18n: translate 02-project-scaffold.md to English"
```

---

## Task 4: Translate 03-datalayer-dev.md

**Files:**
- Modify: `03-datalayer-dev.md`

**Step 1: Replace section headers and prose (code blocks are already in English)**

Translate only the non-code text. Key translations:

- `## 架构模式` → `## Architecture`
- `### Provider（数据提供者）` → `### Provider`
- `### Consumer（数据消费者）` → `### Consumer`
- `## 1. Schema 设计（Flatbuffers）` → `## 1. Schema Design (Flatbuffers)`
- `创建 \`schema/{app}.fbs\`：` → `Create \`schema/{app}.fbs\`:`
- `编译：` → `Compile:`
- `## 2. Provider 实现` → `## 2. Provider Implementation`
- `完整示例（含优雅关闭）参见` → `Full example (with graceful shutdown): see`
- `完整示例（含 RAII 关闭）参见` → `Full example (with RAII shutdown): see`
- `完整示例（含 async/await 关闭）参见` → `Full example (with async/await shutdown): see`
- `## 3. Consumer 实现` → `## 3. Consumer Implementation`
- `### 订阅（实时监控）` → `### Subscription (real-time monitoring)`
- `### 批量读取（配置读取）` → `### Bulk Read (for configuration)`
- `## 4. 错误恢复（自动重连）` → `## 4. Error Recovery (Auto-Reconnect)`
- `## 5. 优雅关闭顺序` → `## 5. Graceful Shutdown Sequence`
- `正确关闭顺序（必须严格遵守，否则可能导致 Data Layer 节点残留）：` → `Correct shutdown sequence (must be followed strictly to avoid orphaned Data Layer nodes):`
- `## 6. 性能最佳实践` → `## 6. Performance Best Practices`
- `## 7. 故障排除` → `## 7. Troubleshooting`

Table translations for section 6:

| Chinese | English |
|---|---|
| 传感器实时数据 | Sensor real-time data |
| 订阅间隔 100ms | Use 100 ms subscription interval |
| 状态监控 | Status monitoring |
| 订阅间隔 1000ms | Use 1000 ms subscription interval |
| 配置读取 | Configuration reads |
| 批量读取，非循环单读 | Use bulk read, not per-item loop |
| 连接复用 | Connection reuse |
| 全局维护单个 Provider/Client 实例 | Maintain a single global Provider/Client instance |
| 写入频率 | Write frequency |
| 避免 >10Hz 写入，延长闪存寿命 | Avoid writes faster than 10 Hz to extend flash lifetime |

Table translations for section 7:

| Chinese symptom | English | Chinese cause | English | Chinese fix | English |
|---|---|---|---|---|---|
| Provider 创建返回 None | Provider creation returns None | IPC Socket 未就绪 | IPC socket not ready | 重试连接，检查 ctrlx-datalayer plug 是否已连接 | Retry connection; verify the ctrlx-datalayer plug is connected |
| 节点注册失败 | Node registration fails | 路径已被占用 | Path already registered | 使用 Data Layer Browser 检查现有节点 | Check existing nodes in Data Layer Browser |
| 读取超时 | Read timeout | Flatbuffers schema 版本不匹配 | Flatbuffers schema version mismatch | 重新编译 .fbs，确保客户端和服务端使用同一 schema | Recompile .fbs; ensure client and server use the same schema |
| 订阅无回调 | Subscription receives no callbacks | 路径拼写错误 | Incorrect node path | 在 Data Layer Browser 中验证节点路径 | Verify node path in Data Layer Browser |
| 优雅关闭卡住 | Graceful shutdown hangs | 未调用 unregister_node | unregister_node not called | 确保关闭顺序正确（见第5节） | Follow the correct shutdown sequence (see section 5) |

Write the complete translated file (replacing all Chinese text with English equivalents while keeping all code blocks intact).

**Step 2: Commit**

```bash
git add 03-datalayer-dev.md
git commit -m "i18n: translate 03-datalayer-dev.md to English"
```

---

## Task 5: Translate 04-snap-config.md

**Files:**
- Modify: `04-snap-config.md`

**Step 1: Replace entire file with English translation**

```markdown
# Snap Packaging Configuration

## snapcraft.yaml Structure

### Python Template (Parameterized)

```yaml
name: ctrlx-{company}-{app}
version: '{version}'
summary: {app} - ctrlX Data Layer Application
description: |
  {description}
  Provides real-time data via ctrlX Data Layer.
base: core22  # or core24
confinement: strict
grade: stable

parts:
  {app}:
    plugin: python
    source: .
    python-packages:
      - ctrlx-datalayer>=2.4
      - flatbuffers
    stage-packages:
      - libzmq5  # Data Layer dependency
    override-build: |
      # snapcraft 8.x: use $CRAFT_PART_INSTALL instead of $SNAPCRAFT_PART_INSTALL
      cp -r src/* ${CRAFT_PART_INSTALL}/

apps:
  {app}:
    command: bin/python3 $SNAP/src/main.py
    daemon: simple
    restart-condition: always
    environment:
      SNAP_DATA: $SNAP_DATA
      SNAP_COMMON: $SNAP_COMMON
    plugs:
      - network
      - network-bind
      - home
      - ctrlx-datalayer  # Content interface

plugs:
  ctrlx-datalayer:
    interface: content
    content: ctrlx-datalayer
    target: $SNAP_DATA/.datalayer
```

### C++ Template — Key Differences

```yaml
parts:
  {app}:
    plugin: cmake
    source: .
    build-packages:
      - build-essential
      - libctrlx-datalayer-dev
    stage-packages:
      - libzmq5

apps:
  {app}:
    command: usr/local/bin/{app}  # CMake install target
```

## build-info Configuration

### package-manifest.json (Critical)

```json
{
  "version": "1.0",
  "services": {
    "reverse_proxy": {
      "url": "/app/ctrlx-{company}-{app}",
      "websocket": true,
      "unix_socket": "/var/snap/ctrlx-{company}-{app}/current/package-run/ctrlx-{company}-{app}/ctrlx-{company}-{app}.web.sock",
      "access": "ctrlx-{company}-{app}.access"
    }
  },
  "ports": [],
  "licensing": {
    "enabled": true,
    "check_interval": 30,
    "url": "/.licensing/api/v1/capabilities/ctrlx-{company}-{app}"
  }
}
```

### slotplug-description.json

```json
{
  "description": "Minimal permissions for Data Layer access",
  "slots": [],
  "plugs": [
    {
      "name": "network",
      "reason": "Required for Data Layer communication"
    },
    {
      "name": "network-bind",
      "reason": "Bind to Unix Socket"
    },
    {
      "name": "ctrlx-datalayer",
      "interface": "content",
      "reason": "Access ctrlX Data Layer"
    }
  ]
}
```

## Key Configuration Notes

### Content Interface (ctrlx-datalayer)

This is the **only authorized mechanism** for communicating with the ctrlX system:
- `content`: Fixed identifier — always `ctrlx-datalayer`
- `target`: Mount point — the app accesses Data Layer via `$SNAP_DATA/.datalayer`
- Auto-mount: The system automatically maps the Data Layer Unix Socket at startup

### Reverse Proxy Configuration

Configured via `package-manifest.json → reverse_proxy`:
- `url`: Web UI access path, automatically integrated into ctrlX OS navigation
- `unix_socket`: The socket address the app listens on; Nginx proxies to this address
- `websocket`: Enables real-time WebSocket communication

### Security Hardening

- No global slots: Do not declare sensitive interfaces such as `system-observe`
- File permissions: Snap automatically restricts filesystem access (only `$SNAP_DATA` is writable)
- Network isolation: Unix Socket replaces TCP to avoid exposing the app to the external network
```

**Step 2: Commit**

```bash
git add 04-snap-config.md
git commit -m "i18n: translate 04-snap-config.md to English"
```

---

## Task 6: Translate 05-build-deploy.md

**Files:**
- Modify: `05-build-deploy.md`

**Step 1: Replace all Chinese prose with English (keep all code blocks intact)**

Key section translations:

- `## 快速开发循环（推荐日常使用）` → `## Fast Dev Loop (Recommended for Daily Use)`
- `> **一条命令完成**：构建 → 上传 → 验证运行状态` → `> **One command does it all**: Build → Upload → Verify`
- `### 前置配置（仅首次）` → `### Initial Setup (One-Time)`
- `### 每次迭代` → `### Each Iteration`
- `### 脚本输出示例` → `### Example Script Output`
- `### ctrlX REST API 认证说明` → `### ctrlX REST API Authentication`
- `# 手动获取 token（调试用）` → `# Manually obtain a token (for debugging)`
- `# 返回:` → `# Returns:`
- `## 构建策略选择` → `## Build Strategy Options`
- `### 策略 A: Docker 构建（Windows/macOS/ Linux 通用）` → `### Strategy A: Docker Build (Cross-Platform)`
- `**适用场景**:` → `**When to use:**`
- `开发团队使用 Windows` → `Development team uses Windows`
- `快速原型验证` → `Rapid prototyping`
- `无需安装 Ubuntu VM` → `No Ubuntu VM required`
- `**前置条件**:` → `**Prerequisites:**`
- `Docker Desktop 运行中` → `Docker Desktop running`
- `项目目录可访问` → `Project directory accessible`
- `**构建命令**:` → `**Build commands:**`
- `# x86_64 架构（用于 COREvirtual）` → `# x86_64 (for COREvirtual)`
- `# ARM64 架构（用于物理 ctrlX CORE）` → `# ARM64 (for physical ctrlX CORE)`
- `输出:` → `Output:`
- `### 策略 B: App Build Environment（官方推荐）` → `### Strategy B: App Build Environment (Official)`
- `生产环境构建` → `Production builds`
- `需要原生库链接` → `Native library linking required`
- `符合 Bosch 官方流程` → `Follows official Bosch build process`
- `步骤:` → `Steps:`
- `在 ctrlX WORKS 中启动 App Build Environment（QEMU VM）` → `Launch App Build Environment (QEMU VM) in ctrlX WORKS`
- `等待 VM 启动（端口 10022）` → `Wait for VM to boot (port 10022)`
- `# 默认密码:` → `# Default password:`
- `在 VM 中:` → `Inside the VM:`
- `复制结果到宿主机:` → `Copy output to host:`
- `## 部署流程` → `## Deployment`
- `### 本地测试（COREvirtual）` → `### Local Testing (COREvirtual)`
- `上传 Snap:` → `Upload Snap:`
- `打开 ctrlX OS Web 界面` → `Open ctrlX OS web interface`
- `启用 "Allow installation from unknown source"` → `Enable "Allow installation from unknown source"`
- `上传 .snap 文件` → `Upload the .snap file`
- `验证运行:` → `Verify operation:`
- `检查应用状态为 "Running"` → `Confirm app state shows "Running"`
- `查看 Logs: Diagnostics → Logbook` → `View logs: Diagnostics → Logbook`
- `验证 Data Layer 节点: Data Layer → Browser` → `Verify Data Layer nodes: Data Layer → Browser`
- `功能测试:` → `Functional testing:`
- `使用 Postman 或 SDK 客户端测试节点读写` → `Test node read/write with Postman or SDK client`
- `验证 Flatbuffers 序列化正确性` → `Verify Flatbuffers serialization`
- `### 生产部署（物理 ctrlX CORE）` → `### Production Deployment (Physical ctrlX CORE)`
- `签名验证:` → `Signature verification:`
- `确保 Snap 已通过 Bosch Rexroth 签名` → `Ensure the Snap has been signed by Bosch Rexroth`
- `未签名 Snap 只能用于开发模式` → `Unsigned Snaps can only be used in developer mode`
- `安装:` → `Installation:`
- `通过 ctrlX OS 界面上传` → `Upload via ctrlX OS interface`
- `配置:` → `Configuration:`
- `设置环境变量（如需要）` → `Set environment variables if needed`
- `配置许可证（如启用）` → `Configure license if enabled`
- `## 故障排除` → `## Troubleshooting`
- Error table translations: `在 VM 中运行` → `Run inside VM`, `检查网络连接` → `Check network connection`, `确保使用` → `Make sure to use`
- `App 无法启动` → `App fails to start`, `检查 \`snapcraft.yaml\` 的 \`command\` 路径` → `Check the \`command\` path in \`snapcraft.yaml\``
- `Data Layer 连接失败` → `Data Layer connection fails`, `确认 \`ctrlx-datalayer\` plug 已连接` → `Verify the \`ctrlx-datalayer\` plug is connected`
- `权限拒绝` → `Permission denied`, `检查 Unix Socket 路径权限为 0600` → `Check that the Unix Socket path has 0600 permissions`

**Step 2: Commit**

```bash
git add 05-build-deploy.md
git commit -m "i18n: translate 05-build-deploy.md to English"
```

---

## Task 7: Translate 06-compliance.md

**Files:**
- Modify: `06-compliance.md`

**Step 1: Replace entire file with English translation**

```markdown
# Compliance Checklist

## Category 1 (Baseline Compliance — Required)

### File Integrity

- [ ] `snap/snapcraft.yaml` exists and passes syntax validation
- [ ] `build-info/package-manifest.json` exists and contains a `reverse_proxy` configuration
- [ ] `build-info/slotplug-description.json` describes all interfaces
- [ ] `docs/manual.md` includes installation, configuration, and troubleshooting sections
- [ ] `docs/test-setup.md` describes at least one test scenario
- [ ] `docs/release-notes.md` includes a version changelog

### Technical Specification

- [ ] ctrlx-datalayer Python binding >= 2.4 (or equivalent C++/C# version)
- [ ] snapcraft version >= 8.x (check: `snapcraft --version`)
- [ ] Snap name follows the `ctrlx-{company}-{app}` format
- [ ] Uses `core22` or `core24` as the base image
- [ ] `confinement: strict` is set
- [ ] No global slots declared
- [ ] Plugs limited to: `network`, `network-bind`, `home`, `ctrlx-datalayer`
- [ ] Unix Socket path is configured correctly (TCP ports avoided)

### Resource Limits

- [ ] RAM < 75 MB after app startup (verify with `top`)
- [ ] Snap package size < 100 MB (verify with `ls -lh *.snap`)
- [ ] CPU usage < 5% average load

## Category 2 (Advanced Features — If Used)

### License Integration (if licensing is enabled)

- [ ] `package-manifest.json` has `licensing.enabled = true`
- [ ] App calls the License Manager API on startup
- [ ] Displays a friendly error message when license is absent (no crash)

### Web UI (if provided)

- [ ] Exposed through the reverse proxy (not a direct port)
- [ ] Uses HTTPS/WSS communication
- [ ] Integrated into the ctrlX OS navigation bar

### Data Persistence

- [ ] Configuration files stored in `$SNAP_COMMON` (preserved across upgrades)
- [ ] Transient data stored in `$SNAP_DATA` (version-isolated)
- [ ] Avoid frequent writes to extend flash storage lifetime

## Category 3 (Enterprise — Optional)

- [ ] Supports Solution backup/restore
- [ ] Multi-language support (i18n)
- [ ] Detailed audit logging
- [ ] Exposes performance monitoring metrics

## Automated Checks

```bash
# Verify file structure
ls -la snap/snapcraft.yaml build-info/*.json docs/*.md

# Validate Snap syntax
snapcraft lint

# Check resource usage (run after installation)
ps aux | grep {app-name}          # Memory
du -sh /var/snap/{app-name}/      # Storage

# Verify interface connections
snap connections {app-name}
```

## Signing and Publishing

### Final Checks:
- [ ] Snap has been signed by Bosch Rexroth
- [ ] Version number follows Semantic Versioning (SemVer)
- [ ] Release notes include compatibility information

### Pre-submission Confirmation:
All Category 1 items must pass. Category 2 items are required only if the corresponding feature is used.
```

**Step 2: Commit**

```bash
git add 06-compliance.md
git commit -m "i18n: translate 06-compliance.md to English"
```

---

## Task 8: Create README-cn.md

**Files:**
- Create: `README-cn.md`

**Step 1: Create README-cn.md with current Chinese content + language link**

Copy the current `README.md` content and add a language navigation line at the top:

```markdown
[English](README.md) | 中文

# ctrlX App 开发 Skill

> 用于 [Claude Code](https://claude.ai/code) 的 ctrlX CORE 工业应用开发助手
> 基准版本：**ctrlX OS 2.x | ctrlX SDK 2.4.x | snapcraft 8.x**

## 这是什么？

帮你快速开发符合 Bosch Rexroth 标准的 ctrlX CORE 工业应用，覆盖从项目初始化到发布的完整流程。

**核心特性：**
- 智能阶段检测：自动识别项目所处开发阶段并主动引导
- 诊断模式：描述问题即可获得针对性解决步骤
- 三语言支持：Python / C++ / .NET 模板完整对称
- 一键开发循环：构建 → 上传 → 验证，自动化完成

## 安装（30秒）

```bash
# 全局安装（所有项目可用）
git clone https://github.com/barzoo/claude-code-skill-ctrlx-app-dev \
  ~/.claude/skills/ctrlx-app-dev
```

```bash
# 项目级安装（仅当前项目）
git clone https://github.com/barzoo/claude-code-skill-ctrlx-app-dev \
  .claude/skills/ctrlx-app-dev
```

## 5 分钟上手

### 1. 创建项目

```
/ctrlx-app-dev init my-sensor-app --lang python
```

支持语言：`python` | `cpp` | `csharp`

### 2. 实现 Data Layer 节点

```
/ctrlx-app-dev datalayer add-node
```

告诉 Claude 你的需求，例如：
```
添加一个温度传感器节点，每秒采集数据，范围 0-100 度
```

### 3. 一键构建并部署到 COREvirtual

```bash
# 首次配置（仅需一次）
export CTRLX_HOST=192.168.1.1
export CTRLX_USER=admin
export CTRLX_PASS=your-password
cp templates/dev-loop.sh scripts/dev-loop.sh && chmod +x scripts/dev-loop.sh
```

```
/ctrlx-app-dev build --arch amd64
```

脚本自动完成：构建 snap → 上传到设备 → 等待安装 → 抓取日志，全程约 30-60 秒。

### 4. 合规检查（发布前必做）

```
/ctrlx-app-dev compliance
```

### 5. 问题诊断

```
/ctrlx-app-dev diagnose
```

或直接描述问题，skill 会先问 2 个诊断问题，再给出针对性步骤。

## 命令速查

| 命令 | 作用 |
|------|------|
| `init [name] --lang python\|cpp\|csharp` | 创建项目 |
| `datalayer add-node\|provider\|consumer` | Data Layer 开发 |
| `build [--arch amd64\|arm64]` | 构建并部署 |
| `compliance` | 合规检查 |
| `diagnose` | 问题诊断模式 |
| `overview` | 架构总览 |

## 文件结构

```
ctrlx-app-dev/
├── SKILL.md                    # 主入口（阶段检测 + 命令路由 + 诊断模式）
├── 01-overview.md              # 架构概述与技术栈选择
├── 02-project-scaffold.md      # 项目初始化（Python / C++ / .NET）
├── 03-datalayer-dev.md         # Data Layer 开发指南（SDK 2.4.x，三语言）
├── 04-snap-config.md           # Snap 打包配置详解
├── 05-build-deploy.md          # 构建部署（含快速开发循环）
├── 06-compliance.md            # 合规检查清单
└── templates/
    ├── provider-template.py        # Python Provider 模板（SDK 2.4.x）
    ├── provider-template-cpp.cpp   # C++ Provider 模板
    ├── provider-template-csharp.cs # C# Provider 模板
    ├── snapcraft-python.yaml       # Python Snap 配置模板
    ├── snapcraft-cpp.yaml          # C++ Snap 配置模板
    ├── snapcraft-csharp.yaml       # C# Snap 配置模板
    ├── CMakeLists.txt              # C++ 构建文件模板
    ├── package-manifest.json       # 反向代理 + 许可证配置
    ├── dev-loop.sh                 # 开发循环脚本（Linux/WSL）
    └── dev-loop.ps1                # 开发循环脚本（Windows PowerShell）
```

## 参考资料

- [ctrlX Automation SDK 官方文档](https://boschrexroth.github.io/ctrlx-automation-sdk/)
- [snapcraft 8.x 文档](https://snapcraft.io/docs)
- [Flatbuffers 文档](https://google.github.io/flatbuffers/)
```

**Step 2: Commit**

```bash
git add README-cn.md
git commit -m "i18n: add Chinese README as README-cn.md"
```

---

## Task 9: Rewrite README.md as English Primary File

**Files:**
- Modify: `README.md`

**Step 1: Replace entire README.md with English content + language link**

```markdown
[中文文档](README-cn.md) | English

# ctrlX App Development Skill

> A [Claude Code](https://claude.ai/code) skill for building Bosch Rexroth ctrlX CORE industrial applications
> Baseline: **ctrlX OS 2.x | ctrlX SDK 2.4.x | snapcraft 8.x**

## What is this?

A Claude Code skill that guides you through the full lifecycle of ctrlX CORE app development — from project scaffolding to publishing — following Bosch Rexroth standards.

**Key features:**
- **Smart phase detection**: Automatically identifies your current development phase and provides proactive guidance
- **Diagnostic mode**: Describe your problem in plain language and get targeted, step-by-step resolution
- **Three-language support**: Complete, symmetric templates for Python, C++, and .NET
- **One-command dev loop**: Build → Upload → Verify in a single script (~30–60 seconds)

## Installation

```bash
# Global install (available in all projects)
git clone https://github.com/barzoo/claude-code-skill-ctrlx-app-dev \
  ~/.claude/skills/ctrlx-app-dev
```

```bash
# Project-level install (current project only)
git clone https://github.com/barzoo/claude-code-skill-ctrlx-app-dev \
  .claude/skills/ctrlx-app-dev
```

## 5-Minute Quickstart

### 1. Create a project

```
/ctrlx-app-dev init my-sensor-app --lang python
```

Supported languages: `python` | `cpp` | `csharp`

### 2. Implement a Data Layer node

```
/ctrlx-app-dev datalayer add-node
```

Describe what you need, for example:
```
Add a temperature sensor node that samples data every second, range 0–100 °C
```

### 3. Build and deploy to COREvirtual in one command

```bash
# One-time setup
export CTRLX_HOST=192.168.1.1
export CTRLX_USER=admin
export CTRLX_PASS=your-password
cp templates/dev-loop.sh scripts/dev-loop.sh && chmod +x scripts/dev-loop.sh
```

```
/ctrlx-app-dev build --arch amd64
```

The script handles everything: build snap → upload to device → wait for install → fetch logs. Typically completes in 30–60 seconds.

### 4. Run compliance checks (required before publishing)

```
/ctrlx-app-dev compliance
```

### 5. Diagnose issues

```
/ctrlx-app-dev diagnose
```

Or simply describe the problem in plain text. The skill will ask two diagnostic questions, then provide targeted resolution steps.

## Command Reference

| Command | Description |
|---------|-------------|
| `init [name] --lang python\|cpp\|csharp` | Scaffold a new project |
| `datalayer add-node\|provider\|consumer` | Data Layer development |
| `build [--arch amd64\|arm64]` | Build and deploy |
| `compliance` | Run compliance checklist |
| `diagnose` | Enter diagnostic mode |
| `overview` | Architecture overview |

## File Structure

```
ctrlx-app-dev/
├── SKILL.md                    # Entry point (phase detection, routing, diagnostics)
├── 01-overview.md              # Architecture overview and tech stack
├── 02-project-scaffold.md      # Project initialization (Python / C++ / .NET)
├── 03-datalayer-dev.md         # Data Layer development guide (SDK 2.4.x, 3 languages)
├── 04-snap-config.md           # Snap packaging configuration
├── 05-build-deploy.md          # Build and deploy (includes fast dev loop)
├── 06-compliance.md            # Compliance checklist
└── templates/
    ├── provider-template.py        # Python Provider template (SDK 2.4.x)
    ├── provider-template-cpp.cpp   # C++ Provider template
    ├── provider-template-csharp.cs # C# Provider template
    ├── snapcraft-python.yaml       # Python Snap config template
    ├── snapcraft-cpp.yaml          # C++ Snap config template
    ├── snapcraft-csharp.yaml       # C# Snap config template
    ├── CMakeLists.txt              # C++ build file template
    ├── package-manifest.json       # Reverse proxy + license config
    ├── dev-loop.sh                 # Dev loop script (Linux/WSL)
    └── dev-loop.ps1                # Dev loop script (Windows PowerShell)
```

## References

- [ctrlX Automation SDK Documentation](https://boschrexroth.github.io/ctrlx-automation-sdk/)
- [snapcraft 8.x Documentation](https://snapcraft.io/docs)
- [Flatbuffers Documentation](https://google.github.io/flatbuffers/)
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "i18n: rewrite README.md as English primary file with language link"
```

---

## Task 10: Push to GitHub

**Step 1: Verify clean working tree**

```bash
git status
# Expected: nothing to commit, working tree clean
```

**Step 2: Push**

```bash
git push origin main
```

**Step 3: Verify**

```bash
git log --oneline -12
# Expected: 10 i18n commits visible
```
