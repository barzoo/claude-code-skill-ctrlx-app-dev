# ctrlX App 开发概述

> **当前基准版本**: ctrlX OS 2.x | ctrlX SDK 2.4.x | snapcraft 8.x | Ubuntu Core 22/24

## 什么是 ctrlX App

ctrlX App 是基于 Ubuntu Core Snap 格式的工业自动化应用，运行在 Bosch Rexroth ctrlX CORE 控制系统上。

## 技术栈选择

| 语言 | 适用场景 | 性能 | 开发速度 |
|------|----------|------|----------|
| **Python** | 数据处理、算法原型 | 中等 | ⭐⭐⭐⭐⭐ | (ctrlx-datalayer>=2.4) |
| **C++** | 实时控制、高性能 | 高 | ⭐⭐⭐ |
| **.NET/C#** | 企业集成、HMI | 中高 | ⭐⭐⭐⭐ |

## 架构原则

### 1. 安全模型
- **严格隔离**: Snap 的 strict confinement 限制文件系统访问
- **最小权限**: 仅声明必需的 plugs（network、network-bind、ctrlx-datalayer）
- **通信安全**: Unix Socket > TCP Port，所有通信加密

### 2. 数据流架构
[Physical Layer] → [ctrlX CORE Data Layer] → [Your App (Provider/Consumer)]
↑                           ↓
[Other Apps] ←──────┴─────────────────────────────┘
plain
复制

### 3. 生命周期管理
- **安装**: Snap 原子性安装
- **启动**: Systemd 管理，支持自动重启
- **升级**: 事务性更新，失败自动回滚
- **配置**: 通过 Data Layer 或环境变量

## 开发阶段流程

1. **阶段 1: 初始化** → 项目结构、Snap 配置、基础代码
2. **阶段 2: 开发** → Data Layer 节点、业务逻辑、Flatbuffers
3. **阶段 3: 构建** → Docker 或 ABE 环境编译
4. **阶段 4: 测试** → COREvirtual 本地测试
5. **阶段 5: 合规** → 文档完善、资源检查、安全审计
6. **阶段 6: 发布** → Bosch Rexroth 签名、上架

## 关键设计决策

### 为什么选择 Unix Socket？
- ✅ 避免端口冲突（ctrlX 系统已使用 80/443/4840 等）
- ✅ 无需防火墙配置
- ✅ 符合 Snap 安全模型
- ✅ 通过反向代理暴露 Web 服务

### Data Layer vs REST API
- **Data Layer**: 实时数据、状态同步、机器间通信（推荐）
- **REST API**: 配置管理、历史查询、第三方集成（可选）

## 资源限制基准

| 指标 | 限制值 | 监测方法 |
|------|--------|----------|
| RAM | < 75MB | `top` 或系统监视器 |
| 存储 | < 100MB | `du -sh $SNAP` |
| CPU | < 5% 平均 | `htop` |
| 启动时间 | < 10s | 系统日志 |

## 延伸阅读

- 详细配置: @04-snap-config.md
- 构建指南: @05-build-deploy.md
- 合规清单: @06-compliance.md