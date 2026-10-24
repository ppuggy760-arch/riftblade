"""Renders preview images of Lobster Lagoon (an approximation of the editor).

    python3 render_preview.py      # writes preview/overview.png + close-ups

Colour triggers are applied instantly at their x position; move/rotate
animations are shown in their starting pose. Sprites other than squares,
slopes, circles, spikes and gameplay objects are drawn as simple stand-ins.
"""

import math
import os

from PIL import Image, ImageDraw, ImageFont

import build_level as B
import gdkit as K
import verify as V
import physics as P

FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
PORTAL_COLORS = {12: (60, 220, 90), 13: (255, 90, 200), 47: (255, 80, 60),
                 111: (255, 170, 40), 660: (60, 200, 255), 745: (230, 230, 230),
                 200: (255, 220, 60), 201: (80, 160, 255), 202: (90, 255, 120),
                 203: (255, 120, 255), 1334: (255, 60, 60)}
LAYER_RANK = {None: 4}
TOP, BOTTOM = 330, -45


def channel_timeline(lv):
    """[(x, channel, rgb, opacity, blending)] sorted by x, plus the start."""
    base = {ch: (c["rgb"], c["opacity"], c["blending"]) for ch, c in lv.channels.items()}
    events = []
    for o in lv.objects:
        if o.oid == K.COLOR_TRIGGER:
            events.append((o.x, o["target_color"],
                           (o["red"], o["green"], o["blue"]),
                           o["opacity"] if o["opacity"] is not None else 1.0,
                           bool(o["blending"])))
    events.sort(key=lambda e: e[0])
    return base, events


