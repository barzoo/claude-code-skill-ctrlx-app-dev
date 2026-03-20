# ctrlX App Development Overview

> **Current baseline**: ctrlX OS 2.x | ctrlX SDK 2.4.x | snapcraft 8.x | Ubuntu Core 22/24

## What is a ctrlX App?

A ctrlX App is an industrial automation application packaged in Ubuntu Core Snap format, running on the Bosch Rexroth ctrlX CORE control platform.

## Technology Stack

| Language | Use Case | Performance | Dev Speed |
|----------|----------|-------------|-----------|
| **Python** | Data processing, algorithm prototyping | Medium | ⭐⭐⭐⭐⭐ (ctrlx-datalayer>=2.4) |
| **C++** | Real-time control, high performance | High | ⭐⭐⭐ |
| **.NET/C#** | Enterprise integration, HMI | Medium-High | ⭐⭐⭐⭐ |

## Architecture Principles

### 1. Security Model
- **Strict isolation**: Snap's strict confinement restricts filesystem access
- **Least privilege**: Declare only required plugs (network, network-bind, ctrlx-datalayer)
- **Secure communication**: Unix Socket preferred over TCP; all communication encrypted

### 2. Data Flow Architecture

```
[Physical Layer] → [ctrlX CORE Data Layer] → [Your App (Provider/Consumer)]
       ↑                      ↓
[Other Apps] ←────────────────┘
```

### 3. Lifecycle Management
- **Install**: Atomic Snap installation
- **Start**: Managed by systemd, supports automatic restart
- **Upgrade**: Transactional updates with automatic rollback on failure
- **Config**: Via Data Layer or environment variables

## Development Phases

1. **Phase 1: Scaffold** → Project structure, Snap configuration, base code
2. **Phase 2: Develop** → Data Layer nodes, business logic, Flatbuffers schemas
3. **Phase 3: Build** → Compile in Docker or App Build Environment (ABE)
4. **Phase 4: Test** → Local testing with COREvirtual
5. **Phase 5: Compliance** → Documentation, resource checks, security audit
6. **Phase 6: Publish** → Bosch Rexroth signing, store submission

## Key Design Decisions

### Why Unix Socket?
- ✅ Avoids port conflicts (ctrlX system already uses 80/443/4840, etc.)
- ✅ No firewall configuration required
- ✅ Complies with the Snap security model
- ✅ Web services can be exposed through the reverse proxy

### Data Layer vs REST API
- **Data Layer**: Real-time data, state synchronization, machine-to-machine communication (recommended)
- **REST API**: Configuration management, historical queries, third-party integration (optional)

## Resource Limits

| Metric | Limit | How to Check |
|--------|-------|--------------|
| RAM | < 75 MB | `top` or system monitor |
| Storage | < 100 MB | `du -sh $SNAP` |
| CPU | < 5% average | `htop` |
| Startup time | < 10 s | System logs |

## Further Reading

- Snap configuration details: @04-snap-config.md
- Build guide: @05-build-deploy.md
- Compliance checklist: @06-compliance.md
