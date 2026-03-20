# Compliance Checklist

## Category 1 (Baseline Compliance — Required)

### File Integrity

- [ ] `snap/snapcraft.yaml` exists and passes syntax validation
- [ ] `build-info/package-manifest.json` exists and contains a `reverse_proxy` configuration
- [ ] `build-info/slotplug-description.json` describes all interfaces
- [ ] `docs/manual.md` includes installation, configuration, and troubleshooting sections
- [ ] `docs/test-setup.md` describes at least one test scenario
- [ ] `docs/release-notes.md` includes a version changelog

### Technical Specification

- [ ] ctrlx-datalayer Python binding >= 2.4 (or equivalent C++/C# version)
- [ ] snapcraft version >= 8.x (check: `snapcraft --version`)
- [ ] Snap name follows the `ctrlx-{company}-{app}` format
- [ ] Uses `core22` or `core24` as the base image
- [ ] `confinement: strict` is set
- [ ] No global slots declared
- [ ] Plugs limited to: `network`, `network-bind`, `home`, `ctrlx-datalayer`
- [ ] Unix Socket path is configured correctly (TCP ports avoided)

### Resource Limits

- [ ] RAM < 75 MB after app startup (verify with `top`)
- [ ] Snap package size < 100 MB (verify with `ls -lh *.snap`)
- [ ] CPU usage < 5% average load

## Category 2 (Advanced Features — If Used)

### License Integration (if licensing is enabled)

- [ ] `package-manifest.json` has `licensing.enabled = true`
- [ ] App calls the License Manager API on startup
- [ ] Displays a friendly error message when license is absent (no crash)

### Web UI (if provided)

- [ ] Exposed through the reverse proxy (not a direct port)
- [ ] Uses HTTPS/WSS communication
- [ ] Integrated into the ctrlX OS navigation bar

### Data Persistence

- [ ] Configuration files stored in `$SNAP_COMMON` (preserved across upgrades)
- [ ] Transient data stored in `$SNAP_DATA` (version-isolated)
- [ ] Avoid frequent writes to extend flash storage lifetime

## Category 3 (Enterprise — Optional)

- [ ] Supports Solution backup/restore
- [ ] Multi-language support (i18n)
- [ ] Detailed audit logging
- [ ] Exposes performance monitoring metrics

## Automated Checks

```bash
# Verify file structure
ls -la snap/snapcraft.yaml build-info/*.json docs/*.md

# Validate Snap syntax
snapcraft lint

# Check resource usage (run after installation)
ps aux | grep {app-name}          # Memory
du -sh /var/snap/{app-name}/      # Storage

# Verify interface connections
snap connections {app-name}
```

## Signing and Publishing

### Final Checks:
- [ ] Snap has been signed by Bosch Rexroth
- [ ] Version number follows Semantic Versioning (SemVer)
- [ ] Release notes include compatibility information

### Pre-submission Confirmation:
All Category 1 items must pass. Category 2 items are required only if the corresponding feature is used.
