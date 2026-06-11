"""Generate an AriseStronger overview PDF: cover (icon + description) plus
faithful mockups of the key screens, rendered from the app's real design system.
"""
import os
from PIL import Image, ImageDraw, ImageFont

# ---- palette (from lib/theme.dart) ----
BG = (7, 7, 15)
BG2 = (13, 13, 26)
BG3 = (17, 17, 36)
PURPLE = (124, 92, 252)
BLUE = (61, 155, 255)
GOLD = (240, 180, 41)
RED = (255, 71, 87)
GREEN = (46, 213, 115)
CYAN = (0, 210, 255)
TEXT = (200, 200, 232)
DIM = (107, 107, 154)
BRIGHT = (232, 232, 255)
BORDER = (40, 32, 70)

FD = "assets/fonts/"


def F(name, size):
    return ImageFont.truetype(FD + name, size)


# font cache
def bold(s): return F("Rajdhani-Bold.ttf", s)
def semi(s): return F("Rajdhani-SemiBold.ttf", s)
def reg(s): return F("Rajdhani-Regular.ttf", s)
def mono(s): return F("ShareTechMono-Regular.ttf", s)


_emoji = None
def emoji_font(size):
    global _emoji
    path = "C:/Windows/Fonts/seguiemj.ttf"
    if os.path.exists(path):
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            return None
    return None


def _adv(d, ch, font):
    """Advance width for a char, including drawn glyphs (diamond/triangle)."""
    size = font.size
    if ch == '◈':
        return size * 0.6
    if ch == '▸':
        return size * 0.5
    return d.textlength(ch, font=font)


def tracked(d, xy, s, font, fill, tracking=2):
    x, y = xy
    size = font.size
    for ch in s:
        if ch == '◈':
            r = size * 0.3
            cy = y + size * 0.4
            d.polygon([(x + r, cy - r), (x + 2 * r, cy), (x + r, cy + r), (x, cy)],
                      fill=fill)
        elif ch == '▸':
            h = size * 0.5
            cy = y + size * 0.42
            d.polygon([(x, cy - h / 2), (x + h * 0.7, cy), (x, cy + h / 2)], fill=fill)
        elif ch != ' ':
            d.text((x, y), ch, font=font, fill=fill)
        x += _adv(d, ch, font) + tracking
    return x


def tracked_w(d, s, font, tracking=2):
    return sum(_adv(d, ch, font) + tracking for ch in s) - tracking


def center(d, cx, y, s, font, fill, tracking=0):
    w = tracked_w(d, s, font, tracking)
    tracked(d, (cx - w / 2, y), s, font, fill, tracking)


def draw_emoji(img, d, xy, ch, size, fallback_color):
    ef = emoji_font(size)
    if ef is not None:
        try:
            d.text(xy, ch, font=ef, embedded_color=True)
            return
        except Exception:
            pass
    d.rounded_rectangle([xy[0], xy[1], xy[0] + size, xy[1] + size],
                        radius=4, fill=fallback_color)


def panel(d, box, fill=BG2, border=BORDER, radius=4, width=1):
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=border, width=width)


