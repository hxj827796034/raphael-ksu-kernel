# KernelSU Kernel for Redmi K20 Pro (raphael) — PixelExperience Plus 12.1

一个**端到端**的构建工程：源码 → KSU 集成 → 编译 → AnyKernel3 打包。

> ⚠️ 这是构建**流程**的工程，不是预编译产物。我无法替你跑几小时的编译（也没有你的手机/设备进行端到端验证），但你按本 README 在 WSL2 里跑完，应当得到一个可以刷入 K20 Pro 的 `KSU-raphael-AnyKernel3-*.zip`。

## 0. 设备 / ROM 信息

| 项目 | 值 |
| --- | --- |
| 机型 | Redmi K20 Pro / Mi 9T Pro |
| 代号 | `raphael` |
| SoC | Qualcomm Snapdragon 855 (SM8150) |
| 原生 kernel | Linux 4.14.x（CAF/小米 OSS） |
| 当前 ROM | PixelExperience_Plus_raphael-12.1-20221019-0033-OFFICIAL（Android 12L） |
| 刷入方式 | TWRP 刷 AnyKernel3 zip（boot 分区） |
| 推荐 KSU | **SukiSU-Ultra**（4.14 兼容最佳） |
| KSU Manager | **官方 v3.2.5**（build 32525）——与 SukiSU 内核 ABI 100% 兼容 |

## 1. 编译环境

- **WSL2 Ubuntu 22.04/24.04**（推荐）或原生 Linux
- 磁盘：**至少 80 GB 可用空间**（源码 ~30 GB + 中间产物）
- 内存：≥ 16 GB（至少 8 GB）
- 必要工具链：
  - `git`, `make`, `bc`, `libssl-dev`, `build-essential`, `flex`, `bison`, `libelf-dev`, `cpio`, `python3`
  - GCC：`gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu`（Linaro 9.2）
  - 或 AOSP Clang：`android-sdk` 中 `clang-r377417` 或更新

> 🚨 不要用 `apt install gcc-aarch64-linux-gnu`——版本太新会与 4.14 内核头文件冲突。

## 2. 30 秒启动

在 WSL2 里：

```bash
cd /mnt/e/kernel-raphael
chmod +x build.sh scripts/*.sh
./build.sh all
```

它会按顺序执行：

1. `01-prepare-env.sh` — 检查依赖、装缺失包
2. `02-clone-kernel.sh` — 拉 `MiCode/Xiaomi_Kernel_OpenSource`（raphael 分支）
3. `03-clone-ksu.sh` — 拉 `SukiSU-Ultra/KernelSU`
4. `04-apply-patches.sh` — 打 KSU patch + 可选 SUSFS
5. `05-build.sh` — 编译出 `Image.gz-dtb`
6. `06-make-anykernel.sh` — 打成 AnyKernel3 zip
7. `07-pack-existing.sh` — **可选**——如果你已经有 `Image.gz-dtb` 想直接打包，用这个

输出在 `out/KSU-raphael-AnyKernel3-<timestamp>.zip`。

## 2.A 走 GitHub Actions（推荐，零本地依赖）

