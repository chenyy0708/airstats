<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/logo-dark.png">
  <img src="docs/logo-light.png" alt="" width="104">
</picture>

<h3>AirStats</h3>

An ultra lightweight macOS system monitor.

<hr width="140">

</div>

AirStats is a system monitor for the Mac menu bar. It reads CPU, memory, GPU, network,
disk, battery, temperature, process and host statistics from the kernel and shows them in
three places: the menu bar itself, a panel that drops down when you click the status item,
and a desktop widget you can leave on screen.

It is built to be genuinely light. A menu bar monitor runs all day, every day, so AirStats
holds a few megabytes and a fraction of a percent of one core rather than the tens of
megabytes its peers take. It has no Dock icon, and reads the system through Mach, IOKit,
sysctl and CoreWLAN.

## 简体中文

这是 [byrencheema/airstats](https://github.com/byrencheema/airstats) 的简体中文界面分支，许可证仍是 MIT（见 [LICENSE](LICENSE)）。采样和性能逻辑与上游一致，没有加入遥测。

Mac 的首选语言是简体中文时，菜单栏、设置、面板、提醒和关于页面显示中文；其他语言继续用英文。菜单栏竖排缩写（CPU、TEMP 等）仍是拉丁字母，那一列只有三个大写字母的高度，中文会叠在一起。横排短标题和其余界面会显示中文。

### 从 GitHub Actions 下载构建

工作流名称是 **Build macOS app**，运行器是 `macos-26`，并会选中 Xcode 26，从而编进 Liquid Glass。`#if compiler(>=6.2)` 仍在：更早的 SDK（例如本机的 Xcode 16）会改用原来的毛玻璃材质，简体中文两种构建都在。最低系统版本仍是 macOS 14。`macos-26` 托管运行器偶尔排不上队，作业会在还没编译时被取消；打开那次运行点 **Re-run jobs** 即可。

1. 打开这个仓库的 [Actions](https://github.com/chenyy0708/airstats/actions) 页。
2. 左侧选择 **Build macOS app**。
3. 推送到 `main`，或打开拉取请求时，工作流会自动运行。工作流文件已经在默认分支上之后，也可以在该页选择 **Run workflow** 手动运行。
4. 打开一次成功的运行，滚到页面底部的 **Artifacts**。
5. 下载 **AirStats-macos-app**（里面是 `AirStats.app` 的 zip）或 **AirStats-macos-dmg**（里面是 `.dmg`）。GitHub 会把构件再套一层 zip，解压一次就能看到。
6. 把 `AirStats.app` 拖进“应用程序”。这个包只做了临时签名，从浏览器下载后 macOS 会隔离它。在终端执行：

```sh
xattr -dr com.apple.quarantine /Applications/AirStats.app
```

然后打开。它没有 Apple 公证，和上游在 [airstats.app](https://airstats.app) 提供的已公证安装包不是同一种分发。

## Requirements

- macOS 14 or later
- Apple silicon

## Install

Download it from [airstats.app](https://airstats.app), open the dmg and drag the app to
Applications. It is signed and notarized, so it opens with no warning.

Or with Homebrew:

```sh
brew install --cask airstats
```

AirStats updates itself with [Sparkle](https://sparkle-project.org). It asks airstats.app
once a week whether a newer version exists, and installs one only when you say so. Both of
those can be turned off in General settings.

## Build from source

You need Xcode 16 or later (Swift 6). Liquid Glass is compiled only with the macOS 26 SDK (`#if compiler(>=6.2)`); earlier SDKs keep the material backdrop. The GitHub Actions app build runs on `macos-26` and selects Xcode 26.

```sh
Scripts/build.sh release
cp -R .build/release/AirStats.app /Applications/
open /Applications/AirStats.app
```

`Scripts/build.sh` wraps the SwiftPM binary in a `.app` bundle, copies `Sparkle.framework`
into `Contents/Frameworks`, and signs it ad hoc. macOS grants a status item only to a
signed bundle with `LSUIElement` set. Run the script with no argument for a debug build.

An ad-hoc signature is enough to run a build you made yourself, and not enough to travel:
macOS refuses an ad-hoc bundle that arrived over the internet. `Scripts/release.sh` is what
produces the download above, signing with a Developer ID certificate and stapling Apple's
notarization ticket to the `.dmg`.

## Source layout

| Path | What lives there |
| --- | --- |
| `Sources/AirStatKit` | Collectors, the sampling engine, settings, formatting. No UI. |
| `Sources/AirStatUI` | Menu bar drawing, panel, desktop widget, settings window, charts, design system. |
| `Sources/AirStats` | The executable, app delegate, and the probe and render commands. |
| `Tests/AirStatKitTests` | Contract tests for the collectors, plus settings and formatting. |
| `Scripts/build.sh` | Builds the binary and assembles the `.app`. |
| `Scripts/release.sh` | Signs, notarizes and packages the `.dmg` that ships. |
| `Scripts/appcast.py` | Writes a release into the appcast Sparkle reads. |
| `Scripts/benchmark.py` | Samples the menu bar monitors on your Mac over one shared window. |

`AirStatKit` never imports SwiftUI or AppKit, which is what lets the tests and the probe
run in a windowless process.

## Contributing

[CONTRIBUTING.md](CONTRIBUTING.md) has the checks to run before a pull request and the
house rules.

## Contact

Bugs and feature requests go on the [issue tracker](https://github.com/byrencheema/airstats/issues).
For anything private, email [hello@airstats.app](mailto:hello@airstats.app).

## License

MIT. See [LICENSE](LICENSE).
