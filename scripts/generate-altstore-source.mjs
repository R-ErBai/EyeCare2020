import { mkdirSync, statSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";

const repository = process.env.GITHUB_REPOSITORY;
const ipaPath = process.env.IPA_PATH;
const outputPath = process.argv[2] ?? "dist/altstore.json";
const buildDate = process.env.BUILD_DATE ?? new Date().toISOString();

if (!repository || !/^[^/]+\/[^/]+$/.test(repository)) {
  throw new Error("GITHUB_REPOSITORY must use the owner/repository format.");
}

if (!ipaPath) {
  throw new Error("IPA_PATH is required.");
}

const ipaSize = statSync(resolve(ipaPath)).size;
const assetBase = `https://github.com/${repository}/releases/latest/download`;
const iconURL = `${assetBase}/AppIcon-1024.png`;
const downloadURL = `${assetBase}/EyeCare2020.ipa`;

const source = {
  name: "远眺个人源",
  subtitle: "20·20·20 护眼计时器",
  description:
    "个人使用的 20-20-20 护眼计时器。通过 AltStore 免费账号签名并自动续签。",
  iconURL,
  headerURL: iconURL,
  website: `https://github.com/${repository}`,
  tintColor: "#9FE5BD",
  nsfw: false,
  featuredApps: ["com.personal.EyeCare2020"],
  apps: [
    {
      name: "远眺",
      bundleIdentifier: "com.personal.EyeCare2020",
      developerName: "个人项目",
      subtitle: "每 20 分钟看向远处 20 秒",
      localizedDescription:
        "持续运行 20 分钟用眼循环，到点可选择休息 20 秒或 1 分钟。熄屏时暂停，熄屏超过 1 分钟后重新开始。这是个人侧载版本，通过静音后台音频维持准确计时。",
      iconURL,
      tintColor: "#9FE5BD",
      category: "utilities",
      versions: [
        {
          version: "1.2",
          buildVersion: "3",
          date: buildDate,
          localizedDescription: "新增休息结束提示音选择、锁屏实时活动和灵动岛倒计时。",
          downloadURL,
          size: ipaSize,
          minOSVersion: "17.0",
        },
      ],
      appPermissions: {
        entitlements: [],
        privacy: {},
      },
    },
  ],
  news: [],
};

mkdirSync(dirname(resolve(outputPath)), { recursive: true });
writeFileSync(resolve(outputPath), `${JSON.stringify(source, null, 2)}\n`, "utf8");
console.log(`Generated ${outputPath} (${ipaSize} byte IPA)`);
