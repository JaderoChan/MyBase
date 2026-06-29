# compress_videos 脚本使用说明

## 脚本概述

| 脚本 | 适用系统 |
| --- | --- |
| `compress_videos.bat` | Windows（CMD） |
| `compress_videos.sh` | Linux / macOS（Bash） |

两个脚本功能一致：递归扫描输入目录，对超过指定大小的视频文件进行批量压缩，输出结构与原目录保持一致。

## 运行环境要求

### `compress_videos.bat`（Windows）

| 组件 | 最低要求 | 说明 |
| --- | --- | --- |
| Windows | 10 / 11 | 依赖 CMD `for /f`、延迟扩展等特性 |
| PowerShell | 5.1（Windows 10 内置） | 用于文件枚举、路径计算、文件大小读取 |
| FFmpeg | 4.x+（CPU 模式）；**5.0+（GPU 模式）** | 需加入 `PATH`；GPU 模式版本不足时脚本自动降回 CPU |
| NVIDIA 显卡（GPU 模式） | Maxwell 及以后（GTX 750 起） | 需安装 NVIDIA 驱动 **455+**，并支持 NVENC |

> **PowerShell 版本说明**：`[IO.Path]::GetRelativePath()` 为 .NET Core 2.0 新增方法，PowerShell 5.1（.NET Framework 4.x）**不可用**。脚本已改用字符串截取方式计算相对路径，无需升级 PowerShell。

### `compress_videos.sh`（Linux / macOS）

| 组件 | 最低要求 | 说明 |
| --- | --- | --- |
| Bash | 4.0+ | macOS 自带 Bash 3.2，建议通过 Homebrew 安装 Bash 5 |
| FFmpeg | 4.x+（CPU 模式）；**5.0+（GPU 模式）** | 需加入 `PATH`；GPU 模式版本不足时脚本自动降回 CPU |
| `find` / `sort` / `awk` / `stat` | 系统自带 | Linux 使用 GNU coreutils；macOS 使用 BSD 版本 |
| NVIDIA 显卡（GPU 模式） | 同上 | 需安装 NVIDIA Linux 驱动 455+，并支持 NVENC |

## FFmpeg 版本兼容性说明

### `h264_nvenc` 预设名称差异

FFmpeg 4.x 与 5.x+ 的 `h264_nvenc` 预设体系完全不同，且 NVIDIA 驱动 520+ 废除了旧预设 GUID：

| FFmpeg 版本 | 预设名称体系 | 示例 | 驱动 520+ 兼容 |
| --- | --- | --- | --- |
| 4.x | `default` / `slow` / `medium` / `fast` / `hp` / `hq` | `-preset default` | ❌ 旧 GUID 已废除 |
| 5.x / 6.x+ | `p1`（最快）～ `p7`（最慢） | `-preset p4` | ✅ |

本脚本现使用 `-preset p4`，并在启动时检测 FFmpeg 是否支持该预设：

- 若 FFmpeg **≥ 5.0**：使用 `h264_nvenc -preset p4`（GPU 加速）。
- 若 FFmpeg **< 5.0**：打印警告并自动降回 `libx264` CPU 编码，无需手动干预。

### 为什么不使用旧预设（`default` / `medium` / `hq`）

NVIDIA 驱动 520+（对应 NVENC SDK 12）彻底移除了旧的 GUID 预设 API。使用旧预设会报错：

```plaintext
[h264_nvenc] Cannot get the preset configuration: unsupported param (12)
```

错误代码 12 = `NV_ENC_ERR_UNSUPPORTED_PARAM`，来自 NVENC 底层 API，无法通过调整 FFmpeg 参数绕过，只能换用新预设或更新 FFmpeg。

### 为什么不使用 `-hwaccel cuda`

`-hwaccel cuda` 启用 CUDA 硬件**解码**，会建立一个 CUDA 上下文并尝试与 NVENC 编码器共享。这种混合管线在驱动版本较旧或 GPU 功能受限时同样会触发 `NV_ENC_ERR_UNSUPPORTED_PARAM`。

