import { existsSync, readFileSync, readdirSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";

const root = join(import.meta.dirname, "..");
const checks = [];

function check(name, condition, detail = "") {
  checks.push({ name, condition, detail });
  if (!condition) {
    throw new Error(`${name}${detail ? `: ${detail}` : ""}`);
  }
}

function read(relativePath) {
  return readFileSync(join(root, relativePath), "utf8");
}

function parseJSON(relativePath) {
  const content = read(relativePath);
  JSON.parse(content);
  return content;
}

function tokenizeOpenStep(source) {
  const tokens = [];
  let index = 0;

  while (index < source.length) {
    const character = source[index];

    if (/\s/.test(character)) {
      index += 1;
      continue;
    }

    if (source.startsWith("/*", index)) {
      const end = source.indexOf("*/", index + 2);
      index = end === -1 ? source.length : end + 2;
      continue;
    }

    if (source.startsWith("//", index)) {
      const end = source.indexOf("\n", index + 2);
      index = end === -1 ? source.length : end + 1;
      continue;
    }

    if ("{}()=;,".includes(character)) {
      tokens.push(character);
      index += 1;
      continue;
    }

    if (character === "\"") {
      let value = "";
      index += 1;
      while (index < source.length) {
        const next = source[index];
        if (next === "\\") {
          value += source[index + 1] ?? "";
          index += 2;
        } else if (next === "\"") {
          index += 1;
          break;
        } else {
          value += next;
          index += 1;
        }
      }
      tokens.push(value);
      continue;
    }

    let value = "";
    while (
      index < source.length &&
      !/\s/.test(source[index]) &&
      !"{}()=;,".includes(source[index])
    ) {
      value += source[index];
      index += 1;
    }
    tokens.push(value);
  }

  return tokens;
}

function parseOpenStep(source) {
  const tokens = tokenizeOpenStep(source);
  let index = 0;

  function parseValue() {
    const token = tokens[index];
    if (token === "{") {
      index += 1;
      const value = {};
      while (tokens[index] !== "}") {
        const key = tokens[index];
        index += 1;
        check("OpenStep dictionary key has equals", tokens[index] === "=");
        index += 1;
        value[key] = parseValue();
        check("OpenStep dictionary entry has semicolon", tokens[index] === ";");
        index += 1;
      }
      index += 1;
      return value;
    }

    if (token === "(") {
      index += 1;
      const value = [];
      while (tokens[index] !== ")") {
        value.push(parseValue());
        if (tokens[index] === ",") {
          index += 1;
        }
      }
      index += 1;
      return value;
    }

    index += 1;
    return token;
  }

  const root = parseValue();
  check("OpenStep parser consumed the project", index === tokens.length);
  return root;
}

const requiredFiles = [
  "EyeCare2020.xcodeproj/project.pbxproj",
  "EyeCare2020.xcodeproj/xcshareddata/xcschemes/EyeCare2020.xcscheme",
  "EyeCare2020/EyeCare2020App.swift",
  "EyeCare2020/ContentView.swift",
  "EyeCare2020/Models/NotificationSchedule.swift",
  "EyeCare2020/Timer/TimerCore.swift",
  "EyeCare2020/Services/LockObserver.swift",
  "EyeCare2020/Services/NotificationScheduler.swift",
  "EyeCare2020/Services/BackgroundAudioKeeper.swift",
  "EyeCare2020/Services/LiveActivityManager.swift",
  "EyeCare2020/Services/RestSoundPlayer.swift",
  "EyeCare2020/ViewModels/TimerViewModel.swift",
  "EyeCare2020/Theme/AppTheme.swift",
  "EyeCare2020/Info.plist",
  "EyeCare2020/Resources/silence.wav",
  "EyeCare2020/Resources/soft-chime.wav",
  "EyeCare2020/Resources/woodblock.wav",
  "EyeCare2020/Resources/double-bell.wav",
  "EyeCare2020/Resources/digital-beep.wav",
  "EyeCare2020LiveActivity/EyeCareLiveActivityAttributes.swift",
  "EyeCare2020LiveActivity/EyeCareLiveActivityWidget.swift",
  "EyeCare2020LiveActivity/Info.plist",
  "EyeCare2020/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png",
  "EyeCare2020Tests/TimerCoreTests.swift",
  "EyeCare2020Tests/NotificationScheduleTests.swift",
  "Package.swift",
  "README.md",
  "ALTSTORE-WINDOWS.md",
  "verify-on-mac.command",
  ".github/workflows/ios.yml",
  ".github/workflows/release-unsigned.yml",
  "scripts/generate-altstore-source.mjs",
  ".gitignore",
];

for (const file of requiredFiles) {
  check(`required file ${file}`, existsSync(join(root, file)));
}

const pbxproj = read("EyeCare2020.xcodeproj/project.pbxproj");
const scheme = read("EyeCare2020.xcodeproj/xcshareddata/xcschemes/EyeCare2020.xcscheme");
const infoPlist = read("EyeCare2020/Info.plist");
const readme = read("README.md");
const project = parseOpenStep(pbxproj);
const objects = project.objects;
const rootProject = objects[project.rootObject];

check("project root object parses", rootProject?.isa === "PBXProject");
check("project has app, widget extension, and test targets", rootProject.targets?.length === 3);
check("app and test products exist", rootProject.productRefGroup && objects[rootProject.productRefGroup]);
check("main group exists", objects[rootProject.mainGroup]?.isa === "PBXGroup");

for (const [identifier, object] of Object.entries(objects)) {
  check(`object ${identifier} has isa`, typeof object.isa === "string");

  if (object.isa === "PBXBuildFile") {
    check(`build file ${identifier} resolves`, Boolean(objects[object.fileRef]));
  }

  if (object.isa === "PBXGroup") {
    for (const child of object.children ?? []) {
      check(`group ${identifier} child resolves`, Boolean(objects[child]), child);
    }
  }

  if (object.isa === "PBXNativeTarget") {
    check(`target ${identifier} has configuration list`, Boolean(objects[object.buildConfigurationList]));
    for (const phase of object.buildPhases ?? []) {
      check(`target ${identifier} phase resolves`, Boolean(objects[phase]), phase);
    }
  }

  if (object.isa === "PBXTargetDependency") {
    check(`dependency ${identifier} target resolves`, Boolean(objects[object.target]));
  }

  if (object.isa === "XCConfigurationList") {
    for (const configuration of object.buildConfigurations ?? []) {
      check(`configuration ${configuration} resolves`, Boolean(objects[configuration]));
    }
  }
}

function checkGroupFiles(identifier, parentDirectory) {
  const group = objects[identifier];
  const directory =
    group.sourceTree === "<group>" && group.path
      ? join(parentDirectory, group.path)
      : parentDirectory;

  for (const childIdentifier of group.children ?? []) {
    const child = objects[childIdentifier];
    if (child.isa === "PBXGroup") {
      checkGroupFiles(childIdentifier, directory);
      continue;
    }

    if (child.isa === "PBXFileReference" && child.sourceTree === "<group>") {
      const filePath = join(directory, child.path);
      check(
        `referenced file exists ${filePath.slice(root.length + 1)}`,
        existsSync(filePath),
      );
    }
  }
}
checkGroupFiles(rootProject.mainGroup, root);

for (const file of [
  "EyeCare2020App.swift",
  "ContentView.swift",
  "NotificationSchedule.swift",
  "TimerCore.swift",
  "LockObserver.swift",
  "NotificationScheduler.swift",
  "BackgroundAudioKeeper.swift",
  "LiveActivityManager.swift",
  "RestSoundPlayer.swift",
  "TimerViewModel.swift",
  "AppTheme.swift",
  "Assets.xcassets",
  "silence.wav",
  "soft-chime.wav",
  "woodblock.wav",
  "double-bell.wav",
  "digital-beep.wav",
  "EyeCareLiveActivityAttributes.swift",
  "EyeCareLiveActivityWidget.swift",
  "TimerCoreTests.swift",
  "NotificationScheduleTests.swift",
]) {
  check(`project references ${file}`, pbxproj.includes(file));
}

for (const file of [
  "EyeCare2020App.swift",
  "ContentView.swift",
  "NotificationSchedule.swift",
  "TimerCore.swift",
  "LockObserver.swift",
  "NotificationScheduler.swift",
  "BackgroundAudioKeeper.swift",
  "LiveActivityManager.swift",
  "RestSoundPlayer.swift",
  "TimerViewModel.swift",
  "AppTheme.swift",
  "EyeCareLiveActivityAttributes.swift",
  "EyeCareLiveActivityWidget.swift",
  "TimerCoreTests.swift",
  "NotificationScheduleTests.swift",
]) {
  check(`build phase includes ${file}`, pbxproj.includes(`${file} in Sources`));
}

check("shared scheme references app", scheme.includes('BlueprintName = "EyeCare2020"'));
check("shared scheme references tests", scheme.includes('BlueprintName = "EyeCare2020Tests"'));
for (const identifier of scheme.match(/BlueprintIdentifier = "([A-F0-9]{24})"/g) ?? []) {
  const value = identifier.match(/[A-F0-9]{24}/)?.[0];
  check(`scheme target ${value} exists`, pbxproj.includes(value));
}
check("app target exists", pbxproj.includes('productType = "com.apple.product-type.application"'));
check(
  "widget extension target exists",
  pbxproj.includes('productType = "com.apple.product-type.app-extension"'),
);
check("test target exists", pbxproj.includes('productType = "com.apple.product-type.bundle.unit-test"'));
check(
  "project identifiers are 24-digit hex",
  !/\b(?=[A-Z0-9]*[G-Z])[A-Z][A-Z0-9]{23}\b/.test(pbxproj),
);
check("audio background mode configured", infoPlist.includes("<string>audio</string>"));
check("Live Activities enabled", infoPlist.includes("<key>NSSupportsLiveActivities</key>"));
check("display name configured", infoPlist.includes("<string>远眺</string>"));
check(
  "iOS 17 deployment target",
  pbxproj.includes("IPHONEOS_DEPLOYMENT_TARGET = 17.0;"),
);
check("app icon configured", pbxproj.includes("ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;"));
check("README explains personal-use audio tradeoff", readme.includes("不适合提交 App Store"));
check(
  "Mac verification script includes iOS build",
  read("verify-on-mac.command").includes("xcodebuild test"),
);
check(
  "GitHub Actions includes Swift tests",
  read(".github/workflows/ios.yml").includes("swift test"),
);
const releaseWorkflow = read(".github/workflows/release-unsigned.yml");
check("AltStore workflow is manually runnable", releaseWorkflow.includes("workflow_dispatch:"));
check(
  "AltStore workflow builds unsigned device app",
  releaseWorkflow.includes("CODE_SIGNING_ALLOWED=NO") &&
    releaseWorkflow.includes("-sdk iphoneos"),
);
check(
  "AltStore workflow publishes a release",
  releaseWorkflow.includes("softprops/action-gh-release@v2"),
);
check(
  "AltStore workflow generates source JSON",
  releaseWorkflow.includes("generate-altstore-source.mjs") &&
    releaseWorkflow.includes("dist/altstore.json"),
);
check(
  "AltStore generator uses the app bundle identifier",
  read("scripts/generate-altstore-source.mjs").includes("com.personal.EyeCare2020"),
);
check(
  "Windows guide links the official AltStore documentation",
  read("ALTSTORE-WINDOWS.md").includes("altstore.io"),
);

const generatedSourcePath = join(
  tmpdir(),
  `eye-care-altstore-source-${process.pid}.json`,
);
execFileSync(
  process.execPath,
  ["scripts/generate-altstore-source.mjs", generatedSourcePath],
  {
    cwd: root,
    env: {
      ...process.env,
      GITHUB_REPOSITORY: "example/EyeCare2020",
      IPA_PATH: "README.md",
      BUILD_DATE: "2026-11-05T00:00:00Z",
    },
  },
);
const generatedSource = JSON.parse(readFileSync(generatedSourcePath, "utf8"));
check(
  "generated AltStore source has the expected app",
  generatedSource.apps?.[0]?.bundleIdentifier === "com.personal.EyeCare2020",
);
check(
  "generated AltStore source uses latest-release URLs",
  generatedSource.apps[0].versions[0].downloadURL.includes(
    "/releases/latest/download/EyeCare2020.ipa",
  ),
);

const jsonFiles = [];
function walk(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const fullPath = join(directory, entry.name);
    if (entry.isDirectory()) {
      walk(fullPath);
    } else if (entry.name.endsWith(".json")) {
      jsonFiles.push(fullPath);
    }
  }
}
walk(join(root, "EyeCare2020", "Assets.xcassets"));

