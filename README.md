# auto_env

一个用于一键切换"开发 / 测试 / 预发 / 生产"等多套环境的桌面工具：把 **hosts 映射** 和 **系统环境变量** 打包成可复用的"环境配置（Profile）"，点一下即可应用到本机。

基于 Flutter Desktop 构建，目前覆盖 **macOS** 与 **Windows**。

---

## 一、它解决什么问题

平时切换环境通常意味着：

- 手动 `sudo vim /etc/hosts`，加几行、注释几行，再 `dscacheutil -flushcache`；
- 跑去"系统设置 → 环境变量"或者 `launchctl setenv` 一项一项改 `API_BASE`、`GRPC_ENDPOINT` 之类；
- 切回去时再来一遍，经常漏改、改错、忘了改回去。

auto_env 把这些动作收进一个 GUI：

- **集中存储**：每套环境是一个 Profile，包含 hosts 条目与 K/V 形态的环境变量；
- **一键应用**：单次特权认证（macOS Touch ID / Windows UAC）即可写入 hosts 和系统环境变量，并刷新 DNS；
- **可回滚**：每次切换前自动快照"上一次状态"，切错了能一键还原；
- **不破坏现有 hosts**：用 `# >>> auto_env managed >>>` 标记块只动自己的部分，Docker Desktop、Lens 等工具往同一份 hosts 文件里写的内容会被字节级保留；
- **一次授权、持续生效**（macOS）：通过 Authorization Services 在进程内缓存授权引用，同一次会话内多次切换只弹一次 Touch ID。

---

## 二、如何使用

### 下载与安装

到 [Releases](../../releases/latest) 下载对应平台的产物：

- **macOS**：`auto_env-x.y.z-macos.dmg`
  双击挂载，拖 `auto_env.app` 到 Applications 即可。已 Developer ID 签名 + 公证，首次打开不会被 Gatekeeper 拦截。
