[中文文档](README-cn.md) | English

# ctrlX App Development Skill

> A [Claude Code](https://claude.ai/code) skill for building Bosch Rexroth ctrlX CORE industrial applications
> Baseline: **ctrlX OS 2.x | ctrlX SDK 2.4.x | snapcraft 8.x**

## What is this?

A Claude Code skill that guides you through the full lifecycle of ctrlX CORE app development — from project scaffolding to publishing — following Bosch Rexroth standards.

**Key features:**
- **Smart phase detection**: Automatically identifies your current development phase and provides proactive guidance
- **Diagnostic mode**: Describe your problem in plain language and get targeted, step-by-step resolution
- **Three-language support**: Complete, symmetric templates for Python, C++, and .NET
- **One-command dev loop**: Build → Upload → Verify in a single script (~30–60 seconds)

## Installation

```bash
# Global install (available in all projects)
git clone https://github.com/barzoo/claude-code-skill-ctrlx-app-dev \
  ~/.claude/skills/ctrlx-app-dev
```

```bash
# Project-level install (current project only)
git clone https://github.com/barzoo/claude-code-skill-ctrlx-app-dev \
  .claude/skills/ctrlx-app-dev
```

## 5-Minute Quickstart

### 1. Create a project

```
/ctrlx-app-dev init my-sensor-app --lang python
```

Supported languages: `python` | `cpp` | `csharp`

### 2. Implement a Data Layer node

```
/ctrlx-app-dev datalayer add-node
```

Describe what you need, for example:
```
Add a temperature sensor node that samples data every second, range 0–100 °C
```

### 3. Build and deploy to COREvirtual in one command

```bash
# One-time setup
export CTRLX_HOST=192.168.1.1
export CTRLX_USER=admin
export CTRLX_PASS=your-password
cp templates/dev-loop.sh scripts/dev-loop.sh && chmod +x scripts/dev-loop.sh
```

```
/ctrlx-app-dev build --arch amd64
```

The script handles everything: build snap → upload to device → wait for install → fetch logs. Typically completes in 30–60 seconds.

### 4. Run compliance checks (required before publishing)

```
/ctrlx-app-dev compliance
```

### 5. Diagnose issues

```
/ctrlx-app-dev diagnose
```

Or simply describe the problem in plain text. The skill will ask two diagnostic questions, then provide targeted resolution steps.

## Command Reference

| Command | Description |
|---------|-------------|
| `init [name] --lang python\|cpp\|csharp` | Scaffold a new project |
| `datalayer add-node\|provider\|consumer` | Data Layer development |
| `build [--arch amd64\|arm64]` | Build and deploy |
| `compliance` | Run compliance checklist |
| `diagnose` | Enter diagnostic mode |
| `overview` | Architecture overview |

## File Structure

```
ctrlx-app-dev/
├── SKILL.md                    # Entry point (phase detection, routing, diagnostics)
├── 01-overview.md              # Architecture overview and tech stack
├── 02-project-scaffold.md      # Project initialization (Python / C++ / .NET)
├── 03-datalayer-dev.md         # Data Layer development guide (SDK 2.4.x, 3 languages)
├── 04-snap-config.md           # Snap packaging configuration
├── 05-build-deploy.md          # Build and deploy (includes fast dev loop)
├── 06-compliance.md            # Compliance checklist
└── templates/
    ├── provider-template.py        # Python Provider template (SDK 2.4.x)
    ├── provider-template-cpp.cpp   # C++ Provider template
    ├── provider-template-csharp.cs # C# Provider template
    ├── snapcraft-python.yaml       # Python Snap config template
    ├── snapcraft-cpp.yaml          # C++ Snap config template
    ├── snapcraft-csharp.yaml       # C# Snap config template
    ├── CMakeLists.txt              # C++ build file template
    ├── package-manifest.json       # Reverse proxy + license config
    ├── dev-loop.sh                 # Dev loop script (Linux/WSL)
    └── dev-loop.ps1                # Dev loop script (Windows PowerShell)
```

## References

- [ctrlX Automation SDK Documentation](https://boschrexroth.github.io/ctrlx-automation-sdk/)
- [snapcraft 8.x Documentation](https://snapcraft.io/docs)
- [Flatbuffers Documentation](https://google.github.io/flatbuffers/)
