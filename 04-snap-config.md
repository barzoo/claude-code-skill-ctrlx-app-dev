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
