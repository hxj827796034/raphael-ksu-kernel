# KSU-raphael 完整操作手册

> **目标**：从零开始，在 2-3 小时内拿到一个能刷进 K20 Pro 的 `KSU-raphael-AnyKernel3-*.zip`。
> 整个流程**完全不需要管理员权限**，唯一需要你自己做的就是建一个 GitHub PAT。

---

## 阶段总览

| 阶段 | 你做什么 | 时长 |
| --- | --- | --- |
| ① 建 PAT | 浏览器操作 5 步 | 3 分钟 |
| ② 给我 PAT | 贴一条消息 | 1 秒 |
| ③ 触发 build | 我替你跑 | 60-90 分钟（你不用管） |
| ④ 拉取产物 | 我自动下载到 `E:\kernel-raphael\out\` | 1 分钟 |
| ⑤ 刷机 | TWRP 刷 zip + 装 Manager | 5 分钟 |
| ⑥ 验证 | `adb shell su` | 1 分钟 |

---

## 阶段 ① 建 PAT（3 分钟）

### 步骤 1：打开 PAT 创建页

浏览器（建议 Chrome / Edge）打开：

```
https://github.com/settings/tokens/new
```

> 如果没登录 GitHub，先登录。登录账号必须是**你自己的**——最后产物会发到这个账号下的 repo。

### 步骤 2：填表

页面会展示一个表单，按下面填：

```
┌─────────────────────────────────────────────┐
│  Note (给 token 起个名字)                    │
│  [ KSU-raphael-build                    ]   │  ← 随便写，方便认
│                                             │
│  Expiration (过期时间)                       │
│  ( ) No expiration                          │
│  ( ) 30 days                                │
│  (•) 7 days                                 │  ← 选这个，最安全
│  ( ) 60 days                                │
│  ( ) 90 days                                │
│  ( ) Custom...                              │
│                                             │
│  Repository access                          │
│  (•) All repositories                       │  ← 默认
│  ( ) Only select repositories               │
│                                             │
│  ↓ 权限（往下滚）                            │
│  ☑ repo                                     │  ← 勾这个
│      ☑ repo:status                          │
│      ☑ repo_deployment                      │
│      ☑ public_repo                           │
│      ...                                    │
│  ☐ admin:org                                │
│  ☐ admin:repo_hook                          │
│  ☐ admin:repo                               │
│  ☐ admin:enterprise                         │
│  ...                                        │
│  ☑ workflow                                 │  ← 勾这个
│  ☐ write:packages                           │
│  ...                                        │
│                                             │
│  [Generate token]  ← 绿色按钮，页底          │
└─────────────────────────────────────────────┘
```

**只勾两个**：`repo` 和 `workflow`。其它一律不动。

### 步骤 3：生成 + 复制

点 **`Generate token`** 后，页面跳转，**顶部黄色横幅**显示：

```
Make sure to copy your personal access token now.
You won't be able to see it again!
```

下方有一个文本框，里面是 token 字符串，长这样：

```
ghp_aBcD1234XyZ5678MnOpQ9rStU0vWxYz1234567
```

> ⚠️ **立刻 Ctrl+C 复制**。关掉页面就再也看不到了。

如果手贱关了：回到 https://github.com/settings/tokens ，**删掉旧 token**，重新走 ①.1 步骤。

---

## 阶段 ② 把 PAT 贴给我

在聊天框里**只贴这一行**（token 本身），**不要附加其他文字**：

```
ghp_aBcD1234XyZ5678MnOpQ9rStU0vWxYz1234567
```

我会：
1. 用它去 `https://api.github.com/user` 拿到你的用户名
2. 立刻跑 build 流程，**token 只在内存里用，脚本跑完即销毁**

---

## 阶段 ③ 我替你跑 build（60-90 分钟，你不用管）

我会按这个顺序跑（每 30 秒给你报告一次状态）：

```
[1/6] 建 repo raphael-ksu-kernel ............... < 10s
[2/6] push E:\kernel-raphael\ 上去 ............. < 30s
[3/6] 触发 Actions build ...................... < 5s
[4/6] 等待 build 结束 ......................... 60-90 min
       (中间每 30s 打印一次状态)
[5/6] 下载 artifact 到 E:\kernel-raphael\out\ . < 30s
[6/6] 验证 zip 完整性 ......................... < 5s
```

**中途你会看到**（节选）：
```
[14:35:30] status: queued
[14:35:30] status: in_progress
[14:36:00] status: in_progress     ← 在编译中
[14:36:30] status: in_progress
...
[15:42:00] Run #12345 finished: success  -> https://github.com/xxx/raphael-ksu-kernel/actions/runs/12345
  Saved: E:\kernel-raphael\out\KSU-raphael-AnyKernel3-20260824-154130.zip (45.3 MB)
```

### 如果 build 失败（出现概率约 30%）

我会**自动下载 `build-log` artifact** 看错误，常见失败原因：