for (const file of jsonFiles) {
  JSON.parse(readFileSync(file, "utf8"));
}
check("asset catalog JSON parses", jsonFiles.length >= 4, `${jsonFiles.length} files`);

const icon = readFileSync(
  join(root, "EyeCare2020", "Assets.xcassets", "AppIcon.appiconset", "AppIcon-1024.png"),
);
check(
  "app icon is PNG",
  icon.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])),
);
check("app icon is 1024x1024", icon.readUInt32BE(16) === 1024 && icon.readUInt32BE(20) === 1024);

const wav = readFileSync(join(root, "EyeCare2020", "Resources", "silence.wav"));
check("silent audio is RIFF/WAVE", wav.toString("ascii", 0, 4) === "RIFF" && wav.toString("ascii", 8, 12) === "WAVE");
check("silent audio is 44.1 kHz mono 16-bit", wav.readUInt32LE(24) === 44_100 && wav.readUInt16LE(22) === 1 && wav.readUInt16LE(34) === 16);
check("silent audio contains no non-zero samples", !wav.subarray(44).some(Boolean));
for (const soundFile of [
  "soft-chime.wav",
  "woodblock.wav",
  "double-bell.wav",
  "digital-beep.wav",
]) {
  const sound = readFileSync(join(root, "EyeCare2020", "Resources", soundFile));
  check(
    `${soundFile} is 44.1 kHz mono 16-bit WAVE`,
    sound.toString("ascii", 0, 4) === "RIFF" &&
      sound.toString("ascii", 8, 12) === "WAVE" &&
      sound.readUInt32LE(24) === 44_100 &&
      sound.readUInt16LE(22) === 1 &&
      sound.readUInt16LE(34) === 16,
  );
  check(
    `${soundFile} is a short notification sound`,
    sound.length > 44 && sound.length < 1_000_000,
  );
}

