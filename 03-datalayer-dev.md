# Data Layer Development Guide

> **SDK baseline**: ctrlx-datalayer >= 2.4 (Python) | comm.datalayer >= 2.4 (C++) | Datalayer >= 2.4 (.NET)

## Architecture

ctrlX Data Layer uses a **publish-subscribe** pattern with two roles:

- **Provider**: Registers nodes and responds to read/write requests
- **Consumer**: Subscribes to node changes or performs bulk reads

---

## 1. Schema Design (Flatbuffers)

Create `schema/{app}.fbs`:

```flatbuffers
namespace {company}.{app};

table SensorReading {
  timestamp: ulong;   // Unix timestamp (ms)
  value:     double;  // Sensor value
  unit:      string;  // Unit (e.g., "celsius")
  quality:   int;     // 0=good, 1=uncertain, 2=bad
}

root_type SensorReading;
```

Compile:
```bash
flatc --python -o src/  schema/{app}.fbs   # Python
flatc --cpp    -o src/  schema/{app}.fbs   # C++
flatc --csharp -o src/  schema/{app}.fbs   # C#
```

---

## 2. Provider Implementation

### Python

```python
# SDK 2.4.x — full initialization sequence
from ctrlx_datalayer import system as dl_system
from ctrlx_datalayer.provider_node import ProviderNode, NodeCallback
from ctrlx_datalayer.variant import Variant
from ctrlx_datalayer.helper import get_datalayer_system_url

system = dl_system.System("")
system.start(False)

provider = system.factory().create_provider(get_datalayer_system_url())
provider.start()

def on_read(path: str, output: Variant) -> int:
    output.set_float64(42.0)
    return 0

def on_write(path: str, input: Variant) -> int:
    print(f"Written: {input.get_float64()}")
    return 0

node = ProviderNode(NodeCallback(on_read=on_read, on_write=on_write))
provider.register_node("{company}/{app}/sensor/value", node)
```

Full example (with graceful shutdown): see @templates/provider-template.py

### C++

```cpp
#include "comm/datalayer/datalayer_system.h"
using namespace comm::datalayer;

DatalayerSystem system("");
system.start(false);

auto provider = system.factory()->createProvider("ipc://");
provider->start();

class SensorNode : public IProviderNode {
public:
    void onRead(const std::string&, IProviderNodeResult* r) override {
        Variant v; v.setValue(42.0);
        r->setItem(v); r->finish(DlResult::DL_OK);
    }
    void onWrite(const std::string&, const Variant& data,
                 IProviderNodeResult* r) override {
        // process data.getValue<double>()
        r->finish(DlResult::DL_OK);
    }
    void onMetadata(const std::string&, IProviderNodeResult* r) override {
        r->finish(DlResult::DL_OK);
    }
};

auto node = std::make_shared<SensorNode>();
provider->registerNode("{company}/{app}/sensor/value", node.get());
```

Full example (with RAII shutdown): see @templates/provider-template-cpp.cpp

### C#

```csharp
using Datalayer;
using var system = new DatalayerSystem();
system.Start(isSingleNodeApp: false);

using var provider = system.Factory.CreateProvider("ipc://");
provider.Start();

class SensorNode : IProviderNode {
    public DlResult OnRead(string addr, out IVariant output) {
        output = new Variant(42.0); return DlResult.DL_OK;
    }
    public DlResult OnWrite(string addr, IVariant input, out IVariant output) {
        output = Variant.Empty; return DlResult.DL_OK;
    }
    public DlResult OnMetadata(string addr, out IVariant output) {
        output = Variant.Empty; return DlResult.DL_OK;
    }
}

provider.RegisterNode("{company}/{app}/sensor/value", new SensorNode());
```

Full example (with async/await shutdown): see @templates/provider-template-csharp.cs

---

## 3. Consumer Implementation

### Subscription (real-time monitoring)

**Python**
```python
from ctrlx_datalayer.subscription import SubscriptionProperties

client = system.factory().create_client(get_datalayer_system_url())
props = SubscriptionProperties(publish_interval=100)  # 100ms
sub = client.create_subscription(props)

def on_update(items):
    for item in items:
        if item.error == 0:
            print(f"{item.address} = {item.data.get_float64()}")

sub.subscribe(["{company}/{app}/sensor/value",
               "{company}/{app}/sensor/status"], on_update)
```

**C++**
```cpp
auto client = system.factory()->createClient("ipc://");

SubscriptionProperties props;
props.setPublishInterval(100);
auto sub = client->createSubscription(props,
    [](const std::vector<NotifyItem>& items) {
        for (auto& item : items) {
            if (item.result == DlResult::DL_OK)
                std::cout << item.address << " = "
                          << item.data.getValue<double>() << "\n";
        }
    });

sub->subscribe({"{company}/{app}/sensor/value"});
```

**C#**
```csharp
using var client = system.Factory.CreateClient("ipc://");
var props = new SubscriptionProperties { PublishIntervalMs = 100 };
using var sub = client.CreateSubscription(props, items => {
    foreach (var item in items)
        if (item.Error == DlResult.DL_OK)
            Console.WriteLine($"{item.Address} = {item.Data.ToDouble()}");
});
sub.Subscribe(new[] { "{company}/{app}/sensor/value" });
```

### Bulk Read (for configuration)

**Python**
```python
paths = ["{company}/{app}/cfg/interval",
         "{company}/{app}/cfg/threshold"]
results = client.read_sync(paths)
for r in results:
    if r.error == 0:
        print(f"{r.address} = {r.data.get_float64()}")
```

---

## 4. Error Recovery (Auto-Reconnect)

**Python**
```python
import time

def connect_with_retry(system, max_retries=10, delay=2.0):
    for attempt in range(max_retries):
        provider = system.factory().create_provider(get_datalayer_system_url())
        if provider and provider.start() == 0:
            return provider
        print(f"[provider] Retry {attempt+1}/{max_retries} in {delay}s...")
        time.sleep(delay)
    raise RuntimeError("Failed to connect after retries")
```

---

## 5. Graceful Shutdown Sequence

Correct shutdown sequence (must be followed strictly to avoid orphaned Data Layer nodes):

```
1. Stop business logic loop (set _running = False)
2. unregister_node() / unregisterNode() — unregister each node
3. provider.stop() / provider->stop()
4. system.stop() / system.stop()
```

---

## 6. Performance Best Practices

| Scenario | Recommendation |
|---|---|
| Sensor real-time data | Use 100 ms subscription interval |
| Status monitoring | Use 1000 ms subscription interval |
| Configuration reads | Use bulk read, not per-item loop |
| Connection reuse | Maintain a single global Provider/Client instance |
| Write frequency | Avoid writes faster than 10 Hz to extend flash lifetime |

---

## 7. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Provider creation returns None | IPC socket not ready | Retry connection; verify the ctrlx-datalayer plug is connected |
| Node registration fails | Path already registered | Check existing nodes in Data Layer Browser |
| Read timeout | Flatbuffers schema version mismatch | Recompile .fbs; ensure client and server use the same schema |
| Subscription receives no callbacks | Incorrect node path | Verify node path in Data Layer Browser |
| Graceful shutdown hangs | unregister_node not called | Follow the correct shutdown sequence (see section 5) |
