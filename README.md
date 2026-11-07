# 远眺 20·20·20

一个个人自用的 iPhone 护眼计时器。它每 20 分钟提醒你休息，并让你选择看向约 6 米外 20 秒或休息 1 分钟；休息结束时还会提醒一次。屏幕熄灭时暂停，熄屏不超过 1 分钟会接着计时，超过 1 分钟则自动重置为新的 20 分钟。

## 推荐：无 Mac 安装

如果你没有 Mac，使用 Windows + GitHub Actions + AltStore Classic：

1. 把工程发布到一个公开的 GitHub 仓库。
2. 手动运行 `Build unsigned AltStore IPA` 工作流。
3. 在 Windows 安装 iTunes、iCloud 和 AltServer。
4. 把生成的最新 `altstore.json` 地址添加到 AltStore。

完整步骤见 [ALTSTORE-WINDOWS.md](ALTSTORE-WINDOWS.md)。

免费 Apple ID 签名仍然只有 7 天有效期，但 AltStore 会自动续签，不需要每周手动重装。自动续签时，Windows 电脑需要开机并与 iPhone 处于同一 Wi-Fi。

当前安装源：

```text
https://github.com/R-ErBai/EyeCare2020/releases/latest/download/altstore.json
```

## 重要说明

这个版本为了准确处理锁屏，使用静音音频维持后台运行。因此：

- 只适合个人侧载，不适合提交 App Store。
- 运行时会比普通计时器多耗一点电。
- 锁屏媒体区域可能出现播放状态。
- 只有点击“结束计时”或强制退出 App，循环才会停止。
- iPhone 需要设置锁屏密码，否则系统可能无法可靠发出“设备已锁定”的信号。
- 强制退出会终止循环，但已经排好的下一次提醒仍可能显示一次；要完全停止，请先点击“结束计时”。

## 可选：使用 Mac 安装

如果以后能使用 Mac，可以直接用 Xcode 15 或更高版本安装；仍然需要一个 Apple ID 和运行 iOS 17 或更高版本的 iPhone。

1. 在 Mac 上双击 `EyeCare2020.xcodeproj`。
2. 打开左侧的 `EyeCare2020` 工程，在 `Signing & Capabilities` 中选择你的 Team。
3. 如果提示 Bundle Identifier 冲突，把 `com.personal.EyeCare2020` 改成你自己的唯一标识。
4. 确认 `Background Modes` 中的 `Audio, AirPlay, and Picture in Picture` 已勾选。
5. 用数据线连接 iPhone，选择你的 iPhone 作为运行设备，然后点击 Run。
6. 首次安装后，在 iPhone 的“设置 → 隐私与安全性 → 开发者模式”中开启开发者模式并重启手机。
7. 首次点击“开始护眼”时允许通知。

如果在 App 里没看到通知，请检查“设置 → 通知 → 远眺”，打开“允许通知”。到点会自动开始 20 秒休息：App 在前台时可以点“改为 1 分钟”，切到其他 App 时也可展开系统通知直接改为 1 分钟，无需打开 App。休息结束时可选择并试听四种提示音。

首页右上角可设置每轮用眼时长，范围为 1～120 分钟，默认 20 分钟。计时过程中修改时，新时长从下一轮开始生效。运行时还会在锁屏实时活动和灵动岛中显示当前阶段和倒计时。

## 验证核心行为

模拟器适合检查界面，但锁屏判断必须用真机测试：

1. 开始计时，等待约 1 分钟，切到其他 App；计时应在返回后保持正确。
2. 熄屏 30 秒后解锁，剩余时间应保持熄屏前的进度。
3. 熄屏 70 秒后解锁，界面应显示 20:00，并自动开始新的一轮。
4. 熄屏期间不应收到远眺提醒。
5. 点击“结束计时”后，不应再出现后续通知。
6. 到点应立即开始 20 秒休息，并在 5 秒内允许改为 1 分钟。
7. 选择 1 分钟时，应在 1 分钟后收到休息结束通知。
8. 锁屏和灵动岛应显示当前阶段；熄屏后应切换为暂停状态。

## 开发测试

状态机可以在没有 Xcode 的 Swift 环境中单独测试：

```bash
swift test
```

在 Mac 上，可以直接双击 `verify-on-mac.command`；如果系统不让双击运行，在终端执行：

```bash
zsh verify-on-mac.command
```

该脚本会检查资源、运行状态机测试，再自动选择一个可用的 iPhone 模拟器完成编译与测试。项目也附带了 GitHub Actions 配置，推送到 GitHub 后可在云端 macOS 环境自动执行同样的检查。

`Build unsigned AltStore IPA` 工作流会生成可供 AltStore 使用的未签名 IPA、应用图标和 `altstore.json` 安装源。

重新生成图标和静音音频：

```bash
node scripts/generate-assets.mjs
```

## 隐私

App 不联网、不收集数据、不使用账号，也不保存用眼记录。
