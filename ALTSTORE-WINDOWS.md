# 无 Mac 安装：Windows + AltStore

这条路线保持当前的完整 iOS 行为：后台持续运行、熄屏暂停、60 秒内继续、超过 60 秒重置。

免费 Apple ID 的签名仍然只有 7 天有效期，但 AltStore 会在后台自动刷新。自动刷新时，Windows 电脑需要开机，并与 iPhone 连接同一个 Wi-Fi。

## 你需要准备

- Windows 10 或 Windows 11 电脑。
- 一个免费 GitHub 账号。
- 一个已开启双重认证的 Apple ID。
- iPhone 和 Windows 电脑处于同一个 Wi-Fi。
- iPhone 设置了锁屏密码；否则系统可能无法可靠发出“设备已锁定”的信号。

不要把 Apple ID 密码发给任何人。Apple ID 只由你本人在 Windows 的 AltServer 中输入。

## 第一步：把工程发布到 GitHub

1. 解压交付的 `EyeCare2020-iOS.zip`。
2. 在 GitHub 新建一个仓库，选择 `Public`。
3. 使用 GitHub Desktop 或 Git，把 `EyeCare2020` 文件夹里的全部内容上传到仓库根目录。
4. `.github`、`EyeCare2020.xcodeproj` 和所有 Swift 文件都必须上传，不能只上传一部分。

仓库必须是公开的，因为 iPhone 上的 AltStore 需要直接下载安装源和 IPA。

## 第二步：让 GitHub 自动构建

1. 打开 GitHub 仓库的 `Actions` 页面。
2. 在左侧选择 `Build unsigned AltStore IPA`。
3. 点击 `Run workflow`。
4. 等待约 5 到 15 分钟。构建会先运行测试，再执行 iOS Release 编译。
5. 成功后打开仓库右侧的 `Releases`，确认最新版本中包含：
   - `EyeCare2020.ipa`
   - `altstore.json`
   - `AppIcon-1024.png`

当前安装源地址为：

```text
https://github.com/R-ErBai/EyeCare2020/releases/latest/download/altstore.json
```

该地址会在每次重新构建后始终指向最新版本。

## 第三步：在 Windows 安装 AltServer

AltStore 官方要求从 Apple 官网安装完整版 iTunes 和 iCloud，不能使用 Microsoft Store 版本。

1. 安装 iTunes：<https://www.apple.com/itunes/download/win64>
2. 安装 iCloud：<https://updates.cdn-apple.com/2020/windows/001-39935-20200911-1A70AA56-F448-11EA-8CC0-99D41950005E/iCloudSetup.exe>
3. 下载 AltServer：<https://cdn.altstore.io/file/altstore/altinstaller.zip>
4. 解压并运行 `Setup.exe`。
5. 在 Windows 搜索栏中打开 `AltServer`，选择“以管理员身份运行”。
6. 如果 Windows 防火墙询问网络权限，请允许访问专用网络。
7. 打开 iTunes，登录你的 Apple ID。
8. 用数据线连接 iPhone，在 iTunes 中为设备开启“通过 Wi-Fi 同步”。

## 第四步：安装 AltStore

1. 打开 Windows 右下角的 AltServer 托盘图标。
2. 选择 `Install AltStore`，再选择你的 iPhone。
3. 按提示输入你自己的 Apple ID。
4. 安装完成后，在 iPhone 的“设置 → 通用 → VPN 与设备管理”中信任你的开发者证书。
5. 如果 iPhone 提示需要“开发者模式”，打开“设置 → 隐私与安全性 → 开发者模式”，开启后重启 iPhone。

如果 AltStore 本身过期，可以直接用 AltServer 再次安装 AltStore，不需要先删除旧版本。

## 第五步：添加安装源并安装远眺

1. 在 iPhone 上打开 AltStore。
2. 打开 `Sources` 或设置中的源管理页面。
3. 添加第二步得到的 `altstore.json` 地址。
4. 返回 Browse，打开“远眺”。
5. 点击 `FREE` 安装。
6. 首次打开后允许通知。

## 第六步：启用自动续签

1. AltStore 设置中开启 `Background Refresh`。
2. 确保 AltServer 随 Windows 启动并保持运行。
3. 让 iPhone 与 Windows 处于同一个 Wi-Fi，或通过 USB 连接。
4. 在 AltStore 的 `My Apps` 中可以查看每个 App 的签名到期时间。

正常情况下不需要每周手动重装。如果某次自动续签没有完成，让 iPhone 和 AltServer 回到同一 Wi-Fi，打开 AltStore 并点击 `Refresh All`。

## 安装后的真机检查

1. 点击“开始护眼”，确认通知权限已允许。
2. 等待约 1 分钟，切换到其他 App，再返回；计时应继续。
3. 熄屏 30 秒后解锁；剩余时间应接着熄屏前继续。
4. 熄屏 70 秒后解锁；界面应显示 20:00，并自动重新开始。
5. 熄屏期间不应出现远眺通知。
6. 点击“结束计时”后不再出现后续通知。

如果锁屏行为不生效，请先确认 iPhone 已设置锁屏密码，并检查 AltStore 后台刷新和通知权限。
