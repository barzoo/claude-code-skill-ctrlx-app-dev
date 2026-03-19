# 构建与部署指南

## 构建策略选择

### 策略 A: Docker 构建（Windows/macOS/ Linux 通用）

**适用场景**:
- 开发团队使用 Windows
- 快速原型验证
- 无需安装 Ubuntu VM

**前置条件**:
- Docker Desktop 运行中
- 项目目录可访问

**构建命令**:

```bash
# x86_64 架构（用于 COREvirtual）
docker run --rm -v "${PWD}:/build" -w /build \
  -e SNAPCRAFT_BUILD_ENVIRONMENT=host \
  ghcr.io/canonical/snapcraft:8_core22 \
  snapcraft --target-arch=amd64

# ARM64 架构（用于物理 ctrlX CORE）
docker run --rm -v "${PWD}:/build" -w /build \
  -e SNAPCRAFT_BUILD_ENVIRONMENT=host \
  ghcr.io/canonical/snapcraft:8_core22 \
  snapcraft --target-arch=arm64
```

输出: ctrlx-{company}-{app}_{version}_{arch}.snap 在 snap/ 目录

### 策略 B: App Build Environment（官方推荐）
**适用场景**:
- 生产环境构建
- 需要原生库链接
- 符合 Bosch 官方流程

步骤:
- 在 ctrlX WORKS 中启动 App Build Environment（QEMU VM）
- 等待 VM 启动（端口 10022）
- SSH 连接:
```bash
ssh boschrexroth@localhost -p 10022
# 默认密码: boschrexroth
```
- 在 VM 中:
```bash
sudo apt update
sudo apt install libctrlx-datalayer-dev -y
cd /path/to/project
snapcraft
```
- 复制结果到宿主机:
```bash
scp -P 10022 boschrexroth@localhost:~/project/*.snap .
```
## 部署流程

### 本地测试（COREvirtual）
1. 上传 Snap:
- 打开 ctrlX OS Web 界面（https://localhost）
- Settings → App Management → Install
- 启用 "Allow installation from unknown source"
- 上传 .snap 文件
2. 验证运行:
- 检查应用状态为 "Running"
- 查看 Logs: Diagnostics → Logbook
- 验证 Data Layer 节点: Data Layer → Browser
3. 功能测试:
- 使用 Postman 或 SDK 客户端测试节点读写
- 验证 Flatbuffers 序列化正确性

### 生产部署（物理 ctrlX CORE）
1. 签名验证:
- 确保 Snap 已通过 Bosch Rexroth 签名
- 未签名 Snap 只能用于开发模式
2. 安装:
- 通过 ctrlX OS 界面上传
- 或命令行: snap install ctrlx-{company}-{app}.snap --dangerous（开发模式）
3. 配置:
- 设置环境变量（如需要）
- 配置许可证（如启用）


## 故障排除

| 构建错误                           | 解决                                               |
| ------------------------------ | ------------------------------------------------ |
| `snapcraft: command not found` | 在 VM 中运行 `sudo snap install snapcraft --classic` |
| `Failed to pull source`        | 检查网络连接，或添加 `--use-lxd` 参数                        |
| `Architecture mismatch`        | 确保使用 `--target-arch=arm64` 用于物理设备                |

| 部署错误            | 解决                                 |
| --------------- | ---------------------------------- |
| App 无法启动        | 检查 `snapcraft.yaml` 的 `command` 路径 |
| Data Layer 连接失败 | 确认 `ctrlx-datalayer` plug 已连接      |
| 权限拒绝            | 检查 Unix Socket 路径权限为 0600          |
