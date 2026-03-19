---
name: ctrlx-app-dev
description: 模块化 ctrlX App 开发助手。支持项目初始化、Data Layer 实现、Snap 打包、构建部署及合规检查。通过子模块引用实现专业工业应用开发。
argument-hint: [init|datalayer|snap|build|compliance|overview]
---

# ctrlX App 开发助手（模块化版本）

你正在使用 **模块化 ctrlX App 开发 Skill**。该 Skill 采用分层架构，主文件仅包含路由逻辑，详细指南和模板存储在子文件中。

## 快速导航

根据用户需求，引用相应子文件：

- **总体架构与规范** → 参考 @01-overview.md
- **创建新项目** → 执行 @02-project-scaffold.md 中的初始化流程
- **Data Layer 开发** → 遵循 @03-datalayer-dev.md 的实现规范
- **Snap 配置详解** → 使用 @04-snap-config.md 的模板和解释
- **构建与部署** → 按 @05-build-deploy.md 的步骤操作
- **合规性验证** → 对照 @06-compliance.md 的检查清单

## 命令路由逻辑

当用户输入以下命令时，执行对应操作：

### `/ctrlx-app-dev init [name] --lang [python|cpp|csharp]`
1. 读取 @02-project-scaffold.md 中的目录结构规范
2. 根据语言选择 @templates/snapcraft-{lang}.yaml 模板
3. 复制 @templates/package-manifest.json 到 build-info/
4. 复制 @templates/provider-template.py（或 cpp/csharp 对应模板）到 src/
5. 按 @02-project-scaffold.md 的 "初始化后步骤" 指导用户

### `/ctrlx-app-dev datalayer [add-node|provider|consumer]`
1. 查阅 @03-datalayer-dev.md 的架构说明
2. 根据操作类型选择对应代码模板
3. 如需要 Flatbuffers，参考 @03-datalayer-dev.md 的 Schema 设计章节

### `/ctrlx-app-dev build [--arch]`
1. 读取 @05-build-deploy.md 的 "构建策略" 章节
2. 根据用户操作系统（Windows/Linux）选择 Docker 或 ABE 方式
3. 提供对应构建脚本

### `/ctrlx-app-dev compliance`
1. 加载 @06-compliance.md 的 Category 1/2/3 检查清单
2. 逐项验证当前项目配置
3. 输出合规报告

## 核心约束（强制执行）

无论调用哪个子模块，必须遵守以下硬性规范（来自 @01-overview.md）：

- **命名规范**: `ctrlx-{company}-{app}_{version}_{arch}.snap`
- **基础镜像**: 必须使用 `core22` 或 `core24`，strict confinement
- **通信方式**: 优先 Unix Socket（而非 TCP 端口）
- **资源限制**: RAM &lt; 75MB, Snap &lt; 100MB
- **必需文件**: package-manifest.json, manual.md, test-setup.md, release-notes.md

## 交互模式

当用户首次使用或输入 `overview` 时：
- 提供 @01-overview.md 的摘要内容
- 询问用户当前处于哪个开发阶段（初始化/开发/构建/部署）
- 引导至对应子模块

当用户询问具体技术细节（如 "如何配置反向代理"）：
- 引用 @04-snap-config.md 的相关章节
- 提供具体代码示例

当用户需要验证项目：
- 使用 @06-compliance.md 作为检查基准
- 逐项确认合规性