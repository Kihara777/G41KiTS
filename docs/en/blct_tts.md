# blct_tts
[中文](../zh/blct_tts.md) | English | [日本語](../ja/blct_tts.md)

blivechat custom template — TTS voice broadcast + default-style visual rendering

## Info

| Item | Value |
|------|-------|
| Type | blc_template |
| Depends | blc |
| Compose | none |
| Version | 1.2.0 |
| Author | 狐莉家的小爪 |

## Features

- **Visual rendering** — YouTube-style chat flow: avatars, usernames, badges, gift icons, super chat highlights
- **Voice broadcast** — Web Speech API TTS, no external dependencies
- **Language adaptive** — auto-detects Japanese (kana→ja-JP), falls back to Chinese engine
- **Smart queue** — danmaku/SC play sequentially; gifts/member joins have their own priority queue
- **Interrupt replay** — interrupted danmaku auto-replays after priority queue drains
- **Right-click settings** — in-page adjustment of rate/pitch/volume/filters, auto-persisted

## Install

```bash
./g41.sh kits add blct_tts
```

The `blc_template/` directory is deployed to `.lc/custom_public/templates/blct_tts/`. Restart blc container for the template to appear.

## Usage

Select "TTS语音播报模板" in blivechat settings, add browser source in OBS. Right-click on page → adjust TTS parameters.