class Palette:
    def __init__(self, lv):
        self.base, self.events = channel_timeline(lv)
        self.cache = {}

    def at(self, x):
        b = int(x // 100)
        if b not in self.cache:
            st = dict(self.base)
            for ex, ch, rgb, op, bl in self.events:
                if ex > b * 100 + 50:
                    break
                st[ch] = (rgb, op, bl)
            self.cache[b] = st
        return self.cache[b]

    def color(self, x, ch):
        st = self.at(x)
        rgb, op, bl = st.get(ch, ((255, 255, 255), 1.0, False))
        a = int(255 * op * (0.75 if bl else 1.0))
        return (*rgb, a)


def obj_polygon(o):
    sx = (o["scale_x"] or 1) * (o["scale"] or 1)
    sy = (o["scale_y"] or 1) * (o["scale"] or 1)
    rot = math.radians(-(o["rot"] or 0))
    fx = -1 if o["flipx"] else 1
    fy = -1 if o["flipy"] else 1
    if o.oid == K.DECO_SLOPE:
        local = [(-15, -15), (15, -15), (15, 15)]
    elif o.oid == K.SPIKE:
        local = [(-15, -15), (15, -15), (0, 15)]
    else:
        local = [(-15, -15), (15, -15), (15, 15), (-15, 15)]
    c, s = math.cos(rot), math.sin(rot)
    out = []
    for lx, ly in local:
        lx, ly = lx * fx * sx, ly * fy * sy
        out.append((o.x + lx * c - ly * s, o.y + lx * s + ly * c))
    return out


def render(lv, x0, x1, scale, path=None, ceilings=()):
    w = int((x1 - x0) * scale)
    h = int((TOP - BOTTOM) * scale)
    img = Image.new("RGB", (w, h), (0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    pal = Palette(lv)

    def P_(x, y):
        return ((x - x0) * scale, (TOP - y) * scale)

    # background and ground
    step = 20
    for xx in range(int(x0), int(x1) + step, step):
        d.rectangle([P_(xx, TOP), P_(xx + step, 0)], fill=pal.color(xx, K.BG)[:3])
        d.rectangle([P_(xx, 0), P_(xx + step, BOTTOM)],
                    fill=pal.color(xx, K.GROUND)[:3])
        lc = pal.color(xx, K.LINE)
        d.rectangle([P_(xx, 1.2), P_(xx + step, -1.2)], fill=lc[:3])
    for cx0, cx1, cy in ceilings:
        if cx1 < x0 or cx0 > x1:
            continue
        d.rectangle([P_(max(cx0, x0), TOP), P_(min(cx1, x1), cy)],
                    fill=(6, 10, 20, 235))

    def reach(o):
        return 15 * max(o["scale_x"] or 1, o["scale_y"] or 1) * (o["scale"] or 1) * 1.5
    objs = [o for o in lv.objects if o.kind != "trigger"
            and x0 - reach(o) < o.x < x1 + reach(o)]
    objs.sort(key=lambda o: (o["z_layer"] if o["z_layer"] is not None
                             else (6 if o.kind in ("hazard", "orb", "pad",
                                                   "portal", "speed", "coin")
                                   else 4), o["z_order"] or 0))
    font_cache = {}
    for o in objs:
        col = o["color"]
        if o.oid in (K.SQUARE, K.DECO_SLOPE, K.SPIKE):
            ch = col if col else (K.OBJ if o.oid != K.SPIKE else B.HAZARD)
            fill = pal.color(o.x, ch)
            poly = [P_(px, py) for px, py in obj_polygon(o)]
            d.polygon(poly, fill=fill)
            if o.oid == K.SPIKE:
                d.line(poly + [poly[0]], fill=(255, 255, 255, 200),
                       width=max(1, int(scale)))
        elif o.oid in (K.CIRCLE, K.HOLLOW_CIRCLE):
            r = 15 * (o["scale"] or 1) * scale
            cx, cy = P_(o.x, o.y)
            fill = pal.color(o.x, col or K.OBJ)
            if o.oid == K.CIRCLE:
                d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)
            else:
                d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=fill,
                          width=max(1, int(r * 0.22)))
        elif o.oid in K.GRASS_PATCHES:
            fill = pal.color(o.x, col or K.OBJ)
            sc = (o["scale"] or 1)
            for k in range(-2, 3):
                bx0, by0 = P_(o.x + k * 5 * sc, o.y - 6 * sc)
                bx1, by1 = P_(o.x + k * 7 * sc, o.y + (6 + 3 * (k % 2)) * sc)
                d.line([bx0, by0, bx1, by1], fill=fill, width=max(1, int(2 * scale)))
        elif o.oid in (K.YELLOW_ORB, K.PINK_ORB):
            cx, cy = P_(o.x, o.y)
            r = 12 * scale
            c = (255, 230, 40) if o.oid == K.YELLOW_ORB else (255, 90, 210)
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c,
                      outline=(255, 255, 255), width=max(1, int(scale)))
        elif o.oid in (K.YELLOW_PAD, K.PINK_PAD):
            c = (255, 230, 40) if o.oid == K.YELLOW_PAD else (255, 90, 210)
            d.rectangle([P_(o.x - 13, o.y - 9), P_(o.x + 13, o.y - 15)], fill=c)
        elif o.oid in PORTAL_COLORS:
            c = PORTAL_COLORS[o.oid]
            tall = 45 if o.kind == "portal" else 32
            d.rounded_rectangle([P_(o.x - 9, o.y + tall), P_(o.x + 9, o.y - tall)],
                                radius=int(6 * scale), outline=c,
                                width=max(2, int(3 * scale)))
        elif o.oid == K.USER_COIN:
            cx, cy = P_(o.x, o.y)
            r = 13 * scale
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 205, 50),
                      outline=(255, 255, 255), width=max(1, int(2 * scale)))
        elif o.oid == K.TEXT:
            import base64
            txt = base64.urlsafe_b64decode(o["text"]).decode()
            size = max(6, int(26 * (o["scale"] or 1) * scale))
            if size not in font_cache:
                try:
                    font_cache[size] = ImageFont.truetype(FONT_PATH, size)
                except OSError:
                    font_cache[size] = ImageFont.load_default()
            f = font_cache[size]
            cx, cy = P_(o.x, o.y)
            tw = d.textlength(txt, font=f)
            d.text((cx - tw / 2, cy - size / 2), txt, font=f,
                   fill=pal.color(o.x, col or K.OBJ))
    if path:
        pts = [P_(px, py) for px, py, _, _ in path if x0 - 20 <= px <= x1 + 20]
        if len(pts) > 1:
            d.line(pts, fill=(255, 255, 255, 140), width=max(1, int(1.2 * scale)))
    return img.convert("RGB")


def main():
    lv, plan, _ = B.build()
    world = P.World(lv)
    end, trace = V.full_run(lv, plan, world, record=True)
    os.makedirs("preview", exist_ok=True)
    ceilings = [(B.bx(B.S_TRAP), B.bx(B.S_CLAW), 300),
                (B.bx(B.S_KELP), B.bx(B.S_ESC), 300)]
    total = B.bx(B.S_END) - 100
    row_len = 2800
    scale = 0.5
    rows = []
    x = -100
    while x < total:
        rows.append(render(lv, x, x + row_len, scale, trace, ceilings))
        x += row_len
    W = rows[0].width
    H = sum(r.height + 6 for r in rows)
    sheet = Image.new("RGB", (W, H), (20, 20, 24))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height + 6
    sheet.save("preview/overview.png")
    shots = {
        "1_title": (-60, 900), "2_seafloor": (1500, 2400),
        "3_trap": (5600, 6500), "4_claw_tunnel": (9200, 10100),
        "5_kelp_forest": (13700, 14600), "6_boil": (16000, 16900),
        "7_escape": (22600, 23500), "8_lobster_king": (25900, 27300),
    }
    for name, (a, b) in shots.items():
        render(lv, a, b, 1.6, None, ceilings).save(f"preview/{name}.png")
    print("wrote preview/overview.png and", len(shots), "close-ups;",
          "bot run", "completed" if not end.dead else f"died: {end.why}")


if __name__ == "__main__":
    main()
