#!/usr/bin/env bash
# ctrlX Dev Loop: Build → Upload → Verify
# Usage: ./scripts/dev-loop.sh [--arch amd64|arm64]
#
# Required env vars:
#   CTRLX_HOST   - IP or hostname of COREvirtual/device (e.g. 192.168.1.1)
#   CTRLX_USER   - Username (default: admin)
#   CTRLX_PASS   - Password

set -euo pipefail

ARCH="amd64"
CTRLX_USER="${CTRLX_USER:-admin}"
MAX_WAIT=120

while [[ $# -gt 0 ]]; do
    case $1 in
        --arch) ARCH="$2"; shift 2 ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

: "${CTRLX_HOST:?Set CTRLX_HOST (e.g. export CTRLX_HOST=192.168.1.1)}"
: "${CTRLX_PASS:?Set CTRLX_PASS}"

echo "▶ [1/5] Building snap for $ARCH..."
START_TIME=$(date +%s)

docker run --rm \
    -v "${PWD}:/build" -w /build \
    -e SNAPCRAFT_BUILD_ENVIRONMENT=host \
    ghcr.io/canonical/snapcraft:8_core22 \
    snapcraft --target-arch="$ARCH" 2>&1 | tail -20

SNAP_FILE=$(ls -t *.snap | head -1)
if [[ -z "$SNAP_FILE" ]]; then
    echo "✗ No .snap file found after build"; exit 1
fi
SNAP_NAME=$(echo "$SNAP_FILE" | sed 's/_[0-9].*//')
echo "  Built: $SNAP_FILE"

echo "▶ [2/5] Authenticating with $CTRLX_HOST..."
TOKEN=$(curl -sk -X POST \
    "https://${CTRLX_HOST}/identity-manager/api/v1/auth/token" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${CTRLX_USER}\",\"password\":\"${CTRLX_PASS}\"}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

if [[ -z "$TOKEN" ]]; then
    echo "✗ Authentication failed"; exit 1
fi
echo "  Token obtained"

echo "▶ [3/5] Uploading $SNAP_FILE..."
HTTP_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" \
    -X POST "https://${CTRLX_HOST}/package-manager/api/v1/packages" \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@${SNAP_FILE}")

if [[ "$HTTP_STATUS" != "200" && "$HTTP_STATUS" != "201" ]]; then
    echo "✗ Upload failed (HTTP $HTTP_STATUS)"; exit 1
fi
echo "  Uploaded (HTTP $HTTP_STATUS)"

echo "▶ [4/5] Waiting for installation (max ${MAX_WAIT}s)..."
ELAPSED=0
while [[ $ELAPSED -lt $MAX_WAIT ]]; do
    STATE=$(curl -sk \
        "https://${CTRLX_HOST}/package-manager/api/v1/packages/${SNAP_NAME}" \
        -H "Authorization: Bearer $TOKEN" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('state','unknown'))" 2>/dev/null)

    echo "  State: $STATE ($ELAPSED s)"
    if [[ "$STATE" == "Running" ]]; then break; fi
    if [[ "$STATE" == "Error" ]]; then echo "✗ App entered Error state"; exit 1; fi
    sleep 3; ELAPSED=$((ELAPSED + 3))
done

if [[ "$STATE" != "Running" ]]; then
    echo "✗ App not running after ${MAX_WAIT}s (last state: $STATE)"; exit 1
fi

echo "▶ [5/5] Fetching recent logs..."
curl -sk \
    "https://${CTRLX_HOST}/log/api/v1/entries?filter=${SNAP_NAME}&count=50" \
    -H "Authorization: Bearer $TOKEN" \
    | python3 -c "
import sys, json
entries = json.load(sys.stdin).get('entries', [])
for e in entries[-20:]:
    print(f\"  [{e.get('timestamp','')}] {e.get('message','')}\")
"

END_TIME=$(date +%s)
echo ""
echo "✓ Dev loop complete in $((END_TIME - START_TIME))s"
echo "  App '$SNAP_NAME' is Running on $CTRLX_HOST"
