---
name: ctrlx-app-dev
description: 模块化 ctrlX App 开发助手（SDK 2.4.x）。支持项目初始化、Data Layer 实现、Snap 打包、构建部署及合规检查。含智能阶段检测和问题诊断。
argument-hint: [init|datalayer|snap|build|compliance|overview|diagnose]
---

# ctrlX App 开发助手

## 启动时：自动检测项目阶段

**每次调用时，先扫描当前目录，判断阶段并主动提示：**

```
检测逻辑（按优先级）：
1. 无 snap/ 目录             → 阶段: 未初始化 → 提示运行 init
2. 有 snap/ 且缺 build-info/ → 阶段: 配置缺失 → 警告并给修复步骤
3. 有 snap/ 但无 *.snap 文件 → 阶段: 开发中   → 询问当前在做什么
4. 有 *.snap 文件            → 阶段: 待部署   → 引导开发循环
```

示例响应（阶段 1）：
> "检测到当前目录没有 snap/ 文件夹，项目尚未初始化。
> 运行以下命令开始：`/ctrlx-app-dev init my-app --lang python`"

---

## 命令路由

### `/ctrlx-app-dev init [name] --lang [python|cpp|csharp]`
1. 读取 @02-project-scaffold.md 中的目录结构规范
2. 根据语言选择对应模板：
   - Python: @templates/snapcraft-python.yaml + @templates/provider-template.py
   - C++: @templates/snapcraft-cpp.yaml + @templates/provider-template-cpp.cpp + @templates/CMakeLists.txt
   - C#: @templates/snapcraft-csharp.yaml + @templates/provider-template-csharp.cs
3. 复制 @templates/package-manifest.json 到 build-info/
4. 按 @02-project-scaffold.md 的 "初始化后步骤" 引导用户

### `/ctrlx-app-dev datalayer [add-node|provider|consumer]`
1. 查阅 @03-datalayer-dev.md（SDK 2.4.x 版本）
2. 根据用户语言（Python/C++/C#）选择对应代码段
3. 如需 Flatbuffers，参考第1节的 Schema 设计

### `/ctrlx-app-dev build [--arch amd64|arm64]`
1. 读取 @05-build-deploy.md 的 "快速开发循环" 章节（首选）
2. 如无 dev-loop 脚本，提供 Docker 构建命令

### `/ctrlx-app-dev compliance`
1. 加载 @06-compliance.md 的 Category 1/2/3 检查清单
2. 扫描当前项目文件，逐项核对
3. 输出合规报告（通过/失败/缺失）

### `/ctrlx-app-dev diagnose`
触发诊断模式（见下方）

---

## 诊断模式

当用户描述问题（而非命令格式）时，**先问 2 个诊断问题，再给出针对性答案**：

**问题 1：确认症状**
> "你遇到的是哪种情况？
> A. 节点在 Data Layer Browser 中不可见
> B. 节点可见但读取返回错误码
> C. 数据格式错误（Flatbuffers 解析失败）
> D. 构建或打包失败"

**问题 2：确认环境**
> "你在哪个环境运行？
> A. COREvirtual（本地虚拟机）
> B. 物理 ctrlX CORE 设备
> C. 本地开发环境（非 snap）"

收到回答后，直接给出针对该症状+环境的具体步骤，参考 @03-datalayer-dev.md 第7节或 @05-build-deploy.md 故障排除表。

---

## 核心约束（强制执行）

- **SDK 版本**: ctrlx-datalayer >= 2.4 (Python) | comm.datalayer >= 2.4 (C++) | Datalayer >= 2.4 (.NET)
- **命名规范**: `ctrlx-{company}-{app}_{version}_{arch}.snap`
- **基础镜像**: `core22` 或 `core24`，strict confinement
- **通信方式**: Unix Socket（IPC），非 TCP 端口
- **资源限制**: RAM < 75MB, Snap < 100MB
- **必需文件**: package-manifest.json, manual.md, test-setup.md, release-notes.md
