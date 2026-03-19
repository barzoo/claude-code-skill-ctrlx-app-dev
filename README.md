# ctrlX App 开发 Skill 快速指南

## 这是什么？
用于 [Claude Code](https://claude.ai/code) 的自动化助手，帮你快速开发符合 Bosch Rexroth 标准的 ctrlX CORE 工业应用。

## 安装（30秒）

```bash
# 方式1：全局安装（所有项目可用）
mkdir -p ~/.claude/skills/ctrlx-app-dev
cp -r skill-modules/* ~/.claude/skills/ctrlx-app-dev/

# 方式2：项目级安装（仅当前项目）
mkdir -p .claude/skills/ctrlx-app-dev
cp -r skill-modules/* .claude/skills/ctrlx-app-dev/
```

## 5 分钟上手

### 1. 创建项目
在 Claude Code 中输入：
```
/ctrlx-app-dev init my-sensor-app --lang python
```
Claude 会自动生成完整的 ctrlX App 项目结构。

### 2. 实现功能
告诉 Claude 你的需求：
```
添加一个温度传感器节点，每秒采集数据，范围 0-100 度
```
Claude 会自动：
- 创建 Flatbuffers schema
- 实现 Data Layer Provider 代码
- 配置 Snap 权限

### 3. 构建应用
```
/ctrlx-app-dev build --arch arm64
```
自动选择 Docker 或虚拟机环境，输出 `.snap` 安装包。

### 4. 合规检查（发布前必做）
```
/ctrlx-app-dev compliance check
```
验证是否符合 Bosch Rexroth Category 1 标准。

## 常用命令速查

| 命令 | 作用 |
|------|------|
| `init [name] --lang python` | 创建 Python 项目 |
| `init [name] --lang cpp` | 创建 C++ 项目 |
| `datalayer add-node [path]` | 添加 Data Layer 数据节点 |
| `build [--arch arm64\|amd64]` | 构建 Snap 安装包 |
| `compliance` | 合规性检查清单 |
| `overview` | 查看架构总览 |

## 核心特性

✅ **标准化**：自动生成符合 Bosch 规范的项目结构  
✅ **安全**：默认使用 Unix Socket，严格权限控制  
✅ **多语言**：支持 Python、C++、.NET  
✅ **开箱即用**：包含完整的 Data Layer 通信模板  

## 文档结构

```
ctrlx-app-dev/
├── SKILL.md              # 主入口（Claude 调用）
├── 01-overview.md        # 架构概述
├── 02-project-scaffold.md # 项目初始化
├── 03-datalayer-dev.md  # Data Layer 开发
├── 04-snap-config.md    # Snap 配置
├── 05-build-deploy.md   # 构建部署
├── 06-compliance.md     # 合规检查
└── templates/           # 代码模板
```

## 下一步

- 查看详细文档：在 Claude 中输入 `/ctrlx-app-dev overview`
- 官方参考：[ctrlX SDK 文档](https://boschrexroth.github.io/ctrlx-automation-sdk/)
- 问题反馈：通过 GitHub Issues（如果是开源项目）

---

**提示**：首次使用建议运行 `/ctrlx-app-dev overview`，Claude 会为你讲解 ctrlX 架构基础。