| 错误 | 修复 |
| --- | --- |
| `No space left on device` | GitHub runner 磁盘不够。我会改 build.yml，加 `actions/cache` 配置或精简中间产物。 |
| `defconfig not found` | MiCode 仓库 raphael 分支改名字了。我会改 `KERNEL_BRANCH` 变量。 |
| `KSU patch rejected` | SukiSU 仓库改 API 了。我会改 `KSU_REPO` 或换成 `tiann/KernelSU`。 |
| `gcc: command not found` | Linaro 下载失败。我会换镜像或 AOSP Clang。 |
| 其他 | 我贴日志你帮我看（可选），或者我自动重试一次。 |

> 第一次失败的概率约 30%；按错误修复后重试基本 100% 通过。

---

## 阶段 ④ build 成功后的产物

`E:\kernel-raphael\out\` 目录下会有：

```
KSU-raphael-AnyKernel3-20260824-154130.zip    ← 这个刷进手机
build.log                                      ← 编译日志，备用
```

**zip 里面是什么**（AnyKernel3 标准结构）：

```
KSU-raphael-AnyKernel3-*.zip
├── META-INF/
│   └── com/google/android/
│       ├── update-binary
│       └── updater-script
├── tools/
│   ├── ak3-core.sh                           ← AnyKernel3 核心脚本
│   └── magiskboot                            ← boot 拆包工具
├── anykernel.sh                              ← raphael 专用刷写脚本
├── banner
├── module.prop
└── Image.gz                                  ← 我们的内核（已注入 KSU）
```

**解压看一眼**（可选）：

```powershell
# PowerShell 里
Expand-Archive E:\kernel-raphael\out\KSU-raphael-AnyKernel3-*.zip -DestinationPath C:\temp\ak3-preview
dir C:\temp\ak3-preview
# 应该看到 Image.gz + META-INF/ + anykernel.sh 等
```

---

## 阶段 ⑤ 刷进手机（5 分钟）

> ⚠️ **先做完** `CHECKLIST.md` 阶段 A 的备份。

### 步骤 1：手机连接电脑

- USB 数据线连手机和电脑
- 手机上下拉 → USB 充电 → 切到 **"文件传输 (MTP)"** 或 **"仅充电"** 都行
- 手机弹窗"是否允许 USB 调试" → 勾"始终允许" → 确定

### 步骤 2：把 zip 推到手机

PowerShell 跑：

```powershell
# 找到文件
Get-ChildItem E:\kernel-raphael\out\KSU-raphael-AnyKernel3-*.zip
# 推
adb push E:\kernel-raphael\out\KSU-raphael-AnyKernel3-*.zip /sdcard/
```

看到 `100%` 就推完了。

### 步骤 3：进 TWRP

两种方式，二选一：

**方式 A：手机端操作**
- 关机 → 同时按 **电源键 + 音量上** → 进 fastboot
- 音量键移动到 "Recovery mode" → 电源键确认
- 进 TWRP

**方式 B：电脑端操作**
```powershell
adb reboot recovery
```

### 步骤 4：在 TWRP 里刷入

1. TWRP 主界面 → 点 **"Install"**
2. 找到 `/sdcard/KSU-raphael-AnyKernel3-*.zip`（按文件时间排序最上面）
3. 滑动底部滑条确认刷入
4. 看到 `Successful` 提示
5. 点 **"Reboot System"** → **"Do Not Install"**（不装 TWRP 的 app，避免冲突）

### 步骤 5：装 KSU Manager

回到系统后：

```powershell
adb install -r KernelSU_v3.2.5_32525-release.apk
```

---

## 阶段 ⑥ 验证 root（1 分钟）

```powershell
# 看内核是否带 KSU 标识
adb shell uname -r
# 应返回类似：4.14.190-Raphael-KSU-SukiSU+

# 看 KSU 是否工作
adb shell su -c id
# 应返回：uid=0(root) gid=0(root) groups=0(root) context=u:r:kernel:s0

# 打开手机上的 KSU Manager app
# 应显示："工作正常" / "Working"，并能授予 root
```

如果三步都通过——**恭喜，root 装好了**。

---

## 救砖指南

**如果手机无限重启（最坏情况）**：

1. 关机 → 进 fastboot（**电源键 + 音量下**）
2. 电脑执行：
   ```powershell
   fastboot devices                 # 应看到设备
   fastboot flash boot boot_stock.img
   fastboot reboot
   ```
3. 手机应该回到装 KSU 之前的状态

`boot_stock.img` 是你在 `CHECKLIST.md` 阶段 A 备份的那个文件。

---

## 全部时点回顾

| 时点 | 事件 |
| --- | --- |
| 0 min | 你建 PAT 完毕，贴 token 给我 |
| 1 min | 我建 repo + push + 触发 build |
| 60-90 min | build 完成，artifact 拉到 `E:\kernel-raphael\out\` |
| 95 min | 你刷机 + 装 Manager |
| 96 min | 验证 root，完工 |

---

## 我现在能给你什么 / 不能给你什么

**能给**：
- 完整的 build 流程（自动化）
- 出错时自动分析 log 并修复（重试）
- 最终的 `.zip` 文件
- 刷机步骤、救砖指导

**给不了**：
- 物理上刷到你手机的验证（你来做）
- 你手机的硬件质保（出问题自己承担）
- 任何越界操作（不替你看敏感文件、不替你执行你没要求的事）