- **Windows**：`auto_env-x.y.z-windows-x64.zip`
  解压到任意目录，双击 `auto_env.exe` 启动。**首次启动会被 SmartScreen 拦一下**（"Windows protected your PC"），点 **更多信息 → 仍要运行** 即可——这是因为目前还没有 Windows 代码签名证书，不是病毒。
  Windows 版是绿色包：所有数据都在 `%APPDATA%\top.linkee\auto_env\`，删除解压目录即可"卸载"（要彻底清干净顺手把 `%APPDATA%` 下那个目录也删掉）。

> Linux 暂未提供下载——hosts/env writers 尚未在 Linux 上实现，发了也用不了。详见 [Roadmap](#四roadmap)。

### 从源码运行（开发者）

- Flutter SDK ≥ 3.11.5（`dart sdk: ^3.11.5`）
- macOS（建议 14+）或 Windows 10/11
- 第一次拉代码后生成 freezed / json 代码：

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

然后：

```bash
flutter run -d macos      # macOS
flutter run -d windows    # Windows
```

发版流程见 [docs/RELEASE.md](docs/RELEASE.md)。

### 典型流程

1. 在列表页点 **新建**，填写 Profile 名称；
2. 在编辑页加入 hosts 条目（IP / 域名 / 是否启用）和环境变量（KEY / VALUE）；
3. 回到列表页，点对应 Profile 的 **应用**：
   - macOS：首次会弹 Touch ID / 管理员密码，之后同一进程不再弹；
   - Windows：会弹一次 UAC 给 sidecar `helper.exe` 提权写 hosts。
4. 切换完成后顶部出现 **Post-switch banner**，可选择 **回滚** 到上一次状态。

### macOS 用户的一次性 shell 配置

GUI 应用（Finder/Spotlight 启动的）通过 `launchctl setenv` 立刻可见；但 **已经开着的 shell 不会自动继承**。在你的 `~/.zshrc` / `~/.bashrc` 中加一行：

```bash
[ -f ~/.config/auto_env/env.sh ] && source ~/.config/auto_env/env.sh
```

之后新开的 shell 会读取最新值。

### 数据与状态存储位置

| 类型 | 路径（macOS） | 路径（Windows） |
|---|---|---|
| Profile 列表 | `~/Library/Application Support/<bundle-id>/auto_env/profiles.json` | `%APPDATA%\<company>\<product>\auto_env\profiles.json` |
| 当前激活快照 | 同目录下 `active_profile.json` | 同上 |
| 上次切换状态（用于回滚） | 同目录下 `last_switch_state.json` | 同上 |
| macOS shell 兼容文件 | `~/.config/auto_env/env.sh` | —— |

写入统一采用 **tmp + rename** 原子策略；读到非法 JSON 会抛 `EnvProfileCorruptedException`，不会静默吞掉。

---

## 三、平台支持

| 平台 | 状态 | 特权机制 | hosts 路径 | 环境变量机制 |
|---|---|---|---|---|
| **macOS** | ✅ 已支持 | `AuthorizationExecuteWithPrivileges`（Touch ID / 密码，会话内缓存）；fallback 为 `osascript` | `/etc/hosts` | `launchctl setenv` + 重写 `~/.config/auto_env/env.sh` |
| **Windows** | ✅ 已支持 | sidecar `helper.exe`（manifest 声明 `requireAdministrator`，触发 UAC） | `C:\Windows\System32\drivers\etc\hosts` | 直接写 `HKCU\Environment` 注册表 + 一次带超时的 `WM_SETTINGCHANGE` 广播 |
| **Linux** | ⏳ 仅有 Flutter desktop 脚手架，未实现 hosts / env 写入 | —— | —— | —— |

> Windows 选择直接写注册表而非 `[Environment]::SetEnvironmentVariable(..., 'User')`，是因为后者每次内部都会同步广播 `WM_SETTINGCHANGE`（.NET 默认 5s 超时），多个 Key 累加常会拖到 10s 以上；直接写注册表 + 一次 `SMTO_ABORTIFHUNG` / 1000ms 广播，可以把整次切换压到 2s 内。

---

## 四、Roadmap

当前已完成的里程碑：

- **M1** — Profile CRUD + 本地 JSON 持久化（Repository + Riverpod + 列表/编辑页）
- **M2** — 切换执行（hosts 管理块 / env vars 双平台写入 / 进度对话框 / 回滚）
- **M2.5** — Raycast 风格暗色主题与设计 token 统一；macOS Touch ID 单进程缓存
- **工程基建** — GitHub Actions 自动构建发版：macOS 签名 + 公证 `.dmg`、Windows 绿色 `.zip`，push `v*.*.*` tag 即触发（[流程](docs/RELEASE.md)）

接下来的方向（按优先级排序，欢迎反馈）：

- **M3 — 体验打磨**
  - 菜单栏 / 托盘常驻，命令面板风格的快速切换
  - 全局快捷键
  - 切换历史 & 多步回滚
- **M4 — 数据流通**
  - Profile 导入 / 导出（JSON / YAML），便于团队共享
  - Profile 模板与变量片段引用
- **M5 — Linux 支持**
  - `/etc/hosts` 写入：`pkexec` / Polkit
  - 环境变量：写入 `~/.config/environment.d/auto_env.conf`（systemd-user）+ shell rc 片段
- **M6 — 进阶能力（设想中）**
  - DNS 后缀 / 代理设置（PAC、系统 Proxy）打包进 Profile
  - 与 `kubectl context`、`aws profile`、`gcloud config` 等外部 CLI context 联动
  - 自动检测网络环境并提示切换

---

## 五、系统设计

### 架构总览

整体采用 **Feature-based Clean Architecture**，分三层：

```
Presentation (Flutter Widgets + Riverpod Notifier)
        │
        ▼
Domain    (Freezed 实体 + 纯函数 + 抽象接口)
        │
        ▼
Data      (Repository / Writer 实现 + 平台调用)
        │
        ▼
