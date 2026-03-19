# 合规性检查清单

## Category 1（基础合规 - 必须）

### 文件完整性检查

- [ ] `snap/snapcraft.yaml` 存在且语法正确
- [ ] `build-info/package-manifest.json` 存在且包含 reverse_proxy 配置
- [ ] `build-info/slotplug-description.json` 描述所有接口
- [ ] `docs/manual.md` 包含安装、配置、故障排除章节
- [ ] `docs/test-setup.md` 描述至少一个测试场景
- [ ] `docs/release-notes.md` 包含版本变更日志

### 技术规范检查

- [ ] Snap 名称符合 `ctrlx-{company}-{app}` 格式
- [ ] 使用 `core22` 或 `core24` 基础镜像
- [ ] `confinement: strict` 已设置
- [ ] 无全局 slots 声明
- [ ] Plugs 仅限: network, network-bind, home, ctrlx-datalayer
- [ ] Unix Socket 路径配置正确（非 TCP 端口优先）

### 资源限制验证

- [ ] 应用启动后 RAM < 75MB（使用 `top` 验证）
- [ ] Snap 包大小 < 100MB（使用 `ls -lh *.snap` 验证）
- [ ] CPU 占用 < 5% 平均负载

## Category 2（高级功能 - 如使用）

### 许可证集成（如启用 licensing）

- [ ] `package-manifest.json` 中 licensing.enabled = true
- [ ] 应用启动时调用 License Manager API
- [ ] 无许可证时显示友好错误提示（非崩溃）

### Web UI（如提供）

- [ ] 通过反向代理暴露（非直接端口）
- [ ] 使用 HTTPS/WSS 通信
- [ ] 集成 ctrlX OS 导航栏

### 数据持久化

- [ ] 配置文件存储于 `$SNAP_COMMON`（跨版本保留）
- [ ] 临时数据存储于 `$SNAP_DATA`（版本隔离）
- [ ] 避免频繁写入（延长闪存寿命）

## Category 3（企业级 - 可选）

- [ ] 支持 Solution 备份/恢复
- [ ] 多语言支持（i18n）
- [ ] 详细审计日志
- [ ] 性能监控指标暴露

## 自动化检查脚本

提供以下检查命令：

```bash
# 检查文件结构
ls -la snap/snapcraft.yaml build-info/*.json docs/*.md

# 验证 Snap 语法
snapcraft lint

# 检查资源占用（安装后运行）
ps aux | grep {app-name}  # 查看内存
du -sh /var/snap/{app-name}/  # 查看存储

# 验证接口连接
snap connections {app-name}
```

## 签名与发布

### 最终检查:
- [ ] 已通过 Bosch Rexroth 官方签名
- [ ] 版本号符合语义化版本（SemVer）
- [ ] 发布说明包含兼容性信息

### 提交前确认:
所有 Category 1 项必须通过，Category 2 根据功能需求选择。