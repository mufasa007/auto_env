# 发版指南

本文档面向维护者，介绍如何把 auto_env 发布到 GitHub Releases。终端用户安装方式请看 [README](../README.md#二如何使用)。

## 当前状态

- ✅ **Windows** 发版流水线已上线。不需要任何 secret，push tag 即可出包。
- ⏸️ **macOS** 发版流水线已写好但**默认禁用**——等 Developer ID Application 证书就位后再启用。完整 job 定义保留在 git 历史 commit `6c90248`。

## 一、Windows 发版

```bash
# 本地确保 main 干净
git checkout main
git pull github main

# 打 tag（不带 +build 号，CI 用 GitHub run number 当 build 号）
git tag v0.1.0
git push github v0.1.0
```

> **注意 remote**：本仓库同时托管在 GitHub 和 Gitee。Actions 只在 GitHub 跑，所以 tag 必须 push 到 `github` remote。

push 完到 https://github.com/mufasa007/auto_env/actions 看进度。两个 job 串行：

1. `build-windows`（约 3–5 分钟，跑在 `windows-2022` runner 上）
2. `release`（秒级，组装 GitHub Release）

成功后 Release 自动出现在 https://github.com/mufasa007/auto_env/releases ，包含：

- `auto_env-<version>-windows-x64.zip` —— 未签名绿色包

### Pre-release / RC

tag 名包含 `-`（例如 `v0.1.0-rc1`、`v0.1.0-beta.1`）时，workflow 会把对应 Release 标记为 pre-release。

## 二、启用 macOS 发版（未来）

需要先做完下列前置工作：

### 1. 拿 Developer ID Application 证书

`security find-identity -v -p codesigning` 里**必须**能看到一行形如：

```
"Developer ID Application: Your Name (TEAMID)"
```

如果只有 `Apple Development: ...` 那是不行的——前者用于 App Store 外分发，后者只能本机调试。证书申请路径：

1. 登 https://developer.apple.com/account/resources/certificates/add
2. 类型选 **Developer ID** → **Developer ID Application**
3. 跟向导用 Keychain 生成 CSR 上传
4. 下载 `.cer` 双击装进 Keychain（注意会装到"登录" keychain）

### 2. 在 GitHub 仓库配置 7 个 secret

仓库 **Settings → Secrets and variables → Actions → New repository secret**：

| Secret 名 | 含义 | 怎么拿 |
|---|---|---|
| `MACOS_CERT_P12_BASE64` | Developer ID Application 证书（`.p12`）的 base64 | 见下方"导出证书" |
| `MACOS_CERT_PASSWORD` | 导出 `.p12` 时设置的密码 | 自己定 |
| `MACOS_KEYCHAIN_PASSWORD` | CI 临时 keychain 的密码 | 任意随机字符串 |
| `MACOS_SIGNING_IDENTITY` | 完整的签名身份字符串 | `security find-identity -v -p codesigning`，复制形如 `Developer ID Application: Your Name (TEAMID)` 的整行 |
| `MACOS_TEAM_ID` | Apple Developer Team ID，10 位 | https://developer.apple.com/account → Membership |
| `MACOS_NOTARY_APPLE_ID` | 用于公证的 Apple ID 邮箱 | 通常就是 Developer 账号邮箱 |
| `MACOS_NOTARY_PASSWORD` | App-Specific Password | https://appleid.apple.com → 登入并管理 → App 专用密码 → 生成 |

#### 导出证书

```bash
# 在已装好 Developer ID 证书的 mac 上：
# 1) Keychain Access → 登录 keychain → 我的证书 →
#    右键 "Developer ID Application: ..." → 导出 → 存为 cert.p12（设密码）
# 2) 转 base64：
base64 -i cert.p12 | pbcopy
# 3) 粘到 MACOS_CERT_P12_BASE64
# 4) 删除本地 p12：rm cert.p12
```

### 3. 恢复 workflow 里的 macOS job

```bash
git show 6c90248:.github/workflows/release.yml > .github/workflows/release.yml
```

然后把 release job 的 `needs:` 加回 `build-macos`，artifact glob 加回 `auto_env-*-macos.dmg`。提交后下一个 tag 就会触发双平台构建。

## 三、常见问题

### Windows 用户反馈 SmartScreen 拦截

预期行为。未签名 exe 第一次跑都会被拦，README 已有"更多信息 → 仍要运行"的说明。如果想根治，需要购买 Windows 代码签名证书（OV 约 $200/年，EV 约 $400/年），改 `release.yml` 加 `signtool sign` 步骤。

### 想改 Flutter 版本

`release.yml` 里 `subosito/flutter-action@v2` 默认 `channel: stable`，会在 CI 时拉最新稳定版。如需锁定版本（强烈推荐做完一次发版后改成固定版本以保证可复现），把 `channel: stable` 改成 `flutter-version: 3.x.y`。

### 不发版只验证 workflow

把 `on.push.tags` 临时改成 `on.workflow_dispatch`，提交后到 Actions 页手动触发；验证完改回来。或者直接打个 `v0.0.0-test1` 这种 pre-release tag 走完整流程，事后删除 Release 和 tag。

### macOS 公证失败排错（启用之后）

```bash
xcrun notarytool history \
  --apple-id "$MACOS_NOTARY_APPLE_ID" \
  --password "$MACOS_NOTARY_PASSWORD" \
  --team-id "$MACOS_TEAM_ID"

xcrun notarytool log <submission-id> \
  --apple-id "$MACOS_NOTARY_APPLE_ID" \
  --password "$MACOS_NOTARY_PASSWORD" \
  --team-id "$MACOS_TEAM_ID"
```

常见原因：
- **缺少 Hardened Runtime**：`codesign --options runtime` 没生效。
- **entitlements 缺项**：日志里会指出具体缺哪个 key，按需补到 `macos/Runner/Release.entitlements`。
- **证书过期**：Developer ID Application 证书 5 年期，到期需重新生成 + 重新导出 `.p12` + 更新 `MACOS_CERT_P12_BASE64`。

## 四、不在本流水线里的事

- **不跑测试**：发版 workflow 不跑 `flutter test` / `flutter analyze`，假定主干已经通过 PR 的 CI 校验。后续如果新增 `ci.yml` 的话，应该在那里跑测试。
- **不更新 `pubspec.yaml` 版本号**：tag 驱动版本，pubspec 的 `version: 1.0.0+1` 仅作开发默认值。
- **不发 Linux 包**：Linux 上 hosts/env writers 尚未实现，发了也没用。
