# English Localization Design

**Date**: 2026-03-20
**Status**: Approved

---

## Goal

Translate the ctrlx-app-dev skill into English to enable international use, while keeping a Chinese README for Chinese-speaking users.

## Scope

### Files to translate (English replacement)
| File | Action |
|---|---|
| `SKILL.md` | Full translation to English |
| `01-overview.md` | Full translation |
| `02-project-scaffold.md` | Full translation (code comments already English) |
| `03-datalayer-dev.md` | Full translation |
| `04-snap-config.md` | Full translation |
| `05-build-deploy.md` | Full translation |
| `06-compliance.md` | Full translation |
| `README.md` | Rewrite as English primary file |

### Files to create
| File | Action |
|---|---|
| `README-cn.md` | Move current Chinese README content here, add language link |

### Files NOT touched
- `templates/` — code files, comments already English
- `docs/plans/` — historical records

## Translation Style

- Keep technical terms as-is: `Provider`, `Consumer`, `Snap`, `Data Layer`, `plug`, `slot`, `confinement`, `strict`
- Keep ctrlX proper nouns: `ctrlX CORE`, `COREvirtual`, `snapcraft`, `Flatbuffers`, `ctrlX OS`
- Tone: professional, concise, industrial automation documentation style
- Command-line examples unchanged

## README Structure

**README.md** (English, GitHub default):
```
[中文文档](README-cn.md) | English

# ctrlX App Development Skill
...full English content...
```

**README-cn.md** (Chinese):
```
[English](README.md) | 中文

# ctrlX App 开发 Skill
...full Chinese content (migrated from current README.md)...
```