def bar(d, x, y, w, h, pct, colors):
    d.rounded_rectangle([x, y, x + w, y + h], radius=h // 2, fill=(24, 24, 34))
    fw = int(w * pct)
    if fw > h:
        d.rounded_rectangle([x, y, x + fw, y + h], radius=h // 2, fill=colors)


# ======================================================================
#  PHONE FRAME
# ======================================================================
PW, PH = 520, 1080


def new_phone():
    img = Image.new("RGBA", (PW, PH), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2, 2, PW - 2, PH - 2], radius=46, fill=BG,
                        outline=(45, 40, 80), width=3)
    # status bar
    d.text((34, 26), "9:41", font=semi(22), fill=BRIGHT)
    for i, w in enumerate([5, 7, 9, 11]):
        d.rounded_rectangle([PW - 150 + i * 12, 40 - w, PW - 150 + i * 12 + 7, 40],
                            radius=2, fill=BRIGHT)
    d.rounded_rectangle([PW - 96, 26, PW - 60, 42], radius=4, outline=BRIGHT, width=2)
    d.rounded_rectangle([PW - 92, 30, PW - 70, 38], radius=2, fill=GREEN)
    return img, d


def bottom_nav(d, active):
    y = PH - 86
    d.rectangle([6, y, PW - 6, PH - 6], fill=BG2)
    d.line([6, y, PW - 6, y], fill=BORDER, width=1)
    items = ["QUEST", "PROGRAM", "PROGRESS", "PROFILE"]
    cw = (PW - 12) / 4
    for i, label in enumerate(items):
        cx = 6 + cw * i + cw / 2
        on = i == active
        col = PURPLE if on else DIM
        if on:
            d.rounded_rectangle([cx - 30, y + 14, cx + 30, y + 42], radius=14,
                                fill=(28, 24, 52))
        d.ellipse([cx - 8, y + 20, cx + 8, y + 36], outline=col, width=2)
        center(d, cx, y + 48, label, mono(15), col, tracking=1)


def header(d, greeting, name, date):
    tracked(d, (30, 70), greeting, mono(18), PURPLE, 2)
    d.text((30, 96), name, font=bold(40), fill=BRIGHT)
    tracked(d, (30, 146), date, mono(16), DIM, 1)


def quote_card(d, y):
    panel(d, [24, y, PW - 24, y + 150], border=(60, 50, 100))
    d.rounded_rectangle([24, y, PW - 24, y + 34], radius=4, fill=(18, 16, 40))
    tracked(d, (38, y + 9), "◈ THE SYSTEM ◈", mono(15), PURPLE, 2)
    tracked(d, (PW - 90, y + 9), "DAILY", mono(13), DIM, 2)
    d.text((38, y + 50), '"I used to be the weakest.', font=semi(22), fill=BRIGHT)
    d.text((38, y + 78), 'So I chose to become', font=semi(22), fill=BRIGHT)
    d.text((38, y + 106), 'the strongest."', font=semi(22), fill=BRIGHT)
    tracked(d, (38, y + 132), "— SUNG JINWOO", mono(14), PURPLE, 1)


def rank_card(d, y, rank="E", name="E-Rank Hunter", color=TEXT, nxt="5 days to E+-Rank",
              pct=0.3):
    panel(d, [24, y, PW - 24, y + 120])
    d.rounded_rectangle([40, y + 22, 96, y + 78], radius=4,
                        fill=(color[0] // 6, color[1] // 6, color[2] // 6 + 10),
                        outline=color, width=3)
    center(d, 68, y + 36, rank, mono(30), color)
    tracked(d, (118, y + 24), "PLAYER RANK", mono(14), DIM, 2)
    d.text((116, y + 40), name, font=bold(26), fill=BRIGHT)
    tracked(d, (118, y + 74), "▸ " + nxt, mono(15), PURPLE, 0)
    bar(d, 40, y + 100, PW - 80, 6, pct, PURPLE)


def quest_row(d, y, icon, name, target, checked, icon_color):
    box = checked
    cb = [40, y, 64, y + 24]
    if box:
        d.rounded_rectangle(cb, radius=4, fill=PURPLE)
        d.line([46, y + 12, 51, y + 18], fill=(255, 255, 255), width=3)
        d.line([51, y + 18, 59, y + 6], fill=(255, 255, 255), width=3)
    else:
        d.rounded_rectangle(cb, radius=4, outline=(90, 80, 140), width=2)
    d.rounded_rectangle([78, y - 2, 104, y + 24], radius=5, fill=icon_color)
    nm_col = DIM if box else TEXT
    d.text((118, y - 2), name, font=semi(24), fill=nm_col)
    tw = d.textlength(target, font=mono(18))
    tracked(d, (PW - 48 - tw, y + 2), target, mono(18),
            GREEN if box else PURPLE, 0)


# ======================================================================
#  SCREEN: QUEST
# ======================================================================
def screen_quest():
    img, d = new_phone()
    header(d, "◈ RISE AND GRIND, HUNTER ◈", "JINWOO",
           "TUESDAY, 10 JUNE 2026")

    # streak banner
    y = 185
    d.rounded_rectangle([24, y, PW - 24, y + 86], radius=4, fill=(30, 26, 20),
                        outline=(120, 95, 35), width=2)
    draw_emoji(img, d, (40, y + 22), "\U0001F525", 40, GOLD)
    tracked(d, (96, y + 18), "12 DAY STREAK", mono(26), GOLD, 1)
    d.text((98, y + 50), "Don't break the chain, Hunter.", font=reg(19), fill=DIM)

    quote_card(d, 290)
    rank_card(d, 458)

    # quest panel
    y = 596
    panel(d, [24, y, PW - 24, y + 290])
    d.rounded_rectangle([24, y, PW - 24, y + 36], radius=4, fill=(18, 16, 40))
    tracked(d, (38, y + 9), "◈ TODAY'S QUEST", mono(15), PURPLE, 2)
    tracked(d, (PW - 86, y + 9), "2 / 4", mono(14), DIM, 1)
    quest_row(d, y + 60, "", "Push-ups", "10 reps", True, (124, 92, 252))
    quest_row(d, y + 104, "", "Sit-ups", "10 reps", True, (255, 120, 60))
    quest_row(d, y + 148, "", "Squats", "10 reps", False, (240, 180, 41))
    quest_row(d, y + 192, "", "Plank", "00:30", False, (46, 213, 115))
    d.line([24, y + 238, PW - 24, y + 238], fill=BORDER, width=1)
    tracked(d, (38, y + 252), "COMPLETION", mono(14), DIM, 1)
    tracked(d, (PW - 70, y + 252), "50%", mono(14), GREEN, 0)
    bar(d, 38, y + 274, PW - 76, 6, 0.5, GREEN)

    # complete button
    y = 906
    d.rounded_rectangle([24, y, PW - 24, y + 56], radius=4, fill=PURPLE)
    center(d, PW / 2, y + 16, "◈ QUEST COMPLETE ◈", bold(24), (255, 255, 255))

    bottom_nav(d, 0)
    return img


# ======================================================================
#  SCREEN: PROGRAM
# ======================================================================
def screen_program():
    img, d = new_phone()
    tracked(d, (30, 74), "◈ TRAINING PROGRAM ◈", mono(18), PURPLE, 2)
    d.rounded_rectangle([30, 108, 78, 156], radius=4, fill=(22, 20, 36),
                        outline=TEXT, width=3)
    center(d, 54, 120, "E", mono(26), TEXT)
    d.text((96, 110), "E-Rank Hunter", font=bold(28), fill=BRIGHT)
    tracked(d, (98, 144), "SYSTEM-PRESCRIBED DAILY SET", mono(13), DIM, 1)

    y = 186
    panel(d, [24, y, PW - 24, y + 200])
    rows = [("Push-ups", "10 reps", (124, 92, 252)),
            ("Sit-ups", "10 reps", (255, 120, 60)),
            ("Squats", "10 reps", (240, 180, 41)),
            ("Plank", "00:30", (46, 213, 115))]
    for i, (nm, tg, c) in enumerate(rows):
        ry = y + 22 + i * 45
        d.rounded_rectangle([40, ry, 66, ry + 26], radius=5, fill=c)
        d.text((80, ry - 2), nm, font=semi(23), fill=TEXT)
        tw = d.textlength(tg, font=mono(18))
        tracked(d, (PW - 48 - tw, ry + 2), tg, mono(18), TEXT, 0)

    tracked(d, (30, y + 222), "◈ YOUR EXERCISES", mono(16), CYAN, 2)
    tracked(d, (PW - 80, y + 222), "+ ADD", mono(15), CYAN, 1)
    panel(d, [24, y + 252, PW - 24, y + 304])
    d.rounded_rectangle([40, y + 268, 66, y + 294], radius=5, fill=CYAN)
    d.text((80, y + 266), "Pull-ups", font=semi(23), fill=TEXT)
    tracked(d, (PW - 110, y + 270), "8 reps", mono(18), CYAN, 0)

    # roadmap
    yy = y + 330
    tracked(d, (30, yy), "◈ RANK ROADMAP", mono(16), PURPLE, 2)
    ranks = [("E", "E-Rank Hunter", TEXT, "CURRENT RANK", True),
             ("D", "D-Rank Hunter", BLUE, "6 exercises", False),
             ("C", "C-Rank Hunter", GOLD, "7 exercises", False),
             ("B", "B-Rank Hunter", (255, 107, 129), "7 exercises", False)]
    for i, (rk, nm, c, sub, cur) in enumerate(ranks):
        ry = yy + 32 + i * 60
        panel(d, [24, ry, PW - 24, ry + 50], fill=BG2,
              border=c if cur else BORDER, width=2 if cur else 1)
        d.rounded_rectangle([38, ry + 8, 74, ry + 44], radius=4,
                            fill=(c[0] // 6, c[1] // 6, c[2] // 6 + 8),
                            outline=c, width=2)
        center(d, 56, ry + 16, rk, mono(20), c)
        d.text((90, ry + 8), nm, font=semi(22), fill=BRIGHT if i == 0 else DIM)
        tracked(d, (92, ry + 32), sub, mono(13), c if cur else DIM, 1)
        d.text((PW - 54, ry + 14), "v", font=reg(20), fill=DIM)

    bottom_nav(d, 1)
    return img


# ======================================================================
#  SCREEN: PROGRESS
# ======================================================================
def screen_progress():
    img, d = new_phone()
    tracked(d, (30, 74), "◈ HUNTER PROGRESS ◈", mono(18), PURPLE, 2)

    # stat boxes
    y = 120
    stats = [("12", "STREAK", GOLD), ("34", "TOTAL DAYS", PURPLE), ("3", "LEVEL", CYAN)]
    bw = (PW - 48 - 16) / 3
    for i, (v, l, c) in enumerate(stats):
        x = 24 + i * (bw + 8)
        panel(d, [x, y, x + bw, y + 92])
        center(d, x + bw / 2, y + 18, v, mono(40), c)
        center(d, x + bw / 2, y + 66, l, mono(13), DIM, 1)

    # rank progress
    y = 232
    panel(d, [24, y, PW - 24, y + 150])
    d.rounded_rectangle([40, y + 20, 90, y + 70], radius=4, fill=(22, 20, 36),
                        outline=TEXT, width=3)
    center(d, 65, y + 32, "E", mono(26), TEXT)
    d.text((110, y + 22), "E-Rank Hunter", font=bold(26), fill=BRIGHT)
    tracked(d, (112, y + 56), "▸ 5 days to E+-Rank", mono(15), PURPLE, 0)
    tracked(d, (40, y + 92), "RANK PROGRESS", mono(15), DIM, 1)
    tracked(d, (PW - 80, y + 92), "30%", mono(15), DIM, 0)
    bar(d, 40, y + 116, PW - 80, 8, 0.3, PURPLE)

    # history
    y = 408
    panel(d, [24, y, PW - 24, y + 280])
    d.rounded_rectangle([24, y, PW - 24, y + 36], radius=4, fill=(18, 16, 40))
    tracked(d, (38, y + 9), "◈ QUEST HISTORY", mono(15), PURPLE, 2)
    tracked(d, (PW - 130, y + 9), "LAST 28 DAYS", mono(12), DIM, 1)
    # dots grid
    import random
    random.seed(7)
    gx, gy = 44, y + 60
    for r in range(4):
        for c in range(7):
            cx = gx + c * 30
            cy = gy + r * 30
            idx = r * 7 + c
            if idx < 5:
                col = (44, 30, 32)  # missed-ish early
            elif idx in (9,):
                col = RED
            else:
                col = PURPLE
            d.ellipse([cx, cy, cx + 18, cy + 18], fill=col)
    # legend
    ly = y + 200
    leg = [(PURPLE, "Complete"), (RED, "Penalty"), ((70, 40, 45), "Missed")]
    lx = 44
    for col, lab in leg:
        d.ellipse([lx, ly, lx + 14, ly + 14], fill=col)
        d.text((lx + 22, ly - 4), lab, font=mono(15), fill=DIM)
        lx += 40 + d.textlength(lab, font=mono(15))

    bottom_nav(d, 2)
    return img


# ======================================================================
#  SCREEN: ONBOARDING
# ======================================================================
def screen_onboarding():
    img, d = new_phone()
    center(d, PW / 2, 90, "◈ AWAKENING ◈", mono(18), PURPLE, 3)
    center(d, PW / 2, 130, "ARISE", bold(48), BRIGHT)
    center(d, PW / 2, 184, "STRONGER", bold(48), CYAN)
    center(d, PW / 2, 250, "The System is calibrating your quest.", reg(20), DIM)

    tracked(d, (40, 300), "YOUR TRAINING LEVEL", mono(15), DIM, 2)
    levels = [("E", "BEGINNER", "Start at E-Rank and build the foundation.", TEXT, True),
              ("C", "INTERMEDIATE", "Begin at C-Rank with a tougher program.", GOLD, False),
              ("B", "PRO", "Enter at B-Rank and push toward Monarch.", (255, 107, 129), False)]
    y = 332
    for rk, title, sub, c, sel in levels:
        h = 92
        d.rounded_rectangle([24, y, PW - 24, y + h], radius=4,
                            fill=(c[0] // 8, c[1] // 8, c[2] // 8 + 8) if sel else BG2,
                            outline=c if sel else BORDER, width=3 if sel else 1)
        d.rounded_rectangle([40, y + 24, 86, y + 70], radius=4,
                            fill=(c[0] // 6, c[1] // 6, c[2] // 6 + 8), outline=c, width=2)
        center(d, 63, y + 36, rk, mono(24), c)
        d.text((104, y + 22), title, font=bold(24), fill=BRIGHT if sel else TEXT)
        d.text((104, y + 54), sub, font=reg(17), fill=DIM)
        if sel:
            d.ellipse([PW - 64, y + 32, PW - 36, y + 60], outline=GREEN, width=3)
            d.line([PW - 58, y + 46, PW - 52, y + 53], fill=GREEN, width=3)
            d.line([PW - 52, y + 53, PW - 42, y + 38], fill=GREEN, width=3)
        y += h + 14

    y += 6
    tracked(d, (40, y), "DAILY REMINDER", mono(15), DIM, 2)
    panel(d, [24, y + 26, PW - 24, y + 80])
    d.text((44, y + 40), "Remind me at 8:00 AM", font=semi(22), fill=BRIGHT)

    y += 110
    d.rounded_rectangle([24, y, PW - 24, y + 58], radius=4, fill=PURPLE)
    center(d, PW / 2, y + 16, "◈ ARISE ◈", bold(26), (255, 255, 255))
    return img


# ======================================================================
#  PAGES
# ======================================================================
PGW, PGH = 1240, 1754


def radial_page():
    page = Image.new("RGB", (PGW, PGH), BG)
    # subtle top glow
    glow = Image.new("RGB", (PGW, PGH), BG)
    gd = ImageDraw.Draw(glow)
    for r in range(420, 0, -8):
        a = int(18 * (r / 420))
        gd.ellipse([PGW // 2 - r, -160 - r // 2, PGW // 2 + r, -160 + r],
                   fill=(7 + a // 3, 7 + a // 4, 15 + a))
    return page


def place_phone(page, phone, cx, top, caption):
    page.paste(phone, (int(cx - phone.width / 2), top), phone)
    d = ImageDraw.Draw(page)
    center(d, cx, top + phone.height + 14, caption, mono(24), PURPLE, 2)


def build():
    d_tmp = ImageDraw.Draw(Image.new("RGB", (10, 10)))

    # ---------- COVER ----------
    cover = radial_page()
    d = ImageDraw.Draw(cover)
    icon = Image.open("assets/icon/icon.png").convert("RGBA").resize((300, 300),
                                                                     Image.LANCZOS)
    cover.paste(icon, (PGW // 2 - 150, 150), icon)
    center(d, PGW / 2, 480, "ARISE", bold(96), BRIGHT)
    center(d, PGW / 2, 590, "STRONGER", bold(96), CYAN)
    center(d, PGW / 2, 720, "A SOLO-LEVELING DAILY FITNESS SYSTEM",
           mono(28), PURPLE, 4)

    desc = ("AriseStronger turns getting fit into an RPG. Complete your daily "
            "workout quest, rank up from E-Rank Hunter all the way to the Shadow "
            "Monarch, and keep your streak alive with daily motivation from "
            "scripture, timeless wisdom, and the System itself. Every rank "
            "prescribes a tougher workout, you can add your own exercises on top, "
            "and real notifications keep you coming back. Miss a day and the "
            "Penalty Zone is waiting. The weak are not forgiven — the strong "
            "keep rising.")
    wrap_paragraph(d, desc, reg(30), TEXT, 110, 800, PGW - 220, 42)

    feats = [
        "10 Hunter ranks with escalating workout programs",
        "Custom exercises — reps or timed, with a built-in timer",
        "Streaks, first-miss grace, and rank-scaled penalties",
        "Daily motivation: Bible, wisdom & Solo Leveling quotes",
        "Real reminders + cloud sync (Supabase), iOS & Android",
    ]
    fy = 1130
    for f in feats:
        d.rounded_rectangle([180, fy + 8, 196, fy + 24], radius=3, fill=PURPLE)
        d.text((220, fy), f, font=semi(30), fill=BRIGHT)
        fy += 56
    center(d, PGW / 2, PGH - 70, "github.com/Laurence-26/Arisestronger",
           mono(24), DIM, 2)

    # ---------- SCREENS PAGE 1 ----------
    p2 = radial_page()
    d2 = ImageDraw.Draw(p2)
    center(d2, PGW / 2, 70, "◈ INSIDE ARISESTRONGER ◈", mono(30), PURPLE, 4)
    place_phone(p2, screen_quest(), PGW / 4 + 20, 150, "DAILY QUEST")
    place_phone(p2, screen_program(), PGW * 3 / 4 - 20, 150, "TRAINING PROGRAM")

    # ---------- SCREENS PAGE 2 ----------
    p3 = radial_page()
    d3 = ImageDraw.Draw(p3)
    center(d3, PGW / 2, 70, "◈ INSIDE ARISESTRONGER ◈", mono(30), PURPLE, 4)
    place_phone(p3, screen_progress(), PGW / 4 + 20, 150, "PROGRESS & HISTORY")
    place_phone(p3, screen_onboarding(), PGW * 3 / 4 - 20, 150, "ONBOARDING")

    out = "AriseStronger_Overview.pdf"
    cover.save(out, save_all=True, append_images=[p2, p3], resolution=150)
    if os.environ.get("PNG"):
        for i, pg in enumerate([cover, p2, p3], 1):
            pg.save(f"tool/_preview_{i}.png")
    print("wrote", out)


def wrap_paragraph(d, text, font, fill, x, y, maxw, lh):
    words = text.split()
    line = ""
    for w in words:
        test = (line + " " + w).strip()
        if d.textlength(test, font=font) > maxw:
            d.text((x, y), line, font=font, fill=fill)
            y += lh
            line = w
        else:
            line = test
    if line:
        d.text((x, y), line, font=font, fill=fill)


if __name__ == "__main__":
    build()
