# KSU-raphael 上手检查清单

挑一条路：推荐 **B（GitHub Actions）**，备选 **C（WSL2）**。

## A. 手机端（一次性）

- [ ] TWRP 已刷入（OrangeFox 也可）
- [ ] 当前能进系统，USB 调试开启
- [ ] **已备份当前 boot 分区**：
  ```bash
  adb shell su -c "dd if=/dev/block/bootdevice/by-name/boot of=/sdcard/boot_stock.img"
  adb pull /sdcard/boot_stock.img   # 留 2 份
  ```
- [ ] 确认 ROM 是 **PE Plus 12.1 raphael (2022-10-19)** 或近似的 Android 12L AOSP
- [ ] 手机电量 ≥ 60%

## B. PC 端 — 走 GitHub Actions（推荐）

- [ ] 创建 GitHub PAT：https://github.com/settings/tokens/new
  - 勾选 `repo` + `workflow` 两个 scope
  - 保存 token（**只显示一次**！）
- [ ] 在 PowerShell 跑：
  ```powershell
  cd E:\kernel-raphael
  .\scripts\trigger-github-build.ps1 -Pat ghp_你的Token -Owner 你的GitHub用户名
  ```
- [ ] 第一次跑会创建 repo + 触发 build + 轮询 + 下载 artifact，全程 60-90 分钟
- [ ] 产物在 `E:\kernel-raphael\out\KSU-raphael-AnyKernel3-*.zip`

## C. PC 端 — 走 WSL2（备选，需 admin）

- [ ] 安装 WSL2：
  ```powershell
  wsl --install -d Ubuntu-22.04
  ```
- [ ] 给 WSL2 分配至少 8 GB RAM、80 GB 磁盘
- [ ] WSL2 内装基础包：
  ```bash
  sudo apt update && sudo apt install -y build-essential bc flex bison libssl-dev libelf-dev cpio python3 rsync curl xz-utils unzip zip u-boot-tools
  ```
- [ ] 下载并解压 Linaro GCC 9.2：
  ```bash
  mkdir -p ~/toolchains
  cd ~/toolchains
  wget -c https://releases.linaro.org/components/toolchain/binaries/9.2-2019.12/aarch64-linux-gnu/gcc-linaro-9.2.1-2019.12-x86_64_aarch64-linux-gnu.tar.xz
  tar -xf gcc-linaro-9.2.1-2019.12-x86_64_aarch64-linux-gnu.tar.xz
  mv gcc-linaro-9.2.1-2019.12-x86_64_aarch64-linux-gnu aarch64-linux-gnu
  ```
- [ ] ADB / fastboot 已装（`platform-tools`），`adb devices` 能看到手机

## D. 第一次构建（WSL2 路径）

```bash
cd /mnt/e/kernel-raphael
./build.sh all
```

第一次会下载 ~30 GB 源码 + 编译 30-90 分钟。**不要中断**。

## E. 刷入

```bash
adb push out/KSU-raphael-AnyKernel3-*.zip /sdcard/
# 重启进 TWRP
adb reboot recovery
# 在 TWRP 选 zip 刷入
```

或者：
```bash
fastboot boot twrp-raphael.img   # 临时启动 TWRP
# 在 TWRP 里操作
```

## F. 验证 root

- 装 **KernelSU Manager v3.2.5**（官方 tiann/KernelSU）
  ```bash
  adb install -r KernelSU_v3.2.5_32525-release.apk
  ```
  （APK SHA256 已与 GitHub release 对过，size/name 完全一致）
- 打开 app 应显示 "工作正常" / "Working"
- 测试：
  ```bash
  adb shell su -c id    # 应返回 uid=0(root)
  adb shell su -c uname -r    # 应是新内核版本（含 KSU 标识）
  ```

## G. 出问题

- **无限重启**：立刻进 fastboot → `fastboot flash boot boot_stock.img`
- **KSU app 显示未安装**：内核编译时 `CONFIG_KSU=y` 没生效，defconfig 没合上
- **启动后 WiFi/相机坏**：错用了 5.x 内核源；必须用 4.14 小米 OSS
- **SafetyNet/Play Integrity 失败**：装 SUSFS 配套模块 + Zygisk