实际上，GPU 加速的主要收益来自 NVENC **编码器**，而非解码器。去掉 `-hwaccel cuda` 后 CPU 负责解码，GPU 负责编码，兼容性最好，整体压缩速度依然远快于纯 CPU 方案。

## 编码参数说明

| 模式 | 编码器 | 质量参数 | 输出格式 |
| --- | --- | --- | --- |
| 有损 + CPU | `libx264` | `-crf 23` | `.mp4` |
| 有损 + GPU（NVENC） | `h264_nvenc` | `-rc:v constqp -qp 23` | `.mp4` |
| 无损 | `libx264` | `-crf 0` | `.mkv` |

- `-crf 23`（libx264）：感知质量恒定，内容越复杂码率越高，是最常用的质量控制方式。
- `-rc:v constqp -qp 23`（h264_nvenc）：固定量化参数，所有帧使用相同 QP 值；视觉质量与 CRF 23 接近，但不像 CRF 那样根据内容复杂度自适应调整，文件大小可能略有差异。
- 音频轨道始终直接复制（`-c:a copy`），不重新编码。

## 常见问题

### Q：运行时出现 "The system cannot find the drive specified."

两处 CMD 内置行为在 `chcp 65001` 模式下会对 Unicode 路径产生问题：

1. `mkdir "!OUT_DIR!"`：CMD 内置 `mkdir` 在处理含 Unicode 字符的路径时，可能无法正确识别驱动器号，报此错误。

2. `ffmpeg !FF_ARGS!`：`FF_ARGS` 字符串中嵌入了 `"..."` 引号括住的文件路径，CMD 对 `!VAR!` 展开后会二次解析引号，导致 Unicode 路径被截断，FFmpeg 收到不完整的路径。

**修复方案**：

- 目录创建改用 `powershell New-Item -LiteralPath $env:...`
- FFmpeg 调用改用 `powershell & ffmpeg ... $env:PS_FF_INPUT ... $env:PS_FF_OUTPUT`

PowerShell 通过 `$env:` 环境变量接收路径，以单个 token 传给外部命令，不做词分割，彻底绕开 CMD 的引号解析和编码问题。

### Q：Windows 下路径含中文时文件大小显示为 0 MB

`TMPLIST` 临时文件含 UTF-8 BOM，导致第一行路径前附加 BOM 字符。脚本已改用 `[Text.UTF8Encoding]::new($false)` 写出无 BOM 的 UTF-8 文件，此问题已修复。

### Q：输出路径出现 `\ \` 异常

`[IO.Path]::GetRelativePath()` 在 PowerShell 5.1 中不存在（.NET Framework 4.x 缺少该方法），调用失败导致相对路径计算错误。脚本已改用 `String.StartsWith` + `Substring` 替代，此问题已修复。

### Q：Windows 下运行出现"命令语法不正确"

`set /p` 提示字符串本身以 `=` 开头时，CMD 会报语法错误。脚本中以 `===` 开头的分隔符行已改用 `echo` 直接输出，此问题已修复。

### Q：使用 `-use_gpu` 时报错 `unsupported param (12)` 或 `Undefined constant or missing '(' in 'p4'`

这两个错误对应两种不同的版本冲突：

| 现象 | 原因 |
| --- | --- |
| `Cannot get the preset configuration: unsupported param (12)` | FFmpeg **< 5.0** + 驱动 **≥ 520**：旧 GUID 预设已被驱动废除 |
| `Undefined constant or missing '(' in 'p4'` | FFmpeg **< 5.0** + 脚本使用新预设 `p4`：FFmpeg 不认识该名称 |

脚本已内置运行时检测：若 FFmpeg 不支持 `p4` 预设，会自动打印警告并降回 CPU 编码。若需 GPU 加速，请将 FFmpeg 升级至 5.0+。

### Q：macOS 下 `stat` 报错

macOS 的 `stat` 语法与 Linux 不同（`-f '%z'` vs `-c '%s'`）。脚本已分别处理，自动识别系统类型。
