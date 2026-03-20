# Project Scaffold Guide

## Directory Structure

All projects must strictly follow this structure:

```
{app-name}/
├── snap/
│   └── snapcraft.yaml          # Snap packaging definition (see @04-snap-config.md)
├── src/
│   ├── main.py                 # Application entry point (see templates/)
│   └── helper/                 # Helper modules
├── schema/
│   └── {app}.fbs               # Flatbuffers schema (if using Data Layer)
├── build-info/                 # Build metadata (required)
│   ├── package-manifest.json   # Reverse proxy and license configuration
│   ├── slotplug-description.json
│   ├── portlist-description.json   # Recommended: empty list
│   └── unixsocket-description.json
├── docs/                       # Documentation (required for compliance)
│   ├── manual.md               # User manual
│   ├── test-setup.md           # Test scenarios
│   └── release-notes.md        # Release changelog
└── scripts/
    └── dev-loop.[sh|ps1]       # Dev loop script (see @05-build-deploy.md)
```

## Initialization Steps

### Step 1: Create Directories

```bash
mkdir -p {app-name}/{snap,src,schema,build-info,docs,scripts}
```

### Step 2: Select Templates

Copy the templates for your language:

**Python project:**
- Entry point: @templates/provider-template.py → src/main.py
- Snap config: @templates/snapcraft-python.yaml → snap/snapcraft.yaml

**C++ project:**
- Entry point: @templates/provider-template-cpp.cpp → src/main.cpp
- Build file: @templates/CMakeLists.txt → CMakeLists.txt
- Snap config: @templates/snapcraft-cpp.yaml → snap/snapcraft.yaml

C++ dependency installation (inside App Build Environment):
```bash
# Add Bosch APT repository
curl -s https://nexus.boschrexroth.com/repository/apt-hosted/gpg.key | sudo apt-key add -
echo "deb https://nexus.boschrexroth.com/repository/apt-hosted focal main" \
  | sudo tee /etc/apt/sources.list.d/bosch.list
sudo apt update
sudo apt install libctrlx-datalayer-dev libflatbuffers-dev flatbuffers-compiler -y
```

**.NET project:**
- Entry point: @templates/provider-template-csharp.cs → src/Program.cs
- Snap config: @templates/snapcraft-csharp.yaml → snap/snapcraft.yaml
- Also create: `{app}.csproj` (see template below)

.NET csproj template:
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <RuntimeIdentifier>linux-x64</RuntimeIdentifier>
    <SelfContained>true</SelfContained>
    <AssemblyName>ctrlx-{company}-{app}</AssemblyName>
  </PropertyGroup>
  <ItemGroup>
    <!-- Bosch NuGet feed: https://nexus.boschrexroth.com/repository/nuget-hosted/ -->
    <PackageReference Include="Datalayer" Version="2.4.*" />
    <PackageReference Include="Google.FlatBuffers" Version="24.*" />
  </ItemGroup>
</Project>
```

NuGet.Config (place in project root):
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <add key="bosch-nexus"
         value="https://nexus.boschrexroth.com/repository/nuget-hosted/" />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
</configuration>
```

### Step 3: Fill in Metadata

Edit the placeholders in:
- `snap/snapcraft.yaml`: Replace `{app-name}`, `{company}`, and version number
- `build-info/package-manifest.json`: Update socket path and license config
- `docs/manual.md`: Describe application functionality and installation steps

## Post-Initialization Steps

After creating the directories, guide the user through:

Validate Snap configuration:
```bash
cd {app-name}
snapcraft lint  # Check syntax
```

Install dependencies (local development):
```bash
pip install ctrlx-datalayer flatbuffers  # Python
```

## First Build Test

Refer to the "Fast Dev Loop" section in @05-build-deploy.md.

## Common Mistakes to Avoid

❌ Forgetting to create the `build-info/` directory → reverse proxy will not work
❌ Using TCP ports instead of Unix Sockets → will fail compliance review
❌ Skipping the `docs/` directory → compliance check will not pass
✅ Always fill in all placeholders using the templates as the reference
