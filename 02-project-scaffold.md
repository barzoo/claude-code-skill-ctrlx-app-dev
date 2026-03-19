# 项目初始化指南

## 目录结构规范

创建项目时必须严格遵循以下结构：
```
{app-name}/
├── snap/
│   └── snapcraft.yaml          # Snap 打包定义（见 @04-snap-config.md）
├── src/
│   ├── main.py                 # 应用入口（模板见 templates/）
│   └── helper/                 # 辅助模块
├── schema/
│   └── {app}.fbs               # Flatbuffers schema（如使用 Data Layer）
├── build-info/                 # 构建元数据（必需）
│   ├── package-manifest.json   # 反向代理、许可证配置
│   ├── slotplug-description.json
│   ├── portlist-description.json   # 推荐为空列表
│   └── unixsocket-description.json
├── docs/                       # 文档（必需，用于合规）
│   ├── manual.md               # 用户手册模板
│   ├── test-setup.md           # 测试场景
│   └── release-notes.md        # 发布说明
└── scripts/
└── build-snap.[sh|ps1]     # 构建脚本（见 @05-build-deploy.md）
```

## 初始化流程

### Step 1: 创建目录
```bash
mkdir -p {app-name}/{snap,src,schema,build-info,docs,scripts}
```

### Step 2: 选择模板
根据语言复制对应模板：

Python 项目:
- 主文件: @templates/provider-template.py → src/main.py
- 配置: @templates/snapcraft-python.yaml → snap/snapcraft.yaml

C++ 项目:
- 配置: @templates/snapcraft-cpp.yaml → snap/snapcraft.yaml
- 额外创建: CMakeLists.txt

## Step 3: 填充元数据
编辑以下文件的占位符：
- snap/snapcraft.yaml: 修改 {app-name}, {company}, 版本号
- build-info/package-manifest.json: 更新 socket 路径、许可证配置
- docs/manual.md: 填写应用功能、安装步骤

## 初始化后步骤
完成目录创建后，指导用户：

验证 Snap 配置:
```bash
cd {app-name}
snapcraft lint  # 检查语法
```

安装依赖（本地开发）:
```bash
pip install ctrlx-datalayer flatbuffers  # Python
```

## 首次构建测试:
参考 @05-build-deploy.md 的 "快速构建测试" 章节

## 常见错误预防
❌ 错误: 忘记创建 build-info/ 目录 → 导致反向代理失效
❌ 错误: 使用 TCP 端口而非 Unix Socket → 审核失败
❌ 错误: 忽略 docs/ 目录 → 合规性检查不通过
✅ 正确: 严格按照模板填写所有占位符