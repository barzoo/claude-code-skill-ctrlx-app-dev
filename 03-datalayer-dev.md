# Data Layer 开发指南

> **SDK 基准**: ctrlx-datalayer >= 2.4 (Python) | comm.datalayer >= 2.4 (C++) | Datalayer >= 2.4 (.NET)

## 架构模式

ctrlX Data Layer 采用**发布-订阅**模式，支持两种角色：

- **Provider**（数据提供者）：注册节点，响应读/写请求
- **Consumer**（数据消费者）：订阅节点变更或批量读取

---

## 1. Schema 设计（Flatbuffers）

创建 `schema/{app}.fbs`：

```flatbuffers
namespace {company}.{app};

table SensorReading {
  timestamp: ulong;   // Unix 时间戳 (ms)
  value:     double;  // 传感器值
  unit:      string;  // 单位 (e.g., "celsius")
  quality:   int;     // 0=good, 1=uncertain, 2=bad
}

root_type SensorReading;
```

编译：
```bash
flatc --python -o src/  schema/{app}.fbs   # Python
flatc --cpp    -o src/  schema/{app}.fbs   # C++
flatc --csharp -o src/  schema/{app}.fbs   # C#
```

---

## 2. Provider 实现

### Python

```python
# SDK 2.4.x — 完整初始化序列
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

完整示例（含优雅关闭）参见 @templates/provider-template.py

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

完整示例（含 RAII 关闭）参见 @templates/provider-template-cpp.cpp

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

完整示例（含 async/await 关闭）参见 @templates/provider-template-csharp.cs

---

## 3. Consumer 实现

### 订阅（实时监控）

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

### 批量读取（配置读取）

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

## 4. 错误恢复（自动重连）

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

## 5. 优雅关闭顺序

正确关闭顺序（必须严格遵守，否则可能导致 Data Layer 节点残留）：

```
1. 停止业务逻辑循环（设置 _running = False）
2. unregister_node() / unregisterNode() — 逐个注销节点
3. provider.stop() / provider->stop()
4. system.stop() / system.stop()
```

---

## 6. 性能最佳实践

| 场景 | 建议 |
|---|---|
| 传感器实时数据 | 订阅间隔 100ms |
| 状态监控 | 订阅间隔 1000ms |
| 配置读取 | 批量读取，非循环单读 |
| 连接复用 | 全局维护单个 Provider/Client 实例 |
| 写入频率 | 避免 >10Hz 写入，延长闪存寿命 |

---

## 7. 故障排除

| 症状 | 原因 | 解决 |
|---|---|---|
| Provider 创建返回 None | IPC Socket 未就绪 | 重试连接，检查 ctrlx-datalayer plug 是否已连接 |
| 节点注册失败 | 路径已被占用 | 使用 Data Layer Browser 检查现有节点 |
| 读取超时 | Flatbuffers schema 版本不匹配 | 重新编译 .fbs，确保客户端和服务端使用同一 schema |
| 订阅无回调 | 路径拼写错误 | 在 Data Layer Browser 中验证节点路径 |
| 优雅关闭卡住 | 未调用 unregister_node | 确保关闭顺序正确（见第5节） |
