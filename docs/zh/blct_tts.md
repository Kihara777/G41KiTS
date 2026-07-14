# blct_tts
中文 | [English](../en/blct_tts.md) | [日本語](../ja/blct_tts.md)

blivechat 自定义模板 —— TTS 语音播报 + 默认风格视觉渲染

## 基本信息

| 项目 | 值 |
|------|-----|
| 类型 | blc_template |
| 依赖 | blc |
| compose | none |
| 版本 | 1.2.0 |
| 作者 | 狐莉家的小爪 |

## 功能

- **视觉渲染** — YouTube 风格弹幕流：头像、用户名、勋章、礼物图标、醒目留言高亮
- **语音播报** — Web Speech API TTS，无外部依赖
- **语言自适应** — 自动检测日语（假名→ja-JP），回退中文引擎
- **智能队列** — 弹幕/SC 顺序播放；礼物/上舰独立队列可插队
- **中断重播** — 礼物打断的弹幕在优先队列清空后自动重播
- **右键设置** — 页内实时调节语速/音调/音量/过滤阈值，自动持久化

## 安装

```bash
./g41.sh kits add blct_tts
```

安装后 `blc_template/` 目录自动部署到 `.lc/custom_public/templates/blct_tts/`。需重启 blc 容器使模板生效。

## 使用

在 blivechat 设置中选择「TTS语音播报模板」，OBS 添加浏览器源即可。页内右键 → 调节 TTS 参数。
