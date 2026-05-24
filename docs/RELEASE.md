# 发版指南

本文档面向维护者，介绍如何把 auto_env 发布到 GitHub Releases。终端用户安装方式请看 [README](../README.md#二如何使用)。

## 一、首次准备（只做一次）

整个流水线由 `.github/workflows/release.yml` 驱动，需要在 GitHub 仓库的 **Settings → Secrets and variables → Actions** 配置以下 secret。Windows 走 zip 绿色包，不需要任何 secret；下列全部 secret 都是给 macOS 签名 + 公证用的。

| Secret 名 | 含义 | 怎么拿 |
|---|---|---|
| `MACOS_CERT_P12_BASE64` | Developer ID Application 证书（`.p12`）的 base64 | 见下方"导出证书" |
| `MACOS_CERT_PASSWORD` | 导出 `.p12` 时设置的密码 | 自己定 |
| `MACOS_KEYCHAIN_PASSWORD` | CI 临时 keychain 的密码 | 任意随机字符串 |
| `MACOS_SIGNING_IDENTITY` | 完整的签名身份字符串 | `security find-identity -v -p codesigning`，复制形如 `Developer ID Application: Your Name (TEAMID)` 的整行 |
| `MACOS_TEAM_ID` | Apple Developer Team ID，10 位 | https://developer.apple.com/account → Membership |
| `MACOS_NOTARY_APPLE_ID` | 用于公证的 Apple ID 邮箱 | 通常就是 Developer 账号邮箱 |
| `MACOS_NOTARY_PASSWORD` | App-Specific Password | https://appleid.apple.com → 登入并管理 → App 专用密码 → 生成 |

### 导出 Developer ID 证书

在已经能本地签名的 mac 上：

1. 打开 **Keychain Access**，左上角选 **登录** keychain，分类选 **我的证书**。
2. 找到 `Developer ID Application: Your Name (TEAMID)`，展开后右键 **导出**，存为 `cert.p12`，设一个密码（这个密码记到 `MACOS_CERT_PASSWORD`）。
3. 转 base64 并复制：
   ```bash
   base64 -i cert.p12 | pbcopy
   ```
4. 在 GitHub secret 里把它粘到 `MACOS_CERT_P12_BASE64`。
5. 导出完成后建议把 `cert.p12` 安全删除（`rm cert.p12`）。

## 二、发版

```bash
# 本地确保 main 干净
git checkout main
git pull

# 打 tag。版本号别带 +build 号，CI 会自动用 GitHub run number 当 build 号。
git tag v0.1.0
git push origin v0.1.0
```

push 后到 **Actions** 标签页看进度。三个 job：

1. `build-macos`（约 6–10 分钟，公证耗时不可控）
2. `build-windows`（约 3–5 分钟）
3. `release`（秒级，组装 GitHub Release）

全部成功后，Release 会自动出现在 https://github.com/<owner>/auto_env/releases ，包含：

- `auto_env-<version>-macos.dmg` —— 已签名 + 公证 + staple
- `auto_env-<version>-windows-x64.zip` —— 未签名绿色包

### Pre-release / RC

tag 名包含 `-`（例如 `v0.1.0-rc1`、`v0.1.0-beta.1`）时，workflow 会把对应 Release 标记为 pre-release。

## 三、常见问题

### 公证失败

公证失败时 workflow 会在 notarize 步骤抛错，但 `notarytool submit --wait` 不会自动打印详细日志。在本地手工跑：

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
- **缺少 Hardened Runtime**：`codesign --options runtime` 没生效。检查 `release.yml` 里的 codesign 步骤是否被改过。
- **entitlements 缺项**：日志里会指出具体缺哪个 key，按需补到 `macos/Runner/Release.entitlements`。
- **证书过期**：Developer ID Application 证书 5 年期，到期需要在 https://developer.apple.com/account/resources/certificates 重新生成，重新导出 `.p12` 并更新 `MACOS_CERT_P12_BASE64`。

### Windows 用户反馈 SmartScreen 拦截

预期行为。未签名 exe 第一次跑都会被拦，README 已有"更多信息 → 仍要运行"的说明。如果想根治，需要购买 Windows 代码签名证书（OV 约 $200/年，EV 约 $400/年），改 `release.yml` 加 `signtool sign` 步骤。

### 想改 Flutter 版本

`release.yml` 里两个 `subosito/flutter-action@v2` 默认 `channel: stable`，会在 CI 时拉最新稳定版。如需锁定版本（强烈推荐做完一次发版后改成固定版本以保证可复现），把 `channel: stable` 改成 `flutter-version: 3.x.y`。

### 不发版只验证 workflow

把 `on.push.tags` 临时改成 `on.workflow_dispatch`，提交后到 Actions 页手动触发；验证完改回来。或者直接打个 `v0.0.0-test1` 这种 pre-release tag 走完整流程，事后删除 Release 和 tag。

## 四、不在本流水线里的事

- **不跑测试**：发版 workflow 不跑 `flutter test` / `flutter analyze`，假定主干已经通过 PR 的 CI 校验。后续如果新增 `ci.yml` 的话，应该在那里跑测试。
- **不更新 `pubspec.yaml` 版本号**：tag 驱动版本，pubspec 的 `version: 1.0.0+1` 仅作开发默认值。
- **不发 Linux 包**：Linux 上 hosts/env writers 尚未实现，发了也没用。
