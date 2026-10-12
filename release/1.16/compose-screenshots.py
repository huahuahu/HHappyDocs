#!/usr/bin/env python3
"""Compose real simulator captures into the HDiary 1.16 App Store artwork."""
from pathlib import Path
import argparse
import glob
import hashlib
import html
import json
import shutil
import subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[1]
THEMES = {
    "light": {
        "background": "#FFF9EF", "accent": "#FFF0D6", "brand": "#473A29",
        "title": "#3F352B", "highlight": "#D96C25", "subtitle": "#817264",
        "frame": "#34302C", "border": "#BCAF9D", "island": "#171614",
        "shadow": (91, 57, 29, 48), "preview": "#EEE8DF",
        "description": "暖白背景 · 橙色标题 · 真实应用页面。",
    },
    "dark": {
        "background": "#191716", "accent": "#2D211B", "brand": "#FFF1DE",
        "title": "#FFF1DE", "highlight": "#FFAA6B", "subtitle": "#C0AEA0",
        "frame": "#242220", "border": "#74655A", "island": "#000000",
        "shadow": (0, 0, 0, 128), "preview": "#100F0E",
        "description": "暖黑背景 · 橙色标题 · 真实深色应用页面。",
    },
}
COPY = {
    "zh-Hans": [
        ("每一份小快乐", "都值得记住", "按时间整理乐事，回看生活里的闪光。"),
        ("留住当时的", "人、事与心情", "用文字、照片、评分，记下更多细节。"),
        ("快乐的回忆", "总有重要的人", "把家人和朋友，放进同一份回忆。"),
        ("用喜欢的标签", "收藏生活片段", "美食、阅读、旅行，轻松分类回顾。"),
        ("看见快乐", "一点点积累", "用图表回顾，让好心情有迹可循。"),
    ],
    "en-US": [
        ("Little moments.", "Lasting happiness.", "Keep everyday joys, beautifully organized."),
        ("Remember more", "of every moment.", "Photos, people and the way you felt."),
        ("Your favorite people.", "Your happiest memories.", "Keep the people in your stories close."),
        ("A place for", "every kind of joy.", "Organize moments with tags that fit your life."),
        ("See your", "happiness grow.", "Look back on the bright spots in your week."),
    ],
}
PAGES = ("01-moments", "02-detail", "03-participants", "04-tags", "05-chart")

def font(size, chinese=False, bold=False):
    if chinese:
        candidates = glob.glob("/System/Library/AssetsV2/com_apple_MobileAsset_Font*/*/AssetData/PingFang.ttc")
        if candidates:
            return ImageFont.truetype(candidates[0], size, index=11 if bold else 3)
        return ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", size)
    path = "/System/Library/Fonts/Avenir Next.ttc"
    for index in range(30):
        try:
            candidate = ImageFont.truetype(path, size, index=index)
        except OSError:
            break
        if candidate.getname()[1] == ("Demi Bold" if bold else "Regular"):
            return candidate
    return ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)

def centered(draw, text, y, width, face, fill):
    bounds = draw.textbbox((0, 0), text, font=face)
    draw.text(((width - (bounds[2] - bounds[0])) / 2, y - bounds[1]), text, font=face, fill=fill)