> **不需要 WSL2、不需要管理员权限、不需要重启**。用 GitHub 提供的免费 Ubuntu runner 跑编译，
> 产出的 zip 作为 Actions artifact 拉回到 `E:\kernel-raphael\out\`。

**一次性前置**：到 https://github.com/settings/tokens/new 创建一个 PAT（Personal Access Token），
勾选 `repo` + `workflow` 两个 scope。**妥善保存，只输入一次**。

**触发 build**（在 PowerShell 里）：

```powershell
cd E:\kernel-raphael
.\scripts\trigger-github-build.ps1 -Pat ghp_你的Token -Owner 你的GitHub用户名
```

脚本会做：

1. 在你 GitHub 账号下创建 `raphael-ksu-kernel` repo（已存在则跳过）
2. 把 `E:\kernel-raphael\` 全部内容 push 上去
3. 触发 `.github/workflows/build.yml`（workflow_dispatch）
4. **轮询** build 状态，每 30s 报一次（最长等 150 分钟）
5. build 成功后**自动下载** `KSU-raphael-zip` artifact 到 `E:\kernel-raphael\out\`
6. 验证 zip 完整性

整个过程**你不用动**，盯输出就行。第一次 build 60-90 分钟，二次 5-15 分钟（ccache 命中）。

> 编译过程可以在 https://github.com/你的用户名/raphael-ksu-kernel/actions 实时看 log。

## 2.5 仅打包（已有 Image）

如果你从别处拿到了 `Image.gz-dtb`（论坛、朋友、CI 产物），不需要重新编译，直接打包：

```bash
./scripts/07-pack-existing.sh /path/to/Image.gz-dtb
# 或
./scripts/07-pack-existing.sh /path/to/Image.gz
# 或自动 gzip
./scripts/07-pack-existing.sh /path/to/Image
```

## 3. 关键选择

### 3.1 Kernel source

默认使用 **MiCode/Xiaomi_Kernel_OpenSource** 的 `raphael` 分支（4.14.190+ 基础）。
这是小米官方源，是社区/PE Plus 12.1 上最稳的 base。branch 名以 `raphael` 关键字匹配。

如果想用 PE 自己的内核源（如果存在并活跃），把 `env.sh` 里 `KERNEL_REPO` / `KERNEL_BRANCH` 改了。

### 3.2 KSU 变体

默认用 **SukiSU-Ultra**（`SukiSU-Ultra/KernelSU`），因为 4.14 兼容最好。

- `SukiSU` （原 `SukiSU-Ultra` 主线，4.14 适配最完整）
- `KernelSU` 主线（tiann/KernelSU）— 仅当 kernel ≥ 4.18 时推荐

改 `env.sh` 里 `KSU_REPO` 即可切换。

> 你用 v3.2.5 官方 Manager（已记录在 `env.sh`），ABI 100% 兼容 SukiSU。

### 3.3 可选模块

| 模块 | 作用 | 开关 |
| --- | --- | --- |
| SUSFS | 隐藏 root（让 SafetyNet/Play Integrity 不易检测到） | `ENABLE_SUSFS=1` |
| trickystore | 绕过 KeyStore 强校验 | `ENABLE_TRICKY=1` |
| HMA | 用户态硬件监控 | `ENABLE_HMA=1` |

## 4. defconfig 增量

`defconfig/raphael_ksu_defconfig` 是相对官方 `raphael_defconfig` 的增量，会在 `04-apply-patches.sh` 里通过 `cat >> arch/arm64/configs/...` 追加到 `arch/arm64/configs/raphael_defconfig`。

最低限度开启：

```
CONFIG_KSU=y
CONFIG_KSU_DEBUG=y                # 出问题好排查
# 可选：
# CONFIG_KSU_SUSFS=y              # 由 ENABLE_SUSFS 自动追加
# CONFIG_TRICKY_STORE=y
```

## 5. 刷入流程

> ⚠️ **必须先在 TWRP 里备份当前 boot 分区！**

1. 完整备份 `boot`：
   ```bash
   adb shell su -c "dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot_stock.img"
   adb pull /sdcard/boot_stock.img
   ```
2. 把 `out/KSU-raphael-AnyKernel3-*.zip` 推到手机：
   ```bash
   adb push out/KSU-raphael-AnyKernel3-*.zip /sdcard/
   ```
3. 重启进 TWRP → Install → 选 zip → 滑动刷入 → 重启。
4. 装 **KSU Manager**（官方 `KernelSU` app 或 `SukiSU Manager`）→ 验证 root。

刷坏恢复：

```bash
fastboot flash boot boot_stock.img
```

## 6. 排错

| 现象 | 排查 |
| --- | --- |
| `flex: not found` | `sudo apt install flex bison` |
| `mkimage not found` | `sudo apt install u-boot-tools` |
| `error: '__force_order' undeclared` | 工具链太新，强制用 Linaro 9.2 |
| 编译后 `Image.gz-dtb` 缺失 | `arch/arm64/configs/raphael_defconfig` 里需要 `CONFIG_BUILD_ARM64_DT_OVERLAY=y` |
| 刷入后无限重启 | 立刻 fastboot 刷回 `boot_stock.img`；多半是 KSU patch 没打全或 defconfig 没合并 |
| 开机但 root 检测不到 | 装对应 Manager；KSU 必须装 SukiSU/Ultra 配套 app |

## 7. 目录结构

```
kernel-raphael/
├── README.md                  # 本文件
├── build.sh                   # 一键入口
├── env.sh                     # 路径与版本配置
├── defconfig/
│   └── raphael_ksu_defconfig  # KSU 增量配置
├── scripts/
│   ├── 01-prepare-env.sh
│   ├── 02-clone-kernel.sh
│   ├── 03-clone-ksu.sh
│   ├── 04-apply-patches.sh
│   ├── 05-build.sh
│   ├── 06-make-anykernel.sh
│   └── 99-clean.sh
├── anykernel3-raphael/        # 刷机模板（raphael 专用）
│   ├── anykernel.sh
│   ├── banner
│   ├── module.prop
│   └── META-INF/com/google/android/...
└── out/                       # 产物（不 commit）
```

## 8. 免责声明

- 刷机有风险，**自行承担**。
- 不要在没备份 `boot` 的情况下刷。
- 本工程不含 KSU/Kernel 的任何二进制或侵权内容；所有源码遵守各自上游 license。

<!-- build-trigger: 2026-08-24T15:41:00Z -->