const swiftFiles = [];
function walkSwift(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const fullPath = join(directory, entry.name);
    if (entry.isDirectory()) {
      walkSwift(fullPath);
    } else if (entry.name.endsWith(".swift")) {
      swiftFiles.push(fullPath);
    }
  }
}
walkSwift(join(root, "EyeCare2020"));
walkSwift(join(root, "EyeCare2020Tests"));
walkSwift(join(root, "EyeCare2020LiveActivity"));

for (const file of swiftFiles) {
  const content = readFileSync(file, "utf8");
  check(`no placeholders in ${file.slice(root.length + 1)}`, !/\b(TBD|TODO|FIXME)\b/.test(content));

  let index = 0;
  const stack = [];
  const pairs = { "}": "{", ")": "(", "]": "[" };
  while (index < content.length) {
    if (content.startsWith("//", index)) {
      const end = content.indexOf("\n", index + 2);
      index = end === -1 ? content.length : end + 1;
      continue;
    }
    if (content.startsWith("/*", index)) {
      const end = content.indexOf("*/", index + 2);
      index = end === -1 ? content.length : end + 2;
      continue;
    }
    if (content[index] === "\"") {
      index += 1;
      while (index < content.length) {
        if (content[index] === "\\") {
          index += 2;
        } else if (content[index] === "\"") {
          index += 1;
          break;
        } else {
          index += 1;
        }
      }
      continue;
    }
    if ("{([".includes(content[index])) {
      stack.push(content[index]);
    } else if ("})]".includes(content[index])) {
      if (pairs[content[index]] !== stack.pop()) {
        throw new Error(
          `unbalanced delimiters in ${file.slice(root.length + 1)} at offset ${index}`,
        );
      }
    }
    index += 1;
  }
  check(
    `balanced Swift delimiters in ${file.slice(root.length + 1)}`,
    stack.length === 0,
  );
}

check("Swift source files present", swiftFiles.length === 15, `${swiftFiles.length} files`);
check("plist is XML", infoPlist.startsWith("<?xml") && infoPlist.trimEnd().endsWith("</plist>"));
check("project block is balanced", (pbxproj.match(/\{/g) ?? []).length === (pbxproj.match(/\}/g) ?? []).length);
check("scheme XML root exists", scheme.includes("<Scheme") && scheme.includes("</Scheme>"));

console.log("PASS");
console.log(`verified ${checks.length} checks, ${swiftFiles.length} Swift files, ${jsonFiles.length} JSON files`);