def compose(path, output_dir, sun, theme):
    locale, device = path.parent.parent.name, path.parent.name
    index = int(path.stem.split("-")[0]) - 1
    chinese = locale == "zh-Hans"
    w, h = (1242, 2688) if device == "iphone" else (2064, 2752)
    scale = w / 1242
    art = Image.new("RGB", (w, h), theme["background"])
    draw = ImageDraw.Draw(art)
    # Quiet, warm edge accents retain a clear field around the app itself.
    draw.ellipse((w * .77, h * .21, w * 1.35, h * .49), fill=theme["accent"])
    draw.ellipse((-w * .29, h * .76, w * .21, h * 1.03), fill=theme["accent"])
    icon = Image.open(sun).convert("RGBA")
    logo_size = round(96 * scale) if device == "iphone" else 116
    icon.thumbnail((logo_size, logo_size), Image.Resampling.LANCZOS)
    logo_y = 77 if device == "iphone" else 57
    brand_font = font(42 if device == "iphone" else 50, bold=True)
    brand_width = draw.textbbox((0, 0), "HDiary", font=brand_font)[2]
    logo_x = int((w - logo_size - 22 - brand_width) / 2)
    if theme is THEMES["dark"]:
        # Preserve the sun artwork; a warm badge keeps its brown rays readable.
        pad = 10
        draw.ellipse((logo_x - pad, logo_y - pad, logo_x + logo_size + pad,
                      logo_y + logo_size + pad), fill="#FFF0D6")
    art.paste(icon, (logo_x, logo_y), icon)
    draw.text((logo_x + logo_size + 22, logo_y + (logo_size - 45) / 2 - 7), "HDiary", font=brand_font, fill=theme["brand"])
    title1, title2, subtitle = COPY[locale][index]
    title_size = (92 if chinese else 87) if device == "iphone" else (112 if chinese else 107)
    face = font(title_size, chinese, True)
    while max(draw.textbbox((0, 0), text, font=face)[2] for text in (title1, title2)) > w * .88:
        title_size -= 2
        face = font(title_size, chinese, True)
    top = 224 if device == "iphone" else 224
    line_height = title_size * 1.24
    centered(draw, title1, top, w, face, theme["title"])
    centered(draw, title2, top + line_height, w, face, theme["highlight"])
    subtitle_size = 38 if device == "iphone" else 50
    subface = font(subtitle_size, chinese)
    while draw.textbbox((0, 0), subtitle, font=subface)[2] > w * .9:
        subtitle_size -= 1
        subface = font(subtitle_size, chinese)
    centered(draw, subtitle, top + line_height * 2 + 24, w, subface, theme["subtitle"])

    screenshot = Image.open(path).convert("RGB")
    expected_size = (1206, 2622) if device == "iphone" else (2064, 2752)
    if screenshot.size != expected_size:
        raise ValueError(f"{path}: expected native pixels {expected_size}, got {screenshot.size}; recapture without downsampling")
    screen_width = 920 if device == "iphone" else 1536
    screen_height = round(screenshot.height * screen_width / screenshot.width)
    screen = screenshot.resize((screen_width, screen_height), Image.Resampling.LANCZOS)
    bezel = 19 if device == "iphone" else 25
    frame_width, frame_height = screen_width + bezel * 2, screen_height + bezel * 2
    x = (w - frame_width) // 2
    y = 608 if device == "iphone" else 622
    outer_radius = 111 if device == "iphone" else 68
    shadow = Image.new("RGBA", (w, h))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x - 3, y + 20, x + frame_width + 3, y + frame_height + 22), radius=outer_radius, fill=theme["shadow"])
    shadow = shadow.filter(ImageFilter.GaussianBlur(25))
    art = Image.alpha_composite(art.convert("RGBA"), shadow)
    draw = ImageDraw.Draw(art)
    draw.rounded_rectangle((x, y, x + frame_width, y + frame_height), radius=outer_radius, fill=theme["frame"], outline=theme["border"], width=3)
    mask = Image.new("L", screen.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, screen_width, screen_height), radius=outer_radius - bezel, fill=255)
    art.paste(screen, (x + bezel, y + bezel), mask)
    # The simulator screenshot excludes the hardware cutout.
    if device == "iphone":
        island_w, island_h = 240, 64
        ix = (w - island_w) // 2
        iy = y + bezel + 25
        draw.rounded_rectangle((ix, iy, ix + island_w, iy + island_h), radius=island_h // 2, fill=theme["island"])
    destination = output_dir / locale / device / path.name
    destination.parent.mkdir(parents=True, exist_ok=True)
    art.convert("RGB").save(destination, optimize=True)
    return destination

def create_review(outputs, base, output_dir, theme):
    preview = base / "preview"
    preview.mkdir(parents=True, exist_ok=True)
    sections = []
    for locale in COPY:
        for device in ("iphone", "ipad"):
            paths = [path for path in outputs if path.parent == output_dir / locale / device]
            if not paths:
                continue
            sheet = Image.new("RGB", (310 * len(paths), 720 if device == "iphone" else 452), theme["preview"])
            draw = ImageDraw.Draw(sheet)
            cards = []
            for index, path in enumerate(paths):
                shot = Image.open(path).convert("RGB")
                shot.thumbnail((300, 670), Image.Resampling.LANCZOS)
                sheet.paste(shot, (index * 310 + 5, 32))
                draw.text((index * 310 + 12, 10), path.stem, fill=theme["title"])
                relative = html.escape(str(path.relative_to(base)))
                cards.append(f'<a href="{relative}"><img src="{relative}" alt="{path.stem}"></a>')
            sheet.save(preview / f"{locale}-{device}.jpg", quality=94)
            sections.append(f'<h2>{locale} · {device}</h2><div class="grid">{"".join(cards)}</div>')
    (base / "review.html").write_text(
        '<!doctype html><html lang="zh-Hans"><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1">'
        '<title>HDiary 1.16 App Store screenshots</title><style>'
        f'body{{margin:32px;background:{theme["background"].lower()};color:{theme["title"].lower()};font-family:system-ui}}'
        'h1{font-size:28px}h2{margin-top:40px;font-size:20px}'
        '.grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:16px}'
        'img{width:100%;border-radius:10px;box-shadow:0 4px 16px #473a2920}'
        '@media(max-width:900px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}'
        '</style><h1>HDiary 1.16 · App Store 截图</h1>'
        f'<p>{theme["description"]}点击图片查看原尺寸。</p>'
        + "".join(sections) + '</html>\n'
    )

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--theme", choices=(*THEMES, "mixed"), default="light",
                        help="Dark uses screenshots/dark; mixed selects four light images and one dark chart into screenshots/mixed")
    parser.add_argument("--allow-partial", action="store_true", help="Compose completed groups while capture is in progress")
    options = parser.parse_args()
    if options.theme == "mixed":
        base = ROOT / "screenshots/mixed"
        output_dir = base / "store"
        selections = []
        for locale in COPY:
            for device in ("iphone", "ipad"):
                for page in PAGES:
                    appearance = "dark" if page == "05-chart" else "light"
                    source_base = ROOT / ("screenshots/dark" if appearance == "dark" else "screenshots")
                    source = source_base / "store" / locale / device / f"{page}.png"
                    destination = output_dir / locale / device / source.name
                    with Image.open(source) as image:
                        expected_size = (1242, 2688) if device == "iphone" else (2064, 2752)
                        if image.size != expected_size or image.mode != "RGB":
                            raise ValueError(f"{source}: expected RGB {expected_size}, got {image.mode} {image.size}")
                    selections.append((source, destination, appearance, expected_size))
        manifest = []
        for source, destination, appearance, size in selections:
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)
            manifest.append({
                "path": str(destination.relative_to(ROOT)),
                "source": str(source.relative_to(ROOT)), "appearance": appearance,
                "width": size[0], "height": size[1], "mode": "RGB",
                "sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
            })
        (base / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
        review_theme = {**THEMES["light"], "description": "前四张暖白浅色 · 第五张暗色统计 · 五张分别展示不同功能。"}
        create_review([destination for _, destination, _, _ in selections], base, output_dir, review_theme)
        print(f"Selected {len(selections)} screenshots: four light images and one dark chart per group")
        return
    theme = THEMES[options.theme]
    base = ROOT / "screenshots" if options.theme == "light" else ROOT / "screenshots/dark"
    raw, output_dir, sun = base / "raw", base / "store", base / "sun.png"
    expected = [raw / locale / device / f"{page}.png"
                for locale in COPY for device in ("iphone", "ipad") for page in PAGES]
    missing = [str(path.relative_to(ROOT)) for path in expected if not path.is_file()]
    if missing and not options.allow_partial:
        parser.error("Missing source screenshots: " + ", ".join(missing))
    sun.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["rsvg-convert", "--width", "384", "--height", "384", "--output", str(sun),
                    str(REPO / "HDiary/Assets.xcassets/WidgetAppIcon.imageset/WidgetAppIcon.svg")], check=True)
    outputs = [compose(path, output_dir, sun, theme) for path in sorted(raw.glob("*/*/*.png"))]
    manifest = []
    for path in outputs:
        with Image.open(path) as image:
            manifest.append({"path": str(path.relative_to(ROOT)), "width": image.width, "height": image.height, "mode": image.mode,
                             "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    (base / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    create_review(outputs, base, output_dir, theme)
    print(f"Composed {len(outputs)} {options.theme} screenshots")

if __name__ == "__main__":
    main()
