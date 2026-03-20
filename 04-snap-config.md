# Snap 打包配置详解

## snapcraft.yaml 结构

### Python 模板（已参数化）

```yaml
name: ctrlx-{company}-{app}
version: '{version}'
summary: {app} - ctrlX Data Layer Application
description: |
  {description}
  Provides real-time data via ctrlX Data Layer.
base: core22  # 或 core24
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
      - libzmq5  # Data Layer 依赖
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

### C++ 模板关键差异
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
    command: usr/local/bin/{app}  # CMake install 目标
```

## build-info 配置

#### package-manifest.json（关键）
```JSON
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
  "ports": [],  // 推荐为空，使用 Unix Socket
  "licensing": {
    "enabled": {true|false},
    "check_interval": 30,
    "url": "/.licensing/api/v1/capabilities/ctrlx-{company}-{app}"
  }
}
```

### slotplug-description.json
```JSON
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

## 关键配置解释

### Content Interface（ctrlx-datalayer）

这是与 ctrlX 系统通信的 唯一授权方式：
- content: 标识符，固定为 ctrlx-datalayer
- target: 挂载点，应用内通过 $SNAP_DATA/.datalayer 访问
- 自动挂载: 系统启动时自动映射 Data Layer Unix Socket

### 反向代理配置

通过 package-manifest.json 的 reverse_proxy：
- url: Web UI 访问路径，自动集成到 ctrlX OS 导航
- unix_socket: 应用监听地址，Nginx 反向代理至此
- websocket: 支持实时 WebSocket 通信

### 安全加固
- 禁用全局 slots: 不声明 system-observe 等敏感接口
- 文件权限: Snap 自动限制文件系统访问（仅 $SNAP_DATA 可写）
- 网络隔离: 通过 Unix Socket 替代 TCP，避免外部网络暴露