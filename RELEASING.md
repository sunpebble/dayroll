# 发布流程

## 工作方式

1. 日常提交用 **Conventional Commits**（`feat: …` / `fix: …` / `chore: …`）推到 `main`
2. release-please 自动维护一个 Release PR（版本号 + CHANGELOG，`feat` 升 minor、`fix` 升 patch）
3. **合并 Release PR** → 自动打 tag、建 GitHub Release → 触发 TestFlight job：archive → 签名 → 上传
4. 版本号唯一来源是 `project.yml` 的 `MARKETING_VERSION`（release-please 通过 `x-release-please-version` 注释自动改写）；build 号 = GitHub run number

## 仓库 Secrets（Settings → Secrets → Actions）

| Secret | 内容 | 获取方式 |
|---|---|---|
| `APPLE_TEAM_ID` | 10 位 Team ID | developer.apple.com → Membership |
| `ASC_KEY_ID` | API Key ID | App Store Connect → 用户和访问 → 集成 → App Store Connect API，创建 **App Manager** 权限的 Team Key |
| `ASC_ISSUER_ID` | Issuer ID | 同上页面顶部 |
| `ASC_API_KEY_P8` | `.p8` 文件全文（含 BEGIN/END 行） | 创建 Key 时下载，只能下载一次 |
| `DIST_CERT_P12` | Apple Distribution 证书 + 私钥的 p12，base64 | 钥匙串导出 .p12 后 `base64 -i cert.p12 | pbcopy` |
| `DIST_CERT_PASSWORD` | p12 导出密码 | 导出时自设 |

## 一次性准备（上传能成功的前提）

- [ ] Apple Developer Program 付费账号
- [ ] App Store Connect 创建 App，bundle id `com.sunpebble.dayroll`
- [ ] developer.apple.com 注册 App Group `group.com.sunpebble.dayroll` 并关联两个 bundle id（`-allowProvisioningUpdates` 通常可自动完成，失败则手动）
- [ ] ASC 内购：创建非消耗型商品 `com.sunpebble.dayroll.lifetime`（$1.99）
- [ ] 本机生成 Apple Distribution 证书并导出 p12

## 注意

- 私有仓库的 macOS runner 按 10 倍分钟计费，流水线只在合并 Release PR 时跑一次 archive+upload，不跑测试（测试在本地/PR 阶段完成）
- 上传成功后在 App Store Connect → TestFlight 里勾出口合规（Info.plist 已声明 `ITSAppUsesNonExemptEncryption=false`，通常自动通过）
