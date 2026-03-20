# Build Command Setup Detection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite the `/ctrlx-app-dev build` command routing in SKILL.md so it detects whether the dev-loop script is configured, guides first-time users through one-time setup, and then executes the loop — making the full build→upload→verify workflow reachable in a single command invocation.

**Architecture:** Single-file change to `SKILL.md`. Replace the two-line build routing stub with a three-branch decision tree: (1) first-time setup flow, (2) ready-to-run flow, (3) Docker-only fallback. No new files needed — the dev-loop scripts already exist in `templates/`.

**Tech Stack:** Markdown, bash/PowerShell (referenced, not written here)

---

## Task 1: Replace the `/ctrlx-app-dev build` routing in SKILL.md

**Files:**
- Modify: `SKILL.md` (lines 43–45, the `build` routing section)

**Step 1: Replace the existing build routing block**

Find and replace this block in `SKILL.md`:

```markdown
### `/ctrlx-app-dev build [--arch amd64|arm64]`
1. Read the "Fast Dev Loop" section in @05-build-deploy.md (preferred)
2. If dev-loop script is not set up, provide the Docker build command
```

Replace with:

```markdown
### `/ctrlx-app-dev build [--arch amd64|arm64]`

**Step 1: Detect dev-loop script**

Check whether `scripts/dev-loop.sh` (Linux/macOS/WSL) or `scripts/dev-loop.ps1` (Windows) exists in the project root.

**If neither exists → First-Time Setup Flow:**

Ask the user which shell they are using:
> "No dev-loop script found. Which environment are you running in?
> A. Linux / macOS / WSL (bash)
> B. Windows PowerShell"

Then guide them through the one-time setup:

```bash
# Option A — bash
cp <skill-path>/templates/dev-loop.sh scripts/dev-loop.sh
chmod +x scripts/dev-loop.sh

export CTRLX_HOST=<IP of your COREvirtual VM>
export CTRLX_USER=admin
export CTRLX_PASS=<your password>
```

```powershell
# Option B — PowerShell
Copy-Item <skill-path>\templates\dev-loop.ps1 scripts\dev-loop.ps1

$env:CTRLX_HOST = "<IP of your COREvirtual VM>"
$env:CTRLX_USER = "admin"
$env:CTRLX_PASS = "<your password>"
```

Then verify connectivity before proceeding:
> "Run the following to confirm your VM is reachable:
> `ping $CTRLX_HOST` (or `Test-Connection $env:CTRLX_HOST` on PowerShell)
>
> If it times out, check:
> - COREvirtual is running in ctrlX WORKS
> - Developer mode is enabled in ctrlX OS → Settings → App Management
> - Your host and VM are on the same network adapter (Host-Only or Bridged)"

Once connectivity is confirmed, continue to the run step below.

**If script exists → Ready-to-Run Flow:**

Check that the three required environment variables are set (`CTRLX_HOST`, `CTRLX_USER`, `CTRLX_PASS`). If any are missing, prompt for them before continuing.

Then run the appropriate script for the detected arch (default `amd64`):

```bash
# bash
./scripts/dev-loop.sh --arch amd64

# PowerShell
.\scripts\dev-loop.ps1 -Arch amd64
```

Expected output ends with:
```
✓ Dev loop complete in <N>s
  App '<snap-name>' is Running on <CTRLX_HOST>
```

If the script exits with an error, read the failure line and route to diagnostic mode (see Diagnostic Mode section).

**If Docker is not available → Fallback:**

If the user cannot run Docker (required by the dev-loop script for the build step), refer them to Strategy B in @05-build-deploy.md (App Build Environment).
```

**Step 2: Commit**

```bash
git add SKILL.md
git commit -m "feat: add first-time setup detection and guided flow to build command"
```

---

## Task 2: Push to GitHub

**Step 1: Verify**

```bash
git status
# Expected: nothing to commit, working tree clean

git log --oneline -3
# Expected: feat commit on top
```

**Step 2: Push**

```bash
git push origin main
```
