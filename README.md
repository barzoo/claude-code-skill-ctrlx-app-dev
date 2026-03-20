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
