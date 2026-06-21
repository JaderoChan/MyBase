# FFmpeg 指令速查表

## 目录

- [FFmpeg 指令速查表](#ffmpeg-指令速查表)
    - [目录](#目录)
    - [基础约定](#基础约定)
    - [常用信息查询](#常用信息查询)
    - [输入、输出与流选择](#输入输出与流选择)
    - [视频编码常用参数](#视频编码常用参数)
    - [音频编码常用参数](#音频编码常用参数)
    - [滤镜基础](#滤镜基础)
    - [常用视频滤镜](#常用视频滤镜)
    - [常用音频滤镜](#常用音频滤镜)
    - [容器与封装操作](#容器与封装操作)
    - [截图、预览与拼图](#截图预览与拼图)
    - [常见转码场景示例](#常见转码场景示例)
        - [MP4（H.264 + AAC，通用兼容）](#mp4h264--aac通用兼容)
        - [HEVC（H.265，更高压缩率）](#hevch265更高压缩率)
        - [无损复制（不重编码）](#无损复制不重编码)
        - [裁剪并缩放到 1080p](#裁剪并缩放到-1080p)
        - [叠加图片水印](#叠加图片水印)
        - [改速（视频 1.25 倍，音频同步）](#改速视频-125-倍音频同步)
    - [硬件加速简表](#硬件加速简表)
    - [常见问题与注意事项](#常见问题与注意事项)

## 基础约定

| 项 | 含义 | 说明 |
| --- | --- | --- |
| `ffmpeg` | 转码与处理主命令 | 读入输入，经过解码/滤镜/编码后输出 |
| `ffprobe` | 媒体信息探测 | 查询时长、码率、流信息、元数据 |
| `-i input` | 输入文件 | 可出现多次表示多输入 |
| `-c:v` / `-c:a` | 视频/音频编码器 | 如 `libx264`、`aac` |
| `-map` | 选择输出流 | 精确控制输出包含哪些流 |
| `-vf` / `-af` | 视频/音频滤镜 | 单路滤镜链 |
| `-filter_complex` | 复杂滤镜图 | 多输入、多输出、合成场景 |

- 选项的作用域通常是“就近作用于其后的输出文件”。
- 同一命令可输出多个文件，每个输出可使用不同参数。
- `-y` 覆盖输出文件，`-n` 遇到已存在文件则不覆盖。

## 常用信息查询

| 目标 | 命令 |
| --- | --- |
| 查看 ffmpeg 版本 | `ffmpeg -version` |
| 列出可用编码器 | `ffmpeg -encoders` |
| 列出可用解码器 | `ffmpeg -decoders` |
| 列出可用复用器（muxer） | `ffmpeg -muxers` |
| 列出可用解复用器（demuxer） | `ffmpeg -demuxers` |
| 列出可用滤镜 | `ffmpeg -filters` |
| 查看指定编码器详情 | `ffmpeg -h encoder=libx264` |
| 查看媒体流信息（简洁） | `ffprobe -hide_banner input.mp4` |

## 输入、输出与流选择

| 参数 | 含义 | 示例 |
| --- | --- | --- |
| `-map 0` | 映射第 0 个输入的全部流 | `-map 0 -c copy out.mkv` |
| `-map 0:v:0` | 选择第 0 输入的第 1 路视频流 | `-map 0:v:0 -map 0:a:0` |
| `-map -0:s` | 排除字幕流 | 常用于去字幕封装 |
| `-vn` | 禁用视频流 | 仅保留音频 |
| `-an` | 禁用音频流 | 仅保留视频 |
| `-sn` | 禁用字幕流 | 忽略字幕 |
| `-dn` | 禁用数据流 | 忽略附件/章节等数据流 |

示例：仅复制视频和音频主流。

```bash
ffmpeg -i input.mkv -map 0:v:0 -map 0:a:0 -c copy out.mp4
```

## 视频编码常用参数

| 参数 | 含义 | 常见值 |
| --- | --- | --- |
| `-c:v` | 视频编码器 | `libx264`、`libx265`、`h264_nvenc` |
| `-crf` | 质量优先模式（恒定质量） | `x264` 常用 `18` - `28` |
| `-preset` | 编码速度与压缩率权衡 | `ultrafast` 到 `veryslow` |
| `-b:v` | 目标视频码率 | 如 `4M` |
| `-maxrate` | 峰值码率 | 常配合 `-bufsize` |
| `-bufsize` | 码率控制缓冲区 | 如 `8M` |
| `-pix_fmt` | 像素格式 | `yuv420p` 兼容性最好 |
| `-r` | 输出帧率 | 如 `30`、`60` |
| `-g` | GOP 长度（关键帧间隔） | 如 `60`（30 fps 下约 2 秒） |

示例：H.264 常见高兼容输出。

```bash
ffmpeg -i input.mov -c:v libx264 -crf 23 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k out.mp4
```

## 音频编码常用参数

| 参数 | 含义 | 常见值 |
| --- | --- | --- |
| `-c:a` | 音频编码器 | `aac`、`libopus`、`libmp3lame` |
| `-b:a` | 音频码率 | `128k`、`192k`、`320k` |
| `-ar` | 采样率 | `44100`、`48000` |
| `-ac` | 声道数 | `1`（单声道）、`2`（立体声） |
| `-q:a` | VBR 质量参数（部分编码器） | mp3 常见 `0` - `5` |

示例：提取高质量 MP3。

```bash
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 out.mp3
```

## 滤镜基础

| 写法 | 说明 |
| --- | --- |
| `-vf "scale=1280:-2,fps=30"` | 视频单链滤镜，按顺序执行 |
| `-af "volume=1.5,aresample=48000"` | 音频单链滤镜 |
| `-filter_complex "..."` | 多输入多输出复杂图 |
| `[0:v][1:v]hstack=inputs=2[outv]` | 通过标签连接滤镜节点 |

- `-vf`、`-af` 用于简单单路处理。
- 涉及叠加、拼接、画中画、多路混音时使用 `-filter_complex`。

## 常用视频滤镜

| 滤镜 | 作用 | 示例 |
| --- | --- | --- |
| `scale` | 缩放分辨率 | `scale=1920:1080` |
| `fps` | 改变帧率 | `fps=30` |
| `crop` | 裁剪画面 | `crop=1280:720:0:0` |
| `pad` | 补边 | `pad=1920:1080:(ow-iw)/2:(oh-ih)/2` |
| `transpose` | 旋转 90 度 | `transpose=1` |
| `hflip` / `vflip` | 水平/垂直翻转 | `hflip` |
| `drawtext` | 绘制文字水印 | `drawtext=text='Demo':x=20:y=20` |
| `subtitles` | 烧录字幕 | `subtitles=sub.srt` |
| `setpts` | 改变视频速度时间戳 | `setpts=0.5*PTS`（2 倍速） |

## 常用音频滤镜

| 滤镜 | 作用 | 示例 |
| --- | --- | --- |
| `volume` | 调整音量 | `volume=1.5` |
| `aresample` | 重采样 | `aresample=48000` |
| `atrim` | 裁切音频区间 | `atrim=start=5:end=20` |
| `afade` | 淡入淡出 | `afade=t=in:ss=0:d=2` |
| `atempo` | 改变播放速度 | `atempo=1.25` |
| `pan` | 声道重映射 | `pan=mono\|c0=0.5*c0+0.5*c1` |
| `loudnorm` | 响度标准化（EBU R128） | `loudnorm=I=-16:LRA=11:TP=-1.5` |

## 容器与封装操作

| 目标 | 命令 |
| --- | --- |
| 无损换封装（remux） | `ffmpeg -i input.mkv -c copy out.mp4` |
| 提取音频流为 m4a | `ffmpeg -i input.mp4 -vn -c:a copy out.m4a` |
| 提取视频流（无音频） | `ffmpeg -i input.mp4 -an -c:v copy out.h264` |
| 合并视频与外部音频 | `ffmpeg -i video.mp4 -i audio.m4a -c copy -map 0:v:0 -map 1:a:0 out.mp4` |
| 添加软字幕 | `ffmpeg -i input.mp4 -i sub.srt -c copy -c:s mov_text out.mp4` |

## 截图、预览与拼图

| 目标 | 命令 |
| --- | --- |
| 截取第 10 秒单帧 | `ffmpeg -ss 10 -i input.mp4 -frames:v 1 shot.jpg` |
| 每秒导出 1 帧 | `ffmpeg -i input.mp4 -vf fps=1 frame_%04d.png` |
| 生成 3x3 缩略图拼图 | `ffmpeg -i input.mp4 -vf "fps=1,scale=320:-2,tile=3x3" preview.jpg` |
| 预览前 30 秒 | `ffmpeg -ss 0 -t 30 -i input.mp4 -c copy clip.mp4` |

## 常见转码场景示例

### MP4（H.264 + AAC，通用兼容）

```bash
ffmpeg -i input.mkv -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 192k -movflags +faststart out.mp4
```

### HEVC（H.265，更高压缩率）

```bash
ffmpeg -i input.mp4 -c:v libx265 -crf 28 -preset medium -c:a aac -b:a 160k out_hevc.mp4
```

### 无损复制（不重编码）

```bash
ffmpeg -i input.ts -c copy out.mkv
```

### 裁剪并缩放到 1080p

```bash
ffmpeg -i input.mp4 -vf "crop=iw:ih-140:0:70,scale=1920:1080" -c:v libx264 -crf 22 -c:a copy out_1080p.mp4
```

### 叠加图片水印

```bash
ffmpeg -i input.mp4 -i logo.png -filter_complex "[0:v][1:v]overlay=20:20" -c:v libx264 -crf 23 -c:a copy out_watermark.mp4
```

### 改速（视频 1.25 倍，音频同步）

```bash
ffmpeg -i input.mp4 -filter_complex "[0:v]setpts=PTS/1.25[v];[0:a]atempo=1.25[a]" -map "[v]" -map "[a]" out_speed.mp4
```

## 硬件加速简表

| 平台 | 常见编码器 | 示例 |
| --- | --- | --- |
| NVIDIA | `h264_nvenc`、`hevc_nvenc` | `-c:v h264_nvenc -preset p5 -cq 23` |
| Intel | `h264_qsv`、`hevc_qsv` | `-c:v h264_qsv -global_quality 23` |
| AMD | `h264_amf`、`hevc_amf` | `-c:v h264_amf -quality quality` |
| Apple | `h264_videotoolbox`、`hevc_videotoolbox` | `-c:v h264_videotoolbox -b:v 5M` |

- 不同平台编译的 ffmpeg 可用硬件编码器可能不同。
- 硬件编码通常更快，但同体积画质可能略低于高质量软件编码。

## 常见问题与注意事项

- `-ss` 放在 `-i` 之前通常更快（关键帧级 seek），放在之后通常更准。
- 流复制（`-c copy`）时不能使用会改变码流内容的滤镜。
- MP4 常见兼容像素格式是 `yuv420p`，高位深/非常见像素格式可能导致设备无法播放。
- Web 播放建议加 `-movflags +faststart`，将 moov 元数据前移。
- 音视频不同步时，优先检查源文件时间戳问题，再考虑 `-vsync`、`aresample=async=1` 等策略。
- 大批量任务建议先用一小段样本验证参数，再批处理全量文件。
