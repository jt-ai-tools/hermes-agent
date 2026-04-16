# 渲染 (Rendering) 參考指南

## 前置條件

```bash
manim --version       # Manim CE
pdflatex --version    # LaTeX
ffmpeg -version       # ffmpeg
```

## CLI 參考

```bash
manim -ql script.py Scene1 Scene2    # 草稿模式 (480p 15fps)
manim -qm script.py Scene1           # 中等品質 (720p 30fps)
manim -qh script.py Scene1           # 生產品質 (1080p 60fps)
manim -ql --format=png -s script.py Scene1  # 預覽靜止畫面（最後一影格）
manim -ql --format=gif script.py Scene1     # 輸出為 GIF
```

## 品質預設值 (Quality Presets)

| 標籤 | 解析度 | FPS | 使用案例 |
|------|-----------|-----|----------|
| `-ql` | 854x480 | 15 | 草稿迭代（版面、時機確認） |
| `-qm` | 1280x720 | 30 | 預覽（適用於包含大量文字的場景） |
| `-qh` | 1920x1080 | 60 | 正式生產輸出 |

**文字渲染品質：** `-ql` (480p15) 產生的文字字距和可讀性明顯較差。對於包含大量文字的場景，請使用 `-qm` 預覽靜止畫面，以發現 480p 下無法察覺的問題。僅在測試版面配置和動畫時機時使用 `-ql`。

## 輸出結構

```
media/videos/script/480p15/Scene1_Intro.mp4
media/images/script/Scene1_Intro.png  (來自 -s 標籤)
```

## 使用 ffmpeg 進行拼接

```bash
cat > concat.txt << 'EOF'
file 'media/videos/script/480p15/Scene1_Intro.mp4'
file 'media/videos/script/480p15/Scene2_Core.mp4'
EOF
ffmpeg -y -f concat -safe 0 -i concat.txt -c copy final.mp4
```

## 加入旁白 (Voiceover)

```bash
# 合併旁白音軌 (Mux)
ffmpeg -y -i final.mp4 -i narration.mp3 -c:v copy -c:a aac -b:a 192k -shortest final_narrated.mp4

# 先拼接各場景的音訊
cat > audio_concat.txt << 'EOF'
file 'audio/scene1.mp3'
file 'audio/scene2.mp3'
EOF
ffmpeg -y -f concat -safe 0 -i audio_concat.txt -c copy full_narration.mp3
```

## 加入背景音樂

```bash
ffmpeg -y -i final.mp4 -i music.mp3 \
  -filter_complex "[1:a]volume=0.15[bg];[0:a][bg]amix=inputs=2:duration=shortest" \
  -c:v copy final_with_music.mp4
```

## 匯出為 GIF

```bash
ffmpeg -y -i scene.mp4 \
  -vf "fps=15,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

## 長寬比 (Aspect Ratios)

```bash
manim -ql --resolution 1080,1920 script.py Scene  # 9:16 直向
manim -ql --resolution 1080,1080 script.py Scene  # 1:1 正方形
```

## 渲染工作流程

1. 使用 `-ql` 草擬渲染所有場景
2. 在關鍵時刻預覽靜止畫面 (`-s`)
3. 修復並僅重新渲染出錯的場景
4. 使用 ffmpeg 進行拼接
5. 檢查拼接後的輸出內容
6. 使用 `-qh` 進行正式生產渲染
7. 重新拼接並加入音訊

## manim.cfg — 專案配置

在專案目錄中建立 `manim.cfg` 以設定個別專案的預設值：

```ini
[CLI]
quality = low_quality
preview = True
media_dir = ./media

[renderer]
background_color = #0D1117

[tex]
tex_template_file = custom_template.tex
```

這可以避免在每個場景中重複輸入 CLI 標籤和 `self.camera.background_color`。

## 區段 (Sections) — 章節標記

在場景中標記區段以便於組織輸出：

```python
class LongVideo(Scene):
    def construct(self):
        self.next_section("簡介")
        # ... 簡介內容 ...

        self.next_section("主要概念")
        # ... 主要內容 ...

        self.next_section("結論")
        # ... 結尾 ...
```

渲染個別區段：`manim --save_sections script.py LongVideo`
這會為每個區段輸出獨立的影片檔案 —— 對於只想重新渲染其中一部分的長影片非常有用。

## manim-voiceover 插件（推薦用於帶旁白的影片）

官方的 `manim-voiceover` 插件將 TTS 直接整合到場景代碼中，自動將動畫時長與旁白長度同步。這比上述手動使用 ffmpeg 合併的方法要整潔得多。

### 安裝

```bash
pip install "manim-voiceover[elevenlabs]"
# 或者使用免費/本地的 TTS：
pip install "manim-voiceover[gtts]"    # Google TTS (免費，品質較低)
pip install "manim-voiceover[azure]"   # Azure Cognitive Services
```

### 用法

```python
from manim import *
from manim_voiceover import VoiceoverScene
from manim_voiceover.services.elevenlabs import ElevenLabsService

class NarratedScene(VoiceoverScene):
    def construct(self):
        self.set_speech_service(ElevenLabsService(
            voice_name="Alice",
            model_id="eleven_multilingual_v2"
        ))

        # 旁白會自動控制場景時長
        with self.voiceover(text="這是一個正在被繪製的圓圈。") as tracker:
            self.play(Create(Circle()), run_time=tracker.duration)

        with self.voiceover(text="現在讓我們把它變換成一個正方形。") as tracker:
            self.play(Transform(circle, Square()), run_time=tracker.duration)
```

### 主要功能

- `tracker.duration` —— 旁白的總時長（以秒為單位）
- `tracker.time_until_bookmark("mark1")` —— 將特定動畫與特定單詞同步
- 自動生成字幕檔案 `.srt`
- 在本地快取音訊 —— 重新渲染時不會重複生成 TTS
- 支援：ElevenLabs, Azure, Google TTS, pyttsx3 (離線) 以及自定義服務

### 使用書籤實現精確同步

```python
with self.voiceover(text='這是一個 <bookmark mark="circle"/>圓圈。') as tracker:
    self.wait_until_bookmark("circle")
    self.play(Create(Circle()), run_time=tracker.time_until_bookmark("circle", limit=1))
```

這是任何帶有旁白的影片的推薦方法。上述手動使用 ffmpeg 合併的工作流程在加入背景音樂或後期音訊混音時仍然很有用。
