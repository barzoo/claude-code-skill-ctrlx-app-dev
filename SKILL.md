---
name: ctrlx-app-dev
description: Modular ctrlX App development assistant (SDK 2.4.x). Supports project initialization, Data Layer implementation, Snap packaging, build/deploy, and compliance checks. Includes smart phase detection and diagnostic mode.
argument-hint: [init|datalayer|snap|build|compliance|overview|diagnose]
---

# ctrlX App Development Assistant

## On Startup: Auto-Detect Project Phase

**Each time the skill is invoked, scan the current directory, determine the development phase, and provide proactive guidance:**

```
Detection logic (priority order):
1. No snap/ directory              → Phase: Uninitialized → Prompt to run init
2. Has snap/ but missing build-info/ → Phase: Config missing → Warn and provide fix steps
3. Has snap/ but no *.snap files   → Phase: In development  → Ask what user is working on
4. Has *.snap files                → Phase: Ready to deploy → Guide through dev loop
```

Example response (Phase 1):
> "No snap/ directory found. This project has not been initialized yet.
> Run the following command to get started: `/ctrlx-app-dev init my-app --lang python`"

---

## Command Routing

### `/ctrlx-app-dev init [name] --lang [python|cpp|csharp]`
1. Read the directory structure spec from @02-project-scaffold.md
2. Select templates based on language:
   - Python: @templates/snapcraft-python.yaml + @templates/provider-template.py
   - C++: @templates/snapcraft-cpp.yaml + @templates/provider-template-cpp.cpp + @templates/CMakeLists.txt
   - C#: @templates/snapcraft-csharp.yaml + @templates/provider-template-csharp.cs
3. Copy @templates/package-manifest.json to build-info/
4. Guide user through "Post-initialization steps" in @02-project-scaffold.md

### `/ctrlx-app-dev datalayer [add-node|provider|consumer]`
1. Consult @03-datalayer-dev.md (SDK 2.4.x)
2. Select the code section matching the user's language (Python/C++/C#)
3. For Flatbuffers usage, refer to the Schema Design section in chapter 1

### `/ctrlx-app-dev build [--arch amd64|arm64]`
1. Read the "Fast Dev Loop" section in @05-build-deploy.md (preferred)
2. If dev-loop script is not set up, provide the Docker build command

### `/ctrlx-app-dev compliance`
1. Load the Category 1/2/3 checklists from @06-compliance.md
2. Scan current project files and verify each item
3. Output compliance report (pass/fail/missing)

### `/ctrlx-app-dev diagnose`
Trigger diagnostic mode (see below)

---

## Diagnostic Mode

When the user describes a problem (rather than entering a command), **ask 2 diagnostic questions before providing an answer**:

**Question 1: Confirm the symptom**
> "Which situation are you experiencing?
> A. Node is not visible in Data Layer Browser
> B. Node is visible but read returns an error code
> C. Data format error (Flatbuffers deserialization failed)
> D. Build or packaging failure"

**Question 2: Confirm the environment**
> "Which environment are you running in?
> A. COREvirtual (local virtual machine)
> B. Physical ctrlX CORE device
> C. Local development environment (not inside a snap)"

After receiving answers, provide targeted steps for that symptom + environment combination. Reference @03-datalayer-dev.md section 7 or the troubleshooting table in @05-build-deploy.md.

---

## Core Constraints (Enforced)

- **SDK version**: ctrlx-datalayer >= 2.4 (Python) | comm.datalayer >= 2.4 (C++) | Datalayer >= 2.4 (.NET)
- **Naming convention**: `ctrlx-{company}-{app}_{version}_{arch}.snap`
- **Base image**: `core22` or `core24`, strict confinement
- **Communication**: Unix Socket (IPC), not TCP ports
- **Resource limits**: RAM < 75 MB, Snap < 100 MB
- **Required files**: package-manifest.json, manual.md, test-setup.md, release-notes.md
