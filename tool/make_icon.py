"""Render the AriseStronger app icon with Pillow.

Concept: three stacked upward chevrons = "rise / level up / get stronger",
neon purple->cyan gradient with a strong glow, on the dark System void.
Outputs a full icon (with background) and a transparent foreground for
Android adaptive icons.
"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SS = 2          # supersample factor
S = 1024
N = S * SS

PURPLE = (124, 92, 252)
BLUE = (61, 155, 255)
CYAN = (0, 210, 255)
BG_CENTER = (22, 18, 46)
BG_EDGE = (7, 7, 15)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def radial_bg(size, center, edge):
    img = Image.new("RGB", (size, size))
    px = img.load()
    cx = cy = size / 2
    maxd = math.hypot(cx, cy)
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / maxd
            d = min(1.0, d ** 0.85)
            px[x, y] = lerp(center, edge, d)
    return img


def vgradient(size, stops):
    """Vertical gradient RGBA from a list of (pos0-1, color) stops."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    stops = sorted(stops)
    for y in range(size):
        t = y / (size - 1)
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]
            p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                lt = (t - p0) / (p1 - p0) if p1 > p0 else 0
                col = lerp(c0, c1, lt)
                break
        else:
            col = stops[-1][1]
        for x in range(size):
            px[x, y] = col
    return img


def chevron_mask(size):
    """White stacked upward chevrons on black (L mode)."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    cx = size // 2
    hw = int(0.225 * size)        # horizontal reach
    drop = int(0.15 * size)       # how far arms drop
    stroke = int(0.072 * size)
    r = stroke // 2
    apexes = [0.30, 0.47, 0.64]   # relative y of each apex
    for ay in apexes:
        apex = (cx, int(ay * size))
        left = (cx - hw, int(ay * size) + drop)
        right = (cx + hw, int(ay * size) + drop)
        d.line([left, apex, right], fill=255, width=stroke, joint="curve")
        for p in (left, apex, right):
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=255)
    return m


def build_mark(size):
    """Gradient-filled, glowing chevron mark on a transparent canvas."""
    mask = chevron_mask(size)

    grad = vgradient(size, [
        (0.20, CYAN),
        (0.50, PURPLE),
        (0.85, BLUE),
    ]).convert("RGBA")
    mark = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mark.paste(grad, (0, 0), mask)

    # Glow: colorized blurred copies stacked underneath.
    glow_src = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_src.paste(Image.new("RGBA", (size, size), CYAN + (255,)), (0, 0), mask)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for radius, alpha in ((int(size * 0.06), 150), (int(size * 0.025), 200)):
        g = glow_src.filter(ImageFilter.GaussianBlur(radius))
        g.putalpha(g.getchannel("A").point(lambda a: int(a * alpha / 255)))
        canvas = Image.alpha_composite(canvas, g)
    canvas = Image.alpha_composite(canvas, mark)
    return canvas


def main():
    # --- Full icon (with background) ---
    bg = radial_bg(N, BG_CENTER, BG_EDGE).convert("RGBA")

    # faint system grid
    grid = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    step = N // 14
    for i in range(0, N, step):
        gd.line([(i, 0), (i, N)], fill=(124, 92, 252, 16), width=1)
        gd.line([(0, i), (N, i)], fill=(124, 92, 252, 16), width=1)
    bg = Image.alpha_composite(bg, grid)

    mark = build_mark(N)
    full = Image.alpha_composite(bg, mark)
    full = full.resize((S, S), Image.LANCZOS).convert("RGB")
    full.save("assets/icon/icon.png")

    # --- Adaptive foreground (transparent, mark inset to safe zone) ---
    fg = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    inner = build_mark(int(N * 0.66))
    off = (N - inner.width) // 2
    fg.alpha_composite(inner, (off, off))
    fg = fg.resize((S, S), Image.LANCZOS)
    fg.save("assets/icon/icon_foreground.png")

    # --- Splash logo (transparent mark, used by flutter_native_splash) ---
    splash = build_mark(N).resize((S, S), Image.LANCZOS)
    splash.save("assets/icon/splash.png")

    # --- Store assets ---
    os.makedirs("assets/store", exist_ok=True)
    full.resize((512, 512), Image.LANCZOS).save("assets/store/play_icon_512.png")
    full.save("assets/store/appstore_icon_1024.png")  # already 1024, no alpha
    make_feature_graphic(full)

    print("wrote icon, foreground, splash, and store assets")


def load_font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()


def make_feature_graphic(full_icon):
    """Google Play feature graphic: 1024x500, mark + wordmark + tagline."""
    W, H = 1024, 500
    img = radial_bg(max(W, H), BG_CENTER, BG_EDGE).convert("RGBA")
    img = img.crop((0, (img.height - H) // 2, W, (img.height - H) // 2 + H))

    # mark on the left
    mark = build_mark(820).resize((360, 360), Image.LANCZOS)
    img.alpha_composite(mark, (40, (H - 360) // 2))

    d = ImageDraw.Draw(img)
    big = load_font("assets/fonts/Rajdhani-Bold.ttf", 110)
    mono = load_font("assets/fonts/ShareTechMono-Regular.ttf", 30)

    tx = 430
    d.text((tx, 150), "ARISE", font=big, fill=(232, 232, 255))
    d.text((tx, 250), "STRONGER", font=big, fill=CYAN)
    d.text((tx, 380), "RISE  ·  TRAIN  ·  LEVEL UP", font=mono,
           fill=(124, 92, 252))

    img.convert("RGB").save("assets/store/feature_graphic_1024x500.png")


if __name__ == "__main__":
    main()