Platform  (macOS Swift Bridge / Windows helper.exe / dart:io)
```

两个核心 Feature：

| Feature | 职责 |
|---|---|
| `env_profile` | Profile 的 CRUD 与持久化（M1 范围） |
| `env_switch`  | 把指定 Profile 应用到系统，并维护"激活快照 / 上次切换状态"（M2 范围） |

### 关键设计决策

1. **hosts 文件的 Managed Block**
   - 用 `# >>> auto_env managed >>>` / `# <<< auto_env managed <<<` 包裹我们写入的行；
   - `HostsManagedBlock.split / mergeIntoHosts` 是纯函数，保证标记块之外的字节完全不动；
   - 同时检测原文件的换行风格（LF / CRLF）以避免污染。

2. **Writer 抽象 + 平台实现**
   - `HostsWriter` / `EnvVarWriter` 是接口；
   - `MacosHostsWriter` 通过 MethodChannel 调用 `PrivilegedShell.swift`（Authorization Services）；
   - `WindowsHostsWriter` 通过 `Process.run` 启动同源构建的 sidecar `helper.exe`；
   - `MacosEnvVarWriter` 走 `launchctl setenv` + `env.sh`；`WindowsEnvVarWriter` 走 PowerShell 直接写 `HKCU\Environment` + 单次广播。

3. **提权策略可插拔**
   - `ElevationStrategy` 接口：`MacosPrivilegedShellStrategy`（首选）+ `OsascriptStrategy`（兜底）；
   - 当 Authorization Services 因 macOS 升级失效时，可以零代码切换到 osascript。

4. **切换前先落盘 LastSwitchState**
   - `EnvSwitchNotifier.activate` 在动系统之前，先把"当前 active Profile / 当前 managed block / 当前 env vars"写到磁盘；
   - 即使切换过程中崩溃或断电，也能从 `last_switch_state.json` 手动 / 一键回滚。

5. **进度与错误**
   - `SwitchProgress` 枚举阶段：`requestingPrivilege → writingHosts → writingEnvVars → flushingDns → done`，UI 通过 `SwitchProgressDialog` 展示；
   - 异常被分类为 `PrivilegeDeniedException` / `HostsWriteFailedException` / `EnvVarWriteFailedException` 等具名类型，UI 据此区分文案与是否允许 Retry。

6. **原子写与串行化**
   - `AtomicFileWriter`：`writeAsString → tmp → rename`，避免半写文件；
   - `SerialQueue`：把对同一份 JSON 的并发写串成单队列，防止 race。

### 目录结构

```
lib/
├── core/
│   ├── async/          # SerialQueue
│   ├── process/        # ProcessRunner + ElevationStrategy 系列
│   ├── storage/        # AppPaths + AtomicFileWriter
│   └── ui/             # 设计 token：颜色 / 间距 / 圆角 / 字体 / 动效
├── features/
│   ├── env_profile/    # M1：Profile CRUD
│   │   ├── domain/     # EnvProfile / HostsEntry (Freezed)
│   │   ├── data/       # EnvProfileJsonRepository
│   │   └── presentation/  # 列表页 / 编辑页 / 卡片 / 编辑器
│   └── env_switch/     # M2：执行切换
│       ├── domain/     # HostsManagedBlock / SwitchProgress / SwitchResult / 异常
│       ├── data/
│       │   ├── repositories/  # ActiveProfile / LastSwitchState
│       │   └── writers/       # macOS / Windows × hosts / env
│       └── presentation/      # EnvSwitchNotifier + 进度对话框 + 回滚 banner
└── main.dart

macos/Runner/PrivilegedShell.swift   # Authorization Services 桥接
windows_helper/                       # Windows 提权 sidecar helper.exe 源码
```

### 依赖

- 状态管理：`flutter_riverpod`
- 不可变模型：`freezed_annotation` + `json_annotation`
- 平台路径：`path_provider`
- ID：`uuid`
- 测试：`flutter_test` + `mocktail`

---

## 六、验证

```bash
flutter analyze
flutter test
```

测试覆盖（粗略）：

- `core/`：原子写、串行队列、提权策略
- `env_profile`：Repository（含原子性 + 损坏 JSON）、Riverpod CRUD、列表/编辑页交互
- `env_switch`：HostsManagedBlock 纯函数、各平台 writer、Repository、Notifier 状态机、列表页"应用"流程

---

## License

暂未声明。仓库当前为个人 / 内部使用阶段，后续公开时会补充。
