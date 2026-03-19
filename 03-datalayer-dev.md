# Data Layer 开发指南

## 架构模式

ctrlX Data Layer 采用 **发布-订阅** 模式，支持两种角色：

### Provider（数据提供者）
提供实时数据，如传感器读数、状态信息。

### Consumer（数据消费者）
订阅数据变更，或批量读取历史数据。

## 实现步骤

### 1. Schema 设计（Flatbuffers）

创建 `schema/{app}.fbs`:

```flatbuffers
namespace {company}.{app};

table SensorReading {
  timestamp: ulong;      // Unix 时间戳 (ms)
  value: double;          // 传感器值
  unit: string;           // 单位 (e.g., "celsius")
  quality: int;           // 数据质量 (0=good, 1=uncertain, 2=bad)
}

root_type SensorReading;
```

编译命令:
```bash
# Python
flatc --python -o src/ schema/{app}.fbs

# C++
flatc --cpp -o src/ schema/{app}.fbs
```

### 2. Provider 实现
连接与注册:
```Python
from ctrlx_datalayer.provider import Provider
from ctrlx_datalayer.provider_node import ProviderNode
from helper.ctrlx_datalayer_helper import get_datalayer_system, get_client

# 初始化系统
datalayer_system = get_datalayer_system()
datalayer_system.start(False)

# 通过 Unix Socket 连接
connection = get_client(datalayer_system, "ipc://")

# 创建 Provider
provider = Provider(connection)
provider.start()

# 注册节点
node = ProviderNode(
    self.on_read,
    self.on_write,
    self.on_create,
    self.on_remove
)
provider.register_node("path/to/node", node)
```

回调实现:
```Python
def on_read(self, data: Variant, detail: dict) -> Variant:
    """处理读取请求"""
    # 构建 Flatbuffers 数据
    builder = flatbuffers.Builder(1024)
    # ... 填充数据 ...
    builder.Finish(builder.StartObject())
    
    result = Variant()
    result.set_flatbuffers(builder.Output())
    return result

def on_write(self, data: Variant, detail: dict) -> int:
    """处理写入请求"""
    try:
        # 解析 Flatbuffers
        buf = data.get_flatbuffers()
        # 更新内部状态
        return 0  # 成功
    except Exception as e:
        return 1  # 失败

```

### 3. Consumer 实现
订阅模式（推荐用于实时监控）:
```Python
from ctrlx_datalayer.subscription import Subscription
from ctrlx_datalayer.subscription_properties import SubscriptionProperties

# 创建订阅
props = SubscriptionProperties()
props.publish_interval = 100  # 100ms 间隔

subscription = Subscription(connection)
subscription.create(props)

# 添加节点
subscription.add_item("path/to/node", self.on_update)

def on_update(self, data: Variant, info: dict):
    """数据更新回调"""
    if data.get_type() == VariantType.FLATBUFFERS:
        buf = data.get_flatbuffers()
        # 反序列化
```

### 批量读取（适合配置读取）:
```Python
paths = ["node1", "node2", "node3"]
result, responses = connection.read_sync(paths)
for resp in responses:
    if resp.error == 0:
        value = resp.data.get_float64()
```

### 性能优化
- 批量操作: 优先使用批量读取而非循环单读
- 订阅间隔: 根据数据变化频率设置（传感器 100ms，状态 1000ms）
- 连接复用: 全局维护一个 Connection 实例，避免重复连接


### 故障排除

| 症状    | 原因               | 解决                  |
| ----- | ---------------- | ------------------- |
| 节点不可见 | Provider 未启动     | 检查 systemd 状态       |
| 读取超时  | Flatbuffers 格式错误 | 验证 schema 版本        |
| 订阅无回调 | 路径错误             | 使用 Data Layer 浏览器验证 |
