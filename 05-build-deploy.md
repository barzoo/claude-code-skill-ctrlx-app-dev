# Build and Deploy Guide

## Fast Dev Loop (Recommended for Daily Use)

> **One command does it all**: Build → Upload → Verify

### Initial Setup (One-Time)

```bash
# Linux/macOS/WSL
export CTRLX_HOST=192.168.1.1   # COREvirtual IP
export CTRLX_USER=admin
export CTRLX_PASS=your-password

cp templates/dev-loop.sh scripts/dev-loop.sh
chmod +x scripts/dev-loop.sh
```

```powershell
# Windows PowerShell
$env:CTRLX_HOST = "192.168.1.1"
$env:CTRLX_USER = "admin"
$env:CTRLX_PASS = "your-password"

Copy-Item templates\dev-loop.ps1 scripts\dev-loop.ps1
```

### Each Iteration

```bash
# Linux/WSL — build amd64 (for COREvirtual)
./scripts/dev-loop.sh --arch amd64

# Windows PowerShell
.\scripts\dev-loop.ps1 -Arch amd64

# ARM64 (for physical ctrlX CORE)
./scripts/dev-loop.sh --arch arm64
```

### Example Script Output

```
▶ [1/5] Building snap for amd64...
  Built: ctrlx-myco-myapp_1.0.0_amd64.snap
▶ [2/5] Authenticating with 192.168.1.1...
  Token obtained
▶ [3/5] Uploading ctrlx-myco-myapp_1.0.0_amd64.snap...
  Uploaded
▶ [4/5] Waiting for installation (max 120s)...
  State: Installing (0 s)
  State: Running (9 s)
▶ [5/5] Fetching recent logs...
  [2026-03-19T10:00:01] [ctrlx-myco-myapp] Registered: myco/myapp/sensor/value
  [2026-03-19T10:00:01] [ctrlx-myco-myapp] Running. Press Ctrl+C to stop.

✓ Dev loop complete in 47s
  App 'ctrlx-myco-myapp' is Running on 192.168.1.1
```

### ctrlX REST API Authentication

```bash
# Manually obtain a token (for debugging)
curl -sk -X POST \
  "https://${CTRLX_HOST}/identity-manager/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -d '{"name":"admin","password":"your-password"}'
# Returns: {"access_token": "eyJ...", "token_type": "Bearer"}
```

---

## Build Strategy Options

### Strategy A: Docker Build (Cross-Platform)

**When to use:**
- Development team uses Windows
- Rapid prototyping
- No Ubuntu VM required

**Prerequisites:**
- Docker Desktop running
- Project directory accessible

**Build commands:**

```bash
# x86_64 (for COREvirtual)
docker run --rm -v "${PWD}:/build" -w /build \
  -e SNAPCRAFT_BUILD_ENVIRONMENT=host \
  ghcr.io/canonical/snapcraft:8_core22 \
  snapcraft --target-arch=amd64

# ARM64 (for physical ctrlX CORE)
docker run --rm -v "${PWD}:/build" -w /build \
  -e SNAPCRAFT_BUILD_ENVIRONMENT=host \
  ghcr.io/canonical/snapcraft:8_core22 \
  snapcraft --target-arch=arm64
```

Output: `ctrlx-{company}-{app}_{version}_{arch}.snap` in the `snap/` directory

### Strategy B: App Build Environment (Official)

**When to use:**
- Production builds
- Native library linking required
- Follows official Bosch build process

Steps:
- Launch App Build Environment (QEMU VM) in ctrlX WORKS
- Wait for VM to boot (port 10022)
- SSH in:
```bash
ssh boschrexroth@localhost -p 10022
# Default password: boschrexroth
```
- Inside the VM:
```bash
sudo apt update
sudo apt install libctrlx-datalayer-dev -y
cd /path/to/project
snapcraft
```
- Copy output to host:
```bash
scp -P 10022 boschrexroth@localhost:~/project/*.snap .
```

## Deployment

### Local Testing (COREvirtual)

1. Upload Snap:
   - Open ctrlX OS web interface (https://localhost)
   - Settings → App Management → Install
   - Enable "Allow installation from unknown source"
   - Upload the .snap file
2. Verify operation:
   - Confirm app state shows "Running"
   - View logs: Diagnostics → Logbook
   - Verify Data Layer nodes: Data Layer → Browser
3. Functional testing:
   - Test node read/write with Postman or SDK client
   - Verify Flatbuffers serialization

### Production Deployment (Physical ctrlX CORE)

1. Signature verification:
   - Ensure the Snap has been signed by Bosch Rexroth
   - Unsigned Snaps can only be used in developer mode
2. Installation:
   - Upload via ctrlX OS interface
   - Or command line: `snap install ctrlx-{company}-{app}.snap --dangerous` (developer mode)
3. Configuration:
   - Set environment variables if needed
   - Configure license if enabled

## Troubleshooting

| Build Error | Fix |
|---|---|
| `snapcraft: command not found` | Run `sudo snap install snapcraft --classic` inside VM |
| `Failed to pull source` | Check network connection, or add `--use-lxd` flag |
| `Architecture mismatch` | Make sure to use `--target-arch=arm64` for physical devices |

| Deploy Error | Fix |
|---|---|
| App fails to start | Check the `command` path in `snapcraft.yaml` |
| Data Layer connection fails | Verify the `ctrlx-datalayer` plug is connected |
| Permission denied | Check that the Unix Socket path has 0600 permissions |
