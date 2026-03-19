# ctrlX App Dev Skill 改进设计文档

**日期**: 2026-03-19
**状态**: 已批准
**基准版本**: ctrlX OS 2.x, ctrlX SDK 2.4.x, snapcraft 8.x, Ubuntu Core 22/24

---

## 背景与目标

现有 `ctrlx-app-dev` skill 存在以下问题：
1. 代码示例基于旧版 SDK API，部分示例无法直接运行
2. 模板仅覆盖 Python，C++ 和 .NET 缺失
3. 交互模式被动，不能诊断问题也不能感知开发阶段
4. 本地开发循环（构建→部署→验证）需手动操作，效率低

**目标**：以 ctrlX SDK 2.4.x 为基准，全面提升三语言支持深度，新增智能交互和自动化开发循环。

---

## 设计决策

### 选择方案 B（结构重组，保持向后兼容）

保持现有 6 个模块文件结构不变，在每个模块内部做深度提升，避免破坏现有引用路径。

**放弃方案**：
- 方案 A（精准修补）：无法解决交互模式和版本问题
- 方案 C（微服务化）：文件数量翻倍，维护成本过高

---

## 变更范围

### 1. SKILL.md — 智能路由重设计

#### 阶段感知逻辑

启动时扫描当前目录，自动判断开发阶段并给出主动提示：

| 检测条件 | 判断阶段 | 主动行为 |
|---|---|---|
| 无 `snap/` 目录 | 未初始化 | 引导运行 `init` 命令 |
| 有 `snap/` 但无 `*.snap` 文件 | 开发中 | 询问当前在做什么 |
| 有 `*.snap` 但无部署记录 | 待部署 | 引导本地开发循环 |
| 有 `snap/` 但缺 `build-info/` | 配置缺失 | 直接警告并提供修复步骤 |

#### 诊断路由

用户描述问题时（非命令格式），先问 2 个诊断问题：
1. 确认症状范围（节点不可见 / 读取错误 / 数据格式错误 / 构建失败）
2. 确认运行环境（COREvirtual / 物理 ctrlX CORE，SDK 版本）

然后给出针对性步骤，而非通用答案。

#### 新增命令

```
/ctrlx-app-dev diagnose    # 触发诊断模式
```

---

### 2. 03-datalayer-dev.md — 按 SDK 2.4.x 全面重写

#### API 变更要点（v1.x → v2.x）

| 旧 API | 新 API |
|---|---|
| `get_client(system, "ipc://")` | `system.factory().create_client("ipc://")` |
| `ProviderNode(cb1, cb2, ...)` | `ProviderNodeCallbacks` dataclass |
| `builder.StartObject()` | 正确的 Flatbuffers table builder 序列 |
| 手动连接字符串 | `get_datalayer_system_url()` 自动获取 |

#### 三语言覆盖场景（对称）

每种语言均覆盖：
- Provider 初始化（正确生命周期）
- 单节点注册 + 回调实现
- 多节点批量注册
- Consumer 订阅（单节点 + 多节点）
- 批量读取
- 错误恢复（连接断开自动重连）
- 优雅关闭（SIGTERM 处理）

**Python** — 基于 `ctrlx-datalayer>=2.4` Python binding
**C++** — 基于 `comm.datalayer` SDK，RAII 风格
**.NET/C#** — 基于 `Datalayer` NuGet 包，DI + async/await

---

### 3. 05-build-deploy.md — 新增快速开发循环

#### 章节结构调整

```
原：策略A（Docker）→ 策略B（ABE）→ 部署 → 故障排除
新：快速开发循环 → 策略A（Docker）→ 策略B（ABE）→ 部署 → 故障排除
```

#### 开发循环脚本功能

```
1. 读取环境变量（CTRLX_HOST, CTRLX_USER, CTRLX_PASS）
2. Docker 构建 snap（amd64 或 arm64）
3. 通过 REST API 获取认证 token
   POST /identity-manager/api/v1/auth/token
4. 上传 snap
   POST /package-manager/api/v1/packages
5. 轮询安装状态直到完成
   GET /package-manager/api/v1/packages/{name}
6. 检查 app 状态为 "running"
7. 抓取最新日志（50行）
   GET /log/api/v1/entries?filter={app-name}
8. 输出摘要（成功/失败 + 启动耗时）
```

使用方式：
```bash
export CTRLX_HOST=192.168.1.1
export CTRLX_USER=admin
export CTRLX_PASS=xxx
./scripts/dev-loop.sh --arch amd64
```

---

### 4. 02-project-scaffold.md — 补全 C++/.NET 初始化

**C++ 补充**：
- 生成 `CMakeLists.txt`（含 `find_package(comm.datalayer)` 和交叉编译工具链配置）
- 说明 `libctrlx-datalayer-dev` 安装来源（Bosch APT 仓库）

**.NET 补充**：
- 生成 `.csproj`（含 `Datalayer` NuGet 包）
- 说明 Bosch 私有 NuGet feed 配置方式

---

### 5. templates/ — 新增文件清单

| 文件 | 说明 |
|---|---|
| `provider-template.py` | **更新**：按 SDK 2.4.x 重写，文件名不变 |
| `provider-template-cpp.cpp` | **新增**：C++ Provider 完整示例 |
| `provider-template-csharp.cs` | **新增**：C# Provider 完整示例 |
| `snapcraft-cpp.yaml` | **新增**：C++ cmake plugin 模板 |
| `snapcraft-csharp.yaml` | **新增**：.NET dotnet plugin 模板 |
| `CMakeLists.txt` | **新增**：C++ 项目构建文件模板 |
| `dev-loop.sh` | **新增**：Linux/WSL 开发循环脚本 |
| `dev-loop.ps1` | **新增**：Windows PowerShell 开发循环脚本 |

---

### 6. 小幅更新（无结构变化）

- `01-overview.md`：更新版本号引用（core22/core24，SDK 2.4.x）
- `04-snap-config.md`：C++ 模板差异章节补全，更新 snapcraft 8.x 语法
- `06-compliance.md`：新增 SDK 版本检查项，更新自动化检查脚本

---

## 不在本次范围内

- CI/CD 流程（GitHub Actions / GitLab CI）
- 多语言独立 skill 子目录拆分
- ctrlX WORKS IDE 集成调试
- 许可证管理深度集成

---

## 成功标准

1. 所有代码示例基于 SDK 2.4.x，可直接运行
2. Python / C++ / .NET 三语言模板完整对称
3. `dev-loop.sh/ps1` 在 COREvirtual 环境一键验证通过
4. SKILL.md 能正确检测项目阶段并给出主动提示
