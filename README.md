# auto_env

自动切换环境（hosts、环境变量）的 Flutter 桌面应用。

> 当前里程碑：M1 —— 环境配置管理（创建 / 编辑 / 删除 + 本地 JSON 持久化）。
> 实际切换执行（写 hosts、写环境变量）属于 M2 范围。

## 运行

```bash
flutter pub get
flutter run -d macos    # 或 -d windows
```

## 数据存储

所有环境配置以一个 JSON 数组形式存放在单个文件里，路径由 `path_provider` 的 `getApplicationSupportDirectory()` 决定：

| 平台 | profiles.json 路径 |
|---|---|
| macOS | `~/Library/Application Support/<bundle-id>/auto_env/profiles.json` |
| Windows | `%APPDATA%\<company>\<product>\auto_env\profiles.json` |
| Linux | `~/.local/share/<bundle-id>/auto_env/profiles.json` |

bundle-id / company / product 取决于各平台 Runner 的工程配置（macOS：`macos/Runner/Configs/AppInfo.xcconfig`；Windows：`windows/runner/Runner.rc`）。

写入采用 `tmp + rename` 原子策略；读取到非法 JSON 会抛出 `EnvProfileCorruptedException` 而不是静默吞掉，便于尽早发现损坏。

## 项目布局

```
lib/
├── core/
│   └── storage/app_paths.dart          # path_provider 封装
└── features/env_profile/
    ├── domain/entities/                # Freezed 模型：EnvProfile / HostsEntry
    ├── data/repositories/              # Repository 接口 + JSON 实现
    └── presentation/
        ├── providers/                  # Riverpod AsyncNotifier
        ├── pages/                      # List / Edit 两屏
        └── widgets/                    # 卡片 / hosts / env var 编辑器
```

## 验证

```bash
flutter analyze
flutter test
```

当前 M1 测试覆盖：domain 模型 / repository（含原子性 + 损坏 JSON）/ Riverpod CRUD / 列表页三态 + 删除确认 / 编辑页 new+edit 流程。
